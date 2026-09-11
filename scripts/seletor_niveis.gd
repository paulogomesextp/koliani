class_name SeletorNiveis
extends Control
## Carrossel moderno de escolha de nível (estilo cover-flow): uma fila de
## cartões que desliza na horizontal, com o cartão do meio ampliado. Cada
## cartão mostra a região, o número (N / total), o nome do nível e o nome
## do chefe, mais o estado (concluído / trancado).
##
## Reutilizável:
##   - `MapaMundo` (modo normal): `configurar(indice, true)` -- respeita os
##     bloqueios; níveis por alcançar não entram.
##   - `DevBarra` (DEVELOPER MODE): `configurar(indice, false)` -- pode
##     saltar para qualquer nível.
##
## Sinais: `escolhido(indice)` quando se confirma um nível jogável;
## `cancelado` quando se recua (botão Voltar / ui_cancel).

signal escolhido(indice: int)
signal cancelado

## A chave i18n e a cor de cada região vivem em `EstadoJogo.REGIOES` (campos
## `chave` e `cor`) -- eram tabelas locais de 6 entradas que ficaram para
## trás quando a campanha passou a 20 regiões: da 7.ª em diante o carrossel
## dizia "?" e pintava tudo de cinzento.

## Arte de fundo por região -- preview no cartão. Uma camada do pack de
## parallax que o primeiro nível da região usa (`fundo_pack` no `.tscn`).
## Regiões que partilham pack levam camadas diferentes; a tinta da região
## acaba de as separar.
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


## Cor da região `r` (ordem de `EstadoJogo.REGIOES`).
func cor_regiao(r: int) -> Color:
	if r < 0 or r >= EstadoJogo.REGIOES.size():
		return Color(0.7, 0.7, 0.7)
	return EstadoJogo.REGIOES[r].get("cor", Color(0.7, 0.7, 0.7))

## Nome do ficheiro do retrato do chefe (assets/sprites/pixel/bosses/<x>.png,
## tira de 4 frames -- usa-se o frame 0) por índice de nível. "" = ainda sem
## pixel-art (fica só com o preview do bioma).
const RETRATO_CHEFE := [
	"minotauro", "bruxa", "horror", "folha", "demonio_lodo",              # 1-5
	"guardiao_gelo", "cavaleiro_fogo", "verdugo", "monge", "prisioneiro", # 6-10
	"mimico", "monge_celeste", "arqueiro", "sacerdotisa", "alado",        # 11-15
	"rei_ossario", "ceifeiro", "feiticeiro_sombrio", "serpente", "olho_voador", # 16-20
	"lanceiro", "carniceiro", "golem_pedra", "feiticeiro", "noiva",       # 21-25
	"cavaleiro_negro", "koliani_sombria", "rei_devorador", "arauto", "colosso", # 26-30
	# --- niveis 31-100 -- GERADO por tools/gerar_niveis_31_100.py --------
	# Rig animado (bosses_anim/) nos chefes, especie (enemies/) nos
	# guardioes; o `_retrato_chefe` tenta as duas pastas.
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

const CARTAO := Vector2(336, 392)
const PASSO := 372.0          # cartão + intervalo
const DUR := 0.26

var _respeitar_bloqueio := true
var _sel := 0
var _faixa: Control
var _cartoes: Array[Dictionary] = []   # [{ raiz, indice, jogavel, nome, chefe, estado, pill }]
var _jogar: Button
var _dica: Label
var _arrastar_x := 0.0
var _arrastar_base := 0.0
var _arrastando := false
var _pronto := false

## Barra de progresso da campanha + pastilhas de região (atalho de zona) --
## construídas em `_montar_topo`, atualizadas em `_reconstruir_estilos`.
var _prog_fill: Control
var _prog_label: Label
var _regiao_pills: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_montar()
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	resized.connect(_reposicionar.bind(true))
	get_viewport().size_changed.connect(_reposicionar.bind(true))
	call_deferred("_reposicionar", true)


## Ponto de entrada. `indice_inicial` = nível a mostrar centrado;
## `respeitar_bloqueio` = se true, só deixa confirmar níveis desbloqueados
## (modo normal) e arranca na fronteira se o índice pedido estiver trancado.
func configurar(indice_inicial: int, respeitar_bloqueio: bool) -> void:
	_respeitar_bloqueio = respeitar_bloqueio
	var alvo := clampi(indice_inicial, 0, EstadoJogo.NIVEIS.size() - 1)
	if respeitar_bloqueio and not EstadoJogo.nivel_desbloqueado(alvo):
		alvo = EstadoJogo.fronteira()
	_sel = alvo
	if _pronto:
		_reconstruir_estilos()
		_reposicionar(true)
		_traduzir()
		_atualizar_fundo()


# --- construção ----------------------------------------------------------

var _fundo_arte: TextureRect

func _montar() -> void:
	_montar_fundo()

	_faixa = Control.new()
	_faixa.name = "Faixa"
	_faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_faixa)

	for i in EstadoJogo.NIVEIS.size():
		var c := _fazer_cartao(i)
		_faixa.add_child(c["raiz"])
		_cartoes.append(c)

	_montar_seta("‹", -1, true)
	_montar_seta("›", 1, false)
	_montar_rodape()
	_montar_topo()
	# Execution 9F: botões do rodapé no kit de produção (prancha 09)
	UIProducao.vestir_ecra(self)
	for b in find_children("*", "Button", true, false):
		if b.has_meta("principal_9f"):
			b.add_theme_stylebox_override("normal", UIProducao.caixa("botao_selecionado", Vector4(40, 12, 40, 12)))
	for seta in [find_child("SetaEsq", true, false), find_child("SetaDir", true, false)]:
		if seta:
			for e in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
				(seta as Button).add_theme_stylebox_override(e, StyleBoxEmpty.new())
	_pronto = true
	_reconstruir_estilos()
	_reposicionar(true)
	_traduzir()
	_atualizar_fundo()


