class_name SinoTorre
extends StaticBody2D
## Sino da Torre dos Sinos (Região III / nível 11). Mecânica partilhada:
## bater-lhe (golpe ou projétil da Koliani -- ambos chamam `receber_dano`)
## faz a BADALADA:
##   * alterna o estado de todas as plataformas do grupo "sino_alterna"
##     (colisão + visual): as que estavam sólidas somem, as fantasma
##     ficam sólidas -- o cenário "muda ao som do sino";
##   * gela por uns segundos os inimigos comuns (grupo "inimigos", exceto
##     "chefes") -- ver `DemonioBase.congelar`.
## `recarga` evita disparar várias vezes com o mesmo golpe.
##
## Está na layer 4 (como os inimigos) só para o hitbox/projétil da Koliani
## lhe acertarem; não colide com ninguém fisicamente.

@export var congelar_inimigos := 2.6
@export var recarga := 0.5
## Grupo das plataformas que este sino alterna. Sinos diferentes podem
## controlar secções diferentes.
@export var alterna_grupo := "sino_alterna"
## true = este sino só gela inimigos, não mexe em plataformas nenhumas
## (útil para não baralhar outras secções).
@export var so_congela := false

## Pele aprovada (Regiao III): se preenchida, o sino desenhado por poligonos
## (Corpo/Aro/Brilho/Badalo) esconde-se e mostra-se este sprite. Vazio = igual
## a sempre, e e' o que todos os outros niveis usam.
@export var textura: Texture2D
## Opt-in (N15, "sinos celestiais"): so' responde depois de recolhidos TODOS os
## `FragmentoEco` do nivel (0 = responde sempre, como em todos os outros
## niveis). Antes disso soa surdo e nao mexe em nada.
@export var fragmentos_necessarios := 0

## Cada badalada (golpe ou projetil). O `MecanismoSinos` do N13 escuta-a
## para ler o padrao.
signal badalada(sino: Node)

var _cd := 0.0
var _pele: Sprite2D
var _fragmentos_total := 0
var _usado := false

@onready var _badalo: Node2D = get_node_or_null("Badalo")


func _ready() -> void:
	add_to_group("sinos")
	if fragmentos_necessarios > 0:
		# os fragmentos do nivel: contam-se no arranque (nascem todos com a cena)
		_fragmentos_total = get_tree().get_nodes_in_group("fragmentos_eco").size()
	if textura != null:
		# com pele pintada, tambem o suporte e a corda de placeholder saem: o
		# nivel pendura o sino com a sua propria corrente
		for nome in ["Corpo", "Aro", "Brilho", "Badalo", "Suporte", "Corda"]:
			var n := get_node_or_null(nome) as CanvasItem
			if n:
				n.visible = false
		_pele = Sprite2D.new()
		_pele.texture = textura
		_pele.position = Vector2(0.0, -2.0)
		add_child(_pele)


func _process(dt: float) -> void:
	if _cd > 0.0:
		_cd -= dt


## Chamado por cada `FragmentoEco` recolhido: o sino acende-se com o ultimo.
func fragmento_recolhido() -> void:
	if fragmentos_necessarios <= 0 or _pele == null:
		return
	var feitos := maxi(0, _fragmentos_total - fragmentos_em_falta())
	var f := clampf(float(feitos) / float(maxi(1, _fragmentos_total)), 0.0, 1.0)
	create_tween().tween_property(_pele, "modulate",
		Color(0.8 + 0.7 * f, 0.8 + 0.6 * f, 1.0 + 0.9 * f), 0.4)


func fragmentos_em_falta() -> int:
	if fragmentos_necessarios <= 0:
		return 0
	var vivos := 0
	for fr in get_tree().get_nodes_in_group("fragmentos_eco"):
		if is_instance_valid(fr) and not bool(fr.get("coletado")):
			vivos += 1
	return vivos


func receber_dano(_quantidade: int = 0, _dir: float = 0.0) -> void:
	if _cd > 0.0:
		return
	_cd = recarga
	if fragmentos_em_falta() > 0:
		# surdo: sem os fragmentos, o sino nao acorda
		_onda()
		var som0 := get_node_or_null("/root/Som")
		if som0 and som0.has_method("toca"):
			som0.call("toca", "sino_mecanismo", -20.0, 0.6, 0.03, recarga,
				"sino_surdo_%d" % get_instance_id())
		return
	if fragmentos_necessarios > 0:
		# o sino celestial acorda UMA vez: a escada de ecos nao volta atras
		if _usado:
			return
		_usado = true
	tocar()


