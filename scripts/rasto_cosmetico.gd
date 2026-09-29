extends RefCounted
## RASTOS DO DASH COM ARTE (Loja, categoria "efeitos"). A Koliani chama
## `emitir` a cada eco do `_rasto_dash` quando há um rasto equipado; o que
## emitir vem de `CosmeticosVisuais.rasto_visual()`. Só aparência: nada disto
## toca na física do dash, em colisões ou em tempos.
##
## Cada partícula é um Sprite2D com a folha pixel-art (frames na horizontal)
## e UM tween que a move (velocidade + gravidade, e um bater de asas opcional),
## anima o frame e a apaga -- barato o suficiente para telemóvel (~18 sprites
## por dash, todos livres em ~1 s).

## A silhueta do eco puxada para a tinta do rasto: fica luminosa (lê-se no
## escuro) sem perder o desenho do frame. O `modulate` do eco só leva o alfa.
const SHADER_ECO := """
shader_type canvas_item;
uniform vec4 tinta : source_color = vec4(1.0);
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	COLOR = vec4(mix(t.rgb * tinta.rgb, tinta.rgb, 0.65), COLOR.a);
}
"""

## Quanto do corpo (em px, a partir do centro do sprite) as partículas cobrem.
const ALTURA_CORPO := Vector2(-24.0, 22.0)

static var _shader: Shader
static var _materiais := {}


static func material_eco(rv: Dictionary) -> ShaderMaterial:
	var id := str(rv.get("id", ""))
	if _materiais.has(id):
		return _materiais[id]
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_ECO
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("tinta", rv["eco"])
	_materiais[id] = m
	return m


## Partículas de um eco. `olha` = +1/-1 (para onde a Koliani olha; o rasto
## sai para trás), `grav` = sinal da gravidade (as partículas seguem-na).
static func emitir(pai: Node, centro: Vector2, olha: float, grav: float, rv: Dictionary) -> void:
	if pai == null or rv.is_empty():
		return
	for folha in ["a", "b"]:
		var cfg: Dictionary = rv[folha]
		for _i in int(cfg["qtd"]):
			_uma(pai, centro, olha, grav, cfg)


static func _uma(pai: Node, centro: Vector2, olha: float, grav: float, cfg: Dictionary) -> void:
	var tex: Texture2D = cfg["tex"]
	var n := int(cfg["frames"])
	var s := Sprite2D.new()
	s.name = "RastoCosm"
	s.texture = tex
	s.hframes = n
	s.frame = 0
	s.centered = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	s.z_index = -1
	s.flip_h = olha < 0.0
	var esp := float(cfg["espalha"])
	var p0 := centro + Vector2(randf_range(-esp, esp),
		randf_range(ALTURA_CORPO.x, ALTURA_CORPO.y) * grav)
	s.global_position = p0
	pai.add_child(s)
	var vel: Vector2 = cfg["vel"]
	var v := Vector2(vel.x * olha * randf_range(0.6, 1.2), vel.y * grav * randf_range(0.6, 1.2))
	var g := float(cfg["grav"]) * grav
	var vida := float(cfg["vida"]) * randf_range(0.85, 1.15)
	var fps := float(cfg["fps"])
	var ciclo := bool(cfg.get("ciclo", false))
	var ondula := float(cfg.get("ondula", 0.0))
	var fase := randf() * TAU
	var arranque := randi() % n if ciclo else 0
	var t := s.create_tween()
	t.tween_method(func(tt: float) -> void:
		if not is_instance_valid(s):
			return
		var x := p0.x + v.x * tt + sin(tt * 7.0 + fase) * ondula * tt
		var y := p0.y + v.y * tt + 0.5 * g * tt * tt + sin(tt * 13.0 + fase) * ondula * 0.3
		s.global_position = Vector2(roundf(x), roundf(y))
		if ciclo:
			s.frame = (arranque + int(tt * fps)) % n
		else:
			s.frame = mini(n - 1, int(tt / vida * n))
		s.modulate.a = clampf((vida - tt) / (vida * 0.35), 0.0, 1.0),
		0.0, vida, vida)
	t.tween_callback(s.queue_free)
