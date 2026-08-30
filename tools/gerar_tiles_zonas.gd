extends SceneTree
## Gera um bloco de terreno pixel-art DIFERENTE por regiao da campanha
## (`assets/sprites/pixel/tiles/<bioma>_block.png`, 96x96, 9-slice margem 12),
## a partir da folha "seamless" CC0 do `piiixl`
## (`incoming/piiixl/seamless patterns/16x16px/16x16_SpriteSheet.png`, 25x25
## celulas de 16px). Cada regiao apanha uma celula-base distinta (as 5 mais
## diferentes umas das outras) e leva um recolor proprio -- mas TODAS
## partilham a mesma identidade: aresta de luar + fio magenta no topo +
## flecos "fantasma" (tema do key_art). A `floresta` fica de fora: usa o
## `floresta_block.png` (relva Pixel Adventure) que ja e' distinto.
##
##   godot --headless --script res://tools/gerar_tiles_zonas.gd
##   (PREVIEW=1 grava tambem _preview_zonas.png com os 5 blocos lado a lado)

const FONTE := "res://assets/sprites/incoming/piiixl/seamless patterns/16x16px/16x16_SpriteSheet.png"
const DIR := "res://assets/sprites/pixel/tiles"
const CEL := 16
const N := 96                          # bloco final (6 celulas)
const LUAR := Color(0.86, 0.90, 1.0)   # aresta de topo iluminada (luar)
const RIM := Color(0.92, 0.52, 1.0)    # fio magenta na 1.a linha

## bioma -> [cor_da_pedra (meia-luz), cor_do_musgo_fantasma, escurecer_base]
## O padrao da celula-base entra so como RELEVO (claro/escuro); a cor e'
## sempre a da zona -- assim cada regiao tem material proprio mas on-theme.
const ZONAS := {
	"prisao":     [Color(0.35, 0.39, 0.54), Color(0.60, 0.72, 1.00), 0.10],
	"torres":     [Color(0.53, 0.54, 0.66), Color(0.86, 0.88, 1.00), 0.07],
	"catacumbas": [Color(0.37, 0.45, 0.40), Color(0.58, 0.95, 0.74), 0.11],
	"cidade":     [Color(0.49, 0.34, 0.49), Color(1.00, 0.58, 0.94), 0.09],
	"castelo":    [Color(0.48, 0.33, 0.62), Color(0.92, 0.52, 1.00), 0.05],
}


