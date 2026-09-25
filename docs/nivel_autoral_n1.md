# N1 -- Floresta Corrompida (nivel AUTORAL, TEACH)

Estado: **PRONTO PARA PLAYTEST DO GM -- NAO LOCKED** (26 set 2026, sem push). Cena: `scenes/levels/Floresta_Putrefata.tscn`.

## Arquitectura (padrao para N2-N5)
- `nivel_com_chefe.gd` ganhou 2 exports opt-in (defaults = comportamento antigo, os outros 99 niveis nao mudam):
  `checkpoints_autorais` (a poda por distancia `_reduzir_checkpoints` nao corre e nao se acrescenta checkpoint
  perto do chefe) e `estreia_x_autoral` (onde entra em ecra a mecanica estreada; INF = a entrada -- o N1 mantem o
  aviso de "saltos" logo a entrada).
- A cena N1 leva `corredor = false`, `alongar_plataformas = false`, `candeeiros = false`,
  `checkpoints_autorais = true`. **Sem jornada procedural, sem `gerador_corredor.gd`, sem `if level_id == 1`.**
- Ghorak = no `Guardiao` (o guardiao sela a porta e abre-a quando cai; nao e `Chefe` regional: nao grava boss, nao
  da bau, nao mexe no contrato do N5).
- Teste: `teste_n1_autoral` em `tests/run_tests.gd` (mordido por mutacao: afastar `ChaoRaizes` 100 px falha).
- Bot: `tools/bot_gauntlet.gd ... <cena> <seg> 0 sem_skills` (4.o argumento = nenhuma habilidade).

## Mapa (x do mundo; topo do chao = y 665; salto F1 ~128 px)
| # | Seccao | x | Ensina | Conteudo |
|---|---|---|---|---|
| 1 | Abertura / respiracao | 0-900 | correr, ler o mundo | chao seguro, fogueira `CheckAbertura` (380), nada ataca |
| 2 | Primeiro platforming | 990-1960 | salto, **salto variavel**, controlo aereo | 4 plataformas, vaos 90-100 px, subidas 20-40 px |
| 3 | Primeiro hazard | 2070-2870 | ler telegrafo, esperar/saltar | `CheckRaizes` (2150); 2 `RaizPerigo` desfasadas (2450, 2660), 380 px seguros antes e 210 depois |
| 4 | Primeiro inimigo | 2980-3670 | combate basico | goblin aprendiz isolado (patrulha 110 px) em 690 px; rota alta OPCIONAL (3040-3570, subidas 60 px) com cache de Essencia (segredo) |
| 5 | Combinacao leve | 3780-4740 | platforming + hazard | 2 plataformas com raiz cada + `Descanso` (4480) com `CheckDescanso` (4560) |
| 6 | Ghorak (mini-boss) | 4850-5740 | leitura de inimigo grande | arena 890 px, sem raizes de cenario; Ghorak semeia as suas |
| 7 | Fecho | 5850-6370 | dominio | 2 degraus (subida 45 px), cache de Essencia, Porta (6290, selada ate o Ghorak cair) |

Checkpoints (3, autorais): depois de aprender (380), depois do platforming e antes do hazard (2150), antes do Ghorak
(4560, a 860 px da arena: repetir so' o Ghorak + uma caminhada curta; a luta em si nao e' trivializada).
Todos os vaos <= 125 px (plano) / <= 110 px (a subir); subidas <= 60 px; mantle nunca necessario.

