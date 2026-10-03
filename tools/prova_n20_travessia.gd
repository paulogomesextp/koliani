extends SceneTree
## PROVA DE TRAVESSIA DETERMINISTA do N20 ("Nucleo da Fornalha"): um piloto de
## "jogo perfeito" com a Koliani REAL e os relogios REAIS dos pistoes, jatos,
## plataformas e valvulas. Em cada instante olha para a frente (a velocidade de
## corrida) e SO' avanca se nenhum perigo ativo lhe apanhar o trajecto; toca nas
## valvulas onde o desenho as pede. Prova que existe um caminho FISICO sem
## dano; a dificuldade humana fica para o playtest.
##
## A Koliani fica invulneravel (isola a geometria do dano) mas CONTAM-SE os
## "toques" (frames dentro de uma zona ativa = dano que teria levado) e as
## "quedas" (fundo do fosso). Um percurso limpo tem 0 toques.
##
## Uso (sempre isolado, para nao tocar no save real):
##   python tools/godot_isolado.py -- --headless --fixed-fps 60 --path . \
##       --script res://tools/prova_n20_travessia.gd -- [tmax_s]

const CENA := "res://scenes/levels/O_Abismo.tscn"
const A_DIR := "mover_direita"
const A_SALTO := "saltar"
const VEL := 240.0
const HORIZONTE := 1.5       # s olhados a' frente
const MARGEM := 0.3          # s de folga antes/depois de cada pancada

## Plano: {"v": valvula a tocar, "x": onde ir, "ate": x a partir do qual ja' nao ha' perigo}
var plano: Array = [
	{"x": 1040.0},                       # A: revisao -> CP1
	{"x": 1495.0},                       # B: lava que sobe (pedras)
	{"x": 1915.0},                       # B: carrinho sobre lava
	{"x": 2135.0},                       # CP C0
	{"v": "ValvulaC", "x": 2400.0},
	{"x": 3195.0},                       # C: fosso de ritmadas -> CP3
	{"v": "ValvulaD", "x": 3715.0},
	{"x": 4385.0},                       # D: maquinas -> entrada da arena (CheckBoss)
]

var k: Node2D
var raiz: Node
var t := 0.0
var passo := 0
var toques := 0
var quedas := 0
var _segura_salto := 0.0
var _duplo_usado := false
var _ultimo_ok := Vector2.ZERO
var _tmax := 300.0
var _pistoes: Array = []
var _jatos: Array = []
var _espera := 0.0
var _y_ant := 0.0
var _tocou_neste := {}
var _modo_segredos := false
var _modo_fossos := false
var _fi := 0
var _ff := 0
var _ft := 0.0
var _fok := 0
var _si := 0
var _sf := 0
var _sw := 0.0
var _sdone := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_tmax = float(args[0])
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		es.indice_nivel = int(es.NIVEIS.find(CENA))
		es.checkpoint = Vector2.ZERO
	# o tempo dos perigos e' o da FISICA (o headless corre ~14x mais depressa
	# que a parede): relogio manual desde 0
	RelogioFornalha.manual = 0.0
	change_scene_to_file(CENA)
	await process_frame
	await process_frame
	raiz = current_scene
	k = get_first_node_in_group("koliani")
	if k == null:
		print("PROVA N20 FALHOU: sem Koliani")
		quit(2)
		return
	for n in raiz.get_children():
		var sc: Script = n.get_script()
		var sp := sc.resource_path if sc else ""
		if sp.ends_with("pistao_fornalha.gd"):
			_pistoes.append(n)
		elif sp.ends_with("jato_fornalha.gd"):
			_jatos.append(n)
	_y_ant = k.global_position.y
	# fase inicial: espera N s antes de arrancar, para provar que o percurso nao
	# depende do instante de chegada aos perigos (o ritmo corre desde o arranque)
	_espera = float(OS.get_environment("N20_ESPERA_INICIAL")) if OS.get_environment("N20_ESPERA_INICIAL") != "" else 0.0
	_modo_segredos = OS.get_environment("N20_SEGREDOS") != ""
	_modo_fossos = OS.get_environment("N20_FOSSOS") != ""
	print("PROVA N20: inicio em %s | %d pistoes, %d jatos" % [str(k.global_position), _pistoes.size(), _jatos.size()])


