class_name SeletorNiveis
extends Control
## MAPA DE REGIÃO (Execution 9H). Substitui o carrossel de cartões pelo
## mapa aprovado em `10_menu_rebrand/02_level_selector_approved`: a vista da
## região ao fundo, os cinco níveis como nós ligados por um trilho, um
## painel de detalhe do nível escolhido e as abas das 20 regiões em baixo.
##
## Porque é que deixou de ser um carrossel: o carrossel mostrava 100 níveis
## em fila e a região era uma pastilha ao lado. A prancha diz o contrário --
## a REGIÃO é o ecrã, e os cinco níveis são o caminho que se faz nela. Isso
## é também o que o jogo é (20 regiões x 5), e torna a Região I uma coisa
## vista de frente e não um cartão entre cem.
##
## Reutilizável, com a MESMA interface de antes:
##   - `MapaMundo` (modo normal): `configurar(indice, true)` -- respeita os
##     bloqueios;
##   - `DevBarra` (DEVELOPER MODE): `configurar(indice, false)` -- pode
##     saltar para qualquer nível.
##
## Sinais: `escolhido(indice)` ao confirmar um nível jogável; `cancelado`
## ao recuar.
##
## Todas as medidas são as da prancha reduzidas a 1280x720 e vivem dentro
## de `palco()` (ver `Frontend9H`): a arte e a UI nunca se desencontram,
## seja qual for a forma do ecrã.

signal escolhido(indice: int)
signal cancelado

## Arte de fundo por região -- miniatura do nível no painel. Uma camada do
## pack de parallax que o primeiro nível da região usa (`fundo_pack` no
## `.tscn`). Regiões que partilham pack levam camadas diferentes.
const FUNDO_REGIAO := [
	"res://assets/sprites/pixel/backgrounds/floresta/middle.png",   # 01 Floresta
	"res://assets/sprites/pixel/backgrounds/prisao/middle.png",     # 02 Prisão
	"res://assets/sprites/pixel/backgrounds/montanhas/trees.png",   # 03 Torres
	"res://assets/sprites/pixel/backgrounds/caverna/back-walls.png",# 04 Catacumbas
	"res://assets/sprites/pixel/backgrounds/vilanoite/casario.png", # 05 Cidade
	"res://assets/sprites/pixel/backgrounds/luar/serra.png",        # 06 Castelo
	"res://assets/sprites/pixel/backgrounds/floresta/front.png",    # 07 Queimadas
	"res://assets/sprites/pixel/backgrounds/vilanoite/vila.png",    # 08 Mar dos Mortos
	"res://assets/sprites/pixel/backgrounds/pantano/mid1.png",      # 09 Gelo
	"res://assets/sprites/pixel/backgrounds/rochoso/middle.png",    # 10 Deserto
	"res://assets/sprites/pixel/backgrounds/floresta/back.png",     # 11 Jardins
	"res://assets/sprites/pixel/backgrounds/masmorra/celas.png",    # 12 Máquinas
	"res://assets/sprites/pixel/backgrounds/montanhas/far.png",     # 13 Céu Partido
	"res://assets/sprites/pixel/backgrounds/vilanoite/serra.png",   # 14 Sonhos
	"res://assets/sprites/pixel/backgrounds/prisao/near.png",       # 15 Cidade dos Mortos
	"res://assets/sprites/pixel/backgrounds/pantano/trees.png",     # 16 Mar Vermelho
	"res://assets/sprites/pixel/backgrounds/castelo_velho/salao.png",# 17 Inferno
	"res://assets/sprites/pixel/backgrounds/rochoso/near.png",      # 18 O Vazio
	"res://assets/sprites/pixel/backgrounds/cidade/vila.png",       # 19 Guerra
	"res://assets/sprites/pixel/backgrounds/luar/campo.png",        # 20 Último Caminho
]

