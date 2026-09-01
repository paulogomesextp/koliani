class_name GeradorCorredor
extends Node2D
## JORNADA -- constrói a maior parte de cada nível. Em vez de um chão por
## onde se anda em frente, há um LÍQUIDO MORTAL em toda a extensão (lava /
## ácido / água podre / trevas, conforme a região) e uma ESPINHA de
## plataformas por cima -- pequenas, muito espaçadas, com perigos nos vãos.
## Cair = morte e volta ao checkpoint. Obriga a saltar, subir, descer e a
## passar pelos obstáculos. O chefe fica SEMPRE no fim (geometria à mão).
##
## Anti-softlock (sem chão de rede, é preciso cuidado):
##  - a espinha é SEMPRE contínua: cada plataforma está ao alcance de salto
##    da anterior (Δx <= ~195, subida <= ~115; descer é livre);
##  - plataformas móveis da espinha voltam sempre a um ponto fixo alcançável;
##  - nada BLOQUEIA -- os perigos só magoam/matam e ciclam;
##  - checkpoint a cada 2 plataformas da espinha (morrer custa pouco);
##  - a última câmara é uma passadeira sólida lisa que encosta ao nível.
## `corredor = false` na cena raiz desliga (o último nível nunca o tem).

# Curva de dificuldade (ago 2026): o jogo estava DEMASIADO duro logo no
# Nível 1. Agora a jornada arranca curta e suave e cresce até ao Nível 30 --
# comprimento, densidade de perigos/inimigos e o LEQUE de câmaras (ver
# `TIER_FLAVOUR`) escalam todos com `_dif` (= indice_nivel / 29).
@export var comprimento_base := 6200.0
@export var por_nivel := 880.0
@export var comprimento_max := 32000.0
@export var especie_inimigo := ""
@export var entrada_fresca := true
@export var otimizar_visibilidade := true

const PLAT := preload("res://scenes/actors/Plataforma.tscn")
const ESPINHOS := preload("res://scenes/actors/Espinhos.tscn")
const DEMONIO := preload("res://scenes/actors/DemonioBase.tscn")
const SERRA := preload("res://scenes/actors/Serra.tscn")
const FOGO := preload("res://scenes/actors/Fogo.tscn")
const GUILHOTINA := preload("res://scenes/actors/Guilhotina.tscn")
const TORRETA := preload("res://scenes/actors/Torreta.tscn")
const PLAT_FLUT := preload("res://scenes/actors/PlataformaFlutuante.tscn")
const PLAT_RITMO := preload("res://scenes/actors/PlataformaRitmada.tscn")
const PLAT_CORRENTE := preload("res://scenes/actors/PlataformaCorrente.tscn")
const TUMULO := preload("res://scenes/actors/TumuloElevador.tscn")
const ZONA_GRAV := preload("res://scenes/actors/ZonaGravidade.tscn")
const CORRENTE_AR := preload("res://scenes/actors/CorrenteAr.tscn")
const PENDULO := preload("res://scenes/actors/PenduloLamina.tscn")
const PEDRA := preload("res://scenes/actors/PedraQueda.tscn")
const PORTAL := preload("res://scenes/actors/Portal.tscn")
const PLAT_QUEBRA := preload("res://scenes/actors/PlataformaQuebra.tscn")
const TRAMPOLIM := preload("res://scenes/actors/Trampolim.tscn")
const IMPULSOR := preload("res://scenes/actors/Impulsor.tscn")
const AGUA := preload("res://scenes/actors/AguaVenenosa.tscn")
const CHECKPOINT := preload("res://scripts/checkpoint.gd")

## Líquido mortal por região: [cor, brasas]. floresta=água podre, prisão=ácido,
## torres=??? (usa trevas), catacumbas=trevas, cidade=ácido citrino,
## castelo=lava.
## Cor do "chão mortal" por região. Ocupa um terço do ecrã na jornada, por
## isso NÃO pode ser tinta chapada e berrante: os tons ficam escuros e
## dessaturados (a linha de água acesa do `AguaVenenosa` é que dá a leitura
## do perigo) e puxados para o luar/magenta do key_art.
const LIQUIDO := {
	0: [Color(0.13, 0.28, 0.15, 0.94), false],   # água podre
	1: [Color(0.26, 0.42, 0.14, 0.93), false],   # ácido
	2: [Color(0.06, 0.05, 0.12, 0.96), false],   # trevas / vazio
	3: [Color(0.05, 0.03, 0.09, 0.97), false],   # trevas do abismo
	4: [Color(0.34, 0.40, 0.12, 0.93), false],   # ácido citrino
	5: [Color(0.62, 0.22, 0.08, 0.94), true],    # lava
}

## Tipos de "flavour" de câmara (o que se semeia à volta da espinha).
const POOL_REGIAO := {
	0: ["saltos", "serras", "pendulos", "ritmo", "trampolim", "gruta", "portal"],
	1: ["saltos", "correntes", "elevador", "quebra", "guilhotinas", "serras", "portal", "crossfire", "espinhos"],
	2: ["vento", "saltos", "gravidade", "pendulos", "trampolim", "ritmo", "portal", "ferry"],
	3: ["gruta", "pedras", "elevador", "quebra", "guilhotinas", "pendulos", "portal", "ferry", "espinhos"],
	4: ["saltos", "impulso", "serras", "fogo", "trampolim", "guilhotinas", "portal", "crossfire"],
	5: ["pendulos", "fogo", "guilhotinas", "ritmo", "quebra", "gravidade", "portal", "crossfire", "ferry"],
}

## `_dif` mínimo para cada tipo de câmara entrar na pool. Assim o Nível 1
## (dif 0) só vê câmaras de saltos/gruta/trampolim e a coisa vai apertando
## até ao Nível 30 (dif 1), que tem tudo.
const TIER_FLAVOUR := {
	"saltos": 0.0, "gruta": 0.0, "trampolim": 0.0,
	"ritmo": 0.12, "portal": 0.12, "correntes": 0.16, "elevador": 0.18,
	"gravidade": 0.34, "serras": 0.36, "vento": 0.42, "pendulos": 0.46,
	"impulso": 0.5, "guilhotinas": 0.58, "quebra": 0.62, "fogo": 0.66,
	"crossfire": 0.4, "ferry": 0.3, "espinhos": 0.28,
}
## Fallback quando a região ainda não libertou nada (níveis muito baixos).
const FLAVOUR_SUAVE := ["saltos", "gruta", "trampolim"]

## TODAS as câmaras que `_flavour()` sabe construir. Tem de conter todos os
## valores de `POOL_REGIAO`, `ASSINATURA` e `FLAVOUR_SUAVE` -- um teste em
## `tests/run_tests.gd` garante isso (foi assim que "pedras" andou a gerar
## um vão morto silencioso durante semanas). As câmaras "torre"/"poco"/
## "pilares"/"descanso"/"forquilha"/"arena"/"corredor"/"cripta" também
## entram aqui embora sejam escolhidas por outro caminho no `_construir`.
const CAMARAS_FLAVOUR := [
	"saltos", "serras", "pendulos", "ritmo", "trampolim", "gruta", "quebra",
	"correntes", "elevador", "vento", "gravidade", "guilhotinas", "fogo",
	"impulso", "portal", "torre", "poco", "pilares", "descanso", "forquilha",
	"arena", "corredor", "cripta", "crossfire", "ferry", "pedras", "espinhos",
]

