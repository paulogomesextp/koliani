class_name DemonioBase
extends CharacterBody2D
## Inimigo base: anda de um lado para o outro numa plataforma, vira quando
## bate numa parede ou chega à beira do alcance, e magoa a Koliani por
## contacto (via a Area2D "AreaContacto"). Classe-pai dos demónios
## especificos de cada mundo -- o agente "gaming" herda daqui.

const GRAVIDADE := 1400.0

@export var velocidade := 66.0
@export var vida := 58
@export var dano_contacto := 16
@export var alcance_patrulha := 120.0
## A que distância à frente se testa se ainda há chão (evita cair da
## plataforma na patrulha / na perseguição).
@export var margem_borda := 20.0
## Inimigo de emboscada (Vila dos Sem-Rosto, nível 21): fica quieto e
## inofensivo até a Koliani chegar a `raio_acorda` px -- aí "revela-se"
## (estremece) e passa a patrulhar/atacar como um demónio normal.
@export var dormente := false
@export var raio_acorda := 120.0
## Comportamento (pegada Dead Cells -- cada bicho tem uma ameaça própria):
##   patrulha -- anda de um lado para o outro (o de sempre)
##   saltador -- patrulha e, quando a Koliani está perto, dá um salto em
##               arco na direção dela
##   carga    -- patrulha e, quando a Koliani está perto, telegrafa
##               (estremece, pára) e depois arranca a alta velocidade
@export_enum("patrulha", "saltador", "carga") var comportamento := "patrulha"
const DUR_CARGA := 0.55
const MULT_CARGA := 3.4
const TELEGRAFO_CARGA := 0.42
var _acao_cd := 0.0
var _windup := 0.0
var _carga := 0.0
## Cor do rasto de partículas quando morre.
@export var cor_estilhacos := Color(0.7, 0.25, 0.45)
## Cor da luz de recorte (rim) do sprite -- normalmente o tom do bioma.
@export var cor_rim := Color(0.95, 0.5, 0.72)
## Que monstro pixel-art usar (pack CC0 LuizMelo "Monsters Creatures
## Fantasy"). Pastas em `assets/sprites/pixel/enemies/<especie>/`.
@export_enum("goblin", "mushroom", "esqueleto", "olho",
	"imp", "chort", "orc", "xamane", "demonio_grande", "ogro",
	"abobora", "wogol", "necromante", "lodo") var especie := "goblin"

