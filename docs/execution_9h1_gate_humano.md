# Execution 9H.1 — fecho do gate humano da Região I

**Estado: PARTIAL PASS.** v0.18.0. Região II **não** iniciada.
Relatório da execução anterior: [execution_9h_frontend_regiao1.md](execution_9h_frontend_regiao1.md).

O Game Master fechou a 9H com cinco coisas por fazer. Esta execução existe
só para elas:

| # | pedido | estado |
| --- | --- | --- |
| 1 | trilha sonora de produção | **FEITO** — 6 peças originais |
| 2 | a Koliani tem de LER-SE a fazer um combo | **FEITO** — poses de corpo próprias nos golpes 2/3/4 |
| 3 | inimigos/guardiões/chefe com movimento credível | **FEITO** — 283 frames derivados, 12 criaturas |
| 4 | prova visível em Chrome/PWA | **FEITO com ressalva** (ver §6) |
| 5 | seletor com tema por região | **FEITO** — arquitectura + pele da Região I |

E devolveu um achado que não estava no briefing: o **REPOR do editor de
layout de toque nunca apagou nada no Web** (§7). Corrigido.

---

## 1. Trilha sonora — de PRODUCTION AUDIO MISSING a seis peças originais

O briefing autoriza escolher ou produzir, por ordem de preferência:
material próprio → material gerado/composto → CC0 → licenciado com
atribuição. Ficou-se **no primeiro degrau**: tudo o que toca de novo é
material do projeto, composto e sintetizado aqui.

### As peças

| faixa | papel no jogo | duração | MB | sha256 (12) |
| --- | --- | ---: | ---: | --- |
| `tema_menu.wav` | menu inicial, intro, ecrãs do frontend | 48,0 s | 6,1 | `118eb4dbca3d` |
| `regiao1_exploracao.wav` | Região I, níveis 1-1 a 1-5 | 60,0 s | 7,7 | `43a27ec030bc` |
| `regiao1_combate.wav` | camada de intensidade da Região I | 60,0 s | 7,7 | `ed08bb7a97f8` |
| `regiao1_guardiao.wav` | guardiões 1-1 a 1-4 | 57,6 s | 7,4 | `ab95a03e643e` |
| `regiao1_coracao.wav` | Coração Putrefacto (1-5) | 60,0 s | 7,7 | `e7c348ac6677` |
| `pausa_ambiente.wav` | menu de pausa / opções | 32,0 s | 4,1 | `4f5550fe3868` |

**Proveniência e licença.** 100 % original do projeto. Zero amostras,
gravações ou composições de terceiros; **nenhuma atribuição devida**.
Manifesto: `assets/audio/musica/producao/manifesto_trilha_9h1.json`.
Compositor: `tools/compor_trilha_9h1.py` sobre `tools/motor_musical.py`
(sintetizador escrito de raiz: osciladores por wavetable, corda pincada por
Karplus-Strong, filtro passa-baixo ressonante de 2 pólos, envelopes ADSR,
reverberação de Schroeder — Python puro, sem numpy).

**Porque seis e não quarenta.** O briefing diz, com todas as letras, para
não fazer 40 faixas medianas para satisfazer um número. As Regiões II-XX
continuam nas 20+20 faixas CC0/CC-BY de sempre; compor-lhes música final
antes de elas terem arte aprovada seria escrever no escuro.

### Unidade temática

As cinco peças com melodia usam o **mesmo motivo de sete notas** em ré
menor. O menu enuncia-o inteiro em sino; a exploração desfá-lo em
fragmentos sobre um arpejo de harpa; o combate cita-o em metais; o tema dos
guardiões toca-o em compasso dobrado, em oitavas, com o mi bemol frígio por
baixo; o Coração toca-o **invertido**, com um segundo sino 18 cents acima —
a corrupção é a mesma nota a discutir consigo própria. É isto que separa
uma banda sonora de seis loops soltos.

### O que o jogo faz com elas

- `Musica.faixa_de_nivel(i)` / `faixa_de_chefe(i)`: dentro da Região I
  devolvem as peças novas, fora dela as antigas. Uma função só, usada pelo
  jogo **e** pelos testes.
