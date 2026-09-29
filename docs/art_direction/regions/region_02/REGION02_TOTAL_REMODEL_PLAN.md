# REGIÃO II — DESFILADEIRO DOS VENTOS · PLANO DE REMODEL TOTAL

**Processo:** Region II Total Visual Remaster — Prompt 1 (auditoria + plano)
**Branch:** `claude/region02-total-remodel` · **Base:** `origin/master` `72ea2477`
**Data:** 20 set 2026 · **Estado: PLANO. Nada foi implementado.**

Autoridade: `concept_environment_01.png`, `concept_environment_02.png`,
`level_mechanics_and_layout.png`, `asset_atlas_*`, `enemy_gameplay_pack.png`,
`implementation_sheet.png`, `boss_pack.png` (esta pasta),
[`README.md`](README.md),
[`GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md`](GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md),
[`KOLIANI_REGION_CANON.md`](../../KOLIANI_REGION_CANON.md).

---

## 0. DUAS CORREÇÕES AO ENQUADRAMENTO DO BRIEFING

Ditas primeiro porque mudam o que o plano pode prometer.

### 0.1 A Região I não serve de benchmark visual a partir deste repo

O briefing manda abrir as referências da Região I e replicar-lhe a
metodologia. `docs/art_direction/regions/region_01/` tem **um README e zero
PNG**, e o próprio README diz-se `VISUAL_REFERENCE = MISSING`. A autoridade
real da Região I é
`Koliani_1.0_Master_Package_v2/references/approved/08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png`,
citada em `docs/execution_9c_region1_environment_kit.md` — e esse pacote
**não está neste clone** (fica fora do Git, na máquina do Paulo).

Não vou descrever pranchas que não vi. O que se pode extrair da Região I
é a **metodologia**, que está escrita na 9C e é aproveitável (§C).

### 0.2 O benchmark utilizável é a Região III

A Região III acabou de fazer exactamente esta travessia — de "masmorra
genérica com nomes novos" a região com identidade — e o processo está
documentado e medido em
[`region_03_final_closure.md`](../../../implementation/region_03_final_closure.md).
É esse o padrão de transformação que se pode replicar com prova, e é
sobre ele que §C está construída. Fica dito que isto é uma substituição
consciente do que o briefing pediu, não um esquecimento.

---

## A. BEFORE STATE — o que a Região II parece agora

Capturas reais dos cinco níveis (Godot 4.7.2, janela real via Xvfb,
`tools/shot_plataforma.gd`), medidas contra a fiada de miniaturas de
`level_mechanics_and_layout.png`.

### A medição que manda no plano inteiro

Luminância média e fracção de píxeis claros (luma > 110):

| | luminância prancha | luminância jogo | % claros prancha | % claros jogo |
|---|---:|---:|---:|---:|
| N06 | 79,6 | **35,8** | 34,4 % | **0,6 %** |
| N07 | 82,8 | **35,4** | 34,9 % | **8,0 %** |
| N08 | 87,5 | **43,6** | 39,6 % | **2,3 %** |
| N09 | 87,6 | **32,8** | 36,2 % | **3,5 %** |
| N10 | 68,9 | **36,7** | 28,0 % | **1,2 %** |

**O jogo tem cerca de metade da luminância da prancha, e entre 4× e 57×
menos píxeis claros.**

E o diagnóstico não é "está escuro, clareia-se". É **estrutural**: na
prancha, ~35 % do ecrã é **mar de nuvens luminoso**. Esse mar é o que diz
*altitude* — é ele que separa "desfiladeiro" de "masmorra à noite". No
jogo ele está pintado mas chega ao ecrã como massa escura, por isso a
percentagem de claros colapsa. A luminância em falta **é** o mar de
nuvens em falta.

> Nota honesta, e é o achado mais útil desta auditoria: isto **já foi
> atacado**. O `atmosfera.gd:132-145` documenta um Super-Process A2 que
> deu ganho **1.7** à `nuvens.png` precisamente por este motivo, com o
> raciocínio certo escrito no comentário. A medição de hoje mostra que
> **não chegou**. O próximo passo não é redescobrir a causa — é aceitar
> que um ganho de camada não resolve e mudar de método (§D).

### Hue: não é aqui que está o problema

