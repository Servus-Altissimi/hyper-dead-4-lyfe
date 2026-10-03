LIVE = 3.0
BAND_A, BAND_B = 0.25, 0.75
FULL_HUD = {"full": (16200, 2)}

def fmt(x):
    if isinstance(x, float):
        s = ("%.6f" % x).rstrip("0").rstrip(".")
        return s if s not in ("", "-0") else "0"
    return str(x)

class Mat:
    def __init__(self, base, blend="translucent", shader="UnlitGeneric", texture2=None, params=None):
        self.shader = shader
        self.head = [("$basetexture", base)]
        if texture2:
            self.head.append(("$texture2", texture2))
        self.head.append(("$" + blend, "1"))
        for k in ("$vertexcolor", "$vertexalpha", "$ignorez", "$nomip", "$nolod", "$nocull"):
            self.head.append((k, "1"))
        for k, v in (params or {}).items():
            self.head.append((k, v))
        self.vars = {}
        self.lines = []
        self.n = 0
        self.tags = {}
        self.const_names = {}
        self.var("$alpha", "0")
        self.zero = self.const(0)
        self.one = self.const(1)
        self.v = self.new()
        self.p('"ConVar" { "convar" "name2" "resultVar" "%s" }' % self.v)
        t = self.new()
        self.op("Add", self.v, self.const(50000), t)
        self.op("Divide", t, self.const(1000000), t)
        self.tag = self.new()
        self.p('"Int" { "srcVar1" "%s" "resultVar" "%s" }' % (t, self.tag))
        base_ = self.new()
        self.op("Multiply", self.tag, self.const(1000000), base_)
        self.payload = self.new()
        self.op("Subtract", self.v, base_, self.payload)
        self.time = self.new()
        self.p('"CurrentTime" { "resultVar" "%s" }' % self.time)

    def var(self, name, value):
        self.vars[name] = value

    def new(self, value="0"):
        self.n += 1
        name = "$h_%d" % self.n
        self.var(name, value)
        return name

    def const(self, value):
        key = fmt(value)
        if key not in self.const_names:
            name = "$h_k%d" % len(self.const_names)
            self.var(name, key)
            self.const_names[key] = name
        return self.const_names[key]

    def p(self, line):
        self.lines.append(line)

    def op(self, kind, a, b, out):
        self.p('"%s" { "srcVar1" "%s" "srcVar2" "%s" "resultVar" "%s" }' % (kind, a, b, out))

    def le(self, a, b, yes, no, out):
        self.p('"LessOrEqual" { "srcVar1" "%s" "srcVar2" "%s" "resultVar" "%s" "LessEqualVar" "%s" "greaterVar" "%s" }' % (a, b, out, yes, no))

    def copy(self, a, out):
        self.p('"Equals" { "srcVar1" "%s" "resultVar" "%s" }' % (a, out))

    def hit(self, tag):
        if tag not in self.tags:
            h = self.new()
            self.op("Subtract", self.tag, self.const(tag), h)
            self.p('"Abs" { "srcVar1" "%s" "resultVar" "%s" }' % (h, h))
            self.tags[tag] = h
        return self.tags[tag]

    def field(self, tag, fields, name):
        div, radix = fields[name]
        h = self.hit(tag)
        q = self.new()
        self.op("Divide", self.payload, self.const(div), q)
        self.p('"Int" { "srcVar1" "%s" "resultVar" "%s" }' % (q, q))
        q2 = self.new()
        self.op("Divide", q, self.const(radix), q2)
        self.p('"Int" { "srcVar1" "%s" "resultVar" "%s" }' % (q2, q2))
        self.op("Multiply", q2, self.const(radix), q2)
        fresh = self.new()
        self.op("Subtract", q, q2, fresh)
        out = self.new()
        self.le(h, self.zero, fresh, out, out)
        return out

    def eq(self, a, value):
        d = self.new()
        self.op("Subtract", a, self.const(value), d)
        self.p('"Abs" { "srcVar1" "%s" "resultVar" "%s" }' % (d, d))
        r = self.new()
        self.le(d, self.zero, self.one, self.zero, r)
        return r

    def ge(self, a, value):
        r = self.new()
        self.le(self.const(value), a, self.one, self.zero, r)
        return r

    def any_of(self, a, values):
        out = None
        for v in values:
            e = self.eq(a, v)
            if out is None:
                out = e
            else:
                s = self.new()
                self.op("Add", out, e, s)
                out = s
        return out

    def mul(self, *xs):
        out = xs[0]
        for x in xs[1:]:
            r = self.new()
            self.op("Multiply", out, x, r)
            out = r
        return out

    def scale(self, a, k):
        r = self.new()
        self.op("Multiply", a, self.const(k), r)
        return r

    def add(self, a, b):
        r = self.new()
        self.op("Add", a, b, r)
        return r

    def clamp01(self, a):
        lo = self.new()
        self.le(a, self.zero, self.zero, a, lo)
        hi = self.new()
        self.le(lo, self.one, lo, self.one, hi)
        return hi

    def age(self, seq):
        last = self.new()
        start = self.new()
        chg = self.new()
        self.op("Subtract", seq, last, chg)
        self.p('"Abs" { "srcVar1" "%s" "resultVar" "%s" }' % (chg, chg))
        self.le(chg, self.zero, start, self.time, start)
        self.copy(seq, last)
        a = self.new()
        self.op("Subtract", self.time, start, a)
        return a

    def live(self):
        last = self.new()
        armed = self.new()
        start = self.new("-1000")
        d = self.new()
        self.op("Subtract", self.v, last, d)
        self.p('"Abs" { "srcVar1" "%s" "resultVar" "%s" }' % (d, d))
        go = self.mul(d, armed)
        self.le(go, self.zero, start, self.time, start)
        self.copy(self.v, last)
        self.copy(self.one, armed)
        a = self.new()
        self.op("Subtract", self.time, start, a)
        r = self.new()
        self.le(a, self.const(LIVE), self.one, self.zero, r)
        return r

    def full_hud(self):
        return self.mul(self.field(1, FULL_HUD, "full"), self.live())

    def band(self, lo, hi):
        span = self.new()
        self.op("Subtract", hi, lo, span)
        self.op("Add", span, self.const(0.0001), span)
        s = self.new()
        self.op("Divide", self.const(BAND_B - BAND_A), span, s)
        sl = self.new()
        self.op("Multiply", s, lo, sl)
        t = self.new()
        self.op("Subtract", self.const(BAND_A), sl, t)
        self.var("$h_sv", "[1 1]")
        self.var("$h_tv", "[0 0]")
        self.var("$h_c0", "[0 0]")
        self.copy(s, "$h_sv[0]")
        self.copy(t, "$h_tv[0]")
        self.p('"TextureTransform" { "centerVar" "$h_c0" "scaleVar" "$h_sv" "translateVar" "$h_tv" "resultVar" "$texture2transform" }')

    def scroll(self, rate):
        self.var("$h_off", "[0 0]")
        sx = self.new()
        self.p('"LinearRamp" { "rate" "%s" "initialValue" "0" "resultVar" "%s" }' % (fmt(rate), sx))
        self.copy(sx, "$h_off[0]")
        self.p('"TextureTransform" { "translateVar" "$h_off" "resultVar" "$basetexturetransform" }')

    def show(self, cond, into="$alpha", extra=None):
        parts = [cond, self.live()] + ([extra] if extra else [])
        self.copy(self.mul(*parts), into)

    def body(self):
        out = ['\t"%s" "%s"' % (k, v) for k, v in self.head]
        out += ['\t"%s" "%s"' % (k, v) for k, v in self.vars.items()]
        return out

    def proxies(self):
        return ["\t\t" + l for l in self.lines]

    def text(self):
        return ('"%s"\n{\n' % self.shader + "\n".join(self.body()) + '\n\t"Proxies"\n\t{\n'
                + "\n".join(self.proxies()) + "\n\t}\n}\n")
