class_name ChefeGuardiaoDaFornalha
extends ChefeBase
## Região IV / nível 20 -- GUARDIÃO DA FORNALHA, o ÚNICO boss verdadeiro da
## Região IV (contrato: `region_04/boss_pack.png`, `level_mechanics.png` N20).
## Máquina ancestral alimentada pela lava, ~4x a Koliani. Luta PARADA no chão
## da arena (não anda; só a INVESTIDA o desloca), por padrões e não por RNG:
##
## FASE 1 -- "O teste do aço" (100% a 50% de vida):
##   1. GOLPE VERTICAL -- ergue o martelo; zona à frente marcada no chão.
##   2. ONDA DE LAVA   -- a pancada manda uma onda rasteira: SALTA-SE.
##   3. CHAMAS DO NÚCLEO -- símbolos acendem no chão e sobem jatos: SAI-SE.
## FASE 2 -- "A verdade em chamas" (50% a 0%): telégrafos mais curtos, os
##   ataques encadeiam (golpe -> onda), as chamas ganham uma coluna e entram
##   mais dois:
##   4. INVESTIDA -- recua, inclina-se e corre pela arena (fica EXPOSTO).
##   5. ERUPÇÃO   -- o chão principal acende; as DUAS plataformas
##      secundárias são o refúgio (telégrafo longo, nunca dano inevitável).
##
## Depois de cada ataque fica EXPOSTO (núcleo à vista, janela de ataque).
## Reset: a morte da Koliani recarrega a cena; o `_exit_tree` apaga também
## tudo o que ele pôs no mundo (ondas, colunas, marcas, erupção).

const LAVA_CLARA := Color(1.0, 0.78, 0.30, 1.0)
const LAVA := Color(1.0, 0.42, 0.10, 1.0)
const LAVA_ESCURA := Color(0.55, 0.14, 0.06, 1.0)

enum Fase {
	DORME, DECIDE,
	GOLPE_TEL, GOLPE,
	ONDA_TEL, ONDA,
	CHAMAS_TEL, CHAMAS,
	INVEST_TEL, INVEST,
	ERUPCAO_TEL, ERUPCAO,
	TRANSFORMA, EXPOSTO,
}

@export var dist_deteta := 700.0
@export var dur_tel := 0.75
@export var dur_exposto := 1.7
@export var dano_golpe := 26
@export var dano_onda := 20
@export var dano_chamas := 22
@export var dano_investida := 30
@export var dano_erupcao := 32
## Zona do GOLPE à frente do boss (px a partir do centro).
@export var golpe_ini := 50.0
@export var golpe_fim := 200.0
@export var onda_vel := 250.0
@export var onda_altura := 34.0
@export var invest_vel := 400.0
@export var invest_dur := 0.85
## Faixa (X global) por onde o boss se move; fora dela ficam as plataformas
## de refúgio, para o corpo nunca as atravessar. 0/0 = a do chão medido.
@export var faixa_esq := 0.0
@export var faixa_dir := 0.0
## Extensão da lava da ERUPÇÃO (X global); 0/0 = a faixa do boss.
@export var lava_esq := 0.0
@export var lava_dir := 0.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _ciclos := 0
var _vida_max := 0
var _chao_cache := 0.0
var _exposto := false
var _encadeia := false
var _acertou := false
## Já pôs a marca de telégrafo desta fase.
var _marcou := false
var _alvos: Array[float] = []
## Tudo o que o boss pôs no mundo (para limpar ao morrer / sair da cena).
var _lixo: Array[Node] = []
## Ordem em que o boss entrou nas fases de ataque (os testes leem isto).
var historico: Array[String] = []
var _arena_x0 := 0.0
var _arena_x1 := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 680)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_mostrar_nucleo(false)
	falas_intro = [
		{ "quem": "boss.guardiao_da_fornalha", "texto": "dlg.guardiao_fornalha.intro.1" },
		{ "quem": "boss.guardiao_da_fornalha", "texto": "dlg.guardiao_fornalha.intro.2" },
	]
	falas_fim = [
		{ "quem": "boss.guardiao_da_fornalha", "texto": "dlg.guardiao_fornalha.win.1" },
	]


