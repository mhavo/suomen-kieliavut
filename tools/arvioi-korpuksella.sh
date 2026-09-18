#!/usr/bin/env bash
# Mittaa sanastovaihtoehtojen kattavuuden tools/korpus/-osakorpuksilla.
#
# MIKSI TÄMÄ KORVASI VANHAN VERSION
#
# Vanha skripti raportoi yhden luvun per sanasto, mitattuna 1119 sanan yhden
# lähteen korpuksella. Sen otoskoko antoi ±1,2 prosenttiyksikön
# luottamusvälin 95 %:n tuntumassa, mikä teki yhden desimaalin raportoinnista
# harhaanjohtavaa — ja yksi lähde ei kerro mitään yleistettävyydestä. Lähteen
# alkuperä ja lisenssi eivät myöskään olleet luotettavasti selvitettävissä.
#
# Tämä versio raportoi:
#   - kattavuuden osakorpuksittain JA yhteensä
#   - uniikit sanat (types) ja esiintymät (tokens) erikseen. Token-painotettu
#     kattavuus on se, minkä käyttäjä kokee kirjoittaessaan; type-kattavuus on
#     se, mitä vanha skripti mittasi. Molemmat ovat kiinnostavia, eri syistä.
#   - otoskoon ja 95 %:n Wilson-luottamusvälin jokaiselle luvulle
#   - OOV-otoksen: satunnaiset hylyt tiedostoon, jotta hylkyjen laatu on
#     tarkistettavissa käsin (typo / vierassana / aito puute)
#
# KORPUKSEN MUOTO: tools/korpus/*.txt, rivi = "sana<TAB>esiintymät".
# Esiintymämäärä on 1 niissä osakorpuksissa, joista on saatavilla vain
# tyyppilista (tekninen.txt). Ks. tools/korpus/LUE.md.
#
# KEHÄPÄÄTELMÄ, JOKA ON PIDETTÄVÄ MIELESSÄ: Ginterin sanasto on rakennettu
# suodattamalla parsebank-korpus Voikolla, joten Ginterin sanat ovat
# määritelmällisesti Voikon hyväksymien muotojen osajoukko eikä Voikko voi
# juuri hävitä tässä vertailussa. Tämä ei tee johtopäätöstä vääräksi — syy
# (morfologinen analyysi vs. sanalista) on riippumaton mittauksesta — mutta
# luku ei ole riippumaton todiste. Ks. docs/sanastot.md.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KORPUSHAK="$REPO/tools/korpus"
OOV_HAK=""
OOV_MAARA=100

usage() {
    cat <<'USAGE'
Käyttö: arvioi-korpuksella.sh [valitsimet]

  --korpus <hakemisto>   osakorpusten hakemisto, oletus tools/korpus
  --oov <hakemisto>      kirjoita OOV-otos sanastoittain tähän hakemistoon
  --oov-maara <n>        otoksen koko, oletus 100
  -h, --help             tämä ohje
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --korpus)     KORPUSHAK="${2:?--korpus vaatii hakemiston}"; shift ;;
        --oov)        OOV_HAK="${2:?--oov vaatii hakemiston}"; shift ;;
        --oov-maara)  OOV_MAARA="${2:?--oov-maara vaatii luvun}"; shift ;;
        -h|--help)    usage; exit 0 ;;
        *)            echo "tuntematon valitsin: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

