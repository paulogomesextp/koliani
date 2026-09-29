# Créditos de áudio

## Koliani Signature — Prompt 5 (21 set 2026)

Os 28 WAV de `koliani_signature/` são **síntese original** por
`tools/gerar_sfx_koliani_signature.py`: ruído filtrado, transientes,
varrimentos de frequência e ressonância Shadowblade. Não contêm samples de
terceiros nem dependem de downloads. O script é a fonte; os WAV são saída
reproduzível. Mono PCM 16-bit / 44,1 kHz. Os samples CC0 abaixo continuam
no repositório para os restantes usos e como histórico; não foram reclamados
como originais.

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

## SFX construídos por ferramenta (CC0 — 4 set 2026)

Pedido do Paulo: *"faça um set de sons para a Koliani quando faz animações,
ataques, etc. Faça com que os mobs façam sons também apropriados ao tipo de
monstro"* e *"continuo sem gostar do som da espada, dos mísseis"*.

Estes são construídos por **`tools/preparar_sfx.py`**, não copiados à mão.
A diferença que interessa: os sons de acção são feitos em **camadas**. Um
golpe de espada a sério são duas coisas ao mesmo tempo — o ar a abrir e o
metal a cantar, com ~30 ms entre elas — e uma amostra solta nunca dá isso
(foi por aí que as duas tentativas anteriores falharam). A ferramenta
mistura as camadas, alinha-as, apara o silêncio da frente, corta o rabo que
arrasta e iguala o pico de todos a -2 dBFS.

Sons novos: `passo1..3`, `rolamento`, `dash`, `parede` (deslizar),
`agarrar` (borda), `morte_koliani`, `ataque_forte` (remate do combo), e
**sons por família de monstro** — `mob_<família>_<ataque|dano|morte>` para
humano, morto, gosma, besta, insecto, voador e grande. As 19 espécies
mapeiam-se nas sete famílias em `demonio_base.gd::FAMILIA_SOM`; antes
partilhavam todas os mesmos quatro rosnados. Refeitos: `ataque` e `lancar`.

