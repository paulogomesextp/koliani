extends SceneTree
## Execution 9H.7 — auditoria do fundo da Região I e prova de runtime.
##
## Para cada um de L1–L5: monta o nível, conta o que cada camada de parallax
## tem (por peça), mede a ampliação que sobra para o filtro bilinear do GPU
## em cada sprite de fundo, e grava um PNG com a câmara em 4 pontos do nível
## (15 %, 40 %, 65 %, 90 % da largura) — o fundo só se audita andando, porque
## quase tudo está fora do ecrã do ponto de partida.
##
## Uso (precisa de janela; no 2.º monitor para não roubar o ecrã ao Paulo):
##   Godot --window --screen 1 --path . --script res://tools/auditoria_fundo_9h7.gd -- <pasta> [prefixo]

const NIVEIS := [
	"res://scenes/levels/Floresta_Putrefata.tscn",
	"res://scenes/levels/Pantano_dos_Sussurros.tscn",
	"res://scenes/levels/Ninho_da_Viuva_Negra.tscn",
	"res://scenes/levels/A_Arvore_que_Chora.tscn",
	"res://scenes/levels/Coracao_da_Floresta.tscn",
]
const FRACOES := [0.15, 0.4, 0.65, 0.9]

var _saida := ""
var _prefixo := "depois"
var _relatorio := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://work/9h7")
	if args.size() > 1:
		_prefixo = args[1]
	DirAccess.make_dir_recursive_absolute(_saida)
	_correr.call_deferred()


func _correr() -> void:
	for i in NIVEIS.size():
		var nivel := await _carregar(NIVEIS[i])
		if nivel == null:
			continue
		var alvo := nivel.get_node_or_null("Region1HybridVisualTarget")
		var d := _medir(alvo)
		d["frame_ms"] = await _medir_frame()
		_relatorio["L%d" % (i + 1)] = d
		await _fotografar(nivel, alvo, i + 1)
	var f := FileAccess.open(_saida.path_join("auditoria_%s.json" % _prefixo),
		FileAccess.WRITE)
	f.store_string(JSON.stringify(_relatorio, "\t"))
	f.close()
	for chave in _relatorio:
		var d: Dictionary = _relatorio[chave]
		print("%s  ampliacao_max=%.2f  %s" % [chave, d.get("ampliacao_max", 0.0),
			JSON.stringify(d.get("pecas", {}))])
	quit(0)


## Tempo de frame por RELÓGIO DE PAREDE (o `delta` do motor mente: quando o
## frame estica, ele devolve o passo pedido e não o que custou).
func _medir_frame() -> Dictionary:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for _i in 30:
		await process_frame
	var amostras: Array[float] = []
	var t := Time.get_ticks_usec()
	for _i in 240:
		await process_frame
		var agora := Time.get_ticks_usec()
		amostras.append(float(agora - t) / 1000.0)
		t = agora
	amostras.sort()
	var soma := 0.0
	for a in amostras:
		soma += a
	return {
		"media": snappedf(soma / float(amostras.size()), 0.01),
		"p95": snappedf(amostras[int(float(amostras.size()) * 0.95)], 0.01),
		"draw_calls": RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
	}


func _carregar(cena: String) -> Node:
	if current_scene:
		current_scene.free()
	var pk := load(cena) as PackedScene
	var nivel := pk.instantiate()
	root.add_child(nivel)
	current_scene = nivel
	for _i in 40:
		await process_frame
	return nivel


## Conta as peças por camada e mede a ampliação no pixel do ecrã de cada
## sprite de fundo: `escala de desenho x zoom da camara`. Acima de ~1,2 o
## filtro bilinear está a interpolar, e é isso que se vê desfocado.
func _medir(alvo: Node) -> Dictionary:
	var pecas := {}
	var ampliacoes: Array[float] = []
	if alvo == null:
		return {"erro": "sem Region1HybridVisualTarget"}
	var zoom := 1.4
	var cam := root.get_viewport().get_camera_2d()
	if cam:
		zoom = cam.zoom.x
	for camada in alvo.get_children():
		if not camada is Node2D:
			continue
		var n := 0
		for s in camada.get_children():
			if s is Sprite2D:
				n += 1
				ampliacoes.append(absf(s.scale.x) * zoom)
		if n > 0:
			pecas[String(camada.name)] = n
	# Elementos altos: qualquer peça de fundo que cubra mais do que a altura do
	# ecrã (514 px de mundo a 1,4x) é suspeita -- foi assim que se identificou
	# a linha vertical escura da 9H.7.
	var altos: Array[String] = []
	for camada in alvo.get_children():
		if not camada is Node2D:
			continue
		for s in camada.get_children():
			if not s is Sprite2D or s.texture == null:
				continue
			var h: float = float(s.texture.get_height()) * absf(s.scale.y)
			var w: float = float(s.texture.get_width()) * absf(s.scale.x)
			if h > 520.0 or w < 12.0:
				altos.append("%s/%s %dx%d em %s" % [camada.name, s.name,
					int(w), int(h), s.position])
	if not altos.is_empty():
		print("  ALTOS: ", altos)
	ampliacoes.sort()
	return {
		"pecas": pecas,
		"sprites": ampliacoes.size(),
		"ampliacao_max": ampliacoes[-1] if not ampliacoes.is_empty() else 0.0,
		"ampliacao_mediana": ampliacoes[ampliacoes.size() / 2] if not ampliacoes.is_empty() else 0.0,
	}


func _fotografar(nivel: Node, alvo: Node, n: int) -> void:
	var koliani := nivel.get_tree().get_first_node_in_group("koliani") as Node2D
	if koliani == null or alvo == null:
		return
	var a := float(alvo.get("limite_esquerdo"))
	var b := float(alvo.get("limite_direito"))
	for k in FRACOES.size():
		var x: float = a + (b - a) * float(FRACOES[k])
		# pousa a Koliani no ar e congela-a: só se quer a câmara naquele x
		koliani.global_position = Vector2(x, 560.0)
		koliani.set("velocity", Vector2.ZERO)
		for _i in 24:
			koliani.global_position = Vector2(x, 560.0)
			koliani.set("velocity", Vector2.ZERO)
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png(_saida.path_join("%s_L%d_p%d.png" % [_prefixo, n, k + 1]))
