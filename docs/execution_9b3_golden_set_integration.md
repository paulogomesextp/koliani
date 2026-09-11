# Execution 9B.3 — Golden Set promotion + runtime integration

Data: 11 de setembro de 2026 · Estado: **PASS — KOLIANI GOLDEN SET — PRODUCTION INTEGRATED**

## A. Autoridade

**KOLIANI GOLDEN SET VISUAL AUTHORITY: GAME MASTER APPROVED.**

| | |
|---|---|
| Original | `work/production_art_gate/koliani_golden_set_approved.png.png` (mantido) |
| Canónico | `work/production_art_gate/9b1_game_master_approved/koliani_golden_set_approved.png` |
| SHA-256 | `0b067780d316d1fcb288c2a3d944cd758a212f8d696c1818ae6ac0e4db0c60c4` |
| Byte-idêntico | **SIM** (`cmp` + SHA iguais); 1536×1024 RGBA |

**8 LOW-HEIGHT FRAMES: POSE-JUSTIFIED / ACCEPTED — 59px RULE = REVIEW ALERT ONLY.**
(`jump_start_001`, `jump_loop_001/003`, `attack_basic_001/002/003/005/006`.)

## B. Validator v2 — duas heurísticas corrigidas

- **Xadrez:** só contam píxeis com alpha > 0; a cobertura é medida sobre os
  píxeis visíveis. Um exterior transparente (uniforme ou com lixo RGB) deixou
  de disparar. Xadrez opaco ou semi-opaco continua a ser apanhado.
- **Escala:** se a área da caixa passar `max_scale_ratio` **e** o manifesto
  declarar `normalization_scale` com canvas, baseline e pivot válidos, passa a
  `POSE_AREA_VARIATION` (REVIEW). Mas se a silhueta (nº de píxeis visíveis) variar
  mais do que `max_pixel_count_ratio` (1,45 por omissão; um resize linear k dá
  k²), continua **FAIL** — mesmo com a escala declarada. Sem escala declarada,
  o comportamento é o antigo.
- Regressões novas: exterior com lixo RGB → sem xadrez; xadrez semi-opaco →
  apanhado; mesma escala + pose diferente → REVIEW e não FAIL; personagem
  redimensionada 1,5× → FAIL, com e sem escala declarada.
- Suite: **10/10 OK**. Clipping, alpha, baseline e contaminação não mudaram.

## C. Assets de produção

39 promovidos por cópia byte-a-byte (`tools/promover_golden_set_9b3.py`):

| Animação | Frames | Validator v2 |
|---|---|---|
| `frames/idle` | 7 | PASS |
| `frames/run` | 10 | REVIEW (`POSE_AREA_VARIATION`) |
| `frames/jump_start` | 4 | REVIEW (`POSE_AREA_VARIATION`) |
| `frames/jump_loop` | 3 | REVIEW (`POSE_AREA_VARIATION`) |
| `frames/fall` | 3 | PASS |
| `frames/attack_basic` | 6 | PASS |
| `vfx/vfx_slash_basic` | 6 | REVIEW (`POSE_AREA_VARIATION`, `BOUNDING_BOX_DRIFT`) |

Nenhum FAIL. Os REVIEW são variação de pose ou do VFX, com a escala provada
uniforme (0,3975). Manifesto de produção:
`assets/sprites/koliani_golden_set/production_manifest.json` (animação, índice,
caminho, SHA-256, canvas, pivot, baseline, autoridade + SHA, resultado do
validator). Relatórios e contact sheets ficam fora das pastas de runtime:
`work/production_art_gate/9b3/validator/`.

## D. Godot

`scripts/koliani.gd` → `@export var usar_golden_set`, ativo em L1–L5 (substitui
`usar_piloto_visual_5g`, que fica `false`).

- **Golden (arte direta):** `idle` 7@8, `run` 10@13,33 (ciclo de 0,75 s como a 5G),
  `jump_start` 4@12, `jump_loop` 3@6, `fall` 3@6, `attack` 6@33,33 (= 0,18 s).
- **Golden (derivado só de frames golden, sem píxeis novos):** `attack2/3/4` (os 6
  frames do golpe a 30/20/31,58 fps = 0,20/0,30/0,19 s); `turn` = run 1–4;
  `run_start` = run 1–6; `run_brake` = run 8–10 + idle 1; `land`/`aterrar` =
  fall 3 + idle 1; `lancar` = frames do ataque.
- **VFX:** nó `SlashVFX` (AnimatedSprite2D, filho da Koliani), dispara em
  `_iniciar_ataque`, 6 frames na duração lógica do golpe, espelhado por
  `_olha_para` e pela gravidade. Não toca na hitbox.
- **Escala por animação:** golden 1,0 / offset (0,−18); legado premium 0,75 /
  (0,−12,67). Os pés ficam no mesmo sítio (+22).
- **Luz magenta da lâmina (`LuzLamina`) desligada** com o Golden Set: pintava o
  cabelo e a pele de rosa-choque, e a autoridade tem a lâmina inativa. O glow do
  golpe mantém-se.
- **Fallbacks legados que restam (premium_v1), só para estados sem arte de
  produção:** `dash`, `roll`, `hurt`, `morte`, `crouch`, `wallslide`, `borda`,
  `djump`, `defesa`. A 5G já não é usada na Região I.
