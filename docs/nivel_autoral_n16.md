# N16 autoral — "Entrada da Fornalha" (Região IV, Fornalha)

**Data:** 30 set 2026 · **Branch:** `claude/project-thread-lu210k` · **Cena:**
`scenes/levels/Cemiterio_dos_Reis.tscn` (nome legado — mudá-lo parte saves) ·
**Gerada por:** `tools/construir_n16_entrada.py` + `tools/r4_lib.py` (editar
lá, não no `.tscn`). Chave i18n: `level.n15` (índice 0-based).

Arte: as 7 pranchas aprovadas de `docs/art_direction/regions/region_04/`.

## Pipeline de arte da Região IV (reutilizável por N17–N20)
| Peça | Ferramenta | Saída |
|---|---|---|
| terreno (pedra vulcânica / ferro forjado, sem costura) | `tools/gerar_terreno_prancha.py` (região `fornalha`) | `assets/sprites/pixel/terreno/fornalha/` |
| fundo panorâmico da fundição | `tools/gerar_fundos_regiao02_prancha.py` (`RECORTES_R4`) | `backgrounds/fornalha/prancha.png` |
| ~76 props `r4_*` (portão, forno, tubos, lava, pistões, prensa, carrinho…) | `tools/gerar_props_r4_prancha.py` | `deco/fornalha/` |
| 8 inimigos da região (retrato → idle/run/attack/hit/dead) | `tools/extrair_inimigos_regiao04.py` | `enemies/<espécie>/` |

`Atmosfera`: `bioma="fornalha"`, `fundo_pack="fornalha"` (só a prancha, sem
camadas de substituição).

## Mecânicas novas (opt-in; nenhum outro nível muda)
- **PisoQuente** (`scripts/piso_quente.gd`): placa de ferro que cicla
  frio 2,4 s → aviso 1,0 s (brilha) → quente 1,6 s (dano a cada 0,45 s).
  Relógio global + `fase`, por isso é determinístico e legível.
- **JatoFornalha** (`scripts/jato_fornalha.gd`): bocal que dorme, avisa e
  cospe fogo na vertical; `fase` desfasa jatos vizinhos.
- **LavaFornalha** (`scenes/actors/LavaFornalha.tscn`): lava rasa e não letal
  (22 de dano/0,6 s, impulso de saída) com chão por baixo — penaliza, não mata.
- Carrinhos de minério = `PlataformaCorrente` horizontal, presa a um trilho.

## Layout (4600 × ~900 px, Koliani nasce em x 170)
| Secção | O que se faz |
|---|---|
| A (0–1000) | primeiro piso quente (ensino: dá para esperar), Trabalhador, checkpoint; lava A com 2 ilhas de pedra |
| B (1400–2420) | forno, plataforma do Arqueiro, lava B atravessada por um **carrinho** no tecto; Segredo 1 por cima |
| C (2420–3860) | piso quente 2, túnel inferior (Segredo 2), **dois jatos** desfasados, lava C e 2.º carrinho |
| D (3860–4600) | piso quente 3, **Operário Blindado** elite (guardião), portão e porta |

5 checkpoints, 2 segredos. Inimigos: Trabalhador Corrompido, Arqueiro da
Fornalha, Operário Blindado.

## Decisões de desenho (dúvidas resolvidas pela opção recomendada)
1. Lava **rasa e não letal** com chão por baixo: a Fornalha pune sem obrigar a
   repetir o nível inteiro; a lava letal fica para N18.
2. Os 8 inimigos novos saem de **um só retrato** cada; o `DemonioBase`
   anima por movimento procedural. Se o Paulo quiser ciclos próprios, é
   trabalho de arte, não de código.
3. Nomes de cena legados mantidos.
4. O guardião do N16 é um **Operário Blindado elite**, não um chefe da região
   (os chefes ficam para N20).

## Testes
`tests/test_region04_n16_level.gd` (estrutura, espécies, contagem de
mecânicas, vãos medidos com o salto duplo real) + crivo de alcance
(`porta_alcancavel=true`, sem plataformas órfãs). Capturas em
`docs/qa/n16_autoral/`.

## Travessia real (regra do Paulo, 30 set 2026)
`tools/correr_travessia.sh <cena> [perfis]` pilota a Koliani real (fisica,
mecanicas, portoes) com `bot_humano_r2.gd` do inicio a' porta e sai != 0 se
algum perfil nao chegar. N16: **experiente, normal e casual chegam todos a'
porta** (34-74 s, 2-5 mortes). As mortes de 2 perfis concentram-se em x~2300
(carrinho sobre a lava B) e x~3100 (salto do tunel); uma queda repetida do perfil
experiente em x~1630 (y 1212) nao foi explicada -- o chao ali e' solido; a
reter para o playtest humano.

## Por fazer
Playtest humano (legibilidade do piso quente, dano da lava, TTK do Operário);
polimento opcional do terreno (veios de magma). N17–N20 seguem o mesmo pipeline.
