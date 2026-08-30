class_name GeradorCorredor
extends Node2D
## JORNADA -- constrói a maior parte de cada nível: um percurso LONGO e denso
## à esquerda do sítio onde a Koliani nasce, cheio de plataformas (fixas,
## móveis, rítmicas, de corrente, que esboroam, trampolins, elevadores,
## rajadas, bolsas de gravidade lunar) e de perigos. O chefe fica SEMPRE no
## fim, na geometria feita à mão. Cresce com o número do nível; o tema
## (mistura de câmaras) vem da REGIÃO.
##
## Regras anti-softlock (isto já esteve desligado por causa disso):
##  - há SEMPRE um chão raso contínuo por baixo de tudo -- cair nunca mata
##    nem prende; as plataformas altas são o desafio, o chão é a rede;
##  - nada BLOQUEIA a passagem -- os perigos só magoam e ciclam; sem portas
##    nem alavancas;
##  - todas as subidas têm degraus/rota alternativa (o salto duplo e, se a
##    tiver, o escalar-paredes, chegam sempre);
##  - portais só levam ao parceiro, com chegada em chão sólido.
## É ADITIVO. `corredor = false` na cena raiz desliga (o último nível nunca
## o tem).

@export var comprimento_base := 15000.0
@export var por_nivel := 640.0
@export var comprimento_max := 34000.0
@export var especie_inimigo := ""
## Reposiciona a Koliani no início (só numa entrada fresca -- ver
## `nivel_com_chefe.gd`).
@export var entrada_fresca := true
## Desliga a otimização de visibilidade (bots de teste).
@export var otimizar_visibilidade := true

const LARG := 1250.0
const TETO := 560.0   # altura útil de plataformas acima do chão

const PLAT := preload("res://scenes/actors/Plataforma.tscn")
const ESPINHOS := preload("res://scenes/actors/Espinhos.tscn")
const DEMONIO := preload("res://scenes/actors/DemonioBase.tscn")
const SERRA := preload("res://scenes/actors/Serra.tscn")
const FOGO := preload("res://scenes/actors/Fogo.tscn")
const GUILHOTINA := preload("res://scenes/actors/Guilhotina.tscn")
const TORRETA := preload("res://scenes/actors/Torreta.tscn")
const PAREDE_MOVEL := preload("res://scenes/actors/ParedeMovel.tscn")
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
const CHECKPOINT := preload("res://scripts/checkpoint.gd")

## Câmaras possíveis por região (índice de `EstadoJogo.REGIOES`).
const POOL_REGIAO := {
	0: ["escadaria", "saltos_altos", "ritmadas", "trampolins", "serras", "pendulos", "gruta", "portal", "quebra_ponte"],
	1: ["escadaria", "correntes_v", "elevadores", "quebra_ponte", "guilhotinas", "prensa", "serras", "portal", "gruta"],
	2: ["torre_vento", "saltos_altos", "gravidade", "impulso", "trampolins", "pendulos", "ritmadas", "portal", "escadaria"],
	3: ["gruta", "pedras", "elevadores", "quebra_ponte", "guilhotinas", "pendulos", "saltos_altos", "portal", "escadaria"],
	4: ["escadaria", "impulso", "correntes_v", "serras", "prensa", "fogo", "trampolins", "portal", "guilhotinas"],
	5: ["pendulos", "fogo", "guilhotinas", "ritmadas", "quebra_ponte", "gravidade", "impulso", "prensa", "portal", "escadaria"],
}
## Progresso mínimo (0..1 ao longo da jornada) a que cada tipo pode aparecer.
const MIN_P := {
	"escadaria": 0.0, "saltos_altos": 0.04, "serras": 0.0, "trampolins": 0.06,
	"ritmadas": 0.1, "gruta": 0.08, "portal": 0.12, "quebra_ponte": 0.14,
	"pendulos": 0.16, "correntes_v": 0.12, "elevadores": 0.1, "guilhotinas": 0.2,
	"torre_vento": 0.08, "impulso": 0.14, "gravidade": 0.18, "fogo": 0.26, "pedras": 0.24, "prensa": 0.34,
}

var _chao_y := 0.0
var _idx := 0
var _dif := 0.0
var _regiao := 0
var _esp := "goblin"
var _n := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	call_deferred("_construir")


func _construir() -> void:
	var kol := get_tree().get_first_node_in_group("koliani")
	if kol == null:
		return
	_idx = EstadoJogo.indice_nivel
	_dif = clampf(float(_idx) / 29.0, 0.0, 1.0)
	_regiao = maxi(0, EstadoJogo.regiao_atual())
	_rng.seed = hash("jornada2|%d" % _idx)
	_esp = especie_inimigo if especie_inimigo != "" else _especie_do_nivel()

	var ancora: Vector2 = EstadoJogo.jornada_ancora_para(
		_idx, func() -> Vector2: return (kol as Node2D).global_position)
	_chao_y = ancora.y + 76.0

	var comp: float = clampf(comprimento_base + por_nivel * float(_idx),
		comprimento_base, comprimento_max)
	var n_cam := maxi(3, int(round(comp / LARG)))
	comp = float(n_cam) * LARG
	var x0 := ancora.x - comp

	# --- geometria SEMPRE ativa -----------------------------------------
	var chao := PLAT.instantiate()
	add_child(chao)
	chao.position = Vector2((x0 + ancora.x) * 0.5, _chao_y + 26.0)
	chao.tamanho = Vector2(ancora.x - x0 + 520.0, 52.0)
	chao.altura_visual = 120.0

	var fundo := PLAT.instantiate()
	add_child(fundo)
	fundo.position = Vector2(x0 - 40.0, _chao_y - 260.0)
	fundo.tamanho = Vector2(72.0, 640.0)

	var casca := get_parent().get_node_or_null("Casca")
	if casca and casca.has_method("abrir_esquerda"):
		casca.abrir_esquerda(x0 - 160.0)

	var atm := get_tree().get_first_node_in_group("atmosfera")
	if atm and "largura_nivel" in atm:
		atm.largura_nivel = maxf(atm.largura_nivel, comp + 3000.0)

	if entrada_fresca:
		var inicio := Vector2(x0 + 90.0, _chao_y - 70.0)
		(kol as Node2D).global_position = inicio
		if "velocity" in kol:
			kol.velocity = Vector2.ZERO
		kol.set("_pos_inicial", inicio)
		EstadoJogo.definir_checkpoint(inicio)

	_checkpoint(x0 + 150.0)

	# ponte lisa a ligar o fim da jornada à geometria feita à mão (sem
	# ressaltos no seam, seja qual for a altura do chão do nível)
	var ponte := PLAT.instantiate()
	add_child(ponte)
	ponte.position = Vector2(ancora.x - 40.0, _chao_y + 26.0)
	ponte.tamanho = Vector2(700.0, 52.0)
	ponte.altura_visual = 120.0

	# --- câmaras ------------------------------------------------------
	var ant := ""
	for c in n_cam:
		_n = c
		var cx0 := x0 + float(c) * LARG
		var p := float(c) / float(maxi(1, n_cam - 1))
		# a última câmara é um corredor liso -- chega-se ao nível descansado
		if c == n_cam - 1:
			_c_plano(_container(cx0), cx0)
			_checkpoint(cx0 + 40.0)
			continue
		var t := _escolher(ant, p)
		ant = t
		var par := _container(cx0)
		match t:
			"escadaria": _c_escadaria(par, cx0)
			"saltos_altos": _c_saltos_altos(par, cx0)
			"ritmadas": _c_ritmadas(par, cx0)
			"trampolins": _c_trampolins(par, cx0)
			"correntes_v": _c_correntes(par, cx0)
			"elevadores": _c_elevadores(par, cx0)
			"quebra_ponte": _c_quebra_ponte(par, cx0)
			"torre_vento": _c_torre_vento(par, cx0)
			"impulso": _c_impulso(par, cx0)
			"gravidade": _c_gravidade(par, cx0)
			"serras": _c_serras(par, cx0)
			"guilhotinas": _c_guilhotinas(par, cx0)
			"fogo": _c_fogo(par, cx0)
			"pendulos": _c_pendulos(par, cx0)
			"gruta": _c_gruta(par, cx0)
			"prensa": _c_prensa(par, cx0)
			"pedras": _c_pedras(par, cx0)
			"portal": _c_portal(par, cx0)
			_: _c_escadaria(par, cx0)
		_checkpoint(cx0 + 40.0)


