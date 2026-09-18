# Chromium-oikolukusanaston (`.bdic`) kääntäminen

Chromium ei lue hunspellin `.aff`/`.dic`-pareja suoraan. Se käyttää omaa
binäärimuotoaan `.bdic`, joka on käännettävä hunspell-lähteistä Chromiumin
omalla `convert_dict`-työkalulla.

Suomea ei ole Chromen tuettujen oikolukukielten listassa, joten Google ei
toimita valmista `fi.bdic`:tä eikä selain lataa sellaista koskaan itse. Tämä
käännös on ainoa tapa saada suomen oikoluku Chromiumiin, Chromeen, Braveen,
Edgeen ja kaikkiin Electron-sovelluksiin.

## Miksi tämä on hankalaa

`convert_dict` elää Chromiumin lähdepuussa polussa `chrome/tools/convert_dict`.
Sen kääntäminen tarkoittaa periaatteessa koko Chromiumin noutamista
(`depot_tools`, `fetch chromium`, ~100 GB ja tunteja käännösaikaa) — kohtuuton
hinta yhdestä pienestä apuohjelmasta.

Kiertotie: **jankelemen/convert-dict-tool-from-chromium** julkaisee valmiiksi
käännetyn `convert_dict`-binäärin ja sen tarvitsemat jaetut kirjastot
(`libbase.so`, `libicuuc.so`, `libicui18n.so`, `libc++.so`, `libabsl.so`,
`libboringssl.so`, `libperfetto.so`, `libchrome_zlib.so`, `libbase_i18n.so`) sekä
ICU:n datatiedoston `icudtl.dat`. Yhteensä noin 153 MB, minkä takia niitä ei
säilytetä tässä repossa vaan `tools/build-bdic.sh` noutaa ne ajohetkellä.

## Vaiheet

### 1. Nouda työkalu

```bash
git clone https://github.com/jankelemen/convert-dict-tool-from-chromium.git
cd convert-dict-tool-from-chromium
chmod +x convert_dict
```

### 2. Aseta kolme lähdetiedostoa paikalleen

Kaikkien kolmen on oltava **samassa hakemistossa** ja **samannimisiä**:

```
fi-FI.dic         hunspell-sanasto
fi-FI.aff         hunspell-affiksisäännöt
fi-FI.dic_delta   lisäykset (pakollinen, saa olla lähes tyhjä)
```

`.dic_delta` on Chromiumin oma lisä: siihen kirjataan sanat, jotka lisätään
sanastoon käännösvaiheessa ilman että alkuperäistä `.dic`:tä muokataan. Yksi
sana per rivi, sama syntaksi kuin `.dic`:ssä (`sana` tai `sana/LIPUT`).
Tiedoston on oltava olemassa, mutta yhden sanan sisältö riittää — tämän repon
`dict/ginter/fi_FI.dic_delta` sisältää yhden rivin `tarkkailukehä`.

Huomaa myös **merkistö**: `.aff`-tiedoston ensimmäinen `SET`-rivi kertoo
koodauksen, ja `convert_dict` luottaa siihen. `dict/ginter/` on `SET UTF-8`,
`dict/myspell-fi-0.7/` on `SET ISO8859-1`. Väärä `SET`-rivi tuottaa hiljaisesti
sanaston, jossa ääkköset ovat rikki — ei virheilmoitusta.

### 3. Käännä

```bash
LD_LIBRARY_PATH=. ./convert_dict fi-FI
```

Argumentti on tiedostojen **perusnimi ilman päätettä**. Työhakemiston on
oltava sama kuin binäärien, tai `LD_LIBRARY_PATH` osoitettava niihin —
`icudtl.dat` etsitään työhakemistosta.

Tuloksena syntyy `fi-FI.bdic`.

### 4. Asenna

```bash
install -Dm644 fi-FI.bdic ~/.config/chromium/Dictionaries/fi-3-0.bdic
```

### Tiedoston nimi on kriittinen — mitattu 2026-09-16

Chromium avaa **vain yhden tietyn tiedostonimen** muotoa
`<kielikoodi>-<sanastoversio>.bdic`. Kaikki muut nimet samassa hakemistossa
ohitetaan täysin, ilman virheilmoitusta ja ilman lokiriviä.

Kaksi asiaa menee helposti väärin:

