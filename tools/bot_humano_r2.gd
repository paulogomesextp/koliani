extends SceneTree
## BOT DE PLAYTEST HUMAN-LIKE (Regiao II -- niveis 05 a 10).
##
## NAO altera o jogo: e' um piloto externo que carrega um nivel e carrega nas
## MESMAS accoes que um telemovel carrega (`Input.action_press/release`). Nao
## toca em fisica, em vida, em dano nem no save da campanha -- o `user://` e'
## isolado por `XDG_DATA_HOME` por quem o corre (ver tools/correr_bot_r2.sh).
##
## O ponto nao e' ganhar: e' falhar COMO UM HUMANO FALHA. Tres perfis, com
## tempo de reaccao, erro de temporizacao, hesitacao, saltos curtos por
## largar o botao cedo, dashes desperdicados e reaccao tardia aos telegrafos.
##
## Uso:
##   godot --headless --path . --script res://tools/bot_humano_r2.gd -- \
##       <cena> <perfil> <seed> <saida.json> [tempo_max_s]
##   perfil: casual | normal | experiente

const ACC_ESQ := "mover_esquerda"
const ACC_DIR := "mover_direita"
const ACC_SALTO := "saltar"
const ACC_ATAQUE := "atacar"
const ACC_DASH := "dash"
const ACC_ROLAR := "rolar"

## Perfis. `reac_*` em segundos; `erro_salto` e' o desvio-padrao do erro de
## temporizacao; `falha_salto` a probabilidade de estragar um salto pedido.
const PERFIS := {
	"casual": {
		"reac_min": 0.22, "reac_max": 0.35,
		"erro_salto": 0.085, "falha_salto": 0.17,
		"hesita_por_s": 0.038, "hesita_dur": [0.30, 0.95],
		"dash_util": 0.22, "dash_gratuito_por_s": 0.055,
		"hold_salto": [0.16, 0.30], "prob_hold_curto": 0.22,
		"ataque_dist": 84.0, "prob_esquiva": 0.30, "rolar_util": 0.10,
	},
	"normal": {
		"reac_min": 0.14, "reac_max": 0.22,
		"erro_salto": 0.050, "falha_salto": 0.085,
		"hesita_por_s": 0.018, "hesita_dur": [0.20, 0.60],
		"dash_util": 0.50, "dash_gratuito_por_s": 0.026,
		"hold_salto": [0.20, 0.34], "prob_hold_curto": 0.12,
		"ataque_dist": 96.0, "prob_esquiva": 0.58, "rolar_util": 0.22,
	},
	"experiente": {
		"reac_min": 0.09, "reac_max": 0.15,
		"erro_salto": 0.028, "falha_salto": 0.032,
		"hesita_por_s": 0.006, "hesita_dur": [0.12, 0.35],
		"dash_util": 0.82, "dash_gratuito_por_s": 0.008,
		"hold_salto": [0.24, 0.36], "prob_hold_curto": 0.05,
		"ataque_dist": 108.0, "prob_esquiva": 0.82, "rolar_util": 0.38,
	},
}

var _rng := RandomNumberGenerator.new()
var _p: Dictionary = {}
var _cena := ""
var _perfil := "normal"
var _seed := 0
var _saida := "user://bot.json"
var _tmax := 300.0

# --- estado do piloto -------------------------------------------------------
var _t := 0.0                 # tempo de jogo (s)
var _kol: Node = null
var _porta: Node = null
var _chefe: Node = null
var _vida_ant := -1
var _salto_em := -1.0         # instante agendado para carregar em saltar
var _salto_hold := 0.0        # quanto tempo segurar
var _salto_ate := -1.0
var _salto_motivo := ""
var _hesita_ate := -1.0
var _ataque_cd := 0.0
var _dash_cd := 0.0
var _rolar_cd := 0.0
var _x_ref := 0.0
var _x_ref_t := 0.0
var _salto_ate2 := -9.0
var _antipanico := 0.0        # forca inverter o sentido durante uns frames
var _sentido := 1.0
var _fase_chefe_ant := -1
var _tel_em := -1.0           # instante em que vi um telegrafo
var _tel_dano := false
var _es: Node = null    # EstadoJogo (autoload: em `--script` so' existe por caminho)
var _checkpoints_vistos: Dictionary = {}
var _zonas_rect: Array = []
## Rota de superficies (BFS no grafo de plataformas) ate' a porta. Sem isto o
## bot so' sabe andar para a direita -- e a Regiao II tem niveis VERTICAIS
## (o N10 e' um poco), onde "a direita" e' o abismo.
## Botoes carregados com hora de largar. Sem isto, `atacar` ficava carregado
## para sempre e o `is_action_just_pressed` da Koliani so' disparava UMA vez
## na luta inteira -- o Guardiao acabava as runs com a vida cheia.
var _largar_em: Dictionary = {}
var _rota: Array = []
var _rota_i := 0
var _superficies: Array = []
## Correntes ascendentes ativas (rect + quanto ajudam a subir). O mapa de
## alcance tem de as conhecer: o poco esquerdo do N10 e a subida do N07 so'
## se fazem COM o vento, e sem isto o Dijkstra mandava sempre o bot pelo
## caminho mais perigoso.
var _updrafts: Array = []
## Zonas que ESTICAM um vao: planar contextual (N08) e rajadas horizontais.
## Sem elas o grafo cortava o salto central do N08 -- 640 px entre a
## IlhaMeio e a IlhaVento -- e o bot nem chegava a meio do nivel.
var _esticam: Array = []

