class_name SaveFoundation
extends RefCounted
## Fundação versionada e testável do save de campanha.
##
## O schema 0 representa o JSON legacy sem `save_version`. A passagem para o
## schema atual é sempre sequencial: 0 -> 1 -> 2 -> 3 -> 4 -> 5. Este ficheiro não
## conhece o runtime de EstadoJogo; converte apenas a identidade persistida.

const LEGACY_SAVE_VERSION := 0
const CURRENT_SAVE_VERSION := 5
const SAVE_KIND := "campaign"
const IDS := preload("res://scripts/progression_ids.gd")
const LEVEL_SESSION := preload("res://scripts/level_session.gd")


static func processar(dados: Variant, total_niveis: int) -> Dictionary:
	if not (dados is Dictionary):
		return _falha("invalid_structure", "A raiz do save nao e um dicionario")
	var atual: Dictionary = (dados as Dictionary).duplicate(true)
	var identificacao := _identificar_versao(atual, total_niveis)
	if not identificacao.get("ok", false):
		return identificacao
	var versao: int = identificacao["version"]
	var passos: Array[int] = [versao]
	while versao < CURRENT_SAVE_VERSION:
		var migrado := _migrar_passo(atual, versao)
		if not migrado.get("ok", false):
			return migrado
		atual = migrado["data"]
		versao += 1
		passos.append(versao)
		var validacao_intermedia := _validar_versao(atual, versao, total_niveis)
		if not validacao_intermedia.get("ok", false):
			return _falha("invalid_migration",
				"A migration para v%d produziu dados invalidos: %s" % [
					versao, validacao_intermedia.get("message", "erro desconhecido")])
	# Uma sessao temporaria invalida nunca inutiliza a campanha. Converge para
	# o spawn inicial seguro do current_level_id antes da validacao final.
	atual["level_session"] = LEVEL_SESSION.normalizar(
		atual.get("level_session", {}), str(atual.get("current_level_id", "")))
	var validacao := validar_atual(atual, total_niveis)
	if not validacao.get("ok", false):
		return validacao
	return {"ok": true, "data": atual, "migrations": passos}


static func validar_atual(dados: Variant, total_niveis: int) -> Dictionary:
	if not (dados is Dictionary):
		return _falha("invalid_structure", "A raiz do save nao e um dicionario")
	var d: Dictionary = dados
	if not _inteiro(d.get("save_version")) \
			or int(d.get("save_version")) != CURRENT_SAVE_VERSION:
		return _falha("invalid_structure", "save_version atual em falta ou invalido")
	if d.get("save_kind") != SAVE_KIND:
		return _falha("invalid_structure", "save_kind incompativel")
	return _validar_campos_atuais(d, total_niveis)


static func ler(caminho: String, total_niveis: int) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return _falha("not_found", "Save inexistente: %s" % caminho)
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return _falha("io_error", "Nao foi possivel abrir %s" % caminho)
	var texto := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(texto) != OK:
		return _falha("corrupt_json", "JSON corrompido em %s" % caminho)
	var resultado := processar(json.data, total_niveis)
	resultado["path"] = caminho
	return resultado


static func escrever_seguro(dados: Variant, caminho_primary: String,
		caminho_backup: String, caminho_temp: String, total_niveis: int) -> Dictionary:
	var preparado := processar(dados, total_niveis)
	if not preparado.get("ok", false):
		return preparado
	var texto := JSON.stringify(preparado["data"], "\t")
	if texto.is_empty():
		return _falha("serialization_error", "A serializacao produziu texto vazio")
	if not _escrever_texto(caminho_temp, texto):
		return _falha("io_error", "Nao foi possivel escrever/flush o TEMP")
	return promover_temp_validado(
		caminho_primary, caminho_backup, caminho_temp, total_niveis)


