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

## TRILHA DE PRODUÇÃO (Execution 9H.1). Seis peças originais do projeto,
## compostas por `tools/compor_trilha_9h1.py` -- sem amostras de terceiros,
## sem licenças, sem atribuição devida (ver
## `assets/audio/musica/producao/manifesto_trilha_9h1.json`).
##
## Servem o FRONTEND e a REGIÃO I, que é a fatia que existe a sério. As
## Regiões II-XX continuam nas 20+20 faixas CC0/CC-BY: compor 38 peças para
## regiões sem arte aprovada nem playtest seria fazer número, que foi
## precisamente o que o Game Master proibiu.
const DIR_PRODUCAO := "res://assets/audio/musica/producao/"
const DIR_APROVADO := "res://assets/audio/approved/"
const MENU_APROVADO := DIR_APROVADO + "menu_cinematic_fantasy_dark_no_intro.ogg"
const REGIAO_01_APROVADA := DIR_APROVADO + "region_01_midnight_forest.mp3"
const BOSS_01_APROVADO := DIR_APROVADO + "boss_01_gothic_candlelight.mp3"
const PRODUCAO := {
	"menu": DIR_PRODUCAO + "tema_menu.wav",
	"exploracao": DIR_PRODUCAO + "regiao1_exploracao.wav",
	"combate": DIR_PRODUCAO + "regiao1_combate.wav",
	"guardiao": DIR_PRODUCAO + "regiao1_guardiao.wav",
	"coracao": DIR_PRODUCAO + "regiao1_coracao.wav",
	"pausa": DIR_PRODUCAO + "pausa_ambiente.wav",
}
## Quantos níveis usam a trilha de produção (a Região I: 1-1 a 1-5).
const NIVEIS_PRODUCAO := 5
## O nível da campanha onde está o Coração Putrefacto (1-5), que tem tema
## próprio -- é o clímax da região, não mais um guardião.
const NIVEL_CORACAO := 4
## Quanto tempo a camada de combate se mantém depois do último golpe.
const COMBATE_CAUDA := 7.0
## Duração do cruzamento entre camas. Um fade-OUT sozinho abriria um buraco
## (as camas tocam em ciclo); o que se faz é cruzar as duas.
const CRUZAR := 0.9

## 20 faixas de nível / 20 de chefe, em ciclo (ver assets/audio/CREDITS.md
## para a fonte de cada uma -- todas CC0/CC-BY do OpenGameArt).
const N_FAIXAS := 20
const PASTA_NIVEIS := "res://assets/audio/musica/niveis/nivel_%02d.ogg"
const PASTA_CHEFES := "res://assets/audio/musica/chefes/boss_%02d.ogg"

## Pitch por índice de mundo (0..3): floresta, prisão, torres, castelo.
## O castelo (mundo 4) arranca mais grave -- é a caminhada até ao Zeriko;
## a música de combate entra quando o Zeriko ataca (ver `chefe_base.gd`).
const PITCH_BIOMA := [1.0, 0.94, 1.06, 0.88]

const VOL_CAMA := -8.0
const VOL_BOSS := -6.0
const VOL_ASSOMBRACAO := -19.0

var _p: AudioStreamPlayer       # cama principal (menu / bioma / chefe)
var _p2: AudioStreamPlayer      # cama a SAIR, enquanto dura o cruzamento
var _amb: AudioStreamPlayer     # camada de ambiência do bioma
var _pausa_p: AudioStreamPlayer # ambiência do menu de pausa
## Até quando dura a camada de intensidade (segundos de relógio; 0 = fora).
var _combate_ate := 0.0
## Volume nominal da cama, para a pausa poder baixá-lo e repô-lo.
var _vol_cama_atual := VOL_CAMA
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

	_p2 = AudioStreamPlayer.new()
	_p2.bus = "Music"
	add_child(_p2)

	_pausa_p = AudioStreamPlayer.new()
	_pausa_p.bus = "Music"
	_pausa_p.volume_db = -14.0
	_pausa_p.finished.connect(func() -> void: _pausa_p.play())
	add_child(_pausa_p)

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


## Qual a cama de EXPLORAÇÃO do nível `i`. Dentro da Região I é a peça de
## produção; fora dela, a faixa do ciclo de 20.
static func faixa_de_nivel(i: int) -> String:
	if i >= 0 and i < NIVEIS_PRODUCAO and ResourceLoader.exists(REGIAO_01_APROVADA):
		return REGIAO_01_APROVADA
	if i >= 0 and i < NIVEIS_PRODUCAO and ResourceLoader.exists(PRODUCAO["exploracao"]):
		return PRODUCAO["exploracao"]
	var caminho := PASTA_NIVEIS % ((i % N_FAIXAS) + 1)
	return caminho if ResourceLoader.exists(caminho) else CAMINHO


## Qual a cama de CHEFE do nível `i`. O Coração Putrefacto (1-5) tem tema
## próprio; os outros quatro guardiões da Região I partilham o dos guardiões.
static func faixa_de_chefe(i: int) -> String:
	if i == 0 and ResourceLoader.exists(BOSS_01_APROVADO):
		return BOSS_01_APROVADO
	if i >= 0 and i < NIVEIS_PRODUCAO:
		var chave := "coracao" if i == NIVEL_CORACAO else "guardiao"
		if ResourceLoader.exists(PRODUCAO[chave]):
			return PRODUCAO[chave]
	var caminho := PASTA_CHEFES % ((i % N_FAIXAS) + 1)
	return caminho if ResourceLoader.exists(caminho) else CAMINHO_BOSS


