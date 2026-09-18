#!/usr/bin/env bash
# Väiteharness — distroriippumaton (FEATURE §4.2, R7).
#
# Tämä tiedosto on sekä kirjasto että komento:
#
#   source tarkista.sh            skenaarioskripti saa vaite*-apurit ja
#                                 ympäristöapurit, ja kutsuu itse joukon
#   tarkista.sh <joukko>          ajaa pelkän väitejoukon ja poistuu
#
# Väitteet tulostetaan TAP-muodossa (FEATURE §4.1): yksi rivi per väite,
# "ok <nro> <kuvaus> = <arvo>" tai "not ok <nro> <kuvaus>" + odotettu/saatu.
# Numerot ovat FEATURE §5–§6:n väitenumeroita eivätkä juoksevia: lokirivin
# numero tarkoittaa aina samaa väitettä riippumatta siitä mikä joukko ajettiin.
#
# KAIKKI distrojen väliset erot ratkaistaan täällä (R7). Skenaarioskriptit
# eivät saa haarautua distron mukaan.
set -euo pipefail

TESTI_HAK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_HAK="$(cd "$TESTI_HAK/.." && pwd)"

# Paluukoodit, jotka testaa-puhtaalta.sh tulkitsee (§7.1, §7.3, §3.2):
#   0  kaikki väitteet läpi
#   1  vähintään yksi "not ok"
#   3  SKIP (esim. verkko ei tavoitettavissa)
#   muu  VIRHE — infrastruktuurivika, ei tuotevika
# shellcheck disable=SC2034  # käytetään skenaarioskripteissä, jotka sourcettavat tämän
KOODI_SKIP=3
KOODI_VIRHE=4

VAITTEITA_OK=0
VAITTEITA_EI=0

# --- TAP-tulostus -----------------------------------------------------------

vaite() { # vaite <nro> <kuvaus> <odotettu> <saatu>
    local nro="$1" kuvaus="$2" odotettu="$3" saatu="$4"
    if [ "$odotettu" = "$saatu" ]; then
        printf 'ok %s %s = %s\n' "$nro" "$kuvaus" "$saatu"
        VAITTEITA_OK=$((VAITTEITA_OK + 1))
    else
        printf 'not ok %s %s\n' "$nro" "$kuvaus"
        printf '    odotettu: %s\n' "$odotettu"
        printf '    saatu:    %s\n' "$saatu"
        VAITTEITA_EI=$((VAITTEITA_EI + 1))
    fi
}

# Sisältyykö neula heinäsuovaan. Oma apurinsa, koska "saatu"-kentäksi ei kelpaa
# koko asentimen tuloste — se hukuttaisi lokin.
vaite_sisaltaa() { # vaite_sisaltaa <nro> <kuvaus> <neula> <heinäsuova>
    local nro="$1" kuvaus="$2" neula="$3" suova="$4" saatu="ei löydy"
    case "$suova" in *"$neula"*) saatu="löytyy" ;; esac
    vaite "$nro" "$kuvaus" "löytyy" "$saatu"
}

yhteenveto() {
    printf '# väitteitä %s: ok %s, not ok %s\n' \
        "$((VAITTEITA_OK + VAITTEITA_EI))" "$VAITTEITA_OK" "$VAITTEITA_EI"
    [ "$VAITTEITA_EI" -eq 0 ]
}

# --- ympäristö --------------------------------------------------------------

# Distron tunnus. Käytetään vain täällä ja Dockerfileissä (R7).
distro() {
    ( . /etc/os-release >/dev/null 2>&1
      case "${ID:-}" in
          arch)          printf 'arch\n' ;;
          ubuntu|debian) printf 'ubuntu\n' ;;
          *)             printf 'tuntematon\n' ;;
      esac )
}

