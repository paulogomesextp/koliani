# REGIÃO III — TORRE DOS ECOS · CONTRATO VISUAL E DE GAMEPLAY

**Níveis:** 011–015 · **Boss:** Vyrak, A Voz dos Ecos
**Fonte:** os 7 PNGs APPROVED em `docs/art_direction/regions/region_03/` +
[`KOLIANI_REGION_CANON.md`](../../KOLIANI_REGION_CANON.md) +
[`README.md`](README.md).
**Estado das pranchas:** a `implementation_sheet.png` marca **LOCKED** os seis
pilares (Conceito Geral, Inimigos, Boss Vyrak, Mecânicas dos Níveis, Level
Layout & Assets, Production Sheet) — "REGIÃO III 100% DEFINIDA, PRONTA PARA
IMPLEMENTAÇÃO".

> Este documento existe porque a Região II provou que dá para acertar na
> técnica e falhar na imagem. Aqui separa-se o que **não se negoceia**
> (LOCKED) do que fica ao critério da implementação (FLEX). Quando houver
> dúvida entre este texto e um PNG, **ganha o PNG**.

---

## 0. FICHEIROS LIDOS (todos)

| Ficheiro | O que fixa |
|---|---|
| `concept_environment.png` | Identidade, paleta, tiles, props, parallax, hazards, interativos, nomes dos 5 níveis |
| `boss_pack.png` | Vyrak completo: lore, sprites, 9 ataques, 2 fases, arena, recompensas |
| `enemy_gameplay_pack.png` | 10 inimigos com comportamento + ataques + tabela de progressão |
| `level_mechanics.png` | Por nível: tema, objetivo, mecânicas, elementos únicos, hazards, paleta |
| `layout_usage.png` | Por nível: fluxo A–D, set pieces, inimigos principais, rácios, segredos |
| `implementation_sheet.png` | Parâmetros técnicos, métricas-alvo, pipeline, estado LOCKED |
| `asset_atlas.png` | Atlas de tiles/props/FX + as 5 camadas de parallax |

---

## 1. IDENTIDADE — LOCKED

**Nome:** Torre dos Ecos · **Lema:** ALTURA • MEMÓRIA • SACRIFÍCIO ·
SINOS • ECOS • VERDADE
**Frases canónicas:** *"O que se ouve aqui, nunca se esquece."* ·
*"Onde o passado ainda fala."* · *"Os ecos não mentem. Apenas repetem o que
foi esquecido."* · *"Quanto mais alto sobes, mais longe se ouvem os teus
passos."*

Oito traços (de `concept_environment.png`), todos LOCKED:

1. Torre monumental, visível de longe
2. **Sinos e ecos como elemento central**
3. Arquitetura vertical e interligada
4. Mistura de sagrado e decadente
5. **Luz fria da lua + luz dourada dos sinos** (as duas fontes, em contraste)
6. Sensação de ascensão e descoberta
7. Segredos nas camadas da torre
8. Ambiente melancólico e misterioso

### Paleta — LOCKED

| Nome | Uso |
|---|---|
| Pedra antiga | tiles base, paredes |
| Dourado envelhecido / Ouro antigo | sinos, mecanismos, molduras, luz quente |
| Azul noite | fundo, ar |
| Azul profundo | sombras, poços |
| Luz de lua | contraluz, silhuetas, vitrais |
| Vitrais | acentos saturados (azul/roxo/âmbar) |
| **Acentos roxos (energia)** | eco, magia, aura espectral, Vyrak |

**Proibido:** verdes de floresta, castanhos de pântano, vermelhos de fornalha
como cor dominante. A vegetação existe só como detrito (heras, plantas secas).

---

## 2. OS CINCO NÍVEIS — LOCKED

Os nomes e subtítulos são canónicos (`concept_environment.png`,
`level_mechanics.png`, `layout_usage.png` concordam nos três):

| # | Nome | Subtítulo | Frase | Verbo |
|---|---|---|---|---|
| N11 | **Entrada dos Ecos** | O Primeiro Chamamento | "O eco desperta." | Aprende a ouvir |
| N12 | **Galerias Verticais** | A Ascensão | "Mais alto se ouve." | Sobe e descobre |
| N13 | **Mecanismos Antigos** | O Coração da Torre | "O passado move o presente." | Reativa o passado |
| N14 | **Campanário** | O Peso dos Ecos | "Cada sino lembra." | Sente o peso |
| N15 | **O Topo dos Ecos** | A Verdade | "Tudo o que ecoa, pertence-me." | Enfrenta a verdade |

