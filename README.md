# Suomen kieliavut Linuxiin

> ### Haluatko vain että oikoluku toimii?
>
> **→ [ASENNUS.md](ASENNUS.md) — asennusohje alusta loppuun.**
>
> Tämä tiedosto on hakuteos: se kertoo *miksi* asiat toimivat niin kuin
> toimivat ja mitä on mitattu. Asennukseen sitä ei tarvita.

Suomen **oikoluku, tavutus ja kielentarkistus** Linux-työpöydälle:
LibreOfficeen, selaimiin, sähköpostiin, GTK- ja KDE-sovellusten
tekstikenttiin sekä Vimiin ja Neovimiin. Tämä repo sisältää sekä ohjeet että
valmiiksi käännetyt sanastotiedostot.

Suomen hunspell-sanasto on olemassa yhtenä GitHub-releasena eikä missään
paketinhallinnassa — ei AUR:ssa, ei Debianissa, ei AMO:ssa, ei Flathubissa.
Tämä repo paketoi sen kuuteen sovellusmuotoon, mittaa mitä se kattaa ja kertoo
miten käännökset toistetaan. Samalla se kokoaa yhteen tiedon, joka on hajallaan
Voikon dokumentaatiossa, Chromiumin `convert_dict`-työkalun ympärillä, kahdessa
GitHub-repossa ja Debianin pakettikuvauksissa — ja osin vanhentunutta.
Aukko on eritelty tarkemmin: **[docs/jakelu.md](docs/jakelu.md)**.

Ohjeet on kirjoitettu **Archille (Omarchy)** ja LibreOffice 26.8:lle.
Debian- ja Ubuntu-vastineet mainitaan siellä missä ne eroavat.

---

## Sanasto — mitä nämä sanat tarkoittavat

Alla olevat käsitteet toistuvat läpi ohjeen. Ne kannattaa lukea kerran.

| Termi | Mitä se on |
|---|---|
| **Oikoluku** | Onko sana kirjoitettu oikein. Alleviivaa väärät sanat punaisella. |
| **Tavutus** | Mihin kohtaan sana katkaistaan rivin lopussa. |
| **Kielentarkistus** | Kielioppi ja välimerkit — laajempi kuin yksittäisen sanan tarkistus. |
| **Voikko** | Suomalainen oikolukumoottori, joka *ymmärtää* suomen taivutuksen ja yhdyssanat. |
| **hunspell** | Kansainvälinen oikolukumoottori, joka vertaa sanoja valmiiseen sanalistaan. |
| **Sanasto** | Tiedostopari `.aff` + `.dic`, jonka hunspell lukee. |
| **enchant** | Välikerros, jonka kautta GTK-sovellukset (ja Emacs) löytävät oikolukumoottorin. |
| **Sonnet** | KDE:n oma vastine enchantille. Täysin erillinen järjestelmä. |

Sanastoista on kolme erilaista pakattua muotoa, koska jokainen sovellusperhe
lukee vain omaansa:

| Muoto | Kenelle |
|---|---|
| `.xpi` | Firefox ja Thunderbird (lisäosa) |
| `.bdic` | Chromium ja Electron-sovellukset |
| `.spl` | Vim ja Neovim |
| `.oxt` | LibreOffice-laajennus (tarvitaan Flatpak-versiossa) |

---

## Miksi tarvitaan kaksi eri järjestelmää

Suomi on kieli, jossa sanavartaloon liimataan taivutuspäätteitä ja yhdyssanoja
saa muodostaa vapaasti. Siksi valmiiseen sanalistaan perustuva oikoluku ei voi
koskaan kattaa suomea: `tarkkailukehä` tai `koronarokote` ei ole
missään listassa, vaikka molemmat ovat täysin kelvollisia sanoja.

Tähän on olemassa suomalainen ratkaisu, **Voikko**, joka purkaa sanan osiin ja
päättelee kelpaako se. Ongelma on se, että kaikki sovellukset eivät osaa
käyttää sitä — moni osaa vain hunspellia.

| | Voikko | hunspell |
|---|---|---|
| Menetelmä | purkaa sanan osiin (morfologinen analyysi) | vertaa valmiiseen sanalistaan |
| Tunnistaa yhdyssanat | kyllä | ei |
| Osaa kielentarkistuksen | kyllä | ei |
| LibreOffice | kyllä, liitännäisellä | kyllä, natiivisti |
| GTK-sovellukset (enchant) | kyllä | kyllä |
| KDE- ja Qt-sovellukset (Sonnet) | kyllä | kyllä |
| Emacs (jinx → enchant) | kyllä | kyllä |
| Firefox / Thunderbird / Chromium | **ei** | kyllä |
| Vim / Neovim | ei | kyllä (`:mkspell`) |

**Nyrkkisääntö:** käytä Voikkoa kaikkialla missä se on mahdollista. Käytä
hunspell-sanastoa vain selaimissa, sähköpostissa ja editoreissa, joissa
vaihtoehtoa ei ole. Selaimet tukevat ainoastaan hunspellia, eikä tähän ole
näköpiirissä muutosta.

Ero näkyy myös numeroina. 62 641 uniikin suomenkielisen sanan korpuksella
(`tools/arvioi-korpuksella.sh`; UD Finnish-TDT + fi-Wikipedia, molemmat
CC BY-SA 4.0) mitattu osuus tunnistetuista sanoista:

| Sanasto | Missä käytössä | Uniikit sanat | Esiintymät |
|---|---|---|---|
| Voikko | työpöytäsovellukset | **95,0 %** | **97,6 %** |
| Ginter kokonaan | Firefox, Thunderbird, Vim, Neovim | 88,0 % | 95,9 % |
| Ginter karsittu | Chromium, Electron | 76,4 % | 92,0 % |
| myspell-fi 0.7 | (vanha vaihtoehto) | 47,3 % | 80,1 % |

Kaksi saraketta, koska ne vastaavat eri kysymykseen. **Uniikit sanat** kertoo
miten laaja sanasto on; **esiintymät** painottaa sanoja sillä, miten usein ne
tekstissä esiintyvät, ja on siksi lähempänä sitä minkä käyttäjä kokee.
Kaikkien lukujen 95 %:n luottamusväli on alle ±0,5 prosenttiyksikköä.

Korpuksen katto ei ole 100 %: siinä on vierassanoja ja kirjoitusvirheitä,
joita mikään suomen sanasto ei voi tunnistaa. Luvut ovat siis vertailukelpoisia
keskenään mutta eivät absoluuttisia.

**Tämä on kattavuus, ei oikolukulaatu.** Korpuksessa on vain oikein
kirjoitettuja sanoja, joten taulukko kertoo vain, kuinka suuren osan oikeista
sanoista kukin sanasto tunnistaa. Se ei kerro, kuinka hyvin sanasto hylkää
*väärin* kirjoitetut sanat — kaiken hyväksyvä sanasto saisi tässä 100 %.
Hyväksymisvirheitä, korjausehdotusten osuvuutta eikä yhdyssanavirheitä ei ole
mitattu lainkaan. Menetelmä, rajoitukset ja
Voikko-vertailun kehäpäätelmä: **[docs/sanastot.md](docs/sanastot.md)**.

Sovelluskohtainen erittely — mikä mekanismi, mikä moottori, mitä on todennettu
ja mitä ei: **[docs/sovellukset.md](docs/sovellukset.md)**.

---

## Pikaopas — mitä asennan, jos haluan vain että se toimii

