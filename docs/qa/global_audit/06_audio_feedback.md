# 06 — ÁUDIO & FEEDBACK (Agent 6, auditoria global)

Data: 25 set 2026 · HEAD `bcac9fde` · modo só diagnóstico (nada no jogo foi alterado).
Evidência medida em `docs/qa/global_audit/img/a6/` (CSV/TXT/JSON; a auditoria de áudio
não produz PNG). Harness de runtime: `img/a6/a6_audio_harness.gd.txt` (cópia do script que
correu a partir da scratchpad, via wrapper de sandbox).

---

## 0. Resumo executivo — as causas-raiz

| # | Causa-raiz | Sintomas que explica | Prio |
|---|---|---|---|
| **R1** | **A identidade sonora do jogo é uma playlist de stock, não uma trilha.** 40 faixas Pixabay de ~35 autores, todas escolhidas faixa-a-faixa por título, sem motivo, paleta ou mistura em comum; nenhuma é um loop. | regiões sem identidade própria, «mudança de rádio» entre regiões, reinício audível da faixa a cada 1,5–5 min, Zeriko sem tema, regiões 2–20 sem ambiente próprio | **P0** |
| **R2** | **Não há conceito de mistura: o volume vive em constantes por callsite + um −6 dB global no SFX.** Sem buses por categoria, sem compressor/limitador, sem ducking, sem snapshots. | salto/dash/passos/telegrafos enterrados sob a música, desbloqueio de habilidade quase inaudível, `esmagar` a clipar no master, pickups de 1 s a ocupar o pool | **P0** |
| **R3** | **O áudio não tem espaço: tudo é `AudioStreamPlayer` mono ao centro, e a regra «fora do ecrã» é um interruptor on/off.** | ameaças fora do ecrã mudas (em vez de distantes/panoramizadas), mecanismos do mundo audíveis de qualquer lado, chefes sempre a 100 % | **P1** |
| **R4** | **A música é uma máquina de 2 estados sem memória (`ambiente`/`boss`) que é re-disparada pelo reload da cena.** | **no retry do chefe a música pula para a região e a faixa do chefe recomeça do início a cada morte** (runtime, 12–15 vezes em 45 s); sem camada de combate, sem silêncio intencional, sem vitória | **P1** |
| **R5** | **O vocabulário de SFX foi desenhado para o jogador e para a Região I; o resto do mundo partilha um banco genérico.** | 70/100 chefes usam 4–5 sons de arquétipo; 1 som de salto para salto/duplo/parede; passos iguais em 20 materiais; telegrafo de chefe silencioso; o SFX do checkpoint é também ataque de 3 chefes | **P1** |

O que **funciona e deve ficar**: a cadeia ACTION → SOUND da Koliani está completa
(0 eventos sem som em 4 níveis, runtime); aterragem em 3 tiers; combo de 4 golpes com 4
vozes; variantes de acerto sem repetição imediata; famílias de voz para mobs; pool com
prioridades; `laco()` com tecto e limpeza por troca de cena; o gate `toca_actor` já corta
o ruído de mobs fora de campo; os SFX de progressão aprovados (Pixabay) estão integrados
com hashes e manifesto. É um sistema **tecnicamente cuidado** — o problema é de direção
e de arquitetura de mistura, não de bugs.

---

## 1. Método

- **Estático**: leitura de `scripts/musica.gd`, `scripts/som.gd`, `scripts/opcoes.gd`,
  `default_bus_layout.tres`, `koliani.gd`, `demonio_base.gd`, `chefe_base.gd`,
  `chefe_generico.gd`, `checkpoint.gd`, `main.gd`, scripts de hazards; docs
  `docs/audio/**`, `docs/execution_9h13_14*`, `9h18`, `9h19`, `9f`.
- **Medição de ficheiros (ffmpeg 9.0.1)**: `ebur128` (LUFS I, LRA, true peak, M máx),
  `astats` (pico, RMS, RMS-pico 50 ms), `silencedetect` (caudas/cabeças de loop),
  `aspectralstats` (centróide). **Não usei `volumedetect`.**
  - `img/a6/musica_loudness_loops.csv` — 40 faixas + ambientes.
  - `img/a6/musica_cauda_silencio.txt`, `musica_silencios_loop.txt` — costuras de loop.
  - `img/a6/musica_centroide_espectral.csv` — «brilho» médio de cada faixa.
  - `img/a6/sfx_catalogo_medicoes.csv` — as 112 entradas de `Som.CAMINHOS` + duplicados md5.
  - `img/a6/mix_smr_sfx_vs_musica.csv` — relação sinal/música ao **ganho real de jogo**
    (callsite + bus SFX −6 dB vs música −8/−6 dB).
