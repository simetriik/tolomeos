#!/bin/bash
# Teste la locale fr_BJ : compilation, contenu (monétaire, numérique, temps, téléphone,
# adresse, papier, mesures), parité avec fr_FR et apparition dans « locale -a ».
# Usage : bash tests/test-fr_BJ.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/locales-update"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0; ok() { echo "OK   $1"; }; ko() { echo "ECHEC $1"; fail=1; }
nnbsp=$' '; nbsp=$' '

mkdir -p "$T/loc"
TOLOME_I18N_DIR="$ROOT/i18n" TOLOME_LOCALE_DIR="$T/loc" sh "$SCRIPT" compile 2>"$T/err"
[ -f "$T/loc/fr_BJ.utf8/LC_MONETARY" ] && [ -f "$T/loc/fr_BJ.utf8/.tolome-locales" ] \
    && ok "compilation : dossier fr_BJ.utf8 (12 catégories + témoin)" || { ko "compilation ($(cat "$T/err"))"; exit 1; }
n=$(ls "$T/loc/fr_BJ.utf8" | grep -c '^LC_'); [ "$n" -eq 12 ] && ok "12 catégories LC_* présentes" || ko "catégories : $n"
export LOCPATH="$T/loc"
k() { LC_ALL=fr_BJ.UTF-8 locale -k "$@" 2>/dev/null; }
val() { k "$2" | grep -m1 "^$1=" | sed -E 's/^[^=]+=//; s/^"//; s/"$//'; }
eq() { # nom ; obtenu ; attendu
    if [ "$2" = "$3" ]; then ok "$1 = $(printf '%s' "$3" | sed "s/$nnbsp/<NNBSP>/g;s/$nbsp/<NBSP>/g")"; else ko "$1 : obtenu '$2' attendu '$3'"; fi
}

# --- identification
eq "title"          "$(val title LC_IDENTIFICATION)"      "French locale for Benin"
eq "territory"      "$(val territory LC_IDENTIFICATION)"  "Benin"
eq "language"       "$(val language LC_IDENTIFICATION)"   "French"
eq "source"         "$(val source LC_IDENTIFICATION)"     "Tɔlɔmɛ"
# --- monétaire
eq "int_curr_symbol"   "$(val int_curr_symbol LC_MONETARY)"   "XOF "
eq "currency_symbol"   "$(val currency_symbol LC_MONETARY)"   "${nbsp}F${nnbsp}CFA"
eq "frac_digits"       "$(val frac_digits LC_MONETARY)"       "0"
eq "int_frac_digits"   "$(val int_frac_digits LC_MONETARY)"   "0"
eq "mon_decimal_point" "$(val mon_decimal_point LC_MONETARY)" ","
eq "mon_thousands_sep" "$(val mon_thousands_sep LC_MONETARY)" "$nnbsp"
eq "p_cs_precedes (symbole après le montant)" "$(val p_cs_precedes LC_MONETARY)" "0"
eq "int_p_sep_by_space" "$(val int_p_sep_by_space LC_MONETARY)" "1"
eq "int_n_sep_by_space" "$(val int_n_sep_by_space LC_MONETARY)" "1"
# --- numérique
eq "decimal_point"  "$(val decimal_point LC_NUMERIC)" ","
eq "thousands_sep"  "$(val thousands_sep LC_NUMERIC)" "$nnbsp"
# --- téléphone
eq "tel_int_fmt"  "$(val tel_int_fmt LC_TELEPHONE)" "+%c %l"
eq "tel_dom_fmt"  "$(val tel_dom_fmt LC_TELEPHONE)" "%l"
eq "int_prefix"   "$(val int_prefix LC_TELEPHONE)"  "229"
eq "int_select"   "$(val int_select LC_TELEPHONE)"  "00"
# --- adresse
eq "country_name" "$(val country_name LC_ADDRESS)" "Bénin"
eq "country_ab2"  "$(val country_ab2 LC_ADDRESS)"  "BJ"
eq "country_ab3"  "$(val country_ab3 LC_ADDRESS)"  "BEN"
eq "country_num"  "$(val country_num LC_ADDRESS)"  "204"
eq "country_car"  "$(val country_car LC_ADDRESS)"  "DY"
eq "lang_name"    "$(val lang_name LC_ADDRESS)"    "français"
[ -z "$(val country_isbn LC_ADDRESS)" ] && ok "country_isbn absent" || ko "country_isbn présent"
case "$(val postal_fmt LC_ADDRESS)" in *%z*) ko "postal_fmt contient %z (code postal)" ;; *) ok "postal_fmt sans code postal (%z)" ;; esac
# --- papier, mesures, semaine
eq "papier : hauteur" "$(val height LC_PAPER)" "297"
eq "papier : largeur" "$(val width LC_PAPER)"  "210"
eq "mesures (1 = métrique)" "$(val measurement LC_MEASUREMENT)" "1"
eq "premier jour de la semaine (2 = lundi)" "$(LC_ALL=fr_BJ.UTF-8 locale first_weekday 2>/dev/null)" "2"
eq "jours de la semaine ISO (week-ndays)" "$(val week-ndays LC_TIME)" "7"

# --- parité avec fr_FR pour les catégories copiées
for cat in LC_TIME LC_NUMERIC LC_MESSAGES LC_NAME LC_CTYPE; do
    a=$(LC_ALL=fr_BJ.UTF-8 locale -k $cat 2>/dev/null | md5sum); b=$(LC_ALL=fr_FR.UTF-8 locale -k $cat 2>/dev/null | md5sum)
    [ "$a" = "$b" ] && ok "$cat identique à fr_FR" || ko "$cat diffère de fr_FR"
