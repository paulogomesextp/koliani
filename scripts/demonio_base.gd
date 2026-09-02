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
##   patrulha  -- anda de um lado para o outro (o de sempre)
##   saltador  -- patrulha e, quando a Koliani está perto, salta em arco nela
##   carga     -- patrulha, telegrafa (estremece, pára) e arranca a alta vel.
##   voador    -- sem gravidade, paira à volta da origem e MERGULHA na Koliani
##   escudeiro -- patrulha; golpes de FRENTE são bloqueados pelo escudo (só
##                o pisão ou um golpe pelas costas o magoam)
##   trepador  -- agarrado ao tecto acima; solta-se e cai quando a Koliani
##                passa por baixo, depois anda como patrulha
##   cuspidor  -- patrulha; à distância, pára, telegrafa e COSPE um projétil
##                (BolaFogo) na direção da Koliani; recua a atacar de longe
@export_enum("patrulha", "saltador", "carga", "voador", "escudeiro", "trepador", "cuspidor") var comportamento := "patrulha"
const DUR_CARGA := 0.55
const MULT_CARGA := 3.4
const TELEGRAFO_CARGA := 0.42
const VEL_MERGULHO := 460.0
## cuspidor: alcance horizontal, wind-up e recarga do cuspo.
const ALC_CUSPIR := 440.0
const TELEGRAFO_CUSPIR := 0.5
const VEL_CUSPO := 300.0
const PROJETIL_CUSPO := preload("res://scenes/actors/BolaFogo.tscn")
var _acao_cd := 0.0
var _windup := 0.0
var _carga := 0.0
var _mergulho := 0.0
var _t_hover := 0.0
## Telegrafo (pegada Dead Cells): pisca a AVISAR antes de qualquer investida.
var _telegrafo := 0.0
## Salto do "saltador" a decorrer -- enquanto > 0 a patrulha não pisa a vel.
var _saltando := 0.0
var _dive_dir := Vector2.ZERO
## Cor do rasto de partículas quando morre.
@export var cor_estilhacos := Color(0.7, 0.25, 0.45)
## Cor da luz de recorte (rim) do sprite -- normalmente o tom do bioma.
@export var cor_rim := Color(0.95, 0.5, 0.72)
## ELITE (1 por nível na campanha à mão): aura a pulsar + barra de vida por
## cima da cabeça + rebentamento maior na morte. Lê-se como "este é o grande".
@export var elite := false
## Que monstro pixel-art usar (pack CC0 LuizMelo "Monsters Creatures
## Fantasy"). Pastas em `assets/sprites/pixel/enemies/<especie>/`.
@export_enum("goblin", "mushroom", "esqueleto", "olho",
	"imp", "chort", "orc", "xamane", "demonio_grande", "ogro",
	"abobora", "wogol", "necromante", "lodo",
	"besouro", "raptor", "mastim", "gosma", "abutre") var especie := "goblin"

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
	# pack CC0 ansimuz "Enemies Pack" (tools/extrair_inimigos_pack.gd). O
	# `hit` é o idle (o pisca do dano é do shader) e o `dead` é gerado.
	"besouro":        {"idle": 4, "run": 4, "hit": 4, "dead": 4},
	"raptor":         {"idle": 4, "run": 7, "hit": 4, "dead": 4},
	"mastim":         {"idle": 6, "run": 4, "hit": 6, "dead": 4},
	"gosma":          {"idle": 8, "run": 7, "hit": 8, "dead": 4},
	"abutre":         {"idle": 4, "run": 4, "hit": 4, "dead": 4},
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

## --- Estados de dano ao longo do tempo (pegada Dead Cells) --------------
## QUEIMADURA: dano por tick e ALASTRA a inimigos próximos. SANGRAMENTO:
## dano por tick que ACELERA enquanto o inimigo se mexe. ATORDOAMENTO:
## paralisa como o gelo mas sem o tom azul. Qualquer um deixa o inimigo
## VULNERÁVEL -> os golpes da Koliani nele contam como CRÍTICOS.
const QUEIMA_INTERVALO := 0.5
const SANGRA_INTERVALO := 0.7
const SANGRA_INTERVALO_MOV := 0.34   # a mexer-se, sangra quase a dobrar
const ALASTRA_RAIO := 48.0
var _queimando := 0.0
var _queima_dano := 3
var _queima_cd := 0.0

