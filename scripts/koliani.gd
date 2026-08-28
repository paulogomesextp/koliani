class_name Koliani
extends CharacterBody2D
## A personagem principal. A física real (colisões, `move_and_slide`) vive
## aqui; o "sentir" do movimento está em `movimento.gd` (lógica pura,
## testável). Ataque leve, dash e rolamento são o mínimo para a pegada
## tipo Dead Cells -- o agente "gaming" expande daqui.

signal morreu
signal vida_mudou(atual: int, maximo: int)

const VIDA_MAXIMA := 100
const DANO_ATAQUE := 25
const VEL_DASH := 620.0
const DUR_DASH := 0.16
const RECARGA_DASH := 0.55
const DUR_ATAQUE := 0.18
const I_FRAMES := 0.6

@onready var _hitbox: Area2D = $HitboxAtaque
@onready var _sprite: Node2D = $Sprite

var _mov := Movimento.Estado.new()
var vida := VIDA_MAXIMA
var _olha_para := 1.0
var _dash_restante := 0.0
var _dash_recarga := 0.0
var _ataque_restante := 0.0
var _invulneravel := 0.0


func _ready() -> void:
	if EstadoJogo.checkpoint != Vector2.ZERO:
		global_position = EstadoJogo.checkpoint
	if _hitbox:
		_hitbox.monitoring = false
		_hitbox.body_entered.connect(_ao_acertar_corpo)
	vida_mudou.emit(vida, VIDA_MAXIMA)


func _physics_process(dt: float) -> void:
	_dash_recarga = maxf(0.0, _dash_recarga - dt)
	_invulneravel = maxf(0.0, _invulneravel - dt)

	var dir := Input.get_axis("mover_esquerda", "mover_direita")
	if dir != 0.0:
		_olha_para = signf(dir)
		if _sprite:
			_sprite.scale.x = _olha_para

	if _ataque_restante > 0.0:
		_ataque_restante -= dt
		if _ataque_restante <= 0.0 and _hitbox:
			_hitbox.monitoring = false
	elif Input.is_action_just_pressed("atacar"):
		_iniciar_ataque()

	if _dash_restante > 0.0:
		_dash_restante -= dt
		velocity.x = _olha_para * VEL_DASH
		velocity.y = 0.0
	else:
		if Input.is_action_just_pressed("dash") and _dash_recarga <= 0.0:
			_dash_restante = DUR_DASH
			_dash_recarga = RECARGA_DASH
			_invulneravel = maxf(_invulneravel, DUR_DASH)
		else:
			# salto duplo: habilidade permanente ganha ao longo da campanha
			var saltos_max := 2 if EstadoJogo.tem_habilidade("salto_duplo") else 1
			_mov = Movimento.passo(
				_mov, dir,
				Input.is_action_just_pressed("saltar"),
				Input.is_action_pressed("saltar"),
				is_on_floor(), dt, saltos_max,
			)
			velocity = _mov.velocidade

	move_and_slide()
	_mov.velocidade = velocity


func _iniciar_ataque() -> void:
	_ataque_restante = DUR_ATAQUE
	if _hitbox:
		_hitbox.scale.x = _olha_para
		_hitbox.monitoring = true


func _ao_acertar_corpo(corpo: Node) -> void:
	if corpo.has_method("receber_dano"):
		corpo.receber_dano(DANO_ATAQUE, sign(_olha_para))


func receber_dano(quantidade: int, _dir_empurrao: float = 0.0) -> void:
	if _invulneravel > 0.0:
		return
	vida = maxi(0, vida - quantidade)
	_invulneravel = I_FRAMES
	vida_mudou.emit(vida, VIDA_MAXIMA)
	if vida <= 0:
		_morrer()


func _morrer() -> void:
	morreu.emit()
	EstadoJogo.perder_vida()
	if EstadoJogo.sem_vidas():
		EstadoJogo.reiniciar_campanha()
	get_tree().reload_current_scene()
