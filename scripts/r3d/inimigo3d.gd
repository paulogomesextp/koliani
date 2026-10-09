class_name Inimigo3D
extends CharacterBody3D
## Inimigos da Regiao I em 3D. Tipos (as especies do 2D da regiao):
##   goblin -- goblin corrompido (lamina ferrugenta), o soldado da floresta
##   gosma  -- gosma toxica, avanca aos saltos e cai em cima
##   bruto  -- elite (o guardiao Ghorak/Entrevane da regiao): maca, golpe de
##             chao com aviso no solo
## IA: patrulha perto de casa -> deteta -> persegue -> ataque com aviso
## (antecipacao legivel) -> recupera. Nao cai das plataformas (sonda o chao).
## Sons: as vozes aprovadas `mob_<familia>_<ataque|dano|morte>` do 2D.

const K := preload("res://scripts/r3d/kit3d.gd")
const VFX := preload("res://scripts/r3d/vfx3d.gd")

const TIPOS := {
	"goblin": {"vida": 110, "vel": 3.4, "dano": 12, "alcance": 1.7, "ante": 0.45, "golpe": 0.25, "rec": 0.6,
		"raio": 0.45, "altura": 1.25, "detecao": 10.0, "massa": 1.0, "som": "humano"},
	"gosma": {"vida": 70, "vel": 2.6, "dano": 10, "alcance": 3.4, "ante": 0.55, "golpe": 0.55, "rec": 0.7,
		"raio": 0.55, "altura": 0.9, "detecao": 9.0, "massa": 0.8, "som": "gosma"},
	"bruto": {"vida": 850, "vel": 2.5, "dano": 24, "alcance": 2.6, "ante": 0.8, "golpe": 0.3, "rec": 0.9,
		"raio": 0.8, "altura": 2.3, "detecao": 13.0, "massa": 3.0, "som": "grande"},
}

signal morreu_inimigo

@export var tipo := "goblin"
var vida := 100
var vida_max := 100
var morto := false
var raio_corpo := 0.5
var casa := Vector3.ZERO
var raio_patrulha := 3.0
var _d: Dictionary
var _estado := "patrulha"
var _t := 0.0
var _alvo_patrulha := Vector3.ZERO
var _stagger := 0.0
var _rumo := 0.0
var _modelo: Node3D
var _juntas := {}
var _mats: Array[ShaderMaterial] = []
var _aviso: MeshInstance3D
var _fase := 0.0
var _salto_alvo := Vector3.ZERO
var _acertou := false
var _koliani: Node3D


