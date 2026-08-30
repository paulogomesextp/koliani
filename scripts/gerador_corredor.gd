class_name GeradorCorredor
extends Node2D
## JORNADA DE APROXIMACAO -- prepende um percurso LONGO e tematico a' esquerda
## do sitio onde a Koliani nasce, para que o chefe fique SEMPRE no fim do
## nivel (na ultima plataforma feita a' mao) e haja varios minutos de
## desafios + checkpoints ate la' chegar.
##
## O percurso e' uma fila de CAMARAS ligadas por um chao continuo, cada uma
## com uma mecanica distinta (muros, serras, guilhotinas, laminas
## pendulares, prensas, jatos de fogo, grutas com pedras que caem, colunas
## de vento, portais de teleporte, fossos de salto). O numero de camaras e a
## dureza CRESCEM com o numero do nivel. O tema (que camaras saem mais) vem
## da REGIAO do nivel.
##
## Regras anti-softlock (porque isto ja' esteve desligado):
##  - ha SEMPRE um chao raso continuo por toda a extensao -- cair nunca mata
##    nem prende;
##  - todos os muros sao saltaveis (com o salto duplo, sempre disponivel);
##  - nenhum perigo BLOQUEIA o caminho -- todos so' magoam e ciclam;
##  - nao ha portas trancadas / alavancas no gerador (eram a fonte dos
##    softlocks);
##  - os portais so' levam ao parceiro e a chegada e' sempre em chao solido;
##  - as prensas nunca fecham ate' ao chao.
## E' ADITIVO: nao toca na geometria feita a' mao do nivel. `corredor = false`
## na cena raiz desliga-o (o ultimo nivel nunca o tem).

@export var comprimento_base := 15000.0
@export var por_nivel := 620.0
@export var comprimento_max := 33000.0
## Espécie dos inimigos do percurso ("" = copia de um inimigo do nível).
@export var especie_inimigo := ""
## Reposiciona a Koliani no inicio da jornada (só numa entrada fresca de
## nível -- ver `nivel_com_chefe.gd`). Numa recarga por morte a Koliani já
## volta ao checkpoint sozinha e a jornada só reconstrói a geometria.
@export var entrada_fresca := true
## Desliga a otimização de visibilidade (usado pelos bots de teste).
@export var otimizar_visibilidade := true

const LARG := 1100.0

const PLAT := preload("res://scenes/actors/Plataforma.tscn")
const ESPINHOS := preload("res://scenes/actors/Espinhos.tscn")
const DEMONIO := preload("res://scenes/actors/DemonioBase.tscn")
const SERRA := preload("res://scenes/actors/Serra.tscn")
const FOGO := preload("res://scenes/actors/Fogo.tscn")
const GUILHOTINA := preload("res://scenes/actors/Guilhotina.tscn")
const TORRETA := preload("res://scenes/actors/Torreta.tscn")
const PAREDE_MOVEL := preload("res://scenes/actors/ParedeMovel.tscn")
const PLAT_FLUT := preload("res://scenes/actors/PlataformaFlutuante.tscn")
const CORRENTE_AR := preload("res://scenes/actors/CorrenteAr.tscn")
const PENDULO := preload("res://scenes/actors/PenduloLamina.tscn")
const PEDRA := preload("res://scenes/actors/PedraQueda.tscn")
const PORTAL := preload("res://scenes/actors/Portal.tscn")
const CHECKPOINT := preload("res://scripts/checkpoint.gd")

