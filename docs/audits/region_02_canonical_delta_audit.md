# Região II — auditoria de delta canónico

Data: 2026-09-15
Base: `67b68b249513ee2801846f77b9ef5ed73309dff9`
Escopo: níveis 06–10, sem alterações runtime nem auditoria artística visual.

## 1. Referência e limites da prova

O cânone bloqueado define a Região II como **Desfiladeiro dos Ventos**:
falésias elevadas, ruínas góticas, pontes expostas, céu, montanhas, nuvens,
vegetação afetada pelo vento e partículas/linhas de vento. O vento tem de ser
força externa aplicada ao jogador ou ao ambiente.

Progressão mecânica requerida:

- N06: rajadas horizontais;
- N07: correntes ascendentes;
- N08: ilhas suspensas e planar/mobilidade aérea controlada;
- N09: vento variável combinado com inimigos e plataformas;
- N10: exame da região e Guardião dos Céus.

Esta auditoria é estática. A existência de geometria e scripts não prova
alcance, conforto, legibilidade ou diversão. A migração futura requer smoke,
validação de geometria/movimento e `HUMAN PLAYTEST REQUIRED`.

## 2. Arquitetura atual partilhada

As cinco cenas usam `scripts/nivel_com_chefe.gd`, `Koliani.tscn`,
`Plataforma.tscn`, `Porta.tscn`, `Atmosfera.tscn` e `checkpoint.gd`.
`corredor` conserva o valor default `true`, por isso o runtime prepende uma
jornada construída por `gerador_corredor.gd` à sala authored.

O perfil e o pool atuais ainda descrevem “Prisão dos Condenados”: correntes
mecânicas, elevadores, plataformas frágeis, guilhotinas, serras, espinhos e
outros perigos de prisão. O pool da Região II não inclui a câmara `vento`.
As instâncias `PlataformaCorrente` são plataformas penduradas/móveis; não
aplicam força de vento ao jogador.

Existe uma base reutilizável para força externa:
`CorrenteAr.tscn`/`corrente_ar.gd` chama `Koliani.soprar_para_cima()`, e o
gerador já possui `_f_vento()`. Essa implementação pertence hoje à Região III
e só cobre corrente ascendente; rajadas horizontais/variáveis precisam de
adaptação explícita, sem confundir movimento de plataforma com vento.

Música não é referida diretamente nas cenas: `musica.gd` resolve por índice.
Existem `nivel_06.ogg`–`nivel_10.ogg` e `boss_06.ogg`–`boss_10.ogg`. SFX são
chamados pelos atores/scripts partilhados. Devem ser preservados inicialmente
e reavaliados só depois do gameplay, para evitar misturar migração estrutural
com redesign sonoro.

## 3. Nível 06

**Cena:** `res://scenes/levels/Prisao_dos_Condenados.tscn`

### Estado atual

- Layout horizontal de aproximadamente 3,3k px, com rota alta/baixa e
  reencontro antes da arena.
- Plataformas: chão authored, três `PlataformaCorrente` (vertical, pêndulo e
  horizontal) e plataformas estreitas.
- Checkpoints: início, meio e reencontro.
- Spawn/exit: Koliani em `(150,620)`; porta em `(3260,626)`.
- Hazards: ácido de fundo e dois fogos.
- Inimigos: esqueleto elite e chort/goblin configurado sobre
  `DemonioBase.tscn`.
- Mecânicas: ramificação alta/baixa, plataformas móveis, travessia horizontal;
  não há rajada horizontal nem força externa de vento.
- Background/tiles/props: `Atmosfera` com `fundo_pack="prisao"`,
  `CascaMasmorra`, tons azul-escuros de prisão.
- Boss atual: `ChefeCarcereiro.tscn` numa arena de 600 px.
- Scripts especiais: `plataforma_corrente.gd`; controlador partilhado do nível.
- Áudio: faixa indexada `nivel_06.ogg`, boss `boss_06.ogg`; SFX indiretos.

### Preservação

| Elemento | Decisão | Fundamentação |
|---|---|---|
| Sequência, bifurcação, spawn, porta e checkpoints | KEEP | Boa base para introduzir vento horizontal sem reconstrução total. |
| Geometria das plataformas | ADAPT | Manter progressão, ajustar larguras/folgas apenas após testar rajadas. |
| Plataformas de corrente | KEEP_WITH_RESKIN | Movimento é reutilizável, mas a leitura prisional deve tornar-se ponte/ruína exposta. |
| Ácido e fogos | REPLACE | Não sustentam a assinatura do desfiladeiro; trocar por queda/abismo e perigos coerentes. |
| Inimigos | ADAPT | Preservar encontros/posições; substituir identidade e comportamento conforme pack regional. |
| Prisão, casca e paleta | REPLACE | Contradizem falésias, céu aberto e vegetação ao vento. |
| Rajadas horizontais e feedback visual | ADD | Mecânica canónica ausente. |
| Boss intermédio | REMOVE ou ADAPT | N06 não é exame regional; deve terminar como guardião/elite, não boss persistente. |

