# 04 — Direção de Arte: arte APROVADA vs o que o jogo mostra

Agente 4 (Art Director) · auditoria global · 25 set 2026 · modo só diagnóstico.
Nenhum script, cena, asset ou teste foi alterado. Godot corrido só pelo wrapper de sandbox.

**Veredicto numa linha:** o Game Master tem razão. Só a Região I está no mesmo
universo visual da arte aprovada. As outras 19 não "divergem um pouco": correm
num **pipeline genérico de 7 materiais de terreno + 14 packs de fundo CC0 de baixa
resolução, recoloridos por região**, com bosses **desenhados por código a partir de
primitivas**. As pranchas aprovadas das Regiões II–XX quase não entram no jogo.
A diferença não vem de "falta de polish". É estrutural.

---

## 0. Método e evidência

- **Runtime.** Script próprio `scratchpad/a4/a4_captura.gd` (não está no repo), corrido com
  `godot_sandbox.sh --console --window --screen 1 --script …`. Para **40 níveis** (o 2.º e o 5.º
  de cada uma das 20 regiões) captura o spawn e **2 pontos a 30% e a 70% da extensão das
  plataformas**. Nos níveis com nó no grupo `chefes` também captura a arena do chefe. O zoom é
  o do próprio jogo (1.4). No total ficaram **160 capturas** em `docs/qa/global_audit/img/a4/N###_p{0,1,2}.png` e
  `N###_boss.png`, com log em `scratchpad/a4/log_captura.txt`.
- **Folhas comparativas** (ImageMagick): `img/a4/cmp_regiao_XX.jpg` põe a prancha aprovada da região ao lado
  de 2 pontos do nível 2 e da arena do nível 5. `img/a4/folha_20_regioes_jogo.jpg` mostra uma célula por
  região. `img/a4/folha_20_bosses_jogo.jpg` mostra os 20 bosses regionais.
- **Referências abertas e vistas (Read):** as 38 PNG de `docs/art_direction/regions/**`, o
  `08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png` do Master Package, o
  `work/production_art_gate/9H12D_astra_approved/region1_l1_hybrid_visual_authority_v1.png` e o
  `KOLIANI_REGION_CANON.md`.
- **Artefacto do harness (não é defeito provado).** Ao trocar de cena muito depressa, o balão de fala
  do chefe anterior ficou visível na cena seguinte. Exemplos: "Guardian of the Skies" no N12, "Zeriko"
  no N32 (`cmp_regiao_03/07`). Pode ser um leak real do autoload `Dialogo` numa troca de cena a meio
  de uma fala, mas só se viu no harness. Fica para o agente de UI/fluxo.

---

## 1. Causas-raiz (o que explica quase todos os sintomas)

### RC1 — P0 · O pipeline de ambiente é genérico. A identidade regional é só uma troca de paleta.
- **Terreno: 7 materiais para 20 regiões.** `scripts/plataforma.gd:40` (`BIOMAS`) só conhece
  `floresta, prisao, torres, catacumbas, cidade, castelo, desfiladeiro`. Os níveis 31–100 sorteiam
  entre estes 7 (medido no campo `bioma =` das 100 cenas). Exemplos: `catacumbas` serve para magma,
  oceano, gelo, deserto e o Vazio; nos N31–N100 (medido), `castelo` aparece em 17 níveis de 11 regiões, `torres` em 18 níveis de
  10 regiões e `catacumbas` em 16 níveis de 10 regiões. As 14 regiões novas não têm nenhum
  material próprio. E o
  material "próprio" da Região II é, segundo `assets/sprites/pixel/terreno/terreno.json`,
  `"fonte": "torres (recolorido)"`.
- **Fundos: 14 packs CC0 que rodam.** `scripts/atmosfera.gd:366` (`PACKS_POR_REGIAO`): `luar`
  aparece em 15 das 17 regiões IV–XX e `horror` em 14. O próprio comentário diz que é "uma paleta"
  que escolhe um pack já existente. A "identidade" de cada capítulo é `LUZ_REGIAO`
  (`atmosfera.gd:397`), uma cor de modulação. Isto contradiz a regra escrita em
  `tools/afinar_atmosfera.py:128`: "um pack nunca em duas regiões".
- **Prova em runtime.** As mesmas nuvens de pixel gigante aparecem nas Regiões XIV (Planícies
  Celestiais), XVI (Cânion Sangrento) e XVIII (Cidade Caída) (`cmp_regiao_14/16/18`). As serras
  vermelhas são as mesmas na XIX. O mesmo "arco com trepadeira" branco de baixa resolução aparece
  nas VII, XV, XVII e XX (`cmp_regiao_07/15/17/20`).
