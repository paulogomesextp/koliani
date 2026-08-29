extends SceneTree
## Gera os sprites PIXEL-ART do jogo em `assets/sprites/pixel/*.png` a
## partir de primitivas (rect / elipse / linha) + paleta fechada + contorno
## automatico + sombra de topo. Sem downloads, sem dependencias -- CC0 nosso,
## no espirito do `tools/gerar_audio.py`.
##
##   godot --headless --script res://tools/gerar_sprites.gd
##   godot --headless --import        # gera os .import
##
## Se aparecer um pack CC0 externo melhor, troca-se so' o `texture=` das
## cenas -- estes ficheiros sao o fallback.

const DIR := "res://assets/sprites/pixel"

# paleta gotica / luar / magenta (do key art)
const PAL := {
	"o": Color("0a0a12"),  # contorno
	"x": Color("15121d"),  # sombra profunda
	"p": Color("241d38"),  # roxo-cinza medio
	"P": Color("3a3057"),  # roxo-cinza claro
	"W": Color("6b5f8f"),  # realce frio
	"k": Color("d7c6ac"),  # pele
	"s": Color("a9896b"),  # pele sombra
	"h": Color("3a1326"),  # cabelo
	"m": Color("ff45ef"),  # magenta vivo
	"M": Color("b023cf"),  # magenta medio
	"w": Color("ffe0ff"),  # brilho
	"g": Color("74d44e"),  # verde-veneno
	"G": Color("2e4f22"),  # verde escuro
	"t": Color("14200b"),  # tronco escuro
	"T": Color("223a19"),  # tronco medio
	"b": Color("c9b79a"),  # osso
}

var _img: Image
var _w := 0
var _h := 0


func _initialize() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	_koliani()
	_ghorak()
	_demonio()
	print("OK -- sprites pixel-art em ", DIR)
	quit(0)


## --- utilitarios de desenho ------------------------------------------

func _novo(w: int, h: int) -> void:
	_w = w
	_h = h
	_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0, 0, 0, 0))


func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and x < _w and y >= 0 and y < _h:
		_img.set_pixel(x, y, c)


## Desenha a partir de um "mapa" de linhas de texto (1 char = 1 pixel).
## `leg` mapeia char -> Color; espaço = transparente.
func _mapa(linhas: PackedStringArray, leg: Dictionary) -> void:
	var h := linhas.size()
	var w := 0
	for l in linhas:
		w = maxi(w, l.length())
	_novo(w, h)
	for j in h:
		var linha: String = linhas[j]
		for i in linha.length():
			var ch := linha[i]
			if leg.has(ch):
				_img.set_pixel(i, j, leg[ch])


func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			_px(i, j, c)


func _elipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for j in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for i in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var dx := (i + 0.5 - cx) / maxf(rx, 0.001)
			var dy := (j + 0.5 - cy) / maxf(ry, 0.001)
			if dx * dx + dy * dy <= 1.0:
				_px(i, j, c)


func _linha(x0: int, y0: int, x1: int, y1: int, grossura: int, c: Color) -> void:
	var passos := maxi(absi(x1 - x0), absi(y1 - y0))
	for s in range(passos + 1):
		var f := float(s) / float(maxi(passos, 1))
		var x := int(round(lerpf(x0, x1, f)))
		var y := int(round(lerpf(y0, y1, f)))
		_rect(x - grossura / 2, y - grossura / 2, grossura, grossura, c)


func _sombra_topo() -> void:
	for i in _w:
		var primeiro := -1
		var ultimo := -1
		for j in _h:
			if _img.get_pixel(i, j).a > 0.5:
				if primeiro < 0:
					primeiro = j
				ultimo = j
		if primeiro >= 0:
			_img.set_pixel(i, primeiro, _img.get_pixel(i, primeiro).lightened(0.16))
			if ultimo > primeiro:
				_img.set_pixel(i, ultimo, _img.get_pixel(i, ultimo).darkened(0.22))


func _contorno() -> void:
	var fora: Color = PAL["o"]
	var base := _img.duplicate() as Image
	var viz := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for j in _h:
		for i in _w:
			if base.get_pixel(i, j).a > 0.5:
				continue
			for d: Vector2i in viz:
				var nx := i + d.x
				var ny := j + d.y
				if nx >= 0 and nx < _w and ny >= 0 and ny < _h and base.get_pixel(nx, ny).a > 0.5:
					_img.set_pixel(i, j, fora)
					break


func _guardar(nome: String) -> void:
	_sombra_topo()
	_contorno()
	var caminho := "%s/%s.png" % [DIR, nome]
	var err := _img.save_png(caminho)
	print("  ", nome, "  ", _w, "x", _h, "  err=", err)
	# preview x8 (nearest) so' para inspecao -- nao usado pelo jogo
	if OS.get_environment("PREVIEW") == "1":
		var big := _img.duplicate() as Image
		big.resize(_w * 8, _h * 8, Image.INTERPOLATE_NEAREST)
		big.save_png("%s/_preview_%s.png" % [DIR, nome])


## --- sprites ---------------------------------------------------------

