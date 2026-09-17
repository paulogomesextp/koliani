class_name TestesRegion02N08
extends RefCounted
## Contrato estrutural do PROCESS 11 (N08 -- Ilhas Suspensas). Não certifica
## sensação nem substitui jogar o nível; trava perdas de spawn, fogueiras,
## porta, chefe, recompensa, planar contextual e vento, e a volta de perigos
## da identidade prisional. O percurso real vive em
## `tools/verifica_rota_n08.gd`.

const CENA := "res://scenes/levels/Corredor_das_Execucoes.tscn"
## Perigos da identidade antiga (prisão/execuções) que saíram do N08.
const PROIBIDOS := [
	"res://scenes/actors/Guilhotina.tscn", "res://scenes/actors/Serra.tscn",
	"res://scenes/actors/PlataformaQuebra.tscn", "res://scenes/actors/AguaVenenosa.tscn",
	"res://scenes/actors/CascaMasmorra.tscn",
]


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N08: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	_verificar(falhas, raiz.get("corredor") == false,
		"N08: sala feita à mão (sem jornada procedural)")
	_verificar(falhas, raiz.get("alongar_plataformas") == false,
		"N08: vãos medidos -- o esticão automático não mexe nas ilhas")
	_verificar(falhas, raiz.get("mecanica_anunciada") == "asas",
		"N08: ensina o planar com o texto existente 'asas'")
	for nome in ["Koliani", "Porta", "Chefe", "ColProjetil"]:
		_verificar(falhas, raiz.get_node_or_null(nome) != null, "N08: %s presente" % nome)
	var col := raiz.get_node_or_null("ColProjetil")
	if col:
		_verificar(falhas, col.get("habilidade_id") == "projetil",
			"N08: recompensa de progressão 'projetil' preservada")
	var checks := _filhos_por_prefixo(raiz, "Check")
	_verificar(falhas, checks.size() == 3, "N08: três fogueiras")

	# ninguém sai do N08 com planar permanente
	for filho in raiz.get_children():
		if filho.get("habilidade_id") == "planar":
			falhas.append("N08: %s dava a habilidade permanente planar" % filho.name)
		var caminho := filho.scene_file_path
		if caminho in PROIBIDOS:
			falhas.append("N08: perigo prisional %s voltou (%s)" % [caminho.get_file(), filho.name])

	# planar contextual cobre o percurso inteiro: spawn, fogueiras, porta e
	# todas as ilhas (quem nasce numa fogueira já pode planar)
	var zonas_planar: Array[Node2D] = []
	for filho in raiz.get_children():
		if filho is ZonaPlanar:
			zonas_planar.append(filho)
	_verificar(falhas, zonas_planar.size() == 1, "N08: uma ZonaPlanar")
	if zonas_planar.size() == 1:
		var zp := zonas_planar[0] as ZonaPlanar
		var ret := Rect2(zp.position - zp.tamanho * 0.5, zp.tamanho)
		var pontos: Array[Node2D] = [raiz.get_node("Koliani"), raiz.get_node("Porta")]
		pontos.append_array(checks)
		for filho in raiz.get_children():
			if filho.get("tamanho") is Vector2 and filho.scene_file_path.ends_with("Plataforma.tscn"):
				pontos.append(filho)
		for p in pontos:
			_verificar(falhas, ret.has_point(p.position),
				"N08: ZonaPlanar cobre %s" % p.name)

	# vento: uma corrente ascendente capaz de levantar (> gravidade de queda),
	# uma rajada a favor contínua e uma contra pulsada
	var zonas := _zonas(raiz)
	var sobe := zonas.filter(func(z: WindZone) -> bool: return z.direcao.y < -0.5)
	var favor := zonas.filter(func(z: WindZone) -> bool: return z.direcao.x > 0.5)
	var contra := zonas.filter(func(z: WindZone) -> bool: return z.direcao.x < -0.5)
	_verificar(falhas, sobe.size() == 1 and favor.size() == 1 and contra.size() == 1,
		"N08: corrente + a favor + contra (obtido %d/%d/%d)" % [sobe.size(), favor.size(), contra.size()])
	var queda := Movimento.GRAVIDADE * Movimento.GRAVIDADE_QUEDA
	for z: WindZone in sobe:
		_verificar(falhas, z.modo == WindZone.Modo.CONTINUO and z.intensidade > queda,
			"N08: %s contínua e mais forte do que a queda (%.0f > %.0f)" % [z.name, z.intensidade, queda])
	for z: WindZone in favor:
		_verificar(falhas, z.modo == WindZone.Modo.CONTINUO, "N08: %s contínua" % z.name)
	for z: WindZone in contra:
		_verificar(falhas, z.modo == WindZone.Modo.PULSADO and z.intervalo_pulso > z.duracao_pulso,
			"N08: %s pulsada com pausa maior do que a rajada" % z.name)
	for z: WindZone in zonas:
		var cs := z.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var forma := cs.shape as RectangleShape2D if cs else null
		# a WindZone.tscn partilha a forma: sem forma própria na cena, todas
		# as zonas do N08 colidiam com o tamanho da última configurada
		_verificar(falhas, forma != null and forma.resource_path.get_slice("::", 0) != "res://scenes/actors/WindZone.tscn",
			"N08: %s tem forma de colisão própria" % z.name)
		for c in checks:
			_verificar(falhas, not _contem(z, c.position), "N08: %s não cobre %s" % [z.name, c.name])
		_verificar(falhas, not _contem(z, (raiz.get_node("Chefe") as Node2D).position),
			"N08: %s não cobre o chefe" % z.name)
		_verificar(falhas, not _contem(z, (raiz.get_node("Koliani") as Node2D).position),
			"N08: %s não cobre o spawn" % z.name)

	# a última fogueira fica junto do chefe (senão o nível criava outra)
	var chefe := raiz.get_node("Chefe") as Node2D
	var ultima_x := -INF
	for c in checks:
		ultima_x = maxf(ultima_x, c.position.x)
	_verificar(falhas, absf(chefe.position.x - ultima_x) <= 260.0,
		"N08: última fogueira a <= 260 px do chefe")
	raiz.free()
	return falhas


static func _zonas(raiz: Node) -> Array[WindZone]:
	var r: Array[WindZone] = []
	for filho in raiz.get_children():
		if filho is WindZone:
			r.append(filho)
	return r


static func _filhos_por_prefixo(raiz: Node, prefixo: String) -> Array[Node2D]:
	var r: Array[Node2D] = []
	for filho in raiz.get_children():
		if filho is Node2D and filho.name.begins_with(prefixo):
			r.append(filho)
	return r


static func _contem(zona: WindZone, ponto: Vector2) -> bool:
	var local := ponto - zona.position
	return absf(local.x) <= zona.tamanho.x * 0.5 and absf(local.y) <= zona.tamanho.y * 0.5


static func _verificar(falhas: Array[String], condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
