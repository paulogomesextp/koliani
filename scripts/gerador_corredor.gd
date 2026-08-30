class_name GeradorCorredor
extends Node2D
## Prepende um CORREDOR DE APROXIMAÇÃO à esquerda do sítio onde a Koliani
## nasce: chão contínuo + paredes verticais (escalar/saltar) + espinhos +
## inimigos, e a partir do nível 3 uma PortaTrancada com a sua Alavanca.
## O comprimento e o número de perigos CRESCEM com o número do nível.
##
## É aditivo -- não toca na geometria feita à mão do nível. Só é preciso
## largar um nó destes na cena (ver `nivel_com_chefe.gd`, que o faz sozinho
## a não ser que `corredor = false`).

@export var comprimento_base := 620.0
@export var por_nivel := 140.0
@export var comprimento_max := 4200.0
## Espécie dos inimigos do corredor ("" = copia de um inimigo do nível).
@export var especie_inimigo := ""

const SEG := 300.0
const PLAT := preload("res://scenes/actors/Plataforma.tscn")
const ESPINHOS := preload("res://scenes/actors/Espinhos.tscn")
const DEMONIO := preload("res://scenes/actors/DemonioBase.tscn")
const ALAVANCA := preload("res://scenes/actors/Alavanca.tscn")
const PORTA_T := preload("res://scenes/actors/PortaTrancada.tscn")


func _ready() -> void:
	call_deferred("_construir")


func _construir() -> void:
	var kol := get_tree().get_first_node_in_group("koliani")
	if kol == null:
		return
	var join: Vector2 = (kol as Node2D).global_position
	var chao_y := join.y + 76.0
	var idx := EstadoJogo.indice_nivel
	var dif := clampf(float(idx) / 29.0, 0.0, 1.0)
	var comp: float = minf(comprimento_base + por_nivel * float(idx), comprimento_max)
	var n_seg := int(ceil(comp / SEG))
	var x0 := join.x - float(n_seg) * SEG
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("corredor|%d" % idx)
	var esp := especie_inimigo if especie_inimigo != "" else _especie_do_nivel()

	# chão contínuo do corredor (encosta ao chão do nível no `join`)
	var chao := PLAT.instantiate()
	add_child(chao)
	var largura_chao := join.x - x0 + SEG
	chao.position = Vector2((x0 + join.x) * 0.5, chao_y + 24.0)
	chao.tamanho = Vector2(largura_chao, 48.0)
	chao.altura_visual = 90.0

	# a Koliani arranca no início do corredor (só se não vier de um checkpoint)
	if EstadoJogo.checkpoint == Vector2.ZERO:
		(kol as Node2D).global_position = Vector2(x0 + 70.0, chao_y - 60.0)

	for i in n_seg:
		var sx := x0 + float(i) * SEG + SEG * 0.5
		var r := rng.randf()
		# parede vertical -- SEMPRE saltável (~55-100 px); o escalar_paredes
		# só a torna trivial. A dificuldade vem da densidade, não da altura.
		if r < 0.30 + 0.20 * dif:
			var alt := rng.randf_range(55.0, 100.0)
			var w := PLAT.instantiate()
			add_child(w)
			w.position = Vector2(sx, chao_y - alt * 0.5)
			w.tamanho = Vector2(44.0, alt)
		elif r < 0.52 + 0.16 * dif:
			var e := ESPINHOS.instantiate()
			add_child(e)
			e.position = Vector2(sx, chao_y - 2.0)
			e.largura = clampi(4 + int(3.0 * dif), 4, 7)
			e.dano = 14 + int(10.0 * dif)
		if i > 0 and rng.randf() < 0.32 + 0.45 * dif:
			var d := DEMONIO.instantiate()
			add_child(d)
			d.especie = esp
			d.position = Vector2(sx + rng.randf_range(-60.0, 60.0), chao_y - 44.0)
			d.alcance_patrulha = rng.randf_range(80.0, 170.0)

	# porta trancada + alavanca (a partir do nível 3). A alavanca ENTRA
	# PRIMEIRO na árvore para a porta a encontrar no grupo ao ligar-se.
	if idx >= 2:
		var px := x0 + comp * 0.6
		var lid := "corredor_%d" % idx
		var poleiro := PLAT.instantiate()
		add_child(poleiro)
		poleiro.position = Vector2(px - 150.0, chao_y - 74.0)
		poleiro.tamanho = Vector2(110.0, 18.0)
		var al := ALAVANCA.instantiate()
		add_child(al)
		al.id = lid
		al.so_liga = true
		al.position = Vector2(px - 150.0, chao_y - 88.0)
		var pt := PORTA_T.instantiate()
		add_child(pt)
		pt.id = lid
		pt.tamanho = Vector2(24.0, 156.0)
		pt.position = Vector2(px, chao_y - 78.0)


func _especie_do_nivel() -> String:
	for d in get_tree().get_nodes_in_group("inimigos"):
		if "especie" in d:
			return d.especie
	return "goblin"
