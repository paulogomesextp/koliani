class_name CombateLab
extends Node
## COMBAT LAB v1 -- os golpes novos da Koliani, como COMPONENTE opt-in (filho da Koliani, criado por
## `Koliani.ativar_combat_lab()`). Nenhum nivel normal o cria: `_lab == null` => o `koliani.gd` corre
## exactamente como antes. Numeros/notas em `docs/combat_lab_v1.md`.
##
## Inputs finais (tudo sobre o botao ATACAR + direccoes + Roll/Dash existentes):
##   ATAQUE x3            combo base (inalterado)
##   CIMA + ATAQUE (chao) LAUNCHER   -- lanca leves; golem nao e' lancado
##   ATAQUE (no ar)       cadeia aerea ate' 2 golpes (repoe-se ao aterrar ou a um pogo)
##   BAIXO + ATAQUE (ar)  POGO       -- inalterado
##   SEGURAR ATAQUE       SHADOW CLEAVE (>= 0,50 s, larga-se) -- quebra guarda
##   ATAQUE durante/logo apos DASH  DASH ATTACK (corte curto; nao alarga o dash)
##   ROLL certo (<= 0,22 s antes do golpe inimigo)  PERFECT DODGE (+Energia, abre o contra)
##   ATAQUE ate' 0,60 s depois do Perfect Dodge     SHADOW COUNTER (nunca automatico)

const PD_JANELA := 0.22          # s: o golpe inimigo tem de cair nos primeiros 0,22 s do roll
const PD_COOLDOWN := 0.90        # s: sem farmar Energia a rolar por dentro de bichos
const COUNTER_JANELA := 0.60     # s depois do Perfect Dodge
const CARGA_T := 0.50            # s a segurar para o Shadow Cleave
const AR_MAX := 2                # golpes aereos por "salto"
const BUFFER_T := 0.14           # s de buffer de input entre golpes do lab

const ENERGIA_PD := 25.0
const ENERGIA_CLEAVE := 8.0
const ENERGIA_COUNTER := 10.0
const ENERGIA_DASH_ATK := 5.0
const ENERGIA_LAUNCHER := 5.0

## Frame data em segundos (a 60 Hz: 1 frame = 0,0167 s). rect: em px, relativo ao centro da
## Koliani, com x a apontar para onde ela olha.
const MOVES := {
	"launcher": {"startup": 0.10, "ativo": 0.10, "recup": 0.24, "mult": 0.9, "guard_break": false,
		"rect": Rect2(-10.0, -104.0, 92.0, 132.0), "energia": ENERGIA_LAUNCHER, "passo_visual": 2,
		"avanco": 0.0, "avanco_dur": 0.0, "hitstop": 0.014},
	"dash": {"startup": 0.04, "ativo": 0.10, "recup": 0.22, "mult": 1.15, "guard_break": false,
		"rect": Rect2(-6.0, -44.0, 96.0, 76.0), "energia": ENERGIA_DASH_ATK, "passo_visual": 0,
		"avanco": 300.0, "avanco_dur": 0.14, "hitstop": 0.012},
	"cleave": {"startup": 0.14, "ativo": 0.12, "recup": 0.40, "mult": 2.0, "guard_break": true,
		"rect": Rect2(-10.0, -56.0, 128.0, 90.0), "energia": ENERGIA_CLEAVE, "passo_visual": 3,
		"avanco": 160.0, "avanco_dur": 0.12, "hitstop": 0.030},
	"counter": {"startup": 0.06, "ativo": 0.12, "recup": 0.16, "mult": 2.4, "guard_break": true,
		"rect": Rect2(-10.0, -56.0, 140.0, 90.0), "energia": ENERGIA_COUNTER, "passo_visual": 3,
		"avanco": 520.0, "avanco_dur": 0.14, "hitstop": 0.040},
}

var k: Koliani
var _ar_n := 0
var _move := ""
var _move_t := 0.0
var _move_acertou := false
var _move_atingidos := {}
var _buffer_t := 0.0
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


func iniciar(kol: Koliani) -> void:
	k = kol


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
	return clampf(_hold_t / CARGA_T, 0.0, 1.0) if _hold_ativo else 0.0


func inimigos() -> Array[Node2D]:
	var r: Array[Node2D] = []
	for e in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(e) and e is Node2D and not bool(e.get("_morto")):
			r.append(e)
	return r


# --------------------------------------------------------------- air combo ----
func ar_pode_encadear() -> bool:
	return _ar_n < AR_MAX


func ar_passo_seguinte() -> int:
	var p := mini(_ar_n, 1)
	_ar_n += 1
	_nota("ar %d" % _ar_n)
	return p


