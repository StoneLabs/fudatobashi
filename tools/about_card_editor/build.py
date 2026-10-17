#!/usr/bin/env python3
"""Builds the About this card editor's data, and the single file for writers.

Reads the card explanations (assets/l10n/{en,ja}_card_explanations/NNN.md),
assets/data/poems.json and the pictures the explanations use, and writes:

  data.js                        next to index.html, so index.html opens from disk
  dist/about_card_editor.html    everything inlined into one file, to send out

    python3 -I tools/about_card_editor/build.py [--root DIR]

--root is the checkout to read the assets from; by default this one.
"""
import argparse
import base64
import json
import mimetypes
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
DATA_JS = HERE / 'data.js'
BUNDLE = REPO / 'dist/about_card_editor.html'
LANGS = ('en', 'ja')
CARDS = range(1, 101)
IMAGE = re.compile(r'!\[[^\]]*\]\(([^)\s]+)')
STYLESHEET = re.compile(r'<link rel="stylesheet" href="([\w.]+\.css)">')
SCRIPT = re.compile(r'<script src="([\w.]+\.js)"></script>')
FONT = re.compile(r'url\((fonts/[\w.-]+\.woff2)\)')

# Samples added only to the editor's copy of card 1, so the Kana / Romaji
# switch visibly does something. The app's own md files are not touched, and
# a sample whose text is no longer in the file is left out.
SAMPLES = {
    ('en', 1): [
        ('*Ut enim ad minim veniam, quis nostrud exercitation.*',
         '*Ut enim ad minim veniam, quis nostrud exercitation.* The kimariji is {あきの}, and the particle は is read {わ}.'),
        ('- **Dolor** (dolor):', '- **Dolor** ({あきの}):'),
    ],
    ('ja', 1): [
        ('*またそのなかでいっしょになったたくさんのひとたち。*',
         '*またそのなかでいっしょになったたくさんのひとたち。* この札の決まり字は{あきの}で、助詞の「は」は{わ}と読みます。'),
        ('- **モーリオ**：うつくしい森で飾られた市。', '- **モーリオ**：{うつくしい}森で飾られた市。'),
    ],
}


def read_explanations(root):
    out = {}
    for lang in LANGS:
        folder = root / f'assets/l10n/{lang}_card_explanations'
        out[lang] = {}
        for n in CARDS:
            file = folder / f'{n:03d}.md'
            if not file.is_file():
                sys.exit(f'missing {file}; pass --root')
            text = file.read_text(encoding='utf-8')
            for old, new in SAMPLES.get((lang, n), []):
                text = text.replace(old, new, 1)
            out[lang][n] = text
    return out


def read_poems(root):
    keep = ('kimariji', 'kimarijiReading', 'color', 'author', 'authorKana', 'authorRomaji',
            'kamiRuby', 'shimoRuby', 'versesRomaji')
    poems = json.loads((root / 'assets/data/poems.json').read_text(encoding='utf-8'))
    return [{'n': p['id'], **{k: p[k] for k in keep}} for p in sorted(poems, key=lambda p: p['id'])]


def read_images(root, expl):
    paths = sorted({m for texts in expl.values() for t in texts.values() for m in IMAGE.findall(t)})
    images = {}
    for path in paths:
        file = root / path
        if not file.is_file():
            print('warning: picture not found:', path, file=sys.stderr)
            continue
        mime = mimetypes.guess_type(file.name)[0] or 'application/octet-stream'
        images[path] = f'data:{mime};base64,' + base64.b64encode(file.read_bytes()).decode()
    return images


def font_data(match):
    return f"url(data:font/woff2;base64,{base64.b64encode((HERE / match[1]).read_bytes()).decode()})"


def inline(page):
    """index.html with its stylesheet and scripts pasted in."""
    def text(name):
        source = (HERE / name).read_text(encoding='utf-8')
        assert '</script' not in source and '</style' not in source, name
        return source
    page, styles = STYLESHEET.subn(lambda m: f'<style>\n{FONT.sub(font_data, text(m[1]))}</style>', page)
    page, scripts = SCRIPT.subn(lambda m: f'<script>\n{text(m[1])}</script>', page)
    assert styles == 1 and scripts >= 4, (styles, scripts)
    return page


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default=str(REPO))
    root = Path(ap.parse_args().root)
    expl = read_explanations(root)
    data = {'poems': read_poems(root), 'expl': expl, 'images': read_images(root, expl)}
    blob = json.dumps(data, ensure_ascii=False, separators=(',', ':')).replace('<', '\\u003c')
    DATA_JS.write_text(f'/* Made by build.py: do not edit. */\nconst EDITOR_DATA = {blob};\n', encoding='utf-8')
    BUNDLE.parent.mkdir(parents=True, exist_ok=True)
    BUNDLE.write_text(inline((HERE / 'index.html').read_text(encoding='utf-8')), encoding='utf-8')
    for file in (DATA_JS, BUNDLE):
        print(f'built {file.relative_to(REPO)}: {file.stat().st_size} bytes')
    print(f'from {root}, {len(data["images"])} pictures')


if __name__ == '__main__':
    main()
