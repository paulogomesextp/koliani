# Execution 9G — VFX de produção da Região I

Data: 11 de setembro de 2026. Versão **v0.16.1**. Commit: `651c87f`.

## 1. Estado de partida (Git)

- branch `master`, HEAD = `origin/master` = `3520f32` (docs 9F).
- Trabalho não relacionado preservado: o reordenamento `ui_accept`/`ui_cancel`
  do Paulo no `project.godot` **nunca foi posto em stage** (só a linha
  `config/version`, via `git update-index --cacheinfo`); os Master Packages,
  worktrees e ferramentas não rastreadas ficaram intactos.

## 2. Autoridades

| prancha | dimensões | modo | SHA-256 | papel |
|---|---|---|---|---|
| `07_KOLIANI_VFX_CLEAN_v1_1.png` | 1536×1024 | RGBA | `6564982d…fe8c6` (= manifesto aprovado) | **autoridade dos VFX** |
| `12_PRODUCTION_PACK_v10_…_VFX_SFX_POLISH.png` | 1536×1024 | RGB | `6eea95ba…ccc221` (= manifesto) | só apresentação — nada extraído |

**O que custou a descobrir na prancha 07:** ela *tem* canal alfa, mas **não é
transparente**. O alfa anda entre **208 e 250 em toda a imagem** e o fundo de
cada célula é um xadrez escuro **pintado nos píxeis**. E as linhas das células
**não batem com os frames** (no "finisher burst" há dois rebentamentos dentro
da mesma célula; no "spin slash" a elipse do frame 03 cai quase em cima do
rótulo 04). Portanto: nem recorte pela grelha, nem alfa directo.

## 3. Método de produção (`tools/produzir_vfx_9g.py`)

1. **Fundo medido** por painel: percentil 97 por canal dos píxeis cinzentos.
2. **Alfa reconstruído** (classe B): o efeito é emissivo sobre escuro, logo
   `efeito = px − fundo`. Guarda-se RGBA com `rgb × a = px − fundo`; desenhado
   em modo **aditivo** dá exactamente o que a prancha mostra, sem o xadrez.
3. **Separação dos frames pelos VALES do desenho**: programação dinâmica que
   escolhe os `n−1` cortes de menor massa de alfa, com a largura de cada frame
   presa entre 55 % e 160 % do espaçamento dos rótulos. Sem o termo de
   regularidade a DP enfiava vários cortes seguidos na primeira zona vazia.
4. **Âncora** por frame: grelha regular ajustada por mínimos quadrados aos
   centros do desenho — o arco tem de AVANÇAR dentro do canvas; ancorar cada
   frame no seu próprio centro punha tudo a pulsar no mesmo sítio.
5. **Corrupção** (classe C): a mesma forma, luminância mapeada na rampa
   congelada (preto → violeta escuro → magenta profundo), com o **alfa preso à
   luminância**.

Escala: **1 px da prancha = 1 px do jogo** (nada foi redimensionado).

## 4. Inventário / famílias produzidas

| família | classe | frames | uso no jogo | canvas | validação |
|---|---|---|---|---|---|
| `spin_slash` | B | 8 | golpe 2 do combo | 64×66 | todos PASS |
| `heavy_slash` | B | 10 | golpe 3 (remate) | 76×73 | todos PASS |
| `dash_trail` | B | 8 | rasto do dash | 86×61 | todos PASS |
| `dash_impact` | B | 6 | arranque do dash / 2.º salto | 56×69 | todos PASS |
| `roll_dodge` | B | 8 | rolamento | 80×65 | todos PASS |
| `hit_sparks` | B | 8 | acerto | 72×67 | todos PASS |
| `finisher_burst` | B | 8 | remate / crítico | 72×72 | todos PASS |
| `hurt_blood` | B | 6 | Koliani ferida | 82×64 | todos PASS |
| `land_impact` | B | 8 | aterragem forte | 76×68 | todos PASS |
| `projectile` | B | 8 | tiro mágico | 70×76 | todos PASS |
| `charge_aura` | B | 8 | só como base da corrupção | 52×72 | todos PASS |
| `defend_shield` | B | 8 | escudo | 74×72 | todos PASS |
| `pickup` | B | 6 | apanhar / checkpoint | 50×77 | todos PASS |
| `death_dissolve` | B | 8 | morte | 48×72 | 1 REVIEW |
| `death_dissolve_corrupcao` | C | 8 | corrupção (inimigos, guardiões, Coração) | 48×72 | 1 REVIEW |
| `finisher_burst_corrupcao` | C | 8 | corrupção (inimigos, guardiões, Coração) | 72×72 | todos PASS |
| `projectile_corrupcao` | C | 8 | corrupção (inimigos, guardiões, Coração) | 70×76 | todos PASS |
| `charge_aura_corrupcao` | C | 8 | corrupção (inimigos, guardiões, Coração) | 52×72 | todos PASS |
| `hit_sparks_corrupcao` | C | 8 | corrupção (inimigos, guardiões, Coração) | 72×67 | todos PASS |

