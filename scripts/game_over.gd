extends CanvasLayer
class_name GameOver
## O cartão de "GAME OVER" e o som foram RETIRADOS a pedido do Paulo.
##
## Um run que acaba (modo hardcore: tempo esgotado em `relogio_hardcore.gd`
## ou 3 vidas gastas em `koliani.gd`) recomeça agora a campanha do mundo 1
## em silêncio, sem ecrã nem voz, mantendo o modo hardcore ligado.
##
## A função `mostrar()` fica com a mesma assinatura para os sítios que a
## chamam não precisarem de mudar.


static func mostrar(arvore: SceneTree, _motivo: String) -> void:
	arvore.paused = false
	EstadoJogo.reiniciar_campanha()  # não mexe no hardcore -> continua hardcore
	Transicao.fechar_e(func() -> void: arvore.change_scene_to_file("res://scenes/Main.tscn"))
