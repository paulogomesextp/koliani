# Retomar aqui — Koliani

Índice de integração documental: [master_package_integration.md](master_package_integration.md).

Atualizado em 11 de setembro de 2026.

## Execution 9G — VFX de produção da Região I — **PASS**

**REGION I VFX PRODUCTION GATE CLOSED. Pronto para 9H (montagem visual +
gate humano): SIM** (não iniciada). v0.16.1, commit `651c87f`. Relatório:
[execution_9g_region1_vfx.md](execution_9g_region1_vfx.md).

- **A prancha 07 tem alfa mas NÃO é transparente** (208–250 em toda a imagem;
  o xadrez está pintado nos píxeis) e **a grelha das células não bate com os
  frames** (dois rebentamentos numa célula; a elipse do "spin slash 03" cai em
  cima do rótulo 04). Método que resultou (`tools/produzir_vfx_9g.py`): fundo
  medido por painel (percentil 97 dos cinzentos) → `efeito = px − fundo`
  guardado para desenho **aditivo**; frames separados nos **vales do desenho**
  por programação dinâmica com as larguras presas ao espaçamento dos rótulos;
  âncora por grelha ajustada (mínimos quadrados) para o arco AVANÇAR.
- **Hipóteses descartadas, por ordem, e porquê:** (1) recorte pela grelha das
  células — as linhas não são os frames; (2) componentes ligadas por janela —
  o brilho fraco cola o vizinho e vinham lascas; (3) "rótulo mais perto" — a
  arte está desalinhada dos números e esvaziava frames; (4) DP sem penalização
  de largura — enfia vários cortes seguidos na primeira zona vazia.
- **148 frames: 146 PASS, 2 REVIEW, 0 FAIL.** 14 famílias Shadowblade
  (classe B) + 5 de corrupção (classe C).
- **Armadilha da corrupção:** recolorir mantendo o alfa dava uma **mancha
  preta por cima do guardião** (tapava a silhueta e o telégrafo). Resolvido
  prendendo o alfa à luminância (`a' = a × (0,12 + 1,15·lum)`).
- **Prova no EXE:** `--foto-estado=vfx9g` (rota nova, só dev): 17 fotos no L1,
  20 no L5, **zero texturas legadas**; userdata reposto e verificado por SHA
  (180/180). **Web:** PCK no browser = export (`3928d358…`), cache
  `1789164610|58655591`, VFX visíveis e **áudio do 9F sem regressão**
  (`running`, picos 0,18 menu / 0,29 jogo).
- **Desempenho sem regressão:** L1 1,072 → 1,046 ms; L5 1,067 → 1,011 ms. A
  sonda anda e salta, **não combate**.
- **Nome canónico corrigido nos 6 idiomas: FLORESTA CORROMPIDA**
  (`world.forest` + `level.n00`; live na HUD e no selector).
- **Por fazer:** `RaizPerigo` continua por código (a prancha não tem raízes =
  arte nova); água venenosa e arte da fogueira mantidas; sem playtest humano.

## Execution 9F — UI da Região I + áudio do Web/PWA — **PASS**

**REGION I UI GATE CLOSED. WEB/PWA AUDIO GATE CLOSED. Pronto para 9G (VFX):
SIM** (não iniciada). v0.16.0, commits `72bdc2a` (áudio) + `00399d0` (UI).
Relatório: [execution_9f_ui_pwa_audio.md](execution_9f_ui_pwa_audio.md).

- **Causa-raiz do Web mudo (provada no grafo Web Audio):** os buses Music/SFX
  eram criados em runtime (`Opcoes._criar_buses`). No Web o Godot 4.7.2 toca em
  modo Sample e o `GodotAudio.Bus.move()` do motor faz `splice(toIndex-1)`: o
  bus novo ia para a posição 0 e o Master antigo ficava ligado a ele — ciclo
  Master→SFX→Music→Master, nada chegava ao destino. Contexto `running`, pico 0.
  **Não era autoplay** (as 4 correcções de gesto anteriores não podiam
  resolver). Correcção: `default_bus_layout.tres`. Teste
  `teste_9f_buses_de_audio_estaticos` (morde).
- **Prova no Chrome real** (`?audio-debug=1` + `kolianiAudioDiag()`):
  `suspended` antes do gesto → `running` ao 1.º clique; música do menu 0,08–0,25;
  música de jogo L1 ≈0,09–0,11 contínua; com a Música a 0, SFX de UI (0,30) e de
  jogo (0,28–0,33) isolados. PCK no browser = export (`52349f3a…`), cache
  `1789150815|5733576`.
- **UI:** `tools/produzir_ui_9f.py` → `assets/ui/producao_9f/` (19 peças da
  prancha 09, SHA `264d6def…`; A recorte / B inpaint do texto + máscara / C
  barras). `scripts/ui_producao.gd` (tema). Menu, pausa, opções, diálogo, HUD
  (vida, energia, chefe, vidas, essência, cabeçalho "1-5"), toasts, checkpoint.
  **Seletor 20 × 5:** pastilhas I–XX, "I · REGIÃO · n/5", 1-1..1-5, só a região
  no carrossel, ↑/↓ muda de região; desbloqueio intacto (testado).
- **Prova no EXE:** `Koliani.exe -- --nivel=5 --foto-estado=ui9f --foto=…`
  (HUD, toasts, chefe, diálogo, pausa + JSON das texturas). Única legada:
  `ico_caveira.png`.
- **Armadilhas:** o pane do browser interno permite autoplay (o gesto só se
  prova num Chrome real); `AudioBufferSourceNode.prototype.start` é próprio (o
  hook no pai não apanha nada); rAF pára com o pane escondido; teclas de teste
  só chegam com o canvas focado (clicar primeiro); Espaço também confirma no
  seletor; logo a seguir a retomar da pausa a música recria a fonte (uma
  leitura a 0 nesse instante não é silêncio); a fonte Web não tem emoji nem CJK.
- **Backlog:** fonte CJK livre (chinês em tofu no Web, anterior); `✦` do
  Santuário no i18n; `ico_caveira`; manifestos fora dos exports.

## Execution 9E.2 — Coração Putrefacto fechado + prova no EXE — **PASS**

**ENEMY GATE CLOSED. BOSS GATE CLOSED. Pronto para 9F: SIM** (não iniciada).
v0.15.20, commit `901da1f`. Relatório:
[execution_9e2_coracao_putrefacto_closure.md](execution_9e2_coracao_putrefacto_closure.md).

- **Autoridade dedicada:**
  `work/production_art_gate/9E1_game_master_approved/coracao_putrefacto_production_authority_v1_0.png`,
  1448×1086 RGBA com alfa real, SHA `460435aaf18b9b568b0f4529a087a2cc80e07554def894c313f579b9b9247693`.
- **Boss:** fase 1 = forma contida, fase 2 = forma intensificada (limiar de 50 %
  do jogo), erupção = VFX da transição. `tools/produzir_coracao_9e2.py` →
  `assets/art/regions/region_01_forest/bosses/coracao_putrefacto/production/`.
  As luzes do legado lavavam a casca de rosa: raio a 40 % com produção.
- **Prova no EXE:** `Koliani.exe -- --nivel=N --foto-estado=inimigos --foto=…`
  (rota só de dev em `main.gd`) — 11 identidades + as 2 fases, 58 registos, 0
  texturas legadas. `work/execution_9e2/evidencia_exe_9e2.png`.
- **Armadilhas novas:** o Main junta mais bichos que a cena do nível (dezenas no
  L5) — a rota faz uma série por identidade e chefes primeiro; o alfa binarizado
  come/ganha 1 px, por isso a escala do boss é procurada até dar 100 px exatos.
- Pendente (opcional, design novo): poses de ataque do corpo (a autoridade tem
  duas, mas o runtime não tem estado onde as mostrar); arte do `RaizPerigo`.

## Execution 9D+9E — Inimigos + Coração Putrefacto — **PARTIAL PASS** (boss fechado pela 9E.2)

**ENEMY GATE CLOSED. BOSS GATE OPEN. Pronto para 9F: NÃO.** v0.15.19, commit
`dc06608`. Relatório:
[execution_9d_9e_region1_enemies_boss.md](execution_9d_9e_region1_enemies_boss.md).

- **Autoridade aprovada:**
  `work/production_art_gate/9D1_game_master_approved/region1_enemies_boss_visual_authority_v1_0.png`,
  1536×1024 RGBA, SHA `8ebf8ecd13e8d7e7d803acfcccf3361a35cb77ff9ad6dd1d01c79b8b24ebb2fd`.
- **Feito:** 11 entidades (5 comuns, 4 guardiões, clones da Morvanna, crias da
  Rainha) derivadas por `tools/produzir_inimigos_regiao1.py` e integradas;
  nenhuma arte legada de inimigo/guardião visível na Região I. Crias: campo
  `DemonioBase.identidade_visual` (só arte; `especie` fica goblin).
- **Bloqueado:** Coração Putrefacto. Está pintado dentro da arena; 3 máscaras
  tentadas (duas levam a arena, a terceira inventa uma elipse e perde os
  troncos). **Próximo passo:** o Game Master entregar o Coração isolado (alfa ou
  fundo liso); depois é juntar uma entrada ao produtor e o override de fase 2.
- **Armadilhas:** (1) o `run_tests.gd` só corre testes chamados em
  `_correr_tudo` — um `teste_*` novo não registado passa sem correr; (2)
  ferramentas de evidência que citam `DemonioBase`/`Chefe*` têm de ser CENA, não
  `--script`; (3) sem vsync, "N frames" são milissegundos — esperar por timer;
  (4) o rosa claro dos guardiões nas fotos é o `_piscar` (telégrafo), não a arte.
