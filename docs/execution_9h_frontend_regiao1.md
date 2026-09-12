# Execution 9H — Frontend de produção + vertical slice final da Região I

**v0.17.0** · 11–12 de setembro de 2026 · **PARTIAL PASS**

Refaz o frontend inteiro (intro em vídeo, menu, seletor de níveis, ícone/logo,
HUD), acrescenta o editor de layout de toque da PWA, e responde aos onze
apontamentos que o Game Master deixou depois de jogar a Região I.

---

## 1. A autoridade estava noutro sítio (e é a primeira coisa a saber)

O briefing aponta para
`work/production_art_gate/9H_game_master_approved/…` — **essa pasta não
existe**. As cinco peças aprovadas estão, com outros nomes, em
`work/production_art_gate/10_menu_rebrand/`:

| briefing | ficheiro real | SHA-256 (12) |
|---|---|---|
| `menu_principal_aprovado_9h.png` | `01_main_menu_approved/koliani_main_menu_v1.png` | `22d1ecf0889f` |
| `seletor_niveis_guia_9h.png` | `02_level_selector_approved/koliani_level_selector_v1.png` | `3fbaa747f6da` |
| `icone_logo_guia_9h.png` | `04_branding_icon_approved/koliani_logo_icon_v1.png` | `948e01984a73` |
| `intro_video_9h.mp4` | `05_intro_video_approved/koliani_intro_video.mp4` | `dab200cef9db` |
| — | `06_source_reference/koliani_floresta_sagrada_reference.png` | `fd7f0282692f` |

Confirmado que são as certas pelo conteúdo (o menu tem as cinco entradas e o
crédito no canto; o seletor tem as pastilhas I–V e os nós 1-1..1-5) e pela
data (11 set, 23:51 — depois da 9G). Os SHA ficam presos em
`tools/produzir_frontend_9h.py`: se a autoridade mudar, a ferramenta pára.

**Uma divergência de nome, resolvida:** o menu aprovado diz *FLORESTA
SAGRADA* e o seletor aprovado diz *REGIÃO I — FLORESTA CORROMPIDA*. Não é
contradição, é narrativa: o capítulo chama-se pela floresta que **era**, a
região joga-se pela floresta que **é**. O menu ficou com `menu.tagline`
(SACRED FOREST / FLORESTA SAGRADA) e a região manteve o nome canónico da 9G
(`world.forest` = FLORESTA CORROMPIDA).

---

## 2. Método: uma passagem serve o fundo e as peças

As duas pranchas de ecrã são **maquetes** — arte pintada com a UI já desenhada
por cima, em português, com um estado de jogo fixo. O jogo precisa do
contrário: a arte limpa por baixo, as peças soltas, os rótulos vivos.

`tools/produzir_frontend_9h.py` faz, por prancha:

1. **máscara** das zonas com UI pintada (28 retângulos, 5 coroas de anel, a
   polilinha do trilho);
2. **inpaint** por difusão multi-escala — borrões gaussianos de raio
   decrescente (128 → 1), com os píxeis conhecidos repostos a cada passo.
   Dá a **arte limpa**, sem inventar desenho: o que fica no buraco é a média
   suavizada da vizinhança real;
3. **diferença** `peça = prancha − arte limpa`, com o alfa preso à força da
   diferença. Dá as **peças recortadas** do fundo pintado.

O passo 2 serve os dois fins de uma vez — é o mesmo princípio do 9G
(`efeito = px − fundo`), e é o que torna a extração honesta: não há máscara
desenhada à mão, o alfa sai da própria prancha.

**Saída:** 32 ficheiros (`assets/ui/frontend_9h/` + `assets/branding/`),
manifesto com SHA, `--validar` e `--folha` para revisão.

### Armadilhas que custaram tempo

- **A ordem da máscara importa.** As coroas dos anéis fazem-se a apagar o
  interior do círculo. Desenhadas **depois** dos retângulos, devolviam ao
  fundo as fichas que os retângulos já tinham tapado — os rótulos “1-4” e
  “1-5” sobreviviam no fundo limpo. Agora as coroas fazem-se num mapa à parte
  e os retângulos vão por cima.
