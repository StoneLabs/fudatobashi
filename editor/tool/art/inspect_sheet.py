"""Developer helper: colour a sheet like its preview and write a zoomed crop plus a crop of the wrap seam."""
import sys, os
import numpy as np
from PIL import Image
from lib import *
import previews

SCR = os.environ.get('INSPECT_DIR', '/tmp/claude-1000/-home-stone-Git-fudatobashi/33d0a34f-dd98-44b0-b273-292e4ec44420/scratchpad')

def coloured(folder):
    trim, chans = previews.SPEC[folder]
    s = previews.load(folder)
    s2 = np.tile(s, (2, 2, 1))
    out = np.ones(s2.shape, np.float32) * hexrgb(trim)
    if folder == 'petals':
        sh = s2[..., 2]
        for c, col in ((0, '#FFFFFF'), (1, '#F7C6D6')):
            a = s2[..., c:c + 1]
            out = out * (1 - a) + hexrgb(col) * (.55 + .45 * sh)[..., None] * a
        return out
    for c, col, op in chans:
        a = (s2[..., c] * op)[..., None]
        out = out * (1 - a) + hexrgb(col) * a
    return out

if __name__ == '__main__':
    k = sys.argv[1]
    zoom = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    im = coloured(k)
    n = 512 // zoom
    def crop(y, x):
        c = im[y:y + n, x:x + n]
        return Image.fromarray(np.clip(c * 255 + .5, 0, 255).astype(np.uint8)).resize((512, 512), Image.NEAREST)
    a = crop(100, 100)
    b = crop(1024 - n // 2, 1024 - n // 2)  # centre of the 2x2 tiling: both seams
    c = Image.new('RGB', (1030, 512), 'white'); c.paste(a, (0, 0)); c.paste(b, (518, 0))
    c.save(os.path.join(SCR, f'insp_{k}.png'))
