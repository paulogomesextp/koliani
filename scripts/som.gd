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
	"ataque": "res://assets/audio/ataque.wav",
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
