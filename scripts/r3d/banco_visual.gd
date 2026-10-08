extends Node3D
## Bancada visual da Koliani 3D (dev): mostra o modelo e pecas do kit sob a
## luz da Regiao I e grava um PNG. Uso:
##   godot --path . res://scenes/r3d/BancoVisual.tscn -- --saida=<png> [--estado=run]

const K := preload("res://scripts/r3d/kit3d.gd")


func _ready() -> void:
	var saida := "user://banco_r3d.png"
	var estado := "idle"
	var golpe := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			saida = a.get_slice("=", 1)
		elif a.begins_with("--estado="):
			estado = a.get_slice("=", 1)
		elif a.begins_with("--golpe="):
			golpe = int(a.get_slice("=", 1))
	Ambiente3D.montar(self, 0)
	var chao := K.laje(PackedVector2Array([Vector2(-4, -3), Vector2(4, -3.5), Vector2(5, 2), Vector2(0, 4), Vector2(-5, 2.5)]), 3.0, 1)
	K.inst(self, chao, K.mat("terreno"))
	K.inst(self, K.rocha(0.9, 3), K.mat("rocha"), Vector3(-2.5, 0.2, -1.5))
	K.inst(self, K.rocha(0.6, 5, 1.4), K.mat("pedra_sagrada"), Vector3(2.4, 0.4, -1.8))
	var m := KolianiModelo3D.new()
	add_child(m)
	m.estado = estado
	m.golpe = golpe
	m.vel_h = 6.5 if estado == "run" else 0.0
	m.fase_ataque = 0.45
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0.8, 1.35, 3.0)
	cam.look_at(Vector3(0, 0.95, 0))
	cam.fov = 45
	cam.make_current()
	for i in 40:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(saida)
	print("BANCO_R3D gravado ", saida)
	get_tree().quit()
