#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Prepara as camas de musica do jogo a partir das fontes CC0/CC-BY.

## Porque e' que isto existe

As faixas sao tocadas **em ciclo** (`scripts/musica.gd` poe
`AudioStreamOggVorbis.loop = true`). Um corte "a bruta" com fade-out no
fim faz o pior efeito possivel: de X em X segundos a musica desaparece e
volta a entrar a todo o volume. Foi disso que o Paulo se queixou -- "a
musica do Nivel 32 e' esquisita e tem varios cortes". Medido a 4 set 2026:
8 das 20 faixas de nivel e 10 das 20 de chefe tinham fade-out a tocar em
ciclo, e 7 faixas de nivel eram curtas de mais (a do nivel 1 tinha **7,6
segundos** -- era um jingle de vitoria, nao uma cama).

Esta ferramenta constroi cada faixa de forma a que ela **feche sobre si
propria**:

  1. corta o troco util (tira fade-in / fade-out / cauda a apagar);
  2. cruza a cauda por cima da cabeca (`xfade`), para o fim ligar ao
     inicio sem salto -- excepto nas faixas que ja' vem desenhadas para
     ciclar (`xfade = 0`);
  3. iguala o volume de todas para -16 LUFS com um ganho FIXO (medido com
     o ebur128) -- um compressor mexeria nas pontas e desfazia a costura;
  4. codifica em ogg mono a 64 kbps, como o resto do jogo.

## Uso

    python tools/preparar_musica.py --descarregar   # busca as fontes
    python tools/preparar_musica.py                 # constroi tudo
    python tools/preparar_musica.py --so niveis     # so' as de nivel
    python tools/preparar_musica.py --verificar     # rede de seguranca

As fontes ficam em `assets/audio/incoming/` (ignorado pelo git -- sao
dezenas de MB de originais). O `--verificar` sai != 0 se alguma faixa
publicada violar as regras de ciclo, e serve para os testes.

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
INC = os.path.join(RAIZ, "assets", "audio", "incoming")
SAIDA_NIVEIS = os.path.join(RAIZ, "assets", "audio", "musica", "niveis")
SAIDA_CHEFES = os.path.join(RAIZ, "assets", "audio", "musica", "chefes")
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) koliani-asset-fetch"

## Regras de ciclo (usadas na construcao e no --verificar).
DUR_MINIMA = 28.0        # segundos: abaixo disto a repeticao da' nas vistas
QUEDA_MAXIMA = 5.0       # dB entre o inicio e o fim -- acima disto ouve-se o salto
LUFS_ALVO = -16.0
BITRATE = "64k"