- **Camada de intensidade**: `Musica.intensificar()` entra quando a Koliani
  acerta num inimigo ou leva dano, e sai sozinha 7 s depois do último
  golpe. Num combate de chefe não se mete ao barulho.
- **Pausa**: `Musica.pausa(true)` baixa a cama 11 dB e põe por cima a peça
  de pausa. Não PÁRA a cama — pará-la e recomeçá-la punha a música de volta
  ao princípio a cada pausa.
- **As camas CRUZAM-SE** em 0,9 s (`_p` sobe, `_p2` desce). Não há
  fade-out: uma cama de jogo toca em ciclo e não tem fim, por isso um
  fade-out abre um buraco.

### Duas armadilhas que custaram passagens inteiras

1. **A EMENDA DO CICLO.** Na primeira renderização o fim de cada faixa
   estava até **27 dB abaixo** do princípio: as notas terminavam com o seu
   próprio release e o bordão tinha ataque e queda. Ouve-se como um buraco
   a cada volta. Resolvido com (a) `voz_continua()`, que arredonda a
   frequência do bordão para caber um número **inteiro** de ciclos na
   duração (sem envelope, sem estalo) e (b) camas de acorde a transbordar
   1,55 compassos, que dão a volta e reentram no princípio. Medido depois:
   a última janela de 0,3 s fica entre **−1,6 e +1,6 dB** da mediana da
   faixa (o combate fica a −4,5 dB, que é um compasso a acabar antes do
   tempo forte, não um buraco).
2. **O SALTO DE FASE.** Mesmo com o nível certo, a forma de onda podia dar
   um salto de 0,18 (40 % do pico) na emenda — ouve-se como um estalo a
   cada volta. Um micro-esbatimento de **2,5 ms** nas duas pontas resolve;
   2,5 ms não se ouvem, o estalo ouvia-se.

Formato: WAV 32 kHz estéreo com `compress/mode=2` (QOA) no import — 40,7 MB
em disco, uma fracção disso no PCK.

---

## 2. O combo da Koliani

### O que estava mal

Os golpes 2 e 3 saíam **dos mesmos seis frames golden do `attack_basic`**,
a velocidades diferentes, com arcos de VFX diferentes por cima. Com os
efeitos escondidos eram a mesma animação três vezes. O Game Master leu isso
como insuficiente e tinha razão.

### O que passou a ser

`tools/derivar_combo_koliani_9h1.py` produz **poses de corpo próprias** para
os golpes 2, 3 e 4, derivadas da autoridade aprovada. Identidade intacta:
cara, cabelo, fato, proporções, Shadowblade e estilo do Golden Set vêm
literalmente dos frames aprovados. **Nenhum pixel é desenhado à mão.**

O método tem três partes:

1. **Separar.** A Shadowblade é o único elemento magenta saturado da
   figura (matiz 0,78–0,95, S ≥ 0,30, L ≥ 0,22). A máscara sai limpa nos
   seis frames. O **contorno escuro** da lâmina (um anel de 1 px, matiz
   0,70–0,91) vai com ela; deixado no corpo, o cisalhamento do tronco
   arrastava-o e via-se uma **segunda espada a tracejado** ao lado da
   verdadeira.
2. **Repor o corpo.** Quatro operações de pixel inteiro: `inclinar`
   (cisalha o tronco acima da anca), `passada` (abaixo da anca, a perna da
   frente avança e a de trás recua, com rampa até aos pés), `agachar`
   (comprime na vertical com os pés presos à linha de base) e `espelhar`
   (vira a figura sobre o pivot).
3. **Repor a lâmina.** Rodada em torno do **punho**, detectado como a ponta
   da máscara mais próxima do centro do **tronco** (não da figura inteira:
   a capa arrasta o centróide ~15 px para trás e o "punho" ia parar ao meio
   da lâmina).

### As quatro leituras

| golpe | leitura | corpo | trajectória da lâmina |
| --- | --- | --- | --- |
| 1 | corte descendente | autoridade aprovada, intocada | −39° → +119° → −39° |
| 2 | **revés ascendente** | peso atrás → desenrola → esticada, passada a abrir de −4 a +11 px | −79° → +71° |
| 3 | **rodopio** | frames 3 e 4 são as **COSTAS** (espelhados) | +139° pelas costas → −6° |
| 4 | **REMATE** | agacha (−10 % a −16 % de altura), recua, crava com avanço de 17 px | +141° por cima da cabeça → −69° |

