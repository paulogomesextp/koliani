extends Node
## Autoload "Textos": traduções do jogo. Carrega `assets/i18n/<loc>.json`
## (dicionário chave -> string) e devolve o texto no idioma atual. O
## idioma por omissão é **inglês**; o `pt`/`es`/`fr`/`de`/`zh` são
## traduções. Chave em falta -> tenta o inglês -> devolve a própria chave.
##
## Trocar de idioma: `Textos.definir_idioma(loc)` e recarregar a cena (os
## _ready dos ecrãs voltam a pedir os textos). Quem faz isso é o menu de
## Opções via `Opcoes`.
##
## Carrega por JSON (não por `tr()`/CSV) para não depender do pipeline de
## importação -- corre igual em `--script`, fresh checkout e CI.

signal idioma_mudou(loc: String)

const IDIOMAS := ["en", "pt", "es", "fr", "de", "zh"]
## Nome de cada idioma escrito no próprio idioma (para o seletor).
const NOMES := {
	"en": "English", "pt": "Português", "es": "Español",
	"fr": "Français", "de": "Deutsch", "zh": "中文",
}
const _BASE := "res://assets/i18n/%s.json"

var _loc := "en"
var _map: Dictionary = {}
var _en: Dictionary = {}


func _ready() -> void:
	_en = _carregar("en")
	_map = _en


func idioma() -> String:
	return _loc


func definir_idioma(loc: String) -> void:
	if loc not in IDIOMAS:
		loc = "en"
	if loc == _loc and not _map.is_empty():
		return
	_loc = loc
	_map = _en if loc == "en" else _carregar(loc)
	idioma_mudou.emit(loc)


## Texto da chave no idioma atual.
func t(chave: String) -> String:
	if _map.has(chave):
		return _map[chave]
	if _en.has(chave):
		return _en[chave]
	return chave


## Texto com formatação: `Textos.tf("menu.load_world", [3])`.
func tf(chave: String, args: Array) -> String:
	return t(chave) % args


func _carregar(loc: String) -> Dictionary:
	var caminho := _BASE % loc
	# 1) recurso importado (é o que existe no export Web/APK)
	if ResourceLoader.exists(caminho):
		var r: Variant = load(caminho)
		if r is JSON and r.data is Dictionary:
			return r.data
		if r is Dictionary:
			return r
	# 2) ficheiro em disco (editor / dev / headless sem import)
	if FileAccess.file_exists(caminho):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(caminho))
		if d is Dictionary:
			return d
	push_warning("i18n em falta: %s" % caminho)
	return {}
