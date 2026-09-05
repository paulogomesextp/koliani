class_name PlacaGravidade
extends Area2D
## A placa que vira o mundo ao contrário. Nível 67, Mundo Invertido.
##
## `modo = "alterna"` -> tocar nela inverte a gravidade dela (cai para
## cima, anda nos tectos). Tocar outra vez desfaz. É isto que faz o "à
## vontade" do guia: não há botão novo no comando -- há botões no CHÃO, e
## ela escolhe quando os pisa.
##
## `modo = "repor"` -> põe-na sempre a direito, aconteça o que acontecer.
## Uma destas fecha a sala: sair do Mundo Invertido de pernas para o ar
## partia o resto da jornada, que é toda desenhada para a gravidade normal.
## É a peça mais importante das duas.
##
## A recarga existe porque a placa é uma área e ela pode ficar em cima
## dela: sem isso o mundo virava a cada frame.
##
## Constrói a própria área e o próprio visual: não precisa de cena.

@export_enum("alterna", "repor") var modo := "alterna"
@export var tamanho := Vector2(90.0, 26.0)
## Segundos antes de a mesma placa voltar a valer.
@export var recarga := 0.8

var _cd := 0.0
var _seta: Polygon2D
var _dentro: Array[Node] = []


func _ready() -> void:
	var col := CollisionShape2D.new()
	var f := RectangleShape2D.new()
	f.size = tamanho
	col.shape = f
	add_child(col)
	monitoring = true
	# a Koliani vive na layer 2 (ver `Armadilha`)
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(c: Node) -> void:
		if not (c in _dentro):
			_dentro.append(c)
		_agir(c))
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c))
	_montar_visual()


func _montar_visual() -> void:
	var h := tamanho * 0.5
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	base.color = Color(0.16, 0.12, 0.26, 0.9) if modo == "alterna" \
		else Color(0.10, 0.20, 0.16, 0.9)
	add_child(base)
	# a seta diz o que a placa faz: duas pontas = vira, uma para baixo =
	# põe a direito. Sem isto era um tapete roxo com poderes secretos.
	_seta = Polygon2D.new()
	var pts := PackedVector2Array([
		Vector2(0.0, -10.0), Vector2(9.0, 0.0), Vector2(3.0, 0.0),
		Vector2(3.0, 10.0), Vector2(-3.0, 10.0), Vector2(-3.0, 0.0),
		Vector2(-9.0, 0.0)])
	_seta.polygon = pts
	_seta.color = Color(1.0, 0.36, 0.92) if modo == "alterna" \
		else Color(0.45, 1.0, 0.72)
	add_child(_seta)
	if modo == "alterna":
		var espelho := Polygon2D.new()
		espelho.polygon = pts
		espelho.color = _seta.color
		espelho.scale.y = -1.0
		espelho.position.y = 0.0
		add_child(espelho)


func _agir(corpo: Node) -> void:
	if _cd > 0.0 or not corpo.has_method("inverter_gravidade"):
		return
	if modo == "repor":
		# só age se ela estiver mesmo ao contrário
		if float(corpo.get("_sinal_grav")) < 0.0:
			corpo.call("inverter_gravidade")
			_cd = recarga
		return
	corpo.call("inverter_gravidade")
	_cd = recarga


func _physics_process(dt: float) -> void:
	_cd = maxf(0.0, _cd - dt)
	if _seta:
		_seta.modulate.a = 0.55 + 0.45 * float(_cd <= 0.0)
	# a de repor insiste: se ela cair aqui já invertida (ou passar sem
	# tocar no `body_entered`), continua a valer enquanto lá estiver
	if modo != "repor" or _cd > 0.0:
		return
	for c in _dentro:
		_agir(c)
