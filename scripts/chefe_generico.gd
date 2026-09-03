class_name ChefeGenerico
extends ChefeBase
## Chefe configurado pela CENA, não por um script próprio.
##
## Os 30 chefes dos níveis 1-30 têm um script cada -- cerca de 370 linhas
## por chefe, 11 mil ao todo. Para os 70 chefes dos níveis 31-100
## (`docs/plano_niveis_31_100.md`) isso não escala, e escrever mais 26 mil
## linhas de máquinas de estados quase iguais só faria o jogo mais difícil
## de afinar. Aqui a máquina de estados é UMA, e o que muda de chefe para
## chefe é o **arquétipo** e os números, postos no `.tscn`.
##
## O ciclo é sempre o mesmo -- é o que dá a leitura de "telégrafo, castigo,
## janela" que o combate dos níveis 1-30 já tem:
##
##   APROXIMA -> TELEGRAFO -> ACAO -> RECUPERA -> APROXIMA
##
## `APROXIMA` posiciona conforme o arquétipo (chegar perto ou fugir para
## longe), `TELEGRAFO` pisca e pára (é a leitura), `ACAO` executa e
## `RECUPERA` é a janela em que se castiga. Só `_aproximar()` e `_agir()`
## olham para o arquétipo.
##
## Um chefe novo passa a ser: uma cena com este script, os `@export`
## preenchidos, e uma linha na tabela da campanha.
##
## NÃO usar para os chefes-história com mecânica própria (Zeriko, a Koliani
## Sombria, o Olho do Abismo) -- esses continuam a merecer script próprio.

## O que este chefe faz quando ataca. Cobre os cinco padrões que os 30
## chefes escritos à mão usam entre si.
enum Arquetipo {
	INVESTIDA,   ## arranca a direito pelo chão (Ghorak, Vyrak)
	ATIRADOR,    ## mantém distância e manda salvas (Coração Putrefacto)
	SALTADOR,    ## salta e cai com onda de choque rasteira (Carcereiro)
	INVOCADOR,   ## larga lacaios e reposiciona-se (Bispo Púrpura)
	FEIXE,       ## feixe telegrafado que varre à frente (Cristalith)
}

enum Fase { APROXIMA, TELEGRAFO, ACAO, RECUPERA }

const TIRO := preload("res://scenes/actors/ProjetilZeriko.tscn")
const LACAIO := preload("res://scenes/actors/DemonioBase.tscn")

@export var arquetipo: Arquetipo = Arquetipo.INVESTIDA

## Arte do chefe. Posta pela CENA e aplicada aqui, para que os 70 chefes
## novos possam partilhar um único `ChefeGenerico.tscn` em vez de cada um
## precisar da sua cena com a sua textura ligada à mão.
##
## Enquanto não houver arte própria para as 14 regiões novas
## (`docs/plano_niveis_31_100.md`), isto aponta aos sprites dos 29 chefes
## dos níveis 1-30, recolorados por `cor_rim`/`modulate` da cena. É um
## substituto assumido, não o destino.
@export var textura: Texture2D

## --- ritmo (igual para todos os arquétipos) --------------------------
## A distância a que o chefe deixa de se aproximar. Nos arquétipos de
## longe (ATIRADOR, INVOCADOR) é também a distância a que RECUA.
@export var dist_ideal := 160.0
@export var vel_aproxima := 90.0
## Quanto tempo pisca antes de agir. Curto = agressivo, longo = legível.
@export var dur_telegrafo := 0.42
@export var dur_acao := 0.5
## A janela de castigo. É aqui que se bate no chefe.
@export var dur_recupera := 0.6

## --- segunda fase ----------------------------------------------------
## Fracção da vida a partir da qual o chefe acelera (0 = nunca).
@export var fase2_em := 0.5
## Por quanto se multiplica a velocidade e se divide a duração das pausas.
@export var fase2_ganho := 1.3

## --- INVESTIDA -------------------------------------------------------
@export var vel_investida := 460.0
## Quantas investidas seguidas antes de recuperar (>1 = combo).
@export var investidas_seguidas := 1

## --- ATIRADOR --------------------------------------------------------
@export var tiros_por_salva := 3
## Abertura total do leque, em graus. 0 = tiro único a direito.
@export var leque_graus := 26.0
## Em vez de mirar na Koliani, dispara um círculo completo.
@export var salva_radial := false
@export var dano_tiro := 14
@export var vel_tiro := 260.0

## --- SALTADOR --------------------------------------------------------
@export var forca_salto := 430.0
@export var raio_onda := 300.0
@export var dano_onda := 26

