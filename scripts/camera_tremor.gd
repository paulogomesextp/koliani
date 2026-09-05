extends Camera2D
## Câmara da Koliani com screen shake. `bater(forca)` mete a câmara a
## tremer; o `Tremor` (lógica pura) trata do decaimento. Fica no `offset`
## para não lutar com o `position_smoothing`.
##
## Trata também do **zoom por ecrã**. O `stretch/aspect` do projecto é
## `expand`: num telemóvel de 20:9 o viewport passa de 1280x720 para
## 1600x720 e o jogo mostra 25% mais mundo à largura -- é o "zoom out" que
## se vê no telemóvel e não se vê no executável de Windows. Aqui o zoom da
## câmara sobe na mesma proporção, portanto **vê-se sempre o mesmo mundo**
## em qualquer ecrã, e a UI continua a ter o ecrã todo para se arrumar (que
## era o que se perdia se se mexesse no `aspect` do projecto).

## O zoom desenhado na cena, a 1280x720. Tudo o resto sai daqui.
const ZOOM_BASE := Vector2(1.4, 1.4)
const REF := Vector2(1280.0, 720.0)

var _tremor := Tremor.new()


func _ready() -> void:
	_ajustar_zoom()
	get_viewport().size_changed.connect(_ajustar_zoom)


func _ajustar_zoom() -> void:
	var v := Vector2(get_viewport().get_visible_rect().size)
	if v.x <= 0.0 or v.y <= 0.0:
		return
	# `max` e não `min`: assim o mundo visível nunca é MAIOR do que a 16:9,
	# nem num ecrã mais largo (telemóvel) nem num mais alto (tablet 4:3).
	var f := maxf(v.x / REF.x, v.y / REF.y)
	zoom = ZOOM_BASE * f


func bater(forca: float) -> void:
	_tremor.bater(forca)


func _process(dt: float) -> void:
	if _tremor.ativo():
		offset = _tremor.passo(dt)
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO
