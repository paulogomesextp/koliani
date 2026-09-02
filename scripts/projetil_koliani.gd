class_name ProjetilKoliani
extends Area2D
## Projétil mágico da Koliani (habilidade "projetil"). Anda em linha reta
## numa das 8 direções, magoa inimigos com o mesmo dano do ataque corpo a
## corpo, e desfaz-se contra inimigos, contra o cenário, ou ao fim de algum
## tempo. Custo/energia é gerido em `koliani.gd`.

const VELOCIDADE := 540.0

var dano := 25
var _dir := Vector2.RIGHT
var _tempo_de_vida := 2.2
var _t := 0.0

@onready var _luz: PointLight2D = $Luz
@onready var _corpo: Sprite2D = $Corpo


## `direcao` é um dos 8 vetores (cima/baixo/lados/diagonais); `dano_` vem
## do `Koliani.DANO_ATAQUE` para o projétil bater igual à espada.
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
		_luz.energy = 1.8 + 0.4 * sin(_t * 20.0)  # a aura roxa "respira"
	if _corpo:
		_corpo.frame = int(_t * 20.0) % 6         # o orbe gira
		_corpo.rotation = -rotation               # mantém-se estável no ecrã
	_tempo_de_vida -= dt
	if _tempo_de_vida <= 0.0:
		queue_free()


func _ao_bater(corpo: Node) -> void:
	if corpo.has_method("receber_dano") and not (corpo is Koliani):
		corpo.receber_dano(dano, signf(_dir.x) if _dir.x != 0.0 else 0.0)
		# o tiro mágico DEIXA A ARDER -> abre janela de crítico para a espada
		if corpo.has_method("queimar"):
			corpo.queimar(2.0, maxi(2, roundi(dano * 0.14)))
		Som.toca("acerto", -9.0)
	_estoirar()


func _estoirar() -> void:
	Impacto.rebentar(self, global_position, Color(1, 1, 1), 1.7)
	queue_free()
