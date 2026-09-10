# Prioridades — Koliani

## Agora

1. **Execution 6B — PARTIAL PASS / HUMAN VISUAL REVIEW REQUIRED:** jogar o
   Level 1 completo e validar as pernas recuperadas de `run_03`–`run_09`,
   contraste, continuidade do panorama/caps e leitura do Heart Tree. Windows
   e Web/PWA locais passaram; dispositivo/browser final continua
   `DEVICE VALIDATION REQUIRED`.

## A seguir

2. **Produção visual aprovada em falta:** exportar layers alpha, tiles Hybrid,
   props, criatura infectada, replacement de Ghorak, HUD e áudio sem reabrir
   design.
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
- Construir a primeira Vertical Slice na Região I apenas na execução aprovada.

Detalhes e riscos em [docs/backlog_tecnico.md](docs/backlog_tecnico.md). O
dashboard de execução está em
[docs/execution_dashboard.md](docs/execution_dashboard.md).
