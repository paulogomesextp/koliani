class_name LabInimigo
extends DemonioBase
## COMBAT LAB v1 -- os DOIS inimigos de teste. Variantes do Goblin e do Golem SO' para o lab:
## nao alteram nenhuma cena nem numero de producao (herdam o visual do DemonioBase, mas
## tem IA e reaccao a golpes proprias). Ver `docs/combat_lab_v1.md`.
##
##   GOBLIN  leve: pode ser LANCADO (launcher), aguenta juggle curto (3 elevacoes), ataca com um
##           bote telegrafado (0,50 s). Anti stun-lock: cada hitstun seguido encolhe 25 % e ao 4.o
##           ganha 1,0 s de super-armadura; depois de cair fica 1,2 s imune a launcher.
##   GOLEM   pesado: NAO e' lancado nem interrompido por golpes normais. Tem GUARDA: golpe de frente
##           conta 20 % do dano e gasta guarda; Shadow Cleave / Shadow Counter (ou guarda a 0)
##           QUEBRAM-NA: 1,6 s exposto (x1,4 de dano). Pelas costas e' dano inteiro. Ataques
##           telegrafados: SLAM (0,85 s) e SWEEP (0,60 s, baixo: salta-se).

signal lab_estado_mudou(estado: String)

enum E { APROX, WINDUP, ATIVO, RECUP, HITSTUN, LANCADO, CAIDO, QUEBRADO, IDLE, ESCAPE }

@export_enum("goblin", "golem") var lab_tipo := "goblin"
## Semente do sorteio de ataques do golem (testes usam valor fixo).
@export var lab_semente := 7

# ---- Goblin -----------------------------------------------------------------
const GOB_VIDA := 500
const GOB_DANO := 14
const GOB_VEL := 80.0
const GOB_WINDUP := 0.50
const GOB_ATIVO := 0.14
const GOB_LUNGE := 320.0
const GOB_RECUP := 0.70
const GOB_LANCA_V := 560.0
const GOB_LIFT_V := 170.0
const GOB_JUGGLE_MAX := 3
const GOB_CAIDO := 0.5
const GOB_IMUNE_LANCA := 0.8
const HITSTUN := {"normal0": 0.22, "normal1": 0.26, "normal2": 0.34, "normal3": 0.40,
	"launcher": 0.30, "dash": 0.30, "cleave": 0.80, "counter": 1.00, "pogo": 0.30}
# ANTI-SPAM v1.1: depois de 3 golpes LEVES terrestres seguidos (janela 0,8 s entre golpes) o 4.o mal o
# prende (hitstun x0,25) e o goblin ganha super-armadura (0,9 s) e RECUA (0,28 s) para retomar a
# iniciativa. Launcher / Cleave / Counter e golpes no ar NAO contam nem sao travados pela armadura.
const SEQ_JANELA := 0.8
const SEQ_LIVRES := 3
const ESCAPE_HITSTUN_MULT := 0.25
const ESCAPE_ARMADURA_T := 0.9
const ESCAPE_RECUO_VEL := 340.0
const ESCAPE_DUR := 0.32
const GOLPES_LEVES := ["normal", "dash", "pogo"]
const ESCAPE_WINDUP := 0.30   # o contra-bote apos o escape e' mais curto (mas telegrafado)
# regra v1 (so' para MEDIR o antes/depois): encolher 25 % por hitstun seguido em 2 s; armadura ao 4.o
const STUN_ENCOLHE := 0.75
const STUN_JANELA := 2.0
const STUN_ARMADURA_APOS := 4
const STUN_ARMADURA_T := 1.0
# ---- Golem ------------------------------------------------------------------
const GOL_VIDA := 2000
const GOL_VEL := 50.0
const GOL_GUARDA := 100.0
const GOL_CHIP := 0.20
const GOL_QUEBRA_T := 1.6
const GOL_QUEBRA_DANO := 1.4
const GOL_QUEBRA_IMUNE := 3.0
const GOL_SLAM := {"windup": 0.85, "ativo": 0.16, "recup": 0.90, "alcance": 110.0, "dano": 28, "baixo": false}
const GOL_SWEEP := {"windup": 0.60, "ativo": 0.20, "recup": 0.70, "alcance": 150.0, "dano": 22, "baixo": true}
const GOL_IDLE := 0.8
const GUARDA_CUSTO := {"normal": 5.0, "launcher": 8.0, "dash": 8.0, "pogo": 10.0}