# Paikallinen "julkaisu": hakemisto, jossa on julkaisun liitetiedostot niillä
# litteillä nimillä joita install.sh noutaa.
#
# MIKSI EI SUORAAN file:///repo/build (FEATURE §3): build/ ei sisällä
# tavutuskuvioita — hyph_fi_FI.dic on dict/hyphen/ -hakemistossa. Skenaario 05
# tarvitsee sen, ja väite 20 tarvitsee kirjoitettavan kopion, jota /repo ei
# ole (R1). Skenaario 01 käyttää silti file:///repo/build suoraan, koska sen
# oletusosat löytyvät sieltä sellaisenaan.
valmistele_julkaisu() { # valmistele_julkaisu <kohdehakemisto>
    local kohde="$1"
    mkdir -p "$kohde"
    cp "$REPO_HAK/build/fi-FI.bdic"           "$kohde/fi-FI.bdic"
    cp "$REPO_HAK/build/fi.utf-8.spl"         "$kohde/fi.utf-8.spl"
    cp "$REPO_HAK/build/fi-spell-0.2.xpi"     "$kohde/fi-spell-0.2.xpi"
    cp "$REPO_HAK/build/fi-hunspell-0.9.oxt"  "$kohde/fi-hunspell-0.9.oxt"
    cp "$REPO_HAK/dict/hyphen/hyph_fi_FI.dic" "$kohde/hyph_fi_FI.dic"
    # Chromium-osan työkalut ovat julkaisun liitetiedostoja siinä missä
    # sanastotkin: install.sh noutaa ja varmentaa ne, koska putkessa ajettuna
    # sillä ei ole repon työkopiota. Ilman näitä skenaario 01 kaatuisi
    # lataukseen — ja syyttäisi siitä julkaisua, ei tätä funktiota.
    cp "$REPO_HAK/tools/chromium-ota-kayttoon.sh" "$kohde/chromium-ota-kayttoon.sh"
    cp "$REPO_HAK/tools/pref-kirjoitus.py"        "$kohde/pref-kirjoitus.py"
    # Firefox-osa samoin: työkalut ja Ginterin lähdepari.
    cp "$REPO_HAK/tools/firefox-ota-kayttoon.sh"  "$kohde/firefox-ota-kayttoon.sh"
    cp "$REPO_HAK/tools/prefs-js-kirjoitus.py"    "$kohde/prefs-js-kirjoitus.py"
    cp "$REPO_HAK/dict/ginter/fi_FI.aff"          "$kohde/fi_FI.aff"
    cp "$REPO_HAK/dict/ginter/fi_FI.dic"          "$kohde/fi_FI.dic"
    chmod u+w "$kohde"/*
}

# voikkospell lukee stdinistä lokaalin mukaisella koodauksella: C-lokaalissa
# se katkaisee lukemisen ensimmäiseen ei-ASCII-tavuun ("Error while reading
# from stdin"). Mitattu 2026-09-18. Väärä lokaali näyttäisi Voikon
# hajoamiselta, joten se raportoidaan infrastruktuurivirheenä (§7.3) eikä
# väitteen kaatumisena.
vaadi_utf8() {
    local merkisto
    merkisto="$(locale charmap 2>/dev/null || true)"
    case "$merkisto" in
        UTF-8|utf8|UTF8) return 0 ;;
    esac
    printf '# VIRHE: lokaalin merkistö on %s, ei UTF-8 (LANG=%s)\n' \
        "${merkisto:-tuntematon}" "${LANG:-}" >&2
    exit "$KOODI_VIRHE"
}

# Virkistää pakettilistat ennen kuin asennin yrittää asentaa Voikon.
#
# Tämä EI riko invarianttia R2: Voikko-paketteja ei asenneta, vaan pelkkä
# hakemistoindeksi päivitetään. Ilman sitä kuvan rakennushetkellä noudettu
# indeksi vanhenisi ja asentimen "apt install" kaatuisi 404:ään — se olisi
# ympäristövirhe, joka naamioituisi tuotevirheeksi.
paivita_pakettilistat() {
    case "$(distro)" in
        ubuntu) sudo apt-get update -qq >/dev/null 2>&1 || true ;;
        arch)   sudo pacman -Sy --noconfirm >/dev/null 2>&1 || true ;;
    esac
}

# Ajaa komennon pseudopäätteessä ja syöttää vastaukset sille.
#
# MIKSI script(1) EIKÄ docker run -t: install.sh:n kysy() lukee /dev/tty:stä,
# ei stdinistä, joten putkeen syötetty vastaus ei mene perille ilman oikeaa
# päätettä. script(1) antaa lapselle pseudopäätteen JA ohjaa oman stdininsä
# sinne, joten sama docker run -kutsu kelpaa kaikille skenaarioille — myös
# niille jotka ajetaan tarkoituksella ilman päätettä (§3.3).
pty_aja() { # pty_aja <vastaukset> <komento> [argumentit...]
    local vastaukset="$1"; shift
    local komentorivi
    komentorivi="$(printf '%q ' "$@")"
    printf '%s' "$vastaukset" | script -qec "$komentorivi" /dev/null
}

# script(1) jättää riveille CR:t. Väitteet tehdään siivotusta tekstistä.
riisu_cr() { tr -d '\r'; }

# --- §5.1 LibreOffice -------------------------------------------------------

# Ajaa UNO-luotaimen ja jättää JSONin muuttujaan LO_JSON. Aikakatkaisu on
# luotaimen sisällä (§7.4): paluukoodi 4 on VIRHE, ei "not ok".
lo_luotaa() {
    local koodi=0
    LO_JSON="$(python3 "$TESTI_HAK/lo-oikoluku.py")" || koodi=$?
    if [ "$koodi" -ne 0 ]; then
        printf '# VIRHE: lo-oikoluku.py paluukoodi %s\n' "$koodi" >&2
        printf '%s\n' "${LO_JSON:-}" >&2
        exit "$KOODI_VIRHE"
    fi
}

lo_kentta() { # lo_kentta <jq-polku>
    printf '%s' "$LO_JSON" | jq -r "$1"
}

# FEATURE §5.1 odottaa toteutusnimiä org.puimula.ooovoikko.VoikkoSpellChecker
# ja ...VoikkoGrammarChecker. Ne ovat .oxt-paketin vanhoja nimiä; nykyinen
# voikko-libreoffice rekisteröi itsensä niminä voikko.SpellChecker ja
# voikko.GrammarChecker (mitattu LibreOffice 25 + voikko-libreoffice
# 2026-09-18). Väite ei siis vaadi yhtä kirjaimellista nimeä vaan sitä, että
# tarjoajien joukossa on Voikko — ja tulostaa koko listan, jotta nimen
# vaihtuminen näkyy lokissa. Kirjaimellinen nimi tekisi väitteestä nimen
# historian testin, ei moottorin testin.
joukko_libreoffice() {
    vaadi_utf8
    lo_luotaa
    vaite 1 'LibreOffice: SpellChecker fi-FI -tarjoajat' 'sisältää Voikon' \
        "$(lo_kentta '.oikolukijat | join(", ") | if (ascii_downcase | test("voikko")) then "sisältää Voikon" elif length == 0 then "(tyhjä lista)" else "ei Voikkoa: " + . end')"
    vaite 2 'LibreOffice: isValid("tarkkailukehä", fi-FI)' \
        'true' "$(lo_kentta '.tarkkailukeha')"
    vaite 3 'LibreOffice: isValid("qwertyxyz", fi-FI)' \
        'false' "$(lo_kentta '.qwertyxyz')"
    vaite 4 'LibreOffice: Hyphenator tavuttaa maastopyöräily' \
        'tavutettu' "$(lo_kentta 'if (.tavutus | test("=")) then "tavutettu (\(.tavutus))" else "ei tavutettu: \(.tavutus)" end' | sed 's/^tavutettu .*/tavutettu/')"
    vaite 5 'LibreOffice: Proofreader fi-FI -tarjoajat' 'sisältää Voikon' \
        "$(lo_kentta '.kielentarkistajat | join(", ") | if (ascii_downcase | test("voikko")) then "sisältää Voikon" elif length == 0 then "(tyhjä lista)" else "ei Voikkoa: " + . end')"
    printf '# LibreOffice-luotain: %s\n' "$LO_JSON"
}

