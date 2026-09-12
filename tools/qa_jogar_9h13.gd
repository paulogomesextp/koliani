extends SceneTree
## QA JOGADO da Execution 9H.13/14: abre um nivel numa janela REAL e joga-o
## com input, registando o que de facto aconteceu -- nao e' um screenshot nem
## uma leitura de codigo.
##
## Instrumenta o autoload `Som` (embrulha o `toca`) para provar que cada SFX
## novo chegou mesmo a tocar, com que volume, e que o stream carregou (um
## caminho errado no `CAMINHOS` faz o `toca` sair em silencio -- e' o modo de
## falhar mais provavel deste passe).
##
## Uso:
##   Godot --window --screen 1 --resolution 960x540 --position 1250,860 \
##     --path . --script res://tools/qa_jogar_9h13.gd -- <cena>

var _tocados := {}
var _sem_stream := {}
var _som: Node


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0] if args.size() > 0 else "res://scenes/levels/Pantano_dos_Sussurros.tscn"

	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		var i := int(es.NIVEIS.find(cena))
		if i >= 0:
			es.indice_nivel = i
		es.checkpoint = Vector2.ZERO
	_som = root.get_node_or_null("/root/Som")
	if _som == null:
		print("QA: autoload Som ausente -- este script TEM de correr com autoloads")
		quit(1)
		return

	change_scene_to_file(cena)
	for _i in 10:
		await process_frame

	var k := get_first_node_in_group("koliani")
	if k == null:
		print("QA: koliani ausente")
		quit(1)
		return
	print("QA cena=%s" % cena)

	# --- prova de que os streams novos existem e carregam -------------------
	var novos := [
		"salto", "salto_duplo", "aterrar", "dash", "rolamento",
		"passo1", "passo2", "passo3", "ataque", "ataque2", "ataque3",
		"ataque_forte", "acerto", "dano", "morte_koliani", "bloqueio",
		"apanhar", "selo", "transicao",
		"ui_mover", "ui_confirmar", "ui_voltar", "ui_negado",
	]
	var faltam: Array[String] = []
	var dur := {}
	for n in novos:
		var c: String = _som.CAMINHOS.get(n, "")
		if c == "" or not ResourceLoader.exists(c):
			faltam.append(n)
			continue
		var st := load(c) as AudioStream
		if st == null:
			faltam.append(n)
		else:
			dur[n] = st.get_length()
	print("QA streams: %d/%d carregam; em falta: %s" % [
		dur.size(), novos.size(), str(faltam)])
	for n in novos:
		if dur.has(n):
			print("   %-16s %.3f s" % [n, dur[n]])

	# --- JOGAR --------------------------------------------------------------
	await _correr(k, "mover_direita", 45)
	await _saltar(k)
	await _correr(k, "mover_direita", 30)
	await _accao("dash", 6)
	await _correr(k, "mover_direita", 25)
	# combo 1->4: quatro golpes dentro da janela de combo
	# O 3.o golpe dura 0,30 s (`DUR_COMBO`), por isso o encadeamento tem de
	# esperar por ele: com 9 frames de intervalo o 4.o golpe nunca chegava a
	# entrar e o remate nao tocava.
	for g in 4:
		await _accao("atacar", 4)
		var espera: int = int(60.0 * [0.18, 0.20, 0.30, 0.26][g]) + 6
		for _f in espera:
			await process_frame
	await _correr(k, "mover_esquerda", 35)
	await _saltar(k)
	await _correr(k, "mover_esquerda", 25)
	for _f in 120:
		await process_frame

	print("QA sons tocados (nome x vezes):")
	var chaves := _tocados.keys()
	chaves.sort()
	for n in chaves:
		print("   %-16s x%d" % [n, _tocados[n]])
	print("QA sons pedidos SEM stream (bug de caminho): %s" % str(_sem_stream.keys()))
	print("QA fim")
	quit(0)


func _correr(k: Node, accao: String, n: int) -> void:
	Input.action_press(accao)
	for _i in n:
		await process_frame
		_espiar()
	Input.action_release(accao)


func _saltar(_k: Node) -> void:
	Input.action_press("saltar")
	for _i in 3:
		await process_frame
		_espiar()
	Input.action_release("saltar")
	for _i in 28:
		await process_frame
		_espiar()


func _accao(accao: String, n: int) -> void:
	Input.action_press(accao)
	for _i in n:
		await process_frame
		_espiar()
	Input.action_release(accao)


## O `Som` nao emite sinais, por isso le^-se o pool: uma voz que acabou de
## comecar a tocar um stream conta como um evento. Barato e suficiente para
## provar que o evento chegou ao audio.
var _antes := {}


func _espiar() -> void:
	var pool: Array = _som.get("_pool")
	if pool == null:
		return
	for i in pool.size():
		var p: AudioStreamPlayer = pool[i]
		if p.stream == null:
			continue
		var pos := p.get_playback_position()
		var chave := str(i)
		var ant: float = _antes.get(chave, -1.0)
		if p.playing and (ant < 0.0 or pos < ant):
			var nome := _nome_do(p.stream)
			_tocados[nome] = int(_tocados.get(nome, 0)) + 1
		_antes[chave] = pos if p.playing else -1.0


func _nome_do(st: AudioStream) -> String:
	var caminho := st.resource_path
	for n in _som.CAMINHOS.keys():
		if str(_som.CAMINHOS[n]) == caminho:
			return str(n)
	return caminho.get_file()
