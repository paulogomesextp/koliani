# Créditos de arte — packs externos

A personagem principal (Koliani) é original do projeto
(`tools/gerar_sprites.gd`). Os restantes sprites pixel-art vêm de packs CC0:

## Pixel Frog — "Kings and Pigs"
- https://pixelfrog-assets.itch.io/kings-and-pigs
- Licença: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)
- Uso: inimigo comum (Pig → `assets/sprites/pixel/enemies/pig_*.png`),
  patch de pedra/tijolo das plataformas
  (`assets/sprites/pixel/tiles/pedra_block.png`, do TileSet 32x32) e
  (a integrar) portas, tochas, caixas.

## Pixel Frog — "Pixel Adventure 1"
- https://pixelfrog-assets.itch.io/pixel-adventure-1
- Licença: CC0 1.0
- Uso: patch de relva/terra das plataformas da floresta
  (`assets/sprites/pixel/tiles/floresta_block.png`, do Terrain 16x16),
  armadilhas (`assets/sprites/pixel/traps/`: espinhos, serra, fogo) e
  (a integrar) caixas, fruta.

## Kenney — "Pixel Platformer"
- https://kenney.nl/assets/pixel-platformer
- Licença: CC0 1.0
- Uso: (a integrar) tiles e props de preenchimento.

## 0x72 — "DungeonTileset II" (v1.7)
- https://0x72.itch.io/dungeontileset-ii
- Licença: CC0 1.0
- Uso: tileset de masmorra 16x16 (`assets/sprites/pixel/tiles/dungeon_0x72.png`)
  — chão, paredes, tecto, escadas, buracos, estandartes. Base do
  `assets/tiles/masmorra.tres` (TileSet gerado por `tools/gerar_tileset_masmorra.gd`)
  usado nas regiões II (Prisão) e IV (Catacumbas). `dungeon_0x72_tile_list.txt`
  é a lista de coordenadas do pack (nome x y w h).
- **Monstros da Jornada** (`tools/extrair_monstros_0x72.gd` →
  `assets/sprites/pixel/enemies/{imp,chort,orc,xamane,demonio_grande,ogro,`
  `abobora,wogol,necromante,lodo}/`): frames `<nome>_idle/run_anim_fN`
  ampliados nearest para a altura dos outros inimigos. `DemonioBase.especie`.
- **Props decorativos** (`assets/sprites/pixel/props/`: column, crate, skull,
  wall_banner_red/blue, floor_ladder) — o `gerador_corredor.gd` espalha-os
  pelas plataformas e no fundo da jornada.

## Ansimuz — "Enemies Pack"
- https://ansimuz.itch.io/ · licença pública do pack (ver
  `incoming/enemies-pack/.../public-license.pdf`)
- Uso: 5 inimigos novos em `assets/sprites/pixel/enemies/{besouro,raptor,`
  `mastim,gosma,abutre}/`, extraídos por `tools/extrair_inimigos_pack.gd`
  (o pack só traz walk/idle: o `hit` reaproveita o idle e o `dead` é gerado,
  o bicho achata-se e desvanece). O `abutre` voa, como o `olho`.

## clembod — "Bringer of Death"
- https://clembod.itch.io/ — grátis com uso comercial; **crédito pedido pelo
  autor** (texto exacto por colar em `incoming/LICENSES.md`).
- Uso: o **Colosso Ósseo** (nível 17) — `bosses/colosso.png`, 4 poses
  montadas por `tools/extrair_chefes_packs.gd`.

## chierit — "boss demon slime" (versão FREE)
- https://chierit.itch.io/ — **CC-BY 4.0** (obriga a creditar).
- Uso: o **Ignivar** (nível 7) — `bosses/ignivar.png`. Apesar do nome do
  pack, o sprite é um demónio de fogo com espadão, que é exactamente o
  chefe da Fornalha dos Pecadores.
