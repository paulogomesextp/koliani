class_name Koliani
extends CharacterBody2D
## A personagem principal. A física real (colisões, `move_and_slide`) vive
## aqui; o "sentir" do movimento está em `movimento.gd` (lógica pura,
## testável). Ataque leve, dash e rolamento são o mínimo para a pegada
## tipo Dead Cells -- o agente "gaming" expande daqui.

signal morreu
signal vida_mudou(atual: int, maximo: int)
signal energia_mudou(atual: float, maximo: float)
## Emitido sempre que lança o projétil mágico -- a Ala dos Mortos (nível 09)
## usa-o para materializar as plataformas espectrais.
signal magia_lancada

const VIDA_MAXIMA := 100
## Dano corpo-a-corpo SEM arma equipada (ver EstadoJogo.dano_ataque()).
const DANO_ATAQUE := 25


## Vida máxima efetiva = base + bónus da armadura equipada.
func _vida_max() -> int:
	return VIDA_MAXIMA + EstadoJogo.vida_bonus_armadura()


## Dano do golpe = arma equipada, ou a base se não houver arma.
func _dano_golpe() -> int:
	return EstadoJogo.dano_ataque()
const VEL_DASH := 620.0
const DUR_DASH := 0.16
const RECARGA_DASH := 0.55
const VEL_ROLAR := 360.0
const DUR_ROLAR := 0.30
const RECARGA_ROLAR := 0.45
## Escalar paredes (habilidade "escalar_paredes"): encostada a uma parede
## no ar e a segurar na direção dela, agarra-se; W/S sobe/desce; saltar dá
## impulso para fora (não gasta o salto do ar). Sem limite de tempo.
const VEL_ESCALAR := 135.0
## Escorrega sempre por uma parede a que se agarra (px/s para baixo). Não se
## fica fixo -- ↑ trava/sobe, ↓ acelera a descida.
const VEL_DESLIZE_PAREDE := 55.0
const WALLJUMP := Vector2(330.0, -430.0)
const DUR_ATAQUE := 0.18
const I_FRAMES := 0.6
## Defesa (habilidade "escudo"): anda-se devagar de escudo erguido; um
## ataque que venha de frente é bloqueado (sem dano) com um som subtil.
const VEL_DEFESA := 70.0
const BLOQUEIO_IFRAMES := 0.14
## Projétil mágico (habilidade "projetil"): lança em 8 direções, bate igual
## à espada. Gasta uma fração da barra de Energia, que regenera com o
## tempo. 3 disparos antes de esvaziar (33% cada).
const ENERGIA_MAX := 99.0
const CUSTO_PROJETIL := 33.0
const REGEN_ENERGIA := 22.0   # por segundo (barra cheia em ~4.5 s)
const DUR_LANCAR := 0.16
const PROJETIL_MAGICO := preload("res://scenes/actors/ProjetilKoliani.tscn")
## Abaixo deste Y considera-se que caiu no vazio (fosso sem fundo).
const Y_MORTE := 1200.0
const TEX_IMPACTO := preload("res://assets/sprites/impacto.svg")

@onready var _hitbox: Area2D = $HitboxAtaque
@onready var _sprite: Node2D = $Sprite
@onready var _corpo: AnimatedSprite2D = $Sprite/Corpo
@onready var _arma: Sprite2D = $Sprite/Arma
@onready var _rastro: Line2D = $Sprite/Rastro
@onready var _escudo: Node2D = $Sprite/Escudo
@onready var _camera: Camera2D = $Camera2D
@onready var _faiscas: CPUParticles2D = $FaiscasAtaque
@onready var _po: CPUParticles2D = $PoAterragem