## --- elite (aura + barra de vida) --------------------------------------
var _elite_vmax := 0
var _aura: Node2D
var _barra: Node2D
var _barra_fill: ColorRect
var _aura_t := 0.0
var _sangrando := 0.0
var _sangra_dano := 4
var _sangra_cd := 0.0
var _atordoado := 0.0


## Gela este inimigo por `segundos` (a badalada do Sino, nível 11). Idempotente
## no sentido de ficar sempre com o maior tempo pendente.
func congelar(segundos: float) -> void:
	if _morto:
		return
	_congelado = maxf(_congelado, segundos)
	if _corpo:
		_corpo.modulate = Color(0.7, 0.85, 1.2)


## Põe este inimigo a arder: `dano_tick` a cada `QUEIMA_INTERVALO`, durante
## `segundos`. A chama alastra a quem estiver a `ALASTRA_RAIO`.
func queimar(segundos: float, dano_tick := 3) -> void:
	if _morto:
		return
	_queimando = maxf(_queimando, segundos)
	_queima_dano = maxi(_queima_dano, dano_tick)


## Sangramento: `dano_tick` por tick, mais depressa enquanto ele anda.
func sangrar(segundos: float, dano_tick := 4) -> void:
	if _morto:
		return
	_sangrando = maxf(_sangrando, segundos)
	_sangra_dano = maxi(_sangra_dano, dano_tick)


## Atordoa: paralisa `segundos` (como o gelo, sem o tom azul).
func atordoar(segundos: float) -> void:
	if _morto:
		return
	_atordoado = maxf(_atordoado, segundos)


func esta_a_arder() -> bool:
	return _queimando > 0.0


## true se um golpe da Koliani neste inimigo deve contar como CRÍTICO
## (gelado / a arder / a sangrar / atordoado) -- a "janela" da pegada Dead Cells.
func esta_vulneravel() -> bool:
	return not _morto and (_congelado > 0.0 or _queimando > 0.0 \
		or _sangrando > 0.0 or _atordoado > 0.0)


## Dano que NÃO empurra nem re-telegrafa -- só corrói a vida (DoT).
func _dano_periodico(q: int) -> void:
	if _morto:
		return
	vida -= maxi(1, q)
	piscar_dano()
	if elite:
		_atualizar_barra_elite()
	if vida <= 0:
		if elite:
			_pop_morte_elite()
		if _anim:
			_morrer_anim()
		else:
			Impacto.rebentar(self, global_position + Vector2(0.0, -10.0),
				cor_rim.lerp(Color(1, 1, 1), 0.35), 3.0)
			soltar_estilhacos()
			queue_free()


## Corre os DoT (queimadura/sangramento) e gere o tom da pele conforme o
## estado dominante. Chamado no topo do `_physics_process`.
func _tick_status(dt: float) -> void:
	if _morto:
		return
	if _queimando > 0.0:
		_queimando -= dt
		_queima_cd -= dt
		if _queima_cd <= 0.0:
			_queima_cd = QUEIMA_INTERVALO
			Impacto.rebentar(self, global_position + Vector2(randf_range(-8.0, 8.0), -15.0),
				Color(1.0, 0.55, 0.18), 1.0)
			if _queimando > 0.35:
				for outro in get_tree().get_nodes_in_group("inimigos"):
					if outro == self or not is_instance_valid(outro):
						continue
					if outro.has_method("esta_a_arder") and not outro.esta_a_arder() \
							and outro.has_method("queimar") \
							and global_position.distance_to((outro as Node2D).global_position) <= ALASTRA_RAIO:
						outro.queimar(_queimando * 0.7, _queima_dano)
			_dano_periodico(_queima_dano)
			if _morto:
				return
	if _sangrando > 0.0:
		_sangrando -= dt
		_sangra_cd -= dt
		if _sangra_cd <= 0.0:
			_sangra_cd = SANGRA_INTERVALO_MOV if absf(velocity.x) > 12.0 else SANGRA_INTERVALO
			Impacto.rebentar(self, global_position + Vector2(0.0, -6.0), Color(0.82, 0.06, 0.14), 0.85)
			_dano_periodico(_sangra_dano)
			if _morto:
				return
	_atualizar_tom_estado()