## --- INVOCADOR -------------------------------------------------------
@export var lacaios_por_vez := 2
## Espécie dos lacaios (ver `DemonioBase.ESPECIES`).
@export var lacaio_especie := "goblin"
## Teto de lacaios vivos ao mesmo tempo -- sem isto o ecrã enche.
@export var lacaios_max := 6

## --- FEIXE -----------------------------------------------------------
@export var feixe_alcance := 640.0
@export var feixe_dano := 22
@export var feixe_cor := Color(0.85, 0.4, 1.0)

var _fase: Fase = Fase.APROXIMA
var _t := 0.0
var _agiu := false
var _investidas := 0
var _onda_feita := false
var _dir_investida := 1.0
var _lacaios: Array[Node] = []


func _ready() -> void:
	super._ready()
	# a vida vem do `.tscn` (`vida`); aqui só se garante um mínimo para o
	# chefe não morrer num combo antes de chegar a mostrar o padrão
	vida = maxi(vida, 320)
	if textura:
		var corpo := get_node_or_null("Sprite/Corpo") as Sprite2D
		if corpo:
			corpo.texture = textura


## Multiplicador de ritmo: 1.0 na primeira fase, `fase2_ganho` depois de a
## vida cair abaixo de `fase2_em`.
func _ganho() -> float:
	if fase2_em <= 0.0 or _vida_maxima <= 0:
		return 1.0
	return fase2_ganho if float(vida) / float(_vida_maxima) <= fase2_em else 1.0


func _physics_process(dt: float) -> void:
	var g := _ganho()
	match _fase:
		Fase.APROXIMA:
			_aproximar(dt, g)
			if _t >= 0.45 / g and _pronto_para_agir():
				_ir_para(Fase.TELEGRAFO)
		Fase.TELEGRAFO:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
			_encarar_koliani()
			_cair(dt)
			move_and_slide()
			_piscar(true)
			if _t >= dur_telegrafo / g:
				_piscar(false)
				_dir_investida = _dir_para_koliani()
				_ir_para(Fase.ACAO)
		Fase.ACAO:
			if not _agiu:
				_agiu = true
				_agir()
			_durante_acao(dt, g)
			if _t >= dur_acao / g:
				# INVESTIDA encadeia; os outros passam à janela de castigo
				if arquetipo == Arquetipo.INVESTIDA \
						and _investidas < investidas_seguidas - 1:
					_investidas += 1
					_ir_para(Fase.TELEGRAFO)
				else:
					_investidas = 0
					_ir_para(Fase.RECUPERA)
		Fase.RECUPERA:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * dt)
			_cair(dt)
			move_and_slide()
			if _t >= dur_recupera / g:
				_ir_para(Fase.APROXIMA)
	_t += dt


func _ir_para(f: Fase) -> void:
	_fase = f
	_t = 0.0
	_agiu = false
	_onda_feita = false


func _cair(dt: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt


## Já está na posição de onde este arquétipo ataca?
func _pronto_para_agir() -> bool:
	var d := absf(_vetor_para_koliani().x)
	match arquetipo:
		Arquetipo.ATIRADOR, Arquetipo.INVOCADOR, Arquetipo.FEIXE:
			return d >= dist_ideal * 0.7      # de longe basta ter espaço
		_:
			return d <= dist_ideal


## Posicionamento. Os de corpo-a-corpo aproximam-se; os de longe fogem
## quando a Koliani lhes chega ao pé -- é o que os obriga a ser lidos de
## maneira diferente e não todos como "o bicho que vem a mim".
func _aproximar(dt: float, g: float) -> void:
	_encarar_koliani()
	var dx := _vetor_para_koliani().x
	var longe := arquetipo in [Arquetipo.ATIRADOR, Arquetipo.INVOCADOR,
			Arquetipo.FEIXE]
	var quer := 0.0
	if longe and absf(dx) < dist_ideal * 0.7:
		quer = -signf(dx)                     # recua
	elif not longe and absf(dx) > dist_ideal:
		quer = signf(dx)                      # avança
	# nunca sair da plataforma a andar (a prisão à arena do ChefeBase
	# trava, mas cair a meio de uma investida fica feio)
	if quer != 0.0 and ha_chao_a_frente(quer):
		velocity.x = quer * vel_aproxima * g
	else:
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * dt)
	_cair(dt)
	move_and_slide()


