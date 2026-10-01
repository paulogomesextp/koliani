"""Confere hashes anteriores dos assets/gameplay protegidos deste lote."""
from pathlib import Path
import hashlib
import json

raiz = Path(__file__).resolve().parents[1]
antes = json.loads((raiz / 'work/skins_premium_20261001/antes.json').read_text())
permitidos = tuple('assets/sprites/koliani_skins/' + nome + '/'
                   for nome in ('anjo', 'demonio')) + tuple(
                       'assets/sprites/koliani_skins/' + nome + '/vfx/'
                       for nome in ('abadia_afogada', 'celestial'))
previews = tuple('assets/sprites/koliani_skins/' + nome + '/preview.png'
                 for nome in ('abadia_afogada', 'celestial'))
fontes = ('scripts/vfx_skin.gd', 'scripts/skins_premium_aura.gd',
          'scripts/pausa.gd', 'scripts/musica.gd')
falhas, total = [], 0
for nome, esperado in antes.items():
    if not nome.startswith(('assets/', 'scenes/', 'data/', 'scripts/')):
        continue
    if nome.startswith(permitidos) or nome in fontes or nome in previews:
        continue
    caminho = raiz / nome
    atual = hashlib.sha256(caminho.read_bytes()).hexdigest() if caminho.exists() else None
    total += 1
    if atual != esperado:
        falhas.append(nome)
print(f'SCOPE SKINS: {total} hashes protegidos, {len(falhas)} alterações inesperadas')
for nome in falhas:
    print('FALHOU:', nome)
raise SystemExit(bool(falhas))
