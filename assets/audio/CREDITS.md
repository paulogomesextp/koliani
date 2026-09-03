# Créditos de áudio

As **camas** `ambiente.wav`, `menu.wav`, `boss.wav`, `assombracao.wav` e
`game_over.wav` continuam sintetizadas por `tools/gerar_audio.py` (sem
licenças). Os **SFX de combate/mobs/UI** abaixo (`scripts/som.gd`) foram
trocados a 3 set 2026 por samples reais — todos **CC0** (domínio público),
descarregados do OpenGameArt.org; nenhum exige atribuição, mas fica
registado por transparência.

## SFX (CC0, OpenGameArt — 3 set 2026)

| Pack | Autor | Ficheiros usados |
| --- | --- | --- |
| [RPG Sound Pack](https://opengameart.org/content/rpg-sound-pack) | artisticdude | `ataque`, `invocar`, `apanhar`, `porta`, `carrossel`, `chefe_cai` (giant5) |
| [80 CC0 RPG SFX](https://opengameart.org/content/80-cc0-rpg-sfx) | rubberduck | `lancar`, `selo`, `chefe_magia`, `chama`, `feixe_vil`, `sino_ataque`, `engrenagem`, `lamina_cair` |
| [80 CC0 creature SFX](https://opengameart.org/content/80-cc0-creature-sfx) | rubberduck | `dano`, `demonio_ataque`, `garra`, `grito`, `praga` |
| [20 Sword Sound Effects](https://opengameart.org/content/20-sword-sound-effects-attacks-and-clashes) / [10 Impact/Shield Blocks](https://opengameart.org/content/10-impactshield-blocks) | StarNinjas | `acerto`, `esmagar`, `golpe_pesado`, `bloqueio` |
| [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack) | artisticdude | `salto`, `salto_duplo`, `projetil`, `investida`, `transicao` |
| [Jump Landing Sound](https://opengameart.org/content/jump-landing-sound) | qubodup | `aterrar` |
| [40 CC0 water/splash/slime SFX](https://opengameart.org/content/40-cc0-water-splash-slime-sfx) | rubberduck | `onda` |
| [Freeze Spell](https://opengameart.org/content/freeze-spell-0) | artisticdude | `gelo` |
| [Overloading Sound](https://opengameart.org/content/overloading-sound) | jwiese (dual CC-BY/**CC0**, usado sob CC0) | `raio`, `olho_carregar` |
| [Muffled Distant Explosion](https://opengameart.org/content/muffled-distant-explosion) | NenadSimic | `meteoro` |
| [Hyper-Ultra-Fanfare](https://opengameart.org/content/hyper-ultra-fanfare) | zane-little-music | `conquista` |
| RPG Sound Pack — `NPC/shade/shade3.wav` | artisticdude | `mudar_forma` |

## Música de fundo -- tema do menu (fornecida pelo Paulo)

- **`bg_menu.mp3`** — "The Alchemist's Library · Mysterious Dark Academia &
  Fantasy" — OneCinematicStudio. Abertura do jogo / menu inicial
  (`Musica.menu`).
- **`bg_niveis.mp3`** / **`bg_boss.mp3`** — faixas antigas de fornecidas
  pelo Paulo, ainda usadas como **reserva** por `musica.gd` (fresh
  checkout antes do `--import`). Fora isso, substituídas pelas 20+20
  faixas abaixo.

Ficheiros entregues pelo Paulo; licença/uso à responsabilidade dele.

## Música de níveis e de chefe — 20+20 em ciclo (3 set 2026)

Pedido do Paulo: "20 músicas de nível, em ciclo" e "20 de chefe" em vez de
uma faixa só a repetir por todos os níveis. `Musica.ambiente()`/`boss()`
escolhem por `indice_nivel % 20` (`scripts/musica.gd`). Todas do
OpenGameArt, **CC-BY** (creditar) ou **CC0**; nenhuma é CC-BY-SA. Cada
faixa foi cortada a ~70-80s com fade-out e recodificada a 64kbps mono
(`ffmpeg`, sem dependências no repo) para caber no orçamento de espaço —
o original de cada uma costuma ser mais longo, ver o link se quiseres a
versão completa.

`assets/audio/musica/niveis/nivel_01..20.ogg`:

| Pack | Autor | Licença | Faixas usadas (nº = índice) |
| --- | --- | --- | --- |
| [Essentials Pack for Fantasy Games — LOOP BOX #3](https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures) | Of Far Different Nature | CC-BY 4.0 | 01 Victory Stats · 02 Funny March · 03 Pavane [short] · 04 Ship In A Storm · 05 Obscurium · 06 Hurry! · 07 Underground Town · 08 Horny [v2] · 09 Pavane · 10 Eastern Treasures · 11 Adventure Begins · 12 Zwischenwelt · 13 Epic Departure [v2] · 14 Flow · 15 Throne Room [v2] · 16 In Darkness [v2] · 17 Clash |
| [Free Music Pack](https://opengameart.org/content/free-music-pack) | Alexander Ehlers (subm. tricksntraps) | CC0 | 18 Waking the devil · 19 Great mission · 20 Spacetime |

`assets/audio/musica/chefes/boss_01..20.ogg`:

| Pack | Autor | Licença | Faixas usadas |
| --- | --- | --- | --- |
| [JRPG Pack 5 (Action)](https://opengameart.org/content/jrpg-pack-5-action) | Juhani Junkala (subm. subspaceaudio) | CC0 | 01 Preparing For Battle · 02 Encounter With The Witches · 03 Army Approaching |
| [Action Music Pack](https://opengameart.org/content/action-music-pack) | marcelofg55 | CC-BY 3.0 | 04-08 (versões "Loop") + 09-13 (versões completas) de Lethal Injection, Battle of the Void, Flaming Soul, Black Rock, Desolation |
| [Battle Theme A](https://opengameart.org/content/battle-theme-a) / [B](https://opengameart.org/content/battle-theme-b-for-rpg) | cynicmusic | CC0 | 14, 15 |
| [Fast fight / battle music](https://opengameart.org/content/fast-fight-battle-music) | bonsaiheldin | CC0 | 16 |
| [Gods Forbid](https://opengameart.org/content/gods-forbid) | centurionofwar | CC0 | 17 |
| [Light battle theme](https://opengameart.org/content/light-battle-theme) | Alexandr Zhelanov | CC-BY 4.0 | 18 |
| [Wasteland Showdown](https://opengameart.org/content/wasteland-showdown-battle-music) | matthew-pablo | CC-BY 3.0 | 19 |
| [Rise of spirit](https://opengameart.org/content/rise-of-spirit) | Alexandr Zhelanov | CC-BY 3.0 | 20 |
