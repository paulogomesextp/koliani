class_name PisoQuente
extends Armadilha
## "Pisos aquecidos (telegraficos)" da Regiao IV -- Fornalha (N16 em diante;
## `docs/art_direction/regions/region_04/level_mechanics.png`: "piso que
## aquece e causa dano", com aviso de 0,5 a 1,0 s -- `implementation_sheet`,
## "REGRAS DE TELEGRAPH FEEDBACK").
##
## Uma faixa de chao (a colisao e' a da `Plataforma` por baixo, que nao
## muda) que passa por tres estados num ciclo fixo:
##   FRIO  (`frio_seg`)   pedra escura, brasa fraca nas juntas: seguro
##   AVISO (`aviso_seg`)  as juntas acendem e pulsam, sobem fagulhas: seguro
##   QUENTE (`quente_seg`) laranja vivo + chama baixa: magoa quem la' estiver
##
## O ciclo vem do RELOGIO GLOBAL (como a `PlataformaRitmada`): varias faixas
## batem em sincronia sem maestro, e `fase` desfasa uma da outra -- e' assim
## que se faz "passa agora / espera", sem nada de aleatorio. A origem do no'
## e' o MEIO da superficie do chao (a faixa vive por cima dela).

enum Estado { FRIO, AVISO, QUENTE }

@export var largura := 240.0 : set = _set_largura
@export var frio_seg := 2.4
@export var aviso_seg := 1.0
@export var quente_seg := 1.6
@export var fase := 0.0
## Pintura de luz da prancha (`r4_piso_quente`), em blend ADD.
@export var textura_brilho: Texture2D

const ALTURA_ZONA := 30.0
const REPETE_DANO := 0.45
## Cor do brilho em cada estado (multiplica a textura; o preto nao conta em ADD).
const COR_FRIO := Color(0.30, 0.07, 0.03, 0.55)
const COR_AVISO := Color(1.0, 0.42, 0.12, 0.9)
const COR_QUENTE := Color(1.0, 0.62, 0.2, 1.0)

var estado := Estado.FRIO
var _brilho: Sprite2D
var _juntas: Polygon2D
var _halo: Sprite2D
var _fagulhas: CPUParticles2D
var _chama: CPUParticles2D
var _forma: CollisionShape2D
var _t_dano := 0.0
var _estado_anterior := -1


func _set_largura(v: float) -> void:
	largura = maxf(24.0, v)
	if is_node_ready():
		_reconstruir()


