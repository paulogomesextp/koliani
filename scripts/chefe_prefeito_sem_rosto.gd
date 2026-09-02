class_name ChefePrefeitoSemRosto
extends ChefeBase
## Região V / nível 21 -- O Prefeito Sem-Rosto da Vila dos Sem-Rosto.
## Assume a aparência dos outros. Na luta:
##   * DECOYS   -- larga 2-3 cópias idênticas de si que andam pela arena;
##     só o verdadeiro ataca (e, na fase 2, só o verdadeiro NÃO magoa ao
##     toque -- as cópias dão um toque fraco). Ao fim de uns segundos as
##     cópias esvaem-se.
##   * BENGALA  -- avança e dá uma bengalada.
##   * DECRETO  -- atira três decretos (papéis giratórios) em arco.
## Depois de BENGALA / DECRETO ergue o vazio onde estaria a cara
## (EXPOSTO -- dano a dobrar).
## Fase 2 (< 50% vida): mais cópias, cópias magoam ao toque, tudo mais
## rápido.

const DECRETO_VEL := 320.0

enum Fase { DORME, DECIDE, DECOYS_TEL, DECOYS, BENGALA_TEL, BENGALA, DECRETO_TEL, DECRETO, EXPOSTO }

@export var dist_deteta := 600.0
@export var vel_avanco := 170.0
@export var dur_tel := 0.55
@export var dur_exposto := 1.4
@export var dano_bengala := 20
@export var dano_decreto := 14
@export var dur_decoys := 4.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _vida_max := 420
var _chao_cache := 0.0
var _decoys: Array[Node2D] = []

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 660)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _nucleo and _exposto:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	else:
		velocity.y = 0.0
	velocity.x = 0.0

	match _fase:
		Fase.DORME:
			_encarar_koliani()
			if _ve_koliani():
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_encarar_koliani()
			if _t >= 0.3:
				match _ciclos % 3:
					0: _ir(Fase.DECOYS_TEL)
					1: _ir(Fase.BENGALA_TEL)
					_: _ir(Fase.DECRETO_TEL)
		Fase.DECOYS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_largar_decoys()
				_ir(Fase.DECOYS)
		Fase.DECOYS:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO)
		Fase.BENGALA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				Som.toca("investida", -7.0, 0.9)
				_ataque_forte = 0.4
				_ir(Fase.BENGALA)
		Fase.BENGALA:
			velocity.x = _direcao * vel_avanco
			if _t < 0.06:
				_bengalada()
			if _t >= 0.45:
				_ir(Fase.EXPOSTO)
		Fase.DECRETO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_decretos()
				_ir(Fase.DECRETO)
		Fase.DECRETO:
			if _t >= 0.4:
				_ir(Fase.EXPOSTO)
		Fase.EXPOSTO:
			if not _exposto:
				_exposto = true
				_mostrar_nucleo(true)
			if _t >= dur_exposto:
				_exposto = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)

	move_and_slide()
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 320.0


## --- ataques ---------------------------------------------------------

func _bengalada() -> void:
	Som.toca("demonio_ataque", -7.0, 0.9)
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if absf(d.x) <= 90.0 and absf(d.y) <= 74.0 and signf(d.x) == _direcao:
		k.receber_dano(int(round(dano_bengala * (1.1 if _fase2 else 1.0))), _direcao)


func _decretos() -> void:
	Som.toca("projetil", -8.0, 0.9)
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	for i in 3:
		var p := Area2D.new()
		p.collision_layer = 0
		p.collision_mask = 2
		p.global_position = global_position + Vector2(dir * 20.0, -14.0)
		pai.add_child(p)
		var forma := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(20, 16)
		forma.shape = rs
		p.add_child(forma)
		var poly := Polygon2D.new()
		poly.color = Color(0.9, 0.88, 0.78, 0.95)
		poly.polygon = PackedVector2Array([Vector2(-10, -8), Vector2(10, -8), Vector2(10, 8), Vector2(-10, 8)])
		p.add_child(poly)
		var dano := dano_decreto
		p.body_entered.connect(func(b: Node) -> void:
			if b is Koliani:
				b.receber_dano(dano, dir)
			p.queue_free())
		var t := p.create_tween()
		var apex := p.global_position + Vector2(dir * 200.0, -50.0 - i * 20.0)
		t.tween_property(p, "global_position", apex, 200.0 / DECRETO_VEL).set_trans(Tween.TRANS_SINE)
		t.tween_property(p, "global_position", apex + Vector2(dir, 1.2).normalized() * 700.0, 700.0 / DECRETO_VEL)
		t.parallel().tween_method(func(v: float) -> void: poly.rotation = v, 0.0, TAU * 4.0, 900.0 / DECRETO_VEL)
		t.tween_callback(p.queue_free)


func _largar_decoys() -> void:
	Som.toca("invocar", -10.0, 1.5)
	_limpar_decoys()
	var pai := get_parent()
	if pai == null:
		return
	var n := 3 if _fase2 else 2
	for i in n:
		var d := Area2D.new()
		d.collision_layer = 0
		d.collision_mask = 2
		var lado := -1.0 if i % 2 == 0 else 1.0
		var x := global_position.x + lado * (120.0 + i * 60.0)
		d.global_position = Vector2(x, _chao_y(x) - 44.0)
		pai.add_child(d)
		# visual: cópia do sprite do chefe no frame 0
		if _corpo and _corpo.texture:
			var s := Sprite2D.new()
			s.texture = _corpo.texture
			s.hframes = _corpo.hframes
			s.frame = 0
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.modulate = Color(1, 1, 1, 0.92)
			d.add_child(s)
		var forma := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(40, 84)
		forma.shape = rs
		d.add_child(forma)
		if _fase2:
			d.body_entered.connect(func(b: Node) -> void:
				if b is Koliani:
					b.receber_dano(8, signf(b.global_position.x - d.global_position.x)))
		# vaguear
		var t := d.create_tween()
		t.set_loops(int(dur_decoys / 0.9))
		t.tween_property(d, "global_position:x", d.global_position.x + lado * 40.0, 0.9)
		t.tween_property(d, "global_position:x", d.global_position.x - lado * 40.0, 0.9)
		d.get_tree().create_timer(dur_decoys).timeout.connect(func() -> void:
			if is_instance_valid(d):
				var tw := d.create_tween()
				tw.tween_property(d, "modulate:a", 0.0, 0.25)
				tw.tween_callback(d.queue_free))
		_decoys.append(d)


func _limpar_decoys() -> void:
	for d in _decoys:
		if is_instance_valid(d):
			d.queue_free()
	_decoys.clear()


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(7.0)
	dur_tel *= 0.78
	dur_exposto *= 0.88


## --- núcleo / dano -------------------------------------------------

func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposto:
		_corpo.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	_exposto = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _nucleo:
		_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
		var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
		if luz:
			luz.energy = 1.6 if v else 0.12
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposto:
		Som.toca("bloqueio", -9.0, 0.6)
		if _sprite:
			_sprite.modulate = Color(1.2, 1.2, 1.1)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		_raspao(quantidade, dir_empurrao)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao, critico)


func _exit_tree() -> void:
	_limpar_decoys()


## --- utilitários --------------------------------------------------

func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 40.0
	var de := Vector2(x, _origem.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 640.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
