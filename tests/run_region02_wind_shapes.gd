extends Node2D
## Harness da forma de colisao das zonas de vento (Super-Process A, Fase D).
##
## O bug: `WindZone.tscn` traz um `RectangleShape2D` como sub-recurso e o Godot
## PARTILHA sub-recursos entre instancias da mesma PackedScene. Como o
## `_configurar_forma()` REDIMENSIONA esse recurso, a ultima zona a correr
## `_ready()` impunha o seu tamanho a todas as outras da cena. N08 e N10
## escaparam porque as cenas dao uma forma propria a cada zona; N06/N07/N09
## nao davam.
##
## Este harness mede a forma REAL (o `RectangleShape2D` que a fisica usa), nao
## o export `tamanho` -- que e' o que o contrato estrutural ja' olhava e por
## isso nunca viu o bug.

const CenaWindZone := preload("res://scenes/actors/WindZone.tscn")

const NIVEIS := {
	"N06": "res://scenes/levels/Prisao_dos_Condenados.tscn",
	"N07": "res://scenes/levels/Fornalha_dos_Pecadores.tscn",
	"N08": "res://scenes/levels/Corredor_das_Execucoes.tscn",
	"N09": "res://scenes/levels/Ala_dos_Mortos.tscn",
	"N10": "res://scenes/levels/A_Cela_Zero.tscn",
}

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_executar")


func _executar() -> void:
	await _zonas_soltas()
	await _zonas_dos_niveis()

	if _falhas.is_empty():
		print("OK -- formas das zonas de vento independentes (Region II)")
		get_tree().quit(0)
		return
	for falha in _falhas:
		printerr("FALHOU: ", falha)
	printerr("%d falha(s)" % _falhas.size())
	get_tree().quit(1)


## Duas zonas da MESMA PackedScene com tamanhos diferentes: o caso minimo.
func _zonas_soltas() -> void:
	var palco := Node2D.new()
	add_child(palco)

	var pequena := CenaWindZone.instantiate() as WindZone
	pequena.name = "Pequena"
	pequena.tamanho = Vector2(200.0, 120.0)
	palco.add_child(pequena)

	var grande := CenaWindZone.instantiate() as WindZone
	grande.name = "Grande"
	grande.position = Vector2(2000.0, 0.0)
	grande.tamanho = Vector2(900.0, 600.0)
	palco.add_child(grande)

	await get_tree().physics_frame
	await get_tree().physics_frame

	_medir("solta", pequena)
	_medir("solta", grande)
	var fp := _forma(pequena)
	var fg := _forma(grande)
	_verificar(fp != null and fg != null and fp.get_instance_id() != fg.get_instance_id(),
		"solta: as duas zonas tem recursos de forma DISTINTOS")
	palco.queue_free()
	await get_tree().process_frame


## As cinco cenas reais da Regiao II, ja' no motor (com `_ready()` corrido).
func _zonas_dos_niveis() -> void:
	for nome: String in NIVEIS:
		var cena := load(NIVEIS[nome]) as PackedScene
		if cena == null:
			_falhas.append("%s: cena nao carrega" % nome)
			continue
		var raiz := cena.instantiate()
		add_child(raiz)
		await get_tree().physics_frame
		await get_tree().physics_frame

		var vistas := {}
		var zonas := _zonas(raiz)
		if zonas.is_empty():
			_falhas.append("%s: nenhuma WindZone na cena" % nome)
		for zona in zonas:
			_medir(nome, zona)
			var forma := _forma(zona)
			if forma == null:
				continue
			var id := forma.get_instance_id()
			if vistas.has(id):
				_falhas.append("%s: %s partilha a forma com %s"
					% [nome, zona.name, vistas[id]])
			else:
				vistas[id] = zona.name

		raiz.queue_free()
		await get_tree().process_frame


func _medir(nome: String, zona: WindZone) -> void:
	var forma := _forma(zona)
	if forma == null:
		_falhas.append("%s: %s sem RectangleShape2D" % [nome, zona.name])
		return
	var esperado := Vector2(maxf(1.0, zona.tamanho.x), maxf(1.0, zona.tamanho.y))
	if not forma.size.is_equal_approx(esperado):
		_falhas.append("%s: %s tem forma %s mas o tamanho declarado e' %s"
			% [nome, zona.name, forma.size, esperado])


func _forma(zona: WindZone) -> RectangleShape2D:
	var colisao := zona.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao == null:
		return null
	return colisao.shape as RectangleShape2D


func _zonas(raiz: Node) -> Array[WindZone]:
	var resultado: Array[WindZone] = []
	for filho in raiz.get_children():
		if filho is WindZone:
			resultado.append(filho)
	return resultado


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		_falhas.append(mensagem)
