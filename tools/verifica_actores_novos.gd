extends SceneTree
## Prova que os cinco actores novos de 5 set 2026 (3.a leva) fazem mesmo o
## que dizem: `Iman`, `ChaoQuente`, `Ceifa`, `PlataformaOlhar`, `Ariete`.
##
## Todos constroem a propria area/corpo em codigo e nenhum tem cena de
## editor onde se veja se esta' certo -- sem esta bancada so' se saberia a
## jogar, e a jornada tem 100 niveis para procurar.
##
## Uso: Godot --headless --script res://tools/verifica_actores_novos.gd

const IMAN := preload("res://scripts/iman.gd")
const CHAO_QUENTE := preload("res://scripts/chao_quente.gd")
const CEIFA := preload("res://scripts/ceifa.gd")
const ARIETE := preload("res://scripts/ariete.gd")
const PLAT_OLHAR := preload("res://scenes/actors/PlataformaOlhar.tscn")
const ZONA_ESTADO := preload("res://scripts/zona_estado.gd")
const ZONA_GELO := preload("res://scripts/zona_gelo.gd")
const ZONA_ESCURIDAO := preload("res://scripts/zona_escuridao.gd")
const ZONA_SEM_AR := preload("res://scripts/zona_sem_ar.gd")
const SERPENTE := preload("res://scripts/serpente.gd")
## A Koliani carrega-se em RUNTIME (nao com `preload`): o script dela usa
## autoloads pelo nome e isso nao compila em `--script`.
const KOLIANI := "res://scenes/actors/Koliani.tscn"
## Nao se preload a `Alavanca`: o script dela usa `Som` pelo nome e em
## `--script` isso nao compila. O ariete fala com ela por NOME
## (`get`/`set`/`mudou`), portanto um duble chega e prova a mesma coisa.

var _falhas := 0
var _sala: Node2D


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   %s" % msg)
	else:
		print("  FALHA %s" % msg)
		_falhas += 1


## Um corpo de mentira que serve de Koliani: `_olha_para` e o grupo, que e'
## tudo o que estes actores lhe pedem.
func _duble(pos: Vector2) -> CharacterBody2D:
	var gd := GDScript.new()
	gd.source_code = "extends CharacterBody2D\nvar _olha_para := 1.0\nvar levou := 0\n" \
		+ "func receber_dano(q: int, _d: float = 0.0) -> void:\n\tlevou += q\n"
	gd.reload()
	var c := CharacterBody2D.new()
	c.set_script(gd)
	c.collision_layer = 2      # a layer da Koliani -- e' o que as areas mascaram
	c.collision_mask = 1
	var col := CollisionShape2D.new()
	var f := RectangleShape2D.new()
	f.size = Vector2(20.0, 40.0)
	col.shape = f
	c.add_child(col)
	c.add_to_group("koliani")
	c.global_position = pos
	_sala.add_child(c)
	return c


## Espera TEMPO, nao frames. Em headless os frames correm o mais depressa
## que conseguem: 30 frames podem ser 30 ms, e um actor com um ciclo de
## 0.25 s nunca la' chegava. (A primeira versao desta bancada media frames
## e dava tres falhas que nao existiam.)
func _esperar(seg: float) -> void:
	await create_timer(seg).timeout


## Quantas `CanvasLayer` e' que a zona tem penduradas (o veu).
func _tem_camada(n: Node) -> int:
	var c := 0
	for f in n.get_children():
		if f is CanvasLayer:
			c += 1
	return c


