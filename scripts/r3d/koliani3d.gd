class_name Koliani3D
extends CharacterBody3D
## Koliani 3D -- controlador jogavel da Regiao I em 3D.
##
## Traduz o FEEL do controlador 2D aprovado (`movimento.gd` / `koliani.gd`),
## nao os numeros em pixeis:
##   2D: corrida 240 px/s, salto ~122 px (1,35 corpos), apice em 0,42 s,
##       queda x1,22, apice suave (<60 px/s -> gravidade x0,5), coyote 0,10 s,
##       buffer 0,12 s, corte de salto 0,45, aceleracao ate' ao maximo ~0,1 s.
##   3D: corrida 6,6 m/s, salto ~2,0 m (1,15 corpos), apice em ~0,40 s, mesmos
##       tempos de coyote/buffer/corte/apice. Combo de 4 golpes com os mesmos
##       multiplicadores de dano (0,85/1/1,25/1,9), janela de encadear 0,42 s,
##       i-frames 0,6 s, vida 100 (`VIDA_MAXIMA`).
##
## Mantem o contrato da HUD existente: grupo "koliani" e os sinais
## `vida_mudou` / `energia_mudou` / `morreu`.

signal morreu
signal vida_mudou(atual: int, maximo: int)
signal energia_mudou(atual: float, maximo: float)
signal energia_insuficiente()

const MODELO := preload("res://scripts/r3d/koliani_modelo3d.gd")
const VFX := preload("res://scripts/r3d/vfx3d.gd")

const VIDA_MAXIMA := 100
const VEL := 6.6
const ACEL_CHAO := 62.0
const DESACEL_CHAO := 58.0
const VIRAGEM_CHAO := 95.0
const ACEL_AR := 40.0
const DESACEL_AR := 22.0
const GRAVIDADE := 24.0
const GRAV_QUEDA := 1.22
const APEX_LIMIAR := 1.0
const APEX_GRAV := 0.5
const VEL_MAX_QUEDA := 26.0
const FORCA_SALTO := 9.7
const FORCA_SALTO_DUPLO := 8.6
const CORTE_SALTO := 0.45
const COYOTE := 0.10
const BUFFER_SALTO := 0.12
const I_FRAMES := 0.6
const DUR_COMBO := [0.27, 0.3, 0.42, 0.42]
const ATIVO_INI := [0.22, 0.2, 0.24, 0.3]
const ATIVO_FIM := [0.68, 0.7, 0.74, 0.78]
const DANO_COMBO := [0.85, 1.0, 1.25, 1.9]
const RECUO_COMBO := [2.5, 3.5, 5.0, 9.0]
const AVANCO := [3.2, 3.6, 3.8, 4.6]
const JANELA_COMBO := 0.42
const ALCANCE := 2.0
const SOM_COMBO := ["ataque", "ataque2", "ataque3", "ataque_forte"]
const VOL_COMBO := [-8.0, -7.0, -6.0, -3.0]
const VEL_DASH := 15.0
const DUR_DASH := 0.18
const RECARGA_DASH := 0.55

var vida := VIDA_MAXIMA
var modelo: KolianiModelo3D
var camara: Node  # CamaraR3D
var controlo_externo := false   ## bots/testes escrevem `entrada_*`
var entrada_mov := Vector2.ZERO
var entrada_salto := false
var entrada_ataque := false
var invulneravel_debug := false

var _coyote := 0.0
var _buffer := 0.0
var _cortou := false
var _saltos_ar := 0
var _estava_chao := true
var _vel_queda := 0.0
var _iframes := 0.0
var _dano_t := 0.0
var _morto := false
var _ataque_t := -1.0
var _golpe := 0
var _combo_janela := 0.0
var _ataque_pedido := false
var _atingidos: Array = []
var _passo_t := 0.0
var _passo_var := 0
var _dash_t := 0.0
var _dash_rec := 0.0
var _dash_dir := Vector3.ZERO
var _rumo := 0.0
var _ultimo_seguro := Vector3.ZERO
var _seguro_t := 0.0
var _rasto: Node3D
var _salto_seguro_prev := false
var y_morte := -30.0


