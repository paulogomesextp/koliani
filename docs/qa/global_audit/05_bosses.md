# 05 — BOSSES (Agent 5, auditoria global, 25 set 2026)

Modo diagnóstico. Nada no jogo foi alterado. Harness próprio
(`scratchpad/a5/luta.gd`, fora do repo) corrido pelo wrapper de sandbox, janela real no 2.º monitor.
Capturas e logs em `docs/qa/global_audit/img/a5/` (`nNN_obs_XX.png`, `nNN_fase2.png`, `nNN_morte.png`, `nNN_log.txt`).
Complementa o agente 4 (arte/arenas, `img/a4/folha_20_bosses_jogo.jpg`) e o de áudio (música do chefe);
aqui o foco é **padrões, telégrafos, fases, downtime e dificuldade medidos**.

## Método de runtime

Para cada nível: carregar a cena, pôr a Koliani a ~240 px do chefe e:

- **Fase A (20 s, Koliani passiva)**: vida da Koliani mantida alta; regista fase da máquina de estados,
  animação do rig (`Sprite/Anim`), cada golpe recebido (valor), nós novos (projéteis/Area2D), início do
  diálogo e do `combate_iniciado`.
- **Fase B (morte)**: golpes simulados de **50** (= `EstadoJogo.DANO_BASE`) a cada 0,45 s, ou seja
  **~111 DPS com 100 % de uptime**. Um jogador real (combo máx. 4 golpes/0,94 s, `koliani.gd:84`)
  com 40–50 % de uptime anda nos 85–105 DPS; na prática **TTK real ≈ 1,0–1,3× o medido, mais o tempo
  a esquivar** — os valores servem para comparar chefes entre si.

Limitações: a HUD não aparece em `--script` (sem barra de vida nas capturas); a contagem de essência
usou um nome de grupo errado (0 em todos — **não verificado**); o N20 (Olho do Abismo) mediu stats
mas a Koliani caiu/foi libertada no arranque duas vezes (`Cannot call method 'get' on a previously
freed instance`) — padrão **STATIC ONLY**, segundo a regra de uma só repetição.

## Tabela medida (runtime)

| N | Chefe (script) | Autoria | Vida da luta | Contacto | Dano passivo em 20 s* | TTK a 111 DPS | Alt. vs Koliani | Padrões vistos | Anim. do rig |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| 1 | Ghorak (guardião) | à mão | 416 | 16 | 56 (4 golpes) | 4,2 s | 1,18× | semeia/esmaga | idle/run/attack/hit |
| 5 | Coração Putrefacto | à mão, arte 9D | 1059 | 25 | 129 (9) | 10,3 s | ~2,3×** | 2 (tiros, raízes) alternados a relógio | **congelado em `attack` 0,6→20 s** |
| 10 | Guardião dos Céus | à mão, contrato | 1996 | 31 (56 forte) | 121 (5) | 23,3 s | 1,86× | 3 (lâmina, queda, vento) | ciclo completo |
| 15 | Vyrak | à mão, contrato | 3019 | 46 | 104 (5) | 20,5 s (exposto ×2) | 2,66× | 7 de 9 vistos + RITUAL a 50 % | idle/attack/hit |
| 20 | Olho do Abismo | à mão | 2974 | 38 | — | — | 1,96× | STATIC: 4 | — |
| 25 | Noiva do Eclipse | à mão | 3710 | 42 | 102 (6) | 40,3 s | 2,15× | 3 | idle/attack/hit |
| 30 | Zeriko Final | à mão | 5760 | 57 | 36 (2) | 62,2 s | 2,69× | 4 formas, 8 ataques | **congelado em `attack` 0,6→20 s** |
| 31 | Vulkar (Generico) | híbrido | 1536 | 51 (**92** forte) | **1288 (14)** | 14,5 s | 1,61× | investida + brasas | attack↔parado |
| 35 | Oceânico "estrela" | procedural | 3072 | 51 | 297 (17) | 28,9 s | 2,57× | feixe + onda | só `attack` |
| 45 | Glacial "ymiria" | procedural | 3840 | 51 | 236 (11) | 35,9 s | 2,40× | feixe + runa | só `attack` |
| 50 | Deserto "forgotten_god" | procedural | 4224 | 51 | 457 (20) | 39,7 s | 2,00× | salto + órbita | attack↔parado |
| 55 | Lore "rei_botanico" | procedural | 5088 | 51 | 324 (18) | 47,6 s | 2,00× | invoca + losangos | só `attack` |
| 75 | Lore "morte" | procedural | 9312 | 51 | 369 (16) | 87,3 s | 2,07× | salto + losangos | attack↔parado |
| 100 | Lore "zeriko_homem" | procedural | **16320** | 51 (**92**) | **972 (17)** | **>200 s (não caiu)** | 2,00× | investida + losangos | attack↔parado |

