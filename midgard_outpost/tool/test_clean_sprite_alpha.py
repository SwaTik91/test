#!/usr/bin/env python3
"""Unit tests for clean_sprite_alpha edge-connected cleanup."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

from PIL import Image

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

from clean_sprite_alpha import (  # noqa: E402
    clean_sprite_cutout,
    count_neutral_gray_opaque,
    count_opaque_in_center,
    is_neutral_gray,
)


def _gray_ring_with_interior() -> Image.Image:
    """Neutral gray interior enclosed by solid colored armor."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = img.load()
    armor = (180, 60, 60, 255)
    interior = (120, 120, 120, 255)
    for y in range(8, 24):
        for x in range(8, 24):
            if 12 <= x <= 19 and 12 <= y <= 19:
                px[x, y] = interior
            else:
                px[x, y] = armor
    return img


class CleanSpriteAlphaTest(unittest.TestCase):
    def test_interior_neutral_gray_survives_cleanup(self) -> None:
        src = _gray_ring_with_interior()
        cleaned = clean_sprite_cutout(src, bg_tolerance=80)
        center_opaque = count_opaque_in_center(cleaned, margin_fraction=0.3)
        self.assertGreater(
            center_opaque,
            0,
            "interior neutral gray was wiped by global gray removal",
        )

    def test_exterior_neutral_gray_removed(self) -> None:
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        px = img.load()
        for x in range(16):
            px[x, 15] = (150, 150, 150, 255)
        cleaned = clean_sprite_cutout(img, bg_tolerance=80)
        self.assertEqual(
            count_neutral_gray_opaque(cleaned),
            0,
            "floor shadow gray should be removed",
        )

    def test_preserve_soft_glow_keeps_semi_transparent_core(self) -> None:
        img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
        px = img.load()
        for y in range(6, 14):
            for x in range(6, 14):
                px[x, y] = (255, 120, 40, 180)
        cleaned = clean_sprite_cutout(img, preserve_soft_glow=True)
        semi = sum(
            1
            for y in range(20)
            for x in range(20)
            if 0 < cleaned.getpixel((x, y))[3] < 255
        )
        self.assertGreater(semi, 0, "soft glow semi-transparency was binarized away")


if __name__ == "__main__":
    unittest.main()