# --------------------------------------------------------------------------
# Fontes. `zip` -> descompacta para uma pasta com o mesmo id; senao grava o
# ficheiro solto com o nome indicado. Tudo do OpenGameArt.
# --------------------------------------------------------------------------
FONTES = {
	"ofdn": {
		"url": "https://opengameart.org/sites/default/files/of_far_different_nature_-_loop_box_3_cc-by_-_ogg_files_1.zip",
		"zip": True,
		"pagina": "https://opengameart.org/content/essentials-pack-for-fantasy-games-loop-box-3-orchestral-soundtracks-for-rpgs-and-adventures",
		"licenca": "CC-BY 4.0 -- Of Far Different Nature",
	},
	"ehlers": {
		"url": "https://opengameart.org/sites/default/files/Alexander%20Ehlers%20-%20Free%20Music%20Pack.zip",
		"zip": True,
		"pagina": "https://opengameart.org/content/free-music-pack",
		"licenca": "CC0 -- Alexander Ehlers",
	},
	"jrpg5": {
		"url": "https://opengameart.org/sites/default/files/JRPG%20Music%20Pack%20%235%20%5BAction%5D%20by%20Juhani%20Junkala.zip",
		"zip": True,
		"pagina": "https://opengameart.org/content/jrpg-pack-5-action",
		"licenca": "CC0 -- Juhani Junkala",
	},
	"marcelo": {
		"url": "https://opengameart.org/sites/default/files/Action%20Music%20Pack%20%5Bwww.marcelofernandezmusic.com%5D.zip",
		"zip": True,
		"pagina": "https://opengameart.org/content/action-music-pack",
		"licenca": "CC-BY 3.0 -- marcelofg55",
	},
	# --- rock/metal CC0 do autor `nene` (4 set 2026, pedido do Paulo) ------
	# Varias vem em `_loop.wav`: ja' estao desenhadas para ciclar, por isso
	# entram com `xfade = 0` e sem corte.
	"nene_unchained": {"url": "https://opengameart.org/sites/default/files/unchained_destiny_loop.wav",
		"nome": "unchained_destiny_loop.wav",
		"pagina": "https://opengameart.org/content/unchained-destiny-rock", "licenca": "CC0 -- nene"},
	"nene_futuro": {"url": "https://opengameart.org/sites/default/files/fight_for_better_future.wav",
		"nome": "fight_for_better_future.wav",
		"pagina": "https://opengameart.org/content/fight-for-better-future-rockmetal", "licenca": "CC0 -- nene"},
	"nene_bb8": {"url": "https://opengameart.org/sites/default/files/boss_battle_8_metal_loop.wav",
		"nome": "boss_battle_8_metal_loop.wav",
		"pagina": "https://opengameart.org/content/boss-battle-8-metal", "licenca": "CC0 -- nene"},
	"nene_bb9": {"url": "https://opengameart.org/sites/default/files/boss_battle_9_metal_loop.wav",
		"nome": "boss_battle_9_metal_loop.wav",
		"pagina": "https://opengameart.org/content/boss-battle-9-metal", "licenca": "CC0 -- nene"},
	"nene_once": {"url": "https://opengameart.org/sites/default/files/once_more_metal.wav",
		"nome": "once_more_metal.wav",
		"pagina": "https://opengameart.org/content/once-more-metal", "licenca": "CC0 -- nene"},
	"nene_bb10": {"url": "https://opengameart.org/sites/default/files/boss_battle_10_metal.wav",
		"nome": "boss_battle_10_metal.wav",
		"pagina": "https://opengameart.org/content/boss-battle-10-metal", "licenca": "CC0 -- nene"},
	"nene_short": {"url": "https://opengameart.org/sites/default/files/Short%20Theme%20V2.wav",
		"nome": "short_theme_v2.wav",
		"pagina": "https://opengameart.org/content/short-theme-rockmetal", "licenca": "CC0 -- nene"},
	"nene_bb2": {"url": "https://opengameart.org/sites/default/files/boss_battle_%232_metal_pack.zip",
		"zip": True,
		"pagina": "https://opengameart.org/content/boss-battle-2-symphonic-metal", "licenca": "CC0 -- nene"},
	# --- fontes soltas das faixas de chefe que ja' la' estavam ------------
	"battle_a": {"url": "https://opengameart.org/sites/default/files/battleThemeA.mp3",
		"nome": "battleThemeA.mp3",
		"pagina": "https://opengameart.org/content/battle-theme-a", "licenca": "CC0 -- cynicmusic"},
	"battle_b": {"url": "https://opengameart.org/sites/default/files/battleThemeB.mp3",
		"nome": "battleThemeB.mp3",
		"pagina": "https://opengameart.org/content/battle-theme-b-for-rpg", "licenca": "CC0 -- cynicmusic"},
	"fast_fight": {"url": "https://opengameart.org/sites/default/files/fight.ogg",
		"nome": "fight.ogg",
		"pagina": "https://opengameart.org/content/fast-fight-battle-music", "licenca": "CC0 -- bonsaiheldin"},
	"gods_forbid": {"url": "https://opengameart.org/sites/default/files/heavens_forbid_0.ogg",
		"nome": "heavens_forbid.ogg",
		"pagina": "https://opengameart.org/content/gods-forbid", "licenca": "CC0 -- centurionofwar"},
	"light_battle": {"url": "https://opengameart.org/sites/default/files/Light%20battle_1.ogg",
		"nome": "light_battle.ogg",
		"pagina": "https://opengameart.org/content/light-battle-theme", "licenca": "CC-BY 4.0 -- Alexandr Zhelanov"},
	"wasteland": {"url": "https://opengameart.org/sites/default/files/Wasteland%20Showdown_0.mp3",
		"nome": "wasteland_showdown.mp3",
		"pagina": "https://opengameart.org/content/wasteland-showdown-battle-music", "licenca": "CC-BY 3.0 -- matthew-pablo"},
	"rise_spirit": {"url": "https://opengameart.org/sites/default/files/Rise%20of%20spirit.ogg",
		"nome": "rise_of_spirit.ogg",
		"pagina": "https://opengameart.org/content/rise-of-spirit", "licenca": "CC-BY 3.0 -- Alexandr Zhelanov"},
	"nene_reprise": {"url": "https://opengameart.org/sites/default/files/hero_reprise.ogg",
		"nome": "hero_reprise.ogg",
		"pagina": "https://opengameart.org/content/heros-reprise", "licenca": "CC0 -- nene"},
	"coracao_maquina": {"url": "https://opengameart.org/sites/default/files/Heart%20of%20Machine.ogg",
		"nome": "heart_of_machine.ogg",
		"pagina": "https://opengameart.org/content/heart-of-machine", "licenca": "CC-BY 3.0 -- Alexandr Zhelanov"},
	"vilified": {"url": "https://opengameart.org/sites/default/files/Vilified%20%282012%29_0.mp3",
		"nome": "vilified.mp3",
		"pagina": "https://opengameart.org/content/vilified", "licenca": "CC-BY 3.0 -- matthew-pablo"},
	"nossa_batalha": {"url": "https://opengameart.org/sites/default/files/It%27s%20our%20battle.ogg",
		"nome": "its_our_battle.ogg",
		"pagina": "https://opengameart.org/content/its-our-battle", "licenca": "CC-BY 3.0 -- Alexandr Zhelanov"},
}