**Medida objectiva da distinção** (diferença média de silhueta por frame,
1 − IoU, entre as quatro tiras):

|  | 1 | 2 | 3 | 4 |
| --- | ---: | ---: | ---: | ---: |
| **1** | — | 0,409 | 0,366 | 0,490 |
| **2** | 0,409 | — | 0,381 | 0,383 |
| **3** | 0,366 | 0,381 | — | 0,473 |
| **4** | 0,490 | 0,383 | 0,473 | — |

Entre 37 % e 49 % da silhueta muda de golpe para golpe. **Zero frames
byte-idênticos** entre tiras.

### Uma armadilha de método

A primeira passagem dava à lâmina **ângulos absolutos**, com rotações até
160°. A espada ia parar a sítios onde o braço desenhado não podia levá-la e
lia-se como uma lâmina solta a flutuar. A versão boa usa **deltas
pequenos** (|Δ| ≤ 40°) e tira a trajectória da **escolha do frame de
origem** — os seis frames golden dão ângulos nativos de −39°, +24°, +29°,
+33°, +36° e +119°, e é essa a matéria-prima.

### O combo passou de 3 para 4 golpes

O briefing pede explicitamente ATTACK 1–4 e a verificação da cadeia
`1 → 2 → 3 → 4`. Eram três porque só havia arte para um golpe. `NUM_COMBO`
passou a 4, com `DUR_COMBO = [0,18, 0,20, 0,30, 0,26]` e entradas novas em
`ATAQUE_ATIVO_*`, `AVANCO_*`, `TOM_COMBO` e `ARCO_COMBO`. **O dano por
golpe não mudou** (vem de `_dano_golpe()`, não do passo); o que mudou foi o
comprimento da cadeia. Toda a lógica de remate (hitstop, tremor, sangrar,
selo dourado) já pendurava em `NUM_COMBO - 1` e seguiu sozinha para o 4.º.

### Respostas explícitas

- **ATTACK 1–4 BODY MOTION VISUALLY DISTINCT: YES** — 0,366 a 0,490 de
  diferença de silhueta, nenhum frame repetido.
- **FULL COMBO READS WITHOUT VFX: YES** — provado em runtime com os arcos
  escondidos (`work/execution_9h1/movimento/koliani_combo_sem_vfx.png`).
  Ressalva honesta: à distância de jogo a figura tem ~59 px e a leitura é
  clara mas não teatral; o rodopio (costas viradas) e o remate (avanço
  fundo) são os dois que se reconhecem sem esforço.
- **FINISHER CLEARLY READS AS FINISHER: YES** — é o único golpe com duas
  antecipações agachadas, o único com avanço de 17 px, o único com a lâmina
  por cima da cabeça, e o que leva o hitstop e o tremor de remate.
- **FULL TOUCH COMBO: ver §6.**

---

## 3. Movimento das criaturas

### O que estava mal

A 9D/9E produziu **uma pose por estado** e deixou escrito no manifesto que
ciclos articulados "seriam poses novas — APPROVED DESIGN / PRODUCTION ASSET
MISSING, não se inventaram". A 9H pôs por cima uma camada procedimental que
respira, inclina e recua a **imagem inteira**. O Game Master leu o
resultado pelo que ele era: uma imagem parada a ser transformada. Ou seja,
classificação **B** para as doze entidades.

### O que passou a ser

`tools/animar_criaturas_9h1.py`: **283 frames derivados**, 12 criaturas,
três estados cada (`idle` 8, `run` 8, `attack` 7). A pose de partida fica
guardada intocada em `frames/_base_9h1.png` e é sempre dela que se deriva —
correr a ferramenta duas vezes dá exactamente o mesmo resultado.

As pernas são **detectadas**: na faixa de baixo da silhueta, cada corrida
de colunas ligadas é uma perna. Por isso o mesmo código serve um goblin de
duas, um Ghorak de quatro e uma Rainha de oito.

