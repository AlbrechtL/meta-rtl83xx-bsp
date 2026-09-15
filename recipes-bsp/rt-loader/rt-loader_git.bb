# rt-loader - Realtek Runtime Loader (source only)
#
# Stages the bare-metal LZMA kernel loader sources from the OpenWrt tree
# (target/linux/realtek/image/rt-loader) into the sysroot.
#
# The loader is NOT built here. For the GS1900 family OpenWrt uses the
# "piggy-back" mode (Device/uimage-rt-loader), in which the LZMA compressed
# kernel is turned into an object file and linked into the loader's .kernel
# section. That means the loader can only be built once the kernel exists, so
# the build lives in rtl83xx-bootimage, which depends on virtual/kernel:do_deploy.
#
# The other mode, "standalone" (FLASH_ADDR set), produces a loader without any
# kernel that scans memory-mapped flash for a uImage. It is used by the
# Device/zyxel_zynos boards only and is not what this machine needs.

SUMMARY = "Realtek MIPS runtime loader (LZMA kernel loader) sources"
DESCRIPTION = "Small position independent boot loader for Realtek RTL83xx/RTL93xx \
MIPS switches. It decompresses an LZMA compressed kernel image and executes it. \
This recipe only stages the sources; rtl83xx-bootimage builds them together with \
the kernel payload."
HOMEPAGE = "https://github.com/openwrt/openwrt"
SECTION = "bootloaders"
LICENSE = "GPL-2.0-only & 0BSD"
LIC_FILES_CHKSUM = "file://${UNPACKDIR}/openwrt-${SRCREV}/COPYING;md5=a8db84c7a073d2878849eee8eb0f5daa \
                    file://include/nanoprintf.h;md5=811704d70176c65cda6ee7accc918d8b \
                    "

# OpenWrt master, pinned by commit
SRCREV = "234c308b93dc54b183525782d4529c890e3618cb"
PV = "1.0+git${SRCREV}"

SRC_URI = "https://github.com/openwrt/openwrt/archive/${SRCREV}.tar.gz"
SRC_URI[sha256sum] = "30a428632654768045110b94e871c41f50647f0691dd14cc1459c6f32b2d7f71"

# The src-uri-bad QA check rejects GitHub archive URLs because they are not
# guaranteed to be stable. That is acceptable here: the URL is pinned to a
# full commit SHA and the download is verified against SRC_URI[sha256sum],
# only fetching rt-loader from the huge OpenWrt repo without a git clone.
ERROR_QA:remove = "src-uri-bad"

# Only the rt-loader subdirectory of the OpenWrt tree is of interest
S = "${UNPACKDIR}/openwrt-${SRCREV}/target/linux/realtek/image/rt-loader"

# Plain MIPS assembly and C, not tied to a tune. The consumer compiles it.
inherit allarch nopackages

do_configure[noexec] = "1"
do_compile[noexec] = "1"

# ${datadir} is part of the default SYSROOT_DIRS, so this lands in the
# consumer's RECIPE_SYSROOT. The tree is copied verbatim because the upstream
# Makefile refers to include/ and linker/linker.ld relatively.
do_install() {
    install -d ${D}${datadir}/rt-loader
    cp -R --no-dereference --preserve=mode,timestamps ${S}/. ${D}${datadir}/rt-loader/
}
