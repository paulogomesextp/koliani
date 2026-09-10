# Execution 8 Master — Real Game Production Integration

Data: 10 de setembro de 2026

Baseline: `d9b608f717f9ea89171060975ac6901c34012275`

Estado: **PARTIAL PASS — REAL RUNTIME TECHNICALLY VALIDATED / HUMAN REVIEW REQUIRED**

## Resultado

A cadeia real foi traçada desde `build/windows/Koliani.exe`. O export release
carrega `MenuInicial.tscn`, segue para `MapaMundo.tscn`/`SeletorNiveis.tscn` e
entra em `Main.tscn`, que instancia a cena selecionada e acrescenta HUD e
pausa. Os cinco níveis da Região I usam agora o rig validado atual da Koliani
e o panorama aprovado da Floresta Corrompida. O boss regional, combate,
checkpoints, progressão e reward existentes estavam ativos e foram
preservados.

Os controlos `BOSS TEST`, `TESTAR OUTRO NÍVEL` e `FLYMODE` deixaram de ter uma
entrada no export release. `DevMode` só é visível/acionável em debug e
`DevBarra` tem uma segunda guarda própria. O menu usa agora o nome canónico
Elara nos seis catálogos.

A prova foi obtida no executável Windows exportado, em dados de aplicação
isolados para não ler nem alterar o save do Game Master. A automação nativa de
aplicações Windows não está disponível nesta sessão, por isso a navegação
humana contínua menu → campanha → boss não pode ser certificada. As cenas reais
do produto e o gameplay exportado foram capturados por argumentos de prova
invisíveis; não são mockups nem cenas reconstruídas.

## Runtime truth

| Feature | Recurso canónico | Recurso real | Match | Estado/ação |
|---|---|---|---|---|
| EXE | `build/windows/Koliani.exe` | mesmo | Sim | release regenerado e lançado |
| main scene | `scenes/ui/MenuInicial.tscn` | mesmo, por `project.godot` | Sim | ativo |
| campanha | `scenes/ui/MapaMundo.tscn` | mesmo | Sim | ativo |
| seletor | `scenes/ui/SeletorNiveis.tscn` | mesmo, dentro do mapa | Sim | ativo |
| loader | `scenes/Main.tscn` + `scripts/main.gd` | mesmo | Sim | ativo |
| L1 | `scenes/levels/Floresta_Putrefata.tscn` | `level_001` em `EstadoJogo.NIVEIS` | Sim | atual |
| L2 | `scenes/levels/Pantano_dos_Sussurros.tscn` | `level_002` | Sim | atual |
| L3 | `scenes/levels/Ninho_da_Viuva_Negra.tscn` | `level_003` | Sim | atual |
| L4 | `scenes/levels/A_Arvore_que_Chora.tscn` | `level_004` | Sim | atual |
| L5 | `scenes/levels/Coracao_da_Floresta.tscn` | `level_005` | Sim | atual |
| player | `scenes/actors/Koliani.tscn` | mesmo em L1–L5 | Sim | 44 frames atuais ativos |
| combate | `scripts/koliani.gd` / `HitboxAtaque` | mesmos | Sim | combo/aéreo/Dash ativos |
| inimigos | cenas concretas + `scripts/demonio_base.gd` | mesmos | Sim | funcional; arte legacy |
| boss | `scenes/actors/ChefeCoracaoPutrefacto.tscn` | nó `Chefe` de L5 | Sim | fase 2/reward ativos |
| HUD | `scenes/ui/HUD.tscn` + `scripts/ui.gd` | adicionado por `Main` | Sim | atual parcial |
| pausa | `scenes/ui/Pausa.tscn` | adicionado por `Main` | Sim | atual parcial |
| dev UI | `scenes/ui/DevBarra.tscn` | só debug + `modo_dev` | Sim | escondida em release |

Não foi encontrada uma segunda campanha ativa. Existem ferramentas, cenas de
teste e arte legacy no repositório, mas o fluxo acima é o único alcançado pelo
menu normal. Os argumentos de prova registam build, main scene, level ID,
level scene, player scene e boss ID no log do runtime.

## Materiais e classificação

As doze autoridades em
`Koliani_1.0_Master_Package_v2/references/approved/01...12` existem, são
legíveis e foram verificadas por caminho absoluto, dimensões, modo e SHA-256.
São **APPROVED / FROZEN DESIGN**, não automaticamente sprites jogáveis.

