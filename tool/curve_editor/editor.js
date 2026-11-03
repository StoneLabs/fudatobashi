(function () {
  'use strict';

  // Rating class names and the seconds that start each class, from lib/domain/rating.dart
  // (Rating.bands) and lib/config/tuning/ranked.dart; the first class has no lower bound.
  const BANDS = [
    ['入門', null], ['F下級', 400], ['F上級', 245], ['E下級', 150], ['E上級', 116],
    ['D級', 90], ['C級', 60], ['B級', 52], ['A級', 40],
  ];
  const ratingOf = t => 600 * Math.log2(1000 / t);
  const BOUNDS = BANDS.map(([name, t]) => ({ name, from: t === null ? -Infinity : ratingOf(t) }));

  const HANDLE_PX = 56, HIT_PX = 8, KNOB_PX = 5, POINT_PX = 5;
  const canvas = document.getElementById('c');
  const ctx = canvas.getContext('2d');
  const msg = document.getElementById('msg');

  let curve = Curve.parse('TuningCurve([(0, 0.3), (800, 0.22), (3600, 0.008)])');
  let sel = -1;
  let view = { x0: 0, x1: 1, y0: 0, y1: 1 };
  let drag = null; // { kind: 'point' | 'knob' }
  let hover = null;
  let W = 0, H = 0;

  const PAD = { l: 64, r: 24, t: 34, b: 84 };
  const sx = () => (W - PAD.l - PAD.r) / (view.x1 - view.x0);
  const sy = () => (H - PAD.t - PAD.b) / (view.y1 - view.y0);
  const px = x => PAD.l + (x - view.x0) * sx();
  const py = y => H - PAD.b - (y - view.y0) * sy();
  const dataX = X => view.x0 + (X - PAD.l) / sx();
  const dataY = Y => view.y0 + (H - PAD.b - Y) / sy();

  function fit() {
    const pts = curve.pts;
    const xa = pts[0].x, xb = pts[pts.length - 1].x;
    const mx = (xb - xa) * 0.04 || 1;
    view.x0 = xa - mx;
    view.x1 = xb + mx;
    const at = Curve.makeEvaluator(curve);
    let lo = Infinity, hi = -Infinity;
    for (let i = 0; i <= 300; i++) {
      const v = at(xa + (xb - xa) * i / 300);
      lo = Math.min(lo, v);
      hi = Math.max(hi, v);
    }
    for (const p of pts) { lo = Math.min(lo, p.y); hi = Math.max(hi, p.y); }
    if (lo > 0) lo = 0;
    const my = (hi - lo) * 0.1 || 1;
    view.y0 = lo < 0 ? lo - my : lo;
    view.y1 = hi + my;
    if (lo === 0) view.y0 = -my * 0.3;
  }

  function niceStep(span, target) {
    const raw = span / target, p = Math.pow(10, Math.floor(Math.log10(raw))), f = raw / p;
    return (f < 1.5 ? 1 : f < 3.5 ? 2 : f < 7.5 ? 5 : 10) * p;
  }

  function fmt(v) {
    return String(parseFloat(v.toPrecision(4)));
  }

  // On-screen unit direction and half-length of a point's tangent handle.
  function handleOf(i) {
    const p = curve.pts[i];
    const s = Curve.slopesOf(curve)[i];
    const dydx = curve.log ? p.y * s : s;
    const dx = sx(), dy = -dydx * sy();
    const len = Math.hypot(dx, dy) || 1;
    const ux = dx / len, uy = dy / len;
    const cx = px(p.x), cy = py(p.y);
    return { cx, cy, a: [cx - ux * HANDLE_PX, cy - uy * HANDLE_PX], b: [cx + ux * HANDLE_PX, cy + uy * HANDLE_PX] };
  }

  const vals = document.getElementById('vals');
  const boxX = document.getElementById('ex');
  const boxY = document.getElementById('ey');
  const exact = v => String(parseFloat(v.toPrecision(10)));

  function syncBoxes() {
    vals.style.display = sel >= 0 ? 'flex' : 'none';
    if (sel < 0) return;
    const p = curve.pts[sel];
    if (document.activeElement !== boxX) boxX.value = exact(p.x);
    if (document.activeElement !== boxY) boxY.value = exact(p.y);
  }

  function applyBoxes() {
    if (sel < 0) return;
    const p = curve.pts[sel], pts = curve.pts;
    const x = parseFloat(boxX.value), y = parseFloat(boxY.value);
    if (Number.isFinite(x)) {
      const lo = sel > 0 ? pts[sel - 1].x + 1 : -Infinity;
      const hi = sel < pts.length - 1 ? pts[sel + 1].x - 1 : Infinity;
      p.x = Math.min(Math.max(Math.round(x), lo), hi);
    }
    if (Number.isFinite(y) && !(curve.log && y <= 0)) p.y = y;
    boxX.value = exact(p.x);
    boxY.value = exact(p.y);
    fit();
    draw();
  }

  for (const box of [boxX, boxY]) {
    box.addEventListener('change', applyBoxes);
    box.addEventListener('keydown', e => {
      e.stopPropagation();
      if (e.key === 'Enter') box.blur();
      if (e.key === 'Escape') { box.value = exact(curve.pts[sel][box === boxX ? 'x' : 'y']); box.blur(); }
    });
  }

  function draw() {
    syncBoxes();
    const dpr = window.devicePixelRatio || 1;
    W = window.innerWidth;
    H = window.innerHeight;
    canvas.width = W * dpr;
    canvas.height = H * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.fillStyle = '#383838';
    ctx.fillRect(0, 0, W, H);
    ctx.fillStyle = '#323232';
    ctx.fillRect(PAD.l, PAD.t, W - PAD.l - PAD.r, H - PAD.t - PAD.b);
    ctx.font = '11px sans-serif';

    const xs = niceStep(view.x1 - view.x0, 10), ys = niceStep(view.y1 - view.y0, 8);
    ctx.save();
    ctx.beginPath();
    ctx.rect(PAD.l, PAD.t, W - PAD.l - PAD.r, H - PAD.t - PAD.b);
    ctx.clip();
    ctx.lineWidth = 1;
    for (let x = Math.ceil(view.x0 / xs) * xs; x <= view.x1; x += xs) {
      ctx.strokeStyle = x === 0 ? '#5a5a5a' : '#404040';
      line(Math.round(px(x)) + 0.5, PAD.t, Math.round(px(x)) + 0.5, H - PAD.b);
    }
    for (let y = Math.ceil(view.y0 / ys) * ys; y <= view.y1; y += ys) {
      ctx.strokeStyle = Math.abs(y) < ys / 1e6 ? '#5a5a5a' : '#404040';
      line(PAD.l, Math.round(py(y)) + 0.5, W - PAD.r, Math.round(py(y)) + 0.5);
    }
    ctx.restore();

    ctx.fillStyle = '#9a9a9a';
    ctx.textAlign = 'center';
    for (let x = Math.ceil(view.x0 / xs) * xs; x <= view.x1; x += xs) ctx.fillText(fmt(x), px(x), H - PAD.b + 16);
    ctx.textAlign = 'right';
    for (let y = Math.ceil(view.y0 / ys) * ys; y <= view.y1; y += ys) ctx.fillText(fmt(y), PAD.l - 6, py(y) + 4);

    drawBounds();

    const at = Curve.makeEvaluator(curve);
    const a = curve.pts[0].x, b = curve.pts[curve.pts.length - 1].x;
    ctx.save();
    ctx.beginPath();
    ctx.rect(PAD.l, PAD.t, W - PAD.l - PAD.r, H - PAD.t - PAD.b);
    ctx.clip();
    ctx.strokeStyle = '#4fd35a';
    ctx.lineWidth = 2;
    ctx.beginPath();
    const steps = Math.max(2, Math.ceil(W - PAD.l - PAD.r));
    for (let i = 0; i <= steps; i++) {
      const x = view.x0 + (view.x1 - view.x0) * i / steps;
      const X = px(x), Y = py(at(Math.min(Math.max(x, a), b)));
      if (i === 0) ctx.moveTo(X, Y); else ctx.lineTo(X, Y);
    }
    ctx.stroke();

    if (sel >= 0) {
      const h = handleOf(sel);
      ctx.strokeStyle = curve.pts[sel].s === null ? '#9aa' : '#f0c040';
      ctx.lineWidth = 1.5;
      line(h.a[0], h.a[1], h.b[0], h.b[1]);
      ctx.fillStyle = curve.pts[sel].s === null ? '#9aa' : '#f0c040';
      for (const k of [h.a, h.b]) {
        ctx.fillRect(k[0] - KNOB_PX / 2, k[1] - KNOB_PX / 2, KNOB_PX, KNOB_PX);
      }
    }
    curve.pts.forEach((p, i) => {
      ctx.fillStyle = i === sel ? '#ffffff' : '#4fd35a';
      ctx.strokeStyle = '#1b1b1b';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.arc(px(p.x), py(p.y), POINT_PX, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    });
    ctx.restore();

    if (hover) {
      const t = 'x ' + fmt(hover.x) + '   y ' + fmt(hover.y);
      ctx.font = '12px monospace';
      const w = ctx.measureText(t).width + 12;
      ctx.fillStyle = 'rgba(20,20,20,0.8)';
      ctx.fillRect(W - PAD.r - w, H - 30, w, 20);
      ctx.fillStyle = '#ddd';
      ctx.textAlign = 'left';
      ctx.fillText(t, W - PAD.r - w + 6, H - 16);
    }
  }

  function drawBounds() {
    ctx.save();
    ctx.setLineDash([2, 4]);
    ctx.lineWidth = 1;
    ctx.strokeStyle = '#6a6a6a';
    ctx.fillStyle = '#b0b0b0';
    ctx.font = '12px sans-serif';
    ctx.textAlign = 'center';
    BOUNDS.forEach((bd, i) => {
      const next = i + 1 < BOUNDS.length ? BOUNDS[i + 1].from : Infinity;
      if (bd.from > view.x0 && bd.from < view.x1) line(Math.round(px(bd.from)) + 0.5, PAD.t, Math.round(px(bd.from)) + 0.5, H - PAD.b);
      const l = Math.max(bd.from, view.x0), r = Math.min(next, view.x1);
      if (r > l) {
        const cx = (px(l) + px(r)) / 2;
        if (px(r) - px(l) > ctx.measureText(bd.name).width + 4) ctx.fillText(bd.name, cx, PAD.t - 12);
      }
    });
    ctx.restore();
  }

  function line(x0, y0, x1, y1) {
    ctx.beginPath();
    ctx.moveTo(x0, y0);
    ctx.lineTo(x1, y1);
    ctx.stroke();
  }

  function mouse(e) {
    const r = canvas.getBoundingClientRect();
    return [e.clientX - r.left, e.clientY - r.top];
  }

  function hitKnob(X, Y) {
    if (sel < 0) return false;
    const h = handleOf(sel);
    return [h.a, h.b].some(k => Math.hypot(k[0] - X, k[1] - Y) <= HIT_PX);
  }

  function hitPoint(X, Y) {
    let best = -1, bd = HIT_PX + 2;
    curve.pts.forEach((p, i) => {
      const d = Math.hypot(px(p.x) - X, py(p.y) - Y);
      if (d <= bd) { bd = d; best = i; }
    });
    return best;
  }

  function inPlot(X, Y) {
    return X >= PAD.l && X <= W - PAD.r && Y >= PAD.t && Y <= H - PAD.b;
  }

  function setSlopeFromKnob(X, Y) {
    const p = curve.pts[sel];
    let dX = X - px(p.x), dY = Y - py(p.y);
    if (Math.abs(dX) < 2) dX = dX < 0 ? -2 : 2;
    const dydx = (-dY / sy()) / (dX / sx());
    p.s = curve.log ? dydx / p.y : dydx;
  }

  canvas.addEventListener('mousedown', e => {
    if (e.button !== 0) return;
    const [X, Y] = mouse(e);
    if (hitKnob(X, Y)) { drag = { kind: 'knob' }; return; }
    const i = hitPoint(X, Y);
    sel = i;
    if (i >= 0) drag = { kind: 'point' };
    draw();
  });

  window.addEventListener('mousemove', e => {
    const [X, Y] = mouse(e);
    hover = inPlot(X, Y) ? { x: dataX(X), y: dataY(Y) } : null;
    if (drag && drag.kind === 'point') {
      const pts = curve.pts, p = pts[sel];
      const lo = sel > 0 ? pts[sel - 1].x + 1 : -Infinity;
      const hi = sel < pts.length - 1 ? pts[sel + 1].x - 1 : Infinity;
      p.x = Math.min(Math.max(Math.round(dataX(X)), lo), hi);
      let y = dataY(Y);
      if (curve.log) y = Math.max(y, 1e-9);
      p.y = y;
    } else if (drag && drag.kind === 'knob') {
      setSlopeFromKnob(X, Y);
    }
    draw();
  });

  window.addEventListener('mouseup', () => {
    if (!drag) return;
    drag = null;
    fit();
    draw();
  });

  canvas.addEventListener('dblclick', e => {
    const [X, Y] = mouse(e);
    const i = hitPoint(X, Y);
    if (i >= 0) {
      curve.pts[i].s = null;
      sel = i;
    } else if (inPlot(X, Y)) {
      const x = Math.round(dataX(X));
      const pts = curve.pts;
      if (x <= pts[0].x || x >= pts[pts.length - 1].x || pts.some(p => p.x === x)) return;
      const y = Curve.makeEvaluator(curve)(x);
      const at = pts.findIndex(p => p.x > x);
      pts.splice(at, 0, { x, y, s: null });
      sel = at;
      fit();
    }
    draw();
  });

  canvas.addEventListener('contextmenu', e => {
    e.preventDefault();
    const [X, Y] = mouse(e);
    if (hitKnob(X, Y)) {
      curve.pts[sel].s = null;
    } else {
      const i = hitPoint(X, Y);
      if (i >= 0) removePoint(i);
    }
    draw();
  });

  function removePoint(i) {
    if (curve.pts.length <= 2) { say('A curve needs at least two points'); return; }
    curve.pts.splice(i, 1);
    sel = -1;
    fit();
  }

  window.addEventListener('keydown', e => {
    if ((e.key === 'Delete' || e.key === 'Backspace') && sel >= 0) {
      removePoint(sel);
      draw();
    }
  });

  let msgTimer = 0;
  function say(t) {
    msg.textContent = t;
    clearTimeout(msgTimer);
    msgTimer = setTimeout(() => { msg.textContent = ''; }, 4000);
  }

  function importText(text) {
    try {
      curve = Curve.parse(text);
      sel = -1;
      fit();
      say('');
      draw();
    } catch (err) {
      say('Import failed: ' + err.message);
    }
  }

  document.getElementById('imp').addEventListener('click', () => {
    if (!navigator.clipboard || !navigator.clipboard.readText) { say('Clipboard blocked: press Ctrl+V on the page'); return; }
    navigator.clipboard.readText().then(importText, () => say('Clipboard blocked: press Ctrl+V on the page'));
  });

  window.addEventListener('paste', e => {
    if (e.target.tagName === 'INPUT') return;
    const t = e.clipboardData && e.clipboardData.getData('text');
    if (t) { e.preventDefault(); importText(t); }
  });

  document.getElementById('exp').addEventListener('click', () => {
    const text = Curve.format(curve);
    const fallback = () => {
      const ta = document.getElementById('hold');
      ta.value = text;
      ta.select();
      say(document.execCommand('copy') ? 'Copied' : 'Copy failed');
      ta.blur();
    };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(() => say('Copied'), fallback);
    } else {
      fallback();
    }
  });

  window.addEventListener('resize', draw);
  const q = new URLSearchParams(location.search).get('curve');
  if (q) curve = Curve.parse(q);
  const qs = new URLSearchParams(location.search).get('sel');
  if (qs) sel = parseInt(qs, 10);
  fit();
  draw();
})();
