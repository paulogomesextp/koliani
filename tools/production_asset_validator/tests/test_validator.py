from __future__ import annotations
import hashlib, json, tempfile, unittest
from pathlib import Path
from PIL import Image, ImageDraw

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

    # --- Execution 9B.3: regressões das duas heurísticas corrigidas ---

    def _sprite(self, folder: Path, name: str, rects, bg=(0, 0, 0, 0), size=(64, 64)):
        im = Image.new("RGBA", size, bg); d = ImageDraw.Draw(im)
        for r in rects:
            d.rectangle(r, fill=(170, 40, 190, 255))
        im.save(folder / name); return im

    def test_transparent_rgb_garbage_is_not_checkerboard(self):
        with tempfile.TemporaryDirectory() as raw:
            d = Path(raw)
            # exterior alpha 0 com xadrez de lixo no RGB + figura opaca pequena
            im = Image.new("RGBA", (64, 64)); px = im.load()
            for y in range(64):
                for x in range(64):
                    px[x, y] = (255, 255, 255, 0) if (x // 4 + y // 4) % 2 else (190, 190, 190, 0)
            ImageDraw.Draw(im).rectangle((28, 30, 36, 58), fill=(170, 40, 190, 255))
            im.save(d / "garbage.png")
            self._sprite(d, "sparse.png", [(28, 30, 36, 58)])  # exterior (0,0,0,0) uniforme
            for nome in ("garbage.png", "sparse.png"):
                with self.subTest(nome):
                    f = validar_manifesto(self.manifest(d, [nome], canvas_width=64, canvas_height=64,
                                                        pivot_x=32, pivot_y=59, baseline_y=58))["frames"][0]
                    self.assertNotIn("SUSPICIOUS_CHECKERBOARD", {x["code"] for x in f["findings"]})

    def test_semi_opaque_checkerboard_still_flagged(self):
        with tempfile.TemporaryDirectory() as raw:
            d = Path(raw); im = Image.new("RGBA", (32, 32)); px = im.load()
            for y in range(32):
                for x in range(32):
                    px[x, y] = (190, 190, 190, 128) if (x // 4 + y // 4) % 2 else (235, 235, 235, 128)
            im.save(d / "semi.png")
            f = validar_manifesto(self.manifest(d, ["semi.png"]))["frames"][0]
            self.assertIn("SUSPICIOUS_CHECKERBOARD", {x["code"] for x in f["findings"]})

    def _pose_manifest(self, d: Path, frames, **extra):
        return self.manifest(d, frames, canvas_width=64, canvas_height=64, pivot_x=32,
                             pivot_y=59, baseline_y=58, asset_type="BODY", max_scale_ratio=1.25, **extra)

    def test_same_scale_different_pose_is_not_fail(self):
        with tempfile.TemporaryDirectory() as raw:
            d = Path(raw)
            # mesma "personagem" (192 px), de pé (4x48) e agachada em L (bbox muito maior)
            self._sprite(d, "de_pe.png", [(30, 11, 33, 58)])
            self._sprite(d, "agachada.png", [(22, 35, 25, 58), (26, 55, 45, 58)])
            r = validar_manifesto(self._pose_manifest(d, ["de_pe.png", "agachada.png"], normalization_scale=0.4))
            codes = {x["code"] for x in r["animation"]["findings"]}
            self.assertNotIn("GROSS_SCALE_VARIATION", codes)
            self.assertIn("POSE_AREA_VARIATION", codes)
            self.assertEqual("REVIEW", r["animation"]["status"])

    def test_resized_character_still_fails(self):
        with tempfile.TemporaryDirectory() as raw:
            d = Path(raw)
            self._sprite(d, "normal.png", [(28, 31, 35, 58)])   # 8x28
            self._sprite(d, "grande.png", [(26, 17, 37, 58)])   # 12x42 = 1,5x linear
            for extra in ({}, {"normalization_scale": 0.4}):     # nem a escala declarada o esconde
                with self.subTest(extra=extra):
                    r = validar_manifesto(self._pose_manifest(d, ["normal.png", "grande.png"], **extra))
                    self.assertIn("GROSS_SCALE_VARIATION", {x["code"] for x in r["animation"]["findings"]})
                    self.assertEqual("FAIL", r["animation"]["status"])

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
