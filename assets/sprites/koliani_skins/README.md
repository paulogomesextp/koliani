# Skins da Koliani (Loja > Skins)

Cada skin é o **Golden Set inteiro** (`../koliani_golden_set/frames/`, 84
frames, todas as animações) repintado e, nas premium, vestido com um
**conjunto completo** desenhado de propósito. Mesmo contrato de canvas
(128×128, pés em y=104, escala 1.0): física, câmara, colisão e hitbox não
mudam. **Não editar os PNGs à mão**: são gerados.

| Pasta | Item da Loja | Tipo |
|---|---|---|
| `fornalha/` | `skin_fornalha` (Brasa da Fornalha) | **só paleta**: brasa sobre ferro queimado |
| `abadia_afogada/` | `skin_abadia_afogada` (Abadia Afogada) | **só paleta**: verde-água sobre azul-ardósia |
| `celestial/` | `skin_celestial` (Planícies Celestiais) | **só paleta**: marfim/prata com ouro |
| `anjo/` | `skin_anjo` (Arcanjo) | **premium**: couraça de prata com filigrana de ouro, capa com bainha de ouro, duas asas de penas em 3 camadas (batem), auréola com raios, olhos de luz, ombreira alada, espada sagrada com guarda em asas, brilho |
| `demonio/` | `skin_demonio` (Arquidemónio) | **premium**: couraça de aço negro, obsidiana com veios de lava, dois cornos, olhos em brasa, capa rasgada com forro carmim (esvoaça), cauda com ponta (balança), espadão serrilhado, brilho |

As simples (só paleta) ficam só estas três (decisão do Paulo, 29 set). O
Paulo recusou os conjuntos "peças por cima da paleta" (pareciam cópias das
simples) e pediu **duas premium, Anjo e Demónio, pormenorizadas**.

- `pecas/`: cada peça solta (asa, auréola, cornos, capa, cauda, armas), para rever e para ícones futuros.
- Peças premium e materiais: `tools/trajes_premium.py`; primitivas e âncoras
  (cara, ombro, lâmina): `tools/trajes_koliani.py`. Composição:
  `python tools/gerar_skins_koliani.py [--preview]`, depois `--headless --import`.
- Runtime: `CosmeticosVisuais.DIR_SKIN` -> `koliani.gd::_caminho_skin`.
- Ver todas lado a lado: `res://tools/ProvadorSkins.tscn`.
- Licença: arte do projeto (Golden Set + peças desenhadas aqui); nenhum asset
  de terceiros.

## Shadowblade Koliani (`shadowblade/`, `skin_shadowblade`, lendária)
Skin **puramente visual** sobre o Golden Set final (movimento LOCKED): mesmos
84 frames, mesmo canvas/pés/pivot, `run_final` incluído. Gerada por
`tools/gerar_skin_shadowblade.py` (peças em `tools/trajes_shadowblade.py`,
independente de `trajes_premium.py`): cabelo prata/marfim (por geometria
relativa à cara), roupa preto-roxo, veios roxos, orla de metal fosco, olhos
violeta, cornos e capa de sombra, ombreira, lâmina curva de energia (mesma
reta da lâmina original). Nada da skin fica abaixo da linha do chão do
original. VFX (camadas separadas) em `shadowblade/vfx/`, gerados por
`tools/gerar_vfx_shadowblade.py` e tocados por `scripts/vfx_skin.gd`:
arco do golpe (os 6 frames do Golden Set repintados), anel do salto duplo,
impacto de aterragem, impacto de pogo, partículas (dash/salto/aterragem).
Rasto do dash: eco roxo já existente + partículas. Validação:
`python tools/validar_paridade_skin.py shadowblade` e
`teste_shadowblade_paridade`. `apresentacao/` = recorte da arte de referência
do pacote (não usado no jogo).
