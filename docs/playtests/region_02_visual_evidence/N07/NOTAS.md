# N07 — "Correntes ascendentes" (`Fornalha_dos_Pecadores.tscn`)

**Referências aprovadas usadas:** painel `NÍVEL 7 — CORRENTES ASCENDENTES`
(`concept_environment_01/02`, `level_mechanics_and_layout`,
`asset_atlas_level_assets` paleta **N7 VENTOS LUMINOSOS**), FX
`CORRENTE ASCENDENTE (UPDRAFT)` do `enemy_gameplay_pack`.

**Fotografias:** `01_inicio`, `02/03_jornada_*`; `04_sala_inicio`,
`05_updraft`, `06_correntes`, `07_elite`, `08_arena`, `09_porta`.

## Notas de comparação

- **Bate:** as três colunas ascendentes leem-se como COLUNAS, com setas para
  cima e princípio/fim visíveis — é a melhor leitura de mecânica da região;
  paleta mais clara do que o N06, como a prancha pede; uma torre partida ao
  fundo.
- **Falta:** as "torres destruídas" que a prancha dá como AMBIENTE do nível
  (há uma silhueta, não um cenário); nuvens; lua; vitrais; cristais;
  vegetação; detritos a subir dentro da corrente.
- **Errado:** a coluna é um traço branco liso; a prancha desenha um feixe
  volumétrico azul-branco com partículas. As velas amarelas de `09_porta`
  flutuam sem suporte visível.
- **Distribuição da mecânica:** 13 880 px, 3 updrafts, todos na sala final.

**FIDELITY: MEDIUM.**

## Nota transversal — o mar de nuvens

A camada `nuvens.png` ESTÁ nesta cena e aparece nestas fotografias; o que se
vê como "rocha" no plano médio é ela. Medida a luminância média do fundo
contra a do ficheiro de origem (53%), o que chega ao ecrã tem 10-24%. O
problema não é o asset — é `neblina_fundo` / `dessaturar_fundo` /
`tinta_fundo` da cena e o `cor_fundo` da `Atmosfera`.
