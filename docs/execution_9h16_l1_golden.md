# Execution 9H.16 — L1 como GOLDEN LEVEL (fases B–F)

Ramo `codex/9h16-l1-perfection`, a partir do checkpoint `b6f2d959`.
Executor: Claude Opus 5, 13 de setembro de 2026.

Resumo de uma linha: **a Phase B fechou com QA nativo real; C, D e E
entregaram alterações provadas; a Phase F correu numa build de release
limpa mas o percurso completo do L1 continua HUMAN PLAYTEST REQUIRED.**

---

## PHASE B — Development Mode: CLOSED

Validada na build de QA `25a3125a…` (debug 0.18.7), janela real de
1280×720 no 2.º monitor, **com input nativo** (o Game Master autorizou o
foco temporário; foi isso que destrancou esta fase).

| critério | resultado |
|---|---|
| entrada em Developer Mode | PROVEN (botão do menu) |
| equipamento | PROVEN — ARMAS 20/20, ARMADURAS 10/10, as mais fortes equipadas |
| vidas / HP / stats | PROVEN — x99, barras cheias, 1 000 000 de essência |
| habilidades | LIKELY — `habilidades.assign(HABILIDADES_TODAS)` no código; exercitadas dash e salto, não as 100% |
| FlyMode ON/OFF | PROVEN — quatro direções (A/D/W/S), animação `idle` coerente, OFF repõe o movimento sem queda |
| troca de níveis | PROVEN — L1 → L20 → L50 → L100 → L1, sem crash, HUD coerente |
| isolamento do save | PROVEN — ver abaixo |

### Isolamento do save (o critério mais duro)

Estado legítimo capturado ANTES: `level_001` concluído, atual
`level_002`, 168 de essência, 5 vidas, sem skills nem equipamento
(`progresso.json` SHA256 `d302def8f79b…`).

Depois de uma sessão Dev completa — skills, equipamento, FlyMode, quatro
trocas de nível, checkpoint ativado, saída, **reinício do processo**:

- `progresso.json` **byte a byte idêntico** (`d302def8f79b…`);
- seletor NORMAL idêntico à baseline: 1-1 e 1-2 disponíveis, 1-3/1-4/1-5
  trancados;
- `CONTINUAR` carregou o progresso legítimo (1-2, x5 vidas, sem
  equipamento, sem UI Dev).

Não foi preciso corrigir nada: a implementação do checkpoint anterior
passou. Sem commit nesta fase.

**Nota de UX apanhada de passagem:** a pausa abre com `P` mas **não com
`Escape`** (o `Escape` está mapeado em `ui_cancel` e em `pausa` ao mesmo
tempo). Não foi corrigido — fica anotado.

---

## PHASE C — ajudas fora do centro (commit `8d815dba`)

**Causa:** `_posicionar_notificacao()` centrava tudo
(`(larg - size.x) * 0.5`, y >= 160). Em 1280×720 isso cai em cima da
Koliani, dos inimigos e das plataformas de pouso. A placa da mecânica
tinha 560 px e 10 s.

**O que mudou:** canto superior-esquerdo debaixo do cabeçalho, margem de
24 px e um travão que impede a caixa de invadir os 34% centrais
(encolhe-se a caixa, não se empurra para o meio); placa compacta
(560→380 px, texto à esquerda, fontes 22/17→18/15, alpha 0,9); toast
deixa de poder ter `larg - 168` (1112 px num ecrã de 1280) e passa a 30%
da largura; e **durante o combate não há banners grandes** — a placa
espera por uma pausa (chefe em cena ou inimigo vivo a menos de 460 px),
no máximo 6 s, senão numa arena longa nunca aparecia.

**Provado** em 1280×720, renderer real: toast em (24, 94) 305×81, placa
em (24, 94) 360×126 — banda central (422..858) livre nos dois casos;
`EM_COMBATE=true` no spawn adiou a placa como esperado. **Reconfirmado na
build de release com input real** (o aviso do checkpoint apareceu no
canto).

A duração de 10 s da placa MANTEVE-SE, contra o "~2–4 s" do briefing: o
Paulo tinha pedido 10 s explicitamente quando a placa estava no meio do
ecrã, e agora que está no canto já não estorva. Decisão a confirmar.

---

## PHASE D — combate (commit `b3fa7160`)

