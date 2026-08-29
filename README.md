# Koliani

Platformer de ação para telemóvel. **Koliani**, uma menina de 10 anos,
atravessa mundos fantasmagóricos para libertar a mãe do demónio
**Zeriko** -- passando por vários demónios e portas para outros reinos em
busca de pistas, até ao nível final.

Inspiração de "feel" e combate: *Dead Cells* (mobile). **Não** é roguelite
-- é um platformer **por níveis com história**, progresso guardado e
habilidades permanentes. Ver [`docs/historia.md`](docs/historia.md) e
[`docs/design.md`](docs/design.md).

## Stack

- **Godot 4** (GDScript). Renderer *mobile*, orientação *landscape*.
- Alvo principal: **APK Android**. Export **Web** mantido sempre a
  funcionar (verificação visual + partilha rápida). iOS fica para depois.
- Sem servidor: save local em `user://progresso.json` (JSON).
- Testes headless próprios (sem GUT) em `tests/run_tests.gd`.
- CI: GitHub Actions com `barichello/godot-ci` -> testes + build Web + APK
  como artifacts.

## Comandos

Precisa do editor do **Godot 4.x** instalado (`godot` no PATH).

```
godot -e .                                              # abrir o projeto no editor
godot --headless --script res://tests/run_tests.gd      # correr os testes (sai != 0 se falhar)
godot --headless --export-release "Web" build/web/index.html    # build Web
godot --headless --export-debug   "Android" build/android/koliani.apk  # build APK (precisa de SDK/keystore)
```

Ver o build Web no browser preview:

```
python -m http.server 8060 --directory build/web
```

(há um `.claude/launch.json` com esta config, nome `koliani-web`.)

## Estrutura

