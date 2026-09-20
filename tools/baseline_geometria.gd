extends SceneTree
## BASELINE FUNCIONAL de um nível -- o que NÃO pode mudar quando se mexe só
## em arquitetura e props.
##
## A jornada destes níveis é procedural mas DETERMINÍSTICA
## (`gerador_corredor.gd`: `_rng.seed = hash("jornada4|%d" % _idx)`), por
## isso o mesmo nível dá sempre o mesmo mundo. Isso torna possível uma
## comparação exacta: grava-se isto antes, mexe-se, grava-se depois, e o
## `diff` tem de ser VAZIO.
##
## Só se grava o que é FUNCIONAL:
##   - colisões (forma, extensão, posição global) -- o chão e as paredes
##   - plataformas, perigos, checkpoints, porta, spawn, arena do chefe
##
## O que é decorativo (`Sprite2D`, `Line2D`, luzes, partículas, o nó
## `Atmosfera`) fica DE FORA de propósito: props novos e paredes novas não
## podem aparecer aqui, senão o teste não distinguia "pus uma estátua" de
## "mexi no chão".
##
## Uso:
##   godot --headless --path . --script res://tools/baseline_geometria.gd \
##       -- <indice_do_nivel> <ficheiro.txt>

const DECORATIVOS := [
	"Sprite2D", "AnimatedSprite2D", "Line2D", "PointLight2D",
	"DirectionalLight2D", "GPUParticles2D", "CPUParticles2D",
	"ParallaxBackground", "ParallaxLayer", "CanvasLayer", "ColorRect",
	"TextureRect", "Label", "Polygon2D",
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("uso: -- <indice> <saida.txt>")
		quit(1)
		return
	var indice := int(args[0])
	var saida := String(args[1])

	# TEMPO PARADO. Os perigos que se movem (a `Serra` faz um tween
	# `base -> base+percurso -> base`) perdem a posicao de origem assim que
	# o tween arranca, e duas corridas do MESMO nivel davam diffs de menos
	# de 1 px so' por terem demorado tempos diferentes -- ruido que
	# escondia o que o teste quer ver. Com `time_scale = 0` os tweens nao
	# avancam e cada movel fica onde o gerador o pos. A construcao nao
	# depende do relogio (e' toda em `call_deferred`), por isso nao se
	# perde nada.
	Engine.time_scale = 0.0
	await process_frame
	var estado := root.get_node("/root/EstadoJogo")
	estado.modo_teste = true
	estado.indice_nivel = indice
	estado.iniciar_sessao_nivel(true)

	var caminho: String = estado.NIVEIS[indice]
	var cena: Node = load(caminho).instantiate()
	root.add_child(cena)
	# a jornada constrói-se em `call_deferred`; 90 frames chegam de sobra e
	# não dependem do relógio (headless corre tão depressa quanto pode).
	for _i in 90:
		await process_frame

	var linhas: Array[String] = []
	linhas.append("NIVEL %d  %s" % [indice, caminho])
	_recolher(cena, linhas)
	# ordena para o diff não acusar mudanças de ORDEM de criação, que não
	# são funcionais -- o que interessa é o conjunto.
	linhas.sort()
	var f := FileAccess.open(saida, FileAccess.WRITE)
	f.store_string("\n".join(linhas) + "\n")
	f.close()
	print("BASELINE nivel %d: %d entradas -> %s" % [indice, linhas.size(), saida])
	quit(0)


func _recolher(no: Node, fora: Array[String]) -> void:
	var classe := no.get_class()
	if not DECORATIVOS.has(classe):
		var p := _posicao(no)
		if no is CollisionShape2D:
			fora.append("COLISAO %s %s %s" % [p, _forma(no.shape), _estado(no)])
		elif no is CollisionPolygon2D:
			fora.append("POLIGONO %s %d pontos" % [p, no.polygon.size()])
		elif no is Area2D or no is CharacterBody2D or no is StaticBody2D \
				or no is RigidBody2D or no is AnimatableBody2D:
			fora.append("CORPO %s %s %s" % [classe, p, _identidade(no)])
		elif no is Marker2D or no is Path2D:
			fora.append("MARCA %s %s" % [classe, p])
	for filho in no.get_children():
		_recolher(filho, fora)


## O `disabled` de uma colisão, EXCEPTO nas plataformas rítmicas.
##
## A `PlataformaRitmada` liga e desliga a colisão ao ritmo de
## `Time.get_ticks_msec()` -- RELOGIO DE PAREDE, que o
## `Engine.time_scale = 0` nao congela. O estado instantaneo dela depende de
## ha' quanto tempo o processo arrancou, e duas corridas do MESMO nivel
## davam `disabled` diferente ora numa plataforma ora noutra. Isso nao e'
## geometria -- a posicao, o tamanho e o `periodo` sao identicos, e sao
## esses que este ficheiro guarda. Registar o estado delas era acusar
## regressoes que nao existem: custou uma investigacao inteira no nivel 77.
func _estado(c: CollisionShape2D) -> String:
	var dono := c.get_parent()
	if dono and dono.is_in_group("plataformas_ritmadas"):
		return "ritmada"
	return str(c.disabled)


## Posição no mundo, arredondada a 0,01 px. Sem arredondar, o mesmo mundo
## dava diffs por ruído de vírgula flutuante.
func _posicao(no: Node) -> String:
	if no is Node2D:
		var g: Vector2 = no.global_position
		return "(%.2f, %.2f)" % [g.x, g.y]
	return "(-, -)"


func _forma(f: Shape2D) -> String:
	if f is RectangleShape2D:
		return "rect %.2fx%.2f" % [f.size.x, f.size.y]
	if f is CircleShape2D:
		return "circ %.2f" % f.radius
	if f is CapsuleShape2D:
		return "caps %.2fx%.2f" % [f.radius, f.height]
	if f is SegmentShape2D:
		return "seg %s->%s" % [f.a, f.b]
	if f is WorldBoundaryShape2D:
		return "limite"
	return "forma?" if f == null else f.get_class()


## O que distingue funcionalmente um corpo do outro: grupos (a `koliani`, os
## `checkpoint`), o nome do script e os campos que mudam o jogo.
func _identidade(no: Node) -> String:
	var partes: Array[String] = []
	var gs := no.get_groups()
	gs.sort()
	for g in gs:
		if not String(g).begins_with("_"):
			partes.append("g:" + String(g))
	var s: Script = no.get_script()
	if s:
		partes.append("s:" + s.resource_path.get_file())
	for campo in ["dano", "vida", "especie", "largura", "amplitude", "periodo",
			"modo", "velocidade", "intervalo", "auto", "permanente"]:
		if campo in no:
			partes.append("%s=%s" % [campo, no.get(campo)])
	return " ".join(partes)
