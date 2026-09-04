class_name Portal
extends Area2D
## Portal de teleporte -- mecanica partilhada. Toca-se num portal e a Koliani
## e' cuspida no portal parceiro (o que tem `id == destino_id`). Serve para
## saltar mocegos de espinhos, atalhos verticais, e "estruturas" tematicas
## nos gauntlets de aproximacao antes do chefe.
##
## Anti-softlock: o portal SO' transporta para o parceiro; a chegada e'
## sempre em cima de chao solido (quem semeia o par garante-o) e ha um
## `cooldown` global no par para nao fazer ping-pong. O portal de CHEGADA
## costuma ser `so_saida = true` (nao transporta de volta) -- assim nunca
## se fica preso entre dois.

## Liga este portal aos parceiros com `destino_id` igual a este `id`.
@export var id := "portal_a"
## Para onde manda (o `id` do portal de chegada).
@export var destino_id := "portal_b"
## Portal so' de chegada: recebe mas nao transporta.
@export var so_saida := false
## Cor do anel/luz (por omissao, o magenta da casa).
@export var cor := Color(0.85, 0.35, 1.0)
## Raio do anel (px). A colisao acompanha.
@export var raio := 22.0

const RECARGA := 0.9
## Arte do vórtice (32 frames numa tira). Ver `tools/gerar_fx_portal_balas.py`.
const TIRA_VORTICE := "res://assets/sprites/pixel/props/portal.png"
const FRAMES_VORTICE := 32
## Frames por segundo do rodopio. O portal de SAÍDA anda ao contrário e mais
## devagar, para se distinguir do de entrada sem precisar de legenda.
const FPS_VORTICE := 18.0
## Quanto e' que a chegada sobe acima do centro do portal parceiro. Eram 6 px
## -- com o corpo dela (20x44 centrado) sobravam 4 px acima da plataforma, e
## bastava o nivel andar um nada para ela nascer dentro do chao.
const SUBIDA := 20.0
## Quantos passos de 10 px se procura em volta antes de desistir.
const PASSOS_LIVRES := 12

var _t := 0.0
var _cd := 0.0
## Vórtice: a arte do portal (tira de 32 frames, `assets/.../props/portal.png`).
## `_nucleo`/`_anel` são o desenho POR CÓDIGO que lá estava e que só entra
## se a tira faltar (a ferramenta não ter corrido).
var _vortice: Sprite2D
var _anel: Line2D
var _nucleo: Polygon2D
var _luz: PointLight2D
var _parts: CPUParticles2D


func _ready() -> void:
	add_to_group("portais")
	collision_layer = 0
	collision_mask = 2  # so' a Koliani
	monitoring = not so_saida
	body_entered.connect(_ao_entrar)
	if get_node_or_null("Col") == null:
		var cs := CollisionShape2D.new()
		cs.name = "Col"
		var forma := CapsuleShape2D.new()
		forma.radius = raio * 0.7
		forma.height = raio * 2.4
		cs.shape = forma
		add_child(cs)
	_montar_visual()


func _montar_visual() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	var halo := Polygon2D.new()
	halo.name = "Halo"
	halo.polygon = _oval(raio * 1.25, raio * 1.7)
	halo.color = Color(cor.r, cor.g, cor.b, 0.12)
	halo.material = mat
	add_child(halo)

	# O miolo do portal: a tira do vórtice. Antes era um oval `Polygon2D` a
	# rodar dentro de um `Line2D` -- lia-se como feito por código, que é
	# exactamente a queixa do Paulo. A tira é do pack de FX do CodeManu
	# (domínio público), recolorida por `tools/gerar_fx_portal_balas.py`.
	if ResourceLoader.exists(TIRA_VORTICE):
		_vortice = Sprite2D.new()
		_vortice.name = "Vortice"
		_vortice.texture = load(TIRA_VORTICE)
		_vortice.hframes = FRAMES_VORTICE
		_vortice.material = mat
		_vortice.modulate = Color(cor.r, cor.g, cor.b, 1.0 if not so_saida else 0.72)
		# a arte é redonda (64x64) e o portal é um oval em pé. O rodopio só
		# ocupa uns 60% do frame (o resto são partículas soltas), por isso a
		# escala é maior do que o anel -- é o MIOLO que tem de bater certo.
		_vortice.scale = Vector2(raio * 4.2 / 64.0, raio * 5.0 / 64.0)
		add_child(_vortice)
	else:
		_nucleo = Polygon2D.new()
		_nucleo.name = "Nucleo"
		_nucleo.polygon = _oval(raio * 0.55, raio * 1.05)
		_nucleo.color = Color(cor.r, cor.g, cor.b, 0.5) if not so_saida else Color(cor.r, cor.g, cor.b, 0.32)
		_nucleo.material = mat
		add_child(_nucleo)

		_anel = Line2D.new()
		_anel.name = "Anel"
		_anel.points = _oval(raio, raio * 1.5)
		_anel.closed = true
		_anel.width = 3.0
		_anel.default_color = cor
		_anel.joint_mode = Line2D.LINE_JOINT_ROUND
		_anel.material = mat
		add_child(_anel)

	_luz = PointLight2D.new()
	_luz.texture = _tex_luz()
	_luz.color = cor
	_luz.energy = 0.9
	_luz.scale = Vector2(0.6, 0.9)
	add_child(_luz)

	_parts = CPUParticles2D.new()
	_parts.amount = 18
	_parts.lifetime = 1.1
	_parts.local_coords = false
	_parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	_parts.emission_sphere_radius = raio
	_parts.direction = Vector2(0, -1)
	_parts.spread = 40.0
	_parts.gravity = Vector2.ZERO
	_parts.initial_velocity_min = 4.0
	_parts.initial_velocity_max = 14.0
	_parts.scale_amount_min = 1.0
	_parts.scale_amount_max = 2.4
	_parts.color = Color(cor.r, cor.g, cor.b, 0.7)
	_parts.material = mat
	add_child(_parts)


