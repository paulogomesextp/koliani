# Catálogo de mecânicas — a lista do Paulo (4 set 2026)

> O Paulo deixou este catálogo para escolhermos daqui **na próxima sessão**.
> Não é um plano nem uma lista de tarefas: é o menu. Antes de implementar
> qualquer linha, ele define a prioridade.

Quando se pegar numa entrada, marcar aqui com `✅` e apontar onde ficou
(ficheiro/cena), para não se fazer duas vezes.

---

## Chefes

- ✅ Padrões de ataque reconhecíveis — `chefe_base.gd`: telégrafo + EXPOSTO por arquétipo
- ✅ Fases progressivas — `chefe_base.gd` `fases`; Zeriko tem 4, o Arauto 3
- ✅ Pontos fracos — o núcleo roxo — está no desenho de todos os rigs e no `receber_dano`
- ✅ Janelas de vulnerabilidade — estado EXPOSTO depois de cada investida
- ✅ Arena que muda durante a luta — `chefe_ignivar` (derrete), `chefe_acougueiro_real` (cada golpe muda a arena)
- ⬜ Uso obrigatório de habilidade ensinada na fase — nenhum chefe exige a habilidade do próprio nível
- ⬜ Boss de perseguição
- ⬜ Boss sem combate direto, focado em fuga — o mais perto é a `ameaca_que_avanca.gd` (nível 65), que não é chefe
- ✅ Boss puzzle — `chefe_freira_negra`: manter velas acesas; `chefe_voltaris`: pára-raios
- ✅ Boss com minions — `chefe_rainha_aracnidea`, `chefe_carcereiro` (abre celas)
- ⬜ Boss com cronómetro
- ✅ Segunda fase inesperada — `chefe_primeiro_prisioneiro` (vira energia), `chefe_vyrak` (destrói a torre)
- ➖ Boss cooperativo — não há segundo jogador

## Coletáveis, objetivos e recompensa

- ✅ Moedas · Gemas · Frutas · Fragmentos — Essência (`essencia.gd`) — moeda que não se perde na morte
- ✅ Itens secretos · Vidas extras · Cura · Energia · Munição · Chaves — `coletavel.gd` + alcovas; o tiro é ilimitado, portanto não há munição
- ⬜ Power-ups · Itens cosméticos · Personagens desbloqueáveis — há equipamento (15 armas + 15 armaduras), não há cosméticos nem personagens
- ✅ Fases secretas · Rotas alternativas — câmara `bifurcacao` e as alcovas; fases secretas não
- ⬜ Colecionáveis por tempo limitado
- ✅ Itens que exigem desafio de precisão — a recompensa fora do caminho crítico, em cada nível feito à mão
- ⬜ Ranking de fase · Medalhas por tempo · Nota por mortes — é um dos quatro que o Paulo pôs no painel como ESTRUTURA, à espera de decisão
- ✅ Percentagem de conclusão — progresso por região no MapaMundo e no SeletorNiveis
- ⬜ Missões secundárias · Desafios opcionais
- ⬜ New Game Plus — está no painel, à espera de decisão dele

## Mobilidade

- ✅ Gancho/grappling hook — `ponto_gancho.gd` — nível 53
- ✅ Balançar em cordas · Balançar em barras · Zipline — o balanço é o do gancho; barras e zipline não
- ✅ Planar · Voar temporariamente · Jetpack — habilidade `planar` — nível 63
- ✅ Queda lenta · Paraquedas — é o mesmo planar
- ✅ Teleporte curto — `portal.gd` (fixo); teleporte à vontade só os chefes têm
- ⬜ Troca de posição com objeto/inimigo — o Naga Zeraph troca com estátuas, ela não troca com nada
- ✅ Recuo causado por armas — `koliani.gd`: o golpe empurra-a (`_pop`)
- ⬜ Transformação para formas com mobilidade diferente

## "Game feel"

