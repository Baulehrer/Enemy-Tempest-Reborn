#!/usr/bin/env python3
import struct
import sys
from collections import Counter, defaultdict
from pathlib import Path


NAMES = {
    999: "HUNK_UNIT",
    1000: "HUNK_NAME",
    1001: "HUNK_CODE",
    1002: "HUNK_DATA",
    1003: "HUNK_BSS",
    1004: "HUNK_RELOC32",
    1005: "HUNK_RELOC16",
    1006: "HUNK_RELOC8",
    1007: "HUNK_EXT",
    1008: "HUNK_SYMBOL",
    1009: "HUNK_DEBUG",
    1010: "HUNK_END",
    1011: "HUNK_HEADER",
    1012: "HUNK_OVERLAY",
    1013: "HUNK_BREAK",
    1015: "HUNK_DREL32",
    1016: "HUNK_DREL16",
    1017: "HUNK_DREL8",
    1020: "HUNK_RELOC32SHORT",
}


def u32(buf, off):
    if off + 4 > len(buf):
        raise ValueError(f"read past eof at 0x{off:x}")
    return struct.unpack_from(">I", buf, off)[0], off + 4


def skip_name_table(buf, off):
    count, off = u32(buf, off)
    while count:
        off += count * 4
        count, off = u32(buf, off)
    return off


def parse(path):
    buf = Path(path).read_bytes()
    off = 0
    ident, off = u32(buf, off)
    if ident != 1011:
        raise ValueError(f"{path}: expected HUNK_HEADER, got 0x{ident:08x}")

    name_longs, off = u32(buf, off)
    off += name_longs * 4
    table_size, off = u32(buf, off)
    first, off = u32(buf, off)
    last, off = u32(buf, off)
    sizes = []
    for _ in range(table_size):
        raw, off = u32(buf, off)
        sizes.append(raw)

    print(f"{path}")
    print(f"  bytes={len(buf)} table_size={table_size} first={first} last={last}")
    for i, raw in enumerate(sizes):
        mem = raw & 0xC0000000
        size_lw = raw & 0x3FFFFFFF
        print(f"  table[{i}] raw=0x{raw:08x} mem=0x{mem:08x} alloc={size_lw * 4}")

    seg = -1
    blocks = Counter()
    relocs = defaultdict(Counter)
    payload = {}
    while off < len(buf):
        block_off = off
        ident, off = u32(buf, off)
        base_ident = ident & 0x3FFFFFFF
        blocks[base_ident] += 1
        name = NAMES.get(base_ident, f"UNKNOWN_{base_ident}")
        if base_ident in (1001, 1002):
            seg += 1
            longs, off = u32(buf, off)
            payload[seg] = (name, longs * 4, block_off)
            off += longs * 4
        elif base_ident == 1003:
            seg += 1
            longs, off = u32(buf, off)
            payload[seg] = (name, 0, block_off)
        elif base_ident == 1004:
            while True:
                count, off = u32(buf, off)
                if count == 0:
                    break
                target, off = u32(buf, off)
                relocs[seg][target] += count
                off += count * 4
        elif base_ident == 1020:
            while True:
                count, off = u32(buf, off)
                if count == 0:
                    if off & 2:
                        off += 2
                    break
                target, off = u32(buf, off)
                relocs[seg][target] += count
                off += count * 2
                if off & 2:
                    off += 2
        elif base_ident == 1008:
            off = skip_name_table(buf, off)
        elif base_ident == 1009:
            longs, off = u32(buf, off)
            off += longs * 4
        elif base_ident == 1010:
            pass
        else:
            print(f"  stop: unsupported parser block {name} at file+0x{block_off:x}")
            break

    print("  blocks=" + ", ".join(f"{NAMES.get(k, k)}:{v}" for k, v in sorted(blocks.items())))
    for i in sorted(payload):
        kind, plen, boff = payload[i]
        rtotal = sum(relocs[i].values())
        by_target = ", ".join(f"to#{t}:{c}" for t, c in sorted(relocs[i].items()))
        print(f"  seg#{i} {kind} payload={plen} block_off=0x{boff:x} relocs={rtotal} {by_target}")


def main(argv):
    if len(argv) < 2:
        raise SystemExit("usage: summarize_hunk_loadseg.py FILE...")
    for path in argv[1:]:
        parse(path)


if __name__ == "__main__":
    main(sys.argv)
