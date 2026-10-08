extends Nivel3D
## N03 -- Ninho da Viuva Negra (COMBINACAO). Movimento + combate + perigos:
## porta de raizes com teias, ARENA de emboscada entre casulos, travessia do
## abismo (tronco, lajes, ponte de raiz), trilho estreito com raizes e espinhos.
## Landmark: a TEIA GIGANTE entre duas arvores mortas, com um casulo-coracao
## a pulsar ao centro -- visivel desde a arena.


func construir() -> void:
	indice = 2
	perfil = 2
	y_morte = -6.0
	spawn = Vector3(0, 0.2, -1)
	lado_camara = -1.0
	# 1. entrada: porta de raizes com teias
	ilha(Vector3(0, 0, 0), 7.0, 6.5, 0.0, 4.0, "terreno", 41)
	D.arvore(deco, Vector3(-4.5, 0, 6), 18.0, 1.1, 41, true)
	D.arvore(deco, Vector3(5, 0, 6.5), 17.0, 1.0, 42, true)
	D.teia(deco, Vector3(0.2, 6.5, 6.5), 4.2, 0.0, 1)
	D.casulo(deco, Vector3(-2.5, 4.0, 3), 0.9, 1)
	D.casulo(deco, Vector3(3.0, 3.5, -2), 1.1, 2)
	D.cristais(deco, Vector3(-4.5, 0, -3), 0.8, 41)
	folhagem(Vector3(0, 0, 0), 6.5, 70, "feto_corrompido", 41)
	folhagem(Vector3(0, 0, 0), 6.5, 60, "erva", 42)
	passo(Vector3(0, 0, 0))
	passo(Vector3(0.5, 0, 5))
	faixa(Vector3(0.5, 0, 5), Vector3(2.5, 0, 18), 5.0, 3.0, "terreno", 41)
	passo(Vector3(2.0, 0, 15))
	# 2. ARENA da emboscada (4 goblins + gosma)
	ilha(Vector3(3, 0, 28), 10.5, 9.5, 0.0, 5.0, "terreno", 42)
	for i in 7:
		var a := TAU * i / 7.0 + 0.4
		var p := Vector3(3, 0, 28) + Vector3(cos(a), 0, sin(a)) * 8.6
		if (p.z < 22.0 and absf(p.x - 2.5) < 4.0) or (p.z > 33.0 and absf(p.x - 5.0) < 4.5):
			continue
		if i % 2 == 0:
			D.pilar(deco, p, randf_range(4.5, 7.0), 0.5, 40 + i, true)
		else:
			D.casulo(deco, p + Vector3.UP * 3.5, 1.2, 40 + i)
			D.rocha(deco, p, 1.2, 40 + i, "rocha", true)
	espinhos(Vector3(-4.5, 0, 28), Vector2(1.8, 4.0), 0.0)
	espinhos(Vector3(10.5, 0, 26), Vector2(1.8, 3.4), 0.2)
	inimigo("goblin", Vector3(1, 0, 27), 2.0)
	inimigo("goblin", Vector3(5, 0, 29), 2.0)
	inimigo("goblin", Vector3(2, 0, 33), 2.0)
	inimigo("gosma", Vector3(6, 0, 32), 2.0)
	D.raio_luz(deco, Vector3(3, 0, 28), 24.0, 5.0, true)
	folhagem(Vector3(3, 0, 28), 9.0, 120, "feto_corrompido", 43)
	passo(Vector3(2.5, 0, 22), false, true)
	passo(Vector3(3.0, 0, 28), false, true)
	passo(Vector3(4.5, 0, 34), false, true)
	passo(Vector3(5.5, 0, 36.5))
	# 3. travessia do abismo: tronco -> lajes -> ponte de raiz
	D.tronco_caido(terreno, Vector3(5.3, -0.45, 37.0), Vector3(8.5, -0.3, 47.0), 0.62, 41)
	passo(Vector3(5.8, 0.2, 38.5))
	passo(Vector3(8.2, 0.3, 46.2))
	var lajes := [Vector3(10.0, 1.1, 50.5), Vector3(12.8, 1.8, 54.2)]
	passo(Vector3(8.5, 0.3, 47.0), true)
	cadeia_lajes(lajes, 2.8, 41, Vector3(15.5, 2.2, 57.0))
	ponte_raiz(Vector3(14.0, 1.9, 55.5), Vector3(20.0, 2.6, 64.0), 2.0, 0.6, 41)
	passo(Vector3(14.6, 2.6, 56.4))
	passo(Vector3(17.2, 2.8, 60.0))
	passo(Vector3(19.6, 2.7, 63.4))
	# 4. plataforma da teia gigante (landmark) + fogueira
	ilha(Vector3(22, 2.6, 68), 6.5, 6.0, 0.4, 4.5, "terreno", 43)
	fogueira("n03_cp1", Vector3(20.5, 2.6, 66.0))
	D.arvore(deco, Vector3(30, -4, 64), 30.0, 1.8, 44, true, false, false)
	D.arvore(deco, Vector3(32, -4, 82), 32.0, 1.9, 45, true, false, false)
	D.teia(deco, Vector3(31, 10.0, 73), 8.5, PI * 0.5 + 0.1, 2)
	var coracao := K.inst(deco, K.rocha(1.4, 4, 1.6, 0.2), K.mat("casulo"), Vector3(31, 10.0, 73))
	coracao.scale = Vector3(1, 1, 1)
	var lz := OmniLight3D.new()
	lz.light_color = Color(1.0, 0.2, 0.6)
	lz.light_energy = 4.0
	lz.omni_range = 16.0
	lz.position = Vector3(29, 10.0, 73)
	deco.add_child(lz)
	inimigo("gosma", Vector3(23, 2.6, 70), 2.0)
	inimigo("gosma", Vector3(21, 2.6, 71.5), 2.0)
	folhagem(Vector3(22, 2.6, 68), 6.0, 70, "feto_corrompido", 44)
	passo(Vector3(21.5, 2.6, 66.5))
	passo(Vector3(22.0, 2.6, 70.0), false, true)
	passo(Vector3(22.2, 2.6, 73.5))
	# 5. trilho estreito de raizes: raizes que irrompem + espinhos
	faixa(Vector3(22.2, 2.6, 73.0), Vector3(23.8, 2.6, 89.0), 3.2, 3.0, "terreno", 44)
	raiz_perigo(Vector3(22.6, 2.6, 78.0), 2.8, 0.0, 1.3)
	raiz_perigo(Vector3(23.3, 2.6, 84.0), 2.8, 1.4, 1.3)
	inimigo("goblin", Vector3(23.6, 2.6, 87.5), 1.0)
	D.casulo(deco, Vector3(20.5, 6.0, 80), 1.0, 7)
	D.casulo(deco, Vector3(26.0, 5.5, 85), 0.8, 8)
	passo(Vector3(22.5, 2.6, 76.0))
	passo(Vector3(23.0, 2.6, 81.0))
	passo(Vector3(23.6, 2.6, 86.0), false, true)
	# 6. saida
	ilha(Vector3(24, 2.6, 94), 6.0, 5.0, 0.0, 4.0, "terreno", 45)
	saida(Vector3(24, 2.6, 96.5), PI)
	D.arvore(deco, Vector3(18.5, 2.6, 96), 14.0, 0.9, 46, true)
	D.teia(deco, Vector3(28.5, 4.5, 95), 2.8, PI * 0.4, 3)
	folhagem(Vector3(24, 2.6, 94), 5.0, 50, "feto_corrompido", 45)
	passo(Vector3(24.0, 2.6, 92.0))
	passo(Vector3(24.0, 2.6, 96.5))
	# abismo com nevoa (sem pantano: escuridao + cristais la' em baixo)
	K.inst(self, PlaneMesh.new(), K.mat("veneno"), Vector3(14, -7.0, 50), Vector3.ZERO, Vector3(160, 1, 160), false)
	D.fundo_floresta(deco, Vector3(14, -2, 50), 36.0, 56.0, 40, 3, 0.4)
	for i in 10:
		D.cristais(deco, Vector3(randf_range(-10, 35), -6.5, randf_range(0, 100)), randf_range(1.0, 2.0), 60 + i)
	for i in 8:
		D.teia(deco, Vector3(randf_range(-12, 38), randf_range(3, 9), randf_range(0, 100)), randf_range(1.5, 3.5),
			randf() * TAU, 10 + i)
	VFX.esporos(self, Vector3(14, 3, 50), Vector3(22, 4, 50), Color(0.8, 0.5, 1.0, 0.8), 140)