```
project.godot          -- config + input map + autoloads (EstadoJogo, Textos, Opcoes, Som, Musica, Transicao) + camadas
export_presets.cfg     -- presets "Web" e "Android"; include_filter = assets/i18n/*.json (o .json nao e "importado")
icon.svg               -- icone placeholder
assets/i18n/*.json     -- traducoes por idioma: en (base), pt, es, fr, de, zh
tools/gerar_audio.py   -- gera game_over/boss/assombracao/demonio_ataque .wav (sintese pura, sem numpy)

scripts/
  movimento.gd         -- LOGICA PURA do movimento (coyote, jump buffer, corte de salto, salto duplo); testavel
  koliani.gd           -- CharacterBody2D: liga movimento.gd + dash + ataque + dano + morte + salto duplo
  demonio_base.gd      -- inimigo base (patrulha + dano por contacto); classe-pai dos demonios
  chefe_base.gd        -- base dos chefes (herda DemonioBase): sinal "derrotado", telegrafo, contacto forte
  chefe_floresta.gd    -- chefe M1 -- Raiz-que-Anda: investida horizontal
  chefe_carcereiro.gd  -- chefe M2 -- Carcereiro: salto + onda de choque rasteira
  chefe_vento.gd       -- chefe M3 -- Uivo: voa, paira, mira e mergulha
  zeriko.gd            -- chefe M4 -- Zeriko: teleporta e dispara projeteis; 2.a fase < 50% vida
  relogio_hardcore.gd  -- modo hardcore: conta o tempo do mundo; a zero -> game_over.gd
  game_over.gd         -- cartao "GAME OVER" do hardcore; recomeca a campanha do mundo 1
  projetil_zeriko.gd   -- bola de energia do Zeriko (Area2D em linha reta)
  parede_fragil.gd     -- StaticBody2D: parte-se a golpe se a Koliani tiver "partir_paredes"
  nivel_com_chefe.gd   -- no raiz de M1-M3: sela a porta ate o no "Chefe" cair
  nivel_castelo.gd     -- no raiz de M4: sem porta -- ao "derrotado" do Zeriko arranca a cena final
  cena_final.gd        -- cena narrativa (libertacao da Aurora); no fim volta ao menu inicial
  fim_campanha.gd      -- (legado) cartao de fim usado pela porta quando nao ha proximo nivel; volta ao menu
  atmosfera.gd         -- montagem de ambiente reutilizavel (CanvasModulate + parallax + vinheta + luzes), cores por @export
  coletavel.gd         -- Area2D: apanhar => regista pista / desbloqueia habilidade; nao reaparece
  porta.gd             -- Area2D: avanca para o mundo seguinte / termina a campanha
  checkpoint.gd        -- Area2D: guarda posicao de reaparecimento
  estado_jogo.gd       -- autoload EstadoJogo: vidas, nivel, checkpoint, habilidades, pistas, hardcore, save
  textos.gd            -- autoload Textos: i18n por JSON (assets/i18n/<loc>.json); Textos.t("chave"); EN por omissao
  opcoes.gd            -- autoload Opcoes: volume musica/efeitos (buses "Music"/"SFX") + idioma; user://opcoes.json
  som.gd               -- autoload Som: pool de vozes (bus "SFX"); toca(nome) SFX (assets/audio/*.wav sintetizados)
  musica.gd            -- autoload Musica: cama por bioma + boss.wav no M4 + assombracao.wav por baixo (bus "Music")
  transicao.gd         -- autoload Transicao: fade a preto entre cenas (morte/reaparecer)
  diario_pistas.gd     -- DADOS PUROS: chaves de traducao das pistas por id (para o diario + testes)
  opcoes_menu.gd       -- ecra de Opcoes (sobreposto ao menu): cursores de som + seletor de idioma
  diario.gd            -- ecra de diario: I/Tab, pausa o jogo, lista EstadoJogo.pistas
  pausa.gd             -- menu de pausa: P/botao; pausa a arvore; continuar/recomecar/sair
  tremor.gd            -- LOGICA PURA do screen shake (amplitude decai a zero); testavel
  camera_tremor.gd     -- Camera2D da Koliani: aplica o Tremor ao offset (zoom 1.4)
  atmosfera.gd         -- pinta o ambiente (modulate/parallax/luzes) + poeira segue a camara
  plataforma.gd        -- @tool: plataforma reutilizavel (colisao + shader) por "tamanho"
  controlos_toque.gd   -- HUD: vida sempre visivel; botoes de toque so em ecra tactil
  menu_inicial.gd      -- MENU INICIAL (main_scene): NEW GAME / LOAD GAME / HARDCORE MODE / OPTIONS / Quit; `-- --jogar` salta-o
  main.gd              -- cena de jogo: carrega o nivel atual + HUD + diario + pausa (+ relogio no hardcore); debug F1-F9

scenes/
  Main.tscn                        -- main_scene (ver project.godot)
  levels/Floresta_Putrefata.tscn   -- MUNDO 1: verde-podre, fosso c/ salto duplo, da salto_duplo
  levels/Prisao_dos_Condenados.tscn-- MUNDO 2: azul-frio, subida longa, da dash_aereo
  levels/Torres_Esquecidas.tscn    -- MUNDO 3: roxo, saltos sobre o vazio, da partir_paredes (+ ParedeFragil)
  levels/Castelo_de_Zeriko.tscn    -- MUNDO 4: magenta, arena do Zeriko, sem porta -> cena final da Aurora
  levels/Level_Test.tscn           -- sala de treino (fora da campanha)
  actors/Koliani.tscn              -- placeholder ColorRect (silhueta key art) + lamina c/ PointLight2D + particulas
  actors/DemonioBase.tscn          -- placeholder ColorRect + olho c/ PointLight2D + area de contacto
  actors/ChefeFloresta.tscn / ChefeCarcereiro.tscn / ChefeVento.tscn / Zeriko.tscn -- chefes M1..M4
  actors/ProjetilZeriko.tscn       -- projetil do chefe final
  actors/Coletavel.tscn            -- gema magenta c/ PointLight2D (pista / habilidade)
  actors/ParedeFragil.tscn         -- parede rachada que se parte a golpe (c/ habilidade)
  actors/Plataforma.tscn           -- plataforma "chunky" (shader de pedra/tijolo procedural)
  fx/Atmosfera.tscn                -- ambiente: parallax 4 camadas (silhuetas Polygon2D) + feixes de luz + poeira + vinheta + grade de ecra
assets/shaders/                    -- personagem (rim+flash), plataforma (pedra), grade (contraste/sat/bloom)
  ui/HUD.tscn                      -- barra de vida, vidas, TouchScreenButtons (+ rolar, diario, pausa)
  ui/Diario.tscn                   -- painel do diario de pistas (instanciado pelo main.gd)
  ui/Pausa.tscn                    -- menu de pausa (instanciado pelo main.gd)
  ui/MenuInicial.tscn              -- ecra inicial / titulo (main_scene do projeto)
  ui/Opcoes.tscn                   -- ecra de Opcoes (som + idioma), sobreposto ao menu inicial

tests/run_tests.gd     -- corredor headless proprio (movimento + estado_jogo)
docs/                  -- historia.md, design.md (bibliografia viva)
assets/sprites/*.svg   -- arte SVG original (Koliani, demonios, 4 chefes, gema, porta, impacto)
assets/shaders/*.gdshader -- personagem, plataforma, grade
assets/audio/*.wav     -- SFX + musica SINTETIZADOS (tools/gerar_audio.py; sem licenca de terceiros)
assets/                -- branding/, fonts/, tiles/ -- SO CC0/gratis (ou nosso)
.github/workflows/ci.yml
.claude/agents/gaming.md  -- o agente responsavel por este jogo
```

