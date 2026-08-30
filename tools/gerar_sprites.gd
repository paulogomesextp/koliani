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
	DirAccess.make_dir_recursive_absolute(abs_dir + "/bosses")
	_koliani()
	_ghorak()
	_demonio()
	# chefes da regiao I em pixel-art animado (tiras horizontais de 4 frames:
	# 0 idle A, 1 idle B, 2 telegrafo/ataque, 3 exposto). A tematica vem do
	# nome do nivel -- ver docs/niveis.md.
	_boss_coracao()
	_boss_entrevane()
	_boss_ghorak_anim()
	_boss_morvanna()
	_boss_rainha()
	_boss_ignivar()  # regiao II / nivel 07
	print("OK -- sprites pixel-art em ", DIR)
	quit(0)


## --- utilitarios de desenho ------------------------------------------

func _novo(w: int, h: int) -> void:
	_w = w
	_h = h
	_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0, 0, 0, 0))


## Deslocamento horizontal aplicado a `_px` -- serve para desenhar cada
## frame de uma tira num offset diferente (ver `_boss`).
var _ox := 0


func _px(x: int, y: int, c: Color) -> void:
	var xx := x + _ox
	if xx >= 0 and xx < _w and y >= 0 and y < _h:
		_img.set_pixel(xx, y, c)


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


## --- chefes pixel-art animados (regiao I) -------------------------------
##
## Cada chefe e' uma TIRA horizontal de 4 frames (fw x fh por frame).
## `desenhar.call(f)` desenha o frame f (0..3); o offset horizontal e'
## tratado por `_ox`. Convencao:
##   0 idle A   1 idle B (respira/oscila)   2 telegrafo/ataque   3 exposto
## O jogo poe `hframes = 4` no Sprite2D e o script troca `frame` conforme o
## estado. Sem shader -- contorno + sombra "baked".

func _boss(nome: String, fw: int, fh: int, desenhar: Callable) -> void:
	_novo(fw * 4, fh)
	for f in 4:
		_ox = f * fw
		desenhar.call(f)
	_ox = 0
	_sombra_topo()
	_contorno()
	var err := _img.save_png("%s/bosses/%s.png" % [DIR, nome])
	print("  boss ", nome, "  ", _w, "x", _h, "  err=", err)
	if OS.get_environment("PREVIEW") == "1":
		var big := _img.duplicate() as Image
		big.resize(_w * 6, _h * 6, Image.INTERPOLATE_NEAREST)
		big.save_png("%s/bosses/_preview_%s.png" % [DIR, nome])


## Nivel 05 -- Coracao da Floresta. Coracao purpura pulsante numa gaiola de
## raizes. Batida: 0 diastole (pequeno/apagado) -> 1 sistole (grande/aceso)
## -> 2 fase 2 (fendas radiais) -> 3 fase 3 (partido).
func _boss_coracao() -> void:
	var VEIA := Color("3a1140")
	var CARNE := Color("2a0c33")
	var CARNE_C := Color("5a1668")
	var CAIXA := Color("14090f")
	_boss("coracao", 96, 96, func(f: int) -> void:
		var cx := 48.0
		var cy := 46.0
		var esc: float = [0.86, 1.06, 1.02, 0.9][f]
		for a in 6:
			var ang := TAU * float(a) / 6.0
			_linha(int(cx), int(cy), int(cx + cos(ang) * 40.0), int(cy + sin(ang) * 40.0), 3, CAIXA)
		_linha(10, 30, 30, 66, 2, VEIA)
		_linha(86, 30, 66, 66, 2, VEIA)
		_elipse(16, 62, 4, 3, Color("0e0510"))
		_elipse(80, 60, 4, 3, Color("0e0510"))
		var rx := 22.0 * esc
		var ry := 20.0 * esc
		_elipse(cx - rx * 0.5, cy - ry * 0.3, rx * 0.62, ry * 0.62, CARNE)
		_elipse(cx + rx * 0.5, cy - ry * 0.3, rx * 0.62, ry * 0.62, CARNE)
		for j in int(ry * 1.3):
			var t := float(j) / (ry * 1.3)
			var meia := lerpf(rx * 0.95, 1.0, t)
			_rect(int(cx - meia), int(cy - ry * 0.1 + j), int(meia * 2.0), 1, CARNE)
		var brilho: Color = [Color("6a1a7a"), Color("ff8bf0"), Color("ffa0f5"), Color("c86bd8")][f]
		_elipse(cx, cy, 6.0 * esc, 6.5 * esc, CARNE_C)
		_elipse(cx, cy, 3.2, 3.6, brilho)
		_px(int(cx), int(cy - 1), PAL["w"])
		if f >= 1:
			_linha(int(cx), int(cy), int(cx) - 9, int(cy) + 12, 1, brilho)
			_linha(int(cx), int(cy), int(cx) + 8, int(cy) + 10, 1, brilho)
		if f == 2:
			_linha(int(cx) - 14, int(cy) - 10, int(cx) + 14, int(cy) + 12, 1, brilho)
			_linha(int(cx) + 14, int(cy) - 10, int(cx) - 12, int(cy) + 12, 1, brilho)
		if f == 3:
			_linha(int(cx) - 16, int(cy) - 14, int(cx) + 10, int(cy) + 18, 2, Color("0d0510"))
			_px(int(cx) + 16, int(cy) + 20, CARNE)
			_px(int(cx) - 18, int(cy) + 16, CARNE)
	)


