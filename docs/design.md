# Koliani -- design de jogo

> Documento vivo. Referência de mecânica para o agente `gaming`. Onde isto
> e o código não baterem certo, **o código manda** -- corrige aqui.

## Pilares

1. **Movimento que sabe bem ao toque.** Um platformer de ação só resulta
   se andar/saltar/dash forem responsivos num ecrã de telemóvel. É o
   primeiro a acertar, antes de conteúdo.
2. **Progressão com história.** Não é roguelite: o jogador avança mundo a
   mundo, guarda progresso, e fica mais forte com habilidades
   permanentes. Cada mundo entrega uma pista sobre a mãe.
3. **Pegada Dead Cells.** Combate rápido e legível, inimigos que
   telegrafam, "juice" (screen shake curto, hitstop leve, partículas).

## Controlos

Mapa de input em `project.godot` (nomes em português):

| Ação | Teclado (teste) | Toque |
|------|-----------------|-------|
| `mover_esquerda` / `mover_direita` | setas / A D | d-pad esquerdo (HUD) |
| `saltar` | Espaço / seta cima | botão direito-baixo |
| `atacar` | J | botão de ação (cima) |
| `dash` | K | botão de ação (baixo) |
| `rolar` | seta baixo | botão de ação (esquerda) |
| `diario` | I / Tab | botão canto sup. direito |

`scenes/ui/HUD.tscn` tem os `TouchScreenButton` com a `action` certa; o
Godot injeta a InputAction sozinho. `controlos_toque.gd` só esconde o HUD
quando se joga com teclado.

## Movimento (`scripts/movimento.gd` -- lógica pura, testada)

- Gravidade 1400, queda máx. 1100.
- Corrida: vel. 240, aceleração 2000 no chão / 1200 no ar.
- Salto: força 470, **coyote time** 0.10s, **jump buffer** 0.12s,
  **corte de salto** (largar o botão mantém 45% da vel. vertical).
- **Salto duplo**: `Movimento.passo(..., saltos_max)` -- `saltos_max` = quantos
  saltos se encadeiam no ar antes de tocar no chão (1 normal, 2 com a
  habilidade `salto_duplo`). Sair da plataforma a andar e deixar o coyote
  expirar gasta o "salto do chão" (o 1.º salto no ar já é o 2.º).
- `Movimento.passo(estado, direcao, saltar_premido, saltar_a_segurar,
  no_chao, dt, saltos_max := 1)` devolve o estado atualizado. Sem nós, sem
  física do Godot -- por isso dá para testar headless.

`scripts/koliani.gd` liga isto ao `CharacterBody2D` real e acrescenta:

- **Dash**: vel. 620, duração 0.16s, recarga 0.55s, i-frames durante o dash.
  Só do chão, exceto com a habilidade `dash_aereo`.
- **Rolamento** (`rolar`): vel. 360, duração 0.30s, recarga 0.45s, i-frames
  toda a duração; só do chão, não permite atacar/virar a meio. Estado
  exclusivo (rolamento > dash > movimento normal). Predicado testável:
  `Movimento.pode_rolar(...)`.
- **Ataque leve**: dura 0.18s, ativa a `Area2D` `HitboxAtaque` à frente da
  Koliani; dano 25.
- **Dano recebido**: 0.6s de i-frames; ao chegar a 0 de vida ->
  `EstadoJogo.perder_vida()` e recarrega a cena (reaparece no checkpoint).
  Sem vidas -> `EstadoJogo.reiniciar_campanha()`.

Números são ponto de partida -- afinar com o jogo a correr.

## Camadas de física (`project.godot > layer_names`)

| Bit | Nome | Quem |
|-----|------|------|
| 1 | `mundo` | chão e plataformas (`StaticBody2D`) |
| 2 | `jogador` | corpo da Koliani |
| 3 | `inimigos` | corpo dos demónios |
| 4 | `hitbox_jogador` | `Area2D` de ataque da Koliani |
| 5 | `triggers` | portas, checkpoints |

- Koliani body: layer 2, mask 1.
- Demónio body: layer 3 (=4), mask 1. `AreaContacto` (Area2D): mask 2
  (deteta a Koliani) -> `receber_dano`.
- `HitboxAtaque` da Koliani: layer 8, mask 4 (deteta corpos de inimigos).
- Porta / Checkpoint: layer 16, mask 2.

## Estrutura de nível

