# Plano atual — Execution 6B Character + Level 1 Completion

## Objetivo, âmbito e critério de conclusão 6B — 10 setembro 2026

Provar a causa end-to-end do corte visual do corpo inferior da Koliani,
corrigir apenas pixels legítimos recuperáveis das autoridades `01`–`07` e
usar fallbacks aprovados para qualquer frame irrecuperável. Em seguida,
integrar no Level 1 apenas os elementos de produção já derivados e validados
das autoridades `08`–`12`, preservando o panorama/Heart Tree/cascatas/ruínas
da 6A e toda a geometria, colisão, percurso, movimento, câmara, AI, combate,
save e progressão.

Âmbito de cena: `scenes/levels/Floresta_Putrefata.tscn` e o módulo visual que
ela já instancia. Âmbito de personagem: construção visual do piloto 5G no
`scripts/koliani.gd`, strips correspondentes e ferramentas/diagnósticos 6B.
Não abrange 6C, Levels 2–5, Android/iOS, novas famílias de inimigos, novos
sistemas, novo design ou reconstrução generativa de arte.

Critério: rastreio de todos os 44 frames integrados mais fallbacks; evidência
`koliani_lower_body_trace.png`; targeted de Koliani/animações/Level 1,
Movement+Camera, colisão e alcance; suite completa; capturas reais 6B e
comparação 6A→6B; builds Windows e Web/PWA finais com cache atualizado e
commit de origem registado; commit/push único apenas se não misturar trabalho
local alheio. Qualidade estética e feel terminam obrigatoriamente como
`HUMAN VISUAL REVIEW REQUIRED`.

## Prova por etapa 6B

1. Fixar path, dimensões, modo, SHA-256 e domínio visual das 12 fontes.
2. Rastrear fonte→recorte→RGBA→normalização→strip→import→atlas→transform→
   câmara→render/export; classificar perda por frame.
3. Corrigir só a etapa provada, mantendo escala `0,82`, offset
   `-15,170732`, pivot `(80,90)`, canvas `160×96` e baseline lógica `Y=90`.
4. Validar Phase A e capturar gameplay real antes de continuar.
5. Inventariar as faltas 6A e integrar somente replacements de produção já
   validados, sem alterar nós físicos ou contratos de inimigos/HUD/áudio.
6. Executar validações dirigidas, alcance, suite completa, render real,
   Windows smoke, Web/PWA smoke, rastreabilidade, Git e documentação.

## História preservada

- 5G.1: **TECHNICAL PASS / HUMAN VISUAL FAIL**.
- 6A: **PARTIAL VISUAL BUILD / PRODUCTION ASSETS MISSING**.
- 6B: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW REQUIRED**.

## Resultado 6B

A extração irregular da faixa `run` foi corrigida deterministically na fonte
aprovada: 44/44 frames ativos `SAFE`, sete `FIXED`, zero bloqueados. O Level 1
6A foi preservado e nenhum lote meramente `validated` foi promovido. Targeted,
alcance, suite completa, render real, Windows e Web/PWA passaram; cache PWA
atual `1789047133|5780304`. Relatório:
`docs/execution_6b_character_level1_completion.md`.

Paragem: **HUMAN VISUAL REVIEW REQUIRED**. Não iniciar 6C nem Levels 2–5.

---

# Histórico — Execution 6A Level 1 Approved Visual Build

## Lote de sprites modulares da Região I — 10 setembro 2026

Objetivo: converter as autoridades visuais aprovadas 08 e 10 em sprites
ambientais individuais e consistentes. Âmbito: os 12 ficheiros já definidos no
`artkit_manifest.json` (terreno, plataformas, bordas, cantos, overlays e bloco
de ruína), sem integração em cenas, sem alterações de gameplay, geometria,
Koliani ou do bloqueio 5G.1. Critério: PNGs nas dimensões contratuais, alfa e
nearest-neighbour válidos, fontes preservadas, hashes registados, importação
Godot e prancha de revisão concluídas. Aprovação estética permanece
`HUMAN REVIEW REQUIRED`.