**1. Kielikoodi on `fi`, ei `fi-FI`.** Vaikka lähdetiedostot ovat `fi-FI.aff`
ja `fi-FI.dic` ja `convert_dict`-argumentti on `fi-FI`, Chromium etsii
sanastoa asetuksissa valitun kielen koodilla — suomella se on `fi`.

**2. Sanastoversio on kielikohtainen eikä sitä voi päätellä.** Se ei ole
tiedostomuodon versio vaan Googlen ylläpitämä sanaston *sisällön* versio, ja
jokaisella kielellä on omansa:

| Kieli | Tiedostonimi |
|---|---|
| englanti (US) | `en-US-10-1.bdic` |
| **suomi** | **`fi-3-0.bdic`** |

Englannin `10-1`:stä ei siis voi päätellä suomen `3-0`:aa. Numero on
kovakoodattu Chromiumin lähdekoodiin ja voi muuttua päivityksissä.

### Miten oikean nimen saa selville

Ajamalla Chromiumin kertakäyttöisellä profiililla, jossa suomen oikoluku on
päällä mutta sanastoa ei ole. Chromium yrittää silloin hakea puuttuvan
tiedoston Googlelta, ja verkkolokista näkee tarkan nimen:

```
NetworkDelegate::NotifyBeforeURLRequest:
  https://redirector.gvt1.com/edgedl/chrome/dict/fi-3-0.bdic
```

Lataus epäonnistuu 404:ään — Google ei tosiaan toimita suomen sanastoa,
vaikka se on varannut sille versionumeron. Tämä on tässä sivuseikka: haluttu
tieto on pelkkä tiedostonimi.

Skripti hoitaa tämän: **`tools/chromium-sanastonimi.sh`**.

### Pelkkä tiedosto ei riitä — eikä asetusta voi tehdä käyttöliittymästä

Sanasto avataan vasta kun kieli on `spellcheck.dictionaries`-listassa. Tarkista
profiilin asetuksista:

```bash
python3 -c "import json;print(json.load(open('$HOME/.config/chromium/Default/Preferences'))['spellcheck'])"
```

Jos tuloste on `{'dictionaries': ['en-US'], 'dictionary': ''}`, suomi ei ole
päällä eikä `.bdic`-tiedostoa avata lainkaan, oli se miten oikein nimetty
tahansa.

**Tätä ei voi korjata `chrome://settings/languages`:sta.** Suomi ei ole
Chromiumin tuettujen oikolukukielten listassa (`kSupportedSpellCheckerLanguages`
lähdepuussa), joten asetussivu ei tarjoa suomelle *Tarkista tämän kielen
oikeinkirjoitus* -valintaa lainkaan. Kieli näkyy kielilistassa, mutta
oikolukurastia sille ei ole.

Asetus kirjoitetaan siis suoraan `Preferences`-tiedostoon, selain suljettuna:

```bash
tools/chromium-ota-kayttoon.sh
```

Sanaston **lataus** toimii tämän jälkeen normaalisti, vaikka kieli ei olekaan
tuettujen listalla — se lista ohjaa vain käyttöliittymää, ei latauskoodia.

### Todiste että sanasto oikeasti ladataan — mitattu 2026-09-16

Kolme ajoa kertakäyttöprofiililla, `spellcheck.dictionaries: ["fi"]`:

| `fi-3-0.bdic` | Latausyrityksiä | Tiedoston tila |
|---|---|---|
| eheä | 0 | säilyi (8 625 850 tavua) |
| tarkoituksella rikottu | 2 | **poistettu** |
| puuttuu | 3 | — |

Chromium siis avaa tiedoston, tarkistaa sen sisäisen tarkistussumman, ja
hylkää sen jos summa ei täsmää. Eheä sanasto kelpaa eikä latausta yritetä.
Asetus myös säilyy profiilissa uudelleenkäynnistyksen yli.

### Varoitus: `-3-0` ei kerro tuesta

Versiopääte `-3-0` on Chromiumin **oletusarvo**, ei todiste siitä että kieltä
tuettaisiin. Sama kysely millä tahansa kielikoodilla tuottaa saman muodon:

```
fi -> fi-3-0.bdic      ja -> ja-3-0.bdic
th -> th-3-0.bdic      zz -> zz-3-0.bdic      (zz ei ole olemassa)
```

