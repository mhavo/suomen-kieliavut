# AUR-paketit

Tämän repon sanastot Arch-paketteina, jotta suomen kieliavut olisivat
`yay -S`:n päässä eivätkä `pacman -Qo`:lle orpoja tiedostoja.

Aukko on todellinen. AUR:ssa ei ole lainkaan `hunspell-fi`-pakettia, eikä
Arch paketoi suomen tavutuskuvioita missään muodossa: `hyphen`-paketissa on
vain kirjasto, ei kuvioita (`pacman -Ql hyphen`). Käsin kopioitu
`/usr/share/hyphen/hyph_fi_FI.dic` jää omistajattomaksi — tällä koneella
`pacman -Qo /usr/share/hyphen` vastaa `No package owns`. Nämä paketit
korjaavat sen.

**Voikkoa nämä eivät korvaa.** `voikko-fi` ja `voikko-libreoffice` ovat jo
AUR:ssa, ja ne ovat edelleen se mitä työpöytäsovelluksiin kannattaa asentaa.
Älä duplikoi niitä. Nämä paketit ovat hunspell-reittiä varten: selaimet ja
Neovim eivät osaa Voikkoa, eikä siihen ole näköpiirissä muutosta.

---

## Paketit

| Paketti | Asentaa | Lisenssi |
|---|---|---|
| `hyphen-fi` | `/usr/share/hyphen/hyph_fi_FI.dic` | `LicenseRef-fihyph` |
| `chromium-dict-fi` | `/usr/share/chromium-dict-fi/fi-3-0.bdic` ja `/usr/share/qt6/qtwebengine_dictionaries/fi.bdic` | CC0-1.0 |
| `nvim-spell-fi` | `/usr/share/nvim/site/spell/fi.utf-8.spl` | CC0-1.0 |

Neljäs paketti, `hunspell-fi-ginter`, **ei kuulu 0.9-julkaisuun**. Sen koodi
on tallessa hakemistossa `packaging/ei-julkaista-hunspell-fi-ginter/`
nimenomaan `packaging/aur/`:n ulkopuolella, jottei se lähde AUR:iin
vahingossa. Perustelu on alla luvussa "Kaksi taustaosaa".

Kaikki `arch=('any')`, `pkgver=0.9`, eikä yhdessäkään ole `build()`-vaihetta:
binäärit on rakennettu etukäteen `tools/`-skripteillä ja ne toimitetaan
julkaisun liitetiedostoina. Rakennusohjeet ovat
[docs/convert-dict.md](../docs/convert-dict.md):ssä ja
[docs/sanastot.md](../docs/sanastot.md):ssä.

### `hunspell-fi-ginter` — ei julkaista 0.9:ssä

Ginterin koko sanasto, 476 291 sanuetta, `/usr/share/hunspell/fi_FI.*`:iin.

**Miksi tämä jää julkaisematta.** Se on repon ainoa komponentti, jolla on
globaali, ei-konfiguroitava haittavaikutus. Asennettuna se vie enchantilta
tunnuksen `fi_FI`, jolloin työpöydän oikoluku vaihtuu Voikosta tähän
sanalistaan **kaikissa** `fi_FI`-tunnusta pyytävissä sovelluksissa.
`enchant.ordering` ei auta — mitattu, ks. luku "Kaksi taustaosaa" — ja ainoa
peruutuskeino on paketin poisto.

Sen ainoa hyöty on hunspell-reitin LibreOffice, ja se katetaan jo
`.oxt`-paketilla, joka on opt-in eikä kosketa järjestelmän
enchant-tunnusavaruutta.

Paketti varasi lisäksi AUR:sta nimen `hunspell-fi` (`provides`/`conflicts`).
Julkaisematon paketti ei saa varata nimeä, joten kentät on poistettu.

Jos paketti joskus julkaistaan, se tarvitsee vähintään (a) eri nimen ilman
`hunspell-fi`-varausta ja (b) `.install`-viestin, joka kertoo haitan **ennen**
asennusta eikä sen jälkeen.