func _escolher(ant: String, p: float) -> String:
	var base: Array = POOL_REGIAO.get(_regiao, POOL_REGIAO[0])
	var pool: Array = []
	for t: String in base:
		if p + _dif * 0.25 >= float(MIN_P.get(t, 0.0)):
			pool.append(t)
	pool = pool.filter(func(x: String) -> bool: return x != ant)
	if pool.is_empty():
		return "escadaria"
	return pool[_rng.randi() % pool.size()]


# --- infra --------------------------------------------------------------

func _container(cx0: float) -> Node2D:
	var c := Node2D.new()
	c.name = "Cam_%d" % _n
	add_child(c)
	if otimizar_visibilidade and DisplayServer.get_name() != "headless":
		var en := VisibleOnScreenEnabler2D.new()
		en.process_mode = Node.PROCESS_MODE_ALWAYS
		en.rect = Rect2(cx0 - 700.0, _chao_y - TETO - 400.0, LARG + 1400.0, TETO + 900.0)
		c.add_child(en)
	return c


func _plat(par: Node2D, pos: Vector2, tam: Vector2, alt_vis := 0.0) -> void:
	var p := PLAT.instantiate()
	p.position = pos
	p.tamanho = tam
	if alt_vis > 0.0:
		p.altura_visual = alt_vis
	par.add_child(p)


## Uma escada de plataformas pequenas: `n` degraus de (dx, -dy) a partir de
## (x, y). Devolve o topo.
func _escada(par: Node2D, x: float, y: float, n: int, dx: float, dy: float, w := 92.0) -> Vector2:
	var px := x
	var py := y
	for i in n:
		_plat(par, Vector2(px, py), Vector2(w, 18.0))
		px += dx
		py -= dy
	return Vector2(px - dx, py + dy)


func _flut(par: Node2D, pos: Vector2, w := 120.0, deriva := 0.0, balanco := 10.0) -> void:
	var pf := PLAT_FLUT.instantiate()
	pf.largura = w
	pf.balanco = balanco
	pf.periodo = _rng.randf_range(2.2, 3.4)
	pf.deriva = deriva
	pf.periodo_deriva = _rng.randf_range(3.2, 4.8)
	pf.fase = _rng.randf_range(0.0, 2.0)
	pf.position = pos
	par.add_child(pf)


func _espinhos(par: Node2D, x: float, largura: int, y := 0.0) -> void:
	var e := ESPINHOS.instantiate()
	e.position = Vector2(x, _chao_y + y)
	e.largura = maxi(1, largura)
	e.dano = 14 + int(10.0 * _dif)
	par.add_child(e)


## Serra rasteira a varrer o meio do chão -- ameaça quem CAIR das plataformas
## (as pontas ficam livres para sair a pé).
func _saw_rede(par: Node2D, cx0: float) -> void:
	var s := SERRA.instantiate()
	s.position = Vector2(cx0 + 220.0, _chao_y - 22.0)
	s.percurso = Vector2(LARG * 0.55, 0.0)
	s.tempo = _rng.randf_range(2.2, 3.2)
	par.add_child(s)


## Espécies (arte LuizMelo CC0) que aparecem na jornada de cada região --
## mais variedade do que só a do nível.
const ESP_REGIAO := {
	0: ["goblin", "mushroom"],
	1: ["esqueleto", "goblin"],
	2: ["olho", "goblin"],
	3: ["esqueleto", "olho"],
	4: ["goblin", "esqueleto"],
	5: ["olho", "esqueleto", "goblin"],
}


func _inimigos(par: Node2D, cx0: float, quantos: int, y := -46.0) -> void:
	var especies: Array = ESP_REGIAO.get(_regiao, [_esp])
	for i in clampi(quantos, 0, 4):
		var d := DEMONIO.instantiate()
		d.especie = _esp if _rng.randf() < 0.4 else especies[_rng.randi() % especies.size()]
		d.position = Vector2(cx0 + _rng.randf_range(260.0, LARG - 300.0), _chao_y + y)
		d.alcance_patrulha = _rng.randf_range(80.0, 170.0)
		par.add_child(d)


func _checkpoint(x: float) -> void:
	var ck := Area2D.new()
	ck.name = "JornadaCheck_%d" % roundi(x)
	ck.collision_layer = 16
	ck.collision_mask = 2
	ck.position = Vector2(x, _chao_y - 46.0)
	var cf := CollisionShape2D.new()
	var rc := RectangleShape2D.new()
	rc.size = Vector2(44.0, 92.0)
	cf.shape = rc
	ck.add_child(cf)
	ck.set_script(CHECKPOINT)
	add_child(ck)


