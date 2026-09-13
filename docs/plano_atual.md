## 9H.19 — áudio vertical slice: paragem no gate de fontes

- Objetivo: 12 candidatos físicos/orgânicos, música candidata, A/B Dev e Windows validado, sem propagação antes de escuta humana.
- Âmbito exclusivo de áudio; preservar mixer/save e restantes sistemas.
- Hipóteses dirigidas: packs locais, arquivos/histórico, instrumentos/stems.
- Auditoria/brief concluídos em `docs/execution_9h19_audio_vertical_slice.md`; adequação profissional não estabelecida. PROFESSIONAL PRODUCTION ASSET REQUIRED.
- Critério de retoma: fontes selecionadas por escuta e proveniência/licença suficiente; depois produzir B. B–F não iniciadas; execução INCOMPLETE.

## 9H.16 — L1 Perfection: PHASE A em curso (13 set 2026)

- Briefing autoritativo recebido no anexo pasted-text; ordem A→B→C→D→E→F, sem avanço antes do fecho/commit/push da fase. Base f29b8f5c, branch codex/9h16-l1-perfection, worktree C:/Projetos/koliani-9h16.
- Objetivo A: reproduzir/classificar/corrigir fecho Windows após derrotar Ghorak e atravessar L1→L2. Scope: callbacks/colisões/recompensa de morte/Porta/EstadoJogo/spawn L2. Sem arte nova ou mudanças de design.
- Hipóteses: divergência da build; mutação de física na morte; transição/spawn/resource failure. WER confirma crash nativo c0000005 (versões PE 0.18.6 e 0.18.2, RVA 0x16b3420). EXE no destino foi substituído antes desta execução: SHA256 fe7de41f1 no sufixo, versão runtime 0.18.7; crash anterior ainda não reproduzido nesta base.
- Prova dirigida Ghorak vida=1, ataque por input, aproximação contínua da morte ao portal: reproduz sete area_set_shape_disabled em _soltar_essencia_chefe/cena.add_child durante callback _ao_acertar_corpo. L2 ainda carrega nesta prova (headless e Vulkan real). Não atribuir ao crash causalidade sem evidência.
- Alteração técnica delimitada: adiar inserção de Essencia inteira em ChefeBase e DemonioBase; sem alterar valores nem assets. Critério local: morte por hitbox real, recompensa exata e ausência de flushing queries.
- Aceitação da fase: EXE Windows real, cinco entradas (normal/corrida/salto+dash/efeitos/novo processo), L2 spawn válido, sem crash/softlock/flushing queries; zero falhas novas além das 26 baseline; QA crítico com limites, commit/push isolados só após fase concluída.
- B–F não iniciadas. NATIVE ART REQUIRED se faltar fonte. HUMAN PLAYTEST REQUIRED e DEVICE VALIDATION REQUIRED nos pontos dependentes de sensação/hardware mobile.

# Plano atual — Execution 9H: frontend de produção + slice final da Região I

## 9H.16 continuação — Phase B (13 setembro 2026)

- Objetivo: Dev Mode temporário com progresso normal isolado em memória.
- Âmbito: estado, dano/HP Dev, barra periférica, traduções e provas dirigidas.
- Conclusão: B1–B7 cobertos, QA com input no export Windows limpo, zero
  poluição de save, testes sem regressões além das 26 falhas visuais antigas;
  só então commit/push da fase e avanço para C. A fechada em 9eda04e0.
- Histórico reutilizado: b59f0b8d (sandbox/seletor), ab78a04b (FlyMode),
  scripts atuais. Nenhum desenvolvimento em L2+; L20/50/100 só QA Dev pedido.
- Checkpoint técnico validado; fase continua INCOMPLETE. Provas sintéticas e
  Vulkan registadas na retoma; build Dev separada em C:/Temp. Paragem perto do
  limite usage. Próximo: critérios restantes B e HUMAN PLAYTEST REQUIRED.
