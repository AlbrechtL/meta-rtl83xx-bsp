# meta-rtl83xx-bsp

Yocto BSP layer for Realtek RTL83xx switches. Current target: **Zyxel GS1900-8 A1**
(RTL8380M, MIPS 4KEc, 128 MB RAM, big endian).

`MACHINE = "rtl83xx"`, `DISTRO = "poky-tiny"`.

## Build

```sh
cd build
bitbake rtl83xx-bootimage
```

`EXTRA_IMAGEDEPENDS` also pulls it into `bitbake core-image-minimal`.

Artifacts land in `tmp/deploy/images/rtl83xx/`:

| File | Use |
|---|---|
| `uImage-initramfs-rtl83xx.bin` | legacy U-Boot image — boot with `bootm` |
| `rtl-loader-initramfs-rtl83xx.bin` | same payload, no header — start with `go` |
| `vmlinux.bin-initramfs-rtl83xx.bin` | raw kernel with the initramfs bundled in |
| `rtl8380_zyxel_gs1900-8-a1.dtb` | device tree |

## TFTP boot

Serial console is 115200 8N1.

```
rtk network on
tftpboot 0x84f00000 192.168.1.12:uImage-initramfs-rtl83xx.bin
bootm 0x84f00000
```

Pass the address to `bootm` explicitly; bare `bootm` uses `$loadaddr`.

The alternative, if you prefer the headerless blob:

```
tftpboot 0x84f00000 192.168.1.12:rtl-loader-initramfs-rtl83xx.bin
go 0x84f00000
```

The two files are **not** interchangeable — `bootm` on the raw blob gives
`Bad Header Checksum`, because that variant deliberately has no uImage header.

### Choosing a staging address

RAM is 128 MB, and KSEG0 maps `0x80000000` + physical, so valid addresses stop
at `0x88000000`. `0x84f00000` is safe. **Do not use `0x8f000000`** — it is past
the end of RAM.

Nothing collides at `0x84f00000`: `bootm` copies the payload to `0x80100000`,
the kernel decompresses to `0x80100000`–`0x807a0000`, and rt-loader relocates
itself to roughly `0x87d90000`.

## How the image is put together

This mirrors OpenWrt's `Device/uimage-rt-loader`
(`target/linux/realtek/image/Makefile`), which for the GS1900 expands to:

```
kernel-bin | append-dtb | rt-compress | rt-loader | uImage none
```

| Step | Here |
|---|---|
| `kernel-bin` | `KERNEL_IMAGETYPE = "vmlinux.bin"`, a real MIPS kbuild target |
| `append-dtb` | `cat dtb >> vmlinux.bin` in `rtl83xx-bootimage` |
| `rt-compress` | `xz -9 --format=lzma` |
| `rt-loader` | `make -C rt-loader KERNEL_IMG_IN=...` (piggy-back mode) |
| `uImage none` | `uboot-mkimage` + `uimage-setmagic.py` |

Addresses: load = entry = `0x80100000`, uImage magic = `0x83800000`. Both come
from `conf/machine/rtl83xx.conf` (`RTL_LOADADDR`, `RTL_UIMAGE_MAGIC`).

Two loader variants are built from one payload. The raw one is compiled with
`KERNEL_ADDR=0x80100000` so it can be started from anywhere; the uImage one
without, so it adopts its own run address (which `bootm` sets to `0x80100000`).

### Why the DTB is appended before compression

`CONFIG_MIPS_RAW_APPENDED_DTB=y`. The linker reserves `__appended_dtb` at the
very end of the loadable image (`arch/mips/kernel/vmlinux.lds.S`), so
concatenating the DTB onto the *uncompressed* `vmlinux.bin` puts the FDT exactly
on that symbol. Appending it to the LZMA stream instead would not work.

Check it holds after a kernel change:

```sh
awk '$3=="_text"||$3=="__appended_dtb"{print}' .../linux-rtl83xx-tiny-build/System.map
stat -Lc%s tmp/deploy/images/rtl83xx/vmlinux.bin-initramfs-rtl83xx.bin
```

`__appended_dtb - _text` must equal the file size.

### Why mkimage needs a post-processing step

The stock bootloader and the in-kernel `mtdsplit_uimage` parser expect magic
`0x83800000`, not the standard `0x27051956`. OpenWrt gets this from a local
mkimage patch adding `-M`; oe-core ships unpatched u-boot-tools, so
`recipes-bsp/rtl83xx-bootimage/files/uimage-setmagic.py` rewrites `ih_magic` and
recomputes `ih_hcrc` on the finished 64-byte header.

## Recipes

| Recipe | Role |
|---|---|
| `recipes-bsp/rt-loader/rt-loader_git.bb` | stages the loader **sources** to `${datadir}/rt-loader`; does not compile |
| `recipes-bsp/rtl83xx-bootimage/` | compresses, links the loader around the kernel, wraps in uImage |
| `recipes-core/images/rtl83xx-image-initramfs.bb` | the bundled rootfs |
| `recipes-kernel/linux/linux-yocto-tiny_%.bbappend` | patches, defconfig, config fragment |

