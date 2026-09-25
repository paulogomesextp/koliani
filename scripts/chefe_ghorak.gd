class_name ChefeGhorak
extends ChefeBase
## Regiao I / nivel 01 -- Ghorak, o Guardiao Raiz. MINI-BOSS do N1 (nao e' o
## chefe regional: esse e' o Coracao Putrefacto, no N5).
##
## LOOP (F1/N1, so' com correr + saltar + ataque normal):
##
##   CASCA  -- fora das janelas a casca de raiz e osso aguenta o golpe
##             (`RESIST_CASCA` do dano, sem recuo, som seco de bloqueio). Bater
##             sem parar da' ~5 % do dano: a luta nao se ganha a fazer spam.
##   EXPOSTO -- o nucleo purpura do peito abre-se (frame 3 + brilho a pulsar) e
##             SO' ai' o golpe entra por inteiro. A janela fecha com o nucleo
##             a piscar nos ultimos 0,4 s.
##
## ATAQUES (cada um: pose de aviso + som NO INICIO do aviso -> execucao -> recovery):
##   BAQUE  -- ergue-se (aviso), salta, cai: onda rasteira que so' magoa quem
##             esta' no chao ao alcance (salta-se por cima). Depois fica
##             EXPOSTO (janela grande). E' a "abertura" que a luta ensina.
##   RAIZES -- planta uma zona de raizes a volta da Koliani com o aviso
##             (racha no chao) VISIVEL antes de irromperem: obriga a sair dali.
##             Depois fica EXPOSTO (as raizes irrompem a meio da janela: bate-se
##             e desvia-se).
##   CARGA  -- crava a pose, o rumo trava-se a meio do aviso, investe uma
##             distancia fixa e fica EXPOSTO por pouco tempo (castigo do esquiva).
##   CICLO: atacar -> ficar EXPOSTO (ajoelhado, nucleo aberto, sem magoar) -> atacar...
##   CURTO  -- golpe curto e lento SO' quando a Koliani cola ao corpo: pune
##             quem fica encostado a bater (sem risco).
##
## FASE 2 (< 50 %): mesmo vocabulario, encadeado -- raizes seguidas de carga,
## baque com raizes a nascer na janela (a ganancia paga-se), duas zonas de
## raizes em vez de uma, avisos e janelas mais curtos, recovery da carga menor.
##
## Regra global: nada arranca fora do campo visual (`Som.em_vista`).

const RAIZ := preload("res://scenes/actors/RaizPerigo.tscn")

enum Fase { DORME, DECIDE, CURTO_TEL, CURTO, CURTO_REC, BAQUE_TEL, BAQUE, EXPOSTO,
		MARCAS_TEL, MARCAS_REC, CARGA_TEL, CARGA, CARGA_EXPOSTO, ROAR }

## Fracao do dano que a casca deixa passar fora das janelas.
const RESIST_CASCA := 0.05
## Padroes por fase (indice ciclico). Fase 2 usa combos (`_encadear`).
const PADRAO_F1 := ["BAQUE", "RAIZES", "CARGA", "BAQUE"]
const PADRAO_F2 := ["BAQUE+RAIZES", "CARGA", "RAIZES", "BAQUE+RAIZES"]