\* A Koliani tem 100 de vida. ** o medidor apanhou o rig largo do Coração pela altura do frame; visualmente ~2×.
Logs: `img/a5/nNN_log.txt`; N20 e N55 detalhados em `scratchpad/a5/n20b.out`, `n55b.out`.

## Causas-raiz

### CR1 — Há dois jogos de chefes: 30 escritos à mão e 70 que são o mesmo chefe (P0, REBUILD da camada N31–N100)

**Estado atual.** `ChefeGenerico` (`scripts/chefe_generico.gd`) é UMA máquina de estados de 4 fases
(`APROXIMA → TELEGRAFO → ACAO → RECUPERA`) com 5 arquétipos. Os 70 chefes N31–N100 são esta cena
com um `forma`/rig diferente; `chefe_lore.gd` (50 deles) junta por cima **um de 4 modos de projéteis
escolhido por `abs(forma.hash()) % 4`** (`chefe_lore.gd:64`), com dano fixo 18.
Medido no N55: o ciclo é **fixo em 1,85 s** (0,47 aproxima · 0,37 telégrafo · 0,51 ação · 0,50 recupera),
repetido sem variação da 1.ª à última volta (`n55b.out`). Não há fase 2 real: só `fase2_ganho`=×1,3
na velocidade (`chefe_generico.gd:58-61`).

**O que não funciona.**
- **Os projéteis "de identidade" não têm telégrafo.** Lore/Elemental/Oceânico/Glacial/Deserto disparam
  no `_process` com um temporizador próprio (1,0–1,8 s), independente da máquina de estados — portanto
  **também durante o RECUPERA**, que era a única janela de castigo. O arco que desenham no `_draw`
  como "runa de telégrafo" corre noutro relógio (`fmod(t,1.3)<0.5` vs. `cd = 1.0+hash%9/10`,
  `chefe_lore.gd:57-62`) — pisca sem relação com o disparo. O `ChefeLore` nem verifica distância: dispara
  desde que o nível carrega.
- **Estes 5 scripts sobrepõem `_process` sem `super._process`** (`chefe_lore.gd:53`, `chefe_elemental.gd:13`,
  `chefe_oceanico.gd:14`, `chefe_glacial.gd:16`, `chefe_deserto.gd:14`). Perdem por isso tudo o que o
  `ChefeBase._process` dá (`chefe_base.gd:405-425`): prisão à arena, intro de diálogo, rede de segurança
  de queda, e a animação/flash de telégrafo do `DemonioBase._process` (`demonio_base.gd:598-610`).
  **Runtime confirma**: nos 6 procedurais medidos o rig nunca volta a `idle`/`run` — alterna `attack`
  e o último frame congelado de `attack`/`hit`.
- **Nenhum dos 70 chama `provocar()`** (grep: 0 ocorrências em `chefe_generico/lore/elemental/oceanico/
  glacial/deserto/vulkar`) — a luta só "começa" (barra de vida, música de chefe) quando a Koliani bate
  ou é tocada; N35/N45/N55 atacaram 20 s sem `combate_iniciado` (-1 no log).
- **Identidade = rig + cor.** 22 rigs de packs para 50 chefes (agente 4). O "Zeriko, o Homem" do N100
  é o `cavaleiro_negro` de pack em cima de um tabuleiro de musgo (`img/a5/n100_obs_01.png`);
  a "Morte" do N75 é `ceifeiro`; o "Rei Botânico" N55 é o `entrevane` da Região I com goblins
  invocados (`n55_obs_01.png`).

**Benchmark gap.** Em Hollow Knight/Nine Sols cada chefe é um conjunto de 3–6 golpes com antecipação
própria, e a fase 2 muda o *vocabulário*, não só a velocidade. Aqui 70 % da campanha tem um ciclo de
1,85 s idêntico + fogo não-telegrafado.

**Ação.** REBUILD. Deixar de tratar "boss" como slot obrigatório de cada nível (ver CR3); os encontros
N31–N100 que não são o chefe regional passam a guardiões/elites com o `ChefeGenerico` corrigido
(`super._process`, projéteis dentro de ACAO, `provocar()`); os 17 chefes regionais IV–XX recebem script
próprio como o Vyrak. Corrigir já o `super._process` é P0 barato.

