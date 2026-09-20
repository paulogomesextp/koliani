class_name Koliani
extends CharacterBody2D
## A personagem principal. A física real (colisões, `move_and_slide`) vive
## aqui; o "sentir" do movimento está em `movimento.gd` (lógica pura,
## testável). Ataque leve, dash e rolamento são o mínimo para a pegada
## tipo Dead Cells -- o agente "gaming" expande daqui.

signal morreu
signal vida_mudou(atual: int, maximo: int)
signal energia_mudou(atual: float, maximo: float)
## Emitido sempre que lança o projétil mágico -- a Ala dos Mortos (nível 09)
## usa-o para materializar as plataformas espectrais.
signal magia_lancada

const VIDA_MAXIMA := 100
## Dano corpo-a-corpo SEM arma equipada (ver EstadoJogo.dano_ataque()).
## Duplicado a pedido do Paulo (ago 2026) -- espada e tiros o dobro.
const DANO_ATAQUE := 50


## Vida máxima efetiva = base + bónus da armadura equipada.
func _vida_max() -> int:
	return VIDA_MAXIMA + EstadoJogo.vida_bonus_armadura()


## Dano do golpe = arma equipada, ou a base se não houver arma.
func _dano_golpe() -> int:
	return EstadoJogo.dano_ataque()
## Velocidade do FLYMODE (só DEVELOPER MODE -- ver `alternar_voo`).
const VEL_VOO := 560.0
const VEL_DASH := 620.0
const DUR_DASH := 0.16
const RECARGA_DASH := 0.55
const VEL_ROLAR := 360.0
const DUR_ROLAR := 0.30

## PASSOS e RASPAR NA PAREDE (4 set 2026, pedido do Paulo: "faca um set de
## sons para a koliani quando faz animacoes"). A cadencia dos passos
## ACOMPANHA a velocidade -- a andar devagar sao mais espacados, a correr
## sao mais juntos -- senao soa a metronomo. As tres amostras `passo1..3`
## sorteiam-se e ainda levam pitch aleatorio por cima.
const INTERVALO_PASSO := 0.32
const VEL_PASSO_REF := Movimento.VEL_CORRIDA
const INTERVALO_PAREDE := 0.22
const RECARGA_ROLAR := 0.45
## Janela logo a seguir a um rolamento em que o próximo golpe é CRÍTICO
## (pegada Dead Cells: rolar por dentro do inimigo e rematar).
const POS_ROLL_JANELA := 0.28
## Escalar paredes (habilidade "escalar_paredes"): encostada a uma parede
## no ar e a segurar na direção dela, agarra-se; W/S sobe/desce; saltar dá
## impulso para fora (não gasta o salto do ar). Sem limite de tempo.
const VEL_ESCALAR := 135.0
## Escorrega sempre por uma parede a que se agarra (px/s para baixo). Não se
## fica fixo -- ↑ trava/sobe, ↓ acelera a descida.
const VEL_DESLIZE_PAREDE := 55.0
const WALLJUMP := Vector2(330.0, -430.0)
## Agarrar a borda (básico, sempre disponível -- pegada Dead Cells): a cair
## rente ao rebordo de uma plataforma, a Koliani agarra-se e fica pendurada.
## Saltar / ↑ = sobe para cima da plataforma; ↓ = larga. Perdoa saltos por
## um triz nas torres da jornada.
const BORDA_ALCANCE := 24.0       # quão à frente se sente a parede
const BORDA_PEITO := -30.0        # altura do sensor "há parede à frente"
const BORDA_CABECA := -60.0       # altura do sensor "está livre por cima do rebordo"
const BORDA_MANTLE := Vector2(150.0, -430.0)  # impulso ao subir para a plataforma
const DUR_ATAQUE := 0.18
## QUATRO golpes, desde a 9H.1. Eram três porque só havia arte para um: os
## golpes 2 e 3 repetiam os seis frames golden do `attack_basic` a velocidades
## diferentes, e um quarto passo seria a mesma animação uma quarta vez. Agora
## cada golpe tem poses de corpo próprias (`tools/derivar_combo_koliani_9h1.py`)
## e o 4.º é o REMATE -- antecipação agachada, lâmina por cima da cabeça,
## estocada com avanço fundo e recuperação longa.
##
## O dano POR GOLPE não mudou (vem de `_dano_golpe()`, não do passo); o que
## mudou foi o comprimento da cadeia. Encadeia-se carregando em "atacar" outra
## vez dentro da `JANELA_COMBO` a seguir ao golpe atual (input bufferizado se
## carregar a meio do golpe); passado esse tempo sem novo golpe, o combo cai
## de volta ao 1.º hit.
const NUM_COMBO := 4
const JANELA_COMBO := 0.42
## Duração de cada golpe do combo, a acompanhar o comprimento real de cada
## tira (attack/attack2/attack3/attack4) -- senão a animação era cortada a
## meio antes de terminar, sobretudo o 3.º hit (9 frames, o mais longo).
## O remate é o golpe mais longo depois do rodopio: 6 frames a 23,08 fps.
const DUR_COMBO := [0.18, 0.2, 0.3, 0.26]
## Cada golpe tem antecipação, janela ativa e recuperação explícitas. Os
## valores são frações da duração, para a hitbox acompanhar também a duração
## maior do terceiro golpe sem ficar ligada durante a animação inteira.
## O remate arma mais tempo (a antecipação são dois frames) e por isso a
## janela activa abre mais tarde -- é o que faz o golpe LER-SE como remate.
const ATAQUE_ATIVO_INICIO := [0.22, 0.2, 0.24, 0.34]
const ATAQUE_ATIVO_FIM := [0.68, 0.7, 0.74, 0.72]

## PESO DO IMPACTO -- reafinado a 4 set 2026.
##
## O Paulo: "quando a Koliani ataca com espada o ecra treme e gera frame
## drop". Nao era impressao. O `_hitstop` punha `Engine.time_scale` a
## zero, ou seja PARAVA o jogo: cada acerto parava 50 ms (crit 110 ms), o remate
## do combo parava mais 50 ms **no balanco**, e o proprio `_flash_golpe`
## ja' abanava a camara 1,8 px sem sequer acertar em nada. Num combo de
## quatro acertos dava ~340 ms de jogo parado dentro de 1,5 s -- 23% do
## tempo. Somado ao tremor, que durava mais do que o intervalo entre
## golpes, o resultado le^-se exactamente como engasgo.
##
## Regra nova: **o balanco nao mexe na camara nem para o tempo**. So' a
## LIGACAO tem peso, e o peso e' curto -- um frame no golpe normal, e
## reserva-se o resto para o que e' raro (remate, critico, levar dano).
## REAFINADO A 10 SET 2026 (Execution 8.1C). O Paulo: ainda "congela" ao
## acertar e ao levar. Medido no codigo real (`tools/verifica_hitstop.gd`),
## a parede: remate 41 ms, critico 62 ms, levar dano 55 ms. A 165 Hz isso e'
## 6,8 / 10,3 / 9,1 frames com o jogo TODO parado -- camara, parallax,
## particulas, tudo. Um combo de tres mais um golpe levado dava ~97 ms.
##
## O mecanismo nao estava avariado: nao acumula e repoe sempre o
## `time_scale`. O que mudou foi o CONTRASTE. Estes valores foram afinados a
## 4 set, quando a apresentacao ainda era o judder de 60 Hz (3-3-2) e uma
## paragem de 50 ms se escondia lá dentro. Depois da interpolacao (8.1B) o
## movimento e' liso a 165 Hz, e a mesma paragem passou a ser um buraco de 9
## frames contra um fundo perfeitamente suave.
##
## Regra nova, em frames a 165 Hz: **<=2 frames para o que acontece a toda a
## hora, <=4 para o que e' raro**. Acima disso deixa de se ler como peso e
## passa a ler-se como o jogo a bloquear. Combo de tres + golpe levado passa
## de ~97 ms para ~58 ms, e nenhuma paragem sozinha chega aos 25 ms.
const HITSTOP_GOLPE := 0.010       # ~1,7 frames a 165 Hz -- e' o mais frequente
const HITSTOP_REMATE := 0.018      # 3.o golpe do combo -- ~3 frames
const HITSTOP_CRIT := 0.024        # ~4 frames, so' em critico
const HITSTOP_PISAO := 0.014       # ~2,3 frames
const HITSTOP_DANO := 0.020        # ~3,3 frames -- levar dano ja' tem tremor
## A escala de tempo do hitstop. NAO E' ZERO, e o motivo nao e' estetico.
##
## Ate' 18 set 2026 isto era `Engine.time_scale = 0.0`. Com o tempo a zero o
## Godot chama `PhysicsServer2D.step(physics_step * time_scale)` com passo
## ZERO, e a integracao de um corpo cinematico (`AnimatableBody2D` com
## `sync_to_physics`) calcula a velocidade dele por
## `linear_velocity = motion / passo`. Parado e com passo zero isso e'
## 0/0 = **NaN**. A Koliani em cima da plataforma le' essa velocidade em
## `move_and_slide()` (velocidade da plataforma), e sai de la' com
## `global_position` e `velocity` a NaN -- ela desaparece do nivel.
##
## Foi assim que o NaN do N06 aconteceu: a `CorrenteC` (horizontal, x=1970)
## tem um `chort` a 110 px, e bastava um acerto com a Koliani em cima da
## laje. Nas 9 runs do bot deu em 3 -- e o mesmo valia para as outras oito
## plataformas `AnimatableBody2D` do jogo (elevadores, roda, parede movel,
## raiz elevatoria...), portanto isto NAO era um defeito da Regiao II.
##
## 0,0005 congela o jogo na pratica (uma paragem de 24 ms deixa passar
## 0,012 ms de jogo) e mantem o passo de fisica diferente de zero, que e' o
## que a divisao precisa. O `Engine.time_scale < 0.5` que marca "estou em
## hitstop" continua a dar verdadeiro.
const HITSTOP_ESCALA_TEMPO := 0.0005
const TREMOR_GOLPE := 2.0
const TREMOR_REMATE := 3.2
const TREMOR_CRIT := 4.5
const TREMOR_PISAO := 2.2
const TREMOR_DANO := 5.0
## AVANÇO do golpe (pedido do Paulo, set 2026: "o combo parado no mesmo
## sítio não tem piada"). Cada golpe do combo dá um passo em frente na
## direção para onde se olha -- curto nos três primeiros, comprido no
## remate. Velocidade inicial (px/s) e duração (s) por passo: a
## velocidade decai linearmente, por isso o passo mede ~`vel * dur / 2`
## px, mais o deslize da desaceleração normal a seguir. No AR vale metade,
## para não atirar
## a Koliani para fora das plataformas a meio de um combo.
const AVANCO_VEL := [330.0, 370.0, 390.0, 470.0]
const AVANCO_DUR := [0.13, 0.13, 0.16, 0.19]

## 9H.16 D -- O QUE CADA GOLPE FAZ.
##
## Até aqui os quatro golpes davam o MESMO dano (`_dano_golpe()` não olhava
## para `_combo_passo`) e o único empurrão era um salto de 8 px. O 4.º
## golpe é o que mais compromete -- 0,26 s, janela activa só a 34% da
## animação -- e não pagava nada por isso. Carregar quatro vezes no mesmo
## botão valia tanto como carregar uma; daí "o combate é básico".
##
## Agora a cadeia tem uma curva:
##   1 ABERTURA    -- rápido e barato; pouco dano, quase sem empurrão
##   2 CONTINUIDADE-- dano de referência, empurrão curto, avança
##   3 COMPROMISSO -- mais lento e mais forte; ATORDOA, abrindo a janela
##                    de castigo (é aqui que se decide encadear ou sair)
##   4 REMATE      -- dano a dobrar, empurrão que ATIRA o inimigo, sangra
##
## O dano dos outros golpes (tiro, pisão) continua a sair de `_dano_golpe()`
## sem multiplicador -- só a espada tem cadeia.
const DANO_COMBO := [0.85, 1.0, 1.25, 1.9]
## Empurrão por golpe, em px/s (ver `DemonioBase.receber_dano`).
const RECUO_COMBO := [90.0, 150.0, 230.0, 470.0]
## O 3.º golpe atordoa: é o que transforma o combo numa DECISÃO (arriscar o
## golpe lento para ganhar a janela) em vez de um martelar de botão.
const ATORDOA_COMBO := 0.38
const AVANCO_NO_AR := 0.5
const I_FRAMES := 0.6
## Ressalto ao cair em cima de um inimigo (Mario-style): pulo AUTOMÁTICO --
## não é preciso carregar em nada. Vai por `aplicar_impulso` para o "corte
## de salto" do Movimento não o engolir se o botão não estiver premido, e
## devolve os saltos de ar (encadeia pisões).
##
## Esteve a 1.4x o salto normal e atirava a Koliani muito acima do cenário
## desenhado; o Paulo pediu METADE (3 set 2026). A 0.7x fica abaixo de um
## salto normal: chega para encadear pisões e para se afastar do bicho,
## sem perder o ecrã de vista.
const STOMP_RESSALTO := Movimento.FORCA_SALTO * 0.7
## Defesa (habilidade "escudo"): anda-se devagar de escudo erguido; um
## ataque que venha de frente é bloqueado (sem dano) com um som subtil.
const VEL_DEFESA := 70.0
const BLOQUEIO_IFRAMES := 0.14
## Tiro mágico: premir dispara logo; manter premido repete em 8 direções,
## dá um terço do dano do ataque básico. Não gasta Energia.
const DUR_LANCAR := 0.16
const PROJETIL_MAGICO := preload("res://scenes/actors/ProjetilKoliani.tscn")
const ENERGIA_MAX := 99.0
const REGEN_ENERGIA := 12.0       # por segundo (barra cheia em ~8 s)
## Abaixo deste Y considera-se que caiu no vazio (fosso sem fundo).
const Y_MORTE := 1200.0
const TEX_IMPACTO := preload("res://assets/sprites/impacto.svg")
## Execution 9G: VFX de produção da Região I (prancha 07). Fora dela, nada muda.
const Vfx9G := preload("res://scripts/vfx_regiao1.gd")

## Cúpula de energia roxa à volta do escudo (pedido do Paulo). `ABRIR` é o
## tempo que leva a crescer até ficar redonda ao levantar o escudo; o resto
## do tempo respira. Um bloqueio acende-a de rajada (`_cupula_flash`).
const CUPULA_ABRIR := 0.13
const CUPULA_ALPHA := 0.26          # cúpula em repouso
const CUPULA_ALPHA_FLASH := 0.62    # cúpula no instante do bloqueio
const ARO_ALPHA := 0.62

## Aura roxa à volta da Koliani. Respira devagar e ACENDE quando ela ataca,
## dá dash ou lança -- é o que a faz parecer carregada de energia em vez de
## ter só um halo colado. Valores multiplicam o que está no `.tscn`.
const AURA_ALPHA := 0.5
const AURA_RESPIRA := 0.16          # amplitude do respirar (fracção)
const AURA_ENERGIA := 0.85          # `energy` da LuzAura em repouso
## Feedback dos tiers 0/leve/médio/pesado. Os thresholds físicos vivem em
## Movimento; estes valores visuais/sonoros ficam juntos para o playtest.
const ATERRAGEM_SQUASH := [0.0, 0.24, 0.48, 0.78]
const ATERRAGEM_TREMOR := [0.0, 0.0, 1.4, 2.8]
const ATERRAGEM_VOLUME := [0.0, -21.0, -15.0, -10.0]

@onready var _hitbox: Area2D = $HitboxAtaque
@onready var _sprite: Node2D = $Sprite
@onready var _corpo: AnimatedSprite2D = $Sprite/Corpo
@onready var _arma: Sprite2D = $Sprite/Arma
@onready var _escudo: Node2D = $Sprite/Escudo
@onready var _escudo_glow: CanvasItem = $Sprite/Escudo/Glow
@onready var _escudo_cupula: CanvasItem = $Sprite/Escudo/Cupula
@onready var _escudo_aro: CanvasItem = $Sprite/Escudo/Aro
@onready var _halo: CanvasItem = $Sprite/Halo
@onready var _luz_aura: PointLight2D = $Sprite/LuzAura
@onready var _luz_carga: PointLight2D = $Sprite/LuzCarga
@onready var _luz_golpe: PointLight2D = $Sprite/LuzGolpe
@onready var _luz_lamina: PointLight2D = $Sprite/LuzLamina
@onready var _armadura: Node2D = $Sprite/Armadura
@onready var _camera: Camera2D = $Camera2D
@onready var _faiscas: CPUParticles2D = $FaiscasAtaque
@onready var _po: CPUParticles2D = $PoAterragem

## 0..1, sobe a 1 num bloqueio e decai -- acende a cúpula de energia.
var _cupula_flash := 0.0
## Tempo com o escudo levantado, para a cúpula abrir em vez de aparecer.
var _escudo_t := 0.0
## 0..1, sobe quando ela ataca/dash/lança -- acende a aura.
var _aura_flash := 0.0

