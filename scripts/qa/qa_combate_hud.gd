class_name QaCombateHud
extends CanvasLayer
## FASE 11 -- overlay minimo da arena de QA de PRODUCAO: Energia, janelas (Perfect Dodge/
## Counter/carga Cleave) e o estado de cada piloto real (vida, peso, guarda quando aplicavel).

var koliani: Koliani
var core: CoreCombate
var _label: Label
var _ajuda := true


func _ready() -> void:
	layer = 50
	_label = Label.new()
	_label.position = Vector2(16, 12)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.92, 0.9, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.1))
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)


func alternar_ajuda() -> void:
	_ajuda = not _ajuda


func _process(_dt: float) -> void:
	if koliani == null or core == null:
		return
	var t: Array[String] = []
	t.append("PRODUCTION COMBAT QA ARENA   vida %d   energia %d/99" % [koliani.vida, roundi(koliani.energia_actual())])
	var barra := "#".repeat(roundi(core.carga() * 10.0)).rpad(10, ".")
	t.append("carga cleave [%s]%s   counter %.2fs" % [
		barra, " PRONTO" if core.carga() >= 1.0 else "", core.janela_counter()])
	t.append("golpes: " + "  ".join(core.log_ultimos))
	for e in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(e) and e is DemonioBase and not (e as DemonioBase)._morto:
			var d := e as DemonioBase
			var extra := ""
			if d.tem_guarda_v1:
				extra = "  guarda %d/%d" % [maxi(0, roundi(d._guarda_v1)), roundi(d.guarda_max_v1)]
			t.append("%s (%s)  vida %d  %s%s" % [d.especie, d.peso, d.vida,
				"PILOTO" if d.piloto_combate_v1 else "legacy", extra])
	if _ajuda:
		t.append("")
		t.append("ATAQUE combo x4 | CIMA+ATAQUE launcher | ATAQUE no ar (x2) | BAIXO+ATAQUE no ar pogo")
		t.append("SEGURAR ATAQUE 0,5 s shadow cleave | DASH+ATAQUE dash attack")
		t.append("ROLL certo -> PERFECT DODGE -> ATAQUE counter | Q especial")
		t.append("1 goblin (Regiao I, N1)  2 golem (N6)  3 ambos  R reset  P resumo  H ajuda")
	_label.text = "\n".join(t)
