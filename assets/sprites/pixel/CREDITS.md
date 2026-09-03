# Créditos de arte — packs externos

A personagem principal (Koliani) é **arte original do Paulo** (pixel-art
desenhada à mão, 3 set 2026) — ver "Koliani (rig actual)" no fim deste
ficheiro. Os restantes sprites pixel-art vêm de packs CC0:

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
  (`assets/sprites/pixel/backgrounds/{floresta,pantano,rochoso,montanhas,prisao,caverna,cidade,igreja}/`):
  Parallax Forest v2 (R1 `floresta`), Gothicvania Swamp (R1 pântano
  `pantano`), Mountain Dusk (R3 `montanhas`), Caverns (R4 `caverna`),
  Rocky Pass (R3 `rochoso`), Cold Corridors (R2 `prisao`).

  Até 3 set 2026 o Cold Corridors estava copiado byte a byte para um
  segundo nome, `corredores`, para servir a R6 (castelo) graduado a
  violeta. Não pegava: na folha de contacto o castelo continuava a ler-se
  como a prisão. O pack duplicado foi apagado e cada região passou a ter
  packs só seus — ver `tools/afinar_atmosfera.py`.

- **ansimuz — GothicVania *Gothic Castle*** (patreon collection):
  `backgrounds/masmorra/` — o 2.º fundo da R2. A folha
  `gothic-castle-background.png` não é uma tira de parallax, é um
  mostruário de dez peças soltas (escadaria com lustre, janela gótica,
  gárgula, alcova, pilar de ossos, portão gradeado, arcada, paredes de
  tijolo). O `tools/gerar_fundos.py` monta-as em fiadas e empilha duas
  numa parede alta. É desenhada quase a preto (luminância média ~11,
  contra 26–46 do resto da família) — leva um realce de gama 1.8 na
  geração, senão dava ecrã preto no jogo.
- **Szadi art — *Fantasy Caves*** (o mesmo pack que dá o terreno da R4):
  `backgrounds/gruta/` — quatro das cinco camadas de parallax 960×480 que
  vinham no pack e nunca tinham sido usadas. 2.º fundo da R4.

CC0 não exige atribuição; fica aqui à mesma por cortesia.

## @Jump_Button — "Knight_player 1.4"  ← RETIRADO (3 set 2026)
- Pack do autor @Jump_Button (Twitter). **Licença (Read_me.txt do pack)**
  proíbe expressamente qualquer uso por "AI (...) AI/ML Training (...)
  Such usage is completely prohibited and may result in legal action if
  necessary." Não é CC0. O Paulo confirmou: trocar por um pack CC0
  verdadeiro em vez de arriscar o termo.
- Os `.png` derivados (`assets/sprites/pixel/koliani_cavaleiro/`) foram
  **removidos do repo** (`3c1dd48`+). `koliani.gd::RIG` já não passa por
  `"cavaleiro"` (fica `"nova"`); `tools/importar_rig_cavaleiro.gd` fica
  como código morto/histórico — não voltar a correr. O pack em si continua
  só no disco do Paulo (`assets/sprites/incoming/`, `.gdignore`, nunca foi
  redistribuído no GitHub).

## thewisehedgehog — pack de armas pixel-art
- https://thewisehedgehog.itch.io/  (URL exato + licença POR CONFIRMAR pelo Paulo em incoming/LICENSES.md)
- Uso: as 15 lâminas que a Koliani segura (`assets/sprites/pixel/gear/armas.png`,
  15 frames de 32x32) — extraídas da grelha 6x5 de `File (1).png` por
  `tools/extrair_armas.gd`. A cor dominante de cada lâmina alimenta
  `Equipamento.COR_ARMA`, e o brilho/efeitos do golpe (`koliani.gd`) seguem
  essa cor.

## bdragon1727 — "Free Effect and Bullet 16x16"
- https://bdragon1727.itch.io/free-effect-and-bullet-16x16
- Licença: grátis ("name your own price"). Uso não-comercial livre; uso
  comercial pede contribuição voluntária de qualquer valor. Modificar
  permitido. NÃO revender/redistribuir o pack. Texto completo em
  `assets/sprites/incoming/LICENSES.md`. (Confirmado pelo Paulo, 2 set 2026.)