| | G−R prancha | G−R jogo | B−R prancha | B−R jogo |
|---|---:|---:|---:|---:|
| N06 | −5,1 | −14,2 | +33,7 | +19,0 |
| N07 | −3,2 | −4,8 | +39,7 | **+41,5** |
| N08 | −2,5 | −9,1 | +34,4 | +25,3 |
| N09 | −18,7 | −21,9 | +25,7 | +11,0 |
| N10 | −23,8 | −18,8 | +14,6 | +25,2 |

A prancha também puxa a violeta nos N09/N10 — o jogo não está "com a cor
errada" como a Região III estava (lá o sinal de G−R estava invertido).
**Um recolor de terreno seria trabalho desperdiçado aqui.** O desvio de
B−R nos N06/N08/N09 é consequência do céu em falta, não causa.

### O que se vê, nível a nível

- **N06** — o pior. Duas lajes horizontais contínuas, planas, empilhadas;
  fundo é um degradê violeta liso com colinas escuras. Zero céu, zero
  nuvens, zero vento visível. Lê-se como corredor de masmorra. 0,6 % de
  píxeis claros é o retrato numérico disto.
- **N07** — o melhor dos cinco. Plataformas pequenas soltas no ar, parede
  de falésia alta à esquerda, silhueta de ruína ao longe. **Lê-se mesmo
  como estar no alto.** É a prova de que a arquitectura procedural
  consegue chegar lá.
- **N08** — laje suspensa com vazio por baixo e coluna alta: a ideia certa.
  Mas o "vazio" é rocha escura, não céu; o fundo são calhaus, não ilhas.
- **N09** — brilho magenta forte, paredes altas de alvenaria e um bloco
  com **cruz de campa**. Lê-se como cripta.

  > **CORRIGIDO no Prompt 2.** Aqui estava escrito que a cruz vinha da
  > camada de fundo e **não** dos props, porque `cruz` e `lapide` não
  > estão no `deco.json`. Estava errado: é o prop **`velas.png`**, um
  > nicho de capela com uma cruz gravada por baixo, e **estava** no
  > catálogo do bioma. Ter verificado só dois nomes e concluído a partir
  > disso foi meia medição. Já saiu do `desfiladeiro`.
- **N10** — setas de vento visíveis (o FX existe e lê-se bem), Guardião
  presente, plataformas em degraus. Falta a **Torre dos Céus**: a prancha
  dá-lhe `ambiente: torre celestial` e o jogo não tem landmark nenhum.

### Repetição

A **gárgula** aparece em N06, N07 e N08 nas mesmas capturas. O catálogo
tem 25 props (contra 32 da Região III), mas a distribuição concentra-se
em poucos.

---

## B. APPROVED TARGET — o que as pranchas dizem

De `concept_environment_01.png` e `level_mechanics_and_layout.png`:

**Silhueta da região:** mundo **partido em pedaços flutuantes** sobre um
mar de nuvens, ligados por **pontes de pedra monumentais com arcadas**.
Quedas de água a despenhar-se nas nuvens. Lua vermelha. Silhuetas de
catedral/castelo sobre rocha suspensa.

**Paleta (fiada nomeada):** céu · névoa · rocha · ruínas · vegetação ·
acentos · cristais · FX vento · detalhes. Azul-noite e índigo como base,
**carmesim como acento** (bandeiras com cruz, vinhas vermelhas), lavanda
pálida nas nuvens.

**Terreno (14 variações nomeadas):** chão A/B, plataforma, plataforma em
ruínas, borda esquerda/direita, canto int./ext., parede vertical, parede
destruída, plataforma frágil, plataforma com cristais, variação com gelo,
variação com vinhas. Alvenaria talhada, com **franja de vinhas vermelhas
a pender** por baixo.

**Plataformas especiais (8):** móvel h/v, que aparece, que desaparece,
frágil, oscilante, com corrente (×2).

**Mecânicas (12):** propulsor de vento h/v, vento variável, interruptor
de pressão, interruptor de distância, alavanca, porta com chave, sino
ativável, elevador de correntes, pêndulo retrátil, plataforma elevatória,
zona de vento inverso.

**Hazards (9):** espinhos fixos/móveis, lâminas giratórias, vento de
impulso, vento reverso, tornado vertical/horizontal, laser de cristais,
queda de pedras.