**STRUCTURE REUSABLE:** YES
**GAMEPLAY REUSABLE:** PARTIAL
**ART REUSABLE:** PARTIAL
**CANON GAP:** HIGH

## 4. Nível 07

**Cena:** `res://scenes/levels/Fornalha_dos_Pecadores.tscn`

### Estado atual

- Layout descendente inicial seguido de subida/duas faixas e reencontro;
  aproximadamente 3,2k px.
- Plataformas authored e uma `PlataformaCorrente` vertical chamada
  `CorrenteSobe`; é uma plataforma móvel, não corrente de ar.
- Checkpoints: início, meio e reencontro.
- Spawn/exit: Koliani em `(150,560)`; porta em `(3180,626)`.
- Hazards: lava, fogos e serra móvel.
- Inimigos: imp elite e chort/goblin.
- Mecânicas: mudança de altitude, plataforma elevatória e rotas altas/baixas;
  nenhuma força ascendente aplicada à Koliani.
- Background/props: `fundo_pack="masmorra"`, casca fechada, paleta quente de
  fornalha.
- Boss atual: `ChefeIgnivar.tscn` numa arena de 600 px.
- Áudio: `nivel_07.ogg`/`boss_07.ogg`; SFX indiretos.

### Preservação

| Elemento | Decisão | Fundamentação |
|---|---|---|
| Spawn, porta, checkpoints e progressão vertical | KEEP | Já oferece uma espinha adequada para ensinar subida. |
| Plataformas e rota dupla | ADAPT | Reposicionar após inserir colunas de ar; preservar a ordem de desafios. |
| `CorrenteSobe` | KEEP_WITH_RESKIN | Pode continuar como elemento móvel secundário, mas não satisfaz o requisito de vento. |
| Lava/fogo/serra | REPLACE | Substituir por abismo, detritos, espinhos/obstáculos de falésia conforme necessidade. |
| Correntes ascendentes com força externa | ADD | Reutilizar/adaptar `CorrenteAr`, com entrada, saída e alvo vertical legíveis. |
| Casca de masmorra e arte de fornalha | REPLACE | Necessário abrir o espaço ao céu e montanhas. |
| Inimigos/chefe | ADAPT/REMOVE | Preservar ritmo; N07 deve fechar com elite/guardião, não boss regional. |

**STRUCTURE REUSABLE:** YES
**GAMEPLAY REUSABLE:** PARTIAL
**ART REUSABLE:** PARTIAL
**CANON GAP:** HIGH

## 5. Nível 08

**Cena:** `res://scenes/levels/Corredor_das_Execucoes.tscn`

### Estado atual

- Gauntlet horizontal com guilhotinas, serra, plataforma quebrável e arena;
  aproximadamente 3,2k px.
- Checkpoints: início, meio e reencontro.
- Spawn/exit: Koliani em `(150,600)`; porta em `(3180,606)`.
- Hazards: ácido, quatro guilhotinas no percurso, serra, plataforma quebrável
  e guilhotina na arena.
- Inimigo principal intermédio: chort elite.
- Mecânica dominante: timing de execução/armadilhas; não há ilhas suspensas,
  planar nem mobilidade aérea controlada.
- Background/props: prisão fechada, `CascaMasmorra`, guilhotinas e tons frios.
- Boss atual: `ChefeDamaGuilhotina.tscn`.
- Áudio: `nivel_08.ogg`/`boss_08.ogg`; SFX dos hazards/boss.

### Preservação

| Elemento | Decisão | Fundamentação |
|---|---|---|
| Spawn/porta e marcos de checkpoints | KEEP | Preservam sessão/progressão, mesmo com forte remodelação do espaço. |
| Espinha horizontal e reencontro | ADAPT | Pode estruturar sequência de ilhas, mas exige conversão substancial. |
| Plataformas authored | REPLACE/ADAPT | Reorganizar como ilhas suspensas e aterragens; validar quedas e recuperação. |
| Guilhotinas, serra e ácido | REMOVE/REPLACE | Assinatura de execução incompatível com o foco aéreo. |
| Planar/mobilidade aérea controlada | ADD | Não existe neste nível; o suporte atual de planar só aparece muito mais tarde. É decisão de progressão a validar antes de editar. |
| Arte prisional | REPLACE | Requer céu aberto, ilhas, ruínas e profundidade vertical. |
| Encontro/boss atual | ADAPT/REMOVE | Preservar posição de clímax; trocar por elite regional adequada. |

