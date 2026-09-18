#!/usr/bin/env python3
"""LibreOfficen oikoluku-, tavutus- ja kielentarkistusluotain UNOn yli.

Käynnistää oman headless-LibreOfficen, kysyy LinguServiceManagerilta mitä
palveluita suomelle on tarjolla ja mitä ne vastaavat, ja tulostaa tuloksen
JSONina. Väitteet tehdään testi/tarkista.sh:ssa — tämä ohjelma ei ota kantaa
siihen mikä tulos on oikea.

MIKSI OMA LIBREOFFICE: unopkg ja soffice käyttävät samaa käyttäjäprofiilia
(~/.config/libreoffice/4). Luotain EI siis anna -env:UserInstallation-
valitsinta: skenaario 05:n asentama .oxt näkyy vain jos luotain avaa saman
profiilin.

PYTHON-UNO KAHDESSA DISTROSSA (FEATURE §2.4):
  Ubuntu  python3-uno asentaa uno.py dist-packagesiin — "import uno" toimii.
  Arch    sidonnat tulevat libreoffice-fresh-paketin mukana hakemistossa
          /usr/lib/libreoffice/program, joka ei ole sys.pathissa.
Ero ratkaistaan tässä tiedostossa, ei skenaarioskripteissä (R7).

Paluukoodit:
  0  JSON stdoutissa
  4  VIRHE — soffice ei käynnistynyt, yhteys ei auennut 60 sekunnissa (§7.4),
     tai UNO-kysely kaatui. EI koskaan hiljainen läpimeno.
"""
import json
import os
import shutil
import signal
import subprocess
import sys
import time

AIKAKATKAISU = 60  # sekuntia, FEATURE §7.4
# Portti on ohitettavissa, jotta luotainta voi kokeilla myös kehityskoneella
# ilman että se kaappaa käyttäjän oman LibreOfficen UNO-portin.
PORTTI = int(os.environ.get("LO_LUOTAIN_PORTTI", "2002"))
ARCH_UNO_POLKU = "/usr/lib/libreoffice/program"


def tuo_uno():
    """Palauttaa (uno, unohelper-tyylinen konteksti-moduuli) tai nostaa."""
    try:
        import uno  # noqa: F401
    except ImportError:
        if ARCH_UNO_POLKU not in sys.path:
            sys.path.insert(0, ARCH_UNO_POLKU)
        import uno  # noqa: F401
    return sys.modules["uno"]


