# Skins da Koliani (Loja > Skins)

Cada skin é o **Golden Set inteiro** (`../koliani_golden_set/frames/`, 84
frames, todas as animações) vestido com um **conjunto de armadura + arma**
desenhado de propósito. Mesmo contrato de canvas (128×128, pés em y=104,
escala 1.0): física, câmara, colisão e hitbox não mudam. **Não editar os PNGs
à mão**: são gerados.

| Pasta | Item da Loja | Conjunto |
|---|---|---|
| `fornalha/` | `skin_fornalha` (Guardiã da Forja) | cornos com fendas de brasa, ombreira de ferro com espigão, montante de brasa |
| `abadia_afogada/` | `skin_abadia_afogada` (Abadessa Afogada) | capuz fundo com orla verde-água, tridente |
| `celestial/` | `skin_celestial` (Serafim Celestial) | asas de penas (batem), auréola, ombreira de ouro em asa, espada solar |
| `vazio/` | `skin_vazio` (Arauta do Vazio) | coroa de espinhos, capa rasgada (esvoaça), foice |
| `brasa/`, `mare/`, `marfim/` | `skin_brasa`, `skin_mare`, `skin_marfim` | **só paleta** (as cores da Forja/Abadia/Celestial), silhueta do Golden Set |

- `pecas/` — cada peça solta (cabeça, ombreira, asa, arma), para rever e para
  ícones futuros.
- Peças: `tools/trajes_koliani.py` (grelhas de texto + desenho procedural).
  Composição: `python tools/gerar_skins_koliani.py [--preview]`, depois
  `--headless --import`.
- Runtime: `CosmeticosVisuais.DIR_SKIN` -> `koliani.gd::_caminho_skin`.
- Ver todas lado a lado: `res://tools/ProvadorSkins.tscn`.
- Licença: arte do projeto (Golden Set + peças desenhadas aqui); nenhum asset
  de terceiros.