## Que câmaras podem sair em cada região (índice de `EstadoJogo.REGIOES`).
## A ordem não importa; o filtro por progresso/dureza é feito em `_escolher`.
const POOL_REGIAO := {
	0: ["muros", "serras", "fossos", "pendulos", "portal", "gruta"],
	1: ["muros", "serras", "guilhotinas", "prensa", "gruta", "portal", "fogo"],
	2: ["muros", "fossos", "vento", "pendulos", "portal", "serras"],
	3: ["gruta", "pedras", "guilhotinas", "pendulos", "portal", "muros"],
	4: ["muros", "serras", "prensa", "fogo", "guilhotinas", "portal"],
	5: ["pendulos", "fogo", "guilhotinas", "prensa", "gruta", "portal"],
}
## Progresso mínimo (0..1 ao longo da jornada) a que cada tipo pode aparecer.
const MIN_P := {
	"muros": 0.0, "serras": 0.0, "fossos": 0.06, "gruta": 0.1,
	"portal": 0.14, "pendulos": 0.2, "guilhotinas": 0.24,
	"vento": 0.12, "fogo": 0.3, "pedras": 0.28, "prensa": 0.4,
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
	_rng.seed = hash("jornada|%d" % _idx)
	_esp = especie_inimigo if especie_inimigo != "" else _especie_do_nivel()

	var ancora: Vector2 = EstadoJogo.jornada_ancora_para(
		_idx, func() -> Vector2: return (kol as Node2D).global_position)
	_chao_y = ancora.y + 76.0

	var comp: float = clampf(comprimento_base + por_nivel * float(_idx),
		comprimento_base, comprimento_max)
	var n_cam := maxi(3, int(round(comp / LARG)))
	comp = float(n_cam) * LARG
	var x0 := ancora.x - comp

	# --- geometria SEMPRE ativa (chão contínuo + parede de fundo) ---------
	var chao := PLAT.instantiate()
	add_child(chao)
	chao.position = Vector2((x0 + ancora.x) * 0.5, _chao_y + 26.0)
	chao.tamanho = Vector2(ancora.x - x0 + 520.0, 52.0)
	chao.altura_visual = 120.0

	var fundo := PLAT.instantiate()
	add_child(fundo)
	fundo.position = Vector2(x0 - 40.0, _chao_y - 220.0)
	fundo.tamanho = Vector2(72.0, 560.0)

	# masmorra fechada: recua a parede esquerda da Casca para dar lugar
	var casca := get_parent().get_node_or_null("Casca")
	if casca and casca.has_method("abrir_esquerda"):
		casca.abrir_esquerda(x0 - 160.0)

	# parallax da Atmosfera a acompanhar o novo comprimento
	var atm := get_tree().get_first_node_in_group("atmosfera")
	if atm and "largura_nivel" in atm:
		atm.largura_nivel = maxf(atm.largura_nivel, comp + 2800.0)

	# a Koliani arranca no início da jornada (só numa entrada fresca)
	if entrada_fresca:
		var inicio := Vector2(x0 + 90.0, _chao_y - 70.0)
		(kol as Node2D).global_position = inicio
		if "velocity" in kol:
			kol.velocity = Vector2.ZERO
		kol.set("_pos_inicial", inicio)
		EstadoJogo.definir_checkpoint(inicio)

	# checkpoint logo à entrada da jornada
	_checkpoint(x0 + 150.0)

	# --- câmaras --------------------------------------------------------
	var ant := ""
	for c in n_cam:
		_n = c
		var cx0 := x0 + float(c) * LARG
		var p := float(c) / float(maxi(1, n_cam - 1))
		var t := _escolher(ant, p)
		ant = t
		var par := _container(cx0)
		match t:
			"muros": _c_muros(par, cx0)
			"serras": _c_serras(par, cx0)
			"fossos": _c_fossos(par, cx0)
			"gruta": _c_gruta(par, cx0)
			"pedras": _c_pedras(par, cx0)
			"pendulos": _c_pendulos(par, cx0)
			"guilhotinas": _c_guilhotinas(par, cx0)
			"vento": _c_vento(par, cx0)
			"fogo": _c_fogo(par, cx0)
			"prensa": _c_prensa(par, cx0)
			"portal": _c_portal(par, cx0)
		# checkpoint no início de cada câmara -- morrer nela recomeça aqui
		_checkpoint(cx0 + 40.0)


## Escolhe o tipo da próxima câmara: filtra o pool da região pelo progresso
## `p` (0..1) e pela dureza do nível, e evita repetir a anterior.
func _escolher(ant: String, p: float) -> String:
	var base: Array = POOL_REGIAO.get(_regiao, POOL_REGIAO[0])
	var pool: Array = []
	for t: String in base:
		if p + _dif * 0.25 >= float(MIN_P.get(t, 0.0)):
			pool.append(t)
	pool = pool.filter(func(x: String) -> bool: return x != ant)
	if pool.is_empty():
		return "muros"
	return pool[_rng.randi() % pool.size()]


# --- infra ---------------------------------------------------------------

## Um contentor por câmara. Fora do ecrã, o `VisibleOnScreenEnabler2D`
## desliga-o (os perigos param) -- assim 30 câmaras não pesam no telemóvel.
func _container(cx0: float) -> Node2D:
	var c := Node2D.new()
	c.name = "Cam_%d" % _n
	add_child(c)
	if otimizar_visibilidade and DisplayServer.get_name() != "headless":
		var en := VisibleOnScreenEnabler2D.new()
		en.process_mode = Node.PROCESS_MODE_ALWAYS
		en.rect = Rect2(cx0 - 640.0, _chao_y - 900.0, LARG + 1280.0, 1300.0)
		c.add_child(en)
	return c


func _plat(par: Node2D, pos: Vector2, tam: Vector2, alt_vis := 0.0) -> void:
	var p := PLAT.instantiate()
	p.position = pos
	p.tamanho = tam
	if alt_vis > 0.0:
		p.altura_visual = alt_vis
	par.add_child(p)


func _espinhos(par: Node2D, x: float, largura: int) -> void:
	var e := ESPINHOS.instantiate()
	e.position = Vector2(x, _chao_y)
	e.largura = maxi(1, largura)
	e.dano = 14 + int(10.0 * _dif)
	par.add_child(e)


func _inimigos(par: Node2D, cx0: float, quantos: int) -> void:
	# longe das bordas da câmara para nunca entalarem a Koliani contra um muro
	for i in clampi(quantos, 0, 3):
		var d := DEMONIO.instantiate()
		d.especie = _esp
		d.position = Vector2(cx0 + _rng.randf_range(300.0, LARG - 320.0), _chao_y - 46.0)
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


# --- câmaras -----------------------------------------------------------

## Muros escalonados saltáveis + rota elevada de atalho + inimigos.
func _c_muros(par: Node2D, cx0: float) -> void:
	var n := 3 + int(round(_dif * 2.0))
	var passo := (LARG - 320.0) / float(n)
	for k in n:
		var mx := cx0 + 190.0 + float(k) * passo
		var alt := _rng.randf_range(40.0, 58.0)
		_plat(par, Vector2(mx - 48.0, _chao_y - alt * 0.28), Vector2(30.0, alt * 0.55))
		_plat(par, Vector2(mx, _chao_y - alt * 0.5), Vector2(42.0, alt))
		if k == n - 1 and _rng.randf() < 0.35 + 0.3 * _dif:
			_espinhos(par, mx + passo * 0.5, 2 + int(2.0 * _dif))
	for j in 3:
		_plat(par, Vector2(cx0 + 360.0 + float(j) * 150.0, _chao_y - 168.0), Vector2(96.0, 16.0))
	_inimigos(par, cx0, 1 + int(_dif * 2.0))


## Serras em calhas (horizontal + vertical) + abrigo + fila de espinhos.
func _c_serras(par: Node2D, cx0: float) -> void:
	var sh := SERRA.instantiate()
	sh.position = Vector2(cx0 + 260.0, _chao_y - 34.0)
	sh.percurso = Vector2(320.0 + 90.0 * _dif, 0.0)
	sh.tempo = _rng.randf_range(1.5, 2.2)
	par.add_child(sh)
	var sv := SERRA.instantiate()
	sv.position = Vector2(cx0 + 720.0, _chao_y - 28.0)
	sv.percurso = Vector2(0.0, -150.0)
	sv.tempo = _rng.randf_range(1.0, 1.5)
	par.add_child(sv)
	_espinhos(par, cx0 + 500.0, 3 + int(2.0 * _dif))
	_plat(par, Vector2(cx0 + 500.0, _chao_y - 104.0), Vector2(96.0, 16.0))
	_inimigos(par, cx0, 1 + int(_dif * 1.5))


## Fossos de salto: plataformas elevadas com vãos; uma serra rasteira no
## fundo dá o dano (o chão contínuo por baixo evita o softlock).
func _c_fossos(par: Node2D, cx0: float) -> void:
	var n := 3 + int(round(_dif * 1.5))
	var larg_plat := (LARG - 120.0) / float(n) - _rng.randf_range(46.0, 86.0)
	larg_plat = maxf(70.0, larg_plat)
	# serra rasteira no fundo do fosso -- ameaça quem cair, mas varre só o
	# meio (as pontas ficam livres para sair sempre a pé)
	var sh := SERRA.instantiate()
	sh.position = Vector2(cx0 + 200.0, _chao_y - 22.0)
	sh.percurso = Vector2(LARG * 0.55, 0.0)
	sh.tempo = _rng.randf_range(2.0, 3.0)
	par.add_child(sh)
	for k in n:
		var px := cx0 + 90.0 + float(k) * ((LARG - 120.0) / float(n))
		_plat(par, Vector2(px + larg_plat * 0.5, _chao_y - 64.0), Vector2(larg_plat, 20.0), 110.0)
	if _dif > 0.3:
		var pf := PLAT_FLUT.instantiate()
		pf.largura = 110.0
		pf.balanco = 8.0
		pf.deriva = 90.0
		pf.periodo_deriva = _rng.randf_range(3.4, 4.6)
		pf.position = Vector2(cx0 + LARG * 0.55, _chao_y - 150.0)
		par.add_child(pf)
	_inimigos(par, cx0, 1 + int(_dif * 1.5))


## Gruta: tecto baixo (obriga a baixar), pedras que caem ao passar, um muro
## a saltar e uma nesga de espinhos. Tema das catacumbas/prisão/castelo.
func _c_gruta(par: Node2D, cx0: float) -> void:
	# lajes de tecto com um vão para passar
	_plat(par, Vector2(cx0 + 300.0, _chao_y - 150.0), Vector2(360.0, 40.0))
	_plat(par, Vector2(cx0 + 820.0, _chao_y - 150.0), Vector2(360.0, 40.0))
	# muro central a saltar (com degrau à frente)
	_plat(par, Vector2(cx0 + 560.0, _chao_y - 26.0), Vector2(40.0, 52.0))
	_plat(par, Vector2(cx0 + 512.0, _chao_y - 14.0), Vector2(30.0, 30.0))
	var n := 2 + int(round(_dif * 2.0))
	for k in n:
		var pd := PEDRA.instantiate()
		pd.chao_y = _chao_y
		pd.dano = 18 + int(10.0 * _dif)
		pd.raio_gatilho = 80.0
		pd.aviso = _rng.randf_range(0.42, 0.6)
		pd.position = Vector2(cx0 + 200.0 + float(k) * ((LARG - 320.0) / float(maxi(1, n - 1))), _chao_y - 168.0)
		par.add_child(pd)
	_espinhos(par, cx0 + 940.0, 2 + int(_dif * 2.0))
	_inimigos(par, cx0, 1 + int(_dif * 2.0))


## Corredor de pedras que caem em ciclo -- sprinta-se a cronometrar.
func _c_pedras(par: Node2D, cx0: float) -> void:
	_plat(par, Vector2(cx0 + LARG * 0.5, _chao_y - 200.0), Vector2(LARG - 160.0, 28.0))
	var n := 4 + int(round(_dif * 3.0))
	for k in n:
		var pd := PEDRA.instantiate()
		pd.chao_y = _chao_y
		pd.automatico = true
		pd.periodo = _rng.randf_range(2.4, 3.6) - 0.6 * _dif
		pd.fase = _rng.randf_range(0.0, 2.0)
		pd.dano = 18 + int(12.0 * _dif)
		pd.aviso = 0.5 - 0.15 * _dif
		pd.position = Vector2(cx0 + 150.0 + float(k) * ((LARG - 260.0) / float(maxi(1, n - 1))), _chao_y - 182.0)
		par.add_child(pd)
	_inimigos(par, cx0, 1 + int(_dif))


## Fila de lâminas pendulares desfasadas + degraus para cronometrar.
func _c_pendulos(par: Node2D, cx0: float) -> void:
	_plat(par, Vector2(cx0 + LARG * 0.5, _chao_y - 300.0), Vector2(LARG - 140.0, 22.0))
	var n := 3 + int(round(_dif * 2.0))
	for k in n:
		var comp := _rng.randf_range(180.0, 225.0)
		var pe := PENDULO.instantiate()
		pe.comprimento = comp
		pe.periodo = _rng.randf_range(1.8, 2.6) - 0.3 * _dif
		pe.fase = float(k) / float(n) + _rng.randf_range(-0.1, 0.1)
		pe.amplitude_graus = 56.0 + 14.0 * _dif
		pe.dano = 18 + int(12.0 * _dif)
		# pivô calculado para a ponta da lâmina varrer à altura do peito
		pe.position = Vector2(cx0 + 220.0 + float(k) * ((LARG - 380.0) / float(maxi(1, n - 1))), _chao_y - comp - 34.0)
		par.add_child(pe)
	_inimigos(par, cx0, 1 + int(_dif))


## Corredor de guilhotinas automáticas com tempos desfasados.
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
	_inimigos(par, cx0, 1 + int(_dif * 1.5))


## Coluna de vento ascendente sobre um vão + plataformas altas.
func _c_vento(par: Node2D, cx0: float) -> void:
	var ca := CORRENTE_AR.instantiate()
	ca.position = Vector2(cx0 + LARG * 0.5, _chao_y - 190.0)
	if ca.has_node("Col"):
		pass
	par.add_child(ca)
	# a área da CorrenteAr vem da cena; ajusta-se pela escala do nó
	ca.scale = Vector2(3.4, 4.2)
	_plat(par, Vector2(cx0 + LARG * 0.5, _chao_y - 360.0), Vector2(150.0, 18.0))
	_plat(par, Vector2(cx0 + LARG * 0.5 + 240.0, _chao_y - 250.0), Vector2(120.0, 18.0))
	var sv := SERRA.instantiate()
	sv.position = Vector2(cx0 + LARG * 0.5, _chao_y - 24.0)
	sv.percurso = Vector2(220.0, 0.0)
	sv.tempo = _rng.randf_range(1.6, 2.2)
	par.add_child(sv)
	_inimigos(par, cx0, 1 + int(_dif))


## Jatos de fogo no chão + torretas em postes baixos.
func _c_fogo(par: Node2D, cx0: float) -> void:
	for k in 4:
		var f := FOGO.instantiate()
		f.position = Vector2(cx0 + 190.0 + float(k) * 210.0, _chao_y)
		f.intervalo = 2.0 - 0.4 * _dif
		f.dur_ativa = 1.0 + 0.4 * _dif
		f.fase = 0.6 * float(k)
		par.add_child(f)
	for lado: int in [-1, 1]:
		var px := cx0 + (320.0 if lado < 0 else 760.0)
		_plat(par, Vector2(px, _chao_y - 30.0), Vector2(28.0, 60.0))
		var tr := TORRETA.instantiate()
		tr.direcao = Vector2(float(lado), 0.0)
		tr.intervalo = 2.6 - 0.6 * _dif
		tr.fase = 0.9 if lado > 0 else 0.0
		tr.dano = 14 + int(10.0 * _dif)
		tr.position = Vector2(px + float(lado) * 6.0, _chao_y - 66.0)
		par.add_child(tr)
	_inimigos(par, cx0, 1 + int(_dif * 1.5))


## Prensas verticais que nunca fecham até ao chão.
func _c_prensa(par: Node2D, cx0: float) -> void:
	var n := 2 if _dif < 0.5 else 3
	for k in n:
		var pm := PAREDE_MOVEL.instantiate()
		pm.tamanho = Vector2(88.0, 150.0)
		pm.curso = Vector2(0.0, 82.0)
		pm.periodo = _rng.randf_range(1.9, 2.6)
		pm.fase = 0.5 * float(k % 2)
		pm.position = Vector2(cx0 + 240.0 + float(k) * 280.0, _chao_y - 226.0)
		par.add_child(pm)
	_inimigos(par, cx0, 1 + int(_dif * 2.0))


## Fosso de espinhos largo com DUAS rotas: plataformas/pêndulo por cima OU
## um par de portais de teleporte (entrada antes, saída logo depois).
func _c_portal(par: Node2D, cx0: float) -> void:
	var moat_x := cx0 + 300.0
	var moat_w := 8 + int(4.0 * _dif)
	_espinhos(par, moat_x + moat_w * 8.0, moat_w)

	# rota A: plataformas suspensas + um pêndulo
	for j in 3:
		_plat(par, Vector2(moat_x + 40.0 + float(j) * 150.0, _chao_y - 96.0 - (14.0 if j == 1 else 0.0)), Vector2(84.0, 16.0))
	var pe := PENDULO.instantiate()
	pe.comprimento = 150.0
	pe.periodo = _rng.randf_range(1.9, 2.4)
	pe.amplitude_graus = 56.0
	pe.dano = 18 + int(10.0 * _dif)
	pe.position = Vector2(moat_x + 190.0, _chao_y - 240.0)
	par.add_child(pe)

	# rota B: portal de entrada num pedestal antes do fosso, saída depois
	var idp := "jorn_%d" % _n
	_plat(par, Vector2(cx0 + 150.0, _chao_y - 20.0), Vector2(70.0, 40.0))
	var pa := PORTAL.instantiate()
	pa.id = idp + "_a"
	pa.destino_id = idp + "_b"
	pa.position = Vector2(cx0 + 150.0, _chao_y - 60.0)
	par.add_child(pa)
	var pb := PORTAL.instantiate()
	pb.id = idp + "_b"
	pb.destino_id = idp + "_a"
	pb.so_saida = true
	pb.position = Vector2(cx0 + LARG - 170.0, _chao_y - 34.0)
	par.add_child(pb)

	_inimigos(par, cx0, 1 + int(_dif))