func _pronto() -> void:
	dano = maxi(dano, 14)
	ativa = false
	_forma = CollisionShape2D.new()
	_forma.name = "Zona"
	add_child(_forma)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_brilho = Sprite2D.new()
	_brilho.name = "Brilho"
	_brilho.material = mat
	_brilho.centered = true
	_brilho.z_index = 2
	add_child(_brilho)
	# halo de calor: degrade laranja a subir do chao (a leitura de longe)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 0.75, 0.35, 0.0), Color(1, 0.45, 0.12, 0.55),
		Color(1, 0.3, 0.06, 1.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 8
	gt.height = 64
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	_halo = Sprite2D.new()
	_halo.name = "Halo"
	_halo.texture = gt
	_halo.material = mat
	_halo.centered = false
	_halo.z_index = 2
	add_child(_halo)
	# as juntas acesas da pedra: uma fita fina a' frente do chao
	_juntas = Polygon2D.new()
	_juntas.name = "Juntas"
	_juntas.z_index = 1
	add_child(_juntas)
	_fagulhas = _particulas(14, 1.3, Vector2(0, -60), 30.0, 70.0, 1.5, 3.0)
	_chama = _particulas(18, 0.7, Vector2(0, -120), 20.0, 60.0, 3.0, 6.0)
	_chama.color = Color(1.0, 0.55, 0.18, 0.9)
	_reconstruir()
	_aplicar(true)


func _particulas(n: int, vida: float, grav: Vector2, v0: float, v1: float,
		s0: float, s1: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = n
	p.lifetime = vida
	p.local_coords = false
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = grav
	p.initial_velocity_min = v0
	p.initial_velocity_max = v1
	p.scale_amount_min = s0
	p.scale_amount_max = s1
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emitting = false
	p.z_index = 3
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	ramp.colors = PackedColorArray([Color(1, 0.85, 0.4, 0.0), Color(1, 0.5, 0.15, 0.95),
		Color(0.5, 0.1, 0.05, 0.0)])
	p.color_ramp = ramp
	add_child(p)
	return p


func _reconstruir() -> void:
	if _forma == null:
		return
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, ALTURA_ZONA)
	_forma.shape = r
	_forma.position = Vector2(0, -ALTURA_ZONA * 0.5)
	_juntas.polygon = PackedVector2Array([
		Vector2(-largura * 0.5, -5.0), Vector2(largura * 0.5, -5.0),
		Vector2(largura * 0.5, 3.0), Vector2(-largura * 0.5, 3.0)])
	if _halo:
		_halo.scale = Vector2(largura / 8.0, 1.25)
		_halo.position = Vector2(-largura * 0.5, -80.0 + 2.0)
	for p in [_fagulhas, _chama]:
		p.emission_rect_extents = Vector2(largura * 0.5, 2.0)
	if textura_brilho:
		_brilho.texture = textura_brilho
		# estica a pintura a' largura da faixa, com altura proporcional
		var e := largura / float(textura_brilho.get_width())
		_brilho.scale = Vector2(e, maxf(0.6, e))
		_brilho.position = Vector2(0, -float(textura_brilho.get_height()) * _brilho.scale.y * 0.42)


func _ciclo() -> float:
	return maxf(0.5, frio_seg + aviso_seg + quente_seg)


func estado_em(t_seg: float) -> int:
	var f := fposmod(t_seg + fase, _ciclo())
	if f < frio_seg:
		return Estado.FRIO
	if f < frio_seg + aviso_seg:
		return Estado.AVISO
	return Estado.QUENTE


func _process(dt: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	estado = estado_em(t) as Estado
	if estado != _estado_anterior:
		_aplicar(false)
	var pulso := 0.5 + 0.5 * sin(t * (16.0 if estado == Estado.AVISO else 5.0))
	match estado:
		Estado.FRIO:
			_halo.modulate = Color(1, 1, 1, 0.0)
			_brilho.modulate = COR_FRIO
			_juntas.color = Color(0.55, 0.16, 0.06, 0.5)
		Estado.AVISO:
			var c := COR_AVISO
			c.a *= 0.5 + 0.5 * pulso
			_halo.modulate = Color(1, 1, 1, 0.12 + 0.28 * pulso)
			_brilho.modulate = c
			_juntas.color = Color(1.0, 0.45, 0.14, 0.6 + 0.4 * pulso)
		Estado.QUENTE:
			_halo.modulate = Color(1, 1, 1, 0.8 + 0.15 * pulso)
			_brilho.modulate = COR_QUENTE
			_juntas.color = Color(1.0, 0.72, 0.3, 1.0)
			_t_dano -= dt
			if _t_dano <= 0.0:
				_t_dano = REPETE_DANO
				_ferir_presentes()


func _aplicar(_inicio: bool) -> void:
	_estado_anterior = estado
	ativa = estado == Estado.QUENTE
	_fagulhas.emitting = estado != Estado.FRIO
	_chama.emitting = estado == Estado.QUENTE
	if estado == Estado.AVISO:
		# B8: o piso a aquecer ouve-se (mais grave que o jato)
		var som_a := get_node_or_null("/root/Som")
		if som_a and som_a.has_method("toca_actor") and som_a.has_method("em_vista") and som_a.em_vista(self):
			som_a.call("toca_actor", self, "fornalha_carga", -22.0, 0.75, 0.05, 1.2,
				"piso_aviso_%d" % get_instance_id())
	if estado == Estado.QUENTE:
		_t_dano = 0.0
		_ferir_presentes()
		var som := get_node_or_null("/root/Som")
		if som and som.has_method("toca_actor") and som.has_method("em_vista") and som.em_vista(self):
			som.call("toca_actor", self, "fogo_sopro", -20.0, 0.85, 0.06, 1.2,
				"piso_%d" % get_instance_id())
