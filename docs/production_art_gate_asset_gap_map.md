# Production Art Gate — mapa de lacunas de assets

Data: 11 de setembro de 2026
Companheiro de
[production_art_gate_9a_authority_inventory.md](production_art_gate_9a_authority_inventory.md).

Regra que atravessa o documento inteiro: **asset de produção em falta nunca
reabre uma decisão de desenho aprovada**. Onde se lê **D**, o desenho está
decidido e só falta produzir.

Legenda: **A** aprovado/congelado · **B** implementado e de produção ·
**C** implementado, legado a substituir · **D** desenho aprovado, asset em
falta · **E** asset existe, não integrado · **F** bloqueio técnico ·
**G** decisão nova necessária.

## Prioridade 1 — Koliani

### 1.1 Locomoção — parcialmente resolvida

| Animação | Frames | Autoridade | Asset actual | Classe |
|---|---|---|---|---|
| `idle` | 10 | prancha 05 | `koliani_visual_pilot_5g/idle.png` | **E→B** |
| `run` | 12 | prancha 05 | `run.png` | **E→B** |
| `turn` | 4 | prancha 05 | `turn.png` | **E→B** |
| `run_start` | 6 | prancha 05 | `run_start.png` | **E→B** |
| `jump_start` | 4 | pranchas 05/06 | `jump_start.png` | **E→B** |
| `jump_loop` | 4 | pranchas 05/06 | `jump_loop.png` | **E→B** |
| `fall` | 4 | pranchas 05/06 | `fall.png` | **E→B** |
| `run_brake` | 6 | prancha 05 | **montado por fallback** | **D** |
| `land` | 6 | prancha 06 | **montado por fallback** | **D** |

**Estado técnico dos 7 que existem:** canvas 160×96, pivot (80, 90), última
linha opaca = 89 em 7/7, RGBA com alfa binário 0/255, sem legendas, sem xadrez,
pernas e pés completos, VFX não fundido. **Tecnicamente seguros — não
declarados visualmente finais.**

**Porque é que `land` e `run_brake` estão bloqueados:** a recuperação em
`work/koliani_extraction_recovery_medium/reports/recovery_report.md` marca 11
frames como `VFX_SEPARATION_REQUIRED` — `run_brake_02..06` e `land_01..06`. A
poeira e o impacto tocam a personagem na prancha de origem e não há informação
observável para reconstruir o que está por baixo. É um **F na fonte** que se
traduz num **D no jogo**: ou se desenham os 12 frames, ou a fonte tem de vir
com o VFX já separado.

### 1.2 Combate e interacções — a lacuna maior do projecto

| Animação | Frames pedidos | Autoridade | Asset actual | Classe |
|---|---|---|---|---|
| `attack_1` slash | 8 | prancha 03 | `koliani_premium_v1/attack.png` | **C** |
| `attack_2` spin slash | 8 | prancha 03 | `attack2.png` | **C** |
| `attack_3` heavy slash | 10 | prancha 03 | `attack3.png` | **C** |
| `attack_4` dash strike | 8 | prancha 03 | `attack4.png` | **C** |
| `finisher` | 12 | prancha 03 | não existe | **D** |
| `projectile / launch` | 8 | prancha 03 | reusa `attack` | **D** |
| `hurt` | 6 | prancha 03 | `hurt.png` | **C** |
| `death` | 8 | prancha 03 | `morte.png` | **C** |
| `dash` / `dash_end` | 8 / 6 | prancha 04 | `dash.png` | **C** |
| `roll / dodge` | 8 | prancha 04 | `roll.png` | **C** |
| `crouch` / `crouch_walk` / `stand_up` | 4 / 6 / 4 | prancha 04 | só `crouch.png` | **C** / **D** |
| `wall_slide` / `wall_jump` / `wall_climb` | 6 / 8 / 8 | prancha 04 | só `wallslide.png` | **C** / **D** |
| `ledge_grab` / `ledge_climb` / `ledge_drop` | 6 / 8 / 4 | prancha 04 | só `borda.png` | **C** / **D** |
| `push` / `pull` / `switch_lever` | 6 / 6 / 4 | prancha 04 | não existe | **D** |
| `shield / defend` | 6 | prancha 04 | `defesa.png` | **C** |
| `hold / charge`, `aura_idle`, `telepawn` | 8 / 6 / 8 | prancha 04 | não existe | **D** |
| `prone / slide`, `get_up` | 6 / 6 | prancha 04 | não existe | **D** |

