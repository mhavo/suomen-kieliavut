#!/usr/bin/env bash
# Puhtaan asennuksen testaus Ubuntu- ja Arch-konteissa.
#
# Ajo:  sudo testi/testaa-puhtaalta.sh
#
# Docker-palvelu on tällä koneella pois päältä eikä käyttäjä ole docker-
# ryhmässä (§1.4), joten ajopiste käynnistää palvelun itse ja vaatii rootin.
set -euo pipefail

TESTI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$TESTI/.." && pwd)"

KUTSU=("$0" "$@")
DISTROT=(ubuntu arch)
SKENAARIOT=(01 02 03 04 05 06)
RAKENNA=0

usage() {
    cat <<'USAGE'
Käyttö: sudo testi/testaa-puhtaalta.sh [valitsimet]

Ajaa asennusskenaariot puhtaissa Ubuntu- ja Arch-konteissa. Repo liitetään
kirjoitussuojattuna (R1); jokainen skenaario saa oman kertakäyttöisen
kontin (R4).

  --distro <ubuntu|arch>   vain yksi distro
  --skenaario <01..06>     vain yksi skenaario, molemmissa distroissa
  --rakenna                rakenna kuvat uudelleen vaikka ne olisivat olemassa
  -h, --help               tämä ohje

MITÄ TÄMÄ EI TESTAA (R6): selain ei käynnisty missään vaiheessa eikä
punaista alleviivausta havainnoida. Harness todentaa, että sanasto on
paikallaan ja että asetus osoittaa siihen — se on ehto jolla selaimen
oikoluku toimii, mutta se on päättely, ei havainto.

Skenaariot:
  01  install.sh paikallista file://-julkaisua vastaan
  02  install.sh oikeaa GitHub-julkaisua vastaan (SKIP jos verkkoa ei ole)
  03  tools/asenna.sh repoklonista
  04  pelkät profiilityökalut, kaksi Firefox- ja kolme Chromium-profiilia
  05  install.sh --vain hyphen,oxt,enchant

Tulokset: testi/tulokset/<aikaleima>/<distro>-<skenaario>.log
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --distro)    DISTROT=("${2:?--distro vaatii arvon}"); shift ;;
        --skenaario) SKENAARIOT=("${2:?--skenaario vaatii numeron}"); shift ;;
        --rakenna)   RAKENNA=1 ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "tuntematon valitsin: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }

# Kirjoitusvirhe valitsimessa ei saa näyttää tyhjältä ajolta.
case "${DISTROT[0]}" in ubuntu|arch) ;; *) echo "tuntematon distro: ${DISTROT[0]}" >&2; exit 2 ;; esac
for nro in "${SKENAARIOT[@]}"; do
    loytyi=0
    for ehdokas in "$TESTI/skenaariot/$nro"-*.sh; do
        [ -f "$ehdokas" ] && loytyi=1
    done
    [ "$loytyi" -eq 1 ] || { echo "tuntematon skenaario: $nro" >&2; exit 2; }
done

# --- docker -----------------------------------------------------------------
command -v docker >/dev/null || { echo "docker puuttuu" >&2; exit 1; }
if ! docker info >/dev/null 2>&1; then
    if [ "$(id -u)" -ne 0 ]; then
        echo "docker ei vastaa. Aja tämä rootina: sudo ${KUTSU[*]}" >&2
        exit 1
    fi
    say "docker-palvelu ei ole käynnissä — käynnistetään"
    systemctl start docker || {
        echo "docker-palvelun käynnistys epäonnistui. Tarkista: systemctl status docker" >&2
        exit 1; }
    for _ in $(seq 30); do docker info >/dev/null 2>&1 && break; sleep 1; done
    docker info >/dev/null 2>&1 || {
        echo "docker ei vastannut käynnistyksen jälkeen" >&2; exit 1; }
fi

# --- kuvat ------------------------------------------------------------------
kuvan_nimi() { printf 'suomen-kieliavut-testi:%s\n' "$1"; }

