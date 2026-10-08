class_name ChefeCoracao3D
extends Node3D
## Regiao I / N05 -- O CORACAO PUTREFACTO em 3D (boss regional, exame da
## Floresta Corrompida). Mesmo desenho do `chefe_coracao_putrefacto.gd` 2D:
##
##   PROTEGIDO -> MECANICA (sempre com aviso) -> EXPOSTO -> RECOVER -> ...
##
##   RAIZES  marcas no chao em volta da Koliani (1,5 s) -> raizes irrompem.
##   PULSO   o coracao incha e brilha -> onda rasteira em anel: salta-se por cima.
##   BROTOS  dois brotos crescem: golpea-los rebenta-os, abre o nucleo JA' e
##           alonga a janela 50 %. Ignora-los: o nucleo abre na mesma, mais tarde.
##   EXPOSTO a casca abre-se, o nucleo brilha, nao magoa por contacto: a espada
##           entra por inteiro. Fora da janela a casca deixa passar so' 5 %.
##   FASE 2 (< 50 %): o mesmo vocabulario encadeado (raizes+pulso, pulso duplo,
##           raizes+brotos), avisos ~15 % mais curtos, janela ~20 % mais curta,
##           2.a zona de raizes. Rugido de transicao.
##
## Contrato da HUD aprovada: grupo "chefes" + sinais `combate_iniciado`,
## `vida_mudou`, `derrotado` (a barra do chefe e o nome vem do catalogo).

signal derrotado
signal combate_iniciado(chefe: Node)
signal vida_mudou(atual: int, maximo: int)

const K := preload("res://scripts/r3d/kit3d.gd")
const D := preload("res://scripts/r3d/deco3d.gd")
const VFX := preload("res://scripts/r3d/vfx3d.gd")

const RESIST_CASCA := 0.05
const PADRAO_F1 := ["RAIZES", "PULSO", "BROTOS", "PULSO"]
const PADRAO_F2 := ["RAIZES+PULSO", "BROTOS", "PULSO+PULSO", "RAIZES+BROTOS"]

@export var vida_max := 1500
var vida := 1500
var morto := false
var raio_corpo := 2.9
var raio_arena := 16.0
var t_marcas := 1.5
var t_pulso_tel := 0.95
var t_brotos_espera := 1.7
var janela := 2.6
var vel_onda := 8.5
var dano_raiz := 18
var dano_pulso := 20
var dano_contacto := 12

var _fase := "dorme"
var _t := 0.0
var _f2 := false
var _seq: Array = []
var _passos: Array = []    ## sub-mecanicas do passo atual (ex.: RAIZES+PULSO)
var _dur_janela := 0.0
var _exposto := false
var _combate := false
var _ciclo := 0
var _koli: Node3D
var _coracao: Node3D
var _nucleo: MeshInstance3D
var _petalas: Array[Node3D] = []
var _mat_carne: ShaderMaterial
var _mat_casca: ShaderMaterial
var _luz: OmniLight3D
var _ondas: Array = []      ## [{mi, r, atingiu}]
var _marcas: Array = []     ## [{mi, t, pos, raio}]
var _brotos: Array = []
var _broto_rebentado := false
var _contacto_cd := 0.0
var _abertura := 0.0
var _pulsar := 0.0
var estatisticas := {"raizes": 0, "pulso": 0, "brotos": 0, "exposto": 0, "fase2": false}


func _ready() -> void:
	add_to_group("chefes")
	vida = vida_max
	_construir()
	Musica.preparar_boss()


func centro_golpe() -> Vector3:
	return _coracao.global_position


## O bot de QA so' ataca quando faz sentido (janela aberta).
func bot_pode_atacar() -> bool:
	return _exposto


func esta_exposto() -> bool:
	return _exposto


func fase2() -> bool:
	return _f2


## ---------------------------------------------------------------------------
## Modelo: o coracao encaixado no oco das raizes da arvore-mae corrompida
## ---------------------------------------------------------------------------

