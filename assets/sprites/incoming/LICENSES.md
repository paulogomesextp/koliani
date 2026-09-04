# Licenças dos packs em incoming/

Cola aqui, por cada pack, o URL da página e o texto da licença (da própria
página do itch/Kenney). O agente usa isto para gerar `assets/sprites/pixel/CREDITS.md`.

## pixel-adventure-1
- URL: https://pixelfrog-assets.itch.io/pixel-adventure-1
- Licença: https://creativecommons.org/publicdomain/zero/1.0/
- Autor: Pixel Frog

## kings-and-pigs
- URL: https://pixelfrog-assets.itch.io/kings-and-pigs
- Licença: https://creativecommons.org/publicdomain/zero/1.0/
- Autor: Pixel Frog

## kenney-pixel-platformer  (opcional, se vieres a descarregar)
- URL: https://kenney.nl/assets/pixel-platformer
- Licença: https://creativecommons.org/publicdomain/zero/1.0/
- Autor: Kenney

---

# Packs Dark / Fantasmagórico (preencher ao largar os ficheiros)

## gothicvania
- Packs presentes:
  - `gothicvania church files/` — GothicVania Church Pack
    - `public-license.txt` (incluído): "Public domain and free to use on
      whatever you want, personal or commercial. Credit is not required
      but appreciated." (= CC0 na prática)
- Licença: CC0 / domínio público — https://creativecommons.org/publicdomain/zero/1.0/
- Autor: Luis Zuno (@ansimuz) · música de demo: Pascal Belisle (não usada)

## luizmelo
- URL(s): https://itch.io/profile/luizmelo  (colar cada pack usado)
- Licença: CC0 — https://creativecommons.org/publicdomain/zero/1.0/
- Autor: LuizMelo

## clembod
- URL(s): https://clembod.itch.io/  (colar cada pack usado)
- Licença: (colar o texto exacto da página — grátis, uso comercial, creditar)
- Autor: Clembod  → creditar em CREDITS.md

## chierit
- URL(s): https://chierit.itch.io/  (colar cada boss usado)
- Licença: CC-BY 4.0 — https://creativecommons.org/licenses/by/4.0/
- Autor: chierit  → creditar em CREDITS.md

## 0x72-dungeon-ii
- URL: https://0x72.itch.io/dungeontileset-ii
- Licença: CC0 — https://creativecommons.org/publicdomain/zero/1.0/
- Autor: 0x72

## ansimuz-parallax
- URL(s): https://ansimuz.itch.io/  (colar cada pack de parallax usado)
- Usado tambem em: `props/tocha.png` (Cold Corridors -> Assets/Torch) e
  `props/candeeiro.png` (GothicVania Town -> props-sliced/street-lamp.png),
  recortados por `tools/gerar_luzes.py`.
- Licença: (colar o texto exacto da página)
- Autor: Ansimuz (Luis Zuno)

## bdragon1727 — "Free Effect and Bullet 16x16"
- URL: https://bdragon1727.itch.io/free-effect-and-bullet-16x16
- Autor: BDragon1727
- Preço: Free ("name your own price")
- Licença (texto da página, 2 set 2026):
  - "Free to use on non-commercial games, please leave comments and reviews
    that help motivate me."
  - "If you will be using on a commercial game, please contribute (any value)."
  - "Modify as desired."
  - "You cannot do: Resell / redistribute this asset."
  - Sem exigência explícita de crédito (mas creditado em CREDITS.md).
  - Sem restrição a treino de IA / NFT.
- Confirmado pelo Paulo em 2 set 2026 (usar; contribuir se o jogo for
  vendido). Usado: só a folha roxa, frames extraídos e recoloridos para
  `assets/sprites/pixel/fx/` (não é redistribuição do pack).

---

# Packs descarregados pelo agente (3 set 2026) -- `incoming/_dl/`

Todos do OpenGameArt, todos de DOMINIO PUBLICO / CC0. Descarregados com
autorizacao expressa do Paulo ("assets free, adiciona-os ao jogo").

## gothicvania-cemetery-files_1.zip  -> `_dl/gothicvania-cemetery-files_1/`
- URL: https://opengameart.org/content/gothicvania-cemetery-pack
- Autor: Luis Zuno (@ansimuz)
- Licenca: CC0 -- "Public domain and free to use on whatever you want,
  personal or commercial. Credit is not required but appreciated."
- Conteudo usado: arvores mortas, lapides, cruzes, estatua do ceifeiro,
  arbustos, silhueta do cemiterio.