## Tema do menu inicial (lento, pad + melodia esparsa).
func menu() -> void:
	_combate_ate = 0.0
	var cam: String = MENU_APROVADO
	if not ResourceLoader.exists(cam):
		cam = PRODUCAO["menu"]
	if not ResourceLoader.exists(cam):
		cam = CAMINHO_MENU
	_tocar(cam, 1.0, VOL_CAMA, true)


## Cama de exploração de um mundo: uma das 20 faixas de nível, em ciclo
## (`indice_nivel % N_FAIXAS`). O combate de chefe troca para `boss()` por
## cima disto; ao morrer/recarregar a cena volta-se aqui até o combate
## recomeçar.
func ambiente(indice_nivel: int) -> void:
	_combate_ate = 0.0
	_tocar(faixa_de_nivel(indice_nivel), 1.0, VOL_CAMA, true)


## Música de chefe -- chamada por `chefe_base.gd` quando o **combate
## começa** (o chefe deteta a Koliani ou troca-se o primeiro golpe). Usa o
## mesmo índice de nível que `ambiente()`, por isso o chefe de cada nível
## tem sempre a mesma faixa.
func boss() -> void:
	_combate_ate = 0.0
	_tocar(faixa_de_chefe(EstadoJogo.indice_nivel), 1.0, VOL_BOSS, false)


## Pede a faixa do chefe em SEGUNDO PLANO, para ela já estar em memória
## quando o combate começar.
##
## O `boss()` fazia `load()` da faixa no instante do primeiro golpe, na
## thread principal. Medido em `tools/bench_combate.gd` (Execution 8.1C):
## **um frame de 2006 ms** ao bater no guardião do nível 1. Era esta a
## "congelação ao acertar no chefe"; o hitstop era o menor dos dois males.
func preparar_boss() -> void:
	var caminho := faixa_de_chefe(EstadoJogo.indice_nivel)
	if ResourceLoader.exists(caminho):
		ResourceLoader.load_threaded_request(caminho)


## CAMADA DE INTENSIDADE (Execution 9H.1). O Game Master pediu, para a
## Região I, "a higher-intensity/combat layer or theme". Isto é a camada: a
## `regiao1_combate` entra quando há combate a sério e sai sozinha
## `COMBATE_CAUDA` segundos depois do último golpe.
##
## Quem chama é a Koliani (ao acertar num inimigo e ao levar dano). Fora da
## Região I não faz nada -- as outras regiões não têm peça de combate, e
## meter aqui uma faixa do ciclo de 20 seria trocar de música por trocar.
func intensificar() -> void:
	if EstadoJogo.indice_nivel >= NIVEIS_PRODUCAO:
		return
	if _caminho_atual == faixa_de_chefe(EstadoJogo.indice_nivel):
		return          # num combate de chefe manda o tema do chefe
	_combate_ate = Time.get_ticks_msec() / 1000.0 + COMBATE_CAUDA
	var cam: String = PRODUCAO["combate"]
	if _caminho_atual != cam and ResourceLoader.exists(cam):
		_tocar(cam, 1.0, VOL_CAMA + 1.0, true)


## Ambiência da pausa: baixa a cama e põe por cima a peça de pausa. Não PARA
## a cama -- pará-la e recomeçá-la ao fechar o menu punha a música de volta
## ao princípio a cada pausa.
func pausa(ligada: bool) -> void:
	if _p == null:
		return
	_p.volume_db = (_vol_cama_atual - 11.0) if ligada else _vol_cama_atual
	var cam: String = PRODUCAO["pausa"]
	if not ResourceLoader.exists(cam) or _pausa_p == null:
		return
	if ligada:
		if _pausa_p.stream == null:
			_pausa_p.stream = _carregar_loop(cam)
		_pausa_p.play()
	else:
		_pausa_p.stop()


func _process(_dt: float) -> void:
	if _combate_ate <= 0.0:
		return
	if Time.get_ticks_msec() / 1000.0 < _combate_ate:
		return
	_combate_ate = 0.0
	if _caminho_atual == PRODUCAO["combate"]:
		_tocar(faixa_de_nivel(EstadoJogo.indice_nivel), 1.0, VOL_CAMA, true)


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
	# CRUZAMENTO. Trocar `stream` a seco corta a cama a meio de um compasso, e
	# um fade-out sozinho abre um buraco (uma cama toca em ciclo, não tem fim).
	# O que se faz é pôr a cama velha no `_p2`, a descer, enquanto a nova sobe
	# no `_p`. Sem tween quando não havia nada a tocar -- não há o que cruzar.
	var cruzar := _p.playing and _caminho_atual != ""
	if cruzar:
		_p2.stream = _p.stream
		_p2.pitch_scale = _p.pitch_scale
		_p2.volume_db = _p.volume_db
		_p2.play(_p.get_playback_position())
		var t2 := create_tween()
		t2.tween_property(_p2, "volume_db", -40.0, CRUZAR)
		t2.tween_callback(_p2.stop)
	_p.stream = _carregar_loop(caminho)
	_p.pitch_scale = pitch
	_vol_cama_atual = vol
	_p.volume_db = (vol - 22.0) if cruzar else vol
	_caminho_atual = caminho
	_pitch_atual = pitch
	_p.play()
	if cruzar:
		create_tween().tween_property(_p, "volume_db", vol, CRUZAR)


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
	for pl in [_p, _p2, _amb, _pausa_p]:
		if pl:
			pl.stop()
			pl.stream = null
