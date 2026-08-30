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
	_boss_dama()     # regiao II / nivel 08
	_boss_irmaos()   # regiao II / nivel 09
	_boss_primeiro() # regiao II / nivel 10
	_boss_sino()     # regiao III / nivel 11
	_boss_voltaris() # regiao III / nivel 13
	_boss_sacerdotisa() # regiao III / nivel 14
	_boss_vyrak()    # regiao III / nivel 15
	_boss_rei_ossario() # regiao IV / nivel 16
	_boss_colosso()  # regiao IV / nivel 17
	_boss_freira()   # regiao IV / nivel 18
	_boss_naga()     # regiao IV / nivel 19
	_boss_olho()     # regiao IV / nivel 20
	_boss_prefeito() # regiao V / nivel 21
	_boss_acougueiro() # regiao V / nivel 22
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


## Nivel 08 -- Corredor das Execucoes. A Dama da Guilhotina: executora
## fantasma, manto negro esfarrapado que se esvai em fios no fim, capuz de
## carrasco, uma lamina larga na mao. Frame 2 ergue a lamina (telegrafo);
## frame 3 recolhe o capuz -- cranio palido + nucleo ciano a' vista.
func _boss_dama() -> void:
	var MANTO := Color("14121c")
	var MANTO_C := Color("262034")
	var ESPETRO := Color("bfeaff")
	var OSSO := Color("d7cdb8")
	var ACO := Color("9aa6c8")
	var ACO_C := Color("e6ecff")
	var NUCLEO := Color("6fe0ff")
	_boss("dama", 84, 108, func(f: int) -> void:
		var sway: float = [0.0, 1.5, -1.0, 0.0][f]
		var cx := 42.0 + sway
		for j in range(24, 92):
			var t := float(j - 24) / 68.0
			var meia := lerpf(11.0, 24.0, t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, MANTO if j % 3 else MANTO_C)
		for d in 7:
			var fx := int(cx - 20 + d * 7)
			_linha(fx, 90, fx + int(sway), 90 + 8 + (d % 3) * 5, 1, ESPETRO)
		_linha(int(cx), 26, int(cx), 88, 1, MANTO_C)
		_elipse(cx, 16, 12, 13, MANTO)
		_linha(int(cx) - 8, 3, int(cx) + 4, 9, 3, MANTO)
		if f == 3:
			_elipse(cx, 17, 7.5, 8.5, OSSO)
			_px(int(cx) - 3, 16, NUCLEO)
			_px(int(cx) + 3, 16, NUCLEO)
			_rect(int(cx) - 3, 21, 7, 1, Color("2a2622"))
			_elipse(cx, 40, 5.5, 6.5, NUCLEO)
			_elipse(cx, 40, 2.5, 3.0, ACO_C)
			_px(int(cx), 39, PAL["w"])
		else:
			_rect(int(cx) - 5, 14, 10, 6, Color("07070c"))
			_px(int(cx) - 3, 16, ESPETRO)
			_px(int(cx) + 3, 16, ESPETRO)
		if f == 2:
			_linha(int(cx) + 8, 30, int(cx) + 14, 6, 4, MANTO_C)
			_rect(int(cx) + 2, 0, 30, 8, ACO)
			_rect(int(cx) + 2, 8, 30, 3, ACO_C)
			_px(int(cx) + 30, 4, ACO_C)
		else:
			_linha(int(cx) + 8, 32, int(cx) + 20, 60, 4, MANTO_C)
			_linha(int(cx) + 16, 54, int(cx) + 40, 78, 7, ACO)
			_linha(int(cx) + 18, 52, int(cx) + 42, 76, 2, ACO_C)
		_linha(int(cx) - 8, 32, int(cx) - 16, 58, 4, MANTO_C)
	)


## Nivel 09 -- Ala dos Mortos. Os Irmaos Condenados: fantasma de forcado,
## tunica rasgada, pulsos agrilhoados com um coto de corrente, capuz oco.
## Verde-ciano de alma (distingue-se do azul da Dama). Frame 2 encolhe-se
## para o arremesso; frame 3 abre o peito -- caixa toracica + nucleo de alma.
func _boss_irmaos() -> void:
	var PANO := Color("1b2420")
	var PANO_C := Color("2c3a33")
	var ALMA := Color("7ff0c8")
	var OSSO := Color("cfd8c4")
	var FERRO := Color("5a6b66")
	_boss("irmaos", 88, 104, func(f: int) -> void:
		var crouch := f == 2
		var cx := 44.0
		var topo := 30 if crouch else 22
		# tunica: ombros -> orla que se esfiapa
		for j in range(topo, 90):
			var t := float(j - topo) / float(90 - topo)
			var meia := lerpf(9.0, 20.0, t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, PANO if j % 3 else PANO_C)
		for d in 6:
			var fx := int(cx - 16 + d * 6)
			_linha(fx, 88, fx + (d % 2) * 2 - 1, 88 + 6 + (d % 3) * 4, 1, ALMA)
		# aura fria de um lado
		for j in range(topo + 4, 82):
			if j % 2 == 0:
				_px(int(cx - lerpf(8.0, 17.0, float(j - topo) / 52.0)), j, Color(ALMA.r, ALMA.g, ALMA.b, 0.10))
		# capuz oco
		_elipse(cx, topo - 8, 10, 11, PANO)
		if f == 3:
			_elipse(cx, topo - 7, 6.5, 7.5, OSSO)
			_px(int(cx) - 3, topo - 8, ALMA)
			_px(int(cx) + 3, topo - 8, ALMA)
			# peito aberto: costelas + nucleo
			for r in 3:
				_linha(int(cx) - 8, 44 + r * 5, int(cx) + 8, 44 + r * 5, 1, OSSO)
			_elipse(cx, 50, 5.0, 6.0, ALMA)
			_elipse(cx, 50, 2.2, 2.6, PAL["w"])
		else:
			_rect(int(cx) - 4, topo - 10, 8, 5, Color("06090a"))
			_px(int(cx) - 3, topo - 8, ALMA)
			_px(int(cx) + 3, topo - 8, ALMA)
		# bracos + grilhetas
		var by := 40 if not crouch else 46
		_linha(int(cx) - 8, topo + 6, int(cx) - 16, by, 4, PANO_C)
		_linha(int(cx) + 8, topo + 6, int(cx) + 16, by, 4, PANO_C)
		_rect(int(cx) - 20, by, 6, 4, FERRO)
		_rect(int(cx) + 14, by, 6, 4, FERRO)
		# coto de corrente pendurado do pulso da frente
		for k in 3:
			_px(int(cx) + 17, by + 4 + k * 3, FERRO)
			_px(int(cx) + 18, by + 5 + k * 3, FERRO)
	)


