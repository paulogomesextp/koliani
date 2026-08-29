# Koliani — plano de 30 níveis + bosses

> Bíblia de design do Paulo (2026‑08‑29). É o **alvo** da campanha, não o
> estado atual. Hoje jogam‑se 4 níveis (`EstadoJogo.NIVEIS`): Floresta
> Putrefata, Prisão dos Condenados, Torres Esquecidas, Castelo de Zeriko —
> que correspondem, grosso modo, às regiões I, II, III e VI.
>
> Cada nível novo precisa de: cena `scenes/levels/*.tscn`, entrada em
> `EstadoJogo.NIVEIS`, pistas no `DiarioPistas` + i18n, e (quando tiver
> chefe próprio) script de chefe + sprite. Ordem de ataque sugerida no fim.
>
> **Feito até agora (2026‑08‑29):**
> - `EstadoJogo.REGIOES` — camada de dados das 6 regiões + `concluidos`
>   (estado de conclusão por nível, gravado no save). Falta a UI (mapa).
> - Região I / nível 01: chefe **Ghorak** (`chefe_ghorak.gd` +
>   `ChefeGhorak.tscn` + `assets/sprites/chefe_ghorak.svg`), a substituir o
>   placeholder `ChefeFloresta` na `Floresta_Putrefata.tscn`.
> - Mecânica partilhada **`RaizPerigo`** (`scenes/actors/RaizPerigo.tscn`):
>   espinho de raiz que telegrafa, irrompe e recolhe — base das raízes da
>   região I; reutilizável como perigo/plataforma temporária.

---

## I — Floresta Putrefacta
Natureza corrompida: raízes, fungos, névoa, criaturas deformadas.

### 01 — O Caminho das Raízes Mortas
- **Mecânica:** raízes que crescem e desaparecem, criando plataformas
  temporárias. Árvores gigantes; raízes tentam agarrar a Koliani; criaturas
  infectadas saltam dos troncos.
- **Boss — Ghorak, o Guardião Raiz:** guerreiro de tronco, ossos e raízes.
  Esmaga o chão; faz raízes surgirem sob os pés da Koliani. Fase 2: o
  cenário é tomado por raízes. **Fraqueza:** núcleo púrpura no peito.

### 02 — Pântano dos Sussurros
- **Mecânica:** plataformas flutuantes + água venenosa (morte instantânea).
  Saltar entre troncos, pedras e cogumelos gigantes.
- **Boss — Morvanna, a Bruxa do Pântano:** flutua sobre a água, invoca mãos
  espectrais, cria clones de lama, apaga temporariamente plataformas.

### 03 — Ninho da Viúva Negra
- **Mecânica:** teias como plataformas e paredes escaláveis; floresta vira
  teia vertical.
- **Boss — A Rainha Aracnídea:** aranha colossal com rosto humano. Cospe
  teias que prendem; solta ovos que geram aranhas pequenas. Fase 2:
  destrói partes do cenário.

### 04 — A Árvore que Chora
- **Mecânica:** plataformas dentro e fora de uma árvore gigante; labirinto
  vertical no tronco.
- **Boss — Entrevane, a Árvore Amaldiçoada:** vários rostos; galhos atacam
  de várias direções; lágrimas ácidas. Subir pelo corpo enquanto se luta.

### 05 — Coração da Floresta
- **Mecânica:** cenário muda a cada "batimento" do coração da floresta
  (plataformas, inimigos, perigos).
- **Boss — O Coração Putrefacto:** raízes, cadáveres e um coração púrpura.
  F1 raízes + projéteis · F2 o coração bate e altera a gravidade · F3 a
  arena desmorona.

---

## II — Prisão dos Condenados
Fortaleza subterrânea dos que resistiram a Zeriko.

### 06 — Portão dos Condenados
- **Mecânica:** correntes como plataformas móveis.
- **Boss — O Carcereiro Sem Rosto:** gigante com uma chave no lugar da
  cabeça. Correntes como chicotes; prende plataformas; abre celas para
  soltar monstros.

