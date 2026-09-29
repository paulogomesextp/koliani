# Execução "arte das pranchas" -- Regiões I a III (29 set 2026)

Pedido do Paulo: "tivemos tanto tempo a aprovar artes por nivel, mas ficou
tudo muito fraco em relação aos assets que foram dados" e depois "faça como
achar melhor, eu quero que o jogo fique com a arte melhor". Branch
`claude/project-thread-8ipy7k`, commits pequenos, sem mexer em combate nem
na geometria/colisão dos níveis. O N11 (cena) não foi tocado: só herda o
fundo, o terreno e os props novos da Região III.

## Método (o mesmo para tudo)

Recortar **1:1 das pranchas aprovadas** em `docs/art_direction/regions/`,
sem pintar nem inventar: fundo escuro da prancha -> alfa, ampliação 2x com
Lanczos (+ unsharp nos panoramas), tudo em ferramentas re-corríveis.
Nenhum PNG editado à mão.

## O que mudou

| Região | Antes | Agora | Ferramenta |
|---|---|---|---|
| II (N6-N10) fundo | camadas CC0 de 240 px esticadas 4-7x | panoramas A/B de `concept_environment_01/02` + mar de nuvens com alfa por luminância | `tools/gerar_fundos_regiao02_prancha.py` |
| II terreno | tijolo CC0 recolorido (laje roxa lisa) | pedra talhada com musgo e vinhas do `asset_atlas_tileset.png`; `CascaMasmorra` repintada (6 células) | `tools/gerar_terreno_prancha.py desfiladeiro` |
| III (N11-N15) fundo | pack `torre_ecos` genérico | panorama de `region_03/concept_environment.png` | idem fundos |
| III terreno | mosaico CC0 "church" 192 px (o problema que o N11 já tinha medido) | material NOVO `torre_ecos` (tiles de terreno da prancha); escolhido por `fundo_pack` em `plataforma.gd` (`MATERIAL_POR_PACK`), os outros 18 níveis do bioma `torres` ficam iguais | `tools/gerar_terreno_prancha.py torre_ecos` |
| III props | 21 formas geométricas (sinos trapézio, vitrais em grelha) | recortados de `region_03/asset_atlas.png`, **mesma altura** que tinham (escala no mundo igual) | `tools/gerar_props_prancha.py` |
| I (N1-N5) | copa do primeiro plano cortada a direito no topo do ecrã | degradê ondulado na borda de baixo de `ramos`/`ramo_curvo` | `tools/produzir_l1_hybrid_9h12e.py` |

Código: `scripts/atmosfera.gd` (perfis n06-n10 e pack `torre_ecos` com a
flag `arte_aprovada`: filtro linear, tinta de só 30% do bioma, limpa as
camadas CC0 antigas do pack; banda de céu por cima começa exactamente no
topo da imagem -- correcção global que tirou um degrau visível) e
`scripts/plataforma.gd` (`_nome_material`, altura da `base` passa a ser a da
textura fora do kit da Região I).

## Números medidos

- Escala do panorama da Região II: 0,75-0,8 com base y 600-640 (1,36 era
  enorme, abaixo de 0,7 saía do ecrã). Região III: 1,1 / y 720.
- Topo da capa do terreno: saturação 0,78 (a carmesim pura gritava mais do
  que a Koliani sob a luz magenta).
- `ramos.png` tinha 39% da última linha opaca, `ramo_curvo.png` 35%.

## Hipóteses descartadas (não repetir)

- **Corpo do terreno por espelhamento**: vê-se a simetria de caleidoscópio.
- **Corpo por segmentação em pedras soltas e fiadas ao acaso**: a prancha é
  pequena e irregular, apanhava fundo e contornos -> ruído. O que resultou:
  recortes de junta a junta, dois lado a lado, trocados na segunda fila.
- **Franja da base só por alfa de cor**: bolhas soltas a flutuar debaixo da
  laje. Resolvido com o terço de cima opaco à força (`franja`).
- **Véu mais forte no pântano do N1** (`veu_forca` 2-3): repete-se como
  papel de parede e não tira a leitura de banda chapada. Revertido.

## Armadilhas de método

- `tools/produzir_l1_hybrid_9h12e.py` regrava TODO o kit e ficheiros
  *seguidos no git* em `work/production_art_gate/9H12E_astra_production/`
  com outros tamanhos (o `work/` foi mexido depois por outras execuções).
  Depois de o correr, fazer `git checkout` de tudo o que não se queria mudar
  (os PNG do kit saem pixel-idênticos, só muda a codificação).
- `gerar_props_torre_ecos.py` / `gerar_tileset_regiao02.py` /
  `gerar_terreno_regiao02.py` desfazem este trabalho se corridos depois:
  correr a ferramenta "prancha" correspondente a seguir (nota nos docstrings).
- Depois de regerar PNG é preciso `--headless --import`, senão o jogo e os
  screenshots mostram a textura antiga.

## O que ficou por fazer

- Actores da Região III ainda em polígono: `SinoTorre` sem `textura` (só o
  N12 a define; o N11 é de outra conversa) e o `Vitral` (as texturas mudam a
  altura da colisão -- precisa de cuidado de gameplay). Props `braseiro`,
  `memorial`, `pedra_talhada` ainda geométricos.
- A superfície do pântano/abismo (`agua_venenosa.gd`) continua uma banda
  escura chapada no N1 e no N5 e na faixa cinzenta das torres.
- N16-N100 não foram tocados.

## Testes

Suite completa na cabeça da branch: 2 falhas, ambas explicadas.
- `pack 'torre_ecos': camada 'MarBaixo' nao existe no Parallax` -- o teste
  só aceitava as camadas da cena; a `MarBaixo` é criada por código pelo
  `atmosfera.gd`. Teste actualizado.
- `golem piloto: Cleave ... mais eficiente que o spam` -- **não é
  regressão**: com um `user://` novo passa (ttk 1,5 / 0,93, igual ao
  master); falha só a reutilizar o sandbox de uma corrida completa
  anterior (ttk do cleave 7-9 s). É o estado gravado pela própria suite a
  contaminar o teste (o mesmo mecanismo do aviso do CLAUDE.md). Correr a
  suite sempre com o sandbox limpo (`tools/correr_testes.ps1` já o faz).
