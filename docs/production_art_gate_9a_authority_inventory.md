# Production Art Gate 9A — autoridade visual aprovada e inventário

Data: 11 de setembro de 2026
Execução: **9A — APPROVED VISUAL AUTHORITY + ASSET INVENTORY**
Resultado: **PARTIAL PASS — inventário completo, uma decisão por tomar**

Esta execução **não gerou arte, não integrou arte e não mexeu em geometria**.
É inventário, verificação de autoridade, classificação e mapa de lacunas.
O mapa de lacunas está em
[production_art_gate_asset_gap_map.md](production_art_gate_asset_gap_map.md).
Os manifestos legíveis por máquina ficaram em
`work/production_art_gate/` (pasta ignorada pelo git, no checkout principal).

## 0 — Fecho do Windows Performance Gate

Aprovação humana: **SIM** (o Game Master jogou `build/windows/Koliani.exe`).

| Item | Valor |
|---|---|
| Commit de performance validado | `6beb05b` |
| `master` antes | `b2fd8a0` |
| `master` depois do fast-forward | `6beb05b` |
| Resultado do push | fast-forward aceite, **sem force, sem reset, sem clean** |
| `origin/master` no fim da 9A | `423fde7` (6 commits posteriores, com `6beb05b` como antepassado) |
| Suite headless em `6beb05b` | **OK — todos os testes passaram** |
| Trabalho local não relacionado | **PRESERVADO** (35 entradas por versionar no checkout principal, nenhuma tocada) |

**Ressalva de proveniência, medida e não assumida.** Os `BUILD_SOURCE.txt` do
`build/windows/` e do `build/web/` dizem `SOURCE_COMMIT=05f050e` (Execution
8.1C, exportado às 22:15). O `.exe` que o Game Master aprovou **não inclui** a
correcção 8.1E do save (`6beb05b`, 22:58) — que só melhora o que foi aprovado
(2047 ms → 9,2 ms). `master` é portanto um superconjunto do que foi jogado, e a
8.1E continua **por validar a jogar**.

A `master` **local do checkout principal** ficou deliberadamente em `b2fd8a0`:
esse checkout tem `project.godot` modificado e ~34 ficheiros de arte de produção
por versionar, e a série toca em `project.godot`, por isso um `merge --ff-only`
ali seria recusado. Fazer `git pull --ff-only` só depois de arrumar esse
trabalho local.

**WINDOWS PERFORMANCE GATE = FECHADO / APROVADO POR HUMANO.**

## 1 — As 12 autoridades aprovadas

