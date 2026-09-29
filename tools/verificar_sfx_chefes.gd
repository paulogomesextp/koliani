extends SceneTree
## Prova dirigida do Prompt 3A -- SOM DOS CHEFES.
##
## O que esta suite defende, por ordem de gravidade do que foi encontrado:
##
##  1. `chefe_cai` (MORTE) so' pode tocar na morte. Estava em 33 callsites e
##     so' DOIS eram morte; 28 eram mudanca de fase e 3 eram ataques.
##  2. `conquista` (RECOMPENSA) so' pode tocar na morte. Dois chefes
##     tocavam-na vivos -- o Rei Devorador de cada vez que comia um servo.
##  3. Mudanca de fase le-se como fase: nem morte, nem ataque.
##  4. O golpe FATAL nao empilha hurt (regressao do Prompt 1/2).
##  5. Prioridade: um ataque comum nao rouba voz a morte nem a fase.
##  6. Anti-repeticao DETERMINISTICA -- ciclo, nao sorteio.
##
## Corre com renderer real:
##   godot --headless --path . --script res://tools/verificar_sfx_chefes.gd

var _falhas := 0
var _som: Node

## Chefes instanciados directamente da cena: a prova nao depende de nenhum
## nivel nem de o chefe estar vivo no sitio certo do mundo.
const CHEFES := {
	"Ghorak": "res://scenes/actors/ChefeGhorak.tscn",
	"GuardiaoDosCeus": "res://scenes/actors/ChefeGuardiaoDosCeus.tscn",
	"Vyrak": "res://scenes/actors/ChefeVyrak.tscn",
	"SinoVivo": "res://scenes/actors/ChefeSinoVivo.tscn",
	"ReiDevorador": "res://scenes/actors/ChefeReiDevorador.tscn",
	"IrmaosCondenados": "res://scenes/actors/ChefeIrmaosCondenados.tscn",
	"ZerikoFinal": "res://scenes/actors/ChefeZerikoFinal.tscn",
	"Aerion": "res://scenes/actors/ChefeAerion.tscn",
	"Morvanna": "res://scenes/actors/ChefeMorvanna.tscn",
	"OlhoDoAbismo": "res://scenes/actors/ChefeOlhoDoAbismo.tscn",
}


func _init() -> void:
	await process_frame
	_som = root.get_node("Som")
	_som.call("definir_semente_teste", 20260920)
	var palco := Node2D.new()
	root.add_child(palco)
	await process_frame

	_catalogo()
	_reserva_estatica()
	await _sem_morte_falsa(palco)
	await _fase_nao_e_morte(palco)
	await _morte_correcta(palco)
	await _hurt(palco)
	await _guardiao(palco)
	await _vyrak(palco)
	await _anti_repeticao(palco)
	_prioridade()

	print("SFX CHEFES FINAL falhas=%d" % _falhas)
	quit(0 if _falhas == 0 else 1)


## --- 1. o catalogo nao tem chaves mortas -------------------------------
##
## O Vyrak chamava `Som.toca("boss", ...)`: "boss" nunca foi chave do
## catalogo (`boss.wav` e' uma CAMA DE MUSICA). O `toca()` devolve `false`
## em silencio, portanto a fase 2 do Vyrak era MUDA e ninguem dava por isso.
func _catalogo() -> void:
	var caminhos: Dictionary = _som.get("CAMINHOS")
	_checar(not caminhos.has("boss"),
		"'boss' e' uma cama de musica -- nao pode ser chave de SFX")
	for chave in ["chefe_cai", "conquista", "mudar_forma", "mob_grande_dano"]:
		_checar(caminhos.has(chave), "catalogo sem '%s'" % chave)
	# a carga do olho nao pode voltar a ser o mesmo ficheiro que o relampago
	_checar(String(caminhos["raio"]) != String(caminhos["olho_carregar"]),
		"raio e olho_carregar apontam ao mesmo ficheiro")
	var a := load(String(caminhos["raio"])) as AudioStream
	var b := load(String(caminhos["olho_carregar"])) as AudioStream
	_checar(a != null and b != null
		and absf(a.get_length() - b.get_length()) > 0.5,
		"raio e olho_carregar continuam indistinguiveis em duracao")
	print("SFX CHEFES catalogo: sem chaves mortas, carga != relampago")