func _prem(a: String, on: bool) -> void:
	if on:
		Input.action_press(a)
	else:
		Input.action_release(a)


func _para() -> void:
	_prem(A_DIR, false)
	_prem("mover_esquerda", false)
	_prem(A_SALTO, false)


# ------------------------------------------------------------ perigos
func _perigo_pistao(h: Node2D, s: float) -> bool:
	if h.get("pausado") == true:
		return false
	return bool(h.call("perigoso_em", float(h.call("_tempo")) + s))


func _perigo_jato(h: Node2D, s: float) -> bool:
	if h.get("pausado") == true:
		return false
	var agora: float = float(h.call("_ahora")) + float(h.get("_desloc"))
	return int(h.call("estado_em", agora + s)) == 2


func _lane(h: Node2D, eh_pistao: bool) -> float:
	if eh_pistao:
		return float(h.get("largura")) * 0.86 * 0.5 + 14.0
	return 23.0 + 14.0


func _toca_zona_agora(_p: Vector2) -> bool:
	# dano REAL: zona ativa a sobrepor-se ao corpo da Koliani (o que o jogo usa)
	for h in _pistoes:
		if h.get("ativa") == true and h.overlaps_body(k):
			return true
	for h in _jatos:
		if h.get("ativa") == true and h.overlaps_body(k):
			return true
	return false


## Ha' perigo no trajecto? So' se avalia a PROXIMA corrida de pistas (pistas
## coladas, sem ilha entre elas): parar dentro de uma pista era pior do que
## entrar, e uma ilha a' frente deixa-nos esperar la'.
func _bloqueado(p: Vector2, alvo_x: float) -> bool:
	var pistas: Array = []
	for h in _pistoes:
		pistas.append([h.global_position.x - _lane(h, true), h.global_position.x + _lane(h, true), h, true])
	for h in _jatos:
		pistas.append([h.global_position.x - _lane(h, false), h.global_position.x + _lane(h, false), h, false])
	pistas.sort_custom(func(a, b): return a[0] < b[0])
	var fim_ant := -1.0e9
	# a partir do repouso a Koliani demora ~0,25 s a apanhar a velocidade de corrida
	var vx: float = absf(float(k.get("velocity").x))
	var atraso := 0.25 * (1.0 - clampf(vx / VEL, 0.0, 1.0))
	for pi in pistas:
		var x_in: float = pi[0]
		var x_out: float = pi[1]
		if x_out <= p.x + 2.0 or x_in > alvo_x + 20.0:
			continue
		if fim_ant > -1.0e8 and x_in - fim_ant > 60.0:
			break                       # ha' ilha entre as pistas: a corrida acaba aqui
		fim_ant = x_out
		if p.x > x_in + 2.0:
			continue                    # ja' dentro: comprometido
		var s_in: float = maxf(0.0, (x_in - p.x) / VEL) + atraso
		var s_out: float = (x_out - p.x) / VEL + atraso
		var s := s_in - MARGEM
		while s <= s_out + MARGEM:
			if pi[3]:
				if _perigo_pistao(pi[2], s):
					return true
			elif _perigo_jato(pi[2], s):
				return true
			s += 0.04
	return false


# ------------------------------------------------------------ andar
func _ha_vao_a_frente(p: Vector2) -> bool:
	var sp := k.get_world_2d().direct_space_state
	for dx in [28.0, 52.0]:
		var q := PhysicsRayQueryParameters2D.create(p + Vector2(dx, 6.0), p + Vector2(dx, 90.0), 1)
		if sp.intersect_ray(q).is_empty():
			return true
	return false


func _bate_em_degrau(p: Vector2) -> bool:
	var sp := k.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(p + Vector2(0, -12.0), p + Vector2(34.0, -12.0), 1)
	return not sp.intersect_ray(q).is_empty()


