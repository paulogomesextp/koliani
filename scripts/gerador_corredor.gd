class_name GeradorCorredor
extends Node2D
## Prepende um GAUNTLET DE APROXIMAÇÃO à esquerda do sítio onde a Koliani
## nasce: uma sequência de CÂMARAS ligadas por um chão contínuo, cada uma
## com uma mecânica distinta (muros de salto, porta+alavanca, serras,
## corredor de guilhotinas, jatos de fogo + torretas, prensa). O número de
## câmaras e a densidade de perigos CRESCEM com o número do nível -- os
## níveis passam a ser bem mais longos e difíceis antes do chefe.
##
## Regras anti-softlock: há SEMPRE chão raso por toda a extensão (cair nunca
## mata nem prende); os muros são saltáveis; as portas trancadas têm sempre
## a alavanca acessível mesmo antes delas; as prensas nunca fecham até ao
## chão. É aditivo -- não toca na geometria feita à mão do nível. Pôr
## `corredor = false` na cena para o desligar (o último nível não o tem).

@export var comprimento_base := 2200.0
@export var por_nivel := 260.0
@export var comprimento_max := 7200.0
## Espécie dos inimigos do gauntlet ("" = copia de um inimigo do nível).
@export var especie_inimigo := ""

const CAMARA := 820.0
const PLAT := preload("res://scenes/actors/Plataforma.tscn")
const ESPINHOS := preload("res://scenes/actors/Espinhos.tscn")
const DEMONIO := preload("res://scenes/actors/DemonioBase.tscn")
const ALAVANCA := preload("res://scenes/actors/Alavanca.tscn")
const PORTA_T := preload("res://scenes/actors/PortaTrancada.tscn")
const SERRA := preload("res://scenes/actors/Serra.tscn")
const FOGO := preload("res://scenes/actors/Fogo.tscn")
const GUILHOTINA := preload("res://scenes/actors/Guilhotina.tscn")
const TORRETA := preload("res://scenes/actors/Torreta.tscn")
const PAREDE_MOVEL := preload("res://scenes/actors/ParedeMovel.tscn")
const CHECKPOINT := preload("res://scripts/checkpoint.gd")

var _chao_y := 0.0
var _idx := 0
var _dif := 0.0
var _esp := "goblin"
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	call_deferred("_construir")


func _construir() -> void:
	var kol := get_tree().get_first_node_in_group("koliani")
	if kol == null:
		return
	var join: Vector2 = (kol as Node2D).global_position
	_chao_y = join.y + 76.0
	_idx = EstadoJogo.indice_nivel
	_dif = clampf(float(_idx) / 29.0, 0.0, 1.0)
	_rng.seed = hash("gauntlet|%d" % _idx)
	_esp = especie_inimigo if especie_inimigo != "" else _especie_do_nivel()

	var comp: float = minf(comprimento_base + por_nivel * float(_idx), comprimento_max)
	var n_cam := maxi(2, int(round(comp / CAMARA)))
	comp = float(n_cam) * CAMARA
	var x0 := join.x - comp

	# chão contínuo -- encosta ao chão do nível no `join`
	var chao := PLAT.instantiate()
	add_child(chao)
	chao.position = Vector2((x0 + join.x) * 0.5, _chao_y + 24.0)
	chao.tamanho = Vector2(join.x - x0 + 420.0, 48.0)
	chao.altura_visual = 90.0

	# parede do fundo -- não se sai pela esquerda
	var fundo := PLAT.instantiate()
	add_child(fundo)
	fundo.position = Vector2(x0 - 34.0, _chao_y - 170.0)
	fundo.tamanho = Vector2(64.0, 440.0)

	# a Koliani arranca no início do gauntlet (só se não vier de um checkpoint)
	if EstadoJogo.checkpoint == Vector2.ZERO:
		(kol as Node2D).global_position = Vector2(x0 + 70.0, _chao_y - 60.0)

	# se o nível é uma masmorra fechada, recua a parede esquerda da Casca
	# para dar lugar ao gauntlet
	var casca := get_parent().get_node_or_null("Casca")
	if casca and casca.has_method("abrir_esquerda"):
		casca.abrir_esquerda(x0 - 120.0)

	# --- câmaras -------------------------------------------------------
	var ant := ""
	for c in n_cam:
		var cx0 := x0 + float(c) * CAMARA
		var t := _escolher_camara(ant, float(c) / float(maxi(1, n_cam - 1)))
		ant = t
		match t:
			"muros": _cam_muros(cx0)
			"alavanca": _cam_alavanca(cx0, c)
			"serras": _cam_serras(cx0)
			"guilhotinas": _cam_guilhotinas(cx0)
			"fogo": _cam_fogo(cx0)
			"prensa": _cam_prensa(cx0)
		# checkpoint a cada 2 câmaras -- morrer no meio não volta ao início
		if c > 0 and c % 2 == 0:
			_checkpoint(cx0 + 30.0)


