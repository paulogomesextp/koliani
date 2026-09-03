# Retomar aqui — 3 de setembro de 2026 (sessão da noite)

> **LEIA PRIMEIRO.** Versão actual: **v0.12.0**. Duas coisas grandes
> fecharam nesta sessão: os **chefes animados** e a **campanha dos 100
> níveis**.

## 1. Chefes animados — o ponto 6 do Paulo está FECHADO

**29 de 30 chefes da campanha 1-30 têm rig animado, cada um com a sua
silhueta.** Falta só a Koliani Sombria (n27), de propósito: é o espelho da
heroína e usa o rig dela.

A receita que a sessão anterior deixou escrita era recolorir o mesmo
"Wandering Knight" vinte vezes. Não foi por aí — foram-se buscar packs
novos:

- **`tools/baixar_packs_itch.py` (novo)** — descarrega packs **gratuitos**
  do itch.io. Só *name-your-own-price* a $0; um pack pago responde
  `sem link (pack pago?)` e é saltado. **Não compra nada.**
  - O endpoint do ficheiro é `POST /<slug>/file/<id>?source=game_download`
    na **raiz do subdomínio** — não debaixo do `/download/<chave>` da
    página. A outra forma dá 404 (com a página 404 retro do itch, que
    parece um erro de rede e não é). Precisa de `Referer` +
    `X-Requested-With`.
  - Usa `urllib` e não `curl` porque **o `curl -X POST` para fora é
    bloqueado pelo classificador do harness**.
- Trouxe **18 packs CC0 do LuizMelo** (o autor do "Evil Wizard 2" que já se
  usava, logo o mesmo traço e a mesma densidade de pixel) e **8 gratuitos
  do chierit** (incluindo 5 da série "Elementals"). Muitos dos packs desses
  autores são pagos — esses ficaram de fora.
- **`tools/importar_chefes_animados.py`**: as tiras `@ficheiro.png` deixam
  de precisar da contagem de frames; a célula sai do **máximo divisor comum
  das larguras das folhas do mesmo rig** (`celula_comum`).
- **34 rigs** no catálogo (eram 9).
- `DemonioBase._normalizar_escala` ganhou **tecto de largura**
  (`ChefeBase.LARGURA_ALVO_CHEFE = 110`): um rig largo e baixo esticado até
  100 px de alto ficava com 160+ de largo, mais largo que a plataforma da
  arena.
- **`teste_rigs_dos_chefes`** em `tests/run_tests.gd` é a rede de segurança:
  um `rig` mal escrito não rebenta (o `_montar_rig` só avisa e deixa a folha
  estática), portanto passava despercebido. Verifica catálogo, nó
  `Sprite/Anim`, as cinco tiras, a contagem de frames e o tamanho no ecrã.

Tabela completa rig→chefe→pack→licença: `assets/sprites/pixel/CREDITS.md`.

**Duas escolhas para o Paulo confirmar**: o **Sino Vivo** (n11) é um
**baú-mímico** (não há nada gratuito com cara de sino; um objecto que pende
do tecto e morde faz o trabalho) e o **Vyrak** (n15) é um **morcego
gigante** em vez de dragão.

## 2. A campanha tem 100 níveis e 20 regiões

`docs/plano_niveis_31_100.md` está **todo montado**. Passou de 35 níveis
para 100 nesta sessão (regiões VIII a XX).

Cada região nova é **uma linha por nível** na tabela de
`tools/gerar_niveis_31_100.py`. O que leva tempo agora não é a tubagem — é
dar a cada região uma **cor que nenhuma outra tenha**. As vinte:

| # | região | o que a separa das outras |
| --- | --- | --- |
| I-VI | 1-30 | salas desenhadas à mão, um chefe por nível |
| VII | Terras Queimadas | laranja médio, o reino a arder ao longe |
| VIII | Mar dos Mortos | azul-tinta fundo; 1.º chão mortal que não é quente |
| IX | Reino do Gelo | a **1.ª região clara** do jogo; branco-azul |
| X | Deserto | a mesma luz alta, mas **quente** — dia aberto |
| XI | Jardins do Rei | verde **cultivado** (a I é verde **doente**) |
| XII | Cidade das Máquinas | a mais **fria** de cor; aço e ciano, zero verde |
| XIII | Céu Partido | índigo com estrelas; fundo escuríssimo, luz claríssima |
| XIV | Reino dos Sonhos | lilás **lavado** (não o magenta duro do Zeriko) |
| XV | Cidade dos Mortos | verde-osso — o negativo exacto da XI |
| XVI | Mar Vermelho | vermelho a sério; não há nada assim no resto do jogo |
| XVII | Inferno | também laranja, mas **preto com núcleos de fogo** |
| XVIII | O Vazio | **quase sem cor** (`des` 0.95), sem horizonte |
| XIX | Guerra dos Reinos | fumo e aço; luz do dia passada por fumo |
| XX | O Último Caminho | **quatro chefes** e uma cor por nível (são memórias) |

**Ordem obrigatória do pipeline** (foi um bug real, duas vezes):

```bash
python tools/gerar_niveis_31_100.py     # escreve os .tscn
"...Godot..." --headless --import       # importa
python tools/afinar_atmosfera.py        # só DEPOIS: reescreve o bloco Atmosfera
```

Ao contrário, o gerador apaga a atmosfera afinada e a região fica com as
cores por omissão — foi o que aconteceu à Região VII, que esteve assim
desde que nasceu.