**Props (15):** estátua, gárgula, coluna, arco, janela, bandeira,
correntes, lanterna, urna, vaso, escombros, cristais, vegetação, árvore
seca, detalhes diversos.

**Narrativos (6):** bandeira antiga, altar em ruínas, pedra de memória,
estátua partida, símbolo celestial, inscrições.

**FX (12):** rajada horizontal, corrente ascendente, vento variável,
turbilhão, névoa, folhas/detritos, estilhaços de pedra, estilhaços de
cristal, brilho mágico, poeira no ar, **aurora no céu**, raios distantes.

**Parallax, 4 camadas nomeadas:** L1 silhuetas distantes · L2 montanhas e
ruínas (com a lua vermelha) · L3 falésias e pontes · L4 elementos próximos.

**Por nível** (a prancha nomeia ambiente e segredo de cada um):

| | nome na prancha | ambiente | segredos |
|---|---|---|---|
| N06 | Rajadas Horizontais | falésias abertas | áreas laterais protegidas pelo vento |
| N07 | Correntes Ascendentes | **torres destruídas** | rotas alternativas nas correntes |
| N08 | Ilhas Suspensas | **ilhas flutuantes** | ilhas secretas fora da rota |
| N09 | Vento Variável | **ruínas atmosféricas** | caminhos com vento inverso |
| N10 | **Torre dos Céus** | **torre celestial** | últimos coletáveis antes do chefe |

Cada nível tem um **ambiente próprio nomeado**. Hoje os cinco partilham o
mesmo. É aqui que está a maior distância entre prancha e jogo.

---

## C. LIÇÕES DE BENCHMARK (Região III, com a ressalva do §0)

Cinco coisas que fizeram a Região III passar a ler como região nova, e
que são **método**, não estilo:

1. **Medir antes de opinar.** A Região III só virou quando se mediram as
   dominantes (G−R invertido) e se contaram os props (12, três deles de
   cemitério). "Parece escuro" não é accionável; "0,6 % de píxeis claros
   contra 34,4 %" é.
2. **Plantar arquitectura na camada onde se anda.** O salto de LOW para
   MEDIUM-HIGH veio de tirar arcos, colunas e sinos de `z = -3`
   (escurecidos, atrás do parallax) e pô-los a **46 %** em `z = -1`, à
   escala de quem passa. É a mudança estrutural com melhor retorno.
3. **Desenhar os props quando não há folha para recortar.** As fontes CC0
   vivem em `assets/sprites/incoming/`, que não vem no Git.
   `gerar_props_torre_ecos.py` desenha-os. Para a Região II já existe
   `tools/extrair_props_regiao02.py` — ponto de partida, não do zero.
4. **Acender o que está desenhado.** Havia lanternas e braseiros com
   **zero** `PointLight2D`. Custo medido: 15-23 luzes por nível, ~20 % do
   total. Barato e transforma a leitura.
5. **Separar geometria funcional de geometria visual, e provar.**
   `tools/baseline_geometria.gd` despeja o funcional ignorando
   decorativos; a verificação dos 100 níveis deu **95 iguais / 5 mudados,
   0 fora da região**. Sem esse instrumento não há remodel total seguro.

**O que a Região III mudou e a Região II não:** o primeiro plano
arquitectónico, o catálogo de props, a luz nos props, e a cor do terreno
medida contra a prancha. **A Região II tem um problema que a III não
tinha:** o elemento estrutural principal (o mar de nuvens) existe como
asset mas não chega ao ecrã.

---

## D. REGRAS DE REMODEL — N06–N10

**R1 — O alvo é a luminância, e a via é estrutural, não um ganho.**
Meta: **20–30 % de píxeis claros** por nível (hoje 0,6–8 %). Já se sabe
que subir o ganho da camada não lá chega. Vias a testar, por ordem:
(a) tirar o mar de nuvens de debaixo do `_gradacao` + `dessaturar_fundo`
+ `CanvasModulate` que lhe comem dois terços do brilho, tratando-o como
camada **isenta** e não como fundo distante; (b) uma camada de céu
claro **acima** do horizonte de jogo, não só atrás; (c) abrir o traçado
visual para o mar ser visível, não tapado por rocha.
**Nenhuma destas toca em colisões.**

