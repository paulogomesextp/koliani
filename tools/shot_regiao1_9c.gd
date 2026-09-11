extends SceneTree
## Execution 9C — prova de runtime da Região I.
##
## Para cada um de L1–L5: pousa a Koliani em cima de plataformas REAIS em três
## pontos do nível (15%, 50%, 85% da largura), grava um PNG de cada, e mede o
## tempo de frame de parede com o kit ligado e desligado (`ativo = false`, o
## rollback), com o vsync desligado.
##
## Uso (precisa de janela; no 2.º monitor para não roubar o ecrã):
##   Godot --window --screen 1 --path . --script res://tools/shot_regiao1_9c.gd -- <pasta_saida>

const NIVEIS := [
	"res://scenes/levels/Floresta_Putrefata.tscn",
	"res://scenes/levels/Pantano_dos_Sussurros.tscn",
	"res://scenes/levels/Ninho_da_Viuva_Negra.tscn",
	"res://scenes/levels/A_Arvore_que_Chora.tscn",
	"res://scenes/levels/Coracao_da_Floresta.tscn",
]
const FRACOES := [0.15, 0.5, 0.85]
const FRAMES_MEDIDA := 240

var _saida := ""
var _medidas := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://work/execution_9c/runtime")
	DirAccess.make_dir_recursive_absolute(_saida)
	_correr.call_deferred()


func _correr() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var es := root.get_node_or_null("/root/EstadoJogo")
	for i in NIVEIS.size():
		if es:
			es.indice_nivel = int(es.NIVEIS.find(NIVEIS[i]))
			es.checkpoint = Vector2.ZERO
		for kit in [true, false]:
			var nivel := await _carregar(NIVEIS[i], kit)
			if nivel == null:
				continue
			if kit:
				await _fotografar(nivel, i + 1)
			_medidas["L%d_%s" % [i + 1, "kit" if kit else "legado"]] = await _medir()
	var f := FileAccess.open(_saida.path_join("desempenho_9c.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_medidas, "  "))
	f.close()
	print("9C runtime: ", JSON.stringify(_medidas))
	quit(0)


func _carregar(cena: String, kit: bool) -> Node:
	if current_scene:
		current_scene.free()
	var pk := load(cena) as PackedScene
	var nivel := pk.instantiate()
	var alvo := nivel.get_node_or_null("Region1HybridVisualTarget")
	if alvo:
		alvo.ativo = kit
	root.add_child(nivel)
	current_scene = nivel
	for _i in 30:
		await process_frame
	return nivel


func _fotografar(nivel: Node, n: int) -> void:
	var k := get_first_node_in_group("koliani") as Node2D
	var alvo := nivel.get_node_or_null("Region1HybridVisualTarget")
	var esq: float = alvo.limite_esquerdo if alvo else 0.0
	var dir_: float = alvo.limite_direito if alvo else 3800.0
	var largura := 3800.0
	var atm := get_first_node_in_group("atmosfera")
	if atm and "largura_nivel" in atm:
		largura = float(atm.largura_nivel)
	var plataformas: Array = []
	for c in nivel.get_children():
		if c is StaticBody2D and "tamanho" in c and c.tamanho.x >= 120.0:
			plataformas.append(c)
	for j in FRACOES.size():
		var x := largura * float(FRACOES[j])
		var melhor: Node2D = null
		for p: Node2D in plataformas:
			if melhor == null or absf(p.position.x - x) < absf(melhor.position.x - x):
				melhor = p
		if k and melhor:
			k.global_position = Vector2(melhor.position.x,
				melhor.position.y - melhor.tamanho.y * 0.5 - 24.0)
			if "velocity" in k:
				k.velocity = Vector2.ZERO
			if k.has_method("reset_physics_interpolation"):
				k.reset_physics_interpolation()
		for _i in 40:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png(_saida.path_join("L%d_%d.png" % [n, j + 1]))
	var fundo := alvo.get_node_or_null("PrimeiroPlano") if alvo else null
	print("L%d: legado escondido=%s  primeiro plano topo=%s  intervalo=%s..%s" % [
		n, str(alvo.get_meta("legado_escondido", [])) if alvo else "-",
		str(fundo.get_meta("topo_mundo", -1)) if fundo else "-", esq, dir_])


func _medir() -> Dictionary:
	for _i in 20:
		await process_frame
	var tempos: Array[float] = []
	var t0 := Time.get_ticks_usec()
	for _i in FRAMES_MEDIDA:
		await process_frame
		var t1 := Time.get_ticks_usec()
		tempos.append(float(t1 - t0) / 1000.0)
		t0 = t1
	tempos.sort()
	var soma := 0.0
	for t in tempos:
		soma += t
	return {
		"media_ms": snappedf(soma / tempos.size(), 0.01),
		"p95_ms": snappedf(tempos[int(tempos.size() * 0.95)], 0.01),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"objetos_canvas": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"nos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	}