## Retrato do chefe por índice de nível (ver `_retrato_chefe`).
const RETRATO_CHEFE := [
	"minotauro", "bruxa", "horror", "folha", "demonio_lodo",              # 1-5
	"guardiao_gelo", "cavaleiro_fogo", "verdugo", "monge", "prisioneiro", # 6-10
	"mimico", "monge_celeste", "arqueiro", "sacerdotisa", "alado",        # 11-15
	"rei_ossario", "ceifeiro", "feiticeiro_sombrio", "serpente", "olho_voador", # 16-20
	"lanceiro", "carniceiro", "golem_pedra", "feiticeiro", "noiva",       # 21-25
	"cavaleiro_negro", "koliani_sombria", "rei_devorador", "arauto", "colosso", # 26-30
	# --- niveis 31-100 -- GERADO por tools/gerar_niveis_31_100.py --------
	"vulkar", "magma", "forja", "dragao_lava", "estrela_caida",   # 31-35
	"capitao_afogado", "leviata", "nereia", "devorador_baleias", "abismo_oceanico",   # 36-40
	"frostfang", "skyrend", "prism_scarab", "cryo_sentinel", "ymiria",   # 41-45
	"dune_stalker", "sandstone_colossus", "scorpion_empress", "sun_mummy", "forgotten_god",   # 46-50
	"boss_51_roseira_viva", "boss_52_jardineiro_perdido", "boss_53_alma_errante", "boss_54_trepadeira", "boss_55_rei_botanico",   # 51-55
	"boss_56_automato", "boss_57_foguista", "boss_58_homunculo", "boss_59_bobina_viva", "boss_60_maquina_rei",   # 56-60
	"boss_61_guarda_nuvens", "boss_62_servo_do_trovao", "boss_63_anjo_corrompido", "boss_64_olho_lunar", "boss_65_astronomo",   # 61-65
	"boss_66_sonhador", "boss_67_reflexo", "boss_68_boneca", "boss_69_medo", "boss_70_outra_koliani",   # 66-70
	"boss_71_colecionador", "boss_72_coveiro", "boss_73_santo_corrompido", "boss_74_rei_morto", "boss_75_morte",   # 71-75
	"boss_76_afogado_vermelho", "boss_77_serpente_vermelha", "boss_78_almirante_morto", "boss_79_tentaculo", "boss_80_o_mar",   # 76-80
	"boss_81_sentinela_inferno", "boss_82_duque_infernal", "boss_83_barqueiro", "boss_84_princesa_demonio", "boss_85_rei_demonios",   # 81-85
	"boss_86_sombra", "boss_87_nada", "boss_88_paradoxo", "boss_89_observador", "boss_90_entidade",   # 86-90
	"boss_91_general_caos", "boss_92_dragao_primordial", "boss_93_ultimo_cavaleiro", "boss_94_arauto_final", "boss_95_campeao",   # 91-95
	"boss_96_zeriko_jovem", "boss_97_primeiro_rei", "boss_98_zeriko_absoluto", "boss_99_entidade_purpura", "boss_100_zeriko_homem",   # 96-100
]

const ROMANOS := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
	"XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]

## Onde ficam os cinco nós, em coordenadas do palco. Vêm dos centros
## medidos na prancha (multiplicados por 1280/1672): o trilho não é uma
## fila regular, sobe e desce com o relevo da vista, e é isso que o faz
## parecer um caminho e não um menu.
const NOS := [
	{"p": Vector2(346, 264), "r": 44.0},
	{"p": Vector2(504, 290), "r": 44.0},
	{"p": Vector2(713, 321), "r": 50.0},
	{"p": Vector2(897, 321), "r": 44.0},
	{"p": Vector2(1105, 302), "r": 76.0},   # o chefe da região é maior
]
## Pontos intermédios do trilho (a prancha curva-o entre os nós).
const TRILHO := [Vector2(428, 273), Vector2(612, 308), Vector2(806, 328),
	Vector2(1001, 308)]

const R_PAINEL := Rect2(372, 387, 844, 210)
const R_MINIATURA := Rect2(402, 406, 234, 168)
const R_JOGAR := Rect2(660, 533, 271, 47)
## As abas param em x=1110: a citação do canto vive a seguir, como na prancha.
const R_ABAS := Rect2(20, 620, 1090, 70)
const LARG_ABA := 178.0
const PASSO_ABA := 228.0

var _respeitar_bloqueio := true
var _sel := 0            # índice global do nível selecionado
var _regiao := 0
var _pronto := false

var _palco: Control
var _arte: TextureRect
var _barras: TextureRect
## Peças do frontend que trocam de pele com a região: [{no, peca}].
var _pecas: Array[Dictionary] = []
## Região cuja pele está montada (-1 = nenhuma ainda).
var _tema_montado := -1
var _veu_painel: TextureRect
var _chao_painel: ColorRect
var _titulo_regiao: Label
var _citacao: Label
var _nos: Array[Dictionary] = []      # [{botao, ficha, indice, jogavel}]
var _trilho: Control
var _painel: PanelContainer
var _miniatura: TextureRect
var _retrato: TextureRect
var _nivel_titulo: Label
var _nivel_nome: Label
var _nivel_chefe: Label
var _nivel_estado: Label
var _linhas_info: Array[Label] = []
var _jogar: Button
var _voltar: Button
var _santuario_botao: Button
var _seta_esq: Button
var _seta_dir: Button
var _abas: Array[Button] = []
var _citacao_canto: Label

const SANTUARIO_CENA := preload("res://scenes/ui/Santuario.tscn")
var _santuario: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Frontend9H.vestir(self)
	_montar()
	_pronto = true
	Textos.idioma_mudou.connect(func(_l: String) -> void: _actualizar())
	_actualizar()


## Ponto de entrada. `indice_inicial` = nível a mostrar; `respeitar_bloqueio`
## = se true, só deixa confirmar níveis desbloqueados (modo normal) e
## arranca na fronteira se o índice pedido estiver trancado.
func configurar(indice_inicial: int, respeitar_bloqueio: bool) -> void:
	_respeitar_bloqueio = respeitar_bloqueio
	var alvo := clampi(indice_inicial, 0, EstadoJogo.NIVEIS.size() - 1)
	if respeitar_bloqueio and not EstadoJogo.nivel_desbloqueado(alvo):
		alvo = EstadoJogo.fronteira()
	_sel = alvo
	_regiao = maxi(0, EstadoJogo.regiao_do_nivel(alvo))
	if _pronto:
		_actualizar()


# ── montagem ─────────────────────────────────────────────────────────────

