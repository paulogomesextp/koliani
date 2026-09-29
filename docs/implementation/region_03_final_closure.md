# REGIÃO III — TORRE DOS ECOS · FECHO (20 set 2026)

**Branch:** `claude/region03-completion-pass`
**HEAD de entrada:** `29c0e87c` (a branch tinha avançado legitimamente
desde o `3c1ca794` do briefing; usou-se o remoto mais recente)
**Contrato:** [`REGION03_VISUAL_GAMEPLAY_CONTRACT.md`](../art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md)
**Auditoria por eixo:** [`AUDITORIA_EIXOS.md`](../playtests/region_03_visual_evidence/AUDITORIA_EIXOS.md)

Fecha os três bloqueios que mantinham a região em PARTIAL: o dano
colateral noutras regiões, a auditoria visual por eixo, e a legibilidade.

---

## GATE 1 — o dano colateral

### O que se pedia

As mecânicas canónicas **ficam** na Região III; o traçado de mais nenhum
nível pode mudar. A solução tinha de ser arquitetural.

### O que realmente estava a acontecer — TRÊS causas, não uma

A primeira correcção (`a5eadae0`) tratou só a primeira e o modelo
analítico disse "zero níveis afectados". A verificação empírica dos 100
níveis desmentiu-o: **10 diferentes**, cinco deles fora da região. As
causas:

**1. A pool.** A `MECANICA_DO_NIVEL` decidia também o desbloqueio global,
e o `_pool_permitida()` **duplica o peso** de uma câmara nos 8 níveis a
seguir ao desbloqueio. Antecipar o `elevador` de 15 para 11 tirava-lhe o
peso dobrado no nível 20, que passava a sortear outra coisa.

> Armadilha: comparar só **que** câmaras estão disponíveis dá um falso
> "está tudo bem". O modelo tem de ser o **multiconjunto pesado**.

**2. O `cam` é a câmara-assinatura.** Não é só o rótulo do tutorial: é a
câmara que o gerador **força** na jornada daquele nível (`_estreia_cam`).
Ter dado o slot do N16 a outra coisa mudou-lhe **832 linhas** de
geometria, e o do 56, **848**.

**3. O `grau`.** Ao reescrever a linha 55 perdeu-se o `grau: 1`. O `grau`
manda quantas vezes a assinatura é forçada (`1 + grau`): o master
constrói `engrenagens` duas vezes no nível 56 e a versão nova construía
uma. Apanhado com `tools/camaras_do_nivel.gd`, que lista a sequência de
câmaras de um nível — sem ele isto não se encontrava.

### A correcção

Separar **apresentação** de **desbloqueio**:

| | onde vive | para que serve |
|---|---|---|
| `nivel_de_apresentacao()` | posição na `MECANICA_DO_NIVEL` | só o aviso de tutorial |
| `nivel_de_desbloqueio()` | `DESBLOQUEIO_BASE` (global, congelado) + `DESBLOQUEIO_REGIAO` (local) | quando a câmara pode aparecer |

A Região III antecipa `elevador`, `engrenagens` e `espectral` para o
início da região. **Mais nenhuma região vê essa antecipação.** Os slots
da tabela fora de 11-14 voltaram exactamente ao que eram, `grau`
incluído.

### Uma quarta causa — mas da ferramenta, não do jogo

A `PlataformaRitmada` liga e desliga a colisão ao ritmo de
`Time.get_ticks_msec()` — **relógio de parede**, que o
`Engine.time_scale = 0` não congela. O estado dela depende de há quanto
tempo o processo arrancou, e a baseline acusava "regressões" que mudavam
de plataforma a cada corrida. A ferramenta passa a registar `ritmada` em
vez do estado; posição, tamanho e `periodo` continuam comparados.

### Teste de regressão

`teste_desbloqueio_nao_segue_a_apresentacao` prende o calendário
histórico das oito câmaras que mudaram de lugar, exige que a antecipação
da Região III seja invisível às outras 19, exige que dentro da Região III
elas estejam mesmo disponíveis, e exige que apresentação e desbloqueio
não voltem a ser a mesma coisa. **Provado por mutação:** tirando o
`DESBLOQUEIO_BASE` da consulta, a suite sai 1 e aponta `vento` (13, devia
ser 11), `serras` (0, devia ser 12) e `gravidade` (0, devia ser 13).

---

## GATE 2 — auditoria por eixo

Feita em [`AUDITORIA_EIXOS.md`](../playtests/region_03_visual_evidence/AUDITORIA_EIXOS.md),
APPROVED vs BEFORE vs AFTER, quinze eixos por nível mais o Vyrak.

**Nenhum LOW. Nenhum FAILED.** Onde ainda não é HIGH está dito lá, sem
maquilhagem: midground, densidade visual e composição ficam em MEDIUM
porque a prancha mostra arcadas densas camada sobre camada e a jornada é
procedural — encher mais arriscava tapar a leitura do gameplay.

---

## GATE 3 — legibilidade

Duas medições, não impressões.

### A pedra estava violeta

Nas dominantes da prancha o verde está sempre **acima** do vermelho:
(24,48,96), (48,72,144). No jogo era ao contrário: (96,72,120),
(48,24,72). Vinha do `veio` magenta do *key_art* que o
`gerar_terreno.py` aplica a todas as regiões.

| Ficheiro | G−R antes | G−R depois |
|---|---|---|
| `topo.png` | −13,0 | **+8,6** |
| `corpo.png` | −12,3 | **+4,8** |
| `lado.png` | −9,6 | **+3,4** |

