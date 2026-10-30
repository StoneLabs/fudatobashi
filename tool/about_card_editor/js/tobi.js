/* Tobi's lines, as the app reads them (MarkdownBlocks.tobiLine): a quote that
   starts with {.tobi} or {.tobi pose=waving}. The braces parse as an 'orphan'
   node at the start of the quote's first paragraph. */
Editor.tobi = (() => {
  const { TOBI_POSES } = Editor.config;
  const { textOf } = Editor.CardMarkdown;
  const MARK = /^\{\.tobi((?:\s+[\w-]+=[\w-]*)*)\s*\}$/;
  const ATTRIBUTE = /([\w-]+)=([\w-]*)/g;

  /** For a quote node: {mark, pose, known, words} with the pose as written (null for none),
      whether the app has it, and the words' nodes; else null. */
  function line(node) {
    if (node.tag !== 'blockquote') return null;
    const [first, ...more] = node.c || [];
    const mark = first?.tag === 'p' && first.c?.[0]?.tag === 'orphan' ? MARK.exec(textOf(first.c[0])) : null;
    if (!mark) return null;
    const pose = [...mark[1].matchAll(ATTRIBUTE)].find((a) => a[1] === 'pose')?.[2] ?? null;
    const words = [...first.c.slice(1), ...more.flatMap((p) => [{ t: ' ' }, ...(p.c || [])])];
    return { mark: first.c[0], pose, known: pose === null || TOBI_POSES.includes(pose), words };
  }

  return { line };
})();
