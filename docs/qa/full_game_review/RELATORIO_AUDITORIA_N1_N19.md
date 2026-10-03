# KOLIANI — AUDITORIA EXTERNA N1–N19

**Data:** 3 out 2026 · **Build auditada:** `origin/master` 812baf72, `config/version` **0.18.21** (worktree limpa `C:\Projetos\koliani-audit`; a cópia local do Paulo, branch `claude/9h13b-sfx-redesign`, está atrás e suja e **não foi tocada**).
**Âmbito:** N1–N19. **O N20 foi excluído a pedido do Paulo** (está a ser construído noutra conversa). O último boss avaliado é o do N15 (Vyrak).
**Postura:** o produto não foi alterado. Tudo o que foi criado está em `docs/qa/full_game_review/` (capturas, ferramentas de QA, dados do bot).

---

## 0. MÉTODO E LIMITES (ler antes das notas)

| Fonte | O que mediu | Limite |
|---|---|---|
| Leitura de código e cenas (`scripts/`, `scenes/levels/`, i18n, catálogo) | estrutura, números, contagens, bugs estáticos | não sente o toque |
| Leitura de `docs/art_direction/` + pranchas PNG das Regiões II–IV | contrato visual | a Região I não tem prancha (`VISUAL_REFERENCE = MISSING`) |
| **95 capturas reais** (5 por nível: início, 1/3, 2/3, guardião, porta) + UI, HUD, toque, skins | arte real vs prancha, legibilidade | renderer real em janela, mas a Koliani é teleportada (não é gameplay contínuo) |
| **Bot de playtest** (`tools/bot_humano_r2.gd`, copiado para `docs/qa/.../tools/bot_auditoria.gd` com as habilidades que um jogador de campanha teria), 3 perfis × 19 níveis, `--fixed-fps 60`, 6 min por corrida | mortes por posição, tempo até à porta, guardiões | **o bot é um router horizontal afinado para a Região II**: não sabe usar o dash sob teto, combate mal e não resolve níveis verticais (N10–N15). Os números dele são **sinal de stress, não verdade de dificuldade**. Onde a conclusão depende dele, isso é dito. |
| ffmpeg (duração/loudness da música) | mix, ciclos | não substitui ouvir; a qualidade musical "subjetiva" **não foi avaliada de ouvido** |

**Achado metodológico, já útil para a equipa:** a 1.ª bateria do bot arrancava **sem habilidades** (save novo isolado) e produziu centenas de mortes falsas em portões de dash/salto duplo. O bot oficial do repo tem o mesmo defeito: qualquer métrica de dificuldade tirada dele em N3+ sem entregar habilidades é inválida. Dados v1 guardados à parte em `bot_v1_sem_habilidades/`.

**O que NÃO foi possível medir com rigor:** sensação de toque real num telemóvel, qualidade musical de ouvido, FPS num telemóvel real. Ver §29.

---

## 1. EXECUTIVE SUMMARY

O Koliani tem **duas coisas genuinamente fortes**: a **atmosfera/arte de fundo** (o menu e a Região I, em captura parada, têm nível de produto comercial) e a **disciplina de engenharia** (física de movimento medida, testes, ferramentas de geração, contratos por região, saves isolados nos testes).

Como **jogo**, ainda não está bom. O problema central não é a falta de conteúdo: é que **o conteúdo que existe não forma uma experiência coesa**:

1. **Parece quatro jogos colados.** A Região I é arte pintada HD; a II é pixel-art fina; a III é pixel-art ampliada (píxeis gigantes no fundo do N15); a IV é pixel-art saturada noutra densidade. O Vyrak (clímax da III) é um boneco de formas lisas gerado por código ao lado de chefes desenhados. O N11 tem **polígonos de cor sólida** (sinos amarelos, plataformas lilás) no jogo.
2. **O combate é raso e pouco presente.** 1 a 8 inimigos comuns por nível de 4 500–7 800 px (N1 e N2 têm **um** inimigo comum cada). A Região I tem 2 espécies em 5 níveis. Há ~30 espécies sobre apenas 7 comportamentos. O hitstop é 10–24 ms, invisível a 60 Hz. Na Região IV o bot chega à porta em 25–54 s **sem precisar de lutar**.
3. **Cada nível é igual a si próprio de ponta a ponta.** Na Região I os 5 níveis partilham o mesmo fundo, a mesma laje de terreno e a mesma estrutura: plano → portão de dash sob teto com poço → raízes → guardião → porta. Os 19 níveis acabam **todos** num guardião/boss.
4. **A história existe, mas o jogador não a vê.** Há lore boa escrita (Aurora, Zeriko, o Olho) nas chaves `clue.*` de um sistema retirado. Não há prólogo; "New Game" leva ao mapa. Só o boss do N10 fala.
5. **A UI tem o melhor e o pior.** O menu principal e o HUD novo parecem comerciais. A loja tem a skin principal **duplicada**, células vazias e texto de ~8 px; o seletor mostra "ATUAL" em português num jogo em inglês; a Região IV chama-se **"Catacombs of the Abyss"** no jogo (o cânone diz Fornalha).

**Veredito curto:** produção avançada de *assets* e sistemas; **alpha** como *jogo*. O caminho para "bom" passa por **cortar e unificar**, não por acrescentar mais 81 níveis.

---

## 2. VEREDITO TÉCNICO — MATURIDADE

**ALPHA** (não "alpha avançada").

Justificação:
- Sistemas existem e funcionam: movimento, combate com combo, pogo, dash, especial, vento, sinos, pistões, válvulas, lava, save, loja, skins, HUD, i18n em 6 línguas, builds Windows/Web/Android.
- **Mas** há arte provisória visível num nível jogável (N11), um boss regional com arte provisória (Vyrak), um catálogo de loja com erro de dados visível, nomes de regiões errados na UI, uma suite de testes que a equipa tolera com 9 falhas "pré-existentes", **nenhum nível LOCKED** (todos "PRONTO PARA PLAYTEST — NÃO LOCKED") e nenhum loop de jogo validado por jogadores externos.
- Uma *vertical slice* exige uma fatia com qualidade final. Hoje a fatia mais próxima é a Região I, mas falha no combate (densidade) e na variedade visual entre níveis.

---

## 3. PRIMEIROS 30 MINUTOS

| Momento | Avaliação |
|---|---|
| Arranque → menu | **Forte.** Key art, logótipo e música de menu dão um primeiro impacto comercial. Problema: "DEVELOPER MODE" visível no canto do menu em `master`/playtest. |
| New Game | **Fraco.** Nenhum prólogo, nenhum contexto. O jogador não sabe quem é a Koliani, quem é a Aurora nem porque avança. |
| N1 (0–3 min) | Atmosfera excelente na 1.ª captura. Mas ~25 % inferior do ecrã é uma faixa roxa lisa (o pântano mortal), sem detalhe; a Koliani mede ~70 px a 720p (pequena em telemóvel). |
| N1 combate | **Um** inimigo comum (goblin) em 6 290 px, depois o Ghorak. O Ghorak (915 HP em jogo) é o **guardião mais resistente da Região I**, mais do que os de N2 (458–537), N3 (675) e N4 (532–829). O nível de ensino tem a luta mais longa da região. |
| N2–N3 | Ensina dash (bem pensado: portão sob teto com poço de retry) e pogo. Mesmo fundo, mesmo terreno, mesma estrutura. **Ao minuto ~15 o jogador já viu tudo o que a Região I tem para mostrar visualmente.** |
| Sensação geral | Bonito em fotografia, vazio em jogo. Muito tempo a correr em chão plano entre ideias. |

---

## 4. MOVIMENTO

Números reais (`scripts/movimento.gd`, `scripts/koliani.gd`):

