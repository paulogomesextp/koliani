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

## FEITO (5 set 2026, 3.ª passagem) — 11 provisórias a menos

As linhas `# ~` da `MECANICA_DO_NIVEL` eram 52; passam a **41**. Nenhuma
destas onze precisou de actor novo — o que muda é a **regra da sala**, e é
por isso que saíram todas de uma vez.

| Nível | Câmara nova | O que a distingue da parecida |
|---|---|---|
| 33 A Forja dos Demónios | `martelos` | as `guilhotinas` são uma por plataforma, cada uma no seu tempo; aqui o chão é contínuo, a linha inteira bate e há um jacto de forja entre martelos — pede passo, não espera |
| 52 Labirinto Verde | `bifurcacao` | três bocas, duas mentem. É o labirinto **sem** a `SalaLabirinto` (em pausa desde 30 ago por softlock): um beco só se oferece com a volta atrás à vista e a um salto |
| 55 Árvore do Rei | `raizes` | a fila de raízes irrompe em cadeia — atravessa-se entre duas quem anda ao passo delas |
| 79 Fortaleza Kraken | `varredura` | os `pendulos` penduram-se do tecto e cortam o vão (passa-se por baixo); estes ancoram por baixo do convés e varrem o chão (salta-se por cima) |
| 81 Portão Infernal | `prensa_fogo` | a `prensa` e o `fogo` no mesmo compasso: a parede empurra para o jacto e o jacto acende quando ela chega. O buraco seguro anda |
| 83 Rio das Almas | `correnteza` | a `CorrenteLateral` empurra para trás o trecho todo. Estreia o actor que estava no repo desde 5 set **sem nenhuma câmara a usá-lo** |
| 87 Segundo Vazio | `sem_chao` | rajadas de impulsor encadeadas e ilhotas do tamanho dos pés. A única câmara em que não é o salto dela que a leva à frente |
| 91 Campo de Batalha | `catapulta` | a `chuva` é o tecto a desfazer-se num beiral; aqui vem tudo de fora e o chão é largo, para haver para onde correr |
| 92 Céu em Guerra | `salvas` | o `crossfire` dispara sempre, cada torreta no seu tempo; aqui disparam **todas ao mesmo tempo** — lê-se o compasso, não a linha de tiro |
| 94 Torre da Corrupção | `assalto` | a `torre` é uma subida limpa; esta é a mesma subida com as torretas todas do mesmo lado |
| 96 O Reino Antes da Corrupção | `memoria` | a única câmara **sem perigo nenhum**. Só funciona porque as anteriores ensinaram a desconfiar |

### Segunda leva: três REGRAS de bicho (e cinco linhas mal marcadas)

Estas mexem no `DemonioBase` -- não no `comportamento` (esse continua a
mandar no andar), mas na regra de quem lhe pode tocar, do que ele deixa
atrás e de quando se mexe:

| Nível | Câmara | A regra |
|---|---|---|
| 58 Fábrica dos Homúnculos | `replicantes` | `divide_em`: morre e parte-se em duas cópias mais pequenas e mais rápidas. **As filhas já não se dividem** -- uma cadeia enchia a sala sozinha, e a jornada não tem chão de rede onde isso fosse justo. A sala é fechada por grade: não se passa por cima do problema |
| 68 Quarto das Crianças Mortas | `estatuas` | `so_mexe_sem_olhar`: param quando ela olha. Metade nasce **atrás** da entrada -- é o que obriga a virar-se, e virar-se é o que pára a sala |
| 73 Catedral Fantasma | `incorporeo` | `so_tiro`: a espada e o pisão atravessam-nos, só o tiro lhes toca. Nunca tranca nada (o tiro é ilimitado) -- muda a distância a que o problema se resolve |

> A proposta dizia, para o 58, "replica-se **se não for morto depressa**".
> Ficou **partir-se ao morrer**: limitado por construção, e um temporizador
> a criar bichos numa sala fechada é uma espiral, não uma mecânica.

