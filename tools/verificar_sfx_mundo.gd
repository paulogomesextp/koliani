extends SceneTree
## SFX Overhaul Prompt 3B -- prova dirigida do MUNDO e da PROGRESSAO.
##
##   Godot_console.exe --path . --screen 1 --resolution 640x360 \
##       --script res://tools/verificar_sfx_mundo.gd
##
## Corre com renderer REAL: em `--headless` os autoloads compilam mas o
## `AudioStreamPlayer.playing` nunca fica verdadeiro, e metade destas
## asercoes deixava de morder sem dar erro (ver a nota de sessao sobre
## autoloads em `--script`).
##
## O que se conta e' o que o runtime FEZ, nao o que o codigo diz que faz:
##   * `_ordem` do `Som` sobe uma vez por voz atribuida -> conta one-shots;
##   * `_ultimo_stream()` diz que ficheiro entrou na ultima voz;
##   * `Som.lacos_ativos()` conta os canais ambientais mesmo a tocar.
##
## Cada bloco imprime uma linha com os numeros medidos. Se um bloco nao
## imprimir, rebentou antes -- e' de proposito que as linhas sao a prova.

var _falhas := 0
var _som: Node


func _init() -> void:
	await process_frame
	_som = root.get_node_or_null("Som")
	_checar(_som != null, "autoload Som ausente")
	if _som == null:
		quit(1)
		return
	_som.call("definir_semente_teste", 20260920)
	_catalogo()
	await _vento()
	await _sino()
	await _mecanismo_alavanca()
	await _mecanismo_portao()
	await _elevador()
	await _perigo_plataforma()
	await _perigo_pedra()
	await _perigo_pendulo()
	await _checkpoint()
	await _bau()
	await _pickup()
	await _desbloqueio()
	await _porta_fim()
	await _troca_de_cena()
	await _desempenho()
	print("SFX MUNDO FINAL falhas=%d" % _falhas)
	quit(0 if _falhas == 0 else 1)


## Os 16 streams novos tem de existir mesmo. Um caminho errado no `CAMINHOS`
## nao rebenta: o `toca()` devolve `false` em silencio e o evento fica mudo.
func _catalogo() -> void:
	var novos: Array[String] = [
		"vento_ciclo", "vento_rajada", "mecanismo", "mecanismo_ciclo",
		"portao_abre", "portao_fecha", "sino_mecanismo", "pedra_racha",
		"pedra_parte", "lamina_passa", "fogo_sopro", "raio_aviso",
		"raio_cai", "bau_abrir", "recompensa", "desbloqueio"]
	var ausentes: Array[String] = []
	for n in novos:
		if _som.call("_stream", n) == null:
			ausentes.append(n)
	_checar(ausentes.is_empty(), "streams 3B ausentes: %s" % str(ausentes))
	print("SFX MUNDO CATALOGO novos=%d ausentes=%d total=%d" % [
		novos.size(), ausentes.size(), _som.CAMINHOS.size()])


# ------------------------------------------------------------------- vento

