"""Writes <folder>/preview.png for each placed sheet: 2x2 tiling, coloured as in the mock."""
import os
import numpy as np
from PIL import Image
from lib import *

# folder: (trim, [(channel, colour, opacity)])
SPEC = {
    'seigaiha': ('#2D4A77', [(0, '#40618F', 1)]),
    'asanoha': ('#6A9354', [(0, '#7DA668', .75)]),
    'shippo': ('#694884', [(0, '#7D5D98', .8), (1, '#7D5D98', .25)]),
    'yagasuri': ('#7C3C3B', [(1, '#6C3030', 1), (0, '#6C3030', 1)]),
    'kikko': ('#6B7454', [(0, '#7E8866', .8), (1, '#7E8866', .8)]),
    'washi': ('#A3845F', [(1, '#C9B08A', .35), (0, '#E2D2B2', .65), (2, '#E2D2B2', .12)]),
    'petals': ('#E07E9E', [(0, '#FFFFFF', .9), (1, '#F7C6D6', .95), (2, '#E07E9E', -.0)]),
}


def load(folder):
    return np.asarray(Image.open(os.path.join(OUT, folder, 'sheet.png')).convert('RGB'), np.float32) / 255


def make(folder):
    trim, chans = SPEC[folder]
    s = load(folder)
    layers = [(tile2x2(s[..., c:c + 1])[..., 0], col, op) for c, col, op in chans if op > 0]
    if folder == 'petals':
        sh = tile2x2(s[..., 2:3])[..., 0]
        layers = []
        base = np.ones(sh.shape + (3,), np.float32) * hexrgb(trim)
        for c, col in ((0, '#FFFFFF'), (1, '#F7C6D6')):
            m = tile2x2(s[..., c:c + 1])[..., 0]
            shade = (.55 + .45 * sh)[..., None]
            a = m[..., None]
            base = base * (1 - a) + hexrgb(col) * shade * a
        Image.fromarray(np.clip(base * 255 + .5, 0, 255).astype(np.uint8)).resize((1024, 1024), Image.LANCZOS).save(
            os.path.join(OUT, folder, 'preview.png'), optimize=True)
        return
    preview_from(layers, trim, os.path.join(OUT, folder, 'preview.png'))


if __name__ == '__main__':
    import sys
    for k in (sys.argv[1:] or SPEC):
        if os.path.exists(os.path.join(OUT, k, 'sheet.png')):
            make(k)
