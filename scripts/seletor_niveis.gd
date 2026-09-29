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
const CARTAO_REGIAO := Vector2(252, 106)
const CARTAO_NIVEL := Vector2(196, 92)
const FUNDO_SELECTOR_DIR := "res://assets/ui/level_selector/regions/"
const BOSS_NOMES := [
    "Guardião Verde", "Guardião dos Céus", "Vyrak", "Guardião da Fornalha",
    "Oráculo do Vento", "Mirage Eterna", "Rainha Espinhosa", "Devorador da Cripta",
    "Abade Naufragado", "Arconte do Conhecimento", "Senhor das Marés", "Arauto da Pestilência",
    "Soberano Invertido", "Oráculo Estelar", "Arquialquimista Morvak", "Malgor",
    "Rainha do Sonho", "Colosso da Ruína", "Arquiteto do Limiar", "Zeriko",
]
const BOSS_ART := [
    "res://assets/sprites/pixel/bosses/ghorak.png", "res://assets/sprites/pixel/bosses/aerion.png",
    "res://assets/sprites/pixel/bosses/vyrak.png", "res://assets/sprites/pixel/bosses/magma.png",
    "res://assets/sprites/pixel/bosses/voltaris.png", "res://assets/sprites/pixel/bosses/morvanna.png",
    "res://assets/sprites/pixel/bosses/rainha.png", "res://assets/sprites/pixel/bosses/devorador.png",
    "res://assets/sprites/pixel/bosses/abismo_oceanico.png", "res://assets/sprites/pixel/bosses/olho.png",
    "res://assets/sprites/pixel/bosses/leviata.png", "res://assets/sprites/pixel/bosses/ghorak.png",
    "res://assets/sprites/pixel/bosses/primeiro.png", "res://assets/sprites/pixel/bosses/sacerdotisa.png",
    "res://assets/sprites/pixel/bosses/olho.png", "res://assets/sprites/pixel/bosses/vulkar.png",
    "res://assets/sprites/pixel/bosses/morvanna.png", "res://assets/sprites/pixel/bosses/colosso.png",
    "res://assets/sprites/pixel/bosses/arauto.png", "res://assets/sprites/pixel/bosses/zeriko.png",
]

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
var _regiao_detalhe: Panel
var _regiao_nome: Label
var _regiao_meta: Label
var _regiao_estado: Label
var _regiao_progresso: ProgressBar
var _regiao_entrar: Button
var _regiao_esquerda: Button
var _regiao_direita: Button
var _boss_painel: Panel
var _boss_arte: TextureRect
var _boss_nome: Label
var _fundo_regiao := -1

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
    Frontend9H.por(_voltar, Rect2(32, 22, 210, 42))
    _palco.add_child(_voltar)
    _santuario_botao = _botao("", 14)
    _santuario_botao.pressed.connect(_abrir_santuario)
    Frontend9H.por(_santuario_botao, Rect2(1015, 22, 233, 42))
    _palco.add_child(_santuario_botao)
    _titulo = Label.new()
    Frontend9H.cabecalho(_titulo, 29)
    _titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    Frontend9H.por(_titulo, Rect2(270, 24, 740, 42))
    _palco.add_child(_titulo)
    _subtitulo = Label.new()
    Frontend9H.corpo(_subtitulo, 14, Frontend9H.TEXTO_APAGADO)
    _subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    Frontend9H.por(_subtitulo, Rect2(270, 67, 740, 26))
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
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    return b

func _caixa(cor: Color, borda: Color, raio := 8, largura := 1, sombra := false) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = cor
    s.border_color = borda
    s.set_border_width_all(largura)
    s.set_corner_radius_all(raio)
    if sombra:
        s.shadow_color = Color(0.02, 0.01, 0.04, 0.55)
        s.shadow_size = 5
        s.shadow_offset = Vector2(0, 2)
    s.content_margin_left = 12.0
    s.content_margin_right = 12.0
    s.content_margin_top = 8.0
    s.content_margin_bottom = 8.0
    return s