- **Efeito.** Nenhuma troca de cor transforma um pack de nuvens numa Biblioteca Proibida, numa
  Abadia Afogada ou num Laboratório. As pranchas pedem **arquitetura específica**: estantes
  flutuantes, vitrais submersos, tanques de espécimes, pontes de ossos. Essa arquitetura não existe
  em nenhum asset.

### RC2 — P0 · Só a Região I tem um kit de produção. As pranchas II–XX são conceito, não assets.
- A Região I tem `assets/art/regions/region_01_forest/production/` com kit_9c (terreno, props,
  corrupção, atmosfera), um panorama HD ×4 e l1_hybrid_9h12e. Tem **gate de produção**
  (`docs/production_art_gate_*.md`, 9A→9H). É a única que passou de "board" para "kit".
- As Regiões V–XX têm **uma única** `master_production_board.png` (1225–1672 px de largura)
  cada: uma pintura-mosaico com atlas, inimigos e boss em miniatura. Nada disto é recortável à
  escala do jogo, e nenhuma ferramenta a lê (`grep art_direction/regions` em `tools/` e `scripts/`
  só encontra as Regiões II e III).
- As Regiões II–IV têm atlas separados (`asset_atlas*.png`, `enemy_gameplay_pack.png`,
  `boss_pack.png`). Só da **II** e da **III** se extraíram inimigos e props
  (`tools/extrair_inimigos_regiao02/03.py`, `extrair_props_regiao02.py`). Da **IV** não se
  extraiu nada.
- **Resultado.** Mesmo que o level design estivesse certo, não há material para pintar 19 regiões.
  É o problema de "falta de kits por região", e está a montante de tudo o resto.

### RC3 — P0 · A campanha jogável é a da estrutura antiga; o canon de 15 set nunca chegou às cenas
- `scripts/estado_jogo.gd:165` (`REGIOES`) e `world.*` nos i18n ainda são o plano de
  3 set (`docs/plano_niveis_31_100.md`). O canon (`KOLIANI_REGION_CANON.md`, commit `67b68b24`,
  15 set) prevalece por regra, mas **só a Região II coincide no nome**:

| # | Canon (autoridade) | Jogo (`world.*`, pt) | Boss canon | Boss no jogo (N×5) |
|---|---|---|---|---|
| I | Floresta Sagrada | Floresta Corrompida | ~~Guardião Verde~~ → **Coração Putrefacto** (decisão do GM de 25/09) | Coração Putrefacto ✔ |
| II | Desfiladeiro dos Ventos | Desfiladeiro dos Ventos ✔ | Guardião dos Céus | Guardião dos Céus ✔ (rig de código) |
| III | Torre dos Ecos | Torres Esquecidas | Vyrak | Vyrak ✔ (rig de código) |
| IV | Fornalha | Catacumbas do Abismo | Guardião da Fornalha | Olho do Abismo ✘ |
| V | Cidades Flutuantes | Cidade Corrompida | Oráculo do Vento | Noiva do Eclipse ✘ |
| VI | Deserto das Ilusões | Castelo de Zeriko | Mirage Eterna | **Zeriko (final!)** ✘ |
| VII | Jardins Envenenados | Terras Queimadas | Rainha Espinhosa | Estrela Caída ✘ |
| VIII | Catacumbas da Fome | Mar dos Mortos | Devorador da Cripta | Mãe do Abismo ✘ |
| IX | Abadia Afogada | Reino do Gelo | Abade Naufragado | Ymiria ✘ |
| X | Biblioteca Proibida | Deserto dos Esquecidos | Arconte do Conhecimento | Deus Esquecido ✘ |
| XI | Costa Afundada | Jardins do Rei | Senhor das Marés | Rei Botânico ✘ |
| XII | Terras Envenenadas | Cidade das Máquinas | Arauto da Pestilência | Máquina-Rei ✘ |
| XIII | Torre Invertida | Céu Partido | Soberano Invertido | Astrónomo ✘ |
| XIV | Planícies Celestiais | Reino dos Sonhos | Oráculo Estelar | Outra Koliani ✘ |
| XV | Laboratório Sombrio | Cidade dos Mortos | Arquialquimista Morvak | A Própria Morte ✘ |
| XVI | Cânion Sangrento | Mar Vermelho | Malgor | O Mar ✘ |
| XVII | Jardim Onírico | Inferno | Rainha do Sonho | Rei dos Demónios ✘ |
| XVIII | Cidade Caída | O Vazio | Colosso da Ruína | A Entidade ✘ |
| XIX | Portal Dimensional | Guerra dos Reinos | Arquiteto do Limiar | O Campeão ✘ |
| XX | Trono de Zeriko | O Último Caminho | Zeriko | "Zeriko, Apenas um Homem" (rig `cavaleiro_negro`) ≈ |

  Fontes: `scripts/catalogo_campanha.gd` (`CHEFE_KEY`), cenas `N×5` (`ChefeCoracaoPutrefacto`,
  `ChefeGuardiaoDosCeus`, `ChefeVyrak`, `ChefeOlhoDoAbismo`, `ChefeNoivaDoEclipse`,
  `ChefeZerikoFinal`, e `ChefeGenerico` do N35 ao N100). Confirma e atualiza
  `docs/audits/region_level_structural_audit.md` §4, que ainda dava o Primeiro Prisioneiro como boss
  do N10.