- **Interpolar texto na horizontal nem sempre serve.** Nas abas das regiões o
  rótulo ocupa quase toda a largura: a interpolação entre as colunas de fora
  deixava um rasto claro de lado a lado. Nas abas usa-se interpolação
  **vertical**, que só atravessa o gradiente da placa.
- **A ficha do nível não é nine-patch.** A peça tem 204×108 com losangos de
  30 px de cada lado; num selo de 36 px de altura as duas pontas
  sobrepunham-se e o que se via eram duas barras soltas. Passou a ser uma
  imagem escalada, com o rótulo por cima.
- **`flat = true` não desliga a placa, desliga o desenho da stylebox.** As
  abas do seletor saíram invisíveis na primeira montagem por causa disto.
- **A placa grande não serve botões pequenos.** `placa_selecionada` tem
  margens de 110 px; num botão de 90 px de largura desenham-se lascas da
  pintura. Barras de ferramentas e botões da HUD levam caixa lisa da mesma
  paleta (`Frontend9H.botao_placa`).
- **Depois da ferramenta, `--import` SEMPRE.** Reescrever os PNG sem
  reimportar deixa o Godot com os `.ctex` antigos — o ecrã aparece sem
  texturas nenhumas e parece um bug de código.

---

## 3. O palco 16:9

As pranchas são composições fechadas: a arte e a UI estão presas uma à outra.
Esticar a arte num ecrã que não seja 16:9 tirava a UI do sítio e deformava o
logótipo. Por isso todo o ecrã do frontend se monta dentro de
`Frontend9H.palco()`: um `AspectRatioContainer` 16:9 onde a arte e a UI
partilham as **mesmas coordenadas de 1280×720**, com a própria arte desfocada
e escurecida a encher as barras que sobram (é o que o cinema faz, e evita a
barra preta morta num telemóvel 20:9).

Todas as medidas do menu e do seletor são as da prancha × 1280/1672.

---

## 4. O que mudou, bloco a bloco

### A. Menu principal
`scenes/ui/MenuInicial.tscn` ficou só com a raiz; o ecrã monta-se em
`scripts/menu_inicial.gd` sobre `fundo_menu` (a prancha com a UI retirada).
Cinco entradas na ordem da prancha — **Continuar · Novo Jogo · Selecionar
Nível · Opções · Sair** — com a placa de losango como **realce único que
escorrega** entre entradas (um nó só: não há dois destaques a discutir, rato
contra comando, e o movimento é a vida que faltava). Canto inferior direito:
versão + `Developed by Paulitos`. Folhas vermelhas a atravessar o ecrã são o
único movimento — o “Ken Burns” antigo tirava o logótipo do sítio.

### B. Intro em vídeo
`scenes/ui/Intro.tscn` é a nova `main_scene`. **No desktop** toca
`assets/video/intro_koliani.ogv` (Theora, 960×540, 2,0 MB) num
`VideoStreamPlayer`. **No Web é um `<video>` do DOM** — ver §6. Salta com
qualquer tecla, botão ou toque; relógio de segurança mede a **posição** do
stream (não o `is_playing()`, que diz que sim com o vídeo parado) e, se não
avançar em 1,6 s, vai para o menu. Os atalhos de dev passam-lhe ao lado.

### C. Ícone / logo
Um produtor só, a partir da prancha de branding: 12 tamanhos PNG, `.ico` do
Windows (7 resoluções), `icon.png` do projeto, ícones da PWA (144/180/512) e
do Android. `project.godot`, `export_presets.cfg` (Windows + Android) e o
manifesto da PWA passaram todos a apontar para o novo.

### D. Seletor de níveis
O carrossel de 100 cartões deu lugar ao **mapa de região** da prancha: a vista
da região ao fundo, os cinco níveis como nós ligados por um trilho que acende
até onde se pode ir, painel de detalhe, abas das 20 regiões, setas de região
anterior/seguinte, citação. A interface pública é a mesma
(`configurar(indice, respeitar_bloqueio)`, sinais `escolhido`/`cancelado`),
por isso o `MapaMundo` e a `DevBarra` não mudaram.