- Limitação aceite: uma pose por entidade → estados por translação/dissolução,
  sem ciclos de pernas.

## Execution 9D — Inimigos e guardiões da Região I — **BLOCKED na arte** (superada pela 9D+9E)

Estado: **APPROVED DIRECTION / PRODUCTION ASSET MISSING. REGION I ENEMY
PRODUCTION GATE: OPEN. Pronto para a 9E: NÃO.** Relatório:
[execution_9d_region1_enemies.md](execution_9d_region1_enemies.md).

- **Porquê:** nenhuma prancha desenha inimigos. A 12 (secção 10) tem alguns
  incidentais (plantas carnívoras, besouro, morcego, gosma), mas com ~30 px, em
  RGB, pintados sobre o cenário. Extraí-los obrigava a remover o fundo
  (proibido). Desenhar é design novo, o mesmo bloqueio da 9B.1. **Precisa de
  uma prancha de inimigos do Game Master.**
- **Pronto para quando a arte chegar:** `scripts/regiao1_inimigos.gd`
  (interruptor: kit 9C na cena + `PRODUCTION_INTEGRATED` no manifesto),
  chamado por `DemonioBase._montar_frames` e `ChefeBase._montar_rig`. Manifesto
  e contrato em `assets/art/regions/region_01_forest/enemies/production/`.
  Teste `teste_execution_9d_inimigos_regiao1`, provado a morder.
- **Inventário:** 5 espécies comuns (goblin L1, mushroom L2, gosma L2/L4,
  besouro L3, lodo L5) e 4 guardiões (Ghorak, Morvanna, Rainha, Entrevane).
  **Estados alcançáveis: só idle/run/hit/dead.** O `ChefeBase.atacar_anim()`
  nunca é chamado e o telégrafo é todo por código.
- **As aranhas da Rainha e os clones da Morvanna nascem como goblins** (a
  espécie fica na omissão). É um buraco de identidade e pede design.
- Gameplay intacto. Suite PASS. Builds não refeitos (nada visível mudou; o
  jogo continua o `a5d9ec9`/0.15.18).

## Execution 9C — Kit de ambiente da Região I

Estado: **PASS — REGION I ENVIRONMENT GATE CLOSED. KOLIANI PRODUCTION GATE
CLOSED (não tocado). Pronto para 9D (inimigos/guardiões): SIM** — a 9D não
foi iniciada. Relatório:
[execution_9c_region1_environment_kit.md](execution_9c_region1_environment_kit.md).

- **Kit:** 31 peças em `assets/art/regions/region_01_forest/production/kit_9c/`,
  recortadas sem perdas das pranchas 08 (autoridade, SHA `840cfd82…` = manifesto)
  e 10 (tileset, graduado para a noite da 08) por
  `tools/produzir_kit_regiao1_9c.py`; `--validar` 31/31 PASS; manifesto com a
  caixa exacta na prancha e o SHA de cada peça.
- **O kit `imagegen_v1` da 9A (12 peças) NÃO foi promovido:** musgo amarelo-lima
  em todas as pedras, ruído a 32 px — afasta-se da 08. Fica não rastreado.
- **LEGACY CC0 TERRAIN VISIBLE IN REGION I: NO.** Interruptor único: o nó
  `Region1HybridVisualTarget` entra no grupo `regiao1_kit`; `plataforma.gd` e
  `plataforma_flutuante.gd` usam o kit; os outros 95 níveis ficam no legado
  (testado). `perfil` 1–5 = moods da 08. Geometria intacta.
- **Parallax** à mão, 4 planos + primeiro plano (`posição = desvio × (1−f)`);
  o fundo legado da `Atmosfera` fica escondido. Lanternas com halo aditivo, não
  PointLight2D (não tinge a Koliani).
- **Desempenho:** +0,1 ms/frame (0,52–0,56 vs 0,42–0,44 ms), draw calls
  **descem** (49–62 vs 67–75). Sem regressão.
- Builds de `a5d9ec9` (0.15.18), worktree limpo: EXE 163,2 MB (`4f49ce2d…`),
  PCK 54,1 MB (`0a43829e…`), cache PWA `1789112478|4547531`. EXE: L1–L5 5/5.
  Web: SHA do PCK medido no browser = export.
- **Armadilhas de método (custaram tempo):**
  - o `run_tests.gd` é um nó, não `SceneTree`: `get_root()` → parse error → o
    Godot **pendura** (10 min). `get_tree().root`, e correr sempre com `timeout`;
  - o EXE de **release** recusa `--script` e caminhos de cena. Para fotografar
    níveis no EXE: `Koliani.exe -- --nivel=N --foto=<png>`, com cópia de
    segurança da pasta `app_userdata/Koliani` antes e reposição por SHA depois
    (a rotação de logs apaga logs antigos — repor também os que faltam);
  - o `tools/shot_plataforma.gd` não move a Koliani (fotos iguais) — usar
    `tools/shot_regiao1_9c.gd`.
- **Por fazer (não bloqueia):** o corpo do terreno é um mosaico de 44 px e lê-se
  regular em paredes muito altas; objectos de gameplay (água venenosa,
  checkpoints) mantêm arte própria — 9D/depois.

## Execution 9B.4 — Pacote completo da Koliani

Estado: **PASS — KOLIANI PRODUCTION GATE CLOSED. Pronto para 9C: SIM.**
Relatório: [execution_9b4_full_character_package.md](execution_9b4_full_character_package.md).

- **KOLIANI GOLDEN SET: PRODUCTION INTEGRATED / HUMAN APPROVED. KOLIANI FULL
  PACKAGE: PRODUCTION INTEGRATED.** Os 9 estados que caíam no premium_v1 (dash,
  roll, hurt, morte, crouch, wallslide, borda, djump, defesa) têm agora 23
  frames derivados **só** de frames golden inteiros: cópia, translação inteira,
  rotação exata de 90°. Ferramenta: `tools/derivar_pacote_koliani_9b4.py`.
  Validator v2: 7 PASS, 2 REVIEW (`POSE_AREA_VARIATION`), 0 FAIL.
- **PREMIUM_V1 / 5G BODY NA REGIÃO I: NÃO / NÃO.** Com `usar_golden_set` o
  `_montar_frames` não carrega tira nenhuma de outro rig; o teste novo exige
  que todos os frames venham de `koliani_golden_set/`.
- **Causa escondida do "chibi" no dash/roll:** o `_animar` esmagava o sprite a
  1,32×0,78 no dash e rodava-o no roll, mesmo em pixel-art. Desligado com o
  Golden Set (a pose está nos frames).
- VFX à parte: `RastoDash`, `SaltoDuploVFX`, `MorteVFX` (+ `SlashVFX`, flash,
  `Escudo`). Gameplay: nenhuma constante mudou.
- Builds de `f912753` (0.15.17), de worktree limpo: EXE 162,9 MB (`31e89a6b…`),
  PCK 53,7 MB (`4c5ae22f…`), cache PWA `1789108285|4479642`. Prova no EXE:
  12/12 estados com textura golden (`--foto-estado=pacote`; parede e rebordo
  forçados).
- **Limites (design novo se o GM quiser):** a morte acaba de joelhos (não há
  pose deitada), o rebordo é um agarrar ao nível do peito, os golpes 2–4
  reutilizam os frames do golpe 1.
- **Armadilha de método:** no Git Bash, `grep -c $'\r'` conta TODAS as linhas
  (deu "1779 CR" em ficheiros LF). Verificar CRLF com Python sobre os bytes.
- **Próximo:** 9C — kit de ambiente da Região I (não iniciada).

## Execution 9B.3 — Golden Set em produção e no runtime

Estado: **PASS — KOLIANI GOLDEN SET — PRODUCTION INTEGRATED.** Relatório:
[execution_9b3_golden_set_integration.md](execution_9b3_golden_set_integration.md).

- **KOLIANI GOLDEN SET VISUAL AUTHORITY: GAME MASTER APPROVED.** Canónico:
  `work/production_art_gate/9b1_game_master_approved/koliani_golden_set_approved.png`,
  SHA-256 `0b067780d316d1fcb288c2a3d944cd758a212f8d696c1818ae6ac0e4db0c60c4`
  (byte-idêntico ao `.png.png` original, que se mantém).
- **8 LOW-HEIGHT FRAMES: POSE-JUSTIFIED / ACCEPTED — 59px RULE = REVIEW ALERT
  ONLY.**
- Validator v2: o xadrez ignora alpha 0; a variação de área por pose passa a REVIEW
  com escala uniforme declarada; um resize real continua FAIL. 10/10 testes.
- 39 frames em `assets/sprites/koliani_golden_set/` + `production_manifest.json`.
  Ativos em L1–L5 via `usar_golden_set`. Os estados derivados usam só frames
  golden; o premium_v1 fica só para dash/roll/hurt/morte/crouch/wallslide/borda/
  djump/defesa. VFX no nó `SlashVFX`, `LuzLamina` desligada, gameplay intacto.
- Builds de `98d8c1b` (0.15.16), exportados de um **worktree limpo**: EXE
  162,7 MB (`d2fbf5e6…`), PCK Web 53,6 MB (`3b618698…`), cache PWA
  `1789089732|5080222`. Prova no EXE: 7/7 estados com a textura golden
  registada. Na Web: PCK byte-idêntico e Koliani golden visível, mas só parada
  (o painel do browser estava escondido).
- **Próximo:** pacote completo da Koliani, a derivar do Golden Set.

