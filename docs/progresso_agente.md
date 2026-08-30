# Progresso do agente `gaming` — campanha dos 30 níveis

## ESTADO: CAMPANHA COMPLETA — 30/30 níveis, 30 chefes (v0.5.0, 2026-08-30)

As **6 regiões** estão construídas de ponta a ponta. `EstadoJogo.NIVEIS`
tem 30 entradas (índices 0–29), todas dentro de uma região; cada nível
tem cena + chefe (herda `ChefeBase`) + `_boss_*` em `gerar_sprites.gd` +
pista i18n×6 + `TEMPO_HARDCORE`. `Castelo_de_Zeriko.tscn` / `zeriko.gd` /
`Zeriko.tscn` ficaram como **legado** (fora da campanha).

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

**O QUE FALTA:**
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
