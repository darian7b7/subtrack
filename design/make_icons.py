"""Builds 10 app icon concepts as SVG plus a comparison page (icons.html).

Every icon uses a 108x108 canvas like an Android adaptive icon: the
background fills the square, the symbol stays inside the central safe
zone so no launcher mask (circle, squircle) cuts it off.
"""
from pathlib import Path

OUT = Path(__file__).parent / 'icons'
OUT.mkdir(exist_ok=True)

GREEN = '#2F6B5A'
DEEP = '#1E4D40'
MINT = '#93D3BD'
AMBER = '#F2B54A'
INK = '#10221C'


def arrow(id_, color):
    return (f'<marker id="{id_}" viewBox="0 0 10 10" refX="4" refY="5" markerWidth="2.2" '
            f'markerHeight="2.2" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="{color}"/></marker>')


ICONS = {
    'Renewal loop': f'''
  <defs>{arrow('a1', MINT)}</defs>
  <rect width="108" height="108" fill="{GREEN}"/>
  <path d="M68.14 37.15 A22 22 0 1 1 46.48 33.33" fill="none" stroke="{MINT}" stroke-width="9"
        stroke-linecap="round" marker-end="url(#a1)"/>
  <circle cx="54" cy="54" r="7.5" fill="{AMBER}"/>''',

    'Calendar €': f'''
  <rect width="108" height="108" fill="#DDF1E8"/>
  <rect x="28" y="32" width="52" height="48" rx="9" fill="#fff"/>
  <path d="M28 41 a9 9 0 0 1 9 -9 h34 a9 9 0 0 1 9 9 v5 h-52 z" fill="{GREEN}"/>
  <rect x="39" y="26" width="5" height="11" rx="2.5" fill="{DEEP}"/>
  <rect x="64" y="26" width="5" height="11" rx="2.5" fill="{DEEP}"/>
  <text x="54" y="73" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="800"
        font-size="25" fill="{GREEN}">€</text>''',

    'Stacked cards': f'''
  <rect width="108" height="108" fill="{INK}"/>
  <rect x="30" y="38" width="48" height="32" rx="7" fill="#E4572E" transform="translate(-6 -9) rotate(-14 54 54)"/>
  <rect x="30" y="38" width="48" height="32" rx="7" fill="#5B6CD9" transform="translate(-3 -4) rotate(-5 54 54)"/>
  <g transform="translate(3 6) rotate(6 54 54)">
    <rect x="30" y="38" width="48" height="32" rx="7" fill="{MINT}"/>
    <rect x="30" y="45" width="48" height="6" fill="{DEEP}"/>
    <rect x="36" y="57" width="10" height="7" rx="2" fill="{AMBER}"/>
  </g>''',

    'S monogram': f'''
  <rect width="108" height="108" fill="{MINT}"/>
  <path d="M62.66 39 A10 10 0 1 0 54 54 A10 10 0 1 1 45.34 69" fill="none" stroke="{DEEP}"
        stroke-width="9" stroke-linecap="round"/>
  <circle cx="67" cy="33.5" r="5.5" fill="{AMBER}"/>''',

    'Coin cycle': f'''
  <defs>{arrow('a5', MINT)}</defs>
  <rect width="108" height="108" fill="{GREEN}"/>
  <path d="M28.63 63.23 A27 27 0 0 1 58.69 27.41" fill="none" stroke="{MINT}" stroke-width="5"
        stroke-linecap="round" marker-end="url(#a5)"/>
  <path d="M79.37 44.77 A27 27 0 0 1 49.31 80.59" fill="none" stroke="{MINT}" stroke-width="5"
        stroke-linecap="round" marker-end="url(#a5)"/>
  <circle cx="54" cy="54" r="15" fill="{AMBER}"/>
  <text x="54" y="61.5" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="800"
        font-size="20" fill="#7A4B00">€</text>''',

    'Reminder bell': f'''
  <rect width="108" height="108" fill="{GREEN}"/>
  <circle cx="54" cy="31" r="3.5" fill="{AMBER}"/>
  <path d="M54 33 c-10 0 -16.5 7.5 -16.5 17.5 v9 l-5.5 7.5 h44 l-5.5 -7.5 v-9 c0 -10 -6.5 -17.5 -16.5 -17.5 z"
        fill="{AMBER}"/>
  <circle cx="54" cy="72" r="5" fill="{AMBER}"/>
  <text x="54" y="59" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="800"
        font-size="17" fill="{GREEN}">€</text>''',

    'Price tag': f'''
  <rect width="108" height="108" fill="#FFF0D4"/>
  <path d="M38 35 H61 L77 54 L61 73 H38 a5 5 0 0 1 -5 -5 V40 a5 5 0 0 1 5 -5 Z" fill="{GREEN}"/>
  <circle cx="65" cy="54" r="4" fill="#FFF0D4"/>
  <text x="49" y="61.5" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="800"
        font-size="20" fill="#fff">€</text>''',

    'Receipt': f'''
  <rect width="108" height="108" fill="#EEF2EE"/>
  <path d="M36 27 H72 V80 l-4.5 4 -4.5 -4 -4.5 4 -4.5 -4 -4.5 4 -4.5 -4 -4.5 4 -4.5 -4 Z" fill="{GREEN}"/>
  <path d="M41 39 l3 3 5 -6" fill="none" stroke="{MINT}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="53" y="37" width="13" height="4" rx="2" fill="{MINT}"/>
  <path d="M41 51 l3 3 5 -6" fill="none" stroke="{MINT}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="53" y="49" width="13" height="4" rx="2" fill="{MINT}"/>
  <path d="M41 63 l3 3 5 -6" fill="none" stroke="{AMBER}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="53" y="61" width="13" height="4" rx="2" fill="{AMBER}"/>''',

    'Spending donut': f'''
  <rect width="108" height="108" fill="{INK}"/>
  <g transform="rotate(-90 54 54)" fill="none" stroke-width="12">
    <circle cx="54" cy="54" r="20" stroke="{MINT}" stroke-dasharray="66 59.66"/>
    <circle cx="54" cy="54" r="20" stroke="{AMBER}" stroke-dasharray="32 93.66" stroke-dashoffset="-69"/>
    <circle cx="54" cy="54" r="20" stroke="#7C8CF0" stroke-dasharray="18.66 107" stroke-dashoffset="-104"/>
  </g>''',

    'Wallet': f'''
  <rect width="108" height="108" fill="{GREEN}"/>
  <rect x="35" y="31" width="38" height="16" rx="4" fill="{AMBER}" transform="rotate(-9 54 39)"/>
  <rect x="29" y="40" width="50" height="36" rx="8" fill="{MINT}"/>
  <rect x="58" y="50" width="25" height="16" rx="6" fill="{DEEP}"/>
  <circle cx="66" cy="58" r="3" fill="{MINT}"/>''',
}


