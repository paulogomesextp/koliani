class_name ChefeFloresta
extends DemonioBase
## Chefe do mundo 1. Herda patrulha / vida / dano de `DemonioBase` e
## sobrepõe o `_physics_process` com uma máquina de estados:
##
##   PATRULHA  -> anda devagar (lógica da classe-mãe)
##   TELEGRAFO -> vê a Koliani perto e à mesma altura: trava e pisca
##   INVESTIDA -> arranca na direção da Koliani a alta velocidade
##   RECUPERA  -> fica parado e vulnerável, depois volta a patrulhar
##
## Emite `derrotado` ao cair -- o nível liga isso à abertura da porta.

signal derrotado

enum Fase { PATRULHA, TELEGRAFO, INVESTIDA, RECUPERA }

@export var dist_deteta := 280.0
@export var margem_altura := 64.0
@export var vel_investida := 430.0
@export var dur_telegrafo := 0.55
@export var dur_investida := 0.40
@export var dur_recupera := 0.85
@export var dano_investida := 28

var _fase: Fase = Fase.PATRULHA
var _t := 0.0
var _alvo_dir := 1.0
var _koliani: Node2D


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 220)
	velocidade *= 0.6
	add_to_group("chefes")


func _physics_process(dt: float) -> void:
	if not is_instance_valid(_koliani):
		_koliani = get_tree().get_first_node_in_group("koliani")

	match _fase:
		Fase.PATRULHA:
			super._physics_process(dt)
			if _ve_koliani():
				_mudar_fase(Fase.TELEGRAFO)
		Fase.TELEGRAFO:
			_travar(dt)
			_piscar(true)
			if _t >= dur_telegrafo:
				_alvo_dir = _dir_para_koliani()
				if _sprite:
					_sprite.scale.x = _alvo_dir
				_piscar(false)
				_mudar_fase(Fase.INVESTIDA)
		Fase.INVESTIDA:
			velocity.x = _alvo_dir * vel_investida
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if _t >= dur_investida or is_on_wall():
				_mudar_fase(Fase.RECUPERA)
		Fase.RECUPERA:
			_travar(dt)
			if _t >= dur_recupera:
				_mudar_fase(Fase.PATRULHA)

	_t += dt


func _mudar_fase(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _travar(dt: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	move_and_slide()


func _ve_koliani() -> bool:
	if not is_instance_valid(_koliani):
		return false
	var d := _koliani.global_position - global_position
	return absf(d.x) <= dist_deteta and absf(d.y) <= margem_altura


func _dir_para_koliani() -> float:
	if not is_instance_valid(_koliani):
		return _direcao
	return signf(_koliani.global_position.x - global_position.x)


func _piscar(ligado: bool) -> void:
	if _sprite:
		_sprite.modulate = Color(1.7, 1.25, 1.5) if ligado else Color(1, 1, 1)


func _ao_tocar(corpo: Node) -> void:
	if corpo is Koliani:
		var dano := dano_investida if _fase == Fase.INVESTIDA else dano_contacto
		corpo.receber_dano(dano, signf(corpo.global_position.x - global_position.x))


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	vida -= quantidade
	global_position.x += dir_empurrao * 4.0
	if vida <= 0:
		derrotado.emit()
		queue_free()
