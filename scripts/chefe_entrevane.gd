class_name ChefeEntrevane
extends ChefeBase
## Região I / nível 04 -- Entrevane, a Árvore Amaldiçoada. Uma árvore
## gigante com vários rostos que choram seiva ácida. Quase não se desloca
## (está enraizada); dobra o tronco para atacar de três formas:
##   * GALHO    -- telegrafa e faz um galho varrer na horizontal ao nível
##                 da Koliani (na fase 2 são dois: um alto e um rasteiro).
##   * LÁGRIMAS -- chora: larga uma cortina de `GotaAcida` por cima da
##                 Koliani (poças ácidas no chão onde caem).
##   * RAÍZES   -- raízes irrompem sob os pés da Koliani (`RaizPerigo`).
## Depois de cada ataque um dos rostos abre-se a chorar (nó `Nucleo`): é a
## ÚNICA janela em que leva dano -- e a dobrar. Fora disso a casca aguenta.
## Fase 2 (< 50% vida): telégrafos curtos, goteja sem parar, mais raízes, e
## parte um par de plataformas do tronco (grupo "plataformas_arvore").

const RAIZ := preload("res://scenes/actors/RaizPerigo.tscn")
const GOTA := preload("res://scenes/actors/GotaAcida.tscn")

enum Fase { DORME, DECIDE, GALHO_TEL, GALHO, LAGRIMAS_TEL, LAGRIMAS, RAIZES_TEL, RAIZES, EXPOSTA }