## Execution 9B.2 — Golden Set extraction

Estado: **PARTIAL PASS — EXTRAÍDO, GAME MASTER REVIEW REQUIRED; runtime
inalterado.** O Game Master forneceu a arte que bloqueava a 9B.1:
`work/production_art_gate/koliani_golden_set_approved.png.png` (a pasta
`9b1_game_master_approved/` não existe). Os 33 frames de corpo (idle 7, run 10,
jump_start 4, jump_loop 3, fall 3, attack_basic 6) e os 6 de `vfx_slash_basic` foram
extraídos pelo alpha real, sem redesenho, e normalizados ao contrato 9B.1: 128×128,
repouso **64 px**, pivot (64,104), baseline 103, escala uniforme 0,3975, alpha 0/255.
Validator v2: attack PASS; idle/fall REVIEW (`SUSPICIOUS_CHECKERBOARD`, falso positivo
provado: a heurística ignora o alpha); run/jump_start/jump_loop/vfx FAIL em
`GROSS_SCALE_VARIATION` (área da caixa por pose; a escala é uniforme). **Anti-chibi:
8 frames abaixo dos 59 px** por pose (jump_start_001 48 px, jump_loop_001/003,
attack 1/2/3/5/6), à espera de decisão do GM. Saída em
`work/production_art_gate/9b2_extraction/` (fora do git), relatório
`reports/execution_9b2_report.md`. Ferramentas: `tools/extrair_golden_set_9b2.py`,
`tools/validar_golden_set_9b2.py`. `assets/sprites/koliani_golden_set/` não foi
tocado.

## Execution 9B.1 — Golden Set da Koliani — **BLOQUEADA na arte**

Relatório: [production_art_gate_9b1_golden_set.md](production_art_gate_9b1_golden_set.md).
O Game Master resolveu CONF-01: **Route B**, arte desenhada de raiz.

**O bloqueio é simples: falta quem desenhe.** Um agente sem ferramenta de
imagem só consegue desenhar por código, e isso dava as "generic polygon
approximations" que a 9A proibiu. Não se produziu nem integrou arte nenhuma.

**Feito tudo o resto:** autoridade reverificada (6/6 SHA batem), contrato de
canvas derivado de medições, validador v2 integrado e **provado**, e o
`assets/sprites/koliani_golden_set/` criado com manifestos prontos.

**Contrato de canvas (falta o Paulo aprovar):** 128×128, personagem a 64 px,
pivot (64,104), baseline 103, escala Godot **1,0**, offset (0,−18). Os 64 px
aparentes são os mesmos de hoje (78 px × 0,82), por isso colisão, câmara,
física e tempos de combate não mexem. `(104−64−18)×1,0 = 22` = fundo da caixa
de 20×44, igual a `(90−48−15,170732)×0,82`.

**Defeito do salto CONFIRMADO por medição:** no conjunto 5G activo, `idle` e
`run` têm 78 px de altura; `jump_start` cai para 69 de média e **64 no pior
frame — menos 18%**. A cabeça não encolhe, logo a razão cabeça/corpo desloca-se
mesmo para chibi. Regra que fica: no Golden Set nenhum frame perde mais de 8%
(64 → mínimo 59 px). Imagem em
`work/production_art_gate/9b1_evidencia/defeito_chibi_salto.jpg`.

**Método descartado, para não se repetir:** medir a razão cabeça/corpo por
detecção de tom de pele **não funciona** — apanha braços e pernas e devolve
caixas de 27 a 64 px para a mesma personagem. A altura da figura é que é a
métrica objectiva.

**Validador v2 (`6f13409`) integrado por cherry-pick**, 6/6 testes verdes, e
provado contra o jogo real: `pilot_5g/idle` **PASS**, `premium_v1/attack`
**FAIL** (`CLIPPED_RIGHT`, o arco pintado sai do canvas), `premium_v1/dash`
**FAIL** (baseline 79 em vez de 89). Não vê rabo-de-cavalo nem idade — isso é
Gate 2, humano.

## Production Art Gate 9A — inventário feito, uma decisão à espera

Relatórios: [production_art_gate_9a_authority_inventory.md](production_art_gate_9a_authority_inventory.md)
e [production_art_gate_asset_gap_map.md](production_art_gate_asset_gap_map.md).
Manifestos em `work/production_art_gate/` (não versionado).

**As 12 autoridades aprovadas: 12/12 presentes, legíveis, e os 12 SHA-256 batem
com o `references/manifest.json` do pacote.** O que custou a descobrir: **só 3
têm canal alfa** (05, 06, 07). As outras 9 são RGB puro — incluindo a 02, que
desenha o xadrez de transparência *nos píxeis* e escreve «alpha real, pronto
para Godot». Não está. São exactamente as 3 com alfa as únicas de onde alguma
vez se extraiu alguma coisa.

**A lacuna central, medida:** na Região I o jogador vê **duas Kolianis**. Os
cinco níveis ligam `usar_prototipo_premium = true` **e**
`usar_piloto_visual_5g = true`, por isso `idle/run/turn/run_start/jump_start/
jump_loop/fall` saem da 5G (boa) e `attack1-4/dash/roll/hurt/morte/crouch/
wallslide/borda/djump/defesa/aterrar/jump` saem da `koliani_premium_v1`, que
tem **rabo-de-cavalo**, cabelo roxo e o **arco do golpe pintado dentro do
frame**. `run_brake` e `land` não têm frames — são montados por fallback.

**Números medidos:** 5G = 160×96, alfa binário 0/255, última linha opaca **89
em 7/7** (base consistente). `premium_v1` = base a variar entre 79, 80, 88, 89
e 90. Pacote contratado da Koliani: **0/40 frames**. VFX da prancha 07:
**0 de 16** produzidos. Kit modular da Região I: 12 peças existem, **0 estão no
build** (provado por varrimento de bytes do PCK e do EXE).

**Hipóteses descartadas:** (a) «as pranchas entram no build» — não entram, 0
ocorrências de `KOLIANI_VISUAL_AUTHORITY` no PCK e no EXE; o que inchou o build
antigo de 350 MB foi `work/**`, que já está no `exclude_filter`. Mas **nada
exclui o master package**, e as pranchas estão importadas (`.import` + `.ctex`)
— um export feito no checkout principal voltava a arrastar 29 MB. (b) «o rig
activo é o shadowblade» — é o `const RIG` do script, mas a Região I força o
premium, por isso não é o que se vê.

**A decidir antes do 9B (CONF-01):** o contrato proíbe extrair píxeis das
pranchas; o `.exe` aprovado usa 7 animações extraídas delas. Rota A (extracção
determinista, já provada em 45 frames, mas só serve as 3 pranchas com alfa) ou
Rota B (desenhar de raiz, cobre tudo). Recomendação no mapa de lacunas.

## Desbloqueio de áudio Web/PWA

O bootstrap Web retoma agora o `AudioContext` no início e no fim do gesto
(`touchstart`, `pointerdown`, `click` e equivalentes), mantém `audioSession` em
`playback` quando disponível e só reavalia o aviso depois de a Promise de
`resume()` terminar. Um pulso quase inaudível, em vez de um buffer totalmente a
zero, cobre WebKit que não reconheça silêncio otimizado como reprodução. Para
iPhone/Safari, o mesmo gesto arranca ainda um HTML Audio silencioso em loop,
forçando o canal multimédia que o Web Audio isolado nem sempre abre. Suite Godot
verde e export Web local concluído. O parâmetro `?audio-debug=1` mantém um botão
de diagnóstico visível com os estados Web/iPhone; ao tocar, produz um apito de
660 Hz diretamente no contexto para separar bloqueio do browser de falha interna
do Godot. O teste no iPhone 14 do Paulo ouviu esse apito: browser, contexto e
saída física estão funcionais. A causa restante era a música ser agendada antes
do desbloqueio e descartada pelo iOS enquanto o player continuava marcado como
activo. O HTML avisa agora `Musica` após a retoma e o autoload reinicia as fontes
120 ms depois. Falta confirmar a música/SFX num telemóvel real após a publicação:
**DEVICE VALIDATION REQUIRED**.

## Publicação contínua Web/PWA

O job `pages` da CI passou a fornecer realmente `enablement: true` ao
`actions/configure-pages@v5` e deixou de mascarar falhas com
`continue-on-error`. Cada push aceite em `master` que passe testes e export Web
publica a PWA em `https://paulogomesextp.github.io/koliani/`, no mesmo ciclo que
gera a versão Windows. Falhas de publicação ficam visíveis no workflow. O job
de testes cria agora `work/` antes da suite: a pasta é ignorada pelo Git, mas os
testes de save usam `res://work/` e falhavam em checkouts limpos sem ela. A
bancada `verifica_actores_novos.gd` prepara explicitamente `salto_duplo` antes
de testar `ZonaSemPoder`, pois a campanha atual começa canonicamente sem
habilidades e o teste antigo ainda assumia esse desbloqueio inicial. Os jobs
Windows e Web usam `always()` após a suite: gates vermelhos continuam visíveis,
mas não congelam os canais de entrega num commit antigo; Pages só publica se o
export Web correspondente passar. O próprio job Pages também usa `always()` e
`needs.web.result == 'success'`, evitando herdar o failure ancestral dos testes
quando o export Web terminou verde.

## Production Asset Validator v2 — infraestrutura técnica

Branch `tools/production-asset-validator-v2`: validator determinístico e
somente-leitura preparado em `tools/production_asset_validator/`, com contrato
JSON configurável, relatórios JSON/Markdown, contact sheet 1:1 e fixtures
sintéticas. Suite própria: 6 testes, 0 falhas. Não houve decisão artística,
geração/integração de assets nem alteração de runtime; 9B não foi iniciada.