func _ready() -> void:
	add_to_group("koliani")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(50)
	var forma := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.7
	forma.shape = cap
	forma.position.y = 0.85
	add_child(forma)
	modelo = MODELO.new()
	add_child(modelo)
	_rumo = rotation.y
	rotation.y = 0.0
	modelo.rotation.y = _rumo
	_ultimo_seguro = global_position
	_rasto = VFX.rasto_espada(self, modelo)
	_retrato_hud()
	vida_mudou.emit.call_deferred(vida, VIDA_MAXIMA)


## A HUD aprovada tira o retrato do 1.o frame de `Sprite/Corpo` (idle). Damos-lhe
## o mesmo fotograma do Golden Set, num no' 2D invisivel.
func _retrato_hud() -> void:
	var caminho := "res://assets/sprites/koliani_golden_set/frames/idle/idle_001.png"
	if not ResourceLoader.exists(caminho):
		return
	var sf := SpriteFrames.new()
	sf.add_frame("default", load(caminho))
	if not sf.has_animation("idle"):
		sf.add_animation("idle")
	sf.add_frame("idle", load(caminho))
	var s := Node2D.new()
	s.name = "Sprite"
	s.visible = false
	var corpo := AnimatedSprite2D.new()
	corpo.name = "Corpo"
	corpo.sprite_frames = sf
	corpo.animation = "idle"
	s.add_child(corpo)
	add_child(s)


func vida_maxima() -> int:
	return VIDA_MAXIMA


func esta_morta() -> bool:
	return _morto


func _ler_entrada() -> void:
	if controlo_externo:
		return
	entrada_mov = Vector2(Input.get_axis("mover_esquerda", "mover_direita"),
		Input.get_axis("mirar_baixo", "mirar_cima"))
	if entrada_mov.length() > 1.0:
		entrada_mov = entrada_mov.normalized()


func _unhandled_input(ev: InputEvent) -> void:
	if controlo_externo or _morto:
		return
	if ev.is_action_pressed("saltar"):
		_buffer = BUFFER_SALTO
	if ev.is_action_released("saltar"):
		_soltar_salto()
	if ev.is_action_pressed("atacar"):
		_ataque_pedido = true
	if ev.is_action_pressed("dash") and EstadoJogo.tem_habilidade("dash"):
		_pedir_dash()


## API para bots/testes (sem eventos de input).
func bot_saltar() -> void:
	_buffer = BUFFER_SALTO


func bot_largar_salto() -> void:
	_soltar_salto()


func bot_atacar() -> void:
	_ataque_pedido = true


func _soltar_salto() -> void:
	if velocity.y > 0.0 and not _cortou:
		velocity.y *= CORTE_SALTO
		_cortou = true


func _direcao_mundo(m: Vector2) -> Vector3:
	var frente := Vector3.FORWARD
	var direita := Vector3.RIGHT
	var cam := get_viewport().get_camera_3d()
	if cam:
		frente = -cam.global_transform.basis.z
		frente.y = 0.0
		frente = frente.normalized()
		direita = cam.global_transform.basis.x
		direita.y = 0.0
		direita = direita.normalized()
	return direita * m.x + frente * m.y


func _physics_process(dt: float) -> void:
	if _morto:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * dt)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * dt)
		velocity.y -= GRAVIDADE * dt
		move_and_slide()
		return
	_ler_entrada()
	var no_chao := is_on_floor()
	_iframes = maxf(_iframes - dt, 0.0)
	_dano_t = maxf(_dano_t - dt, 0.0)
	_buffer = maxf(_buffer - dt, 0.0)
	_dash_rec = maxf(_dash_rec - dt, 0.0)
	_combo_janela = maxf(_combo_janela - dt, 0.0)
	modelo.flash(1.0 if _dano_t > 0.17 else 0.0)
	modelo.visible = not (_iframes > 0.0 and _dano_t <= 0.0 and fmod(_iframes, 0.12) < 0.04)
	if no_chao:
		_coyote = COYOTE
		_saltos_ar = 0
		_cortou = false
	else:
		_coyote = maxf(_coyote - dt, 0.0)
	# aterragem
	if no_chao and not _estava_chao:
		var f := clampf(_vel_queda / 18.0, 0.0, 1.0)
		modelo.aterrou(0.4 + f)
		var tier := 1 if _vel_queda < 10.0 else (2 if _vel_queda < 17.0 else 3)
		Som.toca(["", "aterrar", "aterrar_medio", "aterrar_pesado"][tier], [0.0, -8.0, -9.0, -9.0][tier],
			1.0, 0.02, 0.0, "", Som.Prioridade.MEDIA if tier >= 3 else Som.Prioridade.NORMAL)
		if tier >= 2:
			VFX.poeira(get_parent(), global_position, 0.5 + 0.3 * tier)
			if camara and camara.has_method("abanar"):
				camara.abanar(0.05 * tier)
	_estava_chao = no_chao
	if not no_chao:
		_vel_queda = maxf(-velocity.y, 0.0)

	var desejo := _direcao_mundo(entrada_mov)
	var atacando := _ataque_t >= 0.0
	# --- dash ---
	if _dash_t > 0.0:
		_dash_t -= dt
		velocity = _dash_dir * VEL_DASH
		velocity.y = 0.0
		modelo.estado = "dash"
		move_and_slide()
		return
	# --- horizontal ---
	var hv := Vector3(velocity.x, 0, velocity.z)
	var alvo := desejo * VEL
	if atacando and no_chao:
		alvo = desejo * VEL * 0.15
	if _dano_t > 0.0:
		alvo = Vector3.ZERO
	var acel: float
	if no_chao:
		if alvo.length() < 0.05:
			acel = DESACEL_CHAO
		elif hv.length() > 0.5 and hv.normalized().dot(alvo.normalized()) < -0.2:
			acel = VIRAGEM_CHAO
		else:
			acel = ACEL_CHAO
	else:
		acel = ACEL_AR if alvo.length() > 0.05 else DESACEL_AR
	if _dano_t > 0.0:
		acel = 8.0
	hv = hv.move_toward(alvo, acel * dt)
	# --- vertical ---
	var g := GRAVIDADE
	if velocity.y < 0.0:
		g *= GRAV_QUEDA
	if absf(velocity.y) < APEX_LIMIAR and not no_chao and not _cortou:
		g *= APEX_GRAV
	velocity.y = maxf(velocity.y - g * dt, -VEL_MAX_QUEDA)
	# --- salto (buffer + coyote + duplo) ---
	if _buffer > 0.0 and not atacando:
		if _coyote > 0.0:
			_saltar(FORCA_SALTO)
			Som.toca("koliani_salto", -10.0, 1.0, 0.03)
		elif _saltos_ar == 0 and EstadoJogo.tem_habilidade("salto_duplo"):
			_saltos_ar = 1
			_saltar(FORCA_SALTO_DUPLO)
			Som.toca("koliani_salto", -11.0, 1.0, 0.03)
			VFX.anel_salto(get_parent(), global_position)
	velocity.x = hv.x
	velocity.z = hv.z
	# --- ataque ---
	_atualizar_ataque(dt, no_chao)
	# --- rumo do modelo ---
	if desejo.length() > 0.1 and not atacando and _dano_t <= 0.0:
		_rumo = rotate_toward(_rumo, atan2(desejo.x, desejo.z), 14.0 * dt)
	modelo.rotation.y = _rumo
	move_and_slide()
	_sons_passo(dt, no_chao)
	_seguranca(dt, no_chao)
	# --- animacao ---
	modelo.no_chao = no_chao
	modelo.vel_h = Vector2(velocity.x, velocity.z).length()
	modelo.vel_y = velocity.y
	if _dano_t > 0.0:
		modelo.estado = "hurt"
	elif _ataque_t >= 0.0:
		modelo.estado = "attack"
	elif not no_chao:
		modelo.estado = "jump" if velocity.y > 0.0 else "fall"
	elif modelo.vel_h > 0.4:
		modelo.estado = "run"
	else:
		modelo.estado = "idle"
	if global_position.y < y_morte:
		_caiu_no_vazio()


func _saltar(forca: float) -> void:
	velocity.y = forca
	_buffer = 0.0
	_coyote = 0.0
	_cortou = false
	floor_snap_length = 0.0
	get_tree().create_timer(0.1).timeout.connect(func() -> void: floor_snap_length = 0.35)


func _pedir_dash() -> void:
	if _dash_rec > 0.0 or _morto:
		return
	var d := _direcao_mundo(entrada_mov)
	if d.length() < 0.1:
		d = Vector3(sin(_rumo), 0, cos(_rumo))
	_dash_dir = d.normalized()
	_dash_t = DUR_DASH
	_dash_rec = RECARGA_DASH
	_iframes = maxf(_iframes, DUR_DASH)
	Som.toca("dash", -11.0, 1.0, 0.03)


