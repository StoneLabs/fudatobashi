"""Image sets of the ten new standard skins: six Wide Series, Cherry, Snow on Fuji, Dawn Moon and Lacquer.

Reads the source art made by the scripts in tool/art (masks and card-aligned layers) and writes each
skin's files (colour, pattern, material, normal, under) to <out>/<key>/. Needs PIL, numpy and rsvg-convert.

    python3 tool/make_new_skin_sets.py <textures> <out> [--only key,key]
"""
import argparse
import os
import subprocess
import tempfile

import numpy as np
from PIL import Image

from make_v3_textures import H, W, hex_rgb, load, paper_mask, save, solid, to_opengl

# Vanilla's geometry in card units: the paper rectangle, the inner line's inset and the two line widths.
PAPER = (17.34, 19.65, 339.36, 485.79)
WIDE_INSET = 10.0
WIDE_CONTRAST = 2.0
INNER_WIDTH, INNER_INSET = 0.88, 0.88
OUTER_WIDTH = 1.56
PAPER_COLOUR, INNER_COLOUR = '#EAEAEA', '#F2EFF4'

# Wide Series: trim colour, outer line colour and the pattern's tones (mask channel, colour, strength).
WIDE = {
    'wide_washi': ('washi', '#A3845F', '#967957', [('R', '#E2D2B2', .5), ('G', '#F2E6CC', .25), ('B', '#8A6E4E', .15)]),
    'wide_seigaiha': ('seigaiha', '#2D4A77', '#29446D', [('R', '#40618F', 1)]),
    'wide_asanoha': ('asanoha', '#6A9354', '#66904F', [('R', '#7DA668', .75)]),
    'wide_shippo': ('shippo', '#694884', '#614279', [('R', '#7D5D98', .8), ('G', '#7D5D98', .25)]),
    'wide_yagasuri': ('yagasuri', '#7C3C3B', '#723736', [('G', '#6C3030', 1), ('R', '#6C3030', .6)]),
    'wide_kikko': ('kikko', '#6B7454', '#626B4D', [('R', '#7E8866', .8), ('G', '#7E8866', .8)]),
}

# Cherry: the trim and its petals (R white, G pink, B shading) and the card's lines.
SAKURA_TRIM, SAKURA_OUTER = '#E07E9E', '#D27090'
SAKURA_PETALS = [('B', '#C25C80', .55), ('G', '#F7C6D6', 1), ('R', '#FFF7FA', 1)]
SAKURA_NORMAL_STRENGTH = 1.2

# Fuji, Dawn Moon and Lacquer: lines, paper and what the foil layer is painted with.
ART_OUTER_WIDTH_URUSHI = 2.4
GOLD = '#D8B25A'
GLOSS_GOLD, GLOSS_LACQUER, GLOSS_PAPER = .75, .6, .1
ART_NORMAL_STRENGTH = 0.9
PX_HEIGHT = 12.0
ART = {
    'fuji': dict(outer='#0D173A', outer_width=OUTER_WIDTH, paper=PAPER_COLOUR, inner=INNER_COLOUR, trim_gloss=GLOSS_PAPER),
    'ariake': dict(outer='#0E1028', outer_width=OUTER_WIDTH, paper=PAPER_COLOUR, inner=INNER_COLOUR, trim_gloss=GLOSS_PAPER, foil_is_gold=False, metal=.15, gloss_metal=.35, foil_on_trim_only=True),
    'urushi': dict(outer='#D13A22', outer_width=ART_OUTER_WIDTH_URUSHI, paper='#EDEAE3', inner=None, trim_gloss=GLOSS_LACQUER),
}
URUSHI_UNDER, URUSHI_UNDER_PAPER, URUSHI_UNDER_GOLD = '#B8322A', '#F2EEE5', '#8E6B26'


def _render_svg(body):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 374 525">{body}</svg>'
    with tempfile.NamedTemporaryFile('w', suffix='.svg', delete=False) as f:
        f.write(svg)
    out = f.name[:-4] + '.png'
    try:
        subprocess.run(['rsvg-convert', '-w', str(W), '-h', str(H), '-o', out, f.name], check=True)
        return load(out)
    finally:
        os.unlink(f.name)
        if os.path.exists(out):
            os.unlink(out)


def lines_layer(inset, outer, outer_width, paper, inner):
    """Outer line, paper and inner line as Vanilla draws them, on a transparent trim. inset moves the paper edge inwards."""
    x, y, w, h = PAPER
    x, y, w, h = x + inset, y + inset, w - 2 * inset, h - 2 * inset
    half = outer_width / 2
    body = (f'<rect x="{x - half:.3f}" y="{y - half:.3f}" width="{w + outer_width:.3f}" height="{h + outer_width:.3f}" '
            f'fill="none" stroke="{outer}" stroke-width="{outer_width}"/>'
            f'<rect x="{x:.3f}" y="{y:.3f}" width="{w:.3f}" height="{h:.3f}" fill="{paper}"/>')
    if inner:
        i = INNER_INSET
        body += (f'<rect x="{x + i:.3f}" y="{y + i:.3f}" width="{w - 2 * i:.3f}" height="{h - 2 * i:.3f}" '
                 f'fill="none" stroke="{inner}" stroke-width="{INNER_WIDTH}"/>')
    return _render_svg(body)