func _construir() -> void:
	_mat_carne = K.mat_unico("carne")
	_mat_casca = K.mat_unico("casca_morta")
	_mat_casca.set_shader_parameter("emissao", Color(1.0, 0.12, 0.55))
	_mat_casca.set_shader_parameter("emissao_veias", 1.6)
	_mat_casca.set_shader_parameter("pulso", 0.5)
	# raizes-mae a irradiar para a arena (visual) e a subir para a copa
	for i in 9:
		var a := TAU * i / 9.0 + 0.2
		var d := Vector3(cos(a), 0, sin(a))
		var pts := K.curva(PackedVector3Array([d * 1.5 + Vector3.UP * 2.5, d * 4.5 + Vector3.UP * 1.0,
			d * 9.0 + Vector3.UP * 0.1, d * (13.0 + (i % 3) * 2.0) + Vector3.DOWN * 0.6]), 4)
		K.inst(self, K.tubo(pts, K.afunilar(pts.size(), 1.2, 0.25), 9, 0.25, i), _mat_casca)
	for i in 5:
		var a := TAU * i / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		var pts := K.curva(PackedVector3Array([d * 1.4 + Vector3.UP * 4.5, d * 2.2 + Vector3.UP * 9.0,
			d * 1.5 + Vector3.UP * 16.0, d * 3.0 + Vector3.UP * 26.0]), 4)
		K.inst(self, K.tubo(pts, K.afunilar(pts.size(), 0.9, 1.6), 8, 0.25, i + 20), _mat_casca)
	# coracao
	_coracao = Node3D.new()
	_coracao.position = Vector3(0, 3.6, 0)
	add_child(_coracao)
	K.inst(_coracao, K.rocha(2.3, 13, 1.15, 0.22, 2), _mat_carne)
	# arterias a envolver
	for i in 6:
		var a := TAU * i / 6.0
		var pts := PackedVector3Array()
		for k in 7:
			var t := k / 6.0
			var aa := a + t * 1.6
			pts.append(Vector3(cos(aa) * 2.25, (t - 0.5) * 4.2, sin(aa) * 2.25) * (1.0 - absf(t - 0.5) * 0.35))
		K.inst(_coracao, K.tubo(pts, K.afunilar(pts.size(), 0.28, 0.12), 6), _mat_carne)
	# nucleo (aparece com a casca aberta)
	_nucleo = K.inst(_coracao, K.rocha(1.15, 5, 1.0, 0.2, 1), K.mat("nucleo"), Vector3(0, 0, 0.9))
	# casca: 6 petalas de casca corrompida, articuladas na base
	for i in 6:
		var a := TAU * i / 6.0
		var dobradica := Node3D.new()
		dobradica.position = Vector3(cos(a) * 1.4, -2.0, sin(a) * 1.4)
		dobradica.rotation.y = -a + PI * 0.5
		_coracao.add_child(dobradica)
		var pet := K.torno([Vector2(0.0, 0.9), Vector2(1.4, 1.25), Vector2(2.8, 1.05), Vector2(3.9, 0.55), Vector2(4.4, 0.0)],
			10, 1.0, 0.35, 0.15, i + 3)
		var mi := K.inst(dobradica, pet, _mat_casca, Vector3(0, 0, 0.55))
		mi.rotation.x = -0.32
		# espinhos na petala
		for k in 3:
			K.inst(dobradica, K.tubo(PackedVector3Array([Vector3(0, 1.0 + k * 1.1, 0.9), Vector3(0, 1.4 + k * 1.1, 1.8)]),
				PackedFloat32Array([0.16, 0.0]), 5), K.mat("corrupcao"))
		_petalas.append(dobradica)
	# olhos na casca
	for i in 3:
		var a := TAU * i / 3.0 + 0.5
		K.inst(_coracao, K.rocha(0.22, 2, 0.6, 0.05), K.mat("olho_corrupto"),
			Vector3(cos(a) * 2.35, 1.3 + 0.3 * i, sin(a) * 2.35), Vector3(0, -a, 0))
	_luz = OmniLight3D.new()
	_luz.light_color = Color(1.0, 0.2, 0.6)
	_luz.light_energy = 3.0
	_luz.omni_range = 18.0
	_luz.position = Vector3(0, 4.0, 2.5)
	add_child(_luz)
	VFX.esporos(self, Vector3(0, 5, 0), Vector3(6, 4, 6), Color(1.0, 0.3, 0.7, 0.9), 60)
	# corpo solido (nao se atravessa o coracao)
	var corpo := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 2.7
	cil.height = 8.0
	f.shape = cil
	f.position.y = 4.0
	corpo.add_child(f)
	add_child(corpo)


