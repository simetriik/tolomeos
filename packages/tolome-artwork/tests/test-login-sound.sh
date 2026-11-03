#!/bin/sh
# Teste data/login-sound/tolome-login-sound avec de faux gsettings, wpctl, pw-play
# et logger : aucun son n'est réellement joué.
# Usage : sh tests/test-login-sound.sh
set -u
SCRIPT="$(cd "$(dirname "$0")" && pwd)/../data/login-sound/tolome-login-sound"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/sons"
fail=0

cat > "$T/bin/gsettings" <<'F'
#!/bin/sh
echo "${FAKE_EVENT_SOUNDS:-true}"
F
cat > "$T/bin/wpctl" <<'F'
#!/bin/sh
[ "${FAKE_WPCTL:-ok}" = "ok" ]
F
cat > "$T/bin/pw-play" <<'F'
#!/bin/sh
echo "$@" >> "$FAKE_LOG_PLAY"
[ "${FAKE_PWPLAY_FAIL:-0}" = "0" ]
F
cat > "$T/bin/logger" <<'F'
#!/bin/sh
echo "$@" >> "$FAKE_LOG_LOGGER"
F
chmod +x "$T/bin/"*

lance() { # nom ; variables d'environnement déjà exportées
    : > "$T/play.log"; : > "$T/logger.log"
    PATH="$T/bin:$PATH" FAKE_LOG_PLAY="$T/play.log" FAKE_LOG_LOGGER="$T/logger.log" \
        TOLOME_SOUND_DIR="$T/sons" TOLOME_CMDLINE_FILE="$T/cmdline" TOLOME_WAIT_TRIES=2 sh "$SCRIPT"
    echo $?
}
verifie() { # nom ; joue(0/1) ; motif de log ('' = aucun)
    rc=$(lance)
    played=$(wc -l < "$T/play.log"); logged=$(grep -c "$3" "$T/logger.log" || true)
    ok=1
    [ "$rc" = "0" ] || ok=0
    [ "$played" = "$2" ] || ok=0
    if [ -n "$3" ] && [ "$logged" = "0" ]; then ok=0; fi
    if [ "$ok" = 1 ]; then echo "OK   $1"; else echo "ECHEC $1 (rc=$rc, lectures=$played, log='$3'->$logged)"; fail=1; fi
}

echo "BOOT_IMAGE=/vmlinuz root=UUID=x quiet splash" > "$T/cmdline"
: > "$T/sons/accueil.wav"

verifie "session normale : le son est joué"            1 ""
grep -q -- '--volume=0.7' "$T/play.log" && grep -q "$T/sons/accueil.wav" "$T/play.log" \
    && echo "OK   volume 0.7 et fichier accueil.wav" || { echo "ECHEC volume/fichier : $(cat "$T/play.log")"; fail=1; }

echo "BOOT_IMAGE=/live/vmlinuz boot=live components quiet" > "$T/cmdline"
verifie "session live : silence"                       0 ""
echo "BOOT_IMAGE=/vmlinuz quiet" > "$T/cmdline"

FAKE_EVENT_SOUNDS=false; export FAKE_EVENT_SOUNDS
verifie "event-sounds=false : silence"                 0 ""
unset FAKE_EVENT_SOUNDS

FAKE_WPCTL=ko; export FAKE_WPCTL
verifie "pas de sortie audio : silence + journal"      0 "pas de sortie audio"
unset FAKE_WPCTL

FAKE_PWPLAY_FAIL=1; export FAKE_PWPLAY_FAIL
verifie "échec de pw-play : journal, sortie 0"         1 "échec de la lecture"
unset FAKE_PWPLAY_FAIL

rm "$T/sons/accueil.wav"
verifie "aucun fichier : journal, silence"             0 "aucun fichier accueil"
: > "$T/sons/accueil.ogg"
verifie "remplacement par accueil.ogg : joué"          1 ""
grep -q 'accueil.ogg' "$T/play.log" && echo "OK   le fichier .ogg est bien celui joué" || { echo "ECHEC .ogg non joué"; fail=1; }

exit $fail
