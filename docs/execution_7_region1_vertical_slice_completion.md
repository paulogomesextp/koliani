# Execution 7 — Region I Vertical Slice Completion

Data: 10 de setembro de 2026
Estado: **PARTIAL PASS — TECHNICALLY VALIDATED / HUMAN REVIEW REQUIRED**

## Autoridade e baseline

- início: `master`, `cdfa85afb884e81278a523ef9e29ad4d645292b7`, igual a
  `origin/master`; a Execution 6B está no histórico;
- `project.godot` e os ficheiros não rastreados já presentes foram tratados
  como trabalho local alheio e não integram este lote;
- movimento, câmara, colisões validadas, escala `0,82`, offset
  `-15,170732`, pivot `(80,90)`, canvas `160×96` e baseline `Y=90` não foram
  alterados;
- as autoridades 03, 07, 08, 10 e 12 foram abertas nos caminhos exatos e
  verificadas como pranchas compostas 1536×1024. Não foram promovidas a
  sprites de produção por recorte arbitrário.

## Classificação recuperada

1. **APPROVED / FROZEN DESIGN:** combate rápido e legível, combo de três
   golpes, ataque aéreo, Dash no nível 5, uma luta regional no quinto nível.
2. **IMPLEMENTED:** janelas ativas de ataque, deduplicação por golpe,
   cancelamento ataque/Dash, gating de progressão, guardiões L1–L4, Coração
   Putrefacto em duas fases e recompensa persistente.
3. **LEGACY TO REPLACE:** visuais funcionais de Ghorak, Morvanna, Rainha
   Aracnídea, Entrevane, inimigos comuns e parte da apresentação L2–L5.
4. **APPROVED DESIGN / PRODUCTION ASSET MISSING:** frames limpos de combate,
   arte final dos inimigos e do Coração Putrefacto, expansão ambiental
   Premium/Hybrid dos níveis 2–5 e polimento final de VFX/SFX.
5. **TECHNICAL BLOCKER:** nenhum bloqueio de runtime identificado no lote.
6. **NEW DESIGN DECISION REQUIRED:** nenhuma.

## A — Combate

- ataque base com antecipação, janela ativa explícita e recovery; hitbox
  desliga fora da janela e em cancel, dano ou morte;
- combo limitado a três golpes, com janela intencional de avanço e sem ciclo
  infinito;
- ataque aéreo singular, sem pogo implícito nem override permanente de
  gravidade;
- ataque pode cancelar Dash e Dash pode cancelar ataque sem deixar hitbox;
- Dash exige `ability_dash`; Dash aéreo continua a exigir
  `ability_dash_aereo`; salto duplo, pogo e projétil também ficaram sujeitos
  às habilidades respetivas;
- hit-stop, recuo, flash/reação, impacto visual/áudio e tremor pequeno já
  existentes foram preservados. Movimento e câmara: **UNCHANGED**.

## B — inimigos

O roster funcional recuperado para a Região I inclui inimigos comuns da
arquitetura `DemonioBase` (goblin, cogumelo/gosma e variantes colocadas nas
cenas) e os encontros guardiões Ghorak, Morvanna, Rainha Aracnídea e
Entrevane. A arquitetura existente já contém patrulha, carga e pressão à
distância conforme o comportamento configurado, telegraphs, contacto,
reação/knockback, flash, morte e essência.

Os encontros L1–L4 foram classificados no catálogo, manifesto e HUD como
**Guardião**. A morte do guardião abre apenas a saída: não grava boss regional
nem cria baú. Os IDs históricos de `boss_ref` foram preservados no manifesto
para compatibilidade de saves, agora acompanhados por `encounter_role`.

## C — níveis 1–5 e progressão

- L1: introdução com run/jump/ataque e encontros existentes;
- L2: desenvolvimento com guardião Morvanna;
- L3: combinação com guardião Rainha Aracnídea;
- L4: desafio; elevador de raiz, câmara de seiva, reencontro e arena passaram
  os bancos de percurso;
- L5: exame com Dash e Coração Putrefacto. Foram retirados dos L1–L4 os
  colecionáveis de progressão rápida incompatíveis com a autoridade atual.

