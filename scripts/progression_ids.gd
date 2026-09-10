class_name ProgressionIDs
extends RefCounted
## Contrato central das identidades que podem chegar ao save de campanha.
##
## Niveis e chefes vêm do manifesto da Execution 2. Habilidades mantêm as
## chaves runtime existentes, mas o formato persistido usa IDs com namespace.
## Pistas já tinham identidade semântica própria no catálogo do diário.

const CAMINHO_MANIFESTO := "res://data/level_manifest.json"
const DIARIO := preload("res://scripts/diario_pistas.gd")

const HABILIDADE_RUNTIME_PARA_ID := {
	"dash": "ability_dash",
	"salto_duplo": "ability_salto_duplo",
	"dash_aereo": "ability_dash_aereo",
	"pogo": "ability_pogo",
	"partir_paredes": "ability_partir_paredes",
	"escudo": "ability_escudo",
	"projetil": "ability_projetil",
	"escalar_paredes": "ability_escalar_paredes",
	"planar": "ability_planar",
}


## --- Cache do manifesto (Execution 8.1E) ----------------------------------
##
## O manifesto e' um recurso IMUTAVEL em runtime (vem dentro do PCK). Ate' a
## 8.1E, `carregar_manifesto()` lia-o e fazia-lhe parse OUTRA VEZ a cada
## chamada -- e `identidades()` reconstruia os arrays a cada chamada por cima
## disso. Uma so' gravacao do progresso chegava a fazer isto centenas de
## vezes (`SaveFoundation.escrever_seguro()` faz seis validacoes completas, e
## `reward_ids()` sozinho chama `identidades()` uma vez por nivel). Era esta
## a "congelacao" de ~2 s no checkpoint e ao levar dano.
##
## O cache guarda o manifesto E as identidades ja' derivadas. Nao muda um
## unico ID nem a semantica do manifesto: o que se le do disco e o que se
## deriva dele sao exatamente os mesmos, so' que uma vez.
##
## AVISO: `carregar_manifesto()` e `identidades()` devolvem a instancia
## PARTILHADA do cache. Sao de LEITURA. Quem precisar de mexer que use
## `.duplicate(true)`. Todos os consumidores de hoje so' leem.
##
## Ferramentas que regeneram `data/level_manifest.json` dentro do mesmo
## processo tem de chamar `invalidar_cache()` -- o runtime do jogo nunca o
## reescreve, por isso nao ha dados velhos no jogo entregue.

static var _cache_mutex := Mutex.new()
static var _cache_manifesto: Dictionary = {}
static var _cache_identidades: Dictionary = {}
static var _cache_valido := false
static var _cache_ligado := true
## Diagnostico da 8.1E. Contadores baratos (um `+= 1` dentro do lock que ja'
## la' estava); e' o que prova a causa e o que impede a regressao no teste.
static var _leituras_disco := 0
static var _parses_json := 0
static var _chamadas_identidades := 0


## Aquece o cache. Chamar na thread principal, no arranque, antes de qualquer
## thread de fundo -- assim o worker so' le.
static func aquecer() -> void:
	_cache_mutex.lock()
	_garantir_cache()
	_cache_mutex.unlock()


## Para ferramentas que reescrevem o manifesto durante a vida do processo.
static func invalidar_cache() -> void:
	_cache_mutex.lock()
	_cache_valido = false
	_cache_manifesto = {}
	_cache_identidades = {}
	_cache_mutex.unlock()


## Liga/desliga o cache. Existe para a bancada da 8.1E poder medir o ANTES e
## o DEPOIS dentro do mesmo processo. Desligado = comportamento pre-8.1E.
static func usar_cache(ligar: bool) -> void:
	_cache_mutex.lock()
	_cache_ligado = ligar
	_cache_valido = false
	_cache_manifesto = {}
	_cache_identidades = {}
	_cache_mutex.unlock()


