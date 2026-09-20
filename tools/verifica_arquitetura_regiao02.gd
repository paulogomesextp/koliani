extends SceneTree
## Contrato estrutural do Prompt 3 da Regiao II.
##
## Prova que cada nivel recebe o landmark certo e nenhum dos outros, que a
## camada e' exclusivamente visual e que tudo fica atras do gameplay. A
## qualidade/composicao continua a depender das capturas com renderer real.

const ESPERADOS := {
	5: "ponte_monumental",
	6: "torre_partida",
	7: "queda_agua",
	8: "altar_ruinas",
	9: "torre_ceus",
}
const TODOS := [
	"ponte_monumental", "torre_partida", "queda_agua", "altar_ruinas",
	"torre_ceus",
]


func _init() -> void:
	Engine.time_scale = 0.0
	await process_frame
	var estado := root.get_node_or_null("/root/EstadoJogo")
	if estado == null:
		push_error("EstadoJogo em falta")
		quit(2)
		return
	var falhas: Array[String] = []
	for indice: int in ESPERADOS:
		estado.modo_teste = true
		estado.indice_nivel = indice
		estado.iniciar_sessao_nivel(true)
		var cena: Node = load(estado.NIVEIS[indice]).instantiate()
		root.add_child(cena)
		for _i in 90:
			await process_frame
		_verificar_nivel(cena, indice, falhas)
		cena.free()
		await process_frame
	print("ARQUITETURA REGIAO II: %d niveis, %d falhas" % [ESPERADOS.size(), falhas.size()])
	for falha in falhas:
		print("  FALHA: ", falha)
	quit(1 if not falhas.is_empty() else 0)


func _verificar_nivel(cena: Node, indice: int, falhas: Array[String]) -> void:
	var camada := cena.get_node_or_null("Atmosfera/ArquiteturaAltitude")
	var rotulo := "N%02d" % (indice + 1)
	if camada == null:
		falhas.append("%s sem camada ArquiteturaAltitude" % rotulo)
		return
	var esperado: String = ESPERADOS[indice]
	for nome: String in TODOS:
		var existe := camada.get_node_or_null(nome) != null
		if nome == esperado and not existe:
			falhas.append("%s sem landmark %s" % [rotulo, esperado])
		elif nome != esperado and existe:
			falhas.append("%s recebeu landmark alheio %s" % [rotulo, nome])
	var sprites := 0
	for filho in camada.get_children():
		if not (filho is Sprite2D):
			falhas.append("%s tem no nao visual %s" % [rotulo, filho.get_class()])
			continue
		var s := filho as Sprite2D
		sprites += 1
		if s.z_index >= 0:
			falhas.append("%s/%s tem z=%d" % [rotulo, s.name, s.z_index])
		if s.texture == null or not s.texture.resource_path.begins_with(
				"res://assets/sprites/pixel/"):
			falhas.append("%s/%s sem textura de producao" % [rotulo, s.name])
		if _tem_fisica(s):
			falhas.append("%s/%s ganhou corpo/colisao" % [rotulo, s.name])
	if sprites < 4:
		falhas.append("%s so tem %d pecas de arquitectura" % [rotulo, sprites])


func _tem_fisica(no: Node) -> bool:
	if no is CollisionShape2D or no is CollisionPolygon2D \
			or no is CollisionObject2D:
		return true
	for filho in no.get_children():
		if _tem_fisica(filho):
			return true
	return false
