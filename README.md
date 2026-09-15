# meta-rtl83xx-bsp

Yocto BSP layer for Realtek RTL83xx switches. Current target: **Zyxel GS1900-8 A1**
(RTL8380M, MIPS 4KEc, 128 MB RAM, big endian).

`MACHINE = "rtl83xx"`, `DISTRO = "poky-tiny"`.

The layer is hardware-only: kernel, boot image, and flash layout. It boots to a
shell on its own. Networking, management (clixon/RESTCONF), SSH and SWUpdate
live in the sibling `meta-rtl83xx-distro` layer.

See [TECHNICAL.md](TECHNICAL.md) for how the boot image is built, the kernel
configuration layout, and known traps/pitfalls.

## Building the images

```sh
cd build
bitbake rtl83xx-bootimage                        # TFTP boot image
bitbake rtl83xx-swu-factory rtl83xx-swu-upgrade  # SWUpdate packages
```

The `.swu` recipes live in `meta-rtl83xx-distro`, so that layer is required for
the second command. They pull in `rtl83xx-image` and `rtl83xx-bootimage`
automatically, so the second command alone builds everything.

Output lands in `build/tmp/deploy/images/rtl83xx/`. The names below are the
stable symlinks; each points to a timestamped file next to it.

| File | Built by | What it is for |
|---|---|---|
| **`uImage-initramfs-rtl83xx.bin`** | `rtl83xx-bootimage` | TFTP boot with `bootm`. Kernel with the initramfs bundled in, runs entirely from RAM. Used for the first install and for recovery. |
| **`rtl-loader-initramfs-rtl83xx.bin`** | `rtl83xx-bootimage` | Same payload without the uImage header. TFTP boot with `go`. |
| **`rtl83xx-swu-factory-rtl83xx.swu`** | `rtl83xx-swu-factory` | First install, uploaded from the TFTP initramfs. Writes `firmware` and wipes `data`. |
| **`rtl83xx-swu-upgrade-rtl83xx.swu`** | `rtl83xx-swu-upgrade` | Update of a flashed system. Rewrites `firmware`, keeps `data`. |
| `uImage-rtl83xx.bin` | `rtl83xx-bootimage` | Flash kernel, no initramfs. The head of the `firmware` partition. |
| `rtl83xx-image-rtl83xx.rootfs.rtl83xx-fw` | `rtl83xx-image` | `firmware` partition content: `uImage-rtl83xx.bin`, padded to 64k, then the squashfs. Inside both `.swu`. |
| `rtl83xx-image-rtl83xx.rootfs.rtl83xx-data` | `rtl83xx-image` | Empty JFFS2 filling the whole `data` partition. Inside the factory `.swu`. |
| `rtl83xx-image-rtl83xx.rootfs.squashfs-xz` | `rtl83xx-image` | Flash root filesystem. |
| `rtl83xx-image-initramfs-rtl83xx.cpio.gz` | `rtl83xx-image-initramfs` | Initramfs bundled into the TFTP kernel. |
| `vmlinux.bin-initramfs-rtl83xx.bin`, `vmlinux.bin-rtl83xx.bin` | `virtual/kernel` | Raw kernels, before compression and rt-loader. |
| `rtl8380_zyxel_gs1900-8-a1.dtb` | `virtual/kernel` | Device tree, appended to the kernel. |

The files in bold are the ones you use; the rest are intermediate artifacts.

## TFTP boot

Serial console is 115200 8N1.

```
rtk network on
tftpboot 0x84f00000 192.168.1.12:uImage-initramfs-rtl83xx.bin
bootm 0x84f00000
```

Pass the address to `bootm` explicitly; bare `bootm` uses `$loadaddr`. Do not
use `0x8f000000` or higher — that is past the end of RAM.

The alternative, if you prefer the headerless blob:

```
tftpboot 0x84f00000 192.168.1.12:rtl-loader-initramfs-rtl83xx.bin
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

1. TFTP-boot `uImage-initramfs-rtl83xx.bin` (see above).
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
