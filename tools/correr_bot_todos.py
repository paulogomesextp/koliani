#!/usr/bin/env python3
"""Corre o `tools/bot_gauntlet.gd` nos 100 níveis e escreve um relatório.

O bot sozinho diz de UM nível; o que interessa é a lista dos que trancam.
Corre vários em paralelo (cada Godot é um processo à parte, o `Input` é
por processo) e escreve `docs/relatorio_bot.md` ordenado pelo pior.

    python tools/correr_bot_todos.py [segundos] [paralelos] [primeiro] [ultimo]

Nota: precisa de janela (o `--headless` não desenha nesta máquina); usa
`--screen 1` para não roubar o ecrã principal ao Paulo.
"""
import concurrent.futures as cf
import os
import re
import subprocess
import sys
import time

GODOT = r"C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64_console.exe"
RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def niveis() -> list[str]:
    with open(os.path.join(RAIZ, "scripts", "estado_jogo.gd"), encoding="utf-8") as f:
        txt = f.read()
    bloco = txt.split("const NIVEIS := [", 1)[1].split("]", 1)[0]
    return re.findall(r'"(res://scenes/levels/[^"]+)"', bloco)


def correr(i: int, cena: str, segundos: float) -> dict:
    t0 = time.time()
    try:
        p = subprocess.run(
            [GODOT, "--window", "--screen", "1", "--script",
             "res://tools/bot_gauntlet.gd", "--", cena, str(segundos), str(i)],
            cwd=RAIZ, capture_output=True, text=True, errors="replace",
            timeout=segundos + 120)
        saida = p.stdout + p.stderr
        codigo = p.returncode
    except subprocess.TimeoutExpired as e:
        saida = (e.stdout or "") + "\n<<< O GODOT NAO SAIU (timeout)"
        codigo = 99
    r = {"i": i, "cena": cena.split("/")[-1], "codigo": codigo,
         "seg": time.time() - t0, "chegou": "chegou=true" in saida,
         "preso": "NAO PASSOU DAQUI" in saida, "avancou": 0.0, "linhas": []}
    m = re.search(r"avancou (-?[\d.]+) px", saida)
    if m:
        r["avancou"] = float(m.group(1))
    for ln in saida.splitlines():
        if ln.startswith("cena=") or ln.startswith("  "):
            r["linhas"].append(ln.rstrip())
    if "SEM Koliani" in saida:
        r["linhas"].append("  <<< SEM Koliani NA CENA")
    return r


def main() -> None:
    seg = float(sys.argv[1]) if len(sys.argv) > 1 else 90.0
    par = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    ini = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    fim = int(sys.argv[4]) if len(sys.argv) > 4 else 10 ** 6
    todos = list(enumerate(niveis()))[ini:fim + 1]
    print("%d niveis, %.0fs cada, %d em paralelo" % (len(todos), seg, par))
    res = []
    with cf.ThreadPoolExecutor(max_workers=par) as ex:
        futs = {ex.submit(correr, i, c, seg): i for i, c in todos}
        for f in cf.as_completed(futs):
            r = f.result()
            res.append(r)
            print("[%3d/%3d] N%-3d %-38s %s" % (
                len(res), len(todos), r["i"] + 1, r["cena"],
                "OK" if r["chegou"] else ("PRESO" if r["preso"] else "parou")))
            sys.stdout.flush()
    res.sort(key=lambda r: (r["chegou"], not r["preso"], r["avancou"]))
    presos = [r for r in res if r["preso"]]
    parados = [r for r in res if not r["chegou"] and not r["preso"]]
    ok = [r for r in res if r["chegou"]]
    cam = os.path.join(RAIZ, "docs", "relatorio_bot.md")
    with open(cam, "w", encoding="utf-8", newline="\n") as f:
        f.write("# Relatório do bot anti-softlock\n\n")
        f.write("Gerado por `tools/correr_bot_todos.py` — %s, %.0fs por nível.\n\n"
                % (time.strftime("%Y-%m-%d %H:%M"), seg))
        f.write("**%d chegaram ao fim · %d não passaram de um sítio · %d não chegaram**\n\n"
                % (len(ok), len(presos), len(parados)))
        f.write("O bot não é veredicto: falha escadas de ~173 px com 104 px de\n"
                "subida. O que ele acusa vai-se ver com `tools/ver_zona.gd`.\n\n")
        for titulo, grupo in (("Não passaram dali (candidatos a softlock)", presos),
                              ("Não chegaram ao fim", parados),
                              ("Chegaram", ok)):
            f.write("## %s (%d)\n\n" % (titulo, len(grupo)))
            for r in grupo:
                f.write("### N%d — %s\n\n```\n%s\n```\n\n"
                        % (r["i"] + 1, r["cena"], "\n".join(r["linhas"]) or "(sem saída)"))
    print("\nescrito: %s" % cam)
    print("%d OK, %d presos, %d nao chegaram" % (len(ok), len(presos), len(parados)))


if __name__ == "__main__":
    main()
