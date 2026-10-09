class_name Deco3D
extends RefCounted
## Pecas do kit da Regiao I (Floresta Corrompida) montadas a partir do Kit3D:
## arvores antigas com raizes, troncos caidos, ruinas sagradas, arcos, menires
## com runas, crescimentos de corrupcao, cogumelos/cristais luminosos,
## folhagem (MultiMesh), feixes de luar e a floresta de fundo.

const K := preload("res://scripts/r3d/kit3d.gd")


static func _rng(semente: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = semente * 7919 + 13
	return r


## Arvore antiga: tronco torto com contrafortes de raiz, ramos, copa em
## massas facetadas e musgo pendente. `corrompida` = casca escura + veios magenta.
static func arvore(pai: Node3D, pos: Vector3, alt := 9.0, raio := 0.55, semente := 0,
		corrompida := false, copa := true, colisao := true) -> Node3D:
	var r := _rng(semente)
	var raiz := Node3D.new()
	raiz.position = pos
	raiz.rotation.y = r.randf() * TAU
	pai.add_child(raiz)
	var m_casca := K.mat("casca_morta" if corrompida else "casca")
	var ctrl := PackedVector3Array()
	var segs := 5
	for i in segs + 1:
		var t := float(i) / segs
		ctrl.append(Vector3(sin(t * 2.3 + semente) * 0.5 * t, t * alt, cos(t * 1.7 + semente) * 0.4 * t))
	var pts := K.curva(ctrl, 3)
	var raios := PackedFloat32Array()
	for i in pts.size():
		var t := float(i) / (pts.size() - 1)
		raios.append(raio * (1.55 - 0.9 * t + 0.6 * pow(1.0 - t, 6.0)))
	K.inst(raiz, K.tubo(pts, raios, 10, 0.22, semente), m_casca)
	# contrafortes / raizes que mordem o chao
	var nr := 4 + r.randi() % 3
	for i in nr:
		var a := TAU * i / nr + r.randf_range(-0.3, 0.3)
		var d := Vector3(cos(a), 0, sin(a))
		var comp := raio * r.randf_range(2.6, 4.2)
		var rp := K.curva(PackedVector3Array([d * raio * 0.5 + Vector3.UP * raio * 1.6,
			d * raio * 1.3 + Vector3.UP * raio * 0.5, d * comp * 0.7 + Vector3.UP * 0.05, d * comp - Vector3.UP * 0.25]), 3)
		K.inst(raiz, K.tubo(rp, K.afunilar(rp.size(), raio * 0.55, raio * 0.08), 7, 0.25, semente + i), m_casca)
	# ramos
	var nramos := 3 + r.randi() % 3
	var topo := pts[pts.size() - 1]
	var pontas: Array[Vector3] = [topo]
	for i in nramos:
		var t := r.randf_range(0.5, 0.92)
		var b0 := pts[int(t * (pts.size() - 1))]
		var a := r.randf() * TAU
		var d := Vector3(cos(a), r.randf_range(0.35, 0.9), sin(a)).normalized()
		var l := alt * r.randf_range(0.22, 0.38)
		var bp := K.curva(PackedVector3Array([b0, b0 + d * l * 0.5 + Vector3.UP * 0.3, b0 + d * l]), 3)
		K.inst(raiz, K.tubo(bp, K.afunilar(bp.size(), raio * 0.38, raio * 0.06), 6, 0.2, semente + 10 + i), m_casca)
		pontas.append(b0 + d * l)
	if copa:
		var m_copa := K.mat("copa_corrompida" if corrompida else "copa")
		for p in pontas:
			var nb := 2 + r.randi() % 2
			for k in nb:
				var rr := alt * r.randf_range(0.11, 0.17)
				var off := Vector3(r.randf_range(-1, 1), r.randf_range(-0.3, 0.6), r.randf_range(-1, 1)) * rr * 0.8
				K.inst(raiz, K.rocha(1.0, semente * 5 + k + 3, 0.62, 0.45, 1), m_copa, p + off,
					Vector3(0, r.randf() * TAU, 0), Vector3.ONE * rr)
		# musgo pendente / lianas
		var m_musgo := K.mat("musgo_pendente")
		for k in 5:
			var p: Vector3 = pontas[r.randi() % pontas.size()] + Vector3(r.randf_range(-1, 1), -0.4, r.randf_range(-1, 1))
			var l := r.randf_range(1.5, 3.5)
			var lp := PackedVector3Array([p, p + Vector3(0.1, -l * 0.5, 0.05), p + Vector3(0.05, -l, -0.05)])
			K.inst(raiz, K.fita(lp, PackedFloat32Array([0.35, 0.25, 0.05]), Vector3.RIGHT), m_musgo, Vector3.ZERO,
				Vector3.ZERO, Vector3.ONE, false)
	if corrompida:
		for k in 3:
			var p := pts[int(r.randf_range(0.1, 0.6) * (pts.size() - 1))]
			corrupcao(raiz, p + Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3)) * raio * 2.0, 0.5, semente + k, false)
	# colisao de jogo (camada 1) ou so' para a camara (camada 16: a camara
	# encosta-se em vez de ficar tapada por um tronco decorativo)
	var corpo := StaticBody3D.new()
	corpo.collision_layer = 1 if colisao else 16
	corpo.collision_mask = 0
	var f := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = raio * 1.25
	cil.height = alt * 0.8
	f.shape = cil
	f.position.y = alt * 0.4
	corpo.add_child(f)
	raiz.add_child(corpo)
	return raiz


