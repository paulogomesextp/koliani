extends Node
## Fotografa a GEOMETRIA DE JOGO dos niveis da Regiao II (N06-N10).
##
## Serve o "art safety" do Super-Process A: um passe de arte pode mudar
## ceus, tintas, silhuetas e tiles a' vontade, mas NAO pode mexer em nada
## que o jogador toque -- plataformas, colisoes, checkpoints, spawn,
## portas, limites da arena, perigos e zonas de vento.
##
## Grava um JSON com esses valores. Corre-se ANTES do passe, guarda-se o
## ficheiro, e corre-se DEPOIS contra o mesmo ficheiro:
##
##   Godot --headless --path . res://tools/geometria_regiao02.tscn -- gravar <f>
##   Godot --headless --path . res://tools/geometria_regiao02.tscn -- comparar <f>
##
## E' uma CENA e nao um `--script`: em `--script` os autoloads nao existem,
## e basta uma cena de nivel puxar um script que use `Som`/`EstadoJogo`
## para a compilacao rebentar (foi o que aconteceu a' primeira versao).
##
## `comparar` sai != 0 e lista o que mexeu. Le' as cenas do disco (sem as
## por na arvore), por isso e' barato e nao depende de autoloads.

const CENAS := {
	"N06": "res://scenes/levels/Prisao_dos_Condenados.tscn",
	"N07": "res://scenes/levels/Fornalha_dos_Pecadores.tscn",
	"N08": "res://scenes/levels/Corredor_das_Execucoes.tscn",
	"N09": "res://scenes/levels/Ala_dos_Mortos.tscn",
	"N10": "res://scenes/levels/A_Cela_Zero.tscn",
}

## Nos cuja POSICAO/forma e' gameplay. Tudo o que nao entra aqui (luzes,
## Atmosfera, decoracao) e' arte e pode mudar.
const PREFIXOS_GAMEPLAY := [
	"Chao", "Plat", "Plataforma", "Ilha", "Ledge", "Ponte", "Check",
	"Porta", "Koliani", "Chefe", "Espinho", "Serra", "Fogo", "Agua",
	"Acido", "Vento", "Rajada", "Corrente", "Updraft", "Zona", "Col",
	"Bau", "Elite", "Inimigo", "Bicho", "Trampolim", "Alavanca",
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var modo: String = args[0] if args.size() > 0 else "gravar"
	var caminho: String = args[1] if args.size() > 1 else "user://geometria_r2.json"
	var agora := _medir()

	if modo == "gravar":
		var f := FileAccess.open(caminho, FileAccess.WRITE)
		if f == null:
			printerr("nao consegui escrever ", caminho)
			get_tree().quit(1)
			return
		f.store_string(JSON.stringify(agora, "\t", true))
		f.close()
		print("geometria gravada em ", caminho, " (", agora.size(), " niveis)")
		get_tree().quit(0)
		return

	var f2 := FileAccess.open(caminho, FileAccess.READ)
	if f2 == null:
		printerr("nao encontrei a base ", caminho)
		get_tree().quit(1)
		return
	var base: Variant = JSON.parse_string(f2.get_as_text())
	f2.close()
	if not (base is Dictionary):
		printerr("base ilegivel")
		get_tree().quit(1)
		return

	var difs := _comparar(base as Dictionary, agora)
	if difs.is_empty():
		print("OK -- geometria de jogo da Regiao II intacta")
		get_tree().quit(0)
		return
	for d in difs:
		printerr("MEXEU: ", d)
	printerr("%d diferenca(s) de geometria" % difs.size())
	get_tree().quit(1)


func _medir() -> Dictionary:
	var out := {}
	for nome: String in CENAS:
		var cena := load(CENAS[nome]) as PackedScene
		if cena == null:
			out[nome] = {"ERRO": "cena nao carrega"}
			continue
		var raiz := cena.instantiate()
		var nos := {}
		_percorrer(raiz, raiz, nos)
		out[nome] = nos
		raiz.free()
	return out


func _percorrer(no: Node, raiz: Node, nos: Dictionary) -> void:
	for filho in no.get_children():
		if filho is Node2D and _e_gameplay(filho.name):
			var caminho := String(raiz.get_path_to(filho))
			nos[caminho] = _descrever(filho as Node2D)
		_percorrer(filho, raiz, nos)


func _e_gameplay(nome: StringName) -> bool:
	var n := String(nome)
	for p in PREFIXOS_GAMEPLAY:
		if n.begins_with(p):
			return true
	return false


func _descrever(no: Node2D) -> Dictionary:
	var d := {
		"pos": [snappedf(no.position.x, 0.01), snappedf(no.position.y, 0.01)],
	}
	# tamanho jogavel das plataformas/zonas, quando existe
	for prop in ["tamanho", "largura", "altura", "direcao", "intensidade",
			"velocidade_max", "modo", "duracao_pulso", "intervalo_pulso",
			"topo", "esquerda"]:
		if prop in no:
			var v: Variant = no.get(prop)
			if v is Vector2:
				d[prop] = [snappedf((v as Vector2).x, 0.01),
					snappedf((v as Vector2).y, 0.01)]
			elif v is float:
				d[prop] = snappedf(v as float, 0.01)
			else:
				d[prop] = v
	var col := no.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		var r := (col.shape as RectangleShape2D).size
		d["col"] = [snappedf(r.x, 0.01), snappedf(r.y, 0.01)]
		d["col_pos"] = [snappedf(col.position.x, 0.01),
			snappedf(col.position.y, 0.01)]
	return d


## O JSON nao distingue int de float: um `modo = 1` volta do ficheiro
## como 1.0 e uma comparacao por `str()` acusava as cinco zonas de vento
## de terem mudado sem nada ter mudado. Compara-se numero com numero.
func _igual(a: Variant, b: Variant) -> bool:
	if a is Array and b is Array:
		var aa: Array = a
		var ba: Array = b
		if aa.size() != ba.size():
			return false
		for i in aa.size():
			if not _igual(aa[i], ba[i]):
				return false
		return true
	var a_num := a is float or a is int
	var b_num := b is float or b is int
	if a_num and b_num:
		return is_equal_approx(float(a), float(b))
	return str(a) == str(b)


func _comparar(base: Dictionary, agora: Dictionary) -> Array[String]:
	var difs: Array[String] = []
	for nivel: String in base:
		if not agora.has(nivel):
			difs.append("%s desapareceu" % nivel)
			continue
		var b: Dictionary = base[nivel]
		var a: Dictionary = agora[nivel]
		for caminho: String in b:
			if not a.has(caminho):
				difs.append("%s: %s desapareceu" % [nivel, caminho])
				continue
			var bd: Dictionary = b[caminho]
			var ad: Dictionary = a[caminho]
			for chave: String in bd:
				var vb: Variant = bd[chave]
				var va: Variant = ad.get(chave)
				if not _igual(vb, va):
					difs.append("%s: %s.%s  %s -> %s"
						% [nivel, caminho, chave, vb, va])
		for caminho2: String in a:
			if not b.has(caminho2):
				difs.append("%s: %s apareceu" % [nivel, caminho2])
	return difs
