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
from import_art_canon import (  # noqa: E402
    ARCHER_V3_ANIMS,
    ARCHER_VIDEO_CAST_COUNT,
    ARCHER_VIDEO_RUN_COUNT,
    ensure_rgba,
    import_canon,
)
from process_walk_frame import process_walk_frame_image  # noqa: E402

CANON_DIR = Path(__file__).resolve().parents[2] / "docs" / "superpowers" / "art-canon"
ARCHER_V3_DIR = CANON_DIR / "archer-v3"
ARCHER_VIDEO_DIR = CANON_DIR / "archer-video"
ASSETS_DIR = Path(__file__).resolve().parents[1] / "assets" / "images"

HERO_CLASSES = ("archer", "mage", "paladin")
SHEET_SLICE_HEROES = ("mage", "paladin")

ARCHER_ANIM_COUNTS = {
    **ARCHER_V3_ANIMS,
    "run": ARCHER_VIDEO_RUN_COUNT,
    "cast": ARCHER_VIDEO_CAST_COUNT,
}
DEFAULT_ANIM_COUNTS = {
    "idle": 2,
    "run": 4,
    "jump": 2,
    "cast": 3,
}

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


def archer_video_frame_hash(prefix: str, idx: int) -> str:
    src = ARCHER_VIDEO_DIR / f"{prefix}_{idx}.png"
    with Image.open(src) as raw:
        rgba = ensure_rgba(raw.copy())
        w, h = rgba.size
        longest = max(w, h)
        if longest > 96:
            scale = 96 / longest
            rgba = rgba.resize(
                (max(1, int(w * scale)), max(1, int(h * scale))),
                Image.Resampling.NEAREST,
            )
    from io import BytesIO

    buf = BytesIO()
    force_corner_alpha_zero(rgba).save(buf, format="PNG", optimize=True)
    return hashlib.md5(buf.getvalue()).hexdigest()


def archer_video_run_hash(idx: int) -> str:
    return archer_video_frame_hash("run", idx)


def archer_video_cast_hash(idx: int) -> str:
    return archer_video_frame_hash("cast", idx)


def archer_v3_frame_hash(anim: str, idx: int) -> str:
    src = ARCHER_V3_DIR / f"archer-{anim}-{idx}.png"
    with Image.open(src) as raw:
        processed = process_walk_frame_image(
            raw,
            max_edge=96,
            largest_component_only=True,
        )
    from io import BytesIO

    buf = BytesIO()
    force_corner_alpha_zero(ensure_rgba(processed)).save(buf, format="PNG", optimize=True)
    return hashlib.md5(buf.getvalue()).hexdigest()


