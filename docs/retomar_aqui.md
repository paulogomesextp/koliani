# Retomar aqui — 4 de setembro de 2026

> **LEIA PRIMEIRO.** O topo é a **fila de pedidos do Paulo por fazer**; o
> fundo é o que já ficou feito nesta sessão.

---

# ⚠ FILA DO PAULO (por ordem que ele deu)

## FEITO nesta sessão

- ✅ **Koliani mostra o equipamento** (arma/armadura) — por troca de paleta.
- ✅ **Menus de arma/armadura em carrossel**, com preview e stats/diferenças.
- ✅ **PRIORIDADE: o rig "Shadowblade" (arte dele) é a Koliani principal.**

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
- `ERROR: There is no animation with name 'idle'` aparece em todos os níveis
  em `--headless` — é do renderer dummy, não é regressão.
- **Heredocs longos pelo Bash tool corrompem-se** — escrever o ficheiro com
  a ferramenta de escrita, ou pôr o script no scratchpad e correr o ficheiro.
- Os `.json` de i18n **não estão por ordem alfabética** (a ordem agrupa por
  ecrã) — não os re-ordenar ao acrescentar chaves.
- `ffmpeg` existe via `pip install --user imageio-ffmpeg`.
- **NUNCA `git add -A`** — o `incoming/` tem packs enormes.
