# Retomar aqui — 3 de setembro de 2026 (fim da sessão da noite)

> **LEIA PRIMEIRO.** Versão actual: **v0.12.0**, tudo em `origin/master`.
> A parte de baixo ("O QUE FALTA") são **dois pedidos do Paulo por fazer** —
> é por aí que se retoma.

---

# ⚠ O QUE FALTA (pedidos do Paulo, 3 set 2026)

Ele pediu quatro coisas. **Duas ficaram feitas** (a cadência do equipamento
e o retrato do chefe no carrossel — ver abaixo). **Estas duas não:**

## A) A Koliani tem de MOSTRAR o que está equipado

> *"Tente fazer como modelo da koliani no início do projeto, substituir a
> arma do modelo actual pelo asset da arma que estiver equipada, e a
> armadura igual ou pelo menos alterar a cor do modelo quando equiparmos
> outra armadura."*

Hoje **não mostra nada**: `koliani.gd::_aplicar_equipamento()` (~linha 406)
faz `_arma.visible = wi >= 0 and RIG == "codigo"`, e `RIG` é `"cavaleiro"`
desde que o Paulo escolheu esse rig. O mesmo em `_aplicar_visual_armadura()`
(~linha 423): `if RIG != "codigo": _armadura.visible = false`. Ou seja, os
dois nós existem e funcionam — só estão desligados no rig actual, porque as
tiras do "cavaleiro" já trazem espada e roupa desenhadas.

O que já está pronto para isto:

- `$Sprite/Arma` (Sprite2D, `hframes = 20`, tira
  `assets/sprites/pixel/gear/armas.png`) — o `frame` é
  `Equipamento.indice_arma(id)`. O nó já roda pelo punho (`offset` põe o
  punho na origem, ver `koliani.gd` ~linha 894).
- `$Sprite/Armadura` (peito/ombros/cinto/trim vectoriais) — recolorido por
  `Equipamento.cor_armadura(i)`.
- `Equipamento.cor_arma(i)` já alimenta o brilho do golpe, o rastro e a luz
  da lâmina, e **isso já funciona** no rig actual.

**Onde está a dificuldade** (é o que fez a sessão anterior desligar isto):
a lâmina do rig "cavaleiro" está **pintada dentro de cada frame**, em
posições diferentes por frame e por estado. Pôr o `Arma` por cima dá duas
espadas. As saídas possíveis, por ordem de esforço:

1. **Só a cor** (o "pelo menos" do pedido) — tingir o `Corpo` com
   `_tint_armadura()` (já existe e já é chamado) e dar mais peso à cor da
   arma no rim/brilho. É meia hora e cumpre metade do pedido.
2. **Apagar a lâmina do rig e desenhar a arma por cima** — passar
   `tools/importar_rig_koliani.py` a limpar os pixéis da espada nos frames
   (ela é sempre a mesma cor) e ligar o nó `Arma` com uma tabela de
   posição/rotação **por estado e por frame**. É o que dá o resultado que o
   Paulo quer, e é meio dia de trabalho.
3. **Voltar ao `RIG = "codigo"`** (o modelo do início do projecto, que ele
   citou) — aí tudo isto já funciona, mas perde-se a Koliani que ele
   escolheu. **Não fazer sem lhe perguntar.**

Recomendação: fazer o 1 já, mostrar, e perguntar-lhe se quer o 2.

## B) Menus de arma e de armadura em CARROSSEL

> *"Nos menus de arma e de escudo, fazer como selecção de níveis em
> carrossel, e dar uma preview da koliani com essa arma ou equipamento
> equipado e os stats que cada um dá."*

Hoje `scripts/seletor_equip.gd` (231 linhas) é uma **grelha 5x3 de
cartões**. Tem de passar a carrossel como o `SeletorNiveis`.

- **Modelo a copiar:** `scripts/seletor_niveis.gd` — `_montar_seta`,
  `_mover`, `_reposicionar`, `_atualizar_topo`, `CARTAO`/`PASSO`/`DUR`, o
  som `"carrossel"`, e as pastilhas de região no topo (aqui seriam
  pastilhas de tier, ou nada).
