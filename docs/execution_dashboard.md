# Execution dashboard — Koliani

Atualizado em 10 de setembro de 2026.

| Execução | Estado | Resultado / saída |
|---|---|---|
| Execution 0 | DONE | Auditoria histórica; baseline posteriormente atualizado. |
| Execution 1A | DONE | PASS — runner/baseline estrutural restaurado. |
| Execution 1A.1 | DONE | PASS — localização e validações associadas fechadas. |
| Execution 1B | DONE | PASS — riscos estruturais validados dentro do âmbito. |
| Execution 1C | DONE | PASS — documentação canónica normalizada. |
| Execution 2 | DONE | PASS — manifesto 1–100 e geradores não destrutivos por defeito. |
| Execution 3A | DONE | PASS — schema v2, migrations sequenciais, safe write, backup e recovery. |
| Execution 3B | DONE | PASS — schema v3 e stable IDs para progressão/recompensas. |
| Execution 3C | DONE | PASS — Level Session v4 e safe checkpoint recovery. |
| Execution 3D | DONE | PASS — Hardcore removido do runtime/schema atual; legacy migra para v5. |
| Execution 4A | TECHNICAL PASS | Movement + Camera first pass; HUMAN PLAYTEST REQUIRED. |
| Execution 4B | HUMAN-APPROVED | Camera transition tuning aprovada pelo utilizador. |
| Execution 5B | TECHNICAL PASS | Koliani Premium Pixel Art v1 no Level 1; HUMAN PLAYTEST REQUIRED. |
| Execution 5C | TECHNICAL PASS | Region I Hybrid Cinematic Visual Target no início do Level 1; HUMAN VISUAL REVIEW REQUIRED. |
| Execution 5G.1 | TECHNICAL PASS / HUMAN VISUAL FAIL | Piloto integrado; corte visual inferior reportado pelo Game Master. |
| Execution 6A | PARTIAL VISUAL BUILD | Panorama, Heart Tree, cascatas e ruínas integrados; PRODUCTION ASSETS MISSING. |
| Execution 6B | PARTIAL PASS | Sete frames `run` recuperados; 44/44 safe; Level 1 preservado até ao limite da autoridade; HUMAN VISUAL REVIEW REQUIRED. |
| Execution 7 | PARTIAL PASS | Combate 3-hit/aéreo/Dash, guardiões L1–L4 e Coração Putrefacto L5 integrados; gates técnicos PASS; HUMAN VISUAL/FEEL/BALANCE/PLAYTEST REQUIRED. |
| Execution 8 | PARTIAL PASS | Runtime real traçado; Koliani 6B e panorama aprovado ativos L1–L5; debug UI escondida em release; Windows/Web-PWA e provas reais PASS; produção visual e revisão humana pendentes. |

## Baseline após a Execution 3D

- Suite: **74 testes, 0 falhas**.
- Localização: **PASS**.
- Save Foundation: **PASS** — fresh/roundtrip, legacy v0→v1→v2→v3→v4→v5,
  corrupção/recovery, escrita/TEMP/migration inválidos e versão futura.
- Stable Progression IDs: **PASS** — v2→v3, níveis/bosses/abilities/
  collectibles/rewards, idempotência, IDs inválidos e rename resilience.
- Level Session: **PASS** — begin/activate/recover/complete/abandon explícitos;
  `checkpoint_<level_id>_<ordem>`; close/reopen no último checkpoint seguro;
  fallback `_start` para sessão inválida sem perda de campanha.
- Validador do nível 5: **PASS**.
- Nível 12 desktop/OpenGL: **PASS**.
- `SalaLabirinto` deterministic validator: **PASS**.
- Level Source of Truth: **PASS** — 100 níveis, 20 regiões, 5 por região.
- Generator Safety: **PASS** — staging e proteção por ownership.
- Cenas runtime: **PASS** — 100/100 carregáveis no Godot 4.7.2.
- Jornadas: **PASS** — 100 níveis verificados.
- Nível 12 iPhone Safari/PWA: **DEVICE VALIDATION REQUIRED**.

## Regra de leitura

`DONE` significa que a execução cumpriu o seu critério, não que todos os riscos
do projeto desapareceram. A pendência de dispositivo do nível 12 permanece no
[backlog técnico](backlog_tecnico.md) e não reabre a Execution 1B.

Os níveis 31–100 permanecem `ownership = unknown` por decisão conservadora e
estão protegidos contra promoção. Reclassificá-los exige evidência e alteração
explícita do manifesto; não faz parte da próxima execução.

Execution 3D terminou. 4C não foi iniciada.

## Execution 5C — evidência técnica

- Target exclusivo do Level 1 em `x=-300..1250`, aproximadamente dois ecrãs.
- Oito grupos visuais: background, Heart Tree, midground, gameplay skin,
  corrupção, atmosfera, foreground e iluminação seletiva.
- Módulo sem física; spawn, quatro plataformas iniciais, body 20×44 e hitbox
  30×34 em `(23,-4)` verificados sem mudanças.
- Shadowblade reage ao ataque existente com violeta limpo; corrupção usa
  preto/violeta sujo/magenta.
