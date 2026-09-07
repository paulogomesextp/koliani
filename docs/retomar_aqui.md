# Retomar aqui — Koliani

Atualizado em 7 de setembro de 2026.

## Onde está o projeto

- Execution 1A: **DONE / PASS**.
- Execution 1A.1: **DONE / PASS**.
- Execution 1B: **DONE / PASS**.
- Execution 1C: **DONE / PASS**.
- Execution 2: **DONE / PASS**.
- Execution 3A: **DONE / PASS** — Save Foundation.
- Execution 3B: **DONE / PASS** — Stable Progression IDs.
- Execution 3C: **DONE / PASS** — Level Session + Checkpoint State.
- Execution 3D: **DONE / PASS** — Legacy Save / State Cleanup; schema v5.
- Execution 4A: **TECHNICAL PASS / HUMAN PLAYTEST REQUIRED** — primeiro passe
  de Movement + Camera; os parâmetros ainda não são finais.
- Execution 4B: **HUMAN-APPROVED** — transições da câmara aprovadas.
- Execution 5B: **TECHNICAL PASS / HUMAN PLAYTEST REQUIRED** — prototype
  Premium Pixel Art da Koliani, isolado ao Level 1.

Baseline confirmado: 74 testes, 0 falhas, localização PASS, manifesto com 100
níveis/20 regiões PASS, 100 cenas carregáveis, jornadas PASS e geradores de
cena/atmosfera não destrutivos por defeito. O nível 12 em Safari/PWA num
iPhone continua **DEVICE VALIDATION REQUIRED**.

## Execution 5B — retoma

A direção visual aprovada fica registada como **HYBRID CINEMATIC 2D**:
personagens/inimigos/bosses em Premium Pixel Art, ambientes com apresentação
cinematográfica por camadas e UI dark-fantasy minimal. Nesta execução só a
Koliani foi trabalhada.

O prototype `koliani_premium_v1` usa células 160×96, escala 0,75, altura
visual aproximada de 59 px e pés em y=22. Traz idle 4, run 5, jump 3, fall 2,
dash 3, basic attack 6, hurt 2 e death 5; estados restantes usam fallbacks do
mesmo visual. A propriedade `usar_prototipo_premium` está ativa apenas na
Koliani de `Floresta_Putrefata.tscn`; o rig Shadowblade anterior continua a
ser o default e o rollback é desligar essa propriedade.

Validação: targeted 5B PASS, smoke Level 1 PASS, Movement/Camera PASS, suite
completa 74/74, localização 701×6 PASS, captura OpenGL real e `git diff
--check` PASS. Build:
`build/windows/Koliani-Execution-5B-Hybrid-Character-dev.exe`.

O fluxo de morte não mudou e pode interromper a animação visual de death.
Qualidade, legibilidade e feel finais: **HUMAN PLAYTEST REQUIRED**.

## O que acabou de ser feito

A Execution 3D removeu Hardcore do runtime e do schema atual. O schema v5 não
grava nem aceita `hardcore`/`hardcore_tempo_restante`; schemas v0–v4 continuam
reconhecidos e a migration v4→v5 descarta apenas esses campos, sem reativar a
feature e sem perder campanha, level session, bosses ou recompensas.

Checkpoint por coordenadas continua restrito a v0–v3 e é convertido pela
migration v3→v4; v5 grava apenas `level_session`. Identidades legacy de
progressão continuam apenas nas migrations e stable IDs permanecem canónicos.

Validação 3D: Save Foundation 11/11, Level Session 11/11, Progression IDs 6/6,
Movement/Camera targeted PASS, suite completa 74/74, localização 701×6 PASS e
`git diff --check` PASS. Movement/Camera: **HUMAN-APPROVED PARAMETERS
UNCHANGED**.

## Baseline da Execution 3C

A Execution 3C elevou o schema a v4 e separou `level_session` da progressão
permanente. A sessão guarda apenas `level_id` e `checkpoint_id`; coordenadas
são resolvidas pela cena em runtime e nunca representam arbitrary frame save.
O lifecycle begin/activate/recover/complete/abandon ficou explícito. IDs usam
`checkpoint_<level_id>_<ordem>` e o spawn seguro `_start`; sessão inválida
converge para `_start` sem perder campanha.

