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
## Combo de espada (só rig "cavaleiro", que tem 4 tiras de ataque
## distintas): Single -> Double -> Triple -> Quadruple. Encadeia-se
## carregando em "atacar" outra vez dentro da `JANELA_COMBO` a seguir ao
## golpe atual (input bufferizado se carregar a meio do golpe); passado
## esse tempo sem novo golpe, o combo cai de volta ao 1.º hit.
const NUM_COMBO := 4
const JANELA_COMBO := 0.42
## Duração de cada golpe do combo, a acompanhar o comprimento real de cada
## tira (attack/attack2/attack3/attack4) -- senão a animação era cortada a
## meio antes de terminar, sobretudo o 3.º hit (9 frames, o mais longo).
const DUR_COMBO := [0.18, 0.2, 0.3, 0.19]

## PESO DO IMPACTO -- reafinado a 4 set 2026.
##
## O Paulo: "quando a Koliani ataca com espada o ecra treme e gera frame
## drop". Nao era impressao. O `_hitstop` poe `Engine.time_scale = 0.0`,
## ou seja PARA o jogo: cada acerto parava 50 ms (crit 110 ms), o remate
## do combo parava mais 50 ms **no balanco**, e o proprio `_flash_golpe`
## ja' abanava a camara 1,8 px sem sequer acertar em nada. Num combo de
## quatro acertos dava ~340 ms de jogo parado dentro de 1,5 s -- 23% do
## tempo. Somado ao tremor, que durava mais do que o intervalo entre
## golpes, o resultado le^-se exactamente como engasgo.
##
## Regra nova: **o balanco nao mexe na camara nem para o tempo**. So' a
## LIGACAO tem peso, e o peso e' curto -- um frame no golpe normal, e
## reserva-se o resto para o que e' raro (remate, critico, levar dano).
const HITSTOP_GOLPE := 0.02        # ~1 frame a 60 fps
const HITSTOP_REMATE := 0.045      # 4.o golpe do combo
const HITSTOP_CRIT := 0.06
const HITSTOP_PISAO := 0.03
const HITSTOP_DANO := 0.05
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
## px, mais o deslize da desaceleração normal a seguir -- medido no
## `Level_Test`: 23, 29, 34 e 64 px. No AR vale metade, para não atirar
## a Koliani para fora das plataformas a meio de um combo.
const AVANCO_VEL := [330.0, 370.0, 390.0, 540.0]
const AVANCO_DUR := [0.13, 0.13, 0.16, 0.18]
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
## Tiro mágico (toque curto em "lancar"): lança em 8 direções, ILIMITADO,
## dá um terço do dano do ataque básico. Não gasta Energia.
const DUR_LANCAR := 0.16
const PROJETIL_MAGICO := preload("res://scenes/actors/ProjetilKoliani.tscn")
## Kamehameha roxo (habilidade "projetil"): segura-se "lancar" ~0.4 s e
## larga-se -> rajada roxa que atravessa inimigos. Cada rajada gasta 33% da
## barra de Energia (3 seguidas), que regenera continuamente mas devagar
## (não dá para spamar).
const ENERGIA_MAX := 99.0
const CUSTO_KAMEHAMEHA := 33.0
const CARGA_KAMEHAMEHA := 0.4     # segundos com o botão em baixo até carregar
const RECARGA_KAMEHAMEHA := 0.45  # gap mínimo entre rajadas
const REGEN_ENERGIA := 12.0       # por segundo (barra cheia em ~8 s)
const KAMEHAMEHA := preload("res://scenes/actors/KamehamehaKoliani.tscn")
## Abaixo deste Y considera-se que caiu no vazio (fosso sem fundo).
const Y_MORTE := 1200.0
const TEX_IMPACTO := preload("res://assets/sprites/impacto.svg")

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
var _invulneravel := 0.0
## Contadores só visuais (o rig "cavaleiro" tem desenho para eles).
var _hurt_t := 0.0
var _aterrar_t := 0.0
var _no_ar_antes := false
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
## Carga do Kamehameha: segundos com "lancar" em baixo nesta pressão.
var _lancar_seg := 0.0
## Já disparou o Kamehameha nesta pressão (não repete até largar).
var _hold_kame := false
var _kame_recarga := 0.0
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


