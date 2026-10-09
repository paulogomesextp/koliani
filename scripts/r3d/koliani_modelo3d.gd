class_name KolianiModelo3D
extends Node3D
## Koliani 3D -- modelo + rig + animacao procedural.
##
## Fonte visual: o Golden Set (assets/sprites/koliani_golden_set): cabelo negro
## muito comprido com pontas carmesim, cachecol/capeleta vermelha, corpete
## negro, saia escura com bainha vermelha, botas altas negras com tiras
## vermelhas, gema esmeralda no cinto, katana fina com gume magenta.
## Proporcoes adultas (~7,5 cabecas, 1,77 m). O modelo olha para +Z.
##
## A animacao e' feita por juntas (Node3D) com poses calculadas por estado;
## cabelo, cachecol e saia tem movimento secundario por mola.

const K := preload("res://scripts/r3d/kit3d.gd")

var anca: Node3D
var tronco: Node3D
var pescoco: Node3D
var cabeca: Node3D
var ombro_e: Node3D
var ombro_d: Node3D
var cotovelo_e: Node3D
var cotovelo_d: Node3D
var mao_d: Node3D
var coxa_e: Node3D
var coxa_d: Node3D
var joelho_e: Node3D
var joelho_d: Node3D
var pe_e: Node3D
var pe_d: Node3D
var espada: Node3D
var ponta_espada: Node3D
var base_espada: Node3D
var _cabelo: Array[Node3D] = []
var _cabelo2: Array[Node3D] = []
var _cauda: Array[Node3D] = []
var _saia: Node3D
var _mats_flash: Array[ShaderMaterial] = []

## estado da animacao (escrito pelo controlador)
var estado := "idle"
var vel_h := 0.0
var vel_y := 0.0
var fase_ataque := 0.0
var golpe := 0
var no_chao := true

var _t := 0.0
var _ciclo := 0.0
var _aterrar := 0.0
var _morte := 0.0
var _mola_cabelo := Vector2.ZERO
var _mola_vel := Vector2.ZERO
var _vel_ant := Vector3.ZERO
var _pos_ant := Vector3.ZERO


func _ready() -> void:
	_construir()


func _m(nome: String) -> Material:
	# materiais de corpo com flash proprio (dano)
	var m := K.mat_unico(nome) if nome in ["pele", "tecido_negro", "vermelho", "couro"] else null
	if m:
		_mats_flash.append(m)
		return m
	return K.mat(nome)


func _junta(pai: Node3D, nome: String, pos: Vector3) -> Node3D:
	var j := Node3D.new()
	j.name = nome
	j.position = pos
	pai.add_child(j)
	return j