const ART_FRAC := 0.60   # fração do cartão ocupada pela arte/retrato
## Recuo da janela de arte para dentro da moldura. A nine-patch de pedra
## desenha 30 px de moldura (10 px da folha x3, ver `UI.MARGEM_PAINEL`);
## a arte entra por dentro dela, senão tapava-a e voltávamos à caixa lisa.
const MARG_MOLDURA := 24.0

## ALTURA MÍNIMA de qualquer peça vestida com `UI.painel("painel_*")`.
## A nine-patch dos painéis grandes tem 30 px de moldura de cada lado
## (`UI.MARGEM_PAINEL`): abaixo de 60 px de altura os cantos sobrepõem-se e
## a peça sai partida -- os botões do rodapé, a 44 px, desenhavam-se como
## dois blocos soltos. Peças mais baixas que isto usam o `selo` (15 px de
## moldura, ver `UI.MARGEM_SELO`), que aguenta até 30 px.
const ALT_MIN_PAINEL := 64.0

func _fazer_cartao(indice: int) -> Dictionary:
	var regiao := EstadoJogo.regiao_do_nivel(indice)
	var base := cor_regiao(regiao)
	var art_h := CARTAO.y * ART_FRAC

	var raiz := Control.new()
	raiz.custom_minimum_size = CARTAO
	raiz.size = CARTAO
	raiz.pivot_offset = CARTAO * 0.5
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP

	# --- moldura do cartão: a PEDRA do kit da HUD (`UI.painel`) ----------
	# O brilho de selecção vive num nó SEPARADO, por baixo: uma
	# `StyleBoxTexture` não tem sombra, e era a sombra que fazia o cartão do
	# meio saltar à frente dos vizinhos.
	var brilho := Panel.new()
	brilho.name = "Brilho"
	brilho.set_anchors_preset(Control.PRESET_FULL_RECT)
	brilho.offset_left = -8.0
	brilho.offset_top = -8.0
	brilho.offset_right = 8.0
	brilho.offset_bottom = 8.0
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brilho.modulate.a = 0.0
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = Color(0, 0, 0, 0)
	sbg.shadow_color = Color(UIProducao.OURO.r, UIProducao.OURO.g, UIProducao.OURO.b, 0.22)
	sbg.shadow_size = 10
	brilho.add_theme_stylebox_override("panel", sbg)
	raiz.add_child(brilho)

	var painel := Panel.new()
	painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	raiz.add_child(painel)
	# Execution 9F: a moldura de ouro da prancha 09 (secção 9) -- apagada
	# nos vizinhos, acesa no escolhido, como os cartões da secção 5
	var sb := UIProducao.caixa("moldura_ornamentada", Vector4(0, 0, 0, 0),
		Color(0.55, 0.55, 0.62, 0.98))
	var sb_sel := UIProducao.caixa("moldura_ornamentada", Vector4(0, 0, 0, 0))
	painel.add_theme_stylebox_override("panel", sb)

	# interior escuro dentro da moldura: é ele que faz a pedra ler-se como
	# MOLDURA e não como laje, e é sobre ele que o texto fica legível --
	# sem isto o nome do nível caía em cima da pedra clara do cartão aceso.
	var dentro := ColorRect.new()
	dentro.name = "Dentro"
	dentro.color = Color(0.05, 0.04, 0.08, 0.96)
	dentro.position = Vector2(MARG_MOLDURA, MARG_MOLDURA)
	dentro.size = CARTAO - Vector2(MARG_MOLDURA, MARG_MOLDURA) * 2.0
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(dentro)

	# --- zona de arte (topo) --------------------------------------------
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = Vector2(MARG_MOLDURA, MARG_MOLDURA)
	clip.size = Vector2(CARTAO.x - MARG_MOLDURA * 2.0, art_h)
	raiz.add_child(clip)

	var arte := TextureRect.new()
	arte.name = "Arte"
	if regiao >= 0 and regiao < FUNDO_REGIAO.size() and ResourceLoader.exists(FUNDO_REGIAO[regiao]):
		arte.texture = load(FUNDO_REGIAO[regiao])
	arte.set_anchors_preset(Control.PRESET_FULL_RECT)
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arte.modulate = Color(0.62, 0.62, 0.7)   # side; o destaque acende
	clip.add_child(arte)

	# scrim de baixo -> texto legível por cima da arte
	var scrim := TextureRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0.05, 0.04, 0.09, 0.0),
		Color(0.06, 0.04, 0.1, 0.55), Color(0.06, 0.04, 0.1, 0.98)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	scrim.texture = gt
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	clip.add_child(scrim)

	# retrato do chefe -- grande, sobre a arte
	var retrato_tex := _retrato_chefe(indice)
	if retrato_tex:
		var retrato := TextureRect.new()
		retrato.name = "Retrato"
		retrato.texture = retrato_tex
		retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var rs := art_h * 1.15
		retrato.size = Vector2(rs, rs)
		retrato.position = Vector2((clip.size.x - rs) * 0.5, art_h - rs + art_h * 0.16)
		retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip.add_child(retrato)

	# --- selo do número (canto sup. esq.) -- o mesmo selo da HUD ---------
	var selo := PanelContainer.new()
	selo.name = "Selo"
	selo.custom_minimum_size = Vector2(54, 54)
	selo.size = Vector2(54, 54)
	selo.position = Vector2(MARG_MOLDURA - 8.0, MARG_MOLDURA - 8.0)
	selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	selo.custom_minimum_size = Vector2(72, 44)
	selo.size = Vector2(72, 44)
	selo.add_theme_stylebox_override("panel", UIProducao.caixa("botao_desativado", Vector4(8, 2, 8, 2)))
	raiz.add_child(selo)

	var badge := Label.new()
	badge.name = "Numero"
	badge.text = _numero_regional(indice)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 20)
	badge.add_theme_color_override("font_color", UIProducao.OURO_CLARO)
	badge.add_theme_color_override("font_outline_color", Color(0.04, 0.01, 0.06))
	badge.add_theme_constant_override("outline_size", 5)
	selo.add_child(badge)

	# --- fita de estado (canto sup. dir.) -----------------------------
	var pill := Label.new()
	pill.name = "Pill"
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_theme_font_size_override("font_size", 13)
	pill.size = Vector2(140, 40)
	pill.position = Vector2(CARTAO.x - MARG_MOLDURA - 140.0, MARG_MOLDURA - 2.0)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(pill)

	# --- band de info (fundo) ----------------------------------------
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.position = Vector2(MARG_MOLDURA + 12.0, art_h + MARG_MOLDURA + 6.0)
	info.size = Vector2(CARTAO.x - (MARG_MOLDURA + 12.0) * 2.0,
		CARTAO.y - art_h - MARG_MOLDURA * 2.0 - 6.0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var faixa_reg := Label.new()
	faixa_reg.name = "Regiao"
	faixa_reg.add_theme_font_size_override("font_size", 12)
	faixa_reg.add_theme_color_override("font_color", base.lightened(0.25))
	info.add_child(faixa_reg)

	var nome := Label.new()
	nome.name = "Nome"
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.custom_minimum_size = Vector2(CARTAO.x - (MARG_MOLDURA + 12.0) * 2.0, 0)
	nome.add_theme_font_size_override("font_size", 25)
	nome.add_theme_color_override("font_color", Color(0.98, 0.95, 1))
	nome.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03))
	nome.add_theme_constant_override("outline_size", 4)
	info.add_child(nome)

	var chefe := Label.new()
	chefe.name = "Chefe"
	chefe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chefe.custom_minimum_size = Vector2(CARTAO.x - (MARG_MOLDURA + 12.0) * 2.0, 0)
	chefe.add_theme_font_size_override("font_size", 15)
	chefe.add_theme_color_override("font_color", Color(0.84, 0.64, 0.92))
	info.add_child(chefe)

	var premio := Label.new()
	premio.name = "Premio"
	premio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	premio.custom_minimum_size = Vector2(CARTAO.x - (MARG_MOLDURA + 12.0) * 2.0, 0)
	premio.add_theme_font_size_override("font_size", 13)
	premio.add_theme_color_override("font_color", Color(0.98, 0.86, 0.55))
	info.add_child(premio)
	raiz.add_child(info)

	raiz.gui_input.connect(_cartao_input.bind(indice))

	return {
		"raiz": raiz, "indice": indice, "jogavel": true,
		"regiao": faixa_reg, "numero": badge, "nome": nome,
		"chefe": chefe, "premio": premio, "pill": pill, "base": base,
		"arte": arte, "painel": painel, "sb_normal": sb, "sb_sel": sb_sel,
		"brilho": brilho, "em_destaque": false,
	}