func _vento() -> void:
	var cena := _cena()
	var zona = load("res://scripts/wind_zone.gd").new()
	zona.mostrar_guia = false
	cena.add_child(zona)
	var k := _koliani()
	await process_frame

	# ENTRADA: uma rajada, e o laco ambiental abre
	var antes := _contador()
	zona.call("_ao_entrar", k)
	_checar(_avanco(antes) == 1, "entrar na zona de vento nao deu uma rajada")
	_checar(_ultimo_stream() == "vento_rajada.wav",
		"rajada usa stream errado: " + _ultimo_stream())
	# `AudioStreamPlayer.playing` so' fica verdadeiro depois de o servidor de
	# audio correr; uma frame de arvore nao chega
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 1,
		"o ambiente de vento nao arrancou (lacos=%d)" % int(_som.call("lacos_ativos")))

	# FICAR DENTRO: zero vozes novas. E' o spam que a Fase 2 manda matar.
	antes = _contador()
	for _i in 30:
		await physics_frame
	_checar(_avanco(antes) == 0,
		"a zona de vento fez spam ao ficar la' dentro (%d vozes)" % _avanco(antes))

	# RE-ENTRAR dentro da recarga: continua a ser zero
	zona.call("_ao_entrar", k)
	_checar(_avanco(antes) == 0, "re-entrar dentro da recarga disparou rajada")

	# SAIR: o laco fecha
	zona.call("_ao_sair", k)
	await create_timer(1.0).timeout
	_checar(int(_som.call("lacos_ativos")) == 0,
		"o ambiente de vento ficou aberto depois de sair")

	# DUAS ZONAS, UM LACO: e' o teste que apanha o player empilhado
	var z2 = load("res://scripts/wind_zone.gd").new()
	z2.mostrar_guia = false
	cena.add_child(z2)
	await process_frame
	zona.call("_ao_entrar", k)
	z2.call("_ao_entrar", k)
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 1,
		"duas zonas de vento abriram dois lacos")
	print("SFX VENTO rajada=1 spam_dentro=0 lacos_2zonas=%d" % int(_som.call("lacos_ativos")))
	await _fechar(cena)
	_checar(int(_som.call("lacos_ativos")) == 0, "o laco do vento sobreviveu a' cena")


# -------------------------------------------------------------------- sino

func _sino() -> void:
	var cena := _cena()
	var sino = load("res://scripts/sino_torre.gd").new()
	cena.add_child(sino)
	await process_frame
	var antes := _contador()
	sino.call("receber_dano", 1)
	_checar(_avanco(antes) == 1, "a badalada nao deu exactamente uma voz")
	_checar(_ultimo_stream() == "sino_mecanismo.wav",
		"o sino da torre ainda usa o som do chefe: " + _ultimo_stream())
	_checar(_ultimo_stream() != "sino_ataque.ogg", "sino mecanico == sino de chefe")
	# a recarga do proprio sino bloqueia o segundo golpe
	sino.call("receber_dano", 1)
	_checar(_avanco(antes) == 1, "o sino disparou duas vezes no mesmo golpe")
	print("SFX SINO mecanico=%s vozes=%d (o chefe continua com sino_ataque.ogg)" % [
		_ultimo_stream(), _avanco(antes)])
	await _fechar(cena)


# -------------------------------------------------------------- mecanismos

func _mecanismo_alavanca() -> void:
	var cena := _cena()
	var alavanca = load("res://scripts/alavanca.gd").new()
	cena.add_child(alavanca)
	var k := _koliani()
	await process_frame
	var antes := _contador()
	alavanca.call("_ao_tocar", k)
	_checar(_avanco(antes) == 1, "a alavanca nao deu exactamente uma voz")
	_checar(_ultimo_stream() == "mecanismo.wav",
		"a alavanca ainda rouba o selo do checkpoint: " + _ultimo_stream())
	_checar(_ultimo_stream() != "selo.wav", "alavanca == checkpoint")
	print("SFX ALAVANCA stream=%s vozes=%d" % [_ultimo_stream(), _avanco(antes)])
	await _fechar(cena)


func _mecanismo_portao() -> void:
	var cena := _cena()
	var portao = load("res://scripts/porta_trancada.gd").new()
	cena.add_child(portao)
	await process_frame
	var antes := _contador()
	portao.call("_definir_aberta", true)
	_checar(_avanco(antes) == 1, "abrir o portao nao deu uma voz")
	_checar(_ultimo_stream() == "portao_abre.wav",
		"o portao a abrir usa stream errado: " + _ultimo_stream())
	portao.call("_definir_aberta", false)
	_checar(_avanco(antes) == 2, "fechar o portao nao deu uma voz")
	_checar(_ultimo_stream() == "portao_fecha.wav",
		"o portao a fechar usa stream errado: " + _ultimo_stream())
	# estado igual = nada. O `_reavaliar` corre a cada mudanca de alavanca.
	portao.call("_definir_aberta", false)
	_checar(_avanco(antes) == 2, "o portao soou sem mudar de estado")
	print("SFX PORTAO vozes=%d ultimo=%s (repetir estado nao soa)" % [
		_avanco(antes), _ultimo_stream()])
	await _fechar(cena)