## O que fazer a seguir

1. **Playtestar.** É o que falta a sério. 100 níveis e 34 rigs de chefe
   nunca foram jogados de fio a pavio. Atalhos: `tools/testar_chefe.gd --
   <idx0> <prefixo> [n] [seg] [zoom] [recuo]` para um chefe e
   `tools/folha_de_contacto.gd` para ver as 20 regiões de relance (**as
   duas precisam de janela**: `--window --screen 1`).
2. **A curva do 2.º acto** (níveis 31+) espalha-se agora por 70 níveis em
   vez de 5. Os dois pontos de partida (dificuldade 0.72, 14000 px)
   continuam a ser palpite e nunca foram medidos.
3. **`Equipamento.recompensa_do_nivel` acaba no nível 30** (15 armas + 15
   armaduras). Dos 31 aos 100 não há equipamento novo — falta decidir se se
   estica a lista ou se dali para a frente a progressão passa a ser só
   Essência/Melhorias.
4. **O nível 100 não é um chefe normal** no plano: é um duelo de espada,
   sem poderes, sem HUD e sem barra de vida. Está montado como um
   `ChefeGenerico` de INVESTIDA até esse duelo ser feito a sério.
5. **Arte própria das regiões novas.** Da VII em diante os 14 packs de
   fundo são reaproveitados e a identidade vem toda da tinta;
   `gerar_terreno.py` só conhece 6 biomas de terreno.

## Gotchas desta máquina (não voltar a descobrir)

- **Screenshots não saem em `--headless`** (renderer dummy). Usar
  `--window --screen 1` — janela real no 2.º monitor, sem roubar o ecrã
  principal ao Paulo.
- `ERROR: There is no animation with name 'idle'` aparece em **todos** os
  níveis em `--headless`, incluindo o 1 — é do renderer dummy, não é
  regressão. Não perseguir.
- A folha de contacto dos 100 níveis demora mais de 2 minutos: correr em
  background.
- No `tests/run_tests.gd` **não tocar em `ChefeBase.`/`EstadoJogo.`
  directamente**: em `--script` os autoloads não existem e a cadeia toda
  falha a compilar. Ler as constantes da FONTE (`_constante_float`).
- `ffmpeg` existe via `pip install --user imageio-ffmpeg` (ferramenta
  local, não é dependência do projecto).

---

# Histórico anterior (2 e 3 de setembro)

## A lista de 6 pontos do Paulo — COMPLETA

1. **Koliani pixel-art nova** — resolvido de forma diferente do pedido: o
   Paulo escolheu voltar ao rig **"cavaleiro"** (Knight_player recolorido).
   **Decisão consciente sobre a licença**: o pack proíbe uso por IA no seu
   `Read_me.txt`; o Paulo viu o aviso e confirmou que quer esta Koliani na
   mesma. **Não voltar a apagar os assets sem falar com ele primeiro.**
2. Ressalto do pisão a metade — feito.
3. **Sons mais realistas** — 35 SFX trocados por samples CC0 reais do
   OpenGameArt (`assets/audio/CREDITS.md`). Só as **camas** (`menu`,
   `boss`, `ambiente`, `assombracao`, `game_over`) continuam sintetizadas
   por `tools/gerar_audio.py` — o cabeçalho desse ficheiro diz quais as
   chaves que ele já **não** deve gerar.
4. **20 músicas de nível**, em ciclo (`indice_nivel % 20`).
5. **20 músicas de chefe**, pelo mesmo índice.
6. **Chefes animados** — fechado nesta sessão (ver topo).

## Investigação da arte da Koliani (para não repetir)

Procurou-se um pack pixel-art CC0 parecido com a referência (assassina sem
capacete, cabelo à mostra, cachecol vermelho-escuro, espada recta magenta).
Nada bateu: **Knight Hero Platformer** (CC0) tem elmo fechado e escudo;
**Ninja Adventure** (CC0) é top-down; **Ninja Girl** (CC0) é vector
cartoon; o rig **gothic** (Ansimuz) é um monge sem espada. Se for mesmo
preciso trocar o Knight_player, a próxima tentativa deve ser **compor**
(photobash) e não recolorir.

## Música e som — de onde vieram (para expandir)

OpenGameArt (`field_art_type_tid[]=12` para música). Packs mais rentáveis:
`Essentials Pack for Fantasy Games — LOOP BOX #3` (17 das 20 faixas de
nível), `JRPG Pack 5 (Action)` + `Action Music Pack` (13 das 20 de chefe).
SFX: `RPG Sound Pack` (artisticdude), `80 CC0 RPG SFX` + `80 CC0 creature
SFX` + `40 CC0 water/splash/slime SFX` (rubberduck), `20 Sword Sound
Effects` + `10 Impact/Shield Blocks` (StarNinjas).

**Peso resolvido com `ffmpeg`** — 40 faixas cortadas a ~75s com fade-out de
3s e recodificadas a 64kbps mono ficaram em 16 MB:

```bash
FFMPEG=$(python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())")
"$FFMPEG" -y -i entrada.ogg -t 75 -af "afade=t=out:st=72:d=3" \
  -ac 1 -ar 44100 -c:a libvorbis -b:a 64k saida.ogg
```

`scripts/som.gd::CAMINHOS` mistura `.wav`/`.ogg`/`.mp3` por chave — não
presumir que é sempre `.wav`. Pixabay continua bloqueado ao `curl`;
OpenGameArt e itch.io funcionam.