**Todo o `koliani_premium_v1` é C, e por motivos concretos, não por gosto:**

1. **rabo-de-cavalo** — o contrato congelado exige cabelo sempre comprido e
   **completamente solto**, sem rabo-de-cavalo e sem fita;
2. cabelo **roxo com lenço encarnado**, em vez de raízes pretas com pontas
   vermelhas;
3. **VFX fundido no corpo** — o arco violeta do golpe está pintado dentro dos
   frames de `attack`, `attack2`, `attack3`, `attack4` e `dash`;
4. derivado de *checkerboard baked* por remoção automática de fundo;
5. linha de base inconsistente entre animações (79, 80, 88, 89, 90).

Medido por `tools/validate_assets.py`: **PASS=0 FAIL=16**.

**Impacto no jogador, hoje, na build aprovada:** parado e a correr vê a Koliani
certa; a atacar, a fazer dash ou a morrer vê outra personagem. É esta a causa
técnica da leitura de *«ainda parece antigo»*.

### 1.3 Pacote contratado — 0/40

`assets/sprites/koliani_production/production_contract.json` pede 40 frames de
corpo (`idle` 10, `run` 12, `jump_start` 4, `jump_loop` 4, `fall` 4, `land` 6)
e 7 conjuntos de VFX separados. Existem **0 frames** — as pastas
`frames/*` e `vfx/*` têm só `.gitkeep`. Só o `master/koliani_master_right.png`
existe, e está marcado `HUMAN VISUAL REVIEW REQUIRED`.
Estado do contrato: `BLOCKED_UNTIL_40_FRAMES_TECHNICALLY_VALID`.

### 1.4 VFX da Koliani — 0 produzidos

A prancha 07 define **16 conjuntos**: `slash_arc`, `spin_slash`, `heavy_slash`,
`dash_trail`, `dash_impact`, `roll`, `hit_sparks`, `finisher_burst`,
`hurt_blood`, `jump_land_impact`, `projectile`, `charge_aura`, `defend_shield`,
`teleport_portal`, `pickup`, `death_dissolve`. **Nenhum existe como asset.**

O que existe em `assets/sprites/pixel/fx/` são projécteis e impactos do pack
CC0 bdragon1727 (**C**). O rasto da Shadowblade que se vê no jogo é
**desenhado por código** em `scripts/koliani.gd` — não é asset. O único VFX de
lâmina em forma de imagem está **pintado dentro dos frames da `premium_v1`**,
exactamente ao contrário do contrato.

## Prioridade 2 — Kit modular de ambiente da Região I

