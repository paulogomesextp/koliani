@tool
class_name PlataformaSino
extends "res://scripts/plataforma.gd"
## Plataforma que começa "fantasma" (sem colisão, contorno ténue) e só fica
## sólida quando um `SinoTorre` do mesmo `alterna_grupo` é tocado -- ver
## `SinoTorre.tocar()` / `_alternar()`, que já sabe alternar qualquer nó do
## grupo "sino_alterna" (só olha para os filhos "Col"/"Visual", quaisquer que
## sejam). Mecânica partilhada: reaproveita `Plataforma` (tiles, colisão, API
## `tamanho`) e só acrescenta o estado inicial fantasma + o grupo.
##
## Auditoria N11 (Região III, Torre dos Ecos): o grupo "sino_alterna" já
## existia no `SinoTorre` mas NENHUM nível o usava -- os sinos só congelavam
## inimigos, nunca mexiam no cenário. Esta é a primeira plataforma que o liga
## a sério, para o primeiro sino ter uma consequência óbvia e imediata.

## Alpha do contorno enquanto fantasma (antes do primeiro toque do sino).
@export var alpha_fantasma := 0.16
## Grupo que o sino desta secção usa (ver `SinoTorre.alterna_grupo`). Sinos
## diferentes do mesmo nível podem controlar secções diferentes -- basta
## combinar este campo com o `alterna_grupo` do `SinoTorre` certo.
@export var grupo_alternar := "sino_alterna"
## Opt-in (N13, pontes reconfiguraveis): comeca SOLIDA em vez de fantasma --
## a primeira badalada/alavanca e' que a faz sumir.
@export var comeca_solida := false

@onready var _col: CollisionShape2D = get_node_or_null("Col")


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	add_to_group(grupo_alternar)
	if comeca_solida:
		# a cena traz o `Col` desligado e o `Visual` tenue: acender os dois
		if _col:
			_col.set_deferred("disabled", false)
		var v := get_node_or_null("Visual") as CanvasItem
		if v:
			v.modulate = Color(1, 1, 1, 1)
		return
	if _col:
		_col.set_deferred("disabled", true)
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis:
		vis.modulate.a = alpha_fantasma
