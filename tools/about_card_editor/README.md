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
3. Write. Text is saved in the browser as you type. A card with no text starts
   from a "Coming soon" template.
4. Press "Download all (.zip)" and send the zip, plus any pictures, to the
   developer. "Export JSON" and "Import JSON" move your drafts to another
   computer.

## For the developer

Unzip into `assets/l10n/`: the folders `en_card_explanations/` and
`ja_card_explanations/` hold `NNN.md`. Put the pictures where their paths say.