## Câmara "assinatura" de cada região -- no acto do meio da jornada aparece
## com mais frequência para o bioma ter identidade própria (se a dificuldade
## já a libertou). Índice = região.
const ASSINATURA := {
	0: "trampolim",    # Floresta -- ricochete
	1: "guilhotinas",  # Prisão -- execuções
	2: "vento",        # Torres -- correntes de ar
	3: "gruta",        # Catacumbas -- túneis escuros
	4: "impulso",      # Cidade -- máquinas
	5: "fogo",         # Castelo -- lava
}

var _chao_y := 0.0     # topo do líquido mortal
var _idx := 0
var _dif := 0.0
var _regiao := 0
var _esp := "goblin"
var _rng := RandomNumberGenerator.new()
var _cont_i := 0

## Espaço mínimo (px) entre checkpoints da jornada. Antes havia um a cada
## ~2 plataformas (~380 px) -- eram MUITOS. Passa a haver um a cada ~4000 px
## (~90% menos); o do início e o de antes do chefe são sempre postos.
const DIST_CHECKPOINT := 4000.0
var _ultimo_check_x := -1.0e9

## Ritmo (pegada Dead Cells): alterna câmaras de TENSÃO (gauntlets, torres)
## com câmaras de ALÍVIO (`descanso` -- plataforma larga limpa + checkpoint).
var _camaras := 0
var _pos_intenso := false

## Subida máxima (px) de um degrau para o seguinte -- um salto + duplo salto
## da Koliani. Nenhuma plataforma da jornada fica mais alta que isto face à
## anterior (descer é livre). Descer/cair pode ser muito mais.
const SUBIDA_MAX := 104.0
## Topo da banda vertical jogável (definido em `_construir`). Quanto maior a
## dificuldade, mais alto -> jornadas com torres e poços a sério, não só uma
## fita de plataformas quase em linha.
var _teto_y := 0.0


func _ready() -> void:
	call_deferred("_construir")


func _construir() -> void:
	var kol := get_tree().get_first_node_in_group("koliani")
	if kol == null:
		return
	_idx = EstadoJogo.indice_nivel
	_dif = clampf(float(_idx) / 29.0, 0.0, 1.0)
	_regiao = maxi(0, EstadoJogo.regiao_atual())
	_rng.seed = hash("jornada4|%d" % _idx)
	_esp = especie_inimigo if especie_inimigo != "" else _especie_do_nivel()

	var ancora: Vector2 = EstadoJogo.jornada_ancora_para(
		_idx, func() -> Vector2: return (kol as Node2D).global_position)
	_chao_y = ancora.y + 92.0
	_teto_y = _chao_y - lerpf(640.0, 1320.0, _dif)

	var comp: float = clampf(comprimento_base + por_nivel * float(_idx),
		comprimento_base, comprimento_max)
	var x0 := ancora.x - comp

	# --- líquido mortal em toda a extensão -----------------------------
	var liq: Array = LIQUIDO.get(_regiao, LIQUIDO[0])
	var agua := AGUA.instantiate()
	agua.name = "LiquidoMortal"
	agua.largura = comp + 900.0
	agua.altura = 460.0
	agua.cor = liq[0]
	agua.brasas = liq[1]
	agua.position = Vector2((x0 + ancora.x) * 0.5, _chao_y + 230.0)
	add_child(agua)

	# parede de fundo (não se sai pela esquerda). LARGA, ESCURA e encostada à
	# plataforma de partida, para ler como "fim do mundo" e não como uma
	# parede a partir/trepar com espaço do outro lado.
	var fundo := PLAT.instantiate()
	add_child(fundo)
	fundo.tamanho = Vector2(200.0, 900.0)
	fundo.position = Vector2(x0 - 60.0, _chao_y - 300.0)
	fundo.modulate = Color(0.32, 0.32, 0.4)

	var casca := get_parent().get_node_or_null("Casca")
	if casca and casca.has_method("abrir_esquerda"):
		casca.abrir_esquerda(x0 - 160.0)
		# masmorra FECHADA: o tecto (`topo`) e' uma parede solida fixa, que
		# nada aqui em cima sabia -- a jornada podia mandar a espinha de
		# plataformas mais alto do que a sala permite, e o tecto bloqueava
		# o caminho por completo (bug: "parede a impedir de subir", nivel
		# incompletavel). Reaperta a banda vertical à altura real da sala.
		var topo_casca: Variant = casca.get("topo")
		if topo_casca != null:
			_teto_y = maxf(_teto_y, float(topo_casca) + 110.0)

	var atm := get_tree().get_first_node_in_group("atmosfera")
	if atm and atm.has_method("atualizar_extensao"):
		var largura_atual: float = atm.get("largura_nivel")
		atm.atualizar_extensao(maxf(largura_atual, comp + 3200.0), x0 - 400.0)

	# --- espinha de plataformas --------------------------------------
	var pool: Array = _pool_permitida()
	var x := x0 + 40.0
	var y := _chao_y - 150.0

	# plataforma de partida (larga) + Koliani em cima
	var par := _novo_container(x)
	_plat(par, Vector2(x + 70.0, y), Vector2(190.0, 20.0), 46.0)
	if entrada_fresca:
		var inicio := Vector2(x + 40.0, y - 40.0)
		(kol as Node2D).global_position = inicio
		if "velocity" in kol:
			kol.velocity = Vector2.ZERO
		kol.set("_pos_inicial", inicio)
		EstadoJogo.definir_checkpoint(inicio)
	_checkpoint(x + 40.0, y, true)
	x += 240.0

	var passos := 0
	var ant_flavour := ""
	# quão longe ficam as câmaras de flavour umas das outras (passos da
	# espinha): muito espaçadas no Nível 1, coladas no Nível 30.
	var espaco_flavour := int(round(lerpf(13.0, 4.0, _dif)))
	var prox_flavour := espaco_flavour + _rng.randi() % 3
	# de 2 em 2/3 câmaras força-se uma VERTICAL (torre/poço/pilares)
	var flavs_ate_vertical := 2
	# altitude-alvo que vagueia por toda a banda vertical -> a espinha sobe e
	# desce em vagas longas em vez de ondular sempre à mesma altura
	var banda := _chao_y - _teto_y
	var alvo_y := _chao_y - _rng.randf_range(140.0, banda * 0.85)
	var passos_alvo := 4 + _rng.randi() % 4
	while x < ancora.x - 900.0:
		if passos % 10 == 0:
			par = _novo_container(x)
		# --- estrutura em 3 ACTOS (arco de um bioma tipo Dead Cells) -------
		# prog = 0 (início da jornada) .. 1 (encosta ao nível). `intens`
		# escala a densidade de perigos/inimigos: intro suave -> meio a
		# apertar -> alívio antes da rampa final para o chefe.
		var prog := clampf((x - x0) / maxf(1.0, comp), 0.0, 1.0)
		var intens := 1.0
		if prog < 0.28:
			intens = lerpf(0.35, 1.0, prog / 0.28)
		elif prog < 0.82:
			intens = lerpf(1.0, 1.28, (prog - 0.28) / 0.54)
		else:
			intens = 0.5
		# nova altitude-alvo de tempos a tempos
		if passos >= passos_alvo:
			passos_alvo = passos + 4 + _rng.randi() % 5
			alvo_y = _chao_y - _rng.randf_range(140.0, banda * 0.92)
		# --- passo da espinha: caminha para a altitude-alvo, mas NUNCA sobe
		#     mais que um salto de cada vez (descer/cair pode ser muito mais) ---
		var passo_y := clampf((alvo_y - y) * 0.5 + _rng.randf_range(-32.0, 32.0),
			-SUBIDA_MAX, 300.0)
		y = clampf(y + passo_y, _teto_y, _chao_y - 66.0)
		var w := _rng.randf_range(60.0, 94.0)
		var movel := _dif > 0.33 and _rng.randf() < (0.04 + 0.12 * _dif) * intens
		if movel:
			_plat_movel_spine(par, Vector2(x, y), w)
		else:
			_plat(par, Vector2(x, y), Vector2(w, 18.0))
		# 2.º piso: às vezes uma plataforma logo por cima = rota alternativa
		if _rng.randf() < 0.12 and y - 210.0 > _teto_y:
			_plat(par, Vector2(x + _rng.randf_range(-28.0, 28.0),
				y - _rng.randf_range(150.0, 205.0)), Vector2(_rng.randf_range(56.0, 82.0), 16.0))
		# perigo no vão a seguir (não bloqueia a aterragem)
		if passos > 0 and _rng.randf() < (0.05 + 0.5 * _dif) * intens:
			_perigo_no_vao(par, x, y)
		# checkpoint a cada 2 plataformas
		if passos % 2 == 0:
			_checkpoint(x, y)
		# inimigo ocasional na plataforma
		if _rng.randf() < (0.05 + 0.22 * _dif) * intens:
			_inimigo_em(par, Vector2(x, y - 30.0))
		# decoração
		_decorar(par, x, y)
		if passos % 6 == 0:
			_coluna_fundo(par, x + _rng.randf_range(-120.0, 120.0))

		# --- câmara de tempos a tempos: alterna TENSÃO e ALÍVIO ---
		passos += 1
		if passos >= prox_flavour:
			prox_flavour = passos + espaco_flavour + _rng.randi() % 3
			var f: String
			_camaras += 1
			flavs_ate_vertical -= 1
			var sig: String = ASSINATURA.get(_regiao, "")
			if prog > 0.82:
				# ACTO 3: alívio antes da rampa final -> quase só descansos
				f = "descanso" if _rng.randf() < 0.8 else pool[_rng.randi() % pool.size()]
				_pos_intenso = false
			elif _pos_intenso:
				f = "descanso"          # logo a seguir a uma câmara puxada -> respira
				_pos_intenso = false
			elif flavs_ate_vertical <= 0:
				flavs_ate_vertical = 2 + _rng.randi() % 2
				f = ["torre", "poco", "pilares"][_rng.randi() % 3]
				_pos_intenso = true
			elif _camaras % 4 == 0:
				f = "descanso"
			# câmaras "tom" novas (crossfire/ferry/pedras/espinhos) -- ramo
			# próprio e ALTO na cadeia: a pool uniforme e os ramos de
			# arena/torre/descanso engoliam-nas quase sempre. `pool` já vem
			# filtrado por região+tier em `_pool_permitida()`.
			elif prog < 0.82 and _tem_tom_novo(pool) and _rng.randf() < 0.32:
				f = _escolher_tom_novo(pool)
				_pos_intenso = true
			elif prog >= 0.28 and prog <= 0.82 and sig != "" \
					and _dif + 0.0001 >= float(TIER_FLAVOUR.get(sig, 9.0)) \
					and _rng.randf() < 0.3:
				f = sig                 # ACTO 2: a assinatura do bioma
				_pos_intenso = sig in ["guilhotinas", "fogo"]
			elif prog < 0.82 and _dif > 0.12 and _rng.randf() < 0.13:
				f = "arena"             # limpar a sala
				_pos_intenso = true
			elif prog >= 0.28 and prog < 0.82 and _dif > 0.28 and _rng.randf() < 0.12:
				f = "corredor"          # gauntlet apertado
				_pos_intenso = true
			elif prog < 0.82 and _rng.randf() < (0.16 if _regiao == 3 else 0.08):
				f = "cripta"            # sala com obstáculo interior + pedras
				_pos_intenso = true
			elif _dif > 0.18 and _rng.randf() < 0.2:
				f = "forquilha"
				_pos_intenso = true
			else:
				f = pool[_rng.randi() % pool.size()]
				if f == ant_flavour:
					f = pool[(_rng.randi() + 1) % pool.size()]
				_pos_intenso = f in ["guilhotinas", "serras", "pendulos", "fogo", "quebra", "crossfire", "ferry", "pedras", "espinhos"]
			ant_flavour = f
			var res := _flavour(par, f, x, y)
			x = res.x
			y = res.y
			alvo_y = y  # a espinha continua da altura onde a câmara acabou
			continue

		x += _rng.randf_range(148.0, 188.0)

	# --- passadeira final sólida até ao nível feito à mão ---
	par = _novo_container(x)
	var yf := clampf(y, _chao_y - 200.0, _chao_y - 80.0)
	var passar := PLAT.instantiate()
	add_child(passar)
	passar.position = Vector2((x + ancora.x + 200.0) * 0.5, yf + 30.0)
	passar.tamanho = Vector2(ancora.x + 400.0 - x + 200.0, 44.0)
	passar.altura_visual = 110.0
	_checkpoint(x + 60.0, yf, true)  # sempre um antes do chefe
	_inimigo_em(par, Vector2(x + 240.0, yf - 30.0))


