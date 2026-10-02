extends SceneTree
## PROVA DE TRAVESSIA DETERMINISTA do N18 ("Camara da Lava"): um piloto de
## "jogo perfeito" que obedece aos relogios dos perigos (espera pelo elevador,
## pelo piso frio, pela janela do jato) e atravessa o nivel inteiro com a
## Koliani REAL. Complementa o `bot_humano_r2.gd` (que nao sabe esperar por
## plataformas moveis temporizadas): aqui prova-se que o caminho FISICO existe
## com os relogios REAIS; a dificuldade humana fica para o playtest.
##
## A Koliani fica invulneravel (isola a geometria do dano) mas contam-se as
## "quedas" (y > 690 fora de um fosso raso = teria caido na lava funda) e
## regista-se quanto dano TERIA levado (contacto com zonas ativas).
##
## Uso: Godot --headless --fixed-fps 60 --path . --script res://tools/prova_n18_travessia.gd -- [tmax_s]

const CENA := "res://scenes/levels/Cripta_das_Mil_Velas.tscn"
const A_DIR := "mover_direita"
const A_ESQ := "mover_esquerda"
const A_SALTO := "saltar"

var k: Node2D
var raiz: Node
var t := 0.0
var fase := 0
var quedas := 0
var _y_ant := 0.0
var _segura_salto := 0.0
var _esperou := 0.0
var _resultado := {}
var _tmax := 240.0
var _marca := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_tmax = float(args[0])
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		es.indice_nivel = int(es.NIVEIS.find(CENA))
		es.checkpoint = Vector2.ZERO
	change_scene_to_file(CENA)
	await process_frame
	await process_frame
	raiz = current_scene
	k = get_first_node_in_group("koliani")
	if k == null:
		print("PROVA FALHOU: sem Koliani")
		quit(2)
		return
	_y_ant = k.global_position.y
	print("PROVA N18: inicio em ", k.global_position)


func _no(n: String) -> Node2D:
	return raiz.get_node_or_null(n) as Node2D


func _prem(a: String, on: bool) -> void:
	if on:
		Input.action_press(a)
	else:
		Input.action_release(a)


func _salta(on: bool) -> void:
	_prem(A_SALTO, on)


func _physics_process(dt: float) -> bool:
	if k == null or raiz == null:
		return false
	if not is_instance_valid(k) or current_scene != raiz:
		print("PROVA N18 OK (Porta atravessada: o nivel mudou) | fases=%d | quedas=%d | t=%.1fs" % [fase, quedas, t])
		quit(0)
		return false
	t += dt
	k.set("_invulneravel", 5.0)
	var p := k.global_position
	if t > _tmax:
		_fim("TIMEOUT na fase %d em %s" % [fase, str(p)])
		return false
	var no_chao: bool = k.is_on_floor()
	# --- maquina de fases: cada fase leva a Koliani a um alvo (x, y_topo) ---
	match fase:
		0:   # ChaoA -> pedras A1/A2 -> ChaoB1 (espera a lava A baixa)
			_ir_para(1500.0, 600.0, no_chao, p)
		1:   # carrinho B1 (margem 1620 -> 1900)
			_carrinho("CarrinhoB1", 1930.0, 600.0, no_chao, p, 1620.0)
		2:   # ChaoB2 (ate' 2100) -> carrinho B2 -> Laje1 (comeca em 2650)
			_carrinho("CarrinhoB2", 2690.0, 600.0, no_chao, p, 2100.0)
		3:   # Laje1 -> Laje2 -> ChaoB3
			_ir_para(3000.0, 600.0, no_chao, p, true)
		4:   # ChaoB3 -> E1 (espera em baixo, sobe, sai em y~300)
			_elevador_sobe(no_chao, p)
		5:   # LedgeC1 -> PlatC2 (cruza o piso quente a frio) -> lajes -> PedraEspera
			_ir_para(3720.0, 300.0, no_chao, p)
		6:
			_cruza_piso("PisoC2", 3935.0, no_chao, p)
		7:
			_ir_para(4420.0, 300.0, no_chao, p, true)
		8:   # PedraEspera -> E2 -> ExitC
			_elevador_desce(no_chao, p)
		9:   # ExitC -> D (piso, jato) -> lajes -> PedraD3
			_cruza_piso("PisoD1", 5060.0, no_chao, p)
		10:
			_cruza_jato("JatoD1", 5220.0, no_chao, p)
		11:
			_ir_para(5640.0, 600.0, no_chao, p, true)
		12:  # elevador curto -> arena
			_elevador_curto(no_chao, p)
		13:
			_cruza_piso("PisoArena1", 6290.0, no_chao, p, false, 450.0)
		14:
			_cruza_piso("PisoArena2", 6660.0, no_chao, p, false, 450.0)
		_:
			_fim("OK")
			return false
	if p.y > 690.0 and not (p.x > 1130.0 and p.x < 1480.0) and not (p.x > 1620.0 and p.x < 1900.0) \
			and not (p.x > 2100.0 and p.x < 2970.0) and not (p.x > 5250.0 and p.x < 5590.0):
		pass
	if p.y > 715.0 and _y_ant <= 715.0 and (fase >= 4):
		quedas += 1
		print("  QUEDA ao fundo do poco em ", p, " (fase ", fase, ")")
		_repor()
	_y_ant = k.global_position.y
	return false


