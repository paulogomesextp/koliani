# Execution 9E.2 — Coração Putrefacto em produção + prova no EXE

Data: 11 de setembro de 2026. Estado: **PASS.**
**REGION I ENEMY PRODUCTION GATE: CLOSED. REGION I BOSS PRODUCTION GATE: CLOSED.
Pronto para a 9F: SIM** (a 9F não foi iniciada).

## A. Git no início

`master`, HEAD `813e6a8` = `origin/master`; sem commits novos do Luís.
Preservado e fora dos commits: a reordenação `ui_*` do `project.godot` (do
editor) e todos os não rastreados.

## B. Autoridade dedicada

- `C:\Projetos\koliani\work\production_art_gate\9E1_game_master_approved\coracao_putrefacto_production_authority_v1_0.png`
- 1448×1086, **RGBA**, PNG, 2 739 588 bytes
- SHA-256 `460435aaf18b9b568b0f4529a087a2cc80e07554def894c313f579b9b9247693`
- **Alfa real**: 481 k píxeis a 0, 584 k em 224–255, bordas suaves pelo meio;
  compostos sobre verde, os 9 elementos saem limpos. GAME MASTER APPROVED. Lida,
  nunca regravada; o produtor recusa correr se o SHA mudar.

## C. Análise da fonte

Componentes alfa > 16 (8-conexos), em resolução total:

| Elemento | Caixa na autoridade | Classe | Uso |
|---|---|---|---|
| forma contida (raízes + coração) | (8,14)–(726,496) | A | **corpo fase 1** |
| forma intensificada (coroa em chama, núcleo mais forte) | (724,10)–(1444,498) | A | **corpo fase 2** |
| erupção de corrupção (pedras + chamas) | (1112,840)–(1448,1086) | C | **VFX da transição** |
| duas poses de alcance (raízes a esticar) | linha do meio | A | não usadas — o corpo não tem estado de ataque (`atacar_anim` nunca corre) |
| monte de raízes | (0,840)–(330,1086) | C | não usado — seria arte do `RaizPerigo`, ator partilhado |
| tentáculo, varrimento | linha de baixo | C | sem estado/efeito no runtime atual |
| coração compacto | (575,840)–(800,1086) | C | não usado — sozinho seria o "coração a flutuar" que a identidade proíbe |

As caixas das duas fases tocam-se em 2 px: separa-as a máscara de
componentes, não a caixa. Restos vermelhos: 50,7 k píxeis de vermelho puro a
alfa < 64 (véu de apresentação, sai com o corte a 64); 4,8 k opacos são as veias
carmesim da própria arte (ficam); 227 na borda saem com a binarização.

## D. Arte de produção

`tools/produzir_coracao_9e2.py` → `assets/art/regions/region_01_forest/bosses/coracao_putrefacto/production/`:
etiquetagem, véu (alfa < 64) fora, BOX pré-multiplicado a **uma escala comum**
(k = 0.20958, procurada em passos de 0,1 % até a fase 1 medir exatamente
100 px), alfa 0/255, fases alinhadas pelo núcleo e pela base.

- canvas 176×120, baseline 112; fase 1 149×100, fase 2 148×100;
- `phase_1/`: idle ×4 (pulso: ganho só na corrupção magenta 1.0–1.16), run ×1,
  hit ×3 (recuo de píxel inteiro);
- `phase_2/`: idle_f2 ×4 (ganho 1.0–1.25), hit_f2 ×3, dead ×10 (dissolução Bayer
  da forma intensificada — o Coração morre sempre na fase 2);
- `vfx/erupcao.png` 68×44 (com 2 px de borda transparente);
- `manifest.json`: autoridade + SHA, caixas, classes, não usados e porquê,
  operações, núcleo no frame por fase, SHA de cada frame. Registado também no
  manifesto dos inimigos (é por ele que o runtime liga a produção).

