# N11 — Entrada dos Ecos (refeito de raiz, 3 out 2026)

Cena: `scenes/levels/Torre_dos_Sinos.tscn` (nome e índice 10 mantidos — saves).
Gerador: `tools/construir_n11_entrada.py` (**editar lá, nunca no `.tscn`**).
Decisões: DEC-012 (sem guardião: 1.º nível da região), DEC-013 (uma sala fecha
até limpar), DEC-014 (refazer agora). Auditoria de origem:
`docs/qa/full_game_review/RELATORIO_AUDITORIA_N1_N19.md` (A4).

## Porque se refez

A cena anterior tinha ~1 000 px, terminava-se em 31 s e lia-se como
placeholder: os `SinoTorre` não tinham `textura` (desenhavam o polígono
amarelo de recurso) e as plataformas oscilantes eram `PlataformaFlutuante`,
que só sabe desenhar polígonos (lilás). Não era "arte provisória" a substituir
— eram nós sem arte nenhuma.

## Estrutura (~6 700 px, 5 checkpoints, 2 segredos)

| Secção | x | O que ensina / pede |
|---|---|---|
| A) Entrada | 0–1 160 | Landmark: o **grande sino da entrada** (sino_g ×2,6) a pender da arcada. Espinhos simples. **1.º sino de jogo** → ponte de eco sobre um vão **com rede**. A margem de lá fica 280 px acima da rede (acima do salto duplo ~250): sem a ponte só se volta para trás. |
| Encontro 1 | 1 120–1 780 | Sentinela (escudo) à frente de um Acólito (orbes), a > 140 px do muro. |
| 1.ª escalada | 1 760–2 080 | Muro de 290 px (acima do salto duplo) assente no chão: ensina `escalar_paredes` (dada no N10) sem risco. |
| B) Passarelas externas | 2 450–3 480 | 2 correntes móveis (horizontal/vertical, lentas), passarela quebrada (respawn 2,6 s), lâmina de sino LENTA (3,4 s). Sino Flutuante no vão alto. |
| Encontro 2 — **galeria selada** | 3 500–4 180 | `ArenaSelada`: Sentinela + Acólito ELITE + Acólito + Arqueiro na varanda interior. Fecha ao entrar, abre quando os 4 morrem. |
| Encontro 3 — poço do elevador | 4 180–5 300 | **Elevador de coluna** (300 px) sob fogo do Arqueiro no topo e de um Sino Flutuante; o pátio por baixo é rede (cair do topo devolve ao elevador). |
| C) Sala do grande sino | 5 240–6 700 | Encontro 4 (Sentinela + 2 Acólitos). O sino da sala fica **no fundo, atrás deles**: ergue a ponte final e gela os inimigos 2,6 s. Ponte final sem rede, com lâmina lenta — o exame. |

Segredos: alcova por cima da ponte da entrada (do átrio, 60 px para trás) e
nicho por cima da varanda da galeria selada.

## Componente novo: `scripts/arena_selada.gd`

`mec.arena` já tinha texto de ensino mas nenhum mecanismo que fechasse a
passagem (a câmara `arena` do gerador procedural só põe inimigos numa laje).
`ArenaSelada` (Area2D) é **opt-in por colocação** — nenhum sistema global
muda. Inimigos do encontro = filhos `DemonioBase` + grupo `grupo_inimigos`.
Ao entrar a Koliani, sobem duas grades (camada "mundo"); descem quando os
vivos = 0. Rede contra softlock: inimigo que sai da árvore conta como morto e
há `limite_seg` (90 s). Morrer recarrega a cena → a arena renasce aberta.

## Medições (bot oficial, com habilidades — ver D6)

`tools/correr_travessia.sh res://scenes/levels/Torre_dos_Sinos.tscn experiente normal casual`

| Perfil | Fim | Tempo | Mortes | Onde |
|---|---|---|---|---|
| experiente | porta | 102 s | 7 | correntes móveis (2 800), sala do sino, ponte final |
| normal | porta | 150 s | 12 | ponte final (6 400 ×6), sala do sino |
| casual | porta | 342 s | 29 | sala do sino (5 600 ×16), correntes móveis |

O bot é agressivo e não explora: um jogador novo deve levar 3–5 min.
A antiga cena: porta em 31–50 s.

Crivo de alcance dos 100 níveis: 0 portas inalcançáveis.
Teste: `teste_n11_entrada_autoral` (estrutura + arena fecha/abre).

## Armadilhas descobertas

- **`AguaVenenosa` mede pelo centro**: `position.y=1120` com `altura=340`
  põe o topo a 950 — a rede (1 000) matava. Agora 1 270 (topo 1 100).
- **O contrato de 28 set (GM) continua a valer**: `tests/test_region03_n11_level.gd`
  pedia muro de escalada, 1.º sino sem inimigos a < 140 px, elite e ≥ 2
  oscilantes. A 1.ª versão desta reconstrução esquecia a escalada — o teste
  apanhou-o. As oscilantes passaram a `PlataformaCorrente` (com arte).
- **Uma queda fatal debaixo de uma luta não ensina nada**: o casual morria
  14× a cair do topo do poço empurrado pelo Arqueiro. O pátio passou a
  continuar por baixo como rede.
- **O bot oficial não sabia tocar sinos**: atravessava pontes de eco só por
  acertar no sino a meio de lutas. E um golpe perdido no sino DESLIGA a
  ponte (tocar outra vez desfaz) — por isso o sino da sala saiu da zona de
  luta. O bot ganhou `_sino_por_tocar()`.

## Por decidir / playtest humano

- HUMAN PLAYTEST REQUIRED: tempo real (alvo 3–5 min), se o sino da entrada
  se percebe sem texto, e a dificuldade das correntes móveis (onde o bot
  mais morre).
- O experiente faz 102 s (critério global ≥ 90 s: cumprido, mas com
  pouca folga). O casual morre 16× no Encontro 4: confirmar em playtest se
  é exame justo ou pico.
- DEVICE VALIDATION REQUIRED (telemóvel).
