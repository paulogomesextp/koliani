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