# --- infra --------------------------------------------------------------

## A pool de flavour da região atual, filtrada pelo que a dificuldade já
## libertou (`TIER_FLAVOUR`). Se a região ainda não tem nada disponível
## (níveis baixos numa região "dura"), cai nas câmaras suaves.
func _pool_permitida() -> Array:
	var base: Array = POOL_REGIAO.get(_regiao, POOL_REGIAO[0])
	var out: Array = []
	for f: String in base:
		if _dif + 0.0001 >= float(TIER_FLAVOUR.get(f, 0.0)):
			out.append(f)
	return out if out.size() >= 2 else FLAVOUR_SUAVE.duplicate()


## Câmaras "tom" recentes que compensam ter um ramo próprio na seleção
## (senão nunca calhavam). Só as que a região tem na pool.
const TONS_NOVOS := ["crossfire", "ferry", "pedras", "espinhos"]

func _tem_tom_novo(pool: Array) -> bool:
	for t in TONS_NOVOS:
		if t in pool:
			return true
	return false


func _escolher_tom_novo(pool: Array) -> String:
	var opc: Array = []
	for t in TONS_NOVOS:
		if t in pool:
			opc.append(t)
	return opc[_rng.randi() % opc.size()]


func _novo_container(x: float) -> Node2D:
	_cont_i += 1
	var c := Node2D.new()
	c.name = "Cam_%d" % _cont_i
	add_child(c)
	if otimizar_visibilidade and DisplayServer.get_name() != "headless":
		var en := VisibleOnScreenEnabler2D.new()
		en.process_mode = Node.PROCESS_MODE_ALWAYS
		en.rect = Rect2(x - 1100.0, _chao_y - 1800.0, 3400.0, 2500.0)
		c.add_child(en)
	return c


func _plat(par: Node2D, pos: Vector2, tam: Vector2, alt_vis := 0.0) -> void:
	var p := PLAT.instantiate()
	p.position = pos
	p.tamanho = tam
	if alt_vis > 0.0:
		p.altura_visual = alt_vis
	par.add_child(p)


## Segmento móvel da espinha: uma PlataformaFlutuante com deriva PEQUENA (não
## se afasta ao ponto de a plataforma seguinte ficar fora de alcance).
func _plat_movel_spine(par: Node2D, pos: Vector2, w: float) -> void:
	var pf := PLAT_FLUT.instantiate()
	pf.largura = w + 24.0
	pf.balanco = 10.0
	pf.periodo = _rng.randf_range(2.2, 3.0)
	pf.deriva = _rng.randf_range(50.0, 90.0)
	pf.periodo_deriva = _rng.randf_range(3.0, 4.4)
	pf.position = pos
	par.add_child(pf)


