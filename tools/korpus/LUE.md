# Arviointikorpus

`tools/arvioi-korpuksella.sh` mittaa sanastovaihtoehtojen kattavuuden näillä
tiedostoilla. Muoto on `sana<TAB>esiintymät`, yksi sana per rivi, lajiteltuna.

Tämä korpus **korvasi** aiemman yhden lähteen 1119 sanan listan. Syyt
vaihtoon:

- 1119 sanaa antaa ±1,2 prosenttiyksikön luottamusvälin 95 %:n tuntumassa.
  Yhden desimaalin raportointi oli sillä otoskoolla harhaanjohtavaa.
- Yksi lähde ei kerro yleistettävyydestä mitään.
- Vanhassa listassa oli katkenneita sanoja (`istä`), kirjoitusvirheitä ja
  englanninkielisiä juuria. Ne ovat aitoa käyttökieltä, mutta mittaavat eri
  asiaa kuin oikolukusanaston kattavuus: mikään suomen sanasto ei voi
  tunnistaa niitä, joten ne asettavat kattavuudelle tuntemattoman katon.
- Lähteen alkuperä ja lisenssi eivät olleet luotettavasti selvitettävissä.

## Osakorpukset

| Tiedosto | Lähde | Lisenssi | Poiminta |
|---|---|---|---|
| `ud-tdt.txt` | [UD Finnish-TDT](https://github.com/UniversalDependencies/UD_Finnish-TDT) (Turku Dependency Treebank) | CC BY-SA 4.0 | `tools/rakenna-korpus.py ud` |
| `wikipedia.txt` | fi-Wikipedian satunnaisartikkelien johdantokappaleet | CC BY-SA 4.0 | `tools/nouda-wikipedia.py` + `rakenna-korpus.py wikipedia` |

### `ud-tdt.txt`

Käsin tarkistettu treebank, 674 dokumenttia useasta rekisteristä (Wikipedia,
Wikinews, yliopistouutiset, blogit, opiskelijalehdet, kielioppiesimerkit,
Europarl, JRC-Acquis, talousuutiset, kaunokirjallisuus). Erisnimet (`PROPN`),
numerot, välimerkit, symbolit ja vieraskieliset katkelmat (`X`) on pudotettu
sanaluokkamerkinnän perusteella. Loppu on gold standard: jokainen sana on
oikeinkirjoitettua suomea.

**Huomaa suhde Ginterin sanastoon.** TDT:n tekijöihin kuuluu Filip Ginter,
saman ryhmän jäsen, joka tuotti `dict/ginter/`:n. Sanasto ei kuitenkaan ole
johdettu TDT:stä vaan parsebank-korpuksesta, joten kyse ei ole samasta
aineistosta. Yhteys on silti kirjattava.

### `wikipedia.txt`

Satunnaisotos, poimittu MediaWikin `generator=random`-rajapinnalla. Mukaan on
otettu vain tokenit, jotka ovat alkutekstissä **kokonaan pieniä kirjaimia** —
tämä pudottaa erisnimet ilman sanalistaa. Sanalistalla suodattaminen olisi
kehäpäätelmä: se tekisi mitattavasta sanastosta mittarin.

**Mitä tämä ei poista:** Wikipedian omat kirjoitusvirheet ja vierassanat
(esim. `type`). Niiden osuutta ei ole mitattu. Vaikutus on kaikille
vertailtaville sanastoille sama, joten sanastojen keskinäinen järjestys ei
muutu, mutta absoluuttinen kattavuus on hieman todellista matalampi.
Aja `arvioi-korpuksella.sh --oov <hakemisto>` ja lue OOV-otos, jos haluat
arvioida sen suuruusluokkaa itse.

## Frekvenssilista on eri tiedosto

`tools/korpus-frekvenssit.txt` on `build-bdic.sh`:n karsintakriteerin syöte,
ei osa arviointikorpusta. Se on poimittu **eri artikkelijoukosta** kuin
`wikipedia.txt` (`nouda-wikipedia.py`:n ohita-id-tiedosto pitää joukot
erillään), jottei karsintaa optimoida sitä korpusta vasten, jolla tulos
mitataan.

## Yhdysviivalliset sanat on pudotettu molemmista

Tämä ei ole makuasia vaan mittarin ehto. **hunspell tokenisoi syöterivin
itse** ja pilkkoo yhdysviivallisen sanan osiin, raportoiden hylkynä vain
virheellisen *osan*. **voikkospell lukee koko rivin yhtenä sanana.** Jos
yhdysviivalliset olisivat mukana, moottoreita verrattaisiin eri yksiköillä —
ja hunspellin kattavuus näyttäisi todellista paremmalta, koska hylätty osa ei
täsmää korpuksen sanaan lainkaan.

Mitattu ennen korjausta: 1254 yhdysviivallista 63 895 sanasta nosti Ginterin
type-kattavuutta 87,6 %:sta 88,3 %:iin, eli 0,7 prosenttiyksikköä
perusteetta.

Seuraus: korpus ei mittaa yhdyssanojen tunnistusta yhdysviivan yli. Se on
tietoinen rajaus; yhdyssanojen tunnistus näkyy silti mittarissa, koska
suomen yhdyssanat kirjoitetaan pääsääntöisesti ilman viivaa
(`tarkkailukehä`, ei `tarkkailu-kehä`).

## Mitä luvut eivät kerro

- **Luottamusväli koskee otantavirhettä, ei edustavuutta.** Kolme osakorpusta
  ei ole satunnaisotos "suomen kielestä".
- **Voikko-vertailu on osin kehäpäätelmä.** Ginterin sanasto on rakennettu
  suodattamalla parsebank-korpus Voikolla, joten Ginterin sanat ovat
  määritelmällisesti Voikon hyväksymien muotojen osajoukko. Voikko ei voi
  juuri hävitä. Johtopäätös on silti oikea — syy (morfologinen analyysi vs.
  sanalista) on riippumaton mittauksesta — mutta luku ei ole riippumaton
  todiste. Ks. `docs/sanastot.md`.