| tipo | criaturas | o que se mexe |
| --- | --- | --- |
| bípede | goblin, Morvanna, clone | pernas alternadas, tronco a respirar, cabeça com fase própria, manto em onda |
| quadrúpede | Ghorak | quatro patas em ciclo, lombo, **cabeçada do terço da frente** |
| aracnídeo | Rainha, cria, besouro | oito/seis patas desfasadas, corpo a empinar no ataque |
| blob | gosma, lodo | squash & stretch forte, onda a subir pelo corpo |
| fungo | mushroom | chapéu a oscilar e a bater, pé fixo |
| planta | Entrevane | copa em onda de 1,8 períodos, raiz a chicotear no golpe |
| núcleo | Coração (2 fases) | tentáculos em onda dupla, núcleo a bater |

Além disso, **o brilho da corrupção pulsa** em todas: é o sinal de vida mais
barato e mais legível que existe e não mexe uma única silhueta.

### O estado ATTACK não existia

Nenhum inimigo comum tinha animação de ataque — o telégrafo era só cor e
tremura. Agora `DemonioBase._atualizar_anim()` toca `attack` quando
`_telegrafo > 0`, que é exactamente o instante em que a antecipação tem de
se ver.

### Três armadilhas, todas da mesma família

1. **Rodar uma faixa parte o bicho.** Cortar o Ghorak a meio da altura e
   rodar a metade de cima deixa as duas metades desencontradas na linha do
   corte. Onde se quer inclinação usa-se **cisalhamento**, que é contínuo na
   fronteira. A cabeçada do quadrúpede passou a ser do terço da frente **em
   x**, não de uma fatia em y.
2. **Comprimir linha a linha abre uma costura.** Esticar mapeando cada
   linha deixa filas vazias. Redimensiona-se a **região** (NEAREST).
3. **Uma rampa VERTICAL em píxeis inteiros deixa um buraco em cada
   degrau.** O clone da Morvanna ficava com um risco transparente na linha
   47 sempre que a cabeça subia 1 px. O movimento vertical passou a ser
   feito por compressão da região acima do pescoço. Verificação
   automática: **0 frames com linha vazia** (fora os `dead`, onde a
   dissolução do 9D as tem de propósito).

### Coração Putrefacto

- **Fase 1**: núcleo a pulsar, tentáculos em onda dupla (2,4 e 1,3
  períodos, desfasadas), corpo a respirar. Contido.
- **Fase 2**: mesmo tratamento com **amplitude 1,9×** sobre uma pose base
  diferente — visivelmente mais agitado, corrupção mais acesa.
- As duas fases são **material diferente** (frames com SHA distintos),
  guardado por teste.
- Não há escala do sprite inteiro em lado nenhum.

---

## 4. Equilíbrio dos chefes — números, não afinações

Como o briefing manda: **não se afinou nada**. A tabela antes/depois está em
`work/execution_9h1/chefes_regiao1.md`, gerada por
`tools/tabela_chefes_9h1.gd` (instancia cada guardião duas vezes, uma sem
entrar na árvore e outra depois de `_afinar_dificuldade()`).

Resumo (`base` = o que o script declara, `jogo` = o que o jogador encontra):

| chefe | vida base → jogo | alívio da região | telégrafo |
| --- | --- | --- | ---: |
| 1-1 Ghorak | 250 → **416** | vida ×0,52, dano ×0,58 | 0,60 → 0,64 s |
| 1-2 Morvanna | 275 → **537** | vida ×0,60, dano ×0,65 | 0,62 → 0,63 s |
| 1-3 Rainha Aracnídea | 300 → **675** | vida ×0,68, dano ×0,72 | 0,60 → 0,58 s |
| 1-4 Entrevane | 320 → **829** | vida ×0,77, dano ×0,80 | 0,62 → 0,57 s |
| 1-5 Coração Putrefacto | — → — | vida ×0,86, dano ×0,88 | 0,55 → 0,48 s |

**Uma coisa que salta da tabela e não estava no briefing:** o
`dano_contacto` é o único dano que a rampa **não** alivia (está excluído no
`_afinar_dificuldade`), e por isso **sobe** ao longo da região — 16 no
Ghorak, 25 no Coração — enquanto todos os outros danos descem. Pode ser
intencional (encostar-se ao chefe deve doer) ou um descuido. **Fica para
decisão do Game Master**, não se mexeu.

**GAME MASTER PLAYTEST PENDING: YES.**

---

## 5. Seletor com tema por região

### Arquitectura