func _ready() -> void:
	if EstadoJogo.checkpoint != Vector2.ZERO:
		global_position = EstadoJogo.checkpoint
	_pos_inicial = global_position
	# a entrada do nível é um checkpoint implícito: morrer antes de tocar
	# numa gema devolve a Koliani aqui (não ao início da campanha)
	if EstadoJogo.checkpoint == Vector2.ZERO and not EstadoJogo.modo_dev:
		EstadoJogo.definir_checkpoint(_pos_inicial)
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
	var gothic := RIG == "gothic"
	var cavaleiro := RIG == "cavaleiro"
	var nova := RIG == "nova"
	var shadow := RIG == "shadowblade"
	var anims: Dictionary = _KOLI_ANIMS
	var dir_tiras := "koliani"
	if gothic:
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
	if shadow:
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
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for nome: String in anims:
		var cfg: Array = anims[nome]
		sf.add_animation(nome)
		sf.set_animation_speed(nome, cfg[1])
		sf.set_animation_loop(nome, cfg[2])
		var tex: Texture2D = load("res://assets/sprites/pixel/%s/%s.png" % [dir_tiras, nome])
		if tex == null:
			continue
		var n: int = cfg[0]
		var fw := tex.get_width() / maxi(1, n)
		for i in n:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, tex.get_height())
			sf.add_frame(nome, at)
	_corpo.sprite_frames = sf
	_corpo.play("idle")
	_montar_material_equipamento()


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
	_tick_estados(dt)
	_aterrar_t = maxf(0.0, _aterrar_t - dt)
	# aterragem: só depois de ter estado mesmo no ar
	if is_on_floor():
		if _no_ar_antes:
			_aterrar_t = 0.16
		_no_ar_antes = false
	elif velocity.y > 120.0:
		_no_ar_antes = true
	_lancar_restante = maxf(0.0, _lancar_restante - dt)
	_kame_recarga = maxf(0.0, _kame_recarga - dt)
	_preso = maxf(0.0, _preso - dt)
	_parede_lock = maxf(0.0, _parede_lock - dt)
	_borda_lock = maxf(0.0, _borda_lock - dt)
	_djump_t = maxf(0.0, _djump_t - dt)
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
			Som.toca("salto", -10.0)
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
			velocity = Vector2.ZERO
			_mov.saltos_dados = 0
			Som.toca("agarrar", -14.0, randf_range(0.96, 1.06))

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
			Som.toca("salto", -10.0)
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
		Som.toca("salto", -9.0)
		move_and_slide()
		_mov.velocidade = velocity
		_estava_no_chao = false
		return

	# defesa: só com a habilidade "escudo", em pé, e não a meio de outra ação
	_defendendo = EstadoJogo.tem_habilidade("escudo") \
		and Input.is_action_pressed("defender") \
		and _rolar_restante <= 0.0 and _dash_restante <= 0.0 and _ataque_restante <= 0.0 \
		and is_on_floor()

	# ataque leve -- bloqueado enquanto rola ou defende. Combo: um novo
	# golpe a meio do atual fica bufferizado (`_combo_pedido`) e dispara
	# assim que este acabar, em vez de se perder.
	if not _defendendo and _rolar_restante <= 0.0 and Input.is_action_just_pressed("atacar"):
		if _ataque_restante > 0.0:
			_combo_pedido = true
		else:
			_iniciar_ataque()
	if _ataque_restante > 0.0:
		_ataque_restante -= dt
		if _ataque_restante <= 0.0 and _hitbox:
			_hitbox.monitoring = false
			if _combo_pedido:
				_combo_pedido = false
				_iniciar_ataque()
	elif _combo_janela > 0.0:
		_combo_janela -= dt
		if _combo_janela <= 0.0:
			_combo_passo = 0

	# "lancar": toque curto = tiro mágico ilimitado; segurar ~0.4 s e largar =
	# Kamehameha roxo (habilidade "projetil", gasta 33% da Energia).
	_tratar_lancar(dt)

	# estados exclusivos de movimento: rolamento > dash > movimento normal
	if _rolar_restante > 0.0:
		_rolar_restante -= dt
		if _rolar_restante <= 0.0:
			_pos_roll_t = POS_ROLL_JANELA   # abre a janela de crítico pós-rolamento
		velocity.x = _olha_para * VEL_ROLAR
		if not is_on_floor():
			velocity.y = minf(Movimento.VEL_MAX_QUEDA, velocity.y + Movimento.GRAVIDADE * _grav_escala * dt)
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
			velocity.y = minf(Movimento.VEL_MAX_QUEDA, velocity.y + Movimento.GRAVIDADE * _grav_escala * dt)
		_mov.velocidade = velocity
	elif Input.is_action_just_pressed("rolar") and Movimento.pode_rolar(
			_rolar_recarga, is_on_floor(), _rolar_restante, _dash_restante):
		_rolar_restante = DUR_ROLAR
		_rolar_recarga = RECARGA_ROLAR
		Som.toca("rolamento", -13.0, randf_range(0.95, 1.06))
		_invulneravel = maxf(_invulneravel, DUR_ROLAR + EstadoJogo.bonus("iframes_roll"))  # melhoria "agilidade"
		# roll-cancel (pegada Dead Cells): o rolamento corta o recovery do
		# ataque -> encadeia-se ataque -> rolar -> ataque sem esperar
		if _ataque_restante > 0.0:
			_ataque_restante = 0.0
			_avanco_restante = 0.0
			if _hitbox:
				_hitbox.monitoring = false
	elif Input.is_action_just_pressed("dash") and _dash_recarga <= 0.0 and (
			is_on_floor() or EstadoJogo.tem_habilidade("dash_aereo")):
		_dash_restante = DUR_DASH
		_dash_recarga = RECARGA_DASH
		_acender_aura(0.8)
		Som.toca("dash", -11.0, randf_range(0.97, 1.05))
		_invulneravel = maxf(_invulneravel, DUR_DASH)
	else:
		# salto duplo: intrínseco à Koliani desde o nível 1 (deixou de ser um
		# requisito de habilidade -- ver EstadoJogo.HABILIDADES_INICIAIS)
		var saltos_max := 2
		var saltos_antes := _mov.saltos_dados
		_mov = Movimento.passo(
			_mov, dir,
			Input.is_action_just_pressed("saltar"),
			Input.is_action_pressed("saltar") or _impulso_externo_t > 0.0,
			is_on_floor(), dt, saltos_max, _grav_escala, _acel_escala,
			# PLANAR (nível 63): só com a habilidade, e só a segurar o
			# botão. O `Movimento` e' que decide se ela ja' esta' a cair.
			Input.is_action_pressed("saltar")
				and EstadoJogo.tem_habilidade("planar"),
		)
		velocity = _mov.velocidade
		if _mov.saltos_dados > saltos_antes:
			Som.toca("salto_duplo" if _mov.saltos_dados >= 2 else "salto", -10.0)
			if _mov.saltos_dados >= 2:
				_djump_t = 0.45  # mostra a animação do salto duplo

	# batida do Coração Putrefacto (fase 2): gravidade aliviada -- a Koliani
	# fica "leve" e a queda abranda para lhe dar tempo no ar
	if _leve > 0.0 and velocity.y > 0.0:
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

	# cair em cima de um inimigo = golpe de espada + pulo automático (estilo
	# Mario). Janela GENEROSA: basta vir a descer e apanhar o bicho grosso
	# modo por cima -- serve para inimigos de vários tamanhos. Encadeia:
	# cada pisão devolve os saltos de ar todos.
	_stomp_cd = maxf(0.0, _stomp_cd - dt)
	if _stomp_cd <= 0.0 and velocity.y > 40.0 and not is_on_floor() and _dash_restante <= 0.0:
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
			Som.toca("acerto", -10.0, randf_range(0.82, 0.94))
			_pop_impacto(ep)
			break

	# pogo: cair em cima de uma serra / espinhos (grupo "pogavel", layer 6)
	# -> ressalta em vez de levar o golpe (os i-frames apanham o toque desse
	# frame). Só a descer a sério e pela parte de cima.
	if _stomp_cd <= 0.0 and velocity.y > 90.0 and not is_on_floor() and _dash_restante <= 0.0:
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
			Som.toca("acerto", -10.0, randf_range(0.94, 1.07))
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

	var vel_queda := velocity.y
	move_and_slide()
	_mov.velocidade = velocity

	# aterragem: pó + abanão + squash, proporcional à velocidade de queda
	var no_chao := is_on_floor()
	if no_chao and not _estava_no_chao and vel_queda > 180.0:
		if _po:
			_po.restart()
		var f := remap(minf(vel_queda, 1100.0), 180.0, 1100.0, 0.35, 1.0)
		_squash = maxf(_squash, f)
		_abanar(remap(minf(vel_queda, 1100.0), 180.0, 1100.0, 1.0, 4.5))
		Som.toca("aterrar", remap(f, 0.35, 1.0, -20.0, -8.0))
	_estava_no_chao = no_chao

	# caiu num fosso sem fundo -> conta como morte (reaparece no checkpoint)
	if global_position.y > Y_MORTE and vida > 0 and not _voando:
		if EstadoJogo.modo_dev:
			# `_pos_inicial` é só a posição em que a CENA carregou -- fica
			# desatualizada assim que se toca num checkpoint mais à frente
			# (era por isso que em modo dev não se reaparecia no checkpoint
			# tocado). `EstadoJogo.checkpoint` é que está sempre atual.
			var alvo := EstadoJogo.checkpoint if EstadoJogo.checkpoint != Vector2.ZERO else _pos_inicial
			global_position = alvo if alvo != Vector2.ZERO else global_position
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
	elif _agachado:
		a = "crouch"
	elif not is_on_floor():
		if _djump_t > 0.0:
			a = "djump"
		elif velocity.y < -20.0:
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
		elif a == "jump" or a == "djump":
			rot = -0.7
			off = Vector2(7, -6)
		_arma.rotation = rot
		_arma.position = off


