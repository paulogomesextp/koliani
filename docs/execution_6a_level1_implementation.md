# Execution 6A — Level 1 Approved Visual Build

## Result

**PARTIAL VISUAL BUILD / PRODUCTION ASSETS MISSING**

**HUMAN REVIEW REQUIRED**

O Level 1 recebeu o panorama aprovado da Região I, incluindo Heart Tree,
cascatas, ruínas, floresta profunda e foreground baked. A integração é um
crop determinístico da referência 08, sem texto, moldura, personagens
incidentais, remoção de fundo ou pixels inferidos. O módulo continua exclusivo
do Level 1, não contém física e mantém rollback por `ativo = false`.

Não foram produzidos tiles, props, inimigos, HUD ou VFX separados: as pranchas
correspondentes são RGB compostas e não oferecem alpha/source layers seguros.
Os elementos legacy necessários ao gameplay foram preservados.

## Visual sources verified

Todos os ficheiros foram abertos e inspecionados visualmente em 10 de setembro
de 2026. Todos têm `1536×1024`, modo `RGB / 24 bpp`, e são legíveis.

| ID | Path | SHA-256 | Domínio observado |
|---|---|---|---|
| 01 | `C:\Projetos\koliani\Koliani_1.0_Master_Package_v2\references\approved\01_KOLIANI_VISUAL_AUTHORITY_v1_1.png` | `91c298010a3e606d12f73136e41667c6e82ac9c24b577e04e4e4093431408a5f` | identidade, idade aparente, proporções, cabelo, roupa e silhueta da Koliani |
| 08 | `C:\Projetos\koliani\Koliani_1.0_Master_Package_v2\references\approved\08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png` | `840cfd8241a54f7bab0be58ab96892eba8438517888e490587451339b23263a7` | panorama, Heart Tree, profundidade, layers, cascatas e foreground |
| 09 | `C:\Projetos\koliani\Koliani_1.0_Master_Package_v2\references\approved\09_PRODUCTION_PACK_v7_UI_HUD_MAPS_MENUS.png` | `264d6def7c961ea04635754ae91f33f81c891a6eae6eddaf0b1420f094a7aba9` | HUD, ícones, barras, menus e mapas; números/texto são exemplos baked |
| 10 | `C:\Projetos\koliani\Koliani_1.0_Master_Package_v2\references\approved\10_PRODUCTION_PACK_v8_ENV_LIGHT_ATMOSPHERE.png` | `86087e523990a882f2c23c98596265e5afbd5567dfd0c3be02399ecdf0b7b6f6` | tiles, plataformas, ruínas, vegetação, iluminação e atmosfera |
| 11 | `C:\Projetos\koliani\Koliani_1.0_Master_Package_v2\references\approved\11_PRODUCTION_PACK_v9_NARRATIVE_CINEMATICS.png` | `3c3c7279f48dc91b487d5fc989f0d3375d08a2e5c6c354e8537761c046e6bcf8` | framing narrativo, cutscenes e objetos; não obriga cinematic no L1 |
| 12 | `C:\Projetos\koliani\Koliani_1.0_Master_Package_v2\references\approved\12_PRODUCTION_PACK_v10_GAMEPLAY_VFX_SFX_POLISH.png` | `6eea95ba9816509fa4f520b1aeeeda17b0246c56576c57af4ef0a15c65ccc221` | feedback, VFX, SFX, combate e polish; personagens são incidentais |

## Level 1 visual completion