## Arvore-landmark gigante (pode ter buraco/arco no tronco).
static func arvore_gigante(pai: Node3D, pos: Vector3, alt := 30.0, raio := 2.6, semente := 0, corrompida := false) -> Node3D:
	var a := arvore(pai, pos, alt, raio, semente, corrompida, true, true)
	return a


## Tronco caido (plataforma): visual + colisao em caixa ao longo.
static func tronco_caido(pai: Node3D, a: Vector3, b: Vector3, raio := 0.6, semente := 0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	pai.add_child(corpo)
	var meio := (a + b) * 0.5
	var ctrl := PackedVector3Array([a, a.lerp(b, 0.33) + Vector3(0.2, 0.1, 0), a.lerp(b, 0.66) + Vector3(-0.2, -0.05, 0.1), b])
	var pts := K.curva(ctrl, 3)
	var raios := PackedFloat32Array()
	for i in pts.size():
		raios.append(raio * (1.0 - 0.15 * float(i) / pts.size()))
	K.inst(corpo, K.tubo(pts, raios, 9, 0.18, semente), K.mat("casca"))
	# toco partido nas pontas
	K.inst(corpo, K.rocha(raio * 1.05, semente + 2, 1.0, 0.4), K.mat("madeira"), b)
	var f := CollisionShape3D.new()
	var cx := BoxShape3D.new()
	var l := a.distance_to(b)
	cx.size = Vector3(raio * 1.5, raio * 1.6, l)
	f.shape = cx
	corpo.add_child(f)
	f.global_transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), meio)
	return corpo


static func rocha(pai: Node3D, pos: Vector3, raio := 1.0, semente := 0, mat := "rocha", colisao := false,
		achatar := 0.7) -> Node3D:
	var mi := K.inst(pai, K.rocha(raio, semente % 23, achatar, 0.35), K.mat(mat), pos, Vector3(0, semente * 1.3, 0))
	if colisao:
		var corpo := StaticBody3D.new()
		var f := CollisionShape3D.new()
		var s := SphereShape3D.new()
		s.radius = raio * 0.85
		f.shape = s
		f.scale = Vector3(1, achatar, 1)
		f.shape = s
		corpo.add_child(f)
		mi.add_child(corpo)
	return mi