**STRUCTURE REUSABLE:** PARTIAL
**GAMEPLAY REUSABLE:** NO
**ART REUSABLE:** PARTIAL
**CANON GAP:** HIGH

## 6. Nível 09

**Cena:** `res://scenes/levels/Ala_dos_Mortos.tscn`

### Estado atual

- Layout horizontal/ascendente com duas faixas e plataformas espectrais;
  aproximadamente 3,2k px.
- Checkpoints: início, meio e reencontro.
- Spawn/exit: Koliani em `(150,610)`; porta em `(3160,616)`.
- Hazards: ácido; o risco móvel vem sobretudo das plataformas espectrais.
- Inimigos: mastim elite e orc/goblin.
- Mecânicas: plataformas temporárias/espectrais combinadas com combate; não há
  vento variável nem força externa.
- Background/props: `fundo_pack="masmorra"`, casca fechada e estética mortuária.
- Boss atual: `ChefeIrmaosCondenados.tscn`.
- Áudio: `nivel_09.ogg`/`boss_09.ogg`; SFX indiretos.

### Preservação

| Elemento | Decisão | Fundamentação |
|---|---|---|
| Layout, spawn, porta e checkpoints | KEEP | A combinação de percurso e combate é adequada ao objetivo do N09. |
| Plataformas espectrais | ADAPT | Podem tornar-se plataformas/folhagem afetadas por vento variável. |
| Posições dos inimigos | KEEP/ADAPT | Já intercalam combate com plataformas; trocar elenco e testar interação com vento. |
| Ácido | REPLACE | Converter para abismo/queda coerente com falésia. |
| Vento variável | ADD | Introduzir zonas/direções telegráficas e evitar força imprevisível durante saltos cegos. |
| Arte mortuária/masmorra | REPLACE | Necessário reskin integral para céu, pontes e vegetação. |
| Boss atual | REMOVE ou ADAPT | N09 deve usar elite/guardião, reservando boss regional para N10. |

**STRUCTURE REUSABLE:** YES
**GAMEPLAY REUSABLE:** PARTIAL
**ART REUSABLE:** PARTIAL
**CANON GAP:** HIGH

## 7. Nível 10 e boss

**Cena:** `res://scenes/levels/A_Cela_Zero.tscn`

### Estado atual do nível

- Layout vertical compacto: subida por dois lados, ledge central e arena no
  topo; largura da casca 1484 px.
- Checkpoints: início e meio; não há checkpoint authored imediatamente antes
  do boss, embora o controlador comum possa criar um perto da arena.
- Spawn/exit: Koliani em `(180,810)`; porta em `(900,246)`.
- Hazard: ácido de fundo. Inimigo intermédio: orc elite.
- Mecânicas: subida por plataformas estreitas e escolha lateral; não recompõe
  horizontal gusts, updrafts, ilhas/planar e vento variável como exame.
- Background/props: prisão fechada e `CascaMasmorra`.
- Boss: `ChefePrimeiroPrisioneiro.tscn` em arena de 560 px.
- Áudio: `nivel_10.ogg`/`boss_10.ogg`; SFX do boss e sistemas comuns.

### Boss atual: O Primeiro Prisioneiro

- **Scene:** `res://scenes/actors/ChefePrimeiroPrisioneiro.tscn`
- **Script:** `res://scripts/chefe_primeiro_prisioneiro.gd`, especializado sobre
  `ChefeBase`.
- **Vida:** 480 na cena; `_ready()` garante pelo menos 570. Depois,
  `ChefeBase` aplica o multiplicador global de dificuldade do índice 9;
  o valor runtime é portanto superior e deve ser medido, não inferido como 570.
- **Fase 1:** combo de três golpes, dash, guarda/aparo e dardo espelho.
- **Fase 2 (<50%):** flutuação, teleporte, leque de três dardos e reforma com
  janela exposta.
- **Telegraphs:** brilho/piscar e estados dedicados; `dur_tel=0.5s` antes dos
  ajustes globais e da aceleração de fase 2.
- **Arena:** plataforma superior de 560 px, porta à direita, abordagem vertical.
- **Dependências:** `ChefeBase`, `DemonioBase`, rig animado
  `primeiro_prisioneiro`, sprite `primeiro.png`, música global e SFX
  `investida`, `demonio_ataque`, `projetil`, `chefe_cai`, `grito`.

### Preservação