func _especie_do_nivel() -> String:
	for d in get_tree().get_nodes_in_group("inimigos"):
		if "especie" in d:
			return d.especie
	return "goblin"


# --- câmaras: plataforma pura ----------------------------------------------

## Escadaria em ziguezague: sobe ~360 px por degraus, corre um terraço alto,
## e volta a descer. Um par de plataformas flutuantes no terraço.
func _c_escadaria(par: Node2D, cx0: float) -> void:
	var topo := _escada(par, cx0 + 140.0, _chao_y - 40.0, 6, 90.0, 62.0)
	# terraço
	_plat(par, Vector2(topo.x + 120.0, topo.y - 10.0), Vector2(200.0, 18.0))
	_flut(par, Vector2(topo.x + 330.0, topo.y - 30.0), 110.0, 70.0)
	_plat(par, Vector2(topo.x + 540.0, topo.y - 4.0), Vector2(150.0, 18.0))
	# descida
	_escada(par, topo.x + 700.0, topo.y + 20.0, 6, 78.0, -58.0)
	if _rng.randf() < 0.5:
		_espinhos(par, cx0 + LARG * 0.5, 3 + int(2.0 * _dif))
	_inimigos(par, cx0, 1 + int(_dif))


## Campo de plataformas pequenas a alturas variadas sobre um vão. Serra-rede
## no chão + algumas plataformas que esboroam.
func _c_saltos_altos(par: Node2D, cx0: float) -> void:
	_saw_rede(par, cx0)
	var n := 8 + int(round(_dif * 6.0))
	var px := cx0 + 120.0
	for i in n:
		var y := _chao_y - _rng.randf_range(120.0, 300.0)
		if i > 1 and i < n - 1 and _rng.randf() < 0.28 + 0.2 * _dif:
			var q := PLAT_QUEBRA.instantiate()
			q.tamanho = Vector2(84.0, 16.0)
			q.position = Vector2(px, y)
			par.add_child(q)
		else:
			_plat(par, Vector2(px, y), Vector2(_rng.randf_range(74.0, 104.0), 16.0))
		px += (LARG - 220.0) / float(n)
	if _dif > 0.25:
		_flut(par, Vector2(cx0 + LARG * 0.5, _chao_y - 350.0), 120.0, 120.0)
	_inimigos(par, cx0, 1 + int(_dif))


## Duas fileiras de plataformas rítmicas (aparecem/desaparecem), desfasadas.
func _c_ritmadas(par: Node2D, cx0: float) -> void:
	for fila in 2:
		var y := _chao_y - (150.0 if fila == 0 else 280.0)
		var n := 5 + int(_dif * 3.0)
		for i in n:
			var pr := PLAT_RITMO.instantiate()
			pr.tamanho = Vector2(96.0, 18.0)
			pr.periodo = _rng.randf_range(2.0, 3.0)
			pr.fase = fmod(0.16 * float(i) + 0.5 * float(fila), 1.0)
			pr.position = Vector2(cx0 + 140.0 + float(i) * ((LARG - 260.0) / float(n)), y)
			par.add_child(pr)
	# plataformas fixas de refúgio no início e no fim
	_plat(par, Vector2(cx0 + 90.0, _chao_y - 150.0), Vector2(96.0, 18.0))
	_plat(par, Vector2(cx0 + LARG - 90.0, _chao_y - 150.0), Vector2(96.0, 18.0))
	_saw_rede(par, cx0)


## Trampolins a subir por patamares até uma saída alta.
func _c_trampolins(par: Node2D, cx0: float) -> void:
	var alturas := [_chao_y - 20.0, _chao_y - 170.0, _chao_y - 320.0]
	var xs := [cx0 + 180.0, cx0 + 520.0, cx0 + 880.0]
	for i in 3:
		var tr := TRAMPOLIM.instantiate()
		tr.impulso = 720.0 + 40.0 * float(i)
		tr.position = Vector2(xs[i], alturas[i])
		par.add_child(tr)
		# plataforma de aterragem a seguir a cada trampolim
		_plat(par, Vector2(xs[i] + 200.0, alturas[i] - 150.0), Vector2(130.0, 18.0))
	_plat(par, Vector2(cx0 + LARG - 110.0, _chao_y - 300.0), Vector2(150.0, 18.0))
	_saw_rede(par, cx0)
	_inimigos(par, cx0, 1)


