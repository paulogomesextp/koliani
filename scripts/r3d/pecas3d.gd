class_name Pecas3D
extends RefCounted
## Pecas jogaveis da Regiao I em 3D: fogueira (checkpoint), portal de saida,
## espinhos de corrupcao, raiz que irrompe (RaizPerigo), plataforma ritmada /
## movel. Todas usam os SFX aprovados do 2D com a mesma semantica.

const K := preload("res://scripts/r3d/kit3d.gd")
const VFX := preload("res://scripts/r3d/vfx3d.gd")


static func _koli(n: Node) -> Node3D:
	return n.get_tree().get_first_node_in_group("koliani") as Node3D


## ---------------------------------------------------------------------------
## Fogueira = checkpoint (como no 2D). Acende ao chegar perto.
class Fogueira:
	extends Node3D
	var id := "cp"
	var acesa := false
	var _luz: OmniLight3D
	var _fogo: CPUParticles3D
	var _t := 0.0

	func _ready() -> void:
		var m := K.mat("rocha")
		for i in 7:
			var a := TAU * i / 7.0
			K.inst(self, K.rocha(0.22, i + 30, 0.7, 0.3), m, Vector3(cos(a), 0.08, sin(a)) * 0.55)
		for i in 3:
			var a := TAU * i / 3.0 + 0.4
			var d := Vector3(cos(a), 0, sin(a))
			K.inst(self, K.tubo(PackedVector3Array([d * 0.45 + Vector3.UP * 0.05, -d * 0.1 + Vector3.UP * 0.35]),
				PackedFloat32Array([0.07, 0.05]), 6), K.mat("madeira"))
		_luz = OmniLight3D.new()
		_luz.light_color = Color(1.0, 0.55, 0.25)
		_luz.light_energy = 0.4
		_luz.omni_range = 7.0
		_luz.position = Vector3(0, 0.8, 0)
		add_child(_luz)
		_fogo = CPUParticles3D.new()
		_fogo.amount = 28
		_fogo.lifetime = 0.9
		_fogo.mesh = VFX._quad(0.32)
		_fogo.material_override = VFX.mat_particula(Color(1.0, 0.5, 0.18))
		_fogo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_fogo.emission_sphere_radius = 0.18
		_fogo.direction = Vector3.UP
		_fogo.spread = 15.0
		_fogo.initial_velocity_min = 0.6
		_fogo.initial_velocity_max = 1.4
		_fogo.gravity = Vector3(0, 0.8, 0)
		var c := Curve.new()
		c.add_point(Vector2(0, 1))
		c.add_point(Vector2(1, 0))
		_fogo.scale_amount_curve = c
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.85, 0.45))
		g.set_color(1, Color(0.8, 0.15, 0.3, 0.0))
		_fogo.color_ramp = g
		_fogo.position = Vector3(0, 0.2, 0)
		_fogo.emitting = false
		add_child(_fogo)
		# brasa fraca quando apagada
		_fogo.amount = 28

	func acender(som := true) -> void:
		if acesa:
			return
		acesa = true
		_fogo.emitting = true
		if som:
			Som.toca("selo", -12.0)
			VFX.faisca(get_parent(), global_position + Vector3.UP * 0.5, true, Color(1.0, 0.6, 0.25))

	func _process(dt: float) -> void:
		_t += dt
		_luz.light_energy = (2.4 + 0.4 * sin(_t * 13.0) + 0.25 * sin(_t * 7.3)) if acesa else 0.35 + 0.1 * sin(_t * 3.0)
		if acesa:
			return
		var k := Pecas3D._koli(self)
		if k and k.global_position.distance_to(global_position) < 2.0:
			acender()
			Nivel3D.guardar_checkpoint(id, global_position + Vector3(0, 0.1, 0))


