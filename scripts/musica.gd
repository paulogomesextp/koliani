extends Node
## Autoload "Musica": cama de música em loop. O `main.gd` chama
## `ambiente(indice_nivel)` a cada nível; os chefes chamam `boss()` quando
## a Koliani se aproxima.
##
## - Menu: `menu.wav` (lento, tema próprio).
## - Níveis: 20 faixas em `assets/audio/musica/niveis/` (`indice_nivel % 20`,
##   pedido do Paulo a 3 set 2026 -- antes só havia uma faixa `bg_niveis.mp3`
##   para os 30+ níveis). O nível 21 volta à faixa do nível 1.
## - Chefe (qualquer mundo): 20 faixas em `assets/audio/musica/chefes/`
##   (mesmo `indice_nivel % 20`, para o chefe de cada nível ter sempre a
##   mesma faixa). Só entra quando o **combate começa** (o chefe deteta a
##   Koliani / troca o primeiro golpe), NÃO só por o ver. Cada chefe chama
##   `Musica.boss()` via `ChefeBase.provocar()`.
## - Por baixo (exceto no chefe): `assombracao.wav` -- casa assombrada.
##
## Não recomeça a cama se já estiver a tocar a faixa certa, para não
## cortar entre recargas de cena. Tudo encaminha para o bus "Music".

## Cama do menu, fornecida pelo Paulo (OneCinematicStudio -- ver
## assets/audio/CREDITS.md). `CAMINHO`/`CAMINHO_BOSS` (únicas, antigas)
## ficam de reserva -- usadas se por algum motivo as 20 faixas não
## existirem (fresh checkout antes do `--import`, por ex.).
const CAMINHO := "res://assets/audio/bg_niveis.mp3"       # "Shadow of the Forsaken"
const CAMINHO_MENU := "res://assets/audio/bg_menu.mp3"    # "The Alchemist's Library"
const CAMINHO_BOSS := "res://assets/audio/bg_boss.mp3"    # "Final Battle II" (Nyxaurora)
const CAMINHO_ASSOMBRACAO := "res://assets/audio/assombracao.wav"
## Execution 9H: ambiência própria da Região I -- vento nas folhas, água ao
## longe e um bordão de corrupção. A `assombracao` é uma casa assombrada
## (rangidos, correntes) e nunca foi uma floresta; nos cinco primeiros
## níveis é esta que toca por baixo da música.
const CAMINHO_AMB_FLORESTA := "res://assets/audio/ambiente_floresta.wav"
## Quantos níveis da campanha usam a ambiência de floresta (a Região I).
const NIVEIS_FLORESTA := 5

## 20 faixas de nível / 20 de chefe, em ciclo (ver assets/audio/CREDITS.md
## para a fonte de cada uma -- todas CC0/CC-BY do OpenGameArt).
const N_FAIXAS := 20
const PASTA_NIVEIS := "res://assets/audio/musica/niveis/nivel_%02d.ogg"
const PASTA_CHEFES := "res://assets/audio/musica/chefes/boss_%02d.ogg"

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
var _web_audio_callback: JavaScriptObject
var _web_reinicio_agendado := false


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
	_escolher_ambiencia()
	if _amb.stream:
		_amb.play()
	if OS.has_feature("web"):
		# O Safari pode descartar uma faixa iniciada antes do primeiro gesto,
		# embora o AudioStreamPlayer continue a declarar `playing = true`.
		# O bootstrap HTML chama este callback depois de abrir o AudioContext.
		_web_audio_callback = JavaScriptBridge.create_callback(_ao_audio_web_pronto)
		JavaScriptBridge.get_interface("window").kolianiGodotAudioReady = _web_audio_callback


func _ao_audio_web_pronto(_args: Array) -> void:
	if _web_reinicio_agendado:
		return
	_web_reinicio_agendado = true
	call_deferred("_reiniciar_audio_web")


func _reiniciar_audio_web() -> void:
	# Dá ao WebKit um instante para concluir também a abertura do canal HTML
	# multimédia antes de voltar a agendar as fontes do Godot.
	await get_tree().create_timer(0.12, true, false, true).timeout
	_web_reinicio_agendado = false
	if _p and _p.stream and _caminho_atual != "":
		_p.stop()
		_p.play()
	if _amb and _amb.stream and not _amb.playing:
		_amb.play()


