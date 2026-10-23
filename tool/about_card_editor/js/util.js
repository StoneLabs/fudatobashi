/* Small helpers shared by the other files. */
Editor.util = (() => {
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const pad = (n) => String(n).padStart(3, '0');

  /* [hex] blended towards white: t = 1 is the colour itself, t = 0 is white. */
  const mix = (hex, t) => {
    const c = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
    return '#' + c.map((v) => Math.round(255 + (v - 255) * t).toString(16).padStart(2, '0')).join('');
  };

  return { $, $$, esc, pad, mix };
})();
