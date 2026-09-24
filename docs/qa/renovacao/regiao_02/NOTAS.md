# Renovacao — Regiao II (Desfiladeiro dos Ventos, N06-N10) — 25 set 2026

Autoridade visual: `docs/art_direction/regions/region_02/` (concept_environment_01/02,
asset_atlas_*, level_mechanics_and_layout, contrato do Guardiao).

## O que entrou nesta ronda
1. Merge do remodel (`claude/region02-total-remodel`, prompts 2-3: mar de nuvens,
   silhueta por nivel, arquitetura de primeiro plano, landmark por nivel, lua/torre
   no N10) — estava fora do `master`.
2. Prompt 4 (parcial): **R7 anti-repeticao** — campo `niveis` por prop em `deco.json`
   (`tools/distribuir_props_regiao02.py`); nenhum prop em mais de 2 dos 5 niveis
   (a gargula estava em 3). Filtro em `plataforma.gd`, `gerador_corredor.gd`, `atmosfera.gd`.
3. Prompt 4: **R6 FX** — aurora e raios distantes (luz aditiva na camada do ceu,
   so' com `perfil_altitude`; RNG local, nao toca no `_rng` funcional).

## Provas
- `tools/baseline_geometria.gd` N06-N10 antes/depois: **5/5 IGUAIS**, 0 SCRIPT ERROR.
- `verifica_arquitetura_regiao02`: 5 niveis, 0 falhas.
- Suite: exit 0, 1x "OK -- todos os testes passaram", 0 SCRIPT ERROR, save real intacto.
- Capturas: `antes_*` (HEAD 9bca094f) e `depois_*` (inicio, meio, final) — janela real, 1280x720.

## Armadilhas
- O JSON traz floats: comparar `niveis` com `float(n)`.
- Um comentario colado antes do `:` de um `if` parte a compilacao do gerador e o
  baseline em `--script` "mede" um mundo diferente (parse error -> geometria a mudar).

## POLISH / por fazer (nao bloqueia)
- Variacoes de terreno com vinhas/gelo extraidas das pranchas (R5), franja de vinhas.
- `arvore_seca` da parede pixelada ao ser ampliada (N06).
- Aurora discreta (alpha 0.10-0.16); afinar so' com playtest humano.
- Guardiao dos Ceus: ja fechado na A2; auditoria eixo a eixo (Prompt 6) por fazer.
- **HUMAN PLAYTEST REQUIRED** (composicao em movimento).
