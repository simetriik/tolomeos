#!/usr/bin/env python3
# Génère l'identité visuelle de Tɔlɔmɛ : logos et 8 fonds d'écran (SVG).
# Usage : python3 generer-artwork.py [dossier_sortie] [police_montserrat.ttf]
# Sans police : le nom du logo reste un <text> en Montserrat.
# Avec la police (ex. /usr/share/fonts/truetype/montserrat/Montserrat-ExtraBold.ttf
# du paquet fonts-montserrat) : le nom est vectorisé (nécessite fonttools).
import os, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "artwork"
FONT = sys.argv[2] if len(sys.argv) > 2 else None
os.makedirs(f"{OUT}/logos", exist_ok=True)
os.makedirs(f"{OUT}/fonds", exist_ok=True)

IND, IND2, IND3, IND4 = "#23325E", "#2E3F72", "#4A5A8C", "#1B2749"
RED, RED2 = "#A9431E", "#C8693F"
OCR, OCR2, OCR3 = "#C98A2B", "#E0A646", "#B07422"
BRN, CREAM, BLK = "#3A2318", "#F4EDE1", "#141413"


def save(path, w, h, body):
    with open(path, "w", encoding="utf-8") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.0f} {h:.0f}" '
                f'width="{w:.0f}" height="{h:.0f}">{body}</svg>\n')


