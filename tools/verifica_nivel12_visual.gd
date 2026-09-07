extends Node
## Validação visual pesada do nível 12. Usa renderer real, guarda capturas em
## work/execution_1b e não entra na suite rápida de CI.
##
## Godot --rendering-method gl_compatibility --path . \
##   res://tools/verifica_nivel12_visual.tscn

const INDICE := 11
const CENA := "res://scenes/levels/Torre_dos_Ventos.tscn"
const PERFIS := [
	{"id": "16x9", "tam": Vector2i(1280, 720)},
	{"id": "mobile_largo", "tam": Vector2i(1560, 720)},
	{"id": "tablet", "tam": Vector2i(1024, 768)},
]
const NOMES_PONTOS := ["inicio", "25", "50", "75", "final"]

var _estado: Node
var _falhas: Array[String] = []
var _metricas: Array[Dictionary] = []


func _ready() -> void:
	call_deferred("_correr")


func _correr() -> void:
	_estado = get_node_or_null("/root/EstadoJogo")
	if _estado == null:
		_falhar("autoload EstadoJogo ausente")
		_terminar()
		return
	_estado.modo_teste = true
	_estado.modo_dev = true
	_estado.indice_nivel = INDICE
	_estado.checkpoint = Vector2.ZERO
	if _estado.has_method("_limpar_jornada_ancora"):
		_estado._limpar_jornada_ancora()
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://work/execution_1b"))

	var cena := await _carregar()
	if cena == null:
		_terminar()
		return
	_validar_estrutura(cena)
	for perfil in PERFIS:
		DisplayServer.window_set_size(perfil["tam"])
		await get_tree().create_timer(0.15, true, false, true).timeout
		var pontos := _pontos_representativos(cena)
		if pontos.size() < NOMES_PONTOS.size():
			_falhar("%s: faltam pontos representativos" % perfil["id"])
			continue
		for i in NOMES_PONTOS.size():
			await _capturar_ponto(cena, perfil["id"], NOMES_PONTOS[i], pontos[i])

	cena = await _morte_respawn(cena)
	if cena != null:
		DisplayServer.window_set_size(Vector2i(1280, 720))
		await get_tree().create_timer(0.6, true, false, true).timeout
		await _capturar_estado(cena, "pos_respawn")
		var anterior := cena
		get_tree().reload_current_scene()
		await get_tree().create_timer(0.4, true, false, true).timeout
		cena = get_tree().current_scene
		if cena == null or cena == anterior:
			_falhar("reload explicito nao substituiu a cena")
		else:
			await get_tree().create_timer(0.5, true, false, true).timeout
			await _capturar_estado(cena, "pos_reload")
			_validar_estrutura(cena)
	_terminar()


func _carregar() -> Node:
	if _estado.NIVEIS[INDICE] != CENA:
		_falhar("indice 12 nao aponta para Torre_dos_Ventos")
		return null
	# O runner deixa de ser a current_scene, mas permanece sob /root. Assim a
	# troca e os reloads seguintes usam exatamente a API do jogo sem matarem
	# a própria bancada.
	get_tree().current_scene = null
	var erro := get_tree().change_scene_to_file(CENA)
	if erro != OK:
		_falhar("Torre_dos_Ventos nao carregou (%d)" % erro)
		return null
	await get_tree().create_timer(0.5, true, false, true).timeout
	if get_tree().current_scene == null:
		_falhar("Torre_dos_Ventos nao se tornou a cena corrente")
	return get_tree().current_scene


func _validar_estrutura(cena: Node) -> void:
	var atm := cena.get_node_or_null("Atmosfera")
	if atm == null:
		_falhar("Atmosfera ausente")
		return
	var mod := atm.get_node_or_null("Modulacao") as CanvasModulate
	if mod == null:
		_falhar("CanvasModulate ausente")
	elif _luminancia_cor(mod.color) < 0.2:
		_falhar("CanvasModulate em valor de blackout: %s" % mod.color)
	var ceu := atm.get_node_or_null("Parallax/Ceu") as ParallaxLayer
	if ceu == null or ceu.motion_scale != Vector2.ZERO:
		_falhar("ceu fixo a viewport ausente ou com parallax")
	else:
		var spr := ceu.get_child(0) as Sprite2D if ceu.get_child_count() > 0 else null
		if spr == null or spr.texture == null:
			_falhar("ceu fixo sem textura")
		else:
			var cobertura := Vector2(spr.texture.get_size()) * spr.scale
			if cobertura.x < 1560.0 or cobertura.y < 768.0:
				_falhar("ceu nao cobre o maior viewport: %s" % cobertura)
	for nome in ["Fundo", "Longe", "Meio", "Perto"]:
		var layer := atm.get_node_or_null("Parallax/%s" % nome) as ParallaxLayer
		if layer == null:
			_falhar("camada de parallax %s ausente" % nome)
			continue
		var tem_textura := false
		for filho in layer.get_children():
			if filho is Sprite2D and filho.texture != null and filho.has_meta("gerado"):
				tem_textura = true
				break
		if tem_textura and layer.motion_mirroring.x <= 0.0:
			_falhar("camada texturada %s nao repete horizontalmente" % nome)