## ---------------------------------------------------------------------------

func _koliani() -> Node3D:
	if _koli == null or not is_instance_valid(_koli):
		_koli = get_tree().get_first_node_in_group("koliani") as Node3D
	return _koli


func provocar() -> void:
	if _combate or morto:
		return
	_combate = true
	Musica.boss()
	Som.toca("chefe_entrada", -8.0, 1.0, 0.0, 0.0, "", Som.Prioridade.ALTA)
	combate_iniciado.emit(self)
	vida_mudou.emit(vida, vida_max)
	_fase = "decide"
	_t = 0.0


func _process(dt: float) -> void:
	_pulsar += dt * (2.2 if not _f2 else 3.0)
	var bate := pow(maxf(sin(_pulsar * PI), 0.0), 6.0)
	var esc := 1.0 + bate * 0.05
	if _fase == "pulso_tel":
		esc += 0.12 * clampf(_t / _dur_tel(t_pulso_tel), 0.0, 1.0)
	if not morto:
		_coracao.scale = Vector3(esc, esc, esc)
	_luz.light_energy = 2.4 + bate * 2.0 + (4.0 if _exposto else 0.0)
	_mat_carne.set_shader_parameter("emissao_plana", 0.1 + bate * 0.6 + (0.8 if _fase == "pulso_tel" else 0.0))
	# casca abre/fecha
	var alvo := 1.0 if _exposto else 0.0
	if _fase == "recover":
		alvo = 0.55 + 0.45 * sin(_t * 40.0)
	_abertura = move_toward(_abertura, alvo, dt * 3.5)
	for i in _petalas.size():
		_petalas[i].rotation.x = lerpf(-0.05, 0.95, _abertura)
	_nucleo.visible = _abertura > 0.15
	_nucleo.scale = Vector3.ONE * (0.6 + 0.4 * _abertura) * (1.0 + bate * 0.1)


func _physics_process(dt: float) -> void:
	if morto:
		return
	var k := _koliani()
	if not _combate:
		if k and Vector2(k.global_position.x - global_position.x, k.global_position.z - global_position.z).length() < raio_arena - 2.0:
			provocar()
		return
	_t += dt
	_contacto_cd -= dt
	_atualizar_ondas(dt, k)
	_atualizar_marcas(dt, k)
	# contacto com o coracao fechado magoa
	if k and not _exposto and _contacto_cd <= 0.0:
		var d := k.global_position - global_position
		if Vector2(d.x, d.z).length() < 3.35 and d.y < 6.0:
			k.call("receber_dano", dano_contacto, global_position, 8.0)
			_contacto_cd = 0.8
	match _fase:
		"decide":
			if _t > (0.9 if not _f2 else 0.6):
				_proxima_mecanica()
		"raizes":
			if _t > _dur_tel(t_marcas) + 0.7:
				_continuar_passos()
		"pulso_tel":
			if _t > _dur_tel(t_pulso_tel):
				_lancar_onda()
				_fase = "pulso_onda"
				_t = 0.0
		"pulso_onda":
			if _t > 1.2:
				_continuar_passos()
		"brotos":
			if _broto_rebentado:
				_abrir(1.5)
			elif _t > _dur_tel(t_brotos_espera) + 0.6:
				_limpar_brotos()
				_abrir(0.7)
		"exposto":
			if _t > _dur_janela:
				_exposto = false
				_fase = "recover"
				_t = 0.0
		"recover":
			if _t > 0.4:
				_fase = "decide"
				_t = 0.0
		"rugido":
			if _t > 1.4:
				_fase = "decide"
				_t = 0.0


