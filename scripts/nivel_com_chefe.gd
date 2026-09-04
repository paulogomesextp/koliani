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
const CANDEEIRO := preload("res://scenes/actors/Candeeiro.tscn")
## Só plataformas com ESTE script levam candeeiro (ver `_iluminar`).
const CAMINHO_PLATAFORMA := "res://scripts/plataforma.gd"
## Espaço entre luzes. A luz tem ~240 px de raio: a este passo ficam ilhas de
## luz com escuro entre elas, que é o que dá o ar do Dead Cells. Encurtar
## isto ilumina o nível todo por igual e mata o contraste.
const ESPACO_LUZ := 760.0
## Plataforma mais estreita do que isto não leva poste (fica na berma).
const LARGURA_MIN_LUZ := 115.0
## Até que distância de uma coluna se aceita a plataforma encontrada. Mais do
## que isto e a luz saltava para outra parte do nível só para não faltar.
const BUSCA_LUZ := 950.0
## Recuo às pontas da plataforma.
const MARGEM_LUZ := 52.0
## Só plataformas mais altas do que isto levam tocha na face lateral.
const ALTURA_MIN_TOCHA := 90.0
## Tecto de luzes por nível -- a jornada pode ter dezenas de milhares de px.
const MAX_LUZES := 70
const CHECKPOINT_SCRIPT := preload("res://scripts/checkpoint.gd")

## Espaço mínimo (px) entre checkpoints que sobrevivem à limpeza. O Paulo
## queixou-se de haver checkpoints a mais; a resposta é ESPAÇÁ-LOS, não
## cortar uma percentagem -- assim vale para uma sala de 3000px e para uma
## jornada de 40000px na mesma.
const ESPACO_CHECKPOINT := 2600.0
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

## Candeeiros e tochas ao longo do percurso (ver `_iluminar`).
@export var candeeiros := true
## Cor da luz dos candeeiros. Âmbar quente por omissão: as regiões são
## roxas/azuis e é o contraste quente/frio que faz a luz ler-se.
@export var cor_candeeiro := Color(1.0, 0.76, 0.45)

## Entrada "fresca" no nível (não é um respawn num checkpoint a meio). É
## capturado em `_enter_tree`, ANTES de a Koliani correr o seu `_ready` (que
## define um checkpoint implícito no ponto de spawn) -- só assim se
## distingue "acabei de entrar" de "morri e voltei ao checkpoint".
var _entrada_fresca := true

@onready var _porta: Area2D = $Porta
@onready var _chefe: Node = get_node_or_null("Chefe")
## NÍVEL SEM CHEFE (pedido do Paulo, 3 set 2026: "não precisa ter um boss
## todos os níveis"). Em vez de um chefe, o nível pode acabar num
## GUARDIÃO -- um elite que sela a porta até cair. Dá um clímax ao nível
## sem gastar um chefe: a campanha 31-100 passa a ter um chefe por REGIÃO
## (o último dos cinco) e guardiões nos outros quatro.
@onready var _guardiao: Node = get_node_or_null("Guardiao")


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
	_iluminar.call_deferred()

	if _porta == null:
		return
	if _chefe and _chefe.has_signal("derrotado"):
		_selar(true)
		_chefe.derrotado.connect(_abrir)
	elif _guardiao:
		# o guardião não tem sinal próprio: morrer é sair da árvore
		_selar(true)
		_guardiao.tree_exited.connect(_abrir)
	else:
		_selar(false)


func _selar(selada: bool) -> void:
	_porta.monitoring = not selada
	_porta.modulate = Color(0.34, 0.34, 0.4) if selada else Color(1, 1, 1)


func _abrir() -> void:
	_selar(false)