var _mov := Movimento.Estado.new()
var vida := VIDA_MAXIMA
var _olha_para := 1.0
var _dash_restante := 0.0
var _dash_recarga := 0.0
var _rolar_restante := 0.0
var _rolar_recarga := 0.0
var _ataque_restante := 0.0
var _invulneravel := 0.0
var _estava_no_chao := true
var _defendendo := false
var _energia := ENERGIA_MAX
var _lancar_restante := 0.0
## Segundos que ainda está preso numa teia (Região III / Rainha Aracnídea):
## enquanto > 0 não anda nem salta -- só se sacode até se soltar.
var _preso := 0.0
## Agarrada a uma parede (habilidade "escalar_paredes"). `_parede_lock` é um
## breve travão depois do salto de parede para não voltar a colar logo.
var _escalando := false
var _parede_lock := 0.0
## Agachada (segura S no chão, parada). Só bloqueia o andar -- visual.
var _agachado := false
## Conta-decrescente para mostrar a animação do salto duplo.
var _djump_t := 0.0
## Segundos que ainda "flutua" (Região I / Coração Putrefacto, fase 2): a
## batida do coração alivia a gravidade -- a queda cai a menos de metade.
var _leve := 0.0
## Escala da gravidade (1 = normal). O Observatório Lunar (nível 14) mete
## zonas de "gravidade lunar" (< 1) e a Sacerdotisa mexe nisto durante a
## luta. Reposto a 1 por `definir_grav_escala(1.0)` ao sair da zona.
var _grav_escala := 1.0
## Multiplicador do input horizontal (-1 = controlos invertidos). O Olho do
## Abismo (nível 20) inverte-os por uns segundos com `inverter_controlos()`.
var _inverso := 1.0
var _inverso_restante := 0.0
## Corrente de ar (Torre dos Ventos, nível 12): `CorrenteAr` chama
## `soprar_para_cima()` a cada frame enquanto a Koliani lá está.
var _vento_restante := 0.0
var _vento_forca := 0.0
var _vento_alvo := 0.0

# animação procedural (visual, corre em _process)
var _mat: ShaderMaterial
var _anim_t := 0.0
var _squash := 0.0   # impulso da aterragem
var _pop := 0.0      # impulso do ataque
## Onde a Koliani nasceu neste nível (spawn ou checkpoint). No modo dev,
## cair num fosso repõe-a aqui em vez de a matar.
var _pos_inicial := Vector2.ZERO


func _ready() -> void:
	if EstadoJogo.checkpoint != Vector2.ZERO:
		global_position = EstadoJogo.checkpoint
	_pos_inicial = global_position
	if _hitbox:
		_hitbox.monitoring = false
		_hitbox.body_entered.connect(_ao_acertar_corpo)
	if _corpo:
		_montar_frames()
	vida = _vida_max()  # nível novo começa cheio (inclui bónus de armadura)
	vida_mudou.emit(vida, _vida_max())
	energia_mudou.emit(_energia, ENERGIA_MAX)
	_aplicar_equipamento()
	EstadoJogo.equipamento_mudou.connect(func(_t: String, _i: String) -> void: _aplicar_equipamento())


## Constrói os SpriteFrames da Koliani a partir das tiras geradas em
## `tools/gerar_sprites.gd` (assets/sprites/pixel/koliani/*.png). Cada tira
## é horizontal, 40 px por frame, virada à direita.
const _KOLI_ANIMS := {
	"idle":      [4, 6.0, true],
	"run":       [6, 12.0, true],
	"jump":      [2, 8.0, false],
	"fall":      [2, 8.0, true],
	"attack":    [4, 22.0, false],
	"crouch":    [2, 6.0, true],
	"wallslide": [2, 8.0, true],
	"djump":     [4, 18.0, false],
}

func _montar_frames() -> void:
	if _corpo.sprite_frames != null:
		return
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for nome: String in _KOLI_ANIMS:
		var cfg: Array = _KOLI_ANIMS[nome]
		sf.add_animation(nome)
		sf.set_animation_speed(nome, cfg[1])
		sf.set_animation_loop(nome, cfg[2])
		var tex: Texture2D = load("res://assets/sprites/pixel/koliani/%s.png" % nome)
		if tex == null:
			continue
		var n: int = cfg[0]
		var fw := tex.get_width() / maxi(1, n)
		for i in n:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, tex.get_height())
			sf.add_frame(nome, at)
	_corpo.sprite_frames = sf
	_corpo.play("idle")


## Mostra a arma equipada na mão. As tiras da Koliani já trazem a lâmina
## roxa da personagem, por isso a `Arma` extra só aparece se houver uma
## arma equipada (fica por cima da mão).
func _aplicar_equipamento() -> void:
	if _arma:
		var wi := Equipamento.indice_arma(EstadoJogo.arma_equipada)
		_arma.visible = wi >= 0
		if wi >= 0:
			_arma.frame = wi
	if _corpo:
		_corpo.modulate = _tint_armadura()


