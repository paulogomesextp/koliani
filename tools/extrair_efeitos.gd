extends SceneTree
## Extrai tiras de EFEITO do pack bdragon1727 "Effect and Bullet 16x16"
## (folha roxa, grelha de 16x16) para `assets/sprites/pixel/fx/`.
##
## Por agora só o impacto do golpe: um anel que abre a partir do ponto do
## acerto -- o "pop" que faltava aos golpes (as faíscas de partículas
## sozinhas não marcam o momento).
##
##   godot --headless --script res://tools/extrair_efeitos.gd

const FONTE := "res://assets/sprites/incoming/bdragon1727/Effect and Bullet 16x16/Purple Effect and Bullet 16x16.png"
const SAIDA := "res://assets/sprites/pixel/fx"
const CEL := 16

## nome -> [linha, primeira_coluna, n_frames]
const TIRAS := {
	# linha 5, colunas 14..17: ponto -> disco -> anel -> anel largo (o anel a
	# abrir do ponto do acerto)
	"impacto_roxo": [5, 14, 4],
}


func _init() -> void:
	var src := Image.load_from_file(FONTE)
	if src == null:
		push_error("não abriu " + FONTE)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	for nome: String in TIRAS:
		var cfg: Array = TIRAS[nome]
		var lin: int = cfg[0]
		var col: int = cfg[1]
		var n: int = cfg[2]
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
