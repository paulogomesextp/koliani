class_name SeletorNiveis
extends Control
## Seletor da campanha: primeiro escolhe-se uma região, depois um dos seus
## cinco níveis. A tabela canónica e o progresso continuam em EstadoJogo.
## Esta cena só apresenta estado e emite `escolhido`; não possui save próprio.

signal escolhido(indice: int)
signal cancelado

const ROMANOS := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
    "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]
## Referência de arte mantida para as ferramentas existentes. O Pass 1 usa a
## pele da região via TemaRegiao, sem alterar estes caminhos.
const FUNDO_REGIAO := [
    "res://assets/sprites/pixel/backgrounds/floresta/middle.png",
    "res://assets/sprites/pixel/backgrounds/prisao/middle.png",
    "res://assets/sprites/pixel/backgrounds/montanhas/trees.png",
    "res://assets/sprites/pixel/backgrounds/caverna/back-walls.png",
    "res://assets/sprites/pixel/backgrounds/vilanoite/casario.png",
    "res://assets/sprites/pixel/backgrounds/luar/serra.png",
    "res://assets/sprites/pixel/backgrounds/floresta/front.png",
    "res://assets/sprites/pixel/backgrounds/vilanoite/vila.png",
    "res://assets/sprites/pixel/backgrounds/pantano/mid1.png",
    "res://assets/sprites/pixel/backgrounds/rochoso/middle.png",
    "res://assets/sprites/pixel/backgrounds/floresta/back.png",
    "res://assets/sprites/pixel/backgrounds/masmorra/celas.png",
    "res://assets/sprites/pixel/backgrounds/montanhas/far.png",
    "res://assets/sprites/pixel/backgrounds/vilanoite/serra.png",
    "res://assets/sprites/pixel/backgrounds/prisao/near.png",
    "res://assets/sprites/pixel/backgrounds/pantano/trees.png",
    "res://assets/sprites/pixel/backgrounds/castelo_velho/salao.png",
    "res://assets/sprites/pixel/backgrounds/rochoso/near.png",
    "res://assets/sprites/pixel/backgrounds/cidade/vila.png",
    "res://assets/sprites/pixel/backgrounds/luar/campo.png",
]
const COLUNAS_REGIOES := 4
const CARTAO_REGIAO := Vector2(286, 92)
const CARTAO_NIVEL := Vector2(190, 136)

var _respeitar_bloqueio := true
var _sel := 0
var _regiao := 0
var _vista_regioes := true
var _pronto := false
var _palco: Control
var _arte: TextureRect
var _barras: TextureRect
var _titulo: Label
var _subtitulo: Label
var _voltar: Button
var _santuario_botao: Button
var _regioes_painel: Control
var _niveis_painel: Control
var _region_cards: Array[Button] = []
var _level_cards: Array[Button] = []
## Aliases de compatibilidade para ferramentas/testes antigos do selector.
var _abas: Array[Button] = []
var _nos: Array[Dictionary] = []
var _jogar: Button
var _estado: Label
var _detalhe: Label
var _santuario: Control

const SANTUARIO_CENA := preload("res://scenes/ui/Santuario.tscn")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_preset(Control.PRESET_FULL_RECT)
    Frontend9H.vestir(self)
    _montar()
    _pronto = true
    Textos.idioma_mudou.connect(func(_l: String) -> void: _actualizar())
    _actualizar()

func configurar(indice_inicial: int, respeitar_bloqueio: bool) -> void:
    _respeitar_bloqueio = respeitar_bloqueio
    var alvo := clampi(indice_inicial, 0, EstadoJogo.NIVEIS.size() - 1)
    if _respeitar_bloqueio and not EstadoJogo.nivel_desbloqueado(alvo):
        alvo = EstadoJogo.fronteira()
    _sel = alvo
    _regiao = maxi(0, EstadoJogo.regiao_do_nivel(alvo))
    _vista_regioes = true
    if _pronto:
        _actualizar()

