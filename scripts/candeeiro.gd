class_name Candeeiro
extends Node2D
## Fonte de luz de cenário. O Paulo queixou-se de que "o jogo está um bocado
## escuro no geral" e pediu "candeeiros ou lâmpadas a acompanhar os níveis" --
## isto é o prop que dá essa luz. Quem os espalha pelo nível é o
## `nivel_com_chefe.gd::_iluminar`, depois de a jornada estar montada.
##
## Dois feitios (`tipo`), os dois com a MESMA luz por trás:
##   "candeeiro" -- poste gótico de três lanternas (GothicVania Town). Fica
##                  de pé em cima das plataformas largas.
##   "tocha"     -- chama de parede animada, 4 frames (Cold Corridors).
##                  Encosta-se à face vertical das plataformas altas.
##
## Não tem colisão nem lógica de jogo: é decoração que ilumina.

const TEX_CANDEEIRO := preload("res://assets/sprites/pixel/props/candeeiro.png")
const TEX_TOCHA := preload("res://assets/sprites/pixel/props/tocha.png")
const FRAMES_TOCHA := 4
## Cadência da chama. As tochas do pack são de 4 frames a ~8 fps.
const FPS_TOCHA := 8.0
## Escala do ponto de brilho (o degradé tem 256 px, isto dá ~28 px).
const BRILHO_ESC := 0.11

## "candeeiro" | "tocha".
@export var tipo := "candeeiro" : set = _set_tipo
## Cor da luz. Âmbar quente por omissão: as regiões são roxas/azuis e o
## contraste quente/frio é o que faz a luz LER-SE (é o que o Dead Cells faz).
@export var cor := Color(1.0, 0.76, 0.45)
## Multiplica o alcance da luz (1.0 = ~230 px de raio).
@export_range(0.2, 4.0) var alcance := 1.0
## Força da luz em repouso. Acima de ~1.0 a luz deixa de ser uma poça e
## passa a lavar a região inteira de âmbar (apanhado a olho no N1).
@export_range(0.0, 3.0) var forca := 1.0
## Quanto é que a chama tremeluz (0 = luz fixa).
@export_range(0.0, 1.0) var tremeluzir := 0.35
## Espelha o sprite -- para as tochas encostadas à parede da direita.
@export var virado := false : set = _set_virado

var _t := 0.0
## Desfasamento do tremeluzir: duas luzes lado a lado nunca piscam a par.
var _fase := 0.0

@onready var _corpo: Sprite2D = $Corpo
@onready var _luz: PointLight2D = $Luz
@onready var _brilho: Sprite2D = $Brilho


func _ready() -> void:
	_fase = randf() * TAU
	_set_tipo(tipo)
	_set_virado(virado)
	if _luz:
		_luz.color = cor
		_luz.scale = Vector2(alcance, alcance) * 1.6
	if _brilho:
		# ponto de brilho na lanterna, NÃO um halo -- com escala 0.3 saía um
		# ovo de névoa de 77 px que tapava o próprio candeeiro
		_brilho.modulate = Color(cor.r, cor.g, cor.b, 0.34)


func _process(dt: float) -> void:
	_t += dt
	# duas sinusóides desencontradas: dá um tremeluzir irregular sem precisar
	# de ruído nem de sortear todos os frames
	var f := 0.62 * sin(_t * 7.3 + _fase) + 0.38 * sin(_t * 17.1 + _fase * 1.7)
	if _luz:
		_luz.energy = forca * (1.0 + tremeluzir * 0.28 * f)
	if _brilho:
		_brilho.scale = Vector2.ONE * BRILHO_ESC * (1.0 + tremeluzir * 0.12 * f)
	if _corpo and tipo == "tocha":
		_corpo.frame = int(_t * FPS_TOCHA) % FRAMES_TOCHA


func _set_tipo(v: String) -> void:
	tipo = v
	# NB: `is_node_ready()` só passa a true DEPOIS de `_ready` acabar, por
	# isso não serve de guarda aqui -- era ela que impedia a tocha de ser
	# montada. O que interessa é os `@onready` já estarem preenchidos.
	if _corpo == null:
		return
	if tipo == "tocha":
		_corpo.texture = TEX_TOCHA
		_corpo.hframes = FRAMES_TOCHA
		_corpo.scale = Vector2(1.6, 1.6)
		# a chama assenta pela BASE (o cabo encosta à parede)
		_corpo.offset = Vector2(0.0, -TEX_TOCHA.get_height() * 0.5)
		if _brilho:
			_brilho.position = Vector2(0.0, -30.0)
	else:
		_corpo.texture = TEX_CANDEEIRO
		_corpo.hframes = 1
		_corpo.scale = Vector2(0.8, 0.8)
		# o poste assenta pelo pé
		_corpo.offset = Vector2(0.0, -TEX_CANDEEIRO.get_height() * 0.5)
		if _brilho:
			_brilho.position = Vector2(0.0, -74.0)
	if _luz:
		_luz.position = _brilho.position if _brilho else Vector2.ZERO


func _set_virado(v: bool) -> void:
	virado = v
	if _corpo:
		_corpo.scale.x = -absf(_corpo.scale.x) if virado else absf(_corpo.scale.x)
