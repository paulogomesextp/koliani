# Referência visual da Koliani (rig)

O Paulo partilhou (2 set 2026, no chat) uma **folha de referência
pixel-art** da Koliani com todas as animações do rig (IDLE / RUN / JUMP /
ATTACK / CROUCH / WALL SLIDE / DOUBLE JUMP). O ficheiro em si ainda **não
está no repo** — o agente não consegue guardar imagens coladas no chat.
**Pedir ao Paulo para o largar aqui como `koliani_ref.png`.**

## O que a referência mostra

Guerreira **gótica grunge**, ~jovem:

- **Cabelo** castanho-escuro morno, farto/despenteado, com **faixa** na testa.
- **Pele** quente / tan (não pálida).
- **Fato**: colete/arnês de **couro preto** com correias e fivelas,
  braceletes com pregos, brincos. **Motivo de caveira** na anca/cinto.
- **Capa esfarrapada** roxo-ameixa empoeirado (o único roxo forte do
  design — bordas em farrapos).
- **Calças** cinza-esverdeadas escuras; **botas** pretas pesadas.
- **Magia** (só no ATTACK e no DOUBLE JUMP): fios/espíritos **lavanda
  pálido** com carinhas de fantasma. NÃO é magenta berrante.

## Paleta (tira de swatches, escuro -> claro)

`#20202a` · `#2e2e38` · `#3d3d4a` · `#4a4458` · `#5f5570` · `#6d4d7a`
(o roxo-ameixa da capa) · `#9a8fa0` · `#b8a890` (cinza morno) · `#e8dcc4`
(creme / realces).

## Como o `tools/importar_rig_cavaleiro.gd` mapeia o rig fonte para isto

O rig fonte ("Knight_player 1.4") tem **cabelo azul, roupa vermelha,
armadura cinza, pele pêssego**. O `_graduar()`:

- cabelo azul  -> castanho escuro morno (`REF_CABELO`)
- roupa vermelha -> capa roxo-ameixa, sempre escura (`REF_CAPA`)
- armadura/cinza -> couro near-black neutro (`REF_COURO`)
- pele -> mantém-se quente (`REF_PELE`)
- quase-branco -> creme-lavanda (`REF_REALCE`)

E o `_goticar()` faz só um *mood grade* leve (baixa a luz, afunda as
sombras para um escuro neutro). Sem rebordo néon — a referência não tem.

Afinar os `REF_*` contra o `koliani_ref.png` quando ele estiver no repo.
