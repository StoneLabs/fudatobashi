"""Seigaiha, asanoha, shippo, yagasuri, kikko sheets (256 units, 4 px/unit, seamless)."""
import math, os
import numpy as np
from lib import *

U = SHEET_UNITS


def finish(name, r, g, b):
    d = os.path.join(OUT, name)
    os.makedirs(d, exist_ok=True)
    save_rgb(os.path.join(d, 'sheet.png'), r, g, b)
    return d


# ---- seigaiha: 14 periods across, rows every r/2, 56 rows ----
def seigaiha():
    n = 14
    r = U / (2 * n)
    lw = .85
    rows = n * 4
    body = ''
    # painter order by row, wrapped copies placed so each row sees the same neighbours
    for j in range(-4, rows + 5):
        cy = j * r / 2
        for i in range(-1, n + 1):
            cx = i * 2 * r + (r if j % 2 == 0 else 0)
            body += f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="#000"/>'
            for k in range(4):
                rr = r * (1 - k / 4) - lw / 2
                body += f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(rr)}" fill="none" stroke="#fff" stroke-width="{lw}"/>'
    R = render_mask(body, U, U, 4)
    return finish('seigaiha', R, R * 0, R * 0), r


# ---- asanoha: triangular lattice with centroid spokes ----
def asanoha():
    nx, ny = 17, 10
    lx = U / nx            # triangle side along x
    ly = U / (ny * math.sqrt(3))  # side that gives the y period
    hgt = ly * math.sqrt(3) / 2   # row height
    lw = .75
    def V(i, row):  # lattice vertex: x in triangle sides, y in rows
        return (i + .5 * (row % 2), row)
    def tri_up(i, row):  # base on row, apex on row+1
        a, b = V(i, row), V(i + 1, row)
        apex = (a[0] + .5, row + 1)
        return a, b, apex
    def tri_dn(i, row):  # base on row+1, apex on row
        a, b = V(i, row + 1), V(i + 1, row + 1)
        apex = (a[0] + .5, row)
        return a, b, apex
    edges = set()
    def add(p, q):
        key = tuple(sorted([(round(p[0], 3), round(p[1], 3)), (round(q[0], 3), round(q[1], 3))]))
        edges.add(key)
    for row in range(-3, ny * 2 + 3):
        for i in range(-3, nx + 4):
            for t in (tri_up(i, row), tri_dn(i, row)):
                a, b, c = t
                add(a, b); add(b, c); add(c, a)
                g = ((a[0] + b[0] + c[0]) / 3, (a[1] + b[1] + c[1]) / 3)
                for v in t:
                    add(v, g)
    def P(p):
        return f'{f(p[0] * lx)} {f(p[1] * hgt)}'
    path = ''.join(f'M{P(p)}L{P(q)}' for p, q in edges)
    body = f'<path d="{path}" fill="none" stroke="#fff" stroke-width="{lw}" stroke-linecap="round" stroke-linejoin="round"/>'
    R = render_mask(body, U, U, 4)
    return finish('asanoha', R, R * 0, R * 0), (lx, ly)


# ---- shippo: circles radius R on a 2R square period, lens fill ----
def shippo():
    Rr = 8.0
    per = 2 * Rr
    n = int(U / per)
    lw = .8
    centres = [(i * per + dx, j * per + dy) for i in range(-1, n + 1) for j in range(-1, n + 1) for dx, dy in ((0, 0), (Rr, Rr))]
    rings = ''.join(f'<circle cx="{f(x)}" cy="{f(y)}" r="{Rr}" fill="none" stroke="#fff" stroke-width="{lw}"/>' for x, y in centres)
    # lens of two circles whose centres are Rr*sqrt2 apart (diagonal neighbours of the lattice)
    d = Rr * math.sqrt(2)
    half = math.sqrt(Rr * Rr - d * d / 4)
    lens = ''
    for x, y in centres:
        for ux, uy in ((1, 1), (1, -1)):  # each lens once: neighbour at (+Rr,+-Rr)
            nx_, ny_ = x + ux * Rr, y + uy * Rr
            mx, my = (x + nx_) / 2, (y + ny_) / 2
            px, py = -uy / math.sqrt(2), ux / math.sqrt(2)  # perpendicular unit
            p1 = (mx + px * half, my + py * half)
            p2 = (mx - px * half, my - py * half)
            lens += (f'<path d="M{f(p1[0])} {f(p1[1])}A{Rr} {Rr} 0 0 1 {f(p2[0])} {f(p2[1])}'
                     f'A{Rr} {Rr} 0 0 1 {f(p1[0])} {f(p1[1])}Z" fill="#fff"/>')
    R = render_mask(rings, U, U, 4)
    G = render_mask(lens, U, U, 4)
    return finish('shippo', R, G, R * 0), Rr


