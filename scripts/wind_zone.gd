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
## Guia mecânica provisória: linhas/setas deixam direção e pulso legíveis sem
## depender de arte ou SFX finais. Pode ser desligada por instância.
@export var mostrar_guia := true
@export var cor_guia := Color(0.72, 0.88, 1.0, 0.42)

## Nome do laco ambiental partilhado por TODAS as zonas de vento. E' um so'
## canal de proposito: dez zonas no mesmo nivel nao sao dez ventos, sao um
## vento -- e o `Som.laco` sabe que pedir o mesmo nome duas vezes nao abre um
## segundo player.
const LACO_VENTO := "vento_ciclo"
## Segundos entre rajadas de ENTRADA para o mesmo corpo. Sem isto, andar em
## cima da fronteira (ou um salto rente a` borda, que bate
## `body_exited`+`body_entered` no mesmo par de frames) disparava a rajada
## dezenas de vezes por segundo.
const RECARGA_RAJADA := 1.2

var _corpos: Array[Node] = []
var _tempo := 0.0
var _multiplicador_externo := 1.0
var _multiplicador_emitido := -1.0
var _guia: Node2D
var _som: Node
## Quem a rajada de entrada ja' saudou, e ate' quando (segundos de jogo).
## Por CORPO e nao por zona: a Koliani a entrar e um inimigo a entrar sao
## dois eventos diferentes.
var _saudados := {}
var _laco_pedido := false


func _ready() -> void:
	add_to_group("zonas_vento")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_configurar_forma()
	_montar_guia()
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	_tempo = fase_inicial
	# pelo CAMINHO e nao pelo identificador global, para a classe continuar a
	# compilar em `--script` (onde os autoloads nao existem)
	_som = get_node_or_null("/root/Som")


func _exit_tree() -> void:
	for corpo in _corpos:
		_remover_do_corpo(corpo)
	_corpos.clear()
	_parar_ambiente()


func definir_multiplicador_externo(valor: float) -> void:
	_multiplicador_externo = maxf(0.0, valor)


## Muda o sentido do vento em runtime e redesenha a guia (as setas ficariam
## a apontar para o lado antigo). Aditivo: as cenas que nunca chamam isto
## comportam-se exatamente como antes. Usado pelo Guardião dos Céus (N10),
## que vira o vento da arena durante o combate.
func definir_direcao(nova: Vector2) -> void:
	if nova.is_zero_approx():
		return
	if direcao.normalized().is_equal_approx(nova.normalized()):
		return
	direcao = nova
	if _guia:
		remove_child(_guia)
		_guia.queue_free()
		_guia = null
		_montar_guia()


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
	if _guia:
		_guia.modulate.a = multiplicador
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
	_rajada(corpo)
	_pedir_ambiente()
	corpo_entrou.emit(corpo)


func _ao_sair(corpo: Node) -> void:
	_corpos.erase(corpo)
	_remover_do_corpo(corpo)
	if _corpos.is_empty():
		_parar_ambiente()
	corpo_saiu.emit(corpo)


# --------------------------------------------------------------------- som
#
# Duas coisas SEPARADAS, como pede a Fase 2 do briefing:
#
#   AMBIENTE  o laco `vento_ciclo`, -26 dB, abaixo dos passos (-16,3). Nao
#             comunica nada; so' diz que ha' ar a mexer. Um laco, nunca um
#             one-shot repetido.
#   GAMEPLAY  a rajada `vento_rajada`, uma vez por entrada e por corpo, com
#             recarga. Diz "a zona apanhou-te". Deliberadamente escura e sem
#             transiente duro para nao se ler como ataque de chefe.
#
# A zona PULSADA nao toca nada nas suas transicoes: ja' e' o vento a ligar e
# desligar, e um som por pulso a cada segundo era exactamente o spam que a
# Fase 2 manda evitar. O que pulsa le^-se pela guia visual e pelo empurrao.

