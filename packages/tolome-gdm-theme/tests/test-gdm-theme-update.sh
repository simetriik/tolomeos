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
# en dehors du fond et de la carte, les feuilles de style sont identiques
for v in dark light high-contrast; do
    a=$(gresource extract "$T/orig" "$P/gnome-shell-$v.css" | wc -l); b=$(gresource extract "$T/dest" "$P/gnome-shell-$v.css" | wc -l)
    max=6; [ "$v" != "high-contrast" ] && max=40            # +22 lignes environ pour la carte
    [ "$b" -ge "$a" ] && [ $((b - a)) -le $max ] && ok "image : $v.css ne diffère que du fond et de la carte ($a -> $b lignes)" || ko "image : $v.css : $a -> $b lignes"
done

# --- carte d'utilisateur (écran de connexion) : fond translucide, sans liseré bleu
CARTE='.login-dialog-user-list-view .login-dialog-user-list .login-dialog-user-list-item'
css() { gresource extract "$T/dest" "$P/gnome-shell-$1.css"; }
bloc() { css "$1" | sed -n '/tolome-user-card/,$p'; }
for v in dark light; do
    b=$(bloc $v)
    echo "$b" | grep -qF "$CARTE {" && echo "$b" | grep -A3 -F "$CARTE {" | grep -q 'rgba(255, 255, 255, 0.08)' \
        && ok "carte ($v) : repos = rgba(255,255,255,0.08)" || ko "carte ($v) : fond au repos"
    echo "$b" | grep -A3 -F "$CARTE {" | grep -q 'border-radius: 16px' && ok "carte ($v) : coins arrondis conservés (16px)" || ko "carte ($v) : coins"
    echo "$b" | grep -A3 -F "$CARTE {" | grep -q 'box-shadow: none' && ok "carte ($v) : aucune bordure ni ombre au repos" || ko "carte ($v) : bordure au repos"
    echo "$b" | grep -A1 -F "$CARTE:hover {" | grep -q 'rgba(255, 255, 255, 0.14)' && ok "carte ($v) : survol = 0.14" || ko "carte ($v) : survol"
    echo "$b" | grep -A2 -F "$CARTE:focus," | grep -q 'rgba(255, 255, 255, 0.16)' && ok "carte ($v) : focus/sélection = 0.16" || ko "carte ($v) : focus"
    echo "$b" | grep -A3 -F "$CARTE:selected," | grep -q 'inset 0 0 0 1px rgba(255, 255, 255, 0.35) !important' && ok "carte ($v) : contour fin rgba(255,255,255,0.35) en !important" || ko "carte ($v) : contour"
    echo "$b" | grep -qi 'accent' && ko "carte ($v) : couleur d'accent encore présente dans notre bloc" || ok "carte ($v) : plus de bleu d'accent dans notre bloc"
    [ "$(css $v | grep -c tolome-user-card)" -eq 1 ] && ok "carte ($v) : bloc présent une seule fois" || ko "carte ($v) : bloc en double ou absent"
    # la dernière règle gagne : les règles d'origine du sélecteur précèdent notre bloc, qui clôt la feuille
    first=$(css $v | grep -n 'tolome-user-card' | cut -d: -f1); total=$(css $v | wc -l)
    avant=$(css $v | head -n $((first - 1)) | grep -c -F "$CARTE:focus")
    [ "$avant" -ge 1 ] && [ $((total - first)) -le 25 ] && ok "carte ($v) : $avant règle(s) d'origine avant la nôtre, qui est la dernière de la feuille" || ko "carte ($v) : ordre"
done
[ "$(css high-contrast | grep -c tolome-user-card)" -eq 0 ] && ok "carte : contraste élevé inchangé (accessibilité)" || ko "carte : contraste élevé modifié"
# syntaxe CSS vérifiée par l'analyseur de GTK 4 (qui ne connaît pas !important, propre à St)
if command -v gjs >/dev/null 2>&1; then
    bloc dark | sed 's/ !important//' > "$T/bloc.css"
    cat > "$T/parse.js" <<'JS'
imports.gi.versions.Gtk = '4.0';
const {Gtk, GLib} = imports.gi;
Gtk.init();
const p = new Gtk.CssProvider(); let errs = 0;
p.connect('parsing-error', () => { errs++; });
p.load_from_string(new TextDecoder().decode(GLib.file_get_contents(ARGV[0])[1]));
print('ERRS=' + errs);
JS
    [ "$(gjs "$T/parse.js" "$T/bloc.css" 2>/dev/null | grep ERRS)" = "ERRS=0" ] && ok "carte : syntaxe CSS valide (analyseur GTK 4)" || ko "carte : syntaxe CSS"
else
    echo "SKIP : gjs absent (syntaxe CSS non vérifiée)"
fi

# --- idempotence : relancer ne change rien
cp "$T/dest" "$T/avant"; run
cmp -s "$T/avant" "$T/dest" && ok "idempotence : second passage identique" || { n2=$(gresource list "$T/dest" | wc -l); [ "$n2" = "$n1" ] && ok "idempotence : même contenu ($n2 ressources)" || ko "idempotence"; }

# --- mode flat
echo "MODE=flat" > "$T/conf"; run
n=$(gresource list "$T/dest" | wc -l)
[ "$n" -eq "$n0" ] && ok "flat : $n ressources (pas d'image)" || ko "flat : $n ressources"
gresource extract "$T/dest" "$P/gnome-shell-dark.css" | grep -A2 '^#lockDialogGroup' | grep -q 'background-color: #23325E' && ok "flat : aplat indigo" || ko "flat : règle"
gresource extract "$T/dest" "$P/gnome-shell-dark.css" | grep -A3 '^#lockDialogGroup' | grep -q 'background-image' && ko "flat : image présente" || ok "flat : aucune image"
[ "$(css dark | grep -c tolome-user-card)" -eq 1 ] && ok "flat : la carte translucide est appliquée" || ko "flat : carte absente"

# --- image absente => repli flat
echo "MODE=image" > "$T/conf"; mv "$T/fond.png" "$T/fond.bak"; run
grep -q 'repli sur' "$T/log" && [ "$(gresource list "$T/dest" | wc -l)" -eq "$n0" ] && ok "image absente : repli sur l'aplat indigo" || ko "image absente"
mv "$T/fond.bak" "$T/fond.png"

# --- mode off => thème d'origine
echo "MODE=off" > "$T/conf"; run
cmp -s "$T/orig" "$T/dest" && ok "off : thème d'origine rétabli (octet pour octet)" || ko "off"
[ "$(css dark | grep -c tolome-user-card)" -eq 0 ] && ok "off : aucune carte translucide (carte GNOME d'origine)" || ko "off : carte présente"

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
