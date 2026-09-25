extends Node
## F1 -- BANCADA DE DIAGNÓSTICO DO MOVIMENTO (só mede, não altera gameplay).
##
## Corre a Koliani REAL (`Koliani.tscn`, rig golden, habilidades da Região I)
## numa arena plana e regista o estado COMPLETO de cada tick de física
## (posição, velocidade, chão, animação, frame, timers). Nada aqui toca em
## constantes nem em scripts do jogo.
##
## Amostragem: `_process` desta cena tem prioridade depois da Koliani, por
## isso cada amostra é o estado no FIM do frame N (física N + animação N).
## Os inputs são aplicados no sinal `physics_frame`, antes da física do tick,
## logo `paso(acoes)` = "estas ações valem para o tick N; devolve o estado
## no fim dele". Exige `--fixed-fps 60` (1 tick de física = 1 frame).
##
## Uso (sempre isolado -- ver CLAUDE.md):
##   python tools/godot_isolado.py -- --headless --fixed-fps 60 --path . \
##       res://tools/bench_movimento_f1.tscn -- <saida.json>

const KOLI := preload("res://scenes/actors/Koliani.tscn")
const CHAO_Y := 600.0
const TICK := 1.0 / 60.0
const ACOES := ["mover_esquerda", "mover_direita", "saltar", "dash", "rolar",
	"atacar", "mirar_baixo", "mirar_cima"]
const R_ESQ := ["mover_esquerda"]
const R_DIR := ["mover_direita"]

signal _fim_frame

var k: Node = null
var mundo: Node2D
var _ultimo := {}
var _procs := 0
var _fisicos := 0
var rest_y := 0.0
var R := {}


func _ready() -> void:
	process_priority = 1000
	process_physics_priority = 1000
	_correr.call_deferred()


func _physics_process(_dt: float) -> void:
	_fisicos += 1


func _process(_dt: float) -> void:
	_procs += 1
	if k != null and is_instance_valid(k):
		_ultimo = _snap()
	_fim_frame.emit()


func _snap() -> Dictionary:
	var corpo: AnimatedSprite2D = k._corpo
	return {
		"x": k.global_position.x, "y": k.global_position.y,
		"vx": k.velocity.x, "vy": k.velocity.y,
		"chao": k.is_on_floor(),
		"anim": String(corpo.animation), "fr": corpo.frame,
		"aterrar": k._aterrar_t, "dash": k._dash_restante,
		"rolar": k._rolar_restante, "inv": k._invulneravel,
		"borda": k._borda, "coy": k._mov.coyote_restante,
		"buf": k._mov.buffer_restante, "saltos": k._mov.saltos_dados,
		"squash": k._squash,
	}


func _premir(acoes: Array) -> void:
	for a in ACOES:
		var quer: bool = a in acoes
		if quer and not Input.is_action_pressed(a):
			Input.action_press(a)
		elif not quer and Input.is_action_pressed(a):
			Input.action_release(a)


## Um tick com as ações `acoes` premidas; devolve o estado no fim do frame.
## Prime-se no FIM do frame anterior (contexto `_process`), que é o que o
## input real faz: os eventos chegam antes da física e o `just_pressed` vale
## logo nesse tick. (Premir dentro do sinal `physics_frame` atrasava o
## `just_pressed` um tick -- provado por `e_latencia`.)
func paso(acoes: Array = []) -> Dictionary:
	_premir(acoes)
	await _fim_frame
	return _ultimo


func passos(n: int, acoes: Array = []) -> Array:
	var out: Array = []
	for _i in n:
		out.append(await paso(acoes))
	return out


func nova(x: float, habilidades: Array = ["dash", "pogo"]) -> void:
	_premir([])
	if k != null and is_instance_valid(k):
		k.queue_free()
		k = null
		await _fim_frame
	EstadoJogo.habilidades.assign(habilidades)
	k = KOLI.instantiate()
	k.usar_golden_set = true
	mundo.add_child(k)
	k.global_position = Vector2(x, CHAO_Y - 30.0)
	for _i in 45:
		await paso([])
	rest_y = k.global_position.y


