class_name ChefeVyrak
extends ChefeBase
## Região III / nível 15 -- VYRAK, A VOZ DOS ECOS.
##
## Contrato: docs/art_direction/regions/region_03/
## REGION03_VISUAL_GAMEPLAY_CONTRACT.md §3, tirado da prancha aprovada
## `boss_pack.png`.
##
## Isto era "Vyrak, o Dragão das Sombras": uma besta alada de três fases,
## com garra, cauda e sopro de sombra. A prancha mostra outra criatura --
## o guardião do topo da torre, um ser que já foi humano e está fundido
## com os sinos e a memória da torre. Não foi polimento: eram dois chefes
## diferentes com o mesmo nome.
##
## O QUE SE MANTEVE da versão antiga, porque era bom e é exatamente o que
## os "PRINCÍPIOS DE DESIGN" da prancha pedem: o ciclo
## TELEGRAFO -> ATAQUE -> NÚCLEO EXPOSTO. O núcleo (aqui o badalo do sino
## ao peito) é a janela em que ele leva dano a dobrar -- é o que faz o
## "boss sempre atingível" ser verdade e dá o ritmo à luta.
##
## O QUE MUDOU: as fases passam de três para as DUAS do cânone, e os
## ataques passam a ser os nove nomeados na prancha, cada um com o seu
## telégrafo -- que é desenhado no sítio onde o ataque vai cair, porque a
## prancha exige "telegraphing claro (visual e sonoro)".
##
##   F1 (100 %-50 %)  golpe de sino · onda de eco · sino em queda ·
##                    lanças de luz · investida aérea
##   RITUAL DE ATIVAÇÃO (50 %)  cutscene curta, a arena acorda
##   F2 (50 %-0 %)    + chuva de sinos · espiral de ecos · parede de eco ·
##                    julgamento final
##
## A rotação é uma LISTA por fase e não `_ciclos % n` espalhado pelo
## código: assim vê-se de relance que combinações saem, que é o que a
## prancha quer dizer com "combinação de ataques, mas sem spam injusto".

## Ataques, pela ordem em que a prancha os numera.
enum Atk {
	GOLPE_SINO, ONDA_ECO, SINO_QUEDA, LANCAS_LUZ, INVESTIDA,
	CHUVA_SINOS, ESPIRAL, PAREDE_ECO, JULGAMENTO,
}

enum Fase { DORME, DECIDE, TELEGRAFO, EXECUTAR, EXPOSTO, RITUAL }

## Por ataque: duração do telégrafo, duração da execução, dano.
## As durações do telégrafo são a "janela de reação justa": os ataques que
## a prancha marca com dano alto (investida, julgamento) avisam MAIS tempo.
const ATAQUES := {
	Atk.GOLPE_SINO: {"tel": 0.50, "exec": 0.42, "dano": 20},
	Atk.ONDA_ECO:   {"tel": 0.55, "exec": 0.70, "dano": 18},
	Atk.SINO_QUEDA: {"tel": 0.70, "exec": 1.05, "dano": 24},
	Atk.LANCAS_LUZ: {"tel": 0.55, "exec": 0.60, "dano": 16},
	Atk.INVESTIDA:  {"tel": 0.80, "exec": 0.85, "dano": 28},
	Atk.CHUVA_SINOS: {"tel": 0.75, "exec": 1.40, "dano": 20},
	Atk.ESPIRAL:    {"tel": 0.60, "exec": 1.10, "dano": 18},
	Atk.PAREDE_ECO: {"tel": 0.65, "exec": 1.60, "dano": 18},
	Atk.JULGAMENTO: {"tel": 1.05, "exec": 0.80, "dano": 34},
}

## Rotação da fase 1: os cinco da prancha, com o pesado (investida) a
## fechar o ciclo em vez de abrir -- abre-se com o golpe curto para o
## jogador aprender a leitura antes de levar o caro.
const CICLO_F1: Array[Atk] = [
	Atk.GOLPE_SINO, Atk.ONDA_ECO, Atk.LANCAS_LUZ, Atk.GOLPE_SINO,
	Atk.SINO_QUEDA, Atk.ONDA_ECO, Atk.INVESTIDA,
]

