# F1 — Diagnóstico de movimento (25 set 2026)

**Só medição. Nenhuma constante, script de jogo, cena ou asset foi alterado.** A bancada é
`tools/bench_movimento_f1.gd|.tscn`; os dados em bruto (por tick) estão em
`docs/qa/f1_movimento/f1_movimento.json`. Barra de comparação: linha *Movement* e *Animation* de
`docs/vertical_slice_region01.md` §PASS + `docs/foundation_plan.md` F1.

Como repetir (isolado, ~1 min):

```bash
python tools/godot_isolado.py -- --headless --fixed-fps 60 --path . res://tools/bench_movimento_f1.tscn -- "C:/caminho/f1_movimento.json"
```

## Método

- Koliani **real** (`Koliani.tscn`, rig golden como na R-I, habilidades `dash`+`pogo`, sem salto duplo)
  numa arena plana (chão a y=600, rebordo em x=2000, bloco de 100 px para o mantle). Nada mockado.
- `--fixed-fps 60`: 1 tick de física = 1 frame de `process` (verificado: 8 599 = 8 599). Cada amostra é o
  estado no **fim do frame** (física + animação do mesmo tick). 0 = "no próprio tick do input".
- Os inputs entram no fim do frame anterior, como os eventos reais. **Armadilha apanhada:** premir dentro
  do sinal `physics_frame` atrasava o `just_pressed` um tick e deslocava salto/coyote/buffer; a 1.ª
  corrida (com esse atraso) deu coyote 5 e buffer 8 — errados. Os números abaixo são da versão corrigida.
- Físico a 60 Hz. Toda a corrida isolada por `godot_isolado.py`: save real com SHA idêntico.

## Métricas medidas

### Horizontal (chão) — VEL_CORRIDA 240 px/s
| Medida | Valor |
|---|---|
| Resposta do input → velocidade | **0 ticks** (38,3 px/s no 1.º tick) |
| Aceleração (2300 px/s²) | 6 ticks (0,10 s) até 240; 17,4 px de distância |
| Travagem (2200 px/s²) | 6 ticks até 0; derrapagem **11,2 px** |
| Viragem (3600 px/s²) | cruza 0 no tick 3 (6 px); −240 no tick 10 |

### Salto
| Medida | Valor | Barra |
|---|---|---|
| Altura máxima (botão segurado ≥ 20 ticks) | **82,9 px** | 125–135 → **FALHA** (−34 %) |
| Impulso / gravidade de subida | 470 px/s / 1400 px/s² | — |
| Gravidade de queda | 1400 × 1,22 = 1708 px/s² | — |
| Apex | tick 20–21 (0,34 s); tempo no ar 39 ticks (0,65 s) | — |
| Latência do input | 0 ticks | ok |
| Corte de salto | **×0,45 aplicado A CADA TICK** enquanto sobe sem botão: tap de 4 ticks dá vy −423 → −180 → −70,5 → −21 (≈ 5× a gravidade) | 1 só corte → **FALHA** |
| Meia-gravidade no apex | não existe; \|vy\|<50 durante ~3 ticks (−26,7 · −3,3 · +20) | **FALHA** |
| Altura por ticks premido | 1→13 · 2→20 · 3→27 · 4→33 · 6→45 · 8→55 · 10→63 · 15→78 · ≥20→82,9 px | — |
| Velocidade terminal | **1100 px/s**, ultrapassa 750 no tick 27 (0,45 s), satura no tick 39 | ≤ 750 → **FALHA** |
| Impacto de um salto normal | 504 px/s (= tier 2 "média" em `tier_aterragem`) | — |

### Queda e câmara
- Queda de 900 px: 69 ticks; **nos últimos 0,6 s percorre 637 px**. O mundo visível é 720 / zoom 1,4 =
  **514 px** de altura. Ou seja, sem antecipação da câmara o chão **não** está visível 0,6 s antes do
  impacto. *(Deduzido por geometria; o comportamento real da câmara ainda não foi medido — exige
  render/janela.)*

### Ar
| Medida | Valor |
|---|---|
| Aceleração no ar (1350 px/s²) | 13 ticks até 240 (vs 6 no chão) |
| Desaceleração no ar (1050 px/s²) | **16 ticks** até 0 (vs 6 no chão) — deriva |
| Viragem no ar (1800 px/s²) | cruza 0 em 7 ticks; −240 em 18 (vs 3 / 10 no chão) |

