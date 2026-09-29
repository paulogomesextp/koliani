# Execution 9H.17 — Região I sem salto duplo, L2 e entrada Dev

Branch `codex/9h16-l1-perfection`. HEAD inicial `46e06e06`, final `c40ccc23`.
Build `C:/Projetos/koliani/build/windows/Koliani.exe`, release **v0.18.9**,
205 766 648 bytes, SHA256
`b1f81051309b34e031efd63612b080aa10a5a07487e069c337b0d6f09a39954d`.

## A coisa mais importante que se descobriu

O bloqueio do 1-3 que o Game Master apanhou **não era daquele sítio**. Era um
tecto errado em todo o lado, e só se via porque o salto duplo tinha deixado de
existir na campanha.

A Jornada (`gerador_corredor.gd`) construía a espinha com
`SUBIDA_MAX = 104 px` — um salto **mais** o salto duplo. Os cinco níveis da
Região I têm a Jornada ligada (`corredor = true`). E o salto duplo não se
ganhava em lado nenhum: as `HABILIDADES_INICIAIS` estão vazias e não há um
único `Coletavel` com `habilidade_id = "salto_duplo"` nos 100 níveis.

Medida a envolvente do salto simples **com a física do jogo**, não com
aritmética (`tests/run_alcance_9h17.tscn` — piloto sintético, salto sem corte,
agarrar-borda incluído porque é básico e está sempre lá):

| subida (topo→topo) | vão máximo entre bordas |
|---|---|
| 0 px | 140 px (170 falha) |
| 40–64 px | 110 px (140 falha) |
| 72 px | 80 px (110 falha) |
| 76–80 px | ≥ 60 px |
| **88 px e acima** | **impossível a qualquer vão** |

**O tecto físico está entre 80 e 88 px. Os 104 px estavam acima dele.**

## O que se mudou

- `SUBIDA_SIMPLES = 60` para os níveis 1–5 (`NIVEL_SALTO_DUPLO = 5`). O tecto
  vem do **contrato da campanha**, não do save da máquina: o modo Dev dá tudo,
  e uma jornada desenhada por cima disso fica intransponível para quem joga a
  sério.
- `_garantir_alcance()` — a Jornada promete na sua própria documentação que
  "cada plataforma está ao alcance de salto da anterior", mas isso era uma
  **intenção** espalhada por dezenas de sítios que escolhiam o passo em x e a
  subida em y sem se falarem. Agora há uma passagem que percorre a espinha por
  **ponto fixo** e baixa os degraus que ficam fora da envolvente.
- Faltava-lhe também a regra "não se sobe estando debaixo da barriga da
  plataforma" — a mesma que já custou ao projeto dois níveis com o chefe
  inacessível. Foi posta.
- Salas feitas à mão: N3 (poço), N4 (escada do tronco) e N2 (os **dois** ramos
  da bifurcação) tinham degraus de 80–108 px. Desceram para 59–64 px com a
  mesma forma; o N4 ganhou um ramo T5.
- `HABILIDADE_DO_CHEFE = {4: "salto_duplo"}` em `nivel_com_chefe.gd`:
  progressão, não saque — o baú sorteia, e um sorteio não pode decidir se o
  jogo continua jogável.

## Armadilhas de método (custaram tempo)

1. **Limite físico e alvo de desenho são coisas diferentes.** Ao usar uma
   margem de 15% como porteiro, o N1 reprovava por **2 px** num salto que se
   faz. O grafo passa a usar o limite medido puro; a margem só marca degraus
   "apertados".
2. **O `verifica_alcance.gd` desliga a Jornada** — mede a sala à mão. Não serve
   para este contrato. Daí o `verifica_mobilidade_9h17.gd`, que mede o nível
   **como ele é jogado**.