- **Runtime (sandbox, `--headless`, via `Main.tscn` = fluxo real)**: harness próprio que
  pilota a Koliani com `Input.action_press` (andar, saltar curto/longo, atacar perto de
  inimigos, dash, rolar), depois percorre checkpoints/essências e vai ao chefe; lê
  `Som._ordem/_ordem_vozes/_pool` a cada physics frame para registar **cada som que
  arranca**, `Musica._caminho_atual/_amb_caminho` para música/ambiente, e deteta eventos
  de gameplay (salto, salto no ar, aterrar, dash, rolar, dano, morte, checkpoint,
  essência, acerto/morte de inimigo e chefe). Correlação evento→som em [−2, +6] frames.
  4 níveis × 90 s: N1 (idx 0, Região I), N8 (idx 7, Região II), N47 (idx 46, Região X),
  N98 (idx 97, Região XX). Resultados: `img/a6/runtime_eventos_som_idx*.json`.
  - Limites: bot sintético (não humano); o `--headless` usa driver de áudio dummy, por
    isso mede **o que é pedido ao mixer**, não o que sai do altifalante. Nada aqui
    substitui escuta humana.

---

## 2. Música

### 2.1 CURRENT STATE
- `Musica.faixa_de_nivel()` (`scripts/musica.gd:155-166`): **uma faixa por região**
  (20) + `Musica.faixa_de_chefe()` (`:169-181`): **uma faixa de chefe por região**
  (20), partilhada pelos 5 chefes da região. Menu: `menu_cinematic_fantasy_dark_no_intro.ogg`.
- Fonte: todas Pixabay, integradas a 22–24 set (`docs/audio/approved_audio_manifest.md`,
  38 confirmadas por hash). Estado: *approved* pelo Paulo como lista de URLs — é a
  camada 2 da hierarquia; a auditoria avalia a execução.
- Trilha original 9H.1 (`musica/producao/`, D menor 60 BPM, motivo de 7 notas) e as
  40 `.ogg` de `musica/niveis|chefes/` ficam como reserva morta; `intensificar()`
  (`:235-247`) sai sempre cedo porque `REGIAO_01_APROVADA` existe — **não há camada de
  combate em nenhuma região**. `PITCH_BIOMA` (`:75`) já não é usado.
- Ambiente por baixo da música (`_escolher_ambiencia`, `:330-341`): Região I →
  `ambiente_floresta.wav` (18,5 s); **Regiões 2–20 → `assombracao.wav` (12 s, «casa
  assombrada»: rangidos, correntes)** — **RUNTIME VERIFIED** nos idx 7, 46 e 97.

### 2.2 Medições
**Gain staging (bom)** — ao ganho de jogo as regiões ficam entre −23,9 e −19,9 LUFS
(spread 4 dB) e os chefes entre −21,7 e −16,0 (`AJUSTES_REGIAO/BOSS`, `:82-83`). Mas o
**chefe 1 fica 0,7 dB abaixo da região 1** (−21,1 vs −20,4 LUFS efetivos): o primeiro
chefe do jogo não «sobe».

**Nenhuma faixa é um loop** (`musica_cauda_silencio.txt`, `musica_loudness_loops.csv`):
- 31/40 faixas acabam num fade para < −45 dB: região 16 com **9,9 s** de cauda,
  região 01 (a faixa aprovada da Região I) **6,5 s**, região 11 5,7 s, menu 4,0 s,
  chefe 19 4,4 s.
- 17/40 começam com 0,3–1,0 s de silêncio (região 19 1,0 s; regiões 13/17 0,9 s; chefe 06 0,9 s).
- Algumas cortam a seco: região 02 acaba a −21,7 dB RMS e recomeça a −49,8 dB; região 10
  −29 → −45 dB.
- `_carregar_loop` (`:346-354`) liga `loop = true` do início ao fim do ficheiro. Resultado:
  a cada 1,5–5 min ouve-se **«a música acabou… e recomeçou do zero»**, com buraco de
  até ~10 s na região 16. (Memória do projeto: «loops sem emenda» foi resolvido para a
  trilha sintetizada; as faixas de stock nunca passaram por isso.)

**Paleta incoerente** (`musica_centroide_espectral.csv`): centróide médio de 561 Hz
(região 12) a 2581 Hz (região 17) — as regiões 13 («Moving Staircases») e 17
(«Moonpetal Nocturne… with female vocals») são ~4× mais brilhantes que as 5/12. LRA de
1,8 (região 12/14, bordão plano) a 15,3 LU (região 19, cinematográfica com explosões).
As categorias Pixabay nos URLs misturam «ambient», «choir», «main-title», «drama-scene»,
«modern-classical», «epic-classical», «build-up-scenes» e **«fantasy-dreamy-childrens»
(menu e região 05)**. STATIC ONLY — o caráter musical exige escuta; os números só provam
que as faixas não foram produzidas como família.

