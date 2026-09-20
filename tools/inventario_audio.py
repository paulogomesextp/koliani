#!/usr/bin/env python3
"""SFX Overhaul Prompt 4 -- inventario final do catalogo de audio.

    python tools/inventario_audio.py            # escreve o .md
    python tools/inventario_audio.py --check     # so' o veredicto, sai !=0 se falhar

Junta num so' sitio as tres coisas que ate' aqui andavam separadas e por isso
nunca batiam certo:

  1. o CATALOGO   -- as chaves de `Som.CAMINHOS`;
  2. os FICHEIROS -- o que esta' mesmo em `assets/audio/`;
  3. os CALLSITES -- quem, no codigo do jogo, pede cada chave.

E' nessa juncao que vivem os defeitos que nao dao erro nenhum:

  * uma chave sem ficheiro -> `Som.toca()` devolve `false` em silencio e o
    evento fica mudo para sempre (sem aviso, sem log, sem crash);
  * uma chave sem callsite -> som que se manteve, se mediu e se afinou e que
    o jogo nunca toca;
  * dois nomes para o MESMO ficheiro byte-a-byte -> duas "identidades
    sonoras" no papel e uma so' no ouvido.

## O que NAO faz

Nao apaga nada. Assets sem uso ficam classificados `UNUSED` e a decisao e'
humana -- varios sao infra-estrutura adormecida de proposito (as camas de
musica, o `game_over`, as variacoes `_v2`/`_v3` que o `Som` sorteia sozinho
pelo nome base e que por isso nunca aparecem no codigo).

## Medicao

`ffprobe` para formato/duracao/canais e `ffmpeg -af volumedetect/ebur128`
para pico e LUFS integrado. Sons com menos de ~0,4 s nao passam o gate do
EBU R128 e devolvem -70: isso e' uma propriedade da norma, nao um defeito do
ficheiro, e aparece como `curto` na tabela.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(RAIZ, "assets", "audio")
SCRIPTS = os.path.join(RAIZ, "scripts")
SAIDA = os.path.join(RAIZ, "docs", "audio", "final_sfx_inventory.md")

EXTENSOES = (".wav", ".ogg", ".mp3")

## O `ffmpeg` esta' instalado por winget e nao vai ao PATH do Git Bash.
CANDIDATOS_FFMPEG = [
	os.path.join(os.environ.get("LOCALAPPDATA", ""), "Microsoft", "WinGet",
		"Packages",
		"Gyan.FFmpeg.Essentials_Microsoft.Winget.Source_8wekyb3d8bbwe",
		"ffmpeg-9.0.1-essentials_build", "bin"),
]


def achar(exe: str) -> str:
	achado = shutil.which(exe)
	if achado:
		return achado
	for pasta in CANDIDATOS_FFMPEG:
		p = os.path.join(pasta, exe + ".exe")
		if os.path.exists(p):
			return p
	return ""


FFMPEG = achar("ffmpeg")
FFPROBE = achar("ffprobe")


# ---------------------------------------------------------------- categorias
#
# A categoria sai do PAPEL do som, nao da pasta (estao todos na mesma). Os
# prefixos apanham as familias inteiras; a tabela resolve o resto. Um som que
# nao caia em lado nenhum aparece como `?` -- e' um sinal de que o catalogo
# cresceu sem ninguem decidir o que aquilo e'.
PREFIXOS = (
	("mob_", "ENEMY"),
	("ui_", "UI"),
	("bg_", "AMBIENCE"),
	("passo", "PLAYER"),
	("ataque", "PLAYER"),
	("raiz_", "HAZARD"),
	("portao_", "MECHANISM"),
	("pedra_", "HAZARD"),
	("vento_", "WORLD"),
)

CATEGORIA = {
	# --- jogador ---
	"salto": "PLAYER", "salto_duplo": "PLAYER", "aterrar": "PLAYER",
	"dash": "PLAYER", "rolamento": "PLAYER", "parede": "PLAYER",
	"agarrar": "PLAYER", "acerto": "PLAYER", "dano": "PLAYER",
	"bloqueio": "PLAYER", "morte_koliani": "PLAYER", "lancar": "PLAYER",
	"projetil": "PLAYER",
	# --- inimigos ---
	"demonio_ataque": "ENEMY",
	# --- chefes ---
	"chefe_cai": "BOSS", "chefe_magia": "BOSS", "investida": "BOSS",
	"onda": "BOSS", "esmagar": "BOSS", "golpe_pesado": "BOSS",
	"garra": "BOSS", "chama": "BOSS", "gelo": "BOSS", "praga": "BOSS",
	"raio": "BOSS", "invocar": "BOSS", "grito": "BOSS",
	"sino_ataque": "BOSS", "engrenagem": "BOSS", "lamina_cair": "BOSS",
	"feixe_vil": "BOSS", "meteoro": "BOSS", "mudar_forma": "BOSS",
	"olho_carregar": "BOSS",
	# --- mundo / mecanismos ---
	"mecanismo": "MECHANISM", "mecanismo_ciclo": "AMBIENCE",
	"sino_mecanismo": "MECHANISM", "plataforma_surge": "MECHANISM",
	"porta": "MECHANISM",
	# --- perigos ---
	"lamina_passa": "HAZARD", "fogo_sopro": "HAZARD",
	"raio_aviso": "HAZARD", "raio_cai": "HAZARD",
	# --- progressao ---
	"selo": "PROGRESSION", "conquista": "PROGRESSION",
	"transicao": "PROGRESSION", "apanhar": "PROGRESSION",
	"bau_abrir": "PROGRESSION", "recompensa": "PROGRESSION",
	"desbloqueio": "PROGRESSION",
	# --- interface ---
	"carrossel": "UI",
	# --- camas e ambiente ---
	"ambiente": "AMBIENCE", "ambiente_floresta": "AMBIENCE",
	"menu": "AMBIENCE", "boss": "AMBIENCE", "assombracao": "AMBIENCE",
	"game_over": "AMBIENCE", "vento_ciclo": "AMBIENCE",
}

## Ficheiros que NAO tem chave no `Som` de proposito. Sem esta lista, o
## veredicto marcava-os `UNUSED` todas as vezes e o sinal deixava de valer.
INTENCIONAIS = {
	"ambiente.wav": "cama antiga, tocada pelo autoload Musica",
	"ambiente_floresta.wav": "cama de bioma (Musica), nao SFX",
	"menu.wav": "cama do menu (Musica)",
	"boss.wav": "cama de chefe (Musica)",
	"assombracao.wav": "cama de tensao (Musica)",
	"game_over.wav": "ecra de fim (Musica)",
	"bg_menu.mp3": "cama do menu (Musica)",
	"bg_niveis.mp3": "cama de nivel (Musica)",
	"bg_boss.mp3": "cama de chefe (Musica)",
}


def categoria(chave: str) -> str:
	if chave in CATEGORIA:
		return CATEGORIA[chave]
	for pre, cat in PREFIXOS:
		if chave.startswith(pre):
			return cat
	return "?"


# ------------------------------------------------------------------- leitura

def ler_catalogo() -> dict[str, str]:
	"""As chaves de `Som.CAMINHOS`, lidas do proprio ficheiro.

	De proposito NAO se corre o Godot para isto: o inventario tem de poder
	acusar uma chave partida, e se o catalogo viesse do motor a chave partida
	ja' teria falhado antes de chegar aqui.
	"""
	texto = open(os.path.join(SCRIPTS, "som.gd"), encoding="utf-8").read()
	bloco = texto.split("const CAMINHOS := {", 1)[1].split("\n}", 1)[0]
	return dict(re.findall(r'"([^"]+)"\s*:\s*"res://assets/audio/([^"]+)"', bloco))


def ler_callsites(chaves: set[str]) -> dict[str, list[str]]:
	"""Quem pede cada chave, no codigo do JOGO.

	Tres passagens, porque o jogo pede sons de tres maneiras diferentes e uma
	so' passagem dava 29 falsos "sem uso" -- que e' pior do que nao medir:
	convida a apagar sons que o jogo toca mesmo.

	  DIRETO     `Som.toca("selo", ...)` -- a chave literal na propria linha
	             da chamada;
	  TABELA     `const SOM_COMBO := ["ataque", "ataque2", ...]` -- a chave
	             esta' num array/dicionario e a chamada usa o indice. Vale
	             como uso: o nome esta' escrito no codigo do jogo;
	  COMPOSTO   `Som.toca("mob_%s_%s" % [fam, que])` e
	             `Som.toca("passo%d" % n)` -- a chave nunca aparece inteira
	             em lado nenhum. Transforma-se o molde em expressao regular
	             (`%s`/`%d` -> um pedaco de nome) e ve^-se que chaves casam.

	`tools/` e `scripts/dev_sons.gd` ficam de fora: o painel de sons do dev
	toca o catalogo inteiro, e se contasse como uso nenhuma chave morta
	aparecia alguma vez.
	"""
	usos: dict[str, list[str]] = {c: [] for c in chaves}
	marca = re.compile(r"(toca|laco|parar_laco|_som|_som_ataque)")
	for pasta, _sub, ficheiros in os.walk(SCRIPTS):
		for f in sorted(ficheiros):
			if not f.endswith(".gd") or f in ("dev_sons.gd", "som.gd"):
				continue
			caminho = os.path.join(pasta, f)
			rel = os.path.relpath(caminho, RAIZ).replace("\\", "/")
			for n, linha in enumerate(
					open(caminho, encoding="utf-8").read().splitlines(), 1):
				literais = re.findall(r'"([^"]*)"', linha)
				chamada = bool(marca.search(linha))
				for lit in literais:
					if lit in usos and (chamada or _tabela(linha)):
						usos[lit].append("%s:%d" % (rel, n))
					elif "%" in lit:
						for chave in _casa_molde(lit, chaves):
							usos[chave].append("%s:%d~" % (rel, n))
	return usos


def _tabela(linha: str) -> bool:
	"""A linha e' uma tabela de sons? (`const X := [...]`, `{...}`)."""
	return bool(re.search(r"(const |var |:=|\[|\{)", linha))


