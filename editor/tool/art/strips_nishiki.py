"""Brocade River: water.png (flowing lines, RGB), leaves.png (maple leaves, RGBA), and the card's
colour.png and material.png with its gold lines. Usage: strips_nishiki.py [output folder]"""
import math, os, random, sys
import numpy as np
from PIL import Image
from lib import *

WATER_W, WATER_H = 120, 24
LEAF_W, LEAF_H = 808, 32
LEAF_CENTRE = 18
LEAF_COUNT, LEAF_RADIUS = 7, 13.5
PPU = 4
SEED = 69


# ---------- water ----------
# Gold lines at these insets from the card edge (units), with their widths. Even rows flow one
# way (R) as long dashes, odd rows the other (G) as short ones. Each line sways about its inset.
WATER_ROWS = [(3.0, 1.4), (7.4, 1.0), (11.6, 1.4), (15.0, .9)]
WATER_SWAY, WATER_WAVES, WATER_PHASE = 1.4, 3, 1.9
WATER_DASHES = {'R': (1, .58), 'G': (2, .55)}  # dashes per period, share of it that is gold


def sway(i, x):
    return WATER_ROWS[i][0] + WATER_SWAY * math.sin(2 * math.pi * WATER_WAVES * x / WATER_W + WATER_PHASE + i)


def ribbon(i, x0, x1, step=.12):
    n = max(2, int((x1 - x0) / step))
    half = WATER_ROWS[i][1] / 2
    top, bot = [], []
    for k in range(n + 1):
        x = x0 + (x1 - x0) * k / n
        dy = (sway(i, x + .05) - sway(i, x - .05)) / .1
        l = math.hypot(dy, 1)
        nx, ny = -dy / l, 1 / l
        y = sway(i, x)
        top.append((x + nx * half, y + ny * half))
        bot.append((x - nx * half, y - ny * half))
    return 'M' + 'L'.join(f'{f(a)} {f(b)}' for a, b in top + bot[::-1]) + 'Z'


def make_water(out):
    groups = {'R': '', 'G': ''}
    for i in range(len(WATER_ROWS)):
        g = 'R' if i % 2 == 0 else 'G'
        count, share = WATER_DASHES[g]
        piece = WATER_W / count
        for j in range(count):
            start = j * piece + i * 9
            groups[g] += f'<path d="{ribbon(i, start, start + piece * share)}" fill="#fff"/>'
    chans = {g: render_mask(wrap_copies(body, WATER_W, 0, 1, 0), WATER_W, WATER_H, PPU, ss=4) for g, body in groups.items()}
    overlap = float((chans['R'] * chans['G']).max())
    save_rgb(os.path.join(out, 'water.png'), chans['R'], chans['G'], chans['R'] * 0)
    return overlap


# ---------- maple leaf ----------
BULGE, TEETH, TOOTH = .08, 3.0, .08
LOBES = [(-118, .5), (-78, .8), (-38, .94), (0, 1.0), (38, .94), (78, .8), (118, .5)]
SINUS = [(-150, .18), (-98, .28), (-58, .32), (-19, .34), (19, .34), (58, .32), (98, .28), (150, .18)]


def polar(deg, r):
    a = math.radians(deg)
    return (r * math.sin(a), -r * math.cos(a))


def lerp(p, q, t):
    return (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t)


