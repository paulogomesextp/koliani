# KOLIANI — EXECUÇÃO 0: AUDITORIA TÉCNICA

Auditoria feita sobre o estado local de 2026-09-06. O repositório contém um lote de trabalho ainda não publicado; por isso, este relatório distingue o comportamento observado no código atual de validações que ainda precisam de execução em dispositivo. Nenhuma correção, remodelação ou alteração de conteúdo faz parte desta execução.

## A — EXECUTIVE TECHNICAL MAP

Koliani é hoje uma campanha linear de 100 níveis, agrupada visualmente em 20 regiões de cinco níveis. MenuInicial abre MapaMundo, que contém SeletorNiveis; este inicia Main, que carrega a cena escolhida, o jogador, HUD, pausa e controlos tácteis. Portas avançam linearmente e o mapa permite regressar a níveis desbloqueados.

As responsabilidades principais estão concentradas em três blocos grandes:

- EstadoJogo gere campanha, checkpoint, equipamento, economia, habilidades e gravação num único autoload.
- koliani.gd gere movimento, combate, animação, equipamento visual, efeitos, dano, respawn e integração de input. movimento.gd já isola bem a matemática central do movimento.
- DemonioBase, ChefeBase e ChefeGenerico oferecem uma base reutilizável para inimigos e cinco arquétipos de chefe, mas espécies, comportamentos e ataques continuam acoplados a scripts extensos e configuração por strings.

Os níveis 1–30 são maioritariamente cenas autorais. Os níveis 31–100 combinam cenas produzidas por gerador com uma jornada montada em runtime por gerador_corredor.gd. Atmosfera acrescenta fundo, parallax, cor, partículas e luz. Este pipeline permite grande volume, mas a fonte de verdade já não está clara: o gerador antigo pode sobrescrever cenas que receberam trabalho manual posterior.

O projeto está configurado para Godot 4.7.2, 1280×720, landscape, renderer Mobile e escala canvas_items/expand. Há presets Web, Android e Windows. Teclado, comando e toque partilham ações do InputMap; o toque injeta essas ações através de controlos_tacteis.gd.

O estado técnico atual não permite considerar a base pronta para uma remodelação ampla. Os verificadores geométricos passam, mas a suite principal falha com 89 erros por contexto de autoload e divergências de localização. Como a CI bloqueia os exports após essa suite, o pipeline não é neste momento uma prova fiável de build.

## B — KEEP / IMPROVE / REDESIGN / REPLACE / REMOVE

| Decisão | Sistemas | Razão e direção |
|---|---|---|
| KEEP | movimento.gd; InputMap partilhado; Textos com fallback inglês; Opcoes separado; Transicao; base de HUD/pausa; estrutura de 20 regiões | São fundações úteis, relativamente isoladas e compatíveis com mobile. Preservar comportamento enquanto se criam contratos mais claros à volta delas. |
| KEEP | DemonioBase/ChefeBase/ChefeGenerico como ponto de partida | Já fornecem patrulha, dano, estados, telegraph/action/recover e fases. Manter a API durante a extração gradual de comportamentos e ataques. |
| IMPROVE | câmara, toque, feedback de combate, áudio, UI responsiva | A base existe, mas faltam look-ahead e enquadramento por sala, opções de acessibilidade, safe areas e validação real em vários dispositivos. |
| IMPROVE | pipeline de níveis, Atmosfera e visibilidade | Acrescentar manifestos, dry-run, validação determinística e orçamento de nós/luzes. Reduzir jornadas que chegam a cerca de 40 000 px. |
| REDESIGN | EstadoJogo e save | Separar campanha persistente, estado temporário da sessão, checkpoint e definições. Introduzir versão, migração, escrita atómica, backup e validação. |
| REDESIGN | composição de Koliani e equipamento | Separar controlador, combate, apresentação e efeitos. Modelar arma/armadura como dados e visuais encaixáveis; o rig atual incorpora demasiado do equipamento no sprite. |
| REDESIGN | progressão dos 100 níveis | Hoje há chefe e habilidade com frequência excessiva no início e desbloqueio quase só linear. Alinhar regiões, provas de chefe, memórias, segredos, ranking e ritmo de habilidades com a nova visão antes de refazer conteúdo em massa. |
| REPLACE | gerador destrutivo dos níveis 31–100 | Substituir o script que reescreve cenas e parte do seletor por pipeline declarativo, versionado e não destrutivo. Cenas afinadas precisam de proveniência e proteção explícitas. |
| REPLACE | suite invocada diretamente sem contexto de projeto | Usar um runner que carregue autoloads e recursos como o jogo/CI realmente os carrega, mantendo testes puros onde isso for possível. |
| REMOVE | Hardcore do percurso de lançamento | Continua exposto e atravessa menu, save, Main e pausa, apesar de estar fora do âmbito aprovado. Remover depois de uma migração de save segura. |
| REMOVE | código dormente sem dono após inventário final | Diário, pistas e caminhos antigos de final/cinemática não devem coexistir indefinidamente com sistemas novos. Remover apenas depois de confirmar o conteúdo que será aproveitado. |