def _casa_molde(molde: str, chaves: set[str]) -> list[str]:
	"""Chaves que casam com um molde de formatacao (`mob_%s_%s`, `passo%d`).

	`%s` vira um pedaco de nome sem `_` e `%d` vira digitos: sem isso,
	`"mob_%s_%s"` casaria com qualquer chave comecada por `mob_` e o
	inventario deixava de distinguir familias.
	"""
	if not re.search(r"%[sd]", molde):
		return []
	padrao = ""
	i = 0
	while i < len(molde):
		if molde[i] == "%" and i + 1 < len(molde) and molde[i + 1] in "sd":
			padrao += r"\d+" if molde[i + 1] == "d" else r"[a-z]+"
			i += 2
		else:
			padrao += re.escape(molde[i])
			i += 1
	rx = re.compile("^" + padrao + "$")
	return [c for c in chaves if rx.match(c)]


def medir(caminho: str) -> dict:
	"""Formato, duracao, canais, pico e LUFS. Sem ffmpeg devolve vazio -- o
	inventario continua a valer para catalogo/callsites/duplicados."""
	d: dict = {}
	if FFPROBE:
		saida = subprocess.run([
			FFPROBE, "-v", "error", "-show_entries",
			"format=duration,format_name:stream=sample_rate,channels",
			"-of", "json", caminho], capture_output=True, text=True).stdout
		try:
			j = json.loads(saida)
			d["dur"] = float(j["format"]["duration"])
			d["fmt"] = j["format"]["format_name"].split(",")[0]
			d["sr"] = int(j["streams"][0]["sample_rate"])
			d["ch"] = int(j["streams"][0]["channels"])
		except Exception:
			pass
	if FFMPEG:
		r = subprocess.run([FFMPEG, "-hide_banner", "-i", caminho,
			"-af", "volumedetect", "-f", "null", "-"],
			capture_output=True, text=True).stderr
		m = re.search(r"max_volume:\s*(-?[\d.]+) dB", r)
		if m:
			d["pico"] = float(m.group(1))
		r = subprocess.run([FFMPEG, "-hide_banner", "-i", caminho,
			"-af", "ebur128", "-f", "null", "-"],
			capture_output=True, text=True).stderr
		bloco = r.rsplit("Integrated loudness", 1)
		if len(bloco) == 2:
			m = re.search(r"I:\s*(-?[\d.]+) LUFS", bloco[1])
			if m:
				d["lufs"] = float(m.group(1))
	return d


