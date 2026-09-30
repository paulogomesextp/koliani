class_name PlataformaBalanco
extends "res://scripts/tumulo_elevador.gd"
## "Plataformas grandes (oscilacao)" do N14 -- Campanario (`docs/art_direction/
## regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md`): uma laje larga
## pendurada em DUAS correntes paralelas de uma trave alta, a baloicar. As
## correntes sao paralelas, por isso a laje vai sempre deitada (e' um
## baloico, nao um pendulo que a vira) -- quem vai em cima nao escorrega.
##
## O no' fica no PONTO MAIS BAIXO do arco (a laje em repouso); a trave fica
## `comprimento` px acima. Instancia-se a cena `TumuloElevador.tscn` com este
## script por cima (como o `ElevadorColuna`): `AnimatableBody2D` com
## `sync_to_physics`, por isso carrega a Koliani.
##
## Para o crivo de alcance (`tools/verifica_alcance.gd`) e' um VAIVEM entre
## os dois extremos do arco -- e' onde a laje para e onde se sobe e desce
## dela: `_base` = extremo esquerdo, `curso` = ate' ao direito, `auto`.

const PLATAFORMA := preload("res://scripts/plataforma.gd")

## Comprimento das correntes (px): da trave ao topo da laje.
@export var comprimento := 300.0
@export var amplitude_graus := 26.0
## Segundos por ida e volta.
@export var periodo := 4.2
## Fase inicial (0..1 de uma volta).
@export var fase := 0.0
## Corrente pintada (a das pranchas, em mosaico vertical).
@export var textura_corrente: Texture2D
@export var cor_friso := Color(0.86, 0.66, 0.3)

var _pivo := Vector2.ZERO
var _t := 0.0
var _correntes: Array[Sprite2D] = []


func _ready() -> void:
	super._ready()
	auto = true
	_pivo = global_position - Vector2(0.0, comprimento)
	var a := deg_to_rad(amplitude_graus)
	var ext := Vector2(sin(a), cos(a)) * comprimento
	_base = _pivo + Vector2(-ext.x, ext.y)
	curso = Vector2(2.0 * ext.x, 0.0)
	_t = fase * periodo
	_vestir()
	_posicionar()


func _physics_process(dt: float) -> void:
	_t += dt
	_posicionar()


func _posicionar() -> void:
	var ang := deg_to_rad(amplitude_graus) * sin(TAU * _t / maxf(0.3, periodo))
	global_position = _pivo + Vector2(sin(ang), cos(ang)) * comprimento
	# as correntes apontam da laje para a trave: o eixo +y do sprite roda
	# para (-sin ang, -cos ang)
	var r := PI - ang
	for c in _correntes:
		var w := float(c.texture.get_width()) * c.scale.x
		var presa: Vector2 = c.get_meta("presa")
		c.rotation = r
		c.position = presa - Vector2(cos(r), sin(r)) * w * 0.5


func _vestir() -> void:
	var vis := get_node_or_null("Visual") as Polygon2D
	if vis:
		var atm := get_tree().get_first_node_in_group("atmosfera")
		var tex: Texture2D = null
		if atm and "bioma" in atm:
			var material := String(atm.bioma)
			if "fundo_pack" in atm and PLATAFORMA.MATERIAL_POR_PACK.has(atm.fundo_pack):
				material = PLATAFORMA.MATERIAL_POR_PACK[atm.fundo_pack]
			tex = PLATAFORMA._tex(material, "corpo")
		if tex:
			vis.texture = tex
			vis.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			vis.color = Color(1.0, 0.95, 1.0)
		else:
			vis.color = Color(0.27, 0.26, 0.36)
	var runa := get_node_or_null("Runa") as CanvasItem
	if runa:
		runa.visible = false
	var hw := largura * 0.5
	# friso de ouro velho em cima e em baixo, e as argolas onde as correntes
	# prendem (como a prancha: laje de pedra com ferragens douradas)
	for dados in [[-11.0, 3.0, cor_friso], [16.0, 2.0, cor_friso.darkened(0.35)]]:
		var l := Line2D.new()
		l.width = float(dados[1])
		l.default_color = dados[2]
		l.points = PackedVector2Array([Vector2(-hw + 4.0, float(dados[0])), Vector2(hw - 4.0, float(dados[0]))])
		add_child(l)
	for lado in [-1.0, 1.0]:
		var argola := Line2D.new()
		argola.width = 3.0
		argola.default_color = cor_friso
		argola.closed = true
		var pts := PackedVector2Array()
		for i in 10:
			var k := TAU * float(i) / 10.0
			pts.append(Vector2(lado * (hw - 22.0) + cos(k) * 7.0, 26.0 + sin(k) * 7.0))
		argola.points = pts
		add_child(argola)
		if textura_corrente:
			var c := Sprite2D.new()
			c.name = "Corrente"
			c.texture = textura_corrente
			c.centered = false
			c.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			c.region_enabled = true
			var esc := 0.7
			c.scale = Vector2(esc, esc)
			c.region_rect = Rect2(0.0, 0.0, float(textura_corrente.get_width()), (comprimento - 12.0) / esc)
			c.modulate = Color(1.0, 0.86, 0.6)
			c.z_index = -1
			c.set_meta("presa", Vector2(lado * (hw - 22.0), -12.0))
			add_child(c)
			_correntes.append(c)
