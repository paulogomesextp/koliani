class_name ChefeVento
extends ChefeBase
## Chefe do mundo 3 -- o Uivo, uma coisa que voa. Paira acima do chão a
## acompanhar a Koliani; de vez em quando trava, mira (telegrafo) e
## mergulha em diagonal na direção dela. Bate numa parede/chão e volta a
## subir para a altura de voo.

enum Fase { PAIRA, MIRA, MERGULHO, SOBE }

@export var alt_voo := 130.0
@export var vel_deriva := 80.0
@export var vel_mergulho := 540.0
@export var dur_paira := 1.15
@export var dur_mira := 0.5
@export var dur_mergulho := 0.6

var _fase: Fase = Fase.PAIRA
var _t := 0.0
var _y_ref := 0.0
var _alvo := Vector2.ZERO


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 235)
	_y_ref = global_position.y


func _physics_process(dt: float) -> void:
	match _fase:
		Fase.PAIRA:
			var alvo_y := _y_ref - alt_voo + sin(_t * 3.0) * 10.0
			velocity.y = (alvo_y - global_position.y) * 3.0
			var dx := _vetor_para_koliani().x
			velocity.x = signf(dx) * vel_deriva * clampf(absf(dx) / 140.0, 0.0, 1.0)
			_encarar_koliani()
			move_and_slide()
			if _t >= dur_paira and absf(dx) < 380.0:
				provocar()  # travou para mirar -> música de combate
				_ir_para(Fase.MIRA)
		Fase.MIRA:
			velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * dt)
			_piscar(true)
			move_and_slide()
			if _t >= dur_mira:
				_piscar(false)
				var k := _obter_koliani()
				_alvo = k.global_position if k else global_position + Vector2(0, 220)
				_ataque_forte = dur_mergulho
				Som.toca("investida", -10.0)
				_ir_para(Fase.MERGULHO)
		Fase.MERGULHO:
			_ataque_forte = maxf(0.0, _ataque_forte - dt)
			var para := _alvo - global_position
			if para.length() > 8.0:
				velocity = para.normalized() * vel_mergulho
			move_and_slide()
			if _t >= dur_mergulho or is_on_wall() or is_on_floor():
				_ir_para(Fase.SOBE)
		Fase.SOBE:
			var alvo_y := _y_ref - alt_voo
			velocity = Vector2(0.0, (alvo_y - global_position.y) * 4.0)
			move_and_slide()
			if absf(global_position.y - alvo_y) < 12.0:
				_ir_para(Fase.PAIRA)
	_t += dt


func _ir_para(f: Fase) -> void:
	_fase = f
	_t = 0.0
