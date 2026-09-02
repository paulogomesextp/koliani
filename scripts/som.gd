extends Node
## Autoload "Som": toca efeitos sonoros por nome, com um pool de vozes
## para sons sobrepostos. Os `.wav` em `assets/audio/` são gerados por nós
## (sintetizados) -- sem licença de terceiros. Sem música ainda.
##
## Carrega os streams à primeira utilização (não `preload`) para o script
## compilar mesmo antes de o Godot importar os `.wav` (fresh checkout / CI).

const CAMINHOS := {
	"salto": "res://assets/audio/salto.wav",
	"salto_duplo": "res://assets/audio/salto_duplo.wav",
	"ataque": "res://assets/audio/ataque.wav",
	"acerto": "res://assets/audio/acerto.wav",
	"dano": "res://assets/audio/dano.wav",
	"aterrar": "res://assets/audio/aterrar.wav",
	"apanhar": "res://assets/audio/apanhar.wav",
	"porta": "res://assets/audio/porta.wav",
	"chefe_cai": "res://assets/audio/chefe_cai.wav",
	"selo": "res://assets/audio/selo.wav",
	"projetil": "res://assets/audio/projetil.wav",
	"investida": "res://assets/audio/investida.wav",
	"onda": "res://assets/audio/onda.wav",
	"bloqueio": "res://assets/audio/bloqueio.wav",
	"demonio_ataque": "res://assets/audio/demonio_ataque.wav",
	"conquista": "res://assets/audio/conquista.wav",
	"transicao": "res://assets/audio/transicao.wav",
	"chefe_magia": "res://assets/audio/chefe_magia.wav",
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
