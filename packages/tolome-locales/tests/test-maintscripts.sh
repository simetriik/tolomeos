#!/bin/bash
# Teste preinst / postinst / trigger / prerm / postrm du paquet, y compris le
# détournement de SUPPORTED et son retour arrière, dans un espace de noms
# utilisateur où /usr/lib/locale et /usr/share/i18n sont des overlays temporaires
# (la machine n'est pas modifiée). Usage : bash tests/test-maintscripts.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
unshare -Urm true 2>/dev/null || { echo "SKIP : unshare -Urm indisponible"; exit 0; }
[ -f /usr/share/i18n/SUPPORTED ] || { echo "SKIP : paquet locales absent"; exit 0; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0; ok() { echo "OK   $1"; }; ko() { echo "ECHEC $1"; fail=1; }
mkdir -p "$T"/{up_loc,w_loc,up_i18n,w_i18n,dpkg}; : > "$T/dpkg/status"; : > "$T/dpkg/available"; mkdir -p "$T/dpkg/info"
# SUPPORTED est copié dans la couche écrivable : dpkg-divert ne peut pas changer le
# propriétaire d'un fichier de root (non mappé dans l'espace de noms) lors du renommage.
cp /usr/share/i18n/SUPPORTED "$T/up_i18n/SUPPORTED"

# Scripts du paquet : appel de locales-update redirigé vers les sources du dépôt.
for s in preinst postinst prerm postrm; do
    sed -e "s#/usr/lib/tolome/locales-update#env TOLOME_I18N_DIR=$ROOT/i18n sh $ROOT/scripts/locales-update#" \
        -e '/#DEBHELPER#/d' "$ROOT/debian/tolome-locales.$s" > "$T/$s"
done
# enroot COMMANDE… : exécute dans l'espace de noms (overlays montés, base dpkg temporaire)
enroot() {
    unshare -Urm sh -c "
        mount -t overlay overlay -o lowerdir=/usr/lib/locale,upperdir=$T/up_loc,workdir=$T/w_loc /usr/lib/locale &&
        mount -t overlay overlay -o lowerdir=/usr/share/i18n,upperdir=$T/up_i18n,workdir=$T/w_i18n /usr/share/i18n &&
        export DPKG_ADMINDIR=$T/dpkg && $*"
}
SUPP=/usr/share/i18n/SUPPORTED
orig_md5=$(md5sum < "$SUPP"); orig_lines=$(wc -l < "$SUPP")
nloc=$(grep -c -v -E '^[[:space:]]*(#|$)' "$ROOT/i18n/SUPPORTED")   # locales du paquet (fr_BJ, fon_BJ…)
host_loc=$(ls /usr/lib/locale | md5sum)

# --- 0. état initial
enroot "locale -a | grep -q fr_BJ" && ko "fr_BJ présente avant installation" || ok "avant installation : fr_BJ absente de locale -a"

# --- 1. preinst (installation)
enroot "sh $T/preinst install" >/dev/null 2>&1
[ "$(enroot "md5sum < $SUPP.distrib")" = "$orig_md5" ] && ok "preinst : SUPPORTED d'origine déplacé en SUPPORTED.distrib (identique)" || ko "preinst : .distrib"
[ "$(enroot "dpkg-divert --list tolome-locales | grep -c SUPPORTED")" = "1" ] && ok "preinst : détournement enregistré (tolome-locales)" || ko "preinst : détournement"
enroot "[ -f $SUPP ]" && ok "preinst : SUPPORTED reste présent pendant la mise en place" || ko "preinst : SUPPORTED absent"

# --- 2. postinst (configuration)
enroot "sh $T/postinst configure" >/dev/null 2>&1
[ "$(enroot "wc -l < $SUPP")" = "$((orig_lines + nloc))" ] && ok "postinst : SUPPORTED = original + $nloc lignes ($((orig_lines + nloc)) lignes)" || ko "postinst : nombre de lignes $(enroot "wc -l < $SUPP")"
enroot "grep -qx 'fr_BJ.UTF-8 UTF-8' $SUPP" && ok "postinst : « fr_BJ.UTF-8 UTF-8 » dans SUPPORTED (Calamares)" || ko "postinst : fr_BJ absente de SUPPORTED"
enroot "grep -qx 'fon_BJ.UTF-8 UTF-8' $SUPP" && ok "postinst : « fon_BJ.UTF-8 UTF-8 » dans SUPPORTED (Calamares)" || ko "postinst : fon_BJ absente de SUPPORTED"
enroot "head -n $orig_lines $SUPP | md5sum | cut -d' ' -f1" | grep -q "${orig_md5%% *}" && ok "postinst : les lignes d'origine sont inchangées" || ko "postinst : lignes d'origine modifiées"
enroot "[ -f /usr/lib/locale/fr_BJ.utf8/.tolome-locales ] && [ -f /usr/lib/locale/fr_BJ.utf8/LC_MONETARY ]" && ok "postinst : fr_BJ.utf8 compilée (avec témoin)" || ko "postinst : locale non compilée"
enroot "locale -a | grep -qx fr_BJ.utf8" && ok "postinst : locale -a liste fr_BJ.utf8" || ko "postinst : locale -a"
enroot "[ -f /usr/lib/locale/fon_BJ.utf8/.tolome-locales ] && locale -a | grep -qx fon_BJ.utf8" && ok "postinst : fon_BJ.utf8 compilée et listée par locale -a" || ko "postinst : fon_BJ non compilée"
enroot "LC_ALL=fon_BJ.UTF-8 bash -c \"printf '%s' \\\$(locale day | cut -d';' -f2)\"" | grep -q 'Tɛnigbe' && ok "postinst : fon_BJ.UTF-8 utilisable (lundi = Tɛnigbe)" || ko "postinst : setlocale fon_BJ"
enroot "LC_ALL=fr_BJ.UTF-8 bash -c \"printf '%s' \\\$(locale charmap)\"" | grep -q UTF-8 && ok "postinst : fr_BJ.UTF-8 utilisable (setlocale)" || ko "postinst : setlocale"
enroot "[ ! -e /usr/lib/locale/locale-archive ] || cmp -s /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive" && ok "postinst : locale-archive non modifiée" || ko "archive"
# les autres locales ne sont pas touchées
enroot "ls /usr/lib/locale | grep -v -E '^(fr_BJ.utf8|fon_BJ.utf8|\.tolome)' | md5sum" | grep -q "$(ls /usr/lib/locale | md5sum | cut -d' ' -f1)" && ok "postinst : les autres locales de /usr/lib/locale sont intactes" || ko "autres locales modifiées"

# --- 3. idempotence
enroot "sh $T/postinst configure" >/dev/null 2>&1
[ "$(enroot "grep -c '^fr_BJ.UTF-8 UTF-8$' $SUPP")" = "1" ] && ok "idempotence : pas de doublon dans SUPPORTED" || ko "idempotence : doublon"
enroot "[ -f /usr/lib/locale/fr_BJ.utf8/LC_MONETARY ]" && ok "idempotence : locale toujours compilée" || ko "idempotence : locale perdue"

# --- 4. mise à jour du paquet locales : nouveau SUPPORTED écrit dans .distrib, puis trigger
enroot "printf 'zz_ZZ UTF-8\n' >> $SUPP.distrib"
enroot "sh $T/postinst triggered" >/dev/null 2>&1
enroot "grep -qx 'zz_ZZ UTF-8' $SUPP && [ \$(grep -c '^fr_BJ.UTF-8 UTF-8\$' $SUPP) = 1 ]" && ok "trigger : SUPPORTED régénéré depuis le NOUVEAU fichier d'origine (fr_BJ conservée)" || ko "trigger"
enroot "[ -f /usr/lib/locale/fr_BJ.utf8/LC_MONETARY ]" && ok "trigger : fr_BJ recompilée" || ko "trigger : locale"

# --- 5. une locale existante non créée par le paquet n'est pas écrasée
enroot "env TOLOME_I18N_DIR=$ROOT/i18n sh $ROOT/scripts/locales-update clean" >/dev/null 2>&1
enroot "mkdir -p /usr/lib/locale/fr_BJ.utf8 && echo etrangere > /usr/lib/locale/fr_BJ.utf8/LC_IDENTIFICATION" 
enroot "env TOLOME_I18N_DIR=$ROOT/i18n sh $ROOT/scripts/locales-update compile" >/dev/null 2>&1
[ "$(enroot "cat /usr/lib/locale/fr_BJ.utf8/LC_IDENTIFICATION")" = "etrangere" ] && ok "locale préexistante (sans témoin) non écrasée" || ko "locale préexistante écrasée"
enroot "env TOLOME_I18N_DIR=$ROOT/i18n sh $ROOT/scripts/locales-update clean" >/dev/null 2>&1
enroot "[ -d /usr/lib/locale/fr_BJ.utf8 ]" && ok "clean : locale préexistante (sans témoin) conservée" || ko "clean : locale préexistante supprimée"
enroot "rm -rf /usr/lib/locale/fr_BJ.utf8; sh $T/postinst configure" >/dev/null 2>&1

# --- 6. prerm remove : locales compilées supprimées
enroot "sh $T/prerm remove" >/dev/null 2>&1
enroot "[ ! -e /usr/lib/locale/fr_BJ.utf8 ] && [ ! -e /usr/lib/locale/fon_BJ.utf8 ]" && ok "prerm remove : fr_BJ.utf8 et fon_BJ.utf8 supprimées" || ko "prerm : locale restante"
enroot "locale -a | grep -q -E 'fr_BJ|fon_BJ'" && ko "prerm : fr_BJ/fon_BJ toujours dans locale -a" || ok "prerm remove : fr_BJ et fon_BJ absentes de locale -a"
enroot "sh $T/prerm upgrade" >/dev/null 2>&1; enroot "sh $T/postinst configure" >/dev/null 2>&1
enroot "sh $T/prerm upgrade" >/dev/null 2>&1
enroot "[ -f /usr/lib/locale/fr_BJ.utf8/LC_MONETARY ]" && ok "prerm upgrade : la locale n'est pas supprimée lors d'une mise à jour" || ko "prerm upgrade"
enroot "sh $T/prerm remove" >/dev/null 2>&1

# --- 7. postrm remove : SUPPORTED rendu (version à jour), détournement levé
enroot "sh $T/postrm remove" >/dev/null 2>&1
[ "$(enroot "dpkg-divert --list tolome-locales | wc -l")" = "0" ] && ok "postrm remove : détournement levé" || ko "postrm : détournement restant"
enroot "[ ! -e $SUPP.distrib ] && grep -qx 'zz_ZZ UTF-8' $SUPP && ! grep -q -E '^(fr|fon)_BJ' $SUPP" && ok "postrm remove : SUPPORTED rendu à locales (version à jour, sans fr_BJ ni fon_BJ)" || ko "postrm : SUPPORTED"
[ "$(enroot "wc -l < $SUPP")" = "$((orig_lines + 1))" ] && ok "postrm remove : $((orig_lines + 1)) lignes (original + zz_ZZ de la mise à jour simulée)" || ko "postrm : lignes"

# --- 8. purge : pas de reste
enroot "mkdir -p /usr/lib/locale/.tolome-build.X1; sh $T/postrm purge" >/dev/null 2>&1
enroot "ls -a /usr/lib/locale | grep -q tolome" && ko "purge : restes dans /usr/lib/locale" || ok "postrm purge : aucun reste (/usr/lib/locale)"

# --- 9. abort-install : retour arrière après un échec d'installation
enroot "sh $T/preinst install" >/dev/null 2>&1; enroot "sh $T/postrm abort-install" >/dev/null 2>&1
[ "$(enroot "dpkg-divert --list tolome-locales | wc -l")" = "0" ] && enroot "[ -f $SUPP ] && [ ! -e $SUPP.distrib ]" && ok "abort-install : détournement levé, SUPPORTED en place" || ko "abort-install"

# --- 10. la machine n'a pas été touchée
[ "$(md5sum < $SUPP)" = "$orig_md5" ] && ok "machine : /usr/share/i18n/SUPPORTED inchangé" || ko "machine : SUPPORTED modifié"
[ "$(ls /usr/lib/locale | md5sum)" = "$host_loc" ] && ok "machine : /usr/lib/locale inchangé" || ko "machine : /usr/lib/locale modifié"
[ "$(dpkg-divert --list 2>/dev/null | grep -ci tolome-locales)" = "0" ] && ok "machine : aucune diversion tolome-locales" || ko "machine : diversion"
exit $fail
