extends Node2D
## Script para o nó raiz de um mundo com chefe:
##  - a `Porta` para o mundo seguinte fica selada (`monitoring = false` +
##    tom escuro) até o nó `Chefe` emitir `derrotado`;
##  - prepende uma JORNADA DE APROXIMAÇÃO longa e temática (ver
##    `gerador_corredor.gd`) para que o chefe fique SEMPRE no fim do nível.
##
## `corredor = false` na cena desliga a jornada nesse nível. O último nível
## da campanha (o trono do Zeriko) nunca a tem.

const GERADOR := preload("res://scripts/gerador_corredor.gd")
const CHECKPOINT_SCRIPT := preload("res://scripts/checkpoint.gd")

## Fração de checkpoints a manter (pedido do Paulo, 2 set 2026: havia
## checkpoints a mais). Os que sobrevivem ficam espaçados por distância
## IGUAL ao longo do nível (não pelos primeiros N), sempre com o do
## início e um mesmo antes da sala do chefe.
const FRACAO_CHECKPOINTS := 0.2
## Se o checkpoint mais próximo do chefe ficar mais longe que isto,
## acrescenta-se um novo mesmo antes da sala.
const DIST_MAX_ANTES_CHEFE := 260.0

## Prepende a jornada de aproximação (grande, cresce com o número do nível).
@export var corredor := true

## Nos níveis feitos à mão (`corredor = false`): alonga as plataformas de
## chão largas conforme o número do nível -- N1 fica igual, e vai crescendo
## até ~1.8x no N30. Só estica para a direita e nunca invade a plataforma
## seguinte nem a sala do chefe (não mexe em saltos verticais nem em
## plataformas pequenas de precisão).
@export var alongar_plataformas := true
## Esticão máximo no último nível (N1 = 1.0, N30 = 1.0 + isto).
@export var alongar_ampl := 0.8

## Entrada "fresca" no nível (não é um respawn num checkpoint a meio). É
## capturado em `_enter_tree`, ANTES de a Koliani correr o seu `_ready` (que
## define um checkpoint implícito no ponto de spawn) -- só assim se
## distingue "acabei de entrar" de "morri e voltei ao checkpoint".
var _entrada_fresca := true

@onready var _porta: Area2D = $Porta
@onready var _chefe: Node = get_node_or_null("Chefe")


func _enter_tree() -> void:
	_entrada_fresca = EstadoJogo.checkpoint == Vector2.ZERO


func _ready() -> void:
	if corredor and EstadoJogo.indice_nivel < EstadoJogo.NIVEIS.size() - 1:
		var g := Node2D.new()
		g.name = "CorredorAproximacao"
		g.set_script(GERADOR)
		g.set("entrada_fresca", _entrada_fresca)
		add_child(g)

	if alongar_plataformas and not corredor:
		_alongar_nivel()

	_reduzir_checkpoints.call_deferred()

	if _porta == null:
		return
	if _chefe and _chefe.has_signal("derrotado"):
		_selar(true)
		_chefe.derrotado.connect(_abrir)
	else:
		_selar(false)


func _selar(selada: bool) -> void:
	_porta.monitoring = not selada
	_porta.modulate = Color(0.34, 0.34, 0.4) if selada else Color(1, 1, 1)


func _abrir() -> void:
	_selar(false)


## Corta o número de checkpoints do nível para ~`FRACAO_CHECKPOINTS` do
## total (jornada + sala clássica juntas), mantendo sempre o do início e
## garantindo um mesmo antes da sala do chefe -- os que sobrevivem ficam
## espaçados por distância igual ao longo do nível, não pelos primeiros.
## Corre depois de dois frames para dar tempo à Jornada (que gera os seus
## próprios checkpoints em `_construir`, chamada com `call_deferred` no
## `_ready` dela) de já ter acabado.
func _reduzir_checkpoints() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var meus: Array[Node2D] = []
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if c is Node2D and is_ancestor_of(c):
			meus.append(c)
	if meus.is_empty():
		return
	meus.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

	# garante um checkpoint perto do chefe -- se o mais próximo já lá
	# estiver longe, acrescenta um novo mesmo à entrada da sala.
	if _chefe:
		var bx: float = (_chefe as Node2D).global_position.x
		var by: float = (_chefe as Node2D).global_position.y
		var mais_perto := INF
		for c in meus:
			mais_perto = minf(mais_perto, absf(c.global_position.x - bx))
		if mais_perto > DIST_MAX_ANTES_CHEFE:
			var ck := Area2D.new()
			ck.collision_layer = 16
			ck.collision_mask = 2
			ck.global_position = Vector2(bx - 220.0, by)
			var cf := CollisionShape2D.new()
			var rc := RectangleShape2D.new()
			rc.size = Vector2(52.0, 96.0)
			cf.shape = rc
			ck.add_child(cf)
			ck.set_script(CHECKPOINT_SCRIPT)
			add_child(ck)
			meus.append(ck)
			meus.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

	if meus.size() <= 2:
		return
	var alvo := maxi(2, ceili(meus.size() * FRACAO_CHECKPOINTS))
	if alvo >= meus.size():
		return
	var manter := {}
	manter[meus[0]] = true
	manter[meus[-1]] = true
	var x0: float = meus[0].global_position.x
	var span: float = meus[-1].global_position.x - x0
	if span > 0.0:
		for i in range(1, alvo - 1):
			var alvo_x: float = x0 + span * float(i) / float(alvo - 1)
			var melhor: Node2D = null
			var melhor_d := INF
			for c in meus:
				if manter.has(c):
					continue
				var d := absf(c.global_position.x - alvo_x)
				if d < melhor_d:
					melhor_d = d
					melhor = c
			if melhor:
				manter[melhor] = true
	for c in meus:
		if not manter.has(c):
			c.queue_free()