func _koliani() -> void:
	# mapa de pixels feito a' mao. Vista 3/4 virada a' esquerda, capuz,
	# rabo-de-cavalo, capa que abre, adaga magenta a brilhar em baixo.
	#  c capa escura  C capa media  v capa clara  l rim (luz fria)
	#  k pele  s pele sombra  r cabelo/cachecol  e olho
	#  B brilho lamina  b nucleo lamina
	var leg := {
		"c": PAL["x"], "C": PAL["p"], "v": PAL["P"], "l": PAL["W"],
		"t": Color("4a3a68"),  # painel da tunica (frente)
		"k": PAL["k"], "s": PAL["s"], "r": PAL["h"], "e": PAL["m"],
		"B": PAL["M"], "b": PAL["w"],
	}
	_mapa(PackedStringArray([
		"                                  ",
		"              cccc                ",
		"            ccCCCCcc              ",
		"           cCCCvvvCCc             ",
		"          clCCvvvvvCCc            ",
		"          clCvvvvvvvCc   r        ",
		"          clCvkkkkkvCc  rrr       ",
		"          clCvkksskvCc  rrrr      ",
		"          clCkkkseekCc rrrrr      ",
		"          clCkksseekCc rrrrr      ",
		"          clCkkksskvCc rrrrr      ",
		"          clCvkkkkkvCc rrrrr      ",
		"           clCvkkkvCc  rrrrr      ",
		"           clCCvvvCCc  rrrr       ",
		"           clCCvvvCCc  rrrr       ",
		"            clCCvCCc  rrrr        ",
		"            crrCCrrc rrrr         ",
		"           crrrCCrrrrrrr          ",
		"          ccCCCCCCCCcrr           ",
		"         clCCCvvvvCCCc            ",
		"         clCCvvttvvCCc            ",
		"        clCCvvttttvvCc            ",
		"    r   clCCvttttttvCc            ",
		"  rBr   cCCvttttttvCCc            ",
		" rBbBr scCvttttttvCCc            ",
		" rBbBr ksCvtttttttvCc            ",
		"  rBbBrksCvttttttvCCc             ",
		"   rBbrksCvtttttvvCCc             ",
		"    rbksCCvttttvvCCc              ",
		"     bksCCvtttvvvCCc              ",
		"      sCCCvvttvvvCCc              ",
		"      cCCCvvttvvCCCc              ",
		"      cCCCvvttvvCCCc              ",
		"      cCCCvvttvvCCCc              ",
		"      cCCCCvttvCCCCc              ",
		"      cCCCCvttvCCCCc              ",
		"      ccCCCvttvCCCcc              ",
		"       cCCCvttvCCCc               ",
		"       cCCCc  cCCCc               ",
		"       cCCc    cCCc               ",
		"       cCCc    cCCc               ",
		"       cCc      cCc               ",
		"       cCc      cCc               ",
		"      ccCc      cCcc              ",
		"      cccc      cccc              ",
		"                                 ",
	]), leg)
	_guardar("koliani")


func _ghorak() -> void:
	_novo(104, 116)
	# raizes-pernas
	_linha(30, 84, 20, 114, 12, PAL["t"])
	_linha(74, 84, 84, 114, 12, PAL["t"])
	_linha(50, 88, 46, 114, 9, PAL["T"])
	_linha(54, 88, 60, 114, 9, PAL["T"])
	# bracos de raiz
	_elipse(10, 52, 10, 9, PAL["t"])
	_elipse(94, 52, 10, 9, PAL["t"])
	# ombros / massa de raizes
	_elipse(18, 34, 15, 14, PAL["G"])
	_elipse(86, 34, 15, 14, PAL["G"])
	# tronco
	_elipse(52, 48, 28, 38, PAL["t"])
	_elipse(52, 46, 22, 30, PAL["T"])
	# fendas
	_linha(40, 16, 36, 74, 2, PAL["t"])
	_linha(64, 18, 68, 74, 2, PAL["t"])
	# cavidade do peito + nucleo
	_elipse(52, 46, 13, 14, PAL["x"])
	_elipse(52, 46, 6, 7, PAL["M"])
	_elipse(52, 46, 3, 4, PAL["m"])
	_px(52, 45, PAL["w"])
	# costelas de osso
	_linha(39, 40, 39, 58, 2, PAL["b"])
	_linha(65, 40, 65, 58, 2, PAL["b"])
	# cranio embutido
	_elipse(52, 18, 13, 10, PAL["G"])
	_elipse(52, 20, 6, 5, PAL["g"])
	_px(50, 19, PAL["w"])
	_px(54, 19, PAL["w"])
	_guardar("ghorak")


func _demonio() -> void:
	_novo(40, 44)
	# corpo
	_elipse(20, 27, 13, 14, PAL["G"])
	_elipse(20, 25, 10, 10, PAL["T"])
	# cabeca
	_elipse(20, 14, 9, 8, PAL["G"])
	# membros
	_rect(9, 36, 5, 6, PAL["t"])
	_rect(26, 36, 5, 6, PAL["t"])
	# espinhos nas costas
	_linha(8, 20, 5, 14, 2, PAL["T"])
	_linha(32, 20, 35, 14, 2, PAL["T"])
	_linha(20, 6, 20, 1, 2, PAL["T"])
	# olho + infeccao magenta
	_elipse(20, 14, 4, 3, PAL["g"])
	_px(19, 13, PAL["w"])
	_px(14, 22, PAL["M"])
	_px(24, 24, PAL["M"])
	_px(18, 30, PAL["m"])
	_guardar("demonio")