## Frame 0 (repouso) do retrato do chefe/guardião do nível `indice`, ou
## null se não houver.
##
## Há TRÊS sítios onde o boneco pode viver, e o nome sozinho não diz qual --
## por isso tentam-se os três por ordem (3 set 2026: até aqui só se olhava
## para o primeiro, e os níveis 31-100 ficavam sem retrato nenhum):
##
##   1. `bosses_anim/<rig>/idle.png`   -- rig animado (a maioria hoje)
##   2. `enemies/<especie>/idle.png`   -- os GUARDIÕES dos níveis 31-100
##      não são chefes: são elites de uma espécie comum
##   3. `bosses/<slug>.png`            -- as folhas estáticas de 4 poses
##      dos primeiros chefes, que ainda não passaram a rig
##
## O número de frames da tira muda conforme o sítio, e cortar com o número
## errado dá meio boneco -- daí ir buscá-lo ao catálogo de cada um.
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


## Seta de navegação: o chevron solto da prancha 09 (secção 5) -- sem
## placa, claro sobre o fundo escuro, a ouro ao passar.
func _montar_seta(txt: String, dir: int, esquerda: bool) -> void:
	var b := Button.new()
	b.name = "SetaEsq" if esquerda else "SetaDir"
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	for e in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", 72)
	b.add_theme_color_override("font_color", UIProducao.TEXTO)
	b.add_theme_color_override("font_hover_color", UIProducao.OURO_CLARO)
	b.add_theme_color_override("font_pressed_color", UIProducao.OURO)
	b.add_theme_color_override("font_outline_color", UIProducao.CONTORNO)
	b.add_theme_constant_override("outline_size", 8)
	b.anchor_top = 0.5
	b.anchor_bottom = 0.5
	b.offset_top = -36.0
	b.offset_bottom = 36.0
	if esquerda:
		b.anchor_left = 0.0
		b.anchor_right = 0.0
		b.offset_left = 14.0
		b.offset_right = 86.0
	else:
		b.anchor_left = 1.0
		b.anchor_right = 1.0
		b.offset_left = -86.0
		b.offset_right = -14.0
	b.pivot_offset = Vector2(36, 36)
	b.mouse_entered.connect(func() -> void: _animar_escala(b, 1.1))
	b.mouse_exited.connect(func() -> void: _animar_escala(b, 1.0))
	b.pressed.connect(_mover.bind(dir))
	add_child(b)


