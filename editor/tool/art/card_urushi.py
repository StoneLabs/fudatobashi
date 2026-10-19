"""Lacquer and Vermilion skin: black lacquer (back), four gold corner brackets (front), foil with kirikane flecks."""
import math, random
import numpy as np
from card_lib import *

A, TX, TY, TIP = 44.0, 22.9, 24.6, 9.0
RIVETS = [(TX / 2, TY / 2), (A * .66, TY / 2), (TX / 2, A * .66)]
RIVET_R = 2.45
CROP = 64
BEVEL_U, GROOVE_U = 1.7, 3.1
GOLD_LIGHT, GOLD_BASE, GOLD_DARK, EDGE_DARK = '#E6C979', '#C9A45A', '#9A7836', '#5E4415'
LIGHT = np.array([-.52, -.62, .6], np.float32)


def bracket_path():
    return (f'M0 0H{A}L{A + TIP} {f2(TY / 2)}L{A} {TY}H{TX + 6}A6 6 0 0 0 {TX} {TY + 6}V{A}L{f2(TX / 2)} {A + TIP}L0 {A}Z')


def edt_inside(m, rmax):
    """Distance in pixels from each inside pixel to the nearest outside pixel (capped at rmax)."""
    h, w = m.shape
    out = ~m
    d = np.full(m.shape, float(rmax), np.float32)
    pad = np.pad(out, rmax, constant_values=True)
    offs = sorted(((dx, dy) for dx in range(-rmax, rmax + 1) for dy in range(-rmax, rmax + 1)
                   if 0 < dx * dx + dy * dy <= rmax * rmax), key=lambda o: o[0] ** 2 + o[1] ** 2)
    for dx, dy in offs:
        r = math.hypot(dx, dy)
        sh = pad[rmax + dy:rmax + dy + h, rmax + dx:rmax + dx + w]
        d = np.where(sh & (r < d), r, d)
    return np.where(m, d, 0)


def corner_fields():
    """Height field and alpha of the top-left bracket in a 64-unit crop."""
    a = render(f'<path d="{bracket_path()}" fill="#fff"/>', w=CROP, h=CROP)[..., 3]
    d = edt_inside(a > .5, 14) / S  # units
    # subpixel edge: refine with the antialiased alpha
    d = np.where(a > .5, gblur(d, 2.2), 0)
    bevel = np.clip(d / BEVEL_U, 0, 1)
    h = bevel * bevel * (3 - 2 * bevel) * .62
    h -= .2 * np.exp(-((d - GROOVE_U) / .42) ** 2)
    yy, xx = (np.mgrid[0:CROP * S, 0:CROP * S].astype(np.float32) + .5) / S
    rim_mask = np.zeros_like(h)
    for rx, ry in RIVETS:
        rho = np.hypot(xx - rx, yy - ry)
        t = np.clip(rho / RIVET_R, 0, 1)
        dome = 1 - t * t * (3 - 2 * t) * .0 - t ** 2
        h = np.where(rho < RIVET_R + .4, np.maximum(h, .62) + .3 * np.clip(dome, 0, 1) ** .9 * np.clip((RIVET_R + .4 - rho) / .4, 0, 1), h)
        rim_mask = np.maximum(rim_mask, np.clip((RIVET_R - rho) * S + .5, 0, 1).astype(np.float32))
    return a, np.clip(h, 0, 1), d, rim_mask


def place(field, flip_x, flip_y):
    f = field[:, ::-1] if flip_x else field
    f = f[::-1, :] if flip_y else f
    return f


def full_from(field):
    out = np.zeros((PXH, PXW), np.float32)
    c = CROP * S
    out[:c, :c] = place(field, 0, 0)
    out[:c, PXW - c:] = place(field, 1, 0)
    out[PXH - c:, :c] = place(field, 0, 1)
    out[PXH - c:, PXW - c:] = place(field, 1, 1)
    return out