# ------------------------------------------------------------------ analise

def main() -> int:
	so_check = "--check" in sys.argv
	catalogo = ler_catalogo()
	usos = ler_callsites(set(catalogo))
	no_disco = sorted(f for f in os.listdir(AUDIO) if f.endswith(EXTENSOES))

	# md5 -> ficheiros. Duplicados byte-a-byte sao duas identidades no papel
	# e uma so' no ouvido.
	por_hash: dict[str, list[str]] = {}
	for f in no_disco:
		h = hashlib.md5(open(os.path.join(AUDIO, f), "rb").read()).hexdigest()
		por_hash.setdefault(h, []).append(f)
	duplicados = [v for v in por_hash.values() if len(v) > 1]

	usados_ficheiros = set()
	linhas = []
	faltam, sem_uso = [], []
	for chave in sorted(catalogo, key=lambda c: (categoria(c), c)):
		nome = catalogo[chave]
		caminho = os.path.join(AUDIO, nome)
		existe = os.path.exists(caminho)
		if existe:
			usados_ficheiros.add(nome)
		n_usos = len(usos[chave])
		if not existe:
			estado = "MISSING"
			faltam.append(chave)
		elif n_usos == 0:
			# as variacoes `_v2`/`_v3` sao sorteadas pelo `Som` a partir do
			# nome base: nunca aparecem no codigo e nao sao chaves mortas
			if re.search(r"_v\d$", chave):
				estado = "INTENTIONAL"
			else:
				estado = "UNUSED"
				sem_uso.append(chave)
		else:
			estado = "USED"
		m = medir(caminho) if existe else {}
		linhas.append((categoria(chave), chave, nome, estado, n_usos, m,
			usos[chave][:2]))

	orfaos = [f for f in no_disco
		if f not in usados_ficheiros and f not in INTENCIONAIS]
	# Um orfao cujo NOME BASE tem chave noutra extensao nao e' um som perdido:
	# e' o formato anterior do mesmo evento, que ficou para tras quando a
	# 9H.13B trocou os samples `.ogg` por `.wav` sintetizados. Separa-los
	# importa -- um "sobra de formato" e' lixo de export, um orfao a serio
	# seria um som que alguem fez e ninguem ligou.
	bases_com_chave = {os.path.splitext(v)[0] for v in catalogo.values()}
	sobras = [f for f in orfaos if os.path.splitext(f)[0] in bases_com_chave]
	orfaos_reais = [f for f in orfaos if f not in sobras]

	if not so_check:
		escrever(linhas, faltam, sem_uso, orfaos_reais, sobras, duplicados,
			catalogo)

	print("INVENTARIO chaves=%d ficheiros=%d missing=%d unused=%d "
		"sobras_de_formato=%d orfaos=%d duplicados=%d" % (
		len(catalogo), len(no_disco), len(faltam), len(sem_uso),
		len(sobras), len(orfaos_reais), len(duplicados)))
	if faltam:
		print("  MISSING: %s" % ", ".join(faltam))
	if sem_uso:
		print("  UNUSED (chave sem callsite): %s" % ", ".join(sem_uso))
	if sobras:
		kb = sum(os.path.getsize(os.path.join(AUDIO, f)) for f in sobras) / 1024.0
		print("  SOBRAS DE FORMATO (.ogg/.mp3 de chaves que hoje sao .wav, "
			"%.0f KB): %s" % (kb, ", ".join(sobras)))
	if orfaos_reais:
		print("  ORFAOS (ficheiro sem chave nenhuma): %s" % ", ".join(orfaos_reais))
	for grupo in duplicados:
		print("  DUPLICADO byte-a-byte: %s" % " == ".join(grupo))
	# So' `MISSING` e' falha dura: e' o unico que deixa um evento mudo em
	# producao. `UNUSED`/duplicado querem decisao humana.
	return 1 if faltam else 0