Próximo passo: após conclusão de 9A, fornecer em 9B manifestos e caminhos/hash
das referências aprovadas, correr o validator e encaminhar `REVIEW` ao Game
Master.

## Execution 8.1E — Congelamento do save — **RESOLVIDO**

Estado: **PASS.** `EstadoJogo.guardar()`: **2047 ms -> 9,2 ms** de mediana
(pior 14,3 ms), medido na mesma ferramenta que deu o 2047 (`tools/verifica_gravar.tscn`).
Cabe num frame a 60 Hz. Relatório: [execution_8_1e_causa_do_congelamento.md](execution_8_1e_causa_do_congelamento.md).

**A causa era CPU, não disco.** `ProgressionIDs.identidades()` relia e
parseava `data/level_manifest.json` **1312 vezes por gravação** (seis
validações completas em `escrever_seguro()`, e `reward_ids()` sozinho chama-o
uma vez por nível). Corrigido com cache do manifesto + identidades derivadas,
aquecido no `_ready()` do `EstadoJogo`.

**A 8.1C estava enganada** ao culpar o antivírus/`%APPDATA%`: o custo real de
tocar no disco por gravação é **~2 ms**. A exclusão do Windows Defender que lá
ficou sugerida não era precisa.

**`save_pipeline.gd` foi REMOVIDO.** Com 9,2 ms já não é preciso thread
nenhuma, e o export Web é `single-threaded` — a thread nunca teria resolvido lá
nada. O desenho fica no commit `0269d20` se voltar a ser preciso.

**Falta:** validação a jogar no `build/windows/Koliani.exe` (checkpoint,
dano de projétil, dano repetido, morte/reaparecimento). O `.exe` está
construído e arranca limpo, mas jogar é com o Paulo.

**Trava de método:** `godot --headless --path . --check-only --script res://tools/x.gd`
antes de correr qualquer cena de ferramenta nova. Um erro de parse não estoira
— pendura o motor com o log vazio.

## Execution 8.1D — Save não-bloqueante — **INCOMPLETA**

Estado: **BLOCKED.** Sessão encerrada antes de ligar a implementação.
**O jogo continua a congelar ~2 s** no checkpoint e ao levar dano.

`scripts/save_pipeline.gd` está escrito e compila (suite verde), mas
**nenhum ficheiro o usa** — é código inerte. Falta ligá-lo ao `EstadoJogo`.
Relatório e passos exatos: [execution_8_1d_save_nao_bloqueante.md](execution_8_1d_save_nao_bloqueante.md).

**Pista principal para quem retomar:** `ProgressionIDs.identidades()` lê e
faz parse de `data/level_manifest.json` **do disco a cada chamada**, e
`escrever_seguro()` faz seis validações completas que a chamam dezenas de
vezes. Os ~2 s são provavelmente isso — não a escrita, não o antivírus.
**Não medido**, é leitura de código. Se se confirmar, um cache do manifesto
resolve Windows **e** Web (na Web não há threads, o fallback é síncrono e a
thread de fundo sozinha não a salvava).

**Armadilha:** uma cena de ferramenta com erro de parse não estoira — o
Godot fica a correr para sempre sem imprimir nada. Procurar `Parse Error`
no log antes de assumir que está lento. Custou duas corridas de 10 minutos.

## Execution 8.1C — Combat Freeze / Hit-Stop Gate

Estado: **PARTIAL PASS — CAUSA PRINCIPAL PROVADA, CORREÇÃO POR DECIDIR.**

**O congelamento é GRAVAR O SAVE.** `EstadoJogo.guardar()` custa **~2047 ms
de mediana** na thread principal (`tools/verifica_gravar.gd`, 12 gravações).
É chamado por `ativar_checkpoint()` (passar num checkpoint) e por
`perder_vida()` — os dois gatilhos que o Paulo identificou. Explica também
todos os buracos de ~2 s que apareceram nas medições desta sessão (2019,
1975, 1953, 2254, 2081 ms), incluindo o "parada no spawn aos 9 s".

Não há esperas no código: são ~10 operações de ficheiro síncronas por
gravação (escrever TEMP, ler TEMP, ler primary, ler backup, escrever backup,
apagar primary, renomear), cada uma inspeccionada pelo antivírus em
`%APPDATA%` — ~200 ms cada.

**Teste de confirmação sem tocar em código:** excluir
`%APPDATA%\Godot\app_userdata\Koliani` do Windows Defender e voltar a jogar.

**NÃO se mexeu no sistema de save** — tem suite própria de robustez
(corrupção, recuperação, versões, backup validado). Opções por risco
crescente: (a) gravar em thread de fundo mantendo a lógica de integridade;
(b) juntar/espaçar gravações; (c) cortar as leituras de validação repetidas
(esta mexe nas garantias que os testes protegem).

Já corrigido e provado nesta execução:

- **música do chefe**: `provocar()` → `Musica.boss()` fazia `load()` no
  primeiro golpe, na thread principal, com o `time_scale` já a 0 (hitstop) —
  o temporizador que repõe o tempo não podia correr. **2019 ms → 23,4 ms**;
- **áudio dos passos**: `som.gd` carregava cada SFX à primeira utilização.
  Saltar/andar tocava `passo1/2/3.ogg` pela primeira vez e congelava. Agora
  `Som.aquecer_tudo()` pede os 66 sons em segundo plano no arranque —
  **zero carregamentos de áudio depois do nível arrancar**;
- **hit-stop** reduzido para ≤2 frames no frequente e ≤4 no raro (era 7–10).
  Combo + golpe levado: ~97 ms → ~28 ms.

**Correção ao que a 8.1 dizia:** a recarga de nível **não custa 150 ms, custa
~2 s**. A 8.1 mediu com o `delta` do motor, que vem **limitado**; medir
engasgos exige tempo de parede (`Time.get_ticks_usec()`).

Branch `perf/windows-gate-8-1`, commit `b0e9728`. `origin/master` continua
`b2fd8a0` — **não fundir sem revisão do Game Master**.

## Execution 8.1B — Physics Interpolation / Cadence Fix

Estado: **TECHNICALLY VALIDATED / GAME MASTER CADENCE REVIEW REQUIRED**.

`physics/common/physics_interpolation = true`, com a física a continuar a
**60 Hz**. Nenhuma constante de movimento, salto, dash, combate ou câmara
mudou. Provado sobre a imagem desenhada (gravador de filme a 165 fps): o
desvio-padrão da diferença entre frames consecutivos caiu **59 %** e o rácio
p90/mediana passou de **4,19× para 2,06×** — o movimento deixou de chegar aos
solavancos.

Auditados e resolvidos: 4 teletransportes com `reset_physics_interpolation()`
(respawn, rebordo, fosso dev, portal) e 10 nós animados no `_process` com
`PHYSICS_INTERPOLATION_MODE_OFF`. O risco escondido era a **viragem**
(`scale.x = ±1`), que interpolada esmagava o sprite; resolvido desligando no
`$Sprite` (o modo é herdado). Como `ChefeBase extends DemonioBase`, uma
correção cobre inimigos e chefes todos.

A câmara não foi tocada: é filha da Koliani e só escreve `offset`, que não é
interpolado. O motor avisa que passa a `Camera2D` para modo física — é
esperado; o efeito é o screen shake ficar amostrado a 60 Hz.

Suite, jornada 1–100, alcance, Execution 7 targeted e combate runtime: PASS.
Windows e Web/PWA reexportados do mesmo source; cache PWA
`1789071258|42187478`. Relatório:
[`execution_8_1b_physics_interpolation.md`](execution_8_1b_physics_interpolation.md).

Backlog que fica OPEN por instrução: recarga de cena ~150 ms e compilação de
pipelines à primeira utilização.

## Execution 8.1 — Windows Performance Gate

Estado: **PARTIAL PASS — DIAGNÓSTICO FECHADO / DECISÃO DO GAME MASTER
NECESSÁRIA**. **Nenhuma alteração ao runtime do jogo.**

Os "framedrops severos" no `Koliani.exe` **não são falta de desempenho**. Com
o VSync desligado o L1 corre a **1388 FPS (0,72 ms/frame)** a 1080p; script
0,03 ms, física 0,2 ms, 129 draw calls. Em 47 recargas os nós ficam fixos em
871 e os órfãos em 0 — **não há fugas**. Menu, L1, L3, L5 e o Coração
Putrefacto têm todos o mesmo tempo de frame.

Causas-raiz provadas:

1. **Cadência (PROVEN):** física a 60 Hz num painel de 165 Hz com
   `physics_interpolation` desligado → **67,2 % dos frames desenhados não têm
   avanço nenhum**. Os FPS ficam nos 165 e o movimento anda aos degraus. É o
   que se lê como "framedrop" sem os FPS caírem.
2. **Carregamento de cena (PROVEN):** ~150 ms de congelamento em cada morte e
   troca de nível (todos os picos > 33 ms medidos são recargas).
3. **Primeira utilização (LIKELY):** quedas esparsas de um segundo no EXE
   real; o preset de export não tem `shader_baker/enabled`.

As três correções são arquiteturais e ficam **para decisão** (secção 25 do
briefing). Relatório e números:
[`execution_8_1_windows_performance_gate.md`](execution_8_1_windows_performance_gate.md).
Sonda reutilizável: `tools/perf_gate.tscn`.

