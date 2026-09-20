class_name ChefeBase
extends DemonioBase
## Base dos chefes de mundo. Herda de `DemonioBase` (vida, dano por
## contacto, flash, estilhaços) e acrescenta o que todos os chefes
## partilham: o sinal `derrotado` (o nível usa-o para abrir a porta), a
## referência à Koliani e um telegrafo (pausa + brilho) antes dos ataques.
##
## Cada chefe concreto herda daqui e implementa o seu `_physics_process`
## com a sua máquina de estados. NÃO usar `DemonioBase` diretamente para
## chefes.

signal derrotado

## --- RIG ANIMADO (3 set 2026) ----------------------------------------
## Até aqui NENHUM chefe animava. O `tools/extrair_chefes_packs.gd` monta
## uma folha de quatro frames que são POSES -- normal / alternativa / a
## piscar / núcleo à mostra -- e o chefe salta entre elas. Ao lado de uma
## Koliani com 18 estados e de inimigos comuns já animados (o `_anim` do
## `DemonioBase`), os chefes liam-se como bonecos parados.
##
## Pôr aqui o nome de um rig de `assets/sprites/pixel/bosses_anim/rigs.json`
## (feito por `tools/importar_chefes_animados.py`) liga a animação a sério.
## Vazio = folha estática de sempre, portanto os chefes que ainda não têm
## rig não mudam absolutamente nada.
@export var rig := ""

const DIR_RIGS := "res://assets/sprites/pixel/bosses_anim"
## Nome do estado no pack -> nome que o `DemonioBase._atualizar_anim` usa.
const ESTADO_ANIM := {
	"idle": "idle", "walk": "run", "hurt": "hit", "death": "dead",
	"attack": "attack",
}
## Altura do corpo do chefe no ecrã, antes de `escala_visual` (~1.3), que
## o multiplica. Os bichos comuns vão a 48 e a Koliani mede ~40: a 82 o
## chefe saía com 1,4x a Koliani e no ecrã não se lia como chefe, lia-se
## como um inimigo grande. A 100 fica com ~2x.
const ALTURA_ALVO_CHEFE := 100.0

## Tecto de LARGURA do corpo do chefe no ecrã. Sem ele, um rig largo e
## baixo (o morcego de asas abertas do Vyrak, o baú-mímico do Sino Vivo, o
## verme do Naga) era esticado até 100 px de alto e passava a 160 de largo
## -- mais largo que a plataforma da arena. 110 é a largura do rig mais
## largo que já cá estava (o minotauro), portanto nenhum chefe antigo muda.
const LARGURA_ALVO_CHEFE := 110.0

static var _cache_rigs: Dictionary = {}

## Algumas cenas antigas guardavam a espécie do pack em `rig` (wogol, lodo,
## esqueleto...). Estes aliases encaminham-nas para uma folha de boss com os
## cinco estados completos, sem obrigar a reescrever dezenas de cenas.
const RIG_ALIASES := {
	"esqueleto": "rei_ossario", "wogol": "golem_pedra", "lodo": "demonio_lodo",
	"gosma": "demonio_lodo", "ogro": "colosso", "chort": "cavaleiro_fogo",
	"demonio_grande": "colosso",
}

## Escala visual do chefe (o `Sprite` inteiro, incluindo o `Nucleo`). Cada
## `Chefe*.tscn` põe a sua -- dá variedade de tamanho entre chefes e faz
## todos ficarem maiores que a Koliani. NÃO mexe na `AreaContacto`.
@export var escala_visual := 1.3

## O combate começou a sério (1.ª vez que `provocar()` corre). O HUD usa
## para mostrar a barra de vida do chefe.
signal combate_iniciado(chefe: ChefeBase)
## Vida do chefe mudou (após levar dano). `maximo` = vida no início da luta.
signal vida_mudou(atual: int, maximo: int)

## Vida no arranque da luta (capturada na 1.ª `provocar()`/dano, já depois
## de o chefe concreto ter definido a sua vida no `_ready`).
var _vida_maxima := 0

