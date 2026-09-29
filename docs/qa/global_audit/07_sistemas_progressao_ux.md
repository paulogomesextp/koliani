# Auditoria global — AGENT 7: Sistemas, Progressão e UX

Data: 25 set 2026 · build `v0.18.20` (HEAD `bcac9fde`) · modo diagnóstico (nada alterado no jogo).
Runtime: Godot 4.7.2 pelo `godot_sandbox.sh` (APPDATA isolado), janela no 2.º monitor a 1280x720,
harnesses próprios em `scratchpad/a7/` (`a7_fluxo.gd`, `a7_unlocks.gd`, `a7_porta5.gd`, `a7_censo.gd`).
Capturas: `docs/qa/global_audit/img/a7/`.

**Save real:** SHA256 antes = depois = `9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238` (intacto).

---

## 0. Resumo — as 5 causas-raiz

| # | Causa-raiz | Sintomas que explica | Prio |
|---|---|---|---|
| RC1 | **As habilidades não são chaves do level design.** Não existe um calendário de ferramentas como dado; o gerador só conhece "salto simples vs duplo". | dash/escalar/planar/projétil/partir paredes nunca exigidos; pickups legados espalhados em 24 `.tscn` (16 projéteis duplicados); 46 níveis seguidos sem nada novo; `pogo` nunca se ganha; botões de habilidades que ainda não se têm no HUD de toque; toasts com o id cru | **P0** |
| RC2 | **A progressão acontece às escondidas.** A porta salta direto para o nível seguinte, sem momento de recompensa. | arma nova, Kolicoins, +1 vida e fim de região ficam invisíveis; a 1.ª arma *baixa* o dano (50→48); o toast do salto duplo fica atrás da placa de tutorial; o baú é um retângulo de placeholder | **P0** |
| RC3 | **A economia não tem forma:** 3 moedas, sumidouros que se esgotam cedo e escalas presas aos 30 níveis antigos. | melhorias todas compráveis por volta do N19 (modelo); ~90 % da Essência da campanha sem uso; a curva de inimigos/chefes pára no N30 e o equipamento continua a subir até ao N100; o Santuário vende melhorias de habilidades que ainda não se têm | **P1** |
| RC4 | **O "porquê" e o "próximo objetivo" estão desligados.** Os sistemas de narrativa/objetivo estão dormentes ou em conflito com o cânone. | 30+ pistas escritas (com "Aurora", não Elara) sem entrega; Novo Jogo cai num seletor de 100 níveis em vez da história/N1; nenhum objetivo no ecrã; o vídeo de intro repete a cada arranque | **P1** |
| RC5 | **Vidas e saídas castigam sem explicar.** | ficar sem vidas manda para o início do nível sem uma única mensagem; "Mapa"/"Menu" na pausa deitam fora o checkpoint sem aviso; as vidas chegam a 99 e deixam de significar alguma coisa | **P1** |

O que está bom e tem de se preservar: o **save** (versionado, com migrações, temp+backup e IDs estáveis), o **retry rápido**
(**0,47–0,81 s** da morte ao controlo, medido), a **fogueira = checkpoint**, a arte do **menu e do seletor**, a regra
**"loja = só cosméticos"** e a **placa de tutorial por mecânica** (`mec.*`).

---

## 1. Fluxo medido em runtime (novo jogo → N1 → morte → checkpoint → fim → seletor → loja)

Log: `scratchpad/a7/a7_fluxo_log.txt`. Tempos de parede (`Time.get_ticks_msec`).

