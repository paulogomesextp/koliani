# Prioridades — Koliani

## Agora

0. **DECISÃO PENDENTE — interpolação de física (Execution 8.1):** os
   "framedrops" no Windows foram diagnosticados e **não são falta de
   desempenho** (o L1 corre a 1388 FPS sem VSync; zero fugas). São cadência:
   a física corre a 60 Hz num painel de 165 Hz sem interpolação, logo **67 %
   dos frames desenhados são duplicados**. A correção é ligar
   `physics/common/physics_interpolation`; não foi aplicada porque é uma
   mudança de motor que precisa de validação visual humana (respawn,
   checkpoints, arenas de chefe, poeira). Detalhe e números:
   [`docs/execution_8_1_windows_performance_gate.md`](docs/execution_8_1_windows_performance_gate.md).

1. **Execution 8 — PARTIAL PASS / HUMAN REVIEW REQUIRED:** jogar a Região I
   completa (L1→L5→Coração Putrefacto→reward) nos builds Windows e Web/PWA;
   confirmar o menu sem dev UI, Koliani atual, panorama partilhado e validar
   legibilidade visual, feel do combo/aéreo/Dash, curva de dificuldade,
   checkpoints e ritmo do boss. A validação técnica e o runtime exportado
   passaram; isto não constitui aprovação humana.

## A seguir

2. **Produção visual aprovada em falta:** frames limpos de combate, plataformas,
   props, layers
   alpha/tiles Hybrid L2–L5, criaturas/guardiões, Coração Putrefacto, HUD,
   menu/seletor, VFX e áudio, sem reabrir design nem recortar pranchas
   arbitrariamente.
3. **Completar run_brake e land — PRODUÇÃO EM FALTA:** substituir os fallbacks
   aprovados apenas quando existirem os 11 frames limpos. Não inferir pixels.

## Validação externa pendente

- Nível 12 em iPhone, Safari/PWA: **DEVICE VALIDATION REQUIRED**. Desktop e
  OpenGL passaram, mas não encerram este ponto.

## Ordem técnica registada, não autorizada por si só

- Proteger o pipeline/geradores antes de remodelação em massa.
- Definir versionamento e migrações de save antes de mudar progressão.
- Definir IDs estáveis de progressão e persistência de recompensas.
- Validar safe areas e resolver a divergência de versão Android.
- Não iniciar Região II antes do gate humano da primeira Vertical Slice.

Detalhes e riscos em [docs/backlog_tecnico.md](docs/backlog_tecnico.md). O
dashboard de execução está em
[docs/execution_dashboard.md](docs/execution_dashboard.md).