## Tema do menu inicial (lento, pad + melodia esparsa).
func menu() -> void:
	_tocar(CAMINHO_MENU, 1.0, VOL_CAMA, true)


## Cama de exploração de um mundo: uma das 20 faixas de nível, em ciclo
## (`indice_nivel % N_FAIXAS`). O combate de chefe troca para `boss()` por
## cima disto; ao morrer/recarregar a cena volta-se aqui até o combate
## recomeçar.
func ambiente(indice_nivel: int) -> void:
	var caminho := PASTA_NIVEIS % ((indice_nivel % N_FAIXAS) + 1)
	if not ResourceLoader.exists(caminho):
		caminho = CAMINHO  # reserva: fresh checkout antes do --import
	_tocar(caminho, 1.0, VOL_CAMA, true)


## Música de chefe -- chamada por `chefe_base.gd` quando o **combate
## começa** (o chefe deteta a Koliani ou troca-se o primeiro golpe). Usa o
## mesmo índice de nível que `ambiente()`, por isso o chefe de cada nível
## tem sempre a mesma faixa.
func boss() -> void:
	var caminho := PASTA_CHEFES % ((EstadoJogo.indice_nivel % N_FAIXAS) + 1)
	if not ResourceLoader.exists(caminho):
		caminho = CAMINHO_BOSS  # reserva: fresh checkout antes do --import
	_tocar(caminho, 1.0, VOL_BOSS, false)


## Pede a faixa do chefe em SEGUNDO PLANO, para ela já estar em memória
## quando o combate começar.
##
## O `boss()` fazia `load()` da faixa no instante do primeiro golpe, na
## thread principal. Medido em `tools/bench_combate.gd` (Execution 8.1C):
## **um frame de 2006 ms** ao bater no guardião do nível 1. Era esta a
## "congelação ao acertar no chefe"; o hitstop era o menor dos dois males.
func preparar_boss() -> void:
	var caminho := PASTA_CHEFES % ((EstadoJogo.indice_nivel % N_FAIXAS) + 1)
	if not ResourceLoader.exists(caminho):
		caminho = CAMINHO_BOSS
	if ResourceLoader.exists(caminho):
		ResourceLoader.load_threaded_request(caminho)


func parar() -> void:
	_p.stop()
	_caminho_atual = ""
	_pitch_atual = -1.0


## Troca a cama para `caminho`/`pitch`/`vol` (sem cortar se já for isso) e
## liga/desliga a camada de assombração.
func _tocar(caminho: String, pitch: float, vol: float, com_assombracao: bool) -> void:
	_escolher_ambiencia()
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


## Qual a cama de ambiência para o sítio onde se está. Troca-se só quando
## muda mesmo (um `stream =` novo reinicia a reprodução, e ouvia-se o
## corte a cada mudança de faixa).
var _amb_caminho := ""


func _escolher_ambiencia() -> void:
	var quer := CAMINHO_AMB_FLORESTA if EstadoJogo.indice_nivel < NIVEIS_FLORESTA 		else CAMINHO_ASSOMBRACAO
	if not ResourceLoader.exists(quer):
		quer = CAMINHO_ASSOMBRACAO
	if quer == _amb_caminho or not ResourceLoader.exists(quer):
		return
	var tocava := _amb.playing
	_amb.stream = _carregar_loop(quer)
	_amb_caminho = quer
	if tocava:
		_amb.play()


## Carrega um .wav e força o loop no próprio recurso. Em 4.7.2 o
## `edit/loop_mode` do .import NÃO chega ao AudioStreamWAV (vem sempre
## LOOP_DISABLED), por isso marca-se aqui, do início ao fim do sample.
func _carregar_loop(caminho: String) -> AudioStream:
	var st: AudioStream = load(caminho)
	if st is AudioStreamWAV:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(round(st.get_length() * st.mix_rate))
	elif st is AudioStreamMP3 or st is AudioStreamOggVorbis:
		st.loop = true
	return st


func _exit_tree() -> void:
	# fecha os streams ao sair (evita "resource still in use" no shutdown)
	for pl in [_p, _amb]:
		if pl:
			pl.stop()
			pl.stream = null
