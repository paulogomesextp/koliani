class_name CorrenteAr
extends Area2D
## Corrente de ar ascendente da Torre dos Ventos (Região III / nível 12).
## Enquanto a Koliani está lá dentro, é empurrada para cima até uma
## velocidade-alvo (`Koliani.soprar_para_cima`) -- serve para alcançar
## plataformas suspensas altas. Mecânica partilhada e reutilizável.

@export var forca := 3200.0
@export var vel_alvo := 520.0
## Tamanho da coluna (px). `Vector2.ZERO` = o da cena (260x340), que e' o que
## todos os niveis antigos usam. A `RectangleShape2D` da cena e' PARTILHADA
## entre instancias -- por isso duplica-se antes de mexer (a mesma armadilha
## que as `WindZone` ja' tiveram, ver `tests/run_region02_wind_shapes.tscn`).
@export var tamanho := Vector2.ZERO

@onready var _poeira: CPUParticles2D = get_node_or_null("Poeira")

var _dentro: Array[Node] = []


func _ready() -> void:
	add_to_group("correntes_ar")
	if tamanho != Vector2.ZERO:
		_redimensionar()
	body_entered.connect(func(c: Node) -> void:
		if c is Koliani and c not in _dentro:
			_dentro.append(c))
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c))


func _physics_process(_dt: float) -> void:
	for k in _dentro:
		if is_instance_valid(k) and k.has_method("soprar_para_cima"):
			k.soprar_para_cima(forca, vel_alvo)


func _redimensionar() -> void:
	var h := tamanho * 0.5
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		var r := RectangleShape2D.new()
		r.size = tamanho
		col.shape = r
	var fundo := get_node_or_null("Fundo") as ColorRect
	if fundo:
		fundo.offset_left = -h.x
		fundo.offset_top = -h.y
		fundo.offset_right = h.x
		fundo.offset_bottom = h.y
	var cont := get_node_or_null("Contorno") as Line2D
	if cont:
		cont.points = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y),
			Vector2(h.x, h.y), Vector2(-h.x, h.y), Vector2(-h.x, -h.y)])
	if _poeira:
		_poeira.emission_rect_extents = Vector2(maxf(4.0, h.x - 6.0), maxf(4.0, h.y - 4.0))
		# mais coluna = mais poeira, para a densidade a' vista ficar igual
		_poeira.amount = clampi(int(36.0 * tamanho.x * tamanho.y / (260.0 * 340.0)), 12, 120)
