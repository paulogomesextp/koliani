class_name ChefeCoracaoPutrefacto
extends ChefeBase
## Região I / nível 05 -- O Coração Putrefacto. Um coração púrpura gigante
## preso num emaranhado de raízes e cadáveres, no centro da arena. Não se
## desloca: pulsa. Toda a luta anda ao ritmo da "batida da floresta" (o
## mesmo relógio das `PlataformaRitmada`).
##
## A cada SÍSTOLE o núcleo abre-se por um instante -- é a ÚNICA janela de
## dano, e a dobrar. Entre batidas, ataca conforme a fase:
##   * Fase 1 (vida > 50%): raízes sob os pés da Koliani (`RaizPerigo`) +
##     salvas de projéteis dirigidos (`ProjetilZeriko`).
##   * Fase 2 (vida <= 50%): combina o padrão base com um leque radial em
##     cada batida e ALIVIA a gravidade da Koliani
##     (`Koliani.flutuar`) -- "o coração bate e altera a gravidade".
## A plataforma principal permanece contínua: o desafio cresce por padrão e
## combinação, não por retirar chão ao jogador.

const RAIZ := preload("res://scenes/actors/RaizPerigo.tscn")
const TIRO := preload("res://scenes/actors/ProjetilZeriko.tscn")

enum Fase { DORME, ENTRE, RAIZES_TEL, RAIZES, TIROS_TEL, TIROS }

@export var periodo_batida := 2.0
@export var dur_exposta := 0.72
@export var dur_tel := 0.55
@export var dano_raiz := 18
@export var dano_tiro := 15
@export var dano_entulho := 20

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _nivel := 1  ## 1 ou 2
var _nucleo_exposto := false
var _ciclos := 0
var _vida_max := 460
var _ultimo_frac := 0.0
var _combate := false

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")

## Execution 9E.2 -- arte de produção (Região I, manifesto dos inimigos). Com
## ela: fase 1 = forma contida, fase 2 = forma intensificada (`idle_f2`,
## `hit_f2`), erupção de corrupção na transição, núcleo alinhado com o da arte.
## Sem ela, tudo fica como antes. Nada disto toca em vida, dano ou tempos.
const CORACAO_ID := "coracao_putrefacto"
var _prod := false
## 9G: aura de corrupção da fase 2.
var _aura_f2: AnimatedSprite2D


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 360)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_prod = not Inimigos9D.entrada(self, CORACAO_ID).is_empty()
	if _prod:
		_alinhar_nucleo("fase_1")
		# a luz da sístole foi pensada para o coração pequeno do legado: a este
		# raio (~300 px no ecrã) lava o corpo todo de rosa. Encolhida, fica um
		# brilho só no núcleo -- a janela de dano continua a ler-se (a energia
		# e o tempo não mudam).
		var luz_n := _nucleo.get_node_or_null("Luz") as Node2D if _nucleo else null
		if luz_n:
			luz_n.scale *= 0.4
		# idem para a luz magenta constante do coração (~330 px): pinta a casca
		# escura de rosa. Fica um halo à volta do núcleo.
		var luz_c := get_node_or_null("Sprite/LuzCoracao") as Node2D
		if luz_c:
			luz_c.scale *= 0.4
	_mostrar_nucleo(false)


## O Coração de produção é mais largo que alto: com o teto de 110 dos
## guardiões ficava raso. A 150 mantém a altura de sempre (100 x 1.7).
func _largura_alvo() -> float:
	if not Inimigos9D.entrada(self, CORACAO_ID).is_empty():
		return 150.0
	return super._largura_alvo()


## Fase 2 da arte: a forma intensificada substitui a contida; o golpe da fase
## 2 recua a forma intensificada. A fase 1 é o comportamento de sempre.
func _atualizar_anim() -> void:
	if not _prod or _nivel < 2:
		super._atualizar_anim()
		return
	if _morto:
		return
	if _anim.animation in ["hit", "hit_f2"] and _anim.is_playing():
		return
	if _anim.animation != "idle_f2":
		_anim.play("idle_f2")


## Põe o ponto fraco (`Nucleo`) e a luz em cima do núcleo desenhado na arte.
func _alinhar_nucleo(fase: String) -> void:
	var c: Array = (Inimigos9D.entrada(self, CORACAO_ID).get("nucleo_no_frame", {}) as Dictionary).get(fase, [])
	if c.size() < 2 or _anim == null or _anim.sprite_frames == null:
		return
	var tex := _anim.sprite_frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var meio := Vector2(tex.get_width(), tex.get_height()) * 0.5
	var pos := _anim.position + (Vector2(float(c[0]), float(c[1])) - meio) * _anim.scale
	if _nucleo:
		_nucleo.position = pos
	var luz := get_node_or_null("Sprite/LuzCoracao") as Node2D
	if luz:
		luz.position = pos