## Nivel 10 -- A Cela Zero. O Primeiro Prisioneiro: heroi antigo em armadura
## amolgada, sobreveste rasgada, elmo fechado, uma espada reta como a da
## Koliani (gume aceso a magenta). Frame 2 = espada erguida / guarda;
## frame 3 = guarda quebrada, nucleo de energia purpura no peito (fase 2).
func _boss_primeiro() -> void:
	var ACO := Color("3b3f4a")
	var ACO_C := Color("585d6b")
	var PANO := Color("4a2140")
	var GUME := Color("ff45ef")
	var ENERGIA := Color("c86bff")
	_boss("primeiro", 76, 104, func(f: int) -> void:
		var cx := 38.0
		var guarda := f == 2
		# pernas
		_rect(int(cx) - 12, 82, 9, 20, ACO)
		_rect(int(cx) + 3, 82, 9, 20, ACO)
		_rect(int(cx) - 14, 100, 13, 4, ACO_C)
		_rect(int(cx) + 1, 100, 13, 4, ACO_C)
		# sobreveste rasgada
		for j in range(44, 84):
			var t := float(j - 44) / 40.0
			var meia := lerpf(9.0, 15.0, t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, PANO if j % 4 else ACO)
		_px(int(cx) - 13, 82, PANO); _px(int(cx) + 12, 80, PANO)
		# tronco / peitoral
		_elipse(cx, 44, 15, 17, ACO)
		_elipse(cx, 42, 10, 12, ACO_C)
		# elmo
		_elipse(cx, 22, 9, 10, ACO)
		_rect(int(cx) - 6, 21, 12, 2, Color("14161c"))  # visor
		_linha(int(cx), 12, int(cx), 8, 2, ACO_C)       # crista
		# braco de tras
		_linha(int(cx) - 10, 36, int(cx) - 18, 56, 5, ACO)
		# braco da espada + lamina
		if guarda:
			# espada erguida na vertical, a aparar
			_linha(int(cx) + 10, 36, int(cx) + 16, 20, 5, ACO)
			_rect(int(cx) + 13, -6, 5, 30, Color("c8ccdc"))
			_linha(int(cx) + 15, -6, int(cx) + 15, 22, 1, GUME)
			_rect(int(cx) + 9, 22, 14, 3, ACO_C)  # guarda-mao
		else:
			_linha(int(cx) + 10, 38, int(cx) + 24, 54, 5, ACO)
			# lamina baixa na diagonal, como a da Koliani
			_linha(int(cx) + 20, 50, int(cx) + 44, 74, 4, Color("c8ccdc"))
			_linha(int(cx) + 22, 49, int(cx) + 46, 73, 1, GUME)
			_rect(int(cx) + 17, 47, 10, 3, ACO_C)
		# nucleo de energia (fase 2 / exposto)
		if f == 3:
			_elipse(cx, 44, 6.0, 7.0, ENERGIA)
			_elipse(cx, 44, 2.6, 3.0, PAL["w"])
			for a in 4:
				var ang := TAU * float(a) / 4.0 + 0.4
				_linha(int(cx), 44, int(cx + cos(ang) * 12.0), int(44 + sin(ang) * 12.0), 1, ENERGIA)
	)