| Parâmetro | Valor | Leitura |
|---|---|---|
| Corrida | 240 px/s, aceleração 2 300 (≈0,10 s até ao máximo), viragem 3 600 | responsivo, bom |
| Salto | `FORCA_SALTO` 584, gravidade 1 400 → **~122 px** de altura, subida ~0,42 s | correto |
| Queda | multiplicador **1,22×**, apex a 0,5× gravidade | **pouca diferença subida/queda → ligeiramente "floaty"**. Referências do género ficam tipicamente entre 1,5× e 2× |
| Coyote / buffer | 0,10 s / 0,12 s | bons, adequados a toque |
| Corte de salto | mantém 45 % | bom |
| Dash | 620 px/s × 0,16 s, invulnerável, recarga 0,55 s, saída travada em ~2 ticks | sólido e medido (o N2 usa o envelope medido para desenhar portões: excelente prática) |
| Rolar | 320 px/s × 0,30 s | ok |
| Pogo | intencional (Baixo+Ataque), startup 0,07 s, ativo 0,20 s, punição 0,30 s ao falhar | **bom desenho**: tem custo, não se faz spam |

**Veredito:** o movimento é a **base mais sólida do jogo**. Não recomendo reestruturar a física. Afinações pontuais: aumentar a gravidade de queda para ~1,5× e testar.
**Ressalva honesta:** a sensação em toque real não foi testada por mim. A dificuldade do pogo (joystick para baixo + ataque, no ar, com o polegar esquerdo num joystick flutuante) é o maior risco de execução em telemóvel.

---

## 5. COMBATE

| Aspeto | Facto | Avaliação |
|---|---|---|
| Combo | 4 golpes, 0,94 s no total, multiplicadores 0,85/1,0/1,25/1,9, recuo crescente | bem estruturado no papel |
| Dano base | 50 → ~266 de dano/s teórico com o combo completo | ok |
| **Hitstop** | **10 ms** golpe / 18 ms remate / 24 ms crítico | **Abaixo do necessário.** A 60 Hz, 10 ms é menos de um frame; o impacto não se sente. O próprio código comenta que um hitstop maior causava "drop". O problema foi contornado em vez de resolvido |
| Densidade | N1: 1 · N2: 1 · N3: 3 · N4: 8 · N5: 3 · N6: 3 · N7: 4 · N8: 3 · N9: 6 · N10: 1 · N11: 4 · N12: 6 · N13: 6 · N14: 8 · N15: 14 · N16–N19: 5–7 | **vazio**. Em 6 000 px, 1–3 inimigos = combate esporádico |
| Variedade | 7 comportamentos (`patrulha`, `saltador`, `carga`, `voador`, `escudeiro`, `trepador`, `cuspidor`) para ~30 espécies | a maioria das espécies é **"o mesmo inimigo com outra aparência"** |
| Corpo | "Koliani atravessa inimigos" (Combat Lab v1) | atravessar em vez de enfrentar |
| Região IV | bot chega à porta em **25–54 s** com 0–5 mortes nos 3 perfis (N16, N17, N19) | **combate opcional**: os elites não selam a porta |

**Pergunta essencial: "estou a lutar contra inimigos ou a atravessá-los?"** — Hoje, **a atravessá-los**. Combate a sério só acontece nos guardiões.

**Nota: 4/10.**

---

## 6. INIMIGOS

| Região | Espécies em jogo | Leitura |
|---|---|---|
| I | **goblin, gosma** (2) | insuficiente para 5 níveis; o próprio doc do N2 admite "goblin legado" |
| II | golem aéreo, morcego dos ventos, sentinela flutuante, elemental do vento, gosma (repetida) | melhor; animações refeitas a 1 out (relatório próprio) |
| III | acólito do eco, arqueiro das sombras, sentinela da torre, sino flutuante, autómato do sino, gárgula vitral, monge das correntes, construto vitral, espírito do eco, corvo do sino | **a mais rica**, mas 10 espécies em 7 comportamentos |
| IV | trabalhador corrompido, arqueiro da fornalha, operário blindado, autómato de fundição, drone de lava, lança-chamas, sentinela de pressão | boa variedade nominal; o trabalhador corrompido domina (12 de 25 inimigos) |

Sem prova em contrário, o "arqueiro das sombras" e o "arqueiro da fornalha" são o mesmo `cuspidor`, e o "golem aéreo" e o "goblin de carga" são o mesmo `carga`. **Nota: 5/10.**

---

## 7. GUARDIÕES

Facto estrutural: **N1–N19 acabam todos num guardião ou boss.** Na Região I, os guardiões (Ghorak, Morvanna, Rainha Aracnídea, Entrevane) **são chefes da campanha antiga despromovidos** (o próprio `.tscn` do N6 diz que o Golem é o `ChefeCarcereiro` renomeado, "por causa de uids").

| Problema | Impacto |
|---|---|
| Cadência previsível: cada nível é "travessia → guardião → porta" | o guardião deixa de ser evento e passa a rotina |
| HP fora de ordem na Região I (N1 915 > N2–N4) | o pico de combate está no nível de ensino |
| Na Região IV os elites não fecham a porta | o "guardião" é ignorável (25 s até à porta) |
| Repetição: 19 guardiões/bosses em 19 níveis | dilui os 3 bosses reais |

**Recomendação de design (dura):** **retirar o guardião de ~metade dos níveis.** Um guardião em N2 e N4 de cada região (o N3 fica para um desafio de travessia sem luta) e o boss no N5. Menos guardiões, mais memoráveis. **Nota: 5/10.**

---

## 8. BOSSES (N5, N10, N15; o N20 fica fora)

| | N5 Coração Putrefacto | N10 Guardião dos Céus | N15 Vyrak |
|---|---|---|---|
| Cânone | **"Guardião Verde"** (desvio de nome) | ✔ | ✔ nome; ✘ aparência |
| HP em jogo (bot v2, com habilidades) | 1 706 | 1 996 | 3 019 (a vida escala com o estado do jogador; sem habilidades dava 1 265) |
| Fase 2 a 50 % | sim (mesmo vocabulário encadeado + aura 9G) | sim (vento passa a pulsado, ×1,18) — muda a luta, bom | sim (rotação própria, janela mais curta) |
| Arte | boa (raízes, núcleo magenta) | **boa** (ave grande, legível) | **muito abaixo do necessário**: figura de formas lisas gerada por `tools/gerar_chefes_anim.py`, contra uma prancha (`region_03/boss_pack.png`) de figura alada ornamentada a ouro e azul-marinho, com sinos e arena no topo da torre |
| Apresentação | **nenhuma fala** | falas de intro e de fim ✔ | **nenhuma fala**, e o cânone diz que a região deve *introduzir o Vyrak como ameaça* |
| Arena | laje plana da Região I | poço vertical (o bot nunca o sobe, y_min 615) | laje genérica; a arena da prancha (sino gigante, lua, plataformas laterais) não existe |
| Parece clímax de 5 níveis? | **parcialmente** | **sim** (o melhor dos três) | **não** |

TTK: o bot não consegue matar nenhum guardião/boss em 6 min (limitação do combate do bot, ver §0). Teórico, a ~266 de dano/s com acertos limpos: N5 ≈ 6,4 s, N10 ≈ 7,5 s, N15 ≈ 11,3 s de dano puro, ou seja, 27/32/48 golpes. A curva de HP dos bosses sobe corretamente. **Os tempos reais dependem de janelas e telégrafos que só um humano mede.**

**Notas:** N5 6/10 · N10 7/10 · N15 **3/10**. Global bosses **5/10**.

---

## 9. LEVEL DESIGN — FICHAS N1–N19

Tamanho = maior X/Y da cena. Inimigos = instâncias de `DemonioBase` comuns. CP = checkpoints na cena. "Bot" = resultado da bateria v2 (ver §0; vertical = não medível pelo bot). Dificuldade 1–10 = relativa e **estimada** (design + dados), não é nota de qualidade.

