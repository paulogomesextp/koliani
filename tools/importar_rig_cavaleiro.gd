extends SceneTree
## Importa o rig da Koliani a partir do pack "Knight_player 1.4"
## (@Jump_Button, em `incoming/knight-player/`): tiras de 100x64 por
## animação -> `assets/sprites/pixel/koliani_cavaleiro/<estado>.png`, com o
## mesmo contrato das outras tiras (uma tira horizontal por estado, virada à
## DIREITA, frames todos do mesmo tamanho).
##
## O pack é uma cavaleira de cabelo azul com FAIXA na testa, armadura,
## saiote e espada+escudo -- lê como a Koliani. O `GRADE` puxa os vermelhos
## para magenta e arrefece o metal, para casar com o `key_art`.
##
##   godot --headless --script res://tools/importar_rig_cavaleiro.gd
##   PREVIEW=1 grava também `_preview_cavaleiro.png` (folha de contacto x3).

const FONTE := "res://assets/sprites/incoming/knight-player/Knight_player_1.4/Knight_player"
const DESTINO := "res://assets/sprites/pixel/koliani_cavaleiro"
const LARG := 100
const ALT := 64

## estado -> ficheiro de origem (o n.º de frames vem da largura da tira)
const MAPA := {
	"idle": "Idle_KG_1.png",
	"run": "Walking_KG_1.png",
	"jump": "Jump_KG_1.png",
	"fall": "Fall_KG_1.png",
	"attack": "Attack_KG_1.png",
	# combo de espada (2.o/3.o/4.o hit) -- o pack traz 4 tiras de ataque
	# distintas, cada uma com o seu numero de frames
	"attack2": "Attack_KG_2.png",
	"attack3": "Attack_KG_3.png",
	"attack4": "Attack_KG_4.png",
	"crouch": "Crouching_Idle_KG_1.png",
	"wallslide": "Wallside_KG_1.png",
	# o "salto duplo" fica a cambalhota do pack -- lê-se logo como 2.º salto
	"djump": "Rolling_KG_1.png",
	# estados que a Koliani já tinha em código mas não tinha desenho
	"roll": "Rolling_KG_1.png",
	"dash": "Dashing_KG_1.png",
	"hurt": "Hurt_KG_1.png",
	"defesa": "Shield_idle_KG.png",
	"borda": "Grab_idle_KG_1.png",
	"aterrar": "Landing_KG_1.png",
	"morte": "Dying_KG_1.png",
}

## Gradação para a paleta da Koliani: o vermelho do saiote/faixa vira
## magenta e o metal arrefece para violeta. Mexe só na cor, não no desenho.
const MAGENTA := Color(1.0, 0.28, 0.85)
const FRIO := Color(0.82, 0.80, 1.02)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DESTINO))
	var preview: Array[Image] = []
	for estado: String in MAPA:
		var origem := "%s/%s" % [FONTE, MAPA[estado]]
		var img := Image.load_from_file(origem)
		if img == null:
			push_error("não abriu " + origem)
			continue
		_graduar(img)
		_goticar(img)
		var caminho := "%s/%s.png" % [DESTINO, estado]
		var erro := img.save_png(caminho)
		if erro != OK:
			push_error("não gravou %s (erro %d)" % [caminho, erro])
			continue
		print("%-10s %s  %d frames" % [estado, caminho, img.get_width() / LARG])
		preview.append(img)
	_sombria()
	if OS.get_environment("PREVIEW") == "1":
		_preview(preview)
	quit()


## A KOLIANI SOMBRIA (chefe do nível 27) é o espelho da Koliani -- tem de
## usar o MESMO rig, senão o "espelho" deixa de se ler. Monta as 4 poses que
## `chefe_koliani_sombria.gd` usa (0 = parada, 1 = variação, 2 = golpe,
## 3 = exposta) numa folha de 4 frames, em sombra violeta com rebordo
## magenta e olhos acesos.
func _sombria() -> void:
	var poses := [
		["Idle_KG_1.png", 0], ["Idle_KG_1.png", 2],
		["Attack_KG_1.png", 2], ["Hurt_KG_1.png", 1],
	]
	var folha := Image.create(LARG * poses.size(), ALT, false, Image.FORMAT_RGBA8)
	folha.fill(Color(0, 0, 0, 0))
	for i in poses.size():
		var par: Array = poses[i]
		var src := Image.load_from_file("%s/%s" % [FONTE, par[0]])
		if src == null:
			push_error("não abriu " + par[0])
			return
		var f := src.get_region(Rect2i(int(par[1]) * LARG, 0, LARG, ALT))
		_ensombrar(f)
		folha.blit_rect(f, Rect2i(0, 0, LARG, ALT), Vector2i(i * LARG, 0))
	var caminho := "res://assets/sprites/pixel/bosses/koliani_sombria.png"
	if folha.save_png(caminho) != OK:
		push_error("não gravou " + caminho)
		return
	print("sombria   %s  (%d frames)" % [caminho, poses.size()])


## Sombra da Koliani: o corpo afunda para violeta quase preto, a silhueta
## ganha um fio magenta e o que era claro (olhos, gume) fica aceso.
func _ensombrar(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var orig := img.duplicate() as Image
	for y in h:
		for x in w:
			var c := orig.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var lum := maxf(c.r, maxf(c.g, c.b))
			var sombra := Color(0.10 + lum * 0.22, 0.04 + lum * 0.06,
				0.16 + lum * 0.30, c.a)
			if lum > 0.86:  # olhos / gume / brilhos -> magenta aceso
				sombra = Color(1.0, 0.45, 0.95, c.a)
			img.set_pixel(x, y, sombra)
	# fio magenta na silhueta (pixel opaco com vizinho transparente)
	for y in h:
		for x in w:
			if orig.get_pixel(x, y).a <= 0.0:
				continue
			var borda := false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p := Vector2i(x + d.x, y + d.y)
				if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
					borda = true
					break
				if orig.get_pixel(p.x, p.y).a <= 0.0:
					borda = true
					break
			if borda:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(1.0, 0.3, 0.9), 0.7))


