#!/usr/bin/env bash
# Asentaa suomen kieliavut tälle koneelle. Idempotentti.
# Ks. ../README.md
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORCE=0
# Kaksi osaa on oletuksena POIS, kumpikin omasta syystään:
#
#   enchant  Voikko on ainoa suomen tarjoaja, joten järjestystiedostoa ei
#            normaalisti tarvita (ks. README, kohta enchant).
#   oxt      Hunspell-sanastolaajennus on VARAREITTI, ei Voikon korvaaja.
#            Oletusajossa se toisi LibreOfficeen toisen, heikomman tarjoajan
#            (88,0 % vastaan Voikon 95,0 %, eikä kielentarkistusta) Voikon
#            rinnalle — tasan se mitä repo muualla neuvoo välttämään. Tarpeen
#            vain Flatpak-/Snap-LibreOfficessa tai jos voikko-libreoffice
#            hajoaa.
#
# Ota kumpi tahansa käyttöön erikseen: --vain enchant / --vain oxt
DO_VOIKKO=1 DO_HYPHEN=1 DO_CHROMIUM=1 DO_NVIM=1 DO_ENCHANT=0 DO_FIREFOX=1 DO_OXT=0

usage() {
    cat <<'USAGE'
Käyttö: asenna.sh [valitsimet]

Ilman valitsimia asentaa kaiken paitsi enchant- ja oxt-osat.

  --vain <osa>[,<osa>...]  vain nämä: voikko hyphen chromium nvim enchant firefox oxt
  --force                  ylikirjoita olemassa olevat sanastot
  -h, --help               tämä ohje

Osat:
  voikko    distron Voikko-paketit                   (vaatii sudon)
            Arch: yay -S voikko-fi voikko-libreoffice
            Debian/Ubuntu: apt install voikko-fi libreoffice-voikko
                           libenchant-2-voikko python3-libvoikko libvoikko-dev
  hyphen    /usr/share/hyphen/hyph_fi_FI.dic         (vaatii sudon)
  chromium  ~/.config/chromium/Dictionaries/fi-3-0.bdic  (BDIC_NIMI= ohittaa)
  nvim      ~/.config/nvim/spell/fi.utf-8.spl
  enchant   ~/.config/enchant/enchant.ordering       (EI oletuksena — ks. README)
  firefox   Firefox, Thunderbird ja Betterbird: jaettu sanasto + profiilin
            prefs.js (tools/firefox-ota-kayttoon.sh)
  oxt       LibreOfficen hunspell-sanastolaajennus (EI oletuksena — varareitti,
            ks. README)
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --force) FORCE=1 ;;
        --vain)
            DO_VOIKKO=0 DO_HYPHEN=0 DO_CHROMIUM=0 DO_NVIM=0 DO_ENCHANT=0 DO_FIREFOX=0 DO_OXT=0
            IFS=',' read -ra parts <<< "${2:?--vain vaatii listan}"
            for p in "${parts[@]}"; do
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

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
skip() { printf '    ohitetaan: %s\n' "$*"; }

# Distron tunnistus. Vaikuttaa VAIN voikko-osaan: muut osat kirjoittavat
# käyttäjän kotihakemistoon tai /usr/share/hyphen/-polkuun, jotka ovat samat
# kaikilla (ks. ../docs/arch-vs-debian.md kohta 6).
#
# /etc/os-release luetaan aliprosessissa, jotta sen muuttujat eivät vuoda tähän
# skriptiin. ID_LIKE on mukana, jotta johdannaiset (Ubuntu, Manjaro, Mint)
# osuvat oikeaan haaraan ilman erillistä listaa.
tunnista_distro() {
    local osrel=""
    [ -r /etc/os-release ] || { printf 'tuntematon\n'; return; }
    # shellcheck disable=SC1091  # tiedosto on olemassa vasta ajohetkellä
    osrel="$(. /etc/os-release >/dev/null 2>&1 && printf '%s %s' "${ID:-}" "${ID_LIKE:-}")"
    case " $osrel " in
        *" arch "*)                 printf 'arch\n' ;;
        *" debian "*|*" ubuntu "*)  printf 'debian\n' ;;
        *)                          printf 'tuntematon\n' ;;
    esac
}

