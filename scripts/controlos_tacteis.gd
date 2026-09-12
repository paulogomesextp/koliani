extends Control
class_name ControlosTacteis
## Os controlos de toque do telemóvel: um **joystick** à esquerda e cinco
## botões à direita -- Projéteis, Escudo, Investida, Espada e **Salto**
## (o maior). A Investida entrou a pedido dele a 5 set 2026.
##
## Porque é que isto não são `TouchScreenButton`s (o que cá estava):
##
##  1. **Não se viam.** Os `TouchScreenButton` do `HUD.tscn` não tinham
##     textura nenhuma -- eram sete rectângulos invisíveis em píxeis fixos.
##     A pessoa tinha de adivinhar onde carregar.
##  2. **Posição fixa em píxeis.** Estavam em `y = 560..620`, o que só bate
##     certo num ecrã de 720 de alto. Aqui a régua é o tamanho do
##     viewport, e o `resized` remede tudo.
##  3. **Andar era um d-pad de dois botões.** O joystick tem zona morta e
##     agarra-se em qualquer sítio da metade esquerda -- não é preciso
##     acertar no desenho.
##
## Multi-toque a sério: cada dedo é um `index` e cada `index` guarda o que
## está a carregar, portanto saltar-a-atacar-e-a-andar é um gesto só.
##
## O ARO NÃO SE MEXE. A primeira versão era um "stick flutuante" (a base
## ia ter com o dedo), que é o costume nos telemóveis -- mas ele viu-o a
## andar e disse que não podia acontecer. Agora a direcção mede-se sempre
## a partir do centro desenhado.
##
## O que continua sem botão: `rolar`. O salto duplo faz-se carregando
## outra vez no Salto.

## Acções, na ordem em que se desenham. `r` é o raio em píxeis a 720 de
## altura de viewport; tudo isto é multiplicado pela escala do ecrã.
##
## Os TAMANHOS são a ordem de importância que ele deu (5 set 2026,
## segunda versão): **Salto, Tiros e Investida** são os que contam;
## **Escudo e Espada** são os menos importantes, ficam pequenos e por
## fora. Os três grandes ocupam o arco natural do polegar (o canto).
## Não é enfeite: o polegar acerta no grande sem olhar, e é isso que
## decide o que se faz a correr.
const BOTOES := [
	{"accao": "defender", "r": 40.0, "dx": -172.0, "dy": -228.0, "icone": "escudo"},
	{"accao": "atacar", "r": 44.0, "dx": -262.0, "dy": -110.0, "icone": "espada"},
	{"accao": "lancar", "r": 62.0, "dx": -40.0, "dy": -170.0, "icone": "projetil"},
	{"accao": "dash", "r": 62.0, "dx": -150.0, "dy": -46.0, "icone": "dash"},
	{"accao": "saltar", "r": 70.0, "dx": 0.0, "dy": 0.0, "icone": "salto"},
]

## Cores da casa (as do key art): pedra roxa escura e acento magenta.
const C_FUNDO := Color(0.09, 0.07, 0.13, 0.55)
const C_BORDA := Color(0.75, 0.68, 0.92, 0.55)
const C_ICONE := Color(0.92, 0.88, 1.0, 0.85)
const C_PRESSA := Color(1.0, 0.27, 0.94, 0.55)
const C_BORDA_PRESSA := Color(1.0, 0.55, 0.98, 0.95)

## Fracção da largura do ecrã que pertence ao joystick. Carregar em
## qualquer sítio desta metade agarra o stick -- não é preciso acertar no
## desenho.
const ZONA_JOYSTICK := 0.44

## Até que distância da BORDA de um botão é que um toque falhado ainda
## conta como sendo dele (pedido do Paulo, 5 set 2026). A pausa fica de
## fora desta rede de propósito: apanhar-se uma pausa sem se querer
## interrompe o jogo, e um erro que pára tudo é pior do que um toque
## perdido.
const APANHA_MAX := 96.0

## O botão de pausa não é um dos quatro: é o menu. Fica pequeno e longe do
## polegar, no canto de cima -- mas TEM de existir, num telemóvel não há ESC.
const R_PAUSA := 30.0

