# Progresso do agente `gaming` — campanha dos 30 níveis

## Sessão 2026-09-01 (noite, autónoma) — variedade Dead Cells

Continuação da reformulação Dead Cells (Fase 2 câmaras + Fase 2b inimigos)
sem o Paulo à frente. Ecrãs desligados durante a sessão.

**Entregas:** v0.8.7 `_f_crossfire` · v0.8.8 `cuspidor` · v0.8.9 `_f_ferry`
· v0.8.10 `_f_pedras` (+ bug) · v0.8.11 `_f_espinhos`. Tudo com testes
headless + `verifica_jornada.gd` (30 níveis) verdes. **Todos os números
por playtestar.**

### ⚠️ Erro meu: `git add -A` apanhou os packs em bruto (v0.8.7..v0.8.11)
- Os 5 commits de playtest usaram `git add -A` e arrastaram ~5026
  ficheiros / ~180 MB de `assets/sprites/incoming/` (10 packs que o Paulo
  largou: anokolisa, bdragon1727, codemanu, free-game-assets, glionox,
  ninjikin, piiixl, szadiart, thewisehedgehog, zerie). Só tinham
  `.gdignore`, não `.gitignore`.
- **Corrigido** (`0ec3745`): `git rm --cached` das 10 pastas (ficheiros
  ficam em disco) + regra no `.gitignore` para cada. O conjunto de
  ficheiros tracked ficou EXACTAMENTE como estava antes da sessão (o pack
  `kenney-pixel-platformer`, CC0, continua versionado).
- **PENDENTE p/ o Paulo:** os blobs continuam no histórico (9e5791f→).
  Limpar precisa de `git filter-repo` + `push --force` ao `master` — mexe
  no remote e parte o clone do Jensath. Decisão do Paulo.
- A partir daqui, nesta sessão: **nada de `git add -A`**, só paths
  explícitos.

### Inimigo "cuspidor" (v0.8.8)
- `demonio_base.gd`: novo `comportamento = "cuspidor"`. Patrulha e, à
  distância (`ALC_CUSPIR` 440 px, |dy| < 170, |dx| > 60), planta-se,
  telegrafa (`_windup` 0.5 s + pisca) e instancia uma `BolaFogo`
  (`PROJETIL_CUSPO`) na direção da Koliani, com a mira achatada em y
  (`Vector2(dx, dy*0.5).normalized()`) para ser mais legível de desviar.
  Dano do projétil = `dano_contacto * 0.9`. Recarga 1.8-2.8 s; entre
  cuspos anda como patrulha.
- `gerador_corredor.gd` `_inimigo_em`: entra nas opções de comportamento
  a partir de `_dif > 0.22` (a par de saltador/carga/trepador/escudeiro).
- **Falta playtestar**: alcance, cadência, se o projétil lê bem, dano.

### Câmara `_f_espinhos` — a forquilha do pogo (v0.8.11)
- Forquilha (abre em 2, reúne): calha BAIXA = tapete de `Espinhos`
  ("pogavel"), atravessa-se aos ressaltos com o **pogo** da Fase 1, com
  uma `_plat` por baixo de cada tira (falhar o pogo = dano + queda curta,
  não é o líquido); calha ALTA = fila de plataformas limpas, o caminho
  justo. Reúne num `_plat` sólido + checkpoint.
- Aproveita o `const ESPINHOS` que estava preloaded e sem uso.
- Pools **Prisão (1)** e **Catacumbas (3)**; `TIER 0.36`.
- **Falta playtestar**: espaçamento dos espinhos p/ o ritmo de pogo dar
  certo; se a calha alta chega bem ao reencontro.

### Bug + câmara `_f_pedras` (v0.8.10)
- A pool da região 3 (Catacumbas) listava `"pedras"` desde sempre, mas o
  `match` de `_flavour` **não tinha** `"pedras"` → caía no `return
  Vector2(x + 180.0, y)` (no-op): um vão morto de 180 px sem câmara, ~1
  em cada 8 câmaras geradas por pool nas Catacumbas.
- Novo `_f_pedras`: beiral sem tecto, `n` = 5 + 3·`_dif` degraus, uma
  `PedraQueda` por degrau — 1 em cada 3 `automatico` (ciclo/ritmo), as
  outras `raio_gatilho` 82. Sem tecto baixo (≠ `gruta`) nem parede
  interior (≠ `cripta`). Checkpoints a cada 2. `_pos_intenso`.
- NB descoberto nesta sessão: **nenhum nível tem `corredor = false`** — a
  abordagem "Casca + dungeon selada" das regiões II/IV foi revertida; a
  JORNADA corre em todos os níveis 1-29.

### Câmara "ferry / a travessia" (v0.8.9)
- **`_f_ferry`** (`gerador_corredor.gd`): fosso largo (`vao` 620-880 px +
  `220·_dif`) sobre o líquido, atravessado por UMA plataforma-balsa —
  `TumuloElevador` com `curso = Vector2(vao, 0)`, `auto = true`,
  `velocidade` 96 + 30·`_dif`. Duas `PenduloLamina` a 34%/70% do vão
  (blade a ~24 px acima do deck → desviar em pé, agachar não chega).
  Cais de embarque + cais de desembarque sólido + checkpoint forçado.
- Pools de **Torres (2)**, **Catacumbas (3)** e **Castelo (5)**;
  `TIER_FLAVOUR["ferry"] = 0.3`. Sem risco de softlock (a balsa faz
  vaivém → volta sempre ao cais).
- Smoke a 5 níveis OK. **Falta playtestar**: velocidade da balsa, se as
  lâminas ficam a uma altura justa, largura do vão.

### Câmara "fogo cruzado" (v0.8.7)

- **`_f_crossfire`** (`gerador_corredor.gd`): novo "tom" de câmara. Lanço
  recto de plataformas pouco onduladas com uma `Torreta` por passo,
  alternando de lado (esq/dir), a cuspir `BolaFogo` na horizontal a
  alturas ligeiramente acima/abaixo da linha de salto → o feixe cruza o
  caminho. É leitura de padrão / timing dos tiros, não plataforma difícil.
  `intervalo`/`telegrafo`/`dano`/`vel_bola` escalam com `_dif`. Saída
  sólida limpa + checkpoints a cada 2 passos. Marca `_pos_intenso` (entra
  um `_f_descanso` a seguir).
- Entrou nas pools das regiões **Prisão (1)**, **Cidade (4)** e
  **Castelo (5)**; `TIER_FLAVOUR["crossfire"] = 0.4` (só do ~Nível 13 em
  diante, na prática só se vê em Cidade/Castelo).
- Testes headless verdes; smoke a 5 níveis (Vila/Praça do Eclipse/Portões
  de Zeriko/Prisão/Floresta) sem erros de script. **Falta playtestar o
  feel** (ritmo dos tiros, se o fogo cruzado lê bem, dano).
- Entrega **v0.8.7**.

## Sessão 2026-09-01 — curva de dificuldade + pisão

Pedido do Paulo: (1) pisar inimigos = dano de espada + pulo automático;
(2) os níveis ficaram duros demais — dificuldade **básica no N1** a subir
até ao N30.

- **Pisão** (`koliani.gd`): já existia mas a janela era apertada e o
  ressalto fraco. Agora janela generosa (±46 px, banda vertical larga,
  gatilho a `velocity.y > 40`), ressalto forte (`STOMP_RESSALTO` 520 /
  `STOMP_RESSALTO_ALTO` 680 a segurar saltar) e **devolve os saltos de ar
  todos** → encadeia pisões.
- **Dificuldade** — tudo escala com `_dif = indice_nivel / 29`, quase a
  zero no N1:
  - `gerador_corredor.gd`: comprimento 6200 (N1) → ~32000 (N30); câmaras
    de flavour por **`TIER_FLAVOUR`** (N1 só saltos/gruta/trampolim);
    espaçamento das câmaras ~13 passos (N1) → ~4 (N30); perigo-no-vão
    `5%+50%·_dif`, inimigos `5%+22%·_dif`; plataformas móveis só
    `_dif > 0.33`; armadilhas com base de dano mais baixa e `_dif` mais
    íngreme. Seed passou a `jornada4|`.
  - `demonio_base.gd`: escala nos 30 níveis (antes parava no 4). N1 ≈
    ×0.8 vida / ×0.65 dano, N30 ≈ ×1.4.
  - `estado_jogo.gd`: `TEMPO_HARDCORE` reperfilado (170 s N1 → 640 s N30).
- Testes headless verdes; smoke a 4 níveis (N1/N11/N20/N25) OK. **Falta
  playtestar com o jogo a correr e afinar os números.**

Feedback seguinte do Paulo (mesma sessão):

- **Trampolins não funcionavam** (`trampolim.gd` + `koliani.gd`): o
  `Trampolim` mexia em `k.velocity.y` a partir de `body_entered`, mas o
  `Movimento.passo()` reescreve `velocity` do `_mov.velocidade` interno a
  cada frame → o impulso morria e a Koliani ficava pousada. Novo
  `Koliani.aplicar_impulso()` sincroniza os dois. E o `Trampolim` deixou
  de usar `body_entered` (só dispara à entrada) — passa a sondar
  `get_overlapping_bodies()` em `_physics_process`, por isso também salta
  quem lá anda por cima ou lá fica.
