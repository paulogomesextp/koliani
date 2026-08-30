class_name ChefeFloresta
extends ChefeBase
## Chefe do mundo 1 -- a "Raiz-que-Anda". Patrulha lenta; quando vê a
## Koliani perto e à mesma altura, telegrafa (pausa + pisca) e faz uma
## investida rápida na horizontal, depois fica a recuperar (vulnerável).

enum Fase { PATRULHA, TELEGRAFO, INVESTIDA, RECUPERA }

@export var dist_deteta := 300.0
@export var margem_altura := 70.0
@export var vel_investida := 440.0
@export var dur_telegrafo := 0.55
@export var dur_investida := 0.42
@export var dur_recupera := 0.78

var _fase: Fase = Fase.PATRULHA
var _t := 0.0
var _alvo_dir := 1.0


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 250)
	velocidade *= 0.6
	usa_escudo_boss = false  # leva dano sempre -- sem janela blindada


func _physics_process(dt: float) -> void:
	match _fase:
		Fase.PATRULHA:
			super._physics_process(dt)
			if _ve_koliani():
				provocar()  # detetou a Koliani -> música de combate
				_ir_para(Fase.TELEGRAFO)
		Fase.TELEGRAFO:
			_travar(dt)
			_piscar(true)
			if _t >= dur_telegrafo:
				_alvo_dir = _dir_para_koliani()
				if _sprite:
					_sprite.scale.x = _alvo_dir
				_piscar(false)
				_ataque_forte = dur_investida
				Som.toca("investida", -9.0)
				_ir_para(Fase.INVESTIDA)
		Fase.INVESTIDA:
			_ataque_forte = maxf(0.0, _ataque_forte - dt)
			# se sair do chão a meio da investida (fosso), corta o impulso
			# e cai a direito -- não sai a voar pelo mapa fora
			var no_vazio := _t > 0.05 and not is_on_floor()
			velocity.x = 0.0 if no_vazio else _alvo_dir * vel_investida
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if no_vazio or _t >= dur_investida or is_on_wall():
				_ir_para(Fase.RECUPERA)
		Fase.RECUPERA:
			_travar(dt)
			if _t >= dur_recupera:
				_ir_para(Fase.PATRULHA)
	_t += dt


func _ir_para(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _travar(dt: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	move_and_slide()


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= margem_altura
