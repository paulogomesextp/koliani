# Koliani canónica nos níveis 06–100 (Pre-Process 11B)

Data: 17 set 2026 · Base: `origin/claude/n08-preflight-audit` @ `7ff1dbaf`
· Branch: `claude/canonical-koliani-levels` · Worktree limpa:
`C:\Projetos\koliani-canonical-player`.

## Causa

O Golden Set liga-se **cena a cena**. Em `scripts/koliani.gd`,
`usar_prototipo_premium` e `usar_golden_set` são `@export` com `false` por
omissão, e sem elas `_montar_frames` usa o `RIG := "shadowblade"` (atlas
`assets/sprites/pixel/koliani_shadowblade/*`, 51×64, RUN de 5 frames, sem
`morte`). A Execution 9B.3 ligou as flags só em L1–L5. O audit pré-Process 11
(`docs/audits/n08_pre_process11_visual_audit.md`) acrescentou o N08. Nenhum
teste cobria os outros níveis, por isso L6, L7 e L9–L100 mostravam o modelo
antigo sem ninguém dar por isso. A integração da RUN final (`e665da0b`) só
atua dentro de `_montar_golden_set`, que nesses níveis nunca corria.

## Inventário (100 cenas de `EstadoJogo.NIVEIS`)

A tabela completa está em
[`canonical_koliani_levels_06_100/inventario_niveis.csv`](canonical_koliani_levels_06_100/inventario_niveis.csv),
com cena, instância, flags antes, ação e smoke de runtime depois.

| Grupo | Níveis | Instância | Flags antes | Ação |
|---|---|---|---|---|
| Já canónicos | L1–L5, L8 | 1× `Koliani.tscn`, filho da raiz | ambas `true` | nenhuma |
| Sem flags | L6, L7, L9–L100 (94) | 1× `Koliani.tscn`, filho da raiz, só `position` | nenhuma | +2 linhas |

Verificado cena a cena (parse do `.tscn`) e não por amostragem:
- as 100 cenas têm exatamente uma instância de `res://scenes/actors/Koliani.tscn`,
  diretamente sob a raiz;
- nenhuma usa cena herdada, outro player ou outros `usar_*`;
- nenhuma tem CRLF;
- nenhum script fora de `koliani.gd` mexe nas flags em runtime.

### Exceções encontradas

- **L27 `Salao_dos_Espelhos`** referencia também
  `ChefeKolianiSombria.tscn`. É um chefe com script e textura próprios
  (`chefe_koliani_sombria.gd`, `bosses/koliani_sombria.png`), não o rig do
  player. A instância da Koliani é normal e foi corrigida como as outras.
- **`scenes/levels/Level_Test.tscn`** (sala de treino) não pertence à campanha
  e continua sem flags. Fica fora do âmbito 06–100.
- **`scripts/seletor_equip.gd:39`**: a pré-visualização do equipamento usa
  `koliani_shadowblade/idle.png`. É UI e fica fora do âmbito, mas é o próximo
  sítio onde o modelo antigo ainda aparece.

## Solução

Cada uma das 94 cenas recebeu, no nó `Koliani`, exatamente o contrato de L1–L5:

```
usar_prototipo_premium = true
usar_golden_set = true
```

`git diff --numstat` dá `2 0` em todas as 94 cenas, e não mudou mais nada.
**Não** se mexeu em `koliani.gd`, nos defaults globais, em colisão, escala,
offset, SpriteFrames, timing da RUN, física, layout, progressão, chefes ou UI.

Não se mudou o default global (`usar_golden_set := true`) porque isso afetaria
também `Level_Test`, as ferramentas `tools/shot_*`, os testes que instanciam
`Koliani.tscn` sozinha (por exemplo `run_alcance_9h17`) e qualquer cena
futura, sem prova de ausência de regressões. A configuração explícita por
instância é o que L1–L5 já usavam, e o teste de regressão abaixo impede que
um nível novo fique de fora.

### As flags são só visuais (lido no código)

Todas as ramificações de `usar_golden_set`/`usar_prototipo_premium` em
`koliani.gd` são visuais:
- `_montar_frames` / `_montar_golden_set` e `_aplicar_contrato_visual`
  (escala e offset do sprite);
- `_vfx_salto_duplo` e `_vfx_morte`;
- `_flip_sprite` e `_animar` (squash/rotação do sprite no dash/roll);
- `_tint_armadura`;
- a escolha de animação `_anim_locomocao_piloto_5g`. As variáveis
  `_piloto_5g_*` só são lidas dentro dessa função.

