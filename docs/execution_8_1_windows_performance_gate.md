# Execution 8.1 — Windows Performance Gate

Estado: **PARTIAL PASS — DIAGNÓSTICO FECHADO / DECISÃO DO GAME MASTER
NECESSÁRIA**. Nenhuma alteração ao runtime do jogo foi feita.

Data: 10 de setembro de 2026. Baseline: `b2fd8a0a92787f3a0880bb6f6572c29d141d38cd`.

## Resumo em duas linhas

O jogo **não** tem um problema de custo: com o VSync desligado o Nível 1
corre a **1388 FPS (0,72 ms/frame)** a 1920×1080, ou seja ~23× de folga
sobre os 60 FPS. O que o Game Master sente como "framedrop" é **cadência de
imagem**, não falta de desempenho — e a causa principal está provada.

## Método

Sonda nova: [`tools/perf_gate.gd`](../tools/perf_gate.gd) +
`perf_gate.tscn`. Corre o runtime **real** (`scenes/Main.tscn`, com os sete
autoloads vivos) como filho da sonda, sintetiza input (parada → movimento →
combate), e regista por frame o `delta` real mais os monitores do
`Performance`. Escreve JSON em `user://perf/<etiqueta>.json`.

Duas armadilhas encontradas e resolvidas na própria sonda, que vale a pena
registar porque envenenam qualquer medição futura:

- morrer chama `get_tree().reload_current_scene()`
  ([`koliani.gd:1989`](../scripts/koliani.gd)) e a cena atual **é a sonda** —
  a medição reiniciava em ciclo infinito. O estado passou a viver em metas do
  `SceneTree`, que sobrevive ao reload;
- `--headless` não renderiza neste build (driver "dummy"), por isso todas as
  medições correram com **janela real** no `--screen 1`.

Medições de referência (editor binary, `--screen 1`, Vulkan Forward Mobile,
RTX 5070, painel 165 Hz). O EXE real foi medido à parte com `--print-fps`.

## O que NÃO é o problema — tudo medido, tudo negativo

| Hipótese do briefing | Resultado |
|---|---|
| Custo de render / GPU | 0,72 ms/frame a 1080p. **Negativo** |
| Custo de script | `TIME_PROCESS` 0,03–0,12 ms. **Negativo** |
| Custo de física | `TIME_PHYSICS_PROCESS` 0,16–0,35 ms. **Negativo** |
| Fugas / acumulação de nós | 47 reloads: nós **fixos em 871**, órfãos 0. **Negativo** |
| Memória | +1,1 MB em 90 s e 47 reloads. **Negativo** |
| Logging patológico | 20 `print` no total, nenhum por frame. **Negativo** |
| Sistemas de debug escondidos | `DevBarra` nem sequer é instanciada em release (`main.gd:46`), `_unhandled_input` sai logo (`main.gd:100`). **HIDDEN == DISABLED. Negativo** |
| Partículas / VFX | −3,0 % do tempo de frame. **Negativo** |
| Luzes 2D | −17,7 % de 0,72 ms = **0,13 ms**. Irrelevante |
| Overdraw / transparências | 129 draw calls, 2680 primitivas. **Negativo** |
| Inimigos / IA / chefe | L5 (boss) tem o mesmo tempo de frame que L1. **Negativo** |

### Prova de não-acumulação (secção 10)

90 s, recarregando o nível de 7 em 7 s, mais as mortes pelo caminho —
**47 recargas no total**:

```
ciclo    t      nós  objetos  órfãos  mem_MB
  0     1.5     871     3316       0    78.0
  6    43.6     871     3333       0    78.6
 12    85.6     871     3342       0    79.1
```

Contagem de nós rigorosamente constante. Não há fuga.

### Matriz de isolamento (secção 23) — L1, 1080p, VSync desligado

```
base            1388 fps   0.720 ms    —
sem atmosfera   1402 fps   0.713 ms   -1.0 %
sem partículas  1432 fps   0.698 ms   -3.0 %
sem luzes       1687 fps   0.593 ms  -17.7 %
sem HUD         1601 fps   0.625 ms  -13.3 %
```

