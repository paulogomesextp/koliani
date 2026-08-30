extends SceneTree
## Constrói o bloco de terreno GÓTICO das plataformas
## (`assets/sprites/pixel/tiles/pedra_gotica_block.png`, 96x96, 9-slice com
## margem 11) a partir de uma pedra "seamless" do pack CC0 `piiixl`
## (`incoming/piiixl/seamless patterns/16x16px/16x16_SpriteSheet.png`,
## célula 0,0 = calçada azul-escura). Recolor frio + rebordo de luar
## magenta + musgo fantasma. Fonte em incoming/ (.gdignore); o PNG gerado
## é que fica no repo.
##
##   godot --headless --script res://tools/gerar_tiles_goticos.gd

const FONTE := "res://assets/sprites/incoming/piiixl/seamless patterns/16x16px/16x16_SpriteSheet.png"
const DESTINO := "res://assets/sprites/pixel/tiles/pedra_gotica_block.png"
const N := 96
const CEL := 16

# recolor: pedra-cripta violeta, mas SEM escurecer de mais (o `modulate`
# do bioma ainda multiplica por cima).
const MUL := Color(0.92, 0.94, 1.05)
const TINTA := Color(0.34, 0.30, 0.44)
const LUAR := Color(0.88, 0.92, 1.0)        # aresta de topo iluminada
const RIM := Color(0.92, 0.52, 1.0)         # fio magenta no topo
const MUSGO := Color(0.72, 0.38, 0.85)      # flecos "fantasma"


func _init() -> void:
	var src := Image.load_from_file(FONTE)
	if src == null:
		push_error("não abriu " + FONTE)
		quit(1)
		return
	var cobble := src.get_region(Rect2i(0, 0, CEL, CEL))
	var out := Image.create(N, N, false, Image.FORMAT_RGBA8)

	for y in N:
		for x in N:
			var p := cobble.get_pixel(x % CEL, y % CEL)
			var c := Color(p.r * MUL.r, p.g * MUL.g, p.b * MUL.b, 1.0)
			c = c.lerp(TINTA, 0.30)
			# gradiente vertical: topo mais claro, base ligeiramente em sombra
			var f := float(y) / float(N - 1)
			c = c.lerp(Color(0, 0, 0, 1), f * 0.16)
			out.set_pixel(x, y, c)

	# aresta de luar no topo + fio magenta na 1.ª linha
	for x in N:
		var t0 := out.get_pixel(x, 0)
		out.set_pixel(x, 0, t0.lerp(RIM, 0.55))
		out.set_pixel(x, 1, out.get_pixel(x, 1).lerp(LUAR, 0.5))
		out.set_pixel(x, 2, out.get_pixel(x, 2).lerp(LUAR, 0.22))

	# musgo fantasma: uns flecos magenta pseudo-aleatórios
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x60771C
	for _i in 26:
		var mx := rng.randi_range(1, N - 2)
		var my := rng.randi_range(6, N - 3)
		out.set_pixel(mx, my, out.get_pixel(mx, my).lerp(MUSGO, 0.7))
		if rng.randf() < 0.5:
			out.set_pixel(mx, my + 1, out.get_pixel(mx, my + 1).lerp(MUSGO, 0.4))

	var err := out.save_png(ProjectSettings.globalize_path(DESTINO))
	print("pedra_gotica_block.png  %dx%d  err=%d" % [N, N, err])
	quit(0)
