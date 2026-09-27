# N7 -- "The Rising Gorge" (nivel AUTORAL, Regiao II: DESENVOLVIMENTO do vento)

Estado: **PRONTO PARA PLAYTEST DO GM -- NAO LOCKED** (27 set 2026, sem push).
Cena `scenes/levels/Fornalha_dos_Pecadores.tscn` (nome de ficheiro legacy
mantido: mudar partia saves/testes; o jogador lê `level.n06` = "The Rising
Gorge"). Padrão N1-N6: `corredor = false`, `checkpoints_autorais`.

## Estrutura regional (aprovada pelo Paulo)
N6=Teach, **N7=Develop/Test**, N8=Combine, N9=Challenge, N10=Boss/Exame.
N7 pega no que o N6 ensinou sobre vento (rajadas horizontais, threshold
> 1300 px/s² em `movimento.gd`) e exige leitura mais consciente: direção,
timing, correção aérea, Dash contra/com o vento -- sem números absurdos.

## Curva interna (A-F)
| Sec. | x (mundo) | Papel | Conteúdo | Checkpoint |
|---|---|---|---|---|
| A Reintro | 0-900 | relembra o vento, sem risco | chão firme; UMA zona CONTÍNUA fraca (1500/120, a favor); nada mata | `CheckInicio` 300 |
| B Desenvolvimento | 900-1980 | vento altera uma travessia real | 3 pontes (150 px) sobre o vazio; rajada a favor PULSADA (1700/170, 1.6s/1.2s) | `CheckDesenvolve` 800 |
| C Mudança de direção | 1980-3330 | ler qual sopra antes de saltar | duas zonas pulsadas opostas, cores de guia distintas (fria=favor, quente=contra); 1 morcego | `CheckDirecao` 1770 |
| D Dash + vento | 3330-3960 | Dash útil, nunca obrigatório | vazio maior, vento CONTÍNUO contra (1750/160); `DashApoio` (plataforma baixa) garante travessia sem Dash | `CheckDash` 3170 |
| E Combinação | 3960-5290 | plataforma móvel + vento + elite conhecido | `PlataformaCorrente` horizontal dentro de vento pulsado (1600/140); `EliteCombo` (golem_aereo, carga, vida 140) + morcego | `CheckCombinacao` 4050 |
| F Fecho + Guardião | 5290-6400 | prova final, combina o nível | 3 plataformas com as duas direções outra vez; arena com `VentoArena` fraco pulsado (1500/120) + Guardião | (o anterior) |

5 checkpoints, nenhum dentro de vento perigoso (a `VentoReintro`, fraca,
está fora do `CheckInicio`/`CheckDesenvolve` por margem; a `VentoArena`,
fraca, é exceção documentada como no N6 -- cobre a arena de propósito).

## Guardião (não boss)
Fecha com uma **Sentinela Flutuante elite** (`DemonioBase`, `especie =
"sentinela_flutuante"`, `comportamento = "cuspidor"`, vida 230 crua ->
efetiva ~212 após a curva de dificuldade regional), no nó `Guardiao`
(nunca `Chefe`): sela a porta até cair, **não** grava boss derrotado, não
dá baú nem habilidade (`nivel_com_chefe.gd::_abrir_guardiao`). Corresponde
ao arquétipo "Torre Vigia" da chave i18n `guard.vigia_desfiladeiro`
(`CatalogoCampanha.CHEFE_KEY[6]`).

**Por que não é o `ChefeIgnivar`**: essa cena tem um piso de vida
*cozido no script* (`vida = maxi(vida, 560)` em `chefe_ignivar.gd`) para o
seu uso como chefe/exame. Reutilizá-la aqui, mesmo como nó `Guardiao`,
dava vida efetiva **~1977** após a escala regional (`ChefeBase._afinar_
dificuldade`, ×3.53 no índice 6) -- competindo com o boss do N10 e
contradizendo a instrução de não transformar F num boss. Mexer nesse piso
seria mexer num boss (fora de âmbito desta execução). Por isso o Guardião
usa `DemonioBase` diretamente, com vida sob controlo total.

## Wall-jump removido
O `Coletavel` `escalar_paredes` (nó `ColEscalar`, x=2440) que existia na
cena legacy foi **removido por completo**. Nenhuma secção depende de
wall-jump; o kit disponível é Dash (N2), Pogo (N3), Especial (N4), Salto
Duplo (N5) -- **sem** `escalar_paredes` (só entra na Região III, após o
boss do N10).

## Conteúdo temático incompatível removido
A cena legacy (`Fornalha_dos_Pecadores.tscn`, tema "fornalha") já tinha
sido parcialmente adaptada ao canon Desfiladeiro dos Ventos em execuções
anteriores, mas ainda tinha: um `Chefe` persistente (`ChefeIgnivar`, que
GRAVAVA boss derrotado e dava baú -- errado para um nível Develop/Test) e
três `Fogo` (fogos de prisão/fornalha, incompatíveis com "abismo de
nuvens"). Ambos removidos.

## Testes
- `teste_n7_autoral` (`tests/run_tests.gd`): estrutura autoral, sem
  jornada, Guardião≠Chefe, 5 checkpoints, sem `Coletavel`, sem mecânicas
  alheias (serra/fogo/etc.), 9 zonas de vento (as duas direções, ensino
  contínuo fraco, mudança de direção legível, dash-contra contínuo,
  `DashApoio` presente), geometria (vãos ≤140, subidas ≤104), Guardião
  com vida 100-300 (crua), porta selada/aberta corretamente, sem
  `escalar_paredes`/`dash_aereo` concedidos, vento desloca mesmo a
  Koliani no ar.
- `tests/test_region02_wind_levels.gd`: atualizado para tratar N07 como
  autoral (Guardião, 5 checkpoints, 9 zonas horizontais) em vez do
  contrato legacy (Chefe, 3 checkpoints, 3 updrafts verticais); isenção
  de `VentoArena` alargada de N06 para N06+N07 (mesmo padrão de arena
  authored).
- Suite completa: **1 corrida integral confirmada** antes do fecho desta
  execução (achou os dois problemas reais -- checkpoint dentro de vento e
  `Chefe` incompatível --, ambos corrigidos). Depois disso, o runner
  `tools/correr_testes.ps1` ficou instável nesta sessão (hangs
  repetidos, processo Godot preso a 0% CPU -- o mesmo sintoma "Godot
  pendura" documentado no `CLAUDE.md`/memória do projeto). Cobertura de
  substituição, toda via `python tools/godot_isolado.py -- --headless
  --path . res://tests/run_tests.tscn` com `SO_TESTE=<nome>` (mesmo
  isolamento de save, sem o hang): `teste_n1_autoral` .. `teste_n5_autoral`,
  `teste_n6_autoral`, `teste_n7_autoral`, `teste_fluxo_fim_regiao1`,
  `teste_cartao_regiao1`, `TestesRegion02WindLevels.executar()` (via
  wrapper temporário) -- todos **0 falhas**, save real intacto em cada
  corrida. O único falhanço visto na corrida integral
  (`Coracao: o Especial devia ajudar sem resolver a luta (19.7 vs 36.5)`,
  em `teste_9h_chefes_regiao1_mais_faceis`) é sobre o boss do N5
  (Coração Putrefacto), não tocado nesta execução, e foi confirmado
  **flake pré-existente** (0 falhas ao correr isolado): está mesmo no
  limiar da razão 0.55 do teste, sensível a ruído do bot.

## Por validar / dívida (playtest do GM)
- Duração real com humano (estimada 3-5 min pela extensão/curva, não
  medida com bot: o `bot_gauntlet.gd` não sabe usar Dash conscientemente
  contra vento, por isso não é boa medida de tempo aqui).
- Se as duas cores de guia (fria=favor/quente=contra) se leem bem no jogo
  real (placeholder técnico, não arte final).
- TTK do Guardião e do `EliteCombo` (números "a olho", como o resto da
  campanha).
- Arte: terreno/props ainda placeholder de cor sólida como no N6.
