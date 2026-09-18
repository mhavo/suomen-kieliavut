# Lisenssit tiedostoittain

Tämä repo sisältää **oman työn** lisäksi **kolmannen osapuolen aineistoa**
kolmella eri lisenssillä. Ne eivät ole yhtä ja samaa lisenssiä, toisin kuin
tämän repon aiemmat versiot antoivat ymmärtää.

## Oma työ — MIT

| Polku | Tekijä | Lisenssi |
|---|---|---|
| `tools/*.sh` | Miika Havo | MIT, ks. [LICENSE](LICENSE) |
| `tools/testisanat.txt` | Miika Havo | MIT |
| `docs/*.md`, `README.md` | Miika Havo | MIT |
| `.github/workflows/` | Miika Havo | MIT |

## Sanastot

| Polku | Tekijä | Lisenssi | Lisenssiteksti mukana |
|---|---|---|---|
| `dict/ginter/` | Filip Ginter | **CC0-1.0** | ei — ks. alla |
| `dict/ginter-karsittu/` | johdettu `dict/ginter/`:stä | **CC0-1.0** — ks. alla | ei |
| `dict/myspell-fi-0.7/` | Martin Vermeer, Pauli Virtanen | **GPL-2.0-only** | kyllä: `dict/myspell-fi-0.7/LICENSE` |
| `dict/hyphen/` | Kauko Saarinen ym., muunnos Jarno Elonen | **ei muodollista lisenssiä** — ks. alla | ei |

### `dict/ginter/` — CC0

Upstream on **`fginter/hunspell-fi`** GitHubissa, ei AMO. Sen `README.md`
sanoo lisenssiksi yksiselitteisesti:

```
# License

CC0
```

Aineisto on rakennettu TurkuNLP:n parsebank-korpuksesta, jota on **suodatettu**
Voikolla oikein kirjoitettuihin muotoihin. Voikkoa on siis käytetty työkaluna,
ei aineistolähteenä. Tekijän oma tulkinta on että tulos on CC0; tätä repoa
levitetään sillä tulkinnalla. Jos suodattamisen katsottaisiin tuottavan Voikon
GPL-2+-aineiston johdannaisen, tulkinta olisi eri — mutta se on kysymys
upstreamille, ei tälle repolle.

Upstream ei toimita erillistä `LICENSE`-tiedostoa `.xpi`:n sisällä, joten
sellaista ei ole täälläkään. Lisenssitieto on repon README:ssä:
<https://github.com/fginter/hunspell-fi>

> **AVOIN KYSYMYS — rajattu, ei koske lisenssimerkintää.**
> Lisenssi on merkitty: upstreamin README sanoo `# License` / `CC0`
> (tarkistettu 2026-09-16). Se ei kuitenkaan ratkaise sitä, miten
> Voikko-suodatus tulkitaan — tekijän oma lisenssivalinta ei sido, jos
> aineisto olisi jonkin toisen teoksen johdannainen. Jakelijan vastuu ei
> siirry upstreamille: AUR:iin ja AMO:hon vietäessä jakelija on tämän repon
> ylläpitäjä. Upstreamilta on siis yhä tarkoitus pyytää
> (a) maininta siitä, miten Voikko-suodatus on tulkittu, ja
> (b) mieluiten `LICENSE`-tiedosto repoon — sellaista ei ole,
> lisenssitieto on vain README:ssä.
> Vastaus linkitetään tähän kun se saadaan.
>
> 0.9 julkaistaan ennen vastausta. **AMO-vientiä ei tehdä ennen sitä:** AMO
> jakaa vain binääripaketin eikä siinä ole mekanismia GPL-2:n
> lähdevaatimuksen täyttämiseen, joten sinne saa viedä vain aineistoa, jonka
> CC0-status on varma.

### `dict/ginter-karsittu/` — karsintakriteeri ja miksi ketju on puhdas

Ginterin sanasto (476 292 sanuetta) ei mahdu `.bdic`-muotoon, joten se on
karsittava. Karsintakriteeri ratkaisee lisenssin: jos kriteeri katsoo
GPL-lisensoitua aineistoa, tulos on siitä johdettu teos.

**Nykyinen kriteeri** (`tools/build-bdic.sh frekvenssi`): sanan
esiintymistiheys vapaassa korpuksessa `tools/korpus-frekvenssit.txt`
(fi-Wikipedia, CC BY-SA 4.0), tasapelit sanan pituudella. Varareitti
`build-bdic.sh pituus` käyttää pelkkää sananpituutta eikä lue mitään
ulkoista aineistoa.

Kumpikaan ei katso `dict/myspell-fi-0.7/`:ää. Lopputulos sisältää siis vain
Ginterin sanoja, valittuna kriteerillä, joka ei ole kenenkään muun kuratoima
valinta. `CC0-1.0` periytyy suoraan lähteestä.

**Sääntö, jota ei saa rikkoa myöhemmin:** karsintakriteeri ei saa antaa
valintaetusijaa myspell-fi 0.7:n sanalistalla oleville sanoille eikä muutenkaan
lukea sitä. Se lista on GPL-2.0-only, ja sen kuratoitu valinta ei voi olla yhtä
aikaa se, mikä tekee tuloksesta hyvän, ja se, mikä ei periydy lisenssiin.

### Arviointikorpus ja frekvenssilista