## Falas de história (só os chefes-narrativa preenchem, no seu `_ready`).
## Cada entrada: `{ "quem": <chave i18n>, "texto": <chave i18n> }`. A INTRO
## corre quando a Koliani entra na arena (antes do combate); a de FIM corre
## quando o chefe cai, antes de a porta abrir. Ver `Dialogo` / `Balao`.
var falas_intro: Array = []
var falas_fim: Array = []
## Distância (px) a que a Koliani dispara a intro.
var gatilho_intro := 330.0
var _intro_feita := false
var _fim_em_curso := false

var _koliani: Node2D
## Fica > 0 durante um golpe forte do chefe (o contacto magoa mais).
var _ataque_forte := 0.0
var _ja_derrotado := false
## true assim que o combate começa (troca a música para a do chefe). Fica
## false num chefe recém-instanciado (após morte/recarga), por isso a
## música só volta a mudar quando a luta recomeça de facto.
var _musica_boss := false

## MECÂNICA DE ESCUDOS RETIRADA (pedido do Paulo, 2 set 2026): os chefes
## deixaram de ter escudo de cargas E janela EXPOSTA -- levam dano SEMPRE,
## têm mais vida e batem mais forte (ver `_afinar_dificuldade`). Todo o
## código do escudo foi apagado; não repor.

## --- prisão à arena -------------------------------------------------
## O chefe nunca deve cair da plataforma principal (nem a andar, nem
## empurrado por um golpe, nem numa investida). Mede-se a plataforma por
## baixo do chefe no arranque e trava-se o X a essas bordas durante a luta.
@export var preso_a_arena := true
var _arena_ok := false
var _arena_esq := 0.0
var _arena_dir := 0.0
var _arena_topo := 0.0
## O tecto em Y só vale para chefes que ANDAM no chão -- um chefe voador
## nunca toca o chão e não deve ser puxado para baixo da superfície.
var _tocou_chao := false


## 9G: aura de corrupção do telégrafo (criada à primeira vez que é precisa).
var _aura9g: AnimatedSprite2D


func _e_chefe() -> bool:
	return true


func _altura_alvo() -> float:
	return ALTURA_ALVO_CHEFE


func _largura_alvo() -> float:
	return LARGURA_ALVO_CHEFE


## Catálogo dos rigs (`rigs.json`), lido uma vez por sessão.
static func _rigs() -> Dictionary:
	if _cache_rigs.is_empty():
		var cam := "%s/rigs.json" % DIR_RIGS
		if FileAccess.file_exists(cam):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(cam))
			if d is Dictionary:
				_cache_rigs = d
		if _cache_rigs.is_empty():
			_cache_rigs = {"_": {}}    # marca como "já tentei"
	return _cache_rigs


## Monta os `SpriteFrames` do rig no nó `Sprite/Anim` e esconde a folha
## estática. Sem `rig`, sem nó `Anim` ou sem entrada no catálogo, não toca
## em nada -- o chefe continua exactamente como estava.
func _montar_rig() -> void:
	if rig == "":
		return
	if not _rigs().has(rig) and RIG_ALIASES.has(rig):
		rig = RIG_ALIASES[rig]
	var anim := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if anim == null:
		push_warning("chefe com rig '%s' mas sem nó Sprite/Anim" % rig)
		return
	# Região I: arte de produção 9D do guardião, se já estiver integrada
	var prod := Inimigos9D.sprite_frames(self, rig)
	if prod:
		anim.sprite_frames = prod
		anim.visible = true
		var c9d := get_node_or_null("Sprite/Corpo") as Sprite2D
		if c9d:
			c9d.visible = false
			if c9d.material is ShaderMaterial:
				anim.material = (c9d.material as ShaderMaterial).duplicate()
		return
	var cfg: Variant = _rigs().get(rig, null)
	if not (cfg is Dictionary):
		push_warning("rig de chefe desconhecido: '%s'" % rig)
		return
	var estados: Dictionary = (cfg as Dictionary).get("estados", {})
	var fps: Dictionary = (cfg as Dictionary).get("fps", {})
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for estado: String in estados:
		var tex: Texture2D = load("%s/%s/%s.png" % [DIR_RIGS, rig, estado])
		if tex == null:
			continue
		var nome: String = ESTADO_ANIM.get(estado, estado)
		# idle/run em ciclo; ataque, dano e morte tocam uma vez
		_add_tira(sf, nome, tex, int(estados[estado]),
			float(fps.get(estado, 10.0)), nome in ["idle", "run"])
	# packs incompletos (o Minotauro grátis não traz dano nem morte): em vez
	# de deixar o chefe preso num frame, o estado em falta reusa o idle
	if sf.has_animation("idle"):
		for falta: String in ["run", "hit", "dead", "attack"]:
			if sf.has_animation(falta):
				continue
			sf.add_animation(falta)
			sf.set_animation_speed(falta, 8.0)
			sf.set_animation_loop(falta, true)
			for i in sf.get_frame_count("idle"):
				sf.add_frame(falta, sf.get_frame_texture("idle", i))
	anim.sprite_frames = sf
	anim.visible = true
	var corpo := get_node_or_null("Sprite/Corpo") as Sprite2D
	if corpo:
		corpo.visible = false
		# o rim/flash vivia no material da folha estática -- passa para o rig
		if corpo.material is ShaderMaterial:
			anim.material = (corpo.material as ShaderMaterial).duplicate()


