class_name KamehamehaKoliani
extends Area2D
## Kamehameha roxo da Koliani (habilidade "projetil"). Anda depressa numa
## das 8 direções, ATRAVESSA inimigos (magoa cada um uma só vez) e desfaz-se
## contra o cenário ou ao fim do tempo. Custo/energia gerido em `koliani.gd`.

const VELOCIDADE := 900.0
## Roxo do pack das balas, para o estalo do impacto casar com o feixe.
const COR := Color(0.88, 0.5, 1.0)

var dano := 75
var _dir := Vector2.RIGHT
var _tempo_de_vida := 1.1
var _t := 0.0
## Inimigos já atingidos, para não bater duas vezes no mesmo.
var _atingidos: Dictionary = {}

@onready var _luz: PointLight2D = $Luz
@onready var _cabeca: Sprite2D = $Cabeca


## `direcao` é um dos 8 vetores; `dano_` vem do `Koliani._dano_kamehameha()`.
func lancar(direcao: Vector2, dano_: int) -> void:
	_dir = direcao.normalized()
	dano = dano_
	rotation = _dir.angle()


func _ready() -> void:
	body_entered.connect(_ao_bater)


func _physics_process(dt: float) -> void:
	global_position += _dir * VELOCIDADE * dt
	_t += dt
	if _luz:
		_luz.energy = 2.7 + 0.6 * sin(_t * 26.0)
	if _cabeca:
		_cabeca.frame = int(_t * 26.0) % 8   # o flare tem 8 frames
		_cabeca.rotation = -rotation
	_tempo_de_vida -= dt
	if _tempo_de_vida <= 0.0:
		_estoirar()


func _ao_bater(corpo: Node) -> void:
	if corpo is Koliani:
		return
	if corpo.has_method("receber_dano"):
		# atravessa: magoa e segue em frente (uma vez por inimigo)
		if _atingidos.has(corpo):
			return
		_atingidos[corpo] = true
		corpo.receber_dano(dano, signf(_dir.x) if _dir.x != 0.0 else 0.0)
		if corpo.has_method("queimar"):
			corpo.queimar(2.6, maxi(3, roundi(dano * 0.1)))
		Som.toca("acerto", -6.0)
		return
	# cenário -> parte-se
	_estoirar()


func _estoirar() -> void:
	Impacto.rebentar(self, global_position, COR, 2.8)
	queue_free()
