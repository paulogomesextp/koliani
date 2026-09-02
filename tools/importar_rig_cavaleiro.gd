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

## Paleta-alvo = a folha de referência que o Paulo mandou (2 set 2026):
## guerreira gótica grunge -- base escura NEUTRA + UM roxo-ameixa
## empoeirado (a capa esfarrapada) + pele quente/tan + realces creme.
## NADA de magenta berrante nem rebordo néon. Ver
## `assets/branding/koliani_ref.md` (e `koliani_ref.png` se o Paulo o guardar).
const REF_CAPA := Color(0.42, 0.30, 0.50)    # roxo-ameixa da capa (SEMPRE escuro)
const REF_CABELO := Color(0.30, 0.22, 0.17)  # castanho escuro morno (era azul)
const REF_COURO := Color(0.60, 0.585, 0.63)  # multiplicador p/ couro/metal -> near-black
const REF_PELE := Color(0.95, 0.88, 0.82)    # multiplicador p/ manter a pele quente
const REF_REALCE := Color(0.87, 0.81, 0.92)  # branco-lavanda p/ gume/brilhos


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


## 1.ª passagem -- troca os MATIZES do rig fonte para os da referência:
##   cabelo AZUL      -> castanho escuro morno
##   roupa VERMELHA   -> capa roxo-ameixa (sempre escura)
##   armadura CINZA   -> couro near-black neutro
##   pele             -> mantém-se quente/tan
##   quase-branco     -> creme-lavanda (gume / brilhos)
## Só cor, o desenho fica igual.
func _graduar(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var maxc := maxf(c.r, maxf(c.g, c.b))
			var minc := minf(c.r, minf(c.g, c.b))
			var lum := c.r * 0.30 + c.g * 0.59 + c.b * 0.11
			var sat := 0.0 if maxc <= 0.0 else (maxc - minc) / maxc
			var pele := c.r > 0.7 and c.g > 0.42 and c.g < c.r and c.b > 0.36 and c.b <= c.g + 0.14
			var azul := c.b > c.r * 1.12 and c.b >= c.g * 1.02 and sat > 0.2
			var vermelho := c.r > c.g * 1.35 and c.r > c.b * 1.15 and sat > 0.32
			if pele:
				c = Color(clampf(c.r * REF_PELE.r, 0.0, 1.0),
					clampf(c.g * REF_PELE.g, 0.0, 1.0),
					clampf(c.b * REF_PELE.b, 0.0, 1.0), c.a)
			elif maxc > 0.88 and sat < 0.14:
				# realce quase branco -> creme-lavanda (não deixar branco puro)
				c = Color(REF_REALCE.r * maxc, REF_REALCE.g * maxc, REF_REALCE.b * maxc, c.a)
			elif azul:
				var b := 0.35 + 0.95 * lum          # cabelo azul -> castanho
				c = Color(REF_CABELO.r * b, REF_CABELO.g * b, REF_CABELO.b * b, c.a)
			elif vermelho:
				var b := 0.42 + 0.7 * lum           # roupa vermelha -> ameixa, escura
				c = Color(REF_CAPA.r * b, REF_CAPA.g * b, REF_CAPA.b * b, c.a)
			elif sat < 0.3:
				# couro / metal / cinza -> escurece p/ near-black neutro
				c = Color(clampf(lum * REF_COURO.r, 0.0, 1.0),
					clampf(lum * REF_COURO.g, 0.0, 1.0),
					clampf(lum * REF_COURO.b * 1.05, 0.0, 1.0), c.a)
			img.set_pixel(x, y, c)


## 2.ª passagem -- mood grade LEVE: baixa a luz geral e afunda as sombras
## para um escuro NEUTRO. A referência não tem rebordo néon nem magenta
## chapado, por isso aqui não se pinta nada -- só se ajusta o valor.
const _GOT_SOMBRA := Color(0.10, 0.09, 0.13)
const _GOT_LUM := 0.9

func _goticar(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var src := img.get_pixel(x, y)
			if src.a <= 0.0:
				continue
			var lum := src.r * 0.30 + src.g * 0.59 + src.b * 0.11
			var c := src * _GOT_LUM
			var escuro := 1.0 - clampf(lum * 1.5, 0.0, 1.0)
			c = c.lerp(_GOT_SOMBRA, escuro * 0.4)
			c.a = src.a
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
