#!/usr/bin/env python3
"""Servidor local para a PROVA DO WEB (Execution 9H.1).

    python tools/servidor_prova_web.py <pasta_do_build> <pasta_de_saida> [porta]

Serve o export Web e aceita `POST /prova/<nome>` com o corpo em base64 (ou
binario), gravando-o em `<pasta_de_saida>/<nome>`. E' assim que as capturas
feitas DENTRO do browser real saem de la' para o pacote de revisao -- sem
isto, a prova do Web fica so' no ecra de quem a viu.

Tambem manda os cabecalhos de isolamento cruzado (COOP/COEP), que o Godot
pede quando o export os espera.
"""
from __future__ import annotations

import base64
import os
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

SAIDA = os.getcwd()


class Manipulador(SimpleHTTPRequestHandler):
	def end_headers(self):
		self.send_header("Cross-Origin-Opener-Policy", "same-origin")
		self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
		self.send_header("Cache-Control", "no-store")
		super().end_headers()

	def do_POST(self):
		if not self.path.startswith("/prova/"):
			self.send_error(404)
			return
		nome = os.path.basename(self.path[len("/prova/"):]) or "prova.bin"
		n = int(self.headers.get("Content-Length", "0"))
		corpo = self.rfile.read(n)
		if corpo[:5] == b"data:":
			corpo = corpo.split(b",", 1)[1]
		try:
			dados = base64.b64decode(corpo, validate=False)
		except Exception:
			dados = corpo
		os.makedirs(SAIDA, exist_ok=True)
		caminho = os.path.join(SAIDA, nome)
		with open(caminho, "wb") as f:
			f.write(dados)
		print("PROVA WEB gravada: %s (%d bytes)" % (caminho, len(dados)), flush=True)
		self.send_response(200)
		self.send_header("Content-Type", "text/plain")
		self.end_headers()
		self.wfile.write(b"ok")

	def log_message(self, fmt, *args):
		if "POST" in (args[0] if args else ""):
			super().log_message(fmt, *args)


def main(argv):
	global SAIDA
	raiz = argv[1] if len(argv) > 1 else "."
	SAIDA = os.path.abspath(argv[2]) if len(argv) > 2 else os.getcwd()
	porta = int(argv[3]) if len(argv) > 3 else 8777
	os.makedirs(SAIDA, exist_ok=True)
	os.chdir(raiz)
	srv = ThreadingHTTPServer(("127.0.0.1", porta), Manipulador)
	print("a servir %s em http://127.0.0.1:%d  (provas -> %s)"
		% (os.path.abspath(raiz), porta, SAIDA), flush=True)
	srv.serve_forever()


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
