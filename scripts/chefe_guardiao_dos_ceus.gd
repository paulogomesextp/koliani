class_name ChefeGuardiaoDosCeus
extends ChefeBase
## Região II / nível 10 -- GUARDIÃO DOS CÉUS, o confronto regional do
## Desfiladeiro dos Ventos (Process 12). Substitui "O Primeiro Prisioneiro",
## que era um duelo de espada e não examinava nada do que a região ensina.
##
## A luta é o EXAME das três leituras da região, e não uma mecânica nova:
##   1. LÂMINA -- rajada dirigida que se lê pelo telégrafo e se salta/afasta;
##   2. COMANDO DO VENTO -- ele vira o vento da arena (a `WindZone` que já
##      existe na cena), ANUNCIANDO antes: o mesmo vento das travessias,
##      agora dentro do combate;
##   3. QUEDA -- picada com zona de perigo desenhada no chão antes de cair.
##
## Depois de cada ataque desce e fica EXPOSTO ao alcance da espada: um
## chefe que voa e nunca aterra seria inatingível para quem chega aqui só
## com salto duplo. A fase 2 (50% de vida) não infla números -- encadeia
## (vento + lâmina em leque), encurta telégrafos e põe o vento a pulsar.
##
## O vento é SEMPRE força externa (identidade da Região II). Nada aqui
## mexe em gravidade, velocidade, habilidades ou save; a habilidade
## permanente `planar` continua a ser do N63 e o planar contextual do N08
## não é reaproveitado -- a arena joga-se com o kit normal.

## Nome da `WindZone` da arena, procurada no nível ao arrancar.
const NO_VENTO_ARENA := "VentoArena"
const LAMINA_VEL := 300.0

enum Fase {
	DORME, DECIDE,
	LAMINA_TEL, LAMINA,
	VENTO_TEL, VENTO,
	QUEDA_TEL, QUEDA,
	EXPOSTO,
}

@export var dist_deteta := 620.0
@export var altura_voo := 150.0
@export var altura_exposto := 46.0
@export var vel_desloca := 130.0
@export var vel_queda := 720.0
@export var dur_tel := 0.55
@export var dur_exposto := 1.35
@export var dur_vento := 3.4
@export var dano_lamina := 15
@export var dano_queda := 20
## Intensidade que o Guardião impõe à `WindZone` da arena (a da cena é a de
## repouso). Fica abaixo da corrente ascendente do N08 (2600): aqui o vento
## empurra a leitura do combate, não substitui o salto.
@export var vento_intensidade := 1250.0
@export var vento_velocidade_max := 260.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _ciclos := 0
var _vida_max := 0
var _chao_cache := 0.0
var _base_x := 0.0
var _queda_x := 0.0
var _exposto := false

## A `WindZone` da arena e o estado dela antes de o Guardião lhe tocar --
## para a repor exatamente como estava (morte, saída da cena, recarga).
var _vento: WindZone
var _vento_original: Dictionary = {}
var _vento_meu := false
## Marca no chão da zona de perigo da QUEDA (existe só durante o telégrafo).
var _marca: Node2D

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 540)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base_x = global_position.x
	_mostrar_nucleo(false)
	falas_intro = [
		{ "quem": "boss.guardiao_dos_ceus", "texto": "dlg.guardiao_ceus.intro.1" },
		{ "quem": "boss.guardiao_dos_ceus", "texto": "dlg.guardiao_ceus.intro.2" },
	]
	falas_fim = [
		{ "quem": "boss.guardiao_dos_ceus", "texto": "dlg.guardiao_ceus.win.1" },
	]
	call_deferred("_procurar_vento")


func _exit_tree() -> void:
	# Sair da cena (morte da Koliani, recarga do nível, fim do jogo) tem de
	# devolver o vento ao estado da cena: senão uma luta interrompida a meio
	# de um COMANDO deixava a arena a soprar para sempre.
	_repor_vento()
	if is_instance_valid(_marca):
		_marca.queue_free()
		_marca = null


## --- vento da arena ---------------------------------------------------

func _procurar_vento() -> void:
	var pai := get_parent()
	if pai == null:
		return
	var no := pai.get_node_or_null(NO_VENTO_ARENA)
	if no == null:
		# rede: qualquer zona de vento do nível que cubra a arena
		for z in get_tree().get_nodes_in_group("zonas_vento"):
			if z is WindZone and (z as Node2D).global_position.distance_to(global_position) < 420.0:
				no = z
				break
	_vento = no as WindZone
	if _vento:
		_vento_original = {
			"direcao": _vento.direcao,
			"intensidade": _vento.intensidade,
			"velocidade_max": _vento.velocidade_max,
			"modo": _vento.modo,
			"ativa": _vento.ativa,
		}


