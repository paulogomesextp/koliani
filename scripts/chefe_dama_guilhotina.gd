class_name ChefeDamaGuilhotina
extends ChefeBase
## Região II / nível 08 -- A Dama da Guilhotina. Executora fantasma que
## paira no Corredor das Execuções. Não anda: TELEPORTA-SE (esvai-se e
## reaparece noutro ponto do corredor, a uma distância segura da Koliani).
## Três ataques:
##   * LAMINAS    -- arremessa 2-3 lâminas giratórias que voam na horizontal
##                   à altura da Koliani.
##   * GUILHOTINAS-- faz cair várias `Guilhotina` do grupo "guilhotinas_arena"
##                   ao mesmo tempo (cada uma com o seu atraso).
##   * CORTE      -- teleporta-se para cima da Koliani e baixa a lâmina num
##                   arco rasteiro (dano ao chão à frente).
## Depois de cada ataque MATERIALIZA-SE por instantes (estado EXPOSTA): o
## manto solidifica, o crânio fica à vista -- única janela de dano, a
## dobrar. Fora disso é etérea e as lâminas da Koliani atravessam-na.
## Fase 2 (< 50% vida): "arena quase toda vertical" -- sobe as plataformas
## do grupo "plataformas_execucoes", teleporta-se mais, telégrafos curtos,
## mais lâminas.

enum Fase { DORME, DECIDE, SOME, SURGE, LAMINAS_TEL, LAMINAS, GUILHO_TEL, GUILHO, CORTE_TEL, CORTE, EXPOSTA }

@export var dist_deteta := 520.0
@export var altura_voo := 150.0
@export var dur_tel := 0.6
@export var dur_some := 0.28
@export var dur_exposta := 1.45
@export var dur_corte := 0.4
@export var dano_lamina := 16
@export var dano_corte := 22
@export var vel_lamina := 430.0
## Meia-largura do corredor onde ela pode reaparecer (relativa à origem).
@export var alcance_teleporte := 360.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposta := false
var _ciclos := 0
var _vida_max := 340
var _chao_cache := 0.0
var _fase_pos_teleporte: Fase = Fase.LAMINAS_TEL

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 340)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		var amp := 6.0 if not _exposta else 2.0
		_sprite.position.y = sin(_pulso * 2.4) * amp
	if _nucleo and _exposta:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			if _t >= 0.3:
				_escolher()
		Fase.SOME:
			if _t < dt:
				_esvair(true)
			if _t >= dur_some:
				_teleportar()
				_ir(Fase.SURGE)
		Fase.SURGE:
			if _t < dt:
				_esvair(false)
			if _t >= dur_some:
				_ir(_fase_pos_teleporte)
		Fase.LAMINAS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_lancar_laminas()
				_ir(Fase.LAMINAS)
		Fase.LAMINAS:
			if _t >= 0.45:
				_ir(Fase.EXPOSTA)
		Fase.GUILHO_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_cair_guilhotinas()
				_ir(Fase.GUILHO)
		Fase.GUILHO:
			if _t >= 0.6:
				_ir(Fase.EXPOSTA)
		Fase.CORTE_TEL:
			_piscar(true)
			if _t >= dur_tel * 0.8:
				_piscar(false)
				_corte()
				_ir(Fase.CORTE)
		Fase.CORTE:
			if _t >= dur_corte:
				_ir(Fase.EXPOSTA)
		Fase.EXPOSTA:
			if not _exposta:
				_exposta = true
				_mostrar_nucleo(true)
			if _t >= dur_exposta:
				_exposta = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


## Escolhe o próximo ataque e passa sempre por um teleporte antes.
func _escolher() -> void:
	var op := _ciclos % 3
	if _fase2 and _ciclos % 4 == 3:
		op = 1  # repete guilhotinas na fase 2
	match op:
		0: _fase_pos_teleporte = Fase.LAMINAS_TEL
		1: _fase_pos_teleporte = Fase.GUILHO_TEL
		_: _fase_pos_teleporte = Fase.CORTE_TEL
	_ir(Fase.SOME)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 320.0


## --- teleporte -------------------------------------------------------

func _esvair(a_sair: bool) -> void:
	Som.toca("projetil", -12.0, 0.5 if a_sair else 0.8)
	if _sprite == null:
		return
	var alvo := 0.15 if a_sair else 1.0
	create_tween().tween_property(_sprite, "modulate:a", alvo, dur_some * 0.9)


func _teleportar() -> void:
	var alvo_x := _x_koliani()
	var lado := -1.0 if randf() < 0.5 else 1.0
	# ao ir para o CORTE, cai por cima da Koliani; senão, mantém distância
	var afasta := 40.0 if _fase_pos_teleporte == Fase.CORTE_TEL else randf_range(180.0, 300.0)
	var x := clampf(alvo_x + lado * afasta, _origem.x - alcance_teleporte, _origem.x + alcance_teleporte)
	_chao_cache = _chao_y(x)
	global_position = Vector2(x, _chao_cache - altura_voo)
	_encarar_koliani()