## C — SOURCE OF TRUTH / GENERATED CONTENT

| Área | Fonte atual | Conteúdo derivado | Risco |
|---|---|---|---|
| Campanha | EstadoJogo.NIVEIS e tabelas do seletor | mapa, nomes, desbloqueio e carregamento | Há listas paralelas; alterações podem divergir sem erro imediato. |
| Níveis 1–30 | cenas tscn e scripts específicos | nós de runtime adicionados por NivelComChefe | Mistura autoria e construção dinâmica, dificultando atribuir a causa de colisões. |
| Níveis 31–100 | gerar_niveis_31_100.py, cenas já geradas e afinações posteriores | 70 cenas e parte de seletor_niveis.gd | O gerador declara que sobrescreve tudo. O artefacto atual contém trabalho posterior e já não pode ser tratado como descartável. |
| Jornadas | gerador_corredor.gd e índice do nível | plataformas, perigos, checkpoints, luzes e percurso em runtime | A cena em disco não representa a geometria jogada; inspeção estática isolada é insuficiente. |
| Atmosfera | atmosfera.gd mais propriedades Atmosfera das cenas | parallax, céu, partículas, luz e grade | afinar_atmosfera.py reescreve blocos de propriedades; afinação manual pode desaparecer. |
| Arte de terreno | packs de origem e geradores | texturas de corpo/topo/base/lateral e decorações | O jogo usa 20 regiões, mas os geradores materiais cobrem apenas cerca de seis famílias e são reutilizados. |
| Tradução | assets/i18n/en.json como base | cinco catálogos traduzidos e textos aplicados em runtime | pt tem chaves extra e faltas; defaults visuais em tscn podem esconder lacunas durante inspeção. |
| Web | web/head_pwa.html e gerar_head_web.py | conteúdo inserido em export_presets.cfg | Alterar apenas o preset perde-se na próxima geração. |

Antes de qualquer remodelação, criar um manifesto único por nível/região com cena, origem, versão de gerador, seed, chefe, recompensas e afinações. O gerador deve produzir numa pasta temporária, comparar diferenças e recusar a sobrescrita de artefactos marcados como autorais.

## D — TOP RISKS BEFORE REDESIGN

