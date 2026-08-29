extends CanvasLayer
## Cena narrativa do fim da campanha: mostra as linhas uma a uma (avança a
## saltar/atacar) e no fim recomeça a campanha. Instanciada por
## `nivel_castelo.gd` quando o Zeriko cai.

const LINHAS := [
	"Zeriko cai. A lanterna-jaula estilhaça-se no chão de pedra.",
	"A luz que estava presa lá dentro levanta-se. Ganha ombros, mãos, um rosto cansado.",
	"«Aurora.» O nome sai de Koliani antes de ela o pensar.",
	"«Vieste mesmo», diz a mãe. «Eu sabia que virias.»",
	"Saem juntas pela última porta. Lá fora ainda é noite -- mas agora é a noite delas.",
	"-- fim --",
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
	var dica := "\n\n(saltar / atacar)" if _i < LINHAS.size() - 1 else "\n\n(saltar / atacar: recomeçar)"
	_label.text = LINHAS[_i] + dica


func _process(dt: float) -> void:
	_t += dt
	if _t < 0.35:  # ignora o toque que derrotou o Zeriko
		return
	if Input.is_action_just_pressed("saltar") or Input.is_action_just_pressed("atacar"):
		_i += 1
		if _i >= LINHAS.size():
			get_tree().paused = false
			EstadoJogo.reiniciar_campanha()
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		else:
			_t = 0.0
			_mostrar()
