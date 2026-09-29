# F1 — Passagem 1: física / game feel core (25 set 2026)

Aprovada pelo GM a partir de `docs/f1_movimento_diagnostico.md`. **Sem push.** Passagem 2 (mantle +
animação) **NÃO iniciada**: há um sinal de acessibilidade que a regra do GM manda reportar antes (ver
"Regressões e sinais"). Números: `docs/qa/f1_movimento/` (`f1_antes_passagem1.json`,
`f1_depois_passagem1.json`, `f1_envolvente_antes_depois.json`, `f1_alcance_100_niveis.json`).

## O que mudou (código)

| Onde | Antes | Depois |
|---|---|---|
| `Movimento.FORCA_SALTO` | 470 | **584** |
| Jump cut | ×0,45 **a cada tick** | ×0,45 **uma vez** por salto (flags `salto_subindo`/`corte_feito`); a subida por forças externas (corrente de ar) mantém o corte por tick de antes |
| Apex | sem | `APEX_LIMIAR` 60 px/s, `APEX_GRAVIDADE` 0,5 — só num SALTO (`em_salto`), não numa queda de rebordo |
| `VEL_MAX_QUEDA` | 1100 | **750** (sem fast-fall) |
| `ATERRAGEM_PESADA` | 760 | 700 (com teto 750 o tier 3 deixava de existir) |
| `ACEL_AR` / `DESACEL_AR` / `VIRAGEM_AR` | 1350 / 1050 / 1800 | **1440 / 1300 / 4500** |
| Dash | velocidade 1 tick depois do input; 620 a decair ~17 ticks (82 px de deslize) | velocidade **no mesmo tick**; mesmo burst (10 ticks a 620); fim por curva de ~2 ticks até `VEL_CORRIDA` (`DASH_SAIDA_DESACEL`) |
| Roll | 360 px/s, recarga 0,45 s, velocidade 1 tick depois | **320 px/s**, recarga 0,5 s, velocidade no mesmo tick, **recuperação** 0,2 s: desce por curva (4500 px/s²) até 40 px/s no chão (`ROLAR_REC_*`) |
| `STOMP_RESSALTO` | `FORCA_SALTO × 0,7` (329) | fórmula **inalterada** (0,7) → 409 px/s |

Nota: o 1.º valor de `ACEL_AR` foi 1750 e **partiu** `tests/test_glide_region02.gd` (caso H): a Região II
tem rajadas contra de 1500 (`A_Cela_Zero`) e 1600 (`Corredor_das_Execucoes`) que só "encalham" quem segura
em frente enquanto `ACEL_AR` < rajada < `VIRAGEM_AR`. Ficou 1440 (9 ticks, dentro do alvo de 8–10) e a
restrição está escrita no comentário da constante.

## Métricas BEFORE → AFTER (bancada, 60 Hz)

| Medida | Antes | Depois | Alvo GM |
|---|---|---|---|
| Altura do salto (segurado) | 82,9 px | **127,5 px** | 125–135 ✔ |
| Salto mínimo (toque de 1 tick) | 13,0 px | 35,3 px | — |
| Tempo no ar (salto completo) | 39 ticks | 53 ticks | — |
| Jump cut | ×0,45 por tick | 1 só (vy −545 → −235 → só gravidade) | ✔ |
| Janela de apex (\|vy\|<60) | 5 ticks | 9 ticks (0,15 s) | "pequena" ✔ |
| Terminal | 1100 px/s | **750 px/s** | ✔ |
| Coyote / buffer | 6 / 7 ticks | 6 / 7 ticks | mantidos ✔ |
| Ar: acelerar / parar / inverter | 10 / 13 / 18 ticks | **9 / 11 / 11** | 8–10 / 10–12 / 10–12 ✔ |
| Dash: 1.ª velocidade | tick 1 | **tick 0** | mesmo tick ✔ |
| Dash: burst / recarga | 10 ticks a 620 / 34 ticks | 10 ticks a 620 / 34 ticks | inalterados ✔ |
| Dash: distância até parar | 185,6 px | **120,9 px** (103 de burst + 18) | reduzir deslize ✔ |
| Dash a correr: voltar a 240 | > 20 ticks | 11 ticks | controlado ✔ |
| Roll: 1.ª velocidade | tick 1 | tick 0 | — |
| Roll: burst | 360 px/s | 320 px/s (+33 % sobre correr) | > corrida ✔ |
| **Correr 3 s vs roll spam 3 s** (parado) | 709 vs **979** px (×1,38) | 709 vs **695** px (**×0,98**) | correr ≥ roll ✔ |
| idem (a correr, lançada) | 720 vs 983 (×1,37) | 720 vs 695 (×0,97) | ✔ |
| **Pogo**: ressalto / intervalo | 35,9 px / 28 ticks | **56,3 px / 34 ticks** | medido à parte |
| Pogo / salto | 0,43 | 0,44 | proporção conservada |
| Câmara, queda de 900 px: chão visível antes do impacto | 0,27 s | 0,38 s | barra do slice 0,6 s ✘ |
| Queda: px nos últimos 0,6 s | 637 | 448 (mundo visível 514) | — |

