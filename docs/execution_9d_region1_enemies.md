# Execution 9D — Inimigos e guardiões da Região I

Data: 11 de setembro de 2026. Estado: **BLOCKED na arte — APPROVED DIRECTION /
PRODUCTION ASSET MISSING.** Infraestrutura, inventário e guarda: feitos.
**REGION I ENEMY PRODUCTION GATE: OPEN. Pronto para a 9E: NÃO.**

## A. Git no início

`master`, HEAD `2b97a18` = `origin/master`; sem commits novos do Luís. Trabalho
alheio preservado: `project.godot` (reordenação das acções `ui_*` feita pelo
editor, não é da 9D) e os não rastreados listados no `git status`. Nada disso
foi para o commit.

## B. Autoridade

- 08 (`840cfd82…`, 1536×1024 RGB): existe, legível, SHA = manifesto. Desenha
  ambiente, **nenhum inimigo**.
- Kit 9C em produção (`production/kit_9c/`): verificado, intacto.
- Pranchas 10, 11 e 12 revistas à procura de criaturas. **A 12 (secção 10) tem
  inimigos incidentais** (duas plantas carnívoras, um besouro escuro, um morcego,
  uma gosma verde) com ~30 px, em RGB sem alfa, pintados sobre o cenário, numa
  prancha de dia chamada «Floresta Sagrada» (nome não canónico, a 9C já a tratou
  só como referência estrutural). **Não se extraem:** tirar-lhes o fundo é a
  remoção de fundo contaminado que o contrato proíbe (5D, 9A), e a resolução não
  chega para frames de produção.

**Conclusão:** para inimigos não há autoridade de onde *derivar* arte. Produzir
é desenhar de raiz, ou seja, design novo (política, condição A) sem uma
ferramenta que o faça com qualidade (condição F). É o mesmo bloqueio da 9B.1,
que só se resolveu quando o Game Master entregou o Golden Set.

## C. Inventário (medido no código e nas cenas)

Tamanho no ecrã: comuns normalizados a 48 px de corpo (`ALTURA_ALVO_INIMIGO`),
vezes a escala do nó; guardiões a 100 px × `escala_visual`, com teto de 110 px
de largura. Koliani: 64 px.

| Inimigo | Níveis | Papel | Rig atual | Estados alcançáveis | Função visual | Estado | Ação |
|---|---|---|---|---|---|---|---|
| goblin | L1: EliteGoblin (carga, ×1,4), GoblinBaixa (patrulha); **L2 clones da Morvanna; L3 aranhas da Rainha** | corpo-a-corpo, investida | LuizMelo CC0, 150×150 | idle 4, run 8, hit 4, dead 4 | ler a investida (0,42 s de telégrafo) | MISSING | precisa de folha |
| mushroom | L2: EliteCuspidor (cuspidor, ×1,35) | cospe projéteis | LuizMelo CC0 | idem | ler a pontaria (0,5 s) | MISSING | precisa de folha |
| gosma | L2: 1 patrulha; L4: 1 patrulha, EliteSaltador (×1,4), 1 saltador | salto em arco | ansimuz CC0, 73×68 | idle 8, run 7, hit 8, dead 4 | agachar antes do salto (0,26 s) | MISSING | precisa de folha |
| besouro | L3: 2 patrulhas, EliteTrepador (×1,4), 1 trepador | cai do teto | ansimuz CC0, 53×56 | idle/run/hit/dead 4 | ler-se de cabeça para baixo (`scale.y = −1`) | MISSING | precisa de folha |
| lodo | L5: EliteLodo (carga, ×1,45) | investida | 0x72 CC0, 16 px ampliado | 4/4/4/4 | investida | MISSING | precisa de folha |
| Ghorak | L1 guardião (1,2) | raízes, baque | motor de chefes (polígonos) | idle, run, hit, dead | núcleo no peito | MISSING | precisa de folha |
| Morvanna | L2 guardiã (1,35, flutua) | mãos, clones | motor | idle, run, hit, dead | idem | MISSING | precisa de folha |
| Rainha Aracnídea | L3 guardiã (1,4) | investida, teias, ovos | motor | idle, run, hit, dead | idem | MISSING | precisa de folha |
| Entrevane | L4 guardiã (1,25, enraizada) | galho, gotas, raízes | motor | idle, run, hit, dead | idem | MISSING | precisa de folha |

Fora de âmbito: Coração Putrefacto (L5) é da 9E.

**Três descobertas que o próximo passo tem de saber:**

1. **O `attack` dos guardiões nunca se vê.** `ChefeBase.atacar_anim()` não é
   chamado em lado nenhum. Os rigs têm 10 frames de ataque que nunca tocam, e os
   comuns não têm estado de ataque. **O telégrafo é todo por código**: pisca
   branco-quente e abana (`_telegrafo`, `DemonioBase._process`). A arte de
   produção só precisa de idle/run/hit/dead. Uma pose de preparação ajudava a
   leitura, mas pô-la a tocar durante `_telegrafo` é uma alteração visual à parte.
