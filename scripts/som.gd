extends Node
## Autoload "Som": toca efeitos sonoros por nome, com um pool de vozes
## para sons sobrepostos. O catalogo mistura samples CC0 creditados e sintese
## original (Koliani: `tools/gerar_sfx_koliani_signature.py`); ver CREDITS.md.
##
## Carrega os streams à primeira utilização (não `preload`) para o script
## compilar mesmo antes de o Godot importar os ficheiros (fresh checkout / CI).

const CAMINHOS := {
	"salto": "res://assets/audio/salto.wav",
	"koliani_salto": "res://assets/audio/koliani_signature/koliani_jump.wav",
	"salto_duplo": "res://assets/audio/koliani_signature/koliani_jump.wav",
	# Prompt 5: quatro vozes originais da mesma familia Shadowblade.
	"ataque": "res://assets/audio/koliani_signature/shadowblade_swing_1.wav",
	"ataque2": "res://assets/audio/koliani_signature/shadowblade_swing_2.wav",
	"ataque3": "res://assets/audio/koliani_signature/shadowblade_swing_3.wav",
	"lancar": "res://assets/audio/koliani_signature/shadowblade_energy_cast.wav",
	"energia_impacto": "res://assets/audio/koliani_signature/koliani_energy_hit.wav",
	"acerto": "res://assets/audio/koliani_signature/shadowblade_hit.wav",
	"acerto_critico": "res://assets/audio/koliani_signature/shadowblade_critical.wav",
	"pisao_koliani": "res://assets/audio/koliani_signature/koliani_stomp.wav",
	"dano": "res://assets/audio/koliani_signature/koliani_hurt.wav",
	"dano_pesado": "res://assets/audio/koliani_signature/koliani_hurt_heavy.wav",
	"aterrar": "res://assets/audio/koliani_signature/koliani_land_soft.wav",
	"aterrar_medio": "res://assets/audio/koliani_signature/koliani_land_medium.wav",
	"aterrar_pesado": "res://assets/audio/koliani_signature/koliani_land_hard.wav",
	"apanhar": "res://assets/audio/approved/sfx/pickup_normal.mp3",
	"apanhar_raro": "res://assets/audio/approved/sfx/pickup_rare.mp3",
	"curar": "res://assets/audio/approved/sfx/heal_magic.mp3",
	"guardar": "res://assets/audio/approved/sfx/save_success.mp3",
	"respawn": "res://assets/audio/approved/sfx/respawn.mp3",
	"menu_painel": "res://assets/audio/approved/sfx/menu_panel.mp3",
	"portal": "res://assets/audio/approved/sfx/portal_jump.mp3",
	"porta": "res://assets/audio/porta.wav",
	"chefe_cai": "res://assets/audio/chefe_cai.wav",
	"selo": "res://assets/audio/approved/sfx/checkpoint_sword_cut.mp3",
	"projetil": "res://assets/audio/projetil.wav",
	"investida": "res://assets/audio/investida.wav",
	"onda": "res://assets/audio/onda.ogg",
	"bloqueio": "res://assets/audio/bloqueio.wav",
	# 9H.16 E4 -- as mecanicas-assinatura da Regiao I estavam MUDAS
	# (`tools/gerar_sfx_9h16.py`).
	"raiz_irrompe": "res://assets/audio/raiz_irrompe.wav",
	"raiz_aviso": "res://assets/audio/raiz_aviso.wav",
	"plataforma_surge": "res://assets/audio/plataforma_surge.wav",
	"demonio_ataque": "res://assets/audio/demonio_ataque.ogg",
	"conquista": "res://assets/audio/conquista.wav",
	# Execution 9H.18: VARIACOES dos sons que mais se repetem. Nao entram no
	# codigo do jogo -- o `toca()` sorteia-as sozinho pelo nome base.
	"ui_mover_v2": "res://assets/audio/ui_mover_v2.wav",
	"ui_mover_v3": "res://assets/audio/ui_mover_v3.wav",
	"acerto_v2": "res://assets/audio/koliani_signature/shadowblade_hit_v2.wav",
	"acerto_v3": "res://assets/audio/koliani_signature/shadowblade_hit_v3.wav",
	"transicao": "res://assets/audio/approved/sfx/level_complete_soft_landing.mp3",
	"carrossel": "res://assets/audio/carrossel.wav",
	# --- vozes de interface (Execution 9H) --------------------------------
	# O frontend novo pedia um som próprio: o `carrossel` era um clique seco
	# de interface e destoava do menu de fantasia escura. Sintetizados por
	# `tools/gerar_audio_9h.py` (sino + sopro, sem licenças).
	"ui_mover": "res://assets/audio/approved/sfx/ui_hover.mp3",
	"ui_confirmar": "res://assets/audio/approved/sfx/ui_confirm.mp3",
	"ui_voltar": "res://assets/audio/approved/sfx/ui_back.mp3",
	"ui_negado": "res://assets/audio/approved/sfx/ui_error.mp3",
	"chefe_magia": "res://assets/audio/chefe_magia.ogg",
	# sons de habilidade por chefe (2 set 2026)
	"esmagar": "res://assets/audio/esmagar.ogg",
	"golpe_pesado": "res://assets/audio/golpe_pesado.ogg",
	"garra": "res://assets/audio/garra.ogg",
	"chama": "res://assets/audio/chama.ogg",
	"gelo": "res://assets/audio/gelo.wav",
	"praga": "res://assets/audio/praga.ogg",
	"raio": "res://assets/audio/raio.wav",
	"invocar": "res://assets/audio/invocar.wav",
	"grito": "res://assets/audio/grito.ogg",
	"sino_ataque": "res://assets/audio/sino_ataque.ogg",
	"engrenagem": "res://assets/audio/engrenagem.ogg",
	"lamina_cair": "res://assets/audio/lamina_cair.ogg",
	"feixe_vil": "res://assets/audio/feixe_vil.ogg",
	"meteoro": "res://assets/audio/meteoro.wav",
	"mudar_forma": "res://assets/audio/mudar_forma.wav",
	"olho_carregar": "res://assets/audio/olho_carregar.wav",
	# --- Koliani Signature (Prompt 5) --------------------------------------
	# Sintese original, reconstruivel por `gerar_sfx_koliani_signature.py`.
	"passo1": "res://assets/audio/koliani_signature/koliani_step_1.wav",
	"passo2": "res://assets/audio/koliani_signature/koliani_step_2.wav",
	"passo3": "res://assets/audio/koliani_signature/koliani_step_3.wav",
	"rolamento": "res://assets/audio/koliani_signature/koliani_roll.wav",
	"dash": "res://assets/audio/approved/koliani_dash_wind_magic_5.wav",
	"parede": "res://assets/audio/koliani_signature/koliani_wall.wav",
	"agarrar": "res://assets/audio/koliani_signature/koliani_grab.wav",
	"morte_koliani": "res://assets/audio/koliani_signature/koliani_death.wav",
	"ataque_forte": "res://assets/audio/koliani_signature/shadowblade_finisher.wav",
	"escudo_ativar": "res://assets/audio/koliani_signature/shadow_shield_on.wav",
	"escudo_impacto": "res://assets/audio/koliani_signature/shadow_shield_hit.wav",
	# --- monstros, por ARQUETIPO ------------------------------------------
	# "Faca com que os mobs facam sons apropriados ao tipo de monstro."
	# As 19 especies mapeiam-se em sete familias -- ver `demonio_base.gd`.
	"mob_humano_ataque": "res://assets/audio/mob_humano_ataque.ogg",
	"mob_humano_dano": "res://assets/audio/mob_humano_dano.ogg",
	"mob_humano_morte": "res://assets/audio/mob_humano_morte.ogg",
	"mob_morto_ataque": "res://assets/audio/mob_morto_ataque.ogg",
	"mob_morto_dano": "res://assets/audio/mob_morto_dano.ogg",
	"mob_morto_morte": "res://assets/audio/mob_morto_morte.ogg",
	"mob_gosma_ataque": "res://assets/audio/mob_gosma_ataque.ogg",
	"mob_gosma_dano": "res://assets/audio/mob_gosma_dano.ogg",
	"mob_gosma_morte": "res://assets/audio/mob_gosma_morte.ogg",
	"mob_besta_ataque": "res://assets/audio/mob_besta_ataque.ogg",
	"mob_besta_dano": "res://assets/audio/mob_besta_dano.ogg",
	"mob_besta_morte": "res://assets/audio/mob_besta_morte.ogg",
	"mob_insecto_ataque": "res://assets/audio/mob_insecto_ataque.ogg",
	"mob_insecto_dano": "res://assets/audio/mob_insecto_dano.ogg",
	"mob_insecto_morte": "res://assets/audio/mob_insecto_morte.ogg",
	"mob_voador_ataque": "res://assets/audio/mob_voador_ataque.ogg",
	"mob_voador_dano": "res://assets/audio/mob_voador_dano.ogg",
	"mob_voador_morte": "res://assets/audio/mob_voador_morte.ogg",
	"mob_grande_ataque": "res://assets/audio/mob_grande_ataque.ogg",
	"mob_grande_dano": "res://assets/audio/mob_grande_dano.ogg",
	"mob_grande_morte": "res://assets/audio/mob_grande_morte.ogg",
	# --- mundo e progressao (SFX Overhaul Prompt 3B) ----------------------
	# Vinte e oito scripts de cenario nao tinham som NENHUM, e os poucos que
	# tinham pediam-no emprestado ao checkpoint (`selo`) ou aos chefes
	# (`onda`, `sino_ataque`). Ver `tools/gerar_sfx_3b.py` e
	# `docs/audio/world_progression_sfx_audit.md`.
	"vento_ciclo": "res://assets/audio/vento_ciclo.wav",
	"vento_rajada": "res://assets/audio/vento_rajada.wav",
	"mecanismo": "res://assets/audio/mecanismo.wav",
	"mecanismo_ciclo": "res://assets/audio/mecanismo_ciclo.wav",
	"portao_abre": "res://assets/audio/approved/sfx/unlock_door.mp3",
	"portao_fecha": "res://assets/audio/portao_fecha.wav",
	"sino_mecanismo": "res://assets/audio/sino_mecanismo.wav",
	"pedra_racha": "res://assets/audio/pedra_racha.wav",
	"pedra_parte": "res://assets/audio/pedra_parte.wav",
	"lamina_passa": "res://assets/audio/lamina_passa.wav",
	"fogo_sopro": "res://assets/audio/fogo_sopro.wav",
	"raio_aviso": "res://assets/audio/raio_aviso.wav",
	"raio_cai": "res://assets/audio/raio_cai.wav",
	"bau_abrir": "res://assets/audio/approved/sfx/chest_coin_drop.mp3",
	"recompensa": "res://assets/audio/recompensa.wav",
	"desbloqueio": "res://assets/audio/approved/sfx/ability_unlock_stinger.mp3",
}
const VOZES := 8
enum Prioridade { NORMAL, MEDIA, ALTA }