**148 frames: 146 PASS, 2 REVIEW, 0 FAIL.** Os 2 REVIEW são `RUIDO_ISOLADO`
no `death_dissolve_02` (frame quase vazio, 116 píxeis, 8 fortes — é assim na
prancha). Nenhum FAIL foi promovido em silêncio.

`slash_arc` e `teleport_portal` da prancha **não foram produzidos de
propósito**: o golpe 1 é o VFX do Golden Set (já em produção) e não há portal
em L1–L5 — não se fabricam efeitos para mecânicas que o runtime não usa.

## 5. Inventário do que já existia (auditado, não substituído à toa)

| efeito | antes | decisão |
|---|---|---|
| golpe 1 (`SlashVFX`) | Golden Set 9B.3 | **PRODUÇÃO — MANTIDO** |
| rasto do dash (`RastoDash`) | ecos de frames golden tingidos | **PRODUÇÃO — MANTIDO** (+ rasto/estalo da prancha por cima) |
| erupção da transição de fase | autoridade 9E.2 | **PRODUÇÃO — MANTIDO** |
| atmosfera, parallax, lanternas | kit 9C | **PRODUÇÃO — MANTIDO** |
| flash branco ao levar/dar dano | código, curto | **MANTIDO** (restrito e legível) |
| tom do corpo no telégrafo | código | **MANTIDO** — tem autoridade de gameplay |
| anel `impacto_azul` (pack CC0) | legado | **SUBSTITUÍDO** por `hit_sparks` (Região I) |
| partículas de salto duplo / aterragem / morte | CPUParticles genéricas | **SUBSTITUÍDAS** |
| cúpula/aro/glow do escudo | polígonos por código | **SUBSTITUÍDOS** |
| corpo do tiro (`laser_roxo`, pack CC0) | legado | **SUBSTITUÍDO** |
| disco de polígono na queda do chefe | código | **SUBSTITUÍDO** |
| estilhaços na morte dos inimigos | CPUParticles | **SUBSTITUÍDOS** pela dissolução de corrupção |
| `RaizPerigo` (racha + marca) | código | **EM FALTA de autoridade** — mantido; a prancha não desenha raízes |
| água venenosa | polígonos + partículas | **MANTIDA** — objecto de gameplay, sem autoridade na prancha |
| arte base da fogueira | código | fora do 9G (objecto), só o **feedback** entrou |

## 6. Distinção Shadowblade × corrupção

A Shadowblade fica no magenta claro da prancha (média de luminância das
faíscas **0,64**); a corrupção vai à rampa escura (**0,29** — 45 %). Há teste
que exige `corrupção < 0,85 × Shadowblade`.

**Erro corrigido a meio:** a primeira rampa mantinha o alfa do original, e o
brilho largo e fraco virava uma **mancha preta por cima do guardião** — tapava
a silhueta e o telégrafo. Ficou resolvido prendendo o alfa à luminância
(`a' = a × (0,12 + 1,15·lum)`): só os realces de magenta ficam opacos.

## 7. Gameplay

**Nada mudou.** Nenhuma constante de movimento, dano, hitbox, janela de
ataque, IA, limiar de fase (50 %), checkpoint, save ou progressão foi tocada.
A única mudança de assinatura é `_pop_impacto(pos, forte := false)` — escolhe
faíscas ou rebentamento, e mais nada. Os telégrafos mantêm tempos e o tom do
corpo; a aura de corrupção entra **atrás** do corpo (`z_index −2`) e aos pés.

## 8. Prova no runtime EXPORTADO (Windows)

Rota só de dev, nova em `main.gd`:
`Koliani.exe -- --nivel=N --foto-estado=vfx9g --foto=<png>`. Dispara cada
efeito pelo caminho normal do jogo, fotografa e escreve um JSON com a textura
que cada nó de VFX está **mesmo** a desenhar.