## Toca a animação de ataque, se o rig a tiver. Os chefes com máquina de
## estados própria chamam isto no momento do golpe.
func atacar_anim() -> void:
	var anim := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("attack"):
		anim.play("attack")


func _ready() -> void:
	# ANTES do super: o `DemonioBase._ready` chama `_montar_frames`, que só
	# não faz nada se os `sprite_frames` já lá estiverem.
	_montar_rig()
	super._ready()
	# `DemonioBase._ready` aponta o `_mat` (flash de dano, cor do rim) ao
	# material da folha estática -- que o rig acabou de esconder. Sem isto
	# o chefe animado deixava de piscar ao levar dano.
	var _a := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if rig != "" and _a and _a.material is ShaderMaterial:
		_mat = _a.material
		_mat.set_shader_parameter("rim_cor", cor_rim)
	add_to_group("chefes")
	# A faixa do chefe só é pedida no primeiro golpe (`provocar` ->
	# `Musica.boss()`), e o `load()` acontecia nesse instante, na thread
	# principal: 2006 ms de jogo parado, medidos em `tools/bench_combate.gd`.
	# Pedida aqui, em segundo plano, chega pronta. (Os SFX ficam cobertos pelo
	# `Som.aquecer_tudo()` do arranque.)
	Musica.preparar_boss()
	# Sem escudos, os chefes levam dano o tempo todo -> batem MUITO mais
	# forte ao contacto (x1.4 no N1 -> x2.8 no N30). A vida-base sai de
	# cada chefe concreto; o multiplicador de vida entra em _afinar_dificuldade.
	dano_contacto = int(round(dano_contacto
		* (1.4 + 0.05 * float(clampi(EstadoJogo.indice_nivel, 0, 29)))
		* float(alivio_regiao_i()["dano"])))
	if _sprite:
		_sprite.scale = Vector2(_direcao * escala_visual, escala_visual)
	call_deferred("_encurtar_fase_exposto")
	call_deferred("_medir_arena")
	call_deferred("_afinar_dificuldade")


