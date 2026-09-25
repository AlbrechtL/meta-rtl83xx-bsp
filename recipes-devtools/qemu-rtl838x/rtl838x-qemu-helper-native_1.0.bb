# rtl838x-qemu-helper-native - a sysroot to run qemu-system-mips-rtl838x from
#
# A native binary finds its libraries through an RPATH relative to itself,
# so it runs from a sysroot that holds it together with glib, pixman and
# libslirp. Building this recipe leaves exactly that behind, in
#
#   tmp/work/x86_64-linux/rtl838x-qemu-helper-native/*/recipe-sysroot-native/
#
# which is where ethernet-switch-os' scripts/mips-rtl838x-qemu runs the emulator
# from. The same trick as oe-core's qemu-helper-native, which runqemu uses.

SUMMARY = "Sysroot for running the RTL838x QEMU machine"
LICENSE = "MIT"

INHIBIT_DEFAULT_DEPS = "1"

inherit native

DEPENDS = "qemu-rtl838x-native"

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

addtask addto_recipe_sysroot after do_populate_sysroot before do_build