## Pilar de ruina sagrada (octogonal, base + fuste + capitel; partido no topo).
static func pilar(pai: Node3D, pos: Vector3, alt := 5.0, raio := 0.45, semente := 0, partido := true,
		colisao := true) -> Node3D:
	var r := _rng(semente)
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = r.randf() * TAU
	pai.add_child(n)
	var m := K.mat("pedra_sagrada")
	K.inst(n, K.bloco(Vector3(raio * 2.8, 0.45, raio * 2.8), semente, 0.05), m, Vector3(0, 0.22, 0))
	var topo := alt * (r.randf_range(0.55, 0.85) if partido else 1.0)
	var perfil := [Vector2(0.4, raio * 1.05), Vector2(0.55, raio * 0.95), Vector2(topo * 0.5, raio * 0.92), Vector2(topo, raio * 0.88)]
	var mi := K.inst(n, K.torno(perfil, 8, 1.0, 1.0, 0.06, semente), m)
	mi.rotation.z = r.randf_range(-0.04, 0.04)
	if not partido:
		K.inst(n, K.bloco(Vector3(raio * 2.6, 0.4, raio * 2.6), semente + 1, 0.05), m, Vector3(0, alt + 0.2, 0))
	else:
		K.inst(n, K.rocha(raio * 0.9, semente + 4, 0.5, 0.5), m, Vector3(0, topo, 0))
		# pedaco caido ao lado
		K.inst(n, K.torno([Vector2(0, raio * 0.9), Vector2(alt * 0.25, raio * 0.86)], 8, 1.0, 1.0, 0.08, semente + 3), m,
			Vector3(raio * 2.2, raio * 0.85, 0.4), Vector3(0, 0.3, PI * 0.5))
	# hera
	K.inst(n, K.fita(PackedVector3Array([Vector3(raio, topo * 0.9, 0), Vector3(raio * 1.05, topo * 0.5, 0.2),
		Vector3(raio, 0.4, 0.1)]), PackedFloat32Array([0.25, 0.35, 0.2]), Vector3(0, 0, 1)), K.mat("musgo_pendente"))
	if colisao:
		var corpo := StaticBody3D.new()
		var f := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = raio
		cil.height = topo
		f.shape = cil
		f.position.y = topo * 0.5
		corpo.add_child(f)
		n.add_child(corpo)
	return n


## Arco sagrado (portal de pedra em aduelas), com runas esmeralda.
static func arco(pai: Node3D, pos: Vector3, rot_y := 0.0, larg := 4.0, alt := 5.0, semente := 0,
		corrompido := false) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	pai.add_child(n)
	var m := K.mat("pedra_sagrada")
	for s in [-1.0, 1.0]:
		var p := pilar(n, Vector3(s * larg * 0.5, 0, 0), alt, 0.42, semente + int(s + 2), false)
		p.rotation.y = 0.0
	var aduelas := 9
	for i in aduelas:
		var a := PI * (i + 0.5) / aduelas
		var c := Vector3(-cos(a) * larg * 0.5, alt + 0.4 + sin(a) * larg * 0.45, 0)
		var b := K.inst(n, K.bloco(Vector3(0.75, 0.6, 0.85), semente + i, 0.06), m, c, Vector3(0, 0, a - PI * 0.5))
		if i == aduelas / 2:
			b.scale = Vector3(1.15, 1.25, 1.1)
	# runas a brilhar no fecho do arco
	var runa := K.inst(n, K.torno([Vector2(-0.02, 0.0), Vector2(0.0, 0.28), Vector2(0.02, 0.0)], 12), K.mat("corrupcao" if corrompido else "cristal"),
		Vector3(0, alt + 0.4 + larg * 0.45, 0.45), Vector3(PI * 0.5, 0, 0), Vector3(1, 1, 0.3), false)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.25, 0.7) if corrompido else Color(0.35, 1.0, 0.75)
	luz.light_energy = 1.4
	luz.omni_range = 7.0
	luz.position = runa.position + Vector3(0, -0.5, 0.6)
	n.add_child(luz)
	return n