- **Checkpoints a menos** (`gerador_corredor.gd`): havia 20–40 por nível
  (um a cada ~2 plataformas). `_checkpoint()` agora só cria se estiver a
  ≥ `DIST_CHECKPOINT` (4000 px) do anterior; início e pré-chefe são
  `forcar=true`. Resultado ~3 (níveis curtos) a ~10 (N30) — ~90% menos.
- **Jornada 4.0 — verticalidade** (`gerador_corredor.gd`): a espinha era
  uma fita quase horizontal. Agora `_teto_y = _chao_y - lerp(640,1320)`
  (cresce c/ dificuldade); a espinha caminha para uma ALTITUDE-ALVO que
  vagueia por toda a banda; de 2 em 2-3 câmaras entra uma VERTICAL:
  `_f_torre` (subida ziguezague +700..1200), `_f_poco` (desce rente ao
  líquido, sobe pela parede oposta), `_f_pilares` (colunas **só visuais**
  + topos sólidos). Regra de ouro mantida: subida ≤ `SUBIDA_MAX` 104 px.
  **Bug corrigido logo a seguir**: as colunas de `_f_pilares` eram sólidas
  e cortavam passadeiras → "parede que não deixa passar". Passaram a ser
  sprites de fundo.
- **FLYMODE** (`koliani.gd` `alternar_voo()` + `dev_barra.gd`): botão só em
  DEVELOPER MODE (canto inf. esq., por cima das barras) + tecla F. Voa
  livre (setas/WASD, `VEL_VOO` 560), `collision_mask=0` → atravessa tudo,
  sem gravidade nem dano de fosso. Desligar = cai à plataforma. Para
  testar zonas distantes sem jogar o nível todo.
- **Reformulação "pegada Dead Cells"** (decidido c/ Paulo, ver
  `docs/reformulacao_deadcells.md`): passe de feel+arte, mantém a campanha.
  - Fase 1 feel (`koliani.gd`): **agarrar borda/mantle** (`_detetar_borda`),
    **wall-jump básico** (não precisa de `escalar_paredes`), **roll-cancel**
    (rolar corta o recovery do ataque), **pogo** em Serra/Espinhos (grupo
    `"pogavel"` + layer 6, raycast p/ baixo, i-frames apanham o toque).
    Falta afinar números (precisa playtest).
  - Fase 2 jornada (`gerador_corredor.gd`): **ritmo tensão/alívio** —
    `_f_descanso` (plataforma larga limpa + checkpoint) a seguir a câmaras
    puxadas e a cada 4.ª; **`_f_forquilha`** (caminho abre em 2 e reúne);
    **3 actos** (`prog`/`intens`: intro suave → meio a apertar → alívio
    pré-chefe) + **`ASSINATURA`** de região (câmara-cara do bioma no meio).
  - Fase 2b inimigos (`demonio_base.gd` `comportamento`): saltador, carga,
    **voador** (olho: paira + mergulha), **escudeiro** (bloqueia de frente).
  - Fase 4 rig da Koliani: **tentada e revertida** (ficou escura/pequena);
    `RIG = "codigo"`, infra do rig gothic fica na gaveta.
  - Entregas v0.8.0 → v0.8.4 (bump por entrega).

## Sessão 2026-08-31 (cont. 3) — JORNADA 3.0: chão MORTAL + assets

Feedback do Paulo: (1) os níveis tinham quase todos uma plataforma
contínua para andar em frente — pôr líquido mortal e obrigar a saltar;
(2) mapas muito abertos, quer túneis / subir-descer; (3) **analisar TODOS
os assets em `incoming/` e usá-los para melhorar o VISUAL**.

### `docs/assets_incoming.md` (novo) — catálogo completo
`tools/catalogar_assets.gd` varre os 19 packs CC0 em `incoming/` e regista
o tamanho real de cada PNG. Destaques por usar: **parallax** (ansimuz
Cold Corridors/Caverns/Magic Cliffs/Rocky Pass/Mountain Dusk/Gothicvania
Swamp+Church+Town, szadiart bg1-4, free-game-assets bg1-4+Clouds,
parallax_forest_pack v1/v2, underwater-fantasy); **monstros** (0x72 ~20
criaturas, luizmelo, zerie Orc/Soldier/Demon/Blood, chierit
FrostGuardian/DemonSlime/Minotaur bosses, clembod BringerOfDeath, ansimuz
HellHound/Ghost/Spider, gothicvania burning-ghoul/wizard/angel,
kings-and-pigs); **efeitos** (bdragon1727 Fire/Green/**Purple**/Water
bullets 16×16 + Free/Part 16-36 explosões; codemanu 20 folhas de magia
600-1100px; gothicvania fireball/enemy-death); **tilesets** (kenney 180
tiles, szadiart mainlev_build, 0x72, anokolisa HighForest, gothicvania);
**traps** pixel-adventure (RockHead, SpikeHead, SpikedBall, Trampoline,
FallingPlatform, Fan); **props** (0x72 column/crate/skull, glionox 1244
items 16×16, gothicvania town props).

### Jornada 3.0 (`gerador_corredor.gd`, v0.7.0)
- **Chão = líquido MORTAL** em toda a extensão (`AguaVenenosa` dano 999 →
  morte → checkpoint), cor por região: água podre (floresta), ácido
  (prisão/cidade), trevas (torres/catacumbas), **LAVA + brasas** (castelo).
- Por cima, **espinha de plataformas** pequenas e espaçadas, sobe/desce,
  com perigos nos vãos. Cair = morte.
- Anti-softlock sem rede: cada plataforma ao alcance de salto da anterior
  (Δx ≤ 196, subida ≤ 100); móveis com deriva pequena; ~40-65 checkpoints
  por nível; última câmara = passadeira sólida que encosta ao nível.
- 15 câmaras de flavour à volta da espinha (saltos ziguezague, serras/
  pêndulos/guilhotinas/fogo em corredor, rítmicas, trampolins, correntes,
  elevadores, ponte que esboroa, coluna de vento, gravidade lunar, rajada,
  túnel de gruta desce/sobe, par de portais).

### +10 monstros (0x72, v0.7.1)
`tools/extrair_monstros_0x72.gd` → `enemies/{imp,chort,orc,xamane,`
`demonio_grande,ogro,abobora,wogol,necromante,lodo}/` (frames ampliados
nearest). `DemonioBase.ESPECIES`/`@export_enum` alargados; `ESP_REGIAO`
da jornada usa um leque diferente por região.

### Props (0x72, v0.7.2)
`assets/sprites/pixel/props/` (column/crate/skull/estandartes); o gerador
espalha-os pelas plataformas + colunas altas a subir do líquido no fundo.

### A SEGUIR (visual)
Parallax mais rico por bioma (cidade/castelo com Gothicvania town/church);
efeitos bdragon1727 Purple nos projéteis + Kamehameha; codemanu na morte
dos chefes; tilesets kenney/szadiart nas plataformas; props glionox.

### UI moderna — pedido do Paulo (31 ago), feito por outra sessão (Luís, 31 ago)
Menu de escolha de níveis + resto dos ecrãs de UI já não estão "muito
básicos": `MenuInicial`, `SeletorNiveis`, `Pausa`, `Opcoes`, `Diario` e
`MapaMundo` ganharam glow/profundidade nos painéis e botões, hover animado
(escala), destaque claro na ação principal de cada ecrã (LOAD/NEW GAME,
Continuar, idioma ativo, PLAY) e sliders de volume na paleta roxa.

No `SeletorNiveis` especificamente: cada cartão mostra agora o retrato do
chefe (frame de repouso das tiras já existentes em
`assets/sprites/pixel/bosses/*.png` — não desenhado por código) e a badge de
região passou a incluir o progresso ("Rotting Forest · 0/5"). O Carcereiro
(nível 6) ainda não tem retrato porque ainda usa o SVG antigo, não a
pixel-art — fica sem imagem no cartão até ganhar sprite novo.

**Ainda por fazer** do pedido original: transições mais elaboradas ao trocar
de cartão/ecrã (o que há é a animação cover-flow existente, nada novo aqui),
e um "passe" mais profundo ao `MapaMundo` (por agora só ganhou o mesmo
tratamento de título com glow — layout continua simples).

### Arranque preparado mas NÃO aplicado — efeitos roxos nos projéteis
Folha `assets/sprites/incoming/bdragon1727/Effect and Bullet 16x16/Purple
Effect and Bullet 16x16.png` (576×208, 36×13 células de 16px). Frames já
escolhidos: **orbe a girar** = linha 0, cols 30–35 (6 frames) para o corpo do
`ProjetilKoliani`; **anel de impacto** = linha 5, cols 14–17 (4 frames) para o
estoiro do projétil e do Kamehameha (escalado). Plano: `tools/extrair_efeitos_
roxos.gd` → `assets/sprites/pixel/fx/{bala_roxa,impacto_roxo}.png`; trocar os
`Polygon2D` procedurais de `ProjetilKoliani.tscn`/`KamehamehaKoliani.tscn` por
`Sprite2D` com `hframes`; manter a `PointLight2D`; `_estoirar()` instancia a
tira de impacto em vez de `impacto.svg`. Creditar em
`assets/sprites/pixel/CREDITS.md`.

