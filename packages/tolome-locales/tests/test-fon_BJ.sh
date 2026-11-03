#!/bin/bash
# Teste la locale fon_BJ : compilation, jours/mois, 24 h et am_pm, oui/non, langue et pays,
# tri (alphabet à 31 lettres), parité avec fr_BJ (monnaie, nombres, téléphone), locale -a.
# Usage : bash tests/test-fon_BJ.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/locales-update"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0; ok() { echo "OK   $1"; }; ko() { echo "ECHEC $1"; fail=1; }
nnbsp=$'\u202f'; nbsp=$'\u00a0'

mkdir -p "$T/loc"
TOLOME_I18N_DIR="$ROOT/i18n" TOLOME_LOCALE_DIR="$T/loc" sh "$SCRIPT" compile 2>"$T/err"
[ -f "$T/loc/fon_BJ.utf8/LC_TIME" ] && [ -f "$T/loc/fon_BJ.utf8/.tolome-locales" ] \
    && ok "compilation : dossier fon_BJ.utf8 (+ témoin)" || { ko "compilation ($(cat "$T/err"))"; exit 1; }
grep -qiE 'warning|avertissement|erreur|error' "$T/err" && ko "avertissements à la compilation : $(grep -iE 'warning|avertissement|erreur|error' "$T/err" | head -2)" || ok "compilation sans avertissement"
n=$(ls "$T/loc/fon_BJ.utf8" | grep -c '^LC_'); [ "$n" -eq 12 ] && ok "12 catégories LC_* présentes" || ko "catégories : $n"
export LOCPATH="$T/loc"
L() { LC_ALL=fon_BJ.UTF-8 "$@"; }
val() { L locale -k "$2" 2>/dev/null | grep -m1 "^$1=" | sed -E 's/^[^=]+=//; s/^"//; s/"$//'; }
eq() { if [ "$2" = "$3" ]; then ok "$1 = $(printf '%s' "$3" | sed "s/$nnbsp/<NNBSP>/g;s/$nbsp/<NBSP>/g")"; else ko "$1 : obtenu '$2' attendu '$3'"; fi; }

# --- identification et adresse
eq "title"        "$(val title LC_IDENTIFICATION)"     "Fon locale for Benin"
eq "language"     "$(val language LC_IDENTIFICATION)"  "Fon"
eq "territory"    "$(val territory LC_IDENTIFICATION)" "Benin"
eq "lang_name"    "$(val lang_name LC_ADDRESS)"        "Fɔngbè"
eq "lang_term"    "$(val lang_term LC_ADDRESS)"        "fon"
eq "country_name" "$(val country_name LC_ADDRESS)"     "Benɛn"
eq "country_ab2"  "$(val country_ab2 LC_ADDRESS)"      "BJ"
eq "country_ab3"  "$(val country_ab3 LC_ADDRESS)"      "BEN"
eq "country_num"  "$(val country_num LC_ADDRESS)"      "204"

# --- jours, mois (glibc : dimanche en premier)
eq "day"    "$(L locale day | tr -d '\n')"   "Vodungbe;Tɛnigbe;Taatagbe;Azangagbe;Nyɔnuzangbe;Axɔsuzangbe;Sibigbe"
eq "abday"  "$(L locale abday | tr -d '\n')" "vod.;tɛn.;taa.;aza.;nyɔ.;axɔ.;sib."
eq "mon"    "$(L locale mon | tr -d '\n')"   "Aluunsun;Zofinkplɔsun;Xwejisun;Lidosun;Nuxwasun;Ayidosun;Liyasun;Avuvɔsun;Zosun;Kɔnyasun;Abɔxwisun;Woosun"
eq "abmon"  "$(L locale abmon | tr -d '\n')" "alu.;zof.;xwe.;lid.;nux.;ayi.;liy.;avu.;zos.;kɔn.;abɔ.;woo."
eq "premier jour (2 = lundi)" "$(L locale first_weekday)" "2"
d=2026-11-02; names=""; for i in 0 1 2 3 4 5 6; do names="$names$(L date -d "$d +$i day" '+%A') "; done
eq "semaine du lundi 2 au dimanche 8 nov. 2026" "$names" "Tɛnigbe Taatagbe Azangagbe Nyɔnuzangbe Axɔsuzangbe Sibigbe Vodungbe "
m=""; for i in 01 02 03 04 05 06 07 08 09 10 11 12; do m="$m$(L date -d "2026-$i-15" '+%b') "; done
eq "12 mois abrégés" "$m" "alu. zof. xwe. lid. nux. ayi. liy. avu. zos. kɔn. abɔ. woo. "
eq "date (%A %d %B %Y)" "$(L date -d '2026-11-03 14:05:09' '+%A %d %B %Y')" "Taatagbe 03 Abɔxwisun 2026"
eq "date (%x)"          "$(L date -d '2026-11-03 14:05:09' '+%x')" "03/11/2026"

# --- 24 h par défaut ; am_pm
eq "heure par défaut (%X, 24 h)" "$(L date -d '2026-11-03 14:05:09' '+%X')" "14:05:09"
eq "am_pm"           "$(L locale am_pm | tr -d '\n')" "zanzan;xwelɛkɔ"
eq "%p avant midi"   "$(L date -d '2026-11-03 09:05' '+%p')" "zanzan"
eq "%p après midi"   "$(L date -d '2026-11-03 15:05' '+%p')" "xwelɛkɔ"
eq "%r (12 h)"       "$(L date -d '2026-11-03 15:05:09' '+%r')" "03:05:09 xwelɛkɔ"