O `so_tiro` obrigou a uma porta nova: `DemonioBase.receber_tiro()`. É a
única maneira de o bicho saber que o dano veio de longe -- e o
`projetil_koliani.gd` passa por lá agora (quem não a tiver leva na mesma).

E **cinco linhas estavam marcadas `# ~` sem o serem**: são escolhas, não
falta de actor. N64 (a `grav_baixa` um grau acima, do corte do "nadar"),
N71 (a ponte fantasma **é** a `sinos`, assinatura da região XV), N89 e N90
(os dois cortes do Paulo) -- e o N76, que repetia `espinhos` sem razão
nenhuma, passa a ter a **maré de sangue** que o guia lhe dá.

**Provisórias: 52 → 33.** Sobreposição: **0.227**.

### Uma bancada nova: `tools/verifica_regras_bicho.gd`

As três regras vivem no `DemonioBase`, e a suite **não o consegue
instanciar**: em `--script` os autoloads que ele usa não existem como
identificador. Esta corre à parte (e no CI), e as oito asserções foram
partidas de propósito antes de passarem -- duas delas apanharam bugs a
sério: o `float(null)` do `_koliani_a_olhar` quando o nó do grupo não é a
Koliani, e uma expectativa de vida que ignorava a curva de dificuldade
aplicada no `_ready`.

### Terceira leva: sete câmaras e cinco actores novos

| Nível | Câmara | Actor novo | O que a distingue |
|---|---|---|---|
| 51 Jardim das Rosas Negras | `rosas` | — (`Espinhos` em ciclo) | a `espinhos` é fixa e salta-se; aqui o chão é contínuo e o que muda é **quando** se pode estar em cada sítio |
| 60 Coração da Máquina | `imanes` | **`Iman`** | campos que atraem e repelem a alternar. O cenário está parado e o salto é o de sempre -- o que muda é a conta, e muda a meio do voo |
| 75 Trono da Morte | `ceifa` | **`Ceifa`** | uma lâmina rasa varre a sala de ponta a ponta. Os `pendulos` deixam sempre um lado livre; esta não |
| 82 Cidade dos Demónios | `brasas` | **`ChaoQuente`** | o chão queima quem fica parado. Não é uma armadilha de reflexos -- é uma sala que não deixa pensar de pé, e os bichos estão lá para isso |
| 86 Primeiro Vazio | `olhar` | **`PlataformaOlhar`** | as plataformas do meio só existem enquanto ela está virada para elas. Andar em frente acende o caminho; o que se perde é poder olhar para trás |
| 93 Cerco ao Castelo | `ariete` | **`Ariete`** | a porta só abre a empurrar a máquina até lá, e a máquina é a única cobertura contra as torretas. Nunca recua nem fica presa: se ela se afastar, espera |
| 97 O Primeiro Castelo | `revisao` | — | quatro câmaras de regiões diferentes, seguidas. A única câmara do jogo cujo assunto é o próprio jogo -- e só escolhe entre coisas que já estrearam |

**Provisórias: 33 → 26.** Sobreposição: **0.222**.

### `tools/verifica_actores_novos.gd` — e três falhas que eram da bancada

Os cinco actores constroem a própria área/corpo em código e nenhum tem cena
de editor onde se veja se está certo. A bancada apanhou:

- **medir frames em vez de tempo não funciona em headless.** Os frames
  correm o mais depressa que conseguem: 30 frames podem ser 30 ms, e um
  actor com um ciclo de 0.25 s nunca lá chegava. Três "falhas" que não
  existiam. (E a física em headless anda ~10% atrás do relógio -- as
  esperas levam folga.)
- **`await physics_frame` num `SceneTree` em `--script` fica pendurado.**
  O `process_frame` é que anda.
- o `Ariete` só se conseguiu testar depois de deixar de tocar em `Alavanca`
  e em `Som` **pelo identificador** (passou a `get`/`set`/`has_signal` e a
  `/root/Som`) -- de outra forma o script não compila em `--script` e a
  bancada ficava sem o poder ver. É a armadilha dos autoloads outra vez.