**R2 — Um ambiente por nível.** Os cinco não podem partilhar a mesma
receita: falésias abertas · torres destruídas · ilhas flutuantes · ruínas
atmosféricas · torre celestial. Uma silhueta de fundo e um landmark
próprios por nível.

**R3 — Arquitectura em `z = -1`.** Arcadas, pontes de pedra, quedas de
água e colunas à escala de quem passa, decididas por `_rng_deco`.
Alvo ~45 %, como na Região III.

**R4 — Landmark obrigatório por nível.** Um elemento que só existe ali e
que se vê de longe (§E). É o que faz "mapa novo" em vez de "mesmo mapa
com outra cor".

**R5 — Carmesim é acento, nunca cor de massa.** Bandeiras com cruz,
vinhas vermelhas na franja do terreno, pontas de pena do Guardião.

**R6 — O vento tem de se ver em todos.** O FX já existe e lê-se bem (N10
prova-o). Falta a **aurora no céu** e os **raios distantes**, que são os
dois FX que a prancha tem e o jogo não.

**R7 — Anti-repetição.** Nenhum prop em mais de dois dos cinco níveis. A
gárgula está hoje em três.

**R8 — Congelamento de geometria funcional.** Baseline com
`tools/baseline_geometria.gd` antes e depois. Critério: **0 alterações
funcionais nos 100 níveis**, incluindo N06–N10. Gaps, checkpoints,
`WindZone`, `ZonaPlanar`, hazards, lógica do chefe e progressão ficam
byte a byte. A *leitura* deles pode ser inteiramente refeita.

**R9 — Um `_rng` só, e sequencial.** Todo o sorteio decorativo passa por
`_rng_deco`. Um sorteio a mais no `_rng` desloca a geometria de todos os
níveis de todas as regiões — custou a Região III uma volta inteira.

---

## E. PLANO POR NÍVEL

Escala: **KEEP** (não tocar) · **REWORK** (mesma peça, tratamento novo) ·
**REBUILD** (peça nova).

### N06 — As Falésias Abertas *(`Prisao_dos_Condenados.tscn`)*

| Eixo | | |
|---|---|---|
| arquitectura jogável | **KEEP** | geometria congelada (R8) |
| silhueta do mapa | **REBUILD** | duas lajes contínuas planas é a leitura de corredor |
| foreground | **REBUILD** | vazio; arcadas e balaustrada em `z=-1` |
| midground | **REBUILD** | colinas escuras → falésias partidas com ruína |
| background | **REBUILD** | mar de nuvens visível (R1) |
| plataformas | **REWORK** | franja de vinhas vermelhas, bordas talhadas |
| terreno | **KEEP** | hue já bate (G−R −14,2 vs −5,1) |
| props | **REWORK** | tirar a gárgula (R7); bandeiras e lanternas |
| landmarks | **REBUILD** | **ponte de pedra monumental com arcadas** sobre o vazio |
| inimigos | **KEEP** | fora deste prompt |
| iluminação | **REWORK** | acender lanternas e braseiros |
| atmosfera | **REBUILD** | é o nível com 0,6 % de claros |
| identidade | **REBUILD** | — |

**Alvo:** a primeira coisa que se vê da região é que **o chão acabou**.

### N07 — A Garganta Ascendente *(`Fornalha_dos_Pecadores.tscn`)*

| Eixo | | |
|---|---|---|
| arquitectura jogável | **KEEP** | |
| silhueta do mapa | **KEEP** | já lê como altura — é o modelo dos outros |
| foreground | **REWORK** | acrescentar sem estragar |
| midground | **REWORK** | ruínas → **torres destruídas** (ambiente da prancha) |
| background | **REWORK** | mais perto do alvo (8 % de claros); falta o mar |
| plataformas | **REWORK** | correntes e lanternas penduradas |
| terreno · props | **KEEP** · **REWORK** | gárgula fora |
| landmarks | **REBUILD** | **torre partida ao meio**, com a fractura como rota |
| iluminação · atmosfera | **REWORK** | correntes ascendentes visíveis |
| identidade | **REWORK** | |

**Alvo:** subir por dentro de uma torre que já caiu. **Menor risco — é o
melhor ponto de partida.**

### N08 — As Ruínas Suspensas *(`Corredor_das_Execucoes.tscn`)* — **GAMEPLAY LOCKED**

Ilhas, gaps, planar, vento, checkpoints e rota: **KEEP absoluto.**