## Nivel 11 -- Torre dos Sinos. O Sino Vivo: sino de bronze colossal com um
## rosto preso na boca. Frame 2 = baloicado de lado (telegrafo);
## frame 3 = boca aberta, rosto/badalo aceso (exposto).
func _boss_sino() -> void:
	var BRONZE := Color("7a6326")
	var BRONZE_C := Color("a88c3c")
	var BRONZE_E := Color("463a17")
	var SOM := Color("cdd6ff")
	var ROSTO := Color("2a2410")
	_boss("sino", 100, 104, func(f: int) -> void:
		var tilt: float = [0.0, 2.0, -6.0, 0.0][f]
		var cx := 50.0 + tilt
		# suporte / eixo
		_rect(20, 6, 60, 4, BRONZE_E)
		_linha(int(cx), 10, int(cx), 20, 2, BRONZE_E)
		# corpo do sino (trapezio bojudo)
		for j in range(18, 82):
			var t := float(j - 18) / 64.0
			var meia := lerpf(10.0, 34.0, pow(t, 0.8))
			var c := 50.0 + tilt * t
			_rect(int(c - meia), j, int(meia * 2.0), 1, BRONZE if j % 5 else BRONZE_C)
		# aro da boca
		_rect(int(cx) - 38, 80, 76, 8, BRONZE_E)
		_rect(int(cx) - 38, 78, 76, 3, BRONZE_C)
		# brilho num flanco
		_linha(int(cx) - 22, 30, int(cx) - 28, 70, 3, Color(1, 0.95, 0.7, 0.5))
		# rosto preso na boca
		var abrir := f == 3
		var ry := 12.0 if abrir else 7.0
		_elipse(cx, 74, 12.0, ry, ROSTO)
		if abrir:
			_elipse(cx, 74, 8.0, 9.0, Color("120e06"))
			_px(int(cx) - 4, 71, SOM); _px(int(cx) + 4, 71, SOM)
			# badalo aceso
			_elipse(cx, 66, 4.0, 5.0, SOM)
			_rect(int(cx) - 1, 52, 2, 12, BRONZE_E)
		else:
			_px(int(cx) - 4, 73, SOM); _px(int(cx) + 4, 73, SOM)
			_rect(int(cx) - 1, 50, 2, 22, BRONZE_E)  # badalo dentro
			_elipse(cx, 74, 3.5, 3.5, BRONZE_E)
		# fendas (frame 2/3 = fase avancada no visual)
		if f >= 2:
			_linha(int(cx) + 10, 26, int(cx) + 4, 60, 1, BRONZE_E)
			_linha(int(cx) - 14, 34, int(cx) - 8, 66, 1, BRONZE_E)
		# ondas de som no telegrafo
		if f == 2:
			for r in [16, 22, 28]:
				_linha(int(cx) - 40 - r, 40, int(cx) - 40 - r, 60, 1, SOM)
	)


## Nivel 13 -- Torre da Tempestade. Voltaris, o Mago Morto-Vivo: manto
## esfarrapado, cranio com olhos acesos, cajado alto com um orbe. Tom
## ciano eletrico. Frame 2 = cajado erguido, arcos (telegrafo);
## frame 3 = orbe aberto, nucleo a vista (exposto).
func _boss_voltaris() -> void:
	var MANTO := Color("1a2230")
	var MANTO_C := Color("2b3850")
	var RAIO := Color("bfe8ff")
	var OSSO := Color("d8d2be")
	var ORBE := Color("6fd8ff")
	_boss("voltaris", 78, 108, func(f: int) -> void:
		var sway: float = [0.0, 1.5, -1.0, 0.0][f]
		var cx := 39.0 + sway
		# manto conico
		for j in range(26, 100):
			var t := float(j - 26) / 74.0
			var meia := lerpf(9.0, 22.0, t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, MANTO if j % 3 else MANTO_C)
		for d in 6:
			var fx := int(cx - 16 + d * 6)
			_linha(fx, 98, fx + int(sway), 98 + 5 + (d % 3) * 4, 1, RAIO)
		# capuz + cranio
		_elipse(cx, 20, 11, 12, MANTO)
		if f == 3:
			_elipse(cx, 21, 7.0, 8.0, OSSO)
			_px(int(cx) - 3, 20, ORBE); _px(int(cx) + 3, 20, ORBE)
			_rect(int(cx) - 3, 25, 7, 1, Color("20232a"))
			# nucleo no peito
			_elipse(cx, 46, 5.5, 6.5, ORBE)
			_elipse(cx, 46, 2.4, 2.8, PAL["w"])
		else:
			_rect(int(cx) - 5, 16, 10, 6, Color("06080c"))
			_px(int(cx) - 3, 19, RAIO); _px(int(cx) + 3, 19, RAIO)
		# braco + cajado
		var erguido := f == 2
		if erguido:
			_linha(int(cx) + 8, 34, int(cx) + 16, 12, 4, MANTO_C)
			_linha(int(cx) + 18, 4, int(cx) + 18, 70, 3, Color("3a2c1e"))
			_elipse(cx + 18, 2, 6, 6, ORBE)
			_elipse(cx + 18, 2, 2.5, 2.5, PAL["w"])
			# arcos
			_linha(int(cx) + 18, 2, int(cx) + 30, 14, 1, RAIO)
			_linha(int(cx) + 18, 2, int(cx) + 6, 12, 1, RAIO)
		else:
			_linha(int(cx) + 8, 36, int(cx) + 20, 58, 4, MANTO_C)
			_linha(int(cx) + 22, 12, int(cx) + 22, 78, 3, Color("3a2c1e"))
			_elipse(cx + 22, 10, 6, 6, ORBE)
			_elipse(cx + 22, 10, 2.5, 2.5, PAL["w"])
		_linha(int(cx) - 8, 34, int(cx) - 16, 56, 4, MANTO_C)
	)


