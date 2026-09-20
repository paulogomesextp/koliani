extends Node
## Autoload "Som": toca efeitos sonoros por nome, com um pool de vozes
## para sons sobrepostos. Os SFX em `assets/audio/` são samples CC0 reais
## (OpenGameArt -- ver `assets/audio/CREDITS.md`); só as camas antigas
## (`ambiente.wav`, `menu.wav`, `boss.wav`, `assombracao.wav`, `game_over.wav`)
## continuam sintetizadas por `tools/gerar_audio.py`.
##
## Carrega os streams à primeira utilização (não `preload`) para o script
## compilar mesmo antes de o Godot importar os ficheiros (fresh checkout / CI).

const CAMINHOS := {
	"salto": "res://assets/audio/salto.wav",
	"salto_duplo": "res://assets/audio/salto_duplo.wav",
	# Execution 9H.13: o combo tem QUATRO sons proprios, que crescem em peso.
	# Ate' aqui os golpes 2 e 3 eram o `ataque` com `pitch_scale`
	# diferente -- e um sample repetido com outro tom le-se logo como sample
	# repetido. Ver `tools/gerar_sfx_9h13.py` (os tres eixos de crescimento).
	"ataque": "res://assets/audio/ataque.wav",
	"ataque2": "res://assets/audio/ataque2.wav",
	"ataque3": "res://assets/audio/ataque3.wav",
	"lancar": "res://assets/audio/lancar.ogg",
	"acerto": "res://assets/audio/acerto.wav",
	"dano": "res://assets/audio/dano.wav",
	"aterrar": "res://assets/audio/aterrar.wav",
	"apanhar": "res://assets/audio/apanhar.wav",
	"porta": "res://assets/audio/porta.wav",
	"chefe_cai": "res://assets/audio/chefe_cai.wav",
	"selo": "res://assets/audio/selo.wav",
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
	"acerto_v2": "res://assets/audio/acerto_v2.wav",
	"acerto_v3": "res://assets/audio/acerto_v3.wav",
	"transicao": "res://assets/audio/transicao.wav",
	"carrossel": "res://assets/audio/carrossel.wav",
	# --- vozes de interface (Execution 9H) --------------------------------
	# O frontend novo pedia um som próprio: o `carrossel` era um clique seco
	# de interface e destoava do menu de fantasia escura. Sintetizados por
	# `tools/gerar_audio_9h.py` (sino + sopro, sem licenças).
	"ui_mover": "res://assets/audio/ui_mover.wav",
	"ui_confirmar": "res://assets/audio/ui_confirmar.wav",
	"ui_voltar": "res://assets/audio/ui_voltar.wav",
	"ui_negado": "res://assets/audio/ui_negado.wav",
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
	# --- a Koliani a mexer-se (4 set 2026) --------------------------------
	# "Faca um set de sons para a koliani quando faz animacoes, ataques,
	# etc." -- pedido do Paulo. Construidos por `tools/preparar_sfx.py`.
	"passo1": "res://assets/audio/passo1.wav",
	"passo2": "res://assets/audio/passo2.wav",
	"passo3": "res://assets/audio/passo3.wav",
	"rolamento": "res://assets/audio/rolamento.wav",
	"dash": "res://assets/audio/dash.wav",
	"parede": "res://assets/audio/parede.ogg",
	"agarrar": "res://assets/audio/agarrar.ogg",
	"morte_koliani": "res://assets/audio/morte_koliani.wav",
	"ataque_forte": "res://assets/audio/ataque_forte.wav",
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
const VARIANTES := {"ui_mover": 3, "acerto": 3}
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
