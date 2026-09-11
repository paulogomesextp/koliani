#!/usr/bin/env python3
"""Execution 9B.4 -- pacote completo da Koliani, derivado SÓ do Golden Set.

A autoridade aprovada (prancha 9B.1) só desenha idle/run/jump/fall/ataque.
Os estados em falta são montados reutilizando frames golden INTEIROS, com
transformações sem perda: cópia, translação por píxeis inteiros e rotação
exata de 90° (transpose). Nada é redesenhado, redimensionado nem interpolado.

Saída: assets/sprites/koliani_golden_set/{frames,vfx}/<anim>/ + manifest.json
(schema 2) + entradas novas no production_manifest.json. Relatórios do
validator v2 em work/production_art_gate/9b4/validator/.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ))
from tools.production_asset_validator.validator import (  # noqa: E402
    gerar_contact_sheet, markdown, validar_manifesto)

GS = RAIZ / "assets/sprites/koliani_golden_set"
RELATORIOS = RAIZ / "work/production_art_gate/9b4/validator"
AUTORIDADE = "work/production_art_gate/9b1_game_master_approved/koliani_golden_set_approved.png"
AUTORIDADE_SHA = "0b067780d316d1fcb288c2a3d944cd758a212f8d696c1818ae6ac0e4db0c60c4"
CANVAS = 128
BASE = 103          # última linha opaca
PIVOT = (64, 104)
# Frente do corpo encostada à parede: a colisão tem 20 px de largura, por isso
# a parede fica a +10 px da origem = coluna 74 do canvas.
PAREDE_X = 74
# Rebordo: `global_position.y = lip_y + 34` e os pés ficam a +22 da origem
# (linha 104) -> o rebordo cai na linha 104 - 22 - 34 = 48.
REBORDO_Y = 48

# Cada passo: (frame golden, operação). Operações:
#   "copia"                  -- byte-idêntico
#   ("rot", k)               -- k x 90° no sentido horário, pousado na base
#   ("frente", x)            -- translada até o píxel mais à frente estar em x
#   ("mao", x, y)            -- translada até o píxel mais à frente estar em (x, y)
PACOTE = {
    # 3 frames = DUR_DASH 0,16 s: passada mais longa e a estocada do run.
    "dash":      {"fps": 18.75, "loop": False, "passos": [
        ("run/run_006", "copia"), ("run/run_010", "copia"), ("run/run_010", "copia")]},
    # 6 frames = DUR_ROLAR 0,30 s: agacha, cambalhota compacta (4 x 90°), levanta.
    "roll":      {"fps": 20.0, "loop": False, "passos": [
        ("jump_start/jump_start_001", "copia"),
        ("jump_loop/jump_loop_003", ("rot", 0)), ("jump_loop/jump_loop_003", ("rot", 1)),
        ("jump_loop/jump_loop_003", ("rot", 2)), ("jump_loop/jump_loop_003", ("rot", 3)),
        ("jump_start/jump_start_001", "copia")]},
    # 2 frames = _hurt_t 0,24 s: o sacão de braços/cabelo da queda lê-se como recuo.
    "hurt":      {"fps": 8.333333, "loop": False, "passos": [
        ("fall/fall_001", "copia"), ("fall/fall_002", "copia")]},
    # Colapso até ficar de joelhos; o fade da recarga (0,22 s) fecha logo a seguir.
    "morte":     {"fps": 14.0, "loop": False, "passos": [
        ("fall/fall_001", "copia"), ("jump_start/jump_start_002", "copia"),
        ("jump_start/jump_start_001", "copia")]},
    # A antecipação agachada do salto é a pose de agachar da autoridade.
    "crouch":    {"fps": 6.0, "loop": True, "passos": [("jump_start/jump_start_001", "copia")]},
    # Queda com os braços à frente, encostada à parede.
    "wallslide": {"fps": 6.0, "loop": True, "passos": [
        ("fall/fall_001", ("frente", PAREDE_X)), ("fall/fall_002", ("frente", PAREDE_X))]},
    # Punho à frente ao nível do peito, preso ao canto do rebordo.
    "borda":     {"fps": 5.0, "loop": True, "sem_base": True, "passos": [
        ("jump_start/jump_start_004", ("mao", PAREDE_X, REBORDO_Y))]},
    # Sem o frame agachado de 48 px (o defeito chibi histórico era esse).
    "djump":     {"fps": 10.0, "loop": False, "passos": [
        ("jump_start/jump_start_003", "copia"), ("jump_start/jump_start_004", "copia"),
        ("jump_loop/jump_loop_001", "copia"), ("jump_loop/jump_loop_002", "copia")]},
    # Guarda baixa com a Shadowblade à frente (1.º frame do golpe, antes do corte).
    "defesa":    {"fps": 6.0, "loop": True, "passos": [("attack_basic/attack_basic_001", "copia")]},
}


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def escrever(p: Path, texto: str) -> None:
    p.write_text(texto, encoding="utf-8", newline="\n")


def _bbox(im: Image.Image) -> tuple[int, int, int, int]:
    return im.getchannel("A").getbbox()


def _frente(im: Image.Image) -> tuple[int, int]:
    """Píxel opaco mais à direita (a frente, virada à direita); y = o mais alto."""
    a = im.getchannel("A")
    x = _bbox(im)[2] - 1
    ys = [y for y in range(CANVAS) if a.getpixel((x, y)) > 0]
    return x, ys[0]


def _mover(im: Image.Image, dx: int, dy: int) -> Image.Image:
    bb = _bbox(im)
    if bb[0] + dx < 0 or bb[2] + dx > CANVAS or bb[1] + dy < 0 or bb[3] + dy > CANVAS:
        raise SystemExit(f"ERRO: translação ({dx},{dy}) cortava a figura")
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (dx, dy))
    return out


def _rodar(im: Image.Image, k: int) -> Image.Image:
    fig = im.crop(_bbox(im))
    for _ in range(k):
        fig = fig.transpose(Image.Transpose.ROTATE_270)  # 90° horário = para a frente
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    w, h = fig.size
    out.paste(fig, (PIVOT[0] - w // 2, BASE + 1 - h))
    return out


def aplicar(src: Path, op) -> tuple[Image.Image | None, str]:
    if op == "copia":
        return None, "copy (byte-identical)"
    im = Image.open(src).convert("RGBA")
    if op[0] == "rot":
        return _rodar(im, op[1]), f"lossless rotate {op[1] * 90} deg clockwise, bbox centred on x=64, grounded at y=103"
    fx, fy = _frente(im)
    if op[0] == "frente":
        return _mover(im, op[1] - fx, 0), f"integer translate dx={op[1] - fx} (front edge to wall column {op[1]})"
    dx, dy = op[1] - fx, op[2] - fy
    return _mover(im, dx, dy), f"integer translate dx={dx}, dy={dy} (front hand to ledge corner {op[1]},{op[2]})"


def _manifesto_anim(nome: str, frames: list[str], sem_base: bool, derivacao: list[dict]) -> dict:
    return {
        "schema_version": 2, "character": "Koliani", "animation": nome,
        "frame_count": len(frames), "canvas_width": CANVAS, "canvas_height": CANVAS,
        "pivot_x": PIVOT[0], "pivot_y": PIVOT[1],
        # Pendurada no rebordo os pés não tocam no chão: o contacto são as mãos
        # (linha 48). Sem baseline declarada o validator não a mede.
        "baseline_y": None if sem_base else BASE,
        "baseline_tolerance": 1, "max_scale_ratio": 1.25, "max_bbox_drift": 14,
        "asset_type": "BODY", "expected_alpha": True, "vfx_separate": True,
        "reference_path": AUTORIDADE, "reference_sha256": AUTORIDADE_SHA,
        "authority": [{"file": Path(AUTORIDADE).name, "sha256": AUTORIDADE_SHA}],
        "visual_review_state": "DERIVED_FROM_GAME_MASTER_APPROVED_GOLDEN_SET",
        "runtime_integration_state": "INTEGRATED_9B4",
        "frames": frames, "normalization_scale": 0.3975, "max_pixel_count_ratio": 1.45,
        "source_image": AUTORIDADE, "source_sha256": AUTORIDADE_SHA,
        "godot": {"scale": 1.0, "offset": [0, -18]},
        "derivation": derivacao,
    }


def main() -> int:
    if sha(RAIZ / AUTORIDADE) != AUTORIDADE_SHA:
        print("ERRO: a autoridade canónica não bate com o SHA-256 registado")
        return 2
    producao = json.loads((GS / "production_manifest.json").read_text(encoding="utf-8"))
    golden_sha = {f["path"]: f["sha256"] for f in producao["frames"] if f.get("execution") != "9B.4"}
    producao["frames"] = [f for f in producao["frames"] if f.get("execution") != "9B.4"]
    for nome in PACOTE:
        producao["animations"].pop(nome, None)
    RELATORIOS.mkdir(parents=True, exist_ok=True)
    falhou = False
    for nome, cfg in PACOTE.items():
        dst = GS / "frames" / nome
        dst.mkdir(parents=True, exist_ok=True)
        for velho in dst.glob(f"{nome}_*.png"):
            velho.unlink()
        frames, derivacao = [], []
        for i, (fonte, op) in enumerate(cfg["passos"], 1):
            src = GS / "frames" / f"{fonte}.png"
            rel_src = src.relative_to(RAIZ).as_posix()
            if golden_sha.get(rel_src) != sha(src):
                print("ERRO: frame golden alterado ou fora do manifesto:", rel_src)
                return 3
            alvo = dst / f"{nome}_{i:03d}.png"
            im, descr = aplicar(src, op)
            if im is None:
                alvo.write_bytes(src.read_bytes())
            else:
                im.save(alvo, optimize=True)
            frames.append(alvo.name)
            derivacao.append({"frame": alvo.name, "source": rel_src, "source_sha256": golden_sha[rel_src],
                              "operation": descr})
        man = _manifesto_anim(nome, frames, cfg.get("sem_base", False), derivacao)
        escrever(dst / "manifest.json", json.dumps(man, indent=2, ensure_ascii=False) + "\n")
        rel = validar_manifesto(dst / "manifest.json")
        escrever(RELATORIOS / f"{nome}.json", json.dumps(rel, ensure_ascii=False, indent=2, sort_keys=True))
        escrever(RELATORIOS / f"{nome}.md", markdown(rel))
        gerar_contact_sheet(rel, RELATORIOS / f"{nome}_contact_sheet.png", escala=2)
        estado = rel["animation"]["status"]
        falhou |= estado == "FAIL"
        achados = sorted({x["code"] for x in rel["animation"]["findings"]}
                         | {x["code"] for f in rel["frames"] for x in f["findings"]})
        producao["animations"][nome] = {
            "type": "frames", "frame_count": len(frames), "path": dst.relative_to(RAIZ).as_posix(),
            "fps": cfg["fps"], "loop": cfg["loop"], "source": "DERIVED_FROM_GOLDEN_SET_9B4",
            "validator_v2": estado, "findings": achados}
        por_frame = {f["filename"]: f["status"] for f in rel["frames"]}
        for i, d in enumerate(derivacao, 1):
            p = dst / d["frame"]
            producao["frames"].append({
                "animation": nome, "frame_index": i, "path": p.relative_to(RAIZ).as_posix(),
                "sha256": sha(p), "canvas": [CANVAS, CANVAS], "pivot": list(PIVOT),
                "baseline_y": None if cfg.get("sem_base") else BASE,
                "authority_path": AUTORIDADE, "authority_sha256": AUTORIDADE_SHA,
                "execution": "9B.4", "derived_from": d["source"], "operation": d["operation"],
                "validator_result": por_frame.get(d["frame"], "MISSING")})
        print(f"{nome:10s} {len(frames):2d} frames  validator v2: {estado}  {achados}")
    producao["execution"] = "9B.4"
    escrever(GS / "production_manifest.json", json.dumps(producao, indent=2, ensure_ascii=False) + "\n")
    return 1 if falhou else 0


if __name__ == "__main__":
    sys.exit(main())