func _estilo_cartao(b: Button, primaria: Color, ativo: bool, bloqueado: bool) -> void:
    b.flat = false
    var fundo := Color(0.035, 0.026, 0.055, 0.94) if not bloqueado else Color(0.025, 0.025, 0.035, 0.82)
    var linha := Frontend9H.CARMESIM if ativo else Color(0.20, 0.18, 0.28, 0.72)
    if bloqueado:
        linha = Color(0.14, 0.14, 0.19, 0.42)
    var largura := 2 if ativo else 1
    b.add_theme_stylebox_override("normal", _caixa(fundo, linha, 8, largura, ativo))
    b.add_theme_stylebox_override("hover", _caixa(fundo.lightened(0.08), primaria, 8, 1, true))
    b.add_theme_stylebox_override("focus", _caixa(fundo.lightened(0.10), primaria, 8, 2, true))
    b.add_theme_stylebox_override("pressed", _caixa(fundo.lightened(0.04), primaria, 8, 2))
    b.add_theme_color_override("font_color", Frontend9H.TEXTO_APAGADO if bloqueado else Frontend9H.OSSO)
    b.add_theme_color_override("font_hover_color", Frontend9H.OSSO)
    b.add_theme_color_override("font_focus_color", Frontend9H.OSSO)
    b.modulate = Color(0.42, 0.42, 0.48, 0.66) if bloqueado else (Color.WHITE if ativo else Color(0.68, 0.66, 0.72, 0.82))
    b.scale = Vector2(1.025, 1.025) if ativo else Vector2.ONE

func _ligar_microinteracoes(b: Button) -> void:
    b.pivot_offset = b.size / 2.0
    b.mouse_entered.connect(_hover_cartao.bind(b, true))
    b.mouse_exited.connect(_hover_cartao.bind(b, false))

func _hover_cartao(b: Button, entrou: bool) -> void:
    if not is_instance_valid(b) or not b.visible:
        return
    b.pivot_offset = b.size / 2.0
    var escala := Vector2(1.018, 1.018) if entrou else Vector2.ONE
    b.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(b, "scale", escala, 0.10)

func _montar_regioes() -> void:
    for r in EstadoJogo.REGIOES.size():
        var b := _botao("", 16)
        b.alignment = HORIZONTAL_ALIGNMENT_CENTER
        b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.pressed.connect(_abrir_regiao.bind(r))
        b.focus_entered.connect(_selecionar_regiao.bind(r))
        b.mouse_entered.connect(_selecionar_regiao.bind(r))
        Frontend9H.por(b, Rect2(0, 0, CARTAO_REGIAO.x, CARTAO_REGIAO.y))
        _regioes_painel.add_child(b)
        _region_cards.append(b)
        _ligar_microinteracoes(b)
    _abas = _region_cards

    _regiao_esquerda = _botao("‹", 34)
    _regiao_esquerda.pressed.connect(func() -> void: _mudar_regiao(-1))
    Frontend9H.por(_regiao_esquerda, Rect2(82, 280, 60, 64))
    _regioes_painel.add_child(_regiao_esquerda)
    _regiao_direita = _botao("›", 34)
    _regiao_direita.pressed.connect(func() -> void: _mudar_regiao(1))
    Frontend9H.por(_regiao_direita, Rect2(1138, 280, 60, 64))
    _regioes_painel.add_child(_regiao_direita)

    _regiao_detalhe = Panel.new()
    _regiao_detalhe.add_theme_stylebox_override("panel", Frontend9H.painel_liso(0.94))
    Frontend9H.por(_regiao_detalhe, Rect2(286, 376, 708, 214))
    _regioes_painel.add_child(_regiao_detalhe)
    _regiao_nome = Label.new()
    Frontend9H.cabecalho(_regiao_nome, 27)
    _regiao_nome.position = Vector2(42, 24)
    _regiao_nome.size = Vector2(624, 42)
    _regiao_detalhe.add_child(_regiao_nome)
    _regiao_meta = Label.new()
    Frontend9H.corpo(_regiao_meta, 15, Frontend9H.TEXTO_APAGADO)
    _regiao_meta.position = Vector2(44, 72)
    _regiao_meta.size = Vector2(620, 28)
    _regiao_detalhe.add_child(_regiao_meta)
    _regiao_estado = Label.new()
    Frontend9H.corpo(_regiao_estado, 15, Frontend9H.TEXTO)
    _regiao_estado.position = Vector2(44, 104)
    _regiao_estado.size = Vector2(360, 28)
    _regiao_detalhe.add_child(_regiao_estado)
    _regiao_progresso = ProgressBar.new()
    _regiao_progresso.show_percentage = false
    _regiao_progresso.add_theme_stylebox_override("background", _caixa(Color(0.08, 0.05, 0.09, 0.95), Color(0.22, 0.16, 0.25, 0.8), 3, 1))
    _regiao_progresso.add_theme_stylebox_override("fill", _caixa(Color(0.55, 0.08, 0.15, 0.95), Frontend9H.CARMESIM, 3, 1, true))
    _regiao_progresso.position = Vector2(44, 147)
    _regiao_progresso.size = Vector2(350, 10)
    _regiao_detalhe.add_child(_regiao_progresso)
    _regiao_entrar = _botao("", 18)
    Frontend9H.botao_placa(_regiao_entrar, 18)
    _regiao_entrar.pressed.connect(func() -> void: _abrir_regiao(_regiao))
    _regiao_entrar.position = Vector2(458, 104)
    _regiao_entrar.size = Vector2(194, 58)
    _regiao_detalhe.add_child(_regiao_entrar)

