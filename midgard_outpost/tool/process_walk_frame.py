#!/usr/bin/env python3
"""Process a magenta-chroma walk frame PNG into a game-ready hero run frame."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from clean_sprite_alpha import clean_chroma_sprite, force_corner_alpha_zero

RESAMPLE = Image.Resampling.NEAREST


def is_chroma_magenta(r: int, g: int, b: int, a: int) -> bool:
    if a == 0:
        return False
    if r >= 220 and b >= 220 and g <= 40:
        return True
    if r >= 200 and b >= 200 and g <= 50 and (r + b - 2 * g) >= 350:
        return True
    return False


def key_magenta_to_alpha(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_chroma_magenta(r, g, b, a):
                px[x, y] = (r, g, b, 0)
    return rgba


def tight_crop_opaque(img: Image.Image, pad: int = 2) -> Image.Image:
    rgba = img.convert("RGBA")
    bbox = rgba.getbbox()
    if bbox is None:
        return rgba
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(rgba.width, x1 + pad)
    y1 = min(rgba.height, y1 + pad)
    return rgba.crop((x0, y0, x1, y1))


def resize_max_edge(img: Image.Image, max_edge: int) -> Image.Image:
    w, h = img.size
    longest = max(w, h)
    if longest <= max_edge:
        return img
    scale = max_edge / longest
    new_size = (max(1, int(w * scale)), max(1, int(h * scale)))
    return img.resize(new_size, RESAMPLE)


def process_walk_frame(src: Path, dest: Path, max_edge: int = 96) -> tuple[int, int]:
    with Image.open(src) as raw:
        keyed = key_magenta_to_alpha(raw)
    cropped = tight_crop_opaque(keyed)
    sized = resize_max_edge(cropped, max_edge)
    out = clean_chroma_sprite(sized)
    dest.parent.mkdir(parents=True, exist_ok=True)
    out.save(dest, format="PNG", optimize=True)
    return out.size


def main() -> None:
    parser = argparse.ArgumentParser(description="Process one walk frame PNG.")
    parser.add_argument("src", type=Path)
    parser.add_argument("dest", type=Path)
    parser.add_argument("--max-edge", type=int, default=96)
    args = parser.parse_args()
    size = process_walk_frame(args.src, args.dest, args.max_edge)
    print(f"{args.src.name} -> {args.dest} ({size[0]}x{size[1]})")


if __name__ == "__main__":
    main()
