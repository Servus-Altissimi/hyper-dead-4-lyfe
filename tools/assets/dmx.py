import struct
from pathlib import Path

SIZES = {2: 4, 3: 4, 4: 1, 7: 16, 8: 4, 9: 8, 10: 12, 11: 16, 12: 12, 13: 16, 14: 64}

class R:
    def __init__(self, b):
        self.b = b
        self.p = 0

    def i32(self):
        v = struct.unpack_from("<i", self.b, self.p)[0]
        self.p += 4
        return v

    def i16(self):
        v = struct.unpack_from("<h", self.b, self.p)[0]
        self.p += 2
        return v

    def u8(self):
        v = self.b[self.p]
        self.p += 1
        return v

    def raw(self, n):
        v = self.b[self.p:self.p + n]
        self.p += n
        return v

    def cstr(self):
        e = self.b.index(b"\0", self.p)
        v = self.b[self.p:e]
        self.p = e + 1
        return v

def read(data, string_values_indexed):
    r = R(data)
    header = r.cstr()
    strings = [r.cstr() for _ in range(r.i32())]
    elements = []
    for _ in range(r.i32()):
        t = strings[r.i16()]
        n = strings[r.i16()]
        guid = r.raw(16)
        elements.append({"type": t, "name": n, "guid": guid, "attrs": []})
    for el in elements:
        for _ in range(r.i32()):
            name = strings[r.i16()]
            t = r.u8()
            el["attrs"].append([name, t, value(r, t, strings, string_values_indexed)])
    assert r.p == len(data), (r.p, len(data))
    return header, elements, strings

def value(r, t, strings, idx):
    if t == 1:
        v = r.i32()
        if v == -2:
            return ("ext", r.cstr())
        return v
    if t == 5:
        return strings[r.i16()] if idx else r.cstr()
    if t == 6:
        return r.raw(r.i32())
    if t in SIZES:
        return r.raw(SIZES[t])
    if 15 <= t <= 28:
        base = t - 14
        n = r.i32()
        out = []
        for _ in range(n):
            if base == 1:
                v = r.i32()
                out.append(("ext", r.cstr()) if v == -2 else v)
            elif base == 5:
                out.append(r.cstr())
            elif base == 6:
                out.append(r.raw(r.i32()))
            else:
                out.append(r.raw(SIZES[base]))
        return out
    raise ValueError("attr type %d" % t)

def write(header, elements, string_values_indexed, base=()):
    table = list(base)
    index = {s: i for i, s in enumerate(table)}

    def sid(s):
        if s not in index:
            index[s] = len(table)
            table.append(s)
        return index[s]

    for el in elements:
        sid(el["type"])
        sid(el["name"])
    for el in elements:
        for name, t, v in el["attrs"]:
            sid(name)
            if t == 5 and string_values_indexed:
                sid(v)
    out = [header + b"\0", struct.pack("<i", len(table))]
    out += [s + b"\0" for s in table]
    out.append(struct.pack("<i", len(elements)))
    for el in elements:
        out.append(struct.pack("<hh", index[el["type"]], index[el["name"]]) + el["guid"])
    for el in elements:
        out.append(struct.pack("<i", len(el["attrs"])))
        for name, t, v in el["attrs"]:
            out.append(struct.pack("<hB", index[name], t))
            out.append(enc(t, v, index, string_values_indexed))
    return b"".join(out)

def enc(t, v, index, idx):
    if t == 1:
        if isinstance(v, tuple):
            return struct.pack("<i", -2) + v[1] + b"\0"
        return struct.pack("<i", v)
    if t == 5:
        return struct.pack("<h", index[v]) if idx else v + b"\0"
    if t == 6:
        return struct.pack("<i", len(v)) + v
    if t in SIZES:
        return v
    base = t - 14
    parts = [struct.pack("<i", len(v))]
    for x in v:
        if base == 1:
            parts.append(struct.pack("<i", -2) + x[1] + b"\0" if isinstance(x, tuple) else struct.pack("<i", x))
        elif base == 5:
            parts.append(x + b"\0")
        elif base == 6:
            parts.append(struct.pack("<i", len(x)) + x)
        else:
            parts.append(x)
    return b"".join(parts)

def load(path):
    data = Path(path).read_bytes()
    for idx in (True, False):
        try:
            h, els, strings = read(data, idx)
            return h, els, idx, strings
        except Exception:
            continue
    raise ValueError(f"cannot parse {path}")