## Imagem do frontend que ACOMPANHA a pele da região (ver `_aplicar_tema`).
## Tudo o que é moldura passa por aqui; o que não passa fica carmesim para
## sempre, e foi assim que a primeira montagem deixou as setas vermelhas num
## ecrã verde.
func _imagem(nome: String, tinta := Color.WHITE) -> TextureRect:
	var tr := Frontend9H.imagem(nome, tinta)
	tr.set_meta("peca", nome)
	_pecas.append({"no": tr, "peca": nome})
	return tr


func _separador() -> TextureRect:
	var tr := Frontend9H.separador()
	tr.set_meta("peca", "separador_menu")
	_pecas.append({"no": tr, "peca": "separador_menu"})
	return tr


func _montar() -> void:
	_palco = Frontend9H.palco(self, "fundo_seletor")
	_arte = _palco.get_node_or_null("Arte")
	_barras = get_node_or_null("Barras") as TextureRect
	_palco.add_child(Frontend9H.vinheta())
	# véu por baixo do painel e das abas: a metade de baixo do ecrã é toda
	# UI, e sem ele a arte competia com o texto
	_veu_painel = Frontend9H.veu(Vector2(0, 0), Vector2(1280, 720), 0.0)
	_veu_painel.texture = _degrade_vertical()
	Frontend9H.por(_veu_painel, Rect2(0, 330, 1280, 390))
	_palco.add_child(_veu_painel)

	_trilho = Control.new()
	_trilho.name = "Trilho"
	_trilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trilho.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_trilho.draw.connect(_desenhar_trilho)
	_palco.add_child(_trilho)

	_montar_topo()
	_montar_nos()
	_montar_painel()
	_montar_abas()


func _degrade_vertical() -> Texture2D:
	var v: Color = TemaRegiao.do_indice(_regiao)["veu"]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([
		Color(v.r, v.g, v.b, 0.0),
		Color(v.r, v.g, v.b, 0.55),
		Color(v.r, v.g, v.b, 0.86)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 8
	gt.height = 256
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	return gt


func _montar_topo() -> void:
	_voltar = Button.new()
	Frontend9H.rotulo_menu(_voltar, 13)
	_voltar.autowrap_mode = TextServer.AUTOWRAP_WORD
	_voltar.pressed.connect(func() -> void:
		Som.toca("ui_voltar", -8.0)
		cancelado.emit())
	Frontend9H.por(_voltar, Rect2(48, 14, 130, 46))
	_palco.add_child(_voltar)
	var seta := _imagem("voltar_seta")
	Frontend9H.por(seta, Rect2(14, 18, 34, 38))
	_palco.add_child(seta)

	_santuario_botao = Button.new()
	Frontend9H.rotulo_menu(_santuario_botao, 14)
	_santuario_botao.pressed.connect(_abrir_santuario)
	Frontend9H.por(_santuario_botao, Rect2(1060, 14, 206, 34))
	_palco.add_child(_santuario_botao)

	_titulo_regiao = Label.new()
	Frontend9H.cabecalho(_titulo_regiao, 27)
	_titulo_regiao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo_regiao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_titulo_regiao, Rect2(340, 134, 600, 34))
	_palco.add_child(_titulo_regiao)

	var orn := _separador()
	Frontend9H.por(orn, Rect2(535, 168, 210, 12))
	_palco.add_child(orn)

	_citacao = Label.new()
	Frontend9H.corpo(_citacao, 15, Frontend9H.TEXTO_APAGADO)
	_citacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_citacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_citacao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_citacao, Rect2(420, 184, 440, 42))
	_palco.add_child(_citacao)

	var orn2 := _separador()
	Frontend9H.por(orn2, Rect2(535, 226, 210, 12))
	_palco.add_child(orn2)

	_seta_esq = _montar_seta(false)
	_seta_dir = _montar_seta(true)

	_citacao_canto = Label.new()
	Frontend9H.corpo(_citacao_canto, 13, Frontend9H.TEXTO_APAGADO)
	_citacao_canto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_citacao_canto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_citacao_canto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_citacao_canto, Rect2(1080, 630, 190, 46))
	_palco.add_child(_citacao_canto)


func _montar_seta(direita: bool) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	Frontend9H.por(b, Rect2(1216.0 if direita else 8.0, 286, 56, 100))
	b.pressed.connect(func() -> void: _mudar_regiao(1 if direita else -1))
	_palco.add_child(b)

	var img := _imagem("seta_direita" if direita else "seta_esquerda")
	Frontend9H.por(img, Rect2(1222.0 if direita else 14.0, 290, 44, 56))
	_palco.add_child(img)
	b.mouse_entered.connect(func() -> void: img.modulate = Color(1.4, 1.1, 1.1))
	b.mouse_exited.connect(func() -> void: img.modulate = Color.WHITE)

	var l := Label.new()
	Frontend9H.capitular(l, 11, Frontend9H.TEXTO_APAGADO)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.name = "Rotulo"
	Frontend9H.por(l, Rect2(1210.0 if direita else 4.0, 350, 66, 40))
	_palco.add_child(l)
	b.set_meta("rotulo", l)
	b.set_meta("imagem", img)
	return b