func _montar_niveis() -> void:
    var painel := Panel.new()
    painel.add_theme_stylebox_override("panel", Frontend9H.painel_liso(0.93))
    painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    Frontend9H.por(painel, Rect2(72, 126, 1136, 200))
    _niveis_painel.add_child(painel)
    for i in 5:
        var b := _botao("", 19)
        b.alignment = HORIZONTAL_ALIGNMENT_CENTER
        b.pressed.connect(_selecionar_nivel.bind(i))
        b.focus_entered.connect(_selecionar_nivel.bind(i))
        Frontend9H.por(b, Rect2(94 + i * 212, 180, CARTAO_NIVEL.x, CARTAO_NIVEL.y))
        _niveis_painel.add_child(b)
        _level_cards.append(b)
        _nos.append({"botao": b, "indice": -1})
        _ligar_microinteracoes(b)
    _detalhe = Label.new()
    Frontend9H.corpo(_detalhe, 16, Frontend9H.TEXTO)
    _detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    Frontend9H.por(_detalhe, Rect2(112, 390, 720, 68))
    _niveis_painel.add_child(_detalhe)
    _estado = Label.new()
    Frontend9H.corpo(_estado, 16, Frontend9H.VERDE_ESTADO)
    Frontend9H.por(_estado, Rect2(112, 470, 760, 32))
    _niveis_painel.add_child(_estado)
    _jogar = _botao("", 20)
    _jogar.flat = false
    Frontend9H.botao_placa(_jogar, 20)
    _jogar.pressed.connect(_confirmar)
    Frontend9H.por(_jogar, Rect2(900, 430, 280, 60))
    _niveis_painel.add_child(_jogar)
    _boss_painel = Panel.new()
    _boss_painel.add_theme_stylebox_override("panel", _caixa(Color(0.025, 0.015, 0.045, 0.94), Frontend9H.CARMESIM, 8, 1, true))
    Frontend9H.por(_boss_painel, Rect2(874, 342, 306, 76))
    _niveis_painel.add_child(_boss_painel)
    _boss_arte = TextureRect.new()
    _boss_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _boss_arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _boss_arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    Frontend9H.por(_boss_arte, Rect2(10, 8, 62, 60))
    _boss_painel.add_child(_boss_arte)
    _boss_nome = Label.new()
    Frontend9H.corpo(_boss_nome, 14, Frontend9H.OSSO)
    _boss_nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _boss_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    Frontend9H.por(_boss_nome, Rect2(82, 8, 214, 60))
    _boss_painel.add_child(_boss_nome)

func _voltar_premido() -> void:
    if not _vista_regioes:
        _vista_regioes = true
        _actualizar()
        _transitar_vista(_regioes_painel, _niveis_painel)
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
    _transitar_vista(_niveis_painel, _regioes_painel)

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
    match estado:
        "CURRENT": return "ATUAL"
        "COMPLETED": return "CONCLUÍDO"
        "UNLOCKED": return "DESBLOQUEADO"
        _: return "BLOQUEADO"

