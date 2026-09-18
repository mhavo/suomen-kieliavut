#!/usr/bin/env bash
# Suomen kieliavut — etäasennin.
#
#   curl -fsSL https://github.com/mhavo/suomen-kieliavut/raw/v0.9/install.sh | bash
#
# Sama työ kuin tools/asenna.sh:lla, mutta ilman git-klonia: sanastot noudetaan
# GitHub-julkaisun liitetiedostoina ja varmennetaan SHA-256-summilla, jotka on
# upotettu tähän skriptiin. Ks. ../README.md ja SHA256SUMS.
#
# TURVALLISUUS PUTKESSA: "curl | bash" antaa bashille skriptin syötevirtana, ja
# bash lukee sitä palasina suorittaen jo luettua. Jos yhteys katkeaa kesken, se
# suorittaisi puolikkaan skriptin — pahimmillaan komennon, jonka argumentit
# jäivät pois. Suoja on tavanomainen: koko logiikka on funktion sisällä ja
# funktiota kutsutaan vasta tiedoston viimeisellä rivillä. Bash ei suorita
# funktion runkoa ennen kuin sen sulkeva "}" on luettu, joten katkennut lataus
# ei koskaan pääse kutsuriville.
set -euo pipefail

# Kaikki lataus-URL:t johdetaan REPO_OMISTAJAsta, REPO_NIMEstä ja tagista. Jos repo siirtyy
# toiselle omistajalle tai julkaisutagi vaihtuu, tämä on ainoa muutettava kohta
# — mutta huomaa, että .oxt:n tiedostonimi sisältää versionumeron (ks. oxt-osa
# alempana), joten uusi tagi edellyttää myös uutta pakettia ja uusia summia.
REPO_OMISTAJA="mhavo"
REPO_NIMI="suomen-kieliavut"
# LibreOffice-laajennuksen tunniste; unopkg tunnistaa laajennuksen tällä.
OXT_TUNNUS="fi.hunspell.suomen-kieliavut"
JULKAISU_TAGI="v0.9"

# Julkaisun liitetiedostot ovat GitHubissa litteänä listana (ei build/-polkua).
# JULKAISU_URL on ohitettavissa ympäristömuuttujalla: sitä tarvitaan skriptin
# omassa testauksessa, jossa "julkaisuna" on paikallinen file://-hakemisto.
JULKAISU_URL="${JULKAISU_URL:-https://github.com/$REPO_OMISTAJA/$REPO_NIMI/releases/download/$JULKAISU_TAGI}"

# Asentimen oma osoite. Tarvitaan JAI-viesteihin, jotka neuvovat ajamaan
# jonkin osan uudelleen: putkessa ajettu skripti ei tiedä omaa polkuaan.
ASENNIN_URL="https://github.com/$REPO_OMISTAJA/$REPO_NIMI/raw/$JULKAISU_TAGI/install.sh"

# SHA-256-summat julkaisun liitetiedostoille. Nämä ovat repon SHA256SUMS:n
# arvoja sellaisenaan (vain polku on riisuttu tiedostonimeksi).
#
# Summantarkistus EI ole tässä valinnainen mukavuus. "curl | bash" -asennin joka
# hakee binäärin verkosta tarkistamatta sitä on turvallisuusongelma: välimies tai
# kaapattu julkaisu saa kirjoittaa mitä tahansa käyttäjän profiiliin. Siksi
# jokainen tiedosto varmennetaan ennen kuin mitään kirjoitetaan levylle, ja
# epäsuhta on ehdoton "exit 1".
SUMMA_fi_FI_bdic="87aa3a9dde3a1354e3409401cd4c3d70f65a80dd71c40cfb5e54f7d41430a7eb"      # build/fi-FI.bdic
SUMMA_fi_utf8_spl="eccc5b95edb4f49ca3ef9a322b40e2831d5919016eaa8bda57afed924cb91327"     # build/fi.utf-8.spl
SUMMA_fi_spell_xpi="95ded62bc3de347c91d7c91e8d2abb2405e3475bfb7bf735070db11198131a81"    # build/fi-spell-0.2.xpi
SUMMA_hyph_fi_FI="173ddce030554b91c94f01b5c629eadc224ba8f7ba7d385f6369c6a68565d3a6"      # dict/hyphen/hyph_fi_FI.dic
SUMMA_fi_hunspell_oxt="6706e537ede8c73dff923f879fd80327df44b9e71d44f2f77fb470465ab0266f" # build/fi-hunspell-0.9.oxt
# Chromium-osan työkalut. Nämä eivät ole sanastoja vaan koodia, ja ne noudetaan
# julkaisusta samalla varmennuksella — ks. chromium-osan perustelu alempana.
SUMMA_chromium_ota="4799645d56dc05625dd4ce04b60a6483686da75c383fec547c266ff7d41e22ed"     # tools/chromium-ota-kayttoon.sh
SUMMA_pref_kirjoitus="24bea6dc68a7d6c793250743946a8b9da09c0729e611e1f9fa3c2fc46f935209"   # tools/pref-kirjoitus.py
# Firefox-osa: sama järjestely kuin Chromiumilla. Työkalut kirjoittavat
# profiilin prefs.js:ään, ja sanastona on Ginterin lähdepari sellaisenaan —
# Firefox lukee .aff + .dic -parin suoraan hakemistosta.
SUMMA_firefox_ota="76c613933906262afde7da7ec0684c7b72a6b0c9da8c143b27351710fc149e0b"      # tools/firefox-ota-kayttoon.sh
SUMMA_prefs_js="70c060c8c3030d36dab990de8ead8bd8941fd1ac655e89ea075ea4e437002c39"         # tools/prefs-js-kirjoitus.py
SUMMA_fi_FI_aff="027d87effa5c4c629e912d22e052d68fba450bd2849401f5459a3da09b86723d"        # dict/ginter/fi_FI.aff
SUMMA_fi_FI_dic="7015bf1eba98f52f29428117687e08d657ffc189c13960734ff3083d572c98db"        # dict/ginter/fi_FI.dic
# Rivin lopun kommentti kertoo, minkä repon tiedoston summa kyseinen rivi on.
# Se ei ole pelkkää dokumentaatiota: CI:n työ "summat" lukee sen ja vaatii, että
# SHA256SUMS sisältää täsmälleen tämän summan JUURI tuolle tiedostolle. Ilman
# tiedostonimeä portti hyväksyisi myös väärään muuttujaan kopioidun summan.
#
# Nämä summat ovat sama totuus kuin repon SHA256SUMS, kirjoitettuna toiseen
# paikkaan — etäasennin ei voi lukea repon tiedostoa, koska se ajetaan ilman
# klonia. Kaksi kopiota voi erkaantua, ja erkaantuminen näyttäisi käyttäjälle
# hyökkäykseltä ("SHA-256 EI TÄSMÄÄ") vaikka kyse olisi unohduksesta.
# Siksi portti kaatuu erosta.