## LAYOUT DO JOGADOR (Execution 9H). Vazio = layout de fábrica (as
## constantes acima). Cheio = o que o jogador guardou em Opções -> EDITAR
## LAYOUT, em frações do viewport (ver `LayoutToque`).
var layout: Dictionary = {}
## Em modo de edição os toques MOVEM os controlos em vez de os carregar.
var modo_edicao := false
## Controlo agarrado no editor: "joy", "pausa" ou o nome de uma ação.
var selecionado := ""
signal layout_mexido

var _escala := 1.0
var _centro_botoes := Vector2.ZERO
var _joy_base := Vector2.ZERO
var _joy_raio := 90.0
var _joy_actual := Vector2.ZERO
var _pausa_centro := Vector2.ZERO

## dedo -> o que está a carregar: o nome da acção, ou "" para o joystick.
var _dedos := {}
## acções que ESTE nó carregou (para não soltar teclas de outra pessoa).
var _premidos := {}


## Acções que o rato dispara e que, num telemóvel, disparavam SOZINHAS.
## O Godot emula um clique de rato a partir de cada toque (e tem de o
## fazer, senão os botões dos menus deixavam de responder ao dedo) -- só
## que o `lancar` tem o botão esquerdo ligado e o `defender` o direito.
## Resultado: tocar em qualquer sítio do ecrã atirava.
##
## Tira-se o rato destas acções QUANDO os controlos de toque estão a ser
## usados. No PC não se mexe em nada: quem joga com rato continua a ter
## o clique. Os menus também não sofrem -- eles usam `Button`, que não
## passa pelo `InputMap`.
const SO_COM_BOTAO := ["lancar", "defender"]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not modo_edicao:
		layout = LayoutToque.carregar()
	resized.connect(_medir)
	visibility_changed.connect(_so_com_botao)
	_medir()
	_so_com_botao()


func _so_com_botao() -> void:
	if not visible:
		return
	for accao in SO_COM_BOTAO:
		if not InputMap.has_action(accao):
			continue
		for ev in InputMap.action_get_events(accao):
			if ev is InputEventMouseButton:
				InputMap.action_erase_event(accao, ev)


func _medir() -> void:
	# a régua é a altura: num ecrã baixo os botões encolhem com ele
	_escala = clampf(size.y / 720.0, 0.75, 1.6)
	# 118 e não 92: ele pediu-o maior. O aro cresce para CIMA (a base
	# fica presa ao fundo), e por isso o `DESVIO_TOQUE` das barras da
	# HUD subiu com ele -- senão o aro passava por cima delas.
	_joy_raio = 118.0 * _escala
	_joy_base = Vector2(_joy_raio * 1.55, size.y - _joy_raio * 1.35)
	_centro_botoes = Vector2(size.x - 118.0 * _escala, size.y - 118.0 * _escala)
	# por BAIXO do contador de essência, que vive de y=16 a y=54 no canto
	_pausa_centro = Vector2(size.x - R_PAUSA * 1.5 * _escala, 104.0 * _escala)
	# o layout do jogador manda por cima de tudo o que ficou medido acima
	var j: Dictionary = layout.get("joystick", {})
	if j.has("x"):
		_joy_base = Vector2(float(j["x"]) * size.x, float(j.get("y", 0.76)) * size.y)
	if j.has("r"):
		_joy_raio = LayoutToque.prender_raio(float(j["r"])) * size.y
	var pa: Dictionary = layout.get("pausa", {})
	if pa.has("x"):
		_pausa_centro = Vector2(float(pa["x"]) * size.x, float(pa.get("y", 0.14)) * size.y)
	_joy_actual = _joy_base
	queue_redraw()


## Raio da pausa, já com o layout do jogador.
func _raio_pausa() -> float:
	var pa: Dictionary = layout.get("pausa", {})
	if pa.has("r"):
		return LayoutToque.prender_raio(float(pa["r"])) * size.y
	return R_PAUSA * _escala


