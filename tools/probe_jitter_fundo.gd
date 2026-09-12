extends SceneTree
## Sonda de TREMOR do fundo (Execution 9H.13/14).
##
## O Game Master diz que o fundo do L2 "treme constantemente em movimento".
## Tremor não se vê num screenshot -- só em movimento, e só comparando o que
## a câmara faz com o que o fundo faz NO MESMO frame de desenho.
##
## O que isto mede, por frame desenhado, com a Koliani a correr para a
## direita com input real:
##
##   cam_x   `Camera2D.get_screen_center_position().x` (o que a câmara mostra)
##   par_x   `ParallaxBackground.scroll_offset.x` (o que o fundo assume)
##   eco_x   posição NA TELA de uma camada com `motion_scale = m`:
##           `par_x * m - cam_x * m`  -- ou seja, o erro entre os dois.
##
## Com câmara e fundo em fase, `d(eco)/dframe` é praticamente constante. Se o
## fundo for actualizado a passo de FÍSICA e a câmara a passo de DESENHO
## (interpolação física ligada), o `eco` avança aos soluços: alguns frames a
## zero, outros a dobrar. É esse padrão que se procura.
##
## Uso:
##   Godot --window --screen 1 --resolution 640x360 \
##     --script res://tools/probe_jitter_fundo.gd -- <cena> [frames]

const FRAMES_AQUECER := 24


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0] if args.size() > 0 else "res://scenes/levels/Pantano_dos_Sussurros.tscn"
	var n_frames: int = int(args[1]) if args.size() > 1 else 180
	## "nosmooth" desliga o `position_smoothing` da camara; "nointerp" desliga
	## a interpolacao fisica. Servem para ISOLAR a causa -- ver relatorio.
	var variante: String = args[2] if args.size() > 2 else ""

	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		var i := int(es.NIVEIS.find(cena))
		if i >= 0:
			es.indice_nivel = i
		es.checkpoint = Vector2.ZERO
	change_scene_to_file(cena)
	for _i in 6:
		await process_frame

	var koliani := get_first_node_in_group("koliani")
	if koliani == null:
		push_error("SONDA: koliani nao encontrada em %s" % cena)
		quit(1)
		return

	# Parallax: pode estar na Atmosfera (legado) ou solto na cena.
	var par := _achar_parallax(root)
	var cam := root.get_viewport().get_camera_2d()
	if cam != null and variante == "nosmooth":
		cam.position_smoothing_enabled = false
	if variante == "nointerp":
		root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	print("SONDA cena=%s parallax=%s camara=%s smoothing=%s interp_projecto=%s" % [
		cena,
		"nao" if par == null else par.get_path(),
		"nao" if cam == null else cam.get_path(),
		"?" if cam == null else str(cam.position_smoothing_enabled),
		str(ProjectSettings.get_setting("physics/common/physics_interpolation", false)),
	])
	if par == null or cam == null:
		quit(1)
		return

	Input.action_press("mover_direita")
	for _i in FRAMES_AQUECER:
		await process_frame
	var dir := "mover_direita"

	var m := 0.2  # motion_scale representativo de uma camada distante
	var eco_ant := INF
	var par_ant := 0.0
	var _ult := 0.0
	var parado := 0
	var v_max := 0.0
	var desde_virou := 99
	var deltas: Array[float] = []
	var linhas: Array[String] = []
	for i in n_frames:
		await process_frame
		# Inverter a marcha a cada 40 frames: encostada a uma parede nao se
		# mede tremor nenhum (foi assim que o 1.o ensaio deu 141/150 parada).
		if i > 0 and i % 40 == 0:
			Input.action_release(dir)
			dir = "mover_esquerda" if dir == "mover_direita" else "mover_direita"
			Input.action_press(dir)
		cam = root.get_viewport().get_camera_2d()
		if cam == null:
			break
		# `ct` e' a transformacao de canvas REALMENTE usada para desenhar o
		# mundo neste frame -- ja' com interpolacao fisica. E' contra ela, e
		# nao contra `get_screen_center_position()`, que o fundo tem de andar.
		var ct := root.get_viewport().get_canvas_transform().origin.x
		var cam_x := -ct
		var par_x := par.scroll_offset.x
		# Posicao NA TELA de uma camada de fundo com `motion_scale = m` menos a
		# posicao na tela que ela DEVIA ter se acompanhasse a camara desenhada.
		var eco := par_x * m - cam_x * m
		var dt := root.get_process_delta_time()
		if i > 0 and i % 40 == 0:
			desde_virou = 0
		desde_virou += 1
		# REGIME PERMANENTE apenas: a velocidade maxima, e pelo menos 20 frames
		# depois de inverter a marcha. Nas inversoes a camara acelera de
		# proposito (look-ahead de 112 px) -- medir la' e' medir o design, nao
		# tremor. Foi o que estragou o ensaio anterior.
		var vx: float = absf((koliani as CharacterBody2D).velocity.x)
		v_max = maxf(v_max, vx)
		var anda: bool = vx > v_max * 0.98 and desde_virou > 20
		if not anda:
			parado += 1
		if eco_ant != INF and dt > 0.0 and anda:
			# VELOCIDADE na tela (px/s), nao avanco por frame: com vsync
			# desligado os frames tem duracoes muito diferentes e o avanco por
			# frame varia PROPORCIONALMENTE -- isso e' correcto, nao e' tremor.
			# Tremor e' a velocidade a oscilar.
			deltas.append(absf(par_x - par_ant) * m / dt)
		eco_ant = eco
		_ult = par_ant
		par_ant = par_x
		if i >= 60 and i < 84:
			linhas.append("  f%02d ct=%10.3f par=%10.3f  atraso=%8.3f  anda=%s" % [
				i, -cam_x, par_x, par_x - (-cam_x), str(anda),
			])
	Input.action_release(dir)

	for l in linhas:
		print(l)

	if deltas.size() < 4:
		print("SONDA: amostra insuficiente")
		quit(1)
		return
	var soma := 0.0
	for d in deltas:
		soma += d
	var media := soma / float(deltas.size())
	var var_ := 0.0
	var maxi := -INF
	var mini := INF
	var zeros := 0
	for d in deltas:
		var_ += (d - media) * (d - media)
		maxi = maxf(maxi, d)
		mini = minf(mini, d)
		if absf(d) < 0.0005:
			zeros += 1
	var dp := sqrt(var_ / float(deltas.size()))
	print("SONDA frames_parada=%d" % parado)
	print("SONDA (velocidade na tela, px/s) n=%d media=%.4f dp=%.4f min=%.4f max=%.4f zeros=%d (%.0f%%)" % [
		deltas.size(), media, dp, mini, maxi, zeros,
		100.0 * float(zeros) / float(deltas.size()),
	])
	# Veredicto: o fundo treme se o passo do `eco` variar muito face ao passo
	# medio, ou se houver frames parados a alternar com frames a dobrar.
	var razao := dp / maxf(absf(media), 0.0001)
	print("SONDA razao_dp_media=%.2f  -> %s" % [
		razao, "TREME" if razao > 0.5 or zeros > deltas.size() / 5 else "suave",
	])
	quit(0)


func _achar_parallax(n: Node) -> ParallaxBackground:
	if n is ParallaxBackground:
		return n as ParallaxBackground
	for f in n.get_children():
		var r := _achar_parallax(f)
		if r != null:
			return r
	return null
