# N14 autoral — "Campanário" (Região III, Torre dos Ecos)

**Data:** 29 set 2026 · **Branch:** `claude/project-thread-6jbrqw` · **Cena:**
`scenes/levels/Observatorio_Lunar.tscn` (nome de ficheiro legado — mudá-lo
partia saves) · **Gerada por:** `tools/construir_n14_campanario.py` (editar
lá, não no `.tscn`).

Contrato: `docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md`
(N14 — LOCKED), "O Peso dos Ecos": sinos em sequência, plataformas grandes
em oscilação, correntes controláveis, vento vertical (updraft), plataformas
temporizadas; únicos sinos gigantes em movimento, plataformas circulares em
rotação, correntes que mudam de direção, secções ao ar livre com vento;
hazards sinos em queda, vento que empurra, lâminas em cruz; fluxo A–D;
inimigos Monge das Correntes, Sino Flutuante, Corvo do Sino; 3 segredos.

## O que havia antes

Sala antiga do Observatório Lunar com a **Sacerdotisa Lunar** (chefe fora do
contrato — o único confronto da região é o Vyrak, no N15) e um `Coletavel`
a conceder `projetil` (já concedido no N10; a região só concede no chefe).
Saiu tudo. `CHEFE_KEY[13]` passa de `guard.sacerdotisa_lunar` a
`guard.monge_das_correntes` (chave nova nos 6 idiomas; a antiga fica no
i18n, ainda é usada pelo lore dos chefes 64/65).

## O que ficou — a subida ao campanário

Torre feita à mão, 3400 × 3450 px (do chão da base, y 1000, ao topo da
coroa, y −2150). Sobe-se de baixo para cima, de dentro para fora.

| Secção | Onde | O que se faz |
|---|---|---|
| **A** chegada | base da torre (interior) | 2 sinos em queda no corredor, Monge das Correntes, Sino Flutuante; o **1.º baloiço** (laje em duas correntes, 412 px) sobre um fosso de 500 px — ensina a mecânica sem castigo (do fosso sai-se a escalar); Segredo 1 por cima dele |
| **B** sinos em sequência | câmara dos sinos (interior) | Sino 1 acende 4 plataformas temporizadas em escada (7 s) até ao patamar; Sino 2 acende a seguinte (6 s); Sino 3 acende as duas últimas até à **coluna de ar** que sai pelo furo do tecto |
| **C1** ar livre | por cima dos telhados | 2.ª coluna de ar até à laje C1; **2 baloiços grandes** (292 px, 26°, em contrafase) sobre um vão de 940 px, com **vento que empurra** (700) e uma lâmina em cruz a descer; Corvo do Sino; laje C2 com sino em queda |
| **C3** a roda | ar livre | 3 **plataformas circulares** a girar à volta de um cubo com **lâminas em cruz** (raio 190, 10 s por volta); do ponto de cima salta-se para a laje C3; Segredo 2 a oeste do ponto de cima |
| **C4** corrente | ar livre | a **corrente que muda de direção**: tocar o sino de baixo leva-a ao alto, o de cima trá-la de volta |
| **D** sino gigante | sala no topo (interior) | o **sino gigante** a baloiçar (pêndulo de 370 px, dano; passa rente à cabeça da Koliani) por cima do **Guardião = Monge das Correntes elite** (vida 300, escala 1,6); Corvo do Sino; Segredo 3 numa varanda do arco; a porta |

6 checkpoints autorais, 3 segredos, 11 PointLight2D.

**Mobilidade que o desenho respeita** (salto duplo ~246 px, dash, e
`escalar_paredes` sem limite — qualquer face é uma escada):

- a coluna de ar da câmara fica a **480 px** da parede oeste e a 540 da leste,
  debaixo de um tecto contínuo: só as plataformas da 3.ª sequência lá chegam;
- o ar livre (C) não tem paredes — a única é a face exterior da torre (a
  leste), e dela não se chega a nada;
- a laje C3 fica 360 px acima da C2 (fora do salto, e a cabeça não chega à
  aresta de baixo);
- o chão da sala D é fino e está preso à parede leste, 380 px acima da laje
  C3 e a oeste dela nada: só a corrente D lá chega.

## Mecânicas novas (todas opt-in; nenhum outro nível muda)

- `PlataformaBalanco` (`scripts/plataforma_balanco.gd`, herda
  `TumuloElevador`): laje larga em duas correntes paralelas — vai sempre
  deitada, quem vai em cima não escorrega. Para o crivo é um vaivém entre os
  extremos do arco.
