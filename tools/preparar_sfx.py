#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Constroi os efeitos sonoros do jogo a partir de packs CC0 do OpenGameArt.

## Porque e' que isto existe

Ate' aqui cada SFX era UM ficheiro copiado 'a mao de um pack. Isso chega
para uma porta a abrir, mas nao chega para o que o Paulo pediu a 4 set
2026:

  "Faca um set de sons para a koliani quando faz animacoes, ataques, etc.
   Faca com que os mobs facam sons tambem apropriados ao tipo de monstro."
  "Continuo sem gostar do som da espada, dos misseis."

Duas coisas mudam aqui:

1. **Sons novos que nao existiam** -- passos, rolamento, dash, deslizar na
   parede, agarrar a borda, e um som proprio por ARQUETIPO de monstro
   (humanoide, morto-vivo, gosma, besta, insecto, voador, grande) em vez
   dos quatro sons partilhados por todas as 19 especies.

2. **Sons em CAMADAS.** A espada ja' foi trocada duas vezes por outra
   amostra solta e ele continua a nao gostar -- porque uma amostra solta
   nunca soa a golpe de jogo. Um golpe de espada a serio sao duas coisas
   ao mesmo tempo: o AR a abrir e o METAL a cantar, com uns milissegundos
   de diferenca. Esta ferramenta mistura as camadas, alinha-as, apara o
   silencio da frente e iguala o pico -- e' isso que faz a diferenca.

## Uso

    python tools/preparar_sfx.py --descarregar   # busca os packs
    python tools/preparar_sfx.py                 # constroi tudo
    python tools/preparar_sfx.py --so ataque     # so' um som
    python tools/preparar_sfx.py --lista         # o que existe e de onde vem

Os packs ficam em `assets/audio/incoming/` (ignorado pelo git). A saida
sao `.ogg` mono em `assets/audio/`, referidos por `scripts/som.gd`.