func _physics_process(dt: float) -> void:
	_dash_recarga = maxf(0.0, _dash_recarga - dt)
	_rolar_recarga = maxf(0.0, _rolar_recarga - dt)
	_invulneravel = maxf(0.0, _invulneravel - dt)
	_lancar_restante = maxf(0.0, _lancar_restante - dt)
	_preso = maxf(0.0, _preso - dt)
	_parede_lock = maxf(0.0, _parede_lock - dt)
	_djump_t = maxf(0.0, _djump_t - dt)
	_leve = maxf(0.0, _leve - dt)
	if _inverso_restante > 0.0:
		_inverso_restante -= dt
		if _inverso_restante <= 0.0:
			_inverso = 1.0

	# a barra de Energia regenera-se sozinha depois de usada
	if _energia < ENERGIA_MAX:
		_energia = minf(ENERGIA_MAX, _energia + REGEN_ENERGIA * dt)
		energia_mudou.emit(_energia, ENERGIA_MAX)

	var dir := Input.get_axis("mover_esquerda", "mover_direita") * _inverso
	if dir != 0.0 and _rolar_restante <= 0.0:
		_olha_para = signf(dir)  # o flip visual é feito em _animar()

	# agachar: segura S no chão, sem andar nem estar noutra ação -> não anda
	_agachado = is_on_floor() and Input.is_action_pressed("mirar_baixo") \
		and dir == 0.0 and _ataque_restante <= 0.0 and _rolar_restante <= 0.0 \
		and _dash_restante <= 0.0 and not _defendendo
	if _agachado:
		dir = 0.0

	# teia no chão: NÃO prende -- só abranda muito (anda-se sempre para fora,
	# devagar). O `_preso` decai sozinho no _physics_process e está limitado
	# a `MAX_PRESO`, por isso uma teia permanente nunca deixa a Koliani presa.
	if _preso > 0.0:
		dir *= 0.34

	# escalar paredes: encostada a uma parede no ar, a segurar na direção dela
	if EstadoJogo.tem_habilidade("escalar_paredes") and _parede_lock <= 0.0 \
			and not is_on_floor() and is_on_wall_only() \
			and _dash_restante <= 0.0 and _rolar_restante <= 0.0:
		var nx := signf(get_wall_normal().x)
		if not _escalando and dir != 0.0 and signf(dir) == -nx:
			_escalando = true
		elif _escalando and dir != 0.0 and signf(dir) == nx:
			_escalando = false  # largou para o lado oposto
	else:
		_escalando = false

	if _escalando:
		var n := get_wall_normal()
		_olha_para = -signf(n.x)  # virada para a parede
		velocity.x = -n.x * 40.0  # cola-se
		# escorrega SEMPRE pela parede abaixo -- não se fica fixo. ↑ trava e
		# sobe, ↓ desce mais depressa.
		var vsub := Input.get_action_strength("mirar_baixo") - Input.get_action_strength("mirar_cima")
		velocity.y = clampf(VEL_DESLIZE_PAREDE + vsub * VEL_ESCALAR, -VEL_ESCALAR, VEL_ESCALAR * 1.5)
		if Input.is_action_just_pressed("saltar"):
			velocity = Vector2(n.x * WALLJUMP.x, WALLJUMP.y)
			_escalando = false
			_parede_lock = 0.28
			_mov.saltos_dados = 0  # o salto de parede não gasta o salto do ar
			Som.toca("salto", -10.0)
		move_and_slide()
		_mov.velocidade = velocity
		_estava_no_chao = false
		return

	# defesa: só com a habilidade "escudo", em pé, e não a meio de outra ação
	_defendendo = EstadoJogo.tem_habilidade("escudo") \
		and Input.is_action_pressed("defender") \
		and _rolar_restante <= 0.0 and _dash_restante <= 0.0 and _ataque_restante <= 0.0 \
		and is_on_floor()

	# ataque leve -- bloqueado enquanto rola ou defende
	if _ataque_restante > 0.0:
		_ataque_restante -= dt
		if _ataque_restante <= 0.0 and _hitbox:
			_hitbox.monitoring = false
	elif not _defendendo and _rolar_restante <= 0.0 and Input.is_action_just_pressed("atacar"):
		_iniciar_ataque()

	# projétil mágico -- 8 direções, custa 33% da Energia, bate igual à espada
	if not _defendendo and _lancar_restante <= 0.0 \
			and _rolar_restante <= 0.0 and _dash_restante <= 0.0 \
			and EstadoJogo.tem_habilidade("projetil") \
			and Input.is_action_just_pressed("lancar") \
			and _energia >= CUSTO_PROJETIL:
		_lancar_projetil()

	# estados exclusivos de movimento: rolamento > dash > movimento normal
	if _rolar_restante > 0.0:
		_rolar_restante -= dt
		velocity.x = _olha_para * VEL_ROLAR
		if not is_on_floor():
			velocity.y = minf(Movimento.VEL_MAX_QUEDA, velocity.y + Movimento.GRAVIDADE * _grav_escala * dt)
	elif _dash_restante > 0.0:
		_dash_restante -= dt
		velocity.x = _olha_para * VEL_DASH
		velocity.y = 0.0
	elif _defendendo:
		# escudo erguido: anda-se devagar, sem saltar/dash/rolar
		velocity.x = move_toward(velocity.x, dir * VEL_DEFESA, Movimento.ACEL_CHAO * dt)
		if is_on_floor():
			velocity.y = 0.0
		else:
			velocity.y = minf(Movimento.VEL_MAX_QUEDA, velocity.y + Movimento.GRAVIDADE * _grav_escala * dt)
		_mov.velocidade = velocity
	elif Input.is_action_just_pressed("rolar") and Movimento.pode_rolar(
			_rolar_recarga, is_on_floor(), _rolar_restante, _dash_restante):
		_rolar_restante = DUR_ROLAR
		_rolar_recarga = RECARGA_ROLAR
		_invulneravel = maxf(_invulneravel, DUR_ROLAR)
	elif Input.is_action_just_pressed("dash") and _dash_recarga <= 0.0 and (
			is_on_floor() or EstadoJogo.tem_habilidade("dash_aereo")):
		_dash_restante = DUR_DASH
		_dash_recarga = RECARGA_DASH
		_invulneravel = maxf(_invulneravel, DUR_DASH)
	else:
		# salto duplo: habilidade permanente ganha ao longo da campanha
		var saltos_max := 2 if EstadoJogo.tem_habilidade("salto_duplo") else 1
		var saltos_antes := _mov.saltos_dados
		_mov = Movimento.passo(
			_mov, dir,
			Input.is_action_just_pressed("saltar"),
			Input.is_action_pressed("saltar"),
			is_on_floor(), dt, saltos_max, _grav_escala,
		)
		velocity = _mov.velocidade
		if _mov.saltos_dados > saltos_antes:
			Som.toca("salto_duplo" if _mov.saltos_dados >= 2 else "salto", -10.0)
			if _mov.saltos_dados >= 2:
				_djump_t = 0.45  # mostra a animação do salto duplo

	# batida do Coração Putrefacto (fase 2): gravidade aliviada -- a Koliani
	# fica "leve" e a queda abranda para lhe dar tempo no ar
	if _leve > 0.0 and velocity.y > 0.0:
		velocity.y *= 0.4

	# corrente de ar (Torre dos Ventos, nível 12): empurra para cima até
	# uma velocidade de subida-alvo enquanto estiver dentro.
	if _vento_restante > 0.0:
		_vento_restante -= dt
		velocity.y = maxf(velocity.y - _vento_forca * dt, -_vento_alvo)

	var vel_queda := velocity.y
	move_and_slide()
	_mov.velocidade = velocity

	# aterragem: pó + abanão + squash, proporcional à velocidade de queda
	var no_chao := is_on_floor()
	if no_chao and not _estava_no_chao and vel_queda > 180.0:
		if _po:
			_po.restart()
		var f := remap(minf(vel_queda, 1100.0), 180.0, 1100.0, 0.35, 1.0)
		_squash = maxf(_squash, f)
		_abanar(remap(minf(vel_queda, 1100.0), 180.0, 1100.0, 1.0, 4.5))
		Som.toca("aterrar", remap(f, 0.35, 1.0, -20.0, -8.0))
	_estava_no_chao = no_chao

	# caiu num fosso sem fundo -> conta como morte (reaparece no checkpoint)
	if global_position.y > Y_MORTE and vida > 0:
		if EstadoJogo.modo_dev:
			global_position = _pos_inicial if _pos_inicial != Vector2.ZERO else global_position
			velocity = Vector2.ZERO
		else:
			receber_dano(vida)


