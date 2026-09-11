# Execution 9B.1 — Koliani Golden Set

Data: 11 de setembro de 2026
Resultado: **BLOCKED — infraestrutura pronta, arte por produzir**

## O que bloqueia, dito sem rodeios

A 9B.1 pede **arte final de produção desenhada de raiz** (Route B): um Golden
Set de ~33 frames de pixel-art premium de uma rapariga de 16 anos, com rosto,
silhueta, roupa, lenço, amuleto e cabelo comprido preto-para-vermelho
consistentes em repouso, corrida, ar e combate.

**Eu não consigo desenhar isso.** Não tenho ferramenta de geração de imagem
nesta sessão. O que consigo fazer é escrever código que desenha formas — e um
programa que desenhasse uma personagem assim produziria exactamente aquilo que
a 9A proibiu: *«generic polygon approximations»*, *«substitute sprites»*,
*«inventar uma Koliani diferente»*. Cairia na condição de paragem da secção 20
e falharia o Gate 2 à primeira vista.

Por isso **não se produziu nem integrou arte nenhuma**, e nada foi apresentado
como candidato. O que se fez foi tudo o resto: verificar a autoridade, medir o
defeito que o Game Master apontou, derivar o contrato de canvas a partir de
números reais, integrar e **provar** o validador, e deixar o caminho pronto
para quem desenhar.

A 9B.1 precisa de um ilustrador — humano ou uma ferramenta de imagem — a
trabalhar contra o contrato abaixo.

---

## A. Estado do Git à partida

| | |
|---|---|
| Branch | `perf/windows-gate-8-1` |
| HEAD à partida | `b1e67b5` |
| `origin/master` à partida | `556fc0e` |
| Checkout principal | `master` em `b2fd8a0`, 36 entradas por versionar |
| Preservação | **nada apagado, movido, reposto ou forçado** |

Sem `reset`, sem `clean`, sem force-push, sem checkout destrutivo. As 5
entradas `?? tools/*.uid` desta worktree e as 36 do checkout principal continuam
exactamente como estavam.

## B. Verificação de autoridade

Recalculado o SHA-256 das seis pranchas necessárias e comparado com o manifesto
da 9A e com `references/manifest.json` do pacote. **6/6 batem.**

| Prancha | Dim. | Modo | Alfa real | SHA-256 (12 primeiros) | Bate |
|---|---|---|---|---|---|
| 01 identidade | 1536×1024 | RGB | não | `91c298010a3e` | ✔ |
| 02 movimento | 1536×1024 | RGB | não | `78788a032734` | ✔ |
| 03 combate | 1536×1024 | RGB | não | `a2d91fc8bff9` | ✔ |
| 05 idle/run | 1536×1024 | **RGBA** | **sim** | `5056b7267283` | ✔ |
| 06 jump/fall/land | 1774×887 | **RGBA** | **sim** | `afbd74469444` | ✔ |
| 07 VFX | 1536×1024 | **RGBA** | **sim** | `6564982d4ccf` | ✔ |

**Sem APPROVED VISUAL AUTHORITY MISMATCH.** Ficheiros consumidos só para
leitura; bytes intactos; nada comitado do pacote.

## C. Contrato de canvas de produção

| Parâmetro | Valor |
|---|---|
| Canvas | **128 × 128** px |
| Altura da personagem em repouso | **64 px** |
| Linha dos pés / pivot | **(64, 104)** |
| Última linha opaca | **Y = 103** ± 1 |
| Formato | PNG RGBA com alfa 0 real |
| Escala no Godot | **1,0** — sem reamostragem |
| `_corpo.offset` | **(0, −18)** |
| Orientação | direita |

### Porquê, com os números que o justificam

**A personagem tem de aparecer do mesmo tamanho que hoje.** O viewport é
1280×720 e a caixa de colisão é 20×44 com os pés a +22 do centro do corpo.
Hoje a figura ocupa 78 px na célula de 160×96 e é desenhada a escala 0,82 —
**64 px no ecrã**. A secção 14 congela colisões, câmara, física e tempos de
combate, portanto os 64 px aparentes são um dado, não uma escolha. O Golden
Set desenha esses 64 px **directamente, a 1:1**, em vez de desenhar 78 e
encolher.

A fórmula que fixa os pés no mundo é
`(baseline − altura_da_célula/2 + offset) × escala = 22`.
Hoje: `(90 − 48 − 15,170732) × 0,82 = 22,0`.
Novo: `(104 − 64 − 18) × 1,0 = 22,0`. **Idêntico.**

**O canvas é maior porque as poses não cabem no actual,** não porque a
personagem cresça. Medido:

- cabelo solto na corrida leva a caixa a **80 px de largura**;
- as poses de ataque do protótipo legado chegam a **124 px** e **rebentam mesmo
  a célula de 160** — o validador acusa `CLIPPED_RIGHT` em 6/6 frames de
  `attack`;
- as poses no ar precisam de margem por cima sem encolher a figura.

128 de largura dá 64 px de cada lado do pivot. 128 de altura dá 40 px acima da
cabeça e 24 px abaixo da linha dos pés.

**Não se fez upscale de nada.** Sprites legados não são promovidos a arte de
produção, nem aqui nem em lado nenhum.

## D. Golden Set

| Animação | Frames alvo | Caminho | Estado |
|---|---|---|---|
| `idle` | 7 | `assets/sprites/koliani_golden_set/frames/idle/` | **NOT_PRODUCED** |
| `run` | 10 | `.../frames/run/` | **NOT_PRODUCED** |
| `jump_start` | 4 | `.../frames/jump_start/` | **NOT_PRODUCED** |
| `jump_loop` | 3 | `.../frames/jump_loop/` | **NOT_PRODUCED** |
| `fall` | 3 | `.../frames/fall/` | **NOT_PRODUCED** |
| `attack_basic` | 6 | `.../frames/attack_basic/` | **NOT_PRODUCED** |
| `vfx_slash_basic` | 6 | `.../vfx/vfx_slash_basic/` | **NOT_PRODUCED** |

Total: **33 frames de corpo + 6 de VFX**. Contagens dentro das faixas da
secção 7, escolhidas pelo mínimo que lê bem, sem frames de enchimento.

Cada pasta já tem um `manifest.json` schema 2, com o contrato de canvas, a
autoridade e o SHA-256 dela, `visual_review_state` e
`runtime_integration_state`. Basta lá pôr os PNGs e correr o validador.

**Tempos de gameplay continuam congelados.** As contagens de frames acima são
visuais; `DUR_*`, hitboxes, física e câmara não mudam por causa delas.

## E. Zero chibi drift — o defeito está medido

O Game Master disse que o salto faz a Koliani parecer chibi. **Confirma-se, e
com números.** Medida a altura da figura em cada frame do conjunto que está
activo na Região I (`koliani_visual_pilot_5g`):

| Animação | Altura média | vs `idle` | Mínimo |
|---|---|---|---|
| `idle` | 78,0 px | referência | 78 |
| `run` | 78,0 px | +0,0% | 78 |
| `turn` | 77,0 px | −1,3% | 74 |
| `run_start` | 74,7 px | −4,2% | 64 |
| `fall` | 73,5 px | −5,8% | 68 |
| `jump_loop` | 70,5 px | **−9,6%** | 67 |
| `jump_start` | 69,0 px | **−11,5%** | **64** |

No pior frame a figura passa de 78 px para **64 px — menos 18%**. A cabeça é
desenhada ao mesmo tamanho em todos os frames, portanto uma perda de 18% de
altura total **é** uma deslocação da razão cabeça/corpo na direcção do chibi.
É aritmética, não opinião.

Tentou-se medir a razão cabeça/corpo directamente por detecção de tom de pele.
**Não serve como prova:** o detector apanha braços e pernas e devolve caixas de
27 a 64 px para a mesma personagem. Fica registado como método descartado, para
não se voltar a gastar tempo nele. A altura da figura é a métrica objectiva.

**Regra de aceitação que fica no contrato:** no Golden Set, nenhum frame perde
mais de **8%** da altura de repouso — 64 px mínimo **59 px** — sem justificação
explícita de pose. Um sprite tecnicamente válido que fique chibi é **FAIL**.

Evidência visual para o Game Master:
`work/production_art_gate/9b1_evidencia/defeito_chibi_salto.jpg`
(oito frames a 4×, com a linha de base a rosa e o topo do `idle` a azul — dá
para ver de relance quanto é que cada pose encolhe).
Números por frame: `.../9b1_evidencia/proporcoes_por_frame.json`.
Ferramenta: `.../9b1_evidencia/medir_proporcoes.py`.

## F. Corpo / Shadowblade / VFX

Contrato escrito e aplicado à estrutura de pastas: corpo e Shadowblade em
`frames/`, efeitos em `vfx/`, ficheiros separados. Nenhum arco de golpe,
rasto, poeira, faísca ou aura dentro de um frame de corpo.

Shadowblade = violeta claro e limpo (autoridade **07**); corrupção = violeta
escuro, magenta profundo e preto. Têm de continuar distinguíveis.

