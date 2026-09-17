# N08 — Auditoria pré-Process 11 (modelo da Koliani + estrutura)

Data: 17 set 2026 · Base: `origin/codex/region02-wind-system` @ `c41c19ed`
· Branch: `claude/n08-preflight-audit` · Worktree limpa dedicada
(`C:\Projetos\koliani-n08-audit`). A árvore principal tinha 85 alterações
alheias, e `koliani-region02-n08` (`claude/region02-n08-glide`, mesma base)
tem trabalho de planar ainda sem commit. **Nenhuma das duas foi tocada.**

Âmbito: só auditoria e correção da referência errada. Não se implementou o
planar, não se redesenhou o N08 e o Process 11 não arrancou.

---

## 1. Koliani: suspeita CONFIRMADA

| | Cena | Recurso visual |
|---|---|---|
| **Canónica** | `scenes/actors/Koliani.tscn` com `usar_prototipo_premium = true` + `usar_golden_set = true` | `Sprite/Corpo` (AnimatedSprite2D, Nearest). O `SpriteFrames` é montado em runtime por `scripts/koliani.gd::_montar_golden_set` a partir de `res://assets/sprites/koliani_golden_set/frames/**` (128×128). A RUN é `frames/run_final/run_001..010.png`, a 13,333 fps em loop |
| **N08 antes** | `scenes/actors/Koliani.tscn` (mesma cena) **sem** as duas flags | `RIG := "shadowblade"`, ou seja o atlas `res://assets/sprites/pixel/koliani_shadowblade/*.png` (51×64). RUN de 5 frames a 13 fps, sem animação `morte` |
| **N08 depois** | igual à canónica | igual à canónica (medido, ver §6) |

**Modelo antigo referenciado: SIM.**

### Causa

O Golden Set **liga-se nível a nível**. `scripts/koliani.gd:473` declara
`@export var usar_golden_set := false`, e o valor por omissão cai no rig
`shadowblade` (`const RIG`, linha 460). Só as cinco cenas da Região I ligam as
flags no nó `Koliani` (`Floresta_Putrefata`, `Pantano_dos_Sussurros`,
`Ninho_da_Viuva_Negra`, `A_Arvore_que_Chora`, `Coracao_da_Floresta`), e o
teste `teste_execution_8_integracao_player_facing` só verifica esses cinco.
A integração da RUN final (`e665da0b`) mexeu em `_montar_golden_set`, que
nunca corre nos níveis sem a flag.

Não há cache, import antigo nem troca de sprites em runtime: a referência
está mesmo em falta na cena. Também não há cena herdada nem override de
recursos. **Não afeta só o N08**: todos os níveis de 6 a 100 continuam na
Shadowblade (fora do âmbito, fica registado).

### Correção (mínima)

`scenes/levels/Corredor_das_Execucoes.tscn`, nó `Koliani`: as mesmas duas
linhas que a Região I já usa.

```
usar_prototipo_premium = true
usar_golden_set = true
```

Não se mexeu em sprites, escala, física, timing, colisões nem código.

---

## 2. O N08 real: jornada procedural + sala feita à mão

A cena não define `corredor = false`, portanto `nivel_com_chefe.gd::_ready`
põe a **jornada** (`gerador_corredor.gd`) antes da sala. Medido em runtime
(`runtime_geometry_n06_n09.json`):

| | N06 | N07 | N08 | N09 |
|---|---|---|---|---|
| Comprimento da jornada | 8 850 px | 10 100 px | **11 350 px** | 12 600 px |
| Comprimento da sala | ~3 110 px | ~3 030 px | ~3 030 px | ~3 010 px |
| Peso da jornada no total | 74 % | 77 % | **79 %** | 81 % |
| Perfil (foco / tendência / abertura) | máquina / 0 / 0,95 | máquina / −1 / 0,85 | **gauntlet / 0 / 0,80** | combate / 0 / 0,90 |
| Estreia (`MECANICA_DO_NIVEL`) | alavanca | fogo | **guilhotinas** | arena |
| Câmaras usadas | alavanca, arena, descanso, espinhos | alavanca, arena, descanso, espinhos, fogo | **descanso, espinhos, guilhotinas, saltos** | alavanca, arena, descanso, espinhos, pilares |
| Plataformas na jornada | 59 | 77 | 78 | 86 |
| Amplitude vertical do topo das plataformas (jornada) | 389 px | 413 px | **253 px** | 298 px |
| Amplitude vertical (sala) | 209 px | 239 px | **129 px** | 149 px |
| Vão médio / máx. (jornada) | 43 / 118 | 48 / 120 | 51 / 100 | 44 / 122 |
| Perigos na jornada | 10 | 18 | **25** | 20 |
| Inimigos na jornada / sala | 8 / 2 | 11 / 2 | **6 / 1** | 10 / 2 |
| Checkpoints na jornada / sala | 3 / 2 | 3 / 2 | 4 / 2 | 4 / 2 |
| `WindZone` na sala (commit `c41c19ed`) | 2 | 3 | **0** | 3 |
| Casca / líquido | masmorra fechada / ácido | masmorra fechada / lava | masmorra fechada / ácido | masmorra fechada / ácido |

