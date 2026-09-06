class_name CenografiaLore
extends Node2D
## Camada de arte por regiao: fundos pixel art unicos atras das plataformas.
@export var regiao := 0
@export var largura := 12000.0
var _tex: Texture2D
func _ready()->void:
	z_index=-20
	set_process(true)
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
	_desenhar_motivos()

func _process(_dt:float)->void:
	queue_redraw()

func _desenhar_motivos()->void:
	var acento:Color = [Color("6bc58a"),Color("a7a0df"),Color("9dbdff"),Color("9e72c1"),Color("e39577"),Color("c55eff"),Color("f47732"),Color("4dd7d0"),Color("b9f7ff"),Color("f3c568"),Color("c88bc5"),Color("70d4de"),Color("d9ddff"),Color("ecb6ff"),Color("b6d8b6"),Color("ed6263"),Color("ff9b3d"),Color("b2a2ff"),Color("e3a774"),Color("f0c68c")][clampi(regiao,0,19)]
	for x in range(-260, int(largura)+260, 520):
		var xx:=float(x)
		match regiao:
			0,10: # raizes e roseiras
				for j in 3: draw_line(Vector2(xx+j*22.0,520),Vector2(xx-18+j*28.0,350),acento,5)
			1,14: # grades, portoes e lapides
				draw_rect(Rect2(xx,300,120,170),Color(acento,0.22),false,5); draw_line(Vector2(xx+30,300),Vector2(xx+30,470),acento,4); draw_line(Vector2(xx+90,300),Vector2(xx+90,470),acento,4)
			2,8: # torres e cristais
				draw_colored_polygon(PackedVector2Array([Vector2(xx,500),Vector2(xx+44,270),Vector2(xx+88,500)]),Color(acento,0.28)); draw_line(Vector2(xx+44,270),Vector2(xx+44,500),acento,3)
			3,17: # cavernas e fragmentos impossiveis
				draw_circle(Vector2(xx+50,390),55,Color(acento,0.16)); draw_circle(Vector2(xx+50,390),22,Color(acento,0.3)); draw_line(Vector2(xx+10,480),Vector2(xx+90,340),acento,4)
			4,11: # fachadas urbanas e tubos
				draw_rect(Rect2(xx,330,150,170),Color(acento,0.18)); draw_line(Vector2(xx,390),Vector2(xx+150,390),acento,5); draw_line(Vector2(xx+35,330),Vector2(xx+35,500),acento,4)
			5,19: # simbolos de Zeriko e memoria final
				draw_circle(Vector2(xx+50,380),42,Color(acento,0.18)); draw_arc(Vector2(xx+50,380),42,0,TAU,16,acento,4); draw_line(Vector2(xx+20,500),Vector2(xx+50,380),acento,3)
			6,16: # crateras e chamas
				draw_colored_polygon(PackedVector2Array([Vector2(xx,500),Vector2(xx+30,360),Vector2(xx+55,430),Vector2(xx+85,300),Vector2(xx+130,500)]),Color(acento,0.3))
			7,15: # ondas e tentaculos
				draw_arc(Vector2(xx+55,450),70,PI,TAU,18,acento,5); draw_arc(Vector2(xx+55,450),45,PI,TAU,18,Color(acento,0.55),3)
			9: # arcos de dunas
				draw_arc(Vector2(xx+70,500),100,PI,TAU,20,acento,7); draw_arc(Vector2(xx+160,500),75,PI,TAU,20,Color(acento,0.55),4)
			12: # nuvens e relampagos
				draw_circle(Vector2(xx+45,320),30,Color(acento,0.22)); draw_circle(Vector2(xx+85,320),38,Color(acento,0.22)); draw_line(Vector2(xx+70,355),Vector2(xx+40,470),acento,4)
			13: # luas e cortinas de sonho
				draw_circle(Vector2(xx+60,320),42,Color(acento,0.2)); draw_circle(Vector2(xx+78,310),38,Color("241638")); draw_line(Vector2(xx+10,360),Vector2(xx+10,510),acento,3)
			18: # bandeiras e lanças
				draw_line(Vector2(xx+20,300),Vector2(xx+20,510),acento,4); draw_colored_polygon(PackedVector2Array([Vector2(xx+22,305),Vector2(xx+115,325),Vector2(xx+22,350)]),Color(acento,0.55))
			_: # pormenor de luz para as regioes sem motivo dedicado
				draw_circle(Vector2(xx+50,400),18,Color(acento,0.32)); draw_line(Vector2(xx+50,418),Vector2(xx+50,500),acento,3)
