class_name Alavanca
extends Area2D
## Alavanca de parede/chão. A Koliani toca -> muda de estado e avisa as
## `PortaTrancada` com o mesmo `id`. Visual construído em código (base +
## manípulo que baloiça de baixo para cima).
##
## `so_liga = true` -> uma vez ligada não volta a desligar (interruptor de
## um só sentido). Grupo "alavancas".

signal mudou(ligada: bool)

## Liga esta alavanca à(s) `PortaTrancada` com o mesmo id.
@export var id := "porta_a"
## Interruptor de um só sentido (não se pode voltar a desligar).
@export var so_liga := false
## Começa já ligada.
@export var ligada := false
## Opt-in: alavanca pintada (uma textura; ligar espelha-a e acende-a). Vazio =
## a alavanca de poligonos de sempre.
@export var textura: Texture2D
@export var escala_textura := 0.4
## Opt-in: ao mudar, alterna as plataformas deste grupo como a badalada do
## `SinoTorre` (as solidas somem, as fantasma ficam solidas) -- as "pontes
## reconfiguraveis" do N13. Vazio = so' portas.
@export var alterna_grupo := ""

var _pele: Sprite2D

const COR_OFF := Color(0.55, 0.5, 0.4)
const COR_ON := Color(0.5, 1.0, 0.7)

var _cooldown := 0.0
var _manipulo: Polygon2D
var _luz: PointLight2D
var _t := 0.0


func _ready() -> void:
	add_to_group("alavancas")
	body_entered.connect(_ao_tocar)
	_montar_visual()
	if textura:
		for c in get_children():
			if c is Polygon2D:
				(c as Polygon2D).visible = false
		_pele = Sprite2D.new()
		_pele.texture = textura
		_pele.scale = Vector2(escala_textura, escala_textura)
		# a base assenta no chao (a origem da alavanca e' o pe' do poste)
		_pele.position = Vector2(0.0, 16.0 - textura.get_height() * escala_textura * 0.5)
		add_child(_pele)
	_aplicar(true)


func _montar_visual() -> void:
	# poste / base
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-4, 14), Vector2(4, 14), Vector2(4, 2), Vector2(-4, 2)])
	base.color = Color(0.2, 0.18, 0.16)
	add_child(base)
	var suporte := Polygon2D.new()
	suporte.polygon = PackedVector2Array([Vector2(-9, 16), Vector2(9, 16), Vector2(7, 14), Vector2(-7, 14)])
	suporte.color = Color(0.12, 0.11, 0.1)
	add_child(suporte)

	_manipulo = Polygon2D.new()
	_manipulo.polygon = PackedVector2Array([Vector2(-2, 2), Vector2(2, 2), Vector2(2, -18), Vector2(-2, -18)])
	_manipulo.color = COR_OFF
	add_child(_manipulo)
	var punho := Polygon2D.new()
	punho.polygon = PackedVector2Array([Vector2(-5, -22), Vector2(5, -22), Vector2(5, -16), Vector2(-5, -16)])
	punho.color = Color(0.75, 0.2, 0.2)
	_manipulo.add_child(punho)

	_luz = PointLight2D.new()
	_luz.texture = _tex_luz()
	_luz.color = COR_ON
	_luz.energy = 0.0
	_luz.scale = Vector2(0.5, 0.5)
	add_child(_luz)


func _tex_luz() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 140
	t.height = 140
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _process(dt: float) -> void:
	_cooldown = maxf(0.0, _cooldown - dt)
	if ligada and _luz:
		_t += dt
		_luz.energy = 0.9 + 0.25 * sin(_t * 5.0)


func _ao_tocar(corpo: Node) -> void:
	# pelo GRUPO e nao pelo tipo: `is Koliani` arrasta o `koliani.gd`, que
	# fala com autoloads e por isso nao compila em `--script` -- e quem
	# herda desta classe deixava de se poder medir em bancada
	if not (corpo is Node and corpo.is_in_group("koliani")) or _cooldown > 0.0:
		return
	if ligada and so_liga:
		return
	_cooldown = 0.6
	ligada = not ligada
	# pelo caminho e nao pelo IDENTIFICADOR: assim a Alavanca (e tudo o que
	# herda dela, como a `PlacaPeso`) continua a compilar em `--script`, que
	# e' onde as bancadas correm
	# `selo` e' o CHECKPOINT (`checkpoint.gd`). Puxar uma alavanca e ouvir o
	# selo ensinava ao jogador que tinha gravado. `mecanismo` e' metal a
	# engatar -- o pitch continua a distinguir ligar de desligar.
	var som := get_node_or_null("/root/Som")
	if som and som.has_method("toca"):
		som.call("toca", "mecanismo", -11.0, 1.12 if ligada else 0.86)
	_aplicar(false)
	mudou.emit(ligada)
	if alterna_grupo != "":
		for p in get_tree().get_nodes_in_group(alterna_grupo):
			_alternar(p)


## O mesmo alternar da badalada do `SinoTorre` (colisao + visual).
func _alternar(p: Node) -> void:
	var col := p.get_node_or_null("Col") as CollisionShape2D
	if col == null:
		return
	var vai_ficar_solida := col.disabled
	col.set_deferred("disabled", not col.disabled)
	var vis := p.get_node_or_null("Visual") as CanvasItem
	if vis:
		var a: float = float(p.get("alpha_fantasma")) if p.get("alpha_fantasma") != null else 0.16
		create_tween().tween_property(vis, "modulate:a", 1.0 if vai_ficar_solida else a, 0.14)


func _aplicar(instantaneo: bool) -> void:
	if _pele:
		# desligada o manipulo aponta para tras; ligada, para a frente e acesa
		_pele.flip_h = not ligada
		var alvo := Color(1.25, 1.2, 1.05) if ligada else Color(0.85, 0.85, 0.9)
		if instantaneo:
			_pele.modulate = alvo
		else:
			_pele.scale = Vector2(escala_textura * 1.12, escala_textura * 0.9)
			var tp := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tp.tween_property(_pele, "scale", Vector2(escala_textura, escala_textura), 0.2)
			tp.parallel().tween_property(_pele, "modulate", alvo, 0.2)
	if _manipulo == null:
		return
	var ang := deg_to_rad(-32.0) if ligada else deg_to_rad(32.0)
	var cor := COR_ON if ligada else COR_OFF
	var e := 1.0 if ligada else 0.0
	if instantaneo:
		_manipulo.rotation = ang
		_manipulo.color = cor
		if _luz:
			_luz.energy = e
		return
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_manipulo, "rotation", ang, 0.18)
	tw.parallel().tween_property(_manipulo, "color", cor, 0.18)
	if _luz:
		tw.parallel().tween_property(_luz, "energy", e, 0.2)
