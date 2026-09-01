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