## Corre depois do `_ready` do chefe concreto (que define `vida`). Sem a
## janela EXPOSTA a Koliani acerta ~3x mais vezes -> a vida sobe muito para
## a luta não acabar num instante, e os telégrafos/recuperações encurtam.
## ALÍVIO DA REGIÃO I (Execution 9H). O Game Master jogou a Região I e disse
## que os cinco chefes estão demasiado difíceis -- "nem o do nível 1 está
## aceitável". A causa é conhecida e está escrita aqui em cima: quando os
## escudos saíram (maratona de 2 set), a vida subiu x3,2 e o dano de contacto
## x1,4 para a luta não acabar num instante. Isso serve um jogador que já
## conhece os padrões; não serve os cinco primeiros níveis do jogo, que são
## onde se aprende a lê-los.
##
## A correção é uma RAMPA dentro da região, e não um corte igual para todos:
## o 1-1 é a primeira luta do jogo e o 1-5 é o clímax regional. Mexe em
## quatro coisas ao mesmo tempo, porque baixar só a vida faz lutas longas e
## igualmente injustas:
##
##   vida      quanto aguenta          0,52 no 1-1  ->  0,86 no 1-5
##   dano      quanto tira             0,58         ->  0,88
##   tel       quanto TELEGRAFA        1,25 (mais)  ->  1,02
##   exposto   quanto fica a jeito     1,55 (mais)  ->  1,06
##   recupera  quanto demora a voltar  1,15 (mais)  ->  1,00
##
## Fora da Região I nada muda (fator 1,0): o resto da campanha não foi
## jogado nem afinado nesta execução.
const ALIVIO_R1 := [
	{"vida": 0.52, "dano": 0.58, "tel": 1.25, "exposto": 1.55, "recupera": 1.15},
	{"vida": 0.60, "dano": 0.65, "tel": 1.20, "exposto": 1.42, "recupera": 1.11},
	{"vida": 0.68, "dano": 0.72, "tel": 1.14, "exposto": 1.30, "recupera": 1.08},
	{"vida": 0.77, "dano": 0.80, "tel": 1.08, "exposto": 1.18, "recupera": 1.04},
	{"vida": 0.86, "dano": 0.88, "tel": 1.02, "exposto": 1.06, "recupera": 1.00},
]
const SEM_ALIVIO := {"vida": 1.0, "dano": 1.0, "tel": 1.0, "exposto": 1.0, "recupera": 1.0}


## Fatores de alívio do nível em curso (1,0 fora da Região I).
static func alivio_regiao_i(indice := -1) -> Dictionary:
	var i := EstadoJogo.indice_nivel if indice < 0 else indice
	if i < 0 or i >= ALIVIO_R1.size():
		return SEM_ALIVIO
	return ALIVIO_R1[i]


func _afinar_dificuldade() -> void:
	if _ja_derrotado:
		return
	var idx := float(clampi(EstadoJogo.indice_nivel, 0, 29))
	var al := alivio_regiao_i()
	# a Koliani acerta ~3x mais sem a janela EXPOSTA -> vida bem para cima
	var mult_vida := 3.2 + 1.6 * (idx / 29.0)   # N1 x3.2 -> N30 x4.8
	vida = int(round(vida * mult_vida * float(al["vida"])))
	# os danos POR ATAQUE de cada chefe (`dano_onda`, `dano_galho`, ...)
	# descem com o mesmo fator: sem isto, baixar a vida só fazia a luta mais
	# curta -- continuava a matar em três golpes.
	if float(al["dano"]) < 1.0:
		for prop in get_property_list():
			var nome: String = prop["name"]
			if not nome.begins_with("dano_") or nome == "dano_contacto":
				continue
			if not (prop["type"] in [TYPE_INT, TYPE_FLOAT]):
				continue
			var v: float = float(get(nome))
			if v > 0.0:
				set(nome, int(round(v * float(al["dano"])))
					if prop["type"] == TYPE_INT else v * float(al["dano"]))
	_vida_maxima = maxi(vida, 1)
	# vários chefes usam `_vida_max` para os limiares de fase -- acompanha
	if "_vida_max" in self:
		set("_vida_max", vida)
	vida_mudou.emit(vida, _vida_maxima)
	# telégrafos mais curtos, mas com CHÃO de 0.3s -- têm de continuar a
	# dar para ler. As recuperações podem descer mais.
	for nome in ["dur_tel", "dur_telegrafo"]:
		if nome in self:
			var v: float = get(nome)
			if v > 0.05:
				set(nome, maxf(v * 0.85 * float(al["tel"]), 0.3))
	for nome in ["dur_recupera", "dur_baque"]:
		if nome in self:
			var v: float = get(nome)
			if v > 0.05:
				set(nome, v * 0.8 * float(al["recupera"]))


var _arena_tentativas := 0