func _init() -> void:
	var src := Image.load_from_file(FONTE)
	if src == null:
		push_error("nao abriu " + FONTE); quit(1); return
	var cols := src.get_width() / CEL
	var rows := src.get_height() / CEL

	# --- 1. cataloga as celulas com textura util -------------------------
	var cands: Array = []
	for cy in rows:
		for cx in cols:
			var cell := src.get_region(Rect2i(cx * CEL, cy * CEL, CEL, CEL))
			var soma := Vector3.ZERO
			var soma2 := Vector3.ZERO
			var opac := 0
			for y in CEL:
				for x in CEL:
					var p := cell.get_pixel(x, y)
					if p.a > 0.95:
						opac += 1
					var v := Vector3(p.r, p.g, p.b)
					soma += v
					soma2 += Vector3(v.x * v.x, v.y * v.y, v.z * v.z)
			if opac < CEL * CEL - 4:
				continue
			var media := soma / float(CEL * CEL)
			var varr := (soma2 / float(CEL * CEL)) - Vector3(media.x * media.x, media.y * media.y, media.z * media.z)
			var desvio := (sqrt(maxf(varr.x, 0.0)) + sqrt(maxf(varr.y, 0.0)) + sqrt(maxf(varr.z, 0.0))) / 3.0
			var luma := media.x * 0.3 + media.y * 0.59 + media.z * 0.11
			var mx_c := maxf(media.x, maxf(media.y, media.z))
			var mn_c := minf(media.x, minf(media.y, media.z))
			var sat := (mx_c - mn_c) / maxf(mx_c, 0.001)
			# so' pedra/tijolo/calcada: pouca cor, com relevo, nem chapada nem ruido
			if luma < 0.08 or luma > 0.66 or desvio < 0.05 or desvio > 0.16 or sat > 0.30:
				continue
			cands.append({"pos": Vector2i(cx, cy), "media": media, "desvio": desvio})

	if cands.size() < ZONAS.size():
		push_error("poucas celulas-candidatas (%d)" % cands.size()); quit(1); return

	# --- 2. as 5 celulas de padrao mais rico, mas espalhadas pela folha --
	# padroes de detalhe MODERADO (nem chapados nem ruido) leem-se melhor
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return absf(a["desvio"] - 0.10) < absf(b["desvio"] - 0.10))
	var escolhidas: Array = []
	for c in cands:
		var longe := true
		for e in escolhidas:
			var dp: Vector2i = c["pos"] - e["pos"]
			if maxi(absi(dp.x), absi(dp.y)) <= 2:
				longe = false
				break
		if longe:
			escolhidas.append(c)
		if escolhidas.size() == ZONAS.size():
			break
	while escolhidas.size() < ZONAS.size():   # fallback: enche com o que houver
		escolhidas.append(cands[escolhidas.size()])

	# --- 3. recolor por zona + grava ----------------------------------
	var previa: Image = null
	var quero_previa := OS.get_environment("PREVIEW") == "1"
	if quero_previa:
		previa = Image.create(N * ZONAS.size(), N, false, Image.FORMAT_RGBA8)

	var i := 0
	for bioma: String in ZONAS:
		var conf: Array = ZONAS[bioma]
		var tinta: Color = conf[0]
		var musgo: Color = conf[1]
		var escurecer: float = conf[2]
		var base_pos: Vector2i = escolhidas[i]["pos"]
		var base := src.get_region(Rect2i(base_pos.x * CEL, base_pos.y * CEL, CEL, CEL))
		var out := Image.create(N, N, false, Image.FORMAT_RGBA8)

		# a celula-base entra so' como RELEVO: a luminancia do padrao modula
		# a cor-pedra da zona (claro = saliencia, escuro = junta).
		for y in N:
			for x in N:
				var p := base.get_pixel(x % CEL, y % CEL)
				var l := p.r * 0.3 + p.g * 0.59 + p.b * 0.11
				var relevo := clampf(0.72 + (l - 0.42) * 1.9, 0.40, 1.30)
				var c := Color(tinta.r * relevo, tinta.g * relevo, tinta.b * relevo, 1.0)
				var f := float(y) / float(N - 1)
				c = c.lerp(Color(0, 0, 0, 1), f * escurecer)
				out.set_pixel(x, y, c)

		for x in N:
			out.set_pixel(x, 0, out.get_pixel(x, 0).lerp(RIM, 0.55))
			out.set_pixel(x, 1, out.get_pixel(x, 1).lerp(LUAR, 0.5))
			out.set_pixel(x, 2, out.get_pixel(x, 2).lerp(LUAR, 0.22))

		var rng := RandomNumberGenerator.new()
		rng.seed = hash("musgo|" + bioma)
		for _k in 30:
			var mx := rng.randi_range(1, N - 2)
			var my := rng.randi_range(6, N - 3)
			out.set_pixel(mx, my, out.get_pixel(mx, my).lerp(musgo, 0.7))
			if rng.randf() < 0.5:
				out.set_pixel(mx, my + 1, out.get_pixel(mx, my + 1).lerp(musgo, 0.4))

		var caminho := "%s/%s_block.png" % [DIR, bioma]
		var err := out.save_png(ProjectSettings.globalize_path(caminho))
		print("%-11s <- celula %s  err=%d" % [bioma, base_pos, err])
		if previa:
			previa.blit_rect(out, Rect2i(0, 0, N, N), Vector2i(i * N, 0))
		i += 1

	if previa:
		previa.save_png(ProjectSettings.globalize_path("res://_preview_zonas.png"))
		print("previa -> res://_preview_zonas.png")
	quit(0)