var _mov := Movimento.Estado.new()
var vida := VIDA_MAXIMA
var _olha_para := 1.0
var _dash_restante := 0.0
var _dash_recarga := 0.0
var _rolar_restante := 0.0
## contadores dos sons ciclicos (passos, raspar na parede)
var _passo_t := 0.0
var _passo_variante := -1
var _parede_t := 0.0
## Conta-decrescente da janela pós-rolamento (ver `POS_ROLL_JANELA`).
var _pos_roll_t := 0.0
## Avanço do golpe a decorrer (ver `AVANCO_VEL`).
var _avanco_restante := 0.0
var _avanco_dur := 0.0
var _avanco_vel := 0.0
## Janela em que um impulso externo (trampolim, impulsor) fica imune ao
## "corte de salto" do Movimento -- ver `aplicar_impulso`.
var _impulso_externo_t := 0.0
var _rolar_recarga := 0.0
var _ataque_restante := 0.0
## Duração do golpe atual (varia por passo do combo -- ver `DUR_COMBO`).
var _ataque_dur := DUR_ATAQUE
## Passo do combo de espada (0 = 1.º hit "Single" .. 3 = 4.º "Quadruple").
var _combo_passo := 0
## Janela ainda aberta para o próximo golpe encadear no combo -- ao chegar
## a 0 sem novo golpe, o combo cai de volta ao 1.º hit.
var _combo_janela := 0.0
## Carregou em "atacar" a meio do golpe atual -- o próximo golpe do combo
## dispara assim que este acabar (não se perde o input).
var _combo_pedido := false
## Ataque aéreo é um golpe único: usa a apresentação de ataque disponível,
## preserva gravidade/controlo no ar e nunca abre uma cadeia infinita.
var _ataque_no_ar := false
## Um corpo só pode receber dano uma vez por golpe, mesmo que saia e volte a
## entrar na Area2D durante a mesma janela ativa.
var _alvos_atingidos_ataque := {}
var _invulneravel := 0.0
## Contadores só visuais (o rig "cavaleiro" tem desenho para eles).
var _hurt_t := 0.0
var _aterrar_t := 0.0
var _no_ar_antes := false
var _piloto_5g_em_movimento := false
var _piloto_5g_no_ar := false
var _piloto_5g_facing := 1.0
var _stomp_cd := 0.0
var _estava_no_chao := true
var _defendendo := false
## true a partir da 1.ª chamada a `_morrer()` -- evita mortes a dobrar
## (fosso + armadilha no mesmo frame, chefe a acertar num cadáver) que
## empilhavam transições e deixavam o ecrã preso a preto.
var _a_morrer := false
var _energia := ENERGIA_MAX
## FLYMODE ligado (só DEVELOPER MODE). Enquanto true: voo livre, atravessa
## paredes, sem gravidade nem dano de fosso.
var _voando := false
var _lancar_restante := 0.0
## Segundos que ainda está preso numa teia (Região III / Rainha Aracnídea):
## enquanto > 0 não anda nem salta -- só se sacode até se soltar.
var _preso := 0.0
## Agarrada a uma parede (habilidade "escalar_paredes"). `_parede_lock` é um
## breve travão depois do salto de parede para não voltar a colar logo.
var _escalando := false
var _parede_lock := 0.0
## Pendurada num rebordo (agarrar a borda). `_borda_lock` = pequeno travão
## depois de largar/subir para não voltar a agarrar logo.
var _borda := false
var _borda_lock := 0.0
var _borda_lado := 1.0
## Agachada (segura S no chão, parada). Só bloqueia o andar -- visual.
var _agachado := false
## Conta-decrescente para mostrar a animação do salto duplo.
var _djump_t := 0.0
## Segundos que ainda "flutua" (Região I / Coração Putrefacto, fase 2): a
## batida do coração alivia a gravidade -- a queda cai a menos de metade.
var _leve := 0.0
## Escala da gravidade (1 = normal). O Observatório Lunar (nível 14) mete
## zonas de "gravidade lunar" (< 1) e a Sacerdotisa mexe nisto durante a
## luta. Reposto a 1 por `definir_grav_escala(1.0)` ao sair da zona.
var _grav_escala := 1.0
## Atrito do chao: < 1 = ESCORREGADIO (nivel 41). Como a travagem usa a
## mesma aceleracao da arrancada, um so' numero da' as duas metades da
## sensacao. Reposto a 1 pela `ZonaGelo` a' saida.
var _acel_escala := 1.0

## --- GANCHO (nível 53, Jardim das Almas) ------------------------------
## Pendurada numa trepadeira, a física dela é um PÊNDULO e mais nada (a
## matemática está em `Movimento.balanco`, pura e testada). Engata-se
## sozinha ao passar por um `PontoGancho` no ar -- nunca há botão novo,
## que num telemóvel seria mais um polegar --, e `saltar` larga com a
## velocidade da tangente.
var _gancho_ativo := false
var _gancho_ancora := Vector2.ZERO
var _gancho_theta := 0.0
var _gancho_vel := 0.0
var _gancho_comp := 130.0
## Recarga depois de largar: sem ela voltava a engatar no mesmo ponto no
## frame seguinte e nunca saía de lá.
var _gancho_cd := 0.0

## --- GRAVIDADE INVERTIDA (nível 67, Mundo Invertido) ------------------
## +1 normal, -1 de pernas para o ar: ela cai para CIMA e anda nos tectos.
## Não há um segundo caminho de código -- é a mesma conta com um sinal (ver
## `Movimento.passo`), e o `up_direction` é o que faz o `is_on_floor()`
## passar a olhar para o tecto.
var _sinal_grav := 1.0


## Velocidade vertical do ponto de vista DELA: positiva = a cair, seja para
## que lado for. Todo o código que pergunta "está a cair?" usa isto, para a
## inversão não precisar de cópias.
func _vy() -> float:
	return velocity.y * _sinal_grav


## Vira a gravidade dela ao contrário (a `PlacaGravidade` chama isto).
## Devolve o sinal novo. Não guarda nada no save: é um estado de sala.
func inverter_gravidade() -> float:
	_sinal_grav = -_sinal_grav
	up_direction = Vector2(0.0, -_sinal_grav)
	# quem vira o boneco é o `_animar()` (a escala dele é reescrita todos
	# os frames); aqui só muda o sinal.
	Som.toca("gelo", -10.0, 0.8 if _sinal_grav < 0.0 else 1.25, 0.02)
	return _sinal_grav

## --- ESTADOS que a apanham a ela (5 set 2026) -------------------------
## Os inimigos ja' tinham queimar/sangrar/atordoar (`DemonioBase`); ela nao
## tinha nenhum. Estes dois sao as estreias dos niveis 45 e 48.
##
## VENENO: dano ao longo do tempo. Passa a' frente dos i-frames e do escudo
## de proposito -- um estado que se pudesse bloquear com o escudo levantado
## nao era um estado, era mais um golpe.
var _veneno := 0.0
var _veneno_tick := 0.0
var _veneno_dano := 4
## FRIO: abranda-a durante uns segundos (mexe no mesmo `_acel_escala` do
## gelo, mas por TEMPO em vez de por sitio).
var _frio := 0.0

const VENENO_INTERVALO := 0.8
## Multiplicador do input horizontal (-1 = controlos invertidos). O Olho do
## Abismo (nível 20) inverte-os por uns segundos com `inverter_controlos()`.
var _inverso := 1.0
var _inverso_restante := 0.0
## Corrente de ar (Torre dos Ventos, nível 12): `CorrenteAr` chama
## `soprar_para_cima()` a cada frame enquanto a Koliani lá está.
var _vento_restante := 0.0
var _vento_forca := 0.0
var _vento_alvo := 0.0
## Influências reutilizáveis de vento. Cada zona renova a sua entrada por
## frame e remove-a no exit; o TTL é a rede para teleporte/queue_free/sinais
## perdidos. A chave é o instance_id da zona, por isso sobreposições somam sem
## um booleano global que possa ficar preso.
var _ventos_externos: Dictionary = {}
const VENTO_EXTERNO_TTL := 0.12
## PLANAR CONTEXTUAL (Região II / N08, Ilhas Suspensas). Não é a habilidade
## permanente "planar" (essa só abre no N63): é concedido por uma
## `ZonaPlanar` enquanto a Koliani lá está. Mesmo contrato do vento -- uma
## entrada por zona, renovada por frame, com TTL de rede para teleporte,
## queue_free ou sinal de saída perdido. Nada disto é gravado no save.
var _planar_contextos: Dictionary = {}
const PLANAR_CONTEXTO_TTL := 0.12
## Verdadeiro no frame em que o planar está mesmo a segurar a queda (no ar,
## a descer, botão seguro). Só leitura -- feedback e testes; a física não
## depende dele.
var _planando := false

# animação procedural (visual, corre em _process)
var _mat: ShaderMaterial
## Shader de troca de paleta do rig (arma/armadura) -- ver
## `_montar_material_equipamento`.
var _mat_equip: ShaderMaterial
var _anim_t := 0.0
var _squash := 0.0   # impulso da aterragem
var _pop := 0.0      # impulso do ataque
## Onde a Koliani nasceu neste nível (spawn ou checkpoint). No modo dev,
## cair num fosso repõe-a aqui em vez de a matar.
var _pos_inicial := Vector2.ZERO


## O CORPO da Koliani é interpolado -- é isso que dá o movimento suave num
## painel de 165 Hz. O `$Sprite` NÃO: a viragem dela é `scale.x = ±1`
## (`_aplicar_pose`), e interpolar isso fá-la-ia passar por zero durante um
## tick, ou seja esmagava-se de cada vez que se virava. Como o modo é
## herdado, desligar no `$Sprite` chega para todo o visual por baixo (corpo,
## arma, escudo, armadura, luzes). Eles continuam a herdar a posição
## interpolada do corpo: anda suave, vira seco.
func _sem_interpolacao_no_visual() -> void:
	if _sprite:
		_sprite.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _ready() -> void:
	_sem_interpolacao_no_visual()
	_desencravar()
	_pos_inicial = global_position
	# O início do nível é o checkpoint seguro `_start`. A posição concreta é
	# contexto runtime e nunca entra no save v4.
	EstadoJogo.registar_spawn_inicio(_pos_inicial)
	if _hitbox:
		_hitbox.monitoring = false
		_hitbox.body_entered.connect(_ao_acertar_corpo)
	if _corpo:
		_montar_frames()
	vida = _vida_max()  # nível novo começa cheio (inclui bónus de armadura)
	vida_mudou.emit(vida, _vida_max())
	energia_mudou.emit(_energia, ENERGIA_MAX)
	_aplicar_equipamento()
	EstadoJogo.equipamento_mudou.connect(func(_t: String, _i: String) -> void: _aplicar_equipamento())


## Rig do sprite:
##   "cavaleiro" -- pack "Knight_player 1.4" (@Jump_Button), graduado para a
##      paleta da Koliani por `tools/importar_rig_cavaleiro.gd`. É o rig ATUAL
##      (pedido do Paulo, 1 set 2026): cavaleira de faixa na testa, armadura,
##      espada e escudo, com animações a sério para TODOS os estados (rolar,
##      dash, dano, defesa, borda, aterrar, morte).
##   "codigo" -- tiras geradas por `tools/gerar_sprites.gd` (a Koliani roxa
##      desenhada por código; fica como alternativa).
##   "gothic" -- rig Ansimuz "Gothicvania Church", experiência da fase 4
##      DESLIGADA a pedido do Paulo (ficou escura/pequena).
##   "shadowblade" -- ACTUAL (4 set 2026): a arte que o Paulo fez de raiz
##      ("criei de raiz para ter várias ações"). Vive em
##      `assets/sprites/incoming/shadowblade/`; `tools/importar_rig_shadowblade.py`
##      limpa-a e recorta-a para `assets/sprites/pixel/koliani_shadowblade/`.
##      É a única sem problema de licença -- é do Paulo.
##   "nova" -- a pixel-art que o Paulo desenhou
##      (cabelo lavanda, manto azul, botas vermelhas). Só veio `idle` e
##      `walk`; os outros 16 estados são derivados desses frames por
##      `tools/importar_rig_koliani_nova.py`.
const RIG := "shadowblade"

## Execution 5B/8: variante visual por instância. O valor por omissão preserva
## o rig Shadowblade fora do lote; a Região I ativa o fallback premium.
@export var usar_prototipo_premium := false

## Execution 5G/8: sobreposição de locomoção validada para a Região I.
## Mantém o prototype 5B como fallback para combate e estados sem arte 5G.
@export var usar_piloto_visual_5g := false

## Execution 9B.3: Golden Set aprovado pelo Game Master como fonte visual ativa
## de idle/run/jump_start/jump_loop/fall/ataque básico (+ VFX do golpe à parte).
## Substitui a 5G e o corpo premium_v1 nesses estados; o premium_v1 fica só
## como fallback dos estados ainda sem arte de produção (ver `_montar_golden_set`).
@export var usar_golden_set := false

## Rigs desenhados frame a frame (tudo menos o "codigo", que é um boneco
## vectorial montado por código). Neles a animação PROCEDURAL de `_animar`
## -- o balanço da corrida, a inclinação, o "respirar" parado, o esticão do
## salto -- é contraproducente: escalar e rodar continuamente um sprite com
## filtro Nearest faz os pixéis saltarem dentro da figura, e lê-se como
## tremura ou frame drop. Foi metade da queixa do Paulo (4 set 2026:
## "parece que tem algum frame drop"). Fica só o que é transitório
## (squash de aterragem, pop e smear do golpe), que dura décimas de segundo.
const RIG_PIXEL := RIG != "codigo"

## As poses de PAREDE do rig "shadowblade" foram desenhadas com a parede à
## ESQUERDA da Koliani -- ao contrário da convenção "virada à direita" que o
## resto do rig segue. Espelhá-las como as outras punha-a agarrada ao lado
## errado numa parede esquerda (pedido do Paulo, 4 set 2026).
const PAREDE_ESPELHADA := RIG == "shadowblade"

## [n_frames, fps, loop] por estado. Cada tira é horizontal, virada à direita.
const _KOLI_ANIMS := {
	"idle":      [4, 6.0, true],
	"run":       [6, 12.0, true],
	"jump":      [2, 8.0, false],
	"fall":      [2, 8.0, true],
	"attack":    [4, 22.0, false],
	"crouch":    [2, 6.0, true],
	"wallslide": [2, 8.0, true],
	"djump":     [4, 18.0, false],
}
## Contagens do rig "gothic" (Punch tem 6 frames, jump só 2).
const _KOLI_ANIMS_GOTHIC := {
	"idle":      [4, 7.0, true],
	"run":       [6, 13.0, true],
	"jump":      [2, 8.0, false],
	"fall":      [2, 8.0, true],
	"attack":    [6, 26.0, false],
	"crouch":    [2, 6.0, true],
	"wallslide": [2, 8.0, true],
	"djump":     [2, 12.0, false],
}

## Rig "cavaleiro": frames de 100x64. Os estados a mais (roll/dash/hurt/
## defesa/borda/aterrar/morte) só existem neste rig -- o `_atualizar_anim`
## pergunta sempre `has_animation` antes de os usar.
const _KOLI_ANIMS_CAVALEIRO := {
	"idle":      [4, 6.0, true],
	"run":       [7, 12.0, true],
	"jump":      [6, 14.0, false],
	"fall":      [3, 8.0, true],
	"attack":    [6, 24.0, false],
	## combo de espada -- 2.º/3.º/4.º hit, cada um com a sua tira própria
	## (Attack_KG_2/3/4 do pack, ver `_iniciar_ataque`/`_anim_ataque`).
	"attack2":   [6, 24.0, false],
	"attack3":   [9, 26.0, false],
	"attack4":   [5, 22.0, false],
	"crouch":    [3, 6.0, true],
	"wallslide": [2, 8.0, true],
	"djump":     [10, 24.0, false],
	"roll":      [10, 26.0, false],
	"dash":      [4, 18.0, false],
	"hurt":      [4, 16.0, false],
	"defesa":    [4, 6.0, true],
	"borda":     [3, 6.0, true],
	"aterrar":   [4, 20.0, false],
	"morte":     [5, 9.0, false],
}
## Escala/desvio do rig "cavaleiro": o frame tem 64 px de alto com os pés na
## base, e o corpo da Koliani mede 44 px (ver `RectangleShape2D_body`).
const CAV_ESCALA := 0.8
const CAV_OFFSET_Y := -2.0

## Rig "shadowblade" -- a arte do Paulo (4 set 2026). Frames de 51x64, com a
## personagem a medir ~59 px e os pés na base (a tira já sai reduzida do
## `importar_rig_shadowblade.py`, por isso o jogo desenha-a a 1:1).
##
## As 34 poses do atlas dão 13 estados (ver `ESTADOS` na ferramenta). O
## `fps` de cada golpe do combo acompanha o `DUR_COMBO` correspondente, para
## a animação acabar exactamente com o golpe. Os estados que faltam
## (roll/dash/hurt/defesa/morte) não existem neste rig -- `_atualizar_anim`
## pergunta sempre `has_animation` antes de os usar.
const _KOLI_ANIMS_SHADOW := {
	"idle":      [4, 6.0, true],
	"run":       [5, 13.0, true],
	## 3 -> 2 e 2 -> 1 a 4 set 2026: duas das poses aereas do atlas estao
	## SEM CABECA (o recorte de origem cortou-lhes o tronco de cima) e a meio
	## do salto via-se um tronco decapitado -- ver `importar_rig_shadowblade.py`.
	"jump":      [2, 11.0, false],
	"fall":      [1, 7.0, true],
	"aterrar":   [2, 16.0, false],
	## combo de espada -- cada golpe tem a sua pose (corte descendente, arco
	## por cima, estocada com raio, investida rasteira). Antes eram os seis
	## frames da linha de ataque todos na MESMA tira, e por isso o combo
	## "fazia sempre a mesma animação" (Paulo, 4 set 2026).
	"attack":    [3, 17.0, false],
	"attack2":   [3, 15.0, false],
	"attack3":   [3, 10.0, false],
	"attack4":   [4, 21.0, false],
	"crouch":    [1, 6.0, true],
	"wallslide": [3, 8.0, true],
	"borda":     [2, 5.0, true],
	"djump":     [4, 14.0, false],
}
## Os pés estão em y=62 do frame de 64 (30 px abaixo do centro) e a colisão
## mede 44 de alto (base 22 abaixo da origem): -8 põe os pés no chão.
const SHADOW_ESCALA := 1.0
const SHADOW_OFFSET_Y := -8.0

## Prototype premium da Execution 5B. As tiras usam celulas 160x96; a escala
## mantem a figura com ~59 px de altura no mundo. Os fps dos quatro golpes
## correspondem aos tempos logicos 0.18/0.20/0.30/0.19 s sem os alterar.
const _KOLI_ANIMS_PREMIUM := {
	"idle":      [4, 6.0, true],
	"run":       [5, 13.0, true],
	"jump":      [3, 11.0, false],
	"fall":      [2, 7.0, true],
	"aterrar":   [2, 16.0, false],
	"attack":    [6, 33.333333, false],
	"attack2":   [6, 30.0, false],
	"attack3":   [6, 20.0, false],
	"attack4":   [6, 31.578947, false],
	"dash":      [3, 18.75, false],
	"hurt":      [2, 8.333333, false],
	"morte":     [5, 9.0, false],
	"crouch":    [1, 6.0, true],
	"wallslide": [2, 8.0, true],
	"borda":     [2, 5.0, true],
	"djump":     [3, 14.0, false],
	"roll":      [3, 18.75, false],
	"defesa":    [1, 6.0, true],
}
const PREMIUM_ESCALA := 0.75
## Pes em y=90 da celula: (90-48)*0.75 + offset*0.75 = 22 no mundo.
const PREMIUM_OFFSET_Y := -12.666667

