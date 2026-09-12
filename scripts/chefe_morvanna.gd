class_name ChefeMorvanna
extends ChefeBase
## Região I / nível 02 -- Morvanna, a Bruxa do Pântano. Flutua sobre a água
## venenosa, longe do alcance da Koliani, e ataca de três formas:
##   * MÃOS   -- invoca mãos espectrais que telegrafam e irrompem sob os
##               pés da Koliani (dano ao toque).
##   * CLONES -- larga clones de lama que andam até à Koliani (herdam de
##               DemonioBase; pouca vida, desfazem-se sozinhos).
##   * APAGA  -- faz desaparecer metade das plataformas flutuantes por uns
##               segundos (a Koliani fica sem onde pisar sobre a água).
## Execution 9H.9 -- O Game Master disse que a luta não fazia sentido: ela
## ficava no ar, a Koliani é MELEE e não tem nada para lhe chegar, o simples
## facto de ela pairar por cima já fazia dano, e não havia janela de ataque
## legível. O ciclo é agora sempre o mesmo, e acaba sempre ao alcance:
##
##   REPOSICIONA (voa em x) -> TELEGRAFO -> ATAQUE -> PICADA até ao chão
##   -> ATERRADA (janela de melee, leva dano a dobrar) -> LEVANTA -> ar
##
## Duas regras que a luta não tinha:
##   * o dano dela vem SÓ de ataques reconhecíveis. No ar não tem dano de
##     contacto nenhum -- só a picada (e essa tem telégrafo) e as invocações.
##   * a janela de melee é no CHÃO, não a pairar a meia altura. A Koliani
##     salta 85 px de um salto; a EXPOSTA antiga punha-a a 88, ou seja no
##     limite exacto do apogeu, e só lá chegava ~0,8 s dos 1,5 s do estado.
##     (Ela leva dano em qualquer altura desde o passe "chefes sem escudos";
##     o que faltava não era vulnerabilidade, era ALCANCE.)
##
## Fase 2 (< 50% vida): telégrafos mais curtos, mais mãos, apaga mais tempo.

const CLONE := preload("res://scenes/actors/DemonioBase.tscn")

enum Fase {
	DORME, REPOSICIONA, MAOS_TEL, MAOS, CLONES_TEL, CLONES, APAGA_TEL, APAGA,
	PICADA_TEL, PICADA, ATERRADA, LEVANTA,
}

