# Execution 9H.17 CONTINUATION — a Região I inteira em Hybrid (13 set 2026)

Ramo `codex/9h16-l1-perfection`. Commits desta execução: `24b9eef8` (Hybrid
L3/L4/L5), `ca4fb0e1` (segurança do Novo Jogo), `3a39300b` (isolamento dos
testes).

---

## 1. O degrau de qualidade era real, e media-se

O `serve()` do `l1_hybrid_9h12e.gd` só cobria os perfis 1 e 2. O L3/L4/L5
continuavam a esticar **3×** um panorama de **952×247** — e não era só o
fundo: `plataforma.gd` liga o **corpo orgânico** (9H.17 I3) pela MESMA
chamada, por isso aqueles três níveis ainda tinham o bloco rectangular em
mosaico enquanto o L1/L2 já tinham silhueta irregular. Um único interruptor
explicava as duas queixas.

A prova visual está em `L3_antes.png` vs `L3b.png` (capturas de runtime): o
"antes" é pixel-art chapada com arestas pretas sobre um fundo desfocado
saturado; o "depois" é a linguagem do L1.

## 2. As composições não foram inventadas

`data/regiao1/remaster.json` **já declarava** a identidade de cada nível, e
foi ela que mandou:

| nível | tema | o que manda |
|---|---|---|
| L3 | `ruinas_da_viuva` | ruinas 0,85 · lanternas 0,60 · cascatas 0,20 |
| L4 | `cascatas_da_seiva` | cascatas 0,90 · corrupcao 0,60 |
| L5 | `coracao_corrompido` | corrupcao 1,80 · densidade 1,45 · lanternas 0,12 |

As peças `lanterna` e `cristais` do kit 9H.12E **nunca tinham sido usadas** —
eram o vocabulário que faltava para separar os níveis sem os tornar cópias.

## 3. Duas coisas que se perdiam em silêncio

- **O landmark do L5.** `_montar_heart_tree()` é um nó VAZIO com a meta
  `baked_into`: a Heart Tree vivia na coluna pintada do panorama. Trocar o
  fundo sem mais nada APAGAVA o landmark que a 9H.7 pôs lá para o jogador não
  chegar ao chefe sem o ver. Volta como peça própria, ancorada em
  `landmark_visto_em = 3060`.
- **As teias do L3.** O comentário prometia "losango + fios" e só desenhava o
  losango: um `Polygon2D` chapado a 50% de alfa. Era a última arte de
  protótipo no plano de jogo. Ganhou os fios; a colisão não mudou um número.

## 4. A baseline dos testes que o briefing trazia estava errada

O briefing dizia **26 falhas conhecidas**. Medido no ramo, a baseline eram
**2** — e ambas na suite PRINCIPAL, no mesmo teste
(`teste_execution_9c_kit_ambiente_regiao1`), não numa suite auxiliar. As duas
mediam nomes que a arquitectura já não escreve. Corrigidas mantendo os
dentes.

A auditoria da 9H.7 passou a contar as peças de identidade pela meta `peca`
em vez do nome das camadas do legado. **Os limiares são os mesmos** (≥14
ruínas no L3, ≥14 cascatas no L4, ≥12 cristais no L5) — e foi preciso subir
mesmo as densidades para lá chegar, não baixar o teste.

**Suite: EXIT 0.**

## 5. O save do Game Master foi apagado — e porquê

Durante o QA, o *Novo Jogo* substituiu a campanha do Paulo (nível 1-5, 239 de
essência). Reposta e verificada por SHA256.

A confirmação em dois passos **já existia e está bem feita**. O que faltava:
`_armado` só era limpo DENTRO das acções, nunca ao navegar. Armava-se o NOVO
JOGO, percorria-se o menu, e a campanha morria à primeira tecla de volta —
sem segundo aviso, e com o aviso laranja ainda no ecrã colado a outro item.
Sair do botão passa a desarmar (teclado e rato).

Teste novo guarda a GARANTIA, não a implementação. **Provado que morde**: sem
a correcção falha em três pontos, incluindo *"voltar ao NOVO JOGO apagou a
campanha sem novo aviso"*.

## 6. A suite de testes também escrevia no save real

Descoberto por acaso e é o achado mais feio desta execução: a essência do
Paulo foi **239 → 0** depois de duas corridas de `run_tests.tscn`. Não foi o
playtest.