## ---------------------------------------------------------------------------
## Portal de saida: arco de pedra com vortice magenta. Fechado ate' `abrir()`.
class PortalSaida:
	extends Node3D
	signal atravessado
	var aberto := true
	var _aneis: Array[MeshInstance3D] = []
	var _luz: OmniLight3D
	var _t := 0.0
	var _usado := false

	func _ready() -> void:
		Deco3D.arco(self, Vector3.ZERO, 0.0, 3.6, 4.2, 77, false)
		for i in 3:
			var a := K.inst(self, K.anel(1.0 - i * 0.25, 1.35 - i * 0.25), K.mat("vfx_onda"), Vector3(0, 3.0, 0),
				Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)
			_aneis.append(a)
		var nucleo := K.inst(self, K.disco(1.0, 32), K.mat("vfx_magenta"), Vector3(0, 3.0, 0), Vector3(PI * 0.5, 0, 0),
			Vector3(1.0, 1, 1.0), false)
		nucleo.transparency = 0.5
		_aneis.append(nucleo)
		_luz = OmniLight3D.new()
		_luz.light_color = Color(1.0, 0.3, 0.8)
		_luz.light_energy = 2.5
		_luz.omni_range = 9.0
		_luz.position = Vector3(0, 3.0, 1.0)
		add_child(_luz)
		VFX.esporos(self, Vector3(0, 3.0, 0), Vector3(1.2, 1.5, 0.4), Color(1.0, 0.4, 0.85), 20)
		_mostrar(aberto)

	func _mostrar(v: bool) -> void:
		for a in _aneis:
			a.visible = v
		if _luz:
			_luz.visible = v

	func abrir() -> void:
		aberto = true
		_mostrar(true)
		Som.toca("portal", -10.0, 1.0, 0.02)

	func fechar() -> void:
		aberto = false
		_mostrar(false)

	func _process(dt: float) -> void:
		_t += dt
		for i in _aneis.size():
			_aneis[i].rotation.y += dt * (1.1 if i % 2 == 0 else -1.7)
		if _luz:
			_luz.light_energy = 2.3 + 0.4 * sin(_t * 3.0)
		if not aberto or _usado:
			return
		var k := Pecas3D._koli(self)
		if k and not bool(k.call("esta_morta")):
			var d := k.global_position - global_position
			if Vector2(d.x, d.z).length() < 1.5 and d.y > -1.0 and d.y < 3.5:
				_usado = true
				atravessado.emit()


## ---------------------------------------------------------------------------
## Espinhos de corrupcao (estaticos): ferem ao toque.
class Espinhos:
	extends Node3D
	var tam := Vector2(2.0, 1.0)
	var dano := 12
	var _cd := 0.0

	func _ready() -> void:
		add_to_group("perigos3d")
		var r := RandomNumberGenerator.new()
		r.seed = int(global_position.x * 13.0 + global_position.z * 7.0)
		var m := K.mat("corrupcao")
		var n := int(tam.x * tam.y * 7.0) + 4
		for i in n:
			var p := Vector3(r.randf_range(-0.5, 0.5) * tam.x, 0, r.randf_range(-0.5, 0.5) * tam.y)
			var d := Vector3(r.randf_range(-0.35, 0.35), 1, r.randf_range(-0.35, 0.35)).normalized()
			var l := r.randf_range(0.45, 0.95)
			K.inst(self, K.tubo(PackedVector3Array([p - Vector3.UP * 0.1, p + d * l]), PackedFloat32Array([0.09, 0.0]), 5), m)
		K.inst(self, K.rocha(1.0, 3, 0.25, 0.3), K.mat("terreno_corrompido"), Vector3.ZERO, Vector3.ZERO,
			Vector3(tam.x * 0.55, 1, tam.y * 0.55))

	func _process(dt: float) -> void:
		_cd -= dt
		if _cd > 0.0:
			return
		var k := Pecas3D._koli(self)
		if k == null:
			return
		var d := global_transform.affine_inverse() * k.global_position
		if absf(d.x) < tam.x * 0.5 + 0.25 and absf(d.z) < tam.y * 0.5 + 0.25 and d.y < 0.9 and d.y > -0.5:
			k.call("receber_dano", dano, global_position + Vector3.DOWN, 7.0)
			_cd = 0.5


