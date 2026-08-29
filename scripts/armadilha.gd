class_name Armadilha
extends Area2D
## Base das armadilhas de cenario (espinhos, serra, fogo). Magoa a Koliani
## por contacto enquanto `ativa`. Mascara so a layer 2 (a Koliani); nao
## colide com nada, so deteta.
##
## As subclasses poem o visual e, se forem temporarias, ligam/desligam
## `ativa`. `_pronto()` e o hook de `_ready()` para elas.

@export var dano := 16
## Empurrao horizontal ao ferir. 0 = atira a Koliani para longe do centro.
@export var empurrao := 0.0

var ativa := true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_ao_tocar)
	_pronto()


## Hook para as subclasses (o `_ready` proprio fica reservado a esta base).
func _pronto() -> void:
	pass


func _ao_tocar(corpo: Node) -> void:
	_ferir(corpo)


func _ferir(corpo: Node) -> void:
	if not ativa:
		return
	if corpo is Koliani:
		var dir := empurrao
		if dir == 0.0:
			dir = signf(corpo.global_position.x - global_position.x)
			if dir == 0.0:
				dir = 1.0
		corpo.receber_dano(dano, dir)


## Re-testa quem ja esta dentro (chamar quando a armadilha "liga").
func _ferir_presentes() -> void:
	for c in get_overlapping_bodies():
		_ferir(c)
