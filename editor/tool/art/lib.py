"""Shared helpers for the texture scripts: SVG masks rendered with rsvg-convert."""
import subprocess, tempfile, os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE)
SHEET_UNITS = 256
SHEET_PX = 1024
SS = 2  # supersample factor on top of the target resolution


def f(x):
    return ('%.3f' % x).rstrip('0').rstrip('.')


def render_mask(body, w_units, h_units, px_per_unit, bg='#000', ss=SS, defs=''):
    """Render SVG shapes (white on black by default) to a float array in 0..1,
    at px_per_unit, supersampled by ss and box-averaged down."""
    scale = px_per_unit * ss
    w, h = round(w_units * scale), round(h_units * scale)
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
           f'viewBox="0 0 {f(w_units)} {f(h_units)}"><defs>{defs}</defs>'
           f'<rect width="{f(w_units)}" height="{f(h_units)}" fill="{bg}"/>{body}</svg>')
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, 'a.svg')
        o = os.path.join(d, 'a.png')
        open(p, 'w').write(svg)
        subprocess.run(['rsvg-convert', '-o', o, p], check=True)
        im = Image.open(o).convert('L')
    a = np.asarray(im, dtype=np.float32) / 255.0
    th, tw = round(h_units * px_per_unit), round(w_units * px_per_unit)
    return a.reshape(th, ss, tw, ss).mean(axis=(1, 3))


def save_rgb(path, r, g, b):
    arr = np.stack([r, g, b], axis=-1)
    Image.fromarray(np.clip(arr * 255 + .5, 0, 255).astype(np.uint8), 'RGB').save(path, optimize=True)


def wrap_copies(shapes, w, h, nx=1, ny=1):
    """Repeat an SVG snippet in the 3x3 neighbourhood so a torus crop is seamless."""
    out = ''
    for j in range(-ny, ny + 1):
        for i in range(-nx, nx + 1):
            out += f'<g transform="translate({f(i * w)} {f(j * h)})">{shapes}</g>'
    return out


def hexrgb(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255


def tile2x2(img):
    return np.tile(img, (2, 2, 1))


def preview_from(layers, base, path, size=1024):
    """layers: list of (mask array 2x2-tiled HxW, colour hex, opacity)."""
    h, w = layers[0][0].shape
    out = np.ones((h, w, 3), np.float32) * hexrgb(base)
    for m, c, o in layers:
        a = (m * o)[..., None]
        out = out * (1 - a) + hexrgb(c) * a
    im = Image.fromarray(np.clip(out * 255 + .5, 0, 255).astype(np.uint8), 'RGB')
    im.resize((size, size), Image.LANCZOS).save(path, optimize=True)


def render_rgba(body, w_units, h_units, px_per_unit, ss=SS, defs=''):
    """Render SVG to straight-alpha RGBA (uint8), supersampled in premultiplied space.
    Colour under transparent pixels is bled outward from the artwork so filtering never darkens edges."""
    scale = px_per_unit * ss
    w, h = round(w_units * scale), round(h_units * scale)
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
           f'viewBox="0 0 {f(w_units)} {f(h_units)}"><defs>{defs}</defs>{body}</svg>')
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, 'a.svg')
        o = os.path.join(d, 'a.png')
        open(p, 'w').write(svg)
        subprocess.run(['rsvg-convert', '-o', o, p], check=True)
        im = Image.open(o).convert('RGBA')
    a = np.asarray(im, dtype=np.float32) / 255.0
    th, tw = round(h_units * px_per_unit), round(w_units * px_per_unit)
    alpha = a[..., 3]
    pm = a[..., :3] * alpha[..., None]
    pm = pm.reshape(th, ss, tw, ss, 3).mean(axis=(1, 3))
    alpha = alpha.reshape(th, ss, tw, ss).mean(axis=(1, 3))
    rgb = np.where(alpha[..., None] > 1e-4, pm / np.maximum(alpha[..., None], 1e-4), 0)
    return bleed(rgb, alpha)


def bleed(rgb, alpha, iterations=6):
    known = alpha > 1e-3
    rgb = rgb.copy()
    for _ in range(iterations):
        acc = np.zeros_like(rgb)
        cnt = np.zeros(alpha.shape, np.float32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                k = np.roll(known, (dy, dx), (0, 1))
                v = np.roll(rgb, (dy, dx), (0, 1))
                acc += v * k[..., None]
                cnt += k
        fill = (~known) & (cnt > 0)
        rgb[fill] = acc[fill] / cnt[fill][..., None]
        known = known | fill
    out = np.dstack([rgb, alpha])
    return np.clip(out * 255 + .5, 0, 255).astype(np.uint8)