## Frames tecnicamente limpos da Execution 5G. `run_brake` e `land` são
## montados abaixo com poses destas sequências, sem gerar ou inferir pixels.
const _KOLI_ANIMS_PILOTO_5G := {
	"idle":       [10, 8.0, true],
	"run":        [12, 16.0, true],
	"turn":       [4, 12.0, false],
	"run_start":  [6, 12.0, false],
	"jump_start": [4, 12.0, false],
	"jump_loop":  [4, 8.0, true],
	"fall":       [4, 8.0, true],
}
const PILOTO_5G_DIR := "koliani_visual_pilot_5g"
## A escala 5G.1 aumenta a leitura da personagem no Level 1 sem mover os pes.
## (90 - 48 + offset) * escala continua igual a 22 no mundo.
const PILOTO_5G_ESCALA := 0.82
const PILOTO_5G_OFFSET_Y := -15.170732

## Golden Set (contrato 9B.1): células 128x128, pés em y=104, desenhado a 1:1.
## (104 - 64 + offset) * escala = 22 no mundo, igual aos (90-48-15,17)*0,82 da 5G.
const GOLDEN_DIR := "res://assets/sprites/koliani_golden_set"
const GOLDEN_ESCALA := 1.0
const GOLDEN_OFFSET_Y := -18.0
## [pasta, n_frames, fps, loop]. Os ciclos seguem os da 5G (run 0,75 s, ar
## 0,5 s); o golpe dura exatamente `DUR_COMBO[0]` (6 frames / 0,18 s).
const _KOLI_ANIMS_GOLDEN := {
	"idle":       ["frames/idle", 7, 8.0, true],
	"run":        ["frames/run", 10, 13.333333, true],
	"jump_start": ["frames/jump_start", 4, 12.0, false],
	"jump_loop":  ["frames/jump_loop", 3, 6.0, true],
	"fall":       ["frames/fall", 3, 6.0, true],
	"attack":     ["frames/attack_basic", 6, 33.333333, false],
	# Execution 9H.1: poses de corpo PRÓPRIAS para os golpes 2/3/4 do combo
	# (`tools/derivar_combo_koliani_9h1.py`). Os fps fazem cada tira durar
	# exactamente o `DUR_COMBO` do seu passo: 0,20 / 0,30 / 0,26 s.
	"attack2":    ["frames/attack_2", 6, 30.0, false],
	"attack3":    ["frames/attack_3", 6, 20.0, false],
	"attack4":    ["frames/attack_4", 6, 23.076923, false],
	# Execution 9B.4: pacote completo, derivado só de frames golden inteiros
	# (`tools/derivar_pacote_koliani_9b4.py`). Os fps fazem cada animação durar
	# o tempo lógico do estado: dash 0,16 s, roll 0,30 s, hurt 0,24 s.
	"dash":       ["frames/dash", 3, 18.75, false],
	"roll":       ["frames/roll", 6, 20.0, false],
	"hurt":       ["frames/hurt", 2, 8.333333, false],
	"morte":      ["frames/morte", 3, 14.0, false],
	"crouch":     ["frames/crouch", 1, 6.0, true],
	"wallslide":  ["frames/wallslide", 2, 6.0, true],
	"borda":      ["frames/borda", 1, 5.0, true],
	"djump":      ["frames/djump", 4, 10.0, false],
	"defesa":     ["frames/defesa", 1, 6.0, true],
}
## RESERVA dos golpes 2/3/4: os mesmos 6 frames do `attack_basic` à velocidade
## de cada passo. Era isto que o jogo fazia até à 9H.1 e é o que volta a fazer
## se as tiras derivadas não estiverem importadas (checkout fresco antes do
## `--import`). Com as tiras presentes, nunca é usado.
const _GOLDEN_COMBO_FPS := {"attack2": 30.0, "attack3": 20.0, "attack4": 23.076923}
const GOLDEN_VFX_FRAMES := 6
## Onde nasce o arco do golpe, relativo à origem da Koliani (virada à direita):
## à frente e à altura do peito. Só visual -- a hitbox não depende disto.
const GOLDEN_VFX_OFFSET := Vector2(16.0, -30.0)

## Rig "nova" -- a arte do Paulo. Frames de 72x72 com os pés em y=68
## (`tools/importar_rig_koliani_nova.py`). O `idle` tem 10 frames e o `run`
## 12 (a passada original tinha 24, ficou de dois em dois).
const _KOLI_ANIMS_NOVA := {
	"idle":      [10, 8.0, true],
	"run":       [12, 16.0, true],
	"jump":      [3, 12.0, false],
	"fall":      [3, 8.0, true],
	"attack":    [5, 22.0, false],
	"attack2":   [5, 22.0, false],
	"attack3":   [6, 24.0, false],
	"attack4":   [5, 20.0, false],
	"crouch":    [2, 6.0, true],
	"wallslide": [2, 8.0, true],
	"djump":     [8, 22.0, false],
	"roll":      [6, 20.0, false],
	"dash":      [3, 16.0, false],
	"hurt":      [3, 14.0, false],
	"defesa":    [2, 5.0, true],
	"borda":     [2, 5.0, true],
	"aterrar":   [4, 20.0, false],
	"morte":     [6, 9.0, false],
}
## O frame tem 72 px de alto com os pés em y=68 (32 px abaixo do centro) e o
## corpo da Koliani mede 44 px: 0.86 de escala e -6.4 de desvio põem os pés
## exactamente na base da colisão.
const NOVA_ESCALA := 0.86
const NOVA_OFFSET_Y := -6.4


func _montar_frames() -> void:
	if _corpo.sprite_frames != null:
		return
	var premium := usar_prototipo_premium
	var gothic := RIG == "gothic"
	var cavaleiro := RIG == "cavaleiro"
	var nova := RIG == "nova"
	var shadow := RIG == "shadowblade"
	var anims: Dictionary = _KOLI_ANIMS
	var dir_tiras := "koliani"
	if premium:
		anims = _KOLI_ANIMS_PREMIUM
		dir_tiras = "koliani_premium_v1"
	elif gothic:
		anims = _KOLI_ANIMS_GOTHIC
		dir_tiras = "koliani_gothic"
	elif cavaleiro:
		anims = _KOLI_ANIMS_CAVALEIRO
		dir_tiras = "koliani_cavaleiro"
	elif nova:
		anims = _KOLI_ANIMS_NOVA
		dir_tiras = "koliani_nova"
	elif shadow:
		anims = _KOLI_ANIMS_SHADOW
		dir_tiras = "koliani_shadowblade"
	if premium:
		_corpo.scale = Vector2(PREMIUM_ESCALA, PREMIUM_ESCALA)
		_corpo.offset = Vector2(0.0, PREMIUM_OFFSET_Y)
		if _armadura:
			_armadura.visible = false
		if _luz_lamina:
			_luz_lamina.enabled = true
	elif shadow:
		_corpo.scale = Vector2(SHADOW_ESCALA, SHADOW_ESCALA)
		_corpo.offset = Vector2(0.0, SHADOW_OFFSET_Y)
		if _armadura:
			_armadura.visible = false   # a arte ja' traz o fato todo
		if _luz_lamina:
			_luz_lamina.enabled = true  # a lamina e' roxa e brilha: acompanha
	if nova:
		_corpo.scale = Vector2(NOVA_ESCALA, NOVA_ESCALA)
		_corpo.offset = Vector2(0.0, NOVA_OFFSET_Y)
		if _armadura:
			_armadura.visible = false   # a arte já traz o manto
		if _luz_lamina:
			_luz_lamina.enabled = false  # o clarão do golpe já vem no frame
	if cavaleiro:
		_corpo.scale = Vector2(CAV_ESCALA, CAV_ESCALA)
		_corpo.offset = Vector2(0.0, CAV_OFFSET_Y)
		if _armadura:
			_armadura.visible = false  # o rig já traz armadura
		# a espada e o escudo já estão desenhados nos frames
		if _luz_lamina:
			_luz_lamina.enabled = false
	if gothic:
		_corpo.scale = Vector2(1.05, 1.05)
		_corpo.offset = Vector2(0.0, 4.0)  # baixa o sprite -> pés no chão
		if _armadura:
			_armadura.visible = false  # o rig já traz roupa
		# o rig não tem "lâmina que brilha" -- desliga o glow que fica preso
		# ao sprite (o clarão do GOLPE continua a disparar nos acertos)
		if _luz_lamina:
			_luz_lamina.enabled = false
	if usar_piloto_visual_5g and not usar_golden_set:
		_corpo.scale = Vector2(PILOTO_5G_ESCALA, PILOTO_5G_ESCALA)
		_corpo.offset = Vector2(0.0, PILOTO_5G_OFFSET_Y)
	if usar_golden_set:
		# Execution 9B.4: com o Golden Set o corpo sai SÓ de frames golden. Nem o
		# premium_v1 nem o rig do script chegam a ser carregados, por isso não há
		# estado nenhum que possa cair de volta noutra Koliani.
		anims = {}
		if _armadura:
			_armadura.visible = false
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for nome: String in anims:
		_adicionar_animacao_de_tira(sf, nome, anims[nome], dir_tiras)
	if usar_golden_set:
		_montar_golden_set(sf)
		# A luz magenta da lâmina servia a lâmina acesa do premium_v1; sobre o
		# Golden Set pintava as pontas do cabelo e a pele de rosa-choque, e a
		# autoridade aprovada tem a Shadowblade inativa, sem brilho (9B.1 §F).
		# O glow curto do golpe (`_luz_golpe`) continua.
		if _luz_lamina:
			_luz_lamina.enabled = false
	elif usar_piloto_visual_5g:
		for nome: String in _KOLI_ANIMS_PILOTO_5G:
			_adicionar_animacao_de_tira(sf, nome, _KOLI_ANIMS_PILOTO_5G[nome], PILOTO_5G_DIR)
		_montar_fallbacks_piloto_5g(sf)
	# Gesto de lançamento com poses existentes, sem ativar a hitbox da espada.
	if sf.has_animation("attack") and not sf.has_animation("lancar"):
		sf.add_animation("lancar")
		sf.set_animation_loop("lancar", false)
		sf.set_animation_speed("lancar", sf.get_frame_count("attack") / DUR_LANCAR)
		for i in sf.get_frame_count("attack"):
			sf.add_frame("lancar", sf.get_frame_texture("attack", i))
	_corpo.sprite_frames = sf
	if usar_golden_set:
		_corpo.animation_changed.connect(_aplicar_contrato_visual)
	_corpo.play("idle")
	_aplicar_contrato_visual()
	_montar_material_equipamento()


## Nomes servidos pelo Golden Set (inclui os derivados só de frames golden).
var _golden_anims := {}
var _slash_vfx: AnimatedSprite2D
## 9G: arco dos golpes 2/3 (spin/heavy slash), filho da Koliani enquanto dura.
var _vfx_combo: AnimatedSprite2D
var _combo_selo: Label

## LEITURA DO COMBO (Execution 9H). O Game Master: "a Koliani não parece dar
## combos". Não era o encadeamento -- esse funciona: era a APRESENTAÇÃO. Os
## três golpes saem dos mesmos seis frames aprovados do Golden Set (não há
## arte própria por golpe), e o que mudava entre eles era a velocidade. Três
## golpes com a mesma pose e o mesmo arco lêem-se como um só, repetido.
##
## O que passa a distinguir cada golpe, sem tocar no corpo aprovado (o rig
## não se deforma por código -- ver `RIG_PIXEL`):
##
##   1.º  arco baixo, diagonal a subir, curto e frio
##   2.º  giro largo (spin slash), espelhado na vertical, mais alto
##   3.º  arco pesado (heavy slash), maior, deslocado à frente, quente
##
## mais o SELO do combo (o "×2"/"×3" por cima da cabeça, que apaga com a
## janela) e um tom de voz próprio em cada golpe. Nenhum destes mexe na
## hitbox: a leitura mudou, o combate não.
const ARCO_COMBO := [
	{"fam": "spin_slash", "escala": Vector2(0.82, 0.82), "desloc": Vector2(-4.0, 6.0),
		"giro": 16.0, "cor": Color(0.86, 0.90, 1.0, 0.95)},
	{"fam": "spin_slash", "escala": Vector2(1.16, -1.12), "desloc": Vector2(6.0, -4.0),
		"giro": -12.0, "cor": Color(1.0, 0.92, 0.98, 1.0)},
	{"fam": "heavy_slash", "escala": Vector2(1.34, 1.28), "desloc": Vector2(14.0, 0.0),
		"giro": 0.0, "cor": Color(1.0, 0.80, 0.86, 1.0)},
	## remate: o arco mais largo, virado para baixo e à frente (a lâmina crava)
	{"fam": "heavy_slash", "escala": Vector2(1.52, -1.40), "desloc": Vector2(18.0, 8.0),
		"giro": 34.0, "cor": Color(1.0, 0.72, 0.80, 1.0)},
]
## Tom de cada golpe: o combo sobe de altura, e o remate cai para o grave.
const TOM_COMBO := [1.0, 1.09, 1.16, 0.84]
## Som e volume de cada golpe do combo (Execution 9H.13). O remate e' o
## evento mais pesado do teclado de sons do jogo -- e' ele que tem de
## mandar na mistura quando toca.
const SOM_COMBO := ["ataque", "ataque2", "ataque3", "ataque_forte"]
const VOL_COMBO := [-8.0, -7.0, -6.0, -3.0]
## 9G: cúpula do escudo (prancha 07), filha do nó `Escudo`.
var _escudo_9g: AnimatedSprite2D
## Centro do arco dos golpes 2/3: à frente do peito, onde a lâmina passa.
const VFX9G_COMBO_POS := Vector2(20.0, -10.0)


## Monta o Golden Set: todos os estados alcançáveis da Koliani, só com frames
## golden (diretos, ou derivados sem píxeis novos na 9B.3/9B.4).
func _montar_golden_set(sf: SpriteFrames) -> void:
	_golden_anims.clear()
	for nome: String in _KOLI_ANIMS_GOLDEN:
		var c: Array = _KOLI_ANIMS_GOLDEN[nome]
		var base: String = String(c[0]).get_file()
		var quadros: Array = []
		for i in int(c[1]):
			quadros.append("%s/%s/%s_%03d.png" % [GOLDEN_DIR, c[0], base, i + 1])
		_animacao_golden(sf, nome, quadros, c[2], c[3])
	# Reserva: só para os golpes cuja tira derivada não veio no pacote.
	var ataque: Array = _frames_de(sf, "attack", range(6))
	for nome: String in _GOLDEN_COMBO_FPS:
		if sf.has_animation(nome) and sf.get_frame_count(nome) > 0:
			continue
		_animacao_golden(sf, nome, ataque, _GOLDEN_COMBO_FPS[nome], false)
	# Execution 9H.18: se a arte NATIVA da corrida estiver no repo, e' ela que
	# manda. Ver `docs/spec_run_nativo_koliani.md` -- e' um drop-in: chega
	# largar os frames na pasta e reimportar, sem tocar em codigo.
	_substituir_run_por_nativo(sf)
	# Estados de locomoção da 5G, agora montados com poses golden existentes.
	# NB: saem do `run` que ficou montado acima (nativo, se existir).
	_animacao_golden(sf, "turn", _frames_de(sf, "run", [0, 1, 2, 3]), 12.0, false)
	_animacao_golden(sf, "run_start", _frames_de(sf, "run", [0, 1, 2, 3, 4, 5]), 12.0, false)
	# 9H.18: o travao e a aterragem DAVAM UM POP. Medido em largura de
	# silhueta: o `run_brake` ia do frame mais aberto do ciclo (57 px) para o
	# `idle` (37 px) num unico frame de 71 ms -- 20 px de silhueta a
	# desaparecer de repente, que se le' como um salto, nao como uma
	# derrapagem. O `land` fazia o mesmo de 49 para 37.
	#
	# Nao ha' frames novos aqui -- ha' os MESMOS frames escolhidos por
	# largura, a fechar por degraus. O travao passa a 57-51-48-46-43-37
	# (degrau maximo 6 px) e a aterragem a 49-44-38-37 (maximo 6), que
	# tambem e' o gesto certo: bate, encolhe, levanta.
	_animacao_golden(sf, "run_brake",
		_frames_de(sf, "run", [9, 8, 2, 0]) + _frames_de(sf, "idle", [3, 0]),
		20.0, false)
	var aterrar: Array = _frames_de(sf, "fall", [2, 0])
	aterrar += _frames_de(sf, "crouch", [0]) + _frames_de(sf, "idle", [0])
	for nome in ["land", "aterrar"]:
		_animacao_golden(sf, nome, aterrar, 16.0, false)
	# `jump` só é pedido pelo caminho de locomoção antigo; fica golden na mesma.
	_animacao_golden(sf, "jump", _frames_de(sf, "jump_start", [1, 2, 3]), 12.0, false)
	# RUN final aprovada: substituir só depois de preservar os derivados anteriores.
	# Os dez PNGs NN128 usam o mesmo contrato; física e cadência não mudam.
	var run_final: Array = []
	for i in 10:
		run_final.append("%s/frames/run_final/run_%03d.png" % [GOLDEN_DIR, i + 1])
	_animacao_golden(sf, "run", run_final, _KOLI_ANIMS_GOLDEN["run"][2], true)
	_montar_vfx_golpe()


## Pasta onde a arte NATIVA da corrida entra, quando existir. Enquanto nao
## existir, o jogo corre com o `run` da folha golden -- que NAO tem passada
## de duas pernas (medido na 9H.18: o pe' de tras varre 7 px e o da frente
## 29; `tools/validar_run_nativo_9h18.py` reprova-o). O contrato do ficheiro
## esta' em `docs/spec_run_nativo_koliani.md`.
const GOLDEN_RUN_NATIVO_DIR := "res://assets/sprites/koliani_golden_set/frames/run_native"