**Correspondência região↔faixa escolhida pelo título** (STATIC ONLY, sem escuta):
Região 07 «Jardins Envenenados» ← «Garden of Morning Dew»; Região 17 «Jardim Onírico» ←
balada com voz feminina (voz por cima de gameplay compete com diálogo/SFX); Região 14
«Planícies Celestiais» ← «Dark»; chefe 11 ← «Epic Hollywood Trailer». O final (N100,
Zeriko de 4 formas) usa `boss_20` = a mesma faixa dos outros 4 chefes da Região XX
(e é byte-idêntica a `bg_boss.mp3`, a reserva legada).

**Ambiente inaudível**: os dois ambientes medem −19,4 LUFS e tocam a −19 dB →
**−38,4 LUFS efetivos, ~17 dB abaixo da música**. Na prática a camada de ambiente não
contribui para a identidade de região nenhuma — e onde se ouvir, as regiões 2–20 soam
todas a «casa assombrada», em 12 s de ciclo.

### 2.3 Máquina de estados da música — defeito provado em runtime (R4)
`Musica.boss()` entra por `ChefeBase.provocar()` (`chefe_base.gd:447-455`) e pela última
fogueira (`checkpoint.gd:134`, `:411`). `main.gd:26` chama `Musica.ambiente()` em **cada**
carregamento de nível — incluindo o *reload* depois de morrer. Como `_tocar()` troca
`_p.stream` (`musica.gd:311-317`), cada troca recomeça a faixa do início.

**RUNTIME VERIFIED** (`runtime_eventos_som_idx07/46/97.json`, campo `musica`): no retry do
chefe, cada morte da Koliani é seguida ~14 frames depois de `region_XX` e ~50 frames
depois de `boss_XX` outra vez. Em 45 s de luta: **14 alternâncias no N8, 22 no N47, 30 no
N98.** Exemplo N47: mortes em f2959, 3197, 3326, 3624, 3921 → região em f2973, 3211, 3340,
3638, 3935. O jogador que falha um chefe 10 vezes ouve 10 vezes o cruzamento para a
música de exploração e 10 vezes a introdução do tema do chefe.

### 2.4 WHAT WORKS
- Cruzamento de 0,9 s entre camas (`:302-321`) em vez de corte seco; `preparar_boss()` em
  thread elimina o frame de 2 s medido em 8.1C; a cama não reinicia entre níveis da mesma
  região (`:294`); compensações de loudness medidas.
- Tudo licenciado, rastreado por SHA e manifestado — base sólida para trabalhar.

### 2.5 WHAT DOES NOT WORK
Identidade (R1), loops (R1), ambiente (R1/R2), retry do chefe (R4), zero dinâmica:
sem camada de combate, sem estados de tensão/vida baixa, sem silêncio intencional (a
música toca sempre, mesmo na fogueira), sem *stinger* de vitória musical (o chefe morre →
`conquista.wav` + regresso à cama de região).

### 2.6 BENCHMARK GAP
- **Hollow Knight**: um compositor, leitmotivos (tema de área que regressa em variações),
  instrumentação por área, camadas que entram/saem por sub-área, **ambiente de área como
  metade da identidade** (Greenpath = água/folhas, Crystal Peak = cristais/maquinaria),
  silêncio usado como recurso, tema do chefe que reage às fases. Koliani: 40 obras
  independentes, sem motivo comum, ambiente único e inaudível.
- **Dead Cells**: loops escritos para loop, música do bioma contínua através de mortes
  (a morte não é um corte musical), clímax do chefe por fase. Koliani: reinício audível e
  ping-pong no retry.

### 2.7 KOLIANI OPPORTUNITY
O canon já dá o material de um leitmotivo: **Koliani / Aurora / Zeriko**. Um motivo de 5–7
notas (o `compor_trilha_9h1.py` já tem um, em D menor) que (a) aparece no menu, (b)
é citado de forma distorcida à medida que a corrupção de Zeriko cresce, (c) se inverte no
N100 — dá ao jogo uma espinha que nenhuma playlist dá. Ambiente por região tem um
bónus próprio: as **mecânicas-assinatura por nível** (vento, sinos, água, relógios) podem
*ser* o ambiente, e a Região III («armadilhas ativadas por som», canon) pede o áudio
como mecânica.

### 2.8 ACTION
- **PARTIAL REWORK / P0** — Tratar a música como *spec* de produção: por região, uma cama
  de exploração **em loop real** (ponto de loop marcado, sem cauda nem cabeça), um estado
  de combate/ tensão, um tema de chefe com variação por fase; paleta e motivo comuns.
  As faixas Pixabay aprovadas podem ficar como **referência de tom** (autoridade 2) ou
  como material editado (cortar intros/outros e marcar loop — edição, não substituição),
  mas não como produto final de 20 regiões.