## Perigo num vão (pêndulo, serra ou fogo) -- posicionado ENTRE plataformas,
## acima do líquido, sem tapar a aterragem.
func _perigo_no_vao(par: Node2D, x: float, y: float) -> void:
	match _rng.randi() % 3:
		0:
			var pe := PENDULO.instantiate()
			var comp := _rng.randf_range(150.0, 210.0)
			pe.comprimento = comp
			pe.periodo = _rng.randf_range(1.9, 2.7) - 0.35 * _dif
			pe.amplitude_graus = 46.0 + 20.0 * _dif
			pe.dano = 8 + int(20.0 * _dif)
			pe.fase = _rng.randf()
			pe.position = Vector2(x + 95.0, y - comp - 30.0)
			par.add_child(pe)
		1:
			var s := SERRA.instantiate()
			s.position = Vector2(x + 95.0, y - 20.0)
			s.percurso = Vector2(0.0, -_rng.randf_range(80.0, 130.0 + 40.0 * _dif))
			s.tempo = _rng.randf_range(1.1, 1.7)
			par.add_child(s)
		2:
			var f := FOGO.instantiate()
			f.position = Vector2(x + 95.0, y + 6.0)
			f.intervalo = 2.3 - 0.6 * _dif
			f.dur_ativa = 0.8 + 0.5 * _dif
			f.fase = _rng.randf() * 1.5
			par.add_child(f)


## Props decorativos (0x72 DungeonTileset II, CC0) -- ["ficheiro", escala].
const PROPS_CHAO := [
	["crate.png", 3.2], ["skull.png", 3.0],
	["wall_banner_red.png", 3.4], ["wall_banner_blue.png", 3.4],
]
const PROP_COLUNA := preload("res://assets/sprites/pixel/props/column.png")


## Prop pequeno pousado numa plataforma da espinha.
func _decorar(par: Node2D, x: float, y: float) -> void:
	if _rng.randf() > 0.3:
		return
	var d: Array = PROPS_CHAO[_rng.randi() % PROPS_CHAO.size()]
	var tex: Texture2D = load("res://assets/sprites/pixel/props/%s" % d[0])
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(d[1], d[1]) * _rng.randf_range(0.85, 1.15)
	s.z_index = -1
	s.position = Vector2(x + _rng.randf_range(-24.0, 24.0),
		y - 9.0 - tex.get_height() * s.scale.y * 0.5)
	par.add_child(s)


## Coluna alta a subir do líquido, atrás dos atores (profundidade).
func _coluna_fundo(par: Node2D, x: float) -> void:
	var s := Sprite2D.new()
	s.texture = PROP_COLUNA
	var esc := _rng.randf_range(3.5, 6.0)
	s.scale = Vector2(esc, esc)
	s.z_index = -3
	s.modulate = Color(0.6, 0.6, 0.7, 0.85)
	s.position = Vector2(x, _chao_y - PROP_COLUNA.get_height() * esc * 0.5 + 40.0)
	par.add_child(s)


func _inimigo_em(par: Node2D, pos: Vector2) -> void:
	var d := DEMONIO.instantiate()
	d.especie = _especie_aleatoria()
	d.position = pos
	d.alcance_patrulha = _rng.randf_range(40.0, 90.0)
	# comportamento próprio -- cada bicho uma ameaça (pegada Dead Cells)
	var r := _rng.randf()
	if d.especie == "olho" or d.especie == "abutre":
		if _dif > 0.08 and r < 0.7:
			d.comportamento = "voador"   # o olho e o abutre voam e mergulham
	elif _dif > 0.15 and r < 0.18 + 0.26 * _dif:
		var opcoes := ["saltador", "carga"]
		if _dif > 0.22:
			opcoes.append("cuspidor")
		if _dif > 0.3:
			opcoes.append("trepador")
		if _dif > 0.35:
			opcoes.append("escudeiro")
		var esc: String = opcoes[_rng.randi() % opcoes.size()]
		d.comportamento = esc
		if esc == "trepador":
			d.position.y -= _rng.randf_range(120.0, 170.0)  # colado mais acima
	par.add_child(d)


const ESP_REGIAO := {
	0: ["goblin", "mushroom", "lodo", "besouro", "gosma"],
	1: ["esqueleto", "chort", "orc", "imp", "mastim"],
	2: ["xamane", "wogol", "olho", "abutre", "imp"],
	3: ["esqueleto", "necromante", "chort", "ogro", "gosma"],
	4: ["orc", "abobora", "xamane", "raptor", "mastim"],
	5: ["demonio_grande", "ogro", "chort", "olho", "raptor"],
}

## A "cara" de cada NÍVEL (pedido do Paulo: não repetir o mesmo monstro em
## todos os níveis). Dentro de uma região não há assinaturas repetidas, e as
## 19 espécies aparecem todas ao longo da campanha. É o bicho que mais se vê
## na jornada desse nível; o resto vem da pool da região.
const ESP_ASSINATURA := [
	"goblin", "mushroom", "besouro", "gosma", "lodo",              # I  Floresta
	"esqueleto", "imp", "chort", "mastim", "orc",                  # II Prisão
	"xamane", "abutre", "olho", "wogol", "imp",                    # III Torres
	"necromante", "esqueleto", "gosma", "wogol", "ogro",           # IV Catacumbas
	"abobora", "orc", "mastim", "raptor", "xamane",                # V  Cidade
	"demonio_grande", "chort", "raptor", "ogro", "olho",           # VI Castelo
]


func _especie_aleatoria() -> String:
	var assinatura: String = ESP_ASSINATURA[clampi(_idx, 0, ESP_ASSINATURA.size() - 1)]
	if _rng.randf() < 0.45:
		return assinatura
	var lista: Array = ESP_REGIAO.get(_regiao, [assinatura])
	return lista[_rng.randi() % lista.size()]


## `forcar` ignora o espaçamento mínimo (início da jornada e antes do chefe).
func _checkpoint(x: float, y: float, forcar := false) -> void:
	if not forcar and absf(x - _ultimo_check_x) < DIST_CHECKPOINT:
		return
	_ultimo_check_x = x
	var ck := Area2D.new()
	ck.name = "JornadaCheck_%d" % roundi(x)
	ck.collision_layer = 16
	ck.collision_mask = 2
	ck.position = Vector2(x, y - 46.0)
	var cf := CollisionShape2D.new()
	var rc := RectangleShape2D.new()
	rc.size = Vector2(52.0, 96.0)
	cf.shape = rc
	ck.add_child(cf)
	ck.set_script(CHECKPOINT)
	add_child(ck)


func _especie_do_nivel() -> String:
	for d in get_tree().get_nodes_in_group("inimigos"):
		if "especie" in d:
			return d.especie
	return "goblin"


# --- câmaras de flavour (avançam a espinha) --------------------------------
## Cada uma recebe o (x, y) da última plataforma da espinha e devolve o
## (x, y) da última que ela própria pôs -- a espinha continua daí.