## Faz o nível MAIS COMPRIDO conforme o número do nível (N1 igual, cresce
## até ~+`alongar_ampl` no N30). Alarga as plataformas de CHÃO da faixa
## baixa e EMPURRA tudo o que vem a seguir pela mesma medida -- os vãos
## entre plataformas ficam iguais (saltos idênticos), o nível é que se
## estica. Poças/casca/atmosfera acompanham.
func _alongar_nivel() -> void:
	var idx := EstadoJogo.indice_nivel
	if idx <= 0:
		return
	var fator := 1.0 + alongar_ampl * (float(idx) / 29.0)
	if fator <= 1.01:
		return

	var lim_dir := INF
	if _chefe and _chefe is Node2D:
		lim_dir = (_chefe as Node2D).position.x - 200.0

	var todas: Array[Node2D] = []
	var chao_largo: Array[Node2D] = []
	for c in get_children():
		if not (c is Node2D) or not ("tamanho" in c):
			continue
		var no := c as Node2D
		todas.append(no)
		var t: Vector2 = no.tamanho
		if t.x >= 240.0 and t.x >= t.y * 3.0:
			chao_largo.append(no)
	if chao_largo.is_empty():
		return
	var y_chao := -INF
	for p in chao_largo:
		y_chao = maxf(y_chao, p.position.y)

	# segmentos de esticão: (borda_direita_original, delta, plataforma). Só
	# plataformas de chão da faixa baixa, antes da sala do chefe, e com um
	# VÃO real (>=40px) a seguir na mesma faixa -- um encosto de plataformas
	# (ex.: carruagens de comboio) não se estica.
	var segs: Array = []
	for p in chao_largo:
		if p.position.y < y_chao - 130.0:
			continue
		var w: float = p.tamanho.x
		var borda_dir: float = p.position.x + w * 0.5
		if borda_dir - w >= lim_dir:
			continue
		var p_esq: float = borda_dir - w
		var folga := INF
		var encostada := false
		for o in todas:
			if o == p or absf(o.position.y - p.position.y) >= 60.0:
				continue
			var ow: float = o.tamanho.x
			var o_esq: float = o.position.x - ow * 0.5
			var o_dir: float = o.position.x + ow * 0.5
			# sobrepõe/toca o intervalo desta plataforma (mais 8px à direita)?
			if o_dir > p_esq + 4.0 and o_esq < borda_dir + 8.0:
				encostada = true
				break
			if o_esq >= borda_dir:
				folga = minf(folga, o_esq - borda_dir)
		if encostada or folga < 40.0:
			continue
		var delta: float = minf(w * (fator - 1.0), 420.0)
		if delta < 8.0:
			continue
		segs.append([borda_dir, delta, p])
	if segs.is_empty():
		return
	segs.sort_custom(func(a, b): return a[0] < b[0])

	var desloc := func(x: float) -> float:
		var s := 0.0
		for seg in segs:
			if seg[0] <= x + 0.5:
				s += seg[1]
		return s

	# aplica: cada filho Node2D desloca em x pela soma dos deltas à sua
	# esquerda; as plataformas esticadas também ganham largura (para a
	# direita, borda esquerda fixa).
	var esticadas := {}
	for seg in segs:
		esticadas[seg[2]] = seg[1]
	for c in get_children():
		if not (c is Node2D):
			continue
		var no := c as Node2D
		if esticadas.has(no):
			var w: float = no.tamanho.x
			var esq: float = no.position.x - w * 0.5
			var d_antes: float = desloc.call(esq - 1.0)
			var nova_w: float = w + esticadas[no]
			no.tamanho = Vector2(nova_w, no.tamanho.y)
			no.position.x = esq + d_antes + nova_w * 0.5
		else:
			no.position.x += desloc.call(no.position.x)

	var total: float = desloc.call(INF)
	# poças mortais / casca / atmosfera acompanham o novo comprimento
	for c in get_children():
		if "largura" in c and ("brasas" in c or "cor" in c):     # AguaVenenosa
			c.largura += total
		elif "largura" in c and c.has_method("_construir"):      # CascaMasmorra
			c.largura += total
			c._construir()
	var atm := get_node_or_null("Atmosfera")
	if atm and atm.has_method("atualizar_extensao"):
		atm.atualizar_extensao(atm.largura_nivel + total + 200.0, atm.extensao_esquerda)

	print("[nivel %d] esticado +%.0f px (fator %.2f, %d segmentos)" % [idx + 1, total, fator, segs.size()])
