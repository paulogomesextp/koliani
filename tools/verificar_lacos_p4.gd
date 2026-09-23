extends SceneTree
## SFX Overhaul Prompt 4 -- QA dos LACOS, em tempo real.
##
##   Godot_console.exe --path . --screen 1 --resolution 640x360 \
##       --script res://tools/verificar_lacos_p4.gd
##
## O `verificar_sfx_mundo.gd` prova o ROTEAMENTO dos lacos (abrem, fecham,
## respeitam o tecto). Isto prova a DURACAO, que e' outra coisa: um laço que
## abre bem pode na mesma parar sozinho ao fim da primeira volta, acumular
## players ao longo de meio minuto, ou sobreviver a um reload.
##
## Por isso aqui deixa-se mesmo correr o relogio. O bloco longo toca 32 s de
## `vento_ciclo` -- mais de cinco voltas do ciclo de 6 s -- e vai contando.
## Nao ha' atalho: o defeito que isto apanha (o laço que se cala na juncao)
## so' aparece depois da primeira volta.
##
## Corre com renderer REAL: em `--headless` o `AudioStreamPlayer.playing`
## nunca fica verdadeiro e todas as contagens dariam zero sem falhar.

const SEGUNDOS_LONGO := 32.0
## O `vento_ciclo` dura 6 s. Se o laço morresse na emenda, `playing` caia
## algures antes dos 7 s e a amostragem apanhava-o.
const AMOSTRAS_LONGO := 64

var _falhas := 0
var _som: Node


func _init() -> void:
	await process_frame
	_som = root.get_node_or_null("Som")
	_checar(_som != null, "autoload Som ausente")
	if _som == null:
		quit(1)
		return
	await _arranque_e_paragem()
	await _longa_duracao()
	await _sem_acumular()
	await _troca_de_cena()
	await _reload_da_mesma_cena()
	if ResourceLoader.exists("res://scripts/wind_zone.gd"):
		await _respawn()
	else:
		print("LACOS respawn com WindZone: omitido (sistema ausente nesta base)")
	print("LACOS FINAL falhas=%d" % _falhas)
	quit(0 if _falhas == 0 else 1)


func _arranque_e_paragem() -> void:
	var ok := bool(_som.call("laco", "vento_ciclo", -26.0, 0.0))
	_checar(ok, "o laco do vento nao arrancou")
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 1, "laco nao esta' a tocar")
	_som.call("parar_laco", "vento_ciclo", 0.0)
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 0, "o laco nao parou")
	# e o mecanismo, que tem um ciclo muito mais curto (2,4 s)
	_som.call("laco", "mecanismo_ciclo", -24.0, 0.0)
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 1, "o laco do mecanismo nao arrancou")
	_som.call("parar_laco", "mecanismo_ciclo", 0.0)
	await _assentar()
	print("LACOS arranque/paragem: vento ok, mecanismo ok")


## O teste que importa: 32 s a tocar, com a posicao de leitura observada.
## Um laco partido nao da' erro -- simplesmente cala-se na emenda -- por isso
## o que se mede e' `playing` ao longo do tempo E se a cabeca de leitura
## volta ao inicio (a prova de que deu a volta e nao ficou presa no fim).
func _longa_duracao() -> void:
	for nome: String in ["vento_ciclo", "mecanismo_ciclo"]:
		_som.call("parar_lacos", 0.0)
		await process_frame
		_som.call("laco", nome, -26.0, 0.0)
		await _assentar()
		var p := _player(nome)
		_checar(p != null, "%s: sem player" % nome)
		if p == null:
			continue
		var comprimento: float = p.stream.get_length()
		var caladas := 0
		var voltas := 0
		var anterior := -1.0
		var maximo := 0.0
		for i in AMOSTRAS_LONGO:
			await create_timer(SEGUNDOS_LONGO / float(AMOSTRAS_LONGO)).timeout
			if not is_instance_valid(p) or not p.playing:
				caladas += 1
				continue
			var pos := p.get_playback_position()
			maximo = maxf(maximo, pos)
			if anterior >= 0.0 and pos < anterior - comprimento * 0.5:
				voltas += 1  # a cabeca recuou muito -> deu a volta
			anterior = pos
		_checar(caladas == 0,
			"%s calou-se em %d de %d amostras ao longo de %.0f s"
			% [nome, caladas, AMOSTRAS_LONGO, SEGUNDOS_LONGO])
		var esperadas := int(SEGUNDOS_LONGO / comprimento) - 1
		_checar(voltas >= esperadas,
			"%s deu %d voltas em %.0f s, esperavam-se >= %d (ciclo %.2f s)"
			% [nome, voltas, SEGUNDOS_LONGO, esperadas, comprimento])
		_checar(int(_som.call("lacos_ativos")) == 1,
			"%s: numero de lacos mudou durante a corrida" % nome)
		print(("LACOS %s: %.0f s, ciclo %.2f s, voltas=%d, calado=%d, "
			+ "pos_max=%.2f") % [nome, SEGUNDOS_LONGO, comprimento, voltas,
			caladas, maximo])
	_som.call("parar_lacos", 0.0)
	await process_frame


