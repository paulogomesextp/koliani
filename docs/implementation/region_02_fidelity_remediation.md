# Região II — Fidelity & Playability Remediation (Super-Process A2)

**Estado: quase completo — falta o relatório final e uma varredura de
harnesses. Ver "O que falta" no fim.**
**Data:** 18 set 2026
**Base:** `claude/region02-humanlike-bot-playtest` @ `1bfda76f`
**Branch:** `claude/region02-fidelity-remediation`
**Feito e provado:** GATE 1, GATE 2, Fases 3, 4, 5, 6, 7 e 9.

Ponto de partida: [`docs/playtests/region_02_bot_humanlike_playtest.md`](../playtests/region_02_bot_humanlike_playtest.md).

---

## Ambiente desta execução (importante para quem retomar)

Correu em **Linux headless**, não na máquina do Paulo. O binário do Godot
4.7.2 não vem no contentor; foi buscado a
`github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`.

O `tools/correr_testes.ps1` é PowerShell e isola o `user://` por `%APPDATA%`.
Em Linux o equivalente é `XDG_DATA_HOME`:

```bash
SANDBOX=$(mktemp -d)
XDG_DATA_HOME="$SANDBOX" godot --headless --path . res://tests/run_tests.tscn
```

As fotografias precisam de `xvfb-run -a --server-args="-screen 0 1280x720x24"`
mais `--rendering-driver opengl3`.

**Armadilha de método:** as runs do bot **não são determinísticas entre
processos**, mesmo com a mesma seed — a seed só governa o RNG do bot, e o
jogo usa `randf()` global. O NaN do N06 aparecia em ~1 de cada 4 runs, e a
primeira tentativa de reproduzir (2 runs) não o apanhou. Foi preciso correr
12 em paralelo.

---

## GATE 1 — o NaN do N06

### Reproduzido

Sim. Armadilha nova em `tools/bot_humano_r2.gd` (`nan_frames`,
`nan_primeiro`), que despeja o estado todo no primeiro frame em que a
posição ou a velocidade da Koliani deixa de ser finita. Duas ocorrências
apanhadas em 12 runs, **as duas no mesmo sítio**: x≈1990, y≈635 — em cima da
`CorrenteC`, a plataforma-corrente horizontal do N06 (x=1970).

Sonda por etapas dentro de `koliani.gd::_physics_process` (temporária,
removida depois) deu a etapa exacta nas duas: **`pos_move`**. Ou seja o NaN
sai do próprio `move_and_slide()`, com velocidade **e** posição **finitas à
entrada**.

### Causa (provada, não inferida)

`_hitstop()` punha `Engine.time_scale = 0.0`. O Godot chama
`PhysicsServer2D.step(physics_step * time_scale)`, portanto o passo de física
ia a **zero**; e a integração de um corpo cinemático (`AnimatableBody2D` com
`sync_to_physics`) calcula-lhe a velocidade por `linear_velocity = motion /
passo`. Parada e com passo zero isso é **0/0 = NaN**. Quem estiver **em
cima** lê essa velocidade em `move_and_slide()` (velocidade da plataforma) e
sai de lá com `global_position` e `velocity` a NaN.

No N06 há um `chort` a 110 px da `CorrenteC`: bastava um acerto com a Koliani
em cima da laje.

**Isto não era um defeito da Região II.** Valia para as nove plataformas
`AnimatableBody2D` do jogo: `PlataformaCorrente`, `PlataformaFlutuante`,
`PlataformaPeso`, `PlataformaRoda`, `ParedeMovel`, `TumuloElevador`,
`RaizElevatoria`, `Ariete` e a `RaizElevatoria` de `A_Arvore_que_Chora`.

### Hipóteses DESCARTADAS (para não se voltarem a pagar)

- **Vectores de vento / normalização de vector zero.** `Vector2.normalized()`
  devolve `(0,0)` para comprimento zero em Godot — não dá NaN. E uma das duas
  ocorrências tinha `ventos_activos = 0`.
- **`aplicar_forca_externa` / `Movimento.passo`.** A sonda `pre_move` nunca
  disparou: a velocidade entrava finita.
- **Divisão por `delta`.** Todas as divisões por tempo em `koliani.gd` já têm
  `maxf(..., 0.001)`.
