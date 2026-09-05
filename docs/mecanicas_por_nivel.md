# Uma mecânica nova por nível — proposta para aprovação

> **Isto é uma proposta, não é código.** O Paulo pediu:
>
> > *"Joguei até Nível 37 e acho que o jogo tem poucas mecânicas, analise
> > outros jogos e faça muito mais mecânicas. E mude o raciocínio: em vez de
> > ir adicionando mais mecânicas e ir misturando e pôr mais quantidades em
> > níveis mais altos, tente pôr uma mecânica nova a cada nível, e aumente a
> > dificuldade das mecânicas à medida que o nível aumenta."*
>
> A tabela abaixo é a resposta: **100 níveis, 100 mecânicas, uma por
> nível.** Antes de se escrever uma linha de código, ele diz o que corta,
> o que troca e por onde se começa.

---

## A regra

Hoje o jogo tem ~33 "câmaras" (`CAMARAS_FLAVOUR` no `gerador_corredor.gd`)
que a jornada **sorteia e mistura**, com a dificuldade a abrir mais tipos à
medida que o nível sobe (`TIER_FLAVOUR`). É exactamente o raciocínio que ele
quer trocar.

A regra nova, em três linhas:

1. **Cada nível ESTREIA uma mecânica.** No nível em que estreia, ela aparece
   sozinha e mansa — é o tutorial dela, sem texto.
2. **Depois disso pode voltar, sempre mais dura.** Cada mecânica tem um
   **parâmetro** que escala com o número do nível (a coluna "escala").
3. **A mecânica da estreia manda no nível.** Ela é o assunto; o resto do
   nível encosta-se a ela.

Isto substitui o `TIER_FLAVOUR` (que abre mecânicas por patamar de
dificuldade) por uma **tabela nível→mecânica**. O `PERFIL` de forma
(vertical/horizontal, foco, amplitude) fica como está — trata do desenho do
espaço, não das mecânicas.

## O que já existe, e o que é preciso construir

Das 100 linhas:

| | Quantas | O que quer dizer |
|---|---|---|
| ✅ **Já existe** | **38** | Actor ou câmara já no jogo. É só passar a estrear no nível certo e ligar-lhe o parâmetro de escala. |
| 🔸 **Variação** | **17** | Reaproveita um actor que existe com uma regra nova (ex.: a lava que SOBE é a `AguaVenenosa` com um `y` a subir). Barato. |
| 🔶 **Novo, pequeno** | **31** | Actor novo mas de uma peça só — um script e uma cena, no molde dos que já lá estão. |
| 🔴 **Novo, grande** | **14** | Mexe na física da Koliani ou na estrutura do nível (nadar, gancho, gravidade rotativa, cenário que se reescreve). Cada um é uma sessão por si. |

Ou seja: **mais de metade da tabela já está construída ou quase.** O
trabalho de verdade são os 14 vermelhos — e é aí que ele pode cortar sem o
jogo perder a promessa de "uma mecânica nova por nível".

---

## Região I — Floresta Putrefacta (tutorial)

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 1 | Floresta Putrefata | **Raízes que irrompem do chão** — telegrafam e batem | menos aviso, mais juntas | ✅ |
| 2 | Pântano dos Sussurros | **Água mortal + ilhas** — o chão deixa de ser garantido | ilhas mais pequenas | ✅ |
| 3 | Ninho da Viúva Negra | **Teia que prende** — o movimento pode ser tirado | prende mais tempo, em cadeia | ✅ |
| 4 | A Árvore que Chora | **Ácido a pingar** — perigo vindo de cima | cadência, pingos duplos | ✅ |
| 5 | Coração da Floresta ⚔ | **Plataforma rítmica** — o cenário tem compasso | compasso mais rápido | ✅ |

## Região II — Prisão dos Condenados

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 6 | Prisão dos Condenados | **Alavanca → grade** — o caminho abre-se | duas alavancas; depois temporizada | ✅ |
| 7 | Fornalha dos Pecadores | **Lava que SOBE** — o nível tem pressa | sobe mais depressa | 🔸 |
| 8 | Corredor das Execuções | **Guilhotinas** — perigo de cadência fixa | cadências dessincronizadas | ✅ |
| 9 | Ala dos Mortos | **Inimigo que se levanta outra vez** | mais ressurreições | 🔶 |
| 10 | A Cela Zero ⚔ | **Prensa / paredes que varrem** | menos folga entre elas | ✅ |