func _andar_para(alvo_x: float, no_chao: bool, p: Vector2) -> void:
	if no_chao:
		if p.y < 640.0:
			_ultimo_ok = p
		if _bloqueado(p, alvo_x):
			_prem(A_DIR, false)
			_prem(A_SALTO, false)
			return
		_prem(A_DIR, p.x < alvo_x)
		if _ha_vao_a_frente(p) or _bate_em_degrau(p):
			_prem(A_SALTO, true)
			_segura_salto = 0.34
		else:
			_prem(A_SALTO, false)
		_duplo_usado = false
	else:
		_prem(A_DIR, p.x < alvo_x)
		_segura_salto -= 1.0 / 60.0
		if _segura_salto <= 0.0:
			_prem(A_SALTO, false)
		if k.get("velocity").y > 120.0 and absf(p.x - alvo_x) > 30.0 and not _duplo_usado \
				and _ha_vao_a_frente(p):
			_duplo_usado = true
			_prem(A_SALTO, false)
			_prem(A_SALTO, true)


func _physics_process(dt: float) -> bool:
	if k == null or raiz == null:
		return false
	if not is_instance_valid(k) or current_scene != raiz:
		_resumo("OK (Porta atravessada: o nivel mudou)")
		quit(0 if toques == 0 else 3)
		return false
	t += dt
	RelogioFornalha.manual = t
	k.set("_invulneravel", 5.0)
	var p := k.global_position
	if t > _tmax:
		_fim("TIMEOUT no passo %d em %s" % [passo, str(p)])
		return false
	var no_chao: bool = k.is_on_floor()
	if _modo_segredos:
		_segredos(dt, no_chao, p)
		return false
	if _modo_fossos:
		_fossos(dt, no_chao, p)
		return false
	if OS.get_environment("N20_DEBUG") != "" and int(t * 2.0) != int((t - dt) * 2.0) and t < 60.0:
		var h2 = _pistoes[1]
		print("   dbg t=%.1f p=(%.0f,%.0f) chao=%s bloq=%s A2.frac=%.2f A2.estado=%d paus=%s" % [t, p.x, p.y, str(no_chao),
			str(_bloqueado(p, 1465.0)), h2._frac, h2.estado, str(h2.pausado)])
	if _toca_zona_agora(p):
		toques += 1
		if toques <= 6 or toques % 30 == 0:
			print("  TOQUE em zona ativa (%d) em (%.0f, %.0f) t=%.1fs passo %d" % [toques, p.x, p.y, t, passo])
	# quedas ao fundo de um fosso: conta e repoe no ultimo ponto bom
	if p.y > 700.0 and _y_ant <= 700.0:
		quedas += 1
		print("  QUEDA ao fundo do fosso em %s (passo %d)" % [str(p), passo])
		if _ultimo_ok != Vector2.ZERO:
			k.global_position = _ultimo_ok
			k.set("velocity", Vector2.ZERO)
	_y_ant = k.global_position.y
	if passo >= plano.size():
		_fim("OK")
		return false
	var s: Dictionary = plano[passo]
	var v_nome: String = s.get("v", "")
	if OS.get_environment("N20_SEM_VALVULAS") != "":
		v_nome = ""     # controlo negativo: sem valvulas o percurso tem de falhar/esperar
	if v_nome != "" and not _tocou_neste.has(passo):
		var v := raiz.get_node_or_null(v_nome)
		if v == null:
			_fim("falta " + v_nome)
			return false
		_andar_para(float(s.x), no_chao, p)
		if v.get("aberta") == true:
			_tocou_neste[passo] = true
			_espera = 0.9
			print("  passo %d: %s aberta em t=%.1fs" % [passo, v_nome, t])
		return false
	if _espera > 0.0:
		_espera -= dt
		_para()
		return false
	_andar_para(float(s.x), no_chao, p)
	if p.x >= float(s.x) - 22.0 and no_chao:
		print("  passo %d ok em (%.0f, %.0f) t=%.1fs" % [passo, p.x, p.y, t])
		_ultimo_ok = p
		_para()
		passo += 1
	return false


func _resumo(msg: String) -> void:
	print("PROVA N20 %s | passos=%d/%d | toques=%d | quedas=%d | t=%.1fs" % [msg, passo, plano.size(), toques, quedas, t])


