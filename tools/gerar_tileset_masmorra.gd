@tool
extends SceneTree
## Gera `res://assets/tiles/masmorra.tres` a partir do atlas CC0
## `assets/sprites/pixel/tiles/dungeon_0x72.png` (0x72 DungeonTileset II,
## grelha 16x16). TileSet com uma camada de física (colisão = "mundo"/bit 1)
## e colisão de quadrado cheio nos tiles estruturais (chão, paredes, tecto).
## Os tiles decorativos (estandartes, buracos, escadas) ficam sem colisão.
##
## Correr:  godot --headless --script res://tools/gerar_tileset_masmorra.gd
## Depois:  godot --headless --import

const ATLAS := "res://assets/sprites/pixel/tiles/dungeon_0x72.png"
const SAIDA := "res://assets/tiles/masmorra.tres"
const TILE := 16

## coords (coluna, linha) na grelha 16x16 do atlas -> tem colisão?
const TILES := {
	# chão (variantes) -- topo sólido
	"floor_1": [Vector2i(1, 4), true],
	"floor_2": [Vector2i(2, 4), true],
	"floor_3": [Vector2i(3, 4), true],
	"floor_4": [Vector2i(1, 5), true],
	"floor_5": [Vector2i(2, 5), true],
	"floor_6": [Vector2i(3, 5), true],
	"floor_7": [Vector2i(1, 6), true],
	"floor_8": [Vector2i(2, 6), true],
	# topo de parede / superfície (banda iluminada)
	"wall_top_left": [Vector2i(1, 0), true],
	"wall_top_mid": [Vector2i(2, 0), true],
	"wall_top_right": [Vector2i(3, 0), true],
	# corpo de parede / tecto / bloco sólido
	"wall_left": [Vector2i(1, 1), true],
	"wall_mid": [Vector2i(2, 1), true],
	"wall_right": [Vector2i(3, 1), true],
	# decoração (sem colisão)
	"wall_banner_red": [Vector2i(1, 2), false],
	"wall_banner_blue": [Vector2i(2, 2), false],
	"wall_banner_green": [Vector2i(1, 3), false],
	"wall_hole_1": [Vector2i(3, 2), false],
	"wall_hole_2": [Vector2i(3, 3), false],
	"floor_ladder": [Vector2i(3, 6), false],
	"floor_stairs": [Vector2i(5, 12), false],
}


func _init() -> void:
	var tex: Texture2D = load(ATLAS)
	if tex == null:
		push_error("sem atlas em %s -- correr --import primeiro" % ATLAS)
		quit(1)
		return

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)  # "mundo"
	ts.set_physics_layer_collision_mask(0, 0)

	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)

	var meio := float(TILE) / 2.0
	var quadrado := PackedVector2Array([
		Vector2(-meio, -meio), Vector2(meio, -meio),
		Vector2(meio, meio), Vector2(-meio, meio),
	])

	for nome: String in TILES:
		var cfg: Array = TILES[nome]
		var coord: Vector2i = cfg[0]
		var solido: bool = cfg[1]
		src.create_tile(coord)
		if solido:
			var td := src.get_tile_data(coord, 0)
			td.set_collision_polygons_count(0, 1)
			td.set_collision_polygon_points(0, 0, quadrado)

	var err := ResourceSaver.save(ts, SAIDA)
	if err != OK:
		push_error("falha a gravar %s (err %d)" % [SAIDA, err])
		quit(1)
		return
	print("TileSet gravado -> ", SAIDA, "  (", TILES.size(), " tiles)")
	quit()