- **Escala zero num nó.** A Koliani nunca mexe no `scale` do próprio corpo,
  só no do `Sprite` e do `_hitbox`.
- **Knockback / respawn / declives.** Nenhum activo no frame apanhado.

### Correcção

`Koliani.HITSTOP_ESCALA_TEMPO = 0.0005` em vez de `0.0`. Congela o jogo na
prática (uma paragem de 24 ms deixa passar 0,012 ms de jogo) e mantém o passo
de física diferente de zero, que é o que a divisão precisa. O
`Engine.time_scale < 0.5` que marca "estou em hitstop" continua verdadeiro,
portanto `bench_combate.gd` e `verifica_hitstop.gd` não mudam.

### Prova

- `teste_gate1_hitstop_nao_gera_nan` (em `tests/run_tests.gd`) monta o caso
  mínimo: plataforma-corrente + Koliani em cima + a escala de tempo do
  hitstop. Com o valor antigo (`0.0`) **falha nas três asserções com
  `(nan, nan)`**; com `0.0005` passa. É determinístico.
- 15 runs do bot (N06-N10, 3 perfis, 900 s cada): **0 frames** com posição ou
  velocidade NaN.
- Suite completa verde, save real intacto por SHA256.

Commit: `84b409e9` — *fix: prevent region02 invalid player motion state*.

---

## GATE 2 — o pico de mortes do N10

### Números de partida

200,7 mortes/1000 px contra 4,7-23,8 nos outros quatro níveis (40x), com
**58,8 de dano médio por run** contra 3465-6604: o nível não feria,
executava. 76% das mortes num único ponto (x≈700), 99% na faixa x=600-820,
todas na superfície do ácido (y=920). Confirmado nesta execução com runs
próprias: 76,5% em x≈700.

### Causa

**Não é o salto.** Com salto duplo a envolvente (`gerador_corredor.vao_possivel`)
dá 195 px de vão para uma subida de 80 px, e o vão `L1`→`R1` são 70 px.

É a **consequência**, e são duas coisas:

1. a `RajadaFavor` cobria x 180-620 e o `ChaoInicio` acaba em x=540 — 80 px
   de vento por cima do vazio, a empurrar para uma queda mortal antes de
   haver onde pousar;
2. por baixo do ziguezague inteiro só havia ácido (`AguaVenenosa` com
   `dano = 999`), portanto falhar um salto a meio de uma subida de 570 px era
   morte instantânea de vida cheia.

### Correcção

1. a rajada acaba onde o chão acaba (x 180-540). O impulso de corrida fica
   inteiro;
2. `ChaoResgate` — laje x 540-880, topo y=850, encostada ao `ChaoInicio`, a
   cobrir a faixa das mortes com folga.

**Não fecha o poço todo, de propósito.** De x=880 para a direita o ácido
continua vivo, e é para lá que cai quem falha a subida ALTA (`RR2`,
`SubidaDir1/2`) — que já está depois do `CheckMeio` (660,516), portanto
morrer lá custa pouco. A torre continua a ser uma torre de onde se cai.

### Tentativas DESCARTADAS (medidas, não opinadas)

| laje | resultado |
|---|---|
| **260 px** (x 600-860) | o aglomerado **mudou-se** para a ponta direita dela: 73,5% das mortes em x≈900. Só muda a borda de sítio. |
| **580 px** (x 540-1120) | apagou as mortes todas (0) **mas virou um atractor de navegação** no fundo do poço: o bot passou a **subir menos** (204 px contra 497) e **nenhuma run voltou a chegar ao chefe**. Um chão largo debaixo de uma subida vertical convida a andar em vez de subir. |
| **340 px** (x 540-880) | **a escolhida** — ver abaixo. |

### Medido (6 runs por variante, 900 s, 3 perfis)

| | mortes | mortes/1000 px | pico num só ponto | subiu | chegou ao chefe |
|---|---:|---:|---:|---:|---:|
| antes | 345 | 164-273 | **77,4%** (x≈700) | 204-497 px | 2/3 runs |
| depois | **72** | **0-31** | **51,4%** (x≈1000) | 204-497 px | 3/6 runs |