### D1 — auditoria

A cadeia de 4 golpes já tinha animações, durações, janelas activas,
avanço, VFX e sons próprios. Três coisas faltavam, e são elas que
explicam "o combate é básico":

1. **Os quatro golpes davam o MESMO dano.** `_dano_golpe()` não olhava
   para `_combo_passo`. O 4.º é o que mais compromete (0,26 s, janela
   activa só a 34% da animação) e não pagava nada por isso.
2. **Não havia recuo.** Levar um golpe era `global_position.x += dir * 8`
   — um teletransporte de 8 px, sem física. O bicho não recuava, piscava
   para o lado.
3. **Nenhum golpe mudava a reacção do inimigo** — sem stagger não há
   janela de castigo a conquistar.

### D2/D3 — a cadeia passou a ter curva

| golpe | papel | dano | recuo | estado deixado |
|---|---|---|---|---|
| 1 | abertura | 0,85× (43) | 90 px/s | — |
| 2 | continuidade | 1,0× (50) | 150 px/s | — |
| 3 | compromisso | 1,25× (63) | 230 px/s | **atordoa 0,38 s** |
| 4 | remate | 1,9× (95) | 470 px/s | **sangra 2,6 s + levanta do chão** |

Recuo a sério no `DemonioBase`: velocidade que decai por atrito e que
manda no movimento enquanto dura (senão a IA reescrevia `velocity.x` no
frame seguinte e não se via nada), com `resistencia_recuo` por inimigo.
Em campo aberto o remate atira o bicho **92 px**. As durações e janelas
activas NÃO mudaram: a resposta ao botão é a mesma.

### D4 — inimigos

Telégrafo (`_telegrafo`/`anticipacao`, pisca branco-quente), cambaleio
contra a parede e janelas de castigo pós-ataque **já existiam** e foram
confirmados; não se tocou neles nem se subiu HP. O elite do L1 levou
`resistencia_recuo = 2.2` — é pesado, não voa com o remate.

### D5 — identidade

O L1 já tinha o arco: raízes ritmadas (720–1080) → raízes que agarram
(1300–1520) → o elite ENTRE as duas raízes → teste na arena do chefe.
O que faltava era a mecânica tocar no combate. Agora **a raiz espeta
também INIMIGOS** (máscara 2→6): com o recuo novo, o remate atira o bicho
~90 px e a floresta corrompida acaba o serviço. Os chefes ficam de fora —
o Ghorak semeia estas raízes, seria ele a matar-se.

### Armadilhas

- A nova assinatura `receber_dano(..., forca_recuo)` obrigou a alinhar os
  **30 overrides** dos chefes; sem isso o `main.gd` não compilava.
- **Não se conduz um bench de combo pelo teclado:** os intervalos do
  arnês passavam a `JANELA_COMBO` (0,42 s) e a cadeia reiniciava a meio,
  pelo que cada corrida media passos diferentes (uma delas deu
  `atordoado` no golpe 2 em vez do 3). `tools/bench_combo_9h16.gd` fixa
  `_combo_passo` e chama o acerto.

---

## PHASE E — arte e som (commit `0fd5f8e4`)

### E1 — plataformas: a laje

O bloco é um MOSAICO de `corpo`/`lado`/`base`/`topo`. Mosaico de um
rectângulo dá um rectângulo — é daí que vem a leitura de laje.

Sem inventar silhueta (regra E2): usou-se arte **já produzida e por
usar** do mesmo passe — `terrain_hd/raizes.png` a rematar as pontas e
`terrain_hd/rocha.png` a quebrar a barriga. Só visual, sempre abaixo da
linha de pouso, atrás do miolo.

### E1 — chão/pântano: EM ABERTO

A faixa pálida no fundo do ecrã é o `LiquidoMortal` do corredor gerado.
Medido: triplica a luminância da banda (0,038 → 0,110), sobretudo via
`Superficie` e `Faixa`. A hipótese do véu (`nevoa.png` →
`corrupcao.png`) foi testada e **revertida por não mostrar efeito**.
A integração chão/pântano fica **NATIVE ART REQUIRED**.

### E3 — corrida da Koliani: BLOCKER (confirmado por medição)

