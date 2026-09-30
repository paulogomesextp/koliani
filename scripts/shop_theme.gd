class_name ShopTheme
extends RefCounted
## Tema dedicado da Loja. Mantém cores, contornos e estados num único sítio;
## catálogo/economia nunca dependem deste ficheiro.

const FUNDO := Color(0.018, 0.012, 0.019, 0.96)
const FUNDO_ELEVADO := Color(0.045, 0.024, 0.036, 0.96)
const FUNDO_PREVIEW := Color(0.025, 0.017, 0.028, 0.96)
const CARMESIM := Color(0.88, 0.075, 0.14)
const CARMESIM_CLARO := Color(1.0, 0.30, 0.35)
const OURO := Color(0.98, 0.73, 0.20)
const EPICO := Color(0.55, 0.28, 0.96)
const RARO := Color(0.18, 0.68, 0.96)
const VERDE := Color(0.18, 0.88, 0.58)
const OSSO := Color(0.96, 0.93, 0.90)
const TEXTO := Color(0.82, 0.80, 0.82)
const APAGADO := Color(0.49, 0.47, 0.51)


static func raridade(id: String) -> Color:
	match id:
		"lendario":
			return OURO
		"epico":
			return EPICO
		"raro":
			return RARO
	return OSSO


static func estado(id: String) -> Color:
	match id:
		"equipado":
			return OURO
		"adquirido", "completo":
			return VERDE
		"bloqueado":
			return APAGADO
	return OSSO


static func painel(cor_borda := CARMESIM, alfa := 0.90, largura := 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(FUNDO_ELEVADO.r, FUNDO_ELEVADO.g, FUNDO_ELEVADO.b, alfa)
	sb.border_color = cor_borda
	sb.set_border_width_all(largura)
	sb.border_width_top = maxi(largura, 2)
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.shadow_color = Color(cor_borda.r, cor_borda.g, cor_borda.b, 0.18)
	sb.shadow_size = 10 if largura > 1 else 4
	return sb


static func placa(cor_borda: Color, intensidade := 0.45, cheia := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(
		cor_borda.r * (0.20 if cheia else 0.09),
		cor_borda.g * (0.14 if cheia else 0.06),
		cor_borda.b * (0.14 if cheia else 0.08),
		0.96)
	sb.border_color = Color(cor_borda.r, cor_borda.g, cor_borda.b, intensidade)
	sb.set_border_width_all(1)
	sb.border_width_top = 2 if intensidade > 0.65 else 1
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.shadow_color = Color(cor_borda.r, cor_borda.g, cor_borda.b, 0.17 * intensidade)
	sb.shadow_size = int(8.0 * intensidade)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	return sb


static func vestir_botao(botao: Button, cor := CARMESIM, tamanho := 14) -> void:
	botao.focus_mode = Control.FOCUS_ALL
	botao.add_theme_font_size_override("font_size", tamanho)
	botao.add_theme_color_override("font_color", TEXTO)
	botao.add_theme_color_override("font_hover_color", OSSO)
	botao.add_theme_color_override("font_focus_color", OSSO)
	botao.add_theme_color_override("font_pressed_color", OSSO)
	botao.add_theme_color_override("font_disabled_color", APAGADO)
	botao.add_theme_color_override("font_outline_color", Color(0.01, 0.005, 0.01))
	botao.add_theme_constant_override("outline_size", 4)
	botao.add_theme_stylebox_override("normal", placa(cor, 0.35))
	botao.add_theme_stylebox_override("hover", placa(cor, 0.85, true))
	botao.add_theme_stylebox_override("focus", placa(cor, 0.90, true))
	botao.add_theme_stylebox_override("pressed", placa(cor, 1.0, true))
	botao.add_theme_stylebox_override("hover_pressed", placa(cor, 1.0, true))
	botao.add_theme_stylebox_override("disabled", placa(APAGADO, 0.20))


static func vestir_label(label: Label, tamanho: int, cor := TEXTO, contorno := 3) -> void:
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_outline_color", Color(0.008, 0.004, 0.009))
	label.add_theme_constant_override("outline_size", contorno)
