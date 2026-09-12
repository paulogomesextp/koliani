# Execution 9H.13/14 — áudio, corrida da Koliani e fundo do L2

12 de setembro de 2026. Ramo `claude/9h13-14-audio-koliani-l2`.
Três queixas do Game Master: SFX fracos, uma perna da Koliani parada a
correr, e o fundo do L2 a tremer e com pouca qualidade.

## A) Passe profissional dos SFX — FEITO

`tools/gerar_sfx_9h13.py` refaz 23 sons, só os que o runtime dispara mesmo
(saídos de `grep 'Som.toca('`). Tudo sintetizado no repositório: sem samples
de terceiros, sem licenças, sem numpy.

O que mudou de **método** — é isto, e não a lista de sons, que faz a
diferença entre "sintetizador" e "profissional":

1. **Três camadas em vez de uma.** CORPO (grave, é o que se sente), BATIDA
   (transiente de 3–8 ms, é o que dá a leitura de impacto) e AR (cauda com
   ecos). A leva antiga era quase só corpo.
2. **Nenhuma senoide a descoberto.** Toda a voz grave leva batimento (duas
   vozes desafinadas) ou ruído por cima. Uma senoide limpa é um bip.
3. **Picos hierarquizados** (`ALVO`, de 0,40 no `ui_mover` a 0,92 no
   `ataque_forte`) em vez de normalizar tudo ao máximo. É assim que o remate
   manda na mistura e o passo não mascara os telégrafos. Nada chega a 1,0,
   portanto as 8 vozes do pool não clipam.

**Combo 1→4:** passou a ter quatro sons próprios. Crescem em três eixos ao
mesmo tempo — o corpo desce de registo (400→150 Hz no 1.º golpe, 300→70 no
remate), o sopro alarga, a cauda cresce. O remate leva antecipação (arma
antes de bater) e badalada grave. Antes eram **dois** samples com
`pitch_scale` por cima, que é exactamente o que se lê como sample repetido.

`dano` (levar dano) é de propósito grave e abafado, sem ruído agudo: ruído
agudo em cima de quem acabou de ser atingido é o que cansa um jogo.

O fix de áudio Web/PWA da 9F não foi tocado (nada mexeu em buses nem no
`Opcoes`).

## B) Corrida da Koliani — causa PROVADA, correcção PARCIAL

**Medido** nos 10 frames golden de
`assets/sprites/koliani_golden_set/frames/run` (faixa dos pés = 12 linhas
acima do `baseline_y`, blocos contíguos por coluna):

| | pé de trás | pé da frente |
|---|---|---|
| percurso em todo o ciclo | **13 px** (x 35–48) | **34 px** (x 59–93) |
| frames em que lidera | **0 de 10** | 7 de 10 (nos outros 3 sobrepõem-se) |

Ou seja: **os frames golden do `run` são um ciclo de UMA perna.** A perna de
trás está desenhada esticada para trás e praticamente plantada no mesmo
sítio nos dez frames, e em nenhum deles o pé de trás passa à frente do da
frente. Não há meia-passada a derivar de lá — a alternância não existe na
fonte. É exactamente o que o Game Master descreve.

**Correcção aplicada** (a menor que é verificável): a cadência da corrida
passa a acompanhar a velocidade (`speed_scale` entre 0,55 e 1,85 em
`koliani.gd`). O ciclo corria sempre aos 13,33 fps da folha: 10 frames /
13,33 fps = 0,75 s, e `Movimento.VEL_CORRIDA` = 240 px/s → **180 px de chão
por ciclo**, para um ciclo de uma passada com uma perna de 23 px. O pé
varria o chão em vez de o agarrar, e a andar devagar a animação corria na
mesma a fundo. Não mexe na física.

**O que NÃO foi feito, e porquê:** fabricar a meia-passada por cirurgia de
pixels. As duas vias possíveis partem a arte e o briefing proíbe
deformações — espelhar o bloco das pernas põe as biqueiras das botas a
apontar para trás, e transladar um membro inteiro descola-o da anca. As 12
poses de corrida da prancha `05_KOLIANI_IDLE_RUN_CLEAN_v1_1.png` **têm**
alternância a sério, mas são de outra paleta (cabelo roxo, botas castanhas)
e usá-las trocava a identidade que o Golden Set fixou.

> **KOLIANI RUN NATIVE FRAMES REQUIRED** — para a passada ler mesmo, faltam
> frames nativos da meia-passada (pé esquerdo à frente), na linguagem do
> Golden Set. Decisão do Game Master.

## C) Tremor do fundo do L2 — causa PROVADA, corrigido

Sonda nova: `tools/probe_jitter_fundo.gd`. Corre o nível com input real e
mede, por frame **desenhado**, a velocidade do fundo na tela.

**Duas armadilhas de método** que estragaram os primeiros ensaios todos e
não se devem repetir:

- **Sem `--fixed-fps` não se mede nada.** Com vsync desligado o frame dura
  entre 1,2 e 17,3 ms, e o avanço por frame varia na mesma proporção — isso
  é *correcto*, não é tremor. Tremor é a **velocidade** a oscilar.