## Região III — Torres Esquecidas

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 11 | Torre dos Sinos | **Badalada → ponte fantasma** — o som é a chave | janela mais curta | ✅ |
| 12 | Torre dos Ventos | **Correntes de ar** — o salto deixa de ser só teu | rajadas que alternam | ✅ |
| 13 | Torre da Tempestade | **Raios em coluna**, padrão previsível | padrão mais denso | ✅ |
| 14 | Observatório Lunar | **Zona de gravidade** — o peso muda por sítio | inversão total | ✅ |
| 15 | O Pico Esquecido ⚔ | **Planar** (segurar salto na descida) | vento contra | 🔴 |

## Região IV — Catacumbas do Abismo

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 16 | Cemitério dos Reis | **Túmulo-elevador** — plataforma que se chama | mais lento a chegar | ✅ |
| 17 | Galeria dos Ossos | **Chão que desaba ao pisar** | menos tempo em pé | ✅ |
| 18 | Cripta das Mil Velas | **Escuridão + acender velas** | raio de luz menor | ✅ |
| 19 | Templo da Serpente | **Bloco empurrável** — mover o cenário | blocos que caem por ordem | 🔶 |
| 20 | O Abismo ⚔ | **Descer agarrada às paredes** | paredes intermitentes | ✅ |

## Região V — Cidade Corrompida

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 21 | Vila dos Sem Rosto | **Mímico** — o que parece cenário ataca | mais falsos, melhor disfarçados | 🔶 |
| 22 | Mercado da Carne | **Gancho de talho** — pendurar-se e balançar | ganchos mais curtos e afastados | 🔶 |
| 23 | Trem dos Mortos | **Carruagens em movimento** | mais depressa, vãos maiores | ✅ |
| 24 | Catedral da Corrupção | **Vitral que parte** | parte mais depressa | ✅ |
| 25 | Praça do Eclipse | **Dia/noite alterna o cenário** | alterna mais depressa | 🔶 |

## Região VI — Castelo de Zeriko (fim do 1.º acto)

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 26 | Portões de Zeriko | **Fogo cruzado de torretas** | cadência | ✅ |
| 27 | Salão dos Espelhos | **Espelho que larga um reflexo** | o reflexo copia os teus golpes | ✅ |
| 28 | Banquete dos Imortais | **Inimigos que se curam uns aos outros** — há uma ordem para matar | cadeias maiores | 🔶 |
| 29 | Torre do Coração Negro | **Perseguição vertical** — a torre desaba por baixo | sobe mais depressa | 🔴 |
| 30 | O Trono de Zeriko ⚔ | **Arena que muda entre fases** | — | ✅ |

## Região VII — Terras Queimadas

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 31 | Estrada das Cinzas | **Cinza funda** — anda-se devagar e afunda-se | mais funda | 🔸 |
| 32 | Rio de Magma | **Jangada que afunda com o teu peso** | afunda mais depressa | 🔸 |
| 33 | A Forja dos Demónios | **Martelos alternados** | sincronia mais apertada | ✅ |
| 34 | Vulcão do Rei Morto | **Chuva de bombas de lava** | mais densa | 🔶 |
| 35 | O Céu em Chamas ⚔ | **Colunas de fogo ascendentes** que empurram para cima | — | 🔸 |

## Região VIII — Mar dos Mortos

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 36 | Porto dos Afogados | **Maré que sobe e desce** | ciclo mais curto | 🔸 |
| 37 | Cidade Submersa | **NADAR** — física subaquática | correntes contra | 🔴 |
| 38 | Palácio das Sereias Mortas | **Ar limitado** — bolhas para respirar | menos bolhas | 🔶 |
| 39 | Ossário das Baleias | **Correntes de água que arrastam** | mais fortes | 🔸 |
| 40 | Abismo Oceânico ⚔ | **Escuridão total** — só a luz dela | — | 🔸 |

## Região IX — Reino do Gelo

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 41 | Floresta Congelada | **Chão escorregadio** — a travagem deixa de existir | menos atrito | 🔶 |
| 42 | Montanha dos Ventos | **Avalanche a perseguir** | mais depressa | 🔴 |
| 43 | Cavernas Cristalinas | **Reflectir luz em cristais** (puzzle) | mais espelhos na cadeia | 🔶 |
| 44 | Castelo Congelado | **Gelo que estala e parte** — quebra com aviso | menos aviso | 🔸 |
| 45 | Coração do Inverno ⚔ | **Congelação** — estado que a abranda | — | 🔶 |