| Pack | Autor | Licença |
| --- | --- | --- |
| [passos](https://opengameart.org/content/different-steps-on-wood-stone-leaves-gravel-and-mud) | TinyWorlds | CC0 |
| [monstros](https://opengameart.org/content/monster-sound-effects-pack) | Ogrebane | CC0 |
| [criaturas2](https://opengameart.org/content/80-cc0-creture-sfx-2) | rubberduck | CC0 |
| [sfx100_2](https://opengameart.org/content/100-cc0-sfx-2) | rubberduck | CC0 |
| [kenney](https://opengameart.org/content/50-rpg-sound-effects) | Kenney | CC0 |

## Música de fundo -- tema do menu (fornecida pelo Paulo) -- RESERVA

- **`bg_menu.mp3`** — "The Alchemist's Library · Mysterious Dark Academia &
  Fantasy" — OneCinematicStudio.
- **`bg_niveis.mp3`** / **`bg_boss.mp3`** — faixas antigas fornecidas
  pelo Paulo.

Os três só tocam como **reserva** em `musica.gd` -- se as faixas aprovadas
abaixo (secção seguinte) não existirem num fresh checkout antes do
`--import`. Com o `--import` feito, quem toca no menu, nos níveis e nos
chefes são as faixas aprovadas Pixabay. `bg_boss.mp3` é, byte a byte, a
mesma faixa que `music/bosses/boss_20.mp3` ("Final Battle II", Nyxaurora) --
cópia legada duplicada de propósito, para a reserva funcionar mesmo que só
`bg_boss.mp3` sobreviva a uma limpeza futura.

Ficheiros entregues pelo Paulo; licença/uso à responsabilidade dele.

## Música de fundo aprovada -- menu + 20 regiões + 20 bosses (Pixabay Content License)

As 41 escolhas musicais que tocam por omissão (assumindo `--import` feito).
Proveniência confirmada por SHA-256: o menu e a Região 01/Boss 01 foram
validados contra os ficheiros de aquisição originais em 22-09-2026 (ver
`docs/audio/approved_audio_manifest.md`); as restantes 38 (Região 02-20 +
Boss 02-20) foram confirmadas em 24-09-2026 por comparação byte a byte entre
`C:\Projetos\koliani-sfx\incoming_music` (CSV de hashes fornecido pelo
Paulo) e os assets em `assets/audio/music/`. Todas sob Pixabay Content
License; não redistribuir os ficheiros de origem isoladamente.

| Uso | Título | Artista | URL Pixabay | Asset runtime |
| --- | --- | --- | --- | --- |
| Menu | Cinematic Fantasy Dark | RomanSenykMusic | https://pixabay.com/music/fantasy-dreamy-childrens-cinematic-fantasy-dark-160932/ | `approved/menu_cinematic_fantasy_dark_no_intro.ogg` |
| Região 01 (Floresta Corrompida) | Midnight Forest | Syouki_Takahashi | https://pixabay.com/music/ambient-midnight-forest-184304/ | `approved/region_01_midnight_forest.mp3` |
| Região 02 (Desfiladeiro dos Ventos) | Desert Wind Meditation Atmosphere | low_atmos | https://pixabay.com/music/ambient-desert-wind-meditation-atmosphere-513281/ | `music/regions/region_02.mp3` |
| Região 03 (Torres Esquecidas) | Church Choir | tunetank | https://pixabay.com/music/adventure-church-choir-349262/ | `music/regions/region_03.mp3` |
| Região 04 (Catacumbas do Abismo) | A Sinister Power Rising | joelfazhari | https://pixabay.com/music/main-title-a-sinister-power-rising-epic-dark-gothic-soundtrack-15021/ | `music/regions/region_04.mp3` |
| Região 05 (Cidade Corrompida) | Shadows Beneath the Keep | menieldm | https://pixabay.com/music/fantasy-dreamy-childrens-shadows-beneath-the-keep-495833/ | `music/regions/region_05.mp3` |
| Região 06 (Castelo de Zeriko) | Desert Travels | grand_project | https://pixabay.com/music/mystery-desert-travels-391123/ | `music/regions/region_06.mp3` |
| Região 07 (Terras Queimadas) | Garden of Morning Dew | tideblue | https://pixabay.com/music/orchestral-garden-of-morning-dew-cinematic-ambient-instrumental-562308/ | `music/regions/region_07.mp3` |
| Região 08 (Mar dos Mortos) | Gothic Horror | 23350895 | https://pixabay.com/music/mystery-gothic-horror-178468/ | `music/regions/region_08.mp3` |
| Região 09 (Reino do Gelo) | Epic Gregorian Choir | vjgalaxy | https://pixabay.com/music/choir-epic-gregorian-choir-cinematic-soundtrack-355524/ | `music/regions/region_09.mp3` |
| Região 10 (Deserto dos Esquecidos) | October Knows | moonpetalmedia | https://pixabay.com/music/orchestral-october-knows-cinematic-gothic-halloween-instrumental-574713/ | `music/regions/region_10.mp3` |
| Região 11 (Jardins do Rei) | The Rolling Mist | geoffharvey | https://pixabay.com/music/drama-scene-the-rolling-mist-cinematic-background-410782/ | `music/regions/region_11.mp3` |
| Região 12 (Cidade das Máquinas) | Dark Ambient Cinematic | everything_is_dead | https://pixabay.com/music/orchestral-dark-ambient-cinematic-566702/ | `music/regions/region_12.mp3` |
| Região 13 (Céu Partido) | Moving Staircases | tuck9 | https://pixabay.com/music/orchestral-moving-staircases-567993/ | `music/regions/region_13.mp3` |
| Região 14 (Reino dos Sonhos) | Dark | leberch | https://pixabay.com/music/orchestral-dark-578736/ | `music/regions/region_14.mp3` |
| Região 15 (Cidade dos Mortos) | Gothic Ritual | sonican | https://pixabay.com/music/choir-gothic-ritual-dramatic-cinematic-choral-473167/ | `music/regions/region_15.mp3` |
| Região 16 (Mar Vermelho) | Bloodlust | Nightcast | https://pixabay.com/music/mystery-bloodlust-176915/ | `music/regions/region_16.mp3` |
| Região 17 (Inferno) | Moonpetal Nocturne | moonpetalmedia | https://pixabay.com/music/modern-classical-moonpetal-nocturne-gothic-dream-pop-ballad-with-female-vocals-548586/ | `music/regions/region_17.mp3` |
| Região 18 (O Vazio) | Empire's Fall | rubyzephyr | https://pixabay.com/music/epic-classical-empirex27s-fall-446040/ | `music/regions/region_18.mp3` |
| Região 19 (Guerra dos Reinos) | The Dark Power | luis_humanoide | https://pixabay.com/music/main-title-the-dark-power-cinematic-orchestral-572891/ | `music/regions/region_19.mp3` |
| Região 20 (O Último Caminho) | Esoteric Execution -- Epic Dark and Horror | joelfazhari | https://pixabay.com/music/mystery-esoteric-execution-epic-dark-and-horror-soundtrack-197591/ | `music/regions/region_20.mp3` |
| Boss 01 (Guardião Verde) | Gothic Candlelight | JoelFazhari | https://pixabay.com/music/mystery-gothic-candlelight-gothic-mystery-soundtrack-1987/ | `approved/boss_01_gothic_candlelight.mp3` |
| Boss 02 (Guardião dos Céus) | Epic Historical Orchestral | musicinmedia | https://pixabay.com/music/adventure-epic-historical-orchestral-244718/ | `music/bosses/boss_02.mp3` |
| Boss 03 (Vyrak) | Gothic Choir -- Dark Epic Choral Atmosphere | sapan4 | https://pixabay.com/music/choir-gothic-choir-dark-epic-choral-atmosphere-404794/ | `music/bosses/boss_03.mp3` |
| Boss 04 (Guardião da Fornalha) | Epic Cinematic Music Powerful | echoes_of_lumen | https://pixabay.com/music/orchestral-epic-cinematic-music-powerful-583433/ | `music/bosses/boss_04.mp3` |
| Boss 05 (Oráculo do Vento) | Cinematic Epic | the_mountain | https://pixabay.com/music/main-title-cinematic-epic-317751/ | `music/bosses/boss_05.mp3` |
| Boss 06 (Mirage Eterna) | Epic Anxious Dark Dramatic Tragic Mystical | denis-pavlov-music | https://pixabay.com/music/build-up-scenes-epic-anxious-dark-dramatic-tragic-mystical-233461/ | `music/bosses/boss_06.mp3` |
| Boss 07 (Rainha Espinhosa) | Destiny Theme | joelfazhari | https://pixabay.com/music/main-title-destiny-theme-epic-orchestral-soundtrack-remastered-440512/ | `music/bosses/boss_07.mp3` |
| Boss 08 (Devorador da Cripta) | Dark Cinematic Epic Orchestral Background 01 | vjgalaxy | https://pixabay.com/music/orchestral-dark-cinematic-epic-orchestral-background-01-527553/ | `music/bosses/boss_08.mp3` |
| Boss 09 (Abade Naufragado) | Gothic Sacred Epic | soundsbyamelia | https://pixabay.com/music/adventure-gothic-sacred-epic-male-chant-female-choir-amp-bells-422978/ | `music/bosses/boss_09.mp3` |
| Boss 10 (Arconte do Conhecimento) | Epic -- The Mountain | the_mountain | https://pixabay.com/music/epic-classical-epic-508009/ | `music/bosses/boss_10.mp3` |
| Boss 11 (Senhor das Marés) | Epic Hollywood Trailer | good_b_music | https://pixabay.com/music/main-title-epic-hollywood-trailer-9489/ | `music/bosses/boss_11.mp3` |
| Boss 12 (Arauto da Pestilência) | The Villain Wins | nickpanek | https://pixabay.com/music/build-up-scenes-the-villain-wins-dark-orchestral-piece-227548/ | `music/bosses/boss_12.mp3` |
| Boss 13 (Soberano Invertido) | Dark Cinematic Epic Orchestral Background 02 | vjgalaxy | https://pixabay.com/music/adventure-dark-cinematic-epic-orchestral-background-02-527552/ | `music/bosses/boss_13.mp3` |
| Boss 14 (Oráculo Estelar) | Epic Fight | alec_koff | https://pixabay.com/music/adventure-epic-fight-487416/ | `music/bosses/boss_14.mp3` |
| Boss 15 (Arquialquimista Morvak) | Dark Cinematic | solarflex | https://pixabay.com/music/orchestral-dark-cinematic-558265/ | `music/bosses/boss_15.mp3` |
| Boss 16 (Malgor) | Battle Boss Fight Game Music | alex-morgan | https://pixabay.com/music/orchestral-battle-boss-fight-game-music-583276/ | `music/bosses/boss_16.mp3` |
| Boss 17 (Rainha do Sonho) | Epic Dark Cinematic Choir Music | desifreemusic | https://pixabay.com/music/choir-epic-dark-cinematic-choir-music-for-trailers-and-dramatic-scenes-428827/ | `music/bosses/boss_17.mp3` |
| Boss 18 (Colosso da Ruína) | Epic Enemy | bearstockmusic | https://pixabay.com/music/orchestral-epic-enemy-578175/ | `music/bosses/boss_18.mp3` |
| Boss 19 (Arquiteto do Limiar) | Return of The Gods | joelfazhari | https://pixabay.com/music/epic-classical-return-of-the-gods-dark-epic-free-soundtrack-2471/ | `music/bosses/boss_19.mp3` |
| Boss 20 (Zeriko) | Final Battle II | nyxaurora | https://pixabay.com/music/main-title-final-battle-ii-epic-cinematic-battle-music-with-intense-orchestral-361155/ | `music/bosses/boss_20.mp3` |

Detalhe completo da verificação por hash (44 MP3 em `incoming_music`, 38
conteúdos únicos, 6 duplicados, e a tabela ficheiro-original -> SHA-256 ->
asset) fica em `docs/audio/approved_audio_manifest.md`, secção "Verificação
por hash local -- 24-09-2026", para não duplicar aqui.

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

## Execution 9H.13 -- passe profissional dos SFX (12 set 2026)

Os sons abaixo foram REFEITOS de raiz por `tools/gerar_sfx_9h13.py`:
100% sintetizados neste repositorio, sem samples de terceiros, sem numpy e
sem licencas a creditar. Substituem as versoes anteriores com o mesmo nome.

Jogador: `salto`, `salto_duplo`, `aterrar`, `dash`, `rolamento`,
`passo1..3`, `morte_koliani`, `dano`.
Combate: `ataque`, `ataque2`, `ataque3`, `ataque_forte` (os quatro golpes do
combo, cada um com som proprio -- antes eram dois samples com `pitch_scale`),
`acerto`, `bloqueio`.
Mundo: `apanhar`, `selo` (checkpoint/fogueira), `transicao` (porta/portal).
Interface: `ui_mover`, `ui_confirmar`, `ui_voltar`, `ui_negado`.

Direccao: fantasia escura, cinematografico, impacto limpo. Cada som e' feito
de tres camadas (corpo grave + transiente curto + cauda com reverberacao) --
o cabecalho do gerador explica porque e' que uma camada so' soa a
sintetizador. Os picos sao hierarquizados no dicionario `ALVO`, entre 0,40
(`ui_mover`) e 0,92 (`ataque_forte`), portanto nenhum som chega a 1,0 e a
soma das 8 vozes do pool nao clipa.

## Execution 9H.13B -- redesenho depois do teste humano (13 set 2026)

O Game Master ouviu a build 0.18.6 e disse que os SFX pareciam iguais aos
anteriores. Estavam LIGADOS (os 13 eventos apontavam mesmo para os ficheiros
novos), mas o desenho estava errado e mediu-se porque:

- **normalizei por PICO em vez de SONORIDADE.** Os sons eram todo transiente
  e pouco corpo (crista 14-18 dB contra 8-12 dB do legado), por isso com o
  mesmo pico tinham muito menos energia. O `acerto` -- o som mais repetido do
  combate -- ficou **7,5 dB MAIS FRACO** do que o legado que substituia; os
  passos -6,2 dB; o `ui_mover` -12 dB;
- **os golpes eram mais longos do que o passo do combo** (0,64-0,94 s contra
  0,18-0,30 s), portanto sobrepunham-se 64-73% e a progressao 1->4 lia-se
  como uma papa em vez de quatro golpes.

Esta versao normaliza para sonoridade (`ALVO_DB`, RMS da janela de 100 ms
mais forte), encurta os golpes e faz a progressao 1->4 por TIMBRE (o registo
desce 2655 -> 1788 -> 838 Hz e entra distorcao suave), nao so' por volume.
Resultado medido, legado -> v1 -> v2: `acerto` -10,4 -> -17,9 -> **-9,5**;
passos -16,3 -> -22,5 -> **-17,1**; `bloqueio` -11,4 -> -12,7 -> **-9,6**.

---

## Mundo e progressao (SFX Overhaul, Prompt 3B)

Os 16 sons abaixo foram feitos de raiz por `tools/gerar_sfx_3b.py`, com o
mesmo metodo da 9H.13B: 100% sintetizados neste repositorio, sem samples de
terceiros, sem numpy e **sem licencas** -- nada aqui precisa de atribuicao.

```
vento_ciclo     vento_rajada    mecanismo       mecanismo_ciclo
portao_abre     portao_fecha    sino_mecanismo  pedra_racha
pedra_parte     lamina_passa    fogo_sopro      raio_aviso
raio_cai        bau_abrir       recompensa      desbloqueio
```

Existem porque 28 scripts de cenario (vento, sinos, elevadores, plataformas
que esboroam, pedras, laminas pendulares, raios) nao faziam barulho nenhum, e
os poucos que faziam pediam-no emprestado ao checkpoint (`selo`) ou aos
chefes (`onda`, `sino_ataque`, `conquista`). A auditoria completa, com as
medicoes e a hierarquia de sonoridade, esta' em
`docs/audio/world_progression_sfx_audit.md`.

`vento_ciclo` e `mecanismo_ciclo` sao os primeiros sons do jogo feitos para
tocar em CICLO: costurados com um crossfade de potencia constante, com a
juncao medida (0,02 e 0,30 dB) pelo proprio gerador.
