class_name CosmeticosVisuais
extends RefCounted
## REGISTRY DOS COSMÉTICOS VISUAIS. Único sítio que traduz
## `EstadoJogo.cosmeticos_equipados` em aparência; koliani/HUD/checkpoint só
## perguntam aqui e nunca têm `if item == ...`. Tudo é PLACEHOLDER de QA
## (tinta/cor), NÃO arte final, e nada toca em stats, colisão ou tempos.
## Item desconhecido ou por equipar => neutro (o visual default).

const NEUTRO := Color.WHITE

## id do item -> tinta multiplicada sobre o corpo da Koliani.
const TINTA_SKIN := {
	"skin_carmesim": Color(1.35, 0.62, 0.7),
	"skin_luar": Color(0.75, 0.9, 1.35),
}
## id -> cor do rasto do dash (o base é `koliani.COR_SHADOWBLADE`).
const COR_RASTO := {
	"efeito_rasto_brasa": Color(1.0, 0.5, 0.12),
}
## id -> tinta da moldura do HUD e chama do checkpoint.
const TINTA_MOLDURA := {
	"hud_moldura_osso": Color(1.5, 1.4, 1.15),
}
const COR_CHAMA_CHECKPOINT := {
	"hud_moldura_osso": Color(0.85, 0.95, 1.0),
}


static func _equipado(categoria: String) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return ""
	var ej: Node = tree.root.get_node_or_null("EstadoJogo")
	return ej.equipado_na_categoria(categoria) if ej else ""


static func tinta_skin(id := "") -> Color:
	return TINTA_SKIN.get(id if id != "" else _equipado("skins"), NEUTRO)


## Devolve `base` se não houver rasto equipado.
static func cor_rasto_dash(base: Color, id := "") -> Color:
	return COR_RASTO.get(id if id != "" else _equipado("efeitos"), base)


static func tinta_moldura_hud(id := "") -> Color:
	return TINTA_MOLDURA.get(id if id != "" else _equipado("hud_checkpoint"), NEUTRO)


## Devolve `base` se não houver moldura equipada.
static func cor_chama_checkpoint(base: Color, id := "") -> Color:
	return COR_CHAMA_CHECKPOINT.get(id if id != "" else _equipado("hud_checkpoint"), base)


## --- Rootbound Frame (hud_moldura_raizes): arte real, não tinta -------------
## Coleção Relíquias do Coração Podre. Os assets vivem só nesta pasta e os
## consumidores (HUD, checkpoint, preview) pedem-nos AQUI -- nunca leem o
## catálogo, a posse ou o save.
const ID_RAIZES := "hud_moldura_raizes"
const DIR_RAIZES := "res://assets/ui/shop/heartrot/rootbound_frame/"
static var _cache_raizes := {}


static func _tex_raizes(nome: String) -> Texture2D:
	if _cache_raizes.has(nome):
		return _cache_raizes[nome]
	var cam := DIR_RAIZES + nome + ".png"
	var t: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
	_cache_raizes[nome] = t
	return t


static func raizes_equipado(id := "") -> bool:
	return (id if id != "" else _equipado("hud_checkpoint")) == ID_RAIZES


## Nine-patch da moldura para um slot do HUD ("disco" = ranhura da arma,
## "placa" = placa do nível). null = HUD original, sem tocar em nada.
static func caixa_hud(slot: String, conteudo: Vector4, margens: Array, id := "") -> StyleBoxTexture:
	if not raizes_equipado(id):
		return null
	var t := _tex_raizes("rootbound_frame" if slot == "disco" else "rootbound_placa")
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


## Visual da fogueira com a Rootbound Frame. {} = fogueira original.
## chama = rampa de 4 cores (bile no miolo, musgo nas pontas); as fagulhas
## são púrpura do coração e discretas.
static func checkpoint_visual(id := "") -> Dictionary:
	if not raizes_equipado(id):
		return {}
	var base := _tex_raizes("base_raizes")
	var cog := _tex_raizes("cogumelos")
	var brilho := _tex_raizes("cogumelos_brilho")
	if base == null or cog == null or brilho == null:
		return {}
	return {
		"base": base, "cogumelos": cog, "brilho": brilho,
		# chama fúngica: núcleo bile, corpo musgo, sem branco-amarelo
		"chama": PackedColorArray([
			Color("B8C24A", 0.95), Color("8FA043", 0.9), Color("5E7A3A", 0.7), Color("1E1712", 0.0)]),
		"nucleo": Color("B8C24A", 0.7),
		"luz": Color("A8B860"),
		"brasas": PackedColorArray([Color("B8C24A", 0.0), Color("B8C24A", 0.85), Color("5E7A3A", 0.0)]),
		"fagulhas": Color("9B3FB0"),
		# lenha escura (madeira podre / casca) em vez do laranja original
		"lenha": Color("2A1E17"),
		"lenha_acesa": Color("3A2A20"),
	}


## Preview real da Loja para um item ("" = sem arte, fica o placeholder).
static func preview_loja(id: String) -> Texture2D:
	return _tex_raizes("preview") if id == ID_RAIZES else null
