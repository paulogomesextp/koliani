# REGIÃO II — REMODEL TOTAL · PROMPTS 2–3 · FUNDO, ALTITUDE E ARQUITETURA

**Branch:** `claude/region02-total-remodel` · **entrada Prompt 2:** `a275af7e` ·
**entrada Prompt 3:** `5588b04d`
**Plano:** [`REGION02_TOTAL_REMODEL_PLAN.md`](../art_direction/regions/region_02/REGION02_TOTAL_REMODEL_PLAN.md)
**Evidência:** [`prompt_02_background/`](../playtests/region_02_total_remodel/prompt_02_background/)

---

## 1. DIAGNÓSTICO — onde o mar de nuvens se perdia

O plano dizia "a luminância em falta é o mar de nuvens em falta" e mandava
mudar de método em vez de subir o ganho outra vez. A Fase 1 mediu o
pipeline andar a andar, e o resultado **desmente a hipótese do ganho**.

### A fonte está impecável

| Textura | luminância | píxeis claros |
|---|---:|---:|
| `ceu.png` | 56,5 | 0,6 % |
| `serras.png` | 45,8 | 0,0 % |
| **`nuvens.png`** | **132,5** | **100 %** |
| `falesias.png` | 62,2 | 0,2 % |

### O que chega ao ecrã

`tools/diag_nuvens_r2.gd` grava o mesmo instante com e sem a camada de
nuvens. A diferença é exactamente o que elas põem lá:

| | |
|---|---|
| Ecrã com nuvens | lum **36,6** · claros **1,3 %** |
| Ecrã sem nuvens | lum **33,5** · claros **1,1 %** |
| Píxeis que as nuvens alteram | **15,2 %** do ecrã (36,3 % do terço de cima, 1,6 % do de baixo) |
| Céu por trás delas | lum **34,9** |
| Nuvem no ecrã | lum **55,0** — RGB (62, 45, 87) |
| **Pico da nuvem no ecrã** | **170,7** |

### As duas causas, e a que foi descartada

**Descartada: "falta ganho".** O pico chega aos **170,7**. O ganho de 1,7
funciona. Subi-lo mais só estoura o núcleo que já está claro. Fica
registado porque era a conclusão fácil e teria sido a terceira tentativa
falhada pela mesma razão.

**Causa 1 — o substrato.** 20 % da textura das nuvens é **alfa parcial**.
Essa parte mistura-se com o céu que está por trás, e esse céu chega ao
ecrã a **34,9**. É por isso que a média da nuvem cai de 132,5 para 55. O
`_montar_ceu` fazia um degradê entre `cor_fundo` clareada 16 % e
`cor_fundo` escurecida 40 % — com a `cor_fundo` da Região II
(0.06, 0.05, 0.13) isso é quase preto. Faz sentido numa masmorra, onde o
"céu" é tecto; aqui o que está em baixo é **ar**.

**Causa 2 — a composição.** As nuvens ocupam **15,2 %** do ecrã e só o
terço de cima: lêem-se como neblina alta. Na prancha o mar de nuvens é
~35 % e é o **chão do mundo** — está por baixo de quem joga.

---

## 2. O QUE SE FEZ

### `perfil_altitude` — um export novo, vazio por omissão

Vazio = comportamento **exactamente** como antes, e é o que todos os
outros biomas usam. Preenchido (`"n06"`…`"n10"`) troca o céu e a tabela
de camadas. Nenhum outro bioma vê nada disto.

### Céu de altitude (causa 1)

Três paragens em vez de duas — zénite escuro, meio, **horizonte claro** —
com o horizonte puxado para a `cor_luz` **do próprio nível**, para não
inventar cor fora da paleta de cada um.

### Segundo banco de nuvens (causa 2)

`PERFIS_ALTITUDE` acrescenta um segundo banco, mais baixo e maior, em
camada **própria** (`MarBaixo`, `motion_scale` 0,52), entre a `Meio` e a
`Perto`. Duas armadilhas que custaram uma volta:

1. o ciclo de montagem **limpa os filhos da camada a cada item**, portanto
   dois sprites na mesma camada apagam-se um ao outro;
2. o `motion_mirroring` é propriedade **da camada** — dois sprites com
   escalas diferentes não o podem partilhar.

A `MarBaixo` foi também acrescentada ao `_limpar_gerado`, senão os bancos
acumulavam-se a cada nova geração do parallax.

### Uma composição por nível (Fase 3)

Os cinco continuam a sair das **mesmas quatro texturas** — é
recomposição, não cinco biomas. A prancha nomeia um ambiente a cada um:
falésias abertas (6), torres destruídas (7), ilhas flutuantes (8),
ruínas atmosféricas (9), torre celestial (10).

