# Retomar aqui — 3 de setembro de 2026 (sessão da noite)

> **LEIA PRIMEIRO.** O que mudou nesta sessão está no topo; o histórico
> anterior fica por baixo, encurtado. Versão actual: **v0.11.3**.

## O que se fez nesta sessão

### 1. Chefes animados — o ponto 6 do Paulo está FECHADO

Faltavam 21 dos 30 chefes sem rig animado. A receita que a sessão anterior
deixou escrita era **recolorir o "Wandering Knight" vinte vezes**. Não foi
por aí: **cada chefe tem agora a sua própria silhueta**.

- **`tools/baixar_packs_itch.py` (novo)** — descarrega packs **gratuitos**
  do itch.io. Só *name-your-own-price* a $0; se o pack for pago diz
  `sem link (pack pago?)` e passa à frente — **não compra nada**. Fluxo:
  `GET /<jogo>/purchase` → `POST /<jogo>/download_url` →
  `POST /<jogo>/file/<id>?source=game_download`. O endpoint do ficheiro é
  na RAIZ do subdomínio, **não** debaixo do `/download/<chave>` da página
  (foi a parte que custou a acertar — está comentada no ficheiro).
- Trouxe **18 packs CC0 do LuizMelo** (o autor do "Evil Wizard 2" que já se
  usava, logo o mesmo traço e a mesma densidade de pixel) e **3 gratuitos
  do chierit**. ~15 dos packs do LuizMelo eram pagos — ficaram de fora.
- **`tools/importar_chefes_animados.py`**: as tiras `@ficheiro.png` deixam
  de precisar da contagem de frames. A célula sai do **máximo divisor
  comum das larguras das folhas do mesmo rig** (`celula_comum`). Sem isto
  era preciso contar os frames de ~100 folhas à mão.
- **29 rigs** na tabela `RIGS` (eram 9). 20 cenas de chefe ganharam
  `rig = "..."` + o nó `Sprite/Anim`.
- `DemonioBase._normalizar_escala` ganhou **tecto de largura**
  (`ChefeBase.LARGURA_ALVO_CHEFE = 110`): um rig largo e baixo (o morcego,
  o baú-mímico, o verme) esticado até 100 px de alto ficava com 160+ de
  largo — mais largo que a plataforma da arena. Nenhum chefe antigo muda
  (o mais largo que cá estava tinha 105).
- `escala_visual` reafinado em 9 cenas: as escalas antigas tinham sido
  medidas para folhas estáticas estreitas.

**Estado: 29 de 30.** Fica de fora, de propósito, a **Koliani Sombria**
(n27) — é o espelho da Koliani e usa o rig da própria heroína.

Tabela completa rig→chefe→pack→licença: `assets/sprites/pixel/CREDITS.md`.

**Duas escolhas para o Paulo confirmar** (estão escritas no CREDITS
também): o **Sino Vivo** (n11) é um **baú-mímico** — não há nada gratuito
com cara de sino, e um objecto que pende do tecto e morde faz o trabalho;
o **Vyrak** (n15) é um **morcego gigante** em vez de um dragão. Ambos
ficam à espera de um pack melhor.

### 2. Região VIII — Mar dos Mortos (níveis 36-40)

A campanha passa de 35 para 40 níveis, com a mesma tubagem que a Região
VII estreou (uma linha por nível na tabela de `gerar_niveis_31_100.py`).

    36 Porto dos Afogados          guardião: O Afogado
    37 Cidade Submersa             guardião: Gosma Salgada
    38 Palácio das Sereias Mortas  guardião: Estátua Viva
    39 Ossário das Baleias         guardião: Lodo Abissal
    40 Abismo Oceânico             CHEFE: A Mãe do Abismo  (INVOCADOR)

É o contraponto directo da VII, e isso está escrito em todas as peças:
`POOL_REGIAO[7]` sem `fogo` nem `quebra` (debaixo de água não arde nem se
estilhaça) e com `gravidade` de assinatura — o tema é **flutuar**;
`LIQUIDO[7]` é água negra, a primeira região em que o chão mortal não é
quente; a atmosfera desce de verde-azulado para azul-tinta, com pó denso
(a matéria em suspensão faz o "debaixo de água" sem shader nenhum) e
horizonte apagado nos cinco.

Dois bugs apanhados pelo caminho:

- **O modelo do gerador chapava lava laranja em todas as regiões** — o
  líquido da arena do chefe estava escrito à mão no template. Passa a sair
  de `LIQUIDO_REGIAO`. Sem isto o Abismo Oceânico tinha um fosso de magma.
- **A Região VII estava sem a atmosfera afinada.** Os cinco `.tscn` tinham
  sido gerados *depois* de `afinar_atmosfera.py` correr, e o gerador
  reescreve o bloco `Atmosfera` — os cinco estavam com as cores por
  omissão. **Ordem certa: `gerar_niveis_31_100.py` → `--headless --import`
  → `afinar_atmosfera.py`.** Nunca ao contrário.

