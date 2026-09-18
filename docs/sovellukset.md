# Sovelluskohtainen tila — mikä toimii, millä mekanismilla

README kertoo asennuksen. Tämä dokumentti kertoo **miten** kukin sovellusperhe
löytää suomen oikoluvun, ja mitä se käytännössä osaa. Erottelu on tarpeen,
koska mekanismeja on neljä eikä niillä ole mitään yhteistä koodia:

| Mekanismi | Kuka käyttää | Voikko | hunspell |
|---|---|---|---|
| **Voikon C-API** (`libvoikko`) | LibreOffice-liitännäinen, `voikkospell`, `voikkogc` | kyllä | — |
| **enchant** | GTK/gspell, WebKitGTK, fcitx5, Emacsin jinx | kyllä (`enchant_voikko.so`) | kyllä |
| **Sonnet** | KDE- ja Qt-sovellukset | kyllä (`sonnet_voikko.so`) | kyllä |
| **sovelluksen oma hunspell** | Firefox, Thunderbird, Chromium, Electron, Vim/Neovim | **ei** | kyllä |

Kolme ensimmäistä ovat sama Voikko eri kuorella. Neljäs on oma maailmansa,
eikä siihen ole reittiä Voikosta — ks. [sanastot.md](sanastot.md).

Kaikki tämän dokumentin mittaukset on tehty **2026-09-16** koneella
Arch/Omarchy, `sonnet 6.29.0-1`, `enchant 2.8.21-1`, `libvoikko` Archin
`extra`-paketista, NVIM v0.12.5.

---

## 1. enchant — GTK, gspell, WebKitGTK, fcitx5, Emacs

Archin `enchant`-paketti sisältää valmiiksi `/usr/lib/enchant-2/enchant_voikko.so`,
joten Voikko näkyy automaattisesti kaikissa enchantia käyttävissä sovelluksissa
heti kun `voikko-fi` on asennettu.

Ketä enchant tällä koneella palvelee:

```
$ pacman -Qi enchant | grep "Required By"
Required By     : fcitx5  gspell  webkit2gtk-4.1
```

Eli: `gspell` (gedit, Geany ja muut GTK-tekstieditorit), `webkit2gtk-4.1`
(GNOME Web ja muut WebKitGTK-selaimet) sekä `fcitx5` (syöttömenetelmä).
Lisäksi enchantia kutsuvat sovellukset, jotka eivät ole Archin
riippuvuusgraafissa — esimerkiksi Emacsin jinx (kohta 5).

Todennettu:

```
$ enchant-lsmod-2 -list-dicts
fi (voikko)

$ printf 'tarkkailukehä\nzzzqqq\n' | enchant-2 -d fi -l
zzzqqq
```

Toinen komento on varsinainen todiste: `tarkkailukehä` — sana, jota ei ole
missään sanalistassa — hyväksytään, ja `zzzqqq` hylätään. Morfologinen
analyysi on siis oikeasti käytössä, ei pelkkä sanaston nimi listassa.

`enchant-lsmod-2`:n varoitukset puuttuvista `libaspell.so.15`-,
`libhspell.so.0`- ja `libnuspell.so.5`-kirjastoista ovat kosmeettisia, ks.
[arch-vs-debian.md](arch-vs-debian.md) kohta 5.

## 2. Sonnet — KDE- ja Qt-sovellukset

**README väitti aiemmin, että KDE-sovellukset menevät enchantin kautta. Se ei
pidä paikkaansa.** KDE-sovellukset käyttävät KDE:n omaa **Sonnet**-kehystä,
jolla on täysin erillinen taustaosajärjestelmä. `enchant.ordering` ei koske
niitä lainkaan.

Sonnetin taustaosat ovat Qt-liitännäisiä:

```
$ ls /usr/lib/qt6/plugins/kf6/sonnet/
sonnet_aspell.so  sonnet_hspell.so  sonnet_hunspell.so  sonnet_voikko.so

$ pacman -Qo /usr/lib/qt6/plugins/kf6/sonnet/sonnet_voikko.so
/usr/lib/qt6/plugins/kf6/sonnet/sonnet_voikko.so is owned by sonnet 6.29.0-1

$ ldd /usr/lib/qt6/plugins/kf6/sonnet/sonnet_voikko.so | grep voikko
	libvoikko.so.1 => /usr/lib/libvoikko.so.1
```

Voikko-liitännäinen tulee siis **Sonnetin omasta paketista**, ei mistään
erillisestä voikko-paketista, ja se linkittyy suoraan `libvoikko`:on. Kun
`libvoikko` ja `voikko-fi` ovat asennettuina, suomen oikoluku on
KDE-sovelluksissa — Kate, KWrite, KMail, Okular, mikä tahansa Sonnetia
käyttävä Qt-tekstikenttä — päällä ilman mitään konfiguraatiota.

Neljästä liitännäisestä vain kaksi on tällä koneella ladattavissa:

```
$ for p in /usr/lib/qt6/plugins/kf6/sonnet/*.so; do ldd "$p" | grep "not found"; done
	libaspell.so.15 => not found      (sonnet_aspell.so)
	libhspell.so.0 => not found       (sonnet_hspell.so)
```

`sonnet_hunspell.so` ja `sonnet_voikko.so` latautuvat. Sama Archin tapa kuin
enchantissa: liitännäiset paketoidaan, kirjastoja ei.

**Rajoitus:** yhtään Sonnetia käyttävää sovellusta ei ole asennettuna tälle
koneelle (`pacman -Q kate okular kmail` → ei löydy), joten liitännäisen
toiminta on todennettu vain *rakenteellisesti* — paketti, riippuvuus
`libvoikko`:on ja latautuvuus. Oikolukua ei ole ajettu KDE-sovelluksessa.

### Taustaosan pakottaminen Sonnetissa

Sonnetin `Loader::createSpeller()` valitsee taustaosan kolmiportaisesti:
kutsujan nimeämä taustaosa, sitten asetusten `defaultClient` (jos se tukee
pyydettyä kieltä), sitten kielen luotettavimmaksi merkitty taustaosa.

**Tiedosto ja ryhmä.** `defaultClient` tallennetaan
`QSettings(QStringLiteral("KDE"), QStringLiteral("Sonnet"))`-olioon ilman
`beginGroup()`-kutsua (Sonnetin `src/core/settingsimpl.cpp`, `save()` ja
`restore()`). Organisaatio `KDE` + sovellus `Sonnet` tarkoittaa Linuxilla
INI-tiedostoa `~/.config/KDE/Sonnet.conf`, ja koska ryhmää ei aseteta, avaimet
ovat oletusryhmässä `[General]`.

Todennettu tällä koneella kääntämällä kymmenen rivin Qt-ohjelma, joka avaa
täsmälleen saman `QSettings`-olion, kirjoittaa avaimen ja tulostaa
`fileName()`:n (Qt 6.11.2):

```
$ ./qs
/home/kayttaja/.config/KDE/Sonnet.conf

$ cat ~/.config/KDE/Sonnet.conf
[General]
defaultClient=Voikko
```

Muut samassa ryhmässä olevat avaimet: `defaultLanguage`, `preferredLanguages`,
`checkerEnabledByDefault`, `backgroundCheckerEnabled`, `autodetectLanguage`,
`skipRunTogether`.

**Arvo on `Voikko`, iso alkukirjain.** `defaultClient` vertautuu taustaosan
`name()`-metodin palautusarvoon, ja Sonnetin Voikko-liitännäisen
`voikkoclient.cpp` palauttaa

```cpp
QString VoikkoClient::name() const
{
    return QStringLiteral("Voikko");
}
```

Sama literaali on **asennetussa binäärissä**, ei vain upstreamin masterissa
(`QStringLiteral` tallentaa UTF-16:na, joten se ei näy tavallisella
`strings`-ajolla):

```
$ strings -e l /usr/lib/qt6/plugins/kf6/sonnet/sonnet_voikko.so | grep -i voikko
Voikko
Voikko-user-dictionary.json

$ strings -e l /usr/lib/qt6/plugins/kf6/sonnet/sonnet_hunspell.so | grep -i hunspell
hunspell
Hunspell
/usr/share/hunspell/
```

Vertailu on Qt:n `QString`-vertailu, eli **kirjainkoko merkitsee**:
`defaultClient=voikko` pienellä ei osu mihinkään taustaosaan, jolloin Sonnet
ohittaa asetuksen hiljaisesti ja valitsee luotettavimman. Tämä on helppo tehdä
väärin, koska enchantin vastaava arvo *on* pienellä (`fi:voikko`).

**Olennainen ero enchantiin:** `defaultClient` on **globaali, ei
kielikohtainen**. Sillä ei voi valita Voikkoa vain suomelle — se nimeää yhden
taustaosan kaikille kielille, ja Sonnet ohittaa sen niiden kielten kohdalla
joita nimetty taustaosa ei tue. Enchantin `enchant.ordering` on tässä
ilmaisuvoimaisempi: siinä rivi `fi:voikko` koskee vain suomea.

Tätä asetusta **ei tarvita niin kauan kuin Voikko on ainoa suomen tarjoaja**
(ks. varoitus alla); se on kirjattu tähän sitä varten, että sitä joskus
tarvitaan.

*Todentamisen raja:* tiedoston polku, ryhmä ja taustaosan nimi on todennettu
yllä kuvatuilla ajoilla ja lähdekoodista. **Sitä ei ole todennettu, että
KDE-sovellus tottelee asetusta** — yhtään Sonnetia käyttävää sovellusta ei ole
tällä koneella. Lähteet:
<https://invent.kde.org/frameworks/sonnet/-/raw/master/src/core/settingsimpl.cpp>
ja <https://invent.kde.org/frameworks/sonnet/-/raw/master/src/plugins/voikko/voikkoclient.cpp>.

