# Flash images for the RTL83xx partition map in conf/machine/rtl83xx.conf.
#
# rtl83xx-fw    Contents of the "firmware" partition:
#
#                   uImage (rt-loader + kernel) | pad to erase block | squashfs
#
#               which is OpenWrt's "append-kernel | pad-to 64k | append-rootfs".
#               mtdsplit_uimage looks for the squashfs magic only at erase
#               block boundaries behind the uImage, so the padding is required.
#
# rtl83xx-data  An empty JFFS2 the size of the whole "data" partition. A factory
#               install writes it to wipe the overlay. SWUpdate's flash handler
#               erases only the blocks it writes to, so anything shorter than
#               the partition would leave old overlay nodes behind that JFFS2
#               would happily mount again.

RTL_FIRMWARE_SIZE ?= "0xda0000"
RTL_DATA_SIZE ?= "0x200000"
RTL_FLASH_ERASEBLOCK ?= "0x10000"
RTL_FLASH_UIMAGE ?= "uImage-${MACHINE}.bin"

IMAGE_TYPES += "rtl83xx-fw rtl83xx-data"

IMAGE_TYPEDEP:rtl83xx-fw = "squashfs-xz"
do_image_rtl83xx_fw[depends] += "rtl83xx-bootimage:do_deploy"

IMAGE_CMD:rtl83xx-fw () {
    uimage="${DEPLOY_DIR_IMAGE}/${RTL_FLASH_UIMAGE}"
    rootfs="${IMGDEPLOYDIR}/${IMAGE_NAME}.squashfs-xz"
    out="${IMGDEPLOYDIR}/${IMAGE_NAME}.rtl83xx-fw"

    for f in "$uimage" "$rootfs"; do
        [ -f "$f" ] || bbfatal "missing firmware component: $f"
    done

    cp -L "$uimage" "$out"
    truncate -s %$(printf %d ${RTL_FLASH_ERASEBLOCK}) "$out"
    cat "$rootfs" >> "$out"

    size=$(stat -c %s "$out")
    max=$(printf %d ${RTL_FIRMWARE_SIZE})
    if [ "$size" -gt "$max" ]; then
        bbfatal "firmware image is $size bytes, the firmware partition holds $max"
    fi
    bbnote "firmware image: $size of $max bytes ($(expr $size \* 100 / $max)%)"
}

do_image_rtl83xx_data[depends] += "mtd-utils-native:do_populate_sysroot"

IMAGE_CMD:rtl83xx-data () {
    empty="${WORKDIR}/rtl83xx-data-empty"
    rm -rf "$empty"
    mkdir -p "$empty"

    mkfs.jffs2 ${JFFS2_ENDIANNESS} \
        --eraseblock=$(printf %d ${RTL_FLASH_ERASEBLOCK}) \
        --pad=$(printf %d ${RTL_DATA_SIZE}) \
        --root="$empty" --squash-uids --faketime \
        --output="${IMGDEPLOYDIR}/${IMAGE_NAME}.rtl83xx-data"
}