var _tom_estado := ""

## Tom da pele conforme o estado dominante: gelo > queimadura > sangramento.
## Aplica no sprite desenhado (`_corpo`) ou no de pack (`_anim`), o que existir.
## Só escreve quando o estado MUDA -- não pisa o flash branco de `piscar_dano`.
func _atualizar_tom_estado() -> void:
	var e := ""
	if _congelado > 0.0:
		e = "gelo"
	elif _queimando > 0.0:
		e = "fogo"
	elif _sangrando > 0.0:
		e = "sangue"
	elif _atordoado > 0.0:
		e = "atordoado"
	if e == _tom_estado:
		return
	_tom_estado = e
	var alvo: CanvasItem = _corpo if _corpo != null else _anim
	if alvo == null:
		return
	match e:
		"gelo": alvo.modulate = Color(0.7, 0.85, 1.2)
		"fogo": alvo.modulate = Color(1.3, 0.72, 0.5)
		"sangue": alvo.modulate = Color(1.16, 0.82, 0.86)
		"atordoado": alvo.modulate = Color(1.25, 1.2, 0.7)
		_: alvo.modulate = Color(1, 1, 1)


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
	if comportamento == "escudeiro":
		velocidade *= 0.7  # o escudo pesa
	if comportamento == "trepador" and _sprite:
		_sprite.scale.y = -1.0  # de cabeça para baixo, colado ao tecto

	if _area_contacto:
		_area_contacto.body_entered.connect(_ao_tocar)
	if _corpo:
		_corpo_base = _corpo.position
		if _corpo.material is ShaderMaterial:
			_mat = _corpo.material
			_mat.set_shader_parameter("rim_cor", cor_rim)
	if _anim:
		_montar_frames()
		_normalizar_escala()   # todas as espécies ao mesmo tamanho no ecrã
		_anim.play("idle")
		_calibrar_pes()
	if elite:
		_montar_elite()


## Espécies que voam -- não se alinham os pés ao chão.
const ESPECIES_VOAM := ["olho", "abutre"]

## Altura-alvo (px) do CORPO opaco do inimigo no ecrã -- normaliza as
## espécies, que vêm de packs com densidades diferentes (LuizMelo 150px vs
## 0x72 16px). Sem isto um goblin era ~2x um chort. A Koliani mede ~40 px
## no ecra; os bichos comuns ficam um nada maiores (leem-se como ameaca).
const ALTURA_ALVO_INIMIGO := 48.0

