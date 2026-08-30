# Progresso do agente `gaming` — campanha dos 30 níveis

## COMO RETOMAR (depois de um /clear)

Pedir ao agente `gaming` (ou dizer "continua o koliani"): **continuar a
campanha pelo guia `docs/niveis.md`**, um nível/chefe por commit, no padrão
já estabelecido (ver "Padrão de um nível novo" abaixo). Estado atual:

- **Região I — COMPLETA** (níveis 0–4): Floresta/Ghorak, Pântano/Morvanna,
  Ninho/Rainha Aracnídea, A Árvore que Chora/Entrevane, Coração da
  Floresta/Coração Putrefacto.
- **Região II — 2/5**: nível 5 Prisão/Carcereiro (antigo), nível 6
  Fornalha/Ignivar (novo). **A SEGUIR:** nível 07 Corredor das Execuções /
  Dama da Guilhotina → 08 Ala dos Mortos / Irmãos Condenados → 09 A Cela
  Zero / Primeiro Prisioneiro. `EstadoJogo.NIVEIS` = 9.
- Chefes: pixel-art gerado em `tools/gerar_sprites.gd` (`_boss_*`), tiras
  de 4 frames (0/1 idle, 2 telegrafo, 3 exposto).
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
