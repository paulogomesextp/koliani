extends SceneTree
## Extrai os monstros do pack CC0 ansimuz "Enemies Pack" (em
## `incoming/enemies-pack/`) para tiras horizontais em
## `assets/sprites/pixel/enemies/<especie>/{idle,run,hit,dead}.png`, no
## formato que o `DemonioBase` carrega. Cada frame é ampliado (nearest) para
## a altura-alvo, para o bicho ficar do tamanho dos outros inimigos.
##
## O pack só traz "walk" e "idle"; o `hit` reaproveita o idle (o pisca-pisca
## do dano é feito pelo shader) e o `dead` é gerado -- o bicho ACHATA-SE e
## desvanece em 4 frames.
##
##   godot --headless --script res://tools/extrair_inimigos_pack.gd

const SPRITES := "res://assets/sprites/incoming/enemies-pack/Enemies Pack FIles/Assets/Sprites"
const SAIDA := "res://assets/sprites/pixel/enemies"

## especie -> [pasta_walk, prefixo_walk, n_walk, pasta_idle, prefixo_idle,
##             n_idle, altura_alvo]
const MONSTROS := {
	"besouro": ["Bettle", "bettle", 4, "", "", 0, 48],
	"raptor": ["Dino", "dino", 7, "Dino-Idle", "dino-idle", 4, 62],
	"mastim": ["Dog", "dog", 4, "Dog-idle", "dog-idlet", 6, 56],
	"gosma": ["Slimer", "slimer", 7, "Slimer-Idle", "slimer-idle", 8, 60],
	"abutre": ["Vulture", "vulture", 4, "Vulture-Idle", "vulture-idle", 4, 58],
}


func _init() -> void:
	for esp: String in MONSTROS:
		var cfg: Array = MONSTROS[esp]
		var alt: int = cfg[6]
		var dir := "%s/%s" % [SAIDA, esp]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))

		var run := _tira(_frames(cfg[0], cfg[1], cfg[2]), alt)
		if run == null:
			print("  %s: SEM FRAMES" % esp)
			continue
		var idle := run
		var n_idle: int = cfg[2]
		if cfg[3] != "":
			var i2 := _tira(_frames(cfg[3], cfg[4], cfg[5]), alt)
			if i2 != null:
				idle = i2
				n_idle = cfg[5]
		_guardar(idle, "%s/idle.png" % dir)
		_guardar(run, "%s/run.png" % dir)
		_guardar(idle, "%s/hit.png" % dir)
		_guardar(_morte(idle, n_idle), "%s/dead.png" % dir)
		print("  %s <- %s (%d walk / %d idle, %dpx)" % [esp, cfg[0], cfg[2], cfg[5], alt])
	print("Feito. Correr --import a seguir.")
	quit(0)


func _frames(pasta: String, prefixo: String, n: int) -> Array:
	var out: Array = []
	for i in range(1, n + 1):
		var p := "%s/%s/%s%d.png" % [SPRITES, pasta, prefixo, i]
		var img := Image.new()
		if img.load(ProjectSettings.globalize_path(p)) == OK:
			out.append(img)
		else:
			push_warning("não abriu " + p)
	return out


## Tira horizontal: cada frame numa célula da largura do maior, ampliado
## (nearest) para `alt_alvo` e assente na base da célula.
func _tira(frames: Array, alt_alvo: int) -> Image:
	if frames.is_empty():
		return null
	var esc := float(alt_alvo) / float((frames[0] as Image).get_height())
	var maior := 0
	for f: Image in frames:
		maior = maxi(maior, f.get_width())
	var cw := int(ceil(maior * esc)) + 8
	var ch := alt_alvo + 8
	var tira := Image.create(cw * frames.size(), ch, false, Image.FORMAT_RGBA8)
	tira.fill(Color(0, 0, 0, 0))
	for i in frames.size():
		var f: Image = frames[i]
		var fw := int(round(f.get_width() * esc))
		var fh := int(round(f.get_height() * esc))
		var g := f.duplicate() as Image
		g.resize(maxi(1, fw), maxi(1, fh), Image.INTERPOLATE_NEAREST)
		var ox := i * cw + (cw - fw) / 2
		var oy := ch - fh - 4
		tira.blit_rect(g, Rect2i(0, 0, fw, fh), Vector2i(ox, oy))
	return tira


## Morte em 4 frames a partir do 1.º frame do idle: o bicho vai-se achatando
## contra o chão e a apagar. Chega para o "poof" que o DemonioBase precisa.
func _morte(idle: Image, celulas: int) -> Image:
	var n := 4
	var cw := idle.get_width() / maxi(1, celulas)
	var ch := idle.get_height()
	var base := idle.get_region(Rect2i(0, 0, cw, ch))
	var out := Image.create(cw * n, ch, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for i in n:
		var f := 1.0 - float(i) / float(n)          # 1 -> 0.25
		var g := base.duplicate() as Image
		var nh := maxi(2, int(round(ch * (0.25 + 0.75 * f))))
		g.resize(cw, nh, Image.INTERPOLATE_NEAREST)
		# desvanecer + escurecer
		for y in nh:
			for x in cw:
				var c := g.get_pixel(x, y)
				if c.a <= 0.0:
					continue
				g.set_pixel(x, y, Color(c.r * f, c.g * f, c.b * f, c.a * f))
		out.blit_rect(g, Rect2i(0, 0, cw, nh), Vector2i(i * cw, ch - nh))
	return out


func _guardar(img: Image, res_path: String) -> void:
	img.save_png(ProjectSettings.globalize_path(res_path))
