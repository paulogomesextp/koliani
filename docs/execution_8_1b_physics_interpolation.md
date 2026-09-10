# Execution 8.1B — Physics Interpolation / Cadence Fix

Estado: **TECHNICALLY VALIDATED / GAME MASTER CADENCE REVIEW REQUIRED**.

Data: 10 de setembro de 2026. Segue-se a
[`execution_8_1_windows_performance_gate.md`](execution_8_1_windows_performance_gate.md),
que provou que o problema era cadência e não custo.

## O que mudou

`physics/common/physics_interpolation = true`. A física continua a **60 Hz**.
Não se tocou em nenhuma constante de movimento, aceleração, gravidade, salto,
coyote time, jump buffer, dash, combate, câmara, colisões ou geometria.

O motor passa a interpolar a transformação **desenhada** entre dois ticks de
física, portanto num painel de 165 Hz o movimento avança em todos os frames
em vez de saltar de 60 em 60.

## Prova de que funciona

A sonda da 8.1 não servia aqui: `global_position` devolve a transformação da
física, não a interpolada, por isso ficava cega à melhoria. A verificação
passou a ser feita sobre a **imagem realmente desenhada**, com o gravador de
filme do motor (`--write-movie` + `--fixed-fps 165`), medindo a diferença de
luminância entre frames consecutivos ao longo de 200 frames do Nível 1 em
corrida:

```
                     p50      p90    desvio   p90/p50
INTERPOLAÇÃO OFF    0.078    0.327   0.117     4.19x
INTERPOLAÇÃO ON     0.071    0.146   0.048     2.06x
```

Sem interpolação a distribuição é **bimodal**: a maioria dos frames quase não
muda (o mundo não andou) e uma minoria muda muito (o mundo deu um solavanco).
É essa assimetria — p90 4,2× acima da mediana — que se lê como engasgo.

Com interpolação a distribuição fica **uniforme**: o desvio-padrão cai
**59 %** e o p90 cai 55 %. O movimento passou a ser distribuído por todos os
frames em vez de chegar aos solavancos.

## Auditoria de descontinuidades (`reset_physics_interpolation`)

Sítios auditados no caminho real da campanha e o que se decidiu:

| Sítio | Decisão |
|---|---|
| `koliani.gd` respawn no checkpoint | **RESET** — é o teletransporte mais longo do jogo |
| `koliani.gd` agarrar o rebordo (`_borda`) | **RESET** — salta em Y para o nível do rebordo |
| `koliani.gd` recuperação de fosso (modo dev) | **RESET** |
| `portal.gd` saída pelo portal parceiro | **RESET** — descontínuo por definição |
| `koliani.gd` `_passo_gancho` (baloiço) | sem reset — é movimento **contínuo** por tick |
| `chefe_base._prender_na_arena` | sem reset — é um **clamp** por frame, não um salto |
| Morte / troca de nível | sem reset — a cena é recriada, e nós novos já nascem sem histórico |
| Arranque de nível, tochas, checkpoints, plataformas | sem reset — construídos no `_ready` |

Regra seguida: reset **só** onde há salto de posição de um nó que já estava na
árvore. Não foi posto às cegas.

## Exceções de `_process` (`PHYSICS_INTERPOLATION_MODE_OFF`)

Nós cujo transform é animado no `_process` (a 165 Hz) não podem ser
interpolados: seriam reamostrados a 60 Hz e ficariam com um tick de atraso.

| Ficheiro | Nó | Porquê |
|---|---|---|
| `demonio_base.gd` | `$Sprite`, `Corpo`, `Anim` | balanço/respiração no `_process` **e** viragem por `scale.x = ±1` |
| `koliani.gd` | `$Sprite` | viragem por `scale.x = ±1` |
| `atmosfera.gd` | `Poeira` | colada ao centro do ecrã todos os frames |
| `luz_seguidora.gd` | o próprio nó | persegue a Koliani no `_process` |
| `zona_escuridao.gd` | `_buraco` | idem |
| `agua_venenosa.gd` | `Superficie`, `Rebordo`, `Faixa` | onda animada no `_process` |
| `plataforma_quebra.gd` | o próprio nó | treme e cai no `_process` |
| `portal.gd` | `Anel`, `Nucleo` | rodam no `_process` |
| `trampolim.gd` | `_almofada` | comprime no `_process` |
| `coletavel.gd` | `$Visual` | flutua no `_process` |

