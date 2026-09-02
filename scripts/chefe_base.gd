class_name ChefeBase
extends DemonioBase
## Base dos chefes de mundo. Herda de `DemonioBase` (vida, dano por
## contacto, flash, estilhaços) e acrescenta o que todos os chefes
## partilham: o sinal `derrotado` (o nível usa-o para abrir a porta), a
## referência à Koliani e um telegrafo (pausa + brilho) antes dos ataques.
##
## Cada chefe concreto herda daqui e implementa o seu `_physics_process`
## com a sua máquina de estados. NÃO usar `DemonioBase` diretamente para
## chefes.

signal derrotado

## Escala visual do chefe (o `Sprite` inteiro, incluindo o `Nucleo`). Cada
## `Chefe*.tscn` põe a sua -- dá variedade de tamanho entre chefes e faz
## todos ficarem maiores que a Koliani. NÃO mexe na `AreaContacto`.
@export var escala_visual := 1.3

## O combate começou a sério (1.ª vez que `provocar()` corre). O HUD usa
## para mostrar a barra de vida do chefe.
signal combate_iniciado(chefe: ChefeBase)
## Vida do chefe mudou (após levar dano). `maximo` = vida no início da luta.
signal vida_mudou(atual: int, maximo: int)

## Vida no arranque da luta (capturada na 1.ª `provocar()`/dano, já depois
## de o chefe concreto ter definido a sua vida no `_ready`).
var _vida_maxima := 0

## Falas de história (só os chefes-narrativa preenchem, no seu `_ready`).
## Cada entrada: `{ "quem": <chave i18n>, "texto": <chave i18n> }`. A INTRO
## corre quando a Koliani entra na arena (antes do combate); a de FIM corre
## quando o chefe cai, antes de a porta abrir. Ver `Dialogo` / `Balao`.
var falas_intro: Array = []
var falas_fim: Array = []
## Distância (px) a que a Koliani dispara a intro.
var gatilho_intro := 330.0
var _intro_feita := false
var _fim_em_curso := false

var _koliani: Node2D
## Fica > 0 durante um golpe forte do chefe (o contacto magoa mais).
var _ataque_forte := 0.0
var _ja_derrotado := false
## true assim que o combate começa (troca a música para a do chefe). Fica
## false num chefe recém-instanciado (após morte/recarga), por isso a
## música só volta a mudar quando a luta recomeça de facto.
var _musica_boss := false

## Escudo brilhante da cor do chefe que aparece enquanto ele está BLINDADO
## (fora da janela EXPOSTA). Bloqueia dano A SÉRIO enquanto tiver cargas
## (pedido do Paulo, 2 set 2026): cada golpe que acerte com o escudo em pé
## gasta uma carga sem tirar vida; à última carga o escudo parte-se de vez
## (mostra "BROKEN SHIELD") e abre-se a janela EXPOSTA, onde os golpes
## tiram vida a sério. `usa_escudo_boss = false` no `_ready` de um chefe
## que leve dano SEMPRE (Carcereiro, Ghorak-da-Floresta).
var usa_escudo_boss := true
## Golpes que o escudo aguenta por ciclo antes de partir. Modesto de
## propósito -- é para dar ritmo ao combate, não tornar os chefes esponja.
const CARGAS_ESCUDO := 2
var _cargas_restantes := 0
var _texto_cargas: Label
## Segundos desde o último golpe que ENTROU (reduziu vida). Enquanto > 0 o
## chefe está na janela EXPOSTA -> escudo escondido.
var _dano_recente := 0.0
var _escudo_boss: Node2D
var _escudo_t := 0.0
var _ajuste_janela_feito := false


func _e_chefe() -> bool:
	return true


func _ready() -> void:
	super._ready()
	add_to_group("chefes")
	# chefe mais perigoso ao contacto à medida que a campanha avança (rampa
	# suave pelos 30 níveis: ~x1.0 no nível 1 -> ~x1.9 no nível 30). A
	# vida-base é definida por cada chefe concreto no seu _ready.
	dano_contacto = int(round(dano_contacto * (1.0 + 0.03 * float(clampi(EstadoJogo.indice_nivel, 0, 29)))))
	if _sprite:
		_sprite.scale = Vector2(_direcao * escala_visual, escala_visual)
	call_deferred("_preparar_escudo_boss")


