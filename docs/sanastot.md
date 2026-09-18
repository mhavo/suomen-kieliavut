# Sanastot: mistä ne tulevat ja mikä niistä kannattaa valita

Repossa on kaksi hunspell-sanastoa. Ne eivät ole saman asian eri versioita
vaan kaksi eri sukua, eikä kumpikaan ole toista parempi kaikilla mittareilla.

## Ginterin muunnos — `dict/ginter/`

| | |
|---|---|
| Tekijä | Filip Ginter |
| Sanueita | 476 291 |
| Koko | `fi_FI.aff` 1,9 MB + `fi_FI.dic` 14 MB |
| Merkistö | UTF-8 |
| Julkaisu | 2023-12-06, `fginter/hunspell-fi` release 0.2 (`fi-spell-0.2.xpi`) |
| Lisenssi | **CC0-1.0** (upstreamin README) |
| Aineistolähde | TurkuNLP:n parsebank, suodatettu Voikolla |

Tekijän oma kuvaus laajennuksen `manifest.json`:issa on `"Very quick effort"`.
Kyseessä on koneellisesti laajennettu sanalista: taivutusmuodot on generoitu
massana affiksilipuiksi, ei käsin kuratoitu. Se on kuitenkin ylivoimaisesti
laajin saatavilla oleva suomen hunspell-sanasto, ja se on ainoa jossa on
nykysanastoa.

## myspell-fi 0.7 — `dict/myspell-fi-0.7/`

| | |
|---|---|
| Tekijät | Martin Vermeer, Pauli Virtanen |
| Sanueita | 88 452 |
| Koko | `fi-FI.aff` 560 kB + `fi-FI.dic` 896 kB |
| Merkistö | **ISO8859-1** |
| Alkuperä | Debianin paketti `myspell-fi 0.7-18`, pakattu uudelleen repossa `fluks/fi-FI-mozilla-spellchecker` |
| Lisenssi | **GPL-2.0-only** (`dict/myspell-fi-0.7/LICENSE`) |

Vanha ja pieni, käytännössä 2000-luvun alun sanasto. Sen etu on huoliteltu
affiksisäännöstö; haitta on että se ei tunne mitään 2010-luvun jälkeistä
sanaa eikä juuri yhdyssanoja.

## Mittaus 1: 13 sanan testi

Kolmentoista sanan testi, ajettu 2026-09-09 (`tools/vertaa-sanastot.sh`):

| Sana | Ginter | myspell-fi 0.7 | Voikko |
|---|---|---|---|
| talo | ✓ | ✓ | ✓ |
| taloissamme | ✓ | ✓ | ✓ |
| maastopyörä | ✓ | ✗ | ✓ |
| maastopyöräily | ✓ | ✗ | ✓ |
| tarkkailukehä | ✗ | ✗ | ✓ |
| kännykkä | ✓ | ✗ | ✓ |
| sähköposti | ✓ | ✗ | ✓ |
| verkkosivusto | ✓ | ✗ | ✓ |
| koronarokote | ✗ | ✗ | ✓ |
| linja-autoasema | ✓ | ✓ | ✓ |
| Helsingissä | ✓ | ✓ | ✓ |
| kirjoittaisimmekohan | ✗ | ✓ | ✓ |
| älypuhelin | ✓ | ✗ | ✓ |
| **Hylätty** | **3/13** | **8/13** | **0/13** |

Huomaa `kirjoittaisimmekohan`: pieni ja huolellinen affiksisäännöstö voittaa
laajan ja karkean silloin kun kyse on puhtaasta taivutuksesta. Ginterin
sanasto puolestaan voittaa aina kun kyse on sanavarastosta.

Kumpikin häviää Voikolle, joka hyväksyy nämä kaikki. Se ei etsi sanaa
listasta vaan pilkkoo sen morfeemeiksi — `tarkkailu` + `kehä` on kelvollinen
yhdyssana riippumatta siitä onko sitä koskaan kirjoitettu.

Sanajoukko on tiedostossa `tools/testisanat.txt`; lisää sinne omia
kompastuskiviäsi ja aja skripti uudestaan.

## Kolmas variantti: Ginter karsittuna — `dict/ginter-karsittu/`

245 000 sanuetta Ginterin sanastosta, valittuna niin että tulos mahtuu
Chromiumin `.bdic`-muotoon. Valintaperuste on **sanan esiintymistiheys
vapaassa korpuksessa** (`tools/korpus-frekvenssit.txt`), tasapelit sanan
pituudella.