func _montar_nos() -> void:
	for i in NOS.size():
		var dados: Dictionary = NOS[i]
		var centro: Vector2 = dados["p"]
		var raio: float = dados["r"]

		var anel := _imagem("anel_normal")
		Frontend9H.por(anel, Rect2(centro - Vector2(raio, raio) * 1.16, Vector2(raio, raio) * 2.32))
		_palco.add_child(anel)

		# o miolo do anel é uma LENTE para a vista que está por trás: é o
		# que a prancha desenha (vê-se o cenário dentro do círculo) e evita
		# inventar uma miniatura por nível que não existe
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_ALL
		for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
		Frontend9H.por(b, Rect2(centro - Vector2(raio, raio), Vector2(raio, raio) * 2.0))
		b.pressed.connect(_escolher_no.bind(i))
		b.focus_entered.connect(_escolher_no.bind(i))
		b.mouse_entered.connect(b.grab_focus)
		_palco.add_child(b)

		# A ficha é uma imagem ESCALADA, não uma nine-patch: as margens do
		# losango (30 px de cada lado a 2x) comiam o miolo de uma peça de
		# 36 px de alto e o que se via eram duas barras soltas.
		var alt := 40.0
		var ficha := _imagem("ficha_nivel")
		ficha.stretch_mode = TextureRect.STRETCH_SCALE
		Frontend9H.por(ficha, Rect2(centro.x - 50.0, centro.y + raio * 0.56, 100.0, alt))
		_palco.add_child(ficha)
		var rot := Label.new()
		Frontend9H.corpo(rot, 17, Frontend9H.OSSO)
		rot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Frontend9H.por(rot, Rect2(centro.x - 50.0, centro.y + raio * 0.56, 100.0, alt))
		_palco.add_child(rot)

		var trinco := _imagem("cadeado")
		Frontend9H.por(trinco, Rect2(centro.x - 13.0, centro.y - 15.0, 26.0, 30.0))
		trinco.visible = false
		_palco.add_child(trinco)

		_nos.append({"botao": b, "anel": anel, "ficha": ficha, "rotulo": rot,
			"cadeado": trinco, "indice": i, "jogavel": true})


func _montar_painel() -> void:
	_painel = PanelContainer.new()
	_painel.add_theme_stylebox_override("panel",
		Frontend9H.caixa("painel_detalhe", Vector4(0, 0, 0, 0)))
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	Frontend9H.por(_painel, R_PAINEL)
	_palco.add_child(_painel)
	# fundo do painel: a moldura da prancha é oca, e sem chão o texto ficava
	# em cima da vista
	var chao := ColorRect.new()
	_chao_painel = chao
	chao.color = Color(0.035, 0.016, 0.028, 0.86)
	chao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(chao, Rect2(R_PAINEL.position + Vector2(8, 8), R_PAINEL.size - Vector2(16, 16)))
	_palco.add_child(chao)
	_palco.move_child(chao, _painel.get_index())

	_miniatura = TextureRect.new()
	_miniatura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_miniatura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_miniatura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_miniatura.clip_contents = true
	Frontend9H.por(_miniatura, R_MINIATURA)
	_palco.add_child(_miniatura)

	_retrato = TextureRect.new()
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Frontend9H.por(_retrato, Rect2(R_MINIATURA.position.x + 150, R_MINIATURA.position.y + 28,
		96, 132))
	_palco.add_child(_retrato)

	var moldura := ColorRect.new()
	moldura.color = Color(0, 0, 0, 0)
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palco.add_child(moldura)

	_nivel_titulo = Label.new()
	Frontend9H.cabecalho(_nivel_titulo, 26)
	_nivel_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_nivel_titulo, Rect2(660, 400, 330, 34))
	_palco.add_child(_nivel_titulo)

	_nivel_nome = Label.new()
	Frontend9H.corpo(_nivel_nome, 18, Frontend9H.TEXTO)
	_nivel_nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_nivel_nome, Rect2(660, 432, 330, 26))
	_palco.add_child(_nivel_nome)

	_nivel_chefe = Label.new()
	Frontend9H.corpo(_nivel_chefe, 15, Frontend9H.TEXTO_APAGADO)
	_nivel_chefe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nivel_chefe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_nivel_chefe, Rect2(660, 462, 330, 44))
	_palco.add_child(_nivel_chefe)

	_nivel_estado = Label.new()
	Frontend9H.corpo(_nivel_estado, 15, Frontend9H.VERDE_ESTADO)
	_nivel_estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_nivel_estado, Rect2(660, 506, 330, 24))
	_palco.add_child(_nivel_estado)

	_jogar = Button.new()
	Frontend9H.rotulo_menu(_jogar, 21)
	_jogar.flat = false
	_jogar.add_theme_stylebox_override("normal", Frontend9H.caixa("botao_jogar", Vector4(20, 6, 20, 6)))
	_jogar.add_theme_stylebox_override("hover",
		Frontend9H.caixa("botao_jogar", Vector4(20, 6, 20, 6), Color(1.45, 1.1, 1.1)))
	_jogar.add_theme_stylebox_override("focus",
		Frontend9H.caixa("botao_jogar", Vector4(20, 6, 20, 6), Color(1.45, 1.1, 1.1)))
	_jogar.add_theme_stylebox_override("pressed",
		Frontend9H.caixa("botao_jogar", Vector4(20, 6, 20, 6), Color(0.8, 0.7, 0.7)))
	_jogar.pressed.connect(_confirmar)
	Frontend9H.por(_jogar, R_JOGAR)
	_palco.add_child(_jogar)

	# três linhas de informação à direita, no sítio das estatísticas da
	# prancha. Levam o que o jogo SABE mesmo -- guardião, passo na região,
	# estado -- e não contadores que ainda não existem.
	for i in 3:
		var ico := _imagem("losango")
		Frontend9H.por(ico, Rect2(994, 462.0 + i * 30.0, 18, 18))
		ico.modulate = Color(1.2, 0.9, 0.95)
		_palco.add_child(ico)
		var l := Label.new()
		Frontend9H.corpo(l, 13, Frontend9H.TEXTO)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.clip_text = true
		Frontend9H.por(l, Rect2(1016, 460.0 + i * 30.0, 194, 24))
		_palco.add_child(l)
		_linhas_info.append(l)