> **Personagens já usam sprites SVG** (`assets/sprites/`, desenhados por
> nós). Plataformas e parallax ainda são `ColorRect`. Nada pago sem
> perguntar ao Paulo.

## CI / builds

`.github/workflows/ci.yml` corre em cada push:

1. **testes** -- `godot --headless --script res://tests/run_tests.gd`
2. **web** -- export "Web" -> artifact `koliani-web`
3. **android** -- gera keystore de debug + export "Android" -> artifact
   `koliani-android`
4. **windows** -- export "Windows Desktop" (release) -> artifact
   `koliani-windows` **e** publica `Koliani-windows.zip` no Release
   **`win-latest`** (tag rolante, marcado como *latest*).

Assim há sempre um APK para instalar no telemóvel sem o PC ligado (mesma
ideia do deploy do jogo do jardim). A **primeira execução** pode precisar
de afinação (versão exata da imagem `godot-ci`, nome do preset, Android
SDK) -- ajustar pelo log do Actions.

### Playtester (build Windows para um amigo testar)

O amigo não precisa de conta no GitHub (repo público). Link fixo, sempre
com a versão mais recente:

- Página: <https://github.com/paulogomesextp/koliani/releases/tag/win-latest>
- Download directo:
  <https://github.com/paulogomesextp/koliani/releases/download/win-latest/Koliani-windows.zip>

**Ciclo:** `git push` para `master` -> o CI corre os testes, exporta o
`.exe` e actualiza o `win-latest`. O amigo volta ao mesmo link, descarrega,
extrai e corre `Koliani.exe` (SmartScreen: *Mais informações* -> *Executar
mesmo assim*; é um `.exe` não assinado).

**Publicar num clique:** `publicar.bat` (atalho **"Publicar Koliani"** no
Ambiente de Trabalho, via `criar-atalho.ps1`) sobe o patch de
`config/version`, faz `commit` de tudo e `push`. É o que dispara o ciclo
acima quando as alterações foram feitas no editor. Sessões do agente
fazem o `push` sozinhas.

**Versão:** o número no canto do menu (`config/version` em `project.godot`,
lido em `scripts/menu_inicial.gd`) identifica a build -- o `publicar.bat`
sobe-o automaticamente para o feedback ser rastreável.

**Save do amigo:** `%APPDATA%\Godot\app_userdata\Koliani\progresso.json`
(apagar = recomeçar; o F9 de dev não existe na build release).

## Setup ainda por fazer (fora do repositório)

- ~~Instalar o **Godot 4.x**~~ -- feito: Godot **4.7.2** em
  `C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe`.
- ~~Guardar a **key art**~~ -- feito: `assets/branding/key_art.png`.
- **Ligar o remote:** `git remote add origin <URL do repo>` (corrido pelo
  Paulo -- o agente não mexe em git config).
- **Instalar os modelos de export** (1x, ~700 MB): no editor,
  *Editor > Gerir Modelos de Exportação > Transferir e Instalar*. Precisos
  para o build **Web** local (verificação visual) e para o APK local. O CI
  já traz os dele na imagem `barichello/godot-ci`.
