# Auditoria global — consolidação do Lead Game Director

## 0. Cabeçalho

| Campo | Valor |
|---|---|
| Data | **25 set 2026** |
| Build auditada | `master` `bcac9fde` (v0.18.20) |
| Âmbito | o jogo inteiro: 100 níveis / 20 regiões, a Koliani, o combate, os inimigos, os chefes, a arte, o áudio, os sistemas, a UX e a base técnica |
| Modo | só diagnóstico. Nenhum script, cena, asset ou teste foi alterado. Este documento é a única escrita |
| Save real | SHA256 de `%APPDATA%\Godot\app_userdata\Koliani\progresso.json` = `9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238`. **Inalterado**: os 8 agentes confirmaram-no antes e depois |

### Método

Oito agentes especializados auditaram o jogo **em runtime**. Todo o Godot correu pelo wrapper
`godot_sandbox.sh`, com o APPDATA isolado. Cada agente usou harnesses próprios, fora do repo, e
separou o que foi **RUNTIME VERIFIED** do que ficou **STATIC ONLY**. Esta consolidação lê os 8
relatórios, as folhas comparativas do A4 e o canon (`KOLIANI_REGION_CANON.md`,
`visao_koliani_1_0.md`, `auditoria_reestrutura_niveis_1_20.md` — decisões do GM de 25/09). Também
confirmei por grep às cenas o mapa nível → script de chefe usado na secção 8.

| # | Relatório | Método principal |
|---|---|---|
| A1 | [01 — Game feel e movimento](qa/global_audit/01_game_feel_movimento.md) | arena a x=−30000 com input injetado e registo por tick; N1, N13, N56 e percurso real no N1 |
| A2 | [02 — Combate e inimigos](qa/global_audit/02_combate_inimigos.md) | censo dos 100 níveis (2969 inimigos); duelos por arquétipo; frame data medida |
| A3 | [03 — Level design](qa/global_audit/03_level_design.md) | geometria construída em runtime N1–N100; 90 runs de bot N1–N20; perfis e capturas |
| A4 | [04 — Direção de arte](qa/global_audit/04_direcao_de_arte.md) | 160 capturas em 40 níveis + 20 arenas; folhas prancha vs jogo |
| A5 | [05 — Bosses](qa/global_audit/05_bosses.md) | 13 lutas medidas (passiva 20 s + TTK a 111 DPS) |
| A6 | [06 — Áudio e feedback](qa/global_audit/06_audio_feedback.md) | ffmpeg (ebur128/astats) nos ficheiros; eventos→som em runtime, 4 níveis × 90 s |
| A7 | [07 — Sistemas, progressão e UX](qa/global_audit/07_sistemas_progressao_ux.md) | fluxo novo jogo→N1→morte→fim→seletor→loja cronometrado; censo de pickups |
| A8 | [08 — Técnico](qa/global_audit/08_tecnico.md) | carga/construção dos 100 níveis; determinismo 2×100; perf_gate N1 vs N96 |

### O que ficou STATIC ONLY (não provado em runtime)

- **Humanos e dispositivo.** Não houve playtest humano nem telemóvel real. As zonas de morte do bot
  (N3 trampolim, N4 espinhos, N5 ritmo, início da R3) são *candidatas*, não softlocks provados. O
  hit-stop "sub-frame" a 60 fps é aritmética, não observação num telemóvel.
- **Mistura e música.** Nenhuma escuta humana: loudness, SMR, caráter musical e clipping no Master
  foram medidos nos ficheiros. O headless usa o driver de áudio dummy.
- **Parte do combate.** One-hit kill sem crítico a partir do N45 (aritmética). Tiro contra
  voador/trepador. Combate com os VFX 9G da Região I, porque a arena de teste do A2 usava o fallback.
- **Parte dos chefes.** Padrões do N20 e dos N16–N29 não jogados. Guardiões da R2 como scripts de
  prisão reskinned (leitura de código).
- **Alcance dos níveis tardios.** Os avisos do gerador (N34 51/110, N46 97/134 e N50 143/155
  plataformas por alcançar) podem ser falsos positivos. Os pickups de habilidade legados dos N5–N29
  não foram confirmados como alcançáveis.
- **Ferramentas.** Os bots `XDG_DATA_HOME` que escrevem no save real no Windows foram deduzidos pelo
  código e não corridos, de propósito.
- **Narrativa.** Pistas/Diário dormentes e o conflito Aurora/Elara (leitura de i18n e docs).

### Reconciliação entre relatórios (contradições aparentes)

| Tema | O que parecia contraditório | Leitura consolidada |
|---|---|---|
| **Hit-stop** | A1: `HITSTOP_GOLPE` 10 ms, dano 20 ms. A2: 10/18/24 ms. A6: "boa cadeia hitstop+VFX+som" | Não há conflito. São constantes diferentes (golpe/pesado/crítico/dano recebido), todas **< 1,5 frame a 60 Hz**, afinadas num monitor de 165 Hz. O A6 avalia a *simultaneidade* dos sinais, que é boa. A1 e A2 avaliam a *duração*, que é invisível no alvo mobile. Conclusão: a estrutura fica, a duração é TUNE. STATIC nos dois casos |
| **Número de chefes** | A4: "3 específicos, 17 genéricos" (slots regionais). A5: "30 à mão + 70 genéricos", "85 boss.* vs 20 canónicos". A8: "70 `ChefeGenerico`, 56 cenas com `Guardiao`" | São três cortes do mesmo facto. **Há um encontro de chefe no fim de cada um dos 100 níveis.** N1–N30 têm 30 scripts escritos à mão, e N31–N100 usam `ChefeGenerico` (70). O canon pede **20 chefes regionais**. Nos 20 slots N×5: **3 correspondem ao canon aprovado** (I Coração Putrefacto por decisão do GM de 25/09, II Guardião dos Céus, III Vyrak), **3 são escritos à mão mas fora do canon** (N20 Olho do Abismo, N25 Noiva do Eclipse, N30 Zeriko Final) e **14 são genéricos** (N35–N100). O "Guardião Verde" do A5 está desatualizado: o GM trocou-o pelo Coração Putrefacto e o `KOLIANI_REGION_CANON.md` ainda não foi atualizado |
| **% procedural** | A3: R-I 60 %, R-II 47 %, R-III 96 %, VII–XX 97–99 % (média do comprimento spawn→porta). A8: mediana 87 % (N1–30) e 94 % (N31–100) (`jorn_x`÷(`jorn_x`+largura da cena)). A8 diz "97 de 100 com jornada"; A3 diz "96" | Métricas diferentes, conclusão igual. **97 cenas têm `corredor=true`**, mas o N100 salta a jornada em runtime por ser o último, portanto **96 níveis jogam com jornada procedural**. Só as Regiões I–II são híbridas (≈50–60 % procedural, graças às salas golden set e aos N8/N10). **Da Região III em diante, ≥ 90 % de cada nível é o gerador.** A mediana do A8 para N1–30 é puxada pelas R-III a R-VI |
| **Retry** | A7: retry de 0,47–0,81 s, "uma força". A8: o reload custa até 0,7–0,94 s de construção nos níveis tardios. A3: checkpoints a 2 800–3 700 px | As três coisas são verdade. O *tempo técnico* do retry é bom na Região I e piora com a campanha (≈ +0,85 s no N84/N96). O *custo de jogo* do retry é mau em todo o lado: cada queda devolve até ~3 000 px, ou 15–60 s de percurso refeito. A6 soma-lhe o reinício da música do chefe a cada morte |
| **Inimigos "sem ataque"** | A2 diz 56 % na secção 0 e 68 % na secção 6 | 55,8 % = só `patrulha`. 68 % = patrulha + escudeiro + trepador depois de cair. **Nenhum** inimigo tem hitbox de ataque própria |
| **Dificuldade tardia** | A2: os comuns ficam triviais (1 golpe a partir do N45). A5: os chefes N31+ matam em 2 toques (contacto 92) e o N100 é uma esponja de 16 320 HP | Mesma causa, sintomas opostos. `clampi(indice_nivel,0,29)` congela a vida e o dano dos atores no N30 (confirmado por A2, A5 e A7). O equipamento continua a subir até ao N100, e a vida dos chefes é escrita à mão por cena. Resultado: **mobs triviais e chefes injustos ao mesmo tempo** |
| **Nome da mãe** | CLAUDE.md, historia e pistas dizem "Aurora"; `visao_koliani_1_0.md` diz "Elara" | O documento de visão declara Elara canónica. O jogo e 30+ pistas ainda dizem Aurora. Decisão do GM pendente (ver "Decisões do GM") |

---

## 1. EXECUTIVE VERDICT

**Onde o Koliani está hoje.** O Koliani é um jogo **completo em extensão e incompleto em
intenção**. Tem 100 níveis jogáveis, um chefe no fim de cada um, save robusto, retry rápido,
localização em 6 línguas e build Web/Windows/Android. Mas a campanha que se joga é a de **3 de
setembro** (um gerador procedural com packs CC0 recoloridos e chefes de fórmula). O canon e as
pranchas de **15 de setembro** chegaram por cima dela e só foram aplicados, em parte, às Regiões
I–III. A auditoria confirma as duas conclusões do GM e acrescenta-lhes uma nuance.

- **"Só a Região I se aproxima da arte aprovada" — CONFIRMADO.** A Região I tem match visual **HIGH
  no ambiente / MEDIUM no conjunto** (A4). Tem kit de produção, gate 9A–9H e ≈2 230 linhas de
  código visual dedicado (A8). As Regiões II e III estão em **LOW**, e as 17 restantes em **NONE**.
  Não é falta de polish: fora da Região I, a arte aprovada **não tem caminho até ao ecrã**. Há 7
  materiais de terreno para 20 regiões, 14 packs de fundo de 240 px que rodam (o `luar` aparece em
  15 das 17 regiões IV–XX) e chefes feitos de trapézios em Python. Mesmo a Região I ainda mostra
  hazards em `Polygon2D`, um líquido cinzento de código e props de outra resolução.
- **"Mecanicamente fraco" — CONFIRMADO, com uma nuance.** A fraqueza **não está nas bases de
  baixo nível, está na camada de design por cima delas**.
  - A física de chão é boa: latência 0, aceleração em 7 ticks, buffer de 7 ticks, controlo no ar
    de 0,3 s, e o modelo é idêntico em N1, N13 e N56.
  - O combo da Koliani tem frame data explícita, cancels e buffer.
  - O que falha é o que se construiu por cima.
    - Um salto de 1,3 alturas de corpo, com um corte que trava como um teto.
    - Inimigos que são **corpos que magoam por contacto**, com comportamento sorteado, sem ataque,
      sem aggro e mortos em 1–2 golpes durante 100 níveis.
    - Um tiro ilimitado que anula todos os arquétipos terrestres com 0 de dano sofrido.
    - Níveis que **não ensinam nada**: 89 mecânicas estreadas em 96 níveis, nenhuma testada nem
      combinada.
    - Habilidades que **nunca são exigidas**.
    - 70 chefes com o mesmo ciclo fixo de 1,85 s.
  - Em resumo, o Koliani tem **verbos razoáveis e nenhum problema que os exija**.

**O que funciona (e é raro ter nesta fase).** A Koliani golden set é coerente nos 100 níveis. A
física de chão é seca e sem latência. O combo tem a estrutura certa, e a sinergia "o tiro marca → a
espada executa" tem identidade. O Vyrak é um chefe traduzido fielmente do contrato para o código. O
retry é de nível Celeste na Região I, o save v5 tem migrações e backup, e a geração é determinística
em 100/100 níveis. O desempenho em regime permanente é bom (p99 6–12 ms). As pranchas aprovadas das
20 regiões **já são o design** de cenário, bestiário e chefes. O pipeline da Região I **prova** que a
arte aprovada chega ao ecrã quando há um caminho dedicado.

**O que está abaixo do nível** (contra Celeste, Dead Cells, Hollow Knight, Nine Sols e Lost Crown):

- a qualidade de cada nível (fita de 15–40 mil px, ritmo plano, 36 % de "descanso");
- a identidade regional (recolor);
- a variedade e o papel dos inimigos;
- o vocabulário e a escala dos chefes;
- a animação de locomoção (land de 1 frame, brake com frames legados);
- a direção musical (playlist stock sem loops, ambiente único e inaudível, reinício no retry);
- a mistura (feedback de jogo 5–24 dB abaixo da música);
- a cerimónia da progressão (recompensas invisíveis, 1.ª arma pior do que a mão nua).

**Os maiores problemas estruturais.** São cinco, e explicam quase todos os sintomas dos oito
relatórios:

1. **O nível é o gerador.** A jornada procedural (`gerador_corredor.gd`, 5 528 linhas) é o
   esqueleto de 96 níveis. O desenho à mão é um apêndice no fim. É por isso que tudo se parece, que
   os níveis duram 4–9 minutos em vez de 1–3, que os checkpoints estão longe e que nenhuma prancha
   consegue ser cumprida "em layout".
2. **Não existe pipeline de região.** Nem para arte (kit), nem para bestiário (kit de inimigo), nem
   para mecânica (uma por região), nem para som (ambiente/tema). A Região I foi feita à mão uma vez e
   não se industrializou. As outras 19 são o mesmo jogo com outra cor.
3. **Os números pararam no N30.** O mesmo `clampi(indice,0,29)` em inimigos, chefes e drops, contra
   um equipamento que sobe até ao N100. Não há um modelo de TTK nem uma fonte única de dificuldade.
4. **Os sistemas de jogador não têm custo nem são exigidos.** O tiro é grátis, a Energia não tem
   gasto, o escudo não tem parry, o rolamento é mais rápido do que correr e as habilidades são
   opcionais. Daí as estratégias dominantes e a ausência de decisão.
5. **O canon não foi migrado.** O jogo segue a tabela de 3 set em nomes, temas e chefes: Zeriko no
   N30, 85 "bosses" contra 20, 17 regiões com o tema errado e "Aurora" contra "Elara". Enquanto a
   tabela única não existir, qualquer trabalho de conteúdo nas regiões IV–XX é trabalho deitado fora.

**Veredicto de direção.** Não se deve continuar a "renovar" região a região em cima do gerador (é o
que se fez na R2 e na R3, com fidelidade LOW). A ordem certa é esta:

1. fechar o canon;
2. refazer a **fundação** (movimento, modelo de números, kit de inimigo, pipeline de salas, RegionKit
   e mistura);
3. provar tudo num **vertical slice da Região I** com uma barra mensurável;
4. só depois industrializar região a região.

---

## 2. TOP 10 PROBLEMAS

> Critério: problemas estruturais que explicam muitos sintomas. Os bugs pequenos estão nos
> relatórios auxiliares.

### P-1 · O nível é a jornada procedural; o design autoral é um apêndice — **P0**

- **Evidência.**
  - 96 níveis jogam com jornada (97 cenas com `corredor=true`, que é o valor por omissão,
    `nivel_com_chefe.gd:43`).
  - Da R-III em diante, **≥ 90 % de cada nível é gerado**; nos N31–N100 são 97–99 %, e a sala à mão
    tem 450 px e 1 plataforma (A3 CR1, A8 RC1).
  - O comprimento é uma rampa, `2600 + 1250·idx` e depois 14 000→40 000 px
    (`gerador_corredor.gd:980–986`).
  - Os ~81 % de atores de enchimento são sempre os mesmos 6 tipos: serra em 87 níveis, pêndulo em
    90, fogo em 85, tudo via `_perigo_no_vao` (A3 CR4).
  - Jaccard médio de 0,46 entre quaisquer dois níveis.
  - 36,3 % das câmaras são `descanso`.
  - Checkpoints a 2 800–3 700 px em todos os níveis.
  - Tempos com bot: N11 a N15 levam 4,5–9 min só de jornada, contra 1–3 min no contrato da R3.
  - O N12 "reconstruído" é uma fila forçada dentro do gerador (`_n12_fila`) mais 4 ramos
    `if _idx == 11`.
  - O `_rng` é partilhado (346 sorteios): mexer numa câmara volta a sortear dezenas de níveis
    (A8 RC4).
- **Impacto.** Repetição, vazio, ritmo plano, níveis demasiado longos para mobile, custo de morte
  alto e "parece gerado". Qualquer prancha fica impossível de cumprir em layout.
- **Causa-raiz provável.** Em 3 set a campanha foi escalada para 100 níveis com um gerador
  *anti-softlock por construção*: espinha contínua, "nada bloqueia", líquido mortal por baixo de
  tudo. Esse contrato proíbe estruturalmente salas, chaves, backtracking e verticalidade real.
- **Sistemas afetados.** Level design, arte (as pranchas pedem arquitetura), combate (sem geometria
  de encontro), progressão (as habilidades não são chaves), técnico (reload por morte, monólito,
  RNG), áudio (hazards ouvidos de qualquer lado).

### P-2 · Não há pipeline de região: a arte (e a identidade) só chega onde houve código à medida — **P0**

- **Evidência.**
  - `plataforma.gd:40` tem 7 `BIOMAS` para 20 regiões; o terreno da R-II é "torres (recolorido)".
  - `atmosfera.gd:366` faz rodar 14 packs, contra a regra escrita em `afinar_atmosfera.py:128`.
  - A identidade regional é o `LUZ_REGIAO` (uma cor).
  - Das Regiões V–XX só existe uma `master_production_board.png` cada, que nenhuma ferramenta lê
    (A4 RC1/RC2).
  - A Região I tem ≈2 230 linhas de código visual dedicado; para a II–XX há um `tema_regiao.gd`
    genérico de 150 linhas (A8 RC2).
  - Nenhum dos ~150 inimigos das pranchas V–XX existe como sprite.
  - Hazards em `Polygon2D`: 77 scripts desenham em código.
  - A densidade de texel vai de 1:1 a 1:8.
- **Impacto.** Match visual NONE em 17 regiões. As mesmas nuvens aparecem nas XIV, XVI e XVIII, e o
  mesmo arco com trepadeira nas VII, XV, XVII e XX. É o que o GM viu.
- **Causa-raiz provável.** O passo **prancha → kit → dados de região** foi feito uma vez à mão para
  a Região I e nunca se tornou um contrato reutilizável (RegionKit).
- **Sistemas afetados.** Arte, inimigos, hazards, fundos, som ambiente, chefes/arenas.

### P-3 · O canon (15 set) nunca chegou às cenas; a campanha jogável é a de 3 set — **P0 (decisão do GM)**

- **Evidência.**
  - `estado_jogo.gd:165` (`REGIOES`) e os `world.*` seguem `plano_niveis_31_100.md`.
  - Só a R-II coincide no nome; das 14 regiões novas, 14 têm o tema errado (A4 RC3).
  - O Zeriko Final está no **N30** (canon: Mirage Eterna).
  - Os três "Zerikos" de pack estão nos N96–100.
  - Há 85 encontros `boss.*` para 20 chefes canónicos (A5 CR3).
  - O seletor mostra o "Guardião Verde" com arte `ghorak.png`, ao lado de outro nome.
  - As pistas dizem "Aurora"; a visão diz "Elara" (A7).
  - Os guardiões N1–N4 continuam a ser chefe obrigatório, contra a decisão do GM de 25/09 (A3 CR3).
- **Impacto.** Todo o conteúdo das regiões IV–XX está no tema errado. Produzir arte ou chefes agora
  seria produzir para a tabela errada. O clímax dilui-se porque cada nível acaba num chefe.
- **Causa-raiz provável.** A ordem temporal ficou invertida: primeiro o conteúdo e depois o canon,
  sem um passo de migração de dados.
- **Sistemas afetados.** Narrativa, arte, chefes, música (uma faixa por região na tabela antiga),
  UI (seletor, mapa) e i18n.

### P-4 · A progressão não tem estrutura: uma mecânica nova por nível, habilidades opcionais, recompensas invisíveis — **P0**

- **Evidência.**
  - `MECANICA_DO_NIVEL` dá **89 estreias em 96 níveis**. A estreia ocupa 14,5 % das câmaras e
    desaparece no nível seguinte (A3 CR3).
  - A dificuldade é `_dif = idx/29` linear, sem função Teach/Test/Combine/Challenge/Boss.
  - A Região I estreia 5 mecânicas diferentes (saltos, gruta, trampolim, espinhos, ritmo), nenhuma
    combinada.
  - Nenhuma habilidade é exigida no caminho crítico: `vao_possivel` só conhece salto
    simples/duplo, a `ParedeFragil` "NUNCA está no caminho" e as espectrais ficam sempre sólidas
    (A7 RC1).
  - Os N31–N62 e N64–N100 não dão nada de novo; o `pogo` não se ganha em lado nenhum.
  - Há 16 pickups de projétil duplicados.
  - A porta troca de cena no mesmo frame da recompensa: +Kolicoins, +1 vida e a arma ficam
    invisíveis.
  - A 1.ª arma **baixa** o dano de 50 para 48, e a 1.ª armadura não faz nada (A7 RC2).
  - O toast do salto duplo fica escondido atrás da placa de tutorial.
- **Impacto.** O jogador nunca domina nada e nunca sente "fiquei mais capaz, agora posso ir onde não
  ia". Os 100 níveis não formam um arco.
- **Causa-raiz provável.** A regra "cada nível estreia uma mecânica" (`mecanicas_por_nivel.md`)
  substituiu a pedagogia. Além disso, não existe um calendário de ferramentas como **dado**
  consumido pelo gerador e pelo modelo de alcance.
- **Sistemas afetados.** Level design, habilidades, economia, UI/toasts, fim de nível, narrativa.

### P-5 · O movimento da Koliani é correto mas inerte, e a animação de locomoção está desfasada da física — **P0**

