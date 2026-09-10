@tool
extends Node2D
## Execution 5C — amostra visual Hybrid Cinematic 2D da Região I.
##
## Este módulo só desenha apresentação. Não cria corpos, áreas, colisões nem
## altera a geometria existente. No Level 1 mantém a integração 6A completa;
## nos restantes níveis da Região I pode montar apenas o panorama aprovado.
## `ativo = false` é o interruptor de rollback.

@export var ativo := true
@export var apenas_panorama_aprovado := false
@export var limite_esquerdo := -2550.0
@export var limite_direito := 3850.0

const COR_CEU_ALTO := Color("07111d")
const COR_CEU_MEIO := Color("0b1c25")
const COR_CEU_BAIXO := Color("132620")
const COR_SILHUETA_LONGE := Color("0a1519")
const COR_SILHUETA_MEIO := Color("10241f")
const COR_TRONCO := Color("13201b")
const COR_TRONCO_LUZ := Color("274134")
const COR_MUSGO := Color("56885b")
const COR_MUSGO_LUZ := Color("91bd77")
const COR_PEDRA := Color("17231f")
const COR_PEDRA_LUZ := Color("31463a")
const COR_CORRUPCAO := Color("8c295d")
const COR_CORRUPCAO_FUNDO := Color("421332")
const COR_SHADOWBLADE := Color("bb8cff")
const COR_SHADOWBLADE_NUCLEO := Color("f1e5ff")
const TEX_BACKGROUND_APPROVED := preload("res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_heart_tree.png")
const TEX_BACKGROUND_LEFT := preload("res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_left_cap.png")
const TEX_BACKGROUND_RIGHT := preload("res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_right_cap.png")
const TEX_FLORESTA_BACK := preload("res://assets/sprites/pixel/backgrounds/floresta/back.png")
const TEX_FLORESTA_MIDDLE := preload("res://assets/sprites/pixel/backgrounds/floresta/middle.png")
const TEX_FLORESTA_FRONT := preload("res://assets/sprites/pixel/backgrounds/floresta/front.png")

var _restauro_hud: Array[Dictionary] = []
var _hud_aplicado := false


class AssinaturaLamina:
	extends Node2D
	var alvo: Node
	var limite_esquerdo := -300.0
	var limite_direito := 1250.0
	var pulso := 0.0
	var luz: PointLight2D

	func _ready() -> void:
		z_index = 8
		luz = PointLight2D.new()
		luz.texture = _textura_luz()
		luz.color = Color("c49cff")
		luz.energy = 1.15
		luz.scale = Vector2(0.72, 0.58)
		luz.position = Vector2(18, -7)
		add_child(luz)
		visible = false

	func _process(dt: float) -> void:
		if alvo == null or not is_instance_valid(alvo):
			visible = false
			return
		pulso += dt
		var valor_restante: Variant = alvo.get("_ataque_restante")
		var restante := float(valor_restante) \
			if typeof(valor_restante) in [TYPE_FLOAT, TYPE_INT] else 0.0
		visible = restante > 0.0 and alvo.global_position.x >= limite_esquerdo \
			and alvo.global_position.x <= limite_direito
		if visible:
			luz.energy = 1.0 + sin(pulso * 18.0) * 0.18
			queue_redraw()

	func _draw() -> void:
		var centro := Vector2(11, -8)
		draw_arc(centro, 38.0, -1.28, 1.12, 28,
			Color(0.62, 0.30, 1.0, 0.23), 11.0, true)
		draw_arc(centro, 36.0, -1.25, 1.08, 28,
			Color("bb8cff"), 5.0, true)
		draw_arc(centro, 34.0, -1.20, 1.02, 28,
			Color("f1e5ff"), 1.7, true)
		draw_circle(Vector2(38, -27), 4.2, Color("f1e5ff"))

	func _textura_luz() -> GradientTexture2D:
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
		grad.colors = PackedColorArray([
			Color(1, 1, 1, 0.95), Color(0.75, 0.45, 1, 0.32), Color(0.5, 0.2, 1, 0),
		])
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.width = 192
		tex.height = 192
		tex.fill = 1
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		return tex