func _exit_tree() -> void:
	_limpar_tudo()


func _limpar_tudo() -> void:
	for n in _lixo:
		if is_instance_valid(n):
			n.queue_free()
	_lixo.clear()


## --- consulta (testes / HUD) -------------------------------------------

func fase_atual() -> String:
	return Fase.keys()[_fase]


func vida_maxima_luta() -> int:
	return _vida_max


func esta_em_fase2() -> bool:
	return _fase2


func esta_exposto() -> bool:
	return _exposto


func perigos_ativos() -> int:
	var n := 0
	for x in _lixo:
		if is_instance_valid(x):
			n += 1
	return n


## --- ciclo ---------------------------------------------------------------

func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _nucleo and (_exposto or _fase2):
		var p := (1.0 if _exposto else 0.55) + 0.12 * sin(_pulso * 8.0)
		_nucleo.scale = Vector2(p, p)


func _anim_desejada() -> String:
	match _fase:
		Fase.GOLPE_TEL, Fase.GOLPE, Fase.ONDA_TEL, Fase.ONDA:
			return "attack"
		Fase.CHAMAS_TEL, Fase.CHAMAS, Fase.ERUPCAO_TEL, Fase.ERUPCAO:
			return "cast"
		Fase.INVEST_TEL:
			return "attack"
		Fase.INVEST:
			return "run"
		Fase.TRANSFORMA:
			return "transform"
		Fase.EXPOSTO:
			return "hit"
		_:
			return ""


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _ja_derrotado and not _fase2 and vida <= int(_vida_max * 0.5):
		_ir(Fase.TRANSFORMA)
		_entrar_fase2()
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	else:
		velocity.y = 0.0

	match _fase:
		Fase.DORME:
			velocity.x = 0.0
			_encarar_koliani()
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			velocity.x = 0.0
			_encarar_koliani()
			if _t >= (0.35 if _fase2 else 0.55):
				_escolher()
		# 1. GOLPE VERTICAL -----------------------------------------------
		Fase.GOLPE_TEL:
			velocity.x = 0.0
			_piscar(true)
			if not _marcou:
				_marcou = true
				_marcar_golpe()
			if _t >= _tel():
				_piscar(false)
				_limpar_marcas()
				_golpe()
				_ir(Fase.GOLPE)
		Fase.GOLPE:
			velocity.x = 0.0
			if _t >= 0.4:
				if _encadeia:
					_encadeia = false
					_ir(Fase.ONDA_TEL)
				else:
					_ir(Fase.EXPOSTO)
		# 2. ONDA DE LAVA ----------------------------------------------------
		Fase.ONDA_TEL:
			velocity.x = 0.0
			_piscar(true)
			if _t >= _tel() * (0.7 if _encadeia else 1.0):
				_piscar(false)
				_onda()
				_ir(Fase.ONDA)
		Fase.ONDA:
			velocity.x = 0.0
			if _t >= 0.45:
				_ir(Fase.EXPOSTO)
		# 3. CHAMAS DO NÚCLEO -------------------------------------------------
		Fase.CHAMAS_TEL:
			velocity.x = 0.0
			_piscar(true)
			if not _marcou:
				_marcou = true
				_marcar_chamas()
			if _t >= _tel() * 1.25:
				_piscar(false)
				_disparar_chamas()
				_ir(Fase.CHAMAS)
		Fase.CHAMAS:
			velocity.x = 0.0
			if _t >= 0.9:
				_limpar_marcas()
				_ir(Fase.EXPOSTO)
		# 4. INVESTIDA (fase 2) -------------------------------------------------
		Fase.INVEST_TEL:
			# recua um passo para o lado contrário
			velocity.x = -_direcao * 90.0
			_encarar_koliani_fixo()
			_piscar(true)
			if _t >= _tel():
				_piscar(false)
				_ataque_forte = invest_dur
				_som_ataque("investida", -5.0, 0.8, 0.03, 0.2)
				_ir(Fase.INVEST)
		Fase.INVEST:
			velocity.x = _direcao * invest_vel
			if _t >= invest_dur or _no_limite():
				velocity.x = 0.0
				_abanar_camera(6.0)
				_ir(Fase.EXPOSTO)
		# 5. ERUPÇÃO (fase 2) ----------------------------------------------------
		Fase.ERUPCAO_TEL:
			velocity.x = 0.0
			_piscar(true)
			if not _marcou:
				_marcou = true
				_marcar_erupcao()
			if _t >= 1.7:
				_piscar(false)
				_erupcao()
				_ir(Fase.ERUPCAO)
		Fase.ERUPCAO:
			velocity.x = 0.0
			if _t >= 1.1:
				_limpar_marcas()
				_ir(Fase.EXPOSTO)
		Fase.TRANSFORMA:
			velocity.x = 0.0
			if _t >= 1.5:
				_ir(Fase.DECIDE)
		# recuperação: janela de ataque ---------------------------------------------
		Fase.EXPOSTO:
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
	_acertou = false
	_marcou = false
	var nome: String = Fase.keys()[f]
	if nome.ends_with("_TEL") or nome == "TRANSFORMA":
		historico.append(nome)
		_tocar_clipe(f)


