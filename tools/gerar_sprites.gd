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
	# Vista lateral, VIRADA A' DIREITA (o flip do jogo faz `scale.x =
	# +olha_para` -> sem espelho = a olhar p/ a direita). Construida por
	# primitivas + rim frio no bordo da frente/topo + adaga magenta acesa.
	_novo(30, 44)
	var CAPA_ESC: Color = PAL["x"]
	var CAPA: Color = PAL["p"]
	var CAPA_CLR: Color = PAL["P"]
	var TUNICA := Color("5f4b95")
	var PELE: Color = PAL["k"]
	var PELE_S: Color = PAL["s"]
	var CAB := Color("3a1326")
	var CAB_R := Color("6a2440")
	var RIM := Color("bcabe8")   # luar frio -- destaca a silhueta

	# --- tronco+capa: trapezio (ombros ~9 -> orla ~17), orla a cair p/ tras
	for j in range(14, 33):
		var f := float(j - 14) / 18.0
		var meia := lerpf(4.5, 8.5, f)
		var cx := 15.5 - f * 1.2
		_rect(int(round(cx - meia)), j, int(round(meia * 2.0)), 1, CAPA)
	# vinco/dobras da capa (risca escura de cada lado) -- ANTES do painel
	_linha(11, 17, 10, 31, 1, CAPA_ESC)
	_linha(20, 17, 22, 31, 1, CAPA_ESC)
	# painel da tunica: barra vertical clara ao centro (por cima do vinco)
	for j in range(15, 31):
		var f := float(j - 15) / 15.0
		var meia := lerpf(2.5, 3.6, f)
		_rect(int(round(15.0 - meia)), j, int(round(meia * 2.0)), 1, TUNICA)

	# --- pernas (passada leve), por cima da orla ---
	_rect(10, 33, 4, 9, CAPA); _rect(9, 41, 5, 2, CAPA_ESC)    # perna tras
	_rect(17, 33, 5, 10, CAPA); _rect(17, 42, 6, 2, CAPA_ESC)  # perna frente
	_px(21, 42, CAPA_CLR)

	# --- cabeca com capuz (compacta) ---
	_elipse(16, 8, 6.5, 7, CAPA)         # capuz
	_linha(15, 1, 20, 5, 3, CAPA)        # bico do capuz
	_rect(17, 7, 4, 5, PELE_S)           # abertura da cara (em sombra)
	_rect(18, 9, 3, 3, PELE)             # face iluminada (bochecha/queixo)
	_rect(17, 6, 5, 1, CAPA_ESC)         # sombra da aba sobre a testa
	# olho magenta
	_px(19, 9, PAL["m"]); _px(20, 9, PAL["m"])

	# --- ombro/gola da capa (fecha o pescoco) ---
	_rect(11, 12, 10, 3, CAPA)
	_px(12, 12, CAPA_CLR); _px(19, 12, CAPA_CLR)

	# --- braco da frente + adaga (manga por cima da gola) ---
	_linha(19, 15, 24, 24, 3, CAPA)
	_elipse(24, 25, 2.5, 2.5, PELE)      # mao

	# --- rim de luar no bordo da frente/topo (tronco+cabeca; a orla e as
	#     pernas ficam de fora) ---
	_rim_frente(RIM, 0, 26)

	# --- rabo-de-cavalo: DEPOIS do rim, p/ ficar limpo ---
	_linha(11, 6, 7, 12, 4, CAB)
	_linha(7, 12, 5, 20, 3, CAB)
	_linha(5, 20, 5, 25, 2, CAB_R)
	_px(10, 7, CAB_R); _px(8, 11, CAB_R); _px(6, 17, CAB_R)

	# --- lamina: nucleo branco-quente + halo magenta, p/ baixo-frente ---
	_linha(25, 26, 29, 37, 3, PAL["M"])
	_linha(25, 26, 29, 37, 1, PAL["w"])
	_px(24, 24, PAL["M"]); _px(25, 25, PAL["m"])
	_px(29, 38, PAL["w"])                # faisca na ponta

	_guardar("koliani")


## Realca o bordo superior e o bordo direito (frente) da silhueta com `cor`,
## 1px para dentro, para a leitura "recortada" tipo Dead Cells. `y0..y1`
## limita as linhas afetadas (evita apanhar o rabo-de-cavalo / a lamina).
func _rim_frente(cor: Color, y0: int = 0, y1: int = 9999) -> void:
	for i in _w:
		for j in _h:
			if _img.get_pixel(i, j).a > 0.5:
				if j >= y0 and j <= y1:
					_img.set_pixel(i, j, cor)
				break
	for j in range(maxi(0, y0), mini(_h, y1 + 1)):
		for i in range(_w - 1, -1, -1):
			if _img.get_pixel(i, j).a > 0.5:
				if j > 0 and _img.get_pixel(i, j - 1).a > 0.5:
					_img.set_pixel(i, j, cor)
				break


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
