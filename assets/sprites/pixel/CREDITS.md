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

## LuizMelo — "Monsters Creatures Fantasy"
- https://luizmelo.itch.io/monsters-creatures-fantasy
- Licença: CC0 1.0
- Uso: inimigos comuns pixel-art animados
  (`assets/sprites/pixel/enemies/{goblin,mushroom,esqueleto,olho}/`) —
  Goblin, Mushroom, Skeleton, Flying Eye. `DemonioBase.especie` escolhe.

## Ansimuz (Luis Zuno) — packs "GothicVania" / parallax
- https://ansimuz.itch.io/ · https://opengameart.org/users/ansimuz
- Licença: CC0 / domínio público ("free to use, personal or commercial")
- Uso: fundos parallax pixel-art por nível
  (`assets/sprites/pixel/backgrounds/{floresta,pantano,corredores,rochoso,montanhas}/`)
  — Parallax Forest v2, Gothicvania Swamp, Cold Corridors, Rocky Pass,
  Mountain Dusk.

CC0 não exige atribuição; fica aqui à mesma por cortesia.

## thewisehedgehog — pack de armas pixel-art
- https://thewisehedgehog.itch.io/  (URL exato + licença POR CONFIRMAR pelo Paulo em incoming/LICENSES.md)
- Uso: as 15 lâminas que a Koliani segura (`assets/sprites/pixel/gear/armas.png`,
  15 frames de 32x32) — extraídas da grelha 6x5 de `File (1).png` por
  `tools/extrair_armas.gd`. A cor dominante de cada lâmina alimenta
  `Equipamento.COR_ARMA`, e o brilho/efeitos do golpe (`koliani.gd`) seguem
  essa cor.
