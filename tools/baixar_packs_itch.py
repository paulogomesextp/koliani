#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Descarrega packs GRATUITOS do itch.io para `assets/sprites/incoming/`.

Porque e' que isto existe: os chefes do jogo precisam de rigs animados e o
LuizMelo (o autor do "Evil Wizard 2" que ja' usamos) tem ~48 packs CC0 no
mesmo estilo -- e' a forma mais rapida de dar uma silhueta PROPRIA a cada
chefe em vez de recolorir sempre o mesmo boneco.

So' serve packs "name your own price" (gratuitos). Nao faz login, nao paga
nada, nao toca em packs pagos. O fluxo e' o mesmo do botao "No thanks,
just take me to the downloads" do site:

  1. GET  /<jogo>/purchase        -> cookie de sessao + `csrf_token`
  2. POST /<jogo>/download_url    -> JSON com o link temporario
  3. GET  <link>                  -> pagina com os ficheiros do pack
  4. POST /file/<id>              -> JSON com o URL assinado do .zip

  python tools/baixar_packs_itch.py luizmelo/medieval-king-pack ...
  python tools/baixar_packs_itch.py --lista        # o que ja' esta' em disco
"""

from __future__ import annotations

import http.cookiejar
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC = os.path.join(RAIZ, "assets", "sprites", "incoming")
DEBUG = "--debug" in sys.argv
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) koliani-asset-fetch"

_tarro = http.cookiejar.CookieJar()
_abre = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(_tarro))
_abre.addheaders = [("User-Agent", UA)]


def _get(url: str) -> bytes:
    with _abre.open(urllib.request.Request(url), timeout=60) as r:
        return r.read()


def _post(url: str, dados: dict, referer: str = "") -> dict:
    """POST de formulario. O itch exige o `Referer` e o cabecalho de XHR --
    sem eles responde 404 em vez de devolver o JSON."""
    corpo = urllib.parse.urlencode(dados).encode()
    cab = {
        "X-Requested-With": "XMLHttpRequest",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Accept": "application/json, text/javascript, */*; q=0.01",
    }
    if referer:
        cab["Referer"] = referer
        cab["Origin"] = "https://" + urllib.parse.urlparse(referer).netloc
    req = urllib.request.Request(url, data=corpo, headers=cab)
    try:
        with _abre.open(req, timeout=60) as r:
            return json.loads(r.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        if DEBUG:
            print("    [%s %s] %s" % (e.code, url, e.read()[:200]))
        raise


def _csrf(html: str) -> str:
    m = re.search(r'csrf_token"\s+value="([^"]+)"', html)
    if not m:
        raise RuntimeError("sem csrf_token na pagina")
    return m.group(1)


def baixar(autor: str, jogo: str) -> str | None:
    """Descarrega e descompacta um pack. Devolve a pasta, ou None."""
    destino = os.path.join(INC, autor, jogo)
    if os.path.isdir(destino) and os.listdir(destino):
        print("  = %s/%s ja' em disco" % (autor, jogo))
        return destino

    base = "https://%s.itch.io/%s" % (autor, jogo)
    tok = _csrf(_get(base + "/purchase").decode("utf-8", "replace"))
    link = _post(base + "/download_url", {"csrf_token": tok}, base + "/purchase")
    if "url" not in link:
        print("  ! %s/%s: sem link (pack pago?)" % (autor, jogo))
        return None

    pagina = _get(link["url"]).decode("utf-8", "replace")
    if DEBUG:
        with open(os.path.join(INC, "_dl_debug.html"), "w",
                  encoding="utf-8") as f:
            f.write(pagina)
    tok2 = _csrf(pagina)
    ids = re.findall(r'data-upload_id="(\d+)"', pagina)
    if not ids:
        print("  ! %s/%s: sem ficheiros na pagina de download" % (autor, jogo))
        return None

    os.makedirs(destino, exist_ok=True)
    for uid in ids:
        # O endpoint do ficheiro e' `/<slug>/file/<id>?source=game_download`
        # na RAIZ do subdominio -- nao debaixo do `/download/<chave>` da
        # pagina (ver `download_upload`/`qt` no `extern.min.js` do itch).
        pedido = "%s/file/%s?source=game_download" % (base, uid)
        alvo = _post(pedido, {"csrf_token": tok2}, link["url"])
        if "url" not in alvo:
            continue
        bruto = _get(alvo["url"])
        zipe = os.path.join(destino, "_%s.zip" % uid)
        with open(zipe, "wb") as f:
            f.write(bruto)
        try:
            with zipfile.ZipFile(zipe) as z:
                z.extractall(destino)
            os.remove(zipe)
        except zipfile.BadZipFile:
            print("  ! %s/%s: ficheiro %s nao e' zip" % (autor, jogo, uid))
    print("  + %s/%s -> %s" % (autor, jogo, os.path.relpath(destino, RAIZ)))
    return destino


def main() -> int:
    alvos = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not alvos:
        print(__doc__)
        return 1
    for a in alvos:
        autor, jogo = a.split("/", 1)
        try:
            baixar(autor, jogo)
        except Exception as e:       # rede/site -- nao vale a pena parar tudo
            print("  ! %s: %s" % (a, e))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
