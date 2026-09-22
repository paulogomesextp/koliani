# Level Selector Redesign — Prompt 3

## STATUS

IMPLEMENTADO / QA TÉCNICO PASS / HUMAN PLAYTEST REQUIRED

## BRANCH

`codex/level-selector-redesign`

## HEAD inicial / HEAD final

- Inicial: `cb38481cb0c1a5615d96382513d0a919ce6a518e`
- Final: `91dacd7b388e155cf8cd669b851e16db37e167e4`

## STRUCTURE

PASS — a grelha de 20 cards foi substituída por um carousel com uma região
focada, vizinhas laterais discretas, painel de detalhe e entrada para os cinco
níveis da região. A estrutura de 20 regiões × 5 níveis permanece em
`EstadoJogo.REGIOES`.

## VISUAL MATCH TO MAIN MENU

PASS técnico/visual em captura desktop — fundo de região, carvão, carmesim,
molduras de painel, foco único e botões da família `Frontend9H`.

## REGION CAROUSEL

PASS — `ui_left`/`ui_right`, setas visíveis, mouse e foco de região. Só três
posições são visíveis ao mesmo tempo; todas as 20 regiões continuam acessíveis.

## LEVEL SUBMENU

PASS — cinco níveis da região, foco horizontal, nome, estado e boss no quinto
nível; voltar regressa ao carousel.

## SAVE / UNLOCK

PASS — QA dirigido confirma estados `CURRENT`, `COMPLETED`, `UNLOCKED` e
`LOCKED`, desbloqueio e save inalterados.

## INPUT

- mouse: PASS no QA dirigido e nas capturas reais
- keyboard: PASS no QA dirigido (`ui_left`, `ui_right`, `ui_accept`, `ui_cancel`)
- controller: fluxo de ações simulado no QA; `DEVICE VALIDATION REQUIRED` para
  comando físico

## TESTS

- `res://tests/qa_level_selector_pass1.tscn`: PASS
- cobertura estrutural: 20 regiões, 100 níveis, sem duplicados/ausências,
  bosses N05/N10/N15 … N100: PASS
- captura renderer real OpenGL Compatibility em 1280×720: PASS visual, sem
  clipping evidente
- captura renderer real OpenGL Compatibility em 1920×1080: PASS visual, sem
  clipping evidente
- `git diff --check`: PASS
- leaks/recursos no encerramento: avisos preexistentes do harness, não tratados
  nesta tarefa

## BUILD

Export Windows QA concluído em:
`work/qa_level_selector_redesign/Koliani-QA.exe`

O smoke automatizado do executável não foi certificado porque a flag interna de
fotografia não foi encaminhada pelo export da mesma forma que no editor; a
janela foi encerrada após o timeout. O export em si terminou sem erro fatal.

Capturas:

- `work/qa_level_selector_redesign/selector_1280.png`
- `work/qa_level_selector_redesign/selector_1920.png`

## COMMIT

`91dacd7b388e155cf8cd669b851e16db37e167e4` — commit único desta branch.

## BLOCKERS

- HUMAN PLAYTEST REQUIRED para sensação, transições e juízo final de direção
  visual.
- DEVICE VALIDATION REQUIRED para comando físico e alvos reais.
- Não houve alteração de gameplay, áudio, save ou unlock.