Nada aqui justifica desligar seja o que for. A direção Hybrid Cinematic
aprovada **não é cara** e não deve ser tocada por causa de FPS.

## Causas-raiz

### ROOT CAUSE #1 — cadência: mundo a 60 Hz num ecrã de 165 Hz

**STATUS: PROVEN.**

`Engine.physics_ticks_per_second` = 60 e
`physics/common/physics_interpolation` = **false** (não está sequer escrito
no `project.godot`, fica no default). O render corre com VSync a 165 Hz.

165 / 60 = 2,75 → cada estado do mundo é mostrado durante 2 ou 3
atualizações do ecrã, num padrão 3-3-2. Medido na Koliani a correr:

```
frames desenhados sem avanço nenhum:  67,2 %
desvio relativo do avanço por frame:   1,45   (0 = perfeitamente suave)
```

**Dois em cada três frames desenhados são duplicados.** Os FPS ficam nos 165
e o contador nunca acusa nada — mas o movimento avança aos degraus, com uma
batida irregular. É exatamente isto que se lê como "framedrop severo" sem os
FPS caírem, e é a única causa presente em **todo** o tempo de jogo.

Isto não é regressão da Execution 8: é assim desde sempre. O que mudou foi o
Game Master estar a jogar a sério num painel de 165 Hz.

### ROOT CAUSE #2 — engasgo de ~150 ms em cada carregamento de cena

**STATUS: PROVEN.**

Travessia de 45 s, três níveis:

```
        FPS    p95      p99     pior    frames>33ms   recargas
L1     57.3   16.7ms   24.2ms   149ms     23/2578        11
L3     57.4   16.7ms   23.9ms   147ms     21/2583        11
L5     57.6   16.7ms   22.8ms   149ms     21/2595        10
```

≈2 frames perdidos por recarga, sempre ~150 ms. Fora das recargas o p95 é
16,7 ms — liso. **Todos os picos medidos são carregamentos de cena.** Como
morrer recarrega o nível, quem morre muito leva um congelamento de 150 ms de
cada vez. `main.gd:26` faz `load()` + `instantiate()` síncronos, e o
`Atmosfera._gerar_parallax()` constrói o cenário todo no `_ready`.

### ROOT CAUSE #3 — compilação de pipelines à primeira utilização

**STATUS: LIKELY** (observado, não isolado).

`Koliani.exe` real, três sessões (janela 720p, janela 1280×720 e ecrã
inteiro): 165 FPS estáveis, com quedas esparsas de um segundo perto da
entrada no nível — `165 → 150 → 75`, `165 → 114 → 113`, `165 → 104 → 107`.
O preset de export **não tem `shader_baker/enabled`** (a opção existe no
4.7.2), portanto os pipelines Vulkan compilam durante o jogo.

Sozinha, esta causa não explica a queixa: são segundos isolados, não algo
contínuo.

## Reprodução da queixa do Game Master

| | |
|---|---|
| Problema reproduzido | **PARCIALMENTE** |
| Tipo | **NÃO é FPS baixo.** É cadência/stutter |
| Menu | 60 FPS, **zero** picos > 33 ms |
| Nível 1 | 165 FPS; judder contínuo; 150 ms por morte |
| Nível 3 | igual ao L1 |
| Nível 5 | igual ao L1 |
| Coração Putrefacto | mesmo tempo de frame que o L1; sem custo anormal na fase 2 |
| Piora com o tempo | **NÃO** (47 recargas, tudo estável) |

Não consegui reproduzir "FPS severamente baixo" em lado nenhum. O que existe
e é constante é o judder do #1, mais o engasgo do #2.

## Correções

**Nenhuma alteração ao runtime do jogo foi feita nesta execução.** As três
correções indicadas são arquiteturais e caem na secção 25 do briefing.

### TECHNICAL FIX REQUIRES GAME MASTER REVIEW — #1

Ligar `physics/common/physics_interpolation = true`.

Porquê é a correção certa: mantém a física a 60 Hz — **não mexe em constantes
de movimento, salto, dash, câmara nem timings de combate**. Só interpola a
transformação *desenhada* entre ticks, dando movimento suave a 165 Hz.