2. **As aranhas da Rainha (L3) e os clones da Morvanna (L2) são goblins.**
   Instanciam `DemonioBase` sem definir a espécie, que por omissão é `goblin`.
   Os ovos de aranha eclodem em goblins a 0,62×. Isto é um buraco de identidade
   (as crias não se leem como aranhas) e é design novo: é preciso decidir que
   aspeto têm.
3. O `lodo` do L5 é um tile de 16 px ampliado: é o que se lê pior em toda a
   região.

## D. Arte de produção

**Nenhuma produzida.** Não se desenhou por código: seriam as «aproximações
poligonais» que a 9A proíbe e que já bloquearam a 9B.1. Não se recoloriram
sprites legados (proibido, secção 8). Não se promoveram os inimigos da
prancha 12 (ver B).

## E. Integração — o que ficou pronto

- `scripts/regiao1_inimigos.gd`: interruptor igual ao do kit 9C. Só liga com o
  nó `Region1HybridVisualTarget` na cena **e** com a entrada do inimigo em
  `PRODUCTION_INTEGRATED` no manifesto. Frames soltos (um PNG por frame) com
  fps/ciclo por animação.
- `DemonioBase._montar_frames` e `ChefeBase._montar_rig` perguntam-lhe primeiro.
  Se não houver entrada, o comportamento fica exatamente o de antes.
- Manifesto e contrato de frames em
  `assets/art/regions/region_01_forest/enemies/production/enemy_production_manifest.json`:
  comum 96×96, corpo 48 px, pivot (48,88); guardião 192×192, corpo 100 px,
  pivot (96,180), largura até 110 px; tudo virado para a direita, RGBA 0/255,
  VFX fora do corpo.
- **Gameplay alterado: NÃO.** Nenhuma constante, tempo, colisão, posição, IA ou
  vida mudou.

**Para integrar quando houver arte:** pôr os PNG em `<id>/frames/`, validar
com `python -m tools.production_asset_validator.cli` (contrato BODY com o
canvas acima; os pressupostos da Koliani não estão fixados no código do
validator, vêm todos do manifesto), preencher `animacoes` e o SHA de cada frame
no manifesto, mudar o `status` para `PRODUCTION_INTEGRATED` e correr a suite.

## F. Legado

**LEGACY NORMAL-ENEMY BODY ART VISIBLE IN REGION I: YES.** Dependências
exatas: `assets/sprites/pixel/enemies/{goblin,mushroom,gosma,besouro,lodo}/` e
`assets/sprites/pixel/bosses_anim/{ghorak,morvanna,rainha_aracnidea,entrevane}/`.

## G. Telégrafos

Inalterados: pisca e abana por código (0,26–0,5 s). Legíveis hoje, e a arte
não os tapa. Não se encontrou nenhum tempo avariado.

## H. Desempenho

Um `get_first_node_in_group` e uma consulta a um dicionário em cache por
inimigo, no `_ready`. Nada por frame. **Regressão: NÃO.**

## I. Testes

- Suite headless completa: **PASS** (rc 0).
- Teste novo `teste_execution_9d_inimigos_regiao1`: todos os inimigos e
  guardiões de L1–L4 (e o elite do L5) estão no manifesto, e cada um carrega a
  arte que o manifesto declara. **Provado que morde:** com o goblin marcado como
  integrado sem frames, a suite falha (rc 1, «EliteGoblin anim 'dead' carrega
  …/goblin/dead.png (integrado=true)»). O manifesto foi reposto.
- Validator: 10/10. L1–L5 carregam com 0 erros de script.
- `--check-only` dá «Identifier not found: Som/EstadoJogo»: é a armadilha
  conhecida dos autoloads em `--script`, não vem da 9D.

## J. Evidência de runtime

Não há arte nova para mostrar. A folha dos inimigos atuais (legado) foi gerada
só para o inventário, fora do repo.

## K/L. Windows e Web/PWA

**Não reexportados, de propósito.** O jogador não vê nenhuma diferença (o
interruptor cai sempre no legado), portanto um build novo seria igual ao da
9C (`a5d9ec9`, 0.15.18). A versão não subiu.

## N. Bloqueio (único e verdadeiro)

**Falta quem desenhe 9 famílias de inimigos**, cada uma com idle/run/hit/dead,
mais a decisão sobre o aspeto das crias de aranha e dos clones. É design novo
(condição A) e não se pode produzir com segurança (condição F).

Caminhos, por ordem de recomendação:

1. **O Game Master entrega uma prancha de inimigos da Região I** (como fez com
   o Golden Set), com alfa real ou fundo liso, ao contrato acima. A partir daí
   é tudo determinístico: extrair, normalizar, validar, integrar e exportar.
2. O Game Master autoriza explicitamente pixel-art desenhada por código como
   produção, sujeita a revisão visual (é o que a 9A e a 9B.1 recusaram).

## O/P

**REGION I ENEMY PRODUCTION GATE: OPEN. READY FOR 9E: NO.** (A 9E do Coração
Putrefacto tem o mesmo problema: também não há prancha para ele.)
