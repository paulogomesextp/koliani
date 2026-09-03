# Retomar aqui — 3 de setembro de 2026 (sessão da tarde, depois do /clear)

> **LEIA PRIMEIRO.** Continuação da lista do Paulo (ver histórico git para
> a versão completa anterior). Progresso desta sessão no topo.

## ⚠ A LISTA DO PAULO — estado actual

1. **Substituir a Koliani pelo modelo pixel-art novo** — ✅ **resolvido
   (de forma diferente do pedido original)**. O Paulo reenviou a folha de
   referência (gravada em `assets/branding/koliani_ref_nova.png`), mas
   depois de ver os candidatos CC0 que encontrei (nenhum bate perto o
   suficiente — ver "Investigação da arte" abaixo) **pediu para voltar ao
   rig "cavaleiro"** que já existia há 48h (Knight_player recolorido,
   cabelo comprido à mostra, sem elmo — visualmente o mais próximo que já
   tivemos da referência). `koliani.gd::RIG` voltou a `"cavaleiro"`
   (commit `1b0497e`, v0.10.3). **Decisão consciente sobre a licença**: o
   pack Knight_player proíbe uso por IA no seu `Read_me.txt`; o Paulo viu
   o aviso e confirmou expressamente que quer esta Koliani na mesma,
   aceitando o risco por agora. **Não voltar a apagar os assets sem falar
   com ele primeiro.**
2. Ressalto do pisão a metade — ✅ feito (sessão anterior, `6abcee0`).
3. **Sons mais realistas** — ✅ **feito** (`3c1dd48`, v0.10.2). Os 35 SFX
   de combate/mobs/UI (`scripts/som.gd`) foram trocados por samples CC0
   reais do OpenGameArt — ver `assets/audio/CREDITS.md` para a lista de
   packs/autores. Só as **camas** (`menu.wav`, `boss.wav`, `ambiente.wav`,
   `assombracao.wav`, `game_over.wav`) continuam sintetizadas por
   `tools/gerar_audio.py` — sem equivalente real encontrado ainda.
4. **20 músicas de nível, em ciclo** — por fazer. `faixa = indice_nivel % 20`.
5. **20 músicas de chefe, em ciclo** — por fazer. Mesma ideia para `Musica.boss()`.
6. Só depois disto, voltar aos CHEFES (rigs animados — faltam 24 de 30).

## Investigação da arte da Koliani (para não repetir)

Andei à procura de um pack **pixel-art genuíno e CC0** parecido com a
referência (assassina sem capacete, cabelo à mostra, cachecol/capa
vermelho-escura, espada recta brilhante magenta). Nada bateu perto o
suficiente:

- **Knight Hero Platformer Animation Pack** (CC0, pixivan,
  `opengameart.org/content/knight-hero-platformer-animation-pack`) —
  platformer completo (idle/walk/run/jump/fall/roll/combo de 3
  golpes/hit), mas vem com **elmo fechado e escudo redondo**. Recolori
  para a paleta magenta/roxo/vermelho como teste (o escudo lê bem como
  brilho de energia) mas a silhueta continua "cavaleiro com elmo", não
  "assassina de cabelo à mostra". Ficou descartado.
- **Ninja Adventure Asset Pack** (Pixel-Boy, CC0,
  `github.com/pixel-boy/NinjaAdventure`) — tem skins ninja em várias
  cores, mas é **top-down** (Zelda-like); não tem jump/wall
  slide/double jump porque esses movimentos só existem em plataforma
  lateral. Não aproveitável como esqueleto de movimento.
- **Ninja Girl - Free Sprite** (CC0, pzuh) — é "vector cartoon" (traço
  suave, não pixel-art), destoa do resto do jogo (`Nearest` filter,
  pixel-art puro).
- **rig "gothic"** (Ansimuz GothicVania Church, CC0, já no repo) — monge
  roxo de braços cruzados, sem espada visível. Mostrei ao Paulo, não
  escolheu.
- Não encontrei nada de graça com "cabelo comprido + capa/cachecol +
  espada recta + sem capacete" pronto a usar — é um nicho muito
  específico. Se algum dia for preciso mesmo trocar o Knight_player, a
  próxima tentativa deveria ser **compor** (photobash: pegar cabeça/cabelo
  de um pack sem elmo e colar sobre o corpo do Knight Hero) em vez de só
  recolorir — mais trabalho, resultado incerto.

## Sons — de onde vieram (para expandir mais tarde)

Todos os 35 SFX novos são **CC0** do OpenGameArt (nenhum exige
atribuição). Os packs mais rentáveis (cobriram a maioria sozinhos):
`RPG Sound Pack` (artisticdude), `80 CC0 RPG SFX` + `80 CC0 creature SFX`
+ `40 CC0 water/splash/slime SFX` (rubberduck), `20 Sword Sound Effects` +
`10 Impact/Shield Blocks` (StarNinjas). Lista completa com o ficheiro
exacto por chave: `assets/audio/CREDITS.md`.

**Notas técnicas:**
- `scripts/som.gd::CAMINHOS` agora mistura `.wav`/`.ogg`/`.mp3` por chave
  (Godot 4 importa os três nativamente) — não presumir que é sempre
  `.wav`.
- `tools/gerar_audio.py` **continua a existir mas não deve gerar** as
  chaves que já foram trocadas por samples reais (o cabeçalho do ficheiro
  lista quais) — corrê-lo por inteiro cria `.wav` órfãos ao lado dos
  `.ogg`/`.mp3` novos (inofensivo, mas lixo).

## A FAZER — por onde continuar

### Próximo: músicas de nível e de chefe em ciclo (pontos 4 e 5 da lista)

Mesma técnica de scraping que os SFX (OpenGameArt, `field_art_type_tid[]=12`
para música, termos como `epic orchestral`, `boss battle`, `dark fantasy`,
`dungeon`, `gothic`). **Cuidado com o peso**: `assets/audio` já tem ~26 MB
depois dos SFX novos; 40 faixas de música a ~3-4 MB cada seriam +120-160 MB
no repo. **Não há `ffmpeg` nesta máquina** — a escolha tem de recair sobre
faixas já pequenas (loops curtos `.ogg`), ou perguntar ao Paulo se aceita
o repo crescer muito, ou hospedar as músicas fora do git (ex.: descarregar
em runtime — mais trabalho de infra).

Pixabay continua bloqueado ao `curl`. OpenGameArt funciona bem (foi a
fonte de tudo nesta sessão).

### Depois: voltar aos CHEFES

Faltam rigs animados para 24 dos 30 chefes de 1-30 (5 já têm, ver sessão
anterior). Candidatos por descarregar do itch.io (nenhum ficheiro escrito
ainda): *Boss: Undead Executioner*, *Boss: Mecha-Stone Golem* — ambos
`darkpixel-kronovi.itch.io`, comerciais OK sem redistribuir.

### Pendente há mais tempo (ver histórico para detalhe)

Níveis 31-100 (só a Região VII feita), 24 chefes por animar, arte por
região das 14 regiões novas (31-100) por fazer.