As três linhas de informação à direita levam o que o jogo **sabe** —
guardião, passo na região, estado. Não há contadores de colecionáveis nem
tempos: a prancha mostra-os, o jogo ainda não os tem, e inventá-los era
mentir ao jogador (fica em §8).

### E. HUD
Passou do ouro/ciano da prancha 09 (9F) para o **carmesim sobre carvão** do
rebrand: cabeçalho do nível na aba do kit novo, selo “1-3” na ficha do mapa,
barra do chefe na moldura do painel, contador de essência na mesma aba,
botões de equipamento em caixa lisa da paleta. As barras de vida/energia
continuam a vir do 9F (a gema e o enchimento são material próprio, e não há
equivalente na prancha nova).

### F. Web/PWA: EDITAR LAYOUT
Opções → **EDITAR LAYOUT**, só onde há toque (telemóvel, tablet, Web/PWA).
Arrasta-se qualquer controlo, muda-se o tamanho com − / +, guarda-se, repõe-se.
O layout vive em `user://layout_toque.json`, **em frações do viewport** — o
mesmo ficheiro serve um telefone de 1600×720 e um tablet de 2048×1536, e um
layout guardado não sai do ecrã ao rodar. Ficheiro em falta ou estragado =
layout de fábrica. Em modo de edição o `_input` dos controlos devolve logo,
senão arrastar o botão de Saltar fazia a Koliani saltar por baixo do editor.

### G. Áudio
Quatro vozes de interface novas (`ui_mover`, `ui_confirmar`, `ui_voltar`,
`ui_negado`) e uma **cama de ambiência própria da Região I**
(`ambiente_floresta`, 18,5 s em ciclo: vento a respirar, água ao longe,
bordão de corrupção a pulsar) — tudo sintetizado, sem licenças
(`tools/gerar_audio_9h.py`). A `assombracao` era uma casa assombrada
(rangidos, correntes) e nunca foi uma floresta; nos cinco primeiros níveis
toca esta. Os três golpes do combo passaram a ter tom próprio.

**O que NÃO foi feito, e porquê:** as 40 faixas de música (20 de nível + 20
de chefe) são peças compostas, com licença. Substituí-las por síntese seria
trocar música a sério por bordões — pior, não melhor. Marcado
`PRODUCTION AUDIO MISSING` (§8).

### H. Chefes da Região I mais fáceis
O Game Master: *“nem o do nível 1 está aceitável”*. A causa estava escrita no
próprio código: quando os escudos saíram (maratona de 2 set), a vida subiu
×3,2 e o dano de contacto ×1,4 para a luta não acabar num instante. Isso
serve quem já conhece os padrões; não serve os cinco níveis onde se aprende
a lê-los.

A correção é uma **rampa dentro da região** (`ChefeBase.ALIVIO_R1`), a mexer
em quatro coisas ao mesmo tempo — baixar só a vida faz lutas longas e
igualmente injustas:

| | 1-1 | 1-2 | 1-3 | 1-4 | 1-5 |
|---|---|---|---|---|---|
| vida | 0,52 | 0,60 | 0,68 | 0,77 | 0,86 |
| dano (contacto **e** por ataque) | 0,58 | 0,65 | 0,72 | 0,80 | 0,88 |
| telégrafo | ×1,25 | ×1,20 | ×1,14 | ×1,08 | ×1,02 |
| janela EXPOSTO | ×1,55 | ×1,42 | ×1,30 | ×1,18 | ×1,06 |
| recuperação | ×1,15 | ×1,11 | ×1,08 | ×1,04 | ×1,00 |

**Ghorak (1-1), medido no jogo:** vida 800 → **416**; `dano_onda` 22 → 13;
`dano_raiz` 18 → 10; `dur_exposto` 0,72 s → **1,11 s**. Fora da Região I
nada muda (fator 1,0). Teste `teste_9h_chefes_regiao1_mais_faceis` morde:
instancia o Ghorak e compara com o que ele teria sem alívio.

