# Prioridades — Koliani

## Agora

000000. **9C FEITA — REGION I ENVIRONMENT GATE CLOSED (v0.15.18).** L1–L5 usam
   o kit de produção derivado das pranchas 08/10 (terreno, props, corrupção,
   4 planos de parallax, névoa); o terreno CC0 já não aparece na Região I.
   **Seguinte: 9D — inimigos e guardiões da Região I** (não iniciada).
   Nada pendente de decisão do Game Master. Opcional (seria design novo ou
   outra execução): arte própria para os objectos de gameplay da região (água
   venenosa, checkpoints); um corpo de terreno maior que o mosaico de 44 px da
   prancha 10. Backlog técnico mantido: excluir `assets/**/manifest.json` dos
   exports. Relatório: `docs/execution_9c_region1_environment_kit.md`.

00000. **9B.4 FEITA — KOLIANI PRODUCTION GATE CLOSED (v0.15.17).** Todos os
   estados da Koliani na Região I saem do Golden Set; o premium_v1 e a 5G já não
   aparecem. **Pendente de decisão do Game Master (opcional, é design novo):**
   poses próprias para morte deitada, rebordo de braços por cima e golpes 2–4
   do combo. **Seguinte: 9C — kit de ambiente da Região I.** Backlog técnico:
   excluir `assets/**/manifest.json` dos exports; CI vermelha em "Nascer no
   checkpoint sem ficar preso" (anterior à 9B.3). Relatório:
   `docs/execution_9b4_full_character_package.md`.
   *(As entradas 0000/0000b/000/00a abaixo estão resolvidas pela 9B.1–9B.4.)*

0000. **9B.1 BLOQUEADA: o Golden Set da Koliani precisa de quem o desenhe.**
   O Paulo resolveu CONF-01 para **Route B** (arte de raiz). Um agente sem
   ferramenta de imagem não consegue produzir 33 frames de pixel-art premium
   com identidade consistente — desenhar por código dava as aproximações
   poligonais que a 9A proibiu. **Falta decidir quem desenha.**
   Está tudo o resto pronto: contrato de canvas, pastas, manifestos, validador
   provado. Ver `docs/production_art_gate_9b1_golden_set.md`.

0000b. **APROVAR O CONTRATO DE CANVAS antes de alguém desenhar.** 128×128,
   personagem a 64 px, pivot (64,104), baseline 103, escala Godot 1,0, offset
   (0,−18). Mantém o tamanho aparente de hoje, por isso não mexe em colisão,
   câmara, física nem tempos. Mudá-lo depois custa os 33 frames todos.

000. **DECISÃO DO GAME MASTER PENDENTE (CONF-01, Execution 9A): o 9B extrai
   das pranchas ou desenha de raiz?** O `production_contract.json` diz que
   «nenhum frame ou píxel é extraído ou reciclado» das pranchas, mas as 7
   animações que estão no `.exe` aprovado (`koliani_visual_pilot_5g`) foram
   extraídas das pranchas 05/06. Sem esta decisão o 9B não arranca. As duas
   rotas estão em `docs/production_art_gate_asset_gap_map.md`.

00a. **LACUNA CENTRAL MEDIDA (9A): na Região I vêem-se duas Kolianis.** Parada
   e a correr usa a 5G (cabelo solto, preto/vermelho, sem VFX colado); a
   atacar, dash e morte usa a `koliani_premium_v1`, que tem **rabo-de-cavalo**,
   cabelo roxo e **o arco do golpe pintado dentro do frame**. Viola três
   cláusulas congeladas. `tools/validate_assets.py` → PASS=0 FAIL=16. É a
   causa técnica do «ainda parece antigo».

00b. **WINDOWS PERFORMANCE GATE = FECHADO, APROVADO POR HUMANO.** `master`
   avançou por fast-forward para `6beb05b` e foi empurrado; `origin/master`
   está agora em `423fde7` (commits posteriores, `6beb05b` é antepassado).
   **Mas o `.exe` aprovado foi exportado de `05f050e` (8.1C)** — não traz a
   correção 8.1E. Reexportar antes de dar a 8.1E por validada no binário.
   A `master` do checkout principal ficou em `b2fd8a0` de propósito (tem
   `project.godot` sujo + arte de produção por versionar): `git pull
   --ff-only` só depois de arrumar isso.

00c. **RISCO: arte de produção só existe na máquina do Paulo.** O kit modular
   de 12 peças da Região I e os 449 ficheiros de
   `work/koliani_extraction_recovery_medium/` não estão versionados (e `work/`
   está no `.gitignore`). Um `git clean` apaga trabalho insubstituível. As 12
   pranchas aprovadas (~29 MB) também estão por versionar — comitá-las é
   praticável, mas exige acrescentar `Koliani_1.0_Master_Package_v2/**` ao
   `exclude_filter` dos presets no mesmo gesto.

0. **VALIDAR A JOGAR: o congelamento do save está corrigido (Execution 8.1E).**
   `guardar()` passou de **2047 ms para 9,2 ms** — cabe num frame. A causa era
   `ProgressionIDs.identidades()` a reler e parsear o `level_manifest.json`
   **1312 vezes por gravação**; agora tem cache. Não era o antivírus (a 8.1C
   enganou-se): o disco custa ~2 ms. `build/windows/Koliani.exe` está
   construído e arranca limpo. **Falta o Paulo jogar**: passar num checkpoint,
   levar projétil, levar dano repetido, morrer/reaparecer — e confirmar que os
   dois segundos desapareceram. Ver `docs/execution_8_1e_causa_do_congelamento.md`.

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

1b. **KOLIANI GOLDEN SET — PRODUCTION INTEGRATED (Execution 9B.3, v0.15.16).**
   Ativo em L1–L5 no Windows e na Web. Os 8 frames baixos foram aceites como
   pose; a regra dos 59 px é só alerta de revisão. **A seguir: pacote completo da
   Koliani** (dash, roll, hurt, morte, crouch, wallslide, borda, djump, defesa,
   combos próprios e land), derivado do Golden Set. Até lá esses estados ficam
   no premium_v1. Ver `docs/execution_9b3_golden_set_integration.md`.

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