## Sessão 2026-08-31 (cont.) — JORNADA 2.0: câmaras de plataformas a sério

Feedback do Paulo: "os níveis continuam pequenos, quero MUITO mais
plataformas e mecânicas, vá buscar assets e mude completamente os mapas".

- **`gerador_corredor.gd` reescrito outra vez** — o percurso deixa de ser
  "corredor com perigos" e passa a ser a maior parte do nível: câmaras
  **multi-nível** cheias de plataformas, reutilizando TODAS as mecânicas de
  plataforma do jogo (`PlataformaFlutuante`, `PlataformaRitmada`,
  `PlataformaCorrente`, `TumuloElevador`, `ZonaGravidade`, `CorrenteAr`) +
  3 novas.
- **Mecânicas novas**: `PlataformaQuebra` (esboroa ao pisar),
  `Trampolim` (atira para cima + `Koliani.devolver_saltos_ar()`),
  `Impulsor` (rajada horizontal por um vão). Cenas code-only +
  `scenes/actors/*.tscn`.
- **Câmaras** (`POOL_REGIAO`): escadaria, saltos_altos, ritmadas,
  trampolins, correntes_v, elevadores, quebra_ponte, torre_vento, impulso,
  gravidade + as de perigo (serras/guilhotinas/fogo/pendulos/gruta/prensa/
  pedras/portal) agora com **rota alta** de plataformas por cima.
- Anti-softlock mantido: chão raso contínuo por baixo (as plataformas são o
  desafio, o chão é a rede), última câmara = corredor liso + **ponte no
  seam** (liga a qualquer altura de chão do nível feito à mão).
- Variedade de inimigos na jornada por região (`ESP_REGIAO`, arte LuizMelo
  já existente).
- `LARG` 1100→1250, `comprimento_max` 33k→34k. `verifica_jornada` + testes
  + smoke de 3 níveis OK. v0.6.29+.
- **Assets CC0 por integrar (próximo passo)**: `bdragon1727` bullets nos
  projéteis, `glionox` props na decoração, `szadiart`/`free-game-assets`
  parallax. Estão em `assets/sprites/incoming/` (fora do git).

## Sessão 2026-08-31 — JORNADA (níveis grandes, boss no fim) + pedidos playtest

**v0.6.26.** Feedback do Paulo: "jogo mecanicamente simples; níveis
pequenos; quero 5 min de obstáculos até ao boss; boss SEMPRE no fim".

### Jornada de aproximação (`scripts/gerador_corredor.gd`, reescrito)
- Prepende um **percurso longo e temático** à esquerda do spawn: 17k–34k px
  (cresce com o nível), 15–30 câmaras, checkpoint por câmara. A Koliani
  nasce no início; o nível feito à mão + a arena do chefe passam a ser a
  **reta final**. `nivel_com_chefe.gd`: `corredor = true` por omissão em
  TODOS os níveis (menos o nº 30, o trono).
- **Câmaras** (pool por região em `POOL_REGIAO`): `muros`, `serras`,
  `fossos` (salto), `gruta` (tecto baixo + `PedraQueda`), `pedras`
  (corredor de estalactites em ciclo), `pendulos` (`PenduloLamina`),
  `guilhotinas`, `vento` (`CorrenteAr`), `fogo` (jatos + `Torreta`),
  `prensa` (`ParedeMovel`), `portal` (fosso de espinhos com 2 rotas:
  plataformas/pêndulo OU par de `Portal` de teleporte).
- **Anti-softlock por construção**: chão raso contínuo em toda a extensão
  (cair não mata nem prende), muros ≤ 58 px (+ degrau), nada bloqueia a
  passagem, SEM portas/alavancas no gerador, portais só levam ao parceiro.
  `VisibleOnScreenEnabler2D` por câmara (desligado em headless) para 30
  câmaras não pesarem no telemóvel.
- **Âncora estável**: `EstadoJogo.jornada_ancora_para(idx, calc)` guarda o
  ponto de spawn original em memória (não no save) para a geometria da
  jornada sair IGUAL a cada morte/recarga. `nivel_com_chefe._enter_tree`
  captura `entrada_fresca` (checkpoint == ZERO) antes de a Koliani mexer
  no checkpoint implícito.
- Mecânicas novas reutilizáveis: **`Portal`** (`portal.gd` + `.tscn`,
  grupo "portais", `id`/`destino_id`/`so_saida`), **`PenduloLamina`**,
  **`PedraQueda`**. `Koliani.conceder_iframes()` (o Portal usa).
- `TEMPO_HARDCORE` subido para a nova travessia (300 s → 720 s).
- `tools/verifica_jornada.gd` — confirma a jornada nos 30 níveis headless
  (todos OK: koliani reposicionada ~17–34k px à esquerda do chefe).
- **POR PLAYTESTAR**: números dos perigos (períodos/dano/densidade), se
  algum nível deve ter `corredor = false`, softlock real (o bot
  `bot_gauntlet.gd` acusou uma paragem longa no nível 0 — heurística
  crua, mas rever). O visual dos perigos está afinado para ameaçar quem
  CORRE (serras a `_chao_y-34`, pêndulos à altura do peito).

### Outros pedidos do playtest (mesma sessão)
- **GAME OVER** (ecrã + som) retirado — `game_over.gd::mostrar()` só
  recomeça a campanha em silêncio. Entrada `"game_over"` fora de `som.gd`.
- **Dano da espada e dos tiros a DOBRAR**: `DANO_BASE` 25→50,
  `Koliani.DANO_ATAQUE` 25→50, `Equipamento.ARMAS[].dano` ×2 (curva
  mantida). Kamehameha e projétil seguem `_dano_golpe()`.
- **Comando**: R2 (axis 5) passou de `lancar` para `defender` (Escudo).
- **Coletável de habilidade**: faixa brilhante **"SKILL"** (Label +
  estandarte + glow) em vez da seta ↑. Coletável só-pista já nem aparece.
- **Sistema de PISTAS retirado do jogo**: `Coletavel` ignora `pista_id` e
  só age em `habilidade_id`; Diário fora do HUD (`main.gd` não o
  instancia) e sem tecla (`diario` input vazio); sem balão ao apanhar.
  Infra (`EstadoJogo.pistas`, `DiarioPistas`, i18n `pista.*`, testes
  `teste_diario_*`) fica **dormente** — não foi apagada.
- **Hardcore sem save** (v0.6.27, decisão final do Paulo): `guardar()`/
  `carregar()` são no-op quando `hardcore` — perder = recomeçar tudo, é
  game over (é esse o conceito). O save do modo normal fica sempre
  intacto porque o hardcore nunca lhe toca. Menu: HARDCORE MODE começa
  sempre do zero, sem confirmação. Caveira pixel-art (ícone em código) a
  seguir a "HARDCORE MODE".
- **Bosses "deixam de levar dano"** (v0.6.27): manteve-se a mecânica do
  núcleo exposto, mas (a) `ChefeBase` desenha um **escudo brilhante da cor
  do chefe** (`cor_rim`) enquanto ele está BLINDADO — some ~0.85 s a cada
  golpe que entra; `usa_escudo_boss = false` no Carcereiro e chefe_floresta
  (levam dano sempre); (b) `_preparar_escudo_boss()` alarga
  `dur_exposto`/`dur_exposta` ×1.6 em todos os chefes (menos tempo
  blindado). Heurística: `_dano_recente` (não há hook por-chefe do estado
  exposto; os 3 nomes são `_exposto`/`_exposta`/`_nucleo_exposto`).

## ESTADO: CAMPANHA COMPLETA — 30/30 níveis, 30 chefes (v0.5.0, 2026-08-30)

As **6 regiões** estão construídas de ponta a ponta. `EstadoJogo.NIVEIS`
tem 30 entradas (índices 0–29), todas dentro de uma região; cada nível
tem cena + chefe (herda `ChefeBase`) + `_boss_*` em `gerar_sprites.gd` +
pista i18n×6 + `TEMPO_HARDCORE`. `Castelo_de_Zeriko.tscn` / `zeriko.gd` /
`Zeriko.tscn` ficaram como **legado** (fora da campanha).

## Sessão 2026-08-30 (cont. 2) — packs CC0 novos do Paulo

- **Armas reais.** As 15 lâminas da Koliani vêm agora do pack CC0
  `thewisehedgehog` (`incoming/thewisehedgehog/File (1).png`, grelha 6×5 de
  32×32). `tools/extrair_armas.gd` escolhe 15 células → `gear/armas.png`
  (15×32×32) e amostra a cor dominante de cada → `Equipamento.COR_ARMA`.
  Todo o brilho do golpe (`_cor_golpe`) segue essa cor. `_armas()` de
  `gerar_sprites.gd` fica como fallback (já não é chamado).
- **Plataformas góticas.** `tools/gerar_tiles_goticos.gd` faz
  `tiles/pedra_gotica_block.png` (96×96 9-slice) da calçada seamless CC0 do
  pack `piiixl`, recolor de cripta + luar magenta. `plataforma.gd` usa-o em
  todas as regiões de pedra.