func _elevador() -> void:
	var cena := _cena()
	var elevador = load("res://scenes/actors/TumuloElevador.tscn").instantiate()
	elevador.auto = true
	elevador.curso = Vector2(0.0, -400.0)
	cena.add_child(elevador)
	await process_frame
	for _i in 12:
		await physics_frame
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 1,
		"o elevador em marcha nao abriu o laco (lacos=%d)" % int(_som.call("lacos_ativos")))
	var antes := _contador()
	for _i in 40:
		await physics_frame
	_checar(_avanco(antes) <= 1,
		"o elevador em marcha fez spam de one-shots (%d)" % _avanco(antes))
	print("SFX ELEVADOR lacos=%d oneshots_em_marcha=%d" % [
		int(_som.call("lacos_ativos")), _avanco(antes)])
	await _fechar(cena)
	_checar(int(_som.call("lacos_ativos")) == 0,
		"o laco do elevador sobreviveu a' cena")


# ----------------------------------------------------------------- perigos

func _perigo_plataforma() -> void:
	var cena := _cena()
	var plat = load("res://scripts/plataforma_quebra.gd").new()
	plat.atraso = 0.12
	cena.add_child(plat)
	var k := _koliani()
	await process_frame
	var antes := _contador()
	plat.call("_ao_pisar", k)
	_checar(_avanco(antes) == 1, "pisar a plataforma nao deu o telegrafo")
	_checar(_ultimo_stream() == "pedra_racha.wav",
		"telegrafo da plataforma errado: " + _ultimo_stream())
	# pisar outra vez enquanto treme nao reabre o telegrafo
	plat.call("_ao_pisar", k)
	_checar(_avanco(antes) == 1, "a plataforma repetiu o telegrafo enquanto tremia")
	await create_timer(0.45).timeout
	_checar(_avanco(antes) == 2, "a plataforma caiu sem som")
	_checar(_ultimo_stream() == "pedra_parte.wav",
		"queda da plataforma com stream errado: " + _ultimo_stream())
	print("SFX PLATAFORMA telegrafo+queda=%d vozes ultimo=%s" % [
		_avanco(antes), _ultimo_stream()])
	await _fechar(cena)


func _perigo_pedra() -> void:
	var cena := _cena()
	var pedra = load("res://scripts/pedra_queda.gd").new()
	pedra.aviso = 0.10
	pedra.chao_y = 200.0
	pedra.automatico = false
	cena.add_child(pedra)
	# por baixo e ao alcance (`raio_gatilho` = 70 px), para ARMAR a pedra --
	# aqui a proximidade E' a mecanica, por isso ela tem de estar mesmo la'
	# ao LADO da linha de queda (x = 0): dentro do `raio_gatilho` para armar a
	# pedra, fora do alcance dela para nao levar dano -- a Koliani a ser
	# atingida acrescentava uma terceira voz (o `dano` dela) a um bloco que
	# so' quer contar os dois eventos do PERIGO
	_koliani_viva(cena, Vector2(55, 100))
	# o snapshot vem ANTES de deixar correr fisica: com `aviso = 0,10 s` a
	# pedra arma-se e larga em seis frames, e um `await process_frame` pelo
	# meio ja' comia o telegrafo
	var antes := _contador()
	for _i in 10:
		await physics_frame
	_checar(_avanco(antes) == 1, "a pedra armou-se sem telegrafo (%d vozes)" % _avanco(antes))
	_checar(_ultimo_stream() == "pedra_racha.wav",
		"telegrafo da pedra errado: " + _ultimo_stream())
	for _i in 60:
		await physics_frame
	_checar(_avanco(antes) == 2, "a pedra caiu sem impacto (%d vozes)" % _avanco(antes))
	_checar(_ultimo_stream() == "pedra_parte.wav",
		"impacto da pedra errado: " + _ultimo_stream())
	print("SFX PEDRA aviso+impacto=%d vozes ultimo=%s" % [
		_avanco(antes), _ultimo_stream()])
	await _fechar(cena)


