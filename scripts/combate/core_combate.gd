class_name CoreCombate
extends Node
## CORE COMBAT -- Fases 2/3/4/6 da integração do Combat Lab v1.2 em produção
## (ver `docs/plano_integracao_combate_producao.md` §2 e §8). Mesma lógica
## validada de `scripts/lab/combate_lab.gd` (congelado, não tocado por este
## ficheiro), mas com os números lidos de `BalanceCombate` (Fase 1) em vez de
## constantes soltas, e a origem do dano lida de `OrigemDano` (Fase 5) em vez
## de strings à mão.
##
## Componente OPT-IN (filho da Koliani, criado só por `Koliani.ativar_core_combate()`).
## Nenhum nível de campanha o cria: sem ele, o `koliani.gd` corre exactamente
## como antes -- é o mesmo padrão não-invasivo que o `_lab` já usa (ver
## `Koliani.ativar_combat_lab()`). Só a arena de QA de produção (Fase 11) o liga.
##
## Fases combinadas neste ficheiro em vez de separadas: Launcher, Air Combo,
## Cleave, Dash Attack, Perfect Dodge e Counter partilham UMA máquina de
## estados só (`_move`/`tick`/`tratar_input`) no Combat Lab original -- separá-las
## em ficheiros diferentes duplicaria a mesma fonte de verdade quatro vezes
## (o que a Fase 1 pediu para evitar). Landed juntos; os commits das fases
## 2/3/4/6 ficam documentados nesta mensagem em vez de divididos por ficheiro.
##
## Inputs (iguais ao Combat Lab -- decisão fechada do Game Director):
##   ATAQUE x4            combo base (inalterado)
##   CIMA + ATAQUE (chao) LAUNCHER   -- o botão usado determina a ação;
##                         não cria atalho novo (joystick cima + tiro continua a mirar)
##   ATAQUE (no ar)       cadeia aerea ate' 2 golpes
##   BAIXO + ATAQUE (ar)  POGO       -- inalterado, prioridade sobre Air Attack
##   SEGURAR ATAQUE       SHADOW CLEAVE (>= carga_cleave_t, larga-se) -- quebra guarda
##                         [CLEAVE FINAL ART DEBT: feedback de carga usa `_acender_aura`+som
##                         existentes, sem sprite novo -- ver docs/plano_integracao_combate_producao.md §6]
##   ATAQUE durante/logo apos DASH  DASH ATTACK
##   ROLL certo (janela pd_janela)  PERFECT DODGE (+Energia, abre o contra)
##   ATAQUE ate' counter_janela depois do Perfect Dodge  SHADOW COUNTER (nunca automático)

var bal: BalanceCombate
var k: Koliani
var _ar_n := 0
var _move := ""
var _move_t := 0.0
var _move_acertou := false
var _move_atingidos := {}
var _buffer_pedido := false
var _hold_ativo := false
var _hold_t := 0.0
var _carregado := false
var _atk_antes := false
var _largou := false
var _counter_t := 0.0
var _pd_cd := 0.0
var _pd_flash: Label
var _pogo_antes := 0
var log_ultimos: Array[String] = []


func iniciar(kol: Koliani, balance: BalanceCombate) -> void:
	k = kol
	bal = balance


# ------------------------------------------------------------------ util ------
func _metr(nome: String, dados := {}) -> void:
	get_tree().call_group("lab_metricas", "registar", nome, dados)


func _energia(fonte: String, qtd: float) -> void:
	if qtd <= 0.0:
		return
	var antes := k.energia_actual()
	k.ganhar_energia(qtd)
	_metr("energia", {"fonte": fonte, "pedido": qtd, "ganho": k.energia_actual() - antes})


func _nota(txt: String) -> void:
	log_ultimos.append(txt)
	if log_ultimos.size() > 8:
		log_ultimos.pop_front()


func em_golpe_lab() -> bool:
	return _move != ""


func janela_counter() -> float:
	return _counter_t


func carga() -> float:
	return clampf(_hold_t / bal.carga_cleave_t, 0.0, 1.0) if _hold_ativo else 0.0


## Limita a velocidade horizontal de um golpe em curso para nao passar do centro de um inimigo a` frente
## (mesma faixa vertical). Nao ha' magnetismo: so' trava; quem esta' alem do centro nao e' tocado.
func limitar_x(vx: float, dt: float) -> float:
	if not bal.clamp_avanco or vx == 0.0 or dt <= 0.0:
		return vx
	var dir := signf(vx)
	var maxv := absf(vx)
	for e in inimigos():
		var hb: Rect2 = e.hurtbox() if e.has_method("hurtbox") else Rect2(e.global_position - Vector2(20, 40), Vector2(40, 48))
		if absf(k.global_position.y - hb.get_center().y) > hb.size.y * 0.5 + 30.0:
			continue
		var rel := (hb.get_center().x - k.global_position.x) * dir
		if rel <= 0.0:
			continue
		var dmin := hb.size.x * 0.5 + bal.k_meia_largura - bal.clamp_tolerancia
		maxv = minf(maxv, maxf(0.0, rel - dmin) / dt)
	return dir * maxv