@export var dist_deteta := 380.0
@export var vel_passo := 34.0
@export var vel_aproxima := 95.0
## Escalados pelo `ChefeBase` (alivio da Regiao I): dur_tel x1,06, dur_baque x0,92,
## dur_exposto x0,85. Os valores base ja' tem isso em conta.
@export var dur_tel := 0.75
@export var dur_baque := 0.35
@export var dur_exposto := 3.05
## Nao escalados.
@export var dur_marcas_tel := 0.6
@export var dur_marcas_rec := 0.4
@export var dur_raizes_exposto := 1.8
@export var atraso_raiz := 1.6
@export var dur_carga_tel := 0.9
@export var vel_carga := 560.0
@export var dist_carga := 460.0
@export var dur_carga_exposto := 2.0
@export var dur_curto_tel := 0.5
@export var dur_curto_rec := 0.45
@export var raio_onda := 280.0
@export var dano_onda := 22
@export var dano_raiz := 18
@export var dano_carga := 24
@export var dano_curto := 16

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _onda_feita := false
var _fase2 := false
var _nucleo_exposto := false
var _ciclos := 0
var _vida_max := 420
var _seguinte := ""            # o que a maquina decidiu fazer a seguir
var _encadear := ""            # 2.o elo de um combo da fase 2
var _dir_carga := 1.0
var _x_carga_ini := 0.0
var _carga_feriu := false
var _curto_feriu := false
var _curto_cd := 0.0
var _piscou_fim := false
var _dur_janela := 0.0         # duracao da janela EXPOSTO em curso
var _casca_cd := 0.0
## Diagnostico/testes: quantas vezes cada ataque arrancou.
var contagem := {"BAQUE": 0, "RAIZES": 0, "CARGA": 0, "CURTO": 0}

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 250)
	_vida_max = vida
	velocidade = vel_passo
	alcance_patrulha = maxf(alcance_patrulha, 120.0)
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_casca_cd = maxf(0.0, _casca_cd - dt)
	if _nucleo and _nucleo_exposto:
		_pulso += dt
		var p := 1.0 + 0.16 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)
		# a janela esta' a fechar: o nucleo pisca (aviso legivel)
		var restante := _dur_janela - _t
		if restante < 0.4 and _dur_janela > 0.0:
			var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
			if brilho:
				brilho.visible = int(_pulso * 12.0) % 2 == 0


func _physics_process(dt: float) -> void:
	_curto_cd = maxf(0.0, _curto_cd - dt)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5) \
			and _fase in [Fase.DECIDE, Fase.CURTO_REC]:
		_entrar_fase2()

	match _fase:
		Fase.DORME:
			super._physics_process(dt)  # patrulha lenta (DemonioBase)
			# so' acorda com a Koliani perto E o boss a' vista
			if _ve_koliani() and Som.em_vista(self):
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_decidir(dt)
		Fase.CURTO_TEL:
			_travar(dt)
			_encarar_koliani()
			if _t >= dur_curto_tel:
				_piscar(false)
				_ir(Fase.CURTO)
		Fase.CURTO:
			_travar(dt)
			if not _curto_feriu:
				_curto_feriu = true
				_golpe_curto()
			if _t >= 0.15:
				_ir(Fase.CURTO_REC)
		Fase.CURTO_REC:
			_travar(dt)
			if _t >= dur_curto_rec:
				_ir(Fase.DECIDE)
		Fase.BAQUE_TEL:
			_travar(dt)
			_encarar_koliani()
			if _t >= dur_tel:
				_piscar(false)
				velocity.y = -240.0  # pequeno salto antes do baque
				_som_ataque("investida", -10.0, 0.8)
				_ir(Fase.BAQUE)
		Fase.BAQUE:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * dt)
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			_prender_na_arena()
			if is_on_floor() and _t > 0.06 and not _onda_feita:
				_onda_feita = true
				_baque()
			if _onda_feita and _t >= dur_baque:
				_abrir_janela(dur_exposto * (0.8 if _fase2 else 1.0), Fase.EXPOSTO)
		Fase.EXPOSTO:
			_travar(dt)
			if _fase2 and _encadear == "RAIZES" and _t >= 0.5:
				# a ganancia paga-se: as raizes marcam-se A MEIO da janela
				_encadear = ""
				_plantar_zona(1.0)
			if _t >= _dur_janela:
				_fechar_janela()
		Fase.MARCAS_TEL:
			_travar(dt)
			_encarar_koliani()
			if _t >= dur_marcas_tel:
				_piscar(false)
				_ir(Fase.MARCAS_REC)
		Fase.MARCAS_REC:
			_travar(dt)
			if _t >= dur_marcas_rec:
				# TODO ataque acaba numa janela: as raizes irrompem a meio dela
				_abrir_janela(dur_raizes_exposto * (0.8 if _fase2 else 1.0), Fase.EXPOSTO)
		Fase.CARGA_TEL:
			_travar(dt)
			# o rumo trava-se aos 60 % do aviso: ate' la' ainda acompanha
			if _t < dur_carga_tel * 0.6:
				_encarar_koliani()
				_dir_carga = _direcao
			if _t >= dur_carga_tel:
				_piscar(false)
				_x_carga_ini = global_position.x
				_carga_feriu = false
				_ataque_forte = 1.0
				_som_ataque("investida", -6.0, 0.62)
				_abanar_camera(3.0)
				_ir(Fase.CARGA)
		Fase.CARGA:
			velocity.x = _dir_carga * vel_carga
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			_prender_na_arena()
			_ferir_na_carga()
			var andou := absf(global_position.x - _x_carga_ini)
			if andou >= dist_carga or _t > 1.3 or (is_on_wall() and _t > 0.1):
				_ataque_forte = 0.0
				velocity.x = 0.0
				_abanar_camera(4.0)
				_abrir_janela(dur_carga_exposto * (0.7 if _fase2 else 1.0), Fase.CARGA_EXPOSTO)
		Fase.CARGA_EXPOSTO:
			_travar(dt)
			if _t >= _dur_janela:
				_fechar_janela()
		Fase.ROAR:
			_travar(dt)
			if _t >= 0.9:
				_piscar(false)
				_ir(Fase.DECIDE)
	_t += dt


