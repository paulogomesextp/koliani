extends Nivel3D
## N02 -- Pantano dos Sussurros (DESENVOLVIMENTO). Mais verticalidade: pedras
## sagradas a saltar sobre o pantano envenenado, ponte de raiz a subir, espinhos
## e raizes que irrompem, composicao goblin+gosma.
## Landmark: a TORRE SAGRADA AFUNDADA, inclinada no meio do pantano, com luz
## esmeralda no topo -- o percurso contorna-a pela base.


func construir() -> void:
	indice = 1
	perfil = 1
	y_morte = -2.2
	spawn = Vector3(0, 0.2, 0)
	# 1. cais de raizes (inicio)
	ilha(Vector3(0, 0, 0), 6.5, 5.5, 0.3, 3.5, "terreno_pantano", 21)
	D.arvore(deco, Vector3(-5.5, 0, -2.5), 12.0, 0.7, 21, false)
	D.cogumelos(deco, Vector3(3.5, 0, -2), 6, 3)
	D.menir(deco, Vector3(-3, 0, 3.5), 2.6, 4)
	folhagem(Vector3(0, 0, 0), 6.0, 70, "erva", 21)
	folhagem(Vector3(0, 0, 0), 6.0, 40, "folha_larga", 22)
	passo(Vector3(0, 0, 0))
	passo(Vector3(0.5, 0, 3.0))
	# 2. pedras sagradas sobre o pantano
	var pedras := [Vector3(1.5, 0.2, 9.0), Vector3(3.5, 0.6, 13.2), Vector3(3.0, 1.0, 17.6), Vector3(5.0, 1.0, 21.8)]
	salto_de(Vector3(0.5, 0, 3.0), pedras[0], 2.6)
	cadeia_lajes(pedras, 2.8, 21, Vector3(6.5, 1.0, 29))
	# 3. ilha dos goblins (espinhos, arvore corrompida)
	ilha(Vector3(6.5, 1.0, 31), 7.5, 6.0, 0.2, 4.0, "terreno_pantano", 22)
	espinhos(Vector3(3.0, 1.0, 33), Vector2(2.2, 3.0), 0.3)
	D.arvore(deco, Vector3(11, 1.0, 34), 14.0, 0.9, 22, true)
	D.corrupcao(deco, Vector3(9.5, 1.0, 29), 0.9, 21)
	inimigo("goblin", Vector3(7, 1.0, 32), 2.5)
	inimigo("goblin", Vector3(9, 1.0, 35), 2.0)
	folhagem(Vector3(6.5, 1.0, 31), 6.5, 80, "erva", 23)
	folhagem(Vector3(6.5, 1.0, 31), 6.0, 50, "feto", 24)
	passo(Vector3(6.0, 1.0, 27.0))
	passo(Vector3(6.5, 1.0, 31.0), false, true)
	passo(Vector3(7.0, 1.0, 35.5))
	# 4. ponte de raiz a subir ate' a base da torre
	ponte_raiz(Vector3(7.0, 1.0, 36.5), Vector3(13.0, 2.4, 47.0), 2.0, 0.7, 22)
	passo(Vector3(10.0, 1.9, 41.8))
	passo(Vector3(12.8, 2.5, 46.3))
	# 5. base da torre afundada (landmark) + fogueira
	ilha(Vector3(15.0, 2.4, 52.0), 7.0, 6.0, 0.6, 4.0, "terreno_pantano", 23)
	D.torre_afundada(deco, Vector3(21.5, -2.0, 56.0), 26.0, 3.4, 0.1, 2)
	fogueira("n02_cp1", Vector3(13.0, 2.4, 50.0))
	raiz_perigo(Vector3(16.5, 2.4, 54.0), 3.0, 0.0, 1.2)
	inimigo("gosma", Vector3(14.5, 2.4, 55.5), 1.5)
	D.cogumelos(deco, Vector3(18.5, 2.4, 49.5), 7, 5, 1.3)
	D.raio_luz(deco, Vector3(17, 2.4, 53), 22.0, 3.5)
	folhagem(Vector3(15, 2.4, 52), 6.5, 90, "erva", 25)
	passo(Vector3(13.5, 2.4, 51.0))
	passo(Vector3(13.0, 2.4, 55.0), false, true)
	passo(Vector3(13.5, 2.4, 57.0))
	# 6. degraus de ruina a subir (contornar a torre)
	var degraus := [Vector3(12.8, 3.3, 61.2), Vector3(14.5, 4.2, 66.0), Vector3(17.5, 4.6, 69.5)]
	salto_de(Vector3(13.5, 2.4, 57.0), degraus[0], 0.4)
	cadeia_lajes(degraus, 2.8, 31, Vector3(22.0, 4.6, 74.0))
	# 7. platô alto: gosmas + goblin, raizes alternadas
	ilha(Vector3(23.5, 4.6, 76.5), 7.0, 6.5, 0.0, 5.0, "terreno_pantano", 24)
	raiz_perigo(Vector3(21.0, 4.6, 78.0), 3.2, 0.0, 1.1)
	raiz_perigo(Vector3(25.5, 4.6, 75.0), 3.2, 1.6, 1.1)
	inimigo("gosma", Vector3(24, 4.6, 79), 2.0)
	inimigo("gosma", Vector3(26, 4.6, 77), 2.0)
	inimigo("goblin", Vector3(22, 4.6, 81), 2.0)
	D.pilar(deco, Vector3(28.5, 4.6, 74.5), 6.0, 0.5, 31, true)
	D.pilar(deco, Vector3(18.5, 4.6, 79.5), 5.0, 0.5, 32, true)
	D.arvore(deco, Vector3(28, 4.6, 81), 13.0, 0.8, 33, false)
	folhagem(Vector3(23.5, 4.6, 76.5), 6.5, 90, "feto", 26)
	passo(Vector3(21.5, 4.6, 74.5))
	passo(Vector3(23.5, 4.6, 78.0), false, true)
	passo(Vector3(23.5, 4.6, 82.0))
	# 8. descida por rampa ate' ao portal
	rampa(Vector3(23.5, 4.6, 83.0), Vector3(22.0, 2.6, 92.0), 3.4, 1.6, "terreno_pantano", 25)
	ilha(Vector3(21.5, 2.6, 96.0), 6.0, 5.0, 0.0, 4.0, "terreno_pantano", 26)
	espinhos(Vector3(18.0, 2.6, 95.0), Vector2(1.6, 3.0), 0.0)
	espinhos(Vector3(25.0, 2.6, 97.0), Vector2(1.6, 2.6), 0.4)
	saida(Vector3(21.5, 2.6, 99.0), PI)
	D.arvore(deco, Vector3(15, 2.6, 99), 13.0, 0.8, 34, true)
	folhagem(Vector3(21.5, 2.6, 96.0), 5.0, 60, "erva", 27)
	passo(Vector3(23.0, 3.8, 87.0))
	passo(Vector3(22.0, 2.6, 93.0))
	passo(Vector3(21.5, 2.6, 99.0))
	# pantano + fundo
	veneno(Vector3(12, -1.6, 50), Vector2(150, 170))
	D.fundo_floresta(deco, Vector3(12, 0, 50), 36.0, 58.0, 40, 2, 0.2)
	for i in 16:
		var z := i * 7.0
		var x := 12.0 + (17.0 if i % 2 == 0 else -15.0) + sin(i * 2.3) * 4.0
		D.arvore(deco, Vector3(x, -1.6, z), randf_range(10, 18), randf_range(0.5, 0.9), 70 + i, i % 4 == 1, i % 3 != 0, false)
		if i % 3 == 0:
			D.cogumelos(deco, Vector3(x + 1.5, -1.5, z + 2), 5, i, 1.2)
	VFX.esporos(self, Vector3(12, 2, 50), Vector3(22, 3, 55), Color(0.75, 1.0, 0.4, 0.8), 180)
