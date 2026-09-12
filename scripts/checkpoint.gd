class_name Checkpoint
extends Area2D
## Guarda a posição de reaparecimento. A Koliani reaparece aqui enquanto
## tiver vidas; ao ficar sem vidas a campanha reinicia (ver
## `EstadoJogo.reiniciar_campanha`).
##
## Visual construído em código (ignora o `Visual`/`Luz` que a cena do nível
## traz): uma FOGUEIRA. Apagada é um monte de lenha fria; ao ser tocada
## pega fogo -- chama, brasas a subir e um halo AMARELO que treme. Pedido do
## Paulo (1 set 2026): o losango azul não lia como "ponto de regresso".

const COR_LENHA := Color(0.29, 0.19, 0.14)
const COR_LENHA_ACESA := Color(0.46, 0.29, 0.19)
const COR_PEDRA := Color(0.3, 0.3, 0.36)
const COR_LUZ := Color(1.0, 0.76, 0.32)
const LEVEL_SESSION := preload("res://scripts/level_session.gd")
const IDS_PROGRESSAO := preload("res://scripts/progression_ids.gd")

## Identidade persistente. Pode ser fixada explicitamente por conteúdo
## autoral; quando vazia, é atribuída pela ordem de percurso dos checkpoints
## ativos do nível (`checkpoint_level_005_03`, por exemplo).
@export var checkpoint_id := ""

var _ativo := false
var _t := 0.0
## Esta fogueira é a ÚLTIMA do nível -- a que está ao pé da arena. Acendê-la
## já arranca a música de combate do chefe. Pedido do Paulo (5 set 2026): a
## cama de chefe só entrava ao 1.º golpe (`ChefeBase.provocar`) e a tensão
## chegava tarde; ele quer-a a começar quando vê a fogueira.
var _ultimo := false
var _base: Node2D
var _lenha: Node2D
var _chama: CPUParticles2D
var _brasas: CPUParticles2D
var _nucleo: Polygon2D
var _luz: PointLight2D
## 9G: brilho de "pronta a usar" enquanto a fogueira está apagada.
var _pronta9g: AnimatedSprite2D
const Vfx9G := preload("res://scripts/vfx_regiao1.gd")


func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_ao_entrar)
	# esconde o visual antigo que vinha da cena do nível (poste + brilho)
	for nome in ["Visual", "Luz", "Brilho"]:
		var n := get_node_or_null(nome)
		if n and n is CanvasItem:
			(n as CanvasItem).visible = false
	_montar_visual()
	_pousar()
	# repete no fim do frame -- garante que as plataformas já estão no
	# espaço de física (senão a fogueira ficava a flutuar em alguns níveis).
	_pousar.call_deferred()
	# idem: o chefe só se junta ao grupo "chefes" no `_ready` dele, e o
	# `main.gd` só põe a cama de ambiente depois dos filhos -- avaliar (e
	# tocar) mais cedo seria pisado por essa cama.
	_avaliar_ultimo.call_deferred()
	_preparar_identidade.call_deferred()


func _preparar_identidade() -> void:
	# `NivelComChefe` reduz fogueiras em deferred. Esperar quatro frames garante
	# que a identidade descreve apenas o conjunto semanticamente ativo.
	for _i in 4:
		await get_tree().process_frame
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var level_id := IDS_PROGRESSAO.level_id_do_indice(EstadoJogo.indice_nivel)
	var checkpoints: Array[Node2D] = []
	for no in get_tree().get_nodes_in_group("checkpoints"):
		if no is Node2D and is_instance_valid(no) and not no.is_queued_for_deletion():
			checkpoints.append(no as Node2D)
	checkpoints.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		if not is_equal_approx(a.global_position.x, b.global_position.x):
			return a.global_position.x < b.global_position.x
		return a.global_position.y < b.global_position.y)
	var ordem := checkpoints.find(self) + 1
	if checkpoint_id == "" and ordem > 0:
		checkpoint_id = LEVEL_SESSION.id_checkpoint(level_id, ordem)
	if not LEVEL_SESSION.id_valido_para_nivel(checkpoint_id, level_id):
		push_warning("Checkpoint sem identidade valida em %s" % global_position)
		return
	if EstadoJogo.registar_checkpoint_disponivel(checkpoint_id, global_position):
		_ativar(true)
		var koliani := get_tree().get_first_node_in_group("koliani")
		if koliani and koliani.has_method("recuperar_no_checkpoint"):
			koliani.call_deferred("recuperar_no_checkpoint", global_position)
	# A primeira fogueira valida o conjunto completo. Um ID persistido que ja
	# nao existe converge para o spawn inicial, nunca para uma coordenada solta.
	if ordem == 1:
		var ids: Array[String] = []
		for i in checkpoints.size():
			var ck := checkpoints[i] as Checkpoint
			var id := ck.checkpoint_id
			if id == "":
				id = LEVEL_SESSION.id_checkpoint(level_id, i + 1)
			if id not in ids:
				ids.append(id)
		EstadoJogo.validar_checkpoints_disponiveis(ids)


