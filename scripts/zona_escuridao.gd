class_name ZonaEscuridao
extends Area2D
## Tira-lhe a VISTA enquanto lá estiver dentro. Dois modos:
##
##  - `escuro` (nível 40, Abismo Oceânico): noite fechada com um buraco de
##    luz à volta dela. Vê-se o passo seguinte e mais nada.
##  - `areia` (nível 49, Cidade Enterrada): tempestade -- um véu cor de
##    duna, mais claro, sem buraco nenhum, com o pó a correr de través.
##
## O véu vive numa `CanvasLayer` própria (fica colado ao ecrã, não ao
## mundo) e MORRE com a área: sair da bolsa devolve a vista no mesmo
## frame, e mudar de nível nunca deixa um véu esquecido por cima do jogo.
##
## O buraco de luz é feito com um `CanvasItemMaterial` em modo SUBTRACT
## por cima do véu -- não é uma luz do motor, é um recorte. Assim funciona
## na mesma com as luzes do bioma ligadas ou desligadas.
##
## Constrói a própria área e o próprio visual: não precisa de cena.

@export_enum("escuro", "areia") var tipo := "escuro"
@export var tamanho := Vector2(700.0, 400.0)
## Opacidade do véu no fim da transição.
@export var forca := 0.9
## Raio do buraco de luz à volta dela (só no modo `escuro`).
@export var raio_luz := 190.0
## Segundos a fechar/abrir -- nunca é instantâneo, senão parece um bug.
@export var transicao := 0.45

var _camada: CanvasLayer
var _veu: ColorRect
var _buraco: Sprite2D
var _alvo: Node2D


func _ready() -> void:
	var col := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	col.shape = forma
	add_child(col)
	monitoring = true
	# a Koliani vive na layer 2 (ver `Armadilha`)
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	_montar_marca()


## Uma marca no mundo a dizer onde a bolsa começa. Sem ela a escuridão
## chegava sem aviso, e um perigo sem aviso lê-se como injustiça.
func _montar_marca() -> void:
	var c := Color(0.05, 0.05, 0.1, 0.30) if tipo == "escuro" \
		else Color(0.62, 0.52, 0.32, 0.22)
	var r := ColorRect.new()
	r.color = c
	r.size = tamanho
	r.position = -tamanho * 0.5
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = -2
	add_child(r)


func _ao_entrar(corpo: Node) -> void:
	if not (corpo is Node2D) or _camada != null:
		return
	_alvo = corpo as Node2D
	_montar_veu()


func _ao_sair(corpo: Node) -> void:
	if corpo != _alvo:
		return
	_alvo = null
	_desmontar_veu()


func _montar_veu() -> void:
	_camada = CanvasLayer.new()
	_camada.layer = 40          # por cima do jogo, por baixo da HUD (100)
	add_child(_camada)

	_veu = ColorRect.new()
	_veu.color = Color(0.02, 0.02, 0.05, 0.0) if tipo == "escuro" \
		else Color(0.72, 0.62, 0.40, 0.0)
	_veu.anchor_right = 1.0
	_veu.anchor_bottom = 1.0
	_veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada.add_child(_veu)
	var alvo_cor := _veu.color
	alvo_cor.a = forca
	_veu.create_tween().tween_property(_veu, "color", alvo_cor, transicao)

	if tipo == "escuro":
		_buraco = Sprite2D.new()
		_buraco.texture = _tex_buraco()
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
		_buraco.material = m
		_buraco.modulate = Color(1, 1, 1, 0.0)
		_camada.add_child(_buraco)
		_buraco.create_tween().tween_property(_buraco, "modulate:a", 1.0, transicao)


## Gradiente radial branco->transparente, do tamanho do buraco.
func _tex_buraco() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = int(raio_luz * 2.0)
	t.height = int(raio_luz * 2.0)
	return t


func _desmontar_veu() -> void:
	if _camada == null:
		return
	var c := _camada
	_camada = null
	_veu = null
	_buraco = null
	for f in c.get_children():
		if f is CanvasItem:
			var t := f.create_tween()
			t.tween_property(f, "modulate:a", 0.0, transicao * 0.7)
	get_tree().create_timer(transicao * 0.8).timeout.connect(func() -> void:
		if is_instance_valid(c):
			c.queue_free())


func _process(_dt: float) -> void:
	# o buraco segue-a no ECRÃ, não no mundo: a camada é fixa
	if _buraco == null or _alvo == null or not is_instance_valid(_alvo):
		return
	var vp := _alvo.get_viewport()
	if vp == null:
		return
	var t := vp.get_canvas_transform()
	_buraco.position = t * _alvo.global_position