O aglomerado de x≈700 **desapareceu** (0 mortes). O que sobra são quedas da
subida alta (x 900-1000, y≈900), depois do checkpoint do meio, e o pico é
**8x mais baixo em absoluto** (37 contra 267). A mortalidade fica na ordem do
N08 (23,8/1000 px): o N10 continua o mais exigente da região sem ser um pico
de outra ordem de grandeza.

### Limite honesto

O bot continua a **não lutar o Guardião de forma válida** (1-11 s de combate)
e encrava 186-306 vezes por run na subida. Isso é limite do bot, já registado
no playtest anterior, e **não prova nada sobre o combate**.

`x_max` não mede progresso num poço vertical. O bot passou a gravar também
`y_min`/`y_spawn` (ponto mais alto atingido) — é esse o número que vale no
N10.

Commit: `5187b52c` — *fix: rebalance region02 finale approach hazard*.

---

## Art safety — a rede que fica montada

`docs/playtests/region_02_visual_evidence_after/geometria_gameplay_base.json`
é a fotografia da geometria de jogo **depois** do GATE 2, tirada com
`tools/geometria_regiao02.tscn`. O passe de arte (Fase 4) tem de provar
**0 alterações** contra ela:

```bash
godot --headless --path . res://tools/geometria_regiao02.tscn -- \
  comparar /caminho/geometria_gameplay_base.json     # sai != 0 se mexeu
```

---

## Fase 3 — bestiário canónico  (`74b487e8`)

Censo medido com `tools/recon_r2.gd` **no nível já construído** (a jornada é
gerada em runtime, ler o `.tscn` não chega):

| | antes | depois |
|---|---|---|
| N06 | esqueleto 3 · chort 2 · imp 2 · orc 2 · mastim 1 — **0/10** | **10/10 canónicos** |
| N07 | imp 9 · mastim 2 · chort 1 · esqueleto 1 — **0/10** | **13/13** |
| N08 | chort 1 — **0/10** | **1/1** |
| N09 | mastim 5 · orc 3 · chort 2 · esqueleto 2 — **0/10** | **12/12** |
| N10 | orc 1 — **0/10** | **1/1** |

*(o `goblin` que o censo mostra é o CHEFE: `ChefeBase` herda de `DemonioBase`
e fica com a `especie` por omissão. Já estava assim antes.)*

Cinco espécies, recortadas da prancha aprovada por
`tools/extrair_inimigos_regiao02.py`: `morcego_dos_ventos`,
`sentinela_flutuante`, `gaivota_sombria`, `golem_aereo`,
`elemental_do_vento`. Todas voam, levitam ou **são** vento.

**Cinco das dez, e porquê** — o plano de cada painel da prancha não é o
mesmo, e isso descobriu-se a olhar para eles:

- MORCEGO, GAIVOTA e GOLEM têm a criatura na linha de estados, com os cinco
  estados nomeados: são os casos limpos;
- a SENTINELA tem na linha de estados o **projéctil** (orbes violeta), não a
  criatura — essa só existe na linha de conceito, em três poses;
- o ELEMENTAL tem três espirais para quatro legendas (são largas e
  sobrepõem-se); três chegam, é uma forma etérea;
- o MAGO DO VENTO tem a linha de estados quase toda em glifos e as quatro
  figuras do conceito coladas: **não há corte honesto**. Fica de fora e não
  faz falta — a Feiticeira dos Ventos (N08) já É o arquétipo `MAGO DO VENTO`;
- SERPENTE, ESPECTRO, ARQUEIRO e TORRE VIGIA ficam por fazer; o Espectro e a
  Torre Vigia já existem como guardiões (N09 e N07).

**`attack.png` é novo.** O `_estado_anim` do `demonio_base.gd` já pedia
`"attack"` no telégrafo (`_tem_anim("attack")`) desde sempre — o que nunca
existiu foi quem a montasse. Agora as poses INVESTIDA / MERGULHO / ATAQUE da
prancha são mesmo as que se veem antes do golpe.

---

## Fases 4 e 5 — ambiente, props e o Guardião

### Paleta proibida no Guardião  (`a74152ec`)