done

# --- date
eq "date (%A %d %B %Y)" "$(LC_ALL=fr_BJ.UTF-8 date -d '2026-11-03 14:05:09' '+%A %d %B %Y')" "mardi 03 novembre 2026"
eq "date (%x)" "$(LC_ALL=fr_BJ.UTF-8 date -d '2026-11-03 14:05:09' '+%x')" "03/11/2026"
eq "heure (%X)" "$(LC_ALL=fr_BJ.UTF-8 date -d '2026-11-03 14:05:09' '+%X')" "14:05:09"
eq "mois (%b)" "$(LC_ALL=fr_BJ.UTF-8 date -d '2026-02-03' '+%b')" "$(LC_ALL=fr_FR.UTF-8 date -d '2026-02-03' '+%b')"

# --- printf "%'d" (bash)
eq "printf \"%'d\" 1234567"    "$(LC_ALL=fr_BJ.UTF-8 bash -c "printf \"%'d\" 1234567")" "1${nnbsp}234${nnbsp}567"
eq "printf \"%'d\" 999"        "$(LC_ALL=fr_BJ.UTF-8 bash -c "printf \"%'d\" 999")" "999"
eq "printf \"%'.2f\" 1234,5 (virgule décimale)"   "$(LC_ALL=fr_BJ.UTF-8 bash -c "printf \"%'.2f\" 1234,5")" "1${nnbsp}234,50"
eq "printf \"%'d\" 25000"      "$(LC_ALL=fr_BJ.UTF-8 bash -c "printf \"%'d\" 25000")" "25${nnbsp}000"

# --- LC_MONETARY réel (strfmon via Python)
mon() { LC_ALL=fr_BJ.UTF-8 python3 -I -c "
import locale,sys; locale.setlocale(locale.LC_ALL,'')
print(locale.currency($1, grouping=True, international=$2), end='')"; }
eq "monnaie 25000"        "$(mon 25000 False)"    "25${nnbsp}000${nbsp}F${nnbsp}CFA"
eq "monnaie 1234567"      "$(mon 1234567 False)"  "1${nnbsp}234${nnbsp}567${nbsp}F${nnbsp}CFA"
eq "monnaie -25000"       "$(mon -25000 False)"   "-25${nnbsp}000${nbsp}F${nnbsp}CFA"
eq "monnaie 0"            "$(mon 0 False)"        "0${nbsp}F${nnbsp}CFA"
eq "monnaie 500 (sans décimales)" "$(mon 500.4 False)" "500${nbsp}F${nnbsp}CFA"
# strfmon (fonction C de la glibc, via ctypes) : %n = format national, %i = international
sfm() { LC_ALL=fr_BJ.UTF-8 python3 -I -c "
import ctypes, locale
locale.setlocale(locale.LC_ALL, '')
libc = ctypes.CDLL(None); libc.strfmon.restype = ctypes.c_ssize_t
buf = ctypes.create_string_buffer(128)
n = libc.strfmon(buf, 128, b'$1', ctypes.c_double($2))
print(buf.raw[:n].decode('utf-8'), end='')"; }
eq "strfmon %n 25000 (national)"      "$(sfm '%n' 25000)"    "25${nnbsp}000${nbsp}F${nnbsp}CFA"
eq "strfmon %n -25000"                "$(sfm '%n' -25000)"   "-25${nnbsp}000${nbsp}F${nnbsp}CFA"
eq "strfmon %i 25000 (international)" "$(sfm '%i' 25000)"    "25${nnbsp}000 XOF"
eq "strfmon %i -25000"                "$(sfm '%i' -25000)"   "-25${nnbsp}000 XOF"
eq "strfmon %n 1234567,4 (arrondi à 0 décimale)" "$(sfm '%n' 1234567.4)" "1${nnbsp}234${nnbsp}567${nbsp}F${nnbsp}CFA"

# --- locale -a : fr_BJ.utf8 apparaît (overlay de /usr/lib/locale dans un espace de noms utilisateur)
if unshare -Urm true 2>/dev/null; then
    unset LOCPATH
    la=$(unshare -Urm sh -c "mount -t overlay overlay -o lowerdir='$T/loc':/usr/lib/locale /usr/lib/locale && locale -a" 2>/dev/null)
    echo "$la" | grep -qx 'fr_BJ.utf8' && ok "locale -a liste fr_BJ.utf8" || ko "locale -a : fr_BJ.utf8 absente"
    echo "$la" | grep -qx 'fr_FR.utf8' && ok "locale -a liste toujours fr_FR.utf8" || ko "locale -a : fr_FR.utf8 absente"
    cur=$(unshare -Urm sh -c "mount -t overlay overlay -o lowerdir='$T/loc':/usr/lib/locale /usr/lib/locale && LC_ALL=fr_BJ.UTF-8 locale charmap && LC_ALL=fr_BJ.UTF-8 python3 -I -c 'import locale; print(locale.setlocale(locale.LC_ALL,\"\"))'" 2>&1 | tr '\n' ' ')
    [ "$cur" = "UTF-8 fr_BJ.UTF-8 " ] && ok "setlocale(fr_BJ.UTF-8) fonctionne (charmap UTF-8)" || ko "setlocale : $cur"
else
    echo "SKIP : unshare -Urm indisponible (locale -a non testé)"
fi
exit $fail
