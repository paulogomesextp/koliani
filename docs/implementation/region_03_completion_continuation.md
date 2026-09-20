# REGIÃO III — TORRE DOS ECOS · CONTINUAÇÃO (20 set 2026)

**Estado: PARTIAL.** Não integrado em `master` — ver §6.

**Branch:** `claude/region03-completion-pass`
**HEAD de entrada:** `3c1ca794` (confirmado por `git fetch`, LOCAL == REMOTE)
**Contrato:** [`REGION03_VISUAL_GAMEPLAY_CONTRACT.md`](../art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md)
**Passagem anterior:** [`region_03_completion_pass.md`](region_03_completion_pass.md)

---

## 1. O QUE A REGIÃO ERA, MEDIDO

Antes de mexer em nada, `tools/baseline_geometria.gd` (novo) gravou o que
os cinco níveis têm de funcional — 2278 entradas. O retrato:

| Actor | Total nos 5 níveis |
|---|---|
| `plataforma` | 652 |
| `serra` · `fogo` · `espinhos` | 57 · 30 · 27 |
| **`sino_torre`** | **4** |
| `plataforma_espectral` · `plataforma_roda` · `tumulo_elevador` · `vitral` | **0 · 0 · 0 · 0** |

Uma região cujo elemento central são sinos tinha quatro sinos e nenhuma
das mecânicas que o contrato §2 lhe dá. Corria como masmorra genérica com
nomes novos.

E o bioma `torres` tinha **12 props**, três deles de **cemitério**
(`cruz`, `lapide`, vindos da folha `gothicvania-cemetery`) — metade da
razão de os cinco níveis lerem como campa. A Região II, já passada, tinha 25.

---

## 2. O QUE SE FEZ

| Área | Antes | Depois |
|---|---|---|
| Props do bioma | 12 (3 chão / 5 parede / 4 pendurados) | **32** (10 / 13 / 9) |
| Props de cemitério | `cruz`, `lapide` | **removidos** (ficam nas Catacumbas) |
| Arquitetura | toda em `z = -3`, escurecida (fundo) | **46 %** plantada em `z = -1`, à escala de quem passa |
| N12 estreia | `vento` (assinatura da Região II) | **`elevador`** |
| N13 estreia | `serras` | **`engrenagens`** |
| N14 estreia | `gravidade` (do "Observatório Lunar") | **`vento`** (updraft) |
| N15 estreia | `torre` (não é mecânica) | **`espectral`** (ilusórias) |
| Pool da região | sem elevador/engrenagens/vitral/espectral | as 17 do cânone |
| Plataformas ilusórias | 0 | **20** |
| Rodas / engrenagens | 0 | **6** |
| Elevadores | 0 | **3** |
| Sinos | 4 | 6 |
| Vyrak na lore | "escama caída", "o dragão deitou-se", "Presa" | **A Voz dos Ecos**, nas 6 línguas |

`tools/gerar_props_torre_ecos.py` **desenha** os props em vez de os
recortar, porque tem de o fazer: o `gerar_deco.py` recorta das folhas em
`assets/sprites/incoming/`, que não vem no Git, e das fontes do bioma
`torres` (`church`, `cemetery`, `town`) **nenhuma existe fora da máquina
do Paulo**. O precedente é o fundo desta mesma região, que já é desenhado.

---

## 3. GEOMETRIA — o que não podia mudar, e não mudou

As Fases 1 e 2 (arquitetura e props) fecharam com **0 alterações
funcionais**: os cinco níveis da Região III idênticos entrada por entrada,
mais os níveis 1, 5, 8, 18, 23, 28 e 38 de outras cinco regiões.

Duas armadilhas que custaram voltas:

1. **O `_rng` do gerador é um só e sequencial.** Um sorteio a mais na
   decoração desloca tudo o que vem a seguir e muda a geometria de todos
   os níveis de todas as regiões. A decoração passou a ter gerador próprio
   (`_rng_deco`), e o `_coluna_fundo` continua a consumir os mesmos quatro
   sorteios, pela mesma ordem, mesmo quando a peça acaba desenhada à frente.
2. Dentro dessa função, o `return` da textura que não carrega tem de ficar
   **antes** dos outros três sorteios. Pô-lo depois fazia uma textura em
   falta consumir quatro em vez de um — e a baseline do nível 1 acusou logo
   uma colisão com `disabled` trocado.

E uma armadilha de **método**: a primeira baseline do nível 1 foi capturada
logo a seguir a um `git stash`, com a cache de importação do Godot ainda
desalinhada, e deu um falso positivo. Uma baseline só vale depois de um
`--import` estável.

