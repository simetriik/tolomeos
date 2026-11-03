#!/usr/bin/env python3
"""Fond de l'écran de connexion : fond Ganvié assombri et flouté, teinté d'indigo.

Usage : make-background.py fond.png sortie.png
Le champ du mot de passe reste lisible : détails adoucis, luminosité réduite,
teinte indigo #23325E de la charte.
"""
import sys
from PIL import Image, ImageEnhance, ImageFilter

INDIGO = (0x23, 0x32, 0x5E)
FLOU = 16          # rayon du flou gaussien (pixels, image 1920x1080)
LUMINOSITE = 0.42  # 1.0 = inchangé
TEINTE = 0.30      # part d'indigo mélangée

im = Image.open(sys.argv[1]).convert("RGB")
im = im.filter(ImageFilter.GaussianBlur(FLOU))
im = ImageEnhance.Brightness(im).enhance(LUMINOSITE)
im = Image.blend(im, Image.new("RGB", im.size, INDIGO), TEINTE)
im.save(sys.argv[2], optimize=True)
