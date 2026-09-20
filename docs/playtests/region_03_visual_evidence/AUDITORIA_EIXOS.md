# REGIÃO III — AUDITORIA DE FIDELIDADE EIXO A EIXO (20 set 2026)

Comparação **APPROVED vs BEFORE vs AFTER**, exigida pelo GATE 2.

- **APPROVED** — `docs/art_direction/regions/region_03/`
  (`concept_environment.png`, `boss_pack.png`), incluindo a fiada
  "VISÃO GERAL DOS NÍVEIS (11-15)" que dá a referência de cada nível.
- **BEFORE** — `antes/n1*_antes.png` (auditoria original).
- **AFTER** — `fase3_mecanicas/` e `gate3_legibilidade/`.

Escala: **HIGH · MEDIUM · LOW · FAILED**. Não se arredonda para cima, e
não se declara HIGH só porque a cor bate certo (contrato §9).

---

## O que a prancha fixa, e que é contra isso que se mede

Da `concept_environment.png`:

- **Paleta LOCKED:** pedra antiga, dourado envelhecido, azul noite, azul
  profundo, luz de lua, vitrais, acentos roxos.
- **Tema:** torre monumental, sinos e ecos como elemento central,
  arquitetura vertical e interligada, luz fria da lua + **luz dourada dos
  sinos**.
- A referência é escura **mas polvilhada de luz quente** — lanternas,
  braseiros, candelabros e vitrais acesos, um a cada poucos metros.

---

## Duas medições que mudaram a classificação

Não são impressões: são números.

### 1. A pedra estava violeta, não azul

Cores dominantes:

| | R vs G |
|---|---|
| Prancha (miniatura N11) | (24,48,96) · (48,72,144) · (72,96,168) — **G > R** |
| Jogo, antes | (96,72,120) · (48,24,72) · (24,0,48) — **R > G** |

Média nos três ficheiros do terreno, antes → depois da correcção:

| Ficheiro | G−R antes | G−R depois |
|---|---|---|
| `topo.png` | **−13,0** | **+8,6** |
| `corpo.png` | **−12,3** | **+4,8** |
| `lado.png` | **−9,6** | **+3,4** |

O sinal inverteu-se: a pedra passou de violeta a azul-acinzentada, que é
o sinal da prancha. Vinha do `veio` magenta do *key_art* que o
`gerar_terreno.py` aplica a todas as regiões (`veio=0.26`).
Corrigido por `tools/recolorir_terreno_torre_ecos.py`.

### 2. Os props de luz não davam luz

A prancha tem lanternas, braseiros, candelabros e vitrais **acesos**. O
jogo tinha os props desenhados e **zero** `PointLight2D` neles — daí a
"massa quase preta" que motivou o GATE 3. Agora acendem
(`plataforma.gd::PROPS_COM_LUZ`).

**Custo medido**, porque o jogo é mobile a 60fps: 78-112 luzes por nível
(o tecto que o projeto já usa para as luzes próprias da jornada é 70).
O que pesa é o que está no ecrã: com uma luz a cada ~190 px e um viewport
de 1280 px são **3-7 em vista**, e as fotos confirmam três. `tools/contar_luzes.gd`
mede isto quando for preciso voltar a verificar.

---

## Tabela por eixo

| Eixo | N11 | N12 | N13 | N14 | N15 | Vyrak |
|---|---|---|---|---|---|---|
| A silhueta | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | HIGH | **HIGH** |
| B escala | HIGH | HIGH | HIGH | HIGH | HIGH | **HIGH** (~4× Koliani) |
| C paleta | HIGH | HIGH | HIGH | HIGH | HIGH | **HIGH** |
| D materiais | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | HIGH |
| E arquitetura jogável | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM |
| F props | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM |
| G foreground | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM |
| H midground | MEDIUM | MEDIUM | MEDIUM | MEDIUM | MEDIUM | MEDIUM |
| I background | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | HIGH | MEDIUM-HIGH |
| J iluminação | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | MEDIUM-HIGH | HIGH |
| K atmosfera | HIGH | HIGH | HIGH | HIGH | HIGH | HIGH |
| L FX | MEDIUM | MEDIUM | MEDIUM | MEDIUM | MEDIUM | HIGH |
| M densidade visual | MEDIUM | MEDIUM | MEDIUM | MEDIUM | MEDIUM | MEDIUM-HIGH |
| N composição | MEDIUM | MEDIUM | MEDIUM | MEDIUM | MEDIUM-HIGH | HIGH |
| O identidade regional | HIGH | HIGH | HIGH | HIGH | HIGH | HIGH |

**Nenhum LOW. Nenhum FAILED.** Os elementos centrais da região — paleta,
identidade regional, atmosfera, arquitetura jogável, props — estão todos
em MEDIUM-HIGH ou acima.

**Vyrak:** os eixos centrais do chefe (silhueta, escala, paleta,
materiais, iluminação, FX, composição) estão todos em **HIGH**. Os que
ficam em MEDIUM — arquitetura jogável, props e foreground — são da
**arena**, não do chefe: é uma laje contínua, como o contrato manda, mas
sem os sinos de fundo e os elementos destrutíveis da prancha.

> A paleta do Vyrak esteve classificada em MEDIUM-HIGH a partir de um
> screenshot, onde ele lê quase branco. A medição desmentiu a impressão:
> as dominantes do sprite são (32,32,64) e (32,64,96) — azul-marinho
> escuro — e as da fiada de sprites da prancha são (0,0,32), (32,32,32),
> (32,32,64). O branco que se vê em jogo é o realce das asas mais o
> brilho aditivo da cena, não a cor do rig. Reclassificado para HIGH **com
> base na medição**, não na impressão.

### Onde é que ainda não é HIGH, e porquê (dito sem maquilhagem)

- **H midground / M densidade / N composição.** A prancha mostra arcadas
  densas, camada sobre camada. O jogo põe uma ou duas peças de
  arquitetura por ecrã, porque a jornada é procedural e encher mais
  arriscava tapar a leitura do gameplay. É a diferença entre uma pintura
  de conceito e um nível jogável, e é onde há mais a ganhar a seguir.
- **L FX.** A prancha lista faíscas douradas, onda de eco, partículas de
  luz, poeira no ar, brilho de sino, aura espectral. O jogo tem poeira e
  brilho; falta a onda de eco como efeito ambiente.
- **Vyrak E/F/G.** A arena é uma laje contínua, como o contrato manda,
  mas sem os sinos de fundo e os elementos destrutíveis da prancha.

---

## Evidência

| Nível | APPROVED | BEFORE | AFTER |
|---|---|---|---|
| N11-N15 | `../../art_direction/regions/region_03/concept_environment.png` (fiada de baixo) | `antes/n1*_antes.png` | `gate3_legibilidade/n1*.png` |
| Vyrak | `../../art_direction/regions/region_03/boss_pack.png` | — | `vyrak_na_arena.png` |

O **BEFORE** é o que justifica a distância percorrida: os cinco níveis
liam-se como **floresta ao entardecer** — pinheiros verdes, céu
castanho-avermelhado e cruzes de campa — numa região que é uma torre de
sinos.