def leaf_outline(rng):
    """Closed point list of a maple blade, unit radius, tip of the middle lobe at (0, -1)."""
    pts = [polar(180, .06)]
    for i, (a, l) in enumerate(LOBES):
        l *= 1 + (rng.random() - .5) * .06
        tip = polar(a + (rng.random() - .5) * 3, l)
        for side in (0, 1):
            s_ang, s_r = SINUS[i + side]
            s = polar(s_ang, s_r)
            # flank from sinus to tip (or tip to sinus): bulged curve plus small teeth
            mid = lerp(s, tip, .5)
            dx, dy = tip[0] - s[0], tip[1] - s[1]
            ln = math.hypot(dx, dy)
            nx, ny = (-dy / ln, dx / ln)
            # push the bulge away from the leaf axis (the lobe's own axis)
            ax, ay = polar(a, 1)
            if (mid[0] - 0) * nx + (mid[1] - 0) * ny < 0:
                nx, ny = -nx, -ny
            seg = []
            m = 14
            for k in range(1, m):
                t = k / m
                p = lerp(s, tip, t)
                bulge = BULGE * ln * math.sin(math.pi * t ** .8) ** 1.2
                u = (t * TEETH) % 1
                teeth = TOOTH * ln * u * math.sin(math.pi * t) ** .8
                seg.append((p[0] + nx * (bulge + teeth), p[1] + ny * (bulge + teeth)))
            flank = [s] + seg + [tip]
            if side == 0:
                pts.extend(flank[:-1] if False else flank)
            else:
                pts.extend(flank[::-1][:-1] if False else flank[::-1])
    return pts


def shade(hexc, toward, t):
    a, b = hexrgb(hexc), hexrgb(toward)
    c = a + (b - a) * t
    return '#%02x%02x%02x' % tuple(int(round(v * 255)) for v in c)


def leaf_svg(rng, cx, cy, r, rot, col, uid, vein):
    o = leaf_outline(rng)
    d = 'M' + 'L'.join(f'{f(x)} {f(y)}' for x, y in o) + 'Z'
    dark = shade(col, '#000000', .34)
    edge = shade(col, '#ffffff', .30)
    base = shade(col, '#000000', .20)
    tip = shade(col, '#ffffff', .07)
    veins = ''.join(f'M0 .06L{f(polar(a, .74 * l)[0])} {f(polar(a, .74 * l)[1])}' for a, l in LOBES)
    sw = .035
    return (f'<g transform="translate({f(cx)} {f(cy)}) rotate({f(rot)}) scale({f(r)})">'
            f'<defs><linearGradient id="lg{uid}" x1="0" y1=".5" x2="0" y2="-1"><stop offset="0" stop-color="{base}"/><stop offset="1" stop-color="{tip}"/></linearGradient>'
            f'<clipPath id="lc{uid}"><path d="{d}"/></clipPath></defs>'
            f'<path d="M0 .1Q.03 .4 .09 .66" fill="none" stroke="{dark}" stroke-width=".07" stroke-linecap="round"/>'
            f'<path d="{d}" fill="url(#lg{uid})" stroke="url(#lg{uid})" stroke-width=".02" stroke-linejoin="round"/>'
            f'<g clip-path="url(#lc{uid})"><path d="{d}" fill="none" stroke="{edge}" stroke-opacity=".3" stroke-width=".07" stroke-linejoin="round"/></g>'
            f'<path d="{veins}" fill="none" stroke="{vein}" stroke-opacity=".9" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="M0 .08L0 -.86" fill="none" stroke="{vein}" stroke-opacity=".9" stroke-width=".04" stroke-linecap="round"/>'
            f'</g>')


LEAF_COLOURS = ['#A81E2A', '#8E1B26']
LEAF_VEIN = '#E8C870'


def make_leaves(out):
    rng = random.Random(SEED + 5)
    pitch = LEAF_W / LEAF_COUNT
    body = ''
    for i in range(LEAF_COUNT):
        cx = pitch * (i + .5) + (rng.random() - .5) * pitch * .2
        rot = 60 + rng.random() * 60
        body += leaf_svg(rng, cx, LEAF_CENTRE, LEAF_RADIUS, rot, rng.choice(LEAF_COLOURS), i, LEAF_VEIN)
    arr = render_rgba(body, LEAF_W, LEAF_H, PPU)
    Image.fromarray(arr, 'RGBA').save(os.path.join(out, 'leaves.png'), optimize=True)