func _ready() -> void:
	add_to_group("inimigos3d")
	_d = TIPOS.get(tipo, TIPOS["goblin"])
	vida = int(_d["vida"])
	vida_max = vida
	raio_corpo = float(_d["raio"])
	collision_layer = 4
	collision_mask = 1
	casa = global_position
	_alvo_patrulha = casa
	_rumo = randf() * TAU
	var f := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = raio_corpo
	cap.height = maxf(float(_d["altura"]), raio_corpo * 2.0 + 0.1)
	f.shape = cap
	f.position.y = cap.height * 0.5
	add_child(f)
	_modelo = Node3D.new()
	add_child(_modelo)
	match tipo:
		"gosma": _construir_gosma()
		"bruto": _construir_bruto()
		_: _construir_goblin()
	_aviso = K.inst(self, K.disco(1.0), K.mat_unico("vfx_aviso"),
		Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	_aviso.top_level = true
	_aviso.visible = false


func centro_golpe() -> Vector3:
	return global_position + Vector3.UP * float(_d["altura"]) * 0.5


func _m(nome: String) -> ShaderMaterial:
	var m := K.mat_unico(nome)
	_mats.append(m)
	return m


func _j(pai: Node3D, nome: String, pos: Vector3) -> Node3D:
	var j := Node3D.new()
	j.position = pos
	pai.add_child(j)
	_juntas[nome] = j
	return j


## Goblin corrompido: corcunda, orelhas compridas, olhos magenta, trapos,
## lamina ferrugenta. ~1,25 m.
func _construir_goblin() -> void:
	var pele := _m("pele_goblin")
	var trapo := K.mat("trapo")
	var corpo := _j(_modelo, "corpo", Vector3(0, 0.62, 0))
	K.inst(corpo, K.torno([Vector2(-0.05, 0.16), Vector2(0.1, 0.2), Vector2(0.28, 0.22), Vector2(0.42, 0.17),
		Vector2(0.5, 0.08)], 10, 1.0, 0.8, 0.12, 3), pele, Vector3.ZERO, Vector3(0.45, 0, 0))
	K.inst(corpo, K.torno([Vector2(0.0, 0.2), Vector2(-0.08, 0.24), Vector2(-0.26, 0.28)], 10, 1.0, 0.85, 0.25, 5), trapo)
	var cab := _j(corpo, "cabeca", Vector3(0, 0.46, 0.2))
	K.inst(cab, K.rocha(0.2, 4, 0.9, 0.15), pele, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.9, 1.15))
	K.inst(cab, K.rocha(0.13, 6, 0.6, 0.15), pele, Vector3(0, -0.1, 0.1))
	for s in [-1.0, 1.0]:
		K.inst(cab, K.tubo(PackedVector3Array([Vector3(0.12 * s, 0.05, -0.02), Vector3(0.3 * s, 0.12, -0.08),
			Vector3(0.48 * s, 0.22, -0.12)]), PackedFloat32Array([0.07, 0.04, 0.0]), 5, 0.0, 0, 0.35), pele)
		K.inst(cab, K.rocha(0.035, 2, 1.0, 0.0), K.mat("olho_corrupto"), Vector3(0.075 * s, 0.03, 0.17))
	for s in [-1.0, 1.0]:
		var ombro := _j(corpo, "ombro%d" % int(s), Vector3(0.22 * s, 0.38, 0.08))
		K.inst(ombro, K.tubo(PackedVector3Array([Vector3.ZERO, Vector3(0.05 * s, -0.25, 0.03), Vector3(0.04 * s, -0.52, 0.08)]),
			PackedFloat32Array([0.07, 0.055, 0.05]), 7), pele)
		K.inst(ombro, K.rocha(0.07, 9, 1.0, 0.2), pele, Vector3(0.04 * s, -0.55, 0.08))
		if s < 0.0:
			var lam := Node3D.new()
			lam.position = Vector3(0.04 * s, -0.56, 0.1)
			lam.rotation = Vector3(deg_to_rad(80), 0, 0)
			ombro.add_child(lam)
			K.inst(lam, K.tubo(PackedVector3Array([Vector3(0, -0.1, 0), Vector3(0, 0.05, 0)]), PackedFloat32Array([0.025, 0.025]), 5), K.mat("couro"))
			K.inst(lam, K.bloco(Vector3(0.04, 0.6, 0.16), 3, 0.02), K.mat("metal_ferrugem"), Vector3(0, 0.36, 0.03))
	for s in [-1.0, 1.0]:
		var perna := _j(_modelo, "perna%d" % int(s), Vector3(0.12 * s, 0.6, 0))
		K.inst(perna, K.tubo(PackedVector3Array([Vector3.ZERO, Vector3(0, -0.28, 0.06), Vector3(0, -0.56, -0.02)]),
			PackedFloat32Array([0.085, 0.06, 0.05]), 7), pele)
		K.inst(perna, K.rocha(0.08, 11, 0.5, 0.2), pele, Vector3(0, -0.58, 0.06), Vector3.ZERO, Vector3(1, 1, 1.6))