# --- oui / non
eq "yesstr" "$(L locale yesstr)" "ɛɛn"
eq "nostr"  "$(L locale nostr)"  "eo"
yn() { # mot -> oui|non|? selon yesexpr/noexpr (regex de la glibc, via grep dans la locale)
    if printf '%s\n' "$1" | LC_ALL=fon_BJ.UTF-8 grep -qE "$(L locale yesexpr)"; then echo oui
    elif printf '%s\n' "$1" | LC_ALL=fon_BJ.UTF-8 grep -qE "$(L locale noexpr)"; then echo non
    else echo "?"; fi; }
for w in "ɛɛn:oui" "y:oui" "Y:oui" "+:oui" "1:oui" "eo:non" "n:non" "N:non" "0:non" "-:non" \
         "ɛ:?" "e:?" "E:?" "Ɛ:?" "ɛɛnx:?" "eoz:?" "ɛɛn bien:oui" "x:?"; do
    eq "oui/non « ${w%%:*} »" "$(yn "${w%%:*}")" "${w##*:}"
done

# --- tri : alphabet à 31 lettres  a b c d ɖ e ɛ f g gb h i j k l m n o ɔ p kp r s t u v w x y ny z
alpha="a b c d ɖ e ɛ f g gb h i j k l m n o ɔ p kp r s t u v w x y ny z"
tri() { printf '%s\n' "$@" | LC_ALL=fon_BJ.UTF-8 sort | paste -sd' '; }
eq "alphabet complet (31 lettres)" "$(echo "$alpha" | wc -w)" "31"
mel=$(printf '%sa\n' $alpha | sort -R | tr '\n' ' ')            # mélangé
eq "tri de l'alphabet (31 lettres + a)" "$(tri $mel | sed 's/a\b//g')" "$alpha"
eq "g < gb < h"        "$(tri gz gba gh hoo ga)"        "ga gh gz gba hoo"
eq "k < kp ; kp après p" "$(tri kz kpa pz pa ra kl)"   "kl kz pa pz kpa ra"
eq "n < ny ; ny après y" "$(tri nz nya yz ya za xz)"   "nz xz ya yz nya za"
eq "x < y < ny < z"    "$(tri za nya ya xa)"            "xa ya nya za"
eq "ɖ après d"         "$(tri ea ɖa da db)"             "da db ɖa ea"
eq "ɛ après e"         "$(tri fa ɛa ea eb)"             "ea eb ɛa fa"
eq "ɔ après o"         "$(tri pa ɔa oa ob)"             "oa ob ɔa pa"
eq "majuscules (Gb, GB, Kp, Ny)" "$(tri Gba gba GBA Kpa kpa Nya nya | sed 's/ /\n/g' | tr 'A-Z' 'a-z' | paste -sd' ')" "gba gba gba kpa kpa nya nya"
eq "tons (signes combinants) au 2e niveau" "$(tri ɛ́b ɛa)" "ɛa ɛ́b"
eq "lettres ɖ ɛ ɔ : classe alpha et casse" "$(L python3 -I -c "import locale; locale.setlocale(locale.LC_ALL,''); print(all(c.isalpha() for c in 'ɖɛɔ') and 'ɖɛɔ'.upper()=='ƉƐƆ')")" "True"

# --- parité avec fr_BJ (monnaie, nombres, téléphone)
for cat in LC_MONETARY LC_NUMERIC LC_TELEPHONE; do
    a=$(LC_ALL=fon_BJ.UTF-8 locale -k $cat 2>/dev/null | md5sum); b=$(LC_ALL=fr_BJ.UTF-8 locale -k $cat 2>/dev/null | md5sum)
    [ "$a" = "$b" ] && ok "$cat identique à fr_BJ" || ko "$cat diffère de fr_BJ"
done
eq "printf \"%'d\" 1234567" "$(L bash -c "printf \"%'d\" 1234567")" "1${nnbsp}234${nnbsp}567"
eq "monnaie 25000" "$(L python3 -I -c "
import locale; locale.setlocale(locale.LC_ALL,''); print(locale.currency(25000, grouping=True), end='')")" "25${nnbsp}000${nbsp}F${nnbsp}CFA"

# --- locale -a (overlay de /usr/lib/locale dans un espace de noms utilisateur)
if unshare -Urm true 2>/dev/null; then
    unset LOCPATH
    la=$(unshare -Urm sh -c "mount -t overlay overlay -o lowerdir='$T/loc':/usr/lib/locale /usr/lib/locale && locale -a" 2>/dev/null)
    echo "$la" | grep -qx 'fon_BJ.utf8' && ok "locale -a liste fon_BJ.utf8" || ko "locale -a : fon_BJ.utf8 absente"
    echo "$la" | grep -qx 'fr_FR.utf8' && ok "locale -a liste toujours fr_FR.utf8" || ko "locale -a : fr_FR.utf8 absente"
else
    echo "SKIP : unshare -Urm indisponible (locale -a non testé)"
fi
exit $fail