func _flavour(par: Node2D, tipo: String, x: float, y: float) -> Vector2:
	# diagnóstico: `MAPA_CAMARAS=1 godot ...` lista as câmaras geradas em cada
	# nível (usado por tools/mapa_camaras.gd para saber onde ver cada uma).
	if OS.has_environment("MAPA_CAMARAS"):
		print("CAMARA idx=%d tipo=%s x=%.0f" % [_idx, tipo, x])
	match tipo:
		"saltos": return _f_saltos(par, x, y)
		"serras": return _f_serras(par, x, y)
		"pendulos": return _f_pendulos(par, x, y)
		"ritmo": return _f_ritmo(par, x, y)
		"trampolim": return _f_trampolim(par, x, y)
		"gruta": return _f_gruta(par, x, y)
		"quebra": return _f_quebra(par, x, y)
		"correntes": return _f_correntes(par, x, y)
		"elevador": return _f_elevador(par, x, y)
		"vento": return _f_vento(par, x, y)
		"gravidade": return _f_gravidade(par, x, y)
		"guilhotinas": return _f_guilhotinas(par, x, y)
		"fogo": return _f_fogo(par, x, y)
		"impulso": return _f_impulso(par, x, y)
		"portal": return _f_portal(par, x, y)
		"torre": return _f_torre(par, x, y)
		"poco": return _f_poco(par, x, y)
		"pilares": return _f_pilares(par, x, y)
		"descanso": return _f_descanso(par, x, y)
		"forquilha": return _f_forquilha(par, x, y)
		"arena": return _f_arena(par, x, y)
		"corredor": return _f_corredor(par, x, y)
		"cripta": return _f_cripta(par, x, y)
		"crossfire": return _f_crossfire(par, x, y)
		"ferry": return _f_ferry(par, x, y)
		"pedras": return _f_pedras(par, x, y)
		"espinhos": return _f_espinhos(par, x, y)
	# tipo sem handler -> não deve acontecer (pool/assinatura mal configurada).
	# Avisa em vez de gerar um vão morto silencioso e cai num `descanso`.
	push_warning("GeradorCorredor: câmara '%s' sem _f_ correspondente" % tipo)
	return _f_descanso(par, x, y)


## FERRY: um fosso largo sobre o líquido atravessado por UMA plataforma que
## anda sempre de um lado ao outro (`TumuloElevador` com curso horizontal).
## Salta-se para cima dela, atravessa-se em pé a desviar de 2 lâminas
## penduradas a meio, e sai-se do outro lado. O beat "a viagem".
func _f_ferry(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 200.0, _chao_y - 140.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(96.0, 16.0))                 # cais de embarque
	var vao := _rng.randf_range(620.0, 880.0) + 220.0 * _dif
	# a balsa
	var tu := TUMULO.instantiate()
	tu.auto = true
	tu.curso = Vector2(vao, 0.0)
	tu.velocidade = 96.0 + 30.0 * _dif
	tu.largura = 128.0
	tu.position = Vector2(x + 90.0, cy)
	par.add_child(tu)
	# 2 lâminas penduradas a meio do fosso (desviar em pé, agachar não chega)
	for f in 2:
		var px := x + 90.0 + vao * lerpf(0.34, 0.7, float(f))
		var comp := _rng.randf_range(160.0, 210.0)
		var pe := PENDULO.instantiate()
		pe.comprimento = comp
		pe.periodo = _rng.randf_range(1.9, 2.6) - 0.3 * _dif
		pe.amplitude_graus = 44.0 + 18.0 * _dif
		pe.dano = 8 + int(18.0 * _dif)
		pe.fase = 0.5 * float(f)
		pe.position = Vector2(px, cy - comp - 24.0)
		par.add_child(pe)
	_coluna_fundo(par, x + 90.0 + vao * 0.5)
	# cais de desembarque -- sólido e largo
	x += 90.0 + vao + _rng.randf_range(60.0, 96.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## ESPINHOS: o caminho abre em duas calhas até se voltar a juntar. A calha
## BAIXA é um tapete de espinhos (`Espinhos`, grupo "pogavel") -- quem
## domina o POGO (Fase 1) atravessa aos ressaltos; a calha ALTA é uma fila
## de plataformas limpas, o caminho justo. Falhar o pogo custa vida + uma
## queda curta para a plataforma por baixo dos espinhos (não é o líquido).
func _f_espinhos(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 220.0, _chao_y - 150.0)
	var n := 4 + int(_dif * 2.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(104.0, 16.0))          # boca da forquilha
	# calha BAIXA -- tapete de espinhos com uma plataforma por baixo de cada
	var lx := x
	var by := cy + 66.0
	for _i in n:
		lx += _rng.randf_range(122.0, 150.0)
		_plat(par, Vector2(lx, by), Vector2(98.0, 14.0))
		var sp := ESPINHOS.instantiate()
		sp.largura = 6
		sp.position = Vector2(lx, by)
		par.add_child(sp)
	# calha ALTA -- plataformas limpas (o caminho justo). Sobe em degraus
	# que respeitam SUBIDA_MAX (o 1.º salto a partir da boca não pode ser
	# mais que um salto+duplo) até uma altura de cruzeiro sobre os espinhos.
	var hx := x
	var hy := cy
	var hy_alvo: float = maxf(_teto_y + 40.0, cy - _rng.randf_range(150.0, 180.0))
	for _i in n:
		hx += _rng.randf_range(150.0, 176.0)
		hy = maxf(hy_alvo, hy - SUBIDA_MAX)
		_plat(par, Vector2(hx, hy), Vector2(84.0, 15.0))
	# reencontro
	var jx: float = maxf(lx, hx) + _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(jx, cy), Vector2(126.0, 18.0))
	_checkpoint(jx, cy, true)
	return Vector2(jx, cy)