## --- ataques ---------------------------------------------------------

func _lancar_laminas() -> void:
	Som.toca("investida", -8.0, 1.3)
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var n := 3 if _fase2 else 2
	var k := _obter_koliani()
	var alvo_y := k.global_position.y - 12.0 if k else global_position.y
	for i in n:
		var y := alvo_y + (i - (n - 1) * 0.5) * 26.0
		_lamina(dir, y, i * 0.12)


func _lamina(dir: float, y: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var lam := Area2D.new()
	lam.collision_layer = 0
	lam.collision_mask = 2
	lam.monitoring = false
	lam.global_position = Vector2(global_position.x + dir * 20.0, y)
	pai.add_child(lam)

	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(30, 10)
	forma.shape = rs
	lam.add_child(forma)

	var poly := Polygon2D.new()
	poly.color = Color(0.62, 0.68, 0.82, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(0, -8), Vector2(16, 0), Vector2(0, 8)])
	lam.add_child(poly)

	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.6
	luz.color = Color(0.7, 0.85, 1.0)
	luz.scale = Vector2(0.4, 0.35)
	lam.add_child(luz)

	var dano := int(round(dano_lamina * (1.15 if _fase2 else 1.0)))
	lam.body_entered.connect(func(corpo: Node) -> void:
		if corpo is Koliani:
			corpo.receber_dano(dano, dir))

	var t := lam.create_tween()
	t.tween_interval(atraso)
	t.tween_callback(func() -> void: lam.monitoring = true)
	t.tween_property(lam, "global_position:x", global_position.x + dir * 1500.0, 1500.0 / vel_lamina)
	t.parallel().tween_method(func(v: float) -> void: poly.rotation = v, 0.0, TAU * 7.0, 1500.0 / vel_lamina)
	t.tween_callback(lam.queue_free)


func _cair_guilhotinas() -> void:
	Som.toca("onda", -6.0, 0.8)
	_abanar_camera(4.0)
	var gs := get_tree().get_nodes_in_group("guilhotinas_arena")
	var i := 0
	for g in gs:
		if is_instance_valid(g) and g.has_method("cair"):
			var atraso := 0.1 + (i % 4) * (0.12 if _fase2 else 0.22)
			g.cair(atraso)
			i += 1


func _corte() -> void:
	Som.toca("investida", -6.0, 0.7)
	_abanar_camera(3.0)
	var dir := _dir_para_koliani()
	var pai := get_parent()
	if pai == null:
		return
	var golpe := Area2D.new()
	golpe.collision_layer = 0
	golpe.collision_mask = 2
	golpe.global_position = global_position + Vector2(dir * 46.0, altura_voo - 20.0)
	pai.add_child(golpe)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(96, 40)
	forma.shape = rs
	golpe.add_child(forma)
	var arco := Polygon2D.new()
	arco.color = Color(0.75, 0.85, 1.0, 0.5)
	arco.polygon = PackedVector2Array([Vector2(-48, 14), Vector2(48, 14), Vector2(40, -14), Vector2(-40, -6)])
	golpe.add_child(arco)
	var dano := int(round(dano_corte * (1.15 if _fase2 else 1.0)))
	golpe.body_entered.connect(func(corpo: Node) -> void:
		if corpo is Koliani:
			corpo.receber_dano(dano, dir))
	var t := golpe.create_tween()
	t.tween_callback(func() -> void:
		for c in golpe.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(dano, dir))
	t.tween_property(arco, "modulate:a", 0.0, 0.28)
	t.tween_callback(golpe.queue_free)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -9.0, 0.7)
	_abanar_camera(7.0)
	dur_tel *= 0.72
	dur_exposta *= 0.85
	# "arena quase toda vertical": as plataformas do grupo sobem de nível.
	for p in get_tree().get_nodes_in_group("plataformas_execucoes"):
		if not is_instance_valid(p):
			continue
		var tw := (p as Node).create_tween()
		tw.tween_property(p, "position:y", (p as Node2D).position.y - 130.0, 1.4).set_trans(Tween.TRANS_SINE)


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
	if _sprite:
		_sprite.modulate.a = 1.0
	if _nucleo == null:
		return
	_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
	var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
	if luz:
		luz.energy = 1.6 if v else 0.12
	var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
	if brilho:
		brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposta:
		Som.toca("bloqueio", -9.0, 0.8)
		if _sprite:
			_sprite.modulate = Color(0.7, 0.85, 1.0, _sprite.modulate.a)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1, _sprite.modulate.a), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 40.0
	var de := Vector2(x, _origem.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 520.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 40.0


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
