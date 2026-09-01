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
	if OS.get_environment("PREVIEW") == "1":
		_preview(preview)
	quit()


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