- **Inventário `incoming/` (30 ago, ainda a crescer):** `thewisehedgehog`
  (armas — USADO), `piiixl/seamless patterns` (texturas — USADO),
  `bdragon1727/Effect and Bullet 16x16` (fx Fire/Green/**Purple**/Water
  16×16 — bom p/ projéteis por cor), `codemanu` (20 spritesheets de magia
  800²+ — fireball/nebula/vortex/phantom), `glionox` (~1000 items 16×16),
  `anokolisa` "Legacy Fantasy" (tiles+char+mobs floresta), `zerie` Tiny RPG
  (Soldier/Orc/Demon 100×100), `luizmelo` EvilWizard2 + Monsters v1.2/1.3
  (agora com projéteis), `ninjikin` Water+, `free-game-assets` (4 fundos
  parallax 576×324), `codemanu`. **Licenças de `thewisehedgehog` e `piiixl`
  por confirmar em `incoming/LICENSES.md`.**
- **A SEGUIR (Paulo continua a largar assets):** afinar pose/escala da arma
  na mão em jogo; usar `bdragon1727` Purple/Fire/Green nos projéteis
  (`ProjetilKoliani`, `BolaFogo`, tiros dos chefes) conforme a cor;
  `codemanu` para o Kamehameha / novas magias; ver `anokolisa`/`glionox`
  para props.

## Sessão 2026-08-30 (cont.) — feedback do Paulo: VFX, equipamento, longevidade

- **Golpe de espada com raio de luz.** `koliani.gd` `_flash_golpe()`: a
  cada ataque, `LuzGolpe` (PointLight2D novo) dá um clarão à frente
  (ilumina o cenário) + dois arcos aditivos que varrem com a lâmina (halo
  da cor da arma + núcleo branco-quente). Rastro mais largo e tingido pelo
  tier. `_cor_golpe()` = aço-frio → magenta por `Equipamento.cor_arma`.
- **Armas/armaduras mais ricas.** `gerar_sprites.gd` `_armas()`/
  `_armaduras()` reescritas com `_tier()` (rampa 3 paragens) — lâmina
  sombreada + fio + faísca, silhuetas de armadura por tipo.
- **Armadura visível no boneco.** `Koliani.tscn` `Sprite/Armadura`:
  peitoral + pauldrons + cinto + trim em Polygon2D (herdam a animação
  procedural). `koliani.gd::_aplicar_visual_armadura()` recolore por tier.
- **Gauntlet de aproximação (longevidade ×N).** `gerador_corredor.gd`
  reescrito: sequência de CÂMARAS (muros+degrau, porta+alavanca, serras,
  guilhotinas, fogo+`Torreta`, prensas). ~3280 px (nível 5) → 7200 px
  (nível 29) antes da geometria feita à mão. Anti-softlock: chão contínuo,
  muros baixos com degrau, hazards só magoam (recolhem/ciclam), alavanca
  no chão. `CascaMasmorra.abrir_esquerda()` recua a parede da masmorra →
  `corredor` reativado nas regiões II/IV. Mecânica nova **`Torreta`** +
  **`BolaFogo`** (mob de parede que cospe fogo). `koliani.gd`: wall-grab
  só quando não sobe depressa (`velocity.y > -60`). `tools/bot_gauntlet.gd`
  deteta bloqueios.
- **AINDA POR AFINAR (playtest):** números dos hazards do gauntlet
  (períodos/danos/densidade), se algum nível deve ter `corredor = false`,
  leitura das placas de armadura nos tiers baixos, tamanho do arco do
  golpe.

## Sessão de polish 2026-08-30 (noite) — feito

- **Legado apagado.** `Torres_Esquecidas.tscn`+`ChefeVento`+`chefe_vento.gd`
  e `Castelo_de_Zeriko.tscn`+`Zeriko.tscn`+`zeriko.gd`+`nivel_castelo.gd`
  saíram do repo (já substituídos pelos níveis 12 e 30). `ProjetilZeriko`
  fica (Zeriko final + Coração Putrefacto). `cena_final.gd` fica (narrativa
  a religar ao fim do nível 30).
- **Carrossel de escolha de nível.** `SeletorNiveis.tscn`/`.gd` (cover-flow:
  cartão central + 2 vizinhos, faixa da região, N/30, nome do nível,
  "Chefe: X", CONCLUÍDO/TRANCADO; setas/teclado/roda/arrasto). Substitui a
  lista vertical que passava o ecrã. Usado no **MapaMundo** (respeita
  bloqueios) e na **DevBarra** (livre). Dados: `catalogo_campanha.gd`
  (`CHEFE_KEY` ×30) + 60 chaves i18n (`level.n00..29`, `boss.<slug>`) +
  `sel.*`. Teste `teste_catalogo_campanha`.
- **Balão de fala.** Autoload `Dialogo` + `Balao.tscn`/`.gd` (borda magenta,
  cauda ao orador, typewriter, "toca para continuar", congela a árvore).
  `ChefeBase.falas_intro`/`falas_fim` (opt-in): intro dispara a
  `gatilho_intro` px, fim antes de a porta abrir. Ligados: Primeiro
  Prisioneiro, Noiva do Eclipse, Arauto, ZERIKO. 15 chaves `dlg.*` ×6.
- **Passagem aos números (1.ª).** Curva de vida monótona por região
  (Ghorak 250 → Zeriko 1200; ver `hp` no git). `ChefeBase` deixa de ter o
  multiplicador de dano de contacto travado nos 4 mundos — agora rampa
  suave pelos 30 níveis (`0.03*idx`, ~x1.0 → ~x1.9). `TEMPO_HARDCORE`
  reescrito com 30 entradas a subir por região (+ folga nos fins de
  região; Zeriko 240s). **Ainda "a olho"** — telégrafos, cadências e dano
  por projétil de cada chefe ficam para o playtest do Paulo.

## Sessão de polish 2026-08-30 (noite, cont.) — pedidos do Paulo

- **Monstros/chefes maiores.** `DemonioBase` sprite 0.42→0.86 + colisões;
  `ChefeBase.escala_visual` (@export por cena, 1.2→2.0). Vida EFETIVA dos
  chefes está no `vida = N` de cada `Chefe*.tscn` (não no `maxi()` do
  script) — os 30 `.tscn` foram para a curva Ghorak 250 → ZERIKO 1200.
- **Barra de vida do chefe** ao fundo do ecrã (`controlos_toque.gd`):
  `ChefeBase` emite `combate_iniciado` / `vida_mudou`.
- **Armas & armaduras.** `scripts/equipamento.gd` (15+15, dados puros).
  Acabar nível ímpar → arma seguinte; par → armadura seguinte. `EstadoJogo`
  guarda posse/equipado + `conceder_recompensa`/`equipar_*`/`ciclar_arma`
  + helpers `dano_ataque`/`vida_bonus_armadura`/`reducao_armadura` (tudo no
  save). `koliani.gd` usa-os (golpe/projétil/vida máx/redução).
  - Menu: 2 botões na Pausa → `SeletorEquip.tscn` (grelha 15, bloqueado =
    cinza + "Nv N", toque equipa).
  - HUD novo: vida (vermelho) + energia (azul) no canto inferior-esquerdo
    + disco redondo da arma (iniciais como ícone placeholder; toque/tecla
    E ciclam). Barra do chefe subiu p/ não chocar.
  - Sprite: `Koliani/Sprite/Arma` (Sprite2D `hframes=15`, tira
    `assets/sprites/pixel/gear/armas.png` gerada em `gerar_sprites.gd::
    _armas()`); `frame` = índice da arma. Armadura = tinta 35% no `Corpo`
    (`Equipamento.cor_armadura`). **Placeholder** — trocar por pack CC0
    depois (só o `texture=`/`region` das cenas).
  - Ação de input nova `trocar_arma` (tecla E) em project.godot.
- **NB project.godot** tinha sido truncado a 0 bytes num commit anterior
  (bug de `open(w).write(read())` em Python — trunca antes de ler);
  restaurado de 129a999.

## Sessão autónoma 2026-08-30 (tarde/noite) — feedback do playtest do Paulo

Ronda longa de pedidos enquanto o Paulo jogava. Feito e com push
(v0.5.13 → v0.5.20):

- **Coletáveis/checkpoints** com visual próprio (código): habilidade →
  seta ↑ brilhante; pista → lâmpada; checkpoint → gema verde-platina
  fosca que acende ao tocar. Apanhar uma pista corre o balão de fala
  (`Dialogo`) com o texto.
- **Menu equipamento**: imagem do item como fundo do cartão
  (`gear/armas.png` + `gear/armaduras.png`, `AtlasTexture`); botões
  WEAPONS/ARMOR passaram do menu de Pausa para o **HUD** (por cima da
  vida). Modo DEV desbloqueia todas as armas/armaduras.
- **HUD** refeito: vida (vermelho) + energia (azul) no canto
  inferior-esquerdo + disco redondo da arma (tecla E / toque cicla).
- **Seletor de níveis**: fundo com arte do bioma + linha "Reward: <item>".
- **Goblins não flutuam** (offset do sprite corrigido). **Teia** deixa de
  prender — só abranda.
- **Habilidade nova `escalar_paredes`** (agarrar + subir/descer + salto de
  parede): `koliani.gd`, em `HABILIDADES_TODAS`, coletável no nível 04.
