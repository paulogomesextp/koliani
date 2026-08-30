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

const PLAT := preload("res://scenes/actors/Plataforma.tscn")
const ESPINHOS := preload("res://scenes/actors/Espinhos.tscn")
const SERRA := preload("res://scenes/actors/Serra.tscn")
const DEMONIO := preload("res://scenes/actors/DemonioBase.tscn")
const ALAVANCA := preload("res://scenes/actors/Alavanca.tscn")
const PORTA_T := preload("res://scenes/actors/PortaTrancada.tscn")

const GAP := 108.0   # vão de passagem (por cima/por baixo)
const ESP := 40.0    # espessura das paredes


func _ready() -> void:
	call_deferred("_construir")


func _construir() -> void:
	var W := largura
	var H := altura
	var d := clampf(dificuldade, 0.0, 1.0)

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
	_serra(Vector2(x1 - 80.0, -150.0), Vector2(0.0, 150.0), randf_range(1.4, 2.2))

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
		_serra(Vector2(W * 0.5, -GAP - 30.0), Vector2(0.0, -(H - GAP - 90.0)), randf_range(2.0, 3.0))


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