## Nivel 04 -- A Arvore que Chora. Copa retorcida, tronco, raizes e um rosto
## que chora seiva acida. Frame 2 estende um galho; frame 3 abre o rosto.
func _boss_entrevane() -> void:
	var MAD := Color("241708")
	var MAD_E := Color("140c05")
	var FOLHA := Color("1a2a10")
	var SEIVA := Color("b6c64a")
	var SEIVA_C := Color("e8f2a0")
	_boss("entrevane", 96, 112, func(f: int) -> void:
		var sway: float = [0.0, 2.0, -1.0, 0.0][f]
		for e: Array in [[30, 26, 16, 12], [52, 20, 18, 13], [68, 30, 14, 11], [46, 34, 20, 12]]:
			_elipse(float(e[0]) + sway, e[1], e[2], e[3], MAD)
		for e: Array in [[38, 24, 10, 7], [58, 26, 9, 6]]:
			_elipse(float(e[0]) + sway, e[1], e[2], e[3], FOLHA)
		for j in range(38, 100):
			var t := float(j - 38) / 62.0
			var meia := lerpf(11.0, 15.0, t)
			var cx := 48.0 + sway * (1.0 - t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, MAD)
		_linha(48, 44, 47, 98, 2, MAD_E)
		_linha(38, 98, 22, 111, 4, MAD_E)
		_linha(58, 98, 74, 111, 4, MAD_E)
		_linha(48, 98, 48, 111, 4, MAD_E)
		if f == 2:
			_linha(60, 58, 92, 52, 4, MAD)
			_linha(74, 55, 88, 48, 2, SEIVA)
		else:
			_linha(58, 60, 70, 54, 4, MAD)
		var ry := 10.0 if f < 3 else 12.0
		_elipse(46 + sway, 60, 8.0, ry, MAD_E)
		if f == 3:
			_elipse(46, 58, 5.5, 7.0, Color("3a2a10"))
			_px(44, 56, SEIVA_C)
			_px(48, 56, SEIVA_C)
		else:
			_px(43 + int(sway), 57, MAD_E)
			_px(49 + int(sway), 57, MAD_E)
		var n := 4 if f == 3 else 2
		for d in n:
			_linha(43 + d * 3, 64, 43 + d * 3, 64 + (18 if f == 3 else 9), 1, SEIVA)
		if f == 3:
			_elipse(46, 62, 4, 4, SEIVA_C)
	)


