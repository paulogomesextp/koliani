"""Execution 9G -- VFX de produção da Região I, derivados da prancha 07.

A prancha `07_KOLIANI_VFX_CLEAN_v1_1.png` é a autoridade aprovada dos efeitos
da Koliani/Shadowblade. Tem canal alfa mas NÃO é transparente: o alfa anda
entre 208 e 250 em toda a imagem e o fundo de cada célula é um xadrez escuro
pintado. Por isso:

  * nada se recorta pela grelha das células -- as linhas não batem com os
    frames (o "finisher burst" tem dois frames numa célula). Cada frame é
    localizado pelo NÚMERO impresso por baixo (centro do rótulo) e a janela
    vai de meio caminho ao rótulo anterior a meio caminho ao seguinte;
  * o alfa é RECONSTRUÍDO (classe B, reconstrução técnica): os efeitos são
    emissivos sobre fundo escuro, logo `px = fundo + efeito`. Com o fundo do
    painel medido (percentil 97 dos píxeis cinzentos), `efeito = px - fundo`
    e guarda-se RGBA tal que `rgb * a = px - fundo` -- desenhado em modo
    aditivo dá exactamente o que a prancha mostra, sem o xadrez;
  * variantes de CORRUPÇÃO (classe C, derivação): a mesma forma aprovada,
    com a luminância mapeada na rampa congelada do briefing (preto -> violeta
    escuro -> magenta profundo). Nunca o violeta claro da Shadowblade.

Nada é redesenhado, nada é redimensionado: 1 px da prancha = 1 px do jogo
(a Koliani desenhada nos exemplos da prancha tem os mesmos ~64 px do jogo).

Uso:
    python tools/produzir_vfx_9g.py            # produz + valida + folha
    python tools/produzir_vfx_9g.py --validar  # só valida o que está no disco
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
PRANCHA = RAIZ / "Koliani_1.0_Master_Package_v2/references/approved/07_KOLIANI_VFX_CLEAN_v1_1.png"
PRANCHA_SHA = "6564982d4ccfad84d0a5f6d0e73196785afcff7ac8cd218dd27f066f883fe8c6"
PRANCHA_12 = RAIZ / "Koliani_1.0_Master_Package_v2/references/approved/12_PRODUCTION_PACK_v10_GAMEPLAY_VFX_SFX_POLISH.png"
PRANCHA_12_SHA = "6eea95ba9816509fa4f520b1aeeeda17b0246c56576c57af4ef0a15c65ccc221"
SAIDA = RAIZ / "assets/art/regions/region_01_forest/production/vfx_9g"
MANIFESTO = SAIDA / "vfx_manifest.json"
PREVIEW = RAIZ / "work/execution_9g/preview"

# Faixas (y) do interior das células e centros dos rótulos (x), medidos na
# prancha: faixas por perfil de fundo cinzento, rótulos pelos dígitos brancos.
FAIXAS = {1: (138, 218), 2: (274, 348), 3: (402, 476), 4: (528, 606), 5: (664, 742)}

# nome: (faixa, painel x0..x1, centros dos rótulos, uso no jogo)
# Só entram os efeitos que o runtime da Região I usa (slash_arc e
# teleport_portal ficam de fora: o golpe 1 é o do Golden Set e não há portal
# em L1-L5).
FAMILIAS = {
    "spin_slash": (1, (536, 969), [560, 613, 664, 718, 773, 827, 883, 941], "golpe 2 do combo"),
    "heavy_slash": (1, (987, 1512), [1008, 1056, 1107, 1162, 1218, 1275, 1331, 1383, 1434, 1488], "golpe 3 (remate)"),
    "dash_trail": (2, (24, 548), [55, 119, 182, 245, 313, 381, 448, 515], "rasto do dash"),
    "dash_impact": (2, (566, 980), [597, 664, 732, 802, 872, 943], "arranque do dash / 2.º salto"),
    "roll_dodge": (2, (997, 1511), [1026, 1091, 1154, 1219, 1286, 1351, 1416, 1479], "rolamento"),
    "hit_sparks": (3, (24, 505), [57, 118, 179, 238, 296, 357, 417, 480], "acerto"),
    "finisher_burst": (3, (524, 1030), [552, 611, 671, 732, 797, 866, 932, 1001], "remate / crítico"),
    "hurt_blood": (3, (1049, 1511), [1085, 1163, 1241, 1317, 1389, 1470], "Koliani ferida"),
    "land_impact": (4, (24, 470), [57, 117, 173, 231, 288, 344, 394, 447], "aterragem forte"),
    "projectile": (4, (488, 986), [516, 559, 606, 664, 729, 796, 866, 936], "tiro mágico"),
    "charge_aura": (4, (1007, 1510), [1038, 1097, 1157, 1219, 1283, 1347, 1411, 1477], "só como base da corrupção"),
    "defend_shield": (5, (24, 428), [49, 104, 159, 215, 265, 309, 352, 402], "escudo"),
    "pickup": (5, (771, 1056), [795, 841, 889, 936, 983, 1032], "apanhar / checkpoint"),
    "death_dissolve": (5, (1076, 1512), [1102, 1155, 1209, 1264, 1320, 1378, 1431, 1484], "morte"),
}

# variantes de corrupção (classe C): família base -> nome
CORRUPCAO = {
    "death_dissolve": "death_dissolve_corrupcao",
    "finisher_burst": "finisher_burst_corrupcao",
    "projectile": "projectile_corrupcao",
    "charge_aura": "charge_aura_corrupcao",
    "hit_sparks": "hit_sparks_corrupcao",
}
# rampa congelada do briefing 9G §4: preto -> violeta escuro -> magenta profundo
# (o topo da rampa tem de se ler sobre a noite da Região I: um projéctil do
# Coração que não se vê é um problema de gameplay, não de estilo)
RAMPA = [(0.0, (10, 4, 14)), (0.3, (60, 16, 88)), (0.6, (150, 24, 108)), (1.0, (232, 82, 162))]

LIMIAR = 0.07          # excesso mínimo sobre o fundo (abaixo disto é o xadrez)
FUNDO_PERCENTIL = 0.97


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def _fundo_do_painel(px, x0: int, x1: int, y0: int, y1: int) -> tuple[int, int, int]:
    """Percentil 97 por canal dos píxeis cinzentos do painel (o xadrez)."""
    canais: list[list[int]] = [[], [], []]
    for y in range(y0, y1):
        for x in range(x0, x1):
            c = px[x, y]
            l = (c[0] + c[1] + c[2]) / 3
            if max(c[:3]) - min(c[:3]) < 20 and 20 < l < 100:
                for i in range(3):
                    canais[i].append(c[i])
    out = []
    for v in canais:
        v.sort()
        out.append(v[int(len(v) * FUNDO_PERCENTIL)] if v else 60)
    return tuple(out)


def _reconstruir(c, fundo) -> tuple[int, int, int, int]:
    """RGBA com rgb*a = px - fundo (efeito emissivo sem o fundo pintado)."""
    ex = [max(0, c[i] - fundo[i]) for i in range(3)]
    a = max(ex[i] / max(1, 255 - fundo[i]) for i in range(3))
    # cinzento pouco claro = linha de célula / xadrez, não efeito
    if max(c[:3]) - min(c[:3]) < 25 and (c[0] + c[1] + c[2]) / 3 < 110:
        return (0, 0, 0, 0)
    if a < LIMIAR:
        return (0, 0, 0, 0)
    a2 = min(1.0, (a - LIMIAR) / (1.0 - LIMIAR))
    rgb = tuple(min(255, int(round(ex[i] / a2))) for i in range(3))
    return (*rgb, int(round(a2 * 255)))


def _corromper(c) -> tuple[int, int, int, int]:
    """Mesma forma aprovada, na paleta de corrupção.

    O alfa segue a LUMINÂNCIA do original: sem isto, o brilho largo e fraco da
    prancha ficava com a cor escura da rampa e alfa alto -- uma mancha preta
    que tapava o guardião e o seu telégrafo. Assim só os realces de magenta
    ficam opacos e a silhueta lê-se por baixo."""
    if c[3] == 0:
        return c
    l = (0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]) / 255.0
    a = int(round(c[3] * min(1.0, 0.12 + 1.15 * l)))
    c = (c[0], c[1], c[2], a)
    if a == 0:
        return (0, 0, 0, 0)
    for (t0, c0), (t1, c1) in zip(RAMPA, RAMPA[1:]):
        if l <= t1:
            f = 0.0 if t1 == t0 else (l - t0) / (t1 - t0)
            return (*(int(round(c0[i] + (c1[i] - c0[i]) * f)) for i in range(3)), c[3])
    return (*RAMPA[-1][1], c[3])


def _repartir_painel(px, fundo, px0: int, px1: int, y0: int, y1: int, centros: list[int]):
    """Reconstrói o alfa do painel inteiro e reparte os píxeis pelos frames.

    A prancha é desenhada à mão: a arte NÃO está centrada nos números (a elipse
    do "spin slash 03" cai quase em cima do rótulo 04) e um efeito parte-se em
    vários pedaços soltos. Por isso não serve nem a grelha das células, nem o
    rótulo mais perto, nem as componentes ligadas.

    O que serve é o próprio desenho: os frames estão separados por VALES de
    massa. Escolhem-se os `n-1` cortes que somam menos alfa, com a largura de
    cada frame presa entre 55 % e 160 % do espaçamento dos rótulos (programação
    dinâmica). Onde dois efeitos se tocam mesmo, o corte cai no mínimo local --
    é o menos mau possível e o validador marca o contacto."""
    w, h = px1 - px0, y1 - y0
    tira = Image.new("RGBA", (w, h))
    t = tira.load()
    massa = [0] * w
    for y in range(h):
        for x in range(w):
            c = _reconstruir(px[x + px0, y + y0], fundo)
            t[x, y] = c
            massa[x] += c[3]
    n = len(centros)
    d = (centros[-1] - centros[0]) / max(1, n - 1)
    lo, hi = max(4, int(d * 0.55)), int(d * 1.6)
    # custo de cortar em x: massa numa janela de 3 px (um vale largo é melhor)
    custo = [sum(massa[max(0, x - 1):x + 2]) for x in range(w)]
    # sem isto a programação dinâmica enfia vários cortes seguidos na primeira
    # zona vazia (custo zero) e espreme os frames: a largura tem de puxar para
    # o espaçamento dos rótulos.
    peso = (sum(massa) / max(1, n)) * 0.35

    def pen(larg: float) -> float:
        return peso * ((larg - d) / d) ** 2

    INF = float("inf")
    # dp[k][x] = melhor custo com k cortes feitos, último corte em x
    dp = [[INF] * w for _ in range(n)]
    de = [[-1] * w for _ in range(n)]
    for x in range(lo, min(w, hi + 1)):
        dp[1][x] = custo[x] + pen(x)
    for k in range(2, n):
        for x in range(w):
            melhor, arg = INF, -1
            for xp in range(max(0, x - hi), max(0, x - lo) + 1):
                v = dp[k - 1][xp] + custo[x] + pen(x - xp)
                if v < melhor:
                    melhor, arg = v, xp
            dp[k][x], de[k][x] = melhor, arg
    fim, melhor = -1, INF
    for x in range(w):
        if w - x < lo or w - x > hi:
            continue
        if dp[n - 1][x] + pen(w - x) < melhor:
            melhor, fim = dp[n - 1][x] + pen(w - x), x
    cortes = []
    k, x = n - 1, fim
    while k >= 1 and x >= 0:
        cortes.append(x)
        x = de[k][x]
        k -= 1
    cortes = sorted(c for c in cortes if c >= 0)
    limites = [0] + cortes + [w]
    dono: dict[tuple[int, int], int] = {}
    for y in range(h):
        for x in range(w):
            if t[x, y][3] == 0:
                continue
            i = 0
            while i + 1 < len(limites) - 1 and x >= limites[i + 1]:
                i += 1
            dono[(x, y)] = min(i, n - 1)
    return dono, t, [c + px0 for c in cortes]


def _ancoras(dono: dict, px0: int, n: int) -> list[int]:
    """Âncora de cada frame: grelha regular ajustada (mínimos quadrados) aos
    centros do desenho. Uma grelha em vez do centro de cada frame porque o
    efeito TEM de avançar dentro do canvas (o arco abre para a frente); usar o
    centro de cada frame punha tudo a pulsar no mesmo sítio."""
    soma = [0] * n
    cont = [0] * n
    for (x, _y), i in dono.items():
        soma[i] += x + px0
        cont[i] += 1
    xs = [soma[i] / cont[i] for i in range(n) if cont[i]]
    idx = [i for i in range(n) if cont[i]]
    m = len(idx)
    mi = sum(idx) / m
    mx = sum(xs) / m
    den = sum((i - mi) ** 2 for i in idx) or 1.0
    d = sum((idx[k] - mi) * (xs[k] - mx) for k in range(m)) / den
    a = mx - d * mi
    return [int(round(a + d * i)) for i in range(n)]


def _validar_frame(im: Image.Image, borda_prancha: int) -> tuple[str, list[str], dict]:
    """PASS/REVIEW/FAIL de um frame de VFX (sem regras de personagem)."""
    w, h = im.size
    px = im.load()
    alertas: list[str] = []
    if im.mode != "RGBA":
        return "FAIL", ["SEM_ALFA"], {}
    n = 0
    fortes = 0
    isolados = 0
    cinza = 0
    for y in range(h):
        for x in range(w):
            a = px[x, y][3]
            if a == 0:
                continue
            n += 1
            if a > 76:
                fortes += 1
            c = px[x, y]
            if max(c[:3]) - min(c[:3]) < 20 and a < 64:
                cinza += 1
            viz = 0
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if (dx or dy) and 0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] > 0:
                        viz += 1
            if viz == 0:
                isolados += 1
    medidas = {"pixeis": n, "fortes": fortes, "isolados": isolados, "cinza_fraco": cinza}
    if n == 0 or fortes == 0:
        return "FAIL", ["VAZIO"], medidas
    # contacto com o limite da FAIXA/PAINEL na prancha = o efeito foi pintado
    # a sair da célula (o que falta não existe na autoridade)
    medidas["borda"] = borda_prancha
    if borda_prancha > 2:
        alertas.append("CONTACTO_BORDA")
    if isolados > max(3, n * 0.03):
        alertas.append("RUIDO_ISOLADO")
    if cinza > n * 0.15:
        alertas.append("RESIDUO_CINZA")
    if n < 20:
        alertas.append("POUCA_COBERTURA")
    return ("REVIEW" if alertas else "PASS"), alertas, medidas


def produzir() -> dict:
    if sha256(PRANCHA) != PRANCHA_SHA:
        sys.exit("ERRO: SHA da prancha 07 não bate com o manifesto aprovado")
    fonte = Image.open(PRANCHA)
    modo_fonte = fonte.mode
    px = fonte.convert("RGB").load()
    SAIDA.mkdir(parents=True, exist_ok=True)
    manifesto: dict = {
        "execution": "9G",
        "status": "PRODUCTION_INTEGRATED",
        "autoridade": {
            "ficheiro": str(PRANCHA.relative_to(RAIZ)).replace("\\", "/"),
            "sha256": PRANCHA_SHA, "dimensoes": list(fonte.size), "modo": modo_fonte,
            "nota": "alfa 208-250 em toda a prancha: fundo pintado, alfa reconstruído",
        },
        "referencia_apresentacao": {
            "ficheiro": str(PRANCHA_12.relative_to(RAIZ)).replace("\\", "/"),
            "sha256": PRANCHA_12_SHA,
            "uso": "só apresentação (hit-stop, telegraph, feedback); RGB pintado sobre cenário, nada extraído",
        },
        "familias": {},
    }
    imagens: dict[str, list[Image.Image]] = {}
    for nome, (faixa, (px0, px1), centros, uso) in FAMILIAS.items():
        y0, y1 = FAIXAS[faixa]
        fundo = _fundo_do_painel(px, px0, px1, y0, y1)
        dono, tira, cortes = _repartir_painel(px, fundo, px0, px1, y0, y1, centros)
        ancoras = _ancoras(dono, px0, len(centros))
        alt = y1 - y0
        # meia-largura do canvas: a maior extensão de um frame à sua âncora
        meia = 8
        for (x, y), i in dono.items():
            meia = max(meia, abs(x + px0 - ancoras[i]) + 1)
        larg = 2 * meia
        frames = []
        for i, c in enumerate(ancoras):
            im = Image.new("RGBA", (larg, alt), (0, 0, 0, 0))
            q = im.load()
            borda = 0
            xs = []
            for (x, y), dono_i in dono.items():
                if dono_i != i:
                    continue
                q[x + px0 - c + meia, y] = tira[x, y]
                xs.append(x + px0)
                if tira[x, y][3] > 76 and (y in (0, alt - 1) or x in (0, px1 - px0 - 1)):
                    borda += 1
            caixa = (min(xs) if xs else c, y0, (max(xs) + 1) if xs else c, y1)
            frames.append((im, borda, caixa))
        # corta a margem vazia comum a todos (mantém o centro do rótulo no meio)
        caixas = [f[0].getchannel("A").getbbox() for f in frames]
        caixas = [b for b in caixas if b]
        ux0 = min(b[0] for b in caixas); ux1 = max(b[2] for b in caixas)
        uy0 = min(b[1] for b in caixas); uy1 = max(b[3] for b in caixas)
        mx = min(ux0, larg - ux1)
        corte = (mx, uy0, larg - mx, uy1)
        imagens[nome] = []
        registo = []
        pasta = SAIDA / nome
        pasta.mkdir(exist_ok=True)
        for i, (im, borda, caixa) in enumerate(frames):
            ic = im.crop(corte)
            imagens[nome].append(ic)
            estado, alertas, medidas = _validar_frame(ic, borda)
            f = pasta / f"{nome}_{i + 1:02d}.png"
            ic.save(f, optimize=True)
            registo.append({"ficheiro": f"{nome}/{f.name}", "sha256": sha256(f), "caixa_prancha": list(caixa),
                            "estado": estado, "alertas": alertas, "medidas": medidas})
        # onde está o ponto de ancoragem (centro do rótulo, meio da faixa) no frame
        ancora = [meia - corte[0], (alt // 2) - corte[1]]
        manifesto["familias"][nome] = {
            "classe": "B", "derivacao": "cortes nos vales do desenho + alfa reconstruído sobre o fundo medido",
            "cortes_prancha": cortes,
            "uso": uso, "fundo_medido": list(fundo), "tamanho": list(frames[0][0].crop(corte).size),
            "ancora": ancora, "blend": "add", "frames": registo,
        }
    for base, nome in CORRUPCAO.items():
        pasta = SAIDA / nome
        pasta.mkdir(exist_ok=True)
        registo = []
        imagens[nome] = []
        for i, im in enumerate(imagens[base]):
            ic = im.copy()
            q = ic.load()
            for y in range(ic.size[1]):
                for x in range(ic.size[0]):
                    q[x, y] = _corromper(q[x, y])
            imagens[nome].append(ic)
            f = pasta / f"{nome}_{i + 1:02d}.png"
            ic.save(f, optimize=True)
            b = manifesto["familias"][base]["frames"][i]
            registo.append({"ficheiro": f"{nome}/{f.name}", "sha256": sha256(f), "caixa_prancha": b["caixa_prancha"],
                            "estado": b["estado"], "alertas": b["alertas"], "medidas": b["medidas"]})
        manifesto["familias"][nome] = {
            "classe": "C", "derivacao": f"{base} com a luminância na rampa de corrupção {RAMPA}",
            "uso": "corrupção (inimigos, guardiões, Coração)", "tamanho": manifesto["familias"][base]["tamanho"],
            "ancora": manifesto["familias"][base]["ancora"], "blend": "mix", "frames": registo,
        }
    with open(MANIFESTO, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(manifesto, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    _folha(imagens)
    return manifesto


def _folha(imagens: dict[str, list[Image.Image]]) -> None:
    """Folha de revisão: cada família sobre noite escura e sobre verde médio."""
    PREVIEW.mkdir(parents=True, exist_ok=True)
    esc = 2
    linhas = []
    for nome, ims in imagens.items():
        w = sum(i.size[0] for i in ims) * esc + 4 * len(ims)
        h = max(i.size[1] for i in ims) * esc
        for fundo in ((18, 12, 26), (70, 92, 64)):
            ln = Image.new("RGB", (w, h), fundo)
            x = 0
            for im in ims:
                g = im.resize((im.size[0] * esc, im.size[1] * esc), Image.NEAREST)
                ln.paste(g, (x, 0), g)
                x += g.size[0] + 4
            linhas.append(ln)
    W = max(l.size[0] for l in linhas)
    H = sum(l.size[1] + 6 for l in linhas)
    folha = Image.new("RGB", (W, H), (0, 0, 0))
    y = 0
    for l in linhas:
        folha.paste(l, (0, y))
        y += l.size[1] + 6
    folha.save(PREVIEW / "vfx_9g_folha.png")


def validar() -> int:
    m = json.loads(MANIFESTO.read_text(encoding="utf-8"))
    falhas = 0
    total = 0
    review = 0
    if sha256(PRANCHA) != m["autoridade"]["sha256"]:
        print("FAIL autoridade: SHA da prancha 07 mudou")
        falhas += 1
    for nome, fam in m["familias"].items():
        for fr in fam["frames"]:
            total += 1
            p = SAIDA / fr["ficheiro"]
            if not p.exists() or sha256(p) != fr["sha256"]:
                print(f"FAIL {fr['ficheiro']}: ausente ou SHA diferente")
                falhas += 1
                continue
            im = Image.open(p)
            if im.mode != "RGBA":
                print(f"FAIL {fr['ficheiro']}: sem alfa")
                falhas += 1
            if fr["estado"] == "FAIL":
                print(f"FAIL {fr['ficheiro']}: {fr['alertas']}")
                falhas += 1
            elif fr["estado"] == "REVIEW":
                review += 1
                print(f"REVIEW {fr['ficheiro']}: {fr['alertas']} {fr['medidas']}")
    print(f"VFX 9G: {total} frames, {total - falhas - review} PASS, {review} REVIEW, {falhas} FAIL")
    return 1 if falhas else 0


if __name__ == "__main__":
    if "--validar" not in sys.argv:
        produzir()
    sys.exit(validar())
