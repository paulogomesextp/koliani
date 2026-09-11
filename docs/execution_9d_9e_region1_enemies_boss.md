# Execution 9D+9E — Inimigos da Região I + Coração Putrefacto

Data: 11 de setembro de 2026. Estado: **PARTIAL PASS.**
**REGION I ENEMY PRODUCTION GATE: CLOSED. REGION I BOSS PRODUCTION GATE: OPEN.
Pronto para a 9F: NÃO** (falta o boss).

## A. Git no início

`master`, HEAD `a870363` = `origin/master`; sem commits novos do Luís.
Preservado e fora dos commits: a reordenação `ui_*` do `project.godot` (do
editor, do Game Master) e todos os não rastreados do `git status`.

## B. Autoridade

- `C:\Projetos\koliani\work\production_art_gate\9D1_game_master_approved\region1_enemies_boss_visual_authority_v1_0.png`
- 1536×1024, **RGBA**, PNG, 2 790 735 bytes
- SHA-256 `8ebf8ecd13e8d7e7d803acfcccf3361a35cb77ff9ad6dd1d01c79b8b24ebb2fd`
- **GAME MASTER APPROVED** (Paulo, briefing 9D+9E). Aberta e lida; nunca regravada.
  O produtor recusa correr se o SHA mudar.

Uma pose de identidade por entidade, em painéis com molduras e rótulos. Os
comuns e as crias têm um **xadrez cinzento desfocado** por trás (transparência
falsa incorporada); os guardiões, um **cinzento-escuro liso** com vinheta; o boss
está **pintado dentro da arena** (névoa magenta, pedras, sombra roxa).

## C. Inventário (runtime atual)

| # | Entidade | Runtime | Níveis | Papel | Estados alcançáveis | Estado |
|---|---|---|---|---|---|---|
| 1 | goblin | `DemonioBase` especie goblin | L1 (EliteGoblin, GoblinBaixa) | carga/patrulha | idle, run, hit, dead | INTEGRADO |
| 2 | mushroom | especie mushroom | L2 (EliteCuspidor) | cuspidor | idem | INTEGRADO |
| 3 | gosma | especie gosma | L2 (1), L4 (3) | patrulha/saltador | idem | INTEGRADO |
| 4 | besouro | especie besouro | L3 (4) | patrulha/trepador | idem | INTEGRADO |
| 5 | lodo | especie lodo | L5 (EliteLodo) | carga | idem | INTEGRADO |
| 6 | Ghorak | `ChefeGhorak`, rig ghorak | L1 | guardião | idem | INTEGRADO |
| 7 | Morvanna | `ChefeMorvanna` | L2 | guardiã (flutua) | idem | INTEGRADO |
| 8 | Rainha Aracnídea | `ChefeRainhaAracnidea` | L3 | guardiã | idem | INTEGRADO |
| 9 | Entrevane | `ChefeEntrevane` | L4 | guardiã (enraizada) | idem | INTEGRADO |
| 10 | Clone de Morvanna | `DemonioBase` largado por `_largar_clones` | L2 | invocação | idle, run, hit, dead | INTEGRADO |
| 11 | Cria da Rainha | `DemonioBase` nascido de `_ovo_em` | L3 | cria | idem | INTEGRADO |
| 12 | Coração Putrefacto | `ChefeCoracaoPutrefacto`, rig coracao_putrefacto | L5 | boss (2 fases) | idle, hit, dead (+ overlay do núcleo, pulso por escala) | **PRODUCTION ASSET MISSING** |

Confirmado no código: nenhum guardião da Região I usa `chefe_generico.gd`, por
isso `atacar_anim()` nunca corre e `attack` não é estado alcançável. O telégrafo
é por código (`DemonioBase._telegrafo` → modulate quente; `ChefeBase._piscar` →
modulate 1.7/1.25/1.5). No boss, a troca de frame por fase (`_atualizar_frame`)
mexe no `Corpo`, que o rig esconde: hoje as fases não se distinguem na arte.

## D. Arte de produção

Ferramenta: `tools/produzir_inimigos_regiao1.py` (só Pillow, determinística).
Por entidade: recorte da caixa do painel → máscara por inundação a partir da
borda (fundo = píxel sem cor e liso; mais: sombra/aura escura muito lisa;
buracos fechados com assinatura de fundo; anel cinzento claro do xadrez e halo
escuro descascados; ilhas < 12 px fora) → redução BOX com alfa
pré-multiplicado → alfa 0/255. **Classificação B** (reconstrução técnica segura)
para as 11: nenhuma cor inventada, nenhum píxel repintado.

Contrato (no manifesto):

- comum: canvas **128×96** (era 96×96: o besouro e a gosma da autoridade medem
  94–104 px de largura a 48 de altura), corpo 48 px, pivot (64,88), baseline 88;
- guardião: 192×192, corpo ≤100 alto / ≤110 largo (a regra que o `ChefeBase`
  já aplica, portanto `_normalizar_escala` dá k = 1), pivot (96,180).

