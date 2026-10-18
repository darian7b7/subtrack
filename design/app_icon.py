"""The chosen app icon (calendar with €), as the SVG layers every platform needs.

Run this, then `node render.mjs` to turn them into PNGs in the right folders.
"""
from pathlib import Path

OUT = Path(__file__).parent / 'final'
OUT.mkdir(exist_ok=True)

GREEN = '#2F6B5A'
DEEP = '#1E4D40'
MINT = '#93D3BD'

# Calendar drawn on a 108x108 canvas (Android adaptive icon size). Launchers
# only show the middle 72x72 and then crop that to a circle or squircle, so
# the calendar is scaled down to leave clear space inside that shape.
SCALE = 0.82

GLYPH = f'''<g transform="translate(54 54) scale({SCALE}) translate(-54 -54)">
  <rect x="28" y="32" width="52" height="48" rx="9" fill="#fff"/>
  <path d="M28 41 a9 9 0 0 1 9 -9 h34 a9 9 0 0 1 9 9 v5 h-52 z" fill="{MINT}"/>
  <rect x="39" y="26" width="5" height="11" rx="2.5" fill="{DEEP}"/>
  <rect x="64" y="26" width="5" height="11" rx="2.5" fill="{DEEP}"/>
  <text x="54" y="73" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="800"
        font-size="25" fill="{GREEN}">€</text>
</g>'''

# One-color version for Android's themed icons and the notification icon:
# Android only uses the shape, so the € and the header line are cut out.
MONO = f'''<defs><mask id="m">
  <g transform="translate(54 54) scale({SCALE}) translate(-54 -54)">
    <rect x="28" y="32" width="52" height="48" rx="9" fill="#fff"/>
    <rect x="28" y="46" width="52" height="2.5" fill="#000"/>
    <rect x="37" y="24" width="9" height="15" rx="4.5" fill="#000"/>
    <rect x="62" y="24" width="9" height="15" rx="4.5" fill="#000"/>
    <rect x="39" y="26" width="5" height="11" rx="2.5" fill="#fff"/>
    <rect x="64" y="26" width="5" height="11" rx="2.5" fill="#fff"/>
    <text x="54" y="73" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="800"
          font-size="25" fill="#000">€</text>
  </g>
</mask></defs>
<rect width="108" height="108" fill="#fff" mask="url(#m)"/>'''


def svg(body, view='0 0 108 108'):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}">{body}</svg>\n'


files = {
    # The visible 72x72 middle, for the store, web and legacy icons, so they
    # match what Android launchers show.
    'full.svg': svg(f'<rect width="108" height="108" fill="{GREEN}"/>{GLYPH}', view='18 18 72 72'),
    'foreground.svg': svg(GLYPH),
    'monochrome.svg': svg(MONO),
    # Cropped to the calendar so it fills the small status bar icon.
    'status.svg': svg(MONO, view='30 30 48 48'),
}
for name, content in files.items():
    (OUT / name).write_text(content, encoding='utf-8')
print('wrote', ', '.join(files))
