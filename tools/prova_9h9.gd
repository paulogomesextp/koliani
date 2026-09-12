extends Node
## Execution 9H.9 — prova de movimento das criaturas e da luta da Morvanna.
##
## É uma CENA e não um `--script`: em `--script` os autoloads não existem e a
## compilação rebenta em cascata (Movimento, Koliani, UIProducao...).
##
## Uso: Godot --window --screen 1 --path . res://tools/prova_9h9.tscn

const NIVEL_MORVANNA := "res://scenes/levels/Pantano_dos_Sussurros.tscn"
const NIVEL_GHORAK := "res://scenes/levels/Floresta_Putrefata.tscn"


func _ready() -> void:
	_correr.call_deferred()


func _correr() -> void:
	await _provar_morvanna()
	await _provar_criaturas()
	get_tree().quit(0)


## A Morvanna tem de CHEGAR ao alcance melee da Koliani, e o corpo dela só
## pode machucar durante a picada.
func _provar_morvanna() -> void:
	var nivel := await _carregar(NIVEL_MORVANNA)
	var boss := nivel.get_tree().get_first_node_in_group("chefes") as Node2D
	var k := nivel.get_tree().get_first_node_in_group("koliani") as Node2D
	if boss == null or k == null:
		print("MORVANNA: FALHA -- sem chefe ou sem Koliani")
		return
	# põe a Koliani ao lado dela para a luta arrancar
	k.global_position = boss.global_position + Vector2(-120.0, 180.0)
	var fases := {}
	var min_alt := 9999.0
	var frames_ao_alcance := 0
	var picada_ativa_frames := 0
	var chao := 0.0
	for i in 1400:
		k.set("velocity", Vector2.ZERO)
		await get_tree().process_frame
		if not is_instance_valid(boss):
			break
		var f := int(boss.get("_fase"))
		fases[f] = int(fases.get(f, 0)) + 1
		if chao <= 0.0:
			chao = float(boss.get("_chao_cache"))
		var alt := chao - boss.global_position.y
		min_alt = minf(min_alt, alt)
		# alcance melee: a espada da Koliani chega a ~60 px acima do chão
		if alt <= 70.0:
			frames_ao_alcance += 1
		if bool(boss.get("_picada_ativa")):
			picada_ativa_frames += 1
	print("MORVANNA: altura minima acima do chao = %.0f px" % min_alt)
	print("MORVANNA: frames ao alcance melee (<=70 px) = %d de 1400" % frames_ao_alcance)
	print("MORVANNA: frames com o corpo a machucar (picada) = %d" % picada_ativa_frames)
	print("MORVANNA: fases visitadas = ", fases)
	nivel.free()


## Um inimigo comum e um guardião têm de MUDAR de clipe (idle -> run ->
## attack), não ficar num só.
func _provar_criaturas() -> void:
	var nivel := await _carregar(NIVEL_GHORAK)
	var k := nivel.get_tree().get_first_node_in_group("koliani") as Node2D
	var comum: Node = null
	var chefe := nivel.get_tree().get_first_node_in_group("chefes")
	for no in nivel.get_children():
		if no.get_class() == "CharacterBody2D" and no.get("dano_contacto") != null \
				and no != chefe and no != k and comum == null:
			comum = no
	var vistos := {"comum": {}, "chefe": {}}
	# Metade do tempo ao lado do inimigo comum, metade na arena do guardião:
	# parada longe dele, ele só PERSEGUE, e a perseguição é `run` -- que é o
	# correcto, mas não prova o telégrafo nem o golpe.
	for i in 1300:
		if k:
			var perto: Node2D = (comum as Node2D) if i < 500 and comum else (chefe as Node2D)
			if perto:
				k.global_position = perto.global_position + Vector2(-96.0, -10.0)
				k.set("velocity", Vector2.ZERO)
		await get_tree().process_frame
		for nome in ["comum", "chefe"]:
			var alvo: Node = comum if nome == "comum" else chefe
			if alvo == null or not is_instance_valid(alvo):
				continue
			var an: Node = alvo.get_node_or_null("Sprite/Anim")
			if an == null:
				an = alvo.get_node_or_null("Anim")
			if an == null:
				continue
			var a := String(an.get("animation"))
			(vistos[nome] as Dictionary)[a] = int((vistos[nome] as Dictionary).get(a, 0)) + 1
	print("CRIATURAS: inimigo comum = ", vistos["comum"])
	print("CRIATURAS: guardiao = ", vistos["chefe"])
	nivel.free()


func _carregar(cena: String) -> Node:
	var nivel := (load(cena) as PackedScene).instantiate()
	get_tree().root.add_child(nivel)
	for _i in 40:
		await get_tree().process_frame
	return nivel