- `PlataformaOrbita` (`scripts/plataforma_orbita.gd`): plataforma redonda que
  gira à volta de um cubo, sempre deitada (cadeira de roda gigante). Para o
  crivo é um vaivém vertical (sobe-se em baixo, desce-se em cima).
- `PlataformaSino`: `duracao_solida` (temporizada — a badalada acende-a por N
  segundos e ela pisca no último 1,6 s) e `textura_suporte`.
- `SinoTorre`: pergunta `ao_badalar()` a cada plataforma do grupo antes de a
  alternar (as temporizadas e a corrente respondem).
- `ElevadorColuna.grupo_sino`: corrente controlada pelo sino (cada badalada
  inverte o sentido).
- `CorrenteLateral`: `pele` (o vento da prancha a correr, aditivo, bordas
  esbatidas por shader) e `alfa_pele`.
- `PedraQueda`: `textura` (o sino em queda da prancha).
- `PenduloLamina.area_lamina` (área rectangular — o sino gigante).
- `engrenagem_deco.gd`: `balanco_graus` (sinos de cenário a baloiçar).

## Arte (sem PNGs editados à mão)

`tools/gerar_props_n14_prancha.py` recorta da **coluna N14 do
`level_mechanics.png`**: sino em sequência, plataforma oscilante, correntes,
updraft, plataforma temporizada, sino gigante, plataforma circular, corrente
que muda, sino em queda, vento, lâminas em cruz. Prefixo `c_`.

Interior (A, B, D): cantaria azul-noite com pilares, janelas góticas com a
lua a entrar, sinos da prancha a baloiçar devagar nas traves (e os sinos gigantes pousados ao fundo),
tochas com brilho pintado; lajes grossas com a caixa de engrenagens à vista.
Ar livre (C): o panorama da Torre dos Ecos por baixo, os telhados da base e
da câmara, a face exterior da torre com cunhal de cantaria clara, janelas
acesas e gárgula; bancos de neblina em degradé radial. Primeiro plano:
correntes em silhueta.

Capturas: `docs/qa/n14_autoral/`.

## Testes

- `tests/test_region03_n14_level.gd` (`TestesRegion03N14`): estrutura,
  guardião, inimigos e mecânicas do contrato, e os portões medidos com o
  salto real e contra o escalar paredes (coluna de ar longe das paredes, vão
  dos baloiços, laje C3 fora do salto e da face, chão D preso à parede leste
  e acima da C3, sino gigante por cima do Guardião).
- `teste_r3_n14_sinos` (física, cena inteira na árvore): o Sino 1 acende só
  a 1.ª sequência; nova badalada mantém-na; acabado o tempo apagam-se; o sino
  da corrente leva-a ao alto e o outro trá-la de volta.
- `teste_r3_n14_portoes_no_crivo`: sem a 3.ª sequência, sem a coluna de ar
  da câmara, sem a do telhado, sem cada baloiço, sem a roda ou sem a corrente
  D, o crivo não chega à porta; o nível inteiro chega sem ilhas.

## Decisões tomadas (dúvidas de desenho)

- **O 1.º baloiço não é portão.** Com `escalar_paredes` o fosso A sai-se a
  escalar; em vez de murar o fosso (um nível de ensino que prende é pior),
  o baloiço ensina e leva ao Segredo 1. O crivo confirma: tirá-lo só deixa o
  segredo órfão.
- **A 1.ª sequência contorna-se a escalar a parede leste** até ao patamar B1
  (é o mesmo destino). O portão real da câmara é a 3.ª sequência.
- **O sino gigante usa o recorte "sino em sequência" a 1,5×**: o recorte
  "sino gigante" da prancha traz os pilares ao lado (fica pousado ao
  fundo, como cenário).

## Armadilhas registadas

- O recorte `p_neblina` tem a aresta de baixo dura: no ar livre via-se o
  rectângulo. A neblina do N14 é o degradé radial esticado.
- A pele do vento aditiva com o rectângulo da área inteira lia-se como uma
  caixa azul: bordas esbatidas por shader e alfa 0,24.
- Fundos de laje (`Massa`) com o degradé do N13 (até 0,9) ficam buracos
  pretos contra o céu: no N14 o degradé vai só até 0,68 e a casca é mais
  clara.
- `laje(..., base)` tem de ficar abaixo do fundo do fosso, senão o
  `RectangleShape2D` sai com tamanho negativo.

## Por fazer / por decidir

- Playtest humano: tempo das temporizadas (7/6 s) no telemóvel, leitura do
  empurrão do vento sobre os baloiços, a roda (ritmo de 10 s), TTK do
  Guardião debaixo do sino.