## Centro e raio de um botão, já com a escala do ecrã e com o layout do
## jogador por cima (se houver).
func _sitio(b: Dictionary) -> Array:
	var accao := str(b["accao"])
	var meu: Dictionary = (layout.get("botoes", {}) as Dictionary).get(accao, {})
	var c: Vector2 = _centro_botoes + Vector2(b["dx"], b["dy"]) * _escala
	var r: float = float(b["r"]) * _escala
	if meu.has("x"):
		c = Vector2(float(meu["x"]) * size.x, float(meu.get("y", 0.8)) * size.y)
	if meu.has("r"):
		r = LayoutToque.prender_raio(float(meu["r"])) * size.y
	return [c, r]


## O layout ATUAL em frações do viewport -- é o que o editor guarda.
func layout_actual() -> Dictionary:
	var botoes := {}
	for b in BOTOES:
		var s := _sitio(b)
		botoes[str(b["accao"])] = {
			"x": (s[0] as Vector2).x / maxf(size.x, 1.0),
			"y": (s[0] as Vector2).y / maxf(size.y, 1.0),
			"r": float(s[1]) / maxf(size.y, 1.0)}
	return {
		"joystick": {"x": _joy_base.x / maxf(size.x, 1.0),
			"y": _joy_base.y / maxf(size.y, 1.0),
			"r": _joy_raio / maxf(size.y, 1.0)},
		"pausa": {"x": _pausa_centro.x / maxf(size.x, 1.0),
			"y": _pausa_centro.y / maxf(size.y, 1.0),
			"r": _raio_pausa() / maxf(size.y, 1.0)},
		"botoes": botoes,
	}


# ── edição ───────────────────────────────────────────────────────────────

## Qual o controlo mais perto de `pos` (em píxeis do ecrã).
func controlo_em(pos: Vector2) -> String:
	if pos.distance_to(_pausa_centro) <= _raio_pausa() * 1.4:
		return "pausa"
	for b in BOTOES:
		var s := _sitio(b)
		if pos.distance_to(s[0]) <= float(s[1]) * 1.25:
			return str(b["accao"])
	if pos.distance_to(_joy_base) <= _joy_raio * 1.15:
		return "joy"
	return ""


## Põe o controlo `qual` em `pos` (píxeis), preso ao ecrã.
func mover_controlo(qual: String, pos: Vector2) -> void:
	if qual == "":
		return
	var f := Vector2(pos.x / maxf(size.x, 1.0), pos.y / maxf(size.y, 1.0))
	var r := _raio_de(qual) / maxf(size.y, 1.0)
	f = LayoutToque.prender(f, r, size.y / maxf(size.x, 1.0))
	_definir(qual, {"x": f.x, "y": f.y})


## Muda o tamanho do controlo `qual` em `delta` (fração da altura).
func redimensionar(qual: String, delta: float) -> void:
	if qual == "":
		return
	var r := LayoutToque.prender_raio(_raio_de(qual) / maxf(size.y, 1.0) + delta)
	_definir(qual, {"r": r})


func _raio_de(qual: String) -> float:
	if qual == "joy":
		return _joy_raio
	if qual == "pausa":
		return _raio_pausa()
	for b in BOTOES:
		if str(b["accao"]) == qual:
			return float(_sitio(b)[1])
	return 40.0


func _definir(qual: String, campos: Dictionary) -> void:
	var base := layout_actual()
	if qual == "joy":
		(base["joystick"] as Dictionary).merge(campos, true)
	elif qual == "pausa":
		(base["pausa"] as Dictionary).merge(campos, true)
	else:
		var bs: Dictionary = base["botoes"]
		if not bs.has(qual):
			return
		(bs[qual] as Dictionary).merge(campos, true)
	layout = base
	_medir()
	layout_mexido.emit()


## Volta ao layout de fábrica (em memória -- quem grava é o editor).
func repor_layout() -> void:
	layout = {}
	_medir()
	layout_mexido.emit()


# ── toque ────────────────────────────────────────────────────────────────

