class_name ZonaSemPoder
extends Area2D
## Tira-lhe UMA habilidade enquanto lá estiver dentro. Nível 98, O Coração
## de Zeriko.
##
## É a última mecânica da campanha e a única que mexe no que ela É em vez
## de mexer no cenário: a sala não fica mais difícil, ela é que fica menos.
##
## **Nunca toca no save.** A habilidade vai para
## `EstadoJogo.habilidades_suspensas`, que vive só em memória -- uma
## habilidade perdida no disco por causa de um crash dentro da sala era um
## save estragado, e isso não se arrisca no nível 98 de 100.
##
## Devolve-a à saída E no `_exit_tree` (mudar de cena, morrer, recarregar o
## nível). Se houver duas zonas encavalitadas, cada uma devolve a sua.
##
## Constrói a própria área e o próprio visual: não precisa de cena.

@export var tamanho := Vector2(500.0, 300.0)
## Qual: "salto_duplo", "dash_aereo", "escudo", "projetil",
## "escalar_paredes", "partir_paredes", "planar".
@export var habilidade := "dash_aereo"
@export var cor := Color(0.55, 0.12, 0.30, 0.16)

var _tirada := false
var _rotulo: Label


## Os autoloads vao-se buscar a `/root` e nunca pelo IDENTIFICADOR: tocar
## em `EstadoJogo`/`Textos`/`Som` pelo nome faria este script nao compilar
## em `--script`, e era a bancada (`tools/verifica_actores_novos.gd`) que
## ficava sem poder provar a coisa mais importante daqui -- que a
## habilidade volta SEMPRE. Mesma licao do `ariete.gd`.
func _auto(nome: String) -> Node:
	var a := get_tree()
	if a == null:
		return null
	return a.root.get_node_or_null("/root/%s" % nome)


func _ready() -> void:
	var col := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	col.shape = forma
	add_child(col)
	monitoring = true
	# a Koliani vive na layer 2 (ver `Armadilha`)
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	_montar_visual()


func _montar_visual() -> void:
	var campo := ColorRect.new()
	campo.color = cor
	campo.size = tamanho
	campo.position = -tamanho * 0.5
	campo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	campo.z_index = -2
	add_child(campo)
	for lado in [-1.0, 1.0]:
		var borda := ColorRect.new()
		borda.color = Color(cor.r * 1.6, cor.g * 1.6, cor.b * 1.6, 0.6)
		borda.size = Vector2(4.0, tamanho.y)
		borda.position = Vector2(lado * tamanho.x * 0.5 - 2.0, -tamanho.y * 0.5)
		borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(borda)
	# o rótulo diz QUAL é que lhe falta. Sem isto, a habilidade some-se e
	# ela só descobre a meio de um salto -- que é a definição de injustiça.
	_rotulo = Label.new()
	var textos := _auto("Textos")
	var nome := habilidade
	if textos and textos.has_method("t"):
		nome = str(textos.call("t", "hud.ability.%s" % habilidade))
	_rotulo.text = nome.to_upper()
	_rotulo.modulate = Color(1.0, 0.45, 0.55)
	_rotulo.position = Vector2(-tamanho.x * 0.5 + 12.0, -tamanho.y * 0.5 + 8.0)
	_rotulo.visible = false
	add_child(_rotulo)


func _ao_entrar(corpo: Node) -> void:
	if _tirada or not corpo.is_in_group("koliani"):
		return
	_tirada = true
	var ej := _auto("EstadoJogo")
	if ej and ej.has_method("suspender_habilidade"):
		ej.call("suspender_habilidade", habilidade)
	if _rotulo:
		_rotulo.visible = true
	var som := _auto("Som")
	if som and som.has_method("toca"):
		som.call("toca", "praga", -12.0, 0.9)


func _ao_sair(corpo: Node) -> void:
	if not _tirada or not corpo.is_in_group("koliani"):
		return
	_devolver()


func _exit_tree() -> void:
	# mudar de cena, morrer, recarregar o nível: a habilidade volta na mesma
	_devolver()


func _devolver() -> void:
	if not _tirada:
		return
	_tirada = false
	var ej := _auto("EstadoJogo")
	if ej and ej.has_method("devolver_habilidade"):
		ej.call("devolver_habilidade", habilidade)
	if _rotulo:
		_rotulo.visible = false