## Fase 2: entram os quatro novos, mas os antigos NÃO desaparecem -- a
## prancha diz "aumenta complexidade sem perder legibilidade", e uma fase
## feita só de ataques novos deita fora tudo o que o jogador aprendeu.
## O julgamento final aparece uma vez por volta, no fim.
const CICLO_F2: Array[Atk] = [
	Atk.CHUVA_SINOS, Atk.GOLPE_SINO, Atk.ESPIRAL, Atk.LANCAS_LUZ,
	Atk.PAREDE_ECO, Atk.ONDA_ECO, Atk.SINO_QUEDA, Atk.ESPIRAL,
	Atk.INVESTIDA, Atk.JULGAMENTO,
]

const PROJ_VEL := 300.0
## Cor da energia de eco (prancha: "energia de eco" + acentos roxos).
const ECO := Color(0.56, 0.66, 1.0)
const OURO := Color(0.85, 0.68, 0.36)

@export var dist_deteta := 680.0
@export var altura_voo := 200.0
## Raio da arena em que ele se mantém: a prancha põe-no numa "plataforma
## principal contínua", e um chefe que foge para fora do ecrã deixa de ser
## "sempre atingível".
@export var raio_arena := 420.0

var _fase: Fase = Fase.DORME
var _atk: Atk = Atk.GOLPE_SINO
var _t := 0.0
var _pulso := 0.0
var _passo := 0
var _vida_max := 760
var _f2 := false
var _exposto := false
var _chao_cache := 0.0
var _base_x := 0.0
var _investida_dir := 1.0
var _marcas: Array[Node2D] = []

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 760)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base_x = global_position.x
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 1.8) * (6.0 if not _exposto else 2.5)
	if _nucleo and _exposto:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(_base_x)
	# A transição é aos 50 %, como a prancha manda (não aos 66/33).
	if not _f2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_ir(Fase.RITUAL)

	match _fase:
		Fase.DORME:
			_pairar(dt, 70.0)
			_encarar_koliani()
			if _ve_koliani():
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_pairar(dt, 70.0)
			_voltar_ao_centro(dt)
			_encarar_koliani()
			if _t >= 0.34:
				var ciclo: Array[Atk] = CICLO_F2 if _f2 else CICLO_F1
				_atk = ciclo[_passo % ciclo.size()]
				_passo += 1
				_ir(Fase.TELEGRAFO)
		Fase.TELEGRAFO:
			_pairar(dt, 70.0)
			if _atk != Atk.INVESTIDA:
				_encarar_koliani()
			if _t < dt:
				_telegrafar(_atk)
			if _t >= float(ATAQUES[_atk]["tel"]):
				_piscar(false)
				_executar(_atk)
				_ir(Fase.EXECUTAR)
		Fase.EXECUTAR:
			_durante(_atk, dt)
			if _t >= float(ATAQUES[_atk]["exec"]):
				_limpar_marcas()
				_ir(Fase.EXPOSTO)
		Fase.EXPOSTO:
			_pairar(dt, 62.0)
			_voltar_ao_centro(dt)
			if not _exposto:
				_mostrar_nucleo(true)
			# Na fase 2 a janela é mais curta: mais pressão, mas nunca zero
			# -- sem janela, "boss sempre atingível" deixava de ser verdade.
			if _t >= (1.05 if _f2 else 1.45):
				_mostrar_nucleo(false)
				_ir(Fase.DECIDE)
		Fase.RITUAL:
			if _t < dt:
				_ritual_de_ativacao()
			_pairar(dt, 96.0)
			if _t >= 1.6:
				_passo = 0
				_ir(Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	if f == Fase.RITUAL:
		_f2 = true
	_fase = f
	_t = 0.0


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 420.0


func _pairar(dt: float, altura: float) -> void:
	global_position.y = lerpf(global_position.y, _chao_cache - altura,
		clampf(dt * 2.6, 0.0, 1.0))


func _voltar_ao_centro(dt: float) -> void:
	global_position.x = lerpf(global_position.x, _base_x, clampf(dt * 2.4, 0.0, 1.0))


## --- telégrafos --------------------------------------------------------
##
## Cada um desenha a marca NO SÍTIO onde o ataque vai cair. É a diferença
## entre "o chefe piscou" e "sei para onde fugir".

func _telegrafar(a: Atk) -> void:
	_piscar(true)
	match a:
		Atk.GOLPE_SINO:
			_som("selo", -8.0, 1.25)
			_marca_arco(_direcao)
		Atk.ONDA_ECO:
			_som("invocar", -9.0, 0.8)
			_marca_anel(Vector2(global_position.x, _chao_cache - 6.0), 120.0)
		Atk.SINO_QUEDA:
			_som("selo", -9.0, 0.9)
			for i in 3:
				_marca_anel(Vector2(_x_alvo() + (i - 1) * 96.0,
					_chao_cache - 6.0), 34.0, true)
		Atk.LANCAS_LUZ:
			_som("projetil", -10.0, 1.3)
			_brilho_asas()
		Atk.INVESTIDA:
			_som("investida", -9.0, 0.7)
			_investida_dir = _dir_para_koliani()
			_marca_faixa(_investida_dir)
		Atk.CHUVA_SINOS:
			_som("selo", -8.0, 0.8)
			for i in 5:
				_marca_anel(Vector2(_base_x + (i - 2) * 118.0 + randf_range(-24, 24),
					_chao_cache - 6.0), 36.0, true)
		Atk.ESPIRAL:
			_som("invocar", -9.0, 1.1)
			_marca_anel(global_position, 70.0)
			_marca_anel(global_position, 110.0)
		Atk.PAREDE_ECO:
			_som("invocar", -8.0, 0.6)
			_marca_anel(global_position, 54.0)
		Atk.JULGAMENTO:
			_som("raio", -7.0, 0.7)
			_marca_anel(Vector2(_x_alvo(), _chao_cache - 6.0), 150.0)


func _x_alvo() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else _base_x


## --- execução dos ataques ----------------------------------------------

func _executar(a: Atk) -> void:
	var dano := int(ATAQUES[a]["dano"])
	match a:
		Atk.GOLPE_SINO:
			_som("ataque_forte", -6.0, 0.9)
			_golpe_em_arco(dano)
		Atk.ONDA_ECO:
			_som("ataque_forte", -6.0, 0.6)
			_abanar_camera(5.0)
			_onda_de_choque(dano)
		Atk.SINO_QUEDA:
			for i in 3:
				_sino_cai(_x_alvo() + (i - 1) * 96.0, dano, i * 0.18)
		Atk.LANCAS_LUZ:
			_som("projetil", -7.0, 1.0)
			_leque_de_lancas(dano)
		Atk.INVESTIDA:
			_som("investida", -5.0, 0.9)
			global_position.x = _base_x - _investida_dir * 360.0
		Atk.CHUVA_SINOS:
			for i in 5:
				_sino_cai(_base_x + (i - 2) * 118.0, dano, i * 0.22)
		Atk.ESPIRAL:
			_som("projetil", -7.0, 0.8)
			_espiral(dano)
		Atk.PAREDE_ECO:
			_som("invocar", -6.0, 0.7)
			_parede(dano)
		Atk.JULGAMENTO:
			_som("raio", -4.0, 0.8)
			_abanar_camera(11.0)
			_feixe(dano)


## Comportamento contínuo durante a execução (só a investida precisa).
func _durante(a: Atk, dt: float) -> void:
	if a == Atk.INVESTIDA:
		global_position.x += _investida_dir * 640.0 * dt
		_golpe_corpo(int(ATAQUES[a]["dano"]), 70.0, 86.0)
	else:
		_pairar(dt, 70.0)


## --- ataques em si -----------------------------------------------------

func _golpe_em_arco(dano: int) -> void:
	var area := _nova_area(global_position + Vector2(_direcao * 74.0, 6.0),
		_rect(150, 96))
	var poly := Polygon2D.new()
	poly.color = Color(OURO.r, OURO.g, OURO.b, 0.72)
	poly.polygon = PackedVector2Array([
		Vector2(-_direcao * 20, -46), Vector2(_direcao * 78, -30),
		Vector2(_direcao * 74, 34), Vector2(-_direcao * 24, 46)])
	area.add_child(poly)
	_dano_imediato(area, dano, _direcao)
	var t := area.create_tween()
	t.tween_property(poly, "modulate:a", 0.0, 0.3)
	t.tween_callback(area.queue_free)


func _onda_de_choque(dano: int) -> void:
	# Rasteira: EVITA-SE A SALTAR, como a prancha diz. Por isso é baixa --
	# 30 px de altura a partir do chão.
	for lado in [-1.0, 1.0]:
		var area := _nova_area(Vector2(global_position.x, _chao_cache - 15.0),
			_rect(60, 30))
		var poly := Polygon2D.new()
		poly.color = Color(ECO.r, ECO.g, ECO.b, 0.75)
		poly.polygon = PackedVector2Array([Vector2(-30, 15), Vector2(-18, -15),
			Vector2(18, -15), Vector2(30, 15)])
		area.add_child(poly)
		_dano_continuo(area, dano, lado)
		var t := area.create_tween()
		t.tween_property(area, "global_position:x",
			global_position.x + lado * 460.0, 0.62)
		t.parallel().tween_property(poly, "modulate:a", 0.0, 0.62)
		t.tween_callback(area.queue_free)


func _sino_cai(x: float, dano: int, atraso: float) -> void:
	var area := _nova_area(Vector2(x, _chao_cache - 420.0), _rect(46, 54))
	var poly := Polygon2D.new()
	poly.color = Color(OURO.r, OURO.g, OURO.b, 0.96)
	poly.polygon = PackedVector2Array([Vector2(-16, 26), Vector2(-11, -22),
		Vector2(11, -22), Vector2(16, 26), Vector2(21, 26), Vector2(21, 30),
		Vector2(-21, 30), Vector2(-21, 26)])
	area.add_child(poly)
	_dano_imediato_ao_entrar(area, dano)
	var t := area.create_tween()
	t.tween_interval(atraso)
	t.tween_property(area, "global_position:y", _chao_cache - 22.0, 0.34) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		_som("ataque_forte", -8.0, 0.5)
		_abanar_camera(3.0))
	t.tween_property(poly, "modulate:a", 0.0, 0.34)
	t.tween_callback(area.queue_free)


