# Execution 9C — Região I: kit de ambiente de produção + integração no runtime

Data: 11 de setembro de 2026. Estado: **PASS**.

**KOLIANI PRODUCTION GATE = CLOSED** (não tocado). **REGION I ENVIRONMENT GATE =
CLOSED.** Pronto para 9D (inimigos/guardiões): **SIM**.

## A. Git no início

`master` = `origin/master` = `75be355`. Trabalho alheio preservado: o
`project.godot` tinha uma reordenação feita pelo editor (ui_accept/ui_cancel e
um comentário do ETC2) — **não entrou em nenhum commit**; a subida para 0.15.18
foi posta no índice como blob feito a partir de `HEAD:project.godot`, só com a
linha `config/version`. Master packages, `.worktrees/`, `work/` e o kit
`imagegen_v1` não rastreado ficaram intactos.

## B. Autoridade

| | Caminho | Tamanho | Modo | SHA-256 | Manifesto |
|---|---|---|---|---|---|
| **Autoridade da região** | `Koliani_1.0_Master_Package_v2/references/approved/08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png` | 1536×1024 | RGB | `840cfd8241a54f7bab0be58ab96892eba8438517888e490587451339b23263a7` | bate |
| Estrutural | `…/approved/10_PRODUCTION_PACK_v8_ENV_LIGHT_ATMOSPHERE.png` | 1536×1024 | RGB | `86087e523990a882f2c23c98596265e5afbd5567dfd0c3be02399ecdf0b7b6f6` | bate |

O produtor volta a verificar os dois SHA contra o `references/manifest.json`
em cada execução e **recusa-se a correr** se não baterem. A 10 chama-se
"Floresta Sagrada" e é de dia: tudo o que vem dela é graduado para a noite da
08 (a 08 manda). Da 10 **não** se tirou nada que a 08 não tenha — a árvore
verde "sagrada", as ilhas flutuantes, a bandeira com cruz e o altar ficaram de
fora.

## C. Inventário

### O que havia antes

| Domínio | Autoridade | Asset de produção? | Legado? |
|---|---|---|---|
| terreno (topo/corpo/lado/base) | 10 (08 manda) | não | **sim** — 4 peças CC0 *anokolisa* (`assets/sprites/pixel/terreno/floresta/`) |
| props de chão / pendurados | 10 | não | **sim** — 17 props CC0 (`deco/floresta/`) |
| fundo | 08 | panorama + Heart Tree (**B**, 6A) | **sim** — pack CC0 `floresta` (3 camadas) + silhuetas por polígono |
| primeiro plano, névoa, raios | 08 | não | **sim** — polígonos da `Atmosfera` e do visual 5C |
| corrupção | 08 | não | polígonos desenhados à mão no L1 |
| plataforma flutuante (L2) | 10 | não | trapézio `Polygon2D` chapado |

### O kit `imagegen_v1` (as 12 peças da 9A, classe E) — **NÃO promovido**

`assets/art/regions/region_01_forest/production/{terrain,overlays,props}/`, 12
PNG de 32×32 (64/96 nas plataformas), RGBA, alfa real, validados tecnicamente.
Não foram promovidos porque **se afastam visivelmente da 08** (condição D): o
musgo é amarelo-lima em todas as pedras e a pedra é ruído a 32 px, onde a 08
tem pedra azul-cinza com musgo verde sobretudo no topo, a ~13 px por pedra para
uma Koliani de 60. Ficam como estão (não rastreados, não apagados).

### Kit 9C — 31 peças produzidas

Produtor: `tools/produzir_kit_regiao1_9c.py`. Saída:
`assets/art/regions/region_01_forest/production/kit_9c/` com
`kit_9c_manifest.json` (por peça: prancha, SHA da prancha, caixa exacta na
prancha, operações, tamanho, SHA do PNG, uso). Prancha de revisão:
`work/execution_9c/kit_9c_contacto.png`.

Operações permitidas, e mais nenhuma: recorte sem perdas a 1× da prancha; alfa
binário por chave de cor contra o fundo liso do painel; remoção da auréola do
painel por inundação a partir da borda; graduação 10→08 (transferência de
média/desvio por canal medida no terreno do "exemplo em jogo" da 08, força
0,65; 0,3–0,45 nas peças com chama/bioluminescência, para a luz quente não
morrer); cross-fade da própria borda nas peças que se repetem.

