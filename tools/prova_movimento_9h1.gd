extends Node
## Execution 9H.1 -- PROVA DE MOVIMENTO.
##
## O Game Master: "Static screenshots are NOT enough. Create frame strips [...]
## The difference in motion must be visually obvious."
##
## Isto corre o JOGO A SÉRIO e fotografa o ecrã frame a frame, compondo uma
## TIRA por acção. Não desenha nada: cada célula da tira é um recorte do
## viewport no instante em que a animação estava naquele ponto.
##
## O que produz, em `<saída>/`:
##   koliani_combo.png       os quatro golpes, um por linha, 8 instantes cada
##   koliani_combo_sem_vfx.png  o mesmo com os arcos de VFX escondidos --
##                           é a pergunta explícita do briefing ("reads
##                           without VFX?")
##   <criatura>.png          idle / run / attack, uma linha cada
##   coracao_fase1.png, coracao_fase2.png
##   prova_movimento.json    o que foi capturado e com que tempos
##
## É uma CENA, não um `--script`: em `--script` os autoloads não existem e os
## scripts dos actores não compilam (lição da 9D).
##
## Uso (PRECISA de janela -- em `--headless` o renderer dummy não desenha):
##   Godot --window --screen 1 --resolution 1280x720 --path . \
##       res://tools/prova_movimento_9h1.tscn -- <pasta_saida>

const NIVEL_L1 := "res://scenes/levels/Floresta_Putrefata.tscn"
const INIMIGO := preload("res://scenes/actors/DemonioBase.tscn")
const KIT := preload("res://scripts/regiao1_kit.gd")

## Criaturas a fotografar e em que nível a arte de produção delas está ligada.
## (espécie, nível 0-based, altura da célula da tira)
const CRIATURAS := [
	["goblin", 0], ["mushroom", 0], ["gosma", 1], ["besouro", 2], ["lodo", 3],
	["ghorak", 0], ["morvanna", 1], ["rainha_aracnidea", 2], ["entrevane", 3],
]
const N_CELULAS := 8
const CELULA := Vector2i(128, 128)
const CELULA_GRANDE := Vector2i(240, 240)
## O Coração é desenhado a 1,7x: numa célula de 240 px só se via o miolo.
const CELULA_BOSS := Vector2i(380, 280)

var _saida := ""
var _registo := {"execucao": "9H.1", "tiras": {}}
var _nivel: Node = null


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else ProjectSettings.globalize_path(
		"res://work/execution_9h1/movimento")
	DirAccess.make_dir_recursive_absolute(_saida)
	_correr.call_deferred()


func _correr() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var es := get_node_or_null("/root/EstadoJogo")
	if es:
		es.modo_dev = true
	await _carregar_nivel(0)
	await _prova_combo()
	await _prova_criaturas()
	await _prova_coracao()
	var f := FileAccess.open(_saida + "/prova_movimento.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_registo, "  "))
		f.close()
	print("prova de movimento -> ", _saida)
	get_tree().quit(0)


func _carregar_nivel(indice: int) -> void:
	if _nivel and is_instance_valid(_nivel):
		_nivel.queue_free()
		await get_tree().process_frame
	var es := get_node_or_null("/root/EstadoJogo")
	if es:
		es.indice_nivel = indice
	var caminho: String = NIVEL_L1
	if indice > 0 and es:
		var lista: Array = es.NIVEIS
		if indice < lista.size():
			caminho = String(lista[indice])
	if not ResourceLoader.exists(caminho):
		caminho = NIVEL_L1
	_nivel = (load(caminho) as PackedScene).instantiate()
	add_child(_nivel)
	for _i in 30:
		await get_tree().process_frame


func _koliani() -> Node2D:
	return _nivel.get_node_or_null("Koliani") as Node2D if _nivel else null


## Um recorte do ECRÃ à volta de `mundo`, já em pixéis do viewport.
func _recorte(mundo: Vector2, tam: Vector2i) -> Image:
	var img := get_viewport().get_texture().get_image()
	# NORMALIZAR O FORMATO PRIMEIRO. O viewport não devolve RGBA8: misturar
	# formatos num `blit_rect` dá uma tira com as cores trocadas e bandas
	# horizontais (foi o que saiu na primeira passagem -- parecia corrupção
	# de memória e era só o formato).
	img.convert(Image.FORMAT_RGBA8)
	var cam := get_viewport().get_camera_2d()
	var centro := mundo
	if cam:
		centro = (mundo - cam.get_screen_center_position()) * cam.zoom \
			+ Vector2(get_viewport().get_visible_rect().size) * 0.5
	# ENCOSTAR em vez de devolver vazio. Quando o alvo cai fora do ecrã, um
	# rectângulo vazio dá uma tira de cor lisa -- e uma tira lisa não prova
	# nada (foi o que saiu na fase 1 do Coração). Encostar o recorte à borda
	# devolve sempre píxeis verdadeiros, e vê-se logo se o alvo lá está.
	var canto := Vector2i(centro) - tam / 2
	canto.x = clampi(canto.x, 0, maxi(0, img.get_width() - tam.x))
	canto.y = clampi(canto.y, 0, maxi(0, img.get_height() - tam.y))
	var r := Rect2i(canto, tam).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if r.size.x <= 0 or r.size.y <= 0:
		var vazio := Image.create(tam.x, tam.y, false, Image.FORMAT_RGBA8)
		vazio.fill(Color(0.06, 0.05, 0.08))
		return vazio
	var corte := img.get_region(r)
	if corte.get_size() != tam:
		var cheio := Image.create(tam.x, tam.y, false, Image.FORMAT_RGBA8)
		cheio.fill(Color(0.06, 0.05, 0.08))
		cheio.blit_rect(corte, Rect2i(Vector2i.ZERO, corte.get_size()), Vector2i.ZERO)
		return cheio
	return corte


func _tira(celulas: Array, tam: Vector2i) -> Image:
	var t := Image.create(tam.x * celulas.size(), tam.y, false, Image.FORMAT_RGBA8)
	t.fill(Color(0.06, 0.05, 0.08))
	for i in celulas.size():
		var c: Image = celulas[i]
		c.convert(Image.FORMAT_RGBA8)
		t.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(i * tam.x, 0))
	return t


