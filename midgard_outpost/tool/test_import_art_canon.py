#!/usr/bin/env python3
"""Regression checks for import_art_canon hero slicing and transparency."""

from __future__ import annotations

import hashlib
import sys
import unittest
from pathlib import Path

from PIL import Image

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

from clean_sprite_alpha import (  # noqa: E402
    count_exterior_neutral_gray,
    count_opaque_in_center,
    count_semi_transparent_pixels,
    force_corner_alpha_zero,
)
from import_art_canon import ensure_rgba, import_canon  # noqa: E402
from process_walk_frame import process_walk_frame_image  # noqa: E402

CANON_DIR = Path(__file__).resolve().parents[2] / "docs" / "superpowers" / "art-canon"
ARCHER_V2_DIR = CANON_DIR / "archer-v2"
ASSETS_DIR = Path(__file__).resolve().parents[1] / "assets" / "images"

HERO_CLASSES = ("archer", "mage", "paladin")
SHEET_SLICE_HEROES = ("mage", "paladin")

CREATURE_OUTPUTS = (
    ASSETS_DIR / "enemies" / "slime.png",
    ASSETS_DIR / "enemies" / "boss_demon.png",
    ASSETS_DIR / "props" / "chest.png",
)

MAX_SEMI_TRANSPARENT_HERO = 120
MAX_EXTERIOR_GRAY_HERO = 80
MAX_SEMI_TRANSPARENT_CREATURE = 400

MIN_PALADIN_CENTER_OPAQUE = 800


def file_md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def corners_transparent(path: Path) -> bool:
    with Image.open(path) as img:
        rgba = img.convert("RGBA")
        w, h = rgba.size
        corners = (
            rgba.getpixel((0, 0)),
            rgba.getpixel((w - 1, 0)),
            rgba.getpixel((0, h - 1)),
            rgba.getpixel((w - 1, h - 1)),
        )
    return all(alpha == 0 for *_rgb, alpha in corners)


def archer_v2_frame_hash(anim: str, idx: int) -> str:
    src = ARCHER_V2_DIR / f"archer-{anim}-{idx}.png"
    with Image.open(src) as raw:
        processed = process_walk_frame_image(raw, max_edge=96)
    from io import BytesIO

    buf = BytesIO()
    force_corner_alpha_zero(ensure_rgba(processed)).save(buf, format="PNG", optimize=True)
    return hashlib.md5(buf.getvalue()).hexdigest()


class ImportArtCanonRegressionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if not CANON_DIR.is_dir():
            raise unittest.SkipTest(f"Canon directory missing: {CANON_DIR}")
        import_canon(CANON_DIR, ASSETS_DIR)

    def test_mage_cast_has_two_unique_attack_frames(self) -> None:
        cast_0 = file_md5(ASSETS_DIR / "heroes" / "mage" / "cast_0.png")
        cast_1 = file_md5(ASSETS_DIR / "heroes" / "mage" / "cast_1.png")
        cast_2 = file_md5(ASSETS_DIR / "heroes" / "mage" / "cast_2.png")
        self.assertNotEqual(cast_0, cast_1, "mage cast attack frames duplicated")
        self.assertEqual(cast_2, cast_1, "mage cast_2 should pad cast_1")

    def test_mage_jump_frames_are_unique(self) -> None:
        hashes = {
            file_md5(ASSETS_DIR / "heroes" / "mage" / f"jump_{i}.png")
            for i in range(2)
        }
        self.assertEqual(len(hashes), 2, f"mage jump frames duplicated: {hashes}")

    def test_hero_jump_frames_do_not_duplicate_cast(self) -> None:
        for hero in HERO_CLASSES:
            jump_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"jump_{i}.png")
                for i in range(2)
            }
            cast_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"cast_{i}.png")
                for i in range(3)
            }
            overlap = jump_hashes & cast_hashes
            with self.subTest(hero=hero):
                self.assertFalse(
                    overlap,
                    f"{hero} jump frames duplicate cast: {overlap}",
                )

    def test_cast_third_frame_pads_attack_not_stride(self) -> None:
        for hero in SHEET_SLICE_HEROES:
            cast_1 = file_md5(ASSETS_DIR / "heroes" / hero / "cast_1.png")
            cast_2 = file_md5(ASSETS_DIR / "heroes" / hero / "cast_2.png")
            with self.subTest(hero=hero):
                self.assertEqual(
                    cast_2,
                    cast_1,
                    f"{hero} cast_2 should pad cast_1, not a run stride pose",
                )

    def test_archer_frames_match_v2_canon(self) -> None:
        if not ARCHER_V2_DIR.is_dir():
            self.skipTest(f"archer-v2 canon missing: {ARCHER_V2_DIR}")
        for anim in ("idle", "jump", "cast"):
            count = 2 if anim in ("idle", "jump") else 3
            for idx in range(count):
                dest = ASSETS_DIR / "heroes" / "archer" / f"{anim}_{idx}.png"
                expected = archer_v2_frame_hash(anim, idx)
                actual = file_md5(dest)
                with self.subTest(anim=anim, idx=idx):
                    self.assertEqual(
                        actual,
                        expected,
                        f"archer {anim}_{idx} does not match processed archer-v2 source",
                    )

    def test_archer_idle_frames_are_unique(self) -> None:
        hashes = {
            file_md5(ASSETS_DIR / "heroes" / "archer" / f"idle_{i}.png")
            for i in range(2)
        }
        self.assertEqual(len(hashes), 2, f"archer idle frames duplicated: {hashes}")

    def test_archer_jump_frames_differ_from_cast(self) -> None:
        jump_hashes = {
            file_md5(ASSETS_DIR / "heroes" / "archer" / f"jump_{i}.png")
            for i in range(2)
        }
        cast_hashes = {
            file_md5(ASSETS_DIR / "heroes" / "archer" / f"cast_{i}.png")
            for i in range(3)
        }
        overlap = jump_hashes & cast_hashes
        self.assertFalse(overlap, f"archer jump frames duplicate cast: {overlap}")

    def test_archer_cast_has_real_third_frame(self) -> None:
        """Archer cast uses dedicated v2 art, not sheet-slice padding like mage/paladin."""
        cast_0 = file_md5(ASSETS_DIR / "heroes" / "archer" / "cast_0.png")
        cast_1 = file_md5(ASSETS_DIR / "heroes" / "archer" / "cast_1.png")
        cast_2 = file_md5(ASSETS_DIR / "heroes" / "archer" / "cast_2.png")
        self.assertNotEqual(cast_0, cast_1, "archer cast attack frames duplicated")
        self.assertNotEqual(cast_2, cast_1, "archer cast_2 should be unique v2 frame, not padded")

    def test_archer_preview_and_icon_from_idle_0(self) -> None:
        idle_0 = file_md5(ASSETS_DIR / "heroes" / "archer" / "idle_0.png")
        preview = file_md5(ASSETS_DIR / "heroes" / "archer.png")
        self.assertEqual(preview, idle_0, "archer.png should match processed idle_0")
        icon_path = ASSETS_DIR / "hub" / "icon_archer.png"
        with Image.open(icon_path) as icon:
            self.assertEqual(icon.size, (64, 64))
            self.assertTrue(corners_transparent(icon_path))

    def test_cast_frames_do_not_match_run(self) -> None:
        for hero in HERO_CLASSES:
            cast_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"cast_{i}.png")
                for i in range(3)
            }
            run_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"run_{i}.png")
                for i in range(4)
            }
            overlap = cast_hashes & run_hashes
            with self.subTest(hero=hero):
                self.assertFalse(
                    overlap,
                    f"{hero} cast frames overlap run cycle: {overlap}",
                )

    def test_hero_run_frames_are_unique_and_not_idle(self) -> None:
        for hero in HERO_CLASSES:
            idle_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"idle_{i}.png")
                for i in range(2)
            }
            run_hashes = [
                file_md5(ASSETS_DIR / "heroes" / hero / f"run_{i}.png")
                for i in range(4)
            ]
            with self.subTest(hero=hero):
                self.assertEqual(
                    len(set(run_hashes)),
                    4,
                    f"{hero} run frames duplicated: {run_hashes}",
                )
                overlap = set(run_hashes) & idle_hashes
                self.assertFalse(
                    overlap,
                    f"{hero} run frames duplicate idle: {overlap}",
                )

    def test_paladin_interior_opaque_detail_preserved(self) -> None:
        path = ASSETS_DIR / "heroes" / "paladin" / "cast_0.png"
        with Image.open(path) as img:
            center_opaque = count_opaque_in_center(img)
        self.assertGreaterEqual(
            center_opaque,
            MIN_PALADIN_CENTER_OPAQUE,
            f"paladin interior holes after cleanup: {center_opaque} center opaque px",
        )

    def test_hero_cutouts_have_transparent_corners(self) -> None:
        for hero in HERO_CLASSES:
            for anim in ("idle", "run", "jump", "cast"):
                count = 2 if anim in ("idle", "jump") else (4 if anim == "run" else 3)
                for idx in range(count):
                    path = ASSETS_DIR / "heroes" / hero / f"{anim}_{idx}.png"
                    with self.subTest(path=path):
                        self.assertTrue(path.is_file(), f"missing hero frame: {path}")
                        self.assertTrue(
                            corners_transparent(path),
                            f"opaque corners on hero frame: {path}",
                        )

    def test_hero_frames_have_crisp_alpha(self) -> None:
        for hero in HERO_CLASSES:
            for anim in ("idle", "run", "jump", "cast"):
                count = 2 if anim in ("idle", "jump") else (4 if anim == "run" else 3)
                for idx in range(count):
                    path = ASSETS_DIR / "heroes" / hero / f"{anim}_{idx}.png"
                    with Image.open(path) as img:
                        semi = count_semi_transparent_pixels(img)
                        exterior_gray = count_exterior_neutral_gray(img)
                    with self.subTest(path=path):
                        self.assertLessEqual(
                            semi,
                            MAX_SEMI_TRANSPARENT_HERO,
                            f"too many semi-transparent pixels on {path}: {semi}",
                        )
                        self.assertLessEqual(
                            exterior_gray,
                            MAX_EXTERIOR_GRAY_HERO,
                            f"exterior gray backdrop on {path}: {exterior_gray}",
                        )

    def test_creature_outputs_have_transparent_corners(self) -> None:
        for path in CREATURE_OUTPUTS:
            with self.subTest(path=path):
                self.assertTrue(path.is_file(), f"missing creature output: {path}")
                self.assertTrue(
                    corners_transparent(path),
                    f"opaque corners on creature output: {path}",
                )

    def test_creature_outputs_have_clean_alpha(self) -> None:
        for path in CREATURE_OUTPUTS:
            with Image.open(path) as img:
                semi = count_semi_transparent_pixels(img)
            with self.subTest(path=path):
                self.assertLessEqual(
                    semi,
                    MAX_SEMI_TRANSPARENT_CREATURE,
                    f"too many semi-transparent pixels on {path}: {semi}",
                )


if __name__ == "__main__":
    unittest.main()