## ---------------------------------------------------------------------------
## Raiz que irrompe (RaizPerigo do 2D): racha a brilhar (aviso) -> espinhos de
## raiz saem do chao -> recolhem. Ciclo com desfasamento.
class Raiz:
	extends Node3D
	var periodo := 3.2
	var atraso := 0.0
	var aviso_dur := 1.0
	var ativo_dur := 0.7
	var raio := 1.3
	var dano := 15
	var _t := 0.0
	var _marca: MeshInstance3D
	var _espinhos: Node3D
	var _fase := 0
	var _acertou := false

	func _ready() -> void:
		add_to_group("perigos3d")
		_t = -atraso
		_marca = K.inst(self, K.disco(raio, 28), K.mat_unico("vfx_aviso"), Vector3(0, 0.05, 0), Vector3.ZERO, Vector3.ONE, false)
		_marca.visible = false
		_espinhos = Node3D.new()
		add_child(_espinhos)
		var m := K.mat("casca_morta")
		var mc := K.mat("corrupcao")
		for i in 7:
			var a := TAU * i / 7.0
			var p := Vector3(cos(a), 0, sin(a)) * raio * (0.25 + 0.5 * fmod(i * 0.37, 1.0))
			var pts := K.curva(PackedVector3Array([p - Vector3.UP * 0.4, p + Vector3(0.1, 0.8, 0.05), p + Vector3(-0.05, 1.6, 0.1)]), 3)
			K.inst(_espinhos, K.tubo(pts, K.afunilar(pts.size(), 0.2, 0.0), 6, 0.2, i), m if i % 3 else mc)
		_espinhos.scale = Vector3(1, 0.01, 1)
		_espinhos.visible = false
		# racha permanente no chao (para se ler onde e')
		K.inst(self, K.rocha(1.0, 9, 0.12, 0.4), K.mat("terreno_corrompido"), Vector3(0, -0.02, 0), Vector3.ZERO,
			Vector3(raio * 0.8, 1, raio * 0.8))

	func _process(dt: float) -> void:
		_t += dt
		if _t < 0.0:
			return
		var c := fmod(_t, periodo)
		var k := Pecas3D._koli(self)
		var perto := k != null and k.global_position.distance_to(global_position) < 22.0
		if c < aviso_dur:
			if _fase != 1:
				_fase = 1
				_marca.visible = true
				_acertou = false
				if perto:
					Som.toca("raiz_aviso", -14.0, randf_range(0.94, 1.07))
			_marca.transparency = 0.6 - 0.6 * (c / aviso_dur)
		elif c < aviso_dur + ativo_dur:
			if _fase != 2:
				_fase = 2
				_marca.visible = false
				_espinhos.visible = true
				var tw := _espinhos.create_tween()
				tw.tween_property(_espinhos, "scale", Vector3.ONE, 0.09)
				if perto:
					Som.toca("raiz_irrompe", -7.0, randf_range(0.92, 1.09))
			if not _acertou and k:
				var d := k.global_position - global_position
				if Vector2(d.x, d.z).length() < raio + 0.25 and d.y < 1.6 and d.y > -0.6:
					_acertou = true
					k.call("receber_dano", dano, global_position, 6.0)
		else:
			if _fase != 0:
				_fase = 0
				var tw := _espinhos.create_tween()
				tw.tween_property(_espinhos, "scale", Vector3(1, 0.01, 1), 0.25)
				tw.tween_callback(func() -> void: _espinhos.visible = false)


## ---------------------------------------------------------------------------
## Plataforma de pedra sagrada que se move entre dois pontos (ou sobe/desce).
class PlataformaMovel:
	extends AnimatableBody3D
	var tam := Vector3(3.0, 0.6, 3.0)
	var desloc := Vector3(0, 0, 6)
	var periodo := 5.0
	var fase := 0.0
	var _base := Vector3.ZERO
	var _t := 0.0

	func _ready() -> void:
		add_to_group("chao_movel")
		sync_to_physics = true
		_base = position
		_t = fase * periodo
		K.inst(self, K.bloco(tam, int(_base.x) % 7, 0.07), K.mat("pedra_sagrada"))
		K.inst(self, K.torno([Vector2(-0.05, 0.0), Vector2(0.0, tam.x * 0.28), Vector2(0.03, 0.0)], 14),
			K.mat("cristal"), Vector3(0, -tam.y * 0.5 - 0.02, 0), Vector3(PI, 0, 0), Vector3(1, 1, 1), false)
		var f := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = tam
		f.shape = b
		add_child(f)

	func _physics_process(dt: float) -> void:
		_t += dt
		var k := (1.0 - cos(_t / periodo * TAU)) * 0.5
		position = _base + desloc * k


## ---------------------------------------------------------------------------
## Caixa de dano (onda do chefe, etc.) -- usado pelo chefe.
static func ferir_se_dentro(n: Node, centro: Vector3, raio: float, alt: float, dano: int, recuo := 6.0) -> bool:
	var k := _koli(n)
	if k == null:
		return false
	var d := k.global_position - centro
	if Vector2(d.x, d.z).length() < raio and d.y > -0.6 and d.y < alt:
		k.call("receber_dano", dano, centro, recuo)
		return true
	return false