rt-loader is deliberately split: piggy-back mode needs the compressed kernel at
link time, so the loader can only be built after the kernel exists.

The initramfs is a separate recipe from `core-image-minimal` on purpose.
`EXTRA_IMAGEDEPENDS` applies to *every* image, so reusing the main image as the
initramfs closes a loop: kernel → initramfs image → `rtl83xx-bootimage` →
kernel. `rtl83xx-image-initramfs.bb` clears `EXTRA_IMAGEDEPENDS` locally.

## Kernel configuration

Two layers, and the split matters:

**`files/defconfig` is generated, not hand-written.** It is OpenWrt's generic +
rtl838x configs merged with OpenWrt's own command (`include/target.mk:172`):

```sh
cd <openwrt>
./scripts/kconfig.pl + target/linux/generic/config-6.18 \
                       target/linux/realtek/rtl838x/config-6.18
```

8449 lines, 731 `=y`, and — crucially — 7617 explicit `# ... is not set`. Regenerate it
when you bump the OpenWrt tree; keep the header comment.

**`files/rtl83xx-kmeta/features/rtl83xx/` holds the deltas**, shipped as kernel metadata
(`SRC_URI += "file://rtl83xx-kmeta;type=kmeta;destsuffix=rtl83xx-kmeta"` plus
`KERNEL_FEATURES`). `rtl83xx.scc` pulls in two fragments:

- `rtl83xx-hardware.cfg` (`kconf hardware`) — the board's must-have symbols. These are
  *already* in `defconfig`; the duplication is a tripwire, because a dropped
  `kconf hardware` symbol is reported by the audit even at `KCONF_AUDIT_LEVEL=1`.
- `rtl83xx-yocto.cfg` (`kconf non-hardware`) — only where this build genuinely differs
  from OpenWrt: devtmpfs, `PRINTK_TIME`, `MODULES` off, `DEBUG_INFO_NONE`.

Anything OpenWrt already gets right belongs in neither file.

### Why the base config must be complete

`KCONFIG_MODE = "--allnoconfig"` does **not** strip symbols that are present in the merged
file — `conf_set_all_new_symbols()` skips anything with a user value
(`scripts/kconfig/conf.c:236`). It forces every **absent** symbol to `n`, ignoring its
Kconfig `default y`. So the danger is indirect, through dependencies you did not list.

That is exactly how ethernet was lost for a while: `CONFIG_NET` lives only in OpenWrt's
generic half, which had not been copied. `NET` absent → `n`; `NETDEVICES` *was* requested
but `depends on NET`, so it was dropped **silently**; and the whole DSA/PHY/ethernet tree
went with it. The single visible symptom was one warning, because `REGMAP_MDIO` sits
outside the NET menu and still selected `MDIO_BUS`:

```
WARNING: unmet direct dependencies detected for MDIO_BUS
  Depends on [n]: NETDEVICES [=n]
  Selected by [y]: REGMAP_MDIO [=y]
```

A complete base config removes the whole failure mode.

### Checking config changes

The authoritative list of requested-but-dropped symbols:

```sh
tmp/work-shared/rtl83xx/kernel-source/.kernel-meta/cfg/merge_config_build.log
```

Do **not** just count `not in final .config` — with a complete base that number is in the
thousands and almost all of it is `# CONFIG_X is not set` for symbols this kernel simply
does not have. Only the entries whose *requested* value is `=y`/`=m` matter:

```sh
python3 - <<'EOF'
import re
L = "tmp/work-shared/rtl83xx/kernel-source/.kernel-meta/cfg/merge_config_build.log"
lines = open(L, errors="replace").read().splitlines()
for i, l in enumerate(lines):
    m = re.match(r"Value requested for (CONFIG_\S+) not in final", l)
    if m and lines[i+1].rstrip().endswith(("=y", "=m")):
        print(m.group(1))
EOF
```

