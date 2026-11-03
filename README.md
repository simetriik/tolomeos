# Tɔlɔmɛ

Distribution GNU/Linux pour le Bénin, fondée sur **Debian 13 (trixie)** avec le bureau GNOME.
Éditée par Simetriik Solutions, filiale de Nemim Sarl. Site : https://tolome.net

## Contenu du dépôt

| Dossier | Rôle |
|---|---|
| `packages/` | Paquets Debian de Tɔlɔmɛ (un dossier par paquet, avec son `debian/`) |
| `live/` | Configuration `live-build` qui assemble l'image ISO |
| `tools/` | Scripts de construction et de génération |

Paquets : `tolome-keyboard-fon` (clavier fon + français), `tolome-artwork` (fonds, logos, Plymouth, GRUB, son d'accueil),
`tolome-base` (identité du système, avatar par défaut), `tolome-calamares-settings` (installateur),
`tolome-gdm-theme` (écran de connexion), `tolome-dada` (commande d'administration), `tolome-locales` (locale `fr_BJ`).

Le détail de l'image (langue, fuseau, limites connues) est dans [`live/README.md`](live/README.md).

## Construire

Prérequis : `build-essential debhelper devscripts live-build debootstrap squashfs-tools xorriso mtools grub-pc-bin grub-efi-amd64-bin`.

    tools/build-packages.sh              # construit les paquets et les copie dans live/config/packages.chroot/
    cd live && sudo lb clean && sudo ./auto/build

Ne pas construire dans `/tmp` (tmpfs trop petit). Les `.deb`, l'ISO et les journaux ne sont pas versionnés.

## Régénérer les fonds et logos

    python3 tools/generate-artwork.py packages/tolome-artwork/artwork [police_montserrat.ttf]

Sans police, le nom reste un `<text>`. Avec la police variable `Montserrat[wght].ttf` (OFL-1.1, Google Fonts ; la version du paquet
`fonts-montserrat` n'a pas la lettre « ɔ ») et `fonttools`, le nom est vectorisé : la sortie est identique aux fichiers versionnés.

## Régénérer la locale fon_BJ

    python3 tools/generate-fon_BJ.py <glossaire.csv>

Le script régénère `packages/tolome-locales/i18n/locales/fon_BJ` depuis le glossaire Tɔlɔmɛ (colonne « Fon », lignes LC01 à LC26).
Le glossaire n'est pas versionné dans ce dépôt.

## Licences et marque

Plusieurs licences selon le contenu (GPL-2, CC-BY-SA-4.0, OFL-1.1, LGPL-2.1+) : voir [`LICENSE`](LICENSE) et `LICENSES/`.
Le nom « Tɔlɔmɛ » et le logo baobab sont des marques de Simetriik Solutions : voir [`MARQUE`](MARQUE).

## Contact

dev@tolome.net