| N | Nome (jogo) | Papel | Tamanho | Inim. | CP | Mecânica | Guardião/boss | Dif. | Principais problemas |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Corrupted Forest | Teach | 6 290 | 1 | 3 | saltos, raízes | Ghorak 915 HP | 3 | 1 inimigo; guardião mais duro da região; faixa roxa lisa no ¼ inferior |
| 2 | Swamp of Whispers | Develop: Dash | 5 930 | 1 | 3 | dash sob teto, raízes | Morvanna | 3 | 1 inimigo; raízes em polígonos (doc admite); hotspot de mortes nas raízes (x 2 400–2 700) |
| 3 | Black Widow's Nest | Combine: Pogo | 7 230 | 3 | 4 | pogo em espinhos | Rainha Aracnídea | 4 | 7,2 k px para ensinar 1 verbo; mesmo fundo/terreno |
| 4 | The Weeping Tree | Challenge: Especial | 7 830 | 8 | 5 | energia/especial | Entrevane | 5 | "zona de recuperação" de 450 px vazia, assumida no doc; o nível mais longo da região |
| 5 | Heart of the Forest | Exame + boss | 4 490 | 3 | 4 | revisão | Coração Putrefacto | 5 | sem falas; o nome não bate com o cânone |
| 6 | The Open Cliffs | Teach: vento | 5 860 | 3 | 5 | rajadas | Golem das Falésias | 4 | o doc tem 3 zonas de vento a cobrir checkpoint/arena (decisão em aberto) |
| 7 | The Rising Gorge | Develop | 6 350 | 4 | 5 | vento + plataforma móvel | Ignivar | **7** | **pico**: o bot morre 110–120× em x 4 200–4 400 (plataforma móvel em vento pulsado 1 600 sobre o vazio + elite) nos 3 perfis; precisa de verificação humana, mas está fora de ordem para um "Develop" |
| 8 | The Suspended Ruins | Combine | 6 420 | 3 | 6 | combinação | Dama Guilhotina | 6 | hotspot do casual em x 600 / 1 800 |
| 9 | The Turning Gale | Challenge | 6 650 | 6 | 6 | vento variável | Irmãos Condenados | 6 | ok pelo bot (chega à porta) |
| 10 | The Eternal Winds | Boss | 1 052 (poço) | 1 | 2 | vertical | Guardião dos Céus | 6 | o melhor boss; a arena vertical não é medível pelo bot |
| 11 | Entrance of Echoes | Teach R3 | ~1 065 | 4 | 3 | sinos | — | 2 | **NÃO reformulado**: polígonos placeholder (sinos amarelos, plataformas lilás); acaba em **31 s**; sem doc autoral |
| 12 | Vertical Galleries | Develop | 3 040×~2 400 | 6 | 5 | elevadores, sinos | elite | 5 | vertical (bot não mede); ok visualmente |
| 13 | Ancient Mechanisms | Combine | 3 730×2 250 | 6 | 6 | alavancas, engrenagens, 3 sinos | Construto Vitral | 6 | **muito escuro**; vazios pretos fora dos limites visíveis; faixa de engrenagens repetida tipo papel de parede |
| 14 | The Belfry | Challenge | 3 400×3 450 | 8 | 5 | baloiços, órbita, temporizadas | Monge das Correntes | 7 | ambicioso; ritmo por validar em humano |
| 15 | The Summit of Echoes | Boss | 3 730 | 14 | 4 | fragmentos, fase | **Vyrak** | 7 | boss com arte provisória; fundo com píxeis gigantes |
| 16 | Furnace Gate | Teach R4 | 4 500 | 7 | 5 | piso quente, jatos | elite | 3 | porta em 25–46 s; **mecânicas mudas** (sem SFX) |
| 17 | Foundry | Develop | 5 100 | 7 | 5 | lajes, elevadores, carrinhos | Autómato | 4 | porta em 36–54 s; mudo |
| 18 | Lava Chamber | Combine | 6 730 | 6 | 4–11 | lava ascendente, poços | Sentinela de Pressão | 4 | porta em 35–57 s com 2–4 mortes nos 3 perfis; a lava que sobe não pressiona o suficiente |
| 19 | Pressure Room | Challenge | 6 662 | 5 | 5–8 | pistões, válvulas | Lança-Chamas (placeholder de canon) | 4 | porta em 35–48 s; pistões/válvulas **sem som** |

**Preservar quase como estão:** N10 (boss), N12, N14 (base), N9.
**Alterar:** N1, N2 (densidade e o guardião), N4 (cortar ~25 %), N7 (pico), N13 (luz e vazios), N16–N19 (selar progressão com combate em alguns pontos + som).
**Refazer:** **N11** (é o único nível N1–N19 nunca reformulado) e a **arte/arena do N15**.

---

## 10. CURVA DE DIFICULDADE (estimada)

```
N : 1 2 3 4 5 | 6 7 8 9 10 | 11 12 13 14 15 | 16 17 18 19
D : 3 3 4 5 5 | 4 7 6 6  6 |  2  5  6  7  7 |  3  4  4  4
              ^ pico          ^ vale             ^ planalto baixo
```
- **Pico fora de ordem:** N7 (develop) acima de N8–N10.
- **Vale:** N11 (2) logo a seguir ao boss do N10 é uma descida grande demais; reforça que o N11 não foi feito.
- **Região IV:** N16–N19 atravessam-se TODOS em menos de 1 min pelo bot (25–57 s, 0–5 mortes, 3 perfis); a região está **mais fácil do que a III**, o que inverte a escalada esperada.
- Ghorak (N1) com mais HP do que os guardiões de N2–N4.

---

## 11. REGIÃO I — Floresta (N1–N5)

- **Identidade:** forte em atmosfera; **fraca em variedade**: os 5 níveis partilham fundo (castelo com aqueduto), terreno (laje com estalactites) e paleta. Em captura isolada não se distinguem; só o N5 (cristais magenta) se identifica.
- **Progressão mecânica:** a **melhor do jogo** no papel: dash (N2), pogo (N3), especial/energia (N4), exame (N5), cada um com portão desenhado contra o envelope medido.
- **Combate:** goblin + gosma; 16 inimigos comuns em 5 níveis.
- **Música:** `region_01_midnight_forest.mp3`, ciclo de 168 s, −12,4 LUFS. O boss (`boss_01_gothic_candlelight.mp3`) está a **−19,1 LUFS**, 7 dB **abaixo** da exploração: o boss soa mais baixo do que o passeio, o que é um anticlímax.
- **Cânone:** chama-se "Corrupted Forest" em jogo; o cânone diz "Floresta Sagrada"; o boss chama-se "Coração Putrefacto" e o cânone diz "Guardião Verde".

**Nota da região: 5,5/10.**

## 12. REGIÃO II — Desfiladeiro dos Ventos (N6–N10)

- **Parece região nova?** **Sim no visual, só a meio no sentir.** A pixel-art e a paleta rosa/violeta batem com a prancha. Mas a prancha promete **desfiladeiro vertical, falésias, exposição** e o jogo é **um castelo nas nuvens com chão plano** e a mesma faixa roxa no fundo do ecrã.
- **Vento:** mecânica bem implementada (WindZone, contínuo/pulsado, limiar em `movimento.gd`). As **linhas-guia são quase invisíveis** em captura (traços finos brancos sobre céu claro), e o texto de ensino do vento (`mec.rajada.txt`) manda precisamente "ler as linhas-guia".
- **N10:** o melhor boss do jogo.

**Nota: 6/10.**

## 13. REGIÃO III — Torre dos Ecos (N11–N15)

- **Identidade:** a mais forte em mecânicas (sinos, engrenagens, alavancas, órbitas, temporizadas). É a que melhor cumpre o contrato **no desenho**.
- **Execução:** a **mais irregular**: o N11 é placeholder; o N13 é escuro e mostra vazios pretos; o fundo do N15 está ampliado ao ponto de mostrar píxeis gigantes; o Vyrak é provisório.
- **Escalada N11→N15:** existe de N12 a N14; o N11 parte-a e o N15 falha no clímax.
- **Música:** ciclo de 96 s.

