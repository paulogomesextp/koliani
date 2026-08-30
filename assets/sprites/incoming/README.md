# assets/sprites/incoming/ — packs CC0 por integrar

Larga aqui os packs pixel-art **descompactados**, uma pasta por pack. O
agente pega nisto, organiza para `assets/sprites/pixel/`, configura o import
(Nearest, sem compressão), monta as animações e liga às cenas.

## Pastas à espera de conteúdo

| Pasta | Pack | Onde | Para quê |
|---|---|---|---|
| `pixel-adventure-1/` | Pixel Adventure 1 (Pixel Frog, CC0) | https://pixelfrog-assets.itch.io/pixel-adventure-1 | inimigos animados, tiles floresta/gruta, armadilhas, pickups |
| `kings-and-pigs/` | Kings and Pigs (Pixel Frog, CC0) | https://pixelfrog-assets.itch.io/kings-and-pigs | regiões escuras: calabouço, tochas, portas, inimigos |
| `kenney-pixel-platformer/` | Pixel Platformer (Kenney, CC0) — opcional | https://kenney.nl/assets/pixel-platformer | tiles / props de preenchimento |

### Dark / Fantasmagórico (a descarregar — ver `docs/assets_cc0.md`)

| Pasta | Pack | Licença | Para quê |
|---|---|---|---|
| `gothicvania/` | Ansimuz GothicVania (via **OpenGameArt**) | CC0 | tilesets + parallax + inimigos das regiões escuras |
| `luizmelo/` | LuizMelo — Monsters Creatures Fantasy, etc. | CC0 | inimigos comuns animados (troca o "Pig") |
| `clembod/` | Clembod — Bringer of Death, etc. | grátis / creditar | chefe pixel-art de tema Morte |
| `chierit/` | chierit — Boss Minotaur/Golem/Slime… | CC-BY 4.0 | chefes das regiões II→VI |
| `0x72-dungeon-ii/` | 0x72 — DungeonTileset II | CC0 | calabouço: tiles, tochas, dezenas de bichos |
| `ansimuz-parallax/` | Ansimuz — Gothic Parallax Backgrounds | grátis | camadas reais para o `Atmosfera` |

Cada pasta tem um `_LARGAR_AQUI.md` com os links exactos.

> Pixel Adventure 2 é pago — fora. Packs "free" da CraftPix **não** entram
> (licença proíbe redistribuir num repo público).

Podes acrescentar outras pastas se trouxeres mais packs.

## Depois de largar os ficheiros

Preenche `LICENSES.md` (nesta pasta) com o URL + a licença de cada pack
(copiada da página) e avisa o agente. Não é preciso mais nada.

> A Koliani (personagem principal) é **feita à mão** — `tools/gerar_sprites.gd`
> — não vem de nenhum pack.
