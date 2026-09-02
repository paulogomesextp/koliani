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
const I_FRAMES := 0.6
## Ressalto ao cair em cima de um inimigo (Mario-style): o pulo automático a
## seguir ao "pisão" é sempre um SALTO NORMAL (mesma força de `saltar`),
## partindo da altura a que o golpe acertou -- previsível, encadeia saltos
## de ar (ver `_mov.saltos_dados = 0` a seguir) sem dar mais altura que um
## salto a sério.
const STOMP_RESSALTO := Movimento.FORCA_SALTO
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

@onready var _hitbox: Area2D = $HitboxAtaque
@onready var _sprite: Node2D = $Sprite
@onready var _corpo: AnimatedSprite2D = $Sprite/Corpo
@onready var _arma: Sprite2D = $Sprite/Arma
@onready var _rastro: Line2D = $Sprite/Rastro
@onready var _escudo: Node2D = $Sprite/Escudo
@onready var _escudo_glow: CanvasItem = $Sprite/Escudo/Glow
@onready var _luz_carga: PointLight2D = $Sprite/LuzCarga
@onready var _luz_golpe: PointLight2D = $Sprite/LuzGolpe
@onready var _luz_lamina: PointLight2D = $Sprite/LuzLamina
@onready var _armadura: Node2D = $Sprite/Armadura
@onready var _camera: Camera2D = $Camera2D
@onready var _faiscas: CPUParticles2D = $FaiscasAtaque
@onready var _po: CPUParticles2D = $PoAterragem

var _mov := Movimento.Estado.new()
var vida := VIDA_MAXIMA
var _olha_para := 1.0
var _dash_restante := 0.0
var _dash_recarga := 0.0
var _rolar_restante := 0.0
## Conta-decrescente da janela pós-rolamento (ver `POS_ROLL_JANELA`).
var _pos_roll_t := 0.0
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
const RIG := "cavaleiro"

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


func _montar_frames() -> void:
	if _corpo.sprite_frames != null:
		return
	var gothic := RIG == "gothic"
	var cavaleiro := RIG == "cavaleiro"
	var anims: Dictionary = _KOLI_ANIMS
	var dir_tiras := "koliani"
	if gothic:
		anims = _KOLI_ANIMS_GOTHIC
		dir_tiras = "koliani_gothic"
	elif cavaleiro:
		anims = _KOLI_ANIMS_CAVALEIRO
		dir_tiras = "koliani_cavaleiro"
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


## Mostra a arma equipada na mão. As tiras da Koliani já trazem a lâmina
## roxa da personagem, por isso a `Arma` extra só aparece se houver uma
## arma equipada (fica por cima da mão).
func _aplicar_equipamento() -> void:
	if _arma:
		var wi := Equipamento.indice_arma(EstadoJogo.arma_equipada)
		# nos rigs prontos a lâmina já está desenhada no frame
		_arma.visible = wi >= 0 and RIG == "codigo"
		if wi >= 0:
			_arma.frame = wi
	if _luz_lamina:
		_luz_lamina.color = _cor_golpe()
	if _rastro:
		_rastro.modulate = _cor_golpe()
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
	var t := float(ai) / 14.0
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
	if _inverso_restante > 0.0:
		_inverso_restante -= dt
		if _inverso_restante <= 0.0:
			_inverso = 1.0

	# a barra de Energia regenera-se sozinha depois de usada
	if _energia < ENERGIA_MAX:
		_energia = minf(ENERGIA_MAX, _energia + REGEN_ENERGIA * dt)
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
			Som.toca("aterrar", -16.0)

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
		_invulneravel = maxf(_invulneravel, DUR_ROLAR)
		# roll-cancel (pegada Dead Cells): o rolamento corta o recovery do
		# ataque -> encadeia-se ataque -> rolar -> ataque sem esperar
		if _ataque_restante > 0.0:
			_ataque_restante = 0.0
			if _hitbox:
				_hitbox.monitoring = false
	elif Input.is_action_just_pressed("dash") and _dash_recarga <= 0.0 and (
			is_on_floor() or EstadoJogo.tem_habilidade("dash_aereo")):
		_dash_restante = DUR_DASH
		_dash_recarga = RECARGA_DASH
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
			is_on_floor(), dt, saltos_max, _grav_escala,
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
			if not is_instance_valid(e) or (e as Node).is_in_group("chefes") \
					or not (e as Node).has_method("receber_dano"):
				continue
			if "vida" in e and e.vida <= 0:
				continue
			var ep: Vector2 = (e as Node2D).global_position
			if absf(ep.x - global_position.x) > 46.0:
				continue
			# centro da Koliani acima do centro do inimigo e os pés dela na
			# banda do topo dele (larga, apanha bichos altos e baixos)
			if global_position.y > ep.y + 6.0 or pes < ep.y - 52.0 or pes > ep.y + 30.0:
				continue
			var crit_stomp: bool = e.has_method("esta_vulneravel") and e.esta_vulneravel()
			e.receber_dano(_dano_golpe(), 0.0, crit_stomp)
			velocity.y = -STOMP_RESSALTO
			_mov.saltos_dados = 0  # o ressalto devolve os saltos de ar todos
			_invulneravel = maxf(_invulneravel, 0.3)
			_stomp_cd = 0.22
			_pop = 1.0
			_squash = maxf(_squash, 0.5)
			_abanar(4.5 if crit_stomp else 3.0)
			_hitstop(0.09 if crit_stomp else 0.05)
			Som.toca("ataque", -12.0, randf_range(0.92, 1.09))
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
			velocity.y = -STOMP_RESSALTO
			_mov.saltos_dados = 0
			_invulneravel = maxf(_invulneravel, 0.35)
			_stomp_cd = 0.22
			_pop = 1.0
			_squash = maxf(_squash, 0.5)
			_abanar(3.0)
			_hitstop(0.05)
			Som.toca("acerto", -10.0, randf_range(0.94, 1.07))
			_pop_impacto(global_position + Vector2(0.0, 24.0))

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
	_animar(dt)
	_atualizar_anim()


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


