# Jakelu — miksi tämä repo julkaisee valmiit käännökset

Tämä dokumentti perustelee, miksi repossa on binäärejä (`build/`) eikä pelkkiä
skriptejä, ja mitä kanavia pitkin ne on tarkoitus jakaa. Perustelu on
yksinkertainen: **suomen hunspell-sanastoa ei ole missään paketinhallinnassa.**
Jos sitä ei rakenna itse, sitä ei saa.

Kaikki tämän dokumentin kyselyt on ajettu **2026-09-16**.

---

## 1. Aukko ekosysteemissä

### AUR:ssa ei ole suomen hunspell-sanastoa

```
$ curl -s 'https://aur.archlinux.org/rpc/v5/search/hunspell-fi'
{"resultcount":0,"results":[],"type":"search","version":5}

$ curl -s 'https://aur.archlinux.org/rpc/v5/search/hyphen-fi'
0 pakettia
```

Suomeen liittyviä kieliapupaketteja AUR:ssa on kolme, ja kaikki ovat Voikkoa:

| Paketti | Versio | Ääniä | Popularity | Ylläpitäjä | Viimeksi muokattu |
|---|---|---|---|---|---|
| `voikko-fi` | 2.5-1 | 25 | 0,000016 | Huulivoide | 2023-01-25 |
| `voikko-libreoffice` | 5.0-1 | 25 | 0,000016 | Huulivoide | **2015-12-18** |
| `lib32-libvoikko` | — | — | — | — | — |

Luvut ovat AUR:n RPC-rajapinnasta (`/rpc/v5/info`). Popularity 0,000016 on
käytännössä nolla: paketteja ei asenneta juuri kukaan. `voikko-libreoffice`:n
PKGBUILDia ei ole koskettu vuoden 2015 jälkeen, mikä on repon kannalta
olennaista — se on ainoa reitti LibreOfficen kielentarkistukseen Archissa, ja
se toimii yhä (ks. [../README.md](../README.md) kohta 1), mutta yhden
ylläpitäjän varassa ja yksitoista vuotta koskematta.

Puuttuvat kokonaan: suomen hunspell-sanasto, suomen tavutuskuviot, Chromiumin
`.bdic`, Neovimin `.spl`.

### Debianissa ei ole `hunspell-fi`-pakettia

```
packages.debian.org/search?keywords=hunspell-fi&searchon=names&suite=all&section=all
→ "Sorry, your search gave no results"
```

Ei missään suitessa. Debianissa on `myspell-fi` (sama vanha 0.7, ks.
[sanastot.md](sanastot.md)), `voikko-fi`, `libreoffice-voikko` ja `hyphen-fi`
— mutta ei hunspell-muotoista suomen sanastoa lainkaan.

### AMO:ssa on tasan yksi suomen sanasto

addons.mozilla.orgin hakurajapinta (`type=dictionary`) palauttaa suomelle yhden
tuloksen:

| | |
|---|---|
| Slug | `finnish-spellchecker-dict` |
| Nimi | Finnish Spellchecker |
| Tekijä | fluks |
| Versio | 1.1.2resigned1 |
| Julkaistu | 2024-04-25 |
| Päivittäisiä käyttäjiä | **376** |
| Lisenssi | GPL-2.0-only |
| Kotisivu | <https://github.com/fluks/fi-FI-mozilla-spellchecker> |
| Kuvaus | *"Finnish spellchecker dictionary for Firefox, Thunderbird and SeaMonkey."* |

Laajennuksen oma kuvaus myöntää rajoituksen: *"conjugations and compounds are
not well supported in this spell checker."*

**Mikä sanasto se on.** Ketju on dokumentoitu, ei arvattu:

1. AMO-sivun kotisivulinkki osoittaa repoon `fluks/fi-FI-mozilla-spellchecker`.
2. Sen `copyright`-tiedosto sanoo sanatarkasti: *"The dictionary and affix
   files are from myspell-fi 0.7-18 Debian package."*
3. Sama tiedosto on tässä repossa polussa `dict/myspell-fi-0.7/copyright` —
   repon myspell-sanasto on haettu juuri tuosta samasta fluksin repositoriosta
   (ks. [lahteet.md](lahteet.md)).
