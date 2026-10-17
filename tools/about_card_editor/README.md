# About this card editor

A web page for writing the card explanations, the text under "About the poem"
on each card's About this card page. The phone on the left previews the page
as the app lays it out, and the editor on the right edits the Markdown. Dashed
boxes in the phone mark the parts of the real page that the preview leaves out.

## Files

- `index.html`, `editor.css`, `editor.js`: the page.
- `markdown.js`: the Markdown parser, a port of what the app's package:markdown reads.
- `romaji.js`: the romaji for `{kana}` marks.
- `fonts/DelaGothicOne-latin.woff2`: the Latin letters of the app's
  `assets/fonts/DelaGothicOne-Regular.ttf` (licence: `assets/fonts/OFL-delagothicone.txt`).
  The Google Fonts copy has narrower Latin letters, so the preview uses the app's.
- `build.py`: makes `data.js` and the single file for writers.
- `data.js`: made by `build.py` and not in git.

## Rebuild

From the repository root:

    python3 -I tools/about_card_editor/build.py

It reads `assets/l10n/{en,ja}_card_explanations/*.md`, `assets/data/poems.json`
and the pictures the explanations use, and writes:

- `tools/about_card_editor/data.js`, so `index.html` opens from disk with a double-click;
- `dist/about_card_editor.html`, everything in one file.

Use `--root DIR` to read the assets from another checkout. Run it again after
the explanations change. The editor's copy of card 1 gets a few sample `{kana}`
marks (see `SAMPLES` in `build.py`) so the Kana / Romaji switch shows something.

To remake the font file (needs FontForge):

    fontforge -lang=py -c "import fontforge
    f = fontforge.open('assets/fonts/DelaGothicOne-Regular.ttf')
    f.selection.none()
    for a, b in [(0x20, 0x7E), (0xA0, 0x17F), (0x2010, 0x2027), (0x2030, 0x203A)]:
        f.selection.select(('more', 'ranges', 'unicode'), a, b)
    f.selection.invert(); f.clear()
    f.generate('tools/about_card_editor/fonts/DelaGothicOne-latin.woff2')"

## Hand it to a writer

1. Rebuild, then send `dist/about_card_editor.html`.
2. The writer opens it in a browser (it needs the internet for the kana and
   kanji fonts). Edits are saved in that browser as they type.
3. They send back the edited `.md` files ("Download all edited" makes one zip)
   and any new pictures.
4. Put the files in `assets/l10n/{en,ja}_card_explanations/` and the pictures
   where their paths say.