## Região X — Deserto dos Esquecidos

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 46 | Mar de Areia | **Areia movediça** — puxa para baixo, sai-se a saltar | puxa mais | 🔶 |
| 47 | Templo Sem Nome | **Placa de pressão → armadilha** | menos aviso | 🔶 |
| 48 | Vale dos Escorpiões | **Veneno** — estado que tira vida ao longo do tempo | dura mais | 🔶 |
| 49 | Cidade Enterrada | **Tempestade de areia** — visão curta | vê-se menos | 🔶 |
| 50 | Pirâmide Negra ⚔ | **Bola de pedra a rolar** — fugir para a frente | — | 🔸 |

## Região XI — Jardins do Rei

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 51 | Jardim das Rosas Negras | **Espinhos que crescem em ciclo** | ciclo mais rápido | ✅ |
| 52 | Labirinto Verde | **Bifurcações falsas** — a `SalaLabirinto`, agora a sério | mais fundo | ✅* |
| 53 | Jardim das Almas | **GANCHO** — trepadeiras onde se engata e balança | pontos mais longe | 🔴 |
| 54 | Estufa Maldita | **Esporos que trocam os controlos** por 2 s | dura mais | 🔶 |
| 55 | Árvore do Rei ⚔ | **Raízes que crescem em tempo real** e fecham caminho | — | ✅ |

> \* a `SalaLabirinto` está **em pausa** desde 30 ago (softlock, paredes
> impossíveis). Estrear a mecânica aqui obriga a arranjá-la primeiro.

## Região XII — Cidade das Máquinas

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 56 | Distrito das Engrenagens | **Plataforma que roda** (engrenagem) | roda mais depressa | 🔶 |
| 57 | Linha 13 | **Tapete rolante** | o sentido alterna | ✅ |
| 58 | Fábrica dos Homúnculos | **Inimigo que se replica** se não for morto depressa | replica mais depressa | 🔶 |
| 59 | Torre Eléctrica | **Circuito** — ligar por ordem para abrir | mais nós na ordem | ✅ |
| 60 | Coração da Máquina ⚔ | **Ímanes** que atraem e repelem a Koliani | — | 🔶 |

## Região XIII — Céu Partido

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 61 | Ilhas Flutuantes | **Ilhas em órbita** — a plataforma anda em círculo | órbitas mais rápidas | 🔸 |
| 62 | Templo do Trovão | **Para-raios** — chamar o raio para abrir caminho | janela mais curta | ✅ |
| 63 | Cidade dos Anjos Mortos | **Asas** — voo curto e cronometrado | menos tempo de voo | 🔴 |
| 64 | Lua Quebrada | **Gravidade baixa** — o salto muda de escala | — | ✅ |
| 65 | O Fim do Céu ⚔ | **Queda longa com obstáculos** — o nível é a queda | — | 🔴 |

## Região XIV — Reino dos Sonhos

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 66 | Vila dos Sonhos | **Portais** — entra aqui, sai ali | portais que se movem | ✅ |
| 67 | Mundo Invertido | **Inverter a gravidade à vontade** (botão) | menos sítios onde vale | 🔴 |
| 68 | Quarto das Crianças Mortas | **Brinquedos que só se mexem quando não olhas** | mais e mais perto | 🔶 |
| 69 | Pesadelo | **A tua sombra repete os teus movimentos** com atraso | atraso menor | 🔴 |
| 70 | A Mente ⚔ | **O cenário reescreve-se atrás de ti** | — | 🔴 |

## Região XV — Cidade dos Mortos

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 71 | Avenida dos Mortos | **Ponte fantasma** — sólida só ao toque do sino | janela mais curta | ✅ |
| 72 | Cemitério Infinito | **A mesma sala até acertares na saída** | mais saídas erradas | 🔶 |
| 73 | Catedral Fantasma | **Inimigo incorpóreo** — só o tiro lhe toca | mais deles | 🔶 |
| 74 | Palácio dos Reis Mortos | **Estátuas que se mexem no escuro** | menos luz | 🔶 |
| 75 | Trono da Morte ⚔ | **Ceifa** — uma linha que varre a arena | — | 🔶 |