## ---------------------------------------------------------------------------
## Combate
## ---------------------------------------------------------------------------

func _atualizar_ataque(dt: float, no_chao: bool) -> void:
	if _ataque_pedido and _dano_t <= 0.0:
		if _ataque_t < 0.0:
			_golpe = (_golpe + 1) % 4 if _combo_janela > 0.0 else 0
			_iniciar_golpe(no_chao)
			_ataque_pedido = false
		elif _ataque_t > DUR_COMBO[_golpe] * 0.55:
			pass  # fica pedido: encadeia quando acabar
		else:
			_ataque_pedido = false
	if _ataque_t < 0.0:
		return
	_ataque_t += dt
	var dur: float = DUR_COMBO[_golpe]
	var f := _ataque_t / dur
	modelo.fase_ataque = f
	modelo.golpe = _golpe
	if f < 0.5 and no_chao:
		var frente := Vector3(sin(_rumo), 0, cos(_rumo))
		var av: float = AVANCO[_golpe] * (1.0 - f * 2.0)
		velocity.x = frente.x * av
		velocity.z = frente.z * av
	var ativo: bool = f >= ATIVO_INI[_golpe] and f <= ATIVO_FIM[_golpe]
	_rasto.set("ativo", ativo)
	if ativo:
		_testar_acertos()
	if f >= 1.0:
		_ataque_t = -1.0
		_rasto.set("ativo", false)
		_combo_janela = JANELA_COMBO
		if _ataque_pedido:
			_ataque_pedido = false
			_golpe = (_golpe + 1) % 4
			_iniciar_golpe(no_chao)


func _iniciar_golpe(_no_chao: bool) -> void:
	_ataque_t = 0.0
	_atingidos.clear()
	# mira suave: vira-se para o inimigo mais proximo dentro de 3,2 m
	var melhor: Node3D = null
	var md := 3.2
	for n in _alvos():
		var d: Vector3 = (n as Node3D).global_position - global_position
		d.y = 0.0
		if d.length() < md:
			md = d.length()
			melhor = n
	if melhor:
		var d := melhor.global_position - global_position
		_rumo = atan2(d.x, d.z)
	elif entrada_mov.length() > 0.2:
		var w := _direcao_mundo(entrada_mov)
		_rumo = atan2(w.x, w.z)
	var tom: float = [1.0, 1.03, 0.97, 0.92][_golpe]
	Som.toca(SOM_COMBO[_golpe], VOL_COMBO[_golpe], lerpf(1.0, tom, 0.35), 0.02)


func _alvos() -> Array:
	var r: Array = []
	for g in ["inimigos3d", "chefes", "alvos3d"]:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node3D and n.has_method("receber_dano") and not bool(n.get("morto")):
				r.append(n)
	return r


func _testar_acertos() -> void:
	var frente := Vector3(sin(_rumo), 0, cos(_rumo))
	var centro := global_position + Vector3.UP * 0.95
	for n in _alvos():
		if n in _atingidos:
			continue
		var raio_alvo: float = float(n.get("raio_corpo")) if n.get("raio_corpo") != null else 0.5
		var alvo_c: Vector3 = n.call("centro_golpe") if n.has_method("centro_golpe") else n.global_position + Vector3.UP
		var d := alvo_c - centro
		var dy := d.y
		d.y = 0.0
		var alcance := ALCANCE + raio_alvo + (0.4 if _golpe == 3 else 0.0)
		if d.length() > alcance or absf(dy) > 1.4 + raio_alvo:
			continue
		var ang := frente.angle_to(d.normalized()) if d.length() > 0.05 else 0.0
		if _golpe != 3 and ang > deg_to_rad(80) and d.length() > raio_alvo + 0.4:
			continue
		_atingidos.append(n)
		var dano := int(round(EstadoJogo.dano_ataque() * DANO_COMBO[_golpe]))
		var critico := _golpe == 3
		n.call("receber_dano", dano, global_position, RECUO_COMBO[_golpe], critico)
		if critico:
			Som.toca("acerto_critico", -6.0, 1.0, 0.02, 0.0, "", Som.Prioridade.MEDIA)
		else:
			Som.toca("acerto", -8.0, 1.0, 0.04)
		VFX.faisca(get_parent(), alvo_c - d.normalized() * raio_alvo * 0.6, critico)
		_hitstop(0.018 if critico else 0.01)
		if camara and camara.has_method("abanar"):
			camara.abanar(0.12 if critico else 0.05)