| Autoridade | Dimensões / modo | SHA-256 |
|---|---|---|
| 01 | 1536×1024 RGB | `91C298010A3E606D12F73136E41667C6E82AC9C24B577E04E4E4093431408A5F` |
| 02 | 1536×1024 RGB | `78788A0327347767BC2D94B08B75FE3F45A80FE48FE18AEAB501873F4BDA83B6` |
| 03 | 1536×1024 RGB | `A2D91FC8BFF998398F761D92F0F948C0DCE6425944A2FBE6E409EE6355CAE319` |
| 04 | 1536×1024 RGB | `FC04824DA1C88340BF3DEDC5EF3BEDB89BACC8E17BB0B180252D19E4B34227A7` |
| 05 | 1536×1024 ARGB | `5056B726728328F1F88092F26456FEA8B9785F7E57D89C6C2976485D8C83980D` |
| 06 | 1774×887 ARGB | `AFBD74469444AD01883EA8069EC64B818E47612DA481BECFE32581F883A324B3` |
| 07 | 1536×1024 ARGB | `6564982D4CCFAD84D0A5F6D0E73196785AFCFF7AC8CD218DD27F066F883FE8C6` |
| 08 | 1536×1024 RGB | `840CFD8241A54F7BAB0BE58AB96892EBA8438517888E490587451339B23263A7` |
| 09 | 1536×1024 RGB | `264D6DEF7C961EA04635754AE91F33F81C891A6EAE6EDDAF0B1420F094A7ABA9` |
| 10 | 1536×1024 RGB | `86087E523990A882F2C23C98596265E5AFBD5567DFD0C3BE02399ECDF0B7B6F6` |
| 11 | 1536×1024 RGB | `3C3C7279F48DC91B487D5FC989F0D3375D08A2E5C6C354E8537761C046E6BCF8` |
| 12 | 1536×1024 RGB | `6EEA95BA9816509FA4F520B1AEEEDA17B0246C56576C57AF4EF0A15C65CCC221` |

- Koliani 6B: **IMPLEMENTED AND ACTIVE IN REAL RUNTIME**. 44/44 frames SAFE;
  `run_03`–`run_09` corrigidos; escala `0,82`, offset `-15,170732`, pivot
  `(80,90)`, canvas `160×96` e baseline Y=90 preservados.
- Panorama/Heart Tree/caps de 6A: **PRODUCTION READY AND INTEGRATED**. São
  crops determinísticos da autoridade 08 e aparecem em L1–L5.
- Assets UI atuais usados por `scripts/ui.gd`: **IMPLEMENTED AND ACTIVE**;
  continuam uma solução parcial, não equivalem à prancha 09 completa.
- Kit modular de 12 sprites em `production/`: **TECHNICALLY VALIDATED / HUMAN
  VISUAL REVIEW REQUIRED**. A fonte declarada é `_source/imagegen_v1`; não foi
  promovido para L2–L5 nesta execução e a fonte é excluída dos exports.
- Pranchas 01–12: **REFERENCE ONLY** quando não há extração determinística
  validada correspondente.
- Plataformas, props, inimigos, guardiões e boss visíveis: **LEGACY TO
  REPLACE**, mantidos porque não existe substituição de produção aprovada.

O validador de produção continua a indicar `PASS=0 FAIL=16` para o contrato
completo, o kit regional indica `12 presentes / 0 fails / 12 warnings` e o
pacote Koliani indica master PASS mas lote final `0/40`. Isto é falta de asset,
não falta de direção aprovada.

## Player-facing

Resposta à observação do Game Master: **PARTIAL**. Ao lançar o EXE nota-se de
imediato o menu cinematográfico sem entrada de desenvolvimento, “Free Elara”,
o seletor regional, a Koliani corrigida e o panorama/Heart Tree coerente em
L1–L5. Combate e Coração Putrefacto aparecem no runtime real.

Ainda parecem antigos: plataformas/tiles, pequenos props, inimigos e
guardiões, forma visual do boss, parte do HUD/pausa, VFX/SFX e diferenciação
ambiental específica entre L2–L5. A razão é objetiva: só existem referências
aprovadas ou material experimental, não sprites/layers/frames finais
determinísticos. Não se inventaram pixels para esconder essa falta.

Não ficou desconectada nenhuma substituição simultaneamente validada,
aprovada e aplicável sem decisão humana. O kit ImageGen é validado apenas
tecnicamente, portanto não satisfaz o gate de aprovação visual.

## Combate e boss

- ataque base e combo de três golpes: ativo em `scripts/koliani.gd`;
- ataque aéreo singular: ativo;
- Dash e cancel: ativos; desbloqueio preservado em L5;
- hit-stop, avanço/knockback e reações: ativos nos contratos reais;
- legado: frames finais específicos, VFX de impacto e SFX polidos em falta;
- Coração Putrefacto: ativo em L5, fase 2 a 50%, morte e baú regional;
- reward: idempotente e recompõe a saída após reload.

