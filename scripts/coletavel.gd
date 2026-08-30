class_name Coletavel
extends Area2D
## Item apanhável no mundo: quando a Koliani lhe toca, regista uma pista
## sobre a mãe e/ou desbloqueia uma habilidade permanente, e desaparece.
##
## Visual construído em código conforme o que dá:
##   * habilidade nova -> SETA PARA CIMA brilhante (upgrade).
##   * pista / dica     -> LÂMPADA brilhante.
##
## Se já tinha sido apanhado numa sessão anterior (a pista/habilidade já
## está em `EstadoJogo`), nem chega a aparecer -- evita apanhar duas vezes
## o mesmo objeto ao voltar a entrar no nível.

signal apanhado(pista_id: String, habilidade_id: String)

## Id da pista a registar (vazio = não regista pista).
@export var pista_id := ""
## Id da habilidade a desbloquear (ex.: "salto_duplo"; vazio = nenhuma).
@export var habilidade_id := ""

@onready var _visual: Node2D = $Visual
@onready var _luz: PointLight2D = $Luz

var _t := 0.0


func _ready() -> void:
	if _ja_obtido():
		queue_free()
		return
	body_entered.connect(_ao_entrar)
	_montar_visual()


## Verdadeiro só se este coletável não tem nada de novo para dar.
func _ja_obtido() -> bool:
	var falta_pista := pista_id != "" and not EstadoJogo.pistas.has(pista_id)
	var falta_habilidade := habilidade_id != "" and not EstadoJogo.tem_habilidade(habilidade_id)
	if falta_pista or falta_habilidade:
		return false
	# nada por dar (ou o coletável está mal configurado, sem ids)
	return true


# --- visual ---------------------------------------------------------

func _montar_visual() -> void:
	if _visual == null:
		return
	for c in _visual.get_children():
		c.queue_free()
	if habilidade_id != "":
		_seta_upgrade()
		_pintar_luz(Color(0.55, 1.0, 0.85), 1.7)
	else:
		_lampada()
		_pintar_luz(Color(1.0, 0.88, 0.45), 1.35)


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


## Seta grossa a apontar para cima (upgrade).
func _seta_upgrade() -> void:
	var contorno := PackedVector2Array([
		Vector2(0, -14), Vector2(10, -1), Vector2(4.5, -1), Vector2(4.5, 13),
		Vector2(-4.5, 13), Vector2(-4.5, -1), Vector2(-10, -1),
	])
	_poly(contorno, Color(0.05, 0.12, 0.10), 0)
	var dentro := PackedVector2Array()
	for v in contorno:
		dentro.append(v * 0.72)
	_poly(dentro, Color(0.6, 1.0, 0.85), 1)
	_poly(PackedVector2Array([Vector2(0, -9), Vector2(3.5, -3), Vector2(-3.5, -3)]),
		Color(0.95, 1.0, 0.98), 2)


## Lâmpada (pista / dica).
func _lampada() -> void:
	var bulbo := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		bulbo.append(Vector2(cos(a) * 9.0, sin(a) * 9.0 - 3.0))
	_poly(bulbo, Color(0.05, 0.05, 0.03), 0)
	var bulbo_in := PackedVector2Array()
	for v in bulbo:
		bulbo_in.append(v * 0.82 + Vector2(0, -0.5))
	_poly(bulbo_in, Color(1.0, 0.92, 0.55), 1)
	# rosca / base
	_poly(PackedVector2Array([
		Vector2(-4, 5), Vector2(4, 5), Vector2(3.5, 10), Vector2(-3.5, 10),
	]), Color(0.7, 0.62, 0.4), 1)
	_poly(PackedVector2Array([
		Vector2(-3, 10), Vector2(3, 10), Vector2(2.5, 13), Vector2(-2.5, 13),
	]), Color(0.45, 0.4, 0.28), 1)
	# brilho
	_poly(PackedVector2Array([
		Vector2(-3, -6), Vector2(1, -8), Vector2(-1, -2), Vector2(-4, -1),
	]), Color(1.0, 1.0, 0.9), 2)


func _process(dt: float) -> void:
	_t += dt
	if _visual:
		_visual.position.y = sin(_t * 2.4) * 4.0
		var s := 1.0 + 0.06 * sin(_t * 4.0)
		_visual.scale = Vector2(s, s)
	if _luz:
		_luz.energy = (1.7 if habilidade_id != "" else 1.35) * (0.85 + 0.15 * sin(_t * 5.0))


func _ao_entrar(corpo: Node) -> void:
	if not (corpo is Koliani):
		return
	var pista_nova := pista_id != "" and not EstadoJogo.pistas.has(pista_id)
	if pista_id != "":
		EstadoJogo.registar_pista(pista_id)
	if habilidade_id != "":
		EstadoJogo.desbloquear_habilidade(habilidade_id)
	Som.toca("apanhar", -6.0)
	apanhado.emit(pista_id, habilidade_id)
	# pista nova -> mostra o texto num balão de fala (como os chefes-história):
	# o título da pista é "quem fala", o corpo é o texto.
	if pista_nova and DiarioPistas.PISTAS.has(pista_id):
		var p: Dictionary = DiarioPistas.PISTAS[pista_id]
		Dialogo.correr([{ "quem": p["titulo"], "texto": p["texto"] }])
	queue_free()
