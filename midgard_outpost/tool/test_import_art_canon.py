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

from import_art_canon import import_canon  # noqa: E402

CANON_DIR = Path(__file__).resolve().parents[2] / "docs" / "superpowers" / "art-canon"
ASSETS_DIR = Path(__file__).resolve().parents[1] / "assets" / "images"

HERO_CLASSES = ("archer", "mage", "paladin")

# Representative creature outputs produced by the import pipeline.
CREATURE_OUTPUTS = (
    ASSETS_DIR / "enemies" / "slime.png",
    ASSETS_DIR / "enemies" / "boss_demon.png",
    ASSETS_DIR / "props" / "chest.png",
)


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


class ImportArtCanonRegressionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if not CANON_DIR.is_dir():
            raise unittest.SkipTest(f"Canon directory missing: {CANON_DIR}")
        import_canon(CANON_DIR, ASSETS_DIR)

    def test_mage_cast_frames_are_unique(self) -> None:
        hashes = {
            file_md5(ASSETS_DIR / "heroes" / "mage" / f"cast_{i}.png")
            for i in range(3)
        }
        self.assertEqual(len(hashes), 3, f"mage cast frames duplicated: {hashes}")

    def test_mage_jump_frames_are_unique(self) -> None:
        hashes = {
            file_md5(ASSETS_DIR / "heroes" / "mage" / f"jump_{i}.png")
            for i in range(2)
        }
        self.assertEqual(len(hashes), 2, f"mage jump frames duplicated: {hashes}")

    def test_hero_cutouts_have_transparent_corners(self) -> None:
        for hero in HERO_CLASSES:
            for anim in ("idle", "run", "jump", "cast"):
                count = 2 if anim in ("idle", "jump") else (4 if anim == "run" else 3)
                for idx in range(count):
                    path = ASSETS_DIR / "heroes" / hero / f"{anim}_{idx}.png"
                    with self.subTest(path=path):
                        self.assertTrue(
                            path.is_file(),
                            f"missing hero frame: {path}",
                        )
                        self.assertTrue(
                            corners_transparent(path),
                            f"opaque corners on hero frame: {path}",
                        )

    def test_creature_outputs_have_transparent_corners(self) -> None:
        for path in CREATURE_OUTPUTS:
            with self.subTest(path=path):
                self.assertTrue(path.is_file(), f"missing creature output: {path}")
                self.assertTrue(
                    corners_transparent(path),
                    f"opaque corners on creature output: {path}",
                )


if __name__ == "__main__":
    unittest.main()
