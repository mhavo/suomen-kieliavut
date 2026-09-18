#!/usr/bin/env bash
# Ajaa saman sanajoukon molempien hunspell-sanastojen ja Voikon läpi.
# Tuottaa docs/sanastot.md:n taulukon.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp "$REPO/dict/ginter/fi_FI.aff" "$REPO/dict/ginter/fi_FI.dic" "$WORK/"
cp "$REPO/dict/myspell-fi-0.7/fi-FI.aff" "$REPO/dict/myspell-fi-0.7/fi-FI.dic" "$WORK/"

SANAT=${1:-"$REPO/tools/testisanat.txt"}

check() { # $1 = sanastopolku ilman päätettä
    # hunspell -l tulostaa vain hylätyt sanat.
    hunspell -d "$1" -i UTF-8 -l < "$SANAT"
}

G=$(check "$WORK/fi_FI")
M=$(check "$WORK/fi-FI")
V=""
if command -v voikkospell >/dev/null; then
    V=$(voikkospell < "$SANAT" | awk '/^W/ {print $2}')
fi

# column -t hoitaa sarakkeet: printf %-Ns laskee tavuja, ei merkkejä,
# joten ääkköset sotkisivat tasauksen.
{
    printf 'sana\tginter\tmyspell\tvoikko\n'
    while IFS= read -r w; do
        [ -n "$w" ] || continue
        g="ok"; m="ok"; v="-"
        grep -qxF "$w" <<< "$G" && g="HYLKY"
        grep -qxF "$w" <<< "$M" && m="HYLKY"
        if command -v voikkospell >/dev/null; then
            v="ok"; grep -qxF "$w" <<< "$V" && v="HYLKY"
        fi
        printf '%s\t%s\t%s\t%s\n' "$w" "$g" "$m" "$v"
    done < "$SANAT"
} | column -t -s $'\t' 

printf '\nhylättyjä: ginter %s / myspell %s\n' \
    "$(grep -c . <<< "$G" || true)" "$(grep -c . <<< "$M" || true)"
