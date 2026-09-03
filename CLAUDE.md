# CLAUDE.md — Koliani

Platformer de ação para telemóvel (Godot 4.7.2, GDScript). A **Koliani**
atravessa 6 regiões para libertar a mãe (**Aurora**) do demónio **Zeriko**.
Não é roguelite — é por níveis, com história e progresso guardado.
Contexto completo: [`README.md`](README.md), [`docs/`](docs/) (`design.md`,
`historia.md`, `niveis.md`, `testar.md`). **Ponto de retoma da última
sessão: [`docs/retomar_aqui.md`](docs/retomar_aqui.md)** — ler primeiro.

## Correr o Godot

Não há `godot` no PATH. Binário:
`C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe` (para output no
terminal usar a variante `..._console.exe`).

```bash
# reimportar recursos (SEMPRE depois de acrescentar/mudar assets)
"/c/Users/paulo/Desktop/Godot_v4.7.2-stable_win64_console.exe" --headless --import

# suite de testes headless (sai != 0 se falhar)
"/c/Users/paulo/Desktop/Godot_v4.7.2-stable_win64_console.exe" --headless --script res://tests/run_tests.gd

# smoke-test de uma cena (corre N frames e sai)
"...Godot..._console.exe" --headless --quit-after 180 res://scenes/levels/Floresta_Putrefata.tscn
```

Verificação visual: `tools/shot_plataforma.gd` (`--script ... -- <cena>
<saída.png> [segundos] [koliani_x]`) grava um PNG do ecrã.

## Fluxo de trabalho

- **Autonomia total no repo**: criar/editar cenas e scripts, correr o Godot
  headless, `commit` **e `push`** em `master` sem pedir. Commits pequenos e
  frequentes.
- **NUNCA** mexer em `git config` nem no `git remote` — isso é do Paulo.
- Mensagens de commit terminam com:
  `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`
- Remote: `github.com/paulogomesextp/koliani` (público).

## Colaboração entre sessões

Projeto trabalhado por duas pessoas (Paulo e Luís/Jensath), cada uma com a
sua sessão de agente. Na **primeira interação de cada dia** (data diferente
da última vez que se mexeu no repo nesta máquina), antes de avançar com o
pedido: correr `git fetch origin master` e `git log origin/master
--since="1 day ago" --pretty=format:"%h | %ad | %an | %s" --date=format:"%Y-%m-%d
%H:%M"` para ver se o outro colaborador fez commits recentes. Se houver,
resumir ao utilizador (o quê, não só a lista em bruto) antes de continuar —
evita trabalho duplicado ou conflito com o que o outro já mudou.

## Regras do projeto

- **Código, comentários e logs em português.**
- **Texto do jogo**: nunca strings à mão nos ecrãs — sempre
  `Textos.t("chave")` + entrada nos 6 `assets/i18n/*.json`. O `en.json` é a
  fonte de verdade; os testes exigem as mesmas chaves em todos. O jogo
  corre **em inglês** por omissão.
- **Assets só CC0/grátis** — **nada pago sem perguntar ao Paulo**. Packs
  que o Paulo larga em `assets/sprites/incoming/` (`.gdignore`); copiar o
  que se usa para `assets/sprites/pixel/` e creditar em
  `assets/sprites/pixel/CREDITS.md`.
- Mobile-first: landscape, toque, 60fps. Manter o export Web a funcionar.

## Arte

Terreno, decoração e fundos são **gerados por ferramentas** — mexer nos
tools e regerar, nunca nos PNGs nem no nó `Atmosfera` dos `.tscn` à mão:
`tools/gerar_terreno.py` (material por região), `tools/gerar_deco.py`
(props), `tools/gerar_fundos.py` (packs de parallax),
`tools/afinar_atmosfera.py` (o ar de cada um dos 30 níveis).
`tools/folha_de_contacto.gd` mostra os 30 níveis de relance (precisa de
janela: `--screen 1`).

Alvo visual: **o mais próximo possível de Dead Cells**, com a temática de
`assets/branding/key_art.png` (gótico, luar, brilho magenta/roxo). O jogo
está a **migrar para pixel-art** via packs CC0 (Pixel Adventure 1, Kings
and Pigs, Kenney). `default_texture_filter = Nearest`.

- `tools/gerar_sprites.gd` — gera os sprites pixel-art feitos à mão
  (Koliani, Ghorak, demónio). `godot --headless --script
  res://tools/gerar_sprites.gd`; `PREVIEW=1` grava `_preview_*` x8.
- `tools/gerar_audio.py` — sintetiza os `.wav` (sem numpy, sem licenças).
- Sprites viram para a **direita** por convenção (o jogo faz
  `scale.x = +olha_para`).

## Autoloads

`EstadoJogo` (vidas/nível/checkpoint/habilidades/pistas/hardcore/save),
`Textos` (i18n), `Opcoes` (volumes + idioma), `Som` (SFX pool, bus "SFX"),
`Musica` (camas por bioma, bus "Music"), `Transicao` (fade entre cenas),
`Dialogo` (`await Dialogo.correr(falas)` -> balão de fala moderno; falas
`{quem,texto}` por chave i18n; usado pelos chefes-história via
`ChefeBase.falas_intro` / `falas_fim`).

## Estrutura (resumo — detalhe no README)

```
scenes/levels/   4 mundos jogáveis + Level_Test
scenes/actors/   Koliani, DemonioBase, chefes, Plataforma, Coletavel,
                 Porta, armadilhas (Espinhos/Serra/Fogo), RaizPerigo...
scenes/ui/       MenuInicial (main_scene), HUD, Pausa, Diario, Opcoes,
                 MapaMundo + SeletorNiveis (carrossel de niveis c/ nome
                 do chefe; usado no modo normal e na DevBarra)
scenes/fx/       Atmosfera.tscn (modulate + parallax + luzes + vinheta;
                 recolor por `bioma`/@export; raiz no grupo "atmosfera")
scripts/         1 script por ator; movimento.gd/tremor.gd = lógica pura
assets/i18n/     en (base), pt, es, fr, de, zh
tests/run_tests.gd   corredor headless próprio (sem GUT)
```

## Playtester (build Windows para um amigo)

Ciclo: subir o patch de `config/version` em `project.godot` → `commit`
"playtest vX.Y.Z" → `push` para `master`. O CI (`.github/workflows/ci.yml`)
corre os testes, exporta o `.exe` e actualiza o Release **`win-latest`**
(link fixo). O amigo não precisa de conta no GitHub.