func teleporta_altura(h: float) -> void:
	k.global_position.y = rest_y - h
	k.velocity = Vector2.ZERO
	k._mov.velocidade = Vector2.ZERO
	k.reset_physics_interpolation()


func _arena() -> void:
	mundo = Node2D.new()
	add_child(mundo)
	# chão longo, com rebordo à direita em x=2000 (teste de coyote)
	_bloco(Vector2(-6000, CHAO_Y), Vector2(2000, CHAO_Y + 200))
	# bloco para o teste de agarrar a borda: topo a 100 px acima do chão
	_bloco(Vector2(-4400, CHAO_Y - 100), Vector2(-3800, CHAO_Y))


func _bloco(a: Vector2, b: Vector2) -> void:
	var c := StaticBody2D.new()
	c.collision_layer = 1
	c.collision_mask = 0
	var f := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = (b - a).abs()
	f.shape = s
	c.position = (a + b) * 0.5
	c.add_child(f)
	mundo.add_child(c)


# ── utilitários de análise ───────────────────────────────────────────────

func _primeiro(tr: Array, pred: Callable, desde: int = 0) -> int:
	for i in range(desde, tr.size()):
		if pred.call(tr[i]):
			return i
	return -1


func _serie(tr: Array, chave: String) -> Array:
	var o: Array = []
	for s in tr:
		o.append(snappedf(float(s[chave]), 0.01) if s[chave] is float else s[chave])
	return o


func _runs(tr: Array, chave: String) -> Array:
	## Run-length das animações: [[nome, ticks], ...]
	var out: Array = []
	for s in tr:
		if out.is_empty() or out[-1][0] != s[chave]:
			out.append([s[chave], 1])
		else:
			out[-1][1] += 1
	return out


# ── experiências ─────────────────────────────────────────────────────────

func e_aceleracao() -> void:
	await nova(0.0)
	var ini: float = k.global_position.x
	var tr := await passos(50, R_DIR)
	var i0 := _primeiro(tr, func(s): return absf(s["vx"]) > 0.01)
	var i24 := _primeiro(tr, func(s): return absf(s["vx"]) >= 24.0)
	var i50 := _primeiro(tr, func(s): return absf(s["vx"]) >= 120.0)
	var i100 := _primeiro(tr, func(s): return absf(s["vx"]) >= 239.9)
	var irun := _primeiro(tr, func(s): return s["anim"] == "run")
	R["aceleracao"] = {
		"tick_1a_velocidade": i0, "tick_vx_24": i24, "tick_vx_metade": i50,
		"tick_vx_max": i100, "tick_anim_run": irun,
		"vx_max": tr[-1]["vx"],
		"distancia_ate_vx_max_px": tr[i100]["x"] - ini if i100 >= 0 else -1,
		"vx_por_tick": _serie(tr.slice(0, 20), "vx"),
		"anims": _runs(tr, "anim"),
	}


func e_desaceleracao() -> void:
	await nova(0.0)
	await passos(45, R_DIR)
	var x0: float = k.global_position.x
	var tr := await passos(40, [])
	var i0 := _primeiro(tr, func(s): return absf(s["vx"]) < 239.0)
	var i24 := _primeiro(tr, func(s): return absf(s["vx"]) < 24.0)
	var iz := _primeiro(tr, func(s): return absf(s["vx"]) < 0.01)
	R["desaceleracao"] = {
		"vx_ao_largar": 240.0, "tick_1a_reducao": i0, "tick_vx_lt_24": i24,
		"tick_vx_zero": iz,
		"derrapagem_px": tr[iz]["x"] - x0 if iz >= 0 else -1,
		"anims": _runs(tr, "anim"),
		"vx_por_tick": _serie(tr.slice(0, 16), "vx"),
	}