### Sonnetin oma käyttäjäsanasto

Sonnetin Voikko-liitännäinen pitää omaa käyttäjäsanastoaan tiedostossa
`Voikko-user-dictionary.json` hakemiston `Sonnet` alla. Binäärin literaaleista
näkyy myös JSON:in rakenne — avaimet `PersonalWords` ja `Replacements` — ja
lokiviestit `Loaded %1 words from the user dictionary.` sekä `Loaded %1
replacements from the user dictionary.`

Tämä on luettu binäärin merkkijonoista. **Tiedoston lopullista polkua ei ole
todennettu**, koska se ratkeaa `QStandardPaths`-datahakemistosta, joka riippuu
kutsuvasta sovelluksesta.

### Mistä Sonnetin hunspell-liitännäinen etsii sanastoja

`sonnet_hunspell.so`:ssa on kovakoodattu literaali `/usr/share/hunspell/`, ja
sen lisäksi se kokoaa hakupolkuja QStandardPaths-datahakemistoista ja
päätteestä `/hunspell/` — tällä järjestelmällä siis myös
`~/.local/share/hunspell/`. Liitännäisessä on myös Flatpak-tietoinen haara
(`No flatpak hunspell location found`). Tämä on luettu binäärin
merkkijonoista, ei ajettu.

Käytännön seuraus: **myös käyttäjätason** hunspell-sanasto
`~/.local/share/hunspell/`:issa laukaisee kohdan 3 järjestysongelman, ei
pelkkä järjestelmätason asennus.

## 3. Varoitus: järjestys on pakotettava heti kun suomen hunspell-sanasto asennetaan

Tällä koneella ei ole suomen hunspell-sanastoa järjestelmätasolla — koko
hakemistoa ei ole olemassa:

```
$ ls /usr/share/hunspell/
ls: cannot access '/usr/share/hunspell/': No such file or directory
```

`hunspell 1.7.3-1` on asennettu, mutta pelkkänä ohjelmana ilman sanastoja.
Siksi **Voikko on tällä hetkellä ainoa suomen tarjoaja sekä enchantissa että
Sonnetissa**, eikä kummassakaan tarvitse pakottaa järjestystä: kun tarjoajia
on yksi, valintaa ei ole.

**Tämä muuttuu sinä päivänä kun suomen hunspell-sanasto asennetaan
järjestelmänlaajuisesti** — millä tahansa paketilla, joka kirjoittaa polkuun
`/usr/share/hunspell/fi_FI.*`. Repossa on tällainen paketti,
`hunspell-fi-ginter`, mutta **sitä ei julkaista 0.9:ssä juuri tästä syystä**
(ks. `packaging/README.md`). Sen jälkeen
molemmilla kehyksillä on kaksi suomen tarjoajaa, ja kumpikin voi valita
**hunspellin** — eli 88,0 %:n sanalistan Voikon 95,0 %:n morfologian sijasta.
Ero ei näy virheilmoituksena vaan siinä, että `tarkkailukehä` alkaa
alleviivautua.

Silloin järjestys on pakotettava **molemmissa erikseen**:

```bash
# enchant (GTK, gspell, WebKitGTK, fcitx5, jinx)
mkdir -p ~/.config/enchant
printf 'fi:voikko\n' > ~/.config/enchant/enchant.ordering

# Sonnet (KDE/Qt) — huomaa iso V, arvo on kirjainkokoherkkä
mkdir -p ~/.config/KDE
printf '[General]\ndefaultClient=Voikko\n' >> ~/.config/KDE/Sonnet.conf
```

Enchant-rivi on repon `tools/asenna.sh --vain enchant` -osan sisältö.

**Enchant-rivin rajoitus — mitattu 2026-09-16.** Rivi `fi:voikko` tehoaa vain
jos hunspell-sanasto on asennettu nimellä `fi.{aff,dic}`. Archin konventio (ja
repon julkaisematon `hunspell-fi-ginter`) asentaa sen kuitenkin nimellä
`fi_FI`, ja silloin
**mikään `enchant.ordering`-rivi ei tehoa**: Voikko rekisteröityy tunnuksella
`fi`, hunspell tunnuksella `fi_FI`, eivätkä ne kilpaile samasta tunnuksesta.
Kokeillut ja tehottomiksi todetut: `fi_FI:voikko`, `fi_FI:voikko,hunspell`,
`*:voikko`. Ainoa tapa palauttaa Voikko tunnukselle `fi_FI` on poistaa
hunspell-sanasto. Täysi mittaustaulukko: [../README.md](../README.md), kohta
*Järjestystä ei tarvitse pakottaa — toistaiseksi*.