- E o **Ghorak** (nível 1) — `bosses/ghorak.png`, a partir do **Frost
  Guardian** do mesmo autor, recolorido para casca/musgo com núcleo roxo
  (o Ghorak é "guerreiro de tronco, ossos e raízes, com núcleo púrpura no
  peito" — e o golem do pack já tem o núcleo no peito).

## LuizMelo — "Monsters Creatures Fantasy"
- https://luizmelo.itch.io/monsters-creatures-fantasy
- Licença: CC0 1.0
- Uso: inimigos comuns pixel-art animados
  (`assets/sprites/pixel/enemies/{goblin,mushroom,esqueleto,olho}/`) —
  Goblin, Mushroom, Skeleton, Flying Eye. `DemonioBase.especie` escolhe.
- Também o pack **Evil Wizard 2** (mesmo autor, CC0): é o **Bispo
  Púrpura** (nível 24) — `bosses/bispo.png`, via
  `tools/extrair_chefes_packs.gd`.
- E o **Olho do Abismo** (nível 20) — `bosses/olho.png` — é o mesmo "Flying
  eye" dos inimigos comuns, em tamanho de chefe.

## Ansimuz (Luis Zuno) — packs "GothicVania" / parallax
- https://ansimuz.itch.io/ · https://opengameart.org/users/ansimuz
- Licença: CC0 / domínio público ("free to use, personal or commercial")
- Uso: fundos parallax pixel-art por região
  (`assets/sprites/pixel/backgrounds/{floresta,pantano,corredores,rochoso,montanhas,prisao,caverna,cidade,igreja}/`):
  Parallax Forest v2 (R1 `floresta`), Gothicvania Swamp (R1 pântano
  `pantano`), Mountain Dusk (R3 `montanhas`), Caverns (R4 `caverna`),
  Rocky Pass (R5 `rochoso`). Cold Corridors serve as duas regiões de
  masmorra: `prisao` (R2, graduada a azul-cobalto pela Atmosfera) e
  `corredores` (R6 castelo, graduada a violeta/magenta) — mesma
  arquitectura, ambientes diferentes.

CC0 não exige atribuição; fica aqui à mesma por cortesia.

## @Jump_Button — "Knight_player 1.4"  ← RIG ACTUAL DA KOLIANI
- Pack do autor @Jump_Button (Twitter). Frames de 100x64, uma tira por
  animação. **Licença (Read_me.txt do pack)**: uso pessoal e comercial
  permitido, **crédito OBRIGATÓRIO no uso comercial**; não revender nem
  reproduzir a imagem para lucro; o autor proíbe expressamente usar a arte
  para treino de IA/ML, NFT ou blockchain. Não é CC0 — o Paulo tem de
  confirmar que aceita estes termos antes de publicar o jogo.
- Uso: `assets/sprites/pixel/koliani_cavaleiro/` (15 estados: idle, run,
  jump, fall, attack, crouch, wallslide, djump, roll, dash, hurt, defesa,
  borda, aterrar, morte), importado e recolorido para a paleta da Koliani
  (vermelhos -> magenta, metal -> violeta frio) por
  `tools/importar_rig_cavaleiro.gd`. Ligado por `koliani.gd::RIG`.

## thewisehedgehog — pack de armas pixel-art
- https://thewisehedgehog.itch.io/  (URL exato + licença POR CONFIRMAR pelo Paulo em incoming/LICENSES.md)
- Uso: as 15 lâminas que a Koliani segura (`assets/sprites/pixel/gear/armas.png`,
  15 frames de 32x32) — extraídas da grelha 6x5 de `File (1).png` por
  `tools/extrair_armas.gd`. A cor dominante de cada lâmina alimenta
  `Equipamento.COR_ARMA`, e o brilho/efeitos do golpe (`koliani.gd`) seguem
  essa cor.

## piiixl — "Seamless Patterns" (16x16)
- https://piiixl.itch.io/  (URL exato + licença POR CONFIRMAR pelo Paulo em incoming/LICENSES.md)
- Uso: base dos blocos de terreno das plataformas (96x96, 9-slice). A
  calçada azul-escura (célula 0,0) → `pedra_gotica_block.png` via
  `tools/gerar_tiles_goticos.gd`. E 5 outras células "seamless" (pedra /
  tijolo, pouca cor) → um bloco POR REGIÃO
  (`{prisao,torres,catacumbas,cidade,castelo}_block.png`) via
  `tools/gerar_tiles_zonas.gd`: o padrão da célula entra só como relevo, a
  cor é a da zona, e todas levam a mesma aresta de luar + fio magenta +
  musgo fantasma. `scripts/plataforma.gd` escolhe pelo `bioma`.
  (`floresta` continua com relva do Pixel Adventure.)

## Ansimuz — "Gothicvania Church" (rig da Koliani, EXPERIMENTAL)
- https://ansimuz.itch.io/gothic-vania-church-pack  (CC0 — confirmar em incoming/LICENSES.md)
- Uso: rig de animação do jogador (idle/walk/jump/fall/punch/crouch, tiras
  82x60) recolorido para o luar roxo do key_art (duotone indigo→roxo→
  lavanda) por `tools/importar_rig_koliani.py` → `assets/sprites/pixel/
  koliani_gothic/*.png`. Ligado por `koliani.gd` `RIG = "gothic"`
  (`RIG = "codigo"` volta ao sprite gerado por `tools/gerar_sprites.gd`).
  Mesma família de arte dos parallax Ansimuz já usados nos fundos.
