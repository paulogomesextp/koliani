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

## Alvo mínimo para o pisão/pogo: o `koliani.gd` só exige o grupo "inimigos"
## e o método `receber_dano`.
class Alvo extends Node2D:
	var golpes := 0
	func receber_dano(_d = 0, _e = 0.0, _c = false) -> void:
		golpes += 1


signal _fim_frame

var k: Node = null
var mundo: Node2D
var _ultimo := {}
var _procs := 0
var _fisicos := 0
var rest_y := 0.0
var R := {}
var _reg_env := false


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


func nova(x: float, habilidades: Array = ["dash", "pogo"], y: float = CHAO_Y - 30.0) -> void:
	_premir([])
	if k != null and is_instance_valid(k):
		k.queue_free()
		k = null
		await _fim_frame
	EstadoJogo.habilidades.assign(habilidades)
	k = KOLI.instantiate()
	k.usar_golden_set = true
	mundo.add_child(k)
	k.global_position = Vector2(x, y)
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


## MANTLE (passagem 2): salta encostada a um bloco cujo topo fica `lip` px acima
## do chão e diz o que aconteceu. O mantle é automático (a segurar contra a parede).
func _mantle(lip: float) -> Dictionary:
	await nova(-3100.0)
	# bloco de teste com o topo `lip` acima do chão (o de 100 px do arena serve
	# para 100; para outras alturas cria-se um bloco próprio ao lado)
	var bloco := _bloco_devolve(Vector2(-3000, CHAO_Y - lip), Vector2(-2400, CHAO_Y))
	var tr: Array = []
	var t_mantle := -1
	for i in 200:
		var ac: Array = R_DIR.duplicate()
		if i >= 30 and i < 60:
			ac.append("saltar")
		tr.append(await paso(ac))
		if tr[-1]["borda"] and t_mantle < 0:
			t_mantle = i
		if t_mantle >= 0 and tr[-1]["chao"] and i > t_mantle + 3:
			break
	bloco.queue_free()
	var last: Dictionary = tr[-1]
	var em_cima: bool = last["chao"] and last["y"] < rest_y - lip + 8.0
	var ticks_mantle := 0
	var y_max := 1e9
	for s in tr:
		if s["borda"]:
			ticks_mantle += 1
		y_max = minf(y_max, s["y"])
	var re_agarrou := 0
	var ant := false
	for s in tr:
		if s["borda"] and not ant:
			re_agarrou += 1
		ant = s["borda"]
	return {"rebordo_acima_do_chao": lip, "mantle_iniciou_no_tick": t_mantle,
		"ticks_mantle": ticks_mantle, "agarres": re_agarrou, "acabou_em_cima": em_cima,
		"x_final_rel_face": snappedf(last["x"] + 3000.0, 0.1),
		"y_min": snappedf(y_max, 0.1), "anims_mantle": _runs(tr, "anim")}


func e_borda_mantle() -> void:
	var lista: Array = []
	for lip in [60.0, 100.0, 120.0, 140.0, 150.0, 155.0, 158.0, 160.0, 170.0, 200.0]:
		lista.append(await _mantle(lip))
	R["borda_mantle"] = {"por_altura": lista}


## WALL-JUMP: parede alta (sem rebordo à vista). Mede o salto de parede isolado
## e uma cadeia a subir a parede a segurar contra ela e a saltar em cada toque.
func _walljump(hold: int, com_skill: bool = true) -> Dictionary:
	await nova(-1990.0, ["dash", "pogo", "escalar_paredes"] if com_skill else ["dash", "pogo"])
	var parede := _bloco_devolve(Vector2(-1960, CHAO_Y - 900), Vector2(-1500, CHAO_Y))
	var tr: Array = []
	var presses: Array = []
	var cd := 0
	var seg := 0
	for i in 420:
		var ac: Array = R_DIR.duplicate()
		if i >= 20 and i < 50:
			ac.append("saltar")
		elif seg > 0:
			ac.append("saltar")
			seg -= 1
		elif i >= 50 and cd <= 0 and k.is_on_wall_only() and k.velocity.y > -140.0:
			ac.append("saltar")
			seg = hold - 1
			cd = 20
			presses.append(i)
		cd -= 1
		tr.append(await paso(ac))
	parede.queue_free()
	var y_min := 1e9
	for s in tr:
		y_min = minf(y_min, s["y"])
	var subida_1o := 0.0
	if presses.size() > 0:
		var a: int = presses[0]
		var b: int = presses[1] if presses.size() > 1 else tr.size()
		var ymin1 := 1e9
		for j in range(a, b):
			ymin1 = minf(ymin1, tr[j]["y"])
		subida_1o = tr[a]["y"] - ymin1
	# chutes REAIS: a bancada carrega no botao sempre que toca na parede, por isso
	# `presses` mede tentativas; o chute e' vx <= -0,9*WALLJUMP.x (parede a direita)
	var chutes := 0
	var ant_k := false
	for s in tr:
		var kick: bool = float(s["vx"]) <= -Koliani.WALLJUMP.x * 0.9
		if kick and not ant_k:
			chutes += 1
		ant_k = kick
	return {"botao_premido_ticks": hold, "tentativas": presses.size(), "saltos_de_parede": chutes,
		"subida_do_1o_px": snappedf(subida_1o, 0.1),
		"altura_maxima_da_cadeia_px": snappedf(rest_y - y_min, 0.1)}