## Nivel 01 -- O Caminho das Raizes Mortas. Ghorak: tronco, osso e raizes,
## nucleo purpura no peito. Frame 2 ergue os bracos; frame 3 abre o peito.
func _boss_ghorak_anim() -> void:
	_boss("ghorak", 104, 116, func(f: int) -> void:
		var bracos_cima := f == 2
		_linha(34, 84, 24, 114, 12, PAL["t"])
		_linha(70, 84, 80, 114, 12, PAL["t"])
		_linha(50, 88, 46, 114, 9, PAL["T"])
		_linha(54, 88, 60, 114, 9, PAL["T"])
		if bracos_cima:
			_linha(24, 44, 8, 18, 10, PAL["t"])
			_linha(80, 44, 96, 18, 10, PAL["t"])
			_elipse(8, 16, 9, 8, PAL["t"])
			_elipse(96, 16, 9, 8, PAL["t"])
		else:
			_elipse(12, 52, 10, 9, PAL["t"])
			_elipse(92, 52, 10, 9, PAL["t"])
		_elipse(20, 34, 15, 14, PAL["G"])
		_elipse(84, 34, 15, 14, PAL["G"])
		_elipse(52, 48, 27, 37, PAL["t"])
		_elipse(52, 46, 21, 29, PAL["T"])
		_linha(41, 16, 37, 74, 2, PAL["t"])
		_linha(63, 18, 67, 74, 2, PAL["t"])
		var rn: float = [6.0, 5.0, 8.0, 12.0][f]
		_elipse(52, 46, 13, 14, PAL["x"])
		_elipse(52, 46, rn * 0.55 + 3.0, rn * 0.6 + 3.0, PAL["M"])
		_elipse(52, 46, rn * 0.5, rn * 0.55, PAL["m"])
		_px(52, 45, PAL["w"])
		if f >= 2:
			_px(51, 47, PAL["w"])
			_px(53, 47, PAL["w"])
		_linha(40, 40, 40, 58, 2, PAL["b"])
		_linha(64, 40, 64, 58, 2, PAL["b"])
		_elipse(52, 18, 13, 10, PAL["G"])
		_elipse(52, 20, 6, 5, PAL["g"] if f != 2 else PAL["m"])
		_px(50, 19, PAL["w"])
		_px(54, 19, PAL["w"])
	)


## Nivel 02 -- Pantano dos Sussurros. Morvanna: chapeu largo, manto
## esfarrapado, fios de bruma em vez de pernas. Frame 2 ergue maos
## espectrais; frame 3 desce e a cara acende magenta.
func _boss_morvanna() -> void:
	var MANTO := Color("18202a")
	var MANTO_C := Color("2c3b48")
	var BRUMA := Color("4a7a58")
	var VERDE := Color("5fd48a")
	_boss("morvanna", 84, 104, func(f: int) -> void:
		var desce := 6 if f == 3 else 0
		for d in 5:
			var x := 26 + d * 8
			_linha(x, 66 + desce, x + (d - 2), 96, 2, BRUMA)
		for j in range(24 + desce, 74 + desce):
			var t := float(j - 24 - desce) / 50.0
			var meia := lerpf(9.0, 22.0, t)
			_rect(int(42 - meia), j, int(meia * 2.0), 1, MANTO)
		_linha(34, 60 + desce, 33, 74 + desce, 1, MANTO_C)
		_linha(50, 58 + desce, 52, 74 + desce, 1, MANTO_C)
		_linha(42, 62 + desce, 42, 74 + desce, 1, MANTO_C)
		_linha(20, 24 + desce, 64, 24 + desce, 4, MANTO)
		_linha(42, 24 + desce, 34, 2 + desce, 5, MANTO)
		_px(33, 2 + desce, MANTO_C)
		_elipse(42, 30 + desce, 6, 6, Color("101814"))
		var olho: Color = VERDE if f != 3 else PAL["m"]
		_px(40, 30 + desce, olho)
		_px(44, 30 + desce, olho)
		if f == 2:
			for hx: int in [24, 60]:
				var dx: int = 4 if hx < 42 else -4
				_linha(hx, 40, hx + dx, 20, 3, BRUMA)
				_linha(hx + dx, 20, hx + int(dx / 2.0), 12, 2, VERDE)
		if f == 3:
			_elipse(42, 46 + desce, 5, 6, PAL["M"])
			_elipse(42, 46 + desce, 2.5, 3, PAL["m"])
			_px(42, 45 + desce, PAL["w"])
	)


