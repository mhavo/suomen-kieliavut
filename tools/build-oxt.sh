#!/usr/bin/env bash
# Paketoi hunspell-sanaston LibreOfficen sanastolaajennukseksi (.oxt).
#
# Miksi tämä on olemassa, vaikka LibreOfficelle on Voikko-liitännäinen
# (AUR: voikko-libreoffice): Flatpak- ja Snap-LibreOffice eivät näe
# hiekkalaatikosta järjestelmän libvoikkoa eivätkä hakemistoa
# /usr/share/hunspell. .oxt asentuu LibreOfficen omaan laajennushakemistoon
# hiekkalaatikon SISÄLLE, joten se toimii myös niissä — ja on varapolku, jos
# voikko-libreoffice (viimeksi julkaistu 2015) hajoaa.
# Ks. ../README.md kohta "LibreOffice".
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Käyttö: build-oxt.sh [versio] [ginter|karsittu|myspell]

  versio    laajennuksen versionumero, oletus 0.9
  sanasto   ginter (oletus) | karsittu | myspell

Tulos: build/fi-hunspell-<versio>.oxt

Asennus (käyttäjäkohtainen, ei sudoa):
  unopkg add build/fi-hunspell-<versio>.oxt
Poisto:
  unopkg remove fi.hunspell.suomen-kieliavut

Paketin voi myös avata kaksoisklikkauksella millä tahansa distrolla.
USAGE
    exit 0
fi

VERSION="${1:-0.9}"
SANASTO="${2:-ginter}"

# description.xml:n <version value="..."> on OpenOffice.orgin
# laajennusmäärittelyn mukaan pistein erotettu numerosarja; unopkg vertaa sitä
# numeerisesti päivitystä asennettaessa. Sama tarkistus kuin build-xpi.sh:ssa.
case "$VERSION" in
    [0-9]*) ;;
    *) echo "virheellinen versio: $VERSION (odotettiin numeroa, ks. --help)" >&2; exit 2 ;;
esac

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

case "$SANASTO" in
    ginter)   AFF="$REPO/dict/ginter/fi_FI.aff";         DIC="$REPO/dict/ginter/fi_FI.dic" ;;
    karsittu) AFF="$REPO/dict/ginter/fi_FI.aff";         DIC="$REPO/dict/ginter-karsittu/fi_FI.dic" ;;
    myspell)  AFF="$REPO/dict/myspell-fi-0.7/fi-FI.aff"; DIC="$REPO/dict/myspell-fi-0.7/fi-FI.dic" ;;
    *) echo "tuntematon sanasto: $SANASTO (ks. --help)" >&2; exit 2 ;;
esac

case "$SANASTO" in
    ginter)   LISENSSI="CC0-1.0"; TEKIJA="Filip Ginter" ;;
    karsittu) LISENSSI="CC0-1.0"; TEKIJA="Filip Ginter (karsittu)" ;;
    myspell)  LISENSSI="GPL-2.0-only"; TEKIJA="Martin Vermeer, Pauli Virtanen" ;;
esac

# --- sanastotiedostot ------------------------------------------------------
# Paketin sisällä tiedostojen on oltava fi_FI.aff ja fi_FI.dic. Nimi ei tule
# lokaalista vaan dictionaries.xcu:n Locations-arvoista, mutta hunspell vaatii
# että .aff ja .dic ovat samannimiset — myspell-fi:n alkuperäinen fi-FI
# (viiva) nimetään siis uudelleen.
#
# MERKISTÖ: myspell-fi 0.7 on ISO8859-1 ja sen .aff alkaa rivillä
# "SET ISO8859-1". Hunspell lukee merkistön juuri tuolta SET-riviltä ja
# muuntaa sanat sisäisesti, ja LibreOfficen MySpellSpellChecker välittää
# tekstin hunspellille saman muunnoksen läpi — ISO8859-1-sanasto siis toimii
# LibreOfficessa sellaisenaan (todennettu ajamalla oikoluku UNO-rajapinnan
# kautta: "mäki" hyväksyttiin, "mäkki" hylättiin).
#
# Tiedostot muunnetaan silti UTF-8:ksi ja SET-rivi vastaavasti UTF-8:ksi.
# Syy: .oxt on zip, jonka sisällön moni työkalu (myös LibreOfficen oma
# laajennustenhallinta näyttäessään tiedostoja) olettaa UTF-8:ksi, ja repon
# muut tuotokset (.xpi, .spl) ovat UTF-8:aa — sekamerkistöisen paketin
# jakaminen on pelkkä jalkaan ampumisen tilaisuus. Muunnos on häviötön:
# ISO8859-1 on UTF-8:n osajoukko koodipisteinä.
if [ "$SANASTO" = myspell ]; then
    echo "==> muunnetaan ISO8859-1 -> UTF-8 (myspell-fi 0.7)"
    iconv -f ISO8859-1 -t UTF-8 "$DIC" > "$WORK/fi_FI.dic"
    # SET-rivin on vastattava tiedoston todellista merkistöä, tai hunspell
    # tulkitsee UTF-8-tavuparit kahdeksi latin-1-merkiksi ja kaikki ääkköset
    # rikkoutuvat.
    iconv -f ISO8859-1 -t UTF-8 "$AFF" | sed '1s/^SET ISO8859-1$/SET UTF-8/' > "$WORK/fi_FI.aff"
    if [ "$(head -1 "$WORK/fi_FI.aff")" != "SET UTF-8" ]; then
        echo "SET-riviä ei löytynyt .aff:n ensimmäiseltä riviltä — tarkista lähde" >&2
        exit 1
    fi