Estados, todos derivados só por píxel inteiro (a autoridade tem **uma pose**):

| estado | frames | fps | derivação |
|---|---|---|---|
| idle | 4 | 5, ciclo | translação 0/0/−1/−1 px |
| run | 6 | 10, ciclo | balanço vertical 0…−2 px |
| hit | 3 | 12 | recuo −3/−2/−1 px |
| dead | 6 | 10 | dissolução Bayer 4×4 (0 → 83 %) |

| entidade | caminho | corpo | escala |
|---|---|---|---|
| goblin | `…/enemies/production/goblin/frames/` | 65×48 | 0.324 |
| mushroom | `…/mushroom/frames/` | 60×48 | 0.312 |
| gosma | `…/gosma/frames/` | 95×48 | 0.403 |
| besouro | `…/besouro/frames/` | 100×48 | 0.378 |
| lodo | `…/lodo/frames/` | 88×48 | 0.322 |
| ghorak | `…/ghorak/frames/` | 110×63 | 0.382 |
| morvanna | `…/morvanna/frames/` | 110×84 | 0.466 |
| rainha_aracnidea | `…/rainha_aracnidea/frames/` | 110×49 | 0.297 |
| entrevane | `…/entrevane/frames/` | 110×75 | 0.364 |
| clone_morvanna | `…/clone_morvanna/frames/` | 52×48 | 0.353 |
| cria_rainha | `…/cria_rainha/frames/` | 99×48 | 0.608 |

11 × 19 = 209 frames. Manifesto: `enemy_production_manifest.json` (autoridade +
SHA, caixa na prancha, limiares, escala, contrato, SHA de cada frame).

**Limitação declarada (não é bloqueio):** sem ciclos articulados (pernas a
andar, golpe) — seriam poses novas, que a autoridade não desenha: APPROVED
DESIGN / PRODUCTION ASSET MISSING para esses ciclos. O corpo mexe-se inteiro.

**Validator v2** (`work/execution_9d_9e/validator/`): 33 PASS, 11 REVIEW. Os
REVIEW são `DETACHED_BODY_REGIONS`: todos os `dead` (a dissolução separa o corpo
de propósito) e os 4 estados do besouro (as patas vêm separadas do corpo na
própria autoridade). Revistos visualmente a 4×. 0 FAIL: canvas, RGBA, alfa real,
sem corte nas bordas, baseline ±2, sem xadrez, sem moldura, sem rótulo.

Três iterações de máscara até ficarem limpas (prova em
`work/execution_9d_9e/`): 1.ª deixava a aura do orbe da Morvanna, a sombra da
gosma, o halo da cria e o fundo escuro dentro do arco da Entrevane; corrigido com
as regras acima.

## E. Crias

- **MORVANNA CLONES = arte `clone_morvanna`** (item 10 da autoridade).
- **RAINHA OFFSPRING = arte `cria_rainha`** (item 11).
- **GOBLIN DEFAULT REMOVED = SIM** (na arte). Correção mínima: campo novo
  `DemonioBase.identidade_visual` (só escolhe a arte de produção); a Morvanna e a
  Rainha preenchem-no ao criar as crias. A `especie` continua `goblin`, por isso
  som, tamanho, vida, dano e IA são exatamente os de antes.

## F. Legado

- LEGACY NORMAL ENEMY ART VISIBLE: **NO**
- LEGACY GUARDIAN ART VISIBLE: **NO**
- LEGACY CORAÇÃO PUTREFACTO ART VISIBLE: **YES** (bloqueado, ver G)

O marcador de ponto fraco (losango rosa) que o `ChefeBase` desenha em todos os
chefes continua; é leitura de gameplay, não arte do corpo.

## G. Boss — bloqueado (condição C)

O Coração está **dentro** da cena: raízes escuras sobre névoa magenta, sombra
roxa e pedras, sem fundo de apresentação. Três máscaras determinísticas:

1. névoa magenta lisa → 99 % opaco (a arena entra);
2. casca escura → 99 % opaco (a sombra roxa é tão escura como a casca);
3. casca neutra + núcleo → 35 % opaco, mas **o contorno do coração passa a ser
   uma elipse geométrica e os troncos (tingidos de roxo) perdem-se**: lê-se como
   um coração a flutuar com gravetos, que o briefing proíbe explicitamente.

Derivação fiel tecnicamente impossível → não se integrou nada; o runtime monta o
rig legado (`bosses_anim/coracao_putrefacto`). Manifesto:
`coracao_putrefacto.status = PRODUCTION_ASSET_MISSING`, com o motivo e as
tentativas. **Precisa de uma fonte isolada do Coração** (alfa real ou fundo
liso), idealmente com as duas fases. A integração fica a um passo: entrada no
produtor + override de `_atualizar_anim` para `idle_f2` na fase 2 (desenhado,
não aplicado).

## H. Gameplay

**GAMEPLAY CONSTANTS CHANGED: NO.** Única mudança de código em jogo: o campo
`identidade_visual` e as duas linhas que o preenchem nas crias.

