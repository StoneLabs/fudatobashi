"""Snow on Fuji skin: night-sky trim, Mt Fuji with mist (front) and gold foil on stars and ridge."""
import math, random
import numpy as np
from card_lib import *

CX, Y_TOP, Y_BASE = 187.0, 483.6, 516.0
HW_TOP, HW_BASE = 8.5, 66.0
SNOW_FRAC = .55
SEED = 44
EDGE = '#5A72AE'


def hw_at(s, side):
    """Half width of the cone at height fraction s above the base (1 = summit)."""
    k = 1 - s
    w = HW_TOP + (HW_BASE - HW_TOP) * (.55 * k + .45 * k ** 2.2)
    w *= 1 + .012 * math.sin(s * 17 + side * 2.1) + .008 * math.sin(s * 41 + side)
    return w * (1.05 if side > 0 else 1.0)


def ysum(s):
    return Y_BASE - s * (Y_BASE - Y_TOP)


def profile(inset=0.0, s_min=-.1):
    """Silhouette polyline (left base -> summit -> right base), optionally inset."""
    pts = []
    n = 90
    for i in range(n + 1):
        s = s_min + (1 - s_min) * i / n
        pts.append((CX - hw_at(s, -1) + inset, ysum(s) + (inset if s > .97 else 0)))
    rim = [(-9, .7), (-6.8, .15), (-5, 0), (-2.6, .35), (-.4, .6), (2, .4), (4.6, 0), (6.6, .15), (9, .7)]
    pts += [(CX + dx * (1 - inset * .06), Y_TOP + dy + inset) for dx, dy in rim[1:-1]]
    for i in range(n, -1, -1):
        s = s_min + (1 - s_min) * i / n
        pts.append((CX + hw_at(s, 1) - inset, ysum(s) + (inset if s > .97 else 0)))
    return pts


def poly(pts, close=True):
    return 'M' + 'L'.join(f'{f2(x)} {f2(y)}' for x, y in pts) + ('Z' if close else '')


def chaikin(pts, it=1):
    for _ in range(it):
        out = []
        for a, b in zip(pts, pts[1:]):
            out += [(a[0] * .75 + b[0] * .25, a[1] * .75 + b[1] * .25), (a[0] * .25 + b[0] * .75, a[1] * .25 + b[1] * .75)]
        pts = [pts[0]] + out + [pts[-1]]
    return pts


def flank_lean(x):
    """Horizontal run per unit of descent along the cone's flank at x (0 on the axis, outward either side)."""
    s = SNOW_FRAC
    side = 1 if x > CX else -1
    dy = ysum(s - .05) - ysum(s)
    return side * (hw_at(s - .05, side) - hw_at(s, side)) / dy * min(abs(x - CX) / 25, 1)


def snow_line():
    """Snow line (path commands, left to right): an uneven wave with a few tapered tongues that run down
    the gullies along the flanks, diagonal on the sides and steeper near the middle, uneven in length and spacing."""
    rng = random.Random(8)
    y0 = ysum(SNOW_FRAC)
    ph = rng.uniform(0, 6)

    def base(x):
        return y0 + 1.1 * math.sin(x / 11 + ph) + .7 * math.sin(x / 4.3 + ph * 2) + (x - CX) * .012

    x_start, x_end = CX - 64, CX + 68
    tongues_in = []
    x = x_start + rng.uniform(2, 5)
    while x < x_end - 5:
        w = rng.uniform(1.4, 3.4)
        mid = 1 - min(abs(x - CX) / 64, 1)
        d = (2.0 + 6.5 * mid ** 1.1) * rng.choice([.45, .7, 1.0, 1.25]) + rng.uniform(0, 1.2)
        tongues_in.append((x + w / 2, w, d))
        x += w + rng.choice([rng.uniform(1.5, 3.5), rng.uniform(3, 7), rng.uniform(6, 11)])
    cmds, tongues = [], []
    cur = x_start
    for xc, w, d in tongues_in:
        xl, xr = xc - w / 2, xc + w / 2
        while cur < xl:
            cur = min(cur + 2.0, xl)
            cmds.append(f'L{f2(cur)} {f2(base(cur))}')
        ax, ay = xc + flank_lean(xc) * d, base(xc) + d
        bend = flank_lean(xc) * d * .25
        cmds.append(f'Q{f2(xl + bend)} {f2(base(xl) + d * .5)} {f2(ax)} {f2(ay)}')
        cmds.append(f'Q{f2(xr + bend * 1.6)} {f2(base(xr) + d * .45)} {f2(xr)} {f2(base(xr))}')
        cur = xr
        tongues.append((ax, ay, d))
    while cur < x_end:
        cur = min(cur + 2.0, x_end)
        cmds.append(f'L{f2(cur)} {f2(base(cur))}')
    return cmds, tongues, (x_start, base(x_start))