## Separado da serialização para provar que um TEMP adulterado ou incompleto
## nunca é promovido. O chamador é responsável por ter escrito o TEMP.
static func promover_temp_validado(caminho_primary: String,
		caminho_backup: String, caminho_temp: String, total_niveis: int) -> Dictionary:
	var temp := ler(caminho_temp, total_niveis)
	if not temp.get("ok", false):
		return _falha("invalid_temp", "TEMP invalido: %s" % temp.get("message", ""))

	var primary_existia := FileAccess.file_exists(caminho_primary)
	var primary := ler(caminho_primary, total_niveis) if primary_existia else {}
	if primary_existia and primary.get("error") == "future_version":
		_remover(caminho_temp)
		return _falha("future_version", "Primary de versao futura preservado")
	var backup_existia := FileAccess.file_exists(caminho_backup)
	var backup_atual := ler(caminho_backup, total_niveis) if backup_existia else {}
	if backup_existia and backup_atual.get("error") == "future_version":
		_remover(caminho_temp)
		return _falha("future_version", "Backup de versao futura preservado")

	if primary_existia and primary.get("ok", false):
		var backup_ok := _guardar_backup_validado(
			caminho_primary, caminho_backup, total_niveis)
		if not backup_ok.get("ok", false):
			_remover(caminho_temp)
			return backup_ok
	elif not backup_atual.get("ok", false):
		# No primeiro save (ou quando só havia lixo), o próprio TEMP validado
		# passa também a backup antes da promoção. Assim nunca nasce um primary
		# novo sem existir pelo menos uma segunda cópia já verificada.
		var backup_inicial := _guardar_backup_validado(
			caminho_temp, caminho_backup, total_niveis)
		if not backup_inicial.get("ok", false):
			_remover(caminho_temp)
			return backup_inicial

	if primary_existia and not _remover(caminho_primary):
		_remover(caminho_temp)
		return _falha("replace_error", "Nao foi possivel libertar o caminho primary")
	if not _renomear(caminho_temp, caminho_primary):
		_restaurar_backup(caminho_primary, caminho_backup, caminho_temp, total_niveis)
		return _falha("replace_error", "Nao foi possivel promover o TEMP")

	var final := ler(caminho_primary, total_niveis)
	if not final.get("ok", false):
		_remover(caminho_primary)
		_restaurar_backup(caminho_primary, caminho_backup, caminho_temp, total_niveis)
		return _falha("replace_error", "Primary final falhou a verificacao")
	return {"ok": true, "data": final["data"], "migrations": temp["migrations"]}


static func _identificar_versao(d: Dictionary, total_niveis: int) -> Dictionary:
	if not d.has("save_version"):
		var legacy := _validar_legacy(d, total_niveis)
		if not legacy.get("ok", false):
			return _falha("invalid_legacy", "JSON sem versao nao e um save legacy reconhecido")
		return {"ok": true, "version": LEGACY_SAVE_VERSION}
	if not _inteiro(d["save_version"]):
		return _falha("invalid_structure", "save_version nao e inteiro")
	var versao := int(d["save_version"])
	if versao > CURRENT_SAVE_VERSION:
		return _falha("future_version", "save_version %d e superior a %d" % [
			versao, CURRENT_SAVE_VERSION])
	if versao < LEGACY_SAVE_VERSION:
		return _falha("unknown_version", "save_version negativa/desconhecida")
	var validacao := _validar_versao(d, versao, total_niveis)
	if not validacao.get("ok", false):
		return validacao
	return {"ok": true, "version": versao}


static func _validar_versao(d: Dictionary, versao: int, total_niveis: int) -> Dictionary:
	match versao:
		0:
			return _validar_legacy(d, total_niveis)
		1:
			if int(d.get("save_version", -1)) != 1:
				return _falha("invalid_structure", "Schema v1 sem versao 1")
			return _validar_campos_legacy(d, total_niveis, true)
		2:
			if int(d.get("save_version", -1)) != 2 or d.get("save_kind") != SAVE_KIND:
				return _falha("invalid_structure", "Schema v2 incompativel")
			return _validar_campos_legacy(d, total_niveis, true)
		3:
			if int(d.get("save_version", -1)) != 3 or d.get("save_kind") != SAVE_KIND:
				return _falha("invalid_structure", "Schema v3 incompativel")
			return _validar_campos_v3(d, total_niveis)
		4:
			return _validar_campos_v4(d, total_niveis)
		5:
			var normalizada := d.duplicate(true)
			normalizada["level_session"] = LEVEL_SESSION.normalizar(
				normalizada.get("level_session", {}),
				str(normalizada.get("current_level_id", "")))
			return validar_atual(normalizada, total_niveis)
	return _falha("unknown_version", "Schema sem validator")


