extends SceneTree
## Troca o desenho de alguns CHEFES por sprites de packs prontos, sem mexer
## nas cenas nem nas mecânicas: o contrato é uma folha de 4 frames
## (`Sprite2D.hframes = 4`) e os chefes usam sempre os mesmos índices --
##   0 = normal · 1 = pose alternativa · 2 = a piscar (dano) · 3 = núcleo à
##   mostra (vulnerável).
##
## A ALTURA da célula é a mesma da folha antiga (é o que fixa o tamanho no
## ecrã, porque a cena não leva escala nova); a LARGURA pode crescer -- o
## sprite é centrado, portanto largura a mais é só ar à volta.
##
##   godot --headless --script res://tools/extrair_chefes_packs.gd

const BOSSES := {
	# Colosso Ósseo (Galeria dos Ossos) <- clembod "Bringer of Death"
	"colosso": {
		"altura": 116,
		"poses": [
			"res://assets/sprites/incoming/clembod/Bringer-Of-Death/Individual Sprite/Idle/Bringer-of-Death_Idle_1.png",
			"res://assets/sprites/incoming/clembod/Bringer-Of-Death/Individual Sprite/Idle/Bringer-of-Death_Idle_4.png",
			"res://assets/sprites/incoming/clembod/Bringer-Of-Death/Individual Sprite/Hurt/Bringer-of-Death_Hurt_1.png",
			"res://assets/sprites/incoming/clembod/Bringer-Of-Death/Individual Sprite/Cast/Bringer-of-Death_Cast_4.png",
		],
	},
	# Bispo Púrpura (Catedral da Corrupção) <- luizmelo "Evil Wizard 2"
	"bispo": {
		"altura": 112,
		"tiras": true,   # ficheiros que são tiras horizontais
		"poses": [
			["res://assets/sprites/incoming/luizmelo/EVil Wizard 2/Sprites/Idle.png", 0],
			["res://assets/sprites/incoming/luizmelo/EVil Wizard 2/Sprites/Idle.png", 4],
			["res://assets/sprites/incoming/luizmelo/EVil Wizard 2/Sprites/Take hit.png", 1],
			["res://assets/sprites/incoming/luizmelo/EVil Wizard 2/Sprites/Death.png", 1],
		],
	},
	# O Olho do Abismo (nivel 20) <- luizmelo "Flying eye" (CC0), o mesmo bicho
	# que ja' serve de inimigo comum "olho", mas em tamanho de CHEFE: e'
	# literalmente o mesmo monstro crescido, o que e' bom para a historia da
	# regiao (o abismo esta' cheio de olhos pequenos).
	"olho": {
		"altura": 96,
		"tiras": true,
		"larg_tira": 150,
		"poses": [
			["res://assets/sprites/incoming/luizmelo/Monsters_Creatures_Fantasy/Flying eye/Flight.png", 0],
			["res://assets/sprites/incoming/luizmelo/Monsters_Creatures_Fantasy/Flying eye/Flight.png", 4],
			["res://assets/sprites/incoming/luizmelo/Monsters_Creatures_Fantasy/Flying eye/Take Hit.png", 1],
			["res://assets/sprites/incoming/luizmelo/Monsters_Creatures_Fantasy/Flying eye/Attack.png", 5],
		],
	},
	# Ghorak, o Guardiao Raiz (nivel 1) <- chierit "Frost Guardian": e' um
	# golem com NUCLEO NO PEITO, que e' exactamente a fraqueza escrita em
	# docs/niveis.md. O gelo e' recolorido para casca, musgo e nucleo roxo.
	"ghorak": {
		"altura": 116,
		"recolor": "raiz",
		"poses": [
			"res://assets/sprites/incoming/chierit/Frost_Guardian_FREE_v1.0/PNG files/idle/idle_1.png",
			"res://assets/sprites/incoming/chierit/Frost_Guardian_FREE_v1.0/PNG files/idle/idle_5.png",
			"res://assets/sprites/incoming/chierit/Frost_Guardian_FREE_v1.0/PNG files/take_hit/take_hit_2.png",
			"res://assets/sprites/incoming/chierit/Frost_Guardian_FREE_v1.0/PNG files/1_atk/1_atk_6.png",
		],
	},
	# Ignivar (Fornalha dos Pecadores) <- chierit "boss demon slime": apesar do
	# nome do pack, é um DEMÓNIO DE FOGO com espadão e chifres em chama.
	"ignivar": {
		"altura": 116,
		"grelha": ["res://assets/sprites/incoming/chierit/boss_demon_slime_FREE_v1.0/spritesheets/demon_slime_FREE_v1.0_288x160_spritesheet.png", 288, 160],
		"poses": [[0, 0], [3, 0], [2, 2], [4, 4]],   # [coluna, linha]
	},
}

