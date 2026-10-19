"""Sakura skin: two fixed blossoms (front) and petal-cupping relief."""
import math, random
import numpy as np
from card_lib import *

PETAL = ('M0 -.03C-.17 -.14 -.4 -.34 -.4 -.62C-.4 -.8 -.32 -.92 -.21 -.97C-.15 -.99 -.09 -.96 -.06 -.89'
         'Q-.03 -.83 0 -.8Q.03 -.83 .06 -.89C.09 -.96 .15 -.99 .21 -.97C.32 -.92 .4 -.8 .4 -.62C.4 -.34 .17 -.14 0 -.03Z')
FLOWERS = [(350, 25, 22, 14, 11), (14, 511, 16, -22, 23)]  # x, y, radius, rotation, seed

DEFS = '''
<radialGradient id="pg" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse">
 <stop offset="0" stop-color="#E4437D"/><stop offset=".14" stop-color="#EE6F9B"/>
 <stop offset=".3" stop-color="#F9BFD3"/><stop offset=".52" stop-color="#FFE8F0"/>
 <stop offset=".8" stop-color="#FFF7FA"/><stop offset="1" stop-color="#FFFFFF"/></radialGradient>
<radialGradient id="notch" cx="0" cy="-.86" r=".22" gradientUnits="userSpaceOnUse">
 <stop offset="0" stop-color="#F59FBF" stop-opacity=".75"/><stop offset="1" stop-color="#F59FBF" stop-opacity="0"/></radialGradient>
<filter id="sh" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation=".4"/></filter>
'''


def petals(rng, rot):
    out = []
    for i in range(5):
        out.append((rot + i * 72 + rng.uniform(-2.5, 2.5), rng.uniform(.96, 1.03)))
    return out


def flower(x, y, r, rot, seed, mode='art'):
    rng = random.Random(seed)
    s = r / .97
    ps = petals(rng, rot)
    inner = ''
    shadow = ''
    for a, k in ps:
        t = f'rotate({f2(a)}) scale({f2(k)})'
        shadow += f'<path d="{PETAL}" transform="{t}"/>'
        inner += (f'<g transform="{t}"><path d="{PETAL}" fill="url(#pg)" stroke="#E98FB0" stroke-opacity=".55" stroke-width=".012" stroke-linejoin="round"/>'
                  f'<path d="{PETAL}" fill="url(#notch)"/>'
                  f'<g fill="none" stroke="#EE8DB1" stroke-opacity=".5" stroke-width=".011" stroke-linecap="round">'
                  f'<path d="M0 -.16Q.0 -.5 0 -.72"/><path d="M-.03 -.2Q-.14 -.45 -.23 -.74"/><path d="M.03 -.2Q.14 -.45 .23 -.74"/></g></g>')
    st = ''
    for i in range(15):
        a = rot + i * 24 + rng.uniform(-6, 6)
        L = rng.uniform(.2, .33)
        bend = rng.uniform(-.05, .05)
        ex, ey = L * math.sin(math.radians(a)), -L * math.cos(math.radians(a))
        mx, my = ex * .5 + bend * math.cos(math.radians(a)), ey * .5 + bend * math.sin(math.radians(a))
        st += (f'<path d="M0 0Q{f2(mx)} {f2(my)} {f2(ex)} {f2(ey)}" fill="none" stroke="#DD4F86" stroke-width=".012" stroke-linecap="round"/>'
               f'<ellipse cx="{f2(ex)}" cy="{f2(ey)}" rx=".02" ry=".026" fill="#C42B66" transform="rotate({f2(a)} {f2(ex)} {f2(ey)})"/>')
    centre = ('<circle r=".07" fill="#D83A73"/><circle cx="-.014" cy="-.016" r=".03" fill="#F07BA3" opacity=".8"/>')
    g = f'<g transform="translate({f2(x)} {f2(y)}) scale({f2(s)})">'
    if mode == 'mask':
        return g + f'<g fill="#fff">{shadow}</g></g>'
    sh = (f'<g transform="translate({f2(x + .5)} {f2(y + .7)}) scale({f2(s)})" fill="#A8345F" opacity=".17" filter="url(#sh)">'
          f'<g transform="scale(1)">{shadow}</g></g>')
    return sh + g + inner + st + centre + '</g>'


def build():
    art = ''.join(flower(x, y, r, rot, sd) for x, y, r, rot, sd in FLOWERS)
    front = render(art, DEFS)
    save_front(front, os.path.join(ROOT, 'sakura', 'front.png'))
    # relief: cupped petals, a shallow groove along each vein
    m = ''.join(flower(x, y, r, rot, sd, 'mask') for x, y, r, rot, sd in FLOWERS)
    pm = mask(m)
    body = gblur(pm, 2.2)
    centre_fall = np.zeros_like(pm)
    h = body * .42
    veins = ''
    for x, y, r, rot, sd in FLOWERS:
        rng = random.Random(sd)
        s = r / .97
        for a, k in petals(rng, rot):
            veins += (f'<g transform="translate({f2(x)} {f2(y)}) scale({f2(s)}) rotate({f2(a)}) scale({f2(k)})" fill="none" stroke="#fff" '
                      f'stroke-width=".05" stroke-linecap="round"><path d="M0 -.2Q0 -.5 0 -.74"/></g>')
    vm = gblur(mask(veins), 2.4)
    h = np.clip(h - vm * .22 * (pm > .5), 0, 1)
    h = h + gblur(pm, 6) * .12
    save_foil(np.zeros_like(h), h, os.path.join(ROOT, 'sakura', 'foil.png'))
    preview(os.path.join(ROOT, 'sakura'), hexbg('#E07E9E'), front, (np.zeros_like(h), h), shade='#D27090', badge_ring='#B08E98')
    preview(os.path.join(ROOT, 'sakura'), hexbg('#E07E9E'), front, (np.zeros_like(h), h), shade='#D27090', badge_ring='#B08E98', guides=True, name='preview_guides.png')


def hexbg(c):
    a = np.ones((PXH, PXW, 4), np.float32)
    a[..., :3] = hex_rgb(c)
    return a


if __name__ == '__main__':
    build()
