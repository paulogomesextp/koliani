class_name MecanismoSinos
extends Alavanca
## "Mecanismo central (de 3 sinos)" -- elemento-chave do N13, Mecanismos
## Antigos (`docs/art_direction/regions/region_03/
## REGION03_VISUAL_GAMEPLAY_CONTRACT.md`: "sinos com padrao").
##
## Tres `SinoTorre` (em `sinos`) tem de ser tocados pela ORDEM de `ordem`.
## O proprio mecanismo ENSINA a ordem: com a Koliani perto, de tantos em
## tantos segundos faz o eco do padrao -- cada sino brilha e soa na sua vez
## ("os ecos nao mentem, apenas repetem o que foi esquecido"). Cada sino
## certo fica aceso; um errado apaga tudo e o eco volta a tocar.
##
## Quando o padrao fecha, o mecanismo LIGA-SE como uma alavanca (herda de
## `Alavanca`): as `PortaTrancada` com o mesmo `id` abrem sem codigo novo.
## Nao se liga ao toque -- so' pelo padrao.

## Os tres sinos (caminhos a partir deste no').
@export var sinos: Array[NodePath] = []
## Ordem certa, por indice em `sinos`.
@export var ordem := PackedInt32Array([1, 0, 2])
## Distancia (px) a que a Koliani faz o mecanismo repetir o eco.
@export var raio_eco := 520.0
@export var intervalo_eco := 5.5
## Pele do mecanismo (a prancha "mecanismo central"). Vazio = so' a luz.
@export var textura_mecanismo: Texture2D
@export var escala_mecanismo := 1.0

var _lista: Array[Node] = []
var _certos := 0
var _t_eco := 1.5
var _a_ecoar := false
var _nucleo: Sprite2D


func _montar_visual() -> void:
	_luz = PointLight2D.new()
	_luz.texture = _tex_luz()
	_luz.color = Color(1.0, 0.8, 0.45)
	_luz.energy = 0.0
	_luz.scale = Vector2(1.6, 1.6)
	add_child(_luz)
	if textura_mecanismo:
		_nucleo = Sprite2D.new()
		_nucleo.texture = textura_mecanismo
		_nucleo.scale = Vector2(escala_mecanismo, escala_mecanismo)
		_nucleo.z_index = -1
		_nucleo.modulate = Color(0.7, 0.7, 0.85)
		add_child(_nucleo)
	for c in sinos:
		var s := get_node_or_null(c)
		if s:
			_lista.append(s)
			if s.has_signal("badalada"):
				s.badalada.connect(_ao_badalar)


## Tocar no mecanismo nao faz nada: so' o padrao o liga.
func _ao_tocar(_corpo: Node) -> void:
	pass


func _aplicar(_instantaneo: bool) -> void:
	pass


func _process(dt: float) -> void:
	super._process(dt)
	if ligada or _a_ecoar:
		return
	var k := get_tree().get_first_node_in_group("koliani") as Node2D
	if k == null or k.global_position.distance_to(global_position) > raio_eco:
		return
	_t_eco -= dt
	if _t_eco <= 0.0:
		_t_eco = intervalo_eco
		_ecoar()


## O eco do padrao: cada sino da ordem brilha e soa, um de cada vez.
func _ecoar() -> void:
	_a_ecoar = true
	for i in ordem.size():
		if ligada:
			break
		var s := _sino(ordem[i])
		if s and s.has_method("brilhar"):
			s.brilhar(0.8)
			_som(0.8 + 0.18 * float(ordem[i]), -16.0)
		await get_tree().create_timer(0.65).timeout
		if not is_inside_tree():
			return
	_a_ecoar = false
	# os que ja' estao certos continuam acesos
	for i in _certos:
		var s := _sino(ordem[i])
		if s and s.has_method("brilhar"):
			s.brilhar(0.5)


func _ao_badalar(sino: Node) -> void:
	if ligada:
		return
	var i := _lista.find(sino)
	if i < 0:
		return
	if i == ordem[_certos]:
		_certos += 1
		if _nucleo:
			_nucleo.modulate = Color(0.7, 0.7, 0.85).lerp(Color(1.2, 1.1, 0.95),
				float(_certos) / float(ordem.size()))
		if _certos >= ordem.size():
			_resolver()
	else:
		# errou: apaga tudo, um som grave, e o eco volta pouco depois
		_certos = 0
		if _nucleo:
			create_tween().tween_property(_nucleo, "modulate", Color(0.7, 0.7, 0.85), 0.3)
		_som(0.55, -12.0)
		_t_eco = 1.2


func _resolver() -> void:
	ligada = true
	_som(1.25, -8.0)
	if _luz:
		create_tween().tween_property(_luz, "energy", 1.3, 0.6)
	if _nucleo:
		_nucleo.modulate = Color(1.35, 1.2, 0.95)
	for s in _lista:
		if s.has_method("brilhar"):
			s.brilhar(1.0)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(5.0)
	mudou.emit(true)


func _sino(i: int) -> Node:
	return _lista[i] if i >= 0 and i < _lista.size() else null


func _som(pitch: float, db: float) -> void:
	var som := get_node_or_null("/root/Som")
	if som and som.has_method("toca"):
		som.call("toca", "sino_mecanismo", db, pitch, 0.0)
