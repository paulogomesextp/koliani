extends SceneTree
## Corre o `verifica_alcance.gd` nos 100 niveis de uma vez, num processo so'.
##
## Existe por causa de um bug que chegou ao Paulo DUAS vezes com a mesma
## forma -- o chao do chefe a servir de tecto a quem sobe por baixo, nos
## niveis 10 e 12. Quando o crivo aprendeu a ver tectos, apanhou mais cinco
## niveis com exactamente o mesmo desenho (a familia das torres). Ou seja: a
## ferramenta so' vale se correr em TODOS os niveis, sempre -- e' por isso
## que isto esta' no CI e nao numa linha de comandos que alguem se lembra de
## escrever.
##
## O `Level_Test` fica de fora: e' a sala de treino, tem plataformas soltas
## de proposito.
##
##   godot --headless --script res://tools/verifica_alcance_todos.gd
##
## Sai != 0 se algum nivel tiver a porta inalcancavel.

const CRIVO := preload("res://tools/verifica_alcance.gd")

## Niveis cuja sala nao e' um percurso de plataformas e por isso o crivo
## estatico nao sabe ler. Cada entrada precisa de uma razao escrita: uma
## lista de excepcoes sem razoes vira uma maneira de calar a ferramenta.
const FORA := {
	# o trono e' uma arena de tres pecas com o Zeriko a mudar de forma; nao
	# ha' percurso nenhum para verificar, e as pecas nascem em jogo.
	"O_Trono_de_Zeriko.tscn": "arena final, sem percurso de plataformas",
}


func _init() -> void:
	# os autoloads so' existem depois do primeiro frame -- sem isto o
	# `EstadoJogo` vinha nulo e a ferramenta saia sem medir nada
	await process_frame
	var estado: Node = root.get_node_or_null("EstadoJogo")
	if estado == null:
		print("SEM EstadoJogo -- correr sem --script? (autoloads nao carregam)")
		quit(2)
		return
	var niveis: Array = estado.NIVEIS
	var maus: Array[String] = []
	var saltados := 0
	for n in niveis.size():
		var cena: String = String(niveis[n])
		var ficheiro := cena.get_file()
		if FORA.has(ficheiro):
			saltados += 1
			continue
		var r: Dictionary = await CRIVO.medir(self, cena, n)
		if not bool(r.get("ok_porta", false)):
			maus.append("  [%2d] %-30s %s" % [n + 1, ficheiro, r.get("porque", "")])
	print("")
	print("=== ALCANCE: %d niveis, %d fora da conta, %d com a porta inalcancavel"
		% [niveis.size(), saltados, maus.size()])
	for m in maus:
		print(m)
	quit(1 if not maus.is_empty() else 0)
