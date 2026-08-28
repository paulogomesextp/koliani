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
| `atacar` | J | botão direito |
| `dash` | K | botão direito |
| `rolar` | seta baixo | (por mapear no HUD) |

`scenes/ui/HUD.tscn` tem os `TouchScreenButton` com a `action` certa; o
Godot injeta a InputAction sozinho. `controlos_toque.gd` só esconde o HUD
quando se joga com teclado.

## Movimento (`scripts/movimento.gd` -- lógica pura, testada)

- Gravidade 1400, queda máx. 1100.
- Corrida: vel. 240, aceleração 2000 no chão / 1200 no ar.
- Salto: força 470, **coyote time** 0.10s, **jump buffer** 0.12s,
  **corte de salto** (largar o botão mantém 45% da vel. vertical).
- `Movimento.passo(estado, direcao, saltar_premido, saltar_a_segurar,
  no_chao, dt)` devolve o estado atualizado. Sem nós, sem física do Godot
  -- por isso dá para testar headless.

`scripts/koliani.gd` liga isto ao `CharacterBody2D` real e acrescenta:

- **Dash**: vel. 620, duração 0.16s, recarga 0.55s, i-frames durante o dash.
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
- inimigos (`DemonioBase` ou derivados);
- 0+ `Checkpoint`;
- **1 `Porta`** para o mundo seguinte (a última porta termina a campanha).

`Level_Test.tscn` é o exemplo mínimo. Níveis a sério devem usar
`TileMapLayer` para a geometria em vez de `ColorRect`.

## Progressão (`scripts/estado_jogo.gd`)

Autoload `EstadoJogo`. Guarda em `user://progresso.json`:
`vidas`, `indice_nivel`, `checkpoint`, `habilidades[]`, `pistas[]`.

- `NIVEIS` -- lista ordenada de cenas = a campanha.
- `avancar_nivel()` -- passa ao seguinte e limpa o checkpoint.
- `desbloquear_habilidade(id)` / `tem_habilidade(id)` -- para `koliani.gd`
  ligar habilidades novas (salto duplo, dash aéreo, partir paredes...).
- `registar_pista(id)` -- chamado pelas portas / objetos de mundo.

## Por fazer (lista viva)

- Sprites a substituir os `ColorRect`.
- `TileMapLayer` + tileset para geometria de nível.
- Ecrã de diário das pistas.
- Habilidades desbloqueáveis ligadas ao `koliani.gd`.
- Chefe por mundo.
- Cena de final.
- Som e "juice" (shake, hitstop, partículas).
- Mapear `rolar` no HUD de toque.