- *Opcional, só para APK local:* JDK 17 + Android SDK + keystore de debug.
  Sem isto, o APK sai só do CI.

## Estado da validação (2026-08-30, Godot 4.7.2 headless)

- `--import` sem erros nem avisos; classes globais todas registadas.
- `godot --headless --script res://tests/run_tests.gd` -- **15 testes, todos
  a passar** (movimento + salto duplo + rolar + tremor + estado + diário).
- **As 4 cenas de nível + `Main.tscn` correm headless (200-500 frames)
  sem erros nem avisos.**
- Campanha **completa (4 mundos)** em `EstadoJogo.NIVEIS`. Progressão:
  salto_duplo (M1) -> dash_aereo (M2) -> partir_paredes (M3) -> luta final
  com o Zeriko + cena da Aurora (M4). Chefes distintos nos 4 mundos.
  Diário de pistas funcional (7 pistas escritas).
- **Idioma / i18n**: o jogo é **em inglês por omissão**; todo o texto
  visível vem de `Textos.t("chave")` (autoload `textos.gd`), com os textos
  em `assets/i18n/<loc>.json`. Idiomas: **en** (base), **pt, es, fr, de,
  zh**. O `en.json` é a referência; os testes garantem que os outros têm
  exatamente as mesmas chaves. Trocar de idioma no jogo: **OPTIONS >
  LANGUAGE** -> `Textos` emite `idioma_mudou` e cada ecrã re-traduz na
  hora. **zh (chinês) aparece como quadrados** -- falta uma fonte CJK (ver
  "Por fazer").
- **Menu de Opções** (`scripts/opcoes_menu.gd` + `scenes/ui/Opcoes.tscn`,
  sobreposto ao menu inicial). **SOUND**: cursores de volume de *Music* e
  *Effects* (buses de áudio `Music`/`SFX` criados por `opcoes.gd`).
  **LANGUAGE**: um botão por idioma. Guardado em `user://opcoes.json`
  (separado do progresso).
- **Menu inicial** (`scripts/menu_inicial.gd` + `scenes/ui/MenuInicial.tscn`,
  a `main_scene`): **NEW GAME** (campanha nova, apaga o save com
  confirmação), **LOAD GAME** (retoma o save; só aparece se houver
  progresso), **HARDCORE MODE** (campanha nova com tempo limite por mundo),
  **OPTIONS** e *Quit*. `-- --jogar` / `-- --nivel=N` / `-- --hardcore`
  saltam o menu.
- **Modo hardcore**: `EstadoJogo.hardcore` (gravado no save). Cada mundo
  tem um tempo (`EstadoJogo.TEMPO_HARDCORE`, ponto de partida) mostrado por
  `relogio_hardcore.gd` (relógio no topo; pára em pausa/diário). O tempo
  que falta vive em `EstadoJogo.hardcore_tempo_restante`, por isso
  **continua a contar através das mortes** -- só reinicia ao mudar de
  mundo ou recomeçar. Fim do run (tempo a zero **ou** 3 vidas gastas) ->
  `game_over.gd` com a voz "GAME OVER" e a campanha recomeça do mundo 1,
  ainda em hardcore. Dev: `-- --hc-tempo=N` força N segundos por mundo.
- **Fundo do menu** (`scenes/ui/MenuInicial.tscn`): arte HD 16:9
  (`assets/branding/menu_bg.png`, dada pelo Paulo -- Koliani na ruína,
  Zeriko + lanterna-jaula, castelo, lua), com scrim leve + vinheta radial
  e deriva lenta ("Ken Burns"). Substituir o ficheiro por outro 16:9 e
  reimportar chega para trocar.
- **Áudio** (`tools/gerar_audio.py`, síntese pura): `menu.wav` (tema do
  menu), `boss.wav` (música de chefe -- toca **ao aproximar-se do chefe em
  qualquer mundo**, via `chefe_base.gd` + `Musica.boss()`; no M4 já vem do
  arranque), `assombracao.wav` (casa assombrada por baixo da música),
  `game_over.wav` (voz de arcada), `demonio_ataque.wav` (rosnar ao
  acertar), `conquista.wav` (chefe derrotado -- som de conquista, distinto
  de matar um inimigo), `salto`/`salto_duplo` **refeitos** mais suaves.
  Música global mais alta (cama -12 dB, chefe -6 dB); **efeitos por baixo
  da música** (`Opcoes.vol_efeitos` = 0.45 por omissão).
