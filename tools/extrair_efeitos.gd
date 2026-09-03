extends SceneTree
## Extrai tiras de EFEITO do pack bdragon1727 "Free Effect and Bullet 16x16"
## (grelha de 16x16, uma folha por cor) para `assets/sprites/pixel/fx/`.
##
##   * impacto_roxo -- anel que abre a partir do ponto do acerto (o "pop"
##     que faltava aos golpes). Usado por `scripts/impacto.gd`.
##   * bala_roxa -- vórtice roxo a girar, 6 frames em loop -- corpo do
##     `ProjetilKoliani`, cabeça do `KamehamehaKoliani`, `ProjetilZeriko`.
##   * bola_fogo -- o mesmo vórtice na folha laranja -- corpo da `BolaFogo`
##     (Torreta / cuspidor).
##   * impacto_azul / bala_azul -- os mesmos cortes na folha "Water"
##     (3 set 2026). Com o rig novo da Koliani (manto azul) os tiros roxos
##     deixaram de casar com a personagem; os projécteis dela passaram a
##     azul e o roxo ficou para o Zeriko e para o Kamehameha.
##
##   godot --headless --script res://tools/extrair_efeitos.gd

const PACK := "res://assets/sprites/incoming/bdragon1727/Effect and Bullet 16x16"
const SAIDA := "res://assets/sprites/pixel/fx"
const CEL := 16

## nome -> [folha, linha, primeira_coluna, n_frames]
const TIRAS := {
	# linha 5, colunas 14..17: ponto -> disco -> anel -> anel largo
	"impacto_roxo": ["Purple", 5, 14, 4],
	# linha 0, colunas 30..35: vórtice a girar (loop) -- corpo dos tiros
	"bala_roxa": ["Purple", 0, 30, 6],
	"bola_fogo": ["Fire", 0, 30, 6],
	"impacto_azul": ["Water", 5, 14, 4],
	"bala_azul": ["Water", 0, 30, 6],
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	var cache := {}
	for nome: String in TIRAS:
		var cfg: Array = TIRAS[nome]
		var folha: String = cfg[0]
		var lin: int = cfg[1]
		var col: int = cfg[2]
		var n: int = cfg[3]
		if not cache.has(folha):
			var f := "%s/%s Effect and Bullet 16x16.png" % [PACK, folha]
			cache[folha] = Image.load_from_file(f)
			if cache[folha] == null:
				push_error("não abriu " + f)
				quit(1)
				return
		var src: Image = cache[folha]
		var tira := Image.create(CEL * n, CEL, false, Image.FORMAT_RGBA8)
		tira.fill(Color(0, 0, 0, 0))
		for i in n:
			var reg := src.get_region(Rect2i((col + i) * CEL, lin * CEL, CEL, CEL))
			tira.blit_rect(reg, Rect2i(0, 0, CEL, CEL), Vector2i(i * CEL, 0))
		var caminho := "%s/%s.png" % [SAIDA, nome]
		if tira.save_png(caminho) != OK:
			push_error("não gravou " + caminho)
			continue
		print("%-14s %s  (%d frames de %dx%d)" % [nome, caminho, n, CEL, CEL])
	print("Feito. Correr --import a seguir.")
	quit(0)
