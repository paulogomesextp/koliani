# Região II — N10 exame final + Guardião dos Céus (Process 12)

## Estado

**TÉCNICO COMPLETO — HUMAN PLAYTEST REQUIRED** (17 set 2026).

Suite completa, harness próprio do chefe, os oito verificadores do CI,
glide do N08 e Movement+Camera: tudo PASS. Falta o percurso humano
(sensação, leitura dos telégrafos, justiça do vento na arena) e o passe
canónico de arte, que é do **Process 13**.

Branch `claude/region02-n10-guardian-skies`, base
`claude/region02-n08-glide@a5825950`.

## Antes → depois

| | Antes | Depois |
|---|---|---|
| Nível | `A_Cela_Zero.tscn` com jornada procedural à frente da sala | mesma cena e UID, agora `corredor = false`: o exame é a sala desenhada |
| Chefe | `ChefePrimeiroPrisioneiro` (duelo de espada, imitava a Koliani) | **`ChefeGuardiaoDosCeus`** (confronto regional canónico) |
| Vento | nenhum — o nível da região do vento não tinha vento | 3 zonas de exame + 1 zona de arena que o chefe comanda |
| Mecânica anunciada | nenhuma | `vento` |
| Carrossel / HUD | "Chefe: The First Prisoner" | "Chefe: Guardian of the Skies" (`boss.guardiao_dos_ceus`) |

O que **não** mudou: a topologia do poço em ziguezague, a bifurcação, o
elite orc da ledge central, o ácido do fundo, as duas fogueiras, a
`Porta`, o `ColProjetil` (recompensa de progressão) e todo o fluxo de
morte/respawn/save.

## O exame (o que a Região II ensinou, agora avaliado)

Nada de mecânica nova — só as leituras de N06–N09, encadeadas:

1. **`RajadaFavor`** (400, 820) — vento a favor na entrada: aproveitar.
2. **`CorrenteEsq`** (500, 420), 2500 de intensidade — corrente
   ascendente no poço esquerdo: subir com o vento, como no N07/N08.
3. **`RajadaContra`** (900, 420), pulsada 0,9 s / 1,6 s — vento contra no
   poço direito: esperar a pausa. A bifurcação passa a ser uma escolha
   entre duas leituras, e nenhuma é obrigatória.
4. **`VentoArena`** (640, 160) — nasce **parada**; é o Guardião que lhe dá
   sentido e força, e só depois de anunciar.

Cada zona tem `CollisionShape2D` com forma PRÓPRIA na cena (o bug
conhecido das zonas que partilham a forma faria o exame inteiro com o
tamanho da última). O `wind_zone.gd` não foi alterado nesse ponto: o bug
de N06/N07/N09 continua aberto e fora do âmbito.

## Guardião dos Céus

`scripts/chefe_guardiao_dos_ceus.gd`, cena
`scenes/actors/ChefeGuardiaoDosCeus.tscn`, herdando `ChefeBase` (vida,
dano, flash, estilhaços, sinal `derrotado`, prisão à arena, música de
chefe, afinamento de dificuldade). Rig animado `bosses_anim/monge_celeste`
— silhueta distinta dos outros 29 chefes; **arte final pendente**.

Voa sobre a plataforma principal e **desce a cada recuperação**: a fase
`EXPOSTO` põe-no ao alcance da espada, com o núcleo aberto. Um chefe
voador que nunca aterrasse seria inatingível para quem chega ao N10 com o
kit normal.

### Ataques

| | Ataque | Telégrafo | Resposta |
|---|---|---|---|
| 1 | **LÂMINA** — lâmina de vento dirigida à Koliani | `LAMINA_TEL`, 0,55 s a piscar, parado | saltar / afastar |
| 2 | **COMANDO DO VENTO** — vira a `VentoArena` para o lado da Koliani durante 3,4 s | `VENTO_TEL`, 0,82 s (1,5× o normal): o vento nunca entra sem aviso | reposicionar, andar contra o vento |
| 3 | **QUEDA** — picada a pique | `QUEDA_TEL`, 0,72 s, com **faixa de perigo desenhada no chão** (±96 px) a piscar | sair da faixa |

Entre ataques há sempre `EXPOSTO` (1,35 s). Não há ataque inevitável: os
três avisam-se, e a arena é maior do que qualquer zona de perigo.

### Fase 2 (~50% de vida)