- **O conflito mais grave de canon é o N30.** `O_Trono_de_Zeriko.tscn` com `ChefeZerikoFinal` é
  o final da campanha antiga de 30 níveis e está a meio da campanha de 100. No canon, o N30 é a
  Mirage Eterna.
- **Conflito dentro do material aprovado.** A prancha `08_REGION_I_ART_KIT…png` intitula-se
  "Região I — **Floresta Corrompida**", e o canon diz "Floresta Sagrada". O canon declara que o texto
  do documento prevalece sobre o texto dos PNG. O jogo seguiu o PNG. **Decisão do GM pendente:
  nome da Região I.**
- **Ordem temática invertida.** O jogo tem gelo, máquinas, sonhos, inferno e guerra, que não
  existem no canon. O canon tem biblioteca, abadia, laboratório, torre invertida e portal, que não
  existem no jogo. Não há 1:1 possível: das 14 regiões novas, 14 têm tema errado.

### RC4 — P1 · Bosses: 3 específicos por código, 17 genéricos que reciclam rigs
- **Como os bosses são construídos.** Tirando o Coração Putrefacto (kit da Região I), os bosses são
  "pixel-art" montada por código: juntas + primitivas (`tools/chefes_corpos.py`: `elipse`,
  `trapezio`, `caixa`) em `tools/gerar_chefes_anim.py`.
- **Sintoma no ecrã.** Leitura chapada e com poucos tons, longe do detalhe das pranchas. O Vyrak do
  jogo é uma túnica azul com auréola feita de trapézios (`img/a4/N015_boss.png`). No `boss_pack.png`
  da Região III é um colosso de ouro e sinos com cerca de 4× a altura da Koliani. O Guardião dos Céus
  (`N010_boss.png`) é um pássaro azul em blocos, e o da prancha é uma águia negra-roxa com penas.
- **Reciclagem nos níveis 51–100.** `scripts/chefe_lore.gd:17` distribui ~50 bosses por **22 rigs**:
  - `cavaleiro_fogo` × 6 (Foguista, Sentinela do Inferno, Duque, Rei dos Demónios, Campeão, Zeriko Absoluto);
  - `cavaleiro_negro` × 5 (incluindo 2 dos 3 Zerikos);
  - `horror` × 4;
  - `entrevane` × 3 (é o guardião da Região I);
  - `aerion` × 2 (é o guardião do N12).
- **Prova em runtime.** Os bosses do N40 e do N90 são o mesmo demónio verde alado, e os do N85 e do
  N95 são o mesmo cavaleiro de fogo (`img/a4/folha_20_bosses_jogo.jpg`). Os projéteis são
  `Polygon2D` em losango de cor `hash(forma)` (`chefe_lore.gd:76`).
- **Arenas.** Do N35 ao N95 as arenas são **o mesmo template**: laje de tijolo suspensa sobre um chão
  e um `LiquidoMortal`. Só a cor muda (`folha_20_bosses_jogo.jpg`, linhas 2–4). O N100 tem
  **1 plataforma** (`log_captura.txt`: `N100 plats=1`) e o N30 tem 2.

### RC5 — P1 · Densidade de texel incoerente (mistura de resoluções)
- **Os números.** Os packs de fundo têm 240 px de altura e desenham-se a escala 4.4–6.0
  (`atmosfera.gd:200+`), o que com a câmara a 1.4 dá **≈6–8 px de ecrã por texel**. A Koliani do
  golden set e o kit HD da Região I estão perto de 1:1. O terreno legado, os props CC0 e os inimigos
  de packs (Pixel Adventure, Kings and Pigs) ficam a meio caminho.
