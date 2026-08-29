class_name DemonioBase
extends CharacterBody2D
## Inimigo base: anda de um lado para o outro numa plataforma, vira quando
## bate numa parede ou chega à beira do alcance, e magoa a Koliani por
## contacto (via a Area2D "AreaContacto"). Classe-pai dos demónios
## especificos de cada mundo -- o agente "gaming" herda daqui.

const GRAVIDADE := 1400.0

@export var velocidade := 60.0
@export var vida := 50
@export var dano_contacto := 15
@export var alcance_patrulha := 120.0
## A que distância à frente se testa se ainda há chão (evita cair da
## plataforma na patrulha / na perseguição).
@export var margem_borda := 20.0
## Cor do rasto de partículas quando morre.
@export var cor_estilhacos := Color(0.7, 0.25, 0.45)
## Cor da luz de recorte (rim) do sprite -- normalmente o tom do bioma.
@export var cor_rim := Color(0.95, 0.5, 0.72)

@onready var _origem := global_position
@onready var _sprite: Node2D = $Sprite
@onready var _corpo: Sprite2D = get_node_or_null("Sprite/Corpo")
@onready var _area_contacto: Area2D = $AreaContacto

var _direcao := 1.0
var _mat: ShaderMaterial
# animação procedural (visual): bob de idle/andar + antecipação (wind-up)
var _t_anim := 0.0
var _corpo_base := Vector2.ZERO
## Posto a 1.0 por quem quer um "wind-up" (chefes, no telegrafo).
var anticipacao := 0.0
## Recuo visual ao levar dano (roda o sprite para o lado do empurrão e
## decai a zero). Não afeta a física -- só o "juice".
var _flinch := 0.0
var _flinch_dir := 1.0


func _ready() -> void:
	if _area_contacto:
		_area_contacto.body_entered.connect(_ao_tocar)
	if _corpo:
		_corpo_base = _corpo.position
		if _corpo.material is ShaderMaterial:
			_mat = _corpo.material
			_mat.set_shader_parameter("rim_cor", cor_rim)


func _process(dt: float) -> void:
	if _corpo == null:
		return
	_t_anim += dt
	anticipacao = move_toward(anticipacao, 0.0, dt * 3.5)
	_flinch = move_toward(_flinch, 0.0, dt * 6.0)
	var anda := absf(velocity.x) > 5.0
	var vel := 9.0 if anda else 3.2
	var amp := 1.8 if anda else 1.0
	_corpo.position.y = _corpo_base.y + sin(_t_anim * vel) * amp
	var resp := sin(_t_anim * vel * 0.5) * 0.03
	# wind-up: achata e alarga; flinch: comprime na horizontal + roda
	var sx := 1.0 - resp + anticipacao * 0.22 - _flinch * 0.25
	var sy := 1.0 + resp - anticipacao * 0.2 + _flinch * 0.2
	_corpo.scale = Vector2(sx, sy)
	if _sprite:
		_sprite.rotation = _flinch * _flinch_dir * 0.5


func _physics_process(dt: float) -> void:
	velocity.x = _direcao * velocidade
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	move_and_slide()

	if is_on_wall() or absf(global_position.x - _origem.x) > alcance_patrulha \
			or (is_on_floor() and not ha_chao_a_frente(_direcao)):
		_virar()


func _virar() -> void:
	_direcao *= -1.0
	if _sprite:
		_sprite.scale.x = _direcao


## Há chão logo a seguir à beira, na direção `dir`? (raycast para baixo)
func ha_chao_a_frente(dir: float) -> bool:
	var espaco := get_world_2d().direct_space_state
	var origem := global_position + Vector2(signf(dir) * margem_borda, -6.0)
	var q := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0.0, 74.0), 1)
	q.exclude = [self]
	return not espaco.intersect_ray(q).is_empty()


func _ao_tocar(corpo: Node) -> void:
	if corpo is Koliani:
		corpo.receber_dano(dano_contacto, signf(corpo.global_position.x - global_position.x))
		Som.toca("demonio_ataque", -7.0, randf_range(0.9, 1.15))
		anticipacao = 1.0  # dá um "bote" visual no ataque


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	vida -= quantidade
	global_position.x += dir_empurrao * 8.0
	if vida <= 0:
		soltar_estilhacos()
		queue_free()
	else:
		if dir_empurrao != 0.0:
			_flinch_dir = signf(dir_empurrao)
		_flinch = 1.0
		piscar_dano()


## Flash branco curto ao levar dano (feedback de acerto).
func piscar_dano() -> void:
	if _mat:
		_mat.set_shader_parameter("flash", 1.0)
		var t := create_tween()
		t.tween_method(func(v: float): _mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.12)
	elif _sprite:
		_sprite.modulate = Color(2.2, 2.2, 2.2)
		create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)


## Larga um pequeno rebentamento de partículas na posição da morte. O nó
## das partículas fica no pai (o demónio vai ser libertado a seguir) e
## auto-liberta-se quando acaba.
func soltar_estilhacos() -> void:
	var pai := get_parent()
	if pai == null:
		return
	var p := CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 16
	p.lifetime = 0.5
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 350)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = cor_estilhacos
	pai.add_child(p)
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)
