class_name Coletavel
extends Area2D
## Item apanhável no mundo: quando a Koliani lhe toca, desbloqueia uma
## habilidade permanente e desaparece. Por cima flutua a FAIXA "SKILL" --
## placa escura, letras azuis e brilho aditivo (ver `_faixa_skill`).
##
## O sistema de PISTAS foi retirado do jogo a pedido do Paulo (ago 2026):
## um coletável que só dava pista (`habilidade_id` vazio) já nem aparece.
## `pista_id` fica no `@export` só para as cenas antigas não darem erro.
##
## Se a habilidade já foi obtida numa sessão anterior, nem chega a aparecer
## -- evita apanhar duas vezes o mesmo objeto ao reentrar no nível.

signal apanhado(pista_id: String, habilidade_id: String)

## Mantido por compatibilidade com as cenas antigas -- IGNORADO (o Diário
## de pistas saiu do jogo).
@export var pista_id := ""
## Id da habilidade a desbloquear (ex.: "salto_duplo"; vazio = nenhuma).
@export var habilidade_id := ""

## Paleta da faixa "SKILL" (pedido do Paulo, 4 set 2026: "letras a azul e um
## brilho"). O azul é claro de propósito -- os níveis são escuros e o rótulo
## tem de ler contra o roxo do cenário.
const COR_LETRAS := Color(0.4, 0.72, 1.0)
const COR_BORDA := Color(0.26, 0.58, 1.0)
const COR_BRILHO := Color(0.18, 0.46, 1.0, 0.34)
## ... e a luz do coletável acompanha-a, para o halo no chão não ficar de
## outra cor que a placa.
const COR_LUZ := Color(0.38, 0.66, 1.0)

@onready var _visual: Node2D = $Visual
@onready var _luz: PointLight2D = $Luz

var _t := 0.0


func _ready() -> void:
	if _ja_obtido():
		queue_free()
		return
	body_entered.connect(_ao_entrar)
	_montar_visual()


## Verdadeiro se este coletável não tem NADA de novo para dar. Sem
## habilidade a desbloquear (ex.: era só uma pista) -> nunca aparece.
func _ja_obtido() -> bool:
	if habilidade_id == "":
		return true
	return EstadoJogo.tem_habilidade(habilidade_id)


# --- visual ---------------------------------------------------------

func _montar_visual() -> void:
	if _visual == null:
		return
	for c in _visual.get_children():
		c.queue_free()
	_faixa_skill()
	_pintar_luz(COR_LUZ, 1.9)


func _pintar_luz(cor: Color, energia: float) -> void:
	if _luz:
		_luz.color = cor
		_luz.energy = energia


func _poly(pts: PackedVector2Array, cor: Color, z := 0) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = cor
	p.z_index = z
	_visual.add_child(p)
	return p


## Gema do coletável mais a faixa brilhante a dizer "SKILL" por cima.
##
## A faixa chegou a sair (2 set 2026: o Paulo achou que lia como uma caixa
## solta em cima das plataformas), mas ele pediu-a de volta "como estava
## inicialmente, letras a azul e um brilho" (4 set 2026) -- é a mesma placa,
## com a paleta passada de verde-água para AZUL.
func _faixa_skill() -> void:
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	# gema pequena na base -- dá "corpo" ao coletável ao nível do chão
	var gema := PackedVector2Array([
		Vector2(0, -6), Vector2(5, 2), Vector2(0, 9), Vector2(-5, 2)])
	_poly(gema, Color(0.05, 0.08, 0.16), 0)
	var gema_in := PackedVector2Array()
	for v in gema:
		gema_in.append(v * 0.66)
	_poly(gema_in, Color(0.72, 0.88, 1.0), 1)

	# faixa / estandarte
	var faixa := Node2D.new()
	faixa.name = "Faixa"
	faixa.position = Vector2(0, -30)
	_visual.add_child(faixa)

	# o brilho é aditivo: acende mesmo por cima do cenário escuro em vez de
	# ficar uma mancha de tinta
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-34, -14), Vector2(34, -14), Vector2(40, 0), Vector2(34, 14),
		Vector2(-34, 14), Vector2(-40, 0)])
	glow.color = COR_BRILHO
	glow.material = aditivo
	faixa.add_child(glow)

	var placa := Polygon2D.new()
	placa.polygon = PackedVector2Array([
		Vector2(-30, -11), Vector2(30, -11), Vector2(36, 0), Vector2(30, 11),
		Vector2(-30, 11), Vector2(-36, 0)])
	placa.color = Color(0.05, 0.06, 0.14, 0.92)
	faixa.add_child(placa)
	var borda := Line2D.new()
	borda.points = placa.polygon
	borda.closed = true
	borda.width = 2.0
	borda.default_color = COR_BORDA
	faixa.add_child(borda)

	var lbl := Label.new()
	lbl.text = "SKILL"
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", COR_LETRAS)
	lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.1))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(72, 24)
	lbl.position = Vector2(-36, -13)
	faixa.add_child(lbl)


func _process(dt: float) -> void:
	_t += dt
	if _visual:
		_visual.position.y = sin(_t * 2.4) * 4.0
		var s := 1.0 + 0.06 * sin(_t * 4.0)
		_visual.scale = Vector2(s, s)
	if _luz:
		_luz.energy = 1.9 * (0.85 + 0.15 * sin(_t * 5.0))
	var faixa := _visual.get_node_or_null("Faixa") if _visual else null
	if faixa:
		faixa.scale = Vector2.ONE * (1.0 + 0.05 * sin(_t * 4.0))


func _ao_entrar(corpo: Node) -> void:
	if not (corpo is Koliani):
		return
	if habilidade_id != "":
		EstadoJogo.desbloquear_habilidade(habilidade_id)
	Som.toca("apanhar", -6.0)
	apanhado.emit(pista_id, habilidade_id)
	queue_free()
