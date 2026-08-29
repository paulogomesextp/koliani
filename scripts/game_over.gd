extends CanvasLayer
class_name GameOver
## Cartão de "GAME OVER". Aparece quando um run acaba:
##  - modo hardcore: o tempo do mundo esgotou-se (`relogio_hardcore.gd`);
##  - modo hardcore: gastaram-se as 3 vidas (`koliani.gd`).
## Pausa a árvore, toca a voz "GAME OVER" e -- a um toque em saltar/atacar
## -- recomeça a campanha do mundo 1 (mantém o hardcore ligado).
##
## Usar via `GameOver.mostrar(get_tree(), "time"|"lives")`.

var _motivo := ""   # "time" ou "lives" -- escolhe a linha explicativa
var _t := 0.0
var _pronto := false


## Cria e mostra o cartão por cima da cena atual.
static func mostrar(arvore: SceneTree, motivo: String) -> void:
	var over := CanvasLayer.new()
	over.set_script(load("res://scripts/game_over.gd"))
	over.set("_motivo", motivo)
	var pai: Node = arvore.current_scene
	if pai == null:
		pai = arvore.root
	pai.add_child(over)


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS

	var fundo := ColorRect.new()
	fundo.color = Color(0.06, 0.01, 0.02, 0.96)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var razao := "gameover.reason.time" if _motivo == "time" else "gameover.reason.lives"
	var texto := Label.new()
	texto.text = "%s\n\n%s\n%s\n\n%s" % [
		Textos.t("gameover.title"), Textos.t(razao),
		Textos.t("gameover.restart_note"), Textos.t("gameover.prompt"),
	]
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_constant_override("line_spacing", 8)
	texto.add_theme_color_override("font_color", Color(1, 0.7, 0.62))
	add_child(texto)

	get_tree().paused = true
	Som.toca("game_over", 0.0)


func _process(dt: float) -> void:
	_t += dt
	if not _pronto:
		# folga para ignorar o toque que vinha do jogo
		_pronto = _t >= 0.5
		return
	if Input.is_action_just_pressed("saltar") or Input.is_action_just_pressed("atacar"):
		get_tree().paused = false
		EstadoJogo.reiniciar_campanha()  # não mexe no hardcore -> continua hardcore
		Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file("res://scenes/Main.tscn"))