3. **Um crivo estático mente de duas maneiras**, e as duas apareceram: não
   conhecia as plataformas **flutuantes** (a rota baixa do N2 é feita delas)
   nem os **trampolins/elevadores** (o poço do N3 tem um no fundo, em
   (-3523, 494)). Sem isso reprovava níveis bons. Um "sem caminho" continua a
   ser uma **suspeita**, não uma prova.
4. **O gerador e o crivo têm de ter o mesmo modelo.** Discordaram muito tempo
   porque o gerador classificava uma plataforma como `movel` e o crivo não.
   Quando discordam, o que está errado é quase sempre o modelo, não a
   geometria.
5. `vao_possivel` escolhia o regime pelo tecto de **desenho** (60) em vez do
   tecto **físico** (80) — punha a tabela do salto duplo a responder por
   saltos simples.

## Fases D/E/F

- **D** — A entrada Dev existia; o que não existia era **visível**. Estava
  atrás de `OS.is_debug_build()`, e a build que o Game Master abre é de
  **release**. Havia um segundo alçapão pior: o `main.gd` só punha a **barra**
  Dev (FlyMode, troca de nível) com a mesma condição, portanto quem forçasse
  `--devmode` entrava em modo Dev **sem controlos**. Agora há um portão só,
  `EstadoJogo.entrada_dev_disponivel()`, aberto em release pelo interruptor
  `koliani/qa/entrada_dev`, que o export público desliga. O botão saiu do meio
  do ecrã para o canto **inferior esquerdo**.
- **E** — Fora o subtítulo "FLORESTA SAGRADA". Saíram com ele as duas riscas
  que o ladeavam: sem texto no meio ficavam dois traços órfãos no ar.
- **F** — **NÃO REPRODUZ.** O mapa tem as duas teclas na acção `pausa`
  (physical 80 e 4194305) e duas provas de runtime com teclas a sério mostram
  o Escape a abrir a pausa: em isolamento (`run_pausa_9h17`) e no jogo montado
  — Main + nível + HUD + Pausa (`run_pausa_nivel_9h17`). Falta confirmar com
  mãos na build de Windows.

## Fases G/H/I — o L2 e a arte

O fundo do L2 **está** desfocado, e mede-se porquê: vivia do
`region1_panorama_heart_tree.png`, **952×247**, esticado por todo o ecrã.

**E não há fonte nativa maior no repo:**

- o `_hd_x4` (3808×988) é esse mesmo ficheiro reamostrado — reduzido de volta
  a 952×247 difere do original **3,01/255** em média, e a energia de bordos
  por pixel cai de **1533 para 74**;
- as camadas de 1920×950 em `work/` são declaradas **pelo próprio manifesto da
  produção** como *"camadas ampliadas de recortes, não arte nativa 1920"*;
- a autoridade de arte da Região I inteira é **uma prancha de 1536×1024**, e o
  recorte do panorama dentro dela tem 748×370.

> **NATIVE ART REQUIRED — LEVEL 2 BACKGROUND HD.**

O que se fez com o que há — e que é a razão pela qual o L1 lê melhor — foi
deixar de **ampliar** uma tira pequena e passar a **compor** muitos recortes
nativos (130–300 px) perto da escala a que foram cortados. O passe Hybrid
9H.12E passa a servir o perfil 2, com arranjo e paleta próprios: o L2 é um
pântano, não o L1 com outro nome.

**Três peças de produção estavam no repo e nunca tinham sido ligadas:**

- `terrain_hd/plataforma.png` (290×275) — resolve a fase I3 inteira. Medida
  linha a linha: rebentos por cima (y 0–32), laje sólida (32–104, linha de
  pouso em y=36), barriga esfarrapada de raiz e rocha (104–275). Desenha-se em
  três fatias (ponta / meio repetido / ponta espelhada) e substitui as camadas
  antigas todas — miolo, sombra, gradiente, lados, franja, capa e rim-light —,
  que eram justamente o que fazia o rectângulo.
- a mesma peça nas **flutuantes**: a rota baixa do L2 é feita delas, e vê-las
  com o degrau chapado do kit 9C ao lado das outras era a pior mistura de
  todas.
