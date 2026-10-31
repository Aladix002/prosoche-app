#!/usr/bin/env python3
"""Staticke rezy a subset fontov Prosoche (docs/DESIGN.md 3.1).

Zdroj: variabilne fonty z github.com/google/fonts (ofl/ebgaramond,
ofl/cormorantgaramond), stiahnute rucne do SRC_DIR:

  SRC_DIR/ebgaramond/EBGaramond[wght].ttf
  SRC_DIR/ebgaramond/EBGaramond-Italic[wght].ttf
  SRC_DIR/cormorantgaramond/CormorantGaramond[wght].ttf

Spustenie (z korena appky, potrebuje fonttools):
  python3 -I tool/fonts/build_fonts.py SRC_DIR assets/fonts

OFL 1.1 upravu dovoluje; fonty nemaju Reserved Font Name.
"""
import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

# Latinka, latin-ext, grectina (aj polytonicka), interpunkcia, kombinovane
# diakriticke znamienka.
UNICODES = [
    *range(0x0020, 0x007F), *range(0x00A0, 0x0250), *range(0x0300, 0x0370),
    *range(0x0370, 0x0400), *range(0x1E00, 0x1F00), *range(0x1F00, 0x2000),
    *range(0x2000, 0x2070), 0x20AC, 0x2116, 0x2122, *range(0x2190, 0x2194),
    0x2212, 0x25CF, 0xFB01, 0xFB02,
]

JOBS = [
    # (zdroj, ciel, wght)
    ('ebgaramond/EBGaramond[wght].ttf', 'eb_garamond/EBGaramond-Regular.ttf', 400),
    ('ebgaramond/EBGaramond[wght].ttf', 'eb_garamond/EBGaramond-Medium.ttf', 500),
    ('ebgaramond/EBGaramond-Italic[wght].ttf', 'eb_garamond/EBGaramond-Italic.ttf', 400),
    ('cormorantgaramond/CormorantGaramond[wght].ttf',
     'cormorant_garamond/CormorantGaramond-Medium.ttf', 500),
    ('cormorantgaramond/CormorantGaramond[wght].ttf',
     'cormorant_garamond/CormorantGaramond-SemiBold.ttf', 600),
]


def build(src: Path, out: Path) -> None:
    for rel_src, rel_out, wght in JOBS:
        font = TTFont(src / rel_src)
        static = instancer.instantiateVariableFont(
            font, {'wght': wght}, updateFontNames=True)
        opts = subset.Options()
        opts.layout_features = ['*']
        opts.name_IDs = ['*']
        opts.name_languages = ['*']
        opts.notdef_outline = True
        opts.glyph_names = False
        opts.hinting = False
        sub = subset.Subsetter(opts)
        sub.populate(unicodes=UNICODES)
        sub.subset(static)
        dst = out / rel_out
        dst.parent.mkdir(parents=True, exist_ok=True)
        static.save(dst)
        print(f'{dst} {dst.stat().st_size // 1024} KB')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    build(Path(sys.argv[1]), Path(sys.argv[2]))
