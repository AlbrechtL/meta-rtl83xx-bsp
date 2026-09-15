#!/usr/bin/env python3
"""Rewrite the magic of a legacy U-Boot image header, in place.

The Zyxel GS1900 bootloader (and the in-kernel mtdsplit_uimage parser, via the
openwrt,ih-magic DT property) expects 0x83800000 instead of the standard
IH_MAGIC 0x27051956. OpenWrt gets this from a local mkimage patch adding a -M
option; oe-core ships unpatched u-boot-tools, so patch the 64 byte header here
instead.

    struct image_header {      /* all big endian */
        uint32_t ih_magic;     /* 0x00 */
        uint32_t ih_hcrc;      /* 0x04, CRC32 over the header with hcrc == 0 */
        uint32_t ih_time;      /* 0x08 */
        uint32_t ih_size;      /* 0x0c */
        uint32_t ih_load;      /* 0x10 */
        uint32_t ih_ep;        /* 0x14 */
        uint32_t ih_dcrc;      /* 0x18 */
        uint8_t  ih_os;        /* 0x1c */
        uint8_t  ih_arch;      /* 0x1d */
        uint8_t  ih_type;      /* 0x1e */
        uint8_t  ih_comp;      /* 0x1f */
        uint8_t  ih_name[32];  /* 0x20 */
    };
"""

import struct
import sys
import zlib

HEADER_SIZE = 64
IH_MAGIC = 0x27051956


def main(argv):
    if len(argv) != 3:
        sys.exit("usage: %s <uimage> <magic>" % argv[0])

    path, magic = argv[1], int(argv[2], 0)

    with open(path, "r+b") as f:
        header = bytearray(f.read(HEADER_SIZE))
        if len(header) != HEADER_SIZE:
            sys.exit("%s: too short to be a uImage" % path)

        current = struct.unpack_from(">I", header, 0)[0]
        if current not in (IH_MAGIC, magic):
            sys.exit("%s: not a uImage (magic 0x%08x)" % (path, current))

        struct.pack_into(">I", header, 0, magic)
        struct.pack_into(">I", header, 4, 0)
        struct.pack_into(">I", header, 4, zlib.crc32(header) & 0xFFFFFFFF)

        f.seek(0)
        f.write(header)


if __name__ == "__main__":
    main(sys.argv)