## Vira o vento da arena. Só é chamado DEPOIS do telégrafo -- o anúncio faz
## parte do contrato da região: nenhum vento entra sem aviso.
func _mandar_vento(sentido: Vector2) -> void:
	if _vento == null:
		return
	_vento_meu = true
	_vento.definir_direcao(sentido)
	_vento.intensidade = vento_intensidade * (1.18 if _fase2 else 1.0)
	_vento.velocidade_max = vento_velocidade_max
	_vento.modo = WindZone.Modo.PULSADO if _fase2 else WindZone.Modo.CONTINUO
	_vento.duracao_pulso = 0.8
	_vento.intervalo_pulso = 0.5
	_vento.ativa = true
	Som.toca("chefe_magia", -8.0, 1.05 if sentido.x >= 0.0 else 0.88)


func _repor_vento() -> void:
	if _vento == null or not _vento_meu or not is_instance_valid(_vento):
		_vento_meu = false
		return
	_vento_meu = false
	_vento.definir_direcao(_vento_original.get("direcao", Vector2.RIGHT))
	_vento.intensidade = _vento_original.get("intensidade", 0.0)
	_vento.velocidade_max = _vento_original.get("velocidade_max", 0.0)
	_vento.modo = _vento_original.get("modo", WindZone.Modo.CONTINUO)
	_vento.ativa = _vento_original.get("ativa", true)


## Verdadeiro enquanto o Guardião estiver a impor vento à arena. Os testes
## usam isto para provar que o estado fica limpo no fim da luta.
func vento_do_guardiao_ativo() -> bool:
	return _vento_meu


## Nome da fase em curso. Existe para o harness de testes poder provar a
## ORDEM (telégrafo antes do golpe) sem espreitar variáveis privadas.
func fase_atual() -> String:
	return Fase.keys()[_fase]


## Vida cheia desta luta (já com o afinamento de dificuldade aplicado).
func vida_maxima_luta() -> int:
	return _vida_max


func esta_em_fase2() -> bool:
	return _fase2


func esta_exposto() -> bool:
	return _exposto


## --- ciclo -------------------------------------------------------------

func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		# pairar: sobe e desce de leve, como quem se equilibra no ar
		_sprite.position.y = -3.0 * sin(_pulso * 2.2)
	if _nucleo and (_exposto or _fase2):
		var p := (1.0 if _exposto else 0.55) + 0.14 * sin(_pulso * 8.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(_base_x)
	if not _ja_derrotado and not _fase2 and vida <= int(_vida_max * 0.5):
		_abrir_asas()

	match _fase:
		Fase.DORME:
			velocity = Vector2.ZERO
			_pairar(dt, altura_voo)
			_encarar_koliani()
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_pairar(dt, altura_voo)
			_seguir_koliani(dt)
			_encarar_koliani()
			if _t >= (0.24 if _fase2 else 0.36):
				_escolher()
		# 1. LÂMINA -----------------------------------------------------
		Fase.LAMINA_TEL:
			_pairar(dt, altura_voo)
			velocity.x = 0.0
			_encarar_koliani()
			_piscar(true)
			if _t >= _tel():
				_piscar(false)
				atacar_anim()
				var de := global_position + Vector2(0, -8)
				var base := _dir_para(de)
				if _fase2:
					for a in [-0.26, 0.0, 0.26]:
						_lamina(de, base.rotated(a))
				else:
					_lamina(de, base)
				_ir(Fase.LAMINA)
		Fase.LAMINA:
			_pairar(dt, altura_voo)
			if _t >= 0.35:
				_ir(Fase.EXPOSTO)
		# 2. COMANDO DO VENTO -------------------------------------------
		Fase.VENTO_TEL:
			_pairar(dt, altura_voo + 16.0)
			velocity.x = 0.0
			_encarar_koliani()
			_piscar(true)
			# o anúncio dura MAIS que um telégrafo normal: o jogador tem de
			# ver para que lado vai soprar antes de o vento existir
			if _t >= _tel() * 1.5:
				_piscar(false)
				atacar_anim()
				_mandar_vento(Vector2(_dir_para_koliani(), 0.0))
				_ir(Fase.VENTO)
		Fase.VENTO:
			_pairar(dt, altura_voo)
			_seguir_koliani(dt)
			_encarar_koliani()
			if _t >= dur_vento:
				_repor_vento()
				# fase 2 encadeia: o vento acaba já com uma lâmina a caminho
				_ir(Fase.LAMINA_TEL if _fase2 else Fase.EXPOSTO)
		# 3. QUEDA ------------------------------------------------------
		Fase.QUEDA_TEL:
			_pairar(dt, altura_voo + 40.0)
			velocity.x = 0.0
			if _t < dt:
				_queda_x = _x_koliani()
				_marcar_queda(_queda_x)
			global_position.x = move_toward(global_position.x, _queda_x, 260.0 * dt)
			_piscar(true)
			if _t >= _tel() * 1.3:
				_piscar(false)
				_limpar_marca()
				Som.toca("investida", -6.0, 0.85)
				_ataque_forte = 0.5
				_ir(Fase.QUEDA)
		Fase.QUEDA:
			velocity.x = 0.0
			velocity.y = vel_queda
			move_and_slide()
			if global_position.y >= _chao_cache - 30.0 or is_on_floor():
				_impacto()
				_ir(Fase.EXPOSTO)
			_t += dt
			return
		# recuperação: ao alcance da espada -----------------------------
		Fase.EXPOSTO:
			_pairar(dt, altura_exposto)
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
			if not _exposto:
				_mostrar_nucleo(true)
			if _t >= dur_exposto:
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)

	move_and_slide()
	_t += dt