func _perigo_pendulo() -> void:
	var cena := _cena()
	var pend = load("res://scripts/pendulo_lamina.gd").new()
	pend.periodo = 1.0
	cena.add_child(pend)
	await process_frame
	var antes := _contador()
	# um periodo inteiro = duas passagens pelo fundo do arco
	for _i in 70:
		await physics_frame
	var n := _avanco(antes)
	_checar(n >= 1, "o pendulo continua mudo")
	_checar(n <= 3, "o pendulo fez spam: %d vozes num periodo" % n)
	_checar(_ultimo_stream() == "lamina_passa.wav",
		"sopro do pendulo com stream errado: " + _ultimo_stream())
	print("SFX PENDULO vozes_por_periodo=%d stream=%s" % [n, _ultimo_stream()])
	await _fechar(cena)


# ------------------------------------------------------------- progressao

## Fase 6: o checkpoint foi validado no Prompt 1 e NAO muda. Isto e' a
## regressao que prova que nada deste lote lhe mexeu.
func _checkpoint() -> void:
	root.get_node("EstadoJogo").call("reiniciar_campanha")
	var cena := _cena()
	var k := _koliani()
	var checkpoint = load("res://scripts/checkpoint.gd").new()
	checkpoint.checkpoint_id = "checkpoint_level_001_01"
	cena.add_child(checkpoint)
	await process_frame
	var antes := _contador()
	checkpoint.call("_ao_entrar", k)
	_checar(_avanco(antes) == 1, "o checkpoint deixou de disparar uma so' voz")
	_checar(_ultimo_stream() == "selo.wav", "o checkpoint perdeu o selo")
	checkpoint.call("_ao_entrar", k)
	_checar(_avanco(antes) == 1, "o checkpoint disparou duas vezes")
	print("SFX CHECKPOINT (Prompt 1) stream=%s vozes=%d repetido=0" % [
		_ultimo_stream(), _avanco(antes)])
	await _fechar(cena)


func _bau() -> void:
	root.get_node("EstadoJogo").call("reiniciar_campanha")
	var cena := _cena()
	var bau := Node2D.new()
	bau.set_script(load("res://scripts/bau_chefe.gd"))
	bau.reward_id = "reward_teste_3b"
	cena.add_child(bau)
	await process_frame
	var antes := _contador()
	bau.call("_abrir")
	_checar(_avanco(antes) == 1, "o bau nao deu o som de ABRIR")
	_checar(_ultimo_stream() == "bau_abrir.wav",
		"o bau ainda depende do pickup generico: " + _ultimo_stream())
	_checar(_ultimo_stream() != "apanhar.wav", "bau == essencia do chao")
	await create_timer(0.55).timeout
	_checar(_avanco(antes) == 2, "o premio do bau nao chegou a soar")
	_checar(_ultimo_stream() == "recompensa.wav",
		"o premio do bau usa stream errado: " + _ultimo_stream())
	print("SFX BAU vozes=%d ultimo=%s atraso=0.36s" % [
		_avanco(antes), _ultimo_stream()])
	await _fechar(cena)


func _pickup() -> void:
	var cena := _cena()
	var ess = load("res://scenes/actors/Essencia.tscn").instantiate()
	cena.add_child(ess)
	await process_frame
	var antes := _contador()
	ess.call("_apanhar")
	_checar(_avanco(antes) == 1, "a essencia nao soou")
	_checar(_ultimo_stream() == "apanhar.wav",
		"a essencia deixou de usar o pickup comum: " + _ultimo_stream())
	print("SFX PICKUP comum=apanhar.wav (bau e desbloqueio tem os seus)")
	await _fechar(cena)


