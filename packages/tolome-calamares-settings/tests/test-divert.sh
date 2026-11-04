#!/bin/sh
# Teste la séquence de détournement de calamares.desktop (installation, mise à jour de
# calamares, désinstallation) dans une racine factice. Usage : sh tests/test-divert.sh
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
A="$T/dpkg"; mkdir -p "$A/info" "$T/root/usr/share/applications"; : > "$A/status"; : > "$A/available"
D="dpkg-divert --admindir $A --instdir $T/root"
fail=0
ok() { echo "OK   $1"; }
ko() { echo "ECHEC $1"; fail=1; }

echo "CALAMARES-V1" > "$T/root/usr/share/applications/calamares.desktop"                 # installé par calamares

$D --package tolome-calamares-settings --add --rename --divert /usr/share/applications/calamares.desktop.distrib /usr/share/applications/calamares.desktop >/dev/null
[ ! -e "$T/root/usr/share/applications/calamares.desktop" ] && [ "$(cat "$T/root/usr/share/applications/calamares.desktop.distrib")" = "CALAMARES-V1" ] \
    && ok "installation : l'original est déplacé en calamares.desktop.distrib" || ko "détournement"
echo "TOLOME-MASQUE" > "$T/root/usr/share/applications/calamares.desktop"                          # déballé par tolome-calamares-settings
[ "$(cat "$T/root/usr/share/applications/calamares.desktop")" = "TOLOME-MASQUE" ] && ok "le fichier de tolome-calamares-settings occupe calamares.desktop" || ko "fichier tolome"

echo "CALAMARES-V2" > "$T/root/usr/share/applications/calamares.desktop.distrib"             # mise à jour de calamares (écrit à l'emplacement détourné)
[ "$(cat "$T/root/usr/share/applications/calamares.desktop")" = "TOLOME-MASQUE" ] && ok "mise à jour de calamares : calamares.desktop n'est pas écrasé" || ko "mise à jour"

rm -f "$T/root/usr/share/applications/calamares.desktop"                                    # désinstallation (dpkg retire le fichier du paquet)
$D --package tolome-calamares-settings --remove --rename /usr/share/applications/calamares.desktop >/dev/null
[ "$(cat "$T/root/usr/share/applications/calamares.desktop")" = "CALAMARES-V2" ] && [ ! -e "$T/root/usr/share/applications/calamares.desktop.distrib" ] \
    && ok "désinstallation : calamares retrouve son calamares.desktop (version à jour)" || ko "retour arrière"
exit $fail
