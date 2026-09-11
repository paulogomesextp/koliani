"""Execution 9E.2 -- arte de produção do Coração Putrefacto, derivada da
autoridade dedicada aprovada pelo Game Master
(`coracao_putrefacto_production_authority_v1_0.png`).

A prancha já traz alfa real: 9 elementos soltos sobre transparência. Só se
fazem operações técnicas:
  1. etiquetagem dos componentes (alfa > 16, 8-conexos) em resolução total; cada
     elemento = os componentes cujo centro cai na sua caixa (as caixas de P1 e
     P2 tocam-se em 2 px -- é a máscara que separa, não a caixa);
  2. o véu de brilho de apresentação (alfa < 64, onde vive quase todo o
     vermelho/magenta solto) sai antes da redução;
  3. redução BOX com alfa pré-multiplicado a UMA escala comum às duas fases
     (P1 fica com 100 px de altura -- o `_normalizar_escala` dá k = 1), alfa
     0/255;
  4. as duas fases alinhadas pelo NÚCLEO (o clarão não salta na transição) e
     pela base;
  5. estados só por píxel inteiro: pulso da corrupção (ganho só nos píxeis
     magenta), recuo no golpe, dissolução Bayer na morte.

Uso (na raiz do repo):
    python tools/produzir_coracao_9e2.py [--previa DIR]
"""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import deque
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
AUTORIDADE = RAIZ / "work/production_art_gate/9E1_game_master_approved/coracao_putrefacto_production_authority_v1_0.png"
AUTORIDADE_SHA = "460435aaf18b9b568b0f4529a087a2cc80e07554def894c313f579b9b9247693"
AUT_REL = "work/production_art_gate/9E1_game_master_approved/coracao_putrefacto_production_authority_v1_0.png"
DIR = RAIZ / "assets/art/regions/region_01_forest/bosses/coracao_putrefacto/production"
RES = "res://assets/art/regions/region_01_forest/bosses/coracao_putrefacto/production"
MAN_INIMIGOS = RAIZ / "assets/art/regions/region_01_forest/enemies/production/enemy_production_manifest.json"

## Caixas dos elementos na autoridade (x0, y0, x1, y1). Classificação A/B/C/D
## da análise da 9E.2; só os que têm lugar no runtime atual são produzidos.
ELEMENTOS = {
    "fase_1":  {"caixa": (0, 0, 725, 505), "classe": "A", "uso": "corpo, fase 1 (vida > 50 %)"},
    "fase_2":  {"caixa": (725, 0, 1448, 505), "classe": "A", "uso": "corpo, fase 2 (vida <= 50 %)"},
    "erupcao": {"caixa": (1112, 840, 1448, 1086), "classe": "C", "uso": "VFX da transição de fase"},
}
NAO_USADOS = {
    "alcance_esquerda": {"caixa": [0, 505, 700, 840], "classe": "A",
                         "motivo": "pose de alcance; o runtime não tem estado de ataque do corpo (atacar_anim nunca corre)"},
    "alcance_direita": {"caixa": [680, 505, 1448, 840], "classe": "A", "motivo": "idem, versão intensificada"},
    "monte_raizes": {"caixa": [0, 840, 330, 1086], "classe": "C",
                     "motivo": "seria arte do RaizPerigo, ator partilhado por outros níveis -- fora de âmbito"},
    "tentaculo": {"caixa": [330, 840, 575, 1086], "classe": "C", "motivo": "sem estado/efeito no runtime atual"},
    "coracao_compacto": {"caixa": [575, 840, 800, 1086], "classe": "C",
                         "motivo": "sozinho seria o 'coração a flutuar' que a identidade proíbe; sem uso no runtime"},
    "varrimento": {"caixa": [800, 840, 1112, 1086], "classe": "C", "motivo": "sem estado/efeito no runtime atual"},
}