func _init() -> void:
	await process_frame
	_sala = Node2D.new()
	root.add_child(_sala)

	# --- IMAN ----------------------------------------------------------
	var im: Node2D = IMAN.new()
	im.raio = 200.0
	im.forca = 800.0
	im.periodo = 0.5
	im.global_position = Vector2(0.0, 0.0)
	_sala.add_child(im)
	var k := _duble(Vector2(120.0, 0.0))
	await _esperar(0.2)
	_ok(k.velocity.x < -10.0,
		"Iman: puxa para o nucleo (vx = %.0f)" % k.velocity.x)
	var sinal0: float = float(im.get("_sinal"))
	# um pouco mais de meio-ciclo e bem menos de um ciclo: o sinal tem de
	# ter invertido UMA vez. (A fisica em headless anda ~10% atrasada em
	# relacao ao relogio, por isso a folga.)
	await _esperar(0.62)
	_ok(float(im.get("_sinal")) != sinal0, "Iman: o sentido inverte no ciclo")
	k.queue_free()
	im.queue_free()
	await process_frame

	# --- CHAO QUENTE ---------------------------------------------------
	var cq: Node2D = CHAO_QUENTE.new()
	cq.tamanho = Vector2(200.0, 40.0)
	cq.paciencia = 0.1
	cq.intervalo = 0.05
	cq.dano = 5
	cq.global_position = Vector2(600.0, 0.0)
	_sala.add_child(cq)
	var k2 := _duble(Vector2(600.0, 0.0))
	k2.velocity = Vector2(200.0, 0.0)     # a mexer-se: nao queima
	await _esperar(0.4)
	_ok(int(k2.get("levou")) == 0,
		"ChaoQuente: a mexer-se nao queima (levou %d)" % int(k2.get("levou")))
	k2.velocity = Vector2.ZERO             # parada: queima
	await _esperar(0.5)
	_ok(int(k2.get("levou")) > 0,
		"ChaoQuente: parada queima (levou %d)" % int(k2.get("levou")))
	cq.queue_free()
	k2.queue_free()
	await process_frame

	# --- CEIFA ---------------------------------------------------------
	var ce: Node2D = CEIFA.new()
	ce.curso = 400.0
	ce.periodo = 0.4
	ce.pausa = 0.05
	ce.global_position = Vector2(1200.0, 0.0)
	_sala.add_child(ce)
	await _esperar(0.1)
	var lam := ce.get_node_or_null("Lamina") as Node2D
	_ok(lam != null, "Ceifa: tem lamina")
	var xs: Array[float] = []
	for _i in 30:
		await create_timer(0.05).timeout
		if lam:
			xs.append(lam.position.x)
	var minx: float = xs.min() if not xs.is_empty() else 0.0
	var maxx: float = xs.max() if not xs.is_empty() else 0.0
	_ok(minx < -150.0 and maxx > 150.0,
		"Ceifa: varre de ponta a ponta (%.0f .. %.0f de 200)" % [minx, maxx])
	ce.queue_free()
	await process_frame

	# --- PLATAFORMA OLHAR ----------------------------------------------
	var po: Node2D = PLAT_OLHAR.instantiate()
	po.global_position = Vector2(2000.0, 0.0)
	_sala.add_child(po)
	var k3 := _duble(Vector2(1700.0, 0.0))    # ela a' ESQUERDA da plataforma
	k3.set("_olha_para", 1.0)                 # virada para a direita = a ve'
	await _esperar(0.1)
	var col3 := po.get_node_or_null("Col") as CollisionShape2D
	_ok(col3 != null and not col3.disabled, "PlataformaOlhar: solida quando ela olha")
	k3.set("_olha_para", -1.0)                # virada ao contrario
	await _esperar(0.6)                        # passa a carencia (0.35 s)
	_ok(col3 != null and col3.disabled,
		"PlataformaOlhar: desaparece quando ela desvia o olhar")
	k3.set("_olha_para", 1.0)
	await _esperar(0.1)
	_ok(col3 != null and not col3.disabled, "PlataformaOlhar: volta assim que olha")
	po.queue_free()
	k3.queue_free()
	await process_frame

	# --- ARIETE --------------------------------------------------------
	# duble de alavanca: `id`, `ligada` e o sinal `mudou`, que e' tudo o que
	# o ariete lhe toca
	var gda := GDScript.new()
	gda.source_code = "extends Node2D
