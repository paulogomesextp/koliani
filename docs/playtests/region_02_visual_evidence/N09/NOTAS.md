# N09 — "Vento variável" (`Ala_dos_Mortos.tscn`)

**Referências aprovadas usadas:** painel `NÍVEL 9 — VENTO VARIÁVEL`
(`concept_environment_01/02`, `level_mechanics_and_layout`), paleta
**N9 CREPÚSCULO** (`asset_atlas_level_assets`), ambiente "ruínas
atmosféricas".

**Fotografias:** `01_inicio`, `02/03/04_jornada_*`; `05_sala_inicio`,
`06_vento_entrada`, `07_elite`, `08_vento_combate`, `09_subida`, `10_arena`,
`11_porta`.

## Notas de comparação

- **Bate:** **a paleta** — é o único nível cuja cor própria (crepúsculo
  rosa-malva) bate com a paleta por nível da `asset_atlas_level_assets`;
  setas de vento grandes e claras; vento a favor / contra / a favor como
  estrutura do nível.
- **Falta:** as "ruínas atmosféricas" que dão nome ao ambiente (há montes de
  rocha e uma silhueta de muralha, não ruínas); nuvens; lua; cristais;
  vegetação; estátuas; gárgulas.
- **Errado:** os inimigos (`mastim`, `orc`, `chort`) são cães e brutos
  terrestres num nível cuja identidade é o ar.
- **Nota de método:** `01_inicio` e `02_jornada_a` saíram quase idênticas
  (diferença 0,96). Não é possível separar "cenário repetido" de "a Koliani
  caiu e voltou ao checkpoint" nesse par, por isso **esse par não é usado como
  prova**; a repetição só é afirmada onde foi medida (N06).
- **Distribuição da mecânica:** 16 360 px (o mais longo da região), 3 zonas de
  vento, todas na sala final.

**FIDELITY: LOW.**

## Nota transversal — o mar de nuvens

A camada `nuvens.png` ESTÁ nesta cena e aparece nestas fotografias; o que se
vê como "rocha" no plano médio é ela. Medida a luminância média do fundo
contra a do ficheiro de origem (53%), o que chega ao ecrã tem 10-24%. O
problema não é o asset — é `neblina_fundo` / `dessaturar_fundo` /
`tinta_fundo` da cena e o `cor_fundo` da `Atmosfera`.
