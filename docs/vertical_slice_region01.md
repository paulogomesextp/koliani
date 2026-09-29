# Vertical Slice — Região I (quality target oficial)

Estado: **DEFINIDO (Game Director Fase 0, 25 set 2026)**. Implementação só depois de
`docs/foundation_plan.md` ter as fases F1–F4 fechadas. Autoridade: `docs/auditoria_global_game_director.md`
§10.3–10.4 + decisões fechadas em `docs/game_director_decisions_pending.md`.

Âmbito: **N1 Floresta Putrefata** + **N5 Coração da Floresta (boss: Coração Putrefacto)**, com o
**Ghorak** como encontro authored. N2–N4 só depois de o slice passar (mesmo método, fase CONTENT).
Toda a produção fora deste âmbito está `FROZEN PENDING VERTICAL SLICE`.

Regra de prova: cada critério tem **número + método de medição**. PASS = critério medido no runtime
(harness/bancada, EXE de release quando for visual) **e** aprovação visual/jogada do Game Master.
"Parece melhor" nunca é PASS.

## 1. N1 — Floresta Putrefata ("Teach")

Objetivo: os primeiros 60–180 s provam identidade Koliani, movimento, feel, primeira mecânica
(raízes que irrompem, ensinadas em segurança), primeiro inimigo com ataque real, leitura, áudio,
feedback, exploração e retry.

- **Estrutura**: 4–8 salas authored (sem jornada procedural), semente por sala, checkpoint (fogueira)
  por sala/secção; ≥ 1 rota opcional + 2 segredos (um deles uma pista/memória da mãe).
- **Mecânica**: raízes em ≥ 60 % das salas; primeira exposição num espaço sem morte; nenhuma outra
  mecânica nova estreada.
- **Ghorak**: encontro authored (ver §3), não guardião obrigatório da porta.
- **Ensino de movimento por espaço**: wall-kick/mantle ensinados sem texto; a decisão de antecipar o
  dash é do GM (decisão pendente nº 12).

## 2. N5 — Coração da Floresta ("Exam + Boss")

Objetivo: examinar o domínio das mecânicas da Região I e fechar a região com o boss regional.

- **Preparação**: 2–3 salas de exame (raízes + salto duplo + inimigos com papel) → sala de descanso/
  fogueira → arena.
- **Arena**: enquadramento fixo, sem mostrar "fora do mundo", Heart Tree visível, chefe preso à arena.
- **Boss Coração Putrefacto**: 4–5 ataques, 2 fases com vocabulário novo na fase 2, telégrafo por
  golpe (pose + som), janela EXPOSTO própria, escala e arena da prancha, intro + nome no ecrã, examina
  as raízes, entrega o salto duplo com cerimónia (toast com ícone + instrução).
- **Conclusão regional**: ecrã de fim de região, progressão persistida, retorno ao seletor.

## 3. Ghorak — função no slice

**Recomendação: elite/mini-boss de sala no N1** (encontro authored no fim do 2.º terço), não no N5.
Razões: N5 tem de pertencer só ao Coração (um boss por região, decisão fechada); o Ghorak já tem
identidade e rig; funciona como **exame do combate básico** antes da porta de saída do N1 sem
competir com o clímax. Se falhar a barra do §4 Enemy, cai para "elite comum" — nunca sobe a boss.
Barra: 2–3 ataques com telégrafo por pose+som, TTK 10–15 s, 0 frames congelados.

## 4. QUALITY BAR — critérios de PASS

Todos medidos na build do slice; "harness" = bancada/teste headless ou de janela no `user://` isolado
(`tools/godot_isolado.py`). Os números vêm da auditoria (§10.2 fase 1).

