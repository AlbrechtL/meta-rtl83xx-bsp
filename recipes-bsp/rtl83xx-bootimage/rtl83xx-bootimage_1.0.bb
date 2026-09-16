# Self-extracting kernel image for Realtek RTL83xx switches.
#
# Replicates OpenWrt's Device/uimage-rt-loader pipeline from
# target/linux/realtek/image/Makefile:
#
#     kernel-bin | append-dtb | rt-compress | rt-loader | uImage none
#
# 1. kernel-bin    the raw kernel binary, here KERNEL_IMAGETYPE = "vmlinux.bin"
# 2. append-dtb    cat the DTB onto the *uncompressed* binary. It lands exactly
#                  on __appended_dtb (arch/mips/kernel/vmlinux.lds.S), which
#                  requires CONFIG_MIPS_RAW_APPENDED_DTB=y.
# 3. rt-compress   xz --format=lzma, i.e. LZMA-alone with an unknown size field
#                  and an end-of-stream marker. rt-loader's unlzma expects this
#                  form; the "lzma" tool's sized variant will not do.
# 4. rt-loader     objcopy the LZMA stream into a .kernel section and link it
#                  into the position independent loader (piggy-back mode).
# 5. uImage none   legacy U-Boot header, compression "none" because what U-Boot
#                  sees is the loader, not a compressed kernel.
#
# Two kernels go through this pipeline:
#
#   initramfs  vmlinux.bin-initramfs-*, the TFTP boot/installer image
#   flash      vmlinux.bin-*, without initramfs; its uImage is the head of the
#              "firmware" partition (image_types_rtl83xx.bbclass appends the
#              squashfs behind it)
#
# and two loader variants are produced from the initramfs payload:
#
#   *-rt-loader.bin  built with KERNEL_ADDR=${RTL_LOADADDR}, so the loader may
#                    be started from any address ("go") and still decompresses
#                    the kernel to its fixed link address.
#   *.bin            uImage, built without KERNEL_ADDR, so the loader adopts
#                    its own run address; U-Boot's bootm places it at
#                    RTL_LOADADDR.
#
# The flash kernel only needs the uImage variant.
#
# The recipe post-processes artifacts published by the kernel's do_deploy, the
# same way oe-core's kernel-fit-image.bbclass does.

SUMMARY = "rt-loader wrapped, LZMA compressed kernel image for RTL83xx"
DESCRIPTION = "Assembles the deployed kernel binary and device tree into a \
self-extracting image that the stock Realtek bootloader can TFTP and start."
SECTION = "bootloaders"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

inherit linux-kernel-base kernel-artifact-names deploy nopackages

COMPATIBLE_MACHINE = "^rtl83xx$"
PACKAGE_ARCH = "${MACHINE_ARCH}"
EXCLUDE_FROM_WORLD = "1"

DEPENDS += "rt-loader xz-native u-boot-tools-native"

SRC_URI = "file://uimage-setmagic.py"

S = "${UNPACKDIR}"
B = "${WORKDIR}/build"

do_configure[noexec] = "1"

# Name the artifacts after the kernel they carry, not after this recipe.
PKGV = "${@get_kernelversion_file("${STAGING_KERNEL_BUILDDIR}")}"

# The kernel binary and DTB are read out of DEPLOY_DIR_IMAGE.
do_compile[depends] += "virtual/kernel:do_deploy"

RTL_LOADADDR ?= "0x80100000"
RTL_UIMAGE_MAGIC ?= "0x83800000"
RTL_KERNEL_BIN ?= "vmlinux.bin-initramfs-${MACHINE}.bin"
RTL_KERNEL_BIN_FLASH ?= "vmlinux.bin-${MACHINE}.bin"
# mkimage truncates ih_name at 32 bytes, so drop the kernel type suffix that
# PKGV carries ("6.18.39-yocto-tiny" -> "6.18.39").
RTL_UIMAGE_NAME ?= "MIPS ${DISTRO} Linux-${@d.getVar('PKGV').split('-')[0]}"

# The upstream Makefile hard-sets CC with ':=' and CFLAGS with '=', so the
# toolchain flags Yocto exports through the environment are dropped and the
# compiler cannot find the (freestanding) headers. Pass CC explicitly on the
# make command line -- command-line assignments override ':=' -- pointing gcc
# at the recipe sysroot plus the tune arguments.
RT_LOADER_CC = "${TARGET_PREFIX}gcc --sysroot=${STAGING_DIR_TARGET} ${TUNE_CCARGS}"

