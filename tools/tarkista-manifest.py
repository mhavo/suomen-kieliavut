#!/usr/bin/env python3
"""Tarkistaa, että .xpi:n manifest.json on kelvollinen Firefox-sanastolaajennus.

MDN, manifest.json/dictionaries:
  "If you use the dictionaries key, you must also set an ID for your extension
   using the browser_specific_settings manifest.json key."

MIKSI VANHA "applications"-AVAIN KELPAA TÄSSÄ

MDN:n muotoilu koskee uutta laajennusta. Vanhentunut "applications" on yhä
manifest_version 2:n tuettu alias, ja sitä käyttää mm. upstreamin alkuperäinen
build/fi-spell-0.2.xpi, jota tämä repo jakelee muuttumattomana lisenssisyistä
(ks. LICENSES.md). Jos tämä tarkistin vaatisi ehdottomasti
browser_specific_settings-avainta, se hylkäisi juuri sen tiedoston jonka
julkaisemme — mikä oli tilanne ennen 0.9:ää, ja syy siihen ettei jaeltavaa
.xpi:tä validoitu lainkaan CI:ssä.

Sääntö on siis: id:n ON oltava, jommassakummassa avaimessa; jos molemmat ovat,
niiden on oltava samat. Pelkkä vanha avain tuottaa varoituksen, ei virhettä.
Omissa paketeissa (tools/build-xpi.sh) asetetaan molemmat.

Käyttö: unzip -p paketti.xpi manifest.json | tools/tarkista-manifest.py
        tools/tarkista-manifest.py paketti.xpi
"""
import json
import sys
import zipfile

ID = "fi@dictionaries.addons.mozilla.org"


def lue(argv):
    if len(argv) > 1:
        with zipfile.ZipFile(argv[1]) as z:
            return json.loads(z.read("manifest.json"))
    return json.load(sys.stdin)


def main(argv):
    m = lue(argv)
    virheet = []

    if m.get("manifest_version") != 2:
        virheet.append(f"manifest_version on {m.get('manifest_version')}, odotettiin 2")

    if "dictionaries" not in m:
        virheet.append("dictionaries-avain puuttuu — Firefox ei tunnista sanastoksi")
    elif m["dictionaries"].get("fi") != "dictionaries/fi_FI/fi_FI.dic":
        virheet.append(f"dictionaries.fi osoittaa väärään polkuun: {m['dictionaries'].get('fi')}")

    # Id voi tulla kummasta tahansa avaimesta; ks. moduulin docstring.
    bss = m.get("browser_specific_settings", {}).get("gecko", {}).get("id")
    vanha = m.get("applications", {}).get("gecko", {}).get("id")
    varoitukset = []

    if bss is None and vanha is None:
        virheet.append(
            "laajennuksen id puuttuu: ei browser_specific_settings.gecko.id "
            "eikä applications.gecko.id — dictionaries-avain vaatii id:n"
        )
    elif bss is not None and vanha is not None and bss != vanha:
        virheet.append(
            f"applications.gecko.id ({vanha!r}) eroaa "
            f"browser_specific_settings:istä ({bss!r}) — Firefox voi tulkita "
            "paketin eri laajennukseksi"
        )

    tunnus = bss if bss is not None else vanha
    if tunnus is not None and tunnus != ID:
        virheet.append(f"gecko.id on {tunnus!r}, odotettiin {ID!r}")

    if bss is None and vanha is not None:
        varoitukset.append(
            "id tulee vanhentuneesta applications-avaimesta; uusissa paketeissa "
            "käytä browser_specific_settings-avainta"
        )

    if not m.get("version"):
        virheet.append("version puuttuu")

    for v in varoitukset:
        print(f"VAROITUS: {v}", file=sys.stderr)

    if virheet:
        for v in virheet:
            print(f"VIRHE: {v}", file=sys.stderr)
        return 1

    print(f"manifest ok: {tunnus} v{m['version']} ({m.get('name')})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
