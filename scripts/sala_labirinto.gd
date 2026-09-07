class_name SalaLabirinto
extends Node2D
## Câmara fechada, construída em código: chão + tecto + paredes, um caminho
## em Z com paredes internas (saltar por cima / passar por baixo -- SEMPRE
## há rota sem escalar), DUAS alavancas em alcovas separadas e uma
## `PortaTrancada` na saída que só abre com AS DUAS. Serra + espinhos pelo
## meio.
##
## Origem = ponto de ENTRADA (canto inferior-esquerdo, ao nível do chão). A
## saída fica em `Vector2(largura, 0)`. `GeradorCorredor` encaixa isto no
## corredor; também dá para largar à mão numa cena.

@export var largura := 1100.0
@export var altura := 420.0
## 0..1 -- mais serras/espinhos e alcance dos inimigos.
@export var dificuldade := 0.4
## id que liga as alavancas à porta da saída.
@export var id := "labirinto"
## Espécie de inimigo a usar nas alcovas ("" = goblin).
@export var especie_inimigo := "goblin"
## Controla toda a aleatoriedade estrutural. O valor fica explícito para a
## bancada conseguir reconstruir exatamente a mesma sala.
@export var seed_layout := 1701

const PLAT := preload("res://scenes/actors/Plataforma.tscn")
const ESPINHOS := preload("res://scenes/actors/Espinhos.tscn")
const SERRA := preload("res://scenes/actors/Serra.tscn")
const DEMONIO := preload("res://scenes/actors/DemonioBase.tscn")
const ALAVANCA := preload("res://scenes/actors/Alavanca.tscn")
const PORTA_T := preload("res://scenes/actors/PortaTrancada.tscn")

const GAP := 108.0   # vão de passagem (por cima/por baixo)
const ESP := 40.0    # espessura das paredes
const ALTURA_KOLIANI := 44.0
const MARGEM_SALTO := 10.0