## Para que lado o sprite é espelhado. Por omissão é `_olha_para` (as tiras
## estão viradas à direita), menos nas poses agarradas à parede -- ver
## `PAREDE_ESPELHADA`. Olha para a animação que está MESMO a ser desenhada,
## para não inverter a Koliani quando o estado de parede escolhe outra tira.
func _flip_sprite() -> float:
	if PAREDE_ESPELHADA and _corpo != null \
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

	# luz de carga do Kamehameha: cresce enquanto se segura "lancar"
	if _luz_carga:
		var carga := clampf(_lancar_seg / CARGA_KAMEHAMEHA, 0.0, 1.0) if _lancar_seg > 0.0 \
			and EstadoJogo.tem_habilidade("projetil") else 0.0
		_luz_carga.energy = 3.2 * carga
		var pronto := 1.0 + (0.12 * sin(_anim_t * 24.0) if carga >= 1.0 else 0.0)
		_luz_carga.scale = Vector2(0.28, 0.28) * (0.6 + 0.8 * carga) * pronto

	var no_chao := is_on_floor()
	var vx := absf(velocity.x)
	var escala := Vector2.ONE
	var rot_alvo := 0.0

	if _rolar_restante > 0.0:
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
	_sprite.scale = Vector2(escala.x * _flip_sprite(), escala.y)


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
func _hitstop(segundos: float) -> void:
	if Engine.time_scale < 0.5:
		return
	Engine.time_scale = 0.0
	# NÃO usar `await` aqui: se a Koliani for libertada (reload de cena) a
	# meio, a corrotina morre e o time_scale ficava preso em 0 = freeze.
	# O timer vive na árvore e o Callable não segura `self`.
	get_tree().create_timer(segundos, true, false, true).timeout.connect(
		func() -> void: Engine.time_scale = 1.0)