func _input(evento: InputEvent) -> void:
	if not visible or modo_edicao:
		return
	# So' se marca o evento como tratado quando ELE E' NOSSO. Marcar sempre
	# tirava o toque a tudo o resto: os botoes WEAPONS/ARMOR da propria HUD
	# deixavam de abrir e o balao de fala (que ja' nao pausa o jogo) nunca
	# mais avancava.
	if evento is InputEventScreenTouch:
		var meu := false
		if evento.pressed:
			meu = _pousar(evento.index, evento.position)
		else:
			meu = _levantar(evento.index)
		if meu:
			get_viewport().set_input_as_handled()
	elif evento is InputEventScreenDrag:
		if _dedos.get(evento.index, null) == "":
			_mexer_joystick(evento.position)
			get_viewport().set_input_as_handled()


## Devolve `true` se o dedo caiu num controlo nosso.
func _pousar(index: int, pos: Vector2) -> bool:
	if pos.distance_to(_pausa_centro) <= _raio_pausa() * 1.3:
		_dedos[index] = "pausa"
		_premir("pausa", true)
		queue_redraw()
		return true
	for b in BOTOES:
		var s := _sitio(b)
		# 1.15 de folga: o dedo tapa o botão e acerta sempre um pouco fora
		if pos.distance_to(s[0]) <= float(s[1]) * 1.15:
			_dedos[index] = str(b["accao"])
			_premir(str(b["accao"]), true)
			queue_redraw()
			return true
	if pos.x < size.x * ZONA_JOYSTICK:
		_dedos[index] = ""
		# a base NAO se mexe (pedido do Paulo, 5 set 2026: "os controlos do
		# telefone movimenta-se ao utilizar, não pode acontecer"). Continua a
		# agarrar-se em qualquer sítio desta metade do ecrã -- o que muda é
		# que a direcção se mede sempre a partir do MESMO centro, o que
		# desenhado no aro.
		_mexer_joystick(pos)
		return true
	# FALHOU POR POUCO -> vale o mais perto. Num telemovel o dedo tapa o
	# botao que quer carregar, e por isso quem falha nao sabe que falhou:
	# fica a carregar no vidro a achar que o jogo nao responde.
	#
	# Mede-se a` BORDA do botao e nao ao centro, senao os pequenos (Escudo,
	# Espada) roubavam os toques aos grandes que estao ao lado -- estar a 90
	# px do centro de um botao de 40 e' bem mais longe do que estar a 90 do
	# centro de um de 70.
	var melhor := -1
	var melhor_d := APANHA_MAX * _escala
	for k in BOTOES.size():
		var s2 := _sitio(BOTOES[k])
		var d: float = pos.distance_to(s2[0]) - float(s2[1]) * 1.15
		if d < melhor_d:
			melhor_d = d
			melhor = k
	if melhor >= 0:
		var accao := str(BOTOES[melhor]["accao"])
		_dedos[index] = accao
		_premir(accao, true)
		queue_redraw()
		return true
	return false


func _levantar(index: int) -> bool:
	if not _dedos.has(index):
		return false
	var o: String = _dedos[index]
	_dedos.erase(index)
	if o == "":
		_premir("mover_esquerda", false)
		_premir("mover_direita", false)
		_premir("mirar_cima", false)
		_premir("mirar_baixo", false)
		_joy_actual = _joy_base
	else:
		_premir(o, false)
	queue_redraw()
	return true


func _mexer_joystick(pos: Vector2) -> void:
	var d := pos - _joy_base
	if d.length() > _joy_raio:
		d = d.normalized() * _joy_raio
	_joy_actual = _joy_base + d
	# zona morta: sem ela o polegar pousado já andava sozinho
	var morta := _joy_raio * 0.26
	_premir("mover_direita", d.x > morta)
	_premir("mover_esquerda", d.x < -morta)
	# O EIXO DE CIMA/BAIXO É A MIRA. Sem isto, no telemóvel os projéteis só
	# saíam na horizontal: a mira lê o `mirar_cima`/`mirar_baixo`, que só
	# estavam no W e no S do teclado -- não havia nada que os carregasse.
	#
	# A zona morta vertical é MAIOR do que a horizontal: andar é o que se
	# faz sempre, e com a mesma folga dos lados o polegar pousado agachava
	# ou apontava para cima sem se querer.
	var morta_y := _joy_raio * 0.5
	_premir("mirar_baixo", d.y > morta_y)
	_premir("mirar_cima", d.y < -morta_y)
	queue_redraw()


