extends SceneTree
## A mecânica de estreia de cada nível **existe mesmo lá dentro**?
##
## O `verifica_jornada.gd` já garantia que a CÂMARA da estreia é gerada --
## mas isso só prova que o gerador a escolheu, não que os actores dela
## nasceram. Foi por aí que passou o pior bug da sessão de 5 set: sete
## actores construídos em código ficaram com a máscara de colisão por
## omissão (layer 1, o mundo) e a Koliani vive na **layer 2**. As mecânicas
## existiam na árvore, não existiam a jogar, e a verificação dizia
## "TUDO OK".
##
## Aqui percorrem-se os 100 níveis, constrói-se cada um, e para a estreia
## dele exige-se:
##
##  1. pelo menos um nó com o SCRIPT do actor dessa câmara;
##  2. que as `Area2D` desses actores tenham a layer 2 na máscara -- senão
##     nunca lhe tocam.
##
## A tabela câmara -> script é gerada do próprio `gerador_corredor.gd` (as
## funções `_f_<camara>` e o que elas instanciam, seguindo as auxiliares).
##
## Uso: Godot --headless --script res://tools/verifica_mecanicas.gd

## Só entram aqui os actores que a câmara instancia SEM CONDIÇÃO nenhuma.
## Os que vivem dentro de um `if _dif > ...` são legítimos de faltar num
## nível fácil -- exigi-los dava três falsos positivos. A `Plataforma`
## também sai: está em toda a parte e não prova mecânica nenhuma.
const ACTORES := {
	"alavanca": ["res://scenes/actors/Alavanca.tscn", "res://scenes/actors/PortaTrancada.tscn"],
	"ameaca": ["res://scripts/ameaca_que_avanca.gd"],
	"anel": ["res://scenes/actors/AguaVenenosa.tscn", "res://scenes/actors/DemonioBase.tscn"],
	"ar": ["res://scripts/zona_sem_ar.gd"],
	"areia": ["res://scenes/actors/Espinhos.tscn", "res://scenes/actors/ZonaGravidade.tscn"],
	"areia_no_ar": ["res://scenes/actors/DemonioBase.tscn", "res://scenes/actors/Torreta.tscn", "res://scripts/zona_escuridao.gd"],
	"arena": ["res://scenes/actors/DemonioBase.tscn"],
	"ariete": ["res://scenes/actors/Alavanca.tscn", "res://scenes/actors/PortaTrancada.tscn", "res://scenes/actors/Torreta.tscn", "res://scripts/ariete.gd"],
	"asas": ["res://scenes/actors/Coletavel.tscn"],
	"atoleiro": ["res://scripts/zona_afunda.gd"],
	"bifurcacao": ["res://scenes/actors/DemonioBase.tscn", "res://scenes/actors/Essencia.tscn"],
	"brasas": ["res://scripts/chao_quente.gd"],
	"caixas": ["res://scenes/actors/PortaTrancada.tscn", "res://scripts/bloco_empurravel.gd", "res://scripts/placa_peso.gd"],
	"catapulta": ["res://scenes/actors/PedraQueda.tscn", "res://scenes/actors/Torreta.tscn"],
	"ceifa": ["res://scenes/actors/DemonioBase.tscn", "res://scripts/ceifa.gd"],
	"chuva": ["res://scenes/actors/PedraQueda.tscn"],
	"ciclo": ["res://scenes/actors/Portal.tscn"],
	"circuito": ["res://scenes/actors/Alavanca.tscn", "res://scenes/actors/PortaTrancada.tscn"],
	"conves": ["res://scripts/plataforma_roda.gd"],
	"corredor": ["res://scenes/actors/Serra.tscn"],
	"correntes": ["res://scenes/actors/PlataformaCorrente.tscn"],
	"correnteza": ["res://scripts/corrente_lateral.gd"],
	"cripta": ["res://scenes/actors/PedraQueda.tscn"],
	"crossfire": ["res://scenes/actors/Torreta.tscn"],
	"elevador": ["res://scenes/actors/TumuloElevador.tscn"],
	"engrenagens": ["res://scripts/plataforma_roda.gd"],
	"escuro": ["res://scripts/zona_escuridao.gd"],
	"espectral": ["res://scenes/actors/PlataformaEspectral.tscn"],
	"espelhos": ["res://scenes/actors/Espelho.tscn"],
	"espinhos": ["res://scenes/actors/Espinhos.tscn"],
	"esporos": ["res://scenes/actors/ZonaGravidade.tscn"],
	"estatuas": ["res://scenes/actors/DemonioBase.tscn"],
	"ferry": ["res://scenes/actors/PenduloLamina.tscn", "res://scenes/actors/TumuloElevador.tscn"],
	"fogo": ["res://scenes/actors/Fogo.tscn"],
	"frio": ["res://scripts/zona_estado.gd"],
	"gancho": ["res://scripts/ponto_gancho.gd"],
	"gelo": ["res://scripts/zona_gelo.gd"],
	"grav_baixa": ["res://scenes/actors/ZonaGravidade.tscn"],
	"gravidade": ["res://scenes/actors/ZonaGravidade.tscn"],
	"gruta": ["res://scenes/actors/PedraQueda.tscn"],
	"guilhotinas": ["res://scenes/actors/Guilhotina.tscn"],
	"horda": ["res://scenes/actors/Alavanca.tscn", "res://scenes/actors/DemonioBase.tscn", "res://scenes/actors/PortaTrancada.tscn"],
	"imanes": ["res://scripts/iman.gd"],
	"impulso": ["res://scenes/actors/Impulsor.tscn"],
	"incorporeo": ["res://scenes/actors/DemonioBase.tscn"],
	"invertido": ["res://scripts/placa_gravidade.gd"],
	"lava_sobe": ["res://scenes/actors/AguaVenenosa.tscn"],
	"mare": ["res://scenes/actors/AguaVenenosa.tscn"],
	"martelos": ["res://scenes/actors/Guilhotina.tscn"],
	"mausoleu": ["res://scenes/actors/DemonioBase.tscn", "res://scripts/zona_escuridao.gd"],
	"memoria": ["res://scenes/actors/Essencia.tscn", "res://scenes/actors/Vela.tscn"],
	"mente": ["res://scenes/actors/Essencia.tscn", "res://scripts/sala_reescreve.gd"],
	"olhar": ["res://scenes/actors/PlataformaOlhar.tscn"],
	"orbita": ["res://scenes/actors/PlataformaFlutuante.tscn"],
	"para_raios": ["res://scenes/actors/ParaRaios.tscn", "res://scenes/actors/RaioTempestade.tscn"],
	"pedras": ["res://scenes/actors/PedraQueda.tscn"],
	"pendulos": ["res://scenes/actors/PenduloLamina.tscn"],
	"peso": ["res://scripts/plataforma_peso.gd"],
	"placa": ["res://scenes/actors/Alavanca.tscn", "res://scenes/actors/PortaTrancada.tscn"],
	"portal": ["res://scenes/actors/Portal.tscn"],
	"prensa": ["res://scenes/actors/ParedeMovel.tscn"],
	"prensa_fogo": ["res://scenes/actors/Fogo.tscn", "res://scenes/actors/ParedeMovel.tscn"],
	"provacao": ["res://scripts/zona_sem_poder.gd"],
	"quebra": ["res://scenes/actors/PlataformaQuebra.tscn"],
	"raizes": ["res://scenes/actors/RaizPerigo.tscn"],
	"reflexo": ["res://scripts/sombra_atrasada.gd"],
	"replicantes": ["res://scenes/actors/Alavanca.tscn", "res://scenes/actors/DemonioBase.tscn", "res://scenes/actors/PortaTrancada.tscn"],
	"ritmo": ["res://scenes/actors/PlataformaRitmada.tscn"],
	"rosas": ["res://scenes/actors/Espinhos.tscn"],
	"salvas": ["res://scenes/actors/Torreta.tscn"],
	"segredo": ["res://scenes/actors/Essencia.tscn", "res://scenes/actors/ParedeFragil.tscn"],
	"sem_chao": ["res://scenes/actors/Impulsor.tscn"],
	"serpente": ["res://scripts/serpente.gd"],
	"serras": ["res://scenes/actors/Serra.tscn"],
	"sinos": ["res://scenes/actors/SinoTorre.tscn"],
	"sombra": ["res://scripts/sombra_atrasada.gd"],
	"trampolim": ["res://scenes/actors/Trampolim.tscn"],
	"varredura": ["res://scenes/actors/PenduloLamina.tscn"],
	"velas": ["res://scenes/actors/PlataformaLuz.tscn", "res://scenes/actors/Vela.tscn"],
	"veneno": ["res://scripts/zona_estado.gd"],
	"vento": ["res://scenes/actors/CorrenteAr.tscn"],
	"vitral": ["res://scenes/actors/Espinhos.tscn", "res://scenes/actors/Vitral.tscn"],
}