func _fim(msg: String) -> void:
	_para()
	_resumo(msg + " | pos=" + str(k.global_position))
	quit(0 if (msg == "OK" and toques == 0) else 1)


# ------------------------------------------------------------ segredos
## Cada segredo: abre a valvula, sobe ao degrau (que so' existe com ela aberta),
## salta para a alcova e apanha a essencia. Prova FISICA (salto real) de que os
## tres segredos se alcancam.
const SEGREDOS := [
	{"valvula": "ValvulaC", "take": 2425.0, "degrau": "StepC", "alcova": "SegredoA", "essencia": "EssenciaSegredoA"},
	{"valvula": "ValvulaD", "take": 3698.0, "degrau": "StepD", "alcova": "SegredoB", "essencia": "EssenciaSegredoB"},
]


func _rect(n: Node2D) -> Rect2:
	var tam: Vector2 = n.get("tamanho")
	return Rect2(n.global_position - tam * 0.5, tam)


## Salta (a correr para a direita) ate' pousar em cima de `alvo`; devolve true quando pousou.
var _hold := 0.0
var _duplo2 := false


func _salta_para(alvo: Rect2, no_chao: bool, p: Vector2) -> bool:
	var topo := alvo.position.y
	var dentro := p.x >= alvo.position.x - 4.0 and p.x <= alvo.end.x + 4.0
	if no_chao and dentro and absf(p.y - (topo - 22.0)) < 16.0:
		_para()
		return true
	if no_chao:
		_prem(A_DIR, p.x < alvo.position.x + 6.0)
		_prem(A_SALTO, true)
		_hold = 0.34
		_duplo2 = false
	else:
		_prem(A_DIR, p.x < alvo.position.x + 14.0)
		_hold -= 1.0 / 60.0
		if _hold <= 0.0:
			_prem(A_SALTO, false)
		# segundo salto se ja' vai a descer e ainda esta' abaixo do topo do alvo
		if k.get("velocity").y > 40.0 and p.y > topo - 40.0 and not _duplo2:
			_duplo2 = true
			_prem(A_SALTO, false)
			_prem(A_SALTO, true)
	return false


func _segredos(dt: float, no_chao: bool, p: Vector2) -> void:
	if _si >= SEGREDOS.size():
		print("PROVA N20 SEGREDOS %d/%d | t=%.1fs" % [_sdone, SEGREDOS.size(), t])
		_para()
		quit(0 if _sdone == SEGREDOS.size() else 1)
		return
	var S: Dictionary = SEGREDOS[_si]
	var v: Node2D = raiz.get_node(S.valvula)
	var degrau: Node2D = raiz.get_node(S.degrau)
	var alcova: Node2D = raiz.get_node(S.alcova)
	var ess: Node = raiz.get_node_or_null(S.essencia)
	if int(t * 0.5) != int((t - dt) * 0.5) and t > 4.0 and t < 14.0:
		print("   dbg sf=%d p=(%.0f,%.0f) chao=%s step=%s solido=%s" % [_sf, p.x, p.y, str(no_chao), str(_rect(degrau)), str(degrau.get("_solida_agora"))])
	match _sf:
		0:   # poe a Koliani em cima da valvula (o toque abre-a) e espera
			k.global_position = v.global_position + Vector2(0, -34)
			k.set("velocity", Vector2.ZERO)
			_sf = 1
			_sw = 1.2
		1:
			_sw -= dt
			if _sw <= 0.0:
				if v.get("aberta") != true:
					print("  segredo %d: a valvula %s NAO abriu" % [_si + 1, S.valvula])
					_si += 1
					_sf = 0
				else:
					_sf = 2
		2:   # anda ate' ao ponto de partida
			_prem(A_DIR, p.x < float(S.take))
			if no_chao and p.x >= float(S.take) - 6.0:
				_para()
				_sf = 3
				_sw = 0.25
		3:
			_sw -= dt
			if _sw <= 0.0:
				_sf = 4
		4:   # chao -> degrau
			if _salta_para(_rect(degrau), no_chao, p):
				print("  segredo %d: no degrau %s (t=%.1fs)" % [_si + 1, S.degrau, t])
				_sf = 5
				_sw = 0.3
		5:   # anda ate' ao bordo direito do degrau (salto curto, sem balanco a mais)
			_sw -= dt
			var dg := _rect(degrau)
			_prem(A_DIR, p.x < dg.end.x - 16.0)
			if _sw <= 0.0 and p.x >= dg.end.x - 18.0 and no_chao:
				_para()
				_sf = 6
		6:   # degrau -> alcova
			if _salta_para(_rect(alcova), no_chao, p):
				print("  segredo %d: na alcova %s (t=%.1fs)" % [_si + 1, S.alcova, t])
				_sf = 7
				_sw = 2.0
		7:   # vai buscar a essencia
			var alvo_x: float = ess.global_position.x if ess != null and is_instance_valid(ess) else p.x
			_prem(A_DIR, p.x < alvo_x - 6.0)
			_prem("mover_esquerda", p.x > alvo_x + 6.0)
			_sw -= dt
			if ess == null or not is_instance_valid(ess) or ess.is_queued_for_deletion() or _sw <= 0.0:
				var apanhou: bool = ess == null or not is_instance_valid(ess) or ess.is_queued_for_deletion()
				print("  segredo %d: essencia %s" % [_si + 1, "APANHADA" if apanhou else "NAO apanhada"])
				if apanhou:
					_sdone += 1
				_para()
				_si += 1
				_sf = 0


