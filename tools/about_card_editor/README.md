# About this card editor

One page for writing the card explanations, the text under "About the poem" on
each card's About this card page. The phone on the left previews the page as
the app lays it out, and the editor on the right edits the Markdown. Dashed
boxes in the phone mark the parts of the real page that the preview leaves out.

## The file

`index.html` is the whole editor: styles, scripts, the Markdown parser (a port
of what the app's package:markdown reads), the romaji for `{kana}` marks and
the Latin letters of the app's Dela Gothic One font (licence:
`assets/fonts/OFL-delagothicone.txt`). There is no build step. Edit it
directly. Only the kana and kanji fonts come from Google Fonts, so it needs
the internet for those.

## For writers

1. Open `index.html` in Firefox.
2. Once: open "Card data", then paste `data.csv` from
   https://github.com/StoneLabs/hyakuninissyu-csv, or press "Load from GitHub".
   This only adds kimariji, poem and colour to the preview.
3. Pick the language you write in, under "Settings". The editor works on one
   language at a time, and drafts are kept for each language.
4. Write. Text is saved in the browser as you type. A card with no text starts
   from a "Coming soon" template.
5. Press "Download all (.zip)" and send the zip, plus any pictures, to the
   developer. The zip, "Export JSON" and "Copy all" hold the current language
   only. "Export JSON" and "Import JSON" also move your drafts to another
   computer, or load the current texts the developer sent you. Import refuses a
   file for another language.

## For the developer

Unzip into `assets/l10n/`: the folders `en_card_explanations/` and
`ja_card_explanations/` hold `NNN.md`. Put the pictures where their paths say.

Send a writer the current texts, and take their JSON back, with
`cards_json.py` (Python 3, standard library only, run from anywhere):

    python3 tools/about_card_editor/cards_json.py export en en.json
    python3 tools/about_card_editor/cards_json.py import en.json

`export` reads all 100 files of one language into
`{"lang": "en", "cards": {"001": "…", …}}`. `import` writes each card in such a
file to `assets/l10n/{lang}_card_explanations/NNN.md` and leaves the other
cards alone.
