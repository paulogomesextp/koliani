# N20 autoral — "Núcleo da Fornalha" (Região IV, Fornalha) + Guardião da Fornalha

**Data:** 3 out 2026 · **Cena:** `scenes/levels/O_Abismo.tscn` (nome legado — era O
Abismo, índice 19 de `EstadoJogo.NIVEIS`; mudá-lo parte saves) · **Gerada por:**
`tools/construir_n20_nucleo.py` + `tools/r4_lib.py` (editar lá, nunca no `.tscn`).
Chave i18n: `level.n19` ("Furnace Core"). Boss: `scenes/actors/ChefeGuardiaoDaFornalha.tscn`
+ `scripts/chefe_guardiao_da_fornalha.gd`.

**Estado: tecnicamente fechado; HUMAN PLAYTEST REQUIRED** (justiça dos tempos do
boss, sensação do TTK, legibilidade em telemóvel).

## Contrato LOCKED
`docs/art_direction/regions/region_04/level_mechanics.png` (N20 "Núcleo da Fornalha —
tudo conduz ao Guardião": combinação de todas as mecânicas, sequência final de
plataforma e perigo, maquinário em grande escala, acesso à arena; props: Núcleo
de Magma, Maquinaria Gigante, Ponte Final) e `boss_pack.png` (Guardião da
Fornalha, 10 ataques desenhados, duas fases, notas de design). O contrato manda:
boss "sempre superável", telegraph claro, dificuldade por padrões e não RNG,
fase 2 que transforma mas mantém espaço justo.

## Estrutura (largura 5640 px; chão y=600)
| Secção | x | Reutiliza (provado) |
|---|---|---|
| **A — Revisão** | 0–1130 | pisos quentes + jato (N16), 1 Trabalhador. CP1 1030 |
| **B — Ascensão/calor** | 1130–2100 | lava que sobe com pedras (N18) + carrinho sobre lava (N17). CP2 1940 |
| **C — Pressão** | 2100–3650 | válvula + fosso de ritmadas/pistão/jato (N19). **Segredo 1** (StepC só com a válvula). Do outro lado: Arqueiro numa plataforma + **Operário Blindado elite** (guardião da aproximação). CP 2135 e 3190 |
| **D — Aproximação** | 3650–4300 | corredor de máquinas: 2 pistões desencontrados + jato, "porta de válvula" (sem válvula janela 0,14 s; com ela folga). **Segredo 2** (StepD). CP 3668 |
| **Arena** | 4300–5600 | ver abaixo. CP imediatamente antes do boss (4350) |

6 checkpoints, 2 segredos (30 essência cada, fora do caminho crítico), `corredor = false`.
Nenhum checkpoint entre uma válvula e os seus alvos (as válvulas resetam com a
cena). Todos os fossos têm muros sob as pontas do chão (sem saída por baixo).
Decisão de desenho: o exame **não reensina**; recombina blocos já provados com
densidade crescente e acaba no boss. Dimensão menor que N18/N19 (~6700) de
propósito: densidade + clímax.

**Landmark:** o **Núcleo de Magma** — engrenagem gigante (`r4_eng_grande` ×4,2) a
girar devagar atrás da arena, brilho de lava aditivo, Maquinaria Gigante
(`r4_maquina`/`r4_fornalha` ×2) e correntes do tecto; maior que a roda de pressão
do N19. A **Ponte Final** é o chão contínuo da arena.

## Guardião da Fornalha — o ÚNICO boss da Região IV
Arte: rig `bosses_anim/guardiao_da_fornalha`, extraído por
`tools/extrair_guardiao_da_fornalha.py` do painel SPRITES da prancha oficial
(idle, andar, preparação, ataque, dano, transição, derrota); nada redesenhado.
Altura-alvo 170 px (~4× Koliani). Colisão: corpo 100×150, contacto 150×158 (arte
visível mais larga que a hitbox; só o martelo magoa pela zona telegrafada).

**Luta parada no chão**, por padrões fixos (sem RNG). Depois de cada ataque fica
**EXPOSTO** (núcleo à vista) = janela de ataque. Faixa de movimento 4800–5300; os
dois **refúgios** (110 px acima do chão, um salto simples) ficam fora dela.