var _pool: Array[AudioStreamPlayer] = []
var _idx := 0
var _cache := {}
var _prioridades: Array[int] = []
var _ordem_vozes: Array[int] = []
var _ordem := 0
var _cooldowns := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for i in VOZES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"  # bus criado pelo autoload Opcoes
		add_child(p)
		_pool.append(p)
		_prioridades.append(Prioridade.NORMAL)
		_ordem_vozes.append(0)
	aquecer_tudo()


## Manda vir TODOS os sons do catálogo, em segundo plano, uma vez por sessão.
##
## Isto não é optimização preventiva: é a correcção de um congelamento real.
## O `_stream` carregava cada som à PRIMEIRA utilização, na thread principal.
## O Paulo: "no nível 1 fica no spawn e salta várias vezes, ao fim de alguns
## saltos congela; andar para os lados dá mais freezes". Era isso mesmo --
## cada aterragem toca um `passo1/2/3.ogg`, e a primeira vez que cada um
## tocava custava ~1,9 s de jogo parado (medido com `--verbose` a mostrar o
## `Loading resource:` em cima do buraco de frame).
##
## Uma lista curada não chega: qualquer som que escape volta a congelar na
## primeira vez que toca. São 66 ficheiros, ~48 MB no total -- ao lado dos
## ~78 MB que o jogo já usa, não é nada, e passa a estar tudo pronto antes de
## alguém carregar num botão.
func aquecer_tudo() -> void:
	aquecer(CAMINHOS.keys())


