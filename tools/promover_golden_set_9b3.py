#!/usr/bin/env python3
"""Execution 9B.3 -- promove o Golden Set extraído (9B.2) para produção.

Cópia byte-a-byte de work/production_art_gate/9b2_extraction/normalized/<anim>/
para assets/sprites/koliani_golden_set/{frames,vfx}/<anim>/, atualiza os
manifestos schema 2, valida com o Production Asset Validator v2 e escreve
assets/sprites/koliani_golden_set/production_manifest.json. Relatórios e contact
sheets ficam fora das pastas de runtime (work/production_art_gate/9b3/).
"""
from __future__ import annotations

import hashlib
import json
import shutil
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ))
from tools.production_asset_validator.validator import (  # noqa: E402
    gerar_contact_sheet, markdown, validar_manifesto)

ORIGEM = RAIZ / "work/production_art_gate/9b2_extraction"
DESTINO = RAIZ / "assets/sprites/koliani_golden_set"
RELATORIOS = RAIZ / "work/production_art_gate/9b3/validator"
AUTORIDADE = RAIZ / "work/production_art_gate/9b1_game_master_approved/koliani_golden_set_approved.png"
AUTORIDADE_SHA = "0b067780d316d1fcb288c2a3d944cd758a212f8d696c1818ae6ac0e4db0c60c4"
ANIMS = {"idle": "frames", "run": "frames", "jump_start": "frames", "jump_loop": "frames",
         "fall": "frames", "attack_basic": "frames", "vfx_slash_basic": "vfx"}
GODOT = {"scale": 1.0, "offset": [0, -18]}


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def escrever(p: Path, texto: str) -> None:
    # LF sempre: no Windows o write_text() mete CRLF e o repo é LF
    p.write_text(texto, encoding="utf-8", newline="\n")


def main() -> int:
    if sha(AUTORIDADE) != AUTORIDADE_SHA:
        print("ERRO: a autoridade canónica não bate com o SHA-256 registado")
        return 2
    meta = json.loads((ORIGEM / "reports/extraction_meta.json").read_text(encoding="utf-8"))
    escala = meta["uniform_scale"]
    RELATORIOS.mkdir(parents=True, exist_ok=True)
    producao = {"schema_version": 1, "execution": "9B.3", "character": "Koliani",
                "visual_authority": {"status": "GAME MASTER APPROVED",
                                     "path": AUTORIDADE.relative_to(RAIZ).as_posix(),
                                     "sha256": AUTORIDADE_SHA},
                "low_height_frames": {"status": "POSE-JUSTIFIED / ACCEPTED",
                                      "rule_59px": "REVIEW ALERT ONLY",
                                      "frames": ["jump_start_001", "jump_loop_001", "jump_loop_003",
                                                 "attack_basic_001", "attack_basic_002", "attack_basic_003",
                                                 "attack_basic_005", "attack_basic_006"]},
                "contract": {"canvas": [128, 128], "pivot": [64, 104], "baseline_y": 103,
                             "facing": "right", "normalization_scale": escala, "godot": GODOT},
                "animations": {}, "frames": []}
    falhou = False
    for anim, tipo in ANIMS.items():
        src = ORIGEM / "normalized" / anim
        dst = DESTINO / tipo / anim
        dst.mkdir(parents=True, exist_ok=True)
        man = json.loads((dst / "manifest.json").read_text(encoding="utf-8"))
        for nome in man["frames"]:
            shutil.copyfile(src / nome, dst / nome)
            if sha(src / nome) != sha(dst / nome):
                print("ERRO: cópia não idêntica", nome)
                return 3
        man.update(normalization_scale=escala, max_pixel_count_ratio=1.45,
                   visual_review_state="GAME_MASTER_APPROVED",
                   runtime_integration_state="INTEGRATED_9B3",
                   source_image=AUTORIDADE.relative_to(RAIZ).as_posix(), source_sha256=AUTORIDADE_SHA,
                   godot=GODOT)
        man.pop("validator_result", None)
        escrever(dst / "manifest.json", json.dumps(man, indent=2, ensure_ascii=False) + "\n")
        rel = validar_manifesto(dst / "manifest.json")
        escrever(RELATORIOS / f"{anim}.json", json.dumps(rel, ensure_ascii=False, indent=2, sort_keys=True))
        escrever(RELATORIOS / f"{anim}.md", markdown(rel))
        gerar_contact_sheet(rel, RELATORIOS / f"{anim}_contact_sheet.png", escala=2)
        estado = rel["animation"]["status"]
        falhou |= estado == "FAIL"
        achados = sorted({x["code"] for x in rel["animation"]["findings"]}
                         | {x["code"] for f in rel["frames"] for x in f["findings"]})
        producao["animations"][anim] = {"type": tipo, "frame_count": len(man["frames"]),
                                        "path": dst.relative_to(RAIZ).as_posix(),
                                        "validator_v2": estado, "findings": achados}
        por_frame = {f["filename"]: f["status"] for f in rel["frames"]}
        for i, nome in enumerate(man["frames"], 1):
            producao["frames"].append({
                "animation": anim, "frame_index": i,
                "path": (dst / nome).relative_to(RAIZ).as_posix(), "sha256": sha(dst / nome),
                "canvas": [128, 128], "pivot": [64, 104], "baseline_y": 103,
                "authority_path": AUTORIDADE.relative_to(RAIZ).as_posix(), "authority_sha256": AUTORIDADE_SHA,
                "validator_result": por_frame.get(nome, "MISSING")})
        print(f"{anim:16s} {len(man['frames']):2d} frames  validator v2: {estado}  {achados}")
    escrever(DESTINO / "production_manifest.json", json.dumps(producao, indent=2, ensure_ascii=False) + "\n")
    print("total", len(producao["frames"]))
    return 1 if falhou else 0


if __name__ == "__main__":
    sys.exit(main())