## Decide se esta é a fogueira do chefe: de todas as do nível, a que está
## mais perto da arena. É de confiança porque o gerador põe SEMPRE um
## checkpoint mesmo antes do chefe e espaça os outros 3000 px
## (`gerador_corredor.gd`). Sem chefe no nível não faz nada.
func _avaliar_ultimo() -> void:
	if not is_inside_tree():
		return
	var chefes := get_tree().get_nodes_in_group("chefes")
	if chefes.is_empty():
		return
	var arena := (chefes[0] as Node2D).global_position
	var fogueiras: Array[Node2D] = []
	var pos: Array[Vector2] = []
	for c in get_tree().get_nodes_in_group("checkpoints"):
		var n := c as Node2D
		if n == null:
			continue
		fogueiras.append(n)
		pos.append(n.global_position)
	var i := Fogueiras.indice_da_do_chefe(pos, arena)
	_ultimo = i >= 0 and fogueiras[i] == self
	# recarregou a cena com esta fogueira JÁ acesa (morreu no chefe): a
	# música de combate volta logo, sem esperar por outro golpe.
	if _ultimo and _ativo:
		Musica.boss()


func _montar_visual() -> void:
	_base = Node2D.new()
	_base.name = "Fogueira"
	_base.z_index = -1  # a Koliani passa À FRENTE da fogueira
	add_child(_base)
	# --- pedras da roda (fica sempre visível, acesa ou não) --------------
	for i in 5:
		var a := PI * (0.12 + 0.76 * float(i) / 4.0)
		var pedra := Polygon2D.new()
		var r := 15.0
		var c := Vector2(cos(a) * r, 14.0 + sin(a) * 3.0)
		pedra.polygon = PackedVector2Array([
			c + Vector2(-4, 0), c + Vector2(-3, -4), c + Vector2(3, -4), c + Vector2(4, 1),
		])
		pedra.color = COR_PEDRA.darkened(0.1 * float(i % 2))
		_base.add_child(pedra)

	# --- lenha: três achas cruzadas -------------------------------------
	_lenha = Node2D.new()
	_base.add_child(_lenha)
	for ang in [-0.5, 0.35, 0.05]:
		var acha := Polygon2D.new()
		acha.polygon = PackedVector2Array([
			Vector2(-13, -2), Vector2(13, -2), Vector2(13, 3), Vector2(-13, 3),
		])
		acha.color = COR_LENHA
		acha.rotation = ang
		acha.position = Vector2(0.0, 11.0 - absf(ang) * 3.0)
		_lenha.add_child(acha)

	# --- chama (só emite depois de acesa) --------------------------------
	_chama = CPUParticles2D.new()
	_chama.amount = 26
	_chama.lifetime = 0.62
	_chama.emitting = false
	_chama.local_coords = false
	_chama.direction = Vector2(0, -1)
	_chama.spread = 12.0
	_chama.gravity = Vector2(0, -150)
	_chama.initial_velocity_min = 26.0
	_chama.initial_velocity_max = 62.0
	_chama.scale_amount_min = 2.5
	_chama.scale_amount_max = 6.0
	_chama.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_chama.emission_rect_extents = Vector2(7.0, 2.0)
	_chama.position = Vector2(0.0, 8.0)
	var rampa := Gradient.new()
	rampa.offsets = PackedFloat32Array([0.0, 0.25, 0.7, 1.0])
	rampa.colors = PackedColorArray([
		Color(1.0, 0.98, 0.72, 0.95), Color(1.0, 0.78, 0.26, 0.9),
		Color(0.92, 0.36, 0.1, 0.55), Color(0.35, 0.1, 0.05, 0.0),
	])
	_chama.color_ramp = rampa
	_base.add_child(_chama)

	# --- brasas que sobem devagar ---------------------------------------
	_brasas = CPUParticles2D.new()
	_brasas.amount = 10
	_brasas.lifetime = 1.8
	_brasas.emitting = false
	_brasas.local_coords = false
	_brasas.direction = Vector2(0, -1)
	_brasas.spread = 34.0
	_brasas.gravity = Vector2(0, -22)
	_brasas.initial_velocity_min = 12.0
	_brasas.initial_velocity_max = 34.0
	_brasas.scale_amount_min = 1.0
	_brasas.scale_amount_max = 2.0
	_brasas.position = Vector2(0.0, 4.0)
	var rb := Gradient.new()
	rb.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	rb.colors = PackedColorArray([
		Color(1.0, 0.9, 0.5, 0.0), Color(1.0, 0.72, 0.28, 0.9), Color(0.8, 0.3, 0.1, 0.0),
	])
	_brasas.color_ramp = rb
	_base.add_child(_brasas)

	# --- coração da chama (dá o "cheio" que as partículas não dão) -------
	_nucleo = Polygon2D.new()
	_nucleo.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(6, -4), Vector2(4, 6), Vector2(-4, 6), Vector2(-6, -4),
	])
	_nucleo.color = Color(1.0, 0.86, 0.45, 0.7)
	_nucleo.position = Vector2(0.0, 6.0)
	_nucleo.visible = false
	_base.add_child(_nucleo)

	# 9G: fogueira por acender -- um brilho fraco, em ciclo, a marcar que está
	# pronta. Desaparece assim que acende.
	if Vfx9G.ativo(self):
		_pronta9g = Vfx9G.novo("pickup", true)
		if _pronta9g:
			_pronta9g.modulate.a = 0.38
			_pronta9g.position = Vector2(0.0, -14.0)
			_base.add_child(_pronta9g)
			_pronta9g.play("ciclo")

	_luz = PointLight2D.new()
	_luz.texture = _tex_luz()
	_luz.color = COR_LUZ
	_luz.energy = 0.0
	_luz.position = Vector2(0.0, 2.0)
	_luz.scale = Vector2(0.9, 0.9)
	_base.add_child(_luz)

	# O toast traduzido do HUD confirma a ativação; sem rótulo world-space redundante.


