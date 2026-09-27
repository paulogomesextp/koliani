# N9 -- "Desfiladeiro dos Ventos" (nível AUTORAL, Região II: CHALLENGE)

Estado: **PRONTO PARA PLAYTEST DO GM -- NAO LOCKED** (27 set 2026, sem push).
Cena `scenes/levels/Ala_dos_Mortos.tscn` (nome de ficheiro legacy mantido:
mudar partia saves/testes; o jogador lê `level.n08` [0-based] = "Desfiladeiro
dos Ventos"). Padrão N1-N8: `corredor = false`, `checkpoints_autorais`.

## Estrutura regional (aprovada pelo Paulo)
N6=Teach, N7=Develop/Test, N8=Combine, **N9=Challenge**, N10=Boss/Exame. O N9
é a escalada final de dificuldade antes do boss: VENTO VARIÁVEL + INIMIGOS +
PLATAFORMAS. O desafio vem da combinação de sistemas já ensinados (vento,
Dash, salto duplo, Pogo, Especial/Energia), não de truques novos.
`escalar_paredes` continua indisponível (só depois do boss do N10).

## Auditoria do legacy ("Ala dos Mortos", removido/corrigido nesta execução)
A cena anterior já tinha bioma/fundo corretos (Desfiladeiro), mas trazia
quatro problemas herdados:

1. **`corredor` nunca era posto a `false`.** O `_ready()` de
   `nivel_com_chefe.gd` continuava a PREPENDER a jornada procedural
   (`CorredorAproximacao`) à frente do conteúdo desenhado à mão -- exatamente
   o que N6-N8 já tinham desligado. Corrigido: `corredor = false`,
   `checkpoints_autorais = true`.
2. **Um `Chefe` real (`ChefeIrmaosCondenados.tscn`)**, com sinal `derrotado`,
   baú e gravação de boss derrotado. N9 é Challenge, não Boss/Exame -- esse é
   o N10 exclusivamente (`tests/test_region02_wind_levels.gd::
   _encontros_canonicos` só aceita UM chefe na região, no índice 9).
   Removido; fecha agora com um `Guardiao` elite (golem_aereo, 235 vida
   crua), mesmo padrão do N6/N7/N8. A identidade "Espectros Gémeos"
   (`guard.espectros_gemeos`, rig `espectros_gemeos`) continua viva no
   catálogo/HUD via `CatalogoCampanha` (chave por ÍNDICE, não pelo nó da
   cena) -- não depende deste ficheiro nem foi tocada.
3. **Um `Coletavel` `partir_paredes`** a meio do nível. A região (N6-N10) só
   concede habilidade no N10 (`escalar_paredes`, por fazer nessa execução);
   nenhum coletável aparece em N6/N7/N8. Removido para alinhar com o resto
   da região -- não corresponde a nenhuma das combinações pedidas para o
   Challenge.
4. **`CascaMasmorra`** (tijolo fechado, `estilo = "desfiladeiro"`) trazia o
   ar de masmorra fechada de quando o nível se chamava "Ala dos Mortos".
   N6/N7/N8 são todos desfiladeiro ABERTO com queda para o mar de nuvens
   (`AguaVenenosa` como `FundoDoAbismo`). Removida por coerência visual.
5. **As três `WindZone` variáveis usavam intensidade 360-520**, muito abaixo
   da faixa validada pela região (< 1300 e o vento mal se sente -- achado já
   medido em `docs/nivel_autoral_n6.md`). Reconstruídas com os parâmetros já
   validados em N6-N8 (1400-1800 / velocidade_max 110-170) -- a mesma
   "linguagem" de vento, não números novos arbitrários. **Não** era o bug
   partilhado de sub-recurso da `WindZone` (esse já estava corrigido em
   `wind_zone.gd::_configurar_forma`, com um comentário a citar exatamente
   este nível como o caso que o revelou) -- era só o autor da cena legacy ter
   usado números fracos.

Sem `Coletavel escalar_paredes` nem dependência de wall-jump encontrados
(nada a remover nesse eixo específico).

## Estrutura A-F
| Sec. | x (mundo) aprox. | Papel | Conteúdo | Checkpoint |
|---|---|---|---|---|
| A Reentrada/Leitura | 0-780 | chão firme, sem risco, reapresenta o vento | `ChaoInicio`, `ChaoReintro`+`WindReintro` (fraco, contínuo) | `CheckInicio` 280 |
| B Vento variável | 780-2060 | 3 zonas consecutivas, comportamentos diferentes | `WindB1` (contra contínuo) → `WindB2` (favor pulsado) → `WindB3` (contra pulsado, ritmo distinto) sobre `IlhaB1/B2/B3` | `CheckVento` 1900 |
| C Vento + inimigo | 2060-2800 | inimigo simples legível dentro de vento pulsado | `WindC` pulsado + `SentinelaC` (`sentinela_flutuante`, não elite, sem projéteis) | `CheckInimigo` 2700 |
| D Plataformação c/ pressão | 2800-3510 | única travessia é pela plataforma móvel | `CorrenteD` atravessa `WindD` (contínuo forte) + `MorcegoD` (pressão, não spam) | `CheckPressao` 3400 |
| E Escolha/risco opcional | 3510-4280 | segura (chão, sem vento) vs arriscada (vento+Pogo+recompensa) | `SeguroE1/E2` vs `RiscoE1`+`WindRiscoE`(pulsado a favor)+`AlvoPogoE`/`PlatAlvoE` (Pogo opcional)+`CacheRiscoE` (Essência 26)+`RiscoE2`, convergem em `ConvergeE` | `CheckRisco` 4150 |
| F Pré-exame | 4280-6260 | vento (favor+contra) + salto duplo + Dash + 2 inimigos simples | `WindF1` (favor pulsado) + `GolemF` → `WindF2` (contra contínuo forte) + `FDashApoio` → `WindF3` (pulsado) + `GosmaF` → arena do Guardião | `CheckExame` 5230 |

6 checkpoints, nenhum dentro de vento perigoso (`VentoArena`, fraca, é
exceção documentada como no N6/N7/N8 -- cobre a arena de propósito e fica a
1000+ px do `CheckExame`).

## Guardião (não boss)
Fecha com um **Golem Aéreo elite** (`DemonioBase`, `especie = "golem_aereo"`,
`comportamento = "voador"`, vida 235 crua), no nó `Guardiao` (nunca `Chefe`):
sela a porta até cair, não grava boss derrotado, não dá baú nem habilidade
(`nivel_com_chefe.gd::_abrir_guardiao`). Espécie já usada na região (era o
`EliteMastim` do legacy, renomeado corretamente para "Desfiladeiro"), aqui
como sentinela final distinta dos Guardiões do N06 (Golem das Falésias), N07
(Sentinela Flutuante) e N08 (Elemental do Vento).

## Combinações reais utilizadas
- **Vento variável + plataformas** (secção B): três zonas consecutivas com
  comportamentos diferentes (contínuo contra / pulsado a favor / pulsado
  contra com ritmo próprio) -- nunca a mesma receita duas vezes seguidas.
- **Vento + inimigo simples** (secção C): `sentinela_flutuante` dentro de
  vento pulsado, sem projéteis (comportamento "voador", não "cuspidor") --
  o jogador lê o vento, lê o inimigo, decide quando avançar.
- **Plataforma móvel + vento + inimigo** (secção D): a única travessia
  possível é pela `PlataformaCorrente`, atravessando vento contínuo forte
  com um `morcego_dos_ventos` a acompanhar -- pressão, não spam nem
  aleatoriedade (o inimigo não decide o salto por si).
- **Vento + Pogo opcional + recompensa** (secção E): a rota arriscada tem
  vento a favor pulsado, um alvo de Pogo authored (nunca obrigatório -- a
  rota segura não toca nele) e uma Essência de recompensa.
- **Vento (as duas direções) + salto duplo + Dash + pressão de 2 inimigos**
  (secção F): pré-exame final, combina tudo o que o nível ensinou, com
  `DashApoio` a evitar precisão pixel-perfect.

## Wall-jump / skill nova
Confirmado explicitamente: nenhuma secção exige wall-jump; nenhum
`Coletavel` (nem `escalar_paredes` nem qualquer outro -- ver auditoria);
nenhum teste assume uma habilidade nova; `MuroInicio`/`MuroFim` são só
limites do nível.

## Testes
- `teste_n9_autoral` (`tests/run_tests.gd`): estrutura autoral, sem jornada,
  Guardião≠Chefe, 4-6 checkpoints, sem `Coletavel`/`ZonaPlanar`/`Casca`,
  sem mecânicas alheias, ≥9 zonas de vento (mais variedade que o N8),
  contínuo E pulsado, checkpoints fora do vento perigoso, contrato secção a
  secção (B: 3 comportamentos distintos; C: inimigo simples sem projéteis;
  D: plataforma móvel + inimigo simples; E: rota segura vs arriscada +
  Pogo opcional + recompensa; F: 2 inimigos simples + as duas direções de
  vento), geometria (vãos ≤380 nas cadeias estáticas -- a secção D fica de
  fora da cadeia, tal como a rota rápida do N8, porque a travessia é pela
  plataforma móvel), Guardião com vida 100-320 (crua), porta selada/aberta
  corretamente, sem `escalar_paredes`/`dash_aereo` concedidos, vento desloca
  mesmo a Koliani no ar.
- `tests/test_region02_wind_levels.gd`: bloco N09 reescrito (deixa de
  assumir 3 zonas/Chefe do legacy; passa a Guardião+4-6 checkpoints+≥9
  zonas horizontais contínuas-e-pulsadas), isenção de `VentoArena` alargada
  a N09 (mesmo padrão do N06/N07/N08).
- Suite completa: corrida via `tools/correr_testes.ps1` (isolamento de
  save). Ver estado em `docs/retomar_aqui.md`.

## Por validar / dívida (playtest do GM)
- Duração real com humano (a extensão é próxima do N8; o `bot_gauntlet.gd`
  não sabe combinar vento+plataforma-móvel+Dash conscientemente, por isso
  não é boa medida de tempo aqui).
- Se a rota arriscada da secção E compensa mesmo o risco (a `Essência`
  `CacheRiscoE` vale 26).
- TTK do Guardião e ritmo dos 4 inimigos simples (números "a olho", como o
  resto da campanha).
- Arte: terreno/props ainda placeholder de cor sólida, como o N6/N7/N8.
- Resíduo não tocado (fora de âmbito, mesmo padrão do `verifica_rota_n08.gd`
  do N8): `tools/verifica_casca.gd` ainda lista "Ala_dos_Mortos" como devendo
  ter uma `Casca` (já não tem, por desenho -- desfiladeiro aberto);
  `tools/geometria_regiao02.gd` e `tests/run_region02_wind_shapes.gd` são
  ferramentas avulsas que ainda apontam ao ficheiro (caminho continua
  válido, mas não foram corridas nem verificadas nesta execução).
