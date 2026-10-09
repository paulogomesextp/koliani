class_name Nivel3D
extends Node3D
## Base dos niveis 3D da Regiao I (N01-N05).
##
## Encaixa no fluxo EXISTENTE: `Main.tscn` (main.gd) carrega a cena deste nivel
## no lugar da cena 2D quando o indice e' 0..4 (ver `caminho_para`), e cola por
## cima a HUD, a Pausa e as transicoes aprovadas -- nada do front-end muda.
## A saida faz exatamente o que a `Porta` 2D faz (marcar concluido, sessao,
## avancar_nivel, voltar a Main.tscn).
##
## Cada nivel concreto (n0X_3d.gd) implementa `construir()` com a API abaixo.

const CENA_JOGO := "res://scenes/Main.tscn"
const IDS_PROGRESSAO := preload("res://scripts/progression_ids.gd")
const K := preload("res://scripts/r3d/kit3d.gd")
const D := preload("res://scripts/r3d/deco3d.gd")
const P := preload("res://scripts/r3d/pecas3d.gd")
const VFX := preload("res://scripts/r3d/vfx3d.gd")
const CENAS := [
	"res://scenes/r3d/N01_Floresta_Putrefata_3D.tscn",
	"res://scenes/r3d/N02_Pantano_dos_Sussurros_3D.tscn",
	"res://scenes/r3d/N03_Ninho_da_Viuva_Negra_3D.tscn",
	"res://scenes/r3d/N04_A_Arvore_que_Chora_3D.tscn",
	"res://scenes/r3d/N05_Coracao_da_Floresta_3D.tscn",
]

## checkpoint em memoria (sobrevive ao reload da morte, como a sessao 2D)
static var _cp := {}
## o bot de QA fecha sozinho os cartoes (vitoria)
static var qa_auto := false
## testes: concluir sem trocar de cena
static var trocar_cena := true

@export var indice := 0
@export var perfil := 0

var koliani: Koliani3D
var camara: CamaraR3D
var portal: Pecas3D.PortalSaida
var spawn := Vector3.ZERO
var spawn_rumo := 0.0
var y_morte := -12.0
var rota := PackedVector3Array()
var rota_bot: Array = []   ## [{p, salto, atacar}]
var lado_camara := 1.0
var terreno: Node3D
var deco: Node3D
var vivos: Node3D
var _folhagem: Array = []
var _concluido := false


static func ativo() -> bool:
	if "--2d" in OS.get_cmdline_user_args():
		return false
	return bool(ProjectSettings.get_setting("koliani/r3d/regiao1_3d", true))


static func caminho_para(indice_nivel: int, caminho_2d: String) -> String:
	if indice_nivel >= 0 and indice_nivel < CENAS.size() and ativo() and ResourceLoader.exists(CENAS[indice_nivel]):
		return CENAS[indice_nivel]
	return caminho_2d


static func guardar_checkpoint(id: String, pos: Vector3) -> void:
	_cp = {"nivel": EstadoJogo.indice_nivel, "id": id, "pos": pos}


static func limpar_checkpoint() -> void:
	_cp = {}


static func build_id() -> String:
	var c := "res://scripts/r3d/build_id.gd"
	if ResourceLoader.exists(c):
		var s := load(c) as GDScript
		if s:
			return str(s.get_script_constant_map().get("SHA", "dev"))
	return "dev"


func _ready() -> void:
	terreno = Node3D.new()
	terreno.name = "Terreno"
	add_child(terreno)
	deco = Node3D.new()
	deco.name = "Deco"
	add_child(deco)
	vivos = Node3D.new()
	vivos.name = "Vivos"
	add_child(vivos)
	seed(scene_file_path.hash())
	construir()
	Ambiente3D.montar(self, perfil)
	_criar_jogador()
	_etiqueta_build()
	print("KOLIANI 3D REGION I | build=%s | level=%d | scene=%s" % [build_id(), indice + 1, scene_file_path])
	_pos_construcao.call_deferred()


## Sobrepor nos niveis.
func construir() -> void:
	pass


