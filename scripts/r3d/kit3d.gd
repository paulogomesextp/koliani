class_name Kit3D
extends RefCounted
## Koliani 3D -- fabrica de MALHAS e MATERIAIS da Regiao I (Floresta Corrompida).
##
## Nao ha' Blender nesta maquina: toda a geometria e' gerada aqui por codigo
## (tubos com transporte paralelo, tornos, lajes a partir de contornos, rochas
## facetadas, cartoes de folhagem) e partilha um punhado de shaders
## estilizados em `assets/r3d/shaders/`. Malhas e materiais ficam em cache:
## construir um nivel inteiro reutiliza as mesmas instancias.

const SH_ESTILO := preload("res://assets/r3d/shaders/estilo.gdshader")
const SH_GRADIENTE := preload("res://assets/r3d/shaders/gradiente.gdshader")
const SH_FOLHAGEM := preload("res://assets/r3d/shaders/folhagem.gdshader")
const SH_VENENO := preload("res://assets/r3d/shaders/veneno.gdshader")
const SH_RAIO := preload("res://assets/r3d/shaders/raio_luz.gdshader")
const SH_ADITIVO := preload("res://assets/r3d/shaders/aditivo.gdshader")

static var _mats := {}
static var _malhas := {}
static var _tex_ruido: Texture2D
static var _n3: FastNoiseLite

