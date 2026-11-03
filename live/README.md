# tolome-live

Configuration `live-build` de l'image ISO de **Tɔlɔmɛ** (Debian 13 trixie, amd64, GNOME).

## Contenu de la première image
- Bureau GNOME, installateur Calamares, démarrage BIOS + UEFI (GRUB).
- Paquets Tɔlɔmɛ (dans `config/packages.chroot/`) : `tolome-keyboard-fon`, `tolome-artwork`, `tolome-base`,
  `tolome-calamares-settings` (remplace `calamares-settings-debian`) ; disposition `fon` par défaut, `fr` en seconde (Alt+Maj).
- Langue `fr_FR.UTF-8`, fuseau `Africa/Porto-Novo`, hostname `tolome`.

## Limites connues
- **Pas de locale `fon_BJ` dans glibc** : la langue système reste `fr_FR`, le fon passe par le clavier uniquement.
- **`/etc/os-release` appartient à `base-files`.** Il est maintenant géré par le paquet `tolome-base`
  (détournement `dpkg-divert` de `/usr/lib/os-release` ; `ID=tolome`, `ID_LIKE=debian`).
  L'ancien écrasement via `includes.chroot` est supprimé. `/etc/issue` (bannière console) reste écrasé ici.
- Identité visuelle : `tolome-artwork` (fonds, icône, Plymouth, thème GRUB), `tolome-base` (os-release, GDM),
  `tolome-calamares-settings` (installateur). La visite guidée `gnome-tour` est retirée (hook).
  Le menu de l'ISO live est personnalisé ici : `config/bootloaders/grub-pc/` (`live-theme/theme.txt` + `logo.png` à proportions fixes,
  `config.cfg` qui donne un fond indigo à la console de chargement du noyau ; `splash.png` n'est qu'un aplat indigo, exigé par `theme.cfg`).
- **Courrier : Thunderbird (français) remplace Evolution.** Le méta-paquet `gnome` (qui dépend d'Evolution) est écarté
  par `config/archives/tolome-sans-gnome.pref` ; ses autres applications sont listées dans
  `config/package-lists/apps.list.chroot`. `evolution-data-server` reste (GNOME Agenda, Contacts, menu horloge).
  Le hook `0210-check-packages` fait échouer la construction si Evolution ou un second terminal (Zutty, xterm) réapparaît.
- **Un seul terminal : GNOME Terminal**, listé explicitement dans `desktop.list.chroot` (sinon apt choisit Zutty pour `x-terminal-emulator`).
- **Administration : `dada`** (« Sa Majesté » en fon, paquet `tolome-dada`) appelle `sudo-rs` ; `sudo` d'origine reste
  installé (compatibilité, fichiers PAM partagés). **`nala`** est installé d'office, `apt` reste la base.
- **Écran de connexion** : logo (`tolome-base`, alternative `vendor-logos`) et fond Ganvié assombri et flouté
  (`tolome-gdm-theme`, mode réglable dans `/etc/tolome/gdm-background.conf` : image, flat, off).
- **Image de profil par défaut** : baobab Tɔlɔmɛ (`/etc/skel/.face`, détourné par `tolome-base`).
- **Locale `fr_BJ`** (français du Bénin, paquet `tolome-locales`) : franc CFA « 25 000 F CFA », virgule décimale, +229.
  Compilée dans `/usr/lib/locale/fr_BJ.utf8` ; `/usr/share/i18n/SUPPORTED` est détourné pour que Calamares la propose.
  La langue par défaut reste `fr_FR.UTF-8` (seuls les formats peuvent passer à `fr_BJ` pour le Bénin).
- **Locale `fon_BJ`** (fon, paquet `tolome-locales` 0.2.0) : jours, mois, oui/non et tri de l'alphabet fon à 31 lettres ; locale de formats,
  sans traduction d'interface. La garde `0210-check-packages` vérifie qu'elle est compilée et listée dans `SUPPORTED`.
- Pas de traduction pour l'instant.

## Construction
Prérequis : `live-build debootstrap squashfs-tools xorriso mtools grub-pc-bin grub-efi-amd64-bin`.

    sudo lb clean           # obligatoire avant une reconstruction (conserve cache/)
    lb config               # exécute auto/config
    sudo ./auto/build       # produit l'ISO et build.log

Ne pas construire dans `/tmp` (tmpfs trop petit).

## Test
    qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cdrom tolome-amd64.hybrid.iso -boot d
