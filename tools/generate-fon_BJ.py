#!/usr/bin/env python3
# Régénère la locale glibc fon_BJ (packages/tolome-locales/i18n/locales/fon_BJ) à partir
# du glossaire Tɔlɔmɛ (CSV, colonne « Fon », lignes LC01 à LC26).
# Usage : python3 tools/generate-fon_BJ.py <glossaire.csv> [sortie]
# Sortie par défaut : packages/tolome-locales/i18n/locales/fon_BJ
# Le glossaire n'est pas dans ce dépôt.
import csv, os, sys
src = sys.argv[1]
dst = sys.argv[2] if len(sys.argv) > 2 else os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "packages", "tolome-locales", "i18n", "locales", "fon_BJ")
# Alphabet validé (31 lettres) : gb après g, kp après p, ny après y
kp_after, ny_after = "p", "y"
rows = {r[0]: r for r in csv.reader(open(src, encoding="utf-8", newline="")) if r[0].startswith("LC")}
F = 7
v = lambda k: rows[k][F].strip()
days_mon = [v(f"LC{i:02d}") for i in range(1, 8)]
days = [days_mon[6]] + days_mon[:6]                      # glibc : dimanche en premier
abmon_all = v("LC08").split(); assert len(abmon_all) == 7
assert len(alpha := v('LC24').split()) == 31
abday = [abmon_all[6]] + abmon_all[:6]
mon = [v(f"LC{i:02d}") for i in range(9, 21)]
abmon = v("LC21").split(); assert len(abmon) == 12
am, pm = [x.strip() for x in v("LC22").split("/")]
yes, no = [x.strip() for x in v("LC23").split("/")]
alpha = v("LC24").split()
lang, country = v("LC25"), v("LC26")
q = lambda s: '"' + s + '"'
lst = lambda xs: ";/\n            ".join(q(x) for x in xs)
order = alpha[:]
def after(letter):
    i = order.index(letter); return order[i - 1]
