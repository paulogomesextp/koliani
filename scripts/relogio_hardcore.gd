extends CanvasLayer
## Relógio do modo hardcore. Conta para trás o tempo do mundo atual
## (`EstadoJogo.tempo_hardcore_nivel()`); ao chegar a zero instancia o
## `game_over.gd`. O `main.gd` só o cria quando `EstadoJogo.hardcore`.
##
## Herda o process_mode do Main, por isso PÁRA quando a árvore está em
## pausa (menu de pausa, diário) -- o tempo só corre a jogar. Reinicia a
## cada (re)carga de cena: uma morte com respawn dá relógio novo.
##
## Dev: `-- --hc-tempo=N` força N segundos em todos os mundos (afinação /
## testar o Game Over depressa).

var _restante := 0.0
var _acabou := false
var _label: Label


func _ready() -> void:
	layer = 12
	_restante = EstadoJogo.tempo_hardcore_nivel()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hc-tempo="):
			_restante = maxf(1.0, float(a.get_slice("=", 1)))

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_label.offset_top = 14.0
	_label.offset_bottom = 60.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.03, 0.9))
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	_atualizar()


func _process(dt: float) -> void:
	if _acabou:
		return
	_restante -= dt
	_atualizar()
	if _restante <= 0.0:
		_acabou = true
		var over := CanvasLayer.new()
		over.set_script(load("res://scripts/game_over.gd"))
		add_child(over)


func _atualizar() -> void:
	var s := maxi(0, ceili(_restante))
	_label.text = "%d:%02d" % [s / 60, s % 60]
	var perto := _restante <= 10.0
	if perto:
		# pulsa entre vermelho e branco no último troço
		var f := 0.5 + 0.5 * sin(_restante * TAU * 2.0)
		_label.modulate = Color(1.0, 0.35 + 0.5 * f, 0.35 + 0.5 * f)
	else:
		_label.modulate = Color(1.0, 0.88, 0.5)
