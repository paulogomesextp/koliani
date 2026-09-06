class_name CenografiaLore
extends Node2D
## Camada de arte por regiao: fundos pixel art unicos atras das plataformas.
@export var regiao := 0
@export var largura := 12000.0
var _tex: Texture2D
func _ready()->void:
	z_index=-20
	_tex=load("res://assets/sprites/pixel/biomes/biome_%02d_"%regiao + _nome(regiao) + ".png") as Texture2D
	queue_redraw()
func _nome(i:int)->String:
	return ["putrefacta","prisao","torres","catacumbas","cidade","zeriko","queimadas","mortos_mar","gelo","deserto","jardins","maquinas","ceu","sonhos","mortos","mar_vermelho","inferno","vazio","guerra","fim"][clampi(i,0,19)]
func _draw()->void:
	if _tex==null:return
	var w:=float(_tex.get_width()); var x:=-w
	while x<largura+w:
		draw_texture_rect(_tex,Rect2(x,0,w,288),false,Color.WHITE)
		x+=w
	# neblina de primeiro plano para separar o cenário da jogabilidade
	draw_rect(Rect2(-w,520,largura+w*2,220),Color(0.02,0.02,0.06,0.12))
