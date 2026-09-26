# meta-rtl83xx-bsp

> **⚠️ Proof of concept.** This project is a proof of concept, created with
> the help of AI. It has not undergone thorough review or hardening, and
> should not be assumed suitable for production use.

Part of **Ethernet Switch OS**, see
[ethernet-switch-os](https://github.com/AlbrechtL/ethernet-switch-os).

Yocto BSP layer for Realtek RTL83xx switches (MIPS 4KEc, big endian). It is
the hardware side of Ethernet Switch OS: the kernel with the OpenWrt
drivers and device trees, the boot image for the original bootloader
(`rt-loader`, uImage), the flash layout, and a recipe for the
[rtl838x-qemu](https://github.com/AlbrechtL/rtl838x-qemu) emulator. It
boots to a shell on its own; the userspace comes from
[meta-ethernet-switch-os](https://github.com/AlbrechtL/meta-ethernet-switch-os).
The layer builds against any distro: the product uses
`ethernet-switch-os`, plain `poky-tiny` gives a BSP-only image.

## Documentation

**Installing, updating and trying it in QEMU is documented in the user
guide, which is the only place for that information:**

- [Zyxel GS1900-8](https://albrechtl.github.io/ethernet-switch-os/installation/zyxel-gs1900-8/):
  images, TFTP boot, first installation, flash layout, QEMU
- [Albrecht RTL8382MI test switch](https://albrechtl.github.io/ethernet-switch-os/installation/albrecht-rtl8382mi-test/)

For developers, [TECHNICAL.md](TECHNICAL.md) explains how the boot image is
built, how the kernel configuration is put together, and the traps found on
the way.

## Supported boards

| Board | SoC | `MACHINE` |
|---|---|---|
| Zyxel GS1900-8 A1, 8 ports, 128 MB RAM | RTL8380M | `zyxel-gs1900-8-a1` |
| Albrecht RTL8382MI test switch, 20 ports, 128 MB RAM (experimental) | RTL8382M | `albrecht-rtl8382mi-test` |

Settings shared by the whole SoC family live in
`conf/machine/include/rtl83xx.inc`; a machine `.conf` adds the device tree,
the uImage magic and the flash geometry. Another RTL83xx board is a new
`.conf` next to `zyxel-gs1900-8-a1.conf`. `rtl83xx` stays in
`MACHINEOVERRIDES` (via `SOC_FAMILY`), so family-wide recipes keep using
`COMPATIBLE_MACHINE = "^rtl83xx$"`.

## Building

Not built on its own: [ethernet-switch-os](https://github.com/AlbrechtL/ethernet-switch-os)
holds the build configuration and checks this layer out with kas, see
[Building the firmware](https://albrechtl.github.io/ethernet-switch-os/development/building/).