func _montar_abas() -> void:
	for i in 5:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_ALL
		b.clip_text = true
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		Frontend9H.rotulo_menu(b, 14)
		b.flat = false
		Frontend9H.por(b, Rect2(R_ABAS.position.x + i * PASSO_ABA, R_ABAS.position.y,
			LARG_ABA, R_ABAS.size.y))
		b.pressed.connect(_ir_para_aba.bind(i))
		_palco.add_child(b)
		_abas.append(b)
		if i < 4:
			var d := _imagem("losango")
			Frontend9H.por(d, Rect2(R_ABAS.position.x + i * PASSO_ABA + LARG_ABA + 14.0,
				R_ABAS.position.y + 24.0, 22, 22))
			_palco.add_child(d)


## Veste o ecrã com a pele da região atual (ver `scripts/tema_regiao.gd`).
##
## Corre a cada `_actualizar`, mas só faz trabalho quando a região MUDA --
## trocar dezenas de texturas a cada movimento do cursor seria caro e
## visível. A Região I tem pele própria; todas as outras caem na
## apresentação neutra, com a arte de marca dessaturada. Nada aqui mexe em
## posições, navegação ou bloqueios: muda a cor e a moldura, mais nada.
func _aplicar_tema() -> void:
	if _tema_montado == _regiao:
		return
	_tema_montado = _regiao
	var t := TemaRegiao.do_indice(_regiao)
	var tinta: Color = t.get("tinta_pecas", Color.WHITE)

	var fundo := TemaRegiao.textura("fundo_seletor", _regiao)
	if _arte:
		_arte.texture = fundo
		_arte.modulate = t.get("tinta_fundo", Color.WHITE)
	if _barras:
		_barras.texture = fundo
		# as barras laterais são o mesmo fundo, desfocado e escuro
		var c: Color = t.get("tinta_fundo", Color.WHITE)
		_barras.modulate = Color(c.r * 0.30, c.g * 0.26, c.b * 0.32, 1.0)

	for d in _pecas:
		var no := d["no"] as TextureRect
		if not is_instance_valid(no):
			continue
		no.texture = TemaRegiao.textura(String(d["peca"]), _regiao)
		no.modulate = tinta

	if _painel:
		_painel.add_theme_stylebox_override("panel",
			TemaRegiao.caixa("painel_detalhe", _regiao, Vector4(0, 0, 0, 0)))
	if _chao_painel:
		var v: Color = t["veu"]
		_chao_painel.color = Color(v.r, v.g, v.b, 0.86)
	if _veu_painel:
		_veu_painel.texture = _degrade_vertical()
	if _jogar:
		for estado in ["normal", "hover", "focus", "pressed"]:
			var extra := Color.WHITE
			if estado in ["hover", "focus"]:
				extra = Color(1.45, 1.1, 1.1) if t.get("autoridade", false) 					else Color(1.25, 1.25, 1.28)
			elif estado == "pressed":
				extra = Color(0.8, 0.78, 0.8)
			_jogar.add_theme_stylebox_override(estado,
				TemaRegiao.caixa("botao_jogar", _regiao, Vector4(20, 6, 20, 6), extra))
	# o brilho por trás dos cabeçalhos segue a cor da região
	for l in [_titulo_regiao, _nivel_titulo]:
		if l:
			var p: Color = t["primaria"]
			l.add_theme_color_override("font_shadow_color", Color(p.r, p.g, p.b, 0.5))


# ── desenho do trilho ────────────────────────────────────────────────────

func _desenhar_trilho() -> void:
	var k := _trilho.size / Frontend9H.PALCO
	var pontos := PackedVector2Array()
	for i in NOS.size():
		pontos.append(NOS[i]["p"] * k)
		if i < TRILHO.size():
			pontos.append(TRILHO[i] * k)
	# ordena pelo x para o traço não saltar (os intermédios vêm intercalados)
	var lista: Array[Vector2] = []
	for p in pontos:
		lista.append(p)
	lista.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var suave := PackedVector2Array(lista)
	# o trilho fica CLARO até onde se pode ir e apagado a seguir: é a
	# leitura de progresso que a prancha faz com o brilho do caminho
	var corte := 0
	for i in _nos.size():
		if _nos[i]["jogavel"]:
			corte = i
	var limite: float = NOS[corte]["p"].x * k.x
	for i in suave.size() - 1:
		var a := suave[i]
		var b := suave[i + 1]
		var aceso := b.x <= limite + 2.0
		var t := TemaRegiao.do_indice(_regiao)
		var cor: Color = t["trilho"] if aceso else Color(0.45, 0.42, 0.48, 0.32)
		_trilho.draw_line(a, b, cor, 3.0 * k.y, true)
		if aceso:
			_trilho.draw_line(a, b, t["trilho_brilho"], 8.0 * k.y, true)


