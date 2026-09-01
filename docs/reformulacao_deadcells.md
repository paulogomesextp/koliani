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
- [x] **Roll-cancel**: iniciar rolamento corta o recovery do ataque
  (`koliani.gd`, ramo do `rolar`). Encadeia ataque→rolar→ataque.
- [x] **Pogo em hazards**: a cair em cima de uma `Serra`/`Espinhos` (grupo
  `"pogavel"` + layer 6), a Koliani ressalta em vez de levar o golpe
  (raycast para baixo dos pés; i-frames apanham o toque). **Falta**
  estender a `Guilhotina`/`PenduloLamina` (geometria da lâmina fora do
  root — precisa detetar pela Area2D da lâmina). Líquido mortal nunca é
  `"pogavel"`.
- [x] **Wall-jump básico** (`koliani.gd`): no ar, encostada a uma parede e
  a segurar contra ela, `saltar` chuta para fora (`WALLJUMP`), sem gastar
  o salto do ar. Não precisa de `escalar_paredes`.
- [ ] Afinar aceleração/atrito para o "nunca pára" (rever `movimento.gd`
  `ACEL_AR`/`ACEL_CHAO`, corte de salto). **Falta playtest** dos números
  do agarrar-borda / wall-jump / pogo.

## Fase 2 — Jornada montada de peças (ritmo + ramificação)

Em vez de reescrever tudo para `.tscn` à mão, o `gerador_corredor.gd`
evoluiu para **encadear "câmaras" tipo peça** (funções `_f_*` com
entrada/saída declaradas em altura, regra de ouro `SUBIDA_MAX`).

- [x] **Ritmo tensão/alívio** (`_camaras`, `_pos_intenso`): a seguir a uma
  câmara puxada (vertical, guilhotinas, serras, fogo, quebra) entra sempre
  um `_f_descanso` — plataforma larga e LIMPA + checkpoint + vista. Também
  força descanso a cada 4.ª câmara.
- [x] **`_f_forquilha`**: o caminho abre em dois — rota ALTA curta com
  perigos, rota BAIXA longa e segura — e volta a juntar-se. Ambas as
  pontas alcançam o reencontro (de cima desce-se, de baixo ≤ 1 salto).
- [x] **Estrutura em 3 actos** (arco de bioma tipo Dead Cells): `prog`
  (0→1 pela jornada) + `intens` — intro suave (`prog<0.28`, ×0.35→1) →
  meio a apertar (`0.28–0.82`, ×1→1.28) → alívio antes da rampa do chefe
  (`prog>0.82`, ×0.5, quase só `descanso`). `intens` escala perigos,
  inimigos e plataformas móveis.
- [x] **Assinatura de região** (`ASSINATURA`): no acto do meio, ~30% de a
  câmara ser a "cara" do bioma (Floresta=trampolim, Prisão=guilhotinas,
  Torres=vento, Catacumbas=gruta, Cidade=impulso, Castelo=fogo), se a
  dificuldade já a libertou.
- [ ] mais "tons" de peça: gruta-labirinto, arena de combate fechada,
  alcove-segredo (recompensa fora do caminho), corredor apertado
- [ ] atalhos: 1-2 `Portal` "de retorno" por jornada (teletransporte)
- [ ] (talvez) mover as peças mais estáveis para `scenes/rooms/*.tscn`

## Fase 2b — Inimigos com ameaça própria (combate Dead Cells)

- [x] `DemonioBase.comportamento` (`@export_enum`): **saltador** (salta em
  arco na direção da Koliani quando perto) e **carga** (telegrafa — pára e
  estremece — e arranca a 3.4× a velocidade, sem virar; recupera na
  parede). O gerador atribui-os a partir de `_dif > 0.15` (não nos
  voadores). Método `_dir_koliani_perto(alcance)` (o nome `_dir_para_koliani`
  já existe no `ChefeBase`). **Falta playtest** dos números.
- [x] **voador** (aplicado aos "olho" pelo gerador): sem gravidade, paira à
  volta da origem e MERGULHA na Koliani (direção fixada no arranque,
  recupera na parede/chão).
- [x] **escudeiro** (dif > 0.35): golpe de FRENTE bate no escudo (só
  "clinc"); pisão e golpes pelas costas passam. Anda mais devagar.
- [ ] **trepador de parede/tecto** que se deixa cair.
- [ ] telegrafos mais legíveis (usar mais o campo `anticipacao`).

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