static func _validar_legacy(d: Dictionary, total_niveis: int) -> Dictionary:
	# Assinatura mínima do formato realmente escrito antes da Execution 3A.
	# Um JSON arbitrário sem versão não é aceite apenas por ser Dictionary.
	for chave in ["vidas", "indice_nivel", "checkpoint", "habilidades"]:
		if not d.has(chave):
			return _falha("invalid_legacy", "Legacy sem campo identificador %s" % chave)
	return _validar_campos_legacy(d, total_niveis, false)


static func _validar_campos_legacy(d: Dictionary, total_niveis: int,
		exigir_completo: bool) -> Dictionary:
	var obrigatorios := ["vidas", "indice_nivel", "checkpoint", "habilidades"]
	if exigir_completo:
		obrigatorios.append_array(["pistas", "concluidos", "armas", "armaduras",
			"arma_equipada", "armadura_equipada", "hardcore",
			"hardcore_tempo_restante", "essencia", "melhorias"])
	for chave in obrigatorios:
		if not d.has(chave):
			return _falha("invalid_structure", "Campo obrigatorio em falta: %s" % chave)
	if not _inteiro(d.get("vidas")) or int(d.get("vidas")) < 0 \
			or int(d.get("vidas")) > 1000000:
		return _falha("invalid_structure", "vidas invalido")
	if not _inteiro(d.get("indice_nivel")) or int(d.get("indice_nivel")) < 0 \
			or int(d.get("indice_nivel")) >= total_niveis:
		return _falha("invalid_structure", "indice_nivel invalido")
	if not _vetor_json(d.get("checkpoint")):
		return _falha("invalid_structure", "checkpoint invalido")
	for chave in ["habilidades", "pistas", "armas", "armaduras"]:
		if d.has(chave) and not _array_strings(d[chave]):
			return _falha("invalid_structure", "%s nao e array de strings" % chave)
	if d.has("concluidos"):
		if not (d["concluidos"] is Array):
			return _falha("invalid_structure", "concluidos nao e array")
		for indice in d["concluidos"]:
			if not _inteiro(indice) or int(indice) < 0 or int(indice) >= total_niveis:
				return _falha("invalid_structure", "indice concluido invalido")
	for chave in ["arma_equipada", "armadura_equipada"]:
		if d.has(chave) and not (d[chave] is String):
			return _falha("invalid_structure", "%s nao e string" % chave)
	if d.has("hardcore") and not (d["hardcore"] is bool):
		return _falha("invalid_structure", "hardcore nao e booleano")
	if d.has("hardcore_tempo_restante") and not _numero_finito(d["hardcore_tempo_restante"]):
		return _falha("invalid_structure", "hardcore_tempo_restante invalido")
	if d.has("essencia") and (not _inteiro(d["essencia"]) or int(d["essencia"]) < 0):
		return _falha("invalid_structure", "essencia invalida")
	if d.has("melhorias"):
		if not (d["melhorias"] is Dictionary):
			return _falha("invalid_structure", "melhorias nao e dicionario")
		for chave in d["melhorias"]:
			if not (chave is String) or not _inteiro(d["melhorias"][chave]) \
					or int(d["melhorias"][chave]) < 0:
				return _falha("invalid_structure", "rank de melhoria invalido")
	return {"ok": true}


