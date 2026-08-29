@tool
extends StaticBody2D
## Plataforma reutilizável com visual procedural (ver
## assets/shaders/plataforma.gdshader). Define `tamanho` (e as cores do
## bioma) e o resto -- colisão, ColorRect, parâmetros do shader -- ajusta-se
## sozinho. `@tool` para dar para ver no editor.

@export var tamanho := Vector2(200.0, 40.0) : set = _set_tamanho
## Altura do visual (0 = igual à colisão). Maior => "slab" de chão grosso
## que desce por baixo da superfície, sem mexer na colisão.
@export var altura_visual := 0.0 : set = _set_altura_visual
@export var cor_base := Color(0.15, 0.21, 0.11) : set = _set_cor_base
@export var cor_topo := Color(0.42, 0.62, 0.28) : set = _set_cor_topo


func _ready() -> void:
	_aplicar()


func _set_tamanho(v: Vector2) -> void:
	tamanho = v
	_aplicar()


func _set_altura_visual(v: float) -> void:
	altura_visual = v
	_aplicar()


func _set_cor_base(c: Color) -> void:
	cor_base = c
	_aplicar()


func _set_cor_topo(c: Color) -> void:
	cor_topo = c
	_aplicar()


func _aplicar() -> void:
	if not is_node_ready():
		return
	var vis := get_node_or_null("Visual") as ColorRect
	if vis:
		var vis_h := maxf(tamanho.y, altura_visual)
		vis.size = Vector2(tamanho.x, vis_h)
		vis.position = -tamanho * 0.5  # topo do visual alinhado com o topo da colisão
		var m := vis.material as ShaderMaterial
		if m:
			m.set_shader_parameter("tamanho", Vector2(tamanho.x, vis_h))
			m.set_shader_parameter("cor_base", cor_base)
			m.set_shader_parameter("cor_topo", cor_topo)
	var cs := get_node_or_null("Col") as CollisionShape2D
	if cs:
		var r := RectangleShape2D.new()
		r.size = tamanho
		cs.shape = r