### CR2 — A curva de dificuldade dos chefes não tem autor: é um multiplicador preso ao índice 29 (P0, MAJOR REWORK)

- `_afinar_dificuldade` (`chefe_base.gd:283-321`) e o dano de contacto (`chefe_base.gd:231-233`) fazem
  `clampi(indice_nivel, 0, 29)`: **do N30 ao N100 o multiplicador é o mesmo** (vida ×4,8, contacto ×2,85).
  O que cresce depois é só o `vida` escrito à mão em cada `.tscn` — daí o **degrau para baixo** N30 5760 →
  N31 1536 e a **esponja** do N100 com **16 320** de vida (>200 s a 111 DPS; 321 golpes sem cair).
- **Dano de contacto 51 / 92 forte** em todos os N31+ (medido): a Koliani tem 100 de vida. No N31 e no N100,
  parada, recebeu **92 a cada ~1,4 s** (1288 e 972 em 20 s) — morre em **dois toques**, contra 4–9 golpes
  nos chefes à mão (56–129 em 20 s). O chefe final do jogo (N100) é, em números, uma parede de contacto.
- A **rampa de alívio da Região I** (`chefe_base.gd:265-280`) é a única afinação feita com playtest; tudo o
  resto é fórmula. O `_encurtar_fase_exposto` corta EXPOSTO para 55 % (`chefe_base.gd:395-401`) em todos,
  desde que os escudos saíram — medido: janela de castigo 0,42 s no N5, 0,74 s no N10, 0,77 s no N20.
- Contraste bom: o **Vyrak** mantém EXPOSTO de 1,47 s com dano ×2 no núcleo (`chefe_vyrak.gd:614-618`) —
  TTK 20,5 s com mais vida que a Noiva (40,3 s). É o único chefe com ritmo *ataque → castigo* legível
  de ponta a ponta.

**Ação.** MAJOR REWORK: tabela explícita de vida/dano/janela por chefe regional (20 linhas), dano de
contacto com teto (≤25–30 % da vida da Koliani) e contacto "forte" só em golpes telegrafados; alvo de
TTK por região (ex.: 25–40 s no regional, 10–15 s nos guardiões). P0 porque torna os N31+ injogáveis
sem mexer em arte.

### CR3 — A campanha implementada não tem a estrutura de chefes do cânone (P0, decisão de design)

- **Cânone**: 20 regiões, **1 boss por região** (`docs/art_direction/KOLIANI_REGION_CANON.md`).
  **Jogo**: regiões I–III com 4 guardiões + 1 boss; regiões IV–XX com **5 "boss.*" cada = 85 chefes**
  (`catalogo_campanha.gd:19-149`: 19 `guard.*`, 66+ `boss.*`). O chefe deixa de ser clímax quando todo
  o nível acaba num.
- Das 20 regiões canónicas só **II (Guardião dos Céus) e III (Vyrak)** têm o boss certo no nível certo.
  Região I: o cânone diz **Guardião Verde**, o jogo luta com **O Coração Putrefacto** (`boss.coracao_putrefacto`,
  "The Rotting Heart"); o nome "Guardião Verde" só existe no `seletor_niveis.gd:39-45`, ao lado da
  arte `ghorak.png` — **o seletor mostra num painel o boss canónico com arte legacy e na linha de estado
  outro nome** (`seletor_niveis.gd:434-439`). De IV a XX as regiões do código (`estado_jogo.gd` `REGIOES`:
  Catacumbas, Cidade, Castelo, Queimadas, Mar...) nem coincidem com as do cânone (Fornalha, Cidades
  Flutuantes, Deserto das Ilusões...). O Zeriko luta-se no **N30**; o cânone põe-no no **N96–100**,
  onde o jogo tem três "Zerikos" de pack (`boss_96_zeriko_jovem`, `98_zeriko_absoluto`, `100_zeriko_homem`).
- Arte do seletor por região (`img/a5/seletor_boss_art_regioes_1_9.png`): o "Guardião dos Céus" é um
  inseto-drone cinzento (`aerion.png`), o "Vyrak" é o dragão antigo que o contrato da Região III declarou
  FIDELITY FAILED, o "Guardião da Fornalha" é um **trapézio vermelho com dois olhos** (`magma.png`).
- **Guardiões da Região II são scripts legacy com rig novo**: `ChefeCarcereiro`, `ChefeIgnivar`,
  `ChefeDamaGuilhotina`, `ChefeIrmaosCondenados` (prisão/fornalha/guilhotina) vestidos de `golem_falesias`,
  `vigia_desfiladeiro`, etc. (`scenes/actors/Chefe*.tscn`). Nome e pele mudaram; os padrões (salto+onda,
  martelo, guilhotina) continuam os da prisão. STATIC ONLY.