`_abrir_asas()` dispara quando `vida <= 50%` da vida cheia da luta. Não
infla números às cegas:

- telégrafos a 0,78× (continuam a existir);
- LÂMINA passa a leque de três;
- o vento da arena passa a **pulsado** (0,8 s a soprar / 0,5 s de pausa) e
  1,18× mais forte;
- o ciclo encadeia **vento → lâmina**;
- `EXPOSTO` encurta 12% — mas mantém-se.

Números tocados: dano de contacto ×1,1, lâmina ×1,12, queda ×1,1.

### Vento: estado sempre reposto

O Guardião guarda o estado original da `VentoArena` e repõe-no quando:
morre (`receber_dano` → derrotado), a luta é interrompida e a cena sai
(`_exit_tree` — morte da Koliani, recarga, seletor). Sem isso, uma luta
interrompida a meio de um COMANDO deixava a arena a soprar para sempre.

`wind_zone.gd` ganhou **só** `definir_direcao()` (aditivo: muda o sentido
em runtime e redesenha as setas da guia, que senão ficavam a apontar para
o lado antigo). Nenhuma cena existente chama isto, portanto N06–N09 não
mudam.

## Testes

- `tests/test_region02_n10_level.gd` (na suite) — contrato estrutural:
  cena carrega, sala à mão, mecânica anunciada, identidade do chefe (é
  Guardião, **não** é o Primeiro Prisioneiro, nem o antigo fica na cena),
  chave do carrossel e i18n, as 4 zonas de vento com direção/modo certos,
  arena parada ao início e a cobrir o chefe, formas de colisão próprias,
  fogueiras, `ColProjetil`, Koliani canónica, ninguém larga `planar`.
- `tests/run_boss_guardiao_ceus.tscn` (harness no motor, nível REAL) —
  porta selada, vento parado, os três ataques executam, **cada golpe vem
  logo a seguir ao seu telégrafo**, `EXPOSTO` acontece, o COMANDO mexe
  mesmo na `WindZone`, fase 2 abre perto dos 50%, o chefe leva dano e
  morre, o baú nasce, recolher o baú abre a saída, a marca da queda não
  fica esquecida, e o vento volta ao repouso — inclusive quando a cena sai
  a meio do comando.

### Resultados (17 set 2026, Godot 4.7.2, APPDATA isolado)

| Verificação | Resultado |
|---|---|
| Suite completa (`tests/run_tests.tscn`) | PASS |
| Harness do Guardião | PASS |
| Glide N08 (`run_glide_region02`) | PASS (sem regressão) |
| Movement + Camera 4A | PASS |
| 8 verificadores do CI (bicho, atores, jornada, mecânicas, alcance 100, aerion, baú, câmaras) + spawn livre | PASS |
| Godot real (janela, `shot_plataforma`) | N10 carrega, Koliani canónica, intro do Guardião, arena e guias de vento; 0 erros novos |

Nenhuma falha nova. Nenhuma falha pré-existente encontrada nestes lotes.

### Mutações (prova de que os testes mordem)

| Mutação | Apanhada por |
|---|---|
| repor `ChefePrimeiroPrisioneiro` no nível | 4 falhas do contrato estrutural |
| fase 2 nunca abre (`vida <= 0`) | "a fase 2 abriu" |
| tirar a `Porta` | contrato + harness |

Todas revertidas; a árvore final não tem mutações.

## Limitações / para o playtest humano

- **Sensação da arena**: o vento comandado é legível? 1250 de intensidade
  na arena (contra 2500 da corrente do exame) é pressão ou estorvo?
- **Ritmo**: `EXPOSTO` de 1,35 s dá janela suficiente com o kit do N10?
- A vida sai do afinamento normal (`ChefeBase`): 540 base → ~1996 na luta.
  Números todos "a olho", como os dos outros chefes.
- A picada persegue o X da Koliani no telégrafo: ver se não fica injusta em
  cima da borda da plataforma.
- **Arte**: rig de pack (`monge_celeste`), sem passe canónico — Process 13.
- A lore escrita da Cela Zero (`clue.cela_zero_o_primeiro`) ainda fala do
  Primeiro Prisioneiro. O sistema de pistas está dormente no jogo e o texto
  não é usado pelo chefe; alinhar a história da sala fica para quando a
  Região II levar o passe narrativo.