# ── estado ───────────────────────────────────────────────────────────────

func _actualizar() -> void:
	if not _pronto:
		return
	_aplicar_tema()
	var niveis: Array = EstadoJogo.REGIOES[_regiao]["niveis"]
	if not (_sel in niveis):
		_sel = niveis[0]

	_voltar.text = Textos.t("selector.back_to_menu")
	_santuario_botao.text = Textos.t("shrine.open")
	_titulo_regiao.text = "%s %s — %s" % [Textos.t("selector.region"),
		ROMANOS[_regiao], Textos.t(EstadoJogo.REGIOES[_regiao]["chave"]).to_upper()]
	var chave_citacao := "selector.quote_region_%d" % (_regiao + 1)
	var citacao := Textos.t(chave_citacao)
	_citacao.text = citacao if citacao != chave_citacao else Textos.t("selector.quote_region")
	_citacao_canto.text = Textos.t("selector.quote_corner")
	(_seta_esq.get_meta("rotulo") as Label).text = Textos.t("selector.prev_region")
	(_seta_dir.get_meta("rotulo") as Label).text = Textos.t("selector.next_region")
	_seta_esq.disabled = _regiao <= 0
	_seta_dir.disabled = _regiao >= EstadoJogo.REGIOES.size() - 1
	(_seta_esq.get_meta("imagem") as Control).modulate.a = 0.28 if _seta_esq.disabled else 1.0
	(_seta_dir.get_meta("imagem") as Control).modulate.a = 0.28 if _seta_dir.disabled else 1.0

	# --- nós ---
	for i in _nos.size():
		var n: Dictionary = _nos[i]
		var indice: int = niveis[i] if i < niveis.size() else -1
		n["indice"] = indice
		var jogavel := indice >= 0 and (not _respeitar_bloqueio
			or EstadoJogo.nivel_desbloqueado(indice))
		n["jogavel"] = jogavel
		var concluido := indice in EstadoJogo.concluidos
		var anel := n["anel"] as TextureRect
		var qual := "anel_chefe" if i == NOS.size() - 1 else (
			"anel_atual" if indice == _sel else "anel_normal")
		anel.texture = TemaRegiao.textura(qual, _regiao)
		anel.set_meta("peca", qual)
		for d in _pecas:
			if d["no"] == anel:
				d["peca"] = qual
		anel.modulate = Color(1, 1, 1, 1) if jogavel else Color(0.55, 0.52, 0.58, 0.7)
		if indice == _sel:
			# realce na cor da região (nas regiões sem pele fica em aço, não
			# em rosa -- o realce era o último sítio por onde o carmesim
			# fugia para um ecrã que já não é carmesim)
			var pc: Color = TemaRegiao.do_indice(_regiao)["primaria_clara"]
			anel.modulate = Color(0.7 + pc.r * 0.75, 0.7 + pc.g * 0.75,
				0.7 + pc.b * 0.75, 1.0)
		(n["rotulo"] as Label).text = "%d-%d" % [_regiao + 1, i + 1]
		(n["rotulo"] as Label).add_theme_color_override("font_color",
			Frontend9H.OSSO if jogavel else Frontend9H.TEXTO_APAGADO)
		(n["ficha"] as Control).modulate = Color(1, 1, 1, 1) if jogavel else Color(0.6, 0.58, 0.62, 0.85)
		(n["cadeado"] as Control).visible = not jogavel
		(n["botao"] as Button).tooltip_text = _nome_nivel(indice) if jogavel \
			else Textos.t("selector.unknown")
		if concluido:
			(n["rotulo"] as Label).add_theme_color_override("font_color", Frontend9H.VERDE_ESTADO)
	_trilho.queue_redraw()
	_pulsar_selecionado()

	# --- painel ---
	var passo: Array = EstadoJogo.passo_na_regiao(_sel)
	var jogavel_sel := not _respeitar_bloqueio or EstadoJogo.nivel_desbloqueado(_sel)
	_nivel_titulo.text = "%s %d-%d" % [Textos.t("selector.level"), _regiao + 1, int(passo[0])]
	_nivel_nome.text = _nome_nivel(_sel) if jogavel_sel else Textos.t("selector.unknown")
	var chefe := _nome_chefe(_sel)
	_nivel_chefe.text = Textos.tf("sel.guard", [chefe]) if (chefe != "" and jogavel_sel) else ""
	var estado_chave := "selector.state_locked"
	var cor_estado := Frontend9H.TEXTO_APAGADO
	if _sel in EstadoJogo.concluidos:
		estado_chave = "selector.state_cleared"
		cor_estado = Frontend9H.VERDE_ESTADO
	elif jogavel_sel:
		estado_chave = "selector.state_available"
		cor_estado = Frontend9H.VERDE_ESTADO
	_nivel_estado.text = "%s: %s" % [Textos.t("selector.state"), Textos.t(estado_chave)]
	_nivel_estado.add_theme_color_override("font_color", cor_estado)
	_jogar.text = Textos.t("selector.play")
	_jogar.disabled = not jogavel_sel
	_jogar.modulate = Color(1, 1, 1, 1) if jogavel_sel else Color(0.55, 0.52, 0.56, 0.75)

	_linhas_info[0].text = "%s  %s" % [Textos.t("selector.guardian"),
		chefe if jogavel_sel else Textos.t("selector.unknown")]
	_linhas_info[1].text = "%s  %s %d/%d" % [Textos.t("selector.region"),
		ROMANOS[_regiao], int(passo[0]), int(passo[1])]
	_linhas_info[2].text = "%s  %s" % [Textos.t("selector.state"), Textos.t(estado_chave)]

	_miniatura.texture = _fundo_regiao(_regiao) if jogavel_sel else null
	_miniatura.modulate = Color(0.9, 0.85, 0.92) if jogavel_sel else Color(0.2, 0.2, 0.22)
	_retrato.texture = _retrato_chefe(_sel) if jogavel_sel else null

	# --- abas ---
	var base := _janela_abas()
	for i in _abas.size():
		var r := base + i
		var b := _abas[i]
		var existe := r >= 0 and r < EstadoJogo.REGIOES.size()
		b.visible = existe
		if not existe:
			continue
		var aberta := _regiao_aberta(r)
		b.text = "%s\n%s" % [ROMANOS[r],
			Textos.t(EstadoJogo.REGIOES[r]["chave"]).to_upper() if aberta
			else Textos.t("selector.unknown")]
		b.add_theme_stylebox_override("normal",
			TemaRegiao.caixa("aba_atual" if r == _regiao else "aba_bloqueada", _regiao,
				Vector4(10, 6, 10, 6)))
		b.add_theme_stylebox_override("hover",
			TemaRegiao.caixa("aba_atual", _regiao, Vector4(10, 6, 10, 6), Color(1.3, 1.05, 1.05)))
		b.add_theme_stylebox_override("focus",
			TemaRegiao.caixa("aba_atual", _regiao, Vector4(10, 6, 10, 6), Color(1.3, 1.05, 1.05)))
		b.add_theme_color_override("font_color",
			Frontend9H.OSSO if r == _regiao else (
				Frontend9H.TEXTO if aberta else Frontend9H.TEXTO_APAGADO))
		b.modulate = Color(1, 1, 1, 1) if aberta else Color(0.8, 0.78, 0.82, 0.9)