## PEDRAS (assinatura das Catacumbas): corre-se por um beiral sem tecto a
## desviar de uma saraivada de pedras que caem -- umas por proximidade,
## outras em ciclo (ritmo). Nada de tecto baixo (isso é a `gruta`) nem
## parede interior (isso é a `cripta`): é só movimento em frente e leitura
## das que já tremem.
func _f_pedras(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 150.0, _chao_y - 100.0)
	var n := 5 + int(_dif * 3.0)
	for i in n:
		x += _rng.randf_range(150.0, 178.0)
		cy = clampf(cy + _rng.randf_range(-30.0, 30.0), _teto_y + 120.0, _chao_y - 90.0)
		_plat(par, Vector2(x, cy), Vector2(92.0, 16.0))
		var pd := PEDRA.instantiate()
		pd.chao_y = cy - 8.0
		pd.dano = 8 + int(18.0 * _dif)
		if i % 3 == 1:
			pd.automatico = true                       # uma em cada três em ciclo
			pd.periodo = _rng.randf_range(2.4, 3.4) - 0.5 * _dif
			pd.fase = _rng.randf() * 2.0
		else:
			pd.raio_gatilho = 82.0                     # as outras por proximidade
		pd.aviso = 0.6 - 0.2 * _dif
		pd.position = Vector2(x + _rng.randf_range(-16.0, 16.0), cy - _rng.randf_range(150.0, 220.0))
		par.add_child(pd)
		if i % 2 == 0:
			_checkpoint(x, cy)
	x += _rng.randf_range(150.0, 178.0)
	_plat(par, Vector2(x, cy), Vector2(104.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## FOGO CRUZADO: lanço recto de plataformas com torretas montadas em ambos
## os lados a cuspir fogo horizontal ATRAVÉS do caminho, a alturas
## alternadas. Passa-se salto a salto no intervalo dos tiros -- é leitura de
## padrão, não plataforma difícil. Ritmo Dead Cells: pressão à distância.
func _f_crossfire(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 160.0, _chao_y - 150.0)
	var n := 4 + int(_dif * 3.0)
	var x_ini := x
	for i in n:
		x += _rng.randf_range(150.0, 178.0)
		# a espinha desta câmara ondula pouco (o desafio é o fogo, não o salto)
		cy = clampf(cy + _rng.randf_range(-26.0, 26.0), _teto_y + 150.0, _chao_y - 130.0)
		_plat(par, Vector2(x, cy), Vector2(84.0, 16.0))
		# uma torreta por passo, a alternar de lado; dispara na horizontal,
		# a uma altura ligeiramente acima/abaixo da plataforma -> o feixe
		# cruza a linha de salto.
		var esq := i % 2 == 0
		var tr := TORRETA.instantiate()
		tr.direcao = Vector2(1.0 if esq else -1.0, 0.0)
		tr.intervalo = 2.7 - 0.8 * _dif
		tr.telegrafo = 0.6 - 0.18 * _dif
		tr.dano = 6 + int(16.0 * _dif)
		tr.vel_bola = 210.0 + 70.0 * _dif
		tr.fase = 0.5 * float(i)
		tr.position = Vector2(x + (-118.0 if esq else 118.0),
			cy - 30.0 + (18.0 if i % 4 < 2 else -34.0))
		par.add_child(tr)
		if i % 2 == 0:
			_checkpoint(x, cy)
	# saída sólida e limpa (para não cair logo a seguir ao último feixe)
	x += _rng.randf_range(150.0, 180.0)
	_plat(par, Vector2(x, cy), Vector2(104.0, 18.0))
	_checkpoint(x, cy)
	_coluna_fundo(par, (x_ini + x) * 0.5)
	return Vector2(x, cy)


## CRIPTA: sala fechada com uma parede interior baixa a saltar por cima (ou
## contornar pela plataforma alta) + pedras que caem. Navegação vertical curta.
func _f_cripta(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 150.0, _chao_y - 96.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x + 130.0, cy), Vector2(280.0, 22.0), 42.0)          # chão da sala
	_plat(par, Vector2(x + 130.0, cy - 40.0), Vector2(24.0, 64.0))          # parede interior baixa
	_plat(par, Vector2(x + 130.0, cy - 104.0), Vector2(92.0, 16.0))         # rota alta alternativa
	for i in 2:
		var pd := PEDRA.instantiate()
		pd.chao_y = cy - 8.0
		pd.dano = 8 + int(16.0 * _dif)
		pd.raio_gatilho = 78.0
		pd.position = Vector2(x + 70.0 + 120.0 * float(i), cy - 130.0)
		par.add_child(pd)
	_checkpoint(x + 40.0, cy, true)
	if _dif > 0.2:
		_inimigo_em(par, Vector2(x + 224.0, cy - 30.0))
	x += 280.0 + _rng.randf_range(150.0, 176.0)
	var ny: float = maxf(_teto_y + 40.0, cy - _rng.randf_range(-30.0, SUBIDA_MAX))
	_plat(par, Vector2(x, ny), Vector2(100.0, 18.0))
	return Vector2(x, ny)


## ARENA de combate: chão sólido largo por cima do líquido, vários inimigos
## (comportamentos variados), checkpoint. "Limpa a sala" -- ritmo Dead Cells.
func _f_arena(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 120.0, _chao_y - 88.0)
	x += _rng.randf_range(150.0, 178.0)
	var larg := _rng.randf_range(430.0, 560.0)
	_plat(par, Vector2(x + larg * 0.5, cy), Vector2(larg, 26.0), 48.0)
	_coluna_fundo(par, x + 40.0)
	_coluna_fundo(par, x + larg - 40.0)
	_checkpoint(x + 44.0, cy, true)
	var n := 3 + int(_dif * 3.0)
	for i in n:
		var ex := x + 80.0 + (larg - 160.0) * (float(i) / float(maxi(1, n - 1)))
		_inimigo_em(par, Vector2(ex, cy - 30.0))
	x += larg + _rng.randf_range(148.0, 176.0)
	var ny: float = maxf(_teto_y + 40.0, cy - _rng.randf_range(-40.0, SUBIDA_MAX))
	_plat(par, Vector2(x, ny), Vector2(104.0, 18.0))
	_checkpoint(x, ny)
	return Vector2(x, ny)


## CORREDOR apertado: tecto baixo (bater com a cabeça se saltar) + serras em
## calha no ritmo. Passa-se a correr/rolar, não a saltar.
func _f_corredor(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _chao_y - 260.0, _chao_y - 120.0)
	var n := 4 + int(_dif * 3.0)
	for i in n:
		x += _rng.randf_range(150.0, 176.0)
		_plat(par, Vector2(x, cy), Vector2(96.0, 16.0))
		_plat(par, Vector2(x, cy - 96.0), Vector2(120.0, 22.0))   # tecto baixo
		var s := SERRA.instantiate()
		s.position = Vector2(x - 84.0, cy - _rng.randf_range(40.0, 62.0))
		s.percurso = Vector2(150.0, 0.0)
		s.tempo = _rng.randf_range(1.1, 1.7)
		par.add_child(s)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## --- ritmo: alívio e bifurcação -----------------------------------------

## ALÍVIO: plataforma larga e LIMPA (zero perigos), checkpoint garantido e
## um pouco de vista (colunas ao fundo). O respiro entre gauntlets.
func _f_descanso(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 90.0, _chao_y - 88.0)
	x += _rng.randf_range(150.0, 182.0)
	_plat(par, Vector2(x + 150.0, cy), Vector2(330.0, 24.0), 44.0)
	_checkpoint(x + 40.0, cy, true)
	_coluna_fundo(par, x + 70.0)
	_coluna_fundo(par, x + 240.0)
	x += 330.0
	return Vector2(x, cy)


## FORQUILHA: o caminho abre em dois e volta a juntar-se. Rota ALTA curta e
## com perigos; rota BAIXA mais longa e segura. Ambas as pontas alcançam o
## reencontro (de cima desce-se; de baixo é <= um salto).
func _f_forquilha(par: Node2D, x: float, y: float) -> Vector2:
	var passo := _rng.randf_range(156.0, 176.0)
	var n := 3
	_plat(par, Vector2(x + 60.0, y), Vector2(120.0, 18.0))  # partida à altura da espinha
	var bx := x + 60.0
	var hy := y
	for i in n:
		hy = maxf(_teto_y + 40.0, hy - _rng.randf_range(72.0, SUBIDA_MAX))
		_plat(par, Vector2(bx + passo * float(i + 1), hy), Vector2(72.0, 15.0))
		if i < n - 1 and _rng.randf() < 0.5 + 0.3 * _dif:
			_perigo_no_vao(par, bx + passo * float(i + 1), hy)
	var ly: float = minf(y + 190.0, _chao_y - 82.0)
	for i in n:
		_plat(par, Vector2(bx + passo * float(i + 1), ly), Vector2(90.0, 16.0))
	var jx := bx + passo * float(n + 1)
	var jy: float = clampf(hy + 90.0, ly - 96.0, ly - 40.0)
	_plat(par, Vector2(jx, jy), Vector2(130.0, 18.0))
	_checkpoint(jx, jy)
	return Vector2(jx, jy)


## --- câmaras VERTICAIS (dão altura a sério à jornada) ---------------------

## Torre: subida em ziguezague apertado que ganha MUITA altura (net
## +700..+1200). Δx pequeno, Δy = sempre <= um salto.
func _f_torre(par: Node2D, x: float, y: float) -> Vector2:
	var n := 7 + int(_dif * 5.0)
	var cy := y
	for i in n:
		x += _rng.randf_range(62.0, 106.0)
		cy = maxf(_teto_y, cy - _rng.randf_range(84.0, SUBIDA_MAX))
		_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(58.0, 80.0), 16.0))
		if i > 0 and i < n - 1 and _rng.randf() < 0.16 + 0.4 * _dif:
			_perigo_no_vao(par, x, cy)
		if i % 3 == 0:
			_coluna_fundo(par, x + _rng.randf_range(-90.0, 90.0))
		if cy <= _teto_y + 12.0:
			break
	_checkpoint(x, cy)
	x += _rng.randf_range(140.0, 178.0)
	_plat(par, Vector2(x, cy), Vector2(104.0, 18.0))  # varanda do topo
	return Vector2(x, cy)