func _iniciar_ataque() -> void:
	# encadeia o combo se ainda estamos na janela do golpe anterior;
	# senão volta ao 1.º hit ("Single").
	_combo_passo = (_combo_passo + 1) % NUM_COMBO if _combo_janela > 0.0 else 0
	# o combo de 4 golpes existe nos rigs com tiras `attack2/3/4`
	var tem_combo := RIG == "cavaleiro" or RIG == "nova" or RIG == "shadowblade"
	_ataque_dur = DUR_COMBO[_combo_passo] if tem_combo else DUR_ATAQUE
	_ataque_restante = _ataque_dur
	_combo_janela = _ataque_dur + JANELA_COMBO
	_pop = 1.0
	# a aura acende mais a cada golpe do combo: o 4.º é o que "estoira"
	_acender_aura(0.42 + 0.19 * _combo_passo)
	# passo em frente: o golpe "pisa" para onde se olha (ver `AVANCO_VEL`).
	var i_av: int = clampi(_combo_passo, 0, AVANCO_VEL.size() - 1)
	_avanco_vel = AVANCO_VEL[i_av] * (1.0 if is_on_floor() else AVANCO_NO_AR)
	_avanco_dur = AVANCO_DUR[i_av]
	_avanco_restante = _avanco_dur
	# o remate do combo tem som proprio (mais fundo, com peso de metal)
	if _combo_passo == NUM_COMBO - 1:
		Som.toca("ataque_forte", -5.0, randf_range(0.96, 1.04))
	else:
		Som.toca("ataque", -6.0, randf_range(0.95, 1.06))
	_flash_golpe()
	# NB: o balanco do remate ja' nao abana nem para o tempo -- o peso do
	# combo esta' todo na LIGACAO (ver `TREMOR_REMATE`/`HITSTOP_REMATE`).
	if _hitbox:
		_hitbox.scale.x = _olha_para
		_hitbox.monitoring = true


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