### Coyote e buffer
| Medida | Valor | Barra |
|---|---|---|
| Coyote efetivo | **6 ticks** (salto com sucesso até k=5 após o 1.º tick "sem chão") | 6 → ok |
| Buffer efetivo (toque de 1 tick) | **7 ticks** (k=0..6) | ≥ 7 → ok |

### Aterragem
- `land` mostra-se **10 ticks em 100 % das aterragens** (30–900 px; a tira tem 15 ticks nominais, é
  cortada por `_aterrar_t` = 0,16 s) → barra ≥ 4 ticks: **ok**.
- Não bloqueia input: com direção premida a velocidade é ≥ 24 px/s no próprio tick do pouso.
  Consequência visual: a pose `land` desenha-se 10 ticks **enquanto ela já corre a 240 px/s**.
- Tiers: 30 px→1, 120 px→2, ≥250 px→3; squash 0,07 (30 px) a 0,61 (≥250 px).

### Dash (`VEL_DASH` 620, `DUR_DASH` 0,16)
| Medida | Valor |
|---|---|
| Estado dash | 10 ticks; i-frames 10 ticks (100 %) |
| Arranque | estado começa no tick 0 mas **a velocidade só aparece no tick 1** (1 tick de arranque a 0) |
| Distância | 103 px durante o estado; **186 px até parar** (620 → 0 leva mais 17 ticks, +82 px de deslize sem input) |
| A correr | 620 durante 10 ticks, depois 582 → 275 em 8 ticks (10 ticks até voltar a 240) |
| Recarga | 34 ticks (0,57 s; constante 0,55) |
| No ar sem `dash_aereo` | não dispara (correto) |
| `vy` no dash | 0 |

### Roll (`VEL_ROLAR` 360, `DUR_ROLAR` 0,30)
| Medida | Valor | Barra |
|---|---|---|
| Estado rolar | 19 ticks (const = 18) | — |
| Distância | 114 px no estado; 140,5 px até parar | — |
| I-frames | 19 ticks | — |
| Arranque | estado no tick 0, velocidade no tick 1 (como o dash) | — |
| **Encadeado** (toques alternados, direção premida) | ciclo de **28 ticks** (recarga 0,45 s); **326 px/s de média** vs correr 240 (+36 %); 1311 px em 4 s contra 960 | < 240 → **FALHA** (a auditoria dizia 302; medido aqui 326) |
| Cobertura de i-frames no encadeado | 19 de 28 ticks = 68 % | — |

### Agarrar a borda / mantle (bloco de 100 px)
- Agarra a cair (10 px da face; `y = lip + 34`). Animação enquanto pendurada: `borda`.
- **Subir exige o botão de saltar segurado ≥ 12 ticks (0,2 s).** Com 1, 3 ou 8 ticks a Koliani sobe 12–49 px,
  fica encostada à parede (x nunca avança) e **volta a agarrar a borda** em loop. O impulso do mantle
  (150, −430) também está sujeito ao corte de salto por tick.
- **Não há animação de mantle**: a subida mostra `jump_loop`/`fall`.

### Máquina de animação (fim de frame)
| Transição | Medido |
|---|---|
| idle → correr | `run` no tick 0 (sem `run_start`: a tira `run_start` de 6 frames **nunca toca**) |
| correr → parar | `run` 5 ticks → `run_brake` **18 ticks** → `idle`. A física pára no tick 6, logo ~12 ticks de pose de travagem parada |
| viragem a correr | `turn` **3 ticks** → `run_brake` **1 tick** (flicker) → `run` |
| salto | `jump_start` 20 ticks → `jump_loop` 1 → `fall` 18 → `land` 10 |
| dash | `dash` 10 → `run` 17 (deslize) → `run_brake` 13 |
| roll | `roll` 19 → `run` 10 → `run_brake` 11 |
| Frames legados | **0**: as 26 animações vêm de `koliani_golden_set`. Mas `turn` = `run_001..004`; `run_brake` = `run_010, run_009, run_003, run_001, idle_004, idle_001`; `land` = `fall_003, fall_001, crouch_001, idle_001` — reaproveitam poses, não há pose própria de viragem/travagem/aterragem |

