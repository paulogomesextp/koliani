# Reformulação "pegada Dead Cells" — plano faseado

> Decisão do Paulo (1 set 2026): **passe de feel + arte** — mantém-se a
> campanha de 30 níveis, história, 30 chefes e os saves. Não é pivot
> roguevania. Base de arte: eu escolho por região o que casar melhor com
> `assets/branding/key_art.png` e mostro screenshots antes de fixar.
> Sprite da Koliani: adotar um rig pronto (Magic Cliffs / Gothicvania) e
> recolorir (roxo/luar).
>
> Referência: speedrun WR de Dead Cells (fresh file 8:15). O que se tira:
> momentum sem paragens, roll-cancel, biomas altos e ramificados, salas
> montadas de "chunks" feitos à mão, sem dano de queda, agarrar borda,
> agressão = ritmo.

## Fase 1 — Feel do movimento (código, sem assets)

- [x] **Agarrar a borda / mantle** (`koliani.gd` `_detetar_borda` +
  `_borda*`): a cair rente a um rebordo, agarra-se; saltar/↑ sobe, ↓ larga.
  Perdoa saltos por um triz nas torres da jornada. **Falta playtest** dos
  números (`BORDA_*`, `BORDA_MANTLE`).
- [ ] **Roll-cancel**: iniciar rolamento cancela o recovery do ataque e a
  lag de aterragem. `Movimento.pode_rolar` + estados de `koliani.gd`.
- [ ] **Pogo com a espada**: ataque para baixo no ar → ressalta ao acertar
  em inimigos **e** em serras/espinhos/guilhotinas (NÃO no líquido mortal).
  Precisa de um grupo `"pogavel"` nos hazards (serra/espinhos/guilhotina/
  pendulo/fogo). Reaproveita o bloco do stomp.
- [ ] **Coyote nas paredes + wall-jump puro** (sem precisar da habilidade
  `escalar_paredes` para o chute básico).
- [ ] Afinar aceleração/atrito para o "nunca pára" (rever `movimento.gd`
  `ACEL_AR`/`ACEL_CHAO`, corte de salto).

## Fase 2 — Jornada montada de salas feitas à mão

`gerador_corredor.gd` deixa de "desenhar" geometria e passa a **montar
peças** (`res://scenes/rooms/*.tscn`): cada peça é um troço desenhado à mão
com entrada/saída marcadas (`Marker2D` "entrada"/"saida_*"), tags de bioma
e de dificuldade, e slots de inimigo/hazard/decoração. O gerador escolhe
peças compatíveis e encaixa-as (como o Dead Cells). Mantém-se a regra de
ouro (subida ≤ `SUBIDA_MAX`), o líquido mortal por baixo, o boss no fim.

- [ ] esquema da peça (`RoomChunk` script + convenção de markers)
- [ ] ~8-12 peças por "tom" (corredor, torre, poço, arena-pausa, segredo)
- [ ] gerador: grafo de encaixe + validação de alcance headless
- [ ] atalhos: 1-2 `Portal` "de retorno" por jornada (teletransporte)

## Fase 3 — Arte de ambiente por região

Fontes já em `assets/sprites/incoming/` (nada para descarregar):
Ansimuz **Gothicvania** (church/swamp/town) + parallax **Cold Corridors /
Caverns / Rocky Pass / Mountain Dusk**, **Magic Cliffs** gamekit,
**LuizMelo** inimigos. Copiar o usado para `assets/sprites/pixel/` e
creditar em `CREDITS.md`.

- [ ] I Floresta → Gothicvania Swamp + parallax_forest
- [ ] II Prisão → gothicvania church + Cold Corridors
- [ ] III Torres → Mountain Dusk + Rocky Pass
- [ ] IV Catacumbas → Caverns + church
- [ ] V Cidade → Gothicvania town
- [ ] VI Castelo → church (escuro) + brasas
- [ ] `Atmosfera.tscn` recolor por bioma para casar com o key_art

## Fase 4 — Rig da Koliani

- [ ] adotar sheet do **Magic Cliffs** (idle/run/jump/fall/attack/
  jump-attack/crouch-attack/hurt/death, 128x96) OU Gothicvania church
- [ ] recolorir para a Koliani (bandana, capa roxa esfarrapada, lâmina
  roxa, fumos roxos) — shader de paleta
- [ ] ligar a `koliani.gd` `_KOLI_ANIMS` (mapear estados novos: borda,
  pogo)
- [ ] afinar hitbox/pés à nova métrica

## Fase 5 — Economia / loadout (leve, não roguelite)

- [ ] as gemas viram "essência" com contador visível
- [ ] 2 slots de skill trocáveis num banco entre níveis (já há
  `EstadoJogo` habilidades) — sem perder o esquema de progressão fixa

---

Progresso detalhado em `docs/progresso_agente.md`.
