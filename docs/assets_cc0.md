# Base de dados de assets — Dark / Fantasmagórico (CC0 e grátis)

Catálogo de packs de arte para o Koliani: **morte, fantasmas, monstros,
ruínas, luar, magenta/roxo**. Alinha com `docs/design.md` e o
`assets/branding/key_art.png`.

> **Repo é PÚBLICO** (`github.com/paulogomesextp/koliani`). Só se pode
> **cometer** ao repo arte que a licença deixa **redistribuir**:
> **CC0** (sem créditos) e **CC-BY** (com créditos em
> `assets/sprites/pixel/CREDITS.md`). Packs "free" da CraftPix e afins
> **não** deixam redistribuir — dá para usar num jogo mas **não** metê-los
> num repo público. Evitar.

Fluxo: o Paulo faz download → larga a pasta em `assets/sprites/incoming/`
(tem `.gdignore`, o Godot ignora) → o agente copia só o que usa para
`assets/sprites/pixel/…` e credita.

---

## 1. Ambientes / tilesets / parallax  ★ prioridade

### Ansimuz — série **GothicVania** (OpenGameArt, **CC0**)
No itch.io a maioria é **paga**; no **OpenGameArt as mesmas estão CC0** e
grátis para sempre. Igreja, cemitério, pântano, cidade, ponte, passagem
rochosa, sucata. É *o* match para "castelo assombrado / Ghouls'n Ghosts".
- Colecção curada: `opengameart.org/content/gothicdania` (junta quase tudo)
- `opengameart.org/content/gothicvania-church-pack` — tileset 16x16,
  fundos loopáveis, monge jogável (9 anims), inimigos **Anjo, Burning
  Ghoul, Skeleton Wizard**
- `opengameart.org/content/gothicvania-cemetery-pack` — cena de cemitério
- `opengameart.org/content/gothicvania-town` — 2 camadas parallax, casas,
  barris, 4 NPCs
- `opengameart.org/content/gothicvania-patreons-collection` — **13 packs**
  antigos: **Flying Demon, Fire Skull, Dark Ghost**, Gothic Castle
  Environment, tilesets 16x16, spritesheets de "horrors" e heróis
- `opengameart.org/content/gothicvania-swamp` · `...-magic-pack-9` ·
  `...-bridge-expansion-pack-1` · `...-rocky-pass-environment`

### Ansimuz — grátis no itch.io (name-your-price)
- `ansimuz.itch.io/gothicvania-cold-corridors` — sample de ambiente da
  colecção grande
- `ansimuz.itch.io/gothic-parallax-backgrounds` — fundos parallax góticos
- `ansimuz.itch.io/` → "Ansimuz Legacy Collection" — kit 16-bit amplo
  (personagens, backgrounds em camadas, tilesets top-down + side-view).
  Uso comercial confirmado pelo autor nos comentários.

### Outros (verificar licença em cada página)
- `0x72` — **DungeonTileset II** (**CC0**): paredes, chão, tochas
  animadas, armadilhas, e **dezenas de personagens animados** (cavaleiros
  a demónios, incl. *big demon* de boss). 16x16.
- OpenGameArt: procurar `Dark Fantasy parallax`, `crypt`, `catacombs`,
  `haunted` com filtro **License = CC0**.

---

## 2. Monstros / inimigos comuns

### LuizMelo (itch.io, **CC0** — uso comercial, créditos opcionais) ★
- `luizmelo.itch.io/monsters-creatures-fantasy` — **Skeleton, Mushroom,
  Goblin, Flying Eye**, todos com idle/andar/atacar/dano/morte
- `luizmelo.itch.io/16x16-dungeon-pixel-art-platformer` — tileset + bichos
- Folhas de personagem (servem de inimigo/mini-boss): **Evil Wizard**,
  **Fire Worm**, **Dark Knight**, Wizard, Huntress, Martial Hero 1–3,
  **Hero Knight / Hero Knight 2** (esta base para a Koliani, talvez)

### Dentro dos packs GothicVania (CC0)
Flying Demon, Fire Skull, Dark Ghost, Burning Ghoul, Skeleton Wizard,
Angel corrompido — já animados.