vaite_oxt_asennettu() { # §5.1 väite 6, vain skenaario 05
    local lista
    # Ei "unopkg list | grep": ks. install.sh:n unopkg_on_asennettu.
    lista="$(unopkg list 2>/dev/null || true)"
    vaite_sisaltaa 6 'LibreOffice: unopkg list sisältää fi.hunspell.suomen-kieliavut' \
        'fi.hunspell.suomen-kieliavut' "$lista"
}

# --- §5.2 komentorivi -------------------------------------------------------

vaite_voikkospell() { # väite 7
    local sanoja hyvaksytyt vaarin puuttuu
    sanoja="$(grep -c . "$REPO_HAK/tools/testisanat.txt")"
    # Debianissa /usr/bin/voikkospell tulee paketista libvoikko-dev, jota
    # install.sh ei asenna eikä loppukäyttäjä asentaisi; Arch niputtaa sen
    # libvoikkoon. Ilman tätä haaraa puuttuva binääri näyttää lokissa
    # täsmälleen samalta kuin rikkinäinen Voikko (mitattu 2026-09-18), koska
    # alla oleva 2>/dev/null nielaisee "command not found" -viestin. Väite
    # PYSYY punaisena — tämä on diagnostiikkaa, ei löydöksen piilottamista.
    if ! command -v voikkospell >/dev/null 2>&1; then
        puuttuu='voikkospell puuttuu PATHista (Debian: libvoikko-dev)'
        vaite 7a "voikkospell hyväksyy tools/testisanat.txt ($sanoja sanaa)" \
            "$sanoja" "$puuttuu"
        vaite 7b 'voikkospell hylkää sanan maastopyöräz' 'W' "$puuttuu"
        return 0
    fi
    hyvaksytyt="$(voikkospell < "$REPO_HAK/tools/testisanat.txt" 2>/dev/null | grep -c '^C' || true)"
    vaite 7a "voikkospell hyväksyy tools/testisanat.txt ($sanoja sanaa)" \
        "$sanoja" "$hyvaksytyt"
    vaarin="$(printf 'maastopyöräz\n' | voikkospell 2>/dev/null | cut -c1 || true)"
    vaite 7b 'voikkospell hylkää sanan maastopyöräz' 'W' "$vaarin"
}