func _desbloqueio() -> void:
	root.get_node("EstadoJogo").call("reiniciar_campanha")
	var cena := _cena()
	var col = load("res://scenes/actors/Coletavel.tscn").instantiate()
	# id proprio do teste: com uma habilidade que a campanha ja' da' de
	# inicio, o `Coletavel._ready` chama `_ja_obtido()` e faz `queue_free()`
	# antes de o harness lhe tocar
	col.habilidade_id = "habilidade_teste_3b"
	cena.add_child(col)
	var k := _koliani()
	await process_frame
	var antes := _contador()
	col.call("_ao_entrar", k)
	_checar(_avanco(antes) == 1, "ganhar a habilidade nao deu exactamente uma voz")
	_checar(_ultimo_stream() == "desbloqueio.wav",
		"o desbloqueio usa stream errado: " + _ultimo_stream())
	# Fase 9: nunca a morte nem a vitoria do chefe
	_checar(_ultimo_stream() != "chefe_cai.wav", "unlock == morte do chefe")
	_checar(_ultimo_stream() != "conquista.wav", "unlock == vitoria sobre o chefe")
	print("SFX UNLOCK stream=%s (nao e' chefe_cai nem conquista)" % _ultimo_stream())
	await _fechar(cena)


## Fase 10/11. A porta de fim de nivel muda mesmo de cena, por isso nao se
## chama `_concluir()`: mede-se o VOLUME da voz, que e' o que a fase pede
## (a porta era o som mais alto da cadeia de fim de nivel).
func _porta_fim() -> void:
	var antes := _contador()
	_som.call("toca", "transicao", -7.0)
	_checar(_avanco(antes) == 1, "a transicao nao tocou")
	var db := _ultimo_volume()
	_checar(db <= -6.5, "a porta de fim de nivel voltou a ficar alta (%.1f dB)" % db)
	# o portal do Prompt 1 continua mais baixo do que a porta
	antes = _contador()
	_som.call("toca", "transicao", -10.0, 1.08)
	_checar(_ultimo_volume() < db, "o portal deixou de ser mais baixo do que a porta")
	print("SFX PROGRESSAO porta=%.1f dB portal=%.1f dB (conquista -6 no topo)" % [
		db, _ultimo_volume()])


## Fase 13. O laco e' do AUTOLOAD: nada na cena o liberta. Este e' o teste
## que apanharia o vento do N08 a tocar por cima do menu.
func _troca_de_cena() -> void:
	var cena := _cena()
	var zona = load("res://scripts/wind_zone.gd").new()
	zona.mostrar_guia = false
	cena.add_child(zona)
	var k := _koliani()
	await process_frame
	zona.call("_ao_entrar", k)
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 1, "o laco nao arrancou para o teste de cena")
	# troca de cena a serio, sem ninguem chamar `parar_laco`
	var outra := Node2D.new()
	root.add_child(outra)
	current_scene = outra
	await _assentar()
	_checar(int(_som.call("lacos_ativos")) == 0,
		"UM LACO SOBREVIVEU A' TROCA DE CENA (lacos=%d)" % int(_som.call("lacos_ativos")))
	print("SFX CENA lacos_apos_troca=%d" % int(_som.call("lacos_ativos")))
	cena.queue_free()
	outra.queue_free()
	current_scene = null
	await process_frame


## Fase 15. O projecto e' de telemovel e este lote acrescentou o PRIMEIRO
## audio continuo do jogo. Duas coisas a provar:
##
##   1. o pool continua com 8 vozes -- os lacos sao players a` parte e nao
##      aumentam o pool (o briefing proibe aumenta-lo sem prova);
##   2. `LACOS_MAX` e' um TECTO DURO. Um nivel com muitas zonas ambientais
##      nao pode abrir um player por zona: pedir o 4.o laco tem de devolver
##      `false` e ficar calado, nao arranjar espaco.
func _desempenho() -> void:
	_checar(int(_som.VOZES) == 8, "o pool deixou de ter 8 vozes (%d)" % int(_som.VOZES))
	var tecto := int(_som.LACOS_MAX)
	var abertos := 0
	for nome: String in ["vento_ciclo", "mecanismo_ciclo", "ambiente_floresta",
			"raio_cai", "fogo_sopro"]:
		if bool(_som.call("laco", nome, -40.0, 0.0)):
			abertos += 1
	await _assentar()
	_checar(abertos <= tecto,
		"o tecto de lacos nao segurou: %d abertos para LACOS_MAX=%d" % [abertos, tecto])
	var vivos := int(_som.call("lacos_ativos"))
	_checar(vivos <= tecto, "lacos vivos acima do tecto (%d > %d)" % [vivos, tecto])
	_som.call("parar_lacos", 0.0)
	await process_frame
	_checar(int(_som.call("lacos_ativos")) == 0, "parar_lacos deixou lacos vivos")
	print("SFX DESEMPENHO pool=%d lacos_max=%d pedidos=5 aceites=%d vivos=%d apos_parar=%d" % [
		int(_som.VOZES), tecto, abertos, vivos, int(_som.call("lacos_ativos"))])