- Continuação após 9af93695: HP duplicado, animação de voo e sobreposições
  Dev corrigidos/validados; quatro direções e seletor 100 níveis provados.
  Runtime Windows sky disponível; input nativo aguarda resposta sobre foco
  temporário devido à restrição explícita do briefing. B continua aberta.

## Estado — 12 de setembro de 2026

### Execution 9H.12A — portal, tutorial e scaffold Região I

- Base bd2aa418; âmbito exclusivo: provar/corrigir portal L1, coerência do
  tutorial de saltos e infraestrutura data-driven do remaster L1–L5.
- Hipóteses dirigidas: troca de cena durante flush de física; reentrada no
  portal; tutorial sem gate pela habilidade inicial/desbloqueada.
- Scaffold: perfis, seis slots visuais e planos de remodelação inativos,
  preservando arte, colisões, checkpoints e fluxo atuais. Sem Região II.
- Conclusão: regressão reproduzida e corrigida, testes A/B/scaffold, smoke
  L1–L5 com renderer real e Windows de checkout limpo antes de commit/push.
- HUMAN PLAYTEST REQUIRED para percurso/sensação; DEVICE VALIDATION REQUIRED
  para aceitação em dispositivo. Não fechar arte nem iniciar execução seguinte.
- Resultado técnico: portal/save/retoma/reentrada e tutorial seis idiomas PASS;
  manifesto/VFX e smoke L1–L5 PASS, suite completa/UI PASS. Windows 0.18.3
  exportado de snapshot limpo das fontes do índice antes do commit; EXE local
  atualizado e smoke L1/L5 PASS. Próximo: passe de arte e Game Master test.

### Integração 9H.10 + 9H.11

- Objetivo: integrar ec9a6260 e depois 109653fc sobre master f45fe9a5.
- Âmbito: preservar UI funcional 9H.10 e consistência visual 9H.11;
  smoke L1/L3/L5, Pause, HUD, Santuário e menu sem redesenhar nem alterar gameplay.
- Conclusão: suite completa e runtime dirigido, exports Windows/Web de checkout
  limpo, EXE local atualizado, push normal e CI remoto confirmado.
- Versão visível 0.18.2. HUMAN PLAYTEST REQUIRED; DEVICE VALIDATION REQUIRED
  para aceitação em dispositivo. STOP após publicação e CI; Região II não iniciada.

### Execution 9H.10 — lote exclusivo de UI

- Objetivo/âmbito: legenda, clipping CHECKPOINT/SKILL, fila de notificações e
  substituição de formas legadas apenas por arte já integrada; sem redesign.
- Conclusão técnica: testes dirigidos headless/Vulkan, smoke EXE L1, exports
  Windows/Web sem erros, commit/push isolado. Sem áudio, mobs/bosses ou backgrounds.
- Gate restante: HUMAN PLAYTEST REQUIRED / DEVICE VALIDATION REQUIRED Web real.
  Revisão e merge pelo Game Master; não iniciar outra execução.

### Execution 9H.7 - nitidez do fundo + conteudo dos niveis da Regiao I

- Desfoque: ampliacao bilinear de 2,1x-3,6x no ecra em TODAS as camadas (a 9H
  so tratou o panorama) + o shader de nitidez a atirar o `modulate` fora
  desde a 9H. Corrigido: amplia-se no disco ao fator exacto (panorama x4,
  kit x3), desenha-se a ~1:1, e o shader repoe o modulate pelo vertice.
- Conteudo: as pecas eram pousadas em intervalos escritos a mao e metade caia
  fora do que a camara ve. `_banda()` + densidades por 1000 px. Montado o que
  a 08 tem e faltava: vinhas do primeiro plano, cristais de corrupcao a media
  distancia e os raios de luz volumetricos. L3 ruinas, L4 cascatas, L5 Heart
  Tree sobre a arena.
- Zero alteracoes a gameplay (colisoes/geometria/checkpoints/inimigos/chefes/
  save/movimento). Suite OK + teste dirigido provado por mutacao.
- v0.18.1. Regiao II NAO iniciada. PRONTO PARA REVISAO DO GAME MASTER.