func _stream(nome: String) -> AudioStream:
	if not _cache.has(nome):
		var c: String = CAMINHOS.get(nome, "")
		_cache[nome] = load(c) if c != "" and ResourceLoader.exists(c) else null
	return _cache[nome]


## Manda carregar estes sons em SEGUNDO PLANO, para o `load()` do `_stream`
## não acontecer a meio do jogo.
##
## O `_stream` carregava à primeira utilização, ou seja **no instante do
## primeiro golpe**. Medido em `tools/bench_combate.gd` (Execution 8.1C):
## era isso, e sobretudo o `Musica.boss()`, que dava o congelamento que o
## Paulo via ao bater no chefe -- um frame de 2 segundos. Depois de aquecido,
## o `load()` sai da cache do `ResourceLoader` e não custa nada.
func aquecer(nomes: Array) -> void:
	for n in nomes:
		if _cache.has(n):
			continue
		var c: String = CAMINHOS.get(str(n), "")
		if c != "" and ResourceLoader.exists(c):
			ResourceLoader.load_threaded_request(c)


## Sons com variacoes `_v2`/`_v3` no catalogo. O `toca()` sorteia entre as
## tres sem que quem chama saiba -- os sitios que tocam `ui_mover` e `acerto`
## sao dezenas e nenhum precisa de mudar.
##
## Porque e' preciso: a navegacao do menu e o acerto da espada sao os dois
## sons mais repetidos do jogo. Um `pitch_scale` aleatorio de +-5% nao chega
## para esconder que e' a MESMA forma de onda a disparar vinte vezes -- e a
## repeticao e' metade do que se ouve como "som barato". Sao tres amostras
## mesmo diferentes (madeiras/frequencias diferentes), nao a mesma com outro
## tom; as variacoes ficam perto o suficiente para a identidade nao mudar.
const VARIANTES := {"acerto": 3}
var _ultima_variante := {}