func _animar_escala(no: Control, alvo: float) -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(no, "scale", Vector2(alvo, alvo), 0.15)


const SANTUARIO_CENA := preload("res://scenes/ui/Santuario.tscn")
var _santuario: Control

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
		_reconstruir_estilos())   # ex.: cores/estados podem depender de melhorias


func _montar_rodape() -> void:
	var barra := HBoxContainer.new()
	barra.anchor_left = 0.5
	barra.anchor_right = 0.5
	barra.anchor_top = 1.0
	barra.anchor_bottom = 1.0
	barra.offset_left = -280.0
	barra.offset_right = 280.0
	barra.offset_top = -104.0
	barra.offset_bottom = -40.0
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override("separation", 18)
	add_child(barra)

	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.custom_minimum_size = Vector2(150, ALT_MIN_PAINEL)
	_estilo_botao_rodape(voltar, false)
	voltar.pressed.connect(func() -> void: cancelado.emit())
	barra.add_child(voltar)

	var santuario := Button.new()
	santuario.name = "Santuario"
	santuario.focus_mode = Control.FOCUS_NONE
	santuario.custom_minimum_size = Vector2(175, ALT_MIN_PAINEL)
	_estilo_botao_rodape(santuario, false)
	var chave_sant := Textos.t("shrine.open")
	santuario.text = chave_sant if chave_sant != "shrine.open" else "✦ Santuário"
	santuario.pressed.connect(_abrir_santuario)
	barra.add_child(santuario)

	_jogar = Button.new()
	_jogar.name = "Jogar"
	_jogar.focus_mode = Control.FOCUS_NONE
	_jogar.custom_minimum_size = Vector2(150, ALT_MIN_PAINEL)
	_estilo_botao_rodape(_jogar, true)
	_jogar.pressed.connect(_confirmar)
	barra.add_child(_jogar)

	_dica = Label.new()
	_dica.name = "Dica"
	_dica.anchor_left = 0.5
	_dica.anchor_right = 0.5
	_dica.anchor_top = 1.0
	_dica.anchor_bottom = 1.0
	_dica.offset_left = -380.0
	_dica.offset_right = 380.0
	_dica.offset_top = -34.0
	_dica.offset_bottom = -12.0
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.add_theme_font_size_override("font_size", 14)
	_dica.add_theme_color_override("font_color", Color(0.66, 0.6, 0.76, 0.75))
	add_child(_dica)


## Fundo do ecrã: a arte da região atual, muito escura, + gradiente + um
## painel base para o carrossel nunca ficar sobre o preto puro.
func _montar_fundo() -> void:
	var base := ColorRect.new()
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.color = Color(0.04, 0.03, 0.06)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	_fundo_arte = TextureRect.new()
	_fundo_arte.name = "FundoArte"
	_fundo_arte.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fundo_arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fundo_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo_arte.modulate = Color(0.28, 0.28, 0.34, 1.0)
	add_child(_fundo_arte)

	var grad := TextureRect.new()
	grad.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(0.03, 0.02, 0.05, 0.35),
		Color(0.04, 0.03, 0.07, 0.72), Color(0.02, 0.02, 0.04, 0.95)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	grad.texture = gt
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(grad)


func _atualizar_fundo() -> void:
	if _fundo_arte == null:
		return
	var regiao := EstadoJogo.regiao_do_nivel(_sel)
	if regiao < 0 or regiao >= FUNDO_REGIAO.size() or not ResourceLoader.exists(FUNDO_REGIAO[regiao]):
		return
	var nova := load(FUNDO_REGIAO[regiao]) as Texture2D
	if _fundo_arte.texture == nova:
		return
	var cor := cor_regiao(regiao)
	var alvo := Color(cor.r * 0.4 + 0.1, cor.g * 0.4 + 0.1, cor.b * 0.4 + 0.1, 1.0)
	var t := create_tween()
	t.tween_property(_fundo_arte, "modulate:a", 0.0, 0.12)
	t.tween_callback(func() -> void: _fundo_arte.texture = nova)
	t.tween_property(_fundo_arte, "modulate", alvo, 0.28)