- **Sintomas visíveis:**
  - fundos em escada (as nuvens de `luar`/`montanhas`);
  - o feto em primeiro plano do N005 com pixels ~8× maiores do que a Koliani (`img/a4/N005_p1.png`);
  - a coluna de pedra e a janela gótica do N007 a 1/4 da resolução das plataformas
    (`N007_p1.png`, `cmp_regiao_02`);
  - as cascatas azuis em blocos do N020 (`N020_boss.png`).
- **A Região I também sofre.** O kit HD é pintado, mas o chão, o `LiquidoMortal` (faixa cinzenta
  ondulada) e os pêndulos são legados.
- **Contraste com as pranchas.** Todas as pranchas usam **uma** densidade de texel e contorno
  escuro coerente. Hoje é esta mistura que mais faz o jogo parecer "montado com peças".

### RC6 — P1 · Hazards e mecânicas desenhados em polígonos que não pertencem a região nenhuma
- **Pêndulos.** `PenduloLamina` (`scripts/pendulo_lamina.gd:19,33`, `Polygon2D`) é um losango
  branco-azulado **plano** com uma haste fina. Aparece igual nas Regiões I, IV, V, VII, VIII, XI,
  XII e XV (capturas `N005_p1`, `N017_p1`, `N022_p2`, `N032_p2`, `N037_p1`, `N052_p2`, `N057_p2`,
  `N072_p1`). É, a par da água, o elemento visualmente mais "placeholder".
- **Outros elementos em polígono/código.** A água venenosa (`agua_venenosa.gd`, `Polygon2D`), a
  faixa do `LiquidoMortal`, as serras de engrenagem cinzentas e as plataformas de luz (retângulos
  planos castanho-claros, p. ex. `N035`, `N047_p2`) também são desenhadas em código.
- **Escala do problema.** 77 scripts em `scripts/` desenham com `Polygon2D`/`draw_*`.
- **O que as pranchas pedem.** Hazards específicos da região: sinos-armadilha, lâminas pendulares
  góticas, jatos de lava, vitrais, correntes de maré, esporos. Nenhum deles tem sprite.

### RC7 — P2 · Inimigos: packs CC0 genéricos fora das Regiões II e III
- **Regiões I–III.** A I tem inimigos de produção (`region_01_forest/enemies/production`). A II e a
  III têm espécies extraídas das pranchas (`gaivota_sombria`, `golem_aereo`, `morcego_dos_ventos`,
  `automato_do_sino`, `construto_vitral`, …).
- **Da IV em diante.** Aparecem abóboras, goblins verdes, porcos (Kings and Pigs), cogumelos e
  diabinhos — ver as capturas `N022_p1` (goblins verdes), `N047_p1`, `N067_p1/p2` (abóboras) e
  `N092_p1` (cubos vermelhos).
- **Nenhum dos ~150 inimigos desenhados nas pranchas V–XX existe como sprite.**

---

## 2. Auditoria por região

Legenda de fonte:
- **LEG** = asset legado CC0 anterior às pranchas;
- **PROC** = gerado por ferramenta ou código (`gerar_terreno.py`, `gerar_deco.py`,
  `gerar_fundos*.py`, `afinar_atmosfera.py`, `Polygon2D`);
- **OUT** = asset que pertence a outra região.

Em todas as regiões a Koliani é o golden set: `usar_golden_set = true` nas 100 cenas.

### Região I — canon "Floresta Sagrada" / jogo "Floresta Corrompida" (N1–N5)
**VISUAL MATCH TO APPROVED ART: HIGH (ambiente) / MEDIUM (conjunto)**
Capturas: `N002_p0–p2`, `N002_boss`, `N003_p1`, `N005_p1/p2`, `N005_boss`; `cmp_regiao_01.jpg`.
- **O que corresponde à arte aprovada:**
  - plataformas-pilar de rocha com musgo e raízes, folhagem carmesim, cristais vermelhos e lanternas;
  - a árvore vermelha em primeiro plano;
  - o fundo azul-violeta com castelo e cascatas.
  - Tudo isto casa com o `region1_l1_hybrid_visual_authority_v1.png`. A paleta e a silhueta estão
    certas e o Coração Putrefacto lê-se como uma entidade de raízes com núcleo magenta.
- **Arte aprovada existente mas não usada:** a Heart Tree magenta do `08_…PARALLAX` (panorama
  principal) não se vê nas capturas dos N2/N5, e as 4 variantes de mood por nível (entrada, ruínas,
  cascatas, Heart Tree próxima) também não. Os 5 níveis leem-se todos como a mesma noite azul.