func _transitar_vista(entrar: Control, sair: Control) -> void:
    if not is_instance_valid(entrar) or not is_instance_valid(sair):
        return
    entrar.modulate.a = 0.0
    entrar.visible = true
    var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(entrar, "modulate:a", 1.0, 0.16)
    tween.tween_property(sair, "modulate:a", 0.0, 0.12)
    tween.chain().tween_callback(func() -> void: sair.visible = false)

func _actualizar() -> void:
    if not _pronto:
        return
    var tema: Dictionary = TemaRegiao.do_indice(_regiao)
    _actualizar_fundo(tema)
    if _barras:
        _barras.modulate = Color(0.18, 0.12, 0.22, 1.0)
    if _vista_regioes:
        _titulo.text = "LEVEL SELECT"
        _subtitulo.text = "20 REGIONS  ·  100 LEVELS  ·  SELECT A REGION"
        _voltar.text = Textos.t("selector.back_to_menu")
    else:
        _titulo.text = "%s %s — %s" % [Textos.t("selector.region"), ROMANOS[_regiao], Textos.t(EstadoJogo.REGIOES[_regiao]["chave"]).to_upper()]
        _subtitulo.text = "5 LEVELS  ·  BOSS N%02d  ·  %s" % [(_regiao + 1) * 5, _texto_estado(_estado_regiao(_regiao))]
        _voltar.text = "←  REGIONS"
    _santuario_botao.text = Textos.t("shrine.open")
    _regioes_painel.visible = _vista_regioes
    _niveis_painel.visible = not _vista_regioes
    _actualizar_carousel()
    for r in _region_cards.size():
        var b := _region_cards[r]
        var reg: Dictionary = EstadoJogo.REGIOES[r]
        var estado := _estado_regiao(r)
        var nome := Textos.t(reg["chave"])
        if nome == reg["chave"]:
            nome = str(reg["nome"])
        var estado_marca := _texto_estado(estado)
        var ns_regiao: Array = reg["niveis"]
        var primeiro := int(ns_regiao[0]) + 1
        var ultimo := int(ns_regiao[ns_regiao.size() - 1]) + 1
        b.text = "%s  %02d\n%s\nN%02d–N%02d" % [ROMANOS[r], r + 1, nome.to_upper(), primeiro, ultimo]
        _estilo_cartao(b, reg.get("cor", Color.WHITE), r == _regiao, estado == "LOCKED")
        b.tooltip_text = "LOCKED" if estado == "LOCKED" else nome
        b.visible = _vista_regioes and (r == _regiao or r == _regiao - 1 or r == _regiao + 1)
    var ns: Array = EstadoJogo.REGIOES[_regiao]["niveis"]
    for i in _level_cards.size():
        var indice := int(ns[i])
        var estado := _estado_nivel(indice)
        var nome := _nome_nivel(indice)
        var marca := _texto_estado(estado)
        _level_cards[i].text = "N%02d%s\n%s" % [indice + 1, "  · BOSS" if i == 4 else "", marca]
        _estilo_cartao(_level_cards[i], tema.get("primaria", Color.WHITE), indice == _sel, estado == "LOCKED")
        if i == 4 and estado != "LOCKED":
            _level_cards[i].add_theme_color_override("font_color", Color(1.0, 0.84, 0.58))
        _level_cards[i].tooltip_text = "LOCKED" if estado == "LOCKED" else nome
        _nos[i]["indice"] = indice
    var passo: Array = EstadoJogo.passo_na_regiao(_sel)
    var sel_estado := _estado_nivel(_sel)
    _detalhe.text = "%s %02d  ·  %s\n%s" % [Textos.t("selector.level"), _sel + 1, "BOSS" if int(passo[0]) == 5 else "", _nome_nivel(_sel)]
    _estado.text = "%s  ·  %s%s" % [_texto_estado(sel_estado), _nome_nivel(_sel), "  ·  %s" % _nome_chefe(_sel) if int(passo[0]) == 5 else ""]
    var boss_visivel := int(passo[0]) == 5
    _boss_painel.visible = boss_visivel
    if boss_visivel:
        _boss_arte.texture = load(BOSS_ART[_regiao]) as Texture2D
        _boss_nome.text = "BOSS  ·  %s" % BOSS_NOMES[_regiao]
    _jogar.text = Textos.t("selector.play")
    _jogar.disabled = sel_estado == "LOCKED"
    _jogar.modulate = Color(0.6, 0.6, 0.68) if _jogar.disabled else Color.WHITE

