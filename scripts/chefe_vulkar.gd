class_name ChefeVulkar
extends ChefeGenerico
## Vulkar, Cavaleiro das Cinzas (nível 31). Boss próprio: investida em
## chamas e chuva de brasas; a arena fica perigosa durante a segunda fase.

var _pulso := 0.0
var _brasas_t := 0.0
var _fase2 := false

func _ready() -> void:
	# Vulkar usa o rig completo do cavaleiro de fogo: idle, corrida, ataque,
	# dano e morte. A mecânica das brasas continua neste script.
	rig = "cavaleiro_fogo"
	textura = null
	super._ready()

func _process(dt: float) -> void:
	# Rede de segurança da arena do nível 31: se a física perder a plataforma
	# durante a primeira frame, repõe o cavaleiro sobre o chão em vez de o
	# marcar como derrotado antes de o jogador o conseguir ver.
	if global_position.y > 660.0 and not _ja_derrotado:
		global_position.y = 630.0
		velocity.y = 0.0
	_pulso += dt
	_brasas_t += dt
	if not _fase2 and _vida_maxima > 0 and float(vida) / _vida_maxima < 0.5:
		_fase2 = true
	if _brasas_t > (0.8 if _fase2 else 1.35):
		_brasas_t = 0.0
		_largar_brasa()

func _largar_brasa() -> void:
	var pai := get_parent()
	if pai == null: return
	var brasa := Area2D.new()
	brasa.collision_layer = 0
	brasa.collision_mask = 2
	brasa.global_position = global_position + Vector2(randf_range(-28,28), 20)
	var forma := CollisionShape2D.new()
	var cir := CircleShape2D.new(); cir.radius = 9.0; forma.shape = cir
	brasa.add_child(forma); pai.add_child(brasa)
	var p := Polygon2D.new(); p.polygon = PackedVector2Array([Vector2(0,-10),Vector2(8,0),Vector2(0,10),Vector2(-8,0)]); p.color = Color(1,0.3,0.04,0.95); brasa.add_child(p)
	brasa.body_entered.connect(func(alvo: Node) -> void:
		if alvo.is_in_group("koliani"): alvo.receber_dano(12 if _fase2 else 8, 0.0); brasa.queue_free())
	var t := brasa.create_tween()
	t.tween_property(brasa, "global_position:y", global_position.y + 420.0, 1.1)
	t.tween_callback(brasa.queue_free)