### `hyphen-fi`

Sama nimi kuin Debianissa tarkoituksella: Debianin `hyphen-fi` toimittaa
saman tiedoston samaan polkuun.

Lisenssi ei ole SPDX-listalla. Aineiston ainoa käyttöehto on alkuperäisen
README:n rivi *"Patterns may be freely distributed"*, joten tunniste on
Archin ohjeen (RFC 0016) mukaisesti `LicenseRef-`-etuliitteinen ja
lisenssiteksti toimitetaan kokonaisuudessaan polkuun
`/usr/share/licenses/hyphen-fi/README_hyph_fi_FI.txt`.

**Jos olet ajanut `tools/asenna.sh`:n**, `/usr/share/hyphen/hyph_fi_FI.dic`
on jo levyllä eikä minkään paketin omistama. Pacman kieltäytyy silloin
asentamasta pakettia virheellä `exists in filesystem`. Poista tiedosto ensin
käsin.

### `chromium-dict-fi`

Kaksi asennuspolkua, koska kyse on kahdesta eri moottorista:

- **QtWebEngine lukee sanaston järjestelmästä.** Polku
  `/usr/share/qt6/qtwebengine_dictionaries/` on todennettu kahdesti:
  `libQt6WebEngineCore.so` sisältää merkkijonot `qtwebengine_dictionaries` ja
  `QTWEBENGINE_DICTIONARIES_PATH`, ja `hunspell-en_us` asentaa juuri sinne.
  Tämä osa toimii ilman käyttäjän toimia.
- **Chromium ei lue sanastoa järjestelmästä lainkaan.** Se avaa yhden tietyn
  tiedoston profiilistaan (`~/.config/chromium/Dictionaries/fi-3-0.bdic`), ja
  kieli on lisäksi merkittävä oikoluettavaksi `Preferences`-tiedostoon selain
  suljettuna. Kumpaakaan ei voi tehdä pakettiskriptistä: pacman ajaa
  asennuksen roottina eikä tiedä käyttäjistä mitään. Paketti toimittaa siksi
  tiedoston **valmiiksi oikealla nimellä** hakemistoon
  `/usr/share/chromium-dict-fi/`, jolloin käyttöönotto on yksi
  kopiointikomento, ja `.install` kertoo loput.

Tiedostonimi `fi-3-0.bdic` on mitattu Chromiumin verkkolokista, ei arvattu,
ja se on kielikohtainen. Ks. [docs/convert-dict.md](../docs/convert-dict.md).

### `nvim-spell-fi`

Varsinainen tiedosto menee `/usr/share/nvim/site/spell/`:iin, joka on
Neovimin oma järjestelmänlaajuinen lisäyshakemisto ja oletusarvoisesti
`runtimepath`issa (todennettu `nvim --clean`:llä).

Lisäksi asennetaan symlinkki `/usr/share/nvim/runtime/spell/`:iin. Syy on
mitattu: lazy.nvim-pohjaiset kokoonpanot (LazyVim) kirjoittavat
`runtimepath`in uusiksi, ja `/usr/share/nvim/site` katoaa siitä kokonaan —
`/usr/share/nvim/runtime` (`$VIMRUNTIME`) ei. Ilman symlinkkiä paketti ei
toimisi merkittävälle osalle käyttäjistä.

Paketti asentaa **vain** polkuun `/usr/share/nvim/site/spell/`. Aiempi versio
teki lisäksi symlinkin `/usr/share/nvim/runtime/spell/`:iin, joka on
`neovim`-paketin omistama hakemisto; se on poistettu. Toisen paketin
hakemistoon kirjoittamisesta huomautetaan AUR-katselmuksessa, ja symlinkki
rikkoutuisi tiedostoristiriitana sinä päivänä, kun Neovim alkaa toimittaa
oman `fi.utf-8.spl`:nsä.

