"""Petals sheet: R white petals, G pink petals, B shading (soft centre crease, darker base)."""
import math, os, random
import numpy as np
from lib import *

U = SHEET_UNITS
SEED = 33
COUNT = 46
PINK_SHARE = .36
LEN_RANGE = (6.2, 10.8)  # petal length in units
GAP = 3.0                # clear space between petals, units


def petal_shape(rng):
    """Unit-length petal about (0,0): notched tip at y = -0.5, pointed base at y = +0.5."""
    k = 1 + (rng.random() - .5) * .14      # left/right asymmetry
    w = 1 + (rng.random() - .5) * .12      # overall plumpness
    n = .095 + rng.random() * .025         # notch depth below the lobe tips
    L, R = k, 1 / k
    return (f'M0 .5C{f(-.20 * w * L)} .2 {f(-.27 * w * L)} -.2 {f(-.105 * L)} -.468'
            f'Q{f(-.075 * L)} -.505 {f(-.04 * L)} -.455L0 {f(-.5 + n)}'
            f'L{f(.04 * R)} -.455Q{f(.075 * R)} -.505 {f(.105 * R)} -.468'
            f'C{f(.27 * w * R)} -.2 {f(.20 * w * R)} .2 0 .5Z')


def place(rng):
    pts = []
    tries = 0
    while len(pts) < COUNT and tries < 200000:
        tries += 1
        ln = LEN_RANGE[0] + (LEN_RANGE[1] - LEN_RANGE[0]) * rng.random() ** 1.3
        r = ln / 2
        m = r + .6
        x = m + rng.random() * (U - 2 * m)
        y = m + rng.random() * (U - 2 * m)
        ok = True
        for px, py, pr, _ in pts:
            dx = abs(x - px); dx = min(dx, U - dx)
            dy = abs(y - py); dy = min(dy, U - dy)
            if math.hypot(dx, dy) < r + pr + GAP + 4:
                ok = False
                break
        if ok:
            pts.append((x, y, r, ln))
    return pts


def make():
    rng = random.Random(SEED)
    pts = place(rng)
    white, pink, shade = '', '', ''
    defs = ('<linearGradient id="gb" x1="0" y1="-.5" x2="0" y2=".5" gradientUnits="userSpaceOnUse">'
            '<stop offset="0" stop-color="#fff"/><stop offset=".55" stop-color="#e4e4e4"/><stop offset="1" stop-color="#7a7a7a"/></linearGradient>'
            '<filter id="bl" x="-.5" y="-.5" width="2" height="2"><feGaussianBlur stdDeviation=".035"/></filter>'
            '<filter id="bl2" x="-.5" y="-.5" width="2" height="2"><feGaussianBlur stdDeviation=".06"/></filter>')
    n_pink = round(len(pts) * PINK_SHARE)
    kinds = ['p'] * n_pink + ['w'] * (len(pts) - n_pink)
    rng.shuffle(kinds)
    for (x, y, r, ln), kind in zip(pts, kinds):
        rot = rng.random() * 360
        d = petal_shape(rng)
        tr = f'translate({f(x)} {f(y)}) rotate({f(rot)}) scale({f(ln)})'
        shape = f'<path d="{d}" transform="{tr}" fill="#fff"/>'
        if kind == 'w':
            white += shape
        else:
            pink += shape
        cid = f'c{len(shade)}'
        crease_depth = .28 + rng.random() * .1
        shade += (f'<g transform="{tr}"><clipPath id="{cid}"><path d="{d}"/></clipPath>'
                  f'<g clip-path="url(#{cid})">'
                  f'<rect x="-.7" y="-.7" width="1.4" height="1.4" fill="url(#gb)"/>'
                  f'<path d="M0 .5L0 -.36" stroke="#000" stroke-opacity="{f(crease_depth)}" stroke-width=".08" stroke-linecap="round" filter="url(#bl2)" fill="none"/>'
                  f'<path d="M0 .5L-.2 -.05M0 .5L.2 -.05" stroke="#000" stroke-opacity="{f(crease_depth * .5)}" stroke-width=".045" stroke-linecap="round" filter="url(#bl)" fill="none"/>'
                  f'</g></g>')
    R = render_mask(white, U, U, 4, defs=defs)
    G = render_mask(pink, U, U, 4, defs=defs)
    B = render_mask(shade, U, U, 4, defs=defs)
    d = os.path.join(OUT, 'petals')
    os.makedirs(d, exist_ok=True)
    save_rgb(os.path.join(d, 'sheet.png'), R, G, B)
    return len(pts)


if __name__ == '__main__':
    print(make())
