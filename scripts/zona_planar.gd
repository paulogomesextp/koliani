class_name ZonaPlanar
extends Area2D
## Zona que CONCEDE o planar à Koliani enquanto ela lá está (Região II / N08,
## Ilhas Suspensas). Não desbloqueia nada nem grava no save: a habilidade
## permanente "planar" continua a abrir só no N63. Sair da zona, morrer,
## reaparecer ou mudar de cena tira o planar -- ver `koliani.gd`
## (`atualizar_planar_contextual` e o TTL de rede).
##
## Planar não é voar: a segurar saltar, a queda fica presa a
## `Movimento.VEL_PLANAR`. Nunca dá subida; a subida vem só de forças
## externas (por exemplo uma `WindZone` ascendente).

signal corpo_entrou(corpo: Node)
signal corpo_saiu(corpo: Node)

@export var tamanho := Vector2(1200.0, 900.0)
@export var ativa := true

var _corpos: Array[Node] = []


func _ready() -> void:
	add_to_group("zonas_planar")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_configurar_forma()
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func _exit_tree() -> void:
	for corpo in _corpos:
		_remover_do_corpo(corpo)
	_corpos.clear()


func _physics_process(_dt: float) -> void:
	for i in range(_corpos.size() - 1, -1, -1):
		var corpo := _corpos[i]
		if not is_instance_valid(corpo):
			_corpos.remove_at(i)
			continue
		if ativa:
			corpo.atualizar_planar_contextual(self)
		else:
			_remover_do_corpo(corpo)


## O retângulo coberto, em coordenadas globais (para testes e ferramentas).
func retangulo_global() -> Rect2:
	return Rect2(global_position - tamanho * 0.5, tamanho)


func _ao_entrar(corpo: Node) -> void:
	if not corpo.has_method("atualizar_planar_contextual") or corpo in _corpos:
		return
	_corpos.append(corpo)
	if ativa:
		corpo.atualizar_planar_contextual(self)
	corpo_entrou.emit(corpo)


func _ao_sair(corpo: Node) -> void:
	if not corpo in _corpos:
		return
	_corpos.erase(corpo)
	_remover_do_corpo(corpo)
	corpo_saiu.emit(corpo)


func _remover_do_corpo(corpo: Node) -> void:
	if is_instance_valid(corpo) and corpo.has_method("remover_planar_contextual"):
		corpo.remover_planar_contextual(self)


func _configurar_forma() -> void:
	var colisao := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao == null:
		colisao = CollisionShape2D.new()
		colisao.name = "CollisionShape2D"
		add_child(colisao)
	var retangulo := colisao.shape as RectangleShape2D
	if retangulo == null:
		retangulo = RectangleShape2D.new()
	else:
		# a forma vem partilhada da cena-base: duplicar antes de redimensionar,
		# senão todas as instâncias ficavam com o tamanho da última
		retangulo = retangulo.duplicate() as RectangleShape2D
	retangulo.size = Vector2(maxf(1.0, tamanho.x), maxf(1.0, tamanho.y))
	colisao.shape = retangulo