### I. Fundo desfocado
Estava mesmo. O panorama da Região I é um recorte **1:1** de 952×247 da
prancha 08, desenhado a **3× com filtro LINEAR**, com o zoom 1,4 da câmara
por cima: ~4,2× de ampliação bilinear. Ampliação bilinear é interpolação —
quanto mais se amplia, mais macia fica.

Duas correções, ambas necessárias:

1. **Metade da ampliação deixou de ser do GPU.** `tools/nitidez_panorama_9h.py`
   produz o panorama em dobro (Lanczos + máscara de desfoque 2,0/95 %/2) e o
   jogo desenha-o a 1,5×. A geometria no mundo é a mesma (2 × 1,5 = 3).
2. **Máscara de desfoque no píxel do ECRÃ** (`assets/shaders/nitidez_fundo.gdshader`)
   nas camadas de fundo da Região I. Sharpen na textura não resolvia — a
   ampliação voltava a suavizar; este corre **depois** da ampliação, com o
   raio em píxeis de ecrã, por isso vale em qualquer zoom. Força
   proporcional à ampliação da camada (0,35–1,05), com tecto: acima disso a
   aresta ganha halo.

**Medido** (energia do gradiente na banda de fundo do L1, 1280×300):
5,00 → **5,95**, **+19 %**. Antes/depois lado a lado em
`work/execution_9h/evidencia/l1_blur_antes_depois.png`.

### J. Mobs e chefes com mais movimento
Estavam mesmo parados, e a razão era um `return`: o `_process` do
`DemonioBase` **saía assim que existisse `_anim`**, e toda a respiração,
antecipação e recuo que o caminho antigo fazia ficava por correr. A arte de
produção da Região I (9D/9E) tem **uma pose por estado** — um bicho com uma
pose e sem camada procedimental é, literalmente, uma imagem parada a deslizar
pelo chão.

`_vida_no_anim()` acrescenta: respiração (±4,5 %), passada (|sin|, o pé toca
duas vezes por ciclo), inclinação para onde vai, recuo ao levar, esmagar ao
aterrar, e **fase própria por instância** para um grupo não respirar em
uníssono. A amplitude cai para 42 % quando a animação em curso tem mais do
que um frame (aí a arte já se mexe sozinha). Os chefes herdam.

**Armadilha:** a respiração escala à volta do centro do sprite; sem
compensar, os pés subiam e desciam ~4 px e o bicho parecia a flutuar. O
`_calibrar_pes` passou a guardar a distância centro→pés e a posição repõe o
que a escala afasta. Teste `teste_9h_inimigos_com_vida` mede a amplitude ao
longo de 40 frames — a zero, falha.

### K. Combos da Koliani
*“A Koliani não parece dar combos.”* O encadeamento funciona; a
**apresentação** é que não se lia: os três golpes saem dos mesmos seis frames
aprovados do Golden Set (não há arte própria por golpe) e o que mudava entre
eles era a velocidade. Três golpes com a mesma pose e o mesmo arco lêem-se
como um só, repetido.

Sem tocar no corpo aprovado (o rig não se deforma por código):

- **arco próprio por golpe** — 1.º baixo e frio, 2.º giro largo espelhado na
  vertical e mais alto, 3.º arco pesado, maior, deslocado à frente e quente;
- **tom próprio por golpe** (1,00 / 1,09 / 0,88 — o remate cai para o grave);
- **selo do combo** (`×2`, `×3`) por cima da cabeça, com salto e a apagar com
  a janela. O 1.º golpe não mostra nada de propósito: um `×1` em cada toque
  no botão era ruído constante.

---

## 5. Prova no EXE de release

Tudo em `build/windows/Koliani.exe` (v0.17.0, 394 MB, exportado do mesmo
source que o Web):

| rota | resultado |
|---|---|
| `--foto-intro=<png>@3.0` | **pos=2,93 s, a_tocar=true** — o vídeo anda mesmo |
| `--foto-menu=<png>` | menu novo, `RUNTIME TRACE \| build=0.17.0 \| main_scene=…/Intro.tscn \| frontend=9H`; **sem DEVELOPER MODE** (release) |
| `--foto-mapa=<png>` | mapa da Região I com os 5 nós, painel e abas |
| `--nivel=N --foto=<png>`, N=1..5 | os cinco níveis, HUD novo |
| `--nivel=5 --foto-estado=inimigos` | 18 fotos de identidades/estados |

