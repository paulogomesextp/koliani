# Execution 6B — Character + Level 1 Completion

Data: 10 de setembro de 2026.

Estado: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW
REQUIRED**.

História preservada:

- 5G.1: **TECHNICAL PASS / HUMAN VISUAL FAIL**;
- 6A: **PARTIAL VISUAL BUILD / PRODUCTION ASSETS MISSING**;
- 6B: correção de personagem concluída; Level 1 fechado até ao limite da
  autoridade de produção disponível, sem novo design.

## Autoridade verificada

As doze imagens em
`Koliani_1.0_Master_Package_v2/references/approved/01...12` foram abertas no
path real, inspecionadas visualmente e verificadas por dimensões, modo e
SHA-256 contra o manifesto. A grafia `KolIANI` indicada para a fonte 10 foi
resolvida no Windows para o diretório existente `Koliani_1.0_Master_Package_v2`;
nenhuma imagem foi substituída.

## Koliani — causa e correção

O rastreio cobriu os 44 frames integrados de `idle`, `run`, `run_start`,
`turn`, `jump_start`, `jump_loop` e `fall`, além dos fallbacks `land` e
`run_brake`. A origem do defeito estava na **extração**, antes da normalização:
o processo histórico dividiu a faixa de corrida uniformemente entre
`x=29..1507`, embora os separadores visuais reais fossem irregulares
(`29, 146, 257, 370, 484, 596, 709, 823, 937, 1048, 1160, 1272, 1389,
1506`). O erro acumulado e a seleção apenas do componente frontal descartaram
componentes legítimos das pernas/pés em `run_03`–`run_09`.

A normalização, o strip, o import Godot e as regiões AtlasTexture preservavam
fielmente a entrada defeituosa; não existia crop adicional em runtime. Os
sete frames foram reextraídos deterministicamente das células reais da
autoridade 05, incluindo apenas componentes observados da própria fonte, e
normalizados novamente para `160×96`. Não houve pintura, inferência,
reconstrução generativa ou redesign. SHA-256 final de `run.png`:
`09CC2BE08915AFC9FA8C3E4BB806DD9C9F369EA1581C370D12DE1351B43E68E2`.

Resultado forense final: **44 SAFE, 7 FIXED, 0 BLOCKED, 0 atlas mismatches**.
`run_03`–`run_09`: **RECOVERED FROM APPROVED SOURCE / SAFE**. Fallbacks:
`run_brake` reutiliza frames aprovados de `run` + `idle`; `land` reutiliza
`fall_04` + `idle_01`, sem fabricar os 11 frames ainda ausentes.

Parâmetros congelados e confirmados: escala `0,82`, offset Y `-15,170732`,
pivot `(80,90)`, canvas `160×96`, baseline lógica `Y=90`. Gameplay, colisão,
movimento e câmara: **UNCHANGED**.

Evidência:

- `work/execution_6b/koliani_diagnostics/koliani_lower_body_trace.png`;
- `work/execution_6b/koliani_diagnostics/koliani_lower_body_trace.json`;
- `work/execution_6b/preview/koliani_6b_gameplay_review.png`.

## Level 1 — inventário e limite de produção

### Implementado e preservado

- panorama/floresta profunda da 6A;
- Heart Tree corrompida monumental;
- cascatas, ruínas, silhuetas e foreground baked;
- 29 nós visuais, três luzes e um emissor/34 partículas;
- geometria, 20 plataformas, checkpoints, porta, alcance e progressão;
- inimigos funcionais `EliteGoblin`, `GoblinBaixa` e `Ghorak`;
- HUD, VFX, música e áudio funcionais existentes.

### Legacy retido

Tiles/superfícies, props, inimigos, Ghorak, HUD e áudio atuais foram mantidos
quando a substituição exigiria material de produção inexistente ou ainda não
aprovado. Removê-los reduziria a qualidade ou quebraria sistemas funcionais.

### Approved design / production asset missing

- layers alpha/parallax separados do panorama;
- kit de terreno Hybrid final, continuidade de solo, raízes, rochas,
  vegetação, props e framing modular;
- frames limpos da criatura infectada e replacement visual de Ghorak;
- export final de HUD coerente com a autoridade 09;
- VFX ambientais/inimigos finais da autoridade 12;
- soundscape/ambiente final da Região I;
- animações próprias completas de `land` e `run_brake`.

O kit modular local tem 12/12 PNGs tecnicamente válidos, mas o manifesto
classifica todos apenas como `validated`, e a proveniência local é
`_source/imagegen_v1`. Como não existe aprovação visual de produção, esse lote
**não foi integrado**. Uma referência aprovada não foi confundida com um
asset final.

Bloqueadores técnicos do Level 1: **nenhum**. Bloqueio de produção restante:
assets aprovados ainda não disponíveis. Revisão estética da 6A/6B:
**HUMAN VISUAL REVIEW REQUIRED**.

## Validação

- character trace: PASS — 44/44 safe, sete recuperados;
- targeted Koliani 5G: PASS;
- targeted Level 1 6A invariants: PASS;
- Movement + Camera 4A: PASS;
- reachability: PASS — 20 plataformas, porta alcançável;
- art-kit gate: 12 presentes, zero missing, zero fails, 12 warnings de
  aprovação pendente;
- suite completa: PASS — `OK -- todos os testes passaram`;
- renderer real Godot 4.7.2/OpenGL 3.3/NVIDIA RTX 5070: PASS em oito vistas
  do Level 1 e oito poses da Koliani;
- `git diff --check`: executado antes do commit final.

Avisos não regressivos: dez ficheiros AppleDouble `._monster-*.wav` de 82
bytes não são WAV válidos e geram ruído de import; o runner mantém os avisos
conhecidos de objetos/recurso referenciados ao encerrar. Nenhum deles impediu
testes, export ou smoke.

Pacote de revisão:

- `work/execution_6b/preview/level1_6b_review.png`;
- `work/execution_6b/preview/level1_6a_vs_6b.png`;
- `work/execution_6b/preview/koliani_6b_gameplay_review.png`.

## Entrega

- Windows: `C:\Projetos\koliani\build\windows\Koliani.exe`; export PASS e
  smoke real do Level 1 PASS em `smoke_level1.avi`;
- atalho estabelecido: continua a usar `jogar.bat` e o build acima;
- Web/PWA: `C:\Projetos\koliani\build\web\index.html`; export PASS, HTTP
  local 200;
- PWA: manifest/service worker presentes; cache alterado de
  `1789024307|5115130` para `1789047133|5780304`, com remoção de caches antigos
  do prefixo `Koliani-sw-cache-`;
- Android e iOS: **OUT OF SCOPE**.

Os ficheiros ignorados `build/windows/BUILD_SOURCE.txt` e
`build/web/BUILD_SOURCE.txt` são atualizados após o commit final com o SHA
exato. A validação em dispositivo/browser final continua distinta do smoke
local.

## Conclusão

A causa do corte foi provada e os sete frames recuperáveis foram corrigidos
sem redesenhar a personagem. O Level 1 preserva integralmente o trabalho 6A e
foi completado até ao limite seguro da autoridade já disponível; nenhuma arte
não aprovada foi promovida para esconder lacunas. Classificação final:
**PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN VISUAL REVIEW REQUIRED**.