var lab_estado := E.APROX
var _t := 0.0
var _tempo := 0.0
var _rng := RandomNumberGenerator.new()
var _ataque := {}
var _acertou_neste_ataque := false
var _cd := 0.0
# reaccao
var _juggle := 0
var _g_mult := 1.0
var _imune_lanca_t := 0.0
var _seq_hits := 0
var _seq_ult_t := -99.0
var _armadura_t := 0.0
var _escape_pendente := false
var escapes := 0
var _windup_dur := GOB_WINDUP
var _stun_stacks := 0
var _stun_ult_t := -99.0
@export var regra_v1 := false
## Dano de CONTACTO (nao e' um ataque): 0 por omissao; os testes ligam-no para provar que o
## Perfect Dodge nao conta contacto.
@export var lab_contato_dano := 0
# golem
var guarda := GOL_GUARDA
var _quebra_imune_t := 0.0
# metricas
var _primeiro_golpe_t := -1.0
var dano_recebido_total := 0.0
var lab_arena_x := Vector2(-INF, INF)


func _ready() -> void:
	super._ready()
	_rng.seed = lab_semente
	if lab_tipo == "goblin":
		vida = GOB_VIDA
		especie = "goblin"
	else:
		vida = GOL_VIDA
	_vida_ini = vida
	dano_contacto = 0
	add_to_group("lab_inimigos")
	if lab_tipo == "golem":
		_entrar(E.IDLE)
		_t = GOL_IDLE
	else:
		_entrar(E.APROX)


func _ao_tocar(corpo: Node) -> void:
	# O CONTACTO nao e' um ataque: fere (se ligado nos testes) SEM origem "ataque" => nunca da' Perfect Dodge.
	if lab_contato_dano > 0 and not _morto and corpo is Koliani:
		corpo.receber_dano(lab_contato_dano, signf(corpo.global_position.x - global_position.x))


func lab_vida_max() -> int:
	return GOB_VIDA if lab_tipo == "goblin" else GOL_VIDA


func lab_lancavel() -> bool:
	return lab_tipo == "goblin"


func nome_estado() -> String:
	return String(E.keys()[lab_estado])


func _entrar(e: E) -> void:
	lab_estado = e
	_t = 0.0
	lab_estado_mudou.emit(nome_estado())


func _koliani() -> Node2D:
	return get_tree().get_first_node_in_group("koliani") as Node2D


func hurtbox() -> Rect2:
	for c in get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			var cs := c as CollisionShape2D
			var tam: Vector2 = ((cs.shape as RectangleShape2D).size) * scale.abs()
			return Rect2(global_position + cs.position * scale - tam * 0.5, tam)
	return Rect2(global_position - Vector2(20, 48), Vector2(40, 64))