## Reinicia o clipe no início do telégrafo, com a velocidade pensada para a
## preparação durar exactamente o telégrafo (a pancada cai na pose de golpe).
func _tocar_clipe(f: Fase) -> void:
	var a := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if a == null or a.sprite_frames == null:
		return
	var nome := _anim_desejada()
	if nome == "" or not a.sprite_frames.has_animation(nome):
		return
	a.play(nome)
	a.speed_scale = 1.0
	if nome == "attack":
		var fps := a.sprite_frames.get_animation_speed("attack")
		var dur := maxf(_tel(), 0.2)
		a.speed_scale = 6.0 / (fps * dur)


func _escolher() -> void:
	if not _ve_koliani():
		_ir(Fase.DORME)
		return
	var dx := absf(_vetor_para_koliani().x)
	if _fase2:
		# padrão fixo de 5 ciclos: golpe+onda, chamas, investida, golpe, erupção
		match _ciclos % 5:
			0:
				_encadeia = true
				_ir(Fase.GOLPE_TEL)
			1: _ir(Fase.CHAMAS_TEL)
			2: _ir(Fase.INVEST_TEL)
			3: _ir(Fase.ONDA_TEL if dx > 260.0 else Fase.GOLPE_TEL)
			_: _ir(Fase.ERUPCAO_TEL)
		return
	# fase 1: golpe -> onda -> chamas (a onda quando está longe)
	match _ciclos % 3:
		0: _ir(Fase.GOLPE_TEL if dx < 320.0 else Fase.ONDA_TEL)
		1: _ir(Fase.ONDA_TEL)
		_: _ir(Fase.CHAMAS_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 420.0


func _tel() -> float:
	return dur_tel * (0.8 if _fase2 else 1.0)


func _encarar_koliani_fixo() -> void:
	pass


func _no_limite() -> bool:
	var x := global_position.x
	return (_direcao > 0.0 and x >= _arena_dir - 6.0) or (_direcao < 0.0 and x <= _arena_esq + 6.0)


## --- criação de perigos -------------------------------------------------------

func _novo_perigo(pos: Vector2, tam: Vector2, cor: Color, dano: int, dir_emp: float,
		ativo := true, textura := "") -> Area2D:
	var pai := get_parent()
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.monitoring = ativo
	a.z_index = -1   # atras da Koliani e do boss: o perigo le-se sem os tapar
	pai.add_child(a)
	a.global_position = pos
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = tam
	forma.shape = rs
	a.add_child(forma)
	var poly := Polygon2D.new()
	poly.name = "Corpo"
	poly.color = cor
	poly.polygon = PackedVector2Array([
		Vector2(-tam.x / 2, -tam.y / 2), Vector2(tam.x / 2, -tam.y / 2),
		Vector2(tam.x / 2, tam.y / 2), Vector2(-tam.x / 2, tam.y / 2)])
	a.add_child(poly)
	if textura != "" and ResourceLoader.exists(textura):
		var tex := load(textura) as Texture2D
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.scale = Vector2(tam.x / float(tex.get_width()) * 1.5, tam.y / float(tex.get_height()))
		a.add_child(sp)
		poly.visible = false
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.7
	luz.color = LAVA
	luz.scale = Vector2(maxf(tam.x, 60.0) / 70.0, maxf(tam.y, 40.0) / 70.0)
	a.add_child(luz)
	a.body_entered.connect(func(c: Node) -> void:
		if c is Koliani and a.monitoring:
			c.receber_dano(dano, dir_emp))
	_lixo.append(a)
	return a


func _marca(centro_x: float, larg: float, cor: Color, nome := "Marca") -> Node2D:
	var pai := get_parent()
	var m := Node2D.new()
	m.name = nome
	pai.add_child(m)
	m.global_position = Vector2(centro_x, _chao_cache - 3.0)
	m.z_index = -1
	var poly := Polygon2D.new()
	poly.color = cor
	poly.polygon = PackedVector2Array([
		Vector2(-larg / 2, 0), Vector2(larg / 2, 0), Vector2(larg / 2, -7), Vector2(-larg / 2, -7)])
	m.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.55
	luz.color = LAVA_CLARA
	luz.scale = Vector2(larg / 90.0, 0.35)
	m.add_child(luz)
	var t := m.create_tween()
	t.set_loops()
	t.tween_property(poly, "modulate:a", 0.35, 0.16)
	t.tween_property(poly, "modulate:a", 1.0, 0.16)
	m.add_to_group("marcas_guardiao")
	_lixo.append(m)
	return m


func _limpar_marcas() -> void:
	for m in get_tree().get_nodes_in_group("marcas_guardiao"):
		if is_instance_valid(m):
			_lixo.erase(m)
			m.queue_free()


# 1. GOLPE ---------------------------------------------------------------------

func _golpe_centro() -> float:
	return global_position.x + _direcao * (golpe_ini + golpe_fim) * 0.5


func _marcar_golpe() -> void:
	_marca(_golpe_centro(), golpe_fim - golpe_ini, Color(1.0, 0.5, 0.18, 0.5))


func _golpe() -> void:
	_som_impacto("esmagar", -4.0, 0.8)
	_abanar_camera(8.0)
	var k := _obter_koliani()
	if k:
		var dx := (k.global_position.x - global_position.x) * _direcao
		var dy := absf(k.global_position.y - (_chao_cache - 20.0))
		if dx >= golpe_ini - 12.0 and dx <= golpe_fim + 12.0 and dy <= 70.0:
			k.receber_dano(int(round(dano_golpe * (1.1 if _fase2 else 1.0))), _direcao)
	_fagulhas(Vector2(_golpe_centro(), _chao_cache - 4.0), 26)


# 2. ONDA ------------------------------------------------------------------------

func _onda() -> void:
	_som_ataque("onda", -6.0, 0.7, 0.03, 0.3)
	_abanar_camera(5.0)
	var dir := _direcao
	var x0 := global_position.x + dir * golpe_fim
	var dano := int(round(dano_onda * (1.1 if _fase2 else 1.0)))
	var a := _novo_perigo(Vector2(x0, _chao_cache - onda_altura / 2.0), Vector2(46.0, onda_altura),
		Color(1.0, 0.5, 0.14, 0.9), dano, dir)
	var dist := 1500.0
	var t := a.create_tween()
	t.tween_property(a, "global_position:x", x0 + dir * dist, dist / (onda_vel * (1.15 if _fase2 else 1.0)))
	t.tween_callback(func() -> void:
		_lixo.erase(a)
		a.queue_free())


# 3. CHAMAS ------------------------------------------------------------------------

func _marcar_chamas() -> void:
	_alvos.clear()
	var kx := _obter_koliani().global_position.x if _obter_koliani() else global_position.x
	var n := 4 if _fase2 else 3
	for i in n:
		var x := kx + (i - (n - 1) * 0.5) * 150.0
		x = clampf(x, _arena_esq + 60.0, _arena_dir - 60.0)
		_alvos.append(x)
		_marca(x, 70.0, Color(1.0, 0.45, 0.12, 0.55))


func _disparar_chamas() -> void:
	_som_ataque("onda", -7.0, 1.2, 0.03, 0.3)
	_abanar_camera(4.0)
	var dano := int(round(dano_chamas * (1.1 if _fase2 else 1.0)))
	for x in _alvos:
		var a := _novo_perigo(Vector2(x, _chao_cache - 110.0), Vector2(58.0, 220.0),
			Color(1.0, 0.62, 0.2, 0.85), dano, signf(x - global_position.x), true,
			"res://assets/sprites/pixel/deco/fornalha/r4_jato_fogo.png")
		var t := a.create_tween()
		t.tween_interval(0.7)
		t.tween_callback(func() -> void:
			_lixo.erase(a)
			a.queue_free())


# 5. ERUPÇÃO ----------------------------------------------------------------------

func _marcar_erupcao() -> void:
	var lx := _lava_x()
	_marca((lx.x + lx.y) / 2.0, lx.y - lx.x, Color(1.0, 0.3, 0.08, 0.35), "MarcaErupcao")


func _erupcao() -> void:
	_limpar_marcas()
	_som_ataque("investida", -4.0, 0.6, 0.03, 0.4)
	_abanar_camera(10.0)
	var lx := _lava_x()
	var dano := int(round(dano_erupcao))
	# a lava ocupa a faixa baixa (60 px) do chão principal; as plataformas ficam acima
	var a := _novo_perigo(Vector2((lx.x + lx.y) / 2.0, _chao_cache - 30.0),
		Vector2(lx.y - lx.x, 60.0), Color(1.0, 0.4, 0.1, 0.55), dano, 0.0)
	a.name = "LavaErupcao"
	var t := a.create_tween()
	t.tween_interval(1.0)
	t.tween_callback(func() -> void:
		_lixo.erase(a)
		a.queue_free())


# efeitos ---------------------------------------------------------------------------

func _fagulhas(pos: Vector2, n: int) -> void:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = n
	p.lifetime = 0.6
	p.spread = 70.0
	p.direction = Vector2.UP
	p.gravity = Vector2(0, 700)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 260.0
	p.color = LAVA
	add_sibling(p)
	p.global_position = pos
	p.get_tree().create_timer(1.3).timeout.connect(p.queue_free)


## --- fase 2 ------------------------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	_limpar_marcas()
	_piscar(false)
	_som_fase("fogo")
	_abanar_camera(9.0)
	dur_exposto = maxf(1.1, dur_exposto * 0.85)
	dano_contacto = int(round(dano_contacto * 1.1))
	var a := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if a:
		a.modulate = Color(1.15, 0.95, 0.9, 1.0)
	_fagulhas(global_position + Vector2(0, 40), 40)


## --- núcleo / dano -------------------------------------------------------------------

func _mostrar_nucleo(v: bool) -> void:
	_exposto = v
	_pulso = 0.0
	if _nucleo:
		_nucleo.scale = Vector2.ONE * (1.0 if v else (0.5 if _fase2 else 0.3))
		var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
		if luz:
			luz.energy = 1.5 if v else (0.5 if _fase2 else 0.15)
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v or _fase2


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false,
		_forca_recuo := 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	super.receber_dano(quantidade, 0.0, critico)   # nunca empurra o boss: fica na arena
	if _ja_derrotado:
		_limpar_tudo()


## O boss é uma massa de ~4x a Koliani: só o contacto com o CORPO magoa, e o
## dano do contacto sobe durante a investida (`_ataque_forte`).

## --- utilitários ----------------------------------------------------------------------

func _altura_alvo() -> float:
	return 170.0


func _largura_alvo() -> float:
	return 240.0


func _medir_arena() -> void:
	super._medir_arena()
	if faixa_dir > faixa_esq:
		_arena_esq = faixa_esq
		_arena_dir = faixa_dir
	elif _arena_esq == 0.0 and _arena_dir == 0.0:
		_arena_esq = global_position.x - 450.0
		_arena_dir = global_position.x + 450.0
	_arena_x0 = _arena_esq
	_arena_x1 = _arena_dir


func _lava_x() -> Vector2:
	if lava_dir > lava_esq:
		return Vector2(lava_esq, lava_dir)
	return Vector2(_arena_esq, _arena_dir)


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return global_position.y + 75.0
	var de := Vector2(x, global_position.y - 40.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 500.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else global_position.y + 75.0


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