def sky_stars():
    rng = random.Random(SEED)
    stars = []
    big = trim_points(rng, 6, 55, edge=4, gap=3, keep=lambda x, y: y < 495)
    mid = trim_points(rng, 14, 18, edge=3, gap=2.2)
    tiny = trim_points(rng, 105, 5.5, edge=2, gap=1.6)
    for x, y in big:
        stars.append((x, y, rng.uniform(.95, 1.25), 1.0, 'big'))
    for x, y in mid:
        stars.append((x, y, rng.uniform(.42, .68), rng.uniform(.8, 1), 'mid'))
    for x, y in tiny:
        stars.append((x, y, rng.uniform(.17, .38), rng.uniform(.4, .9), 'tiny'))
    return stars


def stars_svg(stars):
    defs = ('<radialGradient id="sg"><stop offset="0" stop-color="#cfe0ff" stop-opacity=".55"/>'
            '<stop offset=".35" stop-color="#9fb8f0" stop-opacity=".18"/><stop offset="1" stop-color="#9fb8f0" stop-opacity="0"/></radialGradient>')
    b = ''
    for x, y, r, a, k in stars:
        if k == 'big':
            b += f'<circle cx="{f2(x)}" cy="{f2(y)}" r="{f2(r * 4.2)}" fill="url(#sg)"/>'
            L = r * 4.2
            b += (f'<path d="M{f2(x - L)} {f2(y)}L{f2(x)} {f2(y - .09)}L{f2(x + L)} {f2(y)}L{f2(x)} {f2(y + .09)}Z'
                  f'M{f2(x)} {f2(y - L * .9)}L{f2(x + .09)} {f2(y)}L{f2(x)} {f2(y + L * .9)}L{f2(x - .09)} {f2(y)}Z" fill="#eef4ff" opacity=".75"/>')
        b += f'<circle cx="{f2(x)}" cy="{f2(y)}" r="{f2(r)}" fill="#f4f8ff" opacity="{f2(a)}"/>'
    return b, defs


def build_back(stars):
    col = vgrad([(0, '#070E28'), (.3, '#101E4E'), (.62, '#21376A'), (.86, '#17274F'), (1, '#0E1838')])
    yy, xx = yy_xx()
    rng = random.Random(SEED + 5)
    hz = np.zeros_like(yy)
    for _ in range(9):
        yc, sg, am, ph = rng.uniform(15, 510), rng.uniform(2.5, 9), rng.uniform(.04, .08), rng.uniform(0, 6.28)
        hz += am * np.exp(-((yy - yc) / sg) ** 2 / 2) * (.7 + .3 * np.sin(xx / 70 + ph))
    hz = np.clip(hz, 0, .16)[..., None]
    col = col * (1 - hz) + hex_rgb('#6F8FD2') * hz
    sb, sdefs = stars_svg(stars)
    st = render(sb, sdefs)
    col = col * (1 - st[..., 3:4]) + st[..., :3] * st[..., 3:4]
    return np.dstack([col, np.ones_like(yy)])


BARS = [(5, 98, 509.2, 4.2, 'bar', .9), (34, 80, 513.6, 2.8, 'bar2', .72),
        (128, 240, 510.2, 3.0, 'bar', .5), (224, 337, 509.6, 4.4, 'bar', .88), (262, 320, 514, 2.8, 'bar2', .7),
        (338, 380, 505.6, 3.0, 'bar2', .55)]


