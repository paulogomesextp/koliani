extends SceneTree
## Constrói as camadas de fundo GÓTICAS DE INTERIOR (`fundo_pack = "igreja"`)
## a partir da folha de ambiente do pack CC0 Ansimuz "Gothicvania Church"
## (`incoming/gothicvania/.../ENVIRONMENT/backgrounds.png`, 624x192, cinco
## painéis soltos sobre a mesma base #272638).
##
## Gera:
##   backgrounds/igreja/parede.png   -- faixa de parede SEM COSTURA (a base
##       repete-se nas pontas) com janela ogival, nicho de tocha, altar e
##       túmulo espalhados. Camada "Fundo".
##   backgrounds/igreja/pilares.png  -- pilar de crânios recortado (fundo
##       tornado transparente), espaçado. Camadas "Longe"/"Meio".
##   backgrounds/caverna/tumulos.png -- túmulo com gárgula + pilar, também
##       recortados, para dar primeiro plano às Catacumbas (região IV).
##
## Fonte em `incoming/` (`.gdignore`); só os PNG gerados entram no repo.
##
##   godot --headless --script res://tools/gerar_fundos_igreja.gd

const FONTE := "res://assets/sprites/incoming/gothicvania/gothicvania church files/ENVIRONMENT/backgrounds.png"
const DIR_IGREJA := "res://assets/sprites/pixel/backgrounds/igreja"
const DIR_CAVERNA := "res://assets/sprites/pixel/backgrounds/caverna"

## Painéis da folha (x, largura) -- o resto da altura é sempre 192.
const P_JANELA := Vector2i(0, 160)
const P_PILAR := Vector2i(176, 128)
const P_ALTAR := Vector2i(320, 128)
const P_TUMULO := Vector2i(464, 80)
const P_NICHO := Vector2i(560, 64)
const ALT := 192

## Cor de fundo dos painéis -- vira base da parede e chave do recorte.
const BASE := Color(0x27 / 255.0, 0x26 / 255.0, 0x38 / 255.0, 1.0)
const TOLERANCIA := 0.02

const LARG_PAREDE := 768
const LARG_PILARES := 640
const LARG_TUMULOS := 512


func _init() -> void:
	var src := Image.load_from_file(FONTE)
	if src == null:
		push_error("não abriu " + FONTE)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_IGREJA))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_CAVERNA))

	_parede(src)
	_pilares(src)
	_tumulos(src)
	quit()


## Faixa de parede opaca. As pontas ficam só com a cor da base, por isso o
## `motion_mirroring` da Atmosfera repete-a sem costura visível.
func _parede(src: Image) -> void:
	var out := Image.create(LARG_PAREDE, ALT, false, Image.FORMAT_RGBA8)
	out.fill(BASE)
	_colar(out, src, P_JANELA, 48)
	_colar(out, src, P_NICHO, 272)
	_colar(out, src, P_ALTAR, 400)
	_colar(out, src, P_TUMULO, 600)
	# abóbada: o topo da nave perde-se no escuro, a base fica mais presente
	for y in ALT:
		var f := 1.0 - 0.30 * pow(1.0 - float(y) / float(ALT - 1), 1.6)
		for x in LARG_PAREDE:
			var c := out.get_pixel(x, y)
			out.set_pixel(x, y, Color(c.r * f, c.g * f, c.b * f, c.a))
	_gravar(out, "%s/parede.png" % DIR_IGREJA)


## Pilar recortado, sozinho e centrado -- repetido pelo mirroring dá uma
## nave a fugir para o lado.
func _pilares(src: Image) -> void:
	var out := Image.create(LARG_PILARES, ALT, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	_colar(out, src, P_PILAR, 256)
	var antes := out.duplicate() as Image
	_recortar_base(out)
	_tapar_buracos(out, antes)
	_gravar(out, "%s/pilares.png" % DIR_IGREJA)


## Túmulo + pilar recortados, para as Catacumbas terem primeiro plano.
func _tumulos(src: Image) -> void:
	var out := Image.create(LARG_TUMULOS, ALT, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	_colar(out, src, P_TUMULO, 96)
	_colar(out, src, P_PILAR, 300)
	var antes := out.duplicate() as Image
	_recortar_base(out)
	_tapar_buracos(out, antes)
	_gravar(out, "%s/tumulos.png" % DIR_CAVERNA)


func _colar(dst: Image, src: Image, painel: Vector2i, x: int) -> void:
	var reg := src.get_region(Rect2i(painel.x, 0, painel.y, ALT))
	dst.blit_rect(reg, Rect2i(0, 0, painel.y, ALT), Vector2i(x, 0))


## Torna transparente o fundo dos painéis colados, mas SÓ o que está ligado
## às bordas da imagem (inundação a partir do rebordo): assim um pixel da
## cor da base no meio da pedra não abre um buraco no sprite.
func _recortar_base(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var visto := {}
	var fila: Array[Vector2i] = []
	for x in w:
		fila.append(Vector2i(x, 0))
		fila.append(Vector2i(x, h - 1))
	for y in h:
		fila.append(Vector2i(0, y))
		fila.append(Vector2i(w - 1, y))
	while not fila.is_empty():
		var p: Vector2i = fila.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or visto.has(p):
			continue
		visto[p] = true
		var c := img.get_pixel(p.x, p.y)
		if c.a > 0.0 and not _e_base(c):
			continue
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		fila.append(Vector2i(p.x + 1, p.y))
		fila.append(Vector2i(p.x - 1, p.y))
		fila.append(Vector2i(p.x, p.y + 1))
		fila.append(Vector2i(p.x, p.y - 1))


## Tapa os furos que a inundação abriu por dentro da pedra: um pixel que
## ficou transparente mas tem pedra dos QUATRO lados (a ≤ `RAIO` px) volta à
## cor original -- é uma junta entre blocos da cor da base, não fundo.
func _tapar_buracos(img: Image, original: Image) -> void:
	const RAIO := 5
	var w := img.get_width()
	var h := img.get_height()
	var repor: Array[Vector2i] = []
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.0:
				continue
			var fechado := true
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var achou := false
				for k in range(1, RAIO + 1):
					var p := Vector2i(x + d.x * k, y + d.y * k)
					if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
						break
					if img.get_pixel(p.x, p.y).a > 0.0:
						achou = true
						break
				if not achou:
					fechado = false
					break
			if fechado:
				repor.append(Vector2i(x, y))
	for p in repor:
		img.set_pixel(p.x, p.y, original.get_pixel(p.x, p.y))


func _e_base(c: Color) -> bool:
	return absf(c.r - BASE.r) < TOLERANCIA \
		and absf(c.g - BASE.g) < TOLERANCIA \
		and absf(c.b - BASE.b) < TOLERANCIA


func _gravar(img: Image, caminho: String) -> void:
	var erro := img.save_png(caminho)
	if erro != OK:
		push_error("não gravou %s (erro %d)" % [caminho, erro])
		return
	print("gerado: %s (%dx%d)" % [caminho, img.get_width(), img.get_height()])