func _empilhar(tiras: Array, nome: String) -> void:
	if tiras.is_empty():
		return
	var larg := 0
	var alt := 0
	for t in tiras:
		larg = maxi(larg, (t as Image).get_width())
		alt += (t as Image).get_height()
	var folha := Image.create(larg, alt, false, Image.FORMAT_RGBA8)
	folha.fill(Color(0.06, 0.05, 0.08))
	var y := 0
	for t in tiras:
		var im := t as Image
		folha.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, y))
		y += im.get_height()
	folha.save_png("%s/%s.png" % [_saida, nome])


# ── combo ────────────────────────────────────────────────────────────────

## Os quatro golpes, encadeados como no jogo: carrega em "atacar" dentro da
## janela do golpe anterior. Cada golpe dá uma linha de 8 instantes.
func _capturar_combo(sem_vfx: bool) -> Array:
	var k := _koliani()
	if k == null:
		return []
	var tiras: Array = []
	# do lado de cá, para o combo não cair de um rebordo
	for _i in 20:
		await get_tree().process_frame
	for passo in 4:
		Input.action_press("atacar")
		await get_tree().process_frame
		Input.action_release("atacar")
		var dur: float = float(k.DUR_COMBO[passo])
		var celulas: Array = []
		for i in N_CELULAS:
			if sem_vfx:
				_esconder_vfx(k)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			celulas.append(_recorte(k.global_position + Vector2(0, -22), CELULA))
			await get_tree().create_timer(dur / float(N_CELULAS), false).timeout
		tiras.append(_tira(celulas, CELULA))
		# encadeia: o próximo golpe tem de entrar dentro da JANELA_COMBO
		await get_tree().create_timer(0.06, false).timeout
	_registo["tiras"]["koliani_combo%s" % ("_sem_vfx" if sem_vfx else "")] = {
		"golpes": 4, "instantes": N_CELULAS,
		"duracoes": [k.DUR_COMBO[0], k.DUR_COMBO[1], k.DUR_COMBO[2], k.DUR_COMBO[3]],
	}
	return tiras


## Esconde tudo o que é efeito e deixa só o CORPO (que já traz a
## Shadowblade desenhada). A regra é por exclusão: apaga-se todo o
## descendente visual da Koliani excepto `Sprite/Corpo`. A primeira versão
## ia por nomes e falhava -- os arcos do combo (`_slash_vfx`, `_vfx_combo`)
## nascem em runtime como filhos da PRÓPRIA Koliani, não do `Sprite`.
func _esconder_vfx(koliani: Node) -> void:
	if koliani == null:
		return
	var corpo := koliani.get_node_or_null("Sprite/Corpo")
	for n in koliani.find_children("*", "CanvasItem", true, false):
		if n == corpo or n == koliani.get_node_or_null("Sprite"):
			continue
		if corpo != null and corpo.is_ancestor_of(n):
			continue
		(n as CanvasItem).visible = false
	for n in koliani.find_children("*", "Light2D", true, false):
		(n as Light2D).enabled = false


func _prova_combo() -> void:
	var com := await _capturar_combo(false)
	_empilhar(com, "koliani_combo")
	await _carregar_nivel(0)
	var sem := await _capturar_combo(true)
	_empilhar(sem, "koliani_combo_sem_vfx")


# ── criaturas ────────────────────────────────────────────────────────────

func _prova_criaturas() -> void:
	for par in CRIATURAS:
		var especie: String = par[0]
		var nivel: int = par[1]
		await _carregar_nivel(nivel)
		var k := _koliani()
		if k == null:
			continue
		var pos: Vector2 = k.global_position + Vector2(190, -40)
		var bicho := INIMIGO.instantiate()
		bicho.set("especie", especie)
		bicho.global_position = pos
		_nivel.add_child(bicho)
		for _i in 40:
			await get_tree().process_frame
		var anim := bicho.get_node_or_null("Sprite/Anim") as AnimatedSprite2D
		var tiras: Array = []
		for estado in ["idle", "run", "attack"]:
			if anim == null or anim.sprite_frames == null \
					or not anim.sprite_frames.has_animation(estado):
				continue
			var celulas: Array = []
			var n := anim.sprite_frames.get_frame_count(estado)
			for i in N_CELULAS:
				anim.play(estado)
				anim.set_frame_and_progress(i % n, 0.0)
				anim.pause()
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				celulas.append(_recorte(bicho.global_position + Vector2(0, -26),
					CELULA_GRANDE))
			tiras.append(_tira(celulas, CELULA_GRANDE))
		_empilhar(tiras, especie)
		_registo["tiras"][especie] = {"estados": tiras.size(), "instantes": N_CELULAS}
		bicho.queue_free()
		await get_tree().process_frame


func _prova_coracao() -> void:
	await _carregar_nivel(4)
	var chefe: Node2D = null
	for n in _nivel.get_children():
		if n is Node2D and String(n.name).to_lower().contains("coracao"):
			chefe = n
			break
	if chefe == null:
		for n in _nivel.find_children("*", "CharacterBody2D", true, false):
			if String((n as Node).get_script().resource_path if (n as Node).get_script()
					else "").contains("coracao"):
				chefe = n as Node2D
				break
	if chefe == null:
		_registo["tiras"]["coracao"] = {"erro": "chefe nao encontrado no 1-5"}
		return
	var anim := chefe.get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if anim == null or anim.sprite_frames == null:
		_registo["tiras"]["coracao"] = {"erro": "sem SpriteFrames"}
		return
	# o Coração está no FIM do nível: sem levar a Koliani até lá, a câmara
	# fica na entrada e o recorte sai todo preto (foi o que saiu à primeira)
	# A CÂMARA É FILHA DA KOLIANI e segue-a. Mexer na Koliani não chegou (a
	# câmara ficou em x=-3116 com o chefe em x=+3080, ou seja a 6 mil px de
	# distância) porque a posição volta a ser imposta pela física. O que
	# funciona é tirar a câmara da hierarquia (`top_level`) e pô-la à mão.
	var k := _koliani()
	if k:
		k.global_position = chefe.global_position + Vector2(-150, -40)
	var cam := get_viewport().get_camera_2d()
	if cam:
		cam.top_level = true
		cam.position_smoothing_enabled = false
		cam.limit_left = -100000000
		cam.limit_right = 100000000
		cam.limit_top = -100000000
		cam.limit_bottom = 100000000
		cam.global_position = chefe.global_position + Vector2(0, -40)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in 20:
		await get_tree().process_frame
		if cam:
			cam.global_position = chefe.global_position + Vector2(0, -40)
	print("Coracao em ", chefe.global_position, " camara ",
		get_viewport().get_camera_2d().get_screen_center_position()
			if get_viewport().get_camera_2d() else Vector2.ZERO,
		" anims ", anim.sprite_frames.get_animation_names())
	for fase in [1, 2]:
		var tiras: Array = []
		for estado in (["idle", "attack"] if fase == 1 else ["idle_f2", "attack_f2"]):
			if not anim.sprite_frames.has_animation(estado):
				continue
			var celulas: Array = []
			var n := anim.sprite_frames.get_frame_count(estado)
			for i in N_CELULAS:
				anim.play(estado)
				anim.set_frame_and_progress(i % n, 0.0)
				anim.pause()
				if cam:
					cam.global_position = chefe.global_position + Vector2(0, -40)
					cam.force_update_scroll()
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				celulas.append(_recorte(chefe.global_position + Vector2(0, -50),
					CELULA_BOSS))
			tiras.append(_tira(celulas, CELULA_BOSS))
		_empilhar(tiras, "coracao_fase%d" % fase)
		_registo["tiras"]["coracao_fase%d" % fase] = {"tiras": tiras.size()}