def bars_svg(only_mask=False):
    out = ''
    for x0, x1, y, h, kind, op in BARS:
        fill = '#fff' if only_mask else ('url(#mist)' if kind == 'bar' else 'url(#mist2)')
        g = lens_bar(x0, x1, y, h, fill)
        out += g if only_mask else f'<g opacity="{op}">{g}</g>'
    return out


def snow_path():
    cmds, tongues, (x0, y0) = snow_line()
    xe = CX + 130
    head = f'M{CX - 130} {Y_TOP - 20}V{f2(y0)}H{f2(x0)}'
    region = head + ''.join(cmds) + f'H{xe}V{Y_TOP - 20}Z'
    line = f'M{f2(x0)} {f2(y0)}' + ''.join(cmds)
    return region, tongues, line


def build_front(stars):
    sil = profile()
    sl, tongues, sl_line = snow_path()
    defs = f'''
<clipPath id="sil"><path d="{poly(sil)}"/></clipPath>
<clipPath id="snow"><path d="{sl}"/></clipPath>
<linearGradient id="body" gradientUnits="userSpaceOnUse" x1="0" y1="{f2(ysum(SNOW_FRAC))}" x2="0" y2="{Y_BASE + 3}">
 <stop offset="0" stop-color="#8CA0CE"/><stop offset=".5" stop-color="#6A82B8"/><stop offset="1" stop-color="#3C5490"/></linearGradient>
<linearGradient id="side" gradientUnits="userSpaceOnUse" x1="{CX - 10}" y1="0" x2="{CX + 70}" y2="0">
 <stop offset="0" stop-color="#0E1A4A" stop-opacity="0"/><stop offset="1" stop-color="#0E1A4A" stop-opacity=".5"/></linearGradient>
<linearGradient id="sshade" gradientUnits="userSpaceOnUse" x1="{CX - 6}" y1="0" x2="{CX + 36}" y2="0">
 <stop offset="0" stop-color="#9DB3E0" stop-opacity="0"/><stop offset="1" stop-color="#9DB3E0" stop-opacity=".75"/></linearGradient>
<linearGradient id="snowv" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#E9F0FD"/></linearGradient>
<linearGradient id="streak" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E4ECFB" stop-opacity=".55"/><stop offset="1" stop-color="#E4ECFB" stop-opacity="0"/></linearGradient>
<linearGradient id="hill1" gradientUnits="userSpaceOnUse" x1="0" y1="507" x2="0" y2="525"><stop offset="0" stop-color="#1D2F66"/><stop offset="1" stop-color="#0F1A3E"/></linearGradient>
<linearGradient id="hill2" gradientUnits="userSpaceOnUse" x1="0" y1="510" x2="0" y2="525"><stop offset="0" stop-color="#14224F"/><stop offset="1" stop-color="#0B1534"/></linearGradient>
<linearGradient id="mist" gradientUnits="objectBoundingBox" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#EEF3FF" stop-opacity=".45"/><stop offset=".16" stop-color="#EEF3FF"/><stop offset=".84" stop-color="#EEF3FF"/><stop offset="1" stop-color="#EEF3FF" stop-opacity=".45"/></linearGradient>
<linearGradient id="mist2" gradientUnits="objectBoundingBox" x1="0" y1="0" x2="1" y2="0">
 <stop offset="0" stop-color="#B9C6E4" stop-opacity=".4"/><stop offset=".18" stop-color="#B9C6E4"/><stop offset=".82" stop-color="#B9C6E4"/><stop offset="1" stop-color="#B9C6E4" stop-opacity=".4"/></linearGradient>
'''
    rng = random.Random(3)
    fuji = (f'<g clip-path="url(#sil)"><rect x="{CX - 130}" y="{Y_TOP - 4}" width="260" height="60" fill="url(#body)"/>'
            f'<rect x="{CX - 130}" y="{Y_TOP - 4}" width="260" height="60" fill="url(#side)"/>'
            f'<g clip-path="url(#snow)"><rect x="{CX - 130}" y="{Y_TOP - 4}" width="260" height="60" fill="url(#snowv)"/>'
            f'<rect x="{CX - 130}" y="{Y_TOP - 4}" width="260" height="60" fill="url(#sshade)"/></g>'
            f'<path d="{sl_line}" fill="none" stroke="#6F8AC4" stroke-width=".45" stroke-opacity=".55" stroke-linejoin="round"/></g>'
            f'<path d="{poly(sil[:-1 - 0])}" fill="none" stroke="{EDGE}" stroke-opacity=".55" stroke-width=".3" stroke-linejoin="round" clip-path="url(#nobase)"/>')
    defs += f'<clipPath id="nobase"><rect x="0" y="0" width="374" height="{Y_BASE - 1}"/></clipPath>'
    hills = ''
    rngh = random.Random(12)

    def ridge(y, amp, fill):
        pts = []
        for i in range(0, 375, 4):
            pts.append((i, y + amp * math.sin(i / 38 + 1) + amp * .5 * math.sin(i / 17 + 2)
                        + (-2.5 if abs(i - CX) < 90 else 0) * 0 + max(0, (abs(i - CX) - 90)) * .015))
        return f'<path d="{poly(pts + [(374, 526), (0, 526)])}" fill="{fill}"/>'

    hills = ridge(511.6, 1.0, 'url(#hill1)') + ridge(514.6, .8, 'url(#hill2)')
    mist = bars_svg()
    front = render(fuji + hills + mist, defs)
    return front, sil, (sl, tongues)