## Menir sagrado com anel de runas (marca de caminho / landmark menor).
static func menir(pai: Node3D, pos: Vector3, alt := 3.2, semente := 0, corrompido := false) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	pai.add_child(n)
	var mi := K.inst(n, K.rocha(1.0, semente + 7, 1.0, 0.25), K.mat("pedra_sagrada"), Vector3(0, alt * 0.45, 0),
		Vector3(0, semente, 0), Vector3(0.55, alt * 0.5, 0.42))
	mi.rotation.z = 0.06
	for k in 3:
		K.inst(n, K.torno([Vector2(-0.03, 0.0), Vector2(0.0, 0.62 - k * 0.05), Vector2(0.03, 0.0)], 14),
			K.mat("corrupcao" if corrompido else "cristal"), Vector3(0, alt * (0.35 + k * 0.17), 0), Vector3.ZERO, Vector3(1, 1, 0.75), false)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.25, 0.7) if corrompido else Color(0.35, 1.0, 0.75)
	luz.light_energy = 1.0
	luz.omni_range = 5.0
	luz.position = Vector3(0, alt * 0.6, 0.8)
	n.add_child(luz)
	return n


## Crescimento de corrupcao: espinhos/tumores magenta com veios a pulsar.
static func corrupcao(pai: Node3D, pos: Vector3, escala := 1.0, semente := 0, luz := true) -> Node3D:
	var r := _rng(semente + 100)
	var n := Node3D.new()
	n.position = pos
	pai.add_child(n)
	var m := K.mat("corrupcao")
	K.inst(n, K.rocha(0.6 * escala, semente % 17, 0.6, 0.5), m)
	for i in 5 + r.randi() % 4:
		var d := Vector3(r.randf_range(-1, 1), r.randf_range(0.4, 1.0), r.randf_range(-1, 1)).normalized()
		var l := r.randf_range(0.6, 1.5) * escala
		var b := d * 0.3 * escala
		var pts := K.curva(PackedVector3Array([b, b + d * l * 0.5 + Vector3(r.randf_range(-0.2, 0.2), 0, 0) * escala, b + d * l]), 3)
		K.inst(n, K.tubo(pts, K.afunilar(pts.size(), 0.12 * escala, 0.0), 5), m)
	if luz:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.2, 0.65)
		l.light_energy = 1.2 * escala
		l.omni_range = 4.0 * escala + 1.0
		l.position = Vector3(0, 0.8 * escala, 0)
		n.add_child(l)
	return n


static func cogumelos(pai: Node3D, pos: Vector3, n := 5, semente := 0, escala := 1.0) -> void:
	var r := _rng(semente + 300)
	var raiz := Node3D.new()
	raiz.position = pos
	pai.add_child(raiz)
	for i in n:
		var p := Vector3(r.randf_range(-0.6, 0.6), 0, r.randf_range(-0.6, 0.6)) * escala
		var h := r.randf_range(0.2, 0.55) * escala
		var c := r.randf_range(0.12, 0.28) * escala
		K.inst(raiz, K.torno([Vector2(0, 0.035 * escala), Vector2(h, 0.03 * escala)], 6), K.mat("caule"), p, Vector3.ZERO,
			Vector3.ONE, false)
		K.inst(raiz, K.torno([Vector2(h - 0.02, c * 0.3), Vector2(h, c), Vector2(h + c * 0.25, c * 0.85),
			Vector2(h + c * 0.45, 0.0)], 10), K.mat("cogumelo"), p, Vector3.ZERO, Vector3.ONE, false)
	var l := OmniLight3D.new()
	l.light_color = Color(0.3, 0.95, 0.95)
	l.light_energy = 0.8
	l.omni_range = 3.0 * escala
	l.position = Vector3(0, 0.5, 0)
	raiz.add_child(l)


