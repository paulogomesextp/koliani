extends Control
## Mapa da campanha -- overworld estilo Super Mario World. Aparece ao entrar
## no jogo em modo normal (NOVO JOGO / CONTINUAR): mostra as regioes e os
## seus niveis num caminho, deixa escolher qualquer nivel ja' alcancado e
## entra nele. O modo HARDCORE nao passa por aqui (corre linear).
##
## Ao acabar um nivel, a Porta traz de volta a este mapa (ver porta.gd). O
## estado de cada no' vem do EstadoJogo (`nivel_esta_concluido`,
## `nivel_desbloqueado`, `fronteira`).

const CENA_JOGO := "res://scenes/Main.tscn"
const CENA_MENU := "res://scenes/ui/MenuInicial.tscn"
const TEX_TOKEN := preload("res://assets/sprites/koliani.svg")

## chave i18n do nome de cada regiao (id -> chave "world.*")
const WORLD_KEY := {
	"floresta": "world.forest", "prisao": "world.prison",
	"torres": "world.towers", "catacumbas": "world.catacombs",
	"cidade": "world.city", "castelo": "world.castle",
}
## cor de cada regiao (ordem de EstadoJogo.REGIOES) -- puxada do key art
const COR_REGIAO := [
	Color(0.46, 0.78, 0.34),
	Color(0.34, 0.74, 0.85),
	Color(0.96, 0.66, 0.32),
	Color(0.62, 0.55, 0.72),
	Color(0.82, 0.40, 0.52),
	Color(0.88, 0.34, 0.80),
]
const ESPACO_X := 176.0
const Y_BASE := 396.0
const DESVIO_Y := 40.0

@onready var _titulo: Label = $Titulo
@onready var _sub: Label = $Subtitulo
@onready var _dica: Label = $Dica
@onready var _linha: Line2D = $Caminho/Linha
@onready var _nos_pai: Control = $Caminho/Nos
@onready var _token: TextureRect = $Caminho/Token
@onready var _jogar: Button = $Rodape/Jogar
@onready var _menu: Button = $Rodape/Menu

## [{ btn:Button, indice:int, regiao:int, jogavel:bool, pos:Vector2 }]
var _nos: Array = []
var _sel := 0


func _ready() -> void:
	Musica.menu()
	_construir()
	_sel = _no_do_indice(clampi(EstadoJogo.indice_nivel, 0, EstadoJogo.NIVEIS.size() - 1))
	if _nos.is_empty():
		return
	if not _nos[_sel]["jogavel"]:
		_sel = _fronteira_visivel()
	_token.texture = TEX_TOKEN
	_menu.pressed.connect(_voltar_menu)
	_jogar.pressed.connect(_entrar)
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	_atualizar(true)


## --- construcao do caminho ------------------------------------------------

func _construir() -> void:
	var pontos := PackedVector2Array()
	var col := 0
	for r in EstadoJogo.REGIOES.size():
		var reg: Dictionary = EstadoJogo.REGIOES[r]
		var niveis: Array = reg["niveis"]
		if niveis.is_empty():
			var m := _fazer_no(r, -1, false)
			var pm := _pos_coluna(col)
			m.position = pm - m.custom_minimum_size * 0.5
			_nos_pai.add_child(m)
			_nos.append({ "btn": m, "indice": -1, "regiao": r, "jogavel": false, "pos": pm })
			pontos.append(pm)
			col += 1
			continue
		for idx in niveis:
			var jog: bool = EstadoJogo.nivel_desbloqueado(idx)
			var b := _fazer_no(r, idx, jog)
			var p := _pos_coluna(col)
			b.position = p - b.custom_minimum_size * 0.5
			var alvo: int = idx
			b.pressed.connect(func() -> void: _clique(alvo))
			_nos_pai.add_child(b)
			_nos.append({ "btn": b, "indice": idx, "regiao": r, "jogavel": jog, "pos": p })
			pontos.append(p)
			col += 1
	_linha.points = pontos
	# centra o caminho no ecra se sobrar espaco
	var largura := ESPACO_X * maxf(1.0, float(col - 1))
	var margem := (get_viewport_rect().size.x - largura) * 0.5
	_nos_pai.position.x = maxf(40.0, margem) - 120.0
	_linha.position = _nos_pai.position