func _oval(rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static var _TEX: GradientTexture2D

func _tex_luz() -> GradientTexture2D:
	if _TEX == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		_TEX = GradientTexture2D.new()
		_TEX.gradient = g
		_TEX.width = 160
		_TEX.height = 160
		_TEX.fill = GradientTexture2D.FILL_RADIAL
		_TEX.fill_from = Vector2(0.5, 0.5)
		_TEX.fill_to = Vector2(1.0, 0.5)
	return _TEX


func _process(dt: float) -> void:
	_t += dt
	_cd = maxf(0.0, _cd - dt)
	if _vortice:
		var passo := _t * FPS_VORTICE * (1.0 if not so_saida else -0.7)
		_vortice.frame = posmod(int(passo), FRAMES_VORTICE)
		# respira com a mesma cadência de sempre
		var q := 1.0 + 0.06 * sin(_t * 5.0)
		_vortice.scale = Vector2(raio * 4.2 / 64.0 * q, raio * 5.0 / 64.0 * q)
	if _anel:
		_anel.rotation = _t * (1.6 if not so_saida else -1.0)
		var p := 1.0 + 0.08 * sin(_t * 5.0)
		_anel.scale = Vector2(p, p)
	if _luz:
		_luz.energy = (0.7 if _cd > 0.0 else 1.0) + 0.25 * sin(_t * 6.0)
	if _nucleo:
		_nucleo.rotation = -_t * 2.2


func _ao_entrar(corpo: Node) -> void:
	if so_saida or _cd > 0.0 or not (corpo is Koliani):
		return
	var alvo := _parceiro()
	if alvo == null:
		return
	_cd = RECARGA
	alvo._cd = RECARGA  # o parceiro tambem arrefece -> sem ping-pong imediato
	var k := corpo as Node2D
	k.global_position = _lugar_livre(k, alvo.global_position + Vector2(0.0, -SUBIDA))
	if "velocity" in k:
		k.velocity = Vector2(k.velocity.x * 0.4, minf(k.velocity.y, 0.0))
	if k.has_method("conceder_iframes"):
		k.conceder_iframes(0.25)
	_fx(global_position)
	alvo._fx(alvo.global_position)
	Som.toca("onda", -12.0, 1.6)


## O ponto onde ela pode MESMO aterrar. Se o destino cru estiver dentro do
## cenario, procura-se o livre mais proximo -- primeiro a subir, depois de
## lado. Sem isto bastava um portal semeado rente a uma plataforma para a
## entalar: era o softlock que o Paulo apanhou no primeiro portal (4 set
## 2026). Se nada estiver livre devolve-se o ponto cru -- e' melhor cair do
## que ficar preso, e a fisica trata do resto.
func _lugar_livre(k: Node2D, base: Vector2) -> Vector2:
	var forma := _forma_do_corpo(k)
	if forma == null or not _ocupado(k, forma, base):
		return base
	for passo in PASSOS_LIVRES:
		var d := 10.0 * float(passo + 1)
		for desvio: Vector2 in [
				Vector2(0.0, -d),
				Vector2(-d * 0.6, -d), Vector2(d * 0.6, -d),
				Vector2(-d, 0.0), Vector2(d, 0.0)]:
			if not _ocupado(k, forma, base + desvio):
				return base + desvio
	return base


## A forma de colisao do corpo dela (o primeiro `CollisionShape2D` filho).
func _forma_do_corpo(k: Node2D) -> Shape2D:
	for f in k.get_children():
		if f is CollisionShape2D and (f as CollisionShape2D).shape != null:
			return (f as CollisionShape2D).shape
	return null


## Ha' cenario solido (camada 1) a ocupar `pos`?
func _ocupado(k: Node2D, forma: Shape2D, pos: Vector2) -> bool:
	var espaco := k.get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = forma
	q.transform = Transform2D(0.0, pos)
	q.collision_mask = 1          # so' o mundo solido
	q.collide_with_areas = false
	q.exclude = [k.get_rid()] if k is CollisionObject2D else []
	return not espaco.intersect_shape(q, 1).is_empty()


func _parceiro() -> Portal:
	var melhor: Portal = null
	var dd := INF
	for p in get_tree().get_nodes_in_group("portais"):
		if p == self or not (p is Portal) or (p as Portal).id != destino_id:
			continue
		var d: float = global_position.distance_squared_to((p as Portal).global_position)
		if d < dd:
			dd = d
			melhor = p
	return melhor


func _fx(pos: Vector2) -> void:
	if _parts:
		_parts.restart()
	var s := Sprite2D.new()
	s.texture = _tex_luz()
	s.modulate = cor
	s.global_position = pos
	s.scale = Vector2(0.2, 0.2)
	s.z_index = 40
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	get_parent().add_child(s)
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", Vector2(1.6, 1.6), 0.22).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "modulate:a", 0.0, 0.22)
	t.chain().tween_callback(s.queue_free)
