# Combat Production Integration — relatório final (Fases 0–13)

Execução "KOLIANI — CONTROLLED COMBAT INTEGRATION". Baseline: Combat Lab
v1.2 (`24f5f26d`). Plano técnico: [`plano_integracao_combate_producao.md`](plano_integracao_combate_producao.md)
(`7a8e7b84`). Este documento fecha a execução — ver `docs/retomar_aqui.md`
para o estado operacional do dia-a-dia e `PRIORIDADES.md` para o que fica
pendente de decisão.

## Commits (por ordem, todos em cima de `24f5f26d`)

| Fase | Commit | O que fez |
|---|---|---|
| 0 (preflight) | — (só leitura/verificação) | Confirmou branch, HEAD, working tree, sem outra sessão em conflito |
| 1 (fundação de config) | `5c617f3e` | `scripts/combate/balance_combate.gd` (`BalanceCombate`, Resource com os números do Combat Lab v1.2) |
| 5 (contrato de origem) | `4c779bc7` + `2b8599d5` | `scripts/combate/origem_dano.gd` (`OrigemDano`) + migração dos 20 call-sites de produção |
| — (docs) | `7cc4b667` | Registo intermédio do estado (Fases 0/1/5) |
| — (workflow) | `b81887b3` | `tools/correr_testes.ps1` reimporta sempre antes da suite (ver Incidente abaixo) |
| 2/3/4/6 (Core Combat) | `601f1e30` | `scripts/combate/core_combate.gd` (`CoreCombate`): Launcher, Air Combo, Shadow Cleave, Dash Attack, Perfect Dodge, Shadow Counter — opt-in via `Koliani.ativar_core_combate()` |
| — (docs) | `81ac4df8` | Registo intermédio do estado (Fases 0-6 + workflow) |
| 7 (Enemy Combat Contract v1) | `a536bc2d` | `scripts/demonio_base.gd`: `piloto_combate_v1`, `peso`, `pode_ser_lancado`, `tem_guarda_v1`, `guarda_max_v1`, `hurtbox()`, `lab_hit()` |
| 8 (Goblin piloto) | `743ff42f` | `GoblinAprendiz` (N1, `Floresta_Putrefata.tscn`) liga o contrato |
| 9 (Golem piloto) | `6e23cf08` | `EliteGolem` (N6, `Prisao_dos_Condenados.tscn`) liga o contrato + janela de exposição na guarda |
| 10 (Energy instrumentation) | `a1e23b4c` | `teste_energy_instrumentation` mede 6 cenários + baseline |
| 11 (arena de QA) | `a39284a3` | `scenes/qa/ProductionCombatArena.tscn` |
| 13 (este documento) | — | `docs/combat_production_integration_report.md` |

Todos os commits: `git add` com paths explícitos, sem push, testados
individualmente com a suite completa a passar antes de cada um.

## GODOT CLASS CACHE INCIDENT

- **Causa**: um script novo com `class_name` (`OrigemDano`, `BalanceCombate`,
  depois `CoreCombate`, `QaCombateHud`) só fica visível a outros scripts
  depois de `--headless --import` reescrever
  `.godot/global_script_class_cache.cfg` (fora do git).
- **Sintoma**: `chefe_base.gd` referenciava `OrigemDano.CONTATO` e falhava a
  compilar em silêncio; como é a classe-mãe de ~30 chefes, todos partiam com
  `SCRIPT ERROR: Invalid call. Nonexistent function '_process' in base 'Nil'`.
- **Impacto medido**: baseline sem os ficheiros = 0 falhas; com os
  ficheiros sem reimportar = **79 falhas**; com os ficheiros + import = 0
  falhas outra vez.
- **Corrigido no workflow**: `tools/correr_testes.ps1` (commit `b81887b3`)
  corre sempre `--headless --import` antes da suite, incondicional e
  idempotente. Nota espelhada no `CLAUDE.md`. Não se repetiu nas 20+
  corridas seguintes desta execução.

## KOLIANI (produção)

`CoreCombate` (`scripts/combate/core_combate.gd`) é a mesma lógica
validada do Combat Lab, lendo de `BalanceCombate`/`OrigemDano` em vez de
constantes soltas. Ligado via `ativar_core_combate()`, espelhando
`ativar_combat_lab()` — os 7 pontos de despacho em `koliani.gd` passam por
um helper único (`_combate_extra()`) que devolve `_lab` ou `_core`, nunca
os dois ao mesmo tempo na prática.