- Skin do HUD local, reversível e sem alteração de lógica.
- `ativo=false` provado: invisível e zero conteúdo montado.
- Targeted 5C, 5B, Movement/Camera, alcance do Level 1 e smoke/capturas Forward
  Mobile: PASS.
- Suite completa 74/74; localização 701×6 preservada; `git diff --check` PASS.
- Capturas: `work/execution_5c/region1_hybrid_idle.png` e
  `work/execution_5c/region1_hybrid_attack.png`.
- Orçamento: 406 nós, três luzes, um emissor CPU/34 partículas; profiling
  Web/mobile requerido antes de escalar.
- Estado visual: **HUMAN VISUAL REVIEW REQUIRED**.

## Execution 5B — evidência técnica

- Direção: **HYBRID CINEMATIC 2D**; personagens/inimigos/bosses em Premium
  Pixel Art, ambientes em Cinematic Layered Presentation e UI Cinematic
  Dark-Fantasy Minimal.
- Âmbito desta execução: apenas a personagem Koliani.
- Prototype 160×96, escala 0,75, ~59 px visuais e pés em y=22.
- Animações prioritárias: idle 4, run 5, jump 3, fall 2, dash 3, basic attack
  6, hurt 2 e death 5; fallbacks coerentes no mesmo rig.
- Ativação exclusiva por instância no Level 1; rig Shadowblade anterior
  preservado como default/rollback.
- Colisão, hitbox, movement, camera, combat timings, save e progressão:
  **UNCHANGED**.
- Targeted 5B, smoke Level 1 e regressão Movement/Camera: **PASS**.
- Suite completa 74/74; localização 701×6; `git diff --check`: **PASS**.
- Captura OpenGL: `work/execution_5b/koliani_premium_level1.png`.
- Windows dev:
  `build/windows/Koliani-Execution-5B-Hybrid-Character-dev.exe`.
- Estado visual: **HUMAN PLAYTEST REQUIRED**.

## Execution 3D — evidência

- Schema v5 remove `hardcore` e `hardcore_tempo_restante` do formato atual.
- Schemas v0–v4 continuam validados; v4→v5 elimina apenas esses campos e
  preserva progressão permanente e `level_session`.
- Menu/runtime atual já não cria nem consome Hardcore; o valor legacy nunca
  reativa a feature removida.
- Save Foundation 11/11, Level Session 11/11, Progression IDs 6/6 e regressão
  Movement/Camera PASS.
- Suite completa 74/74, localização e `git diff --check`: PASS.
- Movement/Camera: **HUMAN-APPROVED PARAMETERS UNCHANGED**.

## Execution 4A — evidência técnica

- Movement + Camera targeted: **PASS** (24 contratos técnicos).
- L1/L5/L12/L31 smoke: **PASS**; dash integrado preservado.
- L5 checkpoint/death/reload: **PASS** nos cinco checkpoints ativos.
- Atores, gravidade invertida e gancho: **PASS**.
- Cenas runtime: **100/100 carregáveis**.
- Suite completa/localização: **PASS, 0 falhas**.
- `git diff --check`: **PASS**.
- Windows dev: `build/windows/Koliani-Execution-4A-dev.exe`.

Na conclusão da 4A, movement e câmara ainda exigiam playtest humano; esse
playtest originou a afinação dirigida da 4B. A 4A não iniciou 3C/3D.

## Execution 4B — evidência técnica

- Feedback humano tratado: reversals horizontais e transições verticais de
  queda/aterragem demasiado bruscos.
- Horizontal: confirmação 0,10 s → 0,14 s; resposta 5,8 → 3,8.
- Vertical: resposta 8,5 → 5,0; blend de fall framing sem descontinuidade ao
  cruzar apenas um limiar.
- Distância de look-ahead, deadzone, limiares, movement e sistemas adjacentes:
  preservados.
- Targeted Movement + Camera, regressão de movement, smokes L1/L5 e cenário
  de queda/recenter: **PASS**.
- Suite completa: **PASS, 0 falhas**.
- `git diff --check`: **PASS**.
- Windows dev: `build/windows/Koliani-Execution-4B-dev.exe`.

A afinação 4B foi **HUMAN-APPROVED** antes da Execution 3C. Os parâmetros de
movement/camera não foram alterados pela 3C. Execution 4C não foi iniciada.

## Execution 3C — evidência

- Schema v4: campaign progress continua permanente; `level_session` contém
  apenas level/checkpoint stable IDs; coordenadas são contexto runtime.
- Migration v3→v4: checkpoint zero torna-se sessão inativa; coordenada legacy
  não-zero, ambígua, converge para o `_start` seguro do mesmo nível.
- Level 5: cinco checkpoints ativos, IDs estáveis e ciclo
  activation→death→reload→movement/jump PASS.
- Boss/reward: boss derrotado não reaparece; baú único reclamado não duplica;
  porta é recomposta aberta após reload.
- L1/L5/L12/L31, regressões 3A/3B/4A-4B, suite completa, localização e
  `git diff --check`: PASS.