## Largura por omissão de um frame nas tiras (o Evil Wizard tem 250; o
## `larg_tira` de cada chefe sobrepõe-se a isto).
const TIRA_LARG := 250


func _init() -> void:
	for nome: String in BOSSES:
		var cfg: Dictionary = BOSSES[nome]
		var alt: int = cfg["altura"]
		var imgs: Array[Image] = []
		for pose in cfg["poses"]:
			var img := _pose(pose, cfg.get("tiras", false), cfg.get("grelha", []),
				int(cfg.get("larg_tira", TIRA_LARG)))
			if img == null:
				push_error("%s: não abriu %s" % [nome, str(pose)])
				return
			if cfg.get("recolor", "") == "raiz":
				_recolor_raiz(img)
			imgs.append(_ajustar(img, alt))
		var cw := 0
		for i in imgs:
			cw = maxi(cw, i.get_width())
		cw += 8
		var folha := Image.create(cw * imgs.size(), alt, false, Image.FORMAT_RGBA8)
		folha.fill(Color(0, 0, 0, 0))
		for i in imgs.size():
			var im: Image = imgs[i]
			folha.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()),
				Vector2i(i * cw + (cw - im.get_width()) / 2, alt - im.get_height()))
		var caminho := "res://assets/sprites/pixel/bosses/%s.png" % nome
		if folha.save_png(caminho) != OK:
			push_error("não gravou " + caminho)
			continue
		print("%-10s %s  (4 frames de %dx%d)" % [nome, caminho, cw, alt])
	print("Feito. Correr --import a seguir.")
	quit(0)


## Uma pose: um ficheiro inteiro, [tira, índice] ou [coluna, linha] numa
## folha em grelha (`grelha` = [ficheiro, largura_celula, altura_celula]).
func _pose(pose: Variant, tiras: bool, grelha: Array, larg_tira: int) -> Image:
	if not grelha.is_empty():
		var folha := Image.load_from_file(grelha[0])
		if folha == null:
			return null
		var cw: int = grelha[1]
		var ch: int = grelha[2]
		var col: int = (pose as Array)[0]
		var lin: int = (pose as Array)[1]
		if (col + 1) * cw > folha.get_width() or (lin + 1) * ch > folha.get_height():
			return null
		return folha.get_region(Rect2i(col * cw, lin * ch, cw, ch))
	if tiras:
		var par: Array = pose
		var tira := Image.load_from_file(par[0])
		if tira == null:
			return null
		var x := int(par[1]) * larg_tira
		if x + larg_tira > tira.get_width():
			return null
		return tira.get_region(Rect2i(x, 0, larg_tira, tira.get_height()))
	return Image.load_from_file(pose)


## Recolor "raiz": o gelo do Frost Guardian vira casca e musgo, e o núcleo
## quente do peito vira ROXO -- é a fraqueza do Ghorak (`docs/niveis.md`).
## A luminância do pixel original é que manda na rampa, por isso o volume e
## as sombras do desenho ficam iguais.
func _recolor_raiz(img: Image) -> void:
	const CASCA := Color(0.20, 0.15, 0.11)
	const MUSGO := Color(0.44, 0.55, 0.30)
	const SECO := Color(0.72, 0.72, 0.52)
	const NUCLEO := Color(0.85, 0.35, 1.0)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var lum := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			# núcleo/brasa: os pixels QUENTES (vermelho por cima do azul)
			if c.r > c.b * 1.15 and c.r > 0.45:
				var f := clampf((c.r - 0.35) / 0.65, 0.0, 1.0)
				img.set_pixel(x, y, NUCLEO.lerp(Color(1, 0.9, 1), f * 0.6))
				continue
			var cor := CASCA.lerp(MUSGO, clampf(lum * 1.6, 0.0, 1.0))
			if lum > 0.62:
				cor = MUSGO.lerp(SECO, clampf((lum - 0.62) / 0.38, 0.0, 1.0))
			img.set_pixel(x, y, Color(cor.r, cor.g, cor.b, c.a))


## Corta o ar à volta, redimensiona (nearest) para a altura-alvo e devolve o
## sprite pronto a assentar na base da célula.
func _ajustar(img: Image, alt_alvo: int) -> Image:
	var caixa := img.get_used_rect()
	if caixa.size.x <= 0 or caixa.size.y <= 0:
		caixa = Rect2i(Vector2i.ZERO, img.get_size())
	var corte := img.get_region(caixa)
	var alvo := int(round(alt_alvo * 0.94))
	var esc := float(alvo) / float(corte.get_height())
	corte.resize(maxi(1, int(round(corte.get_width() * esc))), alvo,
		Image.INTERPOLATE_NEAREST)
	corte.convert(Image.FORMAT_RGBA8)
	return corte
