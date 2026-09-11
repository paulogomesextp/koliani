extends RefCounted
## Execution 9G — VFX de produção da Região I (prancha 07, `tools/produzir_vfx_9g.py`).
##
## Interruptor igual ao dos inimigos (`regiao1_inimigos.gd`): só vale com o nó
## `Region1HybridVisualTarget` na cena (grupo `regiao1_kit`) E o manifesto em
## `PRODUCTION_INTEGRATED`. Fora da Região I tudo fica com os efeitos de sempre.
##
## Os efeitos são só visuais: nascem, tocam uma vez e libertam-se. Não tocam em
## hitboxes, dano, tempos nem física. As `SpriteFrames` são montadas uma vez por
## família e partilhadas (nada de carregar texturas por acerto).

const Kit := preload("res://scripts/regiao1_kit.gd")
const DIR := "res://assets/art/regions/region_01_forest/production/vfx_9g"
const MANIFESTO := DIR + "/vfx_manifest.json"
const INTEGRADO := "PRODUCTION_INTEGRATED"

## Velocidade por omissão de cada família (frames por segundo).
const FPS := {
	"spin_slash": 40.0, "heavy_slash": 34.0, "dash_trail": 40.0, "dash_impact": 30.0,
	"roll_dodge": 30.0, "hit_sparks": 30.0, "finisher_burst": 22.0, "hurt_blood": 24.0,
	"land_impact": 22.0, "projectile": 14.0, "charge_aura": 10.0, "defend_shield": 20.0,
	"pickup": 18.0, "death_dissolve": 14.0,
}
## Frames que entram na animação. Os 03/04 do "finisher burst" sobrepõem-se na
## própria prancha (dois rebentamentos na mesma célula) -- ficam de fora.
const USAR := {
	"finisher_burst": [0, 1, 4, 5, 6, 7],
}

static var _m: Dictionary = {}
static var _sf: Dictionary = {}


static func manifesto() -> Dictionary:
	if _m.is_empty():
		if FileAccess.file_exists(MANIFESTO):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFESTO))
			if d is Dictionary:
				_m = d
		if _m.is_empty():
			_m = {"familias": {}}
	return _m


## true se os VFX de produção valem para o nó `no` (está na Região I).
static func ativo(no: Node) -> bool:
	if no == null or not no.is_inside_tree() or Kit.alvo(no) == null:
		return false
	return String(manifesto().get("status", "")) == INTEGRADO


static func _base(familia: String) -> String:
	return familia.trim_suffix("_corrupcao")


static func familia(familia_: String) -> Dictionary:
	return (manifesto().get("familias", {}) as Dictionary).get(familia_, {})


## SpriteFrames partilhadas: animação "fx" (uma vez) e "ciclo" (em laço).
static func frames(familia_: String) -> SpriteFrames:
	if _sf.has(familia_):
		return _sf[familia_]
	var f := familia(familia_)
	if f.is_empty():
		return null
	var lista: Array = f.get("frames", [])
	var indices: Array = USAR.get(_base(familia_), range(lista.size()))
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for nome in ["fx", "ciclo"]:
		sf.add_animation(nome)
		sf.set_animation_speed(nome, float(FPS.get(_base(familia_), 20.0)))
		sf.set_animation_loop(nome, nome == "ciclo")
		for i: int in indices:
			var t := load("%s/%s" % [DIR, lista[i]["ficheiro"]]) as Texture2D
			if t:
				sf.add_frame(nome, t)
	_sf[familia_] = sf
	return sf


## Desvio que põe o ponto de ancoragem da família (centro do rótulo na
## prancha) na origem do nó.
static func desvio(familia_: String) -> Vector2:
	var f := familia(familia_)
	var tam: Array = f.get("tamanho", [0, 0])
	var anc: Array = f.get("ancora", [0, 0])
	return Vector2(float(tam[0]) * 0.5 - float(anc[0]), float(tam[1]) * 0.5 - float(anc[1]))


## Monta o sprite do efeito (sem o pôr na árvore).
static func novo(familia_: String, laco := false) -> AnimatedSprite2D:
	var sf := frames(familia_)
	if sf == null:
		return null
	var s := AnimatedSprite2D.new()
	s.name = "VFX9G_" + familia_
	s.sprite_frames = sf
	s.animation = "ciclo" if laco else "fx"
	s.offset = desvio(familia_)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if String(familia(familia_).get("blend", "add")) == "add":
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		s.material = mat
	return s


## Efeito de uma vez, no mundo (cena corrente), em `pos`. `dur` > 0 estica ou
## encolhe a animação para durar isso. Devolve o sprite (ou null).
static func tocar(onde: Node, familia_: String, pos: Vector2, escala := 1.0, rot := 0.0,
		virar_x := false, virar_y := false, z := 30, dur := -1.0,
		cor := Color(1, 1, 1)) -> AnimatedSprite2D:
	if onde == null or not onde.is_inside_tree():
		return null
	var destino: Node = onde.get_tree().current_scene
	if destino == null:
		destino = onde.get_parent()
	var s := novo(familia_)
	if s == null or destino == null:
		return null
	s.scale = Vector2(-escala if virar_x else escala, -escala if virar_y else escala)
	s.rotation = rot
	s.z_index = z
	s.modulate = cor
	if dur > 0.0:
		var n := s.sprite_frames.get_frame_count("fx")
		s.speed_scale = (float(n) / s.sprite_frames.get_animation_speed("fx")) / dur
	destino.add_child(s)
	s.global_position = pos
	s.animation_finished.connect(s.queue_free)
	s.play("fx")
	return s
