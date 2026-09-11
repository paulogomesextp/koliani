# Execution 9B.4 — Pacote completo da Koliani (produção)

Data: 11 de setembro de 2026 · Estado: **PASS — KOLIANI PRODUCTION GATE CLOSED**

## A. Git no início

`master` = `origin/master` = `7760d45`. Única alteração local: `project.godot`
(reordenação de `ui_accept`/`ui_cancel` feita pelo editor, do Paulo) —
**preservada e não comitada**; só entrou a linha da versão (0.15.16 → 0.15.17).
`.worktrees/`, master packages e restantes ficheiros não rastreados: intactos.

## B. Inventário dos estados em runtime

Fonte: `_atualizar_anim` / `_anim_locomocao_piloto_5g` em `scripts/koliani.gd`.
Os estados com habilidade (dash, salto duplo, escudo, escalar paredes) são
alcançáveis na Região I por um save que já as tenha — por isso contam todos.

| Estado | Alcançável? | Fonte visual antes | Agora | Ação |
|---|---|---|---|---|
| idle, run, jump_start, jump_loop, fall, attack | sim | Golden (9B.3) | Golden | — |
| turn, run_start, run_brake, land/aterrar, attack2–4, lancar | sim | Golden derivado (9B.3) | Golden derivado | — |
| dash | sim (hab. `dash`) | premium_v1 | **Golden derivado 9B.4** | produzido |
| roll | sim (sempre) | premium_v1 | **Golden derivado 9B.4** | produzido |
| hurt | sim (sempre) | premium_v1 | **Golden derivado 9B.4** | produzido |
| morte | sim (sempre, ~0,22 s antes do fade) | premium_v1 | **Golden derivado 9B.4** | produzido |
| crouch | sim (S no chão) | premium_v1 | **Golden derivado 9B.4** | produzido |
| wallslide | sim (hab. `escalar_paredes`) | premium_v1 | **Golden derivado 9B.4** | produzido |
| borda | sim (sempre) | premium_v1 | **Golden derivado 9B.4** | produzido |
| djump | sim (hab. `salto_duplo`) | premium_v1 | **Golden derivado 9B.4** | produzido |
| defesa | sim (hab. `escudo`) | premium_v1 | **Golden derivado 9B.4** | produzido |
| jump | **não** no caminho golden (a locomoção usa jump_start/loop) | premium_v1 | alias golden (jump_start 2–4) | só para fechar o legado |

Sem estado próprio no código (e por isso sem arte criada): interação/inspeção,
fogueira/checkpoint, gancho, planar, pogo — usam as poses de locomoção/ataque.
Ataque aéreo usa `attack` (golden).

## C. Animações novas

`tools/derivar_pacote_koliani_9b4.py`. Só frames golden **inteiros**,
com transformações sem perda: cópia byte-a-byte, translação por píxeis inteiros
e rotação exata de 90° (transpose). Nada redesenhado, redimensionado nem
interpolado. Cada frame guarda fonte, SHA da fonte e operação no manifesto.

| Anim | Frames | Derivação | fps (= tempo lógico) | Validator v2 | Runtime |
|---|---|---|---|---|---|
| dash | 3 | run 6, run 10, run 10 | 18,75 (0,16 s) | PASS | EXE ✔ |
| roll | 6 | jump_start 1 → jump_loop 3 a 0/90/180/270° → jump_start 1 | 20 (0,30 s) | PASS | EXE ✔ |
| hurt | 2 | fall 1, fall 2 | 8,33 (0,24 s) | PASS | EXE ✔ |
| morte | 3 | fall 1 → jump_start 2 → jump_start 1 (cai de joelhos) | 14 | REVIEW `POSE_AREA_VARIATION` | EXE ✔ |
| crouch | 1 | jump_start 1 (a antecipação agachada da autoridade) | 6 | PASS | EXE ✔ |
| wallslide | 2 | fall 1–2 com a frente na coluna da parede (x=74) | 6 | PASS | EXE ✔ (forçado) |
| borda | 1 | jump_start 4 com o punho no canto do rebordo (74,48) | 5 | PASS (sem baseline: pendurada) | EXE ✔ (forçado) |
| djump | 4 | jump_start 3–4, jump_loop 1–2 (sem o frame de 48 px) | 10 | REVIEW `POSE_AREA_VARIATION` | EXE ✔ |
| defesa | 1 | attack_basic 1 (guarda baixa, Shadowblade à frente) | 6 | PASS | EXE ✔ |

Os dois REVIEW são o mesmo achado que run/jump já tinham na 9B.3: a caixa muda
com a pose, a escala é a mesma (0,3975) e o número de píxeis visíveis não excede
o limite de resize. **0 FAIL.** Relatórios e contact sheets:
`work/production_art_gate/9b4/validator/`.

**Limites honestos (não bloqueiam, ficam registados):** a autoridade não tem
pose deitada nem de braços por cima da cabeça. A morte acaba de joelhos e o
rebordo é um agarrar ao nível do peito (pose de "mantle"). Os golpes 2–4
continuam a reutilizar os 6 frames do golpe 1 (9B.3). Se o Game Master quiser
poses próprias para estes casos, isso é **design novo** (condição A da
política) — não é defeito deste pacote.

## D. Identidade

Mesma rapariga em todos os estados: 16 anos, atlética, cabelo comprido e solto
preto → vermelho, lenço vermelho, mesma roupa e rosto. **Zero chibi**: nenhum
píxel foi escalado. Na 9B.4 retirou-se ainda o esmagamento por código do dash
(1,32 × 0,78) e a rotação contínua do roll, que deformavam o sprite golden.
Contact sheet do runtime: `work/production_art_gate/9b4/runtime_editor/runtime_crops_x2.png`.

