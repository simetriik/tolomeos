#!/bin/sh
# Teste le détournement de base.lst (installation, mise à jour de xkb-data,
# désinstallation) et la génération de la ligne « fon », dans une racine factice.
# Usage : sh tests/test-base-lst.sh
set -eu
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/xkb-lst-update"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
A="$T/dpkg"; R="$T/root/usr/share/X11/xkb/rules"; mkdir -p "$A/info" "$R"; : > "$A/status"; : > "$A/available"
D="dpkg-divert --admindir $A --instdir $T/root"
LST=/usr/share/X11/xkb/rules/base.lst
fail=0
ok() { echo "OK   $1"; }
ko() { echo "ECHEC $1"; fail=1; }
maj() { TOLOME_XKB_LST="$R/base.lst" sh "$SCRIPT" "$1"; }
nb_fon() { grep -c '^  fon  ' "$R/base.lst" || true; }

cat > "$R/base.lst" <<'LST'
! model
  pc105           Generic 105-key PC

! layout
  fi              Finnish
  fr              French
  custom          A user-defined custom Layout

! variant
  nodeadkeys      fr: French (no dead keys)

! option
  grp             Switching to another layout
LST
cp "$R/base.lst" "$T/orig-v1"

# Installation : l'original passe en .distrib, la version de Tɔlɔmɛ est générée
$D --package tolome-keyboard-fon --add --rename --divert "$LST.distrib" "$LST" >/dev/null
[ ! -e "$R/base.lst" ] && cmp -s "$T/orig-v1" "$R/base.lst.distrib" && ok "installation : base.lst d'origine déplacé en .distrib" || ko "détournement"
cp -p "$R/base.lst.distrib" "$R/base.lst"            # filet de sécurité du preinst
maj update
[ "$(nb_fon)" = 1 ] && ok "update : la ligne fon est dans base.lst" || ko "ligne fon"
awk '/^! layout/{s=1;next} /^! /{s=0} s && /^  fon  +Fongbe/{f=1} END{exit !f}' "$R/base.lst" && ok "fon est dans la section layout, avec sa description" || ko "section layout"
cmp -s "$T/orig-v1" "$R/base.lst.distrib" && ok "le fichier d'origine (.distrib) est intact" || ko ".distrib modifié"
sed -n '/^! layout/,/^! variant/p' "$R/base.lst" | grep -A1 Finnish | tail -1 | grep -q fon && ok "fon est classé par description (après Finnish)" || ko "ordre"
for s in model variant option; do grep -q "^! $s" "$R/base.lst" || ko "section $s perdue"; done
maj update; [ "$(nb_fon)" = 1 ] && ok "update est idempotent" || ko "idempotence"

# Mise à jour de xkb-data : écrit à l'emplacement détourné, le trigger régénère
sed 's/Finnish/Finnish (v2)/' "$T/orig-v1" > "$R/base.lst.distrib"
maj update
grep -q 'Finnish (v2)' "$R/base.lst" && [ "$(nb_fon)" = 1 ] && ok "mise à jour de xkb-data : base.lst reflète la nouvelle version + fon" || ko "mise à jour"

# Désinstallation : xkb-data retrouve son base.lst (version à jour)
rm -f "$R/base.lst"
$D --package tolome-keyboard-fon --remove --rename "$LST" >/dev/null
grep -q 'Finnish (v2)' "$R/base.lst" && [ ! -e "$R/base.lst.distrib" ] && [ "$(nb_fon)" = 0 ] \
    && ok "désinstallation : xkb-data retrouve son base.lst, sans fon" || ko "retour arrière"
exit $fail