## Raio para baixo a partir da origem do chefe: acha a plataforma de chão e
## guarda as bordas esquerda/direita (menos uma margem) e o topo. É
## re-tentado em `_process` enquanto falhar (as colisões podem ainda não
## estar no espaço físico no 1.º frame). Sem plataforma com `tamanho`
## (chão de tiles), cai num limite à volta da origem -- melhor do que nada.
func _medir_arena() -> void:
	if not preso_a_arena or _arena_ok:
		return
	_arena_tentativas += 1
	var mundo := get_world_2d()
	if mundo == null:
		return
	var margem: float = 34.0 * maxf(0.8, escala_visual)
	var de := _origem + Vector2(0.0, -40.0)
	# só a camada 1 (chão/plataformas) -- evita medir a Koliani ou triggers
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 1400.0), 1)
	q.exclude = [self]
	q.collide_with_areas = false
	var hit := mundo.direct_space_state.intersect_ray(q)
	var chao: Node2D = hit.get("collider") as Node2D if not hit.is_empty() else null
	if chao != null and ("tamanho" in chao):
		var meia: float = (chao.tamanho.x as float) * 0.5
		_arena_esq = chao.global_position.x - meia + margem
		_arena_dir = chao.global_position.x + meia - margem
		_arena_topo = (hit["position"].y as float)
		_arena_ok = _arena_dir > _arena_esq
		return
	if not hit.is_empty():
		# há chão mas sem `tamanho` (tiles): limite largo à volta da origem
		_arena_esq = _origem.x - 460.0
		_arena_dir = _origem.x + 460.0
		_arena_topo = (hit["position"].y as float)
		_arena_ok = true
		return
	# ainda sem chão -- desiste ao fim de umas tentativas: prende só o X à
	# volta da origem, sem tecto em Y (pode ser um chefe que voa livremente).
	if _arena_tentativas >= 20:
		_arena_esq = _origem.x - 480.0
		_arena_dir = _origem.x + 480.0
		_arena_topo = INF
		_arena_ok = true


## Trava o chefe dentro das bordas da arena. Chamado todo o frame.
## X: nunca passa das pontas da plataforma. Y: nunca desce abaixo da
## superfície (bloqueia o "chefe por baixo da plataforma"). Os chefes
## voadores pairam ACIMA da superfície, por isso o tecto em Y não lhes
## toca.
func _prender_na_arena() -> void:
	if not _arena_ok or _ja_derrotado:
		return
	if global_position.x < _arena_esq:
		global_position.x = _arena_esq
		if velocity.x < 0.0:
			velocity.x = 0.0
	elif global_position.x > _arena_dir:
		global_position.x = _arena_dir
		if velocity.x > 0.0:
			velocity.x = 0.0
	if _tocou_chao and _arena_topo != INF and global_position.y > _arena_topo + 6.0:
		global_position.y = _arena_topo + 6.0
		if velocity.y > 0.0:
			velocity.y = 0.0


## Feito em deferred: o `_ready` do chefe concreto já correu. Sem a janela
## EXPOSTA (escudos retirados), a fase EXPOSTO das máquinas de estado é só
## um respiro entre ataques -- encurta-se para o chefe não ficar parado
## sem fazer nada.
func _encurtar_fase_exposto() -> void:
	var al := alivio_regiao_i()
	for nome in ["dur_exposto", "dur_exposta"]:
		if nome in self:
			var v: float = get(nome)
			if v > 0.0:
				set(nome, maxf(v * 0.55 * float(al["exposto"]), 0.35))



func _process(dt: float) -> void:
	super._process(dt)
	if is_on_floor():
		_tocou_chao = true
	if not _arena_ok:
		_medir_arena()
	_prender_na_arena()
	# rede de segurança: se mesmo assim o chefe acabar fora do mapa (fosso
	# sem plataforma medida, etc.), conta como derrotado -- senão o nível
	# fica bloqueado porque a porta nunca abre.
	if not _ja_derrotado and global_position.y - _origem.y > 520.0:
		_cair_derrotado()
		return
	# intro de história: a Koliani chegou perto -> corre as falas antes da luta
	if not _intro_feita and not _ja_derrotado and not falas_intro.is_empty():
		var k := _obter_koliani()
		if k and global_position.distance_to(k.global_position) < gatilho_intro:
			_intro_feita = true
			_correr_intro()


