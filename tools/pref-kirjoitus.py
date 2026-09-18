#!/usr/bin/env python3
"""Lukee ja kirjoittaa Chromium-/Electron-profiilin Preferences-tiedoston.

Yhteinen apuohjelma chromium-ota-kayttoon.sh:lle ja electron-sanastot.sh:lle.
Aiemmin sama logiikka oli molemmissa skripteissä upotettuna heredocina, jolloin
korjaus piti tehdä kahdesti.

Käyttö:
    pref-kirjoitus.py tarkista <preferences> <kieli> [valitsimet]
    pref-kirjoitus.py kirjoita <preferences> <kieli> [valitsimet]

Valitsimet:
    --aseta-kieli        lisää kieli myös intl.accept_languages-asetukseen
    --pakota-oikoluku    aseta browser.enable_spellchecking naiiviksi True:ksi,
                         vaikka käyttäjä olisi eksplisiittisesti kytkenyt sen pois

Paluuarvot (tarkista):
    0  muutos tarpeen
    1  ei tarvetta
    2  tiedosto ei aukea tai ei jäsenny JSONina — siihen EI kosketa

KOLME TIETOISTA RAJOITUSTA:

1. Kirjoitus on atominen. Preferences kirjoitetaan ensin samaan hakemistoon
   nimellä <polku>.tmp ja siirretään os.replace():llä paikalleen. Keskeytys
   kesken kirjoituksen (levy täynnä, kill, virrankatkos) jättäisi muuten
   katkenneen JSONin, jolloin Chromium NOLLAA koko profiilin. Varmuuskopio on
   silloin olemassa, mutta käyttäjä ei osaa etsiä tiedostoa
   Preferences.bak-20260916143022.

2. intl.accept_languages EI muutu ilman --aseta-kieli-valitsinta. Se ohjaa
   selaimen lähettämää Accept-Language-otsaketta, joka näkyy jokaiselle
   sivustolle ja vaikuttaa sekä sivustojen kielivalintaan että selaimen
   sormenjälkeen. Oikolukusanaston asennus ei saa muuttaa sitä, mitä käyttäjä
   kertoo verkolle itsestään. Tällä ei ole hintaa käyttöliittymässä: suomi
   näkyy chrome://settings/languages-listassa pelkän
   spellcheck.dictionaries-prefin perusteella (todettu 2026-09-18 kolmessa
   profiilissa, joista kahdessa suomi ei ollut accept_languages-arvossa).

3. browser.enable_spellchecking asetetaan vain jos se puuttuu tai on jo True.
   Eksplisiittinen False on käyttäjän tietoinen valinta pitää oikoluku pois;
   se ohitetaan vain --pakota-oikoluku-valitsimella.
"""
import json
import os
import sys


def lue(polku):
    with open(polku, encoding="utf-8") as f:
        return json.load(f)


def oikoluku_tila(prefs):
    """None = puuttuu, True/False = eksplisiittinen arvo."""
    return prefs.get("browser", {}).get("enable_spellchecking")


def tarvitseeko(prefs, kieli, aseta_kieli, pakota):
    if kieli not in prefs.get("spellcheck", {}).get("dictionaries", []):
        return True
    tila = oikoluku_tila(prefs)
    if tila is not True and (tila is not False or pakota):
        return True
    if aseta_kieli and kieli not in prefs.get("intl", {}).get(
            "accept_languages", "").split(","):
        return True
    return False


def kirjoita(polku, prefs):
    # Sama hakemisto kuin kohde, jotta os.replace on atominen (sama
    # tiedostojärjestelmä). Oikeudet kopioidaan alkuperäisestä.
    tmp = polku + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(prefs, f, separators=(",", ":"))
        f.flush()
        os.fsync(f.fileno())
    try:
        tila = os.stat(polku)
        os.chmod(tmp, tila.st_mode & 0o7777)
    except OSError:
        pass
    os.replace(tmp, polku)


def main():
    if len(sys.argv) < 4:
        print(__doc__, file=sys.stderr)
        return 2
    komento, polku, kieli = sys.argv[1], sys.argv[2], sys.argv[3]
    liput = sys.argv[4:]
    aseta_kieli = "--aseta-kieli" in liput
    pakota = "--pakota-oikoluku" in liput

    try:
        prefs = lue(polku)
    except (OSError, ValueError):
        return 2

    if komento == "tarkista":
        return 0 if tarvitseeko(prefs, kieli, aseta_kieli, pakota) else 1

    if komento != "kirjoita":
        print(f"tuntematon komento: {komento}", file=sys.stderr)
        return 2

    sanastot = prefs.setdefault("spellcheck", {}).setdefault("dictionaries", [])
    if kieli in sanastot:
        print(f"    {kieli} oli jo listassa: {sanastot}")
    else:
        sanastot.append(kieli)
        print(f"    lisätty {kieli}: {sanastot}")

    tila = oikoluku_tila(prefs)
    if tila is False and not pakota:
        print("    browser.enable_spellchecking on eksplisiittisesti false —")
        print("    jätetään koskematta. Oikoluku ei käynnisty ennen kuin kytket")
        print("    sen päälle selaimen asetuksista tai ajat --pakota-oikoluku.")
    elif tila is not True:
        prefs.setdefault("browser", {})["enable_spellchecking"] = True
        print("    browser.enable_spellchecking = true")

    if aseta_kieli:
        intl = prefs.setdefault("intl", {})
        hyvaksytyt = intl.get("accept_languages", "en-US,en")
        if kieli not in hyvaksytyt.split(","):
            intl["accept_languages"] = f"{hyvaksytyt},{kieli}"
            print(f"    accept_languages: {intl['accept_languages']}")
            print("    (tämä näkyy jokaiselle sivustolle Accept-Language-otsakkeessa)")
    else:
        print("    intl.accept_languages jätetään ennalleen (sivustoille lähtevä")
        print("    Accept-Language ei muutu). Valitsin --aseta-kieli lisää kielen siihen.")

    kirjoita(polku, prefs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