### Execution 9H.6 — lote exclusivo iOS + layout live

- Corrigir ciclo de vídeo Web/iOS bloqueado em t=0 e Skip DOM, mantendo MP4.
- Propagar drag/resize/save/REPOR às instâncias tácteis ativas, sem alterar persistência.
- Retirar painel temporário; landscape e restantes sistemas congelados.
- Conclusão: testes dirigidos, export Web, commit/push, CI/Pages confirmados.
- STOP após deploy; DEVICE VALIDATION REQUIRED para vídeo/áudio/Skip no iPhone.
- Publicado 64a57f5: CI/Pages SUCCESS; testes dirigidos e suite PASS.
  STOP de publicação cumprido; reteste físico do Game Master pendente.

**9H PARTIAL PASS (v0.17.0). Região I pronta para o gate humano; Região II
não iniciada.** O frontend inteiro passou a sair das pranchas aprovadas em
`work/production_art_gate/10_menu_rebrand/`: intro em vídeo, menu, seletor
(mapa de região), ícone/logo, HUD. Acrescentou-se o editor de layout de
toque da PWA e responderam-se os onze apontamentos do Game Master
(chefes L1–L5 mais fáceis, fundo mais nítido, inimigos com movimento,
combos legíveis, áudio de interface).

Relatório completo, com números medidos e armadilhas:
[execution_9h_frontend_regiao1.md](execution_9h_frontend_regiao1.md).
Ponto de retoma: [retomar_aqui.md](retomar_aqui.md).
Pendentes de decisão: topo de [../PRIORIDADES.md](../PRIORIDADES.md).

### Critério de conclusão do slice (o que falta para fechar o gate)

1. **Revisão humana** de `work/execution_9h/folha_revisao_9h.png`.
2. **Soundtrack**: entrega do pacote licenciado (bloqueio declarado).
3. **Estatísticas do seletor**: decisão de design (ou manter as três linhas
   que o jogo sabe responder).

---

## Plano anterior (Execution 8)

## Objetivo, âmbito e critério de conclusão 8 — 10 setembro 2026

Integrar no fluxo real do produto todo o trabalho funcional e todo o material
de produção já aprovado, seguro e disponível para a Região I, retirando da
apresentação normal os controlos de desenvolvimento e provando a cadeia
menu → seletor → `level_001`–`level_005` → Coração Putrefacto → recompensa.

Âmbito exato de níveis:

- `scenes/levels/Floresta_Putrefata.tscn` (`level_001`);
- `scenes/levels/Pantano_dos_Sussurros.tscn` (`level_002`);
- `scenes/levels/Ninho_da_Viuva_Negra.tscn` (`level_003`);
- `scenes/levels/A_Arvore_que_Chora.tscn` (`level_004`);
- `scenes/levels/Coracao_da_Floresta.tscn` (`level_005`).

Âmbito partilhado: `MenuInicial`, `MapaMundo`/`SeletorNiveis`, `HUD`, pausa,
`Main`, `Koliani`, combate, inimigos e arquitetura de chefe já usada pelos
cinco níveis; assets e módulos visuais existentes; pipelines de export
Windows/Web-PWA; verificadores, evidência e documentação exclusivos da
Execution 8. Movimento, câmara, colisões, escala `0,82`, offset
`-15,170732`, pivot `(80,90)`, canvas `160×96` e baseline `Y=90` ficam
congelados. Região II, Android, iOS, redesign e arte inventada ficam fora.

Critério: mapear recurso canónico contra recurso realmente carregado; ligar
implementações validadas que estejam desconectadas; integrar apenas assets
de produção com proveniência permitida; esconder `BOSS TEST`, `TESTAR OUTRO
NÍVEL`, `FLYMODE` e equivalentes no build normal; validar import, suite,
source/generator, jornada 1–100, alcance e bancos dirigidos dos níveis 1–5,
combate, boss e recompensa; exportar Windows e Web/PWA do mesmo estado;
executar smoke do EXE canónico; produzir evidência real quando o ambiente o
permita; atualizar retoma/dashboard/handoff; efetuar um único commit/push com
ficheiros intencionais. Aparência, feel, equilíbrio e percurso humano ficam
sempre `HUMAN PLAYTEST REQUIRED`; hardware/browser final fica `DEVICE
VALIDATION REQUIRED`.