@export var dist_deteta := 460.0
## Altura a que paira (px acima do chão da arena) fora da janela de dano.
@export var altura_voo := 210.0
## Altura a que fica ATERRADA: no chão. A Koliani chega-lhe a andar.
@export var altura_exposta := 24.0
@export var balanco := 12.0
@export var dur_tel := 0.62
@export var dur_maos := 0.7
@export var dur_apaga := 3.2
## Janela de melee. Generosa de propósito: é o único sítio onde ela leva
## dano, e é o que torna a luta possível com o kit actual da Koliani.
@export var dur_exposta := 2.1
## Quanto tempo leva a reposicionar-se no ar antes do telégrafo seguinte.
@export var dur_reposiciona := 0.9
## Telégrafo da picada -- mais longo que os outros: é o ataque que a põe em
## cima da Koliani, portanto tem de ser o mais legível de todos.
@export var dur_picada_tel := 0.72
@export var dur_picada := 0.5
@export var dur_levanta := 0.45
## Velocidade do voo horizontal no reposicionamento.
@export var vel_voo := 150.0
@export var dano_mao := 18
@export var dano_clone := 14
## Dano da picada. É o único dano de CONTACTO dela, e só durante a picada.
@export var dano_picada := 20

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposta := false
var _ciclos := 0
var _alvo_y := 0.0
var _vida_max := 300
## Y do chão da arena por baixo da Morvanna (raycast uma vez, ela quase não
## se desloca em x). As alturas de voo/EXPOSTA são relativas a isto.
var _chao_cache := 0.0
## Só durante a PICADA é que o corpo dela machuca. Ver `_ao_tocar`.
var _picada_ativa := false
## x para onde está a voar no REPOSICIONA (do lado da Koliani, com folga).
var _alvo_x := 0.0
var _x_picada := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 275)
	_vida_max = vida
	_alvo_y = _origem.y
	_alvo_x = global_position.x
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		# baloiço de flutuação constante (some no chão, no EXPOSTA)
		var amp := balanco if not _exposta else balanco * 0.4
		_sprite.position.y = sin(_pulso * 2.2) * amp
	if _nucleo and _exposta:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)

	# glide suave até à altura-alvo do estado atual. A PICADA é mais rápida
	# do que o resto: é um ataque, tem de se sentir como uma queda.
	var antes := global_position
	var resposta := 9.0 if _fase == Fase.PICADA else 4.0
	global_position.y = lerpf(global_position.y, _alvo_y, clampf(dt * resposta, 0.0, 1.0))
	# `velocity` não move nada aqui (ela voa por posição), mas é o que o
	# `_atualizar_anim` lê para saber se está a deslocar-se -- sem isto
	# ficava em `idle` a luta toda.
	if dt > 0.0:
		velocity = (global_position - antes) / dt
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			_alvo_y = _chao_cache - altura_voo
			if _ve_koliani():
				_ir(Fase.REPOSICIONA)
		# Voa para o lado da Koliani, com folga, antes de telegrafar. É o que
		# a faz LER como uma bruxa a voar e não como um sprite pendurado.
		Fase.REPOSICIONA:
			_alvo_y = _chao_cache - altura_voo
			if _t < dt:
				_escolher_pouso()
			_voar_para(_alvo_x, dt)
			if _t >= dur_reposiciona:
				_escolher()
		Fase.MAOS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_ir(Fase.MAOS)
		Fase.MAOS:
			if _t < dt:
				_lancar_maos()
			if _t >= dur_maos:
				_ir(Fase.PICADA_TEL)
		Fase.CLONES_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_ir(Fase.CLONES)
		Fase.CLONES:
			if _t < dt:
				_largar_clones()
			if _t >= 0.5:
				_ir(Fase.PICADA_TEL)
		Fase.APAGA_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_ir(Fase.APAGA)
		Fase.APAGA:
			if _t < dt:
				_apagar_plataformas()
			if _t >= 0.5:
				_ir(Fase.PICADA_TEL)
		# TELÉGRAFO DA PICADA: sobe um pouco, fica quieta em x e pisca. É o
		# aviso de que vem a caminho -- e é o que dá à Koliani a informação
		# para se afastar ou para se preparar para castigar.
		Fase.PICADA_TEL:
			_alvo_y = _chao_cache - altura_voo - 26.0
			_piscar(true)
			if _t < dt:
				_x_picada = _x_koliani()
				Som.toca("chefe_magia", -10.0, 1.2)
			if _t >= dur_picada_tel * (0.8 if _fase2 else 1.0):
				_piscar(false)
				_picada_ativa = true
				_abanar_camera(2.0)
				_ir(Fase.PICADA)
		# A PICADA é o único momento em que o corpo dela faz dano.
		Fase.PICADA:
			_alvo_y = _chao_cache - altura_exposta
			_voar_para(_x_picada, dt, 2.4)
			_dano_da_picada()
			if _t >= dur_picada:
				_picada_ativa = false
				_abanar_camera(4.0)
				Som.toca("chefe_cai", -10.0, 1.0)
				_ir(Fase.ATERRADA)
		# JANELA DE MELEE. No chão, núcleo à mostra, sem dano de contacto e
		# quieta: é aqui que a luta se ganha, e é longa o suficiente para
		# caber um combo da Koliani.
		Fase.ATERRADA:
			_alvo_y = _chao_cache - altura_exposta
			velocity.x = 0.0
			if not _exposta:
				_exposta = true
				_mostrar_nucleo(true)
			if _t >= dur_exposta:
				_ir(Fase.LEVANTA)
		# Levanta-se: recolhe o núcleo e sobe, mas ainda não ataca -- a
		# Koliani tem tempo de sair de baixo dela.
		Fase.LEVANTA:
			_alvo_y = _chao_cache - altura_voo
			if _exposta:
				_exposta = false
				_mostrar_nucleo(false)
			if _t >= dur_levanta:
				_ciclos += 1
				_ir(Fase.REPOSICIONA)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


