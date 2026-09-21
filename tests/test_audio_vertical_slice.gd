extends Node
## Teste dirigido: apenas os quatro recursos do Audio Vertical Slice.

func _ready() -> void:
	call_deferred("_verificar")


func _verificar() -> void:
	var falhas: Array[String] = []
	var caminhos := [
		"res://assets/audio/approved/menu_cinematic_fantasy_dark_no_intro.ogg",
		"res://assets/audio/approved/region_01_midnight_forest.mp3",
		"res://assets/audio/approved/boss_01_gothic_candlelight.mp3",
		"res://assets/audio/approved/koliani_dash_wind_magic_5.wav",
	]
	for caminho in caminhos:
		var stream := load(caminho) as AudioStream
		if stream == null or stream.get_length() <= 0.0:
			falhas.append("stream invalido: " + caminho)
	if Musica.faixa_de_nivel(0) != caminhos[1] or Musica.faixa_de_nivel(4) != caminhos[1]:
		falhas.append("Regiao I nao usa a faixa aprovada")
	if Musica.faixa_de_chefe(0) != caminhos[2]:
		falhas.append("Boss 1 nao usa a faixa aprovada")
	if Som.CAMINHOS.get("dash") != caminhos[3]:
		falhas.append("Dash nao usa o derivado aprovado")
	Musica.menu()
	if Musica._caminho_atual != caminhos[0]:
		falhas.append("Menu nao usa a faixa aprovada")
	var menu_stream := Musica._p.stream as AudioStreamOggVorbis
	if menu_stream == null or not menu_stream.loop:
		falhas.append("Menu nao esta configurado para loop")
	if menu_stream == null or abs(menu_stream.get_length() - 139.692) > 0.02:
		falhas.append("Duracao do menu trimmed inesperada")
	Musica.ambiente(0)
	if Musica._caminho_atual != caminhos[1]:
		falhas.append("Ambiente nao trocou para a Regiao I")
	EstadoJogo.indice_nivel = 0
	Musica.boss()
	if Musica._caminho_atual != caminhos[2]:
		falhas.append("Boss nao fez a transicao")
	Musica.ambiente(0)
	if Musica._caminho_atual != caminhos[1]:
		falhas.append("Regresso do boss nao repôs a regiao")
	for falha in falhas:
		printerr("AUDIO VERTICAL SLICE FAIL: ", falha)
	print("AUDIO VERTICAL SLICE: %d falhas" % falhas.size())
	get_tree().quit(0 if falhas.is_empty() else 1)