def kaynnista_soffice():
    soffice = shutil.which("soffice") or shutil.which("libreoffice")
    if not soffice:
        raise RuntimeError("soffice puuttuu")
    yhteys = (
        "socket,host=127.0.0.1,port=%d,tcpNoDelay=1;urp;"
        "StarOffice.ServiceManager" % PORTTI
    )
    return subprocess.Popen(
        [
            soffice,
            "--headless",
            "--invisible",
            "--norestore",
            "--nologo",
            "--nodefault",
            "--nofirststartwizard",
            "--accept=" + yhteys,
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        # Oma prosessiryhmä, jotta koko puu saadaan alas myös silloin kun
        # soffice on jumissa — juuri se tilanne jota §7.4 varten mitataan.
        start_new_session=True,
    )


def yhdista(uno):
    """Odottaa yhteyttä. Nostaa TimeoutError kun AIKAKATKAISU umpeutuu."""
    paikallinen = uno.getComponentContext()
    resolver = paikallinen.ServiceManager.createInstanceWithContext(
        "com.sun.star.bridge.UnoUrlResolver", paikallinen
    )
    osoite = (
        "uno:socket,host=127.0.0.1,port=%d;urp;StarOffice.ComponentContext"
        % PORTTI
    )
    loppuu = time.monotonic() + AIKAKATKAISU
    viimeinen = None
    while time.monotonic() < loppuu:
        try:
            return resolver.resolve(osoite)
        except Exception as e:  # NoConnectException ennen kuin soffice kuuntelee
            viimeinen = e
            time.sleep(0.5)
    raise TimeoutError("UNO-yhteys ei auennut %d sekunnissa: %s"
                       % (AIKAKATKAISU, viimeinen))


# LANGUAGE_FINNISH. Vanha XSpellChecker1 ottaa kielen LCID-lukuna eikä
# Locale-rakenteena.
LCID_SUOMI = 1035


def hae_oikolukija(smgr, ctx, lingu):
    """Palauttaa (oikolukija, tapa).

    MIKSI KAKSI REITTIÄ: LinguServiceManagerin getSpellChecker() palauttaa
    olion, joka toteuttaa SEKÄ XSpellChecker1:n ETTÄ XSpellChecker:n, ja
    molemmissa on isValid. PyUNO valitsee niistä vanhan, jonka toinen
    argumentti on short — Locale-rakenne kaatuu siihen virheeseen
    "CannotConvertException: Type 17 is not supported!". Mitattu
    LibreOffice 25:llä 2026-09-18.

    Ensisijainen reitti on siis palvelu com.sun.star.linguistic2.SpellChecker,
    joka antaa yksikäsitteisen XSpellChecker:n. Jos sitä ei saada, pudotaan
    vanhaan rajapintaan LCID-luvulla — tulos on sama, kutsutapa eri.
    """
    try:
        suora = smgr.createInstanceWithContext(
            "com.sun.star.linguistic2.SpellChecker", ctx
        )
        if suora is not None:
            suora.isValid("talo", uno_locale(), ())
            return suora, "XSpellChecker"
    except Exception:
        pass
    return lingu.getSpellChecker(), "XSpellChecker1"


def uno_locale():
    import uno as _uno
    loc = _uno.createUnoStruct("com.sun.star.lang.Locale")
    loc.Language, loc.Country, loc.Variant = "fi", "FI", ""
    return loc


def kysy_isvalid(oikolukija, tapa, sana, loc):
    if tapa == "XSpellChecker":
        return oikolukija.isValid(sana, loc, ())
    return oikolukija.isValid(sana, LCID_SUOMI, ())


def luotaa(uno, ctx):
    smgr = ctx.ServiceManager
    lingu = smgr.createInstanceWithContext(
        "com.sun.star.linguistic2.LinguServiceManager", ctx
    )
    loc = uno.createUnoStruct("com.sun.star.lang.Locale")
    loc.Language, loc.Country, loc.Variant = "fi", "FI", ""

    tulos = {
        "oikolukijat": list(
            lingu.getAvailableServices("com.sun.star.linguistic2.SpellChecker", loc)
        ),
        "kielentarkistajat": list(
            lingu.getAvailableServices("com.sun.star.linguistic2.Proofreader", loc)
        ),
        "tavuttajat": list(
            lingu.getAvailableServices("com.sun.star.linguistic2.Hyphenator", loc)
        ),
    }

    oikolukija, tapa = hae_oikolukija(smgr, ctx, lingu)
    tulos["oikolukutapa"] = tapa
    tulos["tarkkailukeha"] = bool(kysy_isvalid(oikolukija, tapa, "tarkkailukehä", loc))
    tulos["qwertyxyz"] = bool(kysy_isvalid(oikolukija, tapa, "qwertyxyz", loc))

    # createPossibleHyphens palauttaa kaikki tavurajat kerralla
    # ("maas=to=pyö=räi=ly"); hyphenate() antaisi vain yhden kohdan.
    tavutus = ""
    try:
        mahdolliset = lingu.getHyphenator().createPossibleHyphens(
            "maastopyöräily", loc, ()
        )
        if mahdolliset is not None:
            tavutus = mahdolliset.getPossibleHyphens()
    except Exception as e:
        tavutus = "VIRHE: %s" % e
    tulos["tavutus"] = tavutus
    return tulos


def sammuta(ctx, prosessi):
    try:
        if ctx is not None:
            desktop = ctx.ServiceManager.createInstanceWithContext(
                "com.sun.star.frame.Desktop", ctx
            )
            desktop.terminate()
    except Exception:
        pass
    if prosessi is None:
        return
    try:
        prosessi.wait(timeout=10)
    except Exception:
        try:
            os.killpg(os.getpgid(prosessi.pid), signal.SIGKILL)
        except Exception:
            pass


def main():
    prosessi = None
    ctx = None
    try:
        uno = tuo_uno()
        prosessi = kaynnista_soffice()
        ctx = yhdista(uno)
        tulos = luotaa(uno, ctx)
    except Exception as e:
        print("VIRHE: %s: %s" % (type(e).__name__, e), file=sys.stderr)
        sammuta(ctx, prosessi)
        return 4
    sammuta(ctx, prosessi)
    json.dump(tulos, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
