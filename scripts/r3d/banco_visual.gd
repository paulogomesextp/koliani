extends Node3D
## Bancada visual da Koliani 3D (dev): folha de poses do modelo sob a luz da
## Regiao I e grava um PNG. Uso:
##   godot --path . res://scenes/r3d/BancoVisual.tscn -- --saida=<png> [--perto] [--inimigos]

const K := preload("res://scripts/r3d/kit3d.gd")
const POSES := [["idle", 0], ["run", 0], ["jump", 0], ["fall", 0], ["attack", 0], ["attack", 1], ["attack", 2], ["attack", 3], ["hurt", 0]]


func _ready() -> void:
	var saida := "user://banco_r3d.png"
	var perto := false
	var inimigos := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			saida = a.get_slice("=", 1)
		elif a == "--perto":
			perto = true
		elif a == "--inimigos":
			inimigos = true
	Ambiente3D.montar(self, 0)
	var chao := K.laje(PackedVector2Array([Vector2(-14, -4), Vector2(14, -4), Vector2(14, 4), Vector2(-14, 4)]), 3.0, 1)
	var corpo := StaticBody3D.new()
	add_child(corpo)
	K.inst(corpo, chao, K.mat("terreno"))
	var fc := CollisionShape3D.new()
	fc.shape = chao.create_trimesh_shape()
	corpo.add_child(fc)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40
	if inimigos:
		var tipos := ["goblin", "gosma", "bruto"]
		for i in tipos.size():
			var e := Inimigo3D.new()
			e.tipo = tipos[i]
			e.position = Vector3(-3.0 + i * 3.0, 0.05, 0)
			e.set_physics_process(false)
			add_child(e)
			e.get_child(e.get_child_count() - 1)
		cam.position = Vector3(0, 2.2, 7.5)
		cam.look_at(Vector3(0, 1.0, 0))
	elif perto:
		var m := KolianiModelo3D.new()
		add_child(m)
		m.rotation.y = 0.5
		cam.position = Vector3(0.0, 1.45, 2.4)
		cam.look_at(Vector3(0, 1.15, 0))
		cam.fov = 35
	else:
		for i in POSES.size():
			var m := KolianiModelo3D.new()
			add_child(m)
			m.position = Vector3(-8.0 + i * 2.0, 0, 0)
			m.estado = POSES[i][0]
			m.golpe = POSES[i][1]
			m.vel_h = 6.5 if POSES[i][0] == "run" else 0.0
			m.vel_y = 6.0 if POSES[i][0] == "jump" else -6.0
			m.fase_ataque = 0.42
			m.rotation.y = 0.9
		cam.position = Vector3(0, 1.6, 13.0)
		cam.look_at(Vector3(0, 0.95, 0))
	cam.make_current()
	for i in 45:
		await get_tree().process_frame
	for c in get_children():
		if c is Inimigo3D:
			print("INIMIGO ", c.tipo, " ", c.global_position, " filhos=", c.get_child_count(), " vis=", c.is_visible_in_tree())
	var img := get_viewport().get_texture().get_image()
	img.save_png(saida)
	print("BANCO_R3D gravado ", saida)
	get_tree().quit()
