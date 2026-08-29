extends Armadilha
## Jato de fogo periodico (Pixel Adventure 1, CC0). Ciclo:
##   dormente (`intervalo`s) -> telegrafo curto -> chama (`dur_ativa`s).
## So magoa enquanto a chama esta acesa. `fase` desfasa varios jatos no
## mesmo nivel. A origem do no fica ao nivel do chao (a base de madeira
## desce, a chama sobe).

const TEX_ON := preload("res://assets/sprites/pixel/traps/fire_on.png")
const TEX_OFF := preload("res://assets/sprites/pixel/traps/fire_off.png")

@export var intervalo := 1.8
@export var dur_ativa := 1.4
@export var fase := 0.0  ## atraso antes do 1.o ciclo

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _luz: PointLight2D = $Luz


func _pronto() -> void:
	dano = maxi(dano, 18)
	ativa = false
	_montar_anim()
	_anim.play("off")
	_luz.energy = 0.0
	_ciclo()


func _montar_anim() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("off")
	sf.set_animation_loop("off", true)
	sf.set_animation_speed("off", 1.0)
	var off := AtlasTexture.new()
	off.atlas = TEX_OFF
	off.region = Rect2(0, 0, 16, 32)
	sf.add_frame("off", off)
	sf.add_animation("on")
	sf.set_animation_loop("on", true)
	sf.set_animation_speed("on", 14.0)
	for i in 3:
		var at := AtlasTexture.new()
		at.atlas = TEX_ON
		at.region = Rect2(i * 16, 0, 16, 32)
		sf.add_frame("on", at)
	_anim.sprite_frames = sf


func _ciclo() -> void:
	if fase > 0.0:
		await get_tree().create_timer(fase).timeout
	while is_instance_valid(self):
		_anim.play("off")
		await get_tree().create_timer(intervalo).timeout
		if not is_instance_valid(self):
			return
		# telegrafo: a luz cresce um bocado antes da chama
		create_tween().tween_property(_luz, "energy", 0.5, 0.18)
		await get_tree().create_timer(0.24).timeout
		if not is_instance_valid(self):
			return
		_anim.play("on")
		ativa = true
		_luz.energy = 1.1
		Som.toca("investida", -16.0, 1.7)
		_ferir_presentes()
		await get_tree().create_timer(dur_ativa).timeout
		ativa = false
		create_tween().tween_property(_luz, "energy", 0.0, 0.2)
