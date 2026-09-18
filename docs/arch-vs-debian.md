# Arch vs. Debian/Ubuntu — mikä on eri

Suomen kieliavut on paketoitu Archissa ja Debianissa eri tavoin, ja ero on
suurempi kuin pelkkä paketin nimi. Nämä ovat ne kohdat, joihin Ubuntu-ohje
kaatuu Archissa ja päinvastoin. Vahvistettu tällä koneella 2026-09-09
(Omarchy/Arch, LibreOffice 26.8) ja vanhalla asennuksella (Ubuntu).

## 1. Pakettien nimet ja määrä

| Tarkoitus | Debian/Ubuntu | Arch |
|---|---|---|
| Kirjasto | `libvoikko1` | `extra/libvoikko` |
| Suomen morfologia | `voikko-fi` | `aur/voikko-fi` |
| LibreOffice-liitännäinen | `libreoffice-voikko` | `aur/voikko-libreoffice` |
| enchant-taustaosa | `libenchant-2-voikko` | *sisältyy pakettiin* `extra/enchant` |
| Python-sidonnat | `python3-libvoikko` | *sisältyvät pakettiin* `extra/libvoikko` |
| Komentorivityökalut | `libvoikko-dev` | *sisältyvät pakettiin* `extra/libvoikko` |
| Tavutuskuviot | `hyphen-fi` | **ei ole** |

Kaksi asiaa kannattaa panna merkille:

- **Nimi on käännetty toisin päin.** Debianissa `libreoffice-voikko`,
  AUR:ssa `voikko-libreoffice`. Kumpikin paketoi saman upstream-julkaisun
  5.0 vuodelta 2015.
- **Arch niputtaa, Debian pilkkoo.** `enchant_voikko.so` ja
  `libvoikko.py` tulevat Archissa ilman erillistä pakettia; Debianissa ne
  ovat omiaan. Ubuntu-ohjeen `apt install ... libenchant-2-voikko
  python3-libvoikko` ei siis käänny AUR-paketeiksi yksi yhteen.
- **`voikkospell` ei ole kehitystyökalu, vaikka Debianissa siltä näyttää.**
  Komennot `voikkospell`, `voikkohyphenate` ja `voikkogc` ovat upstreamissa osa
  libvoikkoa, ja [viralliset käännösohjeet][voikko-src] varmistavat asennuksen
  juuri komennolla `voikkospell -d fi`. Arch pitää ne paketissa `libvoikko`;
  Debian siirtää ne `libvoikko-dev`:iin headerien ja staattisen kirjaston
  seuraksi. Tarkistettu Debian trixien tiedostolistasta 2026-09-18. Siksi
  `libvoikko-dev` on Debian-rivillä mukana.

[voikko-src]: https://voikko.puimula.org/source-linux.html

Arch:
```bash
yay -S voikko-fi voikko-libreoffice
```
Debian/Ubuntu:
```bash
apt install voikko-fi libreoffice-voikko libenchant-2-voikko \
            python3-libvoikko libvoikko-dev hyphen-fi
```

## 2. Morfologian polku

| | |
|---|---|
| Arch | `/usr/share/voikko/5/mor-standard/` |
| Debian | `/usr/lib/voikko/5/mor-standard/` |

Sisältö on sama (`mor.vfst`, `autocorr.vfst`, `index.txt`), mutta
`/usr/share` vs. `/usr/lib` eroaa. libvoikko etsii molemmista, joten tämä ei
riko mitään — mutta jos kopioit aineistoa distrosta toiseen käsin tai
kirjoitat skriptin, joka olettaa polun, se hajoaa hiljaisesti.

## 3. LibreOffice-laajennuksen asennustapa

Tämä on merkittävin ero, ja se on hiljainen.

**Debian** asentaa laajennuksen *purettuna hakemistona* polkuun
`/usr/lib/libreoffice/share/extensions/voikko/`. LibreOffice lataa sen
automaattisesti — mitään rekisteröintiä ei tarvita, ja se kestää
LibreOfficen päivitykset.

**Arch** asentaa vain paketin `voikko.oxt` polkuun
`/usr/lib/libreoffice/share/extensions/install/` ja rekisteröi sen
`post_install`-skriptillä:

```bash
/usr/lib/libreoffice/program/unopkg add --shared \
    /usr/lib/libreoffice/share/extensions/install/voikko.oxt
```