- **Placeholders/legado:**
  - pêndulos em losango `Polygon2D` (PROC, `N005_p1`, `N002_p1`);
  - a faixa do `LiquidoMortal` e o chão cinzento (PROC);
  - um feto de pixel gigante em primeiro plano (LEG, resolução errada, `N005_p1`);
  - uma plataforma magenta lisa (`N003_p1`, PROC).
- **Composição:** as plataformas são pilares isolados e repetidos ("cogumelos" de rocha), com pouca
  massa de chão, e o 70% inferior do ecrã fica vazio e escuro. A prancha de gameplay (bottom-left do
  `08`) tem chão contínuo, colunas e arcos.
- **Ação: TUNE (P2).** Trocar os hazards PROC por arte, meter a Heart Tree e os moods por nível e
  retirar os props LEG de outra resolução. **Manter como padrão de qualidade.**

### Região II — Desfiladeiro dos Ventos (N6–N10)
**VISUAL MATCH: LOW**
Capturas: `N007_p0–p2`, `N007_boss`, `N010_p0–p2`, `N010_boss`; `cmp_regiao_02.jpg`.
- **O que corresponde:** a paleta violeta, a lua/torres góticas ao fundo no N10, os estandartes e
  as gárgulas-estátua extraídos da prancha, e o nome do boss.
- **O que não corresponde:**
  - o terreno é tijolo azul de masmorra (`desfiladeiro` = "torres recolorido", PROC/LEG) em lajes
    finas;
  - não há falésias, pontes com arcos, ilhas suspensas com rocha pendente nem mar de nuvens com
    volume;
  - o fundo `desfiladeiro` é um composto de 240 px (`tools/gerar_fundos_regiao02.py`, PROC) com
    serras em escada;
  - a coluna e a janela gótica do N007 estão a ~¼ da resolução (`N007_p1`);
  - o N10 fica **sobre-exposto a magenta** (`N010_boss`), quando a prancha é violeta-cinza com
    nuvens brancas;
  - o boss é um corpo de primitivas (RC4).
- **Arte aprovada não usada:**
  - `asset_atlas_tileset.png` (tiles de terreno, pontes com arcos, plataformas com correntes);
  - `asset_atlas_level_assets.png` quase todo;
  - os `ELEMENTOS DE VENTO` (rajadas desenhadas);
  - as 4 layers de parallax da prancha;
  - as 8 poses e 8 ataques do `boss_pack.png`.
- **Ação: MAJOR REWORK (P0)** — terreno, fundo e boss.

### Região III — canon "Torre dos Ecos" / jogo "Torres Esquecidas" (N11–N15)
**VISUAL MATCH: LOW**
Capturas: `N012_p0–p2`, `N015_p1`, `N015_boss`; `cmp_regiao_03.jpg`.
- **O que corresponde:** a paleta azul-noite, alguns lustres e candeeiros, e os nomes de nível e de
  boss da prancha.
- **O que não corresponde:**
  - o fundo `torre_ecos` é gerado em PIL a 240 px (`tools/gerar_fundo_torre_ecos.py`, PROC): torres
    triangulares e arcos em polígonos azuis chapados, sem ouro, sem vitrais, sem sinos gigantes;
  - o terreno são lajes finas de tijolo azul (`torres` = pack "church", LEG) a flutuar no vazio;
  - a prancha é a torre monumental dourada e azul, com pontes-aqueduto e vitrais iluminados;
  - o Vyrak é um boneco de trapézios com auréola (RC4), sem sinos nem armadura dourada;
  - a arena do N15 é uma laje de tijolo, quando a prancha pede o grande sino e o topo da torre.
- **Arte aprovada não usada:**
  - `asset_atlas.png` inteiro (chão, escadas, rampas, arcos, colunas, plataformas especiais, props,
    hazards como os sinos-armadilha e a laser de luz);
  - `layout_usage.png`;
  - `boss_pack.png` (poses, ataques e arena de fase 2).
  - O elevador de coluna já está referido como "não extraído" em `docs/retomar_aqui.md`.
- **Ação: MAJOR REWORK (P0).**

### Região IV — canon "Fornalha" / jogo "Catacumbas do Abismo" (N16–N20)
**VISUAL MATCH: NONE**
Capturas: `N017_p0–p2`, `N017_boss`, `N020_p0–p2`, `N020_boss`; `cmp_regiao_04.jpg`.
- A prancha é laranja e vermelha, com lava, engrenagens, tubos, correntes e máquinas. O jogo mostra
  uma gruta preto-acinzentada com tijolo castanho (`catacumbas` = pack Szadi, LEG), uma caveira
  gigante e um olho-boss rosa redondo.