## Nivel 03 -- Ninho da Viuva Negra. A Rainha Aracnidea: abdomen com marca
## purpura, cefalotorax, 8 patas, rosto humano. Frame 2 ergue as patas da
## frente; frame 3 acende o rosto humano.
func _boss_rainha() -> void:
	var CORPO := Color("1b0f22")
	var CORPO_C := Color("2a1533")
	var PATA := Color("120a16")
	_boss("rainha", 104, 76, func(f: int) -> void:
		var cx := 52
		for s: int in [-1, 1]:
			for p: int in 4:
				var ax: int = cx + s * 12
				var ay: int = 40
				var bx: int = cx + s * (30 + p * 6)
				var by: int = 34 + p * 2 + (8 if p != 0 else 0)
				if f == 2 and p == 0:
					by = 8
					bx = cx + s * 20
				if f == 1:
					by += 3
				_linha(ax, ay, (ax + bx) / 2, ay - 6, 3, PATA)
				_linha((ax + bx) / 2, ay - 6, bx, by, 3, PATA)
		_elipse(cx, 44, 18, 15, CORPO)
		_elipse(cx, 44, 16, 13, CORPO_C)
		_linha(cx, 36, cx, 52, 4, Color("6a1f7d"))
		_px(cx, 44, PAL["m"])
		_elipse(cx, 26, 12, 10, CORPO)
		var cara: Color = Color("7a2b52") if f != 3 else Color("ffd0e6")
		_elipse(cx, 25, 7, 8, cara)
		var olho: Color = Color("2a1020") if f != 3 else PAL["m"]
		_px(cx - 2, 24, olho)
		_px(cx + 2, 24, olho)
		_linha(cx - 2, 29, cx + 2, 29, 1, Color("2a1020"))
		if f == 2:
			_linha(cx - 4, 34, cx - 6, 40, 2, Color("d8c0d0"))
			_linha(cx + 4, 34, cx + 6, 40, 2, Color("d8c0d0"))
	)


## Nivel 07 -- Fornalha dos Pecadores. Ignivar, o Ferreiro Maldito: massa
## de escoria e ferro, avental de couro, um braco em martelo, nucleo de
## forja aceso no peito. Frame 2 ergue o martelo (baque); frame 3 volta-se
## e a forja das costas abre-se (exposto).
func _boss_ignivar() -> void:
	var FERRO := Color("2a2530")
	var FERRO_C := Color("46414f")
	var COURO := Color("3a2415")
	var BRASA := Color("ff7a1e")
	var BRASA_C := Color("ffd85a")
	_boss("ignivar", 104, 116, func(f: int) -> void:
		var martelo_cima := f == 2
		# pernas / pes de ferro
		_rect(36, 92, 12, 22, FERRO)
		_rect(56, 92, 12, 22, FERRO)
		_rect(32, 110, 18, 5, FERRO_C)
		_rect(54, 110, 18, 5, FERRO_C)
		# tronco (massa de escoria)
		_elipse(52, 56, 26, 30, FERRO)
		_elipse(52, 54, 20, 24, FERRO_C)
		# avental de couro
		for j in range(46, 92):
			var t := float(j - 46) / 46.0
			var meia := lerpf(10.0, 17.0, t)
			_rect(int(52 - meia), j, int(meia * 2.0), 1, COURO)
		# nucleo de forja no peito
		var g: float = [1.0, 1.25, 1.1, 1.0][f]
		_elipse(52, 52, 6.0 * g, 7.0 * g, BRASA)
		_elipse(52, 52, 3.0, 3.5, BRASA_C)
		_px(52, 51, PAL["w"])
		# cabeca (elmo baixo, sem rosto, fenda acesa)
		_elipse(52, 24, 11, 10, FERRO)
		_rect(46, 24, 12, 2, BRASA)
		# braco normal (esquerda)
		_linha(30, 44, 22, 70, 7, FERRO)
		_elipse(22, 72, 6, 6, FERRO_C)
		# braco-martelo (direita) -- erguido no frame 2
		if martelo_cima:
			_linha(74, 44, 88, 14, 8, FERRO)
			_rect(78, 2, 22, 16, FERRO_C)  # cabeca do martelo
			_rect(80, 4, 8, 5, BRASA)
		else:
			_linha(74, 46, 86, 72, 8, FERRO)
			_rect(80, 66, 20, 14, FERRO_C)
			_px(88, 72, BRASA)
		# frame 3: forja das costas a' vista + faíscas
		if f == 3:
			_elipse(52, 58, 9, 11, Color("120a08"))
			_elipse(52, 58, 5, 6, BRASA)
			_elipse(52, 58, 2.5, 3, BRASA_C)
			_px(40, 44, BRASA_C)
			_px(64, 48, BRASA)
			_px(58, 40, BRASA_C)
	)