- ✅ Coyote time: saltar poucos instantes após sair da plataforma — `movimento.gd` (lógica pura, com teste)
- ✅ Jump buffer: registar o botão de salto antes de tocar no chão — `movimento.gd`
- ✅ Perdão de colisão em bordas — agarrar borda em `koliani.gd`
- ✅ Controlo aéreo · Velocidade máxima no ar — `movimento.gd`
- ✅ Queda mais rápida que a subida · Fast fall — gravidade assimétrica em `movimento.gd`
- ✅ Pulo automático ao tocar numa superfície — trampolins (`trampolim.gd`) e o pisão que encadeia
- ⬜ Assistência de mira para ataques no ar
- ⬜ Câmara que acompanha velocidade e direção — a câmara só suaviza a posição (`position_smoothing`)
- ✅ Pequena pausa de impacto ao aterrar ou acertar — hitstop em `koliani.gd`
- ✅ Vibração e efeitos de partículas para feedback — `camera_tremor.gd` + `impacto.gd`; vibração do telemóvel não

## Plataformas e terreno

- ✅ Estáticas · móveis · em loop · circulares · que seguem trilhos — `plataforma.gd`, `plataforma_flutuante.gd`, `plataforma_corrente.gd`
- ✅ Que caem após serem pisadas · temporizadas — `plataforma_quebra.gd`, `plataforma_ritmada.gd`
- ✅ Que desaparecem e reaparecem — `plataforma_espectral.gd`, `plataforma_olhar.gd`
- ✅ Que se movem ao ativar um interruptor — `alavanca.gd` + `porta_trancada.gd`
- ⬜ Que sobem/descem com peso
- ✅ Frágeis ou quebráveis — `parede_fragil.gd`, `plataforma_quebra.gd`
- ✅ Nuvens atravessáveis por baixo — `plataforma.gd`: one-way
- ✅ De salto · pegajosas · escorregadias — trampolim e `zona_gelo.gd` (atrito); pegajosas não
- ✅ Que queimam, eletrocutam ou causam dano — `chao_quente.gd`, `fogo.gd`, `raio_tempestade.gd`
- ✅ Que giram · inclináveis — `plataforma_roda.gd` — níveis 56 e 78
- ✅ Elevadores · Portas automáticas — `tumulo_elevador.gd`, `porta.gd`
- ✅ Paredes destrutíveis — `parede_fragil.gd`
- ✅ Blocos empurráveis · que caem · que surgem/desaparecem · que mudam de posição — `pedra_queda.gd` e `sala_reescreve.gd`; empurráveis é o que falta
- ✅ Terreno deformável · Pontes que desabam — `plataforma_quebra.gd` faz a ponte; terreno deformável não

## Obstáculos e perigos

- ✅ Buracos e quedas fatais — líquido mortal em toda a jornada
- ✅ Espinhos · Serras circulares · Lâminas móveis · Prensas · Pêndulos — `espinhos`, `serra`, `guilhotina`, `parede_movel`, `pendulo_lamina`
- ✅ Bolas de ferro — `ariete.gd`
- ✅ Chamas · Lava · Ácido · Gelo perigoso · Eletricidade · Raios — `fogo`, `agua_venenosa`, `gota_acida`, `zona_gelo`, `raio_tempestade`
- ✅ Projéteis · Canhões · Flechas · Lasers — `torreta.gd` + os tiros dos chefes
- ✅ Armadilhas ativadas por proximidade · Armadilhas de tempo — `armadilha.gd`, `teia_prende.gd`
- ✅ Piso que desaba — `plataforma_quebra.gd`
- ✅ Água que afoga · Correntes de água · Areia movediça — `zona_sem_ar.gd` (nível 38), `corrente_lateral.gd`; areia movediça não
- ⬜ Neve ou areia que afunda
- ✅ Escuridão limitada por luz · Névoa ou veneno — `zona_escuridao.gd`, `zona_estado.gd` (veneno e frio)
- ✅ Inimigos patrulheiros · voadores · que perseguem · que atacam à distância — `demonio_base.gd` (`so_tiro`, voo, perseguição)
- ✅ Inimigos invencíveis que forçam fuga — `ameaca_que_avanca.gd` — nível 65
- ✅ Perseguições por uma ameaça ambiental — a mesma