_OFDN = "ofdn/Of Far Different Nature - %s (CC-BY).ogg"
_EHL = "ehlers/Alexander Ehlers - Free Music Pack/Alexander Ehlers - %s.mp3"
_MAR = "marcelo/Action Music Pack [www.marcelofernandezmusic.com]/%s.ogg"

# --------------------------------------------------------------------------
# As 20 camas de NIVEL. `Musica.ambiente()` escolhe por `indice_nivel % 20`,
# por isso a linha N serve os niveis N, N+20, N+40, N+60 e N+80.
#
#   xfade = 0  -> a faixa ja' vem desenhada para ciclar (nao lhe tocar)
#   xfade > 0  -> segundos de cruzamento da cauda por cima da cabeca
#   max        -> comprimento maximo (so' se aplica quando ha' xfade)
#
# Historico das trocas de 4 set 2026 (pedido do Paulo + defeitos medidos):
#   01,02,03,04,05,06,07,17 -- eram jingles/trocos de 8 a 24 s a repetir
#   12 -- "a musica do Nivel 32 e' esquisita e tem varios cortes" (era o
#         `Zwischenwelt`, que tem fim proprio e desaparecia a cada volta)
#   11 -- ganhou metal para partir a fila de faixas orquestrais
#   18 -- FICA (e' a que ele adorou, no nivel 38); so' se lhe tirou o fade
# --------------------------------------------------------------------------
NIVEIS = [
	{"f": "nene_unchained", "a": "unchained_destiny_loop.wav", "xfade": 0,
	 "nota": "Unchained Destiny [Rock] -- nene, CC0"},
	{"f": "nene_futuro", "a": "fight_for_better_future.wav", "xfade": 2.0,
	 "nota": "Fight for Better Future [Rock/Metal] -- nene, CC0"},
	{"f": "ofdn", "a": _OFDN % "Adventure Begins", "xfade": 0,
	 "nota": "Adventure Begins -- Of Far Different Nature"},
	{"f": "nene_bb9", "a": "boss_battle_9_metal_loop.wav", "xfade": 0,
	 "nota": "Boss Battle #9 [Metal] -- nene, CC0"},
	{"f": "ehlers", "a": _EHL % "Doomed", "xfade": 2.5, "max": 90.0,
	 "nota": "Doomed -- Alexander Ehlers"},
	{"f": "ehlers", "a": _EHL % "Twists", "xfade": 2.5, "max": 90.0,
	 "nota": "Twists -- Alexander Ehlers"},
	{"f": "ehlers", "a": _EHL % "Warped", "xfade": 2.5, "max": 90.0,
	 "nota": "Warped -- Alexander Ehlers"},
	{"f": "ofdn", "a": _OFDN % "Horny [v2]", "xfade": 0,
	 "nota": "Horny [v2] -- Of Far Different Nature"},
	{"f": "ofdn", "a": _OFDN % "Pavane", "xfade": 0,
	 "nota": "Pavane -- Of Far Different Nature"},
	{"f": "ofdn", "a": _OFDN % "Eastern Treasures", "xfade": 2.0,
	 "nota": "Eastern Treasures -- Of Far Different Nature (tinha fade-in)"},
	{"f": "nene_bb8", "a": "boss_battle_8_metal_loop.wav", "xfade": 0,
	 "nota": "Boss Battle #8 [Metal] -- nene, CC0"},
	{"f": "nene_once", "a": "once_more_metal.wav", "xfade": 2.0,
	 "nota": "Once More [Metal] -- nene, CC0 (NIVEL 32: troca pedida pelo Paulo)"},
	{"f": "ofdn", "a": _OFDN % "Epic Departure [v2]", "xfade": 0,
	 "nota": "Epic Departure [v2] -- Of Far Different Nature"},
	{"f": "ofdn", "a": _OFDN % "Flow", "xfade": 0,
	 "nota": "Flow -- Of Far Different Nature"},
	{"f": "ofdn", "a": _OFDN % "Throne Room [v2]", "xfade": 0,
	 "nota": "Throne Room [v2] -- Of Far Different Nature"},
	{"f": "ofdn", "a": _OFDN % "In Darkness [v2]", "xfade": 0,
	 "nota": "In Darkness [v2] -- Of Far Different Nature"},
	{"f": "ehlers", "a": _EHL % "Flags", "xfade": 2.5, "max": 90.0,
	 "nota": "Flags -- Alexander Ehlers"},
	{"f": "ehlers", "a": _EHL % "Waking the devil", "xfade": 2.5, "max": 90.0,
	 "nota": "Waking the devil -- Alexander Ehlers (NIVEL 38: a preferida do Paulo)"},
	{"f": "ehlers", "a": _EHL % "Great mission", "xfade": 2.5, "max": 90.0,
	 "nota": "Great mission -- Alexander Ehlers"},
	{"f": "ehlers", "a": _EHL % "Spacetime", "xfade": 2.5, "max": 90.0,
	 "nota": "Spacetime -- Alexander Ehlers"},
]

