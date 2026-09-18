# Suomen oikoluku Linuxiin — asennusohje

Näiden asennusten jälkeen suomen kielen oikoluku toimii LibreOfficessa,
Firefoxissa, Chromiumissa ja sähköpostissa. Ohje on laadittu sinulle, joka
haluat ymmärtää, miten asennus tehdään.

Tekniset perustelut ja mittaukset ovat [README.md](README.md):ssä.

**Testattu:** Ubuntu 24.04 ja Arch Linux, puhtaalta asennukselta. Muissa
Debian- ja Arch-pohjaisissa jakeluissa (Mint, Manjaro, Omarchy…) asennin
käyttää samoja komentoja, mutta niitä ei ole testattu erikseen.

---

## Miksi asennuksessa on monta osaa

Linuxissa ei ole yhtä oikolukua, jota kaikki ohjelmat käyttäisivät. Jokainen
ohjelmaperhe hakee sen omasta paikastaan.

Suomi tekee tästä hankalampaa kuin useimmilla kielillä. Sanoja taivutetaan ja
yhdistetään niin vapaasti, ettei mikään sanalista kata niitä. Siksi on
olemassa **Voikko**, ohjelma joka purkaa sanan osiin ja päättelee, kelpaako
se. Selaimet ja editorit osaavat kuitenkin vain sanalistan, joten niille
asennetaan erikseen laajin saatavilla oleva lista.

Käytännössä jako on tämä:

| Ohjelmat | Mistä oikoluku tulee | Osaako Voikkoa |
|---|---|---|
| LibreOffice | oma liitännäinen | kyllä |
| GTK- ja KDE-sovellukset | työpöydän välikerros (enchant, Sonnet) | kyllä |
| Firefox, Thunderbird | selaimen sisäänrakennettu sanalista | ei |
| Chromium | sama, mutta oma tiedostomuoto | ei |
| Vim, Neovim | editorin oma sanastotiedosto | ei |

Siksi tässä ohjeessa on neljä vaihetta eikä yhtä, ja siksi selain tuntee
vähemmän sanoja kuin LibreOffice.

---

## Ennen kuin aloitat

**Avaa pääteikkuna.** Useimmissa työpöydissä se aukeaa painamalla
`Ctrl`+`Alt`+`T`, tai sovellusvalikosta sanalla *Pääte* tai *Terminal*.

**Sulje Firefox, Chromium ja sähköpostiohjelma.** Ne kirjoittavat asetuksensa
levylle sulkeutuessaan, joten auki olevaan ohjelmaan tehty muutos katoaisi.
Asennin ei kirjoita käynnissä olevan ohjelman asetuksiin vaan jättää sen osan
väliin ja kertoo siitä.

**Tarvitset koneesi salasanan.** Voikko asennetaan koko järjestelmään, ja
siihen kysytään sama salasana, jolla kirjaudut koneelle. Kun kirjoitat sen
päätteeseen, näytöllä ei näy mitään — ei edes tähtiä. Kirjoita ja paina
enteriä.

Mitä asennin tekee kysymättä ja mitä ei:

- **Järjestelmään** (Voikko-paketit) ei asenneta mitään ilman lupaasi.
- **Kotihakemistoosi** asennin kirjoittaa kysymättä: selainten, sähköpostin ja
  Neovimin sanastot sekä oikolukukielen. Ohjelman asetustiedostosta otetaan
  varmuuskopio ennen muutosta. Kohta [Miten poistan tämän](#miten-poistan-tämän)
  luettelee tiedostot.

---

## Vaihe 1 — asenna

Kopioi tämä rivi päätteeseen ja paina enteriä:

```bash
curl -fsSL https://github.com/mhavo/suomen-kieliavut/raw/v0.9/install.sh | bash
```

Jos vastaus on `curl: command not found` — Ubuntussa `curl` ei ole valmiina —
käytä tätä. Se tekee saman:

```bash
wget -qO- https://github.com/mhavo/suomen-kieliavut/raw/v0.9/install.sh | bash
```

### Mitä näytöllä tapahtuu

Asennin tulostaa ensin, minkä jakelun se tunnisti, ja pysähtyy sitten kysymään
lupaa. Ubuntussa ja Debianissa kysymys näyttää tältä:

```
==> Voikko — morfologinen oikoluku työpöytäsovelluksiin
    Voikko puuttuu. Asennus vaatii paketinhallinnan ja sudon:
      sudo apt install voikko-fi libreoffice-voikko libenchant-2-voikko python3-libvoikko libvoikko-dev
    Ajetaanko tämä nyt? [k/e]
```

**Kirjoita `k` ja paina enteriä.** Tässä kohdassa kysytään salasanaasi. Jos
vastaat jotain muuta, selainten sanastot asentuvat silti, mutta Voikko jää
pois eikä LibreOfficen oikoluku ala toimia.

**Archissa** komento on `yay -S --needed voikko-fi voikko-libreoffice`.
Paketit tulevat AUR:sta, joten `yay` kääntää ne koneellasi ja esittää omat
kysymyksensä; oletusvastaukset käyvät. Käännös voi kestää useita minuutteja.
Jos koneella ei ole `yay`- eikä `paru`-ohjelmaa, asennin kertoo sen, asentaa
muut osat ja neuvoo, miten Voikko-osa ajetaan myöhemmin.

Lopuksi asennin tulostaa yhteenvedon: mitä asennettiin ja mitä *jäi sinun
tehtäväksesi*. Jälkimmäisen listan kohdat vastaavat tämän ohjeen vaiheita 3
ja 4.

### Jos komento ei toiminut

| Näytöllä lukee | Mitä se tarkoittaa | Mitä teet |
|---|---|---|
| `404` tai `Not Found` | Julkaisua ei löytynyt | Ks. huomautus tämän ohjeen alussa |
| `SHA-256 EI TÄSMÄÄ` | Ladattu tiedosto ei ollut se, jota odotettiin | **Älä jatka.** Asennin keskeytti eikä ottanut tiedostoa käyttöön. Kokeile myöhemmin uudelleen |
| `pakettien asennus epäonnistui` | Voikko-pakettien asennus keskeytyi (väärä salasana, verkko) | Muut osat asentuivat. Aja vaiheen 1 komento uudelleen |

---

## Vaihe 2 — tarkista LibreOffice

1. Jos LibreOffice oli auki asennuksen aikana, sulje se ja avaa uudelleen.
2. Avaa **LibreOffice Writer** ja kirjoita tyhjään asiakirjaan:

   ```
   tarkkailukehä maastopyöräz
   ```

**Näin sen pitää näyttää:** `maastopyöräz` saa alleen punaisen aaltoviivan,
`tarkkailukehä` ei. Jälkimmäistä sanaa ei ole yhdessäkään sanalistassa, joten
jos se kelpaa, tarkistuksen tekee Voikko.

### Jos molempien alla on viiva tai punaista viivaa ei näy kummankaan sanan alla

Tarkista ensin asiakirjan kieli. LibreOffice tarkistaa tekstin sillä kielellä,
joksi teksti on merkitty, ja kieli lukee ikkunan alareunan tilarivillä. Jos
siinä on esimerkiksi *English (USA)*, valitse teksti (`Ctrl`+`A` valitsee
kaiken), napsauta tilarivin kielitekstiä ja valitse **suomi**.

Jos kieli on suomi eikä viivaa silti tule, katso kohta
[Jos jokin ei toimi](#jos-jokin-ei-toimi).

---

## Vaihe 3 — Firefox ja sähköposti

### Firefox

Jos Firefox oli kiinni vaiheessa 1, tämä on jo tehty: yhteenvedossa on rivi
*Firefox: sanasto … ja oikolukukieli fi-FI*. Asennin kopioi sanaston
hakemistoon `~/.local/share/suomen-kieliavut/hunspell/` ja merkitsi sen
Firefoxin oletusprofiilin asetuksiin. Lisäosaa ei tarvita.

**Kokeile:** avaa Firefox ja kirjoita mihin tahansa tekstikenttään
`maastopyörä maastopyöräz`. Vain jälkimmäinen saa punaisen viivan. Jos viivaa
ei tule kummallekaan, napsauta tekstikenttää oikealla painikkeella ja varmista,
että **Tarkista oikeinkirjoitus** on rastitettu ja kohdassa **Kielet** on
valittuna suomi.

**Jos Firefox oli auki**, asetukset jäivät kirjoittamatta. Sulje Firefox ja
aja:

```bash
curl -fsSL https://github.com/mhavo/suomen-kieliavut/raw/v0.9/install.sh | bash -s -- --vain firefox
```

Jos käytät useaa Firefox-profiilia, lisää komennon loppuun
`--kaikki-profiilit`.

### Thunderbird ja Betterbird

Sähköposti hoituu samalla tavalla ja samalla komennolla kuin Firefox:
Thunderbird ja sen johdannainen Betterbird käyttävät samaa sanastohakemistoa.
Jos ohjelma oli kiinni vaiheessa 1, yhteenvedossa on rivi
*Thunderbird/Betterbird: sanasto … ja oikolukukieli fi-FI*. Jos se oli auki,
sulje se ja aja yllä oleva `--vain firefox` -komento.

**Kokeile:** kirjoita uuteen viestiin `maastopyörä maastopyöräz`. Vain
jälkimmäinen saa punaisen viivan.

Testattu Betterbirdillä. Thunderbirdiä ei ole testattu erikseen; sen oikoluku
on samaa koodia.

### Snap- ja Flatpak-Firefox (Ubuntu)

**Ubuntussa Firefox on oletuksena Snap-versio.** Snap- ja Flatpak-ohjelmat
ajetaan eristettyinä, eivätkä ne näe yllä mainittua sanastohakemistoa. Asennin
tunnistaa ne ja tekee saman asian eristetyn ohjelman omaan hakemistoon, jonka
se näkee:

| Versio | Sanasto |
| --- | --- |
| Snap | `~/snap/firefox/common/suomen-kieliavut/hunspell/` |
| Flatpak | `~/.var/app/org.mozilla.firefox/suomen-kieliavut/hunspell/` |

Yhteenvedossa rivi on silloin *Firefox (Snap): sanasto … ja oikolukukieli
fi-FI*. Sama koskee Snap- ja Flatpak-Thunderbirdiä. Kokeile kuten yllä.

> **Tätä reittiä ei ole testattu oikealla Snap- tai Flatpak-asennuksella.**
> Jos oikoluku ei toimi, vaikka yhteenveto sanoo asennuksen onnistuneen,
> asenna sanasto lisäosana alla olevan ohjeen mukaan — ja kerro siitä
> [GitHubissa](https://github.com/mhavo/suomen-kieliavut/issues).

### Jos yhteenvedossa luki "Firefox: profiilia ei löytynyt"

Firefox saa profiilin vasta ensimmäisellä käynnistyksellä. Jos se on vasta
asennettu, käynnistä se kerran, sulje ja aja yllä oleva `--vain firefox`
-komento.

Jos se ei auta, sanaston voi asentaa lisäosana käsin. Asennin kopioi tiedoston
valmiiksi **Lataukset**-kansioosi nimellä `fi-spell-0.2.xpi`. (Jos
Lataukset-kansiota ei ole, tiedosto on polussa
`~/.cache/suomen-kieliavut/fi-spell-0.2.xpi`. Snap-Firefox ei saa lukea
kotihakemiston piilohakemistoja, joten kopioi se silloin ensin näkyvään
paikkaan: `cp ~/.cache/suomen-kieliavut/fi-spell-0.2.xpi ~/`.)

1. Kirjoita Firefoxin osoiteriville `about:addons` ja paina enteriä.
2. Napsauta sivun yläreunan **rataskuvaketta** ja valitse **Asenna lisäosa
   tiedostosta**.
3. Valitse Lataukset-kansiosta `fi-spell-0.2.xpi`.
4. Hyväksy asennus.
5. **Valitse kieli — pelkkä lisäosan asennus ei riitä.** Napsauta mitä tahansa
   tekstikenttää oikealla painikkeella, varmista että **Tarkista
   oikeinkirjoitus** on rastitettu, ja valitse **Kielet** → **suomi**.

Lisäosareitti on testattu tavallisella Firefoxilla. Snap- ja Flatpak-Firefoxia
ei ole testattu.

Sama `.xpi` käy Thunderbirdiin: **☰** → *Lisäosat ja teemat* → rataskuvake →
*Asenna lisäosa tiedostosta*. Kieli valitaan viestin kirjoitusikkunan
oikolukuvalikosta. Tätäkään ei ole testattu.

---

## Vaihe 4 — Chromium

Ohita tämä, jos et käytä Chromiumia. Google Chromea ja Ubuntun Snap-Chromiumia
asennin ei tue: ne pitävät asetuksensa eri hakemistossa.

Jos Chromium oli kiinni vaiheessa 1, tämä on jo tehty: yhteenvedossa on rivi
*Chromium: oikolukukieli fi*.

**Jos Chromium oli auki**, sanasto on paikallaan mutta oikolukukieli
asettamatta. Sulje Chromium kokonaan — kaikki ikkunat — ja aja:

```bash
curl -fsSL https://github.com/mhavo/suomen-kieliavut/raw/v0.9/install.sh | bash -s -- --vain chromium
```

Komento tulostaa, mitä se muutti. Jos käytät useaa selainprofiilia, lisää
loppuun `--kaikki-profiilit`.

**Kokeile:** avaa Chromium ja kirjoita tekstikenttään
`maastopyörä maastopyöräz`. Vain jälkimmäinen saa punaisen viivan.

Asennuksen jälkeen suomi näkyy Chromiumin kieliasetuksissa (*Asetukset* →
*Kielet*). Sieltä sitä ei olisi voinut itse valita: Chromium ei tarjoa
suomea oikolukukieleksi, joten asennin kirjoitti valinnan suoraan
asetustiedostoon.

---

## Muut ohjelmat

**KDE-sovellukset** (Kate, KWrite, KMail) ja **GTK-sovellukset** (gedit, Geany)
käyttävät Voikkoa työpöydän välikerroksen kautta. Vaihe 1 riitti.

**Emacs** saa Voikon [jinx](https://github.com/minad/jinx)-paketilla, joka
käyttää samaa välikerrosta kuin GTK-sovellukset.

**Neovim** sai sanastonsa vaiheessa 1. Ota se käyttöön:

```vim
:set spelllang=fi spell
```

**Vim** lukee saman tiedoston eri hakemistosta:

```bash
mkdir -p ~/.vim/spell
cp ~/.config/nvim/spell/fi.utf-8.spl ~/.vim/spell/
```

Editorit käyttävät samaa sanalistaa kuin Firefox, eivät Voikkoa, joten ne
tuntevat vähemmän sanoja kuin LibreOffice. Luvut: [README.md](README.md),
kohta *Miksi tarvitaan kaksi eri järjestelmää*.

---

## Jos jokin ei toimi

| Oire | Todennäköinen syy | Mitä teet |
|---|---|---|
| LibreOfficessa ei punaista viivaa minkään sanan alla | Asiakirjan kieli ei ole suomi | Vaihda kieli tilariviltä — ks. vaihe 2 |
| LibreOffice alleviivaa kaiken, myös oikeat sanat | Kieli on suomi, mutta Voikko ei ole asennettu | Aja vaihe 1 uudelleen ja vastaa kysymykseen `k` |
| Korjausehdotukset ovat englanniksi | Tarkistus käyttää englannin sanastoa | Vaihda asiakirjan tai tekstikentän kieleksi suomi |
| Firefoxissa tai sähköpostissa ei viivaa minkään sanan alla | Ohjelma oli auki asennuksen aikana, tai kieltä ei ole valittu | Ks. vaihe 3 |
| Chromiumissa ei viivaa minkään sanan alla | Chromium oli auki asennuksen aikana | Sulje selain ja aja vaiheen 4 komento |
| `tarkkailukehä` saa punaisen viivan LibreOfficessa | LibreOffice käyttää sanalistaa Voikon sijaan | README.md, kohta *Milloin oikoluku voi vaihtua huonompaan* |
| LibreOffice on asennettu Flatpakista tai Snapista | Se ei näe järjestelmän Voikkoa | README.md, kohta *Flatpak ja Snap* |

Voikon voi tarkistaa myös suoraan päätteestä:

```bash
echo "maastopyöräily" | voikkospell
```

Vastaus `C: maastopyöräily` tarkoittaa, että sana kelpaa (`W` = ei kelpaa).
Jos komentoa ei löydy, Voikko jäi asentamatta.

---

## Miten poistan tämän

Poistoskriptiä ei ole. Alla ovat ne kohteet, jotka tämän ohjeen vaiheet
luovat; harvinaisemmat (tavutus, `.oxt`, enchant) ovat
[README.md](README.md):n kohdassa *Poistaminen*.

**Voikko**, Ubuntu ja Debian:

```bash
sudo apt remove voikko-fi libreoffice-voikko libenchant-2-voikko python3-libvoikko libvoikko-dev
```

**Voikko**, Arch:

```bash
sudo pacman -R voikko-fi voikko-libreoffice
```

**Sanastot ja ladatut tiedostot:**

```bash
rm -f  ~/.config/chromium/Dictionaries/fi-3-0.bdic
rm -f  ~/.config/nvim/spell/fi.utf-8.spl
rm -rf ~/.local/share/suomen-kieliavut
rm -rf ~/.cache/suomen-kieliavut
# Snap- ja Flatpak-versiot, jos niitä oli:
rm -rf ~/snap/*/common/suomen-kieliavut ~/.var/app/*/suomen-kieliavut
```

Jos asennin kopioi `fi-spell-0.2.xpi`:n Lataukset-kansioosi, poista se sieltä.

**Firefoxin asetukset.** Kirjoita osoiteriville `about:config`, hae
`spellchecker.dictionary_path` ja poista tai nollaa se rivin oikean reunan
painikkeesta. Tee sama asetukselle `spellchecker.dictionary`. Jos asensit
lisäosan, poista se `about:addons`-sivulta. Thunderbirdissä ja Betterbirdissä
samat asetukset ovat kohdassa **☰** → *Settings* → *General* → *Config
Editor* (sivun lopussa). Betterbirdistä ei ole suomenkielistä versiota;
suomenkielisessä Thunderbirdissä polku on *Asetukset* → *Yleiset* →
*Asetusten muokkain*.

**Chromiumin asetukset.** Poista suomi kieliasetuksista: *Asetukset* →
*Kielet*. Älä muokkaa `Preferences`-tiedostoa käsin: rikkinäinen tiedosto saa
Chromiumin nollaamaan koko profiilin.

**Varmuuskopiot.** Asennin jätti selainten asetustiedostoista kopiot, jotka
voi poistaa:

```bash
ls ~/.config/chromium/*/Preferences.bak-*
ls ~/.mozilla/firefox/*/prefs.js.bak-* ~/.config/mozilla/firefox/*/prefs.js.bak-*
ls ~/.thunderbird/*/prefs.js.bak-* ~/.config/thunderbird/*/prefs.js.bak-*
```