| Passo | Medido | Captura |
|---|---|---|
| Intro (vídeo) → menu, sem input | **10,5 s** (repete a cada arranque; salta-se com uma tecla) | `01_intro_2s.png` |
| Menu sem save | NEW GAME / SELECT LEVEL / SHOP / OPTIONS / QUIT. "DEVELOPER MODE" visível (build de debug) | `02_menu_inicial_sem_save.png` |
| NOVO JOGO → destino | **Mapa/seletor em 549 ms**, não o N1. Para jogar faltam ainda "View levels" → nível → Play | `05_novo_jogo_destino.png` |
| Mapa → N1 jogável | **2670 ms** (1.º carregamento a frio) | `07_n1_inicio.png` |
| Início do N1 | Sem objetivo, sem história e sem dica de controlos no teclado. Os botões WEAPONS/ARMOR já aparecem com o inventário vazio | `07/08_n1_*.png` |
| Morte 1 (sem checkpoint) | nova Koliani aos **474 ms**, controlo (fade a 0) aos **684 ms** | `09_morte1_*.png` |
| Checkpoint ativado | a sessão grava `checkpoint_level_001_02` | `10_checkpoint_ativado.png` |
| Morte no checkpoint | controlo aos **717 ms**; reaparece em x=150 (a fogueira está em x=430: é o ponto seguro resolvido) | `11_morte_checkpoint_*.png` |
| Ficar sem vidas (vidas=1 → morrer) | controlo aos **810 ms**, **de volta ao início do nível**, vidas repostas a 5, **sem qualquer mensagem** | `14_morte_sem_vidas_*.png` |
| Porta do N1 → N2 | **623 ms**. Só aparece o banner "Advanced to Level 2". Os +25 Kolicoins e o +1 vida não aparecem em lado nenhum | `16/17_n2_*.png` |
| Pausa | Resume / Options / **Shrine** / Level map / Main menu. O "recomeçar no checkpoint" existe mas está escondido | `12_pausa.png` |
| Santuário (seletor e pausa) | chama-se "Sanctuary" no seletor e "Shrine" na pausa | `06`, `13` |
| Seletor depois da Região I | "ATUAL · 5/5 COMPLETE". **"ATUAL" é português cru na UI inglesa** | `18`, `19` |
| Seletor de equipamento | carrossel legível; "Worn Blade DMG 48", sem comparação com o dano sem arma (50) | `20_seletor_equip_arma.png` |
| Loja com 200 K | 5 itens em destaque; o preview do detalhe diz "PLACEHOLDER · ART PENDING" | `22_loja_com_kolicoins.png` |

Tempos de carga por nível (headless, **= custo de cada morte**, porque morrer faz `reload_current_scene`): mediana
**~520 ms**, máximo **1314 ms** (N96), 3016 ms só no 1.º a frio. **O retry é uma força:** está na faixa do Celeste e do Dead Cells.

---

## 2. Habilidades / ferramentas de traversal — RC1

### CURRENT STATE
- 9 habilidades em `HABILIDADES_TODAS` (`scripts/estado_jogo.gd:39`): dash, salto_duplo, dash_aereo, pogo, partir_paredes, escudo, projetil, escalar_paredes, planar. `HABILIDADES_INICIAIS` está vazio (`:43`).
- **Uma única concessão com contrato:** `HABILIDADE_DO_CHEFE := {4: "salto_duplo"}` (`scripts/nivel_com_chefe.gd:216`).
- O resto vem de `Coletavel.habilidade_id` escritos à mão nas cenas antigas, mais um no gerador (planar, `gerador_corredor.gd:4682`). Censo em runtime (campanha nova, 100 níveis, `a7_censo.gd`):

| Nível | pickup presente | | Nível | pickup presente |
|---|---|---|---|---|
| N5 | dash | | N17, N20 | escudo |
| N6 | dash_aereo | | N8,10,12,14,15,18,19,21–29 | projetil (**16 cópias**; depois da 1.ª ficam escondidas) |
| N7, N11 | escalar_paredes | | N31–N62 | **nada** |
| N9, N16 | partir_paredes | | N63 | planar (**2 coletáveis no mesmo nível**) |
| — | **pogo: em nenhum** | | N64–N100 | **nada** |

- **Nenhuma habilidade é exigida pelo caminho crítico.** O modelo de alcance do gerador (`vao_possivel`, `gerador_corredor.gd:5253`) só conhece o salto (simples ou duplo). `ParedeFragil` "NUNCA está no caminho" (`gerador_corredor.gd:2946`), e o comentário ainda diz "nível 4" quando a habilidade só se ganha no N9. As `PlataformaEspectral` ficam **sempre sólidas** sem projétil (`plataforma_espectral.gd:33`). O planar é "o caminho curto, nunca o único" (`:4675`). Única exceção: o salto duplo sobe o degrau máximo de 60 para 104 px a partir do N6 (`:1005`).
- HUD de toque: os botões Escudo, Tiro e Dash **estão visíveis e mortos** no N1 sem nenhuma habilidade (`controlos_tacteis.gd:39-45`, sem gate; captura `30_n1_hud_toque_sem_habilidades.png`). O rolar, que está sempre disponível, **não tem botão de toque** (`controlos_tacteis.gd:27`).
- Toast de desbloqueio: `NOME_HABILIDADE` (`controlos_toque.gd:7-14`) não tem `dash`, `planar` nem `pogo`, por isso aparece **"New ability: dash"** e **"New ability: planar"** com o id cru, e o planar sem ícone (runtime: `31_toast_dash.png`, `31_toast_planar.png`). O toast só diz o nome, nunca *como* se usa.
- O salto duplo (a única habilidade garantida) cai com o chefe do N5, mas o toast **não aparece nos 3 s seguintes**. Fica na fila de slot único (`controlos_toque.gd:821-865`) atrás da placa "Timed Platforms", que dura 10 s (runtime: `33_n5_chefe_caiu.png`, `34_n5_apos_queda.png`).

### WHAT WORKS
`tem_habilidade` e as suspensões (N98) são limpas; o desbloqueio grava logo; o contrato do salto duplo tem teste de mobilidade; a sala do planar ensina sem texto (bom instinto).

### WHAT DOES NOT WORK
As habilidades são **bónus opcionais, não ferramentas que abrem caminho**. A sensação de "fiquei mais capaz e agora vou onde antes não ia" nunca acontece. Depois do N20 não entra nada durante 43 níveis, e dos N64 aos N100 a Koliani não aprende mais nada.

### BENCHMARK GAP
Lost Crown / Hollow Knight: cada ferramenta nova (1) é anunciada com cerimónia e instrução, (2) é **exigida** logo a seguir num teste seguro, (3) é depois **combinada** com as anteriores e (4) reabre sítios antigos. O Koliani não faz nenhum destes quatro.

### KOLIANI OPPORTUNITY
É uma campanha por níveis, não um metroidvania, e isso é uma vantagem: cada região pode ser **"a região de uma ferramenta"** (ensinar → exigir → combinar no exame/boss da região), e os níveis já concluídos ganham **alcovas de revisita** ("volta ao N3 com o dash para abrir a cripta"). O seletor, que já existe, é o sítio natural para mostrar "🔒 precisa de Wall Climb".

### ACTION — **REBUILD (P0)**
Uma tabela de dados única `ABILITY_SCHEDULE` (nível → habilidade → câmara de ensino → primeira câmara obrigatória), consumida pelo gerador **e** pelo modelo de alcance (`vao_possivel` com dash, dash aéreo, escalada e planar). Apagar os pickups legados das `.tscn`. HUD: esconder os botões até ao desbloqueio. Toast com nome i18n, ícone e **linha de instrução** (reaproveitar `mec.*`), e com prioridade sobre a placa de tutorial. Decidir o pogo (dar ou cortar). Distribuir as habilidades pelos 100 níveis: ~1 ferramenta ou variação por região.

---

## 3. Recompensas, fim de nível e equipamento — RC2

### CURRENT STATE
- A porta (`scripts/porta.gd:67-89`) faz `marcar_nivel_concluido` e depois `avancar_nivel` e troca de cena **no mesmo frame**. Os sinais `equipamento_ganho` e `moedas_loja_mudaram` saem para a HUD da cena que está a morrer. Runtime (`a7_porta5.gd`): ao atravessar a porta do N5 o estado passa a kc 100→200, vidas 5→6, `armas=["lamina_gasta"]` equipada. **No ecrã só se vê "Advanced to Level 6"** e um "WB" em texto no slot da arma (`40_n6_chegada_*.png`). Não há marco de "Região I concluída".
- **A 1.ª arma piora o personagem:** `DANO_BASE = 50` (`estado_jogo.gd:358`) contra `lamina_gasta` com dano 48 (`equipamento.gd:25`), auto-equipada porque o slot está vazio (`estado_jogo.gd:571`). Medido: dano 50 → 48.
- A 1.ª armadura, `trapos_de_viajante`, dá 0 de vida e 0 % de redução (`equipamento.gd:57`), portanto não faz nada. O "15+15" do pedido original é hoje **20 armas + 10 armaduras** (cadência 5/10), com 5 artes de armadura órfãs na tira.
- Impacto visual do equipamento: só uma tinta no shader do corpo e a cor do golpe (`koliani.gd:1272-1303`, `2257`). Não há arma nem armadura desenhadas no boneco.
- Baú do chefe: desenhado com `draw_rect` (`bau_chefe.gd:14-18`, placeholder) e painel de uma linha "Boss reward / +47 Essence" (`35_n5_bau_premio.png`). Sorteio de 50 % Essência, 20 % arma, 15 % armadura e 15 % rank de melhoria (`saque_chefe.gd`). Uma **melhoria grátis** entra por sorteio e contorna o Santuário.