[ -d "$KORPUSHAK" ] || { echo "korpushakemistoa ei ole: $KORPUSHAK" >&2; exit 1; }
mapfile -t OSAKORPUKSET < <(find "$KORPUSHAK" -maxdepth 1 -name '*.txt' | sort)
[ ${#OSAKORPUKSET[@]} -gt 0 ] || { echo "ei osakorpuksia: $KORPUSHAK/*.txt" >&2; exit 1; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# hunspell vaatii .aff:n ja .dic:n samannimisinä samasta hakemistosta.
cp "$REPO/dict/ginter/fi_FI.aff"            "$WORK/ginter.aff"
cp "$REPO/dict/ginter/fi_FI.dic"            "$WORK/ginter.dic"
# myspell-fi 0.7 on ISO8859-1. Se on käännettävä UTF-8:ksi ennen mittausta,
# ei mukavuussyistä vaan koska mittaus on muuten harhainen: hunspell kääntää
# UTF-8-syötteen sanaston merkistöön, ja sana jota ei voi esittää Latin-1:ssä
# (esim. "šakki") ei päädy hylkyihin EIKÄ hyväksyttyihin — se katoaa
# tuloksesta kokonaan ja nostaa myspellin näennäistä kattavuutta. Oire on
# stderrissä rivi "error - iconv: UTF-8 -> ISO8859-1"; hunspell palauttaa
# silti 0, joten pipefail ei nappaa tätä. Sama muunnos tehdään
# tools/build-oxt.sh:ssa.
iconv -f ISO8859-1 -t UTF-8 "$REPO/dict/myspell-fi-0.7/fi-FI.dic" > "$WORK/myspell.dic"
iconv -f ISO8859-1 -t UTF-8 "$REPO/dict/myspell-fi-0.7/fi-FI.aff" \
    | sed '1s/^SET ISO8859-1$/SET UTF-8/' > "$WORK/myspell.aff"
if [ "$(head -1 "$WORK/myspell.aff")" != "SET UTF-8" ]; then
    echo "myspell-fi:n .aff:n ensimmäinen rivi ei ollut SET ISO8859-1 — tarkista lähde" >&2
    exit 1
fi
cp "$REPO/dict/ginter/fi_FI.aff"            "$WORK/karsittu.aff"
cp "$REPO/dict/ginter-karsittu/fi_FI.dic"   "$WORK/karsittu.dic"

# Yhdistetty tyyppilista: sana -> yhteenlaskettu esiintymämäärä + osakorpukset.
# Oikoluku ajetaan kerran koko tyyppijoukolle, ei kerran per osakorpus —
# hunspell on hidas ja tulos on sanakohtainen, ei korpuskohtainen.
: > "$WORK/kaikki-tyypit.txt"
for f in "${OSAKORPUKSET[@]}"; do
    cut -f1 "$f"
done | sort -u > "$WORK/kaikki-tyypit.txt"

TYYPPEJA=$(wc -l < "$WORK/kaikki-tyypit.txt")
echo "==> $TYYPPEJA uniikkia sanaa ${#OSAKORPUKSET[@]} osakorpuksesta" >&2

aja_sanasto() {
    local nimi="$1"
    case "$nimi" in
        voikko)
            if command -v voikkospell >/dev/null; then
                # Rivin muoto on "W: <sana>" eli sana alkaa merkistä 4.
                # sort -u ei ole koristelua: voikkospell 4.3.3 tulostaa
                # syötteen VIIMEISEN rivin kahdesti (todettu tällä koneella),
                # ja ilman deduplikointia hylkyjen määrä kasvaisi yhdellä.
                voikkospell < "$WORK/kaikki-tyypit.txt" \
                    | awk '/^W: /{print substr($0,4)}' \
                    | sort -u > "$WORK/hylyt-$nimi.txt"
            else
                return 1
            fi ;;
        *)
            hunspell -d "$WORK/$nimi" -i UTF-8 -l < "$WORK/kaikki-tyypit.txt" \
                | sort -u > "$WORK/hylyt-$nimi.txt" ;;
    esac
}

declare -a SANASTOT=()
for v in ginter karsittu myspell voikko; do
    if aja_sanasto "$v"; then
        SANASTOT+=("$v")
        echo "    $v: $(wc -l < "$WORK/hylyt-$v.txt") hylkyä" >&2
    else
        echo "    $v: ohitettu (työkalu puuttuu)" >&2
    fi
done

if [ -n "$OOV_HAK" ]; then
    mkdir -p "$OOV_HAK"
    for v in "${SANASTOT[@]}"; do
        shuf -n "$OOV_MAARA" "$WORK/hylyt-$v.txt" | sort > "$OOV_HAK/oov-$v.txt"
    done
    echo "==> OOV-otokset ($OOV_MAARA sanaa/sanasto): $OOV_HAK" >&2
fi

python3 - "$WORK" "$KORPUSHAK" "${SANASTOT[@]}" <<'PY'
import glob, math, os, sys

work, korpushak = sys.argv[1], sys.argv[2]
sanastot = sys.argv[3:]

NIMET = {
    "ginter":   "Ginter kokonaan (ei käänny .bdic:iin)",
    "karsittu": "Ginter karsittu (= build/fi-FI.bdic)",
    "myspell":  "myspell-fi 0.7",
    "voikko":   "Voikko (ei selaimiin)",
}

