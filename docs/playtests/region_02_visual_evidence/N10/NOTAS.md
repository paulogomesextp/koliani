# N10 — "Torre dos Céus" (`A_Cela_Zero.tscn`) + GUARDIÃO DOS CÉUS

**Referências aprovadas usadas:** `boss_pack.png` (**autoridade primária**:
conceito, 6 poses, painel `ESCALA`, 6 animações nomeadas, 8 ataques, 11 FX,
paleta, painel `ARENA (ELEMENTOS DO NÍVEL 10)`),
`GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md`, painel `NÍVEL 10 — TORRE DOS CÉUS`
(`level_mechanics_and_layout`), paleta **N10 TORRE FINAL**,
`concept_environment_01.png` painel `BOSS (NÍVEL 10)`.

**Fotografias:** `01_inicio`, `02_rajada_favor`, `03_ziguezague`,
`04_poco_esq`, `05_poco_dir`, `06_arena`, `07_guardiao_idle`, `10_ini`,
e as fases da máquina de estados: `11_tel_lamina` (LAMINA_TEL),
`12_lamina` (LAMINA), `13_vento_tel` (VENTO_TEL), `14_vento` (VENTO),
`15_queda` (QUEDA), `16_exposto` (EXPOSTO).
Ficha de escala: `../_comparacoes/n10_guardiao_escala_vs_koliani.png`.
Rig isolado a x3: `../_comparacoes/rig_guardiao_dos_ceus_idle.png`.

## Arena

Dos oito elementos que o painel `ARENA` do `boss_pack` nomeia — mar de nuvens,
lua de sangue, torres góticas partidas, estandartes carmesins, correntes,
braseiros, colunas em ruínas, cristais — **nenhum está na arena do jogo**.
O que lá está: uma laje de tijolo, duas cruzes azuis pequenas, um lampião, uma
silhueta de muralha ao fundo e o portal magenta. A arena aprovada é uma
plataforma suspensa NO CÉU; a do jogo é um patamar dentro de um poço de pedra
fechado (`CascaMasmorra`).

## Guardião — o que bate e o que não bate

**Bate:** espécie (é uma ave: bico, garras, penas, cauda); bico e garras
dourados; paleta índigo/violeta das penas; olho violeta desenhado na cabeça;
o comportamento dos três ataques canónicos (PENAS CORTANTES /
CHAMADA DOS VENTOS / MERGULHO), distinguíveis entre si; as âncoras (projéctil do ombro da asa, pó das garras);
**a escala — 160 px de altura = 2,46x a Koliani (contrato: 2,6x ±10%) e
235 px de largura = 3,6x (contrato: 3,5-3,7x)**.

**Não bate:** a silhueta. O contrato diz que a leitura à distância é definida
"sobretudo pelas **asas** — o elemento mais largo". No rig as asas ficam espalmadas
para os lados, ao nível do corpo ou abaixo, em `idle` e `attack`; só o `walk`
as levanta, e num V raso (ver `../_comparacoes/guardiao_todas_as_poses.png`,
as quatro tiras). Os 235 px de largura gastam-se numa mancha horizontal baixa
e a criatura lê-se como ave POUSADA e pesada, não como o corvídeo de asas
abertas da `ARTE PRINCIPAL`. Falta a cauda de penas longas na idle; a crista
de espigões na cabeça não existe na prancha; o carmesim está nas patas e no
bordo das asas caídas (lê-se como pés vermelhos) em vez de nas pontas das
penas de voo; e o olho/núcleo perde o papel de centro visual para um losango
branco no ventre nas poses de ataque — que é o PROJÉCTIL a nascer.

**E o projéctil é a cor proibida.** O contrato bane em L3 "a paleta
ciano/branco-gelo do `monge_celeste` (`#a8ebff`, `#0.66,0.92,1`)". As PENAS
CORTANTES são, em `scripts/chefe_guardiao_dos_ceus.gd:399`, um `Polygon2D`
losango de 28x12 px com `Color(0.72, 0.92, 1.0)` = **#B8EBFF**. O corpo foi
repintado para violeta-índigo; o ataque-assinatura ficou com a paleta do rig
antigo, e não se parece com uma pena.

## Respostas às duas perguntas em aberto do contrato

1. **"As asas tapam a Koliani na arena?"** Não. Em todas as fotografias de
   combate a Koliani fica completamente legível e sobra mais de metade da
   plataforma (560 px de arena, 235 px de chefe = 42%). Mas isso é
   consequência de as asas estarem coladas ao corpo: os 235 px não custam
   jogabilidade **e também não estão a fazer o trabalho de silhueta para que
   existem**. Abrir as asas para a pose da prancha é que poria a questão.
2. **"As asas não darem dano lê-se ou parece injusto?"** Lê-se. O chefe paira
   acima da cabeça da Koliani e as asas nunca chegam ao chão onde ela está,
   por isso a pergunta "porque é que aquilo não me feriu?" nunca se põe.

**FIDELITY: MEDIUM** (rig) · **LOW** (arena) · **PARTIALLY MATCHES** (contrato).

## Nota transversal — o mar de nuvens

A camada `nuvens.png` ESTÁ nesta cena e aparece nestas fotografias; o que se
vê como "rocha" no plano médio é ela. Medida a luminância média do fundo
contra a do ficheiro de origem (53%), o que chega ao ecrã tem 10-24%. O
problema não é o asset — é `neblina_fundo` / `dessaturar_fundo` /
`tinta_fundo` da cena e o `cor_fundo` da `Atmosfera`.