### WHAT WORKS
Separar "habilidade = progressão garantida" de "baú = saque sorteado" é o desenho certo (`nivel_com_chefe.gd:206-212`). O som do baú está bem hierarquizado. O seletor de equipamento lê-se bem.

### WHAT DOES NOT WORK
O jogador não sabe **o que ganhou, porque ganhou nem onde o vai usar**. O maior prémio do N5 é invisível. A 1.ª arma é um castigo escondido. A armadura inicial é nula. As 20 armas diferem só num número e numa cor.

### BENCHMARK GAP
Dead Cells: cada pickup tem um cartão com stats e comparação, e o fim do bioma tem um momento próprio (loja, escolha). Hollow Knight: cada charm é uma **decisão** (entalhes) e muda a maneira de jogar. Aqui o equipamento é uma escada linear de números, auto-equipada.

### KOLIANI OPPORTUNITY
Um **ecrã de fim de nível** curto (≤ 4 s, "toca para continuar") com o que se ganhou, a fogueira e a próxima ameaça. O fecho de região é o momento narrativo natural ("a Koliani fica com a lâmina do Ghorak"). As armas podem ter **1 traço cada** (queimar, sangrar, alcance, velocidade: o sistema de estados já existe desde a P1 de combate) em vez de só +dano.

### ACTION — **PARTIAL REWORK (P0 para o ecrã de fim de nível e a 1.ª arma; P1 para os traços das armas)**
Ecrã de recompensa antes da troca de cena. Corrigir a curva (1.ª arma ≥ base, 1.ª armadura com efeito). Baú com arte e cartão de comparação. Considerar reduzir para ~10 armas com identidade em vez de 20 números.

---

## 4. Economia (Essência, Kolicoins, Veracoins, Santuário, Loja) — RC3

### CURRENT STATE
- **Essência** → Santuário: 6 melhorias, 19 ranks, **total 2950** (`melhorias.gd`). Fontes: comuns 1–4, elites 14–36 (`demonio_base.gd:1197-1198`), **todos os chefes e guardiões** 70–160 (`chefe_base.gd:473-476`), baú 35+3·i, e caches em alcovas.
- **Modelo** (contagens de inimigos e elites do censo em runtime × fórmulas do código; STATIC-DERIVED): Região I ≈ 660, N10 ≈ 1290, **as 6 melhorias ficam todas compráveis por volta do N19**, e a campanha rende ≈ **32 000**. Cerca de 90 % da Essência não tem destino. Medido no N5: chefe +82 e baú +47.
- **Kolicoins**: +25 por nível e +100 por exame (`loja_catalogo.gd:28-29`) → ~4000 na campanha, contra ~2350 K do catálogo inteiro. **9 de 10 itens são placeholder**. `skin_coracao_podre`, `efeito_rasto_esporos` e `extra_galeria_conceitos` **não têm efeito visual ligado** (`cosmeticos_visuais.gd` só conhece carmesim, luar, brasa, osso e raízes). Os Kolicoins não se reiniciam com Novo Jogo (`estado_jogo.gd:394-398`) e a 1.ª conclusão volta a pagar, o que permite farm.
- **Veracoins**: moeda premium sem pagamento implementado. Hoje é UI morta (`22_loja_com_kolicoins.png`: "VERACOINS 0").
- **Curvas presas aos 30 níveis antigos:** `clampi(indice_nivel, 0, 29)` em vida, dano e velocidade dos inimigos (`demonio_base.gd:381`), vida e dano dos chefes (`chefe_base.gd:232`, `:286-289`) e drops. O equipamento sobe até ao N100 (dano 48→200, redução até 30 %, +120 de vida). **O combate do Ato 2 (N31–N100) fica mais fácil à medida que se avança.** O gerador tem o seu `_dificuldade` com Ato 2 (`gerador_corredor.gd:972`), mas a vida e o dano dos atores não o seguem.
- O Santuário vende logo "Focus" (energia, que é do projétil, N8) e "Runic Shield" (escudo, N17) a quem ainda não tem essas habilidades (`06_santuario_novo_jogo.png`).