## VFX separado da transição para a fase 2: a erupção de corrupção da
## autoridade, na base do corpo, a subir e a apagar-se. Só visual.
func _erupcao() -> void:
	var v: Dictionary = (Inimigos9D.entrada(self, CORACAO_ID).get("vfx", {}) as Dictionary).get("erupcao", {})
	var tex := load(String(v.get("ficheiro", ""))) as Texture2D if not v.is_empty() else null
	if tex == null:
		return
	var s := Sprite2D.new()
	s.name = "Erupcao9E2"
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = 1
	s.scale = Vector2.ONE * escala_visual
	var base_y := 0.0
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		base_y = col.position.y + (col.shape as RectangleShape2D).size.y * 0.5
	s.position = Vector2(0.0, base_y - tex.get_height() * escala_visual * 0.5)
	add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position:y", s.position.y - 22.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 1.1).set_delay(0.35)
	tw.tween_callback(s.queue_free)


## 9G: a fase 2 não é só "mais depressa" -- a corrupção passa a arder à volta
## do corpo, sem tocar no núcleo (é o ponto fraco) nem tapar a silhueta.
func _aura_fase2() -> void:
	if _aura_f2 != null or not Vfx9G.ativo(self):
		return
	_aura_f2 = Vfx9G.novo("charge_aura_corrupcao", true)
	if _aura_f2 == null:
		return
	_aura_f2.z_index = -2
	_aura_f2.scale = Vector2.ONE * 2.6
	_aura_f2.modulate.a = 0.55
	_aura_f2.position = Vector2(0.0, 10.0)
	add_child(_aura_f2)
	_aura_f2.play("ciclo")


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		# pulsar constante do coração (bombeia mais forte quando exposto)
		var amp := 0.05 if not _nucleo_exposto else 0.14
		var p := 1.0 + amp * sin(_pulso * (PI * 2.0 / periodo_batida) * (2.0 if _nucleo_exposto else 1.0))
		_sprite.scale = Vector2(_direcao * escala_visual * p, escala_visual * p)
	if _nucleo and _nucleo_exposto:
		var q := 1.0 + 0.18 * sin(_pulso * 12.0)
		_nucleo.scale = Vector2(q, q)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	_atualiza_fase()

	if _fase == Fase.DORME:
		if _ve_koliani():
			provocar()
			_combate = true
			_ir(Fase.ENTRE)
		_t += dt
		return

	# batida partilhada com as plataformas (mesmo relógio Time.get_ticks_msec)
	var f := fmod(Time.get_ticks_msec() / 1000.0 / maxf(0.1, periodo_batida), 1.0)
	if f < _ultimo_frac:
		_bater()
	_ultimo_frac = f

	match _fase:
		Fase.ENTRE:
			if _t >= periodo_batida * 0.5:
				_escolher()
		Fase.RAIZES_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_raizes()
				_ir(Fase.RAIZES)
		Fase.RAIZES:
			if _t >= 0.5:
				_ir(Fase.ENTRE)
		Fase.TIROS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_salva_dirigida()
				_ir(Fase.TIROS)
		Fase.TIROS:
			if _t >= 0.5:
				_ir(Fase.ENTRE)
	_t += dt


## --- ritmo -----------------------------------------------------------

func _bater() -> void:
	if not _combate or _ja_derrotado:
		return
	Som.toca("onda", -10.0, 0.7)
	_abanar_camera(3.0 + _nivel)
	_mostrar_nucleo(true)
	get_tree().create_timer(dur_exposta).timeout.connect(func() -> void:
		if is_instance_valid(self):
			_mostrar_nucleo(false))

	if _nivel >= 2:
		var k := _obter_koliani()
		if k and k.has_method("flutuar"):
			k.flutuar(periodo_batida * 0.8)
		_leque_radial()


## --- máquina de estados / fases -------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _escolher() -> void:
	_ciclos += 1
	# alterna pressão de chão e espaçamento; a fase 2 combina o pulso radial
	# previsível com este mesmo padrão em vez de apenas multiplicar dano.
	if _ciclos % 2 == 0:
		_ir(Fase.RAIZES_TEL)
	else:
		_ir(Fase.TIROS_TEL)


func _atualiza_fase() -> void:
	if _ja_derrotado:
		return
	var novo := fase_por_vida(vida, _vida_max)
	if novo != _nivel:
		_nivel = novo
		_atualizar_frame()
		if _prod and _nivel == 2:
			_alinhar_nucleo("fase_2")
			_erupcao()
		if _nivel == 2:
			_aura_fase2()
		Som.toca("chefe_cai", -9.0, 0.7)
		_abanar_camera(6.0)
		if _nivel == 2:
			periodo_batida *= 0.85
			dur_tel *= 0.8