func _process(dt: float) -> void:
	_animar(dt)
	_atualizar_anim()


## Escolhe a animação do corpo conforme o estado (visual apenas).
func _atualizar_anim() -> void:
	if _corpo == null or _corpo.sprite_frames == null:
		return
	var a := "idle"
	if _escalando:
		a = "wallslide"
	elif _ataque_restante > 0.0:
		a = "attack"
	elif _agachado:
		a = "crouch"
	elif not is_on_floor():
		if _djump_t > 0.0:
			a = "djump"
		elif velocity.y < -20.0:
			a = "jump"
		else:
			a = "fall"
	elif absf(velocity.x) > 24.0:
		a = "run"
	if _corpo.animation != a:
		_corpo.play(a)
	elif not _corpo.is_playing():
		_corpo.play(a)

	# a arma acompanha grosso modo a pose: balanço no ataque, recolhida no ar
	if _arma and _arma.visible:
		var rot := 0.0
		var off := Vector2(10, 3)
		if a == "attack":
			var f := clampf(1.0 - _ataque_restante / DUR_ATAQUE, 0.0, 1.0)
			rot = lerpf(-1.3, 0.7, f)
			off = Vector2(9, 1)
		elif a == "wallslide":
			rot = 0.5
			off = Vector2(6, 6)
		elif a == "jump" or a == "djump":
			rot = -0.5
			off = Vector2(7, 0)
		_arma.rotation = rot
		_arma.position = off