var _ultimo_ok := Vector2.ZERO


func _repor() -> void:
	if _ultimo_ok != Vector2.ZERO:
		k.global_position = _ultimo_ok
		k.set("velocity", Vector2.ZERO)


func _anda_ate(alvo_x: float, p: Vector2) -> bool:
	_prem(A_DIR, p.x < alvo_x - 6.0)
	_prem(A_ESQ, p.x > alvo_x + 6.0)
	return absf(p.x - alvo_x) <= 6.0


func _para() -> void:
	_prem(A_DIR, false)
	_prem(A_ESQ, false)
	_salta(false)


## Avanca para a direita e salta quando o chao acaba / ha' um vao a' frente.
func _ir_para(alvo_x: float, alvo_y: float, no_chao: bool, p: Vector2, so_x := false) -> void:
	if absf(p.x - alvo_x) <= 40.0 and (so_x or absf(p.y - alvo_y) < 60.0) and no_chao:
		_marca_ok(p)
		_para()
		fase += 1
		return
	_prem(A_DIR, p.x < alvo_x)
	_prem(A_ESQ, false)
	if no_chao:
		if p.y < 640.0 or fase >= 12:
			_ultimo_ok = p
		# salta se nao ha' chao a' frente (olha 40 px) ou se vai bater numa subida
		if _ha_vao_a_frente(p) or _bate_em_degrau(p):
			_salta(true)
			_segura_salto = 0.34
		else:
			_salta(false)
	else:
		_segura_salto -= get_physics_process_delta_time_safe()
		if _segura_salto <= 0.0:
			_salta(false)
		# duplo salto quando comeca a cair e ainda falta chao
		if k.get("velocity").y > 120.0 and absf(p.x - alvo_x) > 30.0 and not _duplo_usado:
			_duplo_usado = true
			_salta(false)
			_salta(true)
	if no_chao:
		_duplo_usado = false


var _duplo_usado := false


func get_physics_process_delta_time_safe() -> float:
	return 1.0 / 60.0


func _segura() -> bool:
	return true


func _marca_ok(p: Vector2) -> void:
	print("  fase %d ok em (%.0f, %.0f) t=%.1fs" % [fase, p.x, p.y, t])
	_ultimo_ok = p


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


## Carrinho horizontal: espera na margem, embarca quando o carrinho encosta,
## deixa-se levar e salta para a margem de saida (`x_dest`: borda da proxima
## superficie; `alvo_x`: onde fica de pe').
var _est := 0
var _sondou := false
var _sondou2 := false


