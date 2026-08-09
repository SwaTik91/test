#!/usr/bin/env python3
"""Process video-derived monster frames into union-canvas walk cycles."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from clean_sprite_alpha import force_corner_alpha_zero
from import_art_canon import RESAMPLE, ensure_rgba, resize_max_edge, write_png

SLIME_WALK_SOURCES = (
    "f_001.png",
    "f_005.png",
    "f_009.png",
    "f_017.png",
    "f_025.png",
    "f_033.png",
)


def opaque_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    bbox = ensure_rgba(img).getbbox()
    if bbox is None:
        raise ValueError("frame has no opaque pixels")
    return bbox


def union_canvas_bottom_align(frames: list[Image.Image]) -> list[Image.Image]:
    """Place each frame's opaque content in a shared canvas, bottom-centered."""
    bboxes = [opaque_bbox(frame) for frame in frames]
    canvas_w = max(x1 - x0 for x0, _y0, x1, _y1 in bboxes)
    canvas_h = max(y1 - y0 for _x0, y0, _x1, y1 in bboxes)

    aligned: list[Image.Image] = []
    for frame, (x0, y0, x1, y1) in zip(frames, bboxes):
        crop = frame.crop((x0, y0, x1, y1))
        canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
        paste_x = (canvas_w - crop.width) // 2
        paste_y = canvas_h - crop.height
        canvas.paste(crop, (paste_x, paste_y), crop)
        aligned.append(force_corner_alpha_zero(canvas))
    return aligned


def process_walk_cycle(
    sources: list[Path],
    *,
    max_edge: int = 160,
) -> list[Image.Image]:
    resized: list[Image.Image] = []
    for src in sources:
        with Image.open(src) as raw:
            frame = force_corner_alpha_zero(
                resize_max_edge(ensure_rgba(raw), max_edge, resample=RESAMPLE)
            )
        resized.append(frame)
    return union_canvas_bottom_align(resized)


def write_walk_cycle(
    frames: list[Image.Image],
    dest_dir: Path,
    *,
    prefix: str = "walk",
) -> list[Path]:
    dest_dir.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    for idx, frame in enumerate(frames):
        dest = dest_dir / f"{prefix}_{idx}.png"
        write_png(frame, dest)
        paths.append(dest)
    return paths


def bootstrap_slime_canon(
    source_dir: Path,
    canon_dir: Path,
    *,
    max_edge: int = 160,
) -> list[Path]:
    sources = [source_dir / name for name in SLIME_WALK_SOURCES]
    for src in sources:
        if not src.is_file():
            raise SystemExit(f"Missing slime walk source: {src}")
    frames = process_walk_cycle(sources, max_edge=max_edge)
    return write_walk_cycle(frames, canon_dir / "monster-video" / "slime")


def main() -> None:
    parser = argparse.ArgumentParser(description="Process monster video frames into canon walk cycles.")
    root = Path(__file__).resolve().parents[2]
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=Path("/tmp/slime-hf-processed"),
        help="Directory with f_001..f_033 slime hop frames",
    )
    parser.add_argument(
        "--canon",
        type=Path,
        default=root / "docs" / "superpowers" / "art-canon",
        help="Canon output directory",
    )
    parser.add_argument("--max-edge", type=int, default=160)
    args = parser.parse_args()

    paths = bootstrap_slime_canon(args.source_dir, args.canon, max_edge=args.max_edge)
    for path in paths:
        with Image.open(path) as img:
            print(f"{path.name} -> {path.relative_to(args.canon)} ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    main()