## Uma região está aberta quando o seu primeiro nível já se pode jogar.
func _regiao_aberta(r: int) -> bool:
	if not _respeitar_bloqueio:
		return true
	var ns: Array = EstadoJogo.REGIOES[r]["niveis"]
	return not ns.is_empty() and EstadoJogo.nivel_desbloqueado(int(ns[0]))


## Janela de 5 abas centrada na região atual, sem sair das pontas.
func _janela_abas() -> int:
	return clampi(_regiao - 2, 0, maxi(0, EstadoJogo.REGIOES.size() - 5))


## Sopro lento no anel selecionado -- o único movimento do mapa, e o que
## diz onde se está sem precisar de mais uma cor.
func _pulsar_selecionado() -> void:
	for n in _nos:
		var anel := n["anel"] as TextureRect
		anel.scale = Vector2.ONE
		anel.pivot_offset = anel.size / 2.0
		if int(n["indice"]) != _sel:
			continue
		var t := anel.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		t.tween_property(anel, "scale", Vector2(1.045, 1.045), 1.0)
		t.tween_property(anel, "scale", Vector2.ONE, 1.0)


# ── navegação ────────────────────────────────────────────────────────────

func _escolher_no(i: int) -> void:
	var niveis: Array = EstadoJogo.REGIOES[_regiao]["niveis"]
	if i < 0 or i >= niveis.size():
		return
	var novo: int = niveis[i]
	if novo == _sel:
		return
	_sel = novo
	Som.toca("ui_mover", -12.0, randf_range(0.97, 1.05))
	_actualizar()


func _mudar_regiao(dir: int) -> void:
	var nova := clampi(_regiao + dir, 0, EstadoJogo.REGIOES.size() - 1)
	if nova == _regiao:
		return
	_regiao = nova
	_sel = int(EstadoJogo.REGIOES[_regiao]["niveis"][0])
	Som.toca("ui_mover", -9.0, 0.90 if dir < 0 else 1.10)
	_actualizar()


func _ir_para_aba(i: int) -> void:
	_mudar_regiao(_janela_abas() + i - _regiao)


func _mover(dir: int) -> void:
	var niveis: Array = EstadoJogo.REGIOES[_regiao]["niveis"]
	var pos := niveis.find(_sel)
	var novo := pos + dir
	if novo < 0:
		_mudar_regiao(-1)
		var ns: Array = EstadoJogo.REGIOES[_regiao]["niveis"]
		_sel = int(ns[ns.size() - 1])
		_actualizar()
		return
	if novo >= niveis.size():
		_mudar_regiao(1)
		return
	_escolher_no(novo)