## Cabeçalho moderno por cima do carrossel: pastilhas de região (atalho de
## zona -- salta logo para lá em vez de percorrer nível a nível) + barra
## fina com o progresso total da campanha.
##
## Execution 9F -- a estrutura da campanha tem de se LER no ecrã:
## 20 REGIÕES × 5 NÍVEIS. Por cima: legenda, as 20 pastilhas em numeração
## romana (I..XX), e o cabeçalho da região escolhida ("I · FLORESTA ...
## · 0 / 5") com o total da campanha à direita. O carrossel só mostra os
## 5 níveis dessa região, numerados "1-1".."1-5" (como a secção 5 da
## prancha 09). ↑/↓ (ou as pastilhas) mudam de região.
var _cab_regiao: Label
var _cab_progresso: Label
var _pontos: Array[Label] = []

const ROMANOS := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
	"XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]


func _romano(r: int) -> String:
	return ROMANOS[r] if r >= 0 and r < ROMANOS.size() else str(r + 1)


## "1-3" = região 1, 3.º nível dela.
func _numero_regional(indice: int) -> String:
	var r := EstadoJogo.regiao_do_nivel(indice)
	if r < 0 or r >= EstadoJogo.REGIOES.size():
		return "%02d" % (indice + 1)
	var niveis: Array = EstadoJogo.REGIOES[r]["niveis"]
	return "%d-%d" % [r + 1, niveis.find(indice) + 1]


func _montar_topo() -> void:
	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.anchor_left = 0.5
	titulo.anchor_right = 0.5
	titulo.offset_left = -300.0
	titulo.offset_right = 300.0
	titulo.offset_top = 14.0
	titulo.offset_bottom = 38.0
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIProducao.seccao(titulo, 16)
	titulo.add_theme_color_override("font_outline_color", UIProducao.CONTORNO)
	titulo.add_theme_constant_override("outline_size", 3)
	titulo.text = Textos.t("sel.title") if Textos.t("sel.title") != "sel.title" else "ESCOLHER NÍVEL"
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(titulo)

	var pastilhas := HBoxContainer.new()
	pastilhas.name = "Pastilhas"
	pastilhas.anchor_left = 0.5
	pastilhas.anchor_right = 0.5
	pastilhas.offset_top = 42.0
	pastilhas.offset_bottom = 78.0
	pastilhas.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pastilhas.alignment = BoxContainer.ALIGNMENT_CENTER
	pastilhas.add_theme_constant_override("separation", 4)
	pastilhas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pastilhas)

	# pastilha = a placa do botão normal da prancha (apagada) / de ouro
	# (a região aberta); o texto é o numeral romano da região
	var sb := UIProducao.caixa("botao_desativado", Vector4(4, 2, 4, 2))
	var sb_ativa := UIProducao.caixa("botao_normal", Vector4(4, 2, 4, 2), Color(1.25, 1.05, 0.7))
	var sb_hover := UIProducao.caixa("botao_normal", Vector4(4, 2, 4, 2))
	for r in EstadoJogo.REGIOES.size():
		var b := Button.new()
		b.name = "Regiao%d" % r
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(50, 36)
		b.text = _romano(r)
		b.tooltip_text = Textos.t(EstadoJogo.REGIOES[r].get("chave", ""))
		b.add_theme_font_size_override("font_size", 13)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.set_meta("sb_normal", sb)
		b.set_meta("sb_ativa", sb_ativa)
		b.set_meta("sb_hover", sb_hover)
		b.pressed.connect(_ir_para_regiao.bind(r))
		pastilhas.add_child(b)
		_regiao_pills.append(b)

	_cab_regiao = Label.new()
	_cab_regiao.name = "CabecalhoRegiao"
	_cab_regiao.anchor_left = 0.5
	_cab_regiao.anchor_right = 0.5
	_cab_regiao.offset_left = -420.0
	_cab_regiao.offset_right = 420.0
	_cab_regiao.offset_top = 84.0
	_cab_regiao.offset_bottom = 124.0
	_cab_regiao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cab_regiao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cab_regiao.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UIProducao.titulo(_cab_regiao, 30)
	_cab_regiao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cab_regiao)

	# os 5 níveis da região, em linha: "1-1 ✓  1-2  1-3 🔒 ..." -- mostra
	# de relance que a região tem cinco e onde se está
	var linha := HBoxContainer.new()
	linha.name = "NiveisDaRegiao"
	linha.anchor_left = 0.5
	linha.anchor_right = 0.5
	linha.offset_top = 124.0
	linha.offset_bottom = 148.0
	linha.grow_horizontal = Control.GROW_DIRECTION_BOTH
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 22)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(linha)
	for k in 5:
		var p := Label.new()
		p.add_theme_font_size_override("font_size", 15)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		linha.add_child(p)
		_pontos.append(p)

	_cab_progresso = Label.new()
	_cab_progresso.name = "ProgressoCampanha"
	_cab_progresso.anchor_left = 1.0
	_cab_progresso.anchor_right = 1.0
	_cab_progresso.offset_left = -220.0
	_cab_progresso.offset_right = -24.0
	_cab_progresso.offset_top = 14.0
	_cab_progresso.offset_bottom = 38.0
	_cab_progresso.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cab_progresso.add_theme_font_size_override("font_size", 14)
	_cab_progresso.add_theme_color_override("font_color", UIProducao.TEXTO_APAGADO)
	_cab_progresso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prog_label = _cab_progresso
	add_child(_cab_progresso)