## I. Telégrafos

Inalterados (0,26–0,5 s, pisca + abana por código). Em runtime a arte nova não
os tapa: o Ghorak e a Rainha a preparar o golpe aparecem claros/rosados (é o
`_piscar`), os comuns em branco-quente. **Tempos alterados: NÃO.**

## J. Desempenho

Tempo de frame de parede (vsync off, 240 frames): L1 0,48 · L2 0,50 · L3 0,47 ·
L4 0,48 · L5 0,46 ms (9C com kit: 0,52–0,56 ms). **Regressão: NÃO.** Draw calls
64–75 contra 49–62 na 9C: um PNG por frame em vez de uma tira/atlas quebra o
batching. Irrelevante a este tempo de frame; um atlas por entidade seria a
otimização se um dia for preciso.

## K. Testes

- Validator v2: 33 PASS / 11 REVIEW (revistos) / 0 FAIL.
- Suite headless completa: **PASS** (rc 0).
- `teste_execution_9d_inimigos_regiao1`: agora inclui o boss (espera legado) e o
  SHA de cada frame integrado contra o manifesto.
- `teste_9d9e_crias_sem_goblin` (novo): invoca os clones (L2) e choca um ovo
  (L3, tween avançado com `custom_step`), exige `identidade_visual`, `especie`
  goblin e frames da pasta da cria. **Provado que morde:** sem a linha na
  Morvanna, rc 1 com «cria sem identidade 'clone_morvanna'» e «…carrega
  goblin/frames/idle_01.png». Reposto, rc 0.
- L1–L5 carregam; combate (golpe e morte) corrido em runtime em todos os comuns.

## L. Evidência de runtime (`C:\Projetos\koliani\work\execution_9d_9e\`)

Ferramenta: `tools/shot_inimigos_9d9e.tscn` (é cena: em `--script` os
autoloads não existem). 65 PNG em `runtime\` com o registo de que textura estava
no ecrã em cada foto (`runtime\registo_9d9e.json`):

- `folha_runtime_L1..L5.png` — cada inimigo e guardião no ambiente 9C: idle,
  telégrafo, hit e (comuns) morte; textura = pasta de produção em todas;
- `folha_runtime_guardioes_crias_boss.png` — os 4 guardiões, os clones da
  Morvanna, as crias da Rainha e o Coração (legado);
- `validator\*_rel.md` e `resumo.json`; `testes.log`, `testes_mutacao.log`.

## M. Windows

v0.15.19, commit `dc06608`, worktree limpo `.worktrees/export-9d9e` (0
alterações). `build/windows/Koliani.exe`: 165 105 864 bytes, SHA-256
`a6eb9128079ac928b07f5c041d5bbf408e23445d029516e3ad6fd243dd28fe6a`. Smoke no EXE
real (`-- --nivel=N --foto=`): L1–L5, 5/5 rc 0, `build=0.15.19`, fotos em
`work\execution_9d_9e\runtime_exe\`, folha `evidencia_exe_9d9e.jpg`. Userdata
copiado antes e reposto depois, idêntico por SHA. As fotos do EXE são no ponto de
nascimento (sem inimigos no enquadramento); a arte de cada inimigo está provada
em runtime a partir do mesmo commit e o PCK traz os caminhos de produção.

## N. Web/PWA

Mesmo commit e worktree. `build/web/index.pck`: 55 937 724 bytes, SHA-256
`03bb35c1bf5ee185477aafffebd518e9af4e947547ef706d9a2d3ea475a4daa0`; cache do
service worker **`1789146809|5457071`** (9C: `1789112478|4547531`). Servido numa
origem nova (`koliani-web-9d9e`, porta 8072): **SHA calculado no browser = o do
export**, nenhum service worker a controlar a página, menu em v0.15.19, New Game
arranca.

Higiene dos dois builds: 0 × `res://work/`, 0 × `.worktrees/`, 0 × `_source`,
0 × `execution_9d_9e`. O caminho da autoridade e do Master Package aparecem só
como **texto** dos manifestos JSON (backlog conhecido: excluir
`assets/**/manifest.json` dos exports); nenhuma imagem de referência entrou.

## O. Git no fim

- `dc06608` — produtor, 209 frames + manifesto, `identidade_visual`, testes,
  ferramenta de evidência, v0.15.19 (só a linha da versão do `project.godot`);
- commit seguinte — este relatório, `retomar_aqui.md`, `PRIORIDADES.md`,
  `.claude/launch.json`;
- `push` para `origin/master`, sem force.

## P. Bloqueio (único)

**Coração Putrefacto:** a autoridade não permite derivá-lo sem inventar o
contorno ou levar a arena atrás. Precisa do Coração isolado.

## Q/R/S

REGION I ENEMY PRODUCTION GATE: **CLOSED**.
REGION I BOSS PRODUCTION GATE: **OPEN**.
READY FOR 9F: **NO**.
