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
## Opt-in (N14, "sinos em sequencia" + "plataformas temporizadas"): cada
## badalada ACENDE a plataforma por estes segundos (e volta a contar se o
## sino tocar outra vez); no fim pisca e apaga-se. 0 = alterna como sempre.
@export var duracao_solida := 0.0
## Opt-in: a moldura da prancha pendurada por baixo da laje (o triangulo
## dourado das "plataformas temporizadas"). Acende e apaga com ela.
@export var textura_suporte: Texture2D
@export var escala_suporte := 1.0

## Segundos antes do fim em que a plataforma avisa (pisca).
const AVISO_FIM := 1.6

@onready var _col: CollisionShape2D = get_node_or_null("Col")

var _resta := 0.0


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	add_to_group(grupo_alternar)
	if textura_suporte:
		var vis0 := get_node_or_null("Visual")
		if vis0:
			var s := Sprite2D.new()
			s.name = "Suporte"
			s.texture = textura_suporte
			s.scale = Vector2(escala_suporte, escala_suporte)
			s.position = Vector2(0.0, tamanho.y * 0.5 + textura_suporte.get_height() * escala_suporte * 0.5 - 12.0)
			s.z_index = -1
			vis0.add_child(s)
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


## Chamado pelo `SinoTorre` a cada badalada do grupo. So' as temporizadas
## respondem (devolvem true); as outras deixam o sino alternar como sempre.
func ao_badalar() -> bool:
	if duracao_solida <= 0.0:
		return false
	_resta = duracao_solida
	_por_solida(true)
	set_process(true)
	return true


func _process(dt: float) -> void:
	if Engine.is_editor_hint():
		return
	if duracao_solida <= 0.0 or _resta <= 0.0:
		set_process(false)
		return
	_resta -= dt
	var vis := get_node_or_null("Visual") as CanvasItem
	if _resta <= 0.0:
		_por_solida(false)
		set_process(false)
	elif _resta < AVISO_FIM and vis:
		# pisca cada vez mais depressa a' medida que o tempo acaba
		var f := 6.0 + 10.0 * (1.0 - _resta / AVISO_FIM)
		vis.modulate.a = 0.45 + 0.55 * absf(cos(_resta * f))


func _por_solida(sim: bool) -> void:
	if _col:
		_col.set_deferred("disabled", not sim)
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis:
		create_tween().tween_property(vis, "modulate:a", 1.0 if sim else alpha_fantasma, 0.14)