| Domínio | Autoridade | Asset activo | Classe | Candidato |
|---|---|---|---|---|
| Panorama / Heart Tree distante | 08 | `region1_panorama_heart_tree.png` + 2 caps | **B** | — |
| Camadas de parallax separadas (4) | 08 | nenhuma | **D** | — |
| Nevoeiro / névoa volumétrica | 08 / 10 | `Atmosfera.tscn` por código | **C** | — |
| Silhuetas de primeiro plano | 08 | nenhuma | **D** | — |
| `platform tops` | 10 | `terreno/floresta/topo.png` | **C** | `terrain_top.png` (**E**) |
| `platform bodies` | 10 | `corpo.png` | **C** | `terrain_fill.png` (**E**) |
| `platform edges` | 10 | `lado.png` | **C** | `terrain_edge_left/right.png` (**E**) |
| `inner corners` | 10 | nenhum | **D** | `terrain_corner_inner.png` (**E**) |
| `outer corners` | 10 | nenhum | **D** | `terrain_corner_outer.png` (**E**) |
| `ground` | 10 | `base.png` | **C** | — |
| plataformas pequenas / grandes | 10 | `Plataforma.tscn` por código | **C** | `platform_small`, `platform_large_segment` (**E**) |
| `moss` | 10 | nenhum | **D** | `moss_overlay.png` (**E**) |
| `roots` | 08 / 10 | `deco/floresta/raiz.png` | **C** | `root_overlay.png` (**E**) |
| `rocks` | 10 | `deco/floresta/pedra_musgo.png` | **C** | — |
| `vegetation` | 10 | 17 props em `deco/floresta/` | **C** | — |
| `ruins` | 08 / 10 | nenhum | **D** | `ruin_block.png` (**E**) |
| `arches` | 08 / 10 | nenhum | **D** | — |
| `lanterns` (acento quente) | 08 / 10 | nenhum | **D** | — |
| `props` interactivos | 10 | nenhum | **D** | — |
| `corruption growth` | 08 | nenhum | **D** | `corruption_overlay.png` (**E**) |
| `waterfall elements` | 08 / 10 | nenhum | **D** | — |
| `foreground` / `midground` / `background` | 08 | parcial (panorama) | **D** | — |
| `fog/mist layers` | 08 / 10 | por código | **C** | — |
| suporte de iluminação | 10 | `Atmosfera.tscn` | **C** | — |

**O terreno activo da Região I são 4 peças** — `topo`, `corpo`, `lado`, `base`
— geradas por `tools/gerar_terreno.py` a partir do pack CC0 *anokolisa*.
Funciona, lê-se, e **não vem da autoridade aprovada**. É **C**.

**As 12 peças candidatas** em
`assets/art/regions/region_01_forest/production/terrain|overlays|props/` estão
**tecnicamente validadas e por aprovar visualmente**, não estão ligadas a
nenhuma cena e **não estão no build** (verificado por varrimento do PCK e do
EXE: `terrain_top` = 0 ocorrências). São **E**. A fonte declarada é
`_source/imagegen_v1`, excluída dos exports.

**Uma prancha composta não é um kit modular.** A 10 mostra tilesets completos
com chão, plataformas, paredes, cantos, declives, variações e detalhes; o que
existe cobre chão, plataformas, cantos e três overlays. Faltam paredes,
declives, variações, detalhes, pontes, cercas, postes/lanternas, bandeiras,
altar e cascatas modulares.

**Preservar a geometria.** A composição e o layout de plataformas dos níveis
L1–L5 não mudam. Arte de produção substitui apresentação, não desenho de nível.

## Prioridade 3 — Inimigos e guardiões da Região I

**Não existe autoridade visual aprovada.** Nenhuma das 12 pranchas desenha
inimigos ou guardiões. A autoridade escrita é
`Koliani_1.0_Master_Package_v2/docs/design/BOSSES_ENEMIES.md`.

| Alvo | Sprites actuais | Animações | Classe | Runtime |
|---|---|---|---|---|
| Inimigos comuns (`goblin`, `gosma`, `mushroom`, `besouro`, `lodo`) | `assets/sprites/pixel/enemies/<espécie>/` | por espécie | **C** | activos, 1 espécie por nível |
| Ghorak (L1) | `bosses_anim/ghorak/` | `idle`, `walk`, `attack`, `hurt`, `death` | **C** | activo |
| Morvanna (L2) | `bosses_anim/morvanna/` | as mesmas 5 | **C** | activo |
| Rainha Aracnídea (L3) | `bosses_anim/rainha_aracnidea/` | as mesmas 5 | **C** | activo |
| Entrevane (L4) | `bosses_anim/entrevane/` | as mesmas 5 | **C** | activo |