## Gosma toxica: massa translucida verde com nucleo magenta e olhos.
func _construir_gosma() -> void:
	var corpo := _j(_modelo, "corpo", Vector3(0, 0.0, 0))
	K.inst(corpo, K.torno([Vector2(0.0, 0.0), Vector2(0.02, 0.5), Vector2(0.2, 0.62), Vector2(0.45, 0.55),
		Vector2(0.7, 0.35), Vector2(0.85, 0.0)], 14, 1.0, 1.0, 0.12, 8), _m("gosma"))
	K.inst(corpo, K.rocha(0.2, 5, 1.0, 0.3), K.mat("nucleo"), Vector3(0, 0.35, 0))
	for s in [-1.0, 1.0]:
		K.inst(corpo, K.rocha(0.075, 2, 1.0, 0.05), K.mat("olho_corrupto"), Vector3(0.17 * s, 0.6, 0.38))
	for i in 5:
		var a := TAU * i / 5.0
		K.inst(corpo, K.rocha(0.08, 3 + i, 1.0, 0.3), _mats[0], Vector3(cos(a) * 0.6, 0.06, sin(a) * 0.6))


## Bruto (elite): corpo enorme, chifres, armadura de casca, maca de raiz e pedra.
func _construir_bruto() -> void:
	var pele := _m("pele_bruto")
	var corpo := _j(_modelo, "corpo", Vector3(0, 1.15, 0))
	K.inst(corpo, K.torno([Vector2(-0.15, 0.38), Vector2(0.2, 0.5), Vector2(0.55, 0.62), Vector2(0.85, 0.52),
		Vector2(1.0, 0.25)], 12, 1.1, 0.85, 0.15, 4), pele, Vector3.ZERO, Vector3(0.35, 0, 0))
	K.inst(corpo, K.rocha(0.55, 12, 0.7, 0.35), K.mat("casca"), Vector3(0, 0.7, -0.2), Vector3.ZERO, Vector3(1.2, 1, 1))
	var cab := _j(corpo, "cabeca", Vector3(0, 0.95, 0.35))
	K.inst(cab, K.rocha(0.3, 7, 0.95, 0.2), pele, Vector3.ZERO, Vector3.ZERO, Vector3(1, 0.9, 1.1))
	K.inst(cab, K.rocha(0.22, 9, 0.6, 0.15), pele, Vector3(0, -0.18, 0.12), Vector3.ZERO, Vector3(1.2, 1, 1))
	for s in [-1.0, 1.0]:
		var ch := K.curva(PackedVector3Array([Vector3(0.18 * s, 0.15, 0), Vector3(0.45 * s, 0.35, -0.1),
			Vector3(0.55 * s, 0.7, -0.3), Vector3(0.45 * s, 0.95, -0.15)]), 3)
		K.inst(cab, K.tubo(ch, K.afunilar(ch.size(), 0.09, 0.0), 6), K.mat("pedra_sagrada"))
		K.inst(cab, K.rocha(0.05, 2, 1.0, 0.0), K.mat("olho_corrupto"), Vector3(0.11 * s, 0.04, 0.26))
		var ombro := _j(corpo, "ombro%d" % int(s), Vector3(0.62 * s, 0.75, 0.15))
		K.inst(ombro, K.rocha(0.3, 14, 0.8, 0.3), K.mat("casca"), Vector3(0.05 * s, 0.1, 0))
		K.inst(ombro, K.tubo(PackedVector3Array([Vector3.ZERO, Vector3(0.1 * s, -0.45, 0.05), Vector3(0.08 * s, -0.95, 0.15)]),
			PackedFloat32Array([0.19, 0.15, 0.14]), 8), pele)
		K.inst(ombro, K.rocha(0.17, 6, 1.0, 0.25), pele, Vector3(0.08 * s, -1.0, 0.15))
		if s < 0.0:
			var maca := Node3D.new()
			maca.position = Vector3(0.08 * s, -1.0, 0.2)
			maca.rotation = Vector3(deg_to_rad(70), 0, 0)
			ombro.add_child(maca)
			var cabo := K.curva(PackedVector3Array([Vector3(0, -0.2, 0), Vector3(0.05, 0.5, 0), Vector3(-0.03, 1.2, 0)]), 3)
			K.inst(maca, K.tubo(cabo, K.afunilar(cabo.size(), 0.07, 0.11), 7, 0.2), K.mat("casca"))
			K.inst(maca, K.rocha(0.38, 21, 1.0, 0.4), K.mat("pedra_sagrada"), Vector3(-0.03, 1.35, 0))
			Deco3D.corrupcao(maca, Vector3(0, 1.5, 0.1), 0.35, 4, false)
	for s in [-1.0, 1.0]:
		var perna := _j(_modelo, "perna%d" % int(s), Vector3(0.32 * s, 1.15, 0))
		K.inst(perna, K.tubo(PackedVector3Array([Vector3.ZERO, Vector3(0.05 * s, -0.55, 0.1), Vector3(0, -1.1, 0)]),
			PackedFloat32Array([0.25, 0.2, 0.17]), 8), pele)
		K.inst(perna, K.rocha(0.2, 4, 0.55, 0.2), pele, Vector3(0, -1.12, 0.1), Vector3.ZERO, Vector3(1, 1, 1.5))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.2, 0.6)
	l.light_energy = 1.0
	l.omni_range = 4.0
	l.position = Vector3(0, 2.2, 0.8)
	add_child(l)