def hero_anim_counts(hero: str) -> dict[str, int]:
    if hero == "archer":
        return ARCHER_ANIM_COUNTS
    return DEFAULT_ANIM_COUNTS


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
            counts = hero_anim_counts(hero)
            jump_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"jump_{i}.png")
                for i in range(counts["jump"])
            }
            cast_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"cast_{i}.png")
                for i in range(counts["cast"])
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

    def test_archer_frames_match_v3_canon(self) -> None:
        if not ARCHER_V3_DIR.is_dir():
            self.skipTest(f"archer-v3 canon missing: {ARCHER_V3_DIR}")
        for anim, count in ARCHER_V3_ANIMS.items():
            for idx in range(count):
                dest = ASSETS_DIR / "heroes" / "archer" / f"{anim}_{idx}.png"
                expected = archer_v3_frame_hash(anim, idx)
                actual = file_md5(dest)
                with self.subTest(anim=anim, idx=idx):
                    self.assertEqual(
                        actual,
                        expected,
                        f"archer {anim}_{idx} does not match processed archer-v3 source",
                    )

    def test_archer_run_frames_match_video_canon(self) -> None:
        if not ARCHER_VIDEO_DIR.is_dir():
            self.skipTest(f"archer-video canon missing: {ARCHER_VIDEO_DIR}")
        for idx in range(ARCHER_VIDEO_RUN_COUNT):
            dest = ASSETS_DIR / "heroes" / "archer" / f"run_{idx}.png"
            expected = archer_video_run_hash(idx)
            actual = file_md5(dest)
            with self.subTest(idx=idx):
                self.assertEqual(
                    actual,
                    expected,
                    f"archer run_{idx} does not match processed archer-video source",
                )

    def test_archer_cast_frames_match_video_canon(self) -> None:
        if not ARCHER_VIDEO_DIR.is_dir():
            self.skipTest(f"archer-video canon missing: {ARCHER_VIDEO_DIR}")
        for idx in range(ARCHER_VIDEO_CAST_COUNT):
            dest = ASSETS_DIR / "heroes" / "archer" / f"cast_{idx}.png"
            expected = archer_video_cast_hash(idx)
            actual = file_md5(dest)
            with self.subTest(idx=idx):
                self.assertEqual(
                    actual,
                    expected,
                    f"archer cast_{idx} does not match processed archer-video source",
                )

    def test_archer_idle_frames_are_unique(self) -> None:
        hashes = {
            file_md5(ASSETS_DIR / "heroes" / "archer" / f"idle_{i}.png")
            for i in range(ARCHER_ANIM_COUNTS["idle"])
        }
        self.assertEqual(
            len(hashes),
            ARCHER_ANIM_COUNTS["idle"],
            f"archer idle frames duplicated: {hashes}",
        )

    def test_archer_jump_frames_differ_from_cast(self) -> None:
        jump_hashes = {
            file_md5(ASSETS_DIR / "heroes" / "archer" / f"jump_{i}.png")
            for i in range(ARCHER_ANIM_COUNTS["jump"])
        }
        cast_hashes = {
            file_md5(ASSETS_DIR / "heroes" / "archer" / f"cast_{i}.png")
            for i in range(ARCHER_ANIM_COUNTS["cast"])
        }
        overlap = jump_hashes & cast_hashes
        self.assertFalse(overlap, f"archer jump frames duplicate cast: {overlap}")

    def test_archer_cast_has_eight_unique_frames(self) -> None:
        hashes = {
            file_md5(ASSETS_DIR / "heroes" / "archer" / f"cast_{i}.png")
            for i in range(ARCHER_ANIM_COUNTS["cast"])
        }
        self.assertEqual(
            len(hashes),
            ARCHER_ANIM_COUNTS["cast"],
            f"archer cast frames duplicated: {hashes}",
        )

    def test_archer_run_has_eight_unique_frames(self) -> None:
        hashes = {
            file_md5(ASSETS_DIR / "heroes" / "archer" / f"run_{i}.png")
            for i in range(ARCHER_ANIM_COUNTS["run"])
        }
        self.assertEqual(
            len(hashes),
            ARCHER_ANIM_COUNTS["run"],
            f"archer run frames duplicated: {hashes}",
        )

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
            counts = hero_anim_counts(hero)
            cast_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"cast_{i}.png")
                for i in range(counts["cast"])
            }
            run_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"run_{i}.png")
                for i in range(counts["run"])
            }
            overlap = cast_hashes & run_hashes
            with self.subTest(hero=hero):
                self.assertFalse(
                    overlap,
                    f"{hero} cast frames overlap run cycle: {overlap}",
                )

    def test_hero_run_frames_are_unique_and_not_idle(self) -> None:
        for hero in HERO_CLASSES:
            counts = hero_anim_counts(hero)
            idle_hashes = {
                file_md5(ASSETS_DIR / "heroes" / hero / f"idle_{i}.png")
                for i in range(counts["idle"])
            }
            run_hashes = [
                file_md5(ASSETS_DIR / "heroes" / hero / f"run_{i}.png")
                for i in range(counts["run"])
            ]
            with self.subTest(hero=hero):
                self.assertEqual(
                    len(set(run_hashes)),
                    counts["run"],
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
            counts = hero_anim_counts(hero)
            for anim, count in counts.items():
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
            counts = hero_anim_counts(hero)
            for anim, count in counts.items():
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