static func cristais(pai: Node3D, pos: Vector3, escala := 1.0, semente := 0) -> void:
	var r := _rng(semente + 500)
	var raiz := Node3D.new()
	raiz.position = pos
	pai.add_child(raiz)
	for i in 5:
		var d := Vector3(r.randf_range(-0.5, 0.5), 1.0, r.randf_range(-0.5, 0.5)).normalized()
		var l := r.randf_range(0.5, 1.4) * escala
		K.inst(raiz, K.tubo(PackedVector3Array([Vector3.ZERO, d * l * 0.8, d * l]),
			PackedFloat32Array([0.14 * escala, 0.12 * escala, 0.0]), 5), K.mat("cristal"), Vector3(r.randf_range(-0.2, 0.2), 0, r.randf_range(-0.2, 0.2)))
	var lz := OmniLight3D.new()
	lz.light_color = Color(0.35, 1.0, 0.75)
	lz.light_energy = 1.3
	lz.omni_range = 4.5 * escala
	lz.position = Vector3(0, 0.8 * escala, 0)
	raiz.add_child(lz)


static func raio_luz(pai: Node3D, pos: Vector3, alt := 14.0, largura := 2.5, magenta := false) -> void:
	var mi := K.inst(pai, K.cone_luz(alt, largura * 0.3, largura), K.mat("raio_luz_magenta" if magenta else "raio_luz"),
		pos + Vector3.UP * alt, Vector3(0.18, 0, 0.12), Vector3.ONE, false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Folhagem por MultiMesh, pousada no terreno por raios (chamar depois de o
## terreno existir e estar na arvore).
static func folhagem(pai: Node3D, centro: Vector3, raio: float, n: int, tipo := "feto", semente := 0,
		esc := 1.0) -> void:
	var mundo := pai.get_world_3d()
	if mundo == null:
		return
	var espaco := mundo.direct_space_state
	var r := _rng(semente + 900)
	var malha: Mesh
	match tipo:
		"erva": malha = K.tufo(9, 0.55)
		"folha_larga": malha = K.feto(5, 0.9, 0.55)
		_: malha = K.feto(7, 1.0, 0.32)
	var ts: Array[Transform3D] = []
	for i in n * 2:
		if ts.size() >= n:
			break
		var a := r.randf() * TAU
		var d := sqrt(r.randf()) * raio
		var p := centro + Vector3(cos(a) * d, 0, sin(a) * d)
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 6.0, p + Vector3.DOWN * 12.0, 1)
		var hit := espaco.intersect_ray(q)
		if hit.is_empty() or (hit.normal as Vector3).y < 0.7:
			continue
		var s := r.randf_range(0.6, 1.3) * esc
		var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s * r.randf_range(0.8, 1.2), s))
		ts.append(Transform3D(b, pai.to_local(hit.position) + Vector3.DOWN * 0.03))
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malha
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = K.mat(tipo)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 70.0
	pai.add_child(mmi)


## Anel de floresta de fundo (silhuetas altas, sem colisao) a toda a volta.
static func _longe_da_rota(p: Vector3, rota: PackedVector3Array, folga: float) -> bool:
	for q in rota:
		if Vector2(p.x - q.x, p.z - q.z).length() < folga:
			return false
	return true


