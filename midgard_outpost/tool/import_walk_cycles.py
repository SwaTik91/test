#!/usr/bin/env python3
"""Import hero walk/run cycle frames from art-canon walk sources."""

from __future__ import annotations

import argparse
from pathlib import Path

from process_walk_frame import process_walk_frame

HERO_CLASSES = ("archer", "mage", "paladin")
RUN_FRAME_COUNT = 4


def import_walk_cycles(canon_walk_dir: Path, out_dir: Path, max_edge: int = 96) -> list[tuple[Path, Path]]:
    """Import run_0..3 frames for each hero class."""
    results: list[tuple[Path, Path]] = []
    for hero in HERO_CLASSES:
        hero_walk_dir = canon_walk_dir / hero
        if not hero_walk_dir.is_dir():
            raise SystemExit(f"Missing walk source dir: {hero_walk_dir}")
        for idx in range(RUN_FRAME_COUNT):
            src = hero_walk_dir / f"run_{idx}.png"
            if not src.is_file():
                raise SystemExit(f"Missing walk frame: {src}")
            rel = Path("heroes") / hero / f"run_{idx}.png"
            dest = out_dir / rel
            size = process_walk_frame(src, dest, max_edge)
            results.append((src, dest))
            print(f"{src.name} -> {rel} ({size[0]}x{size[1]})")
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="Import hero walk/run frames into game assets.")
    root = Path(__file__).resolve().parents[2]
    parser.add_argument(
        "--canon-walk",
        type=Path,
        default=root / "docs" / "superpowers" / "art-canon" / "walk",
        help="Canon walk frame source directory (heroes/<class>/run_0..3.png)",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "assets" / "images",
        help="Game assets output directory",
    )
    parser.add_argument("--max-edge", type=int, default=96)
    args = parser.parse_args()

    if not args.canon_walk.is_dir():
        raise SystemExit(f"Canon walk directory not found: {args.canon_walk}")

    results = import_walk_cycles(args.canon_walk, args.out, args.max_edge)
    print(f"\nImported {len(results)} walk frame(s) to {args.out}")


if __name__ == "__main__":
    main()