`scripts/tema_regiao.gd` (`TemaRegiao`). Uma estrutura de tema igual para
as vinte regiões, com os campos que o seletor consome: `primaria`,
`primaria_clara`, `acento`, `veu`, `trilho`, `trilho_brilho`, `motivo`,
`miniatura`, `id` da pasta de peças. Acrescentar uma região no dia em que a
arte for aprovada é acrescentar uma entrada e uma pasta em
`assets/ui/frontend_9h/regioes/rNN/` — **não se mexe no seletor**.

O seletor chama `_aplicar_tema()` a cada actualização, mas só faz trabalho
quando a região **muda**. O que o tema muda: fundo, peças de moldura, cor
do trilho, véu, tinta do painel, sombra dos cabeçalhos, realce do nó. O que
**não** muda: estrutura 20×5, navegação, bloqueios, comportamento no
comando/teclado/toque.

### Região I — Floresta Corrompida

- **Fundo**: composição de arte de produção **já aprovada** da Região I —
  o panorama da Árvore-Coração (9H) + névoa e vegetação do kit 9C. Não há
  um pixel de cenário inventado: é o sítio onde o jogo se passa, visto de
  longe. Ferramenta: `tools/tema_regiao_9h1.py`.
- **Peças**: as molduras do frontend 9H com o carmesim rodado para **verde
  de musgo** (matiz 0,30), luminância a 0,86 e saturação a 0,70 — musgo,
  não néon. As abas e a placa levam ainda menos (luz 0,66, sat 0,52)
  porque têm texto por cima.
- **Acento de corrupção**: o **anel do guardião** (1-5) e o **cadeado**
  ficam em magenta/violeta (matiz 0,84). Verde é a floresta; magenta é o
  que lhe está a acontecer.
- **Miniatura do painel**: o panorama da própria região. Era a
  `FUNDO_REGIAO[0]`, uma floresta de **outono** laranja e vermelha, que num
  ecrã verde lia-se como um erro.

### Regiões II–XX

Nada foi inventado. Caem numa pele **neutra de aço frio**: as peças
aprovadas do frontend **dessaturadas** (`tools/tema_regiao_9h1.py`, pasta
`regioes/neutro/`), marcadas `REGION SELECTOR THEME AUTHORITY MISSING` em
`TemaRegiao.SEM_AUTORIDADE`, no manifesto e em `TemaRegiao.estado()`.

Uma nota de método: a primeira tentativa fazia isto por `modulate` com um
cinzento. Não chega — **carmesim × cinzento continua carmesim escuro**, e
a Região V continuava a ler-se como "a vermelha". Tem de se tirar a cor de
verdade, na produção da peça.

### Respostas explícitas

- **REGION I SELECTOR VISUALLY READS AS FLORESTA CORROMPIDA: YES**
- **FUTURE REGION THEMES DATA-DRIVEN: YES**
- **UNAPPROVED REGION ART INVENTED: NO**

### Estatísticas do painel

Continuam a ser só o que o jogo **sabe**: guardião, passo na região
(`REGIÃO I 1/5`), estado (disponível / concluído / trancado). Não há
colecionáveis, desafios nem tempos — esses sistemas não existem e não se
fingiram.

---

## 6. Prova de runtime

### Windows (EXE de release)

Exportado de worktree limpo, commit `12f1209`, v0.18.0.
SHA-256: `670b69435475790bd440748e586c6063ce2fa18b1556e49b61791ac86d4e03de`.
Capturas em `work/execution_9h1/windows/`: intro (`pos=2,80 s`), menu novo
com o ícone do rebrand, **seletor da Região I em verde**, seletor neutro da
Região V, e os níveis 1, 3 e 5 com HUD. Rota nova `--foto-seletor=<png>@<n>`
(só dev) — este ecrã não tinha forma de ser fotografado no export.

### Movimento (tiras de frames, do jogo a correr)

`tools/prova_movimento_9h1.tscn` corre o jogo e fotografa o ecrã frame a
frame. Saída em `work/execution_9h1/movimento/`:

- `koliani_combo.png` e `koliani_combo_sem_vfx.png` — os quatro golpes, 8
  instantes cada, com e sem os arcos;
