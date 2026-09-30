# Execução — Skin Shadowblade Koliani (30 set 2026, commit local, sem push)

Pedido: integrar a skin premium do pacote `Shadowblade_Koliani_Codex_Handoff.zip`
com o movimento atual **LOCKED** (`run_final` = fonte de verdade).

## Como reutiliza as animações
Skin = pasta de frames espelho do Golden Set (mesmo contrato das outras skins):
`CosmeticosVisuais.DIR_SKIN["skin_shadowblade"]` → `koliani.gd::_caminho_skin`.
Nenhuma animação, fps, loop, pivot, escala, hitbox ou state machine foi tocada;
só as texturas lidas mudam. Frame que falte → Golden Set. Skin desconhecida →
default. `tools/gerar_skin_shadowblade.py` (+ `tools/trajes_shadowblade.py`,
independente de `trajes_premium.py`) pinta os 84 frames: cabelo prata (por
geometria relativa à cara), roupa preto-roxo, veios roxos, metal fosco, olhos
violeta, cornos e capa de sombra, ombreira, lâmina curva de energia na reta da
lâmina original. Tudo o que fica abaixo da linha do chão original é cortado.

## Paridade do run_final (prova)
- `python tools/validar_paridade_skin.py shadowblade`: 84 frames, mesmo canvas,
  o corpo não perde pixéis (fora golpes/rolamento), `run_final` 1–10: linha do
  chão igual e extremos dos pés ±3 px (só brilho/capa). PARIDADE OK.
- `teste_shadowblade_paridade` (Godot): mesmas animações, nº frames, fps, loop,
  duração e tamanho de frame por animação; `run` = 10 frames do `run_final` da
  skin, na ordem; offset/escala/hitbox iguais. Como os frames do corpo do
  `run_final` são o original (só recolor + peças) a alternância das pernas é a
  do Golden Set.

## VFX (camadas separadas, `scripts/vfx_skin.gd`)
- Arco do golpe: os 6 frames do Golden Set repintados (mesma geometria/duração).
- Anel do salto duplo, impacto de aterragem, impacto de pogo, partículas
  (dash/salto/aterragem): **procedurais v1** (`tools/gerar_vfx_shadowblade.py`),
  pois o pacote só tem folhas de referência. Rasto do dash: eco roxo já existente.
- Portal FX: não feito (sem cosmético de portal no sistema de skins).
Ganchos em `koliani.gd`: 5 chamadas `VfxSkin.*`, todas no-op sem skin.

## Loja
`skin_shadowblade` em `LojaCatalogo` (skins, lendária, 500 V provisório, grátis
via `GRATIS_EM_DESENVOLVIMENTO`), nome/descrição nos 6 i18n, cartão = `preview.png`.
Saves antigos intactos (só um id novo no catálogo).

## Testes
Suite completa Linux headless (Godot 4.7.2, sandbox isolado): "todos os testes
passaram", save real intacto. `teste_skins_arte_real` cobre a skin nova.

## Limitações
- Peças (couraça, capa, ombreira) ancoram à cara como Anjo/Demónio: em poses
  muito deitadas (dash, rolamento) ficam menos limpas. Falta revisão visual do Paulo.
- Splash/thumbnail: só recorte de referência em `shadowblade/apresentacao/`
  (a Loja não tem slot de splash; o cartão usa o frame de golpe).
- Sem captura in-game (headless).

---
# Fase 2 — Polimento visual in-game (30 set 2026)
Harness novo: `tools/qa_shadowblade_ingame.gd` (Xvfb + opengl3; conduz a Koliani
com input real na Floresta Putrefata, nos dois sentidos; grava tiras x3). Capturas
em `docs/qa/shadowblade/`. **Só a camada visual mudou**; `koliani.gd` e tudo o
resto ficaram iguais ao 7523e96.

## Achados (in-game) e correções
1. Cabelo branco estourado → rampa prata/lilás mais baixa (sem branco puro).
2. Veios de energia a ruído nas pernas → só no tronco (acima da cara+16 px).
3. Cornos pesados a tapar a testa → 62 % do tamanho.
4. Orla de ouro laranja nas coxas → removida (fica o metal só na couraça/arma).
5. Tufos roxos/blocos escuros no cabelo nas poses de salto/queda (cabelo a subir
   acima da cabeça) → regra de cabelo cobre tudo o que está acima da cara.
6. Capa reduzida (80 % × 72 %) para não sujar as pernas na corrida.
7. Preview da Loja: golpe + arco de sombra sobre aura violeta (mesma moldura).
Dash e rolamento: revistos frame a frame in-game nos dois sentidos; o rolamento
roda o frame vestido do `jump_loop_003`, por isso cornos/capa rodam com o corpo.

## Performance (mobile)
VFX de skin vivos em simultâneo no pior caso medido: 2 nós (`SkinVFX_*`), cada um
`queue_free` no fim da animação (≤0,35 s); partículas: 8–10 por rajada, vida
≤0,5 s, `CPUParticles2D` one-shot que se liberta; blend aditivo partilhado (1
material). Nada persistente, nada fora do ecrã além da vida curta.
