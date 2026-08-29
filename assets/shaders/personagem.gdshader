shader_type canvas_item;
// Sprites de personagem, look tipo Dead Cells:
//  - "flash" (0..1): pisca a branco no impacto
//  - "interior": escurece levemente o miolo para a silhueta ler
//  - "rim_*": luz de recorte SUBTIL de um lado (o grosso do rim é pintado
//    no proprio SVG; isto so reforça)

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_cor : source_color = vec4(1.0);
uniform vec4 rim_cor : source_color = vec4(1.0, 0.7, 0.95, 1.0);
uniform float rim_forca : hint_range(0.0, 3.0) = 0.6;
uniform vec2 rim_dir = vec2(-1.0, -0.55);
uniform float rim_espessura : hint_range(0.5, 4.0) = 1.3;
uniform float interior : hint_range(0.0, 1.0) = 0.22;

varying vec4 modul;

void vertex() {
	modul = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.01) {
		COLOR = c;
	} else {
		vec2 px = TEXTURE_PIXEL_SIZE * rim_espessura;
		float na = texture(TEXTURE, UV + normalize(rim_dir) * px).a;
		float borda = clamp(c.a - na, 0.0, 1.0);

		vec3 col = c.rgb * (1.0 - interior * (1.0 - borda));
		col += rim_cor.rgb * borda * rim_forca;
		col = mix(col, flash_cor.rgb, clamp(flash, 0.0, 1.0));

		COLOR = vec4(col, c.a) * modul;
	}
}