- nove criaturas (`goblin`, `mushroom`, `gosma`, `besouro`, `lodo`,
  `ghorak`, `morvanna`, `rainha_aracnidea`, `entrevane`), uma linha por
  estado;
- `coracao_fase1.png` e `coracao_fase2.png`.

Três armadilhas que custaram três passagens, para não se repetirem:

1. **O viewport não devolve RGBA8.** Misturar formatos num `blit_rect` dá
   uma tira com as cores trocadas e bandas horizontais — parece corrupção
   de memória e é só o formato.
2. **Esconder os VFX por nome falha.** Os arcos do combo nascem em runtime
   como filhos da **própria Koliani**, não do `Sprite`. A regra boa é por
   exclusão: apagar tudo menos o `Sprite/Corpo`.
3. **A câmara é filha da Koliani e a física repõe a posição.** Teleportar a
   Koliani para o chefe não chegou (câmara em x=−3116 com o Coração em
   x=+3080, e a tira saía toda preta). Precisa de `top_level = true` e de
   posição imposta a cada frame.

### Web / PWA — em Chrome REAL, visível

Servido por `tools/servidor_prova_web.py` (serve o build e aceita
`POST /prova/<nome>`, que é como as capturas feitas **dentro** do browser
saem de lá para o pacote). Build do mesmo commit `12f1209`; PCK
`297cf8e29dc6d54ab57a4af14493327e702bdc2955e5facdcc3d7a80aa9ff530`.

Provado, com capturas em `work/execution_9h1/web/`:

| item | resultado |
| --- | --- |
| carrega sem erros de GDScript | ✅ banner do motor, `single-threaded`, PCK/wasm/worklets/manifest/ícones todos 200 |
| cartão de gesto + ícone da PWA | ✅ |
| intro em vídeo → menu | ✅ |
| menu novo (v0.18.0) | ✅ `web_01_menu.png` |
| **seletor da Região I em verde** | ✅ `web_02_seletor_r1.png` |
| **apresentação neutra (Região II)** | ✅ `web_03_seletor_neutro.png` |
| áudio a chegar ao altifalante | ✅ contexto `running`, **picos medidos 0,09–0,20** com `?audio-debug=1` (sem regressão do 9F) |
| EDITAR LAYOUT | ✅ `web_04_editor_layout.png` |
| mover o controlo de movimento | ✅ joystick de x=0,14 para x=0,274 |
| mover o controlo de acção | ✅ botão de salto para x=0,893 / y=0,716 |
| redimensionar dois controlos | ✅ joystick r=0,180 e salto r=0,113 |
| gravar | ✅ "Layout saved" + `layout_toque.json` em IndexedDB |
| persistência | ✅ lido de `/userfs/godot/app_userdata/Koliani/layout_toque.json` |
| repor por omissão | ✅ **corrigido e re-verificado** — ver §7 |

**RESSALVA HONESTA, e é importante.** O Chrome desta máquina corre
**ocluído** por trás da aplicação: o `requestAnimationFrame` fica a **1 Hz**
e o jogo anda a 1 frame por segundo. Tudo o que está acima foi feito assim
— cada navegação levou 40 a 60 s de relógio. Portanto:

- o que está provado é que **funciona**: as cenas certas aparecem, com a
  arte certa, com som real a sair;
- o que **não** está provado é a **fluidez** no browser, nem o combo de
  quatro golpes por toque, que a 1 fps não se consegue encadear dentro da
  `JANELA_COMBO` de 0,42 s.

**FULL TOUCH COMBO: NÃO PROVADO** nesta sessão, por esta razão e não por
outra. Fica como P1 para a primeira sessão com uma janela de Chrome em
primeiro plano.

---

## 7. Achado: o REPOR do layout de toque nunca apagou nada no Web

Apanhado exactamente por se ter feito a prova em browser visível.

O botão REPOR punha os controlos no sítio certo no ecrã, e o
`layout_toque.json` **continuava em IndexedDB com os valores editados** — na
recarga seguinte voltava tudo, e nada dizia porquê.

**Causa provada:** `LayoutToque.apagar()` chamava
`DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO))`. No
export Web esse caminho é do sistema de ficheiros do emscripten, que o
`DirAccess` não apaga. O `DirAccess` aceita `user://` tal e qual, e é isso
que funciona nas três plataformas.