func _pos_coluna(col: int) -> Vector2:
	var y := Y_BASE + (DESVIO_Y if col % 2 == 1 else -DESVIO_Y)
	return Vector2(120.0 + col * ESPACO_X, y)


func _fazer_no(regiao: int, indice: int, jogavel: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 94)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.disabled = not jogavel
	b.clip_text = false
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 15)
	b.set_meta("regiao", regiao)
	b.set_meta("indice", indice)
	_estilo_no(b, regiao, indice, jogavel, false)
	return b


func _estilo_no(b: Button, regiao: int, indice: int, jogavel: bool, escolhido: bool) -> void:
	var base: Color = COR_REGIAO[regiao] if regiao < COR_REGIAO.size() else Color(0.6, 0.6, 0.7)
	var concluido := indice >= 0 and EstadoJogo.nivel_esta_concluido(indice)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.border_color = base
	sb.set_border_width_all(2)
	if indice < 0:
		sb.bg_color = Color(0.06, 0.05, 0.09, 0.8)
		sb.border_color = Color(0.4, 0.38, 0.46, 0.6)
	elif not jogavel:
		sb.bg_color = Color(0.06, 0.05, 0.09, 0.85)
		sb.border_color = base.darkened(0.55)
	elif concluido:
		sb.bg_color = base.darkened(0.35)
		sb.bg_color.a = 0.92
	else:
		sb.bg_color = Color(0.09, 0.06, 0.12, 0.92)
	if escolhido:
		sb.border_color = Color(1, 0.9, 0.55)
		sb.set_border_width_all(4)
		sb.shadow_color = Color(1, 0.85, 0.4, 0.5)
		sb.shadow_size = 10
	for e in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(e, sb)
	var fc := Color(0.95, 0.92, 1) if (jogavel or indice < 0) else Color(0.55, 0.52, 0.62)
	b.add_theme_color_override("font_color", fc)
	b.add_theme_color_override("font_disabled_color", fc)


## --- estado / seleccao --------------------------------------------------

func _no_do_indice(indice: int) -> int:
	for i in _nos.size():
		if _nos[i]["indice"] == indice:
			return i
	return 0


func _fronteira_visivel() -> int:
	var melhor := 0
	for i in _nos.size():
		if _nos[i]["jogavel"]:
			melhor = i
	return melhor


func _clique(indice: int) -> void:
	var i := _no_do_indice(indice)
	if not _nos[i]["jogavel"]:
		return
	if i == _sel:
		_entrar()
	else:
		_sel = i
		Som.toca("apanhar", -16.0, 1.25)
		_atualizar(false)


func _mover(dir: int) -> void:
	var i := _sel + dir
	while i >= 0 and i < _nos.size():
		if _nos[i]["jogavel"]:
			_sel = i
			Som.toca("apanhar", -17.0, 1.3)
			_atualizar(false)
			return
		i += dir


func _input(e: InputEvent) -> void:
	if e.is_action_pressed("mover_direita") or e.is_action_pressed("ui_right"):
		_mover(1)
		accept_event()
	elif e.is_action_pressed("mover_esquerda") or e.is_action_pressed("ui_left"):
		_mover(-1)
		accept_event()
	elif e.is_action_pressed("saltar") or e.is_action_pressed("atacar") or e.is_action_pressed("ui_accept"):
		_entrar()
		accept_event()
	elif e.is_action_pressed("pausa") or e.is_action_pressed("ui_cancel"):
		_voltar_menu()
		accept_event()


