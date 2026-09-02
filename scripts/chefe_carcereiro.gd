class_name ChefeCarcereiro
extends ChefeBase
## Chefe do mundo 2 -- o Carcereiro. Pesado e lento: aproxima-se da
## Koliani, e quando a tem ao alcance ergue-se (telegrafo), salta e cai
## com um baque que manda uma **onda de choque** rasteira -- só magoa quem
## estiver no chão dentro do raio. Depois recupera, vulnerável.

enum Fase { APROXIMA, TELEGRAFO, SALTO, IMPACTO, RECUPERA }

@export var dist_parar := 150.0
@export var vel_aproxima := 84.0
@export var dur_telegrafo := 0.42
@export var forca_salto := 430.0
@export var raio_onda := 300.0
@export var dano_onda := 30
@export var dur_impacto := 0.26
@export var dur_recupera := 0.5
## Hipótese de encadear um 2.º baque em vez de recuperar (combo pesado).
@export var hip_duplo_baque := 0.45

var _fase: Fase = Fase.APROXIMA
var _t := 0.0
var _onda_feita := false
var _baques_seguidos := 0


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 540)
	usa_escudo_boss = false  # leva dano sempre -- sem janela blindada


func _physics_process(dt: float) -> void:
	match _fase:
		Fase.APROXIMA:
			_encarar_koliani()
			var dx := _vetor_para_koliani().x
			if absf(dx) > dist_parar and ha_chao_a_frente(signf(dx)):
				velocity.x = signf(dx) * vel_aproxima
			else:
				velocity.x = move_toward(velocity.x, 0.0, 700.0 * dt)
			_cair(dt)
			move_and_slide()
			if absf(dx) <= dist_parar and is_on_floor() and _t > 0.5:
				_ir_para(Fase.TELEGRAFO)
		Fase.TELEGRAFO:
			velocity.x = 0.0
			_cair(dt)
			move_and_slide()
			_piscar(true)
			if _t >= dur_telegrafo:
				_piscar(false)
				velocity.y = -forca_salto
				_ir_para(Fase.SALTO)
		Fase.SALTO:
			velocity.y += GRAVIDADE * dt
			_encarar_koliani()
			move_and_slide()
			if is_on_floor() and _t > 0.06:
				_ir_para(Fase.IMPACTO)
		Fase.IMPACTO:
			velocity = Vector2.ZERO
			if not _onda_feita:
				_onda_feita = true
				_onda()
			if _t >= dur_impacto:
				# combo pesado: às vezes salta outra vez em cima da Koliani
				# antes de recuperar (máximo 2 baques seguidos)
				if _baques_seguidos < 2 and randf() < hip_duplo_baque:
					_baques_seguidos += 1
					_encarar_koliani()
					velocity.y = -forca_salto * 0.92
					_ir_para(Fase.SALTO)
				else:
					_baques_seguidos = 0
					_ir_para(Fase.RECUPERA)
		Fase.RECUPERA:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * dt)
			_cair(dt)
			move_and_slide()
			if _t >= dur_recupera:
				_ir_para(Fase.APROXIMA)
	_t += dt


func _ir_para(f: Fase) -> void:
	_fase = f
	_t = 0.0
	_onda_feita = false


func _cair(dt: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt


func _onda() -> void:
	Som.toca("esmagar", -6.0)
	var k := _obter_koliani()
	if k and absf((k.global_position - global_position).x) <= raio_onda \
			and k.is_on_floor():
		k.receber_dano(dano_onda, signf(k.global_position.x - global_position.x))

	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, 28)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 26
	p.lifetime = 0.5
	p.direction = Vector2(1, -0.2)
	p.spread = 25.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 380.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.55, 0.7, 0.95)
	add_sibling(p)
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)
