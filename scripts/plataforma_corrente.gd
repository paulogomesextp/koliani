class_name PlataformaCorrente
extends AnimatableBody2D
## Plataforma pendurada por uma corrente -- mecânica partilhada da Região II
## (Prisão dos Condenados). `AnimatableBody2D` com `sync_to_physics` ->
## carrega a Koliani. Move-se de três formas (`modo`):
##   * "pendulo"     -- baloiça em arco à volta da âncora (amplitude em graus).
##   * "vertical"    -- sobe e desce (amplitude em px), como um monta-cargas.
##   * "horizontal"  -- vaivém lateral (amplitude em px).
## A corrente (Line2D) é desenhada da âncora até à plataforma a cada frame.
##
## O Carcereiro (chefe do nível 06) "prende" estas plataformas: chama
## `travar(segundos)` -> ela congela no sítio; `soltar()` volta ao ritmo.
## Todas entram no grupo "plataformas_correntes".

@export_enum("pendulo", "vertical", "horizontal") var modo := "pendulo"
## Amplitude: graus (pendulo) ou px de curso total/2 (vertical/horizontal).
@export var amplitude := 32.0
@export var periodo := 3.0
## Desfasamento inicial (segundos) -- plataformas vizinhas fora de fase.
@export var fase := 0.0
## Comprimento da corrente em repouso (px). No "pendulo" é o raio do arco.
@export var comprimento := 150.0
@export var largura := 130.0 : set = _set_largura
@export var cor_topo := Color(0.34, 0.36, 0.42)
@export var cor_base := Color(0.13, 0.14, 0.18)

var _base := Vector2.ZERO
var _ancora := Vector2.ZERO
var _t := 0.0
var _travada := false

@onready var _forma: CollisionShape2D = $Col
@onready var _visual: Polygon2D = $Visual

## Cor da laje e da corrente. Branco (omissao) deixa a arte da cena como
## esta'. A Regiao II usa isto para a laje deixar de ser cinzento de
## prisao e passar a ser a pedra do Desfiladeiro -- so' cor, a colisao e o
## movimento nao mudam.
@export var tinta := Color(1, 1, 1, 1)
@onready var _corrente: Line2D = $Corrente


func _ready() -> void:
	# A tinta tem de entrar nas CORES DOS VERTICES, nao no `color` do
	# Polygon2D: o `_reconstruir()` reescreve `vertex_colors` a partir de
	# `cor_topo`/`cor_base` e por cima delas o `color` nao se ve'. (A
	# primeira tentativa tingiu o `color` e as lajes continuaram cinzentas.)
	if not tinta.is_equal_approx(Color(1, 1, 1, 1)):
		cor_topo = cor_topo * tinta
		cor_base = cor_base * tinta
		var lin := get_node_or_null("Corrente") as Line2D
		if lin:
			lin.default_color = lin.default_color * tinta
	add_to_group("plataformas_correntes")
	sync_to_physics = true
	_base = global_position
	_ancora = _base + Vector2(0.0, -comprimento)
	_t = fase
	_reconstruir()


func _physics_process(dt: float) -> void:
	if not _travada:
		_t += dt
	var s := sin(_t * TAU / maxf(0.1, periodo))
	match modo:
		"vertical":
			global_position = _base + Vector2(0.0, s * amplitude)
		"horizontal":
			global_position = _base + Vector2(s * amplitude, 0.0)
		_:  # pendulo
			var ang := deg_to_rad(amplitude) * s
			global_position = _ancora + Vector2(sin(ang), cos(ang)) * comprimento
	if _corrente:
		_corrente.points = PackedVector2Array([to_local(_ancora), Vector2(0.0, -8.0)])


## O Carcereiro prende a plataforma por uns segundos (fica imóvel + tom frio).
func travar(segundos: float) -> void:
	if _travada:
		return
	_travada = true
	_visual.modulate = Color(0.6, 0.7, 0.95)
	get_tree().create_timer(maxf(0.1, segundos)).timeout.connect(soltar)


func soltar() -> void:
	_travada = false
	if _visual:
		create_tween().tween_property(_visual, "modulate", Color(1, 1, 1), 0.3)


func _set_largura(v: float) -> void:
	largura = maxf(32.0, v)
	if is_node_ready():
		_reconstruir()


func _reconstruir() -> void:
	if _forma == null or _visual == null:
		return
	var hw := largura * 0.5
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, 22.0)
	_forma.shape = r
	_forma.position = Vector2(0.0, 3.0)
	_visual.polygon = PackedVector2Array([
		Vector2(-hw, -9), Vector2(hw, -9),
		Vector2(hw - 7, 14), Vector2(-hw + 7, 14),
	])
	_visual.vertex_colors = PackedColorArray([cor_topo, cor_topo, cor_base, cor_base])