func e_viragem() -> void:
	await nova(0.0)
	await passos(45, R_DIR)
	var x0: float = k.global_position.x
	var tr := await passos(40, R_ESQ)
	var iz := _primeiro(tr, func(s): return s["vx"] <= 0.0)
	var i24 := _primeiro(tr, func(s): return s["vx"] <= -24.0)
	var imax := _primeiro(tr, func(s): return s["vx"] <= -239.9)
	R["viragem"] = {
		"tick_vx_cruza_zero": iz, "tick_vx_menos_24": i24, "tick_vx_menos_max": imax,
		"px_ate_cruzar_zero": tr[iz]["x"] - x0 if iz >= 0 else -1,
		"anims": _runs(tr, "anim"),
		"vx_por_tick": _serie(tr.slice(0, 14), "vx"),
	}


func _salto_com(n_premido: int) -> Dictionary:
	await nova(0.0)
	var tr: Array = []
	for i in 90:
		tr.append(await paso(["saltar"] if i < n_premido else []))
	var ymin := 1e9
	var iap := 0
	for i in tr.size():
		if tr[i]["y"] < ymin:
			ymin = tr[i]["y"]
			iap = i
	var i1 := _primeiro(tr, func(s): return s["vy"] < 0.0)
	var ipouso := _primeiro(tr, func(s): return s["chao"], iap)
	var vmax := 0.0
	for s in tr:
		vmax = maxf(vmax, s["vy"])
	return {
		"premido_ticks": n_premido, "altura_px": snappedf(rest_y - ymin, 0.1),
		"tick_1a_subida": i1, "tick_apex": iap,
		"tempo_no_ar_ticks": ipouso - i1 if ipouso >= 0 else -1,
		"vy_max_queda": snappedf(vmax, 0.1),
		"_tr": tr,
	}


func e_salto() -> void:
	var lista: Array = []
	var trace_cheio: Array = []
	var trace_corte: Array = []
	for n in [1, 2, 3, 4, 6, 8, 10, 15, 20, 90]:
		var r: Dictionary = await _salto_com(n)
		if n == 90:
			trace_cheio = _serie(r["_tr"].slice(0, 46), "vy")
			r["anims"] = _runs(r["_tr"], "anim")
		if n == 3:
			trace_corte = _serie(r["_tr"].slice(0, 14), "vy")
		r.erase("_tr")
		lista.append(r)
	R["salto"] = {"por_ticks_premido": lista, "vy_por_tick_cheio": trace_cheio,
		"vy_por_tick_toque_3": trace_corte}


func e_queda() -> void:
	await nova(0.0)
	teleporta_altura(900.0)
	var tr: Array = []
	var pouso := -1
	for i in 120:
		tr.append(await paso([]))
		if tr[-1]["chao"]:
			pouso = i
			break
	var vmax := 0.0
	var i750 := -1
	var iterm := -1
	for i in tr.size():
		vmax = maxf(vmax, tr[i]["vy"])
		if i750 < 0 and tr[i]["vy"] >= 750.0:
			i750 = i
	for i in tr.size():
		if iterm < 0 and tr[i]["vy"] >= vmax - 0.01:
			iterm = i
	var y0: float = rest_y - 900.0
	# distância percorrida nos últimos 0,6 s (36 ticks) antes do impacto
	var d06 := 0.0
	if pouso >= 36:
		d06 = tr[pouso]["y"] - tr[pouso - 36]["y"]
	R["queda"] = {
		"altura_px": 900, "ticks_ate_pouso": pouso, "vy_max": vmax,
		"tick_vy_750": i750, "tick_vy_max": iterm,
		"px_ultimos_0_6s": snappedf(d06, 0.1),
		"altura_do_viewport_px": 720, "zoom_camara": 1.4,
		"altura_visivel_mundo_px": 720.0 / 1.4,
		"y_inicial": y0,
	}


