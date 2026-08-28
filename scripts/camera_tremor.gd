extends Camera2D
## Câmara da Koliani com screen shake. `bater(forca)` mete a câmara a
## tremer; o `Tremor` (lógica pura) trata do decaimento. Fica no `offset`
## para não lutar com o `position_smoothing`.

var _tremor := Tremor.new()


func bater(forca: float) -> void:
	_tremor.bater(forca)


func _process(dt: float) -> void:
	if _tremor.ativo():
		offset = _tremor.passo(dt)
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO
