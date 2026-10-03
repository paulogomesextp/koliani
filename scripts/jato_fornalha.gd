class_name JatoFornalha
extends Armadilha
## "Jatos de fogo telegraficos" da Regiao IV -- Fornalha (N16 pontualmente,
## N19 como mecanica central; prancha `level_mechanics.png`). Ao contrario do
## `Fogo` (um candeeiro de chama baixa do Pixel Adventure), isto e' uma COLUNA
## de fogo industrial que sai do chao e sobe `alcance` px, com o ciclo da
## `implementation_sheet` ("Jato de fogo: ciclo 2-5 s, duracao 1-2 s,
## alcance 1-3 tiles, telegrafo 0,5-1 s"):
##   DORME (`intervalo`) -> AVISO (`aviso_seg`: bocal a brilhar, fagulhas,
##   chama pequena a crescer) -> ATIVO (`dur_ativa`: a coluna inteira).
## O ciclo e' do relogio global e `fase` desfasa -- sem aleatorio.
## A origem do no' e' a BOCA do jato (chao); a chama sobe (y negativo). Com
## `invertido = true` desce (jato de teto).

enum Estado { DORME, AVISO, ATIVO }

@export var alcance := 220.0 : set = _set_alcance
@export var largura := 46.0
@export var intervalo := 2.2
@export var aviso_seg := 0.8
@export var dur_ativa := 1.4
@export var fase := 0.0
@export var invertido := false
@export var textura_jato: Texture2D
@export var textura_bocal: Texture2D
## Opt-in (N19, `ValvulaFornalha`): grupo da valvula que o governa ("" = nenhuma).
## Enquanto aberta o jato DORME (sem aviso, sem fogo); ao fechar recomeca o
## ciclo em `fase_retoma` (-1 = `fase`), que tem de cair no `intervalo`.
@export var grupo_valvula := ""
@export var fase_retoma := -1.0
## Opt-in: o ciclo conta desde o arranque do no' (reaparecer repete o ritmo) em
## vez do relogio global do jogo. Omissao `false` = comportamento de sempre.
@export var relogio_local := false

var estado := Estado.DORME
var _forma: CollisionShape2D
var _coluna: Sprite2D
var _bocal: Sprite2D
var _faiscas: CPUParticles2D
var _estado_anterior := -1
var _t_dano := 0.0
var pausado := false
var _desloc := 0.0


func _set_alcance(v: float) -> void:
	alcance = maxf(40.0, v)
	if is_node_ready():
		_reconstruir()


func _pronto() -> void:
	dano = maxi(dano, 20)
	ativa = false
	if grupo_valvula != "":
		add_to_group("valvula_" + grupo_valvula)
	if relogio_local:
		_desloc = -_ahora()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_forma = CollisionShape2D.new()
	_forma.name = "Zona"
	add_child(_forma)
	_coluna = Sprite2D.new()
	_coluna.name = "Coluna"
	_coluna.material = mat
	_coluna.centered = true
	_coluna.z_index = 3
	add_child(_coluna)
	_bocal = Sprite2D.new()
	_bocal.name = "Bocal"
	_bocal.material = mat
	_bocal.z_index = 3
	add_child(_bocal)
	_faiscas = CPUParticles2D.new()
	_faiscas.amount = 16
	_faiscas.lifetime = 0.9
	_faiscas.local_coords = false
	_faiscas.direction = Vector2(0, 1.0 if invertido else -1.0)
	_faiscas.spread = 22.0
	_faiscas.gravity = Vector2(0, 0)
	_faiscas.initial_velocity_min = 60.0
	_faiscas.initial_velocity_max = 160.0
	_faiscas.scale_amount_min = 1.6
	_faiscas.scale_amount_max = 3.4
	_faiscas.emitting = false
	_faiscas.z_index = 4
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	ramp.colors = PackedColorArray([Color(1, 0.9, 0.5, 0.0), Color(1, 0.55, 0.15, 0.95),
		Color(0.5, 0.1, 0.05, 0.0)])
	_faiscas.color_ramp = ramp
	add_child(_faiscas)
	_reconstruir()
	_aplicar()