## Feito em deferred: o `_ready` do chefe concreto já correu e definiu a
## `dur_exposto`/`dur_exposta` -- aqui ALARGA-SE essa janela (menos tempo
## blindado, pedido do Paulo) e monta-se o escudo da cor do chefe.
func _preparar_escudo_boss() -> void:
	for nome in ["dur_exposto", "dur_exposta"]:
		if nome in self:
			var v: float = get(nome)
			if v > 0.0:
				set(nome, v * 1.6)
	if usa_escudo_boss:
		_montar_escudo_boss()


func _montar_escudo_boss() -> void:
	if _escudo_boss != null:
		return
	var cor: Color = cor_rim
	cor.a = 1.0
	var r := 78.0 * maxf(0.8, escala_visual)
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_escudo_boss = Node2D.new()
	_escudo_boss.name = "EscudoBoss"
	_escudo_boss.z_index = 6
	_escudo_boss.visible = false
	if _sprite:
		_escudo_boss.position = _sprite.position
	add_child(_escudo_boss)

	var disco := Polygon2D.new()
	disco.name = "Disco"
	disco.polygon = _circulo_pts(r, 30)
	disco.color = Color(cor.r, cor.g, cor.b, 0.10)
	disco.material = aditivo
	_escudo_boss.add_child(disco)

	var aro := Line2D.new()
	aro.name = "Aro"
	aro.points = _circulo_pts(r, 40)
	aro.closed = true
	aro.width = 4.0
	aro.default_color = Color(cor.r, cor.g, cor.b, 0.9)
	aro.joint_mode = Line2D.LINE_JOINT_ROUND
	aro.material = aditivo
	_escudo_boss.add_child(aro)

	var aro2 := Line2D.new()
	aro2.name = "Aro2"
	aro2.points = _circulo_pts(r * 0.86, 40)
	aro2.closed = true
	aro2.width = 2.0
	aro2.default_color = Color(1, 1, 1, 0.5)
	aro2.material = aditivo
	_escudo_boss.add_child(aro2)

	var luz := PointLight2D.new()
	luz.name = "Luz"
	luz.texture = _tex_luz_escudo()
	luz.color = cor
	luz.energy = 0.9
	luz.scale = Vector2(r / 90.0, r / 90.0)
	_escudo_boss.add_child(luz)

	_texto_cargas = Label.new()
	_texto_cargas.name = "TextoCargas"
	_texto_cargas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto_cargas.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto_cargas.add_theme_font_size_override("font_size", 14)
	_texto_cargas.add_theme_color_override("font_color", cor.lightened(0.5))
	_texto_cargas.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03))
	_texto_cargas.add_theme_constant_override("outline_size", 4)
	_texto_cargas.size = Vector2(200.0, 24.0)
	_texto_cargas.position = Vector2(-100.0, -r - 26.0)
	_escudo_boss.add_child(_texto_cargas)