## Pastilha de região premida -- salta para o 1.º nível alcançável dessa
## região (ou o 1.º da região, em modo dev / sem bloqueios).
func _ir_para_regiao(regiao: int) -> void:
	if regiao < 0 or regiao >= EstadoJogo.REGIOES.size():
		return
	var niveis: Array = EstadoJogo.REGIOES[regiao]["niveis"]
	if niveis.is_empty():
		return
	var alvo: int = niveis[0]
	if _respeitar_bloqueio:
		for n in niveis:
			if EstadoJogo.nivel_desbloqueado(n):
				alvo = n
	Som.toca("apanhar", -17.0, 1.2)
	_ir_para(alvo)


## Botões do rodapé: o tema de produção (9F) veste-os todos; o principal
## (JOGAR) é o botão SELECIONADO da prancha 09 também em repouso -- a
## hierarquia sai da moldura de ouro. Chamado antes do `vestir_ecra`, por
## isso o override do principal é posto depois (em `_montar`).
func _estilo_botao_rodape(b: Button, principal: bool) -> void:
	b.add_theme_font_size_override("font_size", 16 if not principal else 18)
	if principal:
		b.set_meta("principal_9f", true)
	b.pivot_offset = b.custom_minimum_size / 2.0
	b.mouse_entered.connect(func() -> void: _animar_escala(b, 1.05))
	b.mouse_exited.connect(func() -> void: _animar_escala(b, 1.0))


# --- estado / layout ---------------------------------------------------

func _reconstruir_estilos() -> void:
	for c in _cartoes:
		var idx: int = c["indice"]
		var jog := (not _respeitar_bloqueio) or EstadoJogo.nivel_desbloqueado(idx)
		c["jogavel"] = jog
		var regiao := EstadoJogo.regiao_do_nivel(idx)
		var nome_regiao := Textos.t(EstadoJogo.chave_regiao_do_nivel(idx))
		(c["regiao"] as Label).text = "%s  ·  %s" % [nome_regiao.to_upper(), _progresso_regiao(regiao)]
		(c["numero"] as Label).text = _numero_regional(idx)
		(c["nome"] as Label).text = _nome_nivel(idx)
		var rotulo := "sel.boss" if CatalogoCampanha.tem_chefe(idx) else "sel.guard"
		(c["chefe"] as Label).text = Textos.tf(rotulo, [_nome_chefe(idx)])
		(c["premio"] as Label).text = _texto_premio(idx)
		var pill := c["pill"] as Label
		var painel := c["painel"] as Panel
		painel.modulate = Color(1, 1, 1)
		if EstadoJogo.nivel_esta_concluido(idx):
			pill.text = "✓ " + Textos.t("sel.cleared")
			pill.visible = true
			_estilo_pill(pill, Color(0.38, 0.82, 0.5))
		elif not jog:
			pill.text = Textos.t("sel.locked")   # sem emoji: tofu no Web (9F)
			pill.visible = true
			_estilo_pill(pill, Color(0.5, 0.5, 0.56))
			painel.modulate = Color(0.72, 0.7, 0.78)   # cartão trancado esbatido
		else:
			pill.visible = false
	_atualizar_topo()


## Atualiza a barra de progresso total + a pastilha de região em destaque
## (a do nível selecionado no carrossel).
func _atualizar_topo() -> void:
	var total := EstadoJogo.NIVEIS.size()
	var feitos := 0
	for i in total:
		if EstadoJogo.nivel_esta_concluido(i):
			feitos += 1
	if _prog_fill:
		_prog_fill.anchor_right = clampf(float(feitos) / maxf(1.0, float(total)), 0.0, 1.0)
	if _prog_label:
		_prog_label.text = Textos.tf("sel.count", [feitos, total])
	var regiao_atual := EstadoJogo.regiao_do_nivel(_sel)
	for r in _regiao_pills.size():
		var b := _regiao_pills[r]
		var ativa := r == regiao_atual
		b.add_theme_stylebox_override("normal", b.get_meta("sb_ativa") if ativa else b.get_meta("sb_normal"))
		b.add_theme_stylebox_override("hover", b.get_meta("sb_ativa") if ativa else b.get_meta("sb_hover"))
		b.add_theme_stylebox_override("pressed", b.get_meta("sb_ativa"))
		b.add_theme_color_override("font_color", UIProducao.OURO_CLARO if ativa else UIProducao.TEXTO_APAGADO)
	if _cab_regiao and regiao_atual >= 0 and regiao_atual < EstadoJogo.REGIOES.size():
		var nome := Textos.t(EstadoJogo.REGIOES[regiao_atual].get("chave", ""))
		_cab_regiao.text = "%s  ·  %s  ·  %s" % [_romano(regiao_atual), nome.to_upper(),
			_progresso_regiao(regiao_atual)]
		var niveis: Array = EstadoJogo.REGIOES[regiao_atual]["niveis"]
		for k in _pontos.size():
			var p := _pontos[k]
			if k >= niveis.size():
				p.visible = false
				continue
			var n: int = niveis[k]
			p.visible = true
			# estado pela COR (a fonte do Web não tem emoji: o 🔒 saía em tofu)
			p.text = "%d-%d" % [regiao_atual + 1, k + 1]
			var cor := UIProducao.TEXTO_APAGADO
			if EstadoJogo.nivel_esta_concluido(n):
				cor = Color(0.5, 0.86, 0.56)
			elif _respeitar_bloqueio and not EstadoJogo.nivel_desbloqueado(n):
				cor = Color(0.36, 0.38, 0.45)
			if n == _sel:
				cor = UIProducao.OURO_CLARO
			p.add_theme_color_override("font_color", cor)
			p.add_theme_font_size_override("font_size", 17 if n == _sel else 15)


