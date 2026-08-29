@tool
extends StaticBody2D
## Plataforma reutilizavel com terreno pixel-art (packs CC0 -- ver
## assets/sprites/pixel/CREDITS.md). Define `tamanho` e o resto -- colisao,
## NinePatchRect, patch do bioma -- ajusta-se sozinho. `@tool` para dar para
## ver no editor.
##
## O bioma nao se poe plataforma a plataforma: le-se do no do grupo
## "atmosfera" (o raiz de Atmosfera.tscn). Sem esse no, cai em "floresta".

## Patch de relva/terra (Pixel Adventure 1, 16x16) e de pedra/tijolo
## (Kings and Pigs, 32x32). Sao 9-slices -- o miolo repete-se.
const TEX_FLORESTA := preload("res://assets/sprites/pixel/tiles/floresta_block.png")
const TEX_PEDRA := preload("res://assets/sprites/pixel/tiles/pedra_block.png")

## bioma -> [textura, margem_esq, margem_topo, margem_dir, margem_baixo, tom]
## O `tom` recolore o patch de pedra por regiao (a relva fica como esta).
const BIOMAS := {
	"floresta":   [TEX_FLORESTA, 5, 15, 5, 6, Color(1, 1, 1)],
	"prisao":     [TEX_PEDRA, 11, 11, 11, 11, Color(0.62, 0.8, 0.98)],
	"torres":     [TEX_PEDRA, 11, 11, 11, 11, Color(1.1, 0.88, 0.6)],
	"catacumbas": [TEX_PEDRA, 11, 11, 11, 11, Color(0.82, 0.86, 0.66)],
	"cidade":     [TEX_PEDRA, 11, 11, 11, 11, Color(0.95, 0.66, 0.62)],
	"castelo":    [TEX_PEDRA, 11, 11, 11, 11, Color(0.95, 0.6, 1.0)],
}

@export var tamanho := Vector2(200.0, 40.0) : set = _set_tamanho
## Altura do visual (0 = igual a colisao). Maior => "slab" de chao grosso
## que desce por baixo da superficie, sem mexer na colisao.
@export var altura_visual := 0.0 : set = _set_altura_visual
## Mantidas por compatibilidade com as cenas de nivel antigas -- o visual
## e agora pixel-art, portanto estas cores sao ignoradas.
@export var cor_base := Color(0.15, 0.21, 0.11)
@export var cor_topo := Color(0.42, 0.62, 0.28)


func _ready() -> void:
	_aplicar()


func _set_tamanho(v: Vector2) -> void:
	tamanho = v
	_aplicar()


func _set_altura_visual(v: float) -> void:
	altura_visual = v
	_aplicar()


## Nome do bioma a usar (do no do grupo "atmosfera"), ou "floresta".
func _nome_bioma() -> String:
	var atm := get_tree().get_first_node_in_group("atmosfera") if is_inside_tree() else null
	if atm and "bioma" in atm and BIOMAS.has(atm.bioma):
		return atm.bioma
	return "floresta"


func _aplicar() -> void:
	if not is_node_ready():
		return

	var cs := get_node_or_null("Col") as CollisionShape2D
	if cs:
		var r := RectangleShape2D.new()
		r.size = tamanho
		cs.shape = r

	var vis := get_node_or_null("Visual") as NinePatchRect
	if vis == null:
		return
	var d: Array = BIOMAS[_nome_bioma()]
	var vis_h := maxf(tamanho.y, altura_visual)
	vis.texture = d[0]
	vis.patch_margin_left = d[1]
	vis.patch_margin_top = d[2]
	vis.patch_margin_right = d[3]
	vis.patch_margin_bottom = d[4]
	vis.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	vis.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	vis.modulate = d[5]
	vis.size = Vector2(tamanho.x, vis_h)
	vis.position = -tamanho * 0.5  # topo do visual alinhado com o topo da colisao