- **Mecânica `Alavanca` → `PortaTrancada`** (`id` liga os dois; grupo
  "alavancas"). Paredes verticais = `Plataforma` alta (já servia).
- **`GeradorCorredor`** (`gerador_corredor.gd` + `nivel_com_chefe.gd`):
  prepende um **corredor de aproximação** a TODOS os níveis (menos o
  último). Chão contínuo + paredes ≤100px + espinhos + inimigos (espécie
  copiada do nível) + porta-alavanca a partir do nível 3. Comprimento
  `620 + 140·idx` (máx 4200) e densidade de perigos crescem com o número
  do nível → "níveis mais longos que crescem com o número". Aditivo, não
  toca na geometria feita à mão. `corredor = false` na cena desliga.

### PROSSEGUIDO (o Paulo disse "concordo com tudo, procede como achares")

- **`SalaLabirinto`** (`sala_labirinto.gd` + `SalaLabirinto.tscn`): câmara
  fechada paramétrica -- casca (chão/tecto/paredes) + caminho em Z com 2
  paredes internas (salta por cima / passa por baixo, SEMPRE há rota sem
  escalar) + **2 alavancas encadeadas** em alcovas separadas (uma em cima,
  uma atrás de espinhos) + `PortaTrancada` na saída que só abre com AS
  DUAS + serras. `largura`/`altura`/`dificuldade`/`id`/`especie_inimigo`.
- **`GeradorCorredor`** passa a **encaixar uma `SalaLabirinto` no corredor
  a partir do nível 3** (`id = labirinto_<idx>`, tamanho/dificuldade
  crescem com o nível). Níveis 1-2 ficam com a porta-alavanca simples.
  Os segmentos por baixo da sala não recebem perigos avulsos.

Resultado: cada nível 3-29 tem agora, no acesso ao chefe, um mini-labirinto
real com alavancas encadeadas. Smoke dos 30 OK.

### AINDA POR AFINAR (playtest do Paulo)
- Fluxo das `SalaLabirinto` embebidas (só testei a sala isolada + smoke).
- `VEL_ESCALAR` / `WALLJUMP` do escalar paredes; onde exigir a habilidade.
- Comprimento/dificuldade do corredor (`gerador_corredor.gd`).
- Se algum nível não deve ter corredor/sala (`corredor = false` na cena).

## O QUE FALTA (antigo):
1. **Playtest fino.** Telégrafos/cadências/dano-por-ataque dos 30 chefes
   continuam por afinar em jogo. A curva de vida e o hardcore são um 1.º
   palpite coerente, não o número final.
2. **Mecânicas aproximadas** (assinaladas nos comentários das cenas):
   nível 19 "paredes móveis" (agora `ParedeMovel`, rever); nível 23 "trem
   que anda de facto" (é a Koliani a correr + parallax); Vyrak (15) F3
   "arena em cima do dragão"; nível 15 é nível-luta sem traversia própria.
3. **`cena_final.gd`** (6 linhas, `final.line1..6`) por religar ao fim do
   nível 30 no lugar do provisório `fim_campanha.gd`.
4. **Screenshots headless FUNCIONAM** nesta máquina (RTX 5070) — ver o
   padrão no git desta sessão (SceneTree que instancia a cena + `--script`).

## COMO RETOMAR (para continuar o polish)

Pedir ao agente `gaming`: playtestar região a região e **afinar os
números** dos chefes, OU pegar num dos pontos de dívida acima. O padrão de
um nível/chefe está em "Padrão de um nível novo" mais abaixo. Chefes:
pixel-art gerado em `tools/gerar_sprites.gd` (`_boss_*`), tiras de 4
frames (0/1 idle, 2 telegrafo, 3 exposto; multi-forma usa 0/1 = forma,
2 telegrafo, 3 exposto).
- Fundos: `Atmosfera.fundo_pack` → `assets/sprites/pixel/backgrounds/<pack>/`
  (packs Ansimuz CC0). Mapa em `atmosfera.gd::PACKS`.
- Inimigos comuns: `DemonioBase.especie` = goblin | mushroom | esqueleto |
  olho (LuizMelo CC0). Já atribuídos por região nas cenas.
- **Assets CC0 disponíveis** em `assets/sprites/incoming/` (fora do git):
  gothicvania (tilesets+inimigos), luizmelo, clembod (Bringer of Death),
  chierit (bosses Minotaur/Golem/Slime), 0x72 DungeonTileset II. Catálogo:
  `docs/assets_cc0.md`. **Regra nova do Paulo:** ao mexer em modelos/fundos,
  se não der para fazer bem por código, LEMBRAR de ir buscar assets CC0 —
  poupa tempo e melhora muito (foi assim que ganhámos os fundos reais).
- Antes de cada commit: `tests/run_tests.gd` OK + export Web OK + smoke da
  cena. `push` para master. Bumpar `config/version` em `project.godot`.
- **Padrão de um nível novo:** cena `scenes/levels/*.tscn` + chefe
  (`chefe_*.gd` herda `ChefeBase`, ponto fraco = `Nucleo` só na janela
  EXPOSTA, dano x2) + `ChefeX.tscn` (Sprite2D `hframes=4` → pixel-art) +
  `_boss_x` em `gerar_sprites.gd` + entrada em `EstadoJogo.NIVEIS`/`REGIOES`
  + `TEMPO_HARDCORE` + pista em `diario_pistas.gd` + i18n ×6 +
  `fundo_pack`/`especie` na cena. Mecânica partilhada nova = cena+script
  reutilizável (ver `RaizPerigo`, `GotaAcida`, `PlataformaCorrente`…).

---

Registo vivo do avanço pela bíblia `docs/niveis.md`. Serve para retomar
depois de um `/clear` sem perder o fio: o estado real está sempre no
`git log` + no código; isto é só o índice do que já foi feito e o que
vem a seguir.

## Como está a campanha (`EstadoJogo.NIVEIS` / `REGIOES`)

| idx | cena | região | chefe | estado |
|-----|------|--------|-------|--------|
| 0 | `Floresta_Putrefata.tscn` | I Floresta | Ghorak | jogável (antigo "M1") |
| 1 | `Pantano_dos_Sussurros.tscn` | I Floresta | Morvanna | **novo 2026-08-30** |
| 2 | `Ninho_da_Viuva_Negra.tscn` | I Floresta | Rainha Aracnídea | **novo 2026-08-30** |
| 3 | `A_Arvore_que_Chora.tscn` | I Floresta | Entrevane | **novo 2026-08-30** |
| 4 | `Prisao_dos_Condenados.tscn` | II Prisão | Carcereiro | jogável (antigo "M2") |
| 5 | `Torres_Esquecidas.tscn` | III Torres | Uivo/Vento | jogável (antigo "M3") |
| 6 | `Castelo_de_Zeriko.tscn` | VI Castelo | Zeriko | jogável (final) |

> **Nota de save:** inserir níveis no meio de `NIVEIS` desloca os índices.
> Saves de playtest antigos ficam a apontar para o nível errado — fazer
> **NEW GAME** depois de puxar. É esperado nesta fase (campanha ainda a
> ser construída).

## Mecânicas partilhadas já reutilizáveis

- `RaizPerigo` — espinho de raiz que telegrafa/irrompe/recolhe (região I).
- `AguaVenenosa` — poça de morte instantânea (`scripts/agua_venenosa.gd`,
  cena `scenes/actors/AguaVenenosa.tscn`). `largura`/`altura` em px, rebordo
  aceso + luz na linha de água.
- `PlataformaFlutuante` — plataforma que baloiça (seno) e opcionalmente
  deriva; `AnimatableBody2D` com `sync_to_physics`, carrega a Koliani.
  Grupo "plataformas_flutuantes"; `desvanecer()`/`reaparecer()`.
- `TeiaPrende` — mancha de teia que PRENDE a Koliani (`Koliani.prender`, novo
  em `koliani.gd`: `_preso` bloqueia andar/saltar). `permanente=true` =
  teia fixa do cenário; a Rainha Aracnídea chama `lancar()`.
  `scripts/teia_prende.gd` + cena.
- `GotaAcida` — lágrima de seiva ácida (`scripts/gota_acida.gd` + cena).
  Pende de um galho, incha (telegrafo), cai e deixa uma POÇA que magoa por
  `dur_poca`. `automatico=true` goteja em ciclo (perigo de cenário); a
  Entrevane pousa-a sobre a Koliani e chama `cair()`. O escudo bloqueia
  (a gota vem de cima -> empurrão 0).
- `Plataforma`, `Espinhos`, `Serra`, `Fogo`, `ParedeFragil` — já existiam.
  Nota: `Plataforma` ignora `cor_base/cor_topo` para o NinePatch de terreno,
  por isso as "plataformas de teia" ainda parecem relva — trocar por tiles
  de seda no passe pixel-art.
- `tools/shot_plataforma.gd` ganhou 5.º arg opcional `koliani_y`.

## Feito nesta linha de trabalho

- **Nível 02 — Pântano dos Sussurros** (região I): plataformas flutuantes
  sobre água venenosa, névoa, `Serra` e `Espinhos`. Chefe **Morvanna, a
  Bruxa do Pântano** (`chefe_morvanna.gd`): flutua sobre a água, invoca
  mãos espectrais que irrompem sob a Koliani, cria clones de lama e apaga
  temporariamente as plataformas flutuantes. Fase 2 < 50% vida: telégrafos
  mais curtos, mais mãos, apaga mais tempo. Ponto fraco = quando desce
  para "provocar" (estado EXPOSTA) leva dano a dobrar.
