# Lähteet, alkuperä ja lisenssit

> Tiedostokohtainen lisenssierittely on omassa tiedostossaan:
> **[LICENSES.md](../LICENSES.md)**. Tämä dokumentti kertoo mistä aineisto
> tulee; LICENSES.md kertoo millä ehdoilla sitä saa käyttää.

## Ohjelmistot

| Komponentti | Lähde | Lisenssi |
|---|---|---|
| libvoikko | https://voikko.puimula.org · Arch: `extra/libvoikko` | GPL-2.0-or-later |
| voikko-fi (morfologia) | https://github.com/voikko/corevoikko · AUR: `voikko-fi` | GPL-2+ |
| voikko-libreoffice | AUR: `voikko-libreoffice` 5.0 · `org.puimula.ooovoikko` | **MPL-2.0 / GPL-3.0+** (kaksoislisenssi) |
| enchant + `enchant_voikko.so` | Arch: `extra/enchant` | LGPL-2.1+ |
| convert_dict | Chromium, `chrome/tools/convert_dict` | BSD-3-Clause |
| convert_dict -binäärit | https://github.com/jankelemen/convert-dict-tool-from-chromium | BSD-3-Clause |

`voikko-fi`-paketin `index.txt` kertoo aineiston tekijät:

```
Copyright: 2006-2020 Hannu Väisänen, Harri Pitkänen, Teemu Likonen and others
License: GPL version 2 or later
Description: suomi (perussanasto)
SM-Version: 2.4
```

## Sanastot

**`dict/ginter/`** — Filip Ginter, *Finnish Spell Dictionary* 0.2, julkaistu
2023-12-06. Lisenssi **CC0**.

Upstream on GitHub, ei AMO: <https://github.com/fginter/hunspell-fi>, release
`0.2`, liite `fi-spell-0.2.xpi`. Laajennuksen sisäinen gecko-id on
`fi@dictionaries.addons.mozilla.org`, mutta laajennusta ei ole julkaistu AMO:ssa
— AMO:n hakemistosta löytyy vain `fluks`in vanhempi *Finnish Spellchecker*
(`fi-FI@dictionaries…`, GPL-2), joka on eri sanasto.

`build/fi-spell-0.2.xpi` on tämä upstreamin **alkuperäinen julkaisu
sellaisenaan**, ei tässä repossa rakennettu. Varmennettu 2026-09-16
lataamalla release-liite uudelleen ja vertaamalla SHA-256:

```
95ded62bc3de347c91d7c91e8d2abb2405e3475bfb7bf735070db11198131a81  fi-spell-0.2.xpi
```

Tiedostot `dict/ginter/fi_FI.aff` ja `fi_FI.dic` on purettu tästä samasta
`.xpi`:stä.

Lisenssistä: upstreamin `README.md` sanoo `# License` / `CC0`. Aineisto on
rakennettu TurkuNLP:n parsebank-korpuksesta, jota on **suodatettu** Voikolla;
Voikkoa on siis käytetty työkaluna, ei aineistolähteenä. Ks. [LICENSES.md](../LICENSES.md).

**`dict/myspell-fi-0.7/`** — Martin Vermeer ja Pauli Virtanen. Alkuperäinen
Debianin paketti `myspell-fi 0.7-18`; tämä kopio on repon
https://github.com/fluks/fi-FI-mozilla-spellchecker kautta (sekin GPL-2).
**GPL-2.0-only**, ks. `dict/myspell-fi-0.7/copyright` ja koko lisenssiteksti
`dict/myspell-fi-0.7/LICENSE`.

**`dict/hyphen/hyph_fi_FI.dic`** — LibreOfficen tavutuskuviot, Debianin
paketista `hyphen-fi`. Kuviot: Kauko Saarinen (1986, uudelleenkirjoitettu 1988),
lisäyksiä Fred Karlsson ja Thomas Esser; muunnos LibHnj-muotoon Jarno Elonen
2003. Ks. `README_hyph_fi_FI.txt` samassa hakemistossa. Archissa vastaavaa
pakettia ei ole.

**Ei muodollista lisenssiä.** Ainoa käyttöehto on alkuperäisen kuviotiedoston
rivi *"Patterns may be freely distributed"*. Tiedosto levitetään tässä
muuttumattomana ja alkuperäisen README:nsä kanssa, mikä on ainoa ehdon selvästi
sallima tapa. Ks. [LICENSES.md](../LICENSES.md).

## Valmiit tuotteet `build/`-hakemistossa

| Tiedosto | Lähdesanasto | Työkalu |
|---|---|---|
| `fi-spell-0.2.xpi` | — | **ei rakennettu täällä**: upstreamin alkuperäinen julkaisu |
| `fi-FI.bdic` | Ginter karsittuna (245 000 sanuetta) | `convert_dict` |
| `fi-FI-myspell-0.7.bdic` | myspell-fi 0.7 | `convert_dict` |
| `fi.utf-8.spl` | Ginter kokonaan | Neovimin `:mkspell` |

Chromium-sanasto on karsittu, koska koko Ginter ei mahdu `.bdic`-muotoon;
`fi-FI-myspell-0.7.bdic` on vuosien 2025–2026 vanha versio, säilytetty
vertailuksi. Ks. [convert-dict.md](convert-dict.md) ja [sanastot.md](sanastot.md).

