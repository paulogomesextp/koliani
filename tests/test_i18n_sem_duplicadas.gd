class_name TestesI18nSemDuplicadas
extends RefCounted
## O `JSON.parse` do Godot aceita chaves repetidas e fica com a ULTIMA, em
## silencio: o merge do N17 deixou `guard.automato_de_fundicao` duas vezes e a
## 2.a (em ingles) vencia nas linguas que nao eram o ingles. Le o texto em bruto
## e exige que cada chave apareca uma unica vez em cada `assets/i18n/*.json`.

const LINGUAS := ["en", "pt", "es", "fr", "de", "zh"]


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var re := RegEx.new()
	re.compile('(?m)^\\s*"([^"]+)"\\s*:')
	for loc in LINGUAS:
		var f := FileAccess.open("res://assets/i18n/%s.json" % loc, FileAccess.READ)
		if f == null:
			falhas.append("i18n %s: ficheiro nao abre" % loc)
			continue
		var vistas := {}
		for m: RegExMatch in re.search_all(f.get_as_text()):
			var k: String = m.get_string(1)
			if vistas.has(k):
				falhas.append("i18n %s: chave duplicada '%s'" % [loc, k])
			vistas[k] = true
	return falhas