func _construir() -> void:
	var m_pele := _m("pele")
	var m_negro := _m("tecido_negro")
	var m_verm := _m("vermelho")
	var m_couro := _m("couro")
	anca = _junta(self, "Anca", Vector3(0, 0.93, 0))
	tronco = _junta(anca, "Tronco", Vector3.ZERO)
	# corpete (negro) + peito/ombros (pele)
	K.inst(tronco, K.torno([Vector2(-0.02, 0.125), Vector2(0.08, 0.112), Vector2(0.18, 0.118),
		Vector2(0.28, 0.148), Vector2(0.37, 0.158), Vector2(0.4, 0.15)], 14, 1.0, 0.68), m_negro)
	K.inst(tronco, K.torno([Vector2(0.34, 0.15), Vector2(0.42, 0.17), Vector2(0.47, 0.16),
		Vector2(0.51, 0.1), Vector2(0.53, 0.05)], 14, 1.0, 0.62), m_pele)
	# fitas vermelhas do corpete
	for y in [0.3]:
		K.inst(tronco, K.torno([Vector2(y - 0.012, 0.0), Vector2(y - 0.01, 0.124 + y * 0.12),
			Vector2(y + 0.01, 0.124 + y * 0.12), Vector2(y + 0.012, 0.0)], 14, 1.0, 0.7), m_verm)
	# cinto + bolsa + gema
	K.inst(tronco, K.torno([Vector2(-0.05, 0.0), Vector2(-0.045, 0.135), Vector2(0.0, 0.135), Vector2(0.005, 0.0)],
		14, 1.0, 0.75), m_couro)
	K.inst(tronco, K.rocha(0.035, 3, 0.9, 0.15), K.mat("gema"), Vector3(0.05, -0.025, 0.1))
	K.inst(tronco, K.bloco(Vector3(0.07, 0.08, 0.04), 2, 0.01), m_couro, Vector3(-0.11, -0.06, 0.05), Vector3(0, 0.6, 0))
	# saia (gradiente para vermelho na bainha) -- pendurada da anca
	_saia = _junta(anca, "Saia", Vector3(0, -0.02, 0))
	K.inst(_saia, K.torno([Vector2(0.0, 0.135), Vector2(-0.06, 0.17), Vector2(-0.16, 0.235), Vector2(-0.24, 0.27)],
		16, 1.0, 0.82, 0.12, 4), K.mat("saia"))
	# pescoco + cabeca
	pescoco = _junta(tronco, "Pescoco", Vector3(0, 0.5, 0.005))
	K.inst(pescoco, K.torno([Vector2(-0.02, 0.052), Vector2(0.09, 0.047)], 10), m_pele)
	cabeca = _junta(pescoco, "Cabeca", Vector3(0, 0.075, 0.012))
	# cranio + maxilar afilado (cara de traco anime, nao chibi)
	K.inst(cabeca, K.torno([Vector2(0.0, 0.0), Vector2(0.012, 0.035), Vector2(0.045, 0.072), Vector2(0.09, 0.096),
		Vector2(0.15, 0.102), Vector2(0.2, 0.088), Vector2(0.235, 0.055), Vector2(0.25, 0.0)], 16, 0.86, 1.0), m_pele)
	# olhos amendoados escuros com reflexo carmesim, sobrancelhas, nariz, boca
	for s in [-1.0, 1.0]:
		K.inst(cabeca, K.rocha(1.0, 1, 1.0, 0.0), K.mat("olho"), Vector3(0.033 * s, 0.112, 0.083),
			Vector3(0, 0, 0.12 * s), Vector3(0.024, 0.013, 0.012))
		K.inst(cabeca, K.rocha(1.0, 2, 1.0, 0.0), K.mat("gume"), Vector3(0.037 * s, 0.116, 0.093),
			Vector3.ZERO, Vector3(0.005, 0.004, 0.003))
		K.inst(cabeca, K.bloco(Vector3(0.042, 0.006, 0.01), 1, 0.0), K.mat("cabelo"), Vector3(0.034 * s, 0.135, 0.088),
			Vector3(0, 0, -0.2 * s))
	K.inst(cabeca, K.rocha(0.012, 4, 1.4, 0.0), m_pele, Vector3(0, 0.085, 0.095))
	K.inst(cabeca, K.bloco(Vector3(0.022, 0.004, 0.006), 2, 0.0), K.mat("vermelho"), Vector3(0, 0.052, 0.082))
	# cabelo: calote negra + franja + madeixas longas em cadeia (mola)
	var m_cab := K.mat("cabelo")
	K.inst(cabeca, _calote(), m_cab)
	for i in 9:
		var x := lerpf(-0.085, 0.085, i / 8.0)
		var comp := 0.07 + 0.03 * ((i * 7) % 3)
		var pts := PackedVector3Array([Vector3(x * 0.5, 0.245, 0.04), Vector3(x * 0.95, 0.2, 0.098),
			Vector3(x * 1.1, 0.2 - comp, 0.104)])
		K.inst(cabeca, K.fita(pts, PackedFloat32Array([0.045, 0.04, 0.008]), Vector3.RIGHT, 0.3), m_cab)
	# mechas laterais a emoldurar a cara
	for s in [-1.0, 1.0]:
		var pts := K.curva(PackedVector3Array([Vector3(0.085 * s, 0.17, 0.05), Vector3(0.105 * s, 0.05, 0.06),
			Vector3(0.11 * s, -0.12, 0.05), Vector3(0.1 * s, -0.3, 0.03)]), 3)
		K.inst(cabeca, K.fita(pts, K.afunilar(pts.size(), 0.05, 0.01), Vector3(0, 0, 1), 0.2), m_cab)
	# madeixas longas: 3 grupos (esq/centro/dir), cada um em 2 elos
	for g in 3:
		var gx := (g - 1) * 0.06
		var piv := _junta(cabeca, "Cabelo%d" % g, Vector3(gx, 0.17, -0.09))
		var piv2 := _junta(piv, "Cabelo%db" % g, Vector3(gx * 0.5, -0.42, -0.06))
		for k in 3:
			var dx := (k - 1) * 0.035 + gx * 0.4
			var p1 := K.curva(PackedVector3Array([Vector3(dx * 0.5, 0.06, 0.04), Vector3(dx, -0.12, -0.04),
				Vector3(dx * 1.2 + gx * 0.3, -0.42, -0.06)]), 3)
			K.inst(piv, K.fita(p1, K.afunilar(p1.size(), 0.075, 0.065), Vector3.RIGHT, 0.25), m_cab)
			var comp := 0.55 + 0.1 * ((k + g) % 3)
			var p2 := K.curva(PackedVector3Array([Vector3(dx * 1.2 + gx * 0.3 - gx * 0.5, 0.0, 0.0),
				Vector3(dx * 1.4 + gx * 0.2, -comp * 0.5, -0.03), Vector3(dx * 1.7 + gx * 0.4, -comp, 0.02)]), 3)
			K.inst(piv2, K.fita(p2, K.afunilar(p2.size(), 0.065, 0.008, 0.8), Vector3.RIGHT, 0.2), K.mat("cabelo_pontas"))
		_cabelo.append(piv)
		_cabelo2.append(piv2)
	# capeleta/cachecol vermelho sobre os ombros + caudas
	var m_cach := K.mat("cachecol")
	K.inst(tronco, K.torno([Vector2(0.57, 0.058), Vector2(0.54, 0.085), Vector2(0.5, 0.15), Vector2(0.45, 0.205),
		Vector2(0.39, 0.235), Vector2(0.33, 0.25)], 18, 1.0, 0.74, 0.16, 9), m_cach)
	for s in [-1.0, 1.0]:
		var piv := _junta(tronco, "Cauda", Vector3(0.05 * s, 0.5, -0.1))
		var pts := K.curva(PackedVector3Array([Vector3.ZERO, Vector3(0.03 * s, -0.2, -0.08),
			Vector3(0.06 * s, -0.45, -0.12), Vector3(0.1 * s, -0.7, -0.1)]), 3)
		K.inst(piv, K.fita(pts, K.afunilar(pts.size(), 0.13, 0.05), Vector3.RIGHT, 0.15), m_cach)
		_cauda.append(piv)
	# bracos
	ombro_e = _junta(tronco, "OmbroE", Vector3(0.185, 0.44, -0.01))
	ombro_d = _junta(tronco, "OmbroD", Vector3(-0.185, 0.44, -0.01))
	for par in [[ombro_e, 1.0], [ombro_d, -1.0]]:
		var o: Node3D = par[0]
		K.inst(o, K.tubo(PackedVector3Array([Vector3(0, 0.02, 0), Vector3(0, -0.13, 0), Vector3(0, -0.27, 0)]),
			PackedFloat32Array([0.046, 0.04, 0.035]), 9), m_pele)
		var cot := _junta(o, "Cotovelo", Vector3(0, -0.27, 0))
		K.inst(cot, K.tubo(PackedVector3Array([Vector3(0, 0.0, 0), Vector3(0, -0.12, 0), Vector3(0, -0.24, 0)]),
			PackedFloat32Array([0.038, 0.037, 0.03]), 9), m_negro)
		K.inst(cot, K.torno([Vector2(-0.2, 0.0), Vector2(-0.195, 0.042), Vector2(-0.16, 0.042), Vector2(-0.155, 0.0)], 9), m_verm)
		var mao := _junta(cot, "Mao", Vector3(0, -0.25, 0))
		K.inst(mao, K.rocha(0.042, 5, 1.1, 0.12), m_negro, Vector3(0, -0.02, 0.0))
		if par[1] > 0.0:
			cotovelo_e = cot
		else:
			cotovelo_d = cot
			mao_d = mao
	# pernas (botas altas negras com tiras vermelhas)
	coxa_e = _junta(anca, "CoxaE", Vector3(0.088, -0.03, 0))
	coxa_d = _junta(anca, "CoxaD", Vector3(-0.088, -0.03, 0))
	for c in [coxa_e, coxa_d]:
		K.inst(c, K.tubo(PackedVector3Array([Vector3(0, 0.02, 0), Vector3(0, -0.2, 0), Vector3(0, -0.42, 0)]),
			PackedFloat32Array([0.078, 0.066, 0.052]), 10), m_negro)
		K.inst(c, K.torno([Vector2(-0.1, 0.0), Vector2(-0.095, 0.076), Vector2(-0.07, 0.076), Vector2(-0.065, 0.0)], 10), m_verm)
		var j := _junta(c, "Joelho", Vector3(0, -0.42, 0))
		K.inst(j, K.tubo(PackedVector3Array([Vector3(0, 0.02, 0), Vector3(0, -0.15, -0.005), Vector3(0, -0.4, 0)]),
			PackedFloat32Array([0.058, 0.056, 0.047]), 10), m_negro)
		K.inst(j, K.rocha(0.05, 8, 0.9, 0.2), m_negro, Vector3(0, -0.01, 0.04))
		for y in [-0.3]:
			K.inst(j, K.torno([Vector2(y - 0.012, 0.0), Vector2(y - 0.01, 0.06), Vector2(y + 0.01, 0.06), Vector2(y + 0.012, 0.0)], 10), m_verm)
		var pe := _junta(j, "Pe", Vector3(0, -0.4, 0))
		K.inst(pe, K.tubo(PackedVector3Array([Vector3(0, 0.02, -0.04), Vector3(0, -0.02, 0.04), Vector3(0, -0.035, 0.13)]),
			PackedFloat32Array([0.05, 0.046, 0.03]), 9, 0.0, 0, 0.65), m_negro)
		K.inst(pe, K.bloco(Vector3(0.08, 0.025, 0.2), 4, 0.004), m_couro, Vector3(0, -0.055, 0.035))
		if c == coxa_e:
			joelho_e = j
			pe_e = pe
		else:
			joelho_d = j
			pe_d = pe
	_construir_espada()