`tools/recolorir_terreno_torre_ecos.py` — idempotente (guarda os
originais em `_origem/`). O bioma `torres` é exclusivo da Região III.

### Os props de luz não davam luz

A prancha é escura mas **polvilhada de luz quente**. O jogo tinha
lanternas, braseiros, candelabros e vitrais desenhados e **zero**
`PointLight2D` neles — daí metade do ecrã ser massa preta. Agora acendem.

**Custo medido** (`tools/contar_luzes.gd`), porque o jogo é mobile a
60fps: com as luzes 78/110/107 por nível, sem elas 63/95/84 — ou seja
**15-23 minhas, ~20% do total**. O grosso vem dos checkpoints, das
alavancas e das luzes próprias da jornada. No ecrã são 3-7 em vista.

> Armadilha de método, registada porque quase passou: uma corrida da
> suite levou 25 min e eu atribuí isso às luzes novas. Cronometrada
> sozinha, **a suite leva 14 segundos**. Os 25 min eram inteiramente
> **contenção de CPU** com o batch dos 100 níveis a correr em paralelo —
> e o "~8 min" que eu usava como referência também era contenção, de
> outra corrida. Medir sozinho, antes de concluir.

### A geometria não mudou com isto

Luzes e recolorações são visuais: `Sprite2D`, `PointLight2D` e PNGs. A
baseline funcional ignora-os de propósito, e os cinco níveis da Região
III continuam idênticos entrada por entrada nas Fases 1-2.

---

## VERIFICAÇÃO GLOBAL DE GEOMETRIA

Os 100 níveis, "antes" com o gerador do `master` e "depois" com este
HEAD, comparados entrada por entrada (colisões, corpos, perigos,
checkpoints, spawn, porta, arena).

| | |
|---|---|
| **UNCHANGED COUNT** | **95** |
| **CHANGED COUNT** | **5** |
| **CHANGED LIST** | **11, 12, 13, 14, 15** |
| **CHANGED OUTSIDE REGION III** | **0** |

Os cinco alterados são exactamente os cinco da Torre dos Ecos, que é onde
as mecânicas canónicas entraram. **Nenhum outro nível do jogo mudou de
traçado.**

Para contexto do que isto custou a atingir: a primeira verificação
(depois da correcção que o modelo analítico dava por boa) deu
**90 iguais / 10 diferentes**, com 16, 26, 56, 77 e 99 fora da região. É
a diferença entre um modelo e uma medição.

---

## O QUE FICA

- `serras` e `gravidade` já não têm nível onde sejam **apresentadas** (os
  slots eram o "Observatório Lunar" e a "Torre da Tempestade", que o
  cânone renomeou). Continuam a aparecer, no mesmo calendário; perderam
  o aviso de estreia.
- `elevador` é assinatura do N12 **e** do N16. Quem joga conhece-o no
  N12; o N16 não o reapresenta. O teste aceita **uma** repetição, nomeada
  — uma segunda volta a falhar.
- A queda punitiva do N15 **não foi tocada**: continua reservada para
  playtest humano, como mandado.

---

## PRODUÇÃO — o que ficou publicado, e o que não foi verificado

`master` em `7f789a18`, versão **0.18.19**. Integração por
**fast-forward** a partir de `17b90e28`: sem merge commit, sem force
push, sem amend de commit publicado.

| CI run #487 (`7f789a18`) | |
|---|---|
| Testes headless (suite + 9 verificadores) | **success** |
| Build Android (APK debug) | **success** |
| Build Windows (release) | **success** |
| Build Web | **success** |
| Publicar o Web no GitHub Pages | **success** |

Release `win-latest` reescrito às 09:54:40 pelo job de Windows dessa run:
`Koliani-windows.zip`, 131 168 223 bytes,
`sha256:08d9a266794a7b8a71acbfdfe2982678498e9203f3a8c28285049c3ac45d36d9`.
Corpo do release aponta o commit `7f789a187a3061f6ca3a369fa0f60e076f9d04aa`.
**MASTER == WINDOWS SOURCE == PWA SOURCE**, os três no mesmo SHA.

### A run que encravou, e porque não era do código

A run #486 (`e4576f1e`) ficou **mais de 40 minutos** no passo "Correr
suite de testes" e nunca fechou — o `updated_at` dela não avançou depois
de 09:19:51. Era tentador chamar-lhe falha do código, porque esse passo
é exactamente onde entraram as luzes novas. Não é:

- a suite cronometrada sozinha nesta máquina leva **14 s**, saída 0;
- o mesmo passo, no mesmo runner do GitHub, correu em **30 s** na #487
  (09:48:56 → 09:49:26) com um HEAD que só difere da #486 em três
  ficheiros de documentação.

Um passo que passa de 30 s para >40 min sem alteração de código é
infraestrutura. A #487 substitui-a.

### O que NÃO foi verificado — dito por inteiro

1. **O `.exe` não foi aberto em Windows.** O contentor não tem Windows
   nem wine. O que se validou foi o `.pck` extraído do executável
   exportado localmente do mesmo `master`: corre, imprime
   `RUNTIME TRACE | build=0.18.19`, o menu desenha e os assets da torre
   estão lá. Abrir o `.exe` a sério continua por fazer.
2. **A PWA pública não foi aberta.** A rede deste contentor bloqueia
   `github.io`. O que se reporta é o registo do deployment e o `head_sha`
   — não uma visita à página. Não se inventa validação.