**Nota: 5/10.** Tem o melhor potencial e o pior polish.

## 14. REGIÃO IV — Fornalha (N16–N19)

- **Identidade:** fortíssima em cor (vermelho/laranja), coesa entre níveis, **mas os 4 níveis parecem o mesmo nível** (mesmo forno, mesmo arco, mesma laje de pedra, mesma lava estilizada).
- **Legibilidade:** a Koliani (escura, vermelho/preto) perde-se contra o fundo vermelho saturado.
- **Mecânicas:** pistões, válvulas, jatos, piso quente, lava ascendente, carrinhos: boa lista, **todas mudas** (nenhum `Som.*` em `pistao_fornalha.gd`, `valvula_fornalha.gd`, `jato_fornalha.gd`, `lava_fornalha.gd`, `piso_quente.gd`). Numa região de maquinaria, isto é uma falha grave de feedback.
- **Combate:** opcional (25–57 s até à porta, nos 4 níveis).
- **Música:** ciclo de **73 s** para níveis de 4,5–6,7 k px: repetição audível várias vezes por nível.

**Nota: 5,5/10.**

---

## 15. ARTE APROVADA vs JOGO

| Nível | Contrato | Implementação | Desvio | Severidade |
|---|---|---|---|---|
| N1–N5 | só textual (sem PNG) | fundo pintado HD, terreno igual nos 5 | sem landmark por nível | MÉDIA |
| N1–N10 | — | faixa roxa lisa no ¼ inferior (plano de morte) | parece placeholder; desperdiça ecrã | MÉDIA |
| N6–N10 | desfiladeiro, falésias, vertical (`concept_environment_01.png`) | castelo nas nuvens, chão plano, tijolo roxo único | composição não lê como desfiladeiro | MÉDIA |
| N11 | entrada da torre, sinos | **polígonos de cor sólida** | placeholder em produção | **ALTA** |
| N13 | coração da torre, iluminado | interior muito escuro, vazios pretos | perde a leitura | MÉDIA |
| N15 | arena no topo, Vyrak ornamentado (`boss_pack.png`) | laje genérica, Vyrak de formas lisas, fundo ampliado | o clímax não corresponde | **ALTA** |
| N16–N19 | metal, grelhas, maquinaria (`concept_environment.png`) | paleta certa, terreno de pedra genérica, props repetidos | sem landmark por nível | MÉDIA |
| Global | "o mais próximo possível de Dead Cells" | 4 densidades de píxel / 2 técnicas (pintado vs pixel) | **o jogo não parece um só** | **ALTA** |

---

## 16. ANIMAÇÕES

- **Koliani base (Golden Set):** run com 10 frames aprovado, idle 7, ataque 6×4, dash 3, roll 6, **hurt 2, morte 3** (pouco para o momento mais repetido de um jogo difícil).
- **Inimigos da Região II:** refeitos a 1 out (relatório com GIFs). As outras regiões não foram auditadas frame a frame.
- **Vyrak:** 6 frames de formas lisas; destoa.
- **Risco visto em captura:** fundo pixel-art filtrado (desfocado) por trás de sprites `Nearest`: mistura de filtros.
- Foot sliding/pops: **não medido** (exige gravação contínua; fica para o QA humano).

**Nota: 6/10.**

## 17. VFX

- Bom: aura de fase 2 dos bosses, impactos do pogo/salto duplo por skin, glow roxo da espada (sóbrio).
- Fraco: hitstop quase nulo tira peso aos VFX de golpe; as linhas do vento não se leem; as mecânicas da Região IV têm brilho mas não som (o VFX está sozinho).

**Nota: 6/10.**

## 18. MÚSICA

| Faixa | Ciclo | Loudness |
|---|---|---|
| Região I | 168 s | −12,4 LUFS |
| Região II | 265 s | −11,3 |
| Região III | 96 s | −12,4 |
| Região IV | **73 s** | −13,0 |
| Boss I | 92 s | **−19,1** |
| Boss II | 86 s | −13,3 |
| Boss III | 114 s | −15,5 |
| Boss IV | 149 s | **−9,0** |

- **Spread de 10 dB entre bosses** e o boss I abaixo da exploração: o mix não está normalizado.
- MP3 em ciclo: o *padding* do codificador pode criar um buraco no ponto de loop (a memória do projeto já documenta o problema; ver `loops-de-musica-sem-emenda`). Não verificado ficheiro a ficheiro.
- **`scripts/musica.gd` tem 4 sistemas de música sobrepostos** (`bg_*.mp3` legado, `producao/*.wav`, `approved/`, `music/regions/`). É dívida técnica e risco de tocar a faixa errada.
- Qualidade musical de ouvido: **não avaliada** (sem ouvido humano). Não dou nota a identidade/memorabilidade.

**Nota (só técnica): 5/10.**

## 19. SFX

- Positivo: há som por significado (relatórios 9H.13/13B), sons por família de inimigo (`mob_*`), `Som.toca_actor` com corte por visibilidade da câmara (evita ruído fora do ecrã).
- **Negativo:** a Região IV inteira de maquinaria é muda; `assets/audio/` tem duplicados `.wav`/`.ogg`/`_v2`/`_v3` lado a lado (risco de chamar o ficheiro antigo).
- Off-screen: o corte por visibilidade também elimina **aviso sonoro** de perigos fora do ecrã (ex.: um pistão que vai cair à frente). Falta um meio-termo (som atenuado perto da borda).

**Nota: 5/10.**

## 20–21. UI E MENUS

- **Menu principal: 8/10.** Hierarquia clara, key art forte, tipografia gótica coerente. Tirar "DEVELOPER MODE" das builds de teste.
- **Pausa:** modernizada a 1 out; a ferramenta de captura `tools/shot_ui_9h11.gd pausa` está **partida** (procura o nó `Painel`, que já não existe). A pausa real não foi capturada por mim; ver §31.

## 22. SELETOR DE NÍVEIS

- Bom: carrossel por região, cartão com progresso ("0/5 complete"), boss marcado.
- Mau: **"ATUAL"** escrito à mão em `scripts/seletor_niveis.gd:384` (viola a regra do i18n); os nomes das regiões **errados** contra o cânone: `world.catacombs` = "Catacombs of the Abyss" para a **Região IV (Fornalha)**, `world.forest` = "Corrupted Forest" (cânone: Floresta Sagrada); `EstadoJogo.REGIOES` ainda usa ids da campanha antiga.
- O mapa do mundo e o seletor deram a mesma imagem na captura (verificar se o `MapaMundo` reencaminha).

**Nota: 6/10.**

## 23. HUD

**7,5/10.** Retrato com vidas, barras de vidro, nome do nível + região + progresso ao centro, moedas à direita. Limpo e legível a 1600×720. Problemas: o cartão do tutorial (ex. "Gusts") ocupa ~20 % da largura no canto superior esquerdo durante o jogo; a barra de energia tem segmentos pouco distintos.

## 24. LOJA

**4/10 — parece painel técnico com uma montra bonita.**
- **Bug visível:** `skin_shadowblade` está **duas vezes** em `scripts/loja_catalogo.gd` (linhas ~101 e ~105, a 2.ª sem `splash`) e aparece **duas vezes na grelha**. O próprio `LojaCatalogo.validar()` deteta "id duplicado", portanto a suite tem de estar vermelha por isso.
- 5 itens `placeholder: true` (incluindo `skin_carmesim`, `skin_luar`, `skin_coracao_podre`) vendidos sem arte; células vazias (◇) visíveis.
- Texto do cartão/detalhe a ~8 px de altura a 720p: **ilegível em telemóvel**.
- `GRATIS_EM_DESENVOLVIMENTO = true` no master: a economia nunca foi testada com preço real.
- O destaque (splash pintado) é bonito; as miniaturas de pixel-art minúsculas ao lado perdem-se.

