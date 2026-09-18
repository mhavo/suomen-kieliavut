#!/usr/bin/env bash
# Kääntää hunspell-sanaston Chromiumin .bdic-muotoon.
# Työkalu (n. 153 MB esikäännettyjä binäärejä) noudetaan ajohetkellä lukitusta
# commitista ja varmennetaan SHA-256-summilla ennen suoritusta.
# Ks. ../docs/convert-dict.md
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLREPO="https://github.com/jankelemen/convert-dict-tool-from-chromium.git"
# Lukittu commit. Skripti suorittaa kolmannen osapuolen esikäännetyn binäärin,
# joten haaran päätä EI seurata: noudettu puu varmennetaan sekä commitin
# tunnisteella että tiedostokohtaisilla SHA-256-summilla (tools/convert-dict.sha256).
TOOLCOMMIT="b78ff3a1cd0aed04fed30c559e2c30bcab07fefc"
SUMS="$REPO/tools/convert-dict.sha256"
WORK="${BDIC_WORKDIR:-${XDG_CACHE_HOME:-$HOME/.cache}/suomen-kieliavut}"
MODE="${1:-frekvenssi}"
# Lokaali vaikuttaa valintaan: awk:n tolower() pienentää ääkköset vain UTF-8
# -lokaalissa, ja pelkkä C tuottaa 14 170 sanuetta erilaisen sanaston.
# C.UTF-8 pakotetaan, jotta tulos ei riipu ajoympäristön kieliasetuksista.
if locale -a 2>/dev/null | grep -qix 'C.utf8\|C.UTF-8'; then
    export LC_ALL=C.UTF-8
elif [ "$(locale charmap 2>/dev/null)" = "UTF-8" ]; then
    echo "==> C.UTF-8 puuttuu; käytetään ympäristön UTF-8-lokaalia" >&2
else
    echo "UTF-8-lokaalia ei löydy. Sanaston valinta olisi väärä (ääkköset)." >&2
    echo "Asenna C.UTF-8 tai aja UTF-8-lokaalissa." >&2
    exit 1
fi
# Suurin sanuemäärä, joka mahtuu .bdic-muotoon tällä valinnalla. Raja ei ole
# pelkkä lukumäärä vaan serialisoidun trien koko, joten se riippuu siitä
# mitkä sanat valitaan — hajanainen valinta täyttää muodon nopeammin kuin
# aakkosellinen alkupää. Mitatut katot: aakkosellinen alkupää ~319 500,
# frekvenssivalinta ks. "build-bdic.sh raja". 245 000 jättää varaa.
N="${N:-245000}"

case "$MODE" in
    -h|--help)
        cat <<'USAGE'
Käyttö: build-bdic.sh [frekvenssi|pituus|myspell|ginter|raja]

  frekvenssi  (oletus) Ginterin sanasto karsittuna niin että se mahtuu
              .bdic:iin. Valintajärjestys: sanan esiintymistiheys vapaassa
              korpuksessa (tools/korpus-frekvenssit.txt), tasapelit sanan
              pituudella. Frekvenssikorpus on ERI kuin arviointikorpus, jottei
              valintaa optimoida testijoukkoa vasten.
  pituus      Sama, mutta kriteerinä pelkkä sananpituus. Ei tarvitse
              frekvenssitiedostoa lainkaan. Varareitti.
  myspell     myspell-fi 0.7 sellaisenaan. VAIN VERTAILUUN, ei jaeltavaksi:
              aineisto on GPL-2.0-only.
  ginter      Ginterin sanasto kokonaan. EI KÄÄNNY — 476 292 sanuetta ylittää
              .bdic-muodon rajan. Mukana vain jotta virheen näkee itse.
  valinta     Kirjoittaa vain karsitun .dic-tiedoston eikä käännä mitään.
              Kriteeri toisena argumenttina, oletus frekvenssi. Tällä voi
              verrata kriteereitä ajamatta convert_dictiä:
              build-bdic.sh valinta pituus
  raja        Etsii binäärihaulla suurimman kääntyvän valinnan. Käyttää
              oletuksena frekvenssikriteeriä; toinen argumentti vaihtaa:
              build-bdic.sh raja pituus

LISENSSI: valintakriteeri EI saa katsoa myspell-fi 0.7:n sanalistaa. Se on
GPL-2.0-only, ja jos karsintakriteeri on sen kuratoitu valinta, tulos on
siitä johdettu teos — jolloin dict/ginter-karsittu/:n ja build/fi-FI.bdic:n
CC0-1.0-merkintä olisi väärä. Ks. LICENSES.md.

Ympäristömuuttujat: N=<sanuemäärä>  BDIC_WORKDIR=<polku>

Työkalu (esikäännetty convert_dict, ~153 MB) noudetaan lukitusta commitista
ja varmennetaan SHA-256-summilla, ks. tools/convert-dict.sha256.
USAGE
        exit 0 ;;
    frekvenssi|pituus|myspell|ginter|raja|valinta) ;;
    *) echo "tuntematon tila: $MODE (ks. --help)" >&2; exit 2 ;;