## "2 / 5" -- quantos níveis da região já estão concluídos, sobre o total.
func _progresso_regiao(regiao: int) -> String:
	if regiao < 0 or regiao >= EstadoJogo.REGIOES.size():
		return ""
	var niveis: Array = EstadoJogo.REGIOES[regiao]["niveis"]
	var feitos := 0
	for n in niveis:
		if EstadoJogo.nivel_esta_concluido(n):
			feitos += 1
	return "%d / %d" % [feitos, niveis.size()]


## Fita de estado no canto do cartão (CONCLUÍDO / TRANCADO). Placa de pedra
## tingida -- a cor continua a ser o sinal, o material é que passa a ser o
## mesmo da HUD.
func _estilo_pill(pill: Label, cor: Color) -> void:
	pill.add_theme_color_override("font_color", Color(1, 0.98, 1))
	pill.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.05))
	pill.add_theme_constant_override("outline_size", 4)
	# `selo` e não `painel_placa`: a fita tem 40 px e a moldura dos painéis
	# grandes precisa de 60 (ver `ALT_MIN_PAINEL`).
	pill.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pill.add_theme_stylebox_override("normal", UIProducao.caixa("botao_normal",
		Vector4(10, 2, 10, 2), Color(cor.r * 0.5 + 0.5, cor.g * 0.5 + 0.5, cor.b * 0.5 + 0.5)))


func _reposicionar(instantaneo: bool) -> void:
	if not _pronto or size.x < 200.0:
		return
	var centro := size * 0.5 + Vector2(0, 26)
	# 9F: só os 5 níveis da região do escolhido entram na fila -- a
	# posição é a do nível DENTRO da região, e as outras regiões somem
	var regiao_sel := EstadoJogo.regiao_do_nivel(_sel)
	var niveis_sel: Array = EstadoJogo.REGIOES[regiao_sel]["niveis"] if regiao_sel >= 0 else []
	var local_sel := niveis_sel.find(_sel)
	for i in _cartoes.size():
		var raiz := _cartoes[i]["raiz"] as Control
		var local_i := niveis_sel.find(i)
		var fora := local_i < 0
		var rel := (local_i - local_sel) if not fora else (i - _sel) * 10
		var alvo_pos := Vector2(centro.x - CARTAO.x * 0.5 + rel * PASSO, centro.y - CARTAO.y * 0.5)
		var dist: int = absi(rel)
		raiz.visible = not fora
		var escala := 1.0
		var alpha := 1.0
		var dy := 0.0
		if dist == 1:
			escala = 0.82
			alpha = 0.55
			dy = 16.0
		elif dist >= 2:
			escala = 0.7
			alpha = 0.0
			dy = 24.0
		alvo_pos.y += dy
		var destaque := dist == 0
		if destaque != _cartoes[i]["em_destaque"]:
			_cartoes[i]["em_destaque"] = destaque
			var painel := _cartoes[i]["painel"] as Panel
			painel.add_theme_stylebox_override("panel", _cartoes[i]["sb_sel"] if destaque else _cartoes[i]["sb_normal"])
			var arte := _cartoes[i].get("arte") as TextureRect
			if arte:
				var t2 := create_tween()
				t2.tween_property(arte, "modulate", Color(1, 1, 1) if destaque else Color(0.62, 0.62, 0.7), 0.2)
			var bril := _cartoes[i].get("brilho") as Control
			if bril:
				create_tween().tween_property(bril, "modulate:a", 1.0 if destaque else 0.0, 0.2)
		raiz.mouse_filter = Control.MOUSE_FILTER_STOP if dist <= 1 else Control.MOUSE_FILTER_IGNORE
		if instantaneo:
			raiz.position = alvo_pos
			raiz.scale = Vector2(escala, escala)
			raiz.modulate.a = alpha
		else:
			var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			t.tween_property(raiz, "position", alvo_pos, DUR)
			t.tween_property(raiz, "scale", Vector2(escala, escala), DUR)
			t.tween_property(raiz, "modulate:a", alpha, DUR)
		raiz.z_index = 10 - dist
	if _jogar:
		_jogar.disabled = not _cartoes[_sel]["jogavel"]