- **A preview da Koliani** é a parte nova. O mais barato que dá bom
  resultado: um `AnimatedSprite2D` com as tiras do rig actual (ver
  `koliani.gd::_montar_frames`, tabela `_KOLI_ANIMS_CAVALEIRO`) a tocar
  `idle`, com o `Arma` por cima a mostrar `frame = indice_arma` e o
  `modulate` do corpo a `Equipamento.cor_armadura(i)`. **Depende do ponto
  A**: se A ficar só na cor, a preview mostra a cor; se A fizer a arma a
  sério, a preview usa o mesmo código.
- **Os stats já estão calculados** e já aparecem nos cartões de hoje
  (`gear.stat.dmg`, `gear.stat.hp`, `gear.stat.armor`) — é só passá-los
  para o cartão grande, e vale a pena mostrar também a **diferença** para o
  que está equipado (+12 dano, −3% armadura), que é o que faz decidir.
- Cuidado: **a armadura indexa a tira por `Equipamento.celula_armadura(id)`
  e NÃO pela posição na lista** (a tira tem as 15 originais, só 10 estão em
  jogo). Já está corrigido no ficheiro actual — não voltar a trocar.

---

# O que se fez nesta sessão

## 1. Chefes animados — o ponto 6 da lista antiga está FECHADO

**29 de 30 chefes de 1-30 têm rig animado, cada um com a sua silhueta.**
Falta só a Koliani Sombria (n27), de propósito.

- **`tools/baixar_packs_itch.py` (novo)** — descarrega packs **gratuitos**
  do itch.io. Só *name-your-own-price* a $0; pago é saltado, **não compra
  nada**. O endpoint do ficheiro é
  `POST /<slug>/file/<id>?source=game_download` na **raiz do subdomínio**
  (não debaixo do `/download/<chave>`), com `Referer` +
  `X-Requested-With`. Usa `urllib` porque **o `curl -X POST` para fora é
  bloqueado pelo classificador do harness**.
- Trouxe 18 packs CC0 do LuizMelo e 8 grátis do chierit. **34 rigs** no
  catálogo (eram 9). Tabela rig→chefe→pack→licença em
  `assets/sprites/pixel/CREDITS.md`.
- `ChefeBase.LARGURA_ALVO_CHEFE` (110) é o tecto de largura: um rig largo e
  baixo escalado só pela altura saía mais largo que a plataforma da arena.
- **`teste_rigs_dos_chefes`** é a rede de segurança — um `rig` mal escrito
  não rebenta, só deixa a folha estática, e passava despercebido.

**Duas escolhas para o Paulo confirmar**: o **Sino Vivo** (n11) é um
**baú-mímico** e o **Vyrak** (n15) é um **morcego gigante**.

## 2. A campanha tem 100 níveis e 20 regiões

`docs/plano_niveis_31_100.md` está **todo montado**. Cada região nova é uma
linha por nível na tabela de `tools/gerar_niveis_31_100.py`; o trabalho a
sério é dar-lhe uma **cor que nenhuma das outras 19 tenha** (os 14 packs de
fundo estão gastos desde a VI, portanto a identidade vem toda da tinta e do
`amb`).

**Ordem obrigatória do pipeline** — enganei-me nisto duas vezes:

```bash
python tools/gerar_niveis_31_100.py     # escreve os .tscn (e RETRATO_CHEFE)
"...Godot..." --headless --import
python tools/afinar_atmosfera.py        # só DEPOIS: reescreve o bloco Atmosfera
```

Ao contrário, o gerador apaga a atmosfera afinada e a região fica com as
cores por omissão.

## 3. Equipamento: 1 arma / 5 níveis, 1 armadura / 10 (pedido do Paulo)

- **20 armas** (níveis 5, 10, ... 100) e **10 armaduras** (10, 20, ... 100).
  Nos múltiplos de 10 caem as duas.
