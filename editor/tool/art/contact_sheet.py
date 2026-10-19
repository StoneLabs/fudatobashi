#!/usr/bin/env python3
"""Contact sheet of skins: our render beside the design mock's card, with names and a tier swatch.

    contact_sheet.py --renders DIR --refs DIR --map map.json --out sheet.png

The map is an ordered list of {key, title, ja, tier, ref}. The render is DIR/<key>.png; ref is a
file name stem in the refs directory, or null. Also writes <out>_960.png, 960 px wide.
"""
import argparse
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

CARD_W, CARD_H = 374, 525
PER_ROW = 4
GAP_PAIR = 10
GAP_CELL = 44
MARGIN = 40
LABEL_H = 118
BG = (246, 244, 240)
INK = (34, 32, 30)
MUTED = (120, 116, 110)
TIER = {
    'none': ('#9A9A9A', 'No tier'),
    'blue': ('#4B69FF', 'Blue'),
    'purple': ('#8847FF', 'Purple'),
    'pink': ('#D32CE6', 'Pink'),
    'red': ('#EB4B4B', 'Red'),
    'gold': ('#E4AE39', 'Gold'),
}
PLACEHOLDER = (226, 223, 218)


def find_font(bold):
    pattern = 'Noto Sans CJK JP:' + ('bold' if bold else 'regular') + ':lang=ja'
    out = subprocess.run(['fc-match', '-f', '%{file}|%{index}', pattern], capture_output=True, text=True).stdout
    path, _, index = out.partition('|')
    return path, int(index or 0)


def font(size, bold=False):
    path, index = find_font(bold)
    return ImageFont.truetype(path, size, index=index)


def load_card(path):
    if path is None or not Path(path).exists():
        return None
    return Image.open(path).convert('RGB').resize((CARD_W, CARD_H), Image.LANCZOS)


def tier_of(entry):
    t = entry.get('tier')
    return TIER[t if t in TIER else 'none']


def draw_cell(canvas, draw, entry, x, y, renders, refs, fonts):
    render = load_card(renders / f"{entry['key']}.png")
    ref = load_card(refs / f"{entry['ref']}.png") if entry.get('ref') else None
    for i, (img, caption) in enumerate(((render, 'Editor'), (ref, 'Mock'))):
        cx = x + i * (CARD_W + GAP_PAIR)
        if img is None:
            draw.rectangle([cx, y, cx + CARD_W - 1, y + CARD_H - 1], fill=PLACEHOLDER)
            draw.text((cx + CARD_W / 2, y + CARD_H / 2), 'none', font=fonts['small'], fill=MUTED, anchor='mm')
        else:
            canvas.paste(img, (cx, y))
        draw.text((cx + 2, y + CARD_H + 6), caption, font=fonts['small'], fill=MUTED)
    ty = y + CARD_H + 30
    draw.text((x, ty), entry['title'], font=fonts['title'], fill=INK)
    draw.text((x, ty + 36), entry.get('ja', ''), font=fonts['ja'], fill=INK)
    colour, name = tier_of(entry)
    sw = 20
    sx = x + 2 * CARD_W + GAP_PAIR - 110
    draw.rounded_rectangle([sx, ty + 4, sx + sw, ty + 4 + sw], radius=5, fill=colour)
    draw.text((sx + sw + 8, ty + 4 + sw / 2), name, font=fonts['small'], fill=INK, anchor='lm')


def build(entries, renders, refs):
    fonts = {'title': font(26, True), 'ja': font(22), 'small': font(17)}
    cell_w = 2 * CARD_W + GAP_PAIR
    cell_h = CARD_H + LABEL_H
    rows = (len(entries) + PER_ROW - 1) // PER_ROW
    width = 2 * MARGIN + PER_ROW * cell_w + (PER_ROW - 1) * GAP_CELL
    height = 2 * MARGIN + rows * cell_h + (rows - 1) * GAP_CELL
    canvas = Image.new('RGB', (width, height), BG)
    draw = ImageDraw.Draw(canvas)
    for n, entry in enumerate(entries):
        r, c = divmod(n, PER_ROW)
        draw_cell(canvas, draw, entry, MARGIN + c * (cell_w + GAP_CELL), MARGIN + r * (cell_h + GAP_CELL),
                  renders, refs, fonts)
    return canvas


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--renders', required=True, type=Path)
    ap.add_argument('--refs', required=True, type=Path)
    ap.add_argument('--map', required=True, type=Path)
    ap.add_argument('--out', required=True, type=Path)
    a = ap.parse_args()
    entries = json.loads(a.map.read_text())
    sheet = build(entries, a.renders, a.refs)
    sheet.save(a.out, optimize=True)
    small = sheet.resize((960, round(sheet.height * 960 / sheet.width)), Image.LANCZOS)
    small.save(a.out.with_name(a.out.stem + '_960.png'), optimize=True)
    print(a.out, sheet.size)


if __name__ == '__main__':
    main()