func _leque_de_lancas(dano: int) -> void:
	# "projéteis em leque · evitar: desviar ENTRE as lanças" -- por isso o
	# leque é largo e com folga entre lanças, não uma parede.
	var base := _dir_para_koliani()
	for i in 5:
		var ang := deg_to_rad(-30.0 + i * 15.0)
		var dir := Vector2(base, 0.0).rotated(ang if base > 0.0 else -ang)
		_lanca(global_position + Vector2(0, -10), dir, dano)


func _lanca(de: Vector2, dir: Vector2, dano: int) -> void:
	var area := _nova_area(de, _circ(8.0))
	var poly := Polygon2D.new()
	poly.color = Color(ECO.r, ECO.g, ECO.b, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(0, -5),
		Vector2(16, 0), Vector2(0, 5)])
	poly.rotation = dir.angle()
	area.add_child(poly)
	_dano_imediato_ao_entrar(area, dano)
	var t := area.create_tween()
	t.tween_property(area, "global_position", de + dir * 620.0, 620.0 / PROJ_VEL)
	t.tween_callback(area.queue_free)


func _espiral(dano: int) -> void:
	# "espiral de projéteis · evitar: mover-se em ziguezague": duas voltas
	# com desfasamento, que deixam sempre um corredor a andar.
	for volta in 2:
		for i in 7:
			var ang := TAU * float(i) / 7.0 + volta * 0.42
			var dir := Vector2.RIGHT.rotated(ang)
			var atraso := volta * 0.34 + i * 0.045
			var tmr := get_tree().create_timer(atraso)
			tmr.timeout.connect(func() -> void:
				if is_instance_valid(self) and not _ja_derrotado:
					_lanca(global_position + Vector2(0, -8), dir, dano))