func _rajada(corpo: Node) -> void:
	if _som == null or not _som.has_method("toca"):
		return
	if not ativa or multiplicador_atual() <= 0.0:
		return  # zona desligada / a meio do intervalo do pulso: nao ha' o que anunciar
	var agora := Time.get_ticks_msec() * 0.001
	var id := corpo.get_instance_id()
	if agora < float(_saudados.get(id, 0.0)):
		return
	_saudados[id] = agora + RECARGA_RAJADA
	# a recarga vive TAMBEM no `Som`, com chave por corpo: duas zonas coladas
	# uma a` outra sao duas instancias e cada uma so' conhece o seu dicionario
	_som.call("toca", "vento_rajada", -13.0, 1.0, 0.06,
		RECARGA_RAJADA, "vento_rajada_%d" % id)


func _pedir_ambiente() -> void:
	if _laco_pedido or _som == null or not _som.has_method("laco"):
		return
	_laco_pedido = _som.call("laco", LACO_VENTO, -26.0, 0.9)


## Fecha o ambiente -- mas so' se mais nenhuma zona do nivel o quiser. O laco
## e' UM para todas as zonas (ver `LACO_VENTO`), por isso a ultima a esvaziar
## e' que o apaga; sem esta conta, atravessar a primeira de tres zonas
## coladas calava o vento das outras duas.
func _parar_ambiente() -> void:
	if not _laco_pedido:
		return
	_laco_pedido = false
	if _som == null or not _som.has_method("parar_laco"):
		return
	if not is_inside_tree():
		_som.call("parar_laco", LACO_VENTO, 0.0)
		return
	for outra in get_tree().get_nodes_in_group("zonas_vento"):
		if outra != self and is_instance_valid(outra) and outra.get("_laco_pedido"):
			return
	_som.call("parar_laco", LACO_VENTO, 0.8)


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
	else:
		# O Godot PARTILHA os sub-recursos entre instancias da mesma
		# PackedScene, e a `WindZone.tscn` traz o `RectangleShape2D` como
		# sub-recurso. Sem esta copia, redimensionar aqui mexia na forma de
		# TODAS as zonas da cena e so' sobrevivia o tamanho da ultima a
		# arrancar -- em N09 as tres zonas ficavam com 300x220 em vez dos
		# 680x240 / 650x270 desenhados. Copiar por instancia e' generico:
		# nao sabe de niveis nem de tamanhos, e as cenas que ja' davam forma
		# propria a cada zona (N08, N10) ficam exatamente como estavam.
		retangulo = retangulo.duplicate() as RectangleShape2D
	colisao.shape = retangulo
	retangulo.size = Vector2(maxf(1.0, tamanho.x), maxf(1.0, tamanho.y))


func _montar_guia() -> void:
	if not mostrar_guia:
		return
	_guia = Node2D.new()
	_guia.name = "GuiaVento"
	_guia.z_index = -1
	add_child(_guia)
	var sentido := direcao.normalized()
	if sentido.is_zero_approx():
		sentido = Vector2.RIGHT
	var transversal_dir := Vector2(-sentido.y, sentido.x)
	var comprimento := absf(sentido.x) * tamanho.x + absf(sentido.y) * tamanho.y
	var transversal := absf(transversal_dir.x) * tamanho.x \
		+ absf(transversal_dir.y) * tamanho.y
	var quantidade := clampi(int(transversal / 52.0), 3, 8)
	var meio := maxf(18.0, comprimento * 0.32)
	for i in quantidade:
		var faixa := Line2D.new()
		faixa.name = "Faixa%d" % (i + 1)
		faixa.width = 2.0
		faixa.default_color = cor_guia
		faixa.points = PackedVector2Array([-sentido * meio, sentido * meio])
		var t := (float(i) + 0.5) / float(quantidade) - 0.5
		faixa.position = transversal_dir * transversal * t
		_guia.add_child(faixa)
		var seta := Polygon2D.new()
		var ponta := sentido * meio
		var base := ponta - sentido * 11.0
		seta.polygon = PackedVector2Array([
			ponta, base + transversal_dir * 4.5, base - transversal_dir * 4.5])
		seta.color = cor_guia
		faixa.add_child(seta)
