class_name FragmentoEco
extends Area2D
## "Fragmentos de eco (ativam a arena)" do N15 -- O Topo dos Ecos (contrato
## da Regiao III): um estilhaco de memoria da torre, pousado num altar. Tocar-
## -lhe recolhe-o; com TODOS os fragmentos do nivel recolhidos, o sino celestial
## (`SinoTorre.fragmentos_necessarios`) responde e ergue a escada da arena.
##
## Area2D na layer 16 (como os checkpoints), a ver a Koliani (mascara 2).
## Grupo "fragmentos_eco". Nao persiste: o nivel recarrega-os num respawn, por
## isso os tres ficam todos a um ecra do sino.

signal recolhido(fragmento: Node)

## Pele aprovada (`f_fragmentos`): vazio = um cristal desenhado por poligono.
@export var textura: Texture2D
@export var escala_textura := 0.6
@export var cor := Color(0.62, 0.55, 1.0)

var coletado := false

var _pele: Node2D
var _t := 0.0


func _enter_tree() -> void:
	# no `_enter_tree` e nao no `_ready`: o sino celestial conta-os no seu
	# `_ready`, que pode correr antes do de um fragmento que venha depois
	add_to_group("fragmentos_eco")


func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	if textura != null:
		var s := Sprite2D.new()
		s.texture = textura
		s.scale = Vector2(escala_textura, escala_textura)
		_pele = s
	else:
		var p := Polygon2D.new()
		p.polygon = PackedVector2Array([Vector2(0, -16), Vector2(9, 0), Vector2(0, 16), Vector2(-9, 0)])
		p.color = cor
		_pele = p
	add_child(_pele)
	body_entered.connect(_ao_entrar)


func _process(dt: float) -> void:
	if coletado or _pele == null:
		return
	_t += dt
	_pele.position.y = sin(_t * 2.2) * 5.0
	var k := 1.0 + 0.12 * sin(_t * 5.0)
	_pele.modulate = Color(k, k, k * 1.1, 1.0)


func _ao_entrar(c: Node) -> void:
	if coletado or not (c is Koliani):
		return
	coletado = true
	var som := get_node_or_null("/root/Som")
	if som and som.has_method("toca"):
		som.call("toca", "sino_mecanismo", -10.0, 1.6)
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 22
	p.lifetime = 0.8
	p.spread = 180.0
	p.gravity = Vector2(0, 120)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 170.0
	p.color = cor
	add_child(p)
	if _pele:
		var tw := create_tween()
		tw.tween_property(_pele, "scale", _pele.scale * 1.8, 0.35)
		tw.parallel().tween_property(_pele, "modulate:a", 0.0, 0.35)
	recolhido.emit(self)
	get_tree().call_group("sinos", "fragmento_recolhido")
	get_tree().create_timer(1.0).timeout.connect(queue_free)
