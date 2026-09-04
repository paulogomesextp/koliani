# Retomar aqui — 4 de setembro de 2026

> **LEIA PRIMEIRO.** O topo é a **fila de pedidos do Paulo por fazer**; o
> fundo é o que já ficou feito nesta sessão.

---

# ⚠ POR FAZER — o que ficou pendente (4 set 2026, fim de sessão)

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
