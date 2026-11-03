#!/bin/sh
# Construit les paquets Debian de Tɔlɔmɛ et les copie dans la configuration live-build.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
dest="$root/live/config/packages.chroot"
mkdir -p "$dest"
for dir in "$root"/packages/tolome-*/; do
    name=$(basename "$dir")
    echo "== $name"
    (cd "$dir" && dpkg-buildpackage -us -uc -b)
    mv "$root"/packages/"$name"_*_all.deb "$dest"/
    rm -f "$root"/packages/"$name"_*.buildinfo "$root"/packages/"$name"_*.changes
done
ls -l "$dest"