4. Repossa on myös `raw/fluks-install.rdf`, fluksin XUL-aikainen
   asennusmanifesti. Sen `em:id` on `fi-FI@dictionaries.addons.mozilla.org`,
   `em:creator` on `fluks`, `em:homepageURL` on sama GitHub-osoite, ja
   kohdesovelluksiksi on listattu Firefox, Thunderbird ja SeaMonkey — täsmälleen
   AMO-kuvauksen kolmikko.

Ketju on siis vahva. **Yksi asia jää silti todentamatta:** `raw/fluks-install.rdf`
ilmoittaa versioksi `1.1`, kun AMO:n nykyinen julkaisu on `1.1.2resigned1`.
Sitä `.xpi`:tä ei ole ladattu eikä sen sanastotiedostoja ole verrattu
tavu tavulta `dict/myspell-fi-0.7/`:hen. Päättely on siis: **AMO:n ainoa suomen
sanasto on erittäin todennäköisesti myspell-fi 0.7 -sukua**, eli repon
mittauksissa **47,3 %** — kun tämän repon Ginter-pohjainen `.xpi` on **88,0 %**.
Ero on 20 prosenttiyksikköä, ja se selittää laajennuksen oman varauksen
taivutuksista ja yhdyssanoista.

### Ginterin upstream ei ole missään paketinhallinnassa

<https://github.com/fginter/hunspell-fi>, release 0.2, julkaistu 2023-12-06.
Ei AMO:ssa, ei AUR:ssa, ei Debianissa, ei Flathubissa. Ainoa jakelukanava on
GitHubin release-liite, eikä siitä ole julkaistu uutta versiota.

Tekijän oma kuvaus laajennuksen `manifest.json`:issa on `"Very quick effort"`.
Se ei ole vaatimattomuutta vaan tarkka kuvaus: aineisto on koneellisesti
generoitu eikä kuratoitu. Silti se on **paras saatavilla oleva suomen
hunspell-sanasto**, ja 20 prosenttiyksikköä parempi kuin ainoa jaossa oleva
vaihtoehto.

### Yhteenveto aukosta

| Mitä | Missä sen pitäisi olla | Onko |
|---|---|---|
| Suomen hunspell-sanasto | AUR, Debian | ei kummassakaan |
| Suomen tavutuskuviot | AUR | ei (Debianissa `hyphen-fi`) |
| Chromiumin `fi`-`.bdic` | Google, distro | ei kummassakaan |
| Neovimin `fi.utf-8.spl` | AUR, vim.org | ei |
| Nykyaikainen suomen sanasto AMO:ssa | AMO | ei — vain 2008-sukuinen |
| LibreOfficen suomen `.oxt` | LibreOffice-laajennukset | ei |
| Voikko (työpöytä) | AUR, Debian | **kyllä**, ja toimii |

Voikko-puoli on kunnossa. Kaikki muu puuttuu. Tämä repo täyttää sen aukon, ja
siksi se **julkaisee valmiit käännökset** eikä pelkkiä skriptejä: käännösten
toistaminen vaatii 153 MB kolmannen osapuolen binäärejä (`convert_dict`),
Neovimin, ja tietoa jota ei ole koottuna missään.

## 2. Jakelukanavat

Suunniteltu järjestys, helpoimmasta vaativimpaan:

### 1. GitHub Release

Ensisijainen kanava. Kaikki `build/`-tiedostot yhtenä julkaisuna, mukana
`SHA256SUMS` ja `LICENSES.md`. Ei vaadi keneltäkään mitään hyväksyntää, ja
tarkistussummat tekevät sisällöstä todennettavaa.

### 2. AUR-paketit

**Kolme julkaistavaa pakettia**, jotka asentavat sanastot järjestelmätasolle
ja tekevät niistä `pacman -Qo`:lle näkyviä — eli poistavat kohdan 1 aukon
Archista:

- `hyphen-fi` → `/usr/share/hyphen/hyph_fi_FI.dic`
- `chromium-dict-fi` → Chromiumin `.bdic`
- `nvim-spell-fi` → Neovimin `.spl`

Paketointi on hakemistossa `packaging/aur/`, ks. `packaging/README.md`.