- **Ataques integrados**: combo x4 (inalterado), Launcher (CIMA+ATAQUE no
  chão), Air Combo (x2), Shadow Cleave (segurar ATAQUE ~0,5s), Dash Attack,
  Perfect Dodge (Roll + origem `ATAQUE`/`HAZARD_ATAQUE`, janela ~0,22s),
  Shadow Counter (janela ~0,60s após PD, nunca automático).
- **Inputs**: os mesmos do Combat Lab, decisão do GD mantida — o botão usado
  determina a ação (CIMA+ATAQUE ≠ CIMA+tiro).
- **Frame data**: igual ao Combat Lab v1.2 (`BalanceCombate.moves`).
- **Energia**: ganhos configuráveis (`BalanceCombate`), regen/custo do
  Especial inalterados. Ver métricas em §Energy.
- **Perfect Dodge**: `PRODUCTION_READY` no sentido opt-in — confirmado por
  teste funcional numa Koliani de produção real (fora do Combat Lab), mas
  **não ligado à campanha** em nenhum nível.

## GOBLIN PILOTO (`GoblinAprendiz`, N1)

- **Comportamento**: `comportamento = "carga"` (já existia na classe,
  reaproveitado como bote telegrafado — não inventado); `piloto_combate_v1`,
  `peso = "leve"`, `pode_ser_lancado = true` só nesta instância.
- **Contrato**: bote (a meio da investida) marca origem `ATAQUE` — pode dar
  Perfect Dodge; contacto de patrulha comum continua `CONTATO`.
- **Anti-juggle**: uma janela de imunidade a novo Launcher depois de aterrar
  do anterior (`_imune_lancamento_t`).
- **TTK medido** (não é meta, é achado): spam ≈ 0,6s, combo intencional ≈
  1,2s. **Muito abaixo do alvo do plano** (4-6s / 3-4,5s) **e o spam mata
  mais depressa que o combo — o oposto do objetivo.** Causa provável:
  `DemonioBase` não tem nenhum sistema de hitstun/poise/anti-spam (o
  `LabInimigo` do Combat Lab tem um dedicado); a vida de produção (58,
  escalada pela dificuldade de N1) é baixa para o dano pleno do combo de
  produção. **Não corrigido silenciosamente** — nem vida nem um sistema de
  poise novo foram ajustados para "passar" o número. Fica marcado como
  achado de balance para decisão do GM.
- **Isolamento confirmado**: nenhum outro goblin/inimigo comum em 4 níveis
  amostra (incluindo o próprio N6) ganhou o contrato.

## GOLEM PILOTO (`EliteGolem`, N6)

- **Peso**: pesado, `pode_ser_lancado = false` — Launcher nunca lança,
  confirmado por teste.
- **Guarda**: `tem_guarda_v1 = true`, `guarda_max_v1 = 100`. Golpe normal
  frontal sem `guard_break` só passa 20% do dano; Cleave/Counter
  (`guard_break`) ignoram-na e esgotam-na sempre, sem loop (fica a 0).
- **Janela de exposição**: a guarda desliga-se quando o golem está
  `esta_vulneravel()` (atordoado, ex. depois de falhar a carga contra uma
  parede) ou a meio da própria investida — reaproveita o mesmo estado que
  já dá CRÍTICO ao combo normal.
- **TTK medido**: spam frontal guardado ≈ 1,5s vs Cleave (quebra guarda) ≈
  0,93s — **o Cleave é claramente mais eficiente, exactamente como o
  desenho pretendia** (ao contrário do achado do Goblin).

## DAMAGE CONTRACT

- **Migrados**: os 20/20 call-sites de produção mapeados no plano (§3):
  8 hazards → `HAZARD_ATAQUE`, 4 inimigos/projéteis com ataque real →
  `ATAQUE`, contacto de corpo (`demonio_base`/`chefe_base`) → `CONTATO`,
  DoT ambiental (`zona_sem_ar`) → `AMBIENTE`. Nada pendente dessa lista.
- Perfect Dodge só reage a `ATAQUE`/`HAZARD_ATAQUE` — confirmado por teste
  (`CONTATO`/`AMBIENTE`/`""` nunca dão PD).

## MOBILE

Os inputs do Core Combat reutilizam ações do Godot já existentes
(`mirar_cima`, `mirar_baixo`, `atacar`, `dash`, `rolar`) — nenhum atalho
novo foi criado. Confirmado estruturalmente em `scripts/controlos_tacteis.gd`:
o eixo vertical do joystick (`mirar_cima`/`mirar_baixo`) e o botão de
ataque (`atacar`) são sinais independentes e simultâneos — CIMA+ATAQUE
(Launcher) e CIMA+tiro (mirar) usam botões diferentes, exactamente como a
decisão fechada do Game Director pedia ("o BOTÃO usado determina a ação").
**Não foi criado nenhum teste de simulação de toque real** (só a análise
estrutural do mapeamento) — se quiseres essa prova extra antes do
playtest, é trabalho em aberto.