## Gere o botão "lancar": segurar carrega o Kamehameha, largar cedo dispara
## o tiro mágico normal. Bloqueado a defender/rolar/dar dash.
func _tratar_lancar(dt: float) -> void:
	if _defendendo or _rolar_restante > 0.0 or _dash_restante > 0.0:
		_lancar_seg = 0.0
		_hold_kame = false
		return

	if Input.is_action_pressed("lancar"):
		_lancar_seg += dt
		# carregou o suficiente -> dispara a rajada (uma vez por pressão)
		if not _hold_kame and _lancar_seg >= CARGA_KAMEHAMEHA \
				and _kame_recarga <= 0.0 \
				and EstadoJogo.tem_habilidade("projetil") \
				and (_energia >= CUSTO_KAMEHAMEHA or EstadoJogo.modo_dev):
			_lancar_kamehameha()
			_hold_kame = true

	if Input.is_action_just_released("lancar"):
		# toque curto (não chegou a carregar) -> tiro mágico normal
		if not _hold_kame and _lancar_seg < CARGA_KAMEHAMEHA and _lancar_restante <= 0.0:
			_lancar_projetil()
		_lancar_seg = 0.0
		_hold_kame = false


## Lança um tiro mágico numa das 8 direções (mira = eixos de movimento + W/S;
## sem mira, para onde está virada). Ilimitado, dá 1/3 do dano do golpe.
func _lancar_projetil() -> void:
	_lancar_restante = DUR_LANCAR
	_pop = 1.0
	_acender_aura(0.7)
	var ax := Input.get_action_strength("mover_direita") - Input.get_action_strength("mover_esquerda")
	var ay := Input.get_action_strength("mirar_baixo") - Input.get_action_strength("mirar_cima")
	var aim := Movimento.direcao_mira(ax, ay, _olha_para)
	var p := PROJETIL_MAGICO.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position + aim * 20.0 + Vector2(0.0, -4.0)
	p.lancar(aim, maxi(1, roundi(_dano_golpe() / 3.0)))
	Som.toca("lancar", -9.0, randf_range(0.96, 1.08))
	if _faiscas:
		_faiscas.position.x = absf(_faiscas.position.x) * signf(aim.x if aim.x != 0.0 else _olha_para)
		_faiscas.restart()


## Dano da rajada Kamehameha (a olho: 3x o golpe básico).
func _dano_kamehameha() -> int:
	return _dano_golpe() * 3


## Dispara o Kamehameha roxo. Já validado: tem a habilidade, há Energia e
## não está em recarga.
func _lancar_kamehameha() -> void:
	if not EstadoJogo.modo_dev:  # modo dev: energia infinita
		_energia = maxf(0.0, _energia - CUSTO_KAMEHAMEHA)
	energia_mudou.emit(_energia, ENERGIA_MAX)
	_kame_recarga = RECARGA_KAMEHAMEHA
	_lancar_restante = DUR_LANCAR
	_pop = 1.0
	_acender_aura(1.0)
	var ax := Input.get_action_strength("mover_direita") - Input.get_action_strength("mover_esquerda")
	var ay := Input.get_action_strength("mirar_baixo") - Input.get_action_strength("mirar_cima")
	var aim := Movimento.direcao_mira(ax, ay, _olha_para)
	var p := KAMEHAMEHA.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position + aim * 26.0 + Vector2(0.0, -4.0)
	p.lancar(aim, _dano_kamehameha())
	Som.toca("onda", -4.0, 0.85)
	_abanar(6.0)
	magia_lancada.emit()  # a magia "a sério" materializa as plataformas espectrais
	if _faiscas:
		_faiscas.position.x = absf(_faiscas.position.x) * signf(aim.x if aim.x != 0.0 else _olha_para)
		_faiscas.restart()