- **TUNE / P1** — Corrigir R4: a música não se decide no `main.gd` a cada reload; decide-se
  pelo estado de sessão (se a última fogueira acesa é a do chefe, a sessão já está em
  «combate de chefe», e o reload não volta à região nem reinicia a faixa).
- **PARTIAL REWORK / P1** — Ambiente por região (20 camas, a −28/−32 LUFS efetivos, não
  −38), começando pelas regiões que já têm arte aprovada.
- **P3** — Limpar o legado morto (`intensificar`, `PITCH_BIOMA`, `PRODUCAO` exceto pausa,
  as 40 `.ogg` de reserva) para ninguém voltar a ligá-lo por engano.

---

## 3. SFX — cobertura, repetição, vocabulário

### 3.1 CURRENT STATE
- `Som.CAMINHOS` (`scripts/som.gd:9-140`): 112 chaves. Pool de 8 vozes `AudioStreamPlayer`
  com prioridade NORMAL/MÉDIA/ALTA (`:271-314`), 3 canais de laço fora do pool (`:347`),
  variação de pitch ±5 % e `VARIANTES := {"acerto": 3}` (`:218`).
- Koliani: síntese original «Signature» (`tools/gerar_sfx_koliani_signature.py`).
  Mobs: 7 famílias × {ataque, dano, morte} (`demonio_base.gd:456-475`), pitch em ciclo
  determinístico. Chefes: `_som_ataque/_som_impacto/_som_fase` (`chefe_base.gd:782-836`).
- Progressão/UI: 16 MP3 Pixabay aprovados (`assets/audio/approved/sfx/`).

### 3.2 Cadeia ACTION → VISUAL → SOUND → RESULT (runtime)

Contagem de 4 níveis × 90 s (`runtime_eventos_som_idx*.json`). «Sem som» = nenhum som
arrancou em [−2, +6] frames do evento.

| Ação | Eventos (4 níveis) | Sem som | Som que dispara | Visual | Leitura |
|---|---:|---:|---|---|---|
| Salto do chão | 133 | 0 | `koliani_jump` | squash/stretch | OK — mas SMR **−4,8 dB** (exploração) / −8,4 (chefe) |
| Salto no ar / parede | 63 | 0 | **o mesmo `koliani_jump`** (`som.gd:11-12`, md5 igual) | — | duplo salto e salto de parede indistinguíveis de ouvido |
| Aterrar | 252 | 1 | `land_soft/medium/hard` por tier | pó no tier ≥2 | bom desenho; leve a **−9,6 dB** SMR |
| Passos | ~560 sons | — | 3 variantes | — | **−24 dB SMR = inaudíveis**; iguais nas 20 regiões |
| Dash | (não detetado pelo harness*) | — | `koliani_dash_wind_magic_5` a −11 dB | rasto | **−10,4 / −14 dB SMR**: o dash é quase mudo |
| Rolar | 32 | 0 | `koliani_roll` | i-frames | OK, −7,9 dB SMR |
| Ataque (combo) | ~470 sons | — | swing 1/2/3 + finisher | smear | swing_1 = 60 % dos golpes (79 vs 25/23/10 no N8) |
| Acerto em inimigo | 6 | 0 | `shadowblade_hit` v1–v3 / `critical` + voz `mob_*_dano` | faíscas + hitstop + tremor | **boa cadeia** (hitstop 8.1C + VFX 9G + 3 variantes) |
| Acerto em chefe | 61 | 0 | hit + `mob_grande_dano` (**sempre a família «grande»**) | idem | todos os chefes «gemem» igual; −9,5 dB SMR na luta |
| Receber dano | 128 | 0 | `koliani_hurt` / `hurt_heavy` | flash branco + sangue 9G | OK (≈0 dB SMR) |
| Morte | ~57 | 0 | `koliani_death` (ALTA) | VFX + fade | OK; poça mortal (98 níveis) morre com o mesmo som, sem *splash* |
| Checkpoint | 104† | 0 | `checkpoint_sword_cut` | fogueira + HUD | OK; **mas o mesmo `selo` é ataque de 3 chefes** (Açougueiro, Maquinista, Vyrak) |
| Essência | 29 | 0 | `pickup_normal` (1,03 s) | mote | 6–9 motes na morte do chefe = 6–9 vozes de 1 s no pool de 8 |
| Habilidade desbloqueada | — | — | `ability_unlock_stinger` | — | **SMR −23,5 dB: o momento de recompensa mais importante é quase inaudível** (STATIC: ficheiro −37 LUFS) |
| Fim de nível | — | — | `level_complete_soft_landing` | fade | −12 dB SMR |
| Telegrafo de hazard (raiz) | 54 sons no N1 | — | `raiz_aviso` | tremor + brilho | **−15,5 dB SMR**: o aviso é mais baixo que o golpe (−1,1) — ao contrário do que um telegrafo pede |
| Telegrafo de chefe genérico | — | — | **nenhum** | aura + flash (`chefe_base.gd:651`) | som só no `_agir()` (`chefe_generico.gd:241-253`) = no golpe, não no aviso |