static func diagnostico() -> Dictionary:
	_cache_mutex.lock()
	var d := {
		"leituras_disco": _leituras_disco,
		"parses_json": _parses_json,
		"chamadas_identidades": _chamadas_identidades,
		"cache_ligado": _cache_ligado,
		"cache_valido": _cache_valido,
	}
	_cache_mutex.unlock()
	return d


static func zerar_diagnostico() -> void:
	_cache_mutex.lock()
	_leituras_disco = 0
	_parses_json = 0
	_chamadas_identidades = 0
	_cache_mutex.unlock()


## Pre-condicao: `_cache_mutex` ja' trancado.
static func _garantir_cache() -> void:
	if _cache_valido:
		return
	var manifesto := {}
	if FileAccess.file_exists(CAMINHO_MANIFESTO):
		var texto := FileAccess.get_file_as_string(CAMINHO_MANIFESTO)
		_leituras_disco += 1
		var dados: Variant = JSON.parse_string(texto)
		_parses_json += 1
		if dados is Dictionary:
			manifesto = dados
	_cache_manifesto = manifesto
	_cache_identidades = identidades_do_manifesto(manifesto)
	# Com o cache desligado nada fica valido -- a chamada seguinte volta ao
	# disco, que e' exatamente o comportamento antigo que queremos comparar.
	_cache_valido = _cache_ligado


static func carregar_manifesto() -> Dictionary:
	_cache_mutex.lock()
	_garantir_cache()
	var r := _cache_manifesto
	_cache_mutex.unlock()
	return r


static func identidades_do_manifesto(manifesto: Dictionary) -> Dictionary:
	var niveis: Array[String] = []
	var bosses: Array[String] = []
	var boss_por_nivel := {}
	for entrada: Dictionary in manifesto.get("levels", []):
		var level_id := str(entrada.get("level_id", ""))
		if level_id == "":
			continue
		niveis.append(level_id)
		var boss: Variant = entrada.get("boss_ref")
		if boss is Dictionary:
			var boss_id := str((boss as Dictionary).get("boss_id", ""))
			if boss_id != "":
				bosses.append(boss_id)
				boss_por_nivel[level_id] = boss_id
	return {
		"level_ids": niveis,
		"boss_ids": bosses,
		"boss_by_level_id": boss_por_nivel,
	}


static func identidades() -> Dictionary:
	_cache_mutex.lock()
	_chamadas_identidades += 1
	_garantir_cache()
	var r := _cache_identidades
	_cache_mutex.unlock()
	return r


static func level_id_do_indice(indice: int) -> String:
	var niveis: Array = identidades().get("level_ids", [])
	return str(niveis[indice]) if indice >= 0 and indice < niveis.size() else ""


static func indice_do_level_id(level_id: String) -> int:
	return identidades().get("level_ids", []).find(level_id)


static func boss_id_do_level_id(level_id: String) -> String:
	return str(identidades().get("boss_by_level_id", {}).get(level_id, ""))


static func boss_id_do_indice(indice: int) -> String:
	return boss_id_do_level_id(level_id_do_indice(indice))


static func ability_id_da_chave_runtime(chave: String) -> String:
	return str(HABILIDADE_RUNTIME_PARA_ID.get(chave, ""))


static func chave_runtime_da_ability_id(ability_id: String) -> String:
	for chave: String in HABILIDADE_RUNTIME_PARA_ID:
		if HABILIDADE_RUNTIME_PARA_ID[chave] == ability_id:
			return chave
	return ""


static func ability_ids() -> Array[String]:
	var ids: Array[String] = []
	for chave: String in HABILIDADE_RUNTIME_PARA_ID:
		ids.append(HABILIDADE_RUNTIME_PARA_ID[chave])
	return ids


static func collectible_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in DIARIO.PISTAS:
		ids.append(id)
	return ids


static func reward_id_bau_chefe(level_id: String) -> String:
	return "reward_boss_chest_%s" % level_id if level_id != "" else ""


static func reward_ids() -> Array[String]:
	var ids: Array[String] = []
	for level_id: String in identidades().get("level_ids", []):
		if boss_id_do_level_id(level_id) != "":
			ids.append(reward_id_bau_chefe(level_id))
	return ids
