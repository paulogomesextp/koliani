class_name LevelSession
extends RefCounted
## Contrato puro do estado TEMPORARIO de um nivel.
##
## A campanha permanente fica em `EstadoJogo`; esta estrutura guarda apenas
## a identidade do nivel em curso e do ultimo ponto seguro. Nunca guarda um
## frame arbitrario, velocity, inimigos, perigos ou estado de nos.

const IDS := preload("res://scripts/progression_ids.gd")


static func vazia() -> Dictionary:
	return {"active": false, "level_id": "", "checkpoint_id": ""}


static func id_inicio(level_id: String) -> String:
	return "checkpoint_%s_start" % level_id if _level_valido(level_id) else ""


static func id_checkpoint(level_id: String, ordem: int) -> String:
	if not _level_valido(level_id) or ordem < 1 or ordem > 999:
		return ""
	return "checkpoint_%s_%02d" % [level_id, ordem]


static func id_valido_para_nivel(checkpoint_id: String, level_id: String) -> bool:
	if not _level_valido(level_id):
		return false
	var prefixo := "checkpoint_%s_" % level_id
	if not checkpoint_id.begins_with(prefixo):
		return false
	var sufixo := checkpoint_id.trim_prefix(prefixo)
	if sufixo == "start":
		return true
	return sufixo.is_valid_int() and int(sufixo) >= 1 and int(sufixo) <= 999


static func iniciar(atual: Variant, level_id: String, forcar_nova := false) -> Dictionary:
	if not _level_valido(level_id):
		return vazia()
	if forcar_nova:
		return {
			"active": true,
			"level_id": level_id,
			"checkpoint_id": id_inicio(level_id),
		}
	var normalizada := normalizar(atual, level_id)
	if normalizada.get("active", false) \
			and normalizada.get("level_id", "") == level_id:
		return normalizada
	return {
		"active": true,
		"level_id": level_id,
		"checkpoint_id": id_inicio(level_id),
	}


static func ativar(atual: Variant, level_id: String, checkpoint_id: String) -> Dictionary:
	if not id_valido_para_nivel(checkpoint_id, level_id):
		return iniciar(atual, level_id)
	return {
		"active": true,
		"level_id": level_id,
		"checkpoint_id": checkpoint_id,
	}


static func normalizar(valor: Variant, current_level_id: String) -> Dictionary:
	if not (valor is Dictionary):
		return iniciar(vazia(), current_level_id, true)
	var d: Dictionary = valor
	if not (d.get("active", false) is bool):
		return iniciar(vazia(), current_level_id, true)
	if not bool(d.get("active", false)):
		return vazia()
	var level_id := str(d.get("level_id", ""))
	var checkpoint_id := str(d.get("checkpoint_id", ""))
	if level_id != current_level_id or not id_valido_para_nivel(checkpoint_id, level_id):
		return iniciar(vazia(), current_level_id, true)
	return {
		"active": true,
		"level_id": level_id,
		"checkpoint_id": checkpoint_id,
	}


static func migrar_v3(level_id: String, checkpoint_legacy: Variant) -> Dictionary:
	# Uma coordenada v3 nao identifica inequivocamente uma fogueira. Zero era
	# ausencia de sessao; qualquer outro valor converge para o spawn inicial
	# seguro do mesmo nivel, preservando toda a campanha permanente.
	if checkpoint_legacy is Array and checkpoint_legacy.size() == 2 \
			and float(checkpoint_legacy[0]) == 0.0 \
			and float(checkpoint_legacy[1]) == 0.0:
		return vazia()
	return iniciar(vazia(), level_id, true)


static func _level_valido(level_id: String) -> bool:
	return level_id in IDS.identidades().get("level_ids", [])