| Elemento | Decisão | Fundamentação |
|---|---|---|
| Espinha vertical, duas rotas, spawn/porta/checkpoints | KEEP/ADAPT | Boa base para exame, mas precisa incorporar as quatro competências regionais. |
| Arena superior | ADAPT | Local e tamanho são reutilizáveis; deve suportar o Guardião dos Céus e vento telegráfico. |
| Ácido/casca prisional | REPLACE | Trocar por abismo, ruínas e céu aberto. |
| Primeiro Prisioneiro scene/script/arte | REPLACE | Identidade, ataques e narrativa contradizem o boss canónico. |
| `ChefeBase`, HUD, porta, sinais, recompensa e música | KEEP | Infraestrutura partilhada não depende da identidade do boss. |
| Ideias de telegraph/fases | ADAPT | Reutilizar padrões técnicos, não copiar o script especializado. |
| Guardião dos Céus | ADD | Criar cena/script/rig canónicos e ataques baseados em vento/posição aérea. |
| Exame cumulativo | ADD | Sequenciar rajada horizontal, corrente ascendente, travessia aérea e vento variável antes da arena. |

**STRUCTURE REUSABLE:** YES
**GAMEPLAY REUSABLE:** PARTIAL
**ART REUSABLE:** PARTIAL
**CANON GAP:** HIGH

**Boss reuse recommendation:** REPLACE o boss específico; KEEP a infraestrutura
`ChefeBase`/arena/porta/HUD e ADAPT apenas os conceitos de telegraph e fases.
**Arena reusable:** PARTIAL
**Script reusable:** NO (`chefe_primeiro_prisioneiro.gd`); a base partilhada é reutilizável.

## 8. Síntese de reutilização

| Nível | Estrutura | Gameplay | Arte | Gap |
|---:|---|---|---|---|
| 06 | YES | PARTIAL | PARTIAL | HIGH |
| 07 | YES | PARTIAL | PARTIAL | HIGH |
| 08 | PARTIAL | NO | PARTIAL | HIGH |
| 09 | YES | PARTIAL | PARTIAL | HIGH |
| 10 | YES | PARTIAL | PARTIAL | HIGH |

**Reutilização estimada:** alta para sessão, spawn/exit, checkpoints,
controlador comum e espinhas dos níveis 06, 07, 09 e 10; média/baixa para a
geometria do N08; baixa para identidade visual, elenco de bosses e mecânicas
canónicas de vento.

**Gaps principais:** o runtime continua a representar prisão/fornalha;
ausência de vento como força externa nos cinco níveis; planar aparece apenas
mais tarde na progressão; todos os cinco níveis ainda têm boss persistente;
Guardião dos Céus não existe.

**Mudanças de maior risco:** introduzir forças externas sem quebrar saltos e
combate; antecipar/atribuir planar sem decidir progressão; converter N08 sem
perder checkpoints; substituir o boss N10 mantendo save/recompensa/porta;
alterar gerador partilhado sem afetar outras regiões.

## 9. Ordem de migração recomendada

1. **Congelar e provar baseline:** registar geometria, checkpoints, caminhos,
   tempos e comportamento atual dos cinco níveis. Identificar os consumidores
   de qualquer script partilhado antes de o alterar.
2. **Criar contrato regional sem trocar layouts:** definir componente de vento
   horizontal/vertical/variável, telegraphs, limites de força e interação com
   Koliani. Resolver primeiro a decisão de progressão do planar do N08;
   `DESIGN DECISION REQUIRED` antes de editar habilidades.
3. **Migrar gameplay incrementalmente:** N06 rajada horizontal, N07 corrente
   ascendente, N09 vento+combate; validar cada mecânica com Koliani real. Depois
   remodelar N08 em ilhas usando checkpoints e marcos preservados.
4. **Aplicar identidade visual:** substituir casca/ácido/fornalha por céu,
   falésias, ruínas, pontes, montanhas/nuvens, vegetação e partículas. Preservar
   colisões até a mecânica passar; só então ajustar folgas.
5. **Reestruturar encontros:** converter N06–N09 em elites/guardiões e adaptar
   inimigos regionais, evitando bosses persistentes fora do exame.
6. **Boss N10:** manter arena/infraestrutura, substituir Primeiro Prisioneiro
   por Guardião dos Céus e montar exame cumulativo antes da arena.
7. **Validação:** import/smoke, verificação de geometria e movimento real,
   regressões de scripts partilhados, screenshots em renderer real e
   `HUMAN PLAYTEST REQUIRED`; `DEVICE VALIDATION REQUIRED` para mobile/Web.

## 10. Decisões que não devem ser tomadas oportunisticamente

- Momento e natureza do desbloqueio de planar no N08.
- Se o vento horizontal altera diretamente velocidade, aceleração ou apenas
  adiciona impulso; isto afeta física e sensação global.
- Política de conversão dos bosses N06–N09 para elites sem quebrar saves.
- Se a música/SFX atuais são preservados, reskinados ou substituídos.
- Se o gerador comum recebe mecânicas canónicas ou se a Região II usa scripts
  isolados para não contaminar outras regiões.