func e_ar() -> void:
	# controlo no ar: salto seguro (segurado), depois esquerda/direita
	await nova(0.0)
	var tr: Array = []
	for i in 30:
		tr.append(await paso(["saltar"] + (R_DIR if i >= 3 else [])))
	var iar := _primeiro(tr, func(s): return not s["chao"])
	var i100 := _primeiro(tr, func(s): return absf(s["vx"]) >= 239.9)
	var acel_ar := {
		"tick_1a_velocidade": _primeiro(tr, func(s): return absf(s["vx"]) > 0.01),
		"tick_vx_max_no_ar": i100, "tick_sai_do_chao": iar,
		"vx_por_tick": _serie(tr.slice(0, 20), "vx"),
	}
	# desaceleração no ar: corre, salta, larga a direção
	await nova(0.0)
	await passos(45, R_DIR)
	var tr2: Array = []
	for i in 40:
		tr2.append(await paso(["saltar"] + (R_DIR if i < 3 else [])))
	var ir := _primeiro(tr2, func(s): return absf(s["vx"]) < 239.0)
	var iz := _primeiro(tr2, func(s): return absf(s["vx"]) < 0.01)
	var desac_ar := {"tick_1a_reducao": ir, "tick_vx_zero": iz,
		"vx_por_tick": _serie(tr2.slice(0, 26), "vx")}
	# viragem no ar
	await nova(0.0)
	await passos(45, R_DIR)
	var tr3: Array = []
	for i in 40:
		tr3.append(await paso(["saltar"] + (R_DIR if i < 3 else R_ESQ)))
	var i0 := _primeiro(tr3, func(s): return s["vx"] <= 0.0, 3)
	var imx := _primeiro(tr3, func(s): return s["vx"] <= -239.9, 3)
	var vira_ar := {"tick_vx_cruza_zero_apos_3": i0 - 3 if i0 >= 0 else -1,
		"tick_vx_menos_max_apos_3": imx - 3 if imx >= 0 else -1,
		"vx_por_tick": _serie(tr3.slice(0, 20), "vx")}
	R["air_control"] = {"aceleracao": acel_ar, "desaceleracao": desac_ar, "viragem": vira_ar}


func e_coyote() -> void:
	# calibração: corre para o rebordo (x=2000), sem saltar
	var res: Dictionary = {}
	await nova(1650.0)
	var cal: Array = []
	var t_off := -1
	for i in 120:
		cal.append(await paso(R_DIR))
		if t_off < 0 and not cal[-1]["chao"]:
			t_off = i
			break
	var x_off: float = cal[-1]["x"]
	var sucesso: Array = []
	# repete com o salto premido k ticks depois do 1º tick que ela reporta "sem chão"
	for kk in range(0, 14):
		await nova(1650.0)
		var pulou := false
		for i in t_off + kk + 8:
			var ac: Array = R_DIR.duplicate()
			if i >= t_off + 1 + kk and i < t_off + 1 + kk + 4:
				ac.append("saltar")
			var s := await paso(ac)
			if i >= t_off + 1 + kk and s["vy"] < -100.0:
				pulou = true
		sucesso.append([kk, pulou])
	var max_ok := -1
	for p in sucesso:
		if p[1]:
			max_ok = p[0]
	# baseline: onde está o corpo em relação ao rebordo no tick em que perde o chão
	res = {"tick_perde_chao": t_off, "x_ao_perder_chao": x_off, "rebordo_x": 2000.0,
		"salto_apos_k_ticks": sucesso,
		"coyote_efetivo_ticks": max_ok + 1,
		"coyote_constante_s": Movimento.COYOTE,
		"coyote_constante_ticks": Movimento.COYOTE * 60.0}
	R["coyote"] = res