## Carrega/solta uma acção no `InputMap` -- e só solta as que fomos nós a
## carregar, senão roubávamos a tecla ao teclado de quem joga no PC.
func _premir(accao: String, ligado: bool) -> void:
	if not InputMap.has_action(accao):
		return
	if ligado:
		if not bool(_premidos.get(accao, false)):
			_premidos[accao] = true
			Input.action_press(accao)
	elif bool(_premidos.get(accao, false)):
		_premidos[accao] = false
		Input.action_release(accao)


func _notification(que: int) -> void:
	# ao esconder (pausa, fim de nível) larga tudo: um botão premido que
	# nunca mais é solto deixa a Koliani a correr contra a parede
	if que == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_soltar_tudo()
	elif que == NOTIFICATION_EXIT_TREE:
		_soltar_tudo()


func _soltar_tudo() -> void:
	for accao in _premidos.keys():
		if bool(_premidos[accao]):
			_premidos[accao] = false
			Input.action_release(accao)
	_dedos.clear()
	_joy_actual = _joy_base


# ── desenho ──────────────────────────────────────────────────────────────

func _draw() -> void:
	# joystick: aro grande + botão do polegar
	draw_circle(_joy_base, _joy_raio, C_FUNDO)
	draw_arc(_joy_base, _joy_raio, 0.0, TAU, 48, C_BORDA, 3.0 * _escala, true)
	var mexido := _joy_actual.distance_to(_joy_base) > _joy_raio * 0.26
	var c_polegar := C_PRESSA if mexido else Color(0.55, 0.5, 0.72, 0.6)
	draw_circle(_joy_actual, _joy_raio * 0.42, c_polegar)
	draw_arc(_joy_actual, _joy_raio * 0.42, 0.0, TAU, 32,
		C_BORDA_PRESSA if mexido else C_BORDA, 2.5 * _escala, true)
	# as setas do aro dizem para que lados é que isto serve. São QUATRO: o
	# eixo de cima/baixo passou a ser a mira dos tiros, e um controlo que
	# faz uma coisa sem a mostrar é um controlo que ninguém descobre.
	for lado in [-1.0, 1.0]:
		var a := 8.0 * _escala
		var ph := _joy_base + Vector2(lado * _joy_raio * 0.72, 0.0)
		draw_colored_polygon(PackedVector2Array([
			ph + Vector2(lado * a, 0.0), ph + Vector2(-lado * a * 0.5, -a * 0.8),
			ph + Vector2(-lado * a * 0.5, a * 0.8)]), C_BORDA)
		# as verticais são mais fracas: mirar é o gesto raro, andar é o de sempre
		var pv := _joy_base + Vector2(0.0, lado * _joy_raio * 0.72)
		draw_colored_polygon(PackedVector2Array([
			pv + Vector2(0.0, lado * a), pv + Vector2(-a * 0.8, -lado * a * 0.5),
			pv + Vector2(a * 0.8, -lado * a * 0.5)]), Color(C_BORDA, C_BORDA.a * 0.6))

	# pausa: duas barras, o símbolo de sempre
	var rp := _raio_pausa()
	draw_circle(_pausa_centro, rp, C_FUNDO)
	draw_arc(_pausa_centro, rp, 0.0, TAU, 28, C_BORDA, 2.5 * _escala, true)
	for l in [-1.0, 1.0]:
		var barra := rp * 0.34
		draw_rect(Rect2(_pausa_centro + Vector2(l * barra - barra * 0.28, -barra),
			Vector2(barra * 0.55, barra * 2.0)), C_ICONE)

	for b in BOTOES:
		var s := _sitio(b)
		var c: Vector2 = s[0]
		var r: float = s[1]
		var premido: bool = _premidos.get(b["accao"], false)
		draw_circle(c, r, C_PRESSA if premido else C_FUNDO)
		draw_arc(c, r, 0.0, TAU, 40, C_BORDA_PRESSA if premido else C_BORDA,
			3.0 * _escala, true)
		_icone(str(b["icone"]), c, r * 0.52)

	if modo_edicao:
		_marcar_selecionado()