func _fisica_base(dt: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt * _g_mult
	elif velocity.y > 0.0:
		velocity.y = 0.0
	move_and_slide()
	if lab_arena_x.x > -INF:
		global_position.x = clampf(global_position.x, lab_arena_x.x, lab_arena_x.y)


func _encarar(k: Node2D) -> void:
	var d := signf(k.global_position.x - global_position.x)
	if d != 0.0:
		_direcao = d
		if _sprite:
			_sprite.scale.x = _direcao


func _telegrafo_visual(ligado: bool) -> void:
	anticipacao = 1.0 if ligado else 0.0
	_telegrafo = 0.3 if ligado else 0.0
	if _anim:
		_anim.modulate = Color(1.9, 0.6, 0.5) if ligado else Color(1, 1, 1)


func _physics_process(dt: float) -> void:
	if _morto:
		return
	_tempo += dt
	_t += dt
	_cd = maxf(0.0, _cd - dt)
	_imune_lanca_t = maxf(0.0, _imune_lanca_t - dt)
	_armadura_t = maxf(0.0, _armadura_t - dt)
	_quebra_imune_t = maxf(0.0, _quebra_imune_t - dt)
	var k := _koliani()
	if lab_tipo == "goblin":
		_ia_goblin(dt, k)
	else:
		_ia_golem(dt, k)


# =================================================================== GOBLIN ===
func _ia_goblin(dt: float, k: Node2D) -> void:
	match lab_estado:
		E.APROX:
			if k:
				_encarar(k)
			var dx := (k.global_position.x - global_position.x) if k else 999.0
			if k and absf(dx) < 520.0 and absf(dx) > 60.0:
				velocity.x = signf(dx) * GOB_VEL
			else:
				velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
			_fisica_base(dt)
			if k and absf(dx) <= 80.0 and _cd <= 0.0 and is_on_floor() \
					and absf(k.global_position.y - global_position.y) < 60.0:
				velocity.x = 0.0
				_acertou_neste_ataque = false
				_windup_dur = GOB_WINDUP
				_telegrafo_visual(true)
				get_tree().call_group("lab_metricas", "registar", "goblin_windup", {})
				_entrar(E.WINDUP)
		E.WINDUP:
			velocity.x = 0.0
			if k:
				_encarar(k)
			_fisica_base(dt)
			if _t >= _windup_dur:
				_telegrafo_visual(false)
				get_tree().call_group("lab_metricas", "registar", "goblin_bote", {})
				_entrar(E.ATIVO)
		E.ATIVO:
			velocity.x = _direcao * GOB_LUNGE
			_fisica_base(dt)
			if k and not _acertou_neste_ataque and _perto_de(k, 52.0, 56.0):
				_acertou_neste_ataque = true
				get_tree().call_group("lab_metricas", "registar", "goblin_acertou",
					{"dano": GOB_DANO})
				k.receber_dano(GOB_DANO, _direcao, "ataque")
			if _t >= GOB_ATIVO:
				velocity.x = 0.0
				_entrar(E.RECUP)
		E.RECUP:
			velocity.x = move_toward(velocity.x, 0.0, 1500.0 * dt)
			_fisica_base(dt)
			if _t >= GOB_RECUP:
				_cd = 0.8
				_entrar(E.APROX)
		E.HITSTUN:
			velocity.x = move_toward(velocity.x, 0.0, RECUO_ATRITO * dt)
			_fisica_base(dt)
			if _t >= _hitstun_dur:
				if _escape_pendente:
					_escape_pendente = false
					_entrar(E.ESCAPE)
				else:
					_entrar(E.APROX)
		E.ESCAPE:
			# recua e retoma a iniciativa: super-armadura activa, ataca logo que possa
			velocity.x = -_direcao * ESCAPE_RECUO_VEL * (1.0 - _t / ESCAPE_DUR)
			_fisica_base(dt)
			if _t >= ESCAPE_DUR:
				# retoma a INICIATIVA: contra-bote telegrafado (0,30 s) para quem continua a martelar parado
				velocity.x = 0.0
				_acertou_neste_ataque = false
				_windup_dur = ESCAPE_WINDUP
				_telegrafo_visual(true)
				get_tree().call_group("lab_metricas", "registar", "goblin_windup", {"escape": true})
				_entrar(E.WINDUP)
		E.LANCADO:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * dt)
			_fisica_base(dt)
			if is_on_floor() and _t > 0.06:
				_g_mult = 1.0
				_juggle = 0
				_imune_lanca_t = GOB_IMUNE_LANCA
				_entrar(E.CAIDO)
		E.CAIDO:
			velocity.x = 0.0
			_fisica_base(dt)
			if _t >= GOB_CAIDO:
				_entrar(E.APROX)
		_:
			_fisica_base(dt)