Peruste vaihtui 0.9:ssä. Aiempi antoi etusijan myspell-fi 0.7:n sanalistalla
oleville sanoille; se lista on GPL-2.0-only, ja kriteerinä se teki
tuloksesta siitä johdetun teoksen. Uusi kriteeri on sekä lisenssipuhdas että
2,9 prosenttiyksikköä parempi. Perustelu ja mittaukset:
[convert-dict.md](convert-dict.md), [`../LICENSES.md`](../LICENSES.md).

Tämä on se, josta repon `build/fi-FI.bdic` on käännetty.

## Mittaus 2: korpuskattavuus

13 sanan testi kertoo mitä sanastot osaavat, mutta ei paljonko sillä on
käytännössä väliä. Toinen mittaus ajaa **62 641 uniikkia suomenkielistä
sanaa** jokaisen sanaston läpi — `tools/arvioi-korpuksella.sh`. Korpus on
kaksi riippumatonta osaa: UD Finnish-TDT (käsin tarkistettu treebank) ja
satunnaisotos fi-Wikipedian artikkeleista, molemmat CC BY-SA 4.0. Ks.
[`../tools/korpus/LUE.md`](../tools/korpus/LUE.md).

### Uniikit sanat (types)

| Sanasto | Hylkyä / 62 641 | Kattavuus | 95 %:n väli |
|---|---|---|---|
| Voikko | 3 157 | **95,0 %** | 94,8–95,1 |
| Ginter kokonaan | 7 493 | 88,0 % | 87,8–88,3 |
| **Ginter karsittu** (`build/fi-FI.bdic`) | **14 774** | **76,4 %** | 76,1–76,7 |
| myspell-fi 0.7 | 32 993 | 47,3 % | 46,9–47,7 |

### Esiintymät (tokens)

Sama mittaus painotettuna sillä, miten usein sana korpuksessa esiintyy. Tämä
on lähempänä sitä, minkä käyttäjä kokee kirjoittaessaan: yleiset sanat
painavat enemmän kuin harvinaiset.

| Sanasto | Kattavuus | 95 %:n väli |
|---|---|---|
| Voikko | **97,6 %** | 97,6–97,7 |
| Ginter kokonaan | 95,9 % | 95,8–96,0 |
| **Ginter karsittu** | **92,0 %** | 91,9–92,1 |
| myspell-fi 0.7 | 80,1 % | 79,9–80,2 |

Otoskoko on 242 037 esiintymää. Huomaa että esiintymät eivät ole toisistaan
riippumattomia, joten token-välit ovat todellista kapeampia.

### Mitä nämä luvut eivät kerro

**Korpuksen katto ei ole 100 %.** Wikipedia-osakorpuksessa on vierassanoja,
lyhenteitä, puhekieltä ja kirjoitusvirheitä, joita mikään suomen sanasto ei
voi eikä saa tunnistaa. Skriptin `--oov`-valitsin poimii satunnaiset 100
hylkyä käsin tarkistettaviksi; Voikon otoksesta noin neljä viidesosaa oli
tällaista kohinaa (`autobahn`, `description`, `nyk`, `roskiksiks`,
`kuvitellu`). Korpuksen todellinen katto on siis noin 96 %, ei 100 % —
eli Voikko ohittaa aidosti vain noin prosentin sanoista.

**Voikko-vertailu on osin kehäpäätelmä.** Ginterin sanasto on rakennettu
suodattamalla parsebank-korpus **Voikolla**, joten Ginterin sanat ovat
määritelmällisesti Voikon hyväksymien muotojen osajoukko eikä Voikko voi
juuri hävitä. Tämä ei tee johtopäätöstä vääräksi — syy (morfologinen
analyysi vs. sanalista) on riippumaton mittauksesta, ja se näkyy myös
13 sanan testissä — mutta luku ei ole riippumaton todiste.

**Luottamusväli koskee otantavirhettä, ei edustavuutta.** Kaksi osakorpusta
ei ole satunnaisotos "suomen kielestä".

**Tämä mittaa vain puolet oikoluvusta, ja se on tärkein rajoitus.** Korpus
sisältää vain oikein kirjoitettuja sanoja, joten mitattu suure on
*kattavuus*: kuinka suuren osan oikeista sanoista sanasto tunnistaa.
Mittaus ei kerro mitään siitä, kuinka hyvin sanasto **hylkää väärin
kirjoitetut sanat**. Nämä kaksi ovat vastakkaisia: sanasto, joka hyväksyy
kaiken, saisi tässä testissä 100 % ja olisi silti täysin hyödytön
oikolukijana. Erityisesti mittaamatta jäävät

