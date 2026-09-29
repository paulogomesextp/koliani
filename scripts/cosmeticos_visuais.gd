class_name CosmeticosVisuais
extends RefCounted
## REGISTRY DOS COSMÉTICOS VISUAIS. Único sítio que traduz
## `EstadoJogo.cosmeticos_equipados` em aparência; koliani/HUD/checkpoint só
## perguntam aqui e nunca têm `if item == ...`. As skins de paleta ainda são
## tinta; as molduras e os rastos com arte vivem em MOLDURAS_ARTE / RASTOS.
## Nada toca em stats, colisão ou tempos.
## Item desconhecido ou por equipar => neutro (o visual default).

const NEUTRO := Color.WHITE

## id do item -> tinta multiplicada sobre o corpo da Koliani.
const TINTA_SKIN := {
	"skin_carmesim": Color(1.35, 0.62, 0.7),
	"skin_luar": Color(0.75, 0.9, 1.35),
}


static func _equipado(categoria: String) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return ""
	var ej: Node = tree.root.get_node_or_null("EstadoJogo")
	return ej.equipado_na_categoria(categoria) if ej else ""


static func tinta_skin(id := "") -> Color:
	return TINTA_SKIN.get(id if id != "" else _equipado("skins"), NEUTRO)


## --- RASTOS DO DASH com arte (gerados por `tools/gerar_cosmeticos_loja.py`) --
## eco: tinta da silhueta que fica para trás (shader em `rasto_cosmetico.gd`);
## vfx: tinta do rasto 9G da Região I; a/b: as duas folhas de partículas
## (frames, fps, quantas por eco, vida, velocidade, gravidade, deriva lateral).
const DIR_RASTOS := "res://assets/ui/shop/rastos/"
const RASTOS := {
	"efeito_rasto_brasa": {
		"pasta": "brasa", "eco": Color(1.0, 0.54, 0.2), "vfx": Color(1.0, 0.62, 0.3),
		"a": {"frames": 6, "fps": 11.0, "qtd": 3, "vida": 0.55, "vel": Vector2(-40, -26), "grav": -30.0, "espalha": 12.0},
		"b": {"frames": 4, "fps": 8.0, "qtd": 1, "vida": 0.9, "vel": Vector2(-18, -34), "grav": 10.0, "espalha": 12.0},
	},
	"efeito_rasto_esporos": {
		"pasta": "esporos", "eco": Color(0.68, 0.8, 0.34), "vfx": Color(0.72, 0.86, 0.38),
		"a": {"frames": 6, "fps": 9.0, "qtd": 2, "vida": 0.66, "vel": Vector2(-14, -10), "grav": -6.0, "espalha": 14.0},
		"b": {"frames": 4, "fps": 7.0, "qtd": 1, "vida": 1.1, "vel": Vector2(-26, -8), "grav": 46.0, "espalha": 12.0},
	},
	"efeito_rasto_mariposas": {
		"pasta": "mariposas", "eco": Color(0.78, 0.82, 1.0), "vfx": Color(0.8, 0.84, 1.0),
		"a": {"frames": 4, "fps": 14.0, "qtd": 1, "vida": 1.0, "vel": Vector2(-34, -40), "grav": -8.0, "espalha": 16.0,
			"ciclo": true, "ondula": 10.0},
		"b": {"frames": 4, "fps": 8.0, "qtd": 2, "vida": 0.6, "vel": Vector2(-10, -12), "grav": 0.0, "espalha": 14.0,
			"ciclo": true},
	},
}
static var _cache_rastos := {}


## Cor do eco do dash. Devolve `base` se não houver rasto equipado.
static func cor_rasto_dash(base: Color, id := "") -> Color:
	var r: Dictionary = RASTOS.get(id if id != "" else _equipado("efeitos"), {})
	return r["eco"] if not r.is_empty() else base


## Tinta do rasto 9G (Região I) -- branco = o original.
static func tinta_vfx_dash(id := "") -> Color:
	var r: Dictionary = RASTOS.get(id if id != "" else _equipado("efeitos"), {})
	return r["vfx"] if not r.is_empty() else Color.WHITE


