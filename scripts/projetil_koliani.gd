class_name ProjetilKoliani
extends Area2D
## Projétil mágico da Koliani (habilidade "projetil"). Anda em linha reta
## numa das 8 direções, magoa inimigos com o mesmo dano do ataque corpo a
## corpo, e desfaz-se contra inimigos, contra o cenário, ou ao fim de algum
## tempo. Custo/energia é gerido em `koliani.gd`.

const VELOCIDADE := 540.0
## Roxo do pack das balas -- tinge o anel de impacto para o estalo casar
## com o tiro (o `Impacto` por omissão é azul, do tempo do rig "nova").
const COR := Color(0.85, 0.45, 1.0)

## As três formas que o Paulo escolheu no pack "500 Bullet 24x24 Free"
## (bloco lavanda do `Part 2C`). Cada disparo sorteia uma -- assim uma
## rajada de tiros não sai toda igual, que era o que dava ar de repetição.
## São DIRECCIONAIS: apontam para onde vão, logo não se lhes tira a rotação
## como se fazia ao orbe redondo que estava aqui antes.
const FORMAS: Array[Texture2D] = [
	preload("res://assets/sprites/pixel/fx/tiro_dardo.png"),
	preload("res://assets/sprites/pixel/fx/tiro_seta.png"),
	preload("res://assets/sprites/pixel/fx/tiro_risco.png"),
]
const FRAMES := 8

var dano := 25
var _dir := Vector2.RIGHT
var _tempo_de_vida := 2.2
var _t := 0.0
## Desfasamento do ciclo de frames, sorteado no `_ready`.
var _fase := 0.0

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
	if _corpo:
		_corpo.texture = FORMAS[randi() % FORMAS.size()]
		_corpo.hframes = FRAMES
		# arranca num frame ao acaso: dois tiros seguidos não pulsam em uníssono
		_fase = randf() * TAU


func _physics_process(dt: float) -> void:
	global_position += _dir * VELOCIDADE * dt
	_t += dt
	if _luz:
		_luz.energy = 1.8 + 0.4 * sin(_t * 20.0)  # a aura roxa "respira"
	if _corpo:
		# pulsa (o pack faz o dardo encolher a meio do ciclo e voltar);
		# a rotação é a do nó, que já aponta na direção do tiro
		_corpo.frame = int(_t * 22.0 + _fase) % FRAMES
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
	Impacto.rebentar(self, global_position, COR, 1.7)
	queue_free()
