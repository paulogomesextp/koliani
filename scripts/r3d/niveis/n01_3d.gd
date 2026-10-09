extends Nivel3D
## N01 -- Floresta Putrefata (TEACH). Ensina movimento 3D, salto e espada.
## Landmark: a ARVORE-MAE corrompida (gigante, ao centro), cujas raizes formam
## a ponte do meio. Fecho com o guardiao (bruto) diante do portal, como o
## Ghorak fecha o N1 em 2D.


func construir() -> void:
	indice = 0
	perfil = 0
	y_morte = -3.5
	spawn = Vector3(0, 0.2, 0)
	spawn_rumo = 0.0
	# 1. clareira de entrada (arco sagrado atras, luar)
	ilha(Vector3(0, 0, -1.5), 9.0, 9.5, 0.0, 4.0, "terreno", 1)
	D.arco(deco, Vector3(0, 0, -9.0), 0.0, 4.4, 5.0, 3)
	D.raio_luz(deco, Vector3(2, 0, 2), 16.0, 3.0)
	D.menir(deco, Vector3(-5, 0, 2), 3.0, 1)
	D.cogumelos(deco, Vector3(5.5, 0, -2), 6, 1)
	folhagem(Vector3(0, 0, 0), 8.5, 90, "feto", 1)
	folhagem(Vector3(0, 0, 0), 8.5, 120, "erva", 2)
	passo(Vector3(0, 0, 0))
	passo(Vector3(0.5, 0, 6))
	# 2. trilho da floresta (1.a gosma)
	faixa(Vector3(0.5, 0, 5), Vector3(4, 0, 27), 5.0, 3.0, "terreno", 2)
	for p in [Vector3(-6.5, 0, 12), Vector3(9.5, 0, 14), Vector3(-5, 0, 22), Vector3(11, 0, 26)]:
		ilha(Vector3(p.x, -0.3, p.z), 3.0, 3.0, 0.0, 3.0, "terreno", 5)
		D.arvore(deco, p, randf_range(10, 14), 0.65, int(p.z))
	inimigo("gosma", Vector3(3, 0, 19), 2.0)
	D.rocha(deco, Vector3(-1.5, 0, 16), 0.9, 4, "rocha", true)
	folhagem(Vector3(2, 0, 16), 6.0, 70, "feto", 3)
	folhagem(Vector3(2, 0, 16), 6.0, 90, "erva", 4)
	passo(Vector3(3, 0, 15))
	passo(Vector3(4, 0, 24))
	# 3. primeiro degrau + primeiro salto sobre o veneno
	ilha(Vector3(5.5, 1.0, 33), 4.5, 4.0, 0.3, 3.5, "terreno", 6)
	passo(Vector3(4.6, 0, 27.6), true)
	passo(Vector3(5.5, 1.0, 32))
	ilha(Vector3(4.5, 1.0, 43), 3.6, 3.4, 0.0, 3.5, "terreno", 7)
	passo(Vector3(5.4, 1.0, 35.8), true)
	passo(Vector3(4.5, 1.0, 42))
	D.cristais(deco, Vector3(6.5, 1.0, 44.5), 0.8, 2)
	# 4. tronco caido como ponte
	D.tronco_caido(terreno, Vector3(4.3, 0.55, 45.5), Vector3(2.2, 0.55, 56.5), 0.62, 3)
	passo(Vector3(4.2, 1.1, 46.4))
	passo(Vector3(2.4, 1.1, 55.8))
	# 5. clareira da Arvore-Mae (landmark) + fogueira + 2 goblins
	ilha(Vector3(0, 0.5, 67), 11.0, 10.0, 0.2, 4.5, "terreno", 8)
	D.arvore_gigante(deco, Vector3(-9, 0.5, 72), 34.0, 3.0, 11, true)
	D.corrupcao(deco, Vector3(-5.5, 0.5, 70), 1.4, 5)
	D.corrupcao(deco, Vector3(-6.5, 0.5, 64), 0.9, 6)
	D.raio_luz(deco, Vector3(1, 0.5, 67), 20.0, 4.0)
	D.raio_luz(deco, Vector3(-6, 0.5, 70), 22.0, 2.5, true)
	fogueira("n01_cp1", Vector3(-1.0, 0.5, 59.5))
	inimigo("goblin", Vector3(2, 0.5, 69), 3.0)
	inimigo("goblin", Vector3(-2, 0.5, 72), 3.0)
	D.pilar(deco, Vector3(6, 0.5, 63), 5.5, 0.45, 1, true)
	D.pilar(deco, Vector3(7, 0.5, 71), 6.0, 0.45, 2, true)
	D.cogumelos(deco, Vector3(-3, 0.5, 75), 7, 2)
	folhagem(Vector3(0, 0.5, 67), 10.0, 130, "feto", 5)
	folhagem(Vector3(0, 0.5, 67), 10.0, 160, "erva", 6)
	folhagem(Vector3(3, 0.5, 70), 6.0, 30, "folha_larga", 7)
	passo(Vector3(1.5, 0.5, 58))
	passo(Vector3(0, 0.5, 64), false, true)
	passo(Vector3(1.5, 0.5, 72), false, true)
	passo(Vector3(2.0, 0.5, 76.0))
	# 6. ponte de raiz da Arvore-Mae (sobe)
	ponte_raiz(Vector3(2.0, 0.5, 76.5), Vector3(6.5, 1.6, 90.5), 2.0, 0.5, 4)
	passo(Vector3(4.2, 1.2, 83))
	passo(Vector3(6.4, 1.7, 89.5))
	# 7. ruinas: degraus de pedra sagrada a subir
	ilha(Vector3(7.5, 1.6, 93), 3.2, 3.0, 0.0, 3.0, "terreno", 9)
	laje_pedra(Vector3(9.0, 2.5, 98.5), Vector3(2.8, 0.7, 2.8), 0.2, 1)
	laje_pedra(Vector3(9.8, 3.3, 103), Vector3(2.8, 0.7, 2.8), -0.1, 2)
	passo(Vector3(7.8, 1.6, 94.6), true)
	passo(Vector3(9.0, 2.5, 98.5))
	passo(Vector3(9.4, 2.5, 99.8), true)
	passo(Vector3(9.8, 3.3, 103))
	ilha(Vector3(10, 3.3, 111), 6.5, 5.5, 0.4, 4.0, "terreno", 10)
	passo(Vector3(10.0, 3.3, 104.4), true)
	passo(Vector3(10, 3.3, 107.5))
	raiz_perigo(Vector3(12.5, 3.3, 111), 3.4, 0.0, 1.2)
	D.pilar(deco, Vector3(5.5, 3.3, 109), 5.0, 0.5, 4, true)
	D.pilar(deco, Vector3(14.5, 3.3, 113), 6.0, 0.5, 5, false)
	D.menir(deco, Vector3(13.5, 3.3, 107), 2.6, 3)
	inimigo("goblin", Vector3(9, 3.3, 112), 2.0)
	inimigo("gosma", Vector3(11, 3.3, 115), 1.5)
	folhagem(Vector3(10, 3.3, 111), 6.0, 70, "feto", 8)
	folhagem(Vector3(10, 3.3, 111), 6.0, 90, "erva", 9)
	passo(Vector3(9.0, 3.3, 112), false, true)
	# 8. aproximacao final: guardiao + portal
	faixa(Vector3(9.5, 3.3, 115), Vector3(8, 3.3, 132), 6.0, 3.5, "terreno", 11)
	ilha(Vector3(8, 3.3, 134), 6.0, 5.0, 0.0, 4.0, "terreno", 12)
	inimigo("bruto", Vector3(8.5, 3.3, 124), 2.0)
	for s in [-1.0, 1.0]:
		D.arvore(deco, Vector3(8 + s * 7.5, 2.0, 124 + s * 3), 15.0, 0.8, 30 + int(s), s > 0)
	D.corrupcao(deco, Vector3(4.5, 3.3, 127), 1.0, 9)
	saida(Vector3(8, 3.3, 136), PI)
	folhagem(Vector3(8.5, 3.3, 126), 6.0, 80, "feto", 10)
	folhagem(Vector3(8, 3.3, 134), 5.0, 60, "erva", 11)
	passo(Vector3(8.8, 3.3, 121), false, true)
	passo(Vector3(8.3, 3.3, 128), false, true)
	passo(Vector3(8, 3.3, 136))
	# pantano envenenado em baixo + floresta de fundo
	veneno(Vector3(5, -3.0, 68), Vector2(140, 190))
	D.fundo_floresta(deco, Vector3(5, 0, 68), 38.0, 60.0, 44, 1, 0.15, rota)
	for i in 14:
		var z := 8.0 + i * 9.0
		var x := 5.0 + (16.0 if i % 2 == 0 else -14.0) + sin(i * 1.7) * 3.0
		D.arvore(deco, Vector3(x, -3.0, z), randf_range(14, 22), randf_range(0.7, 1.1), 50 + i, i % 5 == 2, true, false)
		D.rocha(deco, Vector3(x * 0.8 + 2, -2.8, z + 4), randf_range(1.0, 2.2), 60 + i, "rocha")
	VFX.esporos(self, Vector3(5, 3, 68), Vector3(20, 4, 70), Color(0.6, 1.0, 0.7, 0.9), 160)