ALTURA_FASE_1 = 100
CANVAS = (176, 120)
BASELINE = 112
GANHOS = {"idle": [1.0, 1.08, 1.16, 1.08], "idle_f2": [1.0, 1.12, 1.25, 1.12]}
DEAD_PASSOS = 10
BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def etiquetar(im: Image.Image) -> tuple[list[int], list[tuple[int, int, int, int, int]]]:
    W, H = im.size
    a = im.getchannel("A").tobytes()
    lab = [0] * (W * H)
    info = [(0, 0, 0, 0, 0)]
    for i in range(W * H):
        if a[i] <= 16 or lab[i]:
            continue
        n = len(info)
        q = deque([i]); lab[i] = n
        x0 = y0 = 10 ** 9; x1 = y1 = -1; cnt = 0
        while q:
            j = q.popleft(); y, x = divmod(j, W); cnt += 1
            x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    u, v = x + dx, y + dy
                    if 0 <= u < W and 0 <= v < H:
                        k = v * W + u
                        if a[k] > 16 and not lab[k]:
                            lab[k] = n; q.append(k)
        info.append((cnt, x0, y0, x1 + 1, y1 + 1))
    return lab, info


def isolar(im: Image.Image, lab: list[int], info: list, caixa) -> Image.Image:
    W, H = im.size
    x0, y0, x1, y1 = caixa
    ids = {n for n in range(1, len(info))
           if x0 <= (info[n][1] + info[n][3]) / 2 < x1 and y0 <= (info[n][2] + info[n][4]) / 2 < y1}
    out = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
    o = out.load(); p = im.load()
    for y in range(y0, min(y1, H)):
        for x in range(x0, min(x1, W)):
            if lab[y * W + x] in ids:
                r, g, b, a = p[x, y]
                if a >= 64:  # véu de brilho / restos vermelhos da apresentação: fora
                    o[x - x0, y - y0] = (r, g, b, a)
    return out.crop(out.getchannel("A").getbbox())


