#!/bin/sh
# Teste preinst / postinst / trigger / postrm dans une racine factice :
# installation, mise à jour de gnome-shell-common (nouveau thème d'origine), retrait.
# Usage : GDM_TEST_ORIG=/chemin/gnome-shell-theme.gresource sh tests/test-maintscripts.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${GDM_TEST_ORIG:-/usr/share/gnome-shell/gnome-shell-theme.gresource}"
[ -f "$SRC" ] || { echo "SKIP : thème d'origine introuvable ($SRC)"; exit 0; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0; ok() { echo "OK   $1"; }; ko() { echo "ECHEC $1"; fail=1; }
THEME_DIR="$T/root/usr/share/gnome-shell"
mkdir -p "$THEME_DIR" "$T/dpkg/info" "$T/etc"; : > "$T/dpkg/status"; : > "$T/dpkg/available"
python3 -I -c "from PIL import Image; Image.new('RGB',(64,36),'#101830').save('$T/fond.png')"
echo "MODE=image" > "$T/etc/conf"

# Les scripts du paquet s'exécutent tels quels, dans un espace de noms utilisateur
# (unshare) où /usr/share/gnome-shell est remplacé par un dossier temporaire et
# où dpkg-divert utilise une base temporaire (DPKG_ADMINDIR).
adapte() { sed -e "s#/usr/lib/tolome/gdm-theme-update#env TOLOME_GDM_CONF=$T/etc/conf TOLOME_GDM_IMAGE=$T/fond.png sh $ROOT/data/gdm-theme-update#" \
               -e '/#DEBHELPER#/d' "$ROOT/debian/tolome-gdm-theme.$1" > "$T/$1"; }
adapte preinst; adapte postinst; adapte postrm
enroot() { # exécute un script dans le faux environnement ; $1 = script, $2.. = arguments
    sc=$1; shift
    unshare -Urm sh -c "mount --bind '$THEME_DIR' /usr/share/gnome-shell && DPKG_ADMINDIR='$T/dpkg' sh '$sc' $*"
}
unshare -Urm true 2>/dev/null || { echo "SKIP : unshare -Urm indisponible"; exit 0; }
THEME=/usr/share/gnome-shell/gnome-shell-theme.gresource   # chemin « vu » depuis l'espace de noms

cp "$SRC" "$THEME_DIR/gnome-shell-theme.gresource"                                              # installé par gnome-shell-common
# --- installation
enroot "$T/preinst" install >/dev/null 2>&1 && [ -f "$THEME_DIR/gnome-shell-theme.gresource.distrib" ] && cmp -s "$THEME_DIR/gnome-shell-theme.gresource.distrib" "$SRC" \
    && ok "preinst : thème d'origine déplacé en .distrib" || ko "preinst"
[ -f "$THEME_DIR/gnome-shell-theme.gresource" ] && ok "preinst : le thème reste présent pendant la mise en place" || ko "thème absent après preinst"
enroot "$T/postinst" configure >/dev/null 2>&1
gresource list "$THEME_DIR/gnome-shell-theme.gresource" | grep -q tolome-gdm-background.png && ok "postinst : thème Tɔlɔmɛ généré" || ko "postinst"

# --- mise à jour de gnome-shell-common : nouveau thème d'origine écrit dans .distrib
mkdir -p "$T/nouveau"; for r in $(gresource list "$SRC"); do f="${r#/org/gnome/shell/theme/}"; mkdir -p "$T/nouveau/$(dirname "$f")"; gresource extract "$SRC" "$r" > "$T/nouveau/$f"; done
echo "nouveau" > "$T/nouveau/nouveau-fichier.txt"
( cd "$T/nouveau"; { echo '<gresources><gresource prefix="/org/gnome/shell/theme">'; find . -type f | sed 's#^\./##' | sort | sed 's#.*#<file>&</file>#'; echo '</gresource></gresources>'; } > x.xml; glib-compile-resources --sourcedir=. --target="$T/orig2" x.xml )
cp "$T/orig2" "$THEME_DIR/gnome-shell-theme.gresource.distrib"
enroot "$T/postinst" triggered >/dev/null 2>&1
gresource list "$THEME_DIR/gnome-shell-theme.gresource" | grep -q nouveau-fichier.txt && gresource list "$THEME_DIR/gnome-shell-theme.gresource" | grep -q tolome-gdm-background.png \
    && ok "trigger : le thème est régénéré depuis le NOUVEAU thème d'origine (fond conservé)" || ko "trigger"

# --- mode off puis remise
echo "MODE=off" > "$T/etc/conf"; enroot "$T/postinst" configure >/dev/null 2>&1
cmp -s "$THEME_DIR/gnome-shell-theme.gresource" "$THEME_DIR/gnome-shell-theme.gresource.distrib" && ok "mode off : thème d'origine (celui de la mise à jour)" || ko "mode off"
echo "MODE=image" > "$T/etc/conf"; enroot "$T/postinst" configure >/dev/null 2>&1

# --- retrait du paquet
enroot "$T/postrm" remove >/dev/null 2>&1
[ ! -e "$THEME_DIR/gnome-shell-theme.gresource.distrib" ] && cmp -s "$THEME_DIR/gnome-shell-theme.gresource" "$T/orig2" && ok "postrm : thème d'origine rendu à gnome-shell-common (version à jour)" || ko "postrm"
exit $fail