func _ready() -> void:
	if not ativo:
		visible = false
		set_process(false)
		return
	set_meta("visual_target_5c", true)
	set_meta("intervalo_target", Vector2(limite_esquerdo, limite_direito))
	_montar_background()
	_montar_heart_tree()
	_montar_midground()
	_montar_foreground()
	if apenas_panorama_aprovado:
		return
	_montar_superficies()
	_montar_corrupcao()
	_montar_atmosfera()
	_montar_luzes()
	_ligar_shadowblade.call_deferred()


func _exit_tree() -> void:
	_restaurar_skin_hud()


func _montar_background() -> void:
	var camada := Node2D.new()
	camada.name = "BackgroundApproved08"
	camada.z_index = -30
	camada.set_meta("approved_source", "08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png")
	camada.set_meta("derivation", "crop lossless (18,97,952,247) + mirrored edge caps")
	add_child(camada)

	# O panorama aprovado fica em escala uniforme 4x. Os caps usam as próprias
	# extremidades espelhadas: o limite casa pixel a pixel, a Heart Tree não se
	# repete e nenhuma área da prancha exterior entra no runtime.
	_sprite_aprovado(camada, TEX_BACKGROUND_APPROVED, Vector2(-1254, -134), Vector2(4, 4))
	_sprite_aprovado(camada, TEX_BACKGROUND_LEFT, Vector2(-1254, -134), Vector2(-4, 4))
	_sprite_aprovado(camada, TEX_BACKGROUND_LEFT, Vector2(-3814, -134), Vector2(4, 4))
	_sprite_aprovado(camada, TEX_BACKGROUND_RIGHT, Vector2(3842, -134), Vector2(-4, 4))


func _montar_heart_tree() -> void:
	var camada := Node2D.new()
	camada.name = "LandmarkHeartTreeApproved08"
	camada.z_index = -18
	camada.set_meta("baked_into", "BackgroundApproved08")
	camada.set_meta("production_status", "approved_crop")
	add_child(camada)


func _montar_midground() -> void:
	var camada := Node2D.new()
	camada.name = "MidgroundProductionAssetsMissing"
	camada.z_index = -8
	camada.set_meta("production_status", "approved design; separate alpha layers missing")
	add_child(camada)


func _montar_superficies() -> void:
	var camada := Node2D.new()
	camada.name = "GameplayPlaneLegacyRetained"
	camada.z_index = 2
	camada.set_meta("production_status", "legacy temporary; approved alpha tiles missing")
	add_child(camada)


func _montar_corrupcao() -> void:
	var camada := Node2D.new()
	camada.name = "CorruptionSample"
	camada.z_index = 4
	add_child(camada)

	# Crescimento contaminado junto ao terceiro passo: preto, violeta sujo e
	# magenta orgânico. Não toca em colisões nem assinala perigo de gameplay.
	_poligono(camada, PackedVector2Array([
		Vector2(1080, 637), Vector2(1070, 604), Vector2(1084, 580),
		Vector2(1090, 608), Vector2(1104, 565), Vector2(1110, 611),
		Vector2(1128, 586), Vector2(1120, 637),
	]), Color("120b14"))
	_linha(camada, PackedVector2Array([
		Vector2(1087, 636), Vector2(1090, 609), Vector2(1082, 587),
	]), 4.0, COR_CORRUPCAO_FUNDO)
	_linha(camada, PackedVector2Array([
		Vector2(1102, 636), Vector2(1106, 607), Vector2(1123, 589),
	]), 3.0, COR_CORRUPCAO)
	for p in [Vector2(1084, 585), Vector2(1106, 604), Vector2(1123, 589)]:
		_circulo(camada, p, 5.0, Color(0.76, 0.16, 0.43, 0.62), 14)
		_circulo(camada, p, 2.0, Color("d14a81"), 10)


