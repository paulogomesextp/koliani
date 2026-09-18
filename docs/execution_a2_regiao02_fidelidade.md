# KOLIANI — EXECUTION REPORT

**Execução:** Super-Process A2 — Região II, remediação de fidelidade e jogabilidade
**Data:** 18 set 2026
**Branch:** `claude/region02-fidelity-remediation` (base:
`claude/region02-humanlike-bot-playtest` @ `1bfda76f`)
**Detalhe técnico completo:**
[`docs/implementation/region_02_fidelity_remediation.md`](implementation/region_02_fidelity_remediation.md)
**Ponto de partida:**
[`docs/playtests/region_02_bot_humanlike_playtest.md`](playtests/region_02_bot_humanlike_playtest.md)

> Nota de método: o texto exacto do briefing não sobreviveu à sessão. Este
> relatório segue a estrutura habitual dos `docs/execution_*.md` — pedido,
> o que se fez com prova, números, o que ficou por fazer.

---

## 1. Estado final

| | |
|---|---|
| GATE 1 — NaN do N06 | **FECHADO**, com causa provada |
| GATE 2 — pico de mortes do N10 | **FECHADO**, 200,7 → 18,5 mortes/1000 px |
| Fase 3 — bestiário canónico | **FEITA** (5 espécies da prancha) |
| Fases 4 e 5 — ambiente, props, Guardião | **FEITAS** |
| Fase 6 — re-audit visual | **FEITA** (19 fotografias novas) |
| Fase 7 — 30 runs do bot | **FEITA** |
| Fase 9 — build Windows | **FEITA** (fora do Git; chega pelo CI) |
| Varredura de harnesses | **FEITA** — 7/7 verdes, mais a suite e o chefe |
| Relatório final | **este documento** |

Nenhum nível ou encontro da região ficou classificado `FAILED`.

---

## 2. Os dois GATES

### GATE 1 — a Koliani ia a NaN no N06

Causa provada, não inferida: `_hitstop()` punha `Engine.time_scale = 0.0`,
o Godot passa `physics_step * time_scale` ao servidor de física, logo o passo
ia a **zero**; um `AnimatableBody2D` com `sync_to_physics` calcula a sua
velocidade por `motion / passo` — parado e com passo zero dá **0/0 = NaN** —
e quem está em cima herda-a em `move_and_slide()`.

**Não era um defeito da Região II:** valia para as nove plataformas
`AnimatableBody2D` do jogo.

Correcção: `Koliani.HITSTOP_ESCALA_TEMPO = 0.0005` (`84b409e9`).
Prova: teste determinístico + **0 frames NaN em 30 runs** do bot (antes
aparecia em ~1 de cada 4 runs do N06).

### GATE 2 — o N10 executava em vez de ferir

200,65 → **18,45 mortes/1000 px**; dano médio por run 58,8 → **214**;
progresso 100% em todos os perfis. A causa não era o salto, era a
consequência: a rajada acabava onde o chão acaba. Correcção: rajada
reajustada + laje `ChaoResgate` em x 540-880 (`5187b52c`). De x=880 para a
direita o ácido continua vivo de propósito.

Curva de mortes da região depois de tudo:
**N06 6,9 · N07 5,6 · N08 24,2 · N09 5,7 · N10 18,5** — o pico de outra
ordem de grandeza desapareceu.

---

## 3. Fidelidade — antes → depois

| Nível | antes | depois |
|---|---|---|
| N06 | LOW | **MEDIUM-HIGH** |
| N07 | MEDIUM | **HIGH** |
| N08 | MEDIUM | **HIGH** |
| N09 | LOW | **MEDIUM-HIGH** |
| N10 (arena) | LOW | **MEDIUM** |

| Encontro | antes | depois |
|---|---|---|
| Golem das Falésias | LOW | LOW *(não tocado)* |
| Vigia do Desfiladeiro | MEDIUM | MEDIUM *(não tocado)* |
| Feiticeira dos Ventos | MEDIUM | MEDIUM *(não tocado)* |
| Espectros Gémeos | MEDIUM | MEDIUM *(não tocado)* |
| **Guardião dos Céus** | MEDIUM (rig) · LOW (chefe+arena) | **HIGH (rig)** · **MEDIUM-HIGH (chefe+arena)** |

Principais mudanças com prova medida:
- **Bestiário:** 0 dos 10 inimigos canónicos → **5 espécies extraídas da
  prancha**, e 100% dos inimigos comuns da região canónicos. `attack.png` é
  nova: o `demonio_base.gd` já pedia `"attack"` no telégrafo e ninguém a
  montava.
- **Mar de nuvens:** realces 39-53% → **57-68%** (a textura foi pintada a
  51,9%).
- **Props:** 12 (3 de chão, dois deles de cemitério) → **25 canónicos**
  (8 de chão), mais folhagem carmesim no lábio do terreno e véus de nuvem no
  fundo do abismo.
- **Guardião:** asas ABERTAS E ERGUIDAS (arco +12, asas 40% mais longas),
  **3,59x** em largura e **2,46x** em altura — dentro das duas bandas do
  contrato; e a paleta ciano PROIBIDA (`#B8EBFF`) saiu dos cinco sítios onde
  estava.

---

## 4. Verificação

