extends CanvasLayer
## HUD: barra de vida + vidas (sempre visíveis) e os botões de toque
## (`Toque`), que só aparecem em ecrã táctil / ao primeiro toque. Mostra
## também avisos curtos ao ganhar habilidade ou encontrar pista.

## chave de tradução do nome de cada habilidade (ver assets/i18n)
const NOME_HABILIDADE := {
	"salto_duplo": "hud.ability.salto_duplo",
	"dash_aereo": "hud.ability.dash_aereo",
	"partir_paredes": "hud.ability.partir_paredes",
	"escudo": "hud.ability.escudo",
	"projetil": "hud.ability.projetil",
}

@onready var _barra_vida: ProgressBar = $Vida/Barra
@onready var _barra_energia: ProgressBar = $Energia/Barra
@onready var _label_vidas: Label = $Vidas/Label
@onready var _toque: Control = $Toque


func _ready() -> void:
	if _toque:
		_toque.visible = DisplayServer.is_touchscreen_available()
	# a barra de Energia só aparece depois de apanhar a habilidade "projetil"
	if _barra_energia:
		_barra_energia.get_parent().visible = EstadoJogo.tem_habilidade("projetil")
	EstadoJogo.vidas_mudaram.connect(_atualizar_vidas)
	EstadoJogo.habilidade_desbloqueada.connect(_ao_habilidade)
	EstadoJogo.pista_encontrada.connect(_ao_pista)
	_atualizar_vidas(EstadoJogo.vidas)
	var koliani := get_tree().get_first_node_in_group("koliani")
	if koliani and koliani.has_signal("vida_mudou"):
		koliani.vida_mudou.connect(_atualizar_barra_vida)
	if koliani and koliani.has_signal("energia_mudou"):
		koliani.energia_mudou.connect(_atualizar_energia)


func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch and _toque and not _toque.visible:
		_toque.visible = true


func _atualizar_barra_vida(atual: int, maximo: int) -> void:
	if _barra_vida:
		_barra_vida.max_value = maximo
		_barra_vida.value = atual


func _atualizar_energia(atual: float, maximo: float) -> void:
	if _barra_energia:
		_barra_energia.max_value = maximo
		_barra_energia.value = atual


func _atualizar_vidas(vidas: int) -> void:
	if _label_vidas:
		_label_vidas.text = "x%d" % vidas


func _ao_habilidade(id: String) -> void:
	if id == "projetil" and _barra_energia:
		_barra_energia.get_parent().visible = true
	var nome: String = Textos.t(NOME_HABILIDADE.get(id, id))
	_aviso(Textos.tf("hud.new_ability", [nome]))


func _ao_pista(_id: String, total: int) -> void:
	_aviso(Textos.tf("hud.clue_found", [total]))


func _aviso(txt: String) -> void:
	var l := Label.new()
	l.text = "  " + txt + "  "
	var larg := get_viewport().get_visible_rect().size.x
	l.position = Vector2(larg * 0.5 - 130.0, 68.0)
	l.add_theme_color_override("font_color", Color(1, 0.92, 1))
	l.add_theme_font_size_override("font_size", 20)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.55, 0.18, 0.5, 0.9)
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(6)
	l.add_theme_stylebox_override("normal", sb)
	add_child(l)
	var t := l.create_tween()
	t.tween_interval(1.8)
	t.tween_property(l, "modulate:a", 0.0, 0.6)
	t.tween_callback(l.queue_free)