static func _validar_campos_v3(d: Dictionary, total_niveis: int) -> Dictionary:
	var obrigatorios := ["vidas", "current_level_id", "checkpoint", "ability_ids",
		"collectible_ids", "completed_level_ids", "defeated_boss_ids",
		"claimed_reward_ids", "armas", "armaduras", "arma_equipada",
		"armadura_equipada", "hardcore", "hardcore_tempo_restante", "essencia",
		"melhorias"]
	for chave in obrigatorios:
		if not d.has(chave):
			return _falha("invalid_structure", "Campo obrigatorio em falta: %s" % chave)
	for legacy in ["indice_nivel", "habilidades", "pistas", "concluidos"]:
		if d.has(legacy):
			return _falha("legacy_id_in_current", "Campo legacy chegou ao schema atual: %s" % legacy)
	if total_niveis != IDS.identidades().get("level_ids", []).size():
		return _falha("invalid_structure", "Contrato de niveis incompativel")
	if not _inteiro(d.get("vidas")) or int(d.get("vidas")) < 0 \
			or int(d.get("vidas")) > 1000000:
		return _falha("invalid_structure", "vidas invalido")
	if str(d.get("current_level_id", "")) not in IDS.identidades().get("level_ids", []):
		return _falha("invalid_progression_id", "current_level_id invalido")
	if not _vetor_json(d.get("checkpoint")):
		return _falha("invalid_structure", "checkpoint invalido")
	var validacoes := {
		"ability_ids": IDS.ability_ids(),
		"collectible_ids": IDS.collectible_ids(),
		"completed_level_ids": IDS.identidades().get("level_ids", []),
		"defeated_boss_ids": IDS.identidades().get("boss_ids", []),
		"claimed_reward_ids": IDS.reward_ids(),
	}
	for chave: String in validacoes:
		var resultado := _validar_ids_unicos(d[chave], validacoes[chave], chave)
		if not resultado.get("ok", false):
			return resultado
	for level_id: String in d["completed_level_ids"]:
		# Guardiões dos quatro primeiros níveis não são bosses/recompensas de
		# boss. Mantêm-se aceites os IDs legacy já presentes, mas só o quinto
		# nível de cada região exige estas referências num save novo.
		if not _e_exame_regional(level_id):
			continue
		var boss_id := IDS.boss_id_do_level_id(level_id)
		var reward_id := IDS.reward_id_bau_chefe(level_id)
		if boss_id != "" and boss_id not in d["defeated_boss_ids"]:
			return _falha("incompatible_progression_reference",
				"Nivel concluido sem boss correspondente: %s" % level_id)
		if reward_id != "" and reward_id not in d["claimed_reward_ids"]:
			return _falha("incompatible_progression_reference",
				"Nivel concluido sem recompensa correspondente: %s" % level_id)
	for chave in ["armas", "armaduras"]:
		if not _array_strings(d[chave]):
			return _falha("invalid_structure", "%s nao e array de strings" % chave)
	for chave in ["arma_equipada", "armadura_equipada"]:
		if not (d[chave] is String):
			return _falha("invalid_structure", "%s nao e string" % chave)
	if not (d["hardcore"] is bool):
		return _falha("invalid_structure", "hardcore nao e booleano")
	if not _numero_finito(d["hardcore_tempo_restante"]):
		return _falha("invalid_structure", "hardcore_tempo_restante invalido")
	if not _inteiro(d["essencia"]) or int(d["essencia"]) < 0:
		return _falha("invalid_structure", "essencia invalida")
	if not (d["melhorias"] is Dictionary):
		return _falha("invalid_structure", "melhorias nao e dicionario")
	for chave in d["melhorias"]:
		if not (chave is String) or not _inteiro(d["melhorias"][chave]) \
				or int(d["melhorias"][chave]) < 0:
			return _falha("invalid_structure", "rank de melhoria invalido")
	return {"ok": true}


static func _e_exame_regional(level_id: String) -> bool:
	var indice := IDS.indice_do_level_id(level_id)
	return indice >= 0 and (indice + 1) % 5 == 0


static func _validar_campos_v4(d: Dictionary, total_niveis: int) -> Dictionary:
	var copia := d.duplicate(true)
	if not copia.has("level_session"):
		return _falha("invalid_structure", "Campo obrigatorio em falta: level_session")
	if copia.has("checkpoint"):
		return _falha("legacy_id_in_current", "checkpoint legacy chegou ao schema atual")
	# Reutiliza os invariantes permanentes de v3 com um checkpoint neutro;
	# a sessao tem contrato proprio logo abaixo.
	copia["checkpoint"] = [0.0, 0.0]
	var permanente := _validar_campos_v3(copia, total_niveis)
	if not permanente.get("ok", false):
		return permanente
	var sessao: Variant = d["level_session"]
	if not (sessao is Dictionary):
		return _falha("invalid_structure", "level_session nao e dicionario")
	for chave in ["active", "level_id", "checkpoint_id"]:
		if not sessao.has(chave):
			return _falha("invalid_structure", "level_session sem campo %s" % chave)
	if not (sessao["active"] is bool) or not (sessao["level_id"] is String) \
			or not (sessao["checkpoint_id"] is String):
		return _falha("invalid_structure", "level_session tem tipos invalidos")
	if bool(sessao["active"]):
		if str(sessao["level_id"]) != str(d["current_level_id"]) \
				or not LEVEL_SESSION.id_valido_para_nivel(
					str(sessao["checkpoint_id"]), str(sessao["level_id"])):
			return _falha("invalid_session", "level_session ativa incoerente")
	elif str(sessao["level_id"]) != "" or str(sessao["checkpoint_id"]) != "":
		return _falha("invalid_session", "level_session inativa contem identidade")
	return {"ok": true}


