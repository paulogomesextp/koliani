# Execução — Skins da Koliani com arte real (29 set 2026)

Pedido do Paulo: "quero que faça novos assets para skins da Koliani".

## Como estava
- A Loja já tinha a categoria `skins`, mas todas eram **placeholder**: o
  `skin_carmesim` e o `skin_luar` são só uma tinta (`modulate`) por cima do
  corpo (`CosmeticosVisuais.TINTA_SKIN`); o `skin_coracao_podre` nem tinta tem.
- O corpo da Koliani em **todos os 100 níveis** é o Golden Set
  (`assets/sprites/koliani_golden_set/frames/`, 84 PNGs 128×128, pés em y=104),
  montado em `koliani.gd::_montar_golden_set` / `_animacao_golden`.
- A arte do Golden Set **não é indexada** (~1200 cores por frame): trocar a
  paleta por tabela de cores não serve.

## O que foi feito
1. `tools/gerar_skins_koliani.py` — troca a paleta por MATERIAL, classificado
   em HSV com pesos suaves: `acento` (vermelhos: lenço, pontas do cabelo,
   fivelas), `pele` (nunca muda), `gema` (cristal ciano do cinto) e `tecido`
   (roupa/cabelo/botas). Cada material passa por uma rampa de cores indexada
   pelo brilho original; pixels abaixo de V=0,07 (contorno) ficam iguais.
   Resultado: mesma silhueta (alfa idêntico, verificado no teste), 84 frames
   por skin, ~700 KB cada.
2. Três skins, temas das regiões:
   - `skin_fornalha` — Região IV: brasa/metal fundido sobre ferro queimado
     (600 K, raro);
   - `skin_abadia_afogada` — Região IX: verde-água sobre azul-ardósia
     (900 K ou 180 V, épico);
   - `skin_celestial` — Região XIV: marfim/prata com ouro (250 V, lendário).
   Todas `regiao: -1` (à venda desde o início) e `destaque: true`.
3. Runtime: `CosmeticosVisuais.DIR_SKIN` + `dir_skin()`; `koliani.gd::_caminho_skin`
   troca cada caminho `GOLDEN_DIR/frames/...` pelo da skin (cai no Golden Set
   se o ficheiro não existir, ex. um `run_native` futuro antes de regerar).
   O VFX do golpe não muda. A skin resolve-se ao montar a Koliani (ao entrar
   num nível), não a meio.
4. Loja: `preview_loja()` devolve o `preview.png` da skin, `placeholder: false`.
5. i18n: nome + descrição nos 6 idiomas (traduções reais).
6. `tools/ProvadorSkins.tscn` — as 4 Koliani lado a lado, animações a rodar.
7. Teste `teste_skins_arte_real`: catálogo/preview, 84/84 frames por skin,
   alfa igual e cores diferentes, Koliani com a skin equipada lê os frames da
   pasta dela, sem skin volta ao Golden Set.

## Números
- Suite completa (Linux headless, Godot 4.7.2): **0 falhas**.
- Gerador: ~10 s para as 3 skins.

## Decisões que ficaram por tomar (Paulo)
- Preços/raridades são **provisórios** (mesma escala dos itens existentes).
- As skins não estão presas às regiões (`regiao` -1). Se as quiserem como
  recompensa regional, é mudar o campo no catálogo.
- As skins antigas só-tinta (`skin_carmesim`, `skin_luar`) continuam; podem
  passar a arte real com o mesmo gerador (é acrescentar uma entrada em `SKINS`
  e em `DIR_SKIN`).