## ---------------------------------------------------------------------------

func _koli() -> Node3D:
	if _koliani == null or not is_instance_valid(_koliani):
		_koliani = get_tree().get_first_node_in_group("koliani") as Node3D
	return _koliani


func _physics_process(dt: float) -> void:
	if morto:
		return
	_t += dt
	_fase += dt
	var k := _koli()
	if not is_on_floor():
		velocity.y -= 24.0 * dt
	else:
		velocity.y = maxf(velocity.y, -1.0)
	var dk := Vector3.INF
	if k and not bool(k.call("esta_morta")):
		dk = k.global_position - global_position
	var hv := Vector3(velocity.x, 0, velocity.z)
	var alvo_v := Vector3.ZERO
	if _stagger > 0.0:
		_stagger -= dt
		hv = hv.move_toward(Vector3.ZERO, 12.0 * dt)
		velocity.x = hv.x
		velocity.z = hv.z
		move_and_slide()
		_animar(dt, 0.0)
		return
	match _estado:
		"patrulha":
			if dk != Vector3.INF and Vector2(dk.x, dk.z).length() < float(_d["detecao"]) and absf(dk.y) < 3.5:
				_estado = "perseguir"
			else:
				var p := _alvo_patrulha - global_position
				p.y = 0.0
				if p.length() < 0.4 or _t > 4.0:
					_t = 0.0
					var a := randf() * TAU
					_alvo_patrulha = casa + Vector3(cos(a), 0, sin(a)) * randf() * raio_patrulha
				else:
					alvo_v = p.normalized() * float(_d["vel"]) * 0.4
		"perseguir":
			if dk == Vector3.INF or Vector2(dk.x, dk.z).length() > float(_d["detecao"]) * 1.6 or absf(dk.y) > 5.0:
				_estado = "patrulha"
			else:
				var h := Vector3(dk.x, 0, dk.z)
				if h.length() < float(_d["alcance"]) * 0.85 and absf(dk.y) < 1.8:
					_iniciar_ataque(k)
				else:
					alvo_v = h.normalized() * float(_d["vel"])
		"ante":
			if _t >= float(_d["ante"]):
				_estado = "golpe"
				_t = 0.0
				_acertou = false
				_executar_golpe(k)
		"golpe":
			if tipo == "gosma":
				if is_on_floor() and _t > 0.1:
					_aterrar_gosma(k)
			elif not _acertou:
				_acertou = true
				_testar_golpe(k)
			if _t >= float(_d["golpe"]):
				_estado = "rec"
				_t = 0.0
				_aviso.visible = false
		"rec":
			if _t >= float(_d["rec"]):
				_estado = "perseguir"
				_t = 0.0
	# nao cair das plataformas: sonda o chao a frente
	if alvo_v.length() > 0.05 and is_on_floor():
		var frente := global_position + alvo_v.normalized() * (raio_corpo + 0.45) + Vector3.UP * 0.5
		var q := PhysicsRayQueryParameters3D.create(frente, frente + Vector3.DOWN * 2.2, 1)
		if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			alvo_v = Vector3.ZERO
	if _estado != "golpe" or tipo != "gosma":
		hv = hv.move_toward(alvo_v, 20.0 * dt)
		velocity.x = hv.x
		velocity.z = hv.z
	if alvo_v.length() > 0.1:
		_rumo = rotate_toward(_rumo, atan2(alvo_v.x, alvo_v.z), 8.0 * dt)
	elif dk != Vector3.INF and _estado in ["ante", "perseguir"]:
		_rumo = rotate_toward(_rumo, atan2(dk.x, dk.z), 6.0 * dt)
	_modelo.rotation.y = _rumo
	move_and_slide()
	# contacto com a gosma/bruto magoa (corpo)
	if dk != Vector3.INF and tipo != "goblin" and Vector3(dk.x, 0, dk.z).length() < raio_corpo + 0.35 \
			and dk.y > -0.5 and dk.y < float(_d["altura"]):
		k.call("receber_dano", int(float(_d["dano"]) * 0.5), global_position, 5.0)
	_animar(dt, hv.length())


