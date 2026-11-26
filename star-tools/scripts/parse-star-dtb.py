#!/usr/bin/env python3
"""Minimal Flattened Device Tree reader (no dtc on this host).

Extracts the display-related nodes of star-B.dtb with their reg/compatible
values, which are the authoritative hardware facts for the star display port.
"""
import struct

DTB = "/root/star26/star-B.dtb"
OUT = "/mnt/c/ios26/star-display-nodes.txt"

b = open(DTB, "rb").read()
(magic, totalsize, off_struct, off_strings, off_rsvmap, version,
 last_comp, boot_cpu, size_strings, size_struct) = struct.unpack(">10I", b[:40])
assert magic == 0xD00DFEED, "not an FDT blob: %#x" % magic

strings = b[off_strings:off_strings + size_strings]


def sname(off):
    end = strings.find(b"\0", off)
    return strings[off:end].decode("ascii", "replace")


def align4(n):
    return (n + 3) & ~3


pos, stack, nodes = off_struct, [], []
while pos < off_struct + size_struct:
    tok = struct.unpack(">I", b[pos:pos + 4])[0]
    pos += 4
    if tok == 1:  # BEGIN_NODE
        end = b.find(b"\0", pos)
        name = b[pos:end].decode("ascii", "replace")
        pos = align4(end + 1)
        stack.append(name)
        path = "/".join(stack)
        nodes.append({"path": path, "props": {}})
    elif tok == 2:  # END_NODE
        if stack:
            stack.pop()
    elif tok == 3:  # PROP
        ln, noff = struct.unpack(">II", b[pos:pos + 8])
        pos += 8
        val = b[pos:pos + ln]
        pos = align4(pos + ln)
        if nodes:
            nodes[-1]["props"][sname(noff)] = val
    elif tok == 4:  # NOP
        pass
    elif tok == 9:  # END
        break
    else:
        raise SystemExit("bad FDT token %#x at %d" % (tok, pos - 4))


def cells(val):
    return ["0x%x" % x for x in struct.unpack(">%dI" % (len(val) // 4), val[:len(val) // 4 * 4])]


def text(val):
    return val.rstrip(b"\0").decode("ascii", "replace").replace("\0", " | ")


KEYS = ("mdss", "dsi", "dp_display", "panel", "cont_splash", "pinctrl", "gcc", "disp", "ufs")
with open(OUT, "w") as fh:
    fh.write("FDT %s size=%d version=%d struct=%d strings=%d nodes=%d\n\n"
             % (DTB, totalsize, version, size_struct, size_strings, len(nodes)))
    for n in nodes:
        p = n["path"]
        if not any(k in p.lower() for k in KEYS):
            continue
        fh.write("=== %s ===\n" % p)
        for k in ("compatible", "reg", "status", "qcom,dsi-ctrl-hw-version",
                  "qcom,dsi-phy-version", "qcom,mdss-mdp-reg-offset",
                  "linux,phandle", "phandle", "reg-names", "clock-names"):
            if k in n["props"]:
                v = n["props"][k]
                fh.write("  %-28s %s\n" % (k, text(v) if k != "reg" else " ".join(cells(v))))
        fh.write("\n")
print("nodes=%d report=%s" % (len(nodes), OUT))
