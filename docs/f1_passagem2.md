# F1 — Passagem 2: mantle + animação de locomoção (25 set 2026)

Decisão do GM: **A + C**. O salto de ~128 px é a nova baseline do vertical slice; os níveis legacy
(congelados) **não** são corrigidos para recuperar o gating antigo e N1–N5 desenham-se para esta física.
Passagem 2 = mantle limitado + landing/brake/turn. **Sem push, sem level design.**
Commits: `d93e0c1b` (mantle) e o seguinte (landing/brake/turn + regressão) — revertíveis à parte.

## MANTLE (`MANTLE ANIMATION ASSET MISSING`)

**O que era:** ao cair rente a um rebordo ela pendurava-se (pés ~58 px abaixo do topo) e o mantle era um
impulso (150, −430) que dependia de manter o botão ≥ 12 ticks; um toque curto falhava em silêncio e
re-agarrava a mesma borda em loop. Era também o que esticava a subida efetiva: salto 128 + mantle → ~200 px.

**O que é agora** (`koliani.gd`: `_detetar_mantle`, `MANTLE_*`): passo de degrau **fixo e determinístico**,
sem estado de pendurada.
- Condições geométricas: (1) parede colada à altura dos pés; (2) topo do rebordo entre **4 e 32 px acima dos
  pés**; (3) 48 px livres por cima do rebordo; (4) chão no ponto de chegada.
- Intenção: a segurar contra a parede (ou "cima"); só a cair ou quase parada (`vy > −30`, para não roubar
  a subida). **Não** depende do apex, do botão de saltar nem de velocidade.
- Execução: 9 ticks (0,15 s) — sobe junto à parede (60 %) e depois avança 14 px para dentro; termina de pé
  e no chão, com `_borda_lock` de 0,3 s. Não falha em silêncio (se as condições não valem, nada acontece) e
  não re-agarra (1 agarre em todas as alturas medidas).
- **Sem animação de mantle:** durante os 9 ticks mostra a pose `borda` (parada). Não inventei arte.
  Marcador: **MANTLE ANIMATION ASSET MISSING**.
- Sem cancelamento (não há razão de gameplay clara para o ter).

Medido (bancada `mantle`, rebordo `lip` px acima do chão, botão de saltar largado a meio):

| Rebordo | Resultado |
|---|---|
| 60–120 px | sobe só a saltar (sem mantle) |
| 140, 150, 155 px | **mantle completa**: 9 ticks, 1 agarre, acaba de pé em cima |
| ≥ 158 px | não sobe (sem mantle, sem re-agarre) |

**Subida máxima salto + mantle: ~155 px** (Passagem 1: ~200; legado: ~140). O bónus do mantle sobre o
salto passa de ~70 px para ≤ 32 px.

## Envolvente de salto — legado / P1 (BEFORE) / P2 (AFTER)

Vão máximo (px), a correr, botão segurado (`f1_envolvente_antes_depois.json`):

| Subida | Legado | P1 | **P2** |
|---|---|---|---|
| 0 (salto simples) | 180 | 230 | **220** |
| 64 | 160 | 210 | **190** |
| 100 | 140 | 200 | **180** |
| 140 | 110 | 180 | **150** |
| subida máx. (simples) | ~140 | ~200 | **~150** (dy 160: impossível) |
| Salto duplo, subida 0 | 300 | 390 | **380** |
| Salto duplo, subida 180 | 230 | 330 | **310** |

O vão horizontal continua ~+22 % sobre o legado (é o salto de 128 px, aceite). O salto duplo continua a
chegar a 200 px de subida (dois saltos de 128).

## Acessibilidade dos níveis (`tools/comparar_alcance_f1.gd`, referência = legado)

| | P1 | **P2** |
|---|---|---|
| Níveis com plataformas novas alcançáveis | 46 (1 725) | **42 (1 370)** |
| Portas alcançáveis só a saltar | 8 | **6** (N15, N16, N20, N46, N49, N60) |
| Plataformas que deixaram de ser alcançáveis | 0 | **0** |
| Redução média de saltos até à porta | −10,3 | −8,7 (máx. −21) |

