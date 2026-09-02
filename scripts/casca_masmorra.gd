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
## Água morta a cobrir o fundo (só quando `chao`): cair num fosso = morte
## instantânea e reaparecer no checkpoint, em vez de ficar preso no chão da
## Casca. A superfície fica logo acima do `chao_y`, bem abaixo de qualquer
## plataforma jogável.
@export var agua := true
@export var agua_cor := Color(0.15, 0.3, 0.36, 0.62)

const CENA_AGUA := preload("res://scenes/actors/AguaVenenosa.tscn")

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

	# água morta logo por cima do chão da Casca -- cair num fosso mata em vez
	# de deixar a Koliani presa no fundo
	if chao and agua and not Engine.is_editor_hint():
		# superfície ~40 px acima do chão da Casca (fica bem abaixo de
		# qualquer plataforma jogável mas apanha quem caia no fosso ANTES de
		# assentar no chão da Casca)
		var ag := CENA_AGUA.instantiate()
		ag.name = "AguaFundo"
		ag.largura = largura + esp * 2.0
		ag.altura = 240.0
		ag.cor = agua_cor
		ag.position = Vector2(esquerda + largura * 0.5, chao_y + 80.0)
		ag.z_index = -1
		add_child(ag)


## Recua a parede esquerda de colisão (e estica o chão de fundo + pinta
## tecto/chão em tiles) até `novo_x`, para dar lugar a um gauntlet
## prependido pelo `GeradorCorredor`. Chamado no _ready dele.
func abrir_esquerda(novo_x: float) -> void:
	if novo_x >= esquerda:
		return
	var b := maxi(1, borda_tiles)
	var esp := float(b) * CEL

	var pe := get_node_or_null("ParedeEsq") as StaticBody2D
	if pe:
		pe.position.x = novo_x - esp * 0.5

	if chao:
		var cf := get_node_or_null("ChaoFundo") as StaticBody2D
		if cf and cf.get_child_count() > 0:
			var cs := cf.get_child(0) as CollisionShape2D
			if cs and cs.shape is RectangleShape2D:
				var rs: RectangleShape2D = cs.shape
				var dir_x := esquerda + largura + esp
				rs.size.x = dir_x - (novo_x - esp)
				cf.position.x = (novo_x - esp + dir_x) * 0.5

	var tml := get_node_or_null("Tiles") as TileMapLayer
	if tml:
		var cx0 := int(floor((novo_x - esquerda) / CEL)) - b
		var y0 := int(floor((chao_y - topo) / CEL))
		for cx in range(cx0, 0):
			# limpa a coluna TODA primeiro: estas colunas (cx<0) tinham a
			# parede esquerda ORIGINAL pintada do tecto ao chão em
			# `_construir()`; só repintar as bandas do tecto/chão a seguir
			# deixava o MEIO da parede antiga por tirar -- em masmorras
			# altas (ex.: Fornalha dos Pecadores) isso bloqueava a sala a
			# meio, mesmo com a colisão `ParedeEsq` já deslocada (o
			# tileset tem colisão própria por tile).
			for cy in range(-b, y0 + 1 + b):
				tml.erase_cell(Vector2i(cx, cy))
			tml.set_cell(Vector2i(cx, -1), 0, T_TOPO)
			tml.set_cell(Vector2i(cx, -2), 0, T_PAREDE)
			if chao:
				tml.set_cell(Vector2i(cx, y0), 0, T_TOPO)
				for cy in range(y0 + 1, y0 + 1 + b):
					tml.set_cell(Vector2i(cx, cy), 0, T_FLOOR)


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
