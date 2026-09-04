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

## Música de níveis e de chefe — 20+20 em ciclo (refeitas a 4 set 2026)

Pedido do Paulo: "20 músicas de nível, em ciclo" e "20 de chefe" em vez de
uma faixa só a repetir por todos os níveis. `Musica.ambiente()`/`boss()`
escolhem por `indice_nivel % 20` (`scripts/musica.gd`).

**Refeitas de raiz a 4 set 2026** por `tools/preparar_musica.py`, depois de
o Paulo se queixar de que "a música do Nível 32 é esquisita e tem vários
cortes" e de que "os níveis 1 e 2 têm a mesma música". A medição mostrou o
porquê: as faixas tocam **em ciclo**, e 8 das 20 de nível e 10 das 20 de
chefe tinham **fade-out** — de X em X segundos a música desaparecia e
voltava a entrar a todo o volume. Além disso 7 faixas de nível eram trocos
curtos de mais (a do nível 1 tinha **7,6 segundos** — era um jingle de
vitória, não uma cama; a do nível 2 tinha 8,0 s e vinha do mesmo álbum,
daí soarem iguais).

Agora cada faixa **fecha sobre si própria**: corta-se o troço útil, cruza-se
a cauda por cima da cabeça e iguala-se o volume a -16 LUFS. A regra é
verificável — `python tools/preparar_musica.py --verificar` sai != 0 se
alguma faixa for curta de mais ou tiver um degrau audível na costura.