## Escolhe uma variacao, evitando repetir a anterior de seguida -- e' a
## repeticao imediata que se ouve, nao a distribuicao ao longo do tempo.
func _sortear_variante(nome: String) -> String:
	var n: int = VARIANTES.get(nome, 0)
	if n < 2:
		return nome
	var anterior: int = _ultima_variante.get(nome, -1)
	var i := _rng.randi_range(0, n - 1)
	if i == anterior:
		i = (i + 1 + _rng.randi_range(0, n - 2)) % n
	_ultima_variante[nome] = i
	return nome if i == 0 else "%s_v%d" % [nome, i + 1]


## Ganho de COMPENSACAO por stream, em dB. Nao e' mistura artistica: e' a
## correccao de ficheiros que foram masterizados muito abaixo do resto do
## catalogo e que por isso chegavam ao jogo praticamente inaudiveis, por
## mais que o callsite pedisse -6 dB.
##
## Medido com `ffmpeg -af ebur128/volumedetect` (Prompt 3A). O grosso dos
## ataques do jogo vive entre -13 e -17 LUFS integrados; estes tres estavam
## 15 a 22 dB abaixo disso:
##
##   chama         pico -24,3 dBFS   -35,4 LUFS   (sopro de fogo do Arauto)
##   feixe_vil     pico -15,1 dBFS   -32,1 LUFS   (feixe do Olho / do Zeriko)
##   chefe_magia   pico -14,6 dBFS   -31,1 LUFS   (magia de cinco chefes)
##
## O ganho abaixo poe cada um a ~-17/-18 LUFS, deixando pelo menos 1 dB de
## margem de pico. Fazer isto aqui e nao nos dez callsites e' de proposito:
## a compensacao e' uma propriedade do FICHEIRO, nao do sitio que o toca --
## corrigi-la callsite a callsite garantia que o proximo uso voltava a
## nascer surdo. Os tres sao exclusivos dos chefes.
##
## Isto NAO substitui normalizar os ficheiros de origem; e' o que se pode
## fazer sem mexer nos assets. HUMAN LISTEN REQUIRED.
const COMPENSACAO := {
	"chama": 18.0,
	"feixe_vil": 14.0,
	"chefe_magia": 13.0,
}