var _hitstun_dur := 0.0


func _perto_de(k: Node2D, ax: float, ay: float) -> bool:
	return absf(k.global_position.x - global_position.x) <= ax \
		and absf(k.global_position.y - global_position.y) <= ay


# =================================================================== GOLEM ====
func _ia_golem(dt: float, k: Node2D) -> void:
	match lab_estado:
		E.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
			if k:
				_encarar(k)
			_fisica_base(dt)
			if _t >= GOL_IDLE and k:
				_entrar(E.APROX)
		E.APROX:
			if k:
				_encarar(k)
			var dx := (k.global_position.x - global_position.x) if k else 999.0
			var alvo_alc: float = float((GOL_SWEEP if _ataque_prox_sweep else GOL_SLAM)["alcance"]) * 0.85
			if k and absf(dx) > alvo_alc:
				velocity.x = signf(dx) * GOL_VEL
			else:
				velocity.x = 0.0
			_fisica_base(dt)
			if k and absf(dx) <= alvo_alc + 8.0 and is_on_floor():
				_ataque = (GOL_SWEEP if _ataque_prox_sweep else GOL_SLAM).duplicate()
				_ataque_prox_sweep = _rng.randf() < 0.5
				_acertou_neste_ataque = false
				_telegrafo_visual(true)
				_entrar(E.WINDUP)
		E.WINDUP:
			velocity.x = 0.0
			_fisica_base(dt)
			if _t >= float(_ataque["windup"]):
				_telegrafo_visual(false)
				_entrar(E.ATIVO)
		E.ATIVO:
			velocity.x = 0.0
			_fisica_base(dt)
			if k and not _acertou_neste_ataque and _golem_acerta(k):
				_acertou_neste_ataque = true
				get_tree().call_group("lab_metricas", "registar", "golem_acertou",
					{"dano": int(_ataque["dano"]), "ataque": "sweep" if _ataque["baixo"] else "slam"})
				k.receber_dano(int(_ataque["dano"]), _direcao, "ataque")
			if _t >= float(_ataque["ativo"]):
				_entrar(E.RECUP)
		E.RECUP:
			velocity.x = 0.0
			_fisica_base(dt)
			if _t >= float(_ataque["recup"]):
				_entrar(E.IDLE)
		E.QUEBRADO:
			velocity.x = move_toward(velocity.x, 0.0, RECUO_ATRITO * dt)
			_fisica_base(dt)
			if _t >= GOL_QUEBRA_T:
				guarda = GOL_GUARDA
				_quebra_imune_t = GOL_QUEBRA_IMUNE
				if _anim:
					_anim.modulate = Color(1, 1, 1)
				_entrar(E.IDLE)
		_:
			_fisica_base(dt)


var _ataque_prox_sweep := false


func _golem_acerta(k: Node2D) -> bool:
	var dx := (k.global_position.x - global_position.x) * _direcao
	if dx < -20.0 or dx > float(_ataque["alcance"]):
		return false
	if absf(k.global_position.y - global_position.y) > 70.0:
		return false
	# o SWEEP e' baixo: quem esta' no ar por cima passa
	if bool(_ataque["baixo"]) and k.get("_ataque_no_ar") != null and not k.is_on_floor():
		return false
	return true


func golem_guarda_ativa() -> bool:
	return lab_tipo == "golem" and guarda > 0.0 and lab_estado in [E.IDLE, E.APROX]


