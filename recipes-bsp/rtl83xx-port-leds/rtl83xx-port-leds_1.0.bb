SUMMARY = "Port LED setup for RTL838x boards whose loader leaves it undone"
DESCRIPTION = "Init script that programs the RTL838x port LED controller \
through the rtl83xx DSA driver's debugfs registers at boot, and lets the LEDs \
blink on reboot and during a firmware update."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# The register values are board specific and come from files/<machine>/.
# A board that needs this adds its own port-leds.conf there and its machine
# name here.
COMPATIBLE_MACHINE = "^albrecht-rtl8382mi-test$"
PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI = " \
    file://rtl83xx-port-leds \
    file://rtl83xx-port-leds-blink \
    file://port-leds.conf \
"

S = "${UNPACKDIR}"

inherit update-rc.d

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${sysconfdir}/init.d ${D}${sysconfdir}/default
    install -m 0755 ${S}/rtl83xx-port-leds ${D}${sysconfdir}/init.d/
    install -m 0644 ${S}/port-leds.conf ${D}${sysconfdir}/default/rtl83xx-port-leds

    # For a firmware updater's pre-update hook (SWUpdate -P takes one word).
    install -d ${D}${sbindir}
    install -m 0755 ${S}/rtl83xx-port-leds-blink ${D}${sbindir}/
}

# Early in the boot, so the LEDs work before the ports come up, and stopped
# on halt and reboot, which starts the blinking.
INITSCRIPT_NAME = "rtl83xx-port-leds"
INITSCRIPT_PARAMS = "defaults 04"

# mount, seq, printf from busybox.
RDEPENDS:${PN} = "busybox"
