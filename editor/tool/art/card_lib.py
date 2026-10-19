"""Shared helpers for the card-sized skin art: 374x525 units at 4 px/unit."""
import os, subprocess, tempfile
import numpy as np
from PIL import Image

W, H, S = 374, 525, 4
PXW, PXH = W * S, H * S
PAPER = (17.34, 19.65, 339.36, 485.79)  # x, y, w, h
BADGE = (44.3, 480.26, 16.54)
KANA_COLS = (289.53, 188.64, 91.23)
KANA_TOP, KANA_PITCH, EM = 81.7, 89.63, 78
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_TMP = os.path.join(ROOT, 'src', '_tmp_card')
os.makedirs(_TMP, exist_ok=True)


def f2(v):
    return ('%.3f' % v).rstrip('0').rstrip('.')


def svg_doc(body, defs='', w=W, h=H, bg=None):
    bgrect = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">'
            f'<defs>{defs}</defs>{bgrect}{body}</svg>')


def render(body, defs='', bg=None, scale=S, w=W, h=H):
    """Render SVG content (card units) to a float RGBA array (straight alpha)."""
    path = os.path.join(_TMP, 'r%d.svg' % os.getpid())
    with open(path, 'w') as fh:
        fh.write(svg_doc(body, defs, w, h, bg))
    out = path[:-4] + '.png'
    subprocess.run(['rsvg-convert', '-w', str(int(w * scale)), '-h', str(int(h * scale)),
                    '-o', out, path], check=True)
    a = np.asarray(Image.open(out).convert('RGBA'), dtype=np.float32) / 255.0
    return a


def mask(body, defs=''):
    """Render shapes (use fill="#fff") on black; return a 0..1 float array."""
    return render(body, defs, bg='#000')[..., 0].copy()


def gblur(a, sigma_px):
    """Gaussian blur of a 2D float array via FFT, with edge padding."""
    if sigma_px <= 0:
        return a
    pad = int(sigma_px * 4) + 2
    p = np.pad(a, pad, mode='edge')
    h, w = p.shape
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.rfftfreq(w)[None, :]
    g = np.exp(-2 * (np.pi ** 2) * (sigma_px ** 2) * (fx ** 2 + fy ** 2))
    out = np.fft.irfft2(np.fft.rfft2(p) * g, s=p.shape)
    return out[pad:-pad, pad:-pad].astype(np.float32)


def u(v):
    """Units to pixels."""
    return v * S


def bleed(rgba, thr=0.02):
    """Fill colour into (nearly) transparent pixels so filtering shows no fringes."""
    rgb, a = rgba[..., :3], rgba[..., 3]
    good = (a >= thr).astype(np.float32)
    wgt = a * good
    ext = np.zeros_like(rgb)
    have = np.zeros(a.shape, bool)
    for s in (2, 6, 20, 60):
        bw = gblur(wgt, s)
        ok = (bw > 1e-4) & ~have
        for c in range(3):
            bc = gblur(rgb[..., c] * wgt, s)
            ext[..., c] = np.where(ok, bc / np.maximum(bw, 1e-6), ext[..., c])
        have |= ok
    out = rgb.copy()
    bad = a < thr
    out[bad] = ext[bad]
    return np.dstack([out, a])


def to8(a, dither=False, seed=1):
    a = np.asarray(a, np.float32)
    if dither:
        r = np.random.default_rng(seed)
        a = a + (r.random(a.shape, dtype=np.float32) - r.random(a.shape, dtype=np.float32)) / 255.0
    return np.clip(np.rint(a * 255.0), 0, 255).astype(np.uint8)


def save(arr, path, dither=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    mode = 'RGBA' if arr.shape[-1] == 4 else 'RGB'
    Image.fromarray(to8(arr, dither), mode).save(path, optimize=True)


def save_front(rgba, path):
    save(bleed(rgba), path)


def save_foil(r, g, path):
    arr = np.dstack([np.clip(r, 0, 1), np.clip(g, 0, 1), np.zeros_like(r)])
    save(arr, path)


def yy_xx():
    y, x = np.mgrid[0:PXH, 0:PXW].astype(np.float32)
    return (y + 0.5) / S, (x + 0.5) / S


def hex_rgb(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], np.float32) / 255.0


def vgrad(stops):
    """Vertical colour gradient over the card height; stops = [(t, '#hex'), ...]."""
    ts = np.array([s[0] for s in stops], np.float32)
    cs = np.array([hex_rgb(s[1]) for s in stops])
    y = (np.arange(PXH, dtype=np.float32) + 0.5) / PXH
    col = np.stack([np.interp(y, ts, cs[:, c]) for c in range(3)], -1)
    return np.repeat(col[:, None, :], PXW, axis=1)