## ART DEBT

- `LAUNCHER ART DEBT`, `AIR COMBO ART DEBT`, `DASH ATTACK ART DEBT`,
  `COUNTER ART DEBT` — reusam poses/VFX existentes (`_flash_golpe`,
  `_disparar_vfx_golpe`), sem sprite final.
- `CLEAVE FINAL ART DEBT` — feedback de carga usa `_acender_aura` + som
  `"carrossel"` (existentes), sem sprite final, marcado no `core_combate.gd`.
- `PERFECT DODGE VFX DEBT` — `Label` de debug ("PERFECT DODGE"), sem VFX
  final, marcado no `core_combate.gd`.
- `GUARD BREAK VFX/SFX DEBT` — a guarda do Golem esgota-se silenciosamente
  (sem som/partícula dedicados); reusa `Som.toca("acerto_critico"/"bloqueio")`
  do resto do combate, sem um efeito próprio.

## ENERGY

Medido (janelas de 10s, `ESPECIAL_CUSTO=33`, `REGEN_ENERGIA=12/s`),
`usar_especial()` disparado de verdade sempre que possível:

| Cenário | Energia final (10s) | Especiais em 10s | Especiais/min |
|---|---|---|---|
| passiva (sem input) | 21,8 | 5 | 30 |
| spam básico | 4,0 | 6 | 36 |
| combo intencional | 18,0 | 6 | 36 |
| Launcher + Air | 13,0 | 7 | 42 |
| Pogo | 20,6 | 5 | 30 |
| Perfect Dodge + Counter | 24,8 | 5 | 30 |
| mistura realista | 17,0 | 6 | 36 |

Nenhum cenário de combate ficou abaixo da regen pura — jogar (bem ou mal)
nunca penaliza a Energia face a não fazer nada. "Tempo até 1º Especial"
saiu 0,0s em todos os cenários: **não é bug**, `Koliani._energia` arranca
cheia por omissão (`var _energia := ENERGIA_MAX`) numa instância nova — a
métrica só é reveladora a meio de uma sessão real, não numa Koliani
recém-criada isolada. Regen/custo do Especial não foram tocados.

## REGRESSÕES

Nenhuma encontrada em N1–N6 (nem no resto da campanha) em nenhuma das 20+
corridas completas da suite ao longo desta execução. Nenhum nível
depende das novas ações para alcance — estruturalmente garantido, porque
nenhum nível de campanha chama `ativar_core_combate()` (só a arena de QA
o faz).

## TESTES

- **Suite**: PASS em todas as corridas desde a correção do incidente da
  cache (última corrida oficial de regressão desta execução: 0 falhas,
  save real intacto).
- **CI**: não corrido nesta execução (só local).
- **Save real**: confirmado intacto (SHA256 via `godot_isolado.py`) em
  todas as corridas.

## ARENA

`scenes/qa/ProductionCombatArena.tscn` — abrir com:
```
"/c/Users/paulo/Desktop/Godot_v4.7.2-stable_win64.exe" --path . res://scenes/qa/ProductionCombatArena.tscn
```
Atalhos: `1` Goblin (config real do N1), `2` Golem (config real do N6),
`3` ambos, `R` reset, `P` resumo (consola), `H` ajuda.

## Barreira final

`NEW COMBAT CORE IN PRODUCTION CODE: YES`
`NEW COMBAT ENABLED IN CAMPAIGN: NO`
`GOBLIN PILOT MIGRATED: YES`
`GOLEM PILOT MIGRATED: YES`
`PERFECT_DODGE PRODUCTION_READY: YES (opt-in, não ligado à campanha)`
`MOBILE INPUT BLOCKER: NO (única sobreposição conhecida — CIMA para
Launcher vs. mira — já era decisão fechada do GD, mantida por escolha; sem
conflito novo introduzido pelas Fases 7-11)`
`ENERGY ECONOMY BLOCKER: NO (nenhum cenário medido ficou abaixo da regen
passiva; números documentados acima, não são finais)`
`N1-N6 REGRESSIONS: NO`
`REAL SAVE UNCHANGED: YES`
`FULL SUITE: PASS`
`READY FOR GM PRODUCTION COMBAT PLAYTEST: YES` — com a ressalva explícita
de que o **TTK do Goblin piloto está fora do alvo e o spam domina** (ver
§Goblin); recomenda-se essa decisão de balance antes de propagar o piloto
a mais inimigos.
`N7 STARTED: NO`
`PUSH PERFORMED: NO`