func _traduzir() -> void:
	if not _pronto:
		return
	var voltar := find_child("Voltar", true, false) as Button
	if voltar:
		voltar.text = Textos.t("sel.back")
	if _jogar:
		_jogar.text = Textos.t("sel.play")
	if _dica:
		_dica.text = Textos.t("sel.hint")
	_reconstruir_estilos()


## Nome do nível: chave `level.n##` traduzida; se faltar, cai no nome do
## ficheiro da cena com underscores -> espaços.
func _nome_nivel(indice: int) -> String:
	var chave := CatalogoCampanha.chave_nivel(indice)
	var txt := Textos.t(chave)
	if txt != chave:
		return txt
	if indice >= 0 and indice < EstadoJogo.NIVEIS.size():
		return (EstadoJogo.NIVEIS[indice] as String).get_file().get_basename().replace("_", " ")
	return chave


func _nome_chefe(indice: int) -> String:
	var chave := CatalogoCampanha.chave_chefe(indice)
	return Textos.t(chave) if chave != "" else ""


## "Prémio: 🗡 Foice do Pântano" -- o que se ganha ao acabar este nível.
## Nos múltiplos de 10 são DOIS (arma + armadura), separados por " · ".
func _texto_premio(indice: int) -> String:
	var rs: Array[Dictionary] = Equipamento.recompensas_do_nivel(indice)
	if rs.is_empty():
		return ""
	var partes: Array[String] = []
	for r: Dictionary in rs:
		var it: Dictionary = Equipamento.arma(r["id"]) if r["tipo"] == "arma" else Equipamento.armadura(r["id"])
		partes.append("%s %s" % ["🗡" if r["tipo"] == "arma" else "🛡",
			Textos.t(it.get("nome", ""))])
	return Textos.tf("sel.reward", ["  ·  ".join(partes)])


# --- navegação -------------------------------------------------------

func _mover(dir: int) -> void:
	var novo := clampi(_sel + dir, 0, _cartoes.size() - 1)
	if novo == _sel:
		return
	_sel = novo
	Som.toca("carrossel", -12.0, randf_range(0.97, 1.05))
	_reposicionar(false)
	_atualizar_topo()
	_atualizar_fundo()


func _ir_para(indice: int) -> void:
	var novo := clampi(indice, 0, _cartoes.size() - 1)
	if novo == _sel:
		return
	_sel = novo
	Som.toca("carrossel", -12.0, randf_range(0.97, 1.05))
	_reposicionar(false)
	_atualizar_topo()
	_atualizar_fundo()


func _confirmar() -> void:
	var c: Dictionary = _cartoes[_sel]
	if not c["jogavel"]:
		Som.toca("dano", -18.0, 0.8)
		var raiz := c["raiz"] as Control
		var t := create_tween()
		t.tween_property(raiz, "position:x", raiz.position.x + 8, 0.04)
		t.tween_property(raiz, "position:x", raiz.position.x - 8, 0.04)
		t.tween_property(raiz, "position:x", raiz.position.x, 0.04)
		return
	Som.toca("porta", -6.0)
	escolhido.emit(c["indice"])


func _cartao_input(evento: InputEvent, indice: int) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if indice == _cartoes[_sel]["indice"]:
			_confirmar()
		else:
			_ir_para(indice)


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed:
		match evento.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				_mover(1)
			MOUSE_BUTTON_WHEEL_UP:
				_mover(-1)
			MOUSE_BUTTON_LEFT:
				_arrastando = true
				_arrastar_x = evento.position.x
				_arrastar_base = evento.position.x
	elif evento is InputEventMouseButton and not evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if _arrastando:
			_arrastando = false
			var delta: float = evento.position.x - _arrastar_base
			if absf(delta) > 40.0:
				_mover(-signi(int(delta)))
	elif evento is InputEventMouseMotion and _arrastando:
		var d: float = evento.position.x - _arrastar_x
		if absf(d) > PASSO * 0.6:
			_mover(-signi(int(d)))
			_arrastar_x = evento.position.x


func _unhandled_input(evento: InputEvent) -> void:
	# `visible` sozinho não chega: dentro da DevBarra o painel-pai está
	# escondido mas este nó continua com visible=true -> J/atacar trocava
	# de nível com o painel fechado.
	if not is_visible_in_tree():
		return
	if evento.is_action_pressed("mover_direita") or evento.is_action_pressed("ui_right"):
		_mover(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("mover_esquerda") or evento.is_action_pressed("ui_left"):
		_mover(-1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("saltar") or evento.is_action_pressed("atacar") or evento.is_action_pressed("ui_accept"):
		_confirmar()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel"):
		cancelado.emit()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("ui_up") or evento.is_action_pressed("ui_down"):
		# 9F: região anterior/seguinte (teclado e comando)
		var r := EstadoJogo.regiao_do_nivel(_sel) + (-1 if evento.is_action_pressed("ui_up") else 1)
		_ir_para_regiao(clampi(r, 0, EstadoJogo.REGIOES.size() - 1))
		get_viewport().set_input_as_handled()
