# meta-rtl83xx-bsp — technical notes

Deep-dive background for [README.md](README.md): how the boot image is
assembled, the kernel configuration layout, and traps worth remembering.

## How the boot image is put together

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
from the machine configuration (`RTL_LOADADDR` in
`conf/machine/include/rtl83xx.inc`, `RTL_UIMAGE_MAGIC` per board).

Two loader variants are built from one payload. The raw one is compiled with
`KERNEL_ADDR=0x80100000` so it can be started from anywhere; the uImage one
without, so it adopts its own run address (which `bootm` sets to `0x80100000`).

### Choosing a TFTP staging address

RAM is 128 MB, and KSEG0 maps `0x80000000` + physical, so valid addresses stop
at `0x88000000`. `0x84f00000` is safe.

Nothing collides at `0x84f00000`: `bootm` copies the payload to `0x80100000`,
the kernel decompresses to `0x80100000`–`0x807a0000`, and rt-loader relocates
itself to roughly `0x87d90000`.

### Why the DTB is appended before compression

`CONFIG_MIPS_RAW_APPENDED_DTB=y`. The linker reserves `__appended_dtb` at the
very end of the loadable image (`arch/mips/kernel/vmlinux.lds.S`), so
concatenating the DTB onto the *uncompressed* `vmlinux.bin` puts the FDT exactly
on that symbol. Appending it to the LZMA stream instead would not work.

Check it holds after a kernel change:

```sh
awk '$3=="_text"||$3=="__appended_dtb"{print}' .../linux-rtl83xx-tiny-build/System.map
stat -Lc%s tmp/deploy/images/zyxel-gs1900-8-a1/vmlinux.bin-initramfs-zyxel-gs1900-8-a1.bin
```

`__appended_dtb - _text` must equal the file size.

### Why mkimage needs a post-processing step

The stock bootloader and the in-kernel `mtdsplit_uimage` parser expect magic
`0x83800000`, not the standard `0x27051956`. OpenWrt gets this from a local
mkimage patch adding `-M`; oe-core ships unpatched u-boot-tools, so
`recipes-bsp/rtl83xx-bootimage/files/uimage-setmagic.py` rewrites `ih_magic` and
recomputes `ih_hcrc` on the finished 64-byte header.

rt-loader is deliberately split from `rtl83xx-bootimage`: piggy-back mode
needs the compressed kernel at link time, so the loader can only be built
after the kernel exists.

The initramfs image is a separate recipe from `core-image-minimal` on purpose.
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
tmp/work-shared/zyxel-gs1900-8-a1/kernel-source/.kernel-meta/cfg/merge_config_build.log
```

Do **not** just count `not in final .config` — with a complete base that number is in the
thousands and almost all of it is `# CONFIG_X is not set` for symbols this kernel simply
does not have. Only the entries whose *requested* value is `=y`/`=m` matter:

```sh
python3 - <<'EOF'
import re
L = "tmp/work-shared/zyxel-gs1900-8-a1/kernel-source/.kernel-meta/cfg/merge_config_build.log"
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
enabled. What must stay empty is the hardware list — see the tripwire check above.

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
linux-yocto 6.18.39 still had the open-coded `kfree(pl); return ERR_PTR(ret);`. The fix
was to backport the one upstream commit that introduces the label (0fe1e3e8f338, "net:
phylink: put link_gpio if phylink_create fails") as a BSP patch rather than refresh three
OpenWrt patches. Prefer that direction when the gap is a single upstream commit, and drop
the backport again once linux-yocto picks it up through stable -- this one arrived with
6.18.48 and the patch was removed, since it no longer applies on top of itself.

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

## Boot from flash

- U-Boot loads the uImage at `0x260000`.
- `mtdsplit_uimage` (`pending-6.18/400` plus patch 0003) splits `firmware`
  into `kernel` and `rootfs`. It searches for the squashfs magic only at erase
  block boundaries, hence the padding.
- `hack-6.18/420` makes the mtd named `rootfs` the root device.
- The DTS bootargs add `rootfstype=squashfs init=/sbin/overlay-init`. The
  initramfs kernel runs `/init` and ignores `init=`, so both kernels share
  one DTB.
- `overlay-init` (`recipes-core/rtl83xx-overlay-init`) mounts `mtd:data` on
  `/overlay` and an overlay with `lowerdir=/` on `/mnt`. It then
  `pivot_root`s, keeping the squashfs at `/rom`, and execs busybox init.
  If `data` does not mount, the upper layer falls back to tmpfs.

`firmware` is OpenWrt's merge of the two stock 6976k slots (OpenWrt commit
`35acdbe909`), so there is no A/B: an upgrade rewrites the running firmware.
`data` is Zyxel's `jffs` + `jffs2`.

### Traps

**OpenWrt's mtdsplit is more than patch 0003.** The sources in 0003 only build
once `pending-6.18/400` hooks them into Kconfig, the Makefile and `mtdpart.c`.
They also need `<dt-bindings/mtd/partitions/uimage.h>`, which OpenWrt ships
in `target/linux/generic/files/` rather than in a patch, hence 0007. The
symptom was `fatal error: dt-bindings/mtd/partitions/uimage.h: No such file`.
Also, `MTD_ROOTFS_ROOT_DEV` is only declared by 400; `hack-6.18/420` is what
sets ROOT_DEV. `mtdsplit_lzma.c` still includes `asm/unaligned.h`, which is
gone since 6.12, so leave `MTD_SPLIT_LZMA_FW` off or port it.

**The data image must fill the partition.** SWUpdate's flash handler erases
only the blocks it writes. An empty JFFS2 image shorter than `data` would
leave old overlay nodes behind, and JFFS2 would mount them again. That is why
`rtl83xx-data` is padded to `RTL_DATA_SIZE`.

**`/tmp` is a plain directory in this rootfs, and `/var/log` points into
`/var/volatile`.** On the overlay both would end up on the 2 MiB JFFS2, and
SWUpdate unpacks the whole .swu into `/tmp`. `overlay-init` mounts tmpfs on
both. The image drops `/var/volatile` from fstab, because `mount -a` would
otherwise stack an empty tmpfs over the directories created there.

**An upgrade overwrites what SWUpdate runs from.** The kernel can drop and
re-read squashfs pages at any time. On the flash system, `20-ethernet-switch-os-mode`
first copies swupdate, its libraries, the musl loader, `/www` and busybox to
`/run/swupdate-ram`. It then execs swupdate through the copied loader
(`ld-musl-*.so.1 --library-path`). SWUpdate runs the `-p` post-update command
as `execl("/bin/sh", "sh", "-c", cmd)`, i.e. through the squashfs busybox and
musl loader. The script therefore bind-mounts the RAM copies over both before
starting swupdate, so the shell and `reboot -f` are RAM-backed too.

The reboot must not happen inside `-p`. SWUpdate's web server calls `-p`
synchronously and only forwards the final `DONE` status ("Restarting
system.") after it returns. A `reboot -f` there cuts the browser off without a
word. `-p` therefore detaches a job with `setsid` and returns. The job waits
2 s, stops swupdate so that the websocket closes and the page opens its
restart dialog, then syncs and runs `reboot -f`.

**SWUpdate never reboots by itself.** With `reboot_enabled` the web UI shows
"Restarting system." and SWUpdate runs `-p`. Without a `-p` nothing happens.
In the initramfs, `20-ethernet-switch-os-mode` passes `-p /sbin/reboot`.

**SWUpdate needs `CONFIG_HASH_VERIFY` for the sha256 in the sw-descriptions.**
Without it the parser rejects the description with "hash verification not
enabled but hash supplied", which is followed by the misleading "Compatible SW
not found". `HASH_VERIFY` depends on an SSL implementation, so
`meta-ethernet-switch-os`'s `ethernet-switch-os.cfg` selects openssl. That costs no flash,
because clixon already ships libcrypto. Do not drop the hashes instead: with a
single slot, the image has to be verified before `firmware` is erased.
meta-swupdate derives `DEPENDS` (openssl among them) from that fragment at
parse time. The swupdate bbappend therefore marks `ethernet-switch-os.cfg` as a parse
dependency. Without that, an edit to it leaves the stale `DEPENDS` in the parse
cache: `openssl/bio.h: No such file`, plus "basehash value changed".

**Nothing may install `/etc/u-boot-initial-env`.** `/etc/fw_env.config` points at
the main environment (`u-boot-env`, mtd1, which holds `bootcmd`). If SWUpdate
ever writes the environment and cannot read it, it loads that file and stores
it over `u-boot-env`. Without the file the write fails instead. Today no .swu
writes it at all: there is no `bootenv`, and both sw-descriptions turn off
`bootloader_transaction_marker` and `bootloader_state_marker`.

## Known issues / ToDo

- Kernel config rework: too much is enabled; needs to move closer to the
  poky-tiny standard set. Expect a lot of "[INFO]: the following symbols were
  not found in the active configuration:" warnings until then.
- Verify why `0004-realtek-dts-replace-rtl838x.dtsi-with-the-OpenWrt-ver.patch`
  under `recipes-kernel/linux/files/` is actually necessary — added while chasing a
  build failure, not yet re-checked from first principles.

Find the next size offender with `readelf -d` over the rootfs (`NEEDED`
entries) rather than grepping pkgdata.