## Região XVI — Mar Vermelho

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 76 | Margem do Sangue | **Maré de sangue** — sobe e revela/tapa caminho | ciclo mais curto | 🔸 |
| 77 | Serpentes do Mar | **Serpente** — obstáculo comprido em movimento contínuo | mais rápida | 🔶 |
| 78 | Navio da Condenação | **Convés que inclina** — o chão muda de ângulo | inclina mais | 🔶 |
| 79 | Fortaleza Kraken | **Tentáculos que varrem** o convés | mais tentáculos | 🔶 |
| 80 | Coração Vermelho ⚔ | **Pulsação** — tudo no nível acelera ao ritmo | — | 🔶 |

## Região XVII — Inferno

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 81 | Portão Infernal | **Prensas de fogo** — prensa + queimar | — | 🔸 |
| 82 | Cidade dos Demónios | **O chão queima se ficares parado** | menos tempo parado | 🔶 |
| 83 | Rio das Almas | **Correnteza que empurra** para trás | mais forte | 🔸 |
| 84 | Palácio de Sangue | **Reflexo hostil** — o espelho ataca a sério | — | 🔸 |
| 85 | Trono Infernal ⚔ | **Arena em anel sobre lava** — sem cantos | — | 🔶 |

## Região XVIII — O Vazio

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 86 | Primeiro Vazio | **Plataformas que só existem enquanto olhas** | menos tempo visíveis | 🔶 |
| 87 | Segundo Vazio | **Sem chão** — só o que criares com impulsores | menos impulsores | ✅ |
| 88 | Labirinto Impossível | **Salas que se repetem com UMA diferença** | diferença mais subtil | 🔶 |
| 89 | A Coisa Atrás do Mundo | **Perseguidor invisível** — só o som o marca | mais perto | 🔴 |
| 90 | Centro do Vazio ⚔ | **A gravidade roda 90°** — o nível vira de lado | — | 🔴 |

## Região XIX — Guerra dos Reinos

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 91 | Campo de Batalha | **Catapultas** — pedras que caem do céu | mais densas | ✅ |
| 92 | Céu em Guerra | **Salvas de flechas** — ondas telegrafadas | ondas mais juntas | 🔶 |
| 93 | Cerco ao Castelo | **Aríete** — empurrar uma máquina sob fogo | mais lento, mais fogo | 🔶 |
| 94 | Torre da Corrupção | **Escada de assalto** — subir enquanto lhe atiram | — | 🔸 |
| 95 | Os Cem Guerreiros ⚔ | **Horda** — vagas com contador à vista | — | 🔶 |

## Região XX — O Último Caminho

| # | Nível | Mecânica que estreia | Como escala depois | |
|---|---|---|---|---|
| 96 | O Reino Antes da Corrupção | **Nível sem perigo** — memória, o reino como era | — | 🔶 |
| 97 | O Primeiro Castelo | **Revisão** — uma câmara de cada região, seguidas | — | 🔸 |
| 98 | O Coração de Zeriko | **Perder uma habilidade por sala** | — | 🔴 |
| 99 | O Fim de Tudo | **Tudo desbloqueado, energia sem limite** | — | 🔸 |
| 100 | O Último Salto ⚔ | **Duelo de espada** — sem poderes, sem HUD | — | 🔶 |

⚔ = nível de chefe.

---

## DECIDIDO (5 set 2026) — os 14 grandes ficaram em 7

O Paulo cortou três e aceitou as fusões. Fica assim:

### Cortados

| | Porquê |
|---|---|
| **N37 Nadar** | Física subaquática na Koliani. No lugar dele fica a **bolsa de gravidade baixa**, que já está construída: flutuar e cair devagar é o que a água faz ao corpo. A Cidade Submersa passa a estrear `grav_baixa`. |
| **N90 Gravidade roda 90°** | O mais caro da lista — câmara, controlos e geometria toda de lado. O **N67 (inverter a gravidade à vontade) fica**, e dá quase o mesmo espanto por uma mudança de sinal. |
| **N89 Perseguidor invisível** | **Não foi por preço.** Só é justo se o jogador ouvir, e o jogo joga-se no telemóvel, muitas vezes sem som — uma coisa que mata sem aviso lê-se como bug, não como tensão. No lugar dele fica a `espectral`. |

