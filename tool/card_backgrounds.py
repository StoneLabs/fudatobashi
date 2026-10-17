"""Renders the blank card faces the card renderers draw their text on:

    python3 tool/card_backgrounds.py

assets/cards/yomifuda/default.png: the reading card (読み札) of the
competition reading set in research/yomifuda (52 x 75 mm), a blue band
around white paper, 14 px per mm so it stays sharp at the largest size
the app shows it. Needs Pillow (`pip install pillow`).
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

# Measured on the photos: the band is 4.2 % of the card's width.
YOMIFUDA_SIZE = (52 * 14, 75 * 14)
YOMIFUDA_BAND = round(0.042 * YOMIFUDA_SIZE[0])
YOMIFUDA_BLUE = (0x1A, 0x58, 0xA7)
YOMIFUDA_PAPER = (0xF9, 0xF9, 0xF8)


def yomifuda():
    w, h = YOMIFUDA_SIZE
    image = Image.new('RGB', YOMIFUDA_SIZE, YOMIFUDA_BLUE)
    ImageDraw.Draw(image).rectangle(
        (YOMIFUDA_BAND, YOMIFUDA_BAND, w - YOMIFUDA_BAND - 1, h - YOMIFUDA_BAND - 1), fill=YOMIFUDA_PAPER)
    out = ROOT / 'assets/cards/yomifuda/default.png'
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, optimize=True)
    print('wrote', out.relative_to(ROOT), image.size)


if __name__ == '__main__':
    yomifuda()