# --------------------------------------------------------------------------
# As 20 camas de CHEFE. Mesma escolha por `indice_nivel % 20`, para o chefe
# de cada nivel ter sempre a mesma faixa.
#
# As linhas 09-13 eram os mesmos cinco temas do marcelofg55 das linhas
# 04-08, so' que na versao completa (com fim, e portanto com fade). Passam
# a ser cinco temas DISTINTOS -- quatro deles metal CC0 do `nene`.
# --------------------------------------------------------------------------
CHEFES = [
	{"f": "jrpg5", "a": "jrpg5/Action3 - Preparing For Battle.ogg", "xfade": 2.0, "max": 105.0,
	 "nota": "Preparing For Battle -- Juhani Junkala"},
	{"f": "jrpg5", "a": "jrpg5/Action1 - Encounter With The Witches.ogg", "xfade": 2.0, "max": 105.0,
	 "nota": "Encounter With The Witches -- Juhani Junkala"},
	{"f": "jrpg5", "a": "jrpg5/Action2 - Army Approaching.ogg", "xfade": 2.0, "max": 105.0,
	 "nota": "Army Approaching -- Juhani Junkala"},
	{"f": "marcelo", "a": _MAR % "Lethal Injection Loop", "xfade": 0, "max": 110.0,
	 "nota": "Lethal Injection (Loop) -- marcelofg55"},
	{"f": "marcelo", "a": _MAR % "Battle of the Void Loop", "xfade": 0, "max": 110.0,
	 "nota": "Battle of the Void (Loop) -- marcelofg55"},
	{"f": "marcelo", "a": _MAR % "Flaming Soul Loop", "xfade": 0, "max": 110.0,
	 "nota": "Flaming Soul (Loop) -- marcelofg55"},
	{"f": "marcelo", "a": _MAR % "Black Rock Loop", "xfade": 0, "max": 110.0,
	 "nota": "Black Rock (Loop) -- marcelofg55"},
	{"f": "marcelo", "a": _MAR % "Desolation Loop", "xfade": 0, "max": 110.0,
	 "nota": "Desolation (Loop) -- marcelofg55"},
	# os primeiros 9 s sao uma introducao baixinha; num ciclo isso da' um
	# degrau de 11 dB de cada volta -- entra a partir do sitio onde a faixa
	# ja' esta' a tocar a serio.
	{"f": "nene_bb2", "a": "nene_bb2/boss_battle_#2_metal_loop.wav", "ini": 9.0,
	 "nota": "Boss Battle #2 [Symphonic Metal] -- nene, CC0"},
	{"f": "nene_bb10", "a": "boss_battle_10_metal.wav", "xfade": 2.0, "max": 105.0,
	 "nota": "Boss Battle 10 [Metal] -- nene, CC0"},
	{"f": "nene_short", "a": "short_theme_v2.wav", "xfade": 2.0, "max": 105.0,
	 "nota": "Short Theme [Rock/Metal] V2 -- nene, CC0"},
	{"f": "coracao_maquina", "a": "heart_of_machine.ogg", "xfade": 2.0, "max": 105.0,
	 "nota": "Heart of Machine -- Alexandr Zhelanov"},
	{"f": "nossa_batalha", "a": "its_our_battle.ogg", "xfade": 2.0, "max": 105.0,
	 "nota": "It's Our Battle -- Alexandr Zhelanov"},
	{"f": "battle_a", "a": "battleThemeA.mp3", "xfade": 2.0, "max": 105.0,
	 "nota": "Battle Theme A -- cynicmusic"},
	{"f": "battle_b", "a": "battleThemeB.mp3", "xfade": 2.0, "max": 105.0,
	 "nota": "Battle Theme B -- cynicmusic"},
	{"f": "vilified", "a": "vilified.mp3", "xfade": 2.0, "max": 105.0,
	 "nota": "Vilified -- matthew-pablo"},
	{"f": "gods_forbid", "a": "heavens_forbid.ogg", "xfade": 2.0, "max": 105.0,
	 "nota": "Gods Forbid -- centurionofwar"},
	{"f": "light_battle", "a": "light_battle.ogg", "xfade": 2.0, "max": 105.0,
	 "nota": "Light battle theme -- Alexandr Zhelanov"},
	{"f": "wasteland", "a": "wasteland_showdown.mp3", "xfade": 2.0, "max": 105.0,
	 "nota": "Wasteland Showdown -- matthew-pablo"},
	{"f": "rise_spirit", "a": "rise_of_spirit.ogg", "xfade": 2.0, "max": 105.0,
	 "nota": "Rise of spirit -- Alexandr Zhelanov"},
]