## Troca o `run` pela tira nativa, se ela estiver no repo. Silenciosa e sem
## efeito nenhum quando a pasta nao existe -- e' so' isso que separa o jogo
## de hoje do jogo com a corrida boa.
func _substituir_run_por_nativo(sf: SpriteFrames) -> void:
	if not DirAccess.dir_exists_absolute(GOLDEN_RUN_NATIVO_DIR):
		return
	var dir := DirAccess.open(GOLDEN_RUN_NATIVO_DIR)
	if dir == null:
		return
	var nomes: Array[String] = []
	for f in dir.get_files():
		# depois do export so' ha' `.ctex`; em editor ha' `.png` e `.png.import`.
		if f.ends_with(".import") or f.ends_with(".ctex"):
			f = f.get_basename()
		if f.get_extension().to_lower() == "png" and not nomes.has(f):
			nomes.append(f)
	nomes.sort()
	if nomes.size() < 6:
		push_warning("run nativo com %d frames -- sao precisos 8 a 12; fica o golden"
			% nomes.size())
		return
	var quadros: Array = []
	for n in nomes:
		quadros.append("%s/%s" % [GOLDEN_RUN_NATIVO_DIR, n])
	# O ciclo dura o mesmo que o golden (0,75 s), para nao mexer na cadencia
	# nem no `speed_scale` que acompanha a velocidade.
	_animacao_golden(sf, "run", quadros, float(nomes.size()) / DUR_CICLO_CORRIDA, true)


## Cria (ou substitui) uma animação a partir de caminhos res:// ou texturas já
## carregadas, e marca-a como golden para o contrato de escala.
func _animacao_golden(sf: SpriteFrames, nome: String, quadros: Array, fps: float, loop: bool) -> void:
	if sf.has_animation(nome):
		sf.remove_animation(nome)
	sf.add_animation(nome)
	sf.set_animation_speed(nome, fps)
	sf.set_animation_loop(nome, loop)
	for q in quadros:
		var tex: Texture2D = load(q) if q is String else q
		if tex:
			sf.add_frame(nome, tex)
	_golden_anims[nome] = true


func _frames_de(sf: SpriteFrames, nome: String, indices: Array) -> Array:
	var saida: Array = []
	for i in indices:
		if i < sf.get_frame_count(nome):
			saida.append(sf.get_frame_texture(nome, i))
	return saida


## As células golden (128x128, escala 1,0) e as premium_v1 (160x96, escala
## 0,75) põem os pés no mesmo sítio do mundo, mas precisam de escala/offset
## próprios -- troca-se ao mudar de animação. `_animar` deforma o `_sprite`
## (o pai), por isso isto não colide com o squash/rotação.
func _aplicar_contrato_visual() -> void:
	if not usar_golden_set or _corpo == null:
		return
	# 9B.4: já não há animações de outro rig no SpriteFrames -- escala única.
	_corpo.scale = Vector2(GOLDEN_ESCALA, GOLDEN_ESCALA)
	_corpo.offset = Vector2(0.0, GOLDEN_OFFSET_Y)


## O arco do golpe é uma camada à parte (contrato 9B.1 §F): nunca dentro do
## frame do corpo. É filho da própria Koliani (que não é espelhada) e vira-se à
## mão com `_olha_para`.
func _montar_vfx_golpe() -> void:
	if _slash_vfx != null:
		return
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("slash")
	sf.set_animation_loop("slash", false)
	for i in GOLDEN_VFX_FRAMES:
		var tex: Texture2D = load("%s/vfx/vfx_slash_basic/vfx_slash_basic_%03d.png" % [GOLDEN_DIR, i + 1])
		if tex:
			sf.add_frame("slash", tex)
	_slash_vfx = AnimatedSprite2D.new()
	_slash_vfx.name = "SlashVFX"
	_slash_vfx.sprite_frames = sf
	_slash_vfx.offset = Vector2(0.0, GOLDEN_OFFSET_Y)
	_slash_vfx.z_index = 1
	_slash_vfx.visible = false
	_slash_vfx.animation_finished.connect(func() -> void: _slash_vfx.visible = false)
	add_child(_slash_vfx)


func _disparar_vfx_golpe() -> void:
	if _slash_vfx == null:
		return
	# 9G: os golpes 2 e 3 do combo no chão têm o arco próprio da prancha 07
	# ("spin slash -- ataque 2", "heavy slash -- ataque 3"). Só visual: a
	# duração é a do golpe e a hitbox não sabe que isto existe.
	if _vfx_combo and is_instance_valid(_vfx_combo):
		_vfx_combo.queue_free()
	_vfx_combo = null
	if _combo_passo >= 0 and not _ataque_no_ar and Vfx9G.ativo(self):
		var d: Dictionary = ARCO_COMBO[clampi(_combo_passo, 0, ARCO_COMBO.size() - 1)]
		_vfx_combo = Vfx9G.novo(str(d["fam"]))
		if _vfx_combo:
			_slash_vfx.visible = false
			var n := _vfx_combo.sprite_frames.get_frame_count("fx")
			_vfx_combo.speed_scale = (n / _vfx_combo.sprite_frames.get_animation_speed("fx")) / maxf(_ataque_dur, 0.05)
			var e: Vector2 = d["escala"]
			_vfx_combo.scale = Vector2(e.x * _olha_para, e.y * _sinal_grav)
			var desl: Vector2 = d["desloc"]
			_vfx_combo.position = Vector2((VFX9G_COMBO_POS.x + desl.x) * _olha_para,
				(VFX9G_COMBO_POS.y + desl.y) * _sinal_grav)
			_vfx_combo.rotation_degrees = float(d["giro"]) * _olha_para * _sinal_grav
			_vfx_combo.modulate = d["cor"]
			_vfx_combo.z_index = 1
			_vfx_combo.animation_finished.connect(_vfx_combo.queue_free)
			add_child(_vfx_combo)
			_vfx_combo.play("fx")
			return
	# 6 frames na duração lógica do golpe -- o VFX acaba com a animação do corpo.
	_slash_vfx.sprite_frames.set_animation_speed("slash", GOLDEN_VFX_FRAMES / maxf(_ataque_dur, 0.05))
	# acompanha o espelho do corpo, incluindo a gravidade invertida (`_sinal_grav`)
	_slash_vfx.scale = Vector2(_olha_para, _sinal_grav)
	_slash_vfx.position = Vector2(GOLDEN_VFX_OFFSET.x * _olha_para,
		(GOLDEN_VFX_OFFSET.y - GOLDEN_OFFSET_Y) * _sinal_grav)
	_slash_vfx.visible = true
	_slash_vfx.play("slash")
	_slash_vfx.set_frame_and_progress(0, 0.0)


## VFX do pacote 9B.4 -- todos à parte do corpo, como o `SlashVFX`: o frame
## golden nunca leva efeito pintado dentro. Nascem no pai da Koliani (o nível),
## por isso ficam para trás no mundo e saem com a cena.
const COR_SHADOWBLADE := Color(0.78, 0.32, 1.0)
const RASTO_INTERVALO := 0.035
var _rasto_t := 0.0


## Rasto do dash: cópias do frame golden que está a ser desenhado, tingidas do
## roxo da Shadowblade, a apagar em 0,18 s. Não tocam em nada da física.
func _rasto_dash(dt: float) -> void:
	_rasto_t -= dt
	if _rasto_t > 0.0 or _corpo == null or get_parent() == null:
		return
	_rasto_t = RASTO_INTERVALO
	var tex := _corpo.sprite_frames.get_frame_texture(_corpo.animation, _corpo.frame)
	if tex == null:
		return
	var eco := Sprite2D.new()
	eco.name = "RastoDash"
	eco.texture = tex
	eco.centered = true
	eco.offset = _corpo.offset
	eco.global_position = _corpo.global_position
	eco.scale = _sprite.scale * _corpo.scale
	eco.modulate = Color(COR_SHADOWBLADE, 0.55)
	eco.z_index = -1
	eco.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_parent().add_child(eco)
	var t := eco.create_tween()
	t.tween_property(eco, "modulate:a", 0.0, 0.18)
	t.tween_callback(eco.queue_free)


## Explosão curta de partículas nos pés, no 2.º salto.
func _vfx_salto_duplo() -> void:
	if not usar_golden_set:
		return
	# 9G: o "dash impact" da prancha, rodado para baixo -- o impulso sai dos
	# pés. Rotação exacta e viragem, sem redesenhar nada.
	if Vfx9G.ativo(self):
		Vfx9G.tocar(self, "dash_impact", global_position + Vector2(0.0, 18.0 * _sinal_grav),
			0.9, PI * 0.5 * _sinal_grav, false, false, -1, 0.3)
		return
	_rajada("SaltoDuploVFX", Vector2(0.0, 20.0 * _sinal_grav), 14, 0.32,
		Vector2(0.0, 1.0 * _sinal_grav), 70.0, COR_SHADOWBLADE)


## Motes vermelhos/roxos a subir quando ela cai; o fade da recarga fecha logo.
func _vfx_morte() -> void:
	if not usar_golden_set:
		return
	if Vfx9G.ativo(self):
		Vfx9G.tocar(self, "death_dissolve", global_position + Vector2(0.0, -6.0), 1.3, 0.0,
			false, false, 41, 0.9)
		return
	_rajada("MorteVFX", Vector2(0.0, -10.0), 26, 0.6,
		Vector2(0.0, -1.0 * _sinal_grav), 55.0, Color(0.9, 0.18, 0.28))


## 9G: arranque do dash -- o rasto e o estalo da prancha 07. O rasto nasce
## atrás dela e fica no mundo; o estalo sai dos pés, virado ao contrário do
## sentido do dash. Nada disto toca na física do dash.
func _vfx9g_dash() -> void:
	if not Vfx9G.ativo(self):
		return
	Vfx9G.tocar(self, "dash_trail", global_position + Vector2(-10.0 * _olha_para, -6.0),
		1.0, 0.0, _olha_para > 0.0, _sinal_grav < 0.0, -1, DUR_DASH)
	Vfx9G.tocar(self, "dash_impact", global_position + Vector2(-16.0 * _olha_para, 10.0 * _sinal_grav),
		0.8, 0.0, _olha_para > 0.0, _sinal_grav < 0.0, -1, 0.26)


func _sfx_dash() -> void:
	Som.toca("dash", -11.0, 1.0, 0.03)


func _sfx_ativar_escudo() -> void:
	# Ativacao: o mesmo metal disponivel, mas curto/agudo e discreto. O
	# impacto confirmado vive em `_ao_bloquear`, mais grave e mais alto.
	Som.toca("bloqueio", -18.0, 1.28, 0.01, 0.18,
		"player_shield_activation")


## 9G: a cúpula de energia da prancha 07 substitui os polígonos desenhados por
## código. Os polígonos ficam escondidos (não apagados: fora da Região I são
## eles que se veem). O clarão do bloqueio continua a vir do `_cupula_flash`.
func _vfx9g_escudo() -> void:
	if not Vfx9G.ativo(self) or _escudo == null:
		return
	if _escudo_9g == null:
		_escudo_9g = Vfx9G.novo("defend_shield", true)
		if _escudo_9g == null:
			return
		_escudo_9g.z_index = 1
		_escudo.add_child(_escudo_9g)
		_escudo_9g.play("ciclo")
		for n in ["Cupula", "Aro", "Glow", "Placa"]:
			var c := _escudo.get_node_or_null(n) as CanvasItem
			if c:
				c.visible = false
	var respira := 0.5 + 0.5 * sin(_anim_t * 5.5)
	var e := 0.95 + 0.05 * respira + 0.1 * _cupula_flash
	_escudo_9g.scale = Vector2(e, e)
	_escudo_9g.modulate = Color(1, 1, 1).lerp(Color(2.2, 2.0, 2.4), _cupula_flash)


func _rajada(nome: String, desvio: Vector2, n: int, vida_s: float, dir: Vector2,
		vel: float, cor: Color) -> void:
	if get_parent() == null:
		return
	var p := CPUParticles2D.new()
	p.name = nome
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = n
	p.lifetime = vida_s
	p.direction = dir
	p.spread = 70.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vel * 0.5
	p.initial_velocity_max = vel
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.5
	var rampa := Gradient.new()
	rampa.set_color(0, cor)
	rampa.set_color(1, Color(cor, 0.0))
	p.color_ramp = rampa
	p.global_position = global_position + desvio
	get_parent().add_child(p)
	p.emitting = true
	get_tree().create_timer(vida_s + 0.2, false).timeout.connect(p.queue_free)


func _adicionar_animacao_de_tira(sf: SpriteFrames, nome: String, cfg: Array,
		dir_tiras: String) -> void:
	if sf.has_animation(nome):
		sf.remove_animation(nome)
	sf.add_animation(nome)
	sf.set_animation_speed(nome, cfg[1])
	sf.set_animation_loop(nome, cfg[2])
	var tex: Texture2D = load("res://assets/sprites/pixel/%s/%s.png" % [dir_tiras, nome])
	if tex == null:
		return
	var n: int = cfg[0]
	var fw := tex.get_width() / maxi(1, n)
	for i in n:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, tex.get_height())
		sf.add_frame(nome, at)


func _montar_fallbacks_piloto_5g(sf: SpriteFrames) -> void:
	# Travagem: últimos três momentos da passada e regresso ao primeiro idle.
	sf.add_animation("run_brake")
	sf.set_animation_speed("run_brake", 14.0)
	sf.set_animation_loop("run_brake", false)
	for indice in [9, 10, 11]:
		sf.add_frame("run_brake", sf.get_frame_texture("run", indice))
	sf.add_frame("run_brake", sf.get_frame_texture("idle", 0))
	# Aterragem: fecha a queda e estabiliza em idle. O alias `aterrar` preserva
	# o nome legado do runtime; `land` torna o fallback explícito e substituível.
	for nome in ["land", "aterrar"]:
		if sf.has_animation(nome):
			sf.remove_animation(nome)
		sf.add_animation(nome)
		sf.set_animation_speed(nome, 12.0)
		sf.set_animation_loop(nome, false)
		sf.add_frame(nome, sf.get_frame_texture("fall", 3))
		sf.add_frame(nome, sf.get_frame_texture("idle", 0))


## Pousa no `Corpo` o shader que troca as duas rampas de cinzento do rig
## pelas cores da arma/armadura equipadas (ver `equipamento.gdshader`).
## Só faz sentido nos rigs onde a lâmina e as placas estão pintadas dentro
## do frame -- no rig "codigo" a arma é um nó à parte e a armadura é
## vetorial, e aí o shader não tem nada para apanhar.
const RIGS_COM_PALETA := ["cavaleiro"]

func _montar_material_equipamento() -> void:
	if _corpo == null or not RIGS_COM_PALETA.has(RIG):
		return
	var sh: Shader = load("res://assets/shaders/equipamento.gdshader")
	if sh == null:
		return
	_mat_equip = ShaderMaterial.new()
	_mat_equip.shader = sh
	_corpo.material = _mat_equip


## Mostra o que está equipado no boneco (pedido do Paulo, 3 set 2026).
##
## Dois caminhos, conforme o rig:
##  - rig "codigo": a `Arma` é um Sprite2D à parte (tira de 20 lâminas) e a
##    armadura são polígonos vetoriais -- basta ligá-los e recolori-los.
##  - rigs prontos ("cavaleiro"): a lâmina e as placas estão pintadas DENTRO
##    de cada frame, em sítios diferentes por frame. Pôr a `Arma` por cima
##    dava duas espadas; o que funciona é trocar a paleta pelo shader
##    (`_mat_equip`) -- o fio da lâmina fica da cor da arma e as placas da
##    cor da armadura, em todos os 18 estados e sem tabelas de posição.
func _aplicar_equipamento() -> void:
	var wi := Equipamento.indice_arma(EstadoJogo.arma_equipada)
	var ai := Equipamento.indice_armadura(EstadoJogo.armadura_equipada)
	if _arma:
		# nos rigs prontos a lâmina já está desenhada no frame
		_arma.visible = wi >= 0 and RIG == "codigo"
		if wi >= 0:
			_arma.frame = wi
	if _mat_equip:
		_mat_equip.set_shader_parameter("cor_arma", Equipamento.cor_arma(wi))
		_mat_equip.set_shader_parameter("peso_arma", 1.0 if wi >= 0 else 0.0)
		_mat_equip.set_shader_parameter("cor_armadura", Equipamento.cor_armadura(ai))
		_mat_equip.set_shader_parameter("peso_armadura", 1.0 if ai >= 0 else 0.0)
	if _luz_lamina:
		_luz_lamina.color = _cor_golpe()
	if _corpo:
		_corpo.modulate = _tint_armadura()
	_aplicar_visual_armadura()


## Recolore (e "engorda") as placas de armadura vetoriais que vivem sob o
## `Sprite` -- herdam o squash/stretch/flip da animação procedural.
func _aplicar_visual_armadura() -> void:
	if _armadura == null:
		return
	if RIG != "codigo":
		_armadura.visible = false  # os rigs prontos já trazem roupa própria
		return
	var ai := Equipamento.indice_armadura(EstadoJogo.armadura_equipada)
	_armadura.visible = ai >= 0
	if ai < 0:
		return
	var base := Equipamento.cor_armadura(ai)
	var esc := base.darkened(0.34)
	var clr := base.lerp(Color.WHITE, 0.45)
	var t := float(ai) / 9.0   # 10 armaduras (era 15)
	_pinta(_armadura.get_node_or_null("Peito"), Color(base.r, base.g, base.b, 0.93))
	_pinta(_armadura.get_node_or_null("OmbroEsq"), Color(clr.r, clr.g, clr.b, 0.96))
	_pinta(_armadura.get_node_or_null("OmbroDir"), Color(clr.r, clr.g, clr.b, 0.96))
	_pinta(_armadura.get_node_or_null("Cinto"), Color(esc.r, esc.g, esc.b, 0.96))
	var trim := _armadura.get_node_or_null("Trim")
	if trim:
		var tc := clr.lerp(Color.WHITE, 0.4)
		trim.default_color = Color(tc.r, tc.g, tc.b, 0.55)
	var bulk := 1.0 + 0.16 * t
	_armadura.scale = Vector2(bulk, bulk)


func _pinta(n: Node, c: Color) -> void:
	if n and "color" in n:
		n.color = c