### Molde da sala (igual nos quatro)

`ChaoInicio` x=280 → 3–4 plataformas pequenas → `ChaoMeio`
(x 1360–1560) com o **elite ao centro** e `CheckMeio` → **bifurcação
alto/baixo** (Cima/Baixo · C/P · Alto/Baixo · EspF/S) → `Reencontro`
(x 2230–2520) com `Coletavel` e `CheckReencontro` → [`Pre1` x=2500 no N08 e
no N09] → `ChaoChefe` (x 2900–2960) com o chefe → `Porta` (x 3160–3260).
As luzes (`LuzInicio`/`LuzMeio`/`LuzChefe`) têm as mesmas escalas, a
`CascaMasmorra` tem 3,6k × 2,2k e o líquido mortal tem 3,8–4k de largura.
Os nomes dos nós, a ordem e as coordenadas coincidem a ±200 px.

### Molde da jornada (igual nos quatro)

`Cam_1` (partida) → 4–5 câmaras de ~1,9–2,5k px → última `Cam` com um
inimigo antes da sala. As câmaras `descanso` e `espinhos` aparecem nos quatro
níveis, `alavanca`+`arena` em três. `PenduloLamina`, `Espinhos` e
`DemonioBase` repetem-se em quase todas. Por baixo há sempre uma espinha de
plataformas pequenas sobre líquido mortal.

### Classificação: **TOO SIMILAR**

Ao jogar, o N08 é o mesmo esqueleto do N06, do N07 e do N09 (jornada
procedural sobre líquido + sala molde com bifurcação e reencontro + arena).
Distingue-se só pelo tipo de perigo (guilhotinas) e é o **mais plano** dos
quatro, o contrário do cânone "ilhas suspensas + planar"
(`docs/audits/region_02_canonical_delta_audit.md`).

---

## 3. Comparação objetiva

**SIMILARITIES WITH N06:** sala com o mesmo molde e coordenadas
(ChaoInicio 280, ChaoMeio+elite, bifurcação 4+4, Reencontro+Coletavel,
ChaoChefe ~2900, Porta ~3200); o mesmo `fundo_pack="prisao"`; `CascaMasmorra`
fechada; ácido; jornada com `descanso`+`espinhos`; `tendencia 0`.

**SIMILARITIES WITH N07:** mesmo molde de sala; a mesma bifurcação
(C1–C4 / P1–P4 contra Alto/Baixo); `Serra` na rota baixa nos dois;
comprimentos de sala e jornada parecidos (10,1k contra 11,35k); jornada com
`descanso`+`espinhos`; casca fechada.

**SIMILARITIES WITH N09:** mesmo molde, incluindo o `Pre1` em x=2500 antes da
arena (só N08 e N09 o têm); ácido; casca fechada; espinha de plataformas
pequenas; amplitude vertical baixa (253/129 contra 298/149).

**DISTINCTIVE ELEMENTS ALREADY PRESENT:** câmara `guilhotinas` na jornada
(6 guilhotinas numa só câmara) e 5 guilhotinas na sala; câmara `saltos`;
`PlataformaQuebra` (`QuebraA`); foco `gauntlet` com a maior densidade de
perigos (25); é o único dos quatro sem alavanca/porta trancada; chefe Dama da
Guilhotina; o `ColProjetil` (desbloqueio do projétil).

**ELEMENTS THAT PROCESS 11 MUST CHANGE:**
1. O molde da sala: bifurcação alto/baixo → reencontro. É o maior fator de
   "já joguei isto".
2. A verticalidade: é o nível mais plano da região (129 px na sala). O planar
   precisa de quedas e de distâncias grandes entre ilhas.
3. O tecto: a `CascaMasmorra` fechada corta o `_teto_y` da jornada
   (`gerador_corredor.gd`, "masmorra FECHADA"), e "ilhas suspensas" pede céu
   aberto.
4. O perfil da jornada do índice 7 (`PERFIL` foco `gauntlet`, abertura 0,80,
   estreia `guilhotinas`), ou `corredor = false`. Hoje 79 % do nível sai
   deste gerador, por isso redesenhar só a sala muda 21 % da experiência.
5. O gauntlet de guilhotinas/serra sobre ácido, incompatível com o foco aéreo
   (o delta audit já o marcou REMOVE/REPLACE).
6. O elite ao centro do `ChaoMeio`, que é a mesma posição nos quatro níveis.

**ELEMENTS SAFE TO KEEP:**
- a Koliani canónica (esta correção);
- o path, o uid e o nome da cena, `Porta`, spawn e os IDs `CheckInicio` /
  `CheckMeio` / `CheckReencontro` (topologia de save);