Os quatro guardiões têm silhueta própria e rig animado, vindos do motor de arte
de chefes. Alfa e consistência de frames servem o gameplay. **Não há evidência
de que satisfaçam qualidade de produção aprovada** — e não há prancha contra a
qual medir. Ficam **C**, como manda a secção 12.

Em falta: telégrafos legíveis, separação de VFX, leitura de impacto e fases
finais.

## Prioridade 4 — Coração Putrefacto (L5)

**Também sem prancha aprovada.** Não redesenhar em 9A.

| Subdomínio | Estado | Classe |
|---|---|---|
| Corpo | `bosses/coracao.png` + `bosses_anim/coracao_putrefacto/` (5 animações) | **C** |
| Ataques | `scripts/chefe_coracao_putrefacto.gd` | **C** |
| Fase 2 (aos 50%) | activa | **C** |
| Raízes | activas | **C** |
| Projécteis | pack CC0 | **C** |
| Pulso radial / gravitacional | por código | **C** |
| Telégrafos | por código, sem asset | **C** |
| Morte | rebentamento por código | **C** |
| Baú / recompensa | idempotente, recompõe a saída após reload | **C** |
| VFX próprios | nenhum | **D** |
| Apresentação áudio | camas + SFX por arquétipo | **C** |

## Prioridade 5 — UI, menu, HUD

**Não classificar como visualmente completo por existirem nós e código.** A
observação do Game Master — *«Menu está igual»* — é autoritária.

| Ecrã / elemento | Autoridade | Asset actual | Classe |
|---|---|---|---|
| Menu principal | 09 §4 | `assets/branding/menu_bg.png` (key art) + botões de sistema | **C** |
| Selecção de região | 09 §6 | `MapaMundo.tscn` com progresso | **C** |
| Selecção de nível | 09 §5 | `SeletorNiveis.tscn`, cartões básicos | **C** |
| HUD | 09 §1 | peças de `assets/ui/` geradas por `tools/gerar_ui.py` | **C** |
| Vida | 09 §1–2 | `ico_coracao.png` / `ico_coracao_vazio.png` | **C** |
| Energia | 09 §2 | barra genérica | **C** |
| Moeda / Essência | 09 §1 | `ico_losango.png` | **C** |
| Diálogo | 09 §9 / 11 §3 | balão em `scripts/balao.gd` | **C** |
| Mapa | 09 §6 | sem arte de mapa | **D** |
| Equipamento / progressão | 09 §3, 12 §6 | menus funcionais | **C** |
| Molduras, tipografia, estados de botão | 09 §9 | genéricos | **D** |
| Barra de chefe | 09 §1 | `painel_chefe.png` | **C** |
| Ícones de habilidade | 09 §3 | parciais | **D** |
| Mensagens de feedback | 09 §8 | texto simples | **D** |

Os 21 PNGs em `assets/ui/` são gerados por ferramenta, não derivados da
prancha 09. Nenhum widget aprovado existe.

## Prioridade 6 — VFX de gameplay e ambiente

| Efeito | Autoridade | Estado | Classe |
|---|---|---|---|
| Brilho da Shadowblade | 07 | luz 2D por código | **C** |
| Rastos de ataque | 07 | **pintados dentro dos frames da `premium_v1`** | **C**, viola o contrato |
| Impactos de acerto | 07, 12 | `impacto_roxo.png`, `impacto_azul.png` (CC0) | **C** |
| VFX de dash | 07 | nenhum | **D** |
| VFX de dano | 07 | flash por shader | **C** |
| VFX de corrupção | 07, 08 | partículas por código | **C** |
| Efeitos de checkpoint | 12 | fogueira | **C** |
| Efeitos de ataque de chefe | 12 | por arquétipo | **C** |
| Efeitos de ambiente | 10 | `Atmosfera.tscn` | **C** |
| Os 16 conjuntos da prancha 07 | 07 | nenhum existe | **D** |