## --- maquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0
	_onda_feita = false


func _vulneravel() -> bool:
	return _fase == Fase.EXPOSTO or _fase == Fase.CARGA_EXPOSTO


func _abrir_janela(dur: float, f: Fase) -> void:
	_dur_janela = dur
	_mostrar_nucleo(true)
	_ir(f)
	# o som de "abre" chega com a pose: legivel sem olhar para o nucleo
	Som.toca("mecanismo", -14.0, 1.5, 0.02, 0.2, "ghorak_abre", Som.Prioridade.NORMAL)


func _fechar_janela() -> void:
	_mostrar_nucleo(false)
	_dur_janela = 0.0
	_ciclos += 1
	_ir(Fase.DECIDE)


## DECIDE: aproxima-se, escolhe e ARRANCA o ataque (com o aviso). Nada disto
## acontece com o boss fora do campo visual.
func _decidir(dt: float) -> void:
	_encarar_koliani()
	if not Som.em_vista(self):
		_travar(dt)
		return
	var dx := absf(_vetor_para_koliani().x)
	if _seguinte == "":
		_seguinte = _proximo_ataque()
	# perto demais: golpe curto (pune o "encostado"), com cooldown proprio
	if dx <= 110.0 and _curto_cd <= 0.0 and _t >= 0.15:
		_curto_cd = 3.5
		contagem["CURTO"] += 1
		_curto_feriu = false
		_piscar(true)
		_som_ataque("garra", -9.0, 0.8)
		_ir(Fase.CURTO_TEL)
		return
	# o BAQUE quer a Koliani ao alcance da onda: aproxima-se ate' la'
	var precisa_perto := _seguinte.begins_with("BAQUE")
	if precisa_perto and dx > raio_onda * 0.8 and _t < 1.6:
		velocity.x = move_toward(velocity.x, _direcao * vel_aproxima, 900.0 * dt)
		if not is_on_floor():
			velocity.y += GRAVIDADE * dt
		move_and_slide()
		_prender_na_arena()
		return
	_travar(dt)
	if _t < 0.35:
		return
	var a := _seguinte
	_seguinte = ""
	var partes := a.split("+")
	_encadear = partes[1] if partes.size() > 1 else ""
	match partes[0]:
		"BAQUE":
			contagem["BAQUE"] += 1
			_piscar(true)
			_som_ataque("olho_carregar", -9.0, 0.6)
			_ir(Fase.BAQUE_TEL)
		"RAIZES":
			contagem["RAIZES"] += 1
			_piscar(true)
			_som_ataque("praga", -8.0)
			_plantar_zona(1.0)
			_ir(Fase.MARCAS_TEL)
		"CARGA":
			contagem["CARGA"] += 1
			_iniciar_carga_tel()


