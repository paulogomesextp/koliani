# REGIÃO III — PLAYTEST HUMAN-LIKE (BOT)

**Bot:** `tools/bot_humano_r2.gd` — o mesmo da Região II, sem alterações.
**Bateria:** `tools/correr_bot_r3.sh` — 3 perfis × 2 seeds × 5 níveis =
**30 runs**, 600 s de jogo cada, `user://` isolado por run.
**Dados crus:** [`region_03_bot_humanlike_data.json`](region_03_bot_humanlike_data.json).

---

## 1. O QUE ESTE PLAYTEST NÃO PROVA

Isto vem primeiro de propósito, porque o número que salta à vista
(**0 de 30 concluídos**) não quer dizer o que parece.

### 1.1 A conclusão é inalcançável por construção

Os cinco níveis da Região III são níveis de chefe. A `Porta` só abre
quando o chefe morre (`nivel_com_chefe.gd` sela-a até ao sinal
`derrotado`). O bot **não derrota chefes** — nunca derrotou, em nenhuma
região. Logo `concluido` nunca pode ser `true` nestes níveis, e uma
taxa de conclusão de 0 % não mede dificuldade nenhuma.

### 1.2 Controlo na Região II: também dá 0

Para separar "o bot não consegue" de "a Região III regrediu", correu-se
o **mesmo bot** em dois níveis da Região II, que não foram tocados neste
processo:

| Controlo (Região II) | Concluído | Progresso | Encravamentos | Mortes |
|---|---|---|---|---|
| `A_Cela_Zero` — experiente | não | 101 % | 167 | 0 |
| `A_Cela_Zero` — normal | não | 111 % | 128 | 14 |
| `Prisao_dos_Condenados` — experiente | não | 85 % | 26 | 50 |
| `Prisao_dos_Condenados` — normal | não | 85 % | 7 | 56 |

**0 de 4 concluídos na região de referência, com encravamentos ao mesmo
nível ou piores.** O 0/30 da Região III não é uma regressão introduzida
aqui.

### 1.3 A luta com o Vyrak não foi avaliada pelo bot

Em 30 runs, **0 chefes derrotados** e **1 run** em que o chefe chegou a
levar dano. O bot não chega ao topo das torres, por isso não há nenhuma
amostra válida da luta.

**Não se inventa uma avaliação do combate a partir disto.** A prova de
que o Vyrak funciona vem de um **harness técnico** separado, no
`tests/run_tests.gd` (`teste_r3_vyrak_leva_dano_muda_de_fase_e_morre`),
que verifica que ele é atingível, que transita de fase aos 50 % e que
morre. Ver §4.

---

## 2. O QUE OS NÚMEROS MOSTRAM

| Nível | Runs | Concl. | Mortes (méd.) | Progresso | Encrav. | Saltos falhados |
|---|---|---|---|---|---|---|
| N11 Entrada dos Ecos | 6 | 0 | 0,0 | 55 % | 172,5 | 0,0 |
| N12 Galerias Verticais | 6 | 0 | 0,0 | 56 % | 172,8 | 0,0 |
| N13 Mecanismos Antigos | 6 | 0 | 0,0 | 55 % | 172,0 | 0,0 |
| N14 Campanário | 6 | 0 | 0,0 | 56 % | 172,7 | 0,0 |
| **N15 O Topo dos Ecos** | 6 | 0 | **53,3** | 72 % | 83,7 | **48,2** |

Por perfil (10 runs cada): casual 14,8 mortes · normal 5,4 · experiente
11,8. **A ordem não é monótona**, o que confirma que o que se está a
medir não é perícia.

### 2.1 N11–N14: o bot não morre, encrava

Zero mortes e zero saltos falhados, com ~172 eventos de encravamento por
run. Um bot que morresse estaria a falhar o conteúdo; este fica **preso**
a meio, a saltar contra geometria. É uma falha de navegação, não de
dificuldade.

A causa provável é estrutural: o bot foi feito para a Região II, que é
**horizontal** (a sua própria métrica de progresso chama-se `x_alvo`).
A Região III é **vertical** — o cânone chama-lhe "verticalidade real" e
as salas sobem ~930 px. O bot traça a rota por BFS no grafo de
plataformas (traçou 9 passos, mapeou 113 superfícies) mas não a consegue
executar a subir.

### 2.2 N15 é o outlier, e é informação a sério

O N15 é o único com um perfil de falha diferente: **53 mortes** e **48
saltos falhados** por run, com menos encravamentos (83,7) e mais
progresso (72 %). Ali o bot move-se e **cai**. Bate certo com a geometria
medida na auditoria: o N15 é a sala mais exposta (arena ampla no cimo,
vazio por baixo) e a mais pobre em plataformas (13 contra 16).

Isto é um sinal real a levar ao playtest humano: **o N15 tem queda
punitiva**. Não se mexeu nele por causa disto — 53 mortes de um bot que
não sabe subir não chegam para justificar mudar a geometria de um nível
que ninguém jogou ainda.

### 2.3 O resultado negativo que vale mais

**0 frames com NaN em 30 runs** (30 × 600 s = 5 horas de jogo
simulado), e **0 crashes**. O `nan_frames` existe porque já houve um bug
de velocidade não-finita (ver `teste_gate1_hitstop_nao_gera_nan`). Cinco
horas de jogo com os inimigos novos, o Vyrak novo e o fundo novo sem um
único NaN e sem um único crash é a prova mais forte que esta bateria dá:
**nenhum blocker novo foi introduzido.**

---

## 3. LIMITAÇÕES, DITAS COM TODAS AS LETRAS

1. O bot **não avalia dificuldade** nesta região: não morre onde devia
   morrer, encrava antes.
2. O bot **não avalia a luta do Vyrak**. Zero amostras válidas.
3. A métrica `concluido` é **inútil** em níveis de chefe (§1.1).
4. A progressão de dificuldade N11→N15 pedida pelo briefing **não foi
   medida** — para a medir seria preciso um bot que sobe.
5. As mortes do N15 estão **contaminadas**: um bot que falha 48 saltos
   por run inflaciona qualquer contagem de mortes.

### O que faria falta

Um bot com navegação vertical (ou uma rota guiada, dada à mão por nível)
e uma rotina de combate de chefe. Não se fez aqui: seria reescrever o
piloto, e a auditoria e a migração canónica vinham primeiro.

---

## 4. O QUE SUBSTITUI O BOT NA PROVA DO VYRAK

`tests/run_tests.gd`:

- `teste_r3_vyrak_identidade` — rig `vyrak`, escala ~4× Koliani, as duas
  rotações de ataque, os nove ataques da prancha, nenhum ataque de fase 2
  na rotação da fase 1, e nenhum telégrafo abaixo de 0,45 s.
- `teste_r3_vyrak_leva_dano_muda_de_fase_e_morre` — leva dano, entra na
  fase 2 abaixo de 50 % de vida, e **morre** (um chefe que não morre é um
  softlock).

Provados por mutação: repondo o nome de dragão, a assinatura `vento` e o
`boss.sino_vivo`, os testes acendem nos três casos.
