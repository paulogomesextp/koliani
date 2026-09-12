class_name TemaRegiao
extends RefCounted
## TEMA VISUAL POR REGIÃO (Execution 9H.1).
##
## O Game Master, a fechar a 9H: o seletor de níveis não pode ter uma pele
## global fixa. A Região I tem de se ler como FLORESTA CORROMPIDA, e não
## como "mais um ecrã carmesim". Mas — e isto é a outra metade da regra —
## as Regiões II a XX **não têm autoridade visual aprovada**, e inventar-lhes
## uma identidade final seria exactamente o que o briefing proíbe.
##
## Por isso este ficheiro tem duas coisas e só duas:
##
##   1. uma ESTRUTURA de tema, igual para as vinte regiões, com os campos
##      que o seletor consome (cor primária, acento, véu, trilho, peças de
##      UI, fundo, motivo). Acrescentar uma região no dia em que a arte for
##      aprovada é acrescentar uma entrada aqui e uma pasta em
##      `assets/ui/frontend_9h/regioes/rNN/` -- não se mexe no seletor;
##
##   2. o tema da REGIÃO I, que é o único com autoridade. Tudo o resto cai
##      no `NEUTRO`: apresentação contida, sem identidade fingida, marcada
##      `REGION SELECTOR THEME AUTHORITY MISSING`.
##
## O que MUDA com o tema: cor, arte de fundo e as peças de moldura. O que
## NÃO muda: a estrutura do ecrã (20 regiões x 5 níveis), a navegação, os
## bloqueios, o comportamento no comando/teclado/toque. Isso é UX e é igual
## em todas as regiões, por desenho.

const DIR := "res://assets/ui/frontend_9h/regioes/"

## Marca documental para as regiões sem arte aprovada. Aparece no manifesto,
## no relatório e no `estado()` — para ninguém confundir "neutro de
## propósito" com "esqueceram-se de tematizar".
const SEM_AUTORIDADE := "REGION SELECTOR THEME AUTHORITY MISSING"

## Apresentação neutra: carvão e osso, sem região nenhuma a fingir. O fundo
## é a própria prancha do frontend (arte aprovada, mas **de marca**, não de
## região) dessaturada, para não ler como "esta região é vermelha".
const NEUTRO := {
	## Pele própria — mas de AÇO FRIO, sem região nenhuma: as peças da
	## prancha dessaturadas por `tools/tema_regiao_9h1.py`. Modular a peça
	## carmesim por um cinzento não chega: um vermelho vezes cinzento é um
	## vermelho escuro, e a Região V continuava a ler-se como "a vermelha".
	"id": "neutro",
	"autoridade": false,
	"nota": SEM_AUTORIDADE,
	"primaria": Color(0.62, 0.60, 0.64),
	"primaria_clara": Color(0.86, 0.85, 0.88),
	"acento": Color(0.70, 0.42, 0.72),
	"veu": Color(0.02, 0.018, 0.026),
	"tinta_fundo": Color(1.0, 1.0, 1.0, 1.0),
	"tinta_pecas": Color(1.0, 1.0, 1.0, 1.0),
	"trilho": Color(0.55, 0.53, 0.58, 0.55),
	"trilho_brilho": Color(0.72, 0.70, 0.76, 0.18),
	"motivo": "losango",
}

## Regiões COM autoridade visual de produção. Hoje: uma.
const TEMAS := {
	0: {
		"id": "r01",
		"autoridade": true,
		"nota": "Arte de produção aprovada da Região I (9C/9D/9G/9H).",
		## Verde de musgo: é a cor da floresta e é a matiz para onde
		## `tools/tema_regiao_9h1.py` roda o carmesim das peças.
		"primaria": Color(0.278, 0.561, 0.322),
		"primaria_clara": Color(0.569, 0.827, 0.561),
		## Magenta/violeta: a CORRUPÇÃO. Usa-se com conta — o nó do guardião,
		## o cadeado, a Árvore-Coração ao fundo. Verde é a floresta; magenta
		## é o que lhe está a acontecer.
		"acento": Color(0.847, 0.271, 0.804),
		"veu": Color(0.016, 0.035, 0.024),
		"tinta_fundo": Color(1.0, 1.0, 1.0, 1.0),
		"tinta_pecas": Color(1.0, 1.0, 1.0, 1.0),
		"trilho": Color(0.40, 0.82, 0.46, 0.85),
		"trilho_brilho": Color(0.62, 1.0, 0.66, 0.26),
		"motivo": "losango",
		## A miniatura do painel é o panorama de produção da própria região.
		"miniatura": "res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_heart_tree.png",
	},
}

static var _cache := {}


## O tema da região `r` (0-based). Nunca devolve nulo.
static func do_indice(r: int) -> Dictionary:
	return TEMAS.get(r, NEUTRO)


static func tem_autoridade(r: int) -> bool:
	return bool(do_indice(r).get("autoridade", false))


## Textura de uma peça na pele da região, com reserva na peça base do
## frontend. A reserva é o que faz uma região sem pele continuar a funcionar
## — nada no seletor precisa de saber se o ficheiro existe.
static func textura(nome: String, r: int) -> Texture2D:
	var id: String = String(do_indice(r).get("id", ""))
	if id != "":
		var chave := id + "/" + nome
		if _cache.has(chave):
			return _cache[chave]
		var cam := DIR + chave + ".png"
		var tex: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
		_cache[chave] = tex
		if tex != null:
			return tex
	return Frontend9H.textura(nome)


## Tinta a aplicar a uma peça (é a que dessatura as regiões sem autoridade).
static func tinta(r: int, peca := "") -> Color:
	var t := do_indice(r)
	if bool(t.get("autoridade", false)):
		return Color.WHITE
	return t.get("tinta_pecas", Color.WHITE)


## Nine-patch de uma peça já na pele da região.
static func caixa(nome: String, r: int, conteudo := Vector4(-1, -1, -1, -1),
		extra := Color.WHITE, margens: Array = []) -> StyleBox:
	var tex := textura(nome, r)
	if tex == null:
		return Frontend9H.caixa(nome, conteudo, extra, margens)
	var sb := StyleBoxTexture.new()
	var m: Array = margens if margens.size() == 4 else Frontend9H.MARGENS.get(nome, [16, 16, 16, 16])
	sb.texture = tex
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	sb.content_margin_left = m[0] * 0.45 if conteudo.x < 0 else conteudo.x
	sb.content_margin_top = m[1] * 0.5 if conteudo.y < 0 else conteudo.y
	sb.content_margin_right = m[2] * 0.45 if conteudo.z < 0 else conteudo.z
	sb.content_margin_bottom = m[3] * 0.5 if conteudo.w < 0 else conteudo.w
	sb.modulate_color = extra * tinta(r, nome)
	return sb


## Linha de estado, para o relatório e para os testes: quantas regiões têm
## pele própria e quais continuam à espera de arte aprovada.
static func estado() -> Dictionary:
	var com: Array[int] = []
	var sem: Array[int] = []
	for i in 20:
		if tem_autoridade(i):
			com.append(i + 1)
		else:
			sem.append(i + 1)
	return {"com_autoridade": com, "sem_autoridade": sem, "nota": SEM_AUTORIDADE}