| Categoria | Old state | Approved source | Production asset / integration | Status |
|---|---|---|---|---|
| Background | 5C procedural + legacy | 08 | panorama lossless integrado em toda a rota | **INTEGRATED / HUMAN REVIEW REQUIRED** |
| Parallax | Atmosfera legacy | 08 | layers RGBA separados inexistentes; legacy preservado | **PRODUCTION ASSET MISSING** |
| Heart Tree | landmark procedural 5C | 08 | landmark aprovado baked no panorama | **INTEGRATED** |
| Platforms | legacy mossy stone + máscara plana 5C | 10/08 | máscara removida; plataforma/collision legacy preservada | **PRODUCTION ASSET MISSING** |
| Ground materials | legacy | 10 | sem tiles RGBA repetíveis seguros | **PRODUCTION ASSET MISSING** |
| Ruins | formas 5C + legacy | 08/10 | ruínas approved baked no panorama; props separados em falta | **PARTIAL** |
| Vegetation | formas 5C + legacy | 08/10 | vegetação approved baked; peças RGBA em falta | **PARTIAL** |
| Roots/Rocks | formas 5C + legacy | 10 | formas genéricas 5C removidas; gameplay legacy mantido | **PRODUCTION ASSET MISSING** |
| Waterfalls | legacy/ausente no target | 08/10 | waterfalls approved baked no panorama | **INTEGRATED** |
| Foreground | grande raiz procedural 5C | 08 | foreground approved baked; layer alpha separado em falta | **PARTIAL** |
| Lighting | 5C + Level 1 legacy | 08/10 | 3 luzes seletivas preservadas | **LEGACY TEMPORARY** |
| Fog | 5C + Atmosfera legacy | 08/10 | 3 faixas leves preservadas | **LEGACY TEMPORARY** |
| Lanterns | candeeiros/tochas existentes | 10 | sem novo asset; iluminação quente preservada | **LEGACY TEMPORARY** |
| Corruption | amostra procedural 5C | 08/10 | magenta/violeta escuro separado da Shadowblade | **LEGACY TEMPORARY** |
| Environment VFX | 34 partículas + fog | 08/12 | sistema existente preservado; textura approved em falta | **LEGACY TEMPORARY** |
| Props | cogumelos/checkpoints/props legacy | 10 | sem sprites RGBA aprovados | **PRODUCTION ASSET MISSING** |
| Enemies | 2 goblins legacy + Ghorak | docs/12 | nenhum monstro incidental da board foi promovido | **PRODUCTION ASSET MISSING** |
| Enemy VFX | feedback legacy | 12 | sem frames/VFX aprovados separáveis | **PRODUCTION ASSET MISSING** |
| HUD | HUD atual + skin 5C | 09 | barras preservadas; sample text/números não integrados | **LEGACY TEMPORARY** |
| Audio | áudio/ambiente atual | 12 | direção aprovada não contém ficheiros de produção | **PRODUCTION ASSET MISSING** |

## Assets produced

Fonte integral para os três assets:
`C:\Projetos\koliani\Koliani_1.0_Master_Package_v2\references\approved\08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png`.

| Asset | Método | Final path | Validation |
|---|---|---|---|
| panorama + Heart Tree | crop lossless `(18,97,952,247)` | `assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_heart_tree.png` | RGB `952×247`, SHA-256 `7d174c8ed7a48bba6e85aec4567cbe512852f40a0eb4a9cc97c51328f0e75839` |
| left cap | crop lossless `(0,0,320,247)` do panorama | `assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_left_cap.png` | RGB `320×247`, SHA-256 `c8ae71e993e7b9ddca52dfd3159956ad3b767f386bf2413c0a90af17fc5d4e4f` |
| right cap | crop lossless `(630,0,322,247)` do panorama | `assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_right_cap.png` | RGB `322×247`, SHA-256 `1acaa1fa8472396b1ec4859571d383932475f4a3d10a008597a1d963fcb9837d` |

O gerador reproduzível é `tools/produce_execution_6a_assets.gd`.

## Legacy removed

- céu/gradientes e lua procedurais do target 5C;
- Heart Tree genérica procedural;
- máscaras planas de pedra/musgo sobre `ChaoInicio` e `Passo1..3`;
- arcos, raízes e vegetação vetoriais genéricos do midground 5C;
- raiz gigante e moldura vetorial do foreground 5C.