- **Constantes de gameplay alteradas: NÃO.** Física, movimento, câmara,
  colisão, hitbox, DUR_*, dano, salto, dash, save e progressão ficaram iguais.

## E–F. Zero chibi e ataque (runtime real)

Idle → run → jump_start → jump_loop → fall mostram a mesma rapariga: cabelo
comprido e solto, preto→vermelho, lenço vermelho, mesma roupa e mesma idade
aparente. A cabeça não muda de tamanho e **não há troca de identidade**.
O ataque usa o corpo golden (sem rabo-de-cavalo nem cabelo roxo) e o arco
aparece à parte, no nó `SlashVFX`. A hitbox e os tempos não mudaram.

## G. Testes

- Validator v2: 10/10.
- Suite headless (`res://tests/run_tests.tscn`): **OK — todos os testes
  passaram**. O teste da Execution 8 passa a exigir `usar_golden_set` em L1–L5.
- Smoke L1: sem erros de script.
- Nota: na primeira passagem a suite deu 3 falhas, causadas por eu ter gravado o
  `run_tests.gd` em CRLF (as literais multi-linha deixam de bater). Repus o LF e
  as ferramentas novas escrevem sempre LF.

## H. Evidência de runtime

A prova `--foto-estado=golden` conduz a Koliani com o input normal e grava, a
cada foto, a animação e o recurso **do frame que está a ser desenhado**:

- editor/projeto: `work/production_art_gate/9b3/runtime_editor/` (7 PNG +
  `golden_registo.json` + `runtime_crops_x3.png`);
- **EXE exportado:** `work/production_art_gate/9b3/runtime_windows_exe/` (7 PNG +
  `golden_registo.json` + `runtime_exe_crops_x3.png`). Registo:
  `idle_001`, `attack_basic_005` com VFX visível, `run_004`, `jump_start_001`,
  `jump_loop_001`, `fall_001`, todos com escala 1,0 e offset (0,−18);
- **Web/PWA:** `work/production_art_gate/9b3/runtime_web/`, com capturas do canvas
  do jogo a correr no browser, gravadas por um recetor local. Mostram a Koliani
  do Golden Set **parada** no L1, com v0.15.16. **Limite honesto:** o painel do
  browser estava escondido, e o browser pausa o `requestAnimationFrame` que move
  o loop Web do Godot. As teclas J/→/espaço não chegaram ao jogo, e as 4
  capturas são todas idle (os nomes dos ficheiros dizem isso). Na Web, corrida,
  salto e ataque **não** ficaram fotografados. Ficaram provados no EXE exportado
  do mesmo commit, e o `index.pck` que o browser corre é byte-idêntico ao
  exportado.

## I. Windows

`build/windows/Koliani.exe`: 162 730 376 bytes, SHA-256
`d2fbf5e6202456507418748e4a3c999e6ca6da651d6a5c29cb88be4a51df1e94`, exportado
de um **worktree limpo** no commit `98d8c1b`. `BUILD_SOURCE.txt`:
`SOURCE_COMMIT=98d8c1b…`, versão 0.15.16. O EXE arrancou, carregou o L1 e
passou a prova golden 7/7.

Um primeiro export a partir da árvore de trabalho saiu com 377 MB: arrastava os
`.worktrees/` e os master packages não rastreados (`export_filter=all_resources`),
o mesmo problema da 8.1B. Foi deitado fora e refeito do source commitado.

## J. Web/PWA

`build/web/` do mesmo commit: `index.pck` 53 562 232 bytes, SHA-256
`3b618698639c6f1ea1320e47f956c893346b9687fb7410d88a5217a696498c70`. Cache do
service worker: **`1789089732|5080222`** (antes `1789077283|4629041`).

**Cache velho apanhado e resolvido:** no browser o worker antigo ainda
controlava a página, o novo estava `waiting` e o PCK só existia na cache
velha — o jogo que corria era o build anterior. Ativei o worker novo (mensagem
`claim`, `controllerchange`), a cache velha foi apagada e recarreguei a página.
Depois disso, o `index.pck` na cache tem **exatamente o SHA-256 do export**
(verificado no browser), o jogo mostra v0.15.16 e a Koliani do Golden Set
(parada; ver o limite em H). O
worker gerado pelo Godot já trata disto sozinho quando se fecham os separadores
antigos; quem tiver a PWA aberta verá o build novo depois de a reabrir.

## K. Git

`master`: `98d8c1b` (código + assets). A documentação vai num commit à parte.
O `project.godot` da árvore do Paulo (reordenação do editor de
`ui_accept`/`ui_cancel`) ficou **por comitar e intacto**: só entrou a linha da
versão. Os worktrees do Paulo (`.worktrees/*`, `.claude/worktrees/*`) não
foram tocados.

## L. Bloqueios

Nenhum nesta execução. Fica registado, fora do âmbito: a CI de `master` já
estava vermelha antes da 9B.3, no passo "Nascer no checkpoint sem ficar
preso".

## M. Pronto para o pacote completo da Koliani?

**SIM.** O Golden Set está validado, integrado e visível no runtime Windows e
Web, com a identidade da autoridade aprovada.
