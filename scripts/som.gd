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
	"ataque": "res://assets/audio/ataque.ogg",
	"lancar": "res://assets/audio/lancar.ogg",
	"acerto": "res://assets/audio/acerto.ogg",
	"dano": "res://assets/audio/dano.ogg",
	"aterrar": "res://assets/audio/aterrar.mp3",
	"apanhar": "res://assets/audio/apanhar.wav",
	"porta": "res://assets/audio/porta.wav",
	"chefe_cai": "res://assets/audio/chefe_cai.wav",
	"selo": "res://assets/audio/selo.ogg",
	"projetil": "res://assets/audio/projetil.wav",
	"investida": "res://assets/audio/investida.wav",
	"onda": "res://assets/audio/onda.ogg",
	"bloqueio": "res://assets/audio/bloqueio.ogg",
	"demonio_ataque": "res://assets/audio/demonio_ataque.ogg",
	"conquista": "res://assets/audio/conquista.wav",
	"transicao": "res://assets/audio/transicao.wav",
	"carrossel": "res://assets/audio/carrossel.wav",
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
	"passo1": "res://assets/audio/passo1.ogg",
	"passo2": "res://assets/audio/passo2.ogg",
	"passo3": "res://assets/audio/passo3.ogg",
	"rolamento": "res://assets/audio/rolamento.ogg",
	"dash": "res://assets/audio/dash.ogg",
	"parede": "res://assets/audio/parede.ogg",
	"agarrar": "res://assets/audio/agarrar.ogg",
	"morte_koliani": "res://assets/audio/morte_koliani.ogg",
	"ataque_forte": "res://assets/audio/ataque_forte.ogg",
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

var _pool: Array[AudioStreamPlayer] = []
var _idx := 0
var _cache := {}


func _ready() -> void:
	for i in VOZES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"  # bus criado pelo autoload Opcoes
		add_child(p)
		_pool.append(p)


func _stream(nome: String) -> AudioStream:
	if not _cache.has(nome):
		var c: String = CAMINHOS.get(nome, "")
		_cache[nome] = load(c) if c != "" and ResourceLoader.exists(c) else null
	return _cache[nome]


func toca(nome: String, volume_db := -6.0, pitch := 1.0) -> void:
	var st := _stream(nome)
	if st == null:
		return
	var p := _pool[_idx]
	_idx = (_idx + 1) % VOZES
	p.stream = st
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.play()