## Animação procedural do sprite: flip, squash/stretch, lean, pop de
## ataque e rastro da lâmina. Nada disto afeta a física.
func _animar(dt: float) -> void:
	if _sprite == null:
		return
	_anim_t += dt
	_squash = move_toward(_squash, 0.0, dt * 5.0)
	_pop = move_toward(_pop, 0.0, dt * 7.0)

	# o rig "cavaleiro" já tem escudo desenhado nos frames da defesa
	if _escudo and RIG == "codigo":
		if _defendendo != _escudo.visible:
			_escudo.visible = _defendendo
			if _defendendo:
				_escudo.scale = Vector2.ONE
		if _defendendo and _escudo_glow:
			# só o brilho pulsa -- a placa de metal fica opaca
			_escudo_glow.modulate.a = 0.5 + 0.4 * (0.5 + 0.5 * sin(_anim_t * 7.0))

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
	elif _escalando:
		escala = Vector2(0.86, 1.14)  # esticada contra a parede
		_sprite.rotation = lerp_angle(_sprite.rotation, _olha_para * 0.14, dt * 14.0)
	else:
		_sprite.rotation = lerp_angle(_sprite.rotation, rot_alvo, dt * 12.0)
		if not no_chao:
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

	escala.x += _squash * 0.32 + _pop * 0.10
	escala.y += -_squash * 0.32 + _pop * 0.18
	_sprite.scale = Vector2(escala.x * _olha_para, escala.y)

	_animar_rastro(dt)


func _animar_rastro(dt: float) -> void:
	if _rastro == null:
		return
	if _ataque_restante > 0.0:
		_rastro.visible = true
		_rastro.modulate.a = 1.0
		_rastro.width = 18.0
		var p := clampf(1.0 - _ataque_restante / maxf(_ataque_dur, 0.001), 0.0, 1.0)
		var pts := PackedVector2Array()
		for i in 9:
			var f := p - i * 0.05
			if f < 0.0:
				break
			var ang := lerpf(deg_to_rad(-124.0), deg_to_rad(40.0), f)
			pts.append(Vector2(cos(ang), sin(ang)) * 34.0 + Vector2(0.0, -4.0))
		_rastro.points = pts
	elif _rastro.visible:
		_rastro.modulate.a = move_toward(_rastro.modulate.a, 0.0, dt * 7.0)
		if _rastro.modulate.a <= 0.02:
			_rastro.visible = false
			_rastro.points = PackedVector2Array()


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

func _tint_armadura() -> Color:
	if RIG == "gothic":
		return Color.WHITE  # o rig já vem recolorido -- não pintar por cima
	var ai: int = Equipamento.indice_armadura(EstadoJogo.armadura_equipada)
	return _BRILHO_CORPO if ai < 0 else _BRILHO_CORPO.lerp(Equipamento.cor_armadura(ai), 0.3)


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
	_ataque_dur = DUR_COMBO[_combo_passo] if RIG == "cavaleiro" else DUR_ATAQUE
	_ataque_restante = _ataque_dur
	_combo_janela = _ataque_dur + JANELA_COMBO
	_pop = 1.0
	Som.toca("ataque", -13.0, randf_range(0.92, 1.09))
	_flash_golpe()
	if _combo_passo == NUM_COMBO - 1:
		_abanar(4.0)  # remate do combo ("Quadruple") -- um pouco mais de peso
		_hitstop(0.05)
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