## Nivel 14 -- Observatorio Lunar. A Sacerdotisa Lunar: manto palido comprido,
## toucado em crescente, maos erguidas para a lua. Frame 2 = bracos ao alto,
## brilho lunar (telegrafo); frame 3 = ajoelhada, disco lunar das costas
## aberto (exposto). Prata/branco + violeta.
func _boss_sacerdotisa() -> void:
	var MANTO := Color("cfd2e6")
	var MANTO_S := Color("9498b8")
	var VIOLETA := Color("8a6fd8")
	var LUAR := Color("f2f0ff")
	var PELE := Color("d9c3b0")
	_boss("sacerdotisa", 76, 110, func(f: int) -> void:
		var ajoelha := f == 3
		var cx := 38.0
		var pe := 104 if not ajoelha else 96
		# manto comprido (cai reto; ao ajoelhar alarga em baixo)
		for j in range(30, pe):
			var t := float(j - 30) / float(pe - 30)
			var meia := lerpf(8.0, 16.0 if not ajoelha else 22.0, t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, MANTO if j % 4 else MANTO_S)
		# faixa violeta na cintura
		_rect(int(cx) - 12, 54, 24, 3, VIOLETA)
		# disco lunar das costas
		if ajoelha:
			_elipse(cx - 2, 44, 12, 13, LUAR)
			_elipse(cx + 3, 42, 9, 10, MANTO)   # "fase" -> crescente
			_elipse(cx - 2, 44, 4, 4, VIOLETA)
		else:
			_elipse(cx + 10, 40, 7, 8, Color(LUAR.r, LUAR.g, LUAR.b, 0.5))
		# cabeca + toucado em crescente
		_elipse(cx, 22, 7, 8, MANTO)
		_rect(int(cx) - 3, 20, 6, 5, PELE)
		_linha(int(cx) - 9, 14, int(cx), 6, 2, LUAR)
		_linha(int(cx), 6, int(cx) + 9, 14, 2, LUAR)
		_px(int(cx) - 2, 21, VIOLETA); _px(int(cx) + 2, 21, VIOLETA)
		# bracos
		if f == 2:
			_linha(int(cx) - 7, 34, int(cx) - 16, 10, 4, MANTO)
			_linha(int(cx) + 7, 34, int(cx) + 16, 10, 4, MANTO)
			_elipse(cx - 16, 8, 3, 3, LUAR)
			_elipse(cx + 16, 8, 3, 3, LUAR)
			_elipse(cx, 2, 10, 6, Color(LUAR.r, LUAR.g, LUAR.b, 0.5))
		elif ajoelha:
			_linha(int(cx) - 7, 36, int(cx) - 12, 52, 4, MANTO)
			_linha(int(cx) + 7, 36, int(cx) + 12, 52, 4, MANTO)
		else:
			_linha(int(cx) - 7, 34, int(cx) - 12, 56, 4, MANTO)
			_linha(int(cx) + 7, 34, int(cx) + 12, 56, 4, MANTO)
	)


## Nivel 15 -- O Pico Esquecido. Vyrak, o Dragao das Sombras: corpo escuro,
## asas membranosas, cabeca com cornos, nucleo violeta no peito. Frame 2 =
## asa/garra erguida (telegrafo); frame 3 = cabeca baixa a rugir, nucleo
## em brasa (exposto).
func _boss_vyrak() -> void:
	var SOMBRA := Color("1c1622")
	var SOMBRA_C := Color("2e2440")
	var MEMBRANA := Color("3a2450")
	var NUCLEO := Color("b06bff")
	var GUME := Color("d8c4ff")
	_boss("vyrak", 128, 108, func(f: int) -> void:
		var asa_cima := f == 2
		var cabeca_baixa := f == 3
		var cx := 64.0
		# cauda enrolada atras (esquerda)
		_linha(20, 84, 6, 60, 6, SOMBRA)
		_linha(6, 60, 14, 44, 4, SOMBRA)
		# ancas / pernas
		_elipse(44, 78, 12, 13, SOMBRA)
		_rect(36, 88, 9, 16, SOMBRA)
		_rect(50, 90, 9, 14, SOMBRA)
		# tronco
		_elipse(cx, 62, 22, 20, SOMBRA)
		_elipse(cx, 60, 15, 14, SOMBRA_C)
		# asa (atras do tronco)
		if asa_cima:
			_linha(cx - 6, 50, cx - 30, 8, 5, SOMBRA)
			for wv in [[-30, 8, -6, 26], [-24, 12, 0, 30], [-16, 16, 8, 34]]:
				_linha(cx + wv[0], wv[1] + 0, cx + wv[2], wv[3] + 0, 3, MEMBRANA)
		else:
			_linha(cx - 6, 52, cx - 22, 30, 5, SOMBRA)
			for wv in [[-22, 30, -2, 44], [-14, 32, 8, 48]]:
				_linha(cx + wv[0], wv[1], cx + wv[2], wv[3], 3, MEMBRANA)
		# nucleo do peito
		var g: float = [1.0, 1.2, 1.1, 1.45][f]
		_elipse(cx + 6, 60, 6.0 * g, 7.0 * g, NUCLEO)
		_elipse(cx + 6, 60, 2.6, 3.0, PAL["w"])
		# pescoco + cabeca
		if cabeca_baixa:
			_linha(cx + 16, 52, cx + 40, 78, 7, SOMBRA)
			_elipse(cx + 46, 82, 12, 9, SOMBRA)
			_linha(cx + 40, 74, cx + 34, 66, 3, GUME)  # corno
			_linha(cx + 50, 74, cx + 46, 64, 3, GUME)
			_rect(int(cx) + 40, 84, 14, 2, NUCLEO)     # boca a rugir
			_px(int(cx) + 44, 79, NUCLEO)
		else:
			_linha(cx + 14, 50, cx + 34, 30, 7, SOMBRA)
			_elipse(cx + 40, 26, 12, 10, SOMBRA)
			_linha(cx + 44, 18, cx + 40, 8, 3, GUME)
			_linha(cx + 52, 20, cx + 50, 10, 3, GUME)
			_px(int(cx) + 44, 26, NUCLEO)
			_px(int(cx) + 48, 27, NUCLEO)
		# garra da frente
		if asa_cima or cabeca_baixa:
			_linha(cx + 12, 74, cx + 30, 58, 4, SOMBRA_C)
			for cl in range(3):
				_linha(cx + 30 + cl * 2, 58, cx + 36 + cl * 3, 50, 1, GUME)
		else:
			_linha(cx + 12, 76, cx + 26, 92, 4, SOMBRA_C)
	)


