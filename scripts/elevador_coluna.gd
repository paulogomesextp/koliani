class_name ElevadorColuna
extends "res://scripts/tumulo_elevador.gd"
## "Elevador de coluna (com corrente)" da Regiao III -- Torre dos Ecos,
## N12 Galerias Verticais (`docs/art_direction/regions/region_03/
## REGION03_VISUAL_GAMEPLAY_CONTRACT.md`, elemento unico LOCKED do N12).
##
## A MECANICA e' exactamente a do `TumuloElevador` (sobe com peso / vaivem
## com `auto`, som de marcha, grupo "tumulos") -- so' muda a LEITURA: em vez
## de uma laje de tumulo verde do cemiterio, uma plataforma de pedra com
## friso dourado pendurada em DUAS CORRENTES que sobem ate' uma roldana fixa
## no alto do poco. A corrente encurta a' medida que a plataforma sobe, por
## isso o jogador ve' de longe ONDE o elevador vai parar (a roldana) antes de
## subir -- e' o "ve-se primeiro, usa-se depois" que a regiao pede.
##
## Instancia-se a cena `TumuloElevador.tscn` com este script por cima: o
## `scene_file_path` continua a ser o do elevador, que e' o que o
## `tools/verifica_mecanicas.gd` e os testes procuram para a camara
## "elevador".

const TEX_CORRENTE := preload("res://assets/sprites/pixel/deco/torres/corrente_t.png")
const TEX_ROLDANA := preload("res://assets/sprites/pixel/deco/torres/engrenagem.png")
const PLATAFORMA := preload("res://scripts/plataforma.gd")

## Quanto acima do FIM do curso fica a roldana (px). A corrente vai da
## plataforma ate' la'.
@export var altura_ancora := 110.0
## Cor da pedra e do friso (paleta LOCKED da regiao: pedra antiga + ouro
## envelhecido).
@export var cor_pedra := Color(0.27, 0.26, 0.36)
@export var cor_friso := Color(0.86, 0.66, 0.3)

var _correntes: Array[Sprite2D] = []
var _roldana: Sprite2D
var _ancora_y := 0.0
var _y_antes := 0.0


func _ready() -> void:
	super._ready()
	_vestir()
	_ancora_y = _base.y + minf(curso.y, 0.0) - altura_ancora
	var hw := largura * 0.5
	for lado in [-1.0, 1.0]:
		var c := Sprite2D.new()
		c.name = "Corrente"
		c.texture = TEX_CORRENTE
		c.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		c.region_enabled = true
		c.centered = false
		c.z_index = -1
		c.modulate = Color(1.0, 0.84, 0.52)  # ouro envelhecido (paleta LOCKED)
		c.position = Vector2(lado * (hw - 16.0) - TEX_CORRENTE.get_width() * 0.5, 0.0)
		add_child(c)
		_correntes.append(c)
	# A roldana e' FIXA no mundo: `top_level` desliga-a da transformada da
	# plataforma, que continua a ser o seu pai so' para morrer com ela.
	_roldana = Sprite2D.new()
	_roldana.name = "Roldana"
	_roldana.texture = TEX_ROLDANA
	_roldana.top_level = true
	_roldana.scale = Vector2(1.6, 1.6)
	_roldana.z_index = -1
	_roldana.modulate = Color(1.0, 0.88, 0.6)
	_roldana.global_position = Vector2(_base.x, _ancora_y)
	add_child(_roldana)
	var trave := Line2D.new()
	trave.name = "Trave"
	trave.top_level = true
	trave.width = 8.0
	trave.default_color = cor_pedra.darkened(0.25)
	trave.points = PackedVector2Array([
		Vector2(_base.x - hw - 10.0, _ancora_y - 4.0),
		Vector2(_base.x + hw + 10.0, _ancora_y - 4.0)])
	trave.z_index = -2
	add_child(trave)
	_y_antes = global_position.y
	_esticar()


func _process(_dt: float) -> void:
	_esticar()
	var dy := global_position.y - _y_antes
	_y_antes = global_position.y
	if _roldana and absf(dy) > 0.01:
		# a roldana gira ao ritmo da corrente (perimetro ~ 2*pi*22 px)
		_roldana.rotation += dy / 22.0


## A corrente vai da plataforma (friso, y=-12) ate' a' roldana.
func _esticar() -> void:
	var comp := maxf(0.0, (global_position.y - 12.0) - _ancora_y)
	for c in _correntes:
		c.position.y = -12.0 - comp
		c.region_rect = Rect2(0.0, 0.0, float(TEX_CORRENTE.get_width()), comp)


func _vestir() -> void:
	var vis := get_node_or_null("Visual") as Polygon2D
	if vis:
		vis.color = cor_pedra
		# veste o miolo do terreno do bioma (o mesmo `corpo` das plataformas
		# a' volta), para o elevador ler-se como pedra da torre e nao como
		# um poligono chapado
		var atm := get_tree().get_first_node_in_group("atmosfera")
		var tex: Texture2D = PLATAFORMA._tex(String(atm.bioma), "corpo") \
			if atm and "bioma" in atm else null
		if tex:
			vis.texture = tex
			vis.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			vis.texture_scale = Vector2(2.0, 2.0)
			vis.color = Color(1.0, 0.95, 1.0)
	var runa := get_node_or_null("Runa") as Line2D
	if runa:
		runa.default_color = Color(cor_friso, 0.85)
	var hw := largura * 0.5
	var friso := Line2D.new()
	friso.name = "Friso"
	friso.width = 3.0
	friso.default_color = cor_friso
	friso.points = PackedVector2Array([Vector2(-hw, -11.0), Vector2(hw, -11.0)])
	add_child(friso)
	var base := Line2D.new()
	base.name = "FrisoBaixo"
	base.width = 2.0
	base.default_color = cor_friso.darkened(0.35)
	base.points = PackedVector2Array([Vector2(-hw + 6.0, 16.0), Vector2(hw - 6.0, 16.0)])
	add_child(base)