- A decisão do GM de 25/09 diz que prevalecem as pranchas da IV, e nada foi feito.
- **Arte aprovada não usada:** todos os 7 PNG (atlas, boss_pack, enemy_pack, layout, mechanics,
  implementation, concept).
- **Assets de outra região:** caveira/ossos de catacumba e pêndulos PROC. A cascata azul em blocos
  (`N020_boss`) está numa região de fogo.
- **Ação: REBUILD (P0).**

### Região V — canon "Cidades Flutuantes" / jogo "Cidade Corrompida" (N21–N25)
**VISUAL MATCH: NONE**
Capturas: `N022_*`, `N025_*`; `cmp_regiao_05.jpg`.
- A prancha é céu diurno azul e dourado, cidades brancas nas nuvens e o Oráculo alado. O jogo é um
  céu vermelho-sangue de pixel gigante (pack `cidade`/`vilanoite`, LEG), com lajes castanhas, um
  poço e goblins verdes. O boss é a Noiva do Eclipse, não o Oráculo do Vento.
- **Ação: REBUILD (P0).**

### Região VI — canon "Deserto das Ilusões" / jogo "Castelo de Zeriko" (N26–N30)
**VISUAL MATCH: NONE**
Capturas: `N027_*`, `N030_*`; `cmp_regiao_06.jpg`.
- A prancha é dunas e catedrais soterradas ao pôr do sol, em paleta areia e âmbar. O jogo é um
  interior roxo-escuro de castelo, com um arco lilás de pixel enorme (LEG) e o **Zeriko final** no
  N30 (RC3). A arena do N30 tem 2 plataformas.
- **Ação: REBUILD (P0)**, com decisão de narrativa sobre o N30.

### Regiões VII–XX (N31–N100): todas **VISUAL MATCH: NONE**
Estas 14 regiões correm a mesma máquina: `gerador_corredor.gd` (jornada procedural), 1 de 7
materiais, 1 de 14 packs, `LUZ_REGIAO` e o boss `ChefeGenerico`/`ChefeLore`. O que muda entre elas
é a cor.

| Reg. | Prancha pede | Jogo mostra (capturas) | Não usado da prancha | Fontes no ecrã |
|---|---|---|---|---|
| VII Jardins Envenenados | estufas góticas, rosas carmesim, água tóxica verde, Rainha Espinhosa | escuro teal, arcos brancos de trepadeira em pixel gigante, serras, pêndulos; boss N35 = figura laranja numa laje sobre magma (`N032_*`, `N035_boss`) | atlas de sebes, estufas, vitrais; 12 inimigos; boss | LEG `horror`/`castelo_velho`, PROC pêndulos, OUT (magma de "Terras Queimadas") |
| VIII Catacumbas da Fome | ossários dourados à luz de velas, Devorador de ossos | teal-cinza vazio, rocha de gruta; boss N40 = demónio verde alado (`N037_*`, `N040_boss`) | atlas de ossários, 8 inimigos, arena | LEG `caverna`/`gruta`, PROC |
| IX Abadia Afogada | abadia gótica submersa, azul-petróleo, tempestade | teal-escuro, tijolo azul, engrenagem laranja; boss mago azul (`N042_*`, `N045_boss`) | tiles náuticos, 6 inimigos, níveis de maré | LEG `montanhas`/`gruta`, PROC |
| X Biblioteca Proibida | estantes flutuantes, portais, roxo e dourado | pinheiros-silhueta magenta, lajes castanhas; boss "homem de laranja" (`N047_*`, `N050_boss`) | livros-plataforma, portais, Sentinela do Vazio (elite) | LEG `rochoso`/`luar` |
| XI Costa Afundada | recife bioluminescente, navios, medusas | pântano verde-oliva, galhos; boss árvore (rig `entrevane`, OUT-R1) | tudo | LEG `floresta`/`pantano`, OUT |
| XII Terras Envenenadas | pântano ácido verde-lima, moinhos, Arauto | teal vazio, fios, montanha; boss sobre nuvens rosa (`N057_*`, `N060_boss`) | tudo | LEG `cidade`/`vilanoite`, PROC |
| XIII Torre Invertida | torre invertida azul e dourada, lustres | nuvens cor-de-rosa gigantes, rocha laranja; boss "olho" roxo (`N062_*`, `N065_boss`) | tudo | LEG `montanhas`/`rochoso` |
| XIV Planícies Celestiais | céu diurno branco e dourado, mármore | nuvens verde-oliva/ocre de pixel gigante, abóboras (`N067_*`) | tudo | LEG `luar`/`horror`, inimigos LEG |
| XV Laboratório Sombrio | tanques verdes, alquimia, Morvak | arcos brancos de trepadeira (os mesmos da VII), tijolo castanho (`N072_*`) | tudo | LEG, OUT (VII) |
| XVI Cânion Sangrento | ravina vermelha, cascatas de sangue, Malgor | as mesmas nuvens verde-oliva da XIV (`N077_*`); boss demónio de fogo | tudo | LEG `luar`, OUT (XIV) |
| XVII Jardim Onírico | jardim lilás ao luar, estátuas | a mesma sala verde de arcos da VII/XV (`N082_*`); boss cavaleiro de fogo sobre vulcão | tudo | LEG, OUT |
| XVIII Cidade Caída | metrópole gótica cinza em ruínas, colosso | as mesmas nuvens da XIV/XVI (`N087_*`); boss = o mesmo demónio verde do N40 | tudo | LEG, OUT (VIII) |
| XIX Portal Dimensional | portais roxos, geometria impossível | serras vermelhas em escada, cubos vermelhos (`N092_*`); boss = o mesmo cavaleiro de fogo do N85 | tudo | LEG `rochoso`, OUT (XVII) |
| XX Trono de Zeriko | cidadela magenta, lua negra, Zeriko de coroa | a sala verde de arcos pela 4.ª vez (`N097_*`); N100 com 1 plataforma e um humano genérico (`N100_boss`) | tudo, incluindo o Zeriko | LEG, OUT |

