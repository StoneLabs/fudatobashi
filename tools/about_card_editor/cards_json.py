#!/usr/bin/env python3
"""Converts the card explanations between the editor's JSON and the app's md files.

    python3 tools/about_card_editor/cards_json.py export en [out.json]
    python3 tools/about_card_editor/cards_json.py import file.json

JSON: {"lang": "en", "cards": {"001": "...md...", ...}}
Files: assets/l10n/{lang}_card_explanations/NNN.md
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
LANGS = ('en', 'ja')
CARDS = [f'{n:03d}' for n in range(1, 101)]


def folder(lang):
    return REPO / 'assets/l10n' / f'{lang}_card_explanations'


def export_cards(lang, out):
    cards = {c: (folder(lang) / f'{c}.md').read_bytes().decode('utf-8') for c in CARDS}
    text = json.dumps({'lang': lang, 'cards': cards}, ensure_ascii=False, indent=2) + '\n'
    if out:
        Path(out).write_text(text, encoding='utf-8')
        print(f'wrote {len(cards)} cards to {out}')
    else:
        sys.stdout.write(text)


def import_cards(path):
    data = json.loads(Path(path).read_text(encoding='utf-8'))
    lang = data.get('lang')
    if lang not in LANGS:
        sys.exit(f'lang must be one of {LANGS}, got {lang!r}')
    cards = data.get('cards')
    if not isinstance(cards, dict):
        sys.exit('"cards" must be an object')
    for card, text in cards.items():
        if not re.fullmatch(r'\d{3}', card) or card not in CARDS or not isinstance(text, str):
            sys.exit(f'bad card entry {card!r}: ids are 001 to 100 and texts are strings')
    for card, text in sorted(cards.items()):
        (folder(lang) / f'{card}.md').write_bytes(text.encode('utf-8'))
        print(f'wrote {folder(lang).relative_to(REPO)}/{card}.md')


def main(argv):
    if len(argv) in (3, 4) and argv[1] == 'export' and argv[2] in LANGS:
        export_cards(argv[2], argv[3] if len(argv) == 4 else None)
    elif len(argv) == 3 and argv[1] == 'import':
        import_cards(argv[2])
    else:
        sys.exit(__doc__)


main(sys.argv)