rakenna_kuva() {
    local distro="$1" kuva
    kuva="$(kuvan_nimi "$distro")"
    if [ "$RAKENNA" -eq 0 ] && docker image inspect "$kuva" >/dev/null 2>&1; then
        say "kuva $kuva on jo olemassa"
        return 0
    fi
    say "rakennetaan $kuva"
    docker build -f "$TESTI/Dockerfile.$distro" -t "$kuva" "$TESTI"
}

# --- tulokset ---------------------------------------------------------------
AIKALEIMA="$(date +%F_%H%M%S)"
TULOKSET="$TESTI/tulokset/$AIKALEIMA"
mkdir -p "$TULOKSET"

# Sudon alta ajettuna lokit jäisivät rootin omistukseen keskelle käyttäjän
# työpuuta. Palautetaan ne kutsujalle heti hakemistosta alkaen.
palauta_omistus() {
    [ -n "${SUDO_UID:-}" ] || return 0
    chown -R "$SUDO_UID:${SUDO_GID:-$SUDO_UID}" "$TESTI/tulokset"
}
trap palauta_omistus EXIT

declare -A TULOS=()

aja_skenaario() { # aja_skenaario <distro> <numero>
    local distro="$1" nro="$2" kuva skripti loki koodi=0
    kuva="$(kuvan_nimi "$distro")"
    skripti="$(cd "$TESTI/skenaariot" && echo "$nro"-*.sh)"
    loki="$TULOKSET/$distro-$nro.log"

    say "$distro / skenaario $nro ($skripti)"
    # Ei -t: skenaariot jotka tarvitsevat päätteen varaavat sen itse
    # script(1):llä (§3.3, testi/tarkista.sh: pty_aja).
    docker run --rm \
        --name "kieliavut-testi-$distro-$nro" \
        -v "$REPO:/repo:ro" \
        "$kuva" \
        bash "/repo/testi/skenaariot/$skripti" \
        > "$loki" 2>&1 || koodi=$?

    case "$koodi" in
        0) TULOS["$distro/$nro"]="LÄPI" ;;
        1) TULOS["$distro/$nro"]="EI" ;;
        3) TULOS["$distro/$nro"]="SKIP" ;;
        # §7.3: kontin kuolema tai luotaimen aikakatkaisu on eri asia kuin
        # väitteen kaatuminen — se lähettää ylläpitäjän eri paikkaan.
        *) TULOS["$distro/$nro"]="VIRHE($koodi)" ;;
    esac
    printf '    %s  %s\n' "${TULOS["$distro/$nro"]}" "$loki"
    tail -3 "$loki" | sed 's/^/      /'
}

for distro in "${DISTROT[@]}"; do
    rakenna_kuva "$distro"
done

for distro in "${DISTROT[@]}"; do
    for nro in "${SKENAARIOT[@]}"; do
        aja_skenaario "$distro" "$nro"
    done
done

# --- matriisi ---------------------------------------------------------------
echo
say "Tulokset"
printf '    %-10s' 'distro'
for nro in "${SKENAARIOT[@]}"; do printf '%-12s' "$nro"; done
printf '\n'
VIRHEITA=0
for distro in "${DISTROT[@]}"; do
    printf '    %-10s' "$distro"
    for nro in "${SKENAARIOT[@]}"; do
        tila="${TULOS["$distro/$nro"]:-?}"
        printf '%-12s' "$tila"
        case "$tila" in LÄPI|SKIP) ;; *) VIRHEITA=$((VIRHEITA + 1)) ;; esac
    done
    printf '\n'
done
echo
printf '    lokit: %s\n' "$TULOKSET"

# §7.1: SKIP ei kaada ajoa, kaikki muu kaataa.
[ "$VIRHEITA" -eq 0 ] || { say "$VIRHEITA ajoa ei mennyt läpi"; exit 1; }
say "Kaikki läpi."