Em todas estas regiões:
- **Terreno:** lajes finas de tijolo de 1 de 7 materiais. Nunca há os tiles das pranchas.
- **Profundidade:** 2–3 camadas de pack a 240 px, sem primeiro plano, sem névoa por camadas e sem
  silhueta própria.
- **Iluminação:** `CanvasModulate` e cor de luz regional. Não há fontes de luz diegéticas da região
  (tanques, lava, vitrais).
- **Arenas:** o mesmo template de laje sobre `LiquidoMortal` (RC4).
- **Ação: REBUILD (P0)** — depende de RC2 e RC3.

---

## 3. Balanço por área (formato do briefing)

| Área | CURRENT STATE | WHAT WORKS | WHAT DOES NOT WORK | BENCHMARK GAP | KOLIANI OPPORTUNITY | ACTION | P |
|---|---|---|---|---|---|---|---|
| Identidade regional | 1/20 com kit; 19 = recolor | Região I; paletas por região já pensadas | pack e terreno partilhados; `LUZ_REGIAO` faz de identidade | Hollow Knight: cada zona tem arquitetura, fauna e música próprias | as pranchas já têm 20 identidades fortes e diferentes (Biblioteca, Abadia, Portal…) | REBUILD (pipeline de kits) | P0 |
| Canon / mapeamento | 2–3/20 coerentes | Região II; Vyrak | nomes, temas e bosses de 17 regiões; Zeriko no N30 | — | decidir UMA tabela e migrá-la | MAJOR REWORK (dados + cenas) | P0 |
| Terreno / tiles | 7 materiais | as camadas capa/corpo/lado/pendura do `plataforma.gd` são uma boa estrutura | material e silhueta iguais; lajes finas | Dead Cells: tiles com volume e remates | usar a estrutura por camadas com materiais das pranchas | PARTIAL REWORK | P0 |
| Fundos / parallax | 14 packs CC0 a 240 px + 2 PROC | panorama HD da Região I | pixel gigante, repetição entre regiões | Hollow Knight / Nine Sols: parallax pintado e coerente | as pranchas já definem as 4–5 layers por região | REBUILD (fora da I) | P0 |
| Bosses | 3 próprios, 17 rigs reciclados | Coração Putrefacto; o motor de rigs anima | primitivas chapadas, sem as poses nem os ataques das pranchas | Nine Sols / Hollow Knight: silhueta e telegraph únicos | 20 `boss_pack`/boards com fases e ataques já desenhados | MAJOR REWORK | P1 |
| Inimigos | II/III extraídos; resto packs CC0 | espécies da II/III | abóboras, goblins e porcos numa região de alquimia | — | ~150 inimigos já concebidos nas pranchas | MAJOR REWORK | P1 |
| Hazards | `Polygon2D` genéricos | legíveis | sem região e sem arte | Celeste: o hazard é parte do cenário | hazards-assinatura por região (sino, maré, esporo) | PARTIAL REWORK | P1 |
| Consistência de pixel | texel 1:1 a 1:8 | Koliani (golden set) consistente em todos os níveis | mistura de resoluções | — | fixar 1 densidade de texel (a do golden set / kit da I) | TUNE + regra de pipeline | P1 |
| Koliani | golden set nos 100 níveis | coerente, com rim magenta | — | — | — | KEEP | — |