| # | Ataque | Telégrafo | Defesa |
|---|---|---|---|
| 1 | **Golpe vertical** | martelo sobe, zona à frente marcada no chão (0,75 s) | sair da zona 50–200 px |
| 2 | **Onda de lava** | preparação, depois onda rasteira (250 px/s, 34 px) | saltar |
| 3 | **Chamas do núcleo** | 3 marcas no chão acendem (≈0,94 s) e sobem colunas | mexer-se |
| 4 (f2) | **Investida** | recua e inclina-se | afastar/saltar/refúgio |
| 5 (f2) | **Erupção** | chão todo marcado 1,7 s; lava só na faixa baixa | **subir a um refúgio** |

Fase 1 (100→50 %): GOLPE→ONDA→CHAMAS em ciclo. Fase 2 (≤50 %, `TRANSFORMA` 1,5 s):
telégrafos ×0,8, GOLPE→ONDA encadeados, chamas com 4 colunas, mais INVESTIDA e
ERUPÇÃO; padrão fixo de 5 ciclos. Nunca empurra a Koliani sem aviso.

**HP/TTK:** base 680 (Vyrak 620, Céus 540) ×4,25 do afinador = **2889**. Medido no
harness (golpes de 50 só nas janelas, ~45 % do tempo, 1 golpe/0,45 s): **TTK
59,5 s**, DPS efetivo ≈49; mínimo teórico a bater sempre ≈26 s. Dano por ataque:
golpe 26, onda 20, chamas 22, investida 30, erupção 32 (×1,1 na fase 2).
**Reset:** a morte recarrega a cena; o `_exit_tree` apaga também ondas, colunas,
marcas e lava da erupção (testado: vida cheia, DORME, sem histórico/perigos).
**Conclusão:** ao cair, `derrotado` → baú → cartão `region.4.complete` → porta;
regista `boss_level_020`; **nenhuma habilidade** (o contrato só dá exemplos;
nada inventado). Skill global: não aplicável (N20 sem skill).

## Provas
- `tests/test_region04_n20_level.gd` (estrutura, CPs, válvulas↔alvos↔CPs, vãos com salto
  duplo real, frestas 13–33 px, pistões apoiados, janelas, arena, manifesto, i18n).
- `tests/run_boss_guardiao_fornalha.tscn`: spawn/HP/hitbox, luta inteira com Koliani
  real (cada ataque, telégrafo antes do golpe, **zero dano em telégrafo**, janelas
  EXPOSTO, fase 2 aos 50 %), erupção (refúgio 0 dano; chão >0), TTK, bau→cartão→porta,
  reset.
- `tools/prova_n20_travessia.gd`: piloto físico A–D → entrada da arena: **0 toques,
  0 quedas** em 6 fases de arranque; `N20_SEGREDOS=1` 2/2; `N20_FOSSOS=1` 6/6 saídas;
  `N20_SEM_VALVULAS=1` controlo.
- Capturas reais: `docs/qa/n20_autoral/` (A_exame, B_lava, C_pressao, D_aproximacao,
  overview_arena, boss_fase1_*, boss_fase2_*, exe1_*).

## Defeitos achados e corrigidos na QA
- Marcas de telégrafo do golpe/chamas/erupção nunca eram criadas (`_t < dt` falhava
  por 1 frame): agora `_marcou`. Sem isto o teste de "sem dano em telégrafo" passava vazio.
- Fosso estático sem muros: dava para sair POR BAIXO do chão e cair do mundo.
- Jato C com 50 % de tempo ativo apanhava o piloto 4 em 5 fases: 1,8/0,8/1,7 s.
- Lava da erupção tapava Koliani e boss: z atrás + alfa 0,55.

## Decisões / pendências
- Guardiões N18 (Sentinela de Pressão) e N19 (Lança-Chamas elite): canónicos.
- Rig com resolução da prancha (poses pequenas ampliadas): mais macio que os
  rigs de maior resolução; se o Paulo quiser mais nitidez, só com nova prancha.
- `region.3.complete` não existe (Região III sem cartão): não tocado.
- Nome de região "Catacombs of the Abyss" no seletor é legado: não tocado.
- `tools/afinar_atmosfera.py` ainda lista O_Abismo (gruta roxa): **não correr** no N20.
- DEVICE VALIDATION em telemóvel por fazer.