func _montar_atmosfera() -> void:
	var camada := Node2D.new()
	camada.name = "AtmosphereVFX"
	camada.z_index = -4
	add_child(camada)

	for dados in [
		[Rect2(-520, 500, 1050, 88), Color(0.34, 0.58, 0.55, 0.08), 18.0],
		[Rect2(250, 440, 1180, 112), Color(0.48, 0.61, 0.66, 0.07), -24.0],
		[Rect2(-280, 600, 1600, 70), Color(0.26, 0.47, 0.42, 0.09), 11.0],
	]:
		var nevoa := _faixa_nevoa(camada, dados[0], dados[1])
		var origem := nevoa.position.x
		var tw := create_tween().set_loops()
		tw.tween_property(nevoa, "position:x", origem + dados[2], 5.5)
		tw.tween_property(nevoa, "position:x", origem, 5.5)

	var particulas := CPUParticles2D.new()
	particulas.name = "SporesLeaves"
	particulas.position = Vector2(470, 390)
	particulas.amount = 34
	particulas.lifetime = 7.5
	particulas.preprocess = 5.0
	particulas.lifetime_randomness = 0.55
	particulas.emission_shape = 3
	particulas.emission_rect_extents = Vector2(780, 310)
	particulas.direction = Vector2(0.3, -1.0)
	particulas.spread = 42.0
	particulas.gravity = Vector2(5.0, -3.0)
	particulas.initial_velocity_min = 3.0
	particulas.initial_velocity_max = 11.0
	particulas.scale_amount_min = 0.7
	particulas.scale_amount_max = 2.2
	particulas.color = Color(0.68, 0.88, 0.67, 0.45)
	particulas.texture = _textura_particula()
	camada.add_child(particulas)


func _montar_foreground() -> void:
	var camada := Node2D.new()
	camada.name = "ForegroundApprovedBaked"
	camada.z_index = 12
	camada.set_meta("baked_into", "BackgroundApproved08")
	camada.set_meta("production_status", "approved crop; separate alpha layer missing")
	add_child(camada)


func _montar_luzes() -> void:
	var camada := Node2D.new()
	camada.name = "SelectiveLighting"
	camada.z_index = 3
	add_child(camada)
	_luz(camada, Vector2(245, 620), Color("7ebda0"), 0.58, Vector2(2.0, 1.25))
	_luz(camada, Vector2(760, 545), Color("789db0"), 0.42, Vector2(2.4, 1.6))
	_luz(camada, Vector2(1105, 600), Color("8c295d"), 0.34, Vector2(0.8, 0.8))


func _ligar_shadowblade() -> void:
	if not ativo or not is_inside_tree():
		return
	var koliani := get_tree().get_first_node_in_group("koliani")
	if koliani == null:
		return
	var assinatura := AssinaturaLamina.new()
	assinatura.name = "HybridShadowbladeSignature"
	assinatura.alvo = koliani
	assinatura.limite_esquerdo = limite_esquerdo
	assinatura.limite_direito = limite_direito
	koliani.add_child(assinatura)


func _aplicar_skin_hud() -> void:
	if not ativo or not is_inside_tree():
		return
	# Main cria o HUD depois do nível; duas esperas mantêm esta integração local.
	for _i in 3:
		await get_tree().process_frame
	var hud := get_tree().root.find_child("HUD", true, false)
	if hud == null:
		return
	for caminho in ["Vida/Barra", "Energia/Barra"]:
		var barra := hud.get_node_or_null(caminho) as ProgressBar
		if barra == null:
			continue
		_restauro_hud.append({
			"barra": barra,
			"background": barra.get_theme_stylebox("background"),
			"fill": barra.get_theme_stylebox("fill"),
			"modulate": barra.modulate,
		})
		var fundo := StyleBoxFlat.new()
		fundo.bg_color = Color(0.015, 0.025, 0.035, 0.94)
		fundo.border_color = Color(0.28, 0.42, 0.40, 0.78)
		fundo.set_border_width_all(2)
		fundo.set_corner_radius_all(2)
		fundo.shadow_color = Color(0, 0, 0, 0.62)
		fundo.shadow_size = 5
		var enchimento := StyleBoxFlat.new()
		enchimento.bg_color = Color("9d344f") if caminho.begins_with("Vida") \
			else COR_SHADOWBLADE
		enchimento.border_color = Color("e0808f") if caminho.begins_with("Vida") \
			else COR_SHADOWBLADE_NUCLEO
		enchimento.set_border_width_all(1)
		enchimento.set_corner_radius_all(1)
		barra.add_theme_stylebox_override("background", fundo)
		barra.add_theme_stylebox_override("fill", enchimento)
		barra.modulate = Color(1, 1, 1, 0.96)
	_hud_aplicado = not _restauro_hud.is_empty()


