#!/bin/sh
# Teste data/gdm-theme-update sur un vrai thème GNOME Shell (gresource).
# Usage : GDM_TEST_ORIG=/chemin/gnome-shell-theme.gresource sh tests/test-gdm-theme-update.sh
# (par défaut : /usr/share/gnome-shell/gnome-shell-theme.gresource de la machine)
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/data/gdm-theme-update"
SRC="${GDM_TEST_ORIG:-/usr/share/gnome-shell/gnome-shell-theme.gresource}"
[ -f "$SRC" ] || { echo "SKIP : thème d'origine introuvable ($SRC)"; exit 0; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0
P=/org/gnome/shell/theme
ok() { echo "OK   $1"; }
ko() { echo "ECHEC $1"; fail=1; }

cp "$SRC" "$T/orig"; cp "$SRC" "$T/dest"                      # dest = état après détournement (copie)
python3 -I -c "
from PIL import Image; Image.new('RGB',(64,36),'#101830').save('$T/fond.png')" 2>/dev/null || \
    cp "$ROOT/artwork/tolome-fond-ganvie.svg" "$T/fond.png"
export TOLOME_GDM_ORIG="$T/orig" TOLOME_GDM_DEST="$T/dest" TOLOME_GDM_CONF="$T/conf" TOLOME_GDM_IMAGE="$T/fond.png"
run() { sh "$SCRIPT" 2>"$T/log"; }

# --- mode image
echo "MODE=image" > "$T/conf"; run
n0=$(gresource list "$T/orig" | wc -l); n1=$(gresource list "$T/dest" | wc -l)
[ "$n1" -eq $((n0 + 1)) ] && ok "image : $n1 ressources (= $n0 d'origine + le fond)" || ko "image : $n1 ressources au lieu de $((n0 + 1))"
gresource list "$T/dest" | grep -q "$P/tolome-gdm-background.png" && ok "image : le fond est dans le thème" || ko "image : fond absent"
for v in dark light high-contrast; do
    gresource extract "$T/dest" "$P/gnome-shell-$v.css" | grep -A5 '^#lockDialogGroup' | grep -q 'tolome-gdm-background.png' \
        && ok "image : règle du fond dans gnome-shell-$v.css" || ko "image : règle absente de $v"
done
gresource extract "$T/dest" "$P/gnome-shell-dark.css" | grep -A6 '^#lockDialogGroup'
# les autres ressources sont identiques à l'original
diffs=0
for r in $(gresource list "$T/orig"); do
    case "$r" in */gnome-shell-dark.css|*/gnome-shell-light.css|*/gnome-shell-high-contrast.css) continue ;; esac
    gresource extract "$T/orig" "$r" > "$T/a"; gresource extract "$T/dest" "$r" > "$T/b"
    cmp -s "$T/a" "$T/b" || { diffs=$((diffs + 1)); echo "  différence : $r"; }
done
[ "$diffs" -eq 0 ] && ok "image : les autres ressources sont identiques à l'original" || ko "image : $diffs ressource(s) modifiée(s)"
# en dehors de la règle, les feuilles de style sont identiques
for v in dark light high-contrast; do
    gresource extract "$T/orig" "$P/gnome-shell-$v.css" | grep -v -A1 '^#lockDialogGroup' > /dev/null
    a=$(gresource extract "$T/orig" "$P/gnome-shell-$v.css" | wc -l); b=$(gresource extract "$T/dest" "$P/gnome-shell-$v.css" | wc -l)
    [ "$b" -ge "$a" ] && [ $((b - a)) -le 6 ] && ok "image : $v.css ne diffère que de la règle ($a -> $b lignes)" || ko "image : $v.css : $a -> $b lignes"
done

# --- idempotence : relancer ne change rien
cp "$T/dest" "$T/avant"; run
cmp -s "$T/avant" "$T/dest" && ok "idempotence : second passage identique" || { n2=$(gresource list "$T/dest" | wc -l); [ "$n2" = "$n1" ] && ok "idempotence : même contenu ($n2 ressources)" || ko "idempotence"; }

# --- mode flat
echo "MODE=flat" > "$T/conf"; run
n=$(gresource list "$T/dest" | wc -l)
[ "$n" -eq "$n0" ] && ok "flat : $n ressources (pas d'image)" || ko "flat : $n ressources"
gresource extract "$T/dest" "$P/gnome-shell-dark.css" | grep -A2 '^#lockDialogGroup' | grep -q 'background-color: #23325E' && ok "flat : aplat indigo" || ko "flat : règle"
gresource extract "$T/dest" "$P/gnome-shell-dark.css" | grep -A3 '^#lockDialogGroup' | grep -q 'background-image' && ko "flat : image présente" || ok "flat : aucune image"

# --- image absente => repli flat
echo "MODE=image" > "$T/conf"; mv "$T/fond.png" "$T/fond.bak"; run
grep -q 'repli sur' "$T/log" && [ "$(gresource list "$T/dest" | wc -l)" -eq "$n0" ] && ok "image absente : repli sur l'aplat indigo" || ko "image absente"
mv "$T/fond.bak" "$T/fond.png"

# --- mode off => thème d'origine
echo "MODE=off" > "$T/conf"; run
cmp -s "$T/orig" "$T/dest" && ok "off : thème d'origine rétabli (octet pour octet)" || ko "off"

# --- mode inconnu => off
echo "MODE=zzz" > "$T/conf"; run
cmp -s "$T/orig" "$T/dest" && ok "mode inconnu : thème d'origine" || ko "mode inconnu"

# --- thème d'origine illisible => la destination retrouve l'original sain
echo "MODE=image" > "$T/conf"; cp "$SRC" "$T/orig"; sh "$SCRIPT" 2>/dev/null; echo "xxxx" > "$T/dest"
echo "pas un gresource" > "$T/orig"; run
[ -f "$T/dest" ] && ok "original corrompu : aucune erreur fatale (sortie 0)" || ko "original corrompu"
cp "$SRC" "$T/orig"

# --- outil manquant (glib-compile-resources) => thème d'origine conservé
mkdir "$T/bin"; for b in gresource sed sh cp mv rm mkdir mktemp cat grep wc find sort dirname logger; do p=$(command -v $b) && ln -s "$p" "$T/bin/$b"; done
cp "$SRC" "$T/dest"; echo "MODE=image" > "$T/conf"
PATH="$T/bin" sh "$SCRIPT" 2>"$T/log"
grep -q 'outil manquant' "$T/log" && cmp -s "$T/orig" "$T/dest" && ok "outil manquant : thème d'origine conservé" || ko "outil manquant"

exit $fail