# Asentamatta jääneet osat. Skripti poistuu lopussa nollasta poikkeavalla
# koodilla jos tämä ei ole tyhjä: aiemmin voikko-osa saattoi jättää kaiken
# asentamatta ja skripti tulosti silti "==> Valmis." ja poistui koodilla 0,
# jolloin mikään paluuarvossa ei kertonut käyttäjälle eikä CI:lle mitään.
JAI=()

# Kopioi vain jos kohdetta ei ole (tai --force).
put() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then
        skip "$dst on jo olemassa (--force ylikirjoittaa)"
        return
    fi
    install -Dm644 "$src" "$dst"
    printf '    %s\n' "$dst"
}

OXT="$REPO/build/fi-hunspell-0.9.oxt"
OXT_TUNNUS="fi.hunspell.suomen-kieliavut"

# Onko .oxt jo asennettu tälle käyttäjälle.
#
# ÄLÄ kirjoita tätä muodossa `unopkg list | grep -q ...`. grep -q lopettaa
# ensimmäiseen osumaan ja sulkee putken, jolloin unopkg saa SIGPIPEn ja kuolee
# ENNEN kuin se ehtii poistaa lukkotiedostonsa ~/.config/libreoffice/4/.lock.
# Kuollut lukko estää kaikki myöhemmät unopkg-ajot — myös käyttäjän omat —
# virheeseen "the lock file indicates it is already running". Todettu tässä
# repossa 2026-09-16. Siksi ulostulo luetaan ensin kokonaan muuttujaan.
oxt_on_asennettu() {
    local lista
    lista="$(unopkg list 2>/dev/null || true)"
    case "$lista" in
        *"$OXT_TUNNUS"*) return 0 ;;
        *) return 1 ;;
    esac
}

