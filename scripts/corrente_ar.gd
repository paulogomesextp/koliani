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
## Opt-in: pele pintada da coluna (aneis de vento da prancha) em mosaico
## vertical, a subir. Esconde o retangulo/contorno de placeholder. Os niveis
## que nao a definem nao mudam.
@export var pele: Texture2D
@export var vel_pele := 90.0

var _pele_spr: Sprite2D

@onready var _poeira: CPUParticles2D = get_node_or_null("Poeira")

var _dentro: Array[Node] = []


func _ready() -> void:
	add_to_group("correntes_ar")
	if tamanho != Vector2.ZERO:
		_redimensionar()
	if pele:
		_vestir_pele()
	body_entered.connect(func(c: Node) -> void:
		if c is Koliani and c not in _dentro:
			_dentro.append(c))
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c))


func _vestir_pele() -> void:
	var fundo := get_node_or_null("Fundo") as CanvasItem
	if fundo:
		fundo.modulate.a = 0.35
	var cont := get_node_or_null("Contorno") as CanvasItem
	if cont:
		cont.visible = false
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var tam: Vector2 = tamanho
	if tam == Vector2.ZERO and col and col.shape is RectangleShape2D:
		tam = (col.shape as RectangleShape2D).size
	var esc := tam.x / float(pele.get_width())
	_pele_spr = Sprite2D.new()
	_pele_spr.name = "Pele"
	_pele_spr.texture = pele
	_pele_spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_pele_spr.region_enabled = true
	_pele_spr.region_rect = Rect2(0.0, 0.0, float(pele.get_width()), tam.y / esc)
	_pele_spr.scale = Vector2(esc, esc)
	_pele_spr.modulate = Color(1.0, 1.0, 1.0, 0.85)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_pele_spr.material = m
	add_child(_pele_spr)


func _process(dt: float) -> void:
	if _pele_spr:
		# os aneis sobem: desliza a janela do mosaico para baixo
		var r := _pele_spr.region_rect
		r.position.y = fposmod(r.position.y + vel_pele * dt / _pele_spr.scale.y, float(pele.get_height()))
		_pele_spr.region_rect = r


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
