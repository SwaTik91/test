#!/usr/bin/env python3
"""Import and resize art-canon PNGs into midgard_outpost/assets/images/."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

RESAMPLE = Image.Resampling.LANCZOS

# Special projectile renames (canon stem -> game filename).
PROJECTILE_NAMES: dict[str, str] = {
    "arrow": "arrow.png",
    "fireball": "fireball.png",
    "holy": "holy_bolt.png",
}


def ensure_rgba(img: Image.Image) -> Image.Image:
    if img.mode == "RGBA":
        return img
    return img.convert("RGBA")


def resize_max_edge(img: Image.Image, max_edge: int) -> Image.Image:
    w, h = img.size
    longest = max(w, h)
    if longest <= max_edge:
        return img
    scale = max_edge / longest
    new_size = (max(1, int(w * scale)), max(1, int(h * scale)))
    return img.resize(new_size, RESAMPLE)


def resize_square_crop_fit(img: Image.Image, size: int) -> Image.Image:
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    cropped = img.crop((left, top, left + side, top + side))
    return cropped.resize((size, size), RESAMPLE)


def write_png(img: Image.Image, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    ensure_rgba(img).save(dest, format="PNG", optimize=True)


def dest_for_source(src: Path) -> list[tuple[Path, int, str]]:
    """Return [(dest_path, max_edge, mode), ...] for a canon source file."""
    name = src.name
    stem = src.stem

    if name.startswith("hero-"):
        hero_name = stem.removeprefix("hero-")
        return [
            (Path("heroes") / f"{hero_name}.png", 128, "max_edge"),
            (Path("hub") / f"icon_{hero_name}.png", 64, "square"),
        ]

    if name == "bg-town.png":
        return [(Path("hub") / "town_bg.png", 1920, "max_edge")]

    if name == "bg-fields.png":
        return [(Path("world") / "bg_fields.png", 1920, "max_edge")]

    if name == "bg-forest.png":
        return [(Path("world") / "bg_forest.png", 1920, "max_edge")]

    if name == "ground-tile.png":
        return [(Path("world") / "ground_tile.png", 256, "max_edge")]

    if name.startswith("mob-"):
        mob_name = stem.removeprefix("mob-")
        return [(Path("enemies") / f"{mob_name}.png", 96, "max_edge")]

    if name.startswith("boss-"):
        boss_name = stem.removeprefix("boss-")
        return [(Path("enemies") / f"boss_{boss_name}.png", 160, "max_edge")]

    if name == "prop-chest.png":
        return [(Path("props") / "chest.png", 96, "max_edge")]

    if name.startswith("proj-"):
        proj_name = stem.removeprefix("proj-")
        filename = PROJECTILE_NAMES.get(proj_name, f"{proj_name}.png")
        return [(Path("projectiles") / filename, 64, "max_edge")]

    if name.startswith("ui-btn-"):
        btn_name = stem.removeprefix("ui-btn-")
        return [(Path("ui") / f"btn_{btn_name}.png", 128, "max_edge")]

    return []


def process_image(src: Path, dest: Path, max_edge: int, mode: str) -> None:
    with Image.open(src) as raw:
        img = ensure_rgba(raw)
        if mode == "square":
            out = resize_square_crop_fit(img, max_edge)
        else:
            out = resize_max_edge(img, max_edge)
        write_png(out, dest)


def import_canon(canon_dir: Path, out_dir: Path) -> list[tuple[Path, Path, tuple[int, int]]]:
    """Import all mapped canon PNGs. Returns [(src, dest, (w, h)), ...]."""
    results: list[tuple[Path, Path, tuple[int, int]]] = []
    sources = sorted(canon_dir.glob("*.png"))

    for src in sources:
        mappings = dest_for_source(src)
        if not mappings:
            print(f"skip (no mapping): {src.name}")
            continue

        with Image.open(src) as raw:
            base = ensure_rgba(raw)

        for rel_dest, max_edge, mode in mappings:
            dest = out_dir / rel_dest
            if mode == "square":
                out = resize_square_crop_fit(base, max_edge)
            else:
                out = resize_max_edge(base, max_edge)
            write_png(out, dest)
            results.append((src, dest, out.size))
            print(f"{src.name} -> {rel_dest} ({out.size[0]}x{out.size[1]})")

    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="Import resized art-canon into game assets.")
    parser.add_argument(
        "--canon",
        type=Path,
        default=Path(__file__).resolve().parents[2] / "docs" / "superpowers" / "art-canon",
        help="Canon PNG source directory",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "assets" / "images",
        help="Game assets output directory",
    )
    args = parser.parse_args()

    if not args.canon.is_dir():
        raise SystemExit(f"Canon directory not found: {args.canon}")

    args.out.mkdir(parents=True, exist_ok=True)
    results = import_canon(args.canon, args.out)
    print(f"\nImported {len(results)} file(s) to {args.out}")


if __name__ == "__main__":
    main()
