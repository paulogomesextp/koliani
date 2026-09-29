extends Armadilha
## Serra circular (Pixel Adventure 1, CC0): gira sempre e faz vaivem ao
## longo de `percurso` (deslocamento ponta-a-ponta a partir da pose da cena).
## Sempre ativa; dano alto.

const TEX := preload("res://assets/sprites/pixel/traps/saw.png")
const FRAMES := 8

@export var percurso := Vector2(180.0, 0.0)
@export var tempo := 1.6  ## segundos por travessia
## Opt-in: em vez da serra CC0 animada, uma lamina pintada (textura unica)
## que gira sobre si propria. Os niveis que nao a definem nao mudam.
@export var textura: Texture2D
@export var escala_textura := 1.0
@export var giro_por_seg := 9.0

var _spr: Sprite2D

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D


func _pronto() -> void:
	dano = maxi(dano, 22)
	add_to_group("pogavel")          # a Koliani pode ressaltar em cima (pogo)
	set_collision_layer_value(6, true)
	_montar_anim()
	if textura:
		_anim.visible = false
		_spr = Sprite2D.new()
		_spr.texture = textura
		_spr.scale = Vector2(escala_textura, escala_textura)
		add_child(_spr)
	if percurso != Vector2.ZERO and tempo > 0.0:
		var base := position
		var t := create_tween().set_loops()
		t.tween_property(self, "position", base + percurso, tempo) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(self, "position", base, tempo) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _montar_anim() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("girar")
	sf.set_animation_speed("girar", 24.0)
	sf.set_animation_loop("girar", true)
	var fw := TEX.get_width() / FRAMES
	var fh := TEX.get_height()
	for i in FRAMES:
		var at := AtlasTexture.new()
		at.atlas = TEX
		at.region = Rect2(i * fw, 0, fw, fh)
		sf.add_frame("girar", at)
	_anim.sprite_frames = sf
	_anim.play("girar")


func _process(dt: float) -> void:
	if _spr:
		_spr.rotation += giro_por_seg * dt