func inimigos() -> Array[Node2D]:
	var r: Array[Node2D] = []
	for e in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(e) and e is Node2D and not bool(e.get("_morto")):
			r.append(e)
	return r


# --------------------------------------------------------------- air combo ----
func ar_pode_encadear() -> bool:
	return _ar_n < bal.ar_max


func ar_passo_seguinte() -> int:
	var p := mini(_ar_n, 1)
	_ar_n += 1
	_nota("ar %d" % _ar_n)
	return p


## Devolve o dano AJUSTADO (hierarquia v1.2: o combo basico sustentado paga menos que as sequencias intencionais).
func ao_acertar_normal(corpo: Node, passo: int, no_ar: bool, dano: int) -> int:
	corpo.set_meta("lab_passo", passo)
	corpo.set_meta("lab_ar", no_ar)
	_metr("energia", {"fonte": "normal_ar" if no_ar else "normal%d" % passo, "pedido": Koliani.ENERGIA_POR_GOLPE,
		"ganho": Koliani.ENERGIA_POR_GOLPE})
	_nota("%s%d" % ["AR" if no_ar else "N", passo + 1])
	var mult: float = float((bal.ar_dano_mult if no_ar else bal.base_dano_mult)[clampi(passo, 0, 3 if not no_ar else 1)])
	var base := float(dano) / float(Koliani.DANO_COMBO[clampi(passo, 0, 3)])   # dano da espada sem multiplicador
	return maxi(1, roundi(base * mult))


## Recuperacao extra do golpe normal (v1.2): so' o 4.o (remate), no chao.
func recup_extra(passo: int, no_ar: bool) -> float:
	return bal.recup_extra_remate if (passo >= 3 and not no_ar) else 0.0


# ------------------------------------------------------------------- tick -----
func tick(dt: float) -> void:
	var premido := Input.is_action_pressed("atacar")
	_largou = _atk_antes and not premido
	_atk_antes = premido
	_counter_t = maxf(0.0, _counter_t - dt)
	_pd_cd = maxf(0.0, _pd_cd - dt)
	if k.is_on_floor():
		_ar_n = 0
	# um pogo que acerta (estado 3) repoe a cadeia aerea: Air combo -> Pogo -> reposicionar
	if k._pogo_estado == 3 and _pogo_antes != 3:
		_ar_n = 0
		_nota("POGO")
		_metr("pogo_acerto", {})
		_energia("pogo", bal.energia_pogo)
	_pogo_antes = k._pogo_estado
	# carga do Shadow Cleave
	if _hold_ativo:
		if _largou and _carregado:
			pass   # o `tratar_input` deste frame trata do largar (Shadow Cleave)
		elif Input.is_action_pressed("atacar") and k._hurt_t <= 0.0 and k._rolar_restante <= 0.0 \
				and _move == "" and k.is_on_floor():
			_hold_t += dt
			if not _carregado and _hold_t >= bal.carga_cleave_t:
				_carregado = true
				k._acender_aura(1.0)
				Som.toca("carrossel", -12.0, 1.6, 0.0)
				_nota("CARGA!")
		else:
			_hold_ativo = false
			_hold_t = 0.0
			_carregado = false
	# golpe do lab em curso
	if _move != "":
		_move_t += dt
		var d: Dictionary = bal.moves[_move]
		var ini: float = float(d["startup"])
		var fim: float = ini + float(d["ativo"])
		if _move_t >= ini and _move_t < fim:
			_aplicar_golpe(d)
		if _move_t >= ini + float(d["ativo"]) + float(d["recup"]):
			_move = ""
			if _buffer_pedido:
				_buffer_pedido = false
				k.lab_golpe_custom = false
				k._iniciar_ataque()


