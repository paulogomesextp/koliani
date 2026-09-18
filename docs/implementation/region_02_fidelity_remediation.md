# Região II — Fidelity & Playability Remediation (Super-Process A2)

**Estado: PARCIAL — interrompido por limite de uso a meio da Fase 3.**
**Data:** 18 set 2026
**Base:** `claude/region02-humanlike-bot-playtest` @ `1bfda76f`
**Branch:** `claude/region02-fidelity-remediation`
**Feito e provado:** GATE 1 (NaN do N06) e GATE 2 (pico de mortes do N10).
**Por fazer:** Fases 3 a 9 (inimigos canónicos, ambiente, Guardião, arena,
re-audit, re-run do bot, build Windows).

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

## O que falta (Fases 3 a 9)

Nada disto foi começado. Continua tudo válido como estava no audit:

3. **Inimigos canónicos.** `ESP_REGIAO[1]` em `scripts/gerador_corredor.gd`
   ainda diz `# II Prisão` e lista `esqueleto, chort, orc, imp, mastim`.
   0 dos 10 inimigos canónicos da prancha em N06-N10. `abutre` e `olho` já
   existem com arte completa e já estão em `ESPECIES_VOAM`.
4. **Guardiões N06-N09** (Golem LOW, Vigia MEDIUM, Feiticeira MEDIUM,
   Espectros MEDIUM).
5. **Ambiente N06-N10**: terreno sem vegetação carmesim, mar de nuvens a
   10-24% de luminância contra 53% na origem, bandeira lavanda em vez de
   carmesim, banda do abismo com ar de placeholder, 3 props de chão (dois de
   cemitério).
6. **Guardião dos Céus**: asas espalmadas (a prancha define a leitura pelas
   asas abertas); projéctil das PENAS CORTANTES em `#B8EBFF`
   (`scripts/chefe_guardiao_dos_ceus.gd:399`), que o contrato **proíbe**.
7. **Arena do N10**: 0 dos 8 elementos do painel `ARENA` do `boss_pack`.
8. Re-audit visual, re-run do bot (mín. 30 runs), build Windows.

**Achado novo desta execução, a ter em conta na Fase 4:** nas fotografias do
N10 o ácido é **quase invisível** — uma onda de ameixa escura sobre fundo
preto. Um perigo que mata de vida cheia e não se lê é metade da injustiça que
o GATE 2 corrigiu; a outra metade resolve-se a clarear a banda do abismo,
que já estava na lista como "elemento com mais ar de placeholder".