Corrigido: `apagar()` devolve se apagou mesmo; o editor pisca
**"Layout reposto"** (chave nova `layout.reset_done` nos 6 idiomas) só
quando apagou. Teste de regressão novo.

**Re-verificado no build corrigido, no mesmo Chrome:** GRAVAR → o ficheiro
aparece em IndexedDB; REPOR → **desaparece dentro de 8 s**. Antes da
correcção, o mesmo ficheiro continuava lá 16 s depois do REPOR, portanto a
diferença não é uma questão de tempo de sincronização.

---

## 8. Desempenho

Tempo de **parede** por frame (`tools/bench_9h1.tscn`, 240 frames medidos
depois de 60 a aquecer, vsync desligado):

| cena | média (ms) | p95 (ms) | pior (ms) |
| --- | ---: | ---: | ---: |
| menu | 0,389 | 0,655 | 1,872 |
| seletor Região I (com pele) | 0,384 | 0,696 | 2,211 |
| L1 Floresta Corrompida | 0,646 | 0,992 | 2,225 |
| L3 Ninho da Viúva Negra | 0,678 | 1,079 | 2,024 |
| L5 Coração da Floresta | 0,973 | 1,465 | 2,769 |

Sem regressão material. O pior frame de todo o conjunto fica em 2,8 ms, a
seis vezes de distância do orçamento de 16,7 ms. Não há geração
procedimental de sprites em runtime: os frames derivados são ficheiros de
produção, importados.

---

## 9. Testes

Suite preservada e alargada: **88 funções de teste, 517 asserções**, todas
a passar. Guardas novas da 9H.1:

- `teste_9h1_trilha_de_producao` — as seis peças existem, carregam, têm
  mais de 20 s, estão em **ciclo**, declaram proveniência e licença; os
  buses `Music`/`SFX` continuam lá; o mapeamento acerta dentro e fora da
  Região I.
- `teste_9h1_combo_com_poses_proprias` — as quatro tiras existem, têm 6
  frames, **nenhum par é a mesma sequência de texturas**, e a duração de
  cada tira bate com o `DUR_COMBO` do seu passo (±20 ms).
- `teste_9h1_criaturas_com_movimento` — cada animação derivada tem ≥ 7
  frames e ≥ 5 desenhos diferentes; os quatro guardiões têm os cinco
  estados; o Coração tem as duas fases e elas **não são o mesmo frame**.
- `teste_9h1_tema_do_seletor` — a Região I tem pele própria, **exactamente
  uma** região tem autoridade, as outras 19 estão marcadas, as peças da
  Região I diferem das neutras, o verde é verde e o acento é magenta, e as
  20 regiões continuam com 5 níveis cada.
- `teste_9h1_repor_layout_apaga_mesmo` — o REPOR tem de apagar o ficheiro.

As quatro primeiras foram **provadas a morder**: com as asserções
invertidas de propósito, o corredor devolveu 7 falhas nos sítios certos.

---

## 10. O que fica por fazer

**P1**

- **Combo de quatro golpes por TOQUE**, no browser em primeiro plano (a 1
  fps não se encadeia).
- **Playtest humano** dos chefes da Região I. A tabela do §4 está pronta;
  os números não se mexem sem ele.
- **`dano_contacto` sobe ao longo da região** (16 → 25) enquanto todo o
  resto desce. Decisão do Game Master.

**P2**

- O ecrã de **Opções** continua vestido a ouro/ciano do 9F, dentro de um
  frontend que é carmesim (e, no seletor, verde). Destoa.
- `RaizPerigo` continua desenhada por código (a prancha não tem raízes).
- O PCK do Web está em **85,9 MB**; a trilha nova acrescenta ~13 MB
  comprimidos.

**P3**

- As 19 regiões sem pele: `REGION SELECTOR THEME AUTHORITY MISSING`.
- Faixas de música próprias para as Regiões II–XX, quando essas regiões
  tiverem arte.
- Os ficheiros `._*` (AppleDouble) de um pack antigo continuam a poluir o
  `--import` com erros "Not a WAV file" — ruído, sem efeito no build.

---

**READY FOR GAME MASTER HUMAN REVIEW: SIM.**
**REGIÃO I VISUAL VERTICAL SLICE: HUMAN APPROVAL PENDING.**
**Região II não iniciada.**