## --- 1b. RESERVA: quem pode sequer escrever `chefe_cai`/`conquista` ----
##
## A prova em tempo de execucao so' cobre os caminhos que consegue provocar.
## Esta cobre TODOS: le' o codigo-fonte dos 38 scripts de chefe e exige que
## as duas chaves de MORTE/RECOMPENSA so' aparecam no `chefe_base.gd`, que e'
## onde vive o caminho de morte. Se amanha alguem voltar a por um
## `chefe_cai` numa mudanca de fase, e' aqui que rebenta -- mesmo que esse
## chefe nunca chegue a ser instanciado por nenhum teste.
const RESERVADAS := ["chefe_cai", "conquista"]


func _reserva_estatica() -> void:
	var dir := DirAccess.open("res://scripts")
	_checar(dir != null, "nao consigo ler res://scripts")
	if dir == null:
		return
	var intrusos: Array[String] = []
	var vistos := 0
	for f in dir.get_files():
		if not (f.begins_with("chefe_") and f.ends_with(".gd")):
			continue
		vistos += 1
		if f == "chefe_base.gd":
			continue  # e' a casa do caminho de morte
		var txt := FileAccess.get_file_as_string("res://scripts/" + f)
		for chave in RESERVADAS:
			# so' conta como USO o que esta' dentro de uma chamada de som;
			# os comentarios do ficheiro falam das chaves de proposito.
			for prefixo in ["Som.toca(\"", "_som_ataque(\"", "_som_impacto(\"",
					"_som(\""]:
				if txt.contains(prefixo + chave + "\""):
					intrusos.append("%s -> %s" % [f, chave])
	_checar(intrusos.is_empty(),
		"MORTE/RECOMPENSA fora do chefe_base.gd: %s" % str(intrusos))
	_checar(vistos >= 30, "so' vi %d scripts de chefe" % vistos)
	print("SFX CHEFES reserva: chefe_cai/conquista so' no chefe_base (%d scripts)"
		% vistos)


## --- 2. nenhum chefe toca MORTE ou RECOMPENSA estando vivo -------------
##
## Este e' o teste central do lote. Deixa correr a maquina de estados de
## cada chefe e depois chama todas as accoes sem argumentos que ele saiba
## fazer, exigindo que `chefe_cai.wav` e `conquista.wav` NUNCA apareçam
## enquanto o chefe tem vida.
func _sem_morte_falsa(palco: Node) -> void:
	for nome in CHEFES:
		var c := _nascer(palco, String(CHEFES[nome]))
		if c == null:
			continue
		var antes := _contador()
		for _i in 90:
			await physics_frame
		if not is_instance_valid(c):
			continue  # o chefe libertou-se sozinho durante os 90 frames
		for mn in _accoes_do_chefe(c):
			if not is_instance_valid(c):
				break
			c.call(mn)
		var tocados := _desde(antes)
		_checar(not tocados.has("chefe_cai.wav"),
			"%s toca MORTE estando vivo: %s" % [nome, str(tocados)])
		_checar(not tocados.has("conquista.wav"),
			"%s toca RECOMPENSA estando vivo: %s" % [nome, str(tocados)])
		if is_instance_valid(c):
			c.queue_free()
		await process_frame
	print("SFX CHEFES falso-kill: 0 em %d chefes" % CHEFES.size())


## Metodos sem argumentos que sao accao de combate/fase. Deixa de fora o
## ciclo de vida do no' e os utilitarios de leitura -- chamar `_ready` ou
## `_exit_tree` a mao nao prova nada e rebenta o estado.
const NAO_E_ACCAO := [
	"_ready", "_process", "_physics_process", "_init", "_enter_tree",
	"_exit_tree", "_input", "_unhandled_input", "_draw", "_notification",
	"_get", "_set", "_to_string", "_medir", "_tex_", "_obter", "_chao",
	"_x_", "_dir_", "_ve_", "_nome_", "_anim_", "_altura", "_largura",
	"_origem", "_frame_", "_pitch_", "_som_", "_presa_", "_tel",
]


## Accoes DECLARADAS no script do chefe (e nas suas bases ate' ao
## `ChefeBase`). O `get_method_list()` do no' nao serve: traz os virtuais do
## motor que o script nao implementa (`_mouse_enter` e companhia) e chama-los
## rebenta a prova a meio. Aqui so' entra o que o chefe escreveu mesmo.
func _accoes_do_chefe(c: Node) -> Array[String]:
	var r: Array[String] = []
	var sc: Script = c.get_script()
	while sc != null:
		for m in sc.get_script_method_list():
			var mn := String(m["name"])
			if int((m["args"] as Array).size()) != 0:
				continue
			if _e_accao(mn) and not r.has(mn):
				r.append(mn)
		if String(sc.resource_path).ends_with("chefe_base.gd"):
			break
		sc = sc.get_base_script()
	return r