## D. Kit da Região I

| Categoria | Peças (`kit_9c/…`) | Fonte |
|---|---|---|
| A. Terreno | `terreno/terreno_topo`, `terreno_topo_erva`, `terreno_corpo`, `terreno_lado`, `terreno_base` | 10 "CHÃO" (topo/lado/base/erva) e "PAREDES" (corpo), graduado |
| B. Natural | `props/plantas`, `cogumelos`, `rocha`, `raizes`, `planta_luminosa`, `vinha_a`, `vinha_b`, `vinha_longa` | 10 "Elementos naturais" + "Variações" |
| C. Ruínas / luz | `props/ruina`, `props/lanterna`, `props/tocha`; `fundo/fundo_arco_ruina` | 10 "Elementos de cenário"; 08 "Elementos de parallax" |
| D. Água | `props/cascata`; `fundo/fundo_cascata`, `fundo_colunas_cascata` | 10; 08 |
| E. Corrupção | `corrupcao/cristal_corrupcao_a…d`, `faisca_corrupcao` | 08 "Exemplo em jogo" (chave de matiz magenta) e "Partículas de Corrupção" |
| F. Profundidade | `fundo/fundo_montanhas`, `fundo_arvores_par`, `fundo_arvore_a`, `fundo_arvore_b`, `frente_vegetacao` | 08 "Elementos de parallax" e "Camada 1" |
| F. Landmark | panorama + Heart Tree (6A, já de produção) | 08 "Panorama principal" |
| G. Atmosfera | `atmosfera/nevoa` | 08 "Névoa (foreground/midground)" |

**Validação técnica** (`python tools/produzir_kit_regiao1_9c.py --validar`):
**31/31 PASS** — PNG legível, RGBA, SHA/tamanho = manifesto, transparência real
(o corpo do terreno tem de ser opaco), nada cortado na borda, sem xadrez cozido,
sem linhas lisas de separador. As caixas evitam os rótulos de texto das
pranchas (conferido na prancha de revisão). Não se aplicaram as regras de
baseline/pivot de personagem do validator v2 — não se aplicam a cenário.

Primeira passagem apanhou 2 FAIL legítimos (a névoa e a faísca não tinham alfa
0 em lado nenhum) e 3 defeitos visuais (auréola escura do painel nas peças com
chama, costura na serra, filete da moldura na banda de primeiro plano) — todos
corrigidos no produtor, não à mão.

## E. Integração por nível

Um só interruptor: o nó `Region1HybridVisualTarget` (já presente nos 5 níveis)
entra no grupo `regiao1_kit` no `_enter_tree`; `plataforma.gd` e
`plataforma_flutuante.gd` perguntam pelo grupo e usam o kit. Sem esse nó — os
outros 95 níveis, 11 dos quais também usam o bioma `floresta` — tudo fica como
estava (há teste). `perfil` = variante de cenário da 08:

| Nível | Perfil (mood 08) | Terreno | Fundo | Props | Atmosfera | Corrupção |
|---|---|---|---|---|---|---|
| L1 Floresta Putrefata | 1 Entrada | kit | 4 camadas + primeiro plano | kit; lanternas 0,35 | névoa 0,55 | 0,25 |
| L2 Pântano dos Sussurros | 1 Entrada | kit (+ flutuantes do kit) | idem, mais cascatas | idem | névoa **0,95** | 0,35 |
| L3 Ninho da Viúva Negra | 2 Ruínas | kit | arcos/ruínas dominantes | lanternas 0,45 | 0,6 | 0,5 |
| L4 A Árvore que Chora | 3 Cascatas | kit | cascatas dominantes | idem | 0,75 | 0,6 |
| L5 Coração da Floresta | 4 Heart Tree | kit | tinta "coração" | mais cristais | 0,6 | **1,0** |

A tinta do panorama por nível é a razão medida (média da tira de mood da 08 /
média do panorama), aplicada a 35%. Geometria, colisões, checkpoints,
inimigos, rotas e mecânicas: **nenhuma alteração** (as 5 cenas só ganharam
`perfil = N`).

## F. Legado

**LEGACY CC0 TERRAIN VISIBLE IN REGION I: NO.** (teste: o `ChaoInicio` do L1
tem ≥ 4 texturas `kit_9c` e 0 de `pixel/terreno`).