### N09 — a cruz

**Correcção ao Prompt 1.** Eu tinha escrito que a cruz de campa do N09
vinha da camada de fundo e **não** dos props, e que não havia nada a
remover do `deco.json`. **Estava errado.** É o prop `velas.png` — um
nicho de capela com uma cruz gravada por baixo — e está no catálogo do
bioma. Saiu do `desfiladeiro` (25 → 24 props); continua no `torres`, onde
uma catedral de sinos justifica velas.

---

## 3. RESULTADO MEDIDO

Mesma câmara, mesmo método do Prompt 1.

| | prancha | luminância antes → depois | píxeis claros antes → depois |
|---|---:|---|---|
| **N06** | 79,6 / 34,4 % | 35,8 → **53,7** (+17,9) | 0,6 % → **13,3 %** (+12,6 pt) |
| **N07** | 82,8 / 34,9 % | 35,4 → **43,6** (+8,1) | 8,1 % → **14,5 %** (+6,4 pt) |
| **N08** | 87,5 / 39,6 % | 43,6 → **86,9** (+43,4) | 2,4 % → **31,2 %** (+28,8 pt) |
| **N09** | 87,6 / 36,2 % | 32,8 → **62,0** (+29,2) | 3,5 % → **22,6 %** (+19,1 pt) |
| **N10** | 68,9 / 28,0 % | 36,7 → **43,3** (+6,6) | 1,1 % → **5,7 %** (+4,5 pt) |

**O N08 chega praticamente à prancha** (86,9 contra 87,5). O N10 é o mais
fraco e está dito no §5.

### Uma iteração que correu mal, e o que ensinou

A primeira versão dos perfis **piorou o N09** (32,8 → 29,3) e quase não
mexeu no N10. Causa: eu tinha **ampliado** as `serras` e as `falesias`
nesses dois (escala 5,0 e 4,2), e elas passaram a tapar o céu que eu
estava a tentar abrir. O N08 tinha corrido bem precisamente por eu as ter
**encolhido e subido**. Regra que fica: para o mar de nuvens ler, as
camadas opacas têm de sair da frente — aumentá-las trabalha contra o
objectivo.

---

## 4. O QUE NÃO MUDOU — provado

### Geometria funcional

`tools/baseline_geometria.gd`, antes e depois:

| | entradas | |
|---|---:|---|
| N06 | 333 | **IGUAL** |
| N07 | 59 | **IGUAL** |
| N08 | 351 | **IGUAL** |
| N09 | 79 | **IGUAL** |
| N10 | 381 | **IGUAL** |

**0 diferenças funcionais.** O **N08 continua LOCKED**: ilhas, gaps,
planar, vento, checkpoints e rota byte a byte.

### Outras regiões

Baseline do `master` contra este HEAD nos níveis 1, 5, 12, 23, 38, 56,
77 e 99: **todos IGUAIS**. **0 alteradas fora da Região II.**

### RNG funcional

Não foi tocado, e por construção: o `_gerar_parallax` tem RNG **próprio**
(`hash("seed_ambiente|bioma")`) que nunca toca no `_rng` do
`gerador_corredor`. Tudo o que este prompt mexeu vive nesse lado.

---

## 5. O QUE FICA POR FAZER, DITO SEM MAQUILHAGEM

- **A lua de sangue do N10 NÃO foi entregue.** Está implementada e
  medida a funcionar — o diagnóstico mostrou-a viva, visível, em
  (870, 144), na sua própria camada — mas em todas as posições que
  testei há falésias de fundo a passar-lhe à frente nesta zona do nível.
  Cinco tentativas, quatro causas distintas encontradas pelo caminho
  (z_index, ordem de desenho, camada que se desloca com o mundo, e a
  origem do `ParallaxBackground` ser o canto e não o centro). Continuar a
  empurrá-la pelo ecrã é afinar contra uma captura, não resolver.
  **Removida deste prompt**; passa para o Prompt 3, onde a Torre
  Celestial é trabalhada de qualquer forma e a composição do fundo do
  N10 vai ser mexida a sério.
- **O N10 é o nível mais fraco** (5,7 % de claros contra 28 % da
  prancha). A causa é a mesma: a arena está rodeada de falésias de fundo
  que fecham o céu. Resolve-se na composição, que é Prompt 3.
- **O N07 fica a 14,5 %** contra 34,9 %. Foi deliberado: a silhueta dele
  estava classificada KEEP na auditoria e mexer-lhe muito arriscava
  perder o único nível que já lia como altitude.
