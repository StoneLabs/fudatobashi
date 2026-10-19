"""Image files of the format 3 skins, made from the format 2 skins' textures and colours.
Used by migrate_v3.py; needs PIL, numpy and rsvg-convert.

Files are card-aligned at 4 pixels per card unit (1496 x 2100) unless they are pattern sheets (1024 x 1024).
Normal maps are OpenGL style: green points up the card. Images are straight (not premultiplied) RGBA.
"""
import os
import re
import subprocess
import tempfile

import numpy as np
from PIL import Image

CARD_W, CARD_H = 374, 525
PX = 4
W, H = CARD_W * PX, CARD_H * PX
SHEET = 1024
PAPER = (17.34, 19.65, 339.36, 485.79)

# The app's card and the two colours of it a recolour replaces.
CARD_SVG = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'cards', 'torifuda', 'default.svg')
SVG_TRIM, SVG_OUTER_LINE = '#6A9354', '#66904F'

# Oni: v2 art shader values baked into the files.
ONI_GOLD = (1.0, 0.906, 0.659)
ONI_FLAKE = (0.75, 0.56, 0.24)
ONI_FLAKE_MIX, ONI_FLAKE_DENSITY, ONI_FLAKE_TILE = 0.55, 0.35, 94 * 1.6
ONI_LACQUER_TILE, ONI_LACQUER_STRENGTH = 170, 0.35
ONI_GLOSS_LACQUER, ONI_GLOSS_GOLD, ONI_FLAKE_METAL = 0.45, 0.8, 0.8
ONI_UNDER = '#D2AE58'

# Suminagashi: v2 paint shader colours, the sheet's ground then its R, G and B. The sheet is the marbled
# paper; colour.png lays a see-through navy wash over it on the trim (fitted to the old trim colours).
SUMI_PAPER = ['#EFE9DB', '#A3A3AB', '#93A6C6', '#B8892C']
SUMI_TRIM_WASH, SUMI_TRIM_ALPHA = '#000E2A', 0.85
SUMI_METAL = [0, 0, 0, 0.6]
SUMI_GLOSS_PAPER, SUMI_GLOSS_GOLD = 0.04, 0.5
SUMI_WASHI_TILE, SUMI_WASHI_STRENGTH, SUMI_SHEET_SCALE = 170, 0.1, 0.46

# Tatsuta: v2 ramp shader values. The window scale shrinks so the card never reaches the sheet's
# edge at any rotation, and the sheet is stretched to match, so the card looks the same.
TATSUTA_OLD_SCALE, TATSUTA_SCALE = 0.62, 0.56
TATSUTA_SHEET_SCALE, TATSUTA_MOTIF_SHIFT, TATSUTA_MOTIF_SHADE, TATSUTA_MOTIF_BRIGHT, TATSUTA_LIGHT_LINES = 1.6, 0.3, 0.2, 0.8, 0.6
TATSUTA_LINE_WHITE = (0.97, 0.96, 0.94)
TATSUTA_PAPER, TATSUTA_PAPER_ALPHA = (0.975, 0.958, 0.935), 0.78
TATSUTA_METAL_GLOSS = 0.7


def hex_rgb(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)])


def load(path):
    return np.asarray(Image.open(path).convert('RGBA'), dtype=float) / 255


def save(arr, path):
    arr = np.clip(arr * 255 + 0.5, 0, 255).astype(np.uint8)
    mode = {3: 'RGB', 4: 'RGBA'}[arr.shape[2]]
    Image.fromarray(arr, mode).save(path, optimize=True)
    print(path, arr.shape[1], 'x', arr.shape[0], os.path.getsize(path))


def card_grid():
    """Card units at the centre of each pixel of a card-aligned image."""
    xs = (np.arange(W) + 0.5) / PX
    ys = (np.arange(H) + 0.5) / PX
    return np.meshgrid(xs, ys)


def sample(img, u, v, wrap):
    """Bilinear read of img (h, w, c) at uv; wrap repeats, else edges clamp."""
    h, w = img.shape[:2]
    x, y = u * w - 0.5, v * h - 0.5
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]

    def at(xi, yi):
        if wrap:
            return img[yi % h, xi % w]
        return img[np.clip(yi, 0, h - 1), np.clip(xi, 0, w - 1)]

    top = at(x0, y0) * (1 - fx) + at(x0 + 1, y0) * fx
    bottom = at(x0, y0 + 1) * (1 - fx) + at(x0 + 1, y0 + 1) * fx
    return top * (1 - fy) + bottom * fy