1. A suite principal tem 89 falhas e a CI depende dela; qualquer grande alteração perderia uma rede de segurança essencial.
2. O gerador 31–100 pode apagar afinações, chefes e arte recente porque não distingue conteúdo gerado de conteúdo assumido como autoral.
3. O save não tem versão, migração, escrita atómica ou backup. Mudanças de progressão podem corromper ou reinterpretar campanhas existentes.
4. EstadoJogo e koliani.gd concentram responsabilidades demais. Alterações visuais, de combate ou progressão têm raio de impacto amplo.
5. A geometria efetiva de 31–100 nasce em runtime. Validar apenas tscn não prova alcance, enquadramento, memória ou desempenho.
6. Jornadas crescem até cerca de 40 000 px e instanciam muitos elementos visuais e físicos. O custo em mobile é desconhecido: NEEDS RUNTIME VALIDATION.
7. O dimensionamento de interface mistura anchors com offsets fixos e não usa safe area do sistema. Recortes em notch, barras e proporções extremas são prováveis: NEEDS RUNTIME VALIDATION.
8. As recompensas do baú de chefe não persistem uma identidade de abertura. Recarregar ou repetir permite acumular essência/rank.
9. ChefeBase limita a escala de dificuldade ao intervalo 0–29; os níveis posteriores deixam de evoluir pelo mesmo modelo.
10. A campanha e narrativa atuais ainda referem Aurora, enquanto a visão aprovada aponta para Elara. Refazer arte/texto antes de fixar o cânone produziria retrabalho.

## E — KNOWN BUG DIAGNOSIS

### Nível 12 — ecrã preto

O problema não foi reproduzido como ecrã totalmente preto no estado atual. Torre_dos_Ventos.tscn abre headless sem erro de compilação e uma captura OpenGL 1280×720 foi gerada. A imagem é muito escura: luminância média 33,6/255, com 60,9% dos píxeis abaixo de 32; isto pode ser percebido como ecrã preto em certos ecrãs, mas existe imagem renderizada.

A causa histórica mais suportada pelo código é a cobertura do fundo/parallax numa jornada longa. atmosfera.gd documenta e corrige um caso em que o parallax saía da câmara e deixava canvas negro; gerador_corredor.gd chama a atualização de extensão depois de construir a jornada. A cena atual não contém ZonaEscuridao e os valores de ambiente não explicam sozinhos um frame totalmente negro.

Próxima validação: iniciar o nível pelo menu com save real, testar arranque, morte e reload nas proporções 16:9, 19.5:9 e tablet, e comparar Mobile/GL. Automatizar captura em vários pontos da jornada com limiar de luminância. Até essa execução, a causa exata no dispositivo é NEEDS RUNTIME VALIDATION.

### Nível 5 — checkpoint preso

O verificador atual passa o índice 4 e encontrou três checkpoints gerados com saída lateral. Há também defesas em runtime: o gerador reposiciona/remove checkpoints sob teto baixo e o respawn tenta deslocar Koliani para fora de colisões.

Esse resultado não fecha o bug. verifica_spawn_livre.gd seleciona apenas nós cujo nome começa por JornadaCheck_; Coracao_da_Floresta.tscn contém CheckInicio, CheckMeio e CheckReencontro autorais, que ficam fora do teste. Plataformas móveis e o instante do respawn também não entram na análise estática. A hipótese principal é um checkpoint autoral ou dinâmico sob geometria superior/temporal, seguido por respawn dentro do pocket de colisão.

Próxima validação: enumerar todo o grupo checkpoints, simular morte/respawn em cada ponto, esperar um ciclo completo das plataformas e provar que o jogador consegue mover-se e saltar para uma zona livre. Reproduzir também com o save original, se disponível. Causa exata: NEEDS RUNTIME VALIDATION.

### SalaLabirinto

SalaLabirinto tem geometria fixa em Z, duas alavancas com o mesmo requisito, portão, espinhos e serras com duração aleatória não semeada. A integração foi pausada depois de colisão com a parede esquerda da CascaMasmorra e softlocks; o gerador ativo já não referencia esta sala. Assim, é conteúdo dormente, não um componente seguro para reativar.