- `terrain_hd/corrupcao.png` (199×290) — poça de corrupção pintada, linha de
  água a 29,3% da altura. Entra atrás do líquido e dá leito ao pântano.

A fase H tinha uma causa exacta: numa plataforma do L2 (colisão 18 px,
`altura_visual` 26) a capa desce até y=39 e a franja também, mas as vinhas
eram ancoradas no fundo da **colisão**, em y=7 — ficavam tapadas 32 px e só
reapareciam já longe da pedra. **Escondida de mais é tão mau como escondida de
menos.** Além disso o que pendia por baixo eram **só vinhas**; por baixo de um
bloco agarra-se estrutura, e a folhagem vive em cima.

### O que fica em aberto

- **KOLIANI RUN — NATIVE ART REQUIRED.** Confirmado por medição própria, não
  por repetição: abertura das pernas nos 10 frames golden =
  38, 40, 39, 38, 38, 53, 44, 46, 43, 56 — **nunca fecha** (não há pose de
  passagem) e o centro de massa não alterna com período. Não há outra fonte no
  repo nem no histórico.
- **NATIVE ART REQUIRED — REGION I GROUND / SWAMP INTEGRATION** (só a faixa de
  superfície). O **leito** está resolvido com arte aprovada, mas fica uma faixa
  pálida na base do ecrã cuja origem **não se identificou** nesta execução:
  não é o corpo do líquido da Jornada (baixar-lhe o alfa não a mexeu) nem a
  `Faixa` nem o `Rebordo`, ambos já afinados na 9H.12D. Não se tapa com um
  gradiente.

## Áudio (fase J)

Auditoria técnica dos eventos que se ouvem **no L1/L2**, evento → ficheiro →
disparado: **26 eventos, todos mapeados, todos com ficheiro, nenhum em falta.**

- **23 NOVOS** — o passe de sonoridade 9H.13/9H.13B, mais os três que a 9H.16
  acrescentou (`raiz_aviso`, `raiz_irrompe`, `plataforma_surge`).
- **3 LEGADO**, de 4 set 2026 e os únicos `.ogg`: `agarrar`, `lancar`,
  `parede`. São os únicos que o passe de sonoridade não tocou.
- Qualidade subjetiva: **NOT ASSESSABLE — HUMAN LISTEN REQUIRED.**

## Testes

Baseline eram **26 falhas**. Ficaram **2**. Nenhuma nova — e as 24 que caíram
não foram caladas:

- 18 eram a regra da 9H.7B ("fonte ampliada tem de ser amostrada alinhada à
  grelha") a apanhar as peças do Hybrid, que nasceram **depois** dela e nunca a
  aplicaram. Aplicada. O L1 mudou 0,89/255 em média e ficou **3% mais nítido**
  — não é dano no nível Golden, é o achado tratado;
- 5 eram os eixos de luz volumétrica: gradientes em blend aditivo, sem grelha
  para conservar. A regra é para arte ampliada, não para luz;
- 1 era a moldura de vinhas, que no Hybrid vem da camada `*_frente` e não do
  `VinhasFrente` da prancha 08.

As 2 que ficam são da Execution 9C sobre o L1 usar o kit 9C e as camadas da
08 — ambas superadas pelo passe Hybrid, ambas decisão do nível Golden.

## Ferramentas novas

- `tests/run_alcance_9h17.tscn` — mede a envolvente de salto na física real.
- `tests/run_pausa_9h17.tscn` / `run_pausa_nivel_9h17.tscn` — o Escape na pausa.
- `tools/verifica_mobilidade_9h17.gd` — contrato de mobilidade por nível, com
  a Jornada LIGADA. `-- 0 1 2 3 4` para a Região I; juntar `duplo` força o
  tecto do salto duplo (é o **controlo**: se o nível também reprovar assim, o
  crivo está a mentir).