def paper_mask():
    """1 on the layout's paper, 0 on the trim, antialiased over one pixel."""
    x, y = card_grid()
    px, py, pw, ph = PAPER
    d = np.maximum(np.abs(x - (px + pw / 2)) - pw / 2, np.abs(y - (py + ph / 2)) - ph / 2)
    return np.clip(0.5 - d * PX, 0, 1)


def solid(colour):
    return np.broadcast_to(np.append(hex_rgb(colour), 1.0), (H, W, 4)).copy()


def to_opengl(n):
    """Card-space normals (y down) as an OpenGL-style normal map (green up)."""
    n = n / np.linalg.norm(n, axis=-1, keepdims=True)
    return np.dstack([n[..., 0], -n[..., 1], n[..., 2]]) * 0.5 + 0.5


def scaled_normals(rgb, strength):
    """A v2 normal map texel (card space, y down) with its tilt scaled."""
    n = rgb[..., :3] * 2 - 1
    return np.dstack([n[..., 0] * strength, n[..., 1] * strength, np.maximum(n[..., 2], 0.1)])


def render_card(path, trim=SVG_TRIM, outer=SVG_OUTER_LINE, lines=True):
    """The app's card SVG with its trim and outer line recoloured, rendered at 4 pixels per unit."""
    svg = open(CARD_SVG).read().replace(SVG_TRIM, trim).replace(SVG_OUTER_LINE, outer)
    if not lines:
        svg = re.sub(r'<rect[^>]*fill="none"[^>]*/>\s*', '', svg)
    with tempfile.NamedTemporaryFile('w', suffix='.svg', delete=False) as f:
        f.write(svg)
    try:
        subprocess.run(['rsvg-convert', '-w', str(W), '-h', str(H), '-o', path, f.name], check=True)
    finally:
        os.unlink(f.name)
    print(path, W, 'x', H, os.path.getsize(path))


def oni(src, out):
    x, y = card_grid()
    art = np.asarray(Image.open(os.path.join(src, 'art.png')).convert('RGB').resize((W, H), Image.LANCZOS), dtype=float) / 255
    foil = np.asarray(Image.open(os.path.join(src, 'foil_mask.png')).convert('RGB').resize((W, H), Image.LANCZOS), dtype=float)[..., 0] / 255
    flakes = load(os.path.join(src, 'flakes.png'))
    fl = sample(flakes, x / ONI_FLAKE_TILE, y / ONI_FLAKE_TILE, wrap=True)
    present = ((fl[..., 0] > 0.5) & (np.mod(fl[..., 2] * 13.7, 1) >= 1 - ONI_FLAKE_DENSITY)).astype(float)
    angle = fl[..., 1] * 2 * np.pi
    tilt = 0.1 + 0.5 * np.mod(fl[..., 2] * 37.3, 1)
    facet = np.dstack([np.cos(angle) * tilt, np.sin(angle) * tilt, np.ones_like(tilt)])
    lacquer = scaled_normals(sample(load(os.path.join(src, 'lacquer_normal.png')), x / ONI_LACQUER_TILE, y / ONI_LACQUER_TILE, wrap=True), ONI_LACQUER_STRENGTH)

    colour = art * (1 - foil[..., None]) + np.array(ONI_GOLD) * foil[..., None]
    colour = colour * (1 - (present * ONI_FLAKE_MIX)[..., None]) + np.array(ONI_FLAKE) * (present * ONI_FLAKE_MIX)[..., None]
    save(np.dstack([colour, np.ones_like(foil)]), os.path.join(out, 'colour.png'))
    shiny = np.maximum(foil, present)
    metal = np.maximum(foil, present * ONI_FLAKE_METAL)
    gloss = ONI_GLOSS_LACQUER + (ONI_GLOSS_GOLD - ONI_GLOSS_LACQUER) * shiny
    save(np.dstack([metal, gloss, np.zeros_like(metal)]), os.path.join(out, 'material.png'))
    save(to_opengl(np.where(present[..., None] > 0, facet, lacquer)), os.path.join(out, 'normal.png'))
    save(solid(ONI_UNDER), os.path.join(out, 'under.png'))