---

## 4. O PREÇO DAS MECÂNICAS — declarado, não escondido

A Fase 3 **muda de propósito** a forma dos cinco níveis. Mas muda também
**doze níveis de outras regiões**, e isso ninguém pediu.

### Porquê

A `MECANICA_DO_NIVEL` fazia duas coisas ao mesmo tempo: dizia o que cada
nível *apresenta* e, por ser a primeira ocorrência, decidia a partir de
quando cada câmara fica *disponível em todas as regiões*. E o
`_pool_permitida()` ainda **duplica o peso** de uma câmara nos 8 níveis a
seguir à estreia. Dar à Torre dos Ecos elevadores, engrenagens e
plataformas ilusórias obriga essas câmaras a desbloquear mais cedo — e
isso reescreve o traçado de quem vinha a seguir.

**Níveis afectados: 20, 41-45, 51, 56-60.**

Nenhum regride: a suite, as 100 jornadas, o alcance de todas as salas e o
`verifica_spawn_livre` passam. Nenhuma dessas regiões teve ainda a sua
passagem de cânone. Mas é uma decisão do Paulo, e está no `PRIORIDADES.md`.

### A armadilha que quase passou

A primeira análise comparou só **que** câmaras ficavam disponíveis, deu
"zero níveis afectados" — e o nível 23 mudou 1372 linhas de geometria na
mesma. Faltava a duplicação de peso: o modelo tem de ser o **multiconjunto
pesado**, não o conjunto.

E antes disso, uma pior: `nivel_de_estreia()` devolve **0** para uma câmara
que não esteja na tabela. Ao tirar `serras`, `gravidade` e `torre` dos
únicos sítios onde estreavam, as três passaram a estar disponíveis **desde
o nível 1** — a Floresta ganhou salas de serra, e o `verifica_spawn_livre`
apanhou-o como *"respawn não permite salto (8 px)"*, que é risco de
softlock.

### O que ficou por resolver

`serras` e `gravidade` ficam com o desbloqueio preso (`DESBLOQUEIO_FIXO`)
mas **sem nível onde sejam apresentadas**. Continuam a aparecer; perderam
o aviso de estreia. Era isso ou reconstruir mais níveis.

---

## 5. FIDELIDADE — avaliação honesta

| Eixo | Passagem anterior | Agora |
|---|---|---|
| **Arquitetura do primeiro plano** | **LOW** | **MEDIUM-HIGH** — arcos, vitrais, colunas e sinos grandes na camada onde se anda |
| **Props jogáveis** | **LOW** | **MEDIUM-HIGH** — 32 props canónicos, sem cemitério |
| Mecânicas por nível | ausentes | **implementadas**, uma assinatura por nível |
| Vyrak | HIGH em silhueta, lore de dragão | **HIGH**; lore alinhada nas 6 línguas |
| Paleta · inimigos · background | HIGH / HIGH / MEDIUM | inalterados |
| **Iluminação / legibilidade** | — | **MEDIUM** — ver abaixo |
| Identidade entre os 5 níveis | MEDIUM | **MEDIUM** |

### Porque é que ainda NÃO é PASS

1. **A auditoria por eixo A–N contra as pranchas APPROVED não foi feita.**
   A Fase 5 pede APPROVED vs BEFORE vs AFTER, nível a nível, eixo a eixo.
   O que há é prova visual real dos cinco níveis
   (`fase3_mecanicas/`), não a comparação completa.
2. **Legibilidade.** Em todos os cinco níveis, uma parte grande do ecrã é
   massa quase preta. Não é LOW — a identidade está lá — mas não é o
   "próximo de Dead Cells" que o projeto quer, e declarar HIGH seria
   exactamente a falsa fidelidade que o contrato §9 proíbe.
3. **Os doze níveis de outras regiões** (§4) precisam de decisão humana.

---

## 6. PORQUE É QUE NÃO FOI PARA `master`

O briefing é explícito: só PASS integra, e isto é PARTIAL (§5). Por isso
**não houve integração, nem build de Windows, nem publicação de PWA** — o
briefing manda guardar, fazer commit, push da task branch e parar.

---

## 7. PRÓXIMA FASE

1. Decisão do Paulo sobre os doze níveis (§4) — é o que desbloqueia tudo.
2. Auditoria de fidelidade eixo a eixo contra as pranchas APPROVED.
3. Iluminação e legibilidade dos cinco níveis (a massa preta à esquerda).
4. `serras` e `gravidade`: onde é que passam a ser apresentadas.
5. Só depois: integração, Windows e PWA.
