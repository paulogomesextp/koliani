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
## Opt-in (N13, "contrapesos"): peso pendurado do outro lado da roldana, a
## descer quando a plataforma sobe -- le-se de longe que e' uma balanca.
@export var textura_contrapeso: Texture2D
@export var escala_contrapeso := 0.6
## Lado da roldana onde fica o contrapeso (-1 esquerda, 1 direita).
@export var lado_contrapeso := 1.0
## Opt-in (N14, "correntes que mudam direcao"): o elevador deixa de subir
## com peso e passa a obedecer a um SINO -- cada badalada do `SinoTorre`
## com este `alterna_grupo` manda a corrente para o outro extremo. Vazio =
## o elevador de sempre.
@export var grupo_sino := ""

var _no_fim := false

var _contrapeso: Sprite2D
var _corda_peso: Sprite2D

var _correntes: Array[Sprite2D] = []
var _roldana: Sprite2D
var _ancora_y := 0.0
var _y_antes := 0.0


func _ready() -> void:
	super._ready()
	if grupo_sino != "":
		add_to_group(grupo_sino)
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
	if textura_contrapeso:
		_corda_peso = Sprite2D.new()
		_corda_peso.texture = TEX_CORRENTE
		_corda_peso.top_level = true
		_corda_peso.centered = false
		_corda_peso.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_corda_peso.region_enabled = true
		_corda_peso.modulate = Color(1.0, 0.84, 0.52)
		_corda_peso.z_index = -1
		add_child(_corda_peso)
		_contrapeso = Sprite2D.new()
		_contrapeso.texture = textura_contrapeso
		_contrapeso.top_level = true
		_contrapeso.scale = Vector2(escala_contrapeso, escala_contrapeso)
		_contrapeso.z_index = -1
		add_child(_contrapeso)
	_esticar()


## A badalada do sino do grupo: a corrente muda de direcao.
func ao_badalar() -> bool:
	if grupo_sino == "":
		return false
	_no_fim = not _no_fim
	return true


func _physics_process(dt: float) -> void:
	if grupo_sino == "":
		super._physics_process(dt)
		return
	var alvo := (_base + curso) if _no_fim else _base
	_som_marcha(global_position.distance_to(alvo) > PARADO)
	global_position = global_position.move_toward(alvo, velocidade * dt)


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
	if _contrapeso:
		# o peso desce o que a plataforma sobe (mesma corda pela roldana)
		var subido := _base.y - global_position.y
		var x := _base.x + lado_contrapeso * (largura * 0.5 + 34.0)
		var y_peso := _ancora_y + 60.0 + subido
		_contrapeso.global_position = Vector2(x, y_peso + textura_contrapeso.get_height() * escala_contrapeso * 0.5)
		_corda_peso.global_position = Vector2(x - TEX_CORRENTE.get_width() * 0.5, _ancora_y)
		_corda_peso.region_rect = Rect2(0.0, 0.0, float(TEX_CORRENTE.get_width()), maxf(1.0, y_peso - _ancora_y))


func _vestir() -> void:
	var vis := get_node_or_null("Visual") as Polygon2D
	if vis:
		vis.color = cor_pedra
		# veste o miolo do terreno do bioma (o mesmo `corpo` das plataformas
		# a' volta), para o elevador ler-se como pedra da torre e nao como
		# um poligono chapado
		var atm := get_tree().get_first_node_in_group("atmosfera")
		var tex: Texture2D = null
		if atm and "bioma" in atm:
			# o mesmo material das plataformas a' volta (`MATERIAL_POR_PACK`)
			var material := String(atm.bioma)
			if "fundo_pack" in atm and PLATAFORMA.MATERIAL_POR_PACK.has(atm.fundo_pack):
				material = PLATAFORMA.MATERIAL_POR_PACK[atm.fundo_pack]
			tex = PLATAFORMA._tex(material, "corpo")
		if tex:
			vis.texture = tex
			vis.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			vis.texture_scale = Vector2.ONE
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