- **L1: 17 fotos. L5: 20 fotos. Texturas legadas de VFX: ZERO nas 37.**
- Cobre: golpes 1/2/3, dash, salto duplo, aterragem, dano, escudo, tiro da
  Koliani, tiro do chefe, acerto, remate, morte de inimigo, telégrafo do
  guardião, Coração fase 1 / transição / fase 2, queda do chefe, checkpoint
  pronto e aceso.
- O chefe **não é morto** (chama-se só o rebentamento da queda) e nada grava:
  o `%APPDATA%/Godot/app_userdata/Koliani` foi copiado antes e reposto depois,
  **verificado por SHA-256 ficheiro a ficheiro: 180/180 idênticos**.
- Evidência: `work/execution_9g/exe/` (fotos + `*_registo.json` +
  `folha_prova_exe.png`).

## 9. Web/PWA (mesmo commit `651c87f`)

- `index.pck` 57 369 320 bytes, SHA `3928d358…f5b51b`; **SHA medido no browser
  = export** (comparado dentro da página, em Chrome real).
- Service worker `activated`, cache única `Koliani-sw-cache-1789164610|58655591`.
- **VFX visíveis**: o arco do golpe aparece nas capturas do L1 no browser.
- **ÁUDIO (regressão do 9F): OK.** `suspended` antes do gesto → `running` ao
  primeiro clique real; pico no destino 0,176 no menu e 0,29 / 0,12 em jogo.
  O `default_bus_layout.tres` não foi tocado e o teste que o protege passa.
- Nome canónico live: o selector mostra "I · CORRUPTED FOREST" e a HUD do
  nível "Corrupted Forest".

## 10. Desempenho

`tools/perf_gate.tscn`, mesmas definições antes e depois (OpenGL, sem VSync,
10 s, 1152×648):

| cena | antes (ms médio / p95 / p99) | depois | frames > 20 ms |
|---|---|---|---|
| L1 | 1,072 / 1,485 / 1,786 | **1,046 / 1,459 / 1,781** | 0 → 1 (pico de 30 ms na 1.ª utilização) |
| L5 | 1,067 / 1,546 / 1,864 | **1,011 / 1,419 / 1,796** | 0 → 0 |

**Regressão: NÃO.** As médias e os percentis ficam iguais ou melhores (as
partículas que saíram compensam os sprites que entraram). O único pico novo é
o primeiro desenho de uma textura de VFX. Honestidade do método: a sonda anda
e salta, **não combate** — o custo medido não inclui uma sala cheia a rebentar.

Desenho a favor: `SpriteFrames` montadas **uma vez por família** e partilhadas,
efeitos de uma vez que se libertam sozinhos, texturas de 1–6 KB, nenhuma
PointLight2D nova, nenhum shader novo, nada de alocações por frame. Os únicos
efeitos em ciclo são o brilho do checkpoint por acender, a aura do telégrafo
(criada uma vez e só ligada/desligada) e a aura da fase 2.

## 11. Testes

- Suite headless completa: **OK — todos os testes passaram**.
- Novo: `teste_9g_vfx_producao_regiao1`, registado em `_correr_tudo` (a
  armadilha de sempre: um `teste_*` não registado passa sem correr). Verifica
  manifesto em `PRODUCTION_INTEGRATED`, SHA da autoridade, existência e estado
  de cada frame, texturas só da pasta de produção, corrupção mais escura que a
  Shadowblade, o interruptor ligado na Região I e **desligado no L6**, e o
  nome canónico nos 6 idiomas.
- **Provado a morder:** com os PNG por importar, o mesmo teste deu **168
  falhas**.

## 12. Fica por fazer / limites honestos

- `RaizPerigo` continua desenhado por código: **a prancha não tem raízes** —
  é arte nova, não conversão (condição A do briefing).
- Água venenosa e a arte base da fogueira mantêm-se: objectos de gameplay sem
  autoridade na prancha 07.
- `death_dissolve_02` fica em REVIEW (ruído isolado) — é assim na prancha.
- O ficheiro da cena ainda se chama `Floresta_Putrefata.tscn` (caminho
  interno, invisível ao jogador); renomear mexe em manifestos e saves.
- Sem playtest humano: o feel dos efeitos (duração, tamanho) é julgado por
  fotos, não a jogar.