### N11 — Entrada dos Ecos

- **Objetivo:** chegar às galerias verticais. Tutorial implícito da região.
- **Mecânicas:** sinos básicos (ativar) · plataformas oscilantes · correntes
  móveis · ecos visuais (baixa intensidade)
- **Únicos:** sino de entrada (ativação inicial) · plataformas simples em
  vaivém · primeiras passarelas externas
- **Hazards:** espinhos simples · queda vertical · lâminas de sino (rotativas
  **lentas**)
- **Fluxo:** A entrada e tutorial · B galerias iniciais · C sala do grande
  sino *(elemento chave)*
- **Set pieces:** entrada da torre · primeiro sino · passarelas quebradas
- **Inimigos principais:** Acólito do Eco · Sino Flutuante · Arqueiro das Sombras
- **Paleta:** azul frio, luz divina, primeiros ecos · **Segredos:** 2
- **Rácio:** exploração 70 / combate 30

### N12 — Galerias Verticais

- **Objetivo:** alcançar o nível superior. Foco total na verticalidade.
- **Mecânicas:** plataformas verticais (elevadores) · escadas quebradas ·
  sinos de sincronização · **ecos que revelam plataformas**
- **Únicos:** elevador de coluna (com corrente) · plataformas que desaparecem ·
  vitrais interativos (projetam eco)
- **Hazards:** queda em poços · plataformas falsas · lâminas verticais (**rápidas**)
- **Fluxo:** A base das galerias · B ascensão por plataformas · C secção de
  vento e queda controlada · D chegada às galerias superiores
- **Set pieces:** poço vertical · galerias com vitrais · secção de vento
- **Inimigos principais:** Gárgula Vitral · Autómato do Sino · Monge das Correntes
- **Paleta:** interiores altos, vitrais, luz divina filtrada · **Segredos:** 3
- **Rácio:** exploração 60 / combate 40

### N13 — Mecanismos Antigos

- **Objetivo:** reativar o mecanismo central.
- **Mecânicas:** rodas de engrenagem · sinos com padrão · alavancas múltiplas ·
  plataformas rotativas · pontes reconfiguráveis
- **Únicos:** **mecanismo central (de 3 sinos)** · pontes móveis · engrenagens
  giratórias · contrapesos
- **Hazards:** engrenagens mortais · piso que colapsa · correntes com peso ·
  lâminas em pêndulo
- **Fluxo:** A introdução aos mecanismos · B salas de engrenagens e alavancas ·
  C combinação de sinos e plataformas · D núcleo central *(elemento chave)*
- **Set pieces:** sala das engrenagens · pontes móveis · mecanismo central
- **Inimigos principais:** Autómato do Sino · Construto Vitral · Espírito do Eco
- **Paleta:** metal antigo, ouro envelhecido, máquinas · **Segredos:** 3
- **Rácio:** exploração 55 / combate 45

### N14 — Campanário

- **Objetivo:** alcançar o topo da torre. Campanário totalmente operacional.
- **Mecânicas:** sinos em sequência · plataformas grandes (oscilação) ·
  correntes controláveis · **vento vertical (updraft)** · plataformas temporizadas
- **Únicos:** sinos gigantes (em movimento) · plataformas circulares em rotação ·
  correntes que mudam direção · secções ao ar livre (com vento)
- **Hazards:** sinos em queda · vento que empurra · lâminas em cruz
- **Fluxo:** A chegada ao campanário · B sinos em sequência · C plataformas
  dinâmicas e vento intenso · D sala do sino gigante *(elemento chave)*
- **Set pieces:** sinos gigantes · plataformas circulares · vento intenso
- **Inimigos principais:** Monge das Correntes · Sino Flutuante (variação) · Corvo do Sino
- **Paleta:** céu aberto, vento, sinos monumentais · **Segredos:** 3
- **Rácio:** exploração 50 / combate 50

### N15 — O Topo dos Ecos

- **Objetivo:** derrotar Vyrak, A Voz dos Ecos. Mistura de **todas** as
  mecânicas da região.
- **Mecânicas:** combinação de sinos · plataformas dinâmicas · **ecos de
  memória (plataformas ilusórias)** · vento intenso · elementos destrutíveis
- **Únicos:** plataforma final (múltiplas fases) · sinos celestiais ·
  fragmentos de eco (ativam a arena) · estruturas em colapso