## Validação

- import/export Godot 4.7.2: PASS, com avisos conhecidos dos dez AppleDouble
  `._monster-*.wav` de 82 bytes;
- suite completa: PASS;
- Execution 7 targeted: PASS;
- combate runtime: PASS;
- piloto visual Koliani L1–L5: PASS;
- Level 1 6A: PASS;
- source of truth/generator safety: PASS;
- jornada 1–100: PASS, sobreposição média 0,226;
- alcance: 100 níveis, 1 fora do crivo por desenho, 0 portas inalcançáveis;
- L4 raiz elevatória e câmara da seiva: PASS;
- L5 boss/reward/reload: PASS;
- Windows export: PASS;
- screenshots do EXE final: PASS;
- Web/PWA export e HTTP: PASS; HTML, JS, WASM, PCK, manifest, ícones, service
  worker e offline page responderam 200;
- Chrome startup: PASS, menu atual visível e zero logs warning/error;
- PWA cache: `1789065387|5837615`.

Os falsos negativos dos gates de boss/baú vinham do save local já conter o
boss derrotado. Os verificadores isolam agora esse estado em memória e não
gravam o progresso.

## Entrega e rastreabilidade

- Windows: `C:\Projetos\koliani\build\windows\Koliani.exe`;
- SHA-256 Windows: `FFD58E4961D94F50E4BE1609184F69A2E6E87C83C96D5D4708244669BCA69F59`;
- Web: `C:\Projetos\koliani\build\web\index.html`;
- PCK SHA-256: `DFEFCE47D452A345E7E7C8F3A7E3344EAA6CAB02C4D32399FBFCD628DF43FB8E`;
- WASM SHA-256: `FC74679E3B97F76878947FCD4FBE1268CBFA6188182A2E33BBC3F5DC9BFA57D0`;
- `jogar.bat`: `C:\Projetos\koliani\jogar.bat` → `build\windows\Koliani.exe`;
- atalho: `C:\Users\paulo\Desktop\Koliani (testar).lnk` → `jogar.bat`, sem
  argumentos, working directory no repositório;
- Windows e Web: mesmo source state;
- os presets release excluem `work`, `tools`, `tests`, `docs`, fontes `_source`
  e ficheiros AppleDouble dos pacotes de jogador;
- Android/iOS: fora de scope.

## Evidência

Em `work/execution_8/real_runtime/`: `main_menu_current_windows.png`,
`region_select_current_windows.png`, `level1_current_windows.png` até
`level5_current_windows.png`, `combat_current_windows.png`,
`boss_current_windows.png` e `region1_runtime_contact_sheet.png`.

## Gaps de produção

- **Koliani:** frames finais limpos de `run_brake` e `land`; lote contratual
  completo 40/40.
- **Combate:** frames finais de combo/aéreo/Dash, impactos e leitura de hit.
- **Plataformas:** tiles Hybrid aprovados, cantos/remates/variação por nível.
- **Ambiente:** layers alpha/parallax específicos L2–L5, fog/lighting final,
  diferenciação interna sem abandonar o biome.
- **Props:** raízes, rochas, vegetação, ruínas, lanternas e interativos finais.
- **Inimigos:** sprites/animações finais das criaturas e quatro guardiões.
- **Boss:** modelo/animações/telegraphs finais do Coração Putrefacto e baú.
- **HUD:** health/energia/moeda/equipamento e boss bar finais.
- **Menu:** widgets/tipografia/estados finais derivados da autoridade 09.
- **Region select:** cartões, locks, completion e boss card finais.
- **VFX:** Shadowblade violeta limpa, corrupção escura, Dash/hit/death/reward.
- **SFX:** espada, impactos, inimigos, boss, UI e reward.
- **Music/soundscape:** floresta, variações L1–L5 e boss final.
- **Narrativa/cinemáticas:** assets finais derivados da autoridade 11.

## Stop

**HUMAN VISUAL REVIEW REQUIRED, HUMAN COMBAT FEEL REVIEW REQUIRED, HUMAN
BALANCE REVIEW REQUIRED, HUMAN PLAYTEST REQUIRED e DEVICE VALIDATION
REQUIRED.** Não iniciar Região II. O próximo trabalho só pode ser: correções
pedidas pela revisão humana, criação/aprovação dos assets acima, ou correção
técnica suportada por nova evidência.
