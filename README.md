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
  chefe_floresta.gd    -- chefe do mundo 1: FSM patrulha/telegrafo/investida/recupera; sinal "derrotado"
  nivel_floresta.gd    -- script do no raiz do mundo 1: sela a porta ate o chefe cair
  coletavel.gd         -- Area2D: apanhar => regista pista / desbloqueia habilidade; nao reaparece
  porta.gd             -- Area2D: avanca para o mundo seguinte / termina a campanha
  checkpoint.gd        -- Area2D: guarda posicao de reaparecimento
  estado_jogo.gd       -- autoload EstadoJogo: vidas, nivel, checkpoint, habilidades, pistas, save
  diario_pistas.gd     -- DADOS PUROS: textos das pistas por id (para o diario + testes)
  diario.gd            -- ecra de diario: I/Tab, pausa o jogo, lista EstadoJogo.pistas
  tremor.gd            -- LOGICA PURA do screen shake (amplitude decai a zero); testavel
  camera_tremor.gd     -- Camera2D da Koliani: aplica o Tremor ao offset
  controlos_toque.gd   -- HUD de toque (esconde-se com teclado)
  main.gd              -- cena de arranque: carrega o nivel atual + HUD + diario + cartao de fim

scenes/
  Main.tscn                        -- main_scene (ver project.godot)
  levels/Floresta_Putrefata.tscn   -- MUNDO 1: parallax + luz tipo Dead Cells, fosso c/ salto duplo, coletaveis, demonios, chefe, checkpoint, porta selada
  levels/Level_Test.tscn           -- sala de treino (fora da campanha)
  actors/Koliani.tscn              -- placeholder ColorRect (silhueta key art) + lamina c/ PointLight2D + particulas
  actors/DemonioBase.tscn          -- placeholder ColorRect + olho c/ PointLight2D + area de contacto
  actors/ChefeFloresta.tscn        -- chefe do mundo 1 (massa roxa, 2 olhos, luz)
  actors/Coletavel.tscn            -- gema magenta c/ PointLight2D (pista / habilidade)
  ui/HUD.tscn                      -- barra de vida, vidas, TouchScreenButtons (+ rolar, diario)
  ui/Diario.tscn                   -- painel do diario de pistas (instanciado pelo main.gd)

tests/run_tests.gd     -- corredor headless proprio (movimento + estado_jogo)
docs/                  -- historia.md, design.md (bibliografia viva)
assets/                -- branding/, sprites/, audio/, fonts/, tiles/ -- SO CC0/gratis
.github/workflows/ci.yml
.claude/agents/gaming.md  -- o agente responsavel por este jogo
```

> **Visuais são `ColorRect` placeholder.** Substituir por sprites CC0
> (Kenney, itch.io CC0, OpenGameArt). Nada pago sem perguntar ao Paulo.

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

## Estado da validação (2026-08-29, Godot 4.7.2 headless)

- `--import` -- OK, classes globais registadas (`Coletavel`, `Koliani`,
  `Movimento`), assets importados.
- `godot --headless --script res://tests/run_tests.gd` -- **14 testes, todos
  a passar** (movimento + salto duplo + rolar + tremor + estado + diário).
- `Main.tscn` (mundo 1 + chefe + HUD + diário) corre 600 frames headless
  **sem erros nem avisos**.
- Build Web/APK local -- bloqueado só pela falta dos modelos de export
  (ver acima).

## Dúvidas para o Paulo (2026-08-29)

1. **Sprites CC0.** Posso avançar e integrar packs concretos (Kenney
   "Pixel Platformer" / "Pixel Adventure" no itch.io, ambos CC0) para
   Koliani, demónios e tiles da floresta? Ou preferes escolher tu os
   packs primeiro? Nada foi descarregado ainda.
2. **Level_Test fora da campanha.** Tirei-o de `EstadoJogo.NIVEIS`; a
   campanha começa já na Floresta Putrefata. Ok assim?
3. **Fim da campanha.** Com só o mundo 1, a porta final mostra um cartão
   de texto e pausa. Deixo assim até existir o mundo 2, certo?
4. **Ligar o remote / CI.** O `git remote` continua por ligar (regra:
   não mexo em git config). Sem isso o GitHub Actions não corre e não há
   APK do CI para o telemóvel.

## Regras

- Código, comentários e logs em **português**.
- Assets só **CC0/grátis**.
- **Nunca** mexer em `git config` -- pedir ao Paulo.
- Mobile-first: landscape, toque, 60fps. Testar no telemóvel do Paulo.
- Manter o export Web a funcionar.