## Roda entre os três ataques de invocação; na fase 2 repete APAGA mais
## vezes. Cada um deles cai depois na PICADA, portanto cada ciclo tem sempre
## a sua janela de melee -- não há ciclo em que ela fique inalcançável.
func _escolher() -> void:
	var op := _ciclos % 3
	if _fase2 and _ciclos % 4 == 3:
		op = 2
	match op:
		0: _ir(Fase.MAOS_TEL)
		1: _ir(Fase.CLONES_TEL)
		_: _ir(Fase.APAGA_TEL)


## Onde se vai pôr no ar: do lado da Koliani, a uma distância que a deixa
## ver-se no ecrã inteira (e não colada por cima dela).
func _escolher_pouso() -> void:
	var k := _obter_koliani()
	if k == null:
		_alvo_x = global_position.x
		return
	var lado := -1.0 if k.global_position.x > global_position.x else 1.0
	_alvo_x = clampf(k.global_position.x + lado * 170.0,
		_origem.x - 300.0, _origem.x + 300.0)


## Voo horizontal por posição (ela não usa `move_and_slide`: atravessa as
## plataformas flutuantes da arena de propósito).
func _voar_para(x: float, dt: float, mult := 1.0) -> void:
	var d := x - global_position.x
	var passo := vel_voo * mult * dt
	if absf(d) <= passo:
		global_position.x = x
		return
	global_position.x += signf(d) * passo


## O dano da picada: só enquanto `_picada_ativa`, e só uma vez por picada.
## É por overlap directo e não pelo `body_entered` porque a Koliani já pode
## estar dentro da área quando a picada começa.
func _dano_da_picada() -> void:
	if not _picada_ativa or _area_contacto == null:
		return
	for c in _area_contacto.get_overlapping_bodies():
		if c is Koliani:
			_picada_ativa = false
			c.receber_dano(int(round(dano_picada * (1.15 if _fase2 else 1.0))),
				signf(c.global_position.x - global_position.x))
			return


## O corpo dela NÃO machuca fora da picada. Era esta a queixa do Game
## Master: pairar sobre a Koliani fazia dano sem ataque nenhum.
func _ao_tocar(corpo: Node) -> void:
	if _picada_ativa:
		super._ao_tocar(corpo)


## O clipe que o `DemonioBase._atualizar_anim` deve tocar em cada estado.
func _anim_desejada() -> String:
	match _fase:
		Fase.MAOS_TEL, Fase.CLONES_TEL, Fase.APAGA_TEL, Fase.PICADA_TEL:
			return "attack"
		Fase.MAOS, Fase.CLONES, Fase.APAGA, Fase.PICADA:
			return "attack"
		Fase.ATERRADA:
			return "hit"
		Fase.REPOSICIONA, Fase.LEVANTA:
			return "run"
		_:
			return ""


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta


## --- ataques ---------------------------------------------------------

func _lancar_maos() -> void:
	Som.toca("chefe_magia", -8.0, 1.5)
	_abanar_camera(3.0)
	var n := 3 if _fase2 else 2
	var alvo := _x_koliani()
	for i in n:
		var x := alvo + (i - (n - 1) * 0.5) * 96.0 + randf_range(-16.0, 16.0)
		_invocar_mao(x, 0.12 + i * 0.16)