## Mede o corpo opaco do frame idle e ajusta `_anim.scale` para ele render
## a ~`ALTURA_ALVO_INIMIGO` px -- todas as espécies ao mesmo tamanho.
func _normalizar_escala() -> void:
	if _anim == null or _anim.sprite_frames == null:
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
	if r.size.y <= 4:
		return
	var alvo := ALTURA_ALVO_INIMIGO * (0.86 if especie in ESPECIES_VOAM else 1.0)
	var k := clampf(alvo / float(r.size.y), 0.25, 2.2)
	_anim.scale = Vector2(k, k)

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
	if elite and not _morto:
		_pulsar_aura(dt)
	if _anim:
		_atualizar_anim()
		# telegrafo: pisca forte (branco-quente) enquanto vai atacar
		if _telegrafo > 0.0 and not _morto:
			var p := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.045)
			_anim.modulate = Color(1, 1, 1).lerp(Color(2.6, 1.6, 1.4), p)
			if _sprite:
				_sprite.rotation = sin(Time.get_ticks_msec() * 0.09) * 0.06
		elif not _morto and _congelado <= 0.0:
			_anim.modulate = _anim.modulate.lerp(Color(1, 1, 1), dt * 4.0)
			if _sprite and absf(_sprite.rotation) > 0.001:
				_sprite.rotation = lerp_angle(_sprite.rotation, 0.0, dt * 10.0)
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
	_tick_status(dt)
	if _morto:  # um DoT pode tê-lo morto
		return
	if _congelado > 0.0 or _atordoado > 0.0:
		_congelado = maxf(0.0, _congelado - dt)
		_atordoado = maxf(0.0, _atordoado - dt)
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVIDADE * dt
		move_and_slide()
		return
	_acao_cd = maxf(0.0, _acao_cd - dt)
	_telegrafo = maxf(0.0, _telegrafo - dt)

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
				# bateu na parede: CAMBALEIA -> janela de castigo (crítico)
				_carga = 0.0
				_acao_cd = randf_range(1.8, 3.0)
				atordoar(0.85)
				Som.toca("bloqueio", -10.0, 0.7)
			elif _carga <= 0.0:
				# investida falhou: recuo curto, ainda dá para rematar
				_acao_cd = randf_range(1.2, 2.0)
				atordoar(0.4)
			return
		var alvo_c := _dir_koliani_perto(320.0)
		if alvo_c != 0.0 and _acao_cd <= 0.0 and is_on_floor():
			_direcao = alvo_c
			if _sprite:
				_sprite.scale.x = _direcao
			_windup = TELEGRAFO_CARGA
			_telegrafo = TELEGRAFO_CARGA
			anticipacao = 1.0
			velocity.x = 0.0
			Som.toca("demonio_ataque", -14.0, 0.7)
			return
	elif comportamento == "saltador":
		if _saltando > 0.0:  # no ar -- deixa a gravidade fazer o arco
			_saltando -= dt
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if is_on_floor() and _saltando < 0.45:
				_saltando = 0.0
				atordoar(0.32)  # aterra desengonçado -> janela curta de castigo
			return
		if _windup > 0.0:  # agacha-se a avisar
			_windup -= dt
			velocity.x = 0.0
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if _windup <= 0.0:
				velocity = Vector2(_direcao * 175.0, -430.0)
				_saltando = 0.75
				Som.toca("demonio_ataque", -9.0, 1.0)
				move_and_slide()
			return
		if _acao_cd <= 0.0 and is_on_floor():
			var alvo_s := _dir_koliani_perto(230.0)
			if alvo_s != 0.0:
				_direcao = alvo_s
				if _sprite:
					_sprite.scale.x = _direcao
				_windup = 0.26
				_telegrafo = 0.26
				anticipacao = 1.0
				_acao_cd = randf_range(1.5, 2.6)
				return
	elif comportamento == "voador":
		# sem gravidade: paira à volta da origem e mergulha na Koliani
		if _mergulho > 0.0:  # em picada -- direção fixada no arranque
			_mergulho -= dt
			move_and_slide()
			if _mergulho <= 0.0 or is_on_wall() or is_on_floor():
				_mergulho = 0.0
				_acao_cd = randf_range(1.3, 2.3)
				atordoar(0.5)  # fim da picada -> paira tonto (janela de castigo)
			return
		if _windup > 0.0:  # trava no ar a avisar, depois mergulha
			_windup -= dt
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
			move_and_slide()
			if _windup <= 0.0:
				velocity = _dive_dir * VEL_MERGULHO
				_mergulho = 0.6
				Som.toca("demonio_ataque", -8.0, 1.1)
				move_and_slide()
			return
		var kv := get_tree().get_first_node_in_group("koliani")
		if kv and _acao_cd <= 0.0:
			var d: Vector2 = (kv as Node2D).global_position - global_position
			if d.length() < 300.0:
				_dive_dir = d.normalized()
				_windup = 0.3
				_telegrafo = 0.3
				anticipacao = 1.0
				if _sprite:
					_sprite.scale.x = signf(d.x) if d.x != 0.0 else _sprite.scale.x
				_acao_cd = randf_range(1.3, 2.3)
				return
		_t_hover += dt
		var pouso := _origem + Vector2(sin(_t_hover * 1.4) * 62.0, sin(_t_hover * 2.1) * 24.0)
		velocity = (pouso - global_position) * 3.0
		move_and_slide()
		return
	elif comportamento == "trepador":
		# agarrado ao tecto/parede acima; solta-se quando a Koliani passa por
		# baixo e depois comporta-se como patrulha (cai e anda)
		var kc := get_tree().get_first_node_in_group("koliani")
		if kc:
			var d: Vector2 = (kc as Node2D).global_position - global_position
			if absf(d.x) < 100.0 and d.y > 24.0:
				comportamento = "patrulha"
				if _sprite:
					_sprite.scale.y = 1.0
				velocity = Vector2(0.0, 240.0)
				anticipacao = 1.0
				Som.toca("demonio_ataque", -9.0, 0.9)
				move_and_slide()
				return
		velocity = Vector2.ZERO
		move_and_slide()
		return
	elif comportamento == "cuspidor":
		if _windup > 0.0:  # plantado a avisar, depois cospe
			_windup -= dt
			velocity.x = 0.0
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if _windup <= 0.0:
				var b := PROJETIL_CUSPO.instantiate()
				b.velocidade = _dive_dir * VEL_CUSPO
				b.dano = maxi(1, int(round(dano_contacto * 0.9)))
				get_parent().add_child(b)
				b.global_position = global_position + _dive_dir * 16.0
				Som.toca("projetil", -13.0, 0.9)
				_acao_cd = randf_range(1.8, 2.8)
				atordoar(0.35)  # recuo do cuspo -> janela curta de castigo
			return
		if _acao_cd <= 0.0 and is_on_floor():
			var kk := get_tree().get_first_node_in_group("koliani")
			if kk:
				var d: Vector2 = (kk as Node2D).global_position - global_position
				if absf(d.x) < ALC_CUSPIR and absf(d.y) < 170.0 and absf(d.x) > 60.0:
					_direcao = signf(d.x)
					if _sprite:
						_sprite.scale.x = _direcao
					# mira ligeiramente achatada (mais legível de desviar)
					_dive_dir = Vector2(d.x, d.y * 0.5).normalized()
					_windup = TELEGRAFO_CUSPIR
					_telegrafo = TELEGRAFO_CUSPIR
					anticipacao = 1.0
					velocity.x = 0.0
					Som.toca("demonio_ataque", -15.0, 0.7)
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


