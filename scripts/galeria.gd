class_name Galeria
extends Control
## GALERIA DE CONCEITOS (extra da Loja `extra_galeria_conceitos`). Abre por
## cima da Loja (botão VER no detalhe do item) e mostra a arte de produção:
## a key art, a folha de modelo da Koliani e as pranchas de cada região com
## os seus chefes.
##
## As imagens vêm de `docs/art_direction/` mas o export exclui `docs/**`:
## `tools/preparar_galeria.py` copia-as para `assets/ui/galeria/*.jpg`, que é
## o que se lê aqui. Os nomes em PAGINAS têm de bater com esse tool.
##
## Sem spoilers: as páginas de uma região só abrem depois de concluída a
## região anterior (no modo dev abre tudo). Uma página fechada não carrega a
## imagem -- mostra só o cadeado e o que falta fazer.
##
## Controlos: Anterior/Seguinte, setas, deslizar o dedo; duplo toque ou
## duplo clique amplia no ponto tocado, arrastar move, a roda amplia.
## Fecha em VOLTAR ou Esc/BACK.

signal fechado

const ITEM := "extra_galeria_conceitos"
const DIR := "res://assets/ui/galeria/"
const ZOOM_MAX := 3.0
const ZOOM_TOQUE := 2.5
const DESLIZE_MIN := 80.0   ## px para um deslizar mudar de página

## regiao = índice em EstadoJogo.REGIOES (-1 = sempre aberta)
const PAGINAS := [
	{"img": "key_art", "titulo": "gallery.page.key_art", "tipo": "gallery.kind.key_art", "regiao": -1},
	{"img": "koliani_ref", "titulo": "gallery.page.koliani", "tipo": "gallery.kind.model_sheet", "regiao": -1},
	{"img": "r02_concept_environment_01", "tipo": "gallery.kind.environment", "regiao": 1},
	{"img": "r02_concept_environment_02", "tipo": "gallery.kind.environment", "regiao": 1},
	{"img": "r02_boss_pack", "tipo": "gallery.kind.boss", "regiao": 1},
	{"img": "r03_concept_environment", "tipo": "gallery.kind.environment", "regiao": 2},
	{"img": "r03_boss_pack", "tipo": "gallery.kind.boss", "regiao": 2},
	{"img": "r04_concept_environment", "tipo": "gallery.kind.environment", "regiao": 3},
	{"img": "r04_boss_pack", "tipo": "gallery.kind.boss", "regiao": 3},
	{"img": "r05_master_production_board", "tipo": "gallery.kind.board", "regiao": 4},
	{"img": "r06_master_production_board", "tipo": "gallery.kind.board", "regiao": 5},
	{"img": "r07_master_production_board", "tipo": "gallery.kind.board", "regiao": 6},
	{"img": "r08_master_production_board", "tipo": "gallery.kind.board", "regiao": 7},
	{"img": "r09_master_production_board", "tipo": "gallery.kind.board", "regiao": 8},
	{"img": "r10_master_production_board", "tipo": "gallery.kind.board", "regiao": 9},
	{"img": "r11_master_production_board", "tipo": "gallery.kind.board", "regiao": 10},
	{"img": "r12_master_production_board", "tipo": "gallery.kind.board", "regiao": 11},
	{"img": "r13_master_production_board", "tipo": "gallery.kind.board", "regiao": 12},
	{"img": "r14_master_production_board", "tipo": "gallery.kind.board", "regiao": 13},
	{"img": "r15_master_production_board", "tipo": "gallery.kind.board", "regiao": 14},
	{"img": "r16_master_production_board", "tipo": "gallery.kind.board", "regiao": 15},
	{"img": "r17_master_production_board", "tipo": "gallery.kind.board", "regiao": 16},
	{"img": "r18_master_production_board", "tipo": "gallery.kind.board", "regiao": 17},
	{"img": "r19_master_production_board", "tipo": "gallery.kind.board", "regiao": 18},
	{"img": "r20_master_production_board", "tipo": "gallery.kind.board", "regiao": 19},
]

var pagina := 0
var zoom := 1.0
var _pan := Vector2.ZERO
var _arrasto := false
var _inicio := Vector2.ZERO

var _titulo: Label
var _dica: Label
var _vista: Control
var _img: TextureRect
var _cadeado: Label
var _ornamentos: Array[Control] = []
var _nome: Label
var _sub: Label
var _ant: Button
var _seg: Button
var _voltar: Button