func _invocar_mao(x: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var chao := _chao_y(x)
	var mao := Area2D.new()
	mao.collision_layer = 0
	mao.collision_mask = 2
	mao.global_position = Vector2(x, chao)
	mao.monitoring = false
	pai.add_child(mao)

	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(26, 66)
	forma.shape = rs
	forma.position = Vector2(0, -33)
	mao.add_child(forma)

	var garra := Polygon2D.new()
	garra.color = Color(0.12, 0.28, 0.22, 0.9)
	garra.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(-9, -44), Vector2(-3, -30), Vector2(0, -58),
		Vector2(3, -30), Vector2(9, -44), Vector2(12, 0),
	])
	garra.scale.y = 0.0
	mao.add_child(garra)

	var racha := Polygon2D.new()
	racha.color = Color(0.5, 0.95, 0.7, 0.5)
	racha.polygon = PackedVector2Array([Vector2(-14, -1), Vector2(14, -1), Vector2(10, 2), Vector2(-10, 2)])
	mao.add_child(racha)

	var dano := int(round(dano_mao * (1.15 if _fase2 else 1.0)))
	var t := mao.create_tween()
	t.tween_property(racha, "modulate:a", 0.25, atraso * 0.5)
	t.tween_property(racha, "modulate:a", 1.0, atraso * 0.5)
	t.tween_callback(func() -> void: racha.visible = false)
	t.tween_callback(func() -> void: mao.monitoring = true)
	t.parallel().tween_property(garra, "scale:y", 1.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void:
		for c in mao.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(dano, signf(c.global_position.x - mao.global_position.x)))
	t.tween_interval(0.55)
	t.tween_callback(func() -> void: mao.monitoring = false)
	t.tween_property(garra, "scale:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(mao.queue_free)


func _largar_clones() -> void:
	Som.toca("invocar", -8.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var n := 2 if _fase2 else 1
	for i in n:
		var clone := CLONE.instantiate()
		clone.identidade_visual = "clone_morvanna"  # só a arte; a espécie fica
		clone.vida = 22
		clone.dano_contacto = dano_clone
		clone.velocidade = 74.0
		clone.alcance_patrulha = 260.0
		clone.cor_estilhacos = Color(0.3, 0.45, 0.28)
		clone.cor_rim = Color(0.45, 0.85, 0.55)
		var x := global_position.x + (i * 2 - 1) * 48.0
		clone.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(clone)
		# rede de segurança: não fica para sempre
		clone.get_tree().create_timer(9.0).timeout.connect(func() -> void:
			if is_instance_valid(clone) and not clone._morto:
				clone.soltar_estilhacos()
				clone.queue_free())


func _apagar_plataformas() -> void:
	Som.toca("grito", -7.0, 0.9)
	_abanar_camera(4.0)
	var plats := get_tree().get_nodes_in_group("plataformas_flutuantes")
	var segundos := dur_apaga * (1.4 if _fase2 else 1.0)
	for i in plats.size():
		# apaga uma sim, uma não -- sobra sempre onde pisar, mas mal
		if i % 2 == 0 and plats[i].has_method("desvanecer"):
			plats[i].desvanecer(segundos)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -9.0, 0.7)
	_abanar_camera(6.0)
	dur_tel *= 0.7
	dur_exposta *= 0.85


## --- núcleo / dano -------------------------------------------------

## Telegrafo -> frame 2 (mãos espectrais erguidas) da tira pixel-art.
func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposta:
		_corpo.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _nucleo == null:
		return
	_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
	var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
	if luz:
		luz.energy = 1.6 if v else 0.12
	var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
	if brilho:
		brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	super.receber_dano(quantidade, dir_empurrao, critico)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var espaco := get_world_2d().direct_space_state
	var de := Vector2(x, _origem.y - 40.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 420.0), 1)
	q.exclude = [self]
	var hit := espaco.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