### Não medido nesta fase (fora da lista pedida)
Velocidade externa preservada ≥ 60 ticks (vento/íman/trampolim), knockback ao levar dano, comportamento
real da câmara em queda, salto duplo/pogo em ciclo. Continuam por medir em F1.6/F1.7.

## Problemas objetivos e prioridade (proposta minha; decisão do GM)

**P0 — falham a barra Movement e definem a sensação inteira do slice**
1. Altura do salto 82,9 px contra 125–135 px.
2. Corte de salto aplicado por tick (≈ 5× a gravidade) em vez de um corte único.
3. Sem meia-gravidade no apex (hang ≈ 3 ticks).
4. Velocidade terminal 1100 px/s contra ≤ 750 px/s; a queda de 0,6 s (637 px) excede o mundo visível
   (514 px), pendente de confirmar com a câmara real.

**P1 — falham uma barra ou quebram a fiabilidade de uma mecânica que o slice usa**
5. Rolar encadeado a 326 px/s (mais rápido que correr; barra < 240).
6. Mantle: falha silenciosa com toque curto (< 12 ticks) e em loop de re-agarrar; sem animação de mantle
   (barra "mantle com animação").
7. Dash e roll arrancam a 0 durante 1 tick (velocidade só no tick seguinte); o dash deixa 17 ticks / 82 px
   de deslize sem input, o que anula a leitura "100 px de dash".
8. Deriva no ar: parar no ar demora 16 ticks (vs 6 no chão) e virar 18 ticks.

**P2 — visuais, sem violar a barra**
9. `run_brake` 18 ticks com a física parada ao tick 6; flicker de 1 tick de `run_brake` entre `turn` e `run`.
10. `run_start` nunca é usada; `turn`/`run_brake`/`land` reaproveitam poses de outras animações.
11. `land` (10 ticks) sobrepõe-se à corrida quando há direção premida.
12. Todo o salto normal aterra a 504 px/s = tier 2 (VFX + som médios em cada aterragem).

Ok face à barra: coyote 6 ticks, buffer 7 ticks, `land` ≥ 4 ticks, resposta do input horizontal e do
salto a 0 ticks, aceleração/travagem/viragem no chão rápidas.

## Alterações recomendadas — NÃO implementadas
1. **Salto**: `FORCA_SALTO` 470 → ~600 com `GRAVIDADE` de subida 1400 dá ≈ 128 px; meia-gravidade quando
   `|vy| < ~80`; corte **único** (multiplicar `vy` uma vez ao largar, com flag). `STOMP_RESSALTO` =
   `FORCA_SALTO × 0.7` sobe de 329 para ~420 (pogo de 39 → 63 px): decidir se se desacopla. Re-correr
   `tools/verifica_alcance*.gd` nos 100 níveis e registar o que quebra (informação, não bloqueio).
2. **Queda**: `VEL_MAX_QUEDA` 1100 → 750 (ou fast-fall por input) + antecipação vertical da câmara; medir a
   câmara numa janela real.
3. **Rolar**: escolher entre (a) `VEL_ROLAR` ≤ 240 (só i-frames) ou (b) recuperação pós-rolamento lenta
   (ex. teto de ~120 px/s durante ~6 ticks) para a média encadeada ficar < 240. Afinar `RECARGA_ROLAR`.
4. **Dash/roll**: aplicar a velocidade no próprio tick do gatilho; no fim do dash limitar a `VEL_CORRIDA`
   (ou brake curto) em vez de deixar 620 decair sem input.
5. **Mantle**: movimento com deslocamento fixo (independente do botão e do corte), animação própria.
6. **Ar**: aproximar `DESACEL_AR`/`VIRAGEM_AR` do chão (F1 só regista; é escolha de feel).
7. **Animação**: máquina de estados no tick de física com duração mínima e cancel por input após 4 ticks
   no `land`; encurtar `run_brake` ao tempo de travagem física; corrigir o flicker turn→brake;
   decidir sobre `run_start`.
8. **Regressão**: transformar esta bancada em teste com limiares (barra do slice) antes de afinar, para
   cada tuning ser medido e não julgado ao olho.

## Confirmação
Nenhuma mecânica nem gameplay foi alterada: `git diff -- scripts scenes project.godot assets` vazio.
Ficheiros novos: `tools/bench_movimento_f1.gd|.tscn`, `docs/qa/f1_movimento/f1_movimento.json`, este
relatório. Saves reais intactos (SHA verificado em cada corrida). Não foi feito tuning.