func _parede(dano: int) -> void:
	# "cria barreiras móveis · evitar: encontrar aberturas". A abertura é
	# real e é sempre uma: sem ela isto era dano inevitável, que os
	# princípios da prancha proíbem.
	var abertura := randi_range(0, 3)
	for lado in [-1.0, 1.0]:
		for i in 4:
			if i == abertura:
				continue
			var y := _chao_cache - 40.0 - i * 62.0
			var area := _nova_area(Vector2(global_position.x + lado * 60.0, y),
				_rect(34, 54))
			var poly := Polygon2D.new()
			poly.color = Color(ECO.r, ECO.g, ECO.b, 0.66)
			poly.polygon = PackedVector2Array([Vector2(-17, -27), Vector2(17, -27),
				Vector2(17, 27), Vector2(-17, 27)])
			area.add_child(poly)
			_dano_continuo(area, dano, lado)
			var t := area.create_tween()
			t.tween_property(area, "global_position:x",
				global_position.x + lado * 520.0, 1.5)
			t.parallel().tween_property(poly, "modulate:a", 0.0, 1.5)
			t.tween_callback(area.queue_free)


func _feixe(dano: int) -> void:
	# "feixe vertical massivo · dano muito alto". Cai onde o anel grande
	# do telégrafo ficou -- e o anel fica 1,05 s no chão antes disto.
	var x := _marcas[0].global_position.x if not _marcas.is_empty() else _x_alvo()
	var area := _nova_area(Vector2(x, _chao_cache - 230.0), _rect(104, 460))
	var poly := Polygon2D.new()
	poly.color = Color(1.0, 0.95, 0.82, 0.9)
	poly.polygon = PackedVector2Array([Vector2(-52, -230), Vector2(52, -230),
		Vector2(38, 230), Vector2(-38, 230)])
	area.add_child(poly)
	_dano_imediato(area, dano, signf(x - global_position.x))
	var t := area.create_tween()
	t.tween_property(poly, "scale:x", 0.2, 0.5)
	t.parallel().tween_property(poly, "modulate:a", 0.0, 0.5)
	t.tween_callback(area.queue_free)