# ------------------------------------------------------------ fossos
## Cair num fosso de lava NAO e' morte nem prisao: da' para sair a saltar (salto
## duplo + agarrar a borda) por qualquer das duas pontas. Probe fisico, por
## fosso e por lado.
func _fossos(dt: float, no_chao: bool, p: Vector2) -> void:
	var fossos := ["LavaB1", "LavaB2", "LavaC"]
	if _fi >= fossos.size() * 2:
		print("PROVA N20 FOSSOS %d/%d | t=%.1fs" % [_fok, fossos.size() * 2, t])
		_para()
		quit(0 if _fok == fossos.size() * 2 else 1)
		return
	var lava: Node2D = raiz.get_node(fossos[_fi / 2])
	var esq: float = lava.global_position.x - float(lava.get("largura")) * 0.5
	var dir: float = lava.global_position.x + float(lava.get("largura")) * 0.5
	var lado_esq := (_fi % 2) == 0
	match _ff:
		0:
			k.global_position = Vector2((esq + 40.0) if lado_esq else (dir - 40.0), 690.0)
			k.set("velocity", Vector2.ZERO)
			_ff = 1
			_ft = 0.0
		1:
			_ft += dt
			var alvo_x := esq - 30.0 if lado_esq else dir + 30.0
			_prem("mover_esquerda", lado_esq)
			_prem(A_DIR, not lado_esq)
			if no_chao:
				_prem(A_SALTO, true)
				_hold = 0.34
				_duplo2 = false
			else:
				_hold -= dt
				if _hold <= 0.0:
					_prem(A_SALTO, false)
				if k.get("velocity").y > 40.0 and not _duplo2:
					_duplo2 = true
					_prem(A_SALTO, false)
					_prem(A_SALTO, true)
			var fora := p.x < esq if lado_esq else p.x > dir
			if no_chao and fora and p.y < 590.0:
				print("  fosso %s lado %s: saiu em %.1fs" % [fossos[_fi / 2], "esq" if lado_esq else "dir", _ft])
				_fok += 1
				_para()
				_fi += 1
				_ff = 0
			elif _ft > 8.0:
				print("  fosso %s lado %s: NAO saiu em 8 s (pos %s chao=%s vel=%s)" % [fossos[_fi / 2], "esq" if lado_esq else "dir", str(p), str(no_chao), str(k.get("velocity"))])
				for i in k.get_slide_collision_count():
					var col: KinematicCollision2D = k.get_slide_collision(i)
					print("     colide com ", col.get_collider(), " normal ", col.get_normal())
				_para()
				_fi += 1
				_ff = 0