def build_foil(stars, sil, sl):
    sl = sl[0]
    S_ = S
    # relief: snow cap and mist bars
    clip = f'<clipPath id="c"><path d="{poly(sil)}"/></clipPath>'
    snow_region = sl
    snow = mask(f'<g clip-path="url(#c)"><path d="{snow_region}" fill="#fff"/></g>', clip)
    barm = mask(bars_svg(True), '')
    h = gblur(snow, 2.4) * .62 + gblur(barm, 2.0) * .34
    # gold ridge line just inside the silhouette top edge
    inner = profile(inset=.75)
    ridge_pts = [p for p in inner if p[1] < ysum(SNOW_FRAC) - 1.0]
    cut = ridge_pts
    rm = mask(f'<g clip-path="url(#c2)"><path d="{poly(cut, False)}" fill="none" stroke="#fff" stroke-width=".5" stroke-linecap="round" stroke-linejoin="round"/></g>',
              f'<clipPath id="c2"><path d="{snow_region}"/></clipPath>')
    sm = []
    for x, y, r, a, k in stars:
        if k == 'big':
            sm.append(f'<circle cx="{f2(x)}" cy="{f2(y)}" r="{f2(r * .95)}" fill="#fff"/>')
        elif k == 'mid' and r > .56:
            sm.append(f'<circle cx="{f2(x)}" cy="{f2(y)}" r="{f2(r * .9)}" fill="#fff" fill-opacity=".8"/>')
    stm = mask(''.join(sm))
    R = np.clip(rm * .95 + stm, 0, 1)
    h = h + gblur(rm, 1.4) * .5 + gblur(stm, 1.2) * .45
    return R, np.clip(h, 0, 1)


def build():
    stars = sky_stars()
    back = build_back(stars)
    save(back, os.path.join(ROOT, 'fuji', 'back.png'), dither=True)
    front, sil, sl = build_front(stars)
    save_front(front, os.path.join(ROOT, 'fuji', 'front.png'))
    R, G = build_foil(stars, sil, sl)
    save_foil(R, G, os.path.join(ROOT, 'fuji', 'foil.png'))
    kw = dict(shade='#0D173A', badge_ring='#7D8499', paper_fill='#EAEAEA')
    preview(os.path.join(ROOT, 'fuji'), back, front, (R, G), **kw)
    preview(os.path.join(ROOT, 'fuji'), back, front, (R, G), guides=True, name='preview_guides.png', **kw)


if __name__ == '__main__':
    build()
