# N19 autoral — "Sala das Pressões" (Região IV, Fornalha)

**Data:** 2–3 out 2026 · **Cena:** `scenes/levels/Templo_da_Serpente.tscn` (nome
legado — era o Templo da Serpente, índice 18 de `EstadoJogo.NIVEIS`; mudá-lo
parte saves) · **Gerada por:** `tools/construir_n19_sala_pressoes.py` +
`tools/r4_lib.py` (editar lá, nunca no `.tscn`). Chave i18n: `level.n18`
(os índices de `level.nXX` andam 1 atrás do número do nível; ver N18).

**Estado: FECHADO tecnicamente (3 out 2026); playtest humano feito pelo Paulo.** Tudo o que é técnico está provado (testes,
piloto físico, crivo dos 100 níveis); a justiça dos tempos, a dificuldade e a
sensação de toque só se decidem a jogar.

## Contrato LOCKED vs. briefing
`docs/art_direction/regions/region_04/level_mechanics.png` + `layout_usage.png`
(coluna N19 "Sala das Pressões — ritmo, tempo, sobrevivência"): *jatos de fogo
telegráficos, pistões esmagadores, válvulas de pressão, plataformas
sincronizadas, vapor, dano em área*. Props exclusivos: Pistão Industrial,
Válvula de Pressão, Jato de Fogo. Fluxo do contrato: A jatos e timing · B
plataformas de precisão · C secção com pressão variável · D saída para o núcleo ·
3 segredos · combate 50 %.

O briefing estruturou o nível A pistões → B primeira válvula → C máquina
sincronizada → D Sala das Pressões → Guardião. Seguiu-se o briefing **dentro**
do contrato (mecânicas e props são os do contrato; nada inventado).

### Decisões que divergem ou ficam em aberto
1. **Guardião — DECISÃO FECHADA (3 out 2026): Lança-Chamas elite é canónico para o N19.** Os quatro inimigos
   principais do N19 na prancha (Válvula Viva, Assassino Ígneo, Torreta de
   Plasma, Gárgula de Fogo) **não têm espécie extraída**; o Autómato de
   Fundição é do N17 e a Sentinela de Pressão do N18. Usado, e agora formalizado, o **Lança-Chamas elite** (espécie já extraída, escala 1,6; chave
   `guard.lanca_chamas` nas 6 línguas). Nenhuma espécie nova foi inventada.
2. **Inimigos**: só espécies extraídas da Região IV (Trabalhador Corrompido,
   Arqueiro da Fornalha, Lança-Chamas). O contrato diz combate 50 % — o N19
   tem muito menos (o foco é a máquina); à vista do playtest.
3. **Dimensão: 6740 px** (briefing: 5600–6500 "a resultar do conteúdo"). Sai do
   conteúdo: 3 fossos de 460/710/812 px com fendas de segurança + arena de 740 px.
4. `data/level_manifest.json` continua a listar o `boss_ref` legado (Naga) para
   este índice — o mesmo que ficou no N18; não é lido em jogo.
5. Pistões e válvulas são **novos** (não existiam); ver "Componentes".

## Componentes novos (reutilizáveis, opt-in, default-safe)

| Ficheiro | O que é |
|---|---|
| `scripts/pistao_fornalha.gd` (`PistaoFornalha`) | Pistão esmagador. `Armadilha` (Area2D) sem física: só fere por contacto |
| `scripts/valvula_fornalha.gd` (`ValvulaFornalha`) | Válvula de pressão: toque → abre → avisa o grupo |
| `scripts/relogio_fornalha.gd` (`RelogioFornalha`) | Relógio único (`manual < 0` = parede; as bancadas fixam-no) |
| `scripts/gira_devagar.gd` (`GiraDevagar`) | Roda decorativa (o marco visual) |
| `JatoFornalha` (+3 props) e `PlataformaRitmada` (+3 props) | ganchos opt-in da válvula |

### Pistão — ciclo e telégrafo
`RETRAÍDO (repouso) → AVISO (≥ 0,7 s) → EXTENDENDO (0,22 s) → ESTENDIDO → RETRAINDO`.
Perigoso só com a cabeça a > 25 % do curso (`LIMIAR_PERIGO`); no AVISO a cabeça
**treme**, brilha, saltam **fagulhas**, a **marca no chão acende** onde vai
bater e toca `mecanismo_ciclo`; a pancada toca `mecanismo` (grave) e solta vapor.
Nunca fere no mesmo instante em que muda de estado. A zona de dano é a da
cabeça (nunca física: não prende nem esmaga contra nada). `direcao` aceita os
quatro eixos (testado o vertical; o horizontal só por geometria).
Funções puras: `estado_em(t)`, `curso_em(t)`, `perigoso_em(t)`,
`aviso_restante_a_partir_de(p)`, `caixa_cabeca(f)`; `passo(dt, t)` para bancadas.