static func caminho(i: int) -> String:
	return DIR + str(PAGINAS[i]["img"]) + ".jpg"


## Página aberta? As de uma região só depois de concluída a anterior.
static func pagina_aberta(i: int) -> bool:
	var r := int(PAGINAS[i]["regiao"])
	if r <= 0 or EstadoJogo.modo_dev:
		return true
	return EstadoJogo.regiao_esta_concluida(r - 1)


static func titulo_pagina(i: int) -> String:
	var p: Dictionary = PAGINAS[i]
	if p.has("titulo"):
		return Textos.t(str(p["titulo"]))
	return Textos.t(str(EstadoJogo.REGIOES[int(p["regiao"])]["chave"]))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Frontend9H.vestir(self)
	_montar()
	Textos.idioma_mudou.connect(func(_l: String) -> void: _mostrar())
	_mostrar()
	_seg.grab_focus()


func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(Frontend9H.CARVAO.r, Frontend9H.CARVAO.g, Frontend9H.CARVAO.b, 1.0)
	add_child(fundo)

	# a moldura da imagem: fundo mais escuro e um fio carmesim
	var moldura := Panel.new()
	Frontend9H.por(moldura, Rect2(52.0, 86.0, 1176.0, 540.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.01, 0.02, 1.0)
	sb.border_color = Color(Frontend9H.CARMESIM.r, Frontend9H.CARMESIM.g, Frontend9H.CARMESIM.b, 0.45)
	sb.set_border_width_all(1)
	moldura.add_theme_stylebox_override("panel", sb)
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(moldura)

	_vista = Control.new()
	_vista.name = "Vista"
	Frontend9H.por(_vista, Rect2(53.0, 87.0, 1174.0, 538.0))
	_vista.clip_contents = true
	_vista.mouse_filter = Control.MOUSE_FILTER_STOP
	_vista.gui_input.connect(_entrada_vista)
	_vista.resized.connect(_encaixar)
	add_child(_vista)
	_img = TextureRect.new()
	_img.name = "Imagem"
	_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_img.stretch_mode = TextureRect.STRETCH_SCALE
	_img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista.add_child(_img)
	_cadeado = Label.new()
	_cadeado.name = "Cadeado"
	_cadeado.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cadeado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cadeado.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cadeado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Frontend9H.corpo(_cadeado, 20, Frontend9H.TEXTO_APAGADO)
	_cadeado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista.add_child(_cadeado)
	for dy: float in [-44.0, 30.0]:
		var o := Frontend9H.separador()
		o.set_anchors_preset(Control.PRESET_CENTER)
		o.offset_left = -150.0
		o.offset_right = 150.0
		o.offset_top = dy
		o.offset_bottom = dy + 14.0
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_vista.add_child(o)
		_ornamentos.append(o)
	add_child(Frontend9H.vinheta())

	_titulo = Label.new()
	Frontend9H.por(_titulo, Rect2(0.0, 18.0, 1280.0, 50.0))
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Frontend9H.cabecalho(_titulo, 30)
	add_child(_titulo)
	var orn := Frontend9H.separador()
	Frontend9H.por(orn, Rect2(490.0, 60.0, 300.0, 14.0))
	add_child(orn)
	_dica = Label.new()
	Frontend9H.por(_dica, Rect2(900.0, 58.0, 328.0, 22.0))
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Frontend9H.capitular(_dica, 11, Frontend9H.TEXTO_APAGADO)
	add_child(_dica)

	_nome = Label.new()
	Frontend9H.por(_nome, Rect2(290.0, 636.0, 700.0, 34.0))
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome.clip_text = true
	Frontend9H.cabecalho(_nome, 20)
	add_child(_nome)
	_sub = Label.new()
	Frontend9H.por(_sub, Rect2(290.0, 670.0, 700.0, 24.0))
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Frontend9H.capitular(_sub, 13, Frontend9H.CARMESIM_CLARO)
	add_child(_sub)

	_voltar = Button.new()
	_voltar.name = "Voltar"
	Frontend9H.por(_voltar, Rect2(52.0, 22.0, 150.0, 42.0))
	_ant = Button.new()
	_ant.name = "Anterior"
	Frontend9H.por(_ant, Rect2(52.0, 644.0, 200.0, 46.0))
	_seg = Button.new()
	_seg.name = "Seguinte"
	Frontend9H.por(_seg, Rect2(1028.0, 644.0, 200.0, 46.0))
	for b: Button in [_voltar, _ant, _seg]:
		Frontend9H.botao_placa(b, 17)
		add_child(b)
	_voltar.pressed.connect(_fechar)
	_ant.pressed.connect(func() -> void: ir(pagina - 1))
	_seg.pressed.connect(func() -> void: ir(pagina + 1))


## Muda de página (dá a volta nas pontas).
func ir(i: int) -> void:
	var n := PAGINAS.size()
	pagina = ((i % n) + n) % n
	zoom = 1.0
	_pan = Vector2.ZERO
	Som.toca("menu_mover", -14.0)
	_mostrar()


func _mostrar() -> void:
	_titulo.text = Frontend9H.espacar(Textos.t("gallery.title"), 1)
	_dica.text = Textos.t("gallery.hint")
	_voltar.text = Textos.t("options.back")
	_ant.text = Textos.t("gallery.prev")
	_seg.text = Textos.t("gallery.next")
	_nome.text = titulo_pagina(pagina)
	var p: Dictionary = PAGINAS[pagina]
	_sub.text = "%s   ·   %d / %d" % [Textos.t(str(p["tipo"])), pagina + 1, PAGINAS.size()]
	if pagina_aberta(pagina):
		_img.texture = load(caminho(pagina))
		_img.visible = true
		_cadeado.text = ""
	else:
		_img.texture = null
		_img.visible = false
		var r := int(p["regiao"])
		_cadeado.text = Textos.tf("gallery.locked",
			[Textos.t(str(EstadoJogo.REGIOES[r - 1]["chave"]))])
	for o: Control in _ornamentos:
		o.visible = _cadeado.text != ""
	_encaixar()


## Tamanho e posição da imagem: cabe inteira a zoom 1; ampliada, o `_pan`
## (em px da vista) desloca-a, sem deixar ver para lá das bordas.
func _encaixar() -> void:
	if _img == null or _img.texture == null:
		return
	var vs := _vista.size
	var ts := Vector2(_img.texture.get_size())
	var s := minf(vs.x / ts.x, vs.y / ts.y) * zoom
	var tam := ts * s
	var folga := ((tam - vs) * 0.5).max(Vector2.ZERO)
	_pan = _pan.clamp(-folga, folga)
	_img.size = tam
	_img.position = ((vs - tam) * 0.5 + _pan).round()


## Amplia para `z` mantendo o ponto `em` (coordenadas da vista) no sítio.
func ampliar(z: float, em: Vector2) -> void:
	z = clampf(z, 1.0, ZOOM_MAX)
	var centro := _vista.size * 0.5
	# ponto da imagem sob `em`, relativo ao centro da imagem, antes e depois
	var rel := (em - centro - _pan) * (z / zoom)
	_pan = em - centro - rel
	zoom = z
	if is_equal_approx(zoom, 1.0):
		_pan = Vector2.ZERO
	_encaixar()


func _entrada_vista(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			ampliar(zoom * 1.2, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			ampliar(zoom / 1.2, mb.position)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and mb.double_click:
				ampliar(1.0 if zoom > 1.01 else ZOOM_TOQUE, mb.position)
				_arrasto = false
			elif mb.pressed:
				_arrasto = true
				_inicio = mb.position
			elif _arrasto:
				_arrasto = false
				var d := mb.position - _inicio
				if zoom <= 1.01 and absf(d.x) >= DESLIZE_MIN and absf(d.x) > absf(d.y) * 1.5:
					ir(pagina + (1 if d.x < 0.0 else -1))
		_vista.accept_event()
	elif ev is InputEventMouseMotion and _arrasto:
		var mm := ev as InputEventMouseMotion
		if zoom > 1.01:
			_pan += mm.relative
			_encaixar()
		_vista.accept_event()


## Setas e Esc antes dos botões (senão as setas só mudavam o foco).
func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if ev.is_action_pressed("ui_cancel"):
		_fechar()
	elif ev.is_action_pressed("ui_left"):
		ir(pagina - 1)
	elif ev.is_action_pressed("ui_right"):
		ir(pagina + 1)
	else:
		return
	get_viewport().set_input_as_handled()


func _fechar() -> void:
	if is_queued_for_deletion():
		return
	Som.toca("menu_painel", -12.0, 0.92)
	fechado.emit()
	queue_free()
