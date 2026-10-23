/* What the dotted class names in braces mean: the palette colours and the picture sides. */
Editor.classes = (() => {
  const { PALETTE, FLOAT, BOX, ALIGN_CLASSES } = Editor.config;
  const prefix = PALETTE.backgroundPrefix;

  const textColours = new Map(PALETTE.text.map((c) => [c.name, c.hex]));
  const backgrounds = new Map(PALETTE.background.map((c) => [prefix + c.name, c.hex]));
  const COLOUR_CLASSES = [...textColours.keys(), ...backgrounds.keys()];

  /* What a ::: box may carry: colours and alignment. */
  const BOX_CLASSES = [...COLOUR_CLASSES, ...ALIGN_CLASSES];

  const kindOf = (name) => (textColours.has(name) ? 'text' : backgrounds.has(name) ? 'background' : ALIGN_CLASSES.includes(name) ? 'align' : 'other');
  const isAlignOnly = (classes) => classes.every((c) => ALIGN_CLASSES.includes(c));
  const unknownIn = (classes, allowed) => [...new Set(classes.filter((c) => !allowed.includes(c)))];
  /* When a kind is given twice, the last one wins. */
  const lastOf = (classes, map) => classes.filter((c) => map.has(c)).map((c) => map.get(c)).pop();
  const colourOf = (classes) => ({ text: lastOf(classes, textColours), background: lastOf(classes, backgrounds) });
  const repeats = (classes) => ['text', 'background'].some((k) => classes.filter((c) => kindOf(c) === k).length > 1);
  const floatSide = (classes) => classes?.find((c) => FLOAT.sides.includes(c)) ?? null;
  /* [html] in a coloured span; style is { text, background } from colourOf, or nothing. */
  const paint = (html, style) => {
    if (!style?.text && !style?.background) return html;
    const css = (style.text ? `color:${style.text};` : '') + (style.background ? `background-color:${style.background}` : '');
    return `<span${style.background ? ' class="tint"' : ''} style="${css}">${html}</span>`;
  };
  const listed = (names) => names.map((n) => '.' + n).join(', ');

  /* The picture numbers reach the style sheet as custom properties. */
  const root = document.documentElement.style;
  root.setProperty('--float-width', FLOAT.width);
  root.setProperty('--float-max-height', FLOAT.maxHeight + 'px');
  root.setProperty('--float-gap', FLOAT.gap + 'px');
  root.setProperty('--box-padding', BOX.padding);
  root.setProperty('--box-border', BOX.border + 'px');

  return { COLOUR_CLASSES, BOX_CLASSES, isAlignOnly, kindOf, unknownIn, colourOf, repeats, floatSide, paint, listed };
})();
