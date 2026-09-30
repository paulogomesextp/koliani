extends Node2D
## Aura premium independente: contorno luminoso, filamentos e motes orbitais.
## Segue a textura do corpo, sem modificar animacoes ou colisao.
const CODIGO := """
shader_type canvas_item;
render_mode unshaded, blend_add;
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
  longe = max(longe, texture(TEXTURE, UV+d*4.0).a);
 }
 float exterior = 1.0-centro;
 vec3 cor = mix(vec3(0.48,0.12,0.95), vec3(0.87,0.66,1.0), perto);
 float alfa = exterior*(perto*0.38+longe*0.18)*(0.85+pulso*0.4);
 COLOR = vec4(cor, alfa);
}
"""
var tempo := 0.0
var energia := 0.0
var halo: Sprite2D

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
	(halo.material as ShaderMaterial).set_shader_parameter("pulso", 0.3 + 0.15*sin(t*3.0) + flash)
	queue_redraw()

func _draw() -> void:
	# Filamentos laterais deixam cara, tronco e arma livres.
	for lado in [-1.0, 1.0]:
		var pontos := PackedVector2Array()
		for i in 14:
			var f := float(i)/13.0
			pontos.append(Vector2(lado*(17.0+4.0*sin(f*5.0+tempo*2.0)), 23.0-f*58.0))
		draw_polyline(pontos, Color(0.62,0.24,1.0,0.24+energia*0.2), 2.0)
		draw_polyline(pontos, Color(0.9,0.72,1.0,0.4), 1.0)
	for i in 10:
		var fase := fposmod(tempo*0.35+float(i)*0.137,1.0)
		var x := sin(float(i)*2.4+tempo)*22.0
		var p := Vector2(x, 23.0-fase*65.0)
		var alfa := sin(fase*PI)*0.8
		draw_line(p-Vector2(2,0), p+Vector2(2,0), Color(0.87,0.69,1.0,alfa),1.0)
		draw_line(p-Vector2(0,2), p+Vector2(0,2), Color(1.0,0.9,1.0,alfa),1.0)
