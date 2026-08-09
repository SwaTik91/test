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

# Per-mob walk-cycle frame picks (f_XXX from /tmp/mob-processed/<name>/).
MOB_WALK_SOURCES: dict[str, tuple[str, ...]] = {
    "lunatic": ("f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png", "f_019.png"),
    "wolf": ("f_007.png", "f_010.png", "f_013.png", "f_016.png", "f_019.png", "f_022.png"),
    "mushroom": ("f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png", "f_019.png"),
    "bee": ("f_001.png", "f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png"),
    "crab": ("f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png", "f_019.png"),
    "ghost": ("f_001.png", "f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png"),
    "plant": ("f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png", "f_019.png"),
    "boss_demon": ("f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png", "f_019.png"),
    "boss_spider": ("f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png", "f_019.png"),
    "boss_undead": ("f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png", "f_019.png"),
    "boss_golem": ("f_004.png", "f_007.png", "f_010.png", "f_013.png", "f_016.png", "f_019.png"),
}

CHEST_OPEN_SOURCES = (
    "f_004.png",
    "f_007.png",
    "f_010.png",
    "f_013.png",
    "f_016.png",
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


def bootstrap_mob_canon(
    mob_name: str,
    source_dir: Path,
    canon_dir: Path,
    *,
    max_edge: int = 160,
) -> list[Path]:
    frame_names = MOB_WALK_SOURCES[mob_name]
    sources = [source_dir / name for name in frame_names]
    for src in sources:
        if not src.is_file():
            raise SystemExit(f"Missing {mob_name} walk source: {src}")
    frames = process_walk_cycle(sources, max_edge=max_edge)
    return write_walk_cycle(frames, canon_dir / "monster-video" / mob_name)


def bootstrap_chest_canon(
    source_dir: Path,
    canon_dir: Path,
    *,
    max_edge: int = 160,
) -> list[Path]:
    sources = [source_dir / name for name in CHEST_OPEN_SOURCES]
    for src in sources:
        if not src.is_file():
            raise SystemExit(f"Missing chest open source: {src}")
    frames = process_walk_cycle(sources, max_edge=max_edge)
    return write_walk_cycle(frames, canon_dir / "prop-video" / "chest", prefix="open")


def bootstrap_all_canon(
    processed_root: Path,
    canon_dir: Path,
    *,
    max_edge: int = 160,
) -> list[Path]:
    paths: list[Path] = []
    for mob_name in MOB_WALK_SOURCES:
        source_dir = processed_root / mob_name
        if not source_dir.is_dir():
            raise SystemExit(f"Missing processed mob dir: {source_dir}")
        paths.extend(bootstrap_mob_canon(mob_name, source_dir, canon_dir, max_edge=max_edge))
    chest_dir = processed_root / "chest"
    if not chest_dir.is_dir():
        raise SystemExit(f"Missing processed chest dir: {chest_dir}")
    paths.extend(bootstrap_chest_canon(chest_dir, canon_dir, max_edge=max_edge))
    return paths


def main() -> None:
    parser = argparse.ArgumentParser(description="Process monster video frames into canon walk cycles.")
    root = Path(__file__).resolve().parents[2]
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=Path("/tmp/mob-processed"),
        help="Directory with per-mob f_XXX frames (subdirs per mob name)",
    )
    parser.add_argument(
        "--canon",
        type=Path,
        default=root / "docs" / "superpowers" / "art-canon",
        help="Canon output directory",
    )
    parser.add_argument("--max-edge", type=int, default=160)
    parser.add_argument(
        "--all",
        action="store_true",
        help="Process all mobs + chest (default when --mob not set)",
    )
    parser.add_argument(
        "--mob",
        type=str,
        default="",
        help="Process a single mob name (e.g. lunatic, boss_demon)",
    )
    parser.add_argument(
        "--slime-only",
        action="store_true",
        help="Process slime only (legacy /tmp/slime-hf-processed layout)",
    )
    args = parser.parse_args()

    if args.slime_only:
        slime_dir = Path("/tmp/slime-hf-processed")
        paths = bootstrap_slime_canon(slime_dir, args.canon, max_edge=args.max_edge)
    elif args.mob:
        mob_name = args.mob
        if mob_name == "chest":
            paths = bootstrap_chest_canon(args.source_dir / "chest", args.canon, max_edge=args.max_edge)
        elif mob_name in MOB_WALK_SOURCES:
            paths = bootstrap_mob_canon(
                mob_name, args.source_dir / mob_name, args.canon, max_edge=args.max_edge
            )
        else:
            raise SystemExit(f"Unknown mob: {mob_name}")
    else:
        paths = bootstrap_all_canon(args.source_dir, args.canon, max_edge=args.max_edge)

    for path in paths:
        with Image.open(path) as img:
            print(f"{path.name} -> {path.relative_to(args.canon)} ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    main()