func _montar() -> void:
    _palco = Frontend9H.palco(self, "fundo_seletor")
    _arte = _palco.get_node_or_null("Arte") as TextureRect
    _barras = get_node_or_null("Barras") as TextureRect
    _palco.add_child(Frontend9H.vinheta())
    _voltar = _botao("", 15)
    _voltar.pressed.connect(_voltar_premido)
    Frontend9H.por(_voltar, Rect2(28, 18, 180, 42))
    _palco.add_child(_voltar)
    _santuario_botao = _botao("", 14)
    _santuario_botao.pressed.connect(_abrir_santuario)
    Frontend9H.por(_santuario_botao, Rect2(1040, 18, 220, 42))
    _palco.add_child(_santuario_botao)
    _titulo = Label.new()
    Frontend9H.cabecalho(_titulo, 29)
    _titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    Frontend9H.por(_titulo, Rect2(260, 24, 760, 42))
    _palco.add_child(_titulo)
    _subtitulo = Label.new()
    Frontend9H.corpo(_subtitulo, 14, Frontend9H.TEXTO_APAGADO)
    _subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    Frontend9H.por(_subtitulo, Rect2(260, 66, 760, 26))
    _palco.add_child(_subtitulo)
    _regioes_painel = Control.new()
    _regioes_painel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _regioes_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _palco.add_child(_regioes_painel)
    _montar_regioes()
    _niveis_painel = Control.new()
    _niveis_painel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _niveis_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _palco.add_child(_niveis_painel)
    _montar_niveis()

func _botao(texto: String, tamanho: int) -> Button:
    var b := Button.new()
    b.text = texto
    b.focus_mode = Control.FOCUS_ALL
    b.clip_text = true
    Frontend9H.rotulo_menu(b, tamanho)
    return b

func _caixa(cor: Color, borda: Color, raio := 8, largura := 2) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = cor
    s.border_color = borda
    s.set_border_width_all(largura)
    s.set_corner_radius_all(raio)
    s.content_margin_left = 12.0
    s.content_margin_right = 12.0
    s.content_margin_top = 8.0
    s.content_margin_bottom = 8.0
    return s

func _estilo_cartao(b: Button, primaria: Color, ativo: bool, bloqueado: bool) -> void:
    var fundo := Color(0.035, 0.026, 0.055, 0.94) if not bloqueado else Color(0.025, 0.025, 0.035, 0.82)
    var linha := primaria if ativo else Color(0.28, 0.25, 0.36, 0.9)
    if bloqueado:
        linha = Color(0.22, 0.22, 0.27, 0.75)
    b.add_theme_stylebox_override("normal", _caixa(fundo, linha, 8, 2))
    b.add_theme_stylebox_override("hover", _caixa(fundo.lightened(0.10), primaria, 8, 2))
    b.add_theme_stylebox_override("focus", _caixa(fundo.lightened(0.14), primaria, 8, 3))
    b.add_theme_stylebox_override("pressed", _caixa(fundo.lightened(0.05), primaria, 8, 2))
    b.add_theme_color_override("font_color", Frontend9H.TEXTO_APAGADO if bloqueado else Frontend9H.OSSO)
    b.add_theme_color_override("font_hover_color", Frontend9H.OSSO)
    b.add_theme_color_override("font_focus_color", Frontend9H.OSSO)
    b.modulate = Color(0.62, 0.62, 0.70, 0.82) if bloqueado else Color.WHITE

func _montar_regioes() -> void:
    for r in EstadoJogo.REGIOES.size():
        var b := _botao("", 16)
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.pressed.connect(_abrir_regiao.bind(r))
        b.focus_entered.connect(_selecionar_regiao.bind(r))
        b.mouse_entered.connect(_selecionar_regiao.bind(r))
        var coluna := r % COLUNAS_REGIOES
        var linha := r / COLUNAS_REGIOES
        Frontend9H.por(b, Rect2(62 + coluna * 306, 112 + linha * 108, CARTAO_REGIAO.x, CARTAO_REGIAO.y))
        _regioes_painel.add_child(b)
        _region_cards.append(b)
    _abas = _region_cards

func _montar_niveis() -> void:
    var painel := ColorRect.new()
    painel.color = Color(0.025, 0.018, 0.040, 0.92)
    painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    Frontend9H.por(painel, Rect2(48, 108, 1184, 264))
    _niveis_painel.add_child(painel)
    for i in 5:
        var b := _botao("", 19)
        b.alignment = HORIZONTAL_ALIGNMENT_CENTER
        b.pressed.connect(_selecionar_nivel.bind(i))
        b.focus_entered.connect(_selecionar_nivel.bind(i))
        Frontend9H.por(b, Rect2(74 + i * 226, 142, CARTAO_NIVEL.x, CARTAO_NIVEL.y))
        _niveis_painel.add_child(b)
        _level_cards.append(b)
        _nos.append({"botao": b, "indice": -1})
    _detalhe = Label.new()
    Frontend9H.corpo(_detalhe, 16, Frontend9H.TEXTO)
    _detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    Frontend9H.por(_detalhe, Rect2(76, 400, 760, 68))
    _niveis_painel.add_child(_detalhe)
    _estado = Label.new()
    Frontend9H.corpo(_estado, 16, Frontend9H.VERDE_ESTADO)
    Frontend9H.por(_estado, Rect2(76, 478, 760, 32))
    _niveis_painel.add_child(_estado)
    _jogar = _botao("", 20)
    _jogar.pressed.connect(_confirmar)
    Frontend9H.por(_jogar, Rect2(900, 430, 280, 60))
    _niveis_painel.add_child(_jogar)

