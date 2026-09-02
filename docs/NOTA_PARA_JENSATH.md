# Nota para o Jensath — sessão do Paulo, 2 set 2026

> Pedido do Paulo: deixar-te isto quando entrares no projeto. Podes apagar
> depois de leres. (Detalhe completo em `docs/progresso_agente.md` e nos
> commits `ca56547`..`85e19bb`.)

## O que mudou (grande)

### 1. Os 30 níveis foram REFEITOS À MÃO
Os 29 níveis rejogáveis (Regiões I-VI, menos o Trono n30) passaram a
**`corredor = false`** na cena raiz — **deixaram de correr a jornada
procedural** (`gerador_corredor.gd`). Cada `scenes/levels/*.tscn` é agora
uma **sala desenhada**: bifurcação (rota alta/baixa ou esq/dir), 1 elite
na ledge central, mecânica-assinatura da região tecida na sala, poça
mortal por baixo, recompensa de habilidade no caminho crítico, chefe +
Porta no fim.

- **Verificação obrigatória ao editar um nível à mão:**
  `godot --headless --script res://tools/verifica_alcance.gd -- <cena>`
  → crivo estático de alcance (grafo "dá para saltar de A→B", vão ≤210,
  subida ≤118). Diz se a Porta é alcançável + lista plataformas órfãs.
  Regras: gaps sólidos ≤200 px, subidas ≤110 px. Plataformas MÓVEIS
  (`PlataformaCorrente`, `TumuloElevador`, `CorrenteAr`) não contam no
  grafo → tem de haver sempre um caminho sólido a par.
- `tools/bot_gauntlet.gd` já **não** serve para estes níveis (em modo dev
  a água não mata → o bot fica preso e dá softlock falso).
- `verifica_jornada.gd` já reconhece `corredor = false`.
- A jornada procedural + o `PERFIL` de forma continuam no código mas **não
  correm em lado nenhum** (todos os níveis têm `corredor = false`). Pode
  retirar-se se o Paulo confirmar.

### 2. Combate — núcleo "pegada Dead Cells" (`demonio_base.gd`, `koliani.gd`)
- Estados no inimigo: `queimar()` (DoT que alastra), `sangrar()` (acelera
  a mexer-se), `atordoar()` → `esta_vulneravel()`.
- **Críticos** (×1.7 nos comuns, ×1.5 nos chefes): alvo vulnerável /
  golpe logo a seguir a um rolamento / golpe pelas costas.
- **`receber_dano` ganhou um 3.º parâmetro `critico := false`** — em
  `demonio_base.gd`, `chefe_base.gd` E nos 30 `chefe_*.gd` concretos. Se
  criares um chefe novo, a assinatura tem de ser
  `func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false)`.
- Isca-e-castiga: cada investida comprometida do inimigo que falha abre
  janela de atordoamento.

### 3. Fixes desta sessão
- Pisão nos inimigos: pulo automático e mais ALTO (via `aplicar_impulso`,
  imune ao corte de salto).
- Fogueiras dos checkpoints: `_pousar()` mais robusto — assentam sempre em
  cima da plataforma (não enterradas nem a flutuar).

## O que está estável vs por playtestar
- **Estável:** estrutura dos 30 níveis (alcance verificado), o núcleo de
  combate, os fixes acima. `tests/run_tests.gd` verde.
- **Por afinar (a olho):** espaçamentos e dificuldade dos 30 níveis;
  timing das `PlataformaRitmada`/`Espectral`/`ParedeMovel`/guilhotinas;
  paletas por região; o mismatch de resolução rig/fundos/props.

## Ferramentas novas
- `tools/verifica_alcance.gd` — crivo de alcance dos níveis à mão.
