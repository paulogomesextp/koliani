# Retomar aqui — 4 de setembro de 2026

> **LEIA PRIMEIRO.** O topo é a **fila de pedidos do Paulo por fazer**; o
> fundo é o que já ficou feito nesta sessão.

---

# ⚠ COMECAR AQUI — a ordem que o Paulo deu (4 set 2026)

**Painel de prioridades (é a fonte de verdade da ordem):**
<https://claude.ai/code/artifact/875b9e60-ef1b-4866-ad8f-d273169da411>

> **Regra dele: todo o pedido novo entra nessa página.** O estado de cada
> linha (estado/bloco/ordem) vive no `db` do artifact, não no HTML — o HTML
> só tem o catálogo `ITENS`. Acrescentar uma entrada e republicar **não**
> estraga a organização dele. O ficheiro-fonte da página vive no scratchpad
> da sessão que a publicou: numa sessão nova, ler o artifact
> (`Artifact action:"read"` com o URL), gravar em ficheiro, e só depois
> editar e republicar com o mesmo `url`.

Blocos, por ordem de ataque:

1. ~~**Softlock do portal**~~ — **FEITO** (`712137f`).
   Junto com ele, os dois bugs que ele apanhou a jogar a 4 set: o ecrã a
   engasgar no golpe de espada e os frames soltos por cima da cabeça dela
   no salto — **os dois FEITOS**, ver mais abaixo.
2. ~~**Som e música**~~ — **FEITO** (4 set 2026): as 40 camas refeitas para
   fecharem sobre si próprias + rock CC0; set de sons novo para a Koliani;
   voz própria por família de monstro; espada e mísseis em camadas. Detalhe
   logo a seguir a esta lista.
3. ~~**Projécteis, luz e escudo**~~ — **FEITO** (`2b3dae9`, `8bf1898`).
   Detalhe logo a seguir a esta lista.
