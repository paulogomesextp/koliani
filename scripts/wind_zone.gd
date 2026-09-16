class_name WindZone
extends Area2D
## Zona reutilizável de vento. O vento é uma força externa renovada por frame
## no corpo; nunca muda gravidade, velocidade ou habilidades globais.

signal corpo_entrou(corpo: Node)
signal corpo_saiu(corpo: Node)
signal intensidade_mudou(multiplicador: float)

enum Modo { CONTINUO, PULSADO }

@export var direcao := Vector2.RIGHT
@export_range(0.0, 10000.0, 10.0) var intensidade := 900.0
@export_range(0.0, 2000.0, 10.0) var velocidade_max := 320.0
@export var tamanho := Vector2(320.0, 160.0)
@export var ativa := true
@export var modo := Modo.CONTINUO
@export_range(0.05, 20.0, 0.05) var duracao_pulso := 1.0
@export_range(0.0, 20.0, 0.05) var intervalo_pulso := 1.0
@export_range(0.0, 20.0, 0.05) var fase_inicial := 0.0

var _corpos: Array[Node] = []
var _tempo := 0.0
var _multiplicador_externo := 1.0
var _multiplicador_emitido := -1.0


func _ready() -> void:
	add_to_group("zonas_vento")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_configurar_forma()
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	_tempo = fase_inicial


func _exit_tree() -> void:
	for corpo in _corpos:
		_remover_do_corpo(corpo)
	_corpos.clear()


func definir_multiplicador_externo(valor: float) -> void:
	_multiplicador_externo = maxf(0.0, valor)


func multiplicador_atual() -> float:
	if not ativa:
		return 0.0
	var pulso := 1.0
	if modo == Modo.PULSADO:
		var ciclo := duracao_pulso + intervalo_pulso
		pulso = 1.0 if ciclo <= 0.0 or fmod(_tempo, ciclo) < duracao_pulso else 0.0
	return pulso * _multiplicador_externo


func _physics_process(dt: float) -> void:
	_tempo += dt
	var multiplicador := multiplicador_atual()
	if not is_equal_approx(multiplicador, _multiplicador_emitido):
		_multiplicador_emitido = multiplicador
		intensidade_mudou.emit(multiplicador)
	for i in range(_corpos.size() - 1, -1, -1):
		var corpo := _corpos[i]
		if not is_instance_valid(corpo):
			_corpos.remove_at(i)
			continue
		if multiplicador <= 0.0:
			_remover_do_corpo(corpo)
		elif corpo.has_method("atualizar_vento"):
			var sentido := direcao.normalized()
			corpo.atualizar_vento(self, sentido * intensidade * multiplicador,
				velocidade_max * multiplicador)


func _ao_entrar(corpo: Node) -> void:
	if not corpo.has_method("atualizar_vento") or corpo in _corpos:
		return
	_corpos.append(corpo)
	corpo_entrou.emit(corpo)


func _ao_sair(corpo: Node) -> void:
	_corpos.erase(corpo)
	_remover_do_corpo(corpo)
	corpo_saiu.emit(corpo)


func _remover_do_corpo(corpo: Node) -> void:
	if is_instance_valid(corpo) and corpo.has_method("remover_vento"):
		corpo.remover_vento(self)


func _configurar_forma() -> void:
	var colisao := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao == null:
		colisao = CollisionShape2D.new()
		colisao.name = "CollisionShape2D"
		add_child(colisao)
	var retangulo := colisao.shape as RectangleShape2D
	if retangulo == null:
		retangulo = RectangleShape2D.new()
		colisao.shape = retangulo
	retangulo.size = Vector2(maxf(1.0, tamanho.x), maxf(1.0, tamanho.y))