- Os FX que a prancha tem e o jogo não — **aurora no céu** e **raios
  distantes** — não entraram. São Prompt 4.

---

## 6. PROMPT 3 — ARQUITETURA E LANDMARKS

O lote acrescenta arquitetura de primeiro plano comum ao Desfiladeiro e um
landmark exclusivo, deliberadamente colocado, a cada nível:

| nível | landmark | composição final |
|---|---|---|
| **N06** | ponte monumental | três arcos sobre a rota aberta |
| **N07** | torre partida | silhueta quebrada na jornada, fora da casca fechada da sala authored |
| **N08** | queda de água | cascata no vazio entre duas ilhas, sem criar chão |
| **N09** | altar em ruínas | altar exposto e legível na aproximação |
| **N10** | Torre dos Céus + lua de sangue | torre a enquadrar a arena, lua em segunda profundidade |

As cinco peças maiores partem de fontes geradas para este lote, guardadas em
`assets/sprites/pixel/arquitetura/desfiladeiro/_source/`. O script
`tools/gerar_arquitetura_regiao02.py` recorta o alfa, limita a resolução e
gera os PNGs usados pelo jogo; a lua é gerada deterministicamente pelo mesmo
script. Os fallbacks desenhados no script permitem reconstruir o lote mesmo
sem as fontes.

`Atmosfera._arquitetura_altitude()` trata as salas authored: posições fixas,
`Sprite2D`, `z_index` negativo e nenhuma física. A jornada procedural recebe o
mesmo vocabulário de arcos, colunas, janelas e balaustradas através de
`_rng_deco`; os quatro sorteios de `_rng` que existiam em `_coluna_fundo()`
continuam exactamente no mesmo lugar e pela mesma ordem.

### Prova visual

Capturas finais com renderer Vulkan real:
[`prompt_03_architecture/`](../playtests/region_02_total_remodel/prompt_03_architecture/).
`FINAL_N06.png` a `FINAL_N10.png` mostram os landmarks; `INICIO_N06_inicio.png`
a `INICIO_N10_inicio.png` repetem a câmara de medição do Prompt 2. A captura
estática dos landmarks destaca a `Camera2D` da personagem e **não** é prova de
travessia.

| | luminância Prompt 2 → Prompt 3 | claros (`luma > 110`) Prompt 2 → Prompt 3 |
|---|---:|---:|
| **N06** | 53,7 → **49,7** | 13,5 % → **13,6 %** |
| **N07** | 43,6 → **43,9** | 14,8 % → **14,8 %** |
| **N08** | 86,9 → **83,0** | 31,1 % → **29,3 %** |
| **N09** | 62,0 → **62,4** | 22,7 % → **22,7 %** |
| **N10** | 43,3 → **44,0** | 5,8 % → **6,5 %** |

N06 e N08 perdem luminância média porque a arquitetura opaca ocupa parte do
céu, mas N06 preserva a fracção clara e N08 continua dentro da meta de
20–30 %. N10 melhora ligeiramente e, sobretudo, recebe finalmente a composição
torre + lua que faltava.

### Prova funcional e estrutural

- `tools/baseline_geometria.gd`, HEAD de entrada contra este lote:
  **100 ficheiros, 100 iguais, 0 diferenças funcionais**. Isto inclui o N08
  LOCKED e as 19 regiões fora do âmbito.
- `tools/verifica_arquitetura_regiao02.gd`: **5 níveis, 0 falhas**. Confirma
  landmark certo e exclusivo, pelo menos quatro peças por nível, texturas de
  produção, `z_index < 0` e ausência de corpos/colisões.
- Import Godot 4.7.2 e smoke N06–N10: **0 erros novos**.
- Onze guardas dirigidas (`regras_bicho`, actores, jornada, mecânicas, alcance
  dos 100 níveis, Aerion, baú, câmaras, spawn, vento da Região II e
  arquitetura): **11/11, 0 falhas e 0 erros**.
- Suite: código **0**, todos os testes `OK`, save real intacto. Os 30 erros de
  teardown (`data.tree` nulo, instância libertada e RIDs) são **idênticos**, em
  número e texto, no HEAD de entrada `5588b04d`; não foram introduzidos por
  este lote.

### Fecho do Prompt 3

**PASS técnico do lote. HUMAN PLAYTEST REQUIRED** para composição, leitura em
movimento e sensação do percurso. Não integrar em `master`: a Região II ainda
tem os Prompts 4–6. Próximo passo, e só ele: **Prompt 4 — props, luz,
anti-repetição e FX atmosféricos**.