## Escolhe o tipo da próxima câmara: mais fáceis no início, as duras entram
## conforme a dificuldade do nível e o avanço `p` (0..1) pelo gauntlet.
func _escolher_camara(ant: String, p: float) -> String:
	var pool := ["muros", "alavanca", "serras"]
	if _dif > 0.12 or p > 0.35:
		pool.append("guilhotinas")
	if _dif > 0.22 or p > 0.5:
		pool.append("fogo")
	if _dif > 0.38 or p > 0.68:
		pool.append("prensa")
	pool = pool.filter(func(x: String) -> bool: return x != ant)
	return pool[_rng.randi() % pool.size()]


# --- câmaras ---------------------------------------------------------------

## Muros escalonados -- saltar / usar escalar_paredes. Um vão com espinhos
## e uma rota elevada opcional por cima.
func _cam_muros(cx0: float) -> void:
	var n := 3 + int(round(_dif * 2.0))
	var passo := 640.0 / float(n)
	for k in n:
		var mx := cx0 + 150.0 + float(k) * passo
		var alt := _rng.randf_range(50.0, 78.0)
		# degrau baixo mesmo antes do muro -> salta-se por cima sem colar à
		# parede (a habilidade escalar_paredes torna-o trivial, mas nunca
		# obrigatório).
		var deg := PLAT.instantiate()
		deg.position = Vector2(mx - 46.0, _chao_y - alt * 0.28)
		deg.tamanho = Vector2(30.0, alt * 0.55)
		add_child(deg)
		_muro(mx, alt)
		if k == n - 1 and _rng.randf() < 0.4 + 0.3 * _dif:
			var e := ESPINHOS.instantiate()
			e.position = Vector2(mx + passo * 0.5, _chao_y)
			e.largura = 2 + int(2.0 * _dif)
			e.dano = 16 + int(10.0 * _dif)
			add_child(e)
	# rota elevada (atalho) por cima do meio
	for j in 3:
		var p := PLAT.instantiate()
		p.position = Vector2(cx0 + 300.0 + float(j) * 90.0, _chao_y - 150.0 - (12.0 if j == 1 else 0.0))
		p.tamanho = Vector2(76.0, 16.0)
		add_child(p)
	_inimigos(cx0, 1 + int(_dif * 2.0))


## Porta trancada a atravessar o chão + a sua alavanca numa saliência antes
## dela (SEMPRE acessível). Uma serra entre as duas para dar pressa.
func _cam_alavanca(cx0: float, c: int) -> void:
	var lid := "gaunt_%d_%d" % [_idx, c]
	# alavanca AO NÍVEL DO CHÃO, mesmo no caminho -- passa-se por cima dela
	# (adicionar ANTES da porta: a porta liga-se às alavancas no _ready).
	var al := ALAVANCA.instantiate()
	al.id = lid
	al.so_liga = true
	al.position = Vector2(cx0 + 240.0, _chao_y - 16.0)
	add_child(al)

	if _dif > 0.25:
		var s := SERRA.instantiate()
		s.position = Vector2(cx0 + 400.0, _chao_y - 44.0)
		s.percurso = Vector2(0.0, -120.0)
		s.tempo = _rng.randf_range(1.2, 1.8)
		add_child(s)

	var pt := PORTA_T.instantiate()
	pt.id = lid
	pt.exige_todas = false
	pt.tamanho = Vector2(24.0, 150.0)
	pt.position = Vector2(cx0 + 560.0, _chao_y - 67.0)
	add_child(pt)

	_inimigos(cx0, 1 + int(_dif * 2.0))


## Serras em calhas (horizontal + vertical) sobre o chão + uma fila de
## espinhos com salto.
func _cam_serras(cx0: float) -> void:
	var sh := SERRA.instantiate()
	sh.position = Vector2(cx0 + 210.0, _chao_y - 58.0)
	sh.percurso = Vector2(210.0 + 60.0 * _dif, 0.0)
	sh.tempo = _rng.randf_range(1.3, 1.9)
	add_child(sh)

	var sv := SERRA.instantiate()
	sv.position = Vector2(cx0 + 520.0, _chao_y - 30.0)
	sv.percurso = Vector2(0.0, -130.0)
	sv.tempo = _rng.randf_range(1.0, 1.5)
	add_child(sv)

	var e := ESPINHOS.instantiate()
	e.position = Vector2(cx0 + 370.0, _chao_y)
	e.largura = 3 + int(2.0 * _dif)
	e.dano = 16 + int(10.0 * _dif)
	add_child(e)
	# plataforma-abrigo entre as serras
	var p := PLAT.instantiate()
	p.position = Vector2(cx0 + 370.0, _chao_y - 96.0)
	p.tamanho = Vector2(84.0, 16.0)
	add_child(p)
	_inimigos(cx0, 1 + int(_dif * 1.5))