- Órfãos: `ChefePrimeiroPrisioneiro.tscn`, `ChefeFloresta.tscn` não são usados por nenhum nível.

**Ação.** Decisão do GM antes de mais código: fixar **20 chefes regionais** (N5, N10, ..., N100) e rebaixar os
restantes 80 encontros a guardiões/elites. Isto reduz o trabalho de 85 chefes para 17 e devolve peso ao clímax.

### CR4 — Mesmo os chefes aprovados estão abaixo da prancha: escala, vocabulário, animação (P1, PARTIAL REWORK)

- **Escala.** `ALTURA_ALVO_CHEFE = 100` (`chefe_base.gd:37`, comentário: "fica com ~2×"). Medido: 1,2–2,7×
  a Koliani em todos os 14. Pranchas: Guardião dos Céus 2,6–3,7× (contrato L2 exige ~170 px de corpo;
  medido 121 px = 1,86×), **Vyrak ~4×** (medido 2,66×), Guardião da Fornalha ~4×. Nas capturas o chefe
  cabe numa plataforma de 1/3 do ecrã (`n10_obs_02.png`, `n15_obs_01.png`) — lê-se como "inimigo grande".
- **Vocabulário.** Guardião dos Céus: **3 de 8** ataques da prancha (contrato L6 adiou 5); medido um ciclo
  lâmina→queda→vento a cada ~9 s, fase 2 só encadeia. Vyrak: 9/9 implementados, 7 vistos em 40 s + RITUAL;
  é o padrão a copiar. Coração (N5, clímax da Região I, o chefe de referência): **2 ataques alternados a
  relógio** (tiros 1,0 s → raízes → tiros, período 4,0 s exato, `n05_log.txt`), TTK 10 s — é o chefe mais
  curto e mais pobre das três regiões aprovadas, e é o que dá o salto duplo.
- **Animação.** Os rigs têm 5 estados mas `attack`/`hit` não fazem loop e ninguém pede o regresso:
  **Coração e Zeriko Final ficaram congelados no último frame de `attack` durante 19,4 s** (logs `n05`, `n30`).
  Todos os chefes usam `hit` como pose da janela EXPOSTO (`chefe_base.gd:624-625`) — a vulnerabilidade
  lê-se como "levou dano", não como "abriu a guarda". 25 rigs (1–30) são polígonos gerados em Python
  (`tools/gerar_chefes_anim.py` + `chefes_corpos.py`), todos com 6/8/10/4/10 frames; o Guardião dos Céus
  em jogo é um pássaro de polígonos azul (`n10_obs_02.png`) ao lado de uma prancha de penas detalhadas.
- **Telégrafos.** À mão: 0,47–0,8 s, pintados no sítio do golpe no Vyrak (bom), só `modulate` + aura nos
  outros. Genéricos: 0,36–0,42 s de piscar. Nine Sols dá telégrafo *diferente por golpe* (cor/som/pose);
  aqui o piscar é o mesmo para todos os golpes do mesmo chefe.

**Ação.** PARTIAL REWORK nos 3 aprovados: altura alvo por chefe segundo a prancha (GdC 170, Vyrak ~250),
arena à medida, loops/pose de EXPOSTO próprias, e o Coração (ou o Guardião Verde, se o GM o mantiver)
com 4–5 ataques e 2 fases.

### CR5 — Entrada, morte e recompensa não marcam o clímax (P1, TUNE)

- **Entrada.** Só 4 chefes têm `falas_intro` (N10, N25, N29, N30 — grep + runtime N10/N25/N30:
  diálogo em t=0,03 s). O chefe da Região I, o Vyrak e 96 outros entram mudos. O Vyrak **atacou 5 vezes
  antes de `combate_iniciado`** (t=19,5 s) porque só chama `provocar()` ao levar dano
  (`chefe_vyrak.gd:614`): sem barra, sem música, enquanto já bate.
- **Música.** `faixa_de_chefe` é por região (`musica.gd:169-181`): os 4 guardiões tocam o **mesmo tema**
  do chefe regional antes dele aparecer (agente de áudio cobre o resto).
- **Morte.** Igual para todos: `chefe_cai` + `conquista` + anéis/flash (`chefe_base.gd:486-560`); sem
  cena de colapso de arena (a prancha do Vyrak pede "colapso da torre").