### WHAT WORKS
A Essência não se perde na morte, o que está certo para um jogo por níveis. A UI do Santuário é clara (ícone, ranks, efeito, custo). A regra "Veracoins nunca compram vantagem" é validada por teste.

### WHAT DOES NOT WORK
Há três moedas para dois sumidouros pequenos. A meta-progressão acaba no primeiro quinto da campanha. Nos últimos 70 níveis a progressão de poder é só equipamento automático sem contrapeso. As melhorias não se ligam às habilidades.

### BENCHMARK GAP
Dead Cells: as células (a moeda da meta) têm sumidouros escalonados e contínuos (blueprints, flasks, dificuldade "boss cells") e cada compra desbloqueia **opções** novas, não só +%. Hollow Knight: Geo tem sempre destino (mapas, charms, entalhes, chaves).

### KOLIANI OPPORTUNITY
Juntar Kolicoins e Essência numa moeda de jogo. Ligar o Santuário às habilidades ("Dash: +1 carga", "Planar: dura mais") para que **cada ferramenta nova abra um ramo de melhorias**, o que dá sumidouro até ao N100. Usar o calendário de dificuldade de 100 níveis que já existe no gerador também nos atores.

### ACTION — **MAJOR REWORK (P1)**
Uma moeda de jogo. Árvore de melhorias por habilidade, com custos até ao N100. Tirar o `clampi(...,0,29)` e usar a mesma função de dificuldade do gerador. Loja cosmética: tirar da UI os itens sem visual e as Veracoins até haver arte e pagamento.

---

## 5. Save, sessão e checkpoints

### CURRENT STATE
`save_foundation.gd`: schema v5, migrações sequenciais 0→5 validadas passo a passo, TEMP+backup, `level_session` com IDs estáveis de checkpoint e fallback controlado (`estado_jogo.gd:920-932`). Runtime: o checkpoint ativa e grava o ID (`checkpoint_level_001_02`); o CONTINUE aparece com save (`21_menu_com_save.png`).

### WHAT WORKS
É a parte mais sólida do domínio. Nunca guarda um frame arbitrário, e o `_desencravar` protege saves antigos. **KEEP.**

### WHAT DOES NOT WORK
Os campos hardcore continuam no schema (`save_foundation.gd:200,225`) apesar de "Hardcore fora do scope 1.0" (`docs/visao_koliani_1_0.md`). A pausa → "Level map" / "Main menu" chama `abandonar_sessao_nivel()` (`pausa.gd:188-197`) e **perde o checkpoint sem aviso**, enquanto fechar a app mantém a sessão. É incoerente.

### ACTION — **KEEP (save) / TUNE (P2)**
Aviso "vais perder o progresso deste nível" ou manter a sessão ao sair para o mapa. Limpar os campos hardcore numa migração v6 quando o scope fechar.

---

## 6. Morte, vidas, restart — RC5

### CURRENT STATE
Morrer faz fade de 0,22 s e `reload_current_scene` (`koliani.gd:2754-2769`, `transicao.gd`). Controlo de volta em **0,47–0,81 s** (medido). Vidas: começam em 5, +1 por nível e tecto de 99 (`estado_jogo.gd:31-36`). Sem vidas: `reiniciar_run()` repõe as vidas e manda para o **início do nível** (`:836-848`). Runtime: acontece **sem ecrã, sem som próprio e sem texto** (`14_morte_sem_vidas_reaparece.png`). O `game_over.gd` só existe para o hardcore.

### WHAT WORKS
O retry é rápido e sem menus, ao nível do Celeste. Mantém-se.

### WHAT DOES NOT WORK
As vidas são uma camada de castigo que o jogador não percebe: o único efeito é perder o checkpoint, e em silêncio. Aos +1 por nível chegam a 20–40 a meio da campanha e tornam-se ruído no HUD.

### BENCHMARK GAP
Celeste, Hollow Knight e Dead Cells não têm vidas. O custo da morte é a distância à fogueira (ou a sombra/moedas no HK), e é sempre legível.

### KOLIANI OPPORTUNITY
Tirar as vidas e fazer da **fogueira** o único contrato. Se se quiser tensão, pôr um custo legível e recuperável (por exemplo deixar Essência na sombra da morte, tipo HK), coerente com o tema.

