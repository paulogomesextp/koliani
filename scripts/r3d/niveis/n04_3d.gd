extends Nivel3D
## N04 -- A Arvore que Chora (DESAFIO). Subida em espiral pelas raizes do
## SALGUEIRO CHORAO gigante (landmark), com o bruto a guardar o patamar do meio,
## tronco suspenso sobre o vazio e raizes que irrompem. No fim, a varanda das
## raizes mostra ao longe o CORACAO DA FLORESTA a pulsar (prenuncio do chefe).


func construir() -> void:
	indice = 3
	perfil = 3
	y_morte = -4.0
	spawn = Vector3(0, 0.2, 0)
	# landmark: o salgueiro, no centro da espiral
	D.salgueiro(deco, Vector3(22, -2.0, 40), 34.0, 4.0, 51)
	# 1. base
	ilha(Vector3(0, 0, 0), 7.0, 6.0, 0.0, 4.0, "terreno", 51)
	D.menir(deco, Vector3(-4, 0, 2), 3.0, 51)
	D.pilar(deco, Vector3(4.5, 0, -2.5), 5.0, 0.5, 51, true)
	D.cogumelos(deco, Vector3(-3.5, 0, -3), 6, 51)
	folhagem(Vector3(0, 0, 0), 6.0, 70, "feto", 51)
	folhagem(Vector3(0, 0, 0), 6.0, 70, "erva", 52)
	passo(Vector3(0, 0, 0))
	passo(Vector3(1.5, 0, 5))
	# 2. rampa de raiz para o 1.o patamar (goblins + espinhos)
	rampa(Vector3(1.8, 0, 6.0), Vector3(3.8, 1.8, 13.5), 3.4, 1.6, "terreno", 51)
	ilha(Vector3(5, 1.8, 18), 5.5, 5.0, 0.3, 4.0, "terreno", 52)
	espinhos(Vector3(1.8, 1.8, 19), Vector2(1.6, 3.0), 0.0)
	inimigo("goblin", Vector3(5, 1.8, 18), 2.0)
	inimigo("goblin", Vector3(7, 1.8, 20), 1.5)
	folhagem(Vector3(5, 1.8, 18), 5.0, 50, "feto", 53)
	passo(Vector3(3.0, 1.0, 10.0))
	passo(Vector3(4.2, 1.8, 15.0))
	passo(Vector3(5.0, 1.8, 18.5), false, true)
	# 3. lajes a subir
	var lajes := [Vector3(9.5, 2.7, 22.0), Vector3(12.2, 3.6, 25.3), Vector3(14.5, 4.5, 29.0)]
	salto_de(Vector3(5.0, 1.8, 18.5), lajes[0], 2.8)
	cadeia_lajes(lajes, 2.8, 51, Vector3(15.5, 4.5, 35.0))
	# 4. patamar do bruto + fogueira
	ilha(Vector3(14.5, 4.5, 36.5), 6.5, 6.0, 0.4, 4.5, "terreno", 53)
	fogueira("n04_cp1", Vector3(12.0, 4.5, 33.0))
	inimigo("bruto", Vector3(15.5, 4.5, 38.5), 1.5)
	D.raio_luz(deco, Vector3(14.5, 4.5, 37), 24.0, 4.0)
	D.cristais(deco, Vector3(10, 4.5, 38), 1.0, 52)
	folhagem(Vector3(14.5, 4.5, 36.5), 6.0, 80, "feto", 54)
	passo(Vector3(13.5, 4.5, 34.0))
	passo(Vector3(14.5, 4.5, 38.0), false, true)
	passo(Vector3(14.5, 4.5, 42.0))
	# 5. ponte de raiz a subir
	ponte_raiz(Vector3(14.5, 4.5, 43.0), Vector3(12.5, 6.0, 53.0), 2.0, 0.6, 52)
	ilha(Vector3(12.0, 6.0, 57.0), 5.5, 5.0, 0.2, 4.0, "terreno", 54)
	raiz_perigo(Vector3(10.0, 6.0, 57.5), 3.0, 0.5, 1.1)
	inimigo("gosma", Vector3(13, 6.0, 58), 1.5)
	inimigo("gosma", Vector3(11, 6.0, 60), 1.5)
	folhagem(Vector3(12, 6.0, 57), 5.0, 50, "erva", 55)
	passo(Vector3(13.8, 5.3, 48.0))
	passo(Vector3(12.6, 6.1, 52.4))
	passo(Vector3(12.5, 6.0, 57.0), false, true)
	passo(Vector3(12.8, 6.0, 61.0))
	# 6. tronco suspenso sobre o vazio
	D.tronco_caido(terreno, Vector3(12.8, 5.45, 61.5), Vector3(10.5, 5.45, 72.0), 0.6, 52)
	passo(Vector3(12.6, 6.0, 62.5))
	passo(Vector3(10.8, 6.0, 71.2))
	ilha(Vector3(10.0, 6.0, 76.0), 5.0, 5.0, 0.0, 4.0, "terreno", 55)
	raiz_perigo(Vector3(8.0, 6.0, 76.5), 2.6, 0.0, 1.1)
	raiz_perigo(Vector3(12.0, 6.0, 77.5), 2.6, 1.3, 1.1)
	espinhos(Vector3(14.0, 6.0, 75.0), Vector2(1.4, 2.4), 0.0)
	inimigo("goblin", Vector3(10, 6.0, 78), 1.5)
	passo(Vector3(10.0, 6.0, 74.0))
	passo(Vector3(10.0, 6.0, 78.5), false, true)
	# 7. lajes finais ate' a varanda (prenuncio)
	var lajes2 := [Vector3(9.0, 6.8, 83.6), Vector3(8.0, 7.2, 87.8)]
	salto_de(Vector3(10.0, 6.0, 78.5), lajes2[0], 2.6)
	cadeia_lajes(lajes2, 2.8, 61, Vector3(8.0, 7.2, 93.0))
	ilha(Vector3(8.0, 7.2, 95.0), 6.5, 5.0, 0.0, 4.5, "terreno_corrompido", 56)
	D.corrupcao(deco, Vector3(4, 7.2, 96), 1.0, 51)
	D.corrupcao(deco, Vector3(12.5, 7.2, 94), 0.8, 52)
	saida(Vector3(8.0, 7.2, 97.5), PI)
	passo(Vector3(8.0, 7.2, 92.5))
	passo(Vector3(8.0, 7.2, 97.5))
	# o CORACAO ao longe: massa pulsante + coluna de luz magenta
	var longe := Vector3(-10, 4, 175)
	K.inst(deco, K.rocha(9.0, 8, 1.1, 0.3), K.mat("carne"), longe)
	for i in 6:
		var a := TAU * i / 6.0
		var pts := K.curva(PackedVector3Array([longe + Vector3(cos(a) * 6, 2, sin(a) * 6), longe + Vector3(cos(a) * 14, -4, sin(a) * 14),
			longe + Vector3(cos(a) * 22, -12, sin(a) * 22)]), 3)
		K.inst(deco, K.tubo(pts, K.afunilar(pts.size(), 2.2, 0.6), 7, 0.2, i), K.mat("casca_morta"))
	D.raio_luz(deco, longe + Vector3(0, -6, 0), 60.0, 6.0, true)
	var lz := OmniLight3D.new()
	lz.light_color = Color(1.0, 0.15, 0.5)
	lz.light_energy = 8.0
	lz.omni_range = 40.0
	lz.position = longe + Vector3(0, 6, -10)
	deco.add_child(lz)
	# vazio + fundo
	K.inst(self, PlaneMesh.new(), K.mat("veneno"), Vector3(12, -5.0, 50), Vector3.ZERO, Vector3(120, 1, 120), false)
	D.fundo_floresta(deco, Vector3(12, -2, 50), 36.0, 55.0, 38, 4, 0.15)
	for i in 12:
		var z := i * 9.0
		var x := 12.0 + (18.0 if i % 2 == 0 else -16.0)
		D.arvore(deco, Vector3(x, -5, z), randf_range(16, 24), randf_range(0.8, 1.2), 90 + i, i % 5 == 0, true, false)
	VFX.esporos(self, Vector3(18, 8, 45), Vector3(16, 10, 30), Color(0.5, 0.9, 1.0, 0.9), 220)