func _physics_process(dt: float) -> void:
	_dash_recarga = maxf(0.0, _dash_recarga - dt)
	_rolar_recarga = maxf(0.0, _rolar_recarga - dt)
	_pos_roll_t = maxf(0.0, _pos_roll_t - dt)
	_invulneravel = maxf(0.0, _invulneravel - dt)
	_impulso_externo_t = maxf(0.0, _impulso_externo_t - dt)
	_hurt_t = maxf(0.0, _hurt_t - dt)
	# planar é estado de UM frame: só volta a verdadeiro no ramo do movimento
	# normal (dash, rolamento, escudo, gancho e voo nunca planam)
	_planando = false
	_descartar_planar_invalido(dt)
	_tick_estados(dt)
	_aterrar_t = maxf(0.0, _aterrar_t - dt)
	# aterragem: só depois de ter estado mesmo no ar
	if is_on_floor():
		if _no_ar_antes:
			_aterrar_t = 0.16
		_no_ar_antes = false
	elif _vy() > 120.0:
		_no_ar_antes = true
	_lancar_restante = maxf(0.0, _lancar_restante - dt)
	_preso = maxf(0.0, _preso - dt)
	_parede_lock = maxf(0.0, _parede_lock - dt)
	_borda_lock = maxf(0.0, _borda_lock - dt)
	_djump_t = maxf(0.0, _djump_t - dt)
	_gancho_cd = maxf(0.0, _gancho_cd - dt)
	_leve = maxf(0.0, _leve - dt)
	_sons_de_movimento(dt)
	if _inverso_restante > 0.0:
		_inverso_restante -= dt
		if _inverso_restante <= 0.0:
			_inverso = 1.0

	# a barra de Energia regenera-se sozinha depois de usada
	if _energia < ENERGIA_MAX:
		_energia = minf(ENERGIA_MAX, _energia + REGEN_ENERGIA * (1.0 + EstadoJogo.bonus("regen_energia")) * dt)  # melhoria "foco"
		energia_mudou.emit(_energia, ENERGIA_MAX)

	# FLYMODE (só DEVELOPER MODE, botão na DevBarra): voa livre e atravessa
	# tudo. Sem `move_and_slide` -> zero colisão. Ao desligar cai à plataforma.
	if _voando:
		var vx := Input.get_axis("mover_esquerda", "mover_direita")
		var vy := Input.get_axis("mirar_cima", "mirar_baixo")
		var v := Vector2(vx, vy)
		if v.length() > 1.0:
			v = v.normalized()
		velocity = v * VEL_VOO
		if vx != 0.0:
			_olha_para = signf(vx)
		move_and_slide()  # collision_mask = 0 enquanto voa -> atravessa tudo
		_mov.velocidade = velocity
		return

	# GANCHO: enquanto está pendurada, o pêndulo é a física toda. Nada do
	# que vem a seguir (andar, saltar, dash, gravidade) se aplica.
	if _gancho_ativo:
		_passo_gancho(dt)
		return

	var dir := Input.get_axis("mover_esquerda", "mover_direita") * _inverso
	if dir != 0.0 and _rolar_restante <= 0.0:
		_olha_para = signf(dir)  # o flip visual é feito em _animar()

	# agachar: segura S no chão, sem andar nem estar noutra ação -> não anda
	_agachado = is_on_floor() and Input.is_action_pressed("mirar_baixo") \
		and dir == 0.0 and _ataque_restante <= 0.0 and _rolar_restante <= 0.0 \
		and _dash_restante <= 0.0 and not _defendendo
	if _agachado:
		dir = 0.0

	# teia no chão: NÃO prende -- só abranda muito (anda-se sempre para fora,
	# devagar). O `_preso` decai sozinho no _physics_process e está limitado
	# a `MAX_PRESO`, por isso uma teia permanente nunca deixa a Koliani presa.
	if _preso > 0.0:
		dir *= 0.34

	# escalar paredes: encostada a uma parede no ar, a segurar na direção dela
	if EstadoJogo.tem_habilidade("escalar_paredes") and _parede_lock <= 0.0 \
			and not is_on_floor() and is_on_wall_only() \
			and _dash_restante <= 0.0 and _rolar_restante <= 0.0:
		var nx := signf(get_wall_normal().x)
		# só agarra quando NÃO está a subir depressa -- assim um salto por
		# cima de um obstáculo baixo não fica preso a colar-se à parede.
		if not _escalando and dir != 0.0 and signf(dir) == -nx and velocity.y > -60.0:
			_escalando = true
		elif _escalando and dir != 0.0 and signf(dir) == nx:
			_escalando = false  # largou para o lado oposto
	else:
		_escalando = false

	if _escalando:
		var n := get_wall_normal()
		_olha_para = -signf(n.x)  # virada para a parede
		velocity.x = -n.x * 40.0  # cola-se
		# escorrega SEMPRE pela parede abaixo -- não se fica fixo. ↑ trava e
		# sobe, ↓ desce mais depressa.
		var vsub := Input.get_action_strength("mirar_baixo") - Input.get_action_strength("mirar_cima")
		velocity.y = clampf(VEL_DESLIZE_PAREDE + vsub * VEL_ESCALAR, -VEL_ESCALAR, VEL_ESCALAR * 1.5)
		if Input.is_action_just_pressed("saltar"):
			velocity = Vector2(n.x * WALLJUMP.x, WALLJUMP.y)
			_escalando = false
			_parede_lock = 0.28
			_mov.saltos_dados = 0  # o salto de parede não gasta o salto do ar
			Som.toca("salto", -10.0, 1.0, 0.03)
		move_and_slide()
		_mov.velocidade = velocity
		_estava_no_chao = false
		return

	# --- agarrar a borda (básico) -----------------------------------------
	# a cair (ou quase parada no ar) rente ao rebordo de uma plataforma:
	# agarra-se. Não corre se estiver a escalar, a rolar, a dar dash, ou
	# logo a seguir a largar/subir.
	if not _borda and _borda_lock <= 0.0 and not is_on_floor() \
			and _rolar_restante <= 0.0 and _dash_restante <= 0.0 \
			and _ataque_restante <= 0.0 and _preso <= 0.0 \
			and velocity.y > -30.0:
		var lado := signf(dir) if dir != 0.0 else _olha_para
		var lip_y := _detetar_borda(lado)
		if not is_nan(lip_y):
			_borda = true
			_borda_lado = lado
			global_position.y = lip_y + 34.0  # mãos ao nível do rebordo
			# Salto de posição: sem isto a interpolação desenhava-a a subir
			# desde onde estava, em vez de já agarrada ao rebordo.
			reset_physics_interpolation()
			velocity = Vector2.ZERO
			_mov.saltos_dados = 0
			Som.toca("agarrar", -14.0, 1.0, 0.04)

	if _borda:
		_olha_para = _borda_lado
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("saltar") or Input.is_action_just_pressed("mirar_cima"):
			# sobe para cima da plataforma
			velocity = Vector2(_borda_lado * BORDA_MANTLE.x, BORDA_MANTLE.y)
			_mov.velocidade = velocity
			_mov.saltos_dados = 0
			_borda = false
			_borda_lock = 0.25
			Som.toca("salto", -10.0, 1.0, 0.03)
		elif Input.is_action_pressed("mirar_baixo") \
				or (dir != 0.0 and signf(dir) == -_borda_lado):
			_borda = false
			_borda_lock = 0.22
		move_and_slide()
		_mov.velocidade = velocity
		_estava_no_chao = false
		return

	# wall-jump básico (sempre, não precisa da habilidade "escalar_paredes"):
	# no ar, encostada a uma parede e a segurar CONTRA ela -> chuta para
	# fora. Não gasta o salto do ar. Perde para o escalar quando este está
	# ativo (esse já saiu acima com `return`).
	if not is_on_floor() and is_on_wall_only() and _parede_lock <= 0.0 \
			and not _escalando and _dash_restante <= 0.0 and _rolar_restante <= 0.0 \
			and velocity.y > -140.0 and dir != 0.0 \
			and signf(dir) == -signf(get_wall_normal().x) \
			and Input.is_action_just_pressed("saltar"):
		var wn := get_wall_normal()
		velocity = Vector2(wn.x * WALLJUMP.x, WALLJUMP.y)
		_parede_lock = 0.24
		_mov.saltos_dados = 0  # o chute de parede não gasta o salto do ar
		_mov.velocidade = velocity
		_olha_para = signf(wn.x)
		Som.toca("salto", -10.0, 1.0, 0.03)
		move_and_slide()
		_mov.velocidade = velocity
		_estava_no_chao = false
		return

	# defesa: só com a habilidade "escudo", em pé, e não a meio de outra ação
	var defendia := _defendendo
	_defendendo = EstadoJogo.tem_habilidade("escudo") \
		and Input.is_action_pressed("defender") \
		and _rolar_restante <= 0.0 and _dash_restante <= 0.0 and _ataque_restante <= 0.0 \
		and is_on_floor()
	if _defendendo and not defendia:
		_sfx_ativar_escudo()

	# ataque leve -- bloqueado enquanto rola ou defende. Combo: um novo
	# golpe a meio do atual fica bufferizado (`_combo_pedido`) e dispara
	# assim que este acabar, em vez de se perder.
	if not _defendendo and _rolar_restante <= 0.0 and Input.is_action_just_pressed("atacar"):
		# Dash -> ataque é um cancel explícito; não deixa o estado de dash
		# continuar por baixo do golpe nem duplica a hitbox.
		if _dash_restante > 0.0:
			_dash_restante = 0.0
		if _ataque_restante > 0.0:
			_combo_pedido = not _ataque_no_ar
		else:
			_iniciar_ataque()
	if _ataque_restante > 0.0:
		_ataque_restante -= dt
		_atualizar_janela_ataque()
		if _ataque_restante <= 0.0:
			_desativar_hitbox_ataque()
			if _combo_pedido:
				_combo_pedido = false
				_iniciar_ataque()
			else:
				_ataque_no_ar = false
	elif _combo_janela > 0.0:
		_combo_janela -= dt
		if _combo_janela <= 0.0:
			_combo_passo = 0

	# Disparos contínuos enquanto o botão estiver premido.
	_tratar_lancar(dt)

	# estados exclusivos de movimento: rolamento > dash > movimento normal
	if _rolar_restante > 0.0:
		_rolar_restante -= dt
		if _rolar_restante <= 0.0:
			_pos_roll_t = POS_ROLL_JANELA   # abre a janela de crítico pós-rolamento
		velocity.x = _olha_para * VEL_ROLAR
		if not is_on_floor():
			velocity.y = Movimento.aplicar_gravidade(
				velocity.y, dt, _grav_escala, _sinal_grav)
	elif _dash_restante > 0.0:
		_dash_restante -= dt
		velocity.x = _olha_para * VEL_DASH
		velocity.y = 0.0
	elif _defendendo:
		# escudo erguido: anda-se devagar, sem saltar/dash/rolar
		velocity.x = move_toward(velocity.x, dir * VEL_DEFESA, Movimento.ACEL_CHAO * dt)
		if is_on_floor():
			velocity.y = 0.0
		else:
			velocity.y = Movimento.aplicar_gravidade(
				velocity.y, dt, _grav_escala, _sinal_grav)
		_mov.velocidade = velocity
	elif Input.is_action_just_pressed("rolar") and Movimento.pode_rolar(
			_rolar_recarga, is_on_floor(), _rolar_restante, _dash_restante):
		_rolar_restante = DUR_ROLAR
		_rolar_recarga = RECARGA_ROLAR
		Som.toca("rolamento", -13.0, 1.0, 0.04)
		if Vfx9G.ativo(self):
			Vfx9G.tocar(self, "roll_dodge", global_position + Vector2(0.0, 6.0 * _sinal_grav),
				1.0, 0.0, _olha_para < 0.0, _sinal_grav < 0.0, -1, DUR_ROLAR)
		_invulneravel = maxf(_invulneravel, DUR_ROLAR + EstadoJogo.bonus("iframes_roll"))  # melhoria "agilidade"
		# roll-cancel (pegada Dead Cells): o rolamento corta o recovery do
		# ataque -> encadeia-se ataque -> rolar -> ataque sem esperar
		if _ataque_restante > 0.0:
			_cancelar_ataque()
	elif Input.is_action_just_pressed("dash") and _dash_recarga <= 0.0 \
			and EstadoJogo.tem_habilidade("dash") and (
			is_on_floor() or EstadoJogo.tem_habilidade("dash_aereo")):
		# Ataque -> Dash corta recovery e a janela física antes de arrancar.
		if _ataque_restante > 0.0:
			_cancelar_ataque()
		_dash_restante = DUR_DASH
		_dash_recarga = RECARGA_DASH
		_acender_aura(0.8)
		_sfx_dash()
		_vfx9g_dash()
		_invulneravel = maxf(_invulneravel, DUR_DASH)
	else:
		var saltos_max := 2 if EstadoJogo.tem_habilidade("salto_duplo") else 1
		var saltos_antes := _mov.saltos_dados
		# PLANAR: habilidade permanente (N63) OU uma `ZonaPlanar` (N08), e
		# só a segurar o botão. Durante o atordoamento do dano fica suspenso
		# (o golpe lê-se como queda a sério). O `Movimento` é que decide se
		# ela já está a cair -- planar nunca acrescenta subida.
		var planar_pedido := Input.is_action_pressed("saltar") \
			and pode_planar() and _hurt_t <= 0.0
		_mov = Movimento.passo(
			_mov, dir,
			Input.is_action_just_pressed("saltar"),
			Input.is_action_pressed("saltar") or _impulso_externo_t > 0.0,
			is_on_floor(), dt, saltos_max, _grav_escala, _acel_escala,
			planar_pedido,
			_sinal_grav,
		)
		_planando = planar_pedido and not is_on_floor() \
			and _mov.velocidade.y * _sinal_grav > 0.0
		velocity = _mov.velocidade
		if _mov.saltos_dados > saltos_antes:
			Som.toca("salto_duplo" if _mov.saltos_dados >= 2 else "salto",
				-10.0, 1.0, 0.03)
			if _mov.saltos_dados >= 2:
				_djump_t = 0.45  # mostra a animação do salto duplo
				_vfx_salto_duplo()

	# batida do Coração Putrefacto (fase 2): gravidade aliviada -- a Koliani
	# fica "leve" e a queda abranda para lhe dar tempo no ar
	if _leve > 0.0 and _vy() > 0.0:
		velocity.y *= 0.4

	# corrente de ar (Torre dos Ventos, nível 12): sobe depressa enquanto lá
	# estiver E no ar. Se estiver POUSADA numa plataforma dentro da corrente,
	# o vento não a levanta -- assim o salto/duplo salto funcionam normal.
	# Segurar "baixo" (mirar_baixo) deixa descer contra o vento.
	if _vento_restante > 0.0 and not is_on_floor():
		_vento_restante -= dt
		if Input.is_action_pressed("mirar_baixo"):
			velocity.y = minf(velocity.y + _vento_forca * 0.7 * dt, _vento_alvo * 0.85)
		else:
			velocity.y = maxf(velocity.y - _vento_forca * dt, -_vento_alvo)
	elif _vento_restante > 0.0:
		_vento_restante -= dt

	_aplicar_ventos_externos(dt)

	# cair em cima de um inimigo = golpe de espada + pulo automático (estilo
	# Mario). Janela GENEROSA: basta vir a descer e apanhar o bicho grosso
	# modo por cima -- serve para inimigos de vários tamanhos. Encadeia:
	# cada pisão devolve os saltos de ar todos.
	_stomp_cd = maxf(0.0, _stomp_cd - dt)
	if EstadoJogo.tem_habilidade("pogo") and _stomp_cd <= 0.0 \
			and _vy() > 40.0 and not is_on_floor() and _dash_restante <= 0.0:
		var pes := global_position.y + 24.0
		for e in get_tree().get_nodes_in_group("inimigos"):
			if not is_instance_valid(e) or not (e as Node).has_method("receber_dano"):
				continue
			if "vida" in e and e.vida <= 0:
				continue
			# CHEFES NÃO SE PISAM (pedido do Paulo, 3 set 2026): nem dano, nem
			# ressalto. A banda de aceitação deles era generosa (210 px de
			# altura) e saltar-lhes para cima era a maneira mais barata de os
			# despachar -- ainda por cima atirava a Koliani ecrã acima, para
			# fora do cenário desenhado. A luta de chefe faz-se com espada e
			# tiro; encostar-se a um custa dano de contacto, como a qualquer
			# outro bicho.
			if (e as Node).is_in_group("chefes"):
				continue
			var ep: Vector2 = (e as Node2D).global_position
			if absf(ep.x - global_position.x) > 46.0:
				continue
			# a Koliani vem a descer por cima e os pés dela na banda do topo
			if global_position.y > ep.y + 6.0 or pes < ep.y - 52.0 or pes > ep.y + 30.0:
				continue
			var crit_stomp: bool = e.has_method("esta_vulneravel") and e.esta_vulneravel()
			e.receber_dano(_dano_golpe(), 0.0, crit_stomp)
			# pulo automático ALTO, imune ao corte de salto (ver aplicar_impulso)
			aplicar_impulso(Vector2(0.0, -STOMP_RESSALTO), true)
			_invulneravel = maxf(_invulneravel, 0.3)
			_stomp_cd = 0.22
			_pop = 1.0
			_squash = maxf(_squash, 0.5)
			_abanar(TREMOR_CRIT if crit_stomp else TREMOR_PISAO)
			_hitstop(HITSTOP_CRIT if crit_stomp else HITSTOP_PISAO)
			# pisão na carne: pancada surda, sem o silvo da espada
			Som.toca("acerto", -10.0, 0.88, 0.03)
			_pop_impacto(ep)
			break

	# pogo: cair em cima de uma serra / espinhos (grupo "pogavel", layer 6)
	# -> ressalta em vez de levar o golpe (os i-frames apanham o toque desse
	# frame). Só a descer a sério e pela parte de cima.
	if EstadoJogo.tem_habilidade("pogo") and _stomp_cd <= 0.0 \
			and _vy() > 90.0 and not is_on_floor() and _dash_restante <= 0.0:
		var esp := get_world_2d().direct_space_state
		var rq := PhysicsRayQueryParameters2D.create(
			global_position + Vector2(0.0, 16.0), global_position + Vector2(0.0, 46.0), 1 << 5)
		rq.collide_with_areas = true
		rq.collide_with_bodies = false
		rq.hit_from_inside = true
		rq.exclude = [self]
		var ph := esp.intersect_ray(rq)
		if not ph.is_empty() and (ph["collider"] as Node).is_in_group("pogavel"):
			aplicar_impulso(Vector2(0.0, -STOMP_RESSALTO), true)
			_invulneravel = maxf(_invulneravel, 0.35)
			_stomp_cd = 0.22
			_pop = 1.0
			_squash = maxf(_squash, 0.5)
			_abanar(TREMOR_PISAO)
			_hitstop(HITSTOP_PISAO)
			Som.toca("acerto", -10.0, 1.0, 0.04)
			_pop_impacto(global_position + Vector2(0.0, 24.0))

	# passo em frente do golpe: empurra SEMPRE para a frente e nunca trava
	# quem já vai mais depressa (correr a atacar continua a correr).
	if _avanco_restante > 0.0:
		_avanco_restante -= dt
		var f := clampf(_avanco_restante / maxf(_avanco_dur, 0.001), 0.0, 1.0)
		var empurrao := _olha_para * _avanco_vel * f
		if _olha_para > 0.0:
			velocity.x = maxf(velocity.x, empurrao)
		else:
			velocity.x = minf(velocity.x, empurrao)

	var vel_queda := _vy()
	move_and_slide()
	_mov.velocidade = velocity

	# Aterragem em três tiers, sempre só com feedback: nunca bloqueia input.
	var no_chao := is_on_floor()
	var tier_aterragem := Movimento.tier_aterragem(vel_queda) \
		if no_chao and not _estava_no_chao else 0
	if tier_aterragem > 0:
		if tier_aterragem >= 2:
			if Vfx9G.ativo(self):
				Vfx9G.tocar(self, "land_impact", global_position + Vector2(0.0, 22.0 * _sinal_grav),
					1.0, 0.0, false, _sinal_grav < 0.0, -1, 0.4)
			elif _po:
				_po.restart()
		var squash_tier: float = ATERRAGEM_SQUASH[tier_aterragem]
		var tremor_tier: float = ATERRAGEM_TREMOR[tier_aterragem]
		var volume_tier: float = ATERRAGEM_VOLUME[tier_aterragem]
		_squash = maxf(_squash, squash_tier)
		if tremor_tier > 0.0:
			_abanar(tremor_tier)
		Som.toca("aterrar", volume_tier, 1.0, 0.02, 0.0, "",
			Som.Prioridade.MEDIA if tier_aterragem >= 3 else Som.Prioridade.NORMAL)
	_estava_no_chao = no_chao

	# caiu num fosso sem fundo -> conta como morte (reaparece no checkpoint)
	if global_position.y > Y_MORTE and vida > 0 and not _voando:
		if EstadoJogo.modo_dev:
			# `_pos_inicial` é só a posição em que a CENA carregou -- fica
			# desatualizada assim que se toca num checkpoint mais à frente
			# (era por isso que em modo dev não se reaparecia no checkpoint
			# tocado). `EstadoJogo.checkpoint` é que está sempre atual.
			var alvo := EstadoJogo.ponto_recuperacao()
			global_position = alvo if alvo != Vector2.ZERO else global_position
			reset_physics_interpolation()  # teletransporte: não arrastar
			velocity = Vector2.ZERO
		else:
			receber_dano(vida)


