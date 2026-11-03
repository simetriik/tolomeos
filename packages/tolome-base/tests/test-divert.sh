#!/bin/sh
# Teste la séquence de détournement de .face (installation, mise à jour de
# desktop-base, désinstallation) dans une racine factice. Usage : sh tests/test-divert.sh
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
A="$T/dpkg"; mkdir -p "$A/info" "$T/root/etc/skel"; : > "$A/status"; : > "$A/available"
D="dpkg-divert --admindir $A --instdir $T/root"
fail=0
ok() { echo "OK   $1"; }
ko() { echo "ECHEC $1"; fail=1; }

echo "SPIRALE-DEBIAN" > "$T/root/etc/skel/.face"                 # installé par desktop-base

$D --package tolome-base --add --rename --divert /etc/skel/.face.distrib /etc/skel/.face >/dev/null
[ ! -e "$T/root/etc/skel/.face" ] && [ "$(cat "$T/root/etc/skel/.face.distrib")" = "SPIRALE-DEBIAN" ] \
    && ok "installation : l'original est déplacé en .face.distrib" || ko "détournement"
echo "BAOBAB" > "$T/root/etc/skel/.face"                          # déballé par tolome-base
[ "$(cat "$T/root/etc/skel/.face")" = "BAOBAB" ] && ok "le fichier de tolome-base occupe .face" || ko "fichier tolome"

echo "SPIRALE-V2" > "$T/root/etc/skel/.face.distrib"             # mise à jour de desktop-base (écrit à l'emplacement détourné)
[ "$(cat "$T/root/etc/skel/.face")" = "BAOBAB" ] && ok "mise à jour de desktop-base : .face n'est pas écrasé" || ko "mise à jour"

rm -f "$T/root/etc/skel/.face"                                    # désinstallation (dpkg retire le fichier du paquet)
$D --package tolome-base --remove --rename /etc/skel/.face >/dev/null
[ "$(cat "$T/root/etc/skel/.face")" = "SPIRALE-V2" ] && [ ! -e "$T/root/etc/skel/.face.distrib" ] \
    && ok "désinstallation : desktop-base retrouve son .face (version à jour)" || ko "retour arrière"
exit $fail