- **Hazards:** feixes de luz · plataformas instáveis · queda com vento · destroços
- **Fluxo:** A ascensão final · B plataformas e últimos desafios · C caminho
  para a arena · D arena — Vyrak
- **Set pieces:** última ascensão · plataformas finais · arena de Vyrak
- **Inimigos:** todos os da região + Vyrak (boss final)
- **Paleta:** céu noturno, energia do eco, clímax · **Segredos:** 4
- **Rácio:** exploração 40 / combate 60

> **Rácios e segredos = LOCKED na tendência**, não no número exato: a
> exploração desce 70→40 e o combate sobe 30→60 ao longo da região. Ver §7.

---

## 3. VYRAK — A VOZ DOS ECOS — LOCKED

> **Vyrak NÃO é um dragão.** A prancha aprovada mostra um guardião humanoide
> encapuzado, coroado, de asas de eco e sino central. Ver §8 (conflitos).

**Lore (LOCKED):** guardião do topo da Torre dos Ecos, um ser que já foi
humano, agora fundido com os sinos e a memória da torre. Acredita que o
passado deve ser preservado, mesmo que isso signifique aprisionar o mundo em
ecos eternos. Testa Koliani para ver se ela é digna de quebrar o ciclo.

**Falas:** *"Tudo o que foi dito, ainda ecoa. E tudo o que ecoa,
pertence-me."* · Fase 2: *"O eco nunca morre!"* · Derrota: *"Os ecos
libertam-se... E o futuro finalmente pode falar."*

- **Escala:** ≈ **4× Koliani** (a prancha mostra a silhueta comparada)
- **Materiais:** metal envelhecido · pedra gótica · ouro antigo · energia de
  eco · vitrais
- **Anatomia:** cabeça/coroa (halo anelar) · **sino central ao peito** · asas
  de eco (lâminas de luz) · armadura · símbolos anelares flutuantes
- **Sprites:** Idle · Andar · Preparação · Ataque · Hurt · Death

### Ataques — Fase 1 (100 %→50 %)

| # | Nome | Telegrafo | Descrição | Evitar | Dano |
|---|---|---|---|---|---|
| 1 | Golpe de Sino | levanta o sino | golpe lateral em arco | saltar ou afastar | médio |
| 2 | Onda de Eco | círculo no chão | onda de choque | saltar | médio |
| 3 | Sino em Queda | brilho no teto | sinos caem em linha | mover-se | médio/alto |
| 4 | Lanças de Luz | brilho nas asas | projéteis em leque | desviar entre as lanças | médio |
| 5 | Investida Aérea | eleva-se no ar | investida em linha | correr ou saltar no último momento | alto |

### Ataques — Fase 2 (50 %→0 %)

| # | Nome | Telegrafo | Descrição | Evitar | Dano |
|---|---|---|---|---|---|
| 6 | Chuva de Sinos | círculos múltiplos | vários sinos caem | mover-se constantemente | médio |
| 7 | Espiral de Ecos | anéis expandem | espiral de projéteis | mover-se em ziguezague | médio |
| 8 | Parede de Eco | mãos ao centro | cria barreiras móveis | encontrar aberturas | contacto |
| 9 | Julgamento Final | círculo grande | feixe vertical massivo | — | muito alto |

### Ciclo e arena — LOCKED

`Fase 1 (100–50 %)` ataques básicos + sinos e projéteis → `Transição`
cutscene curta + mudança da arena (*Ritual de Ativação*) → `Fase 2 (50–0 %)`
ataques avançados + arena dinâmica → `Derrota` colapso da torre + cena final.

- **Arena F1:** plataforma principal **contínua**, elementos destrutíveis,
  sinos ao fundo, plataformas laterais, sinos ativos.
- **Arena F2:** expande-se, surgem novos sinos e plataformas, fragmentos
  flutuam.

### Princípios de design do boss — LOCKED

- Boss **sempre atingível**
- Telegraphing claro (**visual e sonoro**)
- Arena funcional antes de ser espetacular
- Ataques com janelas de reação justas
- Combinação de ataques, mas **sem "spam" injusto**
- Fase 2 aumenta complexidade **sem perder legibilidade**

**Recompensas:** Memória de Vyrak (item de história) · Cristal de Eco
(melhoria) · Insígnia da Torre (colecionável).

