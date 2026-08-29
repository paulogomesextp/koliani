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
project.godot          -- config + input map (pt) + autoload EstadoJogo + camadas de fisica
export_presets.cfg     -- presets "Web" e "Android" (re-gravar pelo editor se preciso)
icon.svg               -- icone placeholder

scripts/
  movimento.gd         -- LOGICA PURA do movimento (coyote, jump buffer, corte de salto, salto duplo); testavel
  koliani.gd           -- CharacterBody2D: liga movimento.gd + dash + ataque + dano + morte + salto duplo
  demonio_base.gd      -- inimigo base (patrulha + dano por contacto); classe-pai dos demonios
  chefe_base.gd        -- base dos chefes (herda DemonioBase): sinal "derrotado", telegrafo, contacto forte
  chefe_floresta.gd    -- chefe M1 -- Raiz-que-Anda: investida horizontal
  chefe_carcereiro.gd  -- chefe M2 -- Carcereiro: salto + onda de choque rasteira
  chefe_vento.gd       -- chefe M3 -- Uivo: voa, paira, mira e mergulha
  zeriko.gd            -- chefe M4 -- Zeriko: teleporta e dispara projeteis; 2.a fase < 50% vida
  projetil_zeriko.gd   -- bola de energia do Zeriko (Area2D em linha reta)
  parede_fragil.gd     -- StaticBody2D: parte-se a golpe se a Koliani tiver "partir_paredes"
  nivel_com_chefe.gd   -- no raiz de M1-M3: sela a porta ate o no "Chefe" cair
  nivel_castelo.gd     -- no raiz de M4: sem porta -- ao "derrotado" do Zeriko arranca a cena final
  cena_final.gd        -- cena narrativa (libertacao da Aurora); no fim recomeca a campanha
  fim_campanha.gd      -- (legado) cartao de fim usado pela porta quando nao ha proximo nivel
  atmosfera.gd         -- montagem de ambiente reutilizavel (CanvasModulate + parallax + vinheta + luzes), cores por @export
  coletavel.gd         -- Area2D: apanhar => regista pista / desbloqueia habilidade; nao reaparece
  porta.gd             -- Area2D: avanca para o mundo seguinte / termina a campanha
  checkpoint.gd        -- Area2D: guarda posicao de reaparecimento
  estado_jogo.gd       -- autoload EstadoJogo: vidas, nivel, checkpoint, habilidades, pistas, save
  som.gd               -- autoload Som: pool de vozes; toca(nome) SFX (assets/audio/*.wav sintetizados)
  musica.gd            -- autoload Musica: cama de ambiente em loop, pitch por bioma
  transicao.gd         -- autoload Transicao: fade a preto entre cenas (morte/reaparecer)
  diario_pistas.gd     -- DADOS PUROS: textos das pistas por id (para o diario + testes)
  diario.gd            -- ecra de diario: I/Tab, pausa o jogo, lista EstadoJogo.pistas
  pausa.gd             -- menu de pausa: P/botao; pausa a arvore; continuar/recomecar/sair
  tremor.gd            -- LOGICA PURA do screen shake (amplitude decai a zero); testavel
  camera_tremor.gd     -- Camera2D da Koliani: aplica o Tremor ao offset (zoom 1.4)
  atmosfera.gd         -- pinta o ambiente (modulate/parallax/luzes) + poeira segue a camara
  plataforma.gd        -- @tool: plataforma reutilizavel (colisao + shader) por "tamanho"
  controlos_toque.gd   -- HUD: vida sempre visivel; botoes de toque so em ecra tactil
  menu_inicial.gd      -- MENU INICIAL (main_scene): continuar / novo jogo / sair; `-- --jogar` salta-o
  main.gd              -- cena de jogo: carrega o nivel atual + HUD + diario + pausa; atalhos de debug (F1-F9)

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

tests/run_tests.gd     -- corredor headless proprio (movimento + estado_jogo)
docs/                  -- historia.md, design.md (bibliografia viva)
assets/sprites/*.svg   -- arte SVG original (Koliani, demonios, 4 chefes, gema, porta, impacto)
assets/shaders/*.gdshader -- personagem, plataforma, grade
assets/audio/*.wav     -- SFX + ambiente SINTETIZADOS (script no repo; sem licenca de terceiros)
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

Assim há sempre um APK para instalar no telemóvel sem o PC ligado (mesma
ideia do deploy do jogo do jardim). A **primeira execução** pode precisar
de afinação (versão exata da imagem `godot-ci`, nome do preset, Android
SDK) -- ajustar pelo log do Actions.

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
- **Menu inicial** (`scripts/menu_inicial.gd` + `scenes/ui/MenuInicial.tscn`,
  agora a `main_scene`): título + *Continuar* (só se houver progresso) /
  *Novo jogo* (pede confirmação se apagar um save) / *Sair*. `-- --jogar`
  salta o menu (mantém as capturas `--foto` a funcionar).
- **Menu de pausa** (`scripts/pausa.gd` + `scenes/ui/Pausa.tscn`): P ou
  botão do HUD; pausa a árvore; continuar / recomeçar no checkpoint / menu
  principal / sair. Verificado no build Web (abrir, fechar, recomeçar e
  voltar ao menu com fade).
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
   feel/dificuldade (os níveis foram montados sem jogar).
2. **Remote / CI** -- ligar o `git remote` (é trabalho do Paulo; o build
   Web local já funciona).
3. Frames de animação, fundos temáticos, tiles/decoração, mixagem de
   áudio -- quando o Paulo der luz verde.

## Regras

- Código, comentários e logs em **português**.
- Assets só **CC0/grátis**.
- **Nunca** mexer em `git config` -- pedir ao Paulo.
- Mobile-first: landscape, toque, 60fps. Testar no telemóvel do Paulo.
- Manter o export Web a funcionar.