## Plataformas de corrente (pêndulo / vertical) a atravessar um vão.
func _c_correntes(par: Node2D, cx0: float) -> void:
	_espinhos(par, cx0 + LARG * 0.5, 10 + int(6.0 * _dif))
	var n := 4 + int(_dif * 2.0)
	for i in n:
		var pc := PLAT_CORRENTE.instantiate()
		pc.modo = "pendulo" if i % 2 == 0 else "vertical"
		pc.amplitude = 30.0 if pc.modo == "pendulo" else _rng.randf_range(60.0, 100.0)
		pc.periodo = _rng.randf_range(2.4, 3.4)
		pc.fase = _rng.randf_range(0.0, 2.0)
		pc.comprimento = _rng.randf_range(120.0, 180.0)
		pc.largura = 120.0
		pc.position = Vector2(cx0 + 180.0 + float(i) * ((LARG - 320.0) / float(n)), _chao_y - 240.0)
		par.add_child(pc)
	_plat(par, Vector2(cx0 + 90.0, _chao_y - 150.0), Vector2(90.0, 18.0))
	_plat(par, Vector2(cx0 + LARG - 90.0, _chao_y - 150.0), Vector2(90.0, 18.0))


## Elevadores (túmulos) automáticos entre patamares + plataformas fixas.
func _c_elevadores(par: Node2D, cx0: float) -> void:
	for i in 3:
		var tu := TUMULO.instantiate()
		tu.curso = Vector2(0.0, -_rng.randf_range(180.0, 300.0))
		tu.velocidade = _rng.randf_range(70.0, 110.0)
		tu.auto = true
		tu.largura = 130.0
		tu.position = Vector2(cx0 + 240.0 + float(i) * 340.0, _chao_y - 40.0)
		par.add_child(tu)
	_plat(par, Vector2(cx0 + 410.0, _chao_y - 260.0), Vector2(120.0, 18.0))
	_plat(par, Vector2(cx0 + 750.0, _chao_y - 300.0), Vector2(120.0, 18.0))
	_plat(par, Vector2(cx0 + LARG - 100.0, _chao_y - 180.0), Vector2(130.0, 18.0))
	_inimigos(par, cx0, 1 + int(_dif))


## Ponte de plataformas que esboroam -- atravessa-se sem parar.
func _c_quebra_ponte(par: Node2D, cx0: float) -> void:
	_saw_rede(par, cx0)
	var n := 7 + int(round(_dif * 5.0))
	var y := _chao_y - 130.0
	for i in n:
		var q := PLAT_QUEBRA.instantiate()
		q.tamanho = Vector2(96.0, 16.0)
		q.atraso = 0.5 - 0.16 * _dif
		q.respawn = 2.8
		q.position = Vector2(cx0 + 130.0 + float(i) * ((LARG - 240.0) / float(n)), y + _rng.randf_range(-24.0, 24.0))
		par.add_child(q)
	_plat(par, Vector2(cx0 + 80.0, y), Vector2(80.0, 16.0))
	_plat(par, Vector2(cx0 + LARG - 80.0, y), Vector2(80.0, 16.0))
	_inimigos(par, cx0, 1)


## Coluna de vento a elevar até plataformas empilhadas; flutua-se para a
## saída alta.
func _c_torre_vento(par: Node2D, cx0: float) -> void:
	var ca := CORRENTE_AR.instantiate()
	ca.position = Vector2(cx0 + 320.0, _chao_y - 220.0)
	ca.scale = Vector2(3.0, 4.4)
	par.add_child(ca)
	for i in 4:
		_plat(par, Vector2(cx0 + 260.0 + float(i % 2) * 180.0, _chao_y - 90.0 - float(i) * 110.0), Vector2(110.0, 16.0))
	# travessia alta até à direita
	_plat(par, Vector2(cx0 + 640.0, _chao_y - 430.0), Vector2(130.0, 16.0))
	_flut(par, Vector2(cx0 + 850.0, _chao_y - 400.0), 110.0, 130.0)
	_plat(par, Vector2(cx0 + LARG - 90.0, _chao_y - 330.0), Vector2(140.0, 18.0))
	_espinhos(par, cx0 + 520.0, 4 + int(2.0 * _dif))
	_inimigos(par, cx0, 1)


