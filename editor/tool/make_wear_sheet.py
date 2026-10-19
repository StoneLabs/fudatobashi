"""Writes skins/_shared/wear_sheet.png, the wear sheet every skin shares. Run from editor/:
python3 tool/make_wear_sheet.py. Needs PIL and numpy.

R: chip order, uniform 0..1: blotches a few units across over broader drifts. The seed places the sheet
and paint goes where chip order times the skin's wear.png passes 1 - float.
G: a grunge cloud for dirt. B: scratches, thin lines, each with its own depth (brighter shows sooner).
"""
import os

import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), '..', 'skins', '_shared', 'wear_sheet.png')
SHEET = 512


def rank01(a):
    order = a.ravel().argsort().argsort()
    return (order / (order.size - 1)).reshape(a.shape)


def fnoise(n, beta, seed, cutoff=None):
    """Tileable noise in 0..1 from random phases and a 1/f^beta spectrum.
    cutoff (cycles per texel) removes finer detail, which would alias."""
    rng = np.random.default_rng(seed)
    f = np.fft.fftfreq(n)
    r = np.sqrt(f[:, None] ** 2 + f[None, :] ** 2)
    r[0, 0] = 1
    spec = r ** -beta * np.exp(2j * np.pi * rng.random((n, n)))
    spec[0, 0] = 0
    if cutoff:
        spec *= np.exp(-(r / cutoff) ** 2)
    a = np.fft.ifft2(spec).real
    return (a - a.min()) / (a.max() - a.min())


def wrapped_lines(n, seed, count):
    rng = np.random.default_rng(seed)
    img = Image.new('L', (n, n), 0)
    d = ImageDraw.Draw(img)
    for _ in range(count):
        x, y = rng.random(2) * n
        ang = (0.42 if rng.random() < 0.72 else 2.1) + (rng.random() - 0.5) * 0.7
        length = 15 + rng.random() * 90
        shade = int(80 + rng.random() * 175)
        width = 1 if rng.random() < 0.8 else 2
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                d.line([(x + ox, y + oy), (x + ox + np.cos(ang) * length, y + oy + np.sin(ang) * length)], fill=shade, width=width)
    return np.asarray(img, dtype=float)


def main():
    chips = rank01(0.5 * fnoise(SHEET, 2.2, 1) + 0.3 * fnoise(SHEET, 1.1, 2, 0.25) + 0.2 * fnoise(SHEET, 0.5, 6, 0.3))
    grunge = rank01(0.55 * fnoise(SHEET, 1.6, 3) + 0.45 * fnoise(SHEET, 2.8, 4))
    scratches = wrapped_lines(SHEET, 5, 60)
    rgb = np.dstack([chips * 255, grunge * 255, scratches])
    Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), 'RGB').save(OUT, optimize=True)
    print(OUT, os.path.getsize(OUT))


main()