## Prioridade 7 — Áudio

Fora do âmbito desta execução, excepto onde materialmente em falta. As camas
por bioma, os SFX por arquétipo de chefe e o aquecimento de áudio no arranque
estão implementados (**C**). A prancha 12 §7 define o conjunto alvo de SFX; a
comparação fica para depois de 9B a 9F.

## Rota de produção proposta para 9B — Koliani

**Não executar agora.** Isto é a especificação, não o trabalho.

### Autoridade

| Papel | Ficheiro |
|---|---|
| **Identidade global da personagem** | `01_KOLIANI_VISUAL_AUTHORITY_v1_1.png` |
| Locomoção | `02_KOLIANI_MOVEMENT_CORE_v1_1.png` e `05_KOLIANI_IDLE_RUN_CLEAN_v1_1.png` |
| Salto / queda / aterragem | `06_KOLIANI_JUMP_FALL_LAND_v1_1.png` |
| Combate | `03_KOLIANI_COMBAT_ACTIONS_v1_1.png` |
| Interacções e estados | `04_KOLIANI_INTERACTIONS_STATES_v1_1.png` |
| VFX | `07_KOLIANI_VFX_CLEAN_v1_1.png` |

A 01 vence sempre em identidade, silhueta, proporções, fato e cabelo. A 07
vence sempre em cor e forma de VFX. Koliani incidental nas 09/11/12 não conta.

### Material reutilizável com segurança

**Fontes:** `05`, `06` e `07` — os únicos três ficheiros com alfa real.
As `01`–`04` e `08`–`12` são RGB sem alfa e exigiriam recorte manual por cima
de molduras e legendas.

**Frames já extraídos, reutilizáveis:** os 45 frames limpos em
`work/koliani_extraction_recovery_medium/frames_clean/` — `idle` 10, `run` 12,
`turn` 4, `run_start` 6, `jump_start` 4, `jump_loop` 4, `fall` 4,
`run_brake` 1. Os 7 conjuntos já promovidos estão em
`assets/sprites/pixel/koliani_visual_pilot_5g/` e no build.

**Não reutilizável:** todo o `koliani_premium_v1` (rabo-de-cavalo, VFX fundido,
xadrez *baked*) e todo o `koliani_shadowblade` (arte de outro desenho, célula
51×64).

### Contrato de frame

| Parâmetro | Valor |
|---|---|
| Formato | PNG, RGBA |
| Alfa | binário: exterior 0, interior 255 |
| Canvas | **160 × 96** px por célula |
| Pivot | **(80, 90)** |
| Linha de base dos pés | **Y = 90** — última linha opaca em **89** |
| Altura da personagem | ~64 px |
| Orientação | virada à **direita** |
| Organização | frames em linha, uma tira por animação |
| Escala no jogo | 1:1, `default_texture_filter = Nearest` |

O contrato da prancha (64×64, pivot (32,60)) é o mesmo desenho noutra escala;
o canvas do jogo é 160×96 com pivot (80,90), e é esse que manda.

### Contrato de separação de VFX

Corpo e efeito **em ficheiros distintos**. Nenhum arco de lâmina, poeira,
faísca ou aura pintado dentro de um frame de corpo. Os 7 conjuntos do contrato
— `slash`, `dash_trail`, `hit_sparks`, `jump_dust`, `land_impact`,
`projectile`, `aura_charge` — saem à parte, derivados da prancha 07, em
magenta/violeta limpo para a Shadowblade e violeta escuro/preto/magenta
profundo para a corrupção.

### Assets a produzir em 9B

- **Corpo, 40 frames do contrato:** `idle` 10 ✔, `run` 12 ✔, `jump_start` 4 ✔,
  `jump_loop` 4 ✔, `fall` 4 ✔, **`land` 6 ✘**;
- **`run_brake` 6** ✘ (1 de 6 recuperado);
- **combate, ~46 frames:** `attack_1` 8, `attack_2` 8, `attack_3` 10,
  `attack_4` 8, `finisher` 12 — todos por produzir;
