extends Node2D
## Fonte única dos perfis L1–L5 e slots visuais aditivos. Nunca cria geometria.
const MANIFESTO := "res://data/regiao1/remaster.json"
static var _dados: Dictionary = {}
var _slots: Dictionary = {}
var _fatores: Dictionary = {}

static func _carregar() -> Dictionary:
	if _dados.is_empty():
		var ficheiro := FileAccess.open(MANIFESTO, FileAccess.READ)
		assert(ficheiro != null, "Região I: manifesto remaster não disponível")
		var valor: Variant = JSON.parse_string(ficheiro.get_as_text())
		assert(valor is Dictionary and valor.get("schema") == 1, "Região I: schema inválido")
		_dados = valor
	return _dados

static func dados() -> Dictionary:
	return _carregar().duplicate(true)

static func nivel(numero: int) -> Dictionary:
	assert(numero >= 1 and numero <= 5, "Remaster exclusivo da Região I")
	return _carregar()["niveis"][str(numero)].duplicate(true)

static func perfil(numero: int) -> Dictionary:
	return nivel(numero)["visual_atual"]

static func densidade(chave: String) -> float:
	return float(_carregar()["densidades_fundo"][chave])

func montar(numero: int) -> void:
	assert(_slots.is_empty(), "Slots remaster já montados")
	var config := nivel(numero)
	set_meta("level_id", config["level_id"])
	set_meta("tema", config["tema"])
	for id: String in _carregar()["slots"]:
		var spec: Dictionary = _carregar()["slots"][id]
		var camada := Node2D.new()
		camada.name = spec["nome"]
		camada.z_index = int(spec["z"])
		camada.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		camada.set_meta("slot", id)
		camada.set_meta("legado", spec["legado"])
		add_child(camada)
		_slots[id] = camada
		_fatores[id] = Vector2(spec["parallax"][0], spec["parallax"][1])
		for entrada: Dictionary in config["camadas"][id]:
			adicionar(id, entrada)

## textura (pixel ou ilustrada) OU cena VFX Node2D; posição em coordenadas
## locais da câmara de referência. Linear por defeito para assets híbridos.
func adicionar(slot: String, entrada: Dictionary) -> Node2D:
	assert(_slots.has(slot), "Slot visual desconhecido")
	var no: Node2D
	if entrada.has("textura"):
		var sprite := Sprite2D.new()
		sprite.texture = load(entrada["textura"]) as Texture2D
		assert(sprite.texture != null, "Textura remaster inválida")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if entrada.get("pixel", false) else CanvasItem.TEXTURE_FILTER_LINEAR
		no = sprite
	else:
		var cena := load(entrada["cena"]) as PackedScene
		assert(cena != null, "Cena VFX inválida")
		var instancia := cena.instantiate()
		if not (instancia is Node2D) or not _apenas_visual(instancia):
			instancia.free()
			push_error("Região I: cena remaster contém geometria/gameplay")
			return null
		no = instancia
	no.position = Vector2(entrada.get("posicao", [0, 0])[0], entrada.get("posicao", [0, 0])[1])
	no.scale = Vector2(entrada.get("escala", [1, 1])[0], entrada.get("escala", [1, 1])[1])
	no.z_index = int(entrada.get("z_relativo", 0))
	no.modulate = Color(entrada.get("cor", "ffffff"))
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_slots[slot].add_child(no)
	return no

func _apenas_visual(no: Node) -> bool:
	if no is CollisionObject2D or no is CollisionShape2D or no is CollisionPolygon2D:
		return false
	for filho in no.get_children():
		if not _apenas_visual(filho):
			return false
	return true

func atualizar(desvio: Vector2) -> void:
	for id: String in _slots:
		_slots[id].position = desvio * (Vector2.ONE - _fatores[id])