func _actualizar_fundo(tema: Dictionary) -> void:
    if not _arte:
        return
    var novo := FUNDO_SELECTOR_DIR + "region_%02d.png" % (_regiao + 1)
    var textura := load(novo) as Texture2D
    var tinta: Color = tema.get("tinta_fundo", Color.WHITE)
    if _fundo_regiao == _regiao:
        _arte.modulate = tinta
        return
    _fundo_regiao = _regiao
    var troca := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    troca.tween_property(_arte, "modulate:a", 0.72, 0.08)
    troca.tween_callback(func() -> void:
        _arte.texture = textura
        _arte.modulate = tinta
        if _barras:
            _barras.texture = textura
    )
    troca.tween_property(_arte, "modulate:a", 1.0, 0.16)

func _actualizar_carousel() -> void:
    if _region_cards.is_empty():
        return
    var posicoes := {
        -1: Rect2(142, 266, 252, 106),
        0: Rect2(514, 236, 252, 132),
        1: Rect2(886, 266, 252, 106),
    }
    for r in _region_cards.size():
        var delta := r - _regiao
        var b := _region_cards[r]
        if not posicoes.has(delta):
            b.visible = false
            continue
        var alvo: Rect2 = posicoes[delta]
        Frontend9H.por(b, alvo)
        b.z_index = 3 if delta == 0 else 1
        b.modulate.a = 1.0 if delta == 0 else 0.62
        b.add_theme_font_size_override("font_size", 21 if delta == 0 else 15)
    var reg: Dictionary = EstadoJogo.REGIOES[_regiao]
    var nome := Textos.t(reg["chave"])
    if nome == reg["chave"]:
        nome = str(reg["nome"])
    var estado := _estado_regiao(_regiao)
    var ns: Array = reg["niveis"]
    var feitos := 0
    for indice in ns:
        if EstadoJogo.nivel_esta_concluido(int(indice)):
            feitos += 1
    _regiao_nome.text = "%s  %s" % [ROMANOS[_regiao], nome.to_upper()]
    _regiao_meta.text = "N%02d–N%02d  ·  5 LEVELS  ·  BOSS N%02d" % [int(ns[0]) + 1, int(ns[4]) + 1, int(ns[4]) + 1]
    _regiao_estado.text = "%s  ·  %d / 5 COMPLETE" % [_texto_estado(estado), feitos]
    _regiao_progresso.value = feitos * 20.0
    _regiao_entrar.text = "VIEW LEVELS"
    _regiao_entrar.disabled = _respeitar_bloqueio and not _regiao_aberta(_regiao)
    _regiao_entrar.modulate = Color(0.55, 0.55, 0.60) if _regiao_entrar.disabled else Color.WHITE
    _regiao_esquerda.disabled = _regiao == 0
    _regiao_direita.disabled = _regiao == EstadoJogo.REGIOES.size() - 1

func _mudar_regiao(dir: int) -> void:
    _regiao = clampi(_regiao + dir, 0, EstadoJogo.REGIOES.size() - 1)
    _sel = int(EstadoJogo.REGIOES[_regiao]["niveis"][0])
    _actualizar()

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
        accept_event(); _mudar_regiao(-1)
    elif _vista_regioes and evento.is_action_pressed("ui_right"):
        accept_event(); _mudar_regiao(1)
    elif _vista_regioes and evento.is_action_pressed("ui_up"):
        accept_event(); _abrir_regiao(_regiao)
    elif _vista_regioes and evento.is_action_pressed("ui_down"):
        accept_event(); _abrir_regiao(_regiao)
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