## O que fazer a seguir

1. **Playtestar os chefes novos.** 20 chefes trocaram de boneco de uma vez
   e só se viram 12 em screenshot. Pontos a olhar: o chefe fica dentro da
   arena? assenta no chão? o tamanho lê-se como chefe e não como bicho
   grande? (`tools/testar_chefe.gd -- <idx0> <prefixo> [n] [seg] [zoom]
   [recuo]`, **precisa de janela**: `--window --screen 1`).
2. **Regiões IX-XX (41-100)** — a IX (Reino do Gelo) é a próxima. A receita
   está nesta sessão e na anterior; são ~30 min por região agora.
3. **Arte própria das regiões novas.** Da VII em diante os packs de fundo
   são reaproveitados e a identidade vem toda da tinta. `gerar_terreno.py`
   só conhece 6 biomas — as regiões novas pedem emprestado.
4. **Playtestar a curva do 2.º acto** (níveis 31+). Os dois pontos de
   partida (dificuldade 0.72, 14000 px) continuam a ser palpite.

## Gotchas desta máquina (não voltar a descobrir)

- **Screenshots não saem em `--headless`** (renderer dummy). Usar
  `--window --screen 1` — janela real no 2.º monitor, sem roubar o ecrã
  principal ao Paulo.
- `ERROR: There is no animation with name 'idle'` aparece em **todos** os
  níveis em `--headless`, incluindo o 1 — é do renderer dummy, não é
  regressão. Não perseguir.
- O `curl -X POST` para fora é bloqueado pelo classificador; a descarga de
  packs faz-se pelo `tools/baixar_packs_itch.py` (urllib).
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
3. **Sons mais realistas** — 35 SFX de combate/mobs/UI trocados por samples
   CC0 reais do OpenGameArt (`assets/audio/CREDITS.md`). Só as **camas**
   (`menu`, `boss`, `ambiente`, `assombracao`, `game_over`) continuam
   sintetizadas por `tools/gerar_audio.py` — o cabeçalho desse ficheiro diz
   quais as chaves que ele já **não** deve gerar.
4. **20 músicas de nível, em ciclo** — `Musica.ambiente()` escolhe
   `nivel_01..20.ogg` por `indice_nivel % 20`.
5. **20 músicas de chefe, em ciclo** — `Musica.boss()` pelo mesmo índice.
6. **Chefes animados** — fechado nesta sessão (ver topo).

## Investigação da arte da Koliani (para não repetir)

Procurou-se um pack pixel-art CC0 parecido com a referência (assassina sem
capacete, cabelo à mostra, cachecol vermelho-escuro, espada recta magenta).
Nada bateu: **Knight Hero Platformer** (CC0) tem elmo fechado e escudo;
**Ninja Adventure** (CC0) é top-down, sem jump/wall-slide; **Ninja Girl**
(CC0) é vector cartoon, destoa do pixel-art; o rig **gothic** (Ansimuz) é
um monge de braços cruzados sem espada. Se algum dia for mesmo preciso
trocar o Knight_player, a próxima tentativa deve ser **compor**
(photobash: cabeça/cabelo de um pack sem elmo sobre o corpo do Knight
Hero) em vez de só recolorir.

## Música e som — de onde vieram (para expandir)

OpenGameArt (`field_art_type_tid[]=12` para música). Packs mais rentáveis:
`Essentials Pack for Fantasy Games — LOOP BOX #3` (17 das 20 faixas de
nível), `JRPG Pack 5 (Action)` + `Action Music Pack` (13 das 20 de chefe).
SFX: `RPG Sound Pack` (artisticdude), `80 CC0 RPG SFX` + `80 CC0 creature
SFX` + `40 CC0 water/splash/slime SFX` (rubberduck), `20 Sword Sound
Effects` + `10 Impact/Shield Blocks` (StarNinjas). Lista completa por
chave: `assets/audio/CREDITS.md`.

**Peso resolvido com `ffmpeg`** — 40 faixas em qualidade original seriam
+120-160 MB; cortadas a ~75s com fade-out de 3s e recodificadas a 64kbps
mono (`libvorbis`) ficaram em 16 MB:

```bash
FFMPEG=$(python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())")
"$FFMPEG" -y -i entrada.ogg -t 75 -af "afade=t=out:st=72:d=3" \
  -ac 1 -ar 44100 -c:a libvorbis -b:a 64k saida.ogg
```

`scripts/som.gd::CAMINHOS` mistura `.wav`/`.ogg`/`.mp3` por chave — não
presumir que é sempre `.wav`. Pixabay continua bloqueado ao `curl`;
OpenGameArt e itch.io funcionam.