def svg(body, size=None):
    dim = f' width="{size}" height="{size}"' if size else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"{dim}>{body}\n</svg>\n'


tiles = []
for i, (name, body) in enumerate(ICONS.items(), 1):
    (OUT / f'icon-{i:02d}.svg').write_text(svg(body), encoding='utf-8')
    # Each preview needs unique marker ids, so suffix them per use.
    def variant(tag):
        return body.replace('id="a', f'id="{tag}a').replace('url(#a', f'url(#{tag}a')
    tiles.append(f'''
    <figure class="tile">
      <div class="big">{svg(variant(f"b{i}"))}</div>
      <div class="row">
        <div class="circle">{svg(variant(f"c{i}"))}</div>
        <div class="home">{svg(variant(f"h{i}"))}<span>Subtrack</span></div>
      </div>
      <figcaption><b>{i}</b> {name}</figcaption>
    </figure>''')

page = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Subtrack icon options</title>
<style>
  :root {{ --bg: #F3F5F2; --fg: #14201B; --muted: #5C6B64; --card: #fff; --wall: #D9E4DE; }}
  @media (prefers-color-scheme: dark) {{
    :root {{ --bg: #111513; --fg: #E6ECE8; --muted: #94A39B; --card: #1A201D; --wall: #26302B; }}
  }}
  body {{ margin: 0; background: var(--bg); color: var(--fg); font: 15px/1.5 system-ui, sans-serif; padding: 28px 16px 48px; }}
  h1 {{ font-size: 24px; margin: 0 auto 4px; max-width: 1100px; }}
  p {{ margin: 0 auto 24px; max-width: 1100px; color: var(--muted); }}
  .grid {{ display: grid; gap: 16px; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); max-width: 1100px; margin: 0 auto; }}
  .tile {{ margin: 0; background: var(--card); border-radius: 20px; padding: 18px; display: grid; gap: 14px; justify-items: center; }}
  .big svg {{ width: 132px; height: 132px; border-radius: 30%; display: block; box-shadow: 0 6px 18px rgb(0 0 0 / .18); }}
  .row {{ display: flex; gap: 14px; align-items: center; background: var(--wall); border-radius: 14px; padding: 10px 14px; }}
  .circle svg {{ width: 56px; height: 56px; border-radius: 50%; display: block; }}
  .home {{ display: grid; justify-items: center; gap: 3px; font-size: 10px; color: var(--muted); }}
  .home svg {{ width: 40px; height: 40px; border-radius: 50%; display: block; }}
  figcaption {{ font-size: 15px; }}
  figcaption b {{ display: inline-grid; place-items: center; width: 24px; height: 24px; border-radius: 50%; background: {GREEN}; color: #fff; font-size: 12px; margin-right: 6px; }}
</style>
</head>
<body>
<h1>Subtrack icon options</h1>
<p>Each one is shown in a rounded square, in a circle (how most Android phones crop it) and at home screen size. Tell me the number you like.</p>
<div class="grid">{''.join(tiles)}
</div>
</body>
</html>
'''
(Path(__file__).parent / 'icons.html').write_text(page, encoding='utf-8')
print('wrote', len(ICONS), 'icons')
