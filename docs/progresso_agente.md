# Progresso do agente `gaming` — campanha dos 30 níveis

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

## Regras que não mudam

Commits pequenos; `tests/run_tests.gd` a sair `OK` e export Web a
funcionar antes de cada commit; `push` para `master`. Texto do jogo só via
`Textos.t()` + os 6 JSON. Assets só CC0. Nunca mexer em `git config`.