## Calote do cabelo: esfera com a CARA aberta (triangulos da frente-baixo
## removidos), para o cabelo cobrir cranio e nuca sem tapar o rosto.
func _calote() -> ArrayMesh:
	var e := SphereMesh.new()
	e.radius = 0.122
	e.height = 0.25
	e.radial_segments = 18
	e.rings = 10
	var arr := e.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var off := Vector3(0, 0.132, -0.016)
	for i in range(0, idx.size(), 3):
		var c := (v[idx[i]] + v[idx[i + 1]] + v[idx[i + 2]]) / 3.0
		if c.z > 0.03 and c.y < 0.05:
			continue  # rosto
		if c.y < -0.07 and c.z > -0.02:
			continue  # queixo/maxilar
		for k in 3:
			var p := v[idx[i + k]]
			p.x *= 1.02
			st.set_uv(Vector2(0.5, clampf(0.5 - p.y * 2.0, 0.0, 1.0)))
			st.add_vertex(p + off)
	st.generate_normals()
	return st.commit()


func _construir_espada() -> void:
	espada = _junta(mao_d, "Espada", Vector3(0, -0.035, 0.0))
	espada.rotation = Vector3(deg_to_rad(100), 0, 0)
	# punho envolto em vermelho + guarda + lamina curva com gume magenta
	var m_l := K.mat("lamina")
	K.inst(espada, K.tubo(PackedVector3Array([Vector3(0, -0.11, 0), Vector3(0, 0.08, 0)]),
		PackedFloat32Array([0.017, 0.017]), 6), K.mat("vermelho"))
	K.inst(espada, K.torno([Vector2(0.075, 0.0), Vector2(0.08, 0.05), Vector2(0.095, 0.05), Vector2(0.1, 0.0)], 8, 1.0, 0.6),
		K.mat("metal"))
	var pts := PackedVector3Array()
	var rs := PackedFloat32Array()
	for i in 9:
		var t := i / 8.0
		pts.append(Vector3(0, 0.1 + t * 0.85, -0.05 * t * t))
		rs.append(lerpf(0.024, 0.004, pow(t, 3.0)))
	K.inst(espada, K.tubo(pts, rs, 4, 0.0, 0, 0.22), m_l)
	var gume := PackedVector3Array()
	var gr := PackedFloat32Array()
	for i in 9:
		var t := i / 8.0
		gume.append(Vector3(0, 0.1 + t * 0.85, -0.05 * t * t + lerpf(0.022, 0.003, pow(t, 3.0))))
		gr.append(lerpf(0.005, 0.002, t))
	K.inst(espada, K.tubo(gume, gr, 4), K.mat("gume"), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	base_espada = _junta(espada, "Base", Vector3(0, 0.15, 0))
	ponta_espada = _junta(espada, "Ponta", Vector3(0, 0.95, -0.05))


## Flash branco de dano no corpo.
func flash(v: float) -> void:
	for m in _mats_flash:
		m.set_shader_parameter("flash", v)


## ---------------------------------------------------------------------------
## Animacao
## ---------------------------------------------------------------------------

func _process(dt: float) -> void:
	_t += dt
	var alvo := {}
	match estado:
		"idle": _pose_idle(alvo)
		"run": _pose_corrida(alvo, dt)
		"jump", "fall": _pose_ar(alvo)
		"attack": _pose_ataque(alvo)
		"hurt": _pose_dano(alvo)
		"death": _pose_morte(alvo, dt)
		"dash": _pose_dash(alvo)
		_: _pose_idle(alvo)
	if _aterrar > 0.0:
		_aterrar -= dt
		var k := clampf(_aterrar / 0.16, 0.0, 1.0)
		alvo["anca_y"] = alvo.get("anca_y", 0.0) - 0.12 * k
		alvo["coxa_e"] = alvo.get("coxa_e", Vector3.ZERO) + Vector3(-0.5 * k, 0, 0)
		alvo["coxa_d"] = alvo.get("coxa_d", Vector3.ZERO) + Vector3(-0.5 * k, 0, 0)
		alvo["joelho_e"] = alvo.get("joelho_e", Vector3.ZERO) + Vector3(0.9 * k, 0, 0)
		alvo["joelho_d"] = alvo.get("joelho_d", Vector3.ZERO) + Vector3(0.9 * k, 0, 0)
		alvo["tronco"] = alvo.get("tronco", Vector3.ZERO) + Vector3(0.25 * k, 0, 0)
	var rapido := 30.0 if estado in ["attack", "hurt"] else 16.0
	var a := clampf(rapido * dt, 0.0, 1.0)
	anca.position.y = lerpf(anca.position.y, 0.93 + float(alvo.get("anca_y", 0.0)), a)
	anca.rotation = anca.rotation.lerp(alvo.get("anca", Vector3.ZERO), a)
	tronco.rotation = tronco.rotation.lerp(alvo.get("tronco", Vector3.ZERO), a)
	cabeca.rotation = cabeca.rotation.lerp(alvo.get("cabeca", Vector3.ZERO), a)
	ombro_e.rotation = ombro_e.rotation.lerp(alvo.get("ombro_e", Vector3.ZERO), a)
	ombro_d.rotation = ombro_d.rotation.lerp(alvo.get("ombro_d", Vector3.ZERO), a)
	cotovelo_e.rotation = cotovelo_e.rotation.lerp(alvo.get("cotovelo_e", Vector3.ZERO), a)
	cotovelo_d.rotation = cotovelo_d.rotation.lerp(alvo.get("cotovelo_d", Vector3.ZERO), a)
	mao_d.rotation = mao_d.rotation.lerp(alvo.get("mao_d", Vector3.ZERO), a)
	coxa_e.rotation = coxa_e.rotation.lerp(alvo.get("coxa_e", Vector3.ZERO), a)
	coxa_d.rotation = coxa_d.rotation.lerp(alvo.get("coxa_d", Vector3.ZERO), a)
	joelho_e.rotation = joelho_e.rotation.lerp(alvo.get("joelho_e", Vector3.ZERO), a)
	joelho_d.rotation = joelho_d.rotation.lerp(alvo.get("joelho_d", Vector3.ZERO), a)
	pe_e.rotation = pe_e.rotation.lerp(alvo.get("pe_e", Vector3.ZERO), a)
	pe_d.rotation = pe_d.rotation.lerp(alvo.get("pe_d", Vector3.ZERO), a)
	_secundario(dt)


func aterrou(forca: float) -> void:
	_aterrar = 0.16 * clampf(forca, 0.4, 1.0)


func reiniciar_morte() -> void:
	_morte = 0.0


func _pose_idle(a: Dictionary) -> void:
	var r := sin(_t * 2.2)
	a["anca_y"] = -0.03 + r * 0.008
	a["tronco"] = Vector3(0.04 + r * 0.015, 0.25, 0)
	a["anca"] = Vector3(0, -0.2, 0)
	a["cabeca"] = Vector3(0.05, -0.15, 0)
	a["ombro_e"] = Vector3(0.05, 0, 0.12 + r * 0.02)
	a["cotovelo_e"] = Vector3(-0.25, 0, 0)
	a["ombro_d"] = Vector3(-0.25, 0.1, -0.22)
	a["cotovelo_d"] = Vector3(-0.55, 0, 0)
	a["mao_d"] = Vector3(1.35, 0, 0.25)
	a["coxa_e"] = Vector3(-0.12, 0, 0.06)
	a["joelho_e"] = Vector3(0.22, 0, 0)
	a["pe_e"] = Vector3(-0.08, 0, 0)
	a["coxa_d"] = Vector3(0.1, 0, -0.08)
	a["joelho_d"] = Vector3(0.12, 0, 0)
	a["pe_d"] = Vector3(-0.02, 0, 0)


func _pose_corrida(a: Dictionary, dt: float) -> void:
	var v := clampf(vel_h / 6.5, 0.0, 1.2)
	_ciclo += dt * (6.0 + 6.0 * v) * 0.5
	var c := _ciclo * TAU * 0.5
	var s := sin(c)
	var s2 := sin(c * 2.0)
	a["anca_y"] = -0.04 - absf(s2) * 0.0 + s2 * 0.035 * v
	a["anca"] = Vector3(0, s * 0.18 * v, 0)
	a["tronco"] = Vector3(0.28 * v, -s * 0.22 * v, 0)
	a["cabeca"] = Vector3(-0.18 * v, s * 0.12 * v, 0)
	a["coxa_e"] = Vector3(-s * 0.95 * v, 0, 0.03)
	a["coxa_d"] = Vector3(s * 0.95 * v, 0, -0.03)
	a["joelho_e"] = Vector3((0.4 + 0.9 * maxf(-cos(c), 0.0) + 0.2) * v, 0, 0)
	a["joelho_d"] = Vector3((0.4 + 0.9 * maxf(cos(c), 0.0) + 0.2) * v, 0, 0)
	a["pe_e"] = Vector3(-0.2 * v, 0, 0)
	a["pe_d"] = Vector3(-0.2 * v, 0, 0)
	a["ombro_e"] = Vector3(s * 0.8 * v, 0, 0.15)
	a["cotovelo_e"] = Vector3(-1.1 * v, 0, 0)
	# braco da espada mais contido: lamina para tras, baixa
	a["ombro_d"] = Vector3(0.45 * v - s * 0.3 * v, 0.1, -0.3)
	a["cotovelo_d"] = Vector3(-0.5, 0, 0)
	a["mao_d"] = Vector3(1.3, 0, 0.3)


func _pose_ar(a: Dictionary) -> void:
	var sobe := clampf(vel_y / 8.0, -1.0, 1.0)
	a["anca_y"] = 0.0
	a["tronco"] = Vector3(0.12 - sobe * 0.1, 0, 0)
	a["cabeca"] = Vector3(-0.1, 0, 0)
	if sobe > 0.0:
		a["coxa_e"] = Vector3(-1.1, 0, 0.05)
		a["joelho_e"] = Vector3(1.6, 0, 0)
		a["coxa_d"] = Vector3(-0.2, 0, -0.05)
		a["joelho_d"] = Vector3(0.9, 0, 0)
		a["ombro_e"] = Vector3(-1.4, 0, 0.3)
		a["cotovelo_e"] = Vector3(-0.6, 0, 0)
	else:
		a["coxa_e"] = Vector3(-0.5, 0, 0.12)
		a["joelho_e"] = Vector3(0.7, 0, 0)
		a["coxa_d"] = Vector3(0.15, 0, -0.12)
		a["joelho_d"] = Vector3(0.45, 0, 0)
		a["ombro_e"] = Vector3(-0.4, 0, 0.9)
		a["cotovelo_e"] = Vector3(-0.4, 0, 0)
	a["pe_e"] = Vector3(0.3, 0, 0)
	a["pe_d"] = Vector3(0.3, 0, 0)
	a["ombro_d"] = Vector3(0.3, 0, -0.7)
	a["cotovelo_d"] = Vector3(-0.4, 0, 0)
	a["mao_d"] = Vector3(0.6, 0, 0.2)


## 4 golpes distintos: corte horizontal, revesso, diagonal descendente, giro pesado.
## fase 0..1: antecipacao (0-0.25) -> golpe (0.25-0.6) -> recuperacao.
func _pose_ataque(a: Dictionary) -> void:
	var f := fase_ataque
	var ante := clampf(f / 0.25, 0.0, 1.0)
	var golp := clampf((f - 0.22) / 0.35, 0.0, 1.0)
	golp = 1.0 - pow(1.0 - golp, 3.0)
	a["anca_y"] = -0.1
	a["coxa_e"] = Vector3(-0.7, 0, 0.12)
	a["joelho_e"] = Vector3(0.75, 0, 0)
	a["coxa_d"] = Vector3(0.45, 0, -0.15)
	a["joelho_d"] = Vector3(0.35, 0, 0)
	a["pe_e"] = Vector3(-0.05, 0, 0)
	a["pe_d"] = Vector3(0.15, 0, 0)
	a["ombro_e"] = Vector3(-0.3, 0, 0.5)
	a["cotovelo_e"] = Vector3(-0.9, 0, 0)
	match golpe:
		0:
			# da direita para a esquerda, a altura do peito
			var tw := lerpf(lerpf(0.0, 0.9, ante), -1.0, golp)
			a["anca"] = Vector3(0, tw * 0.4, 0)
			a["tronco"] = Vector3(0.12, tw * 0.6, 0)
			a["ombro_d"] = Vector3(-1.45, lerpf(0.7, -0.6, golp), -0.25)
			a["cotovelo_d"] = Vector3(lerpf(-0.8, -0.1, golp), 0, 0)
			a["mao_d"] = Vector3(1.3, 0, lerpf(0.4, -0.2, golp))
		1:
			# revesso: da esquerda para a direita, mais baixo
			var tw := lerpf(lerpf(0.0, -0.9, ante), 1.0, golp)
			a["anca"] = Vector3(0, tw * 0.4, 0)
			a["tronco"] = Vector3(0.18, tw * 0.6, 0)
			a["ombro_d"] = Vector3(-1.3, lerpf(-0.9, 0.7, golp), 0.35)
			a["cotovelo_d"] = Vector3(lerpf(-1.4, -0.15, golp), 0, 0)
			a["mao_d"] = Vector3(1.4, 0, lerpf(-0.3, 0.5, golp))
		2:
			# diagonal de cima para baixo
			a["tronco"] = Vector3(lerpf(lerpf(0.0, -0.3, ante), 0.45, golp), lerpf(0.3, -0.3, golp), 0)
			a["anca"] = Vector3(0, lerpf(0.2, -0.3, golp), 0)
			a["ombro_d"] = Vector3(lerpf(lerpf(-1.0, -2.8, ante), -0.5, golp), 0.2, lerpf(-0.5, 0.2, golp))
			a["cotovelo_d"] = Vector3(lerpf(-1.2, -0.1, golp), 0, 0)
			a["mao_d"] = Vector3(lerpf(0.4, 1.2, golp), 0, 0)
			a["anca_y"] = -0.1 - 0.08 * golp
		_:
			# giro pesado (remate): o corpo inteiro roda
			var tw := lerpf(lerpf(0.0, 1.1, ante), -TAU * 0.55, golp)
			a["anca"] = Vector3(0, tw * 0.55, 0)
			a["tronco"] = Vector3(0.22, tw * 0.45, 0)
			a["ombro_d"] = Vector3(-1.55, -0.2, -0.35)
			a["cotovelo_d"] = Vector3(-0.1, 0, 0)
			a["mao_d"] = Vector3(1.5, 0, 0.0)
			a["anca_y"] = -0.16


func _pose_dano(a: Dictionary) -> void:
	a["tronco"] = Vector3(-0.45, 0.2, 0.1)
	a["cabeca"] = Vector3(-0.3, 0, 0)
	a["anca_y"] = -0.06
	a["ombro_e"] = Vector3(-0.6, 0, 0.8)
	a["ombro_d"] = Vector3(-0.3, 0, -0.9)
	a["cotovelo_e"] = Vector3(-0.8, 0, 0)
	a["coxa_e"] = Vector3(-0.3, 0, 0.1)
	a["joelho_e"] = Vector3(0.5, 0, 0)
	a["coxa_d"] = Vector3(0.3, 0, 0)


func _pose_morte(a: Dictionary, dt: float) -> void:
	_morte = minf(_morte + dt, 1.2)
	var k := clampf(_morte / 0.45, 0.0, 1.0)
	var q := clampf((_morte - 0.45) / 0.5, 0.0, 1.0)
	a["anca_y"] = lerpf(-0.0, -0.45, k) - 0.25 * q
	a["coxa_e"] = Vector3(lerpf(0.0, -1.5, k), 0, 0.1)
	a["coxa_d"] = Vector3(lerpf(0.0, -1.3, k), 0, -0.1)
	a["joelho_e"] = Vector3(lerpf(0.0, 2.4, k), 0, 0)
	a["joelho_d"] = Vector3(lerpf(0.0, 2.4, k), 0, 0)
	a["tronco"] = Vector3(lerpf(0.3, 1.2, q), 0, 0.2 * q)
	a["cabeca"] = Vector3(0.6 * q, 0, 0)
	a["ombro_e"] = Vector3(-0.5, 0, 0.5)
	a["ombro_d"] = Vector3(-0.5, 0, -0.5)


func _pose_dash(a: Dictionary) -> void:
	a["anca_y"] = -0.25
	a["tronco"] = Vector3(0.9, 0, 0)
	a["cabeca"] = Vector3(-0.6, 0, 0)
	a["coxa_e"] = Vector3(-1.2, 0, 0.1)
	a["joelho_e"] = Vector3(1.4, 0, 0)
	a["coxa_d"] = Vector3(0.8, 0, -0.1)
	a["joelho_d"] = Vector3(0.6, 0, 0)
	a["ombro_e"] = Vector3(1.2, 0, 0.3)
	a["ombro_d"] = Vector3(1.0, 0, -0.3)
	a["mao_d"] = Vector3(1.0, 0, 0)


## Cabelo/cachecol: mola sobre a velocidade e a aceleracao do mundo.
func _secundario(dt: float) -> void:
	if dt <= 0.0:
		return
	var p := global_position
	var vel := (p - _pos_ant) / dt
	_pos_ant = p
	if vel.length() > 40.0:
		vel = Vector3.ZERO  # teleporte (respawn)
	var local := global_transform.basis.inverse() * vel
	var acel := (local - _vel_ant) / dt
	_vel_ant = local
	var alvo := Vector2(clampf(local.z * 0.11 - local.y * 0.04, -0.2, 1.1), clampf(-local.x * 0.08, -0.5, 0.5))
	alvo += Vector2(clampf(acel.z * 0.004, -0.3, 0.3), 0.0)
	alvo.x += sin(_t * 1.7) * 0.03
	var forca := (alvo - _mola_cabelo) * 90.0 - _mola_vel * 11.0
	_mola_vel += forca * dt
	_mola_cabelo += _mola_vel * dt
	for i in _cabelo.size():
		var d := (i - 1) * 0.12
		_cabelo[i].rotation = Vector3(_mola_cabelo.x * 0.55 + 0.08, 0, _mola_cabelo.y * 0.6 + d)
		_cabelo2[i].rotation = Vector3(_mola_cabelo.x * 0.6 + sin(_t * 3.0 + i) * 0.04 * (1.0 + local.length() * 0.1), 0, _mola_cabelo.y * 0.4)
	for i in _cauda.size():
		_cauda[i].rotation = Vector3(_mola_cabelo.x * 0.8 + 0.1 + sin(_t * 4.0 + i * 1.3) * 0.05 * (1.0 + local.length() * 0.15), 0, _mola_cabelo.y * 0.5)
	_saia.rotation = Vector3(clampf(-local.z * 0.02, -0.15, 0.1), 0, _mola_cabelo.y * 0.15)