- Pista nova `pantano_bilhete_na_agua` (diário + i18n × 6).
- **Nível 03 — Ninho da Viúva Negra** (região I): plataformas de seda,
  manchas de teia `TeiaPrende` que prendem a Koliani, `Serra` + `Espinhos`.
  Chefe **A Rainha Aracnídea** (`chefe_rainha_aracnidea.gd`): cospe teia
  onde a Koliani está, põe ovos que eclodem em aranhas pequenas, arremete.
  Ponto fraco = o rosto humano, só EXPOSTO depois de cada ataque (dano a
  dobrar). Fase 2 < 50%: telégrafos curtos, mais ovos, parte as plataformas
  do grupo "plataformas_ninho".
- Pista nova `ninho_teia_com_cabelo` (diário + i18n × 6).
- `koliani.gd`: novo `_preso` / `prender(segundos)` — preso numa teia não
  anda nem salta. Escudo erguido protege.
- **Nível 04 — A Árvore que Chora** (região I): sobe-se o tronco por galhos
  (alguns no grupo "plataformas_arvore"), com `GotaAcida` a gotejar do
  cimo e a deixar poças ácidas; serra + espinhos. Chefe **Entrevane, a
  Árvore Amaldiçoada** (`chefe_entrevane.gd`): enraizada, varre galhos na
  horizontal, chora cortinas de seiva ácida e faz raízes irromper
  (`RaizPerigo`). Ponto fraco = o rosto que chora, só EXPOSTO depois de
  cada ataque (dano a dobrar). Fase 2 < 50%: telégrafos curtos, goteja
  sem parar, mais raízes/galhos, parte um par de galhos da arena.
- Pista nova `arvore_lagrima_no_tronco` (diário + i18n × 6).

## A seguir (por `docs/niveis.md`, região I)

1. ~~Nível 03 — Ninho da Viúva Negra + Rainha Aracnídea~~ **feito**. Ainda
   não jogado a sério — afinar dano/ritmo/tamanho do chefe no playtest.
2. ~~Nível 04 — A Árvore que Chora + chefe **Entrevane**~~ **feito**. Falta
   afinar no playtest; a ideia de "subir pelo corpo do chefe" ficou como
   combate ao pé dele (janela EXPOSTA) — refinar depois.
3. Nível 05 — Coração da Floresta + chefe **Coração Putrefacto** (arena
   rítmica: muda a cada "batimento"; 3 fases). Fecha a região I.
4. Mecânicas ainda por fazer: plataforma móvel de correntes (região II),
   vento (III), gravidade variável (III), luz↔escuridão (IV), cenário
   rítmico ("batimento", nível 05).
5. Depois: regiões II→VI, 1 chefe por nível, sempre a herdar de `ChefeBase`.

## Região II -- Prisão dos Condenados (2026-08-30, em curso)

- Mecânica partilhada **`PlataformaCorrente`** (`scripts/plataforma_corrente.gd`
  + cena): `AnimatableBody2D` + `sync_to_physics`, pendurada por uma corrente
  (Line2D da âncora à plataforma). `modo` = "pendulo" / "vertical" /
  "horizontal", `amplitude`/`periodo`/`fase`/`comprimento`/`largura`. Grupo
  "plataformas_correntes"; `travar(seg)` / `soltar()` (o Carcereiro há-de
  usar).
- **Nível 07 — Fornalha dos Pecadores** (`Fornalha_dos_Pecadores.tscn`):
  poças de lava (`AguaVenenosa` recolorida a laranja, morte instantânea)
  cruzadas por `PlataformaCorrente`, fogo + serra. Arena com o chefe
  **Ignivar, o Ferreiro Maldito** (`chefe_ignivar.gd`): MARTELO (baque ->
  onda rasteira), FORJA (lâmina em brasa na horizontal), BRASAS (reutiliza
  `GotaAcida` a laranja: chove brasas). Ponto fraco = a forja das costas,
  só EXPOSTO a seguir a cada ataque (dano x2, frame 3). Fase 2 < 50%:
  "derrete a arena" -> as poças do grupo "lava_fornalha" crescem, telégrafos
  curtos, mais brasas.
- Pista nova `fornalha_marca_do_ferreiro` (diário + i18n × 6).
- `EstadoJogo.NIVEIS` = 9; prisão `[5, 6]`. Chefe Ignivar em pixel-art
  (`_boss_ignivar` em `gerar_sprites.gd`).
- **A seguir (região II):** níveis 08 Corredor das Execuções / Dama da
  Guilhotina, 09 Ala dos Mortos / Irmãos Condenados, 10 A Cela Zero /
  Primeiro Prisioneiro. Falta pôr `PlataformaCorrente` no nível 06 (Prisão)
  para o "correntes como plataformas móveis" do design.

## Arte -- chefes em pixel-art (2026-08-30)

Os 5 chefes da região I passaram de SVG (`Sprite/Corpo` + `personagem.gdshader`)
para **pixel-art animado**. `tools/gerar_sprites.gd` ganhou `_boss(nome, fw,
fh, desenhar)` + `_boss_coracao/_entrevane/_ghorak_anim/_morvanna/_rainha`:
cada chefe é uma **tira horizontal de 4 frames** em
`assets/sprites/pixel/bosses/<nome>.png` (0/1 idle, 2 telegrafo/ataque,
3 exposto), temática vinda do nome do nível. As cenas `Chefe*.tscn` usam
`Sprite2D` com `hframes = 4` (sem shader -- contorno/sombra "baked"); os
scripts trocam `_corpo.frame` no `_piscar()` (telegrafo -> 2) e no
`_mostrar_nucleo()` (exposto -> 3); o Coração usa também 1 (sístole) e
mapeia 0/3 à fase. SVGs dos chefes apagados. Regenerar:
`godot --headless --script res://tools/gerar_sprites.gd` (PREVIEW=1 p/
`bosses/_preview_*`, gitignored) + `--import`.

## Regras que não mudam

Commits pequenos; `tests/run_tests.gd` a sair `OK` e export Web a
funcionar antes de cada commit; `push` para `master`. Texto do jogo só via
`Textos.t()` + os 6 JSON. Assets só CC0. Nunca mexer em `git config`.

---

## Sessao autonoma 2026-08-30 (madrugada) -- niveis 08..15

Continuada a campanha pelo `docs/niveis.md` a partir do nivel 08. Padrao
mantido (cena + chefe herda ChefeBase, ponto fraco = Nucleo so na janela
EXPOSTA dano x2, `_boss_*` em gerar_sprites.gd tira 4 frames, pista i18n x6,
entrada em NIVEIS/REGIOES/TEMPO_HARDCORE, bump `config/version`, tests +
smoke + push). **Regioes I, II e III COMPLETAS -- 15/30 niveis.**

`EstadoJogo.NIVEIS` = 16. Indices: floresta [0-4], prisao [5-9],
torres [10-14], catacumbas [] , cidade [] , castelo [15].
> Inserir niveis no meio desloca indices -- **NEW GAME** depois de puxar.

### Regiao II -- Prisao dos Condenados (fechada)
- **08 Corredor das Execucoes / Dama da Guilhotina** (`e1704a2` etc.):
  mecanica `Guilhotina` (guilhotina.gd, ja esbocada -- so' se tirou um
  onready orfao). Chefe teleporta (esvai o Sprite), laminas giratorias,
  faz cair as `guilhotinas_arena`, corte rasteiro. Fase 2 sobe as
  `plataformas_execucoes`. Pista `execucoes_lista_de_nomes`.
- **09 Ala dos Mortos / Os Irmaos Condenados**: mecanica
  `PlataformaEspectral` (so' solida uns segundos apos `Koliani.magia_lancada`
  -- sinal novo). Chefe = 2 fantasmas ligados por corrente (Line2D); o
  IRMAO LONGE e' um Node2D criado em runtime. Aos 50% o longe morre e o
  perto absorve a alma (fase 2, dardos em leque). Pista `mortos_irmao_mais_novo`.
- **10 A Cela Zero / O Primeiro Prisioneiro**: 1.o nivel VERTICAL (a
  camara ja segue nos 2 eixos). Chefe duelista que luta como a Koliani
  (combo/dash/GUARDA que apara de frente) e a IMITA (devolve dardo apos
  `magia_lancada`); fase 2 = energia purpura, teleporta, leque, "reforma".
  Pistas `cela_zero_o_primeiro` + `cela_zero_porta_aberta`.
  **DIALOGOS da luta ainda sem sistema de texto -- ficam pela pista.**

### Regiao III -- Torres Esquecidas (fechada)
- **11 Torre dos Sinos / O Sino Vivo**: mecanica `SinoTorre` (bater =
  golpe/projetil): alterna plataformas do grupo `alterna_grupo` (default
  "sino_alterna") e gela inimigos comuns (`DemonioBase.congelar` novo).
  `so_congela` = sino que so' gela. Chefe = sino de bronze pendular:
  badalada (anel rasteiro), grito (crescentes; fase 2 = 360), QUEDA
  (despenca-se, fica preso EXPOSTO). Pista `sinos_badalada_familiar`.