## `rota` = percurso jogavel: nada de fundo nasce a menos de `folga` dele (os
## niveis sao compridos, nao circulares -- o anel cortava o caminho).
static func fundo_floresta(pai: Node3D, centro: Vector3, raio_min: float, raio_max: float, n: int,
		semente := 0, corrompida_frac := 0.15, rota := PackedVector3Array()) -> void:
	var r := _rng(semente + 1500)
	var no := Node3D.new()
	no.name = "FlorestaFundo"
	pai.add_child(no)
	for i in n:
		var a := TAU * i / n + r.randf_range(-0.1, 0.1)
		var d := r.randf_range(raio_min, raio_max)
		var p := centro + Vector3(cos(a) * d, r.randf_range(-6.0, -2.0), sin(a) * d)
		var alt := r.randf_range(18.0, 34.0)
		var raio := r.randf_range(0.8, 1.6)
		var corr := r.randf() < corrompida_frac
		if not _longe_da_rota(p, rota, 14.0):
			continue
		arvore(no, p, alt, raio, semente + i * 3, corr, true, false)
	# colinas/escarpas longinquas
	for i in n / 3:
		var a := r.randf() * TAU
		var d := raio_max + r.randf_range(8.0, 25.0)
		var p := centro + Vector3(cos(a) * d, r.randf_range(-12.0, -6.0), sin(a) * d)
		var rr := r.randf_range(10.0, 18.0)
		var ach := r.randf_range(0.7, 1.3)
		if not _longe_da_rota(p, rota, rr + 14.0):
			continue
		K.inst(no, K.rocha(rr, i + semente, ach, 0.4), K.mat("rocha"), p)