func _dur_tel(base: float) -> float:
	return base * (0.85 if _f2 else 1.0)


func _proxima_mecanica() -> void:
	if _seq.is_empty():
		_seq = (PADRAO_F2 if _f2 else PADRAO_F1).duplicate()
		_ciclo += 1
	var m: String = _seq.pop_front()
	_passos = m.split("+")
	_continuar_passos()


## Executa a proxima sub-mecanica; quando acabam, ou abre a janela (padrao
## sem brotos) ou volta a decidir.
func _continuar_passos() -> void:
	if _passos.is_empty():
		_abrir(1.0)
		return
	var p: String = _passos.pop_front()
	_t = 0.0
	match p:
		"RAIZES":
			_fase = "raizes"
			estatisticas["raizes"] += 1
			_marcar_raizes()
		"PULSO":
			_fase = "pulso_tel"
			estatisticas["pulso"] += 1
			Som.toca("chefe_entrada", -14.0, 1.4, 0.03)
		"BROTOS":
			_fase = "brotos"
			estatisticas["brotos"] += 1
			_broto_rebentado = false
			_crescer_brotos()


func _abrir(mult: float) -> void:
	_limpar_brotos()
	_passos.clear()
	_exposto = true
	_fase = "exposto"
	_t = 0.0
	estatisticas["exposto"] += 1
	_dur_janela = janela * mult * (0.8 if _f2 else 1.0)
	Som.toca("escudo_impacto", -10.0, 0.7, 0.02)
	VFX.faisca(get_parent(), _coracao.global_position + Vector3(0, 0, 2.0), true)


## --- RAIZES ---------------------------------------------------------------

func _marcar_raizes() -> void:
	var k := _koliani()
	if k == null:
		return
	var zonas := 2 if _f2 else 1
	for z in zonas:
		var base := k.global_position
		if z == 1:
			var a := randf() * TAU
			base = global_position + Vector3(cos(a), 0, sin(a)) * randf_range(7.0, 12.0)
		var n := 3
		for i in n:
			var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(1.8, 2.8)
			var p := base + off
			p.y = global_position.y
			var raio := 1.35
			var mi := K.inst(get_parent(), K.disco(raio, 28), K.mat_unico("vfx_aviso"), p + Vector3.UP * 0.06,
				Vector3.ZERO, Vector3.ONE, false)
			_marcas.append({"mi": mi, "t": 0.0, "pos": p, "raio": raio, "saiu": false})
	Som.toca("raiz_aviso", -12.0, 0.9, 0.04)


func _atualizar_marcas(dt: float, k: Node3D) -> void:
	for m in _marcas.duplicate():
		m["t"] += dt
		var mi: MeshInstance3D = m["mi"]
		var tel := _dur_tel(t_marcas)
		if not m["saiu"]:
			mi.transparency = 0.7 - 0.7 * clampf(m["t"] / tel, 0.0, 1.0)
			if m["t"] >= tel:
				m["saiu"] = true
				_irromper(m["pos"], m["raio"])
				Pecas3D.ferir_se_dentro(self, m["pos"], m["raio"] + 0.2, 1.8, dano_raiz, 6.0)
				mi.queue_free()
				_marcas.erase(m)


func _irromper(p: Vector3, raio: float) -> void:
	Som.toca("raiz_irrompe", -7.0, randf_range(0.92, 1.09))
	var n := Node3D.new()
	get_parent().add_child(n)
	n.global_position = p
	for i in 6:
		var a := TAU * i / 6.0
		var b := Vector3(cos(a), 0, sin(a)) * raio * randf_range(0.2, 0.75)
		var pts := K.curva(PackedVector3Array([b - Vector3.UP * 0.4, b + Vector3(0.1, 1.2, 0.05), b + Vector3(-0.05, 2.4, 0.1)]), 3)
		K.inst(n, K.tubo(pts, K.afunilar(pts.size(), 0.26, 0.0), 6, 0.2, i), _mat_casca if i % 2 else K.mat("corrupcao"))
	n.scale = Vector3(1, 0.01, 1)
	VFX.poeira(get_parent(), p, 1.4)
	var t := n.create_tween()
	t.tween_property(n, "scale", Vector3.ONE, 0.08)
	t.tween_interval(0.6)
	t.tween_property(n, "scale", Vector3(1, 0.01, 1), 0.3)
	t.tween_callback(n.queue_free)


