# 08 — Auditoria técnica (AGENT 8)

Modo: só diagnóstico. Nenhum script, cena, asset ou teste foi alterado. Todo o Godot correu pelo
wrapper de sandbox (`godot_sandbox.sh`, APPDATA descartável). Medições e capturas em
`docs/qa/global_audit/img/a8/`.

Pergunta do briefing: **há decisões de arquitetura que impedem o jogo de ficar parecido com o
design aprovado?** Sim. São quatro, e explicam a maior parte dos sintomas que o GM viu ("só a
Região I se aproxima", "mecanicamente fraco", "as implementações divergiram dos boards").

---

## Números de base (medidos)

| Medida | Valor | Fonte |
|---|---|---|
| Scripts em `scripts/` | 174 ficheiros, 48 645 linhas | `wc -l` |
| `gerador_corredor.gd` | **5 528 linhas**, 140 funções, **98 câmaras `_f_*`**, 346 chamadas `_rng.` | `scripts/gerador_corredor.gd` |
| `koliani.gd` | **2 874 linhas** | `scripts/koliani.gd` |
| `tests/run_tests.gd` | 4 735 linhas (um ficheiro) | |
| Níveis com jornada procedural (`corredor = true`, que é o valor por omissão) | **97 de 100** (só N8, N10 e N30 são salas sem jornada) | `nivel_com_chefe.gd:43` + grep às 100 cenas; confirmado em runtime (coluna `corredor` do CSV) |
| Parte **procedural** da extensão horizontal (mediana) | N1–N30: **87 %**; N31–N100: **94 %** | runtime: `jorn_x` medido ÷ (`jorn_x` + `largura_nivel` da cena) |
| Extensão da jornada | N1 2 963 px → N96 38 701 px (mediana 25 113 px) | `a8_carga_100_headless.csv` |
| Nós por nível após construir | 164 a 4 146 (mediana 2 660); N1 = 767 | idem |
| Manifesto de níveis | 30 `authored`, 70 `generated`/ownership `unknown` | `data/level_manifest.json` |
| Chefes | 70 níveis usam `ChefeGenerico` (7 arquétipos, 362 linhas); 56 cenas têm `Guardiao` | grep às cenas |
| Flags visuais da Koliani | `usar_golden_set` = true nas 100 cenas; `usar_prototipo_premium` = true nas 100; `usar_piloto_visual_5g` = true em **0** | grep às cenas |
| Código dedicado à Região I | ≈2 230 linhas (`l1_hybrid_9h12e.gd` 764, `region1_hybrid_visual_target.gd` 720, `regiao1_kit/remaster/inimigos`, `vfx_regiao1`); para a II–XX não há nada equivalente (`tema_regiao.gd`, 150 linhas, é genérico) | `wc -l`, grep |

---

## CAUSA-RAIZ 1 (P0) — O nível **é** o gerador. As cenas e o manifesto "authored" são só a sala do chefe

**CURRENT STATE.** O `nivel_com_chefe.gd` cria um `GeradorCorredor` em todos os níveis com
`corredor = true` (`nivel_com_chefe.gd:90-96`), e esse é o valor por omissão (`:43`). Só 3 cenas
o desligam. Os 29 níveis "refeitos à mão" de 2 set 2026 voltaram a ter a jornada ligada no
commit `8ad92193` ("JORNADA outra vez ligada"). O manifesto chama `authored` aos N1–N30, mas o que
está desenhado à mão é **só a sala final**: em runtime, a mediana da parte procedural é de 87 % nos
N1–N30 e de 94 % nos N31–N100. As cenas 31–100 têm uma mediana de **71 linhas de `.tscn`**
(Atmosfera, líquido, chão do chefe, chefe, Koliani, checkpoint, porta). O próprio
`tools/gerar_niveis_31_100.py:17-20` escreve "AVISO HONESTO: um nível destes é uma jornada
procedural temática com um chefe no fim".

**WHAT WORKS.** É determinístico (ver causa 4), garante continuidade e escala para 100 níveis com
checkpoints, luzes e reparação de alcance (`_garantir_alcance`, `:5286`). Foi o que permitiu ter a
campanha inteira jogável.

**WHAT DOES NOT WORK.**
- **A identidade de cada nível sai de aritmética, não de um board.** `_vertical_do_nivel =
  ["torre","poco","pilares"][_idx % 3]`, `_especial_do_nivel = [...][(_idx / 2) % 4]`
  (`gerador_corredor.gd:1022-1026`). A "cara" do nível é um ciclo de módulos, com um `PERFIL` de 3
  números (`{v,f,a}`, `:670`) e uma linha em `MECANICA_DO_NIVEL` (`:331`).
- **A espinha é sempre a mesma gramática**: líquido mortal em toda a extensão e plataformas de
  100–160 px (`:1188`) a um passo de 148–188 px (`:1317`), com câmaras enfiadas pelo meio. É por
  isso que 40+ níveis parecem iguais: qualquer câmara nova aparece dentro da mesma espinha. Capturas
  `img/a8/a8_n56_jorn_01.png` e `a8_n96_jorn_02.png` mostram o líquido a ocupar dois terços do ecrã.
  São teleportes: a Koliani caiu no líquido, e a imagem mostra o **enquadramento**, não uma
  passagem jogada.
- **O gerador contradiz-se a si próprio sobre o alcance.** Em runtime, o log do próprio gerador
  diz: **N34: 51/110 plataformas por alcançar; N46: 97/134; N50: 143/155** (`carga100.log`, mensagem
  de `gerador_corredor.gd:5339`). Pode ser um falso positivo do modelo de alcance, que não conhece as
  mecânicas desses níveis (bombas de lava, areia movediça, bola a rolar), ou pode ser um softlock
  real. **Não verificado com bot**, mas a garantia anti-softlock prometida no cabeçalho (`:10-16`) não
  está provada nesses três níveis.
- **Um nível à mão tem de lutar contra o gerador partilhado.** O N12 foi "reconstruído" metendo uma
  fila de câmaras forçadas **dentro** do gerador (`_n12_fila`, `:836`, `:1009-1011`, `:1304`) e mais
  quatro ramos `if _regiao == 2 and _idx == 11` (`:1526`, `:2487`, `:2530`, `:3128`). Há mais um caso
  especial por índice (`_idx == 20`, `:1794`). Cada nível que se quiser desenhar a sério vai
  acrescentar ramos a um ficheiro de 5 500 linhas que os 97 níveis partilham.
- **O conteúdo depende do estado global, não da cena.** `_idx = EstadoJogo.indice_nivel` e
  `_regiao = EstadoJogo.regiao_atual()` (`:997-999`). A mesma cena aberta com outro índice gera outro
  nível. Reordenar `EstadoJogo.NIVEIS` muda o conteúdo de todos os níveis. Não se pode abrir um
  `.tscn` no editor e ver o nível que se joga.

**BENCHMARK GAP.** Celeste, Hollow Knight e The Lost Crown desenham cada sala para uma ideia
(teach → combine). Dead Cells gera, mas monta **salas desenhadas à mão** num grafo por bioma.
Não gera a sala a partir de parâmetros. O Koliani gera a geometria em si.

**KOLIANI OPPORTUNITY.** O catálogo de 98 câmaras `_f_*` e os actores (sinos, vitrais, portal,
pêndulo, gancho, correntes...) são um vocabulário rico. O potencial está em fazer disso **salas-
peça desenhadas** (cenas `.tscn` pequenas por bioma, com arte de região) que um montador encadeia.
É o modelo do Dead Cells, mas com a mecânica-assinatura de cada nível.

**ACTION: MAJOR REWORK (P0).** O nível passa a ser uma lista de salas-peça (autorais ou por bioma)
declarada na cena ou no manifesto, e o gerador fica só como montador. A jornada procedural deve
passar a ser opt-in, e não o valor por omissão.

---

## CAUSA-RAIZ 2 (P0) — A arte aprovada só chega onde houve código à medida: a Região I

**CURRENT STATE.** A Região I tem ≈2 230 linhas de código visual dedicado (L1 Hybrid 9H.12E, alvo
visual híbrido, kit, remaster, inimigos, VFX), ligadas nas 5 cenas da região e em
`plataforma.gd`/`plataforma_flutuante.gd`/`main.gd`. Para as outras 19 regiões, a arte chega por
três vias genéricas: uma cor de líquido por região (`LIQUIDO`, `:112+`), ramos pontuais de
decoração por `_regiao == 1/2` com `_rng_deco` (`:1657`, `:1668`) e o bloco `Atmosfera` escrito por
`tools/afinar_atmosfera.py` (pack de fundo + tinta). O próprio `LIQUIDO` documenta duas correções
("a mesma faixa verde-oliva chapada") feitas região a região.

**WHAT WORKS.** O Golden Set da Koliani está ligado nas 100 cenas (`usar_golden_set = true`), por
isso a protagonista é coerente em todo o jogo.

**WHAT DOES NOT WORK.** Não existe um **pipeline de região** (kit de terreno + props + câmaras-peça
+ inimigos + VFX, validado contra a prancha) que se repita. Cada região "remodelada" passa por
patches no gerador partilhado (Região II: arquitetura do desfiladeiro,
`_arquitetura_frente_desfiladeiro`; Região III: texturas `SINO_M_TEX`/`VITRAL_*` "só o N12 os
preenche", `:63-67`). É isto que explica "só a Região I se aproxima": não é falta de assets, é que o
caminho até ao ecrã só foi construído uma vez. O `afinar_atmosfera.py` e o
`gerar_niveis_31_100.py` reescrevem blocos de `.tscn`. Agora estão protegidos por staging e pelo
manifesto (bom), mas os 70 níveis gerados continuam com ownership `unknown`.

**BENCHMARK GAP.** Hollow Knight: cada região tem o seu tileset, props, inimigos e música, e a
identidade vive nos dados da região, não em `if` no gerador.

**ACTION: MAJOR REWORK (P0).** Um "RegionKit" como recurso de dados (terreno, props, liquido, fundo,
peças de sala, inimigos, VFX), do qual o montador e as plataformas leem. O código da Região I serve
de referência para extrair esse contrato, não para ser copiado 19 vezes.

---

## CAUSA-RAIZ 3 (P1) — Morrer reconstrói o nível inteiro: o retry fica mais lento à medida que a campanha avança

**CURRENT STATE.** `koliani.gd:2769`: `Transicao.fechar_e(get_tree().reload_current_scene)`. Cada
morte volta a instanciar a cena e a jornada volta a construir-se no frame seguinte, em
`call_deferred`.

**Medido (tempo de parede, `Time.get_ticks_usec`, `img/a8/a8_carga.gd.txt`):**

| Nível | frame de construção da jornada (janela real, 2.º monitor) | idem headless | `_ready` da cena (headless) |
|---|---|---|---|
| N1 | 127 ms | 116 ms | 312 ms (a 1.ª carga inclui a compilação) |
| N13 | 208 ms | — | — |
| N84 Palácio de Sangue | **698 ms** | 859 ms | 120 ms |
| N96 O Reino Antes da Corrupção | **718 ms** | 942 ms | 126 ms |

Headless, nos 100 níveis: o frame de construção vai de 5 ms (N30, sem jornada) a 942 ms, com uma
mediana de **185 ms**. O custo total cresce com a região (R1 ≈1,0 s com a compilação a frio, R19
≈0,59 s a quente). A primeira carga a frio compila scripts: 1,3 a 2,3 s.

`perf_gate` (janela real, 12 s, bot `--frente`, `img/a8/a8_perf_n1.json.txt` e
`a8_perf_n96.json.txt`): N1 p99 6,6 ms, 1 frame acima de 50 ms (1 recarga). N96 p99 12,1 ms,
**6 frames acima de 50 ms (máx. 139 ms) e 6 recargas por morte**, o que dá um pico por morte.
Fora das recargas os dois níveis correm a 165 Hz (p50 6,06 ms). **Não há stutter de
gameplay em regime permanente.** A correlação pico ↔ recarga é inferida pelas contagens iguais (6
e 6); não isolei frame a frame.

`Transicao.fechar_e` (`transicao.gd:20-29`) faz um fade de 0,22 s, recarrega e faz um fade de
0,22 s. O frame de 0,7 s cai no início do fade-in, por isso o ecrã fica mais tempo a preto e o
fade salta. Não verifiquei isto visualmente frame a frame.

**BENCHMARK GAP.** No Celeste, retry < 0,5 s sem carregar nada. Aqui, nos níveis finais, há ≈0,85 s
de tempo morto a mais por morte, precisamente onde se morre mais.

**ACTION: PARTIAL REWORK (P1).** Respawn sem `reload_current_scene` (repor actores e a Koliani no
checkpoint; o `recuperar_no_checkpoint` já existe em `koliani.gd:2772`) ou cache da jornada
construída. Isto fica também mais simples se a causa 1 for resolvida.

---

## CAUSA-RAIZ 4 (P1) — Um único `_rng` sequencial para o mundo inteiro: determinístico, mas frágil

**CURRENT STATE.** `_rng.seed = hash("jornada4|%d" % _idx)`, com um `_rng_deco` separado
(`gerador_corredor.gd:1006-1007`). O RNG é consumido 346 vezes, em sequência, por 98 câmaras.

**Medido.** Construí cada nível duas vezes e comparei as posições de todos os corpos estáticos e
checkpoints da jornada: **geração idêntica em 100/100**. A primeira comparação dava 41 diferenças,
mas eram as `AnimatableBody2D` (plataformas móveis) a mexer-se entre as amostras. Excluídas essas,
sobraram 4 (N47, N56, N58, N59), e o diff mostra que são só `porta_trancada.gd` a deslizar
(`a8_determinismo_19_98.csv`). O RNG está bem semeado e **não há não-determinismo**.

**WHAT DOES NOT WORK.** O stream é partilhado dentro do nível e o código é partilhado entre níveis:
mudar o número de sorteios de uma câmara desloca tudo o que vem a seguir, **em todos os níveis que
usam essa câmara**. A equipa já sabe disto: o N12 teve de ser feito "sem tocar no `_rng` dos outros
níveis" (`docs/retomar_aqui.md`, topo), com uma fila forçada em vez de uma sala. Qualquer afinação
de uma câmara é, na prática, um re-roll de dezenas de níveis que já foram vistos ou aprovados.

**ACTION: TUNE (P1).** Uma semente por câmara (`hash(idx, indice_da_camara, tipo)`) isola as
alterações. Com salas-peça (causa 1), o problema desaparece quase todo.

---

## Outras observações técnicas

### Lógica duplicada / legado dormente na Koliani (P2 — TUNE)
`koliani.gd` (2 874 linhas) mantém **cinco rigs** por `const RIG` (`codigo`, `gothic`, `cavaleiro`,
`nova`, `shadowblade`: 12 ramos, `:735-738`, `:2036`, `:2136`) e **três camadas de variante** por
instância (`usar_prototipo_premium`, `usar_piloto_visual_5g`, `usar_golden_set`, `:497-507`).
Estado real nas 100 cenas: golden ligado, premium ligado (mas anulado pelo golden,
`anims = {}` em `:797-803`) e 5G **nunca** ligado. O 5G continua a servir de seletor de locomoção
do golden (`_anim_locomocao_piloto_5g`, `:1812`, `:1853`). Isto funciona, mas qualquer mudança de
animação tem de atravessar 8 combinações, das quais 7 estão mortas. Há ≈1,8 MB de pastas de rigs
não usadas (`koliani_gothic`, `_nova`, `_cavaleiro`, `_visual_pilot_5g`, `_premium_v1`). Não tem
impacto visível hoje; é um risco de regressão.

### Câmara (P2 — TUNE) — STATIC ONLY para a jogabilidade
Não há nenhum `limit_*` em `scripts/` (grep vazio) nem zonas de câmara por sala ou arena. O
`camera_tremor.gd` (184 linhas) tem look-ahead e deadzone vertical bem afinados e documentados
(smoothing desligado de propósito por causa da interpolação física a 165 Hz: medido e com
hipóteses descartadas, **KEEP**). Sem limites, a câmara mostra o que fica por baixo do mundo e as
emendas dos fundos (`a8_n96_jorn_02.png`: retângulos magenta e azul por baixo do líquido, captado
num teleporte). Numa arena de chefe não há enquadramento fixo.

### Processamento fora do ecrã (P2 — KEEP/TUNE)
Os contentores da jornada levam `VisibleOnScreenEnabler2D` de 3 400×2 500 px
(`gerador_corredor.gd:1469`). Em janela, no N96, os corpos de física ativos ficam em média em 8
(`fis_activos`). Funciona. As salas autorais não têm enabler, e o commit `bcac9fde` acrescentou
gating por actor (fogo, guilhotina, torreta, raio, raiz, pedra) e no áudio. Nota: em headless o
enabler é desligado de propósito, por isso as contagens `proc` headless (até 219) são pessimistas.

### Spawning
Inimigos e perigos nascem na construção da jornada, todos de uma vez (até 3 616 nós numa só
jornada) e não à entrada da sala. O pico de construção da causa 3 vem daqui. Não medi spawns em
runtime além disso. **STATIC ONLY.**

### Save real e ferramentas (P1 — TUNE)
- `tools/correr_testes.ps1` isola por `%APPDATA%` e confirma por SHA256: **correto**.
- `tools/correr_bot_r2.sh`, `correr_bot_r3.sh`, `capturar_regiao3.sh` e `correr_testes.sh` isolam só
  por `XDG_DATA_HOME` (`correr_bot_r2.sh:20,45`). **No Windows isto não isola nada**: correm contra o
  save real. É uma armadilha ativa (STATIC ONLY: não os corri crus, de propósito).
- `tools/perf_gate.gd:115-132` faz backup e reposição do `user://progresso.json` real em vez de
  isolar. Se o processo morrer a meio, o save fica trocado.
- A suite corrida crua (`--path . res://tests/run_tests.tscn`) continua a escrever no save real
  (documentado no CLAUDE.md). O isolamento vive no wrapper, não na suite.

### Monólitos
`gerador_corredor.gd` (5 528), `koliani.gd` (2 874), `tests/run_tests.gd` (4 735). O gerador é o
que custa: mistura geometria, dificuldade, decoração, luz, mecânicas, arte por região e casos
especiais por índice num só ficheiro.

---

## Pontos fortes a preservar
- **Geração determinística** (100/100 medidos) e contrato de mobilidade por fase da campanha
  (`_subida_max`, `NIVEL_SALTO_DUPLO`, `vao_possivel` medido na física, `:5251`).
- **Desempenho em regime permanente**: p50 6,06 ms e p99 6,6–12 ms a 165 Hz no N1 e no N96; sem
  órfãos nem fugas (`orfaos` = 0).
- **Câmara com interpolação física** bem estudada (`camera_tremor.gd:29-57`).
- **Manifesto de ownership + staging** nas ferramentas que reescrevem `.tscn`
  (`data/level_manifest.json`, `gerar_niveis_31_100.py`).
- **Vocabulário de mecânicas** (98 câmaras e dezenas de actores) reutilizável como salas-peça.
- **Pipeline visual da Região I**, que é a prova de que a arte aprovada chega ao ecrã quando há um
  caminho dedicado.

---

## RUNTIME VERIFIED vs STATIC ONLY

**RUNTIME VERIFIED** (Godot pelo wrapper de sandbox):
- tempos de carga e de construção dos 100 níveis em headless (`a8_carga_100_headless.csv`) e de
  N1/N13/N84/N96 em janela real no 2.º monitor;
- determinismo da jornada (2 construções por nível, 100/100);
- `corredor` efetivo por nível e extensão da jornada vs sala;
- avisos de alcance do gerador (N34, N46, N50);
- frame times em janela real (N1 vs N96, `perf_gate`, 12 s, 165 Hz) e recargas por morte;
- capturas `img/a8/*.png` (teleportes, não passagens jogadas).

**STATIC ONLY — NOT RUNTIME VERIFIED:**
- se N34/N46/N50 são softlocks reais ou falsos positivos do modelo de alcance;
- o efeito visual do frame de 0,7 s no fade de respawn;
- a ausência de limites de câmara numa passagem jogada (só vista em teleporte);
- os bots `XDG_DATA_HOME` a escrever no save real no Windows (dedução pelo código; não os corri
  crus);
- as 8 combinações de rig/variante da Koliani (leitura de código);
- o spawning em runtime além das contagens de nós.

## Save real
SHA256 de `%APPDATA%\Godot\app_userdata\Koliani\progresso.json` no fim da auditoria:
`9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238`. **Igual ao de antes (não mudou).**