cap = {"ɖ": "Ɖ", "ɛ": "Ɛ", "ɔ": "Ɔ"}
u = lambda c: "<U%04X>" % ord(c)
extra = [l for l in alpha if l in cap or len(l) == 2]    # lettres à placer
out = f'''comment_char %
escape_char /

% Fon (Fɔngbè, ISO 639-3 « fon »), Bénin, pour Tɔlɔmɛ.
%
% Noms des jours et des mois, réponses oui/non, nom de la langue et du pays, ordre
% alphabétique : glossaire Tɔlɔmɛ (lignes LC01 à LC26), orthographe validée.
% Monnaie, nombres, téléphone : repris de fr_BJ. Voir README.Debian.

LC_IDENTIFICATION
title      "Fon locale for Benin"
source     "Tɔlɔmɛ"
address    ""
contact    "Simetriik Solutions"
email      "dev@tolome.net"
tel        ""
fax        ""
language   "Fon"
territory  "Benin"
revision   "1.0"
date       "2026-11-03"

category "i18n:2012";LC_IDENTIFICATION
category "i18n:2012";LC_CTYPE
category "i18n:2012";LC_COLLATE
category "i18n:2012";LC_TIME
category "i18n:2012";LC_NUMERIC
category "i18n:2012";LC_MONETARY
category "i18n:2012";LC_MESSAGES
category "i18n:2012";LC_PAPER
category "i18n:2012";LC_NAME
category "i18n:2012";LC_ADDRESS
category "i18n:2012";LC_TELEPHONE
category "i18n:2012";LC_MEASUREMENT
END LC_IDENTIFICATION

LC_CTYPE
copy "fr_FR"
END LC_CTYPE

% Alphabet fon à 31 lettres, dans cet ordre exact :
%   a b c d ɖ e ɛ f g gb h i j k l m n o ɔ p kp r s t u v w x y ny z
% gb, kp et ny sont des lettres à part entière (digraphes) : gb après g, kp après p,
% ny après y. ɖ, ɛ, ɔ suivent d, e, o (déjà ainsi dans iso14651_t1). Pas de hw ni de xw.
% Les signes combinants (tons) n'interviennent qu'au deuxième niveau de tri.
LC_COLLATE
copy "iso14651_t1"

collating-symbol <d-tail>
collating-symbol <open-e>
collating-symbol <open-o>
collating-symbol <gb-digraph>
collating-symbol <kp-digraph>
collating-symbol <ny-digraph>
collating-element <g-b> from "gb"
collating-element <g-B> from "gB"
collating-element <G-b> from "Gb"
collating-element <G-B> from "GB"
collating-element <k-p> from "kp"
collating-element <k-P> from "kP"
collating-element <K-p> from "Kp"
collating-element <K-P> from "KP"
collating-element <n-y> from "ny"
collating-element <n-Y> from "nY"
collating-element <N-y> from "Ny"
collating-element <N-Y> from "NY"

reorder-after <AFTER-D>
<d-tail>
reorder-after <AFTER-E>
<open-e>
reorder-after <AFTER-O>
<open-o>
reorder-after <AFTER-G>
<gb-digraph>
reorder-after <AFTER-{kp_after.upper()}>
<kp-digraph>
reorder-after <AFTER-{ny_after.upper()}>
<ny-digraph>

<U0256> <d-tail>;"<BASE><BASE>";"<MIN><MIN>";<U0256>
<U0189> <d-tail>;"<BASE><BASE>";"<CAP><MIN>";<U0189>
<U025B> <open-e>;"<BASE><BASE>";"<MIN><MIN>";<U025B>
<U0190> <open-e>;"<BASE><BASE>";"<CAP><MIN>";<U0190>
<U0254> <open-o>;"<BASE><BASE>";"<MIN><MIN>";<U0254>
<U0186> <open-o>;"<BASE><BASE>";"<CAP><MIN>";<U0186>
<g-b> <gb-digraph>;"<BASE><BASE>";"<MIN><MIN>";IGNORE
<g-B> <gb-digraph>;"<BASE><BASE>";"<MIN><CAP>";IGNORE
<G-b> <gb-digraph>;"<BASE><BASE>";"<CAP><MIN>";IGNORE
<G-B> <gb-digraph>;"<BASE><BASE>";"<CAP><CAP>";IGNORE
<k-p> <kp-digraph>;"<BASE><BASE>";"<MIN><MIN>";IGNORE
<k-P> <kp-digraph>;"<BASE><BASE>";"<MIN><CAP>";IGNORE
<K-p> <kp-digraph>;"<BASE><BASE>";"<CAP><MIN>";IGNORE
<K-P> <kp-digraph>;"<BASE><BASE>";"<CAP><CAP>";IGNORE
<n-y> <ny-digraph>;"<BASE><BASE>";"<MIN><MIN>";IGNORE
<n-Y> <ny-digraph>;"<BASE><BASE>";"<MIN><CAP>";IGNORE
<N-y> <ny-digraph>;"<BASE><BASE>";"<CAP><MIN>";IGNORE
<N-Y> <ny-digraph>;"<BASE><BASE>";"<CAP><CAP>";IGNORE

reorder-end
END LC_COLLATE

LC_MESSAGES
% Mots entiers uniquement (ɛɛn, eo) en plus de y/Y et n/N : pas de raccourci sur
% la lettre seule ɛ ou e, pour éviter les confusions sans clavier fon.
% À revoir quand le clavier fon sera répandu.
yesexpr "^([+1yY]|ɛɛn([^[:alpha:]]|$))"
noexpr  "^([-0nN]|eo([^[:alpha:]]|$))"
yesstr  {q(yes)}
nostr   {q(no)}
END LC_MESSAGES

LC_TIME
abday       {lst(abday)}
day         {lst(days)}
abmon       {lst(abmon)}
mon         {lst(mon)}
d_t_fmt     "%a %d %b %Y %T"
date_fmt    "%a %d %b %Y %T %Z"
d_fmt       "%d//%m//%Y"
t_fmt       "%T"
am_pm       {q(am)};{q(pm)}
t_fmt_ampm  "%I:%M:%S %p"
week        7;19971130;4
first_weekday 2
first_workday 2
END LC_TIME

LC_NUMERIC
copy "fr_BJ"
END LC_NUMERIC

LC_MONETARY
copy "fr_BJ"
END LC_MONETARY

LC_PAPER
copy "i18n"
END LC_PAPER

LC_NAME
copy "fr_FR"
END LC_NAME

LC_ADDRESS
postal_fmt    "%f%N%a%N%d%N%b%N%s %h %e %r%N%T%N%c%N"
country_name  {q(country)}
country_ab2   "BJ"
country_ab3   "BEN"
country_num   204
country_car   "DY"
country_post  "BJ"
lang_name     {q(lang)}
lang_term     "fon"
lang_lib      "fon"
END LC_ADDRESS

LC_TELEPHONE
copy "fr_BJ"
END LC_TELEPHONE

LC_MEASUREMENT
copy "i18n"
END LC_MEASUREMENT
'''
open(dst, "w", encoding="utf-8").write(out)