O problema estrutural confirmado é a ausência de um contrato de encaixe e de uma prova de alcançabilidade. A validação proposta tem duas camadas: gerar uma descrição pura e determinística da geometria e construir um grafo navegável com envelopes reais de salto/dash; depois provar entrada → alavanca A/B → saída nas duas ordens. Um bot de física deve confirmar a prova para seeds e timings definidos, incluindo serras e portão. Não reintroduzir a sala enquanto esses invariantes não passarem.

## F — VISUAL CONSISTENCY BASELINE

O projeto já fixa nearest filtering, renderer Mobile e uma direção gótica de luar, magenta e roxo. A leitura global é reforçada por CanvasModulate, luzes, partículas, vignette e fundos regionais. Porém, consistência técnica não equivale ainda a consistência visual.

- Koliani usa atualmente o rig Shadowblade, montando SpriteFrames em runtime a partir de strips. A célula observada é aproximadamente 51×64 px, com colisão 20×44 e alvo visual perto de 59 px.
- Inimigos normalizam altura visual perto de 48 px; chefes apontam para cerca de 100×110 px. A diferença dá hierarquia, mas falta uma tabela oficial de escala, pivô, hitbox e sombra.
- CascaMasmorra usa grelha efetiva de cerca de 32 px; fontes artísticas misturam células de 16 e 32 px e plataformas aceitam dimensões livres. Isto favorece densidade e silhueta inconsistentes.
- As 20 regiões reutilizam um conjunto menor de famílias materiais. Cor, partículas e fundos diferenciam regiões mais do que terreno e adereços próprios.
- Arma e armadura têm dados de gameplay, mas o rig atual incorpora grande parte da aparência; a troca visual modular ainda não está resolvida.
- Não há uma regra única para densidade de luzes/partículas, contraste jogável, contorno interativo e separação entre foreground e colisão.

Baseline recomendado para a futura art bible: grelha mundial 32 px; tabela por família de personagem com altura, pivô e caixa; paleta e faixa de luminância por região; orçamento de detalhe/luzes; linguagem fixa para perigo, interação, segredo e objetivo; e matriz de equipamento por rig. A aparência final e a legibilidade em ecrã pequeno são NEEDS RUNTIME VALIDATION.

## G — GAME FEEL BASELINE

Koliani já tem um conjunto expressivo: corrida com aceleração, coyote time de 0,10 s, buffer de salto de 0,12 s, corte de salto, double jump, air dash, wall slide/jump/climb, mantle, grapple, pogo/stomp, dash e roll. O combate inclui combo de quatro golpes, buffer, hitstop, tremor, knockback, invulnerabilidade, magia e escudo frontal.

Os valores centrais são coerentes para um platformer rápido: corrida 240, salto 470, dash 620 por 0,16 s e câmara com zoom 1,4 e smoothing 8. movimento.gd é uma boa base testável. A integração, porém, depende de muitos booleanos e temporizadores no script principal em vez de uma máquina de estados explícita. Isso aumenta combinações inválidas entre dash, roll, parede, grapple, dano e ataque.

A câmara compensa proporções e suporta tremor, mas não tem um contrato global para look-ahead, limites por sala, zonas verticais e enquadramento de chefe. O conforto real do smoothing, impacto, vibração e controlos tácteis é NEEDS RUNTIME VALIDATION.

Nos primeiros cinco níveis, o código atribui escudo, air dash, wall climb, quebra de paredes e projétil, além de double jump inicial. Este ritmo introduz sistemas mais depressa do que permite aprofundá-los. Há tutorial contextual e chefe frequente, mas o atrito, tempo de conclusão e retenção dos primeiros 10–15 minutos são NEEDS RUNTIME VALIDATION.

## H — UI / UX / LOCALIZATION BASELINE

O percurso atual cobre menu, mapa/seletor, HUD, toque, pausa, opções, equipamento e santuário. Faltam percurso de primeira execução, abertura narrativa, escolha/explicação de dificuldade, loading/resultados consolidados e créditos/final integrados. Hardcore ainda aparece no lançamento.

