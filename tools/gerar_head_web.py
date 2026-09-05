#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Mete o `web/head_pwa.html` no `html/head_include` do preset "Web".

O Godot guarda esse campo como UMA string dentro do `export_presets.cfg`
-- sem newlines e sem aspas duplas. Escrever HTML e JavaScript nessas
condicoes a mao e' como se ve^: ilegivel e impossivel de rever. Por isso o
conteudo vive num ficheiro proprio, comentado, e esta ferramenta e' que o
achata.

    python tools/gerar_head_web.py            # escreve
    python tools/gerar_head_web.py --verificar # so' diz se esta' em dia

Um teste em `tests/run_tests.gd` corre a mesma comparacao, para nao
acontecer o obvio: alguem editar o `head_pwa.html`, esquecer isto, e o
build sair na mesma com o `head_include` antigo.
"""

import io
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTE = os.path.join(RAIZ, "web", "head_pwa.html")
CFG = os.path.join(RAIZ, "export_presets.cfg")


def achatar(html):
    """O HTML numa linha so', sem comentarios e sem espaco a mais.

    Os comentarios `<!-- -->` sao para quem le' o ficheiro, nao para o
    browser; e o `head_include` nao pode ter newlines nenhumas.
    """
    html = re.sub(r"<!--.*?-->", "", html, flags=re.S)
    linhas = [l.strip() for l in html.splitlines()]
    return " ".join(l for l in linhas if l)


def main():
    with io.open(FONTE, encoding="utf-8") as f:
        valor = achatar(f.read())

    if '"' in valor:
        print("ERRO: o head_pwa.html tem aspas DUPLAS -- nao cabem no .cfg.",
              file=sys.stderr)
        print("Usa aspas simples nos atributos e nas strings de JS.",
              file=sys.stderr)
        return 2

    with io.open(CFG, encoding="utf-8", newline="") as f:
        cfg = f.read()

    m = re.search(r'^html/head_include=".*"$', cfg, flags=re.M)
    if m is None:
        print("ERRO: nao encontrei `html/head_include` no export_presets.cfg",
              file=sys.stderr)
        return 2

    novo = 'html/head_include="%s"' % valor
    if m.group(0) == novo:
        print("head_include ja' esta' em dia (%d caracteres)." % len(valor))
        return 0

    if "--verificar" in sys.argv:
        print("head_include DESACTUALIZADO -- corre "
              "`python tools/gerar_head_web.py`", file=sys.stderr)
        return 1

    with io.open(CFG, "w", encoding="utf-8", newline="") as f:
        f.write(cfg[:m.start()] + novo + cfg[m.end():])
    print("head_include actualizado (%d caracteres)." % len(valor))
    return 0


if __name__ == "__main__":
    sys.exit(main())