func _restaurar_skin_hud() -> void:
	if not _hud_aplicado:
		return
	for dados in _restauro_hud:
		var barra: ProgressBar = dados.get("barra")
		if barra == null or not is_instance_valid(barra):
			continue
		barra.add_theme_stylebox_override("background", dados["background"])
		barra.add_theme_stylebox_override("fill", dados["fill"])
		barra.modulate = dados["modulate"]
	_restauro_hud.clear()
	_hud_aplicado = false


func _superficie(camada: Node2D, x0: float, x1: float, topo: float,
		profundidade: float, semente: int) -> void:
	var pontos_topo := PackedVector2Array()
	var passos := maxi(3, int((x1 - x0) / 28.0))
	for i in passos + 1:
		var t := float(i) / float(passos)
		var x := lerpf(x0, x1, t)
		var irregular := sin(float(i * 7 + semente)) * 3.0 + float(posmod(i + semente, 3))
		pontos_topo.append(Vector2(x, topo + irregular))
	var corpo := pontos_topo.duplicate()
	corpo.append(Vector2(x1 + 5, topo + profundidade))
	corpo.append(Vector2(x0 - 5, topo + profundidade + 12))
	_poligono(camada, corpo, COR_PEDRA)
	_linha(camada, pontos_topo, 10.0, Color("263b30"))
	_linha(camada, pontos_topo, 3.0, COR_MUSGO_LUZ)

	# Estratos, lascas e raízes dão volume sem repetir uma grelha de blocos.
	var meio := (x0 + x1) * 0.5
	_linha(camada, PackedVector2Array([
		Vector2(x0 + 16, topo + 30), Vector2(meio - 20, topo + 42),
		Vector2(x1 - 14, topo + 28),
	]), 3.0, COR_PEDRA_LUZ)
	for x in range(int(x0 + 34), int(x1 - 10), 92):
		_linha(camada, PackedVector2Array([
			Vector2(x, topo + 5), Vector2(x + 8, topo + 34),
			Vector2(x - 4, topo + profundidade - 5),
		]), 4.0, Color(0.22, 0.34, 0.24, 0.7))
	for x in range(int(x0 + 24), int(x1 - 18), 58):
		var y := topo + 22.0 + float(posmod(x + semente * 13, maxi(18, int(profundidade - 42.0))))
		var w := 20.0 + float(posmod(x * 3 + semente, 24))
		_poligono(camada, PackedVector2Array([
			Vector2(x - w * 0.5, y), Vector2(x - w * 0.28, y - 8),
			Vector2(x + w * 0.34, y - 6), Vector2(x + w * 0.5, y + 3),
			Vector2(x + w * 0.16, y + 10), Vector2(x - w * 0.4, y + 7),
		]), Color(0.16, 0.24, 0.20, 0.92))
		_linha(camada, PackedVector2Array([
			Vector2(x - w * 0.3, y - 1), Vector2(x + w * 0.26, y - 3),
		]), 1.5, Color(0.34, 0.47, 0.38, 0.62))
	for x in range(int(x0 + 18), int(x1 - 10), 76):
		var p := Vector2(x, topo - 2)
		for i in 4:
			var a := lerpf(-2.55, -0.58, float(i) / 3.0)
			_linha(camada, PackedVector2Array([
				p, p + Vector2(cos(a), sin(a)) * (10.0 + float(posmod(x + i * 7, 9))),
			]), 2.2, COR_MUSGO)