func _proximo_ataque() -> String:
	var padrao: Array = PADRAO_F2 if _fase2 else PADRAO_F1
	return String(padrao[_ciclos % padrao.size()])


func _iniciar_carga_tel() -> void:
	_piscar(true)
	_som_ataque("grito", -7.0, 0.7)
	_abanar_camera(1.5)
	_ir(Fase.CARGA_TEL)


func _travar(dt: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1000.0 * dt)
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	move_and_slide()
	_prender_na_arena()


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 220.0


## --- ataques ---------------------------------------------------------

func _baque() -> void:
	_som_impacto("esmagar", -5.0)
	_abanar_camera(5.0)
	var k := _obter_koliani()
	if k and absf((k.global_position - global_position).x) <= raio_onda and k.is_on_floor():
		k.receber_dano(dano_onda, signf(k.global_position.x - global_position.x))
	_particulas_onda()


func _golpe_curto() -> void:
	_som_impacto("esmagar", -12.0, 1.3)
	var k := _obter_koliani()
	if k == null:
		return
	var d := k.global_position - global_position
	if absf(d.x) <= 150.0 and absf(d.y) <= 110.0 and signf(d.x) == _direcao:
		k.receber_dano(dano_curto, signf(d.x))


func _ferir_na_carga() -> void:
	if _carga_feriu:
		return
	var k := _obter_koliani()
	if k == null:
		return
	var d := k.global_position - global_position
	if absf(d.x) <= 74.0 and absf(d.y) <= 110.0:
		_carga_feriu = true
		k.receber_dano(dano_carga, signf(d.x))


## Uma ZONA de raizes: 3 raizes a volta da Koliani, com o aviso (racha no chao)
## visivel `atraso_raiz` s antes de irromperem -- nunca nascem sem aviso. Na
## fase 2 ha' uma 2.a zona, mais tarde, do lado oposto ao do boss.
func _plantar_zona(_escala: float) -> void:
	var x0 := _x_koliani()
	for i in [-1, 0, 1]:
		_plantar_em(x0 + float(i) * 105.0, atraso_raiz)
	if _fase2:
		var lado := -signf(_dir_para_koliani())
		if lado == 0.0:
			lado = 1.0
		_plantar_em(x0 + lado * 300.0, atraso_raiz + 0.45)
		_plantar_em(x0 + lado * 405.0, atraso_raiz + 0.45)