func _confirmar() -> void:
	if _respeitar_bloqueio and not EstadoJogo.nivel_desbloqueado(_sel):
		Som.toca("ui_negado", -8.0)
		var t := create_tween()
		t.tween_property(_painel, "position:x", _painel.position.x + 7, 0.04)
		t.tween_property(_painel, "position:x", _painel.position.x - 7, 0.04)
		t.tween_property(_painel, "position:x", _painel.position.x, 0.04)
		return
	Som.toca("ui_confirmar", -5.0)
	escolhido.emit(_sel)


func _unhandled_input(evento: InputEvent) -> void:
	if _santuario != null:
		return
	if evento.is_action_pressed("ui_cancel"):
		accept_event()
		Som.toca("ui_voltar", -8.0)
		cancelado.emit()
	elif evento.is_action_pressed("ui_left"):
		accept_event()
		_mover(-1)
	elif evento.is_action_pressed("ui_right"):
		accept_event()
		_mover(1)
	elif evento.is_action_pressed("ui_up"):
		accept_event()
		_mudar_regiao(-1)
	elif evento.is_action_pressed("ui_down"):
		accept_event()
		_mudar_regiao(1)
	elif evento.is_action_pressed("ui_accept"):
		accept_event()
		_confirmar()


# ── santuário ────────────────────────────────────────────────────────────

func _abrir_santuario() -> void:
	if _santuario != null:
		return
	Som.toca("porta", -10.0, 1.1)
	_santuario = SANTUARIO_CENA.instantiate()
	_santuario.z_index = 100
	add_child(_santuario)
	_santuario.fechado.connect(func() -> void:
		if is_instance_valid(_santuario):
			_santuario.queue_free()
		_santuario = null
		_actualizar())


# ── nomes / arte ─────────────────────────────────────────────────────────

## Nome do nível: chave `level.n##` traduzida; se faltar, cai no nome do
## ficheiro da cena com underscores -> espaços.
func _nome_nivel(indice: int) -> String:
	if indice < 0:
		return ""
	var chave := CatalogoCampanha.chave_nivel(indice)
	var txt := Textos.t(chave)
	if txt != chave:
		return txt
	if indice < EstadoJogo.NIVEIS.size():
		return (EstadoJogo.NIVEIS[indice] as String).get_file().get_basename().replace("_", " ")
	return chave


func _nome_chefe(indice: int) -> String:
	if indice < 0:
		return ""
	var chave := CatalogoCampanha.chave_chefe(indice)
	return Textos.t(chave) if chave != "" else ""


## Miniatura do painel. Onde há arte de produção da região, é ELA que se vê
## (a Região I tem o panorama da Árvore-Coração); fora disso volta-se à
## camada de parallax de sempre. A `FUNDO_REGIAO[0]` era uma floresta de
## OUTONO, laranja e vermelha, e num ecrã verde lia-se como um erro.
func _fundo_regiao(r: int) -> Texture2D:
	var t := TemaRegiao.do_indice(r)
	var mini: String = String(t.get("miniatura", ""))
	if mini != "" and ResourceLoader.exists(mini):
		return load(mini)
	if r < 0 or r >= FUNDO_REGIAO.size():
		return null
	var cam: String = FUNDO_REGIAO[r]
	return load(cam) if ResourceLoader.exists(cam) else null


func _retrato_chefe(indice: int) -> Texture2D:
	if indice < 0 or indice >= RETRATO_CHEFE.size():
		return null
	var slug: String = RETRATO_CHEFE[indice]
	if slug == "":
		return null

	var cam := "res://assets/sprites/pixel/bosses_anim/%s/idle.png" % slug
	if ResourceLoader.exists(cam):
		var cfg: Variant = ChefeBase._rigs().get(slug, null)
		var n := 1
		if cfg is Dictionary:
			n = int(((cfg as Dictionary).get("estados", {}) as Dictionary).get("idle", 1))
		return _frame0(cam, maxi(1, n))

	cam = "res://assets/sprites/pixel/enemies/%s/idle.png" % slug
	if ResourceLoader.exists(cam):
		var esp: Dictionary = DemonioBase.ESPECIES.get(slug, {})
		return _frame0(cam, maxi(1, int(esp.get("idle", 4))))

	cam = "res://assets/sprites/pixel/bosses/%s.png" % slug
	if FileAccess.file_exists(cam):
		var folha := load(cam) as Texture2D
		if folha == null:
			return null
		# Os bosses antigos usam tiras horizontais de quatro poses; os
		# retratos novos são PNGs únicos quadrados.
		return _frame0(cam, 4) if folha.get_width() > folha.get_height() * 1.5 else folha
	cam = "res://assets/sprites/pixel/bosses/%s.svg" % slug
	if FileAccess.file_exists(cam):
		return load(cam)
	return null


## Primeiro frame de uma tira horizontal de `n` frames.
func _frame0(caminho: String, n: int) -> Texture2D:
	var folha: Texture2D = load(caminho)
	if folha == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = folha
	atlas.region = Rect2(0, 0, folha.get_width() / float(n), folha.get_height())
	return atlas


## Cor da região `r` (ordem de `EstadoJogo.REGIOES`). Mantida para quem a
## usava de fora (testes e a HUD).
func cor_regiao(r: int) -> Color:
	if r < 0 or r >= EstadoJogo.REGIOES.size():
		return Color(0.7, 0.7, 0.7)
	return EstadoJogo.REGIOES[r].get("cor", Color(0.7, 0.7, 0.7))