# --- metricas ---------------------------------------------------------------
var M := {
	"cena": "", "perfil": "", "seed": 0,
	"tempo_s": 0.0, "concluido": false, "motivo_fim": "",
	"mortes": 0, "quedas": 0, "dano_total": 0, "golpes_sofridos": 0,
	"checkpoints": 0, "saltos": 0, "saltos_falhados": 0,
	"dashes": 0, "dashes_desperdicados": 0,
	"planar_frames": 0, "planar_s": 0.0,
	"vento_entradas": 0, "vento_s": 0.0,
	"hesitacao_s": 0.0, "hesitacoes": 0,
	"ataques": 0,
	"chefe_duracao_s": 0.0, "chefe_dano_sofrido": 0, "chefe_golpes_sofridos": 0,
	"chefe_telegrafos": 0, "chefe_ataques_evitados": 0, "chefe_derrotado": false,
	"progresso_x": 0.0, "x_max": 0.0, "x_alvo": 0.0,
	"pontos_de_falha": {}, "mortes_pos": [],     # x arredondado a 100 -> nº de mortes
	"encravamentos": 0,
	"chefe_vida_inicial": 0, "chefe_vida_min": 0,
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 4:
		push_error("uso: <cena> <perfil> <seed> <saida.json> [tmax]")
		quit(2)
		return
	_cena = args[0]
	_perfil = args[1]
	_seed = int(args[2])
	_saida = args[3]
	if args.size() > 4:
		_tmax = float(args[4])
	_p = PERFIS.get(_perfil, PERFIS["normal"])
	_rng.seed = _seed
	M["cena"] = _cena
	M["perfil"] = _perfil
	M["seed"] = _seed

	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	_es = es
	if es:
		var i := int(es.NIVEIS.find(_cena))
		if i >= 0:
			es.indice_nivel = i
		es.checkpoint = Vector2.ZERO
		es.vidas = 99          # o bot mede MORTES, nao game-overs
	change_scene_to_file(_cena)
	for _i in 6:
		await process_frame
	_ligar()
	await _correr()
	_gravar()
	quit(0)


# ---------------------------------------------------------------------------
func _ligar() -> void:
	_kol = get_first_node_in_group("koliani")
	if _kol == null:
		return
	if not _kol.is_connected("morreu", _ao_morrer):
		_kol.morreu.connect(_ao_morrer)
	if not _kol.is_connected("vida_mudou", _ao_vida):
		_kol.vida_mudou.connect(_ao_vida)
	_vida_ant = int(_kol.vida)
	var raiz := current_scene
	_porta = raiz.get_node_or_null("Porta") if raiz else null
	_chefe = raiz.get_node_or_null("Chefe") if raiz else null
	if _chefe == null and raiz:
		_chefe = raiz.get_node_or_null("Guardiao")
	if _porta:
		M["x_alvo"] = _porta.global_position.x
	_x_ref = _kol.global_position.x
	_x_ref_t = _t
	for z in get_nodes_in_group("zonas_vento"):
		if not z.is_connected("corpo_entrou", _ao_vento):
			z.corpo_entrou.connect(_ao_vento)
	_mapear()
	_mapear_vento()
	_mapear_estica()
	_zonas_rect.clear()
	for z in get_nodes_in_group("zonas_vento"):
		var wz := z as WindZone
		if wz == null:
			continue
		_zonas_rect.append(Rect2(
			wz.global_position - wz.tamanho * 0.5, wz.tamanho))
	_tracar_rota()
	M["rota_passos"] = maxi(int(M.get("rota_passos", 0)), _rota.size())
	M["superficies_mapeadas"] = _superficies.size()
	if OS.has_environment("BOT_DEBUG"):
		print("ROTA (", _rota.size(), " passos):")
		for w in _rota:
			print("   x[%.0f..%.0f] y=%.0f" % [w["x0"], w["x1"], w["y"]])


func _ao_morrer() -> void:
	M["mortes"] += 1
	if _kol and _kol.global_position.y > 1050.0:
		M["quedas"] += 1
	if _salto_motivo != "" and _t - _salto_ate < 2.5:
		M["saltos_falhados"] += 1
	var pk: Vector2 = _kol.global_position if _kol else Vector2.ZERO
	var mortes_pos: Array = M["mortes_pos"]
	mortes_pos.append([snappedf(pk.x, 1.0), snappedf(pk.y, 1.0)])
	var bx := 100.0 * roundi(pk.x / 100.0)
	var chave := str(int(bx))
	var pf: Dictionary = M["pontos_de_falha"]
	pf[chave] = int(pf.get(chave, 0)) + 1


func _ao_vida(atual: int, _maximo: int) -> void:
	if _vida_ant >= 0 and atual < _vida_ant:
		# o golpe LETAL vem sempre como "tira tudo o que resta" (a queda usa
		# `receber_dano(vida)`): contá-lo como dano inflacionava o total em
		# 100 por morte. As mortes tem contador proprio.
		var d: int = _vida_ant - atual
		if atual > 0:
			M["dano_total"] += d
			M["golpes_sofridos"] += 1
			if _chefe_acordado():
				M["chefe_dano_sofrido"] += d
				M["chefe_golpes_sofridos"] += 1
		_tel_dano = true
	_vida_ant = atual


func _ao_vento(corpo: Node) -> void:
	if corpo == _kol:
		M["vento_entradas"] += 1


# ---------------------------------------------------------------------------
func _correr() -> void:
	var dt := 1.0 / 60.0
	var relogio_real := Time.get_ticks_msec()
	while true:
		await physics_frame
		_t += dt
		if Time.get_ticks_msec() - relogio_real > 420000:
			M["motivo_fim"] = "timeout_real"
			break
		if _t > _tmax:
			M["motivo_fim"] = "timeout_jogo"
			break
		# a cena recarrega quando ela morre: reapanhar as referencias
		if _kol == null or not is_instance_valid(_kol) or not _kol.is_inside_tree():
			_soltar_tudo()
			await process_frame
			_ligar()
			if _kol == null:
				continue
		_passo(dt)
		if OS.has_environment("BOT_DEBUG2") and _chefe and is_instance_valid(_chefe) \
				and fmod(_t, 0.5) < dt and int(_chefe.get("_fase")) != 0:
			print("  t=%.1f fase=%s vida=%d  kol=(%.0f,%.0f) chefe=(%.0f,%.0f) olha=%s" % [
				_t, _nome_fase_chefe(int(_chefe.get("_fase"))), int(_chefe.vida),
				_kol.global_position.x, _kol.global_position.y,
				_chefe.global_position.x, _chefe.global_position.y,
				str(_kol.get("_olha_para"))])
		if OS.has_environment("BOT_DEBUG") and fmod(_t, 2.0) < dt:
			print("t=%5.1f  pos=(%.0f,%.0f)  wp=%d/%d  mortes=%d" % [
				_t, _kol.global_position.x, _kol.global_position.y,
				_rota_i, _rota.size(), M["mortes"]])
		if _fim():
			break
	_soltar_tudo()
	M["tempo_s"] = _t
	M["planar_s"] = float(M["planar_frames"]) * dt
	if _chefe and is_instance_valid(_chefe) and "vida" in _chefe:
		M["chefe_vida_final"] = int(_chefe.vida)
		M["chefe_vida_max"] = int(_chefe.get("_vida_max") if _chefe.get("_vida_max") else 0)


func _fim() -> bool:
	if _porta == null or not is_instance_valid(_porta) or _kol == null:
		return false
	# a porta selada nao conta: so' o atravessamento real
	var d: float = _kol.global_position.distance_to(_porta.global_position)
	if d < 46.0 and _porta.monitoring:
		M["concluido"] = true
		M["motivo_fim"] = "porta"
		return true
	return false


func _tap(accao: String, dur := 0.07) -> void:
	if Input.is_action_pressed(accao):
		Input.action_release(accao)
	Input.action_press(accao)
	_largar_em[accao] = _t + dur


func _servir_botoes() -> void:
	for a in _largar_em.keys():
		if _t >= float(_largar_em[a]):
			if Input.is_action_pressed(a):
				Input.action_release(a)
			_largar_em.erase(a)


func _soltar_tudo() -> void:
	for a in [ACC_ESQ, ACC_DIR, ACC_SALTO, ACC_ATAQUE, ACC_DASH, ACC_ROLAR]:
		if Input.is_action_pressed(a):
			Input.action_release(a)


# --- um passo do piloto -----------------------------------------------------
func _passo(dt: float) -> void:
	var pos: Vector2 = _kol.global_position
	M["x_max"] = maxf(M["x_max"], pos.x)
	_servir_botoes()
	_ataque_cd = maxf(0.0, _ataque_cd - dt)
	_dash_cd = maxf(0.0, _dash_cd - dt)
	_rolar_cd = maxf(0.0, _rolar_cd - dt)
	_antipanico = maxf(0.0, _antipanico - dt)
	if _chefe and is_instance_valid(_chefe) and "vida" in _chefe:
		var hv := int(_chefe.vida)
		if int(M.get("chefe_vida_inicial", 0)) <= 0:
			M["chefe_vida_inicial"] = hv
		M["chefe_vida_min"] = hv if int(M.get("chefe_vida_min", 0)) <= 0 \
			else mini(int(M["chefe_vida_min"]), hv)
	if _kol.get("_planando"):
		M["planar_frames"] += 1
	for r in _zonas_rect:
		if (r as Rect2).has_point(pos):
			M["vento_s"] = float(M["vento_s"]) + dt
			break
	var ck: Vector2 = _es.checkpoint if _es else Vector2.ZERO
	if ck != Vector2.ZERO:
		var chave_ck := "%d_%d" % [roundi(ck.x), roundi(ck.y)]
		if not _checkpoints_vistos.has(chave_ck):
			_checkpoints_vistos[chave_ck] = true
			M["checkpoints"] += 1

	# --- para onde? ---------------------------------------------------------
	var alvo := _alvo_atual(pos)
	var alvo_x: float = alvo.x
	var alvo_y: float = alvo.y
	var inimigo := _inimigo_perto(pos)
	# O chefe acorda a 620 px -- e no N10 isso acontece com a Koliani ainda a
	# meio do poco. Entrar em modo de combate ai' fazia o bot largar a rota e
	# ficar a olhar para cima: so' conta como combate quando ela esta' MESMO
	# na arena (a mesma altura que ele).
	var chefe_vivo := _chefe_acordado() \
		and absf(pos.y - _chefe.global_position.y) < 170.0
	if chefe_vivo:
		M["chefe_duracao_s"] += dt
		alvo_x = _chefe.global_position.x
		alvo_y = _chefe.global_position.y
	_sentido = signf(alvo_x - pos.x)
	if absf(alvo_x - pos.x) < 8.0:
		_sentido = 1.0
	if _antipanico > 0.0:
		_sentido = -_sentido

	# --- hesitacao (humano para, olha, pensa) -------------------------------
	if _t < _hesita_ate:
		_soltar_movimento()
		M["hesitacao_s"] += dt
		return
	if _rng.randf() < float(_p["hesita_por_s"]) * dt and not chefe_vivo:
		var hd: Array = _p["hesita_dur"]
		_hesita_ate = _t + _rng.randf_range(float(hd[0]), float(hd[1]))
		M["hesitacoes"] += 1
		_soltar_movimento()
		return

	# --- andar --------------------------------------------------------------
	var parar_para_bater := false
	if chefe_vivo:
		var dx: float = _chefe.global_position.x - pos.x
		parar_para_bater = absf(dx) < 52.0
	elif inimigo != null:
		parar_para_bater = absf(inimigo.global_position.x - pos.x) < 46.0
	if parar_para_bater:
		_soltar_movimento()
	elif _sentido > 0.0:
		if Input.is_action_pressed(ACC_ESQ):
			Input.action_release(ACC_ESQ)
		if not Input.is_action_pressed(ACC_DIR):
			Input.action_press(ACC_DIR)
	else:
		if Input.is_action_pressed(ACC_DIR):
			Input.action_release(ACC_DIR)
		if not Input.is_action_pressed(ACC_ESQ):
			Input.action_press(ACC_ESQ)

	# --- sensores -----------------------------------------------------------
	var d := _sentido
	var buraco := not _ha_chao(pos + Vector2(d * 52.0, 0.0))
	var buraco_longe := not _ha_chao(pos + Vector2(d * 96.0, 0.0))
	var parede := _ha_parede(pos, d)
	# a origem da Koliani esta' ~44 px acima dos pes; a altura do waypoint e' a
	# do TOPO da plataforma. Comparar centro com topo perdia todos os degraus
	# de menos de 110 px -- que e' quase toda a Regiao II.
	var pes: float = pos.y + 44.0
	var precisa_subir: bool = (alvo_y < pes - 45.0) and bool(_kol.is_on_floor())

	# --- pedir salto (com tempo de reaccao) ---------------------------------
	if _salto_em < 0.0 and _kol.is_on_floor():
		var motivo := ""
		if buraco and buraco_longe:
			motivo = "vao"
		elif parede:
			motivo = "parede"
		elif buraco:
			motivo = "borda"
		elif precisa_subir:
			# o alvo esta' acima: saltar quando ja' se esta' debaixo dele
			if absf(alvo_x - pos.x) < 150.0:
				motivo = "subir"
			elif _rng.randf() < 0.25:
				motivo = "subir_cedo"
		if motivo != "":
			var reac: float = _rng.randf_range(float(_p["reac_min"]), float(_p["reac_max"]))
			var erro: float = _rng.randfn(0.0, float(_p["erro_salto"]))
			_salto_em = _t + maxf(0.0, reac * 0.35 + erro)
			_salto_motivo = motivo
			var hh: Array = _p["hold_salto"]
			_salto_hold = _rng.randf_range(float(hh[0]), float(hh[1]))
			if _rng.randf() < float(_p["prob_hold_curto"]):
				_salto_hold *= 0.45          # largou o botao cedo -> salto curto
			if _rng.randf() < float(_p["falha_salto"]):
				_salto_em += _rng.randf_range(0.10, 0.26)   # reagiu tarde

	if _salto_em >= 0.0 and _t >= _salto_em:
		Input.action_press(ACC_SALTO)
		M["saltos"] += 1
		_salto_ate = _t + _salto_hold
		_salto_em = -1.0
	if _salto_ate >= 0.0 and _t >= _salto_ate:
		if Input.is_action_pressed(ACC_SALTO):
			Input.action_release(ACC_SALTO)
		_salto_ate = -1.0
	# planar CONTEXTUAL (N08): dentro da zona, segurar o botao e' a mecanica.
	if not _kol.is_on_floor() and _kol.velocity.y > 0.0 \
			and bool(_kol.call("pode_planar")) and alvo_x != pos.x:
		if _rng.randf() < 0.55 + float(_p["dash_util"]) * 0.4:
			if not Input.is_action_pressed(ACC_SALTO):
				Input.action_press(ACC_SALTO)
			_largar_em[ACC_SALTO] = _t + 0.30

	# planar: segurar saltar na descida sobre um vao (quem sabe usa mais)
	if not _kol.is_on_floor() and _kol.velocity.y > 40.0 and buraco \
			and _rng.randf() < float(_p["dash_util"]) * 0.5:
		if not Input.is_action_pressed(ACC_SALTO):
			Input.action_press(ACC_SALTO)
			_salto_ate = _t + 0.25

	# Dentro da coluna, quem sabe jogar NAO se desvia para os lados: fica no
	# meio dela ate' passar a altura do alvo. Sem isto o bot saia da coluna a
	# meio -- e a Regiao II tem duas subidas que so' se fazem assim.
	var coluna: float = _coluna_em(pos.x, pos.y)
	if coluna < INF and alvo_y < pes - 60.0:
		alvo_x = coluna
		_sentido = signf(alvo_x - pos.x) if absf(alvo_x - pos.x) > 14.0 else 0.0
		if _sentido == 0.0:
			_soltar_movimento()

	# --- subir agarrado a corrente ascendente -------------------------------
	# Dentro de uma corrente, quem sabe jogar nao larga o botao: fica na
	# coluna e vai saltando. E' a leitura que o N07/N08 ensinam.
	var na_corrente: bool = coluna < INF
	if na_corrente and alvo_y < pes - 40.0:
		if _kol.is_on_floor() or _kol.velocity.y > -40.0:
			if _t - _salto_ate2 > 0.32 and _rng.randf() > float(_p["falha_salto"]) * 0.5:
				_tap(ACC_SALTO, _rng.randf_range(0.18, 0.32))
				_salto_ate2 = _t
				M["saltos"] += 1

	# --- salto duplo para chegar a plataforma de cima ----------------------
	if not _kol.is_on_floor() and alvo_y < pes - 30.0 and _kol.velocity.y > -60.0 \
			and _salto_ate < 0.0 and _t - _salto_ate2 > 0.45:
		var erro2: float = _rng.randfn(0.0, float(_p["erro_salto"]))
		if _rng.randf() > float(_p["falha_salto"]):
			Input.action_release(ACC_SALTO)
			Input.action_press(ACC_SALTO)
			_salto_ate = _t + maxf(0.10, 0.26 + erro2)
			_salto_ate2 = _t
			M["saltos"] += 1

	# --- salto duplo a meio do vao (o humano corrige) -----------------------
	if not _kol.is_on_floor() and buraco and _kol.velocity.y > 120.0 \
			and _rng.randf() < 0.05:
		Input.action_release(ACC_SALTO)
		Input.action_press(ACC_SALTO)
		_salto_ate = _t + 0.16
		M["saltos"] += 1

	# --- dash ---------------------------------------------------------------
	if _dash_cd <= 0.0:
		var util := buraco and buraco_longe
		var pronto: bool = float(_kol.get("_dash_recarga")) <= 0.0
		if util and _rng.randf() < float(_p["dash_util"]):
			_tap(ACC_DASH)
			_dash_cd = 0.9
			if pronto:
				M["dashes"] += 1
		elif _rng.randf() < float(_p["dash_gratuito_por_s"]) * dt:
			_tap(ACC_DASH)
			_dash_cd = 1.1
			if pronto:
				M["dashes"] += 1
				M["dashes_desperdicados"] += 1

	# --- combate ------------------------------------------------------------
	_combate(pos, inimigo, chefe_vivo, dt)

	# --- encravou? ----------------------------------------------------------
	if absf(pos.x - _x_ref) > 34.0:
		_x_ref = pos.x
		_x_ref_t = _t
	elif _t - _x_ref_t > 2.4:
		M["encravamentos"] += 1
		_x_ref_t = _t
		_mapear()
		_mapear_vento()
		_mapear_estica()
		_tracar_rota()
		M["rota_passos"] = maxi(int(M.get("rota_passos", 0)), _rota.size())
		_antipanico = _rng.randf_range(0.25, 0.7)
		_salto_em = _t
		if _dash_cd <= 0.0:
			_tap(ACC_DASH)
			_dash_cd = 0.8
			M["dashes"] += 1
			M["dashes_desperdicados"] += 1
	M["progresso_x"] = M["x_max"]


func _combate(pos: Vector2, inimigo: Node, chefe_vivo: bool, _dt: float) -> void:
	if chefe_vivo:
		var f: int = int(_chefe.get("_fase"))
		if f != _fase_chefe_ant:
			_fase_chefe_ant = f
			var nome := _nome_fase_chefe(f)
			# `TELEGRAFO` (Golem) conta como telegrafo tanto como `*_TEL`
			# (os outros quatro); `EXPOSTA` (Feiticeira) e `RECUPERA`
			# (Golem) sao a mesma janela de castigo que `EXPOSTO`.
			if nome.ends_with("_TEL") or nome == "TELEGRAFO":
				M["chefe_telegrafos"] += 1
				_tel_dano = false
				# reaccao tardia: quem e' casual ve' o telegrafo demasiado tarde
				var atraso: float = _rng.randf_range(
					float(_p["reac_min"]), float(_p["reac_max"])) * 1.4
				_tel_em = _t + atraso
			elif nome.begins_with("EXPOST") or nome == "RECUPERA":
				if not _tel_dano:
					M["chefe_ataques_evitados"] += 1
		# esquiva: dash/rolar para longe quando o telegrafo "chega ao cerebro"
		if _tel_em >= 0.0 and _t >= _tel_em:
			_tel_em = -1.0
			if _rng.randf() < float(_p["prob_esquiva"]):
				if _rng.randf() < float(_p["rolar_util"]) and _rolar_cd <= 0.0:
					_tap(ACC_ROLAR)
					_rolar_cd = 1.0
				elif _dash_cd <= 0.0:
					_tap(ACC_DASH)
					_dash_cd = 0.9
					M["dashes"] += 1
		if absf(_chefe.global_position.x - pos.x) < float(_p["ataque_dist"]) \
				and _ataque_cd <= 0.0:
			_tap(ACC_ATAQUE)
			_ataque_cd = _rng.randf_range(0.34, 0.52)
			M["ataques"] += 1
		if int(_chefe.get("vida")) <= 0:
			M["chefe_derrotado"] = true
		return
	if inimigo != null and _ataque_cd <= 0.0:
		var dx: float = inimigo.global_position.x - pos.x
		if absf(dx) < float(_p["ataque_dist"]) \
				and absf(inimigo.global_position.y - pos.y) < 90.0:
			_tap(ACC_ATAQUE)
			_ataque_cd = _rng.randf_range(0.30, 0.48)
			M["ataques"] += 1


# --- utilitarios ------------------------------------------------------------
func _soltar_movimento() -> void:
	for a in [ACC_ESQ, ACC_DIR]:
		if Input.is_action_pressed(a):
			Input.action_release(a)


func _ha_chao(p: Vector2) -> bool:
	var espaco: PhysicsDirectSpaceState2D = _kol.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(
		p + Vector2(0.0, -12.0), p + Vector2(0.0, 132.0), 1)
	q.exclude = [_kol.get_rid()]
	return not espaco.intersect_ray(q).is_empty()


func _ha_parede(p: Vector2, d: float) -> bool:
	var espaco: PhysicsDirectSpaceState2D = _kol.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(
		p + Vector2(0.0, -16.0), p + Vector2(d * 44.0, -16.0), 1)
	q.exclude = [_kol.get_rid()]
	if espaco.intersect_ray(q).is_empty():
		return false
	# so' conta como parede se houver espaco por cima (senao e' tecto)
	var q2 := PhysicsRayQueryParameters2D.create(
		p + Vector2(0.0, -70.0), p + Vector2(d * 44.0, -70.0), 1)
	q2.exclude = [_kol.get_rid()]
	return espaco.intersect_ray(q2).is_empty()


func _inimigo_perto(pos: Vector2) -> Node:
	var melhor: Node = null
	var melhor_d := 260.0
	for e in get_nodes_in_group("inimigos"):
		if not is_instance_valid(e) or e == _chefe:
			continue
		if "vida" in e and int(e.vida) <= 0:
			continue
		var dd: float = absf(e.global_position.x - pos.x)
		if dd < melhor_d and absf(e.global_position.y - pos.y) < 130.0:
			melhor_d = dd
			melhor = e
	return melhor


## O combate comecou? NAO se pode testar por `_fase != 0`: so' quatro das
## cinco maquinas de estado da regiao comecam em DORME -- a do Golem das
## Falesias comeca em APROXIMA, e com aquele teste o combate dele contava
## desde o primeiro frame do nivel. O criterio uniforme e' a DISTANCIA.
func _chefe_acordado() -> bool:
	if _chefe == null or not is_instance_valid(_chefe) or _kol == null:
		return false
	if "vida" in _chefe and int(_chefe.vida) <= 0:
		return false
	return absf(_chefe.global_position.x - _kol.global_position.x) < 620.0


func _nome_fase_chefe(valor: int) -> String:
	var s: Script = _chefe.get_script()
	if s == null:
		return ""
	for c in s.get_script_constant_map().values():
		if c is Dictionary:
			for nome in (c as Dictionary):
				if int((c as Dictionary)[nome]) == valor:
					return String(nome)
	return ""


func _gravar() -> void:
	M["tempo_s"] = snappedf(M["tempo_s"], 0.01)
	M["planar_s"] = snappedf(M["planar_s"], 0.01)
	M["hesitacao_s"] = snappedf(float(M["hesitacao_s"]), 0.01)
	M["vento_s"] = snappedf(float(M["vento_s"]), 0.01)
	M["chefe_duracao_s"] = snappedf(float(M["chefe_duracao_s"]), 0.01)
	var f := FileAccess.open(_saida, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(M, "  "))
		f.close()
	print("BOT_JSON ", JSON.stringify(M))


# --- mapa de plataformas e rota --------------------------------------------
## Recolhe o TOPO de cada corpo estatico da camada 1. E' o unico "conhecimento
## do nivel" que o bot tem -- o mesmo que um jogador tem depois de olhar para
## o ecra: onde da' para por os pes.
func _mapear() -> void:
	_superficies.clear()
	var pilha: Array = [current_scene]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		if n == null:
			continue
		for c in n.get_children():
			pilha.append(c)
		if not (n is StaticBody2D):
			continue
		var sb := n as StaticBody2D
		if (sb.collision_layer & 1) == 0:
			continue
		for c in sb.get_children():
			if not (c is CollisionShape2D):
				continue
			var cs := c as CollisionShape2D
			if cs.disabled or not (cs.shape is RectangleShape2D):
				continue
			var r := (cs.shape as RectangleShape2D).size
			var t := cs.global_transform
			var meia := Vector2(r.x * 0.5 * t.get_scale().x, r.y * 0.5 * t.get_scale().y)
			var c0 := t.origin
			_superficies.append({
				"x0": c0.x - meia.x, "x1": c0.x + meia.x,
				"y": c0.y - meia.y, "yb": c0.y + meia.y,
			})


## Qual a superficie em que este ponto POUSA. A tolerancia para cima existe
## porque as origens dos nos nao estao nos pes (a Porta esta' ~60 px acima do
## chao da arena); sem ela o destino do BFS ficava -1 e o bot andava para a
## direita ate' ao abismo.
func _mapear_vento() -> void:
	_updrafts.clear()
	for z in get_nodes_in_group("zonas_vento"):
		var w := z as WindZone
		if w == null or not w.ativa or w.direcao.y >= -0.4:
			continue
		var c: Vector2 = w.global_position
		_updrafts.append({
			"x0": c.x - w.tamanho.x * 0.5, "x1": c.x + w.tamanho.x * 0.5,
			"y0": c.y - w.tamanho.y * 0.5, "y1": c.y + w.tamanho.y * 0.5,
			# Uma coluna continua mais forte do que a gravidade leva a Koliani
			# ate' ao TOPO da zona -- a altura da zona e' que manda, nao a
			# intensidade. Abaixo de ~1400 ja' nao vence a queda e so' ajuda.
			"ajuda": w.tamanho.y * 0.85 * clampf(w.intensidade / 1400.0, 0.0, 1.0),
		})


func _mapear_estica() -> void:
	_esticam.clear()
	for z in get_nodes_in_group("zonas_planar"):
		var pz := z as ZonaPlanar
		if pz == null or not pz.ativa:
			continue
		var c: Vector2 = pz.global_position
		_esticam.append({
			"x0": c.x - pz.tamanho.x * 0.5, "x1": c.x + pz.tamanho.x * 0.5,
			"y0": c.y - pz.tamanho.y * 0.5, "y1": c.y + pz.tamanho.y * 0.5,
			"ganho": 420.0,
		})
	for z in get_nodes_in_group("zonas_vento"):
		var w := z as WindZone
		if w == null or not w.ativa or absf(w.direcao.x) < 0.4:
			continue
		var c2: Vector2 = w.global_position
		_esticam.append({
			"x0": c2.x - w.tamanho.x * 0.5, "x1": c2.x + w.tamanho.x * 0.5,
			"y0": c2.y - w.tamanho.y * 0.5, "y1": c2.y + w.tamanho.y * 0.5,
			"ganho": clampf(w.velocidade_max * 0.55, 0.0, 240.0),
		})


## Centro da coluna ascendente que serve este ponto (INF se nenhuma).
func _coluna_em(x: float, y: float) -> float:
	for u in _updrafts:
		if x < float(u["x0"]) - 40.0 or x > float(u["x1"]) + 40.0:
			continue
		if y < float(u["y0"]) - 40.0 or y > float(u["y1"]) + 90.0:
			continue
		return (float(u["x0"]) + float(u["x1"])) * 0.5
	return INF


func _ganho_vao(x: float, y: float) -> float:
	var t := 0.0
	for u in _esticam:
		if x < float(u["x0"]) - 40.0 or x > float(u["x1"]) + 40.0:
			continue
		if y < float(u["y0"]) - 140.0 or y > float(u["y1"]) + 200.0:
			continue
		t += float(u["ganho"])
	return minf(t, 560.0)


## Quanto e' que o vento ajuda a subir a partir deste ponto.
func _ajuda_vento(x: float, y: float) -> float:
	var melhor := 0.0
	for u in _updrafts:
		if x < float(u["x0"]) or x > float(u["x1"]):
			continue
		if y < float(u["y0"]) - 50.0 or y > float(u["y1"]) + 50.0:
			continue
		melhor = maxf(melhor, float(u["ajuda"]))
	return melhor


func _superficie_sob(p: Vector2) -> int:
	var melhor := -1
	var melhor_d := 320.0
	for i in _superficies.size():
		var s: Dictionary = _superficies[i]
		if p.x < float(s["x0"]) - 26.0 or p.x > float(s["x1"]) + 26.0:
			continue
		var d: float = float(s["y"]) - p.y
		if d < -96.0 or d > melhor_d:
			continue
		melhor_d = maxf(d, 0.0)
		melhor = i
	return melhor


func _vao(a: Dictionary, b: Dictionary) -> float:
	if float(a["x1"]) < float(b["x0"]):
		return float(b["x0"]) - float(a["x1"])
	if float(b["x1"]) < float(a["x0"]):
		return float(a["x0"]) - float(b["x1"])
	return 0.0


## Salto: v=470, g=1400 -> ~79 px de altura; com o salto duplo ~150 px e
## ~230 px de alcance horizontal. Cair e' de graca (ate' ao fundo do poco).
## X onde a transicao acontece: o meio do vao, ou o meio da sobreposicao.
func _x_transicao(a: Dictionary, b: Dictionary) -> float:
	if float(a["x1"]) < float(b["x0"]):
		return (float(a["x1"]) + float(b["x0"])) * 0.5
	if float(b["x1"]) < float(a["x0"]):
		return (float(b["x1"]) + float(a["x0"])) * 0.5
	return (maxf(float(a["x0"]), float(b["x0"])) + minf(float(a["x1"]), float(b["x1"]))) * 0.5


func _liga(a: Dictionary, b: Dictionary) -> bool:
	var sobe: float = float(a["y"]) - float(b["y"])
	var g: float = _vao(a, b)
	var tx: float = _x_transicao(a, b)
	var ajuda: float = _ajuda_vento(tx, float(a["y"]))
	var estica: float = _ganho_vao(tx, float(a["y"]))
	if sobe > 0.0:
		if sobe > 155.0 + ajuda:
			return false
		# e nenhuma plataforma e' atravessavel: se `b` esta' inteiramente por
		# CIMA de `a`, saltar dali bate-lhe na barriga. Tem de haver chao em
		# `a` FORA do vao de `b` de onde se largue ao lado dela.
		if g <= 0.0 and float(a["x0"]) >= float(b["x0"]) - 8.0 \
				and float(a["x1"]) <= float(b["x1"]) + 8.0:
			return false
		return g <= 250.0 + estica + minf(ajuda, 240.0) * 0.6
	var queda: float = -sobe
	if queda > 900.0:
		return false
	if g <= 0.0 and float(b["x0"]) >= float(a["x0"]) - 8.0 \
			and float(b["x1"]) <= float(a["x1"]) + 8.0:
		return false   # `b` escondida por baixo de `a`: nao ha' por onde cair
	return g <= 520.0 + estica


## VAO SEGURO: o que se faz sem pensar. Acima disto o salto ainda e' possivel
## (ver `_liga`) mas passa a ser um RISCO -- e o custo cresce depressa, para o
## Dijkstra so' o escolher quando nao ha' rota mansa.
func _vao_seguro(a: Dictionary, b: Dictionary) -> float:
	var sobe: float = float(a["y"]) - float(b["y"])
	var tx: float = _x_transicao(a, b)
	var ajuda: float = _ajuda_vento(tx, float(a["y"]))
	var estica: float = _ganho_vao(tx, float(a["y"]))
	if sobe > 0.0:
		return maxf(0.0, 215.0 - maxf(0.0, sobe - ajuda) * 1.05) + estica
	# salto duplo por cima do vao, a 240 px/s
	var queda: float = -sobe
	return 240.0 * (0.7 + sqrt(2.0 * (160.0 + queda) / 1708.0)) + estica


## Custo de um salto para o Dijkstra: contar SALTOS iguais (BFS) faz o bot
## escolher sempre a rota mais curta, que na Regiao II e' a mais perigosa (o
## poco direito, de saltos de 130-150 px sobre o acido). Um humano escolhe a
## rota LEGIVEL. Penalizar a subida e o vao aproxima disso.
func _custo(a: Dictionary, b: Dictionary) -> float:
	var sobe: float = float(a["y"]) - float(b["y"])
	var g: float = _vao(a, b)
	var ajuda: float = _ajuda_vento(_x_transicao(a, b), float(a["y"]))
	var seguro: float = _vao_seguro(a, b)
	var c := 1.0
	if sobe > 0.0:
		c += pow(maxf(0.0, sobe - ajuda * 0.5) / 150.0, 2.0) * 3.0
	else:
		c += pow(minf(-sobe, 900.0) / 900.0, 2.0) * 1.2
	c += pow(maxf(0.0, g - seguro) / 110.0, 2.0) * 4.5
	return c


func _tracar_rota() -> void:
	_rota.clear()
	_rota_i = 0
	if _kol == null or _superficies.is_empty():
		return
	var origem := _superficie_sob(_kol.global_position + Vector2(0.0, 40.0))
	var destino := -1
	if _porta and is_instance_valid(_porta):
		destino = _superficie_sob(_porta.global_position + Vector2(0.0, 60.0))
	if origem < 0 or destino < 0:
		return
	if origem == destino:
		_rota = [_superficies[destino]]
		return
	var n := _superficies.size()
	var dist := PackedFloat32Array()
	dist.resize(n)
	dist.fill(INF)
	var pai := PackedInt32Array()
	pai.resize(n)
	pai.fill(-1)
	var visto := PackedByteArray()
	visto.resize(n)
	dist[origem] = 0.0
	for _passo in n:
		var u := -1
		var melhor := INF
		for i in n:
			if visto[i] == 0 and dist[i] < melhor:
				melhor = dist[i]
				u = i
		if u < 0 or u == destino:
			break
		visto[u] = 1
		for v in n:
			if visto[v] == 1 or v == u:
				continue
			if not _liga(_superficies[u], _superficies[v]):
				continue
			var nd: float = dist[u] + _custo(_superficies[u], _superficies[v])
			if nd < dist[v]:
				dist[v] = nd
				pai[v] = u
	if dist[destino] == INF:
		return
	var caminho: Array = []
	var k: int = destino
	while k != -1:
		caminho.push_front(_superficies[k])
		k = pai[k]
	_rota = caminho
	_rota_i = mini(1, _rota.size() - 1)


## Alvo imediato: o ponto da proxima superficie da rota mais perto de onde ela
## esta'. Sem rota (BFS falhou), aponta a porta -- e o anti-encravamento
## trata do resto, tal como um jogador perdido.
func _alvo_atual(pos: Vector2) -> Vector2:
	if _rota.is_empty():
		if _porta and is_instance_valid(_porta):
			return _porta.global_position
		return pos + Vector2(600.0, 0.0)
	# RESSINCRONIZAR: em que degrau da rota e' que ela esta' MESMO? Sem isto,
	# uma queda de tres plataformas deixava o bot a perseguir um waypoint que
	# ja' tinha passado (ou que ja' nao alcancava) -- e ficava a bater no
	# mesmo sitio ate' ao fim do tempo.
	var pes: float = pos.y + 44.0
	for i in _rota.size():
		var s: Dictionary = _rota[i]
		if pos.x > float(s["x0"]) - 22.0 and pos.x < float(s["x1"]) + 22.0 \
				and absf(pes - float(s["y"])) < 26.0:
			_rota_i = mini(i + 1, _rota.size() - 1)
			break
	var wp: Dictionary = _rota[mini(_rota_i, _rota.size() - 1)]
	return Vector2(clampf(pos.x, float(wp["x0"]) + 22.0, float(wp["x1"]) - 22.0),
		float(wp["y"]))