Kaksi varausta Sonnet-riviin. Ensinnäkin `>>` lisää rivin tiedoston loppuun;
jos tiedostossa on jo `[General]`-lohko tai `defaultClient`-rivi, **tarkista ja
korjaa tiedosto käsin** äläkä aja komentoa sokeasti. Toiseksi: polku, ryhmä ja
arvo on todennettu yllä kuvatulla tavalla, mutta **asetusta ei ole testattu
oikeassa KDE-sovelluksessa**, koska sellaista ei ole tällä koneella.

## 4. voikkogc — kielentarkistus komentoriviltä

`voikkospell` tarkistaa sanoja, `voikkohyphenate` tavuttaa — ja **`voikkogc`
tarkistaa kieliopin**. Se on ainoa tapa ajaa suomen kielentarkistusta
putkessa, esimerkiksi skriptissä tai CI:ssä. Se tulee samasta paketista kuin
kaksi muuta (`/usr/bin/voikkogc`).

Oletuksena `descr`-kenttä on tyhjä; selitykset saa lisäämällä
`explanation_language=fi`. Ajettu 2026-09-16:

```
$ printf 'Kissa joka istui matolla oli musta.\n' | voikkogc explanation_language=fi
[code=18, level=0, descr="", stpos=11, len=17, suggs={}] (Virkkeestä saattaa puuttua pilkku, tai siinä voi olla ylimääräinen verbi.)
-

$ printf 'Koira istui matolla ja se oli hyvä koira\n' | voikkogc explanation_language=fi
[code=9, level=0, descr="", stpos=35, len=5, suggs={}] (Välimerkki puuttuu virkkeen lopusta.)
-

$ printf 'Tämä on erittäin erittäin hyvä juttu.\n' | voikkogc explanation_language=fi
[code=8, level=0, descr="", stpos=8, len=17, suggs={"erittäin"}] (Sana on kirjoitettu kahteen kertaan.)
-
```

`stpos` ja `len` ovat virheen alkukohta ja pituus merkkeinä, `suggs`
korjausehdotukset. Viimeinen rivi `-` on kappaleen loppumerkki; virheetön
kappale tuottaa pelkän `-`:n.

**`voikkogc` ei tarkista oikeinkirjoitusta**, vain kielioppia:

```
$ printf 'Tämä on maastopyöräilyz.\n' | voikkogc explanation_language=fi
-
```

Kirjoitusvirhe menee läpi. Oikoluku on `voikkospell`in työtä; nämä kaksi ovat
eri tarkistuksia, ja molemmat tarvitaan.

Hyödyllisiä lisävalitsimia (`man voikkogc`): `--tokenize` ja
`--split-sentences` pilkkovat syötteen, `-n` etuliittää rivinumeron.

## 5. Emacs — jinx