Seuraus: kokoonpanoissa, jotka nollaavat `runtimepath`in (esim. LazyVim),
käyttäjän on lisättävä polku itse tai kopioitava tiedosto
`~/.config/nvim/spell/`:iin. Ohje on paketin `.install`-viestissä.

---

## Kaksi taustaosaa — mitä `hunspell-fi-ginter` rikkoo

Repon README toteaa, että suomelle ei tarvita `enchant.ordering`-tiedostoa,
koska Voikko on ainoa suomen tarjoaja. `hunspell-fi-ginter` lopettaa sen.

Mitattu tällä koneella (enchant 2.8.21, `enchant-lsmod-2`,
`ENCHANT_CONFIG_DIR`-eristyksellä):

| Tilanne | `-lang fi` | `-lang fi_FI` |
|---|---|---|
| vain Voikko | `fi (voikko)` | `fi (voikko)` |
| + hunspell `fi_FI.{aff,dic}` | `fi (voikko)` | **`fi_FI (hunspell)`** |

Sanasto rekisteröityy tunnuksella `fi_FI`, Voikko tunnuksella `fi`. Sovellus,
joka pyytää kieltä nimellä `fi_FI` — esimerkiksi lokaalista `fi_FI.UTF-8` —
saa siis tästedes hunspellin.

**`enchant.ordering` ei korjaa tätä.** Kokeillut rivit `fi_FI:voikko`,
`fi_FI:voikko,hunspell` ja `*:voikko` antavat kaikki edelleen
`fi_FI (hunspell)`. Syy: Voikko ei tarjoa tunnusta `fi_FI` täsmällisesti vaan
vain tunnuksen `fi`, ja järjestystiedosto vaikuttaa vasta täsmäävien
tarjoajien kesken. Ordering-tiedosto auttaa vain suoraan törmäykseen — rivi
`fi:hunspell` todella siirtää tunnuksen `fi` hunspellille, jos joku asentaa
`/usr/share/hunspell/fi.{aff,dic}`. Sitä nimeä nämä paketit eivät käytä.

Ainoa varma tapa palauttaa Voikko tunnukselle `fi_FI` on poistaa
`hunspell-fi-ginter`. Jos tarvitset hunspell-sanastoa vain selaimiin ja
Neovimiin, asenna `chromium-dict-fi` ja `nvim-spell-fi` — ne eivät koske
enchantiin lainkaan.

**KDE / Sonnet.** Sonnet valitsee kielelle sen liitännäisen, jonka
`reliability()` on suurin. Upstreamin arvot ovat Voikko 50 ja Hunspell 40,
joten Voikon pitäisi voittaa ilman mitään konfiguraatiota silloin kun
molemmat tarjoavat saman kielitunnuksen. Jos pakotusta tarvitaan, asetus on
`QSettings("KDE", "Sonnet")` eli tiedosto `~/.config/KDE/Sonnet.conf`:

```ini
[General]
defaultClient=Voikko
```

Avaimet `defaultClient`, `defaultLanguage` ja `preferredLanguages` löytyvät
`libKF6SonnetCore.so`:n merkkijonoista, samoin organisaationimi `KDE` ja
sovellusnimi `Sonnet`. Avaimet ovat ryhmässä `[General]`, koska Sonnet ei
kutsu `beginGroup()`:ia.

Asetus on **globaali eikä kielikohtainen**, toisin kuin enchantin
`fi:voikko`. Se ei silti riko muita kieliä. `Loader::createSpeller()`
tarkistaa, tukeeko oletustaustaosa pyydettyä kieltä, ja jos ei, nollaa
valinnan:

```cpp
backend = d->settings->defaultClient();
if (!backend.isEmpty()) {
    bool unknown = !std::any_of(lClients.constBegin(), lClients.constEnd(), ...);
    if (unknown) {
        qCWarning(SONNET_LOG_CORE) << "Default client" << backend
                                   << "doesn't support language:" << plang;
        backend = QString();
    }
}
```