- hyväksymisvirheet eli väärien sanojen läpipääsy (*false positives*),
- korjausehdotusten osuvuus, joka on se, minkä käyttäjä kokee laatuna,
- yhdyssana- ja taivutusvirheiden havaitseminen,
- arkikieli, ammattikieli ja käyttäjien todelliset kirjoitusvirheet.

Luvut ovat siis vertailukelpoisia **keskenään** sanastojen laajuuden
mittarina, mutta niistä ei voi päätellä, mikä sanasto on parempi
oikolukija. Negatiivinen virhekorpus tätä varten on kirjattu siirretyksi
työksi, ks. [../HARDENING_NOTES.md](../HARDENING_NOTES.md).

**myspell-fi:n merkistö.** myspell-fi 0.7 on ISO8859-1. Se käännetään
mittauksessa UTF-8:ksi, koska ilman muunnosta hunspell pudottaa Latin-1:n
ulkopuolisia merkkejä sisältävät sanat (esim. `šakki`) tuloksesta kokonaan —
ne eivät päädy hylkyihin eivätkä hyväksyttyihin, mikä nostaisi myspellin
lukuja perusteettomasti. Oire olisi stderrissä `error - iconv: UTF-8 ->
ISO8859-1`, mutta hunspell palauttaa silti 0.

### Johtopäätös

Ginter kokonaan olisi paras hunspell-vaihtoehto, mutta se ei käänny
`.bdic`-muotoon. Karsittu versio maksaa 11,6 prosenttiyksikköä täydestä
Ginteristä ja voittaa myspell-fi 0.7:n 29,1:llä.

Voikon ja parhaan hunspell-vaihtoehdon väliin jää 7 prosenttiyksikköä
(types) tai 1,7 (tokens). Se on se hinta, jonka selaimissa kirjoittaminen
maksaa, eikä sitä voi maksaa pois.

## Suositus kohteittain

| Kohde | Valitse | Miksi |
|---|---|---|
| LibreOffice (natiivi) | Voikko | kielentarkistus + yhdyssanat |
| LibreOffice (Flatpak/Snap) | Ginter `.oxt` | Voikko ei toimi hiekkalaatikossa |
| GTK, Emacs (enchant) | Voikko | sama moottori, tulee automaattisesti |
| KDE/Qt (**Sonnet**, ei enchant) | Voikko | `sonnet_voikko.so` tulee `sonnet`-paketista |
| Firefox / Thunderbird | Ginter | ainoa järkevä hunspell-vaihtoehto |
| Chromium / Electron | Ginter **karsittuna** | koko sanasto ei mahdu `.bdic`-muotoon |
| Vim / Neovim | Ginter | `:mkspell` kääntää sen ongelmitta |

Mekanismien erittely ja se mitä kussakin on todennettu:
[sovellukset.md](sovellukset.md).

## Historia: `build/fi-FI.bdic` oli pitkään väärästä sanastosta

Vuosina 2025–2026 Chromiumissa ollut sanasto oli käännetty **myspell-fi
0.7:stä**, siis siitä 67 prosentin vaihtoehdosta. Syy löytyi jälkikäteen:
`convert-dict-tool-from-chromium` -repon mukana tulevat esimerkkitiedostot
ovat juuri `fi-FI.aff` ja `fi-FI.dic`, ja käännös meni niillä läpi
ensimmäisellä yrityksellä. Ginterin sanastolla se ei olisi mennyt — se
kaatuu muodon rajaan.

Vanha tiedosto on säilytetty nimellä `build/fi-FI-myspell-0.7.bdic`
vertailua varten. Nykyinen `build/fi-FI.bdic` on karsittu Ginter
(2026-09-09).

## Vaihtoehto, jota ei ole

Voikko-projekti ei julkaise hunspell-muotoista sanastoa. Voikon oma aineisto
on äärellistilainen transduktori (`mor.vfst`), josta ei ole suoraa
muunnosreittiä hunspelliin — sen sanamuotojoukko on ääretön. Ginterin
muunnos on juuri yritys generoida siitä äärellinen approksimaatio, ja
`"very quick effort"` kuvaa hyvin sitä miten hyvin se onnistuu.

Tästä seuraa, että selainten suomen oikoluku pysyy pysyvästi huonompana kuin
työpöytäsovellusten. Se ei ole asennusvirhe vaan rakenteellinen rajoite.
