#!/usr/bin/env python3
"""Compose store listing art: launcher icons (and screenshots in Task 3)."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[2]
MIDGARD = REPO_ROOT / "midgard_outpost"
ASSETS = MIDGARD / "assets" / "images"
STORE_ICONS = REPO_ROOT / "store" / "icons"
MIPMAP_DIR = MIDGARD / "android" / "app" / "src" / "main" / "res"

ICON_SIZE = 512
HERO_TARGET = 280

MIPMAP_SIZES: dict[str, int] = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def cover_scale(image: Image.Image, size: int) -> Image.Image:
    """Scale image to cover a square canvas, then center-crop."""
    w, h = image.size
    scale = max(size / w, size / h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    scaled = image.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - size) // 2
    top = (new_h - size) // 2
    return scaled.crop((left, top, left + size, top + size))


def compose_launcher_icon() -> Image.Image:
    bg_path = ASSETS / "hub" / "town_bg.png"
    hero_path = ASSETS / "heroes" / "paladin.png"

    bg = Image.open(bg_path).convert("RGB")
    canvas = cover_scale(bg, ICON_SIZE)

    hero = Image.open(hero_path).convert("RGBA")
    hero_w, hero_h = hero.size
    scale = HERO_TARGET / max(hero_w, hero_h)
    new_size = (max(1, int(round(hero_w * scale))), max(1, int(round(hero_h * scale))))
    hero_scaled = hero.resize(new_size, Image.Resampling.NEAREST)

    x = (ICON_SIZE - new_size[0]) // 2
    y = (ICON_SIZE - new_size[1]) // 2
    canvas.paste(hero_scaled, (x, y), hero_scaled)
    return canvas


def write_icons() -> None:
    icon = compose_launcher_icon()

    STORE_ICONS.mkdir(parents=True, exist_ok=True)
    master_path = STORE_ICONS / "ic_launcher_512.png"
    icon.save(master_path, format="PNG")

    for density, px in MIPMAP_SIZES.items():
        out_dir = MIPMAP_DIR / f"mipmap-{density}"
        out_dir.mkdir(parents=True, exist_ok=True)
        resized = icon.resize((px, px), Image.Resampling.LANCZOS)
        resized.save(out_dir / "ic_launcher.png", format="PNG")

    print(f"Wrote {master_path.relative_to(REPO_ROOT)}")
    for density in MIPMAP_SIZES:
        rel = MIPMAP_DIR / f"mipmap-{density}" / "ic_launcher.png"
        print(f"Wrote {rel.relative_to(REPO_ROOT)}")


def compose_screenshots() -> None:
    # TODO(Task 3): generate Play Store / RuStore screenshots via --screenshots
    raise NotImplementedError("Screenshot generation is implemented in Store Task 3")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compose Midgard Outpost store art assets.")
    parser.add_argument("--icons", action="store_true", help="Generate launcher icon master and mipmaps")
    parser.add_argument(
        "--screenshots",
        action="store_true",
        help="Generate store screenshots (Task 3 — not yet implemented)",
    )
    args = parser.parse_args(argv)

    if not args.icons and not args.screenshots:
        parser.error("Specify at least one of --icons or --screenshots")

    if args.icons:
        write_icons()

    if args.screenshots:
        compose_screenshots()

    return 0


if __name__ == "__main__":
    sys.exit(main())
