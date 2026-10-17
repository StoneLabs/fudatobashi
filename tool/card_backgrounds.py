"""Renders the blank card faces the card renderers draw their text on:

    python3 tool/card_backgrounds.py

assets/cards/yomifuda/default.svg: the reading card (読み札) of the
competition reading set in research/yomifuda, in millimetres (52 x 75):
a blue band around white paper.

assets/cards/torifuda/default.svg: the taking card (取り札) in the original
app's artwork, in its 374 x 525 card units: green backing, a darker band
just outside the paper, the paper and a lighter band just inside its edge.

Both are vectors, so their thin bands stay sharp at every size.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Measured on the photos: the band is 4.4 % of the card's width.
YOMIFUDA_SIZE = (52, 75)
YOMIFUDA_BAND = 0.044 * YOMIFUDA_SIZE[0]
YOMIFUDA_BLUE = '#1856A6'
YOMIFUDA_PAPER = '#F9F9FA'

TORIFUDA_SIZE = (374, 525)
TORIFUDA_PAPER = (17.34, 19.65, 356.7, 505.44)  # left, top, right, bottom
TORIFUDA_FRAME = '#6A9354'
TORIFUDA_SHADE = '#66904F'
TORIFUDA_SHADE_WIDTH = 1.56
TORIFUDA_PAPER_COLOUR = '#EAEAEA'
TORIFUDA_HIGHLIGHT = '#F2EFF4'
TORIFUDA_HIGHLIGHT_INSET = 0.44
TORIFUDA_HIGHLIGHT_WIDTH = 0.88


def _rect(box, grow, **attrs):
    """A <rect> of `box` grown by `grow` on every side (negative shrinks)."""
    left, top, right, bottom = box
    x, y = left - grow, top - grow
    w, h = right - left + 2 * grow, bottom - top + 2 * grow
    props = ' '.join(f'{k.replace("_", "-")}="{v}"' for k, v in attrs.items())
    return f'  <rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" {props}/>'


def _write_svg(path, size, backing, shapes):
    """Writes an SVG of `size` filled with `backing`, then `shapes` on top."""
    w, h = size
    svg = '\n'.join([
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">',
        f'  <rect x="0" y="0" width="{w}" height="{h}" fill="{backing}" stroke="none"/>',
        *shapes,
        '</svg>',
        '',
    ])
    out = ROOT / path
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(svg)
    print('wrote', out.relative_to(ROOT), size)


def yomifuda():
    w, h = YOMIFUDA_SIZE
    paper = _rect((0, 0, w, h), -YOMIFUDA_BAND, fill=YOMIFUDA_PAPER, stroke='none')
    _write_svg('assets/cards/yomifuda/default.svg', YOMIFUDA_SIZE, YOMIFUDA_BLUE, [paper])


def torifuda():
    # A stroke is centred on its rectangle, so each band's rectangle runs
    # along the band's middle.
    shade = _rect(TORIFUDA_PAPER, TORIFUDA_SHADE_WIDTH / 2, fill='none', stroke=TORIFUDA_SHADE,
                  stroke_width=TORIFUDA_SHADE_WIDTH, stroke_linejoin='miter')
    inset = TORIFUDA_HIGHLIGHT_INSET + TORIFUDA_HIGHLIGHT_WIDTH / 2
    highlight = _rect(TORIFUDA_PAPER, -inset, fill='none', stroke=TORIFUDA_HIGHLIGHT,
                      stroke_width=TORIFUDA_HIGHLIGHT_WIDTH, stroke_linejoin='miter')
    paper = _rect(TORIFUDA_PAPER, 0, fill=TORIFUDA_PAPER_COLOUR, stroke='none')
    _write_svg('assets/cards/torifuda/default.svg', TORIFUDA_SIZE, TORIFUDA_FRAME, [shade, paper, highlight])


if __name__ == '__main__':
    yomifuda()
    torifuda()
