extends Node
## Autoload "Musica": cama de música em loop. O `main.gd` chama
## `ambiente(indice_nivel)` a cada nível; os chefes chamam `boss()` quando
## a Koliani se aproxima.
##
## - Menu: `menu.wav` (lento, tema próprio).
## - Mundos 1-3: `ambiente.wav`, pitch por bioma.
## - Chefe (qualquer mundo, ao aproximar-se): `boss.wav` -- mais rápida,
##   mais alta e fantasmagórica.
## - Por baixo (exceto no chefe): `assombracao.wav` -- casa assombrada.
##
## Não recomeça a cama se já estiver a tocar a faixa certa, para não
## cortar entre recargas de cena. Tudo encaminha para o bus "Music".

const CAMINHO := "res://assets/audio/ambiente.wav"
const CAMINHO_MENU := "res://assets/audio/menu.wav"
const CAMINHO_BOSS := "res://assets/audio/boss.wav"
const CAMINHO_ASSOMBRACAO := "res://assets/audio/assombracao.wav"

## Pitch por índice de mundo (0..2): floresta, prisão, torres.
const PITCH_BIOMA := [1.0, 0.94, 1.06]
## Mundo 4 = arena do chefe final (0-indexado): já arranca em boss.
const IDX_CHEFE := 3

const VOL_CAMA := -12.0
const VOL_BOSS := -6.0
const VOL_ASSOMBRACAO := -19.0

var _p: AudioStreamPlayer       # cama principal (menu / bioma / chefe)
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


## Tema do menu inicial (lento, pad + melodia esparsa).
func menu() -> void:
	_tocar(CAMINHO_MENU, 1.0, VOL_CAMA, true)


## Cama de um mundo normal (ou boss, se for o mundo do chefe final).
func ambiente(indice_nivel: int) -> void:
	if indice_nivel >= IDX_CHEFE:
		boss()
	else:
		var pitch: float = PITCH_BIOMA[clampi(indice_nivel, 0, PITCH_BIOMA.size() - 1)]
		_tocar(CAMINHO, pitch, VOL_CAMA, true)


## Música de chefe -- chamada por `chefe_base.gd` quando a Koliani se
## aproxima do chefe (em qualquer mundo).
func boss() -> void:
	_tocar(CAMINHO_BOSS, 1.0, VOL_BOSS, false)


func parar() -> void:
	_p.stop()
	_caminho_atual = ""
	_pitch_atual = -1.0


## Troca a cama para `caminho`/`pitch`/`vol` (sem cortar se já for isso) e
## liga/desliga a camada de assombração.
func _tocar(caminho: String, pitch: float, vol: float, com_assombracao: bool) -> void:
	if _amb.stream:
		if com_assombracao and not _amb.playing:
			_amb.play()
		elif not com_assombracao and _amb.playing:
			_amb.stop()

	if _p.playing and caminho == _caminho_atual and is_equal_approx(pitch, _pitch_atual):
		return
	if not ResourceLoader.exists(caminho):
		return
	_p.stream = load(caminho)  # o loop vem do .import (edit/loop_mode=1)
	_p.pitch_scale = pitch
	_p.volume_db = vol
	_caminho_atual = caminho
	_pitch_atual = pitch
	_p.play()


func _exit_tree() -> void:
	# fecha os streams ao sair (evita "resource still in use" no shutdown)
	for pl in [_p, _amb]:
		if pl:
			pl.stop()
			pl.stream = null