func _reconstruir() -> void:
	if _forma == null:
		return
	var s := -1.0 if not invertido else 1.0
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, alcance)
	_forma.shape = r
	_forma.position = Vector2(0, s * alcance * 0.5)
	if textura_jato:
		_coluna.texture = textura_jato
		var e := alcance / float(textura_jato.get_height())
		_coluna.scale = Vector2(maxf(largura * 1.9 / float(textura_jato.get_width()), 0.3), e)
		_coluna.flip_v = invertido
		_coluna.position = Vector2(0, s * alcance * 0.5)
	if textura_bocal:
		_bocal.texture = textura_bocal
		_bocal.position = Vector2(0, 0)
		_bocal.scale = Vector2(largura * 1.2 / float(textura_bocal.get_width()), 0.5)
	_faiscas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_faiscas.emission_rect_extents = Vector2(largura * 0.3, 2.0)


func _ciclo() -> float:
	return maxf(0.6, intervalo + aviso_seg + dur_ativa)


func estado_em(t_seg: float) -> int:
	var f := fposmod(t_seg + fase, _ciclo())
	if f < intervalo:
		return Estado.DORME
	if f < intervalo + aviso_seg:
		return Estado.AVISO
	return Estado.ATIVO


func _ahora() -> float:
	return RelogioFornalha.agora()


## Chamado pela `ValvulaFornalha` do `grupo_valvula`.
func valvula_mudou(aberta: bool) -> void:
	if aberta:
		pausado = true
	elif pausado:
		pausado = false
		_desloc = (fase_retoma if fase_retoma >= 0.0 else fase) - fase - _ahora()


func _process(dt: float) -> void:
	var t := _ahora() + _desloc
	estado = Estado.DORME if pausado else estado_em(t) as Estado
	if estado != _estado_anterior:
		_aplicar()
	var f := fposmod(t + fase, _ciclo())
	var pulso := 0.5 + 0.5 * sin(t * 30.0)
	match estado:
		Estado.DORME:
			_bocal.modulate = Color(0.4, 0.75, 1.0, 0.85) if pausado else Color(0.35, 0.1, 0.04, 0.7)
			_coluna.modulate.a = 0.0
		Estado.AVISO:
			# a chama pequena cresce ate' um quarto do alcance: le-se de longe
			var k := clampf((f - intervalo) / maxf(0.01, aviso_seg), 0.0, 1.0)
			_bocal.modulate = Color(1.0, 0.5, 0.15, 0.6 + 0.4 * pulso)
			_coluna.modulate = Color(1, 0.6, 0.3, 0.35 + 0.25 * pulso)
			_coluna.scale.y = (alcance / float(_coluna.texture.get_height()) if _coluna.texture else 1.0) * (0.12 + 0.13 * k)
			_coluna.position.y = (-1.0 if not invertido else 1.0) * alcance * (0.06 + 0.065 * k)
		Estado.ATIVO:
			_bocal.modulate = Color(1.0, 0.8, 0.45, 1.0)
			_coluna.modulate = Color(1.0, 0.85 + 0.1 * pulso, 0.7, 0.85 + 0.15 * pulso)
			if _coluna.texture:
				_coluna.scale.y = alcance / float(_coluna.texture.get_height())
			_coluna.position.y = (-1.0 if not invertido else 1.0) * alcance * 0.5
			_t_dano -= dt
			if _t_dano <= 0.0:
				_t_dano = 0.4
				_ferir_presentes()


func _aplicar() -> void:
	_estado_anterior = estado
	ativa = estado == Estado.ATIVO
	_faiscas.emitting = estado != Estado.DORME
	if estado == Estado.AVISO:
		# B8: o aviso tambem se OUVE (antes so' se via) -- antes do perigo
		var som_a := get_node_or_null("/root/Som")
		if som_a and som_a.has_method("toca_actor") and som_a.has_method("em_vista") and som_a.em_vista(self, 160.0):
			som_a.call("toca_actor", self, "fornalha_carga", -18.0, 1.0, 0.05, 1.0,
				"jato_aviso_%d" % get_instance_id())
	if estado == Estado.ATIVO:
		_t_dano = 0.0
		_ferir_presentes()
		var som := get_node_or_null("/root/Som")
		if som and som.has_method("toca_actor") and som.has_method("em_vista") and som.em_vista(self):
			som.call("toca_actor", self, "fogo_sopro", -16.0, 0.9, 0.06, 1.0,
				"jato_%d" % get_instance_id())