# Onko .oxt jo asennettu tälle käyttäjälle.
#
# ÄLÄ kirjoita tätä muodossa `unopkg list | grep -q ...`. grep -q lopettaa
# ensimmäiseen osumaan ja sulkee putken, jolloin unopkg saa SIGPIPEn ja kuolee
# ENNEN kuin se ehtii poistaa oman lukkotiedostonsa
# ~/.config/libreoffice/4/.lock. Jäljelle jäävä kuollut lukko estää kaikki
# myöhemmät unopkg-ajot virheeseen "the lock file indicates it is already
# running" — myös käyttäjän omat. Todettu tässä repossa 2026-09-16.
#
# Siksi ulostulo luetaan ensin kokonaan muuttujaan ja vasta sitten haetaan.
unopkg_on_asennettu() {
    local lista
    lista="$(unopkg list 2>/dev/null || true)"
    case "$lista" in
        *"$OXT_TUNNUS"*) return 0 ;;
        *) return 1 ;;
    esac
}

asennin() {
    local FORCE=0 VAIN_ANNETTU=0 KAIKKI_PROFIILIT=0
    # Oletusvalinta on tarkoituksella suppeampi kuin tools/asenna.sh:ssa:
    # etäasennin ei saa yllättää sudo-kyselyllä. Kotihakemistoon menevät osat
    # ovat päällä, /usr/share-hakemistoon kirjoittava "hyphen" ei.
    # DO_OXT=0: hunspell-sanastolaajennus on VARAREITTI, ei Voikon korvaaja.
    # Oletusajossa se toisi LibreOfficeen toisen, heikomman tarjoajan (88,0 %
    # vastaan Voikon 95,0 %, eikä kielentarkistusta) Voikon rinnalle — tasan se
    # mitä repo muualla neuvoo välttämään. Tarpeen vain Flatpak-/Snap-
    # LibreOfficessa tai jos voikko-libreoffice hajoaa: --vain oxt.
    # DO_HYPHEN=0 omasta syystään: se on ainoa osa joka vaatii sudon.
    local DO_VOIKKO=1 DO_HYPHEN=0 DO_CHROMIUM=1 DO_NVIM=1 DO_ENCHANT=0 DO_FIREFOX=1 DO_OXT=0

    usage() {
        cat <<'USAGE'
Käyttö: install.sh [valitsimet]

Noutaa sanastot GitHub-julkaisusta, varmentaa SHA-256:lla ja asentaa ne.
Ilman valitsimia asentaa vain käyttäjän omiin hakemistoihin — ei sudoa.

  --vain <osa>[,<osa>...]  vain nämä: voikko hyphen chromium nvim enchant firefox oxt
  --force                  ylikirjoita olemassa olevat sanastot
  --kaikki-profiilit       chromium- ja firefox-osa: aseta oikolukukieli
                           jokaiseen profiiliin, ei vain oletusprofiiliin
  -h, --help               tämä ohje

Osat:
  voikko    kertoo distrolle oikeat paketit ja kysyy luvan asentaa ne
  hyphen    /usr/share/hyphen/hyph_fi_FI.dic            (VAATII SUDON, ei oletuksena)
  chromium  ~/.config/chromium/Dictionaries/fi-3-0.bdic (BDIC_NIMI= ohittaa)
  nvim      ~/.config/nvim/spell/fi.utf-8.spl
  enchant   ~/.config/enchant/enchant.ordering          (EI oletuksena — ks. README)
  firefox   Firefox, Thunderbird ja Betterbird:
            ~/.local/share/suomen-kieliavut/hunspell/ + profiilin prefs.js;
            noutaa lisäksi .xpi:n käsin asennettavaksi (Snap-/Flatpak-versiot)
  oxt       LibreOfficen hunspell-sanastolaajennus (EI oletuksena — varareitti,
            Flatpak/Snap tai rikkinäinen voikko-libreoffice; ks. README)

Ympäristömuuttujat:
  JULKAISU_URL   ohita julkaisun osoite (testaukseen)
  BDIC_NIMI      Chromium-sanaston tiedostonimi, oletus fi-3-0.bdic
USAGE
    }

    while [ $# -gt 0 ]; do
        case "$1" in
            --force) FORCE=1 ;;
            # Välitetään sellaisenaan chromium- ja firefox-osan työkaluille. Ei oletuksena:
            # kirjoittaminen profiileihin, joita käyttäjä ei maininnut, on
            # hänen päätöksensä eikä asentimen.
            --kaikki-profiilit) KAIKKI_PROFIILIT=1 ;;
            --vain)
                VAIN_ANNETTU=1
                DO_VOIKKO=0 DO_HYPHEN=0 DO_CHROMIUM=0 DO_NVIM=0 DO_ENCHANT=0 DO_FIREFOX=0 DO_OXT=0
                IFS=',' read -ra osat <<< "${2:?--vain vaatii listan}"
                for p in "${osat[@]}"; do
                    case "$p" in
                        voikko) DO_VOIKKO=1 ;; hyphen) DO_HYPHEN=1 ;;
                        chromium) DO_CHROMIUM=1 ;; nvim) DO_NVIM=1 ;;
                        enchant) DO_ENCHANT=1 ;; firefox) DO_FIREFOX=1 ;;
                        oxt) DO_OXT=1 ;;
                        *) echo "tuntematon osa: $p" >&2; exit 2 ;;
                    esac
                done
                shift ;;
            -h|--help) usage; exit 0 ;;
            *) echo "tuntematon valitsin: $1" >&2; usage >&2; exit 2 ;;
        esac
        shift
    done

    say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
    skip() { printf '    ohitetaan: %s\n' "$*"; }
    rivi() { printf '    %s\n' "$*"; }

    # Yhteenvetoa varten. Tulostetaan lopuksi: mitä tuli levylle ja mikä jäi
    # käyttäjän tehtäväksi. Etäasennin on kertakäyttöinen — käyttäjällä ei ole
    # repoa johon palata, joten loppuyhteenvedon on oltava itsenäinen.
    local -a TEHTY=() JAI=()

    # --- riippuvuudet ---------------------------------------------------------
    local NOUTAJA=""
    if command -v curl >/dev/null; then NOUTAJA=curl
    elif command -v wget >/dev/null; then NOUTAJA=wget
    else echo "curl tai wget vaaditaan" >&2; exit 1; fi

    local SUMMAAJA=""
    if command -v sha256sum >/dev/null; then SUMMAAJA=sha256sum
    elif command -v shasum >/dev/null; then SUMMAAJA="shasum -a 256"
    else echo "sha256sum tai shasum vaaditaan — ilman niitä latauksia ei voi varmentaa" >&2; exit 1; fi

    # --- distron tunnistus ----------------------------------------------------
    # Vaikuttaa vain siihen mitä Voikko-paketteja neuvotaan. Selain- ja
    # Neovim-osat ovat käyttäjän kotihakemistossa eivätkä riipu distrosta
    # (ks. docs/arch-vs-debian.md, kohta 6).
    local DISTRO="tuntematon" DISTRO_NIMI="tuntematon"
    if [ -r /etc/os-release ]; then
        # /etc/os-release luetaan aliprosessissa, jotta sen muuttujat (ID, NAME,
        # ...) eivät vuoda tähän skriptiin. Kolme kenttää yhdellä luennalla.
        local osrel=""
        # shellcheck disable=SC1091  # tiedosto on olemassa vasta ajohetkellä
        osrel="$(. /etc/os-release >/dev/null 2>&1 &&
                 printf '%s\n%s\n%s' "${PRETTY_NAME:-${NAME:-tuntematon}}" "${ID:-}" "${ID_LIKE:-}")"
        DISTRO_NIMI="$(printf '%s' "$osrel" | sed -n 1p)"
        case " $(printf '%s' "$osrel" | sed -n 2p) $(printf '%s' "$osrel" | sed -n 3p) " in
            *" arch "*)                 DISTRO="arch" ;;
            *" debian "*|*" ubuntu "*)  DISTRO="debian" ;;
        esac
    fi

    # --- lataus ja varmennus --------------------------------------------------
    local TYOHAK=""
    TYOHAK="$(mktemp -d)"
    # Väliaikaishakemisto siivotaan aina, myös virhetilanteessa: varmentamaton
    # tai hylätty tiedosto ei saa jäädä levylle harhauttamaan.
    # Polku lavennetaan trappiin heti (kaksoislainausmerkit), koska TYOHAK on
    # funktion local-muuttuja eikä näkyisi enää siinä vaiheessa kun EXIT-trap
    # ajetaan funktion päätyttyä.
    # shellcheck disable=SC2064  # lavennus NYT on tässä tarkoitus, ks. yllä
    trap "rm -rf '$TYOHAK'" EXIT

    nouda() {
        local tiedosto="$1" kohde="$TYOHAK/$1"
        case "$NOUTAJA" in
            curl) curl -fsSL -o "$kohde" "$JULKAISU_URL/$tiedosto" ;;
            wget) wget -q -O "$kohde" "$JULKAISU_URL/$tiedosto" ;;
        esac
    }

    # Nouda + varmenna. Palauttaa polun väliaikaiskopioon vasta kun summa
    # täsmää; muussa tapauksessa lopettaa koko ajon. Huomaa järjestys: tiedosto
    # on tässä vaiheessa vain väliaikaishakemistossa, joten "exit 1" tapahtuu
    # ennen kuin mitään on kirjoitettu käyttäjän hakemistoihin.
    nouda_ja_varmenna() {
        local tiedosto="$1" odotettu="$2" saatu=""
        printf '    nouda %s ... ' "$tiedosto"
        if ! nouda "$tiedosto"; then
            printf 'EPÄONNISTUI\n'
            echo "    lataus ei onnistunut: $JULKAISU_URL/$tiedosto" >&2
            exit 1
        fi
        saatu="$($SUMMAAJA "$TYOHAK/$tiedosto" | cut -d' ' -f1)"
        if [ "$saatu" != "$odotettu" ]; then
            printf 'SHA-256 EI TÄSMÄÄ\n'
            echo "    odotettu: $odotettu" >&2
            echo "    saatu:    $saatu" >&2
            echo "    Tiedostoa EI oteta käyttöön eikä mitään kirjoitettu levylle." >&2
            echo "    Julkaisu voi olla vaihdettu tai lataus vioittunut." >&2
            exit 1
        fi
        printf 'sha256 ok\n'
    }

    # Kopioi paikalleen vain jos kohdetta ei ole (tai --force). Sama semantiikka
    # kuin tools/asenna.sh:n put().
    put() {
        local src="$1" dst="$2"
        if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then
            skip "$dst on jo olemassa (--force ylikirjoittaa)"
            return 1
        fi
        install -Dm644 "$src" "$dst"
        printf '    %s\n' "$dst"
        return 0
    }

    # Kysyy kyllä/ei. Putkessa ajettaessa skriptin oma stdin on skriptiteksti,
    # joten "read" söisi siitä rivejä — siksi luetaan /dev/tty:stä. Jos tty:tä
    # ei ole (CI, cron), vastataan "ei": etäasennin ei saa asentaa
    # järjestelmäpaketteja kysymättä.
    #
    # Päätteen puute testataan AVAAMALLA /dev/tty, ei testillä [ -r /dev/tty ].
    # Jälkimmäinen on access() laitesolmuun: se on tosi aina kun solmu on
    # olemassa — myös prosessissa jolla ei ole ohjauspäätettä lainkaan, jolloin
    # avaus epäonnistuu vasta ENXIO:lla. Väärä testi ei estänyt asennusta
    # (myöhempi read epäonnistui ja paluukoodi jäi oikeaksi), mutta se vaiensi
    # selittävän viestin: käyttäjä näki vain osan ohittuvan syyttä. Mitattu
    # kontissa 2026-09-18. Tilan <> avaus kattaa molemmat käytöt, luvun ja
    # kirjoituksen.
    kysy() {
        local kysymys="$1" vastaus=""
        if ! { true <>/dev/tty; } 2>/dev/null; then
            printf '    (ei päätettä — ei kysytä, ohitetaan)\n'
            return 1
        fi
        printf '    %s [k/e] ' "$kysymys" > /dev/tty
        read -r vastaus < /dev/tty || return 1
        case "$vastaus" in [kKyYjJ]*) return 0 ;; *) return 1 ;; esac
    }

    say "Suomen kieliavut — etäasennus"
    printf '    julkaisu: %s\n' "$JULKAISU_URL"
    printf '    distro:   %s (%s)\n' "$DISTRO_NIMI" "$DISTRO"

    # --- voikko ---------------------------------------------------------------
    if [ "$DO_VOIKKO" -eq 1 ]; then
        say "Voikko — morfologinen oikoluku työpöytäsovelluksiin"
        # Voikko on repon kannalta perusta, mutta se tulee distron paketeista
        # eikä julkaisusta. Pakettien nimet eroavat merkittävästi (Arch niputtaa,
        # Debian pilkkoo) — ks. docs/arch-vs-debian.md kohta 1.
        local komento=""
        case "$DISTRO" in
            # voikko-fi ja voikko-libreoffice ovat vain AUR:ssa, joten pelkkä
            # pacman ei riitä. yay ei ole kaikissa Arch-johdannaisissa valmiina
            # (puhdas Arch, Manjaro); ilman apuohjelmaa komento jää tyhjäksi ja
            # haara alempana neuvoo käyttäjää sen sijaan että kaatuisi.
            arch)
                local aur_apu="" ehdokas=""
                for ehdokas in yay paru; do
                    if command -v "$ehdokas" >/dev/null 2>&1; then
                        aur_apu="$ehdokas"
                        break
                    fi
                done
                if [ -n "$aur_apu" ]; then
                    komento="$aur_apu -S --needed voikko-fi voikko-libreoffice"
                fi
                ;;
            # libvoikko-dev on mukana komentorivityökalujen takia, ei
            # kehityksen: voikkospell, voikkohyphenate ja voikkogc ovat
            # upstreamissa osa libvoikkoa (voikko.puimula.org/source-linux.html
            # käyttää komentoa `voikkospell -d fi` omana varmistuksenaan) ja
            # Archissa paketissa libvoikko. Vain Debian siirtää ne -dev-
            # pakettiin, jossa ne ovat headerien seurassa. Ilman tätä READMEn
            # dokumentoimat varmistuskomennot eivät toimisi Debianissa
            # lainkaan. Tarkistettu Debian trixien tiedostolistasta 2026-09-18.
            debian) komento="sudo apt install voikko-fi libreoffice-voikko libenchant-2-voikko python3-libvoikko libvoikko-dev" ;;
        esac
        # Onko Voikko jo asennettu. EI `command -v voikkospell`: se binääri on
        # Debianissa eri paketissa (libvoikko-dev) kuin se mitä tässä mitataan,
        # eikä Voikon toiminta riipu siitä. Testi oli aiemmin Debianissa
        # pysyvästi epätosi, joten asennin ehdotti apt-riviä uudelleen myös
        # onnistuneen asennuksen jälkeen (mitattu 2026-09-18). Mitataan siis
        # nimenomaan ne kaksi pakettia jotka tekevät Voikosta toimivan, ja
        # kysytään ne paketinhallinnalta.
        voikko_on() {
            case "$DISTRO" in
                arch)
                    pacman -Q voikko-fi voikko-libreoffice >/dev/null 2>&1
                    ;;
                debian)
                    # Molempien on oltava asennettuja. Muoto '${Status}' on
                    # dpkg:n vanhin ja siksi kannettavin; puuttuva paketti ei
                    # tulosta riviä lainkaan, joten rivit lasketaan.
                    local tila=""
                    tila="$(dpkg-query -W -f='${Status}\n' \
                                voikko-fi libreoffice-voikko 2>/dev/null)"
                    [ "$(printf '%s\n' "$tila" |
                         grep -c '^install ok installed$')" -eq 2 ]
                    ;;
                *)
                    command -v voikkospell >/dev/null 2>&1
                    ;;
            esac
        }

        # CLI-testi on vapaaehtoinen lisä, ei asennuksen mittari.
        voikko_testi() {
            if command -v voikkospell >/dev/null 2>&1; then
                printf '    testi: '
                echo "maastopyöräily" | voikkospell || true
            else
                # Tähän ei pitäisi päätyä asennuksen jälkeen: komento yllä
                # sisältää libvoikko-dev:n. Osuma tarkoittaa joko ennestään
                # asennettua Voikkoa ilman sitä, tai tuntematonta distroa.
                printf '    (voikkospell ei ole asennettuna — komentorivitesti\n'
                printf '     ohitetaan; Debian/Ubuntu: apt install libvoikko-dev)\n'
            fi
        }

        if voikko_on; then
            printf '    Voikko on jo asennettu.\n'
            voikko_testi
        elif [ -z "$komento" ] && [ "$DISTRO" = arch ]; then
            printf '    Voikko puuttuu, eikä AUR-apuohjelmaa (yay, paru) löydy.\n'
            printf '    voikko-fi ja voikko-libreoffice ovat vain AUR:ssa. Asenna yay:\n'
            printf '      https://github.com/Jguer/yay#installation\n'
            printf '    ja aja sitten: curl -fsSL %s | bash -s -- --vain voikko\n' "$ASENNIN_URL"
            JAI+=("Voikko: asenna yay tai paru ja aja: curl -fsSL $ASENNIN_URL | bash -s -- --vain voikko")
        elif [ -z "$komento" ]; then
            printf '    tuntematon distro — asenna Voikko distrosi paketeista:\n'
            printf '      voikko-fi ja LibreOffice-liitännäinen\n'
            JAI+=("Voikon asennus käsin (tuntematon distro)")
        else
            printf '    Voikko puuttuu. Asennus vaatii paketinhallinnan ja sudon:\n'
            printf '      %s\n' "$komento"
            if kysy "Ajetaanko tämä nyt?"; then
                # Epäonnistunut pakettiasennus (väärä salasana, verkko, AUR-
                # käännös) ei saa kaataa loppuja osia: ne ovat kotihakemistossa
                # eivätkä riipu Voikosta.
                if eval "$komento"; then
                    TEHTY+=("Voikko-paketit")
                    voikko_testi
                else
                    printf '    pakettien asennus epäonnistui — muut osat jatkuvat\n'
                    JAI+=("Voikko: asennus epäonnistui, aja uudelleen: $komento")
                fi
            else
                JAI+=("Voikko: $komento")
            fi
        fi
    fi

    # --- hyphen ---------------------------------------------------------------
    if [ "$DO_HYPHEN" -eq 1 ]; then
        say "Tavutuskuviot (LibreOffice, hunspell-reitti)"
        # Tämä on ainoa osa joka kirjoittaa järjestelmähakemistoon, ja siksi
        # ainoa joka ei ole oletuksena päällä. Archissa kuvioita ei paketoi
        # kukaan; Debianissa ne tulevat paketista hyphen-fi.
        # Omistajuustarkistus ennen kirjoitusta. Ilman tätä asennin loisi
        # tiedoston, jota mikään paketti ei omista — juuri se ongelma, jonka
        # AUR-paketti hyphen-fi on tarkoitettu ratkaisemaan. Pakettienhallinnan
        # ulkopuolinen tiedosto jää päivityksissä paikalleen eikä poistu
        # mitenkään hallitusti.
        OMISTAJA=""
        if command -v pacman >/dev/null 2>&1; then
            OMISTAJA="$(pacman -Qoq /usr/share/hyphen/hyph_fi_FI.dic 2>/dev/null || true)"
        elif command -v dpkg >/dev/null 2>&1; then
            OMISTAJA="$(dpkg -S /usr/share/hyphen/hyph_fi_FI.dic 2>/dev/null | cut -d: -f1 || true)"
        fi

        if [ -n "$OMISTAJA" ]; then
            skip "/usr/share/hyphen/hyph_fi_FI.dic kuuluu paketille $OMISTAJA — ei kosketa"
        elif [ -e /usr/share/hyphen/hyph_fi_FI.dic ] && [ "$FORCE" -eq 0 ]; then
            skip "/usr/share/hyphen/hyph_fi_FI.dic on jo olemassa"
        else
            printf '    tämä osa kirjoittaa /usr/share/hyphen/ -hakemistoon ja käyttää sudoa\n'
            printf '    HUOM: näin syntyvää tiedostoa ei omista mikään paketti.\n'
            printf '    Archissa siistimpi vaihtoehto on AUR-paketti hyphen-fi:\n'
            printf '        yay -S hyphen-fi\n'
            printf '    Se asentaa saman tiedoston pakettienhallinnan kautta ja on\n'
            printf '    poistettavissa normaalisti.\n'
            nouda_ja_varmenna "hyph_fi_FI.dic" "$SUMMA_hyph_fi_FI"
            if kysy "Ajetaanko silti sudo install /usr/share/hyphen/hyph_fi_FI.dic?"; then
                sudo install -Dm644 "$TYOHAK/hyph_fi_FI.dic" /usr/share/hyphen/hyph_fi_FI.dic
                printf '    /usr/share/hyphen/hyph_fi_FI.dic\n'
                TEHTY+=("/usr/share/hyphen/hyph_fi_FI.dic")
            else
                JAI+=("tavutuskuviot: sudo install -Dm644 hyph_fi_FI.dic /usr/share/hyphen/")
            fi
        fi
    fi

    # --- chromium -------------------------------------------------------------
    if [ "$DO_CHROMIUM" -eq 1 ]; then
        say "Chromium-sanasto"
        # Chromium avaa vain yhden tietyn nimen: <kieli>-<sanastoversio>.bdic.
        # Sanastoversio on kielikohtainen (en-US 10-1, fi 3-0) eikä sitä voi
        # päätellä muista kielistä. Väärä nimi ohitetaan ilman virheilmoitusta.
        local bdic_nimi="${BDIC_NIMI:-fi-3-0.bdic}"
        local kohde="${XDG_CONFIG_HOME:-$HOME/.config}/chromium/Dictionaries/$bdic_nimi"
        if [ -e "$kohde" ] && [ "$FORCE" -eq 0 ]; then
            skip "$kohde on jo olemassa (--force ylikirjoittaa)"
        else
            nouda_ja_varmenna "fi-FI.bdic" "$SUMMA_fi_FI_bdic"
            put "$TYOHAK/fi-FI.bdic" "$kohde" && TEHTY+=("$kohde")
        fi
        # Pelkkä tiedosto ei riitä: suomi ei ole Chromiumin tuettujen
        # oikolukukielten listassa, joten chrome://settings/languages EI tarjoa
        # sille rastia. Pref on kirjoitettava Preferences-tiedostoon.
        #
        # Työkalu NOUDETAAN julkaisusta eikä ole upotettu tähän. Syy on
        # tools/pref-kirjoitus.py:n docstringissä: sama JSON-logiikka oli ennen
        # kahdessa skriptissä heredocina ja korjaus piti tehdä kahdesti. Logiikka
        # ei myöskään ole triviaalia — kirjoitus on atominen os.replace(), koska
        # katkennut Preferences saa Chromiumin NOLLAAMAAN koko profiilin.
        # Yksi toteutus, noudettuna samalla SHA-256-varmennuksella kuin sanastot.
        #
        # Kumpi tahansa este alla johtaa JAI-merkintään, ei virheeseen: sanasto
        # on jo paikallaan ja osan voi ajaa myöhemmin uudelleen yksinään.
        local chromium_este=""
        if ! command -v python3 >/dev/null 2>&1; then
            chromium_este="python3 puuttuu"
        elif ! command -v pgrep >/dev/null 2>&1; then
            # Ilman pgrepiä ei voi tietää onko selain auki. Kirjoittaminen
            # käynnissä olevan selaimen alta hukkaisi muutoksen hiljaisesti,
            # joten oletetaan pahin.
            chromium_este="pgrep puuttuu, selaimen tilaa ei voi tarkistaa"
        elif pgrep -x 'chromium|chromium-browser|chrome|google-chrome' >/dev/null 2>&1; then
            # pgrep -x täsmää prosessin nimeen kokonaisuudessaan ja tukee
            # vaihtoehtoja; todettu tällä koneella, ettei se anna osumaa
            # nimelle jota listassa ei ole.
            # Chromium kirjoittaa Preferences-tiedoston uudelleen sulkeutuessaan
            # ja ylikirjoittaisi tässä tehdyn muutoksen. Käyttäjälle se näyttäisi
            # siltä ettei asennus toiminut lainkaan.
            chromium_este="selain on käynnissä"
        fi

        if [ -n "$chromium_este" ]; then
            printf '    oikolukukieltä ei aseteta nyt: %s\n' "$chromium_este"
            printf '    sanasto on paikallaan; aseta kieli myöhemmin komennolla:\n'
            printf '      curl -fsSL %s | bash -s -- --vain chromium\n' "$ASENNIN_URL"
            JAI+=("Chromium: oikolukukieli asettamatta ($chromium_este) — sulje selain ja aja: curl -fsSL $ASENNIN_URL | bash -s -- --vain chromium")
        else
            nouda_ja_varmenna "pref-kirjoitus.py"        "$SUMMA_pref_kirjoitus"
            nouda_ja_varmenna "chromium-ota-kayttoon.sh" "$SUMMA_chromium_ota"
            # Työkalu laskee juurensa omasta sijainnistaan ja etsii
            # <juuri>/tools/pref-kirjoitus.py:n, joten molemmat on asetettava
            # tools/-hakemistoon. TYOHAK siivotaan EXIT-trapissa.
            install -Dm644 "$TYOHAK/pref-kirjoitus.py"        "$TYOHAK/tools/pref-kirjoitus.py"
            install -Dm755 "$TYOHAK/chromium-ota-kayttoon.sh" "$TYOHAK/tools/chromium-ota-kayttoon.sh"
            local ota_liput=()
            [ "$KAIKKI_PROFIILIT" -eq 1 ] && ota_liput+=(--kaikki-profiilit)
            if bash "$TYOHAK/tools/chromium-ota-kayttoon.sh" "${ota_liput[@]+"${ota_liput[@]}"}"; then
                TEHTY+=("Chromium: oikolukukieli fi")
                [ "$KAIKKI_PROFIILIT" -eq 0 ] &&
                    printf '    monta profiilia? lisää komentoon --kaikki-profiilit\n'
            else
                JAI+=("Chromium: oikolukukielen asetus epäonnistui")
            fi
        fi
    fi

    # --- nvim -----------------------------------------------------------------
    if [ "$DO_NVIM" -eq 1 ]; then
        say "Neovim-sanasto"
        local spl="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/spell/fi.utf-8.spl"
        if [ -e "$spl" ] && [ "$FORCE" -eq 0 ]; then
            skip "$spl on jo olemassa (--force ylikirjoittaa)"
        else
            nouda_ja_varmenna "fi.utf-8.spl" "$SUMMA_fi_utf8_spl"
            put "$TYOHAK/fi.utf-8.spl" "$spl" && TEHTY+=("$spl")
        fi
        printf '    käyttö: :set spelllang=fi spell\n'
    fi

    # --- enchant --------------------------------------------------------------
    if [ "$DO_ENCHANT" -eq 1 ]; then
        say "enchant — pakota Voikko suomelle"
        printf '    huom: tätä ei normaalisti tarvita, koska Voikko on ainoa\n'
        printf '          suomen tarjoaja. Tarpeen vain jos /usr/share/hunspell/\n'
        printf '          sisältää fi-sanaston, joka kilpailisi Voikon kanssa.\n'
        local ordering="${XDG_CONFIG_HOME:-$HOME/.config}/enchant/enchant.ordering"
        if [ -e "$ordering" ] && [ "$FORCE" -eq 0 ]; then
            skip "$ordering on jo olemassa"
        else
            mkdir -p "$(dirname "$ordering")"
            # Vain fi-rivi. Rivi fi_FI:voikko oli aiemmin mukana, mutta se on
            # TEHOTON: Voikko ei tarjoa enchantille tunnusta fi_FI lainkaan
            # (vain fi), ja enchant.ordering ratkaisee vain samaa tunnusta
            # tarjoavien kesken. Mitattu 2026-09-16. Ks. README.
            printf 'fi:voikko\n' > "$ordering"
            printf '    %s\n' "$ordering"
            TEHTY+=("$ordering")
        fi
    fi

    # --- firefox --------------------------------------------------------------
    if [ "$DO_FIREFOX" -eq 1 ]; then
        say "Firefox, Thunderbird ja Betterbird"
        # Kaksi reittiä, ja asennin valmistelee molemmat:
        #
        #   1. Jaettu sanasto + prefs.js (tools/firefox-ota-kayttoon.sh). Ei
        #      lisäosaa, ei käsityötä, yksi kopio kaikille profiileille, ja
        #      kieli tulee valituksi samalla. Tämä on oletus aina kun
        #      Firefoxin profiilijuuri löytyy tavallisesta paikasta.
        #      Snap- ja Flatpak-versioille sama reitti, mutta sanasto menee
        #      hiekkalaatikon OMAAN hakemistoon (~/snap/<nimi>/common,
        #      ~/.var/app/<tunnus>): eristetty ohjelma ei näe
        #      ~/.local/share-hakemistoa, mutta oman hakemistonsa se näkee
        #      samalla polulla kuin isäntäkin. EI TESTATTU oikealla Snap-/
        #      Flatpak-asennuksella — polut ovat dokumentaation mukaiset.
        #   2. .xpi käsin about:addons-sivulta. Varareitti, kun profiilia ei
        #      löydy mistään tai python3 puuttuu. .xpi noudetaan siksi aina,
        #      ja varareitillä se kopioidaan lisäksi Lataukset-kansioon:
        #      Snap-ohjelma ei saa lukea kotihakemiston piilohakemistoja
        #      (~/.cache), eikä tiedostoikkuna näytä niitä oletuksena.
        #
        # Työkalut noudetaan julkaisusta samasta syystä kuin chromium-osassa.
        local xpi="${XDG_CACHE_HOME:-$HOME/.cache}/suomen-kieliavut/fi-spell-0.2.xpi"
        if [ -e "$xpi" ] && [ "$FORCE" -eq 0 ]; then
            skip "$xpi on jo noudettu (--force noutaa uudelleen)"
        else
            nouda_ja_varmenna "fi-spell-0.2.xpi" "$SUMMA_fi_spell_xpi"
            install -Dm644 "$TYOHAK/fi-spell-0.2.xpi" "$xpi"
            printf '    %s\n' "$xpi"
        fi

        # Profiilijuuret: Firefoxille sama hakujärjestys kuin työkalussa
        # itsessään. Thunderbird ja sen johdannainen Betterbird jakavat saman
        # juuren, ja niiden oikoluku on samaa Gecko-koodia: sama prefs.js-
        # kirjoitus toimii sellaisenaan (todettu Betterbird 153.3.0esr:llä
        # 2026-09-18). Alkiot ovat muotoa
        # "<nimi>|<juuri>|<sanastohakemisto>|<flatpak-tunnus>"; tyhjä
        # sanastohakemisto tarkoittaa työkalun oletusta.
        local -a ff_kohteet=()
        local ff_ehdokas="" ff_firefox_loytyi=0
        for ff_ehdokas in "${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox" "$HOME/.mozilla/firefox"; do
            if [ -d "$ff_ehdokas" ]; then ff_kohteet+=("Firefox|$ff_ehdokas||"); ff_firefox_loytyi=1; break; fi
        done
        for ff_ehdokas in "${XDG_CONFIG_HOME:-$HOME/.config}/thunderbird" "$HOME/.thunderbird"; do
            if [ -d "$ff_ehdokas" ]; then ff_kohteet+=("Thunderbird/Betterbird|$ff_ehdokas||"); break; fi
        done
        # Snap- ja Flatpak-versiot tavallisten LISÄKSI, ei sijasta: Ubuntussa
        # ~/.mozilla voi olla jäänne deb-ajalta, vaikka käytössä on Snap.
        # Alkiot: "<nimi>|<hiekkalaatikon hakemisto>|<flatpak-tunnus>|<juuriehdokkaat>"
        local ff_eristetty="" ff_en="" ff_eh="" ff_et="" ff_ej=""
        for ff_eristetty in \
            "Firefox (Snap)|$HOME/snap/firefox/common||.mozilla/firefox" \
            "Firefox (Flatpak)|$HOME/.var/app/org.mozilla.firefox|org.mozilla.firefox|.mozilla/firefox config/mozilla/firefox" \
            "Thunderbird (Snap)|$HOME/snap/thunderbird/common||.thunderbird" \
            "Thunderbird (Flatpak)|$HOME/.var/app/org.mozilla.Thunderbird|org.mozilla.Thunderbird|.thunderbird" \
            "Betterbird (Flatpak)|$HOME/.var/app/eu.betterbird.Betterbird|eu.betterbird.Betterbird|.thunderbird"; do
            IFS='|' read -r ff_en ff_eh ff_et ff_ej <<<"$ff_eristetty"
            for ff_ehdokas in $ff_ej; do
                [ -d "$ff_eh/$ff_ehdokas" ] || continue
                ff_kohteet+=("$ff_en|$ff_eh/$ff_ehdokas|$ff_eh/suomen-kieliavut/hunspell|$ff_et")
                case "$ff_en" in Firefox*) ff_firefox_loytyi=1 ;; esac
                break
            done
        done

        # Varareitin .xpi näkyvään paikkaan, ks. kohta 2 yllä. Kopioidaan vain
        # tarvittaessa, ettei Lataukset-kansio täyty turhaan.
        xpi_latauksiin() {
            local lataukset=""
            command -v xdg-user-dir >/dev/null 2>&1 &&
                lataukset="$(xdg-user-dir DOWNLOAD 2>/dev/null || true)"
            lataukset="${lataukset%/}"
            # xdg-user-dir palauttaa kotihakemiston, jos kansiota ei ole määritelty.
            if [ -z "$lataukset" ] || [ "$lataukset" = "${HOME%/}" ]; then
                lataukset="$HOME/Downloads"
            fi
            [ -d "$lataukset" ] || return 0
            if install -m644 "$xpi" "$lataukset/fi-spell-0.2.xpi" 2>/dev/null; then
                xpi="$lataukset/fi-spell-0.2.xpi"
            fi
        }

        local ff_uudelleen="curl -fsSL $ASENNIN_URL | bash -s -- --vain firefox"
        # Firefoxin puuttuva juuri kirjataan aina: Firefox on lähes joka
        # koneella, ja Ubuntussa se on Snap-versio, jonka juuri ei ole yllä.
        # Thunderbirdin puuttuminen ei ole huomautuksen arvoinen — useimmilla
        # sitä ei ole asennettuna lainkaan.
        if [ "$ff_firefox_loytyi" -eq 0 ]; then
            xpi_latauksiin
            printf '    Firefoxin profiilia ei löydy (ei tavallista, Snap- eikä Flatpak-versiota).\n'
            printf '    Jos Firefox on vasta asennettu, käynnistä se kerran, sulje ja aja:\n'
            printf '      %s\n' "$ff_uudelleen"
            printf '    Tai asenna sanasto käsin:\n'
            printf '      about:addons -> rataskuvake -> Asenna lisäosa tiedostosta\n'
            printf '      %s\n' "$xpi"
            JAI+=("Firefox: profiilia ei löytynyt — käynnistä Firefox kerran ja aja asennin uudelleen, tai asenna $xpi käsin about:addons-sivulta")
        fi
        if [ ${#ff_kohteet[@]} -eq 0 ]; then
            :
        elif ! command -v python3 >/dev/null 2>&1; then
            xpi_latauksiin
            printf '    python3 puuttuu — asetuksia ei kirjoiteta.\n'
            JAI+=("Firefox/Thunderbird: python3 puuttuu — asenna $xpi käsin about:addons-sivulta")
        else
            nouda_ja_varmenna "firefox-ota-kayttoon.sh" "$SUMMA_firefox_ota"
            nouda_ja_varmenna "prefs-js-kirjoitus.py"   "$SUMMA_prefs_js"
            # Sanastopari on ~15 Mt. Jos aiemman ajon kopio on jo paikallaan ja
            # täsmää summiin, sitä ei noudeta uudelleen — toinen ajo (esim.
            # --kaikki-profiilit) on silloin pelkkä prefs.js-kirjoitus.
            local ff_jaettu="${XDG_DATA_HOME:-$HOME/.local/share}/suomen-kieliavut/hunspell"
            local ff_tied="" ff_odotettu=""
            for ff_tied in fi_FI.aff fi_FI.dic; do
                case "$ff_tied" in
                    fi_FI.aff) ff_odotettu="$SUMMA_fi_FI_aff" ;;
                    fi_FI.dic) ff_odotettu="$SUMMA_fi_FI_dic" ;;
                esac
                if [ -f "$ff_jaettu/$ff_tied" ] &&
                   [ "$($SUMMAAJA "$ff_jaettu/$ff_tied" | cut -d' ' -f1)" = "$ff_odotettu" ]; then
                    cp "$ff_jaettu/$ff_tied" "$TYOHAK/$ff_tied"
                else
                    nouda_ja_varmenna "$ff_tied" "$ff_odotettu"
                fi
            done
            # Työkalu laskee juurensa omasta sijainnistaan: <juuri>/tools/ ja
            # <juuri>/dict/ginter/. TYOHAK siivotaan EXIT-trapissa.
            install -Dm755 "$TYOHAK/firefox-ota-kayttoon.sh" "$TYOHAK/tools/firefox-ota-kayttoon.sh"
            install -Dm644 "$TYOHAK/prefs-js-kirjoitus.py"   "$TYOHAK/tools/prefs-js-kirjoitus.py"
            install -Dm644 "$TYOHAK/fi_FI.aff" "$TYOHAK/dict/ginter/fi_FI.aff"
            install -Dm644 "$TYOHAK/fi_FI.dic" "$TYOHAK/dict/ginter/fi_FI.dic"
            local ff_liput=()
            [ "$KAIKKI_PROFIILIT" -eq 1 ] && ff_liput+=(--kaikki-profiilit)
            # Työkalu palauttaa virheen, jos jokin profiili ohitettiin (ohjelma
            # käynnissä) tai yhtään käynnistettyä profiilia ei ole. Kumpikaan ei
            # kaada asennusta: osan voi ajaa myöhemmin yksinään.
            local ff_kohde="" ff_nimi="" ff_juuri="" ff_sanasto="" ff_flatpak=""
            local -a ff_kohdeliput=()
            for ff_kohde in "${ff_kohteet[@]}"; do
                IFS='|' read -r ff_nimi ff_juuri ff_sanasto ff_flatpak <<<"$ff_kohde"
                ff_kohdeliput=()
                [ -n "$ff_sanasto" ] && ff_kohdeliput+=(--sanastopolku "$ff_sanasto")
                rivi "$ff_nimi:"
                # Flatpak ajaa ohjelman omassa PID-nimiavaruudessaan, joten
                # profiilin lukkotiedoston pid ei päde isännässä eikä työkalun
                # käynnissäolon tarkistus toimi. Kysytään flatpakilta itseltään.
                if [ -n "$ff_flatpak" ] && command -v flatpak >/dev/null 2>&1 &&
                   flatpak ps --columns=application 2>/dev/null | grep -qx "$ff_flatpak"; then
                    printf '    %s on käynnissä. Sulje se ja aja:\n' "$ff_nimi"
                    printf '      %s\n' "$ff_uudelleen"
                    JAI+=("$ff_nimi: asetukset kirjoittamatta — sulje ohjelma ja aja: $ff_uudelleen")
                    continue
                fi
                if bash "$TYOHAK/tools/firefox-ota-kayttoon.sh" "${ff_liput[@]+"${ff_liput[@]}"}" \
                        "${ff_kohdeliput[@]+"${ff_kohdeliput[@]}"}" "$ff_juuri"; then
                    TEHTY+=("$ff_nimi: sanasto ${ff_sanasto:-$ff_jaettu} ja oikolukukieli fi-FI")
                else
                    printf '    %s: asetuksia ei kirjoitettu. Sulje ohjelma ja aja:\n' "$ff_nimi"
                    printf '      %s\n' "$ff_uudelleen"
                    JAI+=("$ff_nimi: asetukset kirjoittamatta — sulje ohjelma ja aja: $ff_uudelleen")
                fi
            done
            [ "$KAIKKI_PROFIILIT" -eq 0 ] &&
                printf '    monta profiilia? lisää komentoon --kaikki-profiilit\n'
        fi
    fi

    # --- oxt ------------------------------------------------------------------
    if [ "$DO_OXT" -eq 1 ]; then
        say "LibreOffice — hunspell-sanastolaajennus (.oxt)"
        # Tämä on Ginterin KOKO sanasto (476 291 sanuetta) LibreOfficen omana
        # laajennuksena. Se ei korvaa Voikkoa vaan on varapolku: Voikko osaa
        # yhdyssanat ja kielentarkistuksen, hunspell ei kumpaakaan. Jos
        # voikko-libreoffice on asennettu, suomelle on tämän jälkeen kaksi
        # tarjoajaa — LibreOffice valitsee itse, eikä valintaa voi lukita.
        #
        # unopkg add ilman --shared asentaa vain tälle käyttäjälle
        # (~/.config/libreoffice), joten sudoa ei tarvita.
        #
        # VAROITUS testaajalle (opittu kantapään kautta 2026-09-16): unopkg EI
        # kunnioita $HOME-muuttujaa vaan ratkaisee käyttäjäprofiilinsa omasta
        # bootstrap-asetuksestaan. HOME=/tmp/... -hiekkalaatikko ei siis eristä
        # mitään — se asentaa silti oikeaan ~/.config/libreoffice/4:ään.
        # Ainoa eristävä tapa on -env:UserInstallation=file:///polku.
        if ! command -v unopkg >/dev/null; then
            # Kelvollinen ohitus, ei virhe: LibreOfficea ei ole asennettu.
            skip "unopkg puuttuu — LibreOfficea ei ilmeisesti ole asennettu"
            JAI+=("LibreOffice-sanasto: asenna LibreOffice ja aja install.sh --vain oxt")
        elif unopkg_on_asennettu && [ "$FORCE" -eq 0 ]; then
            skip "$OXT_TUNNUS on jo asennettu (--force asentaa uudelleen)"
        else
            nouda_ja_varmenna "fi-hunspell-0.9.oxt" "$SUMMA_fi_hunspell_oxt"
            # unopkg epäonnistuu mm. jos LibreOffice on käynnissä. Se ei saa
            # kaataa koko asennusta: muut osat on jo tehty, joten virhe
            # kirjataan yhteenvetoon ja jatketaan.
            local -a unopkg_liput=()
            [ "$FORCE" -eq 1 ] && unopkg_liput+=(-f)
            if unopkg add "${unopkg_liput[@]}" "$TYOHAK/fi-hunspell-0.9.oxt"; then
                rivi "asennettu: $OXT_TUNNUS"
                rivi "poisto: unopkg remove $OXT_TUNNUS"
                TEHTY+=("LibreOffice-laajennus $OXT_TUNNUS")
            else
                rivi "unopkg epäonnistui — onko LibreOffice käynnissä?"
                JAI+=("LibreOffice-sanasto: sulje LibreOffice ja aja install.sh --vain oxt")
            fi
        fi
    fi

    # --- yhteenveto -----------------------------------------------------------
    echo
    say "Yhteenveto"
    if [ ${#TEHTY[@]} -eq 0 ]; then
        printf '    asennettiin: ei mitään uutta (kaikki oli jo paikallaan)\n'
    else
        printf '    asennettiin:\n'
        printf '      - %s\n' "${TEHTY[@]}"
    fi
    if [ ${#JAI[@]} -gt 0 ]; then
        printf '    jäi sinun tehtäväksesi:\n'
        printf '      - %s\n' "${JAI[@]}"
    fi
    if [ "$VAIN_ANNETTU" -eq 0 ]; then
        printf '    ei ajettu oletuksena: hyphen (vaatii sudon), enchant\n'
        printf '      ota käyttöön: install.sh --vain hyphen,enchant\n'
    fi
    printf '    testi: kirjoita tekstikenttään maastopyörä\n'
    printf '           (ei saa alleviivautua) ja maastopyöräz\n'
    printf '           (pitää alleviivautua)\n'
    say "Valmis."
}

# Viimeinen rivi — ks. TURVALLISUUS PUTKESSA skriptin alussa.
asennin "$@"