4. **Infra** — ~~**APK ANDROID FEITO**~~: compilou pela primeira vez
   (run #332) e está no Release **`android-latest`**. Falta só o **switch do
   Pages, que só o Paulo pode dar** — ver "Bloco 4" mais abaixo.
5. **UI, vidas, mecânicas** — ⬅ *é aqui que a próxima sessão pega.*
   ~~vidas a começar em 5 e +1 por nível~~ **FEITO** (`9b8a78e`).
   ~~a tabela das mecânicas~~ **ESCRITA, à espera da aprovação dele**
   (`docs/mecanicas_por_nivel.md` + página abaixo). **Nada disso se coda
   antes de ele responder.** Falta a UI + indicador de nível.
6. **Assets e licenças** — portal da Frostwindz: **cancelar a mudança ou
   achar um equivalente grátis**. Licença do pack das balas: **ignorar**
   (decisão dele).
7. **Trabalho de fundo** — playtest (ele já testou a maior parte e vai dar
   feedback); **chefes com arte própria fiel ao lore, um por nível**; curva
   do 2.º acto; nível 100 = duelo de espada sem poderes; arte própria das 14
   regiões novas; Sino Vivo + Vyrak; menu de selecção de níveis;
   SalaLabirinto.
8. **Afinar** os números postos "a olho" + o glow roxo da espada, que passa
   nos testes mas nunca foi visto em jogo.

---

# BLOCO 3 (projécteis, aura, luz e escudo) — **FECHADO** (4 set 2026)

Os quatro pedidos dele deste bloco estão feitos.

## Laser roxo do Wenrexa — `2b3dae9`

`tools/gerar_fx_laser.py` recorta o pack **Wenrexa "Laser2020"** (CC0, uso
comercial, sem crédito obrigatório). O tiro dela é o cometa magenta
(`13.png` -> `fx/laser_roxo.png`) e o Kamehameha é o raio aos ziguezagues
(`22.png` -> `fx/laser_raio_roxo.png`), que substituiu os três `Polygon2D`
desenhados à mão — eram a parte que se lia como feita por código.

> ⚠ **A escolha dele não bate certo com os nomes dos ficheiros.** Ficou
> registado que escolheu "o último da primeira fila da capa" e que era um
> "cometa magenta de cauda comprida". A capa mostra 10 por linha e os
> ficheiros também andam de 10 em 10 — mas o **10.º é uma bola AMARELA**.
> Foi-se pelo conteúdo e pelo pedido escrito ("roxo com brilho"). **Se ele
> disser que não é este, é uma linha na tabela `LASERS` da ferramenta** —
> há 66 no pack, e a folha de contacto tira-se com
> `tools/gerar_fx_laser.py` + um mosaico.

São glows de alta resolução, **não pixel-art**: os nós desenham-nos com
`texture_filter = 2` (LINEAR). A Nearest sairiam aos degraus. O tiro deixou
de ter tira de frames — o "vivo" é o pulsar da escala.

## Aura roxa — `2b3dae9`

Duas metades no `Koliani.tscn`: o **`Sprite/Halo`** (degradé radial aditivo,
por trás do corpo) que se vê, e a **`LuzAura`** que já lá estava — agora
roxa a sério e com força — que ilumina o cenário. Respiram em conjunto e
**acendem** quando ela golpeia, dá dash ou lança (`_acender_aura`); o 4.º
golpe do combo e o Kamehameha são os que mais a fazem estoirar.

## Escudo de energia — `2b3dae9`

O bloco do escudo estava atrás de `RIG == "codigo"`. Com o **Shadowblade**
activo — que nem tem pose de defesa no atlas — ao carregar em defender **não
aparecia escudo nenhum**. Passou a `RIG != "cavaleiro"` (esse traz o escudo
desenhado nos frames). Por cima da placa entra a **cúpula de energia roxa**:
cresce ao levantar o escudo, respira, e dá um clarão a cada bloqueio.

Bancada: `tools/shot_aura_escudo.gd` (modo `escudo` / `tiro`; **precisa de
janela**). Gotcha guardado lá dentro: **`_defendendo` é recalculado do input
todos os frames** — pôr-lhe a bandeira à mão não serve de nada, tem de se
premir a acção (`Input.action_press("defender")`).

## Candeeiros e tochas — `8bf1898`

Dois props do **Ansimuz**, dos mesmos packs de onde já vêm fundos do jogo,
recortados por `tools/gerar_luzes.py`: o **poste gótico de três lanternas**
(GothicVania Town) e a **tocha de parede animada** (Cold Corridors).

A distribuição é feita em **código** (`nivel_com_chefe.gd::_iluminar`) e não
nos 100 `.tscn`: a maior parte do percurso é a JORNADA, gerada em cada
arranque — luzes postas na cena não apanhavam nada dela. Varre-se o percurso
em **colunas de 760 px** e escolhe-se, para cada uma, a plataforma mais
próxima que sirva.

Só plataformas **estáticas** (o script tem de ser mesmo o `plataforma.gd`):
numa flutuante ou quebradiça a luz ficava para trás. As **tochas** escolhem-se
pela grossura **visual** (`altura_visual`) — medidas pela colisão (22-70 px)
nenhuma plataforma chegava ao limiar e nunca saía nenhuma.

`tools/verifica_luzes.gd` conta as luzes por nível e mede o maior vão sem
luz. **Medição actual: 100/100 com luz; 98/100 com o maior vão < 3000 px.**

## Vidas — `9b8a78e`

`VIDAS_INICIAIS` 3 -> **5**, e **+1 por nível** passado. No **hardcore não
cresce** (lá as vidas são o limite do run) e o `reiniciar_run` repõe as
vidas do ponto onde ele vai (`vidas_de_partida`), não as 5 secas. Tecto de
99 só para o `x%d` do HUD. **A campanha inteira dá ~105 vidas** — se isso
amolecer de mais o fim, o sítio para afinar é `VIDAS_POR_NIVEL`.

---

# BLOCO 4 (infra) — **O APK ANDROID PASSA**, falta o switch do Pages

**O job do Android NUNCA passou — nem no run 1.** A nota "falha desde o run
264" estava errada: conferido pela API do GitHub, com amostras de 25 em 25
desde o run 1, todas dão `failure`. Não é uma regressão, é uma coisa que
nunca chegou a funcionar.

**Os logs deste repo pedem sessão iniciada** — de fora só se vê "Process
completed with exit code 1". As **anotações**, essas, são públicas: o CI
passou a despejar as últimas 25 linhas do export como `::error::` e o
ambiente (ANDROID_HOME, java, build-tools, apksigner, templates) como
`::warning::`. **É por aí que se lê o que se passa, em**
<https://github.com/paulogomesextp/koliani/actions>.

## O que era, afinal — duas coisas, e nenhuma era o que se suspeitava

Assim que a anotação passou a levar o log inteiro, o Godot disse-o por
palavras dele, uma de cada vez:

1. **`A valid Java SDK path is required in Editor Settings`.** A imagem
   `godot-ci` traz o OpenJDK 17 mas com o **`JAVA_HOME` vazio**, e o Godot 4
   não procura o `javac` no PATH — lê `export/android/java_sdk_path` das
   editor settings. O job passa a derivar a raiz do JDK do `javac` real e a
   escrever lá **as duas** definições (Android SDK e Java SDK).
2. **`ETC2/ASTC texture compression is required for Android export`.**
   `textures/vram_compression/import_etc2_astc=true` no `project.godot`.
   Custa uma variante comprimida a mais por textura no `.godot` (que não vai
   para o git) e um `--import` mais demorado.

**Nada disto era o que se suspeitava.** Os templates de Android estavam
todos instalados, o `apksigner` estava em `build-tools/33.0.2` e o
"Could not find version of build tools that matches Target SDK" é só um
aviso. **A parte difícil foi conseguir LER o erro**, não corrigi-lo.

**Resultado (run #332): APK de 100 MB, no Release
[`android-latest`](https://github.com/paulogomesextp/koliani/releases/tag/android-latest).**
Link fixo, a par do `win-latest` — o Paulo descarrega no telemóvel e
instala.

Ao mesmo tempo entraram as duas saídas públicas que faltavam:
- Release de tag rolante **`android-latest`** com o APK (a par do
  `win-latest`);
- **GitHub Pages** com o build Web (`enablement: true` liga o Pages sozinho
  na primeira vez). É a única via grátis para o iPhone.

### ⚠ UMA COISA QUE SÓ O PAULO PODE FAZER

O `GITHUB_TOKEN` **não consegue criar** o site de Pages (limitação conhecida
do `configure-pages`; o erro é `Resource not accessible by integration`).
Basta ir uma vez a **Settings → Pages → Build and deployment → Source:
GitHub Actions** e a partir daí cada push publica o jogo numa página que abre
no iPhone. Até lá o job fica `continue-on-error`, para não pintar o CI de
vermelho a cada push. Já está apontado no painel de prioridades.

### GOTCHA que vale ouro: como depurar este CI de fora

Os **logs** dos Actions deste repo pedem sessão iniciada (`Must have admin
rights`, mesmo sendo público). As **anotações** não:

```bash
curl -s "https://api.github.com/repos/paulogomesextp/koliani/actions/runs/<ID>/jobs"
curl -s "https://api.github.com/repos/paulogomesextp/koliani/check-runs/<JOB_ID>/annotations"
```

Duas armadilhas que já morderam:
- **o GitHub só CRIA as primeiras dez anotações de cada nível por passo.**
  Uma linha por anotação faz o essencial cair fora — manda-se **tudo numa
  anotação só**, com as quebras em `%0A`;
- correr o export com `-v` enche o log de `Loading resource:` e o `tail`
  passa a apanhar só ruído.

**Estado do diagnóstico:** o ambiente do CI está BOM —
`ANDROID_HOME=/usr/lib/android-sdk`, `apksigner` em `build-tools/33.0.2`,
OpenJDK 17. Não é SDK nem Java. As linhas reais que já saíram foram
"Could not find version of build tools that matches Target SDK, using 33.0.2"
(aviso, não fatal) e "Unable to load fontconfig" (ruído de headless). **A
próxima sessão pega o log inteiro na anotação e resolve.**

---

# BLOCO 5 (b) — UI e indicador de nível: o levantamento já está feito

> *"Melhore o UI, o Indicador de Nível, etc, vá buscar assets free."*

**Hoje a HUD não tem arte nenhuma.** É toda `Label` + `StyleBoxFlat` desenhados
por código no `scripts/controlos_toque.gd`: as barras de vida/energia, a barra
do chefe (`_ao_combate_chefe`), e o cabeçalho de nível
(`_encher_cabecalho_nivel`, que é só três Labels — nº do nível, nome, nome do
chefe).

**Já há um kit de HUD no repo, e do pack certo.** Não é preciso descarregar
nada:

```
assets/sprites/incoming/anokolisa/Legacy-Fantasy - High Forest 2.3/HUD/Base-01.png
```

432×304, e traz: **painéis** (pergaminho e madeira, com moldura própria — dão
`NinePatchRect` directo), **calhas e enchimentos de barra** em quatro cores +
as versões finas, e um bloco de **ícones** (pausa, X, +, play, seta, coroa,
troféu, engrenagem, caveira, relógio, aviso, boneco). É do **mesmo pack
anokolisa** que já dá o terreno da floresta, portanto a licença já está
resolvida e creditada.

O que falta é o trabalho: uma ferramenta `tools/gerar_ui.py` a recortar as
peças, e depois trocar os `StyleBoxFlat` por `NinePatchRect` no
`controlos_toque.gd`. O cabeçalho de nível é o sítio onde se nota mais.

---

# BLOCO 5 — a tabela das 100 mecânicas está escrita

`docs/mecanicas_por_nivel.md`, e a mesma coisa em página para ele ver no
telemóvel: <https://claude.ai/code/artifact/10c02ed5-c074-4992-9348-841002e59c31>

Cem níveis, cem mecânicas, uma por nível. A regra: **cada nível ESTREIA uma
mecânica** (mansa, é o tutorial dela sem texto), e **depois ela pode voltar,
sempre mais dura** — cada uma tem um parâmetro que escala com `_dif`.

O inventário honesto: **38 já existem** (actor ou câmara já no jogo), **17
são variações** baratas de coisas que existem, **31 são actores novos
pequenos** e **14 são grandes** (nadar, gancho, gravidade rotativa, a sombra
com atraso...). A página diz quais são os 14 e diz-lhe que **cortar qualquer
um deles não parte a promessa**.

**NÃO CODAR NADA DISTO** antes de ele responder às quatro perguntas do fim da
página. Foi ele que pediu para começar pela tabela.

Quando aprovar, o que muda: a tabela vira `MECANICA_DO_NIVEL` no
`gerador_corredor.gd` (ao lado do `PERFIL` e do `ASSIN_NIVEL`, que já fazem
uma versão fraca disto) e o `TIER_FLAVOUR` deixa de mandar na estreia.

---

# BLOCO 2 (som e música) — **FECHADO** (4 set 2026)

Os quatro pedidos dele sobre som estão feitos. A ordem passa ao **bloco 3
(projécteis, aura, luz e escudo)**.

## Música — o defeito era sistémico, não eram duas faixas

Ele queixou-se de que *"a música do Nível 32 é esquisita e tem vários
cortes"* e de que *"a do nível 1 e a do 2 são iguais"*. Medi antes de mexer
e o problema era maior:

- as camas tocam **sempre em ciclo** (`musica.gd` põe `loop = true`), mas
  **8 das 20 de nível e 10 das 20 de chefe tinham fade-out**. De X em X
  segundos a música desaparecia e voltava a entrar a todo o volume — é esse
  o "corte". A do nível 32 (`Zwischenwelt`) caía 19,5 dB e dava a volta de
  47 em 47 s;
- **7 faixas de nível eram curtas de mais**. A do nível 1 tinha **7,6
  segundos** (era o jingle *Victory Stats*, não uma cama) e a do 2 tinha
  8,0 s, do mesmo álbum — daí soarem iguais.

`tools/preparar_musica.py` reconstrói as 40 de raiz: corta o troço útil,
**cruza a cauda por cima da cabeça** para o fim ligar ao início sem salto, e
iguala tudo a -16 LUFS com ganho fixo. Entraram **6 faixas de rock/metal
CC0 do autor [nene](https://opengameart.org/users/nene)** nos níveis e 3 nos
chefes (o pedido do "tom de rock"); a que ele adorou (nível 38) fica onde
estava, só sem o fade final. As linhas 09-13 dos chefes eram os mesmos cinco
temas das 04-08 noutra versão — passam a ser cinco temas distintos.

> Gotcha guardado: o `acrossfade` do ffmpeg, quando a cauda tem exactamente
> a duração do cruzamento, **há faixas em que não devolve nada** (apanhado
> no `boss_03`). Por isso o cruzamento é feito em Python, no `.wav`.

## SFX — sons novos e uma VOZ por família de monstro

`tools/preparar_sfx.py` (novo). Duas coisas que mudam de método:

- **Sons que não existiam**: passos (três amostras sorteadas, cadência a
  acompanhar a velocidade), rolamento, dash, raspar na parede, agarrar a
  borda, morte, e som próprio para o remate do combo.
- **Sons por FAMÍLIA de monstro**: as 19 espécies partilhavam quatro
  rosnados. Agora há sete famílias (humano, morto, gosma, besta, insecto,
  voador, grande), cada uma com ataque/dano/morte — tabela `FAMILIA_SOM` em
  `demonio_base.gd`.
- **A espada e os mísseis em CAMADAS.** Já tinham sido trocados duas vezes
  por *outra amostra solta*, e era aí que falhava: uma amostra solta nunca
  soa a golpe de jogo. O golpe passa a ser ar + metal com 30 ms entre eles;
  o tiro é sopro grave + zumbido metálico.

**Se ele continuar a não gostar da espada**, a receita é uma linha do
`SONS["ataque"]` em `tools/preparar_sfx.py` — trocar as camadas, correr a
ferramenta e importar. Os packs já estão todos em disco.

Redes de segurança novas: `preparar_musica.py --verificar` (mede o degrau
na costura de cada cama), `teste_camas_de_musica` e `teste_sfx_existem` na
suite.

---

# FEITO — os dois bugs que ele apanhou a jogar (4 set 2026)

## "Quando ataca com espada o ecrã treme e gera frame drop"

Não era impressão. O `_hitstop` põe `Engine.time_scale = 0.0`, ou seja
**pára o jogo**, e estava espalhado por sítios onde não devia: o balanço do
4.º golpe parava 50 ms e abanava a câmara **sem ter acertado em nada**, o
`_flash_golpe` abanava mais 1,8 px em todos os balanços, e cada acerto
parava 50 ms (crítico 110 ms). Num combo de quatro acertos dava **~340 ms
de jogo parado dentro de 1,5 s — 23% do tempo**. E o `Tremor`, a 42 px/s,
durava 107 ms: os abanões encavalitavam-se.

Regra nova, em constantes com nome (`HITSTOP_*` / `TREMOR_*` no
`koliani.gd`): **o balanço não mexe na câmara nem pára o tempo**; só a
ligação tem peso, e o peso é curto. `Tremor.DECAIMENTO` 42 → 70.

## "Quando salta vemos alguns frames acima da cabeça dela"

Duas causas, as duas medidas:

1. O atlas do Shadowblade foi recortado de uma imagem de apresentação e
   trouxe as **guias do cartaz**: uma faixa azul-escura chapada (cor
   `(22,25,38)`) a atravessar células inteiras, desenhada *por trás* das
   figuras, e guias tracejadas mais finas. Como encostam à figura, nem o
   `apagar_linhas` nem o `limpar_celula` as apanhavam. Entraram
   `apagar_faixas` (apaga **pela cor dominante**, para o cabelo desenhado
   por cima sobreviver) e `apagar_riscos`, mais duas regras no
   `limpar_celula`.
2. **A fila do salto não está na grelha de 128** — o mesmo defeito da
   corrida. Os centros medidos estão a 326, 459, 588, 720, 862 e 988: passo
   de ~135. E duas dessas poses (720 e 862) estão mesmo **sem cabeça** no
   atlas — o recorte de origem cortou-as. Eram elas que apareciam a meio do
   salto. Saíram da tabela; `jump` fica com as duas poses inteiras e a
   queda passa a usar a pose de queda da fila do salto duplo.

Conferido com `tools/RigKoliani.tscn` e com uma varredura das 13 tiras:
**zero componentes soltos acima da cabeça em qualquer frame**.

---

# FEITO — softlock do portal (4 set 2026, `712137f`)

Medido, não adivinhado. `tools/verifica_portais.gd` percorre os 100 níveis
**com o índice real de cada um** — a jornada é semeada com
`hash("jornada4|idx")`, portanto carregar a cena com índice 0 gera outro
nível e a medição não vale nada (foi o primeiro erro desta análise).
Resultado: **7 das 36 chegadas de portal punham o corpo dela (20×44) dentro
da geometria** — n32, n59, n75, n81, n90, n91, n93. Os spawns de início de
nível estavam todos bons (0 em 100).

A correcção está no `portal.gd`, onde vale para todos os portais:
`SUBIDA` 6→20 px (sobravam 4 px acima da plataforma) e `_lugar_livre()`, que
consulta a forma contra a camada do mundo e procura o livre mais próximo —
a subir, depois de lado, em passos de 10 px. A ferramenta sai != 0 se alguma
voltar a entalar.

---

# Pendências antigas que sobrevivem (detalhe)

0. **Laser roxo do pack Wenrexa — a meio.** O pack
   [`wenrexa/laser2020`](https://wenrexa.itch.io/laser2020) é **CC0, grátis,
   uso comercial, sem crédito obrigatório** e já está descarregado em
   `assets/sprites/incoming/wenrexa/laser2020/Laser Sprites/` (66 PNGs
   soltos, `01.png`..`66.png`; o demo Windows foi apagado). O Paulo escolheu
   **o último da primeira fila da imagem de capa** — a capa mostra 10 por
   linha, portanto é o **10.º sprite**: o cometa MAGENTA/roxo de cauda
   comprida. Falta: confirmar que a ordem da capa bate certo com a numeração
   dos ficheiros, recortar e apontar o projéctil para ele. Isto casa com o
   pedido nº 4 da fila ("não gosto do estilo do projétil dos mísseis, mude o
   recurso e coloque roxo com brilho").
1. **Escolher mecânicas do catálogo.** O Paulo deixou uma lista enorme de
   mecânicas em [`docs/mecanicas_catalogo.md`](mecanicas_catalogo.md)
   (chefes, coletáveis, mobilidade, game feel, plataformas, perigos,
   combate, puzzles, estrutura de fase). **Ele define as prioridades** —
   perguntar antes de implementar seja o que for daí.
2. **Portal animado do fim de nível: BLOQUEADO por licença.** O pack pago da
   Frostwindz está em `assets/sprites/incoming/frostwindz/` e o recorte
   sai com `python tools/gerar_fx_portal_balas.py`, mas a licença dele
   proíbe redistribuir os ficheiros e este repo é **público** — por isso a
   `Porta.tscn` ficou com o vórtice desenhado por código. Se o repo passar
   a privado (ou houver acordo com a Frostwindz), é só apontar a `Porta`
   para `props/portal_fim.png`. Detalhe em `incoming/LICENSES.md`.
3. **Licença do pack das balas por confirmar.** O `500 Bullet 24x24 Free`
   não traz ficheiro de licença nenhum — só PNGs. Confirmar os termos na
   página do itch.io de onde veio.
4. **O glow do golpe não foi visto em jogo.** Os testes e o smoke-test
   passam, mas não se chegou a tirar uma screenshot da Koliani a atacar
   depois de os efeitos saírem — confirmar que o `COR_GLOW_GOLPE` (roxo
   escuro, `koliani.gd`) está no ponto certo e não subtil demais.
5. Continua tudo o que estava pendente das sessões anteriores (ver o resto
   deste ficheiro e `docs/progresso_agente.md`).

---

# FEITO — tiros de energia novos + espada sem efeitos (4 set 2026)

- Os projécteis da Koliani voltaram ao **roxo** e passaram a usar o pack
  **"500 Bullet 24x24 Free"**. O tiro básico **sorteia uma de três formas a
  cada disparo** — dardo, seta e risco, as que o Paulo escolheu (bloco
  lavanda do `Part 2C`) — e são direccionais: apontam para onde vão.
  Zeriko ficou com um anel grosso e o Kamehameha com um flare espetado, de
  propósito com formas diferentes para se ler de quem vem o tiro.
- **Espada sem efeitos**: saíram os dois arcos de luz que varriam, o rasto
  em `Line2D` e o smear que esticava o sprite; ficou só um **glow roxo
  escuro** discreto (`COR_GLOW_GOLPE`). O "pop"/squash que ainda deformava
  o sprite passou a estar atrás do guarda `RIG_PIXEL`.
- `tools/gerar_fx_portal_balas.py` faz os recortes;
  `tools/shot_projeteis.gd` é a bancada para os ver lado a lado.

---

# ⚠ FILA DO PAULO (por ordem que ele deu)

## FEITO nesta sessão

- ✅ **Koliani mostra o equipamento** (arma/armadura) — por troca de paleta.
- ✅ **Menus de arma/armadura em carrossel**, com preview e stats/diferenças.
- ✅ **PRIORIDADE: o rig "Shadowblade" (arte dele) é a Koliani principal.**

## FEITO — a faixa "SKILL" de volta, a azul (4 set 2026)

> *"O ícone de ganhar novas skills, meta como estava inicialmente, letras a
> azul e um brilho a dizer skill."*

A placa tinha sido removida a 2 set (commit `4c78f1c`) porque ele achou que
lia como uma caixa solta em cima das plataformas. Está reposta em
`scripts/coletavel.gd::_faixa_skill`, igual à original mas com a paleta
passada de verde-água para AZUL — as constantes `COR_LETRAS`/`COR_BORDA`/
`COR_BRILHO`/`COR_LUZ` no topo do ficheiro são o sítio para afinar o tom.
O brilho continua aditivo, para acender por cima do cenário escuro.

---

## FEITO — o rig Shadowblade a sério (4 set 2026)

Três queixas dele sobre o boneco novo, todas resolvidas:

> *"Parece que tem algum frame drop e duplica kolianis."*

A ferramenta antiga deitava fora a grelha do atlas e procurava as figuras por
componentes ligados. Como a arte de células vizinhas se toca, saíam **frames
com duas Kolianis** e frames com meio corpo — e um frame de ataque SEM
personagem nenhuma (a célula que só tem o raio magenta). É isso que se lê
como frame drop. Agora `tools/importar_rig_shadowblade.py` usa a grelha real
(8×5 de 128×160, a mesma do `.tres` que veio no pack), limpa o transbordo do
vizinho célula a célula e ancora tudo pela **mediana do tronco** + linha do
chão, sem recentrar figura a figura (era isso que fazia a personagem tremer).

A **linha da corrida** é o caso feio: cada pose está desenhada DUAS VEZES com
~35 px de desvio e as cópias tapam-se. As cinco janelas de `run1..run5` na
tabela `FRAMES` foram medidas à mão sobre a cópia que ficou inteira; a 6.ª
pose fica cortada pela margem do atlas e perde-se. **Se o Paulo reexportar o
atlas com a linha da corrida espaçada, é só acrescentar uma linha à tabela.**

Do lado do código, `koliani.gd` deixou de deformar o sprite: a animação
procedural (balanço da corrida, inclinação, "respirar" parado, esticão do
salto) era feita para o rig vectorial e, num sprite de pixel-art com filtro
Nearest, escalar/rodar continuamente faz os pixéis saltarem. Fica só o que é
transitório (squash de aterragem, pop e smear do golpe) — ver `RIG_PIXEL`.

> *"Nos combos de ataque faz sempre a mesma animação."*

A linha de ataque do atlas tem quatro poses diferentes e estavam todas na
mesma tira. Agora são quatro tiras: `attack` (corte descendente), `attack2`
(arco roxo por cima), `attack3` (estocada + raio, com o feixe composto por
cima do corpo) e `attack4` (investida rasteira). O `_iniciar_ataque` já conta
o rig "shadowblade" como tendo combo.

> *"Pendurada numa parede esquerda aparece agarrada no lado direito."*

As poses de parede foram desenhadas com a parede à ESQUERDA dela, ao
contrário da convenção "virada à direita" do resto do rig. `_flip_sprite()`
inverte o espelho quando a animação a desenhar é `wallslide`/`borda`
(`PAREDE_ESPELHADA`).

Ferramenta nova para conferir: **`tools/RigKoliani.tscn`** — todos os estados
lado a lado, dentro do jogo, com a linha do chão e a pose de parede
espelhada.

```bash
"...Godot..." --window --screen 1 res://tools/RigKoliani.tscn -- user://rig.png
```

---

## POR FAZER — pedidos "secundários" (ele próprio classificou assim)

Ele disse: *"meta os pedidos que fiz como secundários e dê prioridade a
meter o asset shadowblade"*. O Shadowblade está feito; **isto é a fila.**

### 1. Bug — softlock no primeiro portal
> *"Quando apanhamos o primeiro portal, onde nascemos após apanhar o portal
> é entre 2 plataformas e a Koliani fica presa."*

É o pior da lista (tranca o jogador). Ver `scenes/actors/Portal.tscn` /
o script do portal e onde o `gerador_corredor.gd` põe o destino. O ponto de
saída tem de ser validado contra a geometria — há já
`tools/verifica_alcance.gd` para medir alcance, e o mesmo raciocínio serve
para "há chão por baixo e espaço por cima".

### 2. Sons
> *"Faça um set de sons para a koliani quando faz animações, ataques, etc.
> Faça com que os mobs façam sons também apropriados ao tipo de monstro."*
> *"Continuo sem gostar do som da espada, dos mísseis."*

`tools/gerar_audio.py` sintetiza os `.wav`; os SFX reais CC0 estão
creditados em `assets/audio/CREDITS.md`. A espada e os mísseis já foram
refeitos duas vezes e ele continua a não gostar — desta vez ir buscar
samples reais em vez de sintetizar.

### 3. Música
> *"A música do Nível 32 é esquisita e tem vários cortes, troque."*
> *"Adorei o final da música do Nível 38, se conseguir mais músicas assim
> com tom de rock perfeito."*

Duas coisas: **substituir a do 32** e **usar a do fim do 38 como
referência** (rock) para as próximas. Ver `Musica` (autoload) e as camas por
bioma.

### 4. Projéteis e aura
> *"Não gosto do estilo do projétil dos mísseis, mude o recurso e coloque
> roxo com brilho."*
> *"Faça uma aura roxa brilhante à volta da Koliani."*

Os VFX de projétil vêm do pack bdragon1727 (licença OK). A aura: já existe
`Sprite/LuzAura` (PointLight2D) no `Koliani.tscn` — é ligá-la e afiná-la.

### 5. Escuridão dos mapas
> *"O jogo está um bocado escuro no geral, coloque candeeiros ou lâmpadas a
> acompanhar os níveis, algo que dê alguma luminosidade aos mapas."*

Candeeiros/tochas como decoração **com luz própria** ao longo do percurso.
`tools/gerar_deco.py` faz os props; a luz por nível vem de
`tools/afinar_atmosfera.py`. **Atenção à ordem do pipeline** (ver abaixo).

### 6. Escudo
> *"Tente meter um escudo melhor e quando usamos o escudo fazer um escudo de
> energia roxo brilhante em volta do escudo normal."*

`Sprite/Escudo` no `Koliani.tscn` (polígonos vectoriais) — hoje só aparece
no rig "codigo". Com o Shadowblade é preciso decidir onde encaixa.

### 7. UI
> *"Melhore o UI, o Indicador de Nível, etc, vá buscar assets free."*

Luz verde permanente para descarregar assets grátis (`tools/baixar_packs_itch.py`).

### 8. Vidas
> *"Aumente a quantidade inicial de vidas para 5, e cada vez que passamos num
> nível aumente 1 vida."*

`EstadoJogo` (vidas). Pedido simples — provavelmente o mais rápido da lista.

### 9. MECÂNICAS — o pedido grande
> *"Joguei até Nível 37 e acho que o jogo tem poucas mecânicas, analise
> outros jogos e faça muito mais mecânicas. E mude o raciocínio: em vez de
> ir adicionando mais mecânicas e ir misturando e pôr mais quantidades em
> níveis mais altos, tente pôr uma mecânica nova a cada nível, e aumente a
> dificuldade das mecânicas à medida que o nível aumenta."*

**Uma mecânica nova por nível, 100 níveis.** É uma reformulação de design,
não um patch: hoje há ~12 mecânicas que se repetem e se misturam. Vale a
pena escrever um `docs/mecanicas_por_nivel.md` (tabela nível→mecânica→
parâmetro de dificuldade) ANTES de codar, e mostrar-lha.

---

# O que se fez nesta sessão (4 set 2026)

## 1. A Koliani mostra o que tem vestido — `44fa613`

O rig traz a lâmina e as placas pintadas dentro de cada frame, em sítios
diferentes por frame; pôr o nó `Arma` por cima dava duas espadas (foi por
isso que a sessão anterior o desligou). **A saída foi trocar a PALETA**:
o rig usa duas rampas de cinzento separadas — os médios são o fio da lâmina
e o rasto do golpe, os escuros são as placas do peito/ombros/saia.
`assets/shaders/equipamento.gdshader` reescreve cada rampa na cor do item
guardando a posição na rampa (o sombreado sobrevive), nos 18 estados e sem
tabelas de posição. `tools/verificar_paleta_rig.py` é a rede de segurança.

> ⚠ **Isto está escrito para o rig "cavaleiro"** (`RIGS_COM_PALETA` em
> `koliani.gd`). Com o Shadowblade activo **o shader já não apanha nada** —
> as rampas dele são outras. Falta ler as rampas do Shadowblade (a lâmina é
> roxa e brilha) e acrescentá-las, senão o pedido do equipamento regride.
>
> **Investigado a 4 set (Jensath/Luís) — NÃO é só "ler as rampas".** O
> `koliani_cavaleiro` foi desenhado (ou preparado) de propósito com duas
> rampas de cinzento EXCLUSIVAS (nada mais no rig usa essas cores) — é
> isso que torna a troca de paleta possível. O Shadowblade veio de uma
> imagem de concept art com sombreado contínuo: amostrei os PNGs por
> HSV (matiz/saturação) à procura de uma faixa isolável para a lâmina e
> para a armadura, e **não há separação limpa** — o roxo da lâmina cai na
> mesma faixa que o cabelo e a capa, e a "armadura" cinzenta nem tem uma
> zona de baixa saturação que se distinga do resto. Trocar por cor
> (exata ou por faixa HSV) vai sempre apanhar a personagem toda ou nada.
> Só resolve com **máscara manual por frame** (marcar à mão os pixéis da
> lâmina/armadura, ~12-15 frames) ou pedindo para a próxima exportação já
> vir com a lâmina/armadura numa rampa de cor exclusiva, como no
> cavaleiro. Por agora fica por implementar — o Luís preferiu aceitar a
> limitação a fazer a máscara à mão sem confirmar primeiro com o Paulo.

## 2. Menus de equipamento em carrossel — `dcfaa93`

Mesma forma do `SeletorNiveis`: um cartão por item, setas, arrastar, som
"carrossel", e a **Koliani dentro do cartão** a usar o item. Além dos
números vai a **diferença** para o equipado ("+20 DMG", verde/vermelho).
Corrigido de caminho: as duas tiras não têm a mesma célula (`armas.png` é
640×32 = 20 lâminas de 32×32, `armaduras.png` é 270×26 = 15 de 18×26) e os
cartões cortavam as duas a 18×26 — as armas saíam em pedaços.
`tools/shot_equip.gd` fotografa o ecrã (**precisa de janela**).

## 3. O rig Shadowblade — `40dea83`

**O atlas não se corta pela grelha do `.tres`.** Foi recortado de uma
imagem de apresentação e ficou com: passo entre figuras diferente por
estado (o `idle` anda de 128 em 128, o `run` de ~153); linhas horizontais do
fundo a atravessar a folha, que **colavam as figuras** umas às outras; as
paredes de pedra dos frames de encostar; e figuras descentradas.

`tools/importar_rig_shadowblade.py` limpa isso e procura as figuras por
componentes ligados. **A linha 2 do atlas (o `attack`) tem cortes à mão** —
o rasto do golpe liga tudo e nem a análise pelas pernas separa, porque o
chão da imagem de origem também ficou desenhado. São 33 figuras (o `.tres`
dizia 34: o `crouch` só tem duas poses).

**O que o atlas NÃO tem** (para uma versão futura que o Paulo faça): `roll`,
`dash`, `hurt`, `defesa`, `borda`, `aterrar`, `morte` e os golpes 2/3/4 do
combo. O jogo aguenta (`_atualizar_anim` pergunta `has_animation`), mas cada
tira nova entra só por acrescentar uma linha ao `ORDEM` da ferramenta.

---

# Pendente de antes (não perder de vista)

1. **Playtestar.** 100 níveis e 34 rigs de chefe nunca foram jogados de fio
   a pavio. `tools/testar_chefe.gd` e `tools/folha_de_contacto.gd` (**as
   duas precisam de janela**: `--window --screen 1`).
2. **A curva do 2.º acto** (níveis 31+) espalha-se por 70 níveis; os pontos
   de partida (dificuldade 0.72, 14000 px) continuam a ser palpite.
3. **O nível 100 não é um chefe normal**: é um duelo de espada, sem poderes,
   sem HUD e sem barra de vida. Está montado como `ChefeGenerico` até ser
   feito a sério.
4. **Arte própria das regiões novas** — `gerar_terreno.py` só conhece 6
   biomas de terreno.
5. **Sino Vivo (n11) é um baú-mímico e Vyrak (n15) um morcego gigante** —
   escolhas por confirmar com o Paulo.
6. CI do APK Android falha desde o run 264.

# Ordem obrigatória do pipeline dos níveis

```bash
python tools/gerar_niveis_31_100.py     # escreve os .tscn (e RETRATO_CHEFE)
"...Godot..." --headless --import
python tools/afinar_atmosfera.py        # só DEPOIS: reescreve o bloco Atmosfera
```

Ao contrário, o gerador apaga a atmosfera afinada.

# Gotchas desta máquina (não voltar a descobrir)

- **Screenshots não saem em `--headless`** (renderer dummy). Usar
  `--window --screen 1` — janela real no 2.º monitor.
- Em `--script` os autoloads **não existem como identificador**; buscá-los
  pela árvore (`get_root().get_node("/root/EstadoJogo")`), como fazem o
  `folha_de_contacto.gd` e o `shot_equip.gd`.
- `ERROR: There is no animation with name 'idle'` vinha do `Koliani.tscn`, que
  declarava `animation = &"idle"` num `AnimatedSprite2D` sem `SpriteFrames`
  (quem os monta é o `_montar_frames`). Removido a 4 set 2026.
- **Heredocs longos pelo Bash tool corrompem-se** — escrever o ficheiro com
  a ferramenta de escrita, ou pôr o script no scratchpad e correr o ficheiro.
- Os `.json` de i18n **não estão por ordem alfabética** (a ordem agrupa por
  ecrã) — não os re-ordenar ao acrescentar chaves.
- `ffmpeg` existe via `pip install --user imageio-ffmpeg`.
- **NUNCA `git add -A`** — o `incoming/` tem packs enormes.
