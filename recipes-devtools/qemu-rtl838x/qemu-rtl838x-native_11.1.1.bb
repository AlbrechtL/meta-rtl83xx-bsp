# qemu-rtl838x-native - QEMU with the rtl838x machine from rtl838x-qemu
#
# rtl838x-qemu (https://github.com/AlbrechtL/rtl838x-qemu) emulates the Zyxel
# GS1900-8: an RTL8380M with its interrupt controller, timers, UART, watchdog,
# and a switch core whose eight front ports really forward frames (VLANs,
# spanning tree), and its SPI-NOR flash. It boots the initramfs image of
# zyxel-gs1900-8-a1 as is, and the firmware from flash as the bootloader does.
#
# rtl838x-qemu is not a QEMU fork but a set of device models plus one small
# patch against a pinned QEMU release. This recipe does what its
# scripts/sync.sh and scripts/build.sh do: take the release tarball of that
# QEMU version, copy the models in, apply the patch, and build mips-softmmu
# only. It is a recipe of its own rather than a bbappend to oe-core's
# qemu-system-native, because the models are written and tested against the
# QEMU version rtl838x-qemu pins, not against whatever oe-core ships.
#
# The binary is installed as qemu-system-mips-rtl838x, and the data files go
# to ${datadir}/qemu-rtl838x-native, so it can share a sysroot with
# qemu-system-native. rtl838x-qemu-helper-native gathers it into a sysroot
# to run from, see there.

SUMMARY = "QEMU with the Realtek RTL838x switch SoC machine"
HOMEPAGE = "https://github.com/AlbrechtL/rtl838x-qemu"
LICENSE = "GPL-2.0-only & LGPL-2.1-only & GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://COPYING;md5=a3b50d8b88dcc0eb3d7d39b760b9e821 \
                    file://COPYING.LIB;endline=24;md5=8a8178c06478747a771588adec965232 \
                    file://${UNPACKDIR}/rtl838x-qemu/LICENSE;md5=1d78e217310be197adeb8b236a31ba4a \
                    "

# PV is the QEMU release rtl838x-qemu pins as its qemu submodule. Bump both
# together: SRCREV_rtl838x to the new rtl838x-qemu commit, the file name to
# the QEMU tag its submodule points at, and the sha256sum.
SRC_URI = "https://download.qemu.org/qemu-${PV}.tar.xz;name=qemu \
           git://github.com/AlbrechtL/rtl838x-qemu;protocol=https;branch=master;name=rtl838x;destsuffix=rtl838x-qemu \
           file://0001-configure-use-the-build-system-s-python-and-meson.patch \
           "
SRC_URI[qemu.sha256sum] = "079ffbff8a7111bbc89022107cbabf3bbfd614d5fc9d7cc675991196aca12482"
SRCREV_rtl838x = "5a1b0e406ac10baddbe0af403dcb28c169808398"
SRCREV_FORMAT = "rtl838x"

S = "${UNPACKDIR}/qemu-${PV}"
B = "${WORKDIR}/build"

# QEMU's configure needs a full python3-native, as for oe-core's qemu.
inherit native pkgconfig python3native

DEPENDS = "glib-2.0-native pixman-native zlib-native libslirp-native \
           bison-native meson-native ninja-native"

# rtl838x-qemu's scripts/sync.sh, run on the unpacked tarball: the models and
# their header go into hw/mips/ and include/hw/mips/, patches/rtl838x.patch
# hooks them into Kconfig and meson and adds the rtl8380 CPU. A patch that no
# longer applies means the QEMU version and the rtl838x-qemu commit do not
# belong together.
do_rtl838x_sync() {
	src=${UNPACKDIR}/rtl838x-qemu
	cp $src/src/hw/mips/*.c ${S}/hw/mips/
	install -d ${S}/include/hw/mips
	cp $src/src/include/hw/mips/*.h ${S}/include/hw/mips/
	patch -d ${S} -p1 --forward --batch < $src/patches/rtl838x.patch
}
addtask rtl838x_sync after do_patch before do_configure

# The same options as rtl838x-qemu's scripts/build.sh, with the paths and
# flags oe-core's qemu.inc passes. Headless: the switch has a serial console
# and nothing else.
EXTRA_OECONF = " \
    --prefix=${prefix} \
    --bindir=${bindir} \
    --libdir=${libdir} \
    --datadir=${datadir} \
    --sysconfdir=${sysconfdir} \
    --libexecdir=${libexecdir} \
    --localstatedir=${localstatedir} \
    --with-suffix=${BPN} \
    --target-list=mips-softmmu \
    --disable-strip \
    --disable-werror \
    --extra-cflags='${CFLAGS}' \
    --extra-ldflags='${LDFLAGS}' \
    --disable-download \
    --host-cc='${BUILD_CC}' \
    --disable-docs --disable-tools --disable-guest-agent \
    --disable-gtk --disable-sdl --disable-vnc --disable-spice \
    --disable-opengl --disable-curses --disable-tpm --disable-libusb \
    --disable-af-xdp \
    --enable-slirp \
    "

# QEMU's configure aborts on options it does not know. no-static-libs.inc
# exempts oe-core's qemu recipes by name; this one has to do it itself.
DISABLE_STATIC = ""

LDFLAGS += "-fuse-ld=bfd"

do_configure() {
	export PKG_CONFIG=pkg-config
	${S}/configure ${EXTRA_OECONF}
}
do_configure[cleandirs] += "${B}"

do_install() {
	export STRIP=""
	oe_runmake 'DESTDIR=${D}' install
	mv ${D}${bindir}/qemu-system-mips ${D}${bindir}/qemu-system-mips-rtl838x

	# The check at the end of scripts/build.sh: a build without the machine
	# means the models did not make it into the tree.
	${D}${bindir}/qemu-system-mips-rtl838x -M help | grep -q '^rtl838x ' \
		|| bbfatal "qemu-system-mips-rtl838x has no rtl838x machine"
}