## Tudo o que o `rasto_cosmetico.gd` precisa para emitir as partículas do
## rasto equipado: {id, eco, a: {tex, ...}, b: {tex, ...}}. {} = rasto original.
static func rasto_visual(id := "") -> Dictionary:
	var rid := id if id != "" else _equipado("efeitos")
	if not RASTOS.has(rid):
		return {}
	if _cache_rastos.has(rid):
		return _cache_rastos[rid]
	var d: Dictionary = RASTOS[rid]
	var fora := {"id": rid, "eco": d["eco"]}
	for folha in ["a", "b"]:
		var cam: String = DIR_RASTOS + str(d["pasta"]) + "/particula_" + folha + ".png"
		var t: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
		if t == null:
			return {}
		var cfg: Dictionary = (d[folha] as Dictionary).duplicate()
		cfg["tex"] = t
		fora[folha] = cfg
	_cache_rastos[rid] = fora
	return fora


## Só as molduras SEM arte ficam por tinta (hoje nenhuma): branco = original.
static func tinta_moldura_hud(_id := "") -> Color:
	return NEUTRO


## Devolve `base` se não houver moldura equipada (a chama das molduras com
## arte vem inteira do `checkpoint_visual`).
static func cor_chama_checkpoint(base: Color, _id := "") -> Color:
	return base


## --- MOLDURAS COM ARTE (HUD + fogueira) ------------------------------------
## Cada uma traz: nine-patch do disco e da placa, peças da fogueira (base por
## cima da lenha, frente rente ao chão, brilho da fogueira apagada) com as
## posições locais, e as cores da chama. Os consumidores (HUD, checkpoint,
## preview) pedem-nas AQUI -- nunca leem o catálogo, a posse ou o save.
## Rootbound: `tools/gerar_rootbound.py`; as outras: `tools/gerar_cosmeticos_loja.py`.
const ID_RAIZES := "hud_moldura_raizes"
const DIR_RAIZES := "res://assets/ui/shop/heartrot/rootbound_frame/"
const MOLDURAS_ARTE := {
	"hud_moldura_raizes": {
		"dir": DIR_RAIZES, "disco": "rootbound_frame", "placa": "rootbound_placa",
		"base": "base_raizes", "frente": "cogumelos", "brilho": "cogumelos_brilho",
		"pos_base": Vector2(0, 12), "pos_frente": Vector2(0, 16), "pos_brilho": Vector2(0, 16),
		# chama fúngica: núcleo bile, corpo musgo, sem branco-amarelo
		"chama": [Color("B8C24A", 0.95), Color("8FA043", 0.9), Color("5E7A3A", 0.7), Color("1E1712", 0.0)],
		"nucleo": Color("B8C24A", 0.7), "luz": Color("A8B860"),
		"brasas": [Color("B8C24A", 0.0), Color("B8C24A", 0.85), Color("5E7A3A", 0.0)],
		"fagulhas": Color("9B3FB0"), "ocioso": Color("B8C24A", 0.55),
		# lenha escura (madeira podre / casca) em vez do laranja original
		"lenha": Color("2A1E17"), "lenha_acesa": Color("3A2A20"),
	},
	"hud_moldura_osso": {
		"dir": "res://assets/ui/shop/ossario/", "disco": "moldura", "placa": "placa",
		"base": "base", "frente": "frente", "brilho": "brilho",
		"pos_base": Vector2(0, -1), "pos_frente": Vector2(0, 12), "pos_brilho": Vector2(0, 12),
		# fogo-de-alma: miolo quase branco, corpo turquesa, pontas fundas
		"chama": [Color("E8FFF8", 0.95), Color("9CF5E8", 0.9), Color("37A3A6", 0.65), Color("0E2A30", 0.0)],
		"nucleo": Color("C8FFF6", 0.7), "luz": Color("8CE8E0"),
		"brasas": [Color("E6DBBE", 0.0), Color("E6DBBE", 0.8), Color("8C7C62", 0.0)],
		"fagulhas": Color("F4FFFC"), "ocioso": Color("9CF5E8", 0.5),
		# a lenha são os fémures desenhados na base: a poligonal fica invisível
		"lenha": Color(0, 0, 0, 0), "lenha_acesa": Color(0, 0, 0, 0),
	},
	"hud_moldura_gaiola": {
		"dir": "res://assets/ui/shop/gaiola_aurora/", "disco": "moldura", "placa": "placa",
		"base": "base", "frente": "frente", "brilho": "brilho",
		"pos_base": Vector2(0, -9), "pos_frente": Vector2(0, 12), "pos_brilho": Vector2(0, -9),
		# chama da pedra-da-lua: rosa-pálido, magenta, púrpura
		"chama": [Color("FFD8F6", 0.95), Color("F070D8", 0.9), Color("9B3FB0", 0.65), Color("200A28", 0.0)],
		"nucleo": Color("FFC4F4", 0.7), "luz": Color("E070D0"),
		"brasas": [Color("DCE4F6", 0.0), Color("DCE4F6", 0.85), Color("8C84A6", 0.0)],
		"fagulhas": Color("DCE4F6"), "ocioso": Color("FF7AE6", 0.45),
		"lenha": Color("2E2438"), "lenha_acesa": Color("3E3450"),
	},
}
static var _cache_arte := {}