def _ffmpeg() -> str:
	try:
		import imageio_ffmpeg
		return imageio_ffmpeg.get_ffmpeg_exe()
	except ImportError:
		if shutil.which("ffmpeg"):
			return "ffmpeg"
		sys.exit("preciso do ffmpeg: pip install --user imageio-ffmpeg")


FF = None


def _corre(args: list[str]) -> str:
	global FF
	if FF is None:
		FF = _ffmpeg()
	r = subprocess.run([FF, "-y", "-nostdin"] + args, capture_output=True, text=True)
	return r.stderr


def duracao(caminho: str) -> float:
	m = re.search(r"Duration: (\d+):(\d+):([\d.]+)", _corre(["-i", caminho]))
	if not m:
		raise RuntimeError("nao consigo ler a duracao de %s" % caminho)
	return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3))


def lufs(caminho: str) -> float:
	"""Volume integrado (LUFS) pelo ebur128 -- para igualar as faixas todas."""
	for linha in _corre(["-i", caminho, "-af", "ebur128=framelog=quiet",
	                     "-f", "null", "-"]).splitlines():
		s = linha.strip()
		if s.startswith("I:") and "LUFS" in s:
			return float(s.split()[1])
	return LUFS_ALVO


def envelope(caminho: str, janela: float = 0.25) -> list[float]:
	"""RMS por janela de `janela` segundos (mono, 8 kHz) -- barato e chega
	para saber onde e' que a musica comeca e acaba de facto."""
	import struct
	sr = 8000
	bruto = subprocess.run(
		[FF or _ffmpeg(), "-v", "quiet", "-i", caminho, "-ac", "1", "-ar", str(sr),
		 "-f", "s16le", "-"], stdout=subprocess.PIPE, check=True).stdout
	n = len(bruto) // 2
	amostras = struct.unpack("<%dh" % n, bruto[:n * 2])
	passo = int(sr * janela)
	saida = []
	for i in range(0, n - passo, passo):
		s = 0
		for v in amostras[i:i + passo]:
			s += v * v
		saida.append((s / passo) ** 0.5 / 32768.0)
	return saida


def troco_util(caminho: str, janela: float = 0.25) -> tuple[float, float]:
	"""Onde e' que a faixa esta' 'a todo o volume': corta fade-in e fade-out.

	Devolve (inicio, fim) em segundos. O criterio e' -6 dB face 'a mediana
	das janelas com som -- e' o que apanha um fade sem comer musica boa.
	"""
	env = envelope(caminho, janela)
	if not env:
		return 0.0, duracao(caminho)
	vivos = sorted(v for v in env if v > max(env) * 0.05)
	if not vivos:
		return 0.0, duracao(caminho)
	limiar = vivos[len(vivos) // 2] * 0.5  # -6 dB da mediana
	i = 0
	while i < len(env) and env[i] < limiar:
		i += 1
	j = len(env) - 1
	while j > i and env[j] < limiar:
		j -= 1
	return i * janela, (j + 1) * janela


def _url(u: str) -> bytes:
	req = urllib.request.Request(u, headers={"User-Agent": UA})
	return urllib.request.urlopen(req, timeout=300).read()


def descarregar(so: list[str] | None = None) -> None:
	os.makedirs(INC, exist_ok=True)
	for fid, f in FONTES.items():
		if so and fid not in so:
			continue
		if f.get("zip"):
			destino = os.path.join(INC, fid)
			if os.path.isdir(destino) and os.listdir(destino):
				print("  ja' tenho  %s/" % fid)
				continue
			print("  a buscar   %s ..." % fid, flush=True)
			zipfile.ZipFile(io.BytesIO(_url(f["url"]))).extractall(destino)
		else:
			destino = os.path.join(INC, f["nome"])
			if os.path.exists(destino):
				print("  ja' tenho  %s" % f["nome"])
				continue
			print("  a buscar   %s ..." % f["nome"], flush=True)
			with open(destino, "wb") as fh:
				fh.write(_url(f["url"]))
	print("fontes em %s" % INC)


def construir(entrada: dict, destino: str) -> dict:
	"""Constroi UMA cama a partir da sua fonte. Devolve a ficha do que fez."""
	origem = os.path.join(INC, entrada["a"].replace("/", os.sep))
	if not os.path.exists(origem):
		raise SystemExit("falta a fonte %s -- corre --descarregar" % origem)

	xf = float(entrada.get("xfade", 2.0))
	ini, fim = troco_util(origem)
	if "ini" in entrada:
		# corte 'a mao, para quando a faixa tem uma introducao musical
		# baixinha que o automatico nao apanha (nao e' um fade, e' musica)
		ini, xf = float(entrada["ini"]), max(xf, 2.0)
		fim = duracao(origem)
	elif xf <= 0:
		# faixa desenhada para ciclar: nao lhe mexemos nas pontas, so'
		# tiramos o silencio digital que alguns .wav trazem 'a cabeca.
		ini = min(ini, 0.5)
		fim = duracao(origem)
	if "max" in entrada and fim - ini > entrada["max"]:
		fim = ini + entrada["max"]
		# se o tecto partiu um ciclo desenhado, ha' que voltar a fecha-lo
		if xf <= 0:
			xf = 2.0

	tmp = os.path.join(INC, "_tmp_corte.wav")
	_corre(["-ss", "%.3f" % ini, "-to", "%.3f" % fim, "-i", origem,
	        "-ac", "1", "-ar", "44100", tmp])
	corpo = duracao(tmp)

	if xf > 0 and corpo > xf * 3:
		_cruzar_ciclo(tmp, xf)

	# ganho estatico (nao dinamico: um compressor mexeria nas pontas e
	# estragava a costura que acabamos de fazer)
	ganho = LUFS_ALVO - lufs(tmp)
	_corre(["-i", tmp, "-af", "volume=%.2fdB" % ganho,
	        "-c:a", "libvorbis", "-b:a", BITRATE, "-ac", "1", destino])
	os.remove(tmp)
	return {"dur": duracao(destino), "corte": (ini, fim), "ganho": ganho,
	        "xfade": xf, "nota": entrada["nota"]}


def _cruzar_ciclo(wav: str, segundos: float) -> None:
	"""Faz o ficheiro FECHAR SOBRE SI PROPRIO, no proprio ficheiro.

	Dado o corpo B com N amostras e uma janela de X amostras, escreve

	    S[i] = B[i]*(i/X) + B[N-X+i]*(1 - i/X)    para i < X
	    S[i] = B[i]                               para X <= i < N-X

	O resultado tem N-X amostras e, ao repetir, a ultima amostra (B[N-X-1])
	e' seguida de S[0] = B[N-X] -- ou seja, a musica continua como se nao
	tivesse dado a volta. A conta e' feita aqui em vez de com o `acrossfade`
	do ffmpeg porque esse, quando a cauda tem exactamente a duracao do
	cruzamento, ha' faixas em que nao devolve nada (visto no boss_03).
	"""
	import array
	import wave

	with wave.open(wav, "rb") as f:
		canais, largura, taxa, n = f.getnchannels(), f.getsampwidth(), f.getframerate(), f.getnframes()
		bruto = f.readframes(n)
	assert canais == 1 and largura == 2, "esperava mono 16 bits"

	b = array.array("h")
	b.frombytes(bruto)
	x = int(segundos * taxa)
	if len(b) <= x * 3:
		return

	saida = array.array("h", b[:len(b) - x])
	for i in range(x):
		p = i / x
		v = int(b[i] * p + b[len(b) - x + i] * (1.0 - p))
		saida[i] = max(-32768, min(32767, v))

	with wave.open(wav, "wb") as f:
		f.setnchannels(1)
		f.setsampwidth(2)
		f.setframerate(taxa)
		f.writeframes(saida.tobytes())


def _pontas_db(caminho: str) -> tuple[float, float]:
	"""Volume medio dos primeiros e dos ultimos 1,5 s -- e' o que se ouve
	na costura do ciclo."""
	d = duracao(caminho)
	saida = []
	for ss in (0.0, max(0.0, d - 1.5)):
		v = -99.0
		for linha in _corre(["-ss", "%.3f" % ss, "-t", "1.5", "-i", caminho,
		                     "-af", "volumedetect", "-f", "null", "-"]).splitlines():
			m = re.search(r"mean_volume: ([-\d.]+) dB", linha)
			if m:
				v = float(m.group(1))
		saida.append(v)
	return saida[0], saida[1]


def verificar() -> int:
	"""Rede de seguranca: nenhuma cama pode ser curta de mais nem ter um
	salto audivel entre o fim e o inicio (elas tocam SEMPRE em ciclo)."""
	maus = 0
	for pasta, quantos, molde in ((SAIDA_NIVEIS, len(NIVEIS), "nivel_%02d.ogg"),
	                              (SAIDA_CHEFES, len(CHEFES), "boss_%02d.ogg")):
		for i in range(1, quantos + 1):
			p = os.path.join(pasta, molde % i)
			if not os.path.exists(p):
				print("FALTA   %s" % molde % i)
				maus += 1
				continue
			d = duracao(p)
			a, b = _pontas_db(p)
			erros = []
			if d < DUR_MINIMA:
				erros.append("curta (%.1f s < %.0f)" % (d, DUR_MINIMA))
			if abs(a - b) > QUEDA_MAXIMA:
				erros.append("salto de %.1f dB na costura" % (a - b))
			if erros:
				print("MAU     %-14s %s" % (molde % i, "; ".join(erros)))
				maus += 1
			else:
				print("ok      %-14s %5.1f s  pontas %6.1f /%6.1f dB"
				      % (molde % i, d, a, b))
	if maus:
		print("\n%d faixa(s) fora das regras de ciclo." % maus)
	else:
		print("\ntodas as camas fecham sobre si proprias.")
	return 1 if maus else 0


def _construir_lista(tabela: list[dict], pasta: str, molde: str) -> None:
	os.makedirs(pasta, exist_ok=True)
	for i, e in enumerate(tabela, 1):
		destino = os.path.join(pasta, molde % i)
		f = construir(e, destino)
		print("  %-14s %5.1f s  corte %5.1f-%5.1f  ganho %+5.1f dB  %s"
		      % (molde % i, f["dur"], f["corte"][0], f["corte"][1],
		         f["ganho"], f["nota"]))


if __name__ == "__main__":
	ap = argparse.ArgumentParser(description=__doc__)
	ap.add_argument("--descarregar", action="store_true",
	                help="busca as fontes para assets/audio/incoming/")
	ap.add_argument("--verificar", action="store_true",
	                help="confere as camas ja' publicadas (sai != 0 se houver mas)")
	ap.add_argument("--so", choices=["niveis", "chefes"],
	                help="constroi so' um dos conjuntos")
	a = ap.parse_args()

	if a.descarregar:
		descarregar()
	elif a.verificar:
		sys.exit(verificar())
	else:
		if a.so in (None, "niveis"):
			print("== camas de nivel ==")
			_construir_lista(NIVEIS, SAIDA_NIVEIS, "nivel_%02d.ogg")
		if a.so in (None, "chefes"):
			print("== camas de chefe ==")
			_construir_lista(CHEFES, SAIDA_CHEFES, "boss_%02d.ogg")
		print("\nfeito. Agora: --headless --import, e depois --verificar.")
