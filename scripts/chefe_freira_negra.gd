class_name ChefeFreiraNegra
extends ChefeBase
## Região IV / nível 18 -- A Freira Negra da Cripta das Mil Velas. Paira
## no escuro, velada. A luz das velas fere-a: só se lhe acerta quando ela
## DESCE à luz de uma vela acesa para a apagar (EXPOSTA, dano a dobrar).
##   * APAGAR       -- desce a uma vela acesa e sopra-a (janela de dano).
##   * VELAS NEGRAS -- atira chamas escuras que perseguem um pouco.
##   * PROCISSAO    -- levanta 2 sombras (DemonioBase lento e escuro).
## Se não houver nenhuma vela acesa faz VELAS NEGRAS e tem uma recuperação
## curta em que também fica EXPOSTA.
## Fase 2 (< 50% vida): apaga mais, mais rápido, e de vez em quando um
## sopro apaga TODAS as velas de uma vez.

const SOMBRA := preload("res://scenes/actors/DemonioBase.tscn")
const CHAMA_VEL := 240.0

enum Fase { DORME, DECIDE, DESCE, APAGA, NEGRAS_TEL, NEGRAS, PROC_TEL, PROC, EXPOSTA, SOBE }

@export var dist_deteta := 620.0
@export var altura_voo := 220.0
@export var dur_tel := 0.6
@export var dur_exposta := 1.4
@export var dano_chama := 15
@export var dano_sombra := 14

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposta := false
var _ciclos := 0
var _vida_max := 380
var _chao_cache := 0.0
var _alvo := Vector2.ZERO
var _vela_alvo: Node = null

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 380)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_alvo = global_position
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 1.8) * (6.0 if not _exposta else 2.0)
	if _nucleo and _exposta:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	global_position = global_position.lerp(_alvo, clampf(dt * 3.0, 0.0, 1.0))
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			_alvo = Vector2(global_position.x, _chao_cache - altura_voo)
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_alvo = Vector2(_x_koliani(), _chao_cache - altura_voo)
			if _t >= 0.3:
				_escolher()
		Fase.DESCE:
			if _vela_alvo == null or not is_instance_valid(_vela_alvo) or not _vela_alvo.acesa:
				_ir(Fase.NEGRAS_TEL)
			else:
				_alvo = (_vela_alvo as Node2D).global_position + Vector2(0, -70)
				_piscar(true)
				if global_position.distance_to(_alvo) < 24.0 and _t >= dur_tel * 0.6:
					_piscar(false)
					_ir(Fase.APAGA)
		Fase.APAGA:
			if not _exposta:
				_exposta = true
				_mostrar_nucleo(true)
			if _t < dt and _vela_alvo and is_instance_valid(_vela_alvo):
				_vela_alvo.apagar()
			if _t >= dur_exposta:
				_exposta = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.SOBE)
		Fase.NEGRAS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_velas_negras()
				_ir(Fase.NEGRAS)
		Fase.NEGRAS:
			if _t >= 0.45:
				_ir(Fase.EXPOSTA)
		Fase.PROC_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_procissao()
				_ir(Fase.PROC)
		Fase.PROC:
			if _t >= 0.5:
				_ir(Fase.EXPOSTA)
		Fase.EXPOSTA:
			_alvo = Vector2(global_position.x, _chao_cache - altura_voo * 0.62)
			if not _exposta:
				_exposta = true
				_mostrar_nucleo(true)
			if _t >= dur_exposta * 0.85:
				_exposta = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.SOBE)
		Fase.SOBE:
			_alvo = Vector2(_x_koliani(), _chao_cache - altura_voo)
			if _t >= 0.3:
				_ir(Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _escolher() -> void:
	if _fase2 and _ciclos % 4 == 3:
		_soprar_tudo()
	match _ciclos % 3:
		0:
			_vela_alvo = _vela_acesa_mais_perto()
			if _vela_alvo:
				_ir(Fase.DESCE)
			else:
				_ir(Fase.NEGRAS_TEL)
		1:
			_ir(Fase.NEGRAS_TEL)
		_:
			_ir(Fase.PROC_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 380.0


func _vela_acesa_mais_perto() -> Node:
	var melhor: Node = null
	var dd := INF
	for v in get_tree().get_nodes_in_group("velas"):
		if not is_instance_valid(v) or not v.acesa:
			continue
		var k := _obter_koliani()
		var ref: Vector2 = k.global_position if k else global_position
		var d: float = (v as Node2D).global_position.distance_to(ref)
		if d < dd:
			dd = d
			melhor = v
	return melhor


## --- ataques ---------------------------------------------------------

func _velas_negras() -> void:
	Som.toca("projetil", -9.0, 0.6)
	var pai := get_parent()
	if pai == null:
		return
	var n := 4 if _fase2 else 3
	var base := _vetor_para_koliani().normalized()
	if base.length() < 0.5:
		base = Vector2(_direcao, 0.2).normalized()
	for i in n:
		_chama_negra(base.rotated((i - (n - 1) * 0.5) * 0.26))


func _chama_negra(dir: Vector2) -> void:
	var pai := get_parent()
	var c := Area2D.new()
	c.collision_layer = 0
	c.collision_mask = 2
	c.global_position = global_position + Vector2(0, 4)
	pai.add_child(c)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 8.0
	forma.shape = cs
	c.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.24, 0.12, 0.32, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-5, 7), Vector2(0, -10), Vector2(5, 7)])
	c.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.5
	luz.color = Color(0.4, 0.2, 0.55)
	luz.scale = Vector2(0.3, 0.3)
	c.add_child(luz)
	var dano := dano_chama
	var k := _obter_koliani()
	var meio := c.global_position + dir * 300.0
	if k:
		meio = meio.lerp(k.global_position, 0.35)
	var fim := meio + (meio - c.global_position).normalized() * 900.0
	c.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, signf(dir.x))
		c.queue_free())
	var t := c.create_tween()
	t.tween_property(c, "global_position", meio, 300.0 / CHAMA_VEL).set_trans(Tween.TRANS_SINE)
	t.tween_property(c, "global_position", fim, 900.0 / CHAMA_VEL)
	t.tween_callback(c.queue_free)


