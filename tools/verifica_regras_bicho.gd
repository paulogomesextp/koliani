extends SceneTree
## Prova que as tres REGRAS novas de bicho (5 set 2026) mordem mesmo:
##
##   `divide_em`          -- morre e deixa duas copias mais pequenas
##   `so_tiro`            -- a espada nao lhe toca, o tiro toca
##   `so_mexe_sem_olhar`  -- para' quando a Koliani esta' virada para ele
##
## Existe porque estas tres vivem no `DemonioBase` e a suite (`--script`)
## nao consegue instancia'-lo: o script usa `EstadoJogo`/`Som` pelo nome e
## em `--script` os autoloads nao existem como IDENTIFICADOR. Aqui os nos
## ja' estao em `/root` quando o `load()` corre, e por isso funciona.
##
## Uso: Godot --headless --script res://tools/verifica_regras_bicho.gd

const CENA := "res://scenes/actors/DemonioBase.tscn"

var _falhas := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   %s" % msg)
	else:
		print("  FALHA %s" % msg)
		_falhas += 1


func _init() -> void:
	await process_frame
	var cena := load(CENA) as PackedScene
	if cena == null:
		print("sem cena %s" % CENA)
		quit(1)
		return

	# --- divide_em -----------------------------------------------------
	var sala := Node2D.new()
	root.add_child(sala)
	var pai := Node2D.new()
	sala.add_child(pai)
	var d: Node2D = cena.instantiate()
	d.set("divide_em", 2)
	d.set("vida", 20)
	pai.add_child(d)
	await process_frame
	var antes := pai.get_child_count()
	d.call("receber_dano", 999, 0.0, false)
	await process_frame
	await process_frame
	var filhos := 0
	for c in pai.get_children():
		if c != d and c.get("divide_em") != null:
			filhos += 1
	_ok(filhos == 2, "divide_em: %d copias (antes havia %d nos)" % [filhos, antes])
	for c in pai.get_children():
		_ok(int(c.get("divide_em")) == 0 or c == d,
			"as copias nao se voltam a dividir")
		break

	# --- so_tiro -------------------------------------------------------
	var e: Node2D = cena.instantiate()
	e.set("so_tiro", true)
	e.set("vida", 100)
	sala.add_child(e)
	await process_frame
	# a vida de partida le'-se DEPOIS do _ready: ele reescala-a pela curva
	# de dificuldade da campanha, e um valor cravado aqui nao batia certo.
	var v0 := int(e.get("vida"))
	e.call("receber_dano", 40, 1.0, false)          # espada
	await process_frame
	_ok(int(e.get("vida")) == v0,
		"so_tiro: a espada nao lhe toca (%d -> %d)" % [v0, int(e.get("vida"))])
	e.call("receber_tiro", 40, 1.0)                 # tiro
	await process_frame
	_ok(int(e.get("vida")) == v0 - 40,
		"so_tiro: o tiro toca (%d -> %d)" % [v0, int(e.get("vida"))])
	# e o proximo golpe de espada volta a nao contar -- o `_de_longe` tem
	# de se limpar, senao bastava um tiro para o tornar normal para sempre
	e.call("receber_dano", 40, 1.0, false)
	await process_frame
	_ok(int(e.get("vida")) == v0 - 40,
		"so_tiro: o `_de_longe` limpa-se (vida = %d)" % int(e.get("vida")))

	# --- so_mexe_sem_olhar ---------------------------------------------
	# sem Koliani na cena tem de ANDAR (senao gelava para sempre)
	var s: Node2D = cena.instantiate()
	s.set("so_mexe_sem_olhar", true)
	sala.add_child(s)
	await process_frame
	_ok(not bool(s.call("_koliani_a_olhar")),
		"so_mexe_sem_olhar: sem Koliani conta como 'nao esta' a olhar'")

	# com uma Koliani de mentira: virada para ele (a olhar) e virada para
	# o outro lado (a deixar andar)
	# duble da Koliani: precisa mesmo de um script com `_olha_para`, porque
	# um `set()` num Node2D sem essa propriedade nao cria nada.
	var duble := GDScript.new()
	duble.source_code = "extends Node2D
var _olha_para := 1.0
"
	duble.reload()
	var k := Node2D.new()
	k.set_script(duble)
	k.add_to_group("koliani")
	sala.add_child(k)
	s.global_position = Vector2(300.0, 0.0)
	k.global_position = Vector2(0.0, 0.0)
	k.set("_olha_para", 1.0)                        # olha para a direita
	await process_frame
	_ok(bool(s.call("_koliani_a_olhar")),
		"so_mexe_sem_olhar: ela a' esquerda e virada para a direita = a olhar")
	k.set("_olha_para", -1.0)
	_ok(not bool(s.call("_koliani_a_olhar")),
		"so_mexe_sem_olhar: virada ao contrario = livre para andar")

	print("\n=== REGRAS DE BICHO: %s ===" %
		("TUDO OK" if _falhas == 0 else "%d FALHA(S)" % _falhas))
	quit(1 if _falhas else 0)