func e_walljump() -> void:
	R["walljump"] = {"walljump_const": Koliani.WALLJUMP, "toque_1_tick": await _walljump(1),
		"segurado_14_ticks": await _walljump(14), "segurado_30_ticks": await _walljump(30),
		"sem_skill": await _walljump(1, false)}


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


func e_roll_spam() -> void:
	var r := {}
	for modo in ["parada", "lancada"]:
		await nova(0.0)
		if modo == "lancada":
			await passos(45, R_DIR)
		var x0: float = k.global_position.x
		var tr_run := await passos(180, R_DIR)
		var d_run: float = tr_run[-1]["x"] - x0
		await nova(0.0)
		if modo == "lancada":
			await passos(45, R_DIR)
		x0 = k.global_position.x
		var n_rolls := 0
		var ant := false
		var tr_roll: Array = []
		for i in 180:
			var s := await paso(R_DIR + (["rolar"] if i % 2 == 0 else []))
			tr_roll.append(s)
			var ativo: bool = s["rolar"] > 0.0
			if ativo and not ant:
				n_rolls += 1
			ant = ativo
		var d_roll: float = tr_roll[-1]["x"] - x0
		r[modo] = {"correr_3s_px": snappedf(d_run, 0.1), "roll_spam_3s_px": snappedf(d_roll, 0.1),
			"rolls": n_rolls, "razao_roll_sobre_correr": snappedf(d_roll / d_run, 0.001)}
	R["roll_spam"] = r


func e_pogo() -> void:
	# pisão num alvo parado: mede a altura do ressalto e o encadeamento
	await nova(0.0)
	var alvo := Alvo.new()
	alvo.add_to_group("inimigos")
	alvo.global_position = Vector2(k.global_position.x, CHAO_Y - 30.0)
	mundo.add_child(alvo)
	teleporta_altura(160.0)
	var tr: Array = []
	var toques: Array = []
	var golpes_ant := 0
	for i in 200:
		tr.append(await paso([]))
		if alvo.golpes != golpes_ant:
			golpes_ant = alvo.golpes
			toques.append(i)
	var apexes: Array = []
	# altura de cada ressalto: do ponto do toque ao mínimo de y antes do toque seguinte
	for j in toques.size():
		var a: int = toques[j]
		var b: int = toques[j + 1] if j + 1 < toques.size() else tr.size()
		var ymin := 1e9
		for i in range(a, b):
			ymin = minf(ymin, tr[i]["y"])
		apexes.append(snappedf(tr[a]["y"] - ymin, 0.1))
	R["pogo"] = {"toques_ticks": toques, "altura_ressalto_px": apexes,
		"stomp_ressalto_const": Koliani.STOMP_RESSALTO,
		"intervalo_toques_ticks": toques[1] - toques[0] if toques.size() > 1 else -1}
	alvo.queue_free()


