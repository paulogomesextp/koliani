class_name LabHud
extends CanvasLayer
## COMBAT LAB v1 -- overlay minimo de teste: Energia, ultimos golpes, janelas (Perfect Dodge /
## Counter / carga), estado dos alvos e a legenda de inputs.

var koliani: Koliani
var lab: CombateLab
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
	if koliani == null or lab == null:
		return
	var t: Array[String] = []
	t.append("COMBAT LAB v1   vida %d   energia %d/99" % [koliani.vida, roundi(koliani.energia_actual())])
	var barra := "#".repeat(roundi(lab.carga() * 10.0)).rpad(10, ".")
	t.append("carga cleave [%s]%s   counter %.2fs   ar %d/2" % [
		barra, " PRONTO" if lab.carga() >= 1.0 else "", lab.janela_counter(), lab._ar_n])
	t.append("golpes: " + "  ".join(lab.log_ultimos))
	for e in get_tree().get_nodes_in_group("lab_inimigos"):
		if is_instance_valid(e) and not e._morto:
			t.append("%s vida %d/%d  %s%s" % [e.lab_tipo, e.vida, e.lab_vida_max(), e.nome_estado(),
				("  guarda %d" % int(e.guarda)) if e.lab_tipo == "golem" else ""])
	if _ajuda:
		t.append("")
		t.append("ATAQUE combo | CIMA+ATAQUE launcher | ATAQUE no ar (x2) | BAIXO+ATAQUE no ar pogo")
		t.append("SEGURAR ATAQUE 0,5 s shadow cleave | DASH+ATAQUE dash attack")
		t.append("ROLL certo -> PERFECT DODGE -> ATAQUE counter | Q especial")
		t.append("1 goblin  2 golem  3 ambos  R reset  P resumo  H ajuda")
	_label.text = "\n".join(t)
