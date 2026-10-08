class_name Vfx3D
extends RefCounted
## VFX da Koliani 3D: rasto da espada, faiscas de acerto, poeira, anel de
## salto duplo, esporos/pirilampos ambiente. Tudo aditivo e barato.

const K := preload("res://scripts/r3d/kit3d.gd")

static var _mat_part := {}


static func mat_particula(cor: Color, aditivo := true) -> StandardMaterial3D:
	var chave := "%s_%s" % [cor, aditivo]
	if _mat_part.has(chave):
		return _mat_part[chave]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if aditivo:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.albedo_color = cor
	m.albedo_texture = _tex_bola()
	m.disable_receive_shadows = true
	_mat_part[chave] = m
	return m


static var _bola: Texture2D


static func _tex_bola() -> Texture2D:
	if _bola == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_bola = t
	return _bola


static func _quad(tam: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(tam, tam)
	return q


static func _burst(pai: Node, pos: Vector3, n: int, cor: Color, vel: float, tam: float, vida: float,
		grav := Vector3(0, -6, 0), esfera := 0.2) -> CPUParticles3D:
	if pai == null or not pai.is_inside_tree():
		return null
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = n
	p.lifetime = vida
	p.explosiveness = 0.95
	p.mesh = _quad(tam)
	p.material_override = mat_particula(cor)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = vel * 0.4
	p.initial_velocity_max = vel
	p.gravity = grav
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = esfera
	var curva := Curve.new()
	curva.add_point(Vector2(0, 1))
	curva.add_point(Vector2(1, 0))
	p.scale_amount_curve = curva
	p.color = cor
	pai.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func faisca(pai: Node, pos: Vector3, forte := false, cor := Color(1.0, 0.35, 0.85)) -> void:
	_burst(pai, pos, 18 if forte else 10, cor, 7.0 if forte else 5.0, 0.16 if forte else 0.11, 0.35)
	_burst(pai, pos, 1, Color(1, 0.9, 1), 0.0, 1.4 if forte else 0.9, 0.12, Vector3.ZERO, 0.0)
	if pai and pai.is_inside_tree():
		var luz := OmniLight3D.new()
		luz.light_color = cor
		luz.light_energy = 3.0 if forte else 1.8
		luz.omni_range = 4.0
		pai.add_child(luz)
		luz.global_position = pos
		var t := luz.create_tween()
		t.tween_property(luz, "light_energy", 0.0, 0.18)
		t.tween_callback(luz.queue_free)


static func poeira(pai: Node, pos: Vector3, forca := 1.0) -> void:
	var p := _burst(pai, pos + Vector3.UP * 0.1, int(10 * forca), Color(0.45, 0.5, 0.42, 0.5), 2.5 * forca,
		0.35, 0.5, Vector3(0, 0.6, 0), 0.35)
	if p:
		p.material_override = mat_particula(Color(0.45, 0.5, 0.42, 0.45), false)
		p.direction = Vector3(0, 0.2, 0)
		p.spread = 90.0


static func anel_salto(pai: Node, pos: Vector3) -> void:
	if pai == null:
		return
	var mi := K.inst(pai, K.anel(0.3, 0.55), K.mat("vfx_onda"), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	mi.global_position = pos + Vector3.UP * 0.1
	var t := mi.create_tween()
	t.set_parallel(true)
	t.tween_property(mi, "scale", Vector3(3, 1, 3), 0.35)
	t.tween_property(mi, "transparency", 1.0, 0.35)
	t.chain().tween_callback(mi.queue_free)
	_burst(pai, pos, 12, Color(1.0, 0.3, 0.8), 3.0, 0.12, 0.4)


## Esporos/pirilampos a flutuar numa caixa (ambiente).
static func esporos(pai: Node, centro: Vector3, caixa: Vector3, cor: Color, n := 40) -> void:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.mesh = _quad(0.09)
	p.material_override = mat_particula(cor)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = caixa
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.35
	p.gravity = Vector3(0, 0.05, 0)
	p.color = cor
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0))
	curva.add_point(Vector2(0.2, 1))
	curva.add_point(Vector2(0.8, 1))
	curva.add_point(Vector2(1, 0))
	p.scale_amount_curve = curva
	pai.add_child(p)
	p.position = centro


## Rasto da espada: fita aditiva entre a base e a ponta da lamina nos ultimos
## fotogramas, enquanto `ativo`.
static func rasto_espada(dono: Node3D, modelo: Node3D) -> Node3D:
	var r := RastoEspada.new()
	r.modelo = modelo
	dono.add_child(r)
	return r


class RastoEspada:
	extends MeshInstance3D
	var modelo: Node3D
	var ativo := false
	var _pts: Array = []  # [base, ponta, idade]
	var _im := ImmediateMesh.new()

	func _ready() -> void:
		mesh = _im
		material_override = K.mat("vfx_magenta")
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		top_level = true
		global_transform = Transform3D.IDENTITY

	func _process(dt: float) -> void:
		for p in _pts:
			p[2] += dt
		while _pts.size() > 0 and _pts[0][2] > 0.14:
			_pts.pop_front()
		if ativo and modelo and modelo.get("ponta_espada"):
			var b: Node3D = modelo.get("base_espada")
			var t: Node3D = modelo.get("ponta_espada")
			_pts.append([b.global_position, t.global_position, 0.0])
		_im.clear_surfaces()
		if _pts.size() < 2:
			return
		_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for p in _pts:
			var a := 1.0 - float(p[2]) / 0.14
			_im.surface_set_color(Color(1, 1, 1, a * 0.15))
			_im.surface_set_uv(Vector2(0, 0))
			_im.surface_add_vertex(p[0])
			_im.surface_set_color(Color(1, 1, 1, a * 0.95))
			_im.surface_set_uv(Vector2(0, 1))
			_im.surface_add_vertex(p[1])
		_im.surface_end()