\* O `_dash_restante` não passou a > 0 nas janelas do harness (provável `dash` bloqueado
por habilidade/energia no save novo); o som do dash foi medido estaticamente.
† Inclui mudanças de checkpoint no respawn.

**Conclusão da cadeia**: a Koliani **nunca fica calada** (0 sem som em 4 níveis) — o
problema não é cobertura, é **nível e distinção**: movimento, dash, telegrafos e
recompensas estão abaixo da música; e o que distingue ações diferentes (duplo salto,
dano em chefes diferentes, checkpoint vs ataque de chefe) foi colapsado no mesmo ficheiro.

### 3.3 Repetição e vocabulário do mundo (R5)
- **Chefes**: 70/100 níveis usam `ChefeGenerico` (contagem nas cenas). O arquétipo
  decide o som: `investida`, `chefe_magia`, `esmagar`, `invocar`, `feixe_vil`
  (`chefe_generico.gd:244-340`). Nos 40 scripts de chefe há 18 nomes de som;
  `investida`/`invocar` aparecem 18× cada, `projetil` 16×. 30 chefes de 100 têm script
  próprio; os outros 70 soam por arquétipo.
- **Mobs**: 34 espécies → 7 famílias × 3 eventos = 21 ficheiros, 1 amostra por evento.
- **Passos/aterragens**: 1 material para floresta, deserto, abadia afogada, laboratório,
  planícies celestiais.
- **Mortos no catálogo**: `recompensa`, `apanhar_raro`, `curar`, `guardar`,
  `ui_mover_v2/v3` não têm callsite de jogo (só `dev_sons`); o comentário de `som.gd:208-217`
  diz que `ui_mover` tem variantes mas `VARIANTES` só contém `acerto`.
- **Hazards mudos** (sem nenhuma chamada ao `Som`): `serra`, `espinhos`, `parede_fragil`,
  `gota_acida`, `agua_venenosa` (98 níveis — sem borbulhar nem *splash*), `chao_quente`,
  `ceifa`, `serpente`, `parede_movel`, `corrente_ar`, `plataforma_peso`.
- **Dominância de um hazard** (runtime N1): `raiz_aviso` 29 + `raiz_irrompe` 25 em 90 s =
  16 % de todos os sons do nível; um único ficheiro por fase, variação só de pitch.

### 3.4 WHAT WORKS
Combo com 4 vozes e pesos (`VOL_COMBO`, `koliani.gd:875`), aterragem em 3 tiers
(`koliani.gd:1710-1729`), hitstop + VFX + som no mesmo frame (`koliani.gd:2336-2354`),
prioridades (morte não é cortada por passos), cooldowns por instância, ciclo de pitch
determinístico nos chefes e mobs, voz de ataque dos mobs no início da antecipação
(`demonio_base.gd:844-846`, `1046-1047`) — ou seja **os mobs já têm telegrafo sonoro**.

### 3.5 BENCHMARK GAP
- **Dead Cells**: cada arma tem swing/impacto próprios, impacto > música, *hit-confirm*
  inconfundível, inimigos com grito de aviso **antes** do golpe, SFX de ambiente por
  bioma. Koliani tem a estrutura (hitstop + VFX + som), falta-lhe nível e variedade.
- **Nine Sols / Hollow Knight**: telegrafo audível do chefe (inspirar, raspar, carregar),
  som de fase, som de *parry*. Os 70 chefes genéricos têm telegrafo **só visual**.

### 3.6 KOLIANI OPPORTUNITY
A «Shadowblade» roxa já tem uma família sonora original (síntese própria). É a peça
mais identitária do áudio — alargá-la (energia roxa = assinatura da Koliani; corrupção de
Zeriko = contra-assinatura grave/ruidosa) dá coerência a todo o jogo sem comprar nada.

### 3.7 ACTION
- **TUNE / P1** — Telegrafo sonoro em `ChefeBase._piscar(true)` (um único sítio cobre os
  70 genéricos); voz de dano por chefe (não `mob_grande_dano` para todos); separar
  `salto_duplo`/parede; tirar `selo` dos ataques de chefe.
- **PARTIAL REWORK / P1** — Superfície por região (passos/aterragem, 4–6 materiais) e SFX
  de hazards mudos, começando pela poça mortal (98 níveis) e serra.