- **Evidência (A1, medido por tick).**
  - **Salto.** 82,9 px = **1,3 H** de altura e 160 px de comprimento (Celeste ~2,5 hb). O
    `CORTE_SALTO 0.45` é aplicado **por tick** (≈5× a gravidade ao largar). Não há meia-gravidade
    no apex.
  - **Queda.** 1 100 px/s = 2,1 ecrãs/s, com a câmara a antecipar só ~65 px. Coyote efetivo de 4
    ticks.
  - **Animação.** O `land` dura **1 frame de render** (bug de fase entre `_process` e
    `_physics_process`). O `run_brake` usa **frames legados** e toca 0,3 s já parada. A viragem é
    um flip com pop de brake. Subir ao rebordo não tem animação. Há **seis a oito sistemas de rig**
    vivos no `koliani.gd`.
  - **Knockback.** Nenhum ao levar dano.
  - **Duas fontes de verdade para a velocidade.** Uma escrita externa é descartada: +20 px/s × 60
    ticks = 0 px.
- **Impacto.** "Pesa sem ser poderosa". As aterragens não têm peso, o dano não se sente no corpo e
  cada mecânica externa (íman, vento, trampolim) tem de descobrir um truque.
- **Causa-raiz provável.** A seleção de animação é **derivada** de flags noutro relógio, e não uma
  máquina de estados no tick de física. As constantes foram afinadas isoladamente, não em relação ao
  corpo desenhado nem ao ecrã.
- **Sistemas afetados.** Game feel, animação, câmara, combate (sem knockback), mecânicas de nível
  (forças externas), verificador de alcance.

### P-6 · Os inimigos são "movimento + corpo que magoa": sem ataque, sem papel, sem aggro — **P0**

- **Evidência (A2 RC1, censo dos 100 níveis).**
  - 7 comportamentos genéricos: `patrulha` 55,8 %, e **68 % não atacam**.
  - **Nenhum** tem hitbox de ataque e **nenhum** persegue.
  - A `especie` (34 peles) só escolhe sprite, som e tamanho; o comportamento é **sorteado à parte**
    (`gerador_corredor.gd:1797–1812`).
  - Na R-II há **0 voadores**: o bestiário aéreo aprovado anda a pé.
  - O telegraph é tinta a pulsar; a 0,1 s é indistinguível do idle.
  - A área de contacto (58×74) é maior do que o sprite (44×47).
  - A escala de dificuldade é só de **densidade**: 4 bichos no N1, 60 no N95.
- **Impacto.** Não há decisões de combate: o jogador salta por cima ou mata em 1–2 golpes. A
  variedade é visual, não mecânica. Os boards aprovados (torreta, arqueiro, mago que teleporta,
  mergulho) não existem.
- **Causa-raiz provável.** O modelo de inimigo nasceu como "obstáculo com vida" do gerador. Nunca
  houve um sistema de **kit por espécie** (movimento + 1–2 ataques + papel + aggro).
- **Sistemas afetados.** Combate, level design (encontros), arte (animações de ataque), áudio
  (vozes), dificuldade.

### P-7 · O modelo numérico está partido e congelado no índice 29 — **P0**

- **Evidência.**
  - `clampi(indice_nivel,0,29)` na vida e no dano dos comuns (`demonio_base.gd:381`), na vida e no
    dano dos chefes (`chefe_base.gd:232, 286`) e na essência dos chefes (`:474`) (A2 RC2, A5 CR2,
    A7 RC3).
  - Os comuns ficam em **81 HP/22 de dano do N30 ao N100**, enquanto a arma sobe de 50 a 200. A
    partir do N45 o golpe 1 mata qualquer comum sem crítico.
  - Nos chefes N31+ o contacto é **51, e 92 no golpe forte, contra os 100 de vida da Koliani**:
    morre em 2 toques.
  - A vida do N100 é **16 320** (> 200 s a 111 DPS).
  - O EXPOSTO foi cortado para 55 % em todos (janela de 0,42 s no N5).
  - Com o modelo de economia, as 6 melhorias ficam todas compradas por volta do N19 e ~90 % da
    Essência fica sem destino.
- **Impacto.** O combo de 4 golpes (atordoar no 3.º, sangrar no 4.º) nunca se exerce. O late game é
  ao mesmo tempo trivial (mobs) e injusto (chefes). A progressão de poder deixa de significar alguma
  coisa.
- **Causa-raiz provável.** Não há um **modelo de TTK por papel** nem uma **fonte única de
  dificuldade**. O gerador tem uma curva de 100 níveis (`_dificuldade`), mas os atores não a leem.
- **Sistemas afetados.** Combate, chefes, economia, equipamento, Santuário.

### P-8 · O kit da Koliani não tem custo nem legibilidade: estratégias dominantes e contacto que mente — **P1**

- **Evidência.**
  - **Tiro.** Ilimitado, 6,25/s, alcance de ~1 190 px (maior do que o ecrã). Aplica queimadura →
    vulnerável → crítico ×1,7. Kitar a 380 px matou todos os arquétipos terrestres com **0 de dano**
    (A2 RC3).
  - **Energia.** Regenera e nada a gasta (o Kamehameha foi removido). O upgrade "Focus" é inútil.
  - **Escudo.** Hold-block sem parry.
  - **Rolamento.** Encadeado dá 302 px/s, mais do que os 240 px/s da corrida, com 66 % do tempo
    invulnerável (A1 RC3).
  - **Dash.** Só horizontal e sem limite aéreo.
  - **Ataque.** Não prende o movimento: salta-se a meio do golpe.
  - **Legibilidade.**
    - A hitbox da espada chega 12 px para lá da lâmina desenhada.
    - O dano de contacto só entra no `body_entered`.
    - O flash de acerto tapa o alvo.
    - Hit-stop < 1,5 frame a 60 Hz.
    - A Koliani escura sobre fundo roxo-escuro perde contraste (A1 RC5, A2 RC4).
- **Impacto.** A espada fica opcional e o jogador "acerta sem tocar" e "leva no ar". No telemóvel o
  combate não tem peso.
- **Causa-raiz provável.** Os verbos foram acrescentados um a um sem uma economia de risco comum e
  foram afinados a 165 Hz no desktop, não no alvo mobile a 60 Hz.
- **Sistemas afetados.** Combate, movimento, UI (barra de Energia que "mente"), Santuário, VFX.

### P-9 · Dois jogos de chefes: 30 escritos à mão (3 no canon) e 70 que são o mesmo chefe — **P1** (com correções P0 baratas)

- **Evidência (A5).**
  - `ChefeGenerico` é uma máquina de estados de 4 fases; no N55 o ciclo é **fixo em 1,85 s**, sem
    variação.
  - Os projéteis "de identidade" disparam por um temporizador próprio, **sem telégrafo e durante o
    RECUPERA**.
  - Cinco scripts sobrepõem `_process` sem `super._process`: perdem a prisão à arena, a intro, a
    rede de queda e a animação de telégrafo.
  - Nenhum dos 70 chama `provocar()`, portanto não há barra nem música até levarem dano.
  - Rigs congelados em `attack` durante 19,4 s (Coração N5, Zeriko N30).
  - Escala 1,2–2,7× a Koliani, contra 2,6–4× nas pranchas.
  - O Guardião dos Céus tem 3 dos 8 ataques da prancha.
  - O Coração (clímax da R-I) tem **2 ataques alternados a relógio** e TTK de 10 s.
  - Só 4 chefes têm intro.
  - A única habilidade dada por um chefe é a do N5.
  - Visualmente, N40 = N90 e N85 = N95 (A4).
- **Impacto.** Os chefes leem-se como "inimigo grande", não como clímax. Nos N31–N100 há fogo sem
  aviso sobre números de fórmula.
- **Causa-raiz provável.** O chefe como *slot obrigatório de cada nível* (P-3), mais o esforço
  espalhado por 100 em vez de concentrado em 20.
- **Sistemas afetados.** Combate, arte, áudio (a mesma faixa por região e o mesmo gemido
  `mob_grande_dano` em todos), recompensa, narrativa.

### P-10 · Áudio sem direção nem arquitetura de mistura; a música "reinicia" a cada morte — **P1**

- **Evidência (A6).**
  - A música são **40 faixas Pixabay de ~35 autores**, sem motivo nem paleta comum. O centróide vai
    de 561 a 2 581 Hz. **Nenhuma é um loop**: 31/40 acabam em fade, com caudas até 9,9 s.
  - As regiões 2–20 partilham o `assombracao.wav` a −38 LUFS efetivos, ou seja inaudível.
  - Os buses são só Master → Music/SFX, sem compressor, limitador ou ducking.
  - O **−6 dB global no SFX** põe estes sons abaixo da música:

    | Som | Nível face à música |
    |---|---|
    | dash | −10…−14 dB |
    | telegrafo `raiz_aviso` | −15,5 dB |
    | desbloqueio de habilidade | **−23,5 dB** |

  - `esmagar.ogg` chega a +7,26 dBFS.
  - Zero `AudioStreamPlayer2D`: tudo é mono, e o fora-de-ecrã é um interruptor.
  - **Runtime:** no retry do chefe a música salta para a da região e o tema do chefe recomeça do
    início (14, 22 e 30 trocas em 45 s, no N8, N47 e N98).
  - Os 70 chefes genéricos não têm telegrafo sonoro.
- **Impacto.** As regiões não têm identidade sonora. O feedback de jogo fica mascarado. Os momentos
  de recompensa quase não se ouvem, e o retry do chefe é irritante.
- **Causa-raiz provável.** O som foi tratado como curadoria de ficheiros e afinado por callsite, sem
  alvo de mistura por categoria nem um estado de música por sessão.
- **Sistemas afetados.** Música, SFX, feedback de combate, telegrafos, chefes, UX da morte.

> Fora do top 10, mas reais: vidas que castigam sem explicar e chegam a 99 (A7 RC5); Novo Jogo
> que leva ao seletor e não ao N1; strings PT cruas na UI inglesa; zero acessibilidade; Veracoins e
> 9/10 itens da loja em placeholder; bots `XDG_DATA_HOME` que escrevem no save real no Windows
> (A8, STATIC); `perf_gate` com backup/reposição em vez de isolamento.

---

## 3. TOP 10 PONTOS FORTES — o que NÃO destruir

1. **A Koliani golden set.** Está ligada nas 100 cenas e é coerente, com rim magenta. A arte de
   roll, djump e dash é a melhor do pacote (A1, A4). É a âncora de identidade do jogo.
2. **O pipeline e o kit da Região I** (gate 9A–9H, kit_9c, panorama HD, inimigos e VFX 9G). É a
   **prova** de que a arte aprovada chega ao ecrã (A4, A8). Serve de modelo para o RegionKit, não
   para ser copiado 19 vezes.
3. **A física de chão e o módulo `Movimento`.** Latência 0, 0→máx em 7 ticks, buffer de 7 ticks,
   controlo no ar, um modelo único em todos os níveis, e é puro e testável (A1). Afina-se barato.
4. **A estrutura de combate da Koliani.** Frame data explícita por golpe, cancels para rolar e dash,
   buffer, a cadeia de 4 golpes com atordoar/sangrar, **status → crítico** e o tiro que marca
   (A2). Falta-lhe um adversário, não um desenho.
5. **O Vyrak (N15) como modelo de chefe.** Contrato → código fiel: 9 ataques por fase, telégrafo
   desenhado no sítio do impacto, EXPOSTO de 1,47 s com dano ×2 e ritual a 50 % (A5). O Guardião
   dos Céus examina a mecânica da região (vento). É esta a regra a generalizar.
6. **As "regras de bicho" e as janelas de castigo.** Incorpóreo só-tiro (N73), estátuas que só se
   mexem sem olhar (N68/74/89), divisão (N58), dormente (N21). Há leads de telegraph de 0,42–0,73 s
   e castigo pós-investida de 0,85 s (A2). São as únicas decisões verdadeiras no combate atual.
7. **O retry rápido, a fogueira como checkpoint e o save v5.** Controlo de volta em 0,47–0,81 s na
   R-I. O save tem schema versionado, migrações 0→5, temp+backup e IDs estáveis de checkpoint (A7).
8. **A fundação técnica e de medição.**
   - Geração determinística em 100/100 níveis e desempenho em regime permanente com p99 de
     6,6–12 ms (A8).
   - Manifesto de ownership e staging.
   - Bot, `verifica_alcance`, `camaras_do_nivel`, baseline de geometria.
   - Suite isolada por `correr_testes.ps1`.
   - Câmara sem jitter, com interpolação física estudada.
9. **A família sonora da Koliani (Shadowblade/Signature).** A cadeia ação→som está completa (0
   eventos sem som em 4 níveis), a aterragem tem 3 tiers, o combo tem 4 vozes, os acertos têm
   variantes, o pool tem prioridades e as licenças estão rastreadas por hash (A6).
10. **O design já pago.** As pranchas aprovadas das 20 regiões, com ~150 inimigos concebidos,
    `boss_pack` para II, III e IV e layouts. O catálogo de ~98 câmaras e dezenas de atores
    (sinos, vitrais, portal, gancho). **30+ pistas escritas em 6 línguas**. Menu e seletor com
    qualidade visual (A3, A4, A7, A8). O conteúdo de design existe; falta-lhe o caminho até ao jogo.

---

## 4. ART GAP REPORT

Base: A4 (160 capturas, janela real, zoom de jogo 1,4). As imagens de comparação põem a prancha
aprovada ao lado de 2 pontos do nível 2 e da arena do nível 5 de cada região. Estão em
`qa/global_audit/img/a4/cmp_regiao_XX.jpg`; a visão global está em
[`folha_20_regioes_jogo.jpg`](qa/global_audit/img/a4/folha_20_regioes_jogo.jpg) e em
[`folha_20_bosses_jogo.jpg`](qa/global_audit/img/a4/folha_20_bosses_jogo.jpg).

| Reg. | APPROVED (prancha / canon) | CURRENT (jogo) | GAP | VISUAL MATCH | Comparação |
|---|---|---|---|---|---|
| I | Floresta (canon "Sagrada", PNG "Corrompida"): pilares de rocha com musgo e raízes, folhagem carmesim, cristais, Heart Tree magenta, 4 moods por nível | Kit de produção correto em paleta e silhueta; Coração Putrefacto legível | Pêndulos `Polygon2D`, faixa do `LiquidoMortal` e chão cinzento de código, feto de pixel ×8, plataformas-pilar repetidas com o terço inferior vazio, Heart Tree e moods ausentes nos pontos capturados, 5 níveis na mesma noite azul | **HIGH** (ambiente) / **MEDIUM** (conjunto) | [cmp_regiao_01](qa/global_audit/img/a4/cmp_regiao_01.jpg) |
| II | Desfiladeiro dos Ventos: falésias, pontes com arcos, ilhas com rocha pendente, mar de nuvens, rajadas desenhadas, águia negra-roxa | Tijolo azul de masmorra ("torres recolorido") em lajes finas; fundo PROC de 240 px; N10 sobre-exposto a magenta; boss de polígonos azuis | Atlas de tiles, `level_assets`, elementos de vento, 4 layers de parallax e 8 poses/8 ataques do `boss_pack` por usar | **LOW** | [cmp_regiao_02](qa/global_audit/img/a4/cmp_regiao_02.jpg) |
| III | Torre dos Ecos: torre monumental dourada e azul, aquedutos, vitrais, sinos gigantes, Vyrak colosso de ~4× | Fundo PIL de 240 px com torres triangulares chapadas; lajes de tijolo a flutuar; Vyrak de trapézios com auréola a 2,66×; arena = laje | `asset_atlas`, `layout_usage` e `boss_pack` (poses e arena de fase 2) por usar; elevador de coluna não extraído | **LOW** | [cmp_regiao_03](qa/global_audit/img/a4/cmp_regiao_03.jpg) |
| IV | Fornalha: laranja e vermelho, lava, engrenagens, tubos, máquinas | Gruta preto-acinzentada (Szadi), caveira gigante, olho rosa redondo, cascata azul | Os 7 PNG aprovados por usar; a decisão do GM de 25/09 (prevalecem as pranchas) não foi executada | **NONE** | [cmp_regiao_04](qa/global_audit/img/a4/cmp_regiao_04.jpg) |
| V | Cidades Flutuantes: céu diurno azul e dourado, cidades brancas, Oráculo alado | Céu vermelho-sangue de pixel gigante, goblins verdes; boss Noiva do Eclipse | tudo | **NONE** | [cmp_regiao_05](qa/global_audit/img/a4/cmp_regiao_05.jpg) |
| VI | Deserto das Ilusões: dunas e catedrais soterradas, âmbar; Mirage Eterna | Interior de castelo roxo, arco lilás de pixel enorme; **Zeriko Final** no N30 com 2 plataformas | tudo + conflito narrativo | **NONE** | [cmp_regiao_06](qa/global_audit/img/a4/cmp_regiao_06.jpg) |
| VII | Jardins Envenenados: estufas góticas, rosas, água tóxica | Teal escuro, arcos de trepadeira em pixel gigante, pêndulos; boss laranja sobre magma | atlas de sebes/estufas, 12 inimigos, boss | **NONE** | [cmp_regiao_07](qa/global_audit/img/a4/cmp_regiao_07.jpg) |
| VIII | Catacumbas da Fome: ossários dourados, velas, Devorador | Teal-cinza vazio, rocha de gruta; demónio verde alado (= N90) | tudo | **NONE** | [cmp_regiao_08](qa/global_audit/img/a4/cmp_regiao_08.jpg) |
| IX | Abadia Afogada: gótico submerso, azul-petróleo | Tijolo azul, engrenagem laranja; mago azul | tiles náuticos, 6 inimigos, maré | **NONE** | [cmp_regiao_09](qa/global_audit/img/a4/cmp_regiao_09.jpg) |
| X | Biblioteca Proibida: estantes flutuantes, portais | Pinheiros-silhueta magenta, lajes castanhas; "homem de laranja" | livros-plataforma, portais, elite | **NONE** | [cmp_regiao_10](qa/global_audit/img/a4/cmp_regiao_10.jpg) |
| XI | Costa Afundada: recife bioluminescente, navios | Pântano verde-oliva; boss = rig `entrevane` da R-I | tudo | **NONE** | [cmp_regiao_11](qa/global_audit/img/a4/cmp_regiao_11.jpg) |
| XII | Terras Envenenadas: pântano ácido, moinhos | Teal vazio, fios; boss sobre nuvens rosa | tudo | **NONE** | [cmp_regiao_12](qa/global_audit/img/a4/cmp_regiao_12.jpg) |
| XIII | Torre Invertida: azul e dourado, lustres | Nuvens cor-de-rosa gigantes, rocha laranja; "olho" roxo | tudo | **NONE** | [cmp_regiao_13](qa/global_audit/img/a4/cmp_regiao_13.jpg) |
| XIV | Planícies Celestiais: branco e dourado, mármore | Nuvens verde-oliva de pixel gigante, abóboras | tudo | **NONE** | [cmp_regiao_14](qa/global_audit/img/a4/cmp_regiao_14.jpg) |
| XV | Laboratório Sombrio: tanques, alquimia | Os mesmos arcos da VII, tijolo castanho | tudo | **NONE** | [cmp_regiao_15](qa/global_audit/img/a4/cmp_regiao_15.jpg) |
| XVI | Cânion Sangrento: ravina vermelha, cascatas de sangue | As mesmas nuvens da XIV | tudo | **NONE** | [cmp_regiao_16](qa/global_audit/img/a4/cmp_regiao_16.jpg) |
| XVII | Jardim Onírico: lilás ao luar, estátuas | A sala de arcos da VII/XV; cavaleiro de fogo sobre vulcão | tudo | **NONE** | [cmp_regiao_17](qa/global_audit/img/a4/cmp_regiao_17.jpg) |
| XVIII | Cidade Caída: metrópole gótica em ruínas, colosso | As nuvens da XIV/XVI; boss = demónio do N40 | tudo | **NONE** | [cmp_regiao_18](qa/global_audit/img/a4/cmp_regiao_18.jpg) |
| XIX | Portal Dimensional: portais roxos, geometria impossível | Serras vermelhas em escada, cubos; boss = cavaleiro do N85 | tudo | **NONE** | [cmp_regiao_19](qa/global_audit/img/a4/cmp_regiao_19.jpg) |
| XX | Trono de Zeriko: cidadela magenta, lua negra, Zeriko de coroa | Sala de arcos pela 4.ª vez; N100 com **1 plataforma** e um humano genérico | tudo, incluindo o Zeriko | **NONE** | [cmp_regiao_20](qa/global_audit/img/a4/cmp_regiao_20.jpg) |

**Gaps transversais (todas as regiões):**

- **Densidade de texel.** Mistura de 1:1 a 1:8 (fundos de 240 px a escala 4,4–6), com a Koliani e o
  kit da R-I a 1:1. É o que mais faz o jogo parecer "montado com peças".
- **Hazards.** Em `Polygon2D`, sem região.
- **Arenas N35–N95.** O mesmo template de laje sobre `LiquidoMortal`.
- **Composição das plataformas.** Lajes finas a flutuar sobre um chão mortal. As pranchas pedem
  massa de chão, arcos e colunas.
- **Contraste.** Fraco entre a Koliani e o fundo (A1 RC5).

**Diagnóstico.** O gap é de **pipeline** (P-2) e de **canon** (P-3), não de talento nem de assets
CC0 em falta. A Koliani (**KEEP**) é o único elemento com match em todo o lado.

---

## 5. GAMEPLAY GAP REPORT — Koliani atual vs intenção aprovada vs benchmarks

A intenção aprovada vem da visão 1.0, do alvo "o mais próximo possível de Dead Cells" com temática
gótica e de acrobata, dos contratos da R-II/R-III e das decisões do GM de 25/09 sobre a R-I.

### 5.1 Movimento

| Aspeto | Koliani atual (medido) | Intenção | Benchmark | Gap |
|---|---|---|---|---|
| Chão | 240 px/s (5,5 hb/s), 0→máx em 7 ticks, latência 0 | seco, responsivo | Celeste 8,2 hb/s, ~0,09 s | ✔ seco; um pouco lento para o corpo |
| Salto | 1,3 H de altura, 2,5 H de comprimento; corte ×0,45 por tick; sem apex | acrobata gótica "poderosa" | Celeste ~2,5 hb, corte único + meia-gravidade no apex; Lost Crown com salto alto e flutuante | **grande**: pesa sem ser poderosa |
| Queda | 1 100 px/s, câmara +65 px | queda legível | Celeste ~0,9 ecrãs/s | **grande** (queda às cegas) |
| Verbos N1–N4 | correr, saltar, rolar | "introdução gradual à travessia" | Celeste: 1 verbo núcleo rico desde o 1.º ecrã; Lost Crown: dash cedo | **grande**: a região mais bonita é a mais pobre em movimento |
| Wall-kick | existe mas é escondido: direção para dentro + salto no mesmo tick, sem pose | — | Celeste 3 px de tolerância | médio |
| Borda | agarra sozinha e encrava (3 agarrões não pedidos no N1) | assistência | Dead Cells sobe ao segurar a direção | médio |
| Dash | só horizontal, sem limite no ar | — | Celeste 8 direções, 1 por salto | médio |
| Knockback | nenhum | dano sentido | HK/DC empurram | médio |
| Animação | land de 1 frame, brake legado, turn com pop, sem mantle | pixel-art "Dead Cells" | DC: anticipation/recovery desenhados por transição | **grande** |

### 5.2 Combate

| Aspeto | Atual | Intenção | Benchmark | Gap |
|---|---|---|---|---|
| Combo | 4 golpes com startup/active/recovery 3/5/3 … 6/6/4; cancel para rolar/dash; buffer | "fluidez Dead Cells" | DC: moveset por arma, recovery que compromete | ✔ estrutura; ✘ não há commitment (anda-se e salta-se a meio do golpe) |
| TTK | 1–2 golpes nos 100 níveis; 1 golpe a partir do N45 | o combo exercido (atordoar/sangrar) | DC: comum a meio do jogo leva 3–6 golpes | **crítico** |
| Recurso | Energia sem gasto; tiro grátis e dominante | Shadowblade roxa como identidade | Nine Sols: deflect → Qi → dano; DC: cooldowns e munição | **crítico** |
| Defesa | escudo hold sem parry; rolar com 100 % de i-frames | — | Nine Sols: parry com timing como centro | grande |
| Legibilidade | hitbox +12 px para lá da lâmina; contacto > sprite; flash que tapa; hit-stop < 1,5 f a 60 Hz | leitura clara em ecrã pequeno (visão 1.0) | DC 3–6 frames de hitstop; Nine Sols com telegraph colorido | grande |

### 5.3 Inimigos

| Aspeto | Atual | Intenção (boards II–IV e V–XX) | Benchmark | Gap |
|---|---|---|---|---|
| Papel | 7 comportamentos sorteados, 68 % sem ataque, 0 com hitbox de ataque, 0 com aggro | 10 criaturas por região com verbo de ataque (torreta, arqueiro, mago que teleporta, mergulho, AoE) | DC: papel + ataque assinado + aggro | **crítico** |
| Variedade | 34 peles × 7 scripts; 5–10 peles por região | bestiário regional | HK: fauna própria por zona | **crítico** fora de I–III |
| Telegraph | tinta a pulsar; sem animação de ataque (só 5 espécies da R-II têm `ATAQUE_FRAMES`) | poses de ataque nas pranchas | Nine Sols: animação dedicada + cor | grande |
| Escalada | densidade de 4 → 60 por nível | problemas novos por região | Celeste teach→combine; DC elites com modificadores | **crítico** |
| Encontros | `3+4·dif` inimigos espaçados por igual numa laje | — | DC: composições que obrigam a priorizar | grande |
| O que já funciona | leads de 0,42–0,73 s, janelas de castigo, regras de bicho | — | — | preservar |

---

## 6. SYSTEMS GAP REPORT — existe, mas é superficial, redundante ou pouco aproveitado

| Sistema | Estado | Classificação | Evidência | Ação |
|---|---|---|---|---|
| **Habilidades** (9) | Existem e funcionam, mas nenhuma é exigida; `pogo` nunca se dá; 16 pickups de projétil; nada de novo em N31–N62 nem N64–N100 | **pouco aproveitado** | A7 RC1 | REBUILD: `ABILITY_SCHEDULE` como dado + modelo de alcance com ferramentas + câmaras obrigatórias |
| **Energia** | Barra visível, sem consumidor | **superficial (UI que mente)** | A2 RC3 | PARTIAL REWORK: o tiro gasta, o parry devolve, o especial é o sumidouro |
| **Escudo** | Hold-block, sem parry | superficial | A2 | PARTIAL REWORK (parry) |
| **Status/críticos** | Bom sistema (queimar/sangrar/atordoar/gelar → vulnerável ×1,7), mas o tiro deixa tudo sempre a arder | **anulado por outro sistema** | A2 §7 | KEEP + dar custo ao tiro |
| **Equipamento** | 20 armas + 10 armaduras = escada de números auto-equipada; 1.ª arma < base; armadura inicial nula; sem visual no boneco | superficial | A7 RC2 | PARTIAL REWORK: ~10 armas com 1 traço cada |
| **Essência / Santuário** | 6 melhorias esgotadas por volta do N19; ~90 % da Essência sem destino; vende melhorias de habilidades que ainda não se têm | superficial | A7 RC3 | MAJOR REWORK: árvore ligada às habilidades até ao N100 |
| **Kolicoins / Veracoins / loja** | 3 moedas para 2 sumidouros; 9/10 itens placeholder; Veracoins sem pagamento; cosméticos sem efeito | **redundante** | A7 RC3 | 1 moeda de jogo; esconder a loja até haver conteúdo |
| **Vidas** | +1 por nível, até 99; sem vidas → volta ao início do nível **sem mensagem** | redundante e castigador | A7 RC5 | REBUILD pequeno: a fogueira como único contrato |
| **Pistas / Diário** | 30+ pistas escritas em 6 línguas, sistema dormente; nome "Aurora" | **pouco aproveitado** (melhor texto do jogo) | A7 RC4 | PARTIAL REWORK: coletáveis de exploração ligados às habilidades |
| **Diálogo** | Funciona sem pausar, mas só 4 chefes têm intro | pouco aproveitado | A5 CR5 | TUNE: intro em todos os regionais |
| **Placa `mec.*`** | Boa; entra em conflito com o toast de habilidade (fila de slot único) | OK com defeito | A7 | TUNE (prioridade) |
| **Fim de nível / região** | Troca de cena no mesmo frame da recompensa; não há momento de região | **ausente** | A7 RC2 | PARTIAL REWORK: ecrã ≤ 4 s |
| **Seletor / mapa** | Visualmente bom; sem razão para voltar a um nível (sem segredos, tempo ou "precisa de X"); Novo Jogo cai aqui | pouco aproveitado | A7 §7 | TUNE |
| **Opções / acessibilidade** | Só volume e idioma | ausente | A7 | TUNE (P2) |
| **Hardcore** | Fora do scope 1.0, mas com código e campos no save | **redundante (morto)** | A7, visão 1.0 | cortar (P3) |
| **Rigs da Koliani** | 5 rigs × 3 variantes = 8 combinações, 7 mortas; ≈1,8 MB de pastas | redundante | A1 RC1, A8 | remover depois da máquina de estados |
| **Música dinâmica** | `intensificar()` sai sempre cedo; `PITCH_BIOMA` sem uso; 40 `.ogg` de reserva | morto | A6 | limpar (P3) depois do novo desenho |
| **Espacialização** | Gate on/off `toca_actor`; mecanismos com `Som.toca` audíveis em qualquer lado | superficial | A6 R3 | PARTIAL REWORK |
| **Dificuldade** | Três curvas que não se falam: `_dif` do gerador (100 níveis), clamp 29 nos atores, `ALIVIO_R1` | **fragmentado** | A2, A5, A7 | 1 fonte única por índice + modo assistido |

---

## 7. LEVEL DESIGN GAP REPORT

| Dimensão | Estado medido | Benchmark | Gap | Ação |
|---|---|---|---|---|
| **Repetição** | ~81 % dos atores de enchimento são 6 tipos; serra em 87 níveis, pêndulo em 90, fogo em 85 via `_perigo_no_vao` universal; Jaccard de 0,46; a mesma "fila de plataformas equidistantes sobre líquido mortal" na Floresta, na Torre, no Gelo e no Vazio (`img/a3/n01_01`, `n11_03`, `n045_01`, `n090_02`) | HK/Celeste: vocabulário próprio por zona | **crítico** | Kit de perigos **por região**; eliminar o fallback universal |
| **Proceduralidade** | 96 níveis jogam com jornada; ≥ 90 % gerado a partir da R-III; N31–N100 com 450 px de sala à mão; identidade do nível = `_idx % 3`, `(_idx/2) % 4` | DC: gera o *grafo*, desenha as *salas* | **crítico** | REBUILD: nível = sequência de salas autorais (ou salas-peça por bioma); o gerador só monta/varia; `corredor=false` por omissão |
| **Ritmo** | A mesma curva de 3 atos em 97 níveis; câmaras a cada ~1 700–2 000 px; 36,3 % `descanso`; `descanso→descanso` em 66 níveis | Celeste: sala de 5–20 s com 1 ideia | **crítico** | 4–8 salas por nível; o descanso só onde o ritmo pede |
| **Duração** | N11 4,5–9 min só de jornada (bot); N29 ≈ 185 s só a correr; contrato: 1–3 min | mobile: 1–3 min | **crítico** | Tabela de duração-alvo 60–180 s por nível |
| **Custo de morte** | Checkpoints a 2 800–3 700 px sobre líquido mortal em todo o lado; até 15–60 s de percurso refeito | Celeste: 1–10 s | **crítico** | Checkpoint à entrada de cada sala de desafio |
| **Teaching** | 89 estreias em 96 níveis; mecânica de 1–4 câmaras e depois desaparece; R-I com 5 mecânicas soltas; a mecânica canónica da R-I (raízes) só em "toque" no N1 | Celeste: 1 mecânica por capítulo em 20–40 salas | **crítico** | 1 mecânica (máx. 2) por região, com papéis N1 ensina · N2 testa · N3 combina · N4 desafia · N5 exame+boss |
| **Escalation** | `_dif = idx/29` linear; atores congelados no idx 29; escalada por densidade | arco por região | grande | Fonte única de dificuldade + arco regional |
| **Challenge** | 37–40 % das subidas a ≤ 8 px do limite físico a partir do N6; R-III começa a 90 px do líquido com degraus de 104 px (pico de exigência aos 5 s); N5 "ritmo" com períodos aleatórios (não se aprende); N4 calha baixa de espinhos sem aviso | Celeste: relógio global nos blocos temporizados; a armadilha lê-se | grande | TUNE de regras: 1.º salto ≤ 70 % do envelope; relógio partilhado; rota-armadilha telegrafada; playtest humano dos 4 candidatos |
| **Exploração** | Só a `forquilha` volta a juntar-se em 3 plataformas; `segredo` sempre com o mesmo gabarito; habilidades não abrem caminhos; as pranchas R-III pedem 2–4 segredos por nível | Lost Crown / HK: ferramentas reabrem sítios | grande | Rota crítica + opcional por sala; segredos por leitura; portas de habilidade leves; pistas como prémio |
| **Identidade regional** | Só N8 (planar) e N10 da R-II seguem a prancha; R-IV com mecânicas de Catacumbas legadas; VII–XX são placeholder procedural | HK: área = mecânica + fauna + som | **crítico** | Mecânica-assinatura regional + RegionKit |
| **Preservar** | Contrato de salto simples da R-I (caminho crítico N1–N5 ≤ 88 px); N1/N2 como escala certa (jornada de 11–22 s, bot normal conclui o N1 em 103 s); N8 como modelo de sala à mão; biblioteca de ~98 câmaras | — | — | KEEP como regras e peças |

**Problema maior.** O gerador contínuo *anti-softlock* é o esqueleto de 96 níveis (P-1). A
repetição, a duração, o ritmo, o custo de morte e a falta de teaching são consequências dele e da
regra "uma mecânica nova por nível".

---

## 8. BOSS GAP REPORT

Fontes: A5 (lutas medidas), A4 (arte/arenas) e o mapa nível → script confirmado por grep às cenas.
O canon pede 20 chefes regionais (N5, N10, …, N100).

### 8.1 Chefes regionais escritos à mão (individualmente)

| N | Chefe | Canon? | Medido | Gap | Ação |
|---|---|---|---|---|---|
| 5 | **Coração Putrefacto** | ✔ (decisão do GM de 25/09; `KOLIANI_REGION_CANON.md` ainda diz Guardião Verde) | 1 059 HP, contacto 25, **2 ataques alternados a relógio (período 4,0 s)**, TTK 10 s, rig congelado em `attack` 19,4 s, EXPOSTO 0,42 s, entrada muda; dá o salto duplo (toast escondido) | o chefe mais pobre das 3 regiões aprovadas, no clímax da região de referência; boa arte 9D | **PARTIAL REWORK** (4–5 ataques, 2 fases, intro, loops, EXPOSTO próprio, cerimónia da habilidade). **Central no vertical slice** |
| 10 | **Guardião dos Céus** | ✔ | 1 996 HP, 3 ataques (lâmina/queda/vento), ciclo de ~9 s, 1,86× (contrato: ~170 px); examina o vento; tem intro e fim | 3 de 8 ataques da prancha; rig de polígonos azuis contra uma águia de penas | PARTIAL REWORK (escala, +5 ataques, arte do `boss_pack`) |
| 15 | **Vyrak** | ✔ | 3 019 HP, 9/9 ataques (7 vistos + ritual a 50 %), EXPOSTO 1,47 s ×2, TTK 20,5 s, telégrafo no sítio do impacto | escala 2,66× contra ~4×; trapézios contra colosso de ouro e sinos; ataca 5× antes de `combate_iniciado`; arena = laje | **KEEP o design**, PARTIAL REWORK na arte, escala, arena e `provocar()` |
| 20 | Olho do Abismo | ✘ (canon: Guardião da Fornalha) | 2 974 HP, contacto 38, 1,96×; padrões STATIC | tema e boss errados | REBUILD a partir do `boss_pack` da R-IV |
| 25 | Noiva do Eclipse | ✘ (canon: Oráculo do Vento) | 3 710 HP, 3 padrões, TTK 40,3 s, com intro | tema errado; TTK alto para 3 padrões | REBUILD (canon) |
| 30 | **Zeriko Final** | ✘ **(canon: Mirage Eterna; o Zeriko é no N100)** | 5 760 HP, 4 formas / 8 ataques, TTK 62 s, com intro; **congelado em `attack` 19,4 s**; arena de 2 plataformas | o chefe mais rico do jogo está no sítio errado da narrativa | **Decisão do GM**: mover e reaproveitar como base do N100 |

### 8.2 Guardiões escritos à mão (N×1–N×4 das Regiões I–VI) — por família

| Família | Níveis → chefe | Estado | Ação |
|---|---|---|---|
| **R-I, guardiões obrigatórios** | N1 Ghorak · N2 Morvanna · N3 Rainha Aracnídea · N4 Entrevane | Ghorak: 416 HP, 4,2 s, 1,18× (medido); bot: 37 mortes no guardião do N1 (casual) e o N2 decidido pela Morvanna. **Contra a decisão do GM de 25/09** (N1–N4 não são boss levels) | Rebaixar a elites/mini-bosses opcionais ou de sala; o Ghorak é candidato a mini-boss do vertical slice |
| **R-II, legado da Prisão reskinned** | N6 Carcereiro · N7 Ignivar · N8 Dama Guilhotina · N9 Irmãos Condenados | Nome e pele mudaram (`golem_falesias`, `vigia_desfiladeiro`); os padrões (salto+onda, martelo, guilhotina) continuam os da prisão. STATIC | Rebaixar a elites com kit da região (vento) |
| **R-III, legado** | N11 Sino Vivo · N12 Aerion · N13 Voltaris · N14 Sacerdotisa Lunar | Escritos à mão para a campanha antiga (Aerion = "legado", segundo `retomar_aqui`). STATIC | Idem |
| **R-IV a R-VI, legado 30 níveis** | N16 Rei Ossário · N17 Colosso Ósseo · N18 Freira Negra · N19 Naga Zeraph · N21 Prefeito Sem Rosto · N22 Açougueiro Real · N23 Maquinista Infernal · N24 Bispo Púrpura · N26 Capitão Negro · N27 Koliani Sombria · N28 Rei Devorador · N29 Arauto de Zeriko | Esquema DECIDE/TEL/EXPOSTO com 2–4 ataques; temas da tabela antiga. STATIC | Material reaproveitável como elites. A **Koliani Sombria** (espelho) tem valor narrativo próprio e deve ser avaliada pelo GM |

### 8.3 Chefes genéricos N31–N100 (`ChefeGenerico`, 70) — por família

Todos partilham: ciclo fixo `APROXIMA → TELEGRAFO → ACAO → RECUPERA` (1,85 s no N55); fase 2 =
velocidade ×1,3; sem `provocar()`; contacto 51 e 92 no golpe forte contra os 100 de vida da
Koliani; multiplicadores presos ao idx 29; arenas no mesmo template de laje sobre `LiquidoMortal`;
som por arquétipo e o mesmo `mob_grande_dano`; rigs de packs reciclados (22 rigs para ~50 chefes:
`cavaleiro_fogo` ×6, `cavaleiro_negro` ×5…).

| Família (script) | Níveis | Particularidade medida | Defeito específico |
|---|---|---|---|
| **Vulkar** | N31 | investida + brasas; **1 288 de dano em 20 s parada** (14 golpes) | contacto 92; degrau de vida N30 5 760 → N31 1 536 |
| **Elemental** | N32–N34 | projéteis por temporizador | `_process` sem `super` |
| **Oceânico** | N35–N37 | feixe + onda (N35: 3 072 HP, TTK 28,9 s) | idem; projéteis sem telégrafo, também no RECUPERA |
| **Genérico puro** | N38–N40 | arquétipo só | N40 = N90 visualmente |
| **Glacial** | N41–N45 | feixe + runa (N45: 3 840 HP, 35,9 s) | `_process` sem `super` |
| **Deserto** | N46–N50 | salto + órbita (N50: 4 224 HP, 39,7 s) | idem |
| **Lore** (50 chefes) | N51–N100 | 1 de 4 modos de projétil por `hash(forma) % 4`, dano 18; runa de "telégrafo" noutro relógio; dispara desde que o nível carrega (N55 5 088 HP; N75 9 312; **N100 16 320, > 200 s**) | N100 "Zeriko, o Homem" = `cavaleiro_negro` de pack num tabuleiro de musgo, com 1 plataforma. **O final do jogo é uma parede de contacto** |

**Correções P0 baratas, independentes do rebuild:** `super._process()` nos 5 scripts;
`provocar()` à vista; projéteis só dentro da ACAO; teto de contacto (≤ 25–30 % da vida da Koliani);
loop/regresso a idle nos rigs.

**Estrutural (depende da decisão do GM):** 20 chefes regionais com script próprio (modelo Vyrak) que
**examinam a mecânica da região**, e os restantes 80 encontros rebaixados a guardiões/elites/salas
de desafio. Isto reduz o trabalho de 85 chefes para ~17 novos e devolve peso ao clímax.

---

## 9. "WHAT MAKES KOLIANI KOLIANI?" — pilares próprios a reforçar

Não é "ser como Dead Cells". São estes os traços que já existem em embrião e que nenhum dos
benchmarks tem nesta combinação:

1. **A acrobata gótica de 16 anos.** Movimento alto, elegante e rápido: roll, djump e dash golden são
   o melhor que existe. O corpo tem de *parecer tão poderoso como é desenhado* (2 H de salto, dash
   de 8 direções, mantle, pogo). O movimento é a primeira fonte de expressão, antes do combate.
2. **A Shadowblade roxa: marcar → executar.** O tiro marca (status), a espada executa (crítico), e a
   Energia liga as duas. Somado a um parry que devolve Energia, dá um ciclo "aparar → carregar →
   marcar → executar" que é da Koliani: é o deflect→recurso do Nine Sols com o status→crítico do
   Dead Cells, mas com uma cor e um som próprios (família Signature).
3. **Luar e corrupção.** Gótico, luar, brilho magenta/roxo contra carvão e carmesim (key art, R-I,
   frontend 9H). A corrupção de Zeriko é a *contra-assinatura* (visual e sonora) que invade cada
   região. A identidade visual é um conflito de duas luzes, não uma paleta.
4. **Cada região é um problema, não uma cor.** Uma mecânica-assinatura por região (raízes, vento,
   ecos/sinos, calor/pressão…), ensinada, combinada e **examinada pelo chefe** (como o GdC já faz
   com o vento e o Vyrak com os sinos). O chefe é o exame final da região, não "mais vida".
5. **Bestiário com regras.** Inimigos que mudam *como* se resolve e não *quanto* se bate: incorpóreo
   só-tiro, estátuas que só se mexem sem olhar, divisão, emboscada. Um papel e um ataque por espécie,
   saídos das pranchas.