func _tronco_distante(camada: Node2D, base: Vector2, altura: float,
		largura: float, cor: Color) -> void:
	_poligono(camada, PackedVector2Array([
		base + Vector2(-largura * 0.5, 0), base + Vector2(-largura * 0.28, -altura),
		base + Vector2(0, -altura - 45), base + Vector2(largura * 0.32, -altura),
		base + Vector2(largura * 0.5, 0),
	]), cor)
	_linha(camada, PackedVector2Array([
		base + Vector2(0, -altura * 0.55), base + Vector2(-largura * 1.7, -altura * 0.82),
	]), largura * 0.35, cor)
	_linha(camada, PackedVector2Array([
		base + Vector2(0, -altura * 0.68), base + Vector2(largura * 1.8, -altura * 0.92),
	]), largura * 0.32, cor)


func _arbusto(camada: Node2D, base: Vector2, escala: float,
		cor: Color, luz: Color) -> void:
	for i in 7:
		var a := lerpf(-2.75, -0.38, float(i) / 6.0)
		var fim := base + Vector2(cos(a), sin(a)) * (30.0 + float(posmod(i * 13, 18))) * escala
		_linha(camada, PackedVector2Array([base, fim]), 5.0 * escala, cor)
		_circulo(camada, fim, 7.0 * escala, luz, 12)


func _folhas(camada: Node2D, centro: Vector2, cor: Color) -> void:
	for i in 8:
		var a := float(i) * TAU / 8.0
		var p := centro + Vector2(cos(a), sin(a)) * (18.0 + float(posmod(i * 9, 16)))
		_poligono(camada, PackedVector2Array([
			p + Vector2(-10, 0), p + Vector2(0, -5), p + Vector2(12, 1), p + Vector2(0, 5),
		]), cor)


func _faixa_nevoa(camada: Node2D, rect: Rect2, cor: Color) -> Polygon2D:
	var pontos := PackedVector2Array()
	var segmentos := 14
	for i in segmentos + 1:
		var t := float(i) / float(segmentos)
		pontos.append(Vector2(rect.position.x + rect.size.x * t,
			rect.position.y + sin(t * TAU * 2.0) * 13.0))
	for i in range(segmentos, -1, -1):
		var t := float(i) / float(segmentos)
		pontos.append(Vector2(rect.position.x + rect.size.x * t,
			rect.end.y + sin(t * TAU * 2.0 + 1.4) * 10.0))
	return _poligono(camada, pontos, cor)


func _luz(camada: Node2D, pos: Vector2, cor: Color, energia: float,
		escala: Vector2) -> PointLight2D:
	var luz := PointLight2D.new()
	luz.position = pos
	luz.color = cor
	luz.energy = energia
	luz.scale = escala
	luz.texture = _textura_luz()
	camada.add_child(luz)
	return luz


func _textura_luz() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.36, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	tex.fill = 1
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func _textura_particula() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 0.9), Color(0.7, 1, 0.8, 0.5), Color(0.5, 0.8, 0.6, 0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 10
	tex.height = 10
	tex.fill = 1
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func _rect(camada: Node2D, rect: Rect2, cor: Color) -> Polygon2D:
	return _poligono(camada, PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y),
	]), cor)


func _circulo(camada: Node2D, centro: Vector2, raio: float, cor: Color,
		segmentos := 24) -> Polygon2D:
	var pontos := PackedVector2Array()
	for i in segmentos:
		var a := float(i) * TAU / float(segmentos)
		pontos.append(centro + Vector2(cos(a), sin(a)) * raio)
	return _poligono(camada, pontos, cor)


func _poligono(camada: Node2D, pontos: PackedVector2Array,
		cor: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pontos
	p.color = cor
	camada.add_child(p)
	return p


func _sprite(camada: Node2D, textura: Texture2D, pos: Vector2,
		escala: Vector2, cor: Color) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura
	s.centered = false
	s.position = pos
	s.scale = escala
	s.modulate = cor
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	camada.add_child(s)
	return s


func _sprite_aprovado(camada: Node2D, textura: Texture2D, pos: Vector2,
		escala: Vector2) -> Sprite2D:
	var s := _sprite(camada, textura, pos, escala, Color.WHITE)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return s


func _linha(camada: Node2D, pontos: PackedVector2Array, largura: float,
		cor: Color) -> Line2D:
	var l := Line2D.new()
	l.points = pontos
	l.width = largura
	l.default_color = cor
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	camada.add_child(l)
	return l
