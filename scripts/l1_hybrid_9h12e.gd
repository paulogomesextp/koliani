extends RefCounted
## Passe visual exclusivo do perfil L1. Não instancia física nem altera medidas.
const DIR := "res://assets/art/regions/region_01_forest/production/l1_hybrid_9h12e/"

static func tex(nome: String) -> Texture2D:
	return load(DIR + nome + ".png") as Texture2D

static func montar(alvo: Node2D) -> void:
	var nomes := ["01_far_sky_castle", "02_mid_mountains_waterfalls",
		"03_forest_silhouette", "04_ruins_arches", "05_foreground_branches_vines"]
	var fatores := [0.12, 0.26, 0.46, 0.62, 1.08]
	var profundidades := [-30, -27, -24, -21, 9]
	for i in nomes.size():
		var camada: Node2D = alvo._camada("HybridL1_" + nomes[i], profundidades[i], Vector2(fatores[i], 0.08))
		camada.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var textura := tex("layers/" + nomes[i])
		for repeticao in range(-4, 5):
			var s := Sprite2D.new()
			s.texture = textura
			s.centered = false
			s.scale = Vector2(0.95, 0.95)
			s.position = Vector2(alvo.referencia.x - 912.0 + repeticao * 1824.0, 95.0)
			if i == 0:
				s.flip_h = absi(repeticao) % 2 == 1
				s.modulate = Color(0.78, 0.78, 0.82, 1.0)
			elif i == 4:
				s.modulate = Color(0.65, 0.65, 0.72, 0.85)
			else:
				s.modulate = Color(0.6, 0.63, 0.72, 0.65)
			camada.add_child(s)

static func decorar(vis: Node, largura: float, y0: float, alt: float, rng: RandomNumberGenerator) -> void:
	var nomes := ["cristais", "lanterna", "raizes"]
	for i in mini(5, int(largura / 240.0)):
		var s := Sprite2D.new()
		var nome: String = nomes[rng.randi_range(0, nomes.size()-1)]
		s.texture = tex("props_hd/" + nome)
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var escala := 0.38 if nome == "lanterna" else 0.28
		s.scale = Vector2.ONE * escala
		s.position = Vector2(-largura * 0.5 + 45.0 + i * 240.0, y0 - s.texture.get_height() * escala)
		vis.add_child(s)
	if largura >= 160.0 and alt >= 26.0:
		var raiz := Sprite2D.new()
		raiz.texture = tex("props_hd/raizes")
		raiz.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		raiz.centered = false
		raiz.scale = Vector2(0.4, 0.4)
		raiz.position = Vector2(-largura * 0.22, y0 + alt - 8.0)
		vis.add_child(raiz)