Estado: **PARTIAL VISUAL BUILD / PRODUCTION ASSETS MISSING — HUMAN REVIEW REQUIRED**.

## Objetivo, âmbito e critério de conclusão 6A

Transformar apenas o Level 1 numa aproximação técnica do target visual já
aprovado para a Região I. Produzir e integrar só derivações determinísticas
que passem o gate técnico, preservar integralmente a geometria, colisões,
percurso, métricas de salto, checkpoints, saída e Koliani 5G.1, e classificar
sem redesign tudo o que continuar sem asset de produção.

O lote abrange backgrounds, parallax, Heart Tree, apresentação visual das
plataformas, ruínas, vegetação, atmosfera, VFX, props, inimigos existentes,
HUD e áudio do Level 1. Não abrange outros níveis, alterações de gameplay,
novas espécies, cinematics ou decisões de design.

Critério de conclusão: fontes 01 e 08–12 verificadas técnica e visualmente;
todo o material seguramente derivável integrado; cena importável; alcance e
invariantes do Level 1 preservados; targeted checks, suite final única,
renderer real e `git diff --check` executados; revisão visual subjetiva
separada como `HUMAN REVIEW REQUIRED`; faltas classificadas como
`APPROVED DESIGN / PRODUCTION ASSET MISSING`.

## Prova por etapa 6A

1. Fixar SHA-256, dimensões, modo e leitura visual das seis autoridades.
2. Extrair por crop lossless apenas regiões sem texto, moldura ou elementos
   contaminantes; validar formato, dimensões e ausência de alteração de fonte.
3. Integrar através do módulo visual exclusivo do Level 1, sem nós físicos.
4. Import/smoke, verificador 6A, Movement + Camera e alcance do Level 1.
5. Capturar spawn, travessia, plataformas, Heart Tree, encontro, meio,
   atmosfera e saída num renderer real; gerar comparação before/after.
6. Executar a suite completa uma vez no fim e `git diff --check`.

## Rollback 6A

`Region1HybridVisualTarget.ativo = false` continua a remover integralmente a
camada 6A sem alterar gameplay, geometria ou os assets anteriores.

## Resultado comprovado 6A

Panorama/Heart Tree 08 integrados por crop lossless; formas genéricas 5C
substituídas; 29 nós, 3 luzes e 1 emissor. Targeted 6A, 5G.1,
Movement/Camera, alcance, renderer em oito pontos e suite completa passaram.
Tiles, layers alpha, props, inimigos, HUD e áudio aprovados continuam
`PRODUCTION ASSET MISSING`. Relatório:
`docs/execution_6a_level1_implementation.md`.

## Histórico — Execution 5G.1 Correção Visual do Level 1

Estado: **PARTIAL PASS / HUMAN PLAYTEST REQUIRED**.

## Objetivo e âmbito

Corrigir apenas escala, offset e apresentação do piloto 5G no Level 1, medir
todos os frames únicos ativos e identificar a causa do clipping observado,
preservando gameplay, colisões, hitboxes, câmara, combate, save, sessão,
localização, progressão, geometria e gerador.

## Diagnóstico e correção

- as sete sequências integradas somam 44 frames únicos, não 45; o total 45 da
  recuperação inclui `run_brake_01`, que não é usado pelo fallback atual;
- 37 frames `SAFE`, 0 `TIGHT_MARGIN`, 0 `CLIPPING_RISK` e 7
  `ACTUAL_CLIPPING` (`run_03`–`run_09`);
- nenhum frame toca o canvas `160×96`; as margens mínimas normalizadas são
  12 px no topo, 38 px nos lados e 6 px no fundo;
- `run_03`–`run_06` já tocam o limite esquerdo do recorte-fonte e `run_07`–
  `run_09` o limite direito. Padding, offset ou escala não recuperam os pixels
  ausentes sem inventar arte;