static func _validar_campos_atuais(d: Dictionary, total_niveis: int) -> Dictionary:
	for legacy in ["hardcore", "hardcore_tempo_restante"]:
		if d.has(legacy):
			return _falha("legacy_state_in_current",
				"Estado Hardcore legacy chegou ao schema atual: %s" % legacy)
	var compatibilidade_v4 := d.duplicate(true)
	compatibilidade_v4["hardcore"] = false
	compatibilidade_v4["hardcore_tempo_restante"] = -1.0
	return _validar_campos_v4(compatibilidade_v4, total_niveis)


static func _validar_ids_unicos(valor: Variant, permitidos: Array,
		campo: String) -> Dictionary:
	if not _array_strings(valor):
		return _falha("invalid_structure", "%s nao e array de strings" % campo)
	var vistos := {}
	for id: String in valor:
		if vistos.has(id):
			return _falha("duplicate_progression_id", "%s contem ID duplicado" % campo)
		vistos[id] = true
		if id not in permitidos:
			return _falha("invalid_progression_id", "%s contem ID invalido: %s" % [campo, id])
	return {"ok": true}


static func _migrar_passo(d: Dictionary, versao: int) -> Dictionary:
	var out := d.duplicate(true)
	match versao:
		0:
			# Defaults já usados por EstadoJogo antes do versionamento. Mantêm a
			# compatibilidade sem reinterpretar nenhum campo legacy existente.
			var defaults := {
				"pistas": [], "concluidos": [], "armas": [], "armaduras": [],
				"arma_equipada": "", "armadura_equipada": "", "hardcore": false,
				"hardcore_tempo_restante": -1.0, "essencia": 0, "melhorias": {},
			}
			for chave in defaults:
				if not out.has(chave):
					out[chave] = defaults[chave]
			out["save_version"] = 1
			return {"ok": true, "data": out}
		1:
			# Não substitui um marcador conflitante: nesse caso a validação pós-
			# migration rejeita a estrutura em vez de a reinterpretar.
			if not out.has("save_kind"):
				out["save_kind"] = SAVE_KIND
			out["save_version"] = 2
			return {"ok": true, "data": out}
		2:
			var level_id := IDS.level_id_do_indice(int(out.get("indice_nivel", -1)))
			if level_id == "":
				return _falha("ambiguous_legacy_id", "indice_nivel v2 sem level ID equivalente")
			var ability_ids: Array[String] = []
			for chave: String in out.get("habilidades", []):
				var ability_id := IDS.ability_id_da_chave_runtime(chave)
				if ability_id == "":
					return _falha("ambiguous_legacy_id", "habilidade v2 desconhecida: %s" % chave)
				if ability_id not in ability_ids:
					ability_ids.append(ability_id)
			var collectible_ids: Array[String] = []
			for collectible_id: String in out.get("pistas", []):
				if collectible_id not in IDS.collectible_ids():
					return _falha("ambiguous_legacy_id", "pista v2 desconhecida: %s" % collectible_id)
				if collectible_id not in collectible_ids:
					collectible_ids.append(collectible_id)
			var completed_level_ids: Array[String] = []
			var defeated_boss_ids: Array[String] = []
			var claimed_reward_ids: Array[String] = []
			for indice: Variant in out.get("concluidos", []):
				var completed_id := IDS.level_id_do_indice(int(indice))
				if completed_id == "":
					return _falha("ambiguous_legacy_id", "nivel concluido v2 sem ID equivalente")
				if completed_id not in completed_level_ids:
					completed_level_ids.append(completed_id)
				var boss_id := IDS.boss_id_do_level_id(completed_id)
				if boss_id != "" and boss_id not in defeated_boss_ids:
					defeated_boss_ids.append(boss_id)
				var reward_id := IDS.reward_id_bau_chefe(completed_id)
				if reward_id != "" and reward_id not in claimed_reward_ids:
					claimed_reward_ids.append(reward_id)
			out["current_level_id"] = level_id
			out["ability_ids"] = ability_ids
			out["collectible_ids"] = collectible_ids
			out["completed_level_ids"] = completed_level_ids
			out["defeated_boss_ids"] = defeated_boss_ids
			out["claimed_reward_ids"] = claimed_reward_ids
			for legacy in ["indice_nivel", "habilidades", "pistas", "concluidos"]:
				out.erase(legacy)
			out["save_version"] = 3
			return {"ok": true, "data": out}
		3:
			var level_id := str(out.get("current_level_id", ""))
			out["level_session"] = LEVEL_SESSION.migrar_v3(
				level_id, out.get("checkpoint", [0.0, 0.0]))
			out.erase("checkpoint")
			out["save_version"] = 4
			return {"ok": true, "data": out}
		4:
			# Hardcore saiu do produto atual. Os campos continuam reconhecidos no
			# schema v4, mas nunca reativam a feature nem chegam ao schema corrente.
			out.erase("hardcore")
			out.erase("hardcore_tempo_restante")
			out["save_version"] = 5
			return {"ok": true, "data": out}
	return _falha("unknown_version", "Migration v%d inexistente" % versao)


