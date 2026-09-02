class_name Balao
extends CanvasLayer
## Balão de fala das cenas de história (chefes que falam). NÃO pára o jogo:
## flutua por cima do orador (a cauda aponta-lhe), escreve o texto letra a
## letra e AVANÇA SOZINHO ao fim de cada linha -- o combate continua a
## correr por baixo. Antes congelava a árvore e esperava um toque; o Paulo
## pediu sem pausas (2 set 2026).
##
## Não instanciar à mão -- `await Dialogo.correr(falas)`. Cada fala é
## `{ "quem": <chave i18n>, "texto": <chave i18n> }`, opcional
## `{ "alvo": Node2D }` para a cauda apontar a esse nó do mundo.

signal terminado

const LARGURA := 380.0
const VEL_LETRAS := 44.0             # caracteres por segundo
const ESPERA_MIN := 1.3              # hold mínimo depois de revelar a linha
const ESPERA_POR_CHAR := 0.035
const ESPERA_MAX := 4.0
const ACIMA_DO_ALVO := 150.0         # px que o balão fica acima da origem do orador
const MARGEM_ECRA := 24.0

var _falas: Array = []
var _i := 0
var _texto_alvo := ""
var _revelado := 0.0
var _a_escrever := false
var _espera := 0.0
var _alvo: Node2D
var _ancora_ecra := Vector2.ZERO     # última posição de ecrã conhecida do orador

var _raiz: Control                   # porta o fade (CanvasLayer não tem modulate)
var _painel: PanelContainer
var _nome: Label
var _corpo: RichTextLabel
var _cauda: Polygon2D


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_montar()
	set_process(false)
	visible = false


## Corre a sequência. `await` até ao fim. `_pausar` é ignorado (fica no
## assinatura por compatibilidade com `Dialogo.correr`).
func reproduzir(falas: Array, _pausar := false) -> void:
	_falas = falas
	if _falas.is_empty():
		terminado.emit()
		queue_free()
		return
	visible = true
	_raiz.modulate.a = 0.0
	set_process(true)
	_i = -1
	_avancar()
	create_tween().tween_property(_raiz, "modulate:a", 1.0, 0.18)
	await terminado
	if is_instance_valid(self):
		var t := create_tween()
		t.tween_property(_raiz, "modulate:a", 0.0, 0.16)
		await t.finished
	queue_free()


# --- construção -------------------------------------------------------

func _montar() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE  # não rouba toque ao jogo
	add_child(_raiz)

	_cauda = Polygon2D.new()
	_cauda.color = Color(0.12, 0.09, 0.17, 0.96)
	_raiz.add_child(_cauda)

	_painel = PanelContainer.new()
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.custom_minimum_size = Vector2(LARGURA, 0.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.09, 0.17, 0.96)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.86, 0.4, 0.82, 0.95)
	sb.shadow_color = Color(0.5, 0.15, 0.6, 0.35)
	sb.shadow_size = 12
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_painel.add_theme_stylebox_override("panel", sb)
	_raiz.add_child(_painel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_painel.add_child(col)

	_nome = Label.new()
	_nome.add_theme_font_size_override("font_size", 16)
	_nome.add_theme_color_override("font_color", Color(1, 0.72, 0.95))
	col.add_child(_nome)

	var risca := HSeparator.new()
	col.add_child(risca)

	_corpo = RichTextLabel.new()
	_corpo.bbcode_enabled = true
	_corpo.fit_content = true
	_corpo.scroll_active = false
	_corpo.custom_minimum_size = Vector2(LARGURA - 36.0, 0.0)
	_corpo.add_theme_font_size_override("normal_font_size", 17)
	_corpo.add_theme_color_override("default_color", Color(0.96, 0.93, 1))
	col.add_child(_corpo)


# --- sequência -------------------------------------------------------

func _avancar() -> void:
	_i += 1
	if _i >= _falas.size():
		set_process(false)
		terminado.emit()
		return
	var fala: Dictionary = _falas[_i]
	if fala.has("alvo"):
		_alvo = fala["alvo"]
	_nome.text = Textos.t(fala.get("quem", "")).to_upper()
	_texto_alvo = Textos.t(fala.get("texto", ""))
	_revelado = 0.0
	_a_escrever = true
	_espera = 0.0
	_corpo.text = ""
	Som.toca("apanhar", -20.0, 1.4)


func _process(dt: float) -> void:
	if _a_escrever:
		_revelado = minf(_revelado + VEL_LETRAS * dt, float(_texto_alvo.length()))
		_corpo.text = _texto_alvo.substr(0, int(_revelado))
		if int(_revelado) >= _texto_alvo.length():
			_a_escrever = false
			_espera = clampf(ESPERA_MIN + _texto_alvo.length() * ESPERA_POR_CHAR,
				ESPERA_MIN, ESPERA_MAX)
	else:
		_espera -= dt
		if _espera <= 0.0:
			_avancar()
	_posicionar()


## Segue o orador no ecrã: painel centrado por cima da cabeça, cauda a
## apontar-lhe. Se o orador desaparecer, fica na última posição.
func _posicionar() -> void:
	if is_instance_valid(_alvo):
		_ancora_ecra = _alvo.get_global_transform_with_canvas().origin
	var vp := get_viewport().get_visible_rect().size
	_painel.reset_size()
	var tam := _painel.size
	var px := clampf(_ancora_ecra.x - tam.x * 0.5,
		MARGEM_ECRA, vp.x - tam.x - MARGEM_ECRA)
	var py := clampf(_ancora_ecra.y - ACIMA_DO_ALVO - tam.y,
		MARGEM_ECRA, vp.y - tam.y - MARGEM_ECRA)
	_painel.position = Vector2(px, py)
	# cauda: do fundo do painel até um ponto sobre o orador
	var base := Vector2(clampf(_ancora_ecra.x, px + 18.0, px + tam.x - 18.0),
		py + tam.y)
	var ponta := Vector2(clampf(_ancora_ecra.x, base.x - 40.0, base.x + 40.0),
		minf(_ancora_ecra.y - 12.0, base.y + 46.0))
	_cauda.polygon = PackedVector2Array([
		base + Vector2(-16.0, -2.0), base + Vector2(16.0, -2.0), ponta,
	])