### Fusões aceites

- **N15 Planar + N63 Asas** = uma habilidade em dois graus. Estava mal
  classificada como "grande": segurar o salto para abrandar a queda são
  ~15 linhas.
- **N29 Torre a desabar + N42 Avalanche + N65 Queda longa** = **uma**
  máquina ("ameaça que avança e não se combate") com três caras. Dois dos
  três níveis já têm câmara real (`chuva` no 42, `queda` construída).

### O que sobra — 7 trabalhos, 1 grande

| | Trabalho | Tamanho |
|---|---|---|
| 1 | **Gancho** (N53) — engatar e balançar | **grande** |
| 2 | Inverter a gravidade à vontade (N67) | médio |
| 3 | Ameaça que avança (N29/N42/N65) | médio |
| 4 | Cenário reescreve-se atrás de ti (N70) | médio |
| 5 | A sombra com atraso (N69) | médio |
| 6 | Planar + Asas (N15/N63) | pequeno |
| 7 | Perder uma habilidade por sala (N98) | pequeno |

> **O gancho não se corta.** É a única da lista que muda todos os 100
> níveis e não só o dela. Se for preciso cortar mais um, o candidato é o
> N70 — é o que menos se nota a jogar, porque por definição acontece onde
> já não se está a olhar.

---

## Os 14 "grandes" — a proposta original (histórico)

Estes são os únicos que não cabem numa sessão a par de outra coisa. Por
ordem do que **muda mais o jogo** para o que muda menos:

1. **N37 Nadar** — física subaquática na Koliani. Abre a região VIII inteira.
2. **N53 Gancho** — a mecânica de mobilidade que mais falta ao jogo hoje.
3. **N67 Inverter a gravidade à vontade** — reaproveita a `ZonaGravidade`,
   mas passa a ser um botão do jogador.
4. **N90 A gravidade roda 90°** — o nível vira de lado. Caro, e espectacular.
5. **N15 Planar** / **N63 Asas** — a mesma família; talvez uma só mecânica em
   dois graus.
6. **N69 A sombra com atraso** — grava e reproduz os inputs dela.
7. **N70 O cenário reescreve-se atrás de ti**.
8. **N29 Perseguição vertical** / **N42 Avalanche** / **N65 Queda longa** — a
   mesma máquina (uma ameaça que avança e não se pode combater), três caras.
9. **N89 Perseguidor invisível** — depende do som, que agora já está bom.
10. **N98 Perder uma habilidade por sala**.

**Cortar qualquer um destes não parte a promessa** — o nível fica com uma
variação em vez de uma estreia. O que parte a promessa é cortar muitos: aí
volta-se ao "misturar as mesmas 33".

## O que muda no código, quando ele aprovar

1. `docs/mecanicas_por_nivel.md` (isto) vira uma **tabela em GDScript**,
   `MECANICA_DO_NIVEL`, no `gerador_corredor.gd` — ao lado do `PERFIL` e do
   `ASSIN_NIVEL`, que já fazem uma versão fraca disto.
2. O `TIER_FLAVOUR` (que abre mecânicas por patamar de dificuldade) deixa de
   mandar na estreia: passa a ser só a lista do que **já estreou** e pode
   voltar a aparecer.
3. Cada mecânica ganha um **parâmetro único** que escala com `_dif` — é a
   coluna "como escala".
4. Um teste na suite garante que **as 100 entradas existem e são
   distintas**, e que cada uma tem construtor (foi assim que se apanhou a
   câmara "pedras" a gerar um vão morto durante semanas).

## Perguntas para o Paulo

1. **Corta algum dos 14 grandes?** E há algum que queira ver primeiro?
2. **A estreia deve ser mansa mesmo?** A proposta é que no nível de estreia
   a mecânica não mate — só ensine. Isso amolece 100 momentos do jogo.
3. **A jornada procedural continua?** Hoje 99 níveis têm `corredor = false`
   (são salas desenhadas). A tabela funciona nos dois modos, mas nos níveis
   à mão a estreia tem de ser **colocada à mão** na sala.
4. **Há mecânicas dele que faltem aqui?** O `docs/mecanicas_catalogo.md` tem
   linhas que não entraram — New Game Plus, ranking de fase, troca de
   personagens, backtracking metroidvania. Ficaram de fora por serem
   estrutura de jogo, não mecânica de nível.