`tools/build-xpi.sh` **ei** rakenna `fi-spell-0.2.xpi`:tä uudelleen: upstreamin
paketissa on kaksi kuvaketta ja tekijän oma `"Very quick effort"` -kuvausteksti,
joita skripti ei toisinna. Skripti tuottaa erikseen nimetyn
`build/fi-spell-oma-<versio>.xpi`:n.

Kaikkien tuotosten ja lähdesanastojen SHA-256-summat sekä käytetyt
työkaluversiot ovat tiedostossa [`SHA256SUMS`](../SHA256SUMS):

```bash
sha256sum -c SHA256SUMS
```

**`tools/korpus/`** — arviointikorpus, jolla sanastojen kattavuus mitataan.
Kaksi riippumatonta osakorpusta, molemmat kolmannen osapuolen vapaata
aineistoa:

| Tiedosto | Lähde | Lisenssi |
|---|---|---|
| `ud-tdt.txt` | [UD Finnish-TDT](https://github.com/UniversalDependencies/UD_Finnish-TDT) (Turku Dependency Treebank) | CC BY-SA 4.0 |
| `wikipedia.txt` | fi-Wikipedian satunnaisartikkelien johdantokappaleet | CC BY-SA 4.0 |

Lisäksi `tools/korpus-frekvenssit.txt` on **eri** fi-Wikipedia-otoksesta
laskettu sanafrekvenssilista. Se on `tools/build-bdic.sh`:n karsintakriteerin
syöte, ei osa arviointikorpusta: karsintaa ei saa optimoida sitä korpusta
vasten, jolla tulos mitataan.

Poiminta on toistettavissa:

```bash
tools/nouda-wikipedia.py 200 otos.jsonl
tools/rakenna-korpus.py wikipedia otos.jsonl --ulos tools/korpus/wikipedia.txt
```

Yksityiskohdat, tokenisointisäännöt ja mittarin rajoitukset:
[`tools/korpus/LUE.md`](../tools/korpus/LUE.md).

## Muuttumaton lähdeaineisto `raw/`

- `raw/libreoffice-voikko-5.0-debian/` — Debianin paketin `libreoffice-voikko`
  purettu sisältö vanhalta Ubuntu-asennukselta. Asennettavissa suoraan
  `unopkg add --shared`-komennolla, jos AUR-paketti katoaa.
- `raw/fluks-install.rdf` — vanhan XUL-aikaisen Firefox-sanastolaajennuksen
  asennusmanifesti repon `fluks/fi-FI-mozilla-spellchecker` mukaan (GPL-2).
  Historiallinen; nykyinen `.xpi` käyttää `manifest.json`ia.
- `raw/convert-dict-tool-LICENSE` — Chromiumin BSD-3-Clause-lisenssi. Koskee
  `tools/build-bdic.sh`:n ajohetkellä noutamaa `convert_dict`-työkaluketjua,
  jonka commit ja tiedostosummat on lukittu tiedostoon `tools/convert-dict.sha256`.
- `raw/aur-voikko-libreoffice/` — AUR-paketin `PKGBUILD` ja `.install`-skripti,
  joka näyttää miten Arch rekisteröi laajennuksen. `PKGBUILD` ilmoittaa
  lisenssiksi MPL:n, ja lähdekoodin otsakkeet vahvistavat sen: MPL-2.0 tai
  vaihtoehtoisesti GPL-3.0+. Ks. [arch-vs-debian.md](arch-vs-debian.md).

## Alkuperäinen työ

Nämä tiedostot löytyivät vanhalta Ubuntu-asennukselta, päiväyksillä
24.–25.2.2025. Ne oli
koottu ilman muistiinpanoja, ja tämä repo on jälkikäteen tehty rekonstruktio
siitä mitä silloin tehtiin. Ubuntu-puolen pakettivalinta oli:

```
libvoikko1  voikko-fi  libreoffice-voikko  libenchant-2-voikko
hyphen-fi  python3-libvoikko
```

## Aiheeseen liittyvää luettavaa

- Chromiumin sanastodokumentaatio:
  https://www.chromium.org/developers/how-tos/editing-the-spell-checking-dictionaries
- Hunspellin `.aff`-muodon dokumentaatio: `man 5 hunspell`
- Voikon arkkitehtuuri: https://voikko.puimula.org/architecture.html
- Vimin oikolukusanastojen kääntäminen: `:help mkspell`
- Vimin `.spl`-muodon versiovakio `VIMSPELLVERSION`:
  https://github.com/vim/vim/blob/master/src/spellfile.c
- KDE:n Sonnet, taustaosan valinta ja asetusten tallennus:
  https://invent.kde.org/frameworks/sonnet — `src/core/loader.cpp`,
  `src/core/settingsimpl.cpp`, `src/plugins/voikko/voikkoclient.cpp`
- Emacsin jinx, enchantin C-API suoraan: https://github.com/minad/jinx
- Flatpakin sanastolaajennukset:
  https://www.ctrl.blog/entry/flatpak-locale-dictionaries.html
- Sama ongelma Flathubin LibreOfficessa (koskee unkaria, ei suomea):
  https://github.com/flathub/org.libreoffice.LibreOffice/issues/62
- Ekosysteemin tilan kyselyt (AUR, Debian, AMO) ja niiden tulokset:
  [jakelu.md](jakelu.md)
