# Execution 9H.7 — Região I: nitidez do fundo + conclusão do conteúdo dos níveis

Data: 12 de setembro de 2026. Estado: **PASS**. Versão `0.18.1`.
Base: `origin/master` = `64a57f5`. Região II **não iniciada**.

Âmbito: só os dois pontos que o Game Master deixou abertos — (A) o fundo
desfocado e (B) os níveis 1–5 sem tudo o que a região tinha planeado. Não se
tocou em intro iPhone, soundtrack/SFX do menu, Região II, equilíbrio dos
chefes, combate, editor de toque nem áudio geral. Não se fez reauditoria
global.

## A. Nitidez do fundo

### Causa-raiz (medida, não suposta)

Duas causas somadas, ambas no fundo da Região I:

**A1 — ampliação bilinear.** Cada camada de fundo é desenhada com
`TEXTURE_FILTER_LINEAR` a partir de pinturas pequenas (o panorama da prancha
08 tem 952×247; as peças do kit 9C 50–200 px), com uma escala no mundo que,
vezes o zoom 1,4 da câmara, dá a ampliação real no pixel do ecrã. Ampliação
bilinear é interpolação: quanto mais se amplia, mais macia fica. Medido:

| Camada | escala no mundo | ampliação no ecrã (antes) |
|---|---|---|
| `BackgroundApproved08` | 1,5 (sobre o `_x2` da 9H) | **2,1** |
| `Camada3Distante` serra | 2,2 | **3,08** |
| `Camada3Distante` cascatas/arcos | 1,8–2,2 | 2,52–3,08 |
| `Camada2Floresta` árvores | 2,0–2,4 | 2,8–3,36 |
| `Camada2Floresta` ruínas/cascatas | 2,0–2,6 | 2,8–3,64 |
| `PrimeiroPlano` vegetação | 2,4 | **3,36** |
| `NevoaMedia` | 3,0 | 4,2 (névoa; macio é o desejado) |

A 9H tratou **só o panorama** (4,2 → 2,1, com um `_x2` em disco) e deixou a
serra, as árvores, as ruínas, as cascatas e o primeiro plano — que são a
maior parte do ecrã — nos 2,5–3,6. Daí a queixa persistir.

**A2 — o shader de nitidez atirava o `modulate` fora.** O `COLOR` de um
shader `canvas_item` já vem multiplicado pelo `modulate` do nó e de todos os
pais. O `nitidez_fundo.gdshader` da 9H terminava em `COLOR = c;` com `c` a
sair só da textura, e **ninguém punha nada no uniforme `tinta`** que lá
estava para substituir esse papel. Consequência desde a 9H: o fundo da Região
I era desenhado **sem** a tinta de mood da 08, **sem** os −18 % da camada mais
funda e **sem** os alfas das camadas (0,82 na 3 e 0,6 na 2 — o alfa que
existe para a silhueta das árvores não apagar as arestas de pouso). O azul
saturava e ceifava (medido: B = 255 em zonas inteiras do L5).

### Correção

- `tools/nitidez_fundo_9h7.py` — amplia **no disco**, ao fator exacto a que
  cada camada desenha: panorama e caps **×4**, peças do kit **×3**. Lanczos
  sobre alfa **premultiplicado** (sem isso as silhuetas ganham halo), máscara
  de desfoque só na cor e com a imagem orlada por replicação, raio = fator.
  Não pinta, não gera, não recompõe, não recolore; os originais ficam.
  Manifesto com SHA por peça: `…/production/nitidez_9h7_manifest.json`.
- Quem monta divide a escala pelo mesmo fator (`Kit.HD`, `Kit.tex_hd`), pelo
  que **a geometria no mundo não muda** (4 × 0,75 = 3; 3 × e/3 = e) e a
  composição aprovada fica no sítio ao pixel. `region_rect` convertido para
  a textura HD em `_regiao`.