**FX:** rasto de golpe · onda de eco · impacto de luz · explosão de luz ·
partículas de eco · aura da fase 2.

---

## 4. INIMIGOS — LOCKED (roster) / FLEX (números)

Dez arquétipos. **Nenhum existe hoje no jogo** (ver `AUDIT` na Fase 2).

| Inimigo | Papel | Comportamento | Ataques |
|---|---|---|---|
| **Sentinela da Torre** | guerreiro ancestral, ritmo base | patrulha plataformas · melee com lança · bloqueia por instantes · boa leitura visual | Lança · Investida curta · Bloqueio |
| **Acólito do Eco** | cultista / suporte | invoca ecos · ataques à distância (orbes sonoros) · vulnerável após ataque | Orbe sonoro · Salva de orbes · Invocação |
| **Autómato do Sino** | construção antiga, tanque | lento mas resistente · martelo/sino · gera ondas de eco · **fraco nas costas** | Martelo · Onda de eco · Slam em área |
| **Gárgula Vitral** | predadora aérea | patrulha em voo · ataque em mergulho · cospe fragmentos · força a olhar para cima | Mergulho · Fragmentos · Voo em grupo |
| **Sino Flutuante** | eco menor | rotas fixas · ondas de choque · chama outros sinos · **destruir silencia a área** | Onda de choque · Pulso triplo · Chamada |
| **Arqueiro das Sombras** | atirador | mantém distância · flechas de luz/eco · dispara em arco · posições elevadas | Flecha direta · Flecha em arco · Salva |
| **Monge das Correntes** | controlador | correntes e pesos · **puxa o jogador** · zonas de negação · vulnerável após combo | Chicote · Puxão · Zona de correntes |
| **Espírito do Eco** | perseguidor etéreo | atravessa plataformas (parcialmente) · persegue · **explode ao contacto** · surge de sinos/memoriais | Investida · Explosão · Aparece/Desaparece |
| **Construto Vitral** | golem frágil-pesado | vidro resistente · ataques pesados e lentos · liberta estilhaços ao morrer · **fraco a ataques aéreos** | Soco · Estilhaços · Queda |
| **Corvo do Sino** | assediador | voo rápido e imprevisível · ataca em grupo · **dá alarme a outros** · pouca vida, difícil de acertar | Mergulho · Rasgo · Alarme (som) |

### Distribuição — LOCKED

Fonte primária: `layout_usage.png` ("INIMIGOS PRINCIPAIS" por nível), que é
legível sem ambiguidade:

| Nível | Principais |
|---|---|
| N11 | Acólito do Eco · Sino Flutuante · Arqueiro das Sombras |
| N12 | Gárgula Vitral · Autómato do Sino · Monge das Correntes |
| N13 | Autómato do Sino · Construto Vitral · Espírito do Eco |
| N14 | Monge das Correntes · Sino Flutuante (variação) · Corvo do Sino |
| N15 | todos os da região + Vyrak |

> **Armadilha de método:** a tabela "PROGRESSÃO DE APARIÇÃO" do
> `enemy_gameplay_pack.png` tem os pontos **desalinhados** em relação às
> linhas de texto (a arte foi composta com meia-linha de desvio). Tentar ler
> o ponto exato por linha dá resultados contraditórios — por ex. a Sentinela
> apareceria em 11, 12, 13 **e** 15 mas não em 14. **Não usar essa tabela
> como fonte de distribuição exata.** Serve só para confirmar a *tendência*:
> poucos arquétipos leves em N11, mais e mais pesados até N15.
> A Sentinela da Torre é o "ritmo base" da região: entra como patrulheiro
> comum em N11–N12 mesmo não estando na lista de "principais".

**Regras:** não herdar inimigos de biomas anteriores sem razão · nada de
recolor de demónios de prisão · não pôr todos os inimigos em todos os níveis.

---

## 5. ASSETS E ARQUITETURA — LOCKED (vocabulário) / FLEX (execução)

**Tiles base:** chão normal · chão gasto · chão com runas/fendas · blocos ·
plataforma sólida · plataforma ornamentada · plataforma em ruínas ·
plataforma suspensa · plataforma móvel · rampas/inclinações

**Paredes e estruturas:** parede normal · parede gasta · **parede com vitral** ·
arco pequeno · arco grande · coluna · coluna dupla · torre lateral · parede
destruída

**Escadas:** escada normal · escada quebrada · escada vertical · estrutura
vertical · passarela · suportes