else
    cp "$AFF" "$WORK/fi_FI.aff"
    cp "$DIC" "$WORK/fi_FI.dic"
fi

# --- META-INF/manifest.xml -------------------------------------------------
# OpenOffice.orgin laajennusmäärittely: manifest luettelee jokaisen
# tiedoston, jolle LibreOfficen on tehtävä jotakin asennuksen yhteydessä.
# Pelkkä data (fi_FI.aff, fi_FI.dic) EI kuulu manifestiin — ne vain puretaan
# laajennushakemistoon ja niihin viitataan %origin%:illa. Vain
# dictionaries.xcu tarvitsee merkinnän, jotta sen sisältö sulautetaan
# rekisteriin.
#
# Media-tyyppi application/vnd.sun.star.configuration-data tarkoittaa
# "konfiguraatiofragmentti (.xcu), sulauta rekisteriin". Sama tyyppi on
# käytössä oikeassa toimivassa laajennuksessa, ks.
# ../raw/libreoffice-voikko-5.0-debian/META-INF/manifest.xml.
#
# DOCTYPE-rivi on mukana samassa muodossa kuin tuossa mallissa; LibreOffice ei
# nouda Manifest.dtd:tä verkosta, joten rivi on puhtaasti muodollinen.
mkdir -p "$WORK/META-INF"
cat > "$WORK/META-INF/manifest.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE manifest:manifest PUBLIC "-//OpenOffice.org//DTD Manifest 1.0//EN"
    "Manifest.dtd">
<manifest:manifest xmlns:manifest="http://openoffice.org/2001/manifest">
  <manifest:file-entry
   manifest:media-type="application/vnd.sun.star.configuration-data"
   manifest:full-path="dictionaries.xcu"/>
</manifest:manifest>
XML

# --- dictionaries.xcu ------------------------------------------------------
# Konfiguraatiofragmentti, joka lisätään solmuun
# org.openoffice.Office.Linguistic / ServiceManager / Dictionaries.
# Jokainen kenttä on pakollinen:
#
#   oor:name="Linguistic", oor:package="org.openoffice.Office"
#       määräävät MIHIN rekisterin solmuun fragmentti sulautetaan. Väärä
#       nimi/paketti = fragmentti menee rekisteriin, mutta oikoluku ei näe
#       sitä koskaan.
#   oor:op="fuse"
#       yhdistää solmun olemassa olevaan puuhun sen sijaan että korvaisi sen —
#       muuten laajennus pyyhkisi muut asennetut sanastot.
#   Format = DICT_SPELL
#       kertoo, mikä palvelu sanaston ottaa. LibreOffice ilmoittaa omassa
#       rekisterissään (/usr/lib/libreoffice/share/registry/lingucomponent.xcd)
#       että org.openoffice.lingu.MySpellSpellChecker tukee muotoa DICT_SPELL:
#       "<node oor:name=\"org.openoffice.lingu.MySpellSpellChecker\"
#         oor:op=\"fuse\"><prop oor:name=\"SupportedDictionaryFormats\" ...>
#         <value>DICT_SPELL</value>".
#       DICT_HYPH olisi tavutus ja DICT_THES synonyymisanasto.
#   Locales = fi-FI
#       kieli, jolle sanasto tarjotaan. Muoto on BCP-47-tyylinen viivalla,
#       EI alaviivalla — fi_FI ei täsmää mihinkään.
#   Locations
#       polut .aff- ja .dic-tiedostoihin. %origin% korvautuu ajossa sillä
#       hakemistolla, johon laajennus purettiin, joten polut toimivat myös
#       Flatpakin sisällä. Molemmat polut annetaan yhdessä arvossa välilyönnin
#       erottamina, kuten LibreOfficen omissa sanastolaajennuksissa
#       (dictionaries/*/dictionaries.xcu upstreamissa); .aff ensin.
#
# Solmun nimi HunSpellDic_fi_FI on vapaa tunniste, mutta sen on oltava
# yksilöllinen — samanniminen solmu toisesta laajennuksesta ylikirjoittuisi.
cat > "$WORK/dictionaries.xcu" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<oor:component-data xmlns:oor="http://openoffice.org/2001/registry"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    oor:name="Linguistic"
                    oor:package="org.openoffice.Office">
  <node oor:name="ServiceManager">
    <node oor:name="Dictionaries">
      <node oor:name="HunSpellDic_fi_FI" oor:op="fuse">
        <prop oor:name="Locations" oor:type="oor:string-list">
          <value>%origin%/fi_FI.aff %origin%/fi_FI.dic</value>
        </prop>
        <prop oor:name="Format" oor:type="xs:string">
          <value>DICT_SPELL</value>
        </prop>
        <prop oor:name="Locales" oor:type="oor:string-list">
          <value>fi-FI</value>
        </prop>
      </node>
    </node>
  </node>