def reduzir(im: Image.Image, k: float) -> Image.Image:
    red = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.BOX)
    p = red.load()
    for y in range(red.height):
        for x in range(red.width):
            r, g, b, a = p[x, y]
            p[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    return red.crop(red.getchannel("A").getbbox())


def nucleo(im: Image.Image) -> tuple[float, float]:
    """Centro do clarão do núcleo: média dos píxeis mais claros de corrupção."""
    p = im.load(); pts = []
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = p[x, y]
            if a and r >= 230 and b >= 200 and g >= 150:
                pts.append((x, y))
    if not pts:
        return im.width / 2, im.height / 2
    return sum(x for x, _ in pts) / len(pts), sum(y for _, y in pts) / len(pts)


def ganho(im: Image.Image, g: float) -> Image.Image:
    t = im.copy()
    if g == 1.0:
        return t
    p = t.load()
    for y in range(t.height):
        for x in range(t.width):
            r, gg, b, a = p[x, y]
            if a and r - gg >= 40 and b - gg >= 20:
                p[x, y] = (min(255, round(r * g)), min(255, round(gg * g)), min(255, round(b * g)), a)
    return t


def deslocar(im: Image.Image, dx: int) -> Image.Image:
    t = Image.new("RGBA", im.size, (0, 0, 0, 0)); t.alpha_composite(im, (dx, 0)); return t


def dissolver(im: Image.Image, f: float) -> Image.Image:
    t = im.copy(); p = t.load(); c = f * 16.0
    for y in range(t.height):
        for x in range(t.width):
            if p[x, y][3] and BAYER4[y % 4][x % 4] < c:
                p[x, y] = (0, 0, 0, 0)
    return t


def produzir(previa: Path | None) -> dict:
    if sha256(AUTORIDADE) != AUTORIDADE_SHA:
        raise SystemExit("autoridade com SHA diferente do aprovado -- nada produzido")
    im = Image.open(AUTORIDADE).convert("RGBA")
    lab, info = etiquetar(im)
    fontes = {n: isolar(im, lab, info, e["caixa"]) for n, e in ELEMENTOS.items()}
    k0 = ALTURA_FASE_1 / fontes["fase_1"].height   # escala única para tudo
    # o alfa binarizado come/ganha um píxel: procura, em passos de 0,1 % à volta
    # de k0, a primeira escala em que a fase 1 mede MESMO 100 de alto e cabe nos
    # 150 de largura (o runtime reescala pelo `used_rect` do idle 0)
    k = k0
    for i in sorted(range(-40, 41), key=abs):
        kk = k0 * (1.0 + i * 0.001)
        r1 = reduzir(fontes["fase_1"], kk)
        if r1.height == ALTURA_FASE_1 and r1.width <= 150:
            k = kk
            break
    red = {n: reduzir(f, k) for n, f in fontes.items()}

    # colocar as fases: base na BASELINE, núcleo na mesma coluna
    n1 = nucleo(red["fase_1"]); n2 = nucleo(red["fase_2"])
    cx = CANVAS[0] // 2
    telas = {}
    for n, nx in (("fase_1", n1[0]), ("fase_2", n2[0])):
        t = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        ox = round(cx - nx); oy = BASELINE + 1 - red[n].height
        if ox < 1 or ox + red[n].width > CANVAS[0] - 1 or oy < 1:
            raise SystemExit(f"{n} não cabe no canvas {CANVAS} (ox={ox}, oy={oy}, {red[n].size})")
        t.alpha_composite(red[n], (ox, oy))
        telas[n] = t
    nuc_frame = {n: [round(cx, 2), round(BASELINE + 1 - red[n].height + (n1 if n == "fase_1" else n2)[1], 2)]
                 for n in telas}

    for sub in ("phase_1", "phase_2", "vfx"):
        (DIR / sub).mkdir(parents=True, exist_ok=True)
        for velho in (DIR / sub).glob("*.png"):
            velho.unlink()

    anims: dict = {}

    def gravar(nome: str, sub: str, fps: float, ciclo: bool, imgs: list[Image.Image], fase: int) -> None:
        fr = []
        for i, fi in enumerate(imgs):
            arq = DIR / sub / f"{nome}_{i + 1:02d}.png"
            fi.save(arq, format="PNG", optimize=False, compress_level=9)
            fr.append({"ficheiro": f"{RES}/{sub}/{arq.name}", "sha256": sha256(arq), "dimensoes": list(fi.size)})
        anims[nome] = {"fps": fps, "ciclo": ciclo, "fase": fase, "frames": fr}

    p1, p2 = telas["fase_1"], telas["fase_2"]
    gravar("idle", "phase_1", 5.0, True, [ganho(p1, g) for g in GANHOS["idle"]], 1)
    gravar("run", "phase_1", 5.0, True, [p1], 1)          # velocidade 0: só por segurança
    gravar("hit", "phase_1", 14.0, False, [deslocar(p1, d) for d in (-2, 2, -1)], 1)
    gravar("idle_f2", "phase_2", 6.0, True, [ganho(p2, g) for g in GANHOS["idle_f2"]], 2)
    gravar("hit_f2", "phase_2", 14.0, False, [deslocar(p2, d) for d in (-2, 2, -1)], 2)
    # o Coração morre sempre na fase 2 (a morte vem depois dos 50 %)
    gravar("dead", "phase_2", 10.0, False, [dissolver(p2, i / DEAD_PASSOS) for i in range(DEAD_PASSOS)], 2)

    # borda transparente de 2 px: recortado rente, o validator (com razão) dá
    # CLIPPED_* nos quatro lados
    erup = Image.new("RGBA", (red["erupcao"].width + 4, red["erupcao"].height + 4), (0, 0, 0, 0))
    erup.alpha_composite(red["erupcao"], (2, 2))
    arq = DIR / "vfx" / "erupcao.png"
    erup.save(arq, format="PNG", optimize=False, compress_level=9)
    vfx = {"erupcao": {"ficheiro": f"{RES}/vfx/erupcao.png", "sha256": sha256(arq), "dimensoes": list(erup.size),
                       "uso": ELEMENTOS["erupcao"]["uso"]}}

    manifesto = {
        "execution": "9E.2", "entidade": "coracao_putrefacto", "status": "PRODUCTION_INTEGRATED",
        "autoridade": {"caminho": AUT_REL, "sha256": AUTORIDADE_SHA, "dimensoes": list(im.size), "modo": "RGBA",
                       "alfa": "real (9 elementos sobre transparência; bordas suaves)",
                       "aprovacao": "GAME MASTER APPROVED (Paulo, 11 set 2026)"},
        "autoridade_anterior": {"caminho": "work/production_art_gate/9D1_game_master_approved/region1_enemies_boss_visual_authority_v1_0.png",
                                "sha256": "8ebf8ecd13e8d7e7d803acfcccf3361a35cb77ff9ad6dd1d01c79b8b24ebb2fd"},
        "cena": "res://scenes/actors/ChefeCoracaoPutrefacto.tscn",
        "contrato": {"canvas": list(CANVAS), "baseline_y": BASELINE, "altura_fase_1_px": ALTURA_FASE_1,
                     "largura_max_px": 150, "escala_reducao": round(k, 6),
                     "porque": "o Coração é mais largo que alto; com o teto de 110 dos guardiões ficava com 75 px -- "
                               "150 mantém-no com a altura de sempre (100 x escala_visual 1.7)"},
        "operacoes": ["etiquetagem alfa>16 8-conexa", "alfa<64 fora (véu de apresentação)", "BOX pré-multiplicado",
                      "alfa 0/255", "alinhamento pelo núcleo e pela base", "ganho só na corrupção magenta (pulso)",
                      "translação de píxel inteiro (hit)", "dissolução Bayer 4x4 (dead)"],
        "elementos": {n: {"caixa_autoridade": list(e["caixa"]), "classe": e["classe"], "uso": e["uso"],
                          "corpo_px": list(red[n].size)} for n, e in ELEMENTOS.items()},
        "nao_usados": NAO_USADOS,
        "nucleo_no_frame": nuc_frame,
        "animacoes": anims, "vfx": vfx,
    }
    (DIR / "manifest.json").write_text(json.dumps(manifesto, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # registo no manifesto dos inimigos: é por ele que o runtime (regiao1_inimigos.gd) liga a produção
    man = json.loads(MAN_INIMIGOS.read_text(encoding="utf-8"))
    ent = man["inimigos"]["coracao_putrefacto"]
    for chave in ("motivo", "tentativas_mascara", "classificacao"):
        ent.pop(chave, None)
    ent.update({"status": "PRODUCTION_INTEGRATED", "execution": "9E.2",
                "manifesto_boss": f"{RES}/manifest.json",
                "autoridade": AUT_REL, "autoridade_sha256": AUTORIDADE_SHA,
                "estados_alcancaveis": sorted(anims.keys()), "animacoes": anims, "vfx": vfx,
                "nucleo_no_frame": nuc_frame})
    MAN_INIMIGOS.write_text(json.dumps(man, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"k={k:.5f}  fase_1 {red['fase_1'].size}  fase_2 {red['fase_2'].size}  erupcao {erup.size}  núcleo {nuc_frame}")
    if previa:
        previa.mkdir(parents=True, exist_ok=True)
        par = Image.new("RGBA", (CANVAS[0] * 2 + 8, CANVAS[1] * 2), (24, 20, 30, 255))
        par.paste((0, 190, 90, 255), (0, CANVAS[1], par.width, par.height))
        for i, t in enumerate((p1, p2)):
            for j in range(2):
                par.alpha_composite(t, (i * (CANVAS[0] + 8), j * CANVAS[1]))
        par.resize((par.width * 3, par.height * 3), Image.NEAREST).save(previa / "coracao_fases_3x.png")
        e = Image.new("RGBA", erup.size, (24, 20, 30, 255)); e.alpha_composite(erup)
        e.resize((e.width * 3, e.height * 3), Image.NEAREST).save(previa / "coracao_erupcao_3x.png")
    return manifesto


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--previa", type=Path, default=None)
    produzir(ap.parse_args().previa)