# ================================================================= REACCAO ====
## Golpe normal da espada (o hitbox de producao chama `receber_dano`): traduz para `lab_hit`.
func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false,
		_forca_recuo := 0.0) -> void:
	var passo: int = int(get_meta("lab_passo", -1))
	var no_ar: bool = bool(get_meta("lab_ar", false))
	if has_meta("lab_passo"):
		remove_meta("lab_passo")
		remove_meta("lab_ar")
	var tipo := "normal" if passo >= 0 else "pogo"
	lab_hit({"tipo": tipo, "dano": quantidade, "dir": dir_empurrao, "passo": maxi(passo, 0),
		"ar": no_ar, "critico": critico})


## Entrada UNICA de golpes do lab. `info`: tipo (normal/launcher/dash/cleave/counter/pogo),
## dano, dir, passo, ar, critico, guard_break, lanca.
func lab_hit(info: Dictionary) -> Dictionary:
	var res := {"aplicado": false, "dano": 0.0, "efeito": "", "lancado": false}
	if _morto:
		return res
	if _primeiro_golpe_t < 0.0:
		_primeiro_golpe_t = _tempo
	var tipo: String = info["tipo"]
	var dano := float(info["dano"])
	if bool(info.get("critico", false)):
		dano *= CRIT_MULT
	var dir := signf(float(info.get("dir", 0.0)))
	if lab_tipo == "goblin":
		res = _goblin_recebe(tipo, dano, dir, info)
	else:
		res = _golem_recebe(tipo, dano, dir, info)
	res["aplicado"] = true
	dano_recebido_total += float(res["dano"])
	get_tree().call_group("lab_metricas", "registar", "hit", {
		"alvo": lab_tipo, "tipo": tipo, "dano": res["dano"], "efeito": res["efeito"],
		"passo": int(info.get("passo", 0)), "vida": vida, "estado": nome_estado()})
	if vida <= 0:
		_lab_morrer()
	else:
		piscar_dano()
	return res


func _stun_dur_v1(base: float, forte: bool) -> float:
	var agora := _tempo
	if agora - _stun_ult_t <= STUN_JANELA:
		_stun_stacks += 1
	else:
		_stun_stacks = 0
	_stun_ult_t = agora
	var d := base if forte else base * pow(STUN_ENCOLHE, float(_stun_stacks))
	if _stun_stacks >= STUN_ARMADURA_APOS:
		_armadura_t = STUN_ARMADURA_T
		_stun_stacks = 0
	return d