## gothicvania patreon collection.zip  -> `_dl/gothicvania_patreon/`
- URL: https://opengameart.org/content/gothicvania-patreons-collection
- Autor: Luis Zuno (@ansimuz) · Licenca: CC0
- Conteudo usado: **Old Dark Castle interior tileset** (material da regiao
  VI), Gothic Castle tileset/fundo, Gothic Horror tiles/town/clouds,
  night-town-background (7 camadas de parallax).

## opp3_cave_tiles.zip  -> `_dl/opp3_cave_tiles/`
- URL: https://opengameart.org/content/opp2017-cave-and-mine-cart
- Autor: Open Pixel Project · Licenca: dominio publico ("free to use,
  modify, sell, for any purpose, they are in the public domain!")
- Conteudo: rocha de gruta, cristais, cogumelos, lava, objectos.

## bridge_expansion_pack_1_files.zip  -> `_dl/bridge_expansion/`
- URL: https://opengameart.org/content/gothicvania-bridge-expansion-pack-1
- Autor: Luis Zuno (@ansimuz) · Licenca: CC0
- Conteudo: castelo tileavel, casa, arvore (props de fundo).

## Pixel Art Animated Portal.zip  -> `frostwindz/`  (4 set 2026)
- URL: https://frostwindz.itch.io/  · Autor: **Frostwindz**
- **PAGO** -- o Paulo comprou e largou o zip. Licenca propria ("Frostwindz
  Asset License Agreement", copia no `frostwindz/`):
  - uso comercial e nao comercial OK, modificacao OK, projectos ilimitados;
  - atribuicao apreciada mas nao obrigatoria;
  - **2.1/2.2: NAO se pode redistribuir nem partilhar os ficheiros, no
    original ou modificados, em sitios de onde possam ser descarregados;
    tem de estar integrados num projecto maior.** ATENCAO: o repo do Koliani
    e' PUBLICO -- ver a nota no fim deste ficheiro.
  - proibido usar para treinar modelos de IA.
- **DECISAO DO PAULO (4 set 2026): NAO SE USA no repo.** Enquanto o
  `github.com/paulogomesextp/koliani` for publico, comitar a tira recortada
  era pô-la a descarregar de graca -- o que a clausula 2.1 proibe. A
  `Porta.tscn` fica com o vortice desenhado por codigo (Line2D/Polygon2D).
- Para o experimentar em local: `python tools/gerar_fx_portal_balas.py` gera
  `assets/sprites/pixel/props/portal_fim.png` (256x128 -> tira de 7 frames
  de 64x64). O ficheiro esta' no `.gitignore`, portanto nao escapa sozinho;
  falta so' apontar a `Porta.tscn` para ele. Se um dia o repo passar a
  privado (ou houver acordo com a Frostwindz), e' esse o caminho.

## 500 Bullet 24x24 Free.zip  -> `bullets-500/`  (4 set 2026)
- Pack gratuito de balas 24x24 (30 folhas de 576x360). O zip **nao traz
  ficheiro de licenca** -- so' os PNG e os GIF de preview. Confirmar os
  termos na pagina do itch.io de onde o Paulo o tirou antes de publicar.
- Organizacao: cada folha e' 24x15 celulas; tres blocos de cor de 5 linhas
  (0-4 laranja, 5-9 vermelho, **10-14 roxo**); em cada linha, tres balas de
  8 frames (colunas 0-7 / 8-15 / 16-23).
- Conteudo usado (so' o bloco roxo), via `tools/gerar_fx_portal_balas.py`:
  `fx/bala_roxa.png` (tiro da Koliani), `fx/bala_roxa_grande.png` (bolas do
  Zeriko), `fx/flare_roxo.png` (cabeca do Kamehameha).

---

## Nota sobre redistribuicao (repo publico)
`github.com/paulogomesextp/koliani` e' publico. Os packs em bruto ficam
sempre fora do git (ver `.gitignore`), mas as TIRAS RECORTADAS que se
comitam em `assets/sprites/pixel/` ficam publicas e descarregaveis. Para os
packs CC0 isso nao e' problema; para o **portal da Frostwindz** era um
conflito com a clausula 2.1 da licenca dele -- por isso ficou de fora.

## wenrexa / laser2020
- URL: https://wenrexa.itch.io/laser2020
- Licença: CC0 (domínio público). Uso comercial permitido, sem crédito
  obrigatório, modificação permitida.
- Autor: Wenrexa
- Usado em: `fx/laser_roxo.png` (tiro da Koliani) e `fx/laser_raio_roxo.png`
  (feixe do Kamehameha), recortados por `tools/gerar_fx_laser.py`.