**A viragem era o risco escondido.** `_sprite.scale.x = ±1` interpolado faria
o sprite passar por zero durante um tick — esmagava-se de cada vez que a
Koliani ou um bicho se virava. Como o modo é herdado, desligar no `$Sprite`
chega para todo o visual por baixo; o corpo continua interpolado, por isso
**anda suave e vira seco**.

Como `ChefeBase extends DemonioBase`, a correção do `demonio_base.gd` cobre
todos os inimigos **e** todos os chefes de uma vez.

## Câmara

**Não foi retocada. Nenhuma constante mudou.**

A câmara é filha da Koliani e escreve apenas em `offset` — que não é um
transform de `Node2D` e portanto não é interpolado. A âncora dela (a Koliani)
passou a ser interpolada, logo a câmara herda a suavidade de graça. O
`passo_seguimento` usa `1 - exp(-k*dt)`, que é independente da taxa de frames,
por isso o look-ahead responde exatamente como antes. Não há duplo
amortecimento.

O motor avisa em cada carregamento:

```
Camera2D overridden to physics process mode due to use of physics interpolation.
```

É esperado e benigno: o Godot passa o callback interno da `Camera2D` para
física, e depois interpola a transformação dela. O efeito prático é o screen
shake ficar amostrado a 60 Hz antes de ser interpolado — ou seja um pouco
menos áspero. **Isto é uma mudança de textura do tremor e é matéria de
revisão do Game Master**, não um defeito.

## Resultados

Suite completa: **PASS** (inclui `test_movimento_camera_4a`, que é o gate do
movimento/câmara congelados). Jornada 1–100: **PASS**. Alcance: **PASS**.
Execution 7 targeted (combate/progressão, inimigos, L1–L5, boss): **PASS**.
Combate runtime (hitbox, deduplicação, aéreo, cancel): **PASS**.

`Koliani.exe` reexportado e corrido: **165 FPS estáveis, zero erros no log,
zero quedas** na sessão de 40 s (antes da correção havia quedas esparsas).

### Nota sobre o tamanho do build

O EXE passou de **377 MB para 162 MB** e o `index.pck` da Web de **268 MB
para 53 MB**. Não se apagou nada: o build anterior foi feito a partir da
árvore de trabalho do Paulo, que tem master packages e assets locais **não
rastreados**, e o `export_filter="all_resources"` varria-os para dentro do
pacote. Este build sai só do source commitado, portanto é reproduzível. Se
algum desses assets locais for para ser jogo, tem de ser commitado primeiro.

## Backlog conhecido (fora desta execução, por instrução)

- **Recarga de cena ~150 ms: OPEN.** Continua a congelar em cada morte e
  troca de nível. Precisa de carregamento fora da thread principal e/ou de
  repartir o `Atmosfera._gerar_parallax()` por frames.
- **Compilação de pipelines à primeira utilização: OPEN.**
  `shader_baker/enabled` continua ausente dos presets de export.

Não se mexeu em nenhum dos dois, como pedido.

## O que falta

**GAME MASTER CADENCE REVIEW REQUIRED.** A validação é visual e é sua: correr
o `Koliani.exe` e ver se o movimento agora lê como suave — corrida, saltos,
mudanças rápidas de direção, Dash, combate, câmara, checkpoint, morte e
reaparecimento, L3, L5, arena e Coração Putrefacto, projéteis e VFX.

Dois pontos onde vale a pena olhar com atenção, por serem os que a
interpolação toca de lado:

1. o **reaparecimento** no checkpoint (o reset está lá, mas confirme que ela
   aparece já no sítio, sem risco);
2. a **textura do screen shake**, agora amostrado a 60 Hz.