## Reproduz um SFX. `variacao_pitch` e' a UNICA variacao aplicada aqui; quem
## chama passa sempre o pitch BASE. `cooldown` usa uma chave semantica, que
## pode incluir o instance id para nao silenciar inimigos diferentes.
##
## A prioridade nao aumenta o pool: escolhe uma voz livre; se todas estiverem
## ocupadas, so' substitui a voz mais antiga de prioridade igual/inferior.
## Assim passos/projeteis nao cortam morte de player/boss.
func toca(nome: String, volume_db := -6.0, pitch := 1.0,
		variacao_pitch := 0.05, cooldown := 0.0, chave_cooldown := "",
		prioridade := Prioridade.NORMAL) -> bool:
	var agora := Time.get_ticks_msec() * 0.001
	var chave := chave_cooldown if chave_cooldown != "" else nome
	if cooldown > 0.0 and agora < float(_cooldowns.get(chave, 0.0)):
		return false
	nome = _sortear_variante(nome)
	var st := _stream(nome)
	if st == null:
		return false
	var i := _escolher_voz(prioridade)
	if i < 0:
		return false
	var p := _pool[i]
	_idx = (i + 1) % VOZES
	p.stream = st
	p.volume_db = volume_db + float(COMPENSACAO.get(nome, 0.0))
	p.pitch_scale = pitch * (1.0 + _rng.randf_range(-variacao_pitch, variacao_pitch))
	_prioridades[i] = prioridade
	_ordem += 1
	_ordem_vozes[i] = _ordem
	if cooldown > 0.0:
		_cooldowns[chave] = agora + cooldown
	p.play()
	if OS.get_cmdline_user_args().has("--audio-qa"):
		print("[AUDIO_QA] event=%s stream=%s" % [nome, p.stream.resource_path])
	return true


func _escolher_voz(prioridade: int) -> int:
	for passo in VOZES:
		var i := (_idx + passo) % VOZES
		if not _pool[i].playing:
			return i
	var melhor := -1
	for i in VOZES:
		if _prioridades[i] > prioridade:
			continue
		if melhor < 0 or _prioridades[i] < _prioridades[melhor] \
				or (_prioridades[i] == _prioridades[melhor]
				and _ordem_vozes[i] < _ordem_vozes[melhor]):
			melhor = i
	return melhor


## Harnesses podem fixar a sequencia sem contaminar o RNG de gameplay.
func definir_semente_teste(semente: int) -> void:
	_rng.seed = semente
	_ultima_variante.clear()
	_cooldowns.clear()


# ======================================================================
# LACOS AMBIENTAIS (SFX Overhaul Prompt 3B)
# ======================================================================
#
# O pool de 8 vozes e' de ONE-SHOTS: escolhe a voz mais antiga quando fica
# sem vozes livres. Um laco de vento posto la' dentro seria cortado pelo
# terceiro passo da Koliani -- e, pior, ao ser cortado por um `p.play()` de
# outro som ficaria a ocupar uma voz para sempre em muitos casos.
#
# Por isso os lacos tem canal PROPRIO, fora do pool. Nao e' aumentar o pool:
# sao dois players a mais, no mesmo bus "SFX", e o pool continua com 8 vozes
# exactamente como estava.
#
# O que este canal garante (e que o harness `verificar_sfx_mundo.gd` prova):
#
#   * pedir o mesmo laco duas vezes NAO cria um segundo player -- so' repoe
#     o volume. Era o vazamento obvio: uma `WindZone` com a Koliani a entrar
#     e a sair empilhava um player por entrada;
#   * `LACOS_MAX` e' um tecto duro. Havendo mais zonas ambientais do que
#     canais, as que sobram ficam caladas em vez de comerem CPU de telemovel;
#   * TROCAR DE CENA mata todos os lacos. Um laco e' do autoload, nao da
#     cena, por isso nada morre com o `queue_free()` do nivel -- sem este
#     guarda, o vento do N08 seguia para o menu.
const LACOS_MAX := 3

