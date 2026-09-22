# Manifesto de aquisição — pacote aprovado

## Audio Vertical Slice — 22-09-2026

Aquisição no browser suportado, sem contornar login, CAPTCHA ou paywall. Os quatro ficheiros abaixo foram validados por `ffprobe` e ligados ao runtime. Os três MP3 estão intactos; só o dash foi editado. A build local é candidata de QA, não substitui a publicação oficial.

| Uso | Origem Pixabay | Ficheiro local | Aplicação / edição | Content ID |
| --- | --- | --- | --- | --- |
| Menu | [Cinematic Fantasy Dark — RomanSenykMusic](https://pixabay.com/music/fantasy-dreamy-childrens-cinematic-fantasy-dark-160932/) | `assets/audio/approved/menu_cinematic_fantasy_dark_no_intro.ogg` (derivada de `menu_cinematic_fantasy_dark.mp3`) | MENU MUSIC = versão derivada; -8 dB no player Music; primeiros 5,0 segundos removidos; loop/restart começa no novo início | Sim |
| Região I (níveis 1–5) | [Midnight Forest — Syouki_Takahashi](https://pixabay.com/music/ambient-midnight-forest-184304/) | `assets/audio/approved/region_01_midnight_forest.mp3` | Exploração, -8 dB no player Music; original sem edição | Sim |
| Boss 1 (Guardião Verde) | [Gothic Candlelight — JoelFazhari](https://pixabay.com/music/mystery-gothic-candlelight-gothic-mystery-soundtrack-1987/) | `assets/audio/approved/boss_01_gothic_candlelight.mp3` | Primeiro boss, -6 dB no player Music; original sem edição | Não indicado na página |
| Dash Koliani | [wind magic (5) — Yodguard](https://pixabay.com/sound-effects/film-special-effects-wind-magic-5-378630/) | `assets/audio/approved/koliani_dash_wind_magic_5.wav` | Derivado do MP3 local `assets/audio/acquisition/sfx/wind_magic_5.mp3`: primeiros 0,7 s, fade-out 0,45–0,7 s, -6 dB, mono 44,1 kHz; callsite -11 dB no bus SFX | Não indicado |

Todas as páginas acima indicam utilização sob a Pixabay Content License. Não redistribuir os ficheiros de origem isoladamente. As faixas com Content ID poderão exigir certificado/licença em vídeos publicados.

### SFX principais da Koliani — síntese original

Os SFX `koliani_hurt`, `koliani_death`, `koliani_jump`, `koliani_double_jump`,
`koliani_energy_hit`, `shadow_shield_on/hit`, `shadowblade_swing_1..3`,
`shadowblade_finisher` e `shadowblade_hit` são originais, gerados localmente por
`tools/gerar_sfx_koliani_signature.py` com ruído filtrado, envelopes, varrimentos
e parciais sintéticas. Os URLs Pixabay abaixo continuam apenas como referência
sonora; os downloads bloqueados por 403 não foram forçados nem redistribuídos.

As tentativas seguintes abriram páginas aprovadas de SFX mas não produziram ficheiro local verificável no browser suportado: `soft-body-impact-295404`, `drop-sound-effect-240899`, `shield-block-shortsword-143940`, `deep-impact-sound-effect-176434`, `fireball-impact-351961`, `sword-blade-slicing-flesh-352708`. `musical-hit-94706` apresenta o título “Hit” e não foi integrado sem confirmação de identidade. Sem ficheiro, mantêm-se os SFX anteriores nesses eventos; não declarar estes downloads concluídos.

### Histórico da tentativa anterior

Execução batch em 2026-09-21: 85/85 URLs tentadas com concorrência 4. O asset previamente obtido permanece em `assets/audio/acquisition/sfx/wind_magic_5.mp3` (1/44 SFX). As 85 páginas retornaram HTTP 403 ao cliente Python; não foram contornadas.

Execução batch: todas as URLs foram tentadas; nenhum asset foi integrado no código.

Resultado: 0/85 obtidos; 85 bloqueados.

## Resultados

- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-wind-magic-5-378630/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-walking-on-grass-363353/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/people-soft-body-impact-295404/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-drop-sound-effect-240899/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-shield-block-shortsword-143940/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-deep-impact-sound-effect-176434/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/musical-hit-94706/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-fireball-impact-351961/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-hit-flesh-02-266309/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-magic-chargeup-102051/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/household-wall-hit-1-100717/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-sword-blade-slicing-flesh-352708/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/app-interface-click-2-476372/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-minimalist-button-hover-sound-effect-399749/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/ui-button-sound-cancel-back-exit-continue-467877/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-error-notification-05-199276/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-soft-landing-intro-modern-stereo-332450/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-fantasy-game-sword-cut-sound-effect-2-get-more-on-my-patreon-339823/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-sci-fi-portal-jump-04-416161/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-coin-drop-229314/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-unlock-stinger-289722/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-item-pickup-1-540174/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-coin-collect-1-540179/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/household-unlock-the-door-2-99745/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-healing-magic-2-378663/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/technology-ui-success-chime-513565/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-game-respawn-153317/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-ui-menu-slide-in-516940/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-cinematic-whoosh-transition-impact-562431/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-biodynamic-impact-braam-tonal-dark-184276/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-rpg-sword-attack-combo-24-388941/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-hard-heavy-impact-515256/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/people-hurt-amp-death-pain-gurgle-543682/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-slap-hurt-pain-sound-effect-262618/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-scorpion-claw-attack-2-482516/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-fire-magic-5-378639/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-incoming-228343/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-electric-discharge-386160/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-water-splash-199583/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-rocks-6129/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/household-commercial-oven-door-mechanism-and-open-close-74847/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/nature-bubbling-6184/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-bear-trap-103800/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/sound-effects/film-special-effects-single-church-bell-2-352062/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/fantasy-dreamy-childrens-cinematic-fantasy-dark-160932/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/search/fantasy%20ambient%20forest/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/ambient-desert-wind-meditation-atmosphere-513281/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/adventure-church-choir-349262/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/main-title-a-sinister-power-rising-epic-dark-gothic-soundtrack-15021/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/fantasy-dreamy-childrens-shadows-beneath-the-keep-495833/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/mystery-desert-travels-391123/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-garden-of-morning-dew-cinematic-ambient-instrumental-562308/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/mystery-gothic-horror-178468/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/choir-epic-gregorian-choir-cinematic-soundtrack-355524/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-october-knows-cinematic-gothic-halloween-instrumental-574713/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/drama-scene-the-rolling-mist-cinematic-background-410782/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-dark-ambient-cinematic-566702/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-moving-staircases-567993/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-dark-578736/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/choir-gothic-ritual-dramatic-cinematic-choral-473167/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/search/orchestra%20gothic/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/modern-classical-moonpetal-nocturne-gothic-dream-pop-ballad-with-female-vocals-548586/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/epic-classical-empirex27s-fall-446040/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/main-title-the-dark-power-cinematic-orchestral-572891/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/mystery-esoteric-execution-epic-dark-and-horror-soundtrack-197591/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/mystery-gothic-candlelight-gothic-mystery-soundtrack-1987/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/adventure-epic-historical-orchestral-244718/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/choir-gothic-choir-dark-epic-choral-atmosphere-404794/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-epic-cinematic-music-powerful-583433/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/main-title-cinematic-epic-317751/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/build-up-scenes-epic-anxious-dark-dramatic-tragic-mystical-233461/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/main-title-destiny-theme-epic-orchestral-soundtrack-remastered-440512/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-dark-cinematic-epic-orchestral-background-01-527553/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/adventure-gothic-sacred-epic-male-chant-female-choir-amp-bells-422978/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/epic-classical-epic-508009/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/main-title-epic-hollywood-trailer-9489/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/build-up-scenes-the-villain-wins-dark-orchestral-piece-227548/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/adventure-dark-cinematic-epic-orchestral-background-02-527552/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/adventure-epic-fight-487416/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-dark-cinematic-558265/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-battle-boss-fight-game-music-583276/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/choir-epic-dark-cinematic-choir-music-for-trailers-and-dramatic-scenes-428827/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/orchestral-epic-enemy-578175/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/epic-classical-return-of-the-gods-dark-epic-free-soundtrack-2471/ — HTTP Error 403: Forbidden
- `BLOCKED` — https://pixabay.com/music/main-title-final-battle-ii-epic-cinematic-battle-music-with-intense-orchestral-361155/ — HTTP Error 403: Forbidden