## --- transição de fase -------------------------------------------------

func _ritual_de_ativacao() -> void:
	## "Aos 50 % de vida, Vyrak liberta todo o poder dos ecos. A arena é
	## transformada, mais sinos ativam-se." O colapso da torre fica para a
	## DERROTA, que é onde a prancha o põe -- na versão antiga o chefe
	## partia a torre a meio da luta e tirava plataformas ao jogador.
	_som("boss", -4.0, 0.9)
	_som("invocar", -5.0, 0.7)
	_abanar_camera(9.0)
	_mostrar_nucleo(false)
	for p in get_tree().get_nodes_in_group("plataformas_pico"):
		if not is_instance_valid(p):
			continue
		var tw := (p as Node).create_tween()
		tw.tween_property(p, "modulate", Color(1.25, 1.12, 0.86), 0.5)
	# aura da fase 2
	if _sprite:
		var tw2 := create_tween()
		tw2.tween_property(_sprite, "modulate", Color(1.2, 1.16, 1.35), 0.6)
	dano_contacto = int(round(dano_contacto * 1.15))


## --- marcas de telégrafo -----------------------------------------------

func _marca(n: Node2D) -> void:
	var pai := get_parent()
	if pai == null:
		return
	pai.add_child(n)
	_marcas.append(n)


func _marca_anel(onde: Vector2, r: float, cheio := false) -> void:
	var n := Node2D.new()
	n.global_position = onde
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		# elipse achatada: le'-se como um circulo DESENHADO NO CHAO, que e'
		# o que a prancha mostra ("circulo no chao")
		var a := TAU * float(i) / 20.0
		pts.append(Vector2(r * cos(a), r * 0.34 * sin(a)))
	poly.polygon = pts
	poly.color = Color(ECO.r, ECO.g, ECO.b, 0.30 if cheio else 0.20)
	n.add_child(poly)
	_marca(n)
	var t := n.create_tween().set_loops()
	t.tween_property(poly, "modulate:a", 1.0, 0.22)
	t.tween_property(poly, "modulate:a", 0.45, 0.22)