L3 do contrato proíbe por escrito "a paleta ciano/branco-gelo do
`monge_celeste` (`#a8ebff`)". Estava em **cinco** sítios, não só no que o
audit apanhou: o projéctil das PENAS CORTANTES, a luz dele, o pó das garras,
o tom do rig na fase 2 e o rebentamento da fase 2. O rig tinha sido
redesenhado para violeta-índigo e os **ataques ficaram com a paleta do rig
antigo**.

O projéctil deixa de ser um losango: o painel `2. PENAS CORTANTES` desenha
lâminas EMPLUMADAS (ponta violeta acesa, haste índigo, barbas carmesim a
arrastar) e é isso que `_montar_pena()` monta, em cinco camadas. **Só o
desenho muda** — mesma colisão (círculo r=9) e mesma `LAMINA_VEL`.

Travado por `_paleta_do_guardiao()` em `test_region02_n10_level.gd`, que lê
todos os `Color(...)` do script e rejeita a família gelo. Provado: reposta a
cor antiga, o teste falha.

### Mar de nuvens  (`a74152ec`)

`nuvens.png` foi pintada a **51,9%** de luminância e chegava ao ecrã a
10-24%. Não faltava asset: a camada "Meio" leva `_gradacao` +
`dessaturar_fundo` + o `CanvasModulate` do bioma, e as três comiam-lhe dois
terços do brilho.

A tabela `PACKS` passa a aceitar um 5.º campo por camada — um ganho de
brilho. Por camada e não pela região toda: clarear o `cor_ambiente` lavava o
terreno e os inimigos junto com o céu.

**Armadilha que custou duas tentativas:** o ganho NÃO pode ir dobrado na
`tinta` do `fundo_bioma.gdshader`. Essa uniform é `source_color`, portanto
fica **grampeada a 1.0** — a primeira versão subiu o mar de nuvens 11% em vez
dos 60% pedidos. Vai em uniform própria (`ganho`, float simples).

Medido no jogo real, mesmo ponto de câmara (o p99 é onde vivem os realces):

| | média | p90 | p99 |
|---|---|---|---|
| N06 | 16.5→19.7 | 29.8→42.1 | 52.8→68.2 |
| N07 | 15.3→18.0 | 30.7→33.8 | 44.1→60.9 |
| N08 | 16.1→17.8 | 24.6→28.8 | 39.3→57.3 |
| N09 | 15.6→18.5 | 27.4→37.5 | 47.8→62.6 |
| N10 | 16.5→20.2 | 26.5→37.2 | 51.7→66.5 |

*(medido com ganho 2.1; baixado depois para 1.7/1.12 porque a 2.1 o N06
ficava LAVADO — as serras distantes passavam de manchas pretas a montanhas
lavanda claras e o nível perdia o contraste gótico do `key_art`.)*

### Props canónicos  (`cbf640bf`)

O catálogo dava 12 props ao `desfiladeiro` e eram os de `torres` copiados —
e a linha que os copiava estava em `gerar_terreno_regiao02.py`:
`cat["desfiladeiro"] = cat["torres"]`. Era **a origem exacta do achado** e
uma bomba-relógio para este passe: bastava correr o script e os props
canónicos desapareciam. Corrigido em `77b4c891`.

`tools/extrair_props_regiao02.py` recorta 16 props da prancha: estátua,
bandeira (carmesim, com cruz), correntes, gárgula, lanterna, gaiola, coluna,
arco, janela, escombros, vitral, pedras, cristais, vegetação alta e baixa,
árvore seca. **`desfiladeiro` passa de 12 props (3 de chão) a 25 (8 de
chão)**, e `cruz`, `lapide` e `flamula` saem.

Cada prop de chão leva altura própria, e não é estética: na primeira
passagem ficaram duas pedras de 109 px a fazer de **pilares** ao lado da
Koliani, que tem 65.

### Fundo do abismo  (`cbf640bf`)

"O elemento com mais ar de placeholder" do audit. Mas o fundo do
Desfiladeiro não é uma poça: é o mar de nuvens. A `superficie_textura` do
`agua_venenosa.gd` (existia desde 9H.12D, nunca usada fora do L1) recebe a
mesma `nuvens.png` do parallax.

Não chegou à primeira nem à segunda. Daí dois `@export` novos, ambos com
omissão igual ao que existia:
- `veu_forca` (2.6 aqui, 1.0 no pântano e na lava) — os véus entram a 12-20%
  de alfa e sobre uma banda escura não se viam;