## Prova por etapa 8

1. Congelar Git, propriedade do working tree e hashes/dimensões das doze
   autoridades visuais; classificar produção, referência, legacy e faltas.
2. Traçar `project.godot` → menu → campanha/seletor → níveis 1–5 → jogador →
   combate/inimigos → boss/reward e auditar flags/implementações concorrentes.
3. Capturar baseline do executável atual pelo fluxo normal ou registar o
   bloqueio exato da automação de interface, sem substituir playtest humano.
4. Integrar apenas ligações e apresentação seguras; não promover o kit
   `_source/imagegen_v1`, porque a Execution 8 proíbe produção generativa.
5. Validar import/cenas, Execution 7, combate, jornada, alcance, interiores e
   checkpoints; ler erros e logs, não apenas os códigos de saída.
6. Exportar Windows, lançar exatamente `build/windows/Koliani.exe`, capturar
   prova disponível e confirmar rastreabilidade; depois exportar Web/PWA uma
   vez e renovar cache/versionamento.
7. Produzir matriz de runtime, comparação legacy/current, relatório,
   dashboard, prioridades, retoma e handoff; `git diff --check`, fetch final,
   commit e push não destrutivo.

## Limite de execução já identificado

A API de aplicações Windows do Computer Use está desativada nesta sessão: o
runtime expõe apenas browser e `getApp` não existe. Navegação/captura manual do
EXE não pode ser declarada PASS por esse meio. A execução continuará com os
harnesses reais existentes e smoke do processo exportado; qualquer prova que
dependa de input/observação humana permanece explicitamente pendente.

## Resultado da Execution 8

**PARTIAL PASS — REAL RUNTIME TECHNICALLY VALIDATED / HUMAN REVIEW REQUIRED.**
Objetivo técnico cumprido: runtime mapeado, Koliani atual e panorama aprovado
ativos em L1–L5, apresentação de desenvolvimento escondida nos releases,
combate/boss/reward confirmados, suite/jornada/alcance e gates dirigidos PASS,
Windows e Web/PWA exportados do mesmo estado e provas reais produzidas.

Critério humano não encerrado: a API nativa Windows estava indisponível e
aparência, feel, equilíbrio e percurso exigem o Game Master. Plataformas,
props, inimigos, boss art, UI final e VFX/SFX permanecem legacy porque os
replacements de produção aprovados não existem. Ver
`docs/execution_8_real_game_production_integration.md`.

---

# Histórico — Execution 7 Region I Vertical Slice Completion

## Objetivo, âmbito e critério de conclusão 7 — 10 setembro 2026

Concluir o máximo tecnicamente seguro da primeira Vertical Slice, Região I
(`level_001`–`level_005`), numa execução consolidada: auditar e completar o
combate base permitido, integrar os inimigos já definidos, validar/ajustar os
cinco níveis autorais sem os reconstruir, fechar o boss regional
`boss_level_005` (`ChefeCoracaoPutrefacto.tscn`), progressão, recompensa,
evidência real, exports Windows/Web-PWA, documentação e Git.

Âmbito de níveis exato:

- `scenes/levels/Floresta_Putrefata.tscn` (`level_001`);
- `scenes/levels/Pantano_dos_Sussurros.tscn` (`level_002`);
- `scenes/levels/Ninho_da_Viuva_Negra.tscn` (`level_003`);
- `scenes/levels/A_Arvore_que_Chora.tscn` (`level_004`);
- `scenes/levels/Coracao_da_Floresta.tscn` (`level_005`).