vaite_hunspell() { # väite 8
    # hunspell-sanastoa ei asenneta järjestelmään (se syrjäyttäisi Voikon
    # enchantissa, ks. tools/firefox-ota-kayttoon.sh), joten se osoitetaan
    # DICPATH:lla suoraan repoon. Yhdyssanan odotetaan hajoavan: se on juuri
    # se ero Voikkoon, jonka väite 2 mittaa.
    local perusmuoto yhdyssana
    perusmuoto="$(printf 'talo\n' | DICPATH="$REPO_HAK/dict/ginter" hunspell -d fi_FI 2>/dev/null | sed -n 2p | cut -c1 || true)"
    vaite 8a 'hunspell -d fi_FI hyväksyy perusmuodon talo' '*' "$perusmuoto"
    yhdyssana="$(printf 'tarkkailukehä\n' | DICPATH="$REPO_HAK/dict/ginter" hunspell -d fi_FI 2>/dev/null | sed -n 2p | cut -c1 || true)"
    vaite 8b 'hunspell -d fi_FI hylkää yhdyssanan tarkkailukehä (ero Voikkoon)' '&' "$yhdyssana"
}

vaite_nvim() { # väite 9
    # --clean pudottaa ~/.config/nvim:n runtimepathista, joten spell-hakemisto
    # lisätään takaisin käsin. Ilman tätä spelllang=fi ei löytäisi juuri sitä
    # tiedostoa jonka asennin kirjoitti.
    local tulos=/tmp/nvim-spell-tulos rivi1 rivi2
    rm -f "$tulos"
    nvim --clean --headless \
        --cmd "let g:loaded_spellfile_plugin = 1" \
        --cmd "set runtimepath+=$HOME/.config/nvim" \
        -c 'set spelllang=fi spell' \
        -c "call writefile([get(spellbadword('talo'),0,'VIRHE'), get(spellbadword('qwertyxyz'),0,'VIRHE')], '$tulos')" \
        -c 'qa!' >/dev/null 2>&1 || true
    rivi1="$(sed -n 1p "$tulos" 2>/dev/null || true)"
    rivi2="$(sed -n 2p "$tulos" 2>/dev/null || true)"
    vaite 9a 'nvim spelllang=fi: spellbadword("talo") on tyhjä' '(tyhjä)' "${rivi1:-(tyhjä)}"
    vaite 9b 'nvim spelllang=fi: spellbadword("qwertyxyz") merkitsee sanan' 'qwertyxyz' "$rivi2"
}