**Validator v2** (`work/execution_9e2/validator/`): idle, run, hit, idle_f2,
hit_f2 e a consistência fase 1 × fase 2: **PASS**. dead: REVIEW
(`DETACHED_BODY_REGIONS`, a dissolução separa o corpo de propósito). VFX: a 1.ª
versão deu **FAIL** (`CLIPPED_*` nos 4 lados, recorte rente) — corrigido com
borda transparente, agora **PASS**. Nenhum FAIL promovido.

## E. Integração

`ChefeCoracaoPutrefacto` (`scenes/levels/Coracao_da_Floresta.tscn`, nó `Chefe`):

- **fase 1** (vida > 50 %): `idle` / `hit` da forma contida;
- **fase 2** (vida ≤ 50 %, o limiar do jogo, `fase_por_vida`): `_atualizar_anim`
  passa a `idle_f2`, o golpe a `hit_f2`; na transição, a **erupção** sobe da base e
  apaga-se (1,1 s) e o núcleo realinha-se ao da forma intensificada;
- teto de largura 150 (em vez dos 110 dos guardiões) só com produção: mantém a
  altura de sempre (100 × `escala_visual` 1.7);
- ponto fraco (`Nucleo`) e luzes alinhados ao núcleo desenhado. As duas luzes do
  legado (`Nucleo/Luz`, `LuzCoracao`) tinham ~300 px de raio no ecrã e lavavam a
  casca escura de rosa/branco — **raio reduzido a 40 %** com produção (energia,
  tempos e a janela de dano iguais). Provado em runtime antes/depois
  (`work/execution_9e2/boss_dryrun*.png`).
- **Legado removido: SIM** — nenhum frame de `bosses_anim/coracao_putrefacto`,
  folha estática escondida.

## F. Prova dos 11 inimigos no EXE

Rota nova só de dev em `main.gd`: `Koliani.exe -- --nivel=N
--foto-estado=inimigos --foto=<png>`. Só a Koliani se move (invulnerável, encostada
a cada bicho); crias largadas pelo código dos próprios chefes; fase 2 pelo limiar
do jogo. Cada foto grava no JSON a animação e o recurso do frame desenhado e se o
bicho estava no ecrã.