Englanti jatkaa siis hunspellilla. Hinta on lokimeteli: jokaisesta muun
kielen tarkistuksesta tulee yllä oleva varoitus. Asetusta ei kannata tehdä
varmuuden vuoksi — Sonnet suosii Voikkoa suomelle jo oletuksena.

Koko Sonnet-osuus on luettu kirjastosta ja upstreamin lähdekoodista. **Sitä
ei ole todennettu ajamalla KDE-sovelluksella.**

---

## Ennen AUR:iin lähettämistä

**Neljä asiaa on tehtävä järjestyksessä. Kohta 1 on tehty 2026-09-18**, joten
`source`-kentät ovat noudettavissa ja työ jatkuu kohdasta 2.

### 1. Julkaise repo ja tee release — TEHTY

Tagi `v0.9`, sama kuin `pkgver` jokaisessa PKGBUILD:issä ja
`JULKAISU_TAGI` `install.sh`:ssa. Tagin työntäminen ajaa
`.github/workflows/julkaisu.yml`:n, joka liittää tiedostot automaattisesti —
mutta vasta sen jälkeen kun koko `tarkistus.yml` on mennyt läpi samasta
committista.

Release on osoitteessa
<https://github.com/mhavo/suomen-kieliavut/releases/tag/v0.9> ja sisältää
alla luetellut liitetiedostot.

AUR-pakettien kannalta releasessa on oltava seuraavat tiedostot **täsmälleen
näillä nimillä** — PKGBUILDit nimeävät ne latauksen yhteydessä uudelleen,
mutta lähdenimen on täsmättävä:

| Liitetiedosto | Repossa |
|---|---|
| `fi_FI.aff` | `dict/ginter/fi_FI.aff` |
| `fi_FI.dic` | `dict/ginter/fi_FI.dic` |
| `hyph_fi_FI.dic` | `dict/hyphen/hyph_fi_FI.dic` |
| `README_hyph_fi_FI.txt` | `dict/hyphen/README_hyph_fi_FI.txt` |
| `fi-FI.bdic` | `build/fi-FI.bdic` |
| `fi.utf-8.spl` | `build/fi.utf-8.spl` |

Release sisältää lisäksi `fi-spell-0.2.xpi`:n, `fi-hunspell-0.9.oxt`:n,
`SHA256SUMS-release.txt`:n ja `LICENSES.md`:n, joita AUR-paketit eivät käytä.

### 2. Rakenna puhtaassa chrootissa ja aja namcap

Tämä on AUR:n oma laatuvaatimus eikä se ole valinnainen: `makepkg -si`
kehityskoneella ei paljasta puuttuvia riippuvuuksia, koska ne ovat jo
asennettuina. Vasta kun release on olemassa (kohta 1), lähteet ovat
noudettavissa:

```bash
pacman -S --needed devtools namcap
cd packaging/aur/hyphen-fi
makechrootpkg -c -r /var/lib/archbuild/extra-x86_64   # tai: extra-x86_64-build
namcap PKGBUILD ./*.pkg.tar.zst
```

Toista jokaiselle kolmelle paketille. `namcap`in on oltava puhdas tai
huomautukset perusteltuja ennen lähetystä.

### 3. Tarkista lataus-URL:t

Omistaja on kirjoitettu paketteihin valmiiksi. Jokaisessa PKGBUILD:issä on rivi

```bash
_baseurl="https://github.com/mhavo/suomen-kieliavut/releases/download/v$pkgver"
```

ja `url=`-kentässä sama osoite ilman `releases`-osaa. Jos repo siirtyy toiselle
omistajalle, molemmat on vaihdettava — ja `.SRCINFO` regeneroitava kohdan 4
mukaan, koska URL on myös siellä:

```bash
sed -i 's|github.com/mhavo/|github.com/<uusi>/|g' packaging/aur/*/PKGBUILD
```

### 4. Päivitä summat ja `.SRCINFO`