Porque **não** a apliquei às cegas:

- é uma mudança de comportamento do motor em todos os `Node2D`;
- exige `reset_physics_interpolation()` em cada teletransporte (respawn,
  checkpoint, arenas de chefe) — sem isso vê-se um arrasto de um tick;
- nós movidos no `_process` e não no `_physics_process` precisam de
  interpolação desligada à mão. Há pelo menos um caso já identificado:
  `atmosfera.gd:268` põe `_poeira.global_position` todos os frames;
- **não a consigo verificar com esta sonda**: `global_position` devolve a
  transformação da física, não a interpolada, por isso a métrica de suavidade
  fica cega à melhoria. Confirmei experimentalmente — com a interpolação
  ligada a métrica não mexe (67,3 %), o que **não** prova que não funcione,
  prova que a sonda não a vê. A validação tem de ser visual, humana.

Alternativa mais fraca que **testei e rejeito**: limitar a 60 FPS
(`max_fps = 60`) baixa os frames duplicados de 67,2 % para 10,9 % e o desvio
de 1,45 para 0,36, mas isso é enganador — o mundo continua a avançar 60×/s e
cada estado continua a ser mostrado durante 2 ou 3 atualizações do painel. A
cadência percebida é a mesma; só se poupa GPU. Não resolve a queixa.

### TECHNICAL FIX REQUIRES GAME MASTER REVIEW — #2

Carregamento do nível fora da thread principal
(`ResourceLoader.load_threaded_request`) e/ou geração do parallax repartida
por frames. Muda a arquitetura de arranque de nível; não é para fazer sem
decisão.

### Correção segura mas de valor baixo — #3

`shader_baker/enabled=true` no preset de export. É definição de build, não
toca em design nem em runtime. Não a apliquei porque exigia dois exports e
uma limpeza da cache de shaders para provar o efeito, e a evidência diz que
resolveria segundos isolados — não a queixa. Fica recomendada para quando
houver um export de qualquer forma.

## Regressões

Não aplicável: **zero alterações ao código, cenas, assets ou definições do
jogo**. O único ficheiro novo é a sonda em `tools/`, que está excluída do
export (`exclude_filter=...tools/**...`) e não é carregada pelo jogo.

## Entrega

- Windows: **não reexportado** (não havia alterações de source a entregar).
  `build/windows/Koliani.exe` continua a ser o binário da Execution 8 e foi
  usado como alvo de medição real.
- Web/PWA: **NOT REQUIRED** pela mesma razão.
- Android/iOS: fora de scope.

## Nota de efeito secundário

As medições correram o jogo a sério e por isso escreveram no save real
(`user://progresso.json`): `current_level_id` ficou em `level_001` e a sessão
de nível ativa. Nada foi apagado — `completed_level_ids` e `essencia` (165)
estão intactos.

## Veredicto

1. **O que causou os "frame drops"?** Cadência, não custo: o mundo avança 60
   vezes por segundo num painel de 165 Hz sem interpolação de física (#1),
   mais um congelamento de ~150 ms em cada morte/troca de nível (#2).
2. **Provadas:** #1 e #2. #3 é provável.
3. **Está resolvido?** **NÃO** — o diagnóstico está fechado, a correção de #1
   precisa de decisão e de validação visual humana.
4. **Windows serve para teste humano?** **SIM.** Corre a 165 FPS estáveis, sem
   fugas e sem custo anormal. O que falta é suavidade, não desempenho.
5. **Alguma correção mexeu no visual aprovado?** **NÃO** — não houve correções.
6. **Alguma mexeu no movimento/câmara/feel congelados?** **NÃO.**
7. **Bloqueadores?** A decisão sobre a interpolação de física.
8. **O que falta:** decidir #1, validá-lo visualmente (respawn, checkpoints,
   arenas de chefe, poeira da atmosfera), e depois decidir #2 e #3.

## Próximo gate

Mantém-se: WINDOWS PERFORMANCE GATE → **PRODUCTION ART GATE** → revisão
humana da vertical slice. Não iniciar a Região II.
