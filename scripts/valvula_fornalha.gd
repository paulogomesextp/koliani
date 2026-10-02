class_name ValvulaFornalha
extends Area2D
## "Valvulas de pressao" da Regiao IV -- Fornalha (N19, Sala das Pressoes; set
## piece "Valvulas e tubagens"). A Koliani toca na roda -> a valvula ABRE e
## muda o estado de TODOS os mecanismos do seu `grupo`: `PistaoFornalha`,
## `JatoFornalha` e `PlataformaRitmada` que tenham o mesmo `grupo_valvula`.
## O que cada um faz declara-o ele proprio (`efeito_valvula`); a valvula so'
## avisa "abri / fechei" -- por isso serve para qualquer combinacao.
##
##   modo "temporaria": fica aberta `janela_seg` e fecha sozinha; tocar de novo
##                      renova a janela. Nos ultimos `aviso_fim_seg` a roda
##                      pisca e apita: a janela esta' a fechar.
##   modo "alterna":    cada toque abre/fecha.
##   modo "uma_vez":    abre e fica aberta (ate' a cena recarregar).
##
## Reset: tudo o que a valvula governa e a propria valvula vivem na cena -- ao
## morrer a cena recarrega e volta TUDO ao estado de arranque (valvula fechada).
## Por isso nenhum alvo pode ficar para la' de um checkpoint que a preceda: o
## teste do N19 verifica-o.
##
## Feedback: a roda gira 90 graus, sopro de vapor, brilho azul-gelo e as
## LIGACOES (tubos finos da roda ate' cada alvo) acendem por onde a pressao
## foi desviada. Os alvos que a valvula domina ficam com o mesmo azul-gelo.

signal mudou(aberta: bool)

@export var grupo := "pressao_a"
@export_enum("temporaria", "alterna", "uma_vez") var modo := "temporaria"
@export var janela_seg := 9.0
@export var aviso_fim_seg := 2.0
@export var textura: Texture2D
@export var escala_textura := 0.55
## Tubos finos da roda a cada alvo (a "ligacao visual").
@export var mostrar_ligacoes := true
@export var cor_ligacao := Color(0.45, 0.8, 1.0, 1.0)

const COR_FECHADA := Color(0.95, 0.55, 0.35, 1.0)
const COR_ABERTA := Color(0.5, 0.85, 1.0, 1.0)

var aberta := false
var _cooldown := 0.0
var _t_aberta := 0.0
var _pele: Sprite2D
var _brilho: Sprite2D
var _vapor: CPUParticles2D
var _ligacoes: Array[Line2D] = []
var _ultimo_beep := -1


func _ready() -> void:
	add_to_group("valvulas")
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_ao_tocar)
	_montar()
	set_process(false)
	# as ligacoes so' se desenham depois de os alvos estarem na arvore
	if mostrar_ligacoes:
		call_deferred("_montar_ligacoes")


func _montar() -> void:
	var forma := CollisionShape2D.new()
	forma.name = "Zona"
	var r := RectangleShape2D.new()
	r.size = Vector2(84.0, 110.0)
	forma.shape = r
	forma.position = Vector2(0, -52)
	add_child(forma)
	# pedestal: placa + haste de ferro (a roda gira por cima, a base nao)
	var placa := Polygon2D.new()
	placa.name = "Placa"
	placa.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(26, 0), Vector2(22, -9), Vector2(-22, -9)])
	placa.color = Color(0.3, 0.24, 0.24)
	placa.z_index = 0
	add_child(placa)
	var haste := Polygon2D.new()
	haste.name = "Haste"
	haste.polygon = PackedVector2Array([Vector2(-7, -9), Vector2(7, -9), Vector2(6, -44), Vector2(-6, -44)])
	haste.color = Color(0.22, 0.18, 0.19)
	haste.z_index = 0
	add_child(haste)
	var friso := Polygon2D.new()
	friso.name = "Friso"
	friso.polygon = PackedVector2Array([Vector2(-7, -22), Vector2(7, -22), Vector2(7, -17), Vector2(-7, -17)])
	friso.color = Color(0.8, 0.45, 0.22)
	friso.z_index = 0
	add_child(friso)
	_pele = Sprite2D.new()
	_pele.name = "Roda"
	if textura:
		_pele.texture = textura
		_pele.scale = Vector2(escala_textura, escala_textura)
	_pele.position = Vector2(0, -66)
	_pele.modulate = COR_FECHADA
	_pele.z_index = 1
	add_child(_pele)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 96
	gt.height = 96
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	_brilho = Sprite2D.new()
	_brilho.name = "Brilho"
	_brilho.texture = gt
	_brilho.material = mat
	_brilho.position = Vector2(0, -66)
	_brilho.scale = Vector2(1.7, 1.7)
	_brilho.modulate = Color(1.0, 0.4, 0.15, 0.35)
	_brilho.z_index = 2
	add_child(_brilho)
	_vapor = CPUParticles2D.new()
	_vapor.name = "Vapor"
	_vapor.amount = 14
	_vapor.lifetime = 0.8
	_vapor.one_shot = true
	_vapor.explosiveness = 0.9
	_vapor.local_coords = false
	_vapor.position = Vector2(0, -70)
	_vapor.direction = Vector2(0, -1)
	_vapor.spread = 70.0
	_vapor.gravity = Vector2(0, -26)
	_vapor.initial_velocity_min = 30.0
	_vapor.initial_velocity_max = 80.0
	_vapor.scale_amount_min = 4.0
	_vapor.scale_amount_max = 9.0
	_vapor.emitting = false
	_vapor.z_index = 3
	var rv := Gradient.new()
	rv.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	rv.colors = PackedColorArray([Color(0.75, 0.9, 1, 0), Color(0.78, 0.92, 1, 0.55), Color(0.5, 0.6, 0.7, 0)])
	_vapor.color_ramp = rv
	add_child(_vapor)