## Vermelhos -> magenta; cinzentos do metal -> violeta frio. Guarda o tom da
## pele (que também é avermelhada mas muito menos saturada).
func _graduar(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var maxc := maxf(c.r, maxf(c.g, c.b))
			var minc := minf(c.r, minf(c.g, c.b))
			var sat := 0.0 if maxc <= 0.0 else (maxc - minc) / maxc
			var vermelho := c.r > c.g * 1.5 and c.r > c.b * 1.25 and sat > 0.45
			var pele := c.r > 0.72 and c.g > 0.55 and c.b > 0.45
			if vermelho and not pele:
				# mantém o brilho do pixel, troca-lhe o matiz
				var lum := maxc
				c = Color(MAGENTA.r * lum, MAGENTA.g * lum, MAGENTA.b * lum, c.a)
			elif sat < 0.25:
				# metal/pedra: arrefecer sem escurecer
				c = Color(
					clampf(c.r * FRIO.r, 0.0, 1.0),
					clampf(c.g * FRIO.g, 0.0, 1.0),
					clampf(c.b * FRIO.b, 0.0, 1.0), c.a)
			img.set_pixel(x, y, c)


## 2.ª passagem "MAIS GÓTICA" (pedido do Paulo, 2 set 2026): a Koliani do
## `key_art` é uma silhueta escura ao luar -- roxo profundo, sombras quase
## pretas, magenta só no gume e nos brilhos, pele pálida sem calor. Corre
## DEPOIS do `_graduar` (que já trocou os matizes); aqui só se baixa a luz,
## se dessatura o grosso, se afundam as sombras e se acendem as arestas.
## Toque LEVE -- a Koliani do key_art continua a ler-se (rosto, camadas,
## rabo-de-cavalo, botas), só que mais escura e ao luar. Não é a Sombria:
## nada de a esmagar num vulto preto.
const _GOT_SOMBRA := Color(0.12, 0.09, 0.18)    # p/ onde vão as sombras
const _GOT_ACESO := Color(1.0, 0.40, 0.92)      # gume / brilhos magenta
const _GOT_LUM := 0.78                          # multiplicador geral de luz
const _GOT_DESSAT := 0.35                        # quanto se puxa a cor p/ cinza-violeta

func _goticar(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var orig := img.duplicate() as Image
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)   # já passou pelo _graduar
			var a := c.a
			if a <= 0.0:
				continue
			var lum := c.r * 0.30 + c.g * 0.59 + c.b * 0.11
			var maxc := maxf(c.r, maxf(c.g, c.b))
			var minc := minf(c.r, minf(c.g, c.b))
			var sat := 0.0 if maxc <= 0.0 else (maxc - minc) / maxc
			if lum > 0.82 and (c.r >= c.b or sat > 0.35):
				# gume / brilhos -> deixa acender em magenta (não escurece)
				var t := clampf((lum - 0.82) / 0.18, 0.0, 1.0)
				var novo := _GOT_ACESO.lerp(Color(1, 1, 1), t)
				novo.a = a
				img.set_pixel(x, y, novo)
				continue
			# 1) dessatura um pouco para cinza-violeta frio
			var cinza := Color(lum, lum, lum * 1.12, 1.0)
			c = c.lerp(cinza, _GOT_DESSAT)
			# 2) baixa a luz geral e afunda as sombras para violeta escuro
			c = c * _GOT_LUM
			var escuro := 1.0 - clampf(lum * 1.3, 0.0, 1.0)   # 1 nas sombras, 0 nos claros
			c = c.lerp(_GOT_SOMBRA, escuro * 0.55)
			c.a = a
			img.set_pixel(x, y, c)
	# fio magenta ténue na silhueta -- recorta contra os fundos escuros
	for y in h:
		for x in w:
			if orig.get_pixel(x, y).a <= 0.0:
				continue
			var borda := false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p := Vector2i(x + d.x, y + d.y)
				if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or orig.get_pixel(p.x, p.y).a <= 0.0:
					borda = true
					break
			if borda:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(0.9, 0.32, 0.85), 0.3))


## Folha de contacto x3 com todos os estados empilhados (só para olhar).
func _preview(imgs: Array[Image]) -> void:
	if imgs.is_empty():
		return
	var larg := 0
	for i in imgs:
		larg = maxi(larg, i.get_width())
	var folha := Image.create(larg * 3, ALT * 3 * imgs.size(), false, Image.FORMAT_RGBA8)
	folha.fill(Color(0.16, 0.12, 0.22, 1.0))
	var y := 0
	for i in imgs:
		var g := i.duplicate() as Image
		g.resize(g.get_width() * 3, ALT * 3, Image.INTERPOLATE_NEAREST)
		folha.blit_rect(g, Rect2i(Vector2i.ZERO, g.get_size()), Vector2i(0, y))
		y += ALT * 3
	folha.save_png("res://assets/sprites/pixel/_preview_cavaleiro.png")
	print("preview -> res://assets/sprites/pixel/_preview_cavaleiro.png")