def escrever(linhas, faltam, sem_uso, orfaos, sobras, duplicados,
		catalogo) -> None:
	def fmt(m, chave_m, casas=1, sufixo=""):
		v = m.get(chave_m)
		return ("%.*f%s" % (casas, v, sufixo)) if v is not None else "—"

	out = []
	out.append("# Inventário final do áudio — SFX Overhaul, Prompt 4\n")
	out.append("Gerado por `tools/inventario_audio.py`. Não editar à mão.\n")
	out.append("Junta catálogo (`Som.CAMINHOS`) + ficheiros em "
		"`assets/audio/` + callsites no código do jogo. É na junção dos três "
		"que vivem os defeitos que não dão erro nenhum: uma chave sem "
		"ficheiro deixa o evento mudo em silêncio, e uma chave sem callsite "
		"é um som que ninguém toca.\n")
	out.append("`tools/` e `scripts/dev_sons.gd` não contam como uso — o "
		"painel de sons do dev toca o catálogo inteiro e mascararia todas as "
		"chaves mortas.\n")
	out.append("## Veredicto\n")
	out.append("| | |")
	out.append("|---|---|")
	out.append("| chaves no catálogo | %d |" % len(catalogo))
	out.append("| **MISSING** (chave sem ficheiro) | **%d** |" % len(faltam))
	out.append("| UNUSED (chave sem callsite) | %d |" % len(sem_uso))
	out.append("| sobras de formato (`.ogg`/`.mp3` de chaves que hoje são "
		"`.wav`) | %d |" % len(sobras))
	out.append("| órfãos reais (ficheiro sem chave nenhuma) | %d |"
		% len(orfaos))
	out.append("| duplicados byte-a-byte | %d |" % len(duplicados))
	out.append("")
	if sem_uso:
		out.append("UNUSED: `%s`\n" % "`, `".join(sem_uso))
	if orfaos:
		out.append("Órfãos: `%s`\n" % "`, `".join(orfaos))
	for grupo in duplicados:
		out.append("Duplicado byte-a-byte: `%s`\n" % "` == `".join(grupo))
	out.append("Nada é apagado por este script. Assets sem uso ficam "
		"classificados e a decisão é humana — vários são infra-estrutura "
		"adormecida de propósito.\n")

	out.append("## Catálogo\n")
	out.append("`LUFS` é integrado com gate EBU R128; sons abaixo de ~0,4 s "
		"não passam o gate e leem −70 — é a norma, não o ficheiro. Aparecem "
		"como `curto`.\n")
	cat_atual = None
	for cat, chave, nome, estado, n, m, exemplos in linhas:
		if cat != cat_atual:
			cat_atual = cat
			out.append("\n### %s\n" % cat)
			out.append("| chave | ficheiro | fmt | dur | SR | ch | pico | "
				"LUFS | estado | usos | callsite |")
			out.append("|---|---|---|--:|--:|--:|--:|--:|---|--:|---|")
		lufs = m.get("lufs")
		slufs = "curto" if (lufs is not None and lufs <= -69.0) \
			else fmt(m, "lufs")
		out.append("| `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %d | %s |"
			% (chave, nome, m.get("fmt", "—"), fmt(m, "dur", 2),
			m.get("sr", "—"), m.get("ch", "—"), fmt(m, "pico"), slufs,
			estado, n, (exemplos[0] if exemplos else "—")))
	out.append("")
	os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
	with open(SAIDA, "w", encoding="utf-8", newline="\n") as f:
		f.write("\n".join(out))
	print("escrito: %s" % os.path.relpath(SAIDA, RAIZ))


if __name__ == "__main__":
	raise SystemExit(main())