**Sem excepções pedidas.** O erro concreto a não repetir está identificado: a
`koliani_premium_v1` tem o arco violeta pintado dentro dos frames de `attack`,
`attack2`, `attack3`, `attack4` e `dash` — e é isso que a faz rebentar o canvas.

## G. Validador

| | |
|---|---|
| Branch | `tools/production-asset-validator-v2` |
| Commit | `6f13409a421271c904579b6ec0c91130f3752835` |
| Base | `6beb05b` (antepassado de `origin/master`) |
| Integração | **cherry-pick controlado** para `perf/windows-gate-8-1` |
| Colisões | só `docs/retomar_aqui.md`; resolvida sem perder nada |
| Testes próprios | **6/6 OK**, em isolamento e dentro do repositório |

Integrado sem reconciliação: os 16 ficheiros restantes eram novos.

### Prova de que morde em dados reais

Não basta os testes sintéticos passarem. Corri o validador contra os frames que
estão **mesmo no jogo hoje**, cortados para
`work/production_art_gate/validator_evidence/`:

| Alvo | Resultado | Motivo |
|---|---|---|
| `koliani_visual_pilot_5g/idle` (10 frames) | **PASS** | — |
| `koliani_premium_v1/attack` (6 frames) | **FAIL** | `CLIPPED_RIGHT` — o arco pintado sai do canvas |
| `koliani_premium_v1/dash` (3 frames) | **FAIL** | `BASELINE_OUT_OF_TOLERANCE` — 79 em vez de 89 |

Confirma, por uma ferramenta escrita noutra sessão, dois achados da 9A: o VFX
fundido e a linha de base inconsistente da `premium_v1`.

**O que o validador não vê:** rabo-de-cavalo, cor de cabelo, idade aparente,
proporções, rosto, identidade. Passar no validador é **necessário e não
suficiente**. Esses são o Gate 2.

Relatórios JSON e Markdown e contact sheets 1:1 em cada subpasta de
`validator_evidence/`.

## H. Pacote de revisão para o Game Master

O que existe hoje para reveres:

1. `work/production_art_gate/9b1_evidencia/defeito_chibi_salto.jpg` — o defeito
   do salto, visível e medido;
2. `work/production_art_gate/validator_evidence/*/contact_sheet.png` — as três
   contact sheets que provam o validador a morder;
3. `assets/sprites/koliani_golden_set/README.md` — o contrato de canvas.

**Não há contact sheet do Golden Set porque não há Golden Set.** Não marco
nada como aprovado, e não havia nada para marcar.

**O que precisa de decisão tua:** aprovar o contrato de canvas da secção C
(128×128, personagem a 64 px, pivot (64,104), escala 1,0) antes de alguém
desenhar 33 frames contra ele. Mudar o contrato depois custa os 33 frames.

## I. Piloto no Godot

**Integrado: NÃO.** Não há arte para integrar.

`res://scenes/actors/Koliani.tscn` intacto. `scripts/koliani.gd` intacto.
Constantes de movimento, câmara, colisão, hitboxes e tempos de combate:
**nenhuma alterada**. Os fallbacks legados continuam todos ligados — nada foi
desligado antes de haver substituto aprovado.

## J. Windows / K. Web-PWA

**Não construídos.** A secção 15 diz, textualmente, que é aceitável parar no
pacote de revisão e que não se deve integrar arte não aprovada só para
satisfazer requisitos de entrega. Não há arte nova para chegar ao runtime, por
isso um build novo seria idêntico ao actual em conteúdo visual e não provaria
nada.

A discrepância de proveniência da 9A (`BUILD_SOURCE.txt` a apontar para
`05f050e` quando a fonte de performance final é `6beb05b`) **continua por
resolver** e resolve-se no primeiro build que se fizer com arte a sério.
O Performance Gate não foi reaberto.

Android/iOS: fora de scope, não testados, não reportados como bloqueio.

## L. Estado do Git no fim

| | |
|---|---|
| Branch | `perf/windows-gate-8-1` |
| Commits novos | validador (cherry-pick) + esta documentação |
| Trabalho não relacionado | **preservado** |

## M. Bloqueios e decisões

1. **BLOQUEIO REAL — a arte do Golden Set precisa de um ilustrador.** Não é
   falta de autoridade, de contrato, de ferramenta de validação ou de plano.
   É falta de mão que desenhe.
2. **DECISÃO — aprovar o contrato de canvas** antes de a produção começar.

## N. Pronto para o pacote completo da Koliani?

**NÃO.** O Golden Set não existe. A secção 13 é clara: o resto da biblioteca
deriva de um Golden Set aprovado por humano, e não se gasta tempo nele antes
disso.