## Há um rebordo agarrável no lado `lado` (-1 esq / +1 dir)? Devolve o Y do
## topo da plataforma, ou NAN se não houver. Dois sensores: parede à frente
## à altura do peito E espaço livre à frente à altura da cabeça (= é mesmo
## um rebordo, não uma parede alta). Depois varre para baixo para achar o topo.
func _detetar_borda(lado: float) -> float:
	var espaco := get_world_2d().direct_space_state
	var qp := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, BORDA_PEITO),
		global_position + Vector2(lado * BORDA_ALCANCE, BORDA_PEITO), 1)
	qp.exclude = [self]
	var peito := espaco.intersect_ray(qp)
	if peito.is_empty():
		return NAN
	var qc := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, BORDA_CABECA),
		global_position + Vector2(lado * BORDA_ALCANCE, BORDA_CABECA), 1)
	qc.exclude = [self]
	if not espaco.intersect_ray(qc).is_empty():
		return NAN  # a parede continua acima -> não é um rebordo
	var x_face: float = peito["position"].x + lado * 3.0
	var qd := PhysicsRayQueryParameters2D.create(
		Vector2(x_face, global_position.y + BORDA_CABECA),
		Vector2(x_face, global_position.y + BORDA_PEITO + 8.0), 1)
	qd.exclude = [self]
	var topo := espaco.intersect_ray(qd)
	if topo.is_empty():
		return NAN
	return topo["position"].y


func _process(dt: float) -> void:
	# a escolha da tira vem PRIMEIRO: `_animar` precisa de saber que animação
	# está a ser desenhada para decidir o flip (ver `_flip_sprite`)
	_atualizar_anim()
	_animar(dt)


## Escolhe a animação do corpo conforme o estado (visual apenas).
func _atualizar_anim() -> void:
	if _corpo == null or _corpo.sprite_frames == null:
		return
	var sf := _corpo.sprite_frames
	var a := "idle"
	if _a_morrer and sf.has_animation("morte"):
		a = "morte"
	elif _hurt_t > 0.0 and sf.has_animation("hurt"):
		a = "hurt"
	elif _voando:
		a = "idle"  # Voo Dev sem queda infinita; preserva a reação ao dano.
	elif _rolar_restante > 0.0 and sf.has_animation("roll"):
		a = "roll"
	elif _dash_restante > 0.0 and sf.has_animation("dash"):
		a = "dash"
	elif _borda and sf.has_animation("borda"):
		a = "borda"
	elif _escalando or _borda:
		a = "wallslide"
	elif _ataque_restante > 0.0:
		a = _anim_ataque()
	elif _defendendo and sf.has_animation("defesa"):
		a = "defesa"
	elif _lancar_restante > 0.0 and sf.has_animation("lancar"):
		a = "lancar"
	elif _agachado:
		a = "crouch"
	elif usar_piloto_visual_5g or usar_golden_set:
		a = _anim_locomocao_piloto_5g(sf)
	elif not is_on_floor():
		if _djump_t > 0.0:
			a = "djump"
		elif _vy() < -20.0:
			a = "jump"
		else:
			a = "fall"
	elif _aterrar_t > 0.0 and sf.has_animation("aterrar"):
		a = "aterrar"
	elif absf(velocity.x) > 24.0:
		a = "run"
	if _corpo.animation != a:
		_corpo.play(a)
	elif not _corpo.is_playing():
		_corpo.play(a)
	_passo_cadencia_locomocao(a)

	# a arma acompanha grosso modo a pose: balanço no ataque, recolhida no ar
	# a Arma tem `offset` a pôr o punho na origem do nó -> roda pelo punho.
	# As lâminas da tira já apontam para cima-frente; rotation 0 = "em guarda".
	if _arma and _arma.visible:
		var rot := -0.15
		var off := Vector2(10, -5)
		if a.begins_with("attack"):
			var f := clampf(1.0 - _ataque_restante / maxf(_ataque_dur, 0.001), 0.0, 1.0)
			rot = lerpf(-1.1, 0.8, f)
			off = Vector2(9, -5)
		elif a == "wallslide":
			rot = 0.5
			off = Vector2(6, 0)
		elif a in ["jump", "jump_start", "jump_loop", "djump"]:
			rot = -0.7
			off = Vector2(7, -6)
		_arma.rotation = rot
		_arma.position = off


## Seleção estritamente visual dos estados 5G. Só observa o estado físico já
## calculado; não escreve velocidade, posição, colisões nem tempos de gameplay.
func _anim_locomocao_piloto_5g(sf: SpriteFrames) -> String:
	if not is_on_floor():
		_piloto_5g_em_movimento = false
		if _djump_t > 0.0 and sf.has_animation("djump"):
			_piloto_5g_no_ar = true
			return "djump"
		if not _piloto_5g_no_ar:
			_piloto_5g_no_ar = true
			return "jump_start" if _vy() < -20.0 else "fall"
		if _vy() > 20.0:
			return "fall"
		if _corpo.animation == &"jump_start" and _corpo.is_playing():
			return "jump_start"
		return "jump_loop"

	if _piloto_5g_no_ar:
		_piloto_5g_no_ar = false
		_piloto_5g_em_movimento = false
		return "land"
	if _aterrar_t > 0.0 and _corpo.animation == &"land" and _corpo.is_playing():
		return "land"

	var em_movimento := absf(velocity.x) > 24.0
	if em_movimento:
		var virou := _piloto_5g_em_movimento and not is_equal_approx(_piloto_5g_facing, _olha_para)
		_piloto_5g_facing = _olha_para
		if virou:
			return "turn"
		if _corpo.animation == &"turn" and _corpo.is_playing():
			return "turn"
		if not _piloto_5g_em_movimento:
			_piloto_5g_em_movimento = true
			return "run_start"
		if _corpo.animation == &"run_start" and _corpo.is_playing():
			return "run_start"
		return "run"

	if _piloto_5g_em_movimento:
		_piloto_5g_em_movimento = false
		return "run_brake"
	if _corpo.animation == &"run_brake" and _corpo.is_playing():
		return "run_brake"
	return "idle"


## Para que lado o sprite é espelhado. Por omissão é `_olha_para` (as tiras
## estão viradas à direita), menos nas poses agarradas à parede -- ver
## `PAREDE_ESPELHADA`. Olha para a animação que está MESMO a ser desenhada,
## para não inverter a Koliani quando o estado de parede escolhe outra tira.
func _flip_sprite() -> float:
	# as poses de parede golden seguem a convenção "virada à direita"
	if PAREDE_ESPELHADA and not usar_golden_set and _corpo != null \
			and (_corpo.animation == &"wallslide" or _corpo.animation == &"borda"):
		return -_olha_para
	return _olha_para


## Animação procedural do sprite: flip, squash/stretch, lean, pop de
## ataque e rastro da lâmina. Nada disto afeta a física.
func _animar(dt: float) -> void:
	if _sprite == null:
		return
	_anim_t += dt
	_squash = move_toward(_squash, 0.0, dt * 5.0)
	_pop = move_toward(_pop, 0.0, dt * 7.0)

	_cupula_flash = move_toward(_cupula_flash, 0.0, dt * 3.5)
	_aura_flash = move_toward(_aura_flash, 0.0, dt * 2.6)
	_animar_aura()

	# O rig "cavaleiro" já traz o escudo desenhado nos frames da defesa. Todos
	# os outros usam a placa daqui -- e o "shadowblade" nem sequer tem pose de
	# defesa no atlas, por isso antes disto NÃO aparecia escudo nenhum.
	if _escudo and RIG != "cavaleiro":
		_vfx9g_escudo()
		if _defendendo != _escudo.visible:
			_escudo.visible = _defendendo
			if _defendendo:
				_escudo.scale = Vector2.ONE
				_escudo_t = 0.0
		if _defendendo:
			_escudo_t += dt
			if _escudo_glow:
				# só o brilho pulsa -- a placa de metal fica opaca
				_escudo_glow.modulate.a = 0.5 + 0.4 * (0.5 + 0.5 * sin(_anim_t * 7.0))
			_animar_cupula()

	# Clarão curto em cada lançamento, sem acumular carga ao segurar.
	if _luz_carga:
		var pulso := clampf(_lancar_restante / DUR_LANCAR, 0.0, 1.0)
		_luz_carga.energy = 1.4 * pulso
		_luz_carga.scale = Vector2(0.22, 0.22) * (0.6 + 0.4 * pulso)

	var no_chao := is_on_floor()
	var vx := absf(velocity.x)
	var escala := Vector2.ONE
	var rot_alvo := 0.0

	if usar_golden_set and (_rolar_restante > 0.0 or _dash_restante > 0.0):
		# 9B.4: a cambalhota e a passada do dash já estão nos frames golden.
		# Esmagar (0,78 de altura) ou rodar o sprite por código era o que fazia
		# o boneco parecer chibi -- aqui só se deixa o rasto, que é um VFX à parte.
		_sprite.rotation = 0.0
		if _dash_restante > 0.0:
			_rasto_dash(dt)
	elif _rolar_restante > 0.0:
		escala = Vector2(1.2, 0.8)
		_sprite.rotation += dt * _olha_para * 20.0
	elif _dash_restante > 0.0:
		escala = Vector2(1.32, 0.78)
		_sprite.rotation = lerp_angle(_sprite.rotation, 0.0, dt * 18.0)
	elif _escalando and not RIG_PIXEL:
		escala = Vector2(0.86, 1.14)  # esticada contra a parede
		_sprite.rotation = lerp_angle(_sprite.rotation, _olha_para * 0.14, dt * 14.0)
	else:
		_sprite.rotation = lerp_angle(_sprite.rotation, rot_alvo, dt * 12.0)
		# Num rig de pixel-art nada disto se aplica: a pose de cada estado já
		# está desenhada, e deformar o sprite por cima só faz os pixéis
		# saltarem (ver `RIG_PIXEL`).
		if RIG_PIXEL:
			pass
		elif not no_chao:
			if velocity.y < 0.0:
				escala = Vector2(0.86, 1.16)
			else:
				var f := clampf(velocity.y / 900.0, 0.0, 1.0)
				escala = Vector2(1.0 + 0.16 * f, 1.0 - 0.16 * f)
		elif vx > 25.0:
			var b := sin(_anim_t * 22.0) * 0.06
			escala = Vector2(1.0 + b, 1.0 - b)
			_sprite.rotation = lerp_angle(_sprite.rotation, -_olha_para * 0.08, dt * 12.0)
		else:
			var b := sin(_anim_t * 3.0) * 0.02
			escala = Vector2(1.0 - b, 1.0 + b)

	# o "pop" do golpe e o squash da aterragem tambem deformavam o sprite --
	# e este bloco escapava ao guarda do RIG_PIXEL logo acima. Em pixel-art
	# nao se estica nada por codigo (ver `RIG_PIXEL`); o pop do ataque saiu de
	# vez com o resto dos efeitos da espada (pedido do Paulo, 4 set 2026).
	if not RIG_PIXEL:
		escala.x += _squash * 0.32 + _pop * 0.10
		escala.y += -_squash * 0.32 + _pop * 0.18
	_sprite.position.x = move_toward(_sprite.position.x, 0.0, dt * 90.0)
	if RIG_PIXEL:
		# em pixel-art o sprite tem de assentar em pixéis INTEIROS: meio pixel
		# de desvio faz a personagem cintilar com o filtro Nearest
		_sprite.position.x = roundf(_sprite.position.x)
	# `* _sinal_grav` no y: com a gravidade invertida (nível 67) o boneco
	# vira-se com o mundo. Tem de ser AQUI -- esta linha corre todos os
	# frames e reescrevia a volta que o `inverter_gravidade()` dá.
	_sprite.scale = Vector2(escala.x * _flip_sprite(), escala.y * _sinal_grav)


func _flash_branco() -> void:
	if _corpo == null:
		return
	var base := _tint_armadura()
	_corpo.modulate = Color(2.4, 2.4, 2.4)
	var t := create_tween()
	t.tween_property(_corpo, "modulate", base, 0.16)


## Cor de base do corpo (tinta da armadura ou branco), com sobre-brilho.
## Isto multiplica-se pelo `CanvasModulate` da Atmosfera (cor_ambiente do
## nível, tipicamente ~0.55-0.75 por canal, ainda mais baixo nos níveis de
## propósito escuro) -- um leve >1.0 aqui não chega para compensar isso;
## o Paulo continuou a achar a Koliani escura mesmo depois da 1.ª correção
## (2 set 2026), por isso o over-bright sobe bastante e a tinta da
## armadura pesa ainda menos, para ela ler sempre mais clara que o
## cenário à volta.
const _BRILHO_CORPO := Color(1.4, 1.38, 1.5)
## O rig "shadowblade" (a arte do Paulo) já é desenhado com contraste alto e
## a lâmina dele brilha sozinha: com o over-bright de cima a personagem saía
## rosa-choque e perdia o roxo escuro. Este é o mínimo que ainda a destaca do
## cenário sem lhe queimar a paleta.
const _BRILHO_SHADOW := Color(1.12, 1.10, 1.18)

func _tint_armadura() -> Color:
	if usar_prototipo_premium:
		# O Level 1 tem luz verde intensa; sem esta compensacao os grafites do
		# prototype ficam quase brancos e perdem a silhueta dark-fantasy.
		return Color(0.88, 0.86, 0.94)
	if RIG == "gothic":
		return Color.WHITE  # o rig já vem recolorido -- não pintar por cima
	if RIG == "shadowblade":
		return _BRILHO_SHADOW
	if RIGS_COM_PALETA.has(RIG):
		# a cor da armadura já vai às PLACAS pelo shader; puxá-la também para
		# o modulate pintava a pele e o cabelo e dava um boneco monocromático.
		return _BRILHO_CORPO
	var ai: int = Equipamento.indice_armadura(EstadoJogo.armadura_equipada)
	return _BRILHO_CORPO if ai < 0 else _BRILHO_CORPO.lerp(Equipamento.cor_armadura(ai), 0.3)


## A tinta de base com o estado por cima: verde envenenada, azul gelada. O
## estado TEM de se ver -- vida a descer sem nada no ecra' le'-se como bug.
func _tint_estado() -> Color:
	var c := _tint_armadura()
	if _veneno > 0.0:
		c = c.lerp(Color(0.45, 1.25, 0.5), 0.45)
	if _frio > 0.0:
		c = c.lerp(Color(0.55, 0.85, 1.35), 0.4)
	return c


## Faz correr o veneno e o frio. Chamado uma vez por frame de fisica.
func _tick_estados(dt: float) -> void:
	var tinha := _veneno > 0.0 or _frio > 0.0
	if _frio > 0.0:
		_frio = maxf(0.0, _frio - dt)
		if _frio <= 0.0:
			definir_acel_escala(1.0)
	if _veneno > 0.0:
		_veneno = maxf(0.0, _veneno - dt)
		_veneno_tick -= dt
		if _veneno_tick <= 0.0:
			_veneno_tick = VENENO_INTERVALO
			_dano_de_estado(_veneno_dano)
	if tinha and _corpo:
		_corpo.modulate = _tint_estado()


## Dano de ESTADO: sem i-frames, sem escudo, sem tremor de ecra. O que ele
## partilha com o dano normal e' a morte -- e a reducao da armadura, que e'
## do equipamento e vale sempre.
func _dano_de_estado(q: int) -> void:
	if EstadoJogo.modo_dev or _a_morrer:
		return
	var real := int(round(q * (1.0 - EstadoJogo.reducao_armadura())))
	vida = maxi(0, vida - maxi(1, real))
	vida_mudou.emit(vida, _vida_max())
	if vida <= 0:
		_morrer()


## VENENO (nivel 48, Vale dos Escorpioes). Renova em vez de somar: dez
## picadas seguidas nao valem dez venenos.
func envenenar(segundos: float, dano_tick := 4) -> void:
	if _a_morrer:
		return
	_veneno = maxf(_veneno, segundos)
	_veneno_dano = maxi(_veneno_dano, dano_tick)
	if _veneno_tick <= 0.0:
		_veneno_tick = VENENO_INTERVALO