func e_camera_queda() -> void:
	await nova(0.0)
	var cam: Camera2D = k.get_node("Camera2D")
	# o headless tem um viewport maior que 1280x720 e o zoom automático sobe: fixa-se o de 16:9
	cam.zoom = Vector2(1.4, 1.4)
	var meia_alt: float = 360.0 / cam.zoom.y
	teleporta_altura(900.0)
	# como se tivesse saido de uma borda a 900 px do chao: o "ultimo chao estavel" da camara e' o ponto de partida
	cam.set("_chao_y", k.global_position.y)
	var tr: Array = []
	var pouso := -1
	var vis := -1
	var max_off := 0.0
	var off_max := 0.0
	var cy_ini := 0.0
	for i in 140:
		var s := await paso([])
		tr.append(s)
		var cy: float = cam.get_screen_center_position().y
		if i == 0:
			cy_ini = cy
		if vis < 0 and CHAO_Y <= cy + meia_alt:
			vis = i
		max_off = maxf(max_off, (s["y"] + 24.0) - (cy + meia_alt))
		off_max = maxf(off_max, cam.offset.y)
		if s["chao"]:
			pouso = i
			break
	R["camera_queda"] = {"altura_px": 900, "meia_altura_mundo_px": meia_alt,
		"tick_chao_visivel": vis, "tick_pouso": pouso,
		"chao_visivel_antes_do_impacto_s": snappedf(float(pouso - vis) / 60.0, 0.01) if vis >= 0 else -1.0,
		"pes_fora_do_ecra_px_max": snappedf(max_off, 0.1),
		"look_ahead_y_max_px": snappedf(off_max, 0.1),
		"camera_y_inicial": cy_ini, "zoom": cam.zoom.y,
		"suavizacao": cam.position_smoothing_enabled}


## Look-ahead vertical em saltos e quedas curtas: nao pode disparar (so' a
## velocidade proxima da terminal o leva ao maximo) e tem de voltar a ~0.
func _off_camera(acoes_salto: int, altura: float) -> Dictionary:
	await nova(0.0)
	var cam: Camera2D = k.get_node("Camera2D")
	cam.zoom = Vector2(1.4, 1.4)
	if altura > 0.0:
		teleporta_altura(altura)
		cam.set("_chao_y", k.global_position.y)
	var mx := -1e9
	var mn := 1e9
	var fim := 0.0
	for i in 200:
		var ac: Array = []
		if i < acoes_salto:
			ac.append("saltar")
		await paso(ac)
		mx = maxf(mx, cam.offset.y)
		mn = minf(mn, cam.offset.y)
		if i > 30 and k.is_on_floor():
			for j in 90:
				await paso([])
			fim = cam.offset.y
			break
	return {"offset_max_px": snappedf(mx, 0.1), "offset_min_px": snappedf(mn, 0.1),
		"offset_depois_de_pousar_1_5s_px": snappedf(fim, 0.1)}


func e_camera_contexto() -> void:
	R["camera_contexto"] = {"salto_normal": await _off_camera(40, 0.0),
		"salto_curto": await _off_camera(4, 0.0),
		"queda_curta_100px": await _off_camera(0, 100.0),
		"queda_media_250px": await _off_camera(0, 250.0)}


func _tenta_vao(yA: float, dy: float, vao: float, off: float, duplo: bool) -> bool:
	var xa0 := -2800.0
	var larg := 220.0
	var pa := _bloco_devolve(Vector2(xa0, yA), Vector2(xa0 + larg, yA + 24.0))
	var xb0 := xa0 + larg + vao
	var pb := _bloco_devolve(Vector2(xb0, yA - dy), Vector2(xb0 + 700.0, yA - dy + 24.0))
	var hab: Array = ["dash", "pogo"] + (["salto_duplo"] if duplo else [])
	await nova(xa0 + 20.0, hab, yA - 30.0)
	var ponta := xa0 + larg
	var saltou := false
	var ok := false
	var t_apex := -1
	for i in 260:
		var ac: Array = R_DIR.duplicate()
		if not saltou and k.global_position.x >= ponta - off:
			saltou = true
		if saltou:
			if not duplo or t_apex < 0:
				if k.velocity.y <= 0.0:
					ac.append("saltar")
				elif duplo:
					t_apex = 0
			else:
				# duplo: 1 tick solto e depois volta a premir enquanto sobe
				if t_apex >= 1 and k.velocity.y <= 0.0 + (0.0 if t_apex > 1 else 1e9):
					ac.append("saltar")
				t_apex += 1
		var s := await paso(ac)
		if saltou and s["chao"] and s["x"] > ponta:
			ok = absf(s["y"] - (yA - dy - 30.0)) < 30.0
			break
		if s["y"] > yA + 200.0:
			break
	pa.queue_free()
	pb.queue_free()
	return ok