Morte/reload reconstrói a cena e repõe Koliani no último checkpoint seguro.
Fechar/reabrir retoma esse checkpoint; sair deliberadamente para mapa/menu
abandona a sessão. Concluir regista progressão permanente e limpa a sessão.
Bosses derrotados não reaparecem após reload; baús já reclamados continuam
idempotentes.

Validação 3C: 10 targeted PASS; L5 nos cinco checkpoints com
activation/death/reload/movement/jump PASS; boss/reward runtime PASS;
migrations, backup e future version PASS; L1/L5/L12/L31 PASS; regressões
3A/3B/Movement+Camera PASS; suite completa 74/74; localização 701×6 PASS;
`git diff --check` PASS. Movement/Camera: **HUMAN-APPROVED PARAMETERS
UNCHANGED**.

## Baseline Movement + Camera

A Execution 4B respondeu ao playtest da 4A sem alterar movement. A confirmação
da troca de direção horizontal passou de 0,10 s para 0,14 s e a resposta do
look-ahead de 5,8 para 3,8. Na vertical, a resposta passou de 8,5 para 5,0 e o
fall framing passou a exigir progressão conjunta de distância e velocidade,
eliminando o salto de alvo quando apenas um dos sinais já estava alto.
Distância de look-ahead, deadzone, limiares e visibilidade inferior foram
preservados.

Validação 4B: targeted Movement + Camera PASS; regressão de movement PASS;
smoke L1 PASS (run/jump/dash); smoke L5 PASS; cenário de queda e recenter PASS;
suite completa PASS, 0 falhas; `git diff --check` PASS. Build dev:
`build/windows/Koliani-Execution-4B-dev.exe`.

Os parâmetros foram posteriormente **HUMAN-APPROVED**. A 3C não os alterou.

## Baseline da Execution 4A

A Execution 4A centralizou aceleração, desaceleração e resposta de viragem,
deu à queda uma gravidade ligeiramente superior à subida e formalizou
aterragens light/medium/heavy sem input lock. A câmara ganhou look-ahead
horizontal com histerese, deadzone para hops, antecipação progressiva de
quedas e níveis de tremor Full/Reduced/Off. Dash, input, parede, gancho,
checkpoint e reload mantiveram os contratos existentes.

Validação: targeted Movement + Camera PASS; L1/L5/L12/L31 smoke PASS; ciclo
dos cinco checkpoints ativos do L5 com morte/reload/saída/salto PASS; atores e
gancho PASS; 100/100 cenas carregáveis; suite completa e localização PASS;
`git diff --check` PASS. Build dev:
`build/windows/Koliani-Execution-4A-dev.exe`.

**HUMAN PLAYTEST REQUIRED** para aceitar ou reafinar feel, distâncias,
resposta, tiers e conforto da câmara. Não iniciar 4B/4C antes dessa decisão.

## Baseline persistente anterior

A Execution 3B elevou o schema a v3 e acrescentou a migration sequencial
v2 → v3. O save atual usa IDs estáveis para nível atual/concluídos, bosses,
abilities, pistas/collectibles e recompensas únicas de baú. Níveis e bosses
reutilizam o manifesto da Execution 2; abilities têm mapping central e pistas
reutilizam o catálogo existente. Operações set-like são idempotentes e o baú
de boss não volta a atribuir recompensa após reload. Saves v2 preservam a
progressão equivalente; referências legacy desconhecidas são recusadas em vez
de adivinhadas. TEMP, backup/recovery, Hardcore e checkpoint mantêm a semântica
da 3A.

## O que vem a seguir

1. Playtest humano do build 5B no Level 1: silhueta, escala, animação,
   Shadowblade e leitura durante gameplay.
2. Manter pendente a validação do nível 12 num iPhone real com Safari/PWA.
3. Não iniciar ambiente Hybrid, UI, 4C ou o Visual Target seguinte sem pedido.

## Fonte canónica

- Visão e scope 1.0: [visao_koliani_1_0.md](visao_koliani_1_0.md)
- Decisões: [decisoes.md](decisoes.md)
- Estado das execuções: [execution_dashboard.md](execution_dashboard.md)
- Riscos e dívida: [backlog_tecnico.md](backlog_tecnico.md)
- Regras de agentes: [AGENTS.md](../AGENTS.md)

A auditoria de Execution 0 é evidência histórica, não o estado operacional
atual. Não repetir auditorias completas nesta retoma.