**Região I (N1–N5): 0 plataformas novas e 0 portas novas em todos** — o N3 (43 novas, porta só a saltar em
P1) voltou a exigir as ajudas; N1 −1 salto até à porta, N2 −8, N4 −7, N5 −8. Os 6 níveis com porta agora
alcançável só a saltar são todos de regiões congeladas. Limites do modelo: os de sempre (estático,
plataformas móveis paradas, sem tetos/hazards/inimigos).

## WALL-JUMP — achado a decidir (não alterado)

O salto de parede (`WALLJUMP` (330, −430), básico, sem habilidade) **não foi tocado**, mas o seu
comportamento mudou com a Passagem 1: bancada `walljump` (parede de 900 px, a segurar contra ela e a saltar
em cada toque):

| | Legado (pré-F1) | P1 | P2 (agora) |
|---|---|---|---|
| Botão premido 14 ticks | 1 salto, 83 px | **15 saltos, 941 px** | **15 saltos, 903 px** |
| Toque de 1 tick | 1 salto, 83 px | 3 saltos, 128 px | 3 saltos, 128 px |

Ou seja: com o controlo aéreo novo (`VIRAGEM_AR` 4500) ela volta à parede depressa e a **cadeia de
wall-jumps sobe uma parede inteira**, sem habilidade. No legado a cadeia não arrancava. É o mesmo impulso
(−430 = 66 px, 52 % do salto de 128) — o que mudou foi o regresso à parede. O GM disse que o **wall-kick
fica fora da Região I**; hoje, na prática, está lá e sobe paredes altas. **Recomendação (não feita):**
limitar o wall-jump à mesma parede/lado até tocar no chão ou noutra parede (regra padrão anti-escalada), ou
exigir a habilidade `escalar_paredes`. Decisão de design → precisa do GM.

## LANDING / BRAKE / TURN (`koliani.gd`, `movimento.gd`; sem arte nova)

| Medida | Antes (P1) | Depois (P2) |
|---|---|---|
| `land` parado | 10 ticks | 10 ticks (mín. ~4 ✔) |
| `land` a correr (direção premida) | 10 ticks a 240 px/s | **5 ticks**, depois `run` |
| Tier de aterragem de um salto normal (637 px/s) | 2 (média) sempre | **1 (leve)** (`ATERRAGEM_MEDIA` 430 → 670, `PESADA` 700 → 735) |
| Queda de 120 px / 250 px | tier 2 / 3 | tier 1 / 3 |
| `run_brake` ao largar a direção | `run` 5 ticks → brake **18** ticks → idle (a física pára aos 6) | brake **6** ticks (coincide com a física) → idle |
| Viragem a correr | `turn` 3 → **`run_brake` 1** → run | `turn` **7** → run (sem flicker) |
| Dash sem input | run 7 → brake 18 | brake 8 |
| `run_start` | não usado | não reintroduzido |

Mudanças: `_pose_aterrar_cancelavel()` (≥ 4 ticks de `land`, depois quem se mexe cancela);
`_anim_locomocao_piloto_5g` com brake enquanto desliza sem input e turn até ir a 120 px/s no sentido novo;
`run_brake` 20 → 45 fps e `turn` 12 → 30 fps (mesmos frames golden, só a cadência). Nada de frames
legacy nem arte nova.

## Regressão
- `tools/correr_regressao_movimento.ps1`: **0 falhas** (agora com mantle, brake, turn, land, tier); no
  código anterior à Passagem 2 falha em 7 pontos (prova de que morde).
- Suite completa `OK`; 8 verificadores do CI + `verifica_spawn_livre`, `run_region02_wind_shapes`,
  `run_glide_region02`, `run_movement_camera_4a`, `run_wind_system`: todos exit 0. Save real intacto.
- Bug de método apanhado: os blocos de teste do mantle sobrepunham-se (o de 100 px da arena ficava por baixo
  do de teste) e o sensor do rebordo agarrava o topo errado — testar cada altura com um bloco isolado.

## Por decidir / por fazer
1. **Wall-jump** (acima): limitar a cadeia ou não.
2. Animação de mantle (asset em falta).
3. Câmara em queda (0,38 s, barra 0,6 s) — recomendação da Passagem 1 continua por fazer.
4. Level design N1–N5 para a nova envolvente — **não iniciado**, como pedido.
