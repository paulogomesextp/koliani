extends CanvasLayer
## Cena narrativa do fim da campanha: mostra as linhas uma a uma (avança a
## saltar/atacar) e no fim volta ao menu inicial (o save fica como está --
## o jogador escolhe NEW GAME / LOAD GAME / HARDCORE MODE). Instanciada por
## `nivel_castelo.gd` quando o Zeriko cai.

## chaves de tradução das linhas, por ordem (ver assets/i18n: final.line1..6)
const LINHAS := [
	"final.line1", "final.line2", "final.line3",
	"final.line4", "final.line5", "final.line6",
]

var _i := 0
var _t := 0.0
var _label: Label


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS

	var fundo := ColorRect.new()
	fundo.color = Color(0.02, 0.01, 0.04, 0.97)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_constant_override("line_spacing", 8)
	_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.99))
	add_child(_label)

	get_tree().paused = true
	_mostrar()


func _mostrar() -> void:
	var chave_dica := "final.prompt" if _i < LINHAS.size() - 1 else "final.prompt_last"
	_label.text = Textos.t(LINHAS[_i]) + "\n\n" + Textos.t(chave_dica)


func _process(dt: float) -> void:
	_t += dt
	if _t < 0.35:  # ignora o toque que derrotou o Zeriko
		return
	if Input.is_action_just_pressed("saltar") or Input.is_action_just_pressed("atacar"):
		_i += 1
		if _i >= LINHAS.size():
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/ui/MenuInicial.tscn")
		else:
			_t = 0.0
			_mostrar()