## 25. SKINS

| Skin | Tipo | Avaliação |
|---|---|---|
| Base (Golden Set) | referência | boa |
| Fornalha | recolor de paleta | barata; **sem VFX próprios** (as outras têm 5 pastas de VFX) |
| Abadia Afogada | recolor | barata |
| Celestial | recolor | barata e **vendida como "lendária" (250 Veracoins)**: desonesta para o comprador |
| Anjo (premium) | peças por cima | asas grandes e **estáticas, iguais em idle/run/roll**: lê-se como "colado" |
| Demónio (premium) | peças por cima | a melhor das premium em silhueta |
| Shadowblade | arte do Paulo, 113 frames, paridade completa | boa arte; **baixo contraste em fundos roxos/azuis** (Regiões I/II): a personagem desaparece. Rolamento = sprite rodado, não poses desenhadas |

Paridade de frames: 113 PNG em todas as skins, exceto a Fornalha (85, sem `vfx/`). **Nota: 5/10.**

## 26. PROGRESSÃO

- Habilidades: dash (coletável N2), pogo (coletável N3), especial (N4), salto duplo (boss N5, `HABILIDADE_DO_CHEFE`), escalar paredes (boss N10). Coerente.
- Regra "skill não apanhada não bloqueia": nos níveis N2–N4 o coletável está no caminho crítico e o portão seguinte exige-o, portanto não é possível concluir sem ele. As habilidades de boss são dadas na morte do boss. **Não encontrei bloqueio por código**; não foi testado por playthrough completo.
- Economia: Essência + Kolicoins + Veracoins (3 moedas) para um jogo com 19 níveis jogáveis é **sobreconstruído**.

## 27. SAVE

Não reproduzi perda de progresso. Pontos positivos: save não bloqueante (Execution 8.1d), testes isolados por `tools/godot_isolado.py` (verificado em todas as minhas execuções: "save real intacto"). Risco conhecido: a suite já apagou a essência real uma vez (memória do projeto). **Não testado:** fechar a meio de um checkpoint e reabrir no Web/Android.

## 28. MOBILE UX

**4,5/10.**
- **6 botões** à direita (especial, escudo, projétil, ataque, dash, salto); **dois com o mesmo ícone "••"** (especial e projétil indistinguíveis).
- O cacho cobre ~⅓ direito do ecrã, que é **a direção de avanço** em quase todos os níveis.
- O ataque, o botão mais usado, é **o mais pequeno** e está **no meio** do cacho.
- Pogo = joystick para baixo + ataque no ar: dois polegares, precisão alta. É o verbo mais arriscado em toque.
- A Koliani tem ~70 px a 720p; em 6" fica pequena para ler telégrafos.
- Texto da loja ilegível a ~8 px.

## 29. PERFORMANCE

Ver anexo "Medições de performance" no fim (sonda `tools/perf_gate.tscn`, Windows). **Não medido em telemóvel**, que é a plataforma principal: é a maior lacuna desta auditoria e da equipa.

---

## 30. BUGS

| ID | Sev. | Descrição | Evidência | Reprod. |
|---|---|---|---|---|
| B1 | **HIGH** | `skin_shadowblade` duplicada no catálogo; aparece 2× na loja; o validador marca "id duplicado" | `scripts/loja_catalogo.gd:101` e `:105`; `ui/02_loja.png` | sempre |
| B2 | **HIGH** | N11 com geometria placeholder (polígonos sólidos) em produção | `region03/n11_2_terco.png`, `n11_3_doisterc.png` | sempre |
| B3 | MEDIUM | Região IV mostrada como "Catacombs of the Abyss" | `assets/i18n/en.json` `world.catacombs`; `EstadoJogo.REGIOES[3]` | sempre |
| B4 | MEDIUM | "ATUAL" sem tradução no seletor | `scripts/seletor_niveis.gd:384`; `ui/03_seletor.png` | sempre |
| B5 | MEDIUM | Mecânicas da Região IV sem som | `scripts/{pistao,valvula,jato,lava}_fornalha.gd`, `piso_quente.gd`: 0 chamadas `Som.` | sempre |
| B6 | MEDIUM | Vazios pretos visíveis fora dos limites no N13 | `region03/n13_*` | sempre (câmara) |
| B7 | LOW | "DEVELOPER MODE" no menu em build de playtest | `ui/01_menu_principal.png` | sempre |
| B8 | LOW | Fundo pixel-art com filtro suave (desfocado) | `ui/10_toque_n9.png`, `region03/n15_*` | sempre |
| B9 | LOW (ferramenta) | `tools/shot_ui_9h11.gd pausa` partido (nó `Painel`) | log de execução | sempre |
| B10 | LOW (ferramenta) | `tools/bot_humano_r2.gd` não entrega habilidades: métricas inválidas em N3+ | §0 | sempre |
| B11 | processo | suite com "9 falhas pré-existentes" normalizadas | `docs/retomar_aqui.md` | — |

Nenhum BLOCKER de progressão confirmado em N1–N19 (o bot ficou preso em portões de dash, mas isso é limitação do bot e não do jogo).

## 31. PROBLEMAS DE DESIGN

| ID | Problema | Onde |
|---|---|---|
| D1 | Densidade de combate muito baixa; combate opcional na Região IV | global |
| D2 | Todos os níveis acabam num guardião; guardiões = bosses reciclados | global |
| D3 | Curva fora de ordem: N7 pico, N11 vale, R4 mais fácil do que a R3, Ghorak N1 > N2–N4 | §10 |
| D4 | Níveis longos para a ideia que carregam (N3 7,2 k px para o pogo; N4 com zona morta assumida) | R1 |
| D5 | Sem prólogo nem narrativa visível; a lore está escondida em `clue.*` | global |
| D6 | 3 moedas e 5 skins para um jogo sem campanha jogável completa: sobreconstruído | loja |
| D7 | Estrutura repetida "plano → portão sob teto + poço → raízes → guardião" na Região I | N1–N4 |

## 32. PROBLEMAS VISUAIS

V1 estilos misturados entre regiões · V2 Vyrak provisório · V3 N11 provisório · V4 sem landmark por nível (R1, R4) · V5 faixa roxa do plano de morte · V6 Koliani pouco legível na R4 e a Shadowblade na R1/R2 · V7 N13 escuro · V8 texto da loja · V9 recolors vendidos como premium.

## 33. PROBLEMAS DE ÁUDIO

A1 Região IV muda · A2 loudness dos bosses de −19 a −9 LUFS · A3 ciclo de 73 s na R4 · A4 4 sistemas de música em `musica.gd` · A5 duplicados de SFX · A6 nenhum aviso sonoro de perigo fora do ecrã.

## 34. INCONSISTÊNCIAS

Cânone vs jogo (nomes de região e de boss), ids internos da campanha antiga (`catacumbas`, `Cemiterio_dos_Reis.tscn` = Fornalha), i18n `level.nXX` desfasado de 1 em relação ao número do nível, ficheiros de cena com nomes legados ("mudar parte saves"), o boss Vyrak contra a prancha, arte pintada vs pixel.

---

## 35. TOP 10 PROBLEMAS (por impacto no jogador)

