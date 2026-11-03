#!/bin/bash
# Teste data/set-avatar dans un dossier AccountsService factice : comptes neufs, images choisies
# par l'utilisateur (jamais écrasées), idempotence, retour arrière, et la chaîne complète
# « /etc/passwd modifié -> unité .path -> icône posée » avec systemd --user si disponible.
# Usage : bash tests/test-set-avatar.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/data/set-avatar"
T=$(mktemp -d); trap 'rm -rf "$T"; systemctl --user stop tolome-avatar-test.path tolome-avatar-test.service 2>/dev/null' EXIT
fail=0; ok() { echo "OK   $1"; }; ko() { echo "ECHEC $1"; fail=1; }

AS="$T/as"; H="$T/home"; mkdir -p "$AS/users" "$AS/icons" "$H"
python3 -I -c "
from PIL import Image
Image.new('RGB',(32,32),'#23325E').save('$T/face.png')
Image.new('RGB',(32,32),'#FF0000').save('$T/rouge.png')" 2>/dev/null || { printf 'BAOBAB' > "$T/face.png"; printf 'ROUGE' > "$T/rouge.png"; }
export TOLOME_FACE="$T/face.png" TOLOME_AS_DIR="$AS" TOLOME_PASSWD="$T/passwd" TOLOME_LOGIN_DEFS="$T/login.defs" TOLOME_NO_RESTART=1
printf 'UID_MIN 1000\nUID_MAX 60000\n' > "$T/login.defs"
mkuser() { mkdir -p "$H/$1"; }
cat > "$T/passwd" <<P
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
sysuser:x:999:999::/var/lib/sys:/bin/bash
neuf:x:1000:1000:Neuf:$H/neuf:/bin/bash
choisi:x:1001:1001:Choisi:$H/choisi:/bin/bash
defaut:x:1002:1002:Defaut:$H/defaut:/bin/bash
ailleurs:x:1003:1003:Ailleurs:$H/ailleurs:/bin/bash
perso:x:1004:1004:Perso:$H/perso:/bin/bash
orphelin:x:1005:1005:Orphelin:$H/orphelin:/bin/bash
riche:x:1006:1006:Riche:$H/riche:/bin/bash
sansshell:x:1007:1007:Sans:$H/sansshell:/usr/sbin/nologin
P
for u in neuf choisi defaut ailleurs perso orphelin riche; do mkuser $u; done
# état de départ
cp "$T/face.png" "$H/neuf/.face"                                   # skel : baobab
cp "$T/rouge.png" "$AS/icons/choisi"; printf '[User]\nLanguage=fr_FR.UTF-8\nIcon=%s/icons/choisi\n' "$AS" > "$AS/users/choisi"     # choisi dans Paramètres
cp "$T/face.png" "$H/defaut/.face"; printf '[User]\nIcon=%s/defaut/.face\n' "$H" > "$AS/users/defaut"                              # clé vers le ~/.face par défaut
cp "$T/rouge.png" "$H/ailleurs/.face"; printf '[User]\nIcon=%s/ailleurs/.face\n' "$H" > "$AS/users/ailleurs"                      # clé vers une autre image
cp "$T/rouge.png" "$H/perso/.face"                                                                                              # ~/.face personnel, aucune clé
cp "$T/rouge.png" "$AS/icons/orphelin"                                                                                          # icône sans clé
printf '[User]\nLanguage=fon_BJ.UTF-8\nSession=gnome\nSystemAccount=false\n' > "$AS/users/riche"; cp "$T/face.png" "$H/riche/.face" # autres clés

sh "$SCRIPT" --all 2>"$T/log"
cmpf() { cmp -s "$1" "$2"; }
# --- compte neuf
cmpf "$AS/icons/neuf" "$T/face.png" && ok "compte neuf : icons/neuf = baobab" || ko "compte neuf : icône"
grep -qx "Icon=$AS/icons/neuf" "$AS/users/neuf" && ok "compte neuf : Icon= posé dans users/neuf" || ko "compte neuf : clé"
[ "$(stat -c %a "$AS/icons/neuf")" = 644 ] && ok "compte neuf : icône lisible par GDM (0644)" || ko "compte neuf : droits icône ($(stat -c %a "$AS/icons/neuf"))"
[ "$(stat -c %a "$AS/users/neuf")" = 600 ] && ok "compte neuf : fichier utilisateur en 0600" || ko "compte neuf : droits users"
grep -qx '\[User\]' "$AS/users/neuf" && ok "compte neuf : section [User]" || ko "compte neuf : section"
# --- images choisies : intactes
cmpf "$AS/icons/choisi" "$T/rouge.png" && grep -qx "Icon=$AS/icons/choisi" "$AS/users/choisi" && grep -qx 'Language=fr_FR.UTF-8' "$AS/users/choisi" \
    && ok "image choisie dans Paramètres : intacte (icône, clé et autres réglages)" || ko "image choisie écrasée"
cmpf "$AS/icons/orphelin" "$T/rouge.png" && [ ! -f "$AS/users/orphelin" ] && ok "icône existante sans clé : intacte, rien ajouté" || ko "icône orpheline modifiée"
[ ! -e "$AS/icons/ailleurs" ] && grep -qx "Icon=$H/ailleurs/.face" "$AS/users/ailleurs" && ok "clé vers une autre image (~/.face différent) : intacte" || ko "clé vers une autre image modifiée"
[ ! -e "$AS/icons/perso" ] && [ ! -f "$AS/users/perso" ] && ok "~/.face personnel sans clé : intact, aucune icône posée" || ko "~/.face personnel écrasé"
# --- ~/.face par défaut mais illisible par GDM : redirigé vers icons/
cmpf "$AS/icons/defaut" "$T/face.png" && grep -qx "Icon=$AS/icons/defaut" "$AS/users/defaut" && ! grep -q '/\.face' "$AS/users/defaut" \
    && ok "clé vers le ~/.face par défaut : redirigée vers icons/defaut (lisible par GDM)" || ko "clé ~/.face par défaut"
# --- autres clés conservées
grep -qx 'Language=fon_BJ.UTF-8' "$AS/users/riche" && grep -qx 'Session=gnome' "$AS/users/riche" && grep -qx 'SystemAccount=false' "$AS/users/riche" \
    && [ "$(grep -c '^Icon=' "$AS/users/riche")" = 1 ] && ok "fichier avec d'autres clés : conservées, Icon= ajouté une fois" || ko "autres clés perdues"
# --- comptes exclus
for u in root daemon nobody sysuser sansshell; do
    [ ! -e "$AS/icons/$u" ] && [ ! -e "$AS/users/$u" ] || ko "compte système/sans shell « $u » traité"
