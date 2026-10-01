"""Smoke do executavel exportado, com userdata isolada e hashes do save real."""
import hashlib
import json
import os
import subprocess
from pathlib import Path

raiz = Path(__file__).resolve().parents[1]
real = Path(os.environ['APPDATA'])/'Godot/app_userdata/Koliani'
def estado_real():
    return {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in real.glob('*')
            if p.is_file() and p.suffix in ['.json','.bak']}
antes = estado_real()
env = os.environ.copy()
sandbox = raiz/'work/shadowblade_fidelity/smoke_userdata'
sandbox.mkdir(parents=True,exist_ok=True)
env['APPDATA'] = env['LOCALAPPDATA'] = str(sandbox)
exe = raiz/'build/windows/Koliani.exe'
log = raiz/'work/shadowblade_fidelity/smoke_windows.log'
resultado = subprocess.run([str(exe),'--headless','--quit-after','120','--log-file',str(log)],
                          env=env,cwd=raiz,timeout=45,capture_output=True,
                          creationflags=subprocess.CREATE_NO_WINDOW)
assert estado_real()==antes, 'Save real alterado'
texto = log.read_text(encoding='utf-8') if log.exists() else resultado.stdout.decode(errors='replace')
assert resultado.returncode==0 and 'SCRIPT ERROR' not in texto and '\nERROR:' not in texto, texto[-4000:]
manifesto = {'base':subprocess.check_output(['git','rev-parse','HEAD'],cwd=raiz).decode().strip(),
             'candidato_local_sem_commit':bool(subprocess.check_output(['git','diff','HEAD','--','scripts','assets','project.godot'],cwd=raiz).strip()),'versao':'0.18.20','save_real_intacto':len(antes),
             'windows_sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),
             'web':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (raiz/'build/web').glob('*') if p.is_file()}}
(raiz/'work/shadowblade_fidelity/builds_manifesto.json').write_text(json.dumps(manifesto,indent=2),encoding='utf-8')
print(f'SMOKE Windows: exit 0, sem erros no log, {len(antes)} saves reais intactos; manifesto Windows/Web gravado.')