func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


## Alterna os três ataques em vez de os sortear: um exame lê-se, não se
## adivinha. A ordem muda na fase 2 (vento antes da queda) para o padrão
## não ficar decorado.
func _escolher() -> void:
	if not _ve_koliani():
		_ir(Fase.DORME)
		return
	var dx := absf(_vetor_para_koliani().x)
	if _fase2:
		# fase 2: o vento vem mais cedo no ciclo e arrasta a lâmina atrás
		match _ciclos % 3:
			0: _ir(Fase.LAMINA_TEL)
			1: _ir(Fase.VENTO_TEL)
			_: _ir(Fase.QUEDA_TEL)
		return
	match _ciclos % 3:
		0:
			_ir(Fase.LAMINA_TEL)
		1:
			# a picada quer a Koliani a jeito; de longe vale mais uma lâmina
			_ir(Fase.QUEDA_TEL if dx < 300.0 else Fase.LAMINA_TEL)
		_:
			_ir(Fase.VENTO_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 400.0


func _tel() -> float:
	return dur_tel * (0.78 if _fase2 else 1.0)


## Sobe/desce até à altura pedida acima do chão da arena, sem gravidade: é
## um chefe que voa. A `_prender_na_arena` do `ChefeBase` trata do X.
func _pairar(dt: float, altura: float) -> void:
	var alvo := _chao_cache - altura
	velocity.y = 0.0
	global_position.y = lerpf(global_position.y, alvo, clampf(dt * 4.0, 0.0, 1.0))


func _seguir_koliani(dt: float) -> void:
	var d := _vetor_para_koliani()
	if d == Vector2.ZERO or absf(d.x) < 60.0:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * dt)
		return
	velocity.x = move_toward(velocity.x, signf(d.x) * vel_desloca, 700.0 * dt)


## --- ataques ----------------------------------------------------------

func _dir_para(de: Vector2) -> Vector2:
	var k := _obter_koliani()
	if k == null:
		return Vector2(_direcao, 0)
	return (k.global_position + Vector2(0, -16) - de).normalized()


## Lâmina de vento: projétil com rasto, dano ao tocar. Área própria, como
## os dardos dos outros chefes -- não há sistema de projéteis partilhado.
func _lamina(de: Vector2, dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	Som.toca("projetil", -10.0, 1.15)
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.global_position = de
	pai.add_child(a)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 9.0
	forma.shape = cs
	a.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.72, 0.92, 1.0, 0.95)
	poly.polygon = PackedVector2Array([
		Vector2(-14, 0), Vector2(0, -6), Vector2(14, 0), Vector2(0, 6)])
	poly.rotation = dir.angle()
	a.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.6
	luz.color = Color(0.7, 0.9, 1.0)
	luz.scale = Vector2(0.32, 0.32)
	a.add_child(luz)
	var dano := int(round(dano_lamina * (1.12 if _fase2 else 1.0)))
	a.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, signf(dir.x))
		a.queue_free())
	var t := a.create_tween()
	t.tween_property(a, "global_position", de + dir * 1200.0, 1200.0 / LAMINA_VEL)
	t.tween_callback(a.queue_free)


