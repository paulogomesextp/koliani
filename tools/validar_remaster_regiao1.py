"""Valida o contrato de arte/planos da Região I sem alterar mapas."""
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
SLOTS = {"far_background", "mid_background", "gameplay_terrain",
         "front_silhouettes", "atmospheric_vfx", "landmark_layers"}


def validar():
    dados = json.loads((RAIZ / "data/regiao1/remaster.json").read_text(encoding="utf-8"))
    assert dados["schema"] == 1 and dados["regiao"] == 1, "Schema/região inválidos"
    assert set(dados["slots"]) == SLOTS, "São necessários os seis slots"
    assert set(dados["niveis"]) == {str(i) for i in range(1, 6)}, "Âmbito L1–L5"
    for slot in dados["slots"].values():
        assert len(slot["parallax"]) == 2 and -4096 <= slot["z"] <= 4096
    for chave, nivel in dados["niveis"].items():
        assert nivel["level_id"] == f"level_{int(chave):03d}"
        assert nivel["tema"] and set(nivel["camadas"]) == SLOTS
        perfil = nivel["visual_atual"]
        for campo in ("corrupcao", "nevoa", "ruinas", "cascatas", "lanternas", "densidade"):
            assert isinstance(perfil[campo], (float, int)) and perfil[campo] >= 0
        assert len(perfil["tinta"]) == 3 and 0 <= perfil["forca_tinta"] <= 1
        plano = nivel["plano_mapa"]
        assert plano["aplicar_geometria"] is False, "Esta execução não aplica geometria"
        assert plano["colunas"]["alterar_colisoes"] is False
        assert {"spawn", "checkpoints", "porta", "arena", "jogabilidade_base"} <= set(plano["preservar"])
        for plataforma in plano["plataformas_adicionais"]:
            lo, hi = plataforma["zona"]
            assert 0 <= lo < hi <= 1, "Zona de progressão inválida"
        for marco in plano["landmarks"]:
            assert marco["slot"] in SLOTS and 0 <= marco["progresso"] <= 1
        for entradas in nivel["camadas"].values():
            for entrada in entradas:
                assert ("textura" in entrada) != ("cena" in entrada), "Escolher textura OU cena"
                caminho = entrada.get("textura", entrada.get("cena"))
                assert caminho.startswith("res://assets/"), "Assets de produção vivem em assets/"
                absoluto = (RAIZ / caminho.removeprefix("res://")).resolve()
                assert absoluto.is_relative_to(RAIZ / "assets") and absoluto.is_file()
                if "cena" in entrada:
                    assert absoluto.suffix == ".tscn", "Cena VFX deve ser tscn"
        print(f"L{chave}: {nivel['tema']}; seis slots; plano inativo; {len(plano['landmarks'])} landmarks planeados")
    print("Região I remaster: contrato PASS; geometria futura requer validação própria")


if __name__ == "__main__":
    validar()