## Rajada horizontal a atravessar um vão largo (rota alta) + rota baixa com
## perigo.
func _c_impulso(par: Node2D, cx0: float) -> void:
	var imp := IMPULSOR.instantiate()
	imp.direcao = 1.0
	imp.vel_alvo = 430.0 + 60.0 * _dif
	imp.largura = LARG - 300.0
	imp.altura = 120.0
	imp.position = Vector2(cx0 + LARG * 0.5, _chao_y - 250.0)
	par.add_child(imp)
	_plat(par, Vector2(cx0 + 120.0, _chao_y - 200.0), Vector2(120.0, 18.0))
	_plat(par, Vector2(cx0 + LARG - 120.0, _chao_y - 200.0), Vector2(140.0, 18.0))
	# 2 plataformas no meio para não ser um voo cego
	_plat(par, Vector2(cx0 + LARG * 0.42, _chao_y - 250.0), Vector2(70.0, 14.0))
	_plat(par, Vector2(cx0 + LARG * 0.62, _chao_y - 250.0), Vector2(70.0, 14.0))
	# rota baixa
	_espinhos(par, cx0 + LARG * 0.5, 6 + int(3.0 * _dif))
	var sh := SERRA.instantiate()
	sh.position = Vector2(cx0 + LARG * 0.5, _chao_y - 34.0)
	sh.percurso = Vector2(300.0, 0.0)
	sh.tempo = _rng.randf_range(1.6, 2.2)
	par.add_child(sh)


## Bolsa de gravidade lunar: saltos longos e altos entre plataformas
## afastadas.
func _c_gravidade(par: Node2D, cx0: float) -> void:
	var zg := ZONA_GRAV.instantiate()
	if zg.get_node_or_null("Col") == null:
		var cs := CollisionShape2D.new()
		cs.name = "Col"
		var r := RectangleShape2D.new()
		r.size = Vector2(LARG - 160.0, TETO)
		cs.shape = r
		zg.add_child(cs)
	zg.escala = 0.4
	zg.position = Vector2(cx0 + LARG * 0.5, _chao_y - TETO * 0.5)
	par.add_child(zg)
	var n := 5 + int(_dif * 2.0)
	for i in n:
		var y := _chao_y - _rng.randf_range(90.0, 360.0)
		_plat(par, Vector2(cx0 + 150.0 + float(i) * ((LARG - 300.0) / float(n)), y), Vector2(78.0, 16.0))
	_espinhos(par, cx0 + LARG * 0.5, 8 + int(3.0 * _dif))
	_inimigos(par, cx0, 1)


# --- câmaras: perigo + rota alta -----------------------------------------

func _c_serras(par: Node2D, cx0: float) -> void:
	var sh := SERRA.instantiate()
	sh.position = Vector2(cx0 + 260.0, _chao_y - 34.0)
	sh.percurso = Vector2(360.0 + 90.0 * _dif, 0.0)
	sh.tempo = _rng.randf_range(1.5, 2.2)
	par.add_child(sh)
	var sv := SERRA.instantiate()
	sv.position = Vector2(cx0 + 780.0, _chao_y - 28.0)
	sv.percurso = Vector2(0.0, -160.0)
	sv.tempo = _rng.randf_range(1.0, 1.5)
	par.add_child(sv)
	_espinhos(par, cx0 + 520.0, 3 + int(2.0 * _dif))
	# rota alta
	_plat(par, Vector2(cx0 + 300.0, _chao_y - 150.0), Vector2(110.0, 16.0))
	_plat(par, Vector2(cx0 + 520.0, _chao_y - 210.0), Vector2(110.0, 16.0))
	_plat(par, Vector2(cx0 + 740.0, _chao_y - 150.0), Vector2(110.0, 16.0))
	_inimigos(par, cx0, 1 + int(_dif))