## Nivel 16 -- Cemiterio dos Reis. O Rei Ossario: rei morto-vivo coroado
## num cavalo esqueletico. Frame 0 = montado; frame 1 = a pe (cavalo caido)
## p/ a fase 2; frame 2 = lanca/espada em riste (telegrafo); frame 3 = rei
## descaido na sela / nucleo violeta do peito (exposto).
func _boss_rei_ossario() -> void:
	var OSSO := Color("d8d2ba")
	var OSSO_S := Color("9c9578")
	var OURO := Color("d9b64a")
	var CAPA := Color("3a2036")
	var NUCLEO := Color("9a5cff")
	_boss("rei_ossario", 120, 100, func(f: int) -> void:
		var a_pe := f == 1
		var cx := 60.0
		if not a_pe:
			# cavalo esqueletico (perfil, virado a direita)
			_linha(24, 78, 34, 58, 5, OSSO)      # anca tras
			_linha(86, 74, 92, 56, 5, OSSO)      # peito frente
			for lx in [22, 40, 80, 96]:
				_linha(lx, 78, lx + 2, 96, 3, OSSO_S)   # patas
			_linha(34, 58, 88, 56, 7, OSSO)      # espinha
			_linha(88, 56, 104, 40, 5, OSSO)     # pescoco
			_elipse(106, 34, 8, 6, OSSO)         # cabeca do cavalo
			_linha(30, 60, 18, 72, 3, OSSO_S)    # cauda de ossos
			_px(110, 33, NUCLEO); _px(110, 36, NUCLEO)  # olhos acesos
		else:
			# cavalo caido (linha baixa de ossos)
			for bx in range(26, 96, 8):
				_px(bx, 92, OSSO_S); _px(bx + 2, 93, OSSO_S)
			_elipse(30, 90, 6, 4, OSSO_S)
		# rei (sobre a sela, ou de pe se a_pe)
		var rx := 58.0 if not a_pe else 60.0
		var ry := 30.0 if not a_pe else 56.0
		# corpo / capa
		for j in range(int(ry), int(ry) + (34 if a_pe else 30)):
			var t := float(j - ry) / 30.0
			var meia := lerpf(8.0, 12.0, t)
			_rect(int(rx - meia), j, int(meia * 2.0), 1, CAPA if j % 3 else OSSO_S)
		# peitoral de osso + nucleo
		_elipse(rx, ry + 10, 9, 10, OSSO)
		var g: float = [1.0, 1.0, 1.15, 1.5][f]
		_elipse(rx + 1, ry + 10, 4.5 * g, 5.0 * g, NUCLEO)
		_elipse(rx + 1, ry + 10, 2.0, 2.2, PAL["w"])
		# cabeca + coroa
		var ch := ry - 6.0 if f != 3 else ry - 2.0
		_elipse(rx, ch, 6, 7, OSSO)
		_px(int(rx) - 2, int(ch), NUCLEO); _px(int(rx) + 2, int(ch), NUCLEO)
		for k in 5:
			_linha(int(rx) - 6 + k * 3, int(ch) - 6, int(rx) - 6 + k * 3, int(ch) - 11, 1, OURO)
		_rect(int(rx) - 7, int(ch) - 7, 14, 2, OURO)
		# braco + arma
		if f == 2:
			_linha(int(rx) + 6, int(ry) + 4, int(rx) + 30, int(ry) - 4, 4, OSSO_S)
			_linha(int(rx) + 20, int(ry), int(rx) + 52, int(ry) - 8, 2, OSSO)  # lanca
			_px(int(rx) + 52, int(ry) - 8, PAL["w"])
		else:
			_linha(int(rx) + 6, int(ry) + 6, int(rx) + 18, int(ry) + 22, 4, OSSO_S)
			_linha(int(rx) + 14, int(ry) + 14, int(rx) + 30, int(ry) + 30, 2, OSSO)
	)