Escondido em runtime na Região I (medido nos 5 níveis):
`Parallax/Fundo, Longe, Meio, Perto, PropsRegiao`, `FrenteAmbiente`, `Raios` da
`Atmosfera`. Os polígonos de névoa/corrupção e as 3 PointLight2D do visual 5C
foram retirados do L1.

Dependências legadas que **ficam, justificadas**: o céu em degradé da
`Atmosfera` (só se vê acima do panorama), a `CanvasModulate`, a grade e a
vinheta (luz do nível já aprovada; mexer-lhes recolore a Koliani), a `Poeira`
(partículas), e os objectos de gameplay com arte própria (água venenosa,
checkpoints, portas, alavancas, teias, pedras) — fora do âmbito, são leitura de
perigo e ficam para a 9D/depois. Os ficheiros legados não foram apagados.

## G. Parallax / atmosfera

Parallax feito à mão (`posição = desvio da câmara × (1 − fator)`, sem
interpolação física, no `_process`):

| Plano | Nó | Fator | Conteúdo |
|---|---|---|---|
| 4 | `BackgroundApproved08` | 0,12 / 0,08 | panorama 3× + caps, Heart Tree ao centro do nível, −18% de luz |
| 3 | `Camada3Distante` | 0,26 / 0,16 | serra contínua, cascatas, arcos |
| 2 | `Camada2Floresta` | 0,46 / 0,30 | árvores em silhueta (alfa 0,6), ruínas e cascatas da 10 |
| — | `NevoaMedia` | 0,6 / 0,4 | névoa da 08 em mosaico |
| jogo | plataformas do kit; `NevoaChao` **atrás** do terreno (z −6) | — | nunca tapa uma aresta |
| 1 | `PrimeiroPlano` | 1,15 / 1,0 | vegetação da 08, assente 40 px abaixo da superfície da poça mortal mais alta |

Luz: lanternas e tochas com halo **aditivo** (um quad), não PointLight2D — uma
luz de canvas tingia a pele da Koliani ao passar (o problema da 9B.3). A
Koliani não é tocada por nenhum nó novo. Corrupção (magenta/violeta/preto)
continua separada do violeta limpo da Shadowblade.

## H. Desempenho

Janela real, vsync desligado, 240 frames por medida, kit ligado vs `ativo =
false` (o rollback):

| Nível | kit média / p95 (ms) | legado média / p95 | draw calls kit / legado |
|---|---|---|---|
| L1 | 0,53 / 0,70 | 0,42 / 0,59 | 49 / 68 |
| L2 | 0,53 / 0,76 | 0,44 / 0,63 | 50 / 75 |
| L3 | 0,52 / 0,72 | 0,43 / 0,63 | 53 / 67 |
| L4 | 0,56 / 0,78 | 0,42 / 0,62 | 62 / 70 |
| L5 | 0,52 / 0,70 | 0,44 / 0,67 | 54 / 74 |

+0,1 ms por frame (sobretudo overdraw das camadas com alfa) para um orçamento de
16,7 ms; **as draw calls descem** (o legado eram centenas de polígonos).
Regressão: **NÃO**. Texturas novas: a maior é a banda de primeiro plano,
942×67. Nenhuma alocação por frame; o `_process` escreve 5 posições.

## I. Testes

- produtor/validador do kit: 31/31 PASS;
- suite headless: **OK — todos os testes passaram**, com
  `teste_execution_9c_kit_ambiente_regiao1` (kit no L1, camadas da 08
  presentes, plataforma fora da Região I continua no legado — o caso negativo
  prova que a asserção discrimina — e manifesto com ≥ 30 peças) e o teste da
  Execution 8 atualizado (os 5 níveis com `perfil` 1..5);
- L1–L5: smoke headless sem erros de script; carregados em janela, 3 pontos
  cada.

**Armadilha de método:** o `run_tests.gd` é um nó de cena, não um `SceneTree`
— `get_root()` dá parse error e o Godot **pendura** sem sair (10 min perdidos).
É `get_tree().root`. Correr sempre a suite com `timeout`.

## J. Evidência de runtime

- `work/execution_9c/evidencia_runtime_9c.jpg` — folha 5×3 (L1–L5 a 15/50/85%
  da largura, Koliani pousada em plataformas reais): terreno de produção,
  camadas de parallax, Heart Tree, ruínas/cascatas, névoa, cristais, lanternas,
  Koliani legível contra as arestas;