## Paleta da Regiao I (LOCKED pela direcao de arte: verde-escuro, esmeralda,
## acentos de corrupcao magenta/roxo, luar frio).
const MATERIAIS := {
	"terreno": {"cor_a": Color(0.11, 0.09, 0.075), "cor_b": Color(0.19, 0.155, 0.12), "cor_topo": Color(0.1, 0.25, 0.12),
		"topo_quant": 1.0, "topo_limiar": 0.45, "fendas": 0.35, "escala": 0.32, "rim": 0.12},
	"terreno_pantano": {"cor_a": Color(0.08, 0.08, 0.06), "cor_b": Color(0.15, 0.14, 0.1), "cor_topo": Color(0.13, 0.2, 0.09),
		"topo_quant": 1.0, "topo_limiar": 0.45, "fendas": 0.3, "escala": 0.32, "rim": 0.1},
	"terreno_corrompido": {"cor_a": Color(0.1, 0.06, 0.08), "cor_b": Color(0.17, 0.1, 0.12), "cor_topo": Color(0.16, 0.07, 0.14),
		"topo_quant": 1.0, "topo_limiar": 0.45, "fendas": 0.45, "escala": 0.32, "rim": 0.12,
		"emissao": Color(0.9, 0.08, 0.5), "emissao_veias": 1.2, "pulso": 0.3},
	"rocha": {"cor_a": Color(0.15, 0.16, 0.16), "cor_b": Color(0.27, 0.28, 0.26), "cor_topo": Color(0.12, 0.28, 0.14),
		"topo_quant": 0.85, "topo_limiar": 0.55, "fendas": 0.6, "escala": 0.5, "rim": 0.18, "contraste": 1.3},
	"pedra_sagrada": {"cor_a": Color(0.33, 0.34, 0.31), "cor_b": Color(0.47, 0.47, 0.41), "cor_topo": Color(0.14, 0.3, 0.16),
		"topo_quant": 0.7, "topo_limiar": 0.6, "fendas": 0.5, "escala": 0.6, "rim": 0.22, "contraste": 1.2},
	"casca": {"cor_a": Color(0.09, 0.06, 0.05), "cor_b": Color(0.2, 0.14, 0.1), "cor_topo": Color(0.1, 0.24, 0.12),
		"topo_quant": 0.45, "topo_limiar": 0.6, "fendas": 0.9, "escala": 0.9, "rim": 0.16, "contraste": 1.7},
	"casca_morta": {"cor_a": Color(0.08, 0.06, 0.07), "cor_b": Color(0.17, 0.13, 0.14), "cor_topo": Color(0.12, 0.2, 0.12),
		"topo_quant": 0.3, "topo_limiar": 0.6, "fendas": 0.9, "escala": 0.9, "rim": 0.2, "contraste": 1.6},
	"copa": {"cor_a": Color(0.03, 0.09, 0.05), "cor_b": Color(0.09, 0.24, 0.12), "cor_topo": Color(0.18, 0.42, 0.2),
		"topo_quant": 0.8, "topo_limiar": 0.3, "escala": 0.8, "rim": 0.3, "contraste": 1.8, "cor_rim": Color(0.35, 0.9, 0.55)},
	"copa_corrompida": {"cor_a": Color(0.08, 0.03, 0.08), "cor_b": Color(0.2, 0.06, 0.18), "cor_topo": Color(0.35, 0.08, 0.3),
		"topo_quant": 0.7, "topo_limiar": 0.3, "escala": 0.8, "rim": 0.3, "contraste": 1.8, "cor_rim": Color(0.9, 0.3, 0.7),
		"emissao": Color(0.9, 0.1, 0.55), "emissao_veias": 0.8},
	"corrupcao": {"cor_a": Color(0.1, 0.015, 0.08), "cor_b": Color(0.24, 0.035, 0.17), "cor_topo": Color(0.3, 0.04, 0.2),
		"topo_quant": 0.0, "escala": 1.4, "rim": 0.45, "cor_rim": Color(1.0, 0.25, 0.7), "contraste": 1.6,
		"emissao": Color(1.0, 0.1, 0.55), "emissao_veias": 3.0, "emissao_plana": 0.12, "pulso": 0.45},
	"cristal": {"cor_a": Color(0.1, 0.45, 0.4), "cor_b": Color(0.35, 0.95, 0.75), "escala": 2.0, "rim": 0.8,
		"cor_rim": Color(0.6, 1.0, 0.85), "emissao": Color(0.25, 0.95, 0.7), "emissao_plana": 0.9, "degraus": 0.2},
	"cogumelo": {"cor_a": Color(0.12, 0.35, 0.4), "cor_b": Color(0.2, 0.6, 0.6), "escala": 3.0, "rim": 0.6,
		"cor_rim": Color(0.5, 1.0, 0.95), "emissao": Color(0.2, 0.8, 0.8), "emissao_plana": 0.55, "pulso": 0.15},
	"caule": {"cor_a": Color(0.45, 0.43, 0.36), "cor_b": Color(0.6, 0.58, 0.5), "escala": 3.0, "rim": 0.2},
	"metal": {"cor_a": Color(0.1, 0.1, 0.12), "cor_b": Color(0.3, 0.3, 0.34), "escala": 3.0, "rim": 0.5,
		"cor_rim": Color(0.8, 0.75, 0.95), "contraste": 1.5, "degraus": 0.8},
	"metal_ferrugem": {"cor_a": Color(0.16, 0.08, 0.05), "cor_b": Color(0.32, 0.2, 0.12), "escala": 4.0, "rim": 0.3,
		"cor_rim": Color(0.9, 0.6, 0.4), "contraste": 1.6, "fendas": 0.5},
	"couro": {"cor_a": Color(0.12, 0.07, 0.05), "cor_b": Color(0.22, 0.13, 0.08), "escala": 5.0, "rim": 0.2},
	"tecido_negro": {"cor_a": Color(0.035, 0.03, 0.04), "cor_b": Color(0.085, 0.07, 0.09), "escala": 6.0, "rim": 0.4,
		"cor_rim": Color(0.6, 0.35, 0.65)},
	"vermelho": {"cor_a": Color(0.2, 0.012, 0.025), "cor_b": Color(0.34, 0.03, 0.045), "escala": 6.0, "rim": 0.18,
		"cor_rim": Color(0.9, 0.3, 0.4)},
	"pele": {"cor_a": Color(0.78, 0.58, 0.49), "cor_b": Color(0.86, 0.66, 0.56), "escala": 8.0, "rim": 0.3,
		"cor_rim": Color(1.0, 0.6, 0.55), "degraus": 0.75},
	"olho": {"cor_a": Color(0.05, 0.02, 0.04), "cor_b": Color(0.1, 0.03, 0.05), "escala": 1.0, "rim": 0.0,
		"emissao": Color(0.6, 0.1, 0.2), "emissao_plana": 0.08},
	"gema": {"cor_a": Color(0.05, 0.4, 0.38), "cor_b": Color(0.2, 0.8, 0.7), "escala": 6.0, "rim": 0.6,
		"cor_rim": Color(0.5, 1.0, 0.9), "emissao": Color(0.2, 0.95, 0.8), "emissao_plana": 1.2},
	"pele_goblin": {"cor_a": Color(0.17, 0.21, 0.13), "cor_b": Color(0.28, 0.32, 0.19), "escala": 4.0, "rim": 0.35,
		"cor_rim": Color(0.8, 0.3, 0.7), "contraste": 1.4, "emissao": Color(0.9, 0.1, 0.55), "emissao_veias": 0.9},
	"pele_bruto": {"cor_a": Color(0.2, 0.14, 0.13), "cor_b": Color(0.32, 0.22, 0.2), "escala": 3.0, "rim": 0.35,
		"cor_rim": Color(0.9, 0.3, 0.6), "contraste": 1.5, "fendas": 0.5, "emissao": Color(0.95, 0.15, 0.5), "emissao_veias": 1.4},
	"olho_corrupto": {"cor_a": Color(1.0, 0.3, 0.75), "cor_b": Color(1.0, 0.5, 0.85), "escala": 1.0, "rim": 0.0,
		"emissao": Color(1.0, 0.2, 0.7), "emissao_plana": 3.0, "degraus": 0.0},
	"gosma": {"cor_a": Color(0.05, 0.16, 0.07), "cor_b": Color(0.12, 0.35, 0.14), "escala": 2.0, "rim": 0.9,
		"cor_rim": Color(0.5, 1.0, 0.45), "contraste": 1.4, "emissao": Color(0.7, 0.1, 0.6), "emissao_veias": 1.6, "pulso": 0.6},
	"carne": {"cor_a": Color(0.22, 0.03, 0.07), "cor_b": Color(0.42, 0.06, 0.12), "escala": 1.2, "rim": 0.5,
		"cor_rim": Color(1.0, 0.3, 0.55), "contraste": 1.5, "emissao": Color(1.0, 0.15, 0.45), "emissao_veias": 2.2, "pulso": 0.6},
	"nucleo": {"cor_a": Color(0.9, 0.2, 0.6), "cor_b": Color(1.0, 0.55, 0.85), "escala": 2.0, "rim": 1.0,
		"cor_rim": Color(1.0, 0.7, 0.95), "emissao": Color(1.0, 0.25, 0.7), "emissao_plana": 2.4, "pulso": 0.5, "degraus": 0.0},
	"casulo": {"cor_a": Color(0.45, 0.43, 0.5), "cor_b": Color(0.7, 0.68, 0.75), "escala": 3.0, "rim": 0.5,
		"cor_rim": Color(0.85, 0.7, 1.0), "fendas": 0.6, "contraste": 1.4, "emissao": Color(0.9, 0.2, 0.6), "emissao_veias": 0.6, "pulso": 0.4},
	"madeira": {"cor_a": Color(0.14, 0.09, 0.06), "cor_b": Color(0.26, 0.17, 0.1), "escala": 1.6, "rim": 0.15, "fendas": 0.7, "contraste": 1.4},
	"ouro": {"cor_a": Color(0.4, 0.28, 0.1), "cor_b": Color(0.75, 0.58, 0.25), "escala": 4.0, "rim": 0.5,
		"cor_rim": Color(1.0, 0.85, 0.5), "contraste": 1.3},
}


