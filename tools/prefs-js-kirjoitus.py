#!/usr/bin/env python3
"""Lukee ja kirjoittaa Firefox-profiilin prefs.js-tiedoston.

Vastine pref-kirjoitus.py:lle, joka hoitaa Chromiumin JSON-muotoisen
Preferences-tiedoston. Firefoxin prefs.js ei ole JSONia vaan rivilista
user_pref("avain", arvo); -kutsuja, joten jäsennys on erilainen — mutta
periaate on sama: älä kirjoita jos mikään ei muutu, kirjoita atomisesti,
äläkä koske tiedostoon jota et ymmärrä.

Käyttö:
    prefs-js-kirjoitus.py tarkista <prefs.js> <sanastopolku> [--kieli fi-FI]
    prefs-js-kirjoitus.py kirjoita <prefs.js> <sanastopolku> [--kieli fi-FI]

Paluuarvot (tarkista):
    0  muutos tarpeen
    1  ei tarvetta
    2  tiedosto ei aukea tai ei jäsenny — siihen EI kosketa

KOLME TIETOISTA RATKAISUA:

1. Kirjoitus on atominen (kirjoita .tmp, os.replace paikalleen). Katkennut
   prefs.js ei ole Firefoxille pikkujuttu: se nimeää tiedoston uudelleen
   Invalidprefs.js:ksi ja NOLLAA asetukset.

2. Kohde on prefs.js eikä user.js. user.js pakotetaan uudelleen joka
   käynnistyksessä, jolloin käyttäjän oma kielivalinta oikean painikkeen
   Kielet-valikosta kumoutuisi seuraavassa käynnistyksessä. prefs.js
   kirjoitetaan kerran, ja sen jälkeen käyttäjä päättää itse.

3. spellchecker.dictionary asetetaan vain jos se puuttuu. Olemassa oleva arvo
   on käyttäjän oma valinta — esimerkiksi "fi", jos profiilissa on .xpi-
   lisäosa. Sen ylikirjoittaminen rikkoisi toimivan asetuksen.
"""
import os
import re
import sys

# user_pref("avain", arvo);  — arvo on merkkijono, luku tai totuusarvo.
RIVI = re.compile(r'^\s*user_pref\(\s*"([^"]+)"\s*,\s*(.*?)\s*\)\s*;\s*$')

PATH_AVAIN = "spellchecker.dictionary_path"
KIELI_AVAIN = "spellchecker.dictionary"


def lue(polku):
    """Palauttaa (rivit, {avain: arvo}). Nostaa poikkeuksen jos ei aukea."""
    with open(polku, encoding="utf-8") as f:
        rivit = f.read().splitlines()
    prefit = {}
    for r in rivit:
        m = RIVI.match(r)
        if m:
            prefit[m.group(1)] = m.group(2)
    return rivit, prefit


def lainaa(s):
    return '"%s"' % s.replace("\\", "\\\\").replace('"', '\\"')


def muutokset(prefit, polku, kieli):
    """Mitkä prefit pitää asettaa. Tyhjä sanakirja = ei tarvetta."""
    tarve = {}
    if prefit.get(PATH_AVAIN) != lainaa(polku):
        tarve[PATH_AVAIN] = lainaa(polku)
    # Vain jos puuttuu: ks. ratkaisu 3 ylhäällä.
    if KIELI_AVAIN not in prefit:
        tarve[KIELI_AVAIN] = lainaa(kieli)
    return tarve


def kirjoita(polku, rivit, tarve):
    # Korvaa paikallaan ne rivit jotka jo ovat, lisää loput loppuun. Muu
    # sisältö säilyy rivi riviltä sellaisenaan.
    ulos = []
    for r in rivit:
        m = RIVI.match(r)
        if m and m.group(1) in tarve:
            ulos.append('user_pref("%s", %s);' % (m.group(1), tarve.pop(m.group(1))))
        else:
            ulos.append(r)
    for avain, arvo in tarve.items():
        ulos.append('user_pref("%s", %s);' % (avain, arvo))

    tmp = polku + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write("\n".join(ulos) + "\n")
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, polku)


def main():
    argv = sys.argv[1:]
    kieli = "fi-FI"
    if "--kieli" in argv:
        i = argv.index("--kieli")
        kieli = argv[i + 1]
        del argv[i:i + 2]
    if len(argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    komento, prefs, sanastopolku = argv

    try:
        rivit, prefit = lue(prefs)
    except (OSError, UnicodeDecodeError) as e:
        print("prefs.js ei aukea: %s" % e, file=sys.stderr)
        return 2

    tarve = muutokset(prefit, sanastopolku, kieli)
    if komento == "tarkista":
        return 0 if tarve else 1
    if komento != "kirjoita":
        print("tuntematon komento: %s" % komento, file=sys.stderr)
        return 2

    if not tarve:
        return 1
    for avain, arvo in sorted(tarve.items()):
        print("    %s = %s" % (avain, arvo))
    if KIELI_AVAIN not in tarve:
        print("    %s jätettiin ennalleen (%s) — se on käyttäjän oma valinta."
              % (KIELI_AVAIN, prefit.get(KIELI_AVAIN)))
    kirjoita(prefs, rivit, tarve)
    return 0


if __name__ == "__main__":
    sys.exit(main())
