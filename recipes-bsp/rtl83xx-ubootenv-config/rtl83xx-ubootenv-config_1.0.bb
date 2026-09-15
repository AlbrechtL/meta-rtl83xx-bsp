SUMMARY = "libubootenv configuration for the RTL83xx U-Boot environment"
DESCRIPTION = "/etc/fw_env.config pointing at the stock Zyxel U-Boot's main \
environment."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

COMPATIBLE_MACHINE = "^rtl83xx$"
PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI = "file://fw_env.config"

S = "${UNPACKDIR}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${S}/fw_env.config ${D}${sysconfdir}/fw_env.config
}

# fw_printenv/fw_setenv, to inspect the environment by hand.
RRECOMMENDS:${PN} = "libubootenv-bin"
