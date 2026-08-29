extends Node
## Autoload "Musica": cama de ambiente em loop, com o pitch a mudar por
## bioma (o `main.gd` chama `ambiente(indice_nivel)` a cada nível). Um só
## `AudioStreamPlayer` persistente -- não recomeça se já estiver no pitch
## certo, para não cortar entre recargas de cena.

const CAMINHO := "res://assets/audio/ambiente.wav"
## Pitch por índice de mundo (0..3): floresta, prisão, torres, castelo.
const PITCH_BIOMA := [1.0, 0.94, 1.06, 0.86]

var _p: AudioStreamPlayer
var _pitch_atual := -1.0


func _ready() -> void:
	_p = AudioStreamPlayer.new()
	_p.volume_db = -22.0
	add_child(_p)


func ambiente(indice_nivel: int) -> void:
	var pitch: float = PITCH_BIOMA[clampi(indice_nivel, 0, PITCH_BIOMA.size() - 1)]
	if _p.playing and is_equal_approx(pitch, _pitch_atual):
		return
	if not ResourceLoader.exists(CAMINHO):
		return
	# o loop vem definido no .import (edit/loop_mode=1)
	if _p.stream == null:
		_p.stream = load(CAMINHO)
	_p.pitch_scale = pitch
	_pitch_atual = pitch
	_p.play()


func parar() -> void:
	_p.stop()
	_pitch_atual = -1.0


func _exit_tree() -> void:
	# fecha o stream ao sair (evita "resource still in use" no shutdown)
	if _p:
		_p.stop()
		_p.stream = null