func _hitstop(dur: float) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0


## Dano recebido (inimigos, perigos, chefe). `origem` = posicao da fonte.
func receber_dano(quantidade: int, origem: Vector3 = Vector3.INF, recuo := 6.0) -> void:
	if _morto or _iframes > 0.0 or invulneravel_debug:
		return
	vida = maxi(vida - quantidade, 0)
	vida_mudou.emit(vida, VIDA_MAXIMA)
	_iframes = I_FRAMES
	_dano_t = 0.25
	_ataque_t = -1.0
	_rasto.set("ativo", false)
	if origem != Vector3.INF:
		var d := global_position - origem
		d.y = 0.0
		d = d.normalized() if d.length() > 0.01 else Vector3(sin(_rumo + PI), 0, cos(_rumo + PI))
		velocity = d * recuo + Vector3.UP * 4.5
		_rumo = atan2(-d.x, -d.z)
	if camara and camara.has_method("abanar"):
		camara.abanar(0.2)
	VFX.faisca(get_parent(), global_position + Vector3.UP, false, Color(1, 0.2, 0.25))
	if vida <= 0:
		_morrer()
		return
	Som.toca("dano_pesado" if quantidade >= 25 else "dano", -7.0, 1.0, 0.02, 0.12, "player_hurt",
		Som.Prioridade.MEDIA)


func curar(q: int) -> void:
	vida = mini(vida + q, VIDA_MAXIMA)
	vida_mudou.emit(vida, VIDA_MAXIMA)


func _morrer() -> void:
	if _morto:
		return
	_morto = true
	modelo.reiniciar_morte()
	modelo.estado = "death"
	modelo.flash(0.0)
	modelo.visible = true
	_rasto.set("ativo", false)
	Som.toca("morte_koliani", -6.0, 1.0, 0.02, 0.0, "", Som.Prioridade.ALTA)
	Engine.time_scale = 1.0
	morreu.emit()
	EstadoJogo.perder_vida()
	if EstadoJogo.sem_vidas():
		EstadoJogo.reiniciar_run()
		Nivel3D.limpar_checkpoint()
	await get_tree().create_timer(1.3).timeout
	if is_inside_tree():
		Transicao.fechar_e(get_tree().reload_current_scene)


## Caiu ao vazio/pantano: perde vida e volta ao ultimo chao seguro (como as
## pocas mortais do 2D, que ferem e repoem a Koliani na margem).
func _caiu_no_vazio() -> void:
	if _morto:
		return
	_iframes = 0.0
	receber_dano(20, Vector3.INF)
	if _morto:
		return
	global_position = _ultimo_seguro + Vector3.UP * 0.3
	velocity = Vector3.ZERO
	_iframes = 1.0
	Som.toca("respawn", -9.0, 1.0, 0.01, 0.0, "", Som.Prioridade.MEDIA)
	if camara and camara.has_method("cortar"):
		camara.cortar()


func _seguranca(dt: float, no_chao: bool) -> void:
	if not no_chao:
		_seguro_t = 0.0
		return
	var col := get_last_slide_collision()
	if col and col.get_collider() and col.get_collider().is_in_group("chao_movel"):
		return
	_seguro_t += dt
	if _seguro_t > 0.25:
		_ultimo_seguro = global_position


func definir_seguro(p: Vector3) -> void:
	_ultimo_seguro = p


func _sons_passo(dt: float, no_chao: bool) -> void:
	var v := Vector2(velocity.x, velocity.z).length()
	if no_chao and v > 1.0 and _ataque_t < 0.0:
		_passo_t -= dt * (v / VEL) * 1.25
		if _passo_t <= 0.0:
			_passo_t = 0.32
			_passo_var = (_passo_var + 1) % 3
			Som.toca("passo%d" % (_passo_var + 1), -24.0, 1.0, 0.08)
	else:
		_passo_t = 0.0
