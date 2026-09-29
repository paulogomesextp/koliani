# N12 autoral — "Galerias Verticais" (Região III, Torre dos Ecos)

**Data:** 29 set 2026 · **Branch:** `claude/project-thread-6jbrqw` · **Cena:**
`scenes/levels/Torre_dos_Ventos.tscn` (nome de ficheiro legado — mudá-lo partia
saves) · **Gerada por:** `tools/construir_n12_galerias.py` (editar lá, não no
`.tscn`).

Contrato: `docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md`
(N12 — LOCKED): verticalidade total; elevadores de coluna com corrente,
escadas quebradas, sinos de sincronização, ecos que revelam plataformas,
vitrais interativos, plataformas que desaparecem; hazards poço / plataformas
falsas / lâminas verticais rápidas; fluxo A–D (base → ascensão → vento e
queda controlada → galerias superiores); inimigos Gárgula Vitral, Autómato do
Sino, Monge das Correntes; 3 segredos; exploração 60 / combate 40.

## O que havia antes

O N12 era **jornada procedural** (as câmaras do contrato geradas pelo
`gerador_corredor.gd`) a desembocar numa sala antiga "Torre dos Ventos" com o
**Aerion** — cavaleiro do vento sem lugar no contrato da Torre dos Ecos — e um
`Coletavel` de `projetil` (redundante: já se ganha no N10). Era exatamente o
que o Paulo criticou: pequeno, sem estrutura, arte genérica.

## O que ficou

Sala **feita à mão**, ~2960 × 2700 px (o N11 tem ~1100 × 700), `corredor =
false`, `alongar_plataformas = false`, 5 checkpoints autorais, 3 segredos,
guardião a selar a porta. Coordenadas de desenho (chão da base a y=2400); o
gerador desloca tudo −1400 ao escrever, porque a Koliani morre abaixo de
`koliani.gd::Y_MORTE` = 1200 (armadilha que custou uma sessão de depuração
— ver "Armadilhas").

| secção | papel | o que tem |
|---|---|---|
| **A — Base das galerias** | ensinar | chão largo sem inimigos; **Elevador 1** (peso) com correntes douradas e roldana visível lá em cima; galeria A2 fina a 360 px; **Sino A** de sincronização ergue a ponte de 3 degraus até à A3, com o A2 inteiro por baixo como rede; **Segredo 1** na alcova da roldana |
| **B — Ascensão** | desenvolver | Monge das Correntes na A3; **escadas quebradas** (4 degraus `PlataformaQuebra` com pele de pedra) num poço com rede; lâmina de sino rápida a guardar o **Segredo 2** atrás de um vitral partível; **3 plataformas que desaparecem** em fase escalonada com balcão de rede; **Elevador 2** em vaivém contínuo (ensina a esperar); **vitral interativo** — parti-lo revela a ponte de eco |
| **C — Vento e queda controlada** | variar | galeria oeste alta (CheckC); Monge na ponte alta; **coluna de ar** ascendente de 710 px; **Segredo 3** no cimo da coluna; descida por degraus quebradiços com **vento contra**; rede por baixo encostada à coluna (cair devolve ao ar, não ao início) |
| **D — Galerias superiores** | testar | Autómato do Sino (escudo à frente, fraco nas costas) ao lado do **Sino B**: tocar ergue a ponte **e** gela-o 2,6 s; **lâmina vertical rápida** (serra, 0,8 s) a cortar o salto B2→B3; varanda de rede; arena contínua com o **Guardião** — Autómato do Sino elite (vida 260) |

Guardião: `CatalogoCampanha.CHEFE_KEY[11] = "guard.automato_do_sino"` (novo,
nos 6 idiomas). O Autómato comum da secção D ensina-lhe o ponto fraco antes.

## Arte (sem mexer em PNGs)

- `ElevadorColuna` (`scripts/elevador_coluna.gd`, novo) — a mecânica do
  `TumuloElevador` com a leitura do contrato: pedra do bioma + friso dourado,
  **duas correntes que encurtam** ao subir e **roldana fixa** que gira. Instancia
  `TumuloElevador.tscn` com o script por cima, para os verificadores da câmara
  "elevador" continuarem a reconhecê-lo.
- `PlataformaQuebra.pele_terreno` (opt-in, novo) — os degraus quebradiços
  vestem o `corpo` do bioma em vez da laje cinzenta lisa; o aviso a vermelho
  tinge a textura. Nenhum outro nível muda.
- `CorrenteAr.tamanho` (opt-in, novo) — coluna de ar com o tamanho que a sala
  pede (a forma da cena é partilhada; duplica-se antes de mexer).