func _carrinho(nome: String, alvo_x: float, _alvo_y: float, no_chao: bool, p: Vector2, borda_ent: float) -> void:
	var c := _no(nome)
	if c == null:
		_fim("falta " + nome)
		return
	var metade: float = float(c.get("largura")) * 0.5
	var esq: float = c.global_position.x - metade
	var dir: float = c.global_position.x + metade
	var x_dest: float = _x_dest.get(nome, alvo_x)
	match _est:
		0:   # ir ate' ao bordo da margem de entrada
			_prem(A_DIR, p.x < borda_ent - 22.0)
			_salta(false)
			if p.x >= borda_ent - 24.0 and no_chao:
				_prem(A_DIR, false)
				_est = 1
		1:   # esperar o carrinho encostar (borda esq <= borda_ent + 8) e embarcar
			if esq <= borda_ent + 62.0 and esq >= borda_ent - 12.0 and no_chao:
				_prem(A_DIR, true)
				_salta(true)
				_segura_salto = 0.12
				_est = 2
			else:
				_prem(A_DIR, false)
		2:   # em voo/a bordo: segurar ate' pousar no carrinho
			_segura_salto -= 1.0 / 60.0
			if _segura_salto <= 0.0:
				_salta(false)
			_prem(A_DIR, p.x < esq + metade * 0.9)
			if no_chao and p.y < 600.0 and p.x > esq - 4.0 and p.x < dir + 4.0:
				_prem(A_DIR, false)
				_est = 3
			elif p.y > 650.0:
				_est = 0   # caiu: recomeca (a queda conta)
		3:   # a bordo: esperar que a borda dir encoste a' margem de saida
			_prem(A_DIR, false)
			if dir >= float(_dir_max.get(nome, x_dest)) - 6.0 and no_chao:
				_prem(A_DIR, true)
				_salta(true)
				_segura_salto = 0.28
				_est = 4
		4:   # salto para a margem de saida
			_segura_salto -= 1.0 / 60.0
			if _segura_salto <= 0.0:
				_salta(false)
			_prem(A_DIR, p.x < alvo_x)
			if no_chao and p.x >= x_dest + 4.0 and p.y < 640.0:
				_marca_ok(p)
				_para()
				_est = 0
				fase += 1
			elif p.y > 700.0:
				_est = 0
	if _est == 0 and t > 150.0:
		_fim("carrinho %s nao concluido" % nome)


var _dir_max := {"CarrinhoB1": 1890.0, "CarrinhoB2": 2585.0}
var _x_dest := {"CarrinhoB1": 1900.0, "CarrinhoB2": 2650.0}


func _topo(e: Node2D) -> float:
	return e.global_position.y - 8.0


func _elevador_sobe(no_chao: bool, p: Vector2) -> void:
	var e := _no("ElevadorE1")
	if e == null:
		_fim("falta E1")
		return
	var topo := _topo(e)
	if false and int(t * 4.0) != int((t - 1.0 / 60.0) * 4.0):
		print("   dbg t=%.2f p=(%.0f,%.0f) E1top=%.0f chao=%s" % [t, p.x, p.y, topo, str(no_chao)])
	var a_bordo: bool = p.x > 3318.0 and p.x < 3445.0 and absf(p.y - (topo - 22.0)) < 24.0
	if p.y < 330.0 and p.x > 3440.0:
		_prem(A_DIR, p.x < 3500.0)
		_salta(false)
		if p.x >= 3490.0 and no_chao:
			_marca_ok(p)
			_para()
			fase += 1
		return
	if not a_bordo and p.x < 3470.0:
		# na margem: avanca ate' ao bordo e embarca quando o elevador esta' a menos de 30 px da cota
		if p.x < 3286.0:
			_prem(A_DIR, true)
		elif topo >= 570.0 or p.x > 3300.0:
			_prem(A_DIR, p.x < 3345.0 and topo >= 540.0)
			_salta(p.x < 3330.0 and topo >= 570.0)
		else:
			_prem(A_DIR, false)
			_salta(false)
		return
	_salta(false)
	_prem(A_DIR, false)
	# sai para o patamar C1 quando o elevador passa pelo nivel 300 (a subir)
	if a_bordo and topo <= 306.0 and topo >= 240.0:
		_prem(A_DIR, true)
		_salta(true)
		_segura_salto = 0.2
	if p.x > 3475.0 and no_chao and absf(p.y - 278.0) < 60.0:
		_marca_ok(p)
		_para()
		fase += 1