Vain harvoilla kielillä on oma versionumero (`en-US-10-1`, `en-GB-8-0`,
`tr-4-0`, `tg-5-0`). Tiedostonimen selvittäminen `tools/chromium-sanastonimi.sh`
-skriptillä on siis oikein, mutta pyynnön olemassaolosta ei saa päätellä että
Chromium tukisi kieltä käyttöliittymässä.

Tämä on se kahden virheen yhdistelmä, jonka takia asennus näyttää onnistuvan
mutta oikoluku ei toimi.

Tiedostomuodon oma versio on eri asia ja näkyy otsakkeessa:

```
$ od -A d -t x1z -N 8 fi-FI.bdic
0000000 42 44 69 63 02 00 00 00  >BDic....<
```

`BDic` + little-endian `2`. Tämä on pysynyt samana vuosia.

### 5. Ota käyttöön selaimessa

**Ei asetussivulta.** `chrome://settings/languages` ei tarjoa suomelle
*Tarkista tämän kielen oikeinkirjoitus* -valintaa lainkaan, koska suomi ei ole
Chromiumin tuettujen oikolukukielten listalla — ks. yllä kohta *Pelkkä
tiedosto ei riitä*.
Kieli näkyy kielilistassa, mutta rastia sille ei ole.

Asetus kirjoitetaan siis `Preferences`-tiedostoon selain **kokonaan
suljettuna**:

```bash
tools/chromium-ota-kayttoon.sh
```

Käynnistä selain uudelleen ja testaa: `maastopyörä` ei saa alleviivautua,
`maastopyöräz` pitää. Jos kumpikaan ei alleviivaudu, oikoluku ei ole päällä;
jos molemmat alleviivautuvat, sanastotiedoston nimi on väärä tai tiedosto on
korruptoitunut — Chromium ei kerro kummasta on kyse.

## Muodon raja — mitattu 2026-09-09

**Ginterin koko sanasto (476 291 sanuetta) ei mahdu `.bdic`-muotoon.**
`convert_dict` lukee sen, serialisoi, ja kaatuu vasta tarkistusvaiheessa:

```
Reading fi-FI.aff ...
Reading fi-FI.dic ...
Serializing...
Verifying...
Found the end before we expected
ERROR converting, the dictionary does not check out OK.
```

Raja etsittiin binäärihaulla. Se **ei ole pelkkä sanuemäärä** vaan
serialisoidun trien koko, joten se riippuu siitä mitkä sanat valitaan:

| Valinta | Suurin kääntyvä | Tuloksen koko |
|---|---|---|
| Aakkosellinen alkupää (`head -n`) | ~319 500 sanuetta | ~9,1 MB |
| Hajanainen valinta koko sanastosta | ~248 400 sanuetta | ~8,6 MB |

Hajanainen valinta täyttää muodon nopeammin, koska se tuottaa enemmän
erillisiä etuliitehaaroja trieen. Samalla sanuemäärällä lopputulos on siis
joko kelvollinen tai ei sen mukaan, mitkä sanat siihen otettiin — mikä tekee
virheestä hämmentävän.

Testi, jolla tämän voi toistaa: `tools/build-bdic.sh raja`.

Tarkistettu myös, ettei syy ole affiksisäännöstössä: Ginterin `.aff`:issa on
45 991 uniikkia affiksiryhmää (`FLAG num`) kun myspell-fi 0.7:ssä niitä on
23, mutta sama `.aff` kääntyy ongelmitta pienemmän `.dic`:n kanssa.

## Miten Ginterin sanasto saadaan mahtumaan

Sanastoa on karsittava. Karsintaperuste ratkaisee sekä lopputuloksen laadun
**että lisenssin** — jos peruste katsoo GPL-lisensoitua aineistoa, tulos on
siitä johdettu teos. Molemmat perusteet on mitattu samalla korpuksella kuin
[sanastot.md](sanastot.md) (62 641 uniikkia sanaa, UD Finnish-TDT +
fi-Wikipedia; `tools/arvioi-korpuksella.sh`, pituusvalinta
`tools/build-bdic.sh valinta pituus`):

| Karsinta | Hylkyjä / 62 641 | Kattavuus | Lisenssi |
|---|---|---|---|
| **Frekvenssi** — sanan esiintymistiheys vapaassa korpuksessa, tasapelit pituudella | **14 774** | **76,4 %** | puhdas |
| Pelkkä sananpituus | 17 746 | 71,7 % | puhdas |
| *(vertailuksi: koko Ginter, ei käänny)* | 7 493 | 88,0 % | — |
| *(vertailuksi: myspell-fi 0.7 sellaisenaan)* | 32 993 | 47,3 % | GPL-2.0-only |

