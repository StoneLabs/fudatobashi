"""Dawn Moon skin: dawn-gradient trim with stars (back); moon behind the paper (back); peach mist (front); gold moon foil."""
import math, random
import numpy as np
from card_lib import *

SEED = 21
MOON = (292.0, -6.0, 41.0)
CRATERS = [(-14, 11, 9.5), (9, 15, 6.5), (-1, 27, 4.8), (22, 5, 5.2), (-26, 26, 3.4), (15, 29, 3.0), (-8, 4, 2.6)]
BARS = [(142, 262, 17.4, 5.0, '#F1C6A8', .82), (170, 250, 23.4, 3.2, '#F8DAC2', .75),
        (318, 384, 21.6, 3.4, '#FFFFFF', .55),
        (26, 190, 505.6, 4.6, '#FFE0C6', .92), (58, 148, 510.6, 3.0, '#FFF0E0', .8),
        (206, 356, 506.4, 4.2, '#FFD8BA', .88), (246, 330, 511.4, 2.8, '#FFFFFF', .55),
        (-12, 36, 513.6, 3.2, '#FFFFFF', .5)]


def stars():
    rng = random.Random(SEED)
    out = []
    for x, y in trim_points(rng, 70, 7, edge=2, gap=1.6, keep=lambda x, y: y < 300 and rng.random() < 1 - y / 330):
        out.append((x, y, rng.uniform(.18, .42) * (1 + (y < 120) * .3), rng.uniform(.35, .9)))
    for x, y in trim_points(rng, 8, 30, edge=3, gap=2.2, keep=lambda x, y: y < 200 and math.hypot(x - MOON[0], y - MOON[1]) > 70):
        out.append((x, y, rng.uniform(.5, .75), rng.uniform(.8, 1)))
    return out


def build_back(st):
    col = vgrad([(0, '#0E1230'), (.2, '#1A1B45'), (.42, '#35305D'), (.62, '#68497A'), (.79, '#A96A7C'), (.91, '#D58C7C'), (1, '#E8A683')])
    body = ''.join(f'<circle cx="{f2(x)}" cy="{f2(y)}" r="{f2(r)}" fill="#fff6ea" opacity="{f2(a)}"/>' for x, y, r, a in st)
    s = render(body)
    col = col * (1 - s[..., 3:4]) + s[..., :3] * s[..., 3:4]
    g, defs = moon_svg()
    m = render(g, defs)
    col = col * (1 - m[..., 3:4]) + m[..., :3] * m[..., 3:4]
    return np.dstack([col, np.ones(col.shape[:2], np.float32)])


def moon_svg(mask_only=False):
    cx, cy, r = MOON
    if mask_only:
        return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#fff"/>'
    defs = '''
<radialGradient id="glow" cx="{cx}" cy="{cy}" r="{R}" gradientUnits="userSpaceOnUse">
 <stop offset="{a}" stop-color="#FFF0CC" stop-opacity=".62"/><stop offset=".6" stop-color="#FFE9C0" stop-opacity=".2"/><stop offset="1" stop-color="#FFE9C0" stop-opacity="0"/></radialGradient>
<radialGradient id="disc" cx="{mx}" cy="{my}" r="{r2}" gradientUnits="userSpaceOnUse">
 <stop offset="0" stop-color="#F4ECCF"/><stop offset=".6" stop-color="#EFE4C2"/><stop offset="1" stop-color="#EADFB8"/></radialGradient>
<filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="2.2"/></filter>
<filter id="soft2" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation=".5"/></filter>
<clipPath id="trim"><path d="M0 0H374V525H0ZM{px} {py}H{px2}V{py2}H{px}Z" clip-rule="evenodd"/></clipPath>
<clipPath id="mc"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath>
'''.format(cx=cx, cy=cy, R=r * 2.6, a=f2(1 / 2.6 * .98), mx=cx - 10, my=cy + 8, r2=r * 1.25, r=r, px=PAPER[0], py=PAPER[1], px2=PAPER[0] + PAPER[2], py2=PAPER[1] + PAPER[3])
    g = f'<g clip-path="url(#trim)"><circle cx="{cx}" cy="{cy}" r="{r * 2.6}" fill="url(#glow)"/></g>'
    g += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#disc)"/>'
    g += '<g clip-path="url(#mc)">'
    for dx, dy, cr in CRATERS:
        x, y = cx + dx, cy + dy
        g += f'<circle cx="{f2(x)}" cy="{f2(y)}" r="{f2(cr)}" fill="#E3D5A8" opacity=".3" filter="url(#soft)"/>'
        g += f'<circle cx="{f2(x)}" cy="{f2(y)}" r="{f2(cr * .8)}" fill="#DDCD9E" opacity=".18" filter="url(#soft2)"/>'
    g += '</g>'
    return g, defs


def bars_svg():
    out = ''
    for x0, x1, y, h, c, op in BARS:
        out += f'<g opacity="{op}">{lens_bar(x0, x1, y, h, "url(#m_" + c[1:] + ")")}</g>'
    return out


def bar_defs():
    d = ''
    for c in {b[4] for b in BARS}:
        k = c[1:]
        d += (f'<linearGradient id="m_{k}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="{c}" stop-opacity=".4"/>'
              f'<stop offset=".16" stop-color="{c}"/><stop offset=".84" stop-color="{c}"/><stop offset="1" stop-color="{c}" stop-opacity=".4"/></linearGradient>')
    return d


def build_front():
    return render(bars_svg(), bar_defs())


def build_foil():
    cx, cy, r = MOON
    mm = mask(moon_svg(True))
    # foil: the moon's disc; the set script decides how metallic it is
    R = mm
    h = np.zeros_like(mm)
    bm = mask(''.join(lens_bar(x0, x1, y, hh, '#fff') for x0, x1, y, hh, c, op in BARS))
    h = h + gblur(bm, 2.2) * .22
    return R, np.clip(h, 0, 1) * 1.0


def build():
    st = stars()
    back = build_back(st)
    save(back, os.path.join(ROOT, 'ariake', 'back.png'), dither=True)
    front = build_front()
    save_front(front, os.path.join(ROOT, 'ariake', 'front.png'))
    R, G = build_foil()
    save_foil(R, G, os.path.join(ROOT, 'ariake', 'foil.png'))
    kw = dict(shade='#0E1028', badge_ring='#8D8796')
    preview(os.path.join(ROOT, 'ariake'), back, front, (R, G), **kw)
    preview(os.path.join(ROOT, 'ariake'), back, front, (R, G), guides=True, name='preview_guides.png', **kw)


if __name__ == '__main__':
    build()
