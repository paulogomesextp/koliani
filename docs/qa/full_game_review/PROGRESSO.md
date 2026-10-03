# Auditoria externa N1-N20 -- progresso (retomar daqui)
Worktree limpa: C:\Projetos\koliani-audit @ origin/master 812baf72 (v0.18.21). READ-ONLY ao produto.
Pedido: auditoria completa (ver conversa de 3 out 2026). Responder so' no fim; avisar o Paulo.

## Feito
1. Git/build: HEAD 812baf72, v0.18.21, main_scene MenuInicial. Local do Paulo (claude/9h13b) atras + sujo -- nao tocado.
2. Canon lido (docs/art_direction). R1 sem PNG; R2-R4 com pranchas.

## Achados ate' agora
- N20 EXCLUIDO pelo Paulo (a ser feito noutra conversa). Auditoria = N1-N19; ultimo boss avaliado = N15 Vyrak.
- N5 chefe = Coracao Putrefacto; canon diz "Guardiao Verde" (desvio de nome/canon).
- N10/N11 sem doc autoral; N11 Torre_dos_Sinos tem ChefeSinoVivo (legado?).
- N1: so' 1 inimigo comum (GoblinAprendiz) + Ghorak guardiao -> densidade de combate baixa.

## Por fazer
import (a correr) -> travessias bot 3 perfis N1-N20 -> capturas -> UI/loja/skins -> perf -> relatorio
- Bateria bot (20x3 perfis) a correr: saida docs/qa/full_game_review/bot/nXX_perfil.json (script no scratchpad bateria.sh; se cortar, relancar -- salta os ja' feitos). Ignorar n20.
- N1 normal (teste): 27 mortes, Ghorak nao derrotado (76 golpes sofridos), mortes concentradas x~1250-1570 e x~5000-5500. Bot e' "r2" -- verificar se e' limitacao do bot.
- LOJA: skin_shadowblade DUPLICADA em scripts/loja_catalogo.gd (l.101 e l.105, 2a sem splash) -- artefacto de merge. GRATIS_EM_DESENVOLVIMENTO=true no master.
- Inimigos por nivel (cena): N1 1, N2 1, N3 3, N4 8, N5 3, N6 3, N7 4, N8 3, N9 6, N10 1, N11 4, N12 6, N13 6, N14 8, N15 14, N16 7, N17 7, N18 6, N19 5. Regiao I = so' goblin+gosma. 7 comportamentos para ~30 especies.
- Movimento: salto ~122 px, queda 1.22x gravidade (pouco), corrida 240 c/ acel 0.1s. HITSTOP 10-24 ms (quase invisivel a 60 Hz).
- Capturas: tools/auditoria_fotos.gd (QA). N1 feito; N2-N19 em lote.
- CAPTURAS feitas N1-N19 (+folhas _folha_rX.jpg) e UI (ui/_folha_ui.jpg, _folha_hud.jpg).
- VISUAL: R1 = fundo pintado HD + terreno igual nos 5 niveis (mesmo castelo/aqueduto; laje com estalactites); faixa roxa lisa no 1/4 inferior (pantano). R2 = pixel-art castelo nas nuvens (nao le' como desfiladeiro), tijolo roxo unico. R3 = melhor identidade (sinos/vitrais/engrenagens) MAS N11 tem POLIGONOS PLACEHOLDER (sinos amarelos, plataformas lilas) e vazios pretos fora dos limites em N13. R4 = coeso mas 4 niveis quase iguais e Koliani pouco legivel no fundo vermelho.
- Estilos misturados: R1 pintado HD vs R2-R4 pixel-art com densidades diferentes (R3 parece upscale).
- UI: menu forte (key art); "DEVELOPER MODE" visivel; seletor mostra "ATUAL" (PT em jogo EN); nome R1 "Corrupted Forest" != canon "Floresta Sagrada"; loja mostra Shadowblade 2x + celulas vazias; texto da loja ~8 px a 720p (ilegivel em telemovel). HUD moderno limpo (retrato, barras, nivel, moedas) - bom.
- N10 = arena 900 px; N11 = sala ~1000 px sem doc autoral (nao reformulado).
- tools/shot_ui_9h11.gd pausa partido (no "Painel" nao existe -- ferramenta desatualizada).
- BOT v1 (tools/bot_humano_r2.gd) arrancava SEM habilidades -> dados de N3+ invalidos (guardados em bot_v1_sem_habilidades/). Bateria v2 = tools/bot_auditoria.gd (copia QA que da' dash N2+, pogo N3+, especial N4+, salto_duplo N6+, escalar N11+, projetil). Bot e' router horizontal: N11-N15 verticais nao sao medidos por ele.
- AUDIO: 4 sistemas de musica sobrepostos em scripts/musica.gd (bg_*.mp3 legacy, producao/*.wav, approved/, music/regions/). Loops: R1 168 s, R2 265 s, R3 96 s, R4 73 s (curto p/ N18/N19 longos). LUFS: regioes -11..-13; boss_01 -19.1 (10 dB abaixo do boss_04 -9.0 e 7 dB abaixo da musica de exploracao da R1 => anticlimax). MP3 em loop = risco de buraco por padding.
- SFX: mecanicas da R4 (pistao, valvula, jato, lava, piso quente) NAO tocam som nenhum. Duplicados wav/ogg/_v2/_v3 na raiz de assets/audio.
- SKINS: Fornalha/Abadia/Celestial = recolor de paleta (Celestial vendida como LENDARIA 250 V). Fornalha sem VFX proprios. Anjo: asas estaticas iguais em todas as poses. Shadowblade: baixo contraste em fundos roxos/azuis (R1/R2). Rolamento = sprite rodado. hurt 2 frames, morte 3 frames.
- TOQUE (ui/10_toque_n9.png, 1600x720): 6 botoes a direita; 2 com o MESMO icone "••" (especial/projetil ambiguos); cacho tapa ~1/3 direito (direcao de avanco); ataque e' o botao mais pequeno e esta' no meio. Fundo pixel-art com filtro suave (desfocado). Linhas guia do vento quase invisiveis.
- Estrutura: TODOS os niveis N1-N19 acabam num Guardiao/boss (R1: Ghorak, Morvanna, Rainha Aracnidea, Entrevane = bosses legados despromovidos). Cadencia previsivel.
- Seletor: "ATUAL" hardcoded em scripts/seletor_niveis.gd:384. Textos mec.* bons e concisos.
- Bot N2: 66 mortes em x2400-2700 (RaizCorredor). Doc do N2 admite RaizPerigo "por poligonos" e goblin legado (arte em falta).
- Combat Lab: "Koliani atravessa inimigos" (sem colisao de corpo) -- ver se continua.
- NOMES: world.catacombs = "Catacombs of the Abyss" para a REGIAO IV (canon: Fornalha). world.forest "Corrupted Forest" (canon: Floresta Sagrada). EstadoJogo.REGIOES ainda tem ids da campanha antiga.
- HISTORIA: sem prologo (New Game -> mapa). So' o boss N10 tem falas intro/fim; N5 e Vyrak (N15) mudos. Lore rica escrita nos clue.* (sistema retirado) -> invisivel.
- BOT v2 parcial: N16 25-46 s, N17 36-54 s, N19 35-48 s ate' a' porta com 0-5 mortes => R4 atravessa-se sem combater (elites nao selam porta). N1-N6 guardioes nao vencidos pelo bot (limitacao do combate do bot; TTK teorico Ghorak ~15 golpes). Hotspots = gates de dash sob teto (bot nao sabe) e raizes.
- N4 doc: "zona de recuperacao" 450 px vazia (espaco morto de design).
- VYRAK (N15): rig vyrak gerado por codigo (tools/gerar_chefes_anim.py), formas lisas -- MUITO abaixo da prancha region_03/boss_pack.png (figura alada ornamentada ouro/navy). Arena tambem generica. Fundo N15 com pixeis gigantes (upscale).
- N7: ~110+ mortes do bot em x4200-4400 nos 3 perfis = PlataformaCorrente dentro de vento pulsado 1600 sobre o vazio + elite, logo apos CheckCombinacao 4050 -> provavel pico de dificuldade (nivel "Develop").
- N10: bot nunca sobe o poco (y_min 615); N11: porta em 31 s (nivel curtissimo, nao reformulado).
- RELATORIO a ser escrito em docs/qa/full_game_review/RELATORIO_AUDITORIA_N1_N19.md