## --- PULSO ----------------------------------------------------------------

func _lancar_onda() -> void:
	_lancar_anel(0.0)
	if _passos.size() > 0 and _passos[0] == "PULSO":
		_passos.pop_front()
		get_tree().create_timer(0.75, false).timeout.connect(func() -> void:
			if not morto:
				_lancar_anel(0.0))
	Som.toca("chefe_cai", -14.0, 1.6, 0.03)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("abanar"):
		cam.abanar(0.18)


func _lancar_anel(_r0: float) -> void:
	var mi := K.inst(get_parent(), K.anel(0.92, 1.0, 0.0, 64), K.mat("vfx_onda"), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	mi.global_position = global_position + Vector3.UP * 0.15
	# parede baixa visivel da onda
	var parede := K.inst(mi, K.tubo(PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0.75, 0)]), PackedFloat32Array([1.0, 1.0]), 48, 0.0, 0, 1.0, false),
		K.mat("vfx_magenta"), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	parede.transparency = 0.55
	_ondas.append({"mi": mi, "r": 3.0, "atingiu": false})


func _atualizar_ondas(dt: float, k: Node3D) -> void:
	for o in _ondas.duplicate():
		o["r"] += vel_onda * dt
		var mi: MeshInstance3D = o["mi"]
		var r: float = o["r"]
		mi.scale = Vector3(r, 1, r)
		if not o["atingiu"] and k:
			var d := k.global_position - global_position
			var dh := Vector2(d.x, d.z).length()
			if absf(dh - r) < 0.55 and d.y < 0.75:
				o["atingiu"] = true
				k.call("receber_dano", dano_pulso, global_position, 7.0)
		if r > raio_arena + 1.0:
			mi.queue_free()
			_ondas.erase(o)


## --- BROTOS ---------------------------------------------------------------

func _crescer_brotos() -> void:
	var k := _koliani()
	var base := 0.0
	if k:
		var d := k.global_position - global_position
		base = atan2(d.z, d.x)
	for i in 2:
		var a := base + (0.55 if i == 0 else -0.55)
		var p := global_position + Vector3(cos(a), 0, sin(a)) * 6.5
		var b := BrotoCoracao3D.new()
		b.chefe = self
		get_parent().add_child(b)
		b.global_position = p
		_brotos.append(b)
	Som.toca("raiz_aviso", -12.0, 1.3, 0.04)


func broto_rebentado() -> void:
	_broto_rebentado = true


func _limpar_brotos() -> void:
	for b in _brotos:
		if is_instance_valid(b):
			b.call("murchar")
	_brotos.clear()


## --- dano / fase / morte --------------------------------------------------

func receber_dano(q: int, origem: Vector3 = Vector3.INF, _recuo := 0.0, critico := false) -> void:
	if morto or not _combate:
		if not _combate and not morto:
			provocar()
		return
	var real := q if _exposto else maxi(1, int(round(q * RESIST_CASCA)))
	vida = maxi(vida - real, 0)
	vida_mudou.emit(vida, vida_max)
	_mat_carne.set_shader_parameter("flash", 0.8 if _exposto else 0.25)
	get_tree().create_timer(0.07).timeout.connect(func() -> void: _mat_carne.set_shader_parameter("flash", 0.0))
	if not _exposto:
		Som.toca("bloqueio", -10.0, 0.7, 0.02, 0.12, "chefe_casca")
	if vida <= 0:
		_morrer()
		return
	if not _f2 and vida <= vida_max / 2:
		_entrar_fase2()


