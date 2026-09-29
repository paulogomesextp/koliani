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

## Arte (sem PNGs editados à mão)

**Passe de arte (29 set, depois do pedido do Paulo "níveis com arte
detalhada, isso é o mais importante")** — a branch do PR #1 (arte das
pranchas) foi integrada por *merge*: o N12 herda o panorama da prancha, o
terreno `torre_ecos` e os props recortados. Por cima disso, o N12 ganhou:

- **Interior da torre** (a parede do fundo, só visual): pilares de cantaria
  a toda a altura, arcadas de galeria a cada andar (o céu vê-se pelos vãos),
  e por cima delas a torre fechada com **vitrais emoldurados em arcos de
  pedra com friso dourado**, rosáceas sobre os pilares e **raios de luz de
  lua** a cair dos vitrais; tochas nos pilares (ouro quente) — o par LOCKED
  "lua / ouro". Antes, acima da banda do panorama, cada ecrã era metade céu
  liso.
- **24 peças novas recortadas da prancha** (`tools/gerar_props_n12_prancha.py`,
  mesmo método do PR #1, ficheiros novos `p_*`): paredes, vitrais, rosácea,
  arcadas, mísulas, lâminas, anéis do vento ascendente, raios de luz, poeira,
  névoa, heras, entulho.
- **Os 9 props que ainda eram formas geométricas** no catálogo `torres`
  (braseiro, memorial, pedra talhada, detritos, velas, janela gótica,
  balaustrada, arco pequeno, corrente do sino) — a `Plataforma` espalha-os
  sozinha e eram os "cubos roxos" que sobravam — passam a vir da prancha,
  com a mesma altura. Era o que o relatório do PR #1 deixou por fazer; vale
  para toda a Região III.
- Mecânicas vestidas com a prancha (tudo **opt-in**, os outros níveis não
  mudam): `CorrenteAr.pele` (anéis de vento a subir, em vez do retângulo),
  `PenduloLamina.textura`, `Serra.textura` (lâmina ornamentada que gira),
  `SinoTorre` com pele esconde também o suporte/corda de placeholder,
  `PlataformaQuebra.pele_terreno` e `ElevadorColuna` usam o **material do
  pack** (`Plataforma.MATERIAL_POR_PACK`) e a capa do terreno — os degraus
  quebradiços leem-se como pedra partida da torre, não como caixas.
- Vento contra: rajadas de partículas + névoa em vez das setas-guia.
- Heras a pender das galerias, entulho nos cantos, poeira de luz nos
  vitrais de jogo, brilho dourado nos sinos.
- Desempenho: as tochas e os vitrais da nave **não** têm `PointLight2D`
  (seriam ~45); o nível fica com 18 luzes, cada uma só custa quando está no
  ecrã.

Da versão anterior mantêm-se: `ElevadorColuna` (`scripts/elevador_coluna.gd`)
— correntes douradas que encurtam, roldana fixa que gira; sinos e vitrais
de jogo com as peles aprovadas; props da região colocados à mão.

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

- Capturas das 4 secções: `docs/qa/n12_autoral/`.

- **Playtest humano**: duração (não medida — só a jogar se sabe), leitura dos
  sinos e do vitral sem texto, dureza da serra B2→B3, TTK do Guardião.
- N13 e N14 ainda são jornada + sala antiga com guardiões fora do contrato
  (`guard.voltaris`, `guard.sacerdotisa_lunar`) — o mesmo tratamento, por
  ordem.
