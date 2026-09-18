# REGION II — APPROVED VISUAL REFERENCE MAP

Inventário canónico da Região II (Desfiladeiro dos Ventos, níveis 06-10),
lido DOS FICHEIROS, não de memória. Fonte: `docs/art_direction/regions/region_02/`
(8 pranchas PNG, 1536x1024 cada), `docs/art_direction/KOLIANI_REGION_CANON.md`,
`docs/art_direction/REGIONS_INDEX.md`, `region_02/README.md` e
`region_02/GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md`.

Este mapa é o TERMO DE COMPARAÇÃO do audit. Tudo o que está em **LOCKED**
vem desenhado ou escrito na fonte aprovada; tudo o que está em
**INTERPRETATION FLEX** é decisão técnica livre.

---

## 1. Ficheiros aprovados e o que cada um manda

| Ficheiro | Função | Aplica-se a | Autoridade sobre |
|---|---|---|---|
| `concept_environment_01.png` | prancha-mãe do ambiente | N06-N10 | tiles, plataformas, props, elementos de vento, bestiário, boss, 4 camadas de parallax, paleta da região, 5 mockups de gameplay (um por nível) |
| `concept_environment_02.png` | segunda prancha-mãe | N06-N10 | o mesmo, com 5 camadas de parallax e 2 poses de ataque da Koliani |
| `level_mechanics_and_layout.png` | mapas e mecânicas | N06-N10 | foco/mecânica/ambiente/desafio/segredos por nível, mapa esquemático por nível, 18 tiles de terreno, 8 plataformas especiais, 13 mecânicas, 14 hazards, 14 props, 6 elementos narrativos, 12 FX |
| `asset_atlas_tileset.png` | tileset completo | N06-N10 | chão/bordas/cantos/rampas/paredes/plataformas/meio-bloco/declives, 5 variações temáticas, estruturas, props, vegetação, hazards, coleccionáveis, 5 camadas de parallax |
| `asset_atlas_level_assets.png` | assets por nível | N06-N10 | **identidade e paleta PRÓPRIA de cada nível** (N6 céu frio, N7 ventos luminosos, N8 ruínas flutuantes, N9 crepúsculo, N10 torre final), 21 mecânicas, 18 hazards, props, FX, 4 camadas de parallax |
| `enemy_gameplay_pack.png` | bestiário | N06-N10 | **10 inimigos canónicos** com estados nomeados, hazards ambientais, interactivos, destrutíveis, FX |
| `boss_pack.png` | **autoridade primária do chefe** | N10 | conceito e 6 poses, escala contra figura humana, 6 animações nomeadas, 3 poses de dano/morte, 8 padrões de ataque, 11 FX, 36 amostras de paleta, arena e seus elementos |
| `implementation_sheet.png` | guia de implementação | N06-N10 | estrutura de pastas/nomes, tipos de asset e sinais visuais, resumo por nível, checklist e parâmetros sugeridos |

Não há referência aprovada para o **N05** (é da Região I, Floresta
Corrompida) — daí ser o CONTROLO deste processo, e não referência visual.

---

## 2. LOCKED VISUAL FEATURES (região)

### L-R1 — Identidade e leitura
Falésias abertas e ruínas góticas antigas suspensas sobre um **mar de
nuvens**; céu com **lua grande (rosa/sangue)**; o mundo lê-se **partido e
alto**. Lema das pranchas: "MAIS ALTO. SEMPRE MAIS ALTO."

### L-R2 — Paleta
`CÉU · NÉVOA · ROCHA · RUÍNAS · VEGETAÇÃO · ACENTOS · CRISTAIS · FX VENTO ·
DETALHES` (faixa de 9 famílias em `level_mechanics_and_layout.png`). Os
acentos são **carmesim/vermelho** (bandeiras, vegetação, pontas de pena) e
**violeta** (cristais, magia); o FX de vento é **branco-azul-gelo**. Cinzento
pedra + índigo/lilás nas ruínas e no céu.

### L-R3 — Materiais de terreno
Pedra em blocos com junta visível, **vinhas e folhagem carmesim** a cair das
bordas, cantos e rampas próprios, paredes verticais, meio-blocos, declives,
variações: NORMAL · COM VEGETAÇÃO · DESTRUÍDO · COM CRISTAIS · NEVE/GELO.

### L-R4 — Arquitectura
Arcos góticos, **janelas ogivais com vitral**, colunas em ruínas, pontes de
pedra e de corda, torres partidas, muralhas, plataformas suspensas por
**correntes**.