**O save do Game Master não foi tocado:** 181 ficheiros de userdata antes e
depois, `0` mudados fora de `logs/`.

Pacote de revisão humana: `work/execution_9h/folha_revisao_9h.png`
(11 painéis) + `work/execution_9h/evidencia/`.

---

## 6. Web/PWA — e a razão de o vídeo lá não ser do Godot

**Descoberta que mudou a implementação:** o export Web é *single-threaded, no
GDExtension support* (banner do próprio Godot). Descodificar Theora em wasm
**bloqueia a thread principal**: com a intro a tocar, a página deixava de
responder — nem `screenshot` nem `eval` voltavam.

Correção: no browser a intro é um **`<video>` do DOM**, descodificado pelo
browser por hardware, servido ao lado do `index.html`
(`web/intro_koliani.mp4`; o CI copia-o depois do export). Toca com som porque
já houve o gesto do cartão “TOCAR PARA JOGAR”; se falhar (ficheiro em falta,
codec recusado) o estado vem `erro` e vai-se ao menu na mesma. No Web nem se
carrega o Theora.

**Bug real apanhado no browser, e que no PC nunca se via:** o cartão de gesto
não deixava o toque chegar ao `_unhandled_input`. Um `Control` nasce com
`MOUSE_FILTER_STOP` e come o evento — o cartão ficava a piscar e o toque não
fazia nada. No PC não há cartão, por isso o EXE nunca o mostrou.

### O que ficou provado no Web

- a página carrega, o Godot arranca (banner + WebGL 2.0), **sem erros de
  GDScript**;
- o **ícone novo** e o cartão **TAP TO PLAY** aparecem (captura);
- o `<video>` **toca mesmo**: `currentTime = 6,6 s`, `paused = false`,
  `error = null`, `src = …/intro_koliani.mp4`, estado `a_tocar`;
- o PCK contém tudo o que é novo (`fundo_menu`, `fundo_seletor`,
  `ambiente_floresta`, `ui_confirmar`, `panorama_…_x2`, `Intro.tscn`);
- o manifesto da PWA e os três ícones (144/180/512) são o logótipo novo;
- o bloco de áudio do 9F está no `head_include` intacto.

### O que NÃO ficou provado no Web, e porquê

Capturas do menu/seletor/HUD **dentro do browser** e os picos de áudio.
Causa: **o pane do browser desta sessão está escondido, e um pane escondido
pára o `requestAnimationFrame`** — sem rAF o Godot Web fica parado e
`screenshot`/`eval` esgotam o tempo. Não é defeito do build (o mesmo pane
respondeu enquanto o cartão estava à espera do gesto). Não havia Chrome real
ligado a esta sessão para o fazer pelo caminho da 9F. Fica em §8 (P1).

---

## 7. Testes e desempenho

`tests/run_tests.tscn` — **todos passam**. Três testes novos, todos a morder:

- `teste_9h_frontend_producao` — kit importado (12 peças), `main_scene` é a
  intro, vídeo em Theora presente, ícone do projeto, e as 14 chaves novas nos
  **6 idiomas**;
- `teste_9h_chefes_regiao1_mais_faceis` — rampa monótona, fora da região não
  há alívio, e o Ghorak do 1-1 com ~416 de vida (falha se alguém puser os
  fatores a 1,0);
- `teste_9h_inimigos_com_vida` — mede a amplitude do sprite ao longo de 40
  frames.

Dois testes existentes foram **atualizados, não desligados**: o do seletor
(passou a medir nós/fichas/abas em vez de cartões/pastilhas) e o da defesa
de release do menu (o nome da variável mudou, a asserção é a mesma).

**Armadilha de método que custou três falsos negativos:** o Python a escrever
ficheiros no Windows converte `\n` em `\r\n` por omissão. O
`tests/run_tests.gd` tem **quebras de linha literais dentro de constantes de
texto** (é assim que parte o `gerador_corredor.gd` e o `head_pwa.html`); com
o próprio ficheiro de testes em CRLF, essas constantes passaram a `\r\n` e as
buscas deixaram de bater — “MECANICA_DO_NIVEL tem 0 entradas” e “head_include
DESACTUALIZADO”, nenhum deles verdadeiro. **Regra: `write_text(...,
newline="\n")` sempre neste repo** (`.gitattributes` é `* text=auto eol=lf`).