vaite_enchant() { # väitteet 10 ja 10b, vain skenaario 05
    local lista rivi ordering fi_rivi
    lista="$(enchant-lsmod-2 -list-dicts 2>/dev/null || true)"
    rivi="$(printf '%s\n' "$lista" | grep -E '^fi( |$)' || true)"
    vaite_sisaltaa 10 'enchant-lsmod-2: tunnus fi tulee voikko-tarjoajalta' \
        'voikko' "$rivi"

    # Väite 10 yksin ei mittaa enchant-osaa: Voikko on suomen ainoa tarjoaja,
    # joten enchant valitsee sen ilman ordering-tiedostoakin. Mitattu
    # isännällä 2026-09-18: ~/.config/enchant-hakemistoa ei ollut lainkaan ja
    # enchant-lsmod-2 tulosti silti "fi (voikko)". install.sh sanoo saman itse:
    # "tätä ei normaalisti tarvita". 10b mittaa osan oman jäljen ja punastuu
    # jos osa ei aja tai kirjoittaa väärän rivin. Odotettu sisältö on
    # install.sh:n kirjoittama rivi sellaisenaan (install.sh:375): pelkkä
    # fi-rivi, ei fi_FI:tä — se oli tehoton ja poistettiin 2026-09-16.
    ordering="${XDG_CONFIG_HOME:-$HOME/.config}/enchant/enchant.ordering"
    if [ -r "$ordering" ]; then
        fi_rivi="$(grep -E '^fi:' "$ordering" || echo 'ei fi-riviä')"
    else
        fi_rivi='tiedostoa ei ole'
    fi
    vaite 10b 'enchant.ordering: fi-rivi' 'fi:voikko' "$fi_rivi"
}

# --- §5.3 Firefox -----------------------------------------------------------

# Jaettu sanastohakemisto, jonka tools/firefox-ota-kayttoon.sh luo.
ff_jaettu() { printf '%s/suomen-kieliavut/hunspell\n' "${XDG_DATA_HOME:-$HOME/.local/share}"; }

vaite_ff_sanasto() { # väite 11
    local hak; hak="$(ff_jaettu)"
    local tila='puuttuu tai tyhjä'
    if [ -s "$hak/fi_FI.aff" ] && [ -s "$hak/fi_FI.dic" ]; then tila='olemassa, ei-tyhjät'; fi
    vaite 11 "Firefox: $hak/fi_FI.aff ja .dic" 'olemassa, ei-tyhjät' "$tila"
}

