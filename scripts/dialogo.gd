extends Node
## Autoload "Dialogo": corre uma sequência de falas num balão moderno por
## cima da cena atual. Usar com `await`:
##
##   await Dialogo.correr([
##       { "quem": "boss.zeriko", "texto": "dlg.zeriko.intro.1" },
##       { "quem": "dlg.speaker.koliani", "texto": "dlg.zeriko.intro.2" },
##   ])
##
## Cada fala é `{ "quem": <chave i18n>, "texto": <chave i18n> }` e pode ter
## `"alvo": Node2D` para a cauda do balão apontar a esse nó. `pausar` (por
## omissão true) congela a árvore enquanto o balão está no ecrã.

const CENA_BALAO := preload("res://scenes/ui/Balao.tscn")

## true enquanto há um balão no ecrã (os chefes verificam para não
## dispararem falas a dobrar).
var ativo := false


func correr(falas: Array, pausar := true) -> void:
	if falas.is_empty():
		return
	ativo = true
	var balao: Balao = CENA_BALAO.instantiate()
	get_tree().root.add_child(balao)
	await balao.reproduzir(falas, pausar)
	ativo = false