func _voltar_premido() -> void:
    if not _vista_regioes:
        _vista_regioes = true
        _actualizar()
        return
    Som.toca("ui_voltar", -8.0)
    cancelado.emit()

func _selecionar_regiao(r: int) -> void:
    if r < 0 or r >= EstadoJogo.REGIOES.size():
        return
    _regiao = r
    var ns: Array = EstadoJogo.REGIOES[r]["niveis"]
    if not ns.is_empty() and not (_sel in ns):
        _sel = int(ns[0])
    _actualizar()

func _abrir_regiao(r: int) -> void:
    _selecionar_regiao(r)
    if _respeitar_bloqueio and not _regiao_aberta(r):
        Som.toca("ui_negado", -8.0)
        return
    _vista_regioes = false
    _actualizar()

func _selecionar_nivel(pos: int) -> void:
    var ns: Array = EstadoJogo.REGIOES[_regiao]["niveis"]
    if pos < 0 or pos >= ns.size():
        return
    _sel = int(ns[pos])
    _actualizar()

func _regiao_aberta(r: int) -> bool:
    if not _respeitar_bloqueio:
        return true
    var ns: Array = EstadoJogo.REGIOES[r]["niveis"]
    return not ns.is_empty() and EstadoJogo.nivel_desbloqueado(int(ns[0]))

func _estado_nivel(indice: int) -> String:
    if indice == EstadoJogo.indice_nivel:
        return "CURRENT"
    if EstadoJogo.nivel_esta_concluido(indice):
        return "COMPLETED"
    if not _respeitar_bloqueio or EstadoJogo.nivel_desbloqueado(indice):
        return "UNLOCKED"
    return "LOCKED"

func _estado_regiao(r: int) -> String:
    if r == EstadoJogo.regiao_atual():
        return "CURRENT"
    if EstadoJogo.regiao_esta_concluida(r):
        return "COMPLETED"
    if _regiao_aberta(r):
        return "UNLOCKED"
    return "LOCKED"

func _texto_estado(estado: String) -> String:
    return estado

func _actualizar() -> void:
    if not _pronto:
        return
    var tema: Dictionary = TemaRegiao.do_indice(_regiao)
    if _arte:
        _arte.texture = TemaRegiao.textura("fundo_seletor", _regiao)
        _arte.modulate = tema.get("tinta_fundo", Color.WHITE)
    if _barras:
        _barras.modulate = Color(0.18, 0.12, 0.22, 1.0)
    if _vista_regioes:
        _titulo.text = "LEVEL SELECT"
        _subtitulo.text = "20 REGIONS · 100 LEVELS"
        _voltar.text = Textos.t("selector.back_to_menu")
    else:
        _titulo.text = "%s %s — %s" % [Textos.t("selector.region"), ROMANOS[_regiao], Textos.t(EstadoJogo.REGIOES[_regiao]["chave"]).to_upper()]
        _subtitulo.text = "5 LEVELS · N05 BOSS · %s" % _texto_estado(_estado_regiao(_regiao))
        _voltar.text = "← REGIONS"
    _santuario_botao.text = Textos.t("shrine.open")
    _regioes_painel.visible = _vista_regioes
    _niveis_painel.visible = not _vista_regioes
    for r in _region_cards.size():
        var b := _region_cards[r]
        var reg: Dictionary = EstadoJogo.REGIOES[r]
        var estado := _estado_regiao(r)
        var nome := Textos.t(reg["chave"])
        if nome == reg["chave"]:
            nome = str(reg["nome"])
        b.text = "%s  %s\n%s  ·  %s" % [ROMANOS[r], nome.to_upper(), _texto_estado(estado), "5/5" if EstadoJogo.regiao_esta_concluida(r) else "5 LEVELS"]
        _estilo_cartao(b, reg.get("cor", Color.WHITE), r == _regiao, estado == "LOCKED")
        b.tooltip_text = "LOCKED" if estado == "LOCKED" else nome
    var ns: Array = EstadoJogo.REGIOES[_regiao]["niveis"]
    for i in _level_cards.size():
        var indice := int(ns[i])
        var estado := _estado_nivel(indice)
        var nome := _nome_nivel(indice)
        _level_cards[i].text = "N%02d%s\n%s\n%s" % [i + 1, "  · BOSS" if i == 4 else "", nome.to_upper(), _texto_estado(estado)]
        _estilo_cartao(_level_cards[i], tema.get("primaria", Color.WHITE), indice == _sel, estado == "LOCKED")
        _level_cards[i].tooltip_text = "LOCKED" if estado == "LOCKED" else nome
        _nos[i]["indice"] = indice
    var passo: Array = EstadoJogo.passo_na_regiao(_sel)
    var sel_estado := _estado_nivel(_sel)
    _detalhe.text = "%s %d-%d · %s\n%s" % [Textos.t("selector.level"), _regiao + 1, int(passo[0]), "BOSS" if int(passo[0]) == 5 else "LEVEL", _nome_nivel(_sel)]
    _estado.text = "STATE: %s%s" % [_texto_estado(sel_estado), " · %s" % _nome_chefe(_sel) if int(passo[0]) == 5 else ""]
    _jogar.text = Textos.t("selector.play")
    _jogar.disabled = sel_estado == "LOCKED"
    _jogar.modulate = Color(0.6, 0.6, 0.68) if _jogar.disabled else Color.WHITE

