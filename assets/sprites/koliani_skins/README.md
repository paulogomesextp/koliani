# Skins da Koliani (Loja > Skins)

Cada skin é o **Golden Set inteiro** (`../koliani_golden_set/frames/`, 84
frames, todas as animações) com a paleta trocada e, nas elaboradas, vestido
com um **conjunto de armadura + arma** desenhado de propósito. Mesmo contrato de canvas (128×128, pés em y=104,
escala 1.0): física, câmara, colisão e hitbox não mudam. **Não editar os PNGs
à mão**: são gerados.

| Pasta | Item da Loja | Tipo |
|---|---|---|
| `fornalha/` | `skin_fornalha` (Brasa da Fornalha) | **só paleta** — brasa sobre ferro queimado |
| `abadia_afogada/` | `skin_abadia_afogada` (Abadia Afogada) | **só paleta** — verde-água sobre azul-ardósia |
| `celestial/` | `skin_celestial` (Planícies Celestiais) | **só paleta** — marfim/prata com ouro |
| `guardia_forja/` | `skin_guardia_forja` (Guardiã da Forja) | cornos com brasa, ombreira com espigão, montante de brasa |
| `abadessa_afogada/` | `skin_abadessa_afogada` (Abadessa Afogada) | capuz fundo com orla verde-água, tridente |
| `serafim_celestial/` | `skin_serafim_celestial` (Serafim Celestial) | asas (batem), auréola, ombreira de ouro, espada solar |
| `vazio/` | `skin_vazio` (Arauta do Vazio) | coroa de espinhos, capa rasgada (esvoaça), foice |

As simples (só paleta) ficam só estas três (decisão do Paulo, 29 set);
todas as seguintes são conjuntos de armadura + arma.

- `pecas/` — cada peça solta (cabeça, ombreira, asa, arma), para rever e para
  ícones futuros.
- Peças: `tools/trajes_koliani.py` (grelhas de texto + desenho procedural).
  Composição: `python tools/gerar_skins_koliani.py [--preview]`, depois
  `--headless --import`.
- Runtime: `CosmeticosVisuais.DIR_SKIN` -> `koliani.gd::_caminho_skin`.
- Ver todas lado a lado: `res://tools/ProvadorSkins.tscn`.
- Licença: arte do projeto (Golden Set + peças desenhadas aqui); nenhum asset
  de terceiros.