## Combate

- ✅ Pular sobre inimigos — o pisão que encadeia (`koliani.gd`)
- ✅ Corpo a corpo · combos · carregado · aéreo · descendente · giratório — combo de espada + ataque aéreo; carregado e giratório não
- ✅ Chute · Soco · Espada · Martelo · Chicote — espada e martelo estão no equipamento; chute/soco/chicote não
- ✅ Arma de fogo · Projéteis mágicos · Bombas · Granadas · Arremesso de objetos — tiro roxo ilimitado + kamehameha; bombas e granadas não
- ✅ Bloqueio · Parry · Esquiva · Rolamento · Contra-ataque — escudo e rolamento; **parry e contra-ataque não**
- ✅ Ataques elementais: congelar, queimar, empurrar, atordoar — estados queimar/sangrar/atordoar em `demonio_base.gd`
- ✅ Usar inimigos como plataformas · como projéteis — como plataforma, no pisão; como projétil não
- ✅ Vida, escudo e invencibilidade temporária — `koliani.gd`

## Puzzles e progressão

- ✅ Interruptores de pressão · Alavancas · Botões temporizados — `alavanca.gd`; botões temporizados não
- ✅ Chaves e portas trancadas · Cartões de acesso — `porta_trancada.gd` ligada à alavanca; chaves de inventário não
- ⬜ Objetos para colocar em pedestais · Mover caixas para alcançar locais — nada empurrável no jogo
- ✅ Espelhos e reflexão de luz · Circuitos elétricos · Alterar fluxo de água — `espelho.gd` e `para_raios.gd`; fluxo de água não
- ✅ Alterar gravidade · Manipulação do tempo · Pausar ou rebobinar objetos — `zona_gravidade.gd`, `placa_gravidade.gd` e o mundo invertido (67); tempo não
- ⬜ Alternar entre dimensões · Alternar entre dia/noite — a Praça do Eclipse alterna cenário, mas é decoração
- ⬜ Troca de personagens · Personagens com habilidades complementares — está no painel, à espera de decisão dele
- ⬜ Transformações
- ➖ Habilidades desbloqueadas que abrem áreas antigas · Metroidvania/backtracking — decidido: não é roguevania, é campanha por níveis
- ✅ Árvores de habilidades — as 6 Melhorias permanentes do Santuário (`melhorias.gd`)
- ✅ Itens permanentes de mobilidade · Poderes temporários por fase — as habilidades da campanha; e a `zona_sem_poder.gd` (98) tira uma por sala

## Estrutura de fase

- ✅ Tutorial integrado na fase · Checkpoints — fogueiras; **o tutorial da mecânica nova é pedido dele, ainda por fazer**
- ✅ Vidas limitadas ou mortes ilimitadas · Reinício instantâneo — vidas + hardcore com save próprio
- ✅ Salas curtas de desafio — é o que a jornada faz: uma câmara de cada vez
- ✅ Fases lineares · Mundo aberto ou semiaberto · Mapa por nós · Hub central — lineares + MapaMundo por nós; hub não
- ✅ Fases com múltiplas rotas · Áreas secretas — `bifurcacao` e as alcovas
- ✅ Fases verticais · de perseguição · de fuga · subaquáticas · no ar · em veículo — verticais (torre/poço), fuga (65), ar (38); subaquática e veículo não
- ⬜ Autoscroll · Speedrun · Time attack · Boss rush — nenhum
- ⬜ Desafio pós-jogo — o hardcore é o mais perto