- `veu_origem` (0.5 aqui) — o `region_rect` amostrava de y=0 e a
  `nuvens.png` tem o **céu escuro** no topo: o véu trazia céu, ou seja nada.

### Folhagem no terreno  (`77b4c891`)

O "maior desvio visual" do audit. A `topo.png` passa a levar tufos carmesins
no lábio, feitos das `vegetacao_*` da prancha. As 8 primeiras linhas da
textura caem ACIMA da linha onde se pisa (`plataforma.gd` desenha a capa a
partir de `y0 - SUPERFICIE`) — é nessas que a folhagem vive. A tira é um
mosaico de 96 px, portanto quem cruza a borda é carimbado também do outro
lado.

### As asas do Guardião  (`8c59be26`)

O único critério que o próprio contrato nomeia (L1: a silhueta define-se
"sobretudo pelas ASAS"). O audit media asas espalmadas ao nível do corpo; a
criatura lia-se como ave POUSADA.

**Porque é que estava assim:** a versão anterior tinha asas curtas (24/21) e
arco a -48, que no plano `ave` é para BAIXO. Não foi capricho — uma
tentativa de envergadura larga saiu com rácio 2,03 e 324 px de largo contra
os 560 px da plataforma, e a suite apanhou-a. **O erro foi alargar sem
LEVANTAR.** Levantar troca largura por altura, e como o jogo escala o chefe
pela ALTURA, a largura em jogo cai com o rácio. Medido, sete combinações:

| arco | asa | bbox | rácio | largura em jogo |
|---|---|---|---|---|
| -48 | 24/21 | 232x162 | 1.43 | 229 px = 3.53x (a de antes) |
| -30 | 24/21 | 252x162 | 1.56 | 249 px = 3.83x — fora por cima |
| 12 | 30/27 | 276x200 | 1.38 | 221 px = 3.40x — fora por baixo |
| **12** | **34/30** | **306x210** | **1.46** | **233 px = 3.59x** ← escolhida |
| 16 | 38/34 | 328x232 | 1.41 | 226 px = 3.48x — no limite |
| 25 | 28/25 | 224x212 | 1.06 | 169 px = 2.60x |
| 40 | 30/26 | 184x234 | 0.79 | 126 px = 1.94x |

Asas erguidas (+12) **e** 40% mais longas (34/30): 3,59x em largura (banda
3,5-3,7 de L2) e 2,46x em altura (banda 2,34-2,86). Na arena ocupa 42% da
plataforma — o mesmo de antes.

Também: a cabeça passa à FRENTE da asa da frente (`Z_CABECA` = 3.6). Com as
asas erguidas o ombro de cá cruzava a cabeça e o bico dourado desaparecia.

**Combate não tocado:** `run_boss_guardiao_ceus.tscn` passa; timings, vida,
janela EXPOSTO e os três ataques ficam como estavam.

---

## Fase 7 — 30 runs do bot, depois de tudo

2 casual + 2 normal + 2 experiente por nível, 900 s cada.
Dados: `docs/playtests/region_02_visual_evidence_after/bot_r2_depois_dados.json`.

| nível | mortes/1000 px ANTES | DEPOIS |
|---|---:|---:|
| N06 | 6.25 | 6.94 |
| N07 | 4.87 | 5.58 |
| N08 | 23.76 | 24.20 |
| N09 | 4.70 | 5.71 |
| **N10** | **200.65** | **18.45** |

A curva da região deixa de ter um pico de outra ordem de grandeza:
**6.9 · 5.6 · 24.2 · 5.7 · 18.5**. O N10 continua dos mais exigentes, na
ordem do N08, sem ser 40x os vizinhos.

Outros números:
- **0 frames** com posição ou velocidade NaN em 30 runs (antes: ~1 em cada
  4 runs do N06);
- o N10 passou a **ferir**: dano médio por run 58,8 → **214**; o nível
  deixou de executar;
- progresso do N10: **100% em todos os perfis** (antes 93,8-100%);
- o bot **completou um nível** pela primeira vez (uma run do N07);
- o aglomerado mais forte da região é agora o N09 com 62,7% num ponto — e
  esse ponto é a **arena do chefe**, que é onde as mortes devem estar. O do
  N10 é 49,4% com 89 mortes em 6 runs (antes: 1256 em 9).