## A fogueira tem de assentar no CHÃO, não ficar a pairar: o nó do
## checkpoint anda 46 px acima da plataforma (ver `gerador_corredor.gd`) e
## nos níveis à mão a altura varia. Um raio para baixo resolve os dois casos.
func _pousar() -> void:
	if _base == null:
		return
	var espaco := get_world_2d().direct_space_state
	# começa BEM acima do nó (apanha checkpoints ligeiramente enterrados na
	# plataforma) e varre fundo (níveis à mão com alturas variadas).
	var de := global_position + Vector2(0.0, -80.0)
	var params := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 520.0), 1)
	params.collide_with_areas = false
	var hit := espaco.intersect_ray(params)
	if not hit.is_empty():
		# a fogueira (pedras/lenha desenhadas a ~y+16 local) assenta a base
		# EM CIMA da superfície -- nunca enterrada nem a flutuar.
		_base.position.y = (hit["position"] as Vector2).y - global_position.y - 15.0
	else:
		_base.position.y = 30.0  # sem chão por baixo -- fallback discreto


func _escalar(pts: PackedVector2Array, f: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in pts:
		out.append(v * f)
	return out


func _tex_luz() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 180
	t.height = 180
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _process(dt: float) -> void:
	if not _ativo:
		return
	_t += dt
	# tremor de fogo: duas ondas desencontradas + um salto pequeno ao acaso
	var bruxuleio := 0.16 * sin(_t * 9.3) + 0.09 * sin(_t * 21.7) + randf_range(-0.04, 0.04)
	if _luz:
		_luz.energy = 1.25 + bruxuleio
	if _nucleo:
		_nucleo.scale = Vector2(1.0 + bruxuleio * 0.5, 1.0 + bruxuleio * 0.9)
		_nucleo.modulate.a = 0.8 + bruxuleio


func _ao_entrar(corpo: Node) -> void:
	if corpo is Koliani and not _ativo:
		if not EstadoJogo.ativar_checkpoint(checkpoint_id, global_position):
			return
		_ativar(false)
		Som.toca("selo", -12.0)
		# 9F: o feedback da prancha 09 (secção 8) -- só expõe o que já
		# aconteceu (o checkpoint foi registado no EstadoJogo acima)
		get_tree().call_group("hud_9f", "_aviso", Textos.t("hud.checkpoint"), "ico_checkpoint", "info")
		if _ultimo:
			Musica.boss()


func _ativar(instantaneo: bool) -> void:
	_ativo = true
	# 9G: o mesmo brilho de "interagir" da prancha 07 -- apagado, a fogueira
	# pisca baixinho a dizer que dá para usar; ao acender, dá um estalo. Nada
	# disto mexe no checkpoint em si (já foi registado no EstadoJogo).
	if _pronta9g:
		_pronta9g.queue_free()
		_pronta9g = null
	if not instantaneo and Vfx9G.ativo(self):
		Vfx9G.tocar(self, "pickup", global_position + Vector2(0.0, _base.position.y - 16.0 if _base else -16.0),
			1.4, 0.0, false, false, 12, 0.5)
	if _nucleo:
		_nucleo.visible = true
	if _chama:
		_chama.emitting = true
	if _brasas:
		_brasas.emitting = true
	if _lenha:
		# a lenha acesa aquece de cor
		for acha in _lenha.get_children():
			if acha is Polygon2D:
				if instantaneo:
					(acha as Polygon2D).color = COR_LENHA_ACESA
				else:
					create_tween().tween_property(acha, "color", COR_LENHA_ACESA, 0.3)
	if instantaneo:
		if _luz:
			_luz.energy = 1.25
			_luz.scale = Vector2(1.7, 1.7)
		return
	if _luz:
		# labareda: o fogo pega com um golpe de luz e depois assenta
		var tl := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tl.tween_property(_luz, "scale", Vector2(2.2, 2.2), 0.22)
		tl.parallel().tween_property(_luz, "energy", 1.9, 0.22)
		tl.tween_property(_luz, "scale", Vector2(1.7, 1.7), 0.3)
		tl.parallel().tween_property(_luz, "energy", 1.25, 0.3)