ff_profiilit() { # tulostaa jokaisen profiilin prefs.js-polun
    local juuri="$HOME/.mozilla/firefox" d
    for d in "$juuri"/*/; do
        [ -f "${d}prefs.js" ] && printf '%s\n' "${d}prefs.js"
    done
}

vaite_ff_prefit() { # väitteet 12 ja 13
    local hak prefs arvo maara profiileja=0
    hak="$(ff_jaettu)"
    while read -r prefs; do
        [ -n "$prefs" ] || continue
        profiileja=$((profiileja + 1))
        local nimi; nimi="$(basename "$(dirname "$prefs")")"
        arvo="$(sed -n 's/^user_pref("spellchecker.dictionary_path", "\(.*\)");$/\1/p' "$prefs" | tail -1)"
        vaite 12a "Firefox/$nimi: spellchecker.dictionary_path" "$hak" "${arvo:-(ei asetettu)}"
        arvo="$(sed -n 's/^user_pref("spellchecker.dictionary", "\(.*\)");$/\1/p' "$prefs" | tail -1)"
        vaite 12b "Firefox/$nimi: spellchecker.dictionary" 'fi-FI' "${arvo:-(ei asetettu)}"
        maara="$(grep -c '^user_pref("spellchecker.dictionary_path"' "$prefs" || true)"
        vaite 13 "Firefox/$nimi: dictionary_path-rivejä toisen ajon jälkeen" '1' "$maara"
    done < <(ff_profiilit)
    vaite 12c 'Firefox: käsiteltyjä profiileja' '2' "$profiileja"
}

vaite_xpi() { # väite 14
    local xpi="${XPI_POLKU:?XPI_POLKU on asetettava}" tila='ei kelpaa'
    if unzip -tqq "$xpi" >/dev/null 2>&1 &&
       python3 "$REPO_HAK/tools/tarkista-manifest.py" "$xpi" >/dev/null 2>&1; then
        tila='kelvollinen zip, manifest ok'
    fi
    vaite 14 "Firefox: $(basename "$xpi")" 'kelvollinen zip, manifest ok' "$tila"
}

# --- §5.4 Chromium ----------------------------------------------------------

cr_juuri() { printf '%s/chromium\n' "${XDG_CONFIG_HOME:-$HOME/.config}"; }

vaite_bdic() { # väite 15
    local f otsake
    f="$(cr_juuri)/Dictionaries/${BDIC_NIMI:-fi-3-0.bdic}"
    if [ ! -f "$f" ]; then
        vaite 15 "Chromium: $f" 'BDic v2' 'tiedostoa ei ole'
        return
    fi
    # Sama otsakevertailu kuin CI:n bdic-työssä: "BDic" + versio 2 LE.
    otsake="$(od -A n -t x1 -N 8 "$f" | tr -d ' ')"
    vaite 15 "Chromium: $(basename "$f") -otsake" '4244696302000000' "$otsake"
}

vaite_cr_prefit() { # väitteet 16, 17, 18, 19
    local juuri; juuri="$(cr_juuri)"
    local p nimi
    for nimi in Default 'Profile 1'; do
        p="$juuri/$nimi/Preferences"
        vaite 16 "Chromium/$nimi: spellcheck.dictionaries sisältää fi" 'kyllä' \
            "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("kyllä" if "fi" in d.get("spellcheck",{}).get("dictionaries",[]) else "ei: %s" % d.get("spellcheck",{}).get("dictionaries"))' "$p" 2>/dev/null || printf 'ei jäsenny\n')"
    done
    # 17: System Profile on jätettävä koskematta. Vertailusumma otettiin
    # fikstuuria luotaessa (valeprofiilit.sh).
    local nyt
    nyt="$(sha256sum "$juuri/System Profile/Preferences" | cut -d' ' -f1)"
    vaite 17 'Chromium/System Profile: Preferences ennallaan' \
        "$(cat "$juuri/System Profile/.summa-ennen")" "$nyt"
    for nimi in Default 'Profile 1' 'System Profile'; do
        p="$juuri/$nimi/Preferences"
        vaite 18 "Chromium/$nimi: Preferences on JSONia ja vieras pref säilyi" \
            'JSON ok, custom_chrome_frame=True' \
            "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("JSON ok, custom_chrome_frame=%s" % d.get("browser",{}).get("custom_chrome_frame"))' "$p" 2>/dev/null || printf 'ei jäsenny\n')"
    done
    for nimi in Default 'Profile 1'; do
        p="$juuri/$nimi/Preferences"
        vaite 19 "Chromium/$nimi: intl.accept_languages ennallaan" 'en-US,en' \
            "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d.get("intl",{}).get("accept_languages"))' "$p" 2>/dev/null || printf 'ei jäsenny\n')"
    done
}

# --- väitejoukot ------------------------------------------------------------

# Skenaariot 01, 02, 03: asennin ajettiin, selainprofiileja ei ole.
joukko_taysi() {
    vaadi_utf8
    joukko_libreoffice
    vaite_voikkospell
    vaite_hunspell
    vaite_nvim
    vaite_xpi
    vaite_bdic
}

# Skenaario 04: vain profiilityökalut (§3.1 — vain oma pintansa).
joukko_profiilit() {
    vaite_ff_sanasto
    vaite_ff_prefit
    vaite_bdic
    vaite_cr_prefit
}

# Skenaario 05: sudo-osat (§3.1 — vain oma pintansa).
joukko_sudo_osat() {
    vaadi_utf8
    vaite 24 'hyphen: /usr/share/hyphen/hyph_fi_FI.dic' 'olemassa, ei-tyhjä' \
        "$( [ -s /usr/share/hyphen/hyph_fi_FI.dic ] && printf 'olemassa, ei-tyhjä' || printf 'puuttuu tai tyhjä' )"
    vaite_oxt_asennettu
    vaite_enchant
}

# --- suora ajo --------------------------------------------------------------

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    case "${1:-}" in
        taysi)     joukko_taysi ;;
        profiilit) joukko_profiilit ;;
        sudo-osat) joukko_sudo_osat ;;
        *) echo "käyttö: tarkista.sh taysi|profiilit|sudo-osat" >&2; exit 2 ;;
    esac
    yhteenveto
fi