- escala global do piloto no Level 1 aumentada de `0,75` para `0,82`; offset Y
  alterado de `-12,666667` para `-15,170732`, mantendo pés em `y=22`, pivot
  `(80,90)` e baseline opaca `Y=89`;
- sprites, canvas, offsets por animação e gameplay não foram alterados.

## Provas executadas

- relatório determinístico: `37 SAFE / 7 ACTUAL_CLIPPING`;
- verificador 5G dirigido: PASS para contagens, fallbacks, escala, baseline,
  colisão, hitbox, isolamento ao Level 1 e seleção das transições;
- targeted Movement + Camera 4A: PASS;
- alcance do Level 1: 20 plataformas e porta alcançável: PASS;
- suite completa: PASS;
- smoke/captura real OpenGL 3.3 / NVIDIA RTX 5070: PASS; os erros de escrita
  em `user://`, certificados e opções são ambientais já conhecidos.

## Evidência e ficheiros 5G.1

- `scripts/koliani.gd` e `tools/verifica_koliani_visual_pilot_5g.gd`;
- `tools/shot_koliani_visual_pilot_5g_1.gd` e `.tscn`;
- `work/execution_5g_1/frame_margin_report.json` e
  `work/execution_5g_1/preview/before_after_visual_fix.png`;
- `PRIORIDADES.md`, `docs/plano_atual.md` e `docs/retomar_aqui.md`.

## Paragem e próximo passo

**PARTIAL PASS / HUMAN PLAYTEST REQUIRED.** A escala e baseline passaram
tecnicamente, mas os sete recortes de corrida permanecem. Próximo passo único:
Paulo jogar o Level 1 e validar escala `0,82`, contacto com plataformas, face,
centro visual e popping das transições antes de aceitar esta correção.

## Histórico — Execution 5D.2 Reconstrução limpa

Estado histórico: **MASTER TECHNICAL PASS / HUMAN VISUAL REVIEW REQUIRED**.

## Resultado desta execução

- master novo criado de raiz, sem extração das pranchas aprovadas;
- `160×96`, RGBA, alpha `0/255`, baseline `Y=90`, altura visual `66 px`;
- fonte editável/determinística em `tools/generate_koliani_master.py`;
- contrato, árvore dos 40 frames e pastas de VFX separados preparados;
- gate atual: master `PASS`, lote `PENDING 0/40`, runtime bloqueado;
- gameplay, cenas e integração ficaram intactos;
- relatório: `docs/execution_5d_2_sprite_production.md`.

## Próxima execução — não iniciada

Fazer revisão visual humana do master. Apenas se aprovado, produzir Idle 10,
Run 12, Jump Start 4, Jump Loop 4, Fall 4 e Land 6 mantendo-o como âncora de
identidade. Validar `40/40 PASS` antes de montar strips ou integrar runtime.

## Histórico encerrado — Execution 5D Production Asset Gate

Estado histórico: **ART ASSET REQUIRED**. As referências `01`–`07` ficaram
`REFERENCE_ONLY`; detalhes em `docs/execution_5d_asset_gate.md`.

## Histórico encerrado — Master Package v2 Verification

### Resultado histórico

- pacote `Koliani_1.0_Master_Package_v2/` localizado e estruturalmente íntegro;
- 12/12 referências aprovadas presentes, legíveis e com SHA-256 correto;
- autoridade e precedência da Koliani coerentes com visão/decisões locais;
- índice de integração corrigido para o v2;
- runtime, cenas, gameplay, imagens e assets inalterados;
- production-ready status: **NOT EVALUATED IN THIS EXECUTION**.

### Próxima execução então registada — concluída pela 5D

Com Luna Medium, executar o asset gate técnico de `01`–`07`. Se as fontes não
permitirem frames RGBA nativos/separáveis que cumpram identidade, alpha,
grelha, baseline, pivot e separação de VFX, terminar `ART ASSET REQUIRED` sem
integração. Só após PASS, preparar idle/run/jump/fall/land e integrar o
prototype de forma reversível apenas no Level 1, preservando todo o gameplay.

