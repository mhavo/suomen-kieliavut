#!/usr/bin/env bash
# Luo tyhjät Firefox- ja Chromium-profiilit skenaariolle 04.
#
# MIKSI VALEPROFIILIT EIKÄ OIKEA SELAIN: profiilityökalut lukevat ja
# kirjoittavat pelkkiä tiedostoja — prefs.js ja Preferences — eivätkä
# koskaan puhu selaimelle. Oikean selaimen käynnistäminen kontissa toisi
# X-palvelimen, sandboxin ja snapin ilman yhtään lisäväitettä; punaista
# alleviivausta ei silti nähtäisi (R6).
#
# Fikstuuri on tarkoituksella "likainen": jokaisessa Preferences-tiedostossa
# on vieraita asetuksia, joiden säilymistä väite 18 mittaa, ja valmis
# intl.accept_languages, jonka muuttumattomuutta väite 19 mittaa.
set -euo pipefail

FF_JUURI="$HOME/.mozilla/firefox"
CR_JUURI="${XDG_CONFIG_HOME:-$HOME/.config}/chromium"
REPO="${REPO:-/repo}"

# --- Firefox ----------------------------------------------------------------
# Kaksi profiilia, kumpikin "käynnistetty": prefs.js on olemassa. Juuri sen
# olemassaolo on tunnus, jolla tools/firefox-ota-kayttoon.sh profiilit löytää.
luo_ff_profiili() { # luo_ff_profiili <hakemistonimi>
    local d="$FF_JUURI/$1"
    mkdir -p "$d"
    cat > "$d/prefs.js" <<'PREFS'
// Mozilla User Preferences

user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.startup.page", 3);
PREFS
}

mkdir -p "$FF_JUURI"
luo_ff_profiili "aaaaaaaa.default-release"
luo_ff_profiili "bbbbbbbb.toinen"

cat > "$FF_JUURI/profiles.ini" <<'INI'
[Profile0]
Name=default-release
IsRelative=1
Path=aaaaaaaa.default-release
Default=1

[Profile1]
Name=toinen
IsRelative=1
Path=bbbbbbbb.toinen

[General]
StartWithLastProfile=1
Version=2
INI

cat > "$FF_JUURI/installs.ini" <<'INI'
[4F96D1932A9F858E]
Default=aaaaaaaa.default-release
Locked=1
INI

# --- Chromium ---------------------------------------------------------------
luo_cr_profiili() { # luo_cr_profiili <profiilinimi>
    local d="$CR_JUURI/$1"
    mkdir -p "$d"
    cat > "$d/Preferences" <<'JSON'
{"browser":{"custom_chrome_frame":true},"intl":{"accept_languages":"en-US,en"},"spellcheck":{"dictionaries":["en-US"]}}
JSON
}

luo_cr_profiili "Default"
luo_cr_profiili "Profile 1"
luo_cr_profiili "System Profile"

# Väite 17 vertaa tähän: System Profile on dokumentoidusti ohitettava.
sha256sum "$CR_JUURI/System Profile/Preferences" | cut -d' ' -f1 \
    > "$CR_JUURI/System Profile/.summa-ennen"

# Sanastotiedosto on osa fikstuuria eikä profiilityökalun tuotos: .bdic tulee
# asentimelta, ja skenaario 04 ajaa vain profiilityökalut (§3). Väite 15
# tarkistaa silti otsakkeen, koska juuri tämä tiedosto on se jota
# spellcheck.dictionaries-pref osoittaa käytettäväksi.
install -Dm644 "$REPO/build/fi-FI.bdic" \
    "$CR_JUURI/Dictionaries/${BDIC_NIMI:-fi-3-0.bdic}"

echo "==> Firefox-profiilit: $FF_JUURI"
echo "==> Chromium-profiilit: $CR_JUURI"
