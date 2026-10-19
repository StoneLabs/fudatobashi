"""Writes skins/_shared/wear.png, the ready-made wear.png of a skin: edges and corners wear first.
Run from editor/: python3 tool/make_edge_wear.py. Needs PIL and numpy. Copy it into a skin folder.

Grey, 2 pixels per card unit. 1 at the card corners, EDGE_STRENGTH along the edges, falling linearly
to 0 at EDGE_BAND / CORNER_BAND units in.
"""
import os

import numpy as np
from PIL import Image

CARD_W, CARD_H = 374, 525
PIXELS_PER_UNIT = 2
EDGE_BAND, CORNER_BAND, EDGE_STRENGTH = 9.0, 16.0, 0.8
OUT = os.path.join(os.path.dirname(__file__), '..', 'skins', '_shared', 'wear.png')

xs = (np.arange(CARD_W * PIXELS_PER_UNIT) + 0.5) / PIXELS_PER_UNIT
ys = (np.arange(CARD_H * PIXELS_PER_UNIT) + 0.5) / PIXELS_PER_UNIT
x, y = np.meshgrid(xs, ys)
dx, dy = np.minimum(x, CARD_W - x), np.minimum(y, CARD_H - y)
edge = np.clip(1 - np.minimum(dx, dy) / EDGE_BAND, 0, 1)
corner = np.clip(1 - np.hypot(dx, dy) / CORNER_BAND, 0, 1)
grey = np.maximum(edge * EDGE_STRENGTH, corner)
Image.fromarray(np.round(grey * 255).astype(np.uint8), 'L').save(OUT, optimize=True)
print(OUT)
