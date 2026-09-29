# Loja -- cosméticos com arte real além das skins (29 set 2026)

Pedido do Paulo: "a store além das skins da Koliani tem diversas skins de
outras coisas, crie conteúdo para isso também". Regra de qualidade: só
material que se compraria, pronto para apresentação final; nada de
recolorações a fingir de item novo. As skins da Koliani (anjo/demónio) e o
interruptor "tudo grátis" são de outra sessão (`claude/project-thread-u5wewl`)
e não foram tocados aqui.

## Inventário antes

| Categoria | Item | Estado antes |
|---|---|---|
| skins | base, Carmesim, Luar, Manto de Madeira Podre | tinta / placeholder (outra sessão) |
| efeitos (rasto do dash) | Rasto de Brasas | só mudava a cor do eco |
| efeitos | Rasto de Esporos | placeholder, sem efeito nenhum |
| HUD / fogueira | Moldura de Osso | só tinta branca no disco e chama azulada |
| HUD / fogueira | Moldura de Raízes (Rootbound) | arte real (única) |
| extras | Galeria de Conceitos | placeholder, comprar não faz nada |
| packs | Relíquias do Coração Podre | placeholder |

## O que ficou feito

Tudo desenhado pixel a pixel por `tools/gerar_cosmeticos_loja.py`
(determinístico; sombreado por volumes -- esfera/cápsula com luz de
cima-esquerda, rampas discretas, contorno por camada -- e sprites pequenos
em grelha ASCII). Mexer no tool e regerar, nunca nos PNG.

**Molduras HUD + fogueira** (mesmo contrato da Rootbound: nine-patch do
disco 88x88 e da placa 128x64, peças da fogueira, preview 346x130):

- **Moldura do Ossário** (`hud_moldura_osso`, antes "Bone HUD Frame" por
  tinta): aro de ossos longos, epífises nos cantos, caveira com a alma
  acesa nos olhos (turquesa) em cima-esq., caveira pequena com ossos
  cruzados em baixo-dir. Fogueira: caixa torácica de pé à volta da chama,
  fémures cruzados no lugar da lenha (a lenha poligonal fica invisível),
  caveira e velas de sebo à frente; apagada, os olhos da caveira brilham;
  acesa, fogo-de-alma branco/turquesa.
- **Gaiola de Aurora** (`hud_moldura_gaiola`, NOVO, épico): ferro forjado da
  gaiola onde o Zeriko prende a Aurora (a da key art) -- bandas rebitadas,
  pedras-da-lua magenta engastadas e crescentes de luar nos cantos. Fogueira:
  gaiola de cúpula com argola por cima da chama, corrente partida e cadeado
  aberto no chão; apagada, a pedra da tampa pulsa; acesa, chama
  rosa/magenta/púrpura.

**Rastos do dash** (eco em silhueta luminosa via shader + 2 folhas de
partículas animadas, `scripts/rasto_cosmetico.gd`):

- **Rasto de Brasas** (existente, agora com arte): silhueta incandescente,
  brasas em estrela que arrefecem em 6 frames, flocos de cinza.
- **Rasto de Esporos** (existente, agora com arte): silhueta de musgo,
  nuvens de esporos que rebentam e se desfazem, folhas mortas a rodopiar.
- **Rasto de Mariposas Lunares** (`efeito_rasto_mariposas`, NOVO, épico):
  silhueta prateada, mariposas com olhos magenta nas asas a bater asas e a
  fugir para trás e para cima, pó de luar a cintilar.

**Pack novo**: **Luar de Aurora** (`pack_luar_aurora`, lendário) = Gaiola de
Aurora + Rasto de Mariposas Lunares, com preview próprio.

Preços (placeholder, como o resto da loja): Gaiola K900/V200, Mariposas
K800/V160, pack teto K1200/V250 (paga só o que falta). Textos nos 6 idiomas
(o "Bone HUD Frame" estava por traduzir em es/fr/de/zh -- corrigido).

## Código

- `scripts/cosmeticos_visuais.gd`: passou a data-driven -- `MOLDURAS_ARTE`
  (Rootbound, Ossário, Gaiola) e `RASTOS` (Brasa, Esporos, Mariposas);
  `caixa_hud` / `checkpoint_visual` genéricos; `rasto_visual`,
  `tinta_vfx_dash`, `moldura_arte_equipada` novos; `preview_loja` lê o
  campo `preview` do catálogo (só itens sem `placeholder`). As tintas de
  moldura (`TINTA_MOLDURA`/`COR_CHAMA_CHECKPOINT`) saíram -- nenhuma moldura
  é tinta agora. `TINTA_SKIN` intocado (é da sessão das skins).
- `scripts/rasto_cosmetico.gd` (novo): shader da silhueta + emissão das
  partículas (um Sprite2D e um tween por partícula; ~12 vivas por dash).
- `scripts/koliani.gd`: 5 linhas no `_rasto_dash` (material + emitir) e a
  tinta nos dois `Vfx9G.tocar` do dash.
- `scripts/checkpoint.gd`: posições e cor "ociosa" vêm do dicionário (os
  nós continuam a chamar-se `Rootbound*`).
- `scripts/controlos_toque.gd`: 1 linha (`moldura_arte_equipada`).
- `scripts/loja_catalogo.gd`: 3 itens novos + `preview`/`placeholder` dos 3
  que ganharam arte. A loja em si (`loja.gd`) não foi tocada.

## Verificação

- QA visual em janela real (Xvfb + OpenGL): `tests/qa_loja_arte_visual.tscn`
  -- HUD, fogueira apagada/acesa, dash em câmara lenta, detalhe na Loja.
  32/32 PASS. `tests/qa_rootbound_visual.tscn` continua PASS (2 checks
  ajustados: o Spore Wake já não é placeholder).
- Testes: `teste_loja_arte_molduras_rastos` novo; `teste_rootbound_frame` e
  `teste_loja_cosmeticos_visuais` atualizados (o osso deixou de ser tinta).
- Armadilhas: sob Xvfb o render é lento e o dash (0,16 s) acabava entre dois
  frames desenhados -- a QA usa `Engine.time_scale = 0.1` para o apanhar.
  Os irmãos com nome repetido são renomeados pelo Godot para `@Sprite2D@N`:
  contar partículas pela textura, não pelo nome.

## Por fazer / decisão

- **Galeria de Conceitos** (extras): comprar ainda não faz nada. Precisa de
  um ecrã de galeria e de escolher o conteúdo (key art, pranchas das regiões
  em `docs/art_direction/regions/`, pacotes de chefes). Decisão do Paulo.
- Rasto de Brasas mantém o nome "Ember Trail"; o impacto magenta do kit 9G
  do dash é só tingido (mistura aditiva), não recolorido.
- Pack Coração Podre continua placeholder (depende da skin, que é da outra
  sessão).