func _bloco_devolve(a: Vector2, b: Vector2) -> Node:
	_bloco(a, b)
	return mundo.get_child(mundo.get_child_count() - 1)


func _alguma(yA: float, dy: float, vao: float, duplo: bool) -> bool:
	for off in [26.0, 60.0, 100.0, 140.0]:
		if await _tenta_vao(yA, dy, vao, off, duplo):
			return true
	return false


## vão máximo (passos de 10 px) por subida; pesquisa binária com 4 pontos de salto
func _vao_max(yA: float, dy: float, duplo: bool) -> float:
	if not await _alguma(yA, dy, 0.0, duplo):
		return -1.0
	var lo := 0.0
	var hi := 640.0
	while hi - lo > 10.0:
		var mid := snappedf((lo + hi) * 0.5, 10.0)
		if mid <= lo:
			mid = lo + 10.0
		if await _alguma(yA, dy, mid, duplo):
			lo = mid
		else:
			hi = mid
	return lo


func e_envolvente() -> void:
	var yA := 300.0
	var simples := {}
	var duplo := {}
	var dys_s := [-140.0, -60.0, 0.0, 64.0, 100.0, 140.0] if _reg_env else [-300.0, -240.0, -140.0, -60.0, 0.0, 40.0, 64.0, 80.0, 100.0, 120.0, 140.0, 160.0, 180.0, 200.0]
	var dys_d := [-60.0, 0.0, 100.0, 180.0] if _reg_env else [-300.0, -240.0, -140.0, -60.0, 0.0, 64.0, 100.0, 140.0, 180.0, 200.0, 220.0, 260.0]
	for dy in dys_s:
		simples["dy_%d" % int(dy)] = await _vao_max(yA, dy, false)
	for dy in dys_d:
		duplo["dy_%d" % int(dy)] = await _vao_max(yA, dy, true)
	R["envolvente_salto"] = {"simples": simples, "duplo": duplo}


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


