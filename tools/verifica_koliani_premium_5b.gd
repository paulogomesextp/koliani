extends Node
## Verificacao dirigida da integracao visual da Execution 5B.

const CENA_LEVEL_1 := preload("res://scenes/levels/Floresta_Putrefata.tscn")
const CENA_LEVEL_2 := preload("res://scenes/levels/Pantano_dos_Sussurros.tscn")

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_executar")


func _exigir(condicao: bool, mensagem: String) -> void:
	if not condicao:
		_falhas.append(mensagem)


func _executar() -> void:
	var level_1 := CENA_LEVEL_1.instantiate()
	get_tree().root.add_child(level_1)
	await get_tree().process_frame
	var koliani := level_1.get_node_or_null("Koliani")
	_exigir(koliani != null, "Level 1 sem Koliani")
	if koliani != null:
		_exigir(koliani.usar_prototipo_premium, "prototype nao activo no Level 1")
		var corpo: AnimatedSprite2D = koliani.get_node("Sprite/Corpo")
		var sf := corpo.sprite_frames
		var esperadas := {
			"idle": 4, "run": 5, "jump": 3, "fall": 2, "dash": 3,
			"attack": 6, "attack2": 6, "attack3": 6, "attack4": 6,
			"hurt": 2, "morte": 5,
		}
		for nome: String in esperadas:
			_exigir(sf.has_animation(nome), "animacao em falta: " + nome)
			if sf.has_animation(nome):
				_exigir(sf.get_frame_count(nome) == esperadas[nome],
					"contagem errada em %s" % nome)
		_exigir(corpo.scale.is_equal_approx(Vector2(0.75, 0.75)),
			"escala premium alterada")
		var pes_y := (90.0 - 48.0 + corpo.offset.y) * corpo.scale.y
		_exigir(is_equal_approx(pes_y, 22.0), "pes fora de y=22: %.3f" % pes_y)
		var corpo_col: CollisionShape2D = koliani.get_node("CollisionShape2D")
		_exigir(corpo_col.shape.size.is_equal_approx(Vector2(20, 44)),
			"colisao corporal alterada")
		var hit_col: CollisionShape2D = koliani.get_node("HitboxAtaque/CollisionShape2D")
		_exigir(hit_col.shape.size.is_equal_approx(Vector2(30, 34)),
			"tamanho da hitbox alterado")
		_exigir(hit_col.position.is_equal_approx(Vector2(23, -4)),
			"posicao da hitbox alterada")
	level_1.queue_free()
	await get_tree().process_frame

	var level_2 := CENA_LEVEL_2.instantiate()
	var koliani_2 := level_2.get_node_or_null("Koliani")
	_exigir(koliani_2 != null, "Level 2 sem Koliani")
	if koliani_2 != null:
		_exigir(not koliani_2.usar_prototipo_premium,
			"prototype escapou do Level 1")
	level_2.free()

	if _falhas.is_empty():
		print("EXECUTION 5B TARGETED: PASS")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		print("EXECUTION 5B TARGETED: FAIL (%d)" % _falhas.size())
		get_tree().quit(1)
