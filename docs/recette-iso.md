# Fiche de recette manuelle de l'ISO Tɔlɔmɛ

À remplir à chaque nouvelle ISO. Une fiche par image et par mode de démarrage (BIOS, UEFI).

| Champ | Valeur |
|---|---|
| ISO (nom) | |
| Empreinte sha256 (`sha256sum -c`) | |
| Date du test | |
| Testeur | |
| Mode | BIOS / UEFI |
| Machine | VM (QEMU/KVM) / matériel : |

## Préparation

Une VM sans disque ne permet pas d'atteindre les pages Calamares après « Bienvenue ». Prévoir un disque virtuel d'au moins 20 Go.

    qemu-img create -f qcow2 test.qcow2 20G
    # BIOS
    qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cdrom <iso> -hda test.qcow2 -boot d
    # UEFI (chemin du firmware OVMF à adapter)
    qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cdrom <iso> -hda test.qcow2 -boot d \
        -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd

Légende : `[ ]` à faire, `[x]` conforme, `[!]` non conforme (noter l'observation dans « Anomalies »).

## 1. Démarrage

- [ ] Menu GRUB : fond indigo, logo Tɔlɔmɛ, entrées lisibles, entrée sélectionnée en ocre, aucun message d'erreur (ex. police introuvable).
- [ ] Menu en français : « Essayer Tɔlɔmɛ », « Tɔlɔmɛ, mode sans échec », « Utilitaires… » ; ligne d'aide traduite ; les lettres ɔ et ɛ s'affichent.
- [ ] Splash Plymouth : logo Tɔlɔmɛ affiché (défaut connu : texte du logo inversé horizontalement).
- [ ] Le bureau GNOME s'ouvre sans saisie de mot de passe (session live, utilisateur `tolome`, nom de machine `tolome`).
- [ ] Son d'accueil joué à l'ouverture de session (si la VM a une sortie audio).

## 2. Session live

- [ ] Langue de l'interface : français (`echo $LANG` donne `fr_FR.UTF-8`).
- [ ] Fuseau : `timedatectl` indique `Africa/Porto-Novo`.
- [ ] Clavier : disposition `fon` par défaut, `fr` en seconde ; bascule avec Alt+Maj ; le sélecteur du bandeau affiche « fon ».
- [ ] Saisie fon : les lettres ɔ, ɛ, ɖ, ɣ… sont obtenues selon la disposition ; essayer dans un éditeur de texte.
- [ ] Identité : `grep ^ID= /etc/os-release` donne `ID=tolome`.
- [ ] Applications : Thunderbird (français) présent ; Evolution absent ; un seul terminal (GNOME Terminal) ; pas de visite guidée GNOME Tour.
- [ ] Dock : baobab Tɔlɔmɛ en premier favori ; Thunderbird présent.

## 3. Locales fr_BJ et fon_BJ

- [ ] `locale -a | grep -E 'fr_BJ|fon_BJ'` liste les deux locales.
- [ ] `LC_ALL=fr_BJ.UTF-8 locale -k LC_MONETARY` : monnaie « F CFA », 0 décimale ; `LC_ALL=fr_BJ.UTF-8 locale -k LC_NUMERIC` : virgule décimale ; `LC_ALL=fr_BJ.UTF-8 locale -k LC_TELEPHONE` : préfixe +229.
- [ ] `LC_ALL=fon_BJ.UTF-8 date` : jour et mois en fon.
- [ ] `LANG` reste `fr_FR.UTF-8` (ni `fr_BJ` ni `fon_BJ` par défaut).
- [ ] `grep -E 'fr_BJ|fon_BJ' /usr/share/i18n/SUPPORTED` : les deux lignes sont présentes ; `dpkg-divert --list | grep SUPPORTED` montre le détournement.

## 4. Commande dada

- [ ] `dada whoami` demande le mot de passe puis répond `root` (ou passe sans mot de passe en session live si prévu).
- [ ] `dada -i` ouvre un shell d'administration ; `exit` en sort.
- [ ] `dada ` + Tab : complétion bash des options.
- [ ] `man dada` : page de manuel en français.
- [ ] `sudo` d'origine toujours présent ; `nala` installé (`nala --version`).

## 5. Installateur Calamares

- [ ] Titre de la fenêtre « Installateur Tɔlɔmɛ » ; page « Bienvenue dans l'installateur Calamares pour Tɔlɔmɛ » ; aucune mention de Debian.
- [ ] Logo de la barre latérale : baobab Tɔlɔmɛ.
- [ ] Icône du dock pendant l'installation : icône Tɔlɔmɛ.
- [ ] Le lanceur d'origine « Install System » est absent de la liste des applications.
- [ ] Liste des langues : hindi, marathi, coréen, thaï, malayalam, cingalais lisibles (pas de carrés).
- [ ] Page Clavier : aperçu avec lettres sur les touches ; « Fongbe (Benin) » listé et sélectionnable.
- [ ] Page Lieu / langue : en choisissant le Bénin et le français, les formats proposés sont `fr_BJ.UTF-8`.
- [ ] Page Partitions : disque virtuel détecté ; partitionnement automatique accepté.
- [ ] Installation terminée sans erreur ; message de fin affiché.

## 6. Système installé (après redémarrage sur le disque)

- [ ] Démarrage depuis le disque : menu GRUB aux couleurs Tɔlɔmɛ, splash Plymouth, puis écran de connexion.
- [ ] Écran de connexion (GDM) : fond Ganvié assombri et flouté, logo Tɔlɔmɛ, carte d'utilisateur translucide sans liseré bleu, avatar par défaut (baobab) affiché.
- [ ] Mode de fond : avec `MODE=flat` dans `/etc/tolome/gdm-background.conf` puis `sudo /usr/lib/tolome/gdm-theme-update`, le fond devient un aplat indigo ; remettre `MODE=image` ensuite.
- [ ] Ouverture de session : clavier `fon` par défaut, fuseau `Africa/Porto-Novo`, formats `fr_BJ` si choisis à l'installation.
- [ ] Image de profil par défaut : baobab (`/etc/skel/.face` pour un nouvel utilisateur).
- [ ] `dada` fonctionne avec l'utilisateur créé à l'installation.
- [ ] `/etc/os-release` : `ID=tolome`, `ID_LIKE=debian`.
- [ ] Mise à jour : `dada nala update` s'exécute sans erreur (réseau requis).

## Anomalies

| # | Point | Observé | Gravité | Action |
|---|---|---|---|---|
| | | | | |

## Conclusion

- [ ] ISO conforme (aucune anomalie bloquante) / [ ] non conforme.