func _init() -> void:
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es == null:
		print("SEM EstadoJogo"); quit(1); return
	var falhas := 0
	var avisos := 0
	var sem_tabela: Array[String] = []
	for idx in es.NIVEIS.size():
		es.indice_nivel = idx
		es.checkpoint = Vector2.ZERO
		# sem habilidades: um `Coletavel` de habilidade que a pessoa JÁ tem
		# apaga-se a si próprio no `_ready`, e o nível 63 (a estreia é o
		# planar) dava "não nasceu" só porque o save desta máquina já tinha
		# a habilidade. A bancada tem de correr sempre do mesmo sítio.
		if es.habilidades is Array:
			es.habilidades.clear()
		if es.has_method("_limpar_jornada_ancora"):
			es._limpar_jornada_ancora()
		var cena: PackedScene = load(es.NIVEIS[idx])
		if cena == null:
			print("  [%2d] SEM CENA" % idx); falhas += 1; continue
		var raiz := cena.instantiate()
		root.add_child(raiz)
		for _i in 12:
			await process_frame
		var ger := _achar_gerador(raiz)
		var estreia: String = "" if ger == null else String(ger.get("_estreia_cam"))
		if estreia == "":
			print("  [%2d] %-26s  (sem jornada)" % [idx, raiz.name])
			raiz.queue_free(); await process_frame; continue
		if not ACTORES.has(estreia):
			sem_tabela.append(estreia)
			print("  [%2d] %-26s  estreia '%s' -- sem entrada na tabela" % [
				idx, raiz.name, estreia])
			raiz.queue_free(); await process_frame; continue

		var faltam: Array[String] = []
		var maus: Array[String] = []
		for guiao in ACTORES[estreia]:
			var achados: Array[Node] = []
			_colher(raiz, guiao, achados)
			if achados.is_empty():
				faltam.append(guiao.get_file())
				continue
			for n in achados:
				if n is Area2D and (n.collision_mask & 2) == 0:
					maus.append("%s sem layer 2 na mascara" % n.get_class())
					break
		var linha := "  [%2d] %-26s  estreia=%-14s actores=%d" % [
			idx, raiz.name, estreia, ACTORES[estreia].size()]
		if faltam.is_empty() and maus.is_empty():
			print(linha + "  OK")
		elif not faltam.is_empty():
			print(linha + "  <<< NAO NASCEU: " + ", ".join(faltam))
			falhas += 1
		else:
			print(linha + "  ~~~ " + ", ".join(maus))
			avisos += 1
		raiz.queue_free()
		await process_frame

	if not sem_tabela.is_empty():
		print("
camaras sem entrada na tabela: ", sem_tabela)
	print("
=== MECANICAS: %s, %d aviso(s) ===" % [
		"TUDO OK" if falhas == 0 else "%d FALHA(S)" % falhas, avisos])
	quit(1 if falhas else 0)


## Junta todos os nós que SÃO `guiao`. São duas coisas diferentes conforme
## o alvo: uma cena instanciada conhece-se pelo `scene_file_path`, um actor
## feito em código conhece-se pelo caminho do `get_script()`. Comparar só o
## script dava "não nasceu" em TODAS as cenas -- a Plataforma incluída.
func _colher(n: Node, guiao: String, fora: Array[Node]) -> void:
	if guiao.ends_with(".tscn"):
		if n.scene_file_path == guiao:
			fora.append(n)
	else:
		var sc: Variant = n.get_script()
		if sc != null and (sc as Resource).resource_path == guiao:
			fora.append(n)
	for f in n.get_children():
		_colher(f, guiao, fora)


func _achar_gerador(n: Node) -> Node:
	if n.name == "CorredorAproximacao":
		return n
	for f in n.get_children():
		var r := _achar_gerador(f)
		if r:
			return r
	return null