def rect(x, y, w, h, c, rx=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{c}"/>'

# ---------------------------------------------------------------- logos
CROWN = ('<circle cx="31" cy="36" r="14" fill="{c}"/><circle cx="69" cy="36" r="14" fill="{c}"/>'
         '<circle cx="50" cy="27" r="17" fill="{c}"/><ellipse cx="50" cy="40" rx="27" ry="10" fill="{c}"/>')
TRUNK = '<path d="M42 44 C35 56 34 70 37 79 L63 79 C66 70 65 56 58 44 Z" fill="{t}"/>'


def tree(c=OCR, t=RED):
    return CROWN.format(c=c) + TRUNK.format(t=t)


def sym(ring=False):
    # Baobab dans un disque indigo, posé sur la terre brune (sans racines)
    if ring:
        return (f'<circle cx="50" cy="50" r="49" fill="{CREAM}"/><circle cx="50" cy="50" r="45" fill="{IND}"/>'
                + tree() + f'<path d="M15.6 79 Q50 72 84.4 79 A45 45 0 0 1 15.6 79 Z" fill="{BRN}"/>')
    return (f'<circle cx="50" cy="50" r="48" fill="{IND}"/>' + tree()
            + f'<path d="M11.8 79 Q50 72 88.2 79 A48 48 0 0 1 11.8 79 Z" fill="{BRN}"/>')


def mono(col):
    return tree(col, col) + f'<path d="M16 80 Q50 72 84 80 Q50 87 16 80 Z" fill="{col}"/>'


def icon(simple=False):
    body = (f'<circle cx="50" cy="32" r="22" fill="{OCR}"/>'
            f'<path d="M40 46 C34 58 34 72 37 84 L63 84 C66 72 66 58 60 46 Z" fill="{RED}"/>'
            if simple else tree())
    gy = 84 if simple else 79
    return (f'<defs><clipPath id="sq"><rect x="2" y="2" width="96" height="96" rx="22"/></clipPath></defs>'
            f'<g clip-path="url(#sq)"><rect width="100" height="100" fill="{IND}"/>{body}'
            f'<path d="M0 {gy} Q50 {gy - 7} 100 {gy} V100 H0 Z" fill="{BRN}"/></g>')


NAME = "tɔlɔmɛ"


def word(size, x0, baseline, color):
    # Renvoie (élément SVG, largeur) du nom en Montserrat ExtraBold
    if FONT:
        from fontTools.ttLib import TTFont
        from fontTools.pens.svgPathPen import SVGPathPen
        from fontTools.pens.transformPen import TransformPen
        font = TTFont(FONT)
        if "fvar" in font:
            from fontTools.varLib.instancer import instantiateVariableFont
            font = instantiateVariableFont(font, {"wght": 800})
        cmap, gs, upm, hmtx = font.getBestCmap(), font.getGlyphSet(), font["head"].unitsPerEm, font["hmtx"]
        s, x, d, track = size / upm, 0, [], -0.02 * size
        for ch in NAME:
            g = cmap[ord(ch)]
            pen = SVGPathPen(gs)
            gs[g].draw(TransformPen(pen, (s, 0, 0, -s, x0 + x, baseline)))
            d.append(pen.getCommands())
            x += hmtx[g][0] * s + track
        return f'<path d="{" ".join(d)}" fill="{color}"/>', x - track
    w = size * 3.4
    return (f'<text x="{x0}" y="{baseline}" font-family="Montserrat, sans-serif" font-weight="800" '
            f'font-size="{size}" letter-spacing="-0.02em" fill="{color}">{NAME}</text>'), w


L = f"{OUT}/logos"
save(f"{L}/symbole.svg", 100, 100, sym())
save(f"{L}/icone.svg", 100, 100, icon())
save(f"{L}/icone-16.svg", 100, 100, icon(True))
save(f"{L}/symbole-monochrome-noir.svg", 100, 100, mono(BLK))
save(f"{L}/symbole-monochrome-blanc.svg", 100, 100, mono("#FFFFFF"))
for name, mark, col in (("logo-horizontal", sym(), BRN), ("logo-horizontal-inverse", sym(True), CREAM),
                        ("logo-horizontal-monochrome-noir", mono(BLK), BLK),
                        ("logo-horizontal-monochrome-blanc", mono("#FFFFFF"), "#FFFFFF")):
    txt, w = word(96, 128, 84, col)
    save(f"{L}/{name}.svg", 128 + w + 4, 100, f"<g>{mark}</g>{txt}")
_, w2 = word(56, 0, 0, BRN)
S = max(140, w2 + 20)
txt, _ = word(56, (S - w2) / 2, 160, BRN)
save(f"{L}/logo-carre.svg", S, 180, f'<g transform="translate({(S - 100) / 2:.1f} 0)">{sym()}</g>{txt}')

# ------------------------------------------------------- fonds d'écran


def house(x, y, s=1.0):
    g = [rect(px, 120, 9, 130, BRN) for px in (12, 70, 128, 186)]
    g += [rect(-6, 112, 216, 16, BRN, 4), rect(10, 0, 184, 116, RED), rect(82, 42, 40, 74, BRN, 4),
          rect(30, 34, 30, 26, BRN, 3), rect(144, 34, 30, 26, BRN, 3),
          f'<polygon points="-18,6 102,-88 222,6" fill="{OCR}"/>',
          f'<polygon points="102,-88 222,6 102,6" fill="{OCR3}"/>',
          rect(10, 262, 184, 10, IND3, 5), rect(40, 284, 124, 8, IND3, 4)]
    return f'<g transform="translate({x} {y}) scale({s})">{"".join(g)}</g>'


def ganvie():
    p = [rect(0, 0, 1920, 1080, IND), rect(0, 300, 1920, 160, IND2), rect(0, 460, 1920, 90, IND3),
         rect(0, 550, 1920, 50, "#7A6A7E"), f'<circle cx="1380" cy="540" r="92" fill="{OCR2}"/>',
         rect(0, 600, 1920, 480, IND4)]
    for y, x, w in [(640, 120, 380), (700, 1500, 300), (780, 300, 520), (860, 1300, 460), (950, 80, 600), (1010, 1100, 640)]:
        p.append(rect(x, y, w, 10, IND2, 5))
    for i, (y, w) in enumerate([(624, 230), (660, 180), (700, 130), (746, 84), (796, 46)]):
        p.append(rect(1380 - w // 2, y, w, 12, OCR if i % 2 == 0 else OCR3, 6))
    p += [house(1560, 470, 0.55), house(1720, 490, 0.42), house(180, 470, 1.0), house(470, 500, 0.8), house(760, 520, 0.62),
          f'<path d="M930 880 Q1060 932 1210 880 L1198 900 Q1060 948 942 900 Z" fill="{BRN}"/>',
          f'<path d="M1150 720 L1112 930" stroke="{BRN}" stroke-width="8" stroke-linecap="round"/>',
          rect(950, 952, 240, 8, IND2, 4)]
    return "".join(p)


def tata(x, y):
    g = [rect(0, 70, 330, 110, RED2, 6), rect(140, 120, 50, 60, BRN, 24)]
    for tx, h in ((0, 150), (240, 150), (110, 190)):
        g += [rect(tx, 180 - h, 90, h, RED, 40),
              f'<polygon points="{tx - 14},{186 - h} {tx + 45},{90 - h} {tx + 104},{186 - h}" fill="{OCR}"/>',
              f'<polygon points="{tx + 45},{90 - h} {tx + 104},{186 - h} {tx + 45},{186 - h}" fill="{OCR3}"/>']
    return f'<g transform="translate({x} {y})">{"".join(g)}</g>'


def baobab(x, y, s):
    return f'<g transform="translate({x} {y}) scale({s})">{tree()}</g>'


def atacora():
    return "".join([
        rect(0, 0, 1920, 1080, CREAM), rect(0, 260, 1920, 180, "#EED9B8"), rect(0, 440, 1920, 120, "#E3B77A"),
        f'<circle cx="560" cy="470" r="112" fill="{OCR}"/>',
        '<path d="M0 560 L180 470 L360 540 L620 420 L860 530 L1100 440 L1340 520 L1600 410 L1920 520 L1920 1080 L0 1080 Z" fill="#8E9BC4"/>',
        f'<path d="M0 640 L240 540 L520 630 L780 520 L1080 640 L1380 540 L1660 620 L1920 560 L1920 1080 L0 1080 Z" fill="{IND3}"/>',
        f'<path d="M0 760 L300 650 L620 740 L960 640 L1260 750 L1600 660 L1920 730 L1920 1080 L0 1080 Z" fill="{IND}"/>',
        f'<path d="M0 900 Q480 800 960 870 Q1440 940 1920 840 L1920 1080 L0 1080 Z" fill="{BRN}"/>',
        baobab(400, 640, 2.6), tata(1240, 740), rect(0, 1040, 1920, 40, "#2A1910")])


def palm(x, y, s, flip=False):
    t = f'translate({x} {y}) scale({-s if flip else s} {s})'
    trunk = f'<path d="M0 0 Q40 -260 140 -560" stroke="{BRN}" stroke-width="26" fill="none" stroke-linecap="round"/>'
    fr = "".join(f'<path d="{d}" fill="{BRN}" stroke="{BRN}" stroke-width="10" stroke-linejoin="round"/>' for d in (
        "M140 -560 Q40 -640 -80 -580 Q40 -600 140 -556 Z", "M140 -560 Q120 -700 30 -760 Q140 -690 146 -562 Z",
        "M140 -560 Q240 -700 330 -700 Q230 -660 146 -556 Z", "M140 -560 Q300 -580 380 -480 Q280 -540 142 -552 Z",
        "M140 -560 Q200 -460 200 -360 Q170 -470 136 -552 Z", "M140 -560 Q60 -500 10 -420 Q70 -510 136 -556 Z"))
    return f'<g transform="{t}">{trunk}{fr}<circle cx="140" cy="-556" r="20" fill="{BRN}"/></g>'


def ouidah():
    p = [rect(0, 0, 1920, 1080, IND), rect(0, 240, 1920, 150, "#4A3A5E"), rect(0, 390, 1920, 130, "#7A3E3A"),
         rect(0, 520, 1920, 80, RED), rect(0, 600, 1920, 40, OCR), f'<circle cx="960" cy="640" r="132" fill="{OCR2}"/>',
         rect(0, 640, 1920, 440, IND4)]
    for y, w in [(664, 300), (700, 220), (742, 150), (790, 90), (838, 44)]:
        p.append(rect(960 - w // 2, y, w, 12, OCR, 6))
    for y, x, w in [(690, 120, 420), (760, 1380, 380), (830, 260, 300), (820, 1560, 260)]:
        p.append(rect(x, y, w, 9, IND2, 5))
    waves = "M0 900 " + " ".join(f"Q{x + 60} 870 {x + 120} 900" for x in range(0, 1920, 120)) + " L1920 1080 L0 1080 Z"
    p += [f'<path d="{waves}" fill="{CREAM}"/>',
          '<path d="M0 940 Q480 915 960 935 Q1440 955 1920 925 L1920 1080 L0 1080 Z" fill="#D9A85C"/>',
          palm(170, 1080, 1.0), palm(1760, 1080, 0.78, flip=True)]
    return "".join(p)


def arch(x, y, w, h, c):
    r = w / 2
    return f'<path d="M{x} {y + h} V{y + r} A{r} {r} 0 0 1 {x + w} {y + r} V{y + h} Z" fill="{c}"/>'


def hut(x, y, s, door=True):
    return (f'<g transform="translate({x} {y}) scale({s})">{rect(0, 0, 300, 240, RED)}'
            f'<polygon points="-40,10 150,-150 340,10" fill="{OCR}"/><polygon points="150,-150 340,10 150,10" fill="{OCR3}"/>'
            f'{rect(115, 120, 70, 120, BRN, 6)}</g>')


def abomey():
    p = [rect(0, 0, 1920, 1080, "#EED9B8"), rect(0, 0, 1920, 220, CREAM), rect(0, 420, 1920, 160, "#E3B77A"),
         f'<circle cx="1500" cy="300" r="96" fill="{OCR}"/>', rect(0, 580, 1920, 500, BRN),
         '<path d="M0 640 Q960 600 1920 640 L1920 1080 L0 1080 Z" fill="#5A3624"/>', rect(360, 520, 1200, 230, RED)]
    for px in range(360, 1561, 150):
        p.append(rect(px - 10, 520, 20, 230, "#8E3618"))
    p += ['<polygon points="300,530 520,380 1400,380 1620,530" fill="%s"/>' % OCR,
          '<polygon points="960,380 1400,380 1620,530 960,530" fill="%s"/>' % OCR3, rect(860, 600, 200, 150, BRN, 8)]
    for i, mx in enumerate(range(420, 1520, 100)):
        if 820 < mx < 1080:
            continue
        p.append(rect(mx, 590, 44, 44, CREAM, 4) if i % 2 else
                 f'<polygon points="{mx},634 {mx + 22},592 {mx + 44},634" fill="{CREAM}"/>')
    p += [hut(80, 600, 0.6), hut(1650, 600, 0.55), rect(0, 1030, 1920, 50, "#2A1910")]
    return "".join(p)


def portonovo():
    p = [rect(0, 0, 1920, 1080, "#8E9BC4"), rect(0, 0, 1920, 200, IND3), rect(0, 360, 1920, 200, "#B9C2DE"),
         f'<circle cx="300" cy="230" r="80" fill="{OCR2}"/>']
    facades = [(80, 340, OCR, 300), (450, 330, CREAM, 340), (810, 300, RED2, 280), (1140, 320, OCR2, 320), (1490, 350, "#D8D2E8", 360)]
    for fx, fw, col, fh in facades:
        top = 760 - fh
        p += [rect(fx, top, fw, fh, col), rect(fx - 8, top - 20, fw + 16, 24, BRN, 4)]
        n = 3 if fw > 330 else 2
        step = fw / n
        for k in range(n):
            wx = fx + step * k + step / 2 - 26
            p += [arch(wx, top + 50, 52, 90, IND), arch(wx, top + fh - 130, 52, 130, BRN if k == n // 2 else IND)]
        p.append(rect(fx + 10, top + 150, fw - 20, 10, BRN, 3))
        for bx in range(int(fx + 20), int(fx + fw - 10), 22):
            p.append(rect(bx, top + 150, 5, 34, BRN))
    p += [rect(0, 760, 1920, 40, BRN), rect(0, 800, 1920, 280, IND4)]
    for y, x, w in [(840, 140, 420), (900, 1200, 520), (960, 420, 380), (1020, 1500, 300)]:
        p.append(rect(x, y, w, 10, IND2, 5))
    for fx, fw, col, fh in facades:
        p.append(rect(fx + 10, 810, fw - 20, 12, col, 6))
    return "".join(p)


def pirogue(x, y, s, hull, band):
    return (f'<g transform="translate({x} {y}) scale({s})"><path d="M0 0 Q200 60 420 0 L400 40 Q200 96 20 40 Z" fill="{hull}"/>'
            f'<path d="M14 18 Q200 76 406 18 L402 28 Q200 86 18 28 Z" fill="{band}"/></g>')


def grandpopo():
    p = [rect(0, 0, 1920, 1080, "#B9C2DE"), rect(0, 0, 1920, 180, IND3), rect(0, 180, 1920, 200, "#8E9BC4"),
         f'<circle cx="1560" cy="200" r="74" fill="{CREAM}"/>', rect(0, 520, 1920, 220, IND), rect(0, 520, 1920, 30, IND2)]
    for y, x, w in [(580, 200, 500), (620, 1100, 600), (670, 500, 460)]:
        p.append(rect(x, y, w, 10, IND3, 5))
    waves = "M0 740 " + " ".join(f"Q{x + 80} 700 {x + 160} 740" for x in range(0, 1920, 160)) + " L1920 1080 L0 1080 Z"
    p += [f'<path d="{waves}" fill="{CREAM}"/>', '<path d="M0 790 Q960 760 1920 790 L1920 1080 L0 1080 Z" fill="#E3C28A"/>',
          pirogue(520, 850, 1.0, RED, OCR), pirogue(1000, 900, 0.9, IND, CREAM), pirogue(1380, 830, 0.8, OCR3, RED),
          palm(120, 1080, 0.95), palm(1820, 1080, 0.85, flip=True), palm(1660, 1080, 0.6, flip=True)]
    return "".join(p)


def nere(x, y, s):
    return (f'<g transform="translate({x} {y}) scale({s})">{rect(-10, -120, 20, 120, BRN, 4)}'
            '<ellipse cx="0" cy="-140" rx="150" ry="40" fill="#5A3624"/><ellipse cx="-60" cy="-170" rx="90" ry="34" fill="#5A3624"/>'
            '<ellipse cx="70" cy="-168" rx="80" ry="30" fill="#5A3624"/></g>')


def case(x, y, s):
    return (f'<g transform="translate({x} {y}) scale({s})">{rect(0, 0, 160, 110, RED, 10)}'
            f'<polygon points="-24,8 80,-110 184,8" fill="{OCR}"/>{rect(60, 50, 40, 60, BRN, 18)}</g>')


def parakou():
    p = [rect(0, 0, 1920, 1080, RED), rect(0, 0, 1920, 200, "#7A3E3A"), rect(0, 330, 1920, 160, RED2), rect(0, 490, 1920, 110, OCR),
         f'<circle cx="1200" cy="560" r="150" fill="{OCR2}"/>',
         '<path d="M0 640 Q480 600 960 630 Q1440 660 1920 610 L1920 1080 L0 1080 Z" fill="#B07422"/>',
         f'<path d="M0 760 Q600 700 1200 760 Q1600 800 1920 740 L1920 1080 L0 1080 Z" fill="{BRN}"/>',
         nere(300, 660, 1.1), nere(820, 640, 0.6), nere(1640, 650, 0.85), case(1300, 740, 0.8), case(1440, 756, 0.65)]
    for gx in range(0, 1920, 36):
        h = 60 + (gx * 37 % 70)
        p.append(f'<path d="M{gx} 1080 L{gx + 10} {1080 - h} L{gx + 20} 1080 Z" fill="#2A1910"/>')
    return "".join(p)


def natitingou():
    p = [rect(0, 0, 1920, 1080, "#B9C2DE"), rect(0, 0, 1920, 220, IND3), rect(0, 220, 1920, 160, "#8E9BC4"),
         f'<path d="M0 380 L240 300 L480 360 L700 280 L700 1080 L0 1080 Z" fill="{IND}"/>',
         f'<path d="M1220 280 L1460 330 L1700 270 L1920 340 L1920 1080 L1220 1080 Z" fill="{IND}"/>',
         f'<path d="M560 360 L860 330 L860 1080 L560 1080 Z" fill="{RED}"/>',
         f'<path d="M1060 330 L1360 360 L1360 1080 L1060 1080 Z" fill="{RED}"/>',
         '<path d="M660 420 L860 400 L860 1080 L660 1080 Z" fill="#8E3618"/>',
         '<path d="M1060 400 L1260 420 L1260 1080 L1060 1080 Z" fill="#8E3618"/>', rect(860, 330, 200, 520, CREAM)]
    for cx, c in ((880, "#D8D2E8"), (930, "#B9C2DE"), (990, "#D8D2E8"), (1030, "#B9C2DE")):
        p.append(rect(cx, 360, 12, 480, c, 6))
    p += [f'<path d="M0 820 Q960 780 1920 820 L1920 1080 L0 1080 Z" fill="{IND4}"/>',
          f'<ellipse cx="960" cy="840" rx="220" ry="34" fill="{CREAM}"/>']
    for y, x, w in [(900, 300, 420), (960, 1150, 480), (1020, 520, 360)]:
        p.append(rect(x, y, w, 10, IND2, 5))
    p += [f'<path d="M0 1080 L0 900 Q140 860 260 920 L320 1080 Z" fill="{BRN}"/>',
          f'<path d="M1920 1080 L1920 880 Q1780 850 1660 910 L1600 1080 Z" fill="{BRN}"/>']
    return "".join(p)


FONDS = {"ganvie": ganvie, "porto-novo": portonovo, "abomey": abomey, "ouidah": ouidah,
         "grand-popo": grandpopo, "parakou": parakou, "natitingou": natitingou, "atacora": atacora}
for slug, fn in FONDS.items():
    save(f"{OUT}/fonds/tolome-fond-{slug}.svg", 1920, 1080, fn())

print(f"OK : {len(os.listdir(OUT + '/logos'))} logos et {len(FONDS)} fonds dans {OUT}/"
      + ("" if FONT else " (nom du logo en <text> : relancer avec la police Montserrat pour le vectoriser)"))