## Zona de perigo da QUEDA, desenhada no chão durante o telégrafo. Sem ela
## a picada seria um ataque impossível de ler.
func _marcar_queda(x: float) -> void:
	_limpar_marca()
	var pai := get_parent()
	if pai == null:
		return
	var chao := _chao_y(x)
	var marca := Node2D.new()
	marca.name = "MarcaQueda"
	marca.global_position = Vector2(x, chao - 4.0)
	pai.add_child(marca)
	var poly := Polygon2D.new()
	poly.color = Color(0.95, 0.75, 0.45, 0.4)
	poly.polygon = PackedVector2Array([
		Vector2(-96, 0), Vector2(96, 0), Vector2(96, -6), Vector2(-96, -6)])
	marca.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.5
	luz.color = Color(1.0, 0.8, 0.5)
	luz.scale = Vector2(1.1, 0.35)
	marca.add_child(luz)
	var t := marca.create_tween()
	t.set_loops()
	t.tween_property(poly, "modulate:a", 0.35, 0.18)
	t.tween_property(poly, "modulate:a", 1.0, 0.18)
	_marca = marca


func _limpar_marca() -> void:
	if is_instance_valid(_marca):
		_marca.queue_free()
	_marca = null


## Impacto da QUEDA: sopro curto no chão, só dentro da faixa marcada.
func _impacto() -> void:
	Som.toca("demonio_ataque", -6.0, 0.8)
	_abanar_camera(8.0)
	var k := _obter_koliani()
	if k:
		var d := k.global_position - global_position
		if absf(d.x) <= 104.0 and absf(d.y) <= 90.0:
			k.receber_dano(int(round(dano_queda * (1.1 if _fase2 else 1.0))),
				signf(d.x) if not is_zero_approx(d.x) else _direcao)
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, 6)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.5
	p.spread = 180.0
	p.direction = Vector2.UP
	p.gravity = Vector2(0, 700)
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 240.0
	p.color = Color(0.8, 0.92, 1.0)
	add_sibling(p)
	p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)


## --- fase 2 ------------------------------------------------------------

## 50% de vida: as asas abrem. Não sobe números às cegas -- encurta
## telégrafos, encadeia vento->lâmina, põe o vento a pulsar e a lâmina em
## leque. O EXPOSTO continua a existir: o chefe nunca deixa de ser
## atingível.
func _abrir_asas() -> void:
	_fase2 = true
	Som.toca("grito", -8.0, 1.1)
	_abanar_camera(9.0)
	dur_exposto = maxf(0.8, dur_exposto * 0.88)
	dano_contacto = int(round(dano_contacto * 1.1))
	if _sprite:
		_sprite.modulate = Color(0.86, 0.96, 1.2, 1.0)
	var p := CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 30
	p.lifetime = 0.8
	p.spread = 180.0
	p.direction = Vector2.UP
	p.gravity = Vector2(0, 260)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 260.0
	p.color = Color(0.78, 0.93, 1.0)
	add_sibling(p)
	p.get_tree().create_timer(1.3).timeout.connect(p.queue_free)
	_ir(Fase.VENTO_TEL)


## --- núcleo / dano ----------------------------------------------------

func _mostrar_nucleo(v: bool) -> void:
	_exposto = v
	_pulso = 0.0
	_frame_corpo(3 if (v or _fase2) else 0)
	if _nucleo:
		_nucleo.scale = Vector2.ONE * (1.0 if v else (0.5 if _fase2 else 0.35))
		var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
		if luz:
			luz.energy = 1.6 if v else (0.5 if _fase2 else 0.12)
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v or _fase2


func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if not _exposto and not _fase2:
		_frame_corpo(2 if ligado else 0)


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false,
		_forca_recuo := 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	super.receber_dano(quantidade, dir_empurrao, critico)
	if _ja_derrotado:
		# o vento é dele: cai o Guardião, cai o vento da arena
		_repor_vento()
		_limpar_marca()


## A folha estática de reserva pode ter menos poses que o rig animado (que
## a esconde na maioria das cenas): pedir um frame que não existe enche o
## log de erros. Só troca de pose se a folha as tiver mesmo.
func _frame_corpo(indice: int) -> void:
	if _corpo == null or _corpo.texture == null:
		return
	if indice < _corpo.hframes * _corpo.vframes:
		_corpo.frame = indice


## --- utilitários ------------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 120.0
	var de := Vector2(x, _origem.y - 40.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 640.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 120.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)


static var _luz_cache: GradientTexture2D

func _tex_luz() -> GradientTexture2D:
	if _luz_cache:
		return _luz_cache
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	_luz_cache = tex
	return tex
