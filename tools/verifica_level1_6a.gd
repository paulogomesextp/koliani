extends SceneTree
## Verificação dirigida da Execution 6A.
## Prova asset, isolamento visual, rollback e invariantes congelados do Level 1.

const FONTE_08 := "res://Koliani_1.0_Master_Package_v2/references/approved/08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png"
const HASH_08 := "840cfd8241a54f7bab0be58ab96892eba8438517888e490587451339b23263a7"
const ASSETS := {
	"region1_panorama_heart_tree.png": Vector2i(952, 247),
	"region1_panorama_left_cap.png": Vector2i(320, 247),
	"region1_panorama_right_cap.png": Vector2i(322, 247),
}

var falhas: Array[String] = []


func _init() -> void:
	await process_frame
	_ok(FileAccess.get_sha256(FONTE_08) == HASH_08, "SHA-256 da fonte 08 mudou")
	for nome: String in ASSETS:
		var caminho := "res://assets/art/regions/region_01_forest/production/backgrounds/" + nome
		var imagem := Image.load_from_file(caminho)
		_ok(imagem != null and not imagem.is_empty(), "asset ilegível: " + nome)
		if imagem != null and not imagem.is_empty():
			_ok(imagem.get_size() == ASSETS[nome], "dimensões erradas: " + nome)

	var cena_level_1 := load("res://scenes/levels/Floresta_Putrefata.tscn") as PackedScene
	_ok(cena_level_1 != null, "Level 1 não carregou")
	if cena_level_1 == null:
		_terminar()
		return
	var nivel := cena_level_1.instantiate()
	var koliani_declarada := nivel.get_node_or_null("Koliani")
	var spawn_declarado: Vector2 = koliani_declarada.position \
		if koliani_declarada else Vector2.INF
	var plataformas_antes := _estado_plataformas(nivel)
	root.add_child(nivel)
	for _i in 90:
		await process_frame

	var target := nivel.get_node_or_null("Region1HybridVisualTarget")
	_ok(target != null, "módulo visual 6A em falta")
	if target:
		_ok(bool(target.get("ativo")), "módulo visual 6A devia estar ativo")
		_ok(target.get_meta("intervalo_target", Vector2.ZERO) == Vector2(-2550, 3850),
			"cobertura visual 6A inesperada")
		_ok(not _tem_fisica(target), "módulo visual 6A contém física")
		for nome in ["BackgroundApproved08", "LandmarkHeartTreeApproved08",
				"MidgroundProductionAssetsMissing", "GameplayPlaneLegacyRetained",
				"CorruptionSample", "AtmosphereVFX", "ForegroundApprovedBaked",
				"SelectiveLighting"]:
			_ok(target.get_node_or_null(nome) != null, "camada 6A em falta: " + nome)
		var fundo := target.get_node_or_null("BackgroundApproved08")
		_ok(fundo != null and fundo.get_child_count() == 4,
			"background aprovado devia ter panorama + 3 caps")
		print("6A orçamento runtime: nós=%d luzes=%d partículas=%d" % [
			_contar_nos(target), _contar_tipo(target, "PointLight2D"),
			_contar_tipo(target, "CPUParticles2D")])

	_ok(_estado_plataformas(nivel) == plataformas_antes,
		"posição/tamanho das plataformas congeladas mudou")
	var koliani := nivel.get_node_or_null("Koliani")
	_ok(koliani != null, "Koliani em falta")
	if koliani:
		_ok(spawn_declarado == Vector2(150, 620), "spawn declarado mudou")
		_ok(bool(koliani.get("usar_piloto_visual_5g")), "piloto 5G deixou de estar ativo")
		var corpo := koliani.get_node("Sprite/Corpo") as AnimatedSprite2D
		_ok(corpo.scale.is_equal_approx(Vector2(0.82, 0.82)), "escala 5G.1 mudou")
		_ok(is_equal_approx(corpo.offset.y, -15.170732), "offset 5G.1 mudou")
		var colisao := koliani.get_node("CollisionShape2D") as CollisionShape2D
		var hitbox := koliani.get_node("HitboxAtaque/CollisionShape2D") as CollisionShape2D
		_ok(colisao.shape.size == Vector2(20, 44), "colisão da Koliani mudou")
		_ok(hitbox.shape.size == Vector2(30, 34) and hitbox.position == Vector2(23, -4),
			"hitbox da Koliani mudou")

	_ok(nivel.get_node_or_null("EliteGoblin") != null, "EliteGoblin legacy removido")
	_ok(nivel.get_node_or_null("GoblinBaixa") != null, "GoblinBaixa legacy removido")
	_ok(nivel.get_node_or_null("Chefe") != null, "Ghorak removido")
	nivel.queue_free()
	await process_frame

	var cena_target := load("res://scenes/fx/Region1HybridVisualTarget.tscn") as PackedScene
	_ok(cena_target != null, "cena do módulo 6A não carregou")
	if cena_target == null:
		_terminar()
		return
	var target_off := cena_target.instantiate()
	target_off.set("ativo", false)
	root.add_child(target_off)
	await process_frame
	_ok(not target_off.visible, "rollback OFF devia ocultar o módulo")
	_ok(target_off.get_child_count() == 0, "rollback OFF montou conteúdo")
	target_off.queue_free()
	await process_frame
	_terminar()


func _estado_plataformas(nivel: Node) -> Array:
	var estado: Array = []
	for nome in ["ChaoInicio", "Passo1", "Passo2", "Passo3", "ChaoMeio",
			"Alta1", "Alta2", "Alta3", "Alcova", "Alta4", "Baixa1", "Baixa2",
			"Baixa3", "Baixa4", "Reencontro", "SubidaChefe", "ChaoChefe"]:
		var plataforma := nivel.get_node_or_null(nome)
		if plataforma:
			estado.append([nome, plataforma.position, plataforma.get("tamanho")])
	return estado


func _tem_fisica(no: Node) -> bool:
	if no is CollisionObject2D or no is CollisionShape2D or no is CollisionPolygon2D:
		return true
	for filho in no.get_children():
		if _tem_fisica(filho):
			return true
	return false


func _contar_nos(no: Node) -> int:
	var total := 1
	for filho in no.get_children():
		total += _contar_nos(filho)
	return total


func _contar_tipo(no: Node, tipo: String) -> int:
	var total := 1 if no.get_class() == tipo else 0
	for filho in no.get_children():
		total += _contar_tipo(filho, tipo)
	return total


func _ok(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)


func _terminar() -> void:
	if falhas.is_empty():
		print("LEVEL 1 6A: PASS — assets, rollback e invariantes preservados")
		quit(0)
		return
	for falha in falhas:
		printerr("FALHOU: ", falha)
	quit(1)
