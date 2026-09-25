# meta-rtl83xx-bsp

> **⚠️ Proof of concept.** This project is a proof of concept, created with
> the help of AI. It has not undergone thorough review or hardening, and
> should not be assumed suitable for production use.

Part of **Ethernet Switch OS**. See [ethernet-switch-os](https://github.com/AlbrechtL/ethernet-switch-os),

Yocto BSP layer for Realtek RTL83xx switches (MIPS 4KEc, big endian).
Supported boards:

| Board | SoC | `MACHINE` |
|---|---|---|
| Zyxel GS1900-8 A1, 8 ports, 128 MB RAM | RTL8380M | `zyxel-gs1900-8-a1` |
| Albrecht RTL8382MI test switch, 20 ports, 128 MB RAM (experimental) | RTL8382M | `albrecht-rtl8382mi-test` |

The examples below use the GS1900; the file names of the other board follow
the same pattern with its machine name. The layer builds against any distro; the
product uses `ethernet-switch-os`, and plain `poky-tiny` gives a BSP-only
image that boots to a shell.

Settings shared by the whole SoC family live in
`conf/machine/include/rtl83xx.inc`; a machine `.conf` adds the device tree,
the uImage magic and the flash geometry. Another RTL83xx board is a new
`.conf` next to `zyxel-gs1900-8-a1.conf`. `rtl83xx` stays in
`MACHINEOVERRIDES` (via `SOC_FAMILY`), so family-wide recipes keep using
`COMPATIBLE_MACHINE = "^rtl83xx$"`.

The layer is hardware-only: kernel, boot image, and flash layout. It boots to a
shell on its own.

See [TECHNICAL.md](TECHNICAL.md) for how the boot image is built, the kernel
configuration layout, and known traps/pitfalls.

## Images

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

## QEMU

`qemu-rtl838x-native` builds QEMU with the `rtl838x` machine from
[rtl838x-qemu](https://github.com/AlbrechtL/rtl838x-qemu), which emulates the
GS1900-8 closely enough to boot the TFTP image unchanged:

```
bitbake rtl838x-qemu-helper-native
qemu=$(ls tmp/work/x86_64-linux/rtl838x-qemu-helper-native/*/recipe-sysroot-native/usr/bin/qemu-system-mips-rtl838x)
$qemu -M rtl838x -m 128 -nographic -no-reboot \
    -kernel tmp/deploy/images/zyxel-gs1900-8-a1/ethernet-switch-os-initramfs-zyxel-gs1900-8-a1.bin
```

The recipe takes the QEMU release tarball that rtl838x-qemu pins as its
submodule and applies rtl838x-qemu's models and patch to it; the version in
its file name and `SRCREV_rtl838x` go together.
`rtl838x-qemu-helper-native` only gathers the emulator and its libraries into
a sysroot to run from. The binary is named `qemu-system-mips-rtl838x` so it
does not collide with oe-core's `qemu-system-native`. Every `-nic` becomes
the next front port, `lan1` first. There is no flash: only the initramfs
image works, and nothing survives a reboot.
ethernet-switch-os' `scripts/rtl838x-qemu` wraps all this, with networking.

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
