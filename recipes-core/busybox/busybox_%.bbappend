FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# flash_eraseall for overlay-init, which erases the "data" partition on a
# factory reset. Merged over the defconfig by find_cfgs in busybox.inc.
SRC_URI += "file://rtl83xx-flash-eraseall.cfg"
