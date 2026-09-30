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