EXE v0.15.20: **58 registos, 0 texturas legadas**; todas as 11 identidades no
ecrã com textura de produção. Folha: `work\execution_9e2\evidencia_exe_9e2.png`.
Fotos em `work\execution_9e2\runtime_exe\`:

| identidade | foto | fotos no ecrã |
|---|---|---|
| goblin | `EXE_L1_EliteGoblin_goblin_1_idle.png` | 9 |
| mushroom | `EXE_L2_EliteCuspidor_mushroom_1_idle.png` | 4 |
| gosma | `EXE_L2_GoblinBaixa_gosma_1_idle.png` | 6 |
| besouro | `EXE_L2_DemonioBase_besouro_1_idle.png` | 8 |
| lodo | `EXE_L5_EliteLodo_lodo_1_idle.png` | 3 |
| Ghorak | `EXE_L1_Guardiao_ghorak_1_idle.png` | 3 |
| Morvanna | `EXE_L2_Guardiao_morvanna_1_idle.png` | 3 |
| Rainha Aracnídea | `EXE_L3_Guardiao_rainha_aracnidea_1_idle.png` | 3 |
| Entrevane | `EXE_L4_Guardiao_entrevane_1_idle.png` | 3 |
| clone da Morvanna | `EXE_L2_cria_clone_morvanna.png` | 1 |
| cria da Rainha | `EXE_L3_cria_cria_rainha.png` | 1 |

Registos: `EXE_L{1..5}_registo.json`, resumo `resumo_identidades.json`.

## G. Prova do boss no EXE

- fase 1: `EXE_L5_coracao_1_fase1.png`, telégrafo `EXE_L5_coracao_2_fase1_telegrafo.png`
  (textura `phase_1/idle_*`);
- transição + erupção: `EXE_L5_coracao_3_transicao_erupcao.png` (`phase_2/idle_f2_*`);
- fase 2: `EXE_L5_coracao_4_fase2.png`; golpe na fase 2: `EXE_L5_coracao_5_fase2_hit.png`
  (`phase_2/hit_f2_*`).

## H. Gameplay

**GAMEPLAY CONSTANTS CHANGED: NO.** Vida, dano, tempos, limiar de fase, colisão,
arena: iguais. Mudanças só visuais (animação por fase, VFX, posição/raio das luzes)
e a rota de prova de dev.

## I. Telégrafos

Inalterados (sístole 0,72 s, telégrafos 0,55 s, `_piscar`). O ponto fraco
continua a acender na sístole, agora em cima do núcleo da arte. **Tempos
alterados: NÃO.**

## J. Desempenho

Editor, vsync off, 240 frames: L1 0,46 · L2 0,49 · L3 0,46 · L4 0,47 · L5
0,47 ms; draw calls 51–75 (9D+9E: 0,46–0,51 ms, 64–75). Arte do boss: 20 frames
de 176×120 + 1 VFX, 604 KB em disco. **Regressão: NÃO.**

## K. Testes

- Validator: acima.
- Suite headless completa: **PASS** (rc 0).
- `teste_execution_9d_inimigos_regiao1`: agora aceita a pasta dos chefes como
  produção (`e_producao`) e confirma o SHA de cada frame integrado.
- `teste_9d9e_crias_sem_goblin`: PASS (inalterado).
- `teste_9e2_coracao_producao_e_fases` (novo): 5 animações só com produção, zero
  frames legados, folha estática escondida, fase 1 = `idle`, fase 2 (pelo limiar)
  = `idle_f2` de `phase_2/`, erupção presente. **Provado que morde:** sem o
  mapeamento de fase, rc 1 («fase 2 devia mostrar 'idle_f2', mostra 'idle'»).
- L1–L5 carregam (suite + 5 corridas do EXE).

## L. Windows

v0.15.20, commit `901da1f`, worktree limpo `.worktrees/export-9e2` (0 alterações).
`build/windows/Koliani.exe` 165 722 880 bytes, SHA-256
`3f39363ac1389d474c8cada96e40f1915fd52197184666930df060c1d95625f9`. L1–L5: 5/5
rc 0, `build=0.15.20`. Userdata copiado antes e reposto depois, idêntico por SHA.

## M. Web/PWA

Mesmo commit e worktree. `index.pck` 56 554 740 bytes, SHA-256
`b40ff4ce247a9f9959c04555edb035d1a03230f24abafafb82e35cb1704bdd82` = **SHA
calculado no browser** (origem nova `koliani-web-9e2`, porta 8073, sem service
worker a controlar a página). Cache **`1789148452|5337692`** (9D+9E:
`1789146809|5457071`). Menu em v0.15.20, New Game → L1 corre. **O L5 não foi
aberto na Web:** num save novo só o L1 está desbloqueado e o build de release não
aceita saltos por linha de comando. O PCK verificado traz a arte do boss
(`phase_2/idle_f2_01` presente) e não há ramo visual por plataforma; a prova
exaustiva do boss é a do EXE do mesmo commit.

Higiene (EXE e PCK): 0 × `res://work/`, 0 × `.worktrees/`, 0 × `execution_9e2`,
0 × `_source`. O nome da autoridade 9E1 aparece 2× como texto de proveniência dos
manifestos JSON (backlog conhecido); nenhuma imagem de referência. Os ficheiros do
rig legado `bosses_anim/coracao_putrefacto` continuam no PCK mas não são usados.

## N. Git no fim

- `901da1f` — produtor, 20 frames + VFX + manifestos, integração, rota de prova,
  testes, v0.15.20 (só a linha da versão do `project.godot`);
- commit seguinte — este relatório, `retomar_aqui.md`, `PRIORIDADES.md`,
  `.claude/launch.json`; `push` sem force.

## O. Bloqueios

Nenhum.

## P/Q/R

REGION I ENEMY PRODUCTION GATE: **CLOSED**.
REGION I BOSS PRODUCTION GATE: **CLOSED**.
READY FOR 9F: **SIM** (não iniciada).
