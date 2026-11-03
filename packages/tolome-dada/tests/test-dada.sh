#!/bin/bash
# Teste la commande dada (transmission des arguments) et sa complétion bash.
# Usage : bash tests/test-dada.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0; ok() { echo "OK   $1"; }; ko() { echo "ECHEC $1"; fail=1; }

# --- 1. transmission des arguments : sudo-rs remplacé par un enregistreur
cat > "$T/faux-sudo-rs" <<'F'
#!/bin/sh
i=0; for a in "$@"; do i=$((i + 1)); printf '%s=[%s]\n' "$i" "$a"; done > "$FAUX_LOG"
exit "${FAUX_RC:-0}"
F
chmod +x "$T/faux-sudo-rs"
sed "s#/usr/bin/sudo-rs#$T/faux-sudo-rs#" "$ROOT/data/dada" > "$T/dada"; chmod +x "$T/dada"
export FAUX_LOG="$T/args.log"
"$T/dada" nala install vim; [ "$(cat "$FAUX_LOG" | tr '\n' ' ')" = "1=[nala] 2=[install] 3=[vim] " ] && ok "dada nala install vim -> sudo-rs nala install vim" || ko "arguments simples"
"$T/dada" -u alice sh -c 'echo "a b"' ""; [ "$(cat "$FAUX_LOG" | tr '\n' ' ')" = '1=[-u] 2=[alice] 3=[sh] 4=[-c] 5=[echo "a b"] 6=[] ' ] && ok "espaces, guillemets et argument vide préservés" || ko "arguments spéciaux ($(cat "$FAUX_LOG" | tr '\n' ' '))"
FAUX_RC=7 "$T/dada" false; [ $? -eq 7 ] && ok "le code de retour de sudo-rs est propagé" || ko "code de retour"
"$T/dada"; [ "$(wc -l < "$FAUX_LOG")" -eq 0 ] && ok "sans argument : aucun argument inventé" || ko "sans argument"
sh -n "$ROOT/data/dada" && ok "syntaxe sh" || ko "syntaxe"

# --- 1 bis. pages de manuel
for f in man/dada.8 man/dada.fr.8; do man -l "$ROOT/$f" >/dev/null 2>"$T/man.err" && [ ! -s "$T/man.err" ] && ok "page $f lisible sans erreur" || ko "page $f ($(head -1 "$T/man.err"))"; done

# --- 2. complétion bash (si bash-completion est installé)
BC=/usr/share/bash-completion/bash_completion
if [ ! -f "$BC" ]; then echo "SKIP : bash-completion absent"; exit $fail; fi
complete_cmd() { # $1 = ligne de commande ; affiche les complétions
    bash --norc --noprofile -c '
        source '"$BC"'; source '"$ROOT"'/data/dada.bash-completion
        line=$1; read -ra COMP_WORDS <<< "$line"; [[ $line == *" " ]] && COMP_WORDS+=("")
        COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 )); COMP_LINE=$line; COMP_POINT=${#line}
        fn=$(complete -p dada | sed -E "s/.*-F ([^ ]+) .*/\1/")
        "$fn" dada "${COMP_WORDS[COMP_CWORD]}" "${COMP_WORDS[COMP_CWORD-1]}"
        printf "%s\n" "${COMPREPLY[@]}"' _ "$1" 2>/dev/null
}
complete -p >/dev/null 2>&1
[ -n "$(bash --norc --noprofile -c "source $BC; source $ROOT/data/dada.bash-completion; complete -p dada" 2>/dev/null)" ] && ok "complétion enregistrée pour dada" || ko "complétion non enregistrée"
out=$(complete_cmd "dada --us"); [[ $out == *"--user="* ]] && ok "dada --us<Tab> -> --user=" || ko "option longue ($out)"
out=$(complete_cmd "dada -"); [[ $out == *"--login"* && $out == *"-n"* ]] && ok "dada -<Tab> propose les options de sudo-rs" || ko "options ($out)"
out=$(complete_cmd "dada -u ro"); [[ $out == *"root"* ]] && ok "dada -u ro<Tab> -> root (utilisateurs)" || ko "utilisateurs ($out)"
out=$(complete_cmd "dada -g ro"); [[ $out == *"root"* ]] && ok "dada -g ro<Tab> -> root (groupes)" || ko "groupes ($out)"
out=$(complete_cmd "dada ls --al"); [[ $out == *"--all"* ]] && ok "dada ls --al<Tab> -> --all (commande déléguée)" || ko "commande déléguée ($out)"
out=$(complete_cmd "dada apt ins"); [[ $out == *"install"* ]] && ok "dada apt ins<Tab> -> install" || ko "apt ($out)"
out=$(complete_cmd "dada -u root apt ins"); [[ $out == *"install"* ]] && ok "dada -u root apt ins<Tab> -> install (option avec argument sautée)" || ko "option avec argument ($out)"
exit $fail