## No editor de layout, o controlo agarrado leva um halo e um alvo: sem isto
## não se sabe qual é que os botões − / + vão mudar.
func _marcar_selecionado() -> void:
	var alvos := {"joy": [_joy_base, _joy_raio], "pausa": [_pausa_centro, _raio_pausa()]}
	for b in BOTOES:
		var s := _sitio(b)
		alvos[str(b["accao"])] = [s[0], s[1]]
	for chave: String in alvos:
		var c: Vector2 = alvos[chave][0]
		var r: float = alvos[chave][1]
		var escolhido := chave == selecionado
		var cor := Color(1.0, 0.42, 0.48, 0.95) if escolhido else Color(1.0, 0.9, 0.95, 0.28)
		draw_arc(c, r + 6.0 * _escala, 0.0, TAU, 48, cor, (4.0 if escolhido else 1.5) * _escala, true)
		if not escolhido:
			continue
		# cruz de mira no centro: diz que ISTO é que se está a arrastar
		var a := r * 0.34
		draw_line(c - Vector2(a, 0), c + Vector2(a, 0), cor, 2.5 * _escala, true)
		draw_line(c - Vector2(0, a), c + Vector2(0, a), cor, 2.5 * _escala, true)


## Os ícones são polígonos: à escala a que isto se vê num telemóvel, um
## desenho com detalhe fica papa -- o que se lê é a silhueta.
func _icone(qual: String, c: Vector2, r: float) -> void:
	match qual:
		"salto":
			# seta grossa para cima
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0.0, -r), c + Vector2(r, 0.0), c + Vector2(r * 0.42, 0.0),
				c + Vector2(r * 0.42, r * 0.8), c + Vector2(-r * 0.42, r * 0.8),
				c + Vector2(-r * 0.42, 0.0), c + Vector2(-r, 0.0)]), C_ICONE)
		"espada":
			# lâmina + guarda + punho, na diagonal
			var eixo := Vector2(0.62, -0.78)
			var lado := Vector2(-eixo.y, eixo.x)
			draw_colored_polygon(PackedVector2Array([
				c + eixo * r, c + eixo * r * 0.2 + lado * r * 0.22,
				c - eixo * r * 0.45 + lado * r * 0.18,
				c - eixo * r * 0.45 - lado * r * 0.18,
				c + eixo * r * 0.2 - lado * r * 0.22]), C_ICONE)
			draw_line(c - eixo * r * 0.4 - lado * r * 0.55,
				c - eixo * r * 0.4 + lado * r * 0.55, C_ICONE, 3.0 * _escala)
			draw_line(c - eixo * r * 0.45, c - eixo * r, C_ICONE, 3.0 * _escala)
		"escudo":
			# escudo "heater": ombros direitos e bico em baixo
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.85, -r * 0.75), c + Vector2(r * 0.85, -r * 0.75),
				c + Vector2(r * 0.75, r * 0.2), c + Vector2(0.0, r),
				c + Vector2(-r * 0.75, r * 0.2)]), C_ICONE)
			draw_line(c + Vector2(0.0, -r * 0.6), c + Vector2(0.0, r * 0.7),
				C_FUNDO, 2.5 * _escala)
		"dash":
			# duplo galao para a frente: e' o simbolo de "mais depressa" que se
			# le^ a esta escala sem legenda nenhuma
			for k in 2:
				var dx := -r * 0.55 + k * r * 0.78
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(dx - r * 0.30, -r * 0.72),
					c + Vector2(dx + r * 0.34, 0.0),
					c + Vector2(dx - r * 0.30, r * 0.72),
					c + Vector2(dx - r * 0.02, r * 0.72),
					c + Vector2(dx + r * 0.62, 0.0),
					c + Vector2(dx - r * 0.02, -r * 0.72)]), C_ICONE)
		"projetil":
			# três orbes em fuga: é o tiro roxo, e lê-se como "à distância"
			for k in 3:
				var f := 1.0 - k * 0.3
				draw_circle(c + Vector2(-r * 0.75 + k * r * 0.75, 0.0),
					r * 0.34 * f, C_ICONE)
