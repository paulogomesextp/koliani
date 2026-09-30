# Shop — modernização da apresentação, 30 setembro 2026

Estado: implementação local concluída e testes dirigidos PASS; revisão
estética humana pendente. Sem push, publicação ou builds de entrega.

## Auditoria inicial

Checkout limpo, mas 345 commits atrás de origin/master; atualizado por
fast-forward para `e6e8e7b517d351f27d36a19e96edb8ee12c29001` após fetch.
A Shop não possuía scene própria: `MenuInicial._abrir_loja()` instancia
`Loja.new()`, definida em `scripts/loja.gd`. A UI anterior tinha categorias
verticais, grelha de duas colunas e coordenadas de referência 1280×720.

Fontes únicas identificadas:

- Dados: `LojaCatalogo`, categorias, IDs, descrições i18n, raridades,
  requisitos, preços e interruptor grátis em desenvolvimento.
- Estado/lógica: `EstadoJogo` contém K/V, adquirido/equipado/bloqueado,
  compra/equip, sinais e bloco `loja` do save; conta persiste entre campanhas.
- Previews: `CosmeticosVisuais.preview_loja()`, respeitando o placeholder
  declarado no catálogo. Nenhuma preview conceptual da referência foi usada
  para substituir um item.
- Apresentação: `Frontend9H`, StyleBox, separador/vinheta/fundo existentes;
  nenhuma fonte externa foi acrescentada. Textos usam seis catálogos i18n.

## Alterações e estrutura

Nenhuma scene de produção foi alterada. `scripts/loja.gd` foi remodelado e
continua a ser o ponto de entrada existente. `ShopTheme` centraliza cores,
StyleBox, tipografia e estados. `ShopItemCard` é um Button reutilizável que
recebe dados da Loja e emite o ID selecionado; não contém regras económicas.

Estrutura de apresentação:

```
Loja
  ShopBackground
    BackgroundTexture / DarkOverlay / Vignette / AmbientFX
  MargemSegura / ShopLayout
    Header: marca / SHOP / currencies reais
    Navigation: seis tabs horizontais
    Content
      FeaturedAndCatalog
        FeaturedHero: nome / rarity / estado / descrição / VER / preview
        CatalogScroll / ItemGrid / ShopItemCard
      ItemDetails: preview / dados / requisito / avisos / ações existentes
    Footer: BACK
```

Containers resolvem o layout, com cinco colunas no desktop e alternativas
4/3 para larguras inferiores. Header, Hero e detalhe ficam fixos; apenas os
cards fazem scroll. Hover usa Tween de 100 ms e scale 1.018. Foco explícito
liga tabs/grelha/ações visíveis; botão de Galeria repõe disabled corretamente.
Raridades: ouro, roxo, azul/ciano e branco; estados adquirido verde,
equipado ouro e bloqueado com contraste reduzido.

Scripts QA: novo `tests/qa_shop_layout.gd` + `.tscn`; QA da coleção desliga
grátis apenas no seu processo para validar preços reais; runner de cosméticos
recebe definição ausente de `$iso`. Única chave textual nova: `shop.brand`
nos seis idiomas. `docs/plano_atual.md` e retoma atualizados.

Assets reutilizados: `frontend_9h/fundo_menu.png`, `separador_menu.png`,
vinheta procedural existente, previews de Anjo/Demónio/Celestial/Abadia/
Fornalha e previews de rastos, molduras, packs e Galeria existentes.
Nenhum asset raster foi criado ou modificado.

## Sistemas preservados

Zero diff em `loja_catalogo.gd`, `estado_jogo.gd`, `cosmeticos_visuais.gd`,
sprites, animações, gameplay, progressão e schema de save. A UI mantém
`comprar_item`, `equipar_item`, `preco_loja`, `saldo_loja` e
`estado_item_loja` como autoridade. Modo grátis permanece ligado.

## Validação e resultados

- Import/editor Godot 4.7.2: completou. Aviso de Android build-tools ausente.
- Renderer real Vulkan Forward Mobile, RTX 5070: QA nas quatro resoluções
  pedidas PASS, 0 falhas de asserções. Header, Hero, scroll, detalhe e BACK
  dentro do viewport; seleção sincroniza card/Hero/detalhe.
- Fluxos no QA: tabs, GET grátis, ownership, equip, troca do slot, round-trip
  JSON do save, fechar/reabrir e abrir Galeria PASS.
- QA coleção, com preços reais: requisitos/locked, preços K/V, compra
  individual, pack parcial/completo e ownership PASS, 0 falhas. Verificação
  de texto deste QA: nenhuma ocorrência de texto cortado reportada.
- Dez testes existentes executados isoladamente via SO_TESTE: catálogo,
  compras/equip, grátis dev, save/compatibilidade, progressão/gameplay,
  i18n, visuais, coleção regional, Galeria, molduras/rastos: 0 falhas.
- Persistência com userdata isolada em cinco processos (semear, compra,
  verifica, desequipa, default): todos PASS. Visual runtime conservado.
- `godot_isolado.py` confirmou SHA dos três ficheiros de save real intacto
  em cada execução final. `git diff --check`: PASS.

Limites: a suite geral deixou de produzir progresso durante testes de
gameplay anteriores à Loja e foi interrompida. Não se declara PASS global
nem causa raiz provada. QA apresentou 109–113 instâncias ObjectDB ao sair;
algumas execuções apresentaram também um recurso ainda em uso no teardown.
Um sandbox relativo produziu aviso de shader cache; os runs finais usam
paths absolutos. Nenhum SCRIPT ERROR nos runs finais dirigidos. Teardown
ainda requer investigação própria; não foi provado como regressão.

Regressões funcionais encontradas: nenhuma nos fluxos testados. Input físico
de gamepad, toque/mobile/PWA, todos os idiomas visualmente e performance em
dispositivo permanecem sem validação real. Não confundir testes de fluxo
automatizados com playtest humano.

## Comparação objetiva e pendências visuais

Implementados: composição em duas áreas, header/currencies, seis tabs,
Hero dominante, grid visual, painel permanente, dark/red/gold, rarity por
accent, previews reais e scroll exclusivo do catálogo.

Diferenças: cenário neutro do Hero em vez de catedral/partículas da
referência; tipografia default disponível em vez de serifa refinada;
ornamentos simplificados; ícones de moedas geométricos em vez de emblemas;
fundo reutilizado contém arte/logo do menu e pode ser substituído pela camada
BackgroundTexture. Em 720p a segunda fila exige scroll para ver informação
completa. O Hero acompanha o selecionado também fora da tab Featured.

Placeholders existentes permanecem (por exemplo Classic, Crimson Cloak,
Moonlit Veil, Rotwood Mantle e Heartrot Relics). Um losango neutro comunica
ausência de preview, sem inventar cosméticos. As skins premium usam exatamente
os PNGs reais existentes, apenas ampliados com nearest.

Capturas user-facing: `koliani-shop-{1920x1080,1600x900,1366x768,1280x720}.png`
em outputs do chat. Logs completos/sandboxes em `work/qa_shop` no repositório.
Próximo passo: revisão humana das capturas e teste de gamepad/toque; após
aceitação, passe dedicado de cenário/ornamentação e validação do teardown.
Qualidade estética: HUMAN VISUAL REVIEW REQUIRED. Mobile: DEVICE VALIDATION
REQUIRED. Esta mudança é um candidato local, sem entrega Windows/PWA.