## Nivel 17 -- Galeria dos Ossos. O Colosso Osseo: gigante de centenas de
## esqueletos amontoados, macico. Frame 0/1 idle; frame 2 = braco-arma
## erguido (telegrafo); frame 3 = peito aberto, aglomerado de cranios
## aceso (exposto).
func _boss_colosso() -> void:
	var OSSO := Color("d6cfb4")
	var OSSO_S := Color("948c6f")
	var OSSO_E := Color("57503b")
	var NUCLEO := Color("aef0d0")
	_boss("colosso", 116, 116, func(f: int) -> void:
		var braco_cima := f == 2
		var cx := 58.0
		# pernas macicas de ossos amontoados
		for lx in [40, 76]:
			for j in range(88, 114):
				var meia := 8.0 + 2.0 * sin(j * 0.7 + lx)
				_rect(int(lx - meia), j, int(meia * 2.0), 1, OSSO if j % 3 else OSSO_S)
		_rect(30, 112, 24, 4, OSSO_E)
		_rect(66, 112, 24, 4, OSSO_E)
		# tronco -- massa de ossos
		for j in range(34, 92):
			var t := float(j - 34) / 58.0
			var meia := lerpf(24.0, 18.0, t)
			for i in range(int(cx - meia), int(cx + meia), 3):
				_px(i, j, OSSO if (i + j) % 5 else OSSO_S)
		_elipse(cx, 60, 22, 26, Color(OSSO_S.r, OSSO_S.g, OSSO_S.b, 0.0))
		# ombros / cabeca (cranio grande no topo)
		_elipse(cx, 22, 14, 13, OSSO)
		_rect(int(cx) - 7, 22, 14, 4, OSSO_E)
		_px(int(cx) - 4, 20, NUCLEO); _px(int(cx) + 4, 20, NUCLEO)
		# braco esquerdo (osso)
		_linha(int(cx) - 18, 40, int(cx) - 34, 74, 8, OSSO_S)
		_elipse(cx - 36, 78, 7, 7, OSSO)
		# braco-arma direito
		if braco_cima:
			_linha(int(cx) + 18, 40, int(cx) + 34, 8, 8, OSSO_S)
			_rect(int(cx) + 26, 0, 22, 14, OSSO)      # maco de ossos
			_linha(int(cx) + 30, 2, int(cx) + 44, 12, 2, OSSO_E)
		else:
			_linha(int(cx) + 18, 42, int(cx) + 40, 70, 8, OSSO_S)
			_linha(int(cx) + 34, 60, int(cx) + 58, 84, 3, OSSO)  # foice/lanca em repouso
		# nucleo do peito (aglomerado de cranios)
		var g: float = [0.9, 0.95, 1.05, 1.5][f]
		for d in 5:
			var ang := TAU * float(d) / 5.0
			_elipse(cx + cos(ang) * 6.0 * g, 58 + sin(ang) * 6.0 * g, 3.0 * g, 3.0 * g, NUCLEO if f == 3 else OSSO_S)
		_elipse(cx, 58, 3.5 * g, 3.5 * g, NUCLEO)
		if f == 3:
			_elipse(cx, 58, 1.8, 1.8, PAL["w"])
	)


## Nivel 18 -- Cripta das Mil Velas. A Freira Negra: habito negro comprido,
## veu, um apagador de velas na mao. Frame 2 = braco erguido p/ apagar
## (telegrafo); frame 3 = veu queimado para tras, cara palida + nucleo
## violeta (exposta).
func _boss_freira() -> void:
	var HABITO := Color("100e16")
	var HABITO_C := Color("221d2e")
	var VEU := Color("1a1622")
	var OSSO := Color("d7cdbe")
	var NUCLEO := Color("9a5cff")
	var CHAMA := Color("3a2050")
	_boss("freira", 72, 110, func(f: int) -> void:
		var apaga := f == 2
		var expo := f == 3
		var cx := 36.0
		# habito conico
		for j in range(28, 104):
			var t := float(j - 28) / 76.0
			var meia := lerpf(8.0, 20.0, t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, HABITO if j % 4 else HABITO_C)
		# vinco central
		_linha(int(cx), 30, int(cx), 100, 1, HABITO_C)
		# veu / cabeca
		if expo:
			_elipse(cx, 18, 8, 9, OSSO)
			_px(int(cx) - 3, 17, NUCLEO); _px(int(cx) + 3, 17, NUCLEO)
			_rect(int(cx) - 3, 22, 7, 1, Color("22201c"))
			# veu para tras
			_linha(int(cx) + 6, 12, int(cx) + 16, 4, 3, VEU)
			_linha(int(cx) - 6, 12, int(cx) - 16, 4, 3, VEU)
			# nucleo no peito
			_elipse(cx, 42, 5.5, 6.5, NUCLEO)
			_elipse(cx, 42, 2.4, 2.8, PAL["w"])
		else:
			_elipse(cx, 16, 11, 13, VEU)          # veu a cair
			_rect(int(cx) - 5, 14, 10, 8, Color("07060a"))
			_px(int(cx) - 3, 18, CHAMA); _px(int(cx) + 3, 18, CHAMA)
		# ombros / gola branca
		_rect(int(cx) - 9, 28, 18, 3, OSSO)
		# bracos + apagador
		if apaga:
			_linha(int(cx) + 7, 32, int(cx) + 16, 10, 4, HABITO_C)
			_linha(int(cx) + 16, 12, int(cx) + 16, -2, 2, Color("3a2c1e"))  # cabo
			_elipse(cx + 16, -4, 4, 4, Color("57503b"))                     # cone do apagador
		else:
			_linha(int(cx) + 7, 34, int(cx) + 14, 54, 4, HABITO_C)
			_linha(int(cx) + 12, 46, int(cx) + 12, 66, 2, Color("3a2c1e"))
			_elipse(cx + 12, 68, 3, 3, Color("57503b"))
		_linha(int(cx) - 7, 34, int(cx) - 13, 56, 4, HABITO_C)
	)