## Pontos de um arco cheio (crescente) entre dois raios/ângulos, em local.
func _pontos_arco(r_in: float, r_out: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / float(n))
		pts.append(Vector2(cos(a), sin(a)) * r_out)
	for i in n + 1:
		var a := lerpf(a1, a0, float(i) / float(n))
		pts.append(Vector2(cos(a), sin(a)) * r_in)
	return pts


## Material aditivo partilhado -- faz os arcos BRILHAREM em vez de parecerem
## tinta cinzenta por cima do cenário.
static var _MAT_ADD: CanvasItemMaterial

func _mat_add() -> CanvasItemMaterial:
	if _MAT_ADD == null:
		_MAT_ADD = CanvasItemMaterial.new()
		_MAT_ADD.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _MAT_ADD


## Efeito do corte: raio de luz que varre com a lâmina (núcleo branco-quente
## + halo da cor da arma) + clarão que ilumina mesmo o cenário à frente.
func _flash_golpe() -> void:
	var cor := _cor_golpe()
	var quente := cor.lerp(Color(1, 1, 1), 0.6)

	if _luz_golpe:
		_luz_golpe.color = cor
		_luz_golpe.energy = 0.0
		var tl := _luz_golpe.create_tween()
		tl.tween_property(_luz_golpe, "energy", 2.1, 0.04).set_ease(Tween.EASE_OUT)
		tl.tween_property(_luz_golpe, "energy", 0.0, DUR_ATAQUE + 0.12).set_ease(Tween.EASE_IN)

	if _sprite == null:
		return
	# halo largo (cor da arma) + núcleo fino (branco-quente), ambos aditivos.
	# CURTOS de propósito: o rig "cavaleiro" já desenha o corte no frame, e o
	# arco antigo (raio 52 x1.5) tapava metade da personagem.
	_arco_luz(_pontos_arco(18.0, 40.0, deg_to_rad(-112.0), deg_to_rad(36.0)),
		Color(cor.r, cor.g, cor.b, 0.0), 0.34, 1.22)
	_arco_luz(_pontos_arco(27.0, 36.0, deg_to_rad(-104.0), deg_to_rad(32.0)),
		Color(quente.r, quente.g, quente.b, 0.0), 0.55, 1.1)
	_abanar(1.8)


## Um arco que varre para a frente (segue o flip do Sprite) e desaparece.
func _arco_luz(pts: PackedVector2Array, cor: Color, pico: float, esc: float) -> void:
	var arco := Polygon2D.new()
	arco.polygon = pts
	arco.color = cor
	arco.material = _mat_add()
	arco.position = Vector2(9.0, -6.0)
	arco.rotation = deg_to_rad(-52.0)
	arco.z_index = 30
	_sprite.add_child(arco)
	var t := arco.create_tween()
	t.set_parallel(true)
	t.tween_property(arco, "color:a", pico, 0.035).set_ease(Tween.EASE_OUT)
	t.tween_property(arco, "rotation", deg_to_rad(44.0), DUR_ATAQUE + 0.07) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(arco, "scale", Vector2(esc, esc), DUR_ATAQUE + 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(arco, "color:a", 0.0, 0.08)
	t.chain().tween_callback(arco.queue_free)


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
	var ax := Input.get_action_strength("mover_direita") - Input.get_action_strength("mover_esquerda")
	var ay := Input.get_action_strength("mirar_baixo") - Input.get_action_strength("mirar_cima")
	var aim := Movimento.direcao_mira(ax, ay, _olha_para)
	var p := PROJETIL_MAGICO.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position + aim * 20.0 + Vector2(0.0, -4.0)
	p.lancar(aim, maxi(1, roundi(_dano_golpe() / 3.0)))
	Som.toca("projetil", -13.0, randf_range(1.22, 1.42))
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
		_abanar(8.0 if crit else 4.5)
		_hitstop(0.11 if crit else 0.05 + 0.015 * float(_combo_passo))
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
## que o golpe empurra a Koliani (para longe da fonte); ela bloqueia se
## estiver virada para a fonte. Sem direção conhecida (0), o escudo vale.
func _bloqueia(dir_empurrao: float) -> bool:
	return Movimento.bloqueia_de_frente(dir_empurrao, _olha_para)


func _ao_bloquear() -> void:
	_invulneravel = maxf(_invulneravel, BLOQUEIO_IFRAMES)
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


## Inverte os controlos horizontais por `segundos` (O Olho do Abismo, nível 20).
func inverter_controlos(segundos: float) -> void:
	_inverso = -1.0
	_inverso_restante = maxf(_inverso_restante, segundos)


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
	_abanar(8.0)
	_hitstop(0.07)
	Som.toca("dano", -7.0)
	if vida <= 0:
		_morrer()


func _morrer() -> void:
	if _a_morrer:
		return
	_a_morrer = true
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