def build_front():
    a, h, d, rv = corner_fields()
    al, hh, dd, rr = (full_from(x) for x in (a, h, d, rv))
    gy, gx = np.gradient(hh)
    k = 3.2 * 1.0
    n = np.dstack([-gx * k * S, -gy * k * S, np.ones_like(hh)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    L = LIGHT / np.linalg.norm(LIGHT)
    diff = np.clip((n * L).sum(2), 0, 1)
    flat = float((np.array([0, 0, 1]) * L).sum())
    Hh = L + np.array([0, 0, 1], np.float32)
    Hh /= np.linalg.norm(Hh)
    spec = np.clip((n * Hh).sum(2), 0, 1) ** 28
    yy, xx = yy_xx()
    # base colour: lighter toward each bracket's own outer corner, in screen space
    ux = np.minimum(xx, W - xx)
    uy = np.minimum(yy, H - yy)
    t = np.clip((ux + uy) / (A + TY), 0, 1)
    sx = np.where(xx < W / 2, 1, -1)
    sy = np.where(yy < H / 2, 1, -1)
    gl = np.clip(.5 + (-(ux - uy) * 0) , 0, 1)
    base = hex_rgb(GOLD_BASE)[None, None, :] * (1 - t[..., None] * .25) + hex_rgb(GOLD_LIGHT)[None, None, :] * 0
    base = hex_rgb(GOLD_LIGHT) * (1 - t[..., None]) + hex_rgb(GOLD_DARK) * t[..., None] * .55 + hex_rgb(GOLD_BASE) * t[..., None] * .45
    shade = (.84 + .3 * diff / max(flat, .3))[..., None]
    col = base * shade + spec[..., None] * hex_rgb('#FFF1C4') * .55
    # dark inner edge line
    edge = np.clip(1 - dd / .62, 0, 1)[..., None] ** 1.2
    col = col * (1 - edge * .6) + hex_rgb(EDGE_DARK) * edge * .6
    # rivets: paler gold
    rsh = gblur(np.roll(np.roll(rr, 3, 0), 3, 1), 2.4) * (1 - rr)
    col = col * (1 - .42 * rsh[..., None]) + hex_rgb(EDGE_DARK) * .42 * rsh[..., None] * 0.0
    col = col * (1 - rr[..., None]) + (col * .95 + hex_rgb('#F7E4A3') * .12) * rr[..., None]
    col = np.clip(col, 0, 1)
    shadow = gblur(np.roll(np.roll(al, 3, 0), 2, 1), 4.2) * .4
    ao = al + shadow * (1 - al)
    rgb = (col * al[..., None] + hex_rgb('#140D06') * (shadow * (1 - al))[..., None]) / np.maximum(ao, 1e-4)[..., None]
    return np.dstack([rgb, ao]), al, hh


def build_back():
    yy, xx = yy_xx()
    base = hex_rgb('#0D0B0A')
    g1 = np.exp(-(((xx - 30) / 260) ** 2 + ((yy - 40) / 300) ** 2))
    g2 = np.exp(-(((xx - 350) / 220) ** 2 + ((yy - 500) / 260) ** 2))
    band = np.exp(-(((xx + yy * .35 - 230) / 70) ** 2)) * .5
    warm = hex_rgb('#2A1D17')
    cool = hex_rgb('#181210')
    t1 = (g1 * .85 + band * .12)[..., None]
    t2 = (g2 * .55)[..., None]
    col = base + (warm - base) * t1 + (cool - base) * t2
    return np.dstack([np.clip(col, 0, 1), np.ones_like(yy)])


def flecks(al):
    rng = random.Random(58)
    px, py, pw, ph = PAPER
    bx, by, br = BADGE
    pts = []
    tries = 0
    while len(pts) < 150 and tries < 100000:
        tries += 1
        x, y = rng.uniform(1.5, W - 1.5), rng.uniform(1.5, H - 1.5)
        if px - 3 < x < px + pw + 3 and py - 3 < y < py + ph + 3:
            continue
        ux, uy = min(x, W - x), min(y, H - y)
        if ux < A + 6 and uy < A + 6 and (ux < A + TIP + 3 and uy < A + TIP + 3):
            continue
        dens = .35 + .65 * (.5 + .5 * math.sin(x / 31 + 1.3) * math.sin(y / 47 + .4))
        if rng.random() > dens:
            continue
        if all((x - a_) ** 2 + (y - b_) ** 2 > 5.5 ** 2 for a_, b_, *_ in pts):
            pts.append((x, y, rng.uniform(.3, 1.2), rng.uniform(.6, 1.0), rng.uniform(0, 180), rng.choice([0, 0, 1, 2])))
    body = ''
    for x, y, s, amt, rot, kind in pts:
        if kind == 0:
            w_, h_ = s, s * rng.uniform(.45, .9)
            shape = f'<rect x="{f2(-w_ / 2)}" y="{f2(-h_ / 2)}" width="{f2(w_)}" height="{f2(h_)}"/>'
        elif kind == 1:
            shape = f'<path d="M{f2(-s / 2)} {f2(s * .3)}L{f2(s / 2)} {f2(s * .25)}L{f2(s * .05)} {f2(-s * .45)}Z"/>'
        else:
            shape = f'<path d="M{f2(-s * .5)} {f2(-s * .1)}L{f2(-s * .1)} {f2(-s * .35)}L{f2(s * .5)} {f2(s * .05)}L{f2(s * .15)} {f2(s * .33)}Z"/>'
        v = f2(amt)
        body += f'<g transform="translate({f2(x)} {f2(y)}) rotate({f2(rot)})" fill="rgb({int(amt*255)},0,0)">{shape}</g>'
    return render(body, bg='#000')[..., 0], len(pts)


def build():
    back = build_back()
    save(back, os.path.join(ROOT, 'urushi', 'back.png'), dither=True)
    front, al, hh = build_front()
    save_front(front, os.path.join(ROOT, 'urushi', 'front.png'))
    fl, n = flecks(al)
    R = np.clip(np.maximum(al, fl), 0, 1)
    save_foil(R, hh * (al > .02), os.path.join(ROOT, 'urushi', 'foil.png'))
    print('flecks', n)
    kw = dict(shade='#D13A22', badge_ring='#B0402A', paper_fill='#EDEAE3', hi='#EDEAE300')
    preview(os.path.join(ROOT, 'urushi'), back, front, (R, hh * (al > .02)), **kw)
    preview(os.path.join(ROOT, 'urushi'), back, front, (R, hh * (al > .02)), guides=True, name='preview_guides.png', **kw)


if __name__ == '__main__':
    build()