| Eixo | | |
|---|---|---|
| arquitectura jogável | **KEEP** | LOCKED |
| silhueta do mapa | **KEEP** | as ilhas são a silhueta |
| foreground | **REBUILD** | ilhas pequenas a passar em `z=-1` |
| midground | **REBUILD** | calhaus → **ilhas flutuantes** com ruína em cima |
| background | **REBUILD** | **o vazio tem de ser céu, não rocha** |
| plataformas | **REWORK** | ilha com solo, vinhas e erosão por baixo |
| terreno · props | **KEEP** · **REWORK** | cristais ficam; gárgula sai |
| landmarks | **REBUILD** | **queda de água a despenhar-se nas nuvens** |
| iluminação · atmosfera | **REWORK** · **REBUILD** | detritos a voar |
| identidade | **REBUILD** | |

**Como fazer o N08 parecer novo sem lhe tocar:** o que o envelhece é o
**fundo**, não o traçado. Trocar rocha escura por céu e nuvem por baixo
das mesmas ilhas, e pôr uma queda de água ao fundo, reescreve a leitura
inteira sem mexer num único `CollisionShape2D`. É o nível onde a
separação geometria-funcional / geometria-visual mais rende.

### N09 — A Rajada que Vira *(`Ala_dos_Mortos.tscn`)*

| Eixo | | |
|---|---|---|
| arquitectura jogável | **KEEP** | |
| silhueta do mapa | **REWORK** | paredes altas fecham demais |
| foreground | **REBUILD** | |
| midground | **REBUILD** | **tirar a cruz de campa do fundo** — vem da camada de fundo, não dos props |
| background | **REBUILD** | 3,5 % de claros |
| plataformas | **REWORK** | oscilantes e com corrente (a prancha tem-nas) |
| terreno | **KEEP** | G−R −21,9 vs −18,7: bate |
| props | **REWORK** | **altar em ruínas**, **pedra de memória**, **inscrições** |
| landmarks | **REBUILD** | **altar em ruínas exposto ao vento**, bandeiras rasgadas |
| iluminação | **REWORK** | o magenta está a fazer de luz principal |
| atmosfera | **REBUILD** | vento inverso legível |
| identidade | **REBUILD** | hoje lê cripta, devia ler ruína ao vento |

### N10 — Os Ventos Eternos / Torre dos Céus *(`A_Cela_Zero.tscn`)* — chefe aprovado

A luta **não se redesenha**. Só apresentação.

| Eixo | | |
|---|---|---|
| arquitectura jogável | **KEEP** | arena e lógica intactas |
| silhueta do mapa | **REWORK** | degraus ficam; contorno ganha torre |
| foreground | **REBUILD** | colunas e arcos da torre a enquadrar a arena |
| midground | **REBUILD** | **a Torre dos Céus** (a prancha diz `torre celestial`) |
| background | **REBUILD** | **lua vermelha** + aurora; 1,2 % de claros |
| plataformas · terreno | **KEEP** · **KEEP** | |
| props | **REWORK** | **símbolo celestial**, bandeiras, estátuas partidas |
| landmarks | **REBUILD** | a torre **é** o landmark, e não existe |
| boss presentation | **REWORK** | entrada e enquadramento, nunca ataques nem hitboxes |
| iluminação | **REWORK** | contraluz da lua atrás do Guardião |
| composição | **REBUILD** | a prancha compõe torre + lua + asas |
| identidade | **REBUILD** | |

**Auditoria do Guardião fica para o Prompt 4**, contra o
`GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md`, que já tem escala medida
(2,6× Koliani de corpo, 3,5–3,7× de largura) e paleta amostrada.

---

## F. PLANO DE ASSETS

**Reutilizar (KEEP):** os 4 ficheiros de terreno `desfiladeiro`
(topo/corpo/lado/base) — a cor bate, ao contrário da Região III; os 25
props do catálogo; `ceu.png`, `serras.png`, `nuvens.png`, `falesias.png`;
os FX de vento (o N10 prova que se lêem); o rig do Guardião.

**Refazer (REBUILD):** o **tratamento** do mar de nuvens (R1) — o asset
serve, o pipeline é que o apaga; as silhuetas de fundo, hoje uma só
receita para os cinco níveis.