esac

mkdir -p "$WORK"
# Työkalua ei noudeta lainkaan tilassa "valinta": se tuottaa vain karsitun
# .dic-tiedoston mittausta varten eikä käännä mitään. 153 MB binäärejä on
# turha lataus, kun halutaan verrata kahta karsintakriteeriä keskenään.
if [ "$MODE" != valinta ]; then
    TOOL="$WORK/convert-dict-tool-from-chromium"
    if [ ! -d "$TOOL/.git" ]; then
        echo "==> noudetaan convert_dict (~153 MB) -> $TOOL"
        rm -rf "$TOOL"
        git init -q "$TOOL"
        git -C "$TOOL" remote add origin "$TOOLREPO"
        git -C "$TOOL" fetch -q --depth 1 origin "$TOOLCOMMIT"
        git -C "$TOOL" checkout -q "$TOOLCOMMIT"
    fi

    # Varmenna että välimuistissa on juuri lukittu commit — ei haaran pää.
    have="$(git -C "$TOOL" rev-parse HEAD)"
    if [ "$have" != "$TOOLCOMMIT" ]; then
        echo "==> välimuisti on väärässä commitissa ($have), haetaan lukittu" >&2
        git -C "$TOOL" fetch -q --depth 1 origin "$TOOLCOMMIT"
        git -C "$TOOL" checkout -q "$TOOLCOMMIT"
        git -C "$TOOL" clean -qfd
    fi

    # Summatarkistus on varsinainen portti: se kattaa myös tiedostot, jotka olisi
    # muokattu paikallisesti tai vaihdettu commitin uudelleenkirjoituksella.
    echo "==> tarkistetaan työkalun SHA-256-summat"
    if ! ( cd "$TOOL" && sha256sum -c --quiet "$SUMS" ); then
        echo >&2
        echo "TYÖKALUN TARKISTUSSUMMAT EIVÄT TÄSMÄÄ." >&2
        echo "  $TOOL" >&2
        echo "  Odotettu commit: $TOOLCOMMIT" >&2
        echo "  Käännöstä ei ajeta. Poista välimuisti ja yritä uudelleen, tai" >&2
        echo "  päivitä tools/convert-dict.sha256 jos vaihdat työkaluversiota." >&2
        exit 1
    fi

    chmod +x "$TOOL/convert_dict"
fi


GIN_AFF="$REPO/dict/ginter/fi_FI.aff"
GIN_DIC="$REPO/dict/ginter/fi_FI.dic"

# --- valinta ---------------------------------------------------------------
# convert_dict vertaa lopputulosta syötteeseen sen omassa järjestyksessä.
# Uudelleenlajiteltu .dic kaatuu virheeseen "Index doesn't match, word #...",
# joten valitut rivit on tulostettava ALKUPERÄISESSÄ järjestyksessä.
#
# Kaksi kriteeriä, molemmat lisenssipuhtaita:
#
#   frekvenssi  Sanan esiintymistiheys vapaassa korpuksessa. Ginterin .dic on
#               AAKKOSJÄRJESTYKSESSÄ, joten rivinumero ei ole frekvenssisija —
#               frekvenssi on laskettava erikseen. Korpuksen ulkopuolelle
#               jäävät sanat järjestetään pituuden mukaan, eli valinta on
#               "frekvenssikärki + lyhyt häntä".
#   pituus      Pelkkä sananpituus. Suomessa pituus korreloi harvinaisuuden
#               kanssa, joten lyhyet säilyvät.
#
# Kumpikaan ei katso myspell-fi 0.7:ää: se vuotaisi GPL-2.0-only-ehdon
# CC0-merkittyyn tulokseen.
FREKVENSSIT="${FREKVENSSIT:-$REPO/tools/korpus-frekvenssit.txt}"

valitse() { # $1 = montako riviä, $2 = kriteeri (frekvenssi|pituus)
    local maara="$1" kriteeri="$2"
    if [ "$kriteeri" = frekvenssi ]; then
        [ -f "$FREKVENSSIT" ] || {
            echo "frekvenssitiedostoa ei löydy: $FREKVENSSIT" >&2
            echo "aja 'build-bdic.sh pituus' tai aseta FREKVENSSIT=<polku>" >&2
            exit 1
        }
        awk -F'\t' -v OFS='\t' '
            NR==FNR { f[$1] = $2 + 0; next }
            {
                split($0, kentat, "/")
                lemma = kentat[1]
                lw = tolower(lemma)
                # sort -n lajittelee nousevasti, joten frekvenssi negatiivisena:
                # yleisin ensin. Tuntematon sana saa 0:n eli jää hännille.
                print -f[lw], length(lemma), FNR, $0
            }' "$FREKVENSSIT" <(tail -n +2 "$GIN_DIC") \
        | sort -k1,1n -k2,2n -k3,3n > "$WORK/ranked.tmp"
    else
        awk -F'\t' -v OFS='\t' '
            {
                split($0, kentat, "/")
                lemma = kentat[1]
                print 0, length(lemma), FNR, $0
            }' <(tail -n +2 "$GIN_DIC") \
        | sort -k1,1n -k2,2n -k3,3n > "$WORK/ranked.tmp"
    fi
    # head keskellä putkea antaisi sortille SIGPIPEn, jonka pipefail tulkitsee
    # virheeksi — siksi välitiedosto. Lopuksi takaisin alkuperäiseen
    # rivijärjestykseen (kenttä 3), ks. convert_dictin vaatimus yllä.
    head -n "$maara" "$WORK/ranked.tmp" | cut -f3- | sort -k1,1n | cut -f2-
}