var _lacos := {}            # nome -> AudioStreamPlayer
## ID da cena que estava de pe' quando os lacos abriram. Guarda-se o
## `instance_id` e NAO a referencia: um `Object` ja' libertado compara IGUAL a
## `null` em GDScript, e com a referencia o guarda de troca de cena nao
## disparava justamente no caso que interessa (ver `_process`).
var _cena_dos_lacos := 0
var _lacos_actores := {} # chave -> {"nome": String, "actor_id": int}
const FADE_ACTOR_FORA_ECRA := 0.08


## Poe `nome` a tocar em ciclo, ou so' reajusta o volume se ja' estiver.
## Devolve `true` se o laco esta' a tocar depois da chamada.
func laco(nome: String, volume_db := -24.0, fade := 0.6) -> bool:
	var p := _lacos.get(nome) as AudioStreamPlayer
	if p != null and is_instance_valid(p):
		_alvo_volume(p, volume_db, fade)
		return true
	if _lacos.size() >= LACOS_MAX:
		return false
	var st := _stream(nome)
	if st == null:
		return false
	_marcar_ciclico(st)
	p = AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = st
	p.volume_db = volume_db if fade <= 0.0 else volume_db - 24.0
	add_child(p)
	p.play()
	_lacos[nome] = p
	_cena_dos_lacos = _id_da_cena()
	if fade > 0.0:
		_alvo_volume(p, volume_db, fade)
	return true


## Desliga um laco. Com `fade > 0` desvanece e so' depois liberta o player --
## a entrada no dicionario sai JA', para um `laco()` no meio do fade abrir um
## player novo em vez de reanimar um que esta' a morrer.
func parar_laco(nome: String, fade := 0.5) -> void:
	var p := _lacos.get(nome) as AudioStreamPlayer
	_lacos.erase(nome)
	if p == null or not is_instance_valid(p):
		return
	if fade <= 0.0:
		p.stop()
		p.queue_free()
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", p.volume_db - 30.0, fade)
	tw.tween_callback(func() -> void:
		if is_instance_valid(p):
			p.stop()
			p.queue_free())


func parar_lacos(fade := 0.0) -> void:
	for nome: String in _lacos.keys():
		parar_laco(nome, fade)
	_lacos_actores.clear()


## Reproduz um one-shot emitido por um actor do mundo apenas quando a origem
## está dentro do rectângulo actualmente visível pela Camera2D.
##
## A API normal `toca()` mantém-se deliberadamente sem esta regra para música,
## UI e Koliani. Mobs/actors devem usar esta entrada central.
func toca_actor(actor: Node2D, nome: String, volume_db := -6.0, pitch := 1.0,
		variacao_pitch := 0.05, cooldown := 0.0, chave_cooldown := "",
		prioridade := Prioridade.NORMAL) -> bool:
	var visivel := actor != null and actor_visivel(actor)
	# A música/SFX de boss mantém o comportamento histórico da arena. Os
	# inimigos comuns, incluindo os que herdam DemonioBase, usam a barreira.
	if actor != null and actor.is_in_group("chefes"):
		return toca(nome, volume_db, pitch, variacao_pitch, cooldown,
			chave_cooldown, prioridade)
	if not visivel:
		return false
	return toca(nome, volume_db, pitch, variacao_pitch, cooldown,
		chave_cooldown, prioridade)


## Loop de um actor do mundo. Se a origem sair do viewport, o canal é
## desvanecido rapidamente e fica livre; chamar novamente quando voltar a
## estar visível permite retomá-lo sem acoplar a regra aos actors.
func laco_actor(actor: Node2D, nome: String, volume_db := -24.0,
		fade := 0.6) -> bool:
	if not actor_visivel(actor):
		return false
	var chave := "%s:%s" % [actor.get_instance_id(), nome]
	var p := _lacos.get(chave) as AudioStreamPlayer
	if p != null and is_instance_valid(p):
		_alvo_volume(p, volume_db, fade)
		return true
	if _lacos.size() >= LACOS_MAX:
		return false
	var st := _stream(nome)
	if st == null:
		return false
	_marcar_ciclico(st)
	p = AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = st
	p.volume_db = volume_db if fade <= 0.0 else volume_db - 24.0
	add_child(p)
	p.play()
	_lacos[chave] = p
	_lacos_actores[chave] = {"nome": nome, "actor_id": actor.get_instance_id()}
	_cena_dos_lacos = _id_da_cena()
	if fade > 0.0:
		_alvo_volume(p, volume_db, fade)
	return true