**Frekvenssi voittaa, ja se on myös ainoa oikea valinta lisenssin kannalta.**

Kriteeri ei saa katsoa myspell-fi 0.7:n sanalistaa: se on GPL-2.0-only, ja
jos valinta on sen kuratoima, tulos on siitä johdettu teos eikä CC0-1.0.
Ks. [`LICENSES.md`](../LICENSES.md).

Frekvenssilista on `tools/korpus-frekvenssit.txt`, laskettu **eri**
fi-Wikipedia-otoksesta kuin arviointikorpus: karsintaa ei saa optimoida sitä
korpusta vasten, jolla tulos mitataan. Huomaa että Ginterin `.dic` on
aakkosjärjestyksessä, joten rivinumero ei ole frekvenssisija — frekvenssi on
laskettava erikseen.

Frekvenssilista kattaa 19 700 Ginterin 451 389 sanueesta, eli valinta on
käytännössä "frekvenssikärki + pituusjärjestyksessä täytetty häntä". Listan
kasvattaminen isommalla korpusotoksella on ilmeisin tapa parantaa tulosta
edelleen.

Jos frekvenssitiedosto puuttuu, `tools/build-bdic.sh pituus` rakentaa saman
sanaston pelkällä pituuskriteerillä. Se maksaa 5,1 prosenttiyksikköä mutta
ei tarvitse mitään ulkoista aineistoa.

Tämä on repon `build/fi-FI.bdic`. Toistettavissa bitilleen:
`tools/build-bdic.sh frekvenssi`.

Karsittu lähdelista on säilytetty hakemistossa `dict/ginter-karsittu/`.

## Kaksi virhettä ja mitä ne tarkoittavat

**`Found the end before we expected`** — sanasto ylittää muodon rajan.
Pienennä sanuemäärää: `N=200000 tools/build-bdic.sh frekvenssi`.

**`Index doesn't match, word #Teemu`** — `.dic` on väärässä järjestyksessä.
`convert_dict` vertaa rakentamaansa trietä syötteeseen sen omassa
järjestyksessä, joten rivejä **ei saa lajitella uudelleen**. Jos valitset
sanastosta osajoukon, tulosta valitut rivit alkuperäisessä järjestyksessään.
Tämä on helppo tehdä väärin, koska `sort` on luonteva refleksi ja virheilmoitus
osoittaa satunnaiseen sanaan keskellä sanastoa.

Kumpikaan virhe ei tuota `.bdic`-tiedostoa lainkaan, joten epäonnistumista ei
voi ohittaa vahingossa.

## Electron-sovellukset

Sama tiedosto kelpaa sellaisenaan mihin tahansa Electron-sovellukseen; vain
hakemisto vaihtuu:

```bash
for d in ~/.config/*/Dictionaries; do
  [ -d "$d" ] && install -m644 fi-FI.bdic "$d/fi-3-0.bdic"
done
```

Sanastoversio seuraa sovelluksen Electron-version mukana olevaa Chromiumia,
joten vanha Electron voi odottaa eri nimeä kuin työpöydän Chromium.

Sovelluksen on silti pyydettävä suomea `session.setSpellCheckerLanguages()`illa,
joten tämä ei toimi kaikkialla.

## Varapolku jos upstream katoaa

`convert_dict` on osa Chromiumia eikä sitä poisteta sieltä. Jos
jankelemenin repo häviää, työkalun voi kääntää itse:

```bash
gclient / depot_tools -> fetch --no-history chromium
gn gen out/Default
ninja -C out/Default convert_dict
```

Vaihtoehtoisesti jokin toinen distro paketoi sen — Fedorassa työkalu on
löytynyt `hunspell`-ekosysteemin ympäriltä, mutta Archissa ei ole pakettia.

## Lähteet

- Chromiumin oma kuvaus sanastotiedostoista:
  https://www.chromium.org/developers/how-tos/editing-the-spell-checking-dictionaries
- Esikäännetty työkalu: https://github.com/jankelemen/convert-dict-tool-from-chromium
- `convert_dict` lähdekoodi: `chrome/tools/convert_dict/` Chromiumin puussa