- **Recompensa.** Só o N5 dá habilidade (`HABILIDADE_DO_CHEFE := {4: "salto_duplo"}`,
  `nivel_com_chefe.gd:215`). Os restantes dão um baú de sorteio. As recompensas das pranchas
  (Memória de Vyrak, Cristal de Eco, Cristal da Fornalha) não existem no código (grep vazio).
- Essência do chefe: `_soltar_essencia_chefe` também prende a `indice_nivel` a 29 (`chefe_base.gd:474`).

**Ação.** TUNE: intro curta + nome no ecrã em todos os regionais, `provocar()` à vista em todos,
recompensa narrativa + habilidade por regional.

## O que funciona (preservar)

- **Vyrak** (`chefe_vyrak.gd`): contrato → código fiel (9 ataques em listas por fase, telégrafo desenhado
  no sítio do impacto, núcleo exposto ×2, ritual a 50 %). Ritmo medido de 3 s por ataque com 1,47 s de castigo.
  É o modelo para os 17 regionais que faltam.
- **Guardião dos Céus**: examina a mecânica da região (vento da `WindZone` com anúncio), repõe o estado
  no `_exit_tree`, intro e falas de fim. Falta escala e 5 ataques.
- **Rampa de alívio da Região I** (`ALIVIO_R1`): afinação honesta, feita a partir de playtest.
- Infraestrutura sólida em `ChefeBase`: prisão à arena, som por significado/família, pitch cíclico,
  `derrotado` → porta/baú, falas via `Dialogo` sem pausar.
- Oportunidade própria de KOLIANI: chefes que **examinam a mecânica da região** (vento no II, sinos/eco no III)
  em vez de "mais vida". Levar essa regra aos 17 que faltam dá identidade sem precisar de 85 chefes.

## Pergunta do briefing: clímax ou inimigo grande?

- **Clímax**: Vyrak (N15), e em menor grau Guardião dos Céus (N10) e Zeriko Final (N30, 4 formas / 26
  fases observadas em 62 s — mas congelado em pose de ataque e a 2,7×).
- **Inimigo grande**: Coração Putrefacto (N5, 2 ataques, 10 s), todos os N16–N29 com 2–4 ataques e o mesmo
  esquema DECIDE/TEL/EXPOSTO, e **todos os 70 N31–N100** (ciclo de 1,85 s + fogo sem aviso + números de
  fórmula). Contra Hollow Knight/Nine Sols falta: escala, arena própria, fase 2 com vocabulário novo,
  telégrafo por golpe, entrada/morte encenadas.

## Prioridades

| # | Causa | Prioridade | Ação |
|---|---|---|---|
| CR1 | 70 chefes = um genérico + projéteis sem telégrafo; `_process` sem `super` | P0 | REBUILD (e correção imediata do `super._process`) |
| CR2 | Dificuldade presa ao índice 29; contacto 92 vs 100 de vida; N100 com 16 320 | P0 | MAJOR REWORK (tabela por chefe) |
| CR3 | 85 "bosses" vs 20 canónicos; nomes/regiões/Zeriko fora do cânone; seletor contraditório | P0 (decisão GM) | reestruturar para 20 regionais |
| CR4 | Aprovados abaixo da prancha: escala 1,9–2,7× vs 2,6–4×; GdC 3/8; anim congelada | P1 | PARTIAL REWORK |
| CR5 | Entrada muda, música partilhada, recompensa só no N5 | P1 | TUNE |

## RUNTIME VERIFIED vs STATIC ONLY

**RUNTIME VERIFIED** (sandbox, janela no 2.º monitor): lutas N1, N5, N10, N15, N25, N30, N31, N35, N45,
N50, N55, N75, N100 — vida da luta, dano de contacto, dano recebido em 20 s, sequência de fases
(N55 com ciclo genérico cronometrado), animações do rig, altura relativa, intro/combate_iniciado, TTK
a DPS simulado, capturas. N20: só stats de arranque (vida 2974, contacto 38, 1,96×).

**STATIC ONLY — NOT RUNTIME VERIFIED**: padrões do N20 e dos N16–N29 não carregados; guardiões da Região II
como scripts legacy reskinned; ausência de `provocar()` nos genéricos (confirmado indiretamente pelo
`combate_iniciado=-1` em N35/N45/N55); recompensas canónicas inexistentes; música por região; queda de
essência (medição falhou); o TTK de jogador real (inferido do combo, não jogado); comparação com pranchas
de regiões sem boss_pack (só II, III, IV têm).

## Save real

SHA256 antes: `9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238`
SHA256 no fim: `9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238` — **inalterado**.