## O que continua a acontecer enquanto a acção dura (a INVESTIDA é a única
## que precisa de manter velocidade; as outras ficam paradas a executar).
func _durante_acao(dt: float, g: float) -> void:
	match arquetipo:
		Arquetipo.INVESTIDA:
			velocity.x = _dir_investida * vel_investida * g
			# trava na borda em vez de se atirar ao vazio
			if not ha_chao_a_frente(_dir_investida):
				velocity.x = 0.0
		Arquetipo.SALTADOR:
			# no ar segue a Koliani devagar, para o baque cair onde ela está
			velocity.x = move_toward(velocity.x,
					_dir_para_koliani() * vel_aproxima * 1.6, 900.0 * dt)
		_:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
	_cair(dt)
	move_and_slide()
	# a onda sai ao ATERRAR, não ao saltar: é o baque que magoa
	if arquetipo == Arquetipo.SALTADOR and not _onda_feita 			and is_on_floor() and _t > 0.12:
		_onda_feita = true
		_onda_de_choque()


func _agir() -> void:
	atacar_anim()          # se o chefe tiver rig, é agora que ele golpeia
	match arquetipo:
		Arquetipo.INVESTIDA:
			_ataque_forte = 0.45          # o contacto magoa mais na investida
			Som.toca("investida", -6.0)
		Arquetipo.ATIRADOR:
			_salva()
		Arquetipo.SALTADOR:
			velocity.y = -forca_salto
		Arquetipo.INVOCADOR:
			_invocar()
		Arquetipo.FEIXE:
			_feixe()


# --- ATIRADOR ---------------------------------------------------------

func _salva() -> void:
	Som.toca("chefe_magia", -8.0, 0.9)
	var n: int = maxi(1, tiros_por_salva)
	if salva_radial:
		for i in n:
			_tiro(Vector2.RIGHT.rotated(TAU * float(i) / float(n)))
		return
	var k := _obter_koliani()
	var base := (k.global_position - global_position).normalized() if k \
			else Vector2(_dir_para_koliani(), 0.0)
	for i in n:
		# leque centrado na direcção da Koliani
		var ang := deg_to_rad((float(i) - float(n - 1) * 0.5)
				* (leque_graus / maxf(1.0, float(n - 1))))
		_tiro(base.rotated(ang))


func _tiro(dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var t := TIRO.instantiate()
	t.dano = dano_tiro
	t.velocidade = vel_tiro
	pai.add_child(t)
	t.global_position = global_position + dir * 36.0
	t.lancar(dir)


# --- SALTADOR ---------------------------------------------------------
## A onda só apanha quem está NO CHÃO: saltar é a resposta, e é isso que
## a torna um ataque com solução em vez de dano garantido.
func _onda_de_choque() -> void:
	Som.toca("esmagar", -6.0)
	var k := _obter_koliani()
	if k and absf((k.global_position - global_position).x) <= raio_onda \
			and k.is_on_floor():
		k.receber_dano(dano_onda, signf(k.global_position.x - global_position.x))
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0.0, 28.0)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.5
	p.direction = Vector2(1.0, -0.2)
	p.spread = 25.0
	p.gravity = Vector2(0.0, 900.0)
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 360.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = cor_estilhacos
	add_sibling(p)
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)


# --- INVOCADOR --------------------------------------------------------

func _invocar() -> void:
	Som.toca("invocar", -7.0)
	# `filter()` devolve um `Array` sem tipo -- atribui-lo a um `Array[Node]`
	# rebenta em runtime ("Trying to assign an array of type Array").
	_lacaios.assign(_lacaios.filter(func(n: Node) -> bool: return is_instance_valid(n)))
	var pai := get_parent()
	if pai == null:
		return
	for i in lacaios_por_vez:
		if _lacaios.size() >= lacaios_max:
			return
		var d := LACAIO.instantiate()
		d.set("especie", lacaio_especie)
		pai.add_child(d)
		# nasce ao lado do chefe, alternando os lados
		var lado := 1.0 if i % 2 == 0 else -1.0
		d.global_position = global_position + Vector2(lado * 90.0, -20.0)
		_lacaios.append(d)


# --- FEIXE ------------------------------------------------------------
## Risco recto à frente do chefe: magoa uma vez quem estiver na faixa, e
## fica desenhado meio segundo para se perceber o que aconteceu.
func _feixe() -> void:
	Som.toca("feixe_vil", -6.0)
	var dir := _dir_para_koliani()
	var de := global_position + Vector2(dir * 40.0, -10.0)
	var ate := de + Vector2(dir * feixe_alcance, 0.0)

	var k := _obter_koliani()
	if k:
		var rel := k.global_position - de
		if signf(rel.x) == dir and absf(rel.x) <= feixe_alcance \
				and absf(rel.y) <= 60.0:
			k.receber_dano(feixe_dano, dir)

	var l := Line2D.new()
	l.width = 14.0
	l.default_color = feixe_cor
	l.points = PackedVector2Array([de, ate])
	l.top_level = true
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.45)
	tw.tween_callback(l.queue_free)


