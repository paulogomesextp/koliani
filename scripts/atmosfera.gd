extends Node2D
## Montagem de ambiente reutilizável -- a "profundidade tipo Dead Cells"
## com placeholders. Junta, num só nó instanciável:
##   - `Modulacao` (CanvasModulate, tom do bioma)
##   - `Parallax` com 4 camadas de silhuetas (fundo -> primeiro plano)
##   - `Raios` -- feixes de luz volumétrica (Polygon2D aditivos)
##   - `Poeira` -- partículas de ambiente que seguem a câmara
##   - `Vinheta` + `Grade` (CanvasLayer: vinheta radial + shader de
##     contraste/saturação/bloom suave)
##
## Cada mundo instancia `scenes/fx/Atmosfera.tscn` e afina as cores/densidade
## pelos `@export`.

@export var cor_ambiente := Color(0.6, 0.6, 0.66)
@export var cor_fundo := Color(0.05, 0.06, 0.09)
@export var cor_silhueta := Color(0.1, 0.12, 0.17)
@export var cor_luz := Color(0.6, 0.7, 0.95)
@export var cor_poeira := Color(0.8, 0.9, 1.0)
@export_range(0.0, 3.0) var densidade_poeira := 1.0

var _poeira: CPUParticles2D


func _ready() -> void:
	var modulacao := get_node_or_null("Modulacao") as CanvasModulate
	if modulacao:
		modulacao.color = cor_ambiente

	_pintar_layer("Parallax/Fundo", cor_fundo, cor_silhueta.darkened(0.45))
	_pintar_layer("Parallax/Longe", cor_fundo, cor_silhueta.darkened(0.25))
	_pintar_layer("Parallax/Meio", cor_fundo, cor_silhueta)
	_pintar_layer("Parallax/Perto", cor_fundo, cor_silhueta.darkened(0.55))

	var raios := get_node_or_null("Raios")
	if raios:
		for p in raios.get_children():
			if p is Polygon2D:
				p.color = Color(cor_luz.r, cor_luz.g, cor_luz.b, p.color.a)

	_poeira = get_node_or_null("Poeira") as CPUParticles2D
	if _poeira:
		_poeira.color = cor_poeira
		_poeira.amount = int(maxf(1.0, _poeira.amount * densidade_poeira))


func _process(_dt: float) -> void:
	# a poeira acompanha a câmara para cobrir o nível todo
	if _poeira:
		var cam := get_viewport().get_camera_2d()
		if cam:
			_poeira.global_position = cam.get_screen_center_position()


func _pintar_layer(caminho: String, cor_bruma: Color, cor_forma: Color) -> void:
	var layer := get_node_or_null(caminho)
	if layer == null:
		return
	for n in layer.get_children():
		if n is ColorRect:
			if n.name == "Fundo":
				n.color = cor_bruma
			elif n.name == "Bruma":
				n.color = Color(cor_forma.r, cor_forma.g, cor_forma.b, 0.5)
			else:
				n.color = cor_forma
		elif n is Polygon2D:
			n.color = cor_forma