- **Fim da campanha** volta ao **menu inicial** (o save fica como está --
  o jogador escolhe NEW GAME / LOAD GAME / HARDCORE MODE).
- **Menu de pausa** (`scripts/pausa.gd` + `scenes/ui/Pausa.tscn`): P ou
  botão do HUD; pausa a árvore; continuar / recomeçar no checkpoint / menu
  principal / sair. Verificado no build Web.
- **Playtest do Paulo em curso.** Corrigido já: chefe atirava-se para um
  fosso e ficava o nível bloqueado (rede de segurança em `chefe_base.gd`
  + inimigos viram na beira via `ha_chao_a_frente`); atalhos F1-F9 agora
  mostram um toast (F5 "parecia não fazer nada"). Falta afinar
  distâncias/ritmo/dano com mais notas de jogo.
- **Builds locais FUNCIONAM** (modelos de export instalados):
  `--export-release "Web" build/web/index.html` e
  `--export-release "Windows Desktop" build/windows/Koliani.exe`.
  Atalho no Ambiente de Trabalho: **"Koliani (testar)"** (ver `docs/testar.md`).

## Como testar / instalar

Ver **`docs/testar.md`**: como correr o jogo, controlos, atalhos de debug
(F1-F9), instalar os modelos de export, e ligar o remote/CI.

## Decisões de direção (Paulo)

- Chefes distintos por mundo · mãe = **Aurora** · final = **luta + cena
  narrativa** · música = **B** (drone + melodia esparsa).
- **Estilo de arte:** manter **vetorial** (SVG rim-lit). Pixel-art fica
  como hipótese futura (swap dos sprites).
- **Brilho (bloom):** **suave** -- `Atmosfera.tscn > Grade`
  `shader_parameter/bloom = 0.14`.
- **Animação com frames:** adiada -- só **depois** de afinar a
  jogabilidade. Por agora é procedural (squash/stretch, lean, wind-up,
  rastro, frame de impacto).
- **Fundo temático por mundo** (árvores / grades / torres / arcos):
  aprovado em princípio, mas **polir depois** do gameplay; hoje são
  silhuetas genéricas recortadas.

## Por fazer (à espera do Paulo)

1. **Playtest + afinação** -- testar (`docs/testar.md`) e passar notas de
   feel/dificuldade (os níveis foram montados sem jogar). Inclui afinar
   `EstadoJogo.TEMPO_HARDCORE` (tempos do modo hardcore) e os volumes/mix
   do áudio novo (`game_over`, `boss`, `assombracao`).
2. **Fonte CJK** -- o idioma **zh (chinês)** já está traduzido mas a fonte
   por omissão do Godot não tem glifos CJK (aparecem quadrados). Falta
   juntar uma fonte livre (ex.: Noto Sans SC, OFL) e pô-la no tema -- ~8 MB,
   por isso **a decidir com o Paulo** (tamanho / licença).
3. **Revisão nativa das traduções** -- es/fr/de/zh foram feitas por nós
   (boa-fé, sem revisão nativa).
4. **Remote / CI** -- ligar o `git remote` (é trabalho do Paulo; o build
   Web local já funciona).
5. Frames de animação, fundos temáticos, tiles/decoração -- quando o Paulo
   der luz verde.

## Regras

- Código, comentários e logs em **português**.
- **Texto do jogo**: nada de strings à mão nos ecrãs -- sempre
  `Textos.t("chave")` + entrada nos 6 `assets/i18n/*.json` (o `en.json`
  manda). O jogo vê-se **em inglês** por omissão.
- Assets só **CC0/grátis**. Áudio: sintetizado por nós (`tools/gerar_audio.py`).
- **Nunca** mexer em `git config` -- pedir ao Paulo.
- Mobile-first: landscape, toque, 60fps. Testar no telemóvel do Paulo.
- Manter o export Web a funcionar.