1. **Asenna Voikko.** Tämä riittää LibreOfficeen, GTK-sovelluksiin,
   KDE-sovelluksiin ja komentoriville. → [kohta 1](#1-voikko--perusta)

   Arch:

   ```bash
   yay -S voikko-fi voikko-libreoffice
   ```

   Debian/Ubuntu:

   ```bash
   apt install voikko-fi libreoffice-voikko libenchant-2-voikko \
               python3-libvoikko libvoikko-dev
   ```

2. **Asenna hunspell-sanasto niihin sovelluksiin, jotka eivät osaa Voikkoa:**
   selaimet, sähköposti ja editorit. → [kohta 2](#2-selaimet-sähköposti-ja-editorit--hunspell-reitti)

   ```bash
   tools/asenna.sh
   ```

3. **Jos käytät Flatpak- tai Snap-LibreOfficea**, se ei näe kumpaakaan yllä
   olevista. Sille on oma paketti. → [kohta 3](#3-flatpak-ja-snap--hiekkalaatikon-rajoitus)

Ilman repon kloonausta perusasennuksen saa yhdellä komennolla:

```bash
curl -fsSL https://github.com/mhavo/suomen-kieliavut/raw/v0.9/install.sh | bash
```

Se ei ole **koko** homma, eikä yritä olla. Komento asentaa kotihakemistoon
kirjoitettavat osat ilman sudoa; erikseen jäävät LibreOffice-sanastolaajennus
(`--vain oxt`) ja tavutus (`--vain hyphen`, vaatii sudon).

Chromiumin oikolukukielen asennin asettaa itse — se noutaa
`tools/chromium-ota-kayttoon.sh`:n ja `tools/pref-kirjoitus.py`:n julkaisusta
samalla SHA-256-varmennuksella kuin sanastot, koska putkessa ajettuna sillä ei
ole repon työkopiota. Se ei kuitenkaan kirjoita prefiä **selaimen ollessa
käynnissä**: Chromium kirjoittaa asetuksensa uudelleen sulkeutuessaan ja
pyyhkisi muutoksen. Siinä tapauksessa osa jää yhteenvedon *jäi sinun
tehtäväksesi* -listalle ohjeineen, ja sen voi ajaa myöhemmin yksinään
(`--vain chromium`, monta profiilia `--kaikki-profiilit`).

Firefoxille asennin tekee saman: se noutaa `tools/firefox-ota-kayttoon.sh`:n,
`tools/prefs-js-kirjoitus.py`:n ja Ginterin `.aff` + `.dic` -parin, kopioi
sanaston hakemistoon `~/.local/share/suomen-kieliavut/hunspell/` ja kirjoittaa
profiilin `prefs.js`:ään — lisäosaa ei tarvita (ks.
[Monta profiilia — sanasto ilman lisäosaa](#monta-profiilia--sanasto-ilman-lisäosaa)).
Sama ehto pätee: ohjelman on oltava suljettuna. Sama osa (`--vain firefox`)
hoitaa samalla tavalla myös Thunderbirdin ja Betterbirdin, jos niiden
profiilijuuri (`~/.config/thunderbird` tai `~/.thunderbird`) löytyy.

Snap- ja Flatpak-versiot (Ubuntun oletus-Firefox on Snap) eivät näe jaettua
sanastohakemistoa. Asennin tunnistaa niiden profiilijuuret
(`~/snap/firefox/common/.mozilla/firefox`,
`~/.var/app/org.mozilla.firefox/.mozilla/firefox`, vastaavat Thunderbirdille)
ja kopioi sanaston eristetyn ohjelman omaan hakemistoon
(`~/snap/firefox/common/suomen-kieliavut/hunspell/` tai
`~/.var/app/<tunnus>/suomen-kieliavut/hunspell/`), jonka ohjelma näkee samalla
polulla. **Tätä ei ole testattu oikealla Snap-/Flatpak-asennuksella.**
Varareitiksi `.xpi` noudetaan aina välimuistiin, ja jos Firefoxin profiilia ei
löydy mistään, se kopioidaan lisäksi Lataukset-kansioon (`xdg-user-dir
DOWNLOAD`) käsin asennettavaksi: Snap-ohjelma ei saa lukea kotihakemiston
piilohakemistoja kuten `~/.cache`.

Yksityiskohdat: [Asennus asentimella](#asennus-asentimella).

---

## 1. Voikko — perusta

Voikko hoitaa LibreOfficen, GTK-sovellukset, KDE-sovellukset ja komentorivin.

```bash
yay -S voikko-fi            # vetää mukanaan extra/libvoikko
yay -S voikko-libreoffice   # LibreOffice-liitännäinen
```

Debian ja Ubuntu:

```bash
apt install voikko-fi libreoffice-voikko libenchant-2-voikko python3-libvoikko \
            libvoikko-dev
```

`libvoikko-dev` on listalla komentorivityökalujen takia, ei kehityksen:
`voikkospell`, `voikkohyphenate` ja `voikkogc` ovat upstreamissa osa
libvoikkoa — [viralliset asennusohjeet][voikko-src] varmistavat käännöksen
komennolla `voikkospell -d fi` — ja Archissa ne tulevat paketissa `libvoikko`.
Vain Debian siirtää ne `-dev`-pakettiin headerien seuraksi. Ilman sitä alla
olevat tarkistuskomennot eivät ole olemassa.

[voikko-src]: https://voikko.puimula.org/source-linux.html

Kielitiedot asentuvat Archissa hakemistoon
`/usr/share/voikko/5/mor-standard/` (`mor.vfst`, `autocorr.vfst`,
`index.txt`). **Debianissa polku on eri:** `/usr/lib/voikko/5/mor-standard/`.
Lähdekoodista käännettäessä upstreamin oletus on kolmas:
`/usr/local/voikkodict` (säädettävissä `configure --with-dictionary-path`).
Jos siirrät aineistoa distrojen välillä, tämä on ensimmäinen kompastuskivi.

### Tarkista että se toimii

```bash
$ echo "maastopyöräily" | voikkospell
C: maastopyöräily      # C = kelpaa, W = ei kelpaa

$ echo "maastopyöräily" | voikkohyphenate
maas-to-pyö-räi-ly
```

Voikko ei etsi sanaa listasta vaan purkaa sen osiin. Siksi se hyväksyy myös
yhdyssanat, joita missään sanalistassa ei ole — `tarkkailukehä`,
`koronarokote` — ja juuri tätä hunspell ei osaa.

Samasta paketista tulee kolmas työkalu, **`voikkogc`**, joka tarkistaa
kieliopin. Se on ainoa tapa ajaa suomen kielentarkistusta komentoriviltä:

```
$ printf 'Kissa joka istui matolla oli musta.\n' | voikkogc explanation_language=fi
[code=18, level=0, descr="", stpos=11, len=17, suggs={}] (Virkkeestä saattaa puuttua pilkku, tai siinä voi olla ylimääräinen verbi.)
-
```

Tulosteessa `stpos` on virheen alkukohta, `len` sen pituus, `suggs`
korjausehdotukset ja viimeinen `-` kappaleen loppumerkki. Ilman
`explanation_language=fi` selitys jää pois.

Huomaa että `voikkogc` **ei** tarkista oikeinkirjoitusta, vain kielioppia —
oikeinkirjoitus on `voikkospell`in työtä. Lisää esimerkkejä:
[docs/sovellukset.md](docs/sovellukset.md) kohta 4.

### LibreOffice

`voikko-libreoffice` on Pythonilla kirjoitettu laajennus
(`org.puimula.ooovoikko`, versio 5.0). Se tuo LibreOfficeen kolme asiaa:
oikoluvun, tavutuksen ja **kielentarkistuksen** (Työkalut → Asetukset →
Kieliasetukset → Kirjoitusapuvälineet).

Arch-paketti ei ota laajennusta suoraan käyttöön. Se pudottaa oxt-paketin
polkuun `/usr/lib/libreoffice/share/extensions/install/voikko.oxt` ja
rekisteröi sen asennusskriptillä kaikille käyttäjille yhteisenä laajennuksena.
Tarkista että rekisteröinti onnistui:

```bash
$ unopkg list --shared
Identifier: org.puimula.ooovoikko
  Version: 5.0
  is registered: yes
```

AUR-paketti on vuodelta 2015, mutta se rekisteröityy puhtaasti LibreOffice
26.8:aan (todettu 2026-09-09). Syy toimivuuteen on se, ettei paketin
`description.xml`-tiedostossa ole versiorajoja ja koodi on puhdasta Pythonia.
Jos se joskus hajoaa, varapolku on hunspell-sanasto ([kohta
2](#2-selaimet-sähköposti-ja-editorit--hunspell-reitti)) ilman
kielentarkistusta.

Debianin oma versio samasta laajennuksesta on säilytetty tässä repossa
hakemistoon `raw/libreoffice-voikko-5.0-debian/`. Sen voi asentaa suoraan, jos
AUR-paketti joskus katoaa:

```bash
unopkg add --shared raw/libreoffice-voikko-5.0-debian
```

### Tavutus

Voikko tavuttaa LibreOfficessa itse, joten mitään erillistä ei tarvita.

Jos käytät hunspell-reittiä, tavutus tarvitsee oman tiedostonsa:

```bash
sudo install -Dm644 dict/hyphen/hyph_fi_FI.dic /usr/share/hyphen/hyph_fi_FI.dic
```

Arch ei paketoi suomen tavutuskuvioita lainkaan (`hyphen`-paketissa on vain
kirjasto), joten käsin asennettu tiedosto ei kuulu millekään paketille. Se on
tarkoituksellista. Debianissa sama tiedosto tulee paketista `hyphen-fi`.

### GTK-sovellukset ja Emacs (enchant)

Archin `enchant`-paketissa on valmiina `/usr/lib/enchant-2/enchant_voikko.so`.
Siksi Voikko näkyy automaattisesti kaikissa enchantia käyttävissä
sovelluksissa heti kun `voikko-fi` on asennettu — mitään konfiguraatiota ei
tarvita.

Enchantia käyttävät esimerkiksi `gspell` (gedit, Geany), `webkit2gtk-4.1`
(GNOME Web) ja `fcitx5`. Kuka tahansa voi tarkistaa oman koneensa tilanteen
komennolla `pacman -Qi enchant`. Lisäksi enchantia kutsuu suoraan Emacsin
[jinx](https://github.com/minad/jinx), joka on ainoa tapa saada Emacsiin
Voikon tasoinen suomen oikoluku.

```bash
$ enchant-lsmod-2 -list-dicts
fi (voikko)

$ printf 'tarkkailukehä\nzzzqqq\n' | enchant-2 -d fi -l
zzzqqq
```

Jälkimmäinen komento tulostaa vain ne sanat, joita se ei hyväksy. Se on
varsinainen todiste: `tarkkailukehä` — sana jota ei ole missään sanalistassa —
kelpaa, `zzzqqq` ei.

`enchant-lsmod-2` varoittaa puuttuvista `libaspell.so.15`-, `libhspell.so.0`-
ja `libnuspell.so.5`-kirjastoista. Varoitus on harmiton: Arch paketoi kaikkien
taustaosien liitännäiset mutta ei niiden kirjastoja, ja enchant yrittää ladata
jokaisen. Voikkoon tämä ei vaikuta.

### KDE- ja Qt-sovellukset (Sonnet)

**Nämä eivät kulje enchantin kautta.** KDE-sovellukset käyttävät KDE:n omaa
**Sonnet**-kehystä, jolla on täysin erillinen taustaosajärjestelmä.
`enchant.ordering`-tiedosto ei koske niitä lainkaan. (Repon aiemmat versiot
väittivät toisin — korjattu 2026-09-16.)

Voikko toimii KDE-sovelluksissa **jo valmiiksi**, koska Sonnetin oma paketti
sisältää Voikko-liitännäisen:

```
$ pacman -Qo /usr/lib/qt6/plugins/kf6/sonnet/sonnet_voikko.so
/usr/lib/qt6/plugins/kf6/sonnet/sonnet_voikko.so is owned by sonnet 6.29.0-1

$ ldd /usr/lib/qt6/plugins/kf6/sonnet/sonnet_voikko.so | grep voikko
	libvoikko.so.1 => /usr/lib/libvoikko.so.1
```

Kun `libvoikko` ja `voikko-fi` ovat asennettuina, suomen oikoluku toimii
Katessa, KWritessä, KMailissa, Okularissa ja missä tahansa Sonnetia
käyttävässä Qt-tekstikentässä ilman asetuksia. Mitään asennettavaa ei ole.

### Milloin oikoluku voi vaihtua huonompaan

Suomelle ei tarvitse pakottaa taustaosan järjestystä — ei
`enchant.ordering`-tiedostoa eikä Sonnet-asetusta — **niin kauan kuin Voikko
on ainoa suomen tarjoaja molemmissa**. Näin on silloin kun järjestelmässä ei
ole suomen hunspell-sanastoa lainkaan, eli kun hakemistoa
`/usr/share/hunspell/` ei ole olemassa tai siellä ei ole `fi_FI`-tiedostoja.

**Tilanne muuttuu sinä päivänä kun asennat suomen hunspell-sanaston
järjestelmänlaajuisesti** — esimerkiksi tämän repon julkaisemattomalla
paketilla `hunspell-fi-ginter` tai millä tahansa muulla
`/usr/share/hunspell/fi_FI.*`:n asentavalla paketilla. Sen jälkeen molemmilla kehyksillä on kaksi tarjoajaa, ja
kumpikin voi valita hunspellin. Oikoluvun kattavuus putoaa Voikon 95,0 %:sta
88,0 %:iin ilman mitään virheilmoitusta. Ainoa oire on että `tarkkailukehä`
alkaa alleviivautua.

#### enchant: `enchant.ordering` ei korjaa tätä

Tämä kohta korjaa repon aiemman ohjeen. Vanha neuvo lupasi korjauksen, jota ei
ole olemassa. Mitattu 2026-09-16.

Syy on tunnusten nimissä. Arch asentaa hunspell-sanaston nimellä `fi_FI`
(samoin kuin `hunspell-en_us` → `en_US`), kun taas Voikko rekisteröityy
enchantiin nimellä `fi`. Ne eivät siis kilpaile samasta tunnuksesta, ja
`enchant.ordering` ratkaisee **vain samaa tunnusta tarjoavien kesken**:

```
$ enchant-lsmod-2 -list-dicts          # kun /usr/share/hunspell/fi_FI.* on paikallaan
fi (voikko)
fi_FI (hunspell)
```

Ero on todellinen, ei pelkkää tulosteen kosmetiikkaa — sama ajo, eri tunnus:

```
$ printf 'tarkkailukehä\nkoronarokote\n' | enchant-2 -d fi -l
                                       # tyhjä: molemmat kelpaavat (Voikko)
$ printf 'tarkkailukehä\nkoronarokote\n' | enchant-2 -d fi_FI -l
tarkkailukehä
koronarokote                           # hunspell hylkää molemmat
```

Kaikki kokeillut `enchant.ordering`-rivit ja niiden vaikutus tunnukseen
`fi_FI`:

| Rivi | `-lang fi_FI` |
|---|---|
| (ei tiedostoa) | `fi_FI (hunspell)` |
| `fi_FI:voikko` | `fi_FI (hunspell)` |
| `fi_FI:voikko,hunspell` | `fi_FI (hunspell)` |
| `*:voikko` | `fi_FI (hunspell)` |

**Yksikään ei tehoa.** Voikko ei tarjoa tunnusta `fi_FI` lainkaan, joten
järjestystiedostolla ei ole mitään mistä valita.

Enchant ei silti ole rikki. Jos sanasto nimetään `fi.{aff,dic}`, tunnusten
törmäys on aito ja järjestystiedosto toimii odotetusti: `fi:hunspell` →
`fi (hunspell)`, `fi:voikko` → `fi (voikko)`. Rivi `fi:voikko` on siis
järkevä vakuutus sen varalta, että joku asentaa sanaston tuolla nimellä, mutta
se ei auta `fi_FI`-tapaukseen:

```bash
# enchant (GTK, gspell, WebKitGTK, fcitx5, jinx)
mkdir -p ~/.config/enchant
printf 'fi:voikko\n' > ~/.config/enchant/enchant.ordering
```

**Käytännön ohje:** jos haluat Voikon takaisin tunnukselle `fi_FI`, poista
hunspell-sanasto. Jos tarvitset hunspell-sanastoa vain selaimiin ja Neovimiin,
älä asenna sitä järjestelmänlaajuisesti lainkaan — käytä `chromium-dict-fi`-
ja `nvim-spell-fi`-paketteja, jotka eivät koske enchantiin.

#### Sonnet: `defaultClient`

```bash
# Sonnet (KDE/Qt) — huomaa iso V
mkdir -p ~/.config/KDE
printf '[General]\ndefaultClient=Voikko\n' >> ~/.config/KDE/Sonnet.conf
```

Sonnet valitsee kullekin kielelle sen tarjoajan, jonka luotettavuusluku
(`reliability()`) on suurin — Voikko 50, hunspell 40 — joten pakottamista ei
pitäisi tarvita. Sonnet eroaa enchantista kahdella tavalla, jotka menevät
helposti väärin:

- **Kirjainkoko merkitsee.** Arvo vertautuu taustaosan `name()`-metodin
  palautusarvoon, joka on `Voikko` isolla alkukirjaimella. Pieni `voikko` ei
  osu mihinkään, ja Sonnet ohittaa asetuksen kertomatta siitä mitään.
  Enchantin vastaava arvo taas *on* pienellä (`fi:voikko`).
- **Sonnetin asetus koskee kaikkia kieliä, enchantin vain yhtä.**
  `defaultClient` nimeää yhden taustaosan kaikille kielille; sillä ei voi
  valita Voikkoa vain suomelle. Enchantin rivi `fi:voikko` koskee vain suomea.
  Kumpikaan ei silti auta `fi_FI`-tunnukseen, ks. yllä.

Jos `~/.config/KDE/Sonnet.conf` on jo olemassa, muokkaa sitä käsin — yllä
oleva `>>` lisää rivin tiedoston loppuun eikä yhdistä sitä olemassa olevaan
`[General]`-lohkoon.

Ks. [docs/sovellukset.md](docs/sovellukset.md) kohta 2.

---

## 2. Selaimet, sähköposti ja editorit — hunspell-reitti

Nämä sovellukset eivät osaa Voikkoa. Kaikki alla oleva johdetaan samasta
hunspell-sanastosta (`.aff` + `.dic`), mutta jokainen sovellusperhe tarvitsee
oman pakatun muotonsa: `.xpi` Mozillalle, `.bdic` Chromiumille, `.spl`
editoreille.

Kaikki kolme saa kerralla paikoilleen komennolla `tools/asenna.sh`. Alla
kerrotaan mitä se tekee ja miten sama tehdään käsin.

### Firefox ja Thunderbird

Sama tiedosto `build/fi-spell-0.2.xpi` asentuu molempiin. Kyseessä on
*dictionary*-tyyppinen lisäosa, joka vain toimittaa `.aff`/`.dic`-parin
sovelluksen omalle hunspellille. Sanastolisäosat **eivät tarvitse Mozillan
allekirjoitusta**, joten tämä asentuu myös tavalliseen Release-versioon.
Tämä on ajettu todeksi 2026-09-16 Firefox 155.0.1:llä (release-kanava):
allekirjoittamaton paketti asentui, ei mennyt `appDisabled`-tilaan, ja
sanasto rekisteröityi oikoluvulle. Ks.
[docs/sovellukset.md](docs/sovellukset.md) kohta 6.

- **Firefox:** `about:addons` → rataskuvake → *Asenna lisäosa tiedostosta*.
- **Thunderbird:** Asetukset (☰) → *Lisäosat ja teemat* → rataskuvake →
  *Install Add-on From File…*, tai raahaa `.xpi` suoraan lisäosien
  hallintavälilehdelle.

**Asennus ei yksin riitä — kieli on valittava.** Firefox ei valitse sanastoa
sen perusteella, mikä on asennettu, vaan kentän tai sivun kielestä ja
`spellchecker.dictionary`-asetuksesta. Tuoreessa profiilissa asetus on tyhjä,
jolloin suomenkielinen teksti tarkistetaan englannin sanastolla eikä lisäosasta
näytä olevan mitään hyötyä. Napsauta tekstikenttää **oikealla painikkeella**,
varmista että *Tarkista oikeinkirjoitus* on rastitettu, ja valitse sitten
*Kielet* → **suomi**. Valinta jää muistiin ja koskee jatkossa kaikkia kenttiä.
Saman voi tehdä `about:config`-sivulla asettamalla `spellchecker.dictionary`
arvoon `fi`.

Toimiiko se? Avaa [tools/oikoluku-testi.html](tools/oikoluku-testi.html)
selaimeen. Siinä on kaksi tekstikenttää samoilla sanoilla, joista toinen on
merkitty `lang="fi"`:ksi. Oikein mennyt asennus alleviivaa rivin
`kissanrooka pyorailla qwertyxyz` muttei riviä `kissanruoka pyöräillä talo`.

Ginterin oma README sanoo tämän suoraan: *"The extension can be directly
installed to Thunderbird and Firefox."* Paketin `manifest.json`-tiedostossa ei
ole versiorajoja eikä sovelluskohtaisia lohkoja, mikä tukee väitettä.

Tiedosto on Filip Ginterin **alkuperäinen julkaisu** sellaisenaan
(`fginter/hunspell-fi` release 0.2), ei tässä repossa rakennettu — tarkistettu
SHA-256-summalla, ks. [docs/lahteet.md](docs/lahteet.md).

#### Monta profiilia — sanasto ilman lisäosaa

Lisäosa asennetaan profiilin sisään, joten monen profiilin koneella se on
käsityötä joka profiilille ja oma ~15 Mt kopio sanastosta jokaiseen. Firefox
osaa kuitenkin lukea hunspell-sanaston myös hakemistosta, jonka pref
`spellchecker.dictionary_path` osoittaa — yksi kopio, kaikki profiilit:

```bash
tools/firefox-ota-kayttoon.sh --kaikki-profiilit
```

Firefoxin on oltava suljettuna: se kirjoittaa `prefs.js`:n uudelleen
lopettaessaan. Työkalu kopioi sanaston jaettuun hakemistoon
(`~/.local/share/suomen-kieliavut/hunspell`) ja osoittaa profiilit siihen.
Kattavuus on täysi Ginter 88,0 %, sama kuin lisäosalla.

Kaksi asiaa eroaa lisäosaohjeesta. **Tunniste on `fi-FI` eikä `fi`** — se
tulee tiedostonimestä `fi_FI`, kun lisäosa ilmoittaa nimekseen `fi`. Ja
**jaettu hakemisto ei saa olla `/usr/share/hunspell`**, vaikka se onkin prefin
oletusarvo: enchant haravoi saman polun, ja sanasto siellä syrjäyttäisi Voikon
GTK-sovelluksissa (ks. yllä [enchant: `enchant.ordering` ei korjaa
tätä](#enchant-enchantordering-ei-korjaa-tätä)).

**Thunderbird ja Betterbird** toimivat samalla työkalulla, koska oikoluku on
samaa Gecko-koodia. Profiilijuuri annetaan argumenttina:

```bash
tools/firefox-ota-kayttoon.sh ~/.config/thunderbird    # tai ~/.thunderbird
```

Todettu Betterbird 153.3.0esr:llä 2026-09-18; Thunderbirdiä itseään ei ole
ajettu.

Mittausmenetelmä, negatiivinen tulos profiilin omasta `dictionaries/`-
hakemistosta ja profiilien etsinnän kompastuskivet:
[docs/sovellukset.md](docs/sovellukset.md) kohta 6.

#### Miksi käsin, kun AMO:ssa on suomen sanasto?

Firefoxin lisäosahakemistossa on tasan yksi suomen oikolukusanasto: fluksin
*Finnish Spellchecker* (`fi-FI@dictionaries.addons.mozilla.org`, 376
päivittäistä käyttäjää). Se asentuu yhdellä napsautuksella, ja siihen verrattuna
tämä repo vaatii tiedoston lataamisen käsin. Ero on silti selvä kahdella
akselilla: sisällössä (mitattu) ja lisenssissä (todettu).

**Sisältö.** AMO:n sanasto on myspell-fi 0.7 (Vermeer & Virtanen, Debianin
`myspell-fi 0.7-18`) — ketju on jäljitetty lähteistä, ks.
[docs/jakelu.md](docs/jakelu.md). Se on sama sanasto, joka on yllä olevassa
kattavuustaulukossa rivillä `myspell-fi 0.7`:

| | Uniikit sanat | Esiintymät | Koko |
|---|---|---|---|
| AMO:n *Finnish Spellchecker* (myspell-fi 0.7) | 47,3 % | 80,1 % | ~480 kt¹ |
| tämän repon `.xpi` (Ginter kokonaan) | **88,0 %** | **95,9 %** | 4,7 Mt |

¹ AMO:n listaussivun ilmoittama koko, ei repon mittaama.

Laajennuksen oma AMO-kuvaus myöntää rajoituksen: *"conjugations and compounds
are not well supported in this spell checker."* Se on johdonmukainen mitatun
eron kanssa — suomessa juuri taivutus ja yhdyssanat tuottavat valtaosan
sanamuodoista.

**Lisenssi.** AMO:n sanasto on GPL-2.0-only, tämän repon Ginter-pohjainen
sanasto CC0-1.0. Uudelleenjakelun kannalta ero on suurempi kuin
kattavuusero.

Kaksi rehellistä varausta. **Tämä on kattavuus, ei oikolukulaatu** — mittaus
kertoo vain, kuinka suuren osan oikein kirjoitetuista sanoista sanasto
tunnistaa, ei sitä kuinka luotettavasti se hylkää virheet tai kuinka osuvia
sen korjausehdotukset ovat; laajempi sanasto voi hyväksyä myös virheellisiä
muotoja. Ja **AMO-paketin sisältö on pääteltu, ei purettu**: `1.1.2resigned1`
-julkaisua ei ole ladattu eikä verrattu tavu tavulta
`dict/myspell-fi-0.7/`:hen.

Tunnisteet eivät törmää, joten molemmat voi pitää asennettuina yhtä aikaa ja
valita kumpaa käyttää *Kielet*-valikosta.

Jos haluat rakentaa oman version (esim. karsitusta sanastosta),
[tools/build-xpi.sh](tools/build-xpi.sh) tuottaa erikseen nimetyn
`build/fi-spell-oma-<versio>.xpi`-tiedoston. Selitys:
[docs/sanastot.md](docs/sanastot.md).

### Chromium ja Electron-sovellukset

Google **ei toimita suomen sanastoa lainkaan** — suomi ei ole Chromen
tuettujen oikolukukielten listalla. Siksi `.bdic`-tiedosto on käännettävä itse
Chromiumin `convert_dict`-työkalulla ja pudotettava profiilin
sanastohakemistoon:

```bash
install -Dm644 build/fi-FI.bdic ~/.config/chromium/Dictionaries/fi-3-0.bdic
```

#### Tiedoston nimen on oltava täsmälleen oikea

Chromium ei etsi sanastoa kielikoodilla `fi-FI` eikä ilman versionumeroa: se
avaa vain yhden tietyn nimen, ja Chromium 152:ssa se on `fi-3-0.bdic`. Väärin
nimetty tiedosto ohitetaan täysin ilman virheilmoitusta — selain yrittää sen
sijaan ladata sanaston Googlelta, mikä päättyy 404-virheeseen, koska suomea ei
ole tarjolla.

Nimen muoto on `<kielikoodi>-<sanastoversio>.bdic`, ja **sanastoversio on
kielikohtainen**: englannilla `en-US-10-1.bdic`, suomella `fi-3-0.bdic`.
Englannin päätteestä ei siis voi päätellä suomen päätettä. Jos oikoluku lakkaa
toimimasta Chromiumin päivityksen jälkeen, tarkista mitä nimeä selain
oikeasti hakee:

```bash
tools/chromium-sanastonimi.sh
```

#### Kieli on myös merkittävä oikoluettavaksi

Pelkkä tiedoston kopiointi ei riitä. Jos kieltä ei ole merkitty
oikoluettavaksi, sanastoa ei avata lainkaan — **eikä tätä voi tehdä
käyttöliittymästä.** Koska suomi ei ole Chromiumin tuettujen
oikolukukielten listassa, `chrome://settings/languages` ei tarjoa suomelle
*Tarkista tämän kielen oikeinkirjoitus* -rastia: kieli näkyy kielilistassa,
mutta oikolukuvalintaa sille ei ole.

Asetus on siis kirjoitettava suoraan profiilin `Preferences`-tiedostoon.
**Chromiumin on oltava kokonaan suljettuna**, sillä se ylikirjoittaa tiedoston
lopettaessaan:

```bash
tools/chromium-ota-kayttoon.sh
```

Skripti lisää `fi`:n `spellcheck.dictionaries`-listaan, kytkee oikoluvun
päälle ja tekee varmuuskopion. Se kieltäytyy ajamasta, jos selain on
käynnissä. Asetus säilyy uudelleenkäynnistyksissä — Chromium ei poista sitä,
vaikka kieli ei olekaan sen omalla tuettujen listalla.

#### Monta profiilia

Sanastoa **ei** tarvitse kopioida monesti: `Dictionaries/` on
käyttäjädatahakemiston tasolla, ei profiilin sisällä, joten sama
`fi-3-0.bdic` palvelee kaikkia profiileja. Profiilikohtaista on vain pref,
ja se kirjoitetaan kaikkiin kerralla:

```bash
tools/chromium-ota-kayttoon.sh --kaikki-profiilit
```

Profiileiksi tunnistetaan ne alihakemistot, joissa on `Preferences`-tiedosto
— `Default`, `Profile 1`, `Profile 2` ja niin edelleen. Chromiumin sisäinen
`System Profile` ohitetaan (siinä ei ole selainikkunaa) ja samoin
`Guest Profile` (se nollataan joka istunnossa, joten kirjoitus katoaisi).
Selaimen käynnissäolo tarkistetaan kerran: `SingletonLock` on
käyttäjädatahakemiston tasolla, koska yksi prosessi ajaa kaikkia profiileja.

Testi: kirjoita tekstikenttään `maastopyörä` (ei saa
alleviivautua) ja `maastopyöräz` (pitää alleviivautua).

#### Electron-sovellukset

Sama temppu toimii mihin tahansa Electron-sovellukseen: korvaa polku
sovelluksen omalla `~/.config/<sovellus>/Dictionaries/`-hakemistolla.
Löytyneet profiilit käy läpi oma skriptinsä:

```bash
tools/electron-sanastot.sh --listaa   # mitä koneelta löytyy ja millä versioilla
tools/electron-sanastot.sh            # asenna kaikkiin, sovellukset suljettuina
```

Skripti ei käytä `chromium-ota-kayttoon.sh`:ta sellaisenaan, koska
Electron-sovellukset eivät noudata Chromiumin profiilirakennetta:
`Preferences` on osalla `Default/`-alihakemistossa ja osalla profiilin
juuressa, eikä `SingletonLock` ole kaikilla. Käynnissä olevat sovellukset se
ohittaa — ne ylikirjoittaisivat `Preferences`-tiedoston lopettaessaan.

#### Sanaston kääntäminen itse

**Käännösohje: [docs/convert-dict.md](docs/convert-dict.md).** Se on repon
ydinsisältöä — tästä ei ole netissä koottua kuvausta.

Yksi asia kannattaa tietää etukäteen: **Ginterin koko sanasto ei mahdu
`.bdic`-muotoon.** 476 291 sanuetta ylittää muodon rajan, ja `convert_dict`
kaatuu vasta tarkistusvaiheessa ilmoitukseen `Found the end before we
expected`. Mukana oleva `build/fi-FI.bdic` on siksi karsittu 245 000
sanueeseen — `tools/build-bdic.sh frekvenssi` toistaa sen bitilleen.

**Karsintakriteeri vaihtui 0.9:ssä.** Aiempi kriteeri antoi etusijan
myspell-fi 0.7:n sanalistalla oleville sanoille. Se lista on GPL-2.0-only, ja
kriteerinä se teki tuloksesta johdetun teoksen — vaikka tulos sisältää vain
Ginterin sanoja. Nykyinen kriteeri on sanan esiintymistiheys vapaassa
korpuksessa. Se on sekä lisenssipuhdas että 3,3 prosenttiyksikköä parempi.
Mittaukset: [docs/convert-dict.md](docs/convert-dict.md).

Toistettavuus vaatii kaksi lukitusta, jotka skripti tekee itse:
`convert_dict`-työkalu noudetaan lukitusta commitista ja varmennetaan
SHA-256-summilla, ja lokaaliksi pakotetaan `C.UTF-8`.

### Neovim ja Vim

Sama `.spl`-tiedosto kelpaa molempiin; vain hakemisto vaihtuu.

```bash
install -Dm644 build/fi.utf-8.spl ~/.config/nvim/spell/fi.utf-8.spl  # Neovim
install -Dm644 build/fi.utf-8.spl ~/.vim/spell/fi.utf-8.spl          # Vim
```

```vim
:set spelllang=fi
:set spell
```

Tiedoston otsake on `VIMspell` + versiotavu `0x32` = 50, mikä vastaa Vimin
lähdekoodin `VIMSPELLVERSION`-arvoa. Vim hylkää vain tätä uudemman version,
joten tiedosto kelpaa.

**Varoitus kattavuudesta.** Editorit lukevat `.spl`-tiedostoa, eivät Voikkoa,
joten ne jäävät hunspell-maailman 88,0 %:iin eivätkä yllä Voikon 95,0 %:iin.
Mitattu 2026-09-16 puhtaalla konfiguraatiolla (NVIM v0.12.5, `nvim --clean`):

```
maastopyöräily            => ok
maastopyöräilyz           => bad     (oikein, tämä on virhe)
tarkkailukehä             => bad     <- kelvollinen sana
koronarokote              => bad     <- kelvollinen sana
kirjoittaisimmekohan      => bad     <- kelvollinen sana
```

Tämän README:n oma esimerkkisana `tarkkailukehä` siis alleviivautuu. Se ei ole
asennusvirhe vaan sanaston raja. **Valmista Voikko-LSP-palvelinta ei ole
olemassa** (tarkistettu 2026-09-16). Periaatteessa toimiva mutta toteuttamaton
polku olisi `efm-langserver` + `voikkospell`, ks.
[docs/sovellukset.md](docs/sovellukset.md) kohta 7.

Omat sanat menevät `zg`-komennolla tiedostoon
`~/.config/nvim/spell/fi.utf-8.add`, joka on tavallista tekstiä.
Uudelleenkäännös: [tools/build-nvim-spell.sh](tools/build-nvim-spell.sh).

---

## 3. Flatpak ja Snap — hiekkalaatikon rajoitus

Flatpak- ja Snap-sovellukset ajetaan eristyksissä muusta järjestelmästä. Ne
eivät näe hakemistoa `/usr/share/hunspell` eivätkä kirjastoa `libvoikko`, eikä
Flatpakin runtimessa ole Voikkoa lainkaan. Siksi **Voikko-liitännäiset eivät
toimi Flatpak- tai Snap-LibreOfficessa** — ne ovat Python-koodia, joka yrittää
ladata kirjaston jota siellä ei ole.

Repon ratkaisu on **`.oxt`-sanastolaajennus** (`tools/build-oxt.sh` →
`build/fi-hunspell-<versio>.oxt`). Se on puhdasta hunspell-dataa ilman
natiivikoodia ja asentuu LibreOfficen omaan laajennushakemistoon eristyksen
*sisälle*. Hinta on tuttu: 88,0 % Voikon 95,0 %:n sijaan, eikä
kielentarkistusta lainkaan.

```bash
tools/build-oxt.sh 0.9 ginter              # -> build/fi-hunspell-0.9.oxt
unopkg add build/fi-hunspell-0.9.oxt       # käyttäjäkohtainen, ei sudoa
unopkg remove fi.hunspell.suomen-kieliavut # poisto
```

Paketin voi myös avata kaksoisklikkauksella millä tahansa distrolla. Repossa
toimitetaan valmis `build/fi-hunspell-0.9.oxt`, joka sisältää Ginterin koko
sanaston — `.oxt` on pelkkä zip-kääre eikä siinä ole `.bdic`-muodon kokorajaa.
Tarkistus: `tools/tarkista-oxt.py build/fi-hunspell-0.9.oxt 0.9`.

Paketissa ei ole LibreOffice-versiorajoja samasta syystä kuin
Voikko-liitännäisessäkään: juuri siksi tuo vuonna 2015 julkaistu laajennus yhä
rekisteröityy LibreOffice 26.8:aan.

**Skriptattaessa älä kirjoita `unopkg list | grep -q ...`.** `grep -q` sulkee
putken ensimmäiseen osumaan, jolloin `unopkg` kuolee SIGPIPE-signaaliin ennen
kuin ehtii poistaa lukkotiedostonsa `~/.config/libreoffice/4/.lock`. Kuollut
lukko kaataa kaikki myöhemmät `unopkg`-ajot virheeseen *"the lock file
indicates it is already running"*. Lue ulostulo ensin muuttujaan (ks.
`install.sh`).

Lähteet ja tarkempi kuvaus: [docs/sovellukset.md](docs/sovellukset.md) kohta 8
— mukaan lukien se, että yleisimmin siteerattu Flathub-issue koskee unkaria,
ei suomea.

---

## 4. Omat sanat — mihin ne tallentuvat

| Sovellus | Sijainti | Muoto |
|---|---|---|
| LibreOffice | `~/.config/libreoffice/4/user/wordbook/standard.dic` | oma tekstimuoto |
| Chromium | `~/.config/chromium/Default/Custom Dictionary.txt` | rivi per sana |
| Firefox / Thunderbird | `<profiili>/persdict.dat` | rivi per sana |
| Neovim | `~/.config/nvim/spell/fi.utf-8.add` | rivi per sana |
| Vim | `~/.vim/spell/fi.utf-8.add` | rivi per sana |
| KDE/Qt (Sonnet) | `…/Sonnet/Voikko-user-dictionary.json` | JSON, avain `PersonalWords` |
| Voikko | — | ei omaa käyttäjäsanastoa; vanha `~/.voikko/` poistui |

Voikossa ei siis ole yhtä yhteistä käyttäjäsanastoa: jokainen sovellus hoitaa
lisäykset itse. Nämä tiedostot kannattaa ottaa mukaan, kun vaihdat konetta.

---

## Asennus asentimella

Jos repo on kloonattuna:

```bash
tools/asenna.sh          # kaikki paitsi enchant.ordering
tools/asenna.sh --help   # osina
```

Skripti on idempotentti: sen voi ajaa uudestaan turvallisesti, eikä se
ylikirjoita olemassa olevia sanastoja ilman `--force`-lippua. Idempotenssi ei
kuitenkaan tarkoita peruutettavuutta: yhtenäistä poistoskriptiä ei ole, ja
poisto tehdään käsin — ks. [Poistaminen](#poistaminen). `enchant`-osa on
oletuksena **pois päältä**, koska `enchant.ordering`-tiedostoa ei normaalisti
tarvita (ks. [yllä](#enchant-enchantordering-ei-korjaa-tätä)). Sen saa
käyttöön erikseen: `--vain enchant`.

Jos repoa ei halua kloonata, repon juuressa oleva `install.sh` noutaa
julkaistun version ja asentaa halutut osat:

```bash
curl -fsSL https://github.com/mhavo/suomen-kieliavut/raw/v0.9/install.sh | bash
```

`install.sh` noutaa sanastot GitHub-julkaisusta ja **varmentaa jokaisen
SHA-256-summalla ennen kuin mitään kirjoitetaan levylle**; epäsuhta keskeyttää
asennuksen. Osat ovat samat kuin `tools/asenna.sh`:ssa, ja lisäksi valittavissa
on `oxt` (LibreOffice-sanastolaajennus). Oletuksena skripti kirjoittaa vain
kotihakemistoon eikä pyydä sudoa, joten **kaksi osaa on oletuksena pois
päältä**: `hyphen` vaatii sudon (`--vain hyphen`) ja `oxt` on varareitti
Flatpak-LibreOfficelle eikä oletusvalinta (`--vain oxt`). Distron se tunnistaa ja kertoo oikeat
Voikko-paketit, mutta ei asenna niitä kysymättä.

Tarkistussummat on upotettu skriptiin, koska etäasennin ei voi lukea repon
`SHA256SUMS`-tiedostoa. CI vertaa nämä kaksi kopiota toisiinsa ja kaatuu
erosta — muuten unohtunut päivitys näyttäisi käyttäjälle hyökkäykseltä.

**Mitä summat eivät suojaa.** Ne suojaavat rikkoutuneelta latauksella ja
julkaisun liitetiedoston vaihtumiselta. Ne **eivät** suojaa kaapatulta
GitHub-tililtä tai siirretyltä tagilta: jos hyökkääjä pääsee vaihtamaan
julkaistut tiedostot, hän pääsee vaihtamaan myös verkosta ajettavan
`install.sh`:n ja sen upotetut summat, jolloin tarkistus vertaa hyökkääjän
tiedostoa hyökkääjän summaan. Luottamus on siis viime kädessä repon tiliin,
ei summiin. Kuka tahansa joka ei halua ajaa noutamaansa skriptiä suoraan, voi
noutaa sen ensin, lukea sen ja ajaa sitten:

```bash
curl -fsSLO https://github.com/mhavo/suomen-kieliavut/raw/v0.9/install.sh
less install.sh
bash install.sh
```

Mukana toimitettujen binäärien eheyden voi tarkistaa milloin tahansa:

```bash
sha256sum -c SHA256SUMS
```

### Poistaminen

Yhtenäistä poistoskriptiä **ei ole** — asennin ei pidä kirjaa kirjoittamistaan
tiedostoista. Poisto tehdään käsin, ja alla on täydellinen luettelo
kohteista. Automatisoitu poisto on kirjattu siirretyksi työksi
([HARDENING_NOTES.md](HARDENING_NOTES.md)).

| Osa | Poisto |
|---|---|
| `voikko` | `pacman -R voikko-fi voikko-libreoffice` (tai `apt remove`) — repo ei kirjoita tässä mitään itse |
| `hyphen` | `sudo rm /usr/share/hyphen/hyph_fi_FI.dic` |
| `chromium` | `rm ~/.config/chromium/Dictionaries/fi-3-0.bdic`. **ja** poista suomi Chromiumin asetuksista (Asetukset → Kielet), jossa se näkyy asennuksen jälkeen; älä muokkaa `Preferences`-tiedostoa käsin |
| `nvim` | `rm ~/.config/nvim/spell/fi.utf-8.spl` |
| `enchant` | **poista vain rivi** `fi:voikko` tiedostosta `~/.config/enchant/enchant.ordering` — älä poista tiedostoa, se voi olla muiden kielten käytössä |
| `firefox` | poista lisäosa `about:addons`-sivulta; noudettu välimuistikopio: `rm -r ~/.cache/suomen-kieliavut/` |
| `firefox` (jaettu sanasto) | `rm -r ~/.local/share/suomen-kieliavut/hunspell` **ja** nollaa `spellchecker.dictionary_path` ja `spellchecker.dictionary` `about:config`-sivulla jokaisessa profiilissa |
| `oxt` | `unopkg remove fi.hunspell.suomen-kieliavut` (listaa: `unopkg list`) |

Kolme asiaa, jotka on helppo unohtaa:

**Varmuuskopiot jäävät.** `tools/chromium-ota-kayttoon.sh` ja
`tools/electron-sanastot.sh` kopioivat `Preferences`-tiedoston nimelle
`Preferences.bak-<aikaleima>` joka kerta kun ne kirjoittavat siihen, eikä
mikään siivoa niitä. Ne kertyvät profiiliin: `ls ~/.config/chromium/Default/Preferences.bak-*`.
`tools/firefox-ota-kayttoon.sh` tekee saman Firefoxin `prefs.js`:lle:
`ls ~/.config/mozilla/firefox/*/prefs.js.bak-*`.

**Electron-sovellukset on käytävä läpi erikseen.** `tools/electron-sanastot.sh`
kirjoittaa jokaiseen löytämäänsä profiiliin — `~/.config/*/Dictionaries/` ja
`~/.var/app/*/config/*/Dictionaries/` (Flatpak). Poisto on sama kahdessa
osassa kuin Chromiumilla: `.bdic` pois ja kieli pois sovelluksen asetuksista.

**AUR-paketin poisto ei poista profiiliin kopioituja tiedostoja.**
`pacman -R` poistaa vain paketin omistamat `/usr/share`-polut. Jos olet
lisäksi ajanut asentimen tai kopioinut sanaston itse kotihakemistoosi, se
kopio jää — `chromium-dict-fi` sanoo tämän myös poistoviestissään.

Jos `unopkg` jää valittamaan lukkotiedostosta (*"the lock file indicates it is
already running"*), poista `~/.config/libreoffice/4/.lock`. Lukko jää roikkumaan,
jos `unopkg list` on aiemmin putkitettu `grep`iin ja kuollut SIGPIPEen.

### Järjestelmänlaajuinen asennus Archissa

`packaging/aur/`-hakemistossa on kolme PKGBUILDia: `hyphen-fi`,
`chromium-dict-fi` ja `nvim-spell-fi`.

```bash
cd packaging/aur/hyphen-fi && makepkg -si
```

`hyphen-fi` kannattaa asentaa ensin ja erikseen: se täyttää aidon aukon (Arch
ei paketoi suomen tavutuskuvioita lainkaan) eikä muuta minkään sovelluksen
oikolukua.

Neljäs paketti, `hunspell-fi-ginter`, **ei kuulu 0.9-julkaisuun**. Se on repon
ainoa komponentti, jolla on globaali, ei-konfiguroitava haittavaikutus: se vie
enchantilta tunnuksen `fi_FI` kaikissa työpöytäsovelluksissa, eikä
`enchant.ordering` korjaa sitä. Ks. [Milloin oikoluku voi vaihtua
huonompaan](#milloin-oikoluku-voi-vaihtua-huonompaan). Koodi on tallessa
hakemistossa `packaging/ei-julkaista-hunspell-fi-ginter/` — se on paras
dokumentaatio siitä, miksi tätä ei kannata tehdä.

Paketit eivät ole vielä AUR:ssa. Niiden `source`-rivit osoittavat julkaisuun
`v0.9`, joka on nyt olemassa, joten lähteet ovat noudettavissa — jäljellä on
chroot-rakennus, `namcap` ja lähetys. Ohje ja korvattavat kohdat ovat
[packaging/README.md](packaging/README.md)-tiedostossa.

---

## Repon sisältö

```
dict/ginter/            Filip Ginterin hunspell-muunnos (476 291 sanuetta, 16 MB)
dict/ginter-karsittu/   sama, 245 000 sanuetta — mahtuu Chromiumin .bdic-muotoon
dict/myspell-fi-0.7/    Vermeer & Virtanen, myspell-fi 0.7 (88 452 sanuetta, ISO8859-1)
dict/hyphen/            hyph_fi_FI.dic — LibreOfficen tavutuskuviot
build/fi-spell-0.2.xpi       Firefox-sanastolisäosa (Ginter kokonaan)
build/fi-FI.bdic             Chromium-sanasto (Ginter karsittuna)
build/fi-FI-myspell-0.7.bdic vanha Chromium-sanasto, säilytetty vertailuksi
build/fi.utf-8.spl           Vim- ja Neovim-oikolukusanasto (Ginter kokonaan)
build/fi-hunspell-<v>.oxt    LibreOfficen sanastolaajennus (toimii Flatpakissa)
install.sh              Asennin, myös curl | bash -käyttöön
tools/                  Asennus-, käännös- ja mittausskriptit
  build-oxt.sh            rakentaa .oxt-sanastolaajennuksen
  tarkista-oxt.py         validoi .oxt:n rakenteen
  electron-sanastot.sh    asentaa .bdic:n löytyneisiin Electron-profiileihin
  chromium-ota-kayttoon.sh  kytkee suomen Chromiumin profiilien oikolukuun
  firefox-ota-kayttoon.sh   sama Firefoxille, jaetulla sanastolla ilman lisäosaa
  pref-kirjoitus.py       Chromium-/Electron-profiilin Preferences-kirjoitus
  prefs-js-kirjoitus.py   Firefox-profiilin prefs.js-kirjoitus
  nouda-wikipedia.py      poimii arviointikorpuksen fi-Wikipediasta
  rakenna-korpus.py       tokenisoi raakadatan sanalistoiksi
  korpus/                 arviointikorpus, ks. korpus/LUE.md
  korpus-frekvenssit.txt  karsintakriteerin frekvenssilista (eri otos)
packaging/aur/          PKGBUILDit: hyphen-fi, chromium-dict-fi, nvim-spell-fi
packaging/ei-julkaista-hunspell-fi-ginter/
                        julkaisematon paketti — ks. packaging/README.md
.github/workflows/      CI: shellcheck, summat, sanastot, .bdic, XPI, .oxt, kattavuus
docs/                   Yksityiskohtaiset ohjeet ja lähdeviitteet
raw/                    Muuttumaton lähdeaineisto (mm. Debianin voikko-oxt)
SHA256SUMS              build/-tiedostojen tarkistussummat
LICENSES.md             tiedostokohtaiset lisenssit
```

### Dokumentit

| | |
|---|---|
| [docs/sovellukset.md](docs/sovellukset.md) | sovelluskohtainen tila: enchant, Sonnet, Vim, Thunderbird, Emacs, Flatpak |
| [docs/sanastot.md](docs/sanastot.md) | mistä sanastot tulevat ja mikä niistä kannattaa valita |
| [docs/convert-dict.md](docs/convert-dict.md) | Chromiumin `.bdic`:n kääntäminen |
| [docs/arch-vs-debian.md](docs/arch-vs-debian.md) | viisi eroa, joihin Ubuntu-ohje kaatuu Archissa |
| [docs/jakelu.md](docs/jakelu.md) | miksi repo julkaisee binäärit ja mitä kanavia pitkin |
| [docs/lahteet.md](docs/lahteet.md) | alkuperä ja lähdeviitteet |

### Miksi hunspell-sanastoja on kaksi

Ne eivät ole vaihtoehtoja toisilleen samassa mielessä. Ginterin sanasto on
paljon laajempi mutta raakile; myspell-fi 0.7 on pieni mutta huoliteltu ja
vuodelta 2008. Kolmas, `dict/ginter-karsittu/`, on johdettu molemmista. Ks.
[docs/sanastot.md](docs/sanastot.md).

---

## Testiympäristö ja todentamisen rajat

Kaikki mittaukset ja `$`-alkuiset esimerkkitulosteet on ajettu
**2026-09-16** ympäristössä Arch/Omarchy, LibreOffice 26.8, `sonnet 6.29.0-1`,
`enchant 2.8.21-1`, `libvoikko` Archin `extra`-paketista, NVIM v0.12.5,
Firefox 155.0.1 (release).
Poikkeukset on merkitty erikseen.

**Tämä on 0.9, ei 1.0.** Osa julkaisupolusta on todentamatta, ja se on
merkitty alla olevaan taulukkoon sellaiseksi. Jokaisen jaeltavan tiedoston
lisenssiketju on selvitetty ja kirjattu ([LICENSES.md](LICENSES.md), joka on
itse julkaisun liitetiedosto), mutta yhdessä ketjussa on avoin kohta — ei
kuitenkaan se, että lisenssi puuttuisi. Ginterin sanaston lisenssin on tekijä
itse merkinnyt upstreamin README:ssä (`# License` / `CC0`, tarkistettu
2026-09-16). Avoinna on vain, miten aineiston **Voikko-suodatus**
(GPL-2.0-or-later) tulkitaan, eikä sitä ole kysytty tekijältä. Siksi
AMO-vientiä ei tehdä.
Mitattua on kattavuus — ei oikolukulaatu, ks. yllä.

Osaa väitteistä ei ole voitu ajaa todeksi, koska kyseistä sovellusta ei ollut
testiympäristössä. Nämä on todennettu rakenteellisesti — paketin sisältö,
riippuvuudet, tiedostomuodon versio, lähdekoodi — ei ajamalla:

| Väite | Miten todennettu |
|---|---|
| Voikko toimii KDE-sovelluksissa | paketti `sonnet`, riippuvuus `libvoikko`, liitännäisen latautuvuus |
| Sonnetin `defaultClient`-asetus | Sonnetin lähdekoodi; ei testattu oikeassa KDE-sovelluksessa |
| Thunderbirdin valikkopolku `.xpi`:lle | Ginterin README ja paketin `manifest.json`. Sama paketti on ajettu todeksi Firefox 155.0.1:llä, mutta Thunderbirdiä ei ole tällä koneella. Jaetun sanaston reitti (`prefs.js`) on sen sijaan todettu Betterbird 153.3.0esr:llä |
| Vim lukee `build/fi.utf-8.spl`:n | tiedostomuodon versiotavu vs. `VIMSPELLVERSION` (Neovimilla ajettu) |
| Flatpak- ja Snap-rajoitukset | julkiset lähteet, ks. [docs/sovellukset.md](docs/sovellukset.md) kohta 8 |
| `.oxt` toimii Flatpak-LibreOfficessa | **ei todennettu lainkaan.** Testattu vain natiivilla LibreOffice 26.8:lla. Flatpak on koko `.oxt`:n olemassaolon pääperuste, joten tämä on merkittävä aukko |
| AUR-pakettien rakennus `makepkg`illa | **ei todennettu.** Vain `package()`-funktiot on ajettu käsin; lähdetiedostojen nouto ja summantarkistus vaativat olemassa olevan julkaisun |
| Etäasennin oikeaa julkaisua vasten | **ei todennettu.** Testattu vain paikallisella `file://`-julkaisulla |
| Electron-tuki Flatpak-poluissa | **ei todennettu.** `~/.var/app/*/config/*/Dictionaries` on haussa mukana, mutta koneella ei ole `~/.var/app`-hakemistoa lainkaan |

Sovelluskohtainen erittely siitä mitä on todennettu ja millä tavalla:
[docs/sovellukset.md](docs/sovellukset.md).

---

## Jakelu

Suomen hunspell-sanastoa ei ole AUR:ssa, Debianissa eikä
addons.mozilla.orgissa — tarkistettu 2026-09-16. Siksi tämä repo julkaisee
valmiit käännökset eikä pelkkiä skriptejä. Kanavat, lisenssien asettamat ehdot
kullekin kanavalle ja se mikä on vielä tekemättä:
**[docs/jakelu.md](docs/jakelu.md)**.

## Distroerot

Ubuntu-ohje ei käänny Archiksi yksi yhteen: pakettien nimet ja määrä ovat eri,
Voikon data on eri polussa, LibreOffice-laajennus vaatii
`unopkg`-rekisteröinnin joka voi kadota päivityksessä, eikä tavutuskuvioita
paketoi Archissa kukaan. Kaikki viisi eroa:
[docs/arch-vs-debian.md](docs/arch-vs-debian.md).

## Lähteet ja lisenssit

Repon **oma** aineisto (`tools/`, `docs/`, `README.md`) on MIT-lisensoitu, ks.
[LICENSE](LICENSE). Mukana levitettävä kolmannen osapuolen aineisto **ei** ole:
sanastoilla on kolme eri lisenssiä.

| | Lisenssi |
|---|---|
| `dict/ginter/`, `dict/ginter-karsittu/` ja niistä johdetut `build/`-tiedostot | CC0-1.0 |
| `dict/myspell-fi-0.7/` ja `build/fi-FI-myspell-0.7.bdic` | GPL-2.0-only |
| `dict/hyphen/hyph_fi_FI.dic` | ei muodollista lisenssiä — *"Patterns may be freely distributed"* |
| `raw/libreoffice-voikko-5.0-debian/`, `raw/aur-voikko-libreoffice/` | MPL-2.0 / GPL-3.0-or-later |
| Voikko itse (asennetaan distron paketeista) | GPL-2.0-or-later |

Tiedostokohtainen erittely: **[LICENSES.md](LICENSES.md)**.
Alkuperä ja lähdeviitteet: [docs/lahteet.md](docs/lahteet.md).