## Alvos governados por esta valvula (nos do grupo `valvula_<grupo>`).
func alvos() -> Array[Node]:
	var r: Array[Node] = []
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("valvula_" + grupo):
			r.append(n)
	return r


func _montar_ligacoes() -> void:
	for n in alvos():
		if not (n is Node2D):
			continue
		var d: Vector2 = (n as Node2D).global_position - global_position
		var l := Line2D.new()
		l.width = 3.0
		l.z_index = -3
		l.default_color = Color(0.34, 0.22, 0.2, 0.9)
		l.points = PackedVector2Array([Vector2(0, -20), Vector2(d.x, -20), Vector2(d.x, d.y)])
		add_child(l)
		_ligacoes.append(l)


func _ao_tocar(corpo: Node) -> void:
	if not (corpo is Node and corpo.is_in_group("koliani")) or _cooldown > 0.0:
		return
	activar()


## Toque da Koliani (ou um teste).
func activar() -> void:
	_cooldown = 0.6
	match modo:
		"alterna":
			_definir(not aberta)
		"uma_vez":
			if aberta:
				return
			_definir(true)
		_:
			_t_aberta = 0.0
			_ultimo_beep = -1
			if not aberta:
				_definir(true)
			else:
				_vibra()


func _definir(nova: bool) -> void:
	aberta = nova
	_t_aberta = 0.0
	_ultimo_beep = -1
	set_process(true)
	get_tree().call_group("valvula_" + grupo, "valvula_mudou", aberta)
	_visual(false)
	var som := get_node_or_null("/root/Som")
	if som and som.has_method("toca"):
		som.call("toca", "mecanismo", -9.0, 1.0 if aberta else 0.8)
	if _vapor:
		_vapor.restart()
	mudou.emit(aberta)


func _vibra() -> void:
	if _pele:
		var tw := create_tween()
		tw.tween_property(_pele, "scale", Vector2(escala_textura * 1.12, escala_textura * 0.9), 0.06)
		tw.tween_property(_pele, "scale", Vector2(escala_textura, escala_textura), 0.12)


func _visual(instantaneo: bool) -> void:
	var cor := COR_ABERTA if aberta else COR_FECHADA
	var alvo_rot := (PI * 0.5) if aberta else 0.0
	if _pele:
		if instantaneo:
			_pele.modulate = cor
			_pele.rotation = alvo_rot
		else:
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(_pele, "rotation", alvo_rot, 0.3)
			tw.parallel().tween_property(_pele, "modulate", cor, 0.25)
	if _brilho:
		var c2 := Color(0.4, 0.8, 1.0, 0.6) if aberta else Color(1.0, 0.4, 0.15, 0.35)
		create_tween().tween_property(_brilho, "modulate", c2, 0.25)
	for l in _ligacoes:
		l.default_color = Color(cor_ligacao.r, cor_ligacao.g, cor_ligacao.b, 0.95) if aberta \
			else Color(0.34, 0.22, 0.2, 0.9)
		l.width = 4.0 if aberta else 3.0


func _process(dt: float) -> void:
	_cooldown = maxf(0.0, _cooldown - dt)
	if not aberta:
		if _cooldown <= 0.0:
			set_process(false)
		return
	if modo != "temporaria":
		return
	_t_aberta += dt
	var resta := janela_seg - _t_aberta
	if resta <= aviso_fim_seg and _pele:
		# a janela esta' a fechar: pisca e apita a meio-segundo
		var p := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
		_pele.modulate = COR_ABERTA.lerp(Color(1.0, 0.45, 0.25), p)
		var beep := int(ceil(resta * 2.0))
		if beep != _ultimo_beep:
			_ultimo_beep = beep
			var som := get_node_or_null("/root/Som")
			if som and som.has_method("toca_actor") and som.has_method("em_vista") and som.em_vista(self, 200.0):
				som.call("toca_actor", self, "mecanismo_ciclo", -16.0, 1.5)
	if _t_aberta >= janela_seg:
		_definir(false)


## Volta ao arranque (testes).
func reiniciar() -> void:
	aberta = false
	_t_aberta = 0.0
	_cooldown = 0.0