Um nível é uma `scene` `Node2D` com:
- geometria (`StaticBody2D` + `CollisionShape2D` + visual) na layer `mundo`;
- a Koliani instanciada no ponto de spawn (ou no checkpoint guardado);
- inimigos (`DemonioBase` ou derivados) e, no fim, o **chefe** do mundo;
- 0+ `Checkpoint`;
- 0+ `Coletavel` (pistas/habilidades);
- **1 `Porta`** para o mundo seguinte (a última porta termina a campanha).
  Fica **selada** (`monitoring = false`) até o chefe cair -- ver
  `scripts/nivel_com_chefe.gd` (script no nó raiz do nível que liga
  `Chefe.derrotado` à porta).

`Level_Test.tscn` é o exemplo mínimo (fora da campanha -- sala de treino).
`Floresta_Putrefata.tscn` é o **mundo 1** e serve de molde: geometria
`StaticBody2D` com "lip" claro no topo (look de tile Dead Cells),
`ParallaxBackground` de silhuetas, `CanvasModulate` escuro +
`PointLight2D` a recortar a luz, e uma `CanvasLayer` de vinheta. Níveis a
sério ainda devem migrar para `TileMapLayer` quando houver tileset.

### Coletáveis (`scripts/coletavel.gd`, `scenes/actors/Coletavel.tscn`)

`Area2D` na layer `triggers`. `@export pista_id` e/ou `@export
habilidade_id`: ao tocar na Koliani regista a pista / desbloqueia a
habilidade em `EstadoJogo` e desaparece. Se já foi apanhado numa sessão
anterior (já está no save), nem aparece.

### Montagem de luz / ambiente (por mundo)

Objetivo: sentir Dead Cells com placeholders. Cada nível traz:
`CanvasModulate` (tom do mundo, ~0.45 de brilho), `ParallaxBackground`
com 2 camadas de silhuetas, `PointLight2D` em pontos de interesse
(checkpoint e porta a magenta; luzes de ambiente na cor do mundo),
`CanvasLayer` de vinheta radial. Reaproveitar os `sub_resource`
`Gradient`/`GradientTexture2D` (radial) para as luzes.

## Progressão (`scripts/estado_jogo.gd`)

Autoload `EstadoJogo`. Guarda em `user://progresso.json`:
`vidas`, `indice_nivel`, `checkpoint`, `habilidades[]`, `pistas[]`.

- `NIVEIS` -- lista ordenada de cenas = a campanha.
- `avancar_nivel()` -- passa ao seguinte e limpa o checkpoint.
- `desbloquear_habilidade(id)` / `tem_habilidade(id)` -- `koliani.gd` já lê
  `salto_duplo` e `dash_aereo`; falta `partir_paredes`.
- `registar_pista(id)` -- chamado pelas `Porta` e pelos `Coletavel`. O
  texto legível de cada id está em `scripts/diario_pistas.gd`.

## Por fazer (lista viva)

- Sprites CC0 a substituir os `ColorRect` (Koliani, demónios, tiles da
  floresta, folhagem de parallax) -- ver dúvidas no fim do README.
- `TileMapLayer` + tileset para geometria de nível.
- ~~Ecrã de **diário das pistas**~~ -- feito (`scenes/ui/Diario.tscn` +
  `scripts/diario.gd`; textos em `scripts/diario_pistas.gd`). Falta arte
  e afinar o layout com o jogo a correr.
- ~~Habilidades desbloqueáveis ligadas ao `koliani.gd`~~ -- feito para
  `salto_duplo`; falta `dash_aereo`, `partir_paredes`.
- **Chefe** por mundo. Feito o do mundo 1 (`scripts/chefe_floresta.gd`,
  `scenes/actors/ChefeFloresta.tscn`): FSM patrulha -> telegrafo -> investida
  -> recupera, emite `derrotado`. `scripts/nivel_com_chefe.gd` sela a porta
  até ele cair. Faltam chefes dos mundos 2-4 e afinar tempos/dano.
- Cena de final a sério (o `main.gd._ao_fim_da_campanha` é um cartão).
- Som (sem áudio ainda). **Juice** parcial feito: screen shake
  (`scripts/tremor.gd` puro + `camera_tremor.gd` na câmara), hitstop de
  tempo real (`Koliani._hitstop`), `CPUParticles2D` de impacto e de
  aterragem. Falta afinar valores com o jogo a correr e partículas nos
  demónios.
- Mapear `rolar` no HUD de toque (`scenes/ui/HUD.tscn`).
- Mundos 2-4 (`Prisao_dos_Condenados`, `Torres_Esquecidas`,
  `Castelo_de_Zeriko`) -- usar `Floresta_Putrefata.tscn` como molde.