- e um bug a sério do desenho: o `PlataformaOlhar._aplicar(bool)` colidia
  com o `_aplicar()` que a `Plataforma` já tinha. O script **não compilava**
  e a verificação das jornadas continuava a dizer "TUDO OK", porque a
  plataforma falhava em silêncio.

### Quarta leva: o chão escorregadio (N41) — a primeira que mexe nela

| Nível | Câmara | O que muda |
|---|---|---|
| 41 Floresta Congelada | `gelo` | a `ZonaGelo` baixa a **aceleração horizontal** dela. Como a travagem usa a mesma aceleração, um só número dá as duas metades da sensação: custa a arrancar e custa a parar. O salto é o de sempre e os vãos são os de sempre -- o que desaparece é a travagem, e o problema deixa de ser saltar e passa a ser **parar antes da beira** |

O parâmetro vive na lógica **pura** (`Movimento.passo(..., acel_escala)`),
ao lado do `grav_escala` que a `ZonaGravidade` já usava -- e por isso está
coberto pela suite normal, sem bancada nenhuma à parte
(`teste_movimento_gelo_custa_a_arrancar_e_a_parar`). O mínimo é 0.15: mais
do que isso e ela deixava de conseguir mudar de sentido a tempo de nada, e
o gelo passava de mecânica a castigo. As placas nunca cobrem a plataforma
toda -- há sempre pedra onde se recupera o pé.

**Provisórias: 26 → 25.**

### Quinta leva: os dois primeiros ESTADOS dela (N45 e N48)

Os inimigos já tinham `queimar`/`sangrar`/`atordoar` desde o passe de
combate. **Ela não tinha nenhum.**

| Nível | Câmara | O estado |
|---|---|---|
| 45 Coração do Inverno | `frio` | sopros gelados que a deixam lenta uns segundos **depois** de sair deles. O `gelo` (N41) é um sítio escorregadio -- sai-se de lá e acabou; isto anda com ela, e o que se gere passa a ser *quando* se atravessa o vão a seguir |
| 48 Vale dos Escorpiões | `veneno` | as nuvens marcam e o dano vem depois. É o primeiro perigo do jogo que **não se resolve a sair de cima dele** -- atravessar a correr custa na mesma. Por isso o corredor tem uma varanda limpa por cima: o caminho mais longo é o caminho são |

O veneno passa à frente dos i-frames e do escudo de propósito: um estado
que se pudesse bloquear com o escudo levantado não era um estado, era mais
um golpe. E vê-se -- ela fica esverdeada envenenada, azulada gelada. Vida a
descer sem nada no ecrã lê-se como bug.

### O bug que a bancada apanhou: **as áreas em código nunca lhe tocavam**

Todas as áreas construídas em código ficavam com a **máscara de omissão**
(layer 1, o mundo). A Koliani vive na **layer 2**. Ou seja: `Iman`,
`ChaoQuente`, `Ceifa`, `ZonaGelo`, `ZonaEstado`, a zona de empurro do
`Ariete` -- e a `CorrenteLateral`, que estava assim desde que nasceu --
**nunca a teriam apanhado no jogo**. A `Armadilha` já fazia isto certo
(`collision_layer = 0`, `collision_mask = 2`) e foi o molde.

Nada disto aparecia na verificação das jornadas: os níveis construíam-se
todos, "TUDO OK", e as mecânicas simplesmente não existiriam a jogar.

E outra armadilha da bancada, para não voltar a descobrir: **a Koliani não
fica onde a põem** -- no `_ready` salta para o checkpoint guardado no save.
Sem limpar isso (e sem chão por baixo), o que a primeira versão do teste
mediu foi a **queda no vazio**: "provou" um veneno a tirar 158 de vida em
1.2 s. Com ela pousada, tira 4.

**Provisórias: 25 → 23.**

### Sexta leva: tirar-lhe a vista (N40, N49) e o cemitério que se repete (N72)

| Nível | Câmara | O que muda |
|---|---|---|
| 40 Abismo Oceânico | `escuro` | noite fechada com um buraco de luz à volta dela. A `velas` (N18) também é escura, mas lá a luz **acende-se e fica**; aqui não há nada para acender -- a luz anda com ela, e o que se perde é poder ler a sala antes de entrar. Por isso a geometria é honesta: vãos curtos, nada escondido. O escuro é o problema, não uma tampa por cima de outro |
| 49 Cidade Enterrada | `areia_no_ar` | a tempestade não escurece, **tapa**. Vê-se tudo mal em vez de se ver só um círculo -- e por isso esta sala já pode ter perigo lá dentro: tira a nitidez, não a informação |
| 72 Cemitério Infinito | `ciclo` | três bocas iguais e só uma sai; as outras devolvem à entrada. A `bifurcacao` (N52) mostra as bocas falsas (uma tem essência, outra um elite) -- aqui são iguais, e o que se perde é **tempo**, não vida |

O véu vive numa `CanvasLayer` própria que **nasce à entrada e morre à
saída** (um véu esquecido por cima do jogo seria pior do que não haver
escuro nenhum) e o buraco de luz é um recorte em `BLEND_MODE_SUB`, não uma
luz do motor -- funciona igual com as luzes do bioma ligadas ou desligadas.

**Provisórias: 23 → 20.** Bancada: 25 asserções.

### Sétima leva: duas regras que se multiplicam, e três linhas mal marcadas

| Nível | Câmara | O que muda |
|---|---|---|
| 74 Palácio dos Reis Mortos | `mausoleu` | as estátuas do N68 **dentro** do escuro do N40. Cada uma sozinha é uma regra; juntas são outra coisa: elas só andam quando ela não olha, e agora ela não vê o que está fora do círculo. Olhar para trás deixou de ser grátis -- é o único sítio onde se pode olhar, e é lá que elas estão |
| 88 Labirinto Impossível | `gemea` | a mesma sala duas vezes, com **uma** coisa diferente. A segunda constrói-se com a mesma semente da primeira -- é literalmente a mesma sala --, e depois troca-se uma peça: onde havia um degrau passa a haver espinhos. Não pede reflexos, pede memória. E a diferença é sempre um perigo, nunca um caminho que desapareça: enganar-se custa vida, nunca fecha a passagem |

E mais **três linhas estavam marcadas `# ~` sem o serem**: N57 (Linha 13 --
o guia diz "tapete rolante", que é a `tapete` um grau acima), N66 (Vila dos
Sonhos -- "portais que se movem" é a `portal` grau 2, assinatura da região
XIV) e N100 (o duelo de espada vive na cena do chefe; o último nível nem
sequer tem jornada).

**Provisórias: 20 → 15.**

### Oitava leva: o relógio dela, a curva e o compasso único

| Nível | Câmara | O que muda |
|---|---|---|
| 38 Palácio das Sereias Mortas | `ar` | o relógio passa a ser **dela**: não há ciclo para ler no cenário, há fôlego, e ele acaba. As bolsas de ar enchem-no -- e é a distância entre elas que faz a sala, por isso são poucas, estão sempre à vista, e nunca no caminho curto. Há barra por cima dela: ficar sem ar sem contador à vista lê-se como dano vindo do nada |
| 77 Serpentes do Mar | `serpente` | um obstáculo **comprido** em movimento contínuo. Tudo o resto que magoa é um ponto (serra), uma linha (guilhotina) ou uma parede (prensa); esta é uma curva que atravessa a sala e nunca está duas vezes no mesmo sítio. Não se decora, lê-se -- e por isso o convés é largo e limpo |
| 80 Coração Vermelho | `pulsacao` | a sala inteira num **só compasso**: guilhotinas, jactos e raízes partilham o `periodo` e as fases são frações dele. Depois do `martelos` (contratempo) e do `salvas` (todos ao mesmo tempo), é a terceira maneira de usar o tempo -- aprende-se a batida uma vez e serve para a sala toda |

**Provisórias: 15 → 12** -- e das 12 que restam, **7 são os "grandes"**
(N53 gancho, N63 asas, N65 queda longa, N67 inverter a gravidade, N69
sombra com atraso, N70 cenário que se reescreve, N98 perder uma
habilidade). As outras cinco: N54 (esporos -- a inversão de controlos foi
retirada do jogo pelo Paulo), N56 (plataforma que roda), N78 (convés que
inclina), N84 (reflexo hostil) e N99 (tudo desbloqueado, que é uma bandeira
do nível e não uma câmara).

Bancada: 31 asserções.

### O primeiro dos "grandes": PLANAR (N63) — e afinal era pequeno

A proposta punha "Planar (N15) + Asas (N63)" na lista dos 14 grandes e o
Paulo aceitou a fusão em "uma habilidade em dois graus". Feita, são **oito
linhas** na lógica pura: a cair, com o botão de saltar a segurar, a queda
prende-se a `VEL_PLANAR` (190 px/s) em vez do `VEL_MAX_QUEDA` (1100).

Duas decisões que valem a pena guardar:

- **vem depois do corte de salto.** Ao contrário, o corte deixava de
  acontecer no frame em que ela começa a descer -- e o corte de salto é
  metade da pegada do salto.
- **planar é cair devagar, não voar.** Só vale a descer, e por isso tudo o
  que se atravessa a planar é para baixo. A câmara `asas` (N63) tem o vão
  em queda a seguir ao coletável, e **os degraus da rota longa atravessam o
  mesmo vão aos saltos**: planar é o caminho curto, nunca o único -- quem
  não apanhe a habilidade não fica trancado.

Habilidade nova em `HABILIDADES_TODAS` e nos seis `i18n`. Coberta pela
suite (`teste_movimento_planar_prende_a_queda`), incluindo a asserção de
que **não pode cortar o salto**.

**Provisórias: 12 → 11**, e restam **6 grandes**.

### O segundo "grande": a SOMBRA COM ATRASO (N69)

Grava o caminho dela e anda por ele três segundos depois. **Não decide
nada -- repete**, e é isso que a separa de um perseguidor: não se despista
(vai onde ela foi), não se combate (atravessa-se), e a única maneira de a
manter longe é não voltar atrás. Quem pára apanha a própria decisão de há
três segundos em cima.

Por construção não pode encurralá-la: só vai a sítios onde ela já esteve.
E o rasto é uma **fila**, não um histórico -- deita fora tudo o que é mais
velho do que o atraso, senão uma sala comprida enchia a memória de pontos.

A sala é feita para a mecânica: comprida, de sentido único, com um desvio
para cima a meio que serve de descanso -- e o descanso custa exatamente o
tempo que a sombra leva a chegar lá.

**Provisórias: 11 → 10.** Restam **5 grandes** (N53 gancho, N65 queda
longa, N67 inverter a gravidade, N70 cenário que se reescreve, N98 perder
uma habilidade). Bancada: 35 asserções.

### E as pools das regiões, que era o buraco maior

As 16 estreias de 5 set (`lava_sobe`, `mare`, `espectral`, …) **não estavam
em pool nenhuma**: apareciam uma vez em 100 níveis — a estreia forçada — e
nunca mais. As pools das regiões VII a XX continuavam a ser as mesmas 12
câmaras de sempre, e era isso que fazia o 2.º acto saber ao 1.º. Agora cada
região leva as suas (o filtro por nível de estreia continua a mandar: uma
câmara que estreie depois nunca aparece antes).

Medido com `tools/verifica_jornada.gd` (sobreposição de Jaccard entre
níveis seguidos, menos é melhor):

| | |
|---|---|
| antes desta passagem | 0.275 |
| **depois** | **0.234** — menos 15% |

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
