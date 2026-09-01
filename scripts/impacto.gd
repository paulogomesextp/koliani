class_name Impacto
extends AnimatedSprite2D
## Estalo visual de um acerto: um anel roxo que abre no ponto do golpe e
## desaparece. Instancia-se, põe-se em `global_position` e trata de si --
## toca a animação uma vez e liberta-se.
##
## Existe porque as faíscas de partículas sozinhas não marcam o INSTANTE do
## acerto: falta um "pop" com forma, que é o que o Dead Cells faz.
##
## Uso: `Impacto.rebentar(self, pos)` (ou `pos, cor, escala`).

const TIRA := preload("res://assets/sprites/pixel/fx/impacto_roxo.png")
const FRAMES := 4
const FPS := 26.0


## Cria um impacto na árvore de `onde`, no ponto `pos` (coordenadas de
## mundo). `cor` tinge o anel (por omissão fica a cor do pack).
static func rebentar(onde: Node, pos: Vector2, cor := Color(1, 1, 1),
		escala := 2.4) -> void:
	if onde == null or not onde.is_inside_tree():
		return
	var fx := Impacto.new()
	fx.global_position = pos
	fx.modulate = cor
	fx.scale = Vector2(escala, escala)
	onde.get_tree().current_scene.add_child(fx)
	fx.global_position = pos


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 40
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("pop")
	sf.set_animation_speed("pop", FPS)
	sf.set_animation_loop("pop", false)
	var fw := TIRA.get_width() / FRAMES
	for i in FRAMES:
		var at := AtlasTexture.new()
		at.atlas = TIRA
		at.region = Rect2(i * fw, 0, fw, TIRA.get_height())
		sf.add_frame("pop", at)
	sprite_frames = sf
	rotation = randf_range(0.0, TAU)
	animation_finished.connect(queue_free)
	play("pop")