func _atualizar(instantaneo: bool) -> void:
	if _nos.is_empty():
		return
	var no: Dictionary = _nos[_sel]
	for i in _nos.size():
		var n: Dictionary = _nos[i]
		_estilo_no(n["btn"], n["regiao"], n["indice"], n["jogavel"], i == _sel)

	# pan horizontal: mantém o nó escolhido perto do centro do ecrã. Com 30
	# níveis o caminho é uma faixa muito mais larga que o ecrã, por isso é
	# preciso rolar (o `_construir` só o centrava quando cabia todo).
	var ecra_x := get_viewport_rect().size.x
	var largura := ESPACO_X * maxf(1.0, float(_nos.size() - 1))
	var no_pos: Vector2 = no["pos"]
	var pan_x: float = ecra_x * 0.5 - no_pos.x
	if largura > ecra_x - 160.0:
		pan_x = clampf(pan_x, ecra_x - 120.0 - largura, 120.0)
	else:
		pan_x = maxf(40.0, (ecra_x - largura) * 0.5) - 120.0
	var pan := Vector2(pan_x, _nos_pai.position.y)

	var destino: Vector2 = pan + no_pos + Vector2(0, -84) - _token.size * Vector2(0.5, 0.0)
	if instantaneo:
		_nos_pai.position = pan
		_linha.position = pan
		_token.position = destino
	else:
		var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(_nos_pai, "position", pan, 0.22)
		t.tween_property(_linha, "position", pan, 0.22)
		t.tween_property(_token, "position", destino, 0.22)
	_jogar.disabled = not no["jogavel"]
	_atualizar_titulo(no)


func _atualizar_titulo(no: Dictionary) -> void:
	var reg: Dictionary = EstadoJogo.REGIOES[no["regiao"]]
	_titulo.text = Textos.t(WORLD_KEY.get(reg["id"], "world.unknown"))
	if no["indice"] < 0:
		_sub.text = Textos.t("map.soon")
		return
	var pos_reg: int = (reg["niveis"] as Array).find(no["indice"]) + 1
	var linha := Textos.tf("map.level", [pos_reg])
	if EstadoJogo.nivel_esta_concluido(no["indice"]):
		linha += "   ·   " + Textos.t("map.done")
	elif not no["jogavel"]:
		linha += "   ·   " + Textos.t("map.locked")
	_sub.text = linha


func _traduzir() -> void:
	_dica.text = Textos.t("map.hint")
	_jogar.text = Textos.t("map.play")
	_menu.text = Textos.t("map.back")
	for n: Dictionary in _nos:
		n["btn"].text = _texto_no(n)
	if not _nos.is_empty():
		_atualizar_titulo(_nos[_sel])


func _texto_no(n: Dictionary) -> String:
	var reg: Dictionary = EstadoJogo.REGIOES[n["regiao"]]
	var nome := Textos.t(WORLD_KEY.get(reg["id"], "world.unknown"))
	if n["indice"] < 0:
		return nome + "\n" + Textos.t("map.soon")
	var pos_reg: int = (reg["niveis"] as Array).find(n["indice"]) + 1
	var t := nome + "\n" + Textos.tf("map.level", [pos_reg])
	if EstadoJogo.nivel_esta_concluido(n["indice"]):
		t += "  ✓"
	elif not n["jogavel"]:
		t += "  ✗"
	return t


## --- accoes ----------------------------------------------------------

func _entrar() -> void:
	if _nos.is_empty():
		return
	var no: Dictionary = _nos[_sel]
	if not no["jogavel"]:
		Som.toca("dano", -18.0, 0.8)
		return
	Som.toca("porta", -6.0)
	EstadoJogo.indice_nivel = no["indice"]
	EstadoJogo.checkpoint = Vector2.ZERO
	EstadoJogo.guardar()
	set_process_input(false)
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))


func _voltar_menu() -> void:
	set_process_input(false)
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MENU))
