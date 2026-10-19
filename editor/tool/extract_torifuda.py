"""Writes assets/data/torifuda.json (poem number -> the three torifuda columns)
from the app's poems.json. Usage: extract_torifuda.py path/to/poems.json"""
import json
import sys

poems = json.load(open(sys.argv[1]))
out = {str(p['id']): p['torifudaColumns'] for p in poems}
json.dump(out, open('assets/data/torifuda.json', 'w'), ensure_ascii=False, separators=(',', ':'))
