# Skins da Koliani (Loja > Skins)

Cada pasta é o **Golden Set inteiro** (`../koliani_golden_set/frames/`, todas
as animações, 84 frames) com a paleta trocada. Mesma silhueta, mesmo contrato
de canvas (128×128, pés em y=104, escala 1.0) — nada de física, câmara ou
colisão muda. **Não editar os PNGs à mão**: são gerados.

| Pasta | Item da Loja | Tema |
|---|---|---|
| `fornalha/` | `skin_fornalha` | Região IV — Fornalha: brasa/metal fundido sobre ferro queimado |
| `abadia_afogada/` | `skin_abadia_afogada` | Região IX — Abadia Afogada: verde-água sobre azul-ardósia |
| `celestial/` | `skin_celestial` | Região XIV — Planícies Celestiais: marfim/prata com ouro |

- Gerador: `python tools/gerar_skins_koliani.py [--preview]` (rampas por
  material em `SKINS`; `--preview` grava `work/skins_koliani/folha_skins.png`).
  Depois `--headless --import`.
- Runtime: `CosmeticosVisuais.DIR_SKIN` -> `koliani.gd::_caminho_skin` lê cada
  frame da pasta da skin (cai no Golden Set se faltar algum).
- Ver todas lado a lado: `res://tools/ProvadorSkins.tscn`.
- Licença: derivadas da arte da Koliani do projeto (Golden Set); nenhum asset
  de terceiros.