### ACTION — **REBUILD pequeno (P1)**
Tirar as vidas, ou pelo menos mostrar um ecrã "sem vidas: o nível recomeça" com opção de continuar.

---

## 7. Level select, mapa, HUD e menus

### CURRENT STATE / WHAT WORKS
Menu (`02`) e seletor de regiões (`05`, `19`) de boa qualidade visual, com progresso por região (barra, "5/5 COMPLETE"). O HUD tem região, passo "1/5", nome do guardião, vida, vidas e Essência (`07`). A placa de mecânica `mec.*` explica cada mecânica nova no canto, por 10 s, em fila.

### WHAT DOES NOT WORK
- **Novo Jogo → seletor de 100 níveis**, não o N1 (`menu_inicial.gd:386-388`; runtime 549 ms até ao mapa). Para um jogador novo são 3 passos extra e nenhum contexto. O comentário em `mapa_mundo.gd:9` ("a Porta traz de volta a este mapa") já não é verdade.
- **Strings portuguesas cruas** no seletor: `"ATUAL"`, `"CONCLUÍDO"`, `"DESBLOQUEADO"`, `"BOSS"` (`seletor_niveis.gd:368-372`, `:433`), o que viola a regra i18n do projeto. Visto em runtime ("ATUAL" em `05`, `19`).
- Nomes em conflito: "Sanctuary" (seletor) e "Shrine" (pausa) para o mesmo ecrã.
- Os botões WEAPONS/ARMOR aparecem no HUD com o inventário vazio (N1–N5). O ícone da arma é o texto "WB" (`40_n6_*`).
- O seletor não mostra nada por nível além do estado: nem segredos, nem tempo, nem "precisa de X". **Não há razão para voltar a um nível.**
- Opções: só volume e idioma (`04_opcoes.png`). **Zero acessibilidade**: sem desligar tremor, hitstop ou flashes, sem modo assistido, sem remapear teclas, sem tamanho de texto nem daltonismo.

### ACTION — **TUNE (P1 para i18n e fluxo do Novo Jogo; P2 para o resto)**
Novo Jogo → intro narrativa curta → N1 direto. Chaves i18n no seletor. Um só nome para o Santuário. Esconder slots vazios. Página "Acessibilidade" com tremor, flash, hitstop, assist (vida ou velocidade) e remapeamento.

---

## 8. Onboarding, narrativa como objetivo, sistemas dormentes — RC4

- **Pistas / Diário:** retirados a pedido (`main.gd:45-46`), mas há **30+ pistas escritas nos 6 idiomas** (`clue.*` em `assets/i18n/en.json`), com o nome **"Aurora"** quando o cânone é **Elara** (`docs/visao_koliani_1_0.md`). É o melhor texto de mundo do jogo e não chega ao jogador. `registar_pista` só é chamado pela `Porta.pista_ao_atravessar`. STATIC ONLY para a contagem de callsites vivos.
- **Objetivo:** não há ecrã nem HUD que diga *porque* se avança ("resgatar a mãe; próximo: Coração da Floresta"). Só há o nome do guardião no canto.
- **Intro:** vídeo de 10,5 s a cada arranque (`intro.gd`), mas o Novo Jogo não tem introdução própria.
- **Tutorial de controlos:** existe `hud.controls.*` (com "Jump ×2" apesar de o salto duplo só abrir no N5, `en.json`), mas no desktop o N1 abre sem nenhuma dica (`07_n1_inicio.png`).
- **Hardcore:** `relogio_hardcore.gd`, `game_over.gd` e campos no save. Está fora do scope 1.0 e é código morto com superfície de bugs.

### BENCHMARK GAP
Hollow Knight entrega o mundo por fragmentos que se encontram (tablets, NPCs, diário do caçador): exatamente o que as pistas do Koliani já são, mas desligadas. Celeste ensina tudo por espaço e ritmo, com o objetivo sempre claro (a montanha).

### ACTION — **PARTIAL REWORK (P1)**
Reativar as pistas como **coletável opcional de exploração** (1–2 por nível, em alcovas atrás de habilidades, o que as liga à RC1), com um Diário simples, depois de migrar Aurora para Elara. Mostrar uma linha de objetivo no ecrã de fim de nível e no seletor. Cortar o hardcore do código.

---

## 9. Dificuldade