### Válvula — modos e feedback
`modo`: `temporaria` (janela de `janela_seg`, tocar de novo renova; nos últimos
`aviso_fim_seg` a roda pisca e apita) · `alterna` · `uma_vez`. Toque da
Koliani (como a `Alavanca`), sem botão extra (mobile). Feedback: a roda gira
90°, sopro de vapor, brilho azul-gelo, `mecanismo`, e **as ligações**
(tubos finos da roda a cada alvo) acendem — laranja = válvulas dos
**perigos**, azul = válvulas das **plataformas**. Os alvos que ela domina ficam
também azul-gelo.

| Alvo | `efeito_valvula` | O que faz |
|---|---|---|
| `PistaoFornalha` | `pausa` | recolhe suavemente e fica parado; ao fechar recomeça em `fase_retoma` (dentro do repouso, com o aviso inteiro) |
| `PistaoFornalha` | `ressincroniza` | ao abrir recolhe e recomeça já na fase boa; ao fechar volta à de origem |
| `JatoFornalha` | (pausa) | dorme sem aviso; ao fechar recomeça em `fase_retoma` (≥ 1 s de aviso antes do 1.º fogo) |
| `PlataformaRitmada` | `solida` | fica sempre sólida; ao abrir/fechar o ciclo recomeça no início do período sólido (**nunca** uma queda surpresa) |
| `PlataformaRitmada` | `so_aberta` | só existe (cicla) enquanto aberta — usada nos 3 segredos |

**Ligação** por grupo (`grupo` da válvula = `grupo_valvula` do alvo → grupo de
nós `valvula_<g>`); sem NodePaths frágeis. **Reset:** a morte recarrega a cena
(`reload_current_scene`), portanto válvulas e perigos voltam SEMPRE ao
arranque; por isso **nenhum alvo fica para lá de um checkpoint que preceda a
sua válvula** (o teste verifica-o).

### Performance (mobile)
Cada pistão faz maths puro no `_physics_process`; fora do ecrã **deixa de
correr** (`VisibleOnScreenNotifier2D`; o estado é função do tempo, ao voltar o
1.º passo põe-no certo; quem está a meio de uma válvula continua). Sem renderer
(headless) corre sempre. 14 pistões × 2 `CPUParticles2D` pequenos (8 e 10
partículas, só emitem no aviso/pancada) + 5 jatos + 1 roda (única `_process`
decorativa). Sem luzes novas por pistão. Sem tweens permanentes.

## Layout (Koliani nasce em x=170; chão y=600; largura 6740)

| Secção | x | O que ensina |
|---|---|---|
| **A — Pressão visível** | 0–1500 | sem válvulas/lava/inimigos. A1 pistão lento (6,35 s, aviso 1 s) · A2 dois pistões em contratempo com ilha de 110 px · A3 pistão + jato no mesmo relógio. **CP1** só depois, em chão seguro |
| **B — A primeira válvula** | 1500–2900 | V1 (laranja) desliga 10 s o corredor B1 (dois pistões desencontrados + jato quase sempre aceso). A `StepB1` (só com V1 aberta) leva ao **segredo 1**. B2: fosso de 460 px com 3 ritmadas em onda; V2 (azul) segura-as sólidas 9 s. **CP2** |
| **C — Máquina sincronizada** | 2900–4900 | C1: V3 desliga 8 s dois pistões + jato (**CP3** só depois). C2: fosso de 710 px, V4 (azul, 11 s) segura as 4 ritmadas, mas o pistão sobre a RC2 e o jato do fundo continuam: ritmada → pistão → ilha → jato → ritmada. **Segredo 2** (StepC só com V4). C4: Arqueiro + Trabalhador, a coluna como abrigo. **CP4** |
| **D — Sala das Pressões** | 4900–5972 | V5 (azul, 12 s): ritmadas sólidas, jato adormece, pistões **entram em fase**. Pistão → ritmada → ilha → jato → ritmadas → dois pistões colados → saída. Sem V5 os pistões ficam desencontrados. **Segredo 3** (StepD só com V5). Marco: a grande roda de pressão a girar |
| **Arena do Guardião** | 5972–6712 | ILHA \| PISTÃO \| ILHA (Lança-Chamas elite) \| PISTÃO \| ILHA (porta). Pistões em contratempo (nunca juntos); ilhas ≥ 130 px sempre livres. **V7** numa laje a 80 px do chão (um salto: é preciso querer usá-la) desliga-os 8 s. **CP5** à entrada |