## O caminho de MORTE e' o unico com direito a tocar `chefe_cai`/`conquista`
## -- chamar estas funcoes a' mao e depois acusar o chefe de "tocar morte
## estando vivo" seria a prova a enganar-se a si propria. O que se testa e'
## tudo o resto: ataques, telegrafos, invocacoes, mudancas de fase.
const CAMINHO_DE_MORTE := [
	"_tocar_som_derrota", "_cair_com_falas", "_explodir_derrotado",
	# terceira porta de entrada: o chefe que cai da arena (`_process`)
	"_cair_derrotado",
]


func _e_accao(n: String) -> bool:
	if not n.begins_with("_"):
		return false
	if CAMINHO_DE_MORTE.has(n):
		return false
	for proibido in NAO_E_ACCAO:
		if n.begins_with(proibido):
			return false
	return true


## --- 3. mudanca de fase le-se como FASE ---------------------------------
func _fase_nao_e_morte(palco: Node) -> void:
	for nome in CHEFES:
		var c := _nascer(palco, String(CHEFES[nome]))
		if c == null:
			continue
		c.set("_sfx_fase_cd", 0.0)
		await _acalmar()
		var antes := _contador()
		c.call("_som_fase")
		for _i in 12:
			await physics_frame
		var t := _desde(antes)
		_checar(t.has("mudar_forma.wav"),
			"%s: mudanca de fase sem mudar_forma (%s)" % [nome, str(t)])
		_checar(not t.has("chefe_cai.wav") and not t.has("conquista.wav"),
			"%s: mudanca de fase dispara morte/recompensa (%s)" % [nome, str(t)])
		_checar(t.size() <= 2,
			"%s: fase empilha %d vozes (max 2): %s" % [nome, t.size(), str(t)])
		c.queue_free()
		await process_frame
	print("SFX CHEFES fase: mudar_forma + 1 camada, nunca morte")


## --- 4. a sequencia de MORTE ------------------------------------------
##
## Contrato do Prompt 1, que este lote nao pode regredir:
##   chefe_cai -> 450 ms -> conquista, exactamente uma vez cada.
func _morte_correcta(palco: Node) -> void:
	for nome in ["Ghorak", "GuardiaoDosCeus", "Vyrak", "ReiDevorador"]:
		var c := _nascer(palco, String(CHEFES[nome]))
		if c == null:
			continue
		# Ha' DOIS caminhos de morte, e o contrato e' diferente em cada um:
		#   sem falas  -> `_tocar_som_derrota`: chefe_cai -> 450 ms -> conquista
		#   com falas  -> `_cair_com_falas`:    chefe_cai -> DIALOGO -> conquista
		# Num harness sem input o dialogo nunca fecha, portanto exigir a
		# `conquista` no chefe-historia seria exigir o impossivel. O que se
		# prova nesse caso e' o que importa: a queda toca UMA vez e a
		# recompensa NAO se antecipa ao dialogo.
		var com_falas: bool = not (c.get("falas_fim") as Array).is_empty()
		c.set("vida", 1)
		await _acalmar()
		var antes := _contador()
		c.call("receber_dano", 9999)
		var imediato := _desde(antes)
		_checar(imediato.count("chefe_cai.wav") == 1,
			"%s: morte nao tocou UM chefe_cai (%s)" % [nome, str(imediato)])
		_checar(not imediato.has("conquista.wav"),
			"%s: recompensa no mesmo frame da queda" % nome)
		_checar(not imediato.has("mob_grande_dano.ogg")
			and not imediato.has("mob_grande_dano.wav"),
			"%s: golpe FATAL empilhou hurt (%s)" % [nome, str(imediato)])
		for _i in 40:
			await physics_frame
		var total := _desde(antes)
		_checar(total.count("chefe_cai.wav") == 1,
			"%s: queda duplicada entre base e subclasse (%s)" % [nome, str(total)])
		if com_falas:
			_checar(total.count("conquista.wav") == 0,
				"%s (chefe-historia): recompensa antes das ultimas falas (%s)"
				% [nome, str(total)])
		else:
			_checar(total.count("conquista.wav") == 1,
				"%s: recompensa nao tocou uma vez (%s)" % [nome, str(total)])
	print("SFX CHEFES morte: chefe_cai x1; conquista x1 (ou apos falas)")