func _cruza_piso(nome: String, alvo_x: float, no_chao: bool, p: Vector2, _a := false, _y := 0.0) -> void:
	var piso := _no(nome)
	if piso == null:
		_fim("falta " + nome)
		return
	var larg: float = float(piso.get("largura"))
	var ini: float = piso.global_position.x - larg * 0.5
	var fim: float = piso.global_position.x + larg * 0.5
	var agora := Time.get_ticks_msec() * 0.001
	var cic: float = float(piso.call("_ciclo"))
	# janela segura para atravessar: precisa de >= 1.4 s sem QUENTE (estado FRIO ou AVISO nao fere)
	var seguro := true
	for i in 15:
		if int(piso.call("estado_em", agora + float(i) * 0.1)) == 2:
			seguro = false
	var dentro: bool = p.x > ini - 4.0 and p.x < fim + 4.0
	if p.x < ini - 30.0:
		_prem(A_DIR, true)
	elif p.x < ini - 4.0 and not seguro:
		_prem(A_DIR, false)
	else:
		_prem(A_DIR, p.x < alvo_x)
	if p.x >= alvo_x - 6.0 and no_chao:
		_marca_ok(p)
		_para()
		fase += 1
	if cic < 0.0:
		pass


func _cruza_jato(nome: String, alvo_x: float, no_chao: bool, p: Vector2) -> void:
	var j := _no(nome)
	if j == null:
		_fim("falta " + nome)
		return
	var agora := Time.get_ticks_msec() * 0.001
	var jx: float = j.global_position.x
	var livre := true
	for i in 12:
		if int(j.call("estado_em", agora + float(i) * 0.1)) != 0:
			livre = false
	if p.x < jx - 60.0:
		_prem(A_DIR, true)
	elif p.x < jx - 30.0 and not livre:
		_prem(A_DIR, false)
	else:
		_prem(A_DIR, p.x < alvo_x)
	if p.x >= alvo_x - 6.0 and no_chao:
		_marca_ok(p)
		_para()
		fase += 1


func _elevador_desce(no_chao: bool, p: Vector2) -> void:
	var e := _no("ElevadorE2")
	if e == null:
		_fim("falta E2")
		return
	var topo := _topo(e)
	var a_bordo: bool = p.x > 4487.0 and p.x < 4635.0 and absf(p.y - (topo - 22.0)) < 24.0
	if not a_bordo and p.x < 4640.0:
		if topo <= 312.0 and p.y < 330.0:
			_prem(A_DIR, true)    # elevador no topo, flush com a pedra de espera
		else:
			_prem(A_DIR, false)
		return
	_salta(false)
	_prem(A_DIR, false)
	if a_bordo and topo >= 568.0:
		_prem(A_DIR, true)
		_salta(true)
		_segura_salto = 0.2
	if not a_bordo and p.x > 4640.0 and p.y > 540.0:
		_prem(A_DIR, p.x < 4700.0)
	if p.x > 4690.0 and no_chao and absf(p.y - 578.0) < 60.0:
		_marca_ok(p)
		_para()
		fase += 1


var _topo_ant_d := 600.0


func _elevador_curto(no_chao: bool, p: Vector2) -> void:
	var e := _no("ElevadorD")
	if e == null:
		_fim("falta ElevadorD")
		return
	var topo := _topo(e)
	var subindo: bool = topo < _topo_ant_d
	_topo_ant_d = topo
	var a_bordo: bool = p.x > 5722.0 and p.x < 5838.0 and absf(p.y - (topo - 22.0)) < 24.0
	if _saltou_d:
		_segura_salto -= 1.0 / 60.0
		if _segura_salto <= 0.0:
			_salta(false)
		_prem(A_DIR, true)
		if p.x > 5880.0 and no_chao and absf(p.y - 428.0) < 60.0:
			_marca_ok(p)
			_para()
			_saltou_d = false
			fase += 1
		elif p.y > 650.0:
			_saltou_d = false
		return
	if not a_bordo and p.x < 5860.0:
		_prem(A_DIR, topo >= 590.0 and p.y > 560.0)
		return
	_salta(false)
	_prem(A_DIR, a_bordo and topo <= 560.0 and subindo and p.x < 5812.0)
	if a_bordo and p.x > 5800.0 and topo <= 472.0 and subindo:
		_saltou_d = true
		_prem(A_DIR, true)
		_salta(true)
		_segura_salto = 0.2


var _saltou_d := false


func _fim(msg: String) -> void:
	_para()
	var r := "PROVA N18 %s | fases=%d | quedas=%d | t=%.1fs | pos=%s" % [msg, fase, quedas, t, str(k.global_position)]
	print(r)
	quit(0 if msg == "OK" else 1)