func e_buffer() -> void:
	# queda de 80 px; calibração acha o tick de pouso L
	await nova(-1500.0)
	teleporta_altura(80.0)
	var L := -1
	for i in 60:
		var s := await paso([])
		if s["chao"]:
			L = i
			break
	var sucesso: Array = []
	for kk in range(0, 16):
		await nova(-1500.0)
		teleporta_altura(80.0)
		var pulou := false
		var aterrou := -1
		for i in L + 10:
			var ac: Array = []
			if i == L - kk:
				ac = ["saltar"]
			var s := await paso(ac)
			if s["chao"] and aterrou < 0:
				aterrou = i
			if i > L and s["vy"] < -100.0:
				pulou = true
		sucesso.append([kk, pulou])
	var max_ok := -1
	for p in sucesso:
		if p[1]:
			max_ok = p[0]
	R["buffer"] = {"tick_pouso": L, "toque_de_1_tick_k_antes": sucesso,
		"buffer_efetivo_ticks": max_ok + 1,
		"buffer_constante_s": Movimento.BUFFER_SALTO,
		"buffer_constante_ticks": Movimento.BUFFER_SALTO * 60.0}


func _pouso(h: float, acoes: Array) -> Dictionary:
	await nova(0.0)
	teleporta_altura(h)
	var tr: Array = []
	var L := -1
	var vmax := 0.0
	for i in 120:
		tr.append(await paso([]))
		vmax = maxf(vmax, tr[-1]["vy"])
		if tr[-1]["chao"]:
			L = i
			break
	# vy relevante para o tier = vy antes do move_and_slide do tick de pouso
	var vy_pre: float = tr[L - 1]["vy"] if L >= 1 else 0.0
	var pos: Array = []
	for i in 40:
		pos.append(await paso(acoes))
	var land_ticks := 0
	var first_land := -1
	for i in pos.size():
		if pos[i]["anim"] == "land":
			land_ticks += 1
			if first_land < 0:
				first_land = i
	var i_run := _primeiro(pos, func(s): return s["anim"] == "run")
	var i_vx24 := _primeiro(pos, func(s): return absf(s["vx"]) >= 24.0)
	return {
		"altura_px": h, "vy_pre_pouso": snappedf(vy_pre, 0.1),
		"vy_max": snappedf(vmax, 0.1), "tier": Movimento.tier_aterragem(vy_pre),
		"ticks_anim_land": land_ticks, "tick_1o_land": first_land,
		"tick_anim_run_apos_pouso": i_run, "tick_vx_ge_24": i_vx24,
		"aterrar_t_inicial": snappedf(float(pos[0]["aterrar"]), 0.001),
		"squash_inicial": snappedf(float(pos[0]["squash"]), 0.01),
		"anims": _runs(pos, "anim"),
	}


func e_aterragem() -> void:
	var parado: Array = []
	for h in [30.0, 60.0, 120.0, 250.0, 500.0, 900.0]:
		parado.append(await _pouso(h, []))
	var a_correr: Array = []
	for h in [60.0, 250.0]:
		a_correr.append(await _pouso(h, R_DIR))
	R["aterragem"] = {"parado": parado, "a_correr_dir_premida": a_correr}