def over(back, front):
    """Straight-alpha RGBA front over back."""
    af, ab = front[..., 3:4], back[..., 3:4]
    a = af + ab * (1 - af)
    rgb = (front[..., :3] * af + back[..., :3] * ab * (1 - af)) / np.maximum(a, 1e-6)
    return np.dstack([rgb, a])


def mix_masks(sheet, base, tones, contrast=1.0):
    """The base colour with each (channel, colour, strength) blended over it by that mask channel, in order.
    contrast pushes each tone colour further from the base."""
    out = np.broadcast_to(hex_rgb(base), sheet.shape[:2] + (3,)).astype(float).copy()
    for channel, colour, strength in tones:
        m = sheet[..., 'RGB'.index(channel)][..., None] * strength
        tone = np.clip(hex_rgb(base) + contrast * (hex_rgb(colour) - hex_rgb(base)), 0, 1)
        out = out * (1 - m) + tone * m
    return out


def opaque(rgb):
    return np.dstack([rgb, np.ones(rgb.shape[:2])])


def blur(a, sigma):
    """Gaussian blur of a 2D array, in pixels, with edge padding."""
    pad = int(sigma * 4) + 2
    p = np.pad(a, pad, mode='edge')
    fy, fx = np.fft.fftfreq(p.shape[0])[:, None], np.fft.rfftfreq(p.shape[1])[None, :]
    kernel = np.exp(-2 * np.pi ** 2 * sigma ** 2 * (fx ** 2 + fy ** 2))
    return np.fft.irfft2(np.fft.rfft2(p) * kernel, s=p.shape)[pad:-pad, pad:-pad]


def normals_from_height(height, strength):
    """OpenGL-style normal map from a 0 to 1 height layer; flat where the height is flat."""
    h = blur(height, 1.0) * PX_HEIGHT
    gy, gx = np.gradient(h)
    n = np.dstack([-gx * strength, -gy * strength, np.ones_like(h)])
    return to_opengl(n)



def wide(key, textures, out):
    motif, trim, outer, tones = WIDE[key]
    save(opaque(mix_masks(load(os.path.join(textures, motif, 'sheet.png')), trim, tones, WIDE_CONTRAST)), os.path.join(out, 'pattern.png'))
    save(lines_layer(WIDE_INSET, outer, OUTER_WIDTH, PAPER_COLOUR, INNER_COLOUR), os.path.join(out, 'colour.png'))


def sakura(textures, out):
    src = os.path.join(textures, 'sakura')
    save(opaque(mix_masks(load(os.path.join(textures, 'petals', 'sheet.png')), SAKURA_TRIM, SAKURA_PETALS)), os.path.join(out, 'pattern.png'))
    colour = over(lines_layer(0, SAKURA_OUTER, OUTER_WIDTH, PAPER_COLOUR, INNER_COLOUR), load(os.path.join(src, 'front.png')))
    save(colour, os.path.join(out, 'colour.png'))
    height = load(os.path.join(src, 'foil.png'))[..., 1]
    save(normals_from_height(height, SAKURA_NORMAL_STRENGTH), os.path.join(out, 'normal.png'))


def art_skin(key, textures, out):
    cfg = ART[key]
    src = os.path.join(textures, key)
    back, front = load(os.path.join(src, 'back.png')), load(os.path.join(src, 'front.png'))
    foil = load(os.path.join(src, 'foil.png'))
    foil_mask, height = foil[..., 0], foil[..., 1]
    if cfg.get('foil_on_trim_only'):
        foil_mask = foil_mask * (1 - paper_mask())
    metal = foil_mask * cfg.get('metal', 1.0)

    colour = over(back, lines_layer(0, cfg['outer'], cfg['outer_width'], cfg['paper'], cfg['inner']))
    colour = over(colour, front)
    if cfg.get('foil_is_gold', True):
        gold = foil_mask[..., None]
        colour = np.dstack([colour[..., :3] * (1 - gold) + hex_rgb(GOLD) * gold, colour[..., 3]])
    save(colour, os.path.join(out, 'colour.png'))

    paper = paper_mask()
    base_gloss = paper * GLOSS_PAPER + (1 - paper) * cfg['trim_gloss']
    gloss = base_gloss * (1 - foil_mask) + cfg.get('gloss_metal', GLOSS_GOLD) * foil_mask
    save(np.dstack([metal, gloss, np.zeros_like(metal)]), os.path.join(out, 'material.png'))
    save(normals_from_height(height, ART_NORMAL_STRENGTH), os.path.join(out, 'normal.png'))
    if key == 'urushi':
        p, g = paper[..., None], foil_mask[..., None]
        under = hex_rgb(URUSHI_UNDER) * (1 - p) + hex_rgb(URUSHI_UNDER_PAPER) * p
        under = under * (1 - g) + hex_rgb(URUSHI_UNDER_GOLD) * g
        save(opaque(under), os.path.join(out, 'under.png'))


def build(key, textures, out):
    os.makedirs(out, exist_ok=True)
    if key in WIDE:
        wide(key, textures, out)
    elif key == 'sakura':
        sakura(textures, out)
    else:
        art_skin(key, textures, out)


KEYS = list(WIDE) + ['sakura', 'fuji', 'ariake', 'urushi']

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('textures')
    ap.add_argument('out')
    ap.add_argument('--only', default=','.join(KEYS))
    a = ap.parse_args()
    for k in a.only.split(','):
        build(k, a.textures, os.path.join(a.out, k))
