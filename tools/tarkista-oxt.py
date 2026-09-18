#!/usr/bin/env python3
"""Tarkistaa, että .oxt on kelvollinen LibreOffice-sanastolaajennus.

OpenOffice.orgin laajennusmäärittely vaatii, että paketin juuressa on
description.xml ja META-INF/manifest.xml, ja että manifest luettelee jokaisen
tiedoston, joka on käsiteltävä asennuksessa. Sanastolaajennuksessa se tiedosto
on dictionaries.xcu, joka rekisteröi sanaston solmuun
org.openoffice.Office.Linguistic / ServiceManager / Dictionaries muodolla
DICT_SPELL. Jos jokin näistä puuttuu tai osoittaa väärään tiedostoon,
laajennus asentuu näennäisesti mutta oikoluku ei löydä sanastoa koskaan.

Käyttö: tools/tarkista-oxt.py paketti.oxt [odotettu-versio]
"""
import sys
import xml.etree.ElementTree as ET
import zipfile

TUNNISTE = "fi.hunspell.suomen-kieliavut"
PAKOLLISET = [
    "META-INF/manifest.xml",
    "description.xml",
    "dictionaries.xcu",
    "fi_FI.aff",
    "fi_FI.dic",
]
# Nimiavaruudet. Rekisterifragmentin oor: ja laajennuskuvauksen oma
# oletusnimiavaruus; ElementTree kirjoittaa ne tagiin muodossa {uri}nimi.
NS_MANIFEST = "{http://openoffice.org/2001/manifest}"
NS_OOR = "{http://openoffice.org/2001/registry}"
NS_DESC = "{http://openoffice.org/extensions/description/2006}"
XCU_MEDIA = "application/vnd.sun.star.configuration-data"


def jasenna(z, nimi, virheet):
    try:
        return ET.fromstring(z.read(nimi))
    except ET.ParseError as e:
        virheet.append(f"{nimi} ei jäsenny XML:nä: {e}")
        return None


def tarkista_manifest(juuri, virheet):
    polut = {}
    for e in juuri.findall(f"{NS_MANIFEST}file-entry"):
        polut[e.get(f"{NS_MANIFEST}full-path")] = e.get(f"{NS_MANIFEST}media-type")
    if "dictionaries.xcu" not in polut:
        virheet.append("manifest.xml ei luettele dictionaries.xcu:ta — "
                       "laajennus asentuu mutta sanastoa ei rekisteröidä")
    elif polut["dictionaries.xcu"] != XCU_MEDIA:
        virheet.append(f"dictionaries.xcu:n media-type on {polut['dictionaries.xcu']!r}, "
                       f"odotettiin {XCU_MEDIA!r}")


def tarkista_xcu(juuri, virheet):
    if juuri.get(f"{NS_OOR}name") != "Linguistic" or \
            juuri.get(f"{NS_OOR}package") != "org.openoffice.Office":
        virheet.append("dictionaries.xcu ei kohdistu solmuun "
                       "org.openoffice.Office / Linguistic")

    # HUOM: dictionaries.xcu:ssa vain ATTRIBUUTIT ovat oor:-nimiavaruudessa.
    # Elementit node/prop/value ovat etuliitteettömiä eikä tiedostossa ole
    # oletusnimiavaruutta, joten niiden tagi on paljas "node" — ei {oor}node.
    solmut = juuri.findall(f".//node[@{NS_OOR}name='Dictionaries']/node")
    if not solmut:
        virheet.append("dictionaries.xcu: Dictionaries-solmun alla ei ole yhtään sanastoa")
        return

    for solmu in solmut:
        if solmu.get(f"{NS_OOR}op") != "fuse":
            virheet.append(f"sanastosolmu {solmu.get(NS_OOR + 'name')!r}: "
                           "oor:op ei ole \"fuse\" — korvaisi muut sanastot")
        arvot = {}
        for prop in solmu.findall("prop"):
            arvot[prop.get(f"{NS_OOR}name")] = [
                (v.text or "").strip() for v in prop.findall("value")
            ]
        if arvot.get("Format") != ["DICT_SPELL"]:
            virheet.append(f"Format on {arvot.get('Format')}, odotettiin ['DICT_SPELL']")
        if arvot.get("Locales") != ["fi-FI"]:
            virheet.append(f"Locales on {arvot.get('Locales')}, odotettiin ['fi-FI'] "
                           "(viiva, ei alaviiva)")
        # Locations voi olla joko useana arvona tai yhtenä välilyönnein
        # erotettuna merkkijonona; molemmat ovat kelvollista oor:string-listiä.
        polut = " ".join(arvot.get("Locations", [])).split()
        odotetut = ["%origin%/fi_FI.aff", "%origin%/fi_FI.dic"]
        if sorted(polut) != sorted(odotetut):
            virheet.append(f"Locations on {polut}, odotettiin {odotetut}")


def tarkista_description(juuri, odotettu_versio, virheet):
    def arvo(tagi):
        e = juuri.find(f"{NS_DESC}{tagi}")
        return None if e is None else e.get("value")

    tunniste = arvo("identifier")
    if tunniste != TUNNISTE:
        virheet.append(f"identifier on {tunniste!r}, odotettiin {TUNNISTE!r}")

    versio = arvo("version")
    if not versio:
        virheet.append("description.xml: version puuttuu")
    elif odotettu_versio is not None and versio != odotettu_versio:
        virheet.append(f"version on {versio!r}, odotettiin {odotettu_versio!r}")

    if juuri.find(f"{NS_DESC}display-name/{NS_DESC}name") is None:
        virheet.append("description.xml: display-name puuttuu — "
                       "laajennus näkyisi nimettömänä")
    return versio


def main(argv):
    if len(argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    odotettu_versio = argv[2] if len(argv) > 2 else None
    virheet = []

    with zipfile.ZipFile(argv[1]) as z:
        nimet = set(z.namelist())
        for nimi in PAKOLLISET:
            if nimi not in nimet:
                virheet.append(f"paketista puuttuu {nimi}")
        if virheet:
            # Ilman tiedostoja ei ole mitään jäsennettävää.
            for v in virheet:
                print(f"VIRHE: {v}", file=sys.stderr)
            return 1

        # .aff:n SET-rivin on vastattava tiedoston todellista merkistöä.
        aff = z.read("fi_FI.aff")
        ekarivi = aff.split(b"\n", 1)[0].strip()
        if ekarivi == b"SET UTF-8":
            try:
                aff.decode("utf-8")
            except UnicodeDecodeError as e:
                virheet.append(f"fi_FI.aff ilmoittaa SET UTF-8 mutta ei ole UTF-8: {e}")
        elif not ekarivi.startswith(b"SET "):
            virheet.append(f"fi_FI.aff:n ensimmäinen rivi ei ole SET-rivi: {ekarivi!r}")

        m = jasenna(z, "META-INF/manifest.xml", virheet)
        x = jasenna(z, "dictionaries.xcu", virheet)
        d = jasenna(z, "description.xml", virheet)

    if m is not None:
        tarkista_manifest(m, virheet)
    if x is not None:
        tarkista_xcu(x, virheet)
    versio = tarkista_description(d, odotettu_versio, virheet) if d is not None else None

    if virheet:
        for v in virheet:
            print(f"VIRHE: {v}", file=sys.stderr)
        return 1

    print(f"oxt ok: {TUNNISTE} v{versio} ({len(PAKOLLISET)} pakollista tiedostoa, "
          f"{ekarivi.decode('ascii', 'replace')})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