static func fase_por_vida(vida_atual: int, vida_maxima: int) -> int:
	return 2 if vida_atual <= int(maxi(vida_maxima, 1) * 0.5) else 1


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= 520.0 and absf(d.y) <= 320.0


## --- ataques -------------------------------------------------------

func _raizes() -> void:
	Som.toca("praga", -9.0, 1.2)
	var origem := global_position.x
	var alvo := _x_koliani()
	var n := 3 if _nivel == 1 else 4
	for i in n:
		var fr := float(i) / float(maxi(1, n - 1))
		_raiz_em(lerpf(origem + signf(alvo - origem) * 60.0, alvo, fr), 0.12 + fr * 0.4)


func _raiz_em(x: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var r := RAIZ.instantiate()
	pai.add_child(r)
	r.global_position = Vector2(x, _chao_y(x))
	r.avisar(int(round(dano_raiz * (1.0 + 0.1 * (_nivel - 1)))), atraso)


func _salva_dirigida() -> void:
	var k := _obter_koliani()
	if k == null:
		return
	Som.toca("praga", -9.0, 0.9)
	var base := (k.global_position - global_position).normalized()
	var n := 3 if _nivel == 1 else 5
	for i in n:
		var ang := deg_to_rad((i - (n - 1) * 0.5) * 12.0)
		_tiro(base.rotated(ang))


func _leque_radial() -> void:
	Som.toca("praga", -8.0, 0.7)
	var n := 8 if _nivel == 2 else 12
	for i in n:
		_tiro(Vector2.RIGHT.rotated(TAU * float(i) / float(n)))


func _tiro(dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var t := TIRO.instantiate()
	t.dano = dano_tiro
	t.velocidade = 240.0 + 40.0 * _nivel
	pai.add_child(t)
	t.global_position = global_position + dir * 34.0
	t.lancar(dir)


func _queda_entulho(x: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var topo_y := global_position.y - 260.0
	var chao := _chao_y(x)

	var bloco := Area2D.new()
	bloco.collision_layer = 0
	bloco.collision_mask = 2
	bloco.global_position = Vector2(x, topo_y)
	pai.add_child(bloco)

	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(34, 34)
	forma.shape = rs
	bloco.add_child(forma)

	var poly := Polygon2D.new()
	poly.color = Color(0.14, 0.1, 0.12, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-18, -16), Vector2(16, -18), Vector2(19, 15), Vector2(-16, 18)])
	bloco.add_child(poly)

	var bateu := [false]
	bloco.body_entered.connect(func(corpo: Node) -> void:
		if not bateu[0] and corpo is Koliani:
			bateu[0] = true
			corpo.receber_dano(dano_entulho, 0.0)
			bloco.queue_free())

	var tw := bloco.create_tween()
	tw.tween_property(bloco, "global_position:y", chao, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(bloco, "rotation", randf_range(-1.5, 1.5), 0.5)
	tw.tween_property(poly, "modulate:a", 0.0, 0.25)
	tw.tween_callback(bloco.queue_free)


func _desmoronar_um_pedaco() -> void:
	var plats := get_tree().get_nodes_in_group("plataformas_coracao")
	for p in plats:
		if is_instance_valid(p) and p.visible:
			p.visible = false  # marca para não repetir
			var tw := p.create_tween()
			tw.tween_property(p, "modulate:a", 0.0, 0.35)
			tw.tween_callback(p.queue_free)
			_abanar_camera(4.0)
			return


## --- núcleo / dano ----------------------------------------------------

## Escolhe o frame da tira pixel-art conforme o estado: sístole (batida) usa
## o frame "grande/aceso"; entre batidas usa o frame da fase actual.
func _atualizar_frame() -> void:
	if _corpo == null:
		return
	if _nucleo_exposto:
		_corpo.frame = 2 if _nivel >= 2 else 1
	else:
		_corpo.frame = 0


func _mostrar_nucleo(v: bool) -> void:
	_nucleo_exposto = v
	_atualizar_frame()
	if _nucleo == null:
		return
	_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
	var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
	if luz:
		luz.energy = 1.8 if v else 0.14
	var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
	if brilho:
		brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	super.receber_dano(quantidade, dir_empurrao, critico)
	if _prod and _nivel >= 2 and _anim and _anim.animation == "hit" \
			and _anim.sprite_frames.has_animation("hit_f2"):
		_anim.play("hit_f2")


## --- utilitários ----------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return global_position.y + 200.0
	var de := Vector2(x, global_position.y - 40.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 600.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else global_position.y + 260.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
