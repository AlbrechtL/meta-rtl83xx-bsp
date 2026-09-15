# Initramfs bundled into the kernel (INITRAMFS_IMAGE in conf/machine/rtl83xx.conf).
#
# Identical package set to core-image-minimal, but a separate recipe on
# purpose: using the main image as the initramfs creates a dependency loop,
# because EXTRA_IMAGEDEPENDS makes that image depend on rtl83xx-bootimage,
# which depends on the kernel, which in turn depends on its initramfs image.
#
# IMAGE_CMD:cpio adds the /init -> /sbin/init symlink automatically, so no
# init-framework package is needed.

SUMMARY = "Initramfs for RTL83xx switches, bundled into the kernel"

# rtl83xx-ubootenv-config: fw_printenv/fw_setenv on the U-Boot environment,
# e.g. to check it before a factory install.
IMAGE_INSTALL = "packagegroup-core-boot rtl83xx-ubootenv-config ${CORE_IMAGE_EXTRA_INSTALL}"

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

# image.bbclass turns EXTRA_IMAGEDEPENDS into a do_image_complete dependency
# for *every* image, which would make this one wait for rtl83xx-bootimage and
# close the loop described above. The initramfs needs none of it.
EXTRA_IMAGEDEPENDS = ""

# An initramfs must never contain a kernel.
PACKAGE_EXCLUDE = "kernel-image-*"

# kernel.bbclass copy_initramfs() gunzips this back to a plain cpio for
# CONFIG_INITRAMFS_SOURCE.
IMAGE_FSTYPES = "cpio.gz"

# copy_initramfs() looks for INITRAMFS_IMAGE_NAME, which is built as
# "${INITRAMFS_IMAGE}${IMAGE_MACHINE_SUFFIX}" and carries no IMAGE_NAME_SUFFIX
# (image-artifact-names.bbclass). Drop the default ".rootfs" so the deployed
# file name matches. Same as oe-core's core-image-minimal-initramfs.
IMAGE_NAME_SUFFIX ?= ""

IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "", d)}"

# devtmpfs_mount() is only ever called from prepare_namespace()
# (init/do_mounts.c), i.e. the real-root path -- it never runs for an
# initramfs. /dev is therefore empty when the kernel execs init, which it
# reports as "Warning: unable to open an initial console". busybox' inittab
# mounts devtmpfs a moment later, so this only covers the gap before that.
# Image tasks run under pseudo, so mknod succeeds.
add_initramfs_console_node() {
    mkdir -p ${IMAGE_ROOTFS}/dev
    [ -e ${IMAGE_ROOTFS}/dev/console ] || mknod -m 0622 ${IMAGE_ROOTFS}/dev/console c 5 1
}
ROOTFS_POSTPROCESS_COMMAND += "add_initramfs_console_node;"

# The initramfs is the root filesystem; there is no root block device. The
# stock fstab's /dev/root line makes "mount -a" and mountall.sh fail:
#   /dev/root: Can't lookup blockdev
#   mount: mounting /dev/root on / failed: No such file or directory
rtl83xx_drop_root_fstab() {
    sed -i '\#^/dev/root[[:space:]]#d' ${IMAGE_ROOTFS}${sysconfdir}/fstab
}
ROOTFS_POSTPROCESS_COMMAND += "rtl83xx_drop_root_fstab;"