func _circulo_pts(raio: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(Vector2(cos(a) * raio, sin(a) * raio))
	return pts


static var _TEX_LUZ_ESC: GradientTexture2D

func _tex_luz_escudo() -> GradientTexture2D:
	if _TEX_LUZ_ESC == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
		_TEX_LUZ_ESC = GradientTexture2D.new()
		_TEX_LUZ_ESC.gradient = g
		_TEX_LUZ_ESC.width = 220
		_TEX_LUZ_ESC.height = 220
		_TEX_LUZ_ESC.fill = GradientTexture2D.FILL_RADIAL
		_TEX_LUZ_ESC.fill_from = Vector2(0.5, 0.5)
		_TEX_LUZ_ESC.fill_to = Vector2(1.0, 0.5)
	return _TEX_LUZ_ESC


func _process(dt: float) -> void:
	super._process(dt)
	_dano_recente = maxf(0.0, _dano_recente - dt)
	_atualizar_escudo_boss(dt)
	# rede de segurança: se o chefe se atirar para fora do mapa (investida
	# num fosso, etc.), conta como derrotado -- senão o nível fica
	# bloqueado porque a porta nunca abre.
	if not _ja_derrotado and global_position.y - _origem.y > 520.0:
		_cair_derrotado()
		return
	# intro de história: a Koliani chegou perto -> corre as falas antes da luta
	if not _intro_feita and not _ja_derrotado and not falas_intro.is_empty():
		var k := _obter_koliani()
		if k and global_position.distance_to(k.global_position) < gatilho_intro:
			_intro_feita = true
			_correr_intro()


## O escudo aparece durante o combate SEMPRE que o chefe não levou dano nos
## últimos instantes (= está blindado, fora da janela EXPOSTA). Some quando
## um golpe entra.
func _atualizar_escudo_boss(dt: float) -> void:
	if _escudo_boss == null:
		return
	var mostrar := _musica_boss and not _ja_derrotado and not _fim_em_curso \
		and _dano_recente <= 0.0
	if mostrar != _escudo_boss.visible:
		_escudo_boss.visible = mostrar
		if mostrar:
			_cargas_restantes = CARGAS_ESCUDO  # escudo volta a carregar
			_atualizar_texto_cargas()
	if not mostrar:
		return
	_escudo_t += dt
	var pulso := 1.0 + 0.06 * sin(_escudo_t * 7.0)
	_escudo_boss.scale = Vector2(pulso, pulso)
	var aro := _escudo_boss.get_node_or_null("Aro") as Line2D
	if aro:
		aro.rotation = _escudo_t * 0.8
	var aro2 := _escudo_boss.get_node_or_null("Aro2") as Line2D
	if aro2:
		aro2.rotation = -_escudo_t * 1.3
	var luz := _escudo_boss.get_node_or_null("Luz") as PointLight2D
	if luz:
		luz.energy = 0.8 + 0.35 * (0.5 + 0.5 * sin(_escudo_t * 6.0))


func _correr_intro() -> void:
	await Dialogo.correr(_com_alvo(falas_intro))
	provocar()  # a música de chefe entra ao acabar a conversa


## Copia as falas metendo `self` como alvo da cauda do balão.
func _com_alvo(falas: Array) -> Array:
	var saida: Array = []
	for f: Dictionary in falas:
		var g := (f as Dictionary).duplicate()
		g["alvo"] = self
		saida.append(g)
	return saida


## Marca o início do combate: troca para a música de chefe. Idempotente --
## cada chefe concreto chama isto quando a sua máquina de estados sai da
## patrulha (deteta a Koliani); `chefe_base` também chama ao trocar o
## primeiro golpe. Não basta ver o chefe: é preciso "começar a fight".
func provocar() -> void:
	if _musica_boss or _ja_derrotado:
		return
	_musica_boss = true
	_garantir_vida_maxima()
	Musica.boss()
	combate_iniciado.emit(self)
	vida_mudou.emit(vida, _vida_maxima)


## Regista a vida-cheia da luta (uma vez). Chamado quando o combate começa
## ou ao 1.º dano -- nessa altura o `_ready` do chefe concreto já correu.
func _garantir_vida_maxima() -> void:
	if _vida_maxima <= 0:
		_vida_maxima = maxi(vida, 1)


## Volta à cama de fundo normal do nível (a de chefe entrou em `provocar`).
func _restaurar_musica() -> void:
	if _musica_boss:
		_musica_boss = false
		Musica.ambiente(EstadoJogo.indice_nivel)


func _cair_derrotado() -> void:
	_ja_derrotado = true
	_restaurar_musica()
	Som.toca("chefe_cai", -6.0)
	Som.toca("conquista", -4.0)  # som de "conquista", distinto de matar um inimigo
	derrotado.emit()
	queue_free()


func _obter_koliani() -> Node2D:
	if not is_instance_valid(_koliani):
		_koliani = get_tree().get_first_node_in_group("koliani")
	return _koliani


func _vetor_para_koliani() -> Vector2:
	var k := _obter_koliani()
	return (k.global_position - global_position) if k else Vector2.ZERO


func _dir_para_koliani() -> float:
	var dx := _vetor_para_koliani().x
	return signf(dx) if absf(dx) > 1.0 else _direcao


## Vira o sprite para a Koliani.
func _encarar_koliani() -> void:
	_direcao = _dir_para_koliani()
	if _sprite:
		_sprite.scale = Vector2(_direcao * escala_visual, escala_visual)


func _piscar(ligado: bool) -> void:
	if _sprite:
		_sprite.modulate = Color(1.7, 1.25, 1.5) if ligado else Color(1, 1, 1)
	if ligado:
		anticipacao = 1.0  # wind-up visual (ver DemonioBase._process)


func _ao_tocar(corpo: Node) -> void:
	if corpo is Koliani:
		provocar()  # trocar o primeiro golpe = combate a sério
		var dano := int(round(dano_contacto * (1.8 if _ataque_forte > 0.0 else 1.0)))
		corpo.receber_dano(dano, signf(corpo.global_position.x - global_position.x))


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	_garantir_vida_maxima()
	provocar()  # levou o primeiro golpe = combate a sério
	# escudo de pé com cargas: bloqueia o golpe por completo (sem tirar
	# vida) em vez de abrir logo a janela EXPOSTA. À última carga parte-se.
	if usa_escudo_boss and _escudo_boss and _escudo_boss.visible and _cargas_restantes > 0:
		_cargas_restantes -= 1
		_atualizar_texto_cargas()
		global_position.x += dir_empurrao * 1.5
		Som.toca("bloqueio", -8.0, 0.85)
		if _cargas_restantes <= 0:
			_escudo_boss.visible = false
			_dano_recente = 0.85  # abre a janela EXPOSTA
			_mostrar_texto_quebrado()
		return
	vida -= quantidade
	_dano_recente = 0.85  # golpe entrou -> janela EXPOSTA -> esconde o escudo
	global_position.x += dir_empurrao * 3.0
	vida_mudou.emit(maxi(vida, 0), _vida_maxima)
	if vida <= 0:
		_ja_derrotado = true
		_restaurar_musica()
		if not falas_fim.is_empty():
			_cair_com_falas()
		else:
			Som.toca("chefe_cai", -6.0)
			Som.toca("conquista", -4.0)  # "conquista", distinto de matar um inimigo
			derrotado.emit()
			soltar_estilhacos()
			queue_free()
	else:
		piscar_dano()


func _atualizar_texto_cargas() -> void:
	if _texto_cargas:
		_texto_cargas.text = Textos.tf("chefe.escudo_cargas", [_cargas_restantes])


## Aviso a vermelho no instante em que o escudo parte -- some sozinho.
func _mostrar_texto_quebrado() -> void:
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.22, 0.22))
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.0, 0.0))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.text = Textos.t("chefe.escudo_partido")
	lbl.size = Vector2(240.0, 28.0)
	var base: Vector2 = _sprite.position if _sprite else Vector2.ZERO
	lbl.position = base + Vector2(-120.0, -120.0 * maxf(0.8, escala_visual))
	lbl.z_index = 7
	add_child(lbl)
	var t := create_tween()
	t.tween_interval(0.7)
	t.tween_property(lbl, "modulate:a", 0.0, 0.5)
	t.tween_callback(lbl.queue_free)


## Morte dos chefes-história: congela o chefe, diz as últimas falas e só
## depois abre a porta.
func _cair_com_falas() -> void:
	if _fim_em_curso:
		return
	_fim_em_curso = true
	set_physics_process(false)
	Som.toca("chefe_cai", -6.0)
	await Dialogo.correr(_com_alvo(falas_fim))
	Som.toca("conquista", -4.0)
	derrotado.emit()
	soltar_estilhacos()
	queue_free()