# Build one rt-loader variant. $1 = work directory holding kernel-dtb.lzma and
# the rt-loader sources, $2 = output name, remaining args go to make.
rtl_build_loader() {
    dir="$1"
    out="$2"
    shift 2
    oe_runmake -C $dir/rt-loader all \
        CROSS_COMPILE=${TARGET_PREFIX} \
        "CC=${RT_LOADER_CC}" \
        KERNEL_IMG_IN=$dir/kernel-dtb.lzma \
        KERNEL_IMG_OUT=$dir/$out.bin \
        BUILD_DIR=$dir/$out.build \
        "$@"
}

# Run the whole pipeline for one kernel. $1 = kernel binary in
# DEPLOY_DIR_IMAGE, $2 = work directory below ${B}. Produces $dir/uImage, and
# $dir/rtl-loader.bin as well when $3 is "raw".
rtl_build_bootimage() {
    kernel="${DEPLOY_DIR_IMAGE}/$1"
    dir="${B}/$2"
    dtb="${DEPLOY_DIR_IMAGE}/${RTL_DTB}"

    for f in "$kernel" "$dtb"; do
        [ -f "$f" ] || bbfatal "missing kernel artifact: $f"
    done

    rm -rf $dir
    mkdir -p $dir

    # 2. append-dtb, onto the uncompressed binary
    cat "$kernel" "$dtb" > $dir/kernel-dtb.bin

    # 3. rt-compress
    xz -9 --format=lzma --stdout $dir/kernel-dtb.bin > $dir/kernel-dtb.lzma

    # 4. rt-loader. The Makefile uses relative -Iinclude and -T linker/linker.ld,
    #    so it has to run with its own directory as cwd (make -C does that).
    cp -R ${RECIPE_SYSROOT}${datadir}/rt-loader $dir/rt-loader

    if [ "$3" = "raw" ]; then
        rtl_build_loader $dir rtl-loader KERNEL_ADDR=${RTL_LOADADDR}
    fi
    rtl_build_loader $dir rt-loader-uimage

    # 5. uImage. oe-core's mkimage has no -M option (that is an OpenWrt patch),
    #    so write a standard header and rewrite the magic afterwards.
    # mkimage stamps ih_time from SOURCE_DATE_EPOCH when it is set, which would
    # pin every image to the reproducible-build epoch and make builds
    # indistinguishable in the bootloader's "Created:" line. Use the real time.
    env -u SOURCE_DATE_EPOCH \
    uboot-mkimage -A mips -O linux -T kernel -C none \
        -a ${RTL_LOADADDR} -e ${RTL_LOADADDR} \
        -n "${RTL_UIMAGE_NAME}" \
        -d $dir/rt-loader-uimage.bin $dir/uImage
    python3 ${UNPACKDIR}/uimage-setmagic.py $dir/uImage ${RTL_UIMAGE_MAGIC}
}

do_compile() {
    rtl_build_bootimage ${RTL_KERNEL_BIN} initramfs raw
    rtl_build_bootimage ${RTL_KERNEL_BIN_FLASH} flash
}

do_deploy() {
    install -d ${DEPLOYDIR}

    install -m 0644 ${B}/initramfs/rtl-loader.bin \
        ${DEPLOYDIR}/${RTL_IMAGE_BASENAME}-${INITRAMFS_NAME}-rt-loader${KERNEL_IMAGE_BIN_EXT}
    install -m 0644 ${B}/initramfs/uImage \
        ${DEPLOYDIR}/${RTL_IMAGE_BASENAME}-${INITRAMFS_NAME}${KERNEL_IMAGE_BIN_EXT}
    install -m 0644 ${B}/flash/uImage \
        ${DEPLOYDIR}/${RTL_IMAGE_BASENAME}-kernel-${KERNEL_IMAGE_NAME}${KERNEL_IMAGE_BIN_EXT}

    if [ -n "${INITRAMFS_LINK_NAME}" ]; then
        ln -sf ${RTL_IMAGE_BASENAME}-${INITRAMFS_NAME}-rt-loader${KERNEL_IMAGE_BIN_EXT} \
            ${DEPLOYDIR}/${RTL_IMAGE_BASENAME}-${INITRAMFS_LINK_NAME}-rt-loader${KERNEL_IMAGE_BIN_EXT}
        ln -sf ${RTL_IMAGE_BASENAME}-${INITRAMFS_NAME}${KERNEL_IMAGE_BIN_EXT} \
            ${DEPLOYDIR}/${RTL_IMAGE_BASENAME}-${INITRAMFS_LINK_NAME}${KERNEL_IMAGE_BIN_EXT}
    fi
    # Read back by image_types_rtl83xx as the head of the "firmware" partition,
    # so this name has to be exactly RTL_FLASH_UIMAGE.
    ln -sf ${RTL_IMAGE_BASENAME}-kernel-${KERNEL_IMAGE_NAME}${KERNEL_IMAGE_BIN_EXT} \
        ${DEPLOYDIR}/${RTL_FLASH_UIMAGE}
}
addtask deploy after do_compile before do_build