## So' o brilho da badalada, sem som nem efeito no cenario: o `MecanismoSinos`
## usa-o para MOSTRAR a ordem (o eco do padrao) e para marcar os ja' certos.
func brilhar(forca := 1.0) -> void:
	var alvo: CanvasItem = _pele if _pele else get_node_or_null("Corpo") as CanvasItem
	if alvo == null:
		return
	alvo.modulate = Color(1.0 + 0.7 * forca, 1.0 + 0.55 * forca, 1.0 + 0.2 * forca)
	create_tween().tween_property(alvo, "modulate", Color.WHITE, 0.55)


func tocar() -> void:
	# A BADALADA -- e o sino da torre NAO usa o som do sino do chefe.
	#
	# `sino_ataque.ogg` esta' em cinco callsites de chefe (Sino Vivo, Vyrak) e
	# foi desenhado como golpe: bate e morre. Este sino faz o contrario --
	# troca o estado do cenario inteiro e gela os inimigos. Com o mesmo
	# ficheiro, a mecanica lia-se como "levei um ataque do sino".
	# `sino_mecanismo` e' badalada limpa e longa: soa a ORDEM, nao a golpe.
	#
	# `recarga` ja' impede o mesmo golpe de disparar duas vezes; a chave de
	# cooldown por INSTANCIA deixa dois sinos diferentes soarem juntos, que e'
	# leitura correcta (sao duas seccoes do cenario a trocar).
	var som := get_node_or_null("/root/Som")
	if som and som.has_method("toca"):
		som.call("toca", "sino_mecanismo", -8.0, 1.0, 0.03,
			recarga, "sino_mecanismo_%d" % get_instance_id())
	if _pele:
		var tp := create_tween()
		tp.tween_property(_pele, "rotation", 0.14, 0.06)
		tp.tween_property(_pele, "rotation", -0.1, 0.12)
		tp.tween_property(_pele, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
		_pele.modulate = Color(1.6, 1.5, 1.2)
		create_tween().tween_property(_pele, "modulate", Color.WHITE, 0.4)
	if _badalo:
		var t := create_tween()
		t.tween_property(_badalo, "rotation", 0.5, 0.06)
		t.tween_property(_badalo, "rotation", -0.4, 0.12)
		t.tween_property(_badalo, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	_onda()
	badalada.emit(self)
	if not so_congela:
		for p in get_tree().get_nodes_in_group(alterna_grupo):
			_alternar(p)
	for e in get_tree().get_nodes_in_group("inimigos"):
		if (e as Node).is_in_group("chefes"):
			continue
		if e.has_method("congelar"):
			e.congelar(congelar_inimigos)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(3.0)


func _alternar(p: Node) -> void:
	# Opt-in (N14): quem sabe responder a' badalada por si (plataformas
	# temporizadas, a corrente do elevador que muda de direcao) fa-lo; os
	# outros alternam o `Col`/`Visual` como sempre.
	if p.has_method("ao_badalar") and bool(p.call("ao_badalar")):
		return
	var col := p.get_node_or_null("Col") as CollisionShape2D
	if col == null:
		return
	var vai_ficar_solida := col.disabled  # estava desligada -> passa a sólida
	col.set_deferred("disabled", not col.disabled)
	var vis := p.get_node_or_null("Visual") as CanvasItem
	if vis:
		create_tween().tween_property(vis, "modulate:a", 1.0 if vai_ficar_solida else 0.16, 0.14)


func _onda() -> void:
	var anel := Line2D.new()
	anel.width = 3.0
	anel.default_color = Color(0.8, 0.85, 1.0, 0.7)
	anel.closed = true
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	anel.points = pts
	add_child(anel)
	var t := anel.create_tween()
	t.tween_property(anel, "scale", Vector2(14, 14), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(anel, "modulate:a", 0.0, 0.5)
	t.tween_callback(anel.queue_free)