| # | Problema | Evidência | Impacto | Solução | Esforço | Prio |
|---|---|---|---|---|---|---|
| 1 | **Combate raro e raso** (1–8 inimigos/nível, hitstop invisível, 7 comportamentos, combate opcional na R4) | §5, contagens das cenas, bot R4 25–54 s | muito alto | +2–3 encontros desenhados por nível; hitstop 50–80 ms em golpe pesado/crítico (resolver o "drop" em vez de o evitar); 2–3 comportamentos novos com telégrafo; selar zonas com combate pontualmente | L | P1 |
| 2 | **Jogo visualmente fragmentado** (pintado vs 3 densidades de pixel; filtro suave) | §15, folhas `_folha_r*.jpg` | muito alto | escolher UMA densidade de píxel e UMA regra de filtro; regenerar fundos da R3 sem upscale; decidir se a R1 fica pintada (e as outras sobem) ou desce para pixel | XL | P1 |
| 3 | **N11 placeholder e Vyrak provisório** | B2, §8 | alto | refazer o N11 com o pipeline dos N12–N14; Vyrak a partir de `boss_pack.png` + arena + falas | L | P0 (N11) / P1 (Vyrak) |
| 4 | **Narrativa invisível** | §3, `clue.*` | alto | prólogo de 3–4 painéis + falas de intro/fim nos 3 bosses + 1 pista por região (reativar `clue.*`) | M | P1 |
| 5 | **Mobile: controlos ocupam a direção de avanço; ícones duplicados; ataque pequeno** | `ui/10_toque_n9.png` | alto | 4 botões no máximo (ataque grande, salto, dash, especial contextual); ícones únicos; câmara com *look-ahead* a compensar o cacho | M | P1 |
| 6 | **Níveis sem landmark e repetidos dentro da região** (R1, R4) | folhas R1/R4 | alto | 1 landmark por nível (peça de fundo única + paleta de luz própria) e terreno com 2–3 variações | M | P2 |
| 7 | **Guardião em todos os níveis** | §7 | médio-alto | retirar de ~metade; os que ficam, com arena própria | M | P1 |
| 8 | **Curva de dificuldade fora de ordem** | §10 | médio-alto | N7: tirar o elite do troço com vento pulsado ou baixar para 1 300; Ghorak para ~500; R4: subir pressão | S | P1 |
| 9 | **Loja com bug visível, placeholders e texto ilegível** | B1, §24 | médio | apagar o duplicado; esconder itens `placeholder`; texto ≥ 14 px; recolors não "lendários" | S | P0 (B1) / P2 |
| 10 | **Região IV muda + mix desnivelado** | B5, §18 | médio | SFX de pistão/válvula/jato/lava; normalizar a música a −14 LUFS ±1; ciclo da R4 ≥ 150 s | S–M | P1 |

## 36. TOP 10 PONTOS FORTES

1. **Física de movimento medida** (envelopes de salto/dash usados para desenhar portões): preservar, é o padrão de ouro do projeto.
2. **Menu principal e key art**: nível comercial; deve servir de referência de acabamento para a loja.
3. **Atmosfera da Região I em captura**: o fundo pintado tem a profundidade e a luz que o alvo Dead Cells pede.
4. **HUD moderno**: limpo, informativo, coerente com o menu.
5. **Pogo intencional com custo** (startup/punição): bom desenho de verbo; padrão para outras habilidades.
6. **Guardião dos Céus (N10)**: a fase 2 muda a luta (vento pulsado) em vez de só inflar números, e tem falas; é o modelo para os outros bosses.
7. **Ferramentas e pipeline** (geradores por região, `godot_isolado.py`, travessias físicas): permitem iterar com segurança.
8. **Textos de ensino das mecânicas** (`mec.*.txt`): curtos, concretos, explicam a regra e a exceção.
9. **Região III em desenho de mecânicas** (sinos, engrenagens, órbitas): a mais rica; merece o polish que não tem.
10. **Contratos visuais por região** (pranchas II–IV): dão um alvo claro e mensurável; o problema é cumpri-los, não tê-los.

## 37. QUICK WINS (alto impacto / baixo esforço)

1. Apagar a 2.ª `skin_shadowblade` do catálogo (XS).
2. `world.catacombs` → "The Furnace" (+ 5 línguas) e `world.forest` → nome canónico; "ATUAL" → `Textos.t()` (XS).
3. Esconder "DEVELOPER MODE" fora do modo dev (XS).
4. Hitstop: golpe 35 ms, remate 60 ms, crítico 80 ms, atrás de flag `combate_hitstop_v2` (S).
5. Normalizar a loudness da música (S).
6. SFX dos 5 mecanismos da R4 com `Som.toca_actor` (S).
7. Linhas do vento mais grossas e com contraste (S).
8. Ícones únicos para especial/projétil; ataque maior (S).
9. Ghorak N1 para ~500 HP (915 contra 537/675/829 dos guardiões N2–N4); N7 sem o elite dentro do vento pulsado (S).
10. Esconder itens `placeholder: true` da loja (XS).

## 38. REWORKS IMPORTANTES

| Sistema | Tipo | Porquê |
|---|---|---|
| N11 | **REBUILD** | nunca foi reformulado; placeholder |
| Vyrak (arte + arena + apresentação) | **REBUILD** da arte, PATCH da IA | a IA de 2 fases existe; a arte não serve |
| Densidade de combate N1–N19 | **REWORK** | é desenho de nível, não código |
| Unificação visual (densidade de píxel/filtro) | **REWORK** | decisão de direção de arte + regeneração |
| Controlos tácteis | **REWORK** | layout e número de botões |
| Loja/economia | **REWORK** (simplificar) | 3 moedas e recolors premium |
| `musica.gd` | **REWORK** técnico | 4 sistemas sobrepostos |
| Guardiões | **REWORK** de estrutura | menos e melhores |

## 39. O QUE NÃO DEVEMOS REESTRUTURAR

- **Física/movimento base** (`movimento.gd`): suportado pelos números; só afinar a gravidade de queda.
- **Combo de 4 golpes e pogo**: estrutura boa; o problema é o *feedback* (hitstop) e a *falta de alvos*, não o sistema.
- **HUD novo** e **menu principal**.
- **Pipeline de geração por região** (`construir_nXX_*.py`, `r4_lib.py`) e **isolamento de save**.
- **IA do Guardião dos Céus** (N10).
- **Desenho de mecânicas da Região III** (N12–N14): falta polish, não redesenho.

## 40. ROADMAP RECOMENDADO (sem N21)

**Fase 1 — Blockers (P0):** catálogo duplicado; esconder placeholders da loja; nomes de região/canon; "ATUAL"; N11 refeito ou temporariamente fundido/encurtado com arte real; suite verde (zero falhas toleradas).
**Fase 2 — Gameplay/UX (P1):** densidade de combate; hitstop v2; 2–3 comportamentos novos; menos guardiões; curva (N7, Ghorak, R4); controlos tácteis (4 botões); prólogo + falas dos bosses; SFX da R4; playtest humano em telemóvel real com 3 jogadores externos.
**Fase 3 — Arte/áudio (P2):** unificação de densidade de píxel/filtro; Vyrak e arena do N15; landmark por nível em R1 e R4; luz do N13; normalização e ciclos de música; skins recolor reprecificadas ou fundidas.
**Fase 4 — Polish (P3):** animações de dano/morte, VFX de impacto, loja com texto ≥ 14 px e miniaturas maiores, áudio fora do ecrã atenuado, limpeza de SFX duplicados.

**Estamos prontos para N21? Não.** Ver §42, Q20.

---

## 41. SCORECARD FINAL

| Área | Nota | Justificação |
|---|---|---|
| Movimento | **7** | sólido e medido; queda um pouco "floaty"; toque não validado |
| Combate | **4** | estrutura boa, feedback fraco, poucos alvos, opcional na R4 |
| Inimigos | **5** | ~30 espécies sobre 7 comportamentos; R1 com 2 espécies |
| Bosses | **5** | N10 bom (7), N5 razoável (6), N15 fraco (3) |
| Level Design | **5** | boas ideias por nível; longos, repetidos, curva fora de ordem, N11 por fazer |
| Progressão | **6** | habilidades bem sequenciadas; economia sobreconstruída |
| Arte | **6** | frames isolados fortes; coerência fraca; placeholders em produção |
| Animações | **6** | Koliani boa; dano/morte curtos; Vyrak provisório |
| VFX | **6** | sóbrios e bons; sem peso por falta de hitstop |
| Música | **5** (técnico) | mix desnivelado, ciclos curtos na R4, 4 sistemas; qualidade de ouvido não avaliada |
| SFX | **5** | bom por significado; R4 muda; duplicados |
| UI | **6** | menu/HUD 7,5–8; loja/seletor puxam para baixo |
| UX | **5** | sem prólogo; tutorial textual bom; nomes errados |
| Loja | **4** | bug visível, placeholders, ilegível em telemóvel |
| Skins | **5** | Shadowblade e Demónio boas; 3 recolors caras |
| Performance | **7** | Windows: folga enorme (p99 < 3 ms em todos os níveis); telemóvel NÃO medido, o que impede nota mais alta |
| Polish | **4** | demasiados pormenores de produção visíveis |