| Polku | Lähde | Lisenssi |
|---|---|---|
| `tools/korpus/ud-tdt.txt` | UD Finnish-TDT / Turku Dependency Treebank | **CC BY-SA 4.0**, johdettu aineisto |
| `tools/korpus/wikipedia.txt` | fi-Wikipedian artikkelitekstiä | **CC BY-SA 4.0**, johdettu aineisto |
| `tools/korpus-frekvenssit.txt` | fi-Wikipedian artikkelitekstiä | **CC BY-SA 4.0**, johdettu aineisto |

Kaikki kolme ovat **sanalistoja, jotka on johdettu kolmannen osapuolen
tekstistä**, eivät tämän repon tekijän omaa työtä. Poimintaskriptit
(`tools/nouda-wikipedia.py`, `tools/rakenna-korpus.py`) ovat omaa työtä ja
MIT-lisensoituja; niiden **tuloste** ei ole.

Sanalista tuskin ylittää teoskynnystä, joten CC BY-SA:n share-alike-ehdon
soveltuminen on epävarmaa. Merkintä on silti tehty varovaisemman tulkinnan
mukaan: lähde ja lähteen lisenssi nimettynä.

### `dict/hyphen/hyph_fi_FI.dic` — ei muodollista lisenssiä

`README_hyph_fi_FI.txt` sisältää alkuperäisten TeX-kuvioiden ainoan
käyttöehdon:

```
  Patterns may be freely distributed
```

Tämä ei ole tunnistettu vapaa lisenssi eikä siinä sanota mitään muokkaamisesta
tai johdannaisista. Tiedosto levitetään tässä muuttumattomana ja sen
alkuperäisen README:n kanssa, mikä on ainoa käyttöehdon sallima tapa.
Sama tiedosto on Debianin paketissa `hyphen-fi`.

**Alkuperää ei ole tavoitettu.** Kuvioiden tekijä (Kauko Saarinen) eikä
muunnoksen tekijä (Jarno Elonen) ole vahvistanut ehdon
*"Patterns may be freely distributed"* tulkintaa tälle repolle. Yhteydenottoa
ei ole yritetty. Tämä on tietoinen 0.9:n rajaus: tiedostoa levitetään
bitilleen muuttumattomana alkuperäisen README:n kanssa, mikä on ainoa tapa,
jonka ehto kiistatta sallii.

## `build/` — johdetut tuotokset

Johdannainen perii lähdesanastonsa lisenssin:

| Tiedosto | Lähde | Lisenssi |
|---|---|---|
| `fi-spell-0.2.xpi` | **upstreamin alkuperäinen**, ei tässä rakennettu | CC0-1.0 |
| `fi-hunspell-0.9.oxt` | `dict/ginter/` | CC0-1.0 |
| `fi-FI.bdic` | `dict/ginter-karsittu/` | CC0-1.0 |
| `fi.utf-8.spl` | `dict/ginter/` | CC0-1.0 |
| `fi-FI-myspell-0.7.bdic` | `dict/myspell-fi-0.7/` | GPL-2.0-only — **vain vertailuun**, ei jaella julkaisussa |

Huomaa, että `.oxt` sisältää **koko** Ginterin sanaston ja `.bdic` karsitun.
Ero ei ole lisenssiperäinen: karsinta on `.bdic`-muodon kokorajoitus (ks.
yllä), eikä `.oxt`:llä ole sitä rajoitusta. Molemmat variantit ovat CC0-1.0,
joten ero näkyy kattavuudessa, ei lisenssiketjussa.

`.oxt` sisältää tasan kuusi tiedostoa: `META-INF/manifest.xml`,
`description.xml`, `dictionaries.xcu`, `fi_FI.aff` ja `fi_FI.dic`. Siinä ei
ole tavutustiedostoa eikä lisenssitekstiä — `dict/hyphen/` jaellaan erikseen
(julkaisun liitetiedostona ja AUR:n `hyphen-fi`-pakettina), ja lisenssiketju
on tässä tiedostossa, joka on julkaisun liitetiedosto.

## `raw/` — muuttumaton lähdeaineisto

| Polku | Lisenssi | Peruste |
|---|---|---|
| `raw/libreoffice-voikko-5.0-debian/` | **MPL-2.0 tai GPL-3.0-or-later** (kaksoislisenssi) | lähdekooditiedostojen otsakkeet, esim. `lovoikko.py` |
| `raw/aur-voikko-libreoffice/PKGBUILD` | MPL (`license=('MPL')`) | PKGBUILD itse |
| `raw/convert-dict-tool-LICENSE` | BSD-3-Clause | Chromiumin lisenssi |
| `raw/fluks-install.rdf` | GPL-2.0-only | repo `fluks/fi-FI-mozilla-spellchecker` |

Huom: `voikko-libreoffice` on **MPL-2.0/GPL-3+**, ei GPL-2+. Sen
`lovoikko.py`:n otsake:

```
# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. ...
# Alternatively, the contents of this file may be used under the terms of
# the GNU General Public License Version 3 or later (the "GPL") ...
```

## Riippuvuudet, joita ei levitetä tässä

Nämä asennetaan distron paketeista eikä niiden koodia ole täällä:

| Komponentti | Lisenssi |
|---|---|
| libvoikko | GPL-2.0-or-later |
| voikko-fi (morfologia) | GPL-2.0-or-later |
| enchant + `enchant_voikko.so` | LGPL-2.1-or-later |
| `convert_dict` (Chromium) | BSD-3-Clause |
