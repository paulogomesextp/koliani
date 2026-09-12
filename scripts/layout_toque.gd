class_name LayoutToque
extends RefCounted
## LAYOUT DE TOQUE DO JOGADOR (Execution 9H). Guarda, em
## `user://layout_toque.json`, onde é que cada controlo do telemóvel fica e
## que tamanho tem. Sem ficheiro, o jogo usa o layout de fábrica
## (`ControlosTacteis.BOTOES` + joystick), exatamente como antes.
##
## POR QUE É QUE ISTO EXISTE. O layout de fábrica foi desenhado para o
## telefone do Paulo, com o polegar dele. Num ecrã mais largo, mais estreito,
## ou para quem joga com a outra mão, os botões caem no sítio errado e não há
## nada a fazer. A partir da 9H há: Opções -> EDITAR LAYOUT.
##
## FORMATO. Tudo em FRAÇÕES do viewport (0..1), não em píxeis: o mesmo
## ficheiro serve um telemóvel de 1600x720 e um tablet de 2048x1536, e um
## layout guardado na horizontal não sai do ecrã ao rodar. O raio é fração
## da ALTURA (é a régua que o `ControlosTacteis` já usava).
##
##   {
##     "versao": 1,
##     "joystick": {"x": 0.14, "y": 0.76, "r": 0.164},
##     "pausa":    {"x": 0.96, "y": 0.14, "r": 0.042},
##     "botoes": { "saltar": {"x":..., "y":..., "r":...}, ... }
##   }
##
## Chaves desconhecidas são ignoradas e chaves em falta caem no valor de
## fábrica: um ficheiro de uma versão antiga nunca parte os controlos.

const CAMINHO := "user://layout_toque.json"
const VERSAO := 1

## Limites de segurança. O que isto impede é o jogador guardar um layout que
## não consegue desfazer -- um botão fora do ecrã, ou tão pequeno que já não
## se acerta nele. O "REPOR" existe à mesma, mas mais vale não precisar.
const R_MIN := 0.030
const R_MAX := 0.180
const MARGEM := 0.02


static func existe() -> bool:
	return FileAccess.file_exists(CAMINHO)


## Lê o layout guardado. `{}` quando não há nenhum (ou está ilegível).
static func carregar() -> Dictionary:
	if not FileAccess.file_exists(CAMINHO):
		return {}
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO))
	if not (dados is Dictionary):
		return {}
	var d: Dictionary = dados
	if int(d.get("versao", 0)) > VERSAO:
		return {}   # gravado por uma versão mais nova: melhor não adivinhar
	return d


static func guardar(layout: Dictionary) -> bool:
	var f := FileAccess.open(CAMINHO, FileAccess.WRITE)
	if f == null:
		push_warning("LayoutToque: não consegui escrever %s" % CAMINHO)
		return false
	var saida := layout.duplicate(true)
	saida["versao"] = VERSAO
	f.store_string(JSON.stringify(saida, "\t"))
	f.close()
	return true


## Repõe o layout de fábrica. APAGA o ficheiro -- não basta repor os
## controlos no ecrã.
##
## 9H.1, apanhado na prova do Web em Chrome real: o REPOR devolvia os
## controlos ao sítio certo mas o `layout_toque.json` continuava em
## IndexedDB com os valores editados, e ao recarregar a página voltava tudo
## ao que estava. A causa era `globalize_path()`: no export Web devolve um
## caminho do sistema de ficheiros do emscripten que o `DirAccess` não
## apaga. O `DirAccess` aceita `user://` tal e qual -- e é isso que funciona
## nas três plataformas.
static func apagar() -> bool:
	if not FileAccess.file_exists(CAMINHO):
		return true
	if DirAccess.remove_absolute(CAMINHO) == OK:
		return not FileAccess.file_exists(CAMINHO)
	# último recurso (desktop): o caminho do sistema
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO))
	return not FileAccess.file_exists(CAMINHO)


## Prende um ponto ao ecrã, com folga para o raio. `r` é fração da ALTURA;
## em x vale menos, porque o ecrã é mais largo do que alto -- daí o `razao`
## (altura/largura). Sem isto, num ecrã 20:9 o botão parava a meio caminho
## da borda esquerda e não chegava ao canto.
static func prender(p: Vector2, r: float, razao := 0.5625) -> Vector2:
	var rx := r * razao
	return Vector2(clampf(p.x, rx * 0.6 + MARGEM, 1.0 - rx * 0.6 - MARGEM),
		clampf(p.y, r * 0.6 + MARGEM, 1.0 - r * 0.6 - MARGEM))


static func prender_raio(r: float) -> float:
	return clampf(r, R_MIN, R_MAX)
