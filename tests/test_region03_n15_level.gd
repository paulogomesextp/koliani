class_name TestesRegion03N15
extends RefCounted
## Contrato estrutural do N15 -- "O Topo dos Ecos", 5.o e ultimo nivel da
## Regiao III (Torre dos Ecos). Nivel AUTORAL gerado por
## `tools/construir_n15_topo.py`.
## Contrato: docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md
## (N15, LOCKED). Desenho e medicoes: docs/nivel_autoral_n15.md.
##
## Prova, com o salto REAL da Koliani, que a escada de ecos e' o unico
## caminho para a arena (480 px acima do altar), que nenhum satelite dos
## fragmentos fica a um salto do chao da arena, e que a arena nao tem nenhuma
## face ao alcance de quem escala paredes. A logica dos fragmentos e do ritual
## prova-se em fisica no `run_tests.gd` (`teste_r3_n15_fragmentos_e_escada`,
## `teste_r3_n15_ritual_ergue_a_fase2`) e os portoes no crivo em
## `teste_r3_n15_portoes_no_crivo`.

const CENA := "res://scenes/levels/O_Pico_Esquecido.tscn"
const INDICE_N15 := 14
const ALTURA_CORPO := 44.0
const MANTLE := 32.0
const FOLGA := 12.0
const N12 := preload("res://tests/test_region03_n12_level.gd")
const ESPECIES := ["sentinela_da_torre", "acolito_do_eco", "sino_flutuante", "arqueiro_das_sombras",
	"gargula_vitral", "automato_do_sino", "monge_das_correntes", "corvo_do_sino",
	"espirito_do_eco", "construto_vitral"]


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N15: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	# --- nivel autoral com o chefe final da regiao --------------------------
	_verificar(falhas, raiz.get("corredor") == false, "N15: sem jornada procedural")
	_verificar(falhas, raiz.get("alongar_plataformas") == false,
		"N15: sem esticao automatico (os portoes dependem das medidas exactas)")
	_verificar(falhas, raiz.get("checkpoints_autorais") == true, "N15: checkpoints autorais")
	var chefe := raiz.get_node_or_null("Chefe")
	_verificar(falhas, chefe != null and String(chefe.scene_file_path).ends_with("/ChefeVyrak.tscn"),
		"N15: o chefe e' o Vyrak")
	_verificar(falhas, raiz.get_node_or_null("Porta") != null, "N15: tem porta")
	_verificar(falhas, CatalogoCampanha.CHEFE_KEY[INDICE_N15] == "boss.vyrak", "N15: a HUD diz Vyrak")
	_verificar(falhas, EstadoJogo.NIVEIS[INDICE_N15] == CENA, "N15: indice 14 aponta para esta cena")
	for filho in raiz.get_children():
		var hab = filho.get("habilidade_id")
		_verificar(falhas, hab == null or String(hab) == "",
			"N15: %s concede uma habilidade -- so' o bau do chefe o faz" % filho.name)
	var atm := raiz.get_node_or_null("Atmosfera")
	_verificar(falhas, atm != null and String(atm.get("bioma")) == "torres", "N15: bioma torres")
	_verificar(falhas, atm != null and String(atm.get("fundo_pack")) == "torre_ecos", "N15: fundo torre_ecos")

	# --- "todos os inimigos da regiao" --------------------------------------
	var especies := {}
	for filho in raiz.get_children():
		var e: Variant = filho.get("especie")
		if e != null and String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			especies[String(e)] = true
	for e in ESPECIES:
		_verificar(falhas, especies.has(e), "N15: falta o inimigo da regiao `%s`" % e)

	# --- mecanicas, unicos e hazards do contrato ------------------------------
	var n := {"sino": 0, "celestial": 0, "temporizada": 0, "ecos": 0, "raio": 0, "quebra": 0,
		"balanco": 0, "elevador": 0, "ar": 0, "vento": 0, "queda": 0, "frag": 0, "degrau": 0,
		"fase2": 0}
	for filho in raiz.get_children():
		var f := String(filho.scene_file_path)
		var sc: Script = filho.get_script()
		var sp := sc.resource_path if sc else ""
		if f.ends_with("/SinoTorre.tscn"):
			n.sino += 1
			_verificar(falhas, filho.get("textura") != null,
				"N15: o sino %s devia usar a arte aprovada" % filho.name)
			if int(filho.get("fragmentos_necessarios")) > 0:
				n.celestial += 1
		elif sp.ends_with("plataforma_fase2.gd"):
			n.fase2 += 1
			_verificar(falhas, filho.get("textura_suporte") != null,
				"N15: %s devia usar a plataforma final da prancha" % filho.name)
		elif f.ends_with("/PlataformaSino.tscn"):
			if float(filho.get("duracao_solida")) > 0.0:
				n.temporizada += 1
			elif String(filho.get("grupo_alternar")) == "arena":
				n.degrau += 1
		elif f.ends_with("/PlataformaRitmada.tscn"):
			n.ecos += 1
			_verificar(falhas, filho.get("textura_eco") != null,
				"N15: %s devia ser o eco de memoria da prancha" % filho.name)
		elif f.ends_with("/RaioTempestade.tscn"):
			n.raio += 1
			_verificar(falhas, bool(filho.get("automatico")) and filho.get("textura_feixe") != null,
				"N15: %s devia ser um feixe de luz automatico com a arte da prancha" % filho.name)
		elif f.ends_with("/PlataformaQuebra.tscn"):
			n.quebra += 1
		elif sp.ends_with("plataforma_balanco.gd"):
			n.balanco += 1
		elif sp.ends_with("elevador_coluna.gd"):
			n.elevador += 1
		elif f.ends_with("/CorrenteAr.tscn"):
			n.ar += 1
			_verificar(falhas, filho.get("pele") != null, "N15: %s devia usar o updraft da prancha" % filho.name)
		elif sp.ends_with("corrente_lateral.gd"):
			n.vento += 1
			_verificar(falhas, filho.get("pele") != null, "N15: %s devia usar o vento da prancha" % filho.name)
		elif f.ends_with("/PedraQueda.tscn"):
			n.queda += 1
		elif sp.ends_with("fragmento_eco.gd"):
			n.frag += 1
			_verificar(falhas, filho.get("textura") != null,
				"N15: %s devia ser o fragmento de eco da prancha" % filho.name)
	_verificar(falhas, n.sino >= 2, "N15: sinos (>= 2), ha' %d" % n.sino)
	_verificar(falhas, n.celestial == 1, "N15: um sino celestial que espera os fragmentos")
	_verificar(falhas, n.temporizada >= 4, "N15: plataformas temporizadas (>= 4), ha' %d" % n.temporizada)
	_verificar(falhas, n.ecos >= 8, "N15: ecos de memoria (>= 8 plataformas ilusorias), ha' %d" % n.ecos)
	_verificar(falhas, n.raio >= 4, "N15: feixes de luz (>= 4), ha' %d" % n.raio)
	_verificar(falhas, n.quebra >= 7, "N15: estruturas em colapso (>= 7 pedras), ha' %d" % n.quebra)
	_verificar(falhas, n.balanco >= 2, "N15: plataformas dinamicas (>= 2 baloicos), ha' %d" % n.balanco)
	_verificar(falhas, n.elevador >= 1, "N15: elevador de vaivem")
	_verificar(falhas, n.ar >= 1, "N15: vento vertical")
	_verificar(falhas, n.vento >= 3, "N15: vento intenso (>= 3 zonas), ha' %d" % n.vento)
	_verificar(falhas, n.queda >= 2, "N15: sinos em queda (>= 2), ha' %d" % n.queda)
	_verificar(falhas, n.frag == 3, "N15: tres fragmentos de eco, ha' %d" % n.frag)
	_verificar(falhas, n.degrau == 4, "N15: a escada de ecos (4 degraus + o chao), ha' %d" % n.degrau)
	_verificar(falhas, n.fase2 >= 3, "N15: plataformas da fase 2 (>= 3), ha' %d" % n.fase2)

	# --- segredos e checkpoints ----------------------------------------------
	var segredos := 0
	var checks := 0
	for filho in raiz.get_children():
		if String(filho.name).begins_with("EssenciaSegredo"):
			segredos += 1
		if filho is Area2D and String(filho.name).begins_with("Check"):
			checks += 1
	_verificar(falhas, segredos == 4, "N15: 4 segredos (contrato), ha' %d" % segredos)
	_verificar(falhas, checks >= 7, "N15: >= 7 checkpoints, ha' %d" % checks)

	# --- PORTOES medidos com o salto real e contra o escalar paredes -----------
	var h := N12.alcance_salto_duplo()
	var alcance_topo := h + MANTLE + FOLGA
	var altar := N12._caixa(raiz, "Altar")
	var arena := N12._caixa(raiz, "ArenaChao")
	if altar.is_empty() or arena.is_empty():
		falhas.append("N15: faltam o altar e/ou o chao da arena")
	else:
		# a escada de ecos: 4 degraus + o chao, cada lance dentro do salto, mas o
		# total muito alem dele (sem os degraus o chao da arena nao se alcanca)
		var antes: float = altar.topo
		for k in range(1, 5):
			var d := N12._caixa(raiz, "Degrau%d" % k)
			_verificar(falhas, not d.is_empty(), "N15: falta o Degrau%d" % k)
			if d.is_empty():
				continue
			_verificar(falhas, antes - d.topo <= 118.0,
				"N15: o Degrau%d sobe %.0f (> 118, nao se salta)" % [k, antes - d.topo])
			antes = d.topo
		_verificar(falhas, antes - arena.topo <= 118.0, "N15: o ultimo degrau a' arena e' alto demais")
		_verificar(falhas, altar.topo - arena.topo > alcance_topo * 1.5,
			"N15: a arena salta-se do altar (sobe %.0f, alcance %.0f)" % [altar.topo - arena.topo, alcance_topo])
		# os satelites (e os segredos) a mais de um salto da face de baixo da
		# arena: nem a saltar nem a escalar a face dela se la' chega
		for nome in ["SatN", "SatE", "SatNE", "Segredo3", "EcoF3_1", "EcoF3_2"]:
			var c := N12._caixa(raiz, nome)
			if c.is_empty():
				falhas.append("N15: falta %s" % nome)
				continue
			if c.dir > arena.esq and c.esq < arena.dir + 60.0:
				_verificar(falhas, c.topo - arena.base > alcance_topo,
					"N15: %s esta' a um salto da arena (%.0f, alcance %.0f)" % [nome, c.topo - arena.base, alcance_topo])
		# a arena nao tem paredes ao alcance: o parapeito do lado da porta so'
		# comeca acima da face de baixo do chao
		var par := raiz.get_node_or_null("ParapeitoArena") as Node2D
		if par:
			var col := par.get_node("Col") as CollisionShape2D
			var sz := (col.shape as RectangleShape2D).size
			var base_par := par.position.y + sz.y * 0.5
			_verificar(falhas, base_par <= arena.base + 1.0,
				"N15: o parapeito da arena desce abaixo do chao (base %.0f, chao ate' %.0f)" % [base_par, arena.base])
	# o sino celestial fica no altar, e os tres fragmentos a menos de um ecra dele
	var sc := raiz.get_node_or_null("SinoCelestial") as Node2D
	if sc:
		for nome in ["FragmentoN", "FragmentoE", "FragmentoNE"]:
			var fr := raiz.get_node_or_null(nome) as Node2D
			_verificar(falhas, fr != null and fr.position.distance_to(sc.position) < 2000.0,
				"N15: %s devia ficar a menos de um ecra do sino celestial" % nome)
	else:
		falhas.append("N15: falta o sino celestial")

	raiz.free()
	return falhas


static func _verificar(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
