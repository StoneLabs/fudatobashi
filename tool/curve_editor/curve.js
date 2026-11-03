// Parse, format and evaluate TuningCurve definitions (same maths as the app).
(function (root) {
  'use strict';

  function endSlope(h0, h1, d0, d1) {
    const s = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1);
    if (s * d0 <= 0) return 0;
    if (d0 * d1 <= 0 && Math.abs(s) > 3 * Math.abs(d0)) return 3 * d0;
    return s;
  }

  // Automatic monotone slopes (PCHIP, Fritsch-Carlson) from the points alone.
  function autoSlopes(xs, ys) {
    const n = xs.length;
    if (n === 1) return [0];
    const h = [], d = [];
    for (let i = 1; i < n; i++) {
      h.push(xs[i] - xs[i - 1]);
      d.push((ys[i] - ys[i - 1]) / h[i - 1]);
    }
    if (n === 2) return [d[0], d[0]];
    const m = new Array(n).fill(0);
    for (let i = 1; i < n - 1; i++) {
      if (d[i - 1] * d[i] <= 0) continue;
      const w1 = 2 * h[i] + h[i - 1], w2 = h[i] + 2 * h[i - 1];
      m[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i]);
    }
    m[0] = endSlope(h[0], h[1], d[0], d[1]);
    m[n - 1] = endSlope(h[n - 2], h[n - 3], d[n - 2], d[n - 3]);
    return m;
  }

  // curve = { log: bool, pts: [{x, y, s}] }; s is the explicit slope in working
  // space (d ln y / dx for log curves) or null for automatic.
  function workY(curve, y) { return curve.log ? Math.log(y) : y; }

  // Slope used at every point, in working space.
  function slopesOf(curve) {
    const auto = autoSlopes(curve.pts.map(p => p.x), curve.pts.map(p => workY(curve, p.y)));
    return curve.pts.map((p, i) => (p.s === null || p.s === undefined ? auto[i] : p.s));
  }

  function makeEvaluator(curve) {
    const pts = curve.pts;
    const slopes = slopesOf(curve);
    return function at(x) {
      if (x <= pts[0].x) return pts[0].y;
      for (let i = 1; i < pts.length; i++) {
        const r1 = pts[i].x;
        if (x > r1) continue;
        if (x === r1) return pts[i].y;
        const r0 = pts[i - 1].x;
        const h = r1 - r0, t = (x - r0) / h;
        const y0 = workY(curve, pts[i - 1].y), y1 = workY(curve, pts[i].y);
        const t2 = t * t, t3 = t2 * t;
        const y = (2 * t3 - 3 * t2 + 1) * y0 + (t3 - 2 * t2 + t) * h * slopes[i - 1] +
          (-2 * t3 + 3 * t2) * y1 + (t3 - t2) * h * slopes[i];
        return curve.log ? Math.exp(y) : y;
      }
      return pts[pts.length - 1].y;
    };
  }

  const NUM = '[-+]?(?:\\d+\\.?\\d*|\\.\\d+)(?:[eE][-+]?\\d+)?';
  const PAIR = new RegExp('\\(\\s*(' + NUM + ')\\s*,\\s*(' + NUM + ')\\s*\\)', 'g');

  function pairs(s) {
    return [...s.matchAll(PAIR)].map(p => [parseFloat(p[1]), parseFloat(p[2])]);
  }

  // Returns a curve, or throws Error with a short message.
  function parse(text) {
    const m = /(?:IkkiuchiCurve|TuningCurve)\s*(\.\s*log)?\s*\(/.exec(text);
    if (!m) throw new Error('No TuningCurve( found');
    const rest = text.slice(m.index + m[0].length);
    const open = rest.indexOf('[');
    if (open < 0) throw new Error('No point list found');
    let depth = 0, close = -1;
    for (let i = open; i < rest.length; i++) {
      if (rest[i] === '[') depth++;
      else if (rest[i] === ']' && --depth === 0) { close = i; break; }
    }
    if (close < 0) throw new Error('Point list is not closed');
    const pts = pairs(rest.slice(open, close + 1)).map(([x, y]) => ({ x, y, s: null }));
    if (pts.length < 2) throw new Error('Need at least two points');
    for (let i = 1; i < pts.length; i++) {
      if (!(pts[i].x > pts[i - 1].x)) throw new Error('Point x values must rise');
    }
    const log = !!m[1];
    if (log && pts.some(p => !(p.y > 0))) throw new Error('Log curve values must be above 0');
    const tail = rest.slice(close + 1);
    const sm = /slopes\s*:\s*\[/.exec(tail);
    if (sm) {
      const body = tail.slice(sm.index + sm[0].length - 1);
      const end = body.indexOf(']');
      for (const [x, s] of pairs(end < 0 ? body : body.slice(0, end + 1))) {
        const p = pts.find(q => q.x === x);
        if (!p) throw new Error('Slope x ' + x + ' is not a point');
        p.s = s;
      }
    }
    return { log, pts };
  }

  function sig(v, digits) {
    return String(parseFloat(v.toPrecision(digits)));
  }

  function format(curve) {
    const pts = curve.pts.map(p => '(' + Math.round(p.x) + ', ' + sig(p.y, 4) + ')').join(', ');
    const sl = curve.pts.filter(p => p.s !== null && p.s !== undefined)
      .map(p => '(' + Math.round(p.x) + ', ' + sig(p.s, 3) + ')');
    return 'TuningCurve' + (curve.log ? '.log' : '') + '([' + pts + ']' +
      (sl.length ? ', slopes: [' + sl.join(', ') + ']' : '') + ')';
  }

  const api = { parse, format, makeEvaluator, slopesOf, autoSlopes };
  if (typeof module !== 'undefined') module.exports = api;
  else root.Curve = api;
})(typeof window !== 'undefined' ? window : globalThis);
