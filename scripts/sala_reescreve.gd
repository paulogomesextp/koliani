class_name SalaReescreve
extends Node2D
## O CENÁRIO REESCREVE-SE ATRÁS DELA. Nível 70, A Mente.
##
## Guarda várias versões da mesma varanda e troca de versão à medida que
## ela avança -- mas só o que já ficou **para trás** e longe. Olhar para
## trás mostra uma sala que não é a que se atravessou.
##
## As três regras que a tornam jogável, e são todas sobre o mesmo medo:
##
##  1. **a espinha nunca se reescreve.** O que muda é a varanda de cima,
##     que é rota opcional. O caminho crítico é sempre o mesmo, e por isso
##     isto não pode trancar ninguém.
##  2. **nunca se troca uma peça a menos de `folga` px dela.** Uma
##     plataforma a desaparecer debaixo dos pés não é uma mecânica, é um
##     bug com boa história.
##  3. **troca-se com um fade**, nunca de um frame para o outro -- assim
##     lê-se como o mundo a mudar e não como um erro de desenho.
##
## Quem constrói as versões é a câmara (`_f_mente` no gerador): este nó só
## sabe mostrá-las e trocá-las.

## Distância mínima entre ela e uma peça para essa peça poder mudar.
@export var folga := 320.0
## Segundos do fade de uma versão para a outra.
@export var fade := 0.5
## Segundos entre duas reescritas.
@export var intervalo := 3.0

var _versoes: Array[Node2D] = []
var _atual := 0
var _cd := 0.0
var _alvo: Node2D


## Acrescenta uma versão (um `Node2D` com as plataformas lá dentro). A
## primeira fica visível, as outras nascem apagadas e sem colisão.
func juntar_versao(n: Node2D) -> void:
	add_child(n)
	_versoes.append(n)
	var primeira := _versoes.size() == 1
	n.modulate.a = 1.0 if primeira else 0.0
	_ligar(n, primeira)


func _ligar(n: Node2D, ligada: bool) -> void:
	n.visible = true
	for f in n.get_children():
		if f is CollisionObject2D:
			f.set_deferred("process_mode",
				Node.PROCESS_MODE_INHERIT if ligada else Node.PROCESS_MODE_DISABLED)
			for c in f.get_children():
				if c is CollisionShape2D:
					c.set_deferred("disabled", not ligada)


func _process(dt: float) -> void:
	if _versoes.size() < 2:
		return
	_cd -= dt
	if _cd > 0.0:
		return
	if _alvo == null or not is_instance_valid(_alvo):
		_alvo = get_tree().get_first_node_in_group("koliani") as Node2D
		if _alvo == null:
			return
	# só se ela já estiver longe de tudo o que esta versão tem
	if _perto(_versoes[_atual]):
		return
	_cd = intervalo
	var antiga := _versoes[_atual]
	_atual = (_atual + 1) % _versoes.size()
	var nova := _versoes[_atual]
	_ligar(antiga, false)
	_ligar(nova, true)
	var t := create_tween().set_parallel(true)
	t.tween_property(antiga, "modulate:a", 0.0, fade)
	t.tween_property(nova, "modulate:a", 1.0, fade)


## Há alguma peça desta versão a menos de `folga` px dela?
func _perto(v: Node2D) -> bool:
	for f in v.get_children():
		if f is Node2D and _alvo.global_position.distance_to(
				(f as Node2D).global_position) < folga:
			return true
	return false
