extends Node
## Execution 9D+9E — prova de runtime dos inimigos da Região I.
##
## Em cada nível L1–L5 (ambiente 9C ligado), para cada inimigo/guardião:
## encosta a Koliani a ~150 px, grava idle, telégrafo (o pisca por código),
## golpe (`hit`) e morte (`dead`). Depois invoca as crias (clones da Morvanna
## no L2, ovo da Rainha no L3) e fotografa-as, e fotografa o Coração (L5).
## No fim mede o tempo de frame de parede de cada nível (vsync desligado).
##
## É uma CENA, não um `--script`: em `--script` os autoloads (Som, EstadoJogo)
## não existem e os scripts dos inimigos não compilam.
## Uso (precisa de janela; no 2.º monitor):
##   Godot --window --screen 1 --path . res://tools/shot_inimigos_9d9e.tscn -- <pasta_saida>

const NIVEIS := [
	"res://scenes/levels/Floresta_Putrefata.tscn",
	"res://scenes/levels/Pantano_dos_Sussurros.tscn",
	"res://scenes/levels/Ninho_da_Viuva_Negra.tscn",
	"res://scenes/levels/A_Arvore_que_Chora.tscn",
	"res://scenes/levels/Coracao_da_Floresta.tscn",
]
const FRAMES_MEDIDA := 240

var _saida := ""
var _medidas := {}
var _registo: Array = []
var _nivel_atual: Node = null


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://work/execution_9d_9e/runtime")
	DirAccess.make_dir_recursive_absolute(_saida)
	_correr.call_deferred()


func _correr() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var es := get_node_or_null("/root/EstadoJogo")
	for i in NIVEIS.size():
		if es:
			es.indice_nivel = int(es.NIVEIS.find(NIVEIS[i]))
			es.checkpoint = Vector2.ZERO
		var nivel := await _carregar(NIVEIS[i])
		_medidas["L%d" % (i + 1)] = await _medir()
		var alvos: Array = []
		for c in nivel.get_children():
			if c is DemonioBase:
				alvos.append(c)
		for e: DemonioBase in alvos:
			if is_instance_valid(e):
				await _provar(nivel, e, "L%d" % (i + 1))
		if i == 1 or i == 2:
			nivel = await _carregar(NIVEIS[i])
			await _crias(nivel, "L%d" % (i + 1))
	var f := FileAccess.open(_saida.path_join("registo_9d9e.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"desempenho": _medidas, "capturas": _registo}, "  "))
	f.close()
	print("9D+9E runtime: ", JSON.stringify(_medidas))
	get_tree().quit(0)


func _carregar(cena: String) -> Node:
	if is_instance_valid(_nivel_atual):
		_nivel_atual.free()
	var nivel := (load(cena) as PackedScene).instantiate()
	get_tree().root.add_child(nivel)
	_nivel_atual = nivel
	for _i in 30:
		await get_tree().process_frame
	return nivel


## Koliani a 150 px à esquerda do bicho, imortal para a foto não acabar em
## game over (a IA do bicho continua a correr -- é runtime a sério).
func _encostar(e: Node2D) -> void:
	var k := get_tree().get_first_node_in_group("koliani") as Node2D
	if k == null:
		return
	if "vida" in k:
		k.vida = 99999
	k.global_position = e.global_position + Vector2(-150.0, -10.0)
	if "velocity" in k:
		k.velocity = Vector2.ZERO
	if k.has_method("reset_physics_interpolation"):
		k.reset_physics_interpolation()


func _foto(nome: String, e: Node) -> void:
	var img := get_viewport().get_texture().get_image()
	var cam := _saida.path_join(nome + ".png")
	img.save_png(cam)
	var arte := ""
	var anim := e.get_node_or_null("Sprite/Anim") as AnimatedSprite2D if is_instance_valid(e) else null
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation(anim.animation):
		var t := anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
		arte = t.resource_path if t else ""
		if t is AtlasTexture:
			arte = (t as AtlasTexture).atlas.resource_path
	_registo.append({"png": cam, "anim": anim.animation if anim else "", "textura": arte})
	print(nome, "  anim=", anim.animation if anim else "-", "  textura=", arte)


func _provar(_nivel: Node, e: DemonioBase, pref: String) -> void:
	var id := String(e.get("rig")) if e.is_in_group("chefes") else (e.identidade_visual if e.identidade_visual != "" else e.especie)
	var nome := "%s_%s_%s" % [pref, e.name, id]
	_encostar(e)
	for _i in 40:
		await get_tree().process_frame
	await _foto(nome + "_1_idle", e)
	if not is_instance_valid(e):
		return
	e.set("_telegrafo", 0.45)
	for _i in 8:
		await get_tree().process_frame
	await _foto(nome + "_2_telegrafo", e)
	if not is_instance_valid(e):
		return
	e.receber_dano(1, 1.0)
	for _i in 3:
		await get_tree().process_frame
	await _foto(nome + "_3_hit", e)
	if not is_instance_valid(e) or e.is_in_group("chefes"):
		# chefes: a morte abre diálogo/porta -- prova-se a morte só nos comuns
		return
	e.receber_dano(99999, 1.0)
	for _i in 14:
		await get_tree().process_frame
	await _foto(nome + "_4_dead", e)


func _crias(nivel: Node, pref: String) -> void:
	var chefe: Node2D = null
	for c in nivel.get_children():
		if c is ChefeMorvanna or c is ChefeRainhaAracnidea:
			chefe = c
	if chefe == null:
		return
	_encostar(chefe)
	if chefe is ChefeMorvanna:
		chefe.call("_largar_clones")
	else:
		chefe.call("_ovo_em", chefe.global_position.x - 70.0, 0.4)
		chefe.call("_ovo_em", chefe.global_position.x + 40.0, 0.4)
	# tempo de parede, não frames: sem vsync 90 frames são ~45 ms e o ovo
	# ainda não eclodiu (abana ~0,4 s)
	await get_tree().create_timer(1.5).timeout
	# pela identidade, não pelo índice: projéteis libertados deslocam os índices
	var cria: Node = null
	for c in nivel.get_children():
		if c is DemonioBase and c.identidade_visual != "":
			cria = c
	await _foto("%s_crias_%s" % [pref, "clone_morvanna" if chefe is ChefeMorvanna else "cria_rainha"], cria if cria else chefe)


func _medir() -> Dictionary:
	for _i in 20:
		await get_tree().process_frame
	var tempos: Array[float] = []
	var t0 := Time.get_ticks_usec()
	for _i in FRAMES_MEDIDA:
		await get_tree().process_frame
		var t1 := Time.get_ticks_usec()
		tempos.append(float(t1 - t0) / 1000.0)
		t0 = t1
	tempos.sort()
	var soma := 0.0
	for t in tempos:
		soma += t
	return {"media_ms": snappedf(soma / tempos.size(), 0.01),
		"p95_ms": snappedf(tempos[int(tempos.size() * 0.95)], 0.01),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
