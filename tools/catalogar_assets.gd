extends SceneTree
## Varre `assets/sprites/incoming/` (packs CC0 largados pelo Paulo) e escreve
## um catálogo em `docs/assets_incoming.md` com o tamanho real de cada PNG,
## agrupado por pack e por subpasta, com um palpite da grelha (frames) para
## as folhas de sprites. Uso:
##   Godot --headless --script res://tools/catalogar_assets.gd

const RAIZ := "res://assets/sprites/incoming"
const SAIDA := "res://docs/assets_incoming.md"


func _init() -> void:
	var linhas: Array[String] = []
	linhas.append("# Catálogo dos assets CC0 em `assets/sprites/incoming/`")
	linhas.append("")
	linhas.append("Gerado por `tools/catalogar_assets.gd`. `incoming/` está fora do git")
	linhas.append("(`.gdignore`); copia-se o que se usa para `assets/sprites/pixel/` e")
	linhas.append("credita-se em `CREDITS.md`. Tamanhos em px reais do PNG.")
	linhas.append("")

	var packs := _listar_dir(RAIZ, true)
	packs.sort()
	for pack in packs:
		linhas.append("## %s" % pack)
		linhas.append("")
		var pngs := _todos_png("%s/%s" % [RAIZ, pack])
		if pngs.is_empty():
			linhas.append("_(sem PNG)_")
			linhas.append("")
			continue
		# agrupa por subpasta relativa ao pack
		var por_sub := {}
		for p in pngs:
			var rel: String = p.substr(("%s/%s/" % [RAIZ, pack]).length())
			var sub := rel.get_base_dir()
			if sub == "":
				sub = "."
			if not por_sub.has(sub):
				por_sub[sub] = []
			por_sub[sub].append([rel.get_file(), _dim(p)])
		var subs := por_sub.keys()
		subs.sort()
		for sub in subs:
			var itens: Array = por_sub[sub]
			# resumo por dimensão dominante
			var contagem := {}
			for it in itens:
				var d: String = it[1]
				contagem[d] = int(contagem.get(d, 0)) + 1
			var resumo := []
			for d in contagem:
				resumo.append("%s×%d" % [d, contagem[d]])
			linhas.append("### `%s/` — %d ficheiros  (%s)" % [sub, itens.size(), ", ".join(resumo)])
			# lista até 40 nomes; acima disso só o resumo
			if itens.size() <= 40:
				for it in itens:
					linhas.append("- `%s`  %s" % [it[0], it[1]])
			else:
				var mostra := itens.slice(0, 12)
				for it in mostra:
					linhas.append("- `%s`  %s" % [it[0], it[1]])
				linhas.append("- … (+%d)" % (itens.size() - 12))
			linhas.append("")

	var f := FileAccess.open(SAIDA, FileAccess.WRITE)
	f.store_string("\n".join(linhas))
	f.close()
	print("Catálogo escrito: %s  (%d packs)" % [SAIDA, packs.size()])
	quit(0)


func _listar_dir(caminho: String, so_dirs: bool) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(caminho)
	if d == null:
		return out
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if nome.begins_with("."):
			nome = d.get_next()
			continue
		if so_dirs and d.current_is_dir():
			out.append(nome)
		elif not so_dirs and not d.current_is_dir():
			out.append(nome)
		nome = d.get_next()
	d.list_dir_end()
	return out


func _todos_png(caminho: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(caminho)
	if d == null:
		return out
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if nome.begins_with("."):
			nome = d.get_next()
			continue
		var p := "%s/%s" % [caminho, nome]
		if d.current_is_dir():
			out.append_array(_todos_png(p))
		elif nome.to_lower().ends_with(".png"):
			out.append(p)
		nome = d.get_next()
	d.list_dir_end()
	return out


func _dim(res_path: String) -> String:
	var abs := ProjectSettings.globalize_path(res_path)
	var img := Image.new()
	var err := img.load(abs)
	if err != OK:
		return "?"
	return "%dx%d" % [img.get_width(), img.get_height()]