static func ruido() -> Texture2D:
	if _tex_ruido == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.seed = 7
		n.frequency = 0.012
		n.fractal_octaves = 5
		var img := n.get_seamless_image(256, 256)
		img.convert(Image.FORMAT_RGBA8)
		img.generate_mipmaps()
		_tex_ruido = ImageTexture.create_from_image(img)
	return _tex_ruido


static func _ruido3(p: Vector3) -> float:
	if _n3 == null:
		_n3 = FastNoiseLite.new()
		_n3.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_n3.seed = 11
		_n3.frequency = 1.0
		_n3.fractal_octaves = 2
	return _n3.get_noise_3dv(p)


## Material partilhado por nome (ver MATERIAIS + especiais abaixo).
static func mat(nome: String) -> Material:
	if _mats.has(nome):
		return _mats[nome]
	var m: ShaderMaterial = _criar_mat(nome)
	_mats[nome] = m
	return m


## Copia propria (para flash de dano por instancia).
static func mat_unico(nome: String) -> ShaderMaterial:
	return (mat(nome) as ShaderMaterial).duplicate() as ShaderMaterial


static func _criar_mat(nome: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	match nome:
		"cabelo", "cabelo_pontas":
			m.shader = SH_GRADIENTE
			m.set_shader_parameter("cor_raiz", Color(0.025, 0.018, 0.028))
			m.set_shader_parameter("cor_ponta", Color(0.45, 0.02, 0.05))
			m.set_shader_parameter("ini", 0.25 if nome == "cabelo_pontas" else 2.0)
			m.set_shader_parameter("fim", 1.0 if nome == "cabelo_pontas" else 3.0)
			m.set_shader_parameter("cor_rim", Color(0.75, 0.35, 0.7))
			m.set_shader_parameter("rim", 0.45)
		"cachecol":
			m.shader = SH_GRADIENTE
			m.set_shader_parameter("cor_raiz", Color(0.42, 0.025, 0.05))
			m.set_shader_parameter("cor_ponta", Color(0.2, 0.01, 0.03))
			m.set_shader_parameter("ini", 0.2)
			m.set_shader_parameter("cor_rim", Color(1.0, 0.35, 0.45))
			m.set_shader_parameter("rim", 0.5)
			m.set_shader_parameter("riscas", 0.06)
		"saia":
			m.shader = SH_GRADIENTE
			m.set_shader_parameter("cor_raiz", Color(0.06, 0.05, 0.065))
			m.set_shader_parameter("cor_ponta", Color(0.3, 0.02, 0.05))
			m.set_shader_parameter("ini", 0.55)
			m.set_shader_parameter("cor_rim", Color(0.7, 0.35, 0.6))
			m.set_shader_parameter("rim", 0.35)
			m.set_shader_parameter("riscas", 0.1)
		"musgo_pendente":
			m.shader = SH_GRADIENTE
			m.set_shader_parameter("cor_raiz", Color(0.08, 0.2, 0.1))
			m.set_shader_parameter("cor_ponta", Color(0.03, 0.08, 0.05))
			m.set_shader_parameter("ini", 0.0)
			m.set_shader_parameter("cor_rim", Color(0.4, 0.9, 0.6))
			m.set_shader_parameter("rim", 0.3)
			m.set_shader_parameter("riscas", 0.4)
		"teia":
			m.shader = SH_GRADIENTE
			m.set_shader_parameter("cor_raiz", Color(0.55, 0.55, 0.62))
			m.set_shader_parameter("cor_ponta", Color(0.7, 0.68, 0.8))
			m.set_shader_parameter("ini", 0.0)
			m.set_shader_parameter("cor_rim", Color(0.8, 0.7, 1.0))
			m.set_shader_parameter("rim", 0.6)
			m.set_shader_parameter("brilho", 0.12)
			m.set_shader_parameter("riscas", 0.0)
		"salgueiro":
			m.shader = SH_GRADIENTE
			m.set_shader_parameter("cor_raiz", Color(0.05, 0.16, 0.14))
			m.set_shader_parameter("cor_ponta", Color(0.25, 0.6, 0.6))
			m.set_shader_parameter("ini", 0.2)
			m.set_shader_parameter("cor_rim", Color(0.5, 0.95, 1.0))
			m.set_shader_parameter("rim", 0.5)
			m.set_shader_parameter("brilho", 0.12)
			m.set_shader_parameter("riscas", 0.5)
		"trapo":
			m.shader = SH_GRADIENTE
			m.set_shader_parameter("cor_raiz", Color(0.16, 0.12, 0.08))
			m.set_shader_parameter("cor_ponta", Color(0.08, 0.05, 0.04))
			m.set_shader_parameter("ini", 0.2)
			m.set_shader_parameter("rim", 0.2)
		"feto", "erva", "folha_larga", "feto_corrompido":
			m.shader = SH_FOLHAGEM
			m.set_shader_parameter("forma", {"feto": 0, "feto_corrompido": 0, "erva": 1, "folha_larga": 2}[nome])
			if nome == "feto_corrompido":
				m.set_shader_parameter("cor_base", Color(0.06, 0.02, 0.06))
				m.set_shader_parameter("cor_ponta", Color(0.45, 0.07, 0.35))
				m.set_shader_parameter("cor_rim", Color(1.0, 0.3, 0.7))
			elif nome == "erva":
				m.set_shader_parameter("cor_base", Color(0.03, 0.07, 0.04))
				m.set_shader_parameter("cor_ponta", Color(0.2, 0.45, 0.2))
			elif nome == "folha_larga":
				m.set_shader_parameter("cor_base", Color(0.02, 0.07, 0.05))
				m.set_shader_parameter("cor_ponta", Color(0.1, 0.32, 0.2))
				m.set_shader_parameter("vento", 0.06)
		"veneno":
			m.shader = SH_VENENO
			m.set_shader_parameter("ruido", ruido())
		"raio_luz":
			m.shader = SH_RAIO
		"raio_luz_magenta":
			m.shader = SH_RAIO
			m.set_shader_parameter("cor", Color(0.9, 0.3, 0.75))
			m.set_shader_parameter("forca", 0.18)
		"vfx_magenta", "vfx_verde", "vfx_aviso", "vfx_onda", "vfx_branco":
			m.shader = SH_ADITIVO
			var cores := {"vfx_magenta": Color(1.0, 0.2, 0.75), "vfx_verde": Color(0.4, 1.0, 0.55),
				"vfx_aviso": Color(1.0, 0.15, 0.3), "vfx_onda": Color(1.0, 0.3, 0.8), "vfx_branco": Color(1, 1, 1)}
			m.set_shader_parameter("cor", cores[nome])
			m.set_shader_parameter("modo", {"vfx_aviso": 2, "vfx_onda": 1}.get(nome, 0))
		"lamina":
			m.shader = SH_ESTILO
			_aplicar(m, MATERIAIS["metal"])
			m.set_shader_parameter("cor_rim", Color(1.0, 0.4, 0.8))
			m.set_shader_parameter("rim", 0.9)
		"gume":
			m.shader = SH_ESTILO
			_aplicar(m, {"cor_a": Color(1.0, 0.4, 0.8), "cor_b": Color(1.0, 0.7, 0.95), "emissao": Color(1.0, 0.2, 0.7),
				"emissao_plana": 2.2, "rim": 0.0, "degraus": 0.0})
		_:
			m.shader = SH_ESTILO
			_aplicar(m, MATERIAIS.get(nome, MATERIAIS["rocha"]))
	return m


static func _aplicar(m: ShaderMaterial, d: Dictionary) -> void:
	m.set_shader_parameter("ruido", ruido())
	for k in d:
		m.set_shader_parameter(k, d[k])


## ---------------------------------------------------------------------------
## Construcao de malhas
## ---------------------------------------------------------------------------

## Liga aneis consecutivos (mesmo nº de vertices, sem vertice repetido) em quads.
## `aneis` = Array de PackedVector3Array; `vs` = coordenada v do UV de cada anel.
static var _inv_tubo := false


static func _coser(st: SurfaceTool, aneis: Array, vs: PackedFloat32Array, base: int) -> int:
	var n: int = (aneis[0] as PackedVector3Array).size()
	for i in aneis.size():
		var anel: PackedVector3Array = aneis[i]
		for j in n + 1:
			st.set_uv(Vector2(float(j) / n, vs[i]))
			st.add_vertex(anel[j % n])
	for i in aneis.size() - 1:
		for j in n:
			var a := base + i * (n + 1) + j
			var b := base + (i + 1) * (n + 1) + j
			var c := b + 1
			var d := a + 1
			if _inv_tubo:
				st.add_index(a); st.add_index(b); st.add_index(c)
				st.add_index(a); st.add_index(c); st.add_index(d)
			else:
				st.add_index(a); st.add_index(c); st.add_index(b)
				st.add_index(a); st.add_index(d); st.add_index(c)
	return base + aneis.size() * (n + 1)


static func _tampa(st: SurfaceTool, anel: PackedVector3Array, centro: Vector3, base: int, para_fora: bool, v: float) -> int:
	var n := anel.size()
	st.set_uv(Vector2(0.5, v))
	st.add_vertex(centro)
	for j in n:
		st.set_uv(Vector2(float(j) / n, v))
		st.add_vertex(anel[j])
	for j in n:
		var a := base + 1 + j
		var b := base + 1 + (j + 1) % n
		if para_fora != _inv_tubo:
			st.add_index(base); st.add_index(a); st.add_index(b)
		else:
			st.add_index(base); st.add_index(b); st.add_index(a)
	return base + n + 1


## Tubo ao longo de uma polilinha (troncos, raizes, ramos, membros, chifres).
## `achatar` < 1 achata o tubo na direcao do primeiro normal (fitas grossas).
static func tubo(pts: PackedVector3Array, raios: PackedFloat32Array, lados := 8, amp := 0.0,
		semente := 0, achatar := 1.0, tampas := true) -> ArrayMesh:
	var m := _tubo(pts, raios, lados, amp, semente, achatar, tampas)
	# orientacao: a normal de um vertice do anel tem de apontar para fora
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var i := mini(lados + 1, v.size() - 1)
	var c := pts[mini(1, pts.size() - 1)]
	if nr.size() > i and nr[i].dot(v[i] - c) < 0.0:
		_inv_tubo = not _inv_tubo
		m = _tubo(pts, raios, lados, amp, semente, achatar, tampas)
		_inv_tubo = not _inv_tubo
	return m


static func _tubo(pts: PackedVector3Array, raios: PackedFloat32Array, lados := 8, amp := 0.0,
		semente := 0, achatar := 1.0, tampas := true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var aneis: Array = []
	var vs := PackedFloat32Array()
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
	var acum := 0.0
	var nrm := Vector3.ZERO
	for i in pts.size():
		var t: Vector3
		if i == 0:
			t = (pts[1] - pts[0]).normalized()
		elif i == pts.size() - 1:
			t = (pts[i] - pts[i - 1]).normalized()
		else:
			t = (pts[i + 1] - pts[i - 1]).normalized()
		if i == 0:
			var ref := Vector3.UP if absf(t.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
			nrm = (ref - t * ref.dot(t)).normalized()
		else:
			acum += pts[i].distance_to(pts[i - 1])
			nrm = (nrm - t * nrm.dot(t)).normalized()
		var bi := t.cross(nrm).normalized()
		var anel := PackedVector3Array()
		for j in lados:
			var a := TAU * j / lados
			var off := nrm * cos(a) * achatar + bi * sin(a)
			var r := raios[i]
			if amp > 0.0:
				r *= 1.0 + amp * _ruido3(pts[i] * 1.7 + off * 0.8 + Vector3(semente * 3.1, 0, 0))
			anel.append(pts[i] + off * r)
		aneis.append(anel)
		vs.append(acum / maxf(total, 0.001))
	var base := _coser(st, aneis, vs, 0)
	if tampas:
		if raios[0] > 0.001:
			base = _tampa(st, aneis[0], pts[0], base, false, 0.0)
		if raios[raios.size() - 1] > 0.001:
			base = _tampa(st, aneis[aneis.size() - 1], pts[pts.size() - 1], base, true, 1.0)
	st.generate_normals()
	return st.commit()


## Torno vertical: perfil = [Vector2(y, raio)], escala elipse em XZ.
static func torno(perfil: Array, lados := 12, esc_x := 1.0, esc_z := 1.0, amp := 0.0, semente := 0) -> ArrayMesh:
	var pts := PackedVector3Array()
	var rs := PackedFloat32Array()
	for p in perfil:
		pts.append(Vector3(0, p.x, 0))
		rs.append(p.y)
	var m := tubo(pts, rs, lados, amp, semente, 1.0, true)
	if esc_x != 1.0 or esc_z != 1.0:
		m = _escalar(m, Vector3(esc_x, 1.0, esc_z))
	return m


static func _escalar(m: ArrayMesh, e: Vector3) -> ArrayMesh:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in v.size():
		v[i] = v[i] * e
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = null
	var st := SurfaceTool.new()
	var nova := ArrayMesh.new()
	nova.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	st.create_from(nova, 0)
	st.generate_normals()
	return st.commit()


## Fita (cabelo, cachecol, trapos, musgo pendente): pontos + larguras + lado.
static func fita(pts: PackedVector3Array, larguras: PackedFloat32Array, lado := Vector3.RIGHT, curva := 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var total := 0.0
	for i in range(1, n):
		total += pts[i].distance_to(pts[i - 1])
	var acum := 0.0
	for i in n:
		if i > 0:
			acum += pts[i].distance_to(pts[i - 1])
		var v := acum / maxf(total, 0.001)
		var t: Vector3 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var l := (lado - t * lado.dot(t)).normalized() * larguras[i] * 0.5
		var dobra := t.cross(l).normalized() * curva * larguras[i]
		st.set_uv(Vector2(0, v)); st.add_vertex(pts[i] - l + dobra)
		st.set_uv(Vector2(0.5, v)); st.add_vertex(pts[i])
		st.set_uv(Vector2(1, v)); st.add_vertex(pts[i] + l + dobra)
	for i in n - 1:
		for k in 2:
			var a := i * 3 + k
			var b := (i + 1) * 3 + k
			st.add_index(a); st.add_index(b + 1); st.add_index(b)
			st.add_index(a); st.add_index(a + 1); st.add_index(b + 1)
	st.generate_normals()
	return st.commit()


## Rocha facetada (low-poly estilizada): esfera deformada por ruido, normais planas.
static func rocha(raio := 1.0, semente := 0, achatar := 0.7, amp := 0.35, detalhe := 1) -> ArrayMesh:
	var chave := "rocha_%s_%d_%s_%s_%d" % [raio, semente, achatar, amp, detalhe]
	if _malhas.has(chave):
		return _malhas[chave]
	var esf := SphereMesh.new()
	esf.radius = 1.0
	esf.height = 2.0
	esf.radial_segments = 9 + detalhe * 4
	esf.rings = 5 + detalhe * 2
	var arr := esf.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var off := Vector3(semente * 7.3, semente * 1.9, -semente * 4.1)
	for i in v.size():
		var d := v[i].normalized()
		var k := 1.0 + amp * _ruido3(d * 1.3 + off) + amp * 0.5 * _ruido3(d * 3.1 + off)
		var p := d * k * raio
		p.y *= achatar
		if p.y < -raio * achatar * 0.35:
			p.y = lerpf(p.y, -raio * achatar * 0.35, 0.7)
		v[i] = p
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in idx.size():
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v[idx[i]])
	st.generate_normals()
	var m := st.commit()
	_malhas[chave] = m
	return m


## Bloco de pedra talhada (ruinas): caixa subdividida com lascas, normais planas.
static func bloco(tam: Vector3, semente := 0, lasca := 0.06) -> ArrayMesh:
	var chave := "bloco_%s_%d_%s" % [tam, semente, lasca]
	if _malhas.has(chave):
		return _malhas[chave]
	var bx := BoxMesh.new()
	bx.size = tam
	bx.subdivide_width = 2
	bx.subdivide_height = 2
	bx.subdivide_depth = 2
	var arr := bx.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var off := Vector3(semente * 5.1, semente * 2.3, semente * 3.7)
	var h := tam * 0.5
	for i in v.size():
		var p := v[i]
		var canto := (absf(p.x) / h.x) + (absf(p.y) / h.y) + (absf(p.z) / h.z)
		var j := Vector3(_ruido3(p * 2.0 + off), _ruido3(p * 2.0 + off + Vector3(9, 0, 0)),
				_ruido3(p * 2.0 + off + Vector3(0, 9, 0))) * lasca
		var enc := 1.0 - lasca * 0.6 * maxf(canto - 2.2, 0.0)
		v[i] = p * enc + j
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in idx.size():
		st.set_uv(Vector2.ZERO)
		st.add_vertex(v[idx[i]])
	st.generate_normals()
	var m := st.commit()
	_malhas[chave] = m
	return m


## Ilha de terreno: tampo plano a partir de um contorno XZ + flancos rochosos
## que se afunilam para baixo (plataformas flutuantes / margens do pantano).
static func laje(contorno: PackedVector2Array, espessura := 3.0, semente := 0) -> ArrayMesh:
	var m := _laje(contorno, espessura, semente, false)
	# confirmar a orientacao: a normal do tampo tem de apontar para cima
	var nrm: PackedVector3Array = m.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	if nrm.size() > 0 and nrm[0].y < 0.0:
		m = _laje(contorno, espessura, semente, true)
	return m


static func _laje(contorno: PackedVector2Array, espessura: float, semente: int, inv: bool) -> ArrayMesh:
	var c := contorno.duplicate()
	if Geometry2D.is_polygon_clockwise(c):
		c.reverse()
	var cen := Vector2.ZERO
	for p in c:
		cen += p
	cen /= c.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# tampo
	st.set_smooth_group(1)
	var tri := Geometry2D.triangulate_polygon(c)
	for i in range(0, tri.size(), 3):
		for k in ([0, 1, 2] if inv else [0, 2, 1]):
			var p := c[tri[i + k]]
			st.set_uv(Vector2(p.x, p.y) * 0.1)
			st.add_vertex(Vector3(p.x, 0.0, p.y))
	# flancos
	st.set_smooth_group(2)
	var niveis := [[0.0, 1.0], [-0.35, 1.04], [-espessura * 0.45, 0.88], [-espessura * 0.8, 0.5], [-espessura, 0.12]]
	var aneis: Array = []
	var vs := PackedFloat32Array()
	for nv in niveis:
		var anel := PackedVector3Array()
		for p in c:
			var d := p - cen
			var j := 1.0
			if float(nv[0]) < 0.0:
				j += 0.18 * _ruido3(Vector3(p.x, nv[0], p.y) * 0.4 + Vector3(semente, 0, 0))
			var q: Vector2 = cen + d * float(nv[1]) * j
			anel.append(Vector3(q.x, nv[0], q.y))
		aneis.append(anel)
		vs.append(-nv[0] / espessura)
	# os flancos vao com o MESMO sentido do tampo (contorno CCW visto de cima)
	var n := c.size()
	for i in aneis.size() - 1:
		var a0: PackedVector3Array = aneis[i]
		var a1: PackedVector3Array = aneis[i + 1]
		for j in n:
			var j2 := (j + 1) % n
			if inv:
				st.add_vertex(a0[j]); st.add_vertex(a1[j]); st.add_vertex(a0[j2])
				st.add_vertex(a0[j2]); st.add_vertex(a1[j]); st.add_vertex(a1[j2])
			else:
				st.add_vertex(a0[j]); st.add_vertex(a0[j2]); st.add_vertex(a1[j])
				st.add_vertex(a0[j2]); st.add_vertex(a1[j2]); st.add_vertex(a1[j])
	st.generate_normals()
	return st.commit()


## Cartao de feto: N frondes em arco a partir do centro (para MultiMesh).
static func feto(frondes := 7, comp := 1.0, larg := 0.32) -> ArrayMesh:
	var chave := "feto_%d_%s_%s" % [frondes, comp, larg]
	if _malhas.has(chave):
		return _malhas[chave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := 0
	for f in frondes:
		var ang := TAU * f / frondes + 0.3 * sin(f * 2.7)
		var dir := Vector3(cos(ang), 0, sin(ang))
		var lado := Vector3(-dir.z, 0, dir.x)
		var segs := 4
		for s in segs + 1:
			var t := float(s) / segs
			var incl := lerpf(0.25, 1.35, t) * (0.8 + 0.2 * sin(f * 1.3))
			var p := dir * sin(incl) * comp * t * 1.0 + Vector3.UP * cos(incl) * comp * t * 0.9
			st.set_uv(Vector2(0, t)); st.add_vertex(p - lado * larg * 0.5)
			st.set_uv(Vector2(1, t)); st.add_vertex(p + lado * larg * 0.5)
		for s in segs:
			var a := base + s * 2
			st.add_index(a); st.add_index(a + 2); st.add_index(a + 1)
			st.add_index(a + 1); st.add_index(a + 2); st.add_index(a + 3)
		base += (segs + 1) * 2
	st.generate_normals()
	var m := st.commit()
	_malhas[chave] = m
	return m


## Tufo de erva: laminas finas curvas.
static func tufo(laminas := 9, alt := 0.5) -> ArrayMesh:
	var chave := "tufo_%d_%s" % [laminas, alt]
	if _malhas.has(chave):
		return _malhas[chave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := 0
	for f in laminas:
		var ang := TAU * f / laminas + f * 1.7
		var dir := Vector3(cos(ang), 0, sin(ang))
		var lado := Vector3(-dir.z, 0, dir.x)
		var raiz := dir * 0.06 * (f % 3)
		var h := alt * (0.6 + 0.4 * fmod(f * 0.618, 1.0))
		for s in 4:
			var t := s / 3.0
			var p := raiz + dir * t * t * h * 0.5 + Vector3.UP * t * h
			st.set_uv(Vector2(0, t)); st.add_vertex(p - lado * 0.04)
			st.set_uv(Vector2(1, t)); st.add_vertex(p + lado * 0.04)
		for s in 3:
			var a := base + s * 2
			st.add_index(a); st.add_index(a + 2); st.add_index(a + 1)
			st.add_index(a + 1); st.add_index(a + 2); st.add_index(a + 3)
		base += 8
	st.generate_normals()
	var m := st.commit()
	_malhas[chave] = m
	return m


## Cone de luz aberto (feixe de luar falso).
static func cone_luz(alt := 12.0, r0 := 0.6, r1 := 3.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 10
	for j in n + 1:
		var a := TAU * j / n
		var d := Vector3(cos(a), 0, sin(a))
		st.set_uv(Vector2(float(j) / n, 1.0)); st.add_vertex(d * r0)
		st.set_uv(Vector2(float(j) / n, 0.0)); st.add_vertex(d * r1 + Vector3.DOWN * alt)
	for j in n:
		var a := j * 2
		st.add_index(a); st.add_index(a + 1); st.add_index(a + 2)
		st.add_index(a + 2); st.add_index(a + 1); st.add_index(a + 3)
	st.generate_normals()
	return st.commit()


## Disco plano (marcas no chao, agua).
static func disco(raio := 1.0, lados := 24) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_uv(Vector2(0.5, 0.5)); st.set_color(Color.WHITE); st.add_vertex(Vector3.ZERO)
	for j in lados:
		var a := TAU * j / lados
		st.set_uv(Vector2(0.5 + cos(a) * 0.5, 0.5 + sin(a) * 0.5))
		st.set_color(Color.WHITE)
		st.add_vertex(Vector3(cos(a), 0, sin(a)) * raio)
	for j in lados:
		st.add_index(0); st.add_index(1 + (j + 1) % lados); st.add_index(1 + j)
	st.generate_normals()
	return st.commit()


## Anel achatado (onda de choque): UV.y vai de dentro (0) para fora (1).
static func anel(r_in := 0.8, r_out := 1.0, alt := 0.0, lados := 40) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in lados + 1:
		var a := TAU * j / lados
		var d := Vector3(cos(a), 0, sin(a))
		st.set_color(Color.WHITE); st.set_uv(Vector2(float(j) / lados, 0.0)); st.add_vertex(d * r_in)
		st.set_color(Color.WHITE); st.set_uv(Vector2(float(j) / lados, 1.0)); st.add_vertex(d * r_out + Vector3.UP * alt)
	for j in lados:
		var a := j * 2
		st.add_index(a); st.add_index(a + 2); st.add_index(a + 1)
		st.add_index(a + 1); st.add_index(a + 2); st.add_index(a + 3)
	st.generate_normals()
	return st.commit()


## ---------------------------------------------------------------------------
## Helpers de instancia
## ---------------------------------------------------------------------------

static func inst(pai: Node, malha: Mesh, material: Material, pos := Vector3.ZERO,
		rot := Vector3.ZERO, esc := Vector3.ONE, sombras := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	mi.scale = esc
	if not sombras:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
	return mi


## Curva suave (Catmull-Rom) entre pontos de controlo -> polilinha densa.
static func curva(ctrl: PackedVector3Array, passos := 4) -> PackedVector3Array:
	var out := PackedVector3Array()
	var n := ctrl.size()
	for i in n - 1:
		var p0 := ctrl[maxi(i - 1, 0)]
		var p1 := ctrl[i]
		var p2 := ctrl[i + 1]
		var p3 := ctrl[mini(i + 2, n - 1)]
		for s in passos:
			var t := float(s) / passos
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(ctrl[n - 1])
	return out


static func afunilar(n: int, r0: float, r1: float, potencia := 1.0) -> PackedFloat32Array:
	var r := PackedFloat32Array()
	for i in n:
		var t := float(i) / maxf(n - 1, 1)
		r.append(lerpf(r0, r1, pow(t, potencia)))
	return r