## Chamado depois do 1.o frame de fisica (raios para pousar folhagem).
func depois_de_construir() -> void:
	pass


func _pos_construcao() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	for f in _folhagem:
		D.folhagem(deco, f[0], f[1], f[2], f[3], f[4], f[5])
	depois_de_construir()
	_fundir(deco)
	_fundir(terreno)


func _criar_jogador() -> void:
	var pos := spawn
	var rumo := spawn_rumo
	if not _cp.is_empty() and int(_cp.get("nivel", -1)) == EstadoJogo.indice_nivel:
		pos = _cp["pos"]
		for f in get_tree().get_nodes_in_group("fogueiras3d"):
			if f.get("id") == _cp["id"]:
				f.call("acender", false)
	elif not _cp.is_empty():
		limpar_checkpoint()
	koliani = Koliani3D.new()
	koliani.name = "Koliani"
	koliani.y_morte = y_morte
	add_child(koliani)
	koliani.global_position = pos
	koliani.set("_rumo", rumo)
	koliani.definir_seguro(pos)
	camara = CamaraR3D.new()
	camara.name = "Camara"
	camara.alvo = koliani
	camara.lado = lado_camara
	camara.definir_rota(rota)
	add_child(camara)
	koliani.camara = camara


func _etiqueta_build() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 3
	add_child(cl)
	var l := Label.new()
	l.text = "KOLIANI 3D REGION I  build=%s" % build_id()
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.38))
	l.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	l.position = Vector2(8, -20)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(l)
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.offset_top = -18
	l.offset_left = 8


## ---------------------------------------------------------------------------
## Conclusao (= Porta 2D)
## ---------------------------------------------------------------------------

func concluir() -> void:
	if _concluido:
		return
	_concluido = true
	Som.toca("transicao", -7.0)
	limpar_checkpoint()
	var i := EstadoJogo.indice_nivel
	EstadoJogo.marcar_nivel_concluido(i)
	EstadoJogo.completar_sessao_nivel(IDS_PROGRESSAO.level_id_do_indice(i))
	print("KOLIANI 3D | nivel %d concluido" % (i + 1))
	if EstadoJogo.ha_proximo_nivel():
		EstadoJogo.avancar_nivel()
		if trocar_cena:
			get_tree().change_scene_to_file(CENA_JOGO)


## ---------------------------------------------------------------------------
## API de construcao
## ---------------------------------------------------------------------------

func _contorno(rx: float, rz: float, rot: float, semente: int, n := 18, irregular := 0.16) -> PackedVector2Array:
	var c := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var k := 1.0 + irregular * K._ruido3(Vector3(cos(a) * 1.3, sin(a) * 1.3, semente * 0.77))
		c.append(Vector2(cos(a) * rx * k, sin(a) * rz * k).rotated(rot))
	return c