5 checkpoints (`CheckA1` 1465, `CheckB2` 2960, `CheckC3` 3540, `CheckC4` 4850,
`CheckD5` 6022), 3 segredos (essências 25/25/40), 14 pistões, 5 jatos, 6
válvulas, 15 plataformas ritmadas, 3 fossos de lava **não letal** (20 de dano,
dá para sair), **sem chefe** (`ChefeBase` ausente), `corredor = false`.

### Janelas seguras medidas (modelo puro = scripts reais, travessia a 240 px/s)
Maior janela contígua de instantes de partida sem tocar em perigo, **sem usar
válvulas**:

| Travessia | Janela | | Travessia | Janela |
|---|---|---|---|---|
| A1 (pistão lento) | 4,24 s | | C2a (pistão sobre a RC2) | 3,06 s |
| A2a | 5,58 s | | C2b (jato do fosso) | 2,12 s |
| A2b | 3,06 s | | Arena 1 | 5,58 s |
| A3a | 5,58 s | | Arena 2 | 3,08 s |
| A3b (jato) | 2,52 s | | **B1 / C1 (portas de válvula)** | **0,00 / 0,18 s** |

B1 e C1 são **portas de válvula**: o teste exige janela < 0,6 s — se algum dia
dessem folga a válvula era enfeite. Com V5, a janela dos dois pistões colados de D
passa de pequena a ≥ 2,5 s (testado).

## Testes
- `tests/test_region04_pistao_valvula.gd` — ciclo, telégrafo, dano, fases,
  válvula (abrir, janela temporária, alterna, uma_vez, grupos independentes,
  reset), omissões inalteradas, e **contacto real** com a Koliani (aviso sem
  dano, pancada com dano no tempo certo, válvula aberta pára o dano).
- `tests/test_region04_n19_level.gd` — estrutura, 5 CP, 3 segredos, valvulas ↔
  alvos ↔ checkpoints, vãos com o salto duplo REAL, **nenhuma fresta de 13–33 px**
  (a Koliani mede 20: entala-se), cada pistão bate numa superfície, janelas,
  portas de válvula, retomas, arena, reaparecer repete o ritmo.
- `tests/run_regiao4.tscn` — corredor rápido (~20 s) só da Região IV; a suite
  completa regista os mesmos testes.
- `tools/prova_n19_travessia.gd` (isolado, headless): piloto com a Koliani REAL
  e os relógios REAIS (`RelogioFornalha.manual`: o headless corre ~14× mais
  depressa que a parede). Modos: omissão (percurso inteiro), `N19_SEGREDOS=1`
  (sobe aos 3 segredos e apanha as essências), `N19_FOSSOS=1` (sai dos 3 fossos
  pelos dois lados), `N19_SEM_VALVULAS=1` (controlo negativo),
  `N19_ESPERA_INICIAL=s` (fase de arranque).
- `tools/comparar_baselines_100.py`: baseline funcional dos 100 níveis contra um
  checkout de referência.

## Por fazer / risco
- **HUMAN PLAYTEST REQUIRED** (checklist no relatório final).
- Guardião: fechado (Lança-Chamas elite; as 4 espécies do contrato não têm arte e não se improvisou nenhuma).
- Combate: reforçado de forma moderada (+2 Trabalhadores em chão sem perigos, `TrabalhadorB` 1930 e `TrabalhadorD` 5040; total 4 + elite). Ficou abaixo dos 50 % do contrato de propósito: o foco é a máquina (pistões/válvulas/jatos já ocupam a atenção) e mais inimigos pioravam a leitura.
- `level.n18` nas línguas não-pt/en estava em inglês ("Temple of the Serpent"):
  agora traduzido para as 6; as chaves `guard.automato_de_fundicao` aparecem
  duas vezes em cada `*.json` — **CORRIGIDO** (removida a duplicada em inglês; `tests/test_i18n_sem_chaves_duplicadas.gd` impede o regresso).
- Pistão horizontal (`direcao` ≠ baixo): geometria testada, sem nível a usá-lo.