## Poço: desce por um funil até rente ao líquido mortal, checkpoint no
## fundo, e volta a subir pela parede oposta. Tenso.
func _f_poco(par: Node2D, x: float, y: float) -> Vector2:
	var fundo_y := _chao_y - 82.0
	var cy := y
	for _i in 4:
		x += _rng.randf_range(118.0, 156.0)
		cy = minf(fundo_y, cy + _rng.randf_range(150.0, 240.0))
		_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(70.0, 96.0), 16.0))
	_checkpoint(x, cy)
	if _rng.randf() < 0.5 + 0.4 * _dif:
		_perigo_no_vao(par, x, cy)
	var alvo := maxf(_teto_y + 120.0, y - _rng.randf_range(140.0, 380.0))
	for _i in 6:
		x += _rng.randf_range(70.0, 116.0)
		cy = maxf(alvo, cy - _rng.randf_range(86.0, SUBIDA_MAX))
		_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(58.0, 80.0), 16.0))
		if cy <= alvo + 6.0:
			break
	x += _rng.randf_range(148.0, 182.0)
	_plat(par, Vector2(x, cy), Vector2(100.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## Pilares: colunas altas (SÓ VISUAIS -- nunca colidem, senão cortavam o
## caminho) com uma plataforma SÓLIDA no cimo; salta-se de topo em topo com
## o vazio lá em baixo.
func _f_pilares(par: Node2D, x: float, y: float) -> Vector2:
	var n := 3 + _rng.randi() % 3
	var cy := y
	for i in n:
		x += _rng.randf_range(150.0, 184.0)
		cy = clampf(cy - _rng.randf_range(-96.0, SUBIDA_MAX), _teto_y + 40.0, _chao_y - 150.0)
		_coluna_fundo(par, x)  # o "pilar" é só um sprite de fundo, não bloqueia
		_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(74.0, 100.0), 16.0))  # o topo (sólido)
		if i > 0 and _rng.randf() < 0.24 + 0.36 * _dif:
			_perigo_no_vao(par, x, cy)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## Salta-plataformas em ziguezague apertado (sobe e desce muito).
func _f_saltos(par: Node2D, x: float, y: float) -> Vector2:
	var n := 5 + int(_dif * 3.0)
	var cy := y
	for i in n:
		x += _rng.randf_range(158.0, 190.0)
		var d := _rng.randf_range(-140.0, 96.0)
		cy = clampf(cy - d, _chao_y - 470.0, _chao_y - 70.0)
		var quebra := i > 0 and i < n - 1 and _rng.randf() < 0.12 + 0.28 * _dif
		if quebra:
			var q := PLAT_QUEBRA.instantiate()
			q.tamanho = Vector2(78.0, 16.0)
			q.position = Vector2(x, cy)
			par.add_child(q)
		else:
			_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(64.0, 88.0), 16.0))
		if _rng.randf() < 0.08 + 0.42 * _dif:
			_perigo_no_vao(par, x, cy)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## Corredor de serras: plataformas com serras horizontais em calha por baixo
## e por cima -- passa-se a saltar no ritmo.
func _f_serras(par: Node2D, x: float, y: float) -> Vector2:
	var n := 4 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 300.0, _chao_y - 150.0)
	for i in n:
		x += _rng.randf_range(170.0, 200.0)
		_plat(par, Vector2(x, cy), Vector2(84.0, 16.0))
		var s := SERRA.instantiate()
		s.position = Vector2(x - 90.0, cy - _rng.randf_range(38.0, 58.0))
		s.percurso = Vector2(150.0, 0.0)
		s.tempo = _rng.randf_range(1.2, 1.8)
		par.add_child(s)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_pendulos(par: Node2D, x: float, y: float) -> Vector2:
	var n := 4 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 320.0, _chao_y - 130.0)
	for i in n:
		x += _rng.randf_range(150.0, 178.0)
		_plat(par, Vector2(x, cy), Vector2(72.0, 16.0))
		var comp := _rng.randf_range(170.0, 230.0)
		var pe := PENDULO.instantiate()
		pe.comprimento = comp
		pe.periodo = _rng.randf_range(1.8, 2.6) - 0.3 * _dif
		pe.amplitude_graus = 48.0 + 18.0 * _dif
		pe.dano = 8 + int(20.0 * _dif)
		pe.fase = float(i) / float(n)
		pe.position = Vector2(x + 82.0, cy - comp - 26.0)
		par.add_child(pe)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## Plataformas rítmicas (aparecem/somem) -- tem de se ir sem parar.
func _f_ritmo(par: Node2D, x: float, y: float) -> Vector2:
	var n := 5 + int(_dif * 3.0)
	var cy := clampf(y, _chao_y - 360.0, _chao_y - 140.0)
	# plataforma fixa de partida
	_plat(par, Vector2(x + 90.0, cy), Vector2(80.0, 16.0))
	x += 90.0
	for i in n:
		x += _rng.randf_range(150.0, 176.0)
		cy = clampf(cy - _rng.randf_range(-90.0, 80.0), _chao_y - 420.0, _chao_y - 110.0)
		var pr := PLAT_RITMO.instantiate()
		pr.tamanho = Vector2(88.0, 16.0)
		pr.periodo = _rng.randf_range(2.0, 2.8)
		pr.fase = fmod(0.28 * float(i), 1.0)
		pr.position = Vector2(x, cy)
		par.add_child(pr)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_trampolim(par: Node2D, x: float, y: float) -> Vector2:
	var cy := y
	for i in 3:
		x += _rng.randf_range(150.0, 175.0)
		cy = clampf(cy + 40.0, _chao_y - 200.0, _chao_y - 70.0)  # desce um pouco
		_plat(par, Vector2(x, cy), Vector2(84.0, 16.0))
		var tr := TRAMPOLIM.instantiate()
		tr.impulso = 680.0 + 30.0 * float(i)
		tr.position = Vector2(x, cy - 18.0)
		par.add_child(tr)
		# plataforma alta de aterragem
		x += _rng.randf_range(150.0, 180.0)
		cy = clampf(cy - _rng.randf_range(150.0, 210.0), _chao_y - 480.0, _chao_y - 120.0)
		_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## Gruta apertada: tecto baixo, tem de se descer para um túnel e voltar a