### NOTA GLOBAL ATUAL: **5 / 10**

Não é uma média. É a experiência: **um jogo bonito em fotografia que ainda não é divertido de forma consistente**, com momentos bons (N10, Região III no papel, movimento) espalhados por uma travessia vazia e visualmente desunida.

## 42. REFERÊNCIA DE QUALIDADE

- **7/10** exige: combate presente e com peso (densidade + hitstop + 2 comportamentos novos), N11 e Vyrak refeitos, nomes/canon corrigidos, loja limpa, controlos tácteis revistos, prólogo e falas dos bosses, R4 com som, curva corrigida, **playtest externo em telemóvel real**.
- **8/10** exige, além disso: unificação visual (uma densidade de píxel), landmark por nível, música normalizada com ciclos longos, menos guardiões e mais memoráveis, animações de dano/morte e polish de VFX de impacto.
- **9/10** exige: direção de arte ao nível do menu **em todos os níveis**, inimigos com IA própria por espécie, bosses todos ao nível do N10 ou acima, áudio adaptativo e afinação de mobile por dados de jogadores reais. É trabalho de meses, não de semanas.

### Respostas às 20 perguntas

1. **O que está realmente bom?** Movimento, menu, HUD, atmosfera da R1, boss N10, pogo, pipeline/ferramentas, textos de tutorial.
2. **O que parece amador?** N11, Vyrak, loja (duplicado, células vazias, texto minúsculo), nomes de região errados, "DEVELOPER MODE", faixa roxa do plano de morte, mistura de estilos.
3. **Que níveis precisam de alterações?** N1, N2, N4, N7, N13, N16–N19 (alterar); N11 e a arte/arena do N15 (refazer).
4. **Que níveis preservar?** N10, N12, N14, N9 (com polish).
5. **A progressão N1–N19 funciona?** Mecanicamente sim (habilidades bem sequenciadas). Em dificuldade, não (pico no N7, vale no N11, R4 fácil).
6. **A dificuldade evolui corretamente?** Não; ver §10.
7. **Os bosses são bons?** Um sim (N10), um razoável (N5), um não (N15).
8. **O combate é suficientemente forte?** Não.
9. **A arte real corresponde às pranchas?** Na paleta sim; na composição, nos landmarks e no Vyrak, não.
10. **A música ajuda a identidade?** Tecnicamente está desnivelada; de ouvido não foi avaliada.
11. **A UI parece comercial?** O menu e o HUD sim; a loja e o seletor ainda não.
12. **A loja parece moderna?** A montra sim, o resto não; tem um bug visível.
13. **As skins têm qualidade suficiente?** Shadowblade e Demónio sim; Fornalha, Abadia e Celestial são recolors com preço de premium.
14. **O jogo é confortável em mobile?** Provavelmente não: controlos tapam o avanço, há ícones duplicados e o texto é pequeno. Precisa de teste em dispositivo.
15. **Maiores blockers?** Para playtest externo: N11 placeholder, catálogo duplicado, nomes errados, suite vermelha tolerada.
16. **O que corrigir primeiro?** Os quick wins de §37 e depois a densidade de combate.
17. **Em que NÃO perder tempo?** Mais skins, mais moedas, mais mecânicas, N21+, reestruturar a física.
18. **Qualidade atual real?** 5/10; alpha.
19. **Caminho realista?** Roadmap de §40: ~2 ciclos de correção para chegar a 6,5–7.
20. **Prontos para N21?** **Não.** Acrescentar 81 níveis em cima desta base multiplica os problemas sistémicos (combate raro, estilos misturados, guardião em todos os níveis). Primeiro fechar N1–N20 com playtest externo.


---

## ANEXO A — Medições de performance (Windows, `tools/perf_gate.tscn`, OpenGL3, 1152×648, sem VSync, 20 s)

| Cena | FPS médio (combate) | 1 % low | p95 ms | p99 ms | % frames > 33 ms |
|---|---|---|---|---|---|
| Menu | 1 891 (idle) | 1 255 | 0,64 | 0,80 | 0 |
| N1 | 891 | 516 | 1,57 | 1,94 | 0 |
| N5 | 817 | 457 | 1,74 | 2,19 | 0 |
| N10 | 800 | 456 | 1,81 | 2,19 | 0 (0,02 % em movimento) |
| N15 | 755 | 406 | 1,94 | 2,46 | 0 |
| N18 | 732 | 425 | 1,91 | 2,35 | 0 |
| N19 | **641** | **358** | **2,22** | **2,79** | 0 (0,02 % em movimento) |

Leitura: no PC não há problema. O N19 custa ~1,45× o N1 e é o candidato a vigiar em telemóvel. **Não extrapolo para telemóvel**: falta uma medição em dispositivo real (Android, aparelho de gama média), que é a próxima ação de performance.
Tempos de carregamento: não cronometrados nesta auditoria (sem engasgos > 33 ms observados nas fases medidas).

## ANEXO B — Bateria do bot v2 (com habilidades), 3 perfis × N1–N19, 360 s máx.

Lembrar §0: o bot não usa o dash sob teto, combate mal e não resolve níveis verticais. "timeout_jogo" = não chegou à porta em 6 min.