## Torre sagrada meio afundada no pantano (landmark do N02).
static func torre_afundada(pai: Node3D, pos: Vector3, alt := 22.0, raio := 3.2, incl := 0.12, semente := 0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation = Vector3(incl, semente * 0.7, incl * 0.5)
	pai.add_child(n)
	var m := K.mat("pedra_sagrada")
	var perfil := [Vector2(-4.0, raio * 1.25), Vector2(0.0, raio * 1.15), Vector2(1.0, raio * 1.02),
		Vector2(alt * 0.5, raio * 0.95), Vector2(alt * 0.82, raio * 0.9), Vector2(alt * 0.86, raio * 1.08), Vector2(alt * 0.9, raio * 1.05)]
	K.inst(n, K.torno(perfil, 12, 1.0, 1.0, 0.05, semente), m)
	# janelas escuras e brilho esmeralda la' dentro
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		var h := alt * (0.35 + 0.18 * (i % 3))
		var d := Vector3(cos(a), 0, sin(a))
		K.inst(n, K.bloco(Vector3(0.7, 1.6, 0.6), semente + i, 0.03), K.mat("olho"), d * raio * 0.93 + Vector3.UP * h,
			Vector3(0, -a + PI * 0.5, 0))
	# coroa partida
	var r := _rng(semente + 40)
	for i in 10:
		var a := TAU * i / 10.0
		var hh := r.randf_range(0.6, 3.2)
		K.inst(n, K.bloco(Vector3(1.2, hh, 1.0), semente + 50 + i, 0.08), m,
			Vector3(cos(a), 0, sin(a)) * raio * 0.98 + Vector3.UP * (alt * 0.9 + hh * 0.5), Vector3(0, -a, 0))
	var luz := OmniLight3D.new()
	luz.light_color = Color(0.4, 1.0, 0.7)
	luz.light_energy = 2.0
	luz.omni_range = 14.0
	luz.position = Vector3(0, alt * 0.92, 0)
	n.add_child(luz)
	# hera/musgo a escorrer
	for i in 5:
		var a := TAU * i / 5.0 + 0.5
		var d := Vector3(cos(a), 0, sin(a)) * raio * 1.0
		K.inst(n, K.fita(PackedVector3Array([d + Vector3.UP * alt * 0.85, d * 1.02 + Vector3.UP * alt * 0.5, d + Vector3.UP * 1.0]),
			PackedFloat32Array([0.8, 1.2, 0.6]), Vector3.UP.cross(d).normalized()), K.mat("musgo_pendente"))
	var corpo := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = raio
	cil.height = alt
	f.shape = cil
	f.position.y = alt * 0.5
	corpo.add_child(f)
	n.add_child(corpo)
	return n


## Teia gigante (raios + espiral) entre pontos -- N03.
static func teia(pai: Node3D, centro: Vector3, raio := 5.0, rot_y := 0.0, semente := 0) -> Node3D:
	var n := Node3D.new()
	n.position = centro
	n.rotation.y = rot_y
	pai.add_child(n)
	var m := K.mat("teia")
	var raios := 12
	for i in raios:
		var a := TAU * i / raios + sin(i * 1.3 + semente) * 0.08
		var p := Vector3(cos(a), sin(a), 0) * raio * (0.9 + 0.15 * sin(i * 2.7))
		K.inst(n, K.fita(PackedVector3Array([Vector3.ZERO, p * 0.5 + Vector3(0, -0.15, 0.05), p]),
			PackedFloat32Array([0.05, 0.04, 0.03]), Vector3(0, 0, 1)), m, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	var voltas := 9
	for v in voltas:
		var rr := raio * (0.12 + 0.85 * v / voltas)
		var pts := PackedVector3Array()
		for i in raios + 1:
			var a := TAU * i / raios
			pts.append(Vector3(cos(a), sin(a), 0) * rr + Vector3(0, -0.06 * sin(i * 0.5), 0))
		K.inst(n, K.fita(pts, K.afunilar(pts.size(), 0.035, 0.035), Vector3(0, 0, 1)), m, Vector3.ZERO, Vector3.ZERO,
			Vector3.ONE, false)
	return n


## Casulo pendurado (presa da viuva negra), com fio.
static func casulo(pai: Node3D, pos: Vector3, tam := 1.0, semente := 0) -> void:
	var n := Node3D.new()
	n.position = pos
	pai.add_child(n)
	K.inst(n, K.rocha(0.45 * tam, semente % 13, 1.9, 0.18), K.mat("casulo"), Vector3.ZERO, Vector3(0.2, semente, 0.1))
	K.inst(n, K.fita(PackedVector3Array([Vector3(0, 0.6 * tam, 0), Vector3(0, 6, 0)]), PackedFloat32Array([0.04, 0.03]),
		Vector3.RIGHT), K.mat("teia"), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)


## Salgueiro chorao gigante (landmark do N04): tronco largo, cupula de ramos
## com milhares de "lagrimas" (fitas pendentes) e gotas de luz a cair.
static func salgueiro(pai: Node3D, pos: Vector3, alt := 26.0, raio := 3.0, semente := 0) -> Node3D:
	var t := arvore(pai, pos, alt, raio, semente, false, false, true)
	var r := _rng(semente + 70)
	var m := K.mat("salgueiro")
	var topo := pos + Vector3(0, alt, 0)
	for i in 70:
		var a := r.randf() * TAU
		var d := r.randf_range(2.0, alt * 0.55)
		var p := topo + Vector3(cos(a) * d, -d * 0.35 + r.randf_range(-1.0, 1.5), sin(a) * d)
		var l := r.randf_range(4.0, 11.0)
		var pts := PackedVector3Array([p, p + Vector3(cos(a) * 0.3, -l * 0.5, sin(a) * 0.3), p + Vector3(cos(a) * 0.4, -l, sin(a) * 0.4)])
		K.inst(pai, K.fita(pts, PackedFloat32Array([0.7, 0.55, 0.15]), Vector3(-sin(a), 0, cos(a))), m, Vector3.ZERO,
			Vector3.ZERO, Vector3.ONE, false)
	for i in 14:
		var a := TAU * i / 14.0
		var d := alt * 0.4
		K.inst(pai, K.rocha(1.0, semente + i, 0.5, 0.45, 1), K.mat("copa"), topo + Vector3(cos(a) * d * 0.6, -1.0 + r.randf() * 2.0, sin(a) * d * 0.6),
			Vector3(0, r.randf() * TAU, 0), Vector3.ONE * alt * 0.16)
	var luz := OmniLight3D.new()
	luz.light_color = Color(0.45, 0.85, 1.0)
	luz.light_energy = 2.5
	luz.omni_range = alt * 0.8
	luz.position = topo - Vector3.UP * alt * 0.3
	pai.add_child(luz)
	return t