- **12 Torre dos Ventos** -- **NAO construida**: o slot e' servido pela
  `Torres_Esquecidas.tscn` antiga (chefe_vento). Reconstruir como Aerion
  quando houver tempo.
- **13 Torre da Tempestade / Voltaris**: mecanicas `RaioTempestade`
  (descarga vertical, `automatico` = padrao previsivel) + `ParaRaios`
  (bater arma-o; a descarga seguinte por perto desvia-se e volta contra
  o chefe via `receber_dano_ignorando_guarda`). Chefe teleporta, invoca
  raios + clones eletricos; o para-raios atordoa-o. Pista
  `tempestade_cajado_de_osso`.
- **14 Observatorio Lunar / A Sacerdotisa Lunar**: gravidade variavel --
  `Koliani.definir_grav_escala` + `_grav_escala`; `Movimento.passo` ganhou
  8.o arg `grav_escala` (default 1.0). Mecanica `ZonaGravidade` (bolsa de
  gravidade lunar). Chefe: luas falsas (crescentes que curvam), MARE
  LUNAR (alivia a gravidade da Koliani + chuva de METEOROS). Repoe a
  gravidade ao morrer/sair. Pista `lunar_carta_da_sacerdotisa`.
- **15 O Pico Esquecido / Vyrak, o Dragao das Sombras**: nivel-luta (sem
  mecanica de traversia). Chefe 3 fases: F1 no pico (garra/sopro) -> F2
  parte o cume (grupo "plataformas_pico" cai) e VOA (passagens + bolas +
  cauda) -> F3 despenca-se, nucleo EXPOSTO ate ao fim, garra/cauda/NOVA.
  A "arena em cima do dragao" literal fica p/ polir. Pistas
  `pico_escama_de_vyrak` + `pico_torres_para_tras`.

### A SEGUIR -- Regiao IV: Catacumbas do Abismo (niveis 16..20)
Por `docs/niveis.md`: 16 Cemiterio dos Reis / Rei Ossario (tumulos =
elevadores) - 17 Galeria dos Ossos / Colosso Osseo (paredes destrutiveis)
- 18 Cripta das Mil Velas / Freira Negra (plataformas so' quando
iluminadas) - 19 ??? - 20 ??? (ver a biblia). bioma "catacumbas"
(Plataforma ja recolore pedra a bone-green); fundo: falta pack proprio
(usar "rochoso" ou "corredores" por agora). Inimigos: esqueleto.

### Divida tecnica / a rever
- **Nivel 06 (Prisao)**: falta pOr `PlataformaCorrente` para o
  "correntes como plataformas moveis" do design.
- **Nivel 12 (Torre dos Ventos / Aerion)**: por construir.
- **Sistema de dialogo**: varios chefes (sobretudo O Primeiro Prisioneiro
  e, no fim, Zeriko) pedem falas em cena. Nao ha runtime de texto/caixa
  de dialogo -- so' pistas do diario. Decisao do Paulo.
- **Vyrak F3**: "luta em cima do dragao" e' aproximada (nucleo exposto +
  thrash), nao uma arena movel real.
- Numeros (vida/dano/tempos) de todos os chefes 08..15 por afinar com
  playtest -- foram postos "a olho".

---

## Sessao autonoma 2026-08-30 (continuacao) -- niveis 16..25

**Regioes I, II, III, IV e V COMPLETAS -- 25/30 niveis.** `EstadoJogo.NIVEIS`
= 26. Indices: floresta [0-4], prisao [5-9], torres [10-14],
catacumbas [15-19], cidade [20-24], castelo [25] (so' Castelo_de_Zeriko,
placeholder do M4 antigo).

### Regiao IV -- Catacumbas do Abismo (fechada)
- 16 Cemiterio dos Reis / Rei Ossario -- mecanica `TumuloElevador`
  (AnimatableBody sobe c/ peso em cima; `auto`=vaivem). Chefe montado
  que carga; fase 2 desmonta e combate a pe.
- 17 Galeria dos Ossos / Colosso Osseo -- `ParedeFragil` p/ secrets. Chefe
  quase imovel, 4 armas; `_remodelar()` a cada 75/50/25% (armas novas +
  encolhe, aos 50% 2 caes).