func _iniciar_ataque(k: Node3D) -> void:
	_estado = "ante"
	_t = 0.0
	_voz("ataque")
	if tipo != "goblin":
		var alvo := k.global_position if tipo == "gosma" else global_position + Vector3(sin(_rumo), 0, cos(_rumo)) * 1.6
		_salto_alvo = alvo
		_aviso.visible = true
		_aviso.global_position = _chao_em(alvo) + Vector3.UP * 0.06
		var r := 1.3 if tipo == "gosma" else 2.4
		_aviso.scale = Vector3(r, 1, r)


func _chao_em(p: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.0, p + Vector3.DOWN * 4.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() else p


func _executar_golpe(k: Node3D) -> void:
	if tipo == "gosma":
		var d := _salto_alvo - global_position
		d.y = 0.0
		var t_voo := 0.55
		velocity = d / t_voo
		velocity.y = 24.0 * t_voo * 0.5
		return
	if tipo == "bruto":
		VFX.poeira(get_parent(), _aviso.global_position, 1.6)
		var cam := get_viewport().get_camera_3d()
		if cam and cam.has_method("abanar"):
			cam.abanar(0.25)
	var frente := Vector3(sin(_rumo), 0, cos(_rumo))
	velocity += frente * (4.0 if tipo == "goblin" else 1.0)


func _testar_golpe(k: Node3D) -> void:
	if k == null:
		return
	var c := global_position + Vector3(sin(_rumo), 0, cos(_rumo)) * float(_d["alcance"]) * 0.55
	if tipo == "bruto":
		c = _aviso.global_position
	var d := k.global_position - c
	var raio := float(_d["alcance"]) * 0.75 if tipo == "goblin" else 2.4
	if Vector2(d.x, d.z).length() < raio and absf(d.y) < 1.5:
		k.call("receber_dano", int(_d["dano"]), global_position, 7.0 if tipo == "bruto" else 5.5)


func _aterrar_gosma(k: Node3D) -> void:
	_acertou = true
	VFX.poeira(get_parent(), global_position, 1.0)
	if k:
		var d := k.global_position - global_position
		if Vector2(d.x, d.z).length() < 1.5 and absf(d.y) < 1.2:
			k.call("receber_dano", int(_d["dano"]), global_position, 5.0)
	_estado = "rec"
	_t = 0.0
	_aviso.visible = false
	velocity.x = 0.0
	velocity.z = 0.0


func receber_dano(q: int, origem: Vector3 = Vector3.INF, recuo := 3.0, critico := false) -> void:
	if morto:
		return
	vida -= q
	for m in _mats:
		m.set_shader_parameter("flash", 1.0)
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		for m in _mats:
			m.set_shader_parameter("flash", 0.0))
	if origem != Vector3.INF:
		var d := global_position - origem
		d.y = 0.0
		d = d.normalized()
		var r := recuo / float(_d["massa"])
		velocity = d * r + Vector3.UP * (2.0 if r > 3.0 else 0.5)
		_rumo = atan2(-d.x, -d.z)
	if tipo != "bruto" or critico:
		_stagger = 0.32 if not critico else 0.5
		if _estado in ["ante", "golpe"] and tipo != "bruto":
			_estado = "rec"
			_t = 0.0
			_aviso.visible = false
	if vida <= 0:
		_morrer()
	else:
		_voz("dano")
		if _estado == "patrulha":
			_estado = "perseguir"