Duas armadilhas de método registadas: morrer recarrega a cena atual, o que
reinicia qualquer sonda que seja a cena; e a suite corre por **cena**
(`--headless --path . res://tests/run_tests.tscn`), não por `--script` — e
precisa da pasta `work/`.

## Execution 8 — Real Game Production Integration

Estado: **PARTIAL PASS — REAL RUNTIME TECHNICALLY VALIDATED / HUMAN REVIEW
REQUIRED**. O fluxo real `Koliani.exe` → menu → mapa/seletor → `Main` →
L1–L5 foi traçado. A Koliani 6B e os 44 frames SAFE estão ativos nos cinco
níveis; panorama/Heart Tree aprovado de 6A foi ligado em toda a Região I;
combate, guardiões, Coração Putrefacto e reward foram confirmados ativos.

Exports release já não oferecem `DEVELOPER MODE`, `BOSS TEST`, `TESTAR OUTRO
NÍVEL` nem `FLYMODE`. Windows e Web/PWA foram regenerados do mesmo estado;
smoke Windows, capturas reais, HTTP/Chrome e service worker passaram. Cache
PWA: `1789065387|5837615`. Evidência:
`work/execution_8/real_runtime/region1_runtime_contact_sheet.png`. Relatório:
`docs/execution_8_real_game_production_integration.md`. Retoma externa:
`docs/claude_handoff_execution_8.md`.

Plataformas, props, inimigos/guardiões, boss art, parte de UI e VFX/SFX
continuam legacy por falta de assets de produção aprovados. O kit regional
ImageGen permanece apenas tecnicamente validado e não foi promovido para
L2–L5. **HUMAN VISUAL/COMBAT FEEL/BALANCE/PLAYTEST e DEVICE VALIDATION
REQUIRED**. Próximo passo: revisão humana do build 8 e criação/aprovação dos
gaps; não iniciar Região II.

## Execution 7 — Region I Vertical Slice Completion

Estado: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN REVIEW REQUIRED**.
Combate base foi fechado em três golpes com janelas ativas/deduplicação,
ataque aéreo singular e integração de Dash sem alterar movimento, câmara ou
colisões. L1–L4 terminam agora em guardiões (Ghorak, Morvanna, Rainha
Aracnídea e Entrevane) sem estado/baú de boss; L5 mantém o boss regional
canónico Coração Putrefacto, fase 2 a 50%, Dash e reward idempotente.

Suite, gates dirigidos, source/generator, jornada 1–100, alcance, L4 interior,
checkpoints L5, reward e renderer real passaram. Evidência:
`work/execution_7/review/region1_vertical_slice_review.png`,
`combat_review.png`, `region1_boss_review.png`. Relatório completo:
`docs/execution_7_region1_vertical_slice_completion.md`.

Windows `build/windows/Koliani.exe` e Web/PWA `build/web/index.html` foram
regenerados e passaram smoke local; cache PWA `1789055058|5419303`. Para
retoma noutra ferramenta, usar `docs/claude_handoff_execution_7.md`.

Produção final de combate/inimigos/boss e expansão visual L2–L5 continuam em
falta; legacy funcional foi mantido. **HUMAN VISUAL REVIEW REQUIRED, HUMAN
COMBAT FEEL REVIEW REQUIRED, HUMAN BALANCE REVIEW REQUIRED e HUMAN PLAYTEST
REQUIRED**. Próximo passo: rever Região I nos builds finais desta execução;
não iniciar Região II.

## Execution 6B — Character + Level 1 Completion

Estado: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW
REQUIRED**. A causa das pernas cortadas era a extração histórica da faixa
`run`: divisão uniforme sobre células de larguras reais irregulares, seguida
de seleção que descartou componentes legítimos dos membros. `run_03`–`run_09`
foram reextraídos apenas da autoridade 05; resultado: 44/44 frames ativos
`SAFE`, sete `FIXED`, zero bloqueados e zero divergências de atlas.

Escala `0,82`, offset `-15,170732`, pivot `(80,90)`, canvas `160×96`, baseline
`Y=90`, colisão, movimento e câmara foram preservados. Renderer real, targeted
de Koliani/Level 1/Movement+Camera, alcance e suite completa: PASS.

O ambiente 6A foi preservado. O kit modular local 12/12 passou tecnicamente,
mas permanece `validated`, com origem `_source/imagegen_v1`; não foi promovido
sem aprovação visual. Legacy funcional de plataformas, inimigos, HUD, VFX e
áudio foi retido onde falta produção aprovada. Windows e Web/PWA foram
regenerados; smoke local PASS; cache PWA `1789047133|5780304`.

Evidência: `work/execution_6b/preview/level1_6b_review.png`,
`level1_6a_vs_6b.png`, `koliani_6b_gameplay_review.png` e relatório
`docs/execution_6b_character_level1_completion.md`.

Próximo passo autorizado: **HUMAN VISUAL REVIEW REQUIRED** da Koliani 6B e do
Level 1 6A/6B. Não iniciar 6C nem Levels 2–5.

## Execution 6B — Character + Level 1 Completion

Estado: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW
REQUIRED**. A causa das pernas cortadas era a extração histórica da faixa
`run`: divisão uniforme sobre células de larguras reais irregulares, seguida
de seleção que descartou componentes legítimos dos membros. `run_03`–`run_09`
foram reextraídos apenas da autoridade 05; resultado: 44/44 frames ativos
`SAFE`, sete `FIXED`, zero bloqueados e zero divergências de atlas.

Escala `0,82`, offset `-15,170732`, pivot `(80,90)`, canvas `160×96`, baseline
`Y=90`, colisão, movimento e câmara foram preservados. Renderer real, targeted
de Koliani/Level 1/Movement+Camera, alcance e suite completa: PASS.

O ambiente 6A foi preservado. O kit modular local 12/12 passou tecnicamente,
mas permanece `validated`, com origem `_source/imagegen_v1`; não foi promovido
sem aprovação visual. Legacy funcional de plataformas, inimigos, HUD, VFX e
áudio foi retido onde falta produção aprovada. Windows e Web/PWA foram
regenerados; smoke local PASS; cache PWA `1789047133|5780304`.

Evidência: `work/execution_6b/preview/level1_6b_review.png`,
`level1_6a_vs_6b.png`, `koliani_6b_gameplay_review.png` e relatório
`docs/execution_6b_character_level1_completion.md`.

Próximo passo autorizado: **HUMAN VISUAL REVIEW REQUIRED** da Koliani 6B e do
Level 1 6A/6B. Não iniciar 6C nem Levels 2–5.

## Region I — Modular Sprite Kit v1

Estado: **TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW REQUIRED**. As
autoridades aprovadas 08 e 10 foram convertidas em 12 sprites ambientais
individuais: terreno, remates, cantos, duas plataformas, raízes, musgo,
corrupção e bloco de ruína. Todos cumprem as dimensões 32/64/96 px, alfa,
nearest-neighbour e costuras declaradas no contrato; `validate_region_artkit`
passou com `12 presentes / 0 missing / 0 fails` e o Godot 4.7.2 importou os 12
PNGs.

Fontes, gerador e hashes foram preservados. Prancha de revisão:
`work/region_01_sprite_kit_v1/preview/region_01_sprite_review.png`. Não houve
integração no Level 1 nem alterações de gameplay, geometria ou Koliani. Próximo
passo: aprovação visual humana da prancha antes de qualquer integração.

## Delivery Sync — Windows + Web/PWA

Estado: **PASS LOCAL / REMOTE PAGES NOT CONFIGURED**. Em 10 de setembro de
2026, os presets existentes `Windows Desktop` e `Web` foram exportados do
working tree em `HEAD 24fdf3f` (com alterações locais 5G.1 preservadas) para
`build/windows/Koliani.exe` e `build/web/`. O atalho estabelecido
`Koliani (testar).lnk` continua a apontar para `jogar.bat` e foi confirmado a
lançar o novo `build/windows/Koliani.exe`; o executável anterior era de 6 de
setembro e, portanto, anterior à Execution 6A.

Smoke Windows real e smoke Web/PWA local: PASS. Ambos mostraram no Level 1 o
panorama/floresta, Heart Tree baked, cascatas, ruínas/silhuetas e foreground
da 6A. O PWA gerou manifest, service worker e cache novo
`1789024307|5115130`, que elimina caches antigos com o prefixo Koliani. A rota
GitHub Pages existe no workflow, mas o deployment público permanece 404 e a
própria configuração regista que Pages ainda precisa de ativação no repo.
Metadados locais ignorados em `build/*/BUILD_SOURCE.txt` ligam os artefactos ao
commit e ao estado dirty.

Próximo passo: **HUMAN PLAYTEST REQUIRED** para o bloqueio visual já conhecido
das pernas/lower body da Koliani; não foi alterado nesta sincronização.

## Execution 6A — Level 1 Approved Visual Build

Estado: **PARTIAL VISUAL BUILD / PRODUCTION ASSETS MISSING — HUMAN REVIEW
REQUIRED**. O panorama aprovado da referência 08 foi recortado losslessly e
integrado em toda a rota do Level 1, incluindo Heart Tree, cascatas, ruínas,
floresta profunda e foreground baked. Foram removidos do runtime o céu,
landmark, máscaras de plataforma, midground e foreground vetoriais genéricos
do target 5C. Geometria, colisões, 20 plataformas, porta, inimigos, Ghorak e
Koliani 5G.1 foram preservados.