## Animação procedural do sprite: flip, squash/stretch, lean, pop de
## ataque e rastro da lâmina. Nada disto afeta a física.
func _animar(dt: float) -> void:
	if _sprite == null:
		return
	_anim_t += dt
	_squash = move_toward(_squash, 0.0, dt * 5.0)
	_pop = move_toward(_pop, 0.0, dt * 7.0)

	if _escudo:
		if _defendendo != _escudo.visible:
			_escudo.visible = _defendendo
			if _defendendo:
				_escudo.scale = Vector2.ONE
		if _defendendo:
			_escudo.modulate.a = 0.82 + 0.18 * (0.5 + 0.5 * sin(_anim_t * 7.0))

	var no_chao := is_on_floor()
	var vx := absf(velocity.x)
	var escala := Vector2.ONE
	var rot_alvo := 0.0

	if _rolar_restante > 0.0:
		escala = Vector2(1.2, 0.8)
		_sprite.rotation += dt * _olha_para * 20.0
	elif _dash_restante > 0.0:
		escala = Vector2(1.32, 0.78)
		_sprite.rotation = lerp_angle(_sprite.rotation, 0.0, dt * 18.0)
	elif _escalando:
		escala = Vector2(0.86, 1.14)  # esticada contra a parede
		_sprite.rotation = lerp_angle(_sprite.rotation, _olha_para * 0.14, dt * 14.0)
	else:
		_sprite.rotation = lerp_angle(_sprite.rotation, rot_alvo, dt * 12.0)
		if not no_chao:
			if velocity.y < 0.0:
				escala = Vector2(0.86, 1.16)
			else:
				var f := clampf(velocity.y / 900.0, 0.0, 1.0)
				escala = Vector2(1.0 + 0.16 * f, 1.0 - 0.16 * f)
		elif vx > 25.0:
			var b := sin(_anim_t * 22.0) * 0.06
			escala = Vector2(1.0 + b, 1.0 - b)
			_sprite.rotation = lerp_angle(_sprite.rotation, -_olha_para * 0.08, dt * 12.0)
		else:
			var b := sin(_anim_t * 3.0) * 0.02
			escala = Vector2(1.0 - b, 1.0 + b)

	escala.x += _squash * 0.32 + _pop * 0.10
	escala.y += -_squash * 0.32 + _pop * 0.18
	_sprite.scale = Vector2(escala.x * _olha_para, escala.y)

	_animar_rastro(dt)


