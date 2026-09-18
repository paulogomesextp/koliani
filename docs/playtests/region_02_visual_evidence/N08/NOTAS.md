# N08 — "Ilhas suspensas" (`Corredor_das_Execucoes.tscn`)

**Gameplay LOCKED — não foi tocado nem proposto alterar.**

**Referências aprovadas usadas:** painel `NÍVEL 8 — ILHAS SUSPENSAS`
(`concept_environment_01/02`, `level_mechanics_and_layout`), paleta
**N8 RUÍNAS FLUTUANTES** (`asset_atlas_level_assets`), board de ilhas/ruínas
suspensas do `asset_atlas_tileset` (camadas de parallax).

**Fotografias:** `01_inicio`, `02_ensaio`, `03_ilha1`, `04_ilha2`,
`05_corrente`, `06_ilha3`, `07_elite`, `08_planar` (o vão de 640 px),
`09_ilhavento`, `10_contra`, `11_arena`, `12_porta`.

## Notas de comparação

- **Bate:** ilhas separadas sobre vazio; massas de rocha flutuantes no fundo;
  tochas a marcar as bordas; o vão central como MOMENTO; a melhor leitura de
  altitude da região; setas de vento grandes e inequívocas (a favor à direita,
  contra à esquerda).
- **Falta:** as ilhas do fundo são blocos de rocha, não as ilhas-castelo com
  arquitectura, cascatas e bandeiras da prancha; correntes a
  suspender plataformas; cristais; vegetação; estátuas.
- **Errado:** os "cais" de pedra debaixo das ilhas leem-se como tijolo de
  masmorra visto de baixo, não como rocha partida.
- **Distribuição da mecânica:** 5 620 px, 3 zonas de vento + 1 zona de planar,
  espalhadas pelo percurso inteiro. É o único nível da região assim.

**FIDELITY: MEDIUM.** A ideia estrutural chegou; a aparência das ilhas não.

## Nota transversal — o mar de nuvens

A camada `nuvens.png` ESTÁ nesta cena e aparece nestas fotografias; o que se
vê como "rocha" no plano médio é ela. Medida a luminância média do fundo
contra a do ficheiro de origem (53%), o que chega ao ecrã tem 10-24%. O
problema não é o asset — é `neblina_fundo` / `dessaturar_fundo` /
`tinta_fundo` da cena e o `cor_fundo` da `Atmosfera`.