## subir; estalactites que caem.
func _f_gruta(par: Node2D, x: float, y: float) -> Vector2:
	var cy := y
	# desce ao túnel
	x += 165.0; cy = clampf(cy + 130.0, _chao_y - 160.0, _chao_y - 74.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	_plat(par, Vector2(x, cy - 90.0), Vector2(150.0, 26.0))   # tecto do túnel
	for i in 3:
		x += _rng.randf_range(150.0, 172.0)
		_plat(par, Vector2(x, cy), Vector2(80.0, 16.0))
		_plat(par, Vector2(x, cy - 88.0), Vector2(120.0, 24.0))  # tecto
		var pd := PEDRA.instantiate()
		pd.chao_y = _chao_y
		pd.dano = 8 + int(18.0 * _dif)
		pd.raio_gatilho = 70.0
		pd.position = Vector2(x, cy - 78.0)
		par.add_child(pd)
	_checkpoint(x, cy)
	# volta a subir
	x += 165.0; cy = clampf(cy - 120.0, _chao_y - 300.0, _chao_y - 120.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	return Vector2(x, cy)


func _f_quebra(par: Node2D, x: float, y: float) -> Vector2:
	var n := 6 + int(_dif * 4.0)
	var cy := clampf(y, _chao_y - 300.0, _chao_y - 130.0)
	_plat(par, Vector2(x + 80.0, cy), Vector2(70.0, 16.0))
	x += 80.0
	for i in n:
		x += _rng.randf_range(140.0, 168.0)
		cy = clampf(cy - _rng.randf_range(-70.0, 60.0), _chao_y - 380.0, _chao_y - 110.0)
		var q := PLAT_QUEBRA.instantiate()
		q.tamanho = Vector2(92.0, 16.0)
		q.atraso = 0.72 - 0.3 * _dif
		q.position = Vector2(x, cy)
		par.add_child(q)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_correntes(par: Node2D, x: float, y: float) -> Vector2:
	var n := 3 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 260.0, _chao_y - 150.0)
	for i in n:
		x += _rng.randf_range(175.0, 205.0)
		var pc := PLAT_CORRENTE.instantiate()
		pc.modo = "pendulo" if i % 2 == 0 else "vertical"
		pc.amplitude = 26.0 if pc.modo == "pendulo" else _rng.randf_range(50.0, 80.0)
		pc.periodo = _rng.randf_range(2.4, 3.2)
		pc.fase = _rng.randf_range(0.0, 2.0)
		pc.comprimento = _rng.randf_range(110.0, 160.0)
		pc.largura = 110.0
		pc.position = Vector2(x, cy)
		par.add_child(pc)
		if i % 2 == 0:
			_checkpoint(x, cy)
	x += _rng.randf_range(175.0, 200.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	return Vector2(x, cy)


func _f_elevador(par: Node2D, x: float, y: float) -> Vector2:
	var cy := clampf(y, _chao_y - 160.0, _chao_y - 90.0)
	for i in 3:
		x += _rng.randf_range(180.0, 210.0)
		var tu := TUMULO.instantiate()
		tu.curso = Vector2(0.0, -_rng.randf_range(160.0, 260.0))
		tu.velocidade = _rng.randf_range(70.0, 100.0)
		tu.auto = true
		tu.largura = 120.0
		tu.position = Vector2(x, cy)
		par.add_child(tu)
		_plat(par, Vector2(x + 100.0, cy - _rng.randf_range(150.0, 240.0)), Vector2(90.0, 16.0))
	x += 150.0
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_vento(par: Node2D, x: float, y: float) -> Vector2:
	x += 150.0
	var cy := clampf(y, _chao_y - 140.0, _chao_y - 80.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	var ca := CORRENTE_AR.instantiate()
	ca.position = Vector2(x + 150.0, cy - 240.0)
	ca.scale = Vector2(3.2, 5.0)
	par.add_child(ca)
	# plataformas empilhadas para lá da coluna
	for i in 4:
		_plat(par, Vector2(x + 110.0 + float(i % 2) * 150.0, cy - 100.0 - float(i) * 105.0), Vector2(96.0, 16.0))
	x += 340.0
	cy = clampf(cy - 300.0, _chao_y - 460.0, _chao_y - 160.0)
	_plat(par, Vector2(x, cy), Vector2(100.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_gravidade(par: Node2D, x: float, y: float) -> Vector2:
	var n := 4 + int(_dif * 2.0)
	var cy := y
	var zg := ZONA_GRAV.instantiate()
	if zg.get_node_or_null("Col") == null:
		var cs := CollisionShape2D.new()
		cs.name = "Col"
		var r := RectangleShape2D.new()
		r.size = Vector2(n * 240.0, 560.0)
		cs.shape = r
		zg.add_child(cs)
	zg.escala = 0.4
	zg.position = Vector2(x + n * 120.0, _chao_y - 280.0)
	par.add_child(zg)
	for i in n:
		x += _rng.randf_range(200.0, 250.0)   # gaps maiores (grav lunar)
		cy = clampf(cy - _rng.randf_range(-180.0, 150.0), _chao_y - 470.0, _chao_y - 90.0)
		_plat(par, Vector2(x, cy), Vector2(74.0, 16.0))
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_guilhotinas(par: Node2D, x: float, y: float) -> Vector2:
	var n := 3 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 280.0, _chao_y - 150.0)
	for i in n:
		x += _rng.randf_range(160.0, 186.0)
		_plat(par, Vector2(x, cy), Vector2(86.0, 16.0))
		var g := GUILHOTINA.instantiate()
		g.automatico = true
		g.periodo = _rng.randf_range(2.0, 2.8) - 0.4 * _dif
		g.atraso = 0.72 - 0.28 * _dif
		g.fase = 0.5 * float(i)
		g.altura_queda = 190.0
		g.dano = 10 + int(20.0 * _dif)
		g.position = Vector2(x + 90.0, cy - 210.0)
		par.add_child(g)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_fogo(par: Node2D, x: float, y: float) -> Vector2:
	var n := 4 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 260.0, _chao_y - 130.0)
	for i in n:
		x += _rng.randf_range(158.0, 184.0)
		_plat(par, Vector2(x, cy), Vector2(84.0, 16.0))
		var f := FOGO.instantiate()
		f.position = Vector2(x, cy + 4.0)
		f.intervalo = 1.9 - 0.4 * _dif
		f.dur_ativa = 1.0 + 0.4 * _dif
		f.fase = 0.5 * float(i)
		par.add_child(f)
		if i == n / 2:
			var tr := TORRETA.instantiate()
			tr.direcao = Vector2(-1.0, 0.0)
			tr.intervalo = 2.9 - 0.7 * _dif
			tr.dano = 6 + int(16.0 * _dif)
			tr.position = Vector2(x + 120.0, cy - 40.0)
			par.add_child(tr)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_impulso(par: Node2D, x: float, y: float) -> Vector2:
	var cy := clampf(y, _chao_y - 300.0, _chao_y - 150.0)
	_plat(par, Vector2(x + 90.0, cy), Vector2(90.0, 16.0))
	var imp := IMPULSOR.instantiate()
	imp.direcao = 1.0
	imp.vel_alvo = 440.0 + 60.0 * _dif
	imp.largura = 620.0
	imp.altura = 130.0
	imp.position = Vector2(x + 90.0 + 340.0, cy)
	par.add_child(imp)
	# ilhotas no meio da rajada
	_plat(par, Vector2(x + 90.0 + 260.0, cy), Vector2(60.0, 14.0))
	_plat(par, Vector2(x + 90.0 + 440.0, cy), Vector2(60.0, 14.0))
	x += 90.0 + 640.0
	_plat(par, Vector2(x, cy), Vector2(100.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## Fosso mais largo com DUAS rotas: plataformas suspensas OU um par de
## portais (entrada no caminho, saída em plataforma sólida do outro lado).
func _f_portal(par: Node2D, x: float, y: float) -> Vector2:
	var cy := clampf(y, _chao_y - 240.0, _chao_y - 140.0)
	_plat(par, Vector2(x + 70.0, cy), Vector2(80.0, 16.0))
	var idp := "jorn_%d" % _cont_i
	var pa := PORTAL.instantiate()
	pa.id = idp + "_a"
	pa.destino_id = idp + "_b"
	pa.position = Vector2(x + 70.0, cy - 28.0)
	par.add_child(pa)
	# rota de plataformas suspensas (Δx ~180)
	for i in 3:
		x += _rng.randf_range(168.0, 190.0)
		_plat(par, Vector2(x, cy - _rng.randf_range(-30.0, 40.0)), Vector2(70.0, 14.0))
		if _rng.randf() < 0.1 + 0.5 * _dif:
			_perigo_no_vao(par, x, cy)
	x += _rng.randf_range(168.0, 190.0)
	_plat(par, Vector2(x, cy), Vector2(100.0, 16.0))
	var pb := PORTAL.instantiate()
	pb.id = idp + "_b"
	pb.destino_id = idp + "_a"
	pb.so_saida = true
	pb.position = Vector2(x, cy - 28.0)
	par.add_child(pb)
	_checkpoint(x, cy)
	return Vector2(x, cy)
