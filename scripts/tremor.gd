class_name Tremor
extends RefCounted
## Screen shake decaído -- lógica pura, sem nós, testável headless.
##
## `bater(forca)` dá um impulso (a força é uma amplitude em píxeis);
## `passo(dt)` por frame devolve o deslocamento a somar ao `offset` da
## câmara. A amplitude cai a um ritmo fixo até zero.

const FREQUENCIA := 32.0   # oscilações por segundo
const DECAIMENTO := 42.0   # píxeis de amplitude perdidos por segundo

var _amplitude := 0.0
var _tempo := 0.0
var _semente := 0.0


func bater(forca: float) -> void:
	_amplitude = maxf(_amplitude, forca)
	_semente = randf() * 100.0


func ativo() -> bool:
	return _amplitude > 0.0


func passo(dt: float) -> Vector2:
	if _amplitude <= 0.0:
		return Vector2.ZERO
	_tempo += dt
	_amplitude = maxf(0.0, _amplitude - DECAIMENTO * dt)
	var t := (_tempo + _semente) * FREQUENCIA
	return Vector2(sin(t), cos(t * 1.3)) * _amplitude
