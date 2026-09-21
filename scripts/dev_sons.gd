extends Control
## Teclado de sons do modo Dev (Execution 9H.18, Phase C).
##
## Porque existe: quem faz os sons nesta sessao NAO os ouve. Tudo o que se
## mede -- ataque, cauda, bandas, sonoridade -- diz se a FORMA esta' certa,
## nao se soa bem. Isso so' o Game Master pode dizer, e ate' aqui dizer isso
## custava-lhe jogar ate' cada evento acontecer: encontrar um inimigo para
## ouvir o `acerto`, cair de uma altura certa para ouvir o `aterrar`.
##
## Isto poe os eventos todos a um toque de distancia, agrupados como se
## ouvem no jogo. NAO e' UI permanente: so' existe com o modo Dev ligado, e
## abre-se com a tecla S (ou o botao "SONS" da barra Dev).
##
## Os volumes e os tons sao OS MESMOS que o jogo usa em cada sitio -- se
## aqui soar mal, soa mal em jogo, e vice-versa. Um teclado que tocasse tudo
## a 0 dB nao provava nada.

## [rotulo, som, volume_db, pitch] -- copiado dos sitios reais que os tocam.
const TECLADO := {
	"MENU": [
		["navegar", "ui_mover", -13.0, 1.0],
		["confirmar", "ui_confirmar", -8.0, 1.0],
		["voltar", "ui_voltar", -8.0, 1.0],
		["negado", "ui_negado", -8.0, 1.0],
		["carrossel", "carrossel", -12.0, 1.0],
		["entrar no nivel", "porta", -10.0, 1.1],
	],
	"MOVIMENTO": [
		["passo 1", "passo1", -24.0, 1.0],
		["passo 2", "passo2", -24.0, 1.0],
		["passo 3", "passo3", -24.0, 1.0],
		["salto", "koliani_salto", -10.0, 1.0],
		["salto duplo", "salto_duplo", -10.0, 1.0],
		["aterrar leve", "aterrar", -8.0, 1.0],
		["aterrar medio", "aterrar_medio", -9.0, 1.0],
		["aterrar pesado", "aterrar_pesado", -9.0, 1.0],
		["dash", "dash", -11.0, 1.0],
		["rolamento", "rolamento", -13.0, 1.0],
		["agarrar borda", "agarrar", -14.0, 1.0],
		["parede", "parede", -22.0, 1.0],
	],
	"COMBATE": [
		["golpe 1", "ataque", -8.0, 1.0],
		["golpe 2", "ataque2", -7.0, 1.09],
		["golpe 3", "ataque3", -6.0, 1.16],
		["REMATE", "ataque_forte", -3.0, 0.84],
		["acertar", "acerto", -10.0, 1.0],
		["acertar critico", "acerto_critico", -6.0, 1.0],
		["levar dano", "dano", -7.0, 1.0],
		["dano pesado", "dano_pesado", -7.0, 1.0],
		["escudo ativar", "escudo_ativar", -18.0, 1.0],
		["escudo impacto", "escudo_impacto", -11.0, 1.0],
		["lancar", "lancar", -9.0, 1.0],
		["morrer", "morte_koliani", -6.0, 1.0],
	],
	"INIMIGOS": [
		["ataque (humano)", "mob_humano_ataque", -8.0, 1.0],
		["dano (humano)", "mob_humano_dano", -8.0, 1.0],
		["morte (humano)", "mob_humano_morte", -8.0, 1.0],
		["ataque (besta)", "mob_besta_ataque", -8.0, 1.0],
		["ataque (insecto)", "mob_insecto_ataque", -8.0, 1.0],
		["projetil", "projetil", -6.0, 1.0],
		["investida", "investida", -6.0, 1.0],
		["chefe cai", "chefe_cai", -6.0, 1.0],
	],
	"MUNDO": [
		["apanhar", "apanhar", -6.0, 1.0],
		["essencia", "apanhar", -14.0, 1.25],
		["checkpoint", "selo", -12.0, 1.0],
		["raiz (aviso)", "raiz_aviso", -14.0, 1.0],
		["raiz (irrompe)", "raiz_irrompe", -7.0, 1.0],
		["plataforma", "plataforma_surge", -13.0, 1.0],
		["portal", "onda", -12.0, 1.6],
		["transicao", "transicao", -3.0, 1.0],
		["conquista", "conquista", -4.0, 1.0],
	],
}

var _ultimo: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_montar()


func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.02, 0.01, 0.03, 0.94)
	add_child(fundo)

	var caixa := VBoxContainer.new()
	caixa.set_anchors_preset(Control.PRESET_FULL_RECT)
	caixa.offset_left = 24
	caixa.offset_top = 16
	caixa.offset_right = -24
	caixa.offset_bottom = -16
	caixa.add_theme_constant_override("separation", 6)
	add_child(caixa)

	var titulo := Label.new()
	titulo.text = "TECLADO DE SONS  --  S fecha"
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	caixa.add_child(titulo)

	for grupo: String in TECLADO:
		var rotulo := Label.new()
		rotulo.text = grupo
		rotulo.add_theme_font_size_override("font_size", 13)
		rotulo.add_theme_color_override("font_color", Color(0.72, 0.62, 0.86))
		caixa.add_child(rotulo)
		var linha := HFlowContainer.new()
		linha.add_theme_constant_override("h_separation", 5)
		linha.add_theme_constant_override("v_separation", 4)
		caixa.add_child(linha)
		for entrada: Array in TECLADO[grupo]:
			linha.add_child(_botao(entrada))

	_ultimo = Label.new()
	_ultimo.add_theme_font_size_override("font_size", 13)
	_ultimo.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7))
	caixa.add_child(_ultimo)


func _botao(entrada: Array) -> Button:
	var b := Button.new()
	b.text = String(entrada[0])
	b.custom_minimum_size = Vector2(0, 30)
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(func() -> void:
		Som.toca(String(entrada[1]), float(entrada[2]), float(entrada[3]))
		if _ultimo:
			_ultimo.text = "%s  ->  %s  (%.0f dB, tom %.2f)" % [
				entrada[0], entrada[1], entrada[2], entrada[3]])
	return b


func alternar() -> void:
	visible = not visible
	# Sem pausar o jogo nao se ouvia nada de jeito por cima da accao.
	get_tree().paused = visible
