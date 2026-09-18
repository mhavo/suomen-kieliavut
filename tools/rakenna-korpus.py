#!/usr/bin/env python3
"""Rakentaa arviointikorpuksen ja frekvenssilistan raaka-aineistosta.

    rakenna-korpus.py wikipedia <jsonl...> --ulos tools/korpus/wikipedia.txt
    rakenna-korpus.py ud <conllu...>       --ulos tools/korpus/ud-tdt.txt
    rakenna-korpus.py frekvenssit <jsonl...> --ulos tools/korpus-frekvenssit.txt

Tuloste on aina "sana<TAB>esiintymät", lajiteltuna. Frekvenssilistassa on
lisäksi --vahintaan-karsinta, jotta tiedosto pysyy kohtuullisen kokoisena.

MIKSI TOKENISOINTI ON NÄIN TIUKKA

Arviointikorpuksen jokaisen sanan on oltava oikeinkirjoitettua suomea, tai
kattavuuden katto on tuntematon eikä mittari erota sanaston puutetta korpuksen
virheestä. Kaksi eri keinoa kahdelle lähteelle:

  ud        UD Finnish-TDT on käsin tarkistettu treebank, jossa on sanaluokat.
            Erisnimet (PROPN), numerot, välimerkit ja vieraskieliset katkelmat
            (X) pudotetaan sanaluokan perusteella. Loppu on gold standard.

  wikipedia Sanaluokkia ei ole, joten erisnimet karsitaan typografisesti:
            mukaan otetaan VAIN tokenit, jotka ovat alkutekstissä kokonaan
            pieniä kirjaimia. Tämä pudottaa myös virkkeen ensimmäiset sanat,
            mikä on tilastollisesti harmitonta tämän kokoisessa otoksessa ja
            poistaa erisnimet ilman sanalistaa. (Sanalistalla suodattaminen
            olisi kehäpäätelmä: se tekisi mitattavasta sanastosta mittarin.)

            Jäljelle jää silti Wikipedian omia kirjoitusvirheitä ja
            vierassanoja. Niiden osuutta ei ole mitattu; se on kaikille
            vertailtaville sanastoille sama, joten sanastojen keskinäinen
            järjestys ei siitä muutu, mutta absoluuttinen kattavuus on
            hieman todellista matalampi. Ks. tools/korpus/LUE.md.

Lisenssi: molemmat lähteet ovat CC BY-SA 4.0, joten myös tämän skriptin
tuottamat sanalistat ovat johdettua aineistoa. Ks. LICENSES.md.
"""
import argparse
import collections
import json
import re
import sys

# Suomen kirjaimet + ne vierasperäiset, jotka esiintyvät suomalaisessa
# tekstissä sellaisenaan.
#
# YHDYSVIIVALLISET SANAT PUDOTETAAN, eikä se ole makuasia: hunspell
# tokenisoi syöterivin itse ja pilkkoo yhdysviivallisen sanan osiin,
# raportoiden hylkynä vain virheellisen OSAN. voikkospell taas lukee koko
# rivin yhtenä sanana. Jos yhdysviivalliset olisivat mukana, moottoreita
# verrattaisiin eri yksiköillä — ja hunspellin kattavuus näyttäisi
# todellista paremmalta, koska hylätty osa ei täsmää korpuksen sanaan
# lainkaan. Mitattu: 1254 yhdysviivallista 63 895 sanasta nosti Ginterin
# type-kattavuutta 87,6 %:sta 88,3 %:iin, eli 0,7 prosenttiyksikköä
# perusteetta.
SANA = re.compile(r"^[a-zåäöšžéèüáà]+$")
JAKO = re.compile(r"[^A-Za-zÅÄÖåäöŠšŽžÉéÈèÜüÁáÀà-]+")

OHITA_UPOS = {"PROPN", "NUM", "PUNCT", "SYM", "X"}


def wikipedia_tokenit(tiedostot):
    for polku in tiedostot:
        with open(polku, encoding="utf-8") as f:
            for rivi in f:
                if not rivi.strip():
                    continue
                teksti = json.loads(rivi).get("teksti", "")
                for pala in JAKO.split(teksti):
                    pala = pala.strip("-")
                    if "-" in pala:
                        continue
                    # Vain alkutekstissä pienellä kirjoitetut: pudottaa
                    # erisnimet ja virkkeenalkuiset sanat.
                    if len(pala) >= 2 and pala == pala.lower() and SANA.match(pala):
                        yield pala


def ud_tokenit(tiedostot):
    for polku in tiedostot:
        with open(polku, encoding="utf-8") as f:
            for rivi in f:
                if not rivi or rivi[0] == "#" or "\t" not in rivi:
                    continue
                k = rivi.rstrip("\n").split("\t")
                if len(k) < 4 or not k[0].isdigit():
                    continue          # monisanaiset rivit (1-2) ja tyhjät solmut
                muoto, upos = k[1], k[3]
                if upos in OHITA_UPOS:
                    continue
                pieni = muoto.lower()
                if len(pieni) >= 2 and SANA.match(pieni):
                    yield pieni


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("laji", choices=("wikipedia", "ud", "frekvenssit"))
    ap.add_argument("tiedostot", nargs="+")
    ap.add_argument("--ulos", required=True)
    ap.add_argument("--vahintaan", type=int, default=1,
                    help="jätä pois sanat, jotka esiintyvät harvemmin (oletus 1)")
    a = ap.parse_args()

    tokenit = (ud_tokenit if a.laji == "ud" else wikipedia_tokenit)(a.tiedostot)
    laskuri = collections.Counter(tokenit)

    with open(a.ulos, "w", encoding="utf-8") as f:
        for sana in sorted(laskuri):
            if laskuri[sana] >= a.vahintaan:
                f.write(f"{sana}\t{laskuri[sana]}\n")

    kirjoitettu = sum(1 for s in laskuri if laskuri[s] >= a.vahintaan)
    print(f"{a.ulos}: {kirjoitettu} uniikkia sanaa, "
          f"{sum(laskuri.values())} esiintymää", file=sys.stderr)


if __name__ == "__main__":
    main()