## Validação em runtime (amostras)

Harness `valida_canon.gd.txt`: Godot 4.7.2 com janela real, `--fixed-fps 60`,
cena gravada, input simulado (idle → correr → parar → saltar → cair → dash →
morte visual → `recuperar_no_checkpoint`). Cada nível corre **duas vezes com a
mesma sequência**: uma com a cena gravada (canon) e outra com as flags forçadas
a `false` em memória (antigo). Resultado em `validacao_canonica.json`.

| Nível | Golden ativo | Idle | Run | Jump | Dash | Morte | Escala / offset | Colisão | Física canon vs antigo |
|---|---|---|---|---|---|---|---|---|---|
| L01 | sim | golden idle | run_start → run | jump_start → fall → land | `dash` | `morte` golden | (1,1) / (0,−18) | 20×44 igual | Δ 0,0 (ver nota) |
| L05 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |
| L06 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |
| L07 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |
| L08 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |
| L09 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |
| L10 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |
| L30 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |
| L31 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |
| L63 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |
| L100 | sim | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Δ 0,0 |

- **RUN de 10 frames**: `run_final/run_001..010` pela ordem, a 13,333333 fps,
  em loop, nas 11 amostras. No modo antigo a RUN tinha 5 frames da Shadowblade.
- **Física**: x, y, vx e vy relativos ao ponto de partida, frame a frame,
  idênticos (Δ máx. 0,0) com e sem Golden Set, com colisão, máscara e layer
  iguais.
- **Nota L01**: na 1.ª execução deu Δ 0,39 px em y a meio de uma queda. L01 é
  o primeiro nível carregado pelo processo e não foi alterado aqui. Repetido
  com outra ordem (`6,1,1`) deu Δ 0,0 nas duas passagens: é ruído do primeiro
  carregamento, não da flag.
- **Armadilhas de método** encontradas, a guardar para outros harnesses:
  1. `ativar_modo_dev()` põe `indice_nivel = 0`, por isso tem de se definir o
     índice depois.
  2. Entre corridas é preciso repor `level_session`, senão a 2.ª corrida nasce
     noutro sítio.
  3. Um `await frame_post_draw` (screenshot) só numa das corridas atrasa o
     input 1 frame e parece uma diferença de física de 38 px/s. As duas
     corridas têm de fotografar.
- Capturas: `amostras_run_golden.png` (as 11) e `L006/L008/L030/L063/L100_run.png`.

## Testes

| Teste | Resultado |
|---|---|
| **Novo** `tests/test_koliani_canonica_niveis.gd` (ligado ao `run_tests.gd`) | Lê o `SceneState` das 100 cenas de `NIVEIS`. Exige 100 níveis, 1 instância de `Koliani.tscn` por cena e as duas flags `true` |
| Prova de que morde | Com as flags de L63 retiradas, a suite falhou com exatamente 2 falhas (`L063: Koliani sem usar_prototipo_premium…` e `…usar_golden_set…`). Flags repostas |
| Smoke dos 100 níveis (`smoke100.gd.txt`, APPDATA em sandbox) | **100/100 OK**: cada cena carrega e corre 30 frames, e o sprite vivo confirma flags, RUN final 10 fr / 13,333 / loop, idle golden, `morte` e `dash`, escala 1, offset (0,−18) e colisão 20×44 (`smoke100.txt`) |
| `res://tests/run_movement_camera_4a.tscn` | `OK -- targeted Movement + Camera 4A` |
| `res://tests/run_alcance_9h17.tscn` | Corre (exit 0). É uma tabela de envolvente de salto sobre uma sala sintética com `Koliani.tscn` sozinha, independente das flags dos níveis. A geometria dos níveis não mudou |
| Suite completa `tools/correr_testes.ps1` | **`OK -- todos os testes passaram`**. Na base `7ff1dbaf` também passava. Novas falhas: 0 |
| Save real | Intacto: `progresso.json` SHA256 `7b6eeac7…3d76`, igual à cópia feita no início da sessão |

## Confirmação

A física, o movimento, as colisões, a escala, o timing da RUN, o layout, a
progressão e os chefes não mudaram. A única alteração de conteúdo são 188
linhas (2 × 94) de configuração de instância, mais o teste de regressão.