func e_dash() -> void:
	var r := {}
	# do repouso
	await nova(0.0)
	var x0: float = k.global_position.x
	var tr: Array = []
	for i in 40:
		tr.append(await paso(["dash"] if i == 0 else []))
	var n_dash := 0
	var n_inv := 0
	for s in tr:
		if s["dash"] > 0.0:
			n_dash += 1
		if s["inv"] > 0.0:
			n_inv += 1
	var i_ini := _primeiro(tr, func(s): return s["dash"] > 0.0)
	var i_v := _primeiro(tr, func(s): return absf(s["vx"]) > 400.0)
	var i_fim := _primeiro(tr, func(s): return s["dash"] <= 0.0, i_ini)
	var i_rep := _primeiro(tr, func(s): return absf(s["vx"]) < 0.01, i_fim)
	var vy_max_dash := 0.0
	for s in tr.slice(0, 12):
		vy_max_dash = maxf(vy_max_dash, absf(s["vy"]))
	r["repouso"] = {
		"ticks_estado_dash": n_dash, "ticks_invulneravel": n_inv,
		"tick_estado_dash_comeca": i_ini, "tick_1a_velocidade_dash": i_v,
		"distancia_durante_estado_px": snappedf(tr[i_fim]["x"] - tr[i_ini]["x"], 0.1),
		"distancia_ate_parar_px": snappedf(tr[i_rep]["x"] - x0, 0.1) if i_rep >= 0 else -1,
		"tick_vx_zero_apos_dash": i_rep,
		"vx_por_tick": _serie(tr.slice(0, 34), "vx"),
		"anims": _runs(tr, "anim"), "vy_max_abs_no_dash": vy_max_dash,
		"vx_dash_const": Koliani.VEL_DASH, "dur_dash_const_s": Koliani.DUR_DASH,
	}
	# recarga: carrega dash todos os ticks
	await nova(0.0)
	var arranques: Array = []
	var ant := false
	for i in 80:
		var s := await paso(["dash"] if i % 2 == 0 else [])
		var ativo: bool = s["dash"] > 0.0
		if ativo and not ant:
			arranques.append(i)
		ant = ativo
	r["recarga"] = {"ticks_de_arranque": arranques,
		"intervalo_ticks": arranques[1] - arranques[0] if arranques.size() > 1 else -1,
		"recarga_const_s": Koliani.RECARGA_DASH}
	# a correr: vx no fim do dash
	await nova(0.0)
	await passos(45, R_DIR)
	var tr2: Array = []
	for i in 30:
		tr2.append(await paso((["dash"] if i == 0 else []) + R_DIR))
	r["a_correr"] = {"vx_por_tick": _serie(tr2.slice(0, 20), "vx")}
	# no ar sem dash_aereo
	await nova(0.0)
	var tr3: Array = []
	for i in 30:
		var ac: Array = ["saltar"] if i < 12 else []
		if i == 15:
			ac.append("dash")
		tr3.append(await paso(ac))
	var dash_no_ar := false
	for s in tr3:
		if s["dash"] > 0.0:
			dash_no_ar = true
	r["no_ar_sem_dash_aereo_dispara"] = dash_no_ar
	R["dash"] = r


func e_roll() -> void:
	var r := {}
	await nova(0.0)
	var x0: float = k.global_position.x
	var tr: Array = []
	for i in 40:
		tr.append(await paso(["rolar"] if i == 0 else []))
	var n_roll := 0
	var n_inv := 0
	for s in tr:
		if s["rolar"] > 0.0:
			n_roll += 1
		if s["inv"] > 0.0:
			n_inv += 1
	var i_ini := _primeiro(tr, func(s): return s["rolar"] > 0.0)
	var i_fim := _primeiro(tr, func(s): return s["rolar"] <= 0.0, i_ini)
	var i_rep := _primeiro(tr, func(s): return absf(s["vx"]) < 0.01, i_fim)
	r["repouso"] = {
		"ticks_estado_rolar": n_roll, "ticks_invulneravel": n_inv,
		"tick_estado_rolar_comeca": i_ini,
		"distancia_durante_estado_px": snappedf(tr[i_fim]["x"] - tr[i_ini]["x"], 0.1),
		"distancia_ate_parar_px": snappedf(tr[i_rep]["x"] - x0, 0.1) if i_rep >= 0 else -1,
		"vx_por_tick": _serie(tr.slice(0, 40), "vx"),
		"anims": _runs(tr, "anim"),
		"vel_rolar_const": Koliani.VEL_ROLAR, "dur_rolar_const_s": Koliani.DUR_ROLAR,
		"recarga_const_s": Koliani.RECARGA_ROLAR,
	}
	# rolar ENCADEADO: direção premida + rolar todos os ticks, 240 ticks (4 s)
	await nova(0.0)
	await passos(45, R_DIR)
	var xa: float = k.global_position.x
	var tr2: Array = []
	var arranques: Array = []
	var ant := false
	for i in 240:
		var s := await paso(R_DIR + (["rolar"] if i % 2 == 0 else []))
		tr2.append(s)
		var ativo: bool = s["rolar"] > 0.0
		if ativo and not ant:
			arranques.append(i)
		ant = ativo
	var dist: float = tr2[-1]["x"] - xa
	# velocidade média entre o 1º e o último arranque
	var vmed := -1.0
	if arranques.size() >= 2:
		var ia: int = arranques[0]
		var ib: int = arranques[-1]
		vmed = (tr2[ib]["x"] - tr2[ia]["x"]) / (float(ib - ia) * TICK)
	# correr simples, mesmo tempo
	await nova(0.0)
	await passos(45, R_DIR)
	var xb: float = k.global_position.x
	var tr3 := await passos(240, R_DIR)
	r["encadeado"] = {
		"arranques_ticks": arranques,
		"intervalo_ticks": arranques[1] - arranques[0] if arranques.size() > 1 else -1,
		"velocidade_media_px_s": snappedf(vmed, 0.1),
		"distancia_4s_px": snappedf(dist, 0.1),
		"correr_4s_px": snappedf(tr3[-1]["x"] - xb, 0.1),
		"vel_correr_px_s": Movimento.VEL_CORRIDA,
		"i_frames_cobertura": "ver ticks_invulneravel (rolamento) x recarga",
	}
	R["roll"] = r