`sha256sums` on jo kirjoitettu oikeiksi repon nykyisistä tiedostoista
(`SHA256SUMS`), eikä yhdessäkään paketissa lue `SKIP`. Perustelu: nämä ovat
muuttumattomia tietotiedostoja versioidun julkaisun takana, ja sanasto on
juuri se osa, jota käyttäjä ei lue läpi — `SKIP` tarkoittaisi, että
julkaisuomaisuuden vaihtaminen jäisi huomaamatta.

Summia ei siis tarvitse muuttaa, jos liitteet ovat bitilleen samat. Tarkista
se ensin:

```bash
sha256sum -c SHA256SUMS
```

Jos julkaiset uudet binäärit, laske summat uudestaan jokaisessa
pakettihakemistossa:

```bash
cd packaging/aur/<paketti>
updpkgsums          # noutaa lähteet ja kirjoittaa sha256sums-kentän
makepkg --printsrcinfo > .SRCINFO
```

`.SRCINFO` on **aina** generoitava komennolla, ei käsin. Se on pakollinen
AUR:iin lähettäessä ja se on päivitettävä jokaisen PKGBUILD-muutoksen
jälkeen — myös URL-muutoksen jälkeen, koska osoite on myös `.SRCINFO`:ssa.

### Lähetysjärjestys

Paketit ovat toisistaan riippumattomia. Lähetä:

1. `hyphen-fi` — pienin, riippumaton, täyttää selvimmän aukon (Arch ei
   paketoi suomen tavutuskuvioita lainkaan). Tämä on repon ainoa riidaton
   paketti: se ei muuta minkään sovelluksen oikolukua, aineisto on
   muuttumaton ja lisenssiketju siisti.
2. `nvim-spell-fi` — riippumaton
3. `chromium-dict-fi` — riippumaton

`hunspell-fi-ginter` ei lähde 0.9:ssä lainkaan, ks. yllä.

**Ennen jokaista lähetystä** `makepkg` on ajettava oikeaa julkaisua vasten.
Tähän asti vain `package()`-funktiot on ajettu käsin; lähdetiedostojen nouto
ja summantarkistus ovat todentamatta, koska julkaisua ei ollut.

Kukin AUR-repo erikseen:

```bash
git clone ssh://aur@aur.archlinux.org/<paketti>.git
cp packaging/aur/<paketti>/{PKGBUILD,.SRCINFO} <paketti>/
cp packaging/aur/<paketti>/<paketti>.install <paketti>/   # jos on
cd <paketti> && git add -A && git commit && git push
```

`.install`-tiedosto on lisättävä git-repoon, tai `makepkg` kaatuu
puuttuvaan tiedostoon.

---

## Testaus ilman julkaistua releasea

`makepkg` ei voi rakentaa paketteja ennen kuin lähde-URL toimii. Ilman
verkkoa voi silti tarkistaa kaiken muun:

```bash
cd packaging/aur/<paketti>
bash -n PKGBUILD
makepkg --printsrcinfo > /dev/null
shellcheck -s bash -e SC2148,SC2034,SC2154 PKGBUILD
```

Poissuljetut shellcheck-säännöt eivät ole vaientamista vaan seuraus siitä,
ettei PKGBUILD ole ajettava skripti: ei shebangia (SC2148), muuttujat
asetetaan makepkg:n luettaviksi eikä käytettäviksi (SC2034), ja
`$srcdir`/`$pkgdir` tulevat makepkg:ltä (SC2154).

`package()`-funktion voi ajaa käsin väliaikaiseen juureen repon paikallisilla
tiedostoilla — se paljastaa polkuvirheet ilman verkkoa. Huomaa, että
`/usr/share/myspell/dicts/`- ja `/usr/share/nvim/runtime/spell/`-symlinkit
ovat absoluuttisia eivätkä siksi aukea testijuuressa; se on oikein, ne
osoittavat lopulliseen `/usr`-polkuun.