## Nivel 19 -- Templo da Serpente. Naga Zeraph: cauda de serpente enrolada,
## torso de mulher, capelo de cobra. Frame 2 = ergue-se de boca aberta a
## cuspir (telegrafo); frame 3 = ergue-se por completo, ventre/nucleo a
## mostra (exposta).
func _boss_naga() -> void:
	var ESC := Color("2b6b3a")
	var ESC_C := Color("4a9a55")
	var ESC_E := Color("173e22")
	var PELE := Color("c9a884")
	var OURO := Color("d9b64a")
	var NUCLEO := Color("9a5cff")
	_boss("naga", 84, 112, func(f: int) -> void:
		var ergue := f >= 2
		var cx := 42.0
		# cauda enrolada (base)
		for r in range(3):
			var ry := 96 - r * 8
			_elipse(cx + (r - 1) * 10, ry, 22 - r * 3, 8, ESC if r % 2 else ESC_C)
		_linha(int(cx) + 18, 92, int(cx) + 30, 84, 4, ESC_C)
		# torso (mais erguido nos frames 2/3)
		var ty0 := 40 if not ergue else 24
		for j in range(ty0, 88):
			var t := float(j - ty0) / float(88 - ty0)
			var meia := lerpf(7.0, 12.0, t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, ESC if j % 4 else PELE)
		# ventre claro + nucleo
		var g: float = [0.9, 0.95, 1.1, 1.5][f]
		_elipse(cx, ty0 + 20, 5.0 * g, 6.0 * g, NUCLEO if f == 3 else PELE)
		if f == 3:
			_elipse(cx, ty0 + 20, 2.2, 2.6, PAL["w"])
		# ombros / bracos
		_linha(int(cx) - 7, ty0 + 4, int(cx) - 16, ty0 + 24, 4, ESC_C)
		_linha(int(cx) + 7, ty0 + 4, int(cx) + 16, ty0 + 24, 4, ESC_C)
		# cabeca + capelo de cobra
		var ch := ty0 - 8
		_elipse(cx, ch, 7, 8, PELE)
		_elipse(cx - 11, ch + 1, 5, 8, ESC)     # aba esq do capelo
		_elipse(cx + 11, ch + 1, 5, 8, ESC)     # aba dir
		_rect(int(cx) - 8, ch - 8, 16, 3, OURO) # diadema
		_px(int(cx) - 2, ch, NUCLEO); _px(int(cx) + 2, ch, NUCLEO)
		if f == 2:
			_rect(int(cx) - 3, ch + 4, 6, 4, Color("120a08"))  # boca aberta
			for d in 3:
				_px(int(cx) - 8 + d * 8, ch + 8 + d, Color("5a8a3a"))  # cuspe a sair
		# lingua bifida no frame 3
		if f == 3:
			_linha(int(cx), ch + 5, int(cx) - 3, ch + 12, 1, Color("b0304a"))
			_linha(int(cx), ch + 5, int(cx) + 3, ch + 12, 1, Color("b0304a"))
	)


## Nivel 20 -- O Abismo. O Olho do Abismo: um olho flutuante sem corpo,
## esclera palida, iris purpura, tentaculos de sombra curtos. Frame 2 =
## carrega o laser (iris contraida, brilho); frame 3 = fechado a recarregar
## (palpebra por cima, iris a mostra na fenda -- exposto).
func _boss_olho() -> void:
	var ESCLERA := Color("cdd0dc")
	var ESCLERA_S := Color("8f93a6")
	var IRIS := Color("6a2a8a")
	var IRIS_C := Color("b45cff")
	var SOMBRA := Color("14101c")
	_boss("olho", 96, 96, func(f: int) -> void:
		var carrega := f == 2
		var fechado := f == 3
		var cx := 48.0
		var cy := 48.0
		# tentaculos de sombra
		for a in 8:
			var ang := TAU * float(a) / 8.0
			_linha(int(cx), int(cy), int(cx + cos(ang) * 40.0), int(cy + sin(ang) * 40.0), 3, SOMBRA)
		# globo
		_elipse(cx, cy, 30, 28, ESCLERA)
		_elipse(cx - 8, cy - 6, 16, 14, Color(1, 1, 1, 0.0))
		for j in range(int(cy) + 8, int(cy) + 28):
			_rect(int(cx) - 26, j, 52, 1, ESCLERA_S)
		# veias
		_linha(int(cx) - 20, int(cy) - 14, int(cx) - 8, int(cy) - 2, 1, Color("b04a5a"))
		_linha(int(cx) + 22, int(cy) + 10, int(cx) + 8, int(cy) + 2, 1, Color("b04a5a"))
		if fechado:
			# palpebra por cima, fenda estreita
			_rect(int(cx) - 30, int(cy) - 28, 60, 26, SOMBRA)
			_rect(int(cx) - 22, int(cy) - 3, 44, 6, IRIS)
			_rect(int(cx) - 6, int(cy) - 2, 12, 4, IRIS_C)
			_px(int(cx), int(cy), PAL["w"])
		else:
			var ir := 12.0 if not carrega else 7.0
			_elipse(cx, cy, ir, ir, IRIS)
			_elipse(cx, cy, ir * 0.5, ir * 0.5, IRIS_C)
			_elipse(cx, cy, 2.5, 2.5, SOMBRA)
			_px(int(cx) - 3, int(cy) - 3, PAL["w"])
			if carrega:
				for d in 4:
					var ang2 := TAU * float(d) / 4.0 + 0.4
					_linha(int(cx), int(cy), int(cx + cos(ang2) * 16.0), int(cy + sin(ang2) * 16.0), 1, IRIS_C)
	)