**Pogo** (pedido: não assumir): a fórmula 0,7 dava ~57 px medidos e a proporção pogo/salto ficou igual à
de antes (0,44 vs 0,43) — não foi um número de sorte. Mas em absoluto o ressalto sobe 36 → 56 px e o ciclo
28 → 34 ticks: cada pisão dá mais tempo no ar e mais alcance horizontal (~+40 px por salto). Fica para
playtest; se se quiser o pogo mais "seco", o botão é `STOMP_RESSALTO`.

**Câmara** (medida com zoom 1.4, viewport 1280×720, sem limites de nível): o chão só aparece 0,38 s antes
do impacto (era 0,27 s) — a redução do terminal ajudou mas **não chega a 0,6 s**. Recomendação (não feita):
subir `LOOK_QUEDA_Y` (92 → ~190) e/ou antecipar o limiar da queda em `camera_tremor.gd`, e medir de novo.

**Roll**: o roll continua a ser o movimento mais rápido *no instante* (320 > 240) mas paga com uma
recuperação de 0,2 s; repetido, transporta ~2–3 % **menos** do que correr. Margem pequena de propósito
("não pesado"). Botões: `VEL_ROLAR`, `ROLAR_REC_VEL`, `ROLAR_REC_DUR`, `RECARGA_ROLAR`.

## Regressão obrigatória

1. Bancada F1 corrida (AFTER acima). ✔
2. **Limites em teste**: `tools/correr_regressao_movimento.ps1` (modo `regressao` da bancada, ~20 s,
   isolado) — 30 asserções: altura 125–135, corte único, apex 6–14 ticks, terminal ≤ 755, coyote 6,
   buffer ≥ 7, ar 8–10/10–12/10–12, dash (mesmo tick, 10 ticks, ≤ 130 px, volta a 240 em ≤ 12), roll
   (mesmo tick, > corrida, razão spam/correr ∈ [0,85; 1,0]), pogo 45–65 px e 0,35–0,5 do salto, chão
   visível ≥ 0,35 s, e a envolvente de salto nunca a encolher face ao baseline. **0 falhas com o código
   novo; 25 falhas com o código antigo** (prova de que morde).
3. `verifica_alcance_todos`: 0 portas inalcançáveis (mas usa números FIXOS — vão 210 / subida 118 — e por
   isso não reage a uma mudança de física; ver 4).
4. **Acessibilidade com a envolvente real** — `tools/comparar_alcance_f1.gd`, envolvente medida por
   `envolvente` (vão máximo por subida, a correr, botão segurado, salto simples até N5 e duplo depois):
   - **Nada que era alcançável deixou de o ser** (0 regressões).
   - Envolvente do salto simples: vão a subida 0 **180 → 230 px**; a 100 px de subida 140 → 200; subida
     máxima 140–160 → **200** (com agarrar-borda). Salto duplo: vão 300 → 390, subida máxima 180–220 → 200+.
   - **46 dos 99 níveis** medidos passam a ter plataformas novas alcançáveis (**1 725 de 15 635**, 11 %);
     **8 portas** passam a ser alcançáveis só com saltos: N3, N15, N16, N20, N46, N49, N56, N60. Redução
     média de saltos até à porta −10; máximo −22 (N98).
   - **Região I**: N1 +15 plataformas (10 → 9 saltos até à porta), N2 0, **N3 +43 e porta agora alcançável
     só a saltar (antes não)**, N4 +1, N5 0.
