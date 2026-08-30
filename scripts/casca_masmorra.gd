@tool
class_name CascaMasmorra
extends Node2D
## Fecha um nível de campo aberto numa CAVERNA/MASMORRA: tecto + paredes
## esquerda/direita + fundo, em tiles do `assets/tiles/masmorra.tres`
## (0x72 DungeonTileset II, CC0). O visual é um `TileMapLayer` interno
## (escala x`ESCALA` para os tiles de 16px casarem com a métrica do jogo);
## a colisão são 3 `StaticBody2D` simples (tecto + 2 paredes) na layer
## "mundo" (bit 1) -- fiável, não depende da colisão escalada do tilemap.
##
## Parâmetros em px de mundo. O retângulo interior jogável é
## (`esquerda`, `topo`) .. (`esquerda+largura`, `topo+altura`); a Koliani,
## portas, checkpoints e o chefe ficam DENTRO dele. Aditivo: não mexe na
## geometria de plataformas/chão feita à mão -- só emoldura o nível.

const TSET := preload("res://assets/tiles/masmorra.tres")
const ESCALA := 2
const CEL := 16 * ESCALA          # 32 px por célula no mundo

@export var largura := 3600.0
@export var altura := 660.0
@export var topo := -60.0
@export var esquerda := -80.0
## Grossura (em células) das bordas de tiles.
@export var borda_tiles := 3
## Desenhar também uma faixa de tiles no fundo do nível (chão de segurança
## por baixo de tudo, para não se ver o vazio).
@export var chao := true
@export var chao_y := 720.0

# coords no atlas do masmorra.tres (col, row)
const T_PAREDE := Vector2i(2, 1)   # wall_mid
const T_PAREDE_L := Vector2i(1, 1) # wall_left
const T_PAREDE_R := Vector2i(3, 1) # wall_right
const T_TOPO := Vector2i(2, 0)     # wall_top_mid (banda iluminada)
const T_FLOOR := Vector2i(2, 4)    # floor_1
const T_FUNDO := Vector2i(3, 2)    # wall_hole_1 (buraco escuro na parede)


func _ready() -> void:
	_construir()


func _construir() -> void:
	for c in get_children():
		c.queue_free()

	var tml := TileMapLayer.new()
	tml.name = "Tiles"
	tml.tile_set = TSET
	tml.scale = Vector2(ESCALA, ESCALA)
	tml.z_index = -2   # à frente do parallax, atrás dos atores/plataformas
	tml.position = Vector2(esquerda, topo)
	add_child(tml)

	# grelha em células de 16 (coords locais do tilemap, antes da escala)
	var cols := int(ceil(largura / CEL))
	var rows := int(ceil(altura / CEL))
	var b := maxi(1, borda_tiles)

	for cx in range(-b, cols + b):
		for cy in range(-b, rows + b):
			var borda := cx < 0 or cx >= cols or cy < 0
			if not borda:
				continue
			var at := T_PAREDE
			if cy < 0 and cx >= 0 and cx < cols:
				at = T_TOPO if cy == -1 else T_PAREDE
			elif cx < 0:
				at = T_PAREDE_R if cx == -1 else T_PAREDE
			elif cx >= cols:
				at = T_PAREDE_L if cx == cols else T_PAREDE
			tml.set_cell(Vector2i(cx, cy), 0, at)

	# nichos/buracos esparsos nas paredes laterais (decoração discreta)
	for cy in range(2, rows - 2, 5):
		tml.set_cell(Vector2i(-1, cy), 0, T_FUNDO)
		tml.set_cell(Vector2i(cols, cy + 2), 0, T_FUNDO)

	# chão de tiles no fundo do nível
	if chao:
		var y0 := int(floor((chao_y - topo) / CEL))
		for cx in range(-b, cols + b):
			tml.set_cell(Vector2i(cx, y0), 0, T_TOPO)
			for cy in range(y0 + 1, y0 + 1 + b):
				tml.set_cell(Vector2i(cx, cy), 0, T_FLOOR)

	# --- colisão: tecto + parede esq + parede dir -------------------------
	var esp := float(b) * CEL
	_parede("Tecto", Vector2(esquerda + largura * 0.5, topo - esp * 0.5),
		Vector2(largura + esp * 2.0, esp))
	_parede("ParedeEsq", Vector2(esquerda - esp * 0.5, topo + altura * 0.5),
		Vector2(esp, altura + esp * 2.0))
	_parede("ParedeDir", Vector2(esquerda + largura + esp * 0.5, topo + altura * 0.5),
		Vector2(esp, altura + esp * 2.0))
	if chao:
		_parede("ChaoFundo", Vector2(esquerda + largura * 0.5, chao_y + esp * 0.5),
			Vector2(largura + esp * 2.0, esp))


func _parede(nome: String, centro: Vector2, tam: Vector2) -> void:
	var sb := StaticBody2D.new()
	sb.name = nome
	sb.collision_layer = 1
	sb.collision_mask = 0
	sb.position = centro
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = tam
	cs.shape = rs
	sb.add_child(cs)
	add_child(sb)