**Limite honesto, igual ao do audit:** o bot continua a não lutar o Guardião
de forma válida (7,3 s de combate em média). Os números de **traversal**
valem; os de **combate** não.

---

## Fase 6 — re-audit visual

19 fotografias novas, mesma metodologia e mesmas referências, em
`docs/playtests/region_02_visual_evidence_after/reaudit/`.

| | antes | depois | porquê |
|---|---|---|---|
| N06 | LOW | **MEDIUM-HIGH** | folhagem carmesim nas bordas, estátuas, gárgulas, cristais, bandeiras carmesins, mar de nuvens visível, bestiário canónico |
| N07 | MEDIUM | **HIGH** | a mecânica-assinatura já era a melhor da região; agora o cenário à volta dela também é |
| N08 | MEDIUM | **HIGH** | ilhas sobre nuvens legíveis, vitrais, vegetação |
| N09 | LOW | **MEDIUM-HIGH** | a paleta já acertava; ganhou props, folhagem, profundidade e inimigos do ar |
| N10 (arena) | LOW | **MEDIUM** | 6 dos 8 elementos do painel ARENA (nuvens, correntes, braseiros, colunas, cristais, estandartes); falta a lua de sangue e as torres góticas são silhueta |

| Encontro | antes | depois |
|---|---|---|
| Golem das Falésias | LOW | LOW *(não tocado)* |
| Vigia do Desfiladeiro | MEDIUM | MEDIUM *(não tocado)* |
| Feiticeira dos Ventos | MEDIUM | MEDIUM *(não tocado)* |
| Espectros Gémeos | MEDIUM | MEDIUM *(não tocado)* |
| **Guardião dos Céus** | MEDIUM (rig) · LOW (chefe+arena) | **HIGH (rig)** · **MEDIUM-HIGH (chefe+arena)** |

**Não declaro vitória onde não a há:** os quatro guardiões intermédios não
foram tocados nesta execução. O que mudou à volta deles (cenário, props,
inimigos) melhora a leitura da região, não a fidelidade deles.

---

## Fase 9 — build Windows

`builds/region02-final/` (fora do Git, como manda o processo):
`Koliani-Region02-Final-Test.exe` (197 MB), `Jogar-N06/07/08/09.bat`,
`Jogar-N10-Guardiao.bat`, `Jogar-do-Menu.bat` e `LEIA-ME.txt`.

**Save isolado:** os `.bat` apontam o `%APPDATA%` a `save-isolado` ao lado do
executável — o Godot resolve o `user://` por aí, portanto a campanha do
Paulo não é tocada. Quem abrir o `.exe` directamente escreve no save normal;
o LEIA-ME avisa.

**ATENÇÃO:** esta build foi feita e verificada num contentor EFÉMERO. Para o
Paulo lhe chegar, ou corre o mesmo export na máquina dele, ou vai buscá-la ao
CI — o `.github/workflows/ci.yml` corre em **cada push** e produz o Windows.

---

## O que falta

**Para fechar o Super-Process A2:**

1. **Relatório final** no formato pedido pelo briefing (a secção
   `KOLIANI — EXECUTION REPORT`). Os números todos estão neste documento.
2. **Varredura dos harnesses avulso** — a suite (`run_tests.tscn`) está
   verde e o `run_boss_guardiao_ceus.tscn` também, mas faltou correr um a um:
   `run_movement_camera_4a`, `run_wind_system`, `run_glide_region02`,
   `run_region02_wind_shapes`, `run_level_session_tests`,
   `run_save_foundation_tests`, `run_progression_ids_tests`.

**Ficou por fazer, e é decisão do Paulo:**

