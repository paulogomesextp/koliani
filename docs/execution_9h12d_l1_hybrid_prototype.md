# Execution 9H.12D — L1 Hybrid Cinematic 2D (protótipo)

Data: 12 de setembro de 2026. Versão: **0.18.4**.
Pré-requisito: 9H.12A integrado em `master` (merge `8c784fd0`; estava só no
ramo `codex/9h12a-portal-remaster`, não em `master`).

## O que se fez

### 1. Terreno — o mosaico pobre acabou (FEITO)

O corpo das plataformas era `terreno_corpo.png` de **30x75 px** repetido ~35
vezes numa plataforma de 1050 px. A 30 px de período o olho vê a GRELHA, não
a rocha: era isto, e não o fundo, o que fazia o L1 ler-se como platformer
retro genérico.

Ferramenta nova: [`tools/gerar_terreno_hd_regiao1.py`](../tools/gerar_terreno_hd_regiao1.py).
A matéria-prima já estava no repo e estava a ser deitada fora — as pranchas
de `_source/imagegen_v1/` têm 1254x1254 a 2172x724 e o produtor antigo
reduzia-as a 32/64/96 px porque o contrato pedia *"hard pixel clusters; no
antialiasing"*. Esse contrato caiu com a direcção FROZEN; aqui reamostra-se
com Lanczos e **guarda-se o antialiasing**.

| peça | antes | agora | período |
|---|---|---|---|
| corpo | 30x75 | **384x384** | 12,8x maior |
| capa | 62x32 | **512x56** | 8,3x |
| lado | 16x57 | **28x384** | — |
| base | 62x24 | **512x34** | 8,3x |

Duas armadilhas que custaram medições e não se devem repetir:

* **As peças têm de ser costuráveis.** `texture_repeat` marca uma linha a cada
  período; sem o cross-fade das arestas só se trocava uma grelha de 30 px por
  uma de 384. `costurar_x` / `costurar_y`.
* **Cortar por fracção da prancha gravou uma capa PRETA.** A
  `platform_large_segment` tem margem transparente por cima; `crop(0, 0, w,
  h*0.24)` deu 56 px em que 40 eram vazio — média RGB (0,2,2). O corte passou
  a sair da **caixa do alfa** (`getchannel("A").getbbox()`), não de uma
  fracção escrita à mão.
* **Graduação.** A fonte é pedra azul com musgo amarelo-lima vivo; o lima a
  full em toda a massa era metade do "parede de tijolo amarelo" do QA. O
  musgo do corpo recua (0,34) e só a capa o mantém (0,62), onde dá leitura à
  aresta de pouso. Luminância média do corpo: (10,30,47) contra (25,36,48) do
  antigo — mais escuro e mais frio, mas com estrutura visível.

Ligação em `plataforma.gd` via `Kit.terreno(HD, legado)`: se o kit HD não
existir cai no antigo. **Colisões intactas** — quem as define é `tamanho`;
só mudaram alturas DESENHADAS (capa 32→56, base 24→34, lado 16→26).

### 2. Faixa verde-oliva — identificada e morta (FEITO)

**Não era a poça da cena.** A `PantanoMortal` do `.tscn` está a y=930 com 320
de altura; a faixa começava 53 px acima disso. A fonte real é o
**`LiquidoMortal` que o `gerador_corredor.gd` instancia**, com **460 px de
altura** e a atravessar o nível inteiro, pintado com `LIQUIDO[0] =
Color(0.13, 0.28, 0.15)` — oliva. Isso explica exactamente o que o QA viu:
aparece nos **cinco** níveis da região (é por REGIÃO, não por nível) e no L4
toma um terço do ecrã.

Correcções:

* `LIQUIDO[0]` passa a `Color(0.26, 0.16, 0.42)` — seiva corrompida. A Região
  I é a Floresta CORROMPIDA e a corrupção da região é violeta/magenta em todo
  o lado (VFX, cristais, Árvore). *Toca em L1–L5 porque a constante é por
  região; é só cor — geometria, colisão e dano não mudam.*
* `AguaVenenosa.superficie_textura` (novo, `null` por omissão → nada muda nos
  outros 95 níveis): duas tiras da mesma textura a deslizar em sentidos e
  velocidades diferentes logo abaixo da linha de água. Tira a leitura de
  "polígono de cor plana" por dois quads. Ligada na Região I.
* **P1 introduzido por esta execução e corrigido antes de fechar:** a linha de
  água era `cor.lightened(0.7)`, afinado para a oliva; numa cor escura de
  corrupção dava uma fita quase branca de lado a lado — a mesma leitura de
  placeholder que se estava a tirar. Passou a `0.45` com alfa 0,7.

Medido no EXE de release: a faixa era (31,47,33) oliva, agora é (36,35,49)
violeta-cinza neutro.

## O que NÃO se fez, e porquê

### Background nativo HD — EM ABERTO

O ponto 1 do briefing pede layers nativas de 1920x1080+. **Não existem, e não
se produziram dentro do orçamento.** O que está medido:

* A fonte é a prancha 08 a **1536x1024**, de onde sai o recorte 952x247. Os
  `_x2` e `_hd_x4` são reamostragens do mesmo recorte — não acrescentam
  informação (confirma a 9H.12B).
* O único 1920x1080 ilustrado da Região I no repo é
  `assets/ui/frontend_9h/regioes/r01/fundo_seletor.png` — mas é uma
  **composição** de `tools/tema_regiao_9h1.py` a partir do mesmo panorama
  ampliado, com névoa/vegetação/luz por cima. Lê-se bem a 1:1 no selector;
  como fonte de parallax não traz pixéis novos.

**Hipótese testada e revertida:** pôr `PANORAMA_HD = 4.0` e desenhar a partir
da `_hd_x4`. Foi revertido porque a **9H.7B já tinha medido o contrário** e
deixou-o escrito no próprio ficheiro: a amostragem do shader conserva os
texels e antialiasa só as transições, enquanto o Lanczos de disco já grava o
desfoque antes de o GPU receber a textura. Não se reabre uma hipótese
descartada com prova.

Para fechar o ponto 1 é preciso **decisão do Paulo**: arte nativa nova (IA
original específica para Koliani, ou CC0 compatível com redistribuição num
repo público) separada em 5 layers. Sem isso o fundo fica como está.

### Dressing e Hybrid VFX — parcial

O que já existia (névoa em duas profundidades, raios de luz, partículas de
corrupção, halo das lanternas, vinhas, parallax de 5 camadas) continua e
agora tem um terreno à altura. **Não se acrescentou dressing novo** — o
orçamento foi todo para o terreno e para caçar a fonte real da faixa verde.

## Self-QA (EXE de release 0.18.4, L1 em movimento)

| pergunta | resposta |
|---|---|
| plataformas ainda parecem mosaico? | **não** — massa orgânica, período 384 |
| faixa verde desapareceu? | **sim** — (36,35,49), sem oliva |
| Koliani continua legível? | **sim** — a capa de musgo separa-a do fundo |
| foreground tapa gameplay? | não |
| background continua desfocado? | **sim** — em aberto, ver acima |
| seams/repetições evidentes? | o motivo de arco da `terrain_fill` repete-se a 384 px em plataformas muito largas; aceitável, não resolvido |
| placeholders? | nenhum novo |

## Verificação

* Suite completa headless: **PASS**.
* EXE de release exportado e fotografado em L1 (`--nivel=1 --foto=`).
* Região II: **não iniciada**.
