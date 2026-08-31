extends SceneTree
## Extrai monstros do 0x72 DungeonTileset II (CC0) para tiras horizontais em
## `assets/sprites/pixel/enemies/<especie>/{idle,run,hit,dead}.png`, no
## formato que o `DemonioBase` carrega. Cada frame é ampliado (nearest) para
## uma altura-alvo, para o bicho ficar do tamanho dos outros inimigos.
##   Godot --headless --script res://tools/extrair_monstros_0x72.gd

const FRAMES := "res://assets/sprites/incoming/0x72-dungeon-ii/0x72_DungeonTilesetII_v1.7/frames"
const SAIDA := "res://assets/sprites/pixel/enemies"

# especie -> [base_0x72, tem_run, altura_alvo]
const MONSTROS := {
	"imp":            ["imp", true, 66],
	"chort":          ["chort", true, 76],
	"orc":            ["orc_warrior", true, 78],
	"xamane":         ["orc_shaman", true, 78],
	"demonio_grande": ["big_demon", true, 96],
	"ogro":           ["ogre", true, 100],
	"abobora":        ["pumpkin_dude", true, 78],
	"wogol":          ["wogol", true, 76],
	"necromante":     ["necromancer", false, 78],
	"lodo":           ["swampy", false, 60],
}


func _init() -> void:
	for esp: String in MONSTROS:
		var cfg: Array = MONSTROS[esp]
		var base: String = cfg[0]
		var tem_run: bool = cfg[1]
		var alt: int = cfg[2]
		var dir := "%s/%s" % [SAIDA, esp]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))

		var idle := _tira(_frames_de(base, "idle", 4), alt)
		var run := _tira(_frames_de(base, "run", 4), alt) if tem_run else idle
		if idle == null:
			print("  %s: SEM FRAMES (%s)" % [esp, base])
			continue
		_guardar(idle, "%s/idle.png" % dir)
		_guardar(run if run else idle, "%s/run.png" % dir)
		_guardar(idle, "%s/hit.png" % dir)
		_guardar(idle, "%s/dead.png" % dir)
		print("  %s <- 0x72:%s  (%d frames, %dpx)" % [esp, base, idle.get_width() / maxi(1, idle.get_height()), alt])
	print("Feito. Correr --import a seguir.")
	quit(0)


## Devolve a lista de Images dos frames (idle_anim_fN / run_anim_fN, ou
## anim_fN se não houver "idle"/"run" separados).
func _frames_de(base: String, tipo: String, n: int) -> Array:
	var out: Array = []
	for i in n:
		var p := "%s/%s_%s_anim_f%d.png" % [FRAMES, base, tipo, i]
		if not FileAccess.file_exists(ProjectSettings.globalize_path(p)):
			p = "%s/%s_anim_f%d.png" % [FRAMES, base, i]
		var img := Image.new()
		if img.load(ProjectSettings.globalize_path(p)) == OK:
			out.append(img)
	return out


## Monta uma tira horizontal, cada frame numa célula de largura = maior
## frame, ampliado (nearest) para `alt_alvo` de altura mantendo o rácio.
func _tira(frames: Array, alt_alvo: int) -> Image:
	if frames.is_empty():
		return null
	var esc := float(alt_alvo) / float((frames[0] as Image).get_height())
	var cw := int(ceil((frames[0] as Image).get_width() * esc)) + 8
	var ch := alt_alvo + 8
	var tira := Image.create(cw * frames.size(), ch, false, Image.FORMAT_RGBA8)
	tira.fill(Color(0, 0, 0, 0))
	for i in frames.size():
		var f: Image = frames[i]
		var fw := int(round(f.get_width() * esc))
		var fh := int(round(f.get_height() * esc))
		var g := f.duplicate()
		g.resize(maxi(1, fw), maxi(1, fh), Image.INTERPOLATE_NEAREST)
		var ox := i * cw + (cw - fw) / 2
		var oy := ch - fh - 4
		tira.blit_rect(g, Rect2i(0, 0, fw, fh), Vector2i(ox, oy))
	return tira


func _guardar(img: Image, res_path: String) -> void:
	img.save_png(ProjectSettings.globalize_path(res_path))
