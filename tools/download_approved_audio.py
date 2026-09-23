"""Aquisição batch dos assets Pixabay aprovados, sem integração no jogo."""
from __future__ import annotations

import concurrent.futures
import hashlib
import re
import subprocess
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
PROMPT = Path(r"C:\Users\paulo\.codex\attachments\5390c133-b087-460e-826a-e668cd05d5ab\Texto colado.txt")
OUT = ROOT / "assets" / "audio" / "acquisition"
MANIFEST = ROOT / "docs" / "audio" / "approved_audio_manifest.md"


def urls() -> list[str]:
    text = PROMPT.read_text(encoding="utf-8")
    found = re.findall(r"https://pixabay\.com/[^\s)]+", text)
    return list(dict.fromkeys(u.rstrip("`.,") for u in found if "service/license" not in u))


def fetch(url: str) -> tuple[str, str, str]:
    # A página pública é sempre tentada primeiro; bloqueios ficam registados.
    try:
        req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urlopen(req, timeout=25) as response:
            page = response.read(2_000_000)
        if b"pixabay" not in page.lower():
            return url, "BLOCKED", "resposta sem HTML Pixabay"
        media = re.search(rb"https://cdn\.pixabay\.com/download/audio/[^\"']+", page)
        if not media:
            return url, "BLOCKED", "media URL público não exposto"
        media_url = media.group(0).decode("utf-8").replace("\\u0026", "&")
        kind = "sfx" if "/sound-effects/" in url else "music"
        target_dir = OUT / kind
        target_dir.mkdir(parents=True, exist_ok=True)
        stem = hashlib.sha1(url.encode()).hexdigest()[:12]
        target = target_dir / f"pixabay_{stem}.mp3"
        with urlopen(Request(media_url, headers={"User-Agent": "Mozilla/5.0"}), timeout=45) as response:
            data = response.read()
        if not data.startswith(b"ID3") and not data[:2] in (b"\xff\xfb", b"\xff\xf3", b"\xff\xf2"):
            return url, "BLOCKED", "download não é áudio MP3"
        target.write_bytes(data)
        probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=nw=1:nk=1", str(target)], capture_output=True, text=True)
        if probe.returncode != 0 or not probe.stdout.strip() or float(probe.stdout.strip()) <= 0:
            target.unlink(missing_ok=True)
            return url, "BLOCKED", "ffprobe rejeitou o ficheiro"
        return url, "OK", str(target.relative_to(ROOT))
    except Exception as exc:
        return url, "BLOCKED", str(exc).splitlines()[0][:180]


def main() -> int:
    all_urls = urls()
    results: list[tuple[str, str, str]] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for result in pool.map(fetch, all_urls):
            results.append(result)
            print(result[1], result[0], result[2])
    ok = [r for r in results if r[1] == "OK"]
    failed = [r for r in results if r[1] != "OK"]
    MANIFEST.write_text(
        "# Manifesto de aquisição — pacote aprovado\n\n"
        "Execução batch: todas as URLs foram tentadas; nenhum asset foi integrado no código.\n\n"
        f"Resultado: {len(ok)}/{len(results)} obtidos; {len(failed)} bloqueados.\n\n"
        "## Resultados\n\n"
        + "\n".join(f"- `{status}` — {url} — {detail}" for url, status, detail in results)
        + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
