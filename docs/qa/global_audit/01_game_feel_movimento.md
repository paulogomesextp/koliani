# 01 — Game Feel & Movimento (Agente A1)

Auditoria global, modo diagnóstico. Data: 25 set 2026. HEAD auditado: `bcac9fde`.
Nada no jogo foi alterado. Harnesses próprios em
`C:\Users\paulo\AppData\Local\Temp\claude\C--Projetos-koliani-master\1f7fd79c-0d59-4214-880e-bc6366d65cd5\scratchpad\a1\`
(`a1_mov.gd`, `a1_mov2.gd`, `a1_dbg.gd`, `a1_cam.gd`, `a1_strip.gd` + JSON por frame), todos
corridos pelo wrapper `godot_sandbox.sh`, com APPDATA isolado.

## Pergunta principal: dá gozo mover a Koliani sem inimigos?

**Ainda não.** A base é **correta mas inerte**. O input responde sem atraso e a
aceleração é seca (bom), mas:

- o salto é curto para o corpo que ela tem;
- o corte do salto trava de repente, como um tecto invisível;
- em N1–N4 há poucos verbos (correr, saltar, rolar);
- as transições que dão peso (aterrar, travar, virar, subir o rebordo) ou não se veem ou são
  montadas com frames de outras animações, incluindo frames legados.

Mover-se não tem ritmo próprio. Não há momentum, nem técnica de velocidade, nem uma
recompensa por encadear ações. O único jeito de ir mais depressa que a correr é abusar do
rolamento (medido abaixo), e isso é um defeito, não uma técnica.

## Método

- Arena própria criada **em runtime** a x = −30000, longe da geometria do nível: chão plano,
  plataforma alta com borda, parede de 1000 px, degraus de 60/100/140 px. O input é injetado
  com `Input.action_press/release` e cada tick de física fica registado (pos, vel, chão,
  parede, animação, frame, i-frames, `time_scale`, offset da câmara).
- Os mesmos testes foram corridos em **N1 Floresta Putrefata** (Região I, `usar_golden_set`),
  **N13 Torre da Tempestade** e **N56 Distrito das Engrenagens**.
- Percurso real no N1 com janela (`--window --screen 1`) para medir a câmara, mais tiras de
  frames recortadas do ecrã.
- A física corre a 60 Hz (`Engine.physics_ticks_per_second` = 60). Unidade de normalização:
  **H** = 65 px de altura visual (bbox alfa de `idle_001.png`, 39→104) e **hb** = 44 px de
  hitbox (`Koliani.tscn`, `RectangleShape2D_body` 20×44).
- Artefacto conhecido: no harness, as ações `just_pressed` (saltar, rolar, dash) chegam
  1 tick depois. Os números abaixo já o descontam.

## Números medidos (RUNTIME VERIFIED, iguais nos 3 níveis)

| Parâmetro | Koliani (medido) | Normalizado | Celeste (Player.cs, aprox.) | Leitura |
|---|---|---|---|---|
| Velocidade máx. a correr | 240 px/s | 3,7 H/s · 5,5 hb/s | 90 px/s = 8,2 hb/s | lenta para o tamanho dela |
| 0 → máx. | 7 ticks (0,11 s) | — | ~0,09 s | ✔ seco |
| Travagem máx. → 0 | 7 ticks, desliza 11 px | — | ~0,09 s | ✔ |
| Viragem +240 → −240 | 11 ticks (0,18 s) | — | ~0,18 s | ✔ |
| Latência mover → vx≠0 | 0 ticks | — | 0 | ✔ |
| Altura do salto (segurado) | **82,9 px** | **1,3 H · 1,9 hb** | ~2,5 hb | **curto** |
| Subida / descida / tempo no ar | 21 / 19 ticks · 0,67 s | — | ~0,55–0,6 s | ok |
| Comprimento do salto a correr | **160 px** | **2,5 H · 3,6 hb** | ~4,9 hb | **curto** |
| Salto variável (ticks segurados → altura) | 1→5,5 · 2→13 · 3→20 · 5→33 · 8→50 · 12→67 · 16→78 · 20→83 px | — | corte suave | **corte abrupto** |
| Apex | sem meia-gravidade; gravidade ×1,22 a cair | — | meia-gravidade se \|vy\|<40 | falta hang time |
| Queda máx. | **1100 px/s**, atingida em 39 ticks | 17 H/s · **2,1 ecrãs/s** | 160 px/s ≈ 0,9 ecrãs/s | **queda às cegas** |
| Coyote efetivo | **4 ticks** (5 falha) ≈ 0,07 s | — | 0,1 s | um pouco curto |
| Buffer de salto | **7 ticks** (8 falha) ≈ 0,12 s | — | 0,08 s | ✔ generoso |
| Controlo no ar (+240 → −240) | 18 ticks (0,3 s) | — | AirMult 0,65 | ✔ |
| Rolamento | 360 px/s × 0,30 s → **140 px**; i-frames = duração toda; recarga 0,45 s | 2,2 H | — | ver abuso |
| Rolar sem parar (3 s) | 7 rolamentos, **907 px = 302 px/s**, 66 % do tempo invulnerável | — | — | **mais rápido que correr** |
| Dash (hab. `dash`, N5+) | 620 px/s × 0,16 s → **186 px** a partir de parado (≈100 de dash + 85 a deslizar); recarga 0,55 s; i-frames 10 ticks | 2,9 H | 240×0,15 s, 8 direções, 1 por salto | só na horizontal |
| Dash aéreo | vy = 0 durante o dash; **com ↑ premido continua horizontal**; sem limite por salto (só a recarga) | — | 1 por salto, 8 direções | não é um verbo de traversal |
| Salto duplo | +155 px no total | 2,4 H | — | ✔ |
| Parede (`escalar_paredes`) | desliza a 55 px/s; wall-jump (−330, −430) | — | — | ✔ |
| Wall-kick básico (sem habilidade) | só com a direção **para dentro** da parede **e** saltar no mesmo tick; sem pose de parede (anim `jump_loop`/`fall`); sem coyote de parede | — | 3 px de tolerância, sem segurar | **escondido e rígido** |
| Agarrar a borda | apanha rebordos de 100 e **140 px** (acima do salto) | — | — | ✔ assistência útil… |
| …mas | **agarra sozinha** a cair perto de qualquer lábio e **fica pendurada com → premido**; só sobe com saltar/↑ | — | Dead Cells sobe sozinho ao segurar a direção | **encrava o fluxo** |
| Knockback ao levar dano | **nenhum**: vx = 240 mantém-se, vy = 0, anim `hurt` 14 ticks, i-frames 0,6 s | — | HK/DC empurram | **o dano não se sente no corpo** |
| Hit-stop | `HITSTOP_GOLPE` 0,010 s, `DANO` 0,020 s em tempo real (< 1–1,2 ticks a 60 Hz) | — | DC ~3–6 frames | STATIC ONLY: sub-frame |

Os três níveis dão **exatamente** os mesmos números (altura 82,9 / 160 px / 1100 / dash 185,6 /
coyote 4 / buffer 7). O modelo de movimento é **único e global**, não há divergência entre
níveis; as variações vêm só das zonas (gelo, gravidade, vento, planar).

## Causas-raiz

### RC1 — As animações de locomoção não têm dono: um observador visual desfasado da física e montado com frames emprestados (P0 · PARTIAL REWORK)

`_atualizar_anim()` corre em `_process` e **deduz** a animação a partir de flags e
temporizadores que o `_physics_process` escreve noutro instante
(`scripts/koliani.gd:1785-1891`). Com o Golden Set, as transições são **derivadas** de outras
tiras (`scripts/koliani.gd:915-933`). Sintomas medidos:

1. **A aterragem não se vê.** A animação `land` dura **1 frame de render** e depois cai para
   `idle`/`run`. Isto foi provado frame a frame (`a1_dbg.gd`): `pf 248 anim=land, at=0.0` →
   `pf 249 anim=idle`.
   - Causa: `_aterrar_t` só é armado no **tick seguinte** (`koliani.gd:1338-1343` lê
     `is_on_floor()` do tick anterior), enquanto a flag `_piloto_5g_no_ar` é consumida já no
     primeiro `_process` (`koliani.gd:1868-1873`). A condição de continuação exige
     `_aterrar_t > 0`, e isso falha exatamente nesse frame.
   - Nos 9 saltos testados e no percurso real do N1, `land` **nunca** aparece num tick de física.
   - Em 165 Hz o frame dura 6 ms.
   - Resultado: todas as aterragens, até as de 1100 px/s (tier 3), leem-se sem peso. Só
     sobram o tremor e o som.
2. **A travagem acontece depois de ela já estar parada.** A física pára em 7 ticks. A anim
   `run_brake` (6 frames a 20 fps) toca **mais 18 ticks (0,3 s) com vx = 0**: uma derrapagem
   no sítio.
3. **A travagem usa frames LEGADOS.** `run_brake` é montado a partir de `run` **antes** de o
   `run_final` o substituir (`koliani.gd:915-917` vs `926-929`). A pasta `run_native` não
   tem PNGs, por isso fica o `run` golden antigo.
   - Na tira `img/a1/strip_chao_arranque_travagem_viragem.png` (linha 2) vê-se a silhueta a
     mudar de proporção e de cor ao travar.
   - O commit `15796dd8` limpou o `run_start` legado, mas **o `run_brake` continua legado**.
   - Os pés do `run_final` estão em y = 106 e os do `idle` em y = 104: salto de 2 px na
     transição.
4. **A viragem não é uma viragem.** `turn` = frames 0–3 do `run`, com flip instantâneo.
   - A meio aparece **1 tick de `run_brake`** (vx passa por 0; `viragem` idx 3), um pop
     visível na tira (linha 3, célula 4).
   - Depois o ciclo `run` recomeça do frame 0 com `speed_scale` 0,55, e a mesma pose fica
     ~6 ticks parada no arranque (tira, linha 1).
5. **O `jump_start` (4 frames, 0,33 s) estica-se por toda a subida**, e o `jump_loop`
   aparece durante 1 tick no apex. Na prática, o salto tem 2 poses.
6. **Subir ao rebordo não tem animação**: é um impulso de (150, −430) com a pose `jump_loop`
   (`koliani.gd:1457-1464`, tira `strip_ar_rolar_borda.png`, linha 6).
7. Há **seis sistemas de rig** vivos no mesmo script (`_KOLI_ANIMS`, `_GOTHIC`, `_CAVALEIRO`,
   `_SHADOW`, `_PREMIUM`, `_PILOTO_5G`, `_NOVA`, `_GOLDEN`; `koliani.gd:526-730`). Os 100
   níveis têm `usar_golden_set = true` **e** `usar_prototipo_premium = true`. O caminho de
   locomoção golden reutiliza a máquina "piloto 5G" (`_anim_locomocao_piloto_5g`).
   - A dívida é de estrutura, não de parâmetros: cada correção é um remendo sobre a seleção
     derivada.

**Oportunidade KOLIANI:** a arte golden (roll, djump, dash) é boa quando existe. Se houver
uma máquina de estados explícita no tick de física, com duração mínima por estado, e o
pedido dos 4 frames que faltam (land, brake, turn, mantle) no contrato golden, a Koliani
ganha peso sem mexer num único número de física.

### RC2 — Os números estão afinados isoladamente, não em relação ao corpo nem ao ecrã (P0 · TUNE)

- **O salto é baixo para a personagem.** 1,3 H de altura e 2,5 H de comprimento. A Koliani
  é desenhada alta, com 65 px de arte para 44 px de hitbox, e salta como uma personagem
  atarracada. É por isso que ela "pesa" sem ser "poderosa".
- **O corte do salto é um travão.** `Movimento.CORTE_SALTO = 0.45` é aplicado **em cada
  tick** enquanto ela sobe sem o botão premido (`scripts/movimento.gd:116-117`).
  - Largar o botão tira ~55 % da velocidade vertical por tick: de −400 para ~−35 em
    3 ticks. Equivale a ~5× a gravidade.
  - Não há meia-gravidade no apex.
  - Em toque, um tap de 80–130 ms (5–8 ticks) dá **33–50 px**, 40–60 % do salto. Isto casa
    com a nota do briefing ("taps curtos = salto baixo").
- **Queda a 1100 px/s = 2,1 ecrãs por segundo.** A câmara só antecipa +65 px para baixo
  (`LOOK_QUEDA_Y 92`, amortecido; medido `cam_c.y` ≈ 61–66 px em queda máxima). Em queda
  máxima, o que está por baixo aparece ~0,3 s antes do impacto.
- **O coyote efetivo é de 4 ticks** para os 0,10 s nominais. Isto vem da ordem entre o
  decremento e a regra "perde o salto do chão" (`movimento.gd:66-97`). É um aperto pequeno,
  mas soma-se ao corte abrupto.

**Oportunidade:**

- subir a altura para ~2 H;
- trocar o corte multiplicativo por tick por um corte único (ou gravidade ×2–3 ao largar);
- meia-gravidade no apex;
- teto de queda ~650–750 px/s, ou uma queda rápida opcional com ↓;
- mais antecipação vertical da câmara.

São constantes centralizadas em `Movimento`: a afinação é barata, mas **tem de ser validada
contra a geometria** dos níveis (ver RC3).

### RC3 — O conjunto de verbos de traversal é raso, escondido e com incoerências que se exploram (P1 · PARTIAL REWORK)

- **N1–N4 = correr, saltar, rolar.** `HABILIDADES_INICIAIS = []` (`estado_jogo.gd:43`); o
  dash chega no N5 (`Coracao_da_Floresta.tscn:238`) e o salto duplo com o chefe do N5
  (`nivel_com_chefe.gd:215`). A Região I, a que o GM diz estar mais perto do aprovado, é
  justamente a que tem menos movimento.
- **O wall-kick básico existe mas é invisível e rígido** (`koliani.gd:1478-1493`):
  - exige a direção para dentro da parede e o salto no mesmo tick;
  - `saltar` encostada sem direção não faz nada (`parede_sem_direcao`);
  - não tem pose de parede.
- **Agarrar a borda de forma automática encrava o fluxo.** No percurso real do N1 ela
  agarrou **três rebordos sem ninguém pedir**, a correr ou a cair. Ficou pendurada 60+ ticks
  com → premido (`cam_l1.json`, idx 210, 245, 432). O lado do agarrão vem de
  `_olha_para` quando não há direção (`koliani.gd:1441`), e subir exige saltar/↑.
- **O dash é só horizontal e não tem limite aéreo.** `velocity.x = _olha_para * VEL_DASH`
  (`koliani.gd:1545`) ignora ↑/↓, e não há contador de dashes no ar. A recarga de 0,55 s
  permite vários dashes por queda.
- **O rolamento vale mais que correr.** Encadeado dá 302 px/s contra 240 a correr, com 66 %
  de invulnerabilidade (`rolar_spam`). O dash encadeado dá 337 px/s. A forma ótima de viajar
  acaba por ser rolar sem parar.
- **O dano não mexe no corpo.** `receber_dano` ignora `dir_empurrao` a não ser para o escudo
  (`koliani.gd:2704-2730`); não há nenhum `aplicar_impulso` vindo de inimigos (grep). O
  `hurt` não interrompe a corrida.
- **O verificador de alcance não corresponde ao início da campanha.**
  `tools/verifica_alcance.gd:20-21` assume vão ≤ 210 px e subida ≤ 118 px ("salto + duplo").
  No N1–N4 o alcance real é 160 px na horizontal e 83 px de subida (140 px com o agarrão).
  Os níveis sem salto duplo são validados com um corpo que ainda não existe.

**Oportunidade KOLIANI:** a identidade dela já aponta para uma acrobata gótica (a arte do
roll/djump/dash é a melhor do pacote).

- Um **dash de 8 direções, 1 por salto, recarregado no chão**.
- O **pogo** que já existe no código.
- O **wall-kick ensinado no N1**.
- O agarrão **a subir sozinho quando se segura a direção**.

Com isto, a Região I passa de "andar e saltar" para uma curva ensinar→combinar à Celeste /
Lost Crown, sem copiar ninguém.

### RC4 — A velocidade tem duas fontes de verdade (P1 · PARTIAL REWORK)

`Movimento.passo()` parte de `_mov.velocidade` e reescreve `velocity`; `_mov` só é
sincronizado depois de `move_and_slide` (`koliani.gd:1590-1600, 1707-1708`). **Qualquer
sistema que escreva `velocity` diretamente é descartado no tick seguinte.**

- Provado em runtime: somar +20 px/s a `velocity.x` em cada um de 60 ticks deixa-a **0 px
  mais longe** (`velocity_externa`).
- O `scripts/iman.gd:107-112` faz exatamente isso.
- O `aplicar_impulso` + `_impulso_externo_t` (`koliani.gd:2488-2504`) é o remendo documentado
  para o trampolim, porque o corte de salto também comia os impulsos.
- Os estados rolar, dash, parede, borda e defesa escrevem cada um `velocity` à sua maneira.

É uma armadilha estrutural: cada mecânica nova (vento, íman, portal, plataformas) tem de
descobrir o truque, ou falha em silêncio.

**Ação:** um único dono da velocidade e um acumulador de forças externas (o
`aplicar_forca_externa` já existe em `movimento.gd:143`, mas só serve o vento).

### RC5 — Câmara correta mas passiva, e leitura fraca da personagem (P2 · TUNE)

**O que já está bem:**

- sem smoothing nativo, de propósito, por causa do jitter a 165 Hz (medido na 9H.13/14;
  `camera_tremor.gd:31-65`);
- look-ahead horizontal de 112 px, que chega ao alvo em ~1 s (`LOOK_AHEAD_RESPOSTA 3.8`;
  medido 25 → 111 px entre os ticks 42 e 126 do percurso);
- deadzone vertical de 68 px, que funciona (os hops não arrastam a vista).

**O que falta:**

- não há antecipação para cima nem framing de plataforma alvo;
- a antecipação em queda é insuficiente (RC2);
- a vista mostra 914×514 px de mundo (zoom 1,4) e a Koliani ocupa ~12,6 % da altura do
  ecrã, o que é bom;
- mas **o contraste é fraco**: um corpo escuro, vermelho e roxo sobre um fundo roxo-escuro
  (`img/a1/l1_01_corrida_lookahead.png`, `l1_03_viragem_30f.png`). Parado ou em queda perto
  de decoração, ela desaparece. Isto é tanto um problema de feel (ler o próprio corpo) como
  de arte.

Aviso do motor em todos os runs: *"Camera2D overridden to physics process mode due to use of
physics interpolation"*. O offset é escrito em `_process` (`camera_tremor.gd:185-201`) sobre
uma câmara que corre na física. Isto não foi reavaliado aqui (STATIC ONLY), mas é a mesma
família de mistura de relógios que a 9H.13 descreveu.

## Classificação por elemento

| Elemento | Veredito | Prioridade | Evidência |
|---|---|---|---|
| Aceleração / travagem / viragem (física) | **KEEP** | — | 7/7/11 ticks, 0 de latência |
| Velocidade máx. 240 | **TUNE** (↑ ou dar um estado de sprint/momentum) | P1 | 5,5 hb/s contra 8,2 do Celeste |
| Altura/comprimento do salto | **TUNE** | P0 | 1,3 H / 2,5 H |
| Corte de salto por tick | **REWORK** (corte único + apex) | P0 | tabela do salto variável |
| Gravidade / queda máx. 1100 | **TUNE** | P1 | 2,1 ecrãs/s |
| Coyote | **TUNE** (6 ticks efetivos) | P2 | 4 ticks |
| Jump buffer | **KEEP** | — | 7 ticks |
| Controlo no ar | **KEEP** | — | 0,3 s de inversão |
| Aterragem (anim) | **REWORK** (bug de fase + arte) | P0 | 1 frame de render |
| Travagem (anim) | **REWORK** (frames legados, 0,3 s parada) | P0 | tira linha 2 |
| Viragem (anim) | **REWORK** (pose própria, sem pop do brake) | P1 | tira linha 3 |
| Idle → run | **TUNE** (1.ª pose presa ~6 ticks com cadência 0,55) | P2 | tira linha 1 |
| Rolamento | **TUNE** (recarga/i-frames, não pode bater a corrida) | P1 | 302 px/s |
| Dash | **PARTIAL REWORK** (8 direções, 1 no ar, fim de velocidade limitado) | P1 | `dash_aereo_cima` |
| Salto duplo | **KEEP** | — | +155 px |
| Wall slide/jump (`escalar_paredes`) | **KEEP** | — | 55 px/s |
| Wall-kick básico | **REWORK** (tolerância, pose, ensinar) | P1 | `parede_*` |
| Agarrar a borda | **TUNE** (só com direção para dentro; sobe sozinho ao segurar) + anim de mantle | P1 | 3 agarrões não pedidos no N1 |
| Knockback | **REWORK** (não existe) | P1 | `dano_knockback` |
| Hit-stop | **TUNE** (sub-frame) — ver o agente de combate | P2 | STATIC |
| Câmara horizontal | **KEEP** | — | percurso N1 |
| Câmara vertical / queda | **TUNE** | P2 | cam_c.y ≤ 66 |
| Duas fontes de velocidade | **PARTIAL REWORK** | P1 | `velocity_externa` |
| Rigs legados no `koliani.gd` | **REMOVE** (depois da RC1) | P2 | `koliani.gd:526-730` |

## Pontos fortes a preservar

- O módulo `Movimento` é puro e testável (`scripts/movimento.gd`), e as constantes estão
  centralizadas. Afinar é barato.
- **Latência zero** e aceleração/travagem secas. O chão responde como deve.
- **Um só modelo em todos os níveis** (N1 = N13 = N56, medido). Não há deriva por nível.
- Coyote e buffer existem; o buffer é generoso.
- O agarrão alcança rebordos de 140 px: uma boa rede de segurança se deixar de encravar.
- A arte golden de **roll/djump/dash** é expressiva e lê-se bem (tira `strip_ar_rolar_borda.png`,
  linha 4).
- Câmara sem jitter e com look-ahead estável. O joystick de toque é digital, com zona morta
  (`controlos_tacteis.gd:361-374`): comportamento previsível.

## Capturas

- `docs/qa/global_audit/img/a1/strip_chao_arranque_travagem_viragem.png`: arranque (14
  ticks), travagem (20), viragem (16), 1 tick por célula. Na linha 2 vê-se a troca para
  frames legados; na linha 3, o pop do brake.
- `docs/qa/global_audit/img/a1/strip_ar_rolar_borda.png`: salto parado, salto a correr +
  aterragem (sem `land`), rolamento, agarrão de 140 px + subida (pose `jump_loop`).
- `docs/qa/global_audit/img/a1/l1_00_idle.png`, `l1_01_corrida_lookahead.png`,
  `l1_02_viragem_6f.png`, `l1_03_viragem_30f.png`: N1 real, janela 1280×720, look-ahead e
  contraste.

## RUNTIME VERIFIED vs STATIC ONLY

**RUNTIME VERIFIED** (harness com input injetado, N1 + N13 + N56 em headless; N1 também com
janela):

- velocidade, aceleração, travagem, viragem, latência de movimento;
- tabela do salto variável, apex, tempo no ar, comprimento do salto;
- queda máxima, coyote, buffer, controlo no ar;
- rolamento, abuso do rolamento, dash no chão, abuso do dash, dash aéreo com ↑, salto duplo;
- wall-kick básico, parede com `escalar_paredes`, agarrão em 60/100/140 px + subida;
- ausência de knockback;
- bug de 1 frame da `land`, travagem com frames legados, pop do brake na viragem;
- descarte de velocidade externa;
- look-ahead e deadzone da câmara no N1 real;
- agarrões não pedidos no N1 real;
- números idênticos entre os níveis.

**STATIC ONLY — NOT RUNTIME VERIFIED:**

- a duração percebida do hit-stop;
- o efeito real do `iman.gd` num nível: só se provou o mecanismo de descarte, com escrita
  equivalente;
- o aviso Camera2D física vs `_process`;
- o toque em telemóvel real (a duração dos taps é uma estimativa de 80–130 ms);
- a discrepância do `verifica_alcance.gd` face aos níveis concretos (não se correu o
  verificador);
- as comparações com Hollow Knight, Dead Cells e Lost Crown (qualitativas); as de Celeste
  vêm dos valores públicos do `Player.cs`, aproximados.

## Save real

SHA256 de `%APPDATA%\Godot\app_userdata\Koliani\progresso.json` no fim:
`9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238`. **Igual ao valor de
referência, sem alteração.**