- `ColProjetil` (progressão: não pode desaparecer sem sítio alternativo);
- um slot de clímax no fim (chefe ou guardião, conforme a decisão regional);
- o nó `Atmosfera` (gerado por `tools/afinar_atmosfera.py`; não mexer à mão);
- `PlataformaQuebra` como vocabulário (cabe em ilhas que se desfazem).

---

## 4. Capturas (worktree atual, Godot 4.7.2, Vulkan, janela real 1280×720)

Todas estão em `docs/audits/n08_pre_process11/`, foram tiradas de
`c41c19ed` + correção e não vêm de nenhuma build antiga.

| # | Ficheiro | O que mostra |
|---|---|---|
| 1 | `n08_1_inicio.png` | início da jornada (x = −11 120) |
| 2 | `n08_2_primeiro_terco.png` | 1.º terço do percurso total |
| 3 | `n08_3_centro.png` | centro do percurso |
| 4 | `n08_4_ultimo_terco.png` | último terço (fim da jornada / entrada da sala) |
| 5 | `n08_5_arena_final.png` | arena da Dama da Guilhotina |
| 6 | `n08_6_koliani_gameplay.png` | Koliani Golden Set a correr no `ChaoMeio` com o elite |
| 7 | `n08_7_koliani_zoom.png` | a mesma cena em zoom 2,5 |
| — | `n08_ANTES_6_…`, `n08_ANTES_7_…` | a mesma posição com a Shadowblade (antes) |
| — | `koliani_antes_vs_depois.png` | recorte lado a lado |
| — | `n08_folha_contacto.png` | 1–6 numa folha |
| — | `n08_estados_golden.png` | idle/run/jump/dash/morte/respawn (plano largo; a prova está nos JSON) |

Harness: `audit_n08.gd.txt` (extensão `.txt` para o Godot não o apanhar no
scan de classes). Corre-se com
`Godot --path . --window --screen 1 --script <copia .gd> -- shots|anims|dump <out>`.
Nota: `EstadoJogo.ativar_modo_dev()` põe `indice_nivel = 0`. Chamado antes de
carregar a cena, a jornada não reposiciona a Koliani e a captura sai na sala.
Por isso ativa-se sempre depois.

---

## 5. Validação da Koliani (N08, cena gravada, sem override em memória)

Dados em `anims_antigo.json` e `anims_golden.json`, lidos do `AnimatedSprite2D`
real durante input simulado no `ChaoInicio`:

| Estado | Antes (Shadowblade) | Depois (Golden Set) |
|---|---|---|
| Idle | `idle.png` atlas, 4 fr | `frames/idle`, 7 fr @8 |
| Run | `run.png` atlas, 5 fr @13 | `run_start` 6 fr → **`run_final/run_001..010` @13,333, loop** |
| Paragem | idle direto | `run_brake` 6 fr → idle |
| Jump | `jump` 2 fr / `fall` 1 fr | `jump_start` 4 fr → `fall` 3 fr → idle |
| Dash | sem animação própria (fica `run`) | `frames/dash` 3 fr @18,75 (`_dash_restante > 0` confirmado) |
| Death | sem `morte` (fica idle/run) | `frames/morte` 3 fr @14 |
| Respawn | idle | `recuperar_no_checkpoint` → `run_brake` → idle |
| Escala/offset do corpo | (1,1) / (0,−8) | **(1,1) / (0,−18)**, o contrato Golden Set da Região I |
| Colisão | 20×44 | 20×44 (sem alteração) |
| Filtro | Nearest | Nearest |

- A RUN de 10 frames está preservada: os 10 paths `run_final` estão na ordem
  01→10, a 13,333333 fps e em loop.
- Escala de gameplay preservada: é a mesma de L1–L5 (128×128, `EscalaCorpo`
  1,0, offset (0,−18)).
- Suite `res://tests/run_tests.tscn` via `tools/correr_testes.ps1` (sandbox de
  APPDATA): **"OK -- todos os testes passaram" antes e depois**, sem novas
  falhas.
- O save real ficou intacto: comparado com a cópia feita antes, só mudaram os
  logs do Godot.
- A morte foi validada só no plano visual (`_a_morrer` + `_atualizar_anim`),
  sem recarregar a cena nem gastar vidas. O ciclo completo de reload não foi
  exercido nesta auditoria.

---

## 6. Pendentes para decisão

1. **Níveis 6–100 continuam na Shadowblade.** A mesma correção de duas linhas
   aplica-se a cada cena, mas ficou fora do âmbito. Decidir se entra no
   Process 11 da Região II inteira ou num passe dedicado.
2. **Jornada no N08:** manter o gerador com outro `PERFIL`/estreia ou pôr
   `corredor = false` e desenhar as ilhas à mão. É esta decisão que define se
   o redesenho chega aos 79 % do nível.
3. **Trabalho de planar já existente** em `C:\Projetos\koliani-region02-n08`
   (`claude/region02-n08-glide`, sem commit): o Process 11 tem de o reconciliar
   com esta branch, que muda `Corredor_das_Execucoes.tscn`.