- **reacções:** `hurt` 6, `death` 8;
- **interacções:** `dash` 8, `dash_end` 6, `roll` 8, `crouch_walk` 6,
  `stand_up` 4, `wall_jump` 8, `wall_climb` 8, `ledge_grab` 6, `ledge_climb` 8,
  `ledge_drop` 4, `push` 6, `pull` 6, `switch_lever` 4, `get_up` 6,
  `hold_charge` 8, `aura_idle` 6, `telepawn` 8, `prone_slide` 6;
- **7 conjuntos de VFX separados.**

### Rota — duas hipóteses, à espera do Game Master

**CONF-01 tem de ser decidido antes de 9B arrancar.** O contrato de produção
diz que nenhum píxel é extraído das pranchas; o executável aprovado usa 7
animações extraídas das pranchas. As duas rotas são incompatíveis:

**Rota A — extracção determinista (o que já funcionou).** Continuar o método de
`work/koliani_extraction_recovery_medium/source/recover_extraction_medium.py`:
segmentação determinista da figura alta e central, sem criar, pintar,
interpolar ou inferir píxeis. Provou-se em 45 frames. **Limite duro:** só
funciona sobre as pranchas 05, 06 e 07, porque as restantes não têm alfa; e
falha onde o VFX toca o corpo (`land`, `run_brake`). Cobre talvez metade do
pacote.

**Rota B — arte nova segundo as pranchas.** Desenhar os frames de raiz a partir
da autoridade, respeitando o contrato de 160×96. É o que o
`production_contract.json` exige. Cobre tudo, incluindo combate e interacções,
e resolve a incoerência de personagem de uma vez. Custa muito mais.

**Recomendação:** **Rota B para combate e interacções** — onde não há alfa na
fonte e a rota A não chega — e **Rota A para completar `land` e `run_brake`**
só se a prancha 06 for reexportada com os VFX já em camada separada. Manter os
7 conjuntos 5G actuais como base aprovada de locomoção até serem substituídos
pela mesma mão que desenhar o combate, para não voltar a haver duas Kolianis.

### Validação visual

1. folha de contacto de todas as tiras a 4× (`NEAREST`), por animação;
2. comparação lado a lado com a prancha 01 em identidade, silhueta,
   proporções, fato, amuleto de Elara e cabelo;
3. verificação de que o cabelo é **sempre comprido e sempre solto**, sem
   rabo-de-cavalo e sem fita, em **todos** os frames;
4. verificação de que **o mesmo rosto e a mesma silhueta** atravessam todas as
   animações — o teste que `premium_v1` + 5G falha hoje;
5. captura no jogo real em L1 (`tools/shot_plataforma.gd` ou
   `--window --screen 1`), não em cena de laboratório;
6. **aprovação do Game Master**, sem a qual nada é integrado.

### Validação técnica

1. `tools/validate_koliani_production.py` → `BATCH=PASS 40/40`;
2. `tools/validate_assets.py` → `FAIL=0`;
3. alfa binário 0/255 em todos os frames;
4. última linha opaca **= 89** em todos os frames — falha se variar;
5. canvas 160×96 exacto e pivot (80, 90) em todos;
6. nenhum frame de corpo com VFX pintado;
7. `--headless --import` limpo e suite `tests/run_tests.tscn` verde;
8. varrimento do EXE e do PCK exportados a confirmar que os frames novos
   entraram e que as pranchas continuam **fora** do build.

## Ordem de execução

1. **9B — pacote de produção completo da Koliani** (depois de CONF-01 decidido);
2. kit modular de ambiente da Região I;
3. inimigos e guardiões;
4. Coração Putrefacto;
5. menu, HUD e UI de região;
6. VFX de gameplay e ambiente;
7. áudio, só onde materialmente em falta.

**Não começar o 2 antes de a rota do 1 estar decidida.**