signal mudou(ligada: bool)
" 		+ "var id := \"teste_ar\"
var ligada := false
"
	gda.reload()
	var al := Node2D.new()
	al.set_script(gda)
	al.add_to_group("alavancas")
	al.global_position = Vector2(3000.0, -300.0)
	_sala.add_child(al)
	var ar: Node2D = ARIETE.new()
	ar.id = "teste_ar"
	ar.curso = 60.0
	ar.velocidade = 400.0
	ar.global_position = Vector2(3000.0, 0.0)
	_sala.add_child(ar)
	await _esperar(0.1)
	var x_ini: float = ar.global_position.x
	await _esperar(0.3)
	_ok(is_equal_approx(ar.global_position.x, x_ini),
		"Ariete: sozinho nao anda (%.0f -> %.0f)" % [x_ini, ar.global_position.x])
	# a Koliani encostada atras: ai' sim
	# ela tem de ACOMPANHAR: o ariete afasta-se de quem o empurra, e quem
	# nao anda atras dele sai da zona de empurro (e' isso que se joga)
	var k4 := _duble(Vector2(3000.0 - 72.0, 0.0))
	for _i in 16:
		await create_timer(0.05).timeout
		k4.global_position.x = ar.global_position.x - 72.0
	_ok(ar.global_position.x > x_ini + 20.0,
		"Ariete: com ela atras avanca (%.0f -> %.0f)" % [x_ini, ar.global_position.x])
	_ok(bool(al.get("ligada")), "Ariete: ao chegar ao fim abre a porta (liga a alavanca)")
	k4.queue_free()

	# --- ZONA ESTADO ---------------------------------------------------
	# um duble que so' regista o que lhe chamam: prova que a bolsa MARCA e
	# que continua a renovar enquanto ela la' esta' dentro
	var gde := GDScript.new()
	gde.source_code = "extends CharacterBody2D\nvar env := 0\nvar frio := 0\n" \
		+ "func envenenar(_s: float, _d: int = 4) -> void:\n\tenv += 1\n" \
		+ "func congelar_parcial(_s: float, _e: float = 0.35) -> void:\n\tfrio += 1\n"
	gde.reload()
	for tipo in ["veneno", "frio"]:
		var ze: Node2D = ZONA_ESTADO.new()
		ze.tipo = tipo
		ze.tamanho = Vector2(200.0, 120.0)
		ze.global_position = Vector2(5000.0, 0.0)
		_sala.add_child(ze)
		var kv := CharacterBody2D.new()
		kv.set_script(gde)
		kv.collision_layer = 2
		kv.collision_mask = 1
		var cv := CollisionShape2D.new()
		var fv := RectangleShape2D.new()
		fv.size = Vector2(20.0, 40.0)
		cv.shape = fv
		kv.add_child(cv)
		kv.global_position = Vector2(5000.0, 0.0)
		_sala.add_child(kv)
		await _esperar(1.2)
		var campo := "env" if tipo == "veneno" else "frio"
		_ok(int(kv.get(campo)) >= 2,
			"ZonaEstado(%s): marca e RENOVA enquanto la' esta' (%d vezes)"
				% [tipo, int(kv.get(campo))])
		ze.queue_free()
		kv.queue_free()
		await process_frame

	# --- SERPENTE ------------------------------------------------------
	var se: Node2D = SERPENTE.new()
	se.curso = 400.0
	se.periodo = 0.6
	se.aneis = 4
	se.global_position = Vector2(11000.0, 0.0)
	_sala.add_child(se)
	await _esperar(0.1)
	var cabeca := se.get_child(0) as Node2D
	var sx: Array[float] = []
	for _i in 30:
		await create_timer(0.05).timeout
		if cabeca:
			sx.append(cabeca.position.x)
	var smin: float = sx.min() if not sx.is_empty() else 0.0
	var smax: float = sx.max() if not sx.is_empty() else 0.0
	_ok(smin < -120.0 and smax > 120.0,
		"Serpente: a cabeca atravessa a sala (%.0f .. %.0f de 200)" % [smin, smax])
	# e a cauda vem ATRAS -- nao esta' toda no mesmo sitio
	var cauda := se.get_child(3) as Node2D
	_ok(cauda != null and absf(cauda.position.x - cabeca.position.x) > 10.0,
		"Serpente: a cauda segue a cabeca com atraso")
	se.queue_free()
	await process_frame

	# --- ZONA SEM AR ---------------------------------------------------
	var za: Node2D = ZONA_SEM_AR.new()
	za.tamanho = Vector2(400.0, 300.0)
	za.folego = 0.4
	za.intervalo = 0.2
	za.dano = 3
	za.global_position = Vector2(13000.0, 0.0)
	_sala.add_child(za)
	var kar := _duble(Vector2(13000.0, 0.0))
	await _esperar(1.2)
	_ok(int(kar.get("levou")) > 0,
		"ZonaSemAr: sem ar, afoga-se (levou %d)" % int(kar.get("levou")))
	# uma bolsa de ar por perto e o folego enche-se: para de perder vida
	var bolha := Node2D.new()
	bolha.add_to_group("ar")
	bolha.global_position = kar.global_position
	_sala.add_child(bolha)
	await _esperar(0.4)
	var antes_ar := int(kar.get("levou"))
	await _esperar(1.2)
	_ok(int(kar.get("levou")) == antes_ar,
		"ZonaSemAr: em cima da bolsa de ar nao perde vida (%d -> %d)"
			% [antes_ar, int(kar.get("levou"))])
	za.queue_free()
	kar.queue_free()
	bolha.queue_free()
	await process_frame

	# --- ZONA ESCURIDAO ------------------------------------------------
	# o veu vive numa CanvasLayer que NASCE a' entrada e MORRE a' saida --
	# um veu esquecido por cima do jogo seria pior do que nao haver escuro
	for modo in ["escuro", "areia"]:
		var zx: Node2D = ZONA_ESCURIDAO.new()
		zx.tipo = modo
		zx.tamanho = Vector2(300.0, 200.0)
		zx.transicao = 0.1
		zx.global_position = Vector2(7000.0, 0.0)
		_sala.add_child(zx)
		var kx := _duble(Vector2(6500.0, 0.0))
		await _esperar(0.2)
		_ok(_tem_camada(zx) == 0, "ZonaEscuridao(%s): sem veu de fora" % modo)
		kx.global_position = Vector2(7000.0, 0.0)
		await _esperar(0.3)
		_ok(_tem_camada(zx) == 1, "ZonaEscuridao(%s): o veu aparece la' dentro" % modo)
		kx.global_position = Vector2(6000.0, 0.0)
		await _esperar(0.5)
		_ok(_tem_camada(zx) == 0, "ZonaEscuridao(%s): e sai com ela" % modo)
		zx.queue_free()
		kx.queue_free()
		await process_frame

	# --- OS ESTADOS NA KOLIANI A SERIO ---------------------------------
	var cena_k := load(KOLIANI) as PackedScene
	if cena_k == null:
		_ok(false, "nao se conseguiu carregar a Koliani")
	else:
		# Ela nao fica onde a poem: no `_ready` salta para o checkpoint
		# guardado no save. Sem limpar isso (e sem chao por baixo) o que a
		# bancada media era a QUEDA NO VAZIO -- a primeira versao "provou"
		# um veneno que tirava 158 de vida em 1.2 s, e nao era veneno
		# nenhum.
		var ej := root.get_node_or_null("/root/EstadoJogo")
		if ej:
			ej.set("checkpoint", Vector2.ZERO)
		var ko: Node2D = cena_k.instantiate()
		ko.global_position = Vector2(9000.0, 0.0)
		_sala.add_child(ko)
		await process_frame
		await process_frame
		# o chao vai ter com ela, onde quer que ela tenha ido parar
		var chao := StaticBody2D.new()
		var cc := CollisionShape2D.new()
		var cf := RectangleShape2D.new()
		cf.size = Vector2(3000.0, 60.0)
		cc.shape = cf
		chao.add_child(cc)
		chao.global_position = ko.global_position + Vector2(400.0, 60.0)
		_sala.add_child(chao)
		await _esperar(0.5)
		_ok(bool(ko.call("is_on_floor")),
			"a Koliani da bancada tem de estar POUSADA -- senao mede-se a queda")
		var v0 := int(ko.get("vida"))
		ko.call("envenenar", 3.0, 5)
		await _esperar(1.2)
		var v1 := int(ko.get("vida"))
		_ok(v1 < v0, "Koliani: o veneno tira vida com o tempo (%d -> %d)" % [v0, v1])
		# e passa a' frente dos i-frames: um golpe normal deixa-a
		# invulneravel, e o veneno tem de continuar a morder na mesma
		ko.call("receber_dano", 1, 0.0)
		var v2 := int(ko.get("vida"))
		await _esperar(1.2)
		_ok(int(ko.get("vida")) < v2,
			"Koliani: o veneno passa a' frente dos i-frames (%d -> %d)"
				% [v2, int(ko.get("vida"))])
		# frio: mexe no atrito e passa sozinho
		ko.call("congelar_parcial", 0.5, 0.3)
		await _esperar(0.1)
		_ok(is_equal_approx(float(ko.get("_acel_escala")), 0.3),
			"Koliani: o frio abranda (acel = %.2f)" % float(ko.get("_acel_escala")))
		await _esperar(1.2)
		_ok(is_equal_approx(float(ko.get("_acel_escala")), 1.0),
			"Koliani: o frio passa sozinho (acel = %.2f)" % float(ko.get("_acel_escala")))
		# e a ZonaGelo repoe o atrito a' saida
		var zg: Node2D = ZONA_GELO.new()
		zg.tamanho = Vector2(300.0, 120.0)
		# em cima DELA, onde quer que ela esteja (ver a nota do chao)
		zg.global_position = ko.global_position
		_sala.add_child(zg)
		await _esperar(0.4)
		_ok(float(ko.get("_acel_escala")) < 0.9,
			"ZonaGelo: escorrega la' dentro (acel = %.2f)" % float(ko.get("_acel_escala")))
		ko.global_position += Vector2(900.0, 0.0)
		await _esperar(0.4)
		_ok(is_equal_approx(float(ko.get("_acel_escala")), 1.0),
			"ZonaGelo: a' saida repoe o atrito (acel = %.2f)"
				% float(ko.get("_acel_escala")))

	print("\n=== ACTORES NOVOS: %s ===" %
		("TUDO OK" if _falhas == 0 else "%d FALHA(S)" % _falhas))
	quit(1 if _falhas else 0)