## E. VFX (separados do corpo)

- golpe: `SlashVFX` (9B.3), inalterado;
- dash: `RastoDash` — ecos do frame golden a ser desenhado, roxo da
  Shadowblade, 0,18 s, no nível (não no corpo);
- salto duplo: `SaltoDuploVFX` — rajada de partículas nos pés;
- morte: `MorteVFX` — motes vermelhos a subir;
- dano: o flash branco existente (`_flash_branco`);
- defesa: o nó `Escudo` existente (placa + cúpula), à parte do corpo.

Exceção justificada: na `defesa` a Shadowblade faz parte da pose (relação
mão/arma), como nos frames do golpe aprovados.

## F. Eliminação do legado

**PREMIUM_V1 BODY USED IN REGION I: NO.**
**5G BODY USED IN REGION I: NO.**

Com `usar_golden_set` o `_montar_frames` deixa de carregar **qualquer** tira do
premium_v1 ou do rig do script (`anims = {}`), e o ramo da 5G está num `elif`
depois do golden. Auditoria: estes são os únicos sítios de todo o
`scripts/`+`scenes/` que carregam `koliani_premium_v1` ou
`koliani_visual_pilot_5g`. `usar_prototipo_premium = true` continua nas cinco
cenas mas já só afina a tinta do corpo (`_tint_armadura`), igual à 9B.3.
Os ficheiros legados ficam no repo (ferramentas 5B/5G e outros níveis). O teste
`teste_execution_9b4_pacote_golden_sem_legado` falha se algum frame da Koliani
do L1 vier de fora do `koliani_golden_set/`.

## G. Gameplay

**CONSTANTES ALTERADAS: NÃO.** Movimento, salto, dash, roll, câmara, colisão,
hitboxes, tempos de ataque, dano, save e checkpoints ficaram iguais. As
mudanças em `_animar`/`_flip_sprite` são só visuais. As animações foram
ajustadas aos tempos do jogo (fps), nunca o contrário.

## H. Testes

- Validator v2: 10/10 testes; 9 animações novas: 7 PASS, 2 REVIEW, 0 FAIL.
- Suite headless (`res://tests/run_tests.tscn`): **OK — todos os testes
  passaram**, incluindo o teste novo da 9B.4.
- Smoke L1: sem erros de script. O aviso `1 resources still in use at exit`
  também aparece na suite verde — não é desta execução.

## I. Evidência de runtime

`--foto-estado=pacote` (em `scripts/main.gd`): habilidades só em memória (nada
gravado). Dash, roll, defesa, agachar, salto duplo, dano e morte vão pelo input
e código normais do jogo; parede e rebordo são **forçados** (física parada) —
o início do L1 não tem essa geometria. Cada foto grava a animação e o recurso do
frame que está a ser desenhado.

- editor: `work/production_art_gate/9b4/runtime_editor/` (12 PNG + `pacote_registo.json` + `runtime_crops_x2.png`);
- **EXE exportado:** `work/production_art_gate/9b4/runtime_windows_exe/` —
  12/12 estados com textura `koliani_golden_set/frames/...`, escala 1,0,
  offset (0,−18).

## J. Windows

Exportado de um **worktree limpo** no commit `f912753` (0 alterações,
import sem erros). `build/windows/Koliani.exe`: 162 876 320 bytes, SHA-256
`31e89a6b2375a81ef994952eb732d693ee60cc7a4c432485deddfcdb36cf1b02`, v0.15.17.
Varrimento de bytes: 0 ocorrências de `res://work/`, `.worktrees/` e do
handoff; frames novos presentes. As strings `Koliani_1.0_Master_Package` /
`KOLIANI_VISUAL_AUTHORITY` que aparecem são só **texto** dentro dos
`manifest.json` da 9B.3 (caminhos de referência, uns KB) — não há imagem
nenhuma do pacote no build (o tamanho é o da 9B.3).

## K. Web/PWA

Mesmo commit e mesmo worktree. `index.pck` 53 708 176 bytes, SHA-256
`4c5ae22f5c2c2f5d9c25a272c2318f419f83e3cbe8404d29c03c68afb2a21a2c`; cache do
service worker **`1789108285|4479642`** (antes `1789089732|5080222`).
Smoke num servidor local numa origem nova: o PCK servido tem o SHA do export
(medido no browser), o menu mostra v0.15.17, o L1 carrega e a Koliani golden
aparece e salta com input real. Nesta origem nenhum service worker ficou a
controlar a página: o `index.html` do Godot só o instala quando faltam
funcionalidades, e este build single-threaded não tem nenhuma em falta. Logo não
havia cache nenhuma que pudesse servir um build antigo. Os estados novos não
foram fotografados um a um na Web: mesmo commit, mesmos recursos, nenhum código
visual por plataforma.

## L. Bloqueios

Nenhum. Backlog técnico (fora do âmbito): excluir `assets/**/manifest.json` dos
exports; CI de `master` vermelha antes da 9B.3 em "Nascer no checkpoint sem
ficar preso" (não tocado aqui).

## M/N. Gate

**KOLIANI GOLDEN SET: PRODUCTION INTEGRATED / HUMAN APPROVED.**
**KOLIANI FULL PACKAGE: PRODUCTION INTEGRATED (derivado do Golden Set).**
**KOLIANI PRODUCTION GATE: CLOSED. Pronto para 9C (kit de ambiente da Região I): SIM.**