### 07 — Fornalha dos Pecadores
- **Mecânica:** lava + plataformas móveis; fábrica infernal.
- **Boss — Ignivar, o Ferreiro Maldito:** forja armas mágicas durante a
  luta; martelo cria ondas de choque. Fase 2: derrete a arena.

### 08 — Corredor das Execuções
- **Mecânica:** guilhotinas, lâminas, plataformas que desaparecem.
- **Boss — A Dama da Guilhotina:** executora fantasma. Teleporta‑se; lança
  lâminas; faz várias guilhotinas caírem ao mesmo tempo. Fase 2: arena
  quase toda vertical.

### 09 — Ala dos Mortos
- **Mecânica:** plataformas espectrais que só aparecem quando a Koliani usa
  magia.
- **Boss — Os Irmãos Condenados:** dois fantasmas ligados por corrente (um
  de perto, outro à distância). Quando um morre, o outro absorve‑lhe a
  alma e ganha ataques novos.

### 10 — A Cela Zero
- **Mecânica:** labirinto vertical.
- **Boss — O Primeiro Prisioneiro:** herói antigo que tentou derrotar
  Zeriko. Espada parecida com a da Koliani; imita ataques dela; bloqueia.
  Fase 2: vira criatura de energia púrpura. **Diálogos importantes para a
  história.**

---

## III — Torres Esquecidas
Região vertical: subir as torres até ao observatório.

### 11 — Torre dos Sinos
- **Mecânica:** sinos alteram o cenário — plataformas mudam, inimigos
  congelam, portas abrem.
- **Boss — O Sino Vivo:** criatura presa dentro do sino; ataques por ondas
  sonoras.

### 12 — Torre dos Ventos
- **Mecânica:** correntes de ar para alcançar plataformas distantes.
- **Boss — Aerion, o Cavaleiro Alado:** voa sempre; cria tornados; atira
  lanças. Plataformas suspensas.

### 13 — Torre da Tempestade
- **Mecânica:** raios atingem plataformas em padrões previsíveis.
- **Boss — Voltaris (mago morto‑vivo):** teleporta‑se entre torres; invoca
  raios; clones elétricos. A Koliani pode usar pára‑raios metálicos para
  redirecionar os raios contra ele.

### 14 — Observatório Lunar
- **Mecânica:** gravidade variável — andar por paredes e teto.
- **Boss — A Sacerdotisa Lunar:** manipula a lua; cria luas falsas; altera
  a gravidade; invoca meteoros púrpura.

### 15 — O Pico Esquecido
- **Boss — Vyrak, o Dragão das Sombras:** F1 na torre · F2 destrói a torre
  e voa · F3 a Koliani luta em cima do dragão.

---

## IV — Catacumbas do Abismo
O poder de Zeriko vem de algo enterrado antes do seu reinado.

### 16 — Cemitério dos Reis
- **Mecânica:** túmulos como elevadores.
- **Boss — Rei Ossário:** rei morto‑vivo num cavalo esquelético.

### 17 — Galeria dos Ossos
- **Mecânica:** corredores de osso; certas paredes destruíveis.
- **Boss — O Colosso Ósseo:** gigante de centenas de esqueletos; ao perder
  partes, usa os ossos para criar armas novas.

### 18 — Cripta das Mil Velas
- **Mecânica:** luz e escuridão — plataformas só existem quando iluminadas.
- **Boss — A Freira Negra:** apaga as velas; manter certas chamas acesas
  durante a luta.

### 19 — Templo da Serpente
- **Mecânica:** paredes móveis e passagens secretas.
- **Boss — Naga Zeraph:** invoca cobras; veneno; troca de posição com
  estátuas; transforma partes da arena em veneno.

### 20 — O Abismo
- **Mecânica:** quase sem luz.
- **Boss — O Olho do Abismo:** olho flutuante sem corpo. Lasers;
  plataformas falsas; clones; inverte os comandos por alguns segundos.

---

## V — Cidade Corrompida
A civilização dominada pela magia de Zeriko.

