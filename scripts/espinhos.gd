extends Armadilha
## Fila de espinhos fixos (Pixel Adventure 1, CC0). Sempre ativos. A origem
## do no fica ao nivel do chao; os picos ocupam os 16px acima. `largura` =
## numero de tiles de 16px.

const TEX := preload("res://assets/sprites/pixel/traps/spikes.png")
const TILE := 16

@export var largura := 3 : set = _set_largura

@onready var _spr: Sprite2D = $Sprite2D
@onready var _forma: CollisionShape2D = $CollisionShape2D


func _pronto() -> void:
	add_to_group("pogavel")          # a Koliani pode ressaltar em cima (pogo)
	set_collision_layer_value(6, true)
	_aplicar()


func _set_largura(v: int) -> void:
	largura = maxi(1, v)
	if is_node_ready():
		_aplicar()


func _aplicar() -> void:
	var w := float(largura * TILE)
	_spr.texture = TEX
	_spr.centered = false
	_spr.region_enabled = true
	_spr.region_rect = Rect2(0, 0, w, TILE)
	_spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_spr.offset = Vector2(-w * 0.5, -TILE)
	var r := RectangleShape2D.new()
	# so os picos magoam -- deixa uns pixeis de folga em cima e nos lados
	r.size = Vector2(w - 4.0, 9.0)
	_forma.shape = r
	_forma.position = Vector2(0.0, -5.0)
