#!/usr/bin/env python3
"""Remove leftover magenta/hot-pink chroma-key pixels from Wave 2 animation frames."""

from __future__ import annotations

import argparse
import sys
from collections import deque
from pathlib import Path

from PIL import Image

# Wave 2 frame roots relative to assets/images/
SCAN_DIRS = (
    "heroes",
    "props/chest",
    "vfx",
)


def is_chroma_magenta(r: int, g: int, b: int, a: int) -> bool:
    """Detect pure chroma-key magenta without catching intentional red/purple."""
    if a == 0:
        return False
    # Near #FF00FF / #FF00AA: very high R+B, very low G.
    if r >= 220 and b >= 220 and g <= 40:
        return True
    # Soft hot-pink fringe from imperfect keying.
    if r >= 200 and b >= 200 and g <= 50 and (r + b - 2 * g) >= 350:
        return True
    return False


def neighbor_fill_color(
    pixels: list[list[tuple[int, int, int, int]]],
    x: int,
    y: int,
    width: int,
    height: int,
) -> tuple[int, int, int, int] | None:
    """Average the nearest opaque non-chroma neighbors for in-fill replacement."""
    samples: list[tuple[int, int, int]] = []
    for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < width and 0 <= ny < height:
            r, g, b, a = pixels[ny][nx]
            if a > 0 and not is_chroma_magenta(r, g, b, a):
                samples.append((r, g, b))
    if not samples:
        return None
    count = len(samples)
    return (
        sum(c[0] for c in samples) // count,
        sum(c[1] for c in samples) // count,
        sum(c[2] for c in samples) // count,
        255,
    )


def scrub_image(path: Path, dry_run: bool = False) -> int:
    """Return count of magenta pixels removed from one PNG."""
    img = Image.open(path).convert("RGBA")
    width, height = img.size
    px = img.load()
    pixels = [[px[x, y] for x in range(width)] for y in range(height)]

    changed = 0
    queue: deque[tuple[int, int]] = deque()
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[y][x]
            if is_chroma_magenta(r, g, b, a):
                queue.append((x, y))

    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[y][x]
        if not is_chroma_magenta(r, g, b, a):
            continue

        fill = neighbor_fill_color(pixels, x, y, width, height)
        if fill is None:
            pixels[y][x] = (r, g, b, 0)
        else:
            # Prefer transparent for pure chroma; fill only when surrounded by opaque art.
            if r >= 235 and b >= 235 and g <= 20:
                pixels[y][x] = (r, g, b, 0)
            else:
                pixels[y][x] = fill
        changed += 1

    if changed and not dry_run:
        for y in range(height):
            for x in range(width):
                px[x, y] = pixels[y][x]
        img.save(path, format="PNG")

    return changed


def collect_pngs(asset_root: Path) -> list[Path]:
    files: list[Path] = []
    for rel in SCAN_DIRS:
        base = asset_root / rel
        if not base.exists():
            continue
        for path in sorted(base.rglob("*.png")):
            files.append(path)
    return files


def count_magenta_opaque(asset_root: Path) -> tuple[int, list[tuple[str, int]]]:
    total = 0
    per_file: list[tuple[str, int]] = []
    for path in collect_pngs(asset_root):
        img = Image.open(path).convert("RGBA")
        px = img.load()
        width, height = img.size
        count = 0
        for y in range(height):
            for x in range(width):
                r, g, b, a = px[x, y]
                if is_chroma_magenta(r, g, b, a):
                    count += 1
        if count:
            rel = str(path.relative_to(asset_root))
            per_file.append((rel, count))
            total += count
    return total, per_file


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--asset-root",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "assets" / "images",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--count-only", action="store_true")
    args = parser.parse_args()

    if args.count_only:
        total, per_file = count_magenta_opaque(args.asset_root)
        print(f"magenta_opaque_total={total}")
        for rel, count in per_file:
            print(f"  {rel}: {count}")
        return 0

    files = collect_pngs(args.asset_root)
    total_changed = 0
    touched = 0
    for path in files:
        changed = scrub_image(path, dry_run=args.dry_run)
        if changed:
            touched += 1
            rel = path.relative_to(args.asset_root)
            print(f"{'would scrub' if args.dry_run else 'scrubbed'} {rel}: {changed}px")
            total_changed += changed

    after_total, _ = count_magenta_opaque(args.asset_root) if not args.dry_run else (None, [])
    print(f"files_touched={touched} pixels_changed={total_changed}")
    if not args.dry_run:
        print(f"magenta_opaque_after={after_total}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