@export var dist_deteta := 460.0
@export var dur_tel := 0.62
@export var dur_galho := 0.6
@export var dur_exposta := 1.4
@export var vel_galho := 620.0
@export var dano_galho := 20
@export var dano_raiz := 18
@export var dano_gota := 16

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _sway := 0.0
var _fase2 := false
var _nucleo_exposto := false
var _ciclos := 0
var _vida_max := 400
## Conta-decrescente para o gotejar contínuo da fase 2.
var _t_pingo := 0.0
## Y do chão da arena por baixo da Entrevane (raycast uma vez -- ela não
## anda). Serve para pousar galhos/raízes/lágrimas.
var _chao_cache := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 320)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0  # enraizada: não patrulha
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_sway += dt
	if _sprite and _fase != Fase.GALHO:
		# baloiço lento de tronco ao vento (somado ao recuo de dano do super)
		var amp := 0.03 if not _fase2 else 0.05
		_sprite.rotation += sin(_sway * 1.3) * amp
	if _nucleo and _nucleo_exposto:
		_pulso += dt
		var p := 1.0 + 0.16 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	# gotejar contínuo na fase 2 (perigo de fundo, fora da máquina de ataques)
	if _fase2:
		_pingo_ocasional(dt)

	match _fase:
		Fase.DORME:
			# assenta no chão uma vez (não volta a mexer-se depois)
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
				move_and_slide()
			if _ve_koliani():
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_encarar_koliani()
			if _t >= 0.3:
				_escolher()
		Fase.GALHO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_varrer_galho()
				_ir(Fase.GALHO)
		Fase.GALHO:
			if _t >= dur_galho:
				_ir(Fase.EXPOSTA)
		Fase.LAGRIMAS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_chorar()
				_ir(Fase.LAGRIMAS)
		Fase.LAGRIMAS:
			if _t >= 0.5:
				_ir(Fase.EXPOSTA)
		Fase.RAIZES_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_raizes()
				_ir(Fase.EXPOSTA)
		Fase.EXPOSTA:
			if not _nucleo_exposto:
				_mostrar_nucleo(true)
			if _t >= dur_exposta:
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _escolher() -> void:
	# roda entre os três ataques; na fase 2 chora mais vezes
	var op := _ciclos % 3
	if _fase2 and _ciclos % 4 == 3:
		op = 1
	match op:
		0: _ir(Fase.GALHO_TEL)
		1: _ir(Fase.LAGRIMAS_TEL)
		_: _ir(Fase.RAIZES_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 260.0


## --- ataques ---------------------------------------------------------

func _varrer_galho() -> void:
	Som.toca("golpe_pesado", -8.0, 0.9)
	_abanar_camera(3.0)
	var k := _obter_koliani()
	var alturas := [-40.0]
	if _fase2:
		alturas = [-96.0, -14.0]
	for a in alturas:
		var y_alvo: float = k.global_position.y + a if k else _chao_cache - 60.0
		_lancar_galho(y_alvo)


func _lancar_galho(y: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var galho := Area2D.new()
	galho.collision_layer = 0
	galho.collision_mask = 2
	galho.global_position = Vector2(global_position.x + dir * 40.0, y)
	pai.add_child(galho)

	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(120, 24)
	forma.shape = rs
	galho.add_child(forma)

	var braco := Polygon2D.new()
	braco.color = Color(0.16, 0.12, 0.08, 1.0)
	braco.polygon = PackedVector2Array([
		Vector2(-60, -6), Vector2(40, -10), Vector2(60, -2),
		Vector2(40, 8), Vector2(-60, 6),
	])
	braco.scale.x = dir
	galho.add_child(braco)

	var espinhos := Line2D.new()
	espinhos.points = PackedVector2Array([Vector2(-40, -8), Vector2(-20, -14), Vector2(0, -9), Vector2(24, -13)])
	espinhos.width = 3.0
	espinhos.default_color = Color(0.5, 0.6, 0.25, 0.9)
	braco.add_child(espinhos)

	var dano := int(round(dano_galho * (1.15 if _fase2 else 1.0)))
	galho.body_entered.connect(func(corpo: Node) -> void:
		if corpo is Koliani:
			corpo.receber_dano(dano, dir))

	var destino := global_position.x + dir * 1500.0
	var t := galho.create_tween()
	t.tween_property(galho, "global_position:x", destino, 1500.0 / vel_galho) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(braco, "modulate:a", 0.0, 1500.0 / vel_galho)
	t.tween_callback(galho.queue_free)


func _chorar() -> void:
	Som.toca("grito", -12.0, 0.8)
	var n := 5 if _fase2 else 3
	var alvo := _x_koliani()
	for i in n:
		var x := alvo + (i - (n - 1) * 0.5) * 90.0 + randf_range(-18.0, 18.0)
		_gota_em(x, -180.0, 0.1 + i * 0.14)


func _gota_em(x: float, dy: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var g := GOTA.instantiate()
	g.automatico = false
	g.dano = dano_gota
	g.global_position = Vector2(x, _chao_cache + dy)
	pai.add_child(g)
	g.cair(maxf(0.15, atraso))


func _raizes() -> void:
	Som.toca("esmagar", -8.0, 1.3)
	_abanar_camera(4.0)
	var origem := global_position.x
	var alvo := _x_koliani()
	var passos := 4 if _fase2 else 3
	for i in passos:
		var f := float(i) / float(maxi(1, passos - 1))
		_raiz_em(lerpf(origem + signf(alvo - origem) * 60.0, alvo, f), 0.14 + f * 0.42)


func _raiz_em(x: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var r := RAIZ.instantiate()
	pai.add_child(r)
	r.global_position = Vector2(x, _chao_y(x))
	r.avisar(int(round(dano_raiz * (1.15 if _fase2 else 1.0))), atraso)


func _pingo_ocasional(dt: float) -> void:
	_t_pingo -= dt
	if _t_pingo > 0.0:
		return
	_t_pingo = randf_range(1.1, 2.0)
	var pai := get_parent()
	if pai == null:
		return
	var x := global_position.x + randf_range(-360.0, 360.0)
	var g := GOTA.instantiate()
	g.automatico = false
	g.dano = dano_gota
	g.global_position = Vector2(x, _chao_cache - 220.0)
	pai.add_child(g)
	g.cair(0.5)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -9.0, 0.7)
	_abanar_camera(7.0)
	dur_tel *= 0.7
	dur_exposta *= 0.85
	_t_pingo = 1.0
	# parte um par de plataformas do tronco
	var plats := get_tree().get_nodes_in_group("plataformas_arvore")
	for i in plats.size():
		if i % 2 == 0 and is_instance_valid(plats[i]):
			var p: Node = plats[i]
			var tw := p.create_tween()
			tw.tween_property(p, "modulate:a", 0.0, 0.4)
			tw.tween_callback(p.queue_free)


## --- núcleo / dano -------------------------------------------------

## Telegrafo -> frame 2 (galho estendido) da tira pixel-art.
func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _nucleo_exposto:
		_corpo.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	_nucleo_exposto = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _nucleo == null:
		return
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
	if not _nucleo_exposto:
		# casca de árvore -- o golpe não passa
		Som.toca("bloqueio", -9.0, 0.6)
		if _sprite:
			_sprite.modulate = Color(0.62, 0.68, 0.55)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		_raspao(quantidade, dir_empurrao)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao, critico)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return global_position.y + 40.0
	var de := Vector2(x, global_position.y - 40.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 420.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else global_position.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
