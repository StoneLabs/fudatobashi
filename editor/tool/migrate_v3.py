"""Converts a skins folder from format 2 to format 3.

Each format 2 skin gets its image files (made by make_v3_textures.py from its old textures and colours)
and a format 3 skin.json that keeps its id, key, tier, family, float range, preview poem and text colours.
The old textures are removed; names stay in the l10n files. Skins already in format 3
are left alone. With --brocade, the Brocade River sample is added from a folder holding water.png and
leaves.png.

Run from editor/: python3 tool/migrate_v3.py [skins] [--brocade DIR]
"""
import argparse
import json
import os
import shutil

import make_v3_textures as tex

HERE = os.path.dirname(os.path.abspath(__file__))
SKINS = os.path.join(HERE, '..', 'skins')
L10N = os.path.join(HERE, '..', 'assets', 'l10n')

DEFAULT_TEXT = {'ink': '#262626', 'badge': '#8A8A8A', 'numeral': '#9E9E9E'}
OLD_FILES = {
    'oni': ['art.png', 'flakes.png', 'foil_mask.png', 'lacquer_normal.png'],
    'suminagashi': ['washi_normal.png'],
    'tatsuta': ['leaves.png'],
}
OLD_SHARED = ['spectrum.png']

BROCADE = {
    'format': 3, 'id': 4003, 'key': 'nishiki', 'tier': 'red', 'family': None, 'familyOdds': None, 'drops': True,
    'float': [0.0, 0.08], 'previewPoem': 69,
    'text': {'ink': '#262626', 'badge': '#9A844C', 'numeral': '#9A844C'},
    'shader': 'brocade',
    'values': {'gold': '#C9A45A', 'waterAmount': [0.9, 0.6], 'waterSpeed': [8, 5], 'waterRelief': 0.4, 'leafSpeed': 37, 'leafOpacity': 1},
    'random': {'leafPhase': {'x': [0.0, 1.0]}},
}
BROCADE_TRIM = '#0E2C3A'
BROCADE_NAMES = {'en': 'Brocade River', 'ja': '錦の川'}


def pattern_block(key, old):
    places = old.get('placements', {})
    if key == 'suminagashi':
        return dict(places['sheetPlace'])
    if key == 'tatsuta':
        return {**places['fadePlace'], 'scale': tex.TATSUTA_SCALE}
    return None


def v3_json(old):
    values = old.get('values', {})
    family = old.get('family') or None
    out = {
        'format': 3,
        'id': old['id'],
        'key': old['key'],
        'tier': old['tier'],
        'family': family,
        'familyOdds': old.get('familyOdds') if family else None,
        'drops': old.get('drops', True),
        'float': old['float'],
        'previewPoem': old['previewPoem'],
    }
    pattern = pattern_block(old['key'], old)
    if pattern:
        out['pattern'] = pattern
    out['text'] = {k: values.get(k, d) for k, d in DEFAULT_TEXT.items()}
    return out


def textures(key, folder, old, skins):
    values = old.get('values', {})
    colour = os.path.join(folder, 'colour.png')
    if key == 'vanilla':
        tex.render_card(colour)
        shutil.copyfile(colour, os.path.join(skins, '_shared', 'colour.png'))
    elif old.get('shader') == 'plain':
        tex.render_card(colour, values['trim'], values['outerColour'])
    elif key == 'oni':
        tex.oni(folder, folder)
    elif key == 'suminagashi':
        tex.suminagashi(folder, folder)
    elif key == 'tatsuta':
        tex.tatsuta(folder, folder, old['ramps']['ramp'])
    else:
        raise SystemExit(f'{key}: no recipe for its images')


def write_json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


def add_brocade(skins, source):
    folder = os.path.join(skins, BROCADE['key'])
    os.makedirs(folder, exist_ok=True)
    tex.render_card(os.path.join(folder, 'colour.png'), BROCADE_TRIM, BROCADE_TRIM, lines=False)
    for name in ('water.png', 'leaves.png'):
        shutil.copyfile(os.path.join(source, name), os.path.join(folder, name))
    write_json(os.path.join(folder, 'skin.json'), BROCADE)
    for lang, name in BROCADE_NAMES.items():
        path = os.path.join(L10N, f'{lang}.json')
        names = json.load(open(path))
        names[f'skinName_{BROCADE["key"]}'] = name
        write_json(path, names)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('skins', nargs='?', default=SKINS)
    ap.add_argument('--brocade', help='a folder holding water.png and leaves.png')
    args = ap.parse_args()
    skins = os.path.abspath(args.skins)
    for key in sorted(os.listdir(skins)):
        folder = os.path.join(skins, key)
        path = os.path.join(folder, 'skin.json')
        if key.startswith(('_', '.')) or not os.path.isfile(path):
            continue
        old = json.load(open(path))
        if old.get('format') != 2:
            print(key, 'is not format 2; left alone')
            continue
        textures(key, folder, old, skins)
        write_json(path, v3_json(old))
        for name in OLD_FILES.get(key, []):
            os.remove(os.path.join(folder, name))
        print(key, 'converted')
    for name in OLD_SHARED:
        path = os.path.join(skins, '_shared', name)
        if os.path.exists(path):
            os.remove(path)
    if args.brocade:
        add_brocade(skins, args.brocade)


main()