- `recompensa_do_nivel` → **`recompensas_do_nivel`**, que devolve uma
  **lista** (era o que impedia um nível de dar as duas coisas).
- +5 armas do pós-Zeriko (Maré Escarlate, Brasa do Inferno, Fio do Vazio,
  Juramento de Guerra, **Última Lâmina** — branca, a do duelo do nível 100).
  `tools/extrair_armas.gd` corta 20 lâminas em vez de 15.
- As armaduras passaram de 15 para 10; as 5 que saíram continuam com a arte
  na tira, e por isso a armadura ganhou o campo **`celula`**, que **não é**
  o índice na lista.

## 4. Retrato do chefe no carrossel dos níveis 31-100 (pedido do Paulo)

Não apareciam porque o `_retrato_chefe` só olhava para
`assets/sprites/pixel/bosses/` (as folhas estáticas antigas). Agora tenta
três sítios por ordem — `bosses_anim/<rig>/idle.png`,
`enemies/<especie>/idle.png` (os **guardiões** são elites de espécie
comum), `bosses/<slug>.png` — e vai buscar o número de frames ao catálogo
de cada um. A cauda da tabela (31-100) é **gerada** por
`gerar_niveis_31_100.py::retratos()`, portanto mantém-se em sincronia
sozinha. Os 30 primeiros passaram a apontar ao **rig** em vez da folha
estática: o carrossel mostrava um boneco e o jogo outro.

---

# Pendente de antes (não perder de vista)

1. **Playtestar.** 100 níveis e 34 rigs de chefe nunca foram jogados de fio
   a pavio. `tools/testar_chefe.gd -- <idx0> <prefixo> [n] [seg] [zoom]
   [recuo]` e `tools/folha_de_contacto.gd` (**as duas precisam de janela**:
   `--window --screen 1`).
2. **A curva do 2.º acto** (níveis 31+) espalha-se por 70 níveis; os pontos
   de partida (dificuldade 0.72, 14000 px) continuam a ser palpite.
3. **O nível 100 não é um chefe normal** no plano: é um duelo de espada,
   sem poderes, sem HUD e sem barra de vida. Está montado como
   `ChefeGenerico` de INVESTIDA até ser feito a sério.
4. **Arte própria das regiões novas** — `gerar_terreno.py` só conhece 6
   biomas de terreno.

# Gotchas desta máquina (não voltar a descobrir)

- **Screenshots não saem em `--headless`** (renderer dummy). Usar
  `--window --screen 1` — janela real no 2.º monitor, sem roubar o ecrã
  principal ao Paulo.
- `ERROR: There is no animation with name 'idle'` aparece em **todos** os
  níveis em `--headless`, incluindo o 1 — é do renderer dummy, não é
  regressão.
- A folha de contacto dos 100 níveis demora >2 min: correr em background.
- No `tests/run_tests.gd` **não tocar em `ChefeBase.`/`EstadoJogo.`
  directamente**: em `--script` os autoloads não existem. Ler as constantes
  da FONTE (`_constante_float`).
- Heredocs de Python com `\n` dentro de strings pelo Bash tool corrompem
  ficheiros — escrever o script para o scratchpad e correr o ficheiro.
- `ffmpeg` existe via `pip install --user imageio-ffmpeg`.

# Histórico mais antigo

A lista de 6 pontos do Paulo (Koliani pixel-art, ressalto do pisão, sons
reais, 20+20 músicas, chefes animados) está **completa** — ver o histórico
git e `assets/audio/CREDITS.md` / `assets/sprites/pixel/CREDITS.md` para as
fontes e licenças. **Nota de licença que não se apaga**: o rig "cavaleiro"
da Koliani vem do pack Knight_player, que proíbe uso por IA no seu
`Read_me.txt`; o Paulo viu o aviso e confirmou que quer esta Koliani na
mesma. **Não voltar a apagar esses assets sem falar com ele primeiro.**