## Espalha CANDEEIROS e TOCHAS pelo nível. O Paulo: "o jogo está um bocado
## escuro no geral, coloque candeeiros ou lâmpadas a acompanhar os níveis".
##
## Faz-se em código, e não nos 100 `.tscn`, por duas razões: a maior parte do
## percurso é a JORNADA, que é gerada em cada arranque (pôr as luzes na cena
## não apanhava nada dela), e assim vale para os níveis feitos à mão e para
## os gerados sem ter de reescrever tudo.
##
## Uma luz a cada `ESPACO_LUZ`, deixando escuro entre elas -- ilhas de luz,
## não um nível chapado. Só assentam em plataformas ESTÁTICAS (o script tem
## de ser mesmo o `plataforma.gd`): numa flutuante/quebradiça a luz ficava
## para trás quando a plataforma se mexesse ou caísse.
func _iluminar() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or not candeeiros:
		return

	var plats := _plataformas_estaticas()
	if plats.is_empty():
		return
	plats.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.x < b.global_position.x)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("luzes|%d" % EstadoJogo.indice_nivel)

	var suporte := Node2D.new()
	suporte.name = "Luzes"
	# atrás da Koliani e dos inimigos, como a decoração das plataformas
	# (`plataforma.gd` usa -1) -- senão o poste desenha-se por cima dela
	suporte.z_index = -1
	add_child(suporte)

	# Varre-se o percurso em COLUNAS de `ESPACO_LUZ` e, para cada uma,
	# escolhe-se a plataforma mais próxima que sirva. Percorrer as
	# plataformas por ordem, como se fazia antes, deixava vãos de 5800 px às
	# escuras sempre que o troço era feito de plataformas estreitas.
	var x0 := INF
	var x1 := -INF
	for p in plats:
		x0 = minf(x0, p.global_position.x - p.tamanho.x * 0.5)
		x1 = maxf(x1, p.global_position.x + p.tamanho.x * 0.5)

	var postas := 0
	var alvo := x0 + MARGEM_LUZ
	var ultimo := -INF
	while alvo <= x1 and postas < MAX_LUZES:
		var melhor: Node2D = null
		var melhor_x := 0.0
		var melhor_d := INF
		for p in plats:
			var t: Vector2 = p.tamanho
			if t.x < LARGURA_MIN_LUZ:
				continue
			var esq: float = p.global_position.x - t.x * 0.5 + MARGEM_LUZ
			var dir: float = p.global_position.x + t.x * 0.5 - MARGEM_LUZ
			if dir < esq:
				continue
			var px := clampf(alvo, esq, dir)
			var d := absf(px - alvo)
			# desempate pelo CHÃO: entre duas igualmente perto fica a mais
			# baixa, que é por onde se anda
			if d < melhor_d - 1.0 or (d < melhor_d + 1.0 and melhor 					and p.global_position.y > melhor.global_position.y):
				melhor = p
				melhor_x = px
				melhor_d = d
		alvo += ESPACO_LUZ
		if melhor == null or melhor_d > BUSCA_LUZ:
			continue
		if melhor_x - ultimo < ESPACO_LUZ * 0.5:
			continue
		var luz := _fazer_luz(rng, false)
		suporte.add_child(luz)
		luz.global_position = Vector2(
			melhor_x, melhor.global_position.y - melhor.tamanho.y * 0.5)
		ultimo = melhor_x
		postas += 1

	# Tochas na face vertical das plataformas GROSSAS -- as paredes onde um
	# poste não cabe. A grossura que interessa é a VISUAL (`altura_visual`,
	# a laje que desce por baixo da superfície): a colisão anda pelos 22-70
	# px e, medida por ela, nunca nenhuma plataforma chegava ao limiar.
	for p in plats:
		if postas >= MAX_LUZES:
			break
		var t: Vector2 = p.tamanho
		var alt: float = maxf(t.y, p.altura_visual)
		if alt < ALTURA_MIN_TOCHA or t.x < 120.0:
			continue
		if rng.randf() > 0.4:
			continue
		# de um lado ou do outro, encostada à face, a meia altura da laje.
		# O suporte está a z -1 (atrás dos actores) e aí a tocha ficava
		# ESCONDIDA pelo terreno; +1 (relativo) devolve-a ao plano de quem
		# anda no nível, que é onde uma tocha de parede se vê.
		var direita := rng.randf() < 0.5
		var tocha := _fazer_luz(rng, true)
		tocha.set("virado", direita)
		tocha.z_index = 1
		suporte.add_child(tocha)
		var borda: float = t.x * 0.5 - 10.0
		tocha.global_position = Vector2(
			p.global_position.x + (borda if direita else -borda),
			p.global_position.y - t.y * 0.5 + alt * rng.randf_range(0.35, 0.6))
		postas += 1


## Uma plataforma "candeeirável": estática e com o script base. As
## flutuantes/quebradiças/espectrais têm script próprio e ficam de fora.
func _plataformas_estaticas() -> Array[Node2D]:
	var fora: Array[Node2D] = []
	var por_ver: Array[Node] = [self]
	while not por_ver.is_empty():
		var n: Node = por_ver.pop_back()
		for c in n.get_children():
			por_ver.append(c)
		if not (n is StaticBody2D) or not ("tamanho" in n):
			continue
		var sc: Script = n.get_script() as Script
		if sc == null or sc.resource_path != CAMINHO_PLATAFORMA:
			continue
		fora.append(n as Node2D)
	return fora


func _fazer_luz(rng: RandomNumberGenerator, tocha: bool) -> Node2D:
	var no := CANDEEIRO.instantiate() as Node2D
	no.set("tipo", "tocha" if tocha else "candeeiro")
	no.set("cor", cor_candeeiro)
	no.set("alcance", rng.randf_range(0.9, 1.25) * (0.8 if tocha else 1.0))
	no.set("forca", rng.randf_range(1.0, 1.3))
	return no


## Corta os checkpoints do nível para um a cada `ESPACO_CHECKPOINT` (jornada
## + sala clássica juntas), mantendo sempre o do início, o do fim e um mesmo
## antes da sala do chefe. Corre depois de dois frames para dar tempo à
## Jornada (que gera os seus próprios checkpoints em `_construir`, chamada
## com `call_deferred` no `_ready` dela) de já ter acabado.
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
	# Espaçamento por DISTÂNCIA, não por fração (2 set 2026): com a Jornada
	# outra vez ligada os níveis vão dos ~6000px (N1) aos ~40000px (N30) --
	# ficar com 20% dos checkpoints deixava um nível de 37000px com dois, e
	# cada morte custava minutos. Agora guarda-se o primeiro, o último e um
	# a cada `ESPACO_CHECKPOINT`; numa sala curta feita à mão isto continua
	# a dar dois ou três, como o Paulo pediu.
	var manter := {}
	manter[meus[0]] = true
	manter[meus[-1]] = true
	var ultimo_x: float = meus[0].global_position.x
	for i in range(1, meus.size() - 1):
		var cx: float = meus[i].global_position.x
		if cx - ultimo_x >= ESPACO_CHECKPOINT:
			manter[meus[i]] = true
			ultimo_x = cx
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
