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
const ESSENCIA := preload("res://scenes/actors/Essencia.tscn")
const Inimigos9D := preload("res://scripts/regiao1_inimigos.gd")
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
## --- três regras de bicho (5 set 2026) --------------------------------
## São as mecânicas de estreia dos níveis 58, 73 e 74. Nenhuma toca no
## `comportamento`: mudam a REGRA de quem lhe pode tocar, do que ele deixa
## atrás e de quando se mexe.

## Ao morrer parte-se em `divide_em` cópias mais pequenas -- que já não se
## dividem (senão a sala enchia-se sozinha). Nível 58, Fábrica dos
## Homúnculos.
@export var divide_em := 0
## INCORPÓREO: a espada e o pisão atravessam-no, só o TIRO lhe toca. Nível
## 73, Catedral Fantasma. Ver `receber_tiro()`.
@export var so_tiro := false
## Só anda quando a Koliani NÃO está virada para ele -- e pára, quieto,
## quando ela olha. Níveis 68 (brinquedos) e 74 (estátuas).
@export var so_mexe_sem_olhar := false

## ELITE (1 por nível na campanha à mão): aura a pulsar + barra de vida por
## cima da cabeça + rebentamento maior na morte. Lê-se como "este é o grande".
@export var elite := false
## Que monstro pixel-art usar (pack CC0 LuizMelo "Monsters Creatures
## Fantasy"). Pastas em `assets/sprites/pixel/enemies/<especie>/`.
@export_enum("goblin", "mushroom", "esqueleto", "olho",
	"imp", "chort", "orc", "xamane", "demonio_grande", "ogro",
	"abobora", "wogol", "necromante", "lodo",
	"besouro", "raptor", "mastim", "gosma", "abutre",
	"morcego_dos_ventos", "sentinela_flutuante", "gaivota_sombria",
	"golem_aereo", "elemental_do_vento",
	"sentinela_da_torre", "acolito_do_eco", "automato_do_sino",
	"gargula_vitral", "sino_flutuante", "arqueiro_das_sombras",
	"monge_das_correntes", "espirito_do_eco", "construto_vitral",
	"corvo_do_sino") var especie := "goblin"