- **TUNE / P2** — variantes reais para `koliani_jump`, `swing_1`, `raiz_*`, `pickup`
  (encurtar a cauda de 1 s do pickup para motes múltiplos).

---

## 4. Mistura e volumes (R2)

### 4.1 CURRENT STATE
- `default_bus_layout.tres`: **Master → Music, SFX**. Nenhum `AudioEffect` em nenhum bus
  (grep vazio em `scripts/` e `scenes/`): sem compressor, limitador, EQ, reverb.
- Ambiente e pausa tocam no bus **Music** (`musica.gd:113-123`) — o slider de música
  controla o ambiente.
- `Opcoes.SFX_MIX_DB := -6.0` (`opcoes.gd:31`, «a música fica claramente à frente» —
  decisão do Paulo). Por cima disso, cada callsite escolhe −3 a −24 dB à mão.
- Compensação por ficheiro só para 3 sons (`Som.COMPENSACAO`, `som.gd:257-261`).

### 4.2 Medições (`mix_smr_sfx_vs_musica.csv`, ganho real de jogo)
Música de exploração: RMS médio −25,7 dBFS (região 01), −25,4 (região 10); chefe 10: −22,1.

| Evento | SMR vs exploração | SMR vs chefe |
|---|---:|---:|
| acerto crítico / morte / investida de chefe | +3,7 … +4,5 | ≈0 |
| acerto normal / dano recebido | ≈0 | −3,7 … −3,9 |
| ataque (golpe 1) | −2,5 | −6,1 |
| salto | −4,8 | −8,4 |
| dano no chefe (`mob_grande_dano`) | −5,9 | −9,5 |
| checkpoint | −7,7 | −11,3 |
| aterragem leve | −9,6 | −13,2 |
| **dash** | **−10,4** | **−14,0** |
| fim de nível | −12,1 | −15,7 |
| ataque de mob voador | −14,0 | −17,6 |
| **telegrafo `raiz_aviso`** | **−15,5** | −19,1 |
| **habilidade desbloqueada** | **−23,5** | −27,1 |
| passo | −23,9 | −27,5 |
| hover de UI | −27,9 | −31,5 |

SMR = RMS-pico (janela 50 ms) do SFX − RMS médio da música, banda larga. É uma medida
grosseira (um transiente pode ouvir-se com SMR negativo se ocupar outra banda), mas abaixo
de ~−10 dB o mascaramento é provável. **HUMAN LISTEN REQUIRED.**

Outros:
- **Loudness de origem dos SFX aprovados muito dispersa**: `ui_hover` −39,5 LUFS,
  `ability_unlock_stinger` −37,0, `ui_back` −34,0 vs `portal_jump` −10,1 (`sfx_catalogo_medicoes.csv`).
  Foram integrados «sem edição» e compensados só por callsite (ou nada).
- **Picos acima de 0 dBFS**: `esmagar.ogg` +7,26 dBFS (16 callsites, recusado em
  `docs/audio/final_audio_qa.md` e ainda assim em uso), `unlock_door.mp3` +3,15,
  `portal_jump.mp3` +0,96. Sem limitador no Master, a morte do chefe (`chefe_cai` +
  `conquista` + 6–9 pickups + tema de chefe a −16 LUFS) pode somar acima do tecto.
  STATIC ONLY.
- **Pool**: 8 vozes para sons de até 6,1 s (`conquista`), 5,6 s (`raio`), 5,1 s
  (`meteoro`), 3,5 s (`portal`). STATIC ONLY — o driver dummy não permite medir roubo de voz.

### 4.3 WHAT WORKS
Loudness da música equilibrado (±2 dB entre regiões); prioridades; a correção de clipping
em `golpe_pesado`/`grito` (P4) está aplicada (−0,80/−0,77 dBFS medidos).

### 4.4 WHAT DOES NOT WORK / causa
Não há **alvo** de mistura: cada som foi afinado sozinho, no callsite, por quem o
integrou. A decisão «música à frente» aplicada como −6 dB **global** no SFX penaliza de
igual forma o feedback de combate (informação) e o ruído decorativo. Sem ducking, o tema
de chefe (o mais alto do jogo) é também o momento em que o feedback mais importa.