---

## 4. Causa-raiz de o jogo divergir da arte aprovada (síntese)

1. **Ordem invertida no tempo.** Os 100 níveis foram gerados a 3 set com a tabela antiga
   (`plano_niveis_31_100.md`), com ferramentas procedurais e packs CC0. O canon e as pranchas
   chegaram a 15 set **por cima** disso, e só as Regiões I–III foram depois "renovadas". A campanha
   é a antiga com renovações pontuais.
2. **O pipeline de arte é procedural e partilhado.** `gerar_terreno.py`, `gerar_fundos*.py`,
   `afinar_atmosfera.py`, rigs de primitivas e `Polygon2D`. Isso escala para 100 níveis, mas só
   produz variações de cor do mesmo conjunto. A pergunta "que material/pack?" tem 7/14 respostas
   possíveis; a pergunta "que arquitetura?" não tem resposta nenhuma.
3. **Não existe o passo prancha → kit** para as Regiões IV–XX. A Região I prova que o passo
   funciona: gate 9A–9H, kit_9c, panorama HD. Foi feito uma vez e não foi industrializado.
4. **Recolor por bioma foi tratado como identidade.** O `LUZ_REGIAO` e o `tinta_fundo` dão a
   ilusão de "cada região tem a sua cor", mas o briefing tem razão: troca de paleta não é
   identidade.

**Caminho recomendado (ordem):**
- **P0-a:** o GM fecha a tabela única região→tema→boss (canon vs jogo, incluindo o N30 e o nome
  da I).
- **P0-b:** transformar o gate de produção da Região I num **kit-template por região**, com o
  mesmo contrato de peças:
  - terreno topo/corpo/lado/base/pendura;
  - 4 layers de parallax;
  - 8–12 props;
  - 3–5 hazards;
  - 4–6 inimigos;
  - boss + arena.
  O `plataforma.gd` e o `Atmosfera` já aceitam isto via `Kit`. Produzir por ordem de campanha
  (II, III, IV…), nunca as 20 em paralelo.
- **P1:** uma regra de densidade de texel no pipeline, e a proibição de packs partilhados entre
  regiões.
- **P1:** bosses a partir de `boss_pack` (sprites pintados), com o motor de rigs usado só para
  animação.

---

## 5. RUNTIME VERIFIED vs STATIC ONLY

**RUNTIME VERIFIED** (janela real no 2.º monitor, via wrapper, 160 capturas):
- aparência de 40 níveis: N2/N5, N7/N10, N12/N15 … N97/N100, com 3 pontos cada, e das 20 arenas
  de boss regional + 20 encontros do nível 2;
- identidade visual dos bosses N5…N100, incluindo a repetição de sprites (N40=N90, N85=N95);
- template de arena igual do N35 ao N95; N100 com 1 plataforma e N30 com 2 (`log_captura.txt`);
- mistura de resoluções, pêndulos `Polygon2D`, reutilização de fundos entre regiões (XIV/XVI/XVIII,
  VII/XV/XVII/XX);
- a Koliani golden set presente em todos os níveis capturados;
- balão de fala a persistir entre cenas (**só no harness**, pode ser artefacto).

**STATIC ONLY — NOT RUNTIME VERIFIED:**
- tabelas `BIOMAS`, `PACKS_POR_REGIAO`, `LUZ_REGIAO`, `REGIOES`, `CHEFE_KEY`, `_rig_da_forma`;
- a origem PROC/LEG de cada asset (lida em ferramentas e JSON);
- a contagem de 77 scripts com desenho procedural;
- os níveis não capturados (N1, N3, N4 e os 3 intermédios de cada região);
- o comportamento animado dos bosses (só se viu 1 frame);
- a Heart Tree "ausente" da Região I (vista só nos pontos capturados, pode aparecer noutra zona);
- a leitura em ecrã de telemóvel (tudo foi capturado a 1280×720).

**Save real:** SHA256 no fim da auditoria =
`9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238`. **Igual ao inicial, intacto.**
