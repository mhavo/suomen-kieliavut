# Hardening Notes

**Mikä tämä tiedosto on:** kirjanpito siitä, mitä eri kielimalleilla ajetut
auditoinnit ovat tästä reposta löytäneet ja mitä niille on päätetty tehdä.

Repoa on tarkastutettu useammalla mallilla, ja ne löytävät osittain samat
asiat kerta toisensa jälkeen. Kaikki löydökset eivät ole korjauksen arvoisia:
osa on aitoja huolia, jotka eivät vain kuulu tähän julkaisuun, ja osa on
vääriä hälytyksiä tai jo katettuja asioita. Korjatut löydökset ovat gitin
historiassa eivätkä täällä. **Tänne kirjataan ne, joita ei korjattu — ja
miksi.**

Tiedostolla on siis kaksi tehtävää:

1. **Vaimentaa toistuvaa auditointikohinaa.** Jos seuraava malli nostaa
   saman löydöksen uudelleen, vastaus on jo kirjattu tänne. Lue tämä ennen
   kuin ryhdyt korjaamaan "uutta" löydöstä.
2. **Säilyttää kovennusideat**, jotka ovat oikeasti hyviä mutta kuuluvat
   myöhempään versioon, laukaisimineen: mikä tapahtuma tekee niistä
   ajankohtaisia.

Muotosääntö: **yksi rivi per kenttä** ja pysyvä otsikko, jotta merkintä on
löydettävissä uudelleen. Jos merkintä vaatii kappaleen, se kuuluu README:hen
tai LICENSES.md:hen, ei tänne.

Lähde, ellei toisin mainita: Codex-auditointi 2026-09-16, luokiteltu Realism
Hat -konventiolla (repon ulkopuolinen työtapa, ei julkaistu täällä).

## Siirretyt kovennusideat

Aitoja huolia, joihin voi olla syytä palata, mutta jotka eivät kuulu 0.9:ään.

### Negatiivinen virhekorpus (precision / false positive)

- Huoli: kattavuusmittaus mittaa vain oikein kirjoitettujen sanojen hyväksyntää, ei väärien hylkäämistä — erittäin salliva sanasto näyttäisi tässä erinomaiselta.
- Miksei nyt: vaatii kuratoidun virhekorpuksen (kirjoitusvirheet, taivutusvirheet, yhdyssanavirheet), joka on oma projektinsa; 0.9 ei väitä mittaavansa laatua, vain kattavuutta.
- Tuleva laukaisin: ennen kuin sanastoa verrataan Voikkoon tai kilpailijoihin laatuväitteellä, tai ennen AMO-vientiä.
- Pienin tuleva korjaus: ~500 tunnetun kirjoitusvirheen lista `tools/korpus/virheet.txt` ja false-positive-aste samaan taulukkoon kattavuuden rinnalle.

### Korjausehdotusten laadun mittaus

- Huoli: `hunspell -a` -ehdotusten osuvuutta ei mitata lainkaan, vaikka se on käyttäjän kokema oikolukulaatu.
- Miksei nyt: edellyttää yllä olevaa virhekorpusta ja oikeiden korjausten annotointia.
- Tuleva laukaisin: kun virhekorpus on olemassa.
- Pienin tuleva korjaus: mittaa kuinka usein oikea korjaus on viiden ensimmäisen ehdotuksen joukossa.

### Poistoskripti, asennusmanifesti ja --dry-run

- Huoli: asennus koskee useita selainprofiileja, LibreOffice-laajennuksia, Neovimia ja mahdollisesti `/usr/share`-hakemistoa ilman yhtenäistä peruutusta; AUR-paketin poisto ei poista profiiliin kopioituja tiedostoja.
- Miksei nyt: 0.9 dokumentoi poiston käsin (README, "Poistaminen"); automatisoitu manifesti on oma suunnittelutehtävänsä.
- Tuleva laukaisin: ensimmäinen käyttäjäraportti epäonnistuneesta tai epätäydellisestä poistosta, tai kun asennin alkaa kirjoittaa uusiin kohteisiin.
- Pienin tuleva korjaus: `install.sh` kirjaa jokaisen kohteen `~/.local/state/suomen-kieliavut/asennetut.txt`:hen, `tools/poista.sh` lukee sen.

### Chromiumin bdic-tiedostonimen regressiotesti

- Huoli: `fi-3-0.bdic` on kovakoodattu nimi, jonka Chromium-päivitys voi vaihtaa ja rikkoa oikoluvun hiljaisesti.
- Miksei nyt: vaatii selainversiomatriisin CI:hin; nimen johtaminen ajossa on jo `tools/chromium-sanastonimi.sh`:ssä.
- Tuleva laukaisin: ensimmäinen havaittu hiljainen rikkoutuminen Chromium-päivityksessä.
- Pienin tuleva korjaus: asennin varoittaa, jos johdettu nimi eroaa kopioidusta, sen sijaan että olettaa nimen.

### Testaamattomat integraatiot: Electron-Flatpak, Sonnet, Neovim

- Huoli: näitä polkuja ei ole ajettu oikeassa sovelluksessa.
- Miksei nyt: eivät ole projektin ydinarvolupaus (se on Firefox, Chromium ja LibreOffice); README merkitsee ne testaamattomiksi.
- Tuleva laukaisin: käyttäjäkysyntä tai ensimmäinen bugiraportti.
- Pienin tuleva korjaus: yksi manuaalinen testi per polku ja rivin siirto README:n testaustaulukossa.