**Neljättä pakettia, `hunspell-fi-ginter`, ei julkaista.** Se asentaisi
sanaston polkuun `/usr/share/hunspell/fi_FI.{aff,dic}`, ja se on repon ainoa
komponentti, jolla on globaali, ei-konfiguroitava haittavaikutus — ks.
varoitus alla. Sen PKGBUILD on tallessa hakemistossa
`packaging/ei-julkaista-hunspell-fi-ginter/` varoituksena, ei
lähetettäväksi.

Paketit ovat valmiit mutta **eivät vielä AUR:ssa**. Niiden `source`-rivit
osoittavat tagiin `v$pkgver` eli `v0.9`, joka on nyt olemassa, joten `makepkg`
pystyy noutamaan lähteet — jäljellä on chroot-rakennus, `namcap` ja itse
lähetys. Lähetysjärjestys ja esivaatimukset ovat
[../packaging/README.md](../packaging/README.md):ssä.

Lähetysjärjestys ei ole mielivaltainen: `hyphen-fi` ensin, koska se täyttää
aukon muuttamatta minkään sovelluksen oikolukua.

**Miksi `hunspell-fi-ginter` jää pois:** heti kun se
on asennettu, suomella on kaksi tarjoajaa sekä enchantissa että Sonnetissa, ja
järjestys on pakotettava käsin tai työpöytäsovellusten oikoluku putoaa Voikon
95,0 %:sta hunspellin 88,0 %:iin — enchantissa rivillä `fi:voikko`, Sonnetissa
arvolla `defaultClient=Voikko` (isolla V). Ks.
[sovellukset.md](sovellukset.md) kohdat 2 ja 3.

### 3. AMO-julkaisu

Ginterin `.xpi` AMO:hon suomen toiseksi sanastoksi — nykyaikaisena
vaihtoehtona vuoden 2008 sanastolle. Tämä on ainoa kanava, joka tavoittaa
käyttäjät jotka eivät koskaan avaa terminaalia, ja ainoa jossa 376 päivittäistä
käyttäjää voi löytää paremman vaihtoehdon.

Vaatii AMO-tilin ja tarkistusprosessin läpikäynnin. Sanastolaajennukset eivät
tarvitse allekirjoitusta asentuakseen — todennettu 2026-09-16 Firefox
155.0.1:llä, ks. [sovellukset.md](sovellukset.md) kohta 6 — mutta AMO:ssa
julkaisu käy silti tarkistuksen läpi. AMO ei siis ole edellytys sille, että
`.xpi` toimii; se on tapa tavoittaa käyttäjät, jotka eivät lataa tiedostoja
käsin.

**Tunnisteet eivät törmää — tarkistettu 2026-09-16.** Tämä oli julkaisun
ilmeisin este, koska sanastolaajennuksen tunniste on muotoa
`<kielikoodi>@dictionaries.addons.mozilla.org` eikä kahdella laajennuksella voi
AMO:ssa olla samaa tunnistetta. Ne ovat kuitenkin eri:

| | Tunniste | Lähde |
|---|---|---|
| fluksin AMO-sanasto | `fi-FI@dictionaries.addons.mozilla.org` | AMO API, `guid` |
| Ginterin `.xpi` (tämä repo) | `fi@dictionaries.addons.mozilla.org` | `unzip -p build/fi-spell-0.2.xpi manifest.json` |

Ginterin sanasto voidaan siis julkaista AMO:ssa toisena, rinnakkaisena suomen
sanastona. Käyttäjä voi asentaa molemmat ja valita kumpaa Firefox käyttää.

**Yksi korjaus on kuitenkin pakollinen ennen lähetystä.** Ginterin alkuperäinen
`manifest.json` käyttää vain vanhentunutta `applications`-avainta:

```json
{ "applications": { "gecko": { "id": "fi@dictionaries.addons.mozilla.org" } } }
```

MDN vaatii `dictionaries`-avainta käyttävältä laajennukselta tunnisteen
nykyisessä `browser_specific_settings`-avaimessa. Repon oma
[../tools/build-xpi.sh](../tools/build-xpi.sh) kirjoittaa molemmat ja
[../tools/tarkista-manifest.py](../tools/tarkista-manifest.py) tarkistaa sen —
**AMO:hon on siis vietävä repossa rakennettu `.xpi`, ei upstreamin
`build/fi-spell-0.2.xpi`:tä sellaisenaan.** Jälkimmäinen on repossa
muuttumattomana lähdeaineistona, ei julkaisukelpoisena pakettina.

