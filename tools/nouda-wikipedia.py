#!/usr/bin/env python3
"""Poimi fi-Wikipediasta satunnaisartikkelien johdantokappaleet.

Käyttö: nouda-wikipedia.py <erien-määrä> <ulostulo.jsonl> [ohita-id-tiedosto]

Jokainen erä on yksi API-kutsu ja tuottaa enintään 20 artikkelia. Kaksikymmentä
on MediaWikin katto prop=extracts-kyselylle; se sallii exlimit>1 vain yhdessä
exintro-valitsimen kanssa, joten haemme johdantokappaleet emmekä koko
artikkeleita. Koko artikkeleilla eräkoko olisi 1 ja nouto ~17 kertaa hitaampi.

Ohita-id-tiedosto sisältää pageid:t, joita ei oteta. Sillä pidetään
arviointikorpus ja frekvenssikorpus erillisinä: karsintakriteeriä ei saa
optimoida sitä korpusta vasten, jolla tulos mitataan.

Tuloste on JSONL: {"pageid", "revid", "otsikko", "teksti"} per rivi. revid
talletetaan, jotta otos on jäljitettävissä — Wikipedian teksti muuttuu.

Lisenssi: fi-Wikipedian teksti on CC BY-SA 4.0. Ks. LICENSES.md.
"""
import json, sys, time, urllib.parse, urllib.request

API = "https://fi.wikipedia.org/w/api.php"
UA = "suomen-kieliavut-korpus/0.9 (https://github.com/mhavo/suomen-kieliavut)"

def hae(params):
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    odota = 2.0
    for _ in range(8):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except Exception as e:
            print(f"  uudelleenyritys {odota:.0f} s: {e}", file=sys.stderr)
            time.sleep(odota)
            odota = min(odota * 2, 60)
    raise SystemExit("Wikipedia-API ei vastaa")

def main():
    eria = int(sys.argv[1])
    ulos = sys.argv[2]
    ohita = set()
    if len(sys.argv) > 3:
        with open(sys.argv[3]) as f:
            ohita = {int(x) for x in f.read().split()}

    nahdyt = set()
    with open(ulos, "w", encoding="utf-8") as f:
        for i in range(eria):
            d = hae({
                "action": "query", "format": "json", "formatversion": "2",
                "generator": "random", "grnnamespace": "0", "grnlimit": "20",
                "prop": "extracts|revisions", "explaintext": "1",
                "exintro": "1", "exlimit": "20", "rvprop": "ids",
            })
            for p in d.get("query", {}).get("pages", []):
                pid = p.get("pageid")
                if pid is None or pid in ohita or pid in nahdyt:
                    continue
                teksti = p.get("extract", "")
                if len(teksti) < 150:      # tynkä tai ohjaus
                    continue
                nahdyt.add(pid)
                revid = p.get("revisions", [{}])[0].get("revid")
                f.write(json.dumps({"pageid": pid, "revid": revid,
                                    "otsikko": p.get("title"),
                                    "teksti": teksti}, ensure_ascii=False) + "\n")
            print(f"erä {i+1}/{eria}: {len(nahdyt)} artikkelia", file=sys.stderr)
            time.sleep(1.5)

if __name__ == "__main__":
    main()