func _animar_rastro(dt: float) -> void:
	if _rastro == null:
		return
	if _ataque_restante > 0.0:
		_rastro.visible = true
		_rastro.modulate.a = 1.0
		var p := clampf(1.0 - _ataque_restante / DUR_ATAQUE, 0.0, 1.0)
		var pts := PackedVector2Array()
		for i in 7:
			var f := p - i * 0.06
			if f < 0.0:
				break
			var ang := lerpf(deg_to_rad(-120.0), deg_to_rad(35.0), f)
			pts.append(Vector2(cos(ang), sin(ang)) * 30.0 + Vector2(0.0, -4.0))
		_rastro.points = pts
	elif _rastro.visible:
		_rastro.modulate.a = move_toward(_rastro.modulate.a, 0.0, dt * 7.0)
		if _rastro.modulate.a <= 0.02:
			_rastro.visible = false
			_rastro.points = PackedVector2Array()


func _flash_branco() -> void:
	if _corpo == null:
		return
	var base := _tint_armadura()
	_corpo.modulate = Color(2.4, 2.4, 2.4)
	var t := create_tween()
	t.tween_property(_corpo, "modulate", base, 0.16)


## Cor de base do corpo (tinta da armadura ou branco).
func _tint_armadura() -> Color:
	var ai: int = Equipamento.indice_armadura(EstadoJogo.armadura_equipada)
	return Color.WHITE if ai < 0 else Color.WHITE.lerp(Equipamento.cor_armadura(ai), 0.5)


func _abanar(forca: float) -> void:
	if _camera and _camera.has_method("bater"):
		_camera.bater(forca)


## Pequena paragem de tempo real ("hitstop") para dar peso ao impacto.
func _hitstop(segundos: float) -> void:
	if Engine.time_scale < 0.5:
		return
	Engine.time_scale = 0.0
	await get_tree().create_timer(segundos, true, false, true).timeout
	Engine.time_scale = 1.0


func _iniciar_ataque() -> void:
	_ataque_restante = DUR_ATAQUE
	_pop = 1.0
	Som.toca("ataque", -13.0)
	if _hitbox:
		_hitbox.scale.x = _olha_para
		_hitbox.monitoring = true


## Lança um projétil mágico numa das 8 direções (mira = eixos de movimento
## + W/S; sem mira, para onde está virada). Já validado que há Energia.
func _lancar_projetil() -> void:
	if not EstadoJogo.modo_dev:  # modo dev: energia infinita
		_energia -= CUSTO_PROJETIL
	energia_mudou.emit(_energia, ENERGIA_MAX)
	_lancar_restante = DUR_LANCAR
	_pop = 1.0
	var ax := Input.get_action_strength("mover_direita") - Input.get_action_strength("mover_esquerda")
	var ay := Input.get_action_strength("mirar_baixo") - Input.get_action_strength("mirar_cima")
	var aim := Movimento.direcao_mira(ax, ay, _olha_para)
	var p := PROJETIL_MAGICO.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position + aim * 20.0 + Vector2(0.0, -4.0)
	p.lancar(aim, _dano_golpe())
	Som.toca("projetil", -12.0, 1.25)
	magia_lancada.emit()
	if _faiscas:
		_faiscas.position.x = absf(_faiscas.position.x) * signf(aim.x if aim.x != 0.0 else _olha_para)
		_faiscas.restart()


func _ao_acertar_corpo(corpo: Node) -> void:
	if corpo.has_method("receber_dano"):
		corpo.receber_dano(_dano_golpe(), sign(_olha_para))
		if _faiscas:
			_faiscas.position.x = absf(_faiscas.position.x) * _olha_para
			_faiscas.restart()
		_pop_impacto((corpo as Node2D).global_position if corpo is Node2D else global_position)
		_abanar(4.5)
		_hitstop(0.06)
		Som.toca("acerto", -8.0)