def in_trim(x, y, margin=0.0):
    px, py, pw, ph = PAPER
    inside_paper = (px - margin < x < px + pw + margin) and (py - margin < y < py + ph + margin)
    return not inside_paper and 0 < x < W and 0 < y < H


def trim_points(rng, n, min_d, edge=2.0, gap=2.0, tries=40000, keep=None):
    """Spread n points over the trim with a minimum spacing (Poisson-like)."""
    pts = []
    for _ in range(tries):
        if len(pts) >= n:
            break
        x, y = rng.uniform(edge, W - edge), rng.uniform(edge, H - edge)
        if not in_trim(x, y, gap):
            continue
        if keep and not keep(x, y):
            continue
        if all((x - a) ** 2 + (y - b) ** 2 >= min_d ** 2 for a, b in pts):
            pts.append((x, y))
    return pts


def downscale2(rgba):
    h, w = rgba.shape[:2]
    a = rgba[..., 3:4]
    pm = rgba[..., :3] * a
    pm = pm.reshape(h // 2, 2, w // 2, 2, 3).mean((1, 3))
    al = a.reshape(h // 2, 2, w // 2, 2, 1).mean((1, 3))
    return np.dstack([pm / np.maximum(al, 1e-6), al])


def over(dst, src):
    a = src[..., 3:4]
    return dst * (1 - a) + src[..., :3] * a


def preview(folder, back, front, foil, shade='#00000033', hi='#F2EFF4', guides=False, name='preview.png',
            badge_ring='#8A8A8A', paper_fill='#EAEAEA'):
    """back/front: float RGBA at full size (or None); foil: (R, G) or None."""
    pw, ph = PXW // 2, PXH // 2
    img = np.zeros((ph, pw, 3), np.float32)
    if back is not None:
        img = downscale2(back)[..., :3].copy()
    px, py, wd, ht = PAPER
    lines = (f'<rect x="{px}" y="{py}" width="{wd}" height="{ht}" fill="{paper_fill}"/>'
             f'<rect x="{px - .78}" y="{py - .78}" width="{wd + 1.56}" height="{ht + 1.56}" fill="none" stroke="{shade}" stroke-width="1.56"/>'
             f'<rect x="{px + .88}" y="{py + .88}" width="{wd - 1.76}" height="{ht - 1.76}" fill="none" stroke="{hi}" stroke-width=".88"/>')
    # paper first, then lines drawn over (shade line sits outside the paper edge)
    lines = (f'<rect x="16.56" y="18.87" width="340.92" height="487.35" fill="none" stroke="{shade}" stroke-width="1.56"/>'
             f'<rect x="{px}" y="{py}" width="{wd}" height="{ht}" fill="{paper_fill}"/>'
             f'<rect x="18.22" y="20.53" width="337.6" height="484.03" fill="none" stroke="{hi}" stroke-width=".88"/>')
    bx, by, br = BADGE
    lines2 = f'<circle cx="{bx}" cy="{by}" r="{br}" fill="none" stroke="{badge_ring}" stroke-width="1.08"/>'
    if guides:
        for cx in KANA_COLS:
            for r in range(5):
                cy = KANA_TOP + r * KANA_PITCH
                lines2 += (f'<rect x="{cx - 39}" y="{cy - 39}" width="78" height="78" fill="none" '
                           f'stroke="#cc2222" stroke-width=".5" opacity=".55"/>')
    lay = render(lines, scale=2)
    img = over(img, lay)
    if front is not None:
        img = over(img, downscale2(front))
    if foil is not None:
        r, g = foil
        r2 = r.reshape(ph, 2, pw, 2).mean((1, 3))
        g2 = g.reshape(ph, 2, pw, 2).mean((1, 3))
        gy, gx = np.gradient(gblur(g2, 1.0))
        lam = np.clip(0.72 + (-gx * 0.9 - gy * 1.1) * 6.0, 0.35, 1.45)
        base = hex_rgb('#D8B25A')
        gold = np.clip(base[None, None, :] * lam[..., None] + 0.06 * (lam[..., None] > 1.1), 0, 1)
        img = img * (1 - r2[..., None]) + gold * r2[..., None]
    img = over(img, render(lines2, scale=2))
    os.makedirs(folder, exist_ok=True)
    save(img, os.path.join(folder, name))
    return img


def lens_bar(x0, x1, y, h, fill):
    r = h / 2
    return (f'<path d="M{f2(x0 + r)} {f2(y - r)}H{f2(x1 - r)}Q{f2(x1 + h * .3)} {f2(y)} {f2(x1 - r)} {f2(y + r)}'
            f'H{f2(x0 + r)}Q{f2(x0 - h * .3)} {f2(y)} {f2(x0 + r)} {f2(y - r)}Z" fill="{fill}"/>')