- 18 Cripta das Mil Velas / Freira Negra -- mecanicas `Vela` (acesa/apagada;
  reacende ao tocar) + `PlataformaLuz` (so' solida com Vela acesa perto).
  Chefe desce a apagar velas (unica janela EXPOSTA). Fase 2: sopro apaga
  todas.
- 19 Templo da Serpente / Naga Zeraph -- "paredes moveis" NAO feitas (nota
  na cena); ParedeFragil + estatuas (grupo "estatuas_naga" p/ a TROCA).
  Chefe: cuspe/cobras/poca de veneno/troca com estatua.
- 20 O Abismo / Olho do Abismo -- `LuzSeguidora` (luz fraca cola a Koliani)
  + `Koliani.inverter_controlos`. Chefe: laser em varredura, `plat_falsas`
  que apaga, clones, inversao.

### Regiao V -- Cidade Corrompida (fechada)
- 21 Vila dos Sem-Rosto / Prefeito Sem-Rosto -- `DemonioBase.dormente` +
  `raio_acorda` (inimigos de emboscada). Chefe: DECOYS (copias identicas),
  bengala, decretos.
- 22 Mercado da Carne / Acougueiro Real -- PlataformaCorrente + caixas +
  carrinho (PlataformaFlutuante). Chefe: 2 cutelos; CADA golpe que leva
  sobe/baixa uma "acougue_moveis" (arena muda).
- 23 Trem dos Mortos / Maquinista Infernal -- vagoes (grupo "vagoes_trem")
  com vaos + tunel (Espinhos rodados). NOTA: o trem nao anda de facto.
  Chefe: pa/brasas, vapor, apito; fase 2 "o trem ataca" (brasas +
  vagoes sacodem).
- 24 Catedral da Corrupcao / Bispo Purpura -- mecanica `Vitral` (parede
  colorida na layer 5; golpe/projetil parte-a -> plataformas do
  `grupo_luz` ficam solidas). Chefe: cruzes explosivas, maos, anjos.
- 25 Praca do Eclipse / Noiva do Eclipse -- `eclipse_tint.gd` + 2
  conjuntos de PlataformaRitmada (realidade/corrupcao). Chefe emocional:
  aneis, eclipse+nova, convidados; fase 2 o veu queima e ela deixa de
  magoar ao toque. Pistas fecham o arco da mae.

### A SEGUIR -- Regiao VI: Castelo de Zeriko (niveis 26..30)
Por `docs/niveis.md`: 26 Portoes / Capitao Negro (rapido, "joga como
player") - 27 Salao dos Espelhos / Koliani Sombria (espelho da Koliani) -
28 Banquete dos Imortais / Rei Devorador (come inimigos p/ curar) -
29 Torre do Coracao Negro / Arauto de Zeriko (3 formas) - 30 O TRONO /
ZERIKO (4 fases, boss final). O `Castelo_de_Zeriko.tscn` atual e' o
placeholder do M4 -- fica como nivel 30 ou reconstroi-se. bioma "castelo"
(magenta). **Deixado para revisao do Paulo + sessao dedicada** (o
finale merece cuidado; ha 5 chefes, um deles 4 fases).

### Divida tecnica acumulada (alem da de cima)
- Niveis-luta sem mecanica de traversia propria (15 Vyrak) e mecanicas
  aproximadas: 19 "paredes moveis", 23 "trem que anda", Vyrak F3 "arena
  em cima do dragao".
- **Sem sistema de dialogo** -- as falas dos chefes (Primeiro Prisioneiro,
  Noiva, e sobretudo Zeriko) estao todas nas pistas do diario. Isto vai
  fazer falta a serio na regiao VI.
- Numeros (vida/dano/tempos) de TODOS os chefes 08..25 postos "a olho" --
  precisam de playtest.
- `tools/shot_plataforma.gd` nao produziu PNG nesta sessao (parece
  precisar de GPU/display) -- verificacao foi so' por smoke headless.

---

## Regiao VI -- Castelo de Zeriko (fechada) -- niveis 26..30

- **26 Portoes de Zeriko / O Capitao Negro** -- twist: luta como
  personagem, telegrafos curtos, muito mais rapido. COMBO/BASH/GUARDA
  (bloqueia e devolve)/MERGULHO. Fase 2: escudo estilhaca, +RODOPIO 360.
- **27 Salao dos Espelhos / Koliani Sombria** -- mecanica `Espelho`
  (parte-se, solta um "reflexo" que persegue). Chefe usa o kit da
  Koliani (combo/dash/rola/projetil-leque/salto); espelha `magia_lancada`.
  Fase 2: dash vira pestanejo, projetil persegue, combo +onda.
- **28 Banquete dos Imortais / O Rei Devorador** -- arena = mesa gigante
  (grupo "mesa_banquete"). GARFADA/PRATOS/SERVOS + DEVORAR: come um
  inimigo comum perto e RECUPERA vida (matar os servos longe dele).
- **29 Torre do Coracao Negro / O Arauto de Zeriko** -- PlataformaRitmada
  (pulsos de energia). Chefe 3 FORMAS: Cavaleiro -> Demonio (garras +
  sopro purpura + salto) -> Entidade (flutua, teleporta, dardos, nova).
- **30 O TRONO DE ZERIKO / ZERIKO** -- `O_Trono_de_Zeriko.tscn` (sala do
  trono que mistura elementos: PlataformaCorrente, PlataformaRitmada,
  trono, magia purpura). Chefe final `chefe_zeriko_final.gd`, **4 FORMAS**:
  F1 O MAGO (teleporta, salvas de ProjetilZeriko em leque, meteoros) ->
  F2 O REI (5 garras RaizPerigo em roda + cavaleiros) -> F3 A COISA DO
  ABISMO (tentaculos RaizPerigo + olho que varre um feixe) -> F4 O QUE
  RESTA (pequeno/rapido, golpes de magia curtos, NOVA a partir dele --
  seguro e' colar-se-lhe). Porta com a pista `castelo_aurora_livre` (o
  fim). Legado: `Castelo_de_Zeriko.tscn` fica fora de `NIVEIS`.

## Mecanicas partilhadas criadas nesta campanha (resumo, para reutilizar)

`Guilhotina` (n8) - `PlataformaEspectral` + sinal `Koliani.magia_lancada`
(n9) - `SinoTorre` + `DemonioBase.congelar` (n11) - `RaioTempestade` +
`ParaRaios` + `receber_dano_ignorando_guarda` (n13) - `ZonaGravidade` +
`Koliani.definir_grav_escala` + 8.o arg de `Movimento.passo` (n14) -
`TumuloElevador` (n16) - `Vela` + `PlataformaLuz` (n18) - `LuzSeguidora` +
`Koliani.inverter_controlos` (n20) - `DemonioBase.dormente`/`raio_acorda`
(n21) - `Vitral` (n24) - `eclipse_tint.gd` (n25) - `Espelho` (n27).
Grupos usados por chefes: "estatuas_naga", "plat_falsas", "acougue_moveis",
"vagoes_trem", "mesa_banquete", "plataformas_pico", "plataformas_execucoes",
"lava_fornalha", "sino_alterna"/"vitral_luz"/"vitral_luz_b".

---

## Sessao 2026-08-30 (noite) -- kit de combate + arranque das masmorras

### Feito e com push
- **Menu de pausa**: atalho **Options** (sobrepoe o ecra de Opcoes sem
  mexer em `paused`/cena -> nao perde o nivel). `788ed86`.
- **Tiro ranged**: ILIMITADO (sem custo de Energia), da 1/3 do dano do
  golpe. Visual roxo esbranquicado + aura roxa luminosa
  (`ProjetilKoliani.tscn`). `_lancar_projetil()` em `koliani.gd`.
- **Kamehameha roxo** (nova skill, gate na habilidade "projetil"):
  segurar `lancar` ~0.4s e largar -> rajada perfurante
  (`KamehamehaKoliani.tscn`/`kamehameha_koliani.gd`). Custa 33% da
  Energia (3 seguidas), `REGEN_ENERGIA` 22->12/s + `RECARGA_KAMEHAMEHA`
  -> nao spamavel. Luz de carga na mao (`$Sprite/LuzCarga`).
  `magia_lancada` passou a disparar SO no Kamehameha (plataformas
  espectrais do n09). Barra de Energia do HUD -> roxa.
  `hud.ability.projetil` -> "Kamehameha Roxo" x6. `dcb22b6`.
- **Escudo** (`Koliani.tscn` no `Sprite/Escudo`): losango cru ->
  escudo *heater* (placa metal escuro + `Borda` Line2D + `Boss`/umbo +
  cruz `EmblemaV/H` + `Glow`). So o `Glow` pulsa (era a placa toda).
- **Masmorra -- BASE**: `0x72 DungeonTileset II` (CC0) copiado p/
  `assets/sprites/pixel/tiles/dungeon_0x72.png` (+ `_tile_list.txt`).
  `tools/gerar_tileset_masmorra.gd` -> `assets/tiles/masmorra.tres`
  (21 tiles: chao/paredes/tecto com colisao quadrada na camada fisica
  0 = "mundo"/bit 1; estandartes/buracos/escadas sem colisao).
  `CREDITS.md` atualizado. `53830de`.

### A FAZER (decisoes do Paulo nesta sessao -- opcoes ambiciosas)
1. **Regioes II (Prisao, idx 5-9) e IV (Catacumbas, idx 15-19) -> caverna/
   masmorra FECHADA com layouts a serio (tecto, corredores apertados,
   pocos verticais) via TileMap.** Padrao a criar no nivel-piloto:
   - `TileMapLayer` novo com `tile_set = assets/tiles/masmorra.tres`,
     `Y_SORT`/`z_index` abaixo dos atores; escala do node p/ casar 16px
     com a metrica do jogo (a Koliani mede ~44px de alto -> tile a
     `scale 2` = 32px, 1.4 tiles; ver `RectangleShape2D_body` = 20x44).
   - Manter os `Node2D` de gameplay (Koliani spawn, `Porta`, `Checkpoint`,
     `ChefeX`, coletaveis, armadilhas, `nivel_com_chefe.gd`) -- so a
     GEOMETRIA (chao/paredes/ColorRect de fundo) passa a tiles.
   - `Atmosfera` recolorida p/ pedra/cripta + `fundo_pack` = "corredores"
     (Prisao) / falta pack proprio p/ catacumbas (usar "corredores" ou
     "rochoso"). Ver `atmosfera.gd::PACKS`.
   - **Cuidado**: nao mexer nos X/Y de `Checkpoint`, `gatilho_intro` do
     chefe, nem da `Porta` -- reconstruir a geometria A VOLTA deles.
     Correr `--script tests/run_tests.gd` + smoke de cada cena + o bot
     `tools/_bot.tscn` (gitignored) por nivel depois de converter.
   - `corredor`/`SalaLabirinto` do `GeradorCorredor` continua a prepender
     -- decidir se os niveis-masmorra levam `corredor = false` (a sala
     labirinto ja da a "masmorra"; ver EM PAUSA no fim).
   - **FEITO (arranque):** `scripts/casca_masmorra.gd` +
     `scenes/actors/CascaMasmorra.tscn` -- componente reutilizavel que
     fecha um nivel (tecto + paredes + chao de seguranca em tiles do
     `masmorra.tres`, `TileMapLayer` x2 z=-2, colisao por `StaticBody2D`).
     `@export largura/altura/topo/esquerda/borda_tiles/chao/chao_y`.
   - **FEITO (rollout, sessao 2026-08-30 cont.):** a Casca esta agora nos
     **10 niveis das regioes II e IV** -- piloto Prisao (idx 5) +
     Fornalha/Corredor das Execucoes/Ala dos Mortos/Cela Zero (6-9) +
     Cemiterio/Galeria dos Ossos/Cripta das Mil Velas/Templo da Serpente/
     O Abismo (15-19). Um commit por nivel. Cada um leva tambem
     **`corredor = false`** no no' raiz: um nivel selado nao leva o
     corredor de aproximacao do `GeradorCorredor` (a parede esquerda da
     Casca colidia com o corredor -> softlock; a `SalaLabirinto` embebida
     ja estava EM PAUSA por softlock). Cela Zero usa Casca vertical
     (topo = -90). Fornalha tem chao a y1400, por baixo do lago de lava.
     `tools/verifica_casca.gd` corre os 10 headless e confirma a moldura +
     que Koliani/Porta/Chefe nao ficam presos. Atmosferas dos 9 mantidas
     (ja tinham paletas proprias por nivel).
   - **FALTA:** rework da GEOMETRIA interior nivel-a-nivel (corredores
     apertados, pocos verticais, muros internos) -- a Casca so' da a
     moldura. `tools/shot_plataforma.gd` em modo `--window` FUNCIONA
     (headless as vezes crasha a' saida sem gravar).
   - Koliani apurada mais perto do guia (`d0ec161`): rim violeta, pernas
     sem vao branco, contraste. Continuar o loop PREVIEW=1 se preciso.

2. **Koliani -- apurar o gerador por codigo** (`tools/gerar_sprites.gd`
   `_kol_pose`/`KPAL`/`_poses_*`) p/ o guia do Paulo (bandana, cabelo
   curto side-swept, top s/ mangas + pauldron, capa roxa esfarrapada,
   botas altas, lamina roxa, fumos roxos). Ja esta perto -- e loop de
   PREVIEW=1 (`godot --headless --script res://tools/gerar_sprites.gd`,
   grava `assets/sprites/pixel/koliani/_preview_*` x8; a pasta
   `_preview_koliani` tem de existir) + olhar + afinar contraste/leitura.
3. Depois: continuar a melhorar mapas/conceitos/lutas/monstros dos
   restantes por `docs/niveis.md`, 1 mecanica distinta por mapa. Assets
   CC0 uteis por vasculhar em `assets/sprites/incoming/`: `chierit`
   (Minotaur/Slime/Frost Guardian), `clembod` Bringer of Death,
   `ansimuz` Hell-Hound, gothicvania church/town tilesets, ansimuz
   caverns/cold-corridors parallax, kenney pixel-platformer.