Rekisteröinnin tulos päätyy hakemistoon
`/usr/lib/libreoffice/share/uno_packages/cache/uno_packages/lu*.tmp_/`, joka
**ei ole minkään paketin omistama** — `pacman -Qo` löytää sieltä vain kolme
hakemistoa, jotka kuuluvat `libreoffice-fresh`ille, ei itse laajennusta.

Käytännön seuraus: `voikko-libreoffice`-paketin skriptit ajetaan vain kun
*sitä* pakettia asennetaan tai päivitetään. Jos LibreOffice päivittyy ja
purkaa uno-välimuistin, Voikko katoaa kirjoitusapuvälineistä ilman
virheilmoitusta. Korjaus:

```bash
yay -S --rebuild voikko-libreoffice     # tai
sudo /usr/lib/libreoffice/program/unopkg add --shared \
     /usr/lib/libreoffice/share/extensions/install/voikko.oxt
```

Tarkistus kummassakin distrossa:

```bash
$ unopkg list --shared
Identifier: org.puimula.ooovoikko
  Version: 5.0
  is registered: yes
```

AUR-paketin `.install`-skripti on säilytetty tässä repossa hakemistossa
`raw/aur-voikko-libreoffice/`.

## 4. Tavutuskuvioita ei ole Archissa

Debianin `hyphen-fi` toimittaa tiedoston `/usr/share/hyphen/hyph_fi_FI.dic`.
Archissa `hyphen`-paketissa on vain kirjasto, eikä suomen kuvioita paketoi
kukaan — ei repoissa eikä AUR:ssa.

Tiedosto on kopioitava käsin (`dict/hyphen/hyph_fi_FI.dic` tässä repossa),
jolloin se jää `pacman -Qo`:lle orvoksi. Se on tarkoituksellista, ei jäänne
— merkitse se muistiin, tai seuraava siivous poistaa sen.

Tämä koskee vain hunspell-reittiä: Voikko tavuttaa LibreOfficessa itse.

## 5. enchant valittaa puuttuvista kirjastoista

Arch paketoi `enchant`iin *kaikkien* taustaosien liitännäiset mutta ei
niiden kirjastoja, joten enchant yrittää ladata jokaisen ja epäonnistuu
useimmissa:

```
$ enchant-lsmod-2 -list-dicts
libenchant-WARNING: Error loading plugin: libaspell.so.15: cannot open shared object file
libenchant-WARNING: Error loading plugin: libhspell.so.0: cannot open shared object file
libenchant-WARNING: Error loading plugin: libnuspell.so.5: cannot open shared object file
fi (voikko)
```

Varoitukset ovat kosmeettisia. Debianissa niitä ei näy, koska siellä jokainen
taustaosa on oma pakettinsa eikä asentamatonta liitännäistä ole levyllä.
Viimeinen rivi on se joka merkitsee.

Arch tekee saman KDE:n **Sonnetille**: `sonnet`-paketti toimittaa neljä
liitännäistä, joista vain kaksi on ladattavissa (mitattu 2026-09-16):

```
$ for p in /usr/lib/qt6/plugins/kf6/sonnet/*.so; do ldd "$p" | grep "not found"; done
	libaspell.so.15 => not found      (sonnet_aspell.so)
	libhspell.so.0 => not found       (sonnet_hspell.so)
```

Suomen kannalta tämä on merkityksetöntä: `sonnet_voikko.so` latautuu.
Ks. [sovellukset.md](sovellukset.md) kohta 2.

## 6. Yhteenveto siirtäjälle

Ubuntu-ohjetta seuratessa Archissa nämä viisi kohtaa on korjattava:

1. `apt`-paketit → `yay -S voikko-fi voikko-libreoffice` (kaksi, ei kuusi)
2. Voikon data on `/usr/share/voikko/`, ei `/usr/lib/voikko/`
3. LibreOffice-laajennus vaatii `unopkg`-rekisteröinnin, joka voi kadota
   LibreOfficen päivityksessä
4. `hyph_fi_FI.dic` on kopioitava käsin
5. enchantin varoitukset eivät ole vika

Selainten ja Neovimin osuus (`.xpi`, `.bdic`, `.spl`) on distrosta
riippumaton — ne ovat käyttäjän kotihakemistossa, eikä mikään paketinhallinta
koske niihin.
