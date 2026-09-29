# N13 autoral — "Mecanismos Antigos" (Região III, Torre dos Ecos)

**Data:** 29 set 2026 · **Branch:** `claude/project-thread-6jbrqw` · **Cena:**
`scenes/levels/Torre_da_Tempestade.tscn` (nome de ficheiro legado — mudá-lo
partia saves) · **Gerada por:** `tools/construir_n13_mecanismos.py` (editar
lá, não no `.tscn`).

Contrato: `docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md`
(N13 — LOCKED), "O Coração da Torre": rodas de engrenagem, sinos com padrão,
alavancas múltiplas, plataformas rotativas, pontes reconfiguráveis; únicos
mecanismo central de 3 sinos, pontes móveis, engrenagens giratórias,
contrapesos; hazards engrenagens mortais, piso que colapsa, correntes com
peso, lâminas em pêndulo; fluxo A–D; inimigos Autómato do Sino, Construto
Vitral, Espírito do Eco; paleta metal antigo / ouro envelhecido; 3 segredos.

## O que havia antes

Jornada procedural (câmaras do `gerador_corredor.gd`) a acabar na sala antiga
com o **Voltaris** (chefe de tempestade, fora do contrato). Saiu tudo;
`CHEFE_KEY[12]` passa de `guard.voltaris` a `guard.construto_vitral`
(chave nova nos 6 idiomas).

## O que ficou — três andares de maquinaria

Sala feita à mão, 3600 × 2250 px, como o mapa do N13 no `layout_usage.png`:
três andares empilhados, separados por lajes **grossas** (250 px), e só se
sobe pelos elevadores de contrapeso, **sempre depois de uma porta**.

| Andar | Secção | O que se faz |
|---|---|---|
| 1 (→) | **A** introdução | 1.ª alavanca abre a 1.ª grade de bronze, sala sem inimigos |
| 1 (→) | **B** sala das engrenagens | fosso de 800 px (espinhos + serra-engrenagem) atravessado nos braços de 2 engrenagens em cruz, com poleiro no meio (ritmo das engrenagens canónicas do N56); Segredo 1 do cimo de um braço |
| 1 (→) | **B** alavancas múltiplas | a porta B exige as DUAS alavancas (chão + varanda); pelo meio, piso que colapsa sobre fosso e 2 lâminas em pêndulo; Autómato do Sino; elevador de contrapeso (peso) |
| 2 (←) | **C1** pontes reconfiguráveis | fosso de 650 px sob **tecto baixo** (110 px de folga: sem arco de salto); pisar a alavanca do pilar troca a ponte sólida pela fantasma; Espírito do Eco |
| 2 (←) | **C2** ponte móvel | laje num carro que corre num trilho do tecto sobre fosso de 560 px; 2 correntes com peso a baloiçar |
| 2 (←) | **C3** | alavanca C numa prateleira a 330 px (só do braço de uma engrenagem); Construto Vitral; Segredo 2; elevador em vaivém |
| 3 (→) | **D1** | piso que colapsa + 2 lâminas + 2 Espíritos |
| 3 (→) | **D2 núcleo** | o **mecanismo de 3 sinos**: com a Koliani perto toca o padrão sozinho (os sinos brilham e soam por ordem); tocá-los pela mesma ordem liga o núcleo e abre a porta do guardião; errar apaga tudo e o eco repete. Segredo 3 por cima do estrado |
| 3 (→) | **D3** | Guardião = Construto Vitral elite (vida 280) sela a porta |

6 checkpoints autorais, 3 segredos, 12 PointLight2D (o N12 tem 18).

**Mobilidade que o desenho respeita** (a Koliani já tem salto duplo, dash e
`escalar_paredes`): nenhuma superfície por baixo de um furo de laje; as
travessias "só com mecanismo" têm vãos de 400+ px ou tecto baixo; as portas
vão do chão ao tecto; a prateleira C está fora do salto **e** da face (a
cabeça não chega à aresta de baixo). Cada fosso tem espinhos no fundo e
degraus de serviço dos dois lados: cair custa vida, nunca prende.

## Mecânicas novas (todas opt-in; nenhum outro nível muda)

