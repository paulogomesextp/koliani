# Manifesto de aquisição — pacote aprovado

## Audio Vertical Slice — 22-09-2026

Aquisição no browser suportado, sem contornar login, CAPTCHA ou paywall. Os quatro ficheiros abaixo foram validados por `ffprobe` e ligados ao runtime. Os três MP3 estão intactos; só o dash foi editado. A build local é candidata de QA, não substitui a publicação oficial.

| Uso | Origem Pixabay | Ficheiro local | Aplicação / edição | Content ID |
| --- | --- | --- | --- | --- |
| Menu | [Cinematic Fantasy Dark — RomanSenykMusic](https://pixabay.com/music/fantasy-dreamy-childrens-cinematic-fantasy-dark-160932/) | `assets/audio/approved/menu_cinematic_fantasy_dark_no_intro.ogg` (derivada de `menu_cinematic_fantasy_dark.mp3`) | MENU MUSIC = versão derivada; -8 dB no player Music; primeiros 5,0 segundos removidos; loop/restart começa no novo início | Sim |
| Região I (níveis 1–5) | [Midnight Forest — Syouki_Takahashi](https://pixabay.com/music/ambient-midnight-forest-184304/) | `assets/audio/approved/region_01_midnight_forest.mp3` | Exploração, -8 dB no player Music; original sem edição | Sim |
| Boss 1 (Guardião Verde) | [Gothic Candlelight — JoelFazhari](https://pixabay.com/music/mystery-gothic-candlelight-gothic-mystery-soundtrack-1987/) | `assets/audio/approved/boss_01_gothic_candlelight.mp3` | Primeiro boss; original sem edição. Volume nominal -6 dB, mais +4 dB de compensação no playback do pacote final | Não indicado na página |
| Dash Koliani | [wind magic (5) — Yodguard](https://pixabay.com/sound-effects/film-special-effects-wind-magic-5-378630/) | `assets/audio/approved/koliani_dash_wind_magic_5.wav` | Derivado do MP3 local `assets/audio/acquisition/sfx/wind_magic_5.mp3`: primeiros 0,7 s, fade-out 0,45–0,7 s, -6 dB, mono 44,1 kHz; callsite -11 dB no bus SFX | Não indicado |

Todas as páginas acima indicam utilização sob a Pixabay Content License. Não redistribuir os ficheiros de origem isoladamente. As faixas com Content ID poderão exigir certificado/licença em vídeos publicados.

## Auditoria dirigida de música e SFX de progressão/UI (22-09-2026)

**Região 01.** O ficheiro `region_01_midnight_forest.mp3` tem 5 385 822 bytes,
168,306938 s e SHA-256
`FFF5269D4C05BF3DB5454567E6C2CC47655E5572E0736AC4C4A2EE271AB408BB`.
É byte idêntico a `syouki_takahashi-midnight-forest-184304.mp3` em Downloads.
`Main._ready()` chama `Musica.ambiente(0)` e o player recebe esse stream no
arranque real do Nível 1. A substituição vinha de `Musica.intensificar()`, que
tocava `regiao1_combate.wav` depois de golpes; com a faixa aprovada presente,
essa troca foi desativada. O teste confirma o stream antes e depois de
`intensificar()`. `-- --jogar --audio-qa` imprime o caminho recebido pelo player.
Escuta humana do combate continua necessária.

Os 16 URLs seguintes são **referências aprovadas**, mas os ficheiros
correspondentes não estão identificáveis no repositório, `incoming_music/`,
Downloads, Desktop ou Documents. O único SFX Pixabay de aquisição local é
`wind_magic_5.mp3` (dash). `OLD_ASSET` e `MISSING_APPROVED_SOURCE` podem
coexistir: o primeiro descreve o stream atual; o segundo, a fonte aprovada
ausente. Nenhum item abaixo foi marcado `INTEGRATED`.

| EVENT | STATUS | LOCAL ASSET / chamada real | SOURCE / REFERENCE |
| --- | --- | --- | --- |
| Chest open / reward | OLD_ASSET + MISSING_APPROVED_SOURCE | `BauChefe._som_do_bau()` → `bau_abrir.wav`, depois `recompensa.wav` | [Coin Drop](https://pixabay.com/sound-effects/film-special-effects-coin-drop-229314/) |
| Level complete | OLD_ASSET + MISSING_APPROVED_SOURCE | `Porta._concluir()` → `transicao.wav` | [Soft Landing Intro Modern Stereo](https://pixabay.com/sound-effects/film-special-effects-soft-landing-intro-modern-stereo-332450/) |
| Checkpoint | OLD_ASSET + MISSING_APPROVED_SOURCE | `Checkpoint` → `selo.wav` | [Fantasy Game Sword Cut 2](https://pixabay.com/sound-effects/film-special-effects-fantasy-game-sword-cut-sound-effect-2-get-more-on-my-patreon-339823/) |
| Portal | OLD_ASSET + MISSING_APPROVED_SOURCE | `Portal` → `transicao.wav` | [Sci-Fi Portal Jump 04](https://pixabay.com/sound-effects/film-special-effects-sci-fi-portal-jump-04-416161/) |
| Ability unlock | OLD_ASSET + MISSING_APPROVED_SOURCE | `Coletavel`/`Santuario` → `desbloqueio.wav` | [Unlock Stinger](https://pixabay.com/sound-effects/film-special-effects-unlock-stinger-289722/) |
| Normal pickup | OLD_ASSET + MISSING_APPROVED_SOURCE | `Coletavel`/`Essencia` → `apanhar.wav` | [Item Pickup 1](https://pixabay.com/sound-effects/film-special-effects-item-pickup-1-540174/) |
| Rare pickup | MISSING_APPROVED_SOURCE | Sem evento próprio identificado; `BauChefe` usa `recompensa.wav` | [Coin Collect 1](https://pixabay.com/sound-effects/film-special-effects-coin-collect-1-540179/) |
| Unlock door | MISSING_APPROVED_SOURCE | Sem callsite de unlock door identificado; `porta.wav` só aparece no editor de layout | [Unlock the Door 2](https://pixabay.com/sound-effects/household-unlock-the-door-2-99745/) |
| Heal | MISSING_APPROVED_SOURCE | Sem callsite de SFX de cura identificado | [Healing Magic 2](https://pixabay.com/sound-effects/film-special-effects-healing-magic-2-378663/) |
| Save / autosave | MISSING_APPROVED_SOURCE | `EstadoJogo`/`SaveFoundation` sem callsite de SFX | [UI Success Chime](https://pixabay.com/sound-effects/technology-ui-success-chime-513565/) |
| Respawn | MISSING_APPROVED_SOURCE | `Koliani.recuperar_no_checkpoint()` sem callsite de SFX | [Game Respawn](https://pixabay.com/sound-effects/film-special-effects-game-respawn-153317/) |
| Menu / panel open-close | MISSING_APPROVED_SOURCE | Sem evento próprio de abertura/fecho identificado | [UI Menu Slide In](https://pixabay.com/sound-effects/film-special-effects-ui-menu-slide-in-516940/) |
| UI confirm | OLD_ASSET + MISSING_APPROVED_SOURCE | `MenuInicial`/`SeletorNiveis` → `ui_confirmar.wav` | [Interface Click 2](https://pixabay.com/sound-effects/app-interface-click-2-476372/) |
| UI hover | OLD_ASSET + MISSING_APPROVED_SOURCE | Foco/hover do `MenuInicial` → `ui_mover.wav` ou variantes `_v2`/`_v3` | [Minimalist Button Hover](https://pixabay.com/sound-effects/film-special-effects-minimalist-button-hover-sound-effect-399749/) |
| UI back / cancel | OLD_ASSET + MISSING_APPROVED_SOURCE | `MenuInicial`/`SeletorNiveis` → `ui_voltar.wav` | [UI Button Cancel](https://pixabay.com/sound-effects/ui-button-sound-cancel-back-exit-continue-467877/) |
| UI error | OLD_ASSET + MISSING_APPROVED_SOURCE | `SeletorNiveis`/`Santuario` → `ui_negado.wav` | [Error Notification 05](https://pixabay.com/sound-effects/film-special-effects-error-notification-05-199276/) |

Para QA, `--audio-qa` após `--` ativa linhas
`[AUDIO_QA] event=<event> stream=<resource_path>` nos players reais, sem
logging em execução normal. No baú esperado há uma chamada `bau_abrir` e uma
`recompensa` 0,36 s depois; na conclusão do nível, uma `transicao` disparada
por `Porta._concluir()`. Os WAV atuais são sintetizados/legados do projeto,
não os ficheiros dos URLs. Amostras medidas por `ffprobe`/SHA-256:
`bau_abrir.wav` 0,780 s / `67496166C0AC662F39D38F558A2278A168A93BF29E91B6EDC04BEB8B73915701`;
`recompensa.wav` 1,300 s / `0125FFC1FA88B34C990B6D9F10AF33C93FDB3C9088A47DF3845E4C08EBDE2E89`;
`transicao.wav` 1,050 s / `4648D067E7C39C064D908AA9354BC0509A7A4BE524063B02BDD7A652304CBFE0`.

### Percurso de escuta dirigido

Arrancar a branch com `-- --jogar --audio-qa` e save de QA isolado. No Nível 1,
confirmar no log `event=music stream=res://assets/audio/approved/region_01_midnight_forest.mp3`;
combater e confirmar que não surge `regiao1_combate.wav`. Num baú real,
confirmar exatamente um `event=bau_abrir` e um `event=recompensa`, nesta ordem,
sem `apanhar` adicional. Ao atravessar a porta de fim de nível, confirmar
exatamente um `event=transicao` emitido por essa porta; o portal independente
também usa hoje `transicao.wav`, pelo que o log do evento tem de ser associado
ao momento e ao callsite. Estes dois WAV continuam antigos até serem obtidos
os ficheiros aprovados; este percurso valida o diagnóstico, não o aprova.

## Aquisição manual entregue pelo Paulo — 23-09-2026

Foram recebidos 17 MP3 em `C:\Projetos\koliani-sfx\incoming_sfx`: 14 conteúdos
distintos, três cópias de Coin Drop e duas de Soft Landing. `ffprobe` confirmou
codec MP3, duração positiva, 2 canais e taxas de 24–48 kHz. Os 14 originais
selecionados ficam em `incoming_sfx/` (fora do export) e cópias sem edição em
`assets/audio/approved/sfx/`. O harness `test_approved_progression_sfx.tscn`
confirma o SHA-256 de cada asset e o mapping do catálogo runtime.

Ainda em 23-09-2026 foram entregues separadamente os dois ficheiros que
faltavam: `game-respawn-153317` como `respawn.mp3` e
`ui-menu-slide-in-516940` como `menu_panel.mp3`. Godot 4.7.2 importou ambos
como `AudioStreamMP3`; o harness crítico prova os callsites reais de respawn e
de abertura do painel de opções.

| EVENT | STATUS | LOCAL ASSET | SOURCE / REFERENCE |
| --- | --- | --- | --- |
| Chest open / reward | APPROVED_EXACT | `approved/sfx/chest_coin_drop.mp3`; `BauChefe` dispara exatamente uma voz | [Coin Drop](https://pixabay.com/sound-effects/film-special-effects-coin-drop-229314/) |
| Level complete | APPROVED_EXACT | `approved/sfx/level_complete_soft_landing.mp3`; `Porta._concluir()` → `transicao` | [Soft Landing Intro Modern Stereo](https://pixabay.com/sound-effects/film-special-effects-soft-landing-intro-modern-stereo-332450/) |
| Checkpoint | APPROVED_EXACT | `approved/sfx/checkpoint_sword_cut.mp3`; `Checkpoint` → `selo` | [Fantasy Game Sword Cut 2](https://pixabay.com/sound-effects/film-special-effects-fantasy-game-sword-cut-sound-effect-2-get-more-on-my-patreon-339823/) |
| Portal | APPROVED_EXACT | `approved/sfx/portal_jump.mp3`; evento próprio `portal` | [Sci-Fi Portal Jump 04](https://pixabay.com/sound-effects/film-special-effects-sci-fi-portal-jump-04-416161/) |
| Ability unlock | APPROVED_EXACT | `approved/sfx/ability_unlock_stinger.mp3` | [Unlock Stinger](https://pixabay.com/sound-effects/film-special-effects-unlock-stinger-289722/) |
| Normal pickup | APPROVED_EXACT | `approved/sfx/pickup_normal.mp3` | [Item Pickup 1](https://pixabay.com/sound-effects/film-special-effects-item-pickup-1-540174/) |
| Rare pickup | WRONG_MAPPING | `approved/sfx/pickup_rare.mp3` está no catálogo como `apanhar_raro`, mas não existe callsite raro inequívoco | [Coin Collect 1](https://pixabay.com/sound-effects/film-special-effects-coin-collect-1-540179/) |
| Unlock door | APPROVED_EXACT | `approved/sfx/unlock_door.mp3`; `PortaTrancada` → `portao_abre` | [Unlock the Door 2](https://pixabay.com/sound-effects/household-unlock-the-door-2-99745/) |
| Heal | WRONG_MAPPING | `approved/sfx/heal_magic.mp3` está no catálogo como `curar`, mas o jogo não tem callsite de cura do jogador | [Healing Magic 2](https://pixabay.com/sound-effects/film-special-effects-healing-magic-2-378663/) |
| Save / autosave | WRONG_MAPPING | `approved/sfx/save_success.mp3` está no catálogo como `guardar`; não é disparado porque saves também ocorrem durante morte e empilhava sobre o SFX aprovado de morte | [UI Success Chime](https://pixabay.com/sound-effects/technology-ui-success-chime-513565/) |
| Respawn | APPROVED_EXACT | `approved/sfx/respawn.mp3`; `Koliani.recuperar_no_checkpoint()` dispara exatamente uma voz | [Game Respawn](https://pixabay.com/sound-effects/film-special-effects-game-respawn-153317/) |
| Menu / panel open-close | APPROVED_EXACT | `approved/sfx/menu_panel.mp3`; menus inicial, opções e pausa usam `menu_painel` | [UI Menu Slide In](https://pixabay.com/sound-effects/film-special-effects-ui-menu-slide-in-516940/) |
| UI confirm | APPROVED_EXACT | `approved/sfx/ui_confirm.mp3` | [Interface Click 2](https://pixabay.com/sound-effects/app-interface-click-2-476372/) |
| UI hover | APPROVED_EXACT | `approved/sfx/ui_hover.mp3`; variantes antigas desativadas | [Minimalist Button Hover](https://pixabay.com/sound-effects/film-special-effects-minimalist-button-hover-sound-effect-399749/) |
| UI back / cancel | APPROVED_EXACT | `approved/sfx/ui_back.mp3` | [UI Button Cancel](https://pixabay.com/sound-effects/ui-button-sound-cancel-back-exit-continue-467877/) |
| UI error | APPROVED_EXACT | `approved/sfx/ui_error.mp3` | [Error Notification 05](https://pixabay.com/sound-effects/film-special-effects-error-notification-05-199276/) |

Os três `WRONG_MAPPING` acima significam “fonte aprovada presente, sem evento
runtime inequívoco”; não se inventou um callsite. Não permanecem downloads
manuais deste lote. O trace `--audio-qa` mostra os caminhos reais apenas em QA.

### SFX principais da Koliani — síntese original

Os SFX `koliani_hurt`, `koliani_death`, `koliani_jump`, `koliani_double_jump`,
`koliani_energy_hit`, `shadow_shield_on/hit`, `shadowblade_swing_1..3`,
`shadowblade_finisher` e `shadowblade_hit` são originais, gerados localmente por
`tools/gerar_sfx_koliani_signature.py` com ruído filtrado, envelopes, varrimentos
e parciais sintéticas. Os URLs Pixabay abaixo continuam apenas como referência
sonora; os downloads bloqueados por 403 não foram forçados nem redistribuídos.

O double jump reutiliza exactamente `koliani_jump.wav` (sem variante/pitch).
O bus central `SFX` recebe agora um headroom fixo de −6,0 dB; `Music` e todos
os buses de música permanecem sem alteração. As famílias de inimigos e bosses
reutilizam os mappings existentes por material, com hurt/death separados,
cooldowns e prioridade de morte preservados.

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


## Integração das 38 faixas pendentes — pacote local completo (22-09-2026)

Fonte local: `incoming_music/`; os 38 IDs dos nomes de ficheiro foram cruzados com o manifesto canónico (`music_manifest.csv` e `music_manifest.json`) e as páginas Pixabay indicadas. Os MP3 foram copiados sem edição, sem duplicar originais dentro dos assets. Aplicam-se a Pixabay Content License e as notas de Content ID da página de cada faixa; nos vídeos publicados poderá ser necessário o certificado. Menu, Região 01 e Boss 01 continuam nos caminhos aprovados acima. O runtime usa uma faixa por região de cinco níveis e a faixa de boss da mesma região.

Medição técnica com `ffmpeg volumedetect` nos 40 MP3: médias de -22,0 a -8,4 dBFS, picos até 0,0 dBFS na origem. `Musica` conserva os valores nominais -8 dB (região/menu) e -6 dB (boss) e aplica apenas compensações de reprodução aos extremos: regiões 02 -3, 11 +4, 15 -4, 16 +3, 19 +3 dB; bosses 01 +4, 03 +2, 04 -3, 09 +3, 14 -4, 15 -4, 16 -3, 19 -3 dB. O menu e os MP3 não foram editados. Fades de 0,9 s permanecem. Esta medição não substitui escuta humana para aprovar balanço artístico e loops.

| Uso | Título | Artista (ficheiro) | URL Pixabay | Asset local | Estado |
| --- | --- | --- | --- | --- | --- |
| Região 02 | Desert Wind Meditation Atmosphere | low_atmos | https://pixabay.com/music/ambient-desert-wind-meditation-atmosphere-513281/ | `assets/audio/music/regions/region_02.mp3` | INTEGRATED (local) |
| Região 03 | Church Choir | tunetank | https://pixabay.com/music/adventure-church-choir-349262/ | `assets/audio/music/regions/region_03.mp3` | INTEGRATED (local) |
| Região 04 | A Sinister Power Rising | joelfazhari | https://pixabay.com/music/main-title-a-sinister-power-rising-epic-dark-gothic-soundtrack-15021/ | `assets/audio/music/regions/region_04.mp3` | INTEGRATED (local) |
| Região 05 | Shadows Beneath the Keep | menieldm | https://pixabay.com/music/fantasy-dreamy-childrens-shadows-beneath-the-keep-495833/ | `assets/audio/music/regions/region_05.mp3` | INTEGRATED (local) |
| Região 06 | Desert Travels | grand_project | https://pixabay.com/music/mystery-desert-travels-391123/ | `assets/audio/music/regions/region_06.mp3` | INTEGRATED (local) |
| Região 07 | Garden of Morning Dew | tideblue | https://pixabay.com/music/orchestral-garden-of-morning-dew-cinematic-ambient-instrumental-562308/ | `assets/audio/music/regions/region_07.mp3` | INTEGRATED (local) |
| Região 08 | Gothic Horror | 23350895 | https://pixabay.com/music/mystery-gothic-horror-178468/ | `assets/audio/music/regions/region_08.mp3` | INTEGRATED (local) |
| Região 09 | Epic Gregorian Choir | vjgalaxy | https://pixabay.com/music/choir-epic-gregorian-choir-cinematic-soundtrack-355524/ | `assets/audio/music/regions/region_09.mp3` | INTEGRATED (local) |
| Região 10 | October Knows | moonpetalmedia | https://pixabay.com/music/orchestral-october-knows-cinematic-gothic-halloween-instrumental-574713/ | `assets/audio/music/regions/region_10.mp3` | INTEGRATED (local) |
| Região 11 | The Rolling Mist | geoffharvey | https://pixabay.com/music/drama-scene-the-rolling-mist-cinematic-background-410782/ | `assets/audio/music/regions/region_11.mp3` | INTEGRATED (local) |
| Região 12 | Dark Ambient Cinematic | everything_is_dead | https://pixabay.com/music/orchestral-dark-ambient-cinematic-566702/ | `assets/audio/music/regions/region_12.mp3` | INTEGRATED (local) |
| Região 13 | Moving Staircases | tuck9 | https://pixabay.com/music/orchestral-moving-staircases-567993/ | `assets/audio/music/regions/region_13.mp3` | INTEGRATED (local) |
| Região 14 | Dark | leberch | https://pixabay.com/music/orchestral-dark-578736/ | `assets/audio/music/regions/region_14.mp3` | INTEGRATED (local) |
| Região 15 | Gothic Ritual | sonican | https://pixabay.com/music/choir-gothic-ritual-dramatic-cinematic-choral-473167/ | `assets/audio/music/regions/region_15.mp3` | INTEGRATED (local) |
| Região 16 | Bloodlust | nightcast | https://pixabay.com/music/mystery-bloodlust-176915/ | `assets/audio/music/regions/region_16.mp3` | INTEGRATED (local) |
| Região 17 | Moonpetal Nocturne | moonpetalmedia | https://pixabay.com/music/modern-classical-moonpetal-nocturne-gothic-dream-pop-ballad-with-female-vocals-548586/ | `assets/audio/music/regions/region_17.mp3` | INTEGRATED (local) |
| Região 18 | Empire's Fall | rubyzephyr | https://pixabay.com/music/epic-classical-empirex27s-fall-446040/ | `assets/audio/music/regions/region_18.mp3` | INTEGRATED (local) |
| Região 19 | The Dark Power | luis_humanoide | https://pixabay.com/music/main-title-the-dark-power-cinematic-orchestral-572891/ | `assets/audio/music/regions/region_19.mp3` | INTEGRATED (local) |
| Região 20 | Esoteric Execution – Epic Dark and Horror | joelfazhari | https://pixabay.com/music/mystery-esoteric-execution-epic-dark-and-horror-soundtrack-197591/ | `assets/audio/music/regions/region_20.mp3` | INTEGRATED (local) |
| Boss 02 | Epic Historical Orchestral | musicinmedia | https://pixabay.com/music/adventure-epic-historical-orchestral-244718/ | `assets/audio/music/bosses/boss_02.mp3` | INTEGRATED (local) |
| Boss 03 | Gothic Choir – Dark Epic Choral Atmosphere | sapan4 | https://pixabay.com/music/choir-gothic-choir-dark-epic-choral-atmosphere-404794/ | `assets/audio/music/bosses/boss_03.mp3` | INTEGRATED (local) |
| Boss 04 | Epic Cinematic Music Powerful | echoes_of_lumen | https://pixabay.com/music/orchestral-epic-cinematic-music-powerful-583433/ | `assets/audio/music/bosses/boss_04.mp3` | INTEGRATED (local) |
| Boss 05 | Cinematic Epic | the_mountain | https://pixabay.com/music/main-title-cinematic-epic-317751/ | `assets/audio/music/bosses/boss_05.mp3` | INTEGRATED (local) |
| Boss 06 | Epic Anxious Dark Dramatic Tragic Mystical | denis-pavlov-music | https://pixabay.com/music/build-up-scenes-epic-anxious-dark-dramatic-tragic-mystical-233461/ | `assets/audio/music/bosses/boss_06.mp3` | INTEGRATED (local) |
| Boss 07 | Destiny Theme | joelfazhari | https://pixabay.com/music/main-title-destiny-theme-epic-orchestral-soundtrack-remastered-440512/ | `assets/audio/music/bosses/boss_07.mp3` | INTEGRATED (local) |
| Boss 08 | Dark Cinematic Epic Orchestral Background 01 | vjgalaxy | https://pixabay.com/music/orchestral-dark-cinematic-epic-orchestral-background-01-527553/ | `assets/audio/music/bosses/boss_08.mp3` | INTEGRATED (local) |
| Boss 09 | Gothic Sacred Epic | soundsbyamelia | https://pixabay.com/music/adventure-gothic-sacred-epic-male-chant-female-choir-amp-bells-422978/ | `assets/audio/music/bosses/boss_09.mp3` | INTEGRATED (local) |
| Boss 10 | Epic – The Mountain | the_mountain | https://pixabay.com/music/epic-classical-epic-508009/ | `assets/audio/music/bosses/boss_10.mp3` | INTEGRATED (local) |
| Boss 11 | Epic Hollywood Trailer | good_b_music | https://pixabay.com/music/main-title-epic-hollywood-trailer-9489/ | `assets/audio/music/bosses/boss_11.mp3` | INTEGRATED (local) |
| Boss 12 | The Villain Wins | nickpanek | https://pixabay.com/music/build-up-scenes-the-villain-wins-dark-orchestral-piece-227548/ | `assets/audio/music/bosses/boss_12.mp3` | INTEGRATED (local) |
| Boss 13 | Dark Cinematic Epic Orchestral Background 02 | vjgalaxy | https://pixabay.com/music/adventure-dark-cinematic-epic-orchestral-background-02-527552/ | `assets/audio/music/bosses/boss_13.mp3` | INTEGRATED (local) |
| Boss 14 | Epic Fight | alec_koff | https://pixabay.com/music/adventure-epic-fight-487416/ | `assets/audio/music/bosses/boss_14.mp3` | INTEGRATED (local) |
| Boss 15 | Dark Cinematic | solarflex | https://pixabay.com/music/orchestral-dark-cinematic-558265/ | `assets/audio/music/bosses/boss_15.mp3` | INTEGRATED (local) |
| Boss 16 | Battle Boss Fight Game Music | alex-morgan | https://pixabay.com/music/orchestral-battle-boss-fight-game-music-583276/ | `assets/audio/music/bosses/boss_16.mp3` | INTEGRATED (local) |
| Boss 17 | Epic Dark Cinematic Choir Music | desifreemusic | https://pixabay.com/music/choir-epic-dark-cinematic-choir-music-for-trailers-and-dramatic-scenes-428827/ | `assets/audio/music/bosses/boss_17.mp3` | INTEGRATED (local) |
| Boss 18 | Epic Enemy | bearstockmusic | https://pixabay.com/music/orchestral-epic-enemy-578175/ | `assets/audio/music/bosses/boss_18.mp3` | INTEGRATED (local) |
| Boss 19 | Return of The Gods | joelfazhari | https://pixabay.com/music/epic-classical-return-of-the-gods-dark-epic-free-soundtrack-2471/ | `assets/audio/music/bosses/boss_19.mp3` | INTEGRATED (local) |
| Boss 20 | Final Battle II | nyxaurora | https://pixabay.com/music/main-title-final-battle-ii-epic-cinematic-battle-music-with-intense-orchestral-361155/ | `assets/audio/music/bosses/boss_20.mp3` | INTEGRATED (local) |

## Verificação por hash local -- 24-09-2026

A auditoria de 22-09-2026 (secção anterior) tinha cruzado as 38 faixas
pendentes por **nome/URL**, sem ver `incoming_music`. Esta sessão corre num
contentor cloud sem acesso a `C:\Projetos\koliani-sfx`; nas duas tentativas
anteriores (22-09 e 24-09) isso ficou registado como
`MAPPING NOT CONFIRMED por hash`, sobretudo para a Região 16/Bloodlust, cuja
única fonte era uma linha de tabela sem SHA-256 próprio.

O Paulo forneceu três anexos medidos no PC local:
`incoming_music_hashes.csv` (nome, bytes e SHA-256 de cada ficheiro em
`incoming_music`, gerado por `Get-FileHash`), `music_manifest.csv` e
`music_manifest.json` (mapa índice -> título/artista/URL/`target_basename`,
todos com `status: pending` nesse snapshot local -- desatualizado em relação
ao runtime, que já tem tudo integrado).

**Inventário do CSV** (só `.mp3`, ignorando `.mp3.import`): **44 ficheiros**,
**38 SHA-256 únicos**, **6 pares duplicados byte a byte** (mesmo ficheiro
descarregado duas vezes, sufixo ` (1)` no segundo): `23350895-gothic-horror-178468`,
`echoes_of_lumen-epic-cinematic-music-powerful-583433`,
`geoffharvey-the-rolling-mist-cinematic-background-410782`,
`grand_project-desert-travels-391123`, `leberch-dark-578736`,
`tideblue-garden-of-morning-dew-cinematic-ambient-instrumental-562308`.
44 - 6 = 38 conteúdos únicos, confirmando a contagem "38 faixas" da secção
anterior (que descrevia o **conteúdo**, não o número de ficheiros no disco
do Paulo). "40 MP3" nessa secção referia-se à medição `ffmpeg volumedetect`
sobre os 38 + Região 01 + Boss 01, já integrados antes desta verificação.

**Cruzamento por hash** (recalculado nesta sessão com `sha256sum` sobre os
assets do checkout, comparado byte a byte com o CSV): as **38 SHA-256
únicas do CSV correspondem, uma a uma, sem sobra e sem falta**, às 19 faixas
`assets/audio/music/regions/region_02.mp3`..`region_20.mp3` e às 19
`assets/audio/music/bosses/boss_02.mp3`..`boss_20.mp3` atualmente no
repositório -- nenhum SHA-256 do CSV ficou por explicar, nenhum destes 38
assets runtime ficou sem origem no CSV. R02-20 e Boss02-20 estão portanto
**CONFIRMED BY HASH (evidência do Paulo, cross-checada nesta sessão)**, já
não apenas por nome/URL. Os índices/artistas/títulos do `music_manifest.csv`
batem certo com o nome de cada ficheiro do CSV (ex.: índice 16 =
`Cânion Sangrento, Bloodlust, Nightcast` = ficheiro
`nightcast-bloodlust-176915.mp3`).

**Região 16 / Bloodlust -- confirmação explícita pedida:**
`nightcast-bloodlust-176915.mp3` no CSV do Paulo tem 8 064 940 bytes e
SHA-256 `81E42127822002EDA4BDBD2549968FA57B5CC125D69E924CEAC992AC9B62F030`.
`assets/audio/music/regions/region_16.mp3`, recalculado nesta sessão a
partir do checkout, tem **exatamente** 8 064 940 bytes e SHA-256
`81E42127822002EDA4BDBD2549968FA57B5CC125D69E924CEAC992AC9B62F030` -- match
completo, os 64 carateres batem certo. A Região 16 deixa de ser
`MAPPING NOT CONFIRMED` e passa a **CONFIRMED BY HASH**.

**Assets runtime SEM correspondência no CSV** (esperado, não é
inconsistência): `approved/menu_cinematic_fantasy_dark.mp3`,
`approved/menu_cinematic_fantasy_dark_no_intro.ogg`,
`approved/region_01_midnight_forest.mp3`,
`approved/boss_01_gothic_candlelight.mp3` -- vieram de outra pasta
(Downloads, aquisição de 22-09), não de `incoming_music`. `bg_menu.mp3` /
`bg_niveis.mp3` são as reservas antigas do Paulo (secção "Música de fundo"
do `CREDITS.md`), nunca fizeram parte deste lote.

**Duplicado byte a byte confirmado no runtime:** `bg_boss.mp3` ==
`assets/audio/music/bosses/boss_20.mp3` (mesmo SHA-256
`743732EE...E1E7C603CB0E94F73`, 3 883 008 bytes) -- o `bg_boss.mp3` é a
reserva legada, `boss_20.mp3` é o asset ativo; `nyxaurora-final-battle-ii...mp3`
no CSV é a única cópia de origem para os dois.

**Estado final:** 44 ficheiros locais / 38 conteúdos únicos / 6 duplicados
locais confirmados; 38/38 conteúdos únicos ligados por hash a Região 02-20 +
Boss 02-20; Região 16 confirmada por hash nos dois lados; nenhum
ficheiro do CSV ficou por explicar; nenhum asset runtime dessas 38 faixas
ficou sem origem. Nada foi copiado, movido, editado (além desta
documentação), comitado ou apagado como parte desta verificação --
`incoming_music` e os 6 duplicados locais permanecem intactos no PC do
Paulo.