## "Frame de impacto" -- clarão branco que estica e desaparece depressa.
func _pop_impacto(pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = TEX_IMPACTO
	s.global_position = pos
	s.rotation = randf() * TAU
	s.scale = Vector2(0.3, 0.3)
	s.z_index = 40
	get_parent().add_child(s)
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", Vector2(1.7, 1.7), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "modulate:a", 0.0, 0.16)
	t.chain().tween_callback(s.queue_free)


## Um golpe é bloqueável se vier de frente. `dir_empurrao` é o sentido em
## que o golpe empurra a Koliani (para longe da fonte); ela bloqueia se
## estiver virada para a fonte. Sem direção conhecida (0), o escudo vale.
func _bloqueia(dir_empurrao: float) -> bool:
	return Movimento.bloqueia_de_frente(dir_empurrao, _olha_para)


func _ao_bloquear() -> void:
	_invulneravel = maxf(_invulneravel, BLOQUEIO_IFRAMES)
	Som.toca("bloqueio", -15.0, randf_range(0.97, 1.06))
	_abanar(2.5)
	if _escudo:
		_escudo.scale = Vector2(1.28, 1.16)
		var t := _escudo.create_tween()
		t.tween_property(_escudo, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _faiscas:
		_faiscas.position.x = absf(_faiscas.position.x) * _olha_para
		_faiscas.restart()


## Teia no chão: abranda a Koliani por `segundos` (não a prende). Limitado a
## `MAX_PRESO` para uma teia permanente nunca a segurar de vez. O escudo
## erguido protege-a.
const MAX_PRESO := 1.2

func prender(segundos: float) -> void:
	if _defendendo:
		return
	_preso = clampf(maxf(_preso, segundos), 0.0, MAX_PRESO)


## Alivia a gravidade da Koliani por `segundos` (batida do Coração
## Putrefacto, fase 2). Não a impede de andar/saltar -- só a faz cair devagar.
func flutuar(segundos: float) -> void:
	_leve = maxf(_leve, segundos)


## Define a escala da gravidade (Observatório Lunar, nível 14). 1 = normal,
## ~0.4 = "gravidade lunar" (salto alto, queda lenta). As `ZonaGravidade`
## chamam isto ao entrar/sair; a Sacerdotisa mexe nisto durante a luta.
func definir_grav_escala(v: float) -> void:
	_grav_escala = clampf(v, 0.2, 1.5)


## Inverte os controlos horizontais por `segundos` (O Olho do Abismo, nível 20).
func inverter_controlos(segundos: float) -> void:
	_inverso = -1.0
	_inverso_restante = maxf(_inverso_restante, segundos)


## Corrente de ar a empurrar para cima (Torre dos Ventos, nível 12). A
## `CorrenteAr` chama isto a cada frame enquanto a Koliani lá está;
## `forca` = aceleração, `alvo` = velocidade máxima de subida.
func soprar_para_cima(forca: float, alvo: float) -> void:
	_vento_forca = forca
	_vento_alvo = alvo
	_vento_restante = 0.12  # renova-se enquanto a área a alimentar


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _invulneravel > 0.0:
		return
	if EstadoJogo.modo_dev:  # modo de testes: não perde vida
		return
	if _defendendo and _bloqueia(dir_empurrao):
		_ao_bloquear()
		return
	var real := int(round(quantidade * (1.0 - EstadoJogo.reducao_armadura())))
	vida = maxi(0, vida - maxi(1, real))
	_invulneravel = I_FRAMES
	vida_mudou.emit(vida, _vida_max())
	_flash_branco()
	_abanar(8.0)
	_hitstop(0.07)
	Som.toca("dano", -7.0)
	if vida <= 0:
		_morrer()


func _morrer() -> void:
	Engine.time_scale = 1.0  # não deixar um hitstop pendente a segurar o tempo
	set_physics_process(false)
	morreu.emit()
	EstadoJogo.perder_vida()
	if EstadoJogo.sem_vidas():
		if EstadoJogo.hardcore:
			# hardcore: 3 vidas gastas = fim do run -> cartão GAME OVER (com voz)
			GameOver.mostrar(get_tree(), "lives")
			return
		EstadoJogo.reiniciar_campanha()
	Transicao.fechar_e(get_tree().reload_current_scene)