- `MecanismoSinos` (`scripts/mecanismo_sinos.gd`, herda `Alavanca`): lê a
  ordem das badaladas, ensina-a com o eco, liga-se como uma alavanca (as
  `PortaTrancada` do mesmo `id` abrem sem código novo).
- `SinoTorre`: sinal `badalada` + `brilhar()`.
- `Alavanca`: `textura` (a alavanca da prancha), `alterna_grupo` (troca
  plataformas como a badalada do sino).
- `PlataformaSino.comeca_solida` (a ponte que começa sólida).
- `PortaTrancada`: `textura`/`textura_moldura` — grade levadiça de barras de
  metal dourado e cintas de bronze (nada esticado).
- `PlataformaRoda`: `textura_roda` / `textura_braco`.
- `PlataformaCorrente`: `pele_terreno`, `textura_corrente`, `ancora_no_trilho`.
- `ElevadorColuna`: contrapeso da prancha que desce quando a plataforma sobe.
- `PenduloLamina`: `textura_haste` + `textura_lamina` (corrente em mosaico e
  lâmina a escala fixa — uma textura esticada ficava gigante).
- `engrenagem_deco.gd`: engrenagem de cenário a rodar.

## Arte (sem PNGs editados à mão)

`tools/gerar_props_n13_prancha.py` recorta da **coluna N13 do
`level_mechanics.png`** e do atlas: roda, sino com padrão, mecanismo
central, ponte móvel, engrenagem, contrapeso, engrenagem mortal, corrente
com peso, lâmina de pêndulo, alavanca, interruptor, mecanismo de sino,
porta, elevador, ponte reconfigurável, plataforma rotativa, e as amostras
**"Texturas e materiais"** (metal dourado, bronze envelhecido, madeira,
correntes) para repetir em mosaico. Prefixo `m_`.

Interior: cantaria azul-noite; em cada vão entre pilares **ou** uma janela
gótica com arco e raios de lua **ou** uma máquina de ouro velho a rodar
(engrenagens em sentidos opostos) com correntes a pender; tochas com brilho
pintado (sem luzes 2D); sombra a descer do tecto; lajes com o miolo a
escurecer para baixo (só a capa e a aresta leem) e, nas lajes largas, uma
**caixa de engrenagens** à vista (recesso com carris de metal dourado e
engrenagens a rodar) — o chão de cada andar lê-se como máquina; silhuetas escuras em
primeiro plano; adereços de oficina no chão. Set pieces da prancha: sala das
engrenagens (roda grande + 2 pequenas engrenadas), pontes móveis (trilho e
carro), mecanismo central (grande roda dourada com o vitral azul no cubo,
que acende à medida que o padrão entra).

Capturas: `docs/qa/n13_autoral/`.

## Testes

- `tests/test_region03_n13_level.gd` (`TestesRegion03N13`): estrutura,
  guardião, inimigos, mecânicas do contrato, e as travessias medidas com o
  salto real (fossos > 480 px, folga do tecto baixo, prateleira C fora do
  salto e da face, elevadores depois das portas, portas até ao tecto).
- `teste_r3_n13_mecanismos` (física, cena inteira na árvore): alavanca →
  porta; porta B só com as duas; alavanca das pontes troca as pontes; sino
  fora de ordem apaga; padrão certo liga o núcleo e abre a porta.
- `teste_r3_n13_elevadores_no_crivo`: sem cada elevador o crivo de alcance
  não chega à porta; o nível inteiro chega sem ilhas.

## Armadilhas registadas

- A casca (paredes e telhado) é `StaticBody2D` e **não** `Plataforma`: senão
  o crivo conta-as como ilhas órfãs.
- `ElevadorColuna` não pode ter uma variável `_peso` (já existe no
  `TumuloElevador`, é o contador de quem está em cima).
- A cena `PlataformaSino.tscn` traz o `Col` desligado e o `Visual` ténue:
  `comeca_solida` tem de os acender aos dois.

## Por fazer / por decidir

- Playtest humano: leitura do padrão dos sinos (o eco chega?), ritmo das
  engrenagens no telemóvel, dureza do tecto baixo das pontes, TTK do
  Guardião.
- O crivo de alcance não modela engrenagens nem a ponte móvel: vê o caminho
  pelos fundos dos fossos (degraus de serviço). A thread do crivo está a
  acrescentar a `PlataformaCorrente`.