Verificação 6A, 5G.1, Movement/Camera, alcance e suite completa: PASS. Renderer
Vulkan Forward Mobile: PASS em oito pontos. O módulo visual tem agora 29 nós,
3 luzes e 1 emissor/34 partículas, contra 406 nós no 5C. Evidência:
`work/execution_6a/preview/level1_6a_review.png` e
`work/execution_6a/preview/level1_before_after.png`. Relatório completo:
`docs/execution_6a_level1_implementation.md`.

Próximo passo: **HUMAN PLAYTEST REQUIRED** para legibilidade/continuidade e
produção, sem redesign, dos layers alpha, tiles Hybrid, props, inimigo
infectado, replacement de Ghorak, HUD e áudio ainda em falta.

## Execution 6A — Level 1 Approved Visual Build

Estado: **PARTIAL VISUAL BUILD / PRODUCTION ASSETS MISSING — HUMAN REVIEW
REQUIRED**. O panorama aprovado da referência 08 foi recortado losslessly e
integrado em toda a rota do Level 1, incluindo Heart Tree, cascatas, ruínas,
floresta profunda e foreground baked. Foram removidos do runtime o céu,
landmark, máscaras de plataforma, midground e foreground vetoriais genéricos
do target 5C. Geometria, colisões, 20 plataformas, porta, inimigos, Ghorak e
Koliani 5G.1 foram preservados.

Verificação 6A, 5G.1, Movement/Camera, alcance e suite completa: PASS. Renderer
Vulkan Forward Mobile: PASS em oito pontos. O módulo visual tem agora 29 nós,
3 luzes e 1 emissor/34 partículas, contra 406 nós no 5C. Evidência:
`work/execution_6a/preview/level1_6a_review.png` e
`work/execution_6a/preview/level1_before_after.png`. Relatório completo:
`docs/execution_6a_level1_implementation.md`.

Próximo passo: **HUMAN PLAYTEST REQUIRED** para legibilidade/continuidade e
produção, sem redesign, dos layers alpha, tiles Hybrid, props, inimigo
infectado, replacement de Ghorak, HUD e áudio ainda em falta.

## Execution 5G.1 — Correção visual do piloto no Level 1

Estado: **PARTIAL PASS / HUMAN PLAYTEST REQUIRED**. A medição determinística
dos sete strips ativos encontrou 44 frames únicos: 37 `SAFE` e 7
`ACTUAL_CLIPPING`. O número 45 anteriormente documentado inclui
`run_brake_01`, que não integra o fallback atual. Nenhum frame toca o canvas
normalizado `160×96`; as margens mínimas são 12 px no topo, 38 px nos lados e
6 px no fundo, com baseline opaca uniforme em `Y=89`.

A causa primária é recorte-fonte anterior à normalização: `run_03`–`run_06`
tocam o limite esquerdo do recorte original e `run_07`–`run_09` o limite
direito. Padding, offset ou escala não recuperam esses pixels ausentes, e não
foram inventados, redesenhados ou reextraídos sprites. Como correção parcial da
escala pequena observada no Level 1, a apresentação global do piloto passou de
`0,75` para `0,82`; o offset Y passou de `-12,666667` para `-15,170732`,
preservando pés em `y=22`, pivot `(80,90)`, colisão e hitbox.

Verificador 5G, Movement + Camera 4A, alcance do Level 1 (20 plataformas e
porta alcançável) e suite completa: PASS. Smoke/captura real OpenGL 3.3 na
NVIDIA RTX 5070: PASS, com avisos ambientais já conhecidos de `user://`,
certificados e opções. Relatório: `work/execution_5g_1/frame_margin_report.json`.
Comparação: `work/execution_5g_1/preview/before_after_visual_fix.png`.

Próximo passo único: **HUMAN PLAYTEST REQUIRED** no Level 1 para validar escala
`0,82`, contacto dos pés, face, centro visual e popping das transições antes de
aceitar a correção. Os sete frames `run_03`–`run_09` continuam a exigir fonte
completa para eliminar o clipping sem inventar arte.

## Execution 5G — Level 1 Locomotion Visual Pilot

Estado: **TECHNICAL PASS / HUMAN PLAYTEST REQUIRED**. Os 45 frames limpos de
`idle` (10), `run` (12), `turn` (4), `run_start` (6), `jump_start` (4),
`jump_loop` (4) e `fall` (4) foram copiados sem alteração para
`assets/sprites/pixel/koliani_visual_pilot_5g/` e ligados ao runtime apenas na
instância da Koliani do Level 1. A seleção de animação observa o estado físico
existente, mas não altera movimento, salto, gravidade, dash, combate, colisões,
hitboxes, câmara, save/sessão, localização ou progressão.

`run_brake` é um fallback explícito com `run_10`–`run_12` + `idle_01`;
`land` (com alias legado `aterrar`) usa `fall_04` + `idle_01`. Combate e outros
estados sem frames 5G continuam no piloto 5B. A flag nova está desligada por
omissão, ativa apenas em `Floresta_Putrefata.tscn` e pode ser desligada para
rollback imediato.

Validação: targeted 5G PASS, suite completa PASS, Movement + Camera 4A PASS,
alcance do Level 1 PASS (20 plataformas, porta alcançável), smoke OpenGL real
com o target 5C ativo PASS e nove capturas em `work/execution_5g/`. O import
reportou apenas avisos ambientais/preexistentes de escrita em `user://` e
ficheiros AppleDouble `.wav`; o smoke real final não reportou erros.

Ficheiros 5G: `scripts/koliani.gd`; uma propriedade em
`scenes/levels/Floresta_Putrefata.tscn`; sete PNG + `.import` na pasta do piloto;
os pares `.gd`/`.tscn` `tools/verifica_koliani_visual_pilot_5g` e
`tools/shot_koliani_visual_pilot_5g`; `PRIORIDADES.md`, `docs/plano_atual.md` e
este ficheiro. Capturas em `work/execution_5g/` são evidência ignorada pelo Git.

Próximo passo único: **HUMAN PLAYTEST REQUIRED** no Level 1 para escala,
legibilidade, continuidade das nove sequências visuais e glitches nos fallbacks.
Não iniciar outro lote antes dessa decisão.

## Recuperacao Medium — sprites base normalizados

Estado: **PARTIAL PASS / HUMAN REVIEW REQUIRED**. Foram inventariados os 56
frames existentes e revistos os 13 alvos prioritarios. A selecao deterministica
do componente alto/central recuperou os sete falsos recortes (`turn_04`,
`jump_start_03`, `jump_start_04`, `jump_loop_01`, `jump_loop_03`, `fall_01` e
`fall_04`) sem criar pixels. A revisao geral corrigiu ainda 23 contaminacoes
objetivas por moldura/legenda. Existem 45 frames limpos e strips completos de
`idle`, `run`, `turn`, `run_start`, `jump_start`, `jump_loop` e `fall`.

Continuam bloqueados `run_brake_02`–`run_brake_06` e `land_01`–`land_06` como
`VFX_SEPARATION_REQUIRED`, porque poeira/impacto toca pes ou corpo e a remocao
segura exigiria inferir pixels ocultos. `run_brake` e `land` nao receberam strip
final. Relatorio, folhas de revisao, frames e fonte deterministica:
`work/koliani_extraction_recovery_medium/`. Runtime, cenas, gameplay e assets
integrados permaneceram inalterados.

Proximo passo unico: revisao humana da folha
`work/koliani_extraction_recovery_medium/preview/review_before_after.png` e
fornecimento de frames sem VFX para os 11 bloqueios; nao integrar no Godot antes
dessa decisao.

## Execution 5F.1 — limpeza dirigida da extração

Estado: **TARGETED CLEANUP COMPLETE / HUMAN REVIEW REQUIRED**. Foram
inspecionados os 56 frames normalizados existentes em
`work/koliani_extraction_full/`; nenhum frame aprovado foi alterado. A revisão
identificou 7 frames com falha estrutural de extração (`turn_04`,
`jump_start_03`, `jump_start_04`, `jump_loop_01`, `jump_loop_03`, `fall_01`,
`fall_04`) e os 6 frames de `land` com poeira/impacto fundidos. Não foi segura
uma separação determinística sem risco de perder corpo/cabelo/pernas ou
inventar pixels. A folha exclusiva de revisão está em
`work/koliani_extraction_full/preview/problem_frames_review.png`.
Runtime permaneceu inalterado. Próximo passo único: revisão humana destes 13
frames; `land_01`–`land_06` permanecem `VFX_SEPARATION_REQUIRED`.

## Execution 5E — piloto de extração automática

Estado: **PILOT EXTRACTION READY / HUMAN REVIEW REQUIRED**. Foram extraídos
deterministicamente seis testes da prancha aprovada `05`: dois Idle, dois Run,
um Jump Loop e um Land. Cada recorte mantém a resolução natural e tem uma
versão RGBA com alpha binário `0/255`; não houve geração de arte, integração
Godot ou alteração de runtime. A preview compara cada resultado com o original
sobre fundos preto, branco e verde. Não há dano grosseiro visível, mas halo,
microperdas e o VFX ligado do Land dependem de revisão humana.

Próximo passo único: **HUMAN REVIEW OF CONTACT SHEET** em
`work/koliani_extraction_pilot/preview/koliani_extraction_pilot_contact_sheet.png`.
Não extrair os restantes frames antes da aprovação. Relatório:
`work/koliani_extraction_pilot/reports/execution_5e_pilot.md`.

## Pixelorama capability test — master sprite pilot