func _correr_intro() -> void:
	await Dialogo.correr(_com_alvo(falas_intro))
	provocar()  # a música de chefe entra ao acabar a conversa


## Copia as falas metendo `self` como alvo da cauda do balão.
func _com_alvo(falas: Array) -> Array:
	var saida: Array = []
	for f: Dictionary in falas:
		var g := (f as Dictionary).duplicate()
		g["alvo"] = self
		saida.append(g)
	return saida


## Marca o início do combate: troca para a música de chefe. Idempotente --
## cada chefe concreto chama isto quando a sua máquina de estados sai da
## patrulha (deteta a Koliani); `chefe_base` também chama ao trocar o
## primeiro golpe. Não basta ver o chefe: é preciso "começar a fight".
func provocar() -> void:
	if _musica_boss or _ja_derrotado:
		return
	_musica_boss = true
	_garantir_vida_maxima()
	Musica.boss()
	combate_iniciado.emit(self)
	vida_mudou.emit(vida, _vida_maxima)


## Regista a vida-cheia da luta (uma vez). Chamado quando o combate começa
## ou ao 1.º dano -- nessa altura o `_ready` do chefe concreto já correu.
func _garantir_vida_maxima() -> void:
	if _vida_maxima <= 0:
		_vida_maxima = maxi(vida, 1)


## Volta à cama de fundo normal do nível (a de chefe entrou em `provocar`).
func _restaurar_musica() -> void:
	if _musica_boss:
		_musica_boss = false
		Musica.ambiente(EstadoJogo.indice_nivel)


## Grande recompensa de ESSÊNCIA ao cair o chefe (~70..150, escala com o
## nível). Espalha 6-9 motes.
func _soltar_essencia_chefe(cena: Node) -> void:
	var reg := float(clampi(EstadoJogo.indice_nivel, 0, 29)) / 29.0
	var total := 70 + int(reg * 90.0)
	var n := 7 + (EstadoJogo.indice_nivel % 3)
	for i in n:
		var m := ESSENCIA.instantiate()
		m.valor = maxi(1, total / n + (1 if i < total % n else 0))
		m.global_position = global_position + Vector2(randf_range(-40.0, 40.0), -30.0)
		# A morte pode vir de body_entered da espada: inserir a Area2D com
		# formas físicas durante o flush falha, mesmo com monitoring adiado.
		cena.add_child.call_deferred(m)


func _cair_derrotado() -> void:
	_ja_derrotado = true
	_restaurar_musica()
	_tocar_som_derrota()
	derrotado.emit()
	_explodir_derrotado()
	soltar_estilhacos()
	queue_free()


