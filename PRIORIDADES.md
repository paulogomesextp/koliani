# Prioridades — Koliani

## Agora

0. **RETOMAR: save não-bloqueante (Execution 8.1D) — ficou a meio.**
   Direção já decidida pelo Game Master (thread de fundo + coalescência).
   `scripts/save_pipeline.gd` está escrito e compila, mas **não está ligado**
   — o congelamento de ~2 s no checkpoint e no dano **continua**. Falta
   ligar ao `EstadoJogo` (`guardar()`, `instantaneo()` com `duplicate(true)`,
   `parar()` no fecho). Ver `docs/execution_8_1d_save_nao_bloqueante.md`.
   **Suspeita não medida mas forte:** os ~2 s são o re-parse do
   `level_manifest.json` (sem cache) × seis validações por gravação — e não
   o disco. Confirmar isso primeiro: muda a solução e é o único caminho que
   também arranja a Web, onde não há threads.

0z. **DECIDIR: gravar o save custa ~2 s (Execution 8.1C).** É esta a
   "congelação" — `EstadoJogo.guardar()` leva **2047 ms de mediana** na
   thread principal e é chamado ao passar num checkpoint e ao perder vida.
   Confirmação sem código: excluir `%APPDATA%\Godot\app_userdata\Koliani` do
   Windows Defender. Não mexi no save (tem suite de robustez própria).
   Opções por risco: (a) thread de fundo; (b) espaçar gravações; (c) cortar
   validações repetidas. Ver `docs/retomar_aqui.md`.

0b. **GAME MASTER CADENCE REVIEW REQUIRED (Execution 8.1B):** a interpolação
   de física está **ligada** e validada tecnicamente — a física continua a
   60 Hz e nenhuma constante de movimento/câmara mudou. Medido sobre a
   imagem desenhada: o desvio entre frames consecutivos caiu 59 % e o
   movimento deixou de chegar aos solavancos. Falta a **sua** validação
   visual no `build/windows/Koliani.exe`: corrida, saltos, mudanças rápidas
   de direção, Dash, combate, câmara, checkpoint, morte/reaparecimento, L3,
   L5, arena, Coração Putrefacto, projéteis. Olhar em especial para o
   **reaparecimento** e para a **textura do screen shake** (agora amostrado a
   60 Hz). Detalhe:
   [`docs/execution_8_1b_physics_interpolation.md`](docs/execution_8_1b_physics_interpolation.md).

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
