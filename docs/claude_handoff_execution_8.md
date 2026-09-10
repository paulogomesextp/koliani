# Handoff Claude — após Execution 8

Começar por `docs/retomar_aqui.md` e
`docs/execution_8_real_game_production_integration.md`. Paulo/Game Master tem
autoridade semântica e de produto final.

## Estado atual

- branch `master`; baseline inicial Execution 8: `d9b608f717f9ea89171060975ac6901c34012275`;
- commit final: o commit que contém este documento; confirmar com
  `git rev-parse HEAD` e `git rev-parse origin/master`;
- estado: **PARTIAL PASS — REAL RUNTIME TECHNICALLY VALIDATED / HUMAN REVIEW REQUIRED**;
- cânone: 100 níveis, 20 regiões × 5; Região I L1–L5 é a primeira Vertical
  Slice; Koliani tem 16 anos; mãe Elara; Shadowblade; Hardcore fora de 1.0;
- não iniciar Região II; Android/iOS fora de scope;
- referência aprovada não é automaticamente asset de produção; não improvisar
  nem gerar arte para preencher gaps.

## Runtime atual

`project.godot` abre `scenes/ui/MenuInicial.tscn` →
`scenes/ui/MapaMundo.tscn`/`SeletorNiveis.tscn` → `scenes/Main.tscn` → cena
em `EstadoJogo.NIVEIS`. L1–L5 são as cinco cenas autorais conhecidas. Todas
instanciam `scenes/actors/Koliani.tscn`/`scripts/koliani.gd` com os 44 frames
SAFE, incluindo `run_03`–`run_09` corrigidos. Preservar escala 0,82, offset
-15,170732, pivot (80,90), canvas 160×96, baseline Y=90, movimento, câmara e
colisões.

Combate 3-hit/aéreo/Dash/hit-stop/knockback/reação está ativo. L1–L4 usam
guardiões; L5 usa `ChefeCoracaoPutrefacto.tscn`, fase 2, morte, reward e reload
idempotente. Arte das criaturas/guardiões/boss continua legacy.

L1–L5 ligam o panorama/Heart Tree aprovado de 6A. L2–L5 usam a variante
`apenas_panorama_aprovado`, mantendo gameplay e assets específicos legacy. O
kit modular regional é tecnicamente válido, mas tem origem ImageGen e aguarda
aprovação visual; não o promover automaticamente.

Menu, seletor, HUD e pausa usam a arquitetura real já existente. O subtítulo
é Elara nos seis idiomas. Em release não há entrada para `DevMode`; `DevBarra`
só nasce em debug + modo dev, portanto BOSS TEST/TESTAR OUTRO NÍVEL/FLYMODE
ficam escondidos. Preservar a funcionalidade de debug em builds debug.

## Entrega

- Windows: `build/windows/Koliani.exe`, smoke/capturas reais PASS;
- Web/PWA: `build/web/index.html`, Chrome/HTTP/service worker PASS;
- cache: `1789065387|5837615`;
- Windows/Web exportados do mesmo source state;
- prova: `work/execution_8/real_runtime/region1_runtime_contact_sheet.png`;
- relatório contém hashes, matriz runtime e gaps completos;
- `jogar.bat` e o atalho do Desktop apontam para o EXE canónico.

## Pendências

Faltam produção final de: run_brake/land; combate; plataformas; layers L2–L5;
props; inimigos/guardiões; boss/reward; HUD/menu/seletor; VFX; SFX;
music/soundscape; narrativa/cinemáticas. Legacy é fallback, não aprovação.

Obrigatório: **HUMAN VISUAL REVIEW, HUMAN COMBAT FEEL REVIEW, HUMAN BALANCE
REVIEW, HUMAN PLAYTEST e DEVICE VALIDATION REQUIRED**. A automação nativa de
apps Windows estava indisponível; não declarar a cadeia manual humana PASS.

`project.godot` e vários master packages/assets/tools não rastreados já eram
trabalho local anterior. Foram preservados e não pertencem ao commit 8.