## Multiplicador de dano de um golpe CRÍTICO (inimigo vulnerável, golpe
## pelas costas ou logo a seguir a um rolamento -- ver `Koliani`).
const CRIT_MULT := 1.7

func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _morto:
		return
	# escudeiro: golpe de FRENTE (o empurrão atira-o para trás, contra o
	# sentido em que está virado) bate no escudo -- só "clinc". Pisão
	# (dir_empurrao 0) e golpes pelas costas passam. Um CRÍTICO (costas /
	# pós-rolamento / vulnerável) fura o escudo.
	if comportamento == "escudeiro" and not critico and dir_empurrao != 0.0 \
			and signf(dir_empurrao) == -_direcao:
		Som.toca("bloqueio", -12.0, randf_range(0.85, 0.95))
		_flinch = 0.4
		_flinch_dir = signf(dir_empurrao)
		anticipacao = 0.6
		return
	var q := quantidade
	if critico:
		q = int(round(q * CRIT_MULT))
		# gelo + crítico = ESTILHAÇA: bónus e limpa o congelamento
		if _congelado > 0.0:
			q += int(round(quantidade * 0.6))
			_congelado = 0.0
			_tom_estado = ""
		Impacto.rebentar(self, global_position + Vector2(0.0, -12.0), Color(1, 1, 1), 3.2)
	vida -= q
	global_position.x += dir_empurrao * (12.0 if critico else 8.0)
	if vida <= 0:
		if elite:
			_pop_morte_elite()
		if _anim:
			_morrer_anim()
		else:
			# mesmo "pop" da morte com animação, para o feedback ser igual
			Impacto.rebentar(self, global_position + Vector2(0.0, -10.0),
				cor_rim.lerp(Color(1, 1, 1), 0.35), 3.0)
			soltar_estilhacos()
			queue_free()
	else:
		if dir_empurrao != 0.0:
			_flinch_dir = signf(dir_empurrao)
		_flinch = 1.5 if critico else 1.0
		if critico:
			atordoar(0.18)  # micro-stun no crítico -> dá para encadear
		if _anim:
			_anim.play("hit")
		piscar_dano()
		if elite:
			_atualizar_barra_elite()


