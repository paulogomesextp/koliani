extends SceneTree
## QA da auditoria externa (NAO e' produto). Fotografa um nivel em 5 pontos:
## inicio, 1/3 e 2/3 do caminho inicio->porta, guardiao/chefe, porta.
## Uso: Godot --window --screen 1 --path . --script res://docs/qa/full_game_review/tools/auditoria_fotos.gd -- <cena> <prefixo_saida_abs>

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0]
	var pref: String = args[1]
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		var i := int(es.NIVEIS.find(cena))
		if i >= 0:
			es.indice_nivel = i
		es.checkpoint = Vector2.ZERO
	change_scene_to_file(cena)
	for _i in 40:
		await process_frame
	var nivel := current_scene
	var kol := nivel.get_node_or_null("Koliani") as Node2D
	if kol == null:
		print("AUDIT sem Koliani"); quit(1); return
	var inicio := kol.global_position
	var porta := _achar(nivel, ["Porta", "PortaFinal", "Saida"])
	var chefe := _achar(nivel, ["Guardiao", "Chefe"])
	var fim := porta.global_position if porta else inicio + Vector2(3000, 0)
	var pontos := {
		"1_inicio": inicio,
		"2_terco": inicio.lerp(fim, 0.33),
		"3_doisterc": inicio.lerp(fim, 0.66),
	}
	if chefe:
		pontos["4_guardiao"] = chefe.global_position + Vector2(-260, 0)
	pontos["5_fim"] = fim + Vector2(-200, 0)
	print("AUDIT inicio=", inicio, " porta=", fim, " chefe=", chefe.global_position if chefe else Vector2.ZERO)
	for k in pontos:
		kol.global_position = pontos[k]
		if "velocity" in kol:
			kol.velocity = Vector2.ZERO
		for _i in 14:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png("%s_%s.png" % [pref, k])
	quit(0)

func _achar(n: Node, nomes: Array) -> Node2D:
	for nome in nomes:
		var c := n.get_node_or_null(nome)
		if c is Node2D:
			return c
	return null