## Rebentamento GRANDE quando o chefe cai: 3 anéis pixel-art escalonados da
## cor do chefe + um clarão aditivo + tremor de câmara. O `soltar_estilhacos`
## (herdado do DemonioBase) só larga a poeira -- é o mesmo de um goblin, e um
## chefe merece mais. Tudo instanciado na cena (o chefe faz `queue_free` a
## seguir), sem referências a `self`.
func _explodir_derrotado() -> void:
	var cena := get_tree().current_scene
	if cena == null or not cena.is_inside_tree():
		return
	_soltar_essencia_chefe(cena)
	var base := global_position + Vector2(0.0, -30.0 * maxf(0.8, escala_visual))
	var tinta: Color = cor_rim.lerp(Color(1, 1, 1), 0.4)
	# 9G: a queda de um chefe na Região I é a corrupção a rebentar e a
	# dissolver-se -- sem o disco de polígono que havia por baixo.
	if Vfx9G.ativo(self):
		var esc9g := clampf(_altura_alvo() / 55.0, 1.0, 3.0)
		Vfx9G.tocar(cena, "finisher_burst_corrupcao", base, esc9g, 0.0, false, false, 45, 0.45)
		Vfx9G.tocar(cena, "death_dissolve_corrupcao", base, esc9g * 1.2, 0.0, false, false, 44, 1.1)
		for i in 2:
			var pos9g := base + Vector2(randf_range(-30.0, 30.0), randf_range(-24.0, 16.0))
			var esc_i := esc9g * 0.8
			get_tree().create_timer(0.12 + i * 0.12).timeout.connect(
				func() -> void:
					if is_instance_valid(cena) and cena.is_inside_tree():
						Vfx9G.tocar(cena, "finisher_burst_corrupcao", pos9g, esc_i,
							0.0, false, false, 45, 0.4))
		var cam9g := get_viewport().get_camera_2d()
		if cam9g and cam9g.has_method("bater"):
			cam9g.bater(9.0)
		return
	for i in 3:
		var desloc := Vector2(randf_range(-26.0, 26.0), randf_range(-22.0, 14.0))
		var esc := 3.6 + i * 1.2
		if i == 0:
			Impacto.rebentar(cena, base, tinta, esc)
		else:
			var pos := base + desloc
			get_tree().create_timer(i * 0.09).timeout.connect(
				func() -> void:
					if is_instance_valid(cena) and cena.is_inside_tree():
						Impacto.rebentar(cena, pos, tinta, esc))
	# clarão: disco aditivo que incha e some
	var flash := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 16:
		var a := TAU * float(k) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 60.0)
	flash.polygon = pts
	flash.color = cor_rim.lerp(Color(1, 1, 1), 0.7)
	flash.color.a = 0.9
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flash.material = mat
	flash.global_position = base
	flash.z_index = 45
	flash.scale = Vector2(0.3, 0.3)
	cena.add_child(flash)
	var t := flash.create_tween()
	t.set_parallel(true)
	t.tween_property(flash, "scale", Vector2(3.4, 3.4), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(flash, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(flash.queue_free)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(9.0)


func _obter_koliani() -> Node2D:
	if not is_instance_valid(_koliani):
		_koliani = get_tree().get_first_node_in_group("koliani")
	return _koliani


func _vetor_para_koliani() -> Vector2:
	var k := _obter_koliani()
	return (k.global_position - global_position) if k else Vector2.ZERO


func _dir_para_koliani() -> float:
	var dx := _vetor_para_koliani().x
	return signf(dx) if absf(dx) > 1.0 else _direcao


## Vira o sprite para a Koliani.
func _encarar_koliani() -> void:
	_direcao = _dir_para_koliani()
	if _sprite:
		_sprite.scale = Vector2(_direcao * escala_visual, escala_visual)


## 9G: aura de corrupção do telégrafo. Fica ATRÁS do corpo e aos pés: o aviso
## lê-se mais cedo sem tapar a silhueta nem o ponto fraco. O tom do corpo
## continua a ser o telégrafo principal -- isto só o reforça. Criada à
## primeira vez que é precisa e depois só ligada/desligada (o telégrafo chama
## isto a cada frame).
## Execution 9H.9 -- o clipe de cada fase, pelo NOME da fase.
##
## O Game Master disse que os chefes pareciam sprites fixos, e pareciam: a
## escolha automática do `DemonioBase` só olha para a velocidade, portanto um
## guardião a perseguir ficava em `run` a luta inteira -- telégrafo, golpe e
## recuperação passavam todos sem pose nenhuma. Os frames existem desde a
## 9H.1 (8 idle, 8 run, 7 attack, 3 hit por criatura); faltava quem os pedisse.
##
## Todos os chefes seguem a mesma convenção no seu enum `Fase` (`*_TEL` para
## o telégrafo, `EXPOSTO`/`EXPOSTA` para a janela de castigo, `DORME`/`DECIDE`
## à espera) -- a mesma convenção de que o `_encurtar_fase_exposto` já vive.
var _nomes_fase: Dictionary = {}


func _nome_fase() -> String:
	if _nomes_fase.is_empty():
		var mapa: Variant = get_script().get_script_constant_map().get("Fase", null)
		if not (mapa is Dictionary):
			return ""
		for nome: String in (mapa as Dictionary):
			_nomes_fase[int((mapa as Dictionary)[nome])] = nome
	var f: Variant = get("_fase")
	if f == null:
		return ""
	return String(_nomes_fase.get(int(f), ""))


func _anim_desejada() -> String:
	var n := _nome_fase()
	if n == "":
		return ""
	if n.contains("TEL"):
		return "attack"          # antecipação
	if n.contains("EXPOST"):
		return "hit"             # recuperação / castigo
	if n in ["DORME", "DECIDE"]:
		return ""
	# Fase de acção: se está praticamente quieta, é um golpe ou um conjuro --
	# a pose de ataque. Se está a deslocar-se, a locomoção manda.
	if absf(velocity.x) <= 20.0:
		return "attack"
	return ""


func _aura_telegrafo(ligado: bool) -> void:
	if _aura9g == null:
		if not ligado or not Vfx9G.ativo(self):
			return
		_aura9g = Vfx9G.novo("charge_aura_corrupcao", true)
		if _aura9g == null:
			return
		_aura9g.z_index = -2
		_aura9g.scale = Vector2.ONE * clampf(_altura_alvo() / 70.0, 0.8, 2.4)
		_aura9g.position = Vector2(0.0, _altura_alvo() * 0.1)
		_aura9g.modulate.a = 0.75
		add_child(_aura9g)
		_aura9g.play("ciclo")
	_aura9g.visible = ligado


func _piscar(ligado: bool) -> void:
	_aura_telegrafo(ligado)
	if _sprite:
		_sprite.modulate = Color(1.7, 1.25, 1.5) if ligado else Color(1, 1, 1)
	if ligado:
		anticipacao = 1.0  # wind-up visual (ver DemonioBase._process)


func _ao_tocar(corpo: Node) -> void:
	if corpo is Koliani:
		provocar()  # trocar o primeiro golpe = combate a sério
		var dano := int(round(dano_contacto * (1.8 if _ataque_forte > 0.0 else 1.0)))
		corpo.receber_dano(dano, signf(corpo.global_position.x - global_position.x))


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false,
		_forca_recuo := 0.0) -> void:
	if _ja_derrotado:
		return
	_garantir_vida_maxima()
	provocar()  # levou o primeiro golpe = combate a sério
	var q := quantidade
	if critico:
		# golpe critico no chefe (pos-rolamento / pelas costas / vulneravel)
		q = int(round(q * (1.5 + EstadoJogo.bonus("crit_mult"))))  # melhoria "furia"
		Impacto.rebentar(self, global_position + Vector2(0.0, -20.0 * maxf(0.8, escala_visual)), Color(1, 1, 1), 3.4)
	vida -= q
	global_position.x += dir_empurrao * (4.0 if critico else 3.0)
	vida_mudou.emit(maxi(vida, 0), _vida_maxima)
	if vida <= 0:
		_ja_derrotado = true
		_restaurar_musica()
		if not falas_fim.is_empty():
			_cair_com_falas()
		else:
			_tocar_som_derrota()
			derrotado.emit()
			_explodir_derrotado()
			soltar_estilhacos()
			queue_free()
	else:
		var anim := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("hit"):
			anim.play("hit")
		piscar_dano()


## Separa o peso da queda da recompensa. Antes os dois samples arrancavam no
## mesmo frame e os graves/transientes mascaravam-se. O timer vive na arvore,
## portanto a conquista toca mesmo depois de o chefe fazer `queue_free()`.
func _tocar_som_derrota() -> void:
	Som.toca("chefe_cai", -6.0)
	get_tree().create_timer(0.45, true, false, true).timeout.connect(
		func() -> void: Som.toca("conquista", -6.0))


## Morte dos chefes-história: congela o chefe, diz as últimas falas e só
## depois abre a porta.
func _cair_com_falas() -> void:
	if _fim_em_curso:
		return
	_fim_em_curso = true
	set_physics_process(false)
	Som.toca("chefe_cai", -6.0)
	await Dialogo.correr(_com_alvo(falas_fim))
	Som.toca("conquista", -4.0)
	derrotado.emit()
	_explodir_derrotado()
	soltar_estilhacos()
	queue_free()