if [ "$DO_VOIKKO" -eq 1 ]; then
    say "Voikko"
    # Pakettien nimet ja määrä eroavat distroittain merkittävästi: Arch niputtaa
    # (libvoikko sisältää myös komentorivityökalut), Debian pilkkoo neljään.
    # Ks. ../docs/arch-vs-debian.md kohta 1.
    DISTRO="$(tunnista_distro)"
    paketit=() asenna_komento=() asentaja=""
    case "$DISTRO" in
        arch)
            paketit=(voikko-fi voikko-libreoffice)
            # voikko-fi ja voikko-libreoffice ovat AUR:ssa, joten pelkkä pacman
            # ei riitä.
            asentaja="yay"
            asenna_komento=(yay -S --needed)
            ;;
        debian)
            # libvoikko-dev: komentorivityökalut (voikkospell, voikkohyphenate,
            # voikkogc), jotka Debian yksin siirtää -dev-pakettiin. Archissa ne
            # tulevat libvoikkon mukana. Ks. install.sh:n vastaava kohta.
            paketit=(voikko-fi libreoffice-voikko libenchant-2-voikko python3-libvoikko
                     libvoikko-dev)
            asentaja="apt-get"
            # -y siksi, että tämä skripti ei muutenkaan kysy mitään; sudo on
            # jo tämän osan ehto.
            asenna_komento=(sudo apt-get install -y)
            ;;
    esac

    # Onko paketti asennettu. Kysytään paketinhallinnalta, EI komennolta
    # `command -v voikkospell`: yksi binääri ei kerro mitään listan muista
    # paketeista, ja Debianissa se tulee omastaan (libvoikko-dev). Jokainen
    # paketti mitataan erikseen (mitattu 2026-09-18).
    paketti_on() {
        case "$DISTRO" in
            arch)   pacman -Q "$1" >/dev/null 2>&1 ;;
            debian) [ "$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null)" = \
                      'install ok installed' ] ;;
            *)      return 1 ;;
        esac
    }

    if [ ${#paketit[@]} -eq 0 ]; then
        # Tuntematon distro: nimiä ei voi arvata, eikä Arch-nimien tulostaminen
        # Debian-käyttäjälle auta ketään.
        echo "    tuntematon distro — asenna Voikko distrosi paketeista:" >&2
        echo "      voikko-fi ja LibreOffice-liitännäinen" >&2
        JAI+=("Voikko (tuntematon distro)")
    else
        # Kukin paketti tarkistetaan erikseen: voikko-fi voi olla asennettu
        # ilman LibreOffice-liitännäistä, jolloin kielentarkistus puuttuu.
        puuttuu=()
        for pkg in "${paketit[@]}"; do
            if paketti_on "$pkg"; then
                skip "$pkg on jo asennettu"
            else
                puuttuu+=("$pkg")
            fi
        done
        if [ ${#puuttuu[@]} -eq 0 ]; then
            :
        elif command -v "$asentaja" >/dev/null; then
            "${asenna_komento[@]}" "${puuttuu[@]}"
        else
            echo "    $asentaja puuttuu — asenna käsin: ${puuttuu[*]}" >&2
            JAI+=("Voikko-paketit: ${puuttuu[*]}")
        fi
    fi

    # Komentorivitesti on vapaaehtoinen lisä, ei asennuksen mittari: puuttuva
    # binääri ei tarkoita ettei Voikko toimisi. Tähän ei pitäisi päätyä
    # asennuksen jälkeen, koska libvoikko-dev on Debianin listalla.
    if command -v voikkospell >/dev/null; then
        printf '    testi: '
        echo "maastopyöräily" | voikkospell || true
    elif [ "$DISTRO" = debian ]; then
        printf '    (voikkospell ei ole asennettuna — komentorivitesti\n'
        printf '     ohitetaan; asenna halutessasi: apt install libvoikko-dev)\n'
    fi
fi

if [ "$DO_HYPHEN" -eq 1 ]; then
    say "Tavutuskuviot (LibreOffice, hunspell-reitti)"
    if [ -e /usr/share/hyphen/hyph_fi_FI.dic ] && [ "$FORCE" -eq 0 ]; then
        skip "/usr/share/hyphen/hyph_fi_FI.dic on jo olemassa"
    else
        sudo install -Dm644 "$REPO/dict/hyphen/hyph_fi_FI.dic" \
            /usr/share/hyphen/hyph_fi_FI.dic
        printf '    /usr/share/hyphen/hyph_fi_FI.dic\n'
    fi
fi

if [ "$DO_CHROMIUM" -eq 1 ]; then
    say "Chromium-sanasto"
    # Chromium avaa vain yhden tietyn nimen: <kieli>-<sanastoversio>.bdic.
    # Sanastoversio on kielikohtainen (en-US 10-1, fi 3-0) eikä sitä voi
    # päätellä muista kielistä. Väärä nimi ohitetaan ilman virheilmoitusta.
    # Oikean nimen saa selville: tools/chromium-sanastonimi.sh
    BDIC_NIMI="${BDIC_NIMI:-fi-3-0.bdic}"
    put "$REPO/build/fi-FI.bdic" "$HOME/.config/chromium/Dictionaries/$BDIC_NIMI"
    # Suomi ei ole Chromiumin tuettujen oikolukukielten listassa, joten
    # asetussivu EI tarjoa sille oikolukurastia. Pref on kirjoitettava suoraan.
    printf '    HUOM: pelkkä tiedosto ei riitä eikä asetusta voi tehdä\n'
    printf '          chrome://settings/languages -sivulta — suomi ei ole\n'
    printf '          Chromiumin tuettujen oikolukukielten listassa.\n'
    printf '    ota käyttöön (selain suljettuna):\n'
    printf '                  tools/chromium-ota-kayttoon.sh\n'
    printf '    jos ei toimi Chromium-päivityksen jälkeen, tarkista nimi:\n'
    printf '                  tools/chromium-sanastonimi.sh\n'
fi

if [ "$DO_NVIM" -eq 1 ]; then
    say "Neovim-sanasto"
    put "$REPO/build/fi.utf-8.spl" "$HOME/.config/nvim/spell/fi.utf-8.spl"
    printf '    käyttö: :set spelllang=fi spell\n'
fi

if [ "$DO_ENCHANT" -eq 1 ]; then
    say "enchant — pakota Voikko suomelle"
    printf '    huom: tätä ei normaalisti tarvita, koska Voikko on ainoa\n'
    printf '          suomen tarjoaja. Tarpeen vain jos /usr/share/hunspell/\n'
    printf '          sisältää sanaston nimellä fi.aff/fi.dic.\n'
    printf '    HUOM: sanastoon nimeltä fi_FI (Archin konventio) tämä EI tehoa\n'
    printf '          — Voikko ei tarjoa tunnusta fi_FI lainkaan. Ks. README.\n'
    ordering="$HOME/.config/enchant/enchant.ordering"
    if [ -e "$ordering" ] && [ "$FORCE" -eq 0 ]; then
        skip "$ordering on jo olemassa"
    else
        mkdir -p "$(dirname "$ordering")"
        # Vain fi-rivi. Rivi fi_FI:voikko oli aiemmin mukana, mutta se on
        # TEHOTON: Voikko ei tarjoa enchantille tunnusta fi_FI lainkaan (vain
        # fi), ja enchant.ordering ratkaisee vain samaa tunnusta tarjoavien
        # kesken. Mitattu 2026-09-16 — myös *:voikko ja fi_FI:voikko,hunspell
        # jättävät tunnuksen fi_FI hunspellille. Ks. README.
        printf 'fi:voikko\n' > "$ordering"
        printf '    %s\n' "$ordering"
    fi
    command -v enchant-lsmod-2 >/dev/null && enchant-lsmod-2 -list-dicts | sed 's/^/    /'
fi

if [ "$DO_OXT" -eq 1 ]; then
    say "LibreOffice — hunspell-sanastolaajennus (.oxt)"
    # Tämä on VARAREITTI, ei Voikon korvaaja: 88,0 % vastaan Voikon 95,0 %,
    # eikä kielentarkistusta. Tarpeen kahdessa tilanteessa: Flatpak-/Snap-
    # LibreOffice ei näe hiekkalaatikosta järjestelmän libvoikkoa, ja
    # voikko-libreoffice (AUR, julkaistu 2015) voi joskus hajota.
    # Ks. ../docs/sovellukset.md kohta 8.
    if ! command -v unopkg >/dev/null; then
        # Kelvollinen ohitus, ei virhe: LibreOfficea ei ole asennettu.
        skip "unopkg puuttuu — LibreOfficea ei ilmeisesti ole asennettu"
    elif oxt_on_asennettu && [ "$FORCE" -eq 0 ]; then
        skip "$OXT_TUNNUS on jo asennettu (--force asentaa uudelleen)"
    else
        # unopkg epäonnistuu mm. jos LibreOffice on käynnissä. Se ei saa
        # kaataa koko asennusta, koska muut osat on jo tehty.
        oxt_liput=()
        [ "$FORCE" -eq 1 ] && oxt_liput+=(-f)
        if unopkg add "${oxt_liput[@]}" "$OXT"; then
            printf '    asennettu: %s\n' "$OXT_TUNNUS"
            printf '    poisto:    unopkg remove %s\n' "$OXT_TUNNUS"
        else
            printf '    unopkg epäonnistui — onko LibreOffice käynnissä?\n' >&2
        fi
    fi
fi

if [ "$DO_FIREFOX" -eq 1 ]; then
    say "Firefox"
    # Sama ratkaisu kuin install.sh:ssa: jaettu sanasto ja prefs.js hoidetaan
    # työkalulla eikä lisäosaa tarvita. Snap- ja Flatpak-versioille sanasto
    # menee hiekkalaatikon omaan hakemistoon, jonka eristetty ohjelma näkee
    # (EI TESTATTU oikealla Snap-/Flatpak-asennuksella). .xpi-ohje jää
    # varareitiksi, jos Firefoxin profiilia ei löydy mistään.
    # Alkiot: "<nimi>|<juuri>|<sanastohakemisto>|<flatpak-tunnus>".
    ff_kohteet=()
    ff_firefox_loytyi=0
    for ff_ehdokas in "${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox" "$HOME/.mozilla/firefox"; do
        if [ -d "$ff_ehdokas" ]; then ff_kohteet+=("Firefox|$ff_ehdokas||"); ff_firefox_loytyi=1; break; fi
    done
    # Thunderbird ja Betterbird jakavat juuren; sama työkalu käy niihin.
    for ff_ehdokas in "${XDG_CONFIG_HOME:-$HOME/.config}/thunderbird" "$HOME/.thunderbird"; do
        if [ -d "$ff_ehdokas" ]; then ff_kohteet+=("Thunderbird/Betterbird|$ff_ehdokas||"); break; fi
    done
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

    if [ "$ff_firefox_loytyi" -eq 0 ]; then
        cat <<FF
    Firefoxin profiilia ei löydy (ei tavallista, Snap- eikä Flatpak-versiota).
    Jos Firefox on vasta asennettu, käynnistä se kerran, sulje ja aja tämä
    uudelleen. Tai asenna sanasto käsin:
    about:addons -> rataskuvake -> Asenna lisäosa tiedostosta
    $REPO/build/fi-spell-0.2.xpi
    (Snap-Firefox ei näe piilohakemistoja: kopioi tiedosto tarvittaessa
    ensin Lataukset-kansioon.)
FF
    fi
    if command -v python3 >/dev/null; then
        for ff_kohde in "${ff_kohteet[@]+"${ff_kohteet[@]}"}"; do
            IFS='|' read -r ff_nimi ff_juuri ff_sanasto ff_flatpak <<<"$ff_kohde"
            ff_kohdeliput=()
            [ -n "$ff_sanasto" ] && ff_kohdeliput+=(--sanastopolku "$ff_sanasto")
            # Flatpakin PID-nimiavaruuden takia työkalun lukkotarkistus ei näe
            # käynnissä olevaa ohjelmaa; kysytään flatpakilta.
            if [ -n "$ff_flatpak" ] && command -v flatpak >/dev/null 2>&1 &&
               flatpak ps --columns=application 2>/dev/null | grep -qx "$ff_flatpak"; then
                JAI+=("$ff_nimi: sulje ohjelma ja aja tools/asenna.sh --vain firefox")
                continue
            fi
            if ! "$REPO/tools/firefox-ota-kayttoon.sh" \
                    "${ff_kohdeliput[@]+"${ff_kohdeliput[@]}"}" "$ff_juuri"; then
                JAI+=("$ff_nimi: sulje ohjelma ja aja tools/firefox-ota-kayttoon.sh ${ff_kohdeliput[*]-} $ff_juuri")
            fi
        done
    fi
fi

say "Valmis."

# Paluukoodi kertoo asentamatta jääneistä osista. Ilman tätä epäonnistunut
# voikko-osa katosi tulosteen sekaan ja skripti poistui koodilla 0.
if [ ${#JAI[@]} -gt 0 ]; then
    printf '\n    ASENTAMATTA JÄI:\n' >&2
    printf '      - %s\n' "${JAI[@]}" >&2
    exit 1
fi