## --- 5. hurt base: cooldown e nunca no golpe fatal ---------------------
func _hurt(palco: Node) -> void:
	var c := _nascer(palco, String(CHEFES["Ghorak"]))
	if c == null:
		return
	c.set("vida", 900)
	c.set("_sfx_dano_cd", 0.0)
	await _acalmar()
	var antes := _contador()
	c.call("receber_dano", 1)
	c.call("receber_dano", 1)
	c.call("receber_dano", 1)
	var t := _desde(antes)
	_checar(t.size() == 1, "hurt do chefe ignorou o cooldown (%s)" % str(t))
	_checar(t.size() > 0 and String(t[0]).begins_with("mob_grande_dano"),
		"hurt do chefe nao e' mob_grande_dano (%s)" % str(t))
	c.queue_free()
	await process_frame
	print("SFX CHEFES hurt: 1 voz por 220 ms, mob_grande_dano")


## --- 6. GUARDIAO DOS CEUS: os tres ataques tem de se distinguir --------
func _guardiao(palco: Node) -> void:
	# Sem WindZone na arena o `_mandar_vento` sai pelo `return` inicial e a
	# Chamada dos Ventos nunca chega ao som -- nao e' bug, e' o contrato
	# (nenhum vento entra sem haver vento). A prova monta a zona.
	var zona := (load("res://scenes/actors/WindZone.tscn") as PackedScene).instantiate()
	palco.add_child(zona)
	var c := _nascer(palco, String(CHEFES["GuardiaoDosCeus"]))
	if c == null:
		return
	(zona as Node2D).global_position = (c as Node2D).global_position
	c.call("_procurar_vento")
	await _acalmar()
	var usados: Array[String] = []
	for par in [["_lamina", "blade"], ["_mandar_vento", "vento"],
			["_impacto", "mergulho"]]:
		var antes := _contador()
		match String(par[0]):
			"_lamina":
				c.call("_lamina", Vector2.ZERO, Vector2.RIGHT)
			"_mandar_vento":
				c.call("_mandar_vento", Vector2.RIGHT)
			_:
				c.call("_impacto")
		var t := _desde(antes)
		_checar(t.size() >= 1, "Guardiao: ataque '%s' ficou MUDO" % String(par[1]))
		usados.append(String(t[0]) if t.size() > 0 else "")
	_checar(usados.size() == 3 and usados[0] != usados[1]
		and usados[1] != usados[2] and usados[0] != usados[2],
		"Guardiao: os tres ataques nao se distinguem: %s" % str(usados))
	_checar(not usados.has("projetil.wav"),
		"Guardiao: a lamina voltou ao projectil generico")
	c.queue_free()
	zona.queue_free()
	await process_frame
	print("SFX CHEFES Guardiao: blade/vento/mergulho = %s" % str(usados))


## --- 7. VYRAK ----------------------------------------------------------
func _vyrak(palco: Node) -> void:
	var c := _nascer(palco, String(CHEFES["Vyrak"]))
	if c == null:
		return
	# A fase 2 era MUDA: `_som("boss", ...)` sem chave no catalogo.
	c.set("_sfx_fase_cd", 0.0)
	await _acalmar()
	var antes := _contador()
	c.call("_ritual_de_ativacao")
	var t := _desde(antes)
	_checar(t.size() >= 1, "Vyrak: o ritual da fase 2 continua MUDO")
	_checar(t.has("mudar_forma.wav"),
		"Vyrak: o ritual nao usa a assinatura de fase (%s)" % str(t))
	# O chefe-SINO nao pode usar a espada da KOLIANI.
	antes = _contador()
	for a in range(0, 9):
		c.call("_executar", a)
		for _i in 2:
			await physics_frame
	var todos := _desde(antes)
	_checar(not todos.has("ataque_forte.wav"),
		"Vyrak usa o som da espada da Koliani: %s" % str(todos))
	c.queue_free()
	await process_frame
	print("SFX CHEFES Vyrak: fase audivel, sem a espada do player")