### 21 — Vila dos Sem‑Rosto
- **Mecânica:** alguns NPCs são inimigos disfarçados.
- **Boss — O Prefeito Sem‑Rosto:** assume a aparência de outros
  personagens.

### 22 — Mercado da Carne
- **Mecânica:** plataformas de correntes, caixas e carrinhos.
- **Boss — O Açougueiro Real:** gigante com dois cutelos; cada golpe muda a
  arquitetura da arena.

### 23 — Trem dos Mortos
- **Mecânica:** correr sobre um comboio em movimento — túneis, pontes,
  morcegos, inimigos a saltar entre vagões.
- **Boss — O Maquinista Infernal:** luta em cima do comboio. Fase 2: o
  próprio comboio ataca.

### 24 — Catedral da Corrupção
- **Mecânica:** vitrais destruíveis mudam a iluminação.
- **Boss — O Bispo Púrpura:** magia púrpura; cruzes explosivas; mãos
  espectrais; invoca anjos corrompidos.

### 25 — Praça do Eclipse
- **Mecânica:** cenário alterna entre "realidade" e "corrupção".
- **Boss — A Noiva do Eclipse:** rainha antiga sacrificada por Zeriko —
  boss emocional, ligado à história.

---

## VI — Castelo de Zeriko
Região final; cada nível é uma parte do castelo.

### 26 — Portões de Zeriko
- Cavaleiros corrompidos.
- **Boss — O Capitão Negro:** espada e escudo enormes. **Twist:** luta como
  personagem jogável, ataques muito mais rápidos que os bosses anteriores.

### 27 — Salão dos Espelhos
- **Mecânica:** espelhos criam versões alternativas do cenário; versões
  sombrias da Koliani.
- **Boss — Koliani Sombria:** mesmos movimentos, versões alternativas das
  habilidades, ataques púrpura. Testa tudo o que o jogador aprendeu.

### 28 — Banquete dos Imortais
- **Mecânica:** a arena inteira é uma mesa de jantar gigante.
- **Boss — O Rei Devorador:** come inimigos derrotados para recuperar vida.

### 29 — Torre do Coração Negro
- **Mecânica:** plataformas mágicas aparecem/desaparecem com pulsos de
  energia.
- **Boss — O Arauto de Zeriko:** braço direito de Zeriko, 3 formas —
  Cavaleiro → Demónio → Entidade de pura magia. Ao cair, revela que Zeriko
  nunca esteve sozinho.

### 30 — O TRONO DE ZERIKO
- **Mecânica:** a realidade desmorona; o cenário mistura elementos dos 29
  níveis (raízes, correntes, torres, ossos, cidade, magia púrpura).
- **Boss Final — ZERIKO:** **4 fases** (não só um mago gigante).

---

## Ordem de trabalho sugerida (agente)

1. ~~Refatorar `EstadoJogo.NIVEIS` para suportar regiões + N níveis + estado
   de conclusão~~ **feito** (`REGIOES` + `concluidos`). Falta o menu/mapa
   passar a listar regiões (só UI; a camada de dados já existe).
2. Definir e implementar as **mecânicas partilhadas** reutilizáveis:
   plataforma temporária (raízes/teias/espectral — **`RaizPerigo` feito**
   para a variante raiz), plataforma móvel (correntes), água/lava mortal,
   vento, gravidade variável, luz↔escuridão, cenário rítmico ("batimento").
   Cada uma como cena/nó reutilizável.
3. Construir os níveis por região, começando pela I (biomas e atmosfera já
   existem). 1 chefe novo por nível — herdar de `ChefeBase`. **Feito:**
   Ghorak (nível 01). **A seguir:** Morvanna, Rainha Aracnídea, Entrevane,
   Coração Putrefacto — e as cenas de nível 02‑05 propriamente ditas.
4. Arte: sprites SVG (rim‑lit) no estilo atual; pixel‑art fica como opção
   futura (swap). Núcleos/fraquezas a magenta.
5. Afinar com playtest (Paulo + amigo) a cada região fechada.