3. **A lua de sangue.** Continua sem entrar no enquadramento. Está desenhada
   na `ceu.png` mas essa camada é aplicada a 320 px de altura e o disco fica
   no topo, muito acima da câmara. Tentou-se localizá-la por cor para a
   recortar e **não sai limpa** — o `realcar_lua` do
   `gerar_fundos_regiao02.py` tinge-a e ela deixa de se distinguir do céu.
   O caminho certo é um elemento PRÓPRIO na camada `Ceu` do `atmosfera.gd`
   (essa camada tem `motion_scale = 0`, ou seja fica fixa à câmara — é
   exactamente o que uma lua dominante precisa). Era prioridade BAIXA (#15)
   no audit.
4. **Os quatro guardiões intermédios** (Golem LOW, Vigia MEDIUM, Feiticeira
   MEDIUM, Espectros MEDIUM). Não foram tocados. O Vigia continua a
   CAMINHAR, e a `TORRE VIGIA` da prancha é uma estrutura fixa.
5. **As outras cinco criaturas canónicas** (serpente eólica, espectro das
   ruínas, arqueiro eólico, torre vigia, mago do vento como inimigo comum).
6. **O N10 ficou fácil demais?** 200,7 → 18,5 mortes/1000 px. O alvo era a
   ordem do N08 (24,2) e cumpriu-se, mas quem decide se o exame final quer
   mais mordida é o Paulo, no playtest humano. A laje `ChaoResgate` cobre
   x 540-880 e o comentário na cena tem as três variantes medidas.
7. **Contraste.** O mar de nuvens foi clareado de propósito. Se algum nível
   parecer LAVADO no playtest humano, o botão é o 5.º campo da tabela
   `PACKS` em `atmosfera.gd`.

---

## Como retomar (ambiente)

Nada disto sobrevive ao contentor:

```bash
# 1. o motor (nao vem no contentor)
curl -sSL -o /tmp/g.zip \
  https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip -q /tmp/g.zip -d /tmp/godot && chmod +x /tmp/godot/Godot_v4.7.2-stable_linux.x86_64

# 2. os export templates (so' para a build Windows, ~800 MB)
curl -sSL -o /tmp/t.tpz \
  https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
unzip -q /tmp/t.tpz -d /tmp/t && mkdir -p ~/.local/share/godot/export_templates \
  && mv /tmp/t/templates ~/.local/share/godot/export_templates/4.7.2.stable

# 3. reimportar SEMPRE depois de mexer em assets
/tmp/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --import

# 4. a suite, com o user:// isolado (equivalente Linux do correr_testes.ps1)
SB=$(mktemp -d); XDG_DATA_HOME="$SB" \
  /tmp/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . res://tests/run_tests.tscn

# 5. fotografias (precisam de Xvfb + OpenGL3)
XDG_DATA_HOME=$(mktemp -d) xvfb-run -a --server-args="-screen 0 1280x720x24" \
  /tmp/godot/Godot_v4.7.2-stable_linux.x86_64 --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script res://tools/shot_r2.gd -- <cena> <pasta> <prefixo> "nome@x,y" 1.5

# 6. art safety: 0 alteracoes de gameplay
XDG_DATA_HOME=$(mktemp -d) /tmp/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . \
  res://tools/geometria_regiao02.tscn -- comparar \
  $PWD/docs/playtests/region_02_visual_evidence_after/geometria_gameplay_base.json

# 7. build Windows
/tmp/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . \
  --export-release "Windows Desktop" $PWD/builds/region02-final/Koliani-Region02-Final-Test.exe
# (SEM XDG_DATA_HOME sandboxed -- senao o Godot nao encontra os templates)
```

**A build de Windows nao esta' no Git** (`/builds/` e' ignorado) e o
contentor e' efemero. O `.github/workflows/ci.yml` corre em cada push e
produz o Windows: e' por ai' que ela chega ao Paulo.

---

## Commits desta execução

```
77b4c891 art: folhagem carmesim no terreno, e o tool deixa de apagar os props
8c59be26 art: o Guardiao dos Ceus com as asas abertas da prancha
cbf640bf art: props canonicos e mar de nuvens no fundo do Desfiladeiro
a74152ec art: paleta do contrato no Guardiao e mar de nuvens de volta
74b487e8 feat: bestiario canonico da Regiao II, recortado da prancha aprovada
bbb5862d chore: metadados de import que faltavam + ignorar traducoes compiladas
1ae59868 docs: plano atual -- estado fase a fase do Super-Process A2
206519a2 docs: estado do Super-Process A2 apos os GATES 1 e 2
5187b52c fix: rebalance region02 finale approach hazard   (GATE 2)
84b409e9 fix: prevent region02 invalid player motion state (GATE 1)
```