5. Pogo medido (acima). ✔  6. Dash medido. ✔  7. Roll spam vs correr. ✔  8. Câmara em queda longa. ✔
9. **Suite completa**: `OK -- todos os testes passaram` (antes da mudança também). Além disso os 8
   verificadores do CI, `verifica_spawn_livre`, `run_region02_wind_shapes`, `run_glide_region02`,
   `run_movement_camera_4a` e `run_wind_system`: todos exit 0. A única falha apanhada foi o caso H do vento
   (corrigido, ver nota acima).
10. **Save real intacto** (SHA verificado em cada corrida isolada). ✔

## Regressões e sinais — PARAR antes da Passagem 2

Regressão de alcance: **nenhuma** (nada ficou inalcançável). Mas a regra do GM ("skips graves → parar e
reportar") tem um sinal claro, e por isso não avancei:

**A física nova abre atalhos sobre as mecânicas de "ajuda" dos níveis.** O gerador (`gerador_corredor.gd`,
`SUBIDA_TORRE = 120`, `_ajudas_verticais`) resolve degraus altos com trampolim / impulsor / elevador /
corrente. Com salto de 128 px + agarrar-borda a subida máxima passa de ~140 para ~200 px, e o salto duplo
cruza vãos de 360–390 px (antes ≤ 300) — o que estas ajudas existiam para resolver. Em N3 (Região I), N15,
N16, N20, N46, N49, N56 e N60 o percurso spawn→porta passa a existir **sem usar nenhuma ajuda**.

Limites do modelo (para ninguém tirar mais do que isto): estático; plataformas móveis como caixas paradas
(igual nas duas envolventes, logo comparável); sem tetos, hazards nem inimigos; pilotos "ideais" (botão
segurado, mantle em cada borda — na prática o mantle hoje exige ≥ 12 ticks de botão, é a Passagem 2); a
subida máxima do salto simples antigo (140–160) foi tomada como 140, o que empurra alguns "novos" para o
lado do exagero. É um detetor de DIFERENÇAS, não uma prova de jogabilidade.

**O que não é regressão mas convém saber:** o salto duplo do N5 (entregue pelo Coração Putrefacto) passa a
dar pouco: o salto simples novo (vão 230 a 0 de subida) já cobre o que o duplo antigo pedia (≤ 210). A
proposta de verbos do GM (Dash N2, Pogo N3…) mantém-se, mas a "cerimónia" do duplo salto no N5 perde
função de gate — ver F4.

### Decisão pedida ao GM
- **A (recomendada)**: manter o salto a ~128 px; aceitar o atalho nos níveis legados (estão congelados e
  vão ser reconstruídos pelo pipeline F4) e **desenhar N1–N5 já para a envolvente nova** (a
  tabela medida está em `f1_envolvente_antes_depois.json`). Subir `SUBIDA_TORRE` para ~205 e rever
  `vao_possivel` mexeria na geometria dos 100 níveis (baseline de jornada) — fora desta passagem.
- **B**: descer o salto para ~110 px (abaixo da faixa aprovada) — devolveria parte do gating, à custa do feel.
- **C**: manter 128 px e, na Passagem 2, limitar o mantle (deslocamento fixo curto / só abaixo do apex),
  que é o que estica a subida máxima de ~130 para ~200.

## Efeitos colaterais conhecidos (não medidos, para playtest)
- Combate de chefes: com salto de 128 px (era 83) e ar de 0,88 s (era 0,65) os padrões desenhados para o
  salto antigo podem ficar mais fáceis de evitar. Sem medição.
- `WALLJUMP` (−430) e `BORDA_MANTLE` (−430) continuam absolutos: o salto de parede passa a ser ~52 % do
  salto normal (era ~80 %). Não foi tocado (wall-kick é decisão à parte).
- O salto duplo é "dois saltos de 128" (mesma `FORCA_SALTO`).
- Trampolins/impulsores/vento usam impulsos absolutos: inalterados.

## Ficheiros
`scripts/movimento.gd`, `scripts/koliani.gd`, `tests/test_glide_region02.gd` (só um comentário),
`tools/bench_movimento_f1.gd|.tscn` (bancada + modo `regressao`), `tools/correr_regressao_movimento.ps1`,
`tools/comparar_alcance_f1.gd`, `docs/qa/f1_movimento/*`. Nenhuma cena, asset ou gerador de níveis
alterado (a geometria dos 100 níveis é a mesma: o gerador não lê `Movimento`).