## Frames por animação de cada espécie. luizmelo (goblin/mushroom/esqueleto/
## olho) = tiras 150x150. Os restantes vêm do 0x72 DungeonTileset II (CC0),
## extraídos por `tools/extrair_monstros_0x72.gd` (4 frames por anim).
const ESPECIES := {
	"goblin":    {"idle": 4, "run": 8, "hit": 4, "dead": 4},
	"mushroom":  {"idle": 4, "run": 8, "hit": 4, "dead": 4},
	"esqueleto": {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"olho":      {"idle": 8, "run": 8, "hit": 4, "dead": 4},
	"imp":            {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"chort":          {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"orc":            {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"xamane":         {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"demonio_grande": {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"ogro":           {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"abobora":        {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"wogol":          {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"necromante":     {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"lodo":           {"idle": 4, "run": 4, "hit": 4, "dead": 4},
}

@onready var _origem := global_position
@onready var _sprite: Node2D = $Sprite
@onready var _corpo: Sprite2D = get_node_or_null("Sprite/Corpo")
@onready var _anim: AnimatedSprite2D = get_node_or_null("Sprite/Anim")
@onready var _area_contacto: Area2D = $AreaContacto

var _direcao := 1.0
var _mat: ShaderMaterial
## true a partir do momento em que morre (toca a anim de morte e liberta-se).
var _morto := false
# animação procedural (visual): bob de idle/andar + antecipação (wind-up)
var _t_anim := 0.0
var _corpo_base := Vector2.ZERO
## Posto a 1.0 por quem quer um "wind-up" (chefes, no telegrafo).
var anticipacao := 0.0
## Recuo visual ao levar dano (roda o sprite para o lado do empurrão e
## decai a zero). Não afeta a física -- só o "juice".
var _flinch := 0.0
var _flinch_dir := 1.0
## Segundos que ainda está congelado (Torre dos Sinos: a badalada gela os
## inimigos comuns). Enquanto > 0 não patrulha nem persegue.
var _congelado := 0.0


## Gela este inimigo por `segundos` (a badalada do Sino, nível 11). Idempotente
## no sentido de ficar sempre com o maior tempo pendente.
func congelar(segundos: float) -> void:
	if _morto:
		return
	_congelado = maxf(_congelado, segundos)
	if _corpo:
		_corpo.modulate = Color(0.7, 0.85, 1.2)


## Os chefes (ChefeBase) sobrepõem isto para NÃO levarem a escala de mundo
## dos demónios comuns (têm a sua própria vida/dano).
func _e_chefe() -> bool:
	return false


func _ready() -> void:
	# dificuldade a subir ao longo de TODA a campanha, e devagar: o Nível 1
	# tem demónios MAIS FRACOS que o valor base (o jogo estava a começar
	# demasiado duro) e o Nível 30 fica ~x1.4. Curva linear em `indice_nivel`.
	if not _e_chefe():
		var f := float(clampi(EstadoJogo.indice_nivel, 0, 29)) / 29.0
		vida = maxi(1, int(round(vida * (0.8 + 0.6 * f))))
		dano_contacto = maxi(1, int(round(dano_contacto * (0.65 + 0.75 * f))))
		velocidade *= 0.88 + 0.34 * f

	if comportamento != "patrulha":
		_acao_cd = randf_range(0.6, 1.8)

	if _area_contacto:
		_area_contacto.body_entered.connect(_ao_tocar)
	if _corpo:
		_corpo_base = _corpo.position
		if _corpo.material is ShaderMaterial:
			_mat = _corpo.material
			_mat.set_shader_parameter("rim_cor", cor_rim)
	if _anim:
		_montar_frames()
		_anim.play("idle")
		_calibrar_pes()


## Espécies que voam -- não se alinham os pés ao chão.
const ESPECIES_VOAM := ["olho"]

## Alinha os PÉS do sprite com a linha de chão da colisão. Mede os pixels
## opacos do frame idle (há muito espaço transparente à volta do bicho na
## tira de 150x150), por isso é robusto para todas as espécies e escalas.
func _calibrar_pes() -> void:
	if _anim == null or _anim.sprite_frames == null or especie in ESPECIES_VOAM:
		return
	if not _anim.sprite_frames.has_animation("idle"):
		return
	var tex := _anim.sprite_frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return
	var r := img.get_used_rect()
	if r.size.y <= 0:
		return
	# distância do CENTRO do frame aos pés, já com a escala aplicada
	var pes_do_centro := (float(r.position.y + r.size.y) - float(img.get_height()) * 0.5) * _anim.scale.y
	# linha de chão = fundo da caixa de colisão do corpo
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or not (col.shape is RectangleShape2D):
		return
	var chao_y := col.position.y + (col.shape as RectangleShape2D).size.y * 0.5
	_anim.position.y = chao_y - pes_do_centro + 2.0  # +2 = enterra ligeiramente


## Monta os SpriteFrames a partir das tiras da espécie escolhida.
func _montar_frames() -> void:
	if _anim.sprite_frames != null:
		return  # a cena já traz os seus (chefes pixel-art)
	var cfg: Dictionary = ESPECIES.get(especie, ESPECIES["goblin"])
	var base := "res://assets/sprites/pixel/enemies/%s" % especie
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	_add_tira(sf, "idle", load("%s/idle.png" % base), int(cfg["idle"]), 9.0, true)
	_add_tira(sf, "run", load("%s/run.png" % base), int(cfg["run"]), 11.0, true)
	_add_tira(sf, "hit", load("%s/hit.png" % base), int(cfg["hit"]), 14.0, false)
	_add_tira(sf, "dead", load("%s/dead.png" % base), int(cfg["dead"]), 11.0, false)
	_anim.sprite_frames = sf


func _add_tira(sf: SpriteFrames, nome: String, tex: Texture2D, n: int, fps: float, ciclo: bool) -> void:
	sf.add_animation(nome)
	sf.set_animation_speed(nome, fps)
	sf.set_animation_loop(nome, ciclo)
	if tex == null:
		return
	var fw := tex.get_width() / maxi(1, n)
	var fh := tex.get_height()
	for i in n:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, fh)
		sf.add_frame(nome, at)


func _process(dt: float) -> void:
	if _anim:
		_atualizar_anim()
		return
	if _corpo == null:
		return
	_t_anim += dt
	anticipacao = move_toward(anticipacao, 0.0, dt * 3.5)
	_flinch = move_toward(_flinch, 0.0, dt * 6.0)
	var anda := absf(velocity.x) > 5.0
	var vel := 9.0 if anda else 3.2
	var amp := 1.8 if anda else 1.0
	_corpo.position.y = _corpo_base.y + sin(_t_anim * vel) * amp
	var resp := sin(_t_anim * vel * 0.5) * 0.03
	# wind-up: achata e alarga; flinch: comprime na horizontal + roda
	var sx := 1.0 - resp + anticipacao * 0.22 - _flinch * 0.25
	var sy := 1.0 + resp - anticipacao * 0.2 + _flinch * 0.2
	_corpo.scale = Vector2(sx, sy)
	if _sprite:
		_sprite.rotation = _flinch * _flinch_dir * 0.5


## Estado da anim do inimigo comum (idle/run). "hit" e "dead" mandam.
func _atualizar_anim() -> void:
	if _morto:
		return
	if _anim.animation == "hit" and _anim.is_playing():
		return
	var alvo := "run" if absf(velocity.x) > 6.0 else "idle"
	if _anim.animation != alvo:
		_anim.play(alvo)


func _physics_process(dt: float) -> void:
	if _morto:
		return
	if dormente:
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVIDADE * dt
		move_and_slide()
		var k := get_tree().get_first_node_in_group("koliani")
		if k and global_position.distance_to((k as Node2D).global_position) <= raio_acorda:
			_revelar()
		return
	if _congelado > 0.0:
		_congelado -= dt
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVIDADE * dt
		move_and_slide()
		if _congelado <= 0.0 and _corpo:
			_corpo.modulate = Color(1, 1, 1)
		return
	_acao_cd = maxf(0.0, _acao_cd - dt)

	# --- comportamentos especiais ---------------------------------------
	if comportamento == "carga":
		if _windup > 0.0:  # telegrafo: pára e estremece antes de arrancar
			_windup -= dt
			velocity.x = 0.0
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if _windup <= 0.0:
				_carga = DUR_CARGA
				Som.toca("demonio_ataque", -8.0, 0.85)
			return
		if _carga > 0.0:  # arranque comprometido -- não vira nem trava
			_carga -= dt
			velocity.x = _direcao * velocidade * MULT_CARGA
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if is_on_wall():
				_carga = 0.0
				_acao_cd = randf_range(1.8, 3.0)
			return
		var alvo_c := _dir_koliani_perto(320.0)
		if alvo_c != 0.0 and _acao_cd <= 0.0 and is_on_floor():
			_direcao = alvo_c
			if _sprite:
				_sprite.scale.x = _direcao
			_windup = TELEGRAFO_CARGA
			anticipacao = 1.0
			velocity.x = 0.0
			return
	elif comportamento == "saltador":
		if _acao_cd <= 0.0 and is_on_floor():
			var alvo_s := _dir_koliani_perto(230.0)
			if alvo_s != 0.0:
				_direcao = alvo_s
				if _sprite:
					_sprite.scale.x = _direcao
				velocity = Vector2(_direcao * 170.0, -430.0)
				anticipacao = 1.0
				_acao_cd = randf_range(1.5, 2.6)
				move_and_slide()
				return

	# --- patrulha normal ----------------------------------------------
	velocity.x = _direcao * velocidade
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	move_and_slide()

	if is_on_wall() or absf(global_position.x - _origem.x) > alcance_patrulha \
			or (is_on_floor() and not ha_chao_a_frente(_direcao)):
		_virar()


## Um inimigo de emboscada (`dormente`) "acorda": estremece e passa a
## comportar-se como um demónio normal. Idempotente.
func _revelar() -> void:
	if not dormente:
		return
	dormente = false
	anticipacao = 1.0
	_flinch = 1.0
	Som.toca("demonio_ataque", -10.0, 1.2)
	if _sprite:
		var t := _sprite.create_tween()
		t.tween_property(_sprite, "rotation", 0.25, 0.05)
		t.tween_property(_sprite, "rotation", -0.2, 0.06)
		t.tween_property(_sprite, "rotation", 0.0, 0.08)


func _virar() -> void:
	_direcao *= -1.0
	if _sprite:
		_sprite.scale.x = _direcao


## Direção horizontal (-1/+1) para a Koliani, se ela estiver a <= `alcance`
## px na horizontal e não muito abaixo. 0 = fora de alcance / sem alvo.
func _dir_koliani_perto(alcance: float) -> float:
	var k := get_tree().get_first_node_in_group("koliani")
	if k == null:
		return 0.0
	var d: Vector2 = (k as Node2D).global_position - global_position
	if absf(d.x) > alcance or d.y > 120.0:
		return 0.0
	return signf(d.x) if d.x != 0.0 else _direcao


## Há chão logo a seguir à beira, na direção `dir`? (raycast para baixo)
func ha_chao_a_frente(dir: float) -> bool:
	var espaco := get_world_2d().direct_space_state
	var origem := global_position + Vector2(signf(dir) * margem_borda, -6.0)
	var q := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0.0, 74.0), 1)
	q.exclude = [self]
	return not espaco.intersect_ray(q).is_empty()


func _ao_tocar(corpo: Node) -> void:
	if _morto or dormente:
		return
	if corpo is Koliani:
		corpo.receber_dano(dano_contacto, signf(corpo.global_position.x - global_position.x))
		Som.toca("demonio_ataque", -10.0, randf_range(0.9, 1.15))
		anticipacao = 1.0  # dá um "bote" visual no ataque


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _morto:
		return
	vida -= quantidade
	global_position.x += dir_empurrao * 8.0
	if vida <= 0:
		if _anim:
			_morrer_anim()
		else:
			soltar_estilhacos()
			queue_free()
	else:
		if dir_empurrao != 0.0:
			_flinch_dir = signf(dir_empurrao)
		_flinch = 1.0
		if _anim:
			_anim.play("hit")
		piscar_dano()


## Toca a animação de morte e só então solta estilhaços e liberta-se.
func _morrer_anim() -> void:
	_morto = true
	velocity = Vector2.ZERO
	if _area_contacto:
		_area_contacto.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	_anim.play("dead")
	await _anim.animation_finished
	soltar_estilhacos()
	queue_free()


## Flash branco curto ao levar dano (feedback de acerto).
func piscar_dano() -> void:
	if _mat:
		_mat.set_shader_parameter("flash", 1.0)
		var t := create_tween()
		t.tween_method(func(v: float): _mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.12)
	elif _anim:
		_anim.modulate = Color(3.0, 3.0, 3.0)
		create_tween().tween_property(_anim, "modulate", Color(1, 1, 1), 0.14)
	elif _sprite:
		_sprite.modulate = Color(2.2, 2.2, 2.2)
		create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)


## Larga um pequeno rebentamento de partículas na posição da morte. O nó
## das partículas fica no pai (o demónio vai ser libertado a seguir) e
## auto-liberta-se quando acaba.
func soltar_estilhacos() -> void:
	var pai := get_parent()
	if pai == null:
		return
	var p := CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 16
	p.lifetime = 0.5
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 350)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = cor_estilhacos
	pai.add_child(p)
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)