## Rebentamento GRANDE quando um elite cai (2 anéis da cor do rim + clarão).
func _pop_morte_elite() -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return
	var tinta: Color = cor_rim.lerp(Color(1, 1, 1), 0.4)
	for i in 2:
		Impacto.rebentar(cena, global_position + Vector2(randf_range(-18.0, 18.0), -14.0 - i * 8.0),
			tinta, 4.2 + i * 1.4)


## Toca a animação de morte e só então solta estilhaços e liberta-se.
func _morrer_anim() -> void:
	_morto = true
	velocity = Vector2.ZERO
	# "pop" de morte: o mesmo anel do acerto, maior e na cor do rim do bioma
	Impacto.rebentar(self, global_position + Vector2(0.0, -10.0),
		cor_rim.lerp(Color(1, 1, 1), 0.35), 3.4)
	if _area_contacto:
		_area_contacto.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	_anim.play("dead")
	await _anim.animation_finished
	soltar_estilhacos()
	queue_free()


## Monta o visual de ELITE: DECAL de chão a brilhar (à Dead Cells) + barra
## de vida fina por cima da cabeça (só aparece ao 1.º golpe) + rim aceso.
func _montar_elite() -> void:
	_elite_vmax = maxi(vida, 1)
	var alvo: Node2D = _sprite if _sprite else self
	var cor := cor_rim
	cor.a = 1.0
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	# altura real do bicho no ecrã (para dimensionar decal + barra)
	var alt_px := 44.0
	if _anim and _anim.sprite_frames and _anim.sprite_frames.has_animation("idle"):
		var tx := _anim.sprite_frames.get_frame_texture("idle", 0)
		if tx:
			var im := tx.get_image()
			if im:
				var rr := im.get_used_rect()
				if rr.size.y > 4:
					alt_px = float(rr.size.y) * _anim.scale.y

	# --- decal de chão: elipse achatada a brilhar sob os pés ---
	_aura = Node2D.new()
	_aura.name = "DecalElite"
	_aura.z_index = -1
	alvo.add_child(_aura)
	var raio := clampf(alt_px * 0.5, 18.0, 34.0)
	var elipse := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		elipse.append(Vector2(cos(a) * raio * 1.4, sin(a) * raio * 0.34))
	var disco := Polygon2D.new()
	disco.polygon = elipse
	disco.color = Color(cor.r, cor.g, cor.b, 0.22)
	disco.material = aditivo
	_aura.add_child(disco)
	var aro := Line2D.new()
	aro.points = elipse
	aro.closed = true
	aro.width = 2.0
	aro.default_color = Color(cor.r, cor.g, cor.b, 0.55)
	aro.material = aditivo
	_aura.add_child(aro)

	_barra = Node2D.new()
	_barra.name = "BarraElite"
	_barra.z_index = 20
	_barra.visible = false
	_barra.position = Vector2(0.0, -alt_px - 14.0)
	alvo.add_child(_barra)
	var bg := ColorRect.new()
	bg.size = Vector2(52.0, 6.0)
	bg.position = Vector2(-26.0, 0.0)
	bg.color = Color(0.05, 0.03, 0.06, 0.85)
	_barra.add_child(bg)
	_barra_fill = ColorRect.new()
	_barra_fill.size = Vector2(48.0, 4.0)
	_barra_fill.position = Vector2(-24.0, 1.0)
	_barra_fill.color = cor.lightened(0.15)
	_barra.add_child(_barra_fill)

	if _mat:
		_mat.set_shader_parameter("rim_cor", cor.lightened(0.25))


func _atualizar_barra_elite() -> void:
	if _barra == null or _barra_fill == null:
		return
	_barra.visible = true
	var f := clampf(float(vida) / float(maxi(_elite_vmax, 1)), 0.0, 1.0)
	_barra_fill.size.x = 48.0 * f
	_barra_fill.color = Color(1.0, 0.4, 0.35) if f < 0.35 else cor_rim.lightened(0.15)


func _pulsar_aura(dt: float) -> void:
	if _aura == null:
		return
	_aura_t += dt
	var p := 1.0 + 0.12 * sin(_aura_t * 5.0)
	_aura.scale = Vector2(p, p)
	_aura.modulate.a = 0.7 + 0.3 * (0.5 + 0.5 * sin(_aura_t * 5.0))


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
