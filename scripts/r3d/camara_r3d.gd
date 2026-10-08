class_name CamaraR3D
extends Camera3D
## Camara de jogo 3D da Koliani: terceira pessoa ORIENTADA PELA ROTA do nivel
## (estilo plataformas 3D lineares). A direcao olha sempre "para a frente" do
## percurso desenhado, a 3/4, por isso o jogador nunca tem de gerir a camara
## para ler os saltos. Opcional: orbita manual (rato com botao direito /
## analogico direito) que regressa sozinha. Na arena do chefe enquadra
## Koliani + chefe. Evita paredes com um raio de colisao.

var alvo: Node3D
var rota := PackedVector3Array()
var lado := 1.0
var dist := 7.2
var altura := 3.3
var lateral := 1.5
var foco: Node3D
var _comp := PackedFloat32Array()
var _dir := Vector3.FORWARD
var _y_ref := 0.0
var _pos := Vector3.ZERO
var _abano := 0.0
var _orbita := 0.0
var _orbita_t := 0.0
var _arrastar := false
var _iniciada := false
var _recuo := 1.0


func _ready() -> void:
	fov = 55.0
	near = 0.1
	far = 400.0
	current = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_medir()


func _medir() -> void:
	_comp = PackedFloat32Array([0.0])
	for i in range(1, rota.size()):
		_comp.append(_comp[i - 1] + Vector2(rota[i].x - rota[i - 1].x, rota[i].z - rota[i - 1].z).length())


func definir_rota(r: PackedVector3Array) -> void:
	rota = r
	_medir()


func abanar(f: float) -> void:
	_abano = maxf(_abano, f)


func cortar() -> void:
	_iniciada = false


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT:
		_arrastar = ev.pressed
	elif ev is InputEventMouseMotion and _arrastar:
		_orbita = clampf(_orbita - ev.relative.x * 0.006, -1.4, 1.4)
		_orbita_t = 2.0


## Ponto da rota mais proximo (em XZ) -> distancia ao longo da rota.
func _s_mais_proximo(p: Vector3) -> float:
	var melhor := INF
	var s := 0.0
	var q := Vector2(p.x, p.z)
	for i in rota.size() - 1:
		var a := Vector2(rota[i].x, rota[i].z)
		var b := Vector2(rota[i + 1].x, rota[i + 1].z)
		var ab := b - a
		var t := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var d := q.distance_squared_to(a + ab * t)
		# preferir segmentos a altura parecida (rotas que se cruzam por cima)
		var dy := absf(p.y - lerpf(rota[i].y, rota[i + 1].y, t))
		d += dy * dy * 0.25
		if d < melhor:
			melhor = d
			s = _comp[i] + ab.length() * t
	return s


func _ponto_em(s: float) -> Vector3:
	s = clampf(s, 0.0, _comp[_comp.size() - 1])
	for i in rota.size() - 1:
		if s <= _comp[i + 1] or i == rota.size() - 2:
			var seg := maxf(_comp[i + 1] - _comp[i], 0.0001)
			return rota[i].lerp(rota[i + 1], clampf((s - _comp[i]) / seg, 0.0, 1.0))
	return rota[rota.size() - 1]


func _process(dt: float) -> void:
	if alvo == null or not is_instance_valid(alvo):
		return
	var tp := alvo.get_global_transform_interpolated().origin
	var dir := _dir
	var d_dist := dist
	var d_alt := altura
	var d_lat := lateral * lado
	var olhar_extra := 2.0
	if foco and is_instance_valid(foco) and foco.is_inside_tree():
		var f := foco.global_position - tp
		f.y = 0.0
		if f.length() > 1.0:
			dir = f.normalized()
		d_dist = 8.6
		d_alt = 4.6
		d_lat = 1.2 * lado
		olhar_extra = minf(f.length() * 0.35, 4.0)
	elif rota.size() >= 2:
		var s := _s_mais_proximo(tp)
		var frente := _ponto_em(s + 5.0) - _ponto_em(s - 3.0)
		frente.y = 0.0
		if frente.length() > 0.1:
			dir = frente.normalized()
	# orbita manual (rato/analogico) que volta a zero
	var jx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if absf(jx) > 0.2:
		_orbita = clampf(_orbita - jx * 2.0 * dt, -1.4, 1.4)
		_orbita_t = 2.0
	_orbita_t -= dt
	if _orbita_t <= 0.0:
		_orbita = lerpf(_orbita, 0.0, clampf(dt * 1.5, 0.0, 1.0))
	dir = dir.rotated(Vector3.UP, _orbita)
	if not _iniciada:
		_dir = dir
		_y_ref = tp.y
	_dir = _dir.slerp(dir, clampf(dt * 2.6, 0.0, 1.0)).normalized()
	# vertical preguicosa: segue firme no chao, solta no ar (menos enjoo)
	var no_chao: bool = alvo.is_on_floor() if alvo.has_method("is_on_floor") else true
	var rate := 6.0 if no_chao else 1.2
	if tp.y < _y_ref - 1.6:
		rate = 7.0
	_y_ref = lerpf(_y_ref, tp.y, clampf(dt * rate, 0.0, 1.0))
	var direita := _dir.cross(Vector3.UP).normalized()
	var base := Vector3(tp.x, _y_ref, tp.z)
	var olho := base + Vector3.UP * 1.25 + _dir * olhar_extra
	var desejo := base - _dir * d_dist + direita * d_lat + Vector3.UP * d_alt
	# colisao camara-mundo
	var origem := base + Vector3.UP * 1.4
	var mundo := get_world_3d().direct_space_state
	# esfera a varrer (nao so' um raio): troncos e ruinas nunca tapam a Koliani
	var esfera := SphereShape3D.new()
	esfera.radius = 0.45
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = esfera
	q.collision_mask = 1 | 16
	q.transform = Transform3D(Basis(), origem)
	q.motion = desejo - origem
	var fr := mundo.cast_motion(q)
	var alvo_recuo := 1.0
	if fr.size() == 2 and fr[0] < 1.0:
		alvo_recuo = clampf(fr[0] - 0.02, 0.22, 1.0)
	_recuo = lerpf(_recuo, alvo_recuo, clampf(dt * (12.0 if alvo_recuo < _recuo else 2.5), 0.0, 1.0))
	desejo = origem.lerp(desejo, _recuo)
	if not _iniciada:
		_pos = desejo
		_iniciada = true
	_pos = _pos.lerp(desejo, clampf(dt * 7.0, 0.0, 1.0))
	var tremor := Vector3.ZERO
	if _abano > 0.0:
		_abano = maxf(_abano - dt * 0.9, 0.0)
		tremor = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _abano * 0.35
	global_position = _pos + tremor
	look_at(olho + tremor * 0.5, Vector3.UP)
