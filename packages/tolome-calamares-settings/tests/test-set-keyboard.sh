#!/bin/sh
# Teste data/scripts/set-keyboard sur plusieurs cas, dans un dossier temporaire.
# Usage : sh tests/test-set-keyboard.sh
set -u
SCRIPT="$(dirname "$0")/../data/scripts/set-keyboard"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0

run() { # nom ; contenu du fichier clavier (stdin) ; attendu (XKBLAYOUT XKBVARIANT XKBOPTIONS)
    name=$1; exp_l=$2; exp_v=$3; exp_o=$4
    cat > "$T/keyboard"
    printf '[org/gnome/desktop/input-sources]\nsources=[(%s)]\n\n[org/gnome/system/location]\nenabled=false\n' "'xkb', 'fon'" > "$T/dconf"
    TOLOME_KEYBOARD_FILE="$T/keyboard" TOLOME_DCONF_FILE="$T/dconf" TOLOME_NO_DCONF_UPDATE=1 sh "$SCRIPT"
    ( . "$T/keyboard"
      if [ "$XKBLAYOUT" = "$exp_l" ] && [ "$XKBVARIANT" = "$exp_v" ] && [ "$XKBOPTIONS" = "$exp_o" ]; then
          echo "OK   $name -> $XKBLAYOUT / '$XKBVARIANT' / '$XKBOPTIONS'"
      else
          echo "ECHEC $name : $XKBLAYOUT / '$XKBVARIANT' / '$XKBOPTIONS' (attendu $exp_l / '$exp_v' / '$exp_o')"; exit 1
      fi ) || fail=1
    # le dconf ne doit plus contenir les sources, mais garder la localisation
    if grep -q input-sources "$T/dconf" || ! grep -q 'enabled=false' "$T/dconf"; then
        echo "ECHEC $name : base dconf incorrecte"; fail=1
    fi
}

printf 'XKBMODEL="pc105"\nXKBLAYOUT="fr"\nXKBVARIANT=""\nXKBOPTIONS=""\n' | \
    run "French"                  "fr,fon"  ","       "grp:alt_shift_toggle"
printf 'XKBMODEL="pc105"\nXKBLAYOUT="fr"\nXKBVARIANT="latin9"\nXKBOPTIONS=""\n' | \
    run "French (variante)"       "fr,fon"  "latin9," "grp:alt_shift_toggle"
printf 'XKBMODEL="pc105"\nXKBLAYOUT="de"\nXKBVARIANT=""\nXKBOPTIONS=""\n' | \
    run "German"                  "de,fon"  ","       "grp:alt_shift_toggle"
printf 'XKBMODEL="pc105"\nXKBLAYOUT="be"\nXKBVARIANT="oss"\nXKBOPTIONS="terminate:ctrl_alt_bksp"\n' | \
    run "Belgian + options"       "be,fon"  "oss,"    "terminate:ctrl_alt_bksp,grp:alt_shift_toggle"
printf 'XKBMODEL="pc105"\nXKBLAYOUT="us"\nXKBVARIANT=""\nXKBOPTIONS=""\n' | \
    run "US (choix explicite)"    "us,fon"  ","       "grp:alt_shift_toggle"
printf 'XKBMODEL="pc105"\nXKBLAYOUT="fon"\nXKBVARIANT=""\nXKBOPTIONS=""\n' | \
    run "fon (futur)"             "fon,fr"  ","       "grp:alt_shift_toggle"
printf 'XKBMODEL="pc105"\nXKBLAYOUT="fr"\nXKBVARIANT=""\nXKBOPTIONS="grp:alt_shift_toggle"\n' | \
    run "option déjà présente"    "fr,fon"  ","       "grp:alt_shift_toggle"
printf '' | run "fichier vide"    "us,fon"  ","       "grp:alt_shift_toggle"

# Plusieurs dispositions déjà écrites : fichier laissé tel quel
printf 'XKBLAYOUT="fr,de"\nXKBVARIANT=","\nXKBOPTIONS=""\n' > "$T/keyboard"
cp "$T/keyboard" "$T/keyboard.ref"
TOLOME_KEYBOARD_FILE="$T/keyboard" TOLOME_DCONF_FILE="$T/none" TOLOME_NO_DCONF_UPDATE=1 sh "$SCRIPT"
if cmp -s "$T/keyboard" "$T/keyboard.ref"; then echo "OK   plusieurs dispositions -> inchangé"; else echo "ECHEC plusieurs dispositions"; fail=1; fi

exit $fail