| Nivel | Perfil | Fim | Tempo (s) | Mortes | Golpes sofridos | Chefe vida min/max | X max/alvo | Hotspot de mortes (x) |
|---|---|---|---|---|---|---|---|---|
| n01 | casual | timeout_jogo | 360 | 31 | 86 | 449/915 | 5546/6290 | 4800 (8), 2800 (6) |
| n01 | experiente | timeout_jogo | 360 | 56 | 40 | 520/915 | 5539/6290 | 1200 (27), 1400 (17) |
| n01 | normal | timeout_jogo | 360 | 32 | 106 | 433/915 | 5539/6290 | 5400 (13), 1200 (6) |
| n02 | casual | timeout_jogo | 360 | 113 | 16 | 458/458 | 4617/5930 | 2400 (85), 2200 (19) |
| n02 | experiente | timeout_jogo | 360 | 94 | 21 | 537/537 | 4660/5930 | 2400 (76), 4200 (9) |
| n02 | normal | timeout_jogo | 360 | 87 | 31 | 537/537 | 4660/5930 | 2400 (66), 4200 (11) |
| n03 | casual | timeout_jogo | 360 | 48 | 153 | 502/675 | 7206/7230 | 6400 (25), 3600 (11) |
| n03 | experiente | timeout_jogo | 360 | 52 | 147 | 567/675 | 7075/7230 | 6400 (35), 3600 (8) |
| n03 | normal | timeout_jogo | 360 | 50 | 139 | 524/675 | 7088/7230 | 6400 (39), 6800 (7) |
| n04 | casual | timeout_jogo | 360 | 105 | 40 | 532/532 | 5585/7830 | 4800 (73), 5400 (20) |
| n04 | experiente | timeout_jogo | 360 | 75 | 120 | 505/829 | 7615/7830 | 7000 (47), 4800 (9) |
| n04 | normal | timeout_jogo | 360 | 84 | 105 | 462/829 | 7624/7830 | 7000 (40), 4800 (25) |
| n05 | casual | timeout_jogo | 360 | 40 | 131 | 1335/1706 | 4078/4490 | 4000 (13), 3800 (12) |
| n05 | experiente | timeout_jogo | 360 | 42 | 111 | 1294/1706 | 4127/4490 | 3800 (20), 4000 (10) |
| n05 | normal | timeout_jogo | 360 | 44 | 121 | 1392/1706 | 4075/4490 | 3800 (18), 3400 (8) |
| n06 | casual | timeout_jogo | 360 | 52 | 156 | 350/0 | 5618/5860 | 5400 (46), 5200 (4) |
| n06 | experiente | timeout_jogo | 360 | 47 | 138 | 309/0 | 5569/5860 | 5400 (27), 5200 (17) |
| n06 | normal | timeout_jogo | 360 | 47 | 132 | 243/0 | 5570/5860 | 5400 (39), 5200 (3) |
| n07 | casual | timeout_jogo | 360 | 112 | 5 | 184/0 | 5479/6350 | 4400 (50), 4200 (45) |
| n07 | experiente | timeout_jogo | 360 | 121 | 1 | 184/0 | 4536/6350 | 4200 (58), 4400 (39) |
| n07 | normal | timeout_jogo | 360 | 114 | 6 | 184/0 | 6363/6350 | 4200 (59), 4400 (43) |
| n08 | casual | timeout_jogo | 360 | 80 | 5 | 198/0 | 5204/6420 | 600 (22), 1800 (19) |
| n08 | experiente | timeout_jogo | 360 | 63 | 39 | 198/0 | 5228/6420 | 4800 (34), 5000 (15) |
| n08 | normal | timeout_jogo | 360 | 63 | 25 | 198/0 | 6426/6420 | 4800 (16), 5000 (11) |
| n09 | casual | timeout_jogo | 360 | 53 | 75 | 227/0 | 6610/6600 | 3200 (18), 3000 (11) |
| n09 | experiente | timeout_jogo | 360 | 36 | 110 | 227/0 | 6610/6600 | 6400 (23), 5000 (4) |
| n09 | normal | timeout_jogo | 360 | 34 | 115 | 227/0 | 6610/6600 | 6400 (25), 2800 (3) |
| n10 | casual | timeout_jogo | 360 | 2 | 0 | 1996/1996 | 984/900 | 800 (2) |
| n10 | experiente | timeout_jogo | 360 | 1 | 0 | 1996/1996 | 993/900 | 800 (1) |
| n10 | normal | timeout_jogo | 360 | 3 | 0 | 1996/1996 | 963/900 | 800 (3) |
| n11 | casual | porta | 50 | 4 | 13 | 0/None | 1211/1027 | 1200 (3), 600 (1) |
| n11 | experiente | timeout_jogo | 360 | 6 | 4 | 0/None | 2509/1027 | 2400 (3), 600 (2) |
| n11 | normal | porta | 31 | 3 | 10 | 0/None | 1209/1027 | 1200 (2), 600 (1) |
| n12 | casual | timeout_jogo | 360 | 38 | 0 | 267/0 | 2610/2900 | 2400 (20), 2200 (17) |
| n12 | experiente | timeout_jogo | 360 | 37 | 0 | 267/0 | 2558/2900 | 2400 (22), 2200 (15) |
| n12 | normal | timeout_jogo | 360 | 39 | 0 | 267/0 | 2576/2900 | 2200 (22), 2400 (17) |
| n13 | casual | timeout_jogo | 360 | 0 | 0 | 294/0 | 1044/3500 |  |
| n13 | experiente | timeout_jogo | 360 | 0 | 0 | 294/0 | 1044/3500 |  |
| n13 | normal | timeout_jogo | 360 | 0 | 0 | 294/0 | 1044/3500 |  |
| n14 | casual | timeout_jogo | 360 | 0 | 3 | 321/0 | 3390/3250 |  |
| n14 | experiente | timeout_jogo | 360 | 0 | 3 | 321/0 | 3390/3250 |  |
| n14 | normal | timeout_jogo | 360 | 0 | 3 | 321/0 | 3390/3250 |  |
| n15 | casual | timeout_jogo | 360 | 79 | 12 | 3019/3019 | 2961/3110 | 2600 (56), 2800 (21) |
| n15 | experiente | timeout_jogo | 360 | 75 | 22 | 3019/3019 | 2968/3110 | 2800 (37), 2600 (36) |
| n15 | normal | timeout_jogo | 360 | 75 | 25 | 3019/3019 | 2864/3110 | 2600 (46), 2800 (26) |
| n16 | casual | porta | 46 | 1 | 8 | 0/None | 4460/4500 | 2400 (1) |
| n16 | experiente | porta | 34 | 1 | 11 | 0/None | 4460/4500 | 3200 (1) |
| n16 | normal | porta | 25 | 1 | 9 | 0/None | 4458/4500 | 4000 (1) |
| n17 | casual | porta | 54 | 5 | 27 | 0/None | 5059/5100 | 4200 (3), 3000 (1) |
| n17 | experiente | porta | 36 | 2 | 15 | 0/None | 5060/5100 | 2800 (2) |
| n17 | normal | porta | 48 | 5 | 22 | 0/None | 5060/5100 | 4000 (2), 4200 (2) |
| n18 | casual | porta | 35 | 2 | 13 | 0/None | 6688/6730 | 3600 (1), 6200 (1) |
| n18 | experiente | porta | 57 | 4 | 20 | 0/None | 6689/6730 | 2800 (1), 3800 (1) |
| n18 | normal | porta | 45 | 3 | 18 | 0/None | 6688/6730 | 2800 (1), 3800 (1) |
| n19 | casual | porta | 48 | 3 | 14 | 0/None | 6620/6662 | 4200 (2), 6200 (1) |
| n19 | experiente | porta | 35 | 0 | 4 | 0/None | 6622/6662 |  |
| n19 | normal | porta | 39 | 1 | 7 | 0/None | 6619/6662 | 5800 (1) |
| n20 | casual | timeout_jogo | 480 | 20 | 48 | 2974/2974 | 594/2300 | -24600 (18), 400 (1) |
| n20 | experiente | timeout_jogo | 480 | 27 | 59 | 2974/2974 | 594/2300 | -24600 (23), -25000 (3) |

Conclusões robustas a tirar daqui (independentes da fraqueza do bot):
- **N16–N19 e N11 atravessam-se em menos de 1 min** com 0–6 mortes: o combate/a pressão nesses níveis é contornável.
- **N7** concentra 110–120 mortes no mesmo troço nos 3 perfis: pico localizado.
- Os portões de dash sob teto (N2, N4) e as raízes (N2) são onde o bot morre em massa: **confirmar com humanos** se os telégrafos das raízes chegam.
- O bot não vence nenhum guardião/boss de N1–N6 nem o Vyrak: a ferramenta precisa de um modo de combate antes de servir para medir TTK.

---

## ADENDA — N20 "Núcleo da Fornalha" (3 out 2026, build com o N20)

Travessia A–D sem mortes nos 3 perfis do bot; todas as mortes na arena (x≈5 000, 29–52 por perfil em 6 min); **o perfil experiente vence o Guardião da Fornalha** (2 889 HP), o único boss que o bot venceu. Performance PC: 609 fps em combate, p99 2,59 ms, 0,1 % de frames > 33 ms (o nível mais pesado). Pontos fortes: padrões fixos, telégrafos, janelas EXPOSTO, refúgios, reset limpo, falas. Problemas: 5 dos 10 ataques da prancha; a arena não transforma na fase 2; rig macio (poses pequenas ampliadas) e vermelho sobre vermelho; exame A–D fácil; mecanismos sem som; o seletor ainda diz "Catacombs of the Abyss". Notas: Level Design 6 · Boss 7 · Arte 6 · Legibilidade 5. Bosses globais passam a **6/10**.
Prompt único para o ChatGPT (N1–N20): `docs/qa/full_game_review/PROMPT_CHATGPT_PLANO_N1_N20.md`.