## Corredor de guilhotinas automáticas com tempos desfasados. Viga de
## suporte por cima; chão livre por baixo.
func _cam_guilhotinas(cx0: float) -> void:
	var viga := PLAT.instantiate()
	viga.position = Vector2(cx0 + 400.0, _chao_y - 250.0)
	viga.tamanho = Vector2(660.0, 20.0)
	add_child(viga)
	var n := 3 + int(round(_dif * 2.0))
	for k in n:
		var g := GUILHOTINA.instantiate()
		g.automatico = true
		g.periodo = _rng.randf_range(2.0, 2.8) - 0.5 * _dif
		g.atraso = 0.6 - 0.2 * _dif
		g.fase = 0.5 * float(k)
		g.altura_queda = 208.0
		g.dano = 22 + int(12.0 * _dif)
		g.position = Vector2(cx0 + 170.0 + float(k) * (520.0 / float(maxi(1, n - 1))), _chao_y - 238.0)
		add_child(g)
	_inimigos(cx0, 1 + int(_dif * 1.5))


## Jatos de fogo no chão (desfasados) + torretas que cospem BolaFogo.
func _cam_fogo(cx0: float) -> void:
	for k in 3:
		var f := FOGO.instantiate()
		f.position = Vector2(cx0 + 190.0 + float(k) * 190.0, _chao_y)
		f.intervalo = 1.9 - 0.4 * _dif
		f.dur_ativa = 1.1 + 0.4 * _dif
		f.fase = 0.7 * float(k)
		add_child(f)
	# duas torretas em postes BAIXOS (saltáveis), a disparar em sentidos
	# opostos ao nível da cabeça
	for lado: int in [-1, 1]:
		var px := cx0 + (280.0 if lado < 0 else 560.0)
		var poste := PLAT.instantiate()
		poste.position = Vector2(px, _chao_y - 30.0)
		poste.tamanho = Vector2(28.0, 60.0)
		add_child(poste)
		var tr := TORRETA.instantiate()
		tr.direcao = Vector2(float(lado), 0.0)
		tr.intervalo = 2.6 - 0.6 * _dif
		tr.fase = 0.9 if lado > 0 else 0.0
		tr.dano = 16 + int(10.0 * _dif)
		tr.position = Vector2(px + float(lado) * 6.0, _chao_y - 66.0)
		add_child(tr)
	_inimigos(cx0, 1 + int(_dif * 1.5))


## Prensas verticais que nunca fecham até ao chão -- passa-se na batida em
## que sobem.
func _cam_prensa(cx0: float) -> void:
	var n := 2 if _dif < 0.5 else 3
	for k in n:
		var pm := PAREDE_MOVEL.instantiate()
		pm.tamanho = Vector2(84.0, 140.0)
		pm.curso = Vector2(0.0, 78.0)
		pm.periodo = _rng.randf_range(2.0, 2.6)
		pm.fase = 0.5 * float(k % 2)
		# base: bordo inferior a ~150 px do chão; desce até ~72 px (nunca tapa)
		pm.position = Vector2(cx0 + 220.0 + float(k) * 240.0, _chao_y - 70.0 - 150.0)
		add_child(pm)
	_inimigos(cx0, 1 + int(_dif * 2.0))


# --- utilitários --------------------------------------------------------

func _muro(x: float, alt: float) -> void:
	var w := PLAT.instantiate()
	w.position = Vector2(x, _chao_y - alt * 0.5)
	w.tamanho = Vector2(44.0, alt)
	add_child(w)


func _inimigos(cx0: float, quantos: int) -> void:
	for i in maxi(0, quantos):
		var d := DEMONIO.instantiate()
		d.especie = _esp
		d.position = Vector2(cx0 + _rng.randf_range(120.0, 700.0), _chao_y - 44.0)
		d.alcance_patrulha = _rng.randf_range(90.0, 190.0)
		add_child(d)


func _checkpoint(x: float) -> void:
	var ck := Area2D.new()
	ck.name = "GauntletCheck"
	ck.collision_layer = 16
	ck.collision_mask = 2
	ck.position = Vector2(x, _chao_y - 45.0)
	var cf := CollisionShape2D.new()
	var rc := RectangleShape2D.new()
	rc.size = Vector2(40.0, 90.0)
	cf.shape = rc
	ck.add_child(cf)
	ck.set_script(CHECKPOINT)
	add_child(ck)


func _especie_do_nivel() -> String:
	for d in get_tree().get_nodes_in_group("inimigos"):
		if "especie" in d:
			return d.especie
	return "goblin"