O cabeçalho do `run_tests.gd` promete que os testes de save usam uma cópia de
`estado_jogo.gd`, e para ESSES é verdade — mas o autoload `EstadoJogo`
continua vivo na cena de testes, e basta um teste mexer-lhe e outro provocar
uma gravação.

A correcção não foi caçar testes: foi não os deixar ver o save. No Windows o
`user://` resolve por `%APPDATA%`, por isso `tools/correr_testes.ps1` lança o
motor com o APPDATA num sandbox e **confirma por SHA256** que o save real
ficou byte a byte igual. Zero linhas do jogo alteradas. O `CLAUDE.md` passa a
mandar correr por aí.

---

## 7. QA JOGADO — o que ficou PROVADO e o que NÃO ficou

### Controlo de input: PROVADO

`PostMessage(WM_KEYDOWN/WM_KEYUP)` para o handle da janela entrega teclas
reais ao Godot **sem foco**, com a janela no segundo monitor **e até
minimizada** (uma das teclas foi enviada nesse estado e contou). O ecrã
principal do Paulo fica livre. Ferramenta: `scratchpad/tecla.ps1` (fora do
repo — é instrumento de sessão).

Duas armadilhas medidas:
- **o salto é de altura variável** (`koliani.gd` passa `is_action_pressed`
  além do `just_pressed`): toques de 90 ms davam o salto MÍNIMO, e era isso
  que travava a Koliani. Com 330 ms segurados o percurso abre-se;
- em `pt-PT`, `[double]"0.5"` dá **5** — os instantes dos saltos iam parar ao
  fim do percurso. Parsing em cultura invariante.

### Travessia: PARCIAL — nenhum nível certificado

**NORMAL PROGRESSION CERTIFIED LEVELS: NENHUM.**

O que se conseguiu mesmo, em campanha normal, sem Dev, sem salto duplo:
- a Koliani **atravessou o 1-1 do spawn (x=150) até à arena do chefe** e a
  barra do **GHORAK** apareceu no ecrã (captura guardada);
- numa das travessias chegou a meio **sem perder uma única vida** (5/5);
- essência 0 → 620 ao longo das tentativas (a essência não se perde na morte).

O que NÃO se conseguiu: **matar o Ghorak**. O chefe mata-a antes, a run
reinicia no início do nível, e o ciclo repete. Sem visão contínua entre
comandos, o combate de chefe às cegas não converge.

**Portanto: L1, L2, L3, L4 e L5 continuam SEM PASS.** Não há prova de
atravessar nenhum nível de ponta a ponta.

### Limitação do método, dita com todas as letras

Conduzir um platformer por rajadas de teclas com uma fotografia no fim de
cada rajada é caro e não converge num combate de chefe. O padrão que resultou
melhor foi avançar **aos saltos curtos com paragem entre eles** (correr a
direito leva-a ao pântano); para o chefe faz falta ou um laço de
observação-acção muito mais apertado, ou um humano.

---

## 8. Por verificar (ficou por fazer nesta execução)

- **L2 — QA visual durante o percurso** (desfoque, seam, jitter, vegetação a
  flutuar, aresta de pouso). Só há capturas estáticas, não percurso jogado.
- **Trace do salto duplo**: confirmar em jogo que L1–L5 não o dão e que o
  chefe do L5 o concede e PERSISTE (save / restart / Continue). O código diz
  `HABILIDADE_DO_CHEFE = {4: "salto_duplo"}`; falta a prova jogada.
- **Agente independente de QA** com notas /10 e crítica.
- **Costuras**: a métrica de aresta recta não separa uma aresta de recorte de
  uma parede de plataforma (o jogo está cheio de verticais legítimas). O que
  se pode afirmar é comparativo: L3/L4/L5 (0,56–0,90) caem na MESMA banda que
  o L1/L2 aprovados (0,61–0,77) — nenhuma classe de costura nova.
- **"DEVELOPER MODE" aparece no menu da build de release** (9H.17 D pô-lo lá
  para QA). Para uma build pública parece errado — decisão do Paulo.

## 9. Dívida técnica não tocada, por instrução

`WARNING: 7x ObjectDB instances were leaked at exit` — **PRE-EXISTING TECH
DEBT, NÃO ABORDADO**. Não causa crash, corrupção de save nem crescimento de
memória em jogo.
