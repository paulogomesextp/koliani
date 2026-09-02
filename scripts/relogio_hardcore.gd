extends CanvasLayer
## Relógio do modo hardcore. Conta para trás o tempo do mundo atual
## (`EstadoJogo.tempo_hardcore_nivel()`); ao chegar a zero instancia o
## `game_over.gd`. O `main.gd` só o cria quando `EstadoJogo.hardcore`.
##
## Herda o process_mode do Main, por isso PÁRA quando a árvore está em
## pausa (menu de pausa, diário) -- o tempo só corre a jogar.
##
## O tempo que falta vive em `EstadoJogo.hardcore_tempo_restante`, por isso
## **continua a contar através das mortes** (o autoload não recarrega). Só
## é reposto ao mudar de mundo ou ao recomeçar a campanha.
##
## Dev: `-- --hc-tempo=N` força N segundos (afinação / ver o Game Over
## depressa).

var _restante := 0.0
var _acabou := false
var _label: Label


func _ready() -> void:
	layer = 12
	if EstadoJogo.hardcore_tempo_restante > 0.0:
		_restante = EstadoJogo.hardcore_tempo_restante
	else:
		_restante = EstadoJogo.tempo_hardcore_nivel()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hc-tempo="):
			_restante = maxf(1.0, float(a.get_slice("=", 1)))
	EstadoJogo.hardcore_tempo_restante = _restante

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
	EstadoJogo.hardcore_tempo_restante = _restante  # sobrevive a mortes/recargas
	_atualizar()
	if _restante <= 0.0:
		_acabou = true
		# pedido do Paulo (2 set 2026): esgotar o tempo já não manda a
		# campanha toda de volta ao nível 1 -- recomeça só o nível atual
		# (vidas cheias, relógio cheio, checkpoint no início), mantendo o
		# equipamento/progresso ganho. A "3 vidas gastas" continua a
		# reiniciar a campanha toda (ver koliani.gd::_morrer) -- só o
		# tempo esgotado é que ficou mais brando.
		EstadoJogo.reiniciar_run()
		Transicao.fechar_e(get_tree().reload_current_scene)


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