- Sinos e vitrais com as peles aprovadas (`sino_m`, `vitral_alto` /
  `vitral_partido`); props da região colocados à mão (colunas, arcos,
  estátuas de anjo, sino grande da arena, vitrais iluminados, velas,
  candelabros, flâmulas, correntes douradas) com luz fria nos vitrais e
  quente nos sinos — o par LOCKED "lua / ouro".
- **Nave da torre** (só visual, atrás de tudo): o pack de fundo `torre_ecos`
  só cobre a banda de baixo, e acima dela 2700 px de torre ficavam pretos.
  Pilares de pedra do bioma a toda a altura, frisos a marcar os andares e
  janelas altas com luz de lua entre os pilares.
- Todos os props vêm de `assets/sprites/pixel/deco/torres/` pelo nome, e o
  terreno pelo bioma `torres`: quando o PR #1 (arte das Regiões I–III) entrar,
  o N12 herda os props, o terreno e o fundo novos sem mexer na cena.

## Portões — medidos, não estimados

Cada portão (elevador 1, sino A, elevador 2, vitral, coluna de ar, queda,
sino B) foi dimensionado contra o **salto real**: salto duplo medido com a
lógica pura `Movimento` (≈ 246 px) + mantle 32 px + folga, e contra o
`escalar_paredes` (sobe qualquer parede sem limite — uma face de plataforma ao
alcance da cabeça é um atalho). Consequências de desenho:

- a galeria A2 é **fina** (sem face de parede a escalar) e o salão por baixo
  é chão contínuo — um bloco maciço fazia do elevador um enfeite;
- a **Rede** da secção C é tecto do R4: não deixa saltar por cima do vitral
  nem chegar ao fundo da coluna de ar a partir do R4;
- as redes (Balcão, Rede, Varanda D) estão todas abaixo do alcance da face
  da plataforma seguinte.

## Testes

- `tests/test_region03_n12_level.gd` (`TestesRegion03N12`, novo): estrutura,
  guardião, inimigos principais, mecânicas, 3 segredos, ≥ 5 checkpoints,
  **portões contra o salto medido e contra escalar paredes**, vitral sem
  passagem por cima, nenhum inimigo a < 140 px dos elementos de ensino.
- `teste_r3_n12_contrato` (reescrito): já não exige a jornada; prova o efeito
  das badaladas e do vitral **e a física com a Koliani real** — o elevador
  leva-a ao A2 e volta ao chão sem peso, a coluna de ar leva-a acima do C1.
- `teste_r3_n12_portoes_no_crivo` (novo): tirando cada portão da sala, o crivo
  de alcance deixa de chegar à porta — não há caminho alternativo esquecido.
- `tools/verifica_alcance.gd` aprendeu **elevadores** (base e fim de curso;
  num elevador de peso o fim só se alcança a subir nele), **`CorrenteAr`** e
  **`PlataformaSino`**. O N12 passa sem órfãs.
- `tools/verifica_aerion.gd` (CI) passou a correr na arena de QA
  `scenes/qa/ArenaAerion.tscn`, com a mesma geometria da sala antiga.

## Armadilhas registadas

- **`Y_MORTE` = 1200.** Abaixo disso a Koliani morre ("fosso sem fundo"
  global), e a morte faz `reload_current_scene` — num teste isso recarrega o
  próprio corredor de testes e o sintoma é `get_tree()` nulo a meio de um
  `await`, sem mensagem de morte nenhuma. Níveis altos têm de viver acima.
- **Fora do `Main`, a Koliani nasce com a física desligada.** Um teste de
  física tem de fazer `set_physics_process(true)`; sem isso o elevador parece
  "não pegar" e as capturas mostram-na congelada a meio de um salto.
- `tools/verifica_nivel12_visual.gd` (fora do CI) foi escrito para a jornada
  procedural antiga e não se aplica ao N12 autoral.

## Decisão tomada nesta execução: o Sino Vivo

O `ChefeSinoVivo` saiu do N11 em 28 set e ficou por decidir. **Fica fora da
campanha** (cena e script intactos, como recurso): o contrato LOCKED só
admite um confronto na região (Vyrak, N15) e os guardiões intermédios vêm do
roster aprovado (N12 = Autómato do Sino). O "sino gigante" do N14 é um *set
piece* do cenário, não um chefe.

## Por fazer / por decidir

- **Playtest humano**: duração (não medida — só a jogar se sabe), leitura dos
  sinos e do vitral sem texto, dureza da serra B2→B3, TTK do Guardião.
- N13 e N14 ainda são jornada + sala antiga com guardiões fora do contrato
  (`guard.voltaris`, `guard.sacerdotisa_lunar`) — o mesmo tratamento, por
  ordem.
