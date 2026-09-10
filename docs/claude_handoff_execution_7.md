# Handoff Claude — após Execution 7

Este ficheiro permite retomar o Koliani sem depender do histórico da conversa.
Começar sempre por `docs/retomar_aqui.md` e pelo relatório
`docs/execution_7_region1_vertical_slice_completion.md`.

## Estado entregue

- repositório: `C:\Projetos\koliani`;
- branch intencional: `master`;
- baseline inicial: `cdfa85afb884e81278a523ef9e29ad4d645292b7` (Execution 6B);
- commit final: o commit que contém este documento; confirmar com
  `git rev-parse HEAD` e comparar com `origin/master`;
- Execution 7: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN REVIEW
  REQUIRED**;
- não iniciar Região II; Android/iOS fora de scope;
- movimento/câmara/collision e valores visuais congelados não foram alterados.

## Implementação relevante

- `scripts/koliani.gd`: combo 3-hit, janela de hitbox, deduplicação por golpe,
  aéreo singular, cancel ataque/Dash e gating de abilities tardias;
- `scripts/estado_jogo.gd`, `scripts/save_foundation.gd` e
  `scripts/progression_ids.gd`: campanhas novas L1 com run/jump/attack,
  `ability_dash`, apenas o quinto nível cria boss/reward regional; schema v5;
- L1–L4: nós `Guardiao`, sem baú/estado de boss; L5: Dash e Coração
  Putrefacto;
- `scripts/chefe_coracao_putrefacto.gd`: duas fases, transição a 50%;
- `scripts/nivel_com_chefe.gd`: caminhos separados para guardião e boss,
  incluindo proteção de callback diferido na troca de cena;
- manifesto/catálogo/i18n: `encounter_role`, “Guardião” em L1–L4, boss no L5;
- testes novos: `tools/verifica_execution_7.gd`,
  `tools/verifica_combate_execution_7.tscn` e casos na suite principal.

## Provas já executadas

- `tests/run_tests.tscn`: PASS;
- `tools/verifica_execution_7.gd`: PASS;
- `tools/verifica_combate_execution_7.tscn`: PASS;
- `tools/validar_level_source.py`: source + generator PASS;
- `tools/verifica_jornada.gd`: 100 níveis, TUDO OK;
- alcance global: zero portas inalcançáveis;
- L4 raiz elevatória e câmara de seiva: PASS;
- L5 spawn/checkpoints: PASS;
- `tools/verifica_bau.gd -- 4`: 10/10, reward idempotente/reload PASS;
- renderer OpenGL real: L1–L5, combate, boss fases 1/2 e reward PASS;
- Windows/Web exports: PASS local; Web recursos HTTP 200 e menu visível.

O loader isolado de 100 cenas não terminou em 90 segundos e foi interrompido;
não repetir sem diagnosticar o harness. A cobertura ficou assegurada pela
jornada 1–100, source validator, suite e load dirigido das cinco cenas
alteradas.

## Arte e gates

As pranchas aprovadas não são sprites de produção. Foram preservados visuais
legacy para inimigos/guardiões/boss e parte de L2–L5. Faltam frames limpos de
combate, arte final das criaturas e Coração Putrefacto, expansão Hybrid L2–L5
e polimento VFX/SFX.

Obrigatório antes de chamar a slice final:

- HUMAN VISUAL REVIEW REQUIRED;
- HUMAN COMBAT FEEL REVIEW REQUIRED;
- HUMAN BALANCE REVIEW REQUIRED;
- HUMAN PLAYTEST REQUIRED;
- device/browser final não foi certificado.

## Entrega local

- Windows: `build/windows/Koliani.exe`;
- atalho: `C:\Users\paulo\Desktop\Koliani (testar).lnk` → `jogar.bat`;
- Web/PWA: `build/web/index.html`;
- cache: `1789055058|5419303`;
- review: `work/execution_7/review/region1_vertical_slice_review.png`,
  `combat_review.png`, `region1_boss_review.png`.

## Cuidado com o working tree

`project.godot` e vários master packages/assets/tools não rastreados já
existiam antes da Execution 7. Não os apagar, reverter ou adicionar em massa.
Nunca usar `git add -A`, `git reset --hard`, `git clean` ou force push. Os
artefactos de `build/` e `work/` são ignorados; `BUILD_SOURCE.txt` contém a
rastreabilidade local.

Próximo passo recomendado: o Game Master jogar L1→L5→boss→reward nos dois
builds e registar problemas objetivos. Só depois corrigir regressões provadas
ou produzir os assets finais aprovados; não avançar para Região II.