# ---------------------------------------------------------------- utilidades

## Deixa o servidor de audio correr. Sem isto, `AudioStreamPlayer.playing`
## ainda e' `false` no frame em que se chamou `play()`.
func _assentar() -> void:
	for _i in 4:
		await process_frame
	await create_timer(0.05).timeout


func _cena() -> Node2D:
	var c := Node2D.new()
	root.add_child(c)
	current_scene = c
	return c


func _fechar(cena: Node) -> void:
	cena.queue_free()
	current_scene = null
	await process_frame
	await process_frame


## A Koliani entra CONGELADA. Viva, ela cai no vazio e toca `salto`/`aterrar`
## sozinha -- e como o harness conta vozes do pool, esses one-shots dela
## entravam na conta dos eventos do cenario (a 1.a volta deste ficheiro
## media "pedra_racha" mas via `salto.wav` na ultima voz). Congelada, a
## posicao tambem fica deterministica, que e' o que os gatilhos de
## proximidade da `PedraQueda` precisam.
## Uma Koliani FORA DA ARVORE, so' para servir de argumento.
##
## Foi a armadilha que custou mais nesta bancada. As zonas, as placas de
## deteccao e os baus ficam todos na origem, e uma Koliani viva em cena
## dispara o `body_entered` DE VERDADE no primeiro frame de fisica. O
## harness chamava depois `_ao_entrar(k)` a mao, ja' dentro da recarga, e
## media zero vozes -- lia-se como "o callsite esta' mudo" quando na verdade
## tinha tocado uma frame antes. Afasta-la (4000, 4000) nao chegou: o
## `body_entered` sai na mesma no frame em que ela e' adicionada.
##
## Sem `add_child` nao ha' fisica nenhuma, e `corpo is Koliani` /
## `has_method("atualizar_vento")` continuam a responder na mesma. Os blocos
## em que a PROXIMIDADE e' a mecanica (`PedraQueda`) usam `_koliani_viva`.
func _koliani() -> Node:
	return load("res://scenes/actors/Koliani.tscn").instantiate()


## A Koliani a serio, em cena, congelada no sitio. Congelada porque viva ela
## cai no vazio e toca `salto`/`aterrar` sozinha -- e o harness conta vozes
## do pool, por isso esses one-shots dela entravam na conta dos eventos do
## cenario (a 1.a volta deste ficheiro media "pedra_racha" e via "salto.wav"
## na ultima voz).
func _koliani_viva(cena: Node, em: Vector2) -> Node:
	var k = load("res://scenes/actors/Koliani.tscn").instantiate()
	cena.add_child(k)
	k.global_position = em
	k.set_physics_process(false)
	k.set_process(false)
	return k


func _avanco(antes: int) -> int:
	return _contador() - antes


func _contador() -> int:
	return int(_som.get("_ordem"))


func _voz_anterior() -> AudioStreamPlayer:
	var i := posmod(int(_som.get("_idx")) - 1, int(_som.VOZES))
	var pool: Array = _som.get("_pool")
	return pool[i] as AudioStreamPlayer


func _ultimo_stream() -> String:
	var p := _voz_anterior()
	return p.stream.resource_path.get_file() if p and p.stream else ""


func _ultimo_volume() -> float:
	var p := _voz_anterior()
	return p.volume_db if p else 0.0


func _checar(ok: bool, mensagem: String) -> void:
	if not ok:
		_falhas += 1
		push_error("SFX MUNDO: " + mensagem)