def _mix_masks(masks, values):
    """v2's paint mix: the ground, then each mask's value over it in R, G, B order."""
    out = np.broadcast_to(values[0], masks.shape[:2] + np.shape(values[0])).astype(float)
    for i in range(3):
        m = masks[..., i] if np.ndim(values[0]) == 0 else masks[..., i:i + 1]
        out = out * (1 - m) + values[i + 1] * m
    return out


def suminagashi(src, out):
    masks = load(os.path.join(src, 'pattern.png'))[..., :3]
    pattern = _mix_masks(masks, [hex_rgb(c) for c in SUMI_PAPER])
    save(np.dstack([pattern, np.ones(masks.shape[:2])]), os.path.join(out, 'pattern.png'))
    metal = _mix_masks(masks, SUMI_METAL)
    gloss = SUMI_GLOSS_PAPER + (SUMI_GLOSS_GOLD - SUMI_GLOSS_PAPER) * masks[..., 2]
    save(np.dstack([metal, gloss, np.zeros_like(metal)]), os.path.join(out, 'pattern_material.png'))

    washi = load(os.path.join(src, 'washi_normal.png'))
    repeats = round(CARD_W / SUMI_SHEET_SCALE / SUMI_WASHI_TILE)
    su, sv = np.meshgrid((np.arange(SHEET) + 0.5) / SHEET, (np.arange(SHEET) + 0.5) / SHEET)
    save(to_opengl(scaled_normals(sample(washi, su * repeats, sv * repeats, wrap=True), SUMI_WASHI_STRENGTH)), os.path.join(out, 'pattern_normal.png'))
    x, y = card_grid()
    save(to_opengl(scaled_normals(sample(washi, x / SUMI_WASHI_TILE, y / SUMI_WASHI_TILE, wrap=True), SUMI_WASHI_STRENGTH)), os.path.join(out, 'normal.png'))

    wash = np.broadcast_to(hex_rgb(SUMI_TRIM_WASH), (H, W, 3))
    save(np.dstack([wash, (1 - paper_mask()) * SUMI_TRIM_ALPHA]), os.path.join(out, 'colour.png'))


def _ramp(stops, x):
    """v2's colour ramp: the first stop, then a smooth step to each next stop."""
    x = np.clip(x, 0, 1)
    c = np.broadcast_to(hex_rgb(stops[0]['colour']), x.shape + (3,)).astype(float)
    for a, b in zip(stops, stops[1:]):
        lo, hi = a['at'], b['at']
        t = np.clip((x - lo) / (hi - lo), 0, 1) if hi > lo else (x >= hi).astype(float)
        t = (t * t * (3 - 2 * t))[..., None]
        c = c * (1 - t) + hex_rgb(b['colour']) * t
    return c


def tatsuta(src, out, stops):
    leaves = load(os.path.join(src, 'leaves.png'))
    k = TATSUTA_OLD_SCALE / TATSUTA_SCALE
    u, v = np.meshgrid((np.arange(SHEET) + 0.5) / SHEET, (np.arange(SHEET) + 0.5) / SHEET)
    fu, fv = 0.5 + (u - 0.5) * k, 0.5 + (v - 0.5) * k
    s = sample(leaves, fu * TATSUTA_SHEET_SCALE, fv * TATSUTA_SHEET_SCALE, wrap=True)
    base = _ramp(stops, fu)
    motif = _ramp(stops, fu + TATSUTA_MOTIF_SHIFT + s[..., 1] * TATSUTA_MOTIF_SHADE) * TATSUTA_MOTIF_BRIGHT
    col = base * (1 - s[..., 0:1]) + motif * s[..., 0:1]
    lit = col * (1 - TATSUTA_LIGHT_LINES) + np.array(TATSUTA_LINE_WHITE) * TATSUTA_LIGHT_LINES
    col = col * (1 - s[..., 2:3]) + lit * s[..., 2:3]
    save(np.dstack([col, np.ones(u.shape)]), os.path.join(out, 'pattern.png'))
    save(np.dstack([np.ones(u.shape), np.full(u.shape, TATSUTA_METAL_GLOSS), np.zeros(u.shape)]), os.path.join(out, 'pattern_material.png'))
    mask = paper_mask()
    save(np.dstack([np.broadcast_to(TATSUTA_PAPER, (H, W, 3)), mask * TATSUTA_PAPER_ALPHA]), os.path.join(out, 'colour.png'))
