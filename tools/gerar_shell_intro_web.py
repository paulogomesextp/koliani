#!/usr/bin/env python3
"""Gera o shell da intro iOS com o JS canónico e os seis catálogos Textos."""
import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
fonte = (RAIZ / 'scripts/intro.gd').read_text(encoding='utf-8')
js = re.search(r'const JS_INTRO := """([\s\S]*?)"""', fonte)[1]
chaves = ['menu.skip_to_menu', 'menu.tap_play', 'menu.rotate_device']
catalogos = {}
for idioma in ['en', 'pt', 'es', 'fr', 'de', 'zh']:
    dados = json.loads((RAIZ / f'assets/i18n/{idioma}.json').read_text(encoding='utf-8'))
    catalogos[idioma] = {chave: dados[chave] for chave in chaves}
arranque = (RAIZ / 'web/arranque_intro.js.in').read_text(encoding='utf-8')
arranque = arranque.replace('$CATALOGOS_INTRO', json.dumps(catalogos, ensure_ascii=False)).replace('$JS_INTRO', js)
shell = (RAIZ / 'web/shell_intro.html.in').read_text(encoding='utf-8').replace('$KOLIANI_INTRO', arranque)
shell = '\n'.join(linha.rstrip() for linha in shell.splitlines()) + '\n'
saida = RAIZ / 'web/shell_intro.html'
if '--verificar' in sys.argv:
    if not saida.exists() or saida.read_text(encoding='utf-8') != shell:
        sys.exit('ERRO: shell intro desatualizado')
    print('PASS: shell intro/catálogos/JS sincronizados')
else:
    saida.write_text(shell, encoding='utf-8')
    print('Shell intro Web gerado')