func parar_laco_actor(actor: Node2D, nome: String, fade := 0.08) -> void:
	var chave := "%s:%s" % [actor.get_instance_id(), nome]
	_lacos_actores.erase(chave)
	parar_laco(chave, fade)


## Verificação real contra a Camera2D/viewport, sem limiar de distância.
func actor_visivel(actor: Node2D) -> bool:
	if actor == null or not is_instance_valid(actor) or not actor.is_inside_tree():
		return false
	if not actor.is_visible_in_tree():
		return false
	var viewport := actor.get_viewport()
	if viewport == null:
		return false
	var canvas := viewport.get_canvas_transform()
	var rect := Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
	return rect.grow(1.0).has_point(canvas * actor.global_position)


## Quantos lacos estao mesmo a tocar. E' o numero que o harness conta.
func lacos_ativos() -> int:
	var n := 0
	for nome: String in _lacos:
		var p := _lacos[nome] as AudioStreamPlayer
		if is_instance_valid(p) and p.playing:
			n += 1
	return n


func _alvo_volume(p: AudioStreamPlayer, db: float, fade: float) -> void:
	if fade <= 0.0:
		p.volume_db = db
		return
	create_tween().tween_property(p, "volume_db", db, fade)


## Os `.wav` do catalogo sao importados sem `loop_mode` -- tocariam uma vez
## e calavam-se. Marca-se aqui, no recurso ja' em cache, e nao a mao no
## `.import`: o `--import` do Godot reescreve esses ficheiros e a marca
## perdia-se na primeira reimportacao de assets.
func _marcar_ciclico(st: AudioStream) -> void:
	var w := st as AudioStreamWAV
	if w != null:
		if w.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			# `loop_end = 0` NAO quer dizer "ate' ao fim": e' uma regiao de
			# ciclo de comprimento zero, e o player arranca e para no mesmo
			# frame. Media-se `playing == false` com `loop_mode == 1` --
			# parecia um laco que nao arrancava e era um laco vazio.
			w.loop_end = int(w.get_length() * float(w.mix_rate))
		return
	var o := st as AudioStreamOggVorbis
	if o != null:
		o.loop = true


## Um laco pertence ao AUTOLOAD, nao a' cena que o pediu. Sem este guarda,
## sair do nivel com `change_scene_to_file` deixava o vento a tocar por cima
## do menu -- e a cena seguinte, ao pedir o seu proprio ambiente, batia no
## `LACOS_MAX` com canais ocupados por um nivel que ja' nao existe.
func _process(_dt: float) -> void:
	if not _lacos.is_empty():
		var id := _id_da_cena()
		if id != _cena_dos_lacos:
			parar_lacos(0.0)
			_cena_dos_lacos = id
	for chave: String in _lacos_actores.keys():
		var info: Dictionary = _lacos_actores.get(chave, {})
		var actor := instance_from_id(int(info.get("actor_id", 0))) as Node2D
		if actor == null or not actor_visivel(actor):
			_lacos_actores.erase(chave)
			parar_laco(chave, FADE_ACTOR_FORA_ECRA)


## O `instance_id` da cena actual, ou 0 se nao houver nenhuma.
##
## Porque nao se guarda a referencia: em GDScript um `Object` LIBERTADO
## compara igual a `null`. O guarda comparava `cena != _cena_dos_lacos` com
## uma referencia, e depois de a cena antiga ser libertada essa comparacao
## dava `null != <libertado>` -> FALSO. Ou seja: o guarda calava-se
## exactamente no caso para que foi feito.
##
## E e' o caso normal -- `change_scene_to_file()` liberta a cena antiga. O
## defeito so' nao apareceu na bancada da 3B porque la' a cena velha ainda
## estava viva quando a nova entrava. Com ele, sair de um nivel com vento
## levava o vento para o nivel seguinte.
##
## Um inteiro nao tem este problema: um id nunca "vira null".
func _id_da_cena() -> int:
	if not is_inside_tree():
		return 0
	var cena := get_tree().current_scene
	return cena.get_instance_id() if cena != null else 0
