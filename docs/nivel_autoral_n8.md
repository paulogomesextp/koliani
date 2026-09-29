# N8 -- "Desfiladeiro dos Ventos" (nível AUTORAL, Região II: COMBINE)

Estado: **PRONTO PARA PLAYTEST DO GM -- NAO LOCKED** (27 set 2026, sem push).
Cena `scenes/levels/Corredor_das_Execucoes.tscn` (nome de ficheiro legacy
mantido: mudar partia saves/testes; o jogador lê `level.n07` [0-based] =
"Desfiladeiro dos Ventos"). Padrão N1-N7: `corredor = false`,
`checkpoints_autorais`.

## Estrutura regional (aprovada pelo Paulo)
N6=Teach, N7=Develop/Test, **N8=Combine**, N9=Challenge, N10=Boss/Exame. O
N8 COMBINA competências já aprendidas (vento, Dash, salto duplo, Pogo,
Especial/Energia) sem introduzir nenhuma skill principal nova.
`escalar_paredes` continua indisponível (só depois do boss do N10).

## Auditoria do legacy ("Process 11", removido nesta execução)
A cena anterior era "Ilhas Suspensas": `ZonaPlanar` (planar CONTEXTUAL, só
ali -- a habilidade permanente "planar" continua a abrir só no N63) +
`WindZone` + um `Chefe` (`ChefeDamaGuilhotina`, "Dama da
Guilhotina"/"Feiticeira dos Ventos"). Achados e remoções:

- **`ZonaPlanar` removida por completo.** O planar não está na lista de
  combinações pedida (vento/dash/salto-duplo/pogo/especial) e o briefing
  pede explicitamente para não introduzir nenhuma skill principal nova no
  N8. A mecânica de Movimento (`Movimento.passo(..., planar)`) e o seu
  contrato puro (`tests/test_glide_region02.gd`) **não foram tocados** --
  continuam a servir a habilidade permanente do N63.
- **`Chefe` (`ChefeDamaGuilhotina`) removido.** N8 é Combine, não
  Boss/Exame (esse é o N10). O script `chefe_dama_guilhotina.gd` tem um
  piso de vida cozido (`vida = maxi(vida, 490)`) para o seu uso como
  chefe/exame algures -- usá-lo como Guardião aqui inflacionava-o depois
  da escala regional (`ChefeBase._afinar_dificuldade`), competindo com o
  boss do N10. **O mesmo raciocínio que o N07 já tinha aplicado ao
  `ChefeIgnivar`.** Não se mexeu no script do chefe (fora de âmbito).
- **Nenhum `Coletavel` `escalar_paredes` nem dependência de wall-jump**
  encontrados na cena legacy -- nada a remover nesse eixo.
- **Nenhum conteúdo temático de Prisão/Fornalha/Cárcere** -- o legacy já
  tinha sido adaptado a "ilhas suspensas" numa execução anterior
  ("Process 11"), portanto não havia Guilhotina/Serra/Casca de masmorra
  na cena (confirmado ao ler o ficheiro antes de mexer).
- O teste dedicado antigo `tests/test_region02_n08_level.gd`
  (`TestesRegion02N08`, contrato do Process 11: 3 fogueiras, `Chefe`,
  `ColProjetil`, `ZonaPlanar` cobrindo tudo) foi **retirado** -- o mesmo
  padrão usado quando N06/N07 passaram a autorais (não há
  `test_region02_n06/n07_level.gd`). Substituído por `teste_n8_autoral`
  (`tests/run_tests.gd`) + os blocos N08 acrescentados a
  `tests/test_region02_wind_levels.gd`.

## Curva interna (A-F)
| Sec. | x (mundo) aprox. | Papel | Conteúdo | Checkpoint |
|---|---|---|---|---|
| A Reentrada | 0-830 | chão firme, sem risco, sem tutorial | `ChaoInicio` | `CheckInicio` 300 |
| B Combinação 1 | 830-1970 | vento CONTRA contínuo + salto duplo | `IlhaB1`/`IlhaB2` (vãos 230/190, dentro do salto duplo ≤380); o 2º salto corrige posição contra o vento, não só sobe | `CheckDuplo` 1650 |
| C Combinação 2 | 1970-2790 | vento CONTRA contínuo + Dash | `DashA`→`DashB` (vão direto 190, como o N07); `DashApoio` mais baixo garante travessia sem Dash | `CheckDash` 1780 |
| D Decisão/rota | 2790-3560 | bifurcação sem grande backtracking | Segura (`SeguroA`/`SeguroB`, chão, sem vento) vs. rápida (`RiscoA`+`WindRisco` a favor pulsado+`CorrenteRisco`+`CacheRisco` Essência); convergem em `Converge` | `CheckRota` 3560 |
| E Combinação 3 | 3560-4480 | vento pulsado + ameaça conhecida + Pogo opcional | `WindE` pulsado, `MorcegoAmeaca` (inimigo simples, não elite), `AlvoPogo`+`PlatAlvo` (pogo authored, opcional, chão por baixo -- sem softlock) | `CheckAmeaca` 3850 |
| F Mini-exame | 4480-6550 | combina leitura do vento + salto duplo + Dash + timing, **sem boss** | `WindF1` (favor) → `F2` (salto duplo) → `WindF2` (contra) + `FDashApoio` → `F3`/`F4` → arena do Guardião | `CheckExame` 5600 |

6 checkpoints, nenhum dentro de vento perigoso (`VentoArena`, fraca, é
exceção documentada como no N6/N7 -- cobre a arena de propósito e fica a
210+ px do `CheckExame`).

## Guardião (não boss)
Fecha com um **Elemental do Vento elite** (`DemonioBase`, `especie =
"elemental_do_vento"`, `comportamento = "voador"`, vida 210 crua), no nó
`Guardiao` (nunca `Chefe`): sela a porta até cair, não grava boss
derrotado, não dá baú nem habilidade (`nivel_com_chefe.gd::_abrir_guardiao`).
Espécie já usada na região (N10), aqui como sentinela final distinta dos
Guardiões do N6 (Golem das Falésias) e N7 (Sentinela Flutuante).

## Combinações reais utilizadas
- **Vento + salto duplo** (secção B): vento contra contínuo; o 2º salto
  corrige a trajetória, testado também sem usar o salto duplo no primeiro
  instante possível (a plataforma de partida dá folga).
- **Vento + Dash** (secção C): vento contra contínuo; `DashApoio` evita
  precisão pixel-perfect; Dash cedo/tarde falha, o timing certo emerge do
  vento contínuo (mesmo mecanismo do N07, sem números absurdos novos).
- **Vento + rota/recompensa** (secção D): a rota rápida combina vento a
  favor pulsado + `PlataformaCorrente` (moving platform fiável) para
  chegar à Essência; a rota segura não tem vento nem exige Dash.
- **Vento + ameaça conhecida + Pogo opcional** (secção E): `morcego_dos_
  ventos` dentro de uma zona pulsada; `AlvoPogo` dá um atalho de Pogo
  authored, nunca obrigatório (double jump também atravessa o vão).
- **Vento (as duas direções) + salto duplo + Dash** (secção F): mini-exame
  final, sem inimigo, combina tudo o que o nível ensinou.

## Wall-jump
Confirmado explicitamente: nenhuma secção exige wall-jump; nenhum
`Coletavel` `escalar_paredes`; nenhum teste assume essa habilidade;
`MuroInicio`/`MuroFim` são só limites do nível (paredes lisas, sem
promessa de escalada).

## Testes
- `teste_n8_autoral` (`tests/run_tests.gd`): estrutura autoral, sem
  jornada, Guardião≠Chefe, 6 checkpoints, sem `Coletavel`/`ZonaPlanar`,
  sem mecânicas alheias, 8 zonas de vento (as duas direções, tudo
  horizontal), checkpoints fora do vento perigoso, geometria (vãos ≤380,
  orçamento do salto duplo), UMA `PlataformaCorrente`, Guardião com vida
  100-300 (crua), porta selada/aberta corretamente, sem
  `escalar_paredes`/`dash_aereo` concedidos, vento desloca mesmo a
  Koliani no ar.
- `tests/test_region02_wind_levels.gd`: N08 acrescentado a `CENAS`
  (estrutura, 8 zonas horizontais, direções opostas), à isenção de
  `VentoArena` (mesmo padrão do N06/N07) e à assinatura da região
  ("combinada dirigida", distinta das outras quatro).
- `tests/test_region02_n08_level.gd` (contrato do Process 11 legacy):
  **removido** -- ver secção de auditoria acima.
- Suite completa: corrida via `tools/correr_testes.ps1` (isolamento de
  save). Cobertura isolada de confirmação, via `python
  tools/godot_isolado.py -- --headless --path . res://tests/run_tests.tscn`
  com `SO_TESTE=<nome>`: `teste_n7_autoral` (continua 0 falhas, N7
  intacto), `teste_n8_autoral` (0 falhas), save real intacto em cada
  corrida (confirmado por SHA256 dos ficheiros do save real).

## Por validar / dívida (playtest do GM)
- Duração real com humano (alvo 4-6 min pela extensão/curva; o
  `bot_gauntlet.gd` não sabe combinar vento+Dash+salto duplo
  conscientemente, por isso não é boa medida de tempo aqui).
- Se a rota rápida da secção D compensa mesmo o risco (a `Essência`
  `CacheRisco` vale 24; comparar com o custo de tempo/risco real).
- TTK do Guardião (números "a olho", como o resto da campanha).
- Arte: terreno/props ainda placeholder de cor sólida, como o N6/N7.
- Resíduo não tocado: `tools/verifica_rota_n08.gd` ainda descreve a rota
  do N08 legacy (Process 11) -- ferramenta avulsa, não corre na suite;
  fica para uma limpeza futura (fora de âmbito desta execução).