- O gerador tem uma curva de 100 níveis (`_dificuldade`, Ato 2 a começar em 0,72, `gerador_corredor.gd:967-977`).
- Os atores (inimigos, chefes, drops) param no N30 (secção 4).
- A Região I tem um alívio próprio (`alivio_regiao_i`).
- Não há opção de dificuldade nem de assist para o jogador.

**ACTION — TUNE (P1):** uma fonte única de dificuldade por índice para geometria e atores, mais um modo assistido nas Opções.

---

## 10. Tabela de ações

| Área | Ação | Prio |
|---|---|---|
| Calendário de habilidades como dado + modelo de alcance com ferramentas + câmaras obrigatórias | REBUILD | P0 |
| Ecrã/momento de recompensa no fim de nível e de região; 1.ª arma ≥ base; toast de habilidade com prioridade e instrução | PARTIAL REWORK | P0 |
| Economia: 1 moeda de jogo, melhorias ligadas às habilidades, curva de atores até ao N100 | MAJOR REWORK | P1 |
| Vidas → fogueira como único contrato (ou ecrã explícito) | REBUILD pequeno | P1 |
| Pistas como coletáveis de exploração + objetivo visível (e Aurora→Elara) | PARTIAL REWORK | P1 |
| Novo Jogo → N1; i18n do seletor; nomes coerentes | TUNE | P1 |
| Acessibilidade nas Opções | TUNE | P2 |
| HUD: esconder botões e slots sem conteúdo; ícone de arma real | TUNE | P2 |
| Loja: esconder placeholders, itens sem visual e Veracoins até haver conteúdo | TUNE | P2 |
| Save / sessão / checkpoint / retry | KEEP | — |
| Cortar código do hardcore | TUNE | P3 |

---

## 11. RUNTIME VERIFIED vs STATIC ONLY

**RUNTIME VERIFIED** (sandbox, janela real no 2.º monitor, ou headless para medições):
- Tempos: intro→menu 10,5 s; Novo Jogo→mapa 549 ms; mapa→N1 2670 ms; morte→controlo 684 / 717 / 810 ms; porta N1→N2 623 ms; carga por nível dos 100 (headless, mediana ~520 ms).
- Novo Jogo leva ao seletor e não ao N1; o CONTINUE aparece com save.
- Checkpoint grava o ID; a morte reaparece no ponto seguro; **sem vidas = início do nível sem mensagem**.
- A porta concede +25 / +100 Kolicoins, +1 vida e a arma sem feedback no ecrã; a 1.ª arma baixa o dano de 50 para 48.
- Toast "New ability: dash" / "planar" com o id cru; o toast do salto duplo não aparece nos 3 s depois de o chefe do N5 cair (placa de tutorial por cima).
- Botões de toque Escudo, Tiro e Dash visíveis no N1 sem habilidades.
- Chefe do N5: +82 de Essência; baú +47 de Essência; baú em placeholder.
- "ATUAL" em português na UI inglesa; "Sanctuary" contra "Shrine".
- Opções só com volume e idioma; loja com preview "PLACEHOLDER · ART PENDING".
- Censo de pickups de habilidade, paredes frágeis, plataformas espectrais, inimigos, elites e checkpoints nos 100 níveis (campanha nova). A coluna `comprimento_x` do TSV não é fiável e não foi usada.

**STATIC ONLY — NOT RUNTIME VERIFIED:**
- Que nenhuma habilidade é exigida pelo caminho crítico (leitura do modelo `vao_possivel` e dos comentários do gerador; não foi jogado nível a nível).
- O modelo da economia (N19 para as melhorias todas, ~32k de Essência), derivado das fórmulas com as contagens do censo; assume que se mata tudo e que os guardiões largam Essência como os chefes (os guardiões do N1–N4 largarem Essência não ficou confirmado em runtime).
- Curvas de vida e dano presas a `clampi(...,0,29)`; power creep do Ato 2.
- Cosméticos sem efeito visual (`skin_coracao_podre`, `efeito_rasto_esporos`, `extra_galeria_conceitos`).
- Pistas/Diário dormentes e conflito Aurora/Elara; campos hardcore no save.
- A pausa → mapa/menu perde o checkpoint (leitura de `pausa.gd`).
- Se os pickups legados dos N5–N29 estão em sítios alcançáveis no layout atual.

Save real: SHA256 `9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238` antes e depois (inalterado).
