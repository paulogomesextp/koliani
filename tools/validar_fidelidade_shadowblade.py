#!/usr/bin/env python3
"""Valida nitidez estrutural; qualidade percebida exige revisao humana.

Confere os 84 frames, ausência de halo parcial acrescentado e import pixel-art.
Nao altera assets nem substitui o teste existente de paridade/movimento.
"""
from pathlib import Path
import json
import sys
import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parents[1]


def validar(nome='shadowblade'):
    golden = RAIZ / 'assets/sprites/koliani_golden_set/frames'
    skin = RAIZ / 'assets/sprites/koliani_skins' / nome / 'frames'
    fontes = {p.relative_to(golden).as_posix(): p for p in golden.rglob('*.png')}
    derivados = {p.relative_to(skin).as_posix(): p for p in skin.rglob('*.png')}
    falhas, frames = [], []
    if fontes.keys() != derivados.keys() or len(derivados) != 84:
        falhas.append('Conjunto de frames diferente do Golden Set / contrato de 84')
    for nome, fonte in fontes.items():
        if nome not in derivados:
            continue
        a = np.array(Image.open(fonte).convert('RGBA'))
        b = np.array(Image.open(derivados[nome]).convert('RGBA'))
        if a.shape != b.shape:
            falhas.append('Canvas diferente: ' + nome)
            continue
        aa, ab = a[:, :, 3], b[:, :, 3]
        halo = int(((aa == 0) & (ab > 0) & (ab < 255)).sum())
        if halo:
            falhas.append(f'Halo baked: {nome}: {halo} pixels')
        imp = derivados[nome].with_suffix('.png.import').read_text()
        if 'compress/mode=0' not in imp or 'mipmaps/generate=false' not in imp:
            falhas.append('Import deixou de ser lossless/sem mipmaps: ' + nome)
        if nome.startswith('run_final/'):
            y = int(np.where(aa.any(axis=1))[0].max())
            if not np.array_equal(aa[y-7:y+1] > 0, ab[y-7:y+1] > 0):
                falhas.append('Mascara dos pes diferente: ' + nome)
        frames.append({'frame': nome, 'halo_acrescentado': halo,
                       'alfa_parcial': int(((ab > 0) & (ab < 255)).sum())})
    resultado = {'frames': frames, 'falhas': falhas,
                 'legibilidade_subjetiva': 'HUMAN PLAYTEST REQUIRED'}
    pasta = RAIZ / ('work/shadowblade_fidelity' if nome == 'shadowblade'
                    else 'work/skins_premium_20261001/' + nome)
    pasta.mkdir(parents=True, exist_ok=True)
    (pasta / 'fidelidade.json').write_text(json.dumps(resultado, indent=2))
    print(f'FIDELIDADE ESTRUTURAL: {len(frames)} frames, {len(falhas)} falhas')
    for falha in falhas:
        print('FALHOU:', falha)
    return bool(falhas)


if __name__ == '__main__':
    raise SystemExit(validar(sys.argv[1] if len(sys.argv) > 1 else 'shadowblade'))
