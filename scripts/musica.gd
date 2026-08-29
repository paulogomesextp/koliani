extends Node
## Autoload "Musica": cama de música em loop. O `main.gd` chama
## `ambiente(indice_nivel)` a cada nível; os chefes chamam `boss()` quando
## a Koliani se aproxima.
##
## - Menu: `menu.wav` (lento, tema próprio).
## - Mundos 1-4: `ambiente.wav`, pitch por bioma (o mundo 4 arranca numa
##   cama mais grave -- a aproximação ao Zeriko, ainda sem combate).
## - Chefe (qualquer mundo): `boss.wav` -- mais rápida, mais alta e
##   fantasmagórica. Só entra quando o **combate começa** (o chefe deteta a
##   Koliani / troca o primeiro golpe), NÃO só por o ver. Cada chefe chama
##   `Musica.boss()` via `ChefeBase.provocar()`.
## - Por baixo (exceto no chefe): `assombracao.wav` -- casa assombrada.
##
## Não recomeça a cama se já estiver a tocar a faixa certa, para não
## cortar entre recargas de cena. Tudo encaminha para o bus "Music".

const CAMINHO := "res://assets/audio/ambiente.wav"
const CAMINHO_MENU := "res://assets/audio/menu.wav"
const CAMINHO_BOSS := "res://assets/audio/boss.wav"
const CAMINHO_ASSOMBRACAO := "res://assets/audio/assombracao.wav"

## Pitch por índice de mundo (0..3): floresta, prisão, torres, castelo.
## O castelo (mundo 4) arranca mais grave -- é a caminhada até ao Zeriko;
## a música de combate entra quando o Zeriko ataca (ver `chefe_base.gd`).
const PITCH_BIOMA := [1.0, 0.94, 1.06, 0.88]

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
	# rede de segurança: se por alguma razão a cama não estiver marcada como
	# loop no import, volta a tocá-la ao terminar (a cama nunca é one-shot).
	_p.finished.connect(func() -> void:
		if _caminho_atual != "":
			_p.play())
	add_child(_p)

	_amb = AudioStreamPlayer.new()
	_amb.bus = "Music"
	_amb.volume_db = VOL_ASSOMBRACAO
	_amb.finished.connect(func() -> void: _amb.play())
	add_child(_amb)
	if ResourceLoader.exists(CAMINHO_ASSOMBRACAO):
		_amb.stream = _carregar_loop(CAMINHO_ASSOMBRACAO)
		_amb.play()


## Tema do menu inicial (lento, pad + melodia esparsa).
func menu() -> void:
	_tocar(CAMINHO_MENU, 1.0, VOL_CAMA, true)


## Cama de exploração de um mundo (pitch por bioma). O combate de chefe
## troca para `boss()` por cima disto; ao morrer/recarregar a cena volta-se
## aqui até o combate recomeçar.
func ambiente(indice_nivel: int) -> void:
	var pitch: float = PITCH_BIOMA[clampi(indice_nivel, 0, PITCH_BIOMA.size() - 1)]
	_tocar(CAMINHO, pitch, VOL_CAMA, true)


## Música de chefe -- chamada por `chefe_base.gd` quando o **combate
## começa** (o chefe deteta a Koliani ou troca-se o primeiro golpe).
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
	_p.stream = _carregar_loop(caminho)
	_p.pitch_scale = pitch
	_p.volume_db = vol
	_caminho_atual = caminho
	_pitch_atual = pitch
	_p.play()


## Carrega um .wav e força o loop no próprio recurso. Em 4.7.2 o
## `edit/loop_mode` do .import NÃO chega ao AudioStreamWAV (vem sempre
## LOOP_DISABLED), por isso marca-se aqui, do início ao fim do sample.
func _carregar_loop(caminho: String) -> AudioStream:
	var st: AudioStream = load(caminho)
	if st is AudioStreamWAV:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(round(st.get_length() * st.mix_rate))
	return st


func _exit_tree() -> void:
	# fecha os streams ao sair (evita "resource still in use" no shutdown)
	for pl in [_p, _amb]:
		if pl:
			pl.stop()
			pl.stream = null
