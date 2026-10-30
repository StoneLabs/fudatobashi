/* Every article is a Jinja template before it is Markdown (ArticleTemplate in
   the app), here with nunjucks and the same settings. The template knows the
   reader's kana setting as env.romaji_mode. */
Editor.template = (() => {
  const environment = new nunjucks.Environment(null, { autoescape: false, trimBlocks: true, lstripBlocks: true, throwOnUndefined: true });

  /* The text with its template filled in; a broken template leaves the text
     as it is, with the error to show. */
  function fill(text, romaji) {
    try {
      return { text: environment.renderString(text, { env: { romaji_mode: romaji } }), error: null };
    } catch (e) {
      return { text, error: String(e.message ?? e).replace(/^\(unknown path\)\s*/, '') };
    }
  }

  return { fill };
})();