O mapa apresenta 100 cartões em 20 tabs regionais; funciona como seleção linear, mas não comunica ainda a estrutura de duas etapas/objetivos regionais da nova visão. Teclado e comando têm foco em vários ecrãs, sem remapeamento e sem prova completa de navegação só por comando. Toque adapta medidas, mas safe areas e aparelhos extremos são NEEDS RUNTIME VALIDATION.

A localização usa inglês como base e cobre en, de, es, fr, pt e zh. No estado local, en/de/es/fr/zh têm 659 chaves e pt tem 696; comparado com en, pt tem cinco faltas e 42 extras. A suite também acusa divergências de nomes de chefes. Não há deteção de locale do sistema nem confirmação de idioma na primeira execução. Alguns textos Web e labels como CHECKPOINT/SKILL permanecem hardcoded.

Não existe um pacote consistente de acessibilidade para tamanho/opacity dos botões, intensidade de tremor, flashes, vibração, tamanho de texto e contraste de perigos. A preferência Web reduced-motion afeta apenas o ícone de orientação.

## I — SAVE / PROGRESSION BASELINE

EstadoJogo escreve um único user://progresso.json com nível, máximo desbloqueado, checkpoint Vector2, vidas, habilidades, pistas, conclusões, essência, melhorias, inventário, equipamento e campos Hardcore. Opções vivem em user://opcoes.json.

Pontos positivos: valores ausentes recebem defaults; recompensas de conclusão de nível são protegidas pela lista concluidos; equipamento evita duplicados; o caminho user:// é multiplataforma.

Lacunas críticas:

- Sem save_version, migração, schema, limites, escrita temporária/rename ou backup.
- Campanha persistente e estado temporário/checkpoint partilham o mesmo documento.
- Coordenadas absolutas de checkpoint sobrevivem a mudanças de geometria da cena.
- Falha de parse é ignorada sem recuperação comunicada ao jogador.
- Baús de chefe guardam apenas _aberto em runtime; essência e rank podem ser repetidos após reload/replay.
- Não existem modelos persistentes para memórias, segredos, desafios, melhor tempo, rank ou conclusão regional.
- Hardcore tem comentários e campos contraditórios: guardar retorna cedo nesse modo, apesar de o dicionário conter dados Hardcore.

Antes de mudar progressão, definir um schema versionado com IDs estáveis de nível, checkpoint e recompensa. A migração deve preservar campanhas existentes e converter coordenadas frágeis em IDs de spawn.

## J — TEST / BUILD / PLATFORM BASELINE

Validações executadas no Godot 4.7.2:

- Torre_dos_Ventos carregou headless e produziu captura OpenGL; apenas avisos de recursos/objetos retidos.
- verifica_spawn_livre.gd passou a amostra de oito níveis, incluindo o índice 4, com a limitação de nomes descrita na secção E.
- verifica_jornada.gd percorreu os 100 níveis sem falha geométrica declarada.
- verifica_alcance_todos.gd encontrou zero portas inalcançáveis e um elemento fora dos limites.
- tests/run_tests.gd terminou com código 1 e 89 falhas. O runner direto não resolve autoloads como Som, EstadoJogo e Textos em vários scripts; há também divergências de i18n/nome de chefes.

A CI usa Godot 4.7.2 e só exporta depois dos testes. Tem jobs Web, Android debug, Windows e Pages; estes não comprovam o lote local enquanto a suite falha. Os presets cobrem Web, Android ARMv7/ARM64 e Windows. Não existem presets iOS/macOS nem integração Steam. A versão do preset Android (0.1.0) diverge da versão do projeto (0.15.15).

Web inclui PWA, desbloqueio de áudio e aviso de orientação. Android não tem validação observável de safe area; iOS não tem pipeline. Gamepad e teclado estão mapeados, mas navegação completa, desconexão/reconexão e glyphs são NEEDS RUNTIME VALIDATION. Perfil de 60 fps, memória, tempo de carregamento e tamanho de export em aparelhos alvo são NEEDS RUNTIME VALIDATION.

