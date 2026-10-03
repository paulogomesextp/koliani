```text
És o meu parceiro de planeamento para o jogo KOLIANI. Abaixo está o resultado de uma AUDITORIA EXTERNA completa aos níveis N1–N20, feita por um agente que jogou/mediu o jogo real (capturas, bot de playtest em 3 perfis, código, contratos de arte, áudio, performance). Quero que, a partir disto, definas comigo um PLANO DE MELHORIA EM ETAPAS para irmos resolvendo um passo de cada vez.

COMO QUERO QUE TRABALHES
1. Lê tudo. Não repitas o relatório; usa-o.
2. Propõe 6–8 ETAPAS curtas, ordenadas por impacto/risco. Cada etapa deve caber num "briefing" para um agente de código (Claude Code/Codex) e terminar com algo jogável e testável.
3. Para cada etapa: objetivo, tarefas, ficheiros/sistemas, riscos, testes, Definition of Done, e o que EU (Paulo) tenho de decidir ou testar à mão.
4. Faz-me primeiro as perguntas de decisão em aberto (lista "DECISÕES DO PAULO" no fim) antes de detalhar as etapas que dependem delas.
5. Sê crítico: se achares que uma recomendação da auditoria está errada ou não vale o esforço, diz porquê.
6. NÃO planear N21+ nesta fase. Primeiro N1–N20 bons e testados em telemóvel por jogadores externos.

================================================================
PROJETO
- Koliani: platformer de ação 2D, Godot 4.7.2 / GDScript, mobile-first (landscape, toque, 60 fps), builds Windows, Web/PWA, Android.
- 100 níveis planeados (20 regiões × 5); feitos e auditados: N1–N20 (Regiões I–IV). Estrutura por região: Teach → Develop → Combine → Challenge → Boss.
- Alvo visual: o mais próximo possível de Dead Cells (gótico, luar, magenta/roxo).
- Repo: github.com/paulogomesextp/koliani (master). Build auditada: v0.18.21 + commit local do N20 (d8e1827d, ainda sem push).
- Regras do repo: texto de ecrã só via Textos.t() + 6 línguas; assets CC0/grátis; terreno/fundos/props gerados por ferramentas tools/*.py; mudanças a sistemas globais atrás de flags opt-in; testes por tools/correr_testes.ps1 (protege o save real).

================================================================
VEREDITO
- Maturidade: ALPHA (não alpha avançada). Nota global atual: 5/10.
- Frase-resumo: "Bonito em fotografia, ainda não divertido de forma consistente." Há momentos bons (movimento, menu, HUD, boss N10, boss N20, mecânicas da Região III) espalhados por travessias vazias e visualmente desunidas.
- Pronto para N21? NÃO.

SCORECARD (0–10)
Movimento 7 | Combate 4 | Inimigos 5 | Bosses 6 (N5 6 · N10 7 · N15 3 · N20 7) | Level Design 5 | Progressão 6 | Arte 6 | Animações 6 | VFX 6 | Música (técnica) 5 | SFX 5 | UI 6 | UX 5 | Loja 4 | Skins 5 | Performance 7 (PC; telemóvel não medido) | Polish 4 | GLOBAL 5

================================================================
O QUE ESTÁ BOM (NÃO REESTRUTURAR)
- Física de movimento (scripts/movimento.gd): corrida 240 px/s com aceleração ~0,1 s, salto ~122 px, coyote 0,10 s, buffer 0,12 s, dash 620 px/s invulnerável. Envelopes medidos usados para desenhar portões. Só afinar: gravidade de queda 1,22× é algo "floaty" (testar 1,4–1,5 opt-in).
- Combo de 4 golpes e pogo intencional (Baixo+Ataque, com custo ao falhar).
- Menu principal (key art) e HUD novo: nível comercial.
- Atmosfera da Região I (fundo pintado).
- Boss N10 Guardião dos Céus (fase 2 muda a luta + falas) e boss N20 Guardião da Fornalha (padrões fixos, telégrafos, janelas EXPOSTO, refúgios, reset limpo, TTK medido ~60 s; o bot experiente consegue vencê-lo, é o único boss que o bot venceu).
- Desenho de mecânicas da Região III (sinos, engrenagens, órbitas, temporizadas).
- Ferramentas: geradores por nível (tools/construir_nXX_*.py, r4_lib.py), isolamento do save, travessias físicas.
- Textos de ensino das mecânicas (mec.*.txt): curtos e claros.
- Performance PC: p99 < 3 ms em todos os níveis (N20 é o mais pesado: 609 fps em combate, 0,1 % de frames > 33 ms).

================================================================
TOP PROBLEMAS (por impacto no jogador)
1. COMBATE RARO E SEM PESO
   - 1–8 inimigos comuns por nível de 4 500–7 800 px (N1 = 1, N2 = 1, N10 = 1).
   - Hitstop 10 ms (golpe) / 18 ms / 24 ms: invisível a 60 Hz (o código admite que valores maiores davam "drop").
   - ~30 espécies sobre só 7 comportamentos (patrulha, saltador, carga, voador, escudeiro, trepador, cuspidor); a Região I só tem goblin + gosma.
   - "A Koliani atravessa os inimigos" (sem colisão de corpo).
   - Região IV: o bot chega à porta em 25–57 s em N16, N17, N18 e N19 sem precisar de lutar (os elites não selam a passagem).
2. O JOGO NÃO PARECE UM SÓ: Região I pintada HD; II–IV pixel-art com densidades de píxel diferentes; fundos pixel com filtro suave (desfocados); fundo do N15 com píxeis gigantes; o rig do boss do N20 é ampliado de poses pequenas da prancha (macio/desfocado).
3. CONTEÚDO PROVISÓRIO EM PRODUÇÃO
   - N11: polígonos de cor sólida (sinos amarelos, plataformas lilás), nível de ~1 000 px que acaba em 31 s, nunca reformulado.
   - Vyrak (boss N15): arte gerada por código, de formas lisas, contra uma prancha de figura alada ornamentada; arena genérica; sem falas.
4. NARRATIVA INVISÍVEL: sem prólogo ("New Game" vai ao mapa). Falas só nos bosses N10 e N20; N5 e Vyrak mudos. A lore boa (Aurora, Zeriko, o Olho) está escrita nas chaves clue.* de um sistema retirado.
5. MOBILE: 6 botões à direita, 2 com o mesmo ícone "••" (especial/projétil); o ataque é o botão mais pequeno e está no meio; o cacho tapa ~⅓ direito do ecrã (direção de avanço); a Koliani mede ~70 px a 720p; o pogo exige joystick para baixo + ataque no ar.
6. NÍVEIS SEM LANDMARK E REPETIDOS DENTRO DA REGIÃO: os 5 da Região I partilham fundo/terreno/paleta; os 5 da Região IV também (mesmo forno, arco, laje). Na Região IV a Koliani e o boss (vermelho/escuro) perdem-se contra o fundo vermelho saturado.
7. GUARDIÃO EM TODOS OS NÍVEIS: N1–N20 acabam todos num guardião ou boss; os da Região I são bosses antigos despromovidos. O Ghorak (N1, 915 HP) é o mais resistente da Região I (N2 537, N3 675, N4 829).
8. CURVA DE DIFICULDADE FORA DE ORDEM
   - N7 ("Develop"): o bot morre 110–120× no mesmo troço nos 3 perfis (plataforma móvel em vento pulsado 1 600 sobre o vazio + elite logo após o checkpoint).
   - N11 é um vale depois do boss N10.
   - A Região IV (N16–N19) é mais fácil do que a III.
   - Estimativa N1..N20: 3 3 4 5 5 | 4 7 6 6 6 | 2 5 6 7 7 | 3 4 4 4 7.
9. LOJA
   - skin_shadowblade duplicada em scripts/loja_catalogo.gd (aparece 2× na grelha; o validador marca "id duplicado").
   - 5 itens placeholder à venda e células vazias.
   - Texto ~8 px a 720p.
   - 3 skins são recolors de paleta, uma vendida como "lendária".
   - 3 moedas (Essência, Kolicoins, Veracoins): sobreconstruído.
   - GRATIS_EM_DESENVOLVIMENTO=true: a economia nunca foi testada.
10. ÁUDIO
   - Mecanismos da Região IV (pistões, válvulas, jatos, lava, piso quente) sem nenhum som.
   - Música de boss de −19,1 LUFS (Região I, abaixo da própria exploração) a −9,0 (Região IV).
   - Ciclo da música da Região IV = 73 s para níveis de 4,5–6,7 k px.
   - scripts/musica.gd com 4 sistemas de música sobrepostos.
   - SFX duplicados (.wav/.ogg/_v2/_v3).

OUTROS BUGS/INCONSISTÊNCIAS
- A Região IV aparece na UI como "Catacombs of the Abyss" (cânone: Fornalha); a Região I como "Corrupted Forest" (cânone: Floresta Sagrada); boss N5 "Coração Putrefacto" vs cânone "Guardião Verde".
- "ATUAL" em português no seletor (scripts/seletor_niveis.gd:384) num jogo em inglês.
- "DEVELOPER MODE" visível no menu em builds de teste.
- N13 muito escuro, com vazios pretos visíveis fora dos limites.
- Faixa roxa lisa (plano de morte) a ocupar ~¼ inferior do ecrã em N1–N10.
- Linhas-guia do vento quase invisíveis (e o tutorial manda lê-las).
- Animações de dano (2 frames) e morte (3 frames) da Koliani curtas.
- Skins: asas do Anjo estáticas em todas as poses; Shadowblade com pouco contraste em fundos roxos; Fornalha sem VFX próprios.
- A suite de testes convive com "9 falhas pré-existentes".
- Ferramentas: o bot oficial (tools/bot_humano_r2.gd) arranca SEM habilidades, por isso as métricas de N3+ eram inválidas (a auditoria usou uma cópia corrigida); tools/shot_ui_9h11.gd (pausa) está partido.

================================================================
FICHA DO N20 "NÚCLEO DA FORNALHA" (novo, analisado à parte)
- Exame da Região IV: A revisão (piso quente + jato) → B lava que sobe + carrinho → C válvula + fosso de ritmadas/pistão + elite Operário Blindado → D corredor de máquinas → arena. 5 640 px, 6 checkpoints, 2 segredos. Landmark: Núcleo de Magma (engrenagem gigante).
- Boss Guardião da Fornalha (o único boss da Região IV): 2 889 HP, TTK medido ~60 s. Fase 1: golpe vertical / onda de lava / chamas do núcleo. Fase 2 (50 %): telégrafos ×0,8, investida e erupção (salvas nos refúgios). Sem RNG, sem dano em telégrafo, reset limpo. Tem falas.
- Bot: a travessia A–D faz-se sem mortes nos 3 perfis; TODAS as mortes são na arena (x≈5 000: 29–52 por perfil em 6 min); o perfil experiente VENCE o boss.
- Pontos fortes: o melhor desenho de boss do jogo a par do N10; prova técnica sólida.
- Problemas: implementa 5 dos 10 ataques da prancha; a arena não "transforma" na fase 2 (o contrato pede-o); o rig fica macio/desfocado (poses pequenas ampliadas) e é vermelho sobre fundo vermelho; o exame recombina blocos sem nada novo antes do boss, e a parte A–D é fácil (0 mortes); mesma laje de terreno das outras regiões; nenhum aviso sonoro nos mecanismos; o nome "Catacombs of the Abyss" continua no seletor.
- Notas: Level Design 6, Boss 7, Arte 6, Legibilidade 5.

================================================================
ROADMAP SUGERIDO PELA AUDITORIA (para validares/reordenares)
FASE A (P0, antes de playtest externo): suite verde (zero falhas) · tirar a Shadowblade duplicada · esconder placeholders da loja · nomes canónicos das regiões + "ATUAL" traduzido · esconder "DEVELOPER MODE" · refazer o N11 com o pipeline do N12–N14.
FASE B (P1, gameplay/UX): hitstop v2 (35/60/80 ms, opt-in; resolver o "drop" em vez de o evitar) · 3–5 encontros desenhados por nível e 1–2 zonas que fecham até limpar (incl. Região IV) · 2–3 comportamentos de inimigo novos · guardiões só no 2.º e 4.º nível de cada região + boss no 5.º · curva (N7, Ghorak ~500 HP, Região IV com pressão real) · controlos tácteis com ≤ 5 botões e ícones únicos · prólogo + falas nos bosses N5/N15 · SFX dos mecanismos da Região IV.
FASE C (P2, arte/áudio): UMA densidade de píxel e UM filtro para o jogo todo · Vyrak + arena a partir da prancha · landmark por nível (R1, R4) · luz do N13 · substituir a faixa roxa do plano de morte · música normalizada a −14 LUFS ±1, ciclos ≥ 150 s, OGG com loop points, musica.gd consolidado · skins recolor reprecificadas · rig do boss N20 mais nítido e com contorno contra o fundo · arena do N20 com evolução na fase 2.
FASE D (polish): frames de dano/morte · loja (texto ≥ 14 px, testar com preço real) · linhas do vento visíveis · aviso sonoro atenuado para perigos fora do ecrã · limpar SFX duplicados · consertar o bot (habilidades + modo de combate para medir TTK) · gravidade de queda.
CRITÉRIO DE SAÍDA: suite verde; N1–N20 sem placeholders visíveis; nenhum nível atravessável em < 90 s pelo bot experiente; 3 jogadores externos em telemóvel real completam a Região I e dizem "percebi o que fazer" e "o combate tem peso".

QUICK WINS (alto impacto, baixo esforço): duplicado da loja · nomes das regiões · "DEVELOPER MODE" · hitstop v2 · loudness da música · SFX da Região IV · ícones únicos nos botões · Ghorak ~500 HP · tirar o elite do vento pulsado do N7 · esconder placeholders.

REGRAS PARA CADA CORREÇÃO (dar aos agentes): confirmar a causa antes de mexer; preservar as baselines boas; sistemas globais atrás de flag opt-in; commits pequenos com teste; travessia física + capturas antes/depois; números de "feel" decididos em playtest humano, não às cegas.

================================================================
DECISÕES DO PAULO EM ABERTO (pergunta-me isto primeiro)
1. Direção visual única: o jogo todo em pixel-art (e qual densidade?), ou manter a Região I pintada e subir as outras? E o filtro (Nearest em tudo?).
2. Nome visível da Região I: "Floresta Sagrada" (cânone) ou "Floresta Corrompida"? E o boss N5: "Guardião Verde" (cânone) ou "Coração Putrefacto"?
3. Cortar guardiões para 2 por região + boss? Quais níveis perdem o guardião?
4. Combate: aceitar "fechar a passagem até limpar" em 1–2 zonas por nível?
5. Loja: simplificar para 1–2 moedas? Remover ou reprecificar as skins recolor?
6. O N11: refazer de raiz agora ou adiar e esconder a arte provisória?
7. Quem faz o playtest em telemóvel real, com que aparelho, e quando?

Agora: faz-me as perguntas de decisão e depois propõe as etapas.
```