- `work/execution_9c/runtime/L{n}_{k}.png` + `desempenho_9c.json`;
- `work/execution_9c/kit_9c_contacto.png` — o kit peça a peça.

Ferramenta: `tools/shot_regiao1_9c.gd` (`--window --screen 1 --script … --
<pasta>`). O `shot_plataforma.gd` antigo **não** move a Koliani (as duas
fotos de L1 saíram iguais) — usar o novo.

## K. Windows

Exportado de um **worktree limpo** (`.worktrees/export-9c`, `git worktree add
--detach` em `a5d9ec9`, 0 alterações). `build/windows/Koliani.exe`:
163 219 296 bytes, SHA-256
`4f49ce2d8564670f303342bf52b4c94459a84b20a75ae31db99c5e3bacf599bc`, v0.15.18
(+0,34 MB face à 9B.4). Varrimento de bytes: 0 × `res://work/`, 0 ×
`.worktrees/`, 0 × `region_01_forest/production/_source`; `kit_9c/…`
presente. As 15 ocorrências de `08_REGION_I_ART_KIT` são **texto** dos
manifestos JSON (caminho de proveniência) — o backlog "excluir
`assets/**/manifest.json`" da 9B.4; nenhuma imagem do pacote entrou.

**Smoke no EXE, L1–L5:** o template de release **recusa** `--script` e caminhos
de cena na linha de comando ("compiled without support for path overrides").
O caminho que funciona é o do próprio jogo: `Koliani.exe -- --nivel=N
--foto=<png>` (salta o menu, arranca o `Main` no nível N, fotografa e sai).
5/5: `RUNTIME TRACE | build=0.15.18 | level_00N`, exit 0, foto gravada —
`work/execution_9c/runtime_exe/EXE_L{1..5}.png`, folha
`work/execution_9c/evidencia_exe_9c.jpg`. Terreno do kit, camadas da 08 e o
mood de cada nível visíveis no EXE.

O `--nivel` passa por `iniciar_sessao_nivel`, que pode gravar: a pasta de dados
(`%APPDATA%/Godot/app_userdata/Koliani`, 176 ficheiros) foi copiada antes e
reposta depois — **byte-idêntica ao início** (verificado por SHA). O save não
chegou a mudar; mudaram só os logs do Godot, e a rotação de logs apagou 4 logs
antigos, que foram repostos.

## L. Web/PWA

Mesmo commit, mesmo worktree. `build/web/index.pck`: 54 051 152 bytes, SHA-256
`0a43829eb3e353b91a47857ed8dccabc16d63c31029c078d29f94fb8f1077bea`; cache do
service worker **`1789112478|4547531`** (antes `1789108285|4479642`).

Servido localmente numa origem nova (`koliani-web-9c` no `.claude/launch.json`,
aponta para o export limpo). **SHA-256 do `index.pck` calculado dentro do
browser = o do export**; nenhum service worker a controlar a página (nada podia
servir um build antigo). Menu com v0.15.18; New Game → Play: o L1 corre com o
terreno do kit, o parallax e a Heart Tree, igual ao editor e ao EXE. Os outros
níveis não foram fotografados na Web: mesmo PCK/commit, nenhum código visual por
plataforma.

## M. Git no fim

- `a5d9ec9` — código + kit (78 ficheiros) + v0.15.18;
- commit seguinte — este relatório, `retomar_aqui.md`, `PRIORIDADES.md`,
  `launch.json`;
- `push` para `origin/master` (sem force). O `project.godot` continua com a
  reordenação do editor por preparar — não é desta execução.

## N. Bloqueios

Nenhum.

## O/P. Gates

**REGION I ENVIRONMENT GATE: CLOSED. READY FOR 9D: YES.** A 9D não foi
iniciada.

Limites conhecidos (não bloqueiam; seriam design novo ou outra execução): o
corpo do terreno é um mosaico de 44 px da prancha 10 — lê-se regular em paredes
muito altas; a 08 não tem declives, pontes utilizáveis nem cercas, e a 10 tem,
mas ponte/cerca seriam lidas como geometria — ficaram de fora de propósito; os
objectos de gameplay (água venenosa, checkpoints) mantêm a arte própria.
