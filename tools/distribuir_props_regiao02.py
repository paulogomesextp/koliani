#!/usr/bin/env python3
"""Anti-repeticao dos props da Regiao II (regra R7 do plano de remodel).

    python3 tools/distribuir_props_regiao02.py

Acrescenta a cada prop do bioma `desfiladeiro` o campo `niveis` (numeros de
nivel 1-based, 6..10) com os niveis onde ele pode aparecer. Nenhum prop fica
em mais de DOIS dos cinco, e cada nivel guarda props de chao, de parede e
pendurados. Os consumidores (`plataforma.gd`, `gerador_corredor.gd`,
`atmosfera.gd`) filtram por `EstadoJogo.indice_nivel + 1`; sem o campo, o
prop vale em todos (comportamento das outras regioes, intacto).

So' mexe em deco.json -- nenhuma arte nova, nenhum sorteio do `_rng`
funcional (o filtro so' muda o TAMANHO da lista, nao quantos sorteios se fazem).
"""
import json
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAM = os.path.join(RAIZ, "assets/sprites/pixel/deco/deco.json")

NIVEIS = {
    "balaustrada": [6, 10], "tocha": [6, 9], "janela_gotica": [7],
    "coluna_igreja": [9, 10], "pedra_talhada": [6, 8], "lampiao_t": [7, 9],
    "corrente_t": [8, 10], "corrente_t2": [6, 8], "estatua": [7, 9],
    "bandeira": [6, 10], "correntes": [7, 8], "gargula": [6, 10],
    "lanterna": [8, 9], "gaiola": [7, 10], "coluna": [7, 10],
    "arco": [6, 8], "janela": [7, 9], "escombros": [8, 9],
    "vitral": [9, 10], "pedras": [6, 7], "cristais": [8, 10],
    "vegetacao_alta": [6, 9], "vegetacao_baixa": [7, 8],
    "arvore_seca": [6, 8],
}


def main():
    with open(CAM, encoding="utf-8") as f:
        cat = json.load(f)
    for p in cat["desfiladeiro"]:
        p["niveis"] = NIVEIS[p["nome"]]
    with open(CAM, "w", encoding="utf-8", newline="\n") as f:
        json.dump(cat, f, indent="\t", ensure_ascii=False)
        f.write("\n")
    for n in range(6, 11):
        por = {}
        for p in cat["desfiladeiro"]:
            if n in p["niveis"]:
                por.setdefault(p["onde"], []).append(p["nome"])
        print("N%02d" % n, {k: len(v) for k, v in por.items()})


if __name__ == "__main__":
    main()