Os 10 frames de `koliani_golden_set/frames/run` não têm passada
completa. Medida a abertura das pernas no terço inferior:
38, 40, 39, 38, 38, 53, 44, 46, 43, 56 — os cinco primeiros são
praticamente a mesma pose, e o centro de massa nunca troca de lado
(−7 a +1 px). Não há outra fonte no repo nem no histórico (o único `run`
entrou em `98d8c1b2`). **KOLIANI RUN NATIVE ART BLOCKER** — sem cirurgia
de pixels. Coincide com o PENDENTE 1 já aberto pela 9H.13/14.

### E4 — som: as mecânicas do L1 estavam MUDAS

Auditoria evento → ficheiro dos 22 eventos audíveis no L1. Os 16 da
9H.13 estão ligados e saudáveis (pico 0,65–0,89, RMS −12,5 a −19,7 dB,
zero amostras a clipar). O buraco não era mistura:

    scripts/raiz_perigo.gd         0 chamadas a Som.
    scripts/plataforma_ritmada.gd  0 chamadas a Som.

As DUAS mecânicas-assinatura da Região I não tinham som nenhum — o
telégrafo da armadilha era só visual.

Três sons novos (`tools/gerar_sfx_9h16.py`, método da 9H.13B: três
camadas, normalização por SONORIDADE e não por pico, tudo sintetizado
aqui, zero serviços pagos): `raiz_irrompe` (−13,5 dB, a par do `dano`),
`raiz_aviso` (−21,0 dB), `plataforma_surge` (−19,5 dB).

**A prova apanhou um bug que a leitura do código não dava:** o modo
CENÁRIO da raiz tem a irrupção escrita dentro do `_loop_auto` e NÃO passa
por `_irromper()` — com o som só lá, as raízes do L1 continuavam mudas.
A asserção mordeu antes da correcção.

Legado ainda em uso no L1, medido, **sem julgamento auditivo**
(NOT ASSESSABLE — HUMAN LISTEN REQUIRED): `gelo` (2,12 s, pico 0,99),
`projetil` (pico 0,99), `investida` (pico 0,96), `conquista` (6,12 s),
`agarrar`/`lancar`/`parede`/`esmagar`/`praga` (.ogg). Nenhum clipa.

---

## PHASE F — build e QA jogado

Build de release limpa exportada do worktree `C:\Projetos\koliani-9h16`
para `C:\Projetos\koliani\build\windows\Koliani.exe`
(v0.18.8, 205 755 688 bytes, SHA256 `42764fe5…`).

Jogado com input nativo em 1280×720. **PROVEN:** o L1 abre, o menu e o
seletor normal funcionam, correr/saltar/dash/atacar respondem, os
checkpoints disparam com o aviso já no canto (Phase C confirmada em
release), morte e reentrada no checkpoint funcionam, zero crashes.

**NÃO PROVEN:** o percurso completo até ao Ghorak e a travessia L1→L2.
O input sintético não segura duas teclas ao mesmo tempo sem acorde
explícito, e o platforming do L1 exige-o; cobriu-se o primeiro terço.
**HUMAN PLAYTEST REQUIRED** para o percurso inteiro, para a sensação do
combate e para a mistura de som.

O Developer Mode NÃO aparece nesta build: é `OS.is_debug_build()` por
desenho. Foi validado na Phase B com a build debug.

Observação por confirmar: durante o QA o contador de vidas SUBIU
(5 → 4 → 2 → 6); o save no fim do QA tinha `vidas: 6`. Provavelmente
recolhas de vida no nível, não um defeito — não foi confirmado.

O save legítimo do Paulo foi salvaguardado antes do QA e **reposto no
fim** (`d302def8f79b…`).

---

## Testes

Baseline de 26 falhas conhecidas mantida em todas as fases; **zero
falhas novas**. A única diferença no diff é o TEXTO de uma falha que já
existia ("L1 não usa o terreno do kit"), que agora lista as texturas
novas dos remates.

## Ferramentas novas

- `tools/prova_ajudas_9h16.gd` — posição/tamanho dos avisos em 1280×720
- `tools/bench_combo_9h16.gd` — cadeia de espada, determinista
- `tools/prova_sfx_9h16.gd` — que ficheiros de som tocaram mesmo
- `tools/gerar_sfx_9h16.py` — os três sons das mecânicas
- `tools/probe_faixa_9h16.gd` — amostragem da faixa do fundo