Raiz:
`C:\Projetos\koliani\Koliani_1.0_Master_Package_v2\references\approved\`

Cada ficheiro foi **aberto e inspeccionado**, não deduzido pelo nome.
Encontradas **12/12**, legíveis **12/12**, e os **12 SHA-256 batem** com
`references/manifest.json` do próprio pacote.

| # | Ficheiro | Dim. | Modo | Alfa real | Bytes | SHA-256 (12 primeiros) |
|---|---|---|---|---|---|---|
| 01 | `01_KOLIANI_VISUAL_AUTHORITY_v1_1.png` | 1536×1024 | RGB | **não** | 2 202 457 | `91c298010a3e` |
| 02 | `02_KOLIANI_MOVEMENT_CORE_v1_1.png` | 1536×1024 | RGB | **não** | 2 384 520 | `78788a032734` |
| 03 | `03_KOLIANI_COMBAT_ACTIONS_v1_1.png` | 1536×1024 | RGB | **não** | 2 166 845 | `a2d91fc8bff9` |
| 04 | `04_KOLIANI_INTERACTIONS_STATES_v1_1.png` | 1536×1024 | RGB | **não** | 2 426 538 | `fc04824da1c8` |
| 05 | `05_KOLIANI_IDLE_RUN_CLEAN_v1_1.png` | 1536×1024 | **RGBA** | **sim** | 2 402 502 | `5056b7267283` |
| 06 | `06_KOLIANI_JUMP_FALL_LAND_v1_1.png` | **1774×887** | **RGBA** | **sim** | 1 706 322 | `afbd74469444` |
| 07 | `07_KOLIANI_VFX_CLEAN_v1_1.png` | 1536×1024 | **RGBA** | **sim** | 2 484 306 | `6564982d4ccf` |
| 08 | `08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png` | 1536×1024 | RGB | **não** | 2 420 659 | `840cfd8241a5` |
| 09 | `09_PRODUCTION_PACK_v7_UI_HUD_MAPS_MENUS.png` | 1536×1024 | RGB | **não** | 2 752 078 | `264d6def7c96` |
| 10 | `10_PRODUCTION_PACK_v8_ENV_LIGHT_ATMOSPHERE.png` | 1536×1024 | RGB | **não** | 2 819 659 | `86087e523990` |
| 11 | `11_PRODUCTION_PACK_v9_NARRATIVE_CINEMATICS.png` | 1536×1024 | RGB | **não** | 2 754 763 | `3c3c7279f48d` |
| 12 | `12_PRODUCTION_PACK_v10_GAMEPLAY_VFX_SFX_POLISH.png` | 1536×1024 | RGB | **não** | 2 509 580 | `6eea95ba9816` |

Hashes completos no manifesto JSON.

### O que a inspecção provou

A `references/MANIFEST.md` do pacote já avisava: *«etiquetas geradas por IA
como "transparent PNG", "Godot ready", tamanhos ou gamas de alfa são
alegações, não evidência técnica.»* **Esta execução confirma o aviso com
medições:** 9 das 12 pranchas **não têm canal alfa nenhum**, incluindo a 02,
que desenha um xadrez de transparência nos próprios pixels e escreve
«PNGs com fundo transparente (alpha real) — pronto para importação no Godot».
Não está.

Só **três** ficheiros têm alfa verdadeiro — **05, 06 e 07** — e são exactamente
os únicos de onde alguma coisa foi alguma vez extraída com sucesso.

### Domínio e tipo de cada prancha

| # | Domínio | Tipo | Estado do asset de produção |
|---|---|---|---|
| 01 | Identidade da Koliani | Prancha de character sheet | **D** — desenho aprovado, asset em falta |
| 02 | Locomoção nuclear | Contact board de sprite sheet | **D** |
| 03 | Acções de combate | Contact board de sprite sheet | **D** |
| 04 | Interacções e estados | Contact board de sprite sheet | **D** |
| 05 | Idle/run e cabelo solto | Folha limpa com alfa real | **E/D** — 7 conjuntos extraídos e activos; resto em falta |
| 06 | Salto/queda/aterragem | Folha limpa com alfa real | **E/D** — jump/fall extraídos; `land` bloqueado |
| 07 | Linguagem de VFX (só VFX) | Folha de VFX com alfa real | **D** |
| 08 | Ambiente da Região I | Art kit board | **B/D** — panorama integrado; camadas em falta |
| 09 | UI / HUD / mapa / menus | Production pack board | **D** |
| 10 | Ambiente, luz e atmosfera | Production pack board | **D** |
| 11 | Narrativa e cinemáticas | Production pack board | **D** |
| 12 | Feedback, VFX/SFX, polimento | Production pack board | **D** |

**Nenhuma das 12 é um asset de produção.** Todas são pranchas compostas, com
molduras, legendas, painéis de notas e paletas pintadas por cima. Uma prancha
pode definir exactamente o aspecto do jogo e continuar a não servir para
importar no Godot — que é a regra absoluta do gate.

### Contrato técnico que as próprias pranchas escrevem

As pranchas 03, 04, 05 e 06 trazem a mesma informação técnica escrita:

- frame de **64×64 px** (base);
- PNG de fundo transparente;
- frames em linha, organizados por animação;
- **pivot nos pés, (32, 60)**;
- estilo *Pixel Art Premium (Hybrid 2D)*;
- **«sem VFX na personagem»** e **«VFX em ficheiros separados»**.

A 02 acrescenta a escala de jogo (~64 px de altura de personagem) e nomeia os
efeitos que têm de sair à parte: `slash 1`, `slash 2`, `dash`, `hit spark`,
`land dust`. A 06 nomeia `jump_dust`, `jump_trail`, `land_impact`,
`dust_small`.

O contrato local `assets/sprites/koliani_production/production_contract.json`
converte isto para o canvas do jogo: **160×96, pivot (80, 90), linha de base
Y=90, virada à direita, 64 px de altura de personagem, RGBA com alfa 0/255**,
40 frames de corpo e 7 conjuntos de VFX separados.

## 2 — Verificação contra a documentação canónica

Lidos: `docs/visao_koliani_1_0.md`, `docs/decisoes.md`,
`docs/master_package_integration.md`,
`docs/execution_8_real_game_production_integration.md`, `PRIORIDADES.md`,
`docs/retomar_aqui.md` e `Koliani_1.0_Master_Package_v2/references/MANIFEST.md`.
**Não se repetiu a auditoria global do repositório.**

Hierarquia aplicada:

1. decisão explícita mais recente do Game Master (briefing 9A, secções 5 e 6);
2. documentação canónica local;
3. referência visual aprovada;
4. material histórico.

### Divergências resolvidas pela hierarquia — não são conflitos

**Cor dos VFX.** As pranchas 01 e 03 mostram os golpes a encarnado/carmim; a
07 — que é a autoridade declarada de VFX — mostra-os a **magenta/violeta
limpo**, que é o que a secção 5 do briefing manda. A leitura avermelhada das
01/03 é estilo de prancha. **A 07 governa.** Sem escalada.

**Nome e ambiente da Região I.** A prancha 08 diz *«REGIÃO I — FLORESTA
CORROMPIDA»* e mostra floresta escura ao luar com corrupção magenta. As
pranchas 09, 10, 11 e 12 dizem *«Região I — Floresta Sagrada»* e mostram
floresta verde e dourada, com luz quente. A secção 6 do briefing (nível 1 da
hierarquia) manda **FLORESTA CORROMPIDA**, e a 08 concorda. **Resolvido:** as
09 e 10 continuam autoridade pela **estrutura** — que widgets de interface
existem, que peças modulares de terreno são precisas — e **não** pelo mood.
Fica registado para o Game Master poder decidir o contrário se quiser.

**Koliani incidental.** Nas pranchas 09, 11 e 12 aparece uma Koliani ruiva
clara num bosque luminoso. A regra já estava escrita na `MANIFEST.md` e em
`docs/master_package_integration.md`: personagem incidental em pranchas de
ambiente, UI ou cinemática **não** substitui a 01. Sem escalada.

### Conflito real — requer o Game Master

**GAME MASTER VISUAL CONFLICT REVIEW REQUIRED — CONF-01.**

O contrato `production_contract.json` diz, textualmente:

> «As pranchas são referências visuais; nenhum frame ou píxel é extraído ou
> reciclado.»

Mas os 7 conjuntos de animação que estão **activos no executável que o Game
Master aprovou** (`koliani_visual_pilot_5g`) foram **extraídos** das pranchas
05 e 06 pela Execution 5G, e a recuperação em
`work/koliani_extraction_recovery_medium/` documenta o método frame a frame.

Isto não é uma questão de gosto: **decide a rota do 9B**. Ou o pacote de
produção da Koliani se faz por extracção e normalização determinista a partir
das pranchas 05/06/03/04 — o que já provou funcionar para 45 frames — ou se
desenha de raiz, como o contrato exige, e os frames 5G actuais passam a
provisórios. As duas rotas estão descritas no mapa de lacunas.

### Ausência de referência — não é conflito

As 12 pranchas **não contêm nenhum desenho** de Ghorak, Morvanna, Rainha
Aracnídea, Entrevane ou Coração Putrefacto, nem dos inimigos comuns. As
prioridades 3 e 4 não têm prancha contra a qual validar. A autoridade escrita
existe (`Koliani_1.0_Master_Package_v2/docs/design/BOSSES_ENEMIES.md`), a
visual não. **Não se inventa substituto.**

## 3 — Verdade de runtime, medida nos binários

Não se classificou nada como integrado por existir um nó, um recurso ou um
teste verde. A presença foi **lida por varrimento de bytes** do PCK Web
(53 MB) e do EXE Windows (162 MB) aprovados:

| Token procurado | Web PCK | Windows EXE | Leitura |
|---|---|---|---|
| `koliani_visual_pilot_5g` | 14 | 14 | frames 5G **estão no build** |
| `region1_panorama_heart_tree` | 4 | — | panorama da autoridade 08 **está no build** |
| `terrain_top` | 0 | 0 | kit modular **não está no build** |
| `platform_large_segment` | 0 | 0 | idem |
| `moss_overlay` | 0 | 0 | idem |
| `koliani_master_right` | 0 | 0 | master da Koliani **não está no build** |
| `KOLIANI_VISUAL_AUTHORITY` | 0 | 0 | pranchas **não estão no build** |
| `PRODUCTION_PACK_v7` | 0 | 0 | idem |

### Como a Região I desenha a Koliani, na realidade

As cinco cenas de nível `L1`–`L5` instanciam `scenes/actors/Koliani.tscn` com
**dois** interruptores ligados: `usar_prototipo_premium = true` e
`usar_piloto_visual_5g = true`. O resultado, em `scripts/koliani.gd`, é este:

| Animação | Tiras usadas | Origem | Classe |
|---|---|---|---|
| `idle`, `run`, `turn`, `run_start`, `jump_start`, `jump_loop`, `fall` | `koliani_visual_pilot_5g` | extraído das pranchas 05/06 | **E→B** |
| `run_brake`, `land` | montadas por fallback de poses | sem frames próprios | **D** |
| `attack`, `attack2`, `attack3`, `attack4`, `dash`, `roll`, `hurt`, `morte`, `crouch`, `wallslide`, `borda`, `djump`, `defesa`, `aterrar`, `jump` | `koliani_premium_v1` | protótipo antigo | **C** |

**Consequência, que é a descoberta central da 9A:** na Região I o jogador vê
**duas Kolianis diferentes conforme a acção**. Parada e a correr é a 5G —
cabelo comprido, solto, raízes pretas e pontas vermelhas, sem VFX colado. A
atacar, a fazer dash ou a morrer é a `premium_v1` — **rabo-de-cavalo**, cabelo
roxo com lenço encarnado e **o arco violeta do golpe pintado dentro do frame
do corpo**.

Isto viola três cláusulas congeladas de uma vez: *cabelo sempre solto*,
*sem rabo-de-cavalo*, *mesma silhueta em todas as animações* — e ainda o
contrato de separação de VFX. `tools/validate_assets.py` mede-o sozinho:
**PASS=0 FAIL=16**, com os motivos «cabelo preso/ponytail; contrato v1.1 exige
cabelo completamente solto» e «derivado de checkerboard baked por remoção
automática de fundo».

É esta a razão técnica concreta por trás da observação do Game Master de que a
personagem *«ainda parece antiga»* — não é polimento em falta, são dois rigs
incompatíveis no mesmo boneco.

### Estado técnico medido das tiras activas

`koliani_visual_pilot_5g` (7 tiras, todas 160×96 por célula):

- RGBA com **alfa binário 0/255** em 7/7;
- **última linha opaca = 89** em 7/7 → linha de base Y=90 consistente;
- pivot documentado em (80, 90);
- sem contaminação por legenda nem xadrez;
- pernas e pés completos;
- VFX **não** fundido no corpo;
- identidade coerente com a prancha 01.

`koliani_premium_v1` (18 tiras, 160×96 por célula): alfa binário sim, mas
**última linha opaca varia entre 79, 80, 88, 89 e 90** — a linha de base não é
consistente entre animações.

`koliani_shadowblade` (13 tiras, 51×64): é o rig por omissão de `koliani.gd`
(`const RIG := "shadowblade"`), **mas a Região I não o usa** porque os cinco
níveis forçam `usar_prototipo_premium = true`. Alfa não binário.

## 4 — Material local e por versionar

Inventariado **em modo só-leitura**. **Não se apagou, moveu, renomeou nem
comitou nada.**

O checkout principal tem **35 entradas** em `git status`. As relevantes para
arte:

| Caminho | Classificação | Versionado |
|---|---|---|
| `Koliani_1.0_Master_Package_v2/` (~29 MB) | material do master package | **não** |
| `Koliani_1.0_Master_Package/` | duplicado (versão anterior) | **não** |
| `koliani_codex_handoff_v1_1/` | material do master package | **não** |
| `assets/art/regions/region_01_forest/production/terrain/` (12 peças) | candidato a produção | **não** |
| `.../production/overlays/`, `.../props/` | candidato a produção | **não** |
| `.../production/_source/imagegen_v1/` | trabalho de extracção | **não** (excluído dos exports) |
| `assets/sprites/koliani_production/` | candidato a produção | **não** |
| `work/koliani_extraction_recovery_medium/` (449 ficheiros) | trabalho de extracção | **não** (`work/` no `.gitignore`) |
| `work/execution_8/real_runtime/` | evidência de runtime gerada | **não** |
| `build/windows/`, `build/web/` | saída de build gerada | **não** |
| `asset_contract_v1_1.json` | material do master package | **não** |

Versionado, e portanto no build: **apenas** os 3 panoramas
(`region1_panorama_*.png`) e as 7 tiras `koliani_visual_pilot_5g/*.png`.

**Risco a registar:** o kit modular de 12 peças da Região I e os 449 ficheiros
da recuperação de extracção existem **só na máquina do Paulo**, fora do
controlo de versões, e a recuperação está numa pasta ignorada. Um `git clean`
apaga trabalho insubstituível. A 9A **não** os comita — a secção 20 proíbe
comitar candidatos a produção antes de classificados — mas deixa o aviso.

### `export_filter="all_resources"` — o que se passou e o que continua em aberto

O build antigo `Koliani-Execution-5B-Hybrid-Character-dev.exe` (7 de setembro,
**350 MB**) contém tokens de `work/` — `auditoria_nivel12`, `devbar` — ou seja,
**varreu mesmo screenshots de trabalho para dentro do executável**. Os builds
actuais (**162 MB**) já não, porque `work/**` entrou no `exclude_filter`.

As pranchas aprovadas **não estão** em nenhum dos builds. A razão não é a
configuração: é que o pacote não está versionado e o export correu numa
checkout onde ele não existe. **Nada no `export_presets.cfg` exclui
`Koliani_1.0_Master_Package_v2/**`**, e as 12 pranchas **estão importadas pelo
Godot** (têm `.import` e `.ctex` em `.godot/imported/`). Um export feito no
checkout principal voltaria a arrastar 29 MB de pranchas para dentro do jogo.

Isto é um apontamento de risco, não uma correcção: a 9A não altera
configuração de export.

## 5 — Classificação por domínio

| Domínio | Classe | Asset de produção existe |
|---|---|---|
| Koliani — locomoção (7 animações) | **E→B** parcial | sim, extraído, activo |
| Koliani — `run_brake`, `land` | **D** | não (bloqueado por VFX fundido na fonte) |
| Koliani — combate e interacções (15 animações) | **C** | não |
| Koliani — pacote contratado (40 frames) | **D** | não (0/40) |
| Koliani — VFX separados (7 conjuntos) | **D** | não |
| Região I — panorama / Heart Tree | **B** | sim, activo |
| Região I — camadas de parallax separadas | **D** | não |
| Região I — kit modular de terreno | **E** (activo é **C**) | 12 peças candidatas, não ligadas |
| Região I — props, ruínas, arcos, lanternas, cascatas | **C** / **D** | não |
| Inimigos comuns | **C** | não |
| Guardiões (Ghorak, Morvanna, Rainha Aracnídea, Entrevane) | **C** | não |
| Coração Putrefacto | **C** | não |
| UI / HUD / menus / mapa | **C** | não |
| VFX — projécteis e impactos | **C** | parcial (pack CC0) |
| VFX — os 16 conjuntos da prancha 07 | **D** | não |

Legenda: **A** aprovado/congelado · **B** implementado e de produção ·
**C** implementado, legado a substituir · **D** desenho aprovado, asset em
falta · **E** asset existe, não integrado · **F** bloqueio técnico ·
**G** decisão nova necessária.

**Nenhum domínio ficou em G.** Falta de asset não é falta de decisão.

## 6 — Política de git para as referências aprovadas

- as 12 pranchas estão **UNTRACKED**, fora do controlo de versões;
- **nenhuma** está duplicada dentro de `assets/`;
- existe um **duplicado de pacote inteiro** (`Koliani_1.0_Master_Package/`,
  versão anterior) ao lado do `_v2`;
- peso do conjunto das 12: **29 030 229 bytes (~29 MB)**;
- o pacote inteiro (`_v2`, docs incluídos) pesa **~28 MB** medidos em disco.

**Comitar as 12 é praticável.** 29 MB num repositório que já tem centenas de
PNGs é aceitável, e o pacote inteiro não é «multi-gigabyte» — a preocupação da
secção 20 não se materializa aqui. Recomendação, **não executada** porque a 9A
não o autoriza sem decisão: comitar **exactamente as 12 pranchas** mais
`references/MANIFEST.md` e `references/manifest.json`, e acrescentar
`Koliani_1.0_Master_Package_v2/**` ao `exclude_filter` dos presets no mesmo
gesto, para que a autoridade fique protegida sem entrar no jogo.

O que a 9A comita: **só esta documentação e o mapa de lacunas**. Nenhum
candidato a produção, nenhuma prancha, nenhuma alteração de configuração.

## 7 — Validadores, tal como responderam hoje

| Validador | Resultado |
|---|---|
| `tools/validate_koliani_production.py` | `MASTER=PASS BATCH=PENDING 0/40` |
| `tools/validate_region_artkit.py` | `esperados=12, presentes=12, missing=0, warnings=12, fails=0` |
| `tools/validate_assets.py` | `ASSET PRODUCTION REQUIRED: PASS=0 FAIL=16` |
| `tests/run_tests.tscn` em `6beb05b` | **OK — todos os testes passaram** |

Os 12 *warnings* do art kit dizem «tecnicamente presente; aprovação actual:
validated». Isso é **validação técnica**, não aprovação visual de produção. A
distinção mantém-se em todo este documento.

## Ficheiros produzidos pela 9A

- `docs/production_art_gate_9a_authority_inventory.md` (este)
- `docs/production_art_gate_asset_gap_map.md`
- `work/production_art_gate/approved_visual_authority_manifest.json`
- `work/production_art_gate/existing_asset_inventory.json`

As referências aprovadas **não foram modificadas**.
