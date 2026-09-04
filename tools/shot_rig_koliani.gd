extends Node2D
## Folha de contacto do rig da Koliani, JÁ DENTRO DO JOGO.
##
## Monta a `Koliani.tscn` a sério (portanto passa pelo `_montar_frames`, pela
## escala/desvio do rig e pelo shader do equipamento) uma vez por estado, com
## os pés todos na mesma linha, e grava um PNG. É a maneira de ver de relance
## se algum estado ficou desalinhado, com o boneco a dobrar ou virado ao
## contrário -- que foi o que o Paulo apanhou a jogar (4 set 2026).
##
## A última coluna mostra a pose de parede ESPELHADA, para se confirmar que
## numa parede à esquerda a Koliani se agarra do lado certo.
##
## Corre-se como CENA (e não com `--script`), senão os autoloads não existem
## e o `koliani.gd` nem compila:
##
##   Godot --window --screen 1 res://tools/RigKoliani.tscn -- [saida.png] [frame]

const KOLIANI := preload("res://scenes/actors/Koliani.tscn")
## Um estado por coluna, na ordem em que se veem a jogar.
const ESTADOS := ["idle", "run", "jump", "fall", "aterrar", "attack",
	"attack2", "attack3", "attack4", "crouch", "djump", "wallslide"]
const COLUNA := 96
const LINHA_CHAO := 300


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else "user://rig_koliani.png"
	var frame_fixo: int = int(args[1]) if args.size() > 1 else -1

	var fundo := ColorRect.new()
	fundo.color = Color(0.1, 0.08, 0.13)
	fundo.size = Vector2(get_viewport().size)
	add_child(fundo)
	var chao := ColorRect.new()
	chao.color = Color(0.35, 0.78, 0.5, 0.5)
	chao.position = Vector2(0, LINHA_CHAO)
	chao.size = Vector2(get_viewport().size.x, 1)
	add_child(chao)

	var x := 60
	for estado: String in ESTADOS:
		_por_estado(estado, x, 1.0, estado)
		x += COLUNA
	_por_estado("wallslide", x, -1.0, "parede <-")

	for _i in 14:
		await get_tree().process_frame
	if frame_fixo >= 0:
		for k in get_children():
			if k.has_node("Sprite/Corpo"):
				var c: AnimatedSprite2D = k.get_node("Sprite/Corpo")
				c.stop()
				c.frame = mini(frame_fixo, c.sprite_frames.get_frame_count(c.animation) - 1)
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

	get_viewport().get_texture().get_image().save_png(saida)
	print("shot -> ", saida)
	get_tree().quit()


## Uma Koliani parada, num estado, com os pés na linha do chão. O nó é
## congelado (sem física nem `_process`) para não cair, não mudar de animação
## sozinho e não repor o flip.
func _por_estado(estado: String, x: int, flip: float, rotulo: String) -> void:
	var k: Node2D = KOLIANI.instantiate()
	add_child(k)
	# a colisão mede 44 de alto: a base fica 22 abaixo da origem
	k.position = Vector2(x, LINHA_CHAO - 22)
	k.set_physics_process(false)
	k.set_process(false)
	var cam: Camera2D = k.get_node("Camera2D")
	cam.enabled = false
	var corpo: AnimatedSprite2D = k.get_node("Sprite/Corpo")
	if corpo.sprite_frames != null and corpo.sprite_frames.has_animation(estado):
		corpo.play(estado)
	var sprite: Node2D = k.get_node("Sprite")
	sprite.scale = Vector2(flip, 1.0)

	var etiqueta := Label.new()
	etiqueta.text = rotulo
	etiqueta.position = Vector2(x - 42, LINHA_CHAO + 8)
	etiqueta.add_theme_color_override("font_color", Color(1, 0.88, 0.4))
	add_child(etiqueta)