done; ok "comptes système, UID hors plage et sans shell ignorés"
# --- idempotence
find "$AS" -type f -exec md5sum {} + | sort > "$T/avant"; sleep 1; sh "$SCRIPT" --all 2>/dev/null; find "$AS" -type f -exec md5sum {} + | sort > "$T/apres"
cmp -s "$T/avant" "$T/apres" && ok "idempotence : second passage sans aucun changement" || ko "idempotence"
[ "$(find "$AS" -name '.tolome.*' | wc -l)" = 0 ] && ok "aucun fichier temporaire laissé" || ko "fichiers temporaires"
# --- l'utilisateur change d'image après coup (via Paramètres) : respecté au passage suivant
cp "$T/rouge.png" "$AS/icons/neuf"
sh "$SCRIPT" --all 2>/dev/null; cmpf "$AS/icons/neuf" "$T/rouge.png" && ok "image changée ensuite par l'utilisateur : respectée" || ko "image changée écrasée"
cp "$T/face.png" "$AS/icons/neuf"
# --- --user
printf 'nouveau:x:1010:1010::%s/nouveau:/bin/bash\nsecond:x:1011:1011::%s/second:/bin/bash\n' "$H" "$H" >> "$T/passwd"; mkuser nouveau; mkuser second
sh "$SCRIPT" --user nouveau 2>/dev/null
[ -f "$AS/icons/nouveau" ] && [ ! -e "$AS/icons/second" ] && ok "--user : seul le compte demandé est traité" || ko "--user"
sh "$SCRIPT" --user inconnu 2>/dev/null && ok "--user : compte inconnu ignoré sans erreur" || ko "--user inconnu"
# --- dossiers absents créés avec les bons droits
rm -rf "$AS"; sh "$SCRIPT" --user neuf 2>/dev/null
[ "$(stat -c %a "$AS/icons")" = 755 ] && [ "$(stat -c %a "$AS/users")" = 700 ] && ok "dossiers absents : icons 0755, users 0700" || ko "droits des dossiers"
# --- noms douteux
printf 'bad name:x:1020:1020::%s/x:/bin/bash\nMajus:x:1021:1021::%s/y:/bin/bash\n' "$H" "$H" >> "$T/passwd"
sh "$SCRIPT" --all 2>/dev/null; [ ! -e "$AS/icons/bad name" ] && [ ! -e "$AS/icons/Majus" ] && ok "noms de compte hors norme ignorés" || ko "noms hors norme"
# --- retour arrière : retire le baobab posé, garde les images des utilisateurs
printf '[User]\nLanguage=fon_BJ.UTF-8\nSession=gnome\n' > "$AS/users/riche"; cp "$T/face.png" "$H/riche/.face"
cp "$T/rouge.png" "$AS/icons/second2" 2>/dev/null; printf '[User]\nIcon=%s/icons/second2\n' "$AS" > "$AS/users/second2"
sh "$SCRIPT" --all 2>/dev/null
sh "$SCRIPT" --revert 2>/dev/null
[ ! -e "$AS/icons/neuf" ] && [ ! -e "$AS/users/neuf" ] && ok "--revert : icône posée retirée, fichier réduit à [User] supprimé" || ko "--revert neuf"
grep -qx 'Language=fon_BJ.UTF-8' "$AS/users/riche" && ! grep -q '^Icon=' "$AS/users/riche" && ok "--revert : autres clés conservées, Icon= retiré" || ko "--revert riche"
[ -f "$AS/icons/second2" ] && grep -q "second2" "$AS/users/second2" && ok "--revert : image d'un utilisateur intacte" || ko "--revert image utilisateur"
# --- image par défaut absente
TOLOME_FACE="$T/absent.png" sh "$SCRIPT" --all 2>"$T/log2"; grep -q 'introuvable' "$T/log2" && ok "image par défaut absente : message, sortie 0" || ko "image absente"
# --- sans option
sh "$SCRIPT" >/dev/null 2>&1; [ $? -eq 2 ] && ok "sans option : code 2 et usage" || ko "usage"

# --- chaîne complète avec systemd --user : modification atomique du passwd -> icône posée
if systemctl --user is-system-running >/dev/null 2>&1 || systemctl --user show-environment >/dev/null 2>&1; then
    rm -rf "$AS"; mkdir -p "$AS"; printf 'root:x:0:0:root:/root:/bin/bash\n' > "$T/passwd"; mkuser bonjour
    systemd-run --user --quiet --unit=tolome-avatar-test --path-property=PathChanged="$T/passwd" \
        --setenv=TOLOME_FACE="$T/face.png" --setenv=TOLOME_AS_DIR="$AS" --setenv=TOLOME_PASSWD="$T/passwd" \
        --setenv=TOLOME_LOGIN_DEFS="$T/login.defs" --setenv=TOLOME_NO_RESTART=1 \
        sh "$SCRIPT" --all >/dev/null 2>&1
    sleep 1
    printf 'root:x:0:0:root:/root:/bin/bash\nbonjour:x:1000:1000::%s/bonjour:/bin/bash\n' "$H" > "$T/passwd+"; mv "$T/passwd+" "$T/passwd"   # comme useradd
    for i in 1 2 3 4 5 6 7 8; do [ -f "$AS/icons/bonjour" ] && break; sleep 0.5; done
    cmpf "$AS/icons/bonjour" "$T/face.png" && ok "chaîne complète : passwd remplacé -> unité .path -> baobab posé pour « bonjour »" || ko "chaîne complète (unité .path)"
else
    echo "SKIP : systemd --user indisponible (chaîne .path non testée)"
fi
exit $fail