## --- 8. anti-repeticao DETERMINISTICA ----------------------------------
func _anti_repeticao(palco: Node) -> void:
	var c := _nascer(palco, String(CHEFES["Ghorak"]))
	if c == null:
		return
	# O `_ultimo_player()` (indice - 1) nao serve aqui: o `_physics_process`
	# do chefe toca sons dele pelo meio e move o indice do pool. O tom tem de
	# vir da voz que tocou ESTE ficheiro.
	var tons := _ciclo_de_tons(c)
	_checar(tons.size() == 3 and tons[0] != tons[1] and tons[1] != tons[2],
		"ataque repetido do chefe soa A A A: %s" % str(tons))
	var segunda := _ciclo_de_tons(c)
	_checar(_quase_igual(tons, segunda),
		"anti-repeticao nao e' deterministica: %s vs %s" % [str(tons), str(segunda)])
	c.queue_free()
	await process_frame
	print("SFX CHEFES anti-repeticao: ciclo de 3, deterministico %s" % str(tons))


## Tres disparos seguidos do mesmo ataque; devolve o tom de cada um.
func _ciclo_de_tons(c: Node) -> Array[float]:
	var tons: Array[float] = []
	for _i in 3:
		var antes := _contador()
		c.call("_som_ataque", "projetil", -8.0, 1.0, 0.0, 0.0)
		tons.append(_tom_desde(antes, "projetil.wav"))
	return tons


## Tom da voz que tocou `ficheiro` depois de `antes`. -1 se nao tocou.
func _tom_desde(antes: int, ficheiro: String) -> float:
	var pool: Array = _som.get("_pool")
	var ordens: Array = _som.get("_ordem_vozes")
	var melhor := -1
	var tom := -1.0
	for i in pool.size():
		var p := pool[i] as AudioStreamPlayer
		if p == null or p.stream == null:
			continue
		if int(ordens[i]) > antes and p.stream.resource_path.get_file() == ficheiro:
			if int(ordens[i]) > melhor:
				melhor = int(ordens[i])
				tom = p.pitch_scale
	return tom


## --- 9. prioridade ------------------------------------------------------
func _prioridade() -> void:
	for p in _som.get("_pool"):
		(p as AudioStreamPlayer).stop()
	# oito vozes de MORTE ocupam o pool inteiro
	for _i in int(_som.VOZES):
		_som.call("toca", "chefe_cai", -6.0, 1.0, 0.0, 0.0, "",
			int(_som.Prioridade.ALTA))
	var antes := _contador()
	var tocou: bool = _som.call("toca", "projetil", -8.0, 1.0, 0.0, 0.0,
		"", int(_som.Prioridade.NORMAL))
	_checar(not tocou and _contador() == antes,
		"ataque comum de chefe roubou voz a MORTE")
	print("SFX CHEFES prioridade: morte protegida de ataque comum")


## --- utilitarios --------------------------------------------------------

## Deixa aterrar o que a seccao anterior deixou no ar e limpa o pool.
##
## Sem isto a prova mentia: um `tween_callback` ou um `create_timer` de um
## chefe ja' libertado tocava DENTRO da janela de medicao seguinte e era
## contado como voz da fase. Foi assim que a fase do Ghorak apareceu com
## tres vozes -- duas eram do chefe anterior.
func _acalmar() -> void:
	for _i in 30:
		await physics_frame
	for p in _som.get("_pool"):
		(p as AudioStreamPlayer).stop()
	await process_frame


func _nascer(palco: Node, caminho: String) -> Node:
	var cena := load(caminho) as PackedScene
	if cena == null:
		_checar(false, "cena ausente: %s" % caminho)
		return null
	var c := cena.instantiate()
	palco.add_child(c)
	return c


func _contador() -> int:
	return int(_som.get("_ordem"))


## Ficheiros tocados desde `antes`, por ordem. Le a ordem gravada em cada
## voz do pool -- e' assim que se ve' uma SEQUENCIA e nao so' o ultimo som.
func _desde(antes: int) -> Array:
	var pool: Array = _som.get("_pool")
	var ordens: Array = _som.get("_ordem_vozes")
	var pares: Array = []
	for i in pool.size():
		var o := int(ordens[i])
		var p := pool[i] as AudioStreamPlayer
		if o > antes and p and p.stream:
			pares.append([o, p.stream.resource_path.get_file()])
	pares.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	var r: Array = []
	for par in pares:
		r.append(String(par[1]))
	return r


func _ultimo_player() -> AudioStreamPlayer:
	var i := posmod(int(_som.get("_idx")) - 1, int(_som.VOZES))
	return (_som.get("_pool") as Array)[i] as AudioStreamPlayer


func _quase_igual(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if absf(float(a[i]) - float(b[i])) > 0.0005:
			return false
	return true


func _checar(ok: bool, mensagem: String) -> void:
	if not ok:
		_falhas += 1
		push_error("SFX CHEFES: " + mensagem)
