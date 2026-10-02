#!/usr/bin/env python3
"""Compara o BASELINE FUNCIONAL (`tools/baseline_geometria.gd`: colisoes,
plataformas, perigos, checkpoints, porta, spawn) dos 100 niveis entre este
checkout e um de REFERENCIA (por exemplo o master antes do trabalho).

Serve de PROVA DE NAO ALTERACAO: depois de acrescentar componentes e um nivel,
so' os indices esperados podem diferir.

    python tools/comparar_baselines_100.py <dir_referencia> [dir_saida] [indices...]

Corre sempre pelo isolador de save (`tools/godot_isolado.py`). Sai com 1 se
algum indice nao esperado diferir (esperados: variavel ESPERADOS, ou `--esperar=N,M`).
"""
import os
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ISOLADO = os.path.join(RAIZ, "tools", "godot_isolado.py")


def baseline(projeto: str, indice: int, saida: str) -> bool:
    cmd = [sys.executable, ISOLADO, "--", "--headless", "--path", projeto,
           "--script", "res://tools/baseline_geometria.gd", "--", str(indice), saida]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return False
    return os.path.exists(saida) and r.returncode in (0, 1)


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    esperados = set()
    for a in sys.argv[1:]:
        if a.startswith("--esperar="):
            esperados = {int(x) for x in a.split("=", 1)[1].split(",") if x}
    if not args:
        print(__doc__)
        return 96
    ref = os.path.abspath(args[0])
    saida = os.path.abspath(args[1]) if len(args) > 1 else os.path.join(RAIZ, "work", "baselines")
    indices = [int(x) for x in args[2:]] or list(range(100))
    os.makedirs(os.path.join(saida, "ref"), exist_ok=True)
    os.makedirs(os.path.join(saida, "novo"), exist_ok=True)
    diferem, falharam = [], []
    for i in indices:
        a = os.path.join(saida, "ref", f"n{i:03d}.txt")
        b = os.path.join(saida, "novo", f"n{i:03d}.txt")
        for f in (a, b):
            if os.path.exists(f):
                os.remove(f)
        ok_a = baseline(ref, i, a)
        ok_b = baseline(RAIZ, i, b)
        if not (ok_a and ok_b):
            falharam.append(i)
            print(f"  [{i:3d}] FALHOU a medir (ref={ok_a}, novo={ok_b})", flush=True)
            continue
        ta = open(a, encoding="utf-8").read()
        tb = open(b, encoding="utf-8").read()
        if ta != tb:
            diferem.append(i)
            print(f"  [{i:3d}] DIFERE ({len(ta.splitlines())} vs {len(tb.splitlines())} linhas)", flush=True)
        elif i % 10 == 0:
            print(f"  [{i:3d}] igual", flush=True)
    print(f"niveis medidos: {len(indices) - len(falharam)}/{len(indices)} | iguais: "
          f"{len(indices) - len(falharam) - len(diferem)} | diferem: {diferem} | falharam: {falharam}")
    inesperados = [i for i in diferem if i not in esperados]
    if inesperados or falharam:
        print(f"INESPERADOS: {inesperados} | FALHARAM: {falharam}")
        return 1
    print("OK: so' diferem os indices esperados", sorted(esperados))
    return 0


if __name__ == "__main__":
    sys.exit(main())