Precisa do ffmpeg: `pip install --user imageio-ffmpeg`.
"""

from __future__ import annotations

import argparse
import io
import os
import re
import shutil
import subprocess
import sys
import urllib.request
import zipfile

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC = os.path.join(RAIZ, "assets", "audio", "incoming", "sfx")
SAIDA = os.path.join(RAIZ, "assets", "audio")
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) koliani-asset-fetch"

PICO_ALVO = -2.0     # dBFS: todos os SFX saem com o mesmo pico
BITRATE = "96k"      # SFX sao curtos; nao vale a pena poupar aqui
## Tecto de duracao. Um SFX que arrasta pisa o seguinte -- um dash de 2,5 s
## ainda esta' a tocar quando ela ja' deu o dash outra vez. `max` por som
## manda por cima disto; o corte leva sempre um fade curto no fim.
DUR_MAXIMA = 1.5
FADE_FIM = 0.06

# --------------------------------------------------------------------------
# Packs. Todos CC0 -- ver `assets/audio/CREDITS.md`.
# --------------------------------------------------------------------------
FONTES = {
	"passos": {
		"url": "https://opengameart.org/sites/default/files/%5Bkdd%5DDifferentSteps_0.zip",
		"pagina": "https://opengameart.org/content/different-steps-on-wood-stone-leaves-gravel-and-mud",
		"licenca": "CC0 -- TinyWorlds",
	},
	"monstros": {
		"url": "https://opengameart.org/sites/default/files/monster_sfx_pack.zip",
		"pagina": "https://opengameart.org/content/monster-sound-effects-pack",
		"licenca": "CC0 -- Ogrebane",
	},
	"criaturas2": {
		"url": "https://opengameart.org/sites/default/files/80-CC0-creature-sfx-2.zip",
		"pagina": "https://opengameart.org/content/80-cc0-creture-sfx-2",
		"licenca": "CC0 -- rubberduck",
	},
	"sfx100_2": {
		"url": "https://opengameart.org/sites/default/files/sfx_100_v2.zip",
		"pagina": "https://opengameart.org/content/100-cc0-sfx-2",
		"licenca": "CC0 -- rubberduck",
	},
	"kenney": {
		"url": "https://opengameart.org/sites/default/files/RPGsounds_Kenney.zip",
		"pagina": "https://opengameart.org/content/50-rpg-sound-effects",
		"licenca": "CC0 -- Kenney",
	},
}

K = "kenney/OGG/%s.ogg"
S = "sfx100_2/sfx100v2_%s.ogg"
C = "criaturas2/%s.ogg"
M = "monstros/monster_sfx_pack/monster-%d.wav"
P = "passos/%s.ogg"

# --------------------------------------------------------------------------
# Os sons. Cada um e' uma lista de CAMADAS `(ficheiro, atraso_s, ganho_dB)`
# misturadas; uma camada so' e' o caso simples. `vel` muda a velocidade sem
# mexer no tom (`atempo`), `tom` transpoe (`asetrate`).
# --------------------------------------------------------------------------
SONS: dict[str, dict] = {
	# --- a Koliani a mexer-se (tudo novo) -----------------------------
	# tres variantes de passo: o pool do `Som` alterna e o pitch aleatorio
	# faz o resto. Uma so' amostra a repetir soa a metronomo.
	"passo1": {"cam": [(K % "footstep00", 0.0, 0.0)], "nota": "passo em pedra"},
	"passo2": {"cam": [(K % "footstep03", 0.0, 0.0)], "nota": "passo em pedra"},
	"passo3": {"cam": [(P % "stone01", 0.0, 0.0)], "nota": "passo em pedra"},
	# rolar: pano a esfregar + ar. E' o mesmo gesto que o dash, mas mais
	# surdo -- por isso o dash leva so' o ar, e mais agudo.
	"rolamento": {"max": 0.45, "cam": [(K % "cloth3", 0.0, -2.0), (S % "air_02", 0.02, -6.0)],
	              "nota": "rolamento"},
	"dash": {"max": 0.35, "cam": [(S % "air_01", 0.0, 0.0)], "tom": 1.12, "nota": "dash"},
	# deslizar na parede: cascalho a arranhar, esticado e grave
	"parede": {"max": 0.60, "cam": [(P % "gravel", 0.0, -4.0)], "vel": 0.7, "tom": 0.85,
	           "nota": "deslizar na parede"},
	"agarrar": {"cam": [(K % "handleSmallLeather", 0.0, 0.0)],
	            "nota": "agarrar a borda"},
	"morte_koliani": {"cam": [(C % "human_05", 0.0, 0.0)], "tom": 1.06,
	                  "nota": "a Koliani a cair"},

	# --- espada e misseis: EM CAMADAS (o que o Paulo nao gostava) ------
	# o golpe e' ar + metal, com 30 ms entre os dois: primeiro a lamina
	# abre o ar, depois canta. Uma amostra solta nunca da' isto.
	"ataque": {"max": 0.38, "cam": [(S % "air_03", 0.0, -1.0), (K % "knifeSlice", 0.03, -4.0)],
	           "tom": 1.05, "nota": "golpe de espada (ar + metal)"},
	# o remate do combo e' o mesmo golpe mais fundo e com peso de metal
	"ataque_forte": {"max": 0.60, "cam": [(S % "air_02", 0.0, 0.0), (K % "knifeSlice2", 0.04, -3.0),
	                         (S % "metal_hit_01", 0.05, -9.0)],
	                 "tom": 0.9, "nota": "remate do combo"},
	# o tiro magico: sopro de ar grave + zumbido metalico -> le^-se a energia
	"lancar": {"max": 0.45, "cam": [(S % "air_01", 0.0, -2.0), (S % "metal_04", 0.02, -8.0)],
	           "tom": 0.82, "nota": "tiro magico roxo"},

	# --- monstros, por ARQUETIPO --------------------------------------
	# 19 especies partilhavam quatro sons. Agora cada familia tem a sua voz:
	# ataque (o que se ouve ao investir), dano e morte.
	"mob_humano_ataque": {"cam": [(C % "grunt_07", 0.0, 0.0)], "nota": "goblin/orc/imp/chort/wogol"},
	"mob_humano_dano":   {"cam": [(C % "grunt_09", 0.0, 0.0)], "tom": 1.1},
	"mob_humano_morte":  {"cam": [(C % "die_02", 0.0, 0.0)]},

	"mob_morto_ataque": {"cam": [(M % 4, 0.0, 0.0)], "tom": 1.15, "nota": "esqueleto/necromante"},
	"mob_morto_dano":   {"cam": [(S % "wood_hit_02", 0.0, 0.0)], "tom": 1.2},
	"mob_morto_morte":  {"cam": [(S % "wood_03", 0.0, 0.0), (M % 7, 0.05, -6.0)], "tom": 0.9},

	"mob_gosma_ataque": {"cam": [(C % "slime_03", 0.0, 0.0)], "nota": "gosma/lodo/mushroom"},
	"mob_gosma_dano":   {"cam": [(C % "slime_06", 0.0, 0.0)], "tom": 1.1},
	"mob_gosma_morte":  {"cam": [(C % "slime_08", 0.0, 0.0)], "tom": 0.85},

	"mob_besta_ataque": {"cam": [(M % 2, 0.0, 0.0)], "nota": "mastim/raptor"},
	"mob_besta_dano":   {"cam": [(C % "roar_05", 0.0, 0.0)], "tom": 1.25},
	"mob_besta_morte":  {"cam": [(C % "die_04", 0.0, 0.0)], "tom": 0.95},

	"mob_insecto_ataque": {"cam": [(C % "bug_07", 0.0, 0.0)], "nota": "besouro"},
	"mob_insecto_dano":   {"cam": [(C % "bug_10", 0.0, 0.0)], "tom": 1.15},
	"mob_insecto_morte":  {"cam": [(C % "bug_13", 0.0, 0.0)], "tom": 0.9},

	"mob_voador_ataque": {"cam": [(C % "alien_09", 0.0, 0.0)], "nota": "olho/abutre"},
	"mob_voador_dano":   {"cam": [(C % "alien_11", 0.0, 0.0)], "tom": 1.2},
	"mob_voador_morte":  {"cam": [(C % "die_01", 0.0, 0.0)], "tom": 1.1},

	"mob_grande_ataque": {"max": 0.80, "cam": [(C % "roar_04", 0.0, 0.0)], "tom": 0.85,
	                      "nota": "demonio_grande/ogro/xamane/abobora"},
	"mob_grande_dano":   {"cam": [(M % 9, 0.0, 0.0)], "tom": 0.8},
	"mob_grande_morte":  {"cam": [(C % "roar_06", 0.0, 0.0), (C % "stomp_01", 0.15, -6.0)],
	                      "tom": 0.75},
}

FF = None


def _ffmpeg() -> str:
	try:
		import imageio_ffmpeg
		return imageio_ffmpeg.get_ffmpeg_exe()
	except ImportError:
		if shutil.which("ffmpeg"):
			return "ffmpeg"
		sys.exit("preciso do ffmpeg: pip install --user imageio-ffmpeg")


def _corre(args: list[str]) -> str:
	global FF
	if FF is None:
		FF = _ffmpeg()
	return subprocess.run([FF, "-y", "-nostdin"] + args,
	                      capture_output=True, text=True).stderr


def pico(caminho: str) -> float:
	"""Pico em dBFS."""
	for linha in _corre(["-i", caminho, "-af", "volumedetect",
	                     "-f", "null", "-"]).splitlines():
		m = re.search(r"max_volume: ([-\d.]+) dB", linha)
		if m:
			return float(m.group(1))
	return 0.0


def descarregar() -> None:
	os.makedirs(INC, exist_ok=True)
	for fid, f in FONTES.items():
		destino = os.path.join(INC, fid)
		if os.path.isdir(destino) and os.listdir(destino):
			print("  ja' tenho  %s/" % fid)
			continue
		print("  a buscar   %s ..." % fid, flush=True)
		req = urllib.request.Request(f["url"], headers={"User-Agent": UA})
		dados = urllib.request.urlopen(req, timeout=300).read()
		zipfile.ZipFile(io.BytesIO(dados)).extractall(destino)
	print("packs em %s" % INC)


def construir(nome: str, receita: dict) -> str:
	"""Mistura as camadas, apara e iguala o pico. Devolve uma linha de ficha."""
	entradas = []
	filtros = []
	for i, (rel, atraso, ganho) in enumerate(receita["cam"]):
		caminho = os.path.join(INC, rel.replace("/", os.sep))
		if not os.path.exists(caminho):
			raise SystemExit("falta %s -- corre --descarregar" % caminho)
		entradas += ["-i", caminho]
		f = "[%d:a]aformat=channel_layouts=mono" % i
		if atraso > 0:
			f += ",adelay=%d" % int(atraso * 1000)
		if ganho:
			f += ",volume=%.2fdB" % ganho
		filtros.append(f + "[c%d]" % i)

	n = len(receita["cam"])
	cadeia = ";".join(filtros)
	if n > 1:
		cadeia += ";" + "".join("[c%d]" % i for i in range(n))
		cadeia += "amix=inputs=%d:normalize=0[m]" % n
	else:
		cadeia += ";[c0]anull[m]"

	# velocidade e tom -- `asetrate` transpoe (muda a duracao), `atempo`
	# so' estica no tempo. Aplicados por esta ordem, como num sampler.
	extra = []
	if receita.get("tom", 1.0) != 1.0:
		extra.append("asetrate=44100*%.4f" % receita["tom"])
		extra.append("aresample=44100")
	if receita.get("vel", 1.0) != 1.0:
		extra.append("atempo=%.4f" % receita["vel"])
	# apara o silencio da frente: um SFX tem de comecar quando e' disparado
	extra.append("silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0")
	tecto = float(receita.get("max", DUR_MAXIMA))
	extra.append("atrim=end=%.3f" % tecto)
	extra.append("afade=t=out:st=%.3f:d=%.3f" % (max(0.0, tecto - FADE_FIM), FADE_FIM))
	cadeia += ";[m]" + ",".join(extra) + "[s]"

	tmp = os.path.join(INC, "_tmp_sfx.wav")
	_corre(entradas + ["-filter_complex", cadeia, "-map", "[s]",
	                   "-ac", "1", "-ar", "44100", tmp])
	if not os.path.exists(tmp):
		raise SystemExit("o ffmpeg nao produziu nada para '%s'" % nome)

	ganho = PICO_ALVO - pico(tmp)
	destino = os.path.join(SAIDA, nome + ".ogg")
	_corre(["-i", tmp, "-af", "volume=%.2fdB" % ganho,
	        "-c:a", "libvorbis", "-b:a", BITRATE, "-ac", "1", destino])
	dur = 0.0
	m = re.search(r"Duration: (\d+):(\d+):([\d.]+)", _corre(["-i", destino]))
	if m:
		dur = int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3))
	os.remove(tmp)
	return "  %-20s %5.2f s  %d camada(s)  %s" % (
		nome + ".ogg", dur, n, receita.get("nota", ""))


def lista() -> None:
	for nome, r in SONS.items():
		fontes = ", ".join(c[0] for c in r["cam"])
		print("%-20s <- %s" % (nome, fontes))


if __name__ == "__main__":
	ap = argparse.ArgumentParser(description=__doc__)
	ap.add_argument("--descarregar", action="store_true")
	ap.add_argument("--lista", action="store_true")
	ap.add_argument("--so", help="constroi so' este som")
	a = ap.parse_args()

	if a.descarregar:
		descarregar()
	elif a.lista:
		lista()
	else:
		alvos = {a.so: SONS[a.so]} if a.so else SONS
		for nome, receita in alvos.items():
			print(construir(nome, receita))
		print("\nfeito. Agora: --headless --import.")
