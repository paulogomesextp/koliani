# Execution 9H.18 — a corrida e os SFX

Dois problemas nomeados pelo Game Master depois de jogar a build:
a Koliani não corre, desliza; e os sons continuam maus — no menu e em jogo.

Ramo `codex/9h16-l1-perfection`. Commits `27fc583f` (corrida), `673a2c6f`
(SFX), mais o de documentação e build.

---

## Phase A — a corrida

### O que se procurou

Todas as fontes de corrida da Koliani no repositório: os sete rigs em
`assets/sprites/pixel/koliani*`, a folha Golden Set, `work/production_art_gate/`
(incluindo os candidatos da 9H.15), o `Koliani_1.0_Master_Package_v2`, o
histórico de git e os 15 ramos. Não há mais nenhuma.

### O crivo, e porque é este

`tools/validar_run_nativo_9h18.py`.

Medir a **abertura das pernas** não distingue nada — um ciclo de uma perna
abre e fecha na mesma, e foi por isso que a 9H.13 se enganou a acreditar que
bastava mexer na cadência. O que separa uma corrida de um arrasto é o
**varrimento de cada perna**: nos frames de contacto seguem-se o pé de trás
e o da frente e mede-se o chão que cada um percorre ao longo do ciclo. Numa
corrida a sério os dois percorrem mais ou menos o mesmo — é o mesmo
movimento desfasado de meio ciclo.

| fonte | frames | contactos | pé de trás | pé da frente | razão | veredito |
|---|---|---|---|---|---|---|
| **`koliani_golden_set/frames/run`** (o que o jogo usa em L1–L5) | 10 | 4/10 (40%) | **7 px** | 29 px | **0,24** | REPROVA |
| `koliani_visual_pilot_5g/run.png` | 12 | 11/12 (92%) | 22 px | 20 px | 0,91 | passa — **mas é outra Koliani** |
| `9H15_koliani_run/frames` | 8 | 2/8 (25%) | 2 px | 2 px | — | REPROVA |
| `koliani_nova/run.png` | 12 | 6/12 (50%) | 9 px | 7 px | 0,78 | REPROVA |
| `koliani_shadowblade/run.png` | 5 | 2/5 (40%) | 3 px | 2 px | — | REPROVA |

Medido à parte, os pés em x relativo à anca ao longo dos 10 frames golden:
um vive entre −26 e −2 (sempre atrás) e o outro entre +13 e +27 (sempre à
frente). **Nenhum dos dois atravessa a anca em frame nenhum.** A pose que
falta — o contacto do outro pé — não está desenhada.

### Porque é que nenhuma das outras serve

O **piloto 5G** é o único que passa, e passa bem. Mas é o desenho anterior
ao Golden: cabelo roxo, saia de chama, sem o lenço vermelho. O pedido era
uma corrida melhor, não outra Koliani.

O **master package** tem uma linha `RUN (12 FRAMES)` em
`05_KOLIANI_IDLE_RUN_CLEAN_v1_1.png`, que a própria manifesta do Golden cita
como autoridade — mas é uma folha de apresentação (xadrez pintado em RGB,
sem alfa verdadeiro) e é o mesmo desenho anterior ao Golden. Extrair dali
dava uma Koliani diferente com bordos sujos.

Os **candidatos da 9H.15** já vinham marcados `REJECTED_FOR_PRODUCTION` pela
execução que os fez. Confirmado com o crivo: 2 px de varrimento.

### Veredito: KOLIANI RUN — NATIVE ART REQUIRED

O que fica preparado para a arte entrar sem mais uma execução:

- **`docs/spec_run_nativo_koliani.md`** — a prova, as fontes descartadas com
  o porquê, o contrato do ficheiro (10 frames 128×128 RGBA, pivô 64/104,
  base y=103 igual em todos, virada à direita, ciclo 0,75 s) e as seis
  poses obrigatórias do ciclo;
