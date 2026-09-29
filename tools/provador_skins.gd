extends Node2D
## PROVADOR DE SKINS -- a Koliani base e cada skin com arte real
## (`CosmeticosVisuais.DIR_SKIN`) lado a lado, a correr as animações do Golden
## Set. Não mexe no save nem precisa de Kolicoins: lê os frames das pastas.
##
##   Godot.exe --path . res://tools/ProvadorSkins.tscn
##
## Setas esquerda/direita: animação anterior/seguinte (muda sozinha a cada 3 s).
## F12: grava `user://provador_skins.png`.

const GOLD := "res://assets/sprites/koliani_golden_set/frames/"
## [pasta, fps, loop]
const ANIMS := [
	["idle", 8.0, true], ["run_final", 13.3, true], ["attack_basic", 20.0, true],
	["attack_2", 18.0, true], ["attack_3", 14.0, true], ["jump_start", 8.0, true],
	["djump", 10.0, true], ["dash", 10.0, true], ["roll", 14.0, true],
	["wallslide", 6.0, true], ["hurt", 6.0, true], ["morte", 5.0, true],
]
const ESCALA := 3.0

var _sprites: Array[AnimatedSprite2D] = []
var _anim := 0
var _t := 0.0
var _rotulo: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("1a121e"))
	var fontes: Array = [["skin_koliani_base", GOLD]]
	for id: String in CosmeticosVisuais.DIR_SKIN:
		fontes.append([id, CosmeticosVisuais.DIR_SKIN[id] + "/frames/"])
	var largura := 1280.0 / fontes.size()
	for i in fontes.size():
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		for a: Array in ANIMS:
			sf.add_animation(a[0])
			sf.set_animation_speed(a[0], a[1])
			sf.set_animation_loop(a[0], a[2])
			for f in _pngs(GOLD + a[0]):
				var cam: String = fontes[i][1] + a[0] + "/" + f
				var tex: Texture2D = load(cam) if ResourceLoader.exists(cam) else load(GOLD + a[0] + "/" + f)
				sf.add_frame(a[0], tex)
		var s := AnimatedSprite2D.new()
		s.sprite_frames = sf
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(ESCALA, ESCALA)
		s.position = Vector2(largura * (i + 0.5), 330.0)
		add_child(s)
		_sprites.append(s)
		var nome := Label.new()
		nome.text = Textos.t("shop.item.%s.name" % fontes[i][0])
		nome.add_theme_font_size_override("font_size", 22)
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nome.size = Vector2(largura, 30)
		nome.position = Vector2(largura * i, 560)
		add_child(nome)
	_rotulo = Label.new()
	_rotulo.add_theme_font_size_override("font_size", 18)
	_rotulo.position = Vector2(20, 16)
	add_child(_rotulo)
	_tocar()


func _pngs(dir: String) -> Array[String]:
	var fora: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".import"):
			f = f.get_basename()   # depois do export só há .import
		if f.get_extension() == "png" and not fora.has(f):
			fora.append(f)
	fora.sort()
	return fora


func _tocar() -> void:
	var nome: String = ANIMS[_anim][0]
	for s in _sprites:
		s.play(nome)
		s.frame = 0
	_rotulo.text = "%s  (%d/%d)   <- ->   F12 = PNG" % [nome, _anim + 1, ANIMS.size()]
	_t = 0.0


func _process(dt: float) -> void:
	_t += dt
	if _t > 3.0:
		_anim = (_anim + 1) % ANIMS.size()
		_tocar()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_right"):
		_anim = (_anim + 1) % ANIMS.size()
		_tocar()
	elif ev.is_action_pressed("ui_left"):
		_anim = (_anim - 1 + ANIMS.size()) % ANIMS.size()
		_tocar()
	elif ev is InputEventKey and ev.pressed and ev.keycode == KEY_F12:
		get_viewport().get_texture().get_image().save_png("user://provador_skins.png")
		print("provador: gravado ", ProjectSettings.globalize_path("user://provador_skins.png"))