func _mudar_regiao(dir: int) -> void:
    _regiao = clampi(_regiao + dir, 0, EstadoJogo.REGIOES.size() - 1)
    _sel = int(EstadoJogo.REGIOES[_regiao]["niveis"][0])
    _actualizar()

func _mover_regiao_grid(dir: Vector2i) -> void:
    var linha := _regiao / COLUNAS_REGIOES
    var coluna := _regiao % COLUNAS_REGIOES
    linha = clampi(linha + dir.y, 0, (EstadoJogo.REGIOES.size() - 1) / COLUNAS_REGIOES)
    coluna = clampi(coluna + dir.x, 0, COLUNAS_REGIOES - 1)
    _selecionar_regiao(clampi(linha * COLUNAS_REGIOES + coluna, 0, EstadoJogo.REGIOES.size() - 1))
    _region_cards[_regiao].grab_focus()

func _mover_nivel(dir: int) -> void:
    var ns: Array = EstadoJogo.REGIOES[_regiao]["niveis"]
    var pos := clampi(ns.find(_sel) + dir, 0, ns.size() - 1)
    _selecionar_nivel(pos)
    _level_cards[pos].grab_focus()

func _confirmar() -> void:
    if _vista_regioes:
        _abrir_regiao(_regiao)
        return
    if _respeitar_bloqueio and not EstadoJogo.nivel_desbloqueado(_sel):
        Som.toca("ui_negado", -8.0)
        return
    Som.toca("ui_confirmar", -5.0)
    escolhido.emit(_sel)

func _unhandled_input(evento: InputEvent) -> void:
    if _santuario != null:
        return
    if evento.is_action_pressed("ui_cancel"):
        accept_event(); _voltar_premido()
    elif _vista_regioes and evento.is_action_pressed("ui_left"):
        accept_event(); _mover_regiao_grid(Vector2i.LEFT)
    elif _vista_regioes and evento.is_action_pressed("ui_right"):
        accept_event(); _mover_regiao_grid(Vector2i.RIGHT)
    elif _vista_regioes and evento.is_action_pressed("ui_up"):
        accept_event(); _mover_regiao_grid(Vector2i.UP)
    elif _vista_regioes and evento.is_action_pressed("ui_down"):
        accept_event(); _mover_regiao_grid(Vector2i.DOWN)
    elif not _vista_regioes and evento.is_action_pressed("ui_left"):
        accept_event(); _mover_nivel(-1)
    elif not _vista_regioes and evento.is_action_pressed("ui_right"):
        accept_event(); _mover_nivel(1)
    elif not _vista_regioes and evento.is_action_pressed("ui_up"):
        accept_event(); _mudar_regiao(-1)
    elif not _vista_regioes and evento.is_action_pressed("ui_down"):
        accept_event(); _mudar_regiao(1)
    elif evento.is_action_pressed("ui_accept"):
        accept_event(); _confirmar()

func _nome_nivel(indice: int) -> String:
    var chave := CatalogoCampanha.chave_nivel(indice)
    var txt := Textos.t(chave)
    if txt != chave:
        return txt
    return (EstadoJogo.NIVEIS[indice] as String).get_file().get_basename().replace("_", " ")

func _nome_chefe(indice: int) -> String:
    var chave := CatalogoCampanha.chave_chefe(indice)
    return Textos.t(chave) if chave != "" else ""

func _abrir_santuario() -> void:
    if _santuario != null:
        return
    _santuario = SANTUARIO_CENA.instantiate()
    _santuario.z_index = 100
    add_child(_santuario)
    _santuario.fechado.connect(func() -> void:
        if is_instance_valid(_santuario):
            _santuario.queue_free()
        _santuario = null
        _actualizar())