Campanhas novas começam sem abilities persistidas; run, jump e ataque são o
kit intrínseco. `dash` é concedido no L5. Saves existentes não perdem
habilidades já obtidas. Schema v5 e stable IDs foram preservados.

Conclusão de L1–L4 já não cria boss/reward state. No L5:
`boss_level_005` → `reward_boss_chest_level_005`, com recolha única e reload
sem duplicação.

## D — boss regional

Identidade canónica recuperada: **Coração Putrefacto**. A implementação
reutiliza `ChefeBase` e `NivelComChefe`. Mantém ativação provocada, núcleo
atacável, raiz telegráfica, projéteis dirigidos, dano, morte e baú.

A luta foi normalizada para duas fases: fase 1 acima de 50%; fase 2 a 50% ou
menos. A segunda fase combina raízes, projéteis e pulso radial/variação de
gravidade já suportados pela arquitetura, com redução controlada do período e
telegraph, sem duplicar cegamente dano/velocidade. A plataforma principal da
arena permanece contínua.

## E — validação

- suite completa: **PASS** (`OK -- todos os testes passaram`);
- gate dirigido Execution 7, L1–L5/guardians/boss/alcance: **PASS**;
- runtime de combate (hitbox, deduplicação, aéreo e cancel): **PASS**;
- source of truth + generator safety: **PASS**;
- jornada 1–100: **PASS**; Região I L1–L5: todos `OK`;
- alcance global: **0 portas inalcançáveis** (um nível fora da conta pelo
  contrato histórico do verificador);
- L4 raiz elevatória: transporte/regresso **PASS**;
- L4 câmara de seiva e percurso até arena: **PASS**;
- L5 checkpoints: cinco ativos, respawn + saída + salto **PASS**;
- L5 boss/reward: 10/10 checks, incluindo dupla abertura e reload **PASS**;
- renderer real: OpenGL 3.3, NVIDIA RTX 5070; L1–L5, combate, boss fase 1,
  fase 2 e recompensa capturados sem erro fatal.

O loader isolado das 100 cenas não emitiu resultado dentro de 90 segundos e
foi interrompido; não foi usado como prova. A integridade relevante mantém-se
coberta pelo source validator, pela jornada 1–100, pela suite e pelo load
dirigido das cinco cenas alteradas.

Warnings de escrita `user://`, certificados e imports `._monster-*.wav` em
headless são limitações conhecidas do ambiente/sandbox, não falhas do runtime
alterado. Não houve profiling de device real.

## F — evidência de revisão

- `work/execution_7/review/region1_vertical_slice_review.png`;
- `work/execution_7/review/combat_review.png`;
- `work/execution_7/review/region1_boss_review.png`;
- frames fonte em `work/execution_7/review/shots/`.

Estado obrigatório: **HUMAN VISUAL REVIEW REQUIRED**, **HUMAN COMBAT FEEL
REVIEW REQUIRED**, **HUMAN BALANCE REVIEW REQUIRED** e **HUMAN PLAYTEST
REQUIRED** do percurso integral. As capturas não constituem aprovação humana.

## G — entrega e Git

- Windows: **PASS local**, `build/windows/Koliani.exe`, 435 405 896 bytes;
  export release terminou com código 0, launch real produziu
  `build/windows/smoke_level1.avi`; o atalho `Koliani (testar).lnk` mantém
  `jogar.bat` → executável atual;
- Web/PWA: **PASS local**, `build/web/index.html`; HTML, JS, WASM, PCK,
  manifest, offline e service worker responderam HTTP 200. O browser local
  completou o download e apresentou o menu principal Koliani;
- cache PWA: `1789055058|5419303`, com remoção dos caches antigos pelo prefixo
  `Koliani-sw-cache-`;
- Android/iOS: **OUT OF SCOPE**;
- commit/push: consultar `git log -1` no estado entregue; sincronização remota
  só é concluída depois do fetch final não destrutivo.

## Resultado

O lote funcional técnico da Região I foi implementado e os gates disponíveis
passaram. A Vertical Slice permanece **PARTIAL** enquanto faltarem produção
visual/sonora aprovada e revisão humana de percurso, feel, equilíbrio e
legibilidade. Não iniciar Região II. Próximo passo recomendado: revisão humana
da Região I nos builds Windows e Web/PWA, seguida apenas das correções
objetivas que essa revisão provar.
