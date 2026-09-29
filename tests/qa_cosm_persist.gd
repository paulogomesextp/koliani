extends Control
## Persistencia real entre PROCESSOS. Argumentos de utilizador (depois de `--`):
##   semear     -> saldo de teste (2000 K / 300 V) e grava; SO no sandbox do QA
##   compra     -> compra (se preciso) e equipa carmesim + brasa + osso, grava
##   verifica   -> confirma que continuam equipados e aplicados num nivel real
##   desequipa  -> desequipa tudo e grava
##   default    -> confirma o visual default
## ESCREVE no save: correr por `tools/correr_qa_cosmeticos.ps1` (APPDATA isolado).

var falhas := 0


func _check(c: bool, m: String) -> void:
	print(("PASS   " if c else "FALHOU ") + m)
	if not c:
		falhas += 1


func _ready() -> void:
	var modo := ""
	for a in OS.get_cmdline_user_args():
		modo = a
	await get_tree().create_timer(0.4).timeout
	match modo:
		"semear":
			# so' aqui: o `dev_dar_veracoins` recusa fora de modo_teste, e em
			# modo_teste `guardar()` nao grava -- por isso liga-se so' o tempo do credito
			EstadoJogo.ganhar_kolicoins(2000, false)
			EstadoJogo.modo_teste = true
			EstadoJogo.dev_dar_veracoins(300)
			EstadoJogo.modo_teste = false
			_check(EstadoJogo.guardar(), "semear: save do sandbox gravado")
		"compra":
			for id in ["skin_carmesim", "efeito_rasto_brasa", "hud_moldura_osso"]:
				EstadoJogo.comprar_item(id, "k")
				EstadoJogo.equipar_item(id)
			print("INFO saldo K=", EstadoJogo.kolicoins, " comprados=", EstadoJogo.itens_comprados)
			_check(EstadoJogo.item_equipado("skin_carmesim"), "compra: carmesim equipada")
		"verifica":
			_check(EstadoJogo.item_adquirido("skin_carmesim") and EstadoJogo.item_adquirido("efeito_rasto_brasa"), "reinicio: compras persistiram")
			_check(EstadoJogo.item_equipado("skin_carmesim") and EstadoJogo.item_equipado("efeito_rasto_brasa")
				and EstadoJogo.item_equipado("hud_moldura_osso"), "reinicio: equipados persistiram")
			await _visual(true)
		"desequipa":
			for c in ["skins", "efeitos", "hud_checkpoint"]:
				EstadoJogo.desequipar_categoria(c)
		"default":
			_check(EstadoJogo.item_equipado("skin_koliani_base") and not EstadoJogo.item_equipado("skin_carmesim"), "default: skin base equipada")
			_check(EstadoJogo.item_adquirido("skin_carmesim"), "default: compra mantida apos desequipar")
			await _visual(false)
	print("QA PERSISTENCIA[%s]: %s" % [modo, "PASS" if falhas == 0 else "FAIL"])
	get_tree().quit(0 if falhas == 0 else 1)


func _visual(esperado_aplicado: bool) -> void:
	var n: Node = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	add_child(n)
	await get_tree().create_timer(1.5).timeout
	var k := get_tree().get_first_node_in_group("koliani")
	var m: Color = k._corpo.modulate
	print("INFO modulate corpo=", m)
	var base := Color(0.88, 0.86, 0.94, 1.0)
	var igual := m.is_equal_approx(base)
	_check(igual != esperado_aplicado, "visual %s no jogo (modulate=%s)" % ["aplicado" if esperado_aplicado else "default", str(m)])
