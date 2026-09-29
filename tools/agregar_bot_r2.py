#!/usr/bin/env python3
"""Junta as runs do bot da Regiao II num so' ficheiro de dados + tabelas.

    python3 tools/agregar_bot_r2.py <pasta_runs> <saida.json>

Le' os `n##_<perfil>_<run>.json` que o `correr_bot_r2.sh` deixa, agrega por
nivel e por perfil, e escreve o JSON que acompanha o relatorio. Imprime as
tabelas em markdown para se colarem no relatorio sem as copiar a mao (que e'
como os numeros se estragam).
"""
import json
import os
import statistics
import sys

NIVEIS = ["n05", "n06", "n07", "n08", "n09", "n10"]
# X de nascimento por nivel (a jornada de aproximacao vive toda em X
# NEGATIVO, por isso "quanto andou" nao se le' do x_max sozinho).
SPAWN = {"n05": 150, "n06": -8620, "n07": -9870,
         "n08": 150, "n09": -12370, "n10": 185}
PERFIS = ["casual", "normal", "experiente"]

CAMPOS = [
    "tempo_s", "mortes", "quedas", "dano_total", "golpes_sofridos",
    "checkpoints", "saltos", "saltos_falhados", "dashes",
    "dashes_desperdicados", "planar_s", "vento_entradas", "vento_s",
    "hesitacao_s", "hesitacoes", "ataques", "chefe_duracao_s",
    "chefe_dano_sofrido", "chefe_golpes_sofridos", "chefe_telegrafos",
    "chefe_ataques_evitados", "encravamentos", "x_max",
    "progresso_pct", "mortes_por_kpx",
]


def med(vs):
    vs = [v for v in vs if v is not None]
    return round(statistics.mean(vs), 2) if vs else 0.0


def main():
    pasta, saida = sys.argv[1], sys.argv[2]
    runs = []
    for f in sorted(os.listdir(pasta)):
        if not f.endswith(".json"):
            continue
        nivel, perfil, n = f[:-5].split("_")
        d = json.load(open(os.path.join(pasta, f)))
        d["nivel"], d["perfil"], d["run"] = nivel, perfil, int(n)
        x0 = SPAWN.get(nivel, 0)
        vao = max(1.0, float(d.get("x_alvo", 0)) - x0)
        # x_max pode vir `null`: o acumulador apanhou um NaN. Aconteceu em 3
        # das 9 runs do N06 (ver o relatorio). Nesse caso o melhor X conhecido
        # sai das posicoes de morte, que sao todas finitas.
        xm = d.get("x_max")
        d["x_max_nan"] = xm is None
        if xm is None:
            pos = d.get("mortes_pos") or []
            xm = max([p[0] for p in pos], default=x0)
            d["x_max"] = xm
        d["progresso_pct"] = round(
            100.0 * min(1.0, (float(xm) - x0) / vao), 1)
        # mortes por 1000 px ANDADOS: sem isto um perfil que hesita mais
        # parece "melhor" so' porque avanca menos e morre menos.
        andou = max(1.0, float(xm) - x0)
        d["mortes_por_kpx"] = round(1000.0 * d.get("mortes", 0) / andou, 2)
        runs.append(d)

    por_nivel = {}
    for nv in NIVEIS:
        rs = [r for r in runs if r["nivel"] == nv]
        if not rs:
            continue
        falhas = {}
        for r in rs:
            for x, c in (r.get("pontos_de_falha") or {}).items():
                falhas[x] = falhas.get(x, 0) + c
        por_perfil = {}
        for p in PERFIS:
            sub = [r for r in rs if r["perfil"] == p]
            if sub:
                por_perfil[p] = {c: med([r.get(c) for r in sub]) for c in CAMPOS}
                por_perfil[p]["runs"] = len(sub)
                por_perfil[p]["concluidos"] = sum(
                    1 for r in sub if r.get("concluido"))
        vidas = [r.get("chefe_vida_inicial", 0) for r in rs if r.get("chefe_vida_inicial")]
        minima = [r.get("chefe_vida_min", 0) for r in rs if r.get("chefe_vida_min")]
        por_nivel[nv] = {
            "runs": len(rs),
            "concluidos": sum(1 for r in rs if r.get("concluido")),
            "media": {c: med([r.get(c) for r in rs]) for c in CAMPOS},
            "por_perfil": por_perfil,
            "chefe_vida_inicial": max(vidas) if vidas else 0,
            "chefe_vida_min": min(minima) if minima else 0,
            "pontos_de_falha": dict(sorted(
                falhas.items(), key=lambda kv: -kv[1])[:8]),
            "x_alvo": rs[0].get("x_alvo", 0),
            "seeds": sorted(r["seed"] for r in rs),
            "runs_com_x_max_nan": sum(1 for r in rs if r.get("x_max_nan")),
        }

    json.dump({"runs": runs, "por_nivel": por_nivel}, open(saida, "w"),
              indent=1, ensure_ascii=False)

    print("| nivel | runs | concl. | progresso % | mortes | mortes/1000px | dano "
          "| saltos falh. | dashes desp. | planar s | vento s | hesit. s | chefe s |")
    print("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
    for nv, d in por_nivel.items():
        m = d["media"]
        print(f"| {nv.upper()} | {d['runs']} | {d['concluidos']} "
              f"| {m['progresso_pct']} | {m['mortes']} | {m['mortes_por_kpx']} "
              f"| {m['dano_total']} | {m['saltos_falhados']} "
              f"| {m['dashes_desperdicados']} | {m['planar_s']} | {m['vento_s']} "
              f"| {m['hesitacao_s']} | {m['chefe_duracao_s']} |")
    print()
    print("| nivel | perfil | progresso % | mortes | mortes/1000px | dano "
          "| saltos falh. | hesit. s | chefe: telegrafos / evitados / golpes |")
    print("|---|---|---:|---:|---:|---:|---:|---:|---|")
    for nv, d in por_nivel.items():
        for p, m in d["por_perfil"].items():
            print(f"| {nv.upper()} | {p} | {m['progresso_pct']} | {m['mortes']} "
                  f"| {m['mortes_por_kpx']} | {m['dano_total']} "
                  f"| {m['saltos_falhados']} | {m['hesitacao_s']} "
                  f"| {m['chefe_telegrafos']} / {m['chefe_ataques_evitados']}"
                  f" / {m['chefe_golpes_sofridos']} |")


if __name__ == "__main__":
    main()