## Descrição lógica pura da sala. Não instancia nós nem consulta a árvore.
## É a fonte comum da construção e da prova determinística abaixo.
static func descricao_logica(w := 1100.0, h := 420.0, dif := 0.4,
		seed := 1701) -> Dictionary:
	var d := clampf(dif, 0.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var x1 := w * 0.36
	var x2 := w * 0.66
	var ax := w * 0.82
	var serras: Array[Dictionary] = [{
		"pos": Vector2(x1 - 80.0, -150.0),
		"percurso": Vector2(0.0, 150.0),
		"tempo": rng.randf_range(1.4, 2.2),
		"esperavel": true,
	}]
	if d > 0.5:
		serras.append({
			"pos": Vector2(w * 0.5, -GAP - 30.0),
			"percurso": Vector2(0.0, -(h - GAP - 90.0)),
			"tempo": rng.randf_range(2.0, 3.0),
			"esperavel": true,
		})
	return {
		"entrada": Vector2(20.0, -ESP * 0.5 - ALTURA_KOLIANI * 0.5),
		"saida": Vector2(w + 28.0, -ESP * 0.5 - ALTURA_KOLIANI * 0.5),
		"paredes": [
			{"id": "chao", "pos": Vector2(w * 0.5, ESP * 0.5),
				"tam": Vector2(w + ESP, ESP)},
			{"id": "tecto", "pos": Vector2(w * 0.5, -h - ESP * 0.5),
				"tam": Vector2(w + ESP, ESP)},
			{"id": "limite_esquerdo",
				"pos": Vector2(-ESP * 0.5, -(h + GAP) * 0.5),
				"tam": Vector2(ESP, h - GAP)},
			{"id": "limite_direito",
				"pos": Vector2(w + ESP * 0.5, -(h + GAP) * 0.5),
				"tam": Vector2(ESP, h - GAP)},
			{"id": "parede_baixa", "pos": Vector2(x1, -55.0),
				"tam": Vector2(ESP, 110.0)},
			{"id": "parede_alta", "pos": Vector2(x2, -(h + GAP) * 0.5),
				"tam": Vector2(ESP, h - GAP)},
		],
		"plataformas": [
			{"id": "degrau_1", "pos": Vector2(70.0, -110.0),
				"tam": Vector2(78.0, 18.0)},
			{"id": "degrau_2", "pos": Vector2(160.0, -200.0),
				"tam": Vector2(78.0, 18.0)},
			{"id": "degrau_3", "pos": Vector2(250.0, -290.0),
				"tam": Vector2(120.0, 18.0)},
		],
		"alavancas": {
			"A": Vector2(250.0, -336.0),
			"B": Vector2(ax, -26.0),
		},
		"portao": {"pos": Vector2(w - 4.0, -(h + GAP) * 0.5),
			"tam": Vector2(26.0, h - GAP), "exige": ["A", "B"]},
		"espinhos": {"pos": Vector2(ax - 120.0, -4.0),
			"largura_px": (3 + int(3.0 * d)) * 16.0, "pogavel": true},
		"serras": serras,
		"capacidades": {
			"altura_corpo": ALTURA_KOLIANI,
			"vel_corrida": Movimento.VEL_CORRIDA,
			"gravidade": Movimento.GRAVIDADE,
			"forca_salto": Movimento.FORCA_SALTO,
			"saltos": 2,
		},
	}


## Prova conservadora do contrato de encaixe. Os segmentos ascendentes usam
## a altura balística dos dois saltos reais; descidas são aceites apenas para
## o chão contínuo. Serras periódicas são atravessáveis por espera, nunca por
## assumir um instante aleatório favorável.
static func validar_descricao(desc: Dictionary) -> Dictionary:
	var erros: Array[String] = []
	var caps: Dictionary = desc.get("capacidades", {})
	var grav := float(caps.get("gravidade", 0.0))
	var impulso := float(caps.get("forca_salto", 0.0))
	var saltos := int(caps.get("saltos", 0))
	var altura_max := 0.0
	if grav > 0.0:
		altura_max = impulso * impulso / (2.0 * grav) * saltos
	if altura_max < 100.0 + MARGEM_SALTO:
		erros.append("salto duplo nao vence a parede/degrau de 100 px")
	if GAP < float(caps.get("altura_corpo", INF)) + 20.0:
		erros.append("vao inferior nao tem folga para a Koliani")

	var plats: Array = desc.get("plataformas", [])
	var anterior := desc.get("entrada", Vector2.ZERO) as Vector2
	for p: Dictionary in plats:
		var pos: Vector2 = p["pos"]
		var tam: Vector2 = p["tam"]
		var apoio := Vector2(pos.x, pos.y - tam.y * 0.5
			- float(caps.get("altura_corpo", ALTURA_KOLIANI)) * 0.5)
		var subida := anterior.y - apoio.y
		if subida > altura_max - MARGEM_SALTO:
			erros.append("%s exige subida %.1f, maximo conservador %.1f"
				% [p["id"], subida, altura_max - MARGEM_SALTO])
		anterior = apoio

	var espinhos: Dictionary = desc.get("espinhos", {})
	var alcance_horizontal := float(caps.get("vel_corrida", 0.0)) \
		* (2.0 * impulso / maxf(grav, 1.0))
	if float(espinhos.get("largura_px", INF)) + 64.0 > alcance_horizontal:
		erros.append("espinhos ocupam mais do que o salto horizontal conservador")
	for serra: Dictionary in desc.get("serras", []):
		if float(serra.get("tempo", 0.0)) <= 0.0 or not serra.get("esperavel", false):
			erros.append("serra sem ciclo deterministico esperavel")
	var alavancas: Dictionary = desc.get("alavancas", {})
	var portao: Dictionary = desc.get("portao", {})
	if not alavancas.has("A") or not alavancas.has("B"):
		erros.append("faltam as duas alavancas")
	if portao.get("exige", []) != ["A", "B"]:
		erros.append("portao nao exige A e B")
	return {
		"passou": erros.is_empty(),
		"erros": erros,
		"altura_salto_duplo": altura_max,
		"rotas": {
			"A_B": ["entrada", "degrau_1", "degrau_2", "degrau_3",
				"A", "parede_baixa", "vao_inferior", "espinhos", "B", "saida"],
			"B_A": ["entrada", "parede_baixa", "vao_inferior", "espinhos",
				"B", "espinhos", "vao_inferior", "parede_baixa",
				"degrau_1", "degrau_2", "degrau_3", "A", "saida"],
		},
	}


func _ready() -> void:
	call_deferred("_construir")


func _construir() -> void:
	var W := largura
	var H := altura
	var d := clampf(dificuldade, 0.0, 1.0)
	var logica := descricao_logica(W, H, d, seed_layout)

	# --- casca -------------------------------------------------------
	_parede(Vector2(W * 0.5, ESP * 0.5), Vector2(W + ESP, ESP))          # chão
	_parede(Vector2(W * 0.5, -H - ESP * 0.5), Vector2(W + ESP, ESP))     # tecto
	# parede esquerda com vão de entrada em baixo
	_parede(Vector2(-ESP * 0.5, -(H + GAP) * 0.5), Vector2(ESP, H - GAP))
	# parede direita com vão de saída em baixo (fechado pela porta)
	_parede(Vector2(W + ESP * 0.5, -(H + GAP) * 0.5), Vector2(ESP, H - GAP))

	# --- caminho em Z: 2 paredes internas ---------------------------
	var x1 := W * 0.36
	var x2 := W * 0.66
	# parede 1: sobe do chão, ~110 px -> salta-se por cima
	_parede(Vector2(x1, -55.0), Vector2(ESP, 110.0))
	# parede 2: desce do tecto, deixa GAP ao chão -> passa-se por baixo
	_parede(Vector2(x2, -(H + GAP) * 0.5), Vector2(ESP, H - GAP))

	# --- alcova ESQUERDA (alavanca A), em cima ---------------------
	# degraus para subir + ledge com a alavanca perto do tecto
	for k in 3:
		_plat(Vector2(70.0 + k * 90.0, -110.0 - k * 90.0), Vector2(78.0, 18.0))
	_plat(Vector2(70.0 + 2 * 90.0, -110.0 - 2 * 90.0 - 6.0), Vector2(120.0, 18.0))
	_alavanca(Vector2(70.0 + 2 * 90.0, -110.0 - 2 * 90.0 - 26.0))
	# serra a guardar a descida
	var serras: Array = logica["serras"]
	var serra_a: Dictionary = serras[0]
	_serra(serra_a["pos"], serra_a["percurso"], serra_a["tempo"])

	# --- alcova DIREITA (alavanca B), em baixo, depois da parede 2 --
	var ax := W * 0.82
	_espinhos(Vector2(ax - 120.0, -4.0), 3 + int(3.0 * d))
	_alavanca(Vector2(ax, -26.0))
	if d > 0.3:
		var mob := DEMONIO.instantiate()
		mob.especie = especie_inimigo
		mob.position = Vector2(ax - 40.0, -46.0)
		mob.alcance_patrulha = 90.0 + 120.0 * d
		add_child(mob)

	# --- porta da saída (as DUAS alavancas) -----------------------
	var pt := PORTA_T.instantiate()
	pt.id = id
	pt.tamanho = Vector2(26.0, H - GAP)
	pt.position = Vector2(W - 4.0, -(H + GAP) * 0.5)
	pt.exige_todas = true
	add_child(pt)

	# serra extra no corredor central em dificuldades altas
	if d > 0.5:
		var serra_b: Dictionary = serras[1]
		_serra(serra_b["pos"], serra_b["percurso"], serra_b["tempo"])


# --- helpers -------------------------------------------------------

func _parede(pos: Vector2, tam: Vector2) -> void:
	var p := PLAT.instantiate()
	p.position = pos
	p.tamanho = tam
	add_child(p)


func _plat(pos: Vector2, tam: Vector2) -> void:
	var p := PLAT.instantiate()
	p.position = pos
	p.tamanho = tam
	add_child(p)


func _espinhos(pos: Vector2, larg: int) -> void:
	var e := ESPINHOS.instantiate()
	e.position = pos
	e.largura = clampi(larg, 3, 8)
	e.dano = 16 + int(10.0 * clampf(dificuldade, 0.0, 1.0))
	add_child(e)


func _serra(pos: Vector2, percurso: Vector2, tempo: float) -> void:
	var s := SERRA.instantiate()
	s.position = pos
	s.percurso = percurso
	s.tempo = tempo
	add_child(s)


func _alavanca(pos: Vector2) -> void:
	var a := ALAVANCA.instantiate()
	a.id = id
	a.so_liga = true
	a.position = pos
	add_child(a)