func _mantle(toque: int) -> Dictionary:
	await nova(-4500.0)
	var tr: Array = []
	var agarrou := -1
	for i in 120:
		var ac: Array = R_DIR.duplicate()
		if i >= 30 and i < 60:
			ac.append("saltar")
		tr.append(await paso(ac))
		if tr[-1]["borda"] and agarrou < 0:
			agarrou = i
			break
	var res := {"toque_ticks": toque, "agarrou_no_tick": agarrou}
	if agarrou < 0:
		return res
	res["anims_antes"] = _runs(tr, "anim")
	res["x_rel_face_ao_agarrar"] = snappedf(tr[-1]["x"] + 4400.0, 0.1)
	res["y_ao_agarrar"] = tr[-1]["y"]
	await passos(6, [])
	var tr2: Array = []
	for i in 60:
		var ac2: Array = ["mover_direita"]
		if i < toque:
			ac2.append("saltar")
		tr2.append(await paso(ac2))
	var ymin := 1e9
	for s in tr2:
		ymin = minf(ymin, s["y"])
	res["anims"] = _runs(tr2, "anim")
	res["y_min"] = snappedf(ymin, 0.1)
	res["x_final_rel_face"] = snappedf(tr2[-1]["x"] + 4400.0, 0.1)
	res["y_final"] = snappedf(tr2[-1]["y"], 0.1)
	res["acabou_em_cima"] = tr2[-1]["chao"] and tr2[-1]["y"] < rest_y - 90.0
	return res


func e_borda_mantle() -> void:
	var lista: Array = []
	for t in [1, 3, 8, 12, 16, 24]:
		lista.append(await _mantle(t))
	R["borda_mantle"] = {"topo_bloco_y": CHAO_Y - 100.0, "por_toque": lista}


func e_latencia() -> void:
	# ponto de premir: (a) no sinal physics_frame (dentro do tick) e (b) no fim do frame
	# anterior (process). Separa a latência do jogo da latência do harness.
	var r := {}
	await nova(0.0)
	var a: Array = []
	for i in 6:
		a.append(await paso(["saltar"] if i == 0 else []))
	r["salto_via_paso_1a_subida"] = _primeiro(a, func(s): return s["vy"] < 0.0)
	await nova(0.0)
	_premir(["saltar"])
	var b: Array = []
	for i in 6:
		await _fim_frame
		b.append(_ultimo)
		if i == 0:
			_premir([])
	r["salto_premido_no_process_1a_subida"] = _primeiro(b, func(s): return s["vy"] < 0.0)
	await nova(0.0)
	_premir(["dash"])
	var c: Array = []
	for i in 8:
		await _fim_frame
		c.append(_ultimo)
		if i == 0:
			_premir([])
	r["dash_estado_comeca"] = _primeiro(c, func(s): return s["dash"] > 0.0)
	r["dash_1a_velocidade"] = _primeiro(c, func(s): return absf(s["vx"]) > 400.0)
	await nova(0.0)
	_premir(["rolar"])
	var d: Array = []
	for i in 8:
		await _fim_frame
		d.append(_ultimo)
		if i == 0:
			_premir([])
	r["roll_estado_comeca"] = _primeiro(d, func(s): return s["rolar"] > 0.0)
	r["roll_1a_velocidade"] = _primeiro(d, func(s): return absf(s["vx"]) > 300.0)
	R["latencia_input"] = r