func _entrar_fase2() -> void:
	_f2 = true
	estatisticas["fase2"] = true
	_exposto = false
	_seq.clear()
	_passos.clear()
	_limpar_brotos()
	_fase = "rugido"
	_t = 0.0
	Som.toca("chefe_entrada", -6.0, 0.75, 0.0, 0.0, "", Som.Prioridade.ALTA)
	_lancar_anel(0.0)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("abanar"):
		cam.abanar(0.4)
	_mat_casca.set_shader_parameter("emissao_veias", 3.0)


func _morrer() -> void:
	morto = true
	_exposto = false
	_limpar_brotos()
	for o in _ondas:
		(o["mi"] as Node).queue_free()
	_ondas.clear()
	for m in _marcas:
		(m["mi"] as Node).queue_free()
	_marcas.clear()
	remove_from_group("chefes")
	Som.toca("chefe_cai", -6.0, 1.0, 0.02, 0.0, "", Som.Prioridade.ALTA)
	get_tree().create_timer(0.45).timeout.connect(func() -> void:
		Som.toca("conquista", -6.0, 1.0, 0.01, 0.0, "", Som.Prioridade.ALTA))
	Musica.ambiente(EstadoJogo.indice_nivel)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("abanar"):
		cam.abanar(0.6)
	for i in 6:
		get_tree().create_timer(i * 0.18).timeout.connect(func() -> void:
			VFX.faisca(get_parent(), _coracao.global_position + Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2)), true))
	var t := create_tween()
	t.tween_property(_coracao, "scale", Vector3(0.55, 0.4, 0.55), 1.6).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(_luz, "light_energy", 0.3, 1.6)
	_mat_carne.set_shader_parameter("emissao_veias", 0.0)
	_mat_casca.set_shader_parameter("emissao_veias", 0.0)
	_mat_casca.set_shader_parameter("pulso", 0.0)
	derrotado.emit()


## Broto: alvo de golpe que abre o nucleo. Murcha sozinho se for ignorado.
class BrotoCoracao3D:
	extends Node3D
	var chefe: Node
	var morto := false
	var raio_corpo := 0.6
	var _mat: ShaderMaterial

	func _ready() -> void:
		add_to_group("alvos3d")
		_mat = Kit3D.mat_unico("carne")
		var caule := Kit3D.curva(PackedVector3Array([Vector3.ZERO, Vector3(0.1, 0.6, 0), Vector3(-0.05, 1.2, 0.05)]), 3)
		Kit3D.inst(self, Kit3D.tubo(caule, Kit3D.afunilar(caule.size(), 0.25, 0.15), 6), Kit3D.mat("casca_morta"))
		Kit3D.inst(self, Kit3D.rocha(0.55, 7, 1.2, 0.25), _mat, Vector3(0, 1.45, 0))
		Kit3D.inst(self, Kit3D.rocha(0.25, 3, 1.0, 0.1), Kit3D.mat("nucleo"), Vector3(0, 1.5, 0.35))
		scale = Vector3(0.01, 0.01, 0.01)
		create_tween().tween_property(self, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.3, 0.6)
		l.light_energy = 1.5
		l.omni_range = 3.5
		l.position = Vector3(0, 1.5, 0.5)
		add_child(l)

	func centro_golpe() -> Vector3:
		return global_position + Vector3.UP * 1.2

	func bot_pode_atacar() -> bool:
		return not morto

	func receber_dano(_q: int, _o: Vector3 = Vector3.INF, _r := 0.0, _c := false) -> void:
		if morto:
			return
		morto = true
		Som.toca("acerto_critico", -6.0, 0.8, 0.02)
		VFX.faisca(get_parent(), centro_golpe(), true)
		if chefe and is_instance_valid(chefe):
			chefe.call("broto_rebentado")
		queue_free()

	func murchar() -> void:
		if morto:
			return
		morto = true
		var t := create_tween()
		t.tween_property(self, "scale", Vector3(1, 0.01, 1), 0.3)
		t.tween_callback(queue_free)
