extends Node2D
## Aura separada dos PNGs: penas, brasas, gotas ou estrelas conforme a skin.
## Mesmo contrato de frame/offset/espelho; sem efeitos na fisica ou combate.
const CODIGO := """
shader_type canvas_item;
render_mode unshaded, blend_add;
uniform vec4 cor : source_color;
uniform vec4 luz : source_color;
uniform float pulso = 0.0;
void fragment() {
 vec2 p = TEXTURE_PIXEL_SIZE;
 float centro = texture(TEXTURE, UV).a;
 float perto = 0.0;
 float longe = 0.0;
 for(int i=0; i<8; i++) {
  float a = float(i)*0.785398;
  vec2 d = vec2(cos(a),sin(a))*p;
  perto = max(perto, texture(TEXTURE, UV+d*1.5).a);
  longe = max(longe, texture(TEXTURE, UV+d*3.0).a);
 }
 COLOR = vec4(mix(cor.rgb,luz.rgb,perto), (1.0-centro)*(perto*0.28+longe*0.12)*(0.85+pulso*0.3));
}
"""
var halo: Sprite2D
var cor := Color.WHITE
var luz := Color.WHITE
var tema := ""
var tempo := 0.0
var energia := 0.0

func _init() -> void:
	name = "ShadowbladeAura"
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	light_mask = 0
	var shader := Shader.new()
	shader.code = CODIGO
	var mat := ShaderMaterial.new()
	mat.shader = shader
	halo = Sprite2D.new()
	halo.material = mat
	add_child(halo)
	var mistura := CanvasItemMaterial.new()
	mistura.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mistura

func configurar(perfil: Dictionary) -> void:
	cor = perfil.get("cor", Color.WHITE)
	luz = perfil.get("luz", Color.WHITE)
	tema = perfil.get("tema", "")
	(halo.material as ShaderMaterial).set_shader_parameter("cor", cor)
	(halo.material as ShaderMaterial).set_shader_parameter("luz", luz)

func atualizar(corpo: AnimatedSprite2D, flash: float, t: float) -> void:
	halo.texture = corpo.sprite_frames.get_frame_texture(corpo.animation, corpo.frame)
	position = corpo.position
	halo.offset = corpo.offset
	scale = corpo.scale
	halo.flip_h = corpo.flip_h
	halo.flip_v = corpo.flip_v
	rotation = corpo.rotation
	tempo = t
	energia = flash
	(halo.material as ShaderMaterial).set_shader_parameter("pulso", 0.3+0.15*sin(t*3.0)+flash)
	queue_redraw()

func _draw() -> void:
	# Oito motivos pequenos nas laterais: rosto e roupa ficam livres.
	for i in 8:
		var fase := fposmod(tempo*0.3+float(i)*0.137,1.0)
		var p := Vector2((-1.0 if i%2 else 1.0)*(18.0+4.0*sin(tempo+i)),23.0-fase*62.0)
		var tinta := Color(luz, sin(fase*PI)*0.7)
		if tema == "agua":
			draw_circle(p, 1.5, tinta, false, 1.0)
		elif tema == "penas":
			draw_line(p-Vector2(2,3),p+Vector2(2,3),tinta,1.0)
			draw_line(p-Vector2(2,0),p+Vector2(1,2),Color(cor,tinta.a),1.0)
		elif tema == "brasas":
			draw_line(p+Vector2(0,2),p-Vector2(1,3),tinta,2.0)
		else:
			draw_line(p-Vector2(2,0),p+Vector2(2,0),tinta,1.0)
			draw_line(p-Vector2(0,2),p+Vector2(0,2),tinta,1.0)
