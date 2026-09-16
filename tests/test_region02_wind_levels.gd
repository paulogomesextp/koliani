class_name TestesRegion02WindLevels
extends RefCounted
## Contrato estrutural do Process 10. Não certifica feel nem substitui jogar
## os níveis; trava perdas de zonas, checkpoints, inimigos, boss e porta.

const CENAS := {
	"N06": "res://scenes/levels/Prisao_dos_Condenados.tscn",
	"N07": "res://scenes/levels/Fornalha_dos_Pecadores.tscn",
	"N09": "res://scenes/levels/Ala_dos_Mortos.tscn",
}


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var raizes := {}
	for nome: String in CENAS:
		var cena := load(CENAS[nome]) as PackedScene
		_verificar(falhas, cena != null, "%s: cena carrega" % nome)
		if cena == null:
			continue
		var raiz := cena.instantiate()
		raizes[nome] = raiz
		_verificar(falhas, raiz.get_node_or_null("Koliani") != null,
			"%s: spawn preservado" % nome)
		_verificar(falhas, raiz.get_node_or_null("Porta") != null,
			"%s: porta preservada" % nome)
		_verificar(falhas, raiz.get_node_or_null("Chefe") != null,
			"%s: boss existente preservado" % nome)
		_verificar(falhas, _filhos_por_prefixo(raiz, "Check").size() == 3,
			"%s: três checkpoints preservados" % nome)

	if raizes.has("N06"):
		var zonas06 := _zonas(raizes["N06"])
		_verificar(falhas, zonas06.size() == 2, "N06: duas rajadas")
		_verificar(falhas, _direcoes_x(zonas06).has(-1.0)
			and _direcoes_x(zonas06).has(1.0), "N06: rajadas opostas")
		_verificar(falhas, _todas_pulsadas(zonas06), "N06: rajadas pulsadas")
	if raizes.has("N07"):
		var zonas07 := _zonas(raizes["N07"])
		_verificar(falhas, zonas07.size() == 3, "N07: três updrafts")
		for zona in zonas07:
			_verificar(falhas, zona.direcao == Vector2.UP,
				"N07: %s aponta para cima" % zona.name)
	if raizes.has("N09"):
		var zonas09 := _zonas(raizes["N09"])
		_verificar(falhas, zonas09.size() == 3, "N09: três zonas variáveis")
		_verificar(falhas, _direcoes_x(zonas09).has(-1.0)
			and _direcoes_x(zonas09).has(1.0), "N09: direção varia")
		var intensidades := {}
		for zona in zonas09:
			intensidades[zona.intensidade] = true
		_verificar(falhas, intensidades.size() >= 2, "N09: intensidade varia")
		_verificar(falhas, _todas_pulsadas(zonas09), "N09: vento pulsado")

	for nome: String in raizes:
		var raiz: Node = raizes[nome]
		for zona in _zonas(raiz):
			for checkpoint in _filhos_por_prefixo(raiz, "Check"):
				_verificar(falhas, not _contem_ponto(zona, checkpoint.position),
					"%s: %s não cobre %s" % [nome, zona.name, checkpoint.name])
			var chefe := raiz.get_node("Chefe") as Node2D
			_verificar(falhas, not _contem_ponto(zona, chefe.position),
				"%s: %s não cobre a arena/boss" % [nome, zona.name])
		raiz.free()
	return falhas


static func _zonas(raiz: Node) -> Array[WindZone]:
	var resultado: Array[WindZone] = []
	for filho in raiz.get_children():
		if filho is WindZone:
			resultado.append(filho)
	return resultado


static func _filhos_por_prefixo(raiz: Node, prefixo: String) -> Array[Node2D]:
	var resultado: Array[Node2D] = []
	for filho in raiz.get_children():
		if filho is Node2D and filho.name.begins_with(prefixo):
			resultado.append(filho)
	return resultado


static func _direcoes_x(zonas: Array[WindZone]) -> Array[float]:
	var resultado: Array[float] = []
	for zona in zonas:
		resultado.append(signf(zona.direcao.x))
	return resultado


static func _todas_pulsadas(zonas: Array[WindZone]) -> bool:
	for zona in zonas:
		if zona.modo != WindZone.Modo.PULSADO:
			return false
	return true


static func _contem_ponto(zona: WindZone, ponto: Vector2) -> bool:
	var local := ponto - zona.position
	return absf(local.x) <= zona.tamanho.x * 0.5 \
		and absf(local.y) <= zona.tamanho.y * 0.5


static func _verificar(falhas: Array[String], condicao: bool,
		mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