## Só a ARTE (Execution 9D+9E): quem a define veste-se com a arte de produção
## desta identidade em vez da da `especie`, que continua a mandar no som, no
## tamanho e em tudo o resto. É o que faz os clones da Morvanna parecerem
## Morvanna e as crias da Rainha parecerem aranhas, sem lhes mudar o jogo.
var identidade_visual := ""

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
	# --- REGIAO II, bestiario CANONICO (Super-Process A2, 18 set 2026) ------
	# Recortadas da prancha aprovada `enemy_gameplay_pack.png` por
	# `tools/extrair_inimigos_regiao02.py` -- nao sao desenho novo, sao as
	# poses que a prancha ja' tinha, com os estados que ela ja' nomeava.
	# Ate' aqui a Regiao II usava o pool da antiga Prisao (esqueleto, chort,
	# orc, imp, mastim): bichos terrestres de masmorra num sitio cuja
	# identidade e' o AR. Censo do audit: 0 dos 10 canonicos em N06-N10.
	"morcego_dos_ventos":  {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"sentinela_flutuante": {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	# --- REGIAO III, bestiario CANONICO ------------------------------------
	# Recortadas da prancha aprovada `enemy_gameplay_pack.png` da Regiao III
	# por `tools/extrair_inimigos_regiao03.py`. Mesmo metodo da Regiao II --
	# nao e' desenho novo, sao as poses que a prancha ja' tinha, com os
	# cinco estados que ela ja' nomeava (IDLE/ANDA/ATAQUE/DANO/MORTE).
	# Ate' aqui a Torre dos Ecos usava `xamane, wogol, olho, abutre, imp`:
	# demonios genericos herdados. Censo da auditoria: 0 dos 10 canonicos.
	"sentinela_da_torre":   {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"acolito_do_eco":       {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"automato_do_sino":     {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"gargula_vitral":       {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"sino_flutuante":       {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"arqueiro_das_sombras": {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"monge_das_correntes":  {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"espirito_do_eco":      {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"construto_vitral":     {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"corvo_do_sino":        {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"gaivota_sombria":     {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"golem_aereo":         {"idle": 2, "run": 2, "hit": 1, "dead": 1},
	"elemental_do_vento":  {"idle": 2, "run": 2, "hit": 1, "dead": 1},
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
## O ultimo dano veio de um PROJECTIL? Posto pelo `receber_tiro()` e limpo
## logo a seguir -- e' o unico sitio onde o `so_tiro` consegue distinguir.
var _de_longe := false
## Vida com que nasceu, para as copias do `divide_em` nao herdarem a vida
## a zero de quem se partiu.
var _vida_ini := 0
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
## RECUO a sério (9H.16 D). Até aqui levar um golpe era
## `global_position.x += dir * 8` -- um TELETRANSPORTE de 8 px, instantâneo
## e sem física: o bicho não recuava, piscava para o lado. Sem reação
## visível, qualquer combo se lê como bater num saco. Agora o golpe deixa
## uma velocidade que decai por atrito, e enquanto ela durar a IA não manda
## no movimento.
var _recuo_vel := 0.0
var _recuo_t := 0.0
## Atrito do recuo (px/s por segundo). Alto = trava depressa.
const RECUO_ATRITO := 1250.0
## Quanto este inimigo resiste ao empurrão. 1 = normal; >1 = pesado.
@export var resistencia_recuo := 1.0
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
		_dividir()
		if elite:
			_pop_morte_elite()
		if _anim:
			_morrer_anim()
		else:
			_soltar_essencia()
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


## O CORPO do bicho é interpolado (é ele que anda) mas os nós de dentro NÃO.
## Duas razões, ambas visíveis se isto faltar:
##
## - o balanço/respiração (`_corpo.position.y`, `_sprite.rotation`) é animado
##   no `_process`, a 165 Hz; interpolado, voltava a ser amostrado a 60 Hz e
##   com um tick de atraso -- ficava mole;
## - a viragem é `_sprite.scale.x = ±1`. Interpolar isso faz o sprite passar
##   POR ZERO durante um tick, ou seja esmagava-se de cada vez que o bicho se
##   virava.
##
## Como só o transform LOCAL destes filhos deixa de ser interpolado, eles
## continuam a herdar a posição interpolada do corpo: movimento suave, virar
## seco. Herdado por `ChefeBase`, portanto vale para todos os chefes também.
func _sem_interpolacao_no_visual() -> void:
	for no in [_sprite, _corpo, _anim]:
		if no:
			(no as Node).physics_interpolation_mode = \
				Node.PHYSICS_INTERPOLATION_MODE_OFF


func _ready() -> void:
	# dificuldade a subir ao longo de TODA a campanha, e devagar: o Nível 1
	# tem demónios MAIS FRACOS que o valor base (o jogo estava a começar
	# demasiado duro) e o Nível 30 fica ~x1.4. Curva linear em `indice_nivel`.
	if not _e_chefe():
		var f := float(clampi(EstadoJogo.indice_nivel, 0, 29)) / 29.0
		vida = maxi(1, int(round(vida * (0.8 + 0.6 * f))))
		dano_contacto = maxi(1, int(round(dano_contacto * (0.65 + 0.75 * f))))
		velocidade *= 0.88 + 0.34 * f

	_sem_interpolacao_no_visual()
	_vida_ini = vida
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
		_anim_escala_base = _anim.scale
		_sprite_base_y = _sprite.position.y if _sprite else 0.0
		_fase_vida = randf() * TAU
		_anim.play("idle")
		_calibrar_pes()
	if elite:
		_montar_elite()


## Altura a que o corpo opaco deve ficar. Os chefes reescrevem-na (ver
## `ChefeBase.ALTURA_ALVO_CHEFE`): um chefe com 48 px lia-se como um bicho
## comum, e a normalização foi feita justamente para os bichos comuns
## ficarem todos do mesmo tamanho.
func _altura_alvo() -> float:
	return ALTURA_ALVO_INIMIGO * (0.86 if especie in ESPECIES_VOAM else 1.0)


## Largura máxima do corpo no ecrã, ou 0 = sem tecto. Os bichos comuns não
## precisam (vêm todos de packs de silhueta parecida); os chefes sim -- ver
## `ChefeBase.LARGURA_ALVO_CHEFE`.
func _largura_alvo() -> float:
	return 0.0


## Quem tem POSE DE ATAQUE propria, e com quantos quadros. Fica em tabela a
## parte (e nao dentro de `ESPECIES`) porque o formato de `ESPECIES` esta'
## travado por um teste que o le' com expressao regular; e porque ter ou nao
## pose de ataque e' uma propriedade de quem tem a arte, nao de todos.
const ATAQUE_FRAMES := {
	"morcego_dos_ventos": 1,      # INVESTIDA
	"sentinela_flutuante": 1,
	"gaivota_sombria": 2,         # MERGULHO + ATAQUE
	"golem_aereo": 1,             # ATAQUE
	"elemental_do_vento": 1,
}

## Espécies que voam -- não se alinham os pés ao chão.
const ESPECIES_VOAM := ["olho", "abutre",
	# as cinco canonicas da Regiao II voam, levitam ou SAO vento -- e' a
	# definicao da regiao ("Nenhum e' um bicho de masmorra terrestre")
	"morcego_dos_ventos", "sentinela_flutuante", "gaivota_sombria",
	"golem_aereo", "elemental_do_vento",
	# Regiao III: a gargula patrulha EM VOO, o sino flutua, o corvo voa e o
	# espirito atravessa plataformas -- a prancha diz isso de cada um.
	"gargula_vitral", "sino_flutuante", "corvo_do_sino", "espirito_do_eco"]

## A que FAMILIA de som pertence cada espécie (4 set 2026, pedido do Paulo:
## "faça com que os mobs façam sons apropriados ao tipo de monstro"). Até
## aqui as 19 espécies partilhavam `demonio_ataque`/`garra`/`grito`/`praga`,
## por isso um esqueleto e uma gosma rosnavam igual. As amostras de cada
## família são construídas por `tools/preparar_sfx.py` (todas CC0).
const FAMILIA_SOM := {
	"goblin": "humano", "orc": "humano", "imp": "humano",
	"chort": "humano", "wogol": "humano",
	"esqueleto": "morto", "necromante": "morto",
	"gosma": "gosma", "lodo": "gosma", "mushroom": "gosma",
	"mastim": "besta", "raptor": "besta",
	"besouro": "insecto",
	"olho": "voador", "abutre": "voador",
	"morcego_dos_ventos": "voador", "gaivota_sombria": "voador",
	"elemental_do_vento": "voador",
	"sentinela_flutuante": "morto", "golem_aereo": "grande",
	"demonio_grande": "grande", "ogro": "grande",
	"xamane": "grande", "abobora": "grande",
	# Regiao III -- Torre dos Ecos
	"sentinela_da_torre": "humano", "arqueiro_das_sombras": "humano",
	"monge_das_correntes": "humano", "acolito_do_eco": "morto",
	"espirito_do_eco": "morto", "sino_flutuante": "morto",
	"gargula_vitral": "voador", "corvo_do_sino": "voador",
	"automato_do_sino": "grande", "construto_vitral": "grande",
}


## Toca `ataque`/`dano`/`morte` na voz da família desta espécie. Se por
## alguma razão a amostra não existir, o `Som` ignora e não se ouve nada --
## melhor isso do que voltar ao rosnado único de antes.
func _voz(que: String, volume := -13.0, pitch := 1.0) -> void:
	var fam: String = FAMILIA_SOM.get(especie, "humano")
	Som.toca("mob_%s_%s" % [fam, que], volume, pitch * randf_range(0.94, 1.07))

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
	var alvo := _altura_alvo()
	var k := alvo / float(r.size.y)
	# Bichos LARGOS (o morcego de asas abertas, o baú-mímico, o verme) não
	# podem ser escalados só pela altura: um boneco de 160x68 posto a 100
	# de alto passa a 235 de largo e enche o ecrã. Com um tecto de largura,
	# o que manda é a dimensão maior.
	var larg := _largura_alvo()
	if larg > 0.0 and r.size.x > 0:
		k = minf(k, larg / float(r.size.x))
	_anim.scale = Vector2(clampf(k, 0.25, 3.2), clampf(k, 0.25, 3.2))

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
	_pes_do_centro = pes_do_centro
	# linha de chão = fundo da caixa de colisão do corpo
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or not (col.shape is RectangleShape2D):
		return
	var chao_y := col.position.y + (col.shape as RectangleShape2D).size.y * 0.5
	_anim.position.y = chao_y - pes_do_centro + 2.0  # +2 = enterra ligeiramente
	_anim_base_y = _anim.position.y


## Monta os SpriteFrames a partir das tiras da espécie escolhida.
func _montar_frames() -> void:
	if _anim.sprite_frames != null:
		return  # a cena já traz os seus (chefes pixel-art)
	# Região I: arte de produção 9D, se a desta espécie já estiver integrada
	var prod := Inimigos9D.sprite_frames(self, identidade_visual if identidade_visual != "" else especie)
	if prod:
		_anim.sprite_frames = prod
		return
	var cfg: Dictionary = ESPECIES.get(especie, ESPECIES["goblin"])
	var base := "res://assets/sprites/pixel/enemies/%s" % especie
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	_add_tira(sf, "idle", load("%s/idle.png" % base), int(cfg["idle"]), 9.0, true)
	_add_tira(sf, "run", load("%s/run.png" % base), int(cfg["run"]), 11.0, true)
	_add_tira(sf, "hit", load("%s/hit.png" % base), int(cfg["hit"]), 14.0, false)
	_add_tira(sf, "dead", load("%s/dead.png" % base), int(cfg["dead"]), 11.0, false)
	# A tira de ATAQUE e' opcional e so' existe para quem esta' em
	# `ATAQUE_FRAMES`. O `_estado_anim` ja' pedia "attack" no telegrafo
	# (`_tem_anim("attack")`) desde sempre -- o que nunca existiu foi quem a
	# montasse. As especies antigas nao tem `attack.png` e continuam iguais.
	if ATAQUE_FRAMES.has(especie):
		_add_tira(sf, "attack", load("%s/attack.png" % base),
			int(ATAQUE_FRAMES[especie]), 10.0, false)
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
		elif not _morto and _congelado <= 0.0:
			_anim.modulate = _anim.modulate.lerp(Color(1, 1, 1), dt * 4.0)
		_vida_no_anim(dt)
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


## Fase própria de cada bicho, para um grupo não respirar em uníssono.
var _fase_vida := 0.0
## Escala que o `_normalizar_escala` deixou no `_anim` -- a camada de vida
## MULTIPLICA esta, nunca a substitui (senão todos os bichos voltavam ao
## tamanho da tira).
var _anim_escala_base := Vector2.ONE
var _sprite_base_y := 0.0
## Distância do centro do frame aos pés (com escala), e a altura calibrada.
## A respiração escala à volta do CENTRO do sprite; sem compensar isto, os
## pés subiam e desciam ~4 px e o bicho parecia a flutuar.
var _pes_do_centro := 0.0
var _anim_base_y := 0.0
var _no_ar_antes := false
var _aterrou := 0.0


## CAMADA DE VIDA (Execution 9H). O Game Master: os inimigos e os chefes
## "parecem demasiado estáticos, quase imagem parada". Estavam mesmo: a arte
## de produção da Região I (9D/9E) tem uma pose por estado, e o `_process`
## RETORNAVA assim que existisse `_anim` -- toda a respiração, antecipação e
## recuo que o caminho antigo (`_corpo`) fazia ficava por correr. Um bicho
## com uma pose e sem camada procedimental é, literalmente, uma imagem
## parada a deslizar pelo chão.
##
## O que esta camada acrescenta, sem tocar na arte aprovada nem na física:
##
##   respiração   sobe/desce lento + peito a encher (escala ±4 %)
##   passada      salto vertical ao ritmo do andar, mais alto a correr
##   inclinação   inclina-se para onde vai; recua no telégrafo
##   antecipação  estica-se para trás antes de bater (`anticipacao`)
##   recuo        encolhe e roda ao levar (`_flinch`)
##   aterragem    esmaga e volta ao cair no chão
##
## A amplitude cai para 42 % quando a animação em curso tem mais do que um
## frame: aí a arte já se mexe sozinha e isto é só movimento secundário.
func _vida_no_anim(dt: float) -> void:
	if _sprite == null or _anim == null:
		return
	if _morto:
		return
	_t_anim += dt
	anticipacao = move_toward(anticipacao, 0.0, dt * 3.5)
	_flinch = move_toward(_flinch, 0.0, dt * 6.0)
	_aterrou = move_toward(_aterrou, 0.0, dt * 5.0)
	var no_ar := not is_on_floor()
	if _no_ar_antes and not no_ar:
		_aterrou = 1.0
	_no_ar_antes = no_ar

	var quadros := 1
	if _anim.sprite_frames != null and _anim.sprite_frames.has_animation(_anim.animation):
		quadros = _anim.sprite_frames.get_frame_count(_anim.animation)
	var g := 1.0 if quadros <= 1 else 0.42

	var t := _t_anim + _fase_vida
	var anda := absf(velocity.x) > 5.0
	var vel := 9.0 if anda else 3.4
	var amp := (2.8 if anda else 1.3) * g
	# a passada usa |sin|: o pé toca o chão duas vezes por ciclo
	_sprite.position.y = _sprite_base_y - absf(sin(t * vel)) * amp
	var resp := sin(t * vel * 0.5) * 0.045 * g
	var sx := 1.0 - resp + anticipacao * 0.20 * g - _flinch * 0.22 - _aterrou * 0.10
	var sy := 1.0 + resp - anticipacao * 0.18 * g + _flinch * 0.18 + _aterrou * 0.14
	var esc := _anim_escala_base * Vector2(maxf(sx, 0.4), maxf(sy, 0.4))
	_anim.scale = esc
	# os pés ficam no sítio: o que a escala afasta do centro, a posição repõe
	if _pes_do_centro != 0.0 and _anim_escala_base.y != 0.0:
		_anim.position.y = _anim_base_y - _pes_do_centro * (esc.y / _anim_escala_base.y - 1.0)

	# inclinação: à frente a andar, atrás a preparar o golpe, sacudida no
	# telégrafo. Tudo no `_sprite`, que é quem já trata da viragem.
	var incl := 0.0
	if anda:
		incl += 0.055 * signf(velocity.x) * g
	incl -= anticipacao * 0.11 * _direcao
	incl += _flinch * _flinch_dir * 0.5
	if _telegrafo > 0.0:
		incl += sin(Time.get_ticks_msec() * 0.09) * 0.06
	_sprite.rotation = lerp_angle(_sprite.rotation, incl, clampf(dt * 14.0, 0.0, 1.0))


## Estado da anim do inimigo comum (idle/run/attack). "hit" e "dead" mandam.
##
## O `attack` existe desde a 9H.1 (`tools/animar_criaturas_9h1.py`) e entra no
## TELEGRAFO -- é o mesmo instante em que o bicho estremece e pisca antes de
## bater, e é aí que a antecipação tem de se ver. Antes da 9H.1 nenhum inimigo
## comum tinha animação de ataque: o telégrafo era só cor e tremura.
func _atualizar_anim() -> void:
	if _morto:
		return
	# levar um golpe manda sempre: a reacção tem de se ver mesmo a atacar
	if _anim.animation == "hit" and _anim.is_playing():
		return
	# Execution 9H.9: quem tem estados próprios (um chefe a picar, a aterrar,
	# a levantar-se) diz aqui qual é o clipe. Sem isto um chefe ficava preso
	# na escolha automática e lia-se como um sprite parado.
	var pedida := _anim_desejada()
	if pedida != "" and _tem_anim(pedida):
		# só ao MUDAR de clipe: um clipe sem ciclo que acabou fica na última
		# pose, e é isso que se quer (o remate/recuperação fica sustentado).
		# Re-tocar aqui fazia o ataque repetir-se em loop.
		if _anim.animation != pedida:
			_anim.play(pedida)
		return
	if _anim.animation == "attack" and _anim.is_playing():
		return
	if _telegrafo > 0.0 and _tem_anim("attack"):
		_anim.play("attack")
		return
	var alvo := "run" if _velocidade_visual() > 6.0 else "idle"
	if _anim.animation != alvo:
		_anim.play(alvo)


## O clipe que este bicho quer neste instante, ou "" para deixar a escolha
## automática (idle/run/attack pelo telégrafo). Gancho para as subclasses.
func _anim_desejada() -> String:
	return ""


## Velocidade que conta para a LOCOMOÇÃO visual. Não pode ser só o `x`: quem
## voa mexe-se sobretudo em `y`, e às vezes escrevendo `global_position` sem
## passar pelo `velocity` -- ficava em `idle` a vida toda (era a queixa do
## Game Master de os bichos parecerem sprites fixos).
func _velocidade_visual() -> float:
	return velocity.length()


func _tem_anim(nome: String) -> bool:
	return _anim != null and _anim.sprite_frames != null 		and _anim.sprite_frames.has_animation(nome) 		and _anim.sprite_frames.get_frame_count(nome) > 1


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
	# Enquanto o recuo dura, ele manda no movimento -- senão a IA reescrevia
	# `velocity.x` no frame seguinte e o empurrão não se via.
	if _recuo_t > 0.0:
		_recuo_t = maxf(0.0, _recuo_t - dt)
		_congelado = maxf(0.0, _congelado - dt)
		_atordoado = maxf(0.0, _atordoado - dt)
		velocity.x = _recuo_vel
		_recuo_vel = move_toward(_recuo_vel, 0.0, RECUO_ATRITO * dt)
		if not is_on_floor():
			velocity.y += GRAVIDADE * dt
		move_and_slide()
		return
	if _congelado > 0.0 or _atordoado > 0.0:
		_congelado = maxf(0.0, _congelado - dt)
		_atordoado = maxf(0.0, _atordoado - dt)
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVIDADE * dt
		move_and_slide()
		return
	# ESTÁTUA: quieto enquanto ela olha. Não há aviso nenhum a não ser a
	# própria posição -- entre dois olhares está sempre mais perto.
	if so_mexe_sem_olhar and _koliani_a_olhar():
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
				_voz("ataque", -13.0, 0.8)
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
			_voz("ataque", -14.0, 0.7)
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
				Som.toca("salto", -20.0, 0.68)
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
				_voz("ataque", -13.0, 1.05)
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
				_voz("ataque", -14.0, 0.9)
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
					_voz("ataque", -15.0, 0.7)
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
	_voz("ataque", -13.0, 1.15)
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


## A Koliani está virada para este bicho? Sem Koliani na cena conta como
## "não está a olhar" -- assim o bicho anda, em vez de gelar para sempre.
func _koliani_a_olhar() -> bool:
	var k := get_tree().get_first_node_in_group("koliani")
	if k == null:
		return false
	var d: float = (k as Node2D).global_position.x - global_position.x
	# `_olha_para` e' da Koliani; se o no' do grupo nao a tiver (um duble de
	# teste, um placeholder), `get()` devolve null -- e `float(null)` REBENTA.
	var v: Variant = k.get("_olha_para")
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return false
	var olha := float(v)
	return (olha > 0.0 and d < 0.0) or (olha < 0.0 and d > 0.0)


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
		_voz("ataque", -15.0)
		anticipacao = 1.0  # dá um "bote" visual no ataque


## Multiplicador de dano de um golpe CRÍTICO (inimigo vulnerável, golpe
## pelas costas ou logo a seguir a um rolamento -- ver `Koliani`).
const CRIT_MULT := 1.7

## Execution 9G: VFX de produção da Região I (prancha 07, paleta de corrupção).
const Vfx9G := preload("res://scripts/vfx_regiao1.gd")


## Morte na Região I: a corrupção larga o corpo e dissolve-se. Devolve `true`
## quando tratou do assunto (aí não há anel nem estilhaços do legado).
func _vfx9g_morte() -> bool:
	if not Vfx9G.ativo(self):
		return false
	var alt := maxf(_altura_alvo(), 24.0)
	Vfx9G.tocar(self, "death_dissolve_corrupcao", global_position + Vector2(0.0, -alt * 0.4),
		clampf(alt / 60.0, 0.7, 2.2), 0.0, false, false, 39, 0.8)
	return true

## `forca_recuo` (9H.16 D) é a velocidade do empurrão em px/s. 0 = sem
## recuo (pisão, dano por estado). Os golpes do combo mandam valores
## crescentes -- é o que faz o remate ler-se como remate.
func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false,
		forca_recuo := 0.0) -> void:
	if _morto:
		return
	# INCORPÓREO: a lâmina passa através. Só o que vem de longe lhe toca --
	# e o `_de_longe` só é verdade dentro de um `receber_tiro()`.
	if so_tiro and not _de_longe:
		Som.toca("bloqueio", -18.0, 1.45)
		_flinch = 0.22
		return
	_de_longe = false
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
	_voz("dano", -16.0, 1.15 if critico else 1.0)
	var q := quantidade
	if critico:
		q = int(round(q * (CRIT_MULT + EstadoJogo.bonus("crit_mult"))))  # melhoria "furia"
		# gelo + crítico = ESTILHAÇA: bónus e limpa o congelamento
		if _congelado > 0.0:
			q += int(round(quantidade * 0.6))
			_congelado = 0.0
			_tom_estado = ""
		Impacto.rebentar(self, global_position + Vector2(0.0, -12.0), Color(1, 1, 1), 3.2)
	vida -= q
	if forca_recuo > 0.0 and dir_empurrao != 0.0:
		var f := forca_recuo * (1.35 if critico else 1.0) / maxf(0.2, resistencia_recuo)
		_recuo_vel = signf(dir_empurrao) * f
		_recuo_t = clampf(f / RECUO_ATRITO, 0.08, 0.45)
		# Remate: além de empurrar, LEVANTA do chão. É o que dá ao 4.º
		# golpe um remate que se vê sem olhar para a barra de vida.
		if f >= 380.0 and is_on_floor():
			velocity.y = -195.0
		_flinch = maxf(_flinch, 1.2)
		_flinch_dir = signf(dir_empurrao)
	else:
		# sem recuo pedido: fica o toque de antes, para não mudar o pisão
		# nem o dano por estado.
		global_position.x += dir_empurrao * (12.0 if critico else 8.0)
	if vida <= 0:
		_dividir()
		if elite:
			_pop_morte_elite()
		if _anim:
			_morrer_anim()
		else:
			_soltar_essencia()
			# mesmo "pop" da morte com animação, para o feedback ser igual
			if not _vfx9g_morte():
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


## Parte-se em cópias mais pequenas (nível 58). As filhas nascem com
## `divide_em = 0` -- uma divisão que se repetisse enchia a sala sozinha e
## a jornada não tem chão de rede onde uma horda infinita seja justa.
## Carrega a cena em runtime de propósito: um `preload` da própria cena
## dentro do script dela é um ciclo de recurso.
func _dividir() -> void:
	if divide_em <= 0 or _e_chefe():
		return
	var n := divide_em
	divide_em = 0
	var cena := load("res://scenes/actors/DemonioBase.tscn") as PackedScene
	var pai := get_parent()
	if cena == null or pai == null:
		return
	for i in n:
		var c := cena.instantiate() as DemonioBase
		if c == null:
			continue
		c.especie = especie
		c.comportamento = comportamento
		c.vida = maxi(10, int(round(float(_vida_ini) * 0.42)))
		c.dano_contacto = maxi(4, int(round(float(dano_contacto) * 0.7)))
		c.velocidade = velocidade * 1.15
		c.alcance_patrulha = alcance_patrulha
		c.cor_rim = cor_rim
		c.scale = scale * 0.68
		c.global_position = global_position + Vector2(
			(float(i) - float(n - 1) * 0.5) * 34.0, -6.0)
		pai.add_child(c)


## Entrada de dano de PROJÉCTIL -- existe só por causa do `so_tiro`: é a
## única maneira de o bicho saber que o que lhe tocou veio de longe.
## Quem não a chamar continua a bater como sempre (`receber_dano`).
func receber_tiro(quantidade: int, dir_empurrao := 0.0) -> void:
	_de_longe = true
	receber_dano(quantidade, dir_empurrao)
	_de_longe = false


## Larga ESSÊNCIA ao morrer. Comum: pouca (escala com a região). Elite:
## um monte. Os motes vão para a cena (sobrevivem ao `queue_free` do bicho).
func _soltar_essencia() -> void:
	if _e_chefe():
		return  # os chefes tratam disto no ChefeBase
	var cena := get_tree().current_scene
	if cena == null or not cena.is_inside_tree():
		return
	var reg := float(clampi(EstadoJogo.indice_nivel, 0, 29)) / 29.0
	var total: int = (14 + int(reg * 22.0)) if elite else (1 + (1 if randf() < 0.5 + reg * 0.4 else 0) + int(reg * 2.0))
	if total <= 0:
		return
	var n := 1 if total <= 2 else clampi(total / 4, 2, 6)
	for i in n:
		var m := ESSENCIA.instantiate()
		m.valor = maxi(1, total / n + (1 if i < total % n else 0))
		m.global_position = global_position + Vector2(randf_range(-10.0, 10.0), -14.0)
		# O golpe fatal pode correr no flush da física. Adiar a inserção da
		# Area2D inteira, não apenas o monitoring da essência.
		cena.add_child.call_deferred(m)


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
	_voz("morte", -11.0)
	velocity = Vector2.ZERO
	_soltar_essencia()
	# "pop" de morte: o mesmo anel do acerto, maior e na cor do rim do bioma
	var prod_9g := _vfx9g_morte()
	if not prod_9g:
		Impacto.rebentar(self, global_position + Vector2(0.0, -10.0),
			cor_rim.lerp(Color(1, 1, 1), 0.35), 3.4)
	if _area_contacto:
		_area_contacto.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	_anim.play("dead")
	await _anim.animation_finished
	if not prod_9g:
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