Tudo em Linux headless, com o `user://` isolado por `XDG_DATA_HOME`
(equivalente do `tools/correr_testes.ps1`), portanto **o save real não foi
tocado**.

| Harness | resultado |
|---|---|
| `tests/run_tests.tscn` (suite) | **OK** — todos os testes passaram |
| `tests/run_boss_guardiao_ceus.tscn` | **OK** — Process 12: Guardião dos Céus (N10) |
| `run_movement_camera_4a` | **OK** |
| `run_wind_system` | **OK** — WindZone reutilizável (A-L) |
| `run_glide_region02` | **OK** — planeio do N08 (A-O) |
| `run_region02_wind_shapes` | **OK** — formas das zonas de vento |
| `run_level_session_tests` | **OK** — 11 testes |
| `run_save_foundation_tests` | **OK** — 11 testes |
| `run_progression_ids_tests` | **OK** — 6 testes |

Todos saíram com código 0. Os `ObjectDB instances were leaked at exit` no fim
de cada um são o ruído normal de saída do Godot headless, não falhas.

**Art safety:** a comparação de geometria de gameplay
(`tools/geometria_regiao02.tscn -- comparar`) confirma **0 alterações de
jogabilidade** vindas do trabalho de arte.

Provas visuais: 45 fotografias reais do jogo no audit inicial
(`docs/playtests/region_02_visual_evidence/`) e 19 no re-audit
(`docs/playtests/region_02_visual_evidence_after/reaudit/`).
Dados do bot: `region_02_bot_humanlike_data.json` e
`region_02_visual_evidence_after/bot_r2_depois_dados.json`.

**Limite honesto:** o bot não luta o Guardião de forma válida (7,3 s de
combate em média). Os números de **traversal** valem; os de **combate** não.

---

## 5. Armadilhas de método (o que custou a descobrir)

1. As runs do bot **não são determinísticas entre processos** — a seed só
   governa o RNG do bot; o jogo usa `randf()` global. Foram precisas 12 runs
   para apanhar o NaN.
2. `x_max` **não mede progresso num poço vertical**; o bot passou a gravar
   `y_min`/`y_spawn`.
3. Um chão largo no fundo de uma subida vertical é um **atractor de
   navegação**; uma saliência estreita não resolve, muda a borda de sítio.
4. O ganho de brilho de uma camada de parallax **não pode ir dobrado na
   `tinta`** (`source_color`, grampeada a 1.0).
5. O véu da `superficie_textura` amostrava de y=0, onde a `nuvens.png` tem o
   céu escuro — daí o `veu_origem`.
6. **Levantar as asas de uma ave troca largura por altura**, e o jogo escala
   o chefe pela ALTURA.
7. `gerar_terreno_regiao02.py` fazia `cat["desfiladeiro"] = cat["torres"]` —
   origem dos props de cemitério e bomba-relógio; corrigido.

Hipóteses **descartadas** no GATE 1, para não se voltarem a pagar: vectores
de vento, `aplicar_forca_externa`, divisão por `delta`, escala zero num nó,
knockback/respawn/declives.

---

## 6. O que ficou por fazer — decisão do Paulo

1. **Lua de sangue** — continua fora do enquadramento. O caminho certo é um
   elemento PRÓPRIO na camada `Ceu` do `atmosfera.gd` (`motion_scale = 0`),
   não um recorte da `ceu.png`. Prioridade BAIXA (#15) no audit.
2. **Os quatro guardiões intermédios** (Golem, Vigia, Feiticeira, Espectros)
   não foram tocados. O Vigia continua a CAMINHAR e a `TORRE VIGIA` da
   prancha é uma estrutura fixa.
3. **As outras cinco criaturas canónicas** (serpente eólica, espectro das
   ruínas, arqueiro eólico, torre vigia, mago do vento como inimigo comum).
4. **O N10 ficou fácil demais?** Cumpriu o alvo (ordem do N08), mas quem
   decide se o exame final quer mais mordida é o Paulo, no playtest humano.
   As três variantes medidas estão em comentário na cena.
5. **Contraste** — o mar de nuvens foi clareado de propósito; se algum nível
   parecer LAVADO, o botão é o 5.º campo da tabela `PACKS` em `atmosfera.gd`.

---

## 7. Commits

```
c8b19876 docs: estado do Super-Process A2 -- Fases 3 a 9 feitas
77b4c891 art: folhagem carmesim no terreno, e o tool deixa de apagar os props
8c59be26 art: o Guardiao dos Ceus com as asas abertas da prancha
cbf640bf art: props canonicos e mar de nuvens no fundo do Desfiladeiro
a74152ec art: paleta do contrato no Guardiao e mar de nuvens de volta
74b487e8 feat: bestiario canonico da Regiao II, recortado da prancha aprovada
bbb5862d chore: metadados de import que faltavam + ignorar traducoes compiladas
1ae59868 docs: plano atual -- estado fase a fase do Super-Process A2
206519a2 docs: estado do Super-Process A2 apos os GATES 1 e 2
5187b52c fix: rebalance region02 finale approach hazard    (GATE 2)
84b409e9 fix: prevent region02 invalid player motion state (GATE 1)
```

151 ficheiros, +3019 / -76 (código, cenas, tools e assets).

A build de Windows está feita e verificada, mas **fora do Git e num contentor
efémero**: chega ao Paulo pelo CI, que corre em cada push.