func _procissao() -> void:
	Som.toca("demonio_ataque", -9.0, 0.6)
	var pai := get_parent()
	if pai == null:
		return
	var n := 2 if not _fase2 else 3
	for i in n:
		var s := SOMBRA.instantiate()
		s.especie = "esqueleto"
		s.vida = 22
		s.dano_contacto = dano_sombra
		s.velocidade = 62.0
		s.alcance_patrulha = 340.0
		s.cor_estilhacos = Color(0.3, 0.18, 0.38)
		s.cor_rim = Color(0.5, 0.3, 0.6)
		var x := global_position.x + (i - (n - 1) * 0.5) * 70.0
		s.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(s)
		s.get_tree().create_timer(10.0).timeout.connect(func() -> void:
			if is_instance_valid(s) and not s._morto:
				s.soltar_estilhacos()
				s.queue_free())


func _soprar_tudo() -> void:
	Som.toca("onda", -8.0, 0.6)
	_abanar_camera(5.0)
	for v in get_tree().get_nodes_in_group("velas"):
		if is_instance_valid(v) and v.acesa:
			v.apagar()


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(7.0)
	dur_tel *= 0.75
	dur_exposta *= 0.88


## --- núcleo / dano -------------------------------------------------

func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposta:
		_corpo.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	_exposta = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _nucleo:
		_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
		var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
		if luz:
			luz.energy = 1.7 if v else 0.12
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposta:
		Som.toca("bloqueio", -9.0, 0.7)
		if _sprite:
			_sprite.modulate = Color(1.2, 1.0, 1.3)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 200.0
	var de := Vector2(x, _origem.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 760.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 300.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)


static var _luz_cache: GradientTexture2D

func _tex_luz() -> GradientTexture2D:
	if _luz_cache:
		return _luz_cache
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	_luz_cache = tex
	return tex