Estado: **PIXELORAMA NOT USABLE FOR ART AUTHORING** neste ambiente de agente.
O Pixelorama portátil `v1.2.2-stable` existe e executa localmente; a versão Web
oficial também carregou no browser e aceitou interação básica. Contudo, a
janela nativa não é exposta ao controlo de computador e o editor Web surge
inteiro como um único canvas sem controlos semânticos, seleção de layers ou
feedback de píxel acessíveis. O controlo por coordenadas não oferece precisão
nem auditabilidade suficientes para reconstruir com qualidade de produção uma
personagem de `64–68 px`.

O executável confirmou apenas opções de sistema do Godot. A documentação
oficial descreve uma CLI para inspeção/exportação de projetos existentes e uma
API de extensões carregada dentro da aplicação; nenhuma delas fornece neste
setup um canal comprovado para autorar o desenho. Por isso não foram criados
PNG, PXO, preview ou frames adicionais, e runtime/gameplay permaneceram
inalterados.

Próximo passo único: expor a janela nativa do Pixelorama a um canal de controlo
com precisão de canvas e layers, e então repetir este piloto de um só sprite.

Follow-up de extração: a folha correta
`Koliani_1.0_Master_Package_v2/references/approved/01_KOLIANI_VISUAL_AUTHORITY_v1_1.png`
é um PNG legível de `1536×1024`, mas está em modo `RGB`, sem canal alpha. As
poses estão compostas sobre painéis/fundos opacos. A extração parou sem criar
recortes ou contact sheet, porque isolar personagens com transparência exigiria
remoção/reconstrução de fundo em vez de simples crop lossless.

## Execution 5D.2 — Reconstrução limpa de sprites de produção

Estado: **MASTER TECHNICAL PASS / HUMAN VISUAL REVIEW REQUIRED**. Foi criado
um master novo em `assets/sprites/koliani_production/master/`, gerado de raiz
por `tools/generate_koliani_master.py`, sem recortar ou limpar as pranchas
aprovadas. O PNG passa o gate técnico: `160×96`, RGBA, alpha estritamente
`0/255`, altura visual `66 px`, pivot `(80,90)`, pés em `Y=90`, orientação à
direita e ausência de VFX/fundo residual.

A tentativa built-in de geração visual produziu novamente RGB sem alpha e
checkerboard incorporado; não entrou no projeto. O master final tem fonte
determinística editável. Contrato, pastas dos 40 frames e sete famílias de VFX
separadas ficaram preparados, e `tools/validate_koliani_production.py` mantém
o lote em `PENDING 0/40` e impede strips antes de `40/40 PASS`. Gameplay,
cenas e runtime não foram alterados.

Próximo passo único: revisão visual humana do master. Se aprovado, produzir os
40 frames base mantendo identidade, cabelo, escala, pivot e baseline; só após
o gate completo montar strips e avaliar integração. Relatório:
[execution_5d_2_sprite_production.md](execution_5d_2_sprite_production.md).

## Execution 5D.1 — Native Locomotion Asset Production

Estado: **IMAGE GENERATION CAPABILITY REQUIRED**. A capacidade `imagegen`
disponível foi testada com a autoridade visual `01` e a referência de pose
`05`. Produziu uma linha coerente de 10 poses Idle, mas os dois outputs — a
geração original e uma iteração explícita de extração de fundo — foram PNG
`RGB` de `1983×793`, sem canal alpha e com checkerboard incorporado.

O contrato exige frames nativos `160×96` em RGBA com alpha 0 real e proíbe
remoção de fundo contaminado ou conversão de pranchas em falso asset. Por
isso, nenhum PNG foi copiado para o projeto, as restantes 30 poses não foram
geradas e runtime, cenas, gameplay e integração permaneceram inalterados.

Próximo passo único: executar o brief 5D.1 numa ferramenta de produção que
garanta exports RGBA nativos com transparência real e controlo de frames,
submetendo depois os 40 frames e seis strips ao gate técnico e à revisão
visual humana.

## Execution 5D — Production Asset Gate

Estado: **ART ASSET REQUIRED**. A inspeção técnica e visual direta das
referências aprovadas `01`–`07` confirmou que são pranchas de autoridade, não
assets de produção seguros. `01`–`04` são RGB sem alpha; `05` e `07` têm alpha
global anómalo sem qualquer píxel totalmente opaco, e `07` nem sequer contém
alpha 0; `06` tem áreas transparentes, mas preserva cabeçalhos, barras,
números, linhas e VFX numa única composição e não mantém de forma segura a
identidade/cabelo da autoridade `01`.

Idle, Run, Jump Start, Jump Loop, Fall e Land ficaram todos classificados
`REFERENCE_ONLY`. Não houve extração, criação de assets, integração, testes de
runtime ou alteração de gameplay. O relatório e a especificação dos seis
exports RGBA necessários estão em
[execution_5d_asset_gate.md](execution_5d_asset_gate.md).

Próximo passo único: produzir os seis strips RGBA nativos conforme essa
especificação e repetir o asset gate antes de tocar no runtime.

## Master Package v2 — verificação documental

Estado: **PASS WITH DOC FIXES**. O pacote
`Koliani_1.0_Master_Package_v2/` está instalado ao lado de `project.godot` com
README, instruções de instalação, regras de agente, 17 documentos de design e
dois manifestos de referências. Os 12 PNGs esperados estão presentes em
`references/approved/`, abrem como PNG e os SHA-256 correspondem integralmente
a `references/manifest.json`.

O pacote é Source of Truth para produto/design aprovado; código, testes e
documentação operacional local continuam a vencer para implementação. A
autoridade de personagem está explícita: Koliani tem 16 anos, proporções
atléticas não chibi, cabelo longo completamente solto com raízes pretas e
pontas vermelhas, roupa black/charcoal com vermelho e assinatura violeta da
Shadowblade. A precedência é `01`–`06`; `07` vale apenas para VFX, e figuras
incidentais dos Production Packs não a substituem.

Foi corrigido `docs/master_package_integration.md`, que ainda descrevia o
pacote anterior e referências aprovadas ausentes. As referências v2 são
**APPROVED DESIGN**, não assets production-ready; readiness técnica não foi
avaliada nesta execução. Runtime, cenas, gameplay, imagens e assets não foram
alterados.

Próxima execução, com Luna Medium: fazer um asset gate técnico das referências
`01`–`07`; provar por frame origem, alpha real, dimensões, grelha, baseline,
pivot, separação personagem/VFX e fidelidade à autoridade `01`; parar como
`ART ASSET REQUIRED` se não existirem fontes RGBA separáveis. Só após PASS,
produzir um lote reversível de idle/run/jump/fall/land, validá-lo e integrá-lo
exclusivamente no Level 1 sem alterar gameplay, colisões, hitboxes, movimento,
câmara, save ou progressão; terminar com testes direcionados, suite completa,
captura em renderer real e `HUMAN PLAYTEST REQUIRED`.

## Asset Production Pilot v1.1 — Movement Core

Estado: **ASSET PRODUCTION REQUIRED**. A auditoria conservadora encontrou 16
frames candidatos para idle, run, jump, fall e land, mas nenhum cumpre o
contrato v1.1. A folha `koliani_premium_v1_sheet.png` e as duas referências de
branding não têm alpha real; a folha tem checkerboard incorporado e apresenta
cabelo preso/ponytail. Os strips RGBA existentes foram derivados por remoção
automática desse fundo, `run` inclui poeira colada e `aterrar` reutiliza poses
de fallback em vez de um export dedicado.

`asset_contract_v1_1.json` regista fontes, grelha e falhas semânticas;
`tools/validate_assets.py` mede formato, modo, alpha, dimensões, bounding box,
baseline e pivot por frame. Relatório: `work/koliani_asset_pilot_report.json`,
com 0 PASS e 16 FAIL. Nenhum frame foi copiado para
`assets/sprites/koliani_v1_1/pilot/` e nenhuma referência original foi
alterada.

Próximo passo seguro: produzir exports RGBA nativos de idle, run, jump, fall e
land, com cabelo longo completamente solto, identidade consistente, alpha 0
real, personagem separada de VFX e grelha/pivot documentados; depois repetir o
validator antes de qualquer integração no runtime.

## Onde está o projeto

- Execution 1A: **DONE / PASS**.
- Execution 1A.1: **DONE / PASS**.
- Execution 1B: **DONE / PASS**.
- Execution 1C: **DONE / PASS**.
- Execution 2: **DONE / PASS**.
- Execution 3A: **DONE / PASS** — Save Foundation.
- Execution 3B: **DONE / PASS** — Stable Progression IDs.
- Execution 3C: **DONE / PASS** — Level Session + Checkpoint State.
- Execution 3D: **DONE / PASS** — Legacy Save / State Cleanup; schema v5.
- Execution 4A: **TECHNICAL PASS / HUMAN PLAYTEST REQUIRED** — primeiro passe
  de Movement + Camera; os parâmetros ainda não são finais.
- Execution 4B: **HUMAN-APPROVED** — transições da câmara aprovadas.
- Execution 5B: **TECHNICAL PASS / HUMAN PLAYTEST REQUIRED** — prototype
  Premium Pixel Art da Koliani, isolado ao Level 1.
- Execution 5C: **TECHNICAL PASS / HUMAN VISUAL REVIEW REQUIRED** — target
  Hybrid Cinematic de dois ecrãs no início do Level 1.

Baseline confirmado: 74 testes, 0 falhas, localização PASS, manifesto com 100
níveis/20 regiões PASS, 100 cenas carregáveis, jornadas PASS e geradores de
cena/atmosfera não destrutivos por defeito. O nível 12 em Safari/PWA num
iPhone continua **DEVICE VALIDATION REQUIRED**.

## Region I Production Art Kit R1.1 — infraestrutura