func chao(contorno: PackedVector2Array, centro: Vector3, esp := 3.0, mat := "terreno", semente := 0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = centro
	terreno.add_child(corpo)
	var malha := K.laje(contorno, esp, semente)
	K.inst(corpo, malha, K.mat(mat))
	var f := CollisionShape3D.new()
	var forma := malha.create_trimesh_shape()
	forma.backface_collision = true
	f.shape = forma
	corpo.add_child(f)
	return corpo


## Ilha eliptica irregular (topo plano a altura `c.y`).
func ilha(c: Vector3, rx: float, rz := -1.0, rot := 0.0, esp := 3.0, mat := "terreno", semente := 0) -> StaticBody3D:
	if rz < 0.0:
		rz = rx
	return chao(_contorno(rx, rz, rot, semente + int(c.x * 3.0 + c.z)), c, esp, mat, semente)


## Faixa plana (caminho) de `a` a `b` (altura de `a`), com pontas arredondadas.
func faixa(a: Vector3, b: Vector3, larg := 3.0, esp := 2.5, mat := "terreno", semente := 0) -> StaticBody3D:
	var d := Vector2(b.x - a.x, b.z - a.z)
	var l := d.length()
	var ang := d.angle()
	var c := PackedVector2Array()
	var n := 8
	var r := larg * 0.5
	for i in n + 1:
		var t := -PI * 0.5 + PI * i / n
		c.append(Vector2(l * 0.5 + cos(t) * r, sin(t) * r))
	for i in n + 1:
		var t := PI * 0.5 + PI * i / n
		c.append(Vector2(-l * 0.5 + cos(t) * r, sin(t) * r))
	# irregularidade nas margens
	for i in c.size():
		c[i] += Vector2(0, K._ruido3(Vector3(c[i].x * 0.5, semente, 0)) * larg * 0.12)
	var rotc := PackedVector2Array()
	for p in c:
		rotc.append(p.rotated(ang))
	var meio := (a + b) * 0.5
	meio.y = a.y
	return chao(rotc, meio, esp, mat, semente)


## Rampa: laje inclinada cujo tampo vai de `a` a `b`, com um PATAMAR plano na
## ponta alta (assim entra rente no tampo da ilha de cima, sem degrau).
func rampa(a: Vector3, b: Vector3, larg := 3.0, esp := 1.6, mat := "terreno", semente := 0) -> StaticBody3D:
	var alto := b if b.y >= a.y else a
	var baixo := a if b.y >= a.y else b
	var d := Vector3(alto.x - baixo.x, 0, alto.z - baixo.z).normalized()
	var meio := alto - d * 1.6
	faixa(meio + d * larg * 0.5, alto + d * 1.2, larg, esp * 0.8, mat, semente + 1)
	return _rampa_simples(baixo, meio, larg, esp, mat, semente)


func _rampa_simples(a: Vector3, b: Vector3, larg := 3.0, esp := 1.6, mat := "terreno", semente := 0) -> StaticBody3D:
	var l := a.distance_to(b)
	var c := PackedVector2Array()
	# so' se prolonga para la' da ponta BAIXA (a ponta alta acaba rente, sem
	# degrau onde a capsula encalhe). Local -Z aponta para `b`.
	var h_b := l * 0.5 + (0.6 if b.y < a.y else 0.0)
	var h_a := l * 0.5 + (0.6 if a.y <= b.y else 0.0)
	var hw := larg * 0.5
	for p in [Vector2(-hw, -h_b), Vector2(hw, -h_b), Vector2(hw * 1.08, 0), Vector2(hw, h_a), Vector2(-hw, h_a), Vector2(-hw * 1.08, 0)]:
		c.append(p)
	var corpo := StaticBody3D.new()
	terreno.add_child(corpo)
	var malha := K.laje(c, esp, semente)
	K.inst(corpo, malha, K.mat(mat))
	var f := CollisionShape3D.new()
	var forma := malha.create_trimesh_shape()
	forma.backface_collision = true
	f.shape = forma
	corpo.add_child(f)
	var dirv := (b - a).normalized()
	var base := Basis.looking_at(dirv, Vector3.UP)
	corpo.global_transform = Transform3D(base, (a + b) * 0.5)
	return corpo


## Ponte de raiz retorcida entre dois pontos (com arco para cima).
func ponte_raiz(a: Vector3, b: Vector3, larg := 1.7, arco := 0.6, semente := 0) -> void:
	var corpo := StaticBody3D.new()
	terreno.add_child(corpo)
	var ctrl := PackedVector3Array()
	for i in 6:
		var t := i / 5.0
		ctrl.append(a.lerp(b, t) + Vector3.UP * (sin(t * PI) * arco - larg * 0.3) +
			Vector3(sin(t * 7.0 + semente) * 0.15, 0, cos(t * 5.0) * 0.1))
	var pts := K.curva(ctrl, 4)
	var rs := PackedFloat32Array()
	for i in pts.size():
		var t := float(i) / (pts.size() - 1)
		rs.append(larg * 0.5 * (1.15 - 0.3 * sin(t * PI)))
	K.inst(corpo, K.tubo(pts, rs, 10, 0.18, semente, 0.7), K.mat("casca"))
	# raizes secundarias entrancadas
	for k in 2:
		var p2 := PackedVector3Array()
		for i in pts.size():
			var t := float(i) / (pts.size() - 1)
			p2.append(pts[i] + Vector3(sin(t * 9.0 + k * 3.0), cos(t * 9.0 + k * 3.0) * 0.6, 0) * larg * 0.35)
		K.inst(corpo, K.tubo(p2, K.afunilar(p2.size(), larg * 0.18, larg * 0.12), 6, 0.2, k), K.mat("casca"))
	for i in pts.size() - 1:
		var p0 := pts[i] + Vector3.UP * larg * 0.3
		var p1 := pts[i + 1] + Vector3.UP * larg * 0.3
		var f := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(larg * 0.95, 0.3, p0.distance_to(p1) + 0.05)
		f.shape = bx
		corpo.add_child(f)
		f.global_transform = Transform3D(Basis.looking_at(p1 - p0, Vector3.UP), (p0 + p1) * 0.5 - Vector3.UP * 0.15)


## Laje de pedra sagrada (plataforma talhada) com colisao.
func laje_pedra(c: Vector3, tam := Vector3(3, 0.7, 3), rot := 0.0, semente := 0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = c - Vector3.UP * tam.y * 0.5
	corpo.rotation.y = rot
	terreno.add_child(corpo)
	# pedra sagrada talhada: octogono irregular com flancos partidos (nao caixa)
	var c8 := PackedVector2Array()
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		var k := 1.0 + 0.07 * K._ruido3(Vector3(i * 1.7, semente, 0.3))
		c8.append(Vector2(cos(a) * tam.x * 0.56 * k, sin(a) * tam.z * 0.56 * k))
	K.inst(corpo, K.laje(c8, tam.y + 1.2, semente), K.mat("pedra_sagrada"), Vector3(0, tam.y * 0.5, 0))
	# runa esmeralda gravada no topo
	K.inst(corpo, K.anel(tam.x * 0.22, tam.x * 0.26, 0.0, 24), K.mat("vfx_runa"), Vector3(0, tam.y * 0.5 + 0.015, 0),
		Vector3.ZERO, Vector3.ONE, false)
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(tam.x * 0.98, tam.y, tam.z * 0.98)
	f.shape = b
	corpo.add_child(f)
	return corpo


func plataforma_movel(c: Vector3, desloc: Vector3, periodo := 5.0, tam := Vector3(3, 0.6, 3), fase := 0.0) -> Node3D:
	var p := Pecas3D.PlataformaMovel.new()
	p.tam = tam
	p.desloc = desloc
	p.periodo = periodo
	p.fase = fase
	p.position = c - Vector3.UP * tam.y * 0.5
	vivos.add_child(p)
	return p


func veneno(c: Vector3, tam: Vector2) -> void:
	var pm := PlaneMesh.new()
	pm.size = tam
	pm.subdivide_width = int(tam.x / 3.0)
	pm.subdivide_depth = int(tam.y / 3.0)
	K.inst(self, pm, K.mat("veneno"), c, Vector3.ZERO, Vector3.ONE, false)
	y_morte = maxf(y_morte, c.y - 0.6)
	VFX.esporos(self, c + Vector3.UP * 1.0, Vector3(tam.x * 0.5, 1.0, tam.y * 0.5), Color(0.4, 1.0, 0.5, 0.8), int(tam.x * tam.y / 60.0))


func inimigo(tipo: String, p: Vector3, patrulha := 3.0) -> Inimigo3D:
	var e := Inimigo3D.new()
	e.tipo = tipo
	e.raio_patrulha = patrulha
	e.position = p + Vector3.UP * 0.1
	vivos.add_child(e)
	return e


func espinhos(c: Vector3, tam := Vector2(2, 1), rot := 0.0) -> void:
	var e := Pecas3D.Espinhos.new()
	e.tam = tam
	e.position = c
	e.rotation.y = rot
	vivos.add_child(e)


func raiz_perigo(c: Vector3, periodo := 3.2, atraso := 0.0, raio := 1.3) -> void:
	var r := Pecas3D.Raiz.new()
	r.periodo = periodo
	r.atraso = atraso
	r.raio = raio
	r.position = c
	vivos.add_child(r)


func fogueira(id: String, c: Vector3) -> void:
	var f := Pecas3D.Fogueira.new()
	f.id = id
	f.position = c
	f.add_to_group("fogueiras3d")
	vivos.add_child(f)


func saida(c: Vector3, rot := 0.0, aberto := true) -> Pecas3D.PortalSaida:
	portal = Pecas3D.PortalSaida.new()
	portal.aberto = aberto
	portal.position = c
	portal.rotation.y = rot
	vivos.add_child(portal)
	portal.atravessado.connect(concluir)
	return portal


func folhagem(c: Vector3, raio: float, n: int, tipo := "feto", semente := 0, esc := 1.0) -> void:
	_folhagem.append([c, raio, n, tipo, semente, esc])


## Sequencia de lajes de pedra a saltar: cria as lajes e os pontos de rota
## (centro + borda de salto virada para a seguinte). O salto PARA a primeira
## laje e' responsabilidade de quem chama.
func cadeia_lajes(centros: Array, tam := 2.8, semente := 0, prox: Variant = null) -> void:
	for i in centros.size():
		var c: Vector3 = centros[i]
		laje_pedra(c, Vector3(tam, 0.7, tam), sin(i * 2.1 + semente) * 0.4, semente + i)
		passo(c)
		var n: Variant = centros[i + 1] if i < centros.size() - 1 else prox
		if n != null:
			var d := Vector3((n as Vector3).x - c.x, 0, (n as Vector3).z - c.z).normalized()
			passo(c + d * (tam * 0.5 - 0.55), true)


## Ponto de salto na borda: de `de` em direcao a `para`, a `dist_centro` do centro.
func salto_de(de: Vector3, para: Vector3, dist_centro: float) -> void:
	var d := Vector3(para.x - de.x, 0, para.z - de.z).normalized()
	passo(de + d * dist_centro, true)


## Ponto da rota da camara e do bot de QA. `salto` = saltar ao chegar aqui.
func passo(p: Vector3, salto := false, atacar := false) -> void:
	rota.append(p)
	rota_bot.append({"p": p, "salto": salto, "atacar": atacar})


## ---------------------------------------------------------------------------
## Fundir malhas estaticas por material e celula (menos draw calls).
## ---------------------------------------------------------------------------

func _fundir(raiz: Node3D) -> void:
	var grupos := {}
	var apagar: Array[MeshInstance3D] = []
	_recolher(raiz, raiz, grupos, apagar)
	for chave in grupos:
		var g: Dictionary = grupos[chave]
		var st := SurfaceTool.new()
		for item in g["itens"]:
			st.append_from(item[0], 0, item[1])
		var malha := st.commit()
		var mi := MeshInstance3D.new()
		mi.mesh = malha
		mi.material_override = g["mat"]
		mi.cast_shadow = g["sombra"]
		raiz.add_child(mi)
	for m in apagar:
		m.queue_free()


func _recolher(raiz: Node3D, no: Node, grupos: Dictionary, apagar: Array[MeshInstance3D]) -> void:
	for f in no.get_children():
		if f is MeshInstance3D and not (f is MultiMeshInstance3D) and f.mesh is ArrayMesh \
				and f.material_override != null and not f.top_level and f.visible \
				and (f.mesh as ArrayMesh).get_surface_count() == 1 and f.get_child_count() == 0:
			var xf: Transform3D = raiz.global_transform.affine_inverse() * f.global_transform
			var cel := Vector3i((xf.origin / 24.0).floor())
			var indexada := (f.mesh as ArrayMesh).surface_get_array_index_len(0) > 0
			var chave := "%d_%s_%d_%s" % [f.material_override.get_instance_id(), cel, f.cast_shadow, indexada]
			if not grupos.has(chave):
				grupos[chave] = {"mat": f.material_override, "itens": [], "sombra": f.cast_shadow}
			grupos[chave]["itens"].append([f.mesh, xf])
			apagar.append(f)
		if f is Node3D and not (f is CollisionObject3D and not (f is StaticBody3D)):
			_recolher(raiz, f, grupos, apagar)