# ------------------------------------------------------------ input principal --
## Devolve true se CONSUMIU o input de ataque neste frame (o `koliani.gd` salta a logica normal).
func tratar_input(_dt: float) -> bool:
	if k._defendendo or k._a_morrer:
		return false
	var largou := _largou
	var premiu := Input.is_action_just_pressed("atacar")
	# ---- Shadow Cleave: largar depois de carregado
	if largou and _carregado and _hold_ativo and k.is_on_floor() and _move == "" \
			and k._rolar_restante <= 0.0:
		_hold_ativo = false
		_hold_t = 0.0
		_carregado = false
		_iniciar_move("cleave")
		return true
	if largou:
		_hold_ativo = false
		_hold_t = 0.0
		_carregado = false
	if not premiu:
		return false
	var cima := Input.is_action_pressed("mirar_cima")
	# ---- Shadow Counter: nunca automatico; e' o jogador que carrega
	if _counter_t > 0.0 and _move != "counter":
		if k._rolar_restante > 0.0:
			k._rolar_restante = 0.0   # o contra corta o resto do roll
		_counter_t = 0.0
		_iniciar_move("counter")
		return true
	# ---- Dash Attack: durante o dash ou na janela de saida
	if (k._dash_restante > 0.0 or k._dash_saida_t > 0.0) and _move == "":
		_iniciar_move("dash")
		return true
	# ---- durante um golpe em curso
	if _move != "":
		return _durante_move(cima)
	# ---- Launcher: no chao, CIMA + ATAQUE; pode cortar um golpe normal que ja' acertou
	if cima and k.is_on_floor() and k._rolar_restante <= 0.0 and k._pogo_estado == 0:
		if k._ataque_restante <= 0.0 or _normal_cancelavel():
			if k._ataque_restante > 0.0:
				k._cancelar_ataque()
			_iniciar_move("launcher")
			return true
		return false
	# ---- comeca a contar a carga (o golpe normal dispara na mesma; a carga e' so' segurar)
	if k.is_on_floor() and k._rolar_restante <= 0.0 and k._pogo_estado == 0:
		_hold_ativo = true
		_hold_t = 0.0
		_carregado = false
	return false


func _normal_cancelavel() -> bool:
	if k._ataque_dur <= 0.0 or k._alvos_atingidos_ataque.is_empty():
		return false
	if k._combo_passo >= Koliani.NUM_COMBO - 1:
		return false   # o remate compromete: nao se cancela gratis para o launcher
	var passo := clampi(k._combo_passo, 0, Koliani.NUM_COMBO - 1)
	var prog := 1.0 - k._ataque_restante / k._ataque_dur
	return prog >= float(Koliani.ATAQUE_ATIVO_FIM[passo]) or prog >= 0.5


func _durante_move(cima: bool) -> bool:
	var d: Dictionary = bal.moves[_move]
	var ativo_fim: float = float(d["startup"]) + float(d["ativo"])
	var confirmou := _move_acertou and _move_t >= ativo_fim
	# launcher que acertou + salto: o proximo ATAQUE no ar e' um golpe aereo normal (cancela a recuperacao)
	if not k.is_on_floor() and confirmou:
		_cortar_move()
		return false
	# dash attack / counter que acertaram podem ligar ao LAUNCHER (Dash Attack -> Launcher -> Air Combo)
	if cima and k.is_on_floor() and confirmou and _move in ["dash", "counter", "cleave"]:
		_cortar_move()
		_iniciar_move("launcher")
		return true
	# resto: buffer curto para o golpe normal a seguir
	_buffer_pedido = true   # dispara quando a recuperacao acabar (o compromisso do golpe mantem-se)
	return true


func _cortar_move() -> void:
	_move = ""
	k._cancelar_ataque()


# -------------------------------------------------------------- executar ------
func _iniciar_move(nome: String) -> void:
	var d: Dictionary = bal.moves[nome]
	k._cancelar_ataque()
	k.lab_golpe_custom = true
	_move = nome
	_move_t = 0.0
	_move_acertou = false
	_move_atingidos.clear()
	_buffer_pedido = false
	var total: float = float(d["startup"]) + float(d["ativo"]) + float(d["recup"])
	k._ataque_no_ar = not k.is_on_floor()
	k._combo_passo = int(d["passo_visual"])
	k._ataque_dur = total
	k._ataque_restante = total
	# o dash attack abre a janela do combo normal (o proximo ATAQUE continua no golpe 2)
	k._combo_janela = total + Koliani.JANELA_COMBO if nome == "dash" else 0.0
	k._combo_pedido = false
	k._acender_aura(0.9)
	k._avanco_vel = float(d["avanco"])
	k._avanco_dur = float(d["avanco_dur"])
	k._avanco_restante = float(d["avanco_dur"])
	k._flash_golpe()
	k._disparar_vfx_golpe()
	Som.toca(Koliani.SOM_COMBO[clampi(int(d["passo_visual"]), 0, 3)], -8.0, 0.7 if nome in ["cleave", "counter"] else 1.1, 0.02)
	_nota(nome.to_upper())
	_metr("golpe", {"nome": nome, "startup": d["startup"], "ativo": d["ativo"], "recup": d["recup"]})


