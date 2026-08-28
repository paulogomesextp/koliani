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
  movimento.gd         -- LOGICA PURA do movimento (coyote, jump buffer, corte de salto); testavel
  koliani.gd           -- CharacterBody2D: liga movimento.gd + dash + ataque + dano + morte
  demonio_base.gd      -- inimigo base (patrulha + dano por contacto); classe-pai dos demonios
  porta.gd             -- Area2D: avanca para o mundo seguinte / termina a campanha
  checkpoint.gd        -- Area2D: guarda posicao de reaparecimento
  estado_jogo.gd       -- autoload EstadoJogo: vidas, nivel, checkpoint, habilidades, pistas, save
  controlos_toque.gd   -- HUD de toque (esconde-se com teclado)
  main.gd              -- cena de arranque: carrega o nivel atual + HUD

scenes/
  Main.tscn                    -- main_scene (ver project.godot)
  levels/Level_Test.tscn       -- sala de teste: plataformas, 1 demonio, checkpoint, porta
  actors/Koliani.tscn          -- placeholder ColorRect + hitbox + camara
  actors/DemonioBase.tscn      -- placeholder ColorRect + area de contacto
  ui/HUD.tscn                  -- barra de vida, vidas, TouchScreenButtons

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

- Instalar o **Godot 4.x** (editor) no PC.
- Criar `github.com/paulogomesextp/koliani` e ligar o remote
  (`git remote add ...` -- corrido pelo Paulo; o agente não mexe em git
  config).
- Guardar a **key art** em `assets/branding/key_art.png`.
- *Opcional, só para APK local:* JDK 17 + Android SDK + templates de
  export do Godot + keystore de debug. Sem isto, o APK sai só do CI.

## Regras

- Código, comentários e logs em **português**.
- Assets só **CC0/grátis**.
- **Nunca** mexer em `git config` -- pedir ao Paulo.
- Mobile-first: landscape, toque, 60fps. Testar no telemóvel do Paulo.
- Manter o export Web a funcionar.