| Sistema | Critério de PASS | Como se mede |
|---|---|---|
| **Movement** | Salto 125–135 px de altura; 1 só corte de salto (sem corte por tick); meia-gravidade no apex; queda máx. ≤ 750 px/s ou fast-fall; coyote 6 ticks, buffer ≥ 7; rolar encadeado < 240 px/s (< corrida); velocidade externa (vento/íman/trampolim) preservada por ≥ 60 ticks; knockback ao levar dano | bancada por tick (harness `Movimento`) |
| **Combat** | Tiro gasta Energia; kiting a 380 px não mata o soldado sem dano sofrido; combo 3.º/4.º exerce-se contra o soldado; hitbox da espada ±4 px da lâmina desenhada; hit-stop ≥ 2 frames a 60 Hz; nenhuma estratégia de 0 dano | bot de kiting + medição de hitbox vs frame |
| **Enemy** | 100 % das espécies do slice com: percepção/aggro, ataque com hitbox, telégrafo animado, recovery, reação a hit, morte; telégrafo distinguível do idle a 0,1 s; contacto ≤ sprite; TTK por papel: fodder 2–3, soldier 4–6, elite 10+ golpes (±1) | teste de estados + TTK medido |
| **Platforming** | 0 saltos acima do envelope; precisão máxima nunca sobre morte instantânea sem aviso; cada sala com 1 ideia | `tools/verifica_alcance.gd` + revisão de sala |
| **Camera** | Em queda máxima o chão visível ≥ 0,6 s antes do impacto; arena sem "fora do mundo"; zonas por sala | captura + medição na queda |
| **Art** | Match HIGH no conjunto (não só ambiente); 0 elementos PROC/LEG no ecrã (hazards com sprite, líquido e chão com arte); 1 densidade de texel; contraste da Koliani legível em todas as salas | fotos do EXE de release (`--nivel/--foto`) vs prancha aprovada + aprovação GM |
| **Animation** | `land` ≥ 4 ticks em 100 % das aterragens; 0 frames legados em brake/turn; mantle com animação; chefe/rigs sem frame congelado > 1 s | contagem por estado no tick de física |
| **VFX** | Flash de acerto não tapa o alvo; telégrafo com código de cor/forma por tipo de ataque; 0 fallbacks no ecrã | inspeção + captura |
| **Audio** | Loops sem buraco (0 gaps < −40 dB > 50 ms); SMR do feedback (hit/dano/telégrafo) ≥ 0 dB; 0 picos > −1 dBTP no Master; ambiente da floresta audível; música do chefe sem reinício no retry; stinger de habilidade audível | `astats`/ffmpeg + escuta humana (checklist) |
| **Level Design** | 4–8 salas por nível; N1 60–180 s (jogador médio); retry ≤ 10–15 s de percurso; nenhuma sala > 10 mortes medianas sem ser desafio declarado; ≥ 1 rota opcional + 2 segredos | telemetria de playtest + revisão |
| **Boss** | TTK 25–40 s jogador real; contacto ≤ 25–30 % da vida; ≥ 4 ataques com telégrafo; fase 2 com vocabulário novo; EXPOSTO ≠ hit; 0 frames congelados | logs do chefe + playtest |
| **UI** | Novo Jogo → controlo no N1 em ≤ 2 inputs; recompensa visível em 100 % dos ganhos; 0 strings cruas (`Textos.t`, 6 idiomas); HUD sem botões mortos | teste i18n + inspeção |
| **Performance** | 60 fps estáveis no dispositivo alvo; p99 frame ≤ 16,6 ms; sem engasgos por tempo de parede (não `delta`) | `perf_gate` isolado + telemóvel real |
| **Retry** | Respawn ≤ 0,5 s sem `reload_current_scene`; checkpoint por sala; save compatível (v5) | cronómetro de parede no harness |
| **Regional Identity** | Leitura inequívoca "Região I" em silhueta/paleta/som/mecânica (raízes); nenhum asset de outra região; inimigos, hazards, música/ambiente da região | folha de contacto + GM |

## 5. Ordem de trabalho (não iniciada)

F1 movimento/feel → F2 combate+energia → F3 kit de inimigo → F4 pipeline de sala/nível → N1 → Ghorak →
N5+Coração → áudio/mistura → validação humana (Paulo, Luís, ≥ 3 externos, telemóvel real). Detalhe em
`docs/foundation_plan.md`. Só depois: pipeline da Região II.
