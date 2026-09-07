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
	"salto_duplo": "ability_salto_duplo",
	"dash_aereo": "ability_dash_aereo",
	"partir_paredes": "ability_partir_paredes",
	"escudo": "ability_escudo",
	"projetil": "ability_projetil",
	"escalar_paredes": "ability_escalar_paredes",
	"planar": "ability_planar",
}


static func carregar_manifesto() -> Dictionary:
	if not FileAccess.file_exists(CAMINHO_MANIFESTO):
		return {}
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_MANIFESTO))
	return dados if dados is Dictionary else {}


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
	return identidades_do_manifesto(carregar_manifesto())


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
