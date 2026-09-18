# N06 — "Rajadas horizontais" (`Prisao_dos_Condenados.tscn`)

**Referências aprovadas usadas:**
`concept_environment_01.png` e `_02.png` (painel `NÍVEL 6 — RAJADAS
HORIZONTAIS` e painéis de tiles/props/parallax),
`level_mechanics_and_layout.png` (painel N6),
`asset_atlas_level_assets.png` (paleta **N6 CÉU FRIO**),
`asset_atlas_tileset.png` (tiles com vegetação), `enemy_gameplay_pack.png`.

**Fotografias:** `01_inicio` e `02/03/04_jornada_*` (jornada procedural,
x=-8620 a -1200); `05_sala_inicio` a `10_porta` (sala feita à mão, x=240-3250).

## Notas de comparação

- **Bate:** paleta fria azul-violeta; guia de rajada com setas antes da zona
  (a `implementation_sheet` exige-o); bandeira pendurada (a FORMA; a cor é lavanda, rgb 107·98·147, e o cânone pede carmesim); correntes;
  lampião; arco gótico no portal.
- **Falta:** lua; ilhas/castelos flutuantes no fundo; vegetação
  carmesim nas bordas do terreno; estátuas; gárgulas; cristais; braseiros;
  plataformas suspensas por correntes; folhas/detritos levados pelo vento.
- **Errado:** terreno de tijolo de alvenaria uniforme onde a prancha pede
  pedra irregular de falésia; `cruz` e `lapide` (cemitério) como única
  decoração de chão; a banda lisa do abismo (`AguaVenenosa`) a ocupar os ~15%
  de baixo do ecrã, sem textura nem transição.
- **Repetição medida:** `02`, `03` e `04` cobrem 5 200 px de percurso e
  diferem entre si **1,7-2,8** (0-255 por canal); duas fotografias de sítios
  diferentes do mesmo nível diferem **20-25**.
- **Distribuição da mecânica:** 12 710 px de nível, 2 zonas de vento, ambas na
  sala final (~28% do comprimento).

**FIDELITY: LOW.**

## Nota transversal — o mar de nuvens

A camada `nuvens.png` ESTÁ nesta cena e aparece nestas fotografias; o que se
vê como "rocha" no plano médio é ela. Medida a luminância média do fundo
contra a do ficheiro de origem (53%), o que chega ao ecrã tem 10-24%. O
problema não é o asset — é `neblina_fundo` / `dessaturar_fundo` /
`tinta_fundo` da cena e o `cor_fundo` da `Atmosfera`.