Também a pedido dele ("adorei o final da música do Nível 38, se conseguir
mais músicas assim com tom de rock perfeito"), entraram **6 faixas de
rock/metal CC0 do autor [nene](https://opengameart.org/users/nene)** na
rotação dos níveis e mais 3 na dos chefes. A faixa que ele gostou fica
onde estava (`nivel_18` = nível 38); só se lhe tirou o fade final.

Todas do OpenGameArt, **CC0** ou **CC-BY** (creditar); nenhuma é CC-BY-SA.
Codificadas em ogg mono a 64 kbps.

### `assets/audio/musica/niveis/nivel_01..20.ogg`

| Ficheiro | Faixa e autor | Licença | Página |
| --- | --- | --- | --- |
| `nivel_01.ogg` | Unchained Destiny [Rock] -- nene, CC0 | CC0 | https://opengameart.org/content/unchained-destiny-rock |
| `nivel_02.ogg` | Fight for Better Future [Rock/Metal] -- nene, CC0 | CC0 | https://opengameart.org/content/fight-for-better-future-rockmetal |
| `nivel_03.ogg` | Adventure Begins -- Of Far Different Nature | CC-BY 4.0 | https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures |
| `nivel_04.ogg` | Boss Battle #9 [Metal] -- nene, CC0 | CC0 | https://opengameart.org/content/boss-battle-9-metal |
| `nivel_05.ogg` | Doomed -- Alexander Ehlers | CC0 | https://opengameart.org/content/free-music-pack |
| `nivel_06.ogg` | Twists -- Alexander Ehlers | CC0 | https://opengameart.org/content/free-music-pack |
| `nivel_07.ogg` | Warped -- Alexander Ehlers | CC0 | https://opengameart.org/content/free-music-pack |
| `nivel_08.ogg` | Horny [v2] -- Of Far Different Nature | CC-BY 4.0 | https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures |
| `nivel_09.ogg` | Pavane -- Of Far Different Nature | CC-BY 4.0 | https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures |
| `nivel_10.ogg` | Eastern Treasures -- Of Far Different Nature (tinha fade-in) | CC-BY 4.0 | https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures |
| `nivel_11.ogg` | Boss Battle #8 [Metal] -- nene, CC0 | CC0 | https://opengameart.org/content/boss-battle-8-metal |
| `nivel_12.ogg` | Once More [Metal] -- nene, CC0 (NIVEL 32: troca pedida pelo Paulo) | CC0 | https://opengameart.org/content/once-more-metal |
| `nivel_13.ogg` | Epic Departure [v2] -- Of Far Different Nature | CC-BY 4.0 | https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures |
| `nivel_14.ogg` | Flow -- Of Far Different Nature | CC-BY 4.0 | https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures |
| `nivel_15.ogg` | Throne Room [v2] -- Of Far Different Nature | CC-BY 4.0 | https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures |
| `nivel_16.ogg` | In Darkness [v2] -- Of Far Different Nature | CC-BY 4.0 | https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures |
| `nivel_17.ogg` | Flags -- Alexander Ehlers | CC0 | https://opengameart.org/content/free-music-pack |
| `nivel_18.ogg` | Waking the devil -- Alexander Ehlers (NIVEL 38: a preferida do Paulo) | CC0 | https://opengameart.org/content/free-music-pack |
| `nivel_19.ogg` | Great mission -- Alexander Ehlers | CC0 | https://opengameart.org/content/free-music-pack |
| `nivel_20.ogg` | Spacetime -- Alexander Ehlers | CC0 | https://opengameart.org/content/free-music-pack |

### `assets/audio/musica/chefes/boss_01..20.ogg`

| Ficheiro | Faixa e autor | Licença | Página |
| --- | --- | --- | --- |
| `boss_01.ogg` | Preparing For Battle -- Juhani Junkala | CC0 | https://opengameart.org/content/jrpg-pack-5-action |
| `boss_02.ogg` | Encounter With The Witches -- Juhani Junkala | CC0 | https://opengameart.org/content/jrpg-pack-5-action |
| `boss_03.ogg` | Army Approaching -- Juhani Junkala | CC0 | https://opengameart.org/content/jrpg-pack-5-action |
| `boss_04.ogg` | Lethal Injection (Loop) -- marcelofg55 | CC-BY 3.0 | https://opengameart.org/content/action-music-pack |
| `boss_05.ogg` | Battle of the Void (Loop) -- marcelofg55 | CC-BY 3.0 | https://opengameart.org/content/action-music-pack |
| `boss_06.ogg` | Flaming Soul (Loop) -- marcelofg55 | CC-BY 3.0 | https://opengameart.org/content/action-music-pack |
| `boss_07.ogg` | Black Rock (Loop) -- marcelofg55 | CC-BY 3.0 | https://opengameart.org/content/action-music-pack |
| `boss_08.ogg` | Desolation (Loop) -- marcelofg55 | CC-BY 3.0 | https://opengameart.org/content/action-music-pack |
| `boss_09.ogg` | Boss Battle #2 [Symphonic Metal] -- nene, CC0 | CC0 | https://opengameart.org/content/boss-battle-2-symphonic-metal |
| `boss_10.ogg` | Boss Battle 10 [Metal] -- nene, CC0 | CC0 | https://opengameart.org/content/boss-battle-10-metal |
| `boss_11.ogg` | Short Theme [Rock/Metal] V2 -- nene, CC0 | CC0 | https://opengameart.org/content/short-theme-rockmetal |
| `boss_12.ogg` | Heart of Machine -- Alexandr Zhelanov | CC-BY 3.0 | https://opengameart.org/content/heart-of-machine |
| `boss_13.ogg` | It's Our Battle -- Alexandr Zhelanov | CC-BY 3.0 | https://opengameart.org/content/its-our-battle |
| `boss_14.ogg` | Battle Theme A -- cynicmusic | CC0 | https://opengameart.org/content/battle-theme-a |
| `boss_15.ogg` | Battle Theme B -- cynicmusic | CC0 | https://opengameart.org/content/battle-theme-b-for-rpg |
| `boss_16.ogg` | Vilified -- matthew-pablo | CC-BY 3.0 | https://opengameart.org/content/vilified |
| `boss_17.ogg` | Gods Forbid -- centurionofwar | CC0 | https://opengameart.org/content/gods-forbid |
| `boss_18.ogg` | Light battle theme -- Alexandr Zhelanov | CC-BY 4.0 | https://opengameart.org/content/light-battle-theme |
| `boss_19.ogg` | Wasteland Showdown -- matthew-pablo | CC-BY 3.0 | https://opengameart.org/content/wasteland-showdown-battle-music |
| `boss_20.ogg` | Rise of spirit -- Alexandr Zhelanov | CC-BY 3.0 | https://opengameart.org/content/rise-of-spirit |