func ao_acertar_normal(corpo: Node, passo: int, no_ar: bool, dano: int) -> void:
	corpo.set_meta("lab_passo", passo)
	corpo.set_meta("lab_ar", no_ar)
	_metr("energia", {"fonte": "normal_ar" if no_ar else "normal%d" % passo, "pedido": Koliani.ENERGIA_POR_GOLPE,
		"ganho": Koliani.ENERGIA_POR_GOLPE})
	_nota("%s%d" % ["AR" if no_ar else "N", passo + 1])


# ------------------------------------------------------------------- tick -----
func tick(dt: float) -> void:
	var premido := Input.is_action_pressed("atacar")
	_largou = _atk_antes and not premido
	_atk_antes = premido
	_counter_t = maxf(0.0, _counter_t - dt)
	_pd_cd = maxf(0.0, _pd_cd - dt)
	_buffer_t = maxf(0.0, _buffer_t - dt)
	if k.is_on_floor():
		_ar_n = 0
	# um pogo que acerta (estado 3) repoe a cadeia aerea: Air combo -> Pogo -> reposicionar
	if k._pogo_estado == 3 and _pogo_antes != 3:
		_ar_n = 0
		_nota("POGO")
		_metr("pogo_acerto", {})
	_pogo_antes = k._pogo_estado
	# carga do Shadow Cleave
	if _hold_ativo:
		if _largou and _carregado:
			pass   # o `tratar_input` deste frame trata do largar (Shadow Cleave)
		elif Input.is_action_pressed("atacar") and k._hurt_t <= 0.0 and k._rolar_restante <= 0.0 \
				and _move == "" and k.is_on_floor():
			_hold_t += dt
			if not _carregado and _hold_t >= CARGA_T:
				_carregado = true
				k._acender_aura(1.0)
				k._pop = 1.0
				Som.toca("carrossel", -12.0, 1.6, 0.0)
				_nota("CARGA!")
		else:
			_hold_ativo = false
			_hold_t = 0.0
			_carregado = false
	# golpe do lab em curso
	if _move != "":
		_move_t += dt
		var d: Dictionary = MOVES[_move]
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
	# ---- durante um golpe do lab
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
	var passo := clampi(k._combo_passo, 0, Koliani.NUM_COMBO - 1)
	var prog := 1.0 - k._ataque_restante / k._ataque_dur
	return prog >= float(Koliani.ATAQUE_ATIVO_FIM[passo]) or prog >= 0.5


func _durante_move(cima: bool) -> bool:
	var d: Dictionary = MOVES[_move]
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
	var d: Dictionary = MOVES[nome]
	k._cancelar_ataque()
	k.lab_golpe_custom = true
	_move = nome
	_move_t = 0.0
	_move_acertou = false
	_move_atingidos.clear()
	_buffer_t = 0.0
	_buffer_pedido = false
	var total: float = float(d["startup"]) + float(d["ativo"]) + float(d["recup"])
	k._ataque_no_ar = not k.is_on_floor()
	k._combo_passo = int(d["passo_visual"])
	k._ataque_dur = total
	k._ataque_restante = total
	# o dash attack abre a janela do combo normal (o proximo ATAQUE continua no golpe 2)
	k._combo_janela = total + Koliani.JANELA_COMBO if nome == "dash" else 0.0
	k._combo_pedido = false
	k._pop = 1.0
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
		var dano := maxi(1, roundi(k._dano_golpe() * float(d["mult"])))
		var crit := k._pos_roll_t > 0.0
		var info := {"tipo": _move, "dano": dano, "dir": signf(k._olha_para), "critico": crit,
			"guard_break": bool(d["guard_break"]), "passo": 0, "ar": false}
		var res: Dictionary = {}
		if e.has_method("lab_hit"):
			res = e.lab_hit(info)
		else:
			e.receber_dano(dano, signf(k._olha_para), crit, 200.0)
		_energia(_move, float(d["energia"]))
		k._pop_impacto(e.global_position, _move in ["cleave", "counter"])
		k._abanar(Koliani.TREMOR_REMATE if _move in ["cleave", "counter"] else Koliani.TREMOR_GOLPE)
		k._hitstop(float(d["hitstop"]))
		Som.toca("acerto_critico" if _move in ["cleave", "counter"] else "acerto", -7.0, 1.0, 0.03)
		_nota("%s>%s" % [_move, String(res.get("efeito", ""))])


# ---------------------------------------------------------------- Perfect Dodge
## Chamado pela Koliani quando um golpe inimigo chega enquanto ela esta' invulneravel.
func tentativa_de_dano(quantidade: int) -> void:
	if k._rolar_restante <= 0.0 or _pd_cd > 0.0:
		return
	var decorrido: float = Koliani.DUR_ROLAR - k._rolar_restante
	if decorrido > PD_JANELA:
		_metr("dodge_cedo", {"decorrido": decorrido})
		return
	_pd_cd = PD_COOLDOWN
	_counter_t = COUNTER_JANELA
	_energia("perfect_dodge", ENERGIA_PD)
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