BUILD="$WORK/build-$MODE"
rm -rf "$BUILD"; mkdir -p "$BUILD"

case "$MODE" in
    myspell)
        cp "$REPO/dict/myspell-fi-0.7/fi-FI.aff" "$BUILD/fi-FI.aff"
        cp "$REPO/dict/myspell-fi-0.7/fi-FI.dic" "$BUILD/fi-FI.dic" ;;
    ginter)
        cp "$GIN_AFF" "$BUILD/fi-FI.aff"; cp "$GIN_DIC" "$BUILD/fi-FI.dic" ;;
    frekvenssi|pituus|raja|valinta)
        cp "$GIN_AFF" "$BUILD/fi-FI.aff" ;;
esac
cp "$REPO/dict/ginter/fi_FI.dic_delta" "$BUILD/fi-FI.dic_delta"

# --- käännös ---------------------------------------------------------------
kaanna() { # tiedostot valmiina $BUILD:issa; palauttaa 0 jos syntyi .bdic
    cp "$BUILD"/fi-FI.aff "$BUILD"/fi-FI.dic "$BUILD"/fi-FI.dic_delta "$TOOL/"
    rm -f "$TOOL/fi-FI.bdic"
    ( cd "$TOOL" && LD_LIBRARY_PATH=. ./convert_dict fi-FI 2>&1 | tail -2 )
    [ -s "$TOOL/fi-FI.bdic" ]
}

if [ "$MODE" = raja ]; then
    RAJA_KRITEERI="${2:-frekvenssi}"
    echo "==> etsitään suurin kääntyvä valinta (kriteeri: $RAJA_KRITEERI)"
    lo=100000; hi=400000
    while [ $((hi-lo)) -gt 2000 ]; do
        mid=$(((lo+hi)/2))
        valitse "$mid" "$RAJA_KRITEERI" | { echo "$mid"; cat; } > "$BUILD/fi-FI.dic"
        if kaanna >/dev/null 2>&1; then lo=$mid; else hi=$mid; fi
        printf '    %d..%d\n' "$lo" "$hi"
    done
    echo "==> suurin kääntyvä: $lo sanuetta"
    exit 0
fi

if [ "$MODE" = valinta ]; then
    KRITEERI="${2:-frekvenssi}"
    echo "==> valitaan $N sanuetta ${GIN_DIC##*/}:stä (kriteeri: $KRITEERI)"
    valitse "$N" "$KRITEERI" | { echo "$N"; cat; } > "$BUILD/fi-FI.dic"
    echo "==> valmis, ei käännetty: $BUILD/fi-FI.dic"
    exit 0
fi

if [ "$MODE" = frekvenssi ] || [ "$MODE" = pituus ]; then
    echo "==> valitaan $N sanuetta ${GIN_DIC##*/}:stä (kriteeri: $MODE)"
    valitse "$N" "$MODE" | { echo "$N"; cat; } > "$BUILD/fi-FI.dic"
fi

echo "==> käännetään ($MODE, $(( $(wc -l < "$BUILD/fi-FI.dic") - 1 )) sanuetta)"
echo "    .aff merkistö: $(head -1 "$BUILD/fi-FI.aff")"
if ! kaanna; then
    echo >&2
    echo "KÄÄNNÖS EPÄONNISTUI." >&2
    echo "  'Found the end before we expected' = sanasto ylittää .bdic-muodon" >&2
    echo "  rajan. Aja 'build-bdic.sh raja' tai pienennä: N=200000 $0 $MODE" >&2
    echo "  'Index doesn't match, word #X' = .dic on väärässä järjestyksessä." >&2
    exit 1
fi

cp "$TOOL/fi-FI.bdic" "$BUILD/fi-FI.bdic"
echo "==> valmis: $BUILD/fi-FI.bdic ($(du -h "$BUILD/fi-FI.bdic" | cut -f1))"
od -A d -t x1z -N 8 "$BUILD/fi-FI.bdic" | sed 's/^/    /'
echo
echo "asennus:"
echo "  install -Dm644 $BUILD/fi-FI.bdic ~/.config/chromium/Dictionaries/fi-FI-10-1.bdic"
