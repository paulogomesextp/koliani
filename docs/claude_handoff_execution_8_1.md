# Handoff Claude — após Execution 8.1 (Windows Performance Gate)

Sucessor de [`claude_handoff_execution_8.md`](claude_handoff_execution_8.md),
que **continua válido** para tudo o que é runtime, canon e produção — a 8.1
não alterou nada disso. Começar por
[`retomar_aqui.md`](retomar_aqui.md) e
[`execution_8_1_windows_performance_gate.md`](execution_8_1_windows_performance_gate.md).

## O que a 8.1 fez

Só diagnóstico do Windows Performance Gate. **Zero alterações a código,
cenas, assets ou definições do jogo.** O que entrou no repo:

- `tools/perf_gate.gd` / `.tscn` — sonda de desempenho reutilizável;
- `docs/execution_8_1_windows_performance_gate.md` — relatório;
- entradas em `retomar_aqui.md` e `PRIORIDADES.md`.

## O que ficou provado

O jogo **não** tem problema de custo: 1388 FPS / 0,72 ms por frame no L1 a
1080p com VSync desligado. Sem fugas (871 nós fixos em 47 recargas, 0
órfãos). Sem logging por frame. Debug de release está mesmo desligado, não só
escondido. Partículas, luzes, overdraw, IA e chefe: todos negativos.

O que existe é **cadência**: física a 60 Hz num painel de 165 Hz sem
interpolação → 67,2 % dos frames desenhados são duplicados; mais ~150 ms de
congelamento em cada carregamento de cena.

## Decisão que está à espera do Game Master

Ligar `physics/common/physics_interpolation`. Não altera constantes de
movimento, salto, dash, câmara nem combate — a física continua a 60 Hz, só a
transformação desenhada é interpolada. Não foi aplicada porque:

- muda o comportamento de todos os `Node2D`;
- exige `reset_physics_interpolation()` em cada teletransporte (respawn,
  checkpoints, arenas de chefe);
- nós movidos no `_process` precisam de exceção — pelo menos
  `atmosfera.gd:268` (`_poeira`);
- **a sonda não a consegue validar**: `global_position` devolve a
  transformação da física, não a interpolada. A validação tem de ser visual.

Rejeitada por medição: limitar a 60 FPS. Melhora a métrica (67 % → 11 % de
duplicados) mas não a cadência percebida — o mundo continua a avançar 60×/s
num painel de 165 Hz. Só poupa GPU.

## Armadilhas de método (custaram tempo, não repetir)

- **Morrer recarrega a cena atual** (`koliani.gd:1989`). Qualquer sonda que
  *seja* a cena reinicia-se a cada morte, em ciclo. A `perf_gate` guarda o
  estado em metas do `SceneTree`, que sobrevive ao reload.
- **`--headless` não renderiza** neste build. Medir com janela real em
  `--screen 1`.
- **A suite corre por cena:** `--headless --path . res://tests/run_tests.tscn`.
  O `--script res://tests/run_tests.gd` que está no `CLAUDE.md` **não
  funciona** (os autoloads não existem em `--script` e a compilação falha).
  A suite precisa da pasta `work/`, que não vem do git — sem ela dá 25 falsos
  negativos de save.
- O binário sem consola não entrega stdout ao pipe; ler
  `user://logs/godot.log` ou o JSON em `user://perf/`.
- O EXE exportado aceita flags de motor: `--print-fps`, `-f`, `--screen`,
  `--resolution`, e `-- --jogar` salta o menu. É assim que se mede o binário
  real sem lhe tocar (`tools/**` está excluída do export).

## Estado de entrega

`build/windows/Koliani.exe` e `build/web/index.html` continuam a ser os da
Execution 8 — não foram reexportados porque não houve alterações de source.

## Próximo gate

Inalterado: decidir a interpolação → **PRODUCTION ART GATE** → revisão humana
da vertical slice. Não iniciar a Região II.