func _c_guilhotinas(par: Node2D, cx0: float) -> void:
	_plat(par, Vector2(cx0 + LARG * 0.5, _chao_y - 250.0), Vector2(LARG - 120.0, 20.0))
	var n := 3 + int(round(_dif * 2.5))
	for k in n:
		var g := GUILHOTINA.instantiate()
		g.automatico = true
		g.periodo = _rng.randf_range(2.2, 3.0) - 0.5 * _dif
		g.atraso = 0.6 - 0.2 * _dif
		g.fase = 0.5 * float(k)
		g.altura_queda = 210.0
		g.dano = 20 + int(12.0 * _dif)
		g.position = Vector2(cx0 + 170.0 + float(k) * ((LARG - 300.0) / float(maxi(1, n - 1))), _chao_y - 238.0)
		par.add_child(g)
	# rota alta por cima da viga
	for j in 3:
		_plat(par, Vector2(cx0 + 320.0 + float(j) * 250.0, _chao_y - 330.0), Vector2(90.0, 16.0))
	_inimigos(par, cx0, 1 + int(_dif))


func _c_fogo(par: Node2D, cx0: float) -> void:
	for k in 4:
		var f := FOGO.instantiate()
		f.position = Vector2(cx0 + 200.0 + float(k) * 230.0, _chao_y)
		f.intervalo = 2.0 - 0.4 * _dif
		f.dur_ativa = 1.0 + 0.4 * _dif
		f.fase = 0.6 * float(k)
		par.add_child(f)
	for lado: int in [-1, 1]:
		var px := cx0 + (340.0 if lado < 0 else 840.0)
		_plat(par, Vector2(px, _chao_y - 30.0), Vector2(28.0, 60.0))
		var tr := TORRETA.instantiate()
		tr.direcao = Vector2(float(lado), 0.0)
		tr.intervalo = 2.6 - 0.6 * _dif
		tr.fase = 0.9 if lado > 0 else 0.0
		tr.dano = 14 + int(10.0 * _dif)
		tr.position = Vector2(px + float(lado) * 6.0, _chao_y - 66.0)
		par.add_child(tr)
	# degraus por cima das chamas
	for j in 4:
		_plat(par, Vector2(cx0 + 210.0 + float(j) * 230.0, _chao_y - 140.0 - (30.0 if j % 2 else 0.0)), Vector2(90.0, 16.0))
	_inimigos(par, cx0, 1 + int(_dif))


func _c_pendulos(par: Node2D, cx0: float) -> void:
	_plat(par, Vector2(cx0 + LARG * 0.5, _chao_y - 320.0), Vector2(LARG - 140.0, 20.0))
	var n := 3 + int(round(_dif * 2.0))
	for k in n:
		var comp := _rng.randf_range(180.0, 230.0)
		var pe := PENDULO.instantiate()
		pe.comprimento = comp
		pe.periodo = _rng.randf_range(1.8, 2.6) - 0.3 * _dif
		pe.fase = float(k) / float(n) + _rng.randf_range(-0.1, 0.1)
		pe.amplitude_graus = 56.0 + 14.0 * _dif
		pe.dano = 18 + int(12.0 * _dif)
		pe.position = Vector2(cx0 + 220.0 + float(k) * ((LARG - 380.0) / float(maxi(1, n - 1))), _chao_y - comp - 34.0)
		par.add_child(pe)
	# ilhas entre os pêndulos
	for k in n - 1:
		_plat(par, Vector2(cx0 + 220.0 + (float(k) + 0.5) * ((LARG - 380.0) / float(maxi(1, n - 1))), _chao_y - 30.0), Vector2(72.0, 16.0))
	_inimigos(par, cx0, 1)


func _c_gruta(par: Node2D, cx0: float) -> void:
	_plat(par, Vector2(cx0 + 300.0, _chao_y - 150.0), Vector2(360.0, 40.0))
	_plat(par, Vector2(cx0 + 900.0, _chao_y - 150.0), Vector2(360.0, 40.0))
	_plat(par, Vector2(cx0 + 600.0, _chao_y - 24.0), Vector2(38.0, 46.0))
	_plat(par, Vector2(cx0 + 552.0, _chao_y - 12.0), Vector2(30.0, 26.0))
	# ledges intermédios
	_plat(par, Vector2(cx0 + 430.0, _chao_y - 96.0), Vector2(90.0, 16.0))
	_plat(par, Vector2(cx0 + 770.0, _chao_y - 96.0), Vector2(90.0, 16.0))
	var n := 3 + int(round(_dif * 2.0))
	for k in n:
		var pd := PEDRA.instantiate()
		pd.chao_y = _chao_y
		pd.dano = 18 + int(10.0 * _dif)
		pd.raio_gatilho = 80.0
		pd.aviso = _rng.randf_range(0.42, 0.6)
		pd.position = Vector2(cx0 + 220.0 + float(k) * ((LARG - 360.0) / float(maxi(1, n - 1))), _chao_y - 168.0)
		par.add_child(pd)
	_espinhos(par, cx0 + LARG - 150.0, 2 + int(_dif * 2.0))