func _goblin_recebe(tipo: String, dano: float, dir: float, info: Dictionary) -> Dictionary:
	var res := {"dano": dano, "efeito": "", "lancado": false}
	vida -= int(round(dano))
	if vida <= 0:
		return res
	var chave: String = tipo if tipo != "normal" else "normal%d" % clampi(int(info.get("passo", 0)), 0, 3)
	var base: float = float(HITSTUN.get(chave, 0.25))
	var no_chao := is_on_floor() and lab_estado != E.LANCADO
	if tipo == "launcher" and no_chao and _imune_lanca_t <= 0.0:
		velocity = Vector2(dir * 60.0, -GOB_LANCA_V)
		_juggle = 1
		_g_mult = 1.0
		_telegrafo_visual(false)
		_entrar(E.LANCADO)
		res["efeito"] = "lancado"
		res["lancado"] = true
		return res
	if not no_chao:
		# juggle: no ar cada golpe levanta um pouco, ate' ao tecto de elevacoes; depois cai mais depressa
		if _juggle < GOB_JUGGLE_MAX:
			_juggle += 1
			velocity.y = -GOB_LIFT_V
			res["efeito"] = "juggle%d" % _juggle
		else:
			_g_mult = 1.6
			res["efeito"] = "juggle_max"
		velocity.x = dir * 40.0
		if lab_estado != E.LANCADO:
			_entrar(E.LANCADO)
		return res
	if tipo == "launcher":
		res["efeito"] = "lanca_imune"
	var leve: bool = tipo in GOLPES_LEVES
	if regra_v1:
		if _armadura_t > 0.0:
			res["efeito"] = "armadura"
			return res
		_hitstun_dur = _stun_dur_v1(base, tipo in ["cleave", "counter"])
		var f1: float = {"cleave": 300.0, "counter": 520.0, "dash": 200.0}.get(tipo, 90.0 + 40.0 * float(info.get("passo", 0)))
		velocity.x = dir * f1
		_telegrafo_visual(false)
		_entrar(E.HITSTUN)
		res["efeito"] = "hitstun v1 %.2f" % _hitstun_dur
		return res
	if leve and _armadura_t > 0.0:
		res["efeito"] = "armadura"
		return res
	_hitstun_dur = base
	if leve:
		if _tempo - _seq_ult_t > SEQ_JANELA:
			_seq_hits = 0
		_seq_ult_t = _tempo
		_seq_hits += 1
		if _seq_hits > SEQ_LIVRES:
			# o 4.o golpe leve seguido: quase nao prende, da' armadura e faz o goblin recuar
			_hitstun_dur = base * ESCAPE_HITSTUN_MULT
			_armadura_t = ESCAPE_ARMADURA_T
			_escape_pendente = true
			escapes += 1
			_seq_hits = 0
			res["efeito"] = "escape"
	# v1.2: o recuo do combo basico e' curto e crescente-suave; o 4.o golpe NAO atira o goblin para fora do golpe seguinte
	var f: float = {"cleave": 300.0, "counter": 520.0, "dash": 200.0}.get(tipo, [70.0, 80.0, 90.0, 100.0][clampi(int(info.get("passo", 0)), 0, 3)])
	velocity.x = dir * f
	_telegrafo_visual(false)
	_entrar(E.HITSTUN)
	res["efeito"] = (res["efeito"] + " " if res["efeito"] != "" else "") + "hitstun %.2f" % _hitstun_dur
	return res


func _golem_recebe(tipo: String, dano: float, dir: float, info: Dictionary) -> Dictionary:
	var res := {"dano": 0.0, "efeito": "", "lancado": false}
	var quebrador: bool = tipo in ["cleave", "counter"] or bool(info.get("guard_break", false))
	var frente := tipo == "pogo" or signf(dir) == -_direcao or dir == 0.0
	if lab_estado == E.QUEBRADO:
		res["dano"] = dano * GOL_QUEBRA_DANO
		vida -= int(round(res["dano"]))
		res["efeito"] = "exposto"
		return res
	if quebrador and _quebra_imune_t <= 0.0:
		res["dano"] = dano
		vida -= int(round(dano))
		_quebrar()
		res["efeito"] = "guarda_quebrada"
		return res
	if golem_guarda_ativa() and frente:
		res["dano"] = dano * GOL_CHIP
		vida -= int(round(res["dano"]))
		var custo: float = float(GUARDA_CUSTO.get(tipo, 5.0)) if not quebrador else 25.0
		guarda = maxf(0.0, guarda - custo)
		res["efeito"] = "guardado"
		if guarda <= 0.0:
			_quebrar()
			res["efeito"] = "guarda_esgotada"
		return res
	# sem guarda (a atacar / pelas costas / pogo em recuperacao): dano inteiro, sem interromper
	res["dano"] = dano
	vida -= int(round(dano))
	res["efeito"] = "sem_guarda" + (" costas" if not frente else "")
	return res


func _quebrar() -> void:
	guarda = 0.0
	_telegrafo_visual(false)
	if _anim:
		_anim.modulate = Color(0.7, 0.9, 1.6)
	_entrar(E.QUEBRADO)


func _lab_morrer() -> void:
	_morto = true
	velocity = Vector2.ZERO
	var ttk := _tempo - _primeiro_golpe_t if _primeiro_golpe_t >= 0.0 else 0.0
	get_tree().call_group("lab_metricas", "registar", "morreu", {"alvo": lab_tipo, "ttk": ttk})
	collision_layer = 0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)