func _ao_acertar_corpo(corpo: Node) -> void:
	if corpo.has_method("receber_dano"):
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
		corpo.receber_dano(_dano_golpe(), sign(_olha_para), crit)
		# remate do combo (4.º golpe) -> deixa o inimigo a SANGRAR
		if _combo_passo >= NUM_COMBO - 1 and corpo.has_method("sangrar"):
			corpo.sangrar(2.6, maxi(3, roundi(_dano_golpe() * 0.16)))
		if _faiscas:
			_faiscas.position.x = absf(_faiscas.position.x) * _olha_para
			_faiscas.restart()
		_pop_impacto((corpo as Node2D).global_position if corpo is Node2D else global_position)
		var remate := _combo_passo >= NUM_COMBO - 1
		_abanar(TREMOR_CRIT if crit else (TREMOR_REMATE if remate else TREMOR_GOLPE))
		_hitstop(HITSTOP_CRIT if crit else (HITSTOP_REMATE if remate else HITSTOP_GOLPE))
		if crit:
			Som.toca("acerto", -5.0, randf_range(1.18, 1.32))
		else:
			Som.toca("acerto", -8.0, randf_range(0.94, 1.07))


## "Frame de impacto": o anel pixel-art (`Impacto`) a abrir no ponto do
## acerto, com a cor da arma, mais o clarão antigo por baixo a dar o flash.
func _pop_impacto(pos: Vector2) -> void:
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
	Som.toca("bloqueio", -15.0, randf_range(0.97, 1.06))
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
	Som.toca("salto_duplo" if _voando else "aterrar", -12.0)
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


## Corrente de ar a empurrar para cima (Torre dos Ventos, nível 12). A
## `CorrenteAr` chama isto a cada frame enquanto a Koliani lá está;
## `forca` = aceleração, `alvo` = velocidade máxima de subida.
func soprar_para_cima(forca: float, alvo: float) -> void:
	_vento_forca = forca
	_vento_alvo = alvo
	_vento_restante = 0.12  # renova-se enquanto a área a alimentar


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _invulneravel > 0.0:
		return
	if EstadoJogo.modo_dev:  # modo de testes: não perde vida
		return
	if _defendendo and _bloqueia(dir_empurrao):
		_ao_bloquear()
		return
	var real := int(round(quantidade * (1.0 - EstadoJogo.reducao_armadura())))
	vida = maxi(0, vida - maxi(1, real))
	_invulneravel = I_FRAMES
	_hurt_t = 0.24
	_combo_janela = 0.0  # levar um golpe corta o combo -- o proximo ataque volta ao 1.o hit
	_combo_passo = 0
	vida_mudou.emit(vida, _vida_max())
	_flash_branco()
	_abanar(TREMOR_DANO)
	_hitstop(HITSTOP_DANO)
	Som.toca("dano", -7.0)
	if vida <= 0:
		_morrer()


## Passos e raspar na parede. Sao os unicos sons dela em CICLO, por isso
## vivem aqui em vez de num sitio de evento.
func _sons_de_movimento(dt: float) -> void:
	if is_on_floor() and absf(velocity.x) > 40.0 and _rolar_restante <= 0.0 			and _dash_restante <= 0.0 and not _defendendo and not _a_morrer:
		_passo_t -= dt * (absf(velocity.x) / VEL_PASSO_REF)
		if _passo_t <= 0.0:
			_passo_t = INTERVALO_PASSO
			Som.toca("passo%d" % (randi() % 3 + 1), -24.0, randf_range(0.9, 1.12))
	else:
		_passo_t = 0.0   # parada, o proximo passo sai logo ao arrancar

	if _escalando:
		_parede_t -= dt
		if _parede_t <= 0.0:
			_parede_t = INTERVALO_PAREDE
			Som.toca("parede", -22.0, randf_range(0.94, 1.09))
	else:
		_parede_t = 0.0


func _morrer() -> void:
	if _a_morrer:
		return
	_a_morrer = true
	Som.toca("morte_koliani", -6.0)
	Engine.time_scale = 1.0  # não deixar um hitstop pendente a segurar o tempo
	set_physics_process(false)
	morreu.emit()
	EstadoJogo.perder_vida()
	if EstadoJogo.sem_vidas():
		if EstadoJogo.hardcore:
			# hardcore: 3 vidas gastas = fim do run -> cartão GAME OVER (com voz)
			GameOver.mostrar(get_tree(), "lives")
			return
		# modo normal: vidas cheias e recomeça o nível actual, mas o
		# progresso (níveis concluídos, habilidades, pistas, equipamento) fica
		EstadoJogo.reiniciar_run()
	Transicao.fechar_e(get_tree().reload_current_scene)
