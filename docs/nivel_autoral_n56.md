# N56 autoral — "Fronteira Corrompida" (Região XII, Terras Envenenadas)

**Data:** 1 out 2026 · **Branch:** `claude/regiao-xii-sflopo` · **Cena:**
`scenes/levels/Distrito_das_Engrenagens.tscn` (nome legado — mudá-lo parte saves) ·
**Gerada por:** `tools/construir_n56_fronteira.py` + `tools/r12_lib.py` (editar lá, não no
`.tscn`). Chave i18n: `level.n55` (índice 0-based).

Arte: a prancha única aprovada `docs/art_direction/regions/region_12/master_production_board.png`
(1448×1086). Não há pranchas separadas por nível: o cartão do N56 + a faixa de ativos
alimentam tudo.

## Pipeline de arte da Região XII (reutilizável por N57–N60)
| Peça | Ferramenta | Saída |
|---|---|---|
| terreno (terra castanha + lábio de lodo verde com gotas) | `tools/gerar_r12_prancha.py terreno` | `terreno/terras_envenenadas/` |
| 5 fundos (o mural de cada cartão de nível) | `... fundos` | `backgrounds/terras_n56 … n60/prancha.png` |
| 30 props `r12_*` (cercas, moinho, casas, fungos, santuário, poça, géiser, nuvem…) | `... props` | `deco/terras_envenenadas/` |
| 8 inimigos (retrato → idle/run/attack/hit/dead) | `tools/extrair_inimigos_regiao12.py` | `enemies/<espécie>/` |

Limitação honesta: a prancha é pequena (peças de 25–50 px), por isso tudo é ampliado 4× com
Lanczos; o terreno é refeito por passa-alto + mosaico dihedral (o recorte original dava um
tabuleiro de xadrez).

## Mecânicas novas (opt-in; nenhum outro nível muda)
- **SoloToxico** (`scripts/solo_toxico.gd`): faixa de solo contaminado ou nuvem que vai e vem.
  Não dá dano de impacto: aplica o veneno que a Koliani já tem (`envenenar`, ticks de dano,
  tinta verde). Saltar por cima ou esperar a nuvem sai a custo zero.
- **ZonaLimpa** (`scripts/zona_limpa.gd`): ar respirável; tira o veneno (`Koliani.limpar_veneno`).
- **RespiroPraga** (`scripts/respiro_praga.gd`): géiser telegrafado (para N57+).

## Layout (4700 × ~900 px, Koliani nasce em x 170)
| Secção | O que se faz |
|---|---|
| A (0–1150) | primeira poça de solo contaminado (240 px, cabe num salto), 2 ratos, checkpoint |
| B (1150–2330) | pântano raso (100 px abaixo, todo tóxico) com 3 tábuas e uma nuvem fraca; mosca ácida; zona limpa na margem |
| C (2330–3420) | chão desce 80 px: duas poças alternadas com ilhas, zona limpa, nuvens, mosca, segredo 1 |
| D (3420–4700) | rampa de volta, cogumelos gigantes, **Espreitador Fúngico** (elite, guardião), portão; segredo 2 |

4 checkpoints (CheckInicio, B, C, D), 2 segredos.

## Decisões de desenho (dúvidas resolvidas pela opção recomendada)
1. O veneno **não mata**: a região fala em "acúmulo de veneno" e "zonas limpas"; punir sem obrigar a
   repetir o nível. A letalidade vem nos níveis seguintes (respiros, água contaminada).
2. Os 8 inimigos saem de **um só retrato** cada (como na Região IV); o `DemonioBase` anima por
   movimento procedural.
3. Guardião do N56 = Espreitador Fúngico elite (os chefes ficam para o N60: Arauto da Pestilência).

## Testes e travessia
`tests/test_region12_n56_level.gd` (estrutura, espécies, mecânicas, vãos com o salto real) +
crivo de alcance (`porta_alcancavel=true`) + `tools/correr_travessia.sh` (Koliani real do início
à porta).
