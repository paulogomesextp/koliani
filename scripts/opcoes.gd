extends Node
## Autoload "Opcoes": definições do jogador -- volume da música, volume dos
## efeitos e idioma. Guarda em `user://opcoes.json` (separado do progresso
## de jogo). Cria os buses de áudio "Music" e "SFX" (o `Musica` e o `Som`
## encaminham para lá) e aplica tudo no arranque.
##
## Vem ANTES do `Som`/`Musica` na lista de autoloads para os buses já
## existirem quando eles arrancam; vem DEPOIS do `Textos` para lhe poder
## fixar o idioma guardado.

const CAMINHO := "user://opcoes.json"

var vol_musica := 1.0   # 0.0 .. 1.0 (linear)
var vol_efeitos := 0.9  # 0.0 .. 1.0 (linear)
var idioma := "en"


func _ready() -> void:
	_criar_buses()
	carregar()
	aplicar()


func _criar_buses() -> void:
	for nome in ["Music", "SFX"]:
		if AudioServer.get_bus_index(nome) == -1:
			var i := AudioServer.bus_count
			AudioServer.add_bus(i)
			AudioServer.set_bus_name(i, nome)
			AudioServer.set_bus_send(i, "Master")


func aplicar() -> void:
	_aplicar_volume("Music", vol_musica)
	_aplicar_volume("SFX", vol_efeitos)
	Textos.definir_idioma(idioma)


func _aplicar_volume(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(clampf(v, 0.001, 1.0)))


func definir_musica(v: float) -> void:
	vol_musica = clampf(v, 0.0, 1.0)
	_aplicar_volume("Music", vol_musica)
	guardar()


func definir_efeitos(v: float) -> void:
	vol_efeitos = clampf(v, 0.0, 1.0)
	_aplicar_volume("SFX", vol_efeitos)
	guardar()


func definir_idioma(loc: String) -> void:
	idioma = loc
	Textos.definir_idioma(loc)
	guardar()


func guardar() -> void:
	var f := FileAccess.open(CAMINHO, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"vol_musica": vol_musica,
		"vol_efeitos": vol_efeitos,
		"idioma": idioma,
	}, "\t"))
	f.close()


func carregar() -> void:
	if not FileAccess.file_exists(CAMINHO):
		return
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO))
	if dados is Dictionary:
		vol_musica = float(dados.get("vol_musica", vol_musica))
		vol_efeitos = float(dados.get("vol_efeitos", vol_efeitos))
		idioma = str(dados.get("idioma", idioma))
