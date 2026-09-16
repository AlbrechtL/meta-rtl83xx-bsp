# Settings shared by every Realtek RTL83xx switch. A machine .conf next to this
# file requires it and adds what is board specific: the device tree, the uImage
# magic the stock bootloader expects, and the flash geometry.

# Puts "rtl83xx" into MACHINEOVERRIDES, so recipes can keep using
# COMPATIBLE_MACHINE = "^rtl83xx$" and :rtl83xx overrides for the whole family
# instead of naming every board.
SOC_FAMILY = "rtl83xx"
require conf/machine/include/soc-family.inc

require conf/machine/include/mips/tune-mips-24k.inc

TARGET_ARCH = "mips"
# 24kc, NOT 24kec: the "e" variant adds -mdsp, and GCC then emits DSP-ASE
# instructions (lbux/lwx/insv/...). The RTL8380 core has no DSP ASE -- the DT
# calls it "mips,mips4KEc" and OpenWrt builds this target with CPU_TYPE:=24kc --
# so those trap as Reserved Instruction and the image dies silently, before
# rt-loader can print its banner.
DEFAULTTUNE = "mips32r2-24kc"

PREFERRED_PROVIDER_virtual/kernel = "linux-yocto-tiny"

# -----------------------------------------------------------------------------
# Kernel artifacts
# -----------------------------------------------------------------------------
# "vmlinux.bin" is a real MIPS kbuild target (arch/mips/Makefile: boot-y) that
# runs objcopy -O binary over vmlinux. It is the equivalent of OpenWrt's
# "kernel-bin" build step and is what rt-loader has to compress. Using it as a
# KERNEL_IMAGETYPE means it flows through the standard do_compile/do_install/
# do_deploy path, including the .initramfs variant produced by
# do_bundle_initramfs.
KERNEL_IMAGETYPE = "vmlinux.bin"

# -----------------------------------------------------------------------------
# Initramfs
# -----------------------------------------------------------------------------
# Bundle the rootfs into the kernel (CONFIG_INITRAMFS_SOURCE), which is the
# direct analogue of OpenWrt's vmlinux-initramfs. rt-loader carries exactly one
# payload, so the rootfs has to live inside the kernel image.
#
# This has to be an image that is not itself built via EXTRA_IMAGEDEPENDS
# below, otherwise kernel -> initramfs image -> rtl83xx-bootimage -> kernel
# closes a dependency loop. rtl83xx-image-initramfs has the same package set
# as core-image-minimal.
INITRAMFS_IMAGE = "rtl83xx-image-initramfs"
INITRAMFS_IMAGE_BUNDLE = "1"

SERIAL_CONSOLES = "115200;ttyS0"

# Headless: the only console is the serial port. busybox-inittab defaults
# USE_VT ?= "1" and then adds a "getty 38400 tty1" line, but OpenWrt's config
# leaves CONFIG_VT off (rightly -- these boards have no VT), so /dev/tty1 never
# exists and init respawns that getty forever:
#   can't open /dev/tty1: No such file or directory
USE_VT = "0"

# Print the real build date in the kernel banner. Without this kernel.bbclass
# pins KBUILD_BUILD_TIMESTAMP to the kernel's last git commit date for
# reproducibility, which makes every build look identical on the console.
KERNEL_DEBUG_TIMESTAMPS = "1"

# The boards have no RTC and the shared kernel config is built without
# RTC_CLASS. The "rtc" default machine feature would add busybox-hwclock to
# packagegroup-core-boot, whose hwclock.sh then fails on every boot:
#   hwclock: can't open '/dev/misc/rtc': No such file or directory
MACHINE_FEATURES_OPTED_OUT += "rtc"

# -----------------------------------------------------------------------------
# rt-loader / boot image
# -----------------------------------------------------------------------------
# Load and entry address of the kernel, from OpenWrt
# target/linux/realtek/image/Makefile: KERNEL_LOADADDR = 0x80100000.
# KERNEL_ENTRY is not set upstream, so entry == load.
RTL_LOADADDR ?= "0x80100000"

EXTRA_IMAGEDEPENDS += "rtl83xx-bootimage"

# -----------------------------------------------------------------------------
# Deployed image names
# -----------------------------------------------------------------------------
# The BSP boots on its own, so the artifacts are named after whatever distro
# built them rather than after a layer the BSP does not depend on. With
# meta-ethernet-switch-os that reads
#
#   ethernet-switch-os-initramfs-<machine>.bin           TFTP boot / installer
#   ethernet-switch-os-initramfs-<machine>-rt-loader.bin same, no uImage header
#   ethernet-switch-os-kernel-<machine>.bin              flash kernel
#
# RTL_FLASH_UIMAGE is set here, not in the recipe, because both
# rtl83xx-bootimage (which deploys the file) and image_types_rtl83xx (which
# reads it back) need the same name, and the image recipe does not inherit
# kernel-artifact-names. ".bin" is KERNEL_IMAGE_BIN_EXT's default, spelled out
# for the same reason.
RTL_IMAGE_BASENAME ?= "${DISTRO}"
RTL_FLASH_UIMAGE ?= "${RTL_IMAGE_BASENAME}-kernel-${MACHINE}.bin"

IMAGE_CLASSES += "image_types_rtl83xx"