> **CORRIGIDO no Prompt 2.** Estava escrito que essa receita era o
> `_forma_penhasco`. Não é: com `fundo_pack` preenchido — e estes cinco
> níveis têm-no — o `_gerar_parallax` sai antes de lá chegar, e o
> `_forma_penhasco` é código morto para a Região II. As silhuetas vêm das
> texturas do pack, e a variação por nível fez-se a recompô-las
> (`PERFIS_ALTITUDE`).

**Extrair das pranchas:** variações de terreno com **vinhas vermelhas** e
com **gelo**; **ponte com arcadas**; **queda de água**; **torre celestial**;
**altar em ruínas**; **pedra de memória**; **inscrições**; **símbolo
celestial**; **estátua partida**; **lua vermelha**; **aurora**; **raios
distantes**. Base: `tools/extrair_props_regiao02.py`, que já existe.

**Criar em variantes:** 2–3 gárgulas e estátuas distintas, para cumprir R7.

**Abandonar:** nada. `cruz` e `lapide` estão na pasta mas **fora** do
catálogo — não há nada a remover do `deco.json`. A cruz que se vê no N09
vem do fundo e trata-se lá.

---

## G. MAPA DE RISCO

| Risco | Gravidade | Mitigação |
|---|---|---|
| **Partir o gameplay do N08** (LOCKED) | **Alta** | R8 + R9; baseline antes/depois; N08 só recebe mudanças de fundo e `z=-1` |
| **Deslocar o `_rng` e mudar os 100 níveis** | **Alta** | R9. Aconteceu na Região III; o instrumento que o apanha já existe |
| **Clarear a região e lavar terreno e inimigos** | Média | R1 trata **só** a camada de nuvens; o comentário do `atmosfera.gd:141` avisa disto e tem razão |
| **Repetição entre os cinco** | Média | R2 + R4 + R7: ambiente, landmark e props distintos por nível |
| **Tapar a leitura do gameplay com primeiro plano** | Média | Lição da Região III: MEDIUM em densidade foi **escolha**, não falha. Preferir legibilidade |
| **Mexer no Guardião** | Média | Prompt 4 isolado; só apresentação |
| **Divergir da arte aprovada** | Baixa | Medição contra a prancha em cada fase, como no §A |
| **Perseguir a luminância e não a alcançar** | **Real** | O ganho 1.7 já falhou. Se as três vias de R1 não derem 20 %, **dizer que não deu** e propor o que falta, em vez de arredondar |

---

## H. ORDEM DE EXECUÇÃO

A divisão sugerida no briefing agrupa por nível. Proponho **agrupar por
sistema**, com uma razão forte: o mar de nuvens, as silhuetas de fundo e o
`_rng_deco` são **partilhados pelos cinco**. Fazer N06–N07 primeiro
obriga a mexer no mesmo código outra vez em N08–N10, com o dobro do risco
de deslocar o `_rng`.

| | Conteúdo | Porquê aqui |
|---|---|---|
| **Prompt 2** | **Fundo e altitude nos cinco** (R1, R2): mar de nuvens a chegar ao ecrã, uma silhueta por nível, lua vermelha, aurora, raios | É a causa medida de 90 % da distância. Sem isto, tudo o resto é maquilhagem sobre preto |
| **Prompt 3** | **Arquitectura de primeiro plano + landmarks** (R3, R4): ponte, torre partida, queda de água, altar, Torre dos Céus | Foi o que mais rendeu na Região III; depende do fundo já estar lá |
| **Prompt 4** | **Props, luz e anti-repetição** (R5, R6, R7): extrair das pranchas, acender, distribuir | Barato e de alto retorno, mas só se lê depois do fundo |
| **Prompt 5** | **Guardião dos Céus** contra o contrato visual | Isolado, para a luta não ser tocada por engano |
| **Prompt 6** | **Auditoria por eixo + regressão + produção** | O fecho da Região III, replicado |

Se o Paulo preferir manter a divisão por nível, a ordem menos arriscada é
**N07 → N08 → N06 → N09 → N10**: o N07 já quase lá está e serve de
referência; o N08 é o que mais ganha só com fundo; o N06 é o que exige
mais e beneficia de se fazer com o método já afinado.

Cada prompt fecha com baseline funcional (R8) e medição de luminância
contra a prancha (R1).