# ---- yagasuri ----
def yagasuri():
    n = 14
    c = U / n
    solid = ''
    lines = ''
    lw_edge, lw_hatch = .55, .4
    def chev(x, y):
        return [(x, y), (x + c / 2, y + .42 * c), (x + c, y), (x + c, y + c), (x + c / 2, y + 1.42 * c), (x, y + c)]
    def poly(pts):
        return 'M' + 'L'.join(f'{f(a)} {f(b)}' for a, b in pts) + 'Z'
    for col in range(-1, n + 1):
        for row in range(-3, n + 2):
            if (col + row) % 2:
                continue
            x, y = col * c, row * c
            solid += f'<path d="{poly(chev(x, y))}" fill="#fff"/>'
            # V edges of the solid half
            top = f'M{f(x)} {f(y)}L{f(x + c / 2)} {f(y + .42 * c)}L{f(x + c)} {f(y)}'
            bot = f'M{f(x)} {f(y + c)}L{f(x + c / 2)} {f(y + 1.42 * c)}L{f(x + c)} {f(y + c)}'
            lines += f'<path d="{top}{bot}" fill="none" stroke="#fff" stroke-width="{lw_edge}" stroke-linejoin="round" stroke-linecap="round"/>'
            # barbs: fine V lines through the open half (the band above this chevron's neighbour)
        for row in range(-3, n + 2):
            if (col + row) % 2 == 0:
                continue
            x, y = col * c, row * c
            for k in (1, 2, 3):
                off = k * c / 4
                lines += (f'<path d="M{f(x)} {f(y + off)}L{f(x + c / 2)} {f(y + .42 * c + off)}L{f(x + c)} {f(y + off)}" '
                          f'fill="none" stroke="#fff" stroke-width="{lw_hatch}" stroke-linejoin="round" stroke-linecap="round"/>')
    G = render_mask(solid, U, U, 4)
    R = render_mask(lines, U, U, 4)
    return finish('yagasuri', R, G, R * 0), c


# ---- kikko ----
def kikko():
    nx, ny = 21, 12
    w = U / nx
    sx = w / math.sqrt(3)
    sy = U / (3 * ny)
    lw = .8
    def hexpath(cx, cy, k):
        pts = []
        for i in range(6):
            a = math.pi / 3 * i
            pts.append((cx + k * sx * math.sin(a) * 1, cy - k * sy * math.cos(a)))
        return 'M' + 'L'.join(f'{f(x)} {f(y)}' for x, y in pts) + 'Z'
    outer = inner = ''
    for i in range(-1, nx + 2):
        for j in range(-1, ny + 2):
            for ox, oy in ((0, 0), (w / 2, 1.5 * sy)):
                cx, cy = i * w + ox, j * 3 * sy + oy
                outer += hexpath(cx, cy, .92)
                inner += hexpath(cx, cy, .62)
    stroke = f'fill="none" stroke="#fff" stroke-width="{lw}" stroke-linejoin="round"'
    R = render_mask(f'<path d="{outer}" {stroke}/>', U, U, 4)
    G = render_mask(f'<path d="{inner}" {stroke}/>', U, U, 4)
    return finish('kikko', R, G, R * 0), (sx, sy)


if __name__ == '__main__':
    import sys
    for fn in (seigaiha, asanoha, shippo, yagasuri, kikko):
        if len(sys.argv) < 2 or fn.__name__ in sys.argv[1:]:
            print(fn.__name__, fn()[1])