**Desempenho:** a máscara de desfoque do fundo são 4 amostras extra por
píxel, só nas camadas de fundo da Região I; o panorama em dobro custa ~4,5 MB
de VRAM a mais e poupa metade da ampliação bilinear. A camada de vida dos
inimigos é aritmética por bicho, por frame, sem alocações.

---

## 8. O que fica em aberto

**P0 — nenhum.**

**P1**
1. **Capturas do Web em Chrome real** (menu, seletor, HUD, layout de toque) e
   os picos de áudio com `kolianiAudioDiag()`. Bloqueado pelo pane escondido
   desta sessão, não pelo build. Comando:
   `python <servidor COOP/COEP> build/web` e abrir em Chrome.
2. **`PRODUCTION AUDIO MISSING` — a soundtrack.** O Game Master pediu “mudar
   soundtrack completa”. As 40 faixas atuais são peças licenciadas; para as
   trocar é preciso **entregar o pacote novo** (20 de nível + 20 de chefe, ou
   um conjunto menor com regra de atribuição) com a licença. Sem isso, o que
   se pôde fazer sem licenças está feito (§4G).

**P2**
3. **`APPROVED DESIGN / PRODUCTION ASSET MISSING` — estatísticas do seletor.**
   A prancha mostra *Colecionáveis 0/3*, *Desafios 0/1* e *Melhor Tempo*. O
   jogo não tem nenhum dos três. Ou se decide o design (o que conta como
   colecionável? o que é um desafio?) ou as três linhas ficam como estão
   (guardião / passo / estado).
4. **Citações por região.** Só a Região I tem a sua (a aprovada); as outras 19
   usam uma linha genérica.
5. **PCK do Web com 285 MB.** É o pacote inteiro; num telemóvel é uma espera
   longa. Merece uma passagem de exclusões/compressão.

**P3**
6. Poses de ataque próprias para os inimigos e para os golpes do combo
   (design/arte novos — hoje há uma pose por estado e a leitura vem da camada
   procedimental e dos arcos).
7. `RaizPerigo`, água venenosa e arte base da fogueira continuam sem
   autoridade (herdado da 9G).
8. Fonte CJK livre para o chinês no Web (herdado da 9F).

---

## 9. Ficheiros

**Ferramentas novas:** `tools/produzir_frontend_9h.py`,
`tools/nitidez_panorama_9h.py`, `tools/gerar_audio_9h.py`,
`tools/folha_revisao_9h.py`, `tools/shot_layout_9h.gd`.

**Runtime novo:** `scripts/frontend_9h.gd`, `scripts/intro.gd`,
`scripts/layout_toque.gd`, `scripts/editor_layout_toque.gd`,
`scenes/ui/Intro.tscn`, `assets/shaders/nitidez_fundo.gdshader`.

**Runtime mexido:** `menu_inicial.gd`, `seletor_niveis.gd`,
`controlos_tacteis.gd`, `controlos_toque.gd`, `opcoes_menu.gd`,
`chefe_base.gd`, `demonio_base.gd`, `koliani.gd`, `musica.gd`, `som.gd`,
`region1_hybrid_visual_target.gd`, `MenuInicial.tscn`, `SeletorNiveis.tscn`.

**Assets novos:** `assets/ui/frontend_9h/` (23), `assets/branding/icone_9h_*`
+ `koliani.ico` + `icon.png`, `assets/video/intro_koliani.ogv`,
`assets/audio/ui_*.wav` + `ambiente_floresta.wav`,
`…/backgrounds/region1_panorama_*_x2.png`, `web/intro_koliani.mp4`.

---

## 10. Estado

```
READY FOR GAME MASTER HUMAN REVIEW: YES
REGION I VISUAL VERTICAL SLICE: HUMAN APPROVAL PENDING
```

Não foi iniciada a Região II.