### 4. `curl | bash` -asennin

`install.sh` repon juuressa. Noutaa GitHub Releasen, tarkistaa summat ja
asentaa halutut osat. Tarkoitettu tilanteeseen, jossa repoa ei haluta kloonata.

Summat ovat upotettuina skriptiin, koska etäasennin ei voi lukea repon
`SHA256SUMS`-tiedostoa — sama totuus on siis kahdessa paikassa. CI:n työ
`summat` vertaa ne toisiinsa ja kaatuu erosta. Ilman sitä unohtunut päivitys
näyttäytyisi käyttäjälle sanomana *"SHA-256 EI TÄSMÄÄ"*, eli hyökkäyksenä.

Omistaja (`REPO_OMISTAJA`) ja tagi (`JULKAISU_TAGI`) ovat skriptin alussa, ja
kaikki lataus-URL:t johdetaan niistä. Huomaa, että `.oxt`:n liitetiedostonimi
sisältää versionumeron: uusi tagi edellyttää siis myös uutta `.oxt`-pakettia,
uutta riviä `SHA256SUMS`-tiedostoon ja uutta upotettua summaa.

### 5. LibreOfficen `.oxt`

`build/fi-hunspell-<versio>.oxt` (`tools/build-oxt.sh`). Asentuu LibreOfficen
omaan laajennushakemistoon, myös Flatpak- ja Snap-hiekkalaatikon sisälle, joissa
Voikko ei toimi lainkaan. Ks. [sovellukset.md](sovellukset.md) kohta 8.

Kanavana `.oxt` on poikkeuksellisen halpa: ei allekirjoitusta, ei tiliä, ei
tarkistusprosessia, ei distrokohtaisuutta — pelkkä tiedosto, jonka käyttäjä
avaa kaksoisklikkauksella. Se on siksi ainoa kanava, joka tavoittaa Flatpak-,
Snap- ja ei-Arch-käyttäjät ilman että kenenkään tarvitsee hyväksyä mitään.

## 3. Lisenssit asettavat kanavakohtaiset ehdot

Repon aineistossa on kolme eri lisenssiä (ks. [../LICENSES.md](../LICENSES.md)),
eivätkä ne salli samoja asioita. Tämä ratkaisee, mitä mihinkin kanavaan saa
viedä.

| Aineisto | Lisenssi | Mitä se vaatii |
|---|---|---|
| `dict/ginter/`, `dict/ginter-karsittu/` ja niistä johdetut | **CC0-1.0** | ei mitään — saa levittää vapaasti, myös binäärinä ilman lähdettä |
| `dict/myspell-fi-0.7/` ja `build/fi-FI-myspell-0.7.bdic` | **GPL-2.0-only** | lähde on toimitettava vastaanottajan saataville |
| `dict/hyphen/hyph_fi_FI.dic` | **ei muodollista lisenssiä** — *"Patterns may be freely distributed"* | levitys vain muuttumattomana ja alkuperäisen README:n kanssa |

Kanavakohtaisesti:

**GitHub Release.** Kaikki kolme käyvät. GPL-2:n lähdevaatimus täyttyy, koska
`dict/myspell-fi-0.7/` on repossa samalla commitilla kuin julkaisu, ja
`LICENSES.md` osoittaa sinne. Tavutuskuviot levitetään muuttumattomana
alkuperäisen `README_hyph_fi_FI.txt`:n kanssa.

**AUR.** Käyvät kaikki, koska AUR jakaa PKGBUILDin joka noutaa lähteen —
GPL-2:n lähdevaatimus täyttyy rakenteellisesti. Jokaisen PKGBUILDin
`license=()`-kentän on silti oltava oikea: `CC0-1.0` Ginter-pohjaisille ja
`LicenseRef-fihyph` tavutuskuvioille. Jälkimmäinen ei ole `custom`: Archin
RFC 0016 edellyttää SPDX-tunnistetta, ja tunnistamattomaan ehtoon kuuluu
`LicenseRef-`-etuliite yhdessä sen kanssa, että lisenssiteksti toimitetaan
polkuun `/usr/share/licenses/$pkgname/`. Molemmat tehdään
`packaging/aur/hyphen-fi/PKGBUILD`:issä.