# ---------- card: Vanilla's card in the trim colour, with the gold lines ----------
TRIM = '#0E2C3A'
GOLD_STOPS = [(0, '#8E6B26'), (.28, '#D8B25A'), (.5, '#F7E4A3'), (.72, '#D8B25A'), (1, '#8E6B26')]
PAPER_EDGE_WIDTH, RIM_INSET, RIM_WIDTH = 1.6, 1.2, 1.6
BASE_MATERIAL = (0, 10, 0)
GOLD_MATERIAL = (255, 217, 0)


def make_card(out):
    sys.path.insert(0, os.path.dirname(HERE))
    import make_v3_textures as tex
    base = os.path.join(out, 'colour.png')
    tex.render_card(base, TRIM, TRIM, lines=False)
    x, y, w, h = tex.PAPER
    half = PAPER_EDGE_WIDTH / 2
    stops = ''.join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in GOLD_STOPS)
    defs = f'<linearGradient id="g" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="374" y2="525">{stops}</linearGradient>'
    rects = (f'<rect x="{f(x - half)}" y="{f(y - half)}" width="{f(w + PAPER_EDGE_WIDTH)}" height="{f(h + PAPER_EDGE_WIDTH)}" stroke-width="{PAPER_EDGE_WIDTH}"/>'
             f'<rect x="{RIM_INSET}" y="{RIM_INSET}" width="{374 - 2 * RIM_INSET}" height="{525 - 2 * RIM_INSET}" stroke-width="{RIM_WIDTH}"/>')
    lines = render_rgba(f'<g fill="none" stroke="url(#g)">{rects}</g>', 374, 525, tex.PX, defs=defs).astype(np.float32) / 255
    card = np.asarray(Image.open(base).convert('RGB'), np.float32) / 255
    a = lines[..., 3:4]
    Image.fromarray(np.clip((card * (1 - a) + lines[..., :3] * a) * 255 + .5, 0, 255).astype(np.uint8), 'RGB').save(base, optimize=True)
    mat = np.array(BASE_MATERIAL, np.float32) * (1 - a) + np.array(GOLD_MATERIAL, np.float32) * a
    Image.fromarray(np.clip(mat + .5, 0, 255).astype(np.uint8), 'RGB').save(os.path.join(out, 'material.png'), optimize=True)


def preview(d):
    w = np.asarray(Image.open(os.path.join(d, 'water.png')), np.float32) / 255
    lv = np.asarray(Image.open(os.path.join(d, 'leaves.png')), np.float32) / 255
    two = 2
    width = LEAF_W * PPU
    water = np.tile(w, (1, int(np.ceil(width / w.shape[1])), 1))[:, :width]
    trim = hexrgb('#0E2C3A')
    gold = hexrgb('#C9A45A')
    canvas = np.ones((LEAF_H * PPU, width, 3), np.float32) * trim
    m = np.maximum(water[..., 0], water[..., 1])[..., None]
    canvas[:water.shape[0]] = canvas[:water.shape[0]] * (1 - m) + gold * m
    a = lv[..., 3:4]
    canvas = canvas * (1 - a) + lv[..., :3] * a
    img = Image.fromarray(np.clip(canvas * 255 + .5, 0, 255).astype(np.uint8))
    half = img.resize((width // 2, LEAF_H * PPU // 2), Image.LANCZOS)  # 2 px per unit
    zoom = img.crop((0, 0, 1630, LEAF_H * PPU))
    out = Image.new('RGB', (1630, half.height + zoom.height + 6), (255, 255, 255))
    out.paste(half, (0, 0))
    out.paste(zoom, (0, half.height + 6))
    out.save(os.path.join(d, 'preview.png'), optimize=True)


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(OUT, 'nishiki')
    os.makedirs(out, exist_ok=True)
    print('water overlap max', make_water(out))
    make_leaves(out)
    make_card(out)
    preview(out)