func _pontos_representativos(cena: Node) -> Array[Vector2]:
	var checks: Array[Vector2] = []
	for n in get_tree().get_nodes_in_group("checkpoints"):
		if n is Node2D and cena.is_ancestor_of(n) and not n.is_queued_for_deletion():
			checks.append(n.global_position)
	checks.sort_custom(func(a, b): return a.x < b.x)
	var pontos: Array[Vector2] = []
	if checks.is_empty():
		return pontos
	for f in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var idx := clampi(roundi(f * (checks.size() - 1)), 0, checks.size() - 1)
		pontos.append(checks[idx])
	return pontos


func _capturar_ponto(cena: Node, perfil: String, nome: String,
		ponto: Vector2) -> void:
	var k := get_tree().get_first_node_in_group("koliani") as CharacterBody2D
	if k == null or not cena.is_ancestor_of(k):
		_falhar("%s/%s: Koliani ausente" % [perfil, nome])
		return
	k.global_position = ponto + Vector2(0.0, -40.0)
	k.velocity = Vector2.ZERO
	k.call("_desencravar")
	await get_tree().create_timer(0.35, true, false, true).timeout
	await _guardar_metrica("n12_%s_%s" % [perfil, nome])


func _capturar_estado(cena: Node, nome: String) -> void:
	var k := get_tree().get_first_node_in_group("koliani") as CharacterBody2D
	if k == null or not cena.is_ancestor_of(k):
		_falhar("%s: Koliani ausente" % nome)
		return
	if not k.visible or k.modulate.a < 0.9:
		_falhar("%s: estado visual da Koliani incorreto" % nome)
	await _guardar_metrica("n12_16x9_%s" % nome)


func _morte_respawn(cena: Node) -> Node:
	var checks := _pontos_representativos(cena)
	if checks.is_empty():
		_falhar("sem checkpoint para morte/respawn")
		return cena
	var alvo: Vector2 = checks[-1]
	_estado.definir_checkpoint(alvo)
	var k := get_tree().get_first_node_in_group("koliani") as CharacterBody2D
	if k == null:
		_falhar("Koliani ausente antes da morte")
		return cena
	var anterior := cena
	var vidas_antes := int(_estado.vidas)
	k.call("_morrer")
	await get_tree().create_timer(0.8, true, false, true).timeout
	if get_tree().current_scene == null or get_tree().current_scene == anterior:
		var trans := get_node_or_null("/root/Transicao")
		var tween_valido := false
		var alpha := -1.0
		if trans:
			var tw: Variant = trans.get("_tween")
			tween_valido = tw != null and (tw as Tween).is_valid()
			var rect: Variant = trans.get("_rect")
			if rect is ColorRect:
				alpha = rect.color.a
		_falhar("morte nao produziu respawn/reload "
			+ "(a_morrer=%s, vidas=%d->%d, tween=%s, alpha=%.2f)"
			% [k.get("_a_morrer"), vidas_antes, int(_estado.vidas),
				tween_valido, alpha])
		return null
	return get_tree().current_scene


func _guardar_metrica(id: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var caminho := "res://work/execution_1b/%s.png" % id
	var erro := img.save_png(caminho)
	if erro != OK:
		_falhar("%s: nao guardou PNG (%d)" % [id, erro])
		return
	var soma := 0.0
	var soma2 := 0.0
	var escuros := 0
	var visiveis := 0
	var total := 0
	for y in range(0, img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			var lum := _luminancia_cor(img.get_pixel(x, y)) * 255.0
			soma += lum
			soma2 += lum * lum
			if lum < 32.0:
				escuros += 1
			if lum > 4.0:
				visiveis += 1
			total += 1
	var media := soma / maxf(total, 1)
	var desvio := sqrt(maxf(0.0, soma2 / maxf(total, 1) - media * media))
	var pct_escuro := 100.0 * escuros / maxf(total, 1)
	var pct_visivel := 100.0 * visiveis / maxf(total, 1)
	var metrica := {"id": id, "media": media, "desvio": desvio,
		"escuro": pct_escuro, "visivel": pct_visivel}
	_metricas.append(metrica)
	print("%-30s media=%5.1f desvio=%5.1f <32=%5.1f%% >4=%5.1f%%"
		% [id, media, desvio, pct_escuro, pct_visivel])
	if media < 2.0 or desvio < 1.0 or pct_visivel < 2.0:
		_falhar("%s: frame efetivamente sem conteudo visual" % id)


func _luminancia_cor(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


func _falhar(msg: String) -> void:
	if not _falhas.has(msg):
		_falhas.append(msg)
	printerr("FALHOU: ", msg)


func _terminar() -> void:
	var classificacao := "CONFIRMED BUG" if not _falhas.is_empty() else "NEEDS DEVICE VALIDATION"
	print("\nCLASSIFICACAO NIVEL 12: ", classificacao)
	print("CAPTURAS/METRICAS: ", _metricas.size())
	if not _falhas.is_empty():
		for f in _falhas:
			printerr("  - ", f)
	_estado.modo_teste = false
	_estado.modo_dev = false
	get_tree().quit(1 if not _falhas.is_empty() else 0)