- Uso (folha roxa, `Purple Effect and Bullet 16x16.png`, grelha 16x16,
  extraída por `tools/extrair_efeitos.gd`):
  - `assets/sprites/pixel/fx/impacto_roxo.png` — anel que abre no ponto do
    golpe (`scripts/impacto.gd`); linha 5, colunas 14-17.
  - `assets/sprites/pixel/fx/bala_roxa.png` — orbe roxo a girar (loop de 6
    frames); linha 0, colunas 30-35. Corpo do `ProjetilKoliani`, cabeça do
    `KamehamehaKoliani` e `ProjetilZeriko` (substitui `Polygon2D`/`ColorRect`).
  - `assets/sprites/pixel/fx/bola_fogo.png` — o mesmo vórtice na folha
    laranja (`Fire Effect and Bullet 16x16.png`); corpo da `BolaFogo`
    (Torreta / cuspidor).

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

## Koliani (rig actual) — arte original do Paulo
- Fonte: `C:/Users/paulo/Desktop/newkoliani/` (ficheiros `.aseprite` +
  folhas `idle` 10x46x55 e `walk` 24x45x58). Não é de nenhum pack.
- Uso: `assets/sprites/pixel/koliani_nova/` — 18 estados montados por
  `tools/importar_rig_koliani_nova.py`. **Só o `idle` e o `run` são frames
  desenhados**; os outros 16 (salto, queda, rolamento, dash, agachar,
  parede, borda, aterrar, defesa, dano, morte, salto duplo e os 4 golpes do
  combo) são DERIVADOS desses por transformação — inclinar, achatar, rodar,
  rasto — mais um arco de espada azul desenhado por código nos ataques.
  Substituir por frames a sério assim que existirem.
- A paleta dela manda no resto: o azul do manto (`#0321bc`) é o azul dos
  projécteis (`fx/bala_azul.png`, `fx/impacto_azul.png`, folha "Water" do
  bdragon1727) — antes eram roxos e deixaram de casar com a personagem.

## Packs CC0 de 3 set 2026 (OpenGameArt) — terreno, decoração e fundos
Ver `assets/sprites/incoming/LICENSES.md` para os URLs e o texto das
licenças. Todos de domínio público / CC0.
- **ansimuz — GothicVania Cemetery**: árvores mortas, lápides, cruzes,
  estátua do ceifeiro, arbustos (`deco/{floresta,torres,catacumbas}/`) e o
  fundo `backgrounds/luar/` (lua de sangue nas nuvens — o `key_art` em
  pixel).
- **ansimuz — GothicVania Patreon Collection**: *Old Dark Castle interior*
  (material de terreno da região VI + fundo `backgrounds/castelo_velho/`),
  *Gothic Horror* (`backgrounds/horror/`), *Night Town*
  (`backgrounds/vilanoite/`).
- **Open Pixel Project — OPP2017 Cave**: cristais, ossadas, lanterna
  (`deco/catacumbas/`).
- **ansimuz — GothicVania Bridge Expansion**: props de fundo.

### O que PENDE por baixo das plataformas (`onde: "pendurado"`)
Acrescentado a 3 set 2026. Muito disto é material já creditado acima, virado
ao contrário (`vflip` no `gerar_deco.py`) — um cristal do chão de cabeça para
baixo é uma estalactite, uma árvore morta virada é uma raiz a furar a abóbada:
- **Pixel Frog — Pixel Adventure 1**: o elo de corrente 8×8
  (`Traps/Platforms/Chain.png`), empilhado para dar correntes de qualquer
  comprimento — nas seis regiões.
- **anokolisa — Legacy Fantasy High Forest**: colmeias e folhagem
  (`deco/floresta/`).
- **Pixel Frog — Kings & Pigs**: a flâmula de `Decorations (32x32)`
  (`deco/{torres,castelo}/`).
- **ansimuz — GothicVania Town**: o candeeiro de rua virado, que dá o lampião
  de tecto (`deco/{torres,cidade,castelo}/`).
- **Open Pixel Project — OPP2017 Cave**: os aglomerados de cristal virados =
  estalactites (`deco/catacumbas/`).

## Terreno por região (`assets/sprites/pixel/terreno/`)
Gerado por `tools/gerar_terreno.py`: capa + corpo + franja + corte lateral,
**um pack diferente por região** — anokolisa *Legacy Fantasy* (floresta),
Pixel Frog *Kings & Pigs* (prisão), ansimuz *GothicVania Church* (torres),
Szadi art *Fantasy Caves* (catacumbas), ansimuz *GothicVania Town*
(cidade), ansimuz *Old Dark Castle* (castelo).
