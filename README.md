# meta-rtl83xx-bsp

> **⚠️ Proof of concept.** This project is a proof of concept, created with
> the help of AI. It has not undergone thorough review or hardening, and
> should not be assumed suitable for production use.

Part of **Ethernet Switch OS**. The build lives in
[ethernet-switch-os](https://github.com/AlbrechtL/ethernet-switch-os), which
checks this layer out with [kas](https://kas.readthedocs.io/) and builds the
images. The other pieces are
[meta-ethernet-switch-os](https://github.com/AlbrechtL/meta-ethernet-switch-os)
(the distro and userspace),
[clixon-switch-rs](https://github.com/AlbrechtL/clixon-switch-rs) (its backend
plugin) and [rtl838x-qemu](https://github.com/AlbrechtL/rtl838x-qemu), which
emulates an RTL838x well enough to boot these images and switch real frames
between eight ports.

Yocto BSP layer for Realtek RTL83xx switches. Supported board: **Zyxel GS1900-8 A1**
(RTL8380M, MIPS 4KEc, 128 MB RAM, big endian).

`MACHINE = "zyxel-gs1900-8-a1"`. The layer builds against any distro; the
product uses `ethernet-switch-os`, and plain `poky-tiny` gives a BSP-only
image that boots to a shell.

Settings shared by the whole SoC family live in
`conf/machine/include/rtl83xx.inc`; a machine `.conf` adds the device tree,
the uImage magic and the flash geometry. Another RTL83xx board is a new
`.conf` next to `zyxel-gs1900-8-a1.conf`. `rtl83xx` stays in
`MACHINEOVERRIDES` (via `SOC_FAMILY`), so family-wide recipes keep using
`COMPATIBLE_MACHINE = "^rtl83xx$"`.

The layer is hardware-only: kernel, boot image, and flash layout. It boots to a
shell on its own. Networking, management (clixon/RESTCONF), SSH and SWUpdate
live in the sibling `meta-ethernet-switch-os` layer.

See [TECHNICAL.md](TECHNICAL.md) for how the boot image is built, the kernel
configuration layout, and known traps/pitfalls.

## Building the images

```sh
git clone https://github.com/AlbrechtL/ethernet-switch-os
cd ethernet-switch-os
make container      # the development image, once
make build          # = bitbake ethernet-switch-os-swu-factory ethernet-switch-os-swu-upgrade
```

That is the whole build: kas checks this layer out into
`layers/meta-rtl83xx-bsp` as an ordinary clone of `master`, alongside
openembedded-core and the rest, and selects the machine. Which board is built
is one file there, `kas/board/zyxel-gs1900-8-a1.yml`; a second RTL83xx board
needs a `.conf` here and a copy of that file.

Inside `make shell`, individual targets work as usual:

```sh
bitbake rtl83xx-bootimage    # TFTP boot image, this layer alone
```

The `.swu` recipes live in `meta-ethernet-switch-os`, and pull in
`rtl83xx-image` and `rtl83xx-bootimage` automatically, so building them alone
builds everything.

Output lands in `build/tmp/deploy/images/zyxel-gs1900-8-a1/`. The names below are
the stable symlinks; each points to a timestamped file next to it.

The boot images are named after the distro that built them
(`RTL_IMAGE_BASENAME`, default `${DISTRO}`), so a BSP-only `poky-tiny` build
produces `poky-tiny-initramfs-...` instead. The names below are what
`meta-ethernet-switch-os` produces.

| File | Built by | What it is for |
|---|---|---|
| **`ethernet-switch-os-initramfs-zyxel-gs1900-8-a1.bin`** | `rtl83xx-bootimage` | TFTP boot with `bootm`. Kernel with the initramfs bundled in, runs entirely from RAM. Used for the first install and for recovery. |
| **`ethernet-switch-os-initramfs-zyxel-gs1900-8-a1-rt-loader.bin`** | `rtl83xx-bootimage` | Same payload without the uImage header. TFTP boot with `go`. |
| **`ethernet-switch-os-swu-factory-zyxel-gs1900-8-a1.swu`** | `ethernet-switch-os-swu-factory` | First install, uploaded from the TFTP initramfs. Writes `firmware` and wipes `data`. |
| **`ethernet-switch-os-swu-upgrade-zyxel-gs1900-8-a1.swu`** | `ethernet-switch-os-swu-upgrade` | Update of a flashed system. Rewrites `firmware`, keeps `data`. |
| `ethernet-switch-os-kernel-zyxel-gs1900-8-a1.bin` | `rtl83xx-bootimage` | Flash kernel, no initramfs. The head of the `firmware` partition (`RTL_FLASH_UIMAGE`). |
| `rtl83xx-image-zyxel-gs1900-8-a1.rootfs.rtl83xx-fw` | `rtl83xx-image` | `firmware` partition content: the flash kernel, padded to 64k, then the squashfs. Inside both `.swu`. |
| `rtl83xx-image-zyxel-gs1900-8-a1.rootfs.rtl83xx-data` | `rtl83xx-image` | Empty JFFS2 filling the whole `data` partition. Inside the factory `.swu`. |
| `rtl83xx-image-zyxel-gs1900-8-a1.rootfs.squashfs-xz` | `rtl83xx-image` | Flash root filesystem. |
| `rtl83xx-image-initramfs-zyxel-gs1900-8-a1.cpio.gz` | `rtl83xx-image-initramfs` | Initramfs bundled into the TFTP kernel. |
| `vmlinux.bin-initramfs-zyxel-gs1900-8-a1.bin`, `vmlinux.bin-zyxel-gs1900-8-a1.bin` | `virtual/kernel` | Raw kernels, before compression and rt-loader. |
| `rtl8380_zyxel_gs1900-8-a1.dtb` | `virtual/kernel` | Device tree, appended to the kernel. |

The files in bold are the ones you use; the rest are intermediate artifacts.

## TFTP boot

Serial console is 115200 8N1.

```
rtk network on
tftpboot 0x84f00000 192.168.1.12:ethernet-switch-os-initramfs-zyxel-gs1900-8-a1.bin
bootm 0x84f00000
```

Pass the address to `bootm` explicitly; bare `bootm` uses `$loadaddr`. Do not
use `0x8f000000` or higher — that is past the end of RAM.

The alternative, if you prefer the headerless blob:

```
tftpboot 0x84f00000 192.168.1.12:ethernet-switch-os-initramfs-zyxel-gs1900-8-a1-rt-loader.bin
go 0x84f00000
```

The two files are **not** interchangeable — `bootm` on the raw blob gives
`Bad Header Checksum`, because that variant deliberately has no uImage header.

## Flash image

Layout of the 16 MiB SPI-NOR:

| Offset | Partition | Size | Content |
|---|---|---|---|
| `0x000000` | `u-boot` | 256k | read-only, never written |
| `0x040000` | `u-boot-env` | 64k | |
| `0x050000` | `u-boot-env2` | 64k | `bootpartition`: must be `0` |
| `0x060000` | `data` | 2M | JFFS2, overlay upper layer, kept on upgrade |
| `0x260000` | `firmware` | 13952k | uImage, padded to 64k, then squashfs |

There is no A/B slot: an upgrade rewrites the running firmware in place.

### Install and upgrade

1. TFTP-boot `ethernet-switch-os-initramfs-zyxel-gs1900-8-a1.bin` (see above).
2. Check that U-Boot boots slot 0. `bootpartition` lives in the second
   environment, which `/etc/fw_env.config` deliberately does not list, so read
   it explicitly:

   ```sh
   echo '/dev/mtd2 0x0 0x1000 0x10000' > /tmp/env2.config
   fw_printenv -c /tmp/env2.config bootpartition   # must print bootpartition=0
   ```

3. Upload the factory `.swu` at http://192.168.1.1:8080. It writes `firmware`
   and wipes `data`. It does not touch either U-Boot environment.
4. Reboot. U-Boot now boots from flash.

Later updates: upload the upgrade `.swu` to the running flash system. The
board reboots by itself. If an upgrade is interrupted, TFTP-boot the
initramfs again and repeat the factory install.

## Recipes

| Recipe | Role |
|---|---|
| `recipes-bsp/rt-loader/rt-loader_git.bb` | stages the loader **sources**; does not compile |
| `recipes-bsp/rtl83xx-bootimage/` | compresses, links the loader around the kernel, wraps in uImage |
| `recipes-core/images/rtl83xx-image-initramfs.bb` | the TFTP-bootable rootfs |
| `recipes-core/images/rtl83xx-image.bb` | the flashable rootfs (squashfs + JFFS2 overlay) |
| `recipes-core/rtl83xx-overlay-init/` | pivots the flash rootfs onto a JFFS2 overlay |
| `recipes-bsp/rtl83xx-ubootenv-config/` | `/etc/fw_env.config` for the main U-Boot environment |
| `classes-recipe/image_types_rtl83xx.bbclass` | the `rtl83xx-fw` and `rtl83xx-data` image types |
| `recipes-kernel/linux/linux-yocto-tiny_%.bbappend` | patches, defconfig, kernel metadata fragments |