### L-R5 — Props obrigatórios
**Estátuas** encapuçadas, **gárgulas**, **bandeiras carmesim com cruz**,
**correntes**, **lanternas e braseiros acesos**, urnas, vasos, cercas,
escombros, **cristais violeta**, vegetação carmesim, árvores secas.

### L-R6 — Parallax
4 a 5 camadas nomeadas: silhuetas distantes → montanhas e ruínas → castelos
/ ilhas flutuantes → nuvens e vento → detalhes próximos. As nuvens são um
elemento **estrutural**, não uma névoa: vêem-se volumes de nuvem entre as
ilhas em todas as pranchas.

### L-R7 — FX de vento (elemento identitário da região)
Rajadas horizontais em linhas finas, correntes ascendentes em coluna com
setas, turbilhões/tornados em espiral, folhas e detritos carmesim
arrastados, poeira no ar, névoa baixa, raios distantes, aurora no céu.
**O vento VÊ-SE** — a `implementation_sheet` põe "direcção do vento bem
visível (antes da zona de vento)" como sinal obrigatório.

### L-R8 — Bestiário canónico (10 criaturas)
`MORCEGO DOS VENTOS` · `SENTINELA FLUTUANTE` · `GAIVOTA SOMBRIA` ·
`GOLEM AÉREO` · `MAGO DO VENTO` · `SERPENTE EÓLICA` · `ESPECTRO DAS RUÍNAS` ·
`ARQUEIRO EÓLICO` · `TORRE VIGIA` · `ELEMENTAL DO VENTO`.
Todos voam, levitam, disparam vento ou são feitos de vento. **Nenhum é um
bicho de masmorra terrestre.**

### L-R9 — Identidade por nível
| Nível | Nome na prancha | Foco | Mecânica | Ambiente | Paleta própria |
|---|---|---|---|---|---|
| N06 | RAJADAS HORIZONTAIS | rajadas e precisão | vento de impulso, plataformas móveis | falésias abertas | céu frio |
| N07 | CORRENTES ASCENDENTES | correntes verticais | correntes, salto e timing | torres destruídas | ventos luminosos |
| N08 | ILHAS SUSPENSAS | plataformas instáveis | plataformas que aparecem/desaparecem | ilhas flutuantes | ruínas flutuantes |
| N09 | VENTO VARIÁVEL | combinação de mecânicas | vento variável, plataformas móveis | ruínas atmosféricas | crepúsculo |
| N10 | TORRE DOS CÉUS | aproximação ao chefe | todas as anteriores | torre celestial | torre final |

### L-R10 — Chefe (ver contrato dedicado)
`GUARDIÃO DOS CÉUS`: corvídeo/rapina colossal, asas abertas como elemento
mais largo, bico curvo dourado, garras douradas, **olho = núcleo** violeta
na cabeça, penas índigo com **pontas carmesim**, cauda longa. Escala
2,6x a Koliani em altura, 3,5-3,7x em largura. Arena: plataformas suspensas
sobre mar de nuvens, **lua de sangue**, torres góticas partidas, estandartes
carmesins, correntes, braseiros, colunas em ruínas, cristais.

---

## 3. INTERPRETATION FLEX

- número de frames por estado e resolução de sprite;
- forma exacta de cada pena, folha ou bloco dentro da silhueta;
- detritos/plumas decorativos (podem existir ou não);
- tom exacto do rim-light dentro da família violeta;
- ritmo e timings de combate (**não é arte** — já aprovado);
- disposição concreta das plataformas: os mapas esquemáticos das pranchas
  são intenção de ritmo, não coordenadas;
- quais dos 10 inimigos aparecem em que nível;
- colisões (o contrato do Guardião proíbe explicitamente mexer-lhes).

---

## 4. Onde cada nível do JOGO vive (mapa ficheiro ↔ nível)

Os nomes de ficheiro são da antiga Prisão dos Condenados e foram mantidos
de propósito (mudá-los partia saves e checkpoints — ver commit `8431d887`).

| Nível | Índice `EstadoJogo.NIVEIS` | Ficheiro de cena | Encontro final |
|---|---|---|---|
| N05 (controlo, Região I) | 4 | `Coracao_da_Floresta.tscn` | chefe da Região I |
| N06 | 5 | `Prisao_dos_Condenados.tscn` | Guardião: Golem das Falésias |
| N07 | 6 | `Fornalha_dos_Pecadores.tscn` | Guardião: Vigia do Desfiladeiro |
| N08 | 7 | `Corredor_das_Execucoes.tscn` | Guardião: Feiticeira dos Ventos |
| N09 | 8 | `Ala_dos_Mortos.tscn` | Guardião: Espectros Gémeos |
| N10 | 9 | `A_Cela_Zero.tscn` | **Chefe: Guardião dos Céus** |