- **`koliani.gd::_substituir_run_por_nativo()`** — se a pasta
  `assets/sprites/koliani_golden_set/frames/run_native/` existir, é ela que
  manda, com o `fps` recalculado para o ciclo continuar a dar 0,75 s. O
  `turn`, o `run_start` e o `run_brake` passam a sair da tira nova e a
  cadência por velocidade da 9H.13 continua a pegar. Sem a pasta, nada muda.

Não se usou `speed_scale`, espelho, esticão, desfocagem nem partículas a
tapar. Nenhum deles cria a pose que falta.

### Armadilha de método

A `Koliani.tscn` em bruto **não** vem com o Golden Set — cai no rig
`shadowblade` (5 frames de corrida, que reprova ainda pior). O Golden é
ligado nível a nível. Fotografar a cena em bruto fotografa o rig errado, e
foi o que aconteceu à primeira com o `tools/ShotCorrida9H18.tscn`.

---

## Phase B — os SFX

### Porque é que as duas passagens anteriores não chegaram

A 9H.13B já tinha resolvido a **sonoridade** (normalizar por energia e não
por pico) e mesmo assim o Game Master disse que os sons continuavam maus.
Faltava medir a **forma**. `tools/auditar_sfx_9h18.py` mede tempo até ao
pico, cauda até −40 dB, crista e repartição por bandas. O que apareceu:

| evento | antes | o problema |
|---|---|---|
| `ui_mover` | 160 ms, cauda 109 ms | um tique de navegação que se arrasta; a rolar a lista as caudas empilham-se |
| `ui_confirmar` | 560 ms, cauda 417 ms | meio segundo para confirmar |
| `carrossel` | pico aos **136 ms** | um clique cujo pico chega 136 ms depois do carregar não é um clique |
| `porta` | 1000 ms, pico aos 236 ms | |
| `ataque_forte` | pico aos **70 ms** | o remate do combo chega tarde ao golpe |
| `ataque` vs `acerto` | 15/75/11 % vs 20/64/16 % | **golpear e acertar tinham o mesmo timbre** |
| `passo1/2/3` | 78/20/2, 73/25/2, 67/29/3 | três "variações" que eram o mesmo som |

Nada disto se vê numa tabela de sonoridade — foi por isso que as passagens
anteriores se deram por boas.

### O que se fez

`tools/gerar_sfx_9h18.py` refaz **22 ficheiros** com **alvos de forma por
evento** e verifica-se a si próprio: imprime PASSA/FALHA por som e sai != 0
se algum ficar fora. Os 22 passam.

O motor (herdado da 9H.13) ganhou o que lhe faltava:

- **filtro ressonante** (variável de estado) — textura, não só abafamento;
- **objecto percutido** com modos inarmónicos e decaimento por modo — é a
  diferença entre madeira e bip;
- **grão** — cascalho debaixo da bota, estilhaço no impacto.

| | antes | depois |
|---|---|---|
| `ui_mover` | 160 ms / cauda 109 | **55 ms / cauda 36**, madeira escura |
| `ui_confirmar` | 560 / 417 | **230 / 203**, metal batido com abafador |
| `carrossel` | pico aos 136 ms | **pico aos 0 ms**, 75 ms |
| `ataque_forte` | pico aos 70 ms | **pico aos 0 ms** |
| `ataque` | 15/75/11 | **4/46/50** — ar e fio |
| `acerto` | 20/64/16 | **43/43/14** — impacto |
| `passo1/2/3` | quase iguais | madeiras, grão e modos próprios |

Os alvos de banda do golpe e do acerto **não se sobrepõem, de propósito**:
falhar e acertar têm de soar diferente.

### Duas coisas que custaram a descobrir

1. **Um único fluxo de aleatório fazia os ficheiros mudarem uns com os
   outros.** Mexer no `acerto` deslocava o ruído do `ataque` e as medidas
   variavam sozinhas entre corridas (o `ataque` andava entre 58% e 59% de
   agudo consoante o que se tinha gerado antes). Agora cada ficheiro tem
   semente própria, por `zlib.crc32` — `hash()` de string em Python é
   aleatorizado por processo e não servia.