func _voz(que: String) -> void:
	var fam: String = DemonioBase.FAMILIA_SOM.get(tipo if tipo != "bruto" else "ogro", _d["som"])
	Som.toca("mob_%s_%s" % [fam, que], float(DemonioBase.VOZ_VOLUME.get(que, -14.0)), 1.0, 0.04,
		float(DemonioBase.VOZ_COOLDOWN.get(que, 0.0)), "mob_%s_%d" % [que, get_instance_id()])


func _morrer() -> void:
	morto = true
	_voz("morte")
	_aviso.visible = false
	collision_layer = 0
	morreu_inimigo.emit()
	VFX.faisca(get_parent(), centro_golpe(), true, Color(1.0, 0.25, 0.7))
	var t := create_tween()
	t.tween_property(_modelo, "rotation:x", -PI * 0.45, 0.35).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(_modelo, "position:y", -0.2, 0.35)
	t.tween_interval(0.25)
	t.tween_property(_modelo, "scale", Vector3(1.2, 0.01, 1.2), 0.35)
	t.tween_callback(queue_free)


## Animacao procedural (andar/antecipacao/golpe) por juntas.
func _animar(dt: float, v: float) -> void:
	var c := _fase * (7.0 + v * 1.5)
	var andar := clampf(v / maxf(float(_d["vel"]), 0.1), 0.0, 1.0)
	var corpo: Node3D = _juntas.get("corpo")
	match tipo:
		"gosma":
			var sq := 1.0 + sin(_fase * 5.0) * 0.06
			if _estado == "ante":
				sq = 1.0 - 0.3 * clampf(_t / float(_d["ante"]), 0.0, 1.0)
			elif _estado == "golpe":
				sq = 1.25
			corpo.scale = Vector3(1.0 / sqrt(sq), sq, 1.0 / sqrt(sq))
		_:
			var pe: Node3D = _juntas.get("perna1")
			var pd: Node3D = _juntas.get("perna-1")
			if pe:
				pe.rotation.x = sin(c) * 0.7 * andar
				pd.rotation.x = -sin(c) * 0.7 * andar
			corpo.position.y = (0.62 if tipo == "goblin" else 1.15) + absf(sin(c)) * 0.05 * andar
			var od: Node3D = _juntas.get("ombro-1")
			var oe: Node3D = _juntas.get("ombro1")
			var bal := sin(c) * 0.5 * andar
			if oe:
				oe.rotation.x = -bal
			if od:
				match _estado:
					"ante":
						var k := clampf(_t / float(_d["ante"]), 0.0, 1.0)
						od.rotation = Vector3(-2.6 * k, 0, -0.3 * k)
						corpo.rotation.x = -0.25 * k
					"golpe":
						od.rotation = od.rotation.lerp(Vector3(0.6, 0, 0.2), clampf(dt * 25.0, 0, 1))
						corpo.rotation.x = lerpf(corpo.rotation.x, 0.45, clampf(dt * 20.0, 0, 1))
					_:
						od.rotation = od.rotation.lerp(Vector3(bal - 0.3, 0, 0), clampf(dt * 8.0, 0, 1))
						corpo.rotation.x = lerpf(corpo.rotation.x, 0.0, clampf(dt * 6.0, 0, 1))
	if _stagger > 0.0:
		_modelo.rotation.z = sin(_fase * 40.0) * 0.06
	else:
		_modelo.rotation.z = 0.0
	if _estado == "ante":
		_aviso.transparency = 0.5 - 0.5 * clampf(_t / float(_d["ante"]), 0.0, 1.0)
