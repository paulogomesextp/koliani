shader_type canvas_item;
// 9H.7B: conservar a grelha da fonte, antialiasando só a transição entre
// texels durante o parallax. Sem unsharp, halos ou reamostragem Lanczos.
uniform bool conservar_texel = true;
uniform bool reparar_borda = false;
uniform vec4 tinta : source_color = vec4(1.0);
uniform float dessaturar : hint_range(0.0, 1.0) = 0.0;
varying vec4 modulacao;

void vertex() {
	modulacao = COLOR;
}

void fragment() {
	vec2 uv = UV;
	if (conservar_texel) {
		vec2 p = UV / TEXTURE_PIXEL_SIZE;
		vec2 largura = clamp(fwidth(p), vec2(0.0001), vec2(1.0));
		// Uma transição contínua de um pixel do ecrã, em vez de interpolar
		// todo o texel ampliado. Sob redução converge para bilinear.
		vec2 fracao = fract(p);
		p = floor(p) + 0.5 + (fracao - clamp(fracao, 0.5 * largura, vec2(1.0) - 0.5 * largura)) / largura;
		uv = p * TEXTURE_PIXEL_SIZE;
	}
	// O recorte aprovado do panorama inclui a coluna da moldura. Repete
	// o vizinho, como o produtor 9H.7, sem alterar o quad nem o espelho.
	if (reparar_borda) {
		uv = clamp(uv, 1.5 * TEXTURE_PIXEL_SIZE, vec2(1.0) - 1.5 * TEXTURE_PIXEL_SIZE);
	}
	vec4 c = texture(TEXTURE, uv);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(l), dessaturar) * tinta.rgb;
	COLOR = c * modulacao;
}