[jinx](https://github.com/minad/jinx) kutsuu **enchantin C-API:a suoraan**
Emacsin dynaamisesta moduulista. Se saa siis Voikon samaa reittiä kuin
GTK-sovellukset, ilman erillistä konfiguraatiota: jos `enchant-lsmod-2
-list-dicts` näyttää `fi (voikko)`, jinx näyttää sen myös.

jinxin oma README dokumentoi tämän eksplisiittisesti:

> Enchant uses Hunspell as default backend for most languages. For English
> Enchant prefers Aspell and for Finnish and Turkish special backends called
> Voikko and Zemberek are used.

Sama README neuvoo myös `~/.config/enchant/enchant.ordering`-tiedoston
käytön, eli kohdan 3 varoitus koskee jinxiä sellaisenaan.

Kielen valinta on muuttujassa `jinx-languages` (`"fi"` tai esimerkiksi
`"fi en_US"`, jolloin molemmat kelpaavat samassa puskurissa). Vaatimukset:
Emacs dynaamisten moduulien tuella, C-kääntäjä ja `libenchant`-kehityspaketti
— moduuli käännetään ensimmäisellä käynnistyksellä.

jinx on käytännössä ainoa tapa saada Emacsiin Voikon tasoinen suomen
oikoluku: `ispell.el` puhuu aspellille tai hunspellille eikä osaa Voikkoa.

**Ei todennettu tällä koneella** — Emacsia ei ole asennettu. Enchant-puolen
osuus (kohta 1) on todennettu, jinxin oma osuus perustuu sen dokumentaatioon.

## 6. Firefox ja Thunderbird — sama `.xpi`

`build/fi-spell-0.2.xpi` kelpaa **molempiin**. Ginterin oma README sanoo sen
suoraan:

> The .xpi extension file is a regular zip file which includes the hunspell
> dictionaries (fi_FI.dic and fi_FI.aff). The extension can be directly
> installed to Thunderbird and Firefox.

Paketin `manifest.json` tukee tätä: siinä ei ole `strict_min_version`- eikä
`strict_max_version`-rajoja eikä sovelluskohtaisia lohkoja, vain
`applications.gecko.id` ja `dictionaries`-avain:

```json
{
  "applications": { "gecko": { "id": "fi@dictionaries.addons.mozilla.org" } },
  "manifest_version": 2,
  "name": "Finnish Spell Dictionary",
  "description": "Very quick effort",
  "version": "0.2",
  "author": "Filip Ginter",
  "dictionaries": { "fi": "dictionaries/fi_FI/fi_FI.dic" }
}
```

Sanastolaajennukset eivät tarvitse Mozillan allekirjoitusta, joten asennus
onnistuu myös julkaisuversioihin. **Todennettu 2026-09-16** Firefox 155.0.1:llä
(`AppConstants.MOZ_UPDATE_CHANNEL == "release"`, Archin branded-paketti), ja
kahdella tavalla:

*Lähteestä.* Firefoxin oma `mustSign()` palauttaa `false` heti, jos lisäosan
tyyppi ei ole allekirjoitusta vaativien joukossa, ja joukko ei sisällä
sanastoja:

```
$ unzip -p /usr/lib/firefox/omni.ja modules/addons/XPIDatabase.sys.mjs \
    | grep -n 'SIGNED_TYPES = '
161:const SIGNED_TYPES = new Set(["extension", "locale", "theme"]);
```

`dictionaries`-avaimen sisältävä manifest saa tyypin `dictionary`
(`XPIProvider.sys.mjs`, `webextension-dictionary` → `dictionary`), joka ei ole
joukossa.

*Ajamalla.* `AddonManager.getInstallForFile()` samalla paketilla puhtaaseen
profiiliin — sama koodipolku kuin valikon *Asenna lisäosa tiedostosta* —
päättyi tilaan `ended`, ei `failed`:

```
{ "firefox": "155.0.1", "channel": "release", "result": "ended",
  "id": "fi@dictionaries.addons.mozilla.org", "type": "dictionary",
  "signedState": null, "appDisabled": false, "isActive": true }
```

`signedState: null` kertoo, ettei allekirjoitusta tarkistettu lainkaan, eikä
`appDisabled` mennyt päälle. Uudelleenkäynnistyksen jälkeen sanasto myös
rekisteröityi oikoluvulle (`mozISpellCheckingEngine.getDictionaryList()` →
`["fi", "en-US"]`), ja tarkistus toimi odotetusti: `kissanruoka` ja
`pyöräillä` hyväksyttiin, `kissanrooka` ja `pyorailla` hylättiin.

Huomaa, että rekisteröityminen oikolukumoottorille kestää käynnistyksen
jälkeen muutaman sekunnin; heti asennuksen jälkeen kysytty sanastolista ei
vielä sisällä `fi`:tä.

- **Firefox:** `about:addons` → rataskuvake → *Asenna lisäosa tiedostosta*.
- **Thunderbird:** Asetukset (☰) → *Lisäosat ja teemat* → rataskuvake →
  *Install Add-on From File…*. Mozillan ohje kuvaa painikkeen sijainnin
  *"a button to the left of the search box"*; vaihtoehtoisesti `.xpi`-tiedoston
  voi raahata suoraan lisäosien hallintavälilehdelle.
  <https://support.mozilla.org/en-US/kb/installing-addon-thunderbird>

**Asennus ei yksin riitä — kieli on valittava.** Firefox ei valitse sanastoa
sen perusteella, mikä on asennettu, vaan kentän tai sivun kielestä ja
`spellchecker.dictionary`-asetuksesta. Tuoreessa profiilissa asetus on tyhjä,
jolloin suomenkielinen teksti tarkistetaan englannin sanastolla eikä lisäosasta
näytä olevan mitään hyötyä. Napsauta tekstikenttää **oikealla painikkeella**,
varmista että *Tarkista oikeinkirjoitus* on rastitettu, ja valitse sitten
*Kielet* → **suomi**. Valinta jää muistiin ja koskee jatkossa kaikkia kenttiä.
Saman voi tehdä `about:config`-sivulla asettamalla `spellchecker.dictionary`
arvoon `fi`.

Toimivuuden voi tarkistaa ilman verkkoyhteyttä avaamalla
[../tools/oikoluku-testi.html](../tools/oikoluku-testi.html) selaimeen. Sivun
neljä tekstikenttää on koottu repon `tools/testisanat.txt`-listasta ja
tarkistettu `hunspell -d dict/ginter/fi_FI -l`:llä, joten odotettu tulos on
mitattu eikä arvattu.

Tämä oli 0.9:n kehityksessä ensimmäinen asia, joka näytti rikkinäiseltä
paketilta muttei ollut: lisäosa oli `active`, `appDisabled: false` ja
`startupData.dictionaries` kunnossa, mutta `spellchecker.dictionary` oli
asettamatta eikä mikään alleviivautunut.

### Monta profiilia — sanasto ilman lisäosaa

Lisäosa menee profiilin sisään. Monen profiilin koneella se tarkoittaa
`about:addons`-käsityötä joka profiilille ja purettuna noin 15 Mt kopion
sanastosta jokaiseen. Chromiumissa vastaavaa ongelmaa ei ole, koska siellä
`Dictionaries/` on käyttäjädatahakemiston tasolla ja siis jaettu.

Firefoxilla on kuitenkin toinen reitti: pref `spellchecker.dictionary_path`
osoittaa hakemistoon, josta hunspell-sanastot luetaan. **Mitattu 2026-09-17**
Firefox 155.0.1:llä ajamalla selain headless-tilassa Marionette-protokollalla
(`--marionette -remote-allow-system-access`) ja kysymällä chrome-kontekstissa
`mozISpellCheckingEngine.getDictionaryList()`. Sivun oikolukutuloksia ei voi
kysyä JS:stä, joten tämä on ainoa tapa todentaa lataus ilman ihmissilmää.

| Reitti | Sanastolista tuoreessa profiilissa |
|---|---|
| lähtötila, ei mitään | `["en-US"]` |
| `spellchecker.dictionary_path` → jaettu hakemisto | `["en-US", "fi-FI"]` |
| `<profiili>/dictionaries/` | `["en-US"]` |

**Profiilin oma `dictionaries/`-hakemisto ei siis toimi** — Firefox ei lue
sitä, toisin kuin voisi olettaa siitä että lisäosan sisällä sanasto on juuri
`dictionaries/`-hakemistossa. Negatiivinen tulos on tässä yhtä hyödyllinen
kuin positiivinen: se sulkee pois ilmeiseltä näyttävän ratkaisun.

Työkalu tekee molemmat vaiheet:

```bash
tools/firefox-ota-kayttoon.sh --kaikki-profiilit
```

Se kopioi `dict/ginter/fi_FI.{aff,dic}`:n jaettuun hakemistoon ja kirjoittaa
kunkin profiilin `prefs.js`:ään kaksi prefiä. Firefoxin on oltava suljettuna,
sillä se kirjoittaa `prefs.js`:n uudelleen lopettaessaan.

Kolme yksityiskohtaa, joihin toteutus kompastuu jos niitä ei tiedä:

**1. Tunniste on eri kuin lisäosalla.** Lisäosan `manifest.json` ilmoittaa
sanaston avaimella `"fi"`, ja se rekisteröityy sillä nimellä. Tätä reittiä
tunnus tulee tiedostonimestä `fi_FI`, ja moottori näkee sen nimellä `fi-FI`.
`spellchecker.dictionary` on siis asetettava eri arvoon riippuen siitä, kumpi
reitti on käytössä. Molemmat voivat olla yhtä aikaa käytössä samassa
profiilissa — todennettu, lista oli silloin `["fi", "en-US", "fi-FI"]`.

**2. Jaettu hakemisto ei saa olla `/usr/share/hunspell` eikä
`~/.local/share/hunspell`.** Prefin oletusarvo on nimenomaan
`/usr/share/hunspell`, joten sinne vietynä sanasto näkyisi kaikille
profiileille ilman mitään profiilikohtaista kirjoitusta — mutta enchant
haravoi saman polun, ja `fi_FI`-tunnus syrjäyttäisi siellä Voikon GTK-
sovelluksissa. Ks. kohta 3 alla. Työkalun oletuspolku on siksi
`~/.local/share/suomen-kieliavut/hunspell`, jota vain Firefox katsoo.

**3. Profiileja ei voi etsiä `profiles.ini`:stä.** Firefoxin uusi
profiilivalitsin tallentaa profiilit tietokantaan
`Profile Groups/<id>.sqlite`, eivätkä ne näy `profiles.ini`:ssä lainkaan:
tällä koneella juuri luotu profiili puuttui sieltä, vaikka oli levyllä.
Työkalu etsii profiilit levyltä `prefs.js`:n olemassaolon perusteella.
Sivutuotteena ohittuvat profiilit, joita ei ole koskaan käynnistetty — niissä
ei ole `prefs.js`:ää, koska Firefox luo sen vasta ensimmäisellä
käynnistyksellä.

Huomaa myös, että profiilijuuri voi olla kahdessa paikassa: uusi XDG-sijainti
`~/.config/mozilla/firefox` tai vanha `~/.mozilla/firefox`. Työkalu tunnistaa
kumman tahansa.

**Thunderbirdin polkua ei ole todennettu tällä koneella** — Thunderbirdiä ei
ole asennettu. Kuvaus on Mozillan dokumentaatiosta ja Ginterin README:stä.
Kattavuus on joka tapauksessa sama 88,0 % kuin Firefoxissa, koska sanasto on
sama tiedosto.

## 7. Vim ja Neovim — sama `.spl`

`build/fi.utf-8.spl` kelpaa molempiin. Muoto on yhteinen, ja tiedoston otsake
kertoo version:

```
$ od -A d -c -N 16 build/fi.utf-8.spl
0000000   V   I   M   s   p   e   l   l   2 001 001  \0  \0 001 203 200
```

Kahdeksan ensimmäistä tavua ovat taikamerkkijono `VIMspell`, ja seuraava tavu
on versionumero: `0x32` = 50. Vimin lähdekoodin `src/spellfile.c` määrittelee

```c
#define VIMSPELLMAGIC "VIMspell"  // string at start of Vim spell file
#define VIMSPELLMAGICL 8
#define VIMSPELLVERSION 50
```

(Tarkistettu upstreamista 2026-09-16:
<https://github.com/vim/vim/blob/master/src/spellfile.c>.) Vim hylkää
tiedoston, jonka versiotavu on suurempi kuin sen oma `VIMSPELLVERSION`; 50 on
nykyisen Vimin arvo, joten tiedosto kelpaa. Asennus:

```bash
install -Dm644 build/fi.utf-8.spl ~/.vim/spell/fi.utf-8.spl     # Vim
install -Dm644 build/fi.utf-8.spl ~/.config/nvim/spell/fi.utf-8.spl  # Neovim
```

```vim
:set spelllang=fi
:set spell
```

**Vimiä itseään ei ole asennettu tälle koneelle** (`/usr/bin/vim` puuttuu,
`vim` on alias `nvim`:iin), joten yhteensopivuus on todennettu muodon
version kautta, ei ajamalla. Neovim on todennettu ajamalla, ks. alla.

### Mitä Neovim käytännössä osaa — mitattu 2026-09-16

Neovim lukee `.spl`-tiedostoa, ei Voikkoa. Se on siis hunspell-maailman
**88,0 %**, ei Voikon 95,0 %. Ero näkyy heti. Ajettu puhtaalla
konfiguraatiolla (`nvim --clean --headless`, NVIM v0.12.5, `spelllang=fi`,
pelkkä `build/fi.utf-8.spl` runtimepathissa, tarkistus `vim.fn.spellbadword()`):

| Sana | Tulos |
|---|---|
| `maastopyöräily` | ok |
| `sähköposti` | ok |
| `maastopyöräilyz` | bad *(oikein — tämä on virhe)* |
| `tarkkailukehä` | **bad** |
| `koronarokote` | **bad** |
| `kirjoittaisimmekohan` | **bad** |

Kolme alinta ovat täysin kelvollisia suomen sanoja. `tarkkailukehä` on README:n
oma esimerkki kelvollisesta yhdyssanasta, ja se alleviivautuu Neovimissa —
tämä on syytä tietää etukäteen, ettei aleta etsiä asennusvirhettä. Tulokset
vastaavat [sanastot.md](sanastot.md):n 13 sanan taulukkoa Ginterin sarakkeessa.

`zg` lisää oman sanan tiedostoon `~/.config/nvim/spell/fi.utf-8.add`, joka on
tavallista tekstiä ja jonka voi ottaa mukaan konemigraatiossa.

### Parannuspolku, jota ei ole toteutettu

Periaatteessa Voikon saisi Neovimiin diagnostiikkalähteenä
[efm-langserverin](https://github.com/mattn/efm-langserver) kautta: se käärii
mielivaltaisen komentorivityökalun LSP-palvelimeksi, ja `voikkospell` tuottaa
rivi riviltä jäsennettävää tulostetta.

**Tätä ei ole toteutettu eikä testattu, eikä tämä ole ohje.** Se on kirjattu
tähän, koska vaihtoehtoa kysytään väistämättä. Tarkistettu 2026-09-16: **valmista
Voikko-LSP-palvelinta ei ole olemassa** — ei Voikko-projektilla eikä
kolmansilla. Neovimin suomen oikoluvun ainoat valmiit vaihtoehdot ovat tämä
`.spl` ja LanguageToolin `ltex-ls`, joka ei käytä Voikkoa.

## 8. Flatpak ja Snap — hiekkalaatikko ei näe järjestelmän kieliapuja

Flatpak-sovellus ajetaan omassa ympäristössään, joka ei sisällä järjestelmän
`/usr/share/hunspell`- eikä `/usr/share/myspell`-hakemistoa. Flatpakin
runtimessa ei myöskään ole `libvoikko`:a, joten **Voikko-liitännäiset eivät
toimi Flatpak-LibreOfficessa lainkaan** — liitännäinen on Python-koodia, joka
`dlopen`aa kirjaston jota siellä ei ole. Sama koskee Snapin tiukkaa
confinementia.

Flatpakilla on tähän oma mekanisminsa: runtimen `.Locale`-laajennukset, joita
ohjataan komennolla

```bash
flatpak config languages --set "fi;en"
sudo flatpak update
```

Se tuo runtimeen sen *omat* sanastot, ei järjestelmän eikä Voikkoa.

Lähteet:

- <https://www.ctrl.blog/entry/flatpak-locale-dictionaries.html> — miksi
  Flatpak-sovellus ei näe järjestelmän sanastoja ja mitä `flatpak config
  languages` tekee.
- <https://github.com/flathub/org.libreoffice.LibreOffice/issues/62> — sama
  ongelma Flathubin LibreOfficessa. **Huom:** tämä issue koskee *unkaria*,
  ei suomea eikä Voikkoa; se on lähde mekanismille, ei suomen tilanteelle.

**Kumpaakaan ei ole todennettu tällä koneella:** `flatpak` ja `snap` eivät ole
asennettuina. Yllä oleva on dokumentaatiosta ja mekanismin rakenteesta
johdettua.

Repon ratkaisu on LibreOfficen **`.oxt`-sanastolaajennus**
(`tools/build-oxt.sh` → `build/fi-hunspell-<versio>.oxt`). Se on puhdasta
hunspell-dataa ilman natiivikoodia ja asentuu LibreOfficen omaan
laajennushakemistoon **hiekkalaatikon sisälle**, joten sen **pitäisi** toimia myös
Flatpak- ja Snap-LibreOfficessa. **Tätä ei ole todennettu** — `.oxt` on
testattu vain natiivilla LibreOffice 26.8:lla, eikä koneella ole Flatpakia
eikä Snapia. Flatpak on koko `.oxt`:n olemassaolon pääperuste, joten tämä on
0.9:n merkittävin todentamaton väite. Hinta on tuttu: 88,0 % Voikon 95,0 %:n
sijaan, eikä kielentarkistusta.

```bash
tools/build-oxt.sh 0.9 ginter              # -> build/fi-hunspell-0.9.oxt
unopkg add build/fi-hunspell-0.9.oxt       # käyttäjäkohtainen, ei sudoa
unopkg remove fi.hunspell.suomen-kieliavut # poisto
```

Todennettu 2026-09-16 LibreOffice 26.8:lla. Pelkkä `unopkg list` → `is
registered: yes` **ei riitä todisteeksi**: väärä `Locales`-arvo (`fi_FI`
alaviivalla oikean `fi-FI`:n sijaan) rekisteröityy näennäisesti mutta ei
koskaan löydy oikoluvusta. Siksi todennus tehtiin UNO-rajapinnan kautta
suoraan `org.openoffice.lingu.MySpellSpellChecker`-palvelulta, jolloin
Voikko-liitännäinen ei voi vääristää tulosta:

| | ennen asennusta | asennuksen jälkeen |
|---|---|---|
| `hasLocale(fi-FI)` | False | True |
| `isValid('mäki')` | — | True |
| `isValid('mäkki')` | — | False |

**Skriptattaessa älä kirjoita `unopkg list | grep -q ...`.** `grep -q` sulkee
putken ensimmäiseen osumaan, `unopkg` kuolee SIGPIPEen ennen kuin ehtii poistaa
lukkotiedostonsa `~/.config/libreoffice/4/.lock`, ja kuollut lukko estää kaikki
myöhemmät `unopkg`-ajot — myös käyttäjän omat. Todettu tässä repossa
2026-09-16. Lue ulostulo ensin muuttujaan.

## 9. Yhteenveto

| Sovellus | Mekanismi | Moottori | Kattavuus | Todennettu |
|---|---|---|---|---|
| LibreOffice (natiivi) | UNO-liitännäinen → `libvoikko` | Voikko | 95,0 % | kyllä, `unopkg list` |
| LibreOffice (Flatpak/Snap) | `.oxt`-sanastolaajennus | hunspell | 88,0 % | **ei — ks. kohta 8** |
| gedit, Geany, GNOME Web | enchant | Voikko | 95,0 % | kyllä, `enchant-2 -d fi` |
| Emacs + jinx | enchant | Voikko | 95,0 % | osittain (enchant kyllä, jinx ei) |
| Kate, KMail, Okular, Qt-kentät | Sonnet | Voikko | 95,0 % | rakenteellisesti |
| Firefox | oma hunspell | Ginter `.xpi` | 88,0 % | kyllä, Firefox 155.0.1 (release) |
| Thunderbird | oma hunspell | sama `.xpi` | 88,0 % | ei |
| Chromium, Electron | oma hunspell | Ginter karsittu `.bdic` | 76,4 % | lataus kyllä |
| Vim | oma hunspell | Ginter `.spl` | 88,0 % | muodon versio |
| Neovim | oma hunspell | Ginter `.spl` | 88,0 % | kyllä, mitattu |
| komentorivi | `libvoikko` | Voikko | 95,0 % | kyllä |

Kattavuusluvut ovat [sanastot.md](sanastot.md):n korpusmittauksesta ja
koskevat uniikkeja sanoja (types). Esiintymillä painotettuna erot ovat
pienempiä: Voikko 97,6 %, Ginter kokonaan 95,9 %, Ginter karsittu 92,0 %.