### A explorar
- `RedVoxel` — "Puny Characters" (CC0): tem esqueletos/zombies
- OpenGameArt: `skeleton`, `ghost`, `wraith`, `slime` + filtro CC0

---

## 3. Chefes (grandes, animados — normalmente **CC-BY**, exige crédito)

Servem os chefes da campanha (`docs/niveis.md`). CC-BY = pôr "nome" em
`CREDITS.md`; pode-se comprometer ao repo.

- **Clembod — "Bringer of Death"** (grátis, pessoal+comercial): ceifeira
  encapuzada com foice — **perfeito para tema Morte**. idle/walk/attack/
  hurt/death/cast/spell. `clembod.itch.io`
- **Clembod** — "Golden Knight", "Fire Wizard" (mesma linha)
- **chierit** (CC-BY 4.0, .aseprite incluído, editável): "Boss Minotaur",
  "Boss Demon Slime", "Boss Golem", "Wind Hashashin"… `chierit.itch.io`

---

## 4. Fontes 100% CC0 para vasculhar

- **OpenGameArt.org** — filtrar *Art → 2D*, *License → CC0*; procurar
  `gothic`, `undead`, `ghost`, `skeleton`, `crypt`, `graveyard`, `demon`
- **Kenney.nl** — **tudo CC0**. Estilo mais limpo (bom p/ props, UI,
  partículas, ícones) do que para o mood sombrio principal
- **itch.io** — `itch.io/game-assets/assets-cc0/tag-pixel-art`; confirmar
  sempre a licença ficheiro a ficheiro (nem todo o "free" é CC0)

---

## Recomendação de arranque (para a Fornalha / região II e além)

1. **GothicDania** (OGA, CC0) — cobre igreja/cemitério/pântano/cidade,
   tilesets + parallax + inimigos base. É o alicerce.
2. **LuizMelo — Monsters Creatures Fantasy** (CC0) — inimigos comuns já
   animados, substituem o "Pig".
3. **Clembod — Bringer of Death** (CC-BY) — 1.º chefe pixel-art a sério
   (encaixa em qualquer nível de tema Morte).
4. **Ansimuz — Gothic Parallax Backgrounds** (itch, grátis) — fundos em
   camadas para pôr no `Atmosfera`.

---

## O que está em `incoming/` e AINDA NÃO foi usado (1 set 2026)

Depois da Fase 3 e da troca de 6 chefes, sobra isto por aproveitar. Está
tudo já em disco — não é preciso descarregar nada.

| pack | o que tem | ideia de uso |
|------|-----------|--------------|
| **codemanu** (`*_spritesheet.png`) | 20 folhas de VFX 100x100 (weaponhit, magicspell, vortex, phantom, fire, protectioncircle…), **domínio público, sem crédito obrigatório** | vortex → `Portal`; magicspell → Kamehameha; protectioncircle → escudo do chefe; weaponhit → alternativa lisa ao anel do golpe |
| **chierit — Frost Guardian** | golem de gelo 192x128, muito bom | falta um chefe que case (o Ghorak levou o mesmo golem recolorido); ver `docs/niveis.md` antes de escolher |
| **free-game-assets** | 4 fundos + nuvens em camadas | céus alternativos (Torres / Cidade) |
| **anokolisa — Legacy Fantasy High Forest** | tileset + fundo de floresta | região I, se o pântano cansar |
| **zerie** (Tiny RPG 01/02) | Soldier, Orc, Demon_A, Blood Monster | **baixa resolução** (boneco de ~25 px dentro de 100x100) — fica blocado ao lado do resto; usar só se for de propósito |
| **ninjikin / szadiart / glionox / piiixl (resto)** | props e tiles | preenchimento |
| **bdragon1727** | efeitos 16x16 (já se usou o anel do impacto) | balas, brilhos, explosões pequenas |

Ferramentas que já fazem este tipo de trabalho (copiar e adaptar a tabela lá
de dentro, em vez de escrever tudo de novo):
`tools/extrair_inimigos_pack.gd`, `tools/extrair_chefes_packs.gd`,
`tools/extrair_efeitos.gd`, `tools/gerar_fundos_igreja.gd`,
`tools/importar_rig_cavaleiro.gd`.