static func _guardar_backup_validado(primary: String, backup: String,
		total_niveis: int) -> Dictionary:
	var texto := FileAccess.get_file_as_string(primary)
	var backup_temp := backup + ".tmp"
	if not _escrever_texto(backup_temp, texto):
		return _falha("backup_error", "Nao foi possivel escrever backup TEMP")
	var verificacao := ler(backup_temp, total_niveis)
	if not verificacao.get("ok", false):
		_remover(backup_temp)
		return _falha("backup_error", "Copia para backup falhou validacao")
	if FileAccess.file_exists(backup) and not _remover(backup):
		_remover(backup_temp)
		return _falha("backup_error", "Nao foi possivel substituir o backup")
	if not _renomear(backup_temp, backup):
		return _falha("backup_error", "Nao foi possivel promover o backup TEMP")
	return {"ok": true}


static func _restaurar_backup(primary: String, backup: String, temp: String,
		total_niveis: int) -> bool:
	var valido := ler(backup, total_niveis)
	if not valido.get("ok", false):
		return false
	var restore := temp + ".restore"
	if not _escrever_texto(restore, FileAccess.get_file_as_string(backup)):
		return false
	if FileAccess.file_exists(primary):
		_remover(primary)
	if not _renomear(restore, primary):
		return false
	return ler(primary, total_niveis).get("ok", false)


static func _escrever_texto(caminho: String, texto: String) -> bool:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(texto)
	f.flush()
	var erro := f.get_error()
	f.close()
	return erro == OK


static func _renomear(origem: String, destino: String) -> bool:
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(origem), ProjectSettings.globalize_path(destino)) == OK


static func _remover(caminho: String) -> bool:
	if not FileAccess.file_exists(caminho):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho)) == OK


static func _inteiro(valor: Variant) -> bool:
	if typeof(valor) == TYPE_INT:
		return true
	return typeof(valor) == TYPE_FLOAT and _numero_finito(valor) \
		and float(valor) == floorf(float(valor))


static func _numero_finito(valor: Variant) -> bool:
	return (typeof(valor) == TYPE_INT or typeof(valor) == TYPE_FLOAT) \
		and is_finite(float(valor))


static func _vetor_json(valor: Variant) -> bool:
	return valor is Array and valor.size() == 2 \
		and _numero_finito(valor[0]) and _numero_finito(valor[1])


static func _array_strings(valor: Variant) -> bool:
	if not (valor is Array):
		return false
	for item in valor:
		if not (item is String):
			return false
	return true


static func _falha(codigo: String, mensagem: String) -> Dictionary:
	return {"ok": false, "error": codigo, "message": mensagem}