func e_animacoes_estaticas() -> void:
	await nova(0.0)
	var sf: SpriteFrames = k._corpo.sprite_frames
	var out := {}
	for n in sf.get_animation_names():
		var cnt := sf.get_frame_count(n)
		var fps := sf.get_animation_speed(n)
		var dur := 0.0
		for i in cnt:
			dur += sf.get_frame_duration(n, i)
		dur = dur / maxf(fps, 0.001)
		var tex := sf.get_frame_texture(n, 0) if cnt > 0 else null
		var caminho := ""
		if tex != null:
			caminho = tex.resource_path
			if caminho == "" and tex is AtlasTexture and (tex as AtlasTexture).atlas != null:
				caminho = (tex as AtlasTexture).atlas.resource_path
		var fich: Array = []
		for i in cnt:
			var t := sf.get_frame_texture(n, i)
			var c := t.resource_path if t != null else ""
			if c == "" and t is AtlasTexture and (t as AtlasTexture).atlas != null:
				c = (t as AtlasTexture).atlas.resource_path
			fich.append(c.get_file())
		out[String(n)] = {"ficheiros": fich, "frames": cnt, "fps": snappedf(fps, 0.01),
			"loop": sf.get_animation_loop(n),
			"duracao_ticks": snappedf(dur * 60.0, 0.1),
			"golden": caminho.contains("koliani_golden_set"),
			"origem_frame0": caminho.get_file()}
	R["animacoes_estaticas"] = out


func _correr() -> void:
	_arena()
	await _fim_frame
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else ProjectSettings.globalize_path(
		"res://work/f1_movimento.json")
	await e_animacoes_estaticas()
	await e_aceleracao()
	await e_desaceleracao()
	await e_viragem()
	await e_salto()
	await e_queda()
	await e_ar()
	await e_coyote()
	await e_buffer()
	await e_aterragem()
	await e_dash()
	await e_roll()
	await e_latencia()
	await e_borda_mantle()
	R["harness"] = {"frames_fisicos": _fisicos, "frames_process": _procs,
		"fps_fisica": Engine.physics_ticks_per_second,
		"constantes": {
			"GRAVIDADE": Movimento.GRAVIDADE, "GRAV_SUBIDA": Movimento.GRAVIDADE_SUBIDA,
			"GRAV_QUEDA": Movimento.GRAVIDADE_QUEDA, "VEL_MAX_QUEDA": Movimento.VEL_MAX_QUEDA,
			"VEL_CORRIDA": Movimento.VEL_CORRIDA, "ACEL_CHAO": Movimento.ACEL_CHAO,
			"DESACEL_CHAO": Movimento.DESACEL_CHAO, "VIRAGEM_CHAO": Movimento.VIRAGEM_CHAO,
			"ACEL_AR": Movimento.ACEL_AR, "DESACEL_AR": Movimento.DESACEL_AR,
			"VIRAGEM_AR": Movimento.VIRAGEM_AR, "FORCA_SALTO": Movimento.FORCA_SALTO,
			"CORTE_SALTO": Movimento.CORTE_SALTO}}
	var f := FileAccess.open(saida, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(R, "  "))
		f.close()
	print("bancada F1 -> ", saida)
	get_tree().quit(0)