## Pedir o MESMO laco vinte vezes nao pode criar vinte players. Era o
## vazamento obvio: uma `WindZone` com a Koliani a entrar e a sair.
func _sem_acumular() -> void:
	for _i in 20:
		_som.call("laco", "vento_ciclo", -26.0, 0.0)
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 1,
		"20 pedidos do mesmo laco deram %d players"
		% int(_som.call("lacos_ativos")))
	_checar(_filhos_audio() <= int(_som.VOZES) + int(_som.LACOS_MAX),
		"players a mais no autoload: %d (pool %d + lacos %d)"
		% [_filhos_audio(), int(_som.VOZES), int(_som.LACOS_MAX)])
	print("LACOS 20 pedidos iguais -> %d player; filhos de audio no Som=%d"
		% [int(_som.call("lacos_ativos")), _filhos_audio()])
	_som.call("parar_lacos", 0.0)
	await process_frame


func _troca_de_cena() -> void:
	var a := Node2D.new()
	root.add_child(a)
	current_scene = a
	await process_frame
	_som.call("laco", "vento_ciclo", -26.0, 0.0)
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 1, "laco nao arrancou na cena A")
	var b := Node2D.new()
	root.add_child(b)
	current_scene = b
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 0,
		"o laco sobreviveu a' troca de cena")
	_checar(_filhos_audio() == int(_som.VOZES),
		"ficaram players orfaos depois da troca: %d" % _filhos_audio())
	print("LACOS troca de cena: lacos=0, players no Som=%d (so' o pool)"
		% _filhos_audio())
	a.queue_free()
	b.queue_free()
	current_scene = null
	await process_frame


## RELOAD da mesma cena: o `current_scene` muda de instancia mas nao de
## ficheiro. E' o caso que um guarda ingenuo (comparar o CAMINHO da cena)
## deixava passar -- e ficava um laco orfao da instancia antiga.
func _reload_da_mesma_cena() -> void:
	var antes_players := _filhos_audio()
	for volta in 3:
		var cena := Node2D.new()
		cena.name = "Nivel"
		root.add_child(cena)
		current_scene = cena
		await process_frame
		_som.call("laco", "vento_ciclo", -26.0, 0.0)
		await _assentar()
		_checar(int(_som.call("lacos_ativos")) == 1,
			"volta %d: o laco nao arrancou" % volta)
		cena.queue_free()
		current_scene = null
		await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 0,
		"depois de 3 reloads ficaram %d lacos" % int(_som.call("lacos_ativos")))
	_checar(_filhos_audio() == antes_players,
		"3 reloads acumularam players: %d -> %d"
		% [antes_players, _filhos_audio()])
	print("LACOS 3 reloads: lacos=0, players %d -> %d (sem acumular)"
		% [antes_players, _filhos_audio()])


## RESPAWN: a Koliani morre e volta dentro da MESMA cena. Aqui o laco tem de
## SOBREVIVER (a cena nao mudou) e continuar a ser um so'.
func _respawn() -> void:
	var cena := Node2D.new()
	root.add_child(cena)
	current_scene = cena
	var zona = load("res://scripts/wind_zone.gd").new()
	zona.mostrar_guia = false
	cena.add_child(zona)
	await process_frame
	var k = load("res://scenes/actors/Koliani.tscn").instantiate()
	zona.call("_ao_entrar", k)
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 1, "laco nao arrancou antes do respawn")
	for _volta in 3:
		zona.call("_ao_sair", k)     # morreu
		await process_frame
		zona.call("_ao_entrar", k)   # voltou
		await _assentar()
		_checar(int(_som.call("lacos_ativos")) == 1,
			"respawn deixou %d lacos" % int(_som.call("lacos_ativos")))
	print("LACOS 3 respawns dentro da cena: lacos=%d (esperado 1)"
		% int(_som.call("lacos_ativos")))
	zona.call("_ao_sair", k)
	k.free()
	cena.queue_free()
	current_scene = null
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 0, "laco sobreviveu ao fim da cena")


# --------------------------------------------------------------- utilidades

func _player(nome: String) -> AudioStreamPlayer:
	var lacos: Dictionary = _som.get("_lacos")
	var p = lacos.get(nome)
	return p as AudioStreamPlayer if is_instance_valid(p) else null


## Quantos `AudioStreamPlayer` o autoload tem pendurados. E' a contagem que
## denuncia um vazamento mesmo que `lacos_ativos()` esteja a zero -- um
## player parado mas nao libertado nao aparece na outra conta.
func _filhos_audio() -> int:
	var n := 0
	for f in _som.get_children():
		if f is AudioStreamPlayer:
			n += 1
	return n


func _assentar() -> void:
	for _i in 4:
		await process_frame
	await create_timer(0.08).timeout


func _checar(ok: bool, mensagem: String) -> void:
	if not ok:
		_falhas += 1
		push_error("LACOS: " + mensagem)