**Plataformas especiais:** oscilante · com corrente · desaparece · rotativa ·
elevador · **com vento (updraft)**

**Props:** estátua angélica · estátua partida · gárgula · pilar decorativo ·
candelabro · tocha de parede · lanterna · braseiro · **sino pequeno / médio /
grande / partido** · relógio antigo · bandeiras · livros/pilhas · mobiliário ·
teias · vasos/urnas · caixas · heras · plantas secas · detritos/pedras ·
poeira no chão

**Hazards:** espinhos de pedra/vitral · lâminas pendulares · lâminas
rotativas · piso quebra · laser de luz · chamas azuis · orbe de eco (dano) ·
vento vertical · queda de pedras · sinos em queda · correntes móveis ·
plataforma inclinada · estilhaços

**Interativos:** alavanca · interruptor (pressão) · **pedra de memória** ·
mecanismo de sino · porta com chave · elevadora · elevador · roda de
engrenagem · **corrente quebrável** · espelho de luz (reflexão) · orbe de eco
(colecionável) · vitral quebrável

**FX:** faíscas douradas · partículas de luz · poeira no ar · brilho de sino ·
**onda de eco** · folhas ao vento · raios de luz (volumétrico) · neblina azul ·
estilhaços · **aura espectral**

### Parallax — LOCKED (5 camadas nomeadas)

| Camada | Conteúdo |
|---|---|
| 1 | Silhueta próxima |
| 2 | Torres distantes |
| 3 | Catedral da cidade |
| 4 | Montanhas e nuvens |
| 5 | **Lua e céu** |

> Hoje os cinco níveis usam `fundo_pack = "montanhas"`. Isso só cobre a
> camada 4. Falta o pack próprio da torre.

**Narrativos/colecionáveis:** inscrições antigas · página de diário ·
fragmento de memória · símbolo do eco · altar · bandeira da torre · memorial.

---

## 6. PARÂMETROS TÉCNICOS — LOCKED

| Parâmetro | Valor |
|---|---|
| Resolução base | 1920×1080 (16:9) |
| Pixel scale | 1× (pixel perfect) |
| FPS alvo | 60 |
| Tilemap | 16×16 / 32×32 conforme asset |
| Camadas | Background / Midground / Foreground |
| Física | Plataforma 2D (modelo atual) |
| Checkpoints | automáticos + manuais |
| Save | integrado (região/nível) |

**Métricas-alvo:** FPS ≥ 60 · carregamento < 3 s · memória < 500 MB ·
bugs críticos 0 · **softlocks 0** · dificuldade progressiva e justa ·
taxa de conclusão (teste) > 85 %.

---

## 7. INTERPRETATION FLEX — o que NÃO está fixado

Tudo o que segue é decisão de implementação, documentada aqui para não ser
confundida com cânone:

1. **Duração por nível.** As pranchas pedem 20–45 min por nível (e 40–60 no
   N15). O Koliani é um platformer **mobile por níveis**, com níveis de
   1–3 minutos; as regiões I e II seguem essa escala. Adotar 20–45 min
   partiria a consistência do jogo inteiro e o modelo de save. **Decisão
   conservadora: manter a escala do jogo; respeitar os rácios
   exploração/combate e a ordem de segredos como *proporção*, não como
   minutos.** A tendência (exploração desce, combate sobe) é que é LOCKED.
2. **Número literal de segredos (2/3/3/3/4).** Mantém-se a *ordem crescente*;
   o número exato depende do espaço real de cada cena.
3. **Estrutura de pastas** `res://levels/region3/n11_entrada_ecos/...` da
   prancha. O projeto usa `scenes/levels/<Nome>.tscn` plano e
   `EstadoJogo.NIVEIS` por índice. **Não migrar**: renomear ficheiros de cena
   parte saves e checkpoints (precedente já documentado na Região II). Os
   nomes canónicos entram pelas chaves i18n, não pelo nome do ficheiro.
4. **Tilemap 16×16/32×32.** O jogo desenha plataformas por `Plataforma.tscn`
   (retângulos com `tamanho`/`cor_base`/`cor_topo`), não por TileMap. Manter
   o sistema atual e alcançar a fidelidade por material/props/atmosfera.
5. **Lista exata de ataques por fase do Vyrak.** Os 9 ataques são LOCKED como
   vocabulário; quais entram no protótipo primeiro é FLEX (ver Fase 6).
