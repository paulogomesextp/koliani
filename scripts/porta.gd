class_name Porta
extends Area2D
## Porta de fim de nível. Marca o nível como concluído e SEGUE DIRETO para o
## nível seguinte (com banner "Avançou para o Nível N" ao entrar). Na última
## porta, com a campanha toda feita, dispara `fim_da_campanha`. O Mapa do
## Mundo continua acessível pelo menu de pausa e pelo menu inicial.

signal fim_da_campanha

const CENA_JOGO := "res://scenes/Main.tscn"
const IDS_PROGRESSAO := preload("res://scripts/progression_ids.gd")

@export var pista_ao_atravessar := ""  # id opcional de pista sobre a mãe

var _t := 0.0
var _vortice_arte: Sprite2D
@onready var _anel_e: Node = get_node_or_null("Vortice/AnelExterno")
@onready var _anel_i: Node = get_node_or_null("Vortice/AnelInterno")
@onready var _luz: PointLight2D = get_node_or_null("PointLight2D")


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	# A mesma tira CC0 já aprovada para Portal substitui o hexágono legado.
	if ResourceLoader.exists(Portal.TIRA_VORTICE):
		$Vortice.visible = false
		_vortice_arte = Sprite2D.new()
		_vortice_arte.name = "VorticeArte"
		_vortice_arte.texture = load(Portal.TIRA_VORTICE)
		_vortice_arte.hframes = Portal.FRAMES_VORTICE
		_vortice_arte.position = Vector2(0, 2)
		_vortice_arte.scale = Vector2(1.5, 1.8)
		_vortice_arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_vortice_arte.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		var material_arte := CanvasItemMaterial.new()
		material_arte.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_vortice_arte.material = material_arte
		add_child(_vortice_arte)


func _process(dt: float) -> void:
	# vórtice: anéis a rodar em sentidos opostos + luz a pulsar
	_t += dt
	if _vortice_arte:
		_vortice_arte.frame = int(_t * Portal.FPS_VORTICE) % Portal.FRAMES_VORTICE
	if _anel_e:
		_anel_e.rotation += dt * 1.1
	if _anel_i:
		_anel_i.rotation -= dt * 1.7
	if _luz:
		_luz.energy = 1.7 + 0.35 * sin(_t * 3.0)


func _ao_entrar(corpo: Node) -> void:
	if not (corpo is Koliani):
		return
	if pista_ao_atravessar != "":
		EstadoJogo.registar_pista(pista_ao_atravessar)
	Som.toca("transicao", -3.0)
	var i := EstadoJogo.indice_nivel
	EstadoJogo.marcar_nivel_concluido(i)
	EstadoJogo.completar_sessao_nivel(
		IDS_PROGRESSAO.level_id_do_indice(i))

	# Segue linear para o nível seguinte, sem passar
	# pelo mapa. Só a última porta (campanha feita) é que termina o jogo.
	if EstadoJogo.ha_proximo_nivel():
		EstadoJogo.avancar_nivel()
		get_tree().change_scene_to_file(CENA_JOGO)
	else:
		fim_da_campanha.emit()
