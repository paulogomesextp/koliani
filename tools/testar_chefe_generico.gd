extends SceneTree
## Bancada dos ARQUÉTIPOS do `ChefeGenerico`.
##
## Monta uma arena mínima (uma plataforma larga, a Koliani num canto, o
## chefe no outro), corre uns segundos de física e diz o que aconteceu:
## que fases é que a máquina de estados percorreu, quantos projéteis /
## lacaios / ondas saíram, e se o chefe se aguentou na plataforma.
##
## É a rede de segurança dos 70 chefes dos níveis 31-100: como passam todos
## pelo mesmo script, um arquétipo partido parte-os a todos de uma vez.
##
##   Godot --headless --script res://tools/testar_chefe_generico.gd -- [segundos]
##
## Sai != 0 se algum arquétipo não fizer nada, cair da plataforma, ou rebentar.

# `load()` e nao `preload()`: com `--script`, um `preload` faz o Godot
# compilar a cena (e o `chefe_generico.gd`, que usa `Som`/`EstadoJogo`)
# durante a compilacao DESTE ficheiro -- ou seja, antes de os autoloads
# existirem, e o script do chefe fica por compilar em silencio.
var PLAT: PackedScene
var KOLI: PackedScene
var CHEFE: PackedScene

## Ordem dos valores do enum `ChefeGenerico.Arquetipo`. Escrita a' mao pela
## mesma razao: nomear a classe aqui obrigava a compila-la cedo demais.
const ARQUETIPOS := ["INVESTIDA", "ATIRADOR", "SALTADOR", "INVOCADOR", "FEIXE"]

const CHAO_Y := 400.0
const LARGURA := 1400.0

var _falhas := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var segundos: float = float(args[0]) if args.size() > 0 else 6.0
	await process_frame
	PLAT = load("res://scenes/actors/Plataforma.tscn")
	KOLI = load("res://scenes/actors/Koliani.tscn")
	CHEFE = load("res://scenes/actors/ChefeGenerico.tscn")

	for i in ARQUETIPOS.size():
		await _testar(i, segundos)

	print("\n=== ARQUETIPOS: %s ===" % (
		"TUDO OK" if _falhas == 0 else "%d FALHA(S)" % _falhas))
	quit(1 if _falhas > 0 else 0)


func _testar(indice: int, segundos: float) -> void:
	var nome: String = ARQUETIPOS[indice]
	var raiz := Node2D.new()
	get_root().add_child(raiz)

	var chao: Node2D = PLAT.instantiate()
	chao.position = Vector2(0.0, CHAO_Y)
	chao.set("tamanho", Vector2(LARGURA, 60.0))
	raiz.add_child(chao)

	var kol: Node2D = KOLI.instantiate()
	raiz.add_child(kol)
	kol.global_position = Vector2(-380.0, CHAO_Y - 120.0)

	var chefe: Node2D = CHEFE.instantiate()
	chefe.set("arquetipo", indice)
	# telegrafos curtos para caber tudo em poucos segundos de bancada
	chefe.set("dur_telegrafo", 0.25)
	chefe.set("dur_recupera", 0.3)
	raiz.add_child(chefe)
	chefe.global_position = Vector2(240.0, CHAO_Y - 120.0)

	# a luta só arranca depois de `provocar()` (é o que o nível faz)
	if chefe.has_method("provocar"):
		chefe.provocar()

	var y_partida: float = chefe.global_position.y
	var fases := {}
	var passos := int(segundos * 60.0)
	for _i in passos:
		await physics_frame
		if not is_instance_valid(chefe):
			break
		var f: Variant = chefe.get("_fase")
		if f == null:
			break              # script por compilar -> nao ha' maquina nenhuma
		fases[int(f)] = true

	var problemas: Array[String] = []
	if not is_instance_valid(chefe):
		problemas.append("o chefe deixou de existir")
	else:
		if chefe.global_position.y > y_partida + 400.0:
			problemas.append("caiu da plataforma (y %+.0f)" % (
				chefe.global_position.y - y_partida))
		if absf(chefe.global_position.x) > LARGURA:
			problemas.append("saiu da arena (x %.0f)" % chefe.global_position.x)
		if fases.size() < 3:
			problemas.append("só percorreu %d fase(s) -- máquina presa"
				% fases.size())

	var extras := _contar(raiz)
	print("  %-10s fases=%d  projeteis=%d  lacaios=%d  %s" % [
		nome, fases.size(), extras[0], extras[1],
		"OK" if problemas.is_empty() else "FALHA: " + ", ".join(problemas)])
	if not problemas.is_empty():
		_falhas += 1

	raiz.queue_free()
	await process_frame


## Conta o que o chefe largou na cena: (projéteis, lacaios).
func _contar(raiz: Node) -> Array:
	var proj := 0
	var lacaios := 0
	for n in raiz.get_children():
		var sc: Variant = n.get_script()
		if sc is Script:
			var cam := String((sc as Script).resource_path)
			if cam.ends_with("projetil_zeriko.gd"):
				proj += 1
			elif cam.ends_with("demonio_base.gd"):
				lacaios += 1
	return [proj, lacaios]
