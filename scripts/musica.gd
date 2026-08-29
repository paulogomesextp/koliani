extends Node
## Autoload "Musica": cama de música em loop. O `main.gd` chama
## `ambiente(indice_nivel)` a cada nível.
##
## - Mundos 1-3: `ambiente.wav`, com o pitch a mudar por bioma.
## - Mundo 4 (chefe final Zeriko): `boss.wav` -- mais rápida, mais alta e
##   fantasmagórica.
## - Sempre por baixo (exceto no chefe): `assombracao.wav` -- ruídos de
##   casa assombrada (vento, rangidos, correntes, gemido) a complementar.
##
## Não recomeça a cama se já estiver a tocar a faixa/pitch certos, para não
## cortar entre recargas de cena. Tudo encaminha para o bus "Music".

const CAMINHO := "res://assets/audio/ambiente.wav"
const CAMINHO_BOSS := "res://assets/audio/boss.wav"
const CAMINHO_ASSOMBRACAO := "res://assets/audio/assombracao.wav"

## Pitch por índice de mundo (0..2): floresta, prisão, torres.
const PITCH_BIOMA := [1.0, 0.94, 1.06]
## Mundo 4 = chefe final (0-indexado).
const IDX_CHEFE := 3

const VOL_CAMA := -12.0
const VOL_BOSS := -6.0
const VOL_ASSOMBRACAO := -19.0

var _p: AudioStreamPlayer       # cama principal (bioma / chefe)
var _amb: AudioStreamPlayer     # camada de casa assombrada
var _caminho_atual := ""
var _pitch_atual := -1.0


func _ready() -> void:
	_p = AudioStreamPlayer.new()
	_p.bus = "Music"
	add_child(_p)

	_amb = AudioStreamPlayer.new()
	_amb.bus = "Music"
	_amb.volume_db = VOL_ASSOMBRACAO
	add_child(_amb)
	if ResourceLoader.exists(CAMINHO_ASSOMBRACAO):
		_amb.stream = load(CAMINHO_ASSOMBRACAO)
		_amb.play()


func ambiente(indice_nivel: int) -> void:
	var chefe := indice_nivel >= IDX_CHEFE
	var caminho := CAMINHO_BOSS if chefe else CAMINHO
	var pitch: float = 1.0 if chefe else PITCH_BIOMA[clampi(indice_nivel, 0, PITCH_BIOMA.size() - 1)]

	# no chefe a casa assombrada sai da frente (a faixa já é fantasmagórica)
	if _amb.stream:
		if chefe and _amb.playing:
			_amb.stop()
		elif not chefe and not _amb.playing:
			_amb.play()

	if _p.playing and caminho == _caminho_atual and is_equal_approx(pitch, _pitch_atual):
		return
	if not ResourceLoader.exists(caminho):
		return
	# o loop vem do .import (edit/loop_mode=1)
	_p.stream = load(caminho)
	_p.pitch_scale = pitch
	_p.volume_db = VOL_BOSS if chefe else VOL_CAMA
	_caminho_atual = caminho
	_pitch_atual = pitch
	_p.play()


func parar() -> void:
	_p.stop()
	_caminho_atual = ""
	_pitch_atual = -1.0


func _exit_tree() -> void:
	# fecha os streams ao sair (evita "resource still in use" no shutdown)
	for pl in [_p, _amb]:
		if pl:
			pl.stop()
			pl.stream = null