6. **Ecos: o passado que volta.** O canon da R-III ("cada nível é um eco") dá uma estrutura barata e
   própria: a mesma sala visitada duas vezes (antes/depois), o som como mecânica e o leitmotivo que
   regressa distorcido.
7. **Leitmotivo Koliani / mãe / Zeriko.** Um motivo de 5–7 notas no menu, citado e corrompido ao
   longo da campanha e invertido no final. A trilha passa a contar a história que as pistas escritas
   já contam.
8. **Memória da mãe como exploração.** As 30+ pistas escritas como fragmentos de memória atrás de
   habilidades: a exploração tem um *porquê* narrativo, não só Essência.
9. **Campanha por níveis, curta e mobile.** Níveis de 1–3 minutos, retry instantâneo, a fogueira
   como único contrato e um seletor que mostra "precisa de Wall Climb". Não é roguelite nem
   metroidvania: é a clareza do Celeste com a caixa de ferramentas da Lost Crown, num telemóvel.

---

## 10. RECOMMENDED REBUILD STRATEGY

### 10.1 Princípios

- **Não multiplicar antes de provar.** Nada nas regiões IV–XX até o slice passar a barra. A
  renovação "região a região em cima do gerador" (R-II e R-III) ficou em fidelidade LOW, por isso o
  método tem de mudar antes de se voltar a gastar tempo em conteúdo.
- **As bases vêm primeiro, o conteúdo depois.** Movimento, números, kit de inimigo, pipeline de
  salas, RegionKit e mistura são pré-requisitos de *qualquer* região.
- **Preservar** os 10 pontos fortes da §3. Os IDs, os saves e o determinismo mantêm-se (visão 1.0).
- Não há roadmap dos 100 níveis: o âmbito do Conteúdo decide-se depois da Validação, com o custo real
  por região medido.

### 10.2 Sequência e dependências

```
DECISÕES DO GM (canon) ─┐
                        ├─► FOUNDATION ─► VERTICAL SLICE (R-I) ─► VALIDATION ─► REGION PIPELINE (R-II) ─► CONTENT ─► POLISH
quick wins P0 (paralelo)┘       ▲                                     │
                                └────────── volta se a barra falhar ◄─┘
```

| Fase | O que entra | Depende de | Critério de saída (quality bar mensurável) |
|---|---|---|---|
| **0. DECISÕES** | Tabela única região → tema → mecânica → chefe (canon de 15 set); N30/Zeriko; 20 regionais vs 85; Aurora/Elara; nome da R-I; guardiões N1–N4; música; vidas; moedas; âmbito da 1.0 | — | Documento de decisões assinado pelo GM; `KOLIANI_REGION_CANON.md` atualizado (Coração Putrefacto) |
| **0b. Quick wins** (paralelo, baratos, não se deitam fora) | `super._process` nos 5 chefes; `provocar()`; teto de contacto; estado de música por sessão (retry sem ping-pong); stinger de habilidade/dash/telegrafo na tabela-alvo; 1.ª arma ≥ base; toast com i18n, ícone e prioridade; strings PT cruas → `Textos.t`; esconder botões sem habilidade; isolar os bots `XDG_DATA_HOME` e o `perf_gate` do save real | — | Cada item com teste ou harness; save real intacto (SHA) |
| **1. FOUNDATION** | **(a) Movimento:** máquina de estados de animação no tick de física com duração mínima por estado; frames golden de land, brake, turn e mantle; salto ~2 H com corte único e meia-gravidade no apex; queda ≤ 650–750 px/s (ou fast-fall); coyote de 6 ticks; knockback; 1 dono da velocidade + acumulador de forças; rolar < correr; dash de 8 direções, 1 no ar; remover rigs mortos. **(b) Números:** TTK-alvo por papel (fodder 2–3, soldier 4–6, elite 10+ golpes normalizados); fonte única de dificuldade por índice (fim do clamp 29); poise nos pesados. **(c) Kit de inimigo:** espécie = movimento + 1–2 ataques com hitbox + antecipação animada + recovery + aggro + papel; contacto só residual e ≤ sprite. **(d) Economia do kit:** o tiro gasta Energia, o parry devolve, o especial é o sumidouro. **(e) Pipeline de nível:** `corredor=false` por omissão; nível = lista de salas (cenas pequenas) declarada na cena/manifesto; semente por sala; respawn sem `reload_current_scene`; checkpoint por sala. **(f) RegionKit** como recurso de dados (terreno 5 camadas, 4 layers de parallax, 8–12 props, 3–5 hazards com sprite, 4–6 inimigos, boss + arena, ambiente, tema), extraído do código da R-I; 1 densidade de texel. **(g) Áudio:** buses por categoria + limitador + side-chain; tabela-alvo por categoria normalizada na fonte; `toca_actor` com pan e atenuação | Fase 0 (a/b/c não dependem do canon; e/f sim) | Arena de teste + testes: salto 125–135 px; `land` visível ≥ 4 ticks em 100 % das aterragens; 0 frames legados; rolar encadeado < 240 px/s; velocidade externa preservada; TTK medido por papel dentro do alvo ±1 golpe do N1 ao N100 (tabela); kiting a 380 px **não** mata sem sofrer dano; hitbox ±4 px da lâmina desenhada; hit-stop ≥ 2 frames a 60 Hz; respawn ≤ 0,5 s em qualquer nível; SMR hit/dano/telegrafo ≥ 0 dB; 0 picos > −1 dBTP no Master |
| **2. VERTICAL SLICE** | Ver 10.3 | Foundation completa | Ver 10.3 (barra do slice) |
| **3. VALIDATION** | Playtest humano (Paulo, Luís e ≥ 3 externos); **telemóvel real** (Android + Safari/PWA); gravação de mortes por sala e tempos; comparação lado a lado com Celeste Cap. 1 e Dead Cells (bioma 1) | Slice | GM aprova o slice como **padrão**; tempo por nível dentro de 60–180 s para jogador médio; nenhuma sala com > 10 mortes medianas sem ser desafio declarado; 60 fps estáveis no dispositivo alvo; checklist de áudio humano passado. Se falhar, volta-se à Foundation/Slice |
| **4. REGION PIPELINE** | Industrializar: aplicar o método à **Região II** (tem boards, atlas, `boss_pack`, N8/N10 à mão e 5 espécies extraídas); medir o custo real prancha → kit → salas → bestiário → chefe → som | Validation | R-II ao **mesmo nível de barra** que a R-I, **sem nenhum `if _regiao == N` / `if _idx == N`** no código partilhado; custo por região registado; R-II match visual ≥ MEDIUM-HIGH |
| **5. CONTENT** | Regiões por ordem de campanha (III, IV, …), com âmbito decidido pelo GM face ao custo medido; os 80 encontros não regionais passam a elites/salas de desafio | Region Pipeline | Cada região: match ≥ HIGH; 1 mecânica ensinada → exame; chefe regional ≥ barra do slice; bestiário da prancha com papel |
| **6. POLISH** | Acessibilidade, leitmotivo e camadas musicais, silêncio intencional, cosméticos, segredos, afinação global da dificuldade | Content | Critérios de release 1.0 |

### 10.3 VERTICAL SLICE / QUALITY TARGET — Região I: **N1 "Floresta Putrefata" + N5 "Coração da Floresta"**, com o Ghorak como mini-boss

**Porquê a Região I, e não a II ou a III.**

- É a única região com **kit de produção aprovado** (arte, Koliani golden, inimigos de produção, VFX
  9G). O slice pode medir o *game design* sem ficar à espera de produzir arte.
- A visão 1.0 já a declara "a primeira Vertical Slice".
- O GM fechou a estrutura dela a 25/09: N1 intro · N2 test · N3 combine · N4 desafio · N5 exame+boss;
  chefe = Coração Putrefacto.
- É onde se decide a primeira impressão, e é hoje a região **mais pobre em movimento** (3 verbos) e
  com o chefe regional mais fraco (2 ataques, 10 s). Se o método funcionar aqui, funciona onde há
  menos a salvar.
- A R-II fica guardada para a fase 4, justamente para testar a *industrialização* numa região que
  ainda não tem kit completo.

**Porquê N1 + N5 (e não os 5 níveis).** Juntos cobrem as duas pontas da pedagogia: *ensinar* e
*examinar*. Pedem todos os sistemas e mantêm o slice pequeno. Os N2–N4 constroem-se na fase 5 com o
mesmo método.

**Conteúdo do slice.**

| Elemento validado | Como entra no slice | Barra mensurável |
|---|---|---|
| **Koliani / movimento** | Foundation (a); no N1, o wall-kick e o mantle ensinados por espaço; decisão do GM sobre antecipar o dash (N1/N2) | Números da Foundation; 0 agarrões não pedidos no percurso; land/brake/turn/mantle com arte golden |
| **Combate** | Combo, tiro com custo de Energia, parry, knockback | Cada inimigo morre no TTK-alvo do papel; o combo 3.º/4.º exerce-se contra o soldado; nenhuma estratégia de 0 dano |
| **Câmara** | Zonas por sala e enquadramento fixo na arena; antecipação vertical | Em queda máxima, o chão fica visível ≥ 0,6 s antes do impacto; arena sem mostrar "fora do mundo" |
| **Arte** | Kit da R-I completo: hazards com sprite (fim do `Polygon2D`), líquido e chão com arte, Heart Tree visível no N5, 1 densidade de texel, moods diferentes no N1 e no N5 | Match **HIGH** no conjunto (não só no ambiente); 0 elementos PROC/LEG no ecrã; contraste da Koliani legível em todas as salas (captura em telemóvel) |
| **Inimigos** | 3–4 espécies da R-I com papel (fodder, soldier, voador/ranged) + 1 elite + 1 "regra de bicho", pelo kit de inimigo | 100 % com ataque, antecipação animada e aggro; telegraph distinguível do idle a 0,1 s |
| **Mecânica regional** | **Raízes que irrompem** como mecânica da região: ensinada em segurança no N1 e examinada no N5, combinada com o salto duplo | Aparece em ≥ 60 % das salas do N1 e em 100 % do exame; nenhuma outra mecânica nova estreada |
| **Mini-boss** | **Ghorak** rebaixado a mini-boss de sala no N1 (ou no N3), já não guardião obrigatório da porta (cumpre a decisão do GM) | 2–3 ataques com telégrafo por pose e som; TTK 10–15 s |
| **Boss** | **Coração Putrefacto** refeito: 4–5 ataques, 2 fases com vocabulário novo, telégrafo por golpe (pose + som), EXPOSTO próprio (≠ `hit`), escala e arena da prancha, intro e nome no ecrã; examina as raízes; entrega o salto duplo com cerimónia | TTK de 25–40 s para um jogador real; contacto ≤ 25–30 % da vida; 0 frames congelados; música de chefe sem reinício no retry |
| **Level design** | N1 e N5 como sequências de 4–8 salas autorais, sem jornada | Tempo de 60–180 s (jogador médio); retry ≤ 10–15 s de percurso; ≥ 1 rota opcional + 2 segredos por nível (um deles uma pista/memória) |
| **Áudio** | Buses e mistura da Foundation; ambiente da floresta audível; cama em loop real + tema do chefe com variação por fase; telegrafos audíveis | Loops sem buraco (0 gaps < −40 dB > 50 ms); SMR do feedback ≥ 0 dB; stinger de habilidade audível; escuta humana aprovada |
| **UI / progressão** | Novo Jogo → intro curta → N1; ecrã de fim de nível e de região; toast de habilidade com instrução; HUD sem botões mortos; fogueira como contrato (decisão sobre as vidas) | Novo Jogo → controlo no N1 em ≤ 2 inputs; recompensa visível em 100 % dos ganhos; 0 strings cruas |
| **Técnico** | Respawn sem reload; salas com semente própria; save compatível | Respawn ≤ 0,5 s; 60 fps no dispositivo alvo; suite verde; save real intacto |