func _rect_do_golpe(d: Dictionary) -> Rect2:
	var r: Rect2 = d["rect"]
	var dir := k._olha_para
	var x0 := r.position.x if dir > 0.0 else -(r.position.x + r.size.x)
	return Rect2(k.global_position + Vector2(x0, r.position.y), r.size)


func _aplicar_golpe(d: Dictionary) -> void:
	var caixa := _rect_do_golpe(d)
	for e in inimigos():
		var id := e.get_instance_id()
		if _move_atingidos.has(id):
			continue
		var hb: Rect2 = e.hurtbox() if e.has_method("hurtbox") else Rect2(e.global_position - Vector2(20, 40), Vector2(40, 48))
		if not caixa.intersects(hb):
			continue
		_move_atingidos[id] = true
		_move_acertou = true
		var mult_map: Dictionary = {"launcher": bal.energia_launcher, "dash": bal.energia_dash_atk,
			"cleave": bal.energia_cleave, "counter": bal.energia_counter}
		var golpe_mult := {"launcher": 1.3, "dash": 1.3, "cleave": 2.3, "counter": 2.7}
		var dano := maxi(1, roundi(k._dano_golpe() * float(golpe_mult.get(_move, 1.0))))
		var crit := k._pos_roll_t > 0.0
		var info := {"tipo": _move, "dano": dano, "dir": signf(k._olha_para), "critico": crit,
			"guard_break": bool(d["guard_break"]), "passo": 0, "ar": false}
		var res: Dictionary = {}
		if e.has_method("lab_hit"):
			res = e.lab_hit(info)
		else:
			e.receber_dano(dano, signf(k._olha_para), crit, 200.0)
		_energia(_move, float(mult_map.get(_move, d.get("energia", 0.0))))
		k._pop_impacto(e.global_position, _move in ["cleave", "counter"])
		k._abanar(Koliani.TREMOR_REMATE if _move in ["cleave", "counter"] else Koliani.TREMOR_GOLPE)
		k._hitstop(float(d["hitstop"]))
		Som.toca("acerto_critico" if _move in ["cleave", "counter"] else "acerto", -7.0, 1.0, 0.03)
		_nota("%s>%s" % [_move, String(res.get("efeito", ""))])


# ---------------------------------------------------------------- Perfect Dodge
## Chamado pela Koliani quando um golpe inimigo chega enquanto ela esta' invulneravel.
func tentativa_de_dano(quantidade: int, origem := "") -> void:
	if k._rolar_restante <= 0.0 or _pd_cd > 0.0:
		return
	# CONTRATO (Fase 5): so' um ATAQUE identificado (OrigemDano.ATAQUE / HAZARD_ATAQUE) pode dar
	# Perfect Dodge. Contacto corporal, ambiente e origem desconhecida seguem as regras normais.
	if origem != OrigemDano.ATAQUE and origem != OrigemDano.HAZARD_ATAQUE:
		_metr("pd_ignorado", {"origem": origem, "dano": quantidade})
		return
	var decorrido: float = Koliani.DUR_ROLAR - k._rolar_restante
	if decorrido > bal.pd_janela:
		_metr("dodge_cedo", {"decorrido": decorrido})
		return
	_pd_cd = bal.pd_cooldown
	_counter_t = bal.counter_janela
	_energia("perfect_dodge", bal.energia_perfect_dodge)
	k._hitstop(0.06)
	k._flash_branco()
	k._abanar(Koliani.TREMOR_REMATE)
	k._acender_aura(1.0)
	Som.toca("acerto_critico", -5.0, 1.4, 0.0, 0.0, "", Som.Prioridade.MEDIA)
	Som.toca("bloqueio", -8.0, 1.6, 0.0)
	_mostrar_pd()
	_nota("PERFECT DODGE")
	_metr("perfect_dodge", {"decorrido": decorrido, "dano_evitado": quantidade})


func _mostrar_pd() -> void:
	# [PERFECT DODGE VFX DEBT] -- Label temporario, sem arte final (ver plano §6).
	if _pd_flash == null:
		_pd_flash = Label.new()
		_pd_flash.text = "PERFECT DODGE"
		_pd_flash.add_theme_font_size_override("font_size", 18)
		_pd_flash.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
		_pd_flash.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.15))
		_pd_flash.add_theme_constant_override("outline_size", 6)
		_pd_flash.position = Vector2(-70, -132)
		_pd_flash.z_index = 40
		k.add_child(_pd_flash)
	_pd_flash.visible = true
	_pd_flash.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_property(_pd_flash, "modulate:a", 0.0, 0.3)
