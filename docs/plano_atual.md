# Plano atual — Execution 5B

Estado: **TECHNICAL PASS / HUMAN PLAYTEST REQUIRED**.

## Objetivo

Criar e integrar no Level 1 o prototype visual `Koliani Premium Pixel Art v1`
da direção **HYBRID CINEMATIC 2D**, sem adaptar gameplay à arte.

## Direção visual registada

- personagens, inimigos e bosses: Premium Pixel Art;
- ambientes: Cinematic Layered Presentation;
- UI: Cinematic Dark-Fantasy Minimal;
- estado: prototype da Koliani pendente de aprovação humana.

## Âmbito executado

- nova folha-mestra e tiras 160×96 para a Koliani;
- idle, run, jump, fall, dash, basic attack, hurt e death;
- fallbacks coerentes para landing, crouch, wallslide, ledge hang, double
  jump, roll, defesa e projectile cast;
- propriedade visual por instância em `koliani.gd`;
- ativação exclusiva na instância da Koliani do Level 1;
- rig Shadowblade anterior preservado como default e rollback;
- contraste cosmético exclusivo do prototype sob a luz do Level 1.

## Invariantes preservados

Movement, camera, colisão 20×44, hitbox 30×34 em `(23,-4)`, tempos de
combate, save v5 e progressão não foram alterados. `scripts/movimento.gd` não
foi tocado nesta execução.

## Evidência

- Execution 5B targeted: PASS;
- Level 1 smoke: PASS;
- Movement + Camera targeted: PASS;
- suite completa: 74/74 PASS;
- localização: 701 chaves × 6 locales PASS;
- captura OpenGL real: `work/execution_5b/koliani_premium_level1.png`;
- Windows dev build:
  `build/windows/Koliani-Execution-5B-Hybrid-Character-dev.exe`;
- `git diff --check`: PASS.

## Limites

- os golpes 2–4 reutilizam o prototype visual de basic attack, com fps
  próprios para respeitar 0,20/0,30/0,19 s;
- os estados não prioritários são fallbacks do mesmo rig;
- a animação de death existe, mas o reload/transição atual pode impedir a sua
  reprodução completa; o fluxo não foi alterado;
- qualidade estética, leitura em movimento e sensação geral dependem de
  playtest humano.

Não iniciar ambiente Hybrid, UI, inimigos, bosses, Visual Target seguinte ou
Execution 4C a partir deste plano.
