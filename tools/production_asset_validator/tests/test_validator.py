from __future__ import annotations
import hashlib, json, tempfile, unittest
from pathlib import Path
from PIL import Image

from tools.production_asset_validator.validator import gerar_contact_sheet, validar_manifesto

HERE = Path(__file__).parent; FIX = HERE / "fixtures"

class ValidatorTests(unittest.TestCase):
    def manifest(self, folder: Path, frames: list[str], **changes) -> Path:
        data = {"character":"Synthetic", "animation":"test", "frame_count":len(frames),
                "canvas_width":32, "canvas_height":32, "pivot_x":16, "pivot_y":27,
                "baseline_y":27, "baseline_tolerance":1, "asset_type":"OTHER",
                "expected_alpha":True, "vfx_separate":True, "frames":frames}
        data.update(changes); path = folder / "manifest.json"
        path.write_text(json.dumps(data), encoding="utf-8"); return path

    def copy_fixture(self, folder: Path, name: str):
        (folder/name).write_bytes((FIX/name).read_bytes())

    def test_pass_fixture(self):
        with tempfile.TemporaryDirectory() as raw:
            d=Path(raw); self.copy_fixture(d,"valid_rgba.png")
            report=validar_manifesto(self.manifest(d,["valid_rgba.png"]))
            self.assertEqual("PASS", report["animation"]["status"])

    def test_expected_failures(self):
        expectations={"rgb_no_alpha.png":"NO_ALPHA_CHANNEL", "clipped_bottom.png":"CLIPPED_BOTTOM",
                      "wrong_canvas.png":"CANVAS_WIDTH", "baseline_bad.png":"BASELINE_OUT_OF_TOLERANCE"}
        for filename, code in expectations.items():
            with self.subTest(filename), tempfile.TemporaryDirectory() as raw:
                d=Path(raw); self.copy_fixture(d,filename)
                frame=validar_manifesto(self.manifest(d,[filename]))["frames"][0]
                self.assertEqual("FAIL", frame["status"])
                self.assertIn(code, {x["code"] for x in frame["findings"]})

    def test_inconsistent_canvas_fails(self):
        with tempfile.TemporaryDirectory() as raw:
            d=Path(raw)
            for n in ("valid_rgba.png","wrong_canvas.png"): self.copy_fixture(d,n)
            r=validar_manifesto(self.manifest(d,["valid_rgba.png","wrong_canvas.png"], canvas_width=None))
            self.assertIn("INCONSISTENT_CANVAS", {x["code"] for x in r["animation"]["findings"]})

    def test_checkerboard_requires_review(self):
        with tempfile.TemporaryDirectory() as raw:
            d=Path(raw); self.copy_fixture(d,"checkerboard.png")
            f=validar_manifesto(self.manifest(d,["checkerboard.png"]))["frames"][0]
            self.assertIn("SUSPICIOUS_CHECKERBOARD", {x["code"] for x in f["findings"]})

    def test_deterministic_and_sources_unchanged(self):
        with tempfile.TemporaryDirectory() as raw:
            d=Path(raw); self.copy_fixture(d,"valid_rgba.png"); source=d/"valid_rgba.png"
            before=hashlib.sha256(source.read_bytes()).hexdigest(); manifest=self.manifest(d,[source.name])
            one=validar_manifesto(manifest); two=validar_manifesto(manifest)
            json_one=json.dumps(one,sort_keys=True).encode(); json_two=json.dumps(two,sort_keys=True).encode()
            self.assertEqual(hashlib.sha256(json_one).hexdigest(), hashlib.sha256(json_two).hexdigest())
            self.assertEqual(before,hashlib.sha256(source.read_bytes()).hexdigest())

    def test_contact_sheet(self):
        with tempfile.TemporaryDirectory() as raw:
            d=Path(raw); self.copy_fixture(d,"valid_rgba.png")
            r=validar_manifesto(self.manifest(d,["valid_rgba.png"])); out=d/"sheet.png"
            gerar_contact_sheet(r,out)
            with Image.open(out) as im:
                self.assertEqual("PNG", im.format); self.assertGreater(im.width,32); self.assertGreater(im.height,32)

if __name__ == "__main__": unittest.main()
