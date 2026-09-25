# Plano técnico de FUNDAÇÃO (Game Director Fase 0C)

Estado: **PLANO — nada implementado.** Só o isolamento de save foi alterado nesta fase.
Origem: `docs/auditoria_global_game_director.md` (P-1…P-10) + `docs/qa/global_audit/01…08`.
F1→F4 são pré-requisito do slice (`docs/vertical_slice_region01.md`).
Regra transversal: preservar o que funciona (§3 da auditoria): física de chão sem latência, combo com
frame data, golden set, determinismo 100/100, save v5, retry da R-I.

## F0 (feito) — isolamento de save
`tools/godot_isolado.py` é a única forma de arrancar o Godot em QA/testes/bots (APPDATA no Windows,
fail-fast, SHA do save real). Não reintroduzir `XDG_DATA_HOME` à mão.

## F1 — Movement / game feel (P-5)
Ficheiros: `scripts/koliani.gd`, `scripts/movimento.gd` (lógica pura), câmara.
1. **Diagnóstico por tick antes de tocar em constantes**: bancada que regista altura/comprimento do
   salto, velocidade de queda, ticks de coyote/buffer, duração real de cada animação (a auditoria mediu
   82,9 px = 1,3 H; corte `CORTE_SALTO 0.45` aplicado por tick ≈ 5× gravidade).
2. **Salto**: alvo 125–135 px; corte único (multiplicação da velocidade uma vez ao largar) +
   meia-gravidade no apex. Mexer em `Movimento.FORCA_SALTO`/gravidade afecta `STOMP_RESSALTO`
   (`koliani.gd:201`) e o verificador de alcance → re-medir `tools/verifica_alcance*.gd` a cada mudança.
3. **Queda**: teto ≤ 750 px/s ou fast-fall; antecipação vertical da câmara (só ~65 px hoje).
4. **Animação de locomoção como máquina de estados no tick de física** (não derivada de flags noutro
   relógio): duração mínima por estado; `land` ≥ 4 ticks; brake/turn com frames golden (não legados);
   mantle com animação. Remover rigs mortos (6–8 sistemas vivos) só depois de o golden cobrir os estados.
   **Sem redesenhar a Koliani** (usar o golden set / `RIG_PIXEL`).
5. **Rolar vs correr**: rolar encadeado < 240 px/s (hoje 302); i-frames reduzidos onde necessário.
6. **1 dono da velocidade** + acumulador de forças externas (vento/íman/trampolim) — hoje +20 px/s × 60
   ticks = 0.
7. **Knockback** ao levar dano.
Risco: mexer no salto muda a geometria alcançável dos níveis existentes → re-correr `verifica_alcance` nos
100 níveis e registar quais quebram (informação, não bloqueio: o slice é a R-I).
Saída: números da barra Movement; harness de bancada versionado.

## F2 — Combat (P-7, P-8)
Ficheiros: `koliani.gd`, `estado_jogo.gd`, `demonio_base.gd`, `chefe_base.gd`.
1. **Tiro gasta Energia**; a Energia ganha função (tiro/parry/especial como sumidouro). A decisão do GM
   sobre o regresso de um especial (nº 12) condiciona o desenho.
2. **Hitbox da espada** alinhada à lâmina desenhada (±4 px; hoje +12 px); dano de contacto deixa de
   depender só de `body_entered`.
3. **Hit-stop ≥ 2 frames a 60 Hz**; flash de acerto que não tape o alvo.
4. **Inimigos que morrem antes de agir**: TTK-alvo por papel (fodder 2–3, soldier 4–6, elite 10+) e
   **fonte única de dificuldade** (fim do `clampi(indice_nivel,0,29)` em `demonio_base.gd:381,1197` e
   `chefe_base.gd:232,286,474`). Aplicar primeiro só à curva usada pela R-I; o resto é fase CONTENT.
5. **Decisões de combate**: parry devolve Energia; sem estratégia de 0 dano (bot de kiting a 380 px como
   teste de regressão).
Não balancear 100 níveis: só o core loop do slice.

## F3 — Enemy Foundation
Padrão único de inimigo do slice (espécie = movimento + 1–2 ataques + papel), como máquina de estados
explícita: **percepção/aggro → aproximação (se aplicável) → telégrafo (animado, ≠ idle a 0,1 s) → ataque
com hitbox própria → recovery → reação a hit → morte**. Contacto residual e ≤ sprite (hoje 58×74 vs
44×47). Implementar como componente reutilizável sobre `DemonioBase` (não reescrever os 34 skins). Só as
3–4 espécies da R-I + 1 elite (Ghorak) migram; o resto fica no legado até à fase CONTENT. O sorteio de
comportamento no gerador (`gerador_corredor.gd`, ~1797–1812) deixa de valer para essas espécies: o
comportamento vem da espécie.

## F4 — Level pipeline: o nível deixa de ser o gerador (P-1)
- Nível = **lista de salas authored** (cenas pequenas/módulos) declarada na cena ou num manifesto de
  dados; o gerador (`gerador_corredor.gd`, 5 528 linhas) passa a **ferramenta de apoio** (validação,
  preenchimento opcional), nunca autoridade do layout. **Não reescrever o ficheiro agora.**
- `corredor = false` por omissão; regiões sem jornada procedural.
- **Sem RNG global partilhado**: semente por sala (o `_rng` partilhado acopla níveis — o N12 forçado teve
  de ser isolado para não mexer nos outros).
- **Configuração regional isolada** num recurso de dados (RegionKit: terreno, 4 layers de parallax, 8–12
  props, 3–5 hazards com sprite, 4–6 inimigos, boss+arena, ambiente, tema) — sem `if _regiao == N` /
  `if _idx == N` em código partilhado (critério de saída da fase Region Pipeline).
- Respawn sem `reload_current_scene`; checkpoint por sala.
- Prova de não-regressão: baseline dos 100 níveis (geração determinística) idêntica exceto o(s) nível(eis)
  migrado(s).

## Pipeline de região (modelo para regiões futuras)
1 canon → 2 board visual → 3 atlas/kit → 4 mecânicas → 5 inimigos → 6 hazards → 7 áudio →
8 N1 Teach → 9 N2 Test → 10 N3 Combine → 11 N4 Challenge → 12 N5 Boss → 13 runtime QA →
14 aprovação visual → 15 LOCK. Cada passo tem gate; a região só passa a LOCKED com aprovação do GM.
A R-I prova o método (slice); a R-II é a 1.ª industrialização (custo real registado).

## Estado do conteúdo — FREEZE
`FROZEN PENDING VERTICAL SLICE`: rebuild N13, rebuild N14, Região IV, produção N21–N100, novos bosses,
novas regiões, migração de bosses (20 regionais), substituição de música. O commit do N12 (`1559d461`)
permanece válido mas **não é o quality target** — o slice é.

## Ordem sugerida das próximas sessões
1. F1 diagnóstico + bancada de movimento (sem alterar gameplay) → afinar → medir.
2. F2/F3 em conjunto sobre 1 inimigo (o soldier da R-I) como prova do padrão.
3. F4 mínimo: módulo de sala + semente por sala + N1 como lista de salas.
4. N1 → Ghorak → N5 → áudio → playtest.