- `nitidez_fundo.gdshader` — o `modulate` é apanhado no estágio de **vértice**
  (`varying vec4 modulacao; void vertex() { modulacao = COLOR; }`) e reposto
  no fim (`COLOR = c * modulacao`). Pelo vértice e não por um `MODULATE` no
  fragmento porque esse built-in **não existe nesta versão** (dá "Unknown
  identifier"; confirmado em runtime).
- `_nitidez` passou a receber a ampliação **no pixel do ecrã** e a força
  desceu de 0,35–1,05 para 0,12–0,35: a ~1:1 já não há softness de
  reamostragem para combater, e a força antiga desenhava halo.
- **Emenda escura do panorama corrigida.** O recorte da 6A (caixa
  18,97,952,247 na prancha 08) leva **uma coluna da moldura do painel** em
  cada lado: luminância média 55 na coluna 0 contra 148 na coluna 1, e 19
  contra 27 nas da direita. As pontas do panorama são espelhadas e encostadas
  uma à outra, portanto essa coluna aparecia **a dobrar** — ampliada dava uma
  risca vertical escura de ~6 px, visível no L5. Antes da 9H.7 estava
  escondida dentro do azul ceifado (A2). O produtor repete o pixel aprovado
  do lado (`_reparar_borda`): a caixa e o tamanho ficam iguais, a composição
  não se move, e não se inventa nenhum pixel.

### Resultado medido

Ampliação no pixel do ecrã, por nível (`tools/auditoria_fundo_9h7.gd`):

| | mediana antes | mediana depois | máximo depois |
|---|---|---|---|
| L1 | ~2,8 | **1,05** | 1,56 |
| L2 | ~2,8 | **1,10** | 1,49 |
| L3 | ~2,8 | **1,08** | 1,57 |
| L4 | ~2,8 | **1,05** | 1,58 |
| L5 | ~2,8 | **1,10** | 1,58 |

O máximo que sobra são os cristais maiores (3,4/3 × 1,4) e a névoa (1,4) — e
a névoa é névoa. Emenda do L5 medida coluna a coluna: era um vale a
(7, 3, 10) contra (46, 122, 255) à volta; ficou plano a ~(12, 48, 107).

**Filtro mantido em LINEAR e não trocado para Nearest**: a arte é pintada,
não pixel-art, e a ~1:1 o bilinear é quase passagem directa, enquanto o
Nearest daria cintilação a cada subpixel de parallax.

## B. Conteúdo dos níveis 1–5

Autoridade: prancha **08** (`Koliani_1.0_Master_Package_v2/references/approved/08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png`,
1536×1024, SHA `840cfd82…`), kit **9C**, e os relatórios 9C/9D+9E/9F/9G/9H.
Nada de biomas, mecânicas, personagens ou props novos.

### Lacuna estrutural: metade do vestuário caía fora do ecrã

As peças eram espalhadas por intervalos escritos à mão (`referencia.x ± 2600`
a `± 3200`) que não sabem onde o nível começa nem acaba. Com fator 0,26 e o
nível de −2550 a 3850, a câmara só chega a ver o local **[286, 2864]**:
**metade das peças era pousada onde não se pode ver**, e a outra metade tinha
de encher o ecrã inteiro sozinha. `_banda(f)` calcula agora o intervalo local
que a câmara percorre de ponta a ponta do nível, e as quantidades passaram a
**densidades por 1000 px** dessa faixa. É a razão principal de os níveis
parecerem vazios.

### O que estava em falta e foi montado (tudo com autoridade na 08)

| Elemento da prancha | Estado antes | Agora |
|---|---|---|
| Vinhas a emoldurar o ecrã ("exemplo em jogo") | só por baixo das plataformas (`Kit.pendurar`), quase invisíveis | `VinhasFrente`, 20–22 por nível, penduradas do topo (x do mundo, y colado ao topo do ecrã) |
| Aglomerados de cristal de corrupção a média distância | só props de chão | `Camada2Corrupcao` (fator 0,52, alfa próprio): 4 → 6 → 9 → 11 → **17** de L1 a L5 |
| "Raios de Luz (volumétricos)" (EFEITOS ATMOSFÉRICOS) | a 9C escondeu o `Raios` legado e **não pôs nada no lugar** | `RaiosLuz`: 4 feixes aditivos colados ao ecrã, graduados para o luar da 08, intensidade pela névoa |
| Ruínas dominantes no L3 ("Ruínas Antigas") | 6 arcos + 4 ruínas para 5200 px, meio fora do ecrã | **23 + 29** peças na faixa; L3 é o pico medido |
| Cascatas dominantes no L4 ("Cascatas e Abismos") | 1 cascata visível | **27** peças na camada 3; L4 é o pico medido |
| Heart Tree no L5 ("Heart Tree Próximo") | coluna fixa no mundo: chegava-se ao chefe sem a ver | `landmark_visto_em = 3060` (a arena) — a árvore fica ao centro do ecrã sobre o combate |

Ajustes finos: ruínas da camada 2 de `0,62` para `0,72` de luz (a silhueta
azul-escura perdia-se contra o azul do panorama, e o L3 é o nível em que ela
tem de ser o que se lê); árvores da camada 2 mais juntas (0,72–1,24 da
largura em vez de 0,9–1,6); vinhas graduadas para silhueta
(`0,42/0,48/0,64`) — as peças do kit foram graduadas para o **chão**, ao lado
das lanternas, e penduradas ao luar aquele verde-lima lia-se como vegetação
iluminada.

### Progressão, medida (peças montadas por nível)

| | L1 | L2 | L3 | L4 | L5 |
|---|---|---|---|---|---|
| corrupção (camada própria) | 4 | 6 | 9 | 11 | **17** |
| camada 3 (distante) | 16 | 19 | 23 | **27** | 18 |
| camada 2 (floresta/ruínas) | 19 | 19 | **29** | 26 | 21 |
| vinhas do primeiro plano | 22 | 22 | 22 | 22 | 20 |

Cada nível tem a sua variante da 08 a ler: L1 entrada, L2 o mesmo com névoa a
0,95, L3 ruínas no pico, L4 cascatas no pico, L5 corrupção no pico com a
Heart Tree sobre a arena.

### Não mexido (por instrução)

Colisões, geometria jogável, checkpoints, progressão, comportamento dos
inimigos, lógica dos chefes, save e movimento da Koliani: **nenhuma
alteração**. O único `.tscn` tocado é o do L5, e só para lhe acrescentar
`landmark_visto_em` (uma propriedade de apresentação).

## C. Legado visual que fica

- **LEGACY CC0 TERRAIN VISIBLE IN REGION I: NO** (teste da 9C mantém-se).
- Ficam, justificados e fora de âmbito (os mesmos da 9C): céu em degradé da
  `Atmosfera`, `CanvasModulate`, grade, vinheta, `Poeira`, e a arte própria
  dos objectos de gameplay (água venenosa, checkpoints, portas, alavancas,
  teias, pedras) — são leitura de perigo.
- O `Raios` legado da `Atmosfera` continua escondido; o efeito foi reposto
  pelo `RaiosLuz` da 9H.7, colado ao ecrã (o legado tinha 2–3 polígonos em
  posições fixas do mundo perto de x 180–620, invisíveis num nível de 6400).
- `region1_panorama_*_x2.png` (a 9H) ficam em disco mas **já não são
  carregados**; o produtor da 9H continua no repo como registo.

## D. PRODUCTION ASSET MISSING

- **Chuvisco / Chuva (variante)** — está nos EFEITOS ATMOSFÉRICOS da 08, mas
  a prancha marca-o "(variante)" e não há peça no kit 9C. Não improvisado.
- Nada mais em falta para os cinco níveis: o resto do que a 08 mostra está
  montado.

## E. Desempenho

Tempo de frame por **relógio de parede** (o `delta` do motor mente), vsync
desligado, 240 frames por nível, janela 1280×720:

| | média | p95 | draw calls |
|---|---|---|---|
| L1 | 1,03 ms | 1,70 ms | 70 |
| L2 | 0,79 ms | 1,27 ms | 69 |
| L3 | 0,77 ms | 1,19 ms | 70 |
| L4 | 0,82 ms | 1,25 ms | 72 |
| L5 | 0,97 ms | 1,44 ms | 72 |

Orçamento de 16,7 ms para 60 fps. Draw calls +~10 face à 9C (49–62), pelas
peças novas. Texturas: o panorama ×4 são 3808×988 e os caps 1280×988 e
1288×988 — ~25 MB de VRAM na camada mais funda, contra ~14 MB do ×2 da 9H.
**Medido em PC (RTX 5070), não em telemóvel**: o trabalho é meia dúzia de
quads grandes, portanto limitado por preenchimento, e vale a pena confirmar
num aparelho antes de dar o caso por fechado.

## F. Testes

- Suite completa headless: **OK — todos os testes passaram**.
- Teste dirigido novo `teste_execution_9h7_fundo_regiao1`: nenhuma peça de
  fundo acima de 1,6× no ecrã; ≥ 20 peças em HD por nível; `VinhasFrente` e
  `RaiosLuz` montados nos cinco; corrupção a escalar até ao L5 com mínimo
  absoluto; L3 no pico das ruínas e L4 no das cascatas, ambos com mínimo;
  manifesto do produtor com ≥ 21 peças; e o shader a repor o `modulate`.
- **As asserções morderam** (mutação, uma a uma): `tex_hd` a devolver `null`
  → falha a 4,68× ("só tem 5 peças em HD"); shader de volta a `COLOR = c`
  → falha; densidade dos cristais a 0,4 → falha; densidade dos arcos a 0,6
  → falha; ambas as densidades de cascata a ~0 → falha. A primeira versão da
  asserção da corrupção **passava por vacuidade** (com o L1 a zero, "L5 > 2 ×
  L1" é verdade com um cristal) e foi corrigida com um mínimo absoluto.
- Validador do produtor: `python tools/nitidez_fundo_9h7.py --validar` →
  21/21 (tamanho = fator × original, RGBA).

## G. Prova visual

- `work/9h7/9h7_antes_depois.png` — os cinco níveis, antes/depois, recorte da
  janela de fundo, mesmo enquadramento de jogo (`--nivel=N --foto=`).
- `work/9h7/9h7_niveis.png` — os cinco níveis a 15/40/65/90 % da largura: é
  aí que a identidade de cada um se vê, porque no ponto de partida a
  geometria tapa quase todo o fundo.
- `work/9h7/auditoria_depois.json` — contagens, ampliações e tempos de frame.

## H. Armadilhas de método (para a próxima sessão)

- **O ponto de partida de cada nível é o pior sítio para julgar o fundo**: a
  geometria (duas colunas de terreno) tapa 45 % do ecrã. Fotografar a
  15/40/65/90 % da largura, com a câmara pousada à mão.
- **Um shader de `canvas_item` que escreve `COLOR = <textura>` apaga o
  `modulate` de toda a cadeia** e não avisa. Se uma camada parece ignorar a
  tinta ou o alfa, é o primeiro sítio a olhar.
- **`MODULATE` no fragmento não existe nesta versão do Godot** — apanhar o
  `COLOR` no `vertex()` para um `varying`.
- **Uma asserção de progressão pode passar por vacuidade** se o extremo de
  baixo chegar a zero: pôr sempre um mínimo absoluto ao lado da razão.
- Os PNG `_hd_x*` são derivados: regeneram-se com
  `python tools/nitidez_fundo_9h7.py` e verificam-se com `--validar`. Ao
  mexer numa escala de desenho, mexer no fator do produtor a par.