def wilson(k, n):
    """95 %:n Wilson-luottamusväli osuudelle. Normaaliapproksimaatio antaisi
    kattavuuden ollessa lähellä 100 %:a välin, joka ylittää 100 %."""
    if n == 0:
        return (0.0, 0.0)
    z = 1.959963985
    p = k / n
    d = 1 + z * z / n
    keskus = (p + z * z / (2 * n)) / d
    puolikas = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return (max(0.0, keskus - puolikas) * 100, min(1.0, keskus + puolikas) * 100)

# Osakorpukset: nimi -> {sana: esiintymät}
osakorpukset = {}
for polku in sorted(glob.glob(os.path.join(korpushak, "*.txt"))):
    nimi = os.path.splitext(os.path.basename(polku))[0]
    d = {}
    with open(polku, encoding="utf-8") as f:
        for rivi in f:
            rivi = rivi.rstrip("\n")
            if not rivi:
                continue
            osat = rivi.split("\t")
            sana = osat[0]
            maara = int(osat[1]) if len(osat) > 1 else 1
            d[sana] = d.get(sana, 0) + maara
    osakorpukset[nimi] = d

hylyt = {}
for v in sanastot:
    with open(os.path.join(work, f"hylyt-{v}.txt"), encoding="utf-8") as f:
        hylyt[v] = {r.strip() for r in f if r.strip()}

# Yhteensä-sarake: kaikkien osakorpusten unioni, esiintymät summattuna.
yhteensa = {}
for d in osakorpukset.values():
    for sana, maara in d.items():
        yhteensa[sana] = yhteensa.get(sana, 0) + maara

sarakkeet = list(osakorpukset.items()) + [("YHTEENSÄ", yhteensa)]

def rivi(solut, leveydet):
    return "  ".join(s.ljust(w) for s, w in zip(solut, leveydet)).rstrip()

for mitta in ("types", "tokens"):
    otsikko = ("UNIIKIT SANAT (types) — kattavuus %, 95 %:n Wilson-väli"
               if mitta == "types" else
               "ESIINTYMÄT (tokens) — kattavuus %, 95 %:n Wilson-väli")
    print()
    print(otsikko)
    print("=" * len(otsikko))

    taulu = [["sanasto"] + [n for n, _ in sarakkeet]]
    for v in sanastot:
        r = [NIMET.get(v, v)]
        for _, d in sarakkeet:
            if mitta == "types":
                n = len(d)
                k = sum(1 for s in d if s not in hylyt[v])
            else:
                n = sum(d.values())
                k = sum(m for s, m in d.items() if s not in hylyt[v])
            ala, yla = wilson(k, n)
            r.append(f"{100*k/n:.1f} [{ala:.1f}–{yla:.1f}]" if n else "—")
        taulu.append(r)

    koko = ["otoskoko n"]
    for _, d in sarakkeet:
        koko.append(str(len(d) if mitta == "types" else sum(d.values())))
    taulu.append(koko)

    leveydet = [max(len(r[i]) for r in taulu) for i in range(len(taulu[0]))]
    print(rivi(taulu[0], leveydet))
    print(rivi(["-" * w for w in leveydet], leveydet))
    for r in taulu[1:]:
        print(rivi(r, leveydet))

# Koneluettava yhteenveto CI-porttia varten. Muoto:
#   KONE<TAB>sanasto<TAB>mitta<TAB>osakorpus<TAB>kattavuus<TAB>n
# Taulukon muotoilu saa muuttua vapaasti ilman että portti rikkoutuu.
for mitta in ("types", "tokens"):
    for v in sanastot:
        for nimi, d in sarakkeet:
            if mitta == "types":
                n = len(d)
                k = sum(1 for s in d if s not in hylyt[v])
            else:
                n = sum(d.values())
                k = sum(m for s, m in d.items() if s not in hylyt[v])
            if n:
                print(f"KONE\t{v}\t{mitta}\t{nimi}\t{100*k/n:.1f}\t{n}")

print()
print("Luottamusväli koskee otantavirhettä, ei korpuksen edustavuutta.")
print("Token-kattavuuden n on esiintymien määrä; esiintymät eivät ole")
print("riippumattomia, joten sen väli on todellista kapeampi.")
PY
