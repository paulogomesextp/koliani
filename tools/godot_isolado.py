#!/usr/bin/env python3
r"""Corre o Godot com o `user://` isolado num sandbox descartavel.

E' A UNICA estrategia de isolamento de save do projecto: todo o script de
QA/teste/bot que arranque o Godot passa por aqui.

    python tools/godot_isolado.py [--manter] [--sandbox DIR] -- <argumentos do Godot>

  --sandbox DIR reutiliza (e nunca apaga) essa pasta: serve a QA de
  persistencia entre PROCESSOS, onde varias corridas partilham o mesmo user://.

PORQUE E' QUE EXISTE (bug encontrado na auditoria global)
  Os `.sh` isolavam com `XDG_DATA_HOME`. E' a variavel do LINUX; no Windows o
  Godot resolve `user://` por `%APPDATA%Godot\app_userdata\Koliani` e
  ignora o XDG por completo -- o "isolamento" era um no-op e a suite/bots
  escreviam no save real. Provado: com XDG_DATA_HOME=/tmp/x o Godot continuava
  a devolver C:/Users/<u>/AppData/Roaming/Godot/app_userdata/Koliani.

O QUE FAZ
  1. sonda o `user://` REAL (env intacto) e guarda o SHA256 de todos os
     `*.json`/`*.bak` do save real;
  2. cria um sandbox novo por execucao e aponta a variavel certa do SO
     (Windows: APPDATA/LOCALAPPDATA; Linux: XDG_DATA_HOME; macOS: HOME);
  3. FAIL-FAST: sonda outra vez e recusa correr se o `user://` nao caiu
     dentro do sandbox (codigo 97);
  4. corre o comando; no fim confirma que o save real tem o mesmo SHA
     (codigo 98 se mudou) e apaga o sandbox (com --manter, deixa-o).
Codigos: os do Godot; 96 = uso errado; 97 = isolamento impossivel;
98 = save real alterado.
"""
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import uuid

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT_WIN = r"C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64_console.exe"


def godot_exe() -> str:
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    return GODOT_WIN if sys.platform == "win32" and os.path.exists(GODOT_WIN) else "godot"


def env_sandbox(base: str, sandbox: str) -> dict:
    env = dict(base)
    if sys.platform == "win32":
        env["APPDATA"] = sandbox
        env["LOCALAPPDATA"] = sandbox
    elif sys.platform == "darwin":
        env["HOME"] = sandbox
    else:
        env["XDG_DATA_HOME"] = sandbox
    return env


def sondar(env: dict) -> str:
    p = subprocess.run([godot_exe(), "--headless", "--path", RAIZ, "--script",
                        "res://tools/probe_user_dir.gd"], env=env, cwd=RAIZ,
                       capture_output=True, text=True, errors="replace", timeout=120)
    for ln in (p.stdout + p.stderr).splitlines():
        if ln.startswith("KOLIANI_UDIR="):
            return os.path.normcase(os.path.abspath(ln.split("=", 1)[1].strip()))
    return ""


def hashes(pasta: str) -> dict:
    r = {}
    if pasta and os.path.isdir(pasta):
        for n in sorted(os.listdir(pasta)):
            if n.endswith((".json", ".bak", ".cfg")):
                with open(os.path.join(pasta, n), "rb") as f:
                    r[n] = hashlib.sha256(f.read()).hexdigest()
    return r


def main() -> int:
    args = sys.argv[1:]
    if "--" not in args:
        print(__doc__)
        return 96
    opts = args[:args.index("--")]
    cmd = args[args.index("--") + 1:]
    manter = "--manter" in opts
    fixo = opts[opts.index("--sandbox") + 1] if "--sandbox" in opts else None
    if not cmd:
        return 96

    real = sondar(os.environ)
    if not real:
        print("ISOLAMENTO IMPOSSIVEL: nao consegui sondar o user:// real", file=sys.stderr)
        return 97
    antes = hashes(real)

    sandbox = fixo or os.path.join(tempfile.gettempdir(), "koliani_iso_" + uuid.uuid4().hex[:8])
    manter = manter or bool(fixo)
    os.makedirs(sandbox, exist_ok=True)
    env = env_sandbox(os.environ, sandbox)
    dentro = sondar(env)
    if not dentro or not dentro.startswith(os.path.normcase(os.path.abspath(sandbox))) or dentro == real:
        print(f"ISOLAMENTO IMPOSSIVEL: user:// = {dentro!r} nao esta' dentro de {sandbox}",
              file=sys.stderr)
        shutil.rmtree(sandbox, ignore_errors=True)
        return 97

    print(f"[isolado] real={real}\n[isolado] sandbox user://={dentro}", flush=True)
    try:
        codigo = subprocess.run([godot_exe()] + cmd, env=env, cwd=RAIZ).returncode
    finally:
        depois = hashes(real)
    if antes != depois:
        print(f"ERRO: save real ALTERADO (antes={antes} depois={depois})", file=sys.stderr)
        codigo = 98
    else:
        print(f"[isolado] save real intacto ({len(antes)} ficheiros verificados)", flush=True)
    if manter:
        print(f"[isolado] sandbox mantido: {sandbox}")
    else:
        shutil.rmtree(sandbox, ignore_errors=True)
    return codigo


if __name__ == "__main__":
    sys.exit(main())
