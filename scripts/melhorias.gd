class_name Melhorias
## Catálogo das MELHORIAS permanentes -- compradas com Essência no Santuário
## (`scenes/ui/Santuario.tscn`). Dados puros, sem dependências. A Koliani lê
## os efeitos via `EstadoJogo.bonus("<efeito>")`, que soma o `por_rank` de
## todas as melhorias com esse `efeito`.
##
## Persistência: `EstadoJogo.melhorias` = { id -> rank (int, 0..max) }.
## `reiniciar_campanha()` limpa; `reiniciar_run()` (morte) NÃO -- é por
## níveis, não roguelite.

const CATALOGO := {
	"vitalidade": {
		"icone": "❤", "cor": Color(0.95, 0.4, 0.45),
		"custos": [40, 95, 180, 320], "efeito": "vida_max", "por_rank": 20.0,
	},
	"forca": {
		"icone": "⚔", "cor": Color(1.0, 0.66, 0.35),
		"custos": [55, 120, 210, 360], "efeito": "dano_mult", "por_rank": 0.12,
	},
	"foco": {
		"icone": "✦", "cor": Color(0.55, 0.8, 1.0),
		"custos": [45, 105, 190], "efeito": "regen_energia", "por_rank": 0.28,
	},
	"agilidade": {
		"icone": "➤", "cor": Color(0.55, 0.95, 0.7),
		"custos": [60, 135, 240], "efeito": "iframes_roll", "por_rank": 0.06,
	},
	"furia": {
		"icone": "✷", "cor": Color(1.0, 0.45, 0.85),
		"custos": [70, 155, 270], "efeito": "crit_mult", "por_rank": 0.22,
	},
	"escudo_runico": {
		"icone": "🛡", "cor": Color(0.7, 0.6, 1.0),
		"custos": [90, 210], "efeito": "escudo_cargas", "por_rank": 1.0,
	},
}

## Ordem em que aparecem no Santuário.
const ORDEM := ["vitalidade", "forca", "foco", "agilidade", "furia", "escudo_runico"]


static func max_rank(id: String) -> int:
	return (CATALOGO[id]["custos"] as Array).size() if CATALOGO.has(id) else 0


## Custo (Essência) para subir de `rank_atual` para `rank_atual + 1`.
## -1 = já no máximo ou id inválido.
static func custo(id: String, rank_atual: int) -> int:
	if not CATALOGO.has(id):
		return -1
	var cs: Array = CATALOGO[id]["custos"]
	return int(cs[rank_atual]) if rank_atual >= 0 and rank_atual < cs.size() else -1


## Efeito acumulado da melhoria `id` no rank `rank` (por_rank * rank).
static func efeito_total(id: String, rank: int) -> float:
	if not CATALOGO.has(id):
		return 0.0
	return float(CATALOGO[id]["por_rank"]) * float(maxi(0, rank))


static func icone(id: String) -> String:
	return String(CATALOGO[id]["icone"]) if CATALOGO.has(id) else "•"


static func cor(id: String) -> Color:
	return CATALOGO[id]["cor"] if CATALOGO.has(id) else Color(0.7, 0.7, 0.8)