Estado: **PASS**. Foi criada a estrutura isolada
`assets/art/regions/region_01_forest/production/`, com pastas para terrain,
overlays, props, backgrounds, vfx e fontes. O manifest v1 fixa 12 stable IDs,
grid de 32 px, dimensões, alpha, repetição, nearest filter, uso e estado.

`tools/validate_region_artkit.py` usa apenas a biblioteca standard e valida
manifest, paths/naming, IDs duplicados, estrutura/CRC/IDAT de PNG, dimensões,
grid e alpha. Validação final: `WARNING` controlado, exit code 0, 12 esperados,
0 presentes, 12 missing, 0 fails; compilação Python, JSON e `git diff --check`
PASS. Um PNG real existente também foi aceite pelo leitor técnico.

Nenhum PNG final foi criado, nenhum asset foi integrado e cenas, TileMaps,
gameplay e `Region1HybridVisualTarget` permaneceram intocados nesta execução.
Próximo passo seguro: produzir e inserir o primeiro lote de PNGs reais
aprovados, antes de qualquer integração no Level 1.

## Execution 5C — retoma

O target Hybrid Cinematic está ativo apenas em `Floresta_Putrefata.tscn`, no
intervalo aproximado `x=-300..1250`. O módulo
`Region1HybridVisualTarget.tscn` acrescenta background/midground/foreground,
Heart Tree distante, revestimento visual natural sobre as quatro primeiras
superfícies, vegetação, névoa, 34 partículas, três luzes seletivas, uma amostra
de corrupção e uma assinatura de ataque Shadowblade. Não contém nós físicos.

A skin dark-fantasy das barras do HUD é aplicada e restaurada pelo próprio
módulo; não altera valores, sinais ou visibilidade lógica. `ativo = false` na
instância do Level 1 é o rollback: a validação provou que, nesse estado, o
módulo fica invisível e não monta filhos.

Validação 5C: targeted/rollback PASS; prototype 5B PASS; Movement/Camera PASS;
Level 1 com 20 plataformas e porta alcançável PASS; smoke e duas capturas
Forward Mobile reais PASS; suite completa 74/74; localização 701×6 preservada;
`git diff --check` PASS. Capturas em
`work/execution_5c/region1_hybrid_{idle,attack}.png`.

Orçamento medido: 406 nós no módulo, três `PointLight2D` e um
`CPUParticles2D` com 34 partículas. As luzes e partículas são contidas, mas os
CanvasItems precisam de profiling em Web/mobile antes de reutilizar o padrão.
Qualidade estética e salto geracional: **HUMAN VISUAL REVIEW REQUIRED**.

## Execution 5B — retoma

A direção visual aprovada fica registada como **HYBRID CINEMATIC 2D**:
personagens/inimigos/bosses em Premium Pixel Art, ambientes com apresentação
cinematográfica por camadas e UI dark-fantasy minimal. Nesta execução só a
Koliani foi trabalhada.

O prototype `koliani_premium_v1` usa células 160×96, escala 0,75, altura
visual aproximada de 59 px e pés em y=22. Traz idle 4, run 5, jump 3, fall 2,
dash 3, basic attack 6, hurt 2 e death 5; estados restantes usam fallbacks do
mesmo visual. A propriedade `usar_prototipo_premium` está ativa apenas na
Koliani de `Floresta_Putrefata.tscn`; o rig Shadowblade anterior continua a
ser o default e o rollback é desligar essa propriedade.

Validação: targeted 5B PASS, smoke Level 1 PASS, Movement/Camera PASS, suite
completa 74/74, localização 701×6 PASS, captura OpenGL real e `git diff
--check` PASS. Build:
`build/windows/Koliani-Execution-5B-Hybrid-Character-dev.exe`.

O fluxo de morte não mudou e pode interromper a animação visual de death.
Qualidade, legibilidade e feel finais: **HUMAN PLAYTEST REQUIRED**.

## O que acabou de ser feito

A Execution 3D removeu Hardcore do runtime e do schema atual. O schema v5 não
grava nem aceita `hardcore`/`hardcore_tempo_restante`; schemas v0–v4 continuam
reconhecidos e a migration v4→v5 descarta apenas esses campos, sem reativar a
feature e sem perder campanha, level session, bosses ou recompensas.

Checkpoint por coordenadas continua restrito a v0–v3 e é convertido pela
migration v3→v4; v5 grava apenas `level_session`. Identidades legacy de
progressão continuam apenas nas migrations e stable IDs permanecem canónicos.

Validação 3D: Save Foundation 11/11, Level Session 11/11, Progression IDs 6/6,
Movement/Camera targeted PASS, suite completa 74/74, localização 701×6 PASS e
`git diff --check` PASS. Movement/Camera: **HUMAN-APPROVED PARAMETERS
UNCHANGED**.

## Baseline da Execution 3C

A Execution 3C elevou o schema a v4 e separou `level_session` da progressão
permanente. A sessão guarda apenas `level_id` e `checkpoint_id`; coordenadas
são resolvidas pela cena em runtime e nunca representam arbitrary frame save.
O lifecycle begin/activate/recover/complete/abandon ficou explícito. IDs usam
`checkpoint_<level_id>_<ordem>` e o spawn seguro `_start`; sessão inválida
converge para `_start` sem perder campanha.

Morte/reload reconstrói a cena e repõe Koliani no último checkpoint seguro.
Fechar/reabrir retoma esse checkpoint; sair deliberadamente para mapa/menu
abandona a sessão. Concluir regista progressão permanente e limpa a sessão.
Bosses derrotados não reaparecem após reload; baús já reclamados continuam
idempotentes.

Validação 3C: 10 targeted PASS; L5 nos cinco checkpoints com
activation/death/reload/movement/jump PASS; boss/reward runtime PASS;
migrations, backup e future version PASS; L1/L5/L12/L31 PASS; regressões
3A/3B/Movement+Camera PASS; suite completa 74/74; localização 701×6 PASS;
`git diff --check` PASS. Movement/Camera: **HUMAN-APPROVED PARAMETERS
UNCHANGED**.

## Baseline Movement + Camera

A Execution 4B respondeu ao playtest da 4A sem alterar movement. A confirmação
da troca de direção horizontal passou de 0,10 s para 0,14 s e a resposta do
look-ahead de 5,8 para 3,8. Na vertical, a resposta passou de 8,5 para 5,0 e o
fall framing passou a exigir progressão conjunta de distância e velocidade,
eliminando o salto de alvo quando apenas um dos sinais já estava alto.
Distância de look-ahead, deadzone, limiares e visibilidade inferior foram
preservados.

Validação 4B: targeted Movement + Camera PASS; regressão de movement PASS;
smoke L1 PASS (run/jump/dash); smoke L5 PASS; cenário de queda e recenter PASS;
suite completa PASS, 0 falhas; `git diff --check` PASS. Build dev:
`build/windows/Koliani-Execution-4B-dev.exe`.

Os parâmetros foram posteriormente **HUMAN-APPROVED**. A 3C não os alterou.

## Baseline da Execution 4A

A Execution 4A centralizou aceleração, desaceleração e resposta de viragem,
deu à queda uma gravidade ligeiramente superior à subida e formalizou
aterragens light/medium/heavy sem input lock. A câmara ganhou look-ahead
horizontal com histerese, deadzone para hops, antecipação progressiva de
quedas e níveis de tremor Full/Reduced/Off. Dash, input, parede, gancho,
checkpoint e reload mantiveram os contratos existentes.

Validação: targeted Movement + Camera PASS; L1/L5/L12/L31 smoke PASS; ciclo
dos cinco checkpoints ativos do L5 com morte/reload/saída/salto PASS; atores e
gancho PASS; 100/100 cenas carregáveis; suite completa e localização PASS;
`git diff --check` PASS. Build dev:
`build/windows/Koliani-Execution-4A-dev.exe`.

**HUMAN PLAYTEST REQUIRED** para aceitar ou reafinar feel, distâncias,
resposta, tiers e conforto da câmara. Não iniciar 4B/4C antes dessa decisão.

## Baseline persistente anterior

A Execution 3B elevou o schema a v3 e acrescentou a migration sequencial
v2 → v3. O save atual usa IDs estáveis para nível atual/concluídos, bosses,
abilities, pistas/collectibles e recompensas únicas de baú. Níveis e bosses
reutilizam o manifesto da Execution 2; abilities têm mapping central e pistas
reutilizam o catálogo existente. Operações set-like são idempotentes e o baú
de boss não volta a atribuir recompensa após reload. Saves v2 preservam a
progressão equivalente; referências legacy desconhecidas são recusadas em vez
de adivinhadas. TEMP, backup/recovery, Hardcore e checkpoint mantêm a semântica
da 3A.

## O que vem a seguir

1. Revisão humana das duas capturas e do target 5C no Level 1: salto visual,
   leitura da Koliani, profundidade, corrupção/Shadowblade e HUD.
2. Manter pendente a validação do nível 12 num iPhone real com Safari/PWA.
3. Não escalar o estilo, otimizar em massa, alterar outros níveis ou iniciar a
   execução seguinte antes da decisão humana.

## Fonte canónica

- Visão e scope 1.0: [visao_koliani_1_0.md](visao_koliani_1_0.md)
- Decisões: [decisoes.md](decisoes.md)
- Estado das execuções: [execution_dashboard.md](execution_dashboard.md)
- Riscos e dívida: [backlog_tecnico.md](backlog_tecnico.md)
- Regras de agentes: [AGENTS.md](../AGENTS.md)

A auditoria de Execution 0 é evidência histórica, não o estado operacional
atual. Não repetir auditorias completas nesta retoma.
