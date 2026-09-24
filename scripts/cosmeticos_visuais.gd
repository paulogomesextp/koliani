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
