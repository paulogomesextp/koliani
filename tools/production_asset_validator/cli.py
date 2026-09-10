"""CLI do Production Asset Validator v2."""
from __future__ import annotations
import argparse, json
from pathlib import Path
from .validator import gerar_contact_sheet, markdown, validar_manifesto

def main() -> int:
    p = argparse.ArgumentParser(description="Valida PNGs sem modificar as fontes.")
    p.add_argument("manifest", type=Path); p.add_argument("--json", type=Path, required=True)
    p.add_argument("--markdown", type=Path, required=True); p.add_argument("--contact-sheet", type=Path)
    p.add_argument("--scale", type=int, default=1, help="Escala inteira NEAREST do contact sheet; padrão preserva 1:1.")
    args = p.parse_args(); report = validar_manifesto(args.manifest.resolve())
    args.json.parent.mkdir(parents=True, exist_ok=True); args.markdown.parent.mkdir(parents=True, exist_ok=True)
    args.json.write_text(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True)+"\n", encoding="utf-8")
    args.markdown.write_text(markdown(report), encoding="utf-8")
    if args.contact_sheet: gerar_contact_sheet(report, args.contact_sheet, escala=args.scale)
    print(f"{report['animation']['status']}: {len(report['frames'])} frames")
    return 1 if report["animation"]["status"] == "FAIL" else 0

if __name__ == "__main__": raise SystemExit(main())