2. **O grão espalhado por igual punha o pico do som a 10–18 ms do início.**
   O `acerto` e o `passo` chegavam tarde. Passou a ser denso no impacto e
   ralo depois — que também é o que o cascalho faz de verdade.

### Mobile-first é que manda no tecto de grave

Um altifalante de telemóvel não reproduz quase nada abaixo de 300 Hz. Um som
com 80% da energia em grave é energia que o jogador nunca ouve — soa a nada
e parece fraco, por muito "peso" que tenha no papel. Vários sons subiram o
fundamental para a fronteira dos 250 Hz em vez de ficarem graves na medida.

### Variação (B8)

`ui_mover` e `acerto` — os dois eventos mais repetidos do jogo — saem em
**três amostras mesmo diferentes** e o `Som.toca()` sorteia sem repetir a
anterior de seguida. Nenhum dos dezenas de sítios que os chamam precisou de
mudar. Um `pitch_scale` de ±5% não chega para esconder que é a mesma forma
de onda a disparar vinte vezes, e a repetição é metade do que se ouve como
"som barato".

### Mistura (B9) — não se mexeu

Buses `Master` / `Music` / `SFX`, criados pelo `default_bus_layout.tres` e
mapeados pelo autoload `Opcoes`. O `opcoes.json` da máquina do Game Master
tem `vol_efeitos` 0,40 e `vol_musica` 0,45 — escolhas dele, e continuam a
mandar. Nenhum ficheiro passa de −0,5 dBFS de pico e não há amostras
encostadas ao fundo de escala em nenhum dos 22.

### QA técnica (B10)

- 79 chaves no catálogo do `Som`, **zero ficheiros em falta**;
- **zero eventos chamados sem entrada no catálogo** (as 21 chaves `mob_*`
  que parecem não ser chamadas são montadas por nome — `"mob_%s_%s"`);
- **zero disparos duplicados** encontrados;
- **áudio legado presente mas inerte**: 13 `.ogg` que foram substituídos
  pelos `.wav` e que o catálogo já não aponta — `acerto`, `ataque`,
  `ataque_forte`, `bloqueio`, `dano`, `dash`, `morte_koliani`, `passo1..3`,
  `rolamento`, `selo`, `agarrar`. Ficam no repo, sem serem carregados.
  (`ambiente*.wav`, `boss.wav`, `menu.wav`, `assombracao.wav`,
  `game_over.wav` não são órfãos: são camas do autoload `Musica`.)

### Sons que NÃO foram refeitos nesta passagem

`porta` (1000 ms, pico aos 236 ms), `transicao`, `apanhar`, `selo`,
`conquista`, `projetil`, `investida`, `chefe_cai`, `dano`, `bloqueio`,
`morte_koliani`, `raiz_*`, `plataforma_surge` e os 21 `mob_*`. Estão
auditados e a tabela está acima; ficaram de fora por prioridade — o Game
Master nomeou o menu e o combate.

---

## Phase C — como o Game Master ouve isto

Teclado de sons no **modo Dev**, tecla **S** (`scripts/dev_sons.gd`). Põe os
~40 eventos a um toque, agrupados como se ouvem no jogo, e **com os volumes
e tons reais de cada sítio** — um teclado que tocasse tudo a 0 dB não
provava nada. Não é UI permanente: só existe com o modo Dev ligado.

Quem fez estes sons não os ouve. Tudo o que está acima diz que a forma está
certa, não que soa bem. **HUMAN LISTEN REQUIRED.**

---

## Build

`C:/Projetos/koliani/build/windows/Koliani.exe`, release **v0.18.12**,
205 735 752 bytes, SHA256
`13FD274D4C22CFB9DBA45B0E2169027D93FACFBFC8AFEE622956235FA5F29E5B`.

Suite: **EXIT 0** por `tools/correr_testes.ps1`. Save do Game Master
verificado por SHA256 antes e depois de cada corrida, intacto nas duas.
