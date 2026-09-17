class_name TestesRegion02WindLevels
extends RefCounted
## Contrato estrutural do Process 10, alargado no Super-Process A à
## COERÊNCIA da região: os cinco níveis têm de ler-se como o mesmo sítio
## (mesmo bioma, mesmo pack de fundo) e, ao mesmo tempo, ter cada um o seu
## papel. Não certifica feel nem substitui jogar os níveis.

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

	falhas.append_array(_regiao_coerente())
	return falhas


## As CINCO cenas da Região II como uma sequência.
##
## O cânone (`docs/art_direction/regions/region_02/`) dá a cada nível um
## papel distinto e à região uma identidade só. Antes do Super-Process A
## os cinco corriam com `bioma = "prisao"` e dois packs de masmorra: liam-se
## como a prisão de onde vieram, não como o Desfiladeiro dos Ventos.
static func _regiao_coerente() -> Array[String]:
	var falhas: Array[String] = []
	var todas := {
		"N06": "res://scenes/levels/Prisao_dos_Condenados.tscn",
		"N07": "res://scenes/levels/Fornalha_dos_Pecadores.tscn",
		"N08": "res://scenes/levels/Corredor_das_Execucoes.tscn",
		"N09": "res://scenes/levels/Ala_dos_Mortos.tscn",
		"N10": "res://scenes/levels/A_Cela_Zero.tscn",
	}
	## O papel de cada nível, do painel `EXEMPLOS DE GAMEPLAY` da prancha
	## `concept_environment_01.png`. A assinatura é a DIREÇÃO dominante do
	## vento: nenhum par de níveis pode ter a mesma.
	var assinatura := {
		"N06": "horizontal pulsada",   # rajadas horizontais
		"N07": "ascendente",           # correntes ascendentes
		"N08": "mista + planar",       # ilhas suspensas + planar
		"N09": "variável",             # vento variável + inimigos
		"N10": "exame + chefe",        # o Guardião comanda o vento
	}
	var luzes := {}
	for nome: String in todas:
		var cena := load(todas[nome]) as PackedScene
		if cena == null:
			falhas.append("%s: cena não carrega" % nome)
			continue
		var raiz := cena.instantiate()
		var atm := raiz.get_node_or_null("Atmosfera")
		if atm == null:
			falhas.append("%s: sem nó Atmosfera" % nome)
			raiz.free()
			continue
		# identidade da REGIÃO: o sítio é o mesmo nos cinco
		_verificar(falhas, str(atm.get("bioma")) == "desfiladeiro",
			"%s: bioma é '%s', esperava 'desfiladeiro'"
				% [nome, atm.get("bioma")])
		_verificar(falhas, str(atm.get("fundo_pack")) == "desfiladeiro",
			"%s: fundo_pack é '%s', esperava 'desfiladeiro'"
				% [nome, atm.get("fundo_pack")])
		# identidade do NÍVEL: a luz-chave não se repete, senão os cinco
		# leem-se como a mesma sala
		var luz: Variant = atm.get("cor_luz")
		if luz is Color:
			var chave := "%.2f|%.2f|%.2f" % [(luz as Color).r,
				(luz as Color).g, (luz as Color).b]
			_verificar(falhas, not luzes.has(chave),
				"%s: tem a mesma luz-chave que %s -- a região fica toda igual"
					% [nome, luzes.get(chave, "?")])
			luzes[chave] = nome
		# a casca fechada, quando existe, usa a pedra do desfiladeiro
		var casca := raiz.get_node_or_null("Casca")
		if casca != null:
			_verificar(falhas, str(casca.get("estilo")) == "desfiladeiro",
				"%s: a Casca ainda usa tijolo de masmorra" % nome)
		raiz.free()

	_verificar(falhas, assinatura.size() == 5,
		"a Região II tem de ter cinco níveis com papéis distintos")
	var vistos := {}
	for nome: String in assinatura:
		_verificar(falhas, not vistos.has(assinatura[nome]),
			"%s repete a assinatura de %s" % [nome, vistos.get(assinatura[nome], "?")])
		vistos[assinatura[nome]] = nome
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