## Legacy retained

- `Atmosfera` e o parallax legacy, por falta de layers RGBA aprovados;
- arte mossy-stone de `Plataforma` e materiais de chão, sem tocar collision;
- candeeiros, tochas, fog, partículas, corrupção e luzes seletivas existentes;
- cogumelos, perigos, checkpoints, porta, coletáveis e restantes props;
- `EliteGoblin`, `GoblinBaixa` e respetivo feedback, necessários ao gameplay;
- sprite/rig atual de Ghorak;
- HUD e áudio atuais.

## Production asset missing

- layers de parallax, foreground e fog com alpha real;
- tiles Hybrid repetíveis de terreno/plataformas, edges e moss overlays;
- ruínas, arcos, vegetação, roots, rocks, lanterns, corruption props e VFX
  como sprites separados;
- inimigo “criatura infectada que salta dos troncos” com identidade, frames e
  animações aprovados;
- replacement de produção de Ghorak e VFX de inimigo;
- componentes HUD exportados sem sample text/números/personagem incidental;
- ficheiros finais de ambience/SFX.

## Enemies

- **Approved enemies:** criaturas infectadas que saltam dos troncos; Ghorak,
  o Guardião Raiz.
- **Legacy:** `EliteGoblin` (carga), `GoblinBaixa` (patrulha), sprite atual de
  Ghorak.
- **Produced / integrated:** nenhum; não existe fonte limpa aprovada.
- **Missing:** design visual/frames da criatura infectada e replacement de
  produção de Ghorak.

## Koliani

- 5G.1 preserved: **YES**.
- scale: `0.82`; offset Y: `-15.170732`; pivot: `(80,90)`; feet: preserved.
- known source clipping: `run_03`–`run_09`, **PRODUCTION FRAME REPLACEMENT REQUIRED**.
- readability: tecnicamente visível nas oito capturas; qualidade subjetiva é
  **HUMAN PLAYTEST REQUIRED**.

## Tests

- targeted 6A: **PASS**, 29 nós, 3 `PointLight2D`, 1 `CPUParticles2D`/34 partículas;
- Koliani 5G.1: **PASS**;
- Movement + Camera 4A: **PASS**;
- alcance: **PASS**, 20 plataformas, porta alcançável;
- full suite: **PASS**, “todos os testes passaram”;
- renderer: **PASS**, Vulkan Forward Mobile, NVIDIA RTX 5070, oito pontos;
- checkpoint, exit, enemies, save/session e localization: preservados pela
  regressão dirigida e suite completa; sensação humana não automatizada;
- performance: 29 nós no módulo (versus 406 no 5C), 3 luzes, 1 emissor;
  três texturas únicas usam ~1.50 MiB RGBA descomprimido e ~0.63 MiB em PNG;
- Web/Android em dispositivo: **DEVICE VALIDATION REQUIRED**;
- `git diff --check`: **PASS**.

## Preview

- `C:\Projetos\koliani\work\execution_6a\preview\level1_6a_review.png`
  (`2560×720`, oito capturas reais).
- `C:\Projetos\koliani\work\execution_6a\preview\level1_before_after.png`
  (`2560×720`, comparação de capturas reais).

## Git

- branch: `master`, inicialmente alinhada com `origin/master`;
- commit: lote único 6A deste documento, sem incluir alterações herdadas;
- push: não executado; a proteção de segurança exige autorização explícita
  para publicar este lote em `origin/master`;
- force push: não usado;
- Game Master conflicts: nenhum conflito remoto observado.

## Next step

### READY FOR HUMAN PLAYTEST

- confirmar escala/legibilidade da Koliani, contraste de plataformas,
  continuidade visual nos caps, leitura do Heart Tree e percurso completo;
- validar Web/PWA e Android em hardware real.

### APPROVED DESIGN / PRODUCTION ASSET MISSING

- produzir os exports separados listados acima sem reabrir design.
