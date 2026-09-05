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

## Laser roxo do pack Wenrexa "Laser2020" (CC0). E' um glow de alta
## resolucao, nao pixel-art: e' desenhado com filtro LINEAR e nao tem frames
## -- o "vivo" vem do pulsar da escala e da luz, nao de uma tira de animacao.
## Substituiu as tres formas do pack das balas a pedido do Paulo.
const CORPO: Texture2D = preload("res://assets/sprites/pixel/fx/laser_roxo.png")
## Escala de repouso; a cabeca do cometa fica com ~54 px de comprido.
const ESCALA := 0.75

var dano := 25
var _dir := Vector2.RIGHT
var _tempo_de_vida := 2.2
var _t := 0.0
## Desfasamento do pulsar, sorteado no `_ready`: dois tiros seguidos nao
## respiram em unissono.
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
	_fase = randf() * TAU
	if _corpo:
		_corpo.texture = CORPO


func _physics_process(dt: float) -> void:
	global_position += _dir * VELOCIDADE * dt
	_t += dt
	if _luz:
		_luz.energy = 1.8 + 0.4 * sin(_t * 20.0)  # a aura roxa "respira"
	if _corpo:
		# o pulsar substitui a tira de frames: a cabeça estica e encolhe ~6%
		# ao longo do tiro. A rotação é a do nó, que já aponta na direção.
		var p := 1.0 + 0.06 * sin(_t * 18.0 + _fase)
		_corpo.scale = Vector2(ESCALA * p, ESCALA / p)
	_tempo_de_vida -= dt
	if _tempo_de_vida <= 0.0:
		queue_free()


func _ao_bater(corpo: Node) -> void:
	if corpo.has_method("receber_dano") and not (corpo is Koliani):
		# `receber_tiro` em vez de `receber_dano`: é o que diz ao bicho
		# que isto veio de longe -- os incorpóreos (nível 73) só levam
		# dano por aqui. Quem não a tiver leva na mesma.
		var dir := signf(_dir.x) if _dir.x != 0.0 else 0.0
		if corpo.has_method("receber_tiro"):
			corpo.receber_tiro(dano, dir)
		else:
			corpo.receber_dano(dano, dir)
		# o tiro mágico DEIXA A ARDER -> abre janela de crítico para a espada
		if corpo.has_method("queimar"):
			corpo.queimar(2.0, maxi(2, roundi(dano * 0.14)))
		Som.toca("acerto", -9.0)
	_estoirar()


func _estoirar() -> void:
	Impacto.rebentar(self, global_position, COR, 1.7)
	queue_free()