func _plantar_em(x: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	if _arena_ok:
		x = clampf(x, _arena_esq + 30.0, _arena_dir - 30.0)
	var r := RAIZ.instantiate()
	pai.add_child(r)
	r.global_position = Vector2(x, _chao_y(x))
	r.avisar(int(round(dano_raiz * (1.15 if _fase2 else 1.0))), maxf(atraso, 0.9))


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	_mostrar_nucleo(false)
	_som_fase("carne")
	_abanar_camera(7.0)
	dur_tel *= 0.85
	dur_carga_tel *= 0.85
	dur_curto_tel *= 0.85
	velocidade = vel_passo * 1.25
	vel_aproxima *= 1.2
	_ciclos = 0
	_seguinte = ""
	_encadear = ""
	_piscar(true)
	_raizes_de_fundo()
	_ir(Fase.ROAR)


func _raizes_de_fundo() -> void:
	var pai := get_parent()
	if pai == null:
		return
	for i in 7:
		var x := global_position.x - 700.0 + i * 200.0 + randf_range(-40.0, 40.0)
		var raiz := Polygon2D.new()
		raiz.color = Color(0.06, 0.1, 0.04, 0.92)
		var h := randf_range(130.0, 250.0)
		raiz.polygon = PackedVector2Array([
			Vector2(-14, 0), Vector2(-6, -h * 0.5), Vector2(-9, -h * 0.8),
			Vector2(0, -h), Vector2(8, -h * 0.75), Vector2(6, -h * 0.4), Vector2(15, 0),
		])
		raiz.global_position = Vector2(x, _chao_y(x))
		raiz.z_index = -5
		raiz.scale.y = 0.0
		pai.add_child(raiz)
		var t := raiz.create_tween()
		t.tween_interval(i * 0.05)
		t.tween_property(raiz, "scale:y", 1.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## --- nucleo / dano -------------------------------------------------

## Na janela o Ghorak esta' ABERTO e parado: encostar-se para bater NAO magoa
## (era isto que tornava a luta impossivel -- a janela pedia a Koliani ao pe' do
## corpo, e o contacto tirava-lhe vida). Fora da janela o contacto magoa.
func _ao_tocar(corpo: Node) -> void:
	if _vulneravel():
		return
	super._ao_tocar(corpo)


## Telegrafo -> frame 2 (bracos erguidos) da tira pixel-art.
func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _nucleo_exposto:
		_corpo.frame = 2 if ligado else 0
	if not ligado and _sprite:
		# o `super` repoe o branco: volta o tom da casca (fechada) / do nucleo (aberto)
		_sprite.modulate = Color(1.45, 1.25, 1.1) if _nucleo_exposto else Color(0.9, 0.95, 0.9)


func _mostrar_nucleo(v: bool) -> void:
	_nucleo_exposto = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _sprite and not v:
		_sprite.modulate = Color(0.9, 0.95, 0.9)   # casca fechada: mais baço
	elif _sprite:
		_sprite.modulate = Color(1.45, 1.25, 1.1)  # aberto: quente e claro
	if _nucleo == null:
		return
	_nucleo.scale = Vector2.ONE * (1.0 if v else 0.5)
	var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
	if luz:
		luz.energy = 1.8 if v else 0.15
	var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
	if brilho:
		brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false,
		_forca_recuo := 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if _vulneravel() or _fase == Fase.DORME:
		super.receber_dano(quantidade, dir_empurrao, critico)
		return
	# CASCA: o golpe entra so' em fracao, sem recuo e sem critico, com o
	# feedback seco de "isto nao e' a janela".
	var q := maxi(1, int(round(float(quantidade) * RESIST_CASCA)))
	if vida - q <= 0:
		super.receber_dano(quantidade, dir_empurrao, false)
		return
	vida -= q
	vida_mudou.emit(maxi(vida, 0), _vida_maxima)
	if _casca_cd <= 0.0:
		_casca_cd = 0.1
		Som.toca("bloqueio", -9.0, 0.85, 0.03, 0.0, "", Som.Prioridade.NORMAL)
		Impacto.rebentar(self, global_position + Vector2(0.0, -30.0 * maxf(0.8, escala_visual)),
			Color(0.62, 0.78, 0.55), 1.3)


## --- utilitarios --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var espaco := get_world_2d().direct_space_state
	var de := Vector2(x, global_position.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 280.0), 1)
	q.exclude = [self]
	var hit := espaco.intersect_ray(q)
	return (hit["position"].y as float) if hit else global_position.y + 34.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)


func _particulas_onda() -> void:
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, 30)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 28
	p.lifetime = 0.55
	p.direction = Vector2(1, -0.15)
	p.spread = 22.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 360.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(0.4, 0.6, 0.28)
	add_sibling(p)
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)