</oor:component-data>
XML

# --- description.xml -------------------------------------------------------
# Laajennuksen oma kuvaus: tunniste, versio ja näyttönimi.
#
# IDENTIFIER: fi.hunspell.suomen-kieliavut
#   Tunniste on laajennuksen ainoa avain — unopkg tunnistaa sillä päivitykset
#   ja poistot. Valittu käänteinen verkkotunnusmuoto ilman olemassa olevaa
#   domainia, koska repolla ei ole omaa: "fi" (kieli) + "hunspell" (muoto) +
#   repon nimi. EI törmää Voikko-liitännäisen tunnisteeseen
#   org.puimula.ooovoikko (ks. ../raw/libreoffice-voikko-5.0-debian/
#   description.xml) eikä LibreOfficen omien sanastojen muotoon
#   org.openoffice.<kieli>.hunspell.dictionaries, joten tämän voi asentaa
#   niiden rinnalle.
#
# PLATFORM all: paketti on pelkkää dataa, ei binäärejä — asentuu mille tahansa
# alustalle. Ilman tätä unopkg olettaa oletusarvoisesti "all", mutta
# eksplisiittinen arvo on dokumentaatiota lukijalle.
#
# EI VERSIORAJOJA: <dependencies>-lohko on tarkoituksella jätetty pois.
# OpenOffice.org-minimal-version sitoisi paketin alarajaan, ja vastaava
# yläraja jäädyttäisi sen aikaansa. Voikko-liitännäisen description.xml
# (../raw/libreoffice-voikko-5.0-debian/description.xml) ei myöskään aseta
# yhtään versiorajaa — juuri siksi vuoden 2015 paketti rekisteröityy yhä
# LibreOffice 26.8:aan. Sanastolaajennus on pelkkää dataa, jonka rekisteröinti
# on ollut samanlainen OpenOffice.org 3:sta lähtien, joten rajalla ei
# saavutettaisi mitään mutta menetettäisiin sama pitkäikäisyys.
cat > "$WORK/description.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<description xmlns="http://openoffice.org/extensions/description/2006"
             xmlns:d="http://openoffice.org/extensions/description/2006"
             xmlns:xlink="http://www.w3.org/1999/xlink">

  <identifier value="fi.hunspell.suomen-kieliavut" />
  <version value="$VERSION" />
  <platform value="all" />

  <display-name>
    <name lang="fi">Suomen oikolukusanasto (hunspell)</name>
    <name lang="en-US">Finnish spelling dictionary (hunspell)</name>
  </display-name>

  <publisher>
    <name xlink:href="https://github.com/fginter/hunspell-fi" lang="fi">$TEKIJA — $LISENSSI</name>
  </publisher>

</description>
XML

# Jäsennettävyys tarkistetaan heti, kuten build-xpi.sh tarkistaa manifest.jsonin.
python3 - "$WORK" <<'PY'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
for nimi in ("META-INF/manifest.xml", "dictionaries.xcu", "description.xml"):
    ET.parse(Path(sys.argv[1]) / nimi)
PY

OUT="$REPO/build/fi-hunspell-$VERSION.oxt"
rm -f "$OUT"
# -X jättää pois alustakohtaiset lisäkentät (uid/gid, ulkoiset attribuutit).
# Sama kuin build-xpi.sh:ssa.
#
# HUOM: tämä EI tee paketista tavuntarkasti toistettavaa. zip tallentaa kunkin
# tiedoston mtimen, ja tiedostot syntyvät joka ajossa uudelleen $WORKiin, joten
# sama syöte tuottaa eri summan joka kerta (mitattu 2026-09-16: kaksi peräkkäistä
# ajoa c6de9c31... ja 1a3abdc0...). Siksi julkaisuun EI rakenneta uutta pakettia
# vaan viedään puussa oleva build/fi-hunspell-<versio>.oxt, jonka summa on
# SHA256SUMS:issa ja upotettuna install.sh:hon. Ks. .github/workflows/julkaisu.yml.
# Jos paketti rakennetaan uudelleen, molemmat summat on päivitettävä.
( cd "$WORK" && zip -qrX "$OUT" META-INF description.xml dictionaries.xcu fi_FI.aff fi_FI.dic )

echo "==> valmis: $OUT ($(du -h "$OUT" | cut -f1))"
echo "    sanasto: $SANASTO ($(( $(wc -l < "$WORK/fi_FI.dic") - 1 )) sanuetta, $LISENSSI)"
echo "    merkistö: $(head -1 "$WORK/fi_FI.aff")"
echo "    tunniste: fi.hunspell.suomen-kieliavut v$VERSION"
echo "    asennus:  unopkg add $OUT"
echo "    poisto:   unopkg remove fi.hunspell.suomen-kieliavut"
echo "    tarkistus: tools/tarkista-oxt.py $OUT $VERSION"