## Limites da Passagem 1 (aprovados pelo GM, 25 set 2026). Cada linha é um
## critério de PASS; a bancada é a única fonte dos números.
func _regressao() -> Array:
	var falhas: Array = []
	var chk := func(ok: bool, msg: String) -> void:
		if not ok:
			falhas.append(msg)
	var salto: Array = R["salto"]["por_ticks_premido"]
	var alt: float = salto[-1]["altura_px"]
	chk.call(alt >= 125.0 and alt <= 135.0, "altura do salto %.1f fora de 125-135" % alt)
	# corte UM só: depois de cortado, cada tick só muda pela gravidade (< 40 px/s)
	var vc: Array = R["salto"]["vy_por_tick_toque_3"]
	for i in range(4, 9):
		chk.call(absf(float(vc[i]) - float(vc[i - 1])) < 40.0,
			"jump cut multiplicado por tick (vy %.1f -> %.1f no tick %d)" % [vc[i - 1], vc[i], i])
	var vcheio: Array = R["salto"]["vy_por_tick_cheio"]
	var apex := 0
	for v in vcheio:
		if absf(float(v)) < 60.0 and float(v) != 0.0:
			apex += 1
	chk.call(apex >= 6 and apex <= 14, "janela de apex de %d ticks fora de 6-14" % apex)
	chk.call(float(R["queda"]["vy_max"]) <= 755.0, "velocidade terminal %.0f > 750" % R["queda"]["vy_max"])
	chk.call(int(R["coyote"]["coyote_efetivo_ticks"]) == 6, "coyote %d != 6" % R["coyote"]["coyote_efetivo_ticks"])
	chk.call(int(R["buffer"]["buffer_efetivo_ticks"]) >= 7, "buffer %d < 7" % R["buffer"]["buffer_efetivo_ticks"])
	var ac: int = int(R["air_control"]["aceleracao"]["tick_vx_max_no_ar"]) - 3
	var pa: int = int(R["air_control"]["desaceleracao"]["tick_vx_zero"]) - 3
	var iv: int = int(R["air_control"]["viragem"]["tick_vx_menos_max_apos_3"])
	chk.call(ac >= 8 and ac <= 10, "acelerar no ar %d ticks fora de 8-10" % ac)
	chk.call(pa >= 10 and pa <= 12, "parar no ar %d ticks fora de 10-12" % pa)
	chk.call(iv >= 10 and iv <= 12, "inverter no ar %d ticks fora de 10-12" % iv)
	var dr: Dictionary = R["dash"]["repouso"]
	chk.call(int(dr["tick_1a_velocidade_dash"]) == 0, "dash sem resposta no mesmo tick")
	var n620 := 0
	for v in dr["vx_por_tick"]:
		if float(v) == Koliani.VEL_DASH:
			n620 += 1
	chk.call(n620 == 10, "burst do dash com %d ticks (esperado 10)" % n620)
	chk.call(float(dr["distancia_ate_parar_px"]) <= 130.0, "dash desliza: %.1f px ate parar" % dr["distancia_ate_parar_px"])
	var voltou := 99
	var vxc: Array = R["dash"]["a_correr"]["vx_por_tick"]
	for i in range(3, vxc.size()):
		if float(vxc[i]) <= 241.0:
			voltou = i
			break
	chk.call(voltou <= 12, "dash a correr so volta a 240 ao tick %d" % voltou)
	chk.call(int(R["latencia_input"]["roll_1a_velocidade"]) == 0, "roll sem resposta no mesmo tick")
	chk.call(Koliani.VEL_ROLAR > Movimento.VEL_CORRIDA, "o roll deixou de ser mais rapido que correr")
	for m in ["parada", "lancada"]:
		var rz: float = R["roll_spam"][m]["razao_roll_sobre_correr"]
		chk.call(rz <= 1.0, "roll spam (%s) transporta mais que correr: razao %.3f" % [m, rz])
		chk.call(rz >= 0.85, "roll spam (%s) punitivo: razao %.3f" % [m, rz])
	var pg: float = R["pogo"]["altura_ressalto_px"][1]
	chk.call(pg >= 45.0 and pg <= 65.0, "pogo %.1f px fora de 45-65" % pg)
	chk.call(pg / alt >= 0.35 and pg / alt <= 0.5, "pogo/salto %.2f fora de 0,35-0,5" % (pg / alt))
	chk.call(float(R["camera_queda"]["chao_visivel_antes_do_impacto_s"]) >= 0.6,
		"chao so visivel %.2f s antes do impacto (barra 0,6)" % R["camera_queda"]["chao_visivel_antes_do_impacto_s"])
	var cc: Dictionary = R["camera_contexto"]
	for kk in ["salto_normal", "salto_curto", "queda_curta_100px"]:
		chk.call(float(cc[kk]["offset_max_px"]) <= 75.0, "camera: %s com look-ahead %.0f px (queda so' em quedas rapidas)" % [kk, cc[kk]["offset_max_px"]])
	for kk in cc:
		chk.call(absf(float(cc[kk]["offset_depois_de_pousar_1_5s_px"])) <= 3.0, "camera: %s nao regressou ao enquadramento (%.1f px)" % [kk, cc[kk]["offset_depois_de_pousar_1_5s_px"]])
	# parede de 900 px sem escalar_paredes nao se escala: so' a altura do salto
	chk.call(float(R["walljump"]["sem_skill"]["altura_maxima_da_cadeia_px"]) <= 140.0,
		"parede de 900 px escalada sem a habilidade (%.1f px)" % R["walljump"]["sem_skill"]["altura_maxima_da_cadeia_px"])
	# ANIMAÇÃO (passagem 2): brake segue a física, turn sem flicker, land curto a correr
	var brake_ticks := 0
	for r in R["desaceleracao"]["anims"]:
		if r[0] == "run_brake":
			brake_ticks += int(r[1])
	chk.call(brake_ticks >= 4 and brake_ticks <= 9, "run_brake dura %d ticks (fisica pára em ~6)" % brake_ticks)
	chk.call(R["desaceleracao"]["anims"][0][0] == "run_brake", "o brake deveria começar ao largar a direção")
	var turn_ticks := 0
	for r in R["viragem"]["anims"]:
		chk.call(r[0] != "run_brake", "flicker de run_brake na viragem")
		if r[0] == "turn":
			turn_ticks += int(r[1])
	chk.call(turn_ticks >= 4 and turn_ticks <= 10, "turn dura %d ticks" % turn_ticks)
	for r in R["aterragem"]["a_correr_dir_premida"]:
		var lt: int = int(r["ticks_anim_land"])
		chk.call(lt >= 4 and lt <= 6, "land a correr dura %d ticks (esperado 4-6)" % lt)
	for r in R["aterragem"]["parado"]:
		chk.call(int(r["ticks_anim_land"]) >= 4, "land parado dura menos de 4 ticks")
	chk.call(Movimento.tier_aterragem(float(R["salto"]["por_ticks_premido"][-1]["vy_max_queda"])) == 1,
		"um salto normal aterra com impacto acima de leve")
	# WALL-JUMP (decisao GM): exige `escalar_paredes`
	chk.call(int(R["walljump"]["sem_skill"]["saltos_de_parede"]) == 0,
		"wall-jump executou SEM a habilidade escalar_paredes")
	chk.call(int(R["walljump"]["toque_1_tick"]["saltos_de_parede"]) >= 1,
		"wall-jump nao executa COM escalar_paredes")
	# MANTLE (passagem 2): 9 ticks, sem re-agarrar, alcance limitado
	var mant := {}
	for m in R["borda_mantle"]["por_altura"]:
		mant[int(m["rebordo_acima_do_chao"])] = m
	chk.call(bool(mant[150]["acabou_em_cima"]) and bool(mant[140]["acabou_em_cima"]),
		"mantle nao completa um rebordo a 140-150 px")
	var tm: int = int(mant[150]["ticks_mantle"])
	chk.call(tm >= 8 and tm <= 10, "mantle dura %d ticks (esperado 9)" % tm)
	for h in mant:
		chk.call(int(mant[h]["agarres"]) <= 1, "mantle a %d px re-agarrou (%d agarres)" % [h, mant[h]["agarres"]])
	chk.call(not bool(mant[170]["acabou_em_cima"]) and not bool(mant[200]["acabou_em_cima"]),
		"salto+mantle sobe a 170-200 px (alcance excessivo)")
	# envolvente nunca pode ENCOLHER face ao baseline da passagem 1 (tolerancia 10 px)
	var ref_f := FileAccess.open("res://docs/qa/f1_movimento/f1_envolvente_antes_depois.json", FileAccess.READ)
	if ref_f:
		var ref: Dictionary = JSON.parse_string(ref_f.get_as_text())["passagem2"]
		for tier in ["simples", "duplo"]:
			for k in R["envolvente_salto"][tier]:
				if ref[tier].has(k) and float(ref[tier][k]) >= 0.0:
					var atual: float = R["envolvente_salto"][tier][k]
					chk.call(atual >= float(ref[tier][k]) - 10.0,
						"envolvente %s %s encolheu: %.0f < %.0f" % [tier, k, atual, ref[tier][k]])
	return falhas