### 4.5 BENCHMARK GAP
Dead Cells e Hollow Knight misturam por **prioridade de informação**: hit-confirm,
dano recebido e telegrafo por cima de tudo; música com *ducking*/*side-chain* em momentos
de impacto; ambiente em bus próprio. Koliani mistura por ficheiro.

### 4.6 ACTION
- **PARTIAL REWORK / P0** — Buses por categoria (Music, Ambience, SFX-Player, SFX-Combat,
  SFX-World, UI) + limitador no Master + compressor leve no Music com *side-chain* dos
  impactos/telegrafos; tabela-alvo de loudness por categoria (ex.: hit/dano/telegrafo
  0…+4 dB SMR, movimento −6…−3, UI −8) aplicada **por ficheiro** (normalizar a fonte),
  não por callsite. Mantém-se a decisão do Paulo («música à frente») para o
  **decorativo**; o feedback de jogo é pedido de decisão (ver §8).

---

## 5. Espacialização e sons fora do ecrã (R3)

### 5.1 CURRENT STATE
- **Zero `AudioStreamPlayer2D`, zero `AudioListener2D`** no projeto (grep em `scripts/`
  e `scenes/`). Tudo sai mono ao centro, ao mesmo volume, perto ou longe.
- `Som.toca_actor()` (`som.gd:416-428`, commit `bcac9fde`): o som de um ator só toca se a
  origem estiver no retângulo da câmara (`actor_visivel`, `:470-480`) — **interruptor
  on/off, sem distância, sem pan**. Chefes contornam a regra sempre (`:422-424`).
- Adoção: `demonio_base`, `raiz_perigo`, `pedra_queda`, `pendulo_lamina`, `fogo`,
  `raio_tempestade`, `plataforma_ritmada` usam `toca_actor`; **`porta_trancada`,
  `alavanca`, `placa_peso`, `tumulo_elevador`, `vela`, `ariete`, `sino_torre`,
  `trampolim`, `plataforma_quebra`, `wind_zone` usam `Som.toca` simples** → audíveis de
  qualquer ponto do nível.
- Runtime N47: `mecanismo.wav` + `unlock_door.mp3` dispararam **36× cada em 90 s**, em
  22 casos junto de respawns — o mecanismo do nível (re)abre ao recarregar e ouve-se
  independentemente de onde está.

### 5.2 Leitura
O gate resolve «mobs a rosnar do outro lado do mapa», mas cria o problema oposto: uma
ameaça a 1 px fora do ecrã é **silenciosa**, e a um pixel dentro é **100 %**. Num jogo
landscape em telemóvel, com ecrã estreito, é exatamente aí que o som devia avisar.

### 5.3 BENCHMARK GAP
Hollow Knight: SFX de inimigos e máquinas em 2D com atenuação e pan — ouve-se de que
lado vem o perigo antes de o ver. Dead Cells idem (e ouve-se o elite/porta secreta).

### 5.4 ACTION
- **PARTIAL REWORK / P1** — `toca_actor` passa a pan + atenuação por distância à
  câmara (ou `AudioStreamPlayer2D` no pool), com a margem fora de ecrã a **atenuar**, não a
  cortar; telegrafos de ameaça com prioridade de audibilidade fora do ecrã; mecanismos do
  mundo pela mesma entrada. Mantém-se o corte a partir de uma distância real (o objetivo
  do `bcac9fde` continua válido).

---

## 6. Feedback de ações — Dead Cells como régua

| Sinal | Koliani | Dead Cells | Gap |
|---|---|---|---|
| Hit-confirm (som+hitstop+VFX+tremor no mesmo frame) | ✅ `koliani.gd:2336-2354` | ✅ | nível ≈0 dB SMR; sobe só no crítico |
| Distinção crítico/remate | ✅ som + VFX diferentes | ✅ | — |
| Dano recebido | ✅ 2 intensidades | ✅ | — |
| Telegrafo de inimigo comum | ✅ voz no início da antecipação | ✅ | 1 amostra por família |
| Telegrafo de chefe | ❌ só visual (70 chefes) | ✅ | **P1** |
| Telegrafo de hazard | ⚠ existe (`raiz_aviso`) mas −15 dB SMR | ✅ | P1 |
| Dash/rolar | ⚠ existe, dash −10…−14 dB SMR | ✅ forte | P1 |
| Recompensa (habilidade) | ⚠ existe, −23 dB SMR | ✅ fanfarra | **P0** (quick win) |
| Vitória sobre chefe | ⚠ `chefe_cai`+`conquista`, música volta à região | ✅ | P2 |
| Retry | ❌ música do chefe recomeça + pisca para região | ✅ contínua | **P1** |

---

## 7. Silêncio intencional

Não existe. A música toca sempre (menu, exploração, fogueira, chefe, vitória), o
ambiente toca sempre por baixo (embora inaudível), e não há nenhum momento desenhado de
ausência de música (entrada de chefe, sala de lore, *aftermath*). Hollow Knight usa o
silêncio como ferramenta de atmosfera; para a direção «gótica / luar» do Koliani é uma
oportunidade barata. **P2**, depende de R4 (máquina de estados).

---

## 8. O que precisa de decisão do Game Master

1. **Música: trilha própria vs playlist.** A lista Pixabay está aprovada (autoridade 2).
   A auditoria recomenda usá-la como *referência de tom* e produzir camas em loop com um
   motivo comum; ou, no mínimo, **editar** as 40 faixas para loop real (cortar intros/
   outros). Decisão do Paulo.
2. **«Música claramente à frente»** (decisão explícita, `opcoes.gd:31`). A auditoria mediu
   que isso põe dash, salto, telegrafos e recompensas 5–24 dB abaixo da música. Propõe-se
   manter a música à frente **do decorativo** e pôr o feedback de jogo ao nível dela.
3. **Chefes genéricos**: aceitar 70 chefes com voz de arquétipo, ou exigir voz/telegrafo
   próprio por chefe (custo alto) — pelo menos um telegrafo comum audível (custo baixo).

---

## 9. Prioridades consolidadas

| Prio | Ação | Tipo |
|---|---|---|
| P0 | Arquitetura de mistura: buses por categoria, limitador, side-chain, alvos por categoria normalizados na fonte | PARTIAL REWORK |
| P0 | Direção musical: loops reais + motivo/paleta comum (ou, mínimo, editar as 40 faixas para loop) | PARTIAL REWORK |
| P0 (quick win) | Subir `ability_unlock_stinger`, `ui_hover`, `ui_back`, dash e `raiz_aviso` para a tabela-alvo | TUNE |
| P1 | Estado de música por sessão (retry do chefe sem ping-pong nem reinício) | TUNE |
| P1 | Telegrafo sonoro de chefe em `ChefeBase._piscar` + voz de dano por chefe | TUNE |
| P1 | Espacialização (pan/atenuação) em vez de gate on/off; mecanismos do mundo pela mesma via | PARTIAL REWORK |
| P1 | Ambiente próprio por região, audível (−28…−32 LUFS efetivos) | PARTIAL REWORK |
| P1 | Materiais de superfície + hazards mudos (poça mortal primeiro) | PARTIAL REWORK |
| P2 | Variantes (salto/duplo/parede, swing 1, pickup curto), silêncio intencional, stinger de vitória | TUNE |
| P2 | `esmagar.ogg` +7,26 dBFS (recusado em final_audio_qa, ainda em 16 callsites) | TUNE |
| P3 | Limpar legado morto (intensificar/PITCH_BIOMA/PRODUCAO/40 .ogg de reserva/6 chaves sem callsite) | KEEP→limpar |

**Preservar**: família Shadowblade/Signature da Koliani, aterragem em tiers, combo de 4
vozes, variantes do acerto, pool com prioridades e cooldowns, `laco()` com tecto e guarda
de troca de cena, voz de ataque dos mobs no início da antecipação, rastreio de licenças
por hash, cruzamento de camas.

---

## 10. RUNTIME VERIFIED vs STATIC ONLY

**RUNTIME VERIFIED** (sandbox, `--headless`, `Main.tscn`, harness próprio; 4 níveis × 90 s):
- Todos os eventos da Koliani detetados (salto, salto no ar, aterrar, rolar, dano, morte,
  checkpoint, essência, acerto em inimigo/chefe, morte de chefe) tiveram som em
  [−2, +6] frames — 1 aterragem sem som em 252 (tier 0 presumível).
- Salto, duplo salto e salto de parede tocam o mesmo `koliani_jump.wav`.
- Acerto em chefe → `mob_grande_dano` em todos os chefes observados (N1, N8, N47, N98).
- Música: região certa por índice; ambiente `assombracao.wav` nas regiões II, X e XX.
- **Ping-pong região↔chefe e reinício do tema do chefe a cada morte no retry** (14/22/30
  trocas em ~45 s).
- `mecanismo`/`unlock_door` 36× em 90 s no N47; `raiz_aviso`/`raiz_irrompe` = 16 % dos
  sons do N1; `swing_1` domina os golpes.
- Nota: headless = driver dummy → medido o que é pedido ao mixer, não o que é ouvido.

**STATIC ONLY — NOT RUNTIME VERIFIED**:
- Todas as medições de loudness/SMR/costura de loop/centróide (medidas nos ficheiros e
  combinadas com os ganhos do código; não uma gravação do jogo).
- Caráter musical, adequação região↔faixa, «dark/gótico» — **não houve escuta**.
- Hazards mudos, gate `toca_actor` fora do ecrã, ausência de telegrafo sonoro nos chefes
  genéricos, roubo de voz no pool, clipping no Master.
- Som do dash (o harness não conseguiu disparar o dash no save novo).

**HUMAN LISTEN REQUIRED** para tudo o que é mistura e música.

---

## 11. Save real

SHA256 de `%APPDATA%\Godot\app_userdata\Koliani\progresso.json` no fim da auditoria:
`9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238` — **igual ao de
partida. Save intacto.**