- **Não se mede encostado a uma parede** (o 1.º ensaio saiu 141 frames
  parados em 150) **nem em cima de uma inversão de marcha**, onde a câmara
  acelera de propósito por causa do look-ahead de 112 px.

Em regime permanente, mesma árvore, mesmo input:

| | dp/média | picos |
|---|---|---|
| 165 Hz, `position_smoothing` ligado | **1,70** | 1 a 1000 px/s |
| 165 Hz, `position_smoothing` fora | **0,87** | máx. 187 px/s |
| 60 Hz (ecrã = física) | **0,22** | nunca tremeu |

**Causa:** o `position_smoothing` do `Camera2D` é resolvido no passo de
**física**, e o projecto tem `physics/common/physics_interpolation=true`. O
próprio motor avisa: *"Camera2D overridden to physics process mode due to
use of physics interpolation"*. Acima dos 60 Hz — o ecrã do Paulo anda a 165
— as duas suavizações entram em conflito e a vista avança aos saltos. Por
isso é "constante em movimento" e não se vê em screenshot nenhum.

**Correcção:** `position_smoothing_enabled = false` no `Koliani.tscn`. O
toque de câmara fica: o look-ahead (`_seguimento`, no `_process`) é que dá a
suavidade, e não foi tocado.

**Duas hipóteses testadas e DESCARTADAS** (escritas no `camera_tremor.gd`
para não se re-derivarem):

- *Refazer o atraso à mão no `_process`* dá **pior** — 2781 px/s de pico. Em
  `_process`, `global_position` é a posição da **física** e anda aos degraus
  de 60 Hz; somar um atraso calculado sobre ela a uma câmara já interpolada é
  misturar dois relógios.
- *"O `ParallaxBackground` é legado e atrasa-se em relação ao mundo"* é
  **falso**. Medido a 165 Hz, `scroll_offset.x` e a origem da
  `canvas_transform` são iguais até à milésima em **todos** os frames. O
  fundo nunca esteve dessincronizado da câmara — o que tremia era a câmara, e
  as duas coisas tremiam juntas. **Não há migração para `Parallax2D` a
  fazer.**

## D) Qualidade visual do fundo do L2 — NÃO MELHORADA

Não foi tocada. A 9H.12D já tinha medido que não existe fonte com mais
informação no repositório para a Região I (prancha 08 = 1536×1024; o recorte
do panorama = 952×247), e o briefing proíbe upscale/sharpen a fingir de HD.

> **L2 NATIVE HYBRID ART REQUIRED** — mesma decisão pendente do L1.

## F) QA jogado

`tools/qa_jogar_9h13.gd` — abre o L2 numa janela real e joga-o com input,
lendo o pool do `Som` para provar que cada evento chegou ao áudio.

- **23/23 streams novos carregam** (nenhum caminho partido no `Som.CAMINHOS`
  — era o modo de falhar mais provável deste passe, porque vários sons
  mudaram de `.ogg`/`.mp3` para `.wav`).
- Tocaram, com input real: `salto` ×3, `aterrar` ×3, `passo1/2/3`, e o
  **combo completo `ataque` → `ataque2` → `ataque3` → `ataque_forte`**, um de
  cada.
- Suite headless: **26 falhas — as mesmas 26 do baseline 9H.12E** (23×
  contrato `9H.7B` + 3 contratos de arte do L1). **Zero falhas novas.**

### Problemas encontrados

- **PROVEN** — os frames golden do `run` são um ciclo de uma perna (números
  acima). Não corrigido: precisa de arte nativa.
- **PROVEN** — tremor residual a 165 Hz (dp/média 0,87 contra 0,22 a 60 Hz).
  É inerente ao `Camera2D` ser forçado a processo de física pela
  interpolação; o que se podia tirar sem mexer no feel foi tirado.
- **NOT ASSESSABLE** — `dash`, `rolamento`, `bloqueio`, `dano`, `selo`,
  `apanhar` e `transicao` não chegaram a disparar no arnês (habilidades
  trancadas no save de arranque e eventos que precisam de inimigo/checkpoint
  por perto). Os streams carregam; falta ouvi-los em jogo a sério.
- **NOT ASSESSABLE** — a mistura. Ninguém os **ouviu**: os picos estão
  hierarquizados por construção, mas equilíbrio Music/SFX é juízo de ouvido.
- **NOT ASSESSABLE** — arte fora da temática, placeholders, UI. Não foi feita
  auditoria visual (fora do âmbito, e o briefing proíbe alargá-lo).

## Follow-up (não aberto nesta execução)

1. Frames nativos da meia-passada da Koliani (KOLIANI RUN NATIVE FRAMES).
2. Arte nativa Hybrid do fundo do L2 (L2 NATIVE HYBRID ART).
3. Ouvir os 23 sons em jogo e afinar a mistura.
4. As 26 falhas da suite continuam por decidir desde a 9H.12E.
5. `build/windows/Koliani.exe` **não** foi actualizado — ver o ponto de
   retoma.
