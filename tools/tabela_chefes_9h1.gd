extends Node
## Execution 9H.1 -- TABELA DE EQUILÍBRIO DOS CHEFES DA REGIÃO I.
##
## O briefing (secção 8): "Do NOT rebalance further blindly. Keep current
## values initially. Provide concise current before/after table."
##
## Isto NÃO afina nada: instancia cada guardião duas vezes -- uma com os
## valores de origem e outra depois de `_afinar_dificuldade()`, que é o que o
## jogo corre -- e escreve a diferença. É o "antes/depois" da rampa de alívio
## que a 9H introduziu e que a 9H.1 deixa EXACTAMENTE como estava.
##
## Uso: Godot --headless --path . res://tools/tabela_chefes_9h1.tscn -- <saida.md>

const CHEFES := [
	["1-1", "Ghorak", "res://scenes/actors/ChefeGhorak.tscn"],
	["1-2", "Morvanna", "res://scenes/actors/ChefeMorvanna.tscn"],
	["1-3", "Rainha Aracnidea", "res://scenes/actors/ChefeRainhaAracnidea.tscn"],
	["1-4", "Entrevane", "res://scenes/actors/ChefeEntrevane.tscn"],
	["1-5", "Coracao Putrefacto", "res://scenes/actors/ChefeCoracaoPutrefacto.tscn"],
]
## Propriedades que a rampa mexe, por ordem de interesse.
const CAMPOS := ["vida", "dur_tel", "dur_telegrafo", "dur_exposto", "dur_recupera",
	"dur_baque", "cadencia", "dur_ataque"]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else "res://work/execution_9h1/chefes.md"
	_correr.call_deferred(saida)


func _valores(no: Node) -> Dictionary:
	var d := {}
	for c in CAMPOS:
		if c in no:
			d[c] = no.get(c)
	# todos os `dano_*` declarados pelo chefe concreto
	for prop in no.get_property_list():
		var nome: String = prop["name"]
		if nome.begins_with("dano_") and (prop["type"] in [TYPE_INT, TYPE_FLOAT]):
			d[nome] = no.get(nome)
	return d


func _correr(saida: String) -> void:
	var linhas: Array[String] = []
	linhas.append("# Chefes da Regiao I -- antes/depois da rampa de alivio (9H)")
	linhas.append("")
	linhas.append("Gerado por `tools/tabela_chefes_9h1.gd`. A 9H.1 **nao mexeu** em")
	linhas.append("nenhum destes numeros: a tabela existe para o Game Master os")
	linhas.append("aprovar (ou nao) num playtest humano.")
	linhas.append("")
	linhas.append("`base` = o que o script do chefe declara. `jogo` = o que o jogador")
	linhas.append("encontra, depois de `ChefeBase._afinar_dificuldade()` aplicar o")
	linhas.append("multiplicador de vida da campanha e a rampa `ALIVIO_R1`.")
	linhas.append("")
	for i in CHEFES.size():
		var nivel: String = CHEFES[i][0]
		var nome: String = CHEFES[i][1]
		var cena: String = CHEFES[i][2]
		if not ResourceLoader.exists(cena):
			linhas.append("## %s %s -- CENA EM FALTA (%s)" % [nivel, nome, cena])
			continue
		EstadoJogo.indice_nivel = i
		var pk := load(cena) as PackedScene
		# base: sem entrar na arvore, `_afinar_dificuldade` nunca corre
		var base_no := pk.instantiate()
		var base := _valores(base_no)
		base_no.free()
		# jogo: com `_ready` e o `call_deferred("_afinar_dificuldade")` corrido
		var vivo := pk.instantiate()
		add_child(vivo)
		await get_tree().process_frame
		await get_tree().process_frame
		var depois := _valores(vivo)
		var al := ChefeBase.alivio_regiao_i(i)
		linhas.append("## %s %s" % [nivel, nome])
		linhas.append("")
		linhas.append("Alivio da Regiao I: vida x%.2f, dano x%.2f, telegrafo x%.2f, "
			% [al["vida"], al["dano"], al["tel"]]
			+ "exposto x%.2f, recuperacao x%.2f" % [al["exposto"], al["recupera"]])
		linhas.append("")
		linhas.append("| valor | base | jogo | fator |")
		linhas.append("| --- | ---: | ---: | ---: |")
		var chaves: Array = depois.keys()
		chaves.sort()
		for c in chaves:
			var a: float = float(base.get(c, 0.0))
			var b: float = float(depois[c])
			var f := "--" if is_zero_approx(a) else "x%.2f" % (b / a)
			linhas.append("| `%s` | %s | %s | %s |" % [c,
				("%.3f" % a).trim_suffix("0").trim_suffix("0").trim_suffix("."),
				("%.3f" % b).trim_suffix("0").trim_suffix("0").trim_suffix("."), f])
		linhas.append("")
		vivo.queue_free()
		await get_tree().process_frame
	var f := FileAccess.open(saida, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(linhas) + "\n")
		f.close()
		print("tabela -> ", ProjectSettings.globalize_path(saida))
	else:
		print("NAO GRAVOU: ", saida)
	get_tree().quit(0)
