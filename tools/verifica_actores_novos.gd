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

	print("\n=== ACTORES NOVOS: %s ===" %
		("TUDO OK" if _falhas == 0 else "%d FALHA(S)" % _falhas))
	quit(1 if _falhas else 0)
