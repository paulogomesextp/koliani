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

1. ~~**Softlock do portal**~~ — **FEITO** (`712137f`), ver abaixo.
2. **Som e música** — ⬅ *é aqui que a próxima sessão pega.* Ver o
   levantamento já feito, logo a seguir a esta lista.
3. **Projécteis, luz e escudo** — aura roxa à volta dela
   (`Koliani.tscn → Sprite/LuzAura`, já existe, é ligar); laser roxo do
   Wenrexa nos projécteis (ver ponto 0 abaixo); candeeiros/tochas com luz
   própria ao longo dos níveis; escudo melhor + escudo de energia roxo.
4. **Infra** — CI do APK falha desde o run 264. Plano combinado: arranjar o
   CI, publicar o APK num Release de tag rolante (`android-latest`, a par do
   `win-latest`), e ligar o **GitHub Pages ao build Web** — o preset "Web"
   já é exportado pelo CI mas não é publicado em lado nenhum. O iPhone não
   tem caminho nativo grátis (Apple ID grátis expira em 7 dias e exige Mac;
   TestFlight exige os 99 €/ano), portanto a Web é a saída para iOS.
5. **UI, vidas, mecânicas** — UI + indicador de nível; vidas a começar em 5
   e +1 por nível (o mais rápido de todos, só `EstadoJogo`); e o pedido
   grande: uma mecânica nova por nível, que **começa pela tabela**
   `docs/mecanicas_por_nivel.md` para ele aprovar, não por código.
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

# BLOCO 2 (som) — levantamento já feito, começar por aqui

## Correcção a uma nota antiga: os SFX **já não são sintetizados**

`assets/audio/CREDITS.md` regista que a 3 set 2026 os SFX de combate, mobs e
UI foram trocados por **samples reais CC0 do OpenGameArt**. A espada
(`ataque`) vem do pack *20 Sword Sound Effects* do StarNinjas; o `lancar`
vem dos *80 CC0 RPG SFX* do rubberduck. Só as **camas** (`ambiente`, `menu`,
`boss`, `assombracao`, `game_over`) continuam sintetizadas por
`tools/gerar_audio.py`.

**Portanto o problema não é "sintetizado vs. real" — é a ESCOLHA da
amostra.** Não perder tempo a sintetizar nem a "ir buscar samples reais":
já são reais. É preciso ouvir alternativas e escolher melhor, com o Paulo a
decidir, para `ataque` (espada) e para os mísseis (`lancar` / `projetil`).
O mapa nome→ficheiro está em `scripts/som.gd`.

## A música do Nível 32: identificada

`scripts/musica.gd` escolhe a faixa por `indice_nivel % 20` (20 faixas de
nível + 20 de chefe, em ciclo — pedido dele a 3 set). Logo:

| Nível | índice | `% 20` | ficheiro | faixa |
| --- | --- | --- | --- | --- |
| 32 | 31 | 11 | `musica/niveis/nivel_12.ogg` | *Zwischenwelt* — Of Far Different Nature (CC-BY 4.0) |
| 38 | 37 | 17 | `musica/niveis/nivel_18.ogg` | *Waking the devil* — Alexander Ehlers (**CC0**) |

- **A trocar** é a `nivel_12.ogg`. O "tem vários cortes" de que ele se
  queixa é coerente com o processo: todas as faixas foram **cortadas a
  ~70-80 s com fade-out e recodificadas a 64 kbps mono** para caber no
  orçamento de espaço — nessa a emenda do loop deve estar audível. Vale a
  pena confirmar se o defeito é do corte (recortar melhor) ou da faixa
  (substituir de vez).
- **A referência de tom rock** que ele adorou é a `nivel_18.ogg`. Boa
  notícia: é **CC0** e vem do [Free Music Pack](https://opengameart.org/content/free-music-pack)
  do Alexander Ehlers, que tem mais material no mesmo registo — é por aí
  que se procuram as próximas.

## O resto do pedido dele, por fazer

- Set de sons para as **animações** dela (passos, salto, rolamento,
  aterrar), não só ataques.
- Sons **por espécie de monstro** — hoje há `demonio_ataque`, `garra`,
  `grito`, `praga` partilhados por todos.

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