### 10.4 Anexo A — MATRIZ DE QUALIDADE

| Área | CURRENT STATE | WHAT WORKS | WHAT DOES NOT WORK | BENCHMARK GAP | KOLIANI OPPORTUNITY | ACTION | P |
|---|---|---|---|---|---|---|---|
| **Movement** | Física de chão seca, salto de 1,3 H, queda de 1 100 px/s | latência 0, 7/7/11 ticks, buffer 7, controlo no ar, modelo único | salto curto, corte por tick, sem apex, rolar > correr, sem knockback, 2 fontes de velocidade | Celeste/Lost Crown: salto alto com apex e verbos ricos cedo | acrobata gótica: dash de 8 direções, pogo, mantle | **PARTIAL REWORK** (tune + estados) | P0 |
| **Platforming** | Envelope de salto respeitado na R-I; 37–40 % das subidas no limite a partir do N6 | contrato de salto simples na R-I | precisão máxima sobre morte instantânea; ritmo aleatório no N5; armadilhas sem leitura | Celeste: 1 ideia por sala, relógio global | ecos (salas revisitadas), raízes/vento como problemas | **MAJOR REWORK** (salas autorais) | P0 |
| **Combat** | Combo de 4 golpes com frame data e cancels; TTK 1–2 | estrutura, cancels, buffer, status → crítico | sem commitment, tiro dominante, Energia sem uso, sem parry, hitbox > lâmina | DC (moveset/commitment), Nine Sols (deflect → recurso) | marcar → executar com Energia | **PARTIAL REWORK** | P0 |
| **Enemies** | 7 comportamentos sorteados, 68 % sem ataque, 34 peles | leads de 0,42–0,73 s, castigos, regras de bicho | sem hitbox de ataque, sem aggro, sem papel; escala por densidade | DC: papel + ataque assinado | bestiário das pranchas + regras | **MAJOR REWORK** | P0 |
| **Bosses** | 30 à mão (3 no canon) + 70 genéricos | Vyrak, GdC, infraestrutura `ChefeBase` | ciclo de 1,85 s, fogo sem telégrafo, clamp 29, escala 2×, anims congeladas, 85 contra 20 | HK/Nine Sols: 3–6 golpes próprios, fase 2 com vocabulário novo | o chefe como exame da mecânica regional | **REBUILD** (N31+) / **PARTIAL REWORK** (aprovados) | P1 (fixes P0) |
| **Level Design** | Jornada procedural em 96 níveis | N1/N2 à escala certa, N8, biblioteca de câmaras, ferramentas de medição | repetição, 4–9 min, 36 % descanso, checkpoints longe, 89 estreias | Celeste/Lost Crown/DC (salas autorais) | salas-peça por região | **REBUILD** (pipeline) | P0 |
| **Regional Identity** | 1/20 com kit; 19 recolor | R-I; pranchas das 20 | 7 materiais, 14 packs rotativos, mecânicas legadas | HK: arquitetura, fauna e som por zona | 20 identidades fortes já desenhadas | **REBUILD** (RegionKit) | P0 |
| **Art** | R-I HIGH/MEDIUM, II–III LOW, IV–XX NONE | kit R-I, Koliani golden | packs de 240 px, texel 1:1–1:8, `Polygon2D` | HK/Nine Sols: parallax pintado e coerente | luar vs corrupção | **REBUILD** fora da R-I; TUNE na R-I | P0 |
| **Animation** | Golden bom quando existe; locomoção derivada | roll/djump/dash | land de 1 frame, brake legado, turn com pop, sem mantle; chefes congelados | DC: transições desenhadas | faixa de pixel-art própria | **PARTIAL REWORK** | P0 |
| **VFX** | VFX 9G na R-I; fallback no resto | cadeia de acerto sincronizada | flash que tapa o alvo; telegraph só por cor | Nine Sols: código de cor por tipo de ataque | roxo Shadowblade vs corrupção | **TUNE** | P1 |
| **Camera** | Look-ahead de 112 px, deadzone de 68 px, sem jitter | interpolação física estudada | pouca antecipação vertical; sem limites/zonas; arena sem enquadramento | Celeste/HK: zonas de câmara por sala | câmara por sala autoral | **TUNE** | P2 |
| **Audio (SFX)** | 112 chaves; cadeia da Koliani completa | Signature, tiers, combo, prioridades | mistura por callsite; −6 dB global; mono; hazards mudos; o mesmo gemido em todos os chefes | DC/HK: mistura por prioridade de informação, 2D | assinatura roxa vs contra-assinatura | **PARTIAL REWORK** | P0 (mistura) |
| **Music** | 40 faixas stock, sem loops; ambiente único | loudness equilibrado, crossfade, licenças | sem identidade, cauda até 9,9 s, reinício no retry, sem camadas | HK: leitmotivos + ambiente; DC: música contínua na morte | leitmotivo Koliani/mãe/Zeriko | **PARTIAL REWORK** (decisão do GM) | P0/P1 |
| **UI** | Menu/seletor bons; HUD claro | arte do frontend, placa `mec.*` | strings cruas, botões mortos, "WB" em texto, Sanctuary/Shrine, sem acessibilidade | DC: cartões de pickup | seletor com "precisa de X" | **TUNE** | P1 |
| **Progression** | Recompensas invisíveis; economia esgota-se no N19 | Essência não se perde; separar habilidade de saque | 3 moedas, 1.ª arma pior, vidas até 99, clamp 29 | DC: sumidouros contínuos; HK: charms como decisão | ramos de melhoria por habilidade | **MAJOR REWORK** | P0/P1 |
| **Skills** | 9 habilidades, 0 exigidas | salto duplo com contrato | pogo nunca dado; 46 níveis sem nada novo; opcionais | Lost Crown: anunciar → exigir → combinar → reabrir | "a região de uma ferramenta" | **REBUILD** (calendário) | P0 |
| **Exploration** | Forquilha que se junta; 1 gabarito de segredo | sala do planar ensina sem texto | sem rotas, sem portas de habilidade, sem revisita | Lost Crown / HK | memória da mãe nos segredos | **PARTIAL REWORK** | P2 |
| **Replayability** | Seletor sem motivo para voltar | retry rápido | sem segredos, tempos nem alcovas de revisita | Celeste (morangos, B-sides) | "volta ao N3 com o dash" | **PARTIAL REWORK** | P3 |
| **Narrative Delivery** | Pistas dormentes; 4 intros de chefe; Novo Jogo sem história | 30+ pistas escritas, `Dialogo` sem pausar | sem objetivo no ecrã; Aurora/Elara; Zeriko no N30 | HK: fragmentos que se encontram | leitmotivo + memórias | **PARTIAL REWORK** | P1 |
| **Technical Foundation** | Determinismo 100/100; perf. p99 6–12 ms | save v5, manifesto, sandbox de testes, ferramentas de medição | gerador de 5 528 linhas, `_rng` partilhado, reload por morte (≤ 0,94 s), 8 combinações de rig, bots que escrevem no save real | Celeste: retry < 0,5 s | salas-peça com semente própria | **PARTIAL REWORK** | P1 |

### 10.5 Anexo B — Decisões que só o GM pode tomar

| # | Decisão | Opções | Recomendação da auditoria |
|---|---|---|---|
| 1 | **Tabela única região → tema → mecânica → chefe** | canon de 15 set (`KOLIANI_REGION_CANON.md`) vs tabela de 3 set em jogo (`REGIOES`, `world.*`) | Canon de 15 set. Migrar dados antes de qualquer conteúdo IV–XX |
| 2 | **Chefes: 20 regionais ou 85 "boss.*"** | manter um chefe por nível / 20 regionais + elites | **20 regionais**; os restantes 80 encontros passam a guardiões/elites/salas de desafio |
| 3 | **N30 Zeriko Final** | manter no N30 / mover para o N100 / reaproveitar como base do final | Mover: é o chefe mais rico e pertence ao fim. N30 = Mirage Eterna (canon) |
| 4 | **Nome da mãe** | Aurora (jogo, pistas, CLAUDE.md, historia) / Elara (visão 1.0) | Fechar um nome e migrar i18n e pistas numa só passagem |
| 5 | **Nome e chefe da Região I** | "Floresta Sagrada" (canon) / "Floresta Corrompida" (PNG, jogo); o canon ainda diz Guardião Verde | Atualizar o canon com o Coração Putrefacto (decisão de 25/09) e escolher o nome |
| 6 | **Guardiões N1–N4 (e N×1–N×4 nas outras regiões)** | decidido a 25/09 para a R-I, mas não aplicado; generalizar? | Aplicar na R-I no slice (Ghorak = mini-boss de sala); generalizar a regra a todas as regiões |
| 7 | **Música** | playlist Pixabay aprovada como produto final / como referência de tom + trilha produzida / editar as 40 para loop | No mínimo editar para loop real; idealmente produzir camas com um leitmotivo comum |
| 8 | **"Música claramente à frente"** (`SFX_MIX_DB −6`) | manter global / só para o decorativo | Música à frente do decorativo; feedback de jogo (hit, dano, telegrafo, recompensa) ao nível dela |
| 9 | **Âmbito da 1.0** | 100 níveis à barra do slice / campanha menor à barra / 100 com parte procedural assumida | Decidir **depois** da Validação, com o custo por região medido na fase 4 |
| 10 | **Vidas** | manter / ecrã explícito / remover (a fogueira como único contrato) | Remover |
| 11 | **Moedas** | Essência + Kolicoins + Veracoins / 1 moeda de jogo (+ premium no futuro) | 1 moeda de jogo; esconder as Veracoins até haver pagamento e conteúdo |
| 12 | **Calendário de verbos** | dash no N5 / dash ou wall-kick ensinados no N1–N2; pogo dar ou cortar; regresso de um especial (Kamehameha) como sumidouro de Energia | Antecipar um verbo de traversal para a R-I; dar o pogo; especial de volta com custo |
| 13 | **Koliani Sombria (N27) e outros chefes legados com valor narrativo** | cortar / reaproveitar como elites ou momentos de história | Avaliar caso a caso quando a tabela (1) estiver fechada |
