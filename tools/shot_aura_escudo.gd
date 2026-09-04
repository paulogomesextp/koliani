extends SceneTree
## Bancada da AURA, do ESCUDO DE ENERGIA e do LASER, dentro do jogo a serio.
##
## Nao da' para ver estas tres coisas com `--script` sobre a cena da Koliani
## solta: o `koliani.gd` usa os autoloads (`EstadoJogo`, `Som`) logo no
## `_ready`. Carrega-se um nivel de verdade e mexe-se na Koliani que la'
## esta'. Precisa de JANELA (o `--headless` desta maquina nao desenha):
##
##   Godot --window --screen 1 --resolution 1280x720 \
##     --script res://tools/shot_aura_escudo.gd -- <saida.png> [modo]
##
## modos: `escudo` (por omissao) poe-a a defender e da'-lhe um bloqueio, para
## a cupula abrir e dar o clarao; `tiro` larga tres lasers a' volta dela.

const NIVEL := "res://scenes/levels/Level_Test.tscn"
const LASER := "res://scenes/actors/ProjetilKoliani.tscn"
const KAME := "res://scenes/actors/KamehamehaKoliani.tscn"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else "user://aura.png"
	var modo: String = args[1] if args.size() > 1 else "escudo"

	await process_frame
	# O `EstadoJogo` guarda o checkpoint entre sessoes. Depois de correr
	# qualquer ferramenta que carregue um nivel a serio, fica la' um ponto
	# que pertence a OUTRO nivel -- e a Koliani nasce no vazio da sala de
	# treino e morre antes de a screenshot sair ("Trying to cast a freed
	# object"). Limpa-se, que isto e' uma bancada.
	var ej := root.get_node_or_null("EstadoJogo")
	if ej:
		ej.set("checkpoint", Vector2.ZERO)
		ej.set("indice_nivel", 0)
	change_scene_to_file(NIVEL)
	await process_frame
	await process_frame
	await create_timer(0.4).timeout

	var k := get_first_node_in_group("koliani") as Node2D
	if k == null:
		push_error("nao ha' Koliani no nivel")
		quit(1)
		return

	if modo == "tiro":
		# tres lasers parados a' volta dela, em direcoes diferentes
		for i in 3:
			var p := (load(LASER) as PackedScene).instantiate() as Node2D
			k.get_parent().add_child(p)
			p.global_position = k.global_position + Vector2(60.0 + 70.0 * i, -20.0 * i)
			p.lancar(Vector2.RIGHT.rotated(deg_to_rad(-20.0 * i)), 10)
			p.set_physics_process(false)
		var kame := (load(KAME) as PackedScene).instantiate() as Node2D
		k.get_parent().add_child(kame)
		kame.global_position = k.global_position + Vector2(160.0, 60.0)
		kame.lancar(Vector2.RIGHT, 10)
		kame.set_physics_process(false)
	else:
		# Esperar pelo CHAO. Ela cai ao entrar no nivel e a defesa so' vale
		# com os pes assentes -- premir cedo de mais nao levanta escudo
		# nenhum, e a screenshot sai sem cupula por essa razao e nao por bug.
		var voltas := 0
		while voltas < 240 and is_instance_valid(k) 				and not (k as CharacterBody2D).is_on_floor():
			voltas += 1
			await process_frame
		# `_defendendo` e' recalculado do input TODOS os frames -- por-lhe a
		# bandeira a' mao nao serve de nada. Preme-se a accao a serio.
		Input.action_press("defender")
		await create_timer(0.35).timeout
		# e um bloqueio, para apanhar o clarao no seu auge
		k.set("_cupula_flash", 1.0)

	await create_timer(0.1).timeout
	Input.action_release("defender")
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida)
	quit()
