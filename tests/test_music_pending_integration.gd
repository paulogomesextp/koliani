extends Node
## Verifica as 40 faixas regionais/de boss e transições representativas.

const REGIOES := [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
const BOSSES := [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]


func _ready() -> void:
	call_deferred("_verificar")


func _verificar() -> void:
	var falhas: Array[String] = []
	var regiao_01 := "res://assets/audio/approved/region_01_midnight_forest.mp3"
	var boss_01 := "res://assets/audio/approved/boss_01_gothic_candlelight.mp3"
	if Musica.faixa_de_nivel(0) != regiao_01 or Musica.faixa_de_nivel(4) != regiao_01:
		falhas.append("Regiao 01 alterada")
	if Musica.faixa_de_chefe(0) != boss_01 or Musica.faixa_de_chefe(4) != boss_01:
		falhas.append("Boss 01 alterado")
	for regiao in REGIOES:
		var caminho: String = "res://assets/audio/music/regions/region_%02d.mp3" % regiao
		var stream := load(caminho) as AudioStreamMP3
		if stream == null or stream.get_length() <= 0.0:
			falhas.append("Stream regional invalido: " + caminho)
		for nivel in range((regiao - 1) * 5, regiao * 5):
			if Musica.faixa_de_nivel(nivel) != caminho:
				falhas.append("Mapping regional incorreto: nivel %d" % nivel)
	for regiao in BOSSES:
		var caminho: String = "res://assets/audio/music/bosses/boss_%02d.mp3" % regiao
		var stream := load(caminho) as AudioStreamMP3
		if stream == null or stream.get_length() <= 0.0:
			falhas.append("Stream boss invalido: " + caminho)
		for nivel in range((regiao - 1) * 5, regiao * 5):
			if Musica.faixa_de_chefe(nivel) != caminho:
				falhas.append("Mapping boss incorreto: nivel %d" % nivel)
	for regiao in [1, 7, 9, 12, 13, 20]:
		var nivel: int = (regiao - 1) * 5
		EstadoJogo.indice_nivel = nivel
		Musica.ambiente(nivel)
		if Musica._caminho_atual != Musica.faixa_de_nivel(nivel):
			falhas.append("Entrada regional falhou: %d" % regiao)
		Musica.boss()
		if Musica._caminho_atual != Musica.faixa_de_chefe(nivel):
			falhas.append("Entrada boss falhou: %d" % regiao)
		Musica.ambiente(nivel)
		if Musica._caminho_atual != Musica.faixa_de_nivel(nivel):
			falhas.append("Regresso regional falhou: %d" % regiao)
	Musica.menu()
	if Musica._caminho_atual != Musica.MENU_APROVADO:
		falhas.append("Regresso ao menu falhou")
	if not Musica._p.playing:
		falhas.append("Cama principal nao toca no menu")
	await get_tree().create_timer(1.2).timeout
	if Musica._p2.playing:
		falhas.append("Segunda cama persistiu depois do fade")
	for falha in falhas:
		printerr("MUSIC PENDING FAIL: ", falha)
	print("MUSIC PENDING: %d falhas" % falhas.size())
	get_tree().quit(0 if falhas.is_empty() else 1)