## FRIO (nivel 45, Coracao do Inverno): abranda-a por tempo. Usa o mesmo
## `_acel_escala` do gelo -- sair da nevoa nao chega, e' preciso esperar.
func congelar_parcial(segundos: float, escala := 0.35) -> void:
	if _a_morrer:
		return
	_frio = maxf(_frio, segundos)
	definir_acel_escala(escala)


func _abanar(forca: float) -> void:
	if _camera and _camera.has_method("bater"):
		_camera.bater(forca)


## Pequena paragem de tempo real ("hitstop") para dar peso ao impacto.
##
## Nao poe o tempo a ZERO -- ver `HITSTOP_ESCALA_TEMPO`.
func _hitstop(segundos: float) -> void:
	if Engine.time_scale < 0.5:
		return
	Engine.time_scale = HITSTOP_ESCALA_TEMPO
	# NÃO usar `await` aqui: se a Koliani for libertada (reload de cena) a
	# meio, a corrotina morre e o time_scale ficava preso em 0 = freeze.
	# O timer vive na árvore e o Callable não segura `self`.
	get_tree().create_timer(segundos, true, false, true).timeout.connect(
		func() -> void: Engine.time_scale = 1.0)


func _iniciar_ataque() -> void:
	# encadeia o combo se ainda estamos na janela do golpe anterior;
	# senão volta ao 1.º hit ("Single").
	_ataque_no_ar = not is_on_floor()
	_combo_passo = 0 if _ataque_no_ar else (
		(_combo_passo + 1) % NUM_COMBO if _combo_janela > 0.0 else 0)
	# Os rigs com tiras extra apresentam os três golpes; no ar fica um golpe
	# único e coerente mesmo quando só existe a animação `attack`.
	var tem_combo := RIG == "cavaleiro" or RIG == "nova" or RIG == "shadowblade"
	_ataque_dur = DUR_COMBO[_combo_passo] if tem_combo else DUR_ATAQUE
	_ataque_restante = _ataque_dur
	_combo_janela = 0.0 if _ataque_no_ar else _ataque_dur + JANELA_COMBO
	_combo_pedido = false
	_alvos_atingidos_ataque.clear()
	_pop = 1.0
	# a aura acende mais a cada golpe do combo: o 3.º é o remate
	_acender_aura(0.42 + 0.19 * _combo_passo)
	# passo em frente: o golpe "pisa" para onde se olha (ver `AVANCO_VEL`).
	var i_av: int = clampi(_combo_passo, 0, AVANCO_VEL.size() - 1)
	_avanco_vel = AVANCO_VEL[i_av] * (1.0 if is_on_floor() else AVANCO_NO_AR)
	_avanco_dur = AVANCO_DUR[i_av]
	_avanco_restante = _avanco_dur
	# CADA golpe do combo tem som proprio (Execution 9H.13). Antes eram dois
	# samples com `pitch_scale` por cima (`TOM_COMBO`) -- o mesmo golpe quatro
	# vezes com outro tom, que e' exactamente o que soava a amador. Agora os
	# quatro crescem em corpo, em sopro e em cauda; o volume tambem sobe, mas
	# e' o que menos conta. `TOM_COMBO` fica so' como variacao ligeira.
	var tom: float = TOM_COMBO[clampi(_combo_passo, 0, TOM_COMBO.size() - 1)]
	var i_som: int = clampi(_combo_passo, 0, SOM_COMBO.size() - 1)
	Som.toca(SOM_COMBO[i_som], VOL_COMBO[i_som], lerpf(1.0, tom, 0.35), 0.02)
	_marcar_combo()
	_flash_golpe()
	_disparar_vfx_golpe()
	# NB: o balanco do remate ja' nao abana nem para o tempo -- o peso do
	# combo esta' todo na LIGACAO (ver `TREMOR_REMATE`/`HITSTOP_REMATE`).
	if _hitbox:
		_hitbox.scale.x = _olha_para
		_hitbox.monitoring = false