### CI-matriisi useammalle distrolle ja sovellukselle

- Huoli: asenninta testataan vain yhdessä ympäristössä.
- Miksei nyt: 1.0:n vaatimus; 0.9:n rima on yksi päästä päähän -ajo kontissa ja rehellinen testaustaulukko.
- Tuleva laukaisin: 1.0-tavoite, tai toinen ylläpitäjä.
- Pienin tuleva korjaus: matriisi Arch + Debian-kontille pelkälle `install.sh`:lle, ei sovelluksille.

### CC0-ketjun vahvistus upstreamilta

- Huoli: Ginter-aineiston CC0-tulkintaa ei ole vahvistettu tekijältä. **Huomaa mikä tässä on jo selvää:** lisenssimerkintä on olemassa ja eksplisiittinen — upstreamin README sanoo `# License` / `CC0` (tarkistettu 2026-09-16). Jäljellä oleva huoli koskee vain Voikko-suodatuksen tulkintaa ja puuttuvaa `LICENSE`-tiedostoa. Älä nosta tätä uudelleen muodossa "lisenssiä ei ole sanottu".
- Miksei nyt: jo dokumentoitu rajattuna avoimena kysymyksenä `LICENSES.md`:ssä, ja seuraus on jo rajattu — AMO-vientiä ei tehdä ennen vastausta.
- Tuleva laukaisin: vastaus upstreamilta, tai AMO-/laajemman jakelun suunnittelu.
- Pienin tuleva korjaus: linkitä vastaus `LICENSES.md`:ään ja poista avoin kysymys -laatikko.

## Hylätyt / jo katetut väitteet

Löydöksiä, jotka ovat ylimitoitettuja, jo katettuja tai tuotteen rajojen
ulkopuolella. Nämä merkinnät ovat olemassa lähinnä vaimentamaan toistuvaa
auditointikohinaa.

### AUR-paketteja ei saa julkaista ennen CI-matriisia

- Väite: AUR-paketit on pidätettävä kunnes ne on rakennettu CI:n distromatriisissa.
- Hylkäysperuste: väärä rima väärälle kanavalle — AUR on nimenomaan lähdepakettien ja kokeellisten pakettien jakelutie, ja sen oma laatuvaatimus on puhdas chroot-rakennus, ei ylläpitäjän CI.
- Olemassa oleva takuu: `makepkg -C` puhtaassa chrootissa + `namcap`, `pkgver=0.9`, kuvauksessa kokeellinen tila.
- Älä nosta uudelleen ellei: AUR-paketti hajoa oikealla käyttäjällä tavalla, jonka chroot-rakennus olisi napannut.

### curl | bash on hylättävä ensisijaisena asennustapana

- Väite: `curl | bash` on kelvoton käyttöliittymä projektille, joka muokkaa selainprofiileja ja voi kutsua sudoa.
- Hylkäysperuste: tämä on tuotepäätös, ei virhe; varsinainen löydös oli tarkistussummien liian vahva turvallisuusväite, ja se on korjattu sanamuotona.
- Olemassa oleva takuu: README kertoo mitä summat suojaavat ja mitä eivät, ja tarjoaa lataa-tarkista-aja-polun vaihtoehtona.
- Älä nosta uudelleen ellei: asennin ala tehdä jotain, jota lataa-tarkista-aja-polku ei paljasta lukemalla.

### "Idempotentti ei tarkoita turvallisesti peruttavaa"

- Väite: erillinen löydös siitä, että idempotenssi esitetään turvallisuustakuuna.
- Hylkäysperuste: sama asia kuin puuttuva poistopolku, ei itsenäinen vaatimus; kirjattu kerran yllä.
- Olemassa oleva takuu: README:n poisto-ohje ja siirretty merkintä "Poistoskripti, asennusmanifesti ja --dry-run".
- Älä nosta uudelleen ellei: README ala esittää idempotenssia peruutettavuutena.

### Versionumeroksi on valittava 0.9 eikä 1.0

- Väite: projektia ei saa julkaista 1.0:na.
- Hylkäysperuste: ei löydös vaan jo tehty päätös — `install.sh` on koko ajan sanonut `v0.9`. Todellinen löydös oli versionumeroiden epäjohdonmukaisuus dokumentaatiossa, ja se on korjattu.
- Olemassa oleva takuu: `JULKAISU_TAGI="v0.9"`, ja tarkistus.yml vertaa install.sh:n summat SHA256SUMS:iin.
- Älä nosta uudelleen ellei: dokumentaatioon ilmesty uusi versionumero, joka ei vastaa `JULKAISU_TAGI`-arvoa.

### OXT on rakennettava uudelleen karsitusta sanastosta

- Väite: OXT:n pitäisi sisältää `dict/ginter-karsittu/`, kuten LICENSES.md väitti.
- Hylkäysperuste: karsinta on `.bdic`-muodon kokorajoitus, ei lisenssikriteeri — molemmat variantit ovat CC0-1.0, joten koko sanasto OXT:ssä on perusteltu valinta eikä lisenssiongelma. Löydös oli dokumentaatiovirhe, ja taulukko on korjattu vastaamaan tiedostoa.
- Olemassa oleva takuu: `LICENSES.md`:n `build/`-taulukko, `tools/tarkista-oxt.py` ja `SHA256SUMS`.
- Älä nosta uudelleen ellei: `.oxt` ja `.bdic` ala poiketa toisistaan tavalla, joka näkyy käyttäjälle eri oikolukutuloksena samassa tekstissä.
