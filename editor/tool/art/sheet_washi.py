"""Washi sheet: R long fibres, G low-frequency cloud mottling, B fine grain; all periodic."""
import math, os
import numpy as np
from lib import *

N = SHEET_PX
SEED = 7


def band_noise(rng, fx, fy, order=2.0):
    """Periodic noise from filtered white noise. fx, fy are the cutoff frequencies in cycles per sheet."""
    w = rng.standard_normal((N, N)).astype(np.float32)
    F = np.fft.fft2(w)
    ky = np.fft.fftfreq(N, 1 / N)[:, None]
    kx = np.fft.fftfreq(N, 1 / N)[None, :]
    H = np.exp(-((kx / fx) ** 2 + (ky / fy) ** 2) ** (order / 2) * .5)
    n = np.fft.ifft2(F * H).real
    n -= n.mean()
    return n / (n.std() + 1e-9)


def to_unit(n, spread=2.2):
    return np.clip(.5 + n / (2 * spread), 0, 1)


def fibres(rng, count):
    out = ''
    for _ in range(count):
        x, y = rng.random() * U, rng.random() * U
        ang = rng.random() * math.pi
        long_ = rng.random() < .22
        ln = (30 + rng.random() * 45) if long_ else (8 + rng.random() * 26)
        bend = (rng.random() - .5) * (.34 if long_ else .5)
        # a slightly curved fibre as a quadratic curve
        x2, y2 = x + math.cos(ang) * ln, y + math.sin(ang) * ln
        mx, my = (x + x2) / 2 - math.sin(ang) * ln * bend, (y + y2) / 2 + math.cos(ang) * ln * bend
        wdt = .22 + rng.random() * .42
        val = .35 + rng.random() * .65
        g = int(val * 255)
        out += (f'<path d="M{f(x)} {f(y)}Q{f(mx)} {f(my)} {f(x2)} {f(y2)}" fill="none" '
                f'stroke="rgb({g},{g},{g})" stroke-width="{f(wdt)}" stroke-linecap="round"/>')
    return out


U = SHEET_UNITS


def make():
    rng = np.random.default_rng(SEED)
    import random
    prng = random.Random(SEED)
    body = wrap_copies(fibres(prng, 230), U, U)
    R = render_mask(body, U, U, 4)
    # cloud mottling: anisotropic streaks (as the mock's .012 x .16 turbulence) plus a soft isotropic part
    streak = band_noise(rng, 5, 34, 2.0)
    cloud = band_noise(rng, 6, 6, 2.0)
    mid = band_noise(rng, 14, 14, 2.0)
    G = to_unit(.65 * streak + .75 * cloud + .25 * mid, 2.3)
    grain = band_noise(rng, 190, 190, 2.0)
    B = to_unit(grain, 2.6)
    d = os.path.join(OUT, 'washi')
    os.makedirs(d, exist_ok=True)
    save_rgb(os.path.join(d, 'sheet.png'), R, G, B)


if __name__ == '__main__':
    make()