## Selo do combo: o "×2"/"×3" por cima da cabeça, que dá um salto a cada
## ligação e apaga quando a janela fecha. É o que faz o combo LER-SE como
## combo -- os três golpes saem dos mesmos frames e, sem contador, quem joga
## não distingue "encadeei" de "carreguei outra vez".
##
## O 1.º golpe não mostra nada de propósito: um "×1" em cada toque no botão
## era ruído constante. O selo aparece quando há mesmo cadeia.
func _marcar_combo() -> void:
	if _combo_passo <= 0:
		if _combo_selo:
			_combo_selo.visible = false
		return
	if _combo_selo == null:
		_combo_selo = Label.new()
		_combo_selo.name = "SeloCombo"
		_combo_selo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_combo_selo.add_theme_font_size_override("font_size", 20)
		_combo_selo.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.03, 0.95))
		_combo_selo.add_theme_constant_override("outline_size", 6)
		_combo_selo.z_index = 30
		_combo_selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_combo_selo.size = Vector2(80, 26)
		_combo_selo.pivot_offset = Vector2(40, 13)
		add_child(_combo_selo)
	_combo_selo.position = Vector2(-40.0, SELO_COMBO_Y)
	_combo_selo.text = "×%d" % (_combo_passo + 1)
	# o remate é dourado; as ligações do meio são o carmesim do rebrand
	_combo_selo.add_theme_color_override("font_color",
		Color(1.0, 0.86, 0.42) if _combo_passo == NUM_COMBO - 1 else Color(1.0, 0.46, 0.52))
	_combo_selo.visible = true
	_combo_selo.modulate.a = 1.0
	_combo_selo.scale = Vector2(1.55, 1.55)
	var t := create_tween()
	t.tween_property(_combo_selo, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(_ataque_dur + JANELA_COMBO * 0.6)
	t.tween_property(_combo_selo, "modulate:a", 0.0, 0.18)


## Altura do selo acima da origem da Koliani (o corpo mede ~72 px).
const SELO_COMBO_Y := -104.0


func _atualizar_janela_ataque() -> void:
	if _hitbox == null or _ataque_dur <= 0.0:
		return
	var passo := clampi(_combo_passo, 0, NUM_COMBO - 1)
	var progresso := clampf(1.0 - _ataque_restante / _ataque_dur, 0.0, 1.0)
	_hitbox.monitoring = janela_ataque_ativa(passo, progresso)


static func janela_ataque_ativa(passo: int, progresso: float) -> bool:
	var i := clampi(passo, 0, NUM_COMBO - 1)
	return progresso >= ATAQUE_ATIVO_INICIO[i] and progresso <= ATAQUE_ATIVO_FIM[i]


func _desativar_hitbox_ataque() -> void:
	if _hitbox:
		_hitbox.monitoring = false
	_alvos_atingidos_ataque.clear()


func _cancelar_ataque(reiniciar_combo := false) -> void:
	_ataque_restante = 0.0
	_avanco_restante = 0.0
	_combo_pedido = false
	_ataque_no_ar = false
	_desativar_hitbox_ataque()
	if _slash_vfx:
		_slash_vfx.visible = false
	if _vfx_combo and is_instance_valid(_vfx_combo):
		_vfx_combo.queue_free()
	_vfx_combo = null
	if reiniciar_combo:
		_combo_janela = 0.0
		_combo_passo = 0


## Nome da animação do golpe atual do combo ("attack".."attack4"). Cai
## sempre em "attack" se o rig não tiver as tiras extra (só o "cavaleiro").
func _anim_ataque() -> String:
	if _combo_passo <= 0:
		return "attack"
	var nome := "attack%d" % (_combo_passo + 1)
	if _corpo and _corpo.sprite_frames and _corpo.sprite_frames.has_animation(nome):
		return nome
	return "attack"


## Cor do golpe -- aço frio -> magenta conforme o tier da arma equipada.
const COR_GOLPE_BASE := Color(0.96, 0.55, 1.0)

func _cor_golpe() -> Color:
	var wi := Equipamento.indice_arma(EstadoJogo.arma_equipada)
	return COR_GOLPE_BASE if wi < 0 else Equipamento.cor_arma(wi).lerp(Color.WHITE, 0.4)


## Glow do golpe: um brilho ROXO ESCURO, curto e discreto. Pedido do Paulo
## (4 set 2026): "faça só um leve glow roxo escuro quando ela ataca, algo
## muito subtil". Daqui saíam antes dois arcos de luz a varrer com a lâmina
## (`_arco_luz`), um rasto em `Line2D` e um smear que esticava o sprite --
## tudo isso tapava a arte da personagem, e o rig "Shadowblade" já desenha
## o corte no próprio frame.
const COR_GLOW_GOLPE := Color(0.4, 0.13, 0.6)

func _flash_golpe() -> void:
	if _luz_golpe == null:
		return
	_luz_golpe.color = COR_GLOW_GOLPE
	_luz_golpe.energy = 0.0
	var tl := _luz_golpe.create_tween()
	tl.tween_property(_luz_golpe, "energy", 0.55, 0.05).set_ease(Tween.EASE_OUT)
	tl.tween_property(_luz_golpe, "energy", 0.0, DUR_ATAQUE + 0.08).set_ease(Tween.EASE_IN)


## Dispara ao premir e repete até largar. Bloqueado a defender/rolar/dar dash.
func _tratar_lancar(_dt: float) -> void:
	if not EstadoJogo.tem_habilidade("projetil") \
			or _defendendo or _rolar_restante > 0.0 or _dash_restante > 0.0:
		return
	if Input.is_action_pressed("lancar") and _lancar_restante <= 0.0:
		_lancar_projetil()


## Lança um tiro mágico numa das 8 direções (mira = eixos de movimento + W/S;
## sem mira, para onde está virada). Ilimitado, dá 1/3 do dano do golpe.
func _lancar_projetil() -> void:
	_lancar_restante = DUR_LANCAR
	if _corpo and _corpo.sprite_frames and _corpo.sprite_frames.has_animation("lancar"):
		_corpo.play("lancar")
		_corpo.set_frame_and_progress(0, 0.0)
	_pop = 1.0
	_acender_aura(0.7)
	var ax := Input.get_action_strength("mover_direita") - Input.get_action_strength("mover_esquerda")
	var ay := Input.get_action_strength("mirar_baixo") - Input.get_action_strength("mirar_cima")
	var aim := Movimento.direcao_mira(ax, ay, _olha_para)
	var p := PROJETIL_MAGICO.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position + aim * 20.0 + Vector2(0.0, -4.0)
	p.lancar(aim, maxi(1, roundi(_dano_golpe() / 3.0)))
	magia_lancada.emit()  # Ativa plataformas espectrais sem depender do feixe.
	Som.toca("lancar", -9.0, 1.0, 0.04)
	if _faiscas:
		_faiscas.position.x = absf(_faiscas.position.x) * signf(aim.x if aim.x != 0.0 else _olha_para)
		_faiscas.restart()


func _ao_acertar_corpo(corpo: Node) -> void:
	if corpo.has_method("receber_dano"):
		var alvo_id := corpo.get_instance_id()
		if _alvos_atingidos_ataque.has(alvo_id):
			return
		_alvos_atingidos_ataque[alvo_id] = true
		# CRÍTICO (pegada Dead Cells): inimigo vulnerável (gelo/fogo/sangue/
		# atordoado), golpe logo a seguir a um rolamento, ou golpe pelas costas.
		var crit := false
		if corpo.has_method("esta_vulneravel") and corpo.esta_vulneravel():
			crit = true
		elif _pos_roll_t > 0.0:
			crit = true
		elif corpo is Node2D and corpo.get("_direcao") != null \
				and signf(global_position.x - (corpo as Node2D).global_position.x) == -float(corpo._direcao):
			crit = true
		var passo := clampi(_combo_passo, 0, NUM_COMBO - 1)
		var dano := maxi(1, roundi(_dano_golpe() * float(DANO_COMBO[passo])))
		corpo.receber_dano(dano, sign(_olha_para), crit, float(RECUO_COMBO[passo]))
		# 3.º golpe: ATORDOA -- é o pagamento por arriscar o golpe lento.
		if passo == NUM_COMBO - 2 and corpo.has_method("atordoar"):
			corpo.atordoar(ATORDOA_COMBO)
		# remate do combo (4.º golpe) -> deixa o inimigo a SANGRAR
		if passo >= NUM_COMBO - 1 and corpo.has_method("sangrar"):
			corpo.sangrar(2.6, maxi(3, roundi(dano * 0.16)))
		if _faiscas:
			_faiscas.position.x = absf(_faiscas.position.x) * _olha_para
			_faiscas.restart()
		var remate := passo >= NUM_COMBO - 1
		# Os dois golpes do fim da cadeia (o que atordoa e o remate) pesam
		# mais. Continuam dentro da regra de 8.1C: <=2 frames a 165 Hz no
		# que acontece a toda a hora, <=4 no que é raro.
		var pesado := passo >= NUM_COMBO - 2
		_pop_impacto((corpo as Node2D).global_position if corpo is Node2D else global_position,
			crit or remate)
		_abanar(TREMOR_CRIT if crit else (TREMOR_REMATE if pesado else TREMOR_GOLPE))
		_hitstop(HITSTOP_CRIT if crit else (HITSTOP_REMATE if pesado else HITSTOP_GOLPE))
		# 9H.1: acertar num inimigo levanta a camada de intensidade da música
		# (só na Região I, e só fora do combate de chefe -- ver `Musica`).
		Musica.intensificar()
		if crit:
			Som.toca("acerto", -6.0, 1.25, 0.04, 0.0, "", Som.Prioridade.MEDIA)
		else:
			Som.toca("acerto", -8.0, 1.0, 0.04)


## "Frame de impacto": o anel pixel-art (`Impacto`) a abrir no ponto do
## acerto, com a cor da arma, mais o clarão antigo por baixo a dar o flash.
func _pop_impacto(pos: Vector2, forte := false) -> void:
	# 9G: "hit sparks" no acerto normal, "finisher burst" no remate/crítico --
	# o jogador distingue os dois sem olhar para a barra de vida.
	if Vfx9G.ativo(self):
		Vfx9G.tocar(self, "finisher_burst" if forte else "hit_sparks", pos,
			1.1 if forte else 0.9, randf_range(-0.25, 0.25), false, false, 40,
			0.34 if forte else 0.2)
		return
	Impacto.rebentar(self, pos, _cor_golpe().lerp(Color(1, 1, 1), 0.45), 2.2)
	var s := Sprite2D.new()
	s.texture = TEX_IMPACTO
	s.global_position = pos
	s.rotation = randf() * TAU
	s.scale = Vector2(0.25, 0.25)
	s.z_index = 39
	get_parent().add_child(s)
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", Vector2(1.2, 1.2), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "modulate:a", 0.0, 0.13)
	t.chain().tween_callback(s.queue_free)


## Um golpe é bloqueável se vier de frente. `dir_empurrao` é o sentido em
## A cúpula de energia roxa: cresce ao levantar o escudo, respira enquanto
## está de pé e dá um clarão a cada bloqueio.
func _animar_cupula() -> void:
	var abrir := clampf(_escudo_t / CUPULA_ABRIR, 0.0, 1.0)
	# TRANS_BACK à mão: passa de 1.0 e volta, para "estalar" ao abrir
	var e := abrir * (1.0 + 0.18 * sin(abrir * PI)) * (1.0 + 0.12 * _cupula_flash)
	var respira := 0.5 + 0.5 * sin(_anim_t * 5.5)
	if _escudo_cupula:
		_escudo_cupula.scale = Vector2(e, e * (0.97 + 0.03 * respira))
		_escudo_cupula.modulate.a = lerpf(CUPULA_ALPHA * (0.75 + 0.25 * respira),
			CUPULA_ALPHA_FLASH, _cupula_flash) * abrir
	if _escudo_aro:
		_escudo_aro.scale = Vector2(e, e * (0.97 + 0.03 * respira))
		_escudo_aro.modulate.a = minf(1.0,
			(ARO_ALPHA + 0.28 * respira + 0.38 * _cupula_flash)) * abrir


## A aura roxa. Respira sempre e acende com `_aura_flash` (golpe/dash/tiro).
func _animar_aura() -> void:
	var respira := 0.5 + 0.5 * sin(_anim_t * 2.3)
	var f := _aura_flash
	if _halo:
		var e := 1.0 + AURA_RESPIRA * respira + 0.35 * f
		_halo.scale = Vector2(0.62, 0.78) * e
		_halo.modulate.a = AURA_ALPHA * (0.8 + 0.2 * respira) + 0.4 * f
	if _luz_aura:
		_luz_aura.energy = AURA_ENERGIA * (0.85 + 0.15 * respira) + 1.1 * f


## Acende a aura (0..1). Chamado quando ela golpeia, faz dash ou lança.
func _acender_aura(forca := 1.0) -> void:
	_aura_flash = maxf(_aura_flash, clampf(forca, 0.0, 1.0))


## que o golpe empurra a Koliani (para longe da fonte); ela bloqueia se
## estiver virada para a fonte. Sem direção conhecida (0), o escudo vale.
func _bloqueia(dir_empurrao: float) -> bool:
	return Movimento.bloqueia_de_frente(dir_empurrao, _olha_para)


func _ao_bloquear() -> void:
	_invulneravel = maxf(_invulneravel, BLOQUEIO_IFRAMES)
	_cupula_flash = 1.0
	Som.toca("bloqueio", -11.0, 0.92, 0.02, 0.12, "player_shield_impact",
		Som.Prioridade.MEDIA)
	_abanar(2.5)
	if _escudo:
		_escudo.scale = Vector2(1.28, 1.16)
		var t := _escudo.create_tween()
		t.tween_property(_escudo, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _faiscas:
		_faiscas.position.x = absf(_faiscas.position.x) * _olha_para
		_faiscas.restart()


## Teia no chão: abranda a Koliani por `segundos` (não a prende). Limitado a
## `MAX_PRESO` para uma teia permanente nunca a segurar de vez. O escudo
## erguido protege-a.
const MAX_PRESO := 1.2

func prender(segundos: float) -> void:
	if _defendendo:
		return
	_preso = clampf(maxf(_preso, segundos), 0.0, MAX_PRESO)


## Alivia a gravidade da Koliani por `segundos` (batida do Coração
## Putrefacto, fase 2). Não a impede de andar/saltar -- só a faz cair devagar.
func flutuar(segundos: float) -> void:
	_leve = maxf(_leve, segundos)


## Curto período de invulnerabilidade concedido por fora (ex.: `Portal` ao
## teleportar -- evita levar dano no frame de chegada).
func conceder_iframes(segundos: float) -> void:
	_invulneravel = maxf(_invulneravel, segundos)


## Devolve os saltos do ar (um `Trampolim` chama isto -- depois do ressalto
## ainda se pode fazer o salto duplo).
func devolver_saltos_ar() -> void:
	_mov.saltos_dados = 0


## FLYMODE (DevBarra, só DEVELOPER MODE). Alterna voo livre: atravessa
## paredes, sem gravidade. Ao desligar, a gravidade normal volta e a Koliani
## cai até à plataforma mais próxima. Devolve o novo estado.
var _mask_guardada := 0

func alternar_voo() -> bool:
	if not EstadoJogo.modo_dev:
		return false
	_voando = not _voando
	velocity = Vector2.ZERO
	if _voando:
		_mask_guardada = collision_mask
		collision_mask = 0  # não colide com nada -> atravessa paredes
	else:
		collision_mask = _mask_guardada if _mask_guardada != 0 else collision_mask
		_mov.velocidade = Vector2.ZERO
		_mov.saltos_dados = 0
	Som.toca("salto_duplo" if _voando else "aterrar", -12.0, 1.0, 0.03)
	return _voando


## Impulso vindo de fora (Trampolim, Impulsor...). TEM de passar por aqui e
## não só mexer em `velocity`: o `Movimento.passo()` reescreve `velocity` a
## partir do `_mov.velocidade` a cada frame, por isso é preciso sincronizar
## os dois (senão o impulso é descartado no frame seguinte). Também arma
## `_impulso_externo_t`: sem isso, o "corte de salto" do `Movimento.passo()`
## (que reduz a velocidade vertical sempre que não se segura o botão de
## saltar) via-abaixo o impulso quase por completo já no frame a seguir --
## o trampolim mal se notava (o Paulo reportou "continua sem funcionar").
func aplicar_impulso(v: Vector2, manter_x := false) -> void:
	velocity.y = v.y
	if not manter_x:
		velocity.x = v.x
	_mov.velocidade = velocity
	_mov.saltos_dados = 0
	if v.y < 0.0:
		_impulso_externo_t = 0.4
	_estava_no_chao = false


## Define a escala da gravidade (Observatório Lunar, nível 14). 1 = normal,
## ~0.4 = "gravidade lunar" (salto alto, queda lenta). As `ZonaGravidade`
## chamam isto ao entrar/sair; a Sacerdotisa mexe nisto durante a luta.
func definir_grav_escala(v: float) -> void:
	_grav_escala = clampf(v, 0.2, 1.5)


## Atrito do chao (ver `_acel_escala`). Chamado pela `ZonaGelo`. O minimo e'
## 0.15 de proposito: abaixo disso ela deixa de conseguir mudar de sentido
## a tempo de qualquer coisa, e o gelo passava de mecanica a castigo.
func definir_acel_escala(v: float) -> void:
	_acel_escala = clampf(v, 0.15, 1.5)


## RETIRADO (pedido do Paulo): a inversão de controlos do Olho do Abismo
## (nível 20) dava a sensação de "o boneco anda ao contrário / perde os
## movimentos". Fica como no-op para não partir quem a chama.
func inverter_controlos(_segundos: float) -> void:
	pass


## Engata numa trepadeira e começa o balanço. Chamado pelo `PontoGancho`
## quando ela lhe passa perto NO AR -- não há botão para isto, e é de
## propósito: no telemóvel um botão novo é mais um polegar.
##
## A velocidade que ela trazia não se deita fora: projecta-se na tangente
## do círculo e vira velocidade angular. Chegar a correr e engatar dá um
## balanço grande; chegar quase parada dá um balanço pequeno.
func engatar(ancora: Vector2, comprimento := 0.0) -> void:
	if _gancho_ativo or _gancho_cd > 0.0 or _a_morrer:
		return
	_gancho_ativo = true
	_gancho_ancora = ancora
	var d := global_position - ancora
	_gancho_comp = comprimento if comprimento > 0.0 else clampf(d.length(), 48.0, 220.0)
	_gancho_theta = atan2(d.x, d.y)          # 0 = pendurada a direito
	var tangente := Vector2(cos(_gancho_theta), -sin(_gancho_theta))
	_gancho_vel = clampf(velocity.dot(tangente) / maxf(24.0, _gancho_comp),
		-Movimento.GANCHO_VEL_MAX, Movimento.GANCHO_VEL_MAX)
	velocity = Vector2.ZERO
	Som.toca("agarrar", -11.0, 1.0, 0.04)


## Larga a trepadeira. Sai pela tangente do círculo mais um empurrão para
## cima -- é isto que faz o balanço servir para atravessar: largar no fundo
## do arco atira-a para a frente, largar no alto atira-a para cima e quase
## parada.
func largar_gancho() -> void:
	if not _gancho_ativo:
		return
	_gancho_ativo = false
	_gancho_cd = 0.45
	velocity = Movimento.velocidade_ao_largar(_gancho_theta, _gancho_vel, _gancho_comp)
	_mov.velocidade = velocity
	_mov.saltos_dados = 1     # ainda lhe sobra o salto do ar
	Som.toca("salto", -11.0, 1.0, 0.03)


func _passo_gancho(dt: float) -> void:
	var dir := Input.get_axis("mover_esquerda", "mover_direita") * _inverso
	var r := Movimento.balanco(_gancho_theta, _gancho_vel, _gancho_comp, dir, dt)
	_gancho_theta = r[0]
	_gancho_vel = r[1]
	global_position = Movimento.ponto_do_balanco(_gancho_ancora, _gancho_theta,
		_gancho_comp)
	velocity = Vector2.ZERO
	_mov.velocidade = Vector2.ZERO
	if dir != 0.0:
		_olha_para = signf(dir)
	if Input.is_action_just_pressed("saltar"):
		largar_gancho()


## Corrente de ar a empurrar para cima (Torre dos Ventos, nível 12). A
## `CorrenteAr` chama isto a cada frame enquanto a Koliani lá está;
## `forca` = aceleração, `alvo` = velocidade máxima de subida.
func soprar_para_cima(forca: float, alvo: float) -> void:
	_vento_forca = forca
	_vento_alvo = alvo
	_vento_restante = 0.12  # renova-se enquanto a área a alimentar


## Regista ou renova uma força de vento proveniente de uma zona concreta.
## A direção está embutida em `aceleracao`; a velocidade máxima limita apenas
## o sentido dessa influência. Não altera gravidade, corrida ou aceleração.
func atualizar_vento(fonte: Object, aceleracao: Vector2,
		velocidade_max: float, duracao := VENTO_EXTERNO_TTL) -> void:
	if fonte == null or aceleracao.is_zero_approx():
		if fonte != null:
			remover_vento(fonte)
		return
	_ventos_externos[fonte.get_instance_id()] = {
		"fonte": weakref(fonte),
		"aceleracao": aceleracao,
		"velocidade_max": maxf(0.0, velocidade_max),
		"restante": maxf(duracao, 0.0),
	}


func remover_vento(fonte: Object) -> void:
	if fonte != null:
		_ventos_externos.erase(fonte.get_instance_id())


func limpar_ventos() -> void:
	_ventos_externos.clear()


func quantidade_ventos_ativos() -> int:
	_descartar_ventos_invalidos(0.0)
	return _ventos_externos.size()


func aceleracao_vento_resultante() -> Vector2:
	_descartar_ventos_invalidos(0.0)
	var resultado := Vector2.ZERO
	for entrada: Dictionary in _ventos_externos.values():
		resultado += entrada["aceleracao"] as Vector2
	return resultado


func _aplicar_ventos_externos(dt: float) -> void:
	_descartar_ventos_invalidos(dt)
	var ids := _ventos_externos.keys()
	ids.sort()
	for id in ids:
		var entrada: Dictionary = _ventos_externos[id]
		velocity = Movimento.aplicar_forca_externa(
			velocity,
			entrada["aceleracao"] as Vector2,
			float(entrada["velocidade_max"]),
			dt,
		)


func _descartar_ventos_invalidos(dt: float) -> void:
	for id in _ventos_externos.keys():
		var entrada: Dictionary = _ventos_externos[id]
		var fonte_fraca: WeakRef = entrada["fonte"]
		entrada["restante"] = float(entrada["restante"]) - dt
		if fonte_fraca.get_ref() == null or float(entrada["restante"]) <= 0.0:
			_ventos_externos.erase(id)
		else:
			_ventos_externos[id] = entrada


## Regista ou renova o planar concedido por uma zona concreta (`ZonaPlanar`).
func atualizar_planar_contextual(fonte: Object,
		duracao := PLANAR_CONTEXTO_TTL) -> void:
	if fonte == null:
		return
	_planar_contextos[fonte.get_instance_id()] = {
		"fonte": weakref(fonte),
		"restante": maxf(duracao, 0.0),
	}


func remover_planar_contextual(fonte: Object) -> void:
	if fonte != null:
		_planar_contextos.erase(fonte.get_instance_id())


func limpar_planar_contextual() -> void:
	_planar_contextos.clear()
	_planando = false


func quantidade_planar_contextual() -> int:
	_descartar_planar_invalido(0.0)
	return _planar_contextos.size()


## Pode planar AGORA? Habilidade permanente ou contexto de zona. Uma
## `ZonaSemPoder` que suspenda "planar" desliga as duas fontes.
func pode_planar() -> bool:
	if EstadoJogo.tem_habilidade("planar"):
		return true
	if "planar" in EstadoJogo.habilidades_suspensas:
		return false
	return quantidade_planar_contextual() > 0


func esta_a_planar() -> bool:
	return _planando


func _descartar_planar_invalido(dt: float) -> void:
	for id in _planar_contextos.keys():
		var entrada: Dictionary = _planar_contextos[id]
		var fonte_fraca: WeakRef = entrada["fonte"]
		entrada["restante"] = float(entrada["restante"]) - dt
		if fonte_fraca.get_ref() == null or float(entrada["restante"]) <= 0.0:
			_planar_contextos.erase(id)
		else:
			_planar_contextos[id] = entrada


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _invulneravel > 0.0:
		return
	if _defendendo and _bloqueia(dir_empurrao):
		_ao_bloquear()
		return
	var real := int(round(quantidade * (1.0 - EstadoJogo.reducao_armadura())))
	vida = _vida_max() if EstadoJogo.modo_dev else maxi(0, vida - maxi(1, real))
	_invulneravel = I_FRAMES
	_hurt_t = 0.24
	Musica.intensificar()   # 9H.1: levar dano também é combate
	_cancelar_ataque(true)  # dano corta ataque/combo e desliga a hitbox imediatamente
	vida_mudou.emit(vida, _vida_max())
	_flash_branco()
	if Vfx9G.ativo(self):
		Vfx9G.tocar(self, "hurt_blood", global_position + Vector2(4.0 * _olha_para, -8.0),
			1.0, 0.0, _olha_para < 0.0, false, 41, 0.35)
	_abanar(TREMOR_DANO)
	_hitstop(HITSTOP_DANO)
	if vida <= 0:
		_morrer()
	else:
		# Um golpe fatal tem a voz propria de morte; empilhar `dano` no mesmo
		# frame mascarava esse evento e gastava duas vozes do pool.
		Som.toca("dano", -7.0, 1.0, 0.02, 0.12, "player_hurt",
			Som.Prioridade.MEDIA)


## Passos e raspar na parede. Sao os unicos sons dela em CICLO, por isso
## vivem aqui em vez de num sitio de evento.
func _sons_de_movimento(dt: float) -> void:
	if is_on_floor() and absf(velocity.x) > 40.0 and _rolar_restante <= 0.0 			and _dash_restante <= 0.0 and not _defendendo and not _a_morrer:
		_passo_t -= dt * (absf(velocity.x) / VEL_PASSO_REF)
		if _passo_t <= 0.0:
			_passo_t = INTERVALO_PASSO
			_passo_variante = (_passo_variante + 1) % 3
			Som.toca("passo%d" % (_passo_variante + 1), -24.0, 1.0, 0.08)
	else:
		_passo_t = 0.0   # parada, o proximo passo sai logo ao arrancar

	if _escalando:
		_parede_t -= dt
		if _parede_t <= 0.0:
			_parede_t = INTERVALO_PAREDE
			Som.toca("parede", -22.0, 1.0, 0.06)
	else:
		_parede_t = 0.0


func _morrer() -> void:
	if _a_morrer:
		return
	_a_morrer = true
	_cancelar_ataque(true)
	_vfx_morte()
	Som.toca("morte_koliani", -6.0, 1.0, 0.02, 0.0, "", Som.Prioridade.ALTA)
	Engine.time_scale = 1.0  # não deixar um hitstop pendente a segurar o tempo
	set_physics_process(false)
	morreu.emit()
	EstadoJogo.perder_vida()
	if EstadoJogo.sem_vidas():
		# Vidas cheias e recomeça o nível atual, mas o
		# progresso (níveis concluídos, habilidades, pistas, equipamento) fica
		EstadoJogo.reiniciar_run()
	Transicao.fechar_e(get_tree().reload_current_scene)


## Reconstrói a personagem no ponto seguro resolvido pela fogueira da cena.
## Todo o resto (inimigos, perigos, projectiles, animações e velocity) nasce
## de novo com a cena; não existe arbitrary frame save.
func recuperar_no_checkpoint(posicao_segura: Vector2) -> void:
	if _a_morrer or posicao_segura == Vector2.ZERO:
		return
	global_position = posicao_segura + Vector2(0.0, -ALTURA_SPAWN)
	# Reaparecer é o teletransporte mais longo do jogo (fogueira do outro lado
	# do nível). Sem este reset via-se um risco dela a atravessar o mapa.
	reset_physics_interpolation()
	velocity = Vector2.ZERO
	_mov.velocidade = Vector2.ZERO
	limpar_ventos()
	# a zona que contenha a fogueira volta a conceder no frame seguinte
	limpar_planar_contextual()
	_desencravar()
	_pos_inicial = global_position


## Quantos píxeis ACIMA do checkpoint é que ela nasce. 40 px chegam para
## sair de dentro de uma plataforma fina e são pouco para se dar por eles:
## cai logo de volta ao chão.
const ALTURA_SPAWN := 40.0
## Até onde procurar sítio livre quando o ponto de nascimento está dentro de
## geometria. 4 px de passo porque a plataforma mais fina do jogo tem 15.
const BUSCA_DESENCRAVE := 220.0


## Tira-a de dentro da parede, se lá estiver.
##
## Isto existe por um softlock real (nível 5, relatado pelo Paulo a 5 set
## 2026): reaparecer no checkpoint punha-a entalada entre o chão e uma
## plataforma logo por cima, e dali não saía de maneira nenhuma -- nem
## morrendo, porque voltava exactamente ao mesmo sítio.
##
## A rede tem de estar AQUI e não só no gerador: quem já tem esse
## checkpoint gravado no save continuaria preso para sempre.
func _desencravar() -> void:
	if not test_move(global_transform, Vector2.ZERO):
		return
	var passo := 4.0
	var d := passo
	while d <= BUSCA_DESENCRAVE:
		# primeiro para cima (é de onde vem o tecto que a entala), depois
		# para os lados, e só no fim para baixo
		for tenta in [Vector2(0.0, -d), Vector2(-d, -d * 0.5),
				Vector2(d, -d * 0.5), Vector2(-d, 0.0), Vector2(d, 0.0),
				Vector2(0.0, d)]:
			var t := global_transform
			t.origin += tenta
			if not test_move(t, Vector2.ZERO):
				global_position += tenta
				return
		d += passo
	push_warning("Koliani encravada no spawn em %s e sem saida a %d px"
		% [global_position, int(BUSCA_DESENCRAVE)])


## Cadencia da locomocao: a passada acompanha a VELOCIDADE (Execution 9H.13).
##
## Ate' aqui o `run` corria sempre aos 13,33 fps da folha golden, andasse a
## Koliani depressa ou devagar. Duas consequencias, ambas medidas e nao
## adivinhadas:
##
## 1. **Patinagem.** O ciclo golden sao 10 frames a 13,33 fps = 0,75 s, e a
##    `Movimento.VEL_CORRIDA` sao 240 px/s: 180 px de chao por ciclo. O ciclo
##    desenhado tem UMA passada, e a perna de tras mede 23 px -- ou seja, o
##    chao passa quatro a seis vezes mais depressa do que a passada. O pe'
##    varre o chao em vez de o agarrar, que e' metade do "parece que uma perna
##    nao mexe" que o Game Master descreveu.
## 2. **A andar devagar** (encostada, a sair de um travao, no ar a tocar o
##    chao) a animacao corria na mesma a fundo, o que e' pior ainda.
##
## O `speed_scale` passa a ser a razao entre a velocidade real e a de
## corrida, com um chao (nunca abaixo de 0,55, senao parece cinema lento) e
## um tecto (nunca acima de 1,85, senao borra). Nao mexe em nada da fisica
## nem do `Movimento` -- e' so' o relogio do `AnimatedSprite2D`.
##
## NB: isto NAO resolve a alternancia das pernas. Os 10 frames golden do
## `run` sao um ciclo de UMA perna -- medido: o pe' de tras percorre 13 px em
## todo o ciclo e o da frente 34 px, e em nenhum dos 10 frames o pe' esquerdo
## passa a' frente do direito. Isso precisa de frames nativos -- ver o
## relatorio da 9H.13/14 (KOLIANI RUN NATIVE FRAMES REQUIRED).
## Duracao do ciclo de corrida, em segundos. Os 10 frames golden a 13,33 fps
## dao exactamente isto, e a tira nativa tem de dar o mesmo para a cadencia
## por velocidade continuar a bater certo.
const DUR_CICLO_CORRIDA := 0.75
const CADENCIA_MIN := 0.55
const CADENCIA_MAX := 1.85


func _passo_cadencia_locomocao(a: String) -> void:
	if _corpo == null:
		return
	if a != "run":
		# fora da locomocao o relogio volta ao normal, senao um ataque ou uma
		# queda herdavam a cadencia da corrida anterior.
		if not is_equal_approx(_corpo.speed_scale, 1.0):
			_corpo.speed_scale = 1.0
		return
	var ref: float = maxf(Movimento.VEL_CORRIDA, 1.0)
	_corpo.speed_scale = clampf(absf(velocity.x) / ref, CADENCIA_MIN, CADENCIA_MAX)
