class_name TestesKolianiCanonicaNiveis
extends RefCounted
## Pre-Process 11B: a Koliani canónica (Golden Set) em TODOS os níveis.
##
## O Golden Set é opt-in por cena: sem `usar_prototipo_premium` e
## `usar_golden_set` no nó `Koliani`, `koliani.gd` cai no rig `shadowblade`
## antigo. Até 17 set 2026 só L1–L5 tinham as flags e L6–L100 mostravam o
## modelo velho sem ninguém dar por isso. Este contrato lê o `SceneState` de
## cada cena da campanha (sem instanciar, sem correr `_ready`) e falha em
## qualquer nível que perca as flags ou deixe de instanciar a Koliani normal.

const KOLIANI := "res://scenes/actors/Koliani.tscn"
const ESTADO := preload("res://scripts/estado_jogo.gd")
const FLAGS := ["usar_prototipo_premium", "usar_golden_set"]


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var niveis: Array = ESTADO.NIVEIS
	_verificar(falhas, niveis.size() == 100,
		"Koliani canónica: esperava 100 níveis, há %d" % niveis.size())
	for i in niveis.size():
		var caminho: String = niveis[i]
		var cena := load(caminho) as PackedScene
		_verificar(falhas, cena != null, "L%03d: cena não carrega (%s)" % [i + 1, caminho])
		if cena == null:
			continue
		var instancias := _instancias_koliani(cena.get_state())
		_verificar(falhas, instancias.size() == 1,
			"L%03d: esperava 1 instância de Koliani.tscn, há %d" % [i + 1, instancias.size()])
		for props: Dictionary in instancias:
			for flag: String in FLAGS:
				_verificar(falhas, props.get(flag, false) == true,
					"L%03d: Koliani sem %s = true (cai no rig shadowblade)" % [i + 1, flag])
	return falhas


## Propriedades gravadas em cada nó que instancia a Koliani.
static func _instancias_koliani(estado: SceneState) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for n in estado.get_node_count():
		var inst := estado.get_node_instance(n)
		if inst == null or inst.resource_path != KOLIANI:
			continue
		var props := {}
		for p in estado.get_node_property_count(n):
			props[str(estado.get_node_property_name(n, p))] = estado.get_node_property_value(n, p)
		resultado.append(props)
	return resultado


static func _verificar(falhas: Array[String], condicao: bool,
		mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