6. **"Elemento chave" por nível.** As pranchas marcam-no no mini-mapa mas não
   definem a sua regra. Interpretação mínima suportada: um objeto que abre a
   progressão do nível (sino/alavanca/núcleo), coerente com o "Objetivo".

### Não inventar

Onde as referências não suportam uma mecânica regional grande, **não se
inventa**. Em particular: não há nas pranchas nenhuma mecânica de "eco" com
regras próprias (tipo sonar que mapeia o nível). O que há é
**"ecos que revelam plataformas"** (N12) e **"ecos de memória — plataformas
ilusórias"** (N15). É essa — e só essa — a leitura suportada.

---

## 8. CONFLITOS ENTRE CÂNONE E IMPLEMENTAÇÃO ATUAL

Registados aqui porque mudam o que é "fidelidade":

| # | Cânone (prancha) | Jogo hoje | Veredicto |
|---|---|---|---|
| 1 | Vyrak = **A Voz dos Ecos**, guardião humanoide, 4× Koliani, sinos/ouro/eco, **2 fases** | `chefe_vyrak.gd` = "**o Dragão das Sombras**", besta alada, roxo-sombra, **3 fases** | **FIDELITY FAILED** — identidade errada. Rework. |
| 2 | Região III tem **um** confronto: Vyrak | N11–N14 têm 4 *bosses* (Sino Vivo, Aerion, Voltaris, Sacerdotisa Lunar) | Seguir o precedente da Região II: passam a **GUARDIÕES** (`guard.*`), Vyrak fica o único `boss.*` |
| 3 | Nomes: Entrada dos Ecos / Galerias Verticais / Mecanismos Antigos / Campanário / O Topo dos Ecos | Torre dos Sinos / Torre dos Ventos / Torre da Tempestade / Observatório Lunar / O Pico Esquecido | Renomear **por i18n**, nunca por ficheiro |
| 4 | Sinos = elemento central da região | Só N11 tem `SinoTorre`; N12 vento, N13 tempestade/raios, N14 gravidade | Sinos têm de atravessar os 5 níveis |
| 5 | Hazards de torre (espinhos de vitral, lâminas, engrenagens) | Os 5 níveis usam `AguaVenenosa` como "Vazio" | Funciona, mas o nome/arte é de pântano — merece um ator próprio |
| 6 | 10 inimigos próprios | Só `DemonioBase` com `especie`/`comportamento` genéricos | **REPLACE** — nenhum inimigo canónico existe |
| 7 | 5 camadas de parallax próprias da torre | `fundo_pack = "montanhas"` nos 5 | Falta pack `torre_ecos` |

### O "Sino Vivo"

Não é uma mecânica — é o **chefe do N11** (`ChefeSinoVivo.tscn`,
`boss.sino_vivo`, "The Living Bell"). Um chefe-sino numa torre de sinos é
**coerente com o cânone** e deve ser **preservado**, reclassificado como
guardião (`guard.sino_vivo`) por a região só poder ter um boss (§8.2).

### Armadilha de índices (custou a descobrir)

As chaves i18n `level.nXX` usam o **índice 0-based** de `EstadoJogo.NIVEIS`,
não o número do nível que o jogador vê. Os níveis N11–N15 são:

| Jogador | Índice | Chave i18n | Cena |
|---|---|---|---|
| N11 | 10 | `level.n10` | `Torre_dos_Sinos.tscn` |
| N12 | 11 | `level.n11` | `Torre_dos_Ventos.tscn` |
| N13 | 12 | `level.n12` | `Torre_da_Tempestade.tscn` |
| N14 | 13 | `level.n13` | `Observatorio_Lunar.tscn` |
| N15 | 14 | `level.n14` | `O_Pico_Esquecido.tscn` |

Mexer em `level.n11` a pensar no N11 estraga o **N12**.

---

## 9. CRITÉRIO DE FIDELIDADE

Para cada nível e para o Vyrak, classificar A–N (silhueta, paleta, materiais,
arquitetura, props, foreground, midground, background, iluminação, atmosfera,
FX, profundidade, densidade visual, identidade regional).

- **HIGH** — a forma e o material lêem-se como a prancha, não só a cor.
- **MEDIUM** — identidade certa, detalhe abaixo da referência.
- **LOW** — lê-se como outro bioma ou como genérico. **Não fechar com LOW.**
- **FAILED** — contradiz o cânone (ex.: Vyrak dragão).

Não declarar HIGH porque "a cor parece semelhante".
