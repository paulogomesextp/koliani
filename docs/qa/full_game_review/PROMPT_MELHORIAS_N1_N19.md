# PROMPT DE MELHORIAS KOLIANI — PARA CHATGPT / CLAUDE / CODEX

```text
CONTEXTO
Projeto Koliani (Godot 4.7.2, GDScript), platformer de ação mobile-first (landscape, toque, 60 fps), builds Windows/Web/Android.
Repo: github.com/paulogomesextp/koliani, branch master. Baseline auditada: 812baf72 (v0.18.21).
Âmbito: SÓ N1–N19 (o N20 está a ser feito noutra tarefa; NÃO tocar). NÃO avançar para N21 sem nova decisão do Paulo.
Relatório que origina este plano: docs/qa/full_game_review/RELATORIO_AUDITORIA_N1_N19.md (ler primeiro).
Regras do repo: código/comentários/logs em português; texto de ecrã sempre por Textos.t("chave") + 6 assets/i18n/*.json (en.json é a fonte);
assets só CC0/grátis; arte de terreno/fundos/props gerada por tools/*.py (nunca editar PNGs/blocos Atmosfera à mão);
git add com paths explícitos (NUNCA git add -A); testes via tools/correr_testes.ps1 (protege o save real); Godot com timeout em cada execução.

REGRAS DE EXECUÇÃO (OBRIGATÓRIAS)
1. Antes de cada correção: reproduzir e CONFIRMAR a causa no código/jogo real. Se a causa não se confirmar, parar essa tarefa e reportar.
2. Preservar baselines boas: movimento.gd (física), combo de 4 golpes, pogo, HUD novo, menu principal, IA do Guardião dos Céus (N10), pipeline construir_nXX_*.py / r4_lib.py.
3. Mudanças em sistemas globais (koliani.gd, demonio_base.gd, chefe_base.gd, nivel_com_chefe.gd, musica.gd, som.gd) entram ATRÁS DE FLAG/@export opt-in com default = comportamento atual, ligadas nível a nível.
4. Uma tarefa = um commit pequeno, com teste. Suite inteira verde antes de cada push (ZERO falhas toleradas: as "9 falhas pré-existentes" são a tarefa A0).
5. Cada tarefa de gameplay termina com: travessia física (tools/correr_travessia.sh) + captura do antes/depois em docs/qa/ + nota para playtest humano.
6. Não corrigir às cegas números de feel: propor valor, medir, e deixar o valor final para playtest humano em telemóvel real.

======================================================================
FASE A — P0 (antes de qualquer playtest externo)
======================================================================

A0. Suite de testes vermelha tolerada
PROBLEMA: a equipa convive com "9 falhas pré-existentes" (docs/retomar_aqui.md).
EVIDÊNCIA: retomar_aqui.md (N19); LojaCatalogo.validar() marca "id duplicado" (ver A1).
CAUSA PROVÁVEL: falhas reais misturadas com testes obsoletos.
SOLUÇÃO: classificar cada falha (bug real -> corrigir; teste obsoleto -> atualizar com justificação no commit). Nenhum skip silencioso.
FICHEIROS: tests/run_tests.gd, tools/correr_testes.ps1.
RISCO: baixo. TESTES: suite completa 2× seguidas.
DEFINITION OF DONE: tools/correr_testes.ps1 sai 0, com save real intacto.

A1. skin_shadowblade duplicada na loja
PROBLEMA: o item aparece 2× na grelha da loja.
EVIDÊNCIA: scripts/loja_catalogo.gd ~linhas 101 e 105 (a 2.ª sem "splash"); captura docs/qa/full_game_review/ui/02_loja.png.
CAUSA PROVÁVEL: artefacto de merge.
SOLUÇÃO: apagar a 2.ª entrada (manter a que tem splash). Adicionar teste: LojaCatalogo.validar() == [] no run_tests.
RISCO: saves com o item comprado -> confirmar que o id é o mesmo (é), portanto a posse mantém-se.
TESTES: validar() vazio; abrir loja, contar Shadowblade == 1; comprar/equipar/reabrir.
DOD: 1 entrada; teste novo verde.

A2. Itens placeholder vendidos na loja
PROBLEMA: 5 itens "placeholder": true (skin_carmesim, skin_luar, skin_coracao_podre, base...) e células vazias visíveis.
EVIDÊNCIA: scripts/loja_catalogo.gd; ui/02_loja.png.
SOLUÇÃO: filtrar placeholder:true da grelha (exceto o item inicial/base) até haver arte. Não apagar dados.
RISCO: baixo. TESTES: grelha sem células vazias nem itens sem preview. DOD: zero placeholders visíveis.

A3. Nomes de região contra o cânone + texto não traduzido
PROBLEMA: a Região IV aparece como "Catacombs of the Abyss"; a I como "Corrupted Forest" (cânone: Floresta Sagrada); "ATUAL" em PT num jogo EN.
EVIDÊNCIA: assets/i18n/*.json world.catacombs / world.forest; scripts/estado_jogo.gd REGIOES[0..3]; scripts/seletor_niveis.gd:384; docs/art_direction/KOLIANI_REGION_CANON.md.
SOLUÇÃO: valores i18n canónicos nos 6 idiomas (en é a fonte); "ATUAL" -> Textos.t("ui.current"); NÃO mudar ids internos (partem saves) — só o texto.
Pergunta ao Paulo antes de fechar: o nome visível da Região I é "Floresta Sagrada" (cânone) ou fica "Floresta Corrompida"? Implementar o cânone por omissão.
TESTES: teste i18n de chaves iguais nos 6; captura do seletor e do HUD em N1 e N16.
DOD: nenhum nome de região diverge do cânone; nenhuma string PT no ecrã em EN.

A4. N11 com geometria placeholder
PROBLEMA: o N11 (Torre_dos_Sinos.tscn, "Entrance of Echoes") nunca foi reformulado: polígonos de cor sólida (sinos amarelos, plataformas lilás), nível de ~1 000 px que se termina em 31 s.
EVIDÊNCIA: docs/qa/full_game_review/region03/n11_2_terco.png, n11_3_doisterc.png; bot: porta em 31–50 s; não há docs/nivel_autoral_n11.md.
SOLUÇÃO: refazer como nível autoral "Teach" da Região III com o pipeline do N12–N14 (tools/construir_n12_galerias.py como modelo): ensinar sino->ponte (mec.sinos) e elevador de coluna em segurança, 3–4 encontros, 1 landmark (o sino da entrada), 3 checkpoints. Gerador próprio tools/construir_n11_entrada.py.
RISCO: médio (saves que estão no N11: manter nome de ficheiro e índice).
TESTES: teste_r3_n11_*; travessia física; crivo de alcance 100 níveis; capturas.
DOD: zero Polygon2D de cor sólida como arte final; duração 3–5 min estimada; playtest humano anotado.

A5. Build de teste mostra "DEVELOPER MODE"
SOLUÇÃO: mostrar só com EstadoJogo.modo_dev. DOD: captura do menu sem a etiqueta.

======================================================================
FASE B — P1 (gameplay / UX)
======================================================================

B1. Densidade de combate
PROBLEMA: 1–8 inimigos comuns por nível (N1 = 1, N2 = 1, N10 = 1); combate opcional na Região IV (bot à porta em 25–57 s).
EVIDÊNCIA: contagens de DemonioBase nas cenas (relatório §5); docs/qa/full_game_review/bot/tabela_bot.md.
SOLUÇÃO: por nível, 3–5 ENCONTROS desenhados (não spam): cada encontro = 2–4 inimigos que combinam 2 comportamentos + terreno. Em 1–2 pontos por nível (R4 incluída), fechar a passagem até limpar (mec.arena já existe). Começar por N1, N2, N16, N17. Editar nos geradores tools/construir_*.py quando o nível for gerado.
RISCO: médio (dificuldade). TESTES: travessia física 3 perfis; contar tempo até à porta (> 2 min para N16–N19); capturas.
DOD: ≥ 3 encontros por nível; nenhum nível N1–N19 atravessável em < 90 s pelo perfil experiente.

B2. Hitstop invisível
PROBLEMA: HITSTOP_GOLPE 10 ms, REMATE 18 ms, CRIT 24 ms (< 1–1,5 frames a 60 Hz).
EVIDÊNCIA: scripts/koliani.gd ~linhas 148–174 (o comentário admite que valores maiores davam "drop").
CAUSA PROVÁVEL: o hitstop via Engine.time_scale interfere com algo (áudio/física/medição de frames). CONFIRMAR antes de mexer.
SOLUÇÃO: @export combate_hitstop_v2 (default false): golpe 35 ms, remate 60 ms, crit 80 ms, levar dano 60 ms; se o "drop" se confirmar, implementar o hitstop congelando só os atores envolvidos (process_mode/anim speed) em vez do tempo global.
TESTES: tools/verifica_hitstop.gd; perf_gate sem frames > 33 ms; ligar em N1–N5 primeiro.
DOD: a flag ligada em N1–N19 com perf igual; nota de playtest humano.

B3. Comportamentos de inimigo
PROBLEMA: ~30 espécies sobre 7 comportamentos; a Região I só tem goblin+gosma.
SOLUÇÃO: 2–3 comportamentos novos com telégrafo legível (ex.: "emboscada" que cai do teto, "escudo frontal" que obriga a pogo/costas, "invocador" que só se mata por alcance). A Região I ganha 1 espécie nova da lista CC0/arte própria. Comportamentos novos opt-in por @export.
TESTES: teste por comportamento (telégrafo ≥ 0,35 s; hitbox ativa só após o telégrafo). DOD: cada região com ≥ 4 comportamentos distintos em jogo.

B4. Guardião em todos os níveis
PROBLEMA: N1–N19 acabam todos num guardião/boss; os da Região I são bosses antigos despromovidos; o Ghorak (N1, 915 HP) > guardiões N2–N4 (537/675/829).
SOLUÇÃO: por região, guardião só no 2.º e no 4.º nível + boss no 5.º; o 1.º e o 3.º acabam num desafio de travessia/encontro. Ghorak para ~500 HP (via vida_minima/escala, opt-in).
RISCO: médio (testes que esperam guardião). DOD: 2 guardiões + 1 boss por região; HP de guardiões monotónico dentro da região.

B5. Curva de dificuldade
PROBLEMA: pico no N7 (110–120 mortes do bot em x 4 200–4 400: PlataformaCorrente em vento pulsado 1 600 sobre o vazio + elite logo a seguir ao CheckCombinacao 4050); vale no N11; Região IV mais fácil do que a III.
SOLUÇÃO: N7: separar a plataforma móvel do elite (ou baixar o vento para ~1 300); Região IV: B1 + lava/pistões com pressão real.
TESTES: bot com habilidades (docs/qa/full_game_review/tools/bot_auditoria.gd) + playtest humano. DOD: hotspot do N7 < 30 mortes/6 min no perfil normal.

B6. Controlos tácteis
PROBLEMA: 6 botões à direita, 2 com o mesmo ícone "••", ataque pequeno no meio, o cacho tapa ~1/3 da direção de avanço.
EVIDÊNCIA: docs/qa/full_game_review/ui/10_toque_n9.png; scripts/controlos_tacteis.gd.
SOLUÇÃO: ataque = botão maior e no sítio do polegar em repouso; salto e dash adjacentes; especial e projétil com ícones únicos (ou fundidos num botão contextual); escudo opcional. Câmara com look-ahead extra no sentido do movimento quando o toque está ativo.
TESTES: tools/shot_toque.gd a 1600x720 e 2400x1080; teste em telemóvel real. DOD: ≤ 5 botões, ícones únicos, nenhum botão a tapar o chão à frente da Koliani a 1600x720.

B7. Narrativa visível
PROBLEMA: sem prólogo; só o boss do N10 fala; a lore está escrita em clue.* (sistema retirado).
SOLUÇÃO: prólogo curto (3–4 ecrãs, saltável) no 1.º New Game; falas_intro/falas_fim no Coração Putrefacto (N5) e no Vyrak (N15) pelo padrão de chefe_guardiao_dos_ceus.gd; 1 pista por região reaproveitando clue.*.
TESTES: i18n 6 línguas; saltar prólogo; não repetir no 2.º jogo. DOD: um jogador novo consegue dizer quem é a Aurora e o Zeriko depois do N5.

B8. Região IV muda
PROBLEMA: pistao_fornalha.gd, valvula_fornalha.gd, jato_fornalha.gd, lava_fornalha.gd, piso_quente.gd não chamam Som.* nenhuma vez.
SOLUÇÃO: Som.toca_actor/laco_actor para aviso/impacto do pistão, válvula aberta/fechada, jato a carregar/disparar, borbulhar da lava (laço baixo), piso a aquecer. Sintetizar em tools/gerar_audio.py. Atenção às regras de memória: som por significado, sem empilhar jingles.
DOD: cada mecanismo com aviso sonoro antes do perigo; teste estático das chaves de som.

======================================================================
FASE C — P2 (arte / áudio)
======================================================================

C1. Unificação visual
PROBLEMA: R1 pintada HD vs R2–R4 pixel-art com densidades diferentes; fundos pixel filtrados (desfocados); fundo do N15 com píxeis gigantes.
SOLUÇÃO: DECISÃO DO PAULO PRIMEIRO (escrever docs/decisoes.md): densidade de píxel alvo e filtro único. Depois regenerar fundos da R3 sem upscale e corrigir o filtro de texturas pixel para Nearest.
DOD: folha de contacto (tools/folha_de_contacto.gd) N1–N19 onde os 4 estilos leem como um jogo.

C2. Vyrak (N15) e a arena
PROBLEMA: rig "vyrak" gerado por código, de formas lisas, contra docs/art_direction/regions/region_03/boss_pack.png (figura alada ornamentada ouro/azul-marinho, sinos, arena no topo da torre).
SOLUÇÃO: nova arte do Vyrak a partir da prancha (idle/andar/preparação/ataque/hurt/death + forma de fase 2), arena com o sino grande e a lua; manter a IA de 2 fases de scripts/chefe_vyrak.gd.
DOD: comparação lado a lado com a prancha aprovada pelo Paulo.

C3. Landmark por nível (R1 e R4) e luz do N13
SOLUÇÃO: 1 peça de fundo/primeiro plano única + tom de luz por nível nos geradores; terreno com 2–3 variações por região; N13 com luz de preenchimento e sem vazios pretos (fechar limites da câmara).
DOD: em captura isolada cada nível é identificável (teste cego com 3 pessoas).

C4. Faixa roxa do plano de morte (N1–N10)
SOLUÇÃO: substituir por pântano/abismo com textura e parallax, ou baixar a câmara para não mostrar ¼ de ecrã vazio.

C5. Música
PROBLEMA: bosses de −19,1 (I) a −9,0 LUFS (IV); boss I abaixo da exploração; ciclo da R4 = 73 s; 4 sistemas em scripts/musica.gd.
SOLUÇÃO: normalizar todas as faixas a −14 LUFS ±1 (ffmpeg loudnorm, 2 passes); ciclo ≥ 150 s na R4; converter os loops para OGG com loop points (MP3 tem padding); consolidar musica.gd num só caminho (opt-in, com teste de qual faixa toca em cada nível).
DOD: tabela de LUFS dentro da tolerância; teste "faixa por nível".

C6. Skins
PROBLEMA: Fornalha/Abadia/Celestial são recolors (Celestial "lendária" a 250 V); Fornalha sem vfx/; asas do Anjo estáticas; Shadowblade com baixo contraste em fundos roxos.
SOLUÇÃO: recolors -> raridade "comum/raro" e preço coerente; VFX para a Fornalha; asas do Anjo com 2–3 poses; contorno/rim light de 1 px na Shadowblade (opt-in por skin).
DOD: tools/validar_paridade_skin.py verde para todas; captura de cada skin em N1, N9 e N17.

======================================================================
FASE D — POLISH
======================================================================
D1. Animações de dano (2 frames) e morte (3 frames) da Koliani: +2–4 frames cada.
D2. Loja: texto ≥ 14 px a 720p; miniaturas maiores; testar compra com GRATIS_EM_DESENVOLVIMENTO = false.
D3. Linhas-guia do vento: mais grossas e com contraste (o texto mec.rajada manda lê-las).
D4. Áudio fora do ecrã: aviso atenuado para perigos a ≤ 1 ecrã de distância (não silêncio total).
D5. Limpar SFX duplicados (.wav/.ogg/_v2/_v3) depois de auditar evento -> ficheiro.
D6. Corrigir as ferramentas: tools/shot_ui_9h11.gd (nó "Painel"); tools/bot_humano_r2.gd entregar habilidades por índice (ver docs/qa/full_game_review/tools/bot_auditoria.gd) e ganhar um modo de combate para medir TTK.
D7. Gravidade de queda 1,22 -> testar 1,4–1,5 (opt-in), só com playtest humano.

ORDEM: A0 -> A1 -> A2 -> A3 -> A5 -> A4 -> B2 -> B1 -> B4 -> B5 -> B8 -> B6 -> B7 -> B3 -> C* -> D*.
CRITÉRIO DE SAÍDA GLOBAL: suite verde; N1–N19 sem placeholder visível; nenhum nível < 90 s pelo bot experiente; 3 jogadores externos em telemóvel real completam a Região I e respondem "percebi o que fazer" e "o combate tem peso".
N21+: proibido até o Paulo decidir, depois deste critério cumprido.
```