## K — QUICK WINS

1. Corrigir o contexto do runner de testes e voltar a tornar a CI uma barreira real.
2. Acrescentar ao verificador todos os nós do grupo checkpoints, independentemente do nome.
3. Bloquear o gerador 31–100 por defeito e exigir dry-run/diff antes de sobrescrever cenas.
4. Introduzir save_version, backup e escrita atómica sem ainda alterar a progressão.
5. Persistir IDs dos baús/recompensas de chefe reclamados.
6. Ocultar a entrada Hardcore do lançamento e preparar migração dos campos antigos.
7. Detetar locale do sistema e pedir confirmação de idioma na primeira execução.
8. Uniformizar as chaves i18n e mover CHECKPOINT/SKILL e textos Web para catálogos.
9. Adicionar opções de tremor, flashes, vibração e escala/opacity dos controlos tácteis.
10. Criar uma cena de benchmark representativa com contagem de nós, luzes, partículas, memória e frame time.

## L — RECOMMENDED EXECUTION PLAN

1. Restaurar validação fiável e fechar os três riscos estruturais conhecidos: nível 12, todos os checkpoints e contrato da SalaLabirinto.
2. Congelar fontes de verdade: manifesto de campanha/regiões, IDs estáveis e pipeline gerado não destrutivo.
3. Versionar e migrar save/progressão, separando campanha, sessão e definições.
4. Definir contratos globais de gameplay: estados do jogador, dano, ataques, câmara, input e acessibilidade.
5. Fixar a art bible técnica e budgets mobile antes de produzir novos assets.
6. Modularizar Koliani e equipamento sem alterar ainda o feel aprovado.
7. Construir uma vertical slice completa da Região 1, níveis 1–5, incluindo UI, áudio, save, chefe e métricas.
8. Fazer playtest em PC, Web e aparelhos mobile alvo; corrigir onboarding, feel, legibilidade e performance.
9. Aplicar o padrão validado aos níveis 6–20 e fechar o primeiro domínio.
10. Remodelar por lotes: níveis 21–40, 41–60, 61–80 e 81–100, com validação e playtest por lote.
11. Consolidar UI/UX, primeira execução, acessibilidade, áudio regional e meta-progressão.
12. Balancear economia, ranks, segredos, memórias, desafio e replay; só então preparar release e novas plataformas.

Esta ordem antecipa testes, save e fontes de verdade porque todos os lotes posteriores dependem deles. A vertical slice de cinco níveis deve provar o padrão antes de o multiplicar pelos restantes 95.

## M — NEXT CODEX TASK

**Execução 1 — Baseline estrutural e validação fiável**

Objetivo: obter uma suite verde e reproduções determinísticas dos três problemas conhecidos, sem iniciar a remodelação visual ou de conteúdo.

Âmbito:

1. Fazer tests/run_tests.gd correr com o mesmo contexto de autoload do projeto e corrigir apenas o harness/chaves de expectativa necessárias para eliminar falsos erros.
2. Criar um teste de checkpoints que percorra todos os nós do grupo, simule morte/respawn e prove saída física no nível 5.
3. Capturar o nível 12 em pontos e proporções definidos, após entrada normal, morte e reload, registando luminância e cobertura de Atmosfera.
4. Extrair uma descrição determinística de SalaLabirinto e validar entrada, ambas as ordens de alavancas e saída; manter a sala desativada.
5. Fazer a CI executar estes checks antes de qualquer export.

Critério de conclusão: suite principal sem falhas, três validadores reproduzíveis com logs claros, causa confirmada ou explicitamente marcada NEEDS RUNTIME VALIDATION para cada bug, e nenhuma alteração de gameplay, arte ou níveis fora da correção estrutural estritamente demonstrada pelos testes.