## Histórico encerrado — Execution 5C

## Objetivo

Criar uma amostra curta e reversível da direção **HYBRID CINEMATIC 2D** no
início do Level 1, com diferença imediatamente visível em gameplay normal,
sem adaptar gameplay à arte.

## Secção target

- Level 1, intervalo visual aproximado `x = -300..1250`;
- entrada, `ChaoInicio` e `Passo1..3`;
- cerca de dois ecrãs / 15–30 segundos do percurso normal;
- geometria, colisões, checkpoints e posições autorais preservados.

## Âmbito autorizado

- módulo visual próprio e exclusivo do Level 1;
- background, midground, foreground, vegetação, Heart Tree distante,
  iluminação, névoa, partículas e corrupção;
- revestimento visual das superfícies existentes, sem física;
- assinatura visual limpa da Shadowblade, reagindo ao ataque existente;
- pequena skin reversível das barras já existentes no HUD;
- verificador e captura específicos da Execution 5C.

## Fora do âmbito

- remodelar o resto do Level 1 ou qualquer outro nível;
- alterar `scripts/movimento.gd`, câmara, colisões, hitbox, tempos, dano,
  combate, save, progressão, checkpoints, recompensas ou localização;
- escalar a direção antes da revisão humana.

## Critério de conclusão

- baseline prévia 74/74 e 701 chaves × 6 confirmada;
- módulo sem qualquer `CollisionObject2D` e referência exclusiva no Level 1;
- targeted, cena afetada, regressão Movement/Camera, estrutural relevante e
  suite completa uma vez no fim, todos PASS;
- duas capturas reais: idle/movement e ataque/Shadowblade;
- rollback e riscos de performance documentados;
- resultado final limitado a `TECHNICAL PASS / HUMAN VISUAL REVIEW REQUIRED`,
  `TECHNICAL FAIL` ou `ART ASSET REQUIRED`.

## Prova por etapa

1. Baseline antes de editar: suite e catálogos.
2. Verificador 5C: isolamento, ausência de física e invariantes da secção.
3. Smoke OpenGL real do Level 1.
4. Regressão Movement/Camera e alcance do Level 1.
5. Capturas reais pelo `Main`, incluindo HUD e input de ataque.
6. Suite completa uma vez no fim e `git diff --check`.

## Rollback previsto

`VISUAL TARGET ON`: instância `Region1HybridVisualTarget` com `ativo = true`
em `Floresta_Putrefata.tscn`.

`VISUAL TARGET OFF`: definir `ativo = false` nessa instância. O módulo deixa
de montar camadas, luzes, partículas, assinatura da lâmina e skin do HUD; a
cena regressa aos visuais anteriores sem Git reset/revert.

## Evidência final

- baseline antes: 74/74 e 701×6 PASS;
- targeted 5C + rollback OFF: PASS;
- prototype 5B: PASS;
- Movement + Camera: PASS;
- Level 1: 20 plataformas, porta alcançável: PASS;
- smoke/capturas Forward Mobile reais: PASS;
- suite completa final: 74/74 PASS;
- localização: 701×6 preservada;
- referência exclusiva em `Floresta_Putrefata.tscn`;
- ficheiros protegidos sem diff; `git diff --check` PASS.

## Capturas

- `work/execution_5c/region1_hybrid_idle.png`;
- `work/execution_5c/region1_hybrid_attack.png`.

## Risco de performance

O target monta 406 nós visuais, três luzes e um emissor CPU com 34 partículas.
Não há shader novo nem dezenas de luzes, mas a quantidade de CanvasItems deve
ser medida em Web/Android/iOS antes de qualquer reutilização. Não otimizar nem
escalar antes da revisão visual humana.

## Paragem

Execução encerrada tecnicamente. Não declarar aprovação visual nem começar o
próximo lote: **HUMAN VISUAL REVIEW REQUIRED**.