**AMO. Tähän kanavaan saa viedä vain CC0-aineistoa.** Ginterin `.xpi` on
kokonaan CC0, ja se on ainoa asia mitä AMO:hon viedään. Sekoitettua pakettia —
Ginter + myspell-fi 0.7 samassa `.xpi`:ssä — **ei saa viedä**, koska AMO
jakaa vain binääripaketin eikä siinä ole mitään mekanismia GPL-2:n
lähdevaatimuksen täyttämiseen. Tämä on ehdoton, ei suositus.

Sama koskee `dict/ginter-karsittu/`-sanastoa. Se on johdettu Ginteristä
**karsimalla**, ja ratkaisevaa on, millä kriteerillä. 0.9:ään asti kriteeri
antoi etusijan niille Ginterin sanoille, jotka ovat myspell-fi 0.7:n
listalla — eli karsinnan laatu tuli GPL-2.0-only-aineiston kuratoidusta
valinnasta. Perustelu "tulos sisältää vain Ginterin sanoja" ei riittänyt:
sama valinta ei voi olla yhtä aikaa se, mikä tekee sanastosta hyvän, ja se,
mikä ei periydy lisenssiin.

Nykyinen kriteeri on frekvenssi vapaasta korpuksesta (`tools/build-bdic.sh
frekvenssi`), varareittinä pelkkä sananpituus. Kumpikaan ei lue myspell-fi
0.7:ää, joten `CC0-1.0` periytyy suoraan Ginteristä. Ks. `LICENSES.md`.

**Huomaa silti, että Ginterin CC0:n tulkinta on avoin kysymys.** Lisenssi
itse on merkitty — upstreamin README sanoo `CC0` — mutta aineisto on
suodatettu Voikolla (GPL-2.0-or-later), eikä sitä ole kysytty tekijältä.
AMO-vienti odottaa vastausta. Jos joskus rakennetaan sanasto, joka
sisältää myspell-fi 0.7:n *rivejä*, se on GPL-2 eikä kuulu AMO:hon
missään tapauksessa.

**`curl | bash`.** Asennin noutaa GitHub Releasen, joten lisenssiehdot
täyttyvät siellä. Asentimen on kerrottava käyttäjälle mitä lisenssejä se
asentaa — `LICENSES.md` on osa julkaisua.

**`.oxt`.** Repon oma `.oxt` rakennetaan oletuksena Ginterin sanastosta, eli
se on CC0. `tools/build-oxt.sh` osaa rakentaa sen myös myspell-lähteestä,
jolloin tulos on GPL-2 eikä sitä saa jakaa ilman lähdettä.

## 4. Mitä on tehty ja mitä on vielä tekemättä

Kanavista on avattu ensimmäinen kolmesta. Tarkistettu 2026-09-18:

```
$ git remote -v
origin  https://github.com/mhavo/suomen-kieliavut.git

$ git tag -l
v0.9
```

**Tehty:**

- **GitHub-remote ja tagi `v0.9`** ovat olemassa.
- **GitHub Release `v0.9`** on julkaistu liitteineen: sanastot, `tools/`-osan
  skriptit, `LICENSES.md` ja `SHA256SUMS-release.txt`. `install.sh`:n noutama
  julkaisu on siis olemassa.
- **CI on ajettu GitHubissa ja on vihreä.** `tarkistus.yml` ajettiin sekä
  mainista että tagista `julkaisu.yml`:n kutsumana, ja julkaisu syntyi vasta
  sen jälkeen.
- **Asennin on testattu päästä päähän aitoa julkaisua vastaan.** Skenaario 02
  (`testi/skenaariot/02-install-julkaisu.sh`) noutaa `v0.9`:n verkosta ja menee
  läpi sekä Ubuntu- että Arch-kontissa.

**Tekemättä:**

- **AUR-paketteja ei ole lähetetty.** `packaging/aur/`-hakemiston PKGBUILDien
  `source`-rivit ovat nyt noudettavissa, koska tagi on olemassa, mutta paketteja
  ei ole `namcap`-tarkistettu puhtaassa chrootissa eikä lähetetty AUR:iin.
- **AMO-julkaisua ei ole tehty** eikä AMO-tiliä ole.

Järjestys, jossa loput on järkevä tehdä: AUR → AMO. Kummankin esivaatimus,
noudettava julkaisu, on nyt täytetty.