func _c_prensa(par: Node2D, cx0: float) -> void:
	var n := 2 if _dif < 0.5 else 3
	for k in n:
		var pm := PAREDE_MOVEL.instantiate()
		pm.tamanho = Vector2(88.0, 140.0)
		pm.curso = Vector2(0.0, 66.0)
		pm.periodo = _rng.randf_range(1.9, 2.6)
		pm.fase = 0.5 * float(k % 2)
		pm.position = Vector2(cx0 + 260.0 + float(k) * 320.0, _chao_y - 235.0)
		par.add_child(pm)
	# rota por cima das prensas
	for k in n:
		_plat(par, Vector2(cx0 + 260.0 + float(k) * 320.0, _chao_y - 340.0), Vector2(120.0, 16.0))
	_plat(par, Vector2(cx0 + LARG - 100.0, _chao_y - 200.0), Vector2(120.0, 16.0))


func _c_pedras(par: Node2D, cx0: float) -> void:
	_plat(par, Vector2(cx0 + LARG * 0.5, _chao_y - 210.0), Vector2(LARG - 160.0, 26.0))
	var n := 4 + int(round(_dif * 3.0))
	for k in n:
		var pd := PEDRA.instantiate()
		pd.chao_y = _chao_y
		pd.automatico = true
		pd.periodo = _rng.randf_range(2.4, 3.6) - 0.6 * _dif
		pd.fase = _rng.randf_range(0.0, 2.0)
		pd.dano = 18 + int(12.0 * _dif)
		pd.aviso = 0.5 - 0.15 * _dif
		pd.position = Vector2(cx0 + 150.0 + float(k) * ((LARG - 260.0) / float(maxi(1, n - 1))), _chao_y - 192.0)
		par.add_child(pd)
	# ledges baixos alternativos
	_plat(par, Vector2(cx0 + 300.0, _chao_y - 70.0), Vector2(90.0, 16.0))
	_plat(par, Vector2(cx0 + 700.0, _chao_y - 70.0), Vector2(90.0, 16.0))
	_inimigos(par, cx0, 1)


## Corredor liso -- a última câmara, sem obstáculos: transição limpa para a
## geometria feita à mão (o seam nunca tranca).
func _c_plano(par: Node2D, cx0: float) -> void:
	_inimigos(par, cx0, 1 + int(_dif))
	if _rng.randf() < 0.5:
		_plat(par, Vector2(cx0 + LARG * 0.5, _chao_y - 150.0), Vector2(160.0, 18.0))


func _c_portal(par: Node2D, cx0: float) -> void:
	var moat_x := cx0 + 320.0
	var moat_w := 8 + int(4.0 * _dif)
	_espinhos(par, moat_x + moat_w * 8.0, moat_w)
	# rota A: plataformas suspensas + pêndulo
	for j in 4:
		_plat(par, Vector2(moat_x + 20.0 + float(j) * 150.0, _chao_y - 100.0 - (16.0 if j % 2 else 0.0)), Vector2(84.0, 16.0))
	var pe := PENDULO.instantiate()
	pe.comprimento = 160.0
	pe.periodo = _rng.randf_range(1.9, 2.4)
	pe.amplitude_graus = 56.0
	pe.dano = 18 + int(10.0 * _dif)
	pe.position = Vector2(moat_x + 220.0, _chao_y - 250.0)
	par.add_child(pe)
	# rota B: par de portais
	var idp := "jorn_%d" % _n
	var pa := PORTAL.instantiate()
	pa.id = idp + "_a"
	pa.destino_id = idp + "_b"
	pa.position = Vector2(cx0 + 170.0, _chao_y - 30.0)
	par.add_child(pa)
	var pb := PORTAL.instantiate()
	pb.id = idp + "_b"
	pb.destino_id = idp + "_a"
	pb.so_saida = true
	pb.position = Vector2(cx0 + LARG - 170.0, _chao_y - 34.0)
	par.add_child(pb)