static func _tex_arte(dir: String, nome: String) -> Texture2D:
	var cam := dir + nome + ".png"
	if _cache_arte.has(cam):
		return _cache_arte[cam]
	var t: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
	_cache_arte[cam] = t
	return t


static func _moldura(id: String) -> Dictionary:
	return MOLDURAS_ARTE.get(id if id != "" else _equipado("hud_checkpoint"), {})


static func raizes_equipado(id := "") -> bool:
	return (id if id != "" else _equipado("hud_checkpoint")) == ID_RAIZES


## Há uma moldura com arte própria equipada (o HUD não tinge o disco por cima).
static func moldura_arte_equipada(id := "") -> bool:
	return not _moldura(id).is_empty()


## Nine-patch da moldura para um slot do HUD ("disco" = ranhura da arma,
## "placa" = placa do nível). null = HUD original, sem tocar em nada.
static func caixa_hud(slot: String, conteudo: Vector4, margens: Array, id := "") -> StyleBoxTexture:
	var m := _moldura(id)
	if m.is_empty():
		return null
	var t := _tex_arte(m["dir"], m["disco"] if slot == "disco" else m["placa"])
	if t == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.texture_margin_left = margens[0]
	sb.texture_margin_top = margens[1]
	sb.texture_margin_right = margens[2]
	sb.texture_margin_bottom = margens[3]
	sb.content_margin_left = conteudo.x
	sb.content_margin_top = conteudo.y
	sb.content_margin_right = conteudo.z
	sb.content_margin_bottom = conteudo.w
	return sb


## Visual da fogueira com a moldura equipada. {} = fogueira original.
## base/cogumelos(frente)/brilho: texturas; pos_*: posições locais; chama =
## rampa de 4 cores; brasas = 3; o resto são cores soltas.
static func checkpoint_visual(id := "") -> Dictionary:
	var m := _moldura(id)
	if m.is_empty():
		return {}
	var base := _tex_arte(m["dir"], m["base"])
	var frente := _tex_arte(m["dir"], m["frente"])
	var brilho := _tex_arte(m["dir"], m["brilho"])
	if base == null or frente == null or brilho == null:
		return {}
	return {
		"base": base, "cogumelos": frente, "brilho": brilho,
		"pos_base": m["pos_base"], "pos_frente": m["pos_frente"], "pos_brilho": m["pos_brilho"],
		"chama": PackedColorArray(m["chama"]), "nucleo": m["nucleo"], "luz": m["luz"],
		"brasas": PackedColorArray(m["brasas"]), "fagulhas": m["fagulhas"], "ocioso": m["ocioso"],
		"lenha": m["lenha"], "lenha_acesa": m["lenha_acesa"],
	}


## Preview real da Loja para um item ("" = sem arte, fica o placeholder).
## Vem do campo `preview` do catálogo, mas só para itens SEM `placeholder`.
static func preview_loja(id: String) -> Texture2D:
	var it := LojaCatalogo.item(id)
	if it.is_empty() or bool(it.get("placeholder", true)):
		return null
	var cam: String = str(it.get("preview", ""))
	if cam == "":
		return null
	if _cache_arte.has(cam):
		return _cache_arte[cam]
	var t: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
	_cache_arte[cam] = t
	return t
