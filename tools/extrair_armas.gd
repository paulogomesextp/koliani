extends SceneTree
## Extrai 15 lâminas do pack CC0 `thewisehedgehog` (grelha 6x5 de 32x32 em
## `assets/sprites/incoming/thewisehedgehog/File (1).png`) para a tira que a
## Koliani segura -- `assets/sprites/pixel/gear/armas.png` (15 frames de
## 32x32). Também imprime a COR dominante de cada lâmina, para colar em
## `Equipamento.COR_ARMA` (o brilho/efeitos do golpe seguem essa cor).
##
##   godot --headless --script res://tools/extrair_armas.gd
##
## O ficheiro-fonte vive em `incoming/` (.gdignore, fora do git); a tira
## gerada é que fica no repo. Creditar em assets/sprites/pixel/CREDITS.md.

const FONTE := "res://assets/sprites/incoming/thewisehedgehog/File (1).png"
const DESTINO := "res://assets/sprites/pixel/gear/armas.png"
const CEL := 32

## Índice na grelha (linha*6 + coluna) da lâmina de cada uma das 15 armas
## de `Equipamento.ARMAS`, por ordem.
const SEL := [17, 20, 9, 2, 18, 4, 29, 12, 5, 21, 7, 28, 15, 19, 6]


func _init() -> void:
	var src := Image.load_from_file(FONTE)
	if src == null:
		push_error("não abriu " + FONTE)
		quit(1)
		return
	var cols := int(src.get_width() / CEL)   # 6
	var n := SEL.size()
	var out := Image.create(n * CEL, CEL, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	var linha_cores := PackedStringArray()
	for i in n:
		var idx: int = SEL[i]
		var c := idx % cols
		var r := int(idx / cols)
		var reg := Rect2i(c * CEL, r * CEL, CEL, CEL)
		# as lâminas do pack apontam para CIMA-ESQUERDA (pega em baixo-direita);
		# a Koliani vira-se para a DIREITA -> espelha para a pega ficar na mão
		# e a lâmina apontar para cima-frente.
		var cel := src.get_region(reg)
		cel.flip_x()
		out.blit_rect(cel, Rect2i(0, 0, CEL, CEL), Vector2i(i * CEL, 0))
		linha_cores.append(_cor_str(src, reg))

	var err := out.save_png(ProjectSettings.globalize_path(DESTINO))
	print("armas.png  %dx%d  err=%d" % [out.get_width(), out.get_height(), err])
	print("COR_ARMA (colar em equipamento.gd):")
	print("const COR_ARMA: Array[Color] = [")
	for s in linha_cores:
		print("\t%s," % s)
	print("]")
	quit(0)


## Cor "dominante" de um recorte: média ponderada pela saturação dos pixels
## com alfa alto e luminância média (ignora contorno preto e brilhos brancos).
func _cor_str(img: Image, reg: Rect2i) -> String:
	var sr := 0.0
	var sg := 0.0
	var sb := 0.0
	var peso := 0.0
	for y in range(reg.position.y, reg.position.y + reg.size.y):
		for x in range(reg.position.x, reg.position.x + reg.size.x):
			var p := img.get_pixel(x, y)
			if p.a < 0.6:
				continue
			var lum := 0.3 * p.r + 0.59 * p.g + 0.11 * p.b
			if lum < 0.22 or lum > 0.95:
				continue
			var mx: float = max(p.r, max(p.g, p.b))
			var mn: float = min(p.r, min(p.g, p.b))
			var sat := (mx - mn) / maxf(mx, 0.001)
			var w := 0.15 + sat
			sr += p.r * w
			sg += p.g * w
			sb += p.b * w
			peso += w
	if peso <= 0.0:
		return "Color(0.8, 0.8, 0.85)"
	# realça um pouco para servir de cor de brilho
	var col := Color(sr / peso, sg / peso, sb / peso).lerp(Color(1, 1, 1), 0.12)
	return "Color(%.2f, %.2f, %.2f)" % [col.r, col.g, col.b]