## Nivel 21 -- Vila dos Sem-Rosto. O Prefeito Sem-Rosto: casaca vermelha,
## cartola, faixa de gala, bengala -- e uma cara LISA sem tracos. Frame 2 =
## bengala erguida (telegrafo); frame 3 = a cara lisa abre-se num vazio
## violeta (exposto).
func _boss_prefeito() -> void:
	var CASACA := Color("6a1f2a")
	var CASACA_C := Color("8c3340")
	var CARTOLA := Color("14121a")
	var OURO := Color("d9b64a")
	var CARA := Color("d8cbb6")
	var VAZIO := Color("7a2ea8")
	_boss("prefeito", 68, 108, func(f: int) -> void:
		var bengala_cima := f == 2
		var abre := f == 3
		var cx := 34.0
		# pernas / calcas escuras
		_rect(int(cx) - 10, 84, 8, 22, CARTOLA)
		_rect(int(cx) + 2, 84, 8, 22, CARTOLA)
		_rect(int(cx) - 12, 104, 12, 3, Color("0a0a10"))
		_rect(int(cx), 104, 12, 3, Color("0a0a10"))
		# casaca
		for j in range(38, 90):
			var t := float(j - 38) / 52.0
			var meia := lerpf(11.0, 15.0, t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, CASACA if j % 4 else CASACA_C)
		# faixa de gala (diagonal dourada)
		for j in range(40, 78):
			_px(int(cx) - 10 + (j - 40) / 2, j, OURO)
			_px(int(cx) - 9 + (j - 40) / 2, j, OURO)
		# botoes
		for by in [46, 54, 62, 70]:
			_px(int(cx) + 1, by, OURO)
		# cabeca lisa + cartola
		_elipse(cx, 24, 8, 9, CARA)
		if abre:
			_elipse(cx, 25, 5.0, 6.0, VAZIO)
			_elipse(cx, 25, 2.2, 2.6, PAL["w"])
		# cartola
		_rect(int(cx) - 11, 12, 22, 3, CARTOLA)  # aba
		_rect(int(cx) - 7, 0, 14, 12, CARTOLA)   # copa
		_rect(int(cx) - 7, 4, 14, 2, CASACA)     # fita
		# bracos + bengala
		if bengala_cima:
			_linha(int(cx) + 9, 42, int(cx) + 18, 16, 4, CASACA_C)
			_linha(int(cx) + 18, 16, int(cx) + 22, -4, 2, Color("3a2c1e"))
			_elipse(cx + 22, -6, 3, 3, OURO)
		else:
			_linha(int(cx) + 9, 44, int(cx) + 16, 66, 4, CASACA_C)
			_linha(int(cx) + 16, 52, int(cx) + 16, 88, 2, Color("3a2c1e"))
			_elipse(cx + 16, 50, 3, 3, OURO)
		_linha(int(cx) - 9, 44, int(cx) - 15, 64, 4, CASACA_C)
	)


## Nivel 22 -- Mercado da Carne. O Acougueiro Real: gigante de avental de
## couro manchado, dois cutelos, mascara de malha. Frame 2 = cutelos
## erguidos (telegrafo); frame 3 = cutelos cravados no chao, ventre a
## mostra (exposto).
func _boss_acougueiro() -> void:
	var CARNE := Color("7a3b3b")
	var CARNE_C := Color("9c5050")
	var COURO := Color("5a4326")
	var COURO_C := Color("7a5c36")
	var ACO := Color("b8bcc8")
	var NUCLEO := Color("ff5cc0")
	_boss("acougueiro", 120, 116, func(f: int) -> void:
		var erguido := f == 2
		var cravado := f == 3
		var cx := 60.0
		# pernas
		_rect(int(cx) - 16, 92, 14, 22, CARNE)
		_rect(int(cx) + 4, 92, 14, 22, CARNE)
		_rect(int(cx) - 20, 112, 20, 4, COURO)
		_rect(int(cx) + 2, 112, 20, 4, COURO)
		# tronco enorme
		_elipse(cx, 56, 30, 32, CARNE)
		_elipse(cx, 54, 22, 24, CARNE_C)
		# avental de couro
		for j in range(44, 96):
			var t := float(j - 44) / 52.0
			var meia := lerpf(14.0, 22.0, t)
			_rect(int(cx - meia), j, int(meia * 2.0), 1, COURO if j % 4 else COURO_C)
		# manchas
		_px(int(cx) - 6, 60, CARNE); _px(int(cx) + 8, 72, CARNE); _px(int(cx) - 12, 80, CARNE)
		# ventre / nucleo
		var g: float = [0.9, 0.95, 1.05, 1.5][f]
		_elipse(cx, 66, 5.0 * g, 6.0 * g, NUCLEO if cravado else CARNE_C)
		if cravado:
			_elipse(cx, 66, 2.2, 2.6, PAL["w"])
		# cabeca (mascara de malha, sem tracos)
		_elipse(cx, 22, 12, 12, COURO_C)
		for mx in range(-8, 9, 4):
			_linha(int(cx) + mx, 14, int(cx) + mx, 30, 1, COURO)
		# bracos + cutelos
		if erguido:
			_linha(int(cx) - 22, 44, int(cx) - 34, 8, 7, CARNE)
			_linha(int(cx) + 22, 44, int(cx) + 34, 8, 7, CARNE)
			_rect(int(cx) - 44, -6, 18, 16, ACO)
			_rect(int(cx) + 26, -6, 18, 16, ACO)
		elif cravado:
			_linha(int(cx) - 22, 46, int(cx) - 30, 88, 7, CARNE)
			_linha(int(cx) + 22, 46, int(cx) + 30, 88, 7, CARNE)
			_rect(int(cx) - 40, 84, 16, 14, ACO)
			_rect(int(cx) + 24, 84, 16, 14, ACO)
		else:
			_linha(int(cx) - 22, 46, int(cx) - 38, 72, 7, CARNE)
			_linha(int(cx) + 22, 46, int(cx) + 38, 72, 7, CARNE)
			_rect(int(cx) - 48, 66, 16, 14, ACO)
			_rect(int(cx) + 32, 66, 16, 14, ACO)
	)