## Ghorak -- funcao exata (redesenhado a 26 set 2026, apos o 1.o playtest: "demasiado passivo")
Mini-boss de FECHO. Loop: **CASCA** fora das janelas (so' 5 % do dano passa, sem recuo, som `bloqueio` + faiscas
verdes; sprite mais baco) e **EXPOSTO** (nucleo purpura aberto, frame 3, brilho a pulsar, pisca 0,4 s antes de
fechar, tom quente) -- so' ai' o golpe entra por inteiro. Sem stun-lock: bater nao interrompe nada.
| Ataque | Telegraph (SEE -> HEAR) | Execucao | Depois |
|---|---|---|---|
| BAQUE | pose bracos erguidos + aura corrupcao 0,8 s, som `olho_carregar` grave | salta e cai: onda rasteira a <= 280 px, **so' magoa no chao** (salta-se) | **EXPOSTO ~1,8 s** (fase 2: ~1,4 s) |
| RAIZES | pose 0,6 s + som `praga`; racha visivel no chao 1,15 s antes de irromper | zona de 3 raizes a volta da Koliani (fase 2: +2.a zona do lado oposto, mais tarde) | recovery 0,95 s SEM janela (movimento, nao dano) |
| CARGA | pose + aura 0,9 s + `grito`; o rumo trava aos 60 % do aviso | investe 460 px a 560 px/s (dano 24 x alivio) | **EXPOSTO ~1,4 s** (fase 2: ~1,0 s) |
| CURTO | 0,5 s + `garra`, so' se a Koliani estiver a < 110 px (cooldown 3,5 s) | golpe curto a frente | recovery 0,45 s sem janela (pune quem cola ao corpo) |
Fase 1: padrao BAQUE, RAIZES, BAQUE, CARGA. **Fase 2 (< 50 %)**: mesmo vocabulario encadeado -- RAIZES+CARGA,
BAQUE+RAIZES (as raizes marcam-se a meio da janela: a ganancia paga-se), CARGA, BAQUE; avisos x0,85, janelas
x0,8/0,7, rugido de 0,9 s a entrar. Nada arranca fora do campo visual (`Som.em_vista`).
Vida: base 250 -> **700** (x3,2 x0,52 = 1165). NAO e' sponge: o combo da Koliani da' ~250 de dano em ~1 s
(0,85+1+1,25+1,9 x 50), por isso a vida so' faz sentido com a casca fechada 80 % do tempo.
**Medido (bot perfeito, Koliani invulneravel, `teste_ghorak_n1`)**: TTK 18,9 s lendo as janelas (4 janelas:
1,8 / 1,2 / 0,98 / 1,43 s; media 1,36 s; fase 2 aos 7,5 s); so' a bater na casca: NAO morre em 150 s.
Estimativa de jogador real (60 % de eficiencia): ~30-40 s. **Janela media (1,4 s) e' menor que os 2-3 s pedidos**:
mais tempo = mais de metade da vida numa abertura; afinar no playtest (`dur_exposto`, `dur_carga_exposto`, vida).

### Rework 2 do Ghorak (26 set 2026, apos "impossivel de matar")
Causa provada: a janela pedia a Koliani ao pe' do corpo e o CONTACTO tirava-lhe vida (agora `_ao_tocar` nao magoa na janela); janelas
curtas (1,4 s) e vida alta (1165). Novo ciclo fixo: **atacar -> ficar EXPOSTO (aberto, parado, sem magoar) -> atacar ...**.
TODO ataque acaba numa janela: BAQUE 2,6 s, RAIZES 1,5 s (as raizes irrompem a meio da janela: bate-se e desvia-se), CARGA 2,0 s
(fase 2: x0,8). Padrao F1: BAQUE, RAIZES, CARGA, BAQUE; F2: BAQUE+RAIZES, CARGA, RAIZES, BAQUE+RAIZES. Fase 2 so' arranca fora das janelas.
Vida base 550 (x3,2 x0,52 = 915). Medido (bot a 2 golpes/s so' nas janelas): TTK 20 s, 4 janelas de ~2,1-2,6 s; so' na casca: nao morre em 150 s.
Teste exige: janelas 0,7-3,4 s, ataques <= janelas+1, fase 2, porta abre, nada preso.

## Assets
- Aprovados e usados: kit 9C/`l1_hybrid_9h12e` (terreno, props, fundo panorama 08, corrupcao, nevoa), Koliani golden set,
  Ghorak (rig do motor de chefes).
- **APPROVED ART ASSET MISSING**: (1) `RaizPerigo` continua desenhada por poligonos verdes (a prancha nao tem raizes;
  ja registado na 9G); (2) goblin (inimigo da seccao 4) e' o pixel-art legado -- falta prancha de inimigos (9D);
  (3) animacao de mantle; (4) o panorama tem uma costura horizontal no topo do ecra (pre-existente).

## Validacao
Suite completa PASS; 8 verificadores CI exit 0; bot sem habilidades chega a porta em 26 s (modo dev, sem dano, sem
combate); save real intacto (SHA). Capturas em `docs/qa/n1_autoral/`. Duracao: **medida so' a travessia (26 s)**;
estimativa numa primeira passagem com hazard, goblin e Ghorak: ~2-3 min (abaixo do alvo de 3-5: decidir no playtest).
Faltam a validar por humano: telegraph/legibilidade, offscreen (SEE->TELEGRAPH->HEAR), Ghorak, ritmo, arte.