Âmbito partilhado candidato, sujeito à auditoria antes de editar:
`scripts/koliani.gd`, `scripts/demonio_base.gd`, `scripts/chefe_base.gd`,
`scripts/chefe_generico.gd`, scripts/cenas concretos já referenciados pelos
cinco níveis, EstadoJogo/progressão apenas quando a integração do Dash,
conclusão regional ou recompensa prove uma lacuna, e verificadores/capturas
exclusivos da Execution 7. `scripts/movimento.gd`, parâmetros de câmara,
colisões validadas, escala `0,82`, offset `-15,170732`, pivot `(80,90)`, canvas
`160x96` e baseline `Y=90` ficam congelados.

Critério: gates A–E dirigidos sem hitbox persistente/dano duplicado/deadlock,
IA e telegraphs estáveis, L1–L5 carregáveis com checkpoints/saídas alcançáveis,
boss com ativação/fase 2/morte/recompensa idempotente, fluxo regional e schema
v5 preservados; suite completa e renderer real sem erro fatal; pacote de
revisão em `work/execution_7/review/`; builds finais Windows e Web/PWA com
rastreabilidade; commit/push único apenas com ficheiros intencionais. Feel,
equilíbrio e qualidade visual terminam obrigatoriamente como revisão humana
pendente. Ausência de arte de produção é classificada e não preenchida por
improviso.

## Prova por etapa 7

1. Congelar baseline Git e abrir as autoridades 03, 07, 08, 10 e 12 com
   path, dimensões, modo, SHA-256 e domínio visual confirmados.
2. Auditar runtime atual de combate, inimigos, cenas L1–L5, boss regional,
   checkpoints, progressão, reward e exports; distinguir implementado,
   legado, asset em falta, bloqueio e decisão nova.
3. Gate A: testes de ataque/3-hit/aéreo/Dash/feedback e regressão integral de
   Movement+Camera, sem retuning.
4. Gate B: IA, telegraphs, reação, morte, dano, respawn/checkpoint e
   distribuição segura dos inimigos existentes.
5. Gates C/D: load, spawn, todos os checkpoints, alcance, saída e renderer de
   cada nível 2–5; alcance estático não substitui playtest humano.
6. Gate E: boss `boss_level_005`, arena, fase 2, restart, morte, reward e
   save/reload idempotente.
7. Integração L1→L5→boss→reward→conclusão regional, suite geral, localização,
   100 cenas/integridade existente, capturas reais, performance observável e
   `git diff --check`.
8. Um ciclo final de Windows + Web/PWA, cache novo, smoke exportado,
   rastreabilidade, documentação, fetch final, commit e push não destrutivo.

## Baseline e classificações recuperadas

- início: `master`, `HEAD = origin/master = cdfa85a`, contendo 6B;
- `project.godot` e vários ficheiros não rastreados são trabalho local
  preexistente e permanecem excluídos salvo prova de necessidade;
- `boss_level_005` / Coração Putrefacto: boss regional canónico recuperado;
- Ghorak e bosses L1–L4: implementação legada, não novos bosses regionais;
- referências 03/07/08/10/12: **APPROVED DESIGN**, pranchas compostas;
  produção separável continua sujeita ao gate técnico;
- Execution 6B mantém **TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW
  REQUIRED** e não será retroativamente promovida.

## Resultado técnico 7

Os gates funcionais disponíveis passaram: combo 3-hit com hitbox temporária,
ataque aéreo, gating do Dash, guardiões L1–L4 sem reward de boss, L1–L5 e
checkpoints alcançáveis, interior L4, Coração Putrefacto em duas fases e baú
idempotente. Suite, source/generator, jornada 1–100, alcance e renderer real:
PASS. Relatório e rastreabilidade ficam em
`docs/execution_7_region1_vertical_slice_completion.md`.

Estado: **PARTIAL PASS — HUMAN VISUAL/COMBAT FEEL/BALANCE/PLAYTEST REQUIRED**.
Arte/áudio de produção em falta permanecem classificados; legacy funcional
foi retido. A execução termina após um único ciclo Windows/Web-PWA e Git; não
autoriza Região II.

---

# Histórico — Execution 6B Character + Level 1 Completion

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
