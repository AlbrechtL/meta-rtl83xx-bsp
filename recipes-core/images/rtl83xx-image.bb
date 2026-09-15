# Flashable image: a squashfs root behind the flash kernel in the "firmware"
# partition, with a writable JFFS2 overlay from the "data" partition
# (image_types_rtl83xx.bbclass, conf/machine/rtl83xx.conf).
#
# Same base package set as rtl83xx-image-initramfs. The distro layer adds its
# userspace to both images from one shared include.

SUMMARY = "Flashable squashfs image for RTL83xx switches"

IMAGE_INSTALL = " \
    packagegroup-core-boot \
    rtl83xx-overlay-init \
    rtl83xx-ubootenv-config \
    ${CORE_IMAGE_EXTRA_INSTALL} \
"

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

COMPATIBLE_MACHINE = "^rtl83xx$"

# The kernel is not part of the rootfs; it sits in front of it, in the uImage.
PACKAGE_EXCLUDE = "kernel-image-*"

# rtl83xx-fw pulls in squashfs-xz through IMAGE_TYPEDEP. No read-only-rootfs
# feature: overlay-init makes / writable before busybox init runs.
IMAGE_FSTYPES = "squashfs-xz rtl83xx-fw rtl83xx-data"

# 256k blocks compress a little better than mksquashfs' 128k default; RAM
# for the block cache is not the constraint on this board, flash is.
EXTRA_IMAGECMD:squashfs-xz = "-b 262144"

# overlay-init mounts /var/volatile itself and creates log/ and tmp/ in it.
# Left in fstab, "mount -a" would stack an empty tmpfs over those directories.
rtl83xx_drop_volatile_fstab() {
    sed -i '\#[[:space:]]/var/volatile[[:space:]]#d' ${IMAGE_ROOTFS}${sysconfdir}/fstab
}
ROOTFS_POSTPROCESS_COMMAND += "rtl83xx_drop_volatile_fstab;"

# The kernel has already mounted devtmpfs on /dev (CONFIG_DEVTMPFS_MOUNT), and
# overlay-init moves it into the overlay root, or leaves it in place if there
# is no overlay. Mounting it again on the same spot fails:
#   mount: mounting devtmpfs on /dev failed: Resource busy
# The initramfs keeps the line; /dev is empty there.
rtl83xx_drop_devtmpfs_inittab() {
    sed -i '\#^::sysinit:/bin/mount -t devtmpfs devtmpfs /dev$#d' ${IMAGE_ROOTFS}${sysconfdir}/inittab
}
ROOTFS_POSTPROCESS_COMMAND += "rtl83xx_drop_devtmpfs_inittab;"
