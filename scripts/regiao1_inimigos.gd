extends RefCounted
## Execution 9D — arte de produção dos inimigos e guardiões da Região I.
##
## Interruptor único, igual ao do kit de ambiente (`regiao1_kit.gd`): só vale
## com o nó `Region1HybridVisualTarget` na cena (grupo `regiao1_kit`) E com a
## entrada do inimigo marcada `PRODUCTION_INTEGRATED` no manifesto. Sem uma
## das duas, o bicho monta a arte de sempre -- nada muda nos outros 95 níveis
## nem nos inimigos cuja arte ainda não existe.
##
## O manifesto guarda, por inimigo, os frames de cada animação (caminho +
## SHA-256). Os tempos de gameplay NÃO vivem aqui: a arte adapta-se às janelas
## que o `DemonioBase`/`ChefeBase` já têm.

const Kit := preload("res://scripts/regiao1_kit.gd")
const DIR := "res://assets/art/regions/region_01_forest/enemies/production"
const MANIFESTO := DIR + "/enemy_production_manifest.json"
const INTEGRADO := "PRODUCTION_INTEGRATED"
## Execution 9E.2: a arte do Coração Putrefacto vive na pasta dos chefes; o
## manifesto dos inimigos regista-a com caminhos `res://` absolutos.
const DIR_BOSS := "res://assets/art/regions/region_01_forest/bosses"

static var _cache: Dictionary = {}


## Caminho `res://` de um frame do manifesto (relativo à pasta dos inimigos,
## ou absoluto).
static func caminho(ficheiro: String) -> String:
	return ficheiro if ficheiro.begins_with("res://") else "%s/%s" % [DIR, ficheiro]


## true se `p` é arte de produção da Região I (inimigos ou chefe).
static func e_producao(p: String) -> bool:
	return p.begins_with(DIR + "/") or p.begins_with(DIR_BOSS + "/")


static func manifesto() -> Dictionary:
	if _cache.is_empty():
		if FileAccess.file_exists(MANIFESTO):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFESTO))
			if d is Dictionary:
				_cache = d
		if _cache.is_empty():
			_cache = {"inimigos": {}}
	return _cache


## Entrada de produção do inimigo `id` (espécie ou rig), ou {} se a arte de
## produção não se aplica aqui (fora da Região I ou ainda por produzir).
static func entrada(no: Node, id: String) -> Dictionary:
	if Kit.alvo(no) == null:
		return {}
	var e: Variant = (manifesto().get("inimigos", {}) as Dictionary).get(id, null)
	if not (e is Dictionary) or String(e.get("status", "")) != INTEGRADO:
		return {}
	return e


## SpriteFrames de produção para `id`, ou null. Cada animação é uma lista de
## PNGs soltos (um por frame), não uma tira -- é o formato do manifesto.
static func sprite_frames(no: Node, id: String) -> SpriteFrames:
	var e := entrada(no, id)
	if e.is_empty():
		return null
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var anims: Dictionary = e.get("animacoes", {})
	for nome: String in anims:
		var a: Dictionary = anims[nome]
		sf.add_animation(nome)
		sf.set_animation_speed(nome, float(a.get("fps", 10.0)))
		sf.set_animation_loop(nome, bool(a.get("ciclo", false)))
		for f: Dictionary in a.get("frames", []):
			var t := load(caminho(f["ficheiro"])) as Texture2D
			if t:
				sf.add_frame(nome, t)
	if not sf.has_animation("idle") or sf.get_frame_count("idle") == 0:
		return null
	return sf