func _quer(nome: String, filtro: PackedStringArray) -> bool:
	return filtro.is_empty() or nome in filtro


func _correr() -> void:
	_arena()
	await _fim_frame
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else ProjectSettings.globalize_path(
		"res://work/f1_movimento.json")
	var filtro: PackedStringArray = PackedStringArray()
	var regressao := args.size() > 1 and args[1] == "regressao"
	if regressao:
		_reg_env = true
		filtro = PackedStringArray(["salto", "queda", "ar", "coyote", "buffer", "dash",
			"roll", "latencia", "roll_spam", "pogo", "camera", "camera_contexto", "envolvente", "mantle", "walljump", "desaceleracao", "viragem",
			"aterragem"])
	elif args.size() > 1 and args[1] != "":
		filtro = args[1].split(",")
	var todas := {
		"animacoes": e_animacoes_estaticas, "aceleracao": e_aceleracao,
		"desaceleracao": e_desaceleracao, "viragem": e_viragem, "salto": e_salto,
		"queda": e_queda, "ar": e_ar, "coyote": e_coyote, "buffer": e_buffer,
		"aterragem": e_aterragem, "dash": e_dash, "roll": e_roll,
		"latencia": e_latencia, "roll_spam": e_roll_spam, "pogo": e_pogo,
		"camera": e_camera_queda, "camera_contexto": e_camera_contexto, "envolvente": e_envolvente, "mantle": e_borda_mantle, "walljump": e_walljump,
	}
	for nome in todas:
		if _quer(nome, filtro):
			await (todas[nome] as Callable).call()
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
	if regressao:
		var falhas := _regressao()
		for f2 in falhas:
			printerr("REGRESSAO F1 FALHOU: ", f2)
		print("REGRESSAO F1: %d falha(s)" % falhas.size())
		get_tree().quit(1 if not falhas.is_empty() else 0)
		return
	get_tree().quit(0)