func _marca_arco(dir: float) -> void:
	var n := Node2D.new()
	n.global_position = global_position + Vector2(dir * 70.0, 4.0)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-dir * 18, -44),
		Vector2(dir * 76, -28), Vector2(dir * 72, 32), Vector2(-dir * 22, 44)])
	poly.color = Color(OURO.r, OURO.g, OURO.b, 0.22)
	n.add_child(poly)
	_marca(n)


func _marca_faixa(dir: float) -> void:
	var n := Node2D.new()
	n.global_position = Vector2(_base_x, global_position.y)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-dir * 380, -40),
		Vector2(dir * 380, -40), Vector2(dir * 380, 40), Vector2(-dir * 380, 40)])
	poly.color = Color(ECO.r, ECO.g, ECO.b, 0.18)
	n.add_child(poly)
	_marca(n)


func _brilho_asas() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", Color(1.5, 1.6, 2.0), 0.2)
	tw.tween_property(_sprite, "modulate", Color(1, 1, 1), 0.3)


func _limpar_marcas() -> void:
	for m in _marcas:
		if is_instance_valid(m):
			m.queue_free()
	_marcas.clear()


## --- utilitários de área/dano ------------------------------------------

func _rect(larg: float, alt: float) -> RectangleShape2D:
	var r := RectangleShape2D.new()
	r.size = Vector2(larg, alt)
	return r


func _circ(raio: float) -> CircleShape2D:
	var c := CircleShape2D.new()
	c.radius = raio
	return c


func _nova_area(onde: Vector2, forma: Shape2D) -> Area2D:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	cs.shape = forma
	a.add_child(cs)
	var pai := get_parent()
	if pai:
		pai.add_child(a)
	a.global_position = onde
	return a


## Dano a quem já lá está no instante em que a área nasce.
func _dano_imediato(area: Area2D, dano: int, dir: float) -> void:
	area.create_tween().tween_callback(func() -> void:
		for c in area.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(dano, dir))


## Dano a quem ENTRAR (projéteis, sinos a cair).
func _dano_imediato_ao_entrar(area: Area2D, dano: int) -> void:
	area.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, signf(c.global_position.x - area.global_position.x))
			area.queue_free())


## Dano a quem entrar, mas a área sobrevive (ondas, paredes).
func _dano_continuo(area: Area2D, dano: int, dir: float) -> void:
	area.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, dir))


func _golpe_corpo(dano: int, alc_x: float, alc_y: float) -> void:
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if absf(d.x) <= alc_x and absf(d.y) <= alc_y:
		k.receber_dano(dano, _investida_dir)


func _som(nome: String, vol: float, tom: float) -> void:
	Som.toca(nome, vol, tom)


## --- núcleo / dano -----------------------------------------------------

func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposto:
		_corpo.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	_exposto = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _nucleo:
		_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
		var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
		if luz:
			luz.energy = 1.7 if v else 0.12
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false,
		_forca_recuo := 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	# O sino ao peito é o ponto fraco: exposto, leva a dobrar. É a
	# recompensa por ler o telégrafo e é o que dá ritmo à luta.
	var q := quantidade * 2 if _exposto else quantidade
	super.receber_dano(q, dir_empurrao, critico)


func _exit_tree() -> void:
	_limpar_marcas()


## --- tamanho no ecrã ---------------------------------------------------
##
## A prancha poe o Vyrak a ~4x a Koliani (44 px) e da'-lhe asas de eco
## abertas -- nele, como no Guardiao dos Ceus da Regiao II, a LARGURA faz
## parte da silhueta. Por isso declara alvos proprios em vez de crescer
## pelo `escala_visual`: assim a normalizacao poe-no nos 176 px de alto
## (4,00x a Koliani, medido) e as asas cabem sem esticar o corpo.
## A cena fica com `escala_visual = 1.0`.

func _altura_alvo() -> float:
	return 176.0


func _largura_alvo() -> float:
	return 300.0


## --- utilitários --------------------------------------------------

func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 40.0
	var de := Vector2(x, _origem.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 760.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