~205 today, and all of it is benign: other architectures (ARM/PPC/x86 symbols, since
OpenWrt's generic config is arch-neutral), subsystems whose parent menu is off
(SND/USB/SCSI/NFS/Bluetooth), and OpenWrt-patch-added symbols whose patches are not
enabled. What must stay empty is the hardware list — see the tripwire check below.

`KCONF_AUDIT_LEVEL = "2"` in the bbappend makes `do_kernel_configcheck` write
`.kernel-meta/cfg/mismatch.txt` and warn. The default of `1` passes `--classify` to
`symbol_why.py`, which suppressed the report entirely while networking was disappearing.

To add options the supported way: `bitbake -c menuconfig virtual/kernel`, then
`bitbake -c diffconfig virtual/kernel`, and fold the emitted fragment into the right
`.cfg`.

**Symbols that cannot be set directly.** `CONFIG_DEBUG_INFO` is a promptless bool driven
by the "Debug information" choice (`lib/Kconfig.debug:227`), so
`# CONFIG_DEBUG_INFO is not set` is a no-op — you have to select `CONFIG_DEBUG_INFO_NONE=y`
instead. Expect the same shape for other choice-driven symbols.

## Traps worth remembering

**Tune must be `24kc`, not `24kec`.** The `e` means "with DSP ASE", and
`tune-mips-24k.inc` appends `-mdsp` for it. GCC then emits `lbux`/`lwx`, which
the RTL8380 (no DSP ASE, DT says `mips,mips4KEc`) traps as Reserved Instruction.
Symptom: `Starting ...` on the console and then complete silence — rt-loader
dies on the first character of its own banner, because nanoprintf indexes the
format string byte by byte. OpenWrt builds this target as `CPU_TYPE:=24kc`.

**OpenWrt patch series have prerequisites, and only a subset is enabled.** Of the 359
patches under `files/openwrt-generic-patches/`, the bbappend enables a curated subset.
Turning networking on exposed several gaps, each of which surfaced as a missing header or
an implicit-declaration error rather than anything that named the real cause:

| Symptom | Missing prerequisite |
|---|---|
| `linux/pcs/pcs-provider.h: No such file` | `pending-6.18/737-01..07` |
| `linux/phy/phy-common-props.h: No such file` | `backport-6.18/785-v7.0-01..11` |
| `737-02` fails to apply at `phylink.c` | earlier phylink patches `702`, `703-01/02`, `704`, `706` |
| `implicit declaration of mmd_phy_read` | `backport-6.18/750-v7.0-...` (790 and 795 were on without it) |

When enabling a patch, check the rest of its numeric family and anything else touching the
same file:

```sh
grep -rl "drivers/net/phy/phylink.c" files/openwrt-generic-patches/*/
```

**linux-yocto's base is not OpenWrt's base.** `737-02` still failed after every OpenWrt
prerequisite was on, because it expects `goto free_pl;` in `phylink_create()` while
linux-yocto 6.18.39 still has the open-coded `kfree(pl); return ERR_PTR(ret);`. The fix
was to backport the one upstream commit that introduces the label
(`0005-net-phylink-put-link_gpio-if-phylink_create-fails.patch`, cherry-picked from the
linux-yocto tree) rather than refresh three OpenWrt patches. Prefer that direction when
the gap is a single upstream commit.

**Headless means `USE_VT = "0"`.** `busybox-inittab` defaults `USE_VT ?= "1"` and then
appends a `getty 38400 tty1` line. OpenWrt's config leaves `CONFIG_VT` off, which is right
for this board, so `/dev/tty1` never exists and init respawns that getty forever:

```
can't open /dev/tty1: No such file or directory
process '/sbin/getty 38400 tty1' (pid 377) exited. Scheduling for restart.
```

This only appeared once the OpenWrt base config replaced the tiny ktype's, which had
`CONFIG_VT=y`. `SERIAL_CONSOLES` drives the `ttyS0` getty and is separate.

**`devtmpfs_mount()` never runs for an initramfs.** It is called only from
`prepare_namespace()` (`init/do_mounts.c`), the real-root path, so
`CONFIG_DEVTMPFS_MOUNT=y` does not populate `/dev` here. busybox' inittab mounts
devtmpfs itself; the image recipe ships a static `/dev/console` to cover the gap
before init starts.

**A wiped `tmp/work/<machine>-*` leaves stale stamps behind.** Deleting a work
directory does not invalidate `tmp/stamps`, so bitbake happily skips
`do_prepare_recipe_sysroot` and friends for tasks whose output no longer
exists, and the build either fails strangely (`cp: cannot stat
.../recipe-sysroot/usr/share/rt-loader`) or produces artifacts from a mixed
state. Recover with `bitbake -c clean` on every recipe under that directory,
not by re-running the failing task. One boot ending in

    /sbin/init exists but couldn't execute it (error -8)
    Kernel panic - not syncing: No working init found

came out of exactly such a state and did not reproduce after a clean rebuild;
the root cause was never pinned down because the failing config and rootfs had
already been deleted. If `-8`/`ENOEXEC` shows up again, capture `${B}/.config`
and the initramfs cpio *before* cleaning anything.

**`bitbake -f -c configure virtual/kernel` is misleading.** It does not re-run
`do_kernel_metadata`, so it configures with no fragments and produces a config
that looks nothing like the real one. Use `bitbake -c clean virtual/kernel`
followed by a normal build.

## Not done yet

The flashable image. OpenWrt's `sysupgrade.bin` is
`append-kernel | pad-to 64k | append-rootfs | pad-rootfs | check-size 13952k |
append-metadata`, plus the `zyxel-vers` trailer
(`VERS\nV9.99(AAHH.0) | MM/DD/YYYY\n`) that the stock web UI validates. That
needs a squashfs rootfs, a `padjffs2` equivalent and the MTD partition map.


# ToDo
* Rework kconfigs
  - too much enabled
  - need to use poky standard
  - Lot of "[INFO]: the following symbols were not found in the active configuration:"
* Check why patch 0004 and 0005 are necessary. Claude did it.