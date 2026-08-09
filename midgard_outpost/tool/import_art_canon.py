#!/usr/bin/env python3
"""Import and resize art-canon PNGs into midgard_outpost/assets/images/."""

from __future__ import annotations

import argparse
from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

from clean_sprite_alpha import clean_sprite_cutout, force_corner_alpha_zero

HERO_FRAME_RESAMPLE = Image.Resampling.NEAREST
RESAMPLE = Image.Resampling.LANCZOS

# Ignore tiny VFX particles (e.g. mage fireball) when slicing hero sheets.
MIN_HERO_POSE_PIXELS = 5000
MIN_HERO_POSE_EDGE = 80

# Special projectile renames (canon stem -> game filename).
PROJECTILE_NAMES: dict[str, str] = {
    "arrow": "arrow.png",
    "fireball": "fireball.png",
    "holy": "holy_bolt.png",
}

# Animation frame counts expected by AnimationAtlas (mage/paladin sheet slices).
HERO_ANIM_COUNTS: dict[str, int] = {
    "idle": 2,
    "run": 4,
    "jump": 2,
    "cast": 3,
}

# Archer animation cycles from Higgsfield video frames (pre-keyed alpha in archer-video-v2/).
ARCHER_VIDEO_IDLE_COUNT = 4
ARCHER_VIDEO_RUN_COUNT = 8
ARCHER_VIDEO_JUMP_COUNT = 6
ARCHER_VIDEO_CAST_COUNT = 8

ARCHER_VIDEO_ANIMS: dict[str, int] = {
    "idle": ARCHER_VIDEO_IDLE_COUNT,
    "run": ARCHER_VIDEO_RUN_COUNT,
    "jump": ARCHER_VIDEO_JUMP_COUNT,
    "cast": ARCHER_VIDEO_CAST_COUNT,
}

# Monster walk cycles from art-canon/monster-video/<kind>/ (pre-keyed alpha).
MONSTER_VIDEO_WALK_COUNT = 6

MONSTER_VIDEO_KINDS: tuple[str, ...] = (
    "slime",
    "lunatic",
    "wolf",
    "mushroom",
    "bee",
    "crab",
    "ghost",
    "plant",
    "boss_demon",
    "boss_spider",
    "boss_undead",
    "boss_golem",
)

MONSTER_VIDEO_ANIMS: dict[str, dict[str, int]] = {
    kind: {"walk": MONSTER_VIDEO_WALK_COUNT} for kind in MONSTER_VIDEO_KINDS
}

# Chest open animation from art-canon/prop-video/chest/ (pre-keyed alpha, non-loop).
PROP_VIDEO_CHEST_OPEN_COUNT = 5

PROP_VIDEO_ANIMS: dict[str, dict[str, int]] = {
    "chest": {"open": PROP_VIDEO_CHEST_OPEN_COUNT},
}


@dataclass(frozen=True)
class BBox:
    x0: int
    y0: int
    x1: int
    y1: int
    pixels: int

    @property
    def width(self) -> int:
        return self.x1 - self.x0

    @property
    def height(self) -> int:
        return self.y1 - self.y0

    @property
    def center_y(self) -> float:
        return (self.y0 + self.y1) / 2


def ensure_rgba(img: Image.Image) -> Image.Image:
    if img.mode == "RGBA":
        return img
    return img.convert("RGBA")


def resize_max_edge(img: Image.Image, max_edge: int, resample: Image.Resampling = RESAMPLE) -> Image.Image:
    w, h = img.size
    longest = max(w, h)
    if longest <= max_edge:
        return img
    scale = max_edge / longest
    new_size = (max(1, int(w * scale)), max(1, int(h * scale)))
    return img.resize(new_size, resample)


def make_bottom_aligned_icon(sprite: Image.Image, size: int = 64) -> Image.Image:
    """Fit sprite into size×size canvas, bottom-centered, nearest-neighbor."""
    rgba = ensure_rgba(sprite)
    w, h = rgba.size
    longest = max(w, h)
    if longest > size:
        scale = size / longest
        new_size = (max(1, int(w * scale)), max(1, int(h * scale)))
        rgba = rgba.resize(new_size, RESAMPLE)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - rgba.width) // 2
    y = size - rgba.height
    canvas.paste(rgba, (x, y), rgba)
    return canvas


def resize_square_crop_fit(img: Image.Image, size: int) -> Image.Image:
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    cropped = img.crop((left, top, left + side, top + side))
    return cropped.resize((size, size), RESAMPLE)


def write_png(img: Image.Image, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    force_corner_alpha_zero(ensure_rgba(img)).save(dest, format="PNG", optimize=True)


def estimate_background_rgb(img: Image.Image) -> tuple[int, int, int]:
    rgb = ensure_rgba(img).convert("RGB")
    w, h = rgb.size
    corners = [
        rgb.getpixel((0, 0)),
        rgb.getpixel((w - 1, 0)),
        rgb.getpixel((0, h - 1)),
        rgb.getpixel((w - 1, h - 1)),
    ]
    return (
        sum(c[0] for c in corners) // 4,
        sum(c[1] for c in corners) // 4,
        sum(c[2] for c in corners) // 4,
    )


def remove_background(img: Image.Image, tolerance: int = 36) -> Image.Image:
    """Key neutral sheet backdrop to transparent alpha."""
    return clean_sprite_cutout(img, bg_tolerance=tolerance)


def find_components(img: Image.Image, min_pixels: int = 800) -> list[BBox]:
    rgba = ensure_rgba(img)
    rgb = rgba.convert("RGB")
    w, h = rgb.size
    bg = estimate_background_rgb(rgb)
    px = rgb.load()

    mask = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            dist = abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2])
            mask[y][x] = dist > 90

    visited = [[False] * w for _ in range(h)]
    components: list[BBox] = []

    for y in range(h):
        for x in range(w):
            if not mask[y][x] or visited[y][x]:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited[y][x] = True
            minx = maxx = x
            miny = maxy = y
            count = 0
            while queue:
                cx, cy = queue.popleft()
                count += 1
                minx = min(minx, cx)
                maxx = max(maxx, cx)
                miny = min(miny, cy)
                maxy = max(maxy, cy)
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if (
                        0 <= nx < w
                        and 0 <= ny < h
                        and mask[ny][nx]
                        and not visited[ny][nx]
                    ):
                        visited[ny][nx] = True
                        queue.append((nx, ny))

            if count >= min_pixels:
                components.append(BBox(minx, miny, maxx + 1, maxy + 1, count))

    components.sort(key=lambda c: (c.y0, c.x0))
    return components


def crop_component(img: Image.Image, bbox: BBox, pad: int = 4) -> Image.Image:
    rgba = ensure_rgba(img)
    w, h = rgba.size
    x0 = max(0, bbox.x0 - pad)
    y0 = max(0, bbox.y0 - pad)
    x1 = min(w, bbox.x1 + pad)
    y1 = min(h, bbox.y1 + pad)
    return rgba.crop((x0, y0, x1, y1))


def group_rows(components: list[BBox], row_gap: int = 80) -> list[list[BBox]]:
    if not components:
        return []

    rows: list[list[BBox]] = []
    centers: list[float] = []
    for comp in components:
        cy = comp.center_y
        placed = False
        for idx, row_cy in enumerate(centers):
            if abs(cy - row_cy) <= row_gap:
                rows[idx].append(comp)
                centers[idx] = sum(c.center_y for c in rows[idx]) / len(rows[idx])
                placed = True
                break
        if not placed:
            rows.append([comp])
            centers.append(cy)

    ordered_rows: list[list[BBox]] = []
    for _, row in sorted(zip(centers, rows), key=lambda item: item[0]):
        ordered_rows.append(sorted(row, key=lambda c: c.x0))
    return ordered_rows


def flatten_pose_order(components: list[BBox]) -> list[BBox]:
    rows = group_rows(components)
    return [pose for row in rows for pose in row]


def lower_row_poses(rows: list[list[BBox]]) -> list[BBox]:
    """All poses below the top row, in sheet order (row-major)."""
    if len(rows) <= 1:
        return list(rows[0]) if rows else []
    return [pose for row in rows[1:] for pose in row]


def is_hero_pose(bbox: BBox) -> bool:
    """Filter out tiny VFX particles that are not full character poses."""
    return (
        bbox.pixels >= MIN_HERO_POSE_PIXELS
        and min(bbox.width, bbox.height) >= MIN_HERO_POSE_EDGE
    )


def character_poses(components: list[BBox]) -> list[BBox]:
    return [bbox for bbox in components if is_hero_pose(bbox)]


def action_poses(rows: list[list[BBox]]) -> list[BBox]:
    """Lower-row combat/cast poses, excluding VFX particles."""
    return [pose for pose in lower_row_poses(rows) if is_hero_pose(pose)]


def pick(source: list[BBox], count: int, *, fallback: list[BBox]) -> list[BBox]:
    pool = source or fallback
    if not pool:
        return []
    if len(pool) >= count:
        return pool[:count]
    padded = list(pool)
    while len(padded) < count:
        padded.append(pool[-1])
    return padded


def poses_for_animation(components: list[BBox]) -> dict[str, list[BBox]]:
    """Map canon hero sheet rows to idle/jump/cast frames.

    Sheet layout (RO multi-pose):
      top row    -> front standing idle variants (+ side/back references)
      lower rows -> cast/attack poses; last pose is a run stride (not used for cast)

    Run frames are imported separately from art-canon/walk/.
    Canon provides no dedicated jump/air art; jump uses side/back top-row poses as
    a plausible airborne substitute (distinct from cast attack poses).
    """
    poses = character_poses(components)
    rows = group_rows(poses)
    if not rows:
        return {name: [] for name in HERO_ANIM_COUNTS}

    top = rows[0]
    actions = action_poses(rows)

    # Standing idle: first two front-facing poses on the top row.
    idle = pick(top, 2, fallback=top)

    # Air substitute: side/back references (canon has no jump frames).
    jump = pick(top[2:4] if len(top) >= 4 else top[2:], 2, fallback=idle)

    # Cast: attack-only poses (exclude trailing stride that reads as run).
    attack_only = actions[:2] if len(actions) >= 2 else actions
    cast = pick(attack_only, 3, fallback=top)

    return {
        "idle": idle,
        "jump": jump,
        "cast": cast,
    }


def import_hero_sheet(src: Path, hero_name: str, out_dir: Path) -> list[tuple[Path, tuple[int, int]]]:
    """Slice a multi-pose hero sheet into animation frames and hub assets."""
    results: list[tuple[Path, tuple[int, int]]] = []
    with Image.open(src) as raw:
        sheet = ensure_rgba(raw)

    components = find_components(sheet)
    if len(components) < 2:
        raise SystemExit(f"Expected multi-pose hero sheet for {src.name}, found {len(components)} pose(s)")

    pose_map = poses_for_animation(components)
    hero_dir = out_dir / "heroes" / hero_name

    for anim, bboxes in pose_map.items():
        count = HERO_ANIM_COUNTS[anim]
        for idx in range(count):
            bbox = bboxes[idx]
            frame = clean_sprite_cutout(
                resize_max_edge(crop_component(sheet, bbox), 96, resample=HERO_FRAME_RESAMPLE)
            )
            rel = Path("heroes") / hero_name / f"{anim}_{idx}.png"
            dest = out_dir / rel
            write_png(frame, dest)
            results.append((dest, frame.size))
            print(f"{src.name} -> {rel} ({frame.size[0]}x{frame.size[1]})")

    # Run frames are imported separately from art-canon/walk/ side-view cycles.

    preview = clean_sprite_cutout(
        resize_max_edge(crop_component(sheet, pose_map["idle"][0]), 128, resample=HERO_FRAME_RESAMPLE)
    )
    preview_rel = Path("heroes") / f"{hero_name}.png"
    preview_dest = out_dir / preview_rel
    write_png(preview, preview_dest)
    results.append((preview_dest, preview.size))
    print(f"{src.name} -> {preview_rel} ({preview.size[0]}x{preview.size[1]})")

    icon = resize_square_crop_fit(crop_component(sheet, pose_map["idle"][0]), 64)
    icon = clean_sprite_cutout(icon)
    icon_rel = Path("hub") / f"icon_{hero_name}.png"
    icon_dest = out_dir / icon_rel
    write_png(icon, icon_dest)
    results.append((icon_dest, icon.size))
    print(f"{src.name} -> {icon_rel} ({icon.size[0]}x{icon.size[1]})")

    return results


def import_creature(src: Path, rel_dest: Path, out_dir: Path, max_edge: int) -> tuple[Path, tuple[int, int]]:
    with Image.open(src) as raw:
        sheet = ensure_rgba(raw)

    components = find_components(sheet)
    if not components:
        keyed = remove_background(sheet)
        out = resize_max_edge(keyed, max_edge)
    else:
        main = max(components, key=lambda c: c.pixels)
        cutout = clean_sprite_cutout(
            resize_max_edge(crop_component(sheet, main), max_edge),
            preserve_soft_glow=True,
        )
        out = cutout

    dest = out_dir / rel_dest
    write_png(out, dest)
    print(f"{src.name} -> {rel_dest} ({out.size[0]}x{out.size[1]})")
    return dest, out.size


def dest_for_source(src: Path, canon_dir: Path | None = None) -> list[tuple[Path, int, str]]:
    """Return [(dest_path, max_edge, mode), ...] for a canon source file."""
    name = src.name
    stem = src.stem

    if name.startswith("hero-"):
        return []

    if name == "bg-town.png":
        return [(Path("hub") / "town_bg.png", 1920, "max_edge")]

    if name == "bg-fields-prontera.png":
        return [(Path("world") / "bg_fields.png", 1920, "max_edge")]

    if name == "bg-forest.png":
        return [(Path("world") / "bg_forest.png", 1920, "max_edge")]

    if name == "ground-tile-v4.png":
        return [(Path("world") / "ground_tile.png", 256, "max_edge")]

    if name == "ground-tile-v3.png":
        if canon_dir and (canon_dir / "ground-tile-v4.png").is_file():
            return []
        return [(Path("world") / "ground_tile.png", 256, "max_edge")]

    if name == "ground-tile-v2.png":
        if canon_dir and (
            (canon_dir / "ground-tile-v4.png").is_file()
            or (canon_dir / "ground-tile-v3.png").is_file()
        ):
            return []
        return [(Path("world") / "ground_tile.png", 256, "max_edge")]

    if name == "ground-tile.png":
        if canon_dir and (
            (canon_dir / "ground-tile-v4.png").is_file()
            or (canon_dir / "ground-tile-v3.png").is_file()
            or (canon_dir / "ground-tile-v2.png").is_file()
        ):
            return []
        return [(Path("world") / "ground_tile.png", 256, "max_edge")]

    if name.startswith("mob-"):
        mob_name = stem.removeprefix("mob-")
        if canon_dir and (canon_dir / "monster-video" / mob_name).is_dir():
            return []
        return [(Path("enemies") / f"{mob_name}.png", 96, "creature")]

    if name.startswith("boss-"):
        boss_name = stem.removeprefix("boss-")
        kind_name = f"boss_{boss_name}"
        if canon_dir and (canon_dir / "monster-video" / kind_name).is_dir():
            return []
        return [(Path("enemies") / f"boss_{boss_name}.png", 160, "creature")]

    if name == "prop-chest.png":
        if canon_dir and (canon_dir / "prop-video" / "chest").is_dir():
            return []
        return [(Path("props") / "chest.png", 96, "creature")]

    if name.startswith("proj-"):
        proj_name = stem.removeprefix("proj-")
        filename = PROJECTILE_NAMES.get(proj_name, f"{proj_name}.png")
        return [(Path("projectiles") / filename, 64, "creature")]

    if name.startswith("ui-btn-"):
        btn_name = stem.removeprefix("ui-btn-")
        return [(Path("ui") / f"btn_{btn_name}.png", 128, "max_edge")]

    return []


def process_image(src: Path, dest: Path, max_edge: int, mode: str) -> tuple[int, int]:
    with Image.open(src) as raw:
        img = ensure_rgba(raw)
        if mode == "square":
            out = resize_square_crop_fit(img, max_edge)
        elif mode == "creature":
            components = find_components(img)
            if components:
                main = max(components, key=lambda c: c.pixels)
                out = clean_sprite_cutout(
                    resize_max_edge(crop_component(img, main), max_edge),
                    preserve_soft_glow=True,
                )
            else:
                out = clean_sprite_cutout(
                    resize_max_edge(remove_background(img), max_edge),
                    preserve_soft_glow=True,
                )
        else:
            out = resize_max_edge(img, max_edge)
        write_png(out, dest)
        return out.size


def _import_archer_video_frames(
    video_dir: Path,
    out_dir: Path,
    *,
    prefix: str,
    count: int,
) -> list[tuple[Path, Path, tuple[int, int]]]:
    """Import one archer-video-v2 animation cycle (pre-keyed alpha, passthrough at 192px)."""
    results: list[tuple[Path, Path, tuple[int, int]]] = []
    hero_dir = out_dir / "heroes" / "archer"
    anim_dir = video_dir / prefix

    for idx in range(count):
        src = anim_dir / f"{prefix}_{idx}.png"
        if not src.is_file():
            raise SystemExit(f"Missing archer-video-v2 frame: {src}")
        with Image.open(src) as raw:
            frame = ensure_rgba(raw.copy())
        rel = Path("heroes") / "archer" / f"{prefix}_{idx}.png"
        dest = out_dir / rel
        write_png(frame, dest)
        results.append((src, dest, frame.size))
        print(f"{src.name} -> {rel} ({frame.size[0]}x{frame.size[1]})")

    if hero_dir.is_dir():
        for stale in hero_dir.glob(f"{prefix}_*.png"):
            stale_idx = int(stale.stem.removeprefix(f"{prefix}_"))
            if stale_idx >= count:
                stale.unlink()
                print(f"removed stale {prefix} frame: {stale.name}")

    return results


def import_archer_video_if_present(
    canon_dir: Path, out_dir: Path
) -> list[tuple[Path, Path, tuple[int, int]]]:
    """Import archer idle/run/jump/cast from art-canon/archer-video-v2/ (pre-keyed alpha)."""
    video_dir = canon_dir / "archer-video-v2"
    if not video_dir.is_dir():
        return []

    results: list[tuple[Path, Path, tuple[int, int]]] = []
    idle_0: Image.Image | None = None

    for prefix, count in ARCHER_VIDEO_ANIMS.items():
        batch = _import_archer_video_frames(video_dir, out_dir, prefix=prefix, count=count)
        results.extend(batch)
        if prefix == "idle" and batch:
            with Image.open(batch[0][1]) as img:
                idle_0 = ensure_rgba(img.copy())

    if idle_0 is None:
        raise SystemExit("archer-video-v2 import produced no idle_0 frame")

    preview_rel = Path("heroes") / "archer.png"
    preview_dest = out_dir / preview_rel
    write_png(idle_0, preview_dest)
    results.append((video_dir / "idle" / "idle_0.png", preview_dest, idle_0.size))
    print(f"idle_0.png -> {preview_rel} ({idle_0.size[0]}x{idle_0.size[1]})")

    icon = make_bottom_aligned_icon(idle_0, 64)
    icon_rel = Path("hub") / "icon_archer.png"
    icon_dest = out_dir / icon_rel
    write_png(icon, icon_dest)
    results.append((video_dir / "idle" / "idle_0.png", icon_dest, icon.size))
    print(f"idle_0.png -> {icon_rel} ({icon.size[0]}x{icon.size[1]})")

    return results


def import_monster_video_if_present(
    canon_dir: Path, out_dir: Path
) -> list[tuple[Path, Path, tuple[int, int]]]:
    """Import monster walk cycles from art-canon/monster-video/<kind>/ (pre-keyed alpha)."""
    video_root = canon_dir / "monster-video"
    if not video_root.is_dir():
        return []

    results: list[tuple[Path, Path, tuple[int, int]]] = []
    for kind_name, anims in MONSTER_VIDEO_ANIMS.items():
        kind_dir = video_root / kind_name
        if not kind_dir.is_dir():
            raise SystemExit(f"Missing monster-video source dir: {kind_dir}")

        walk_0: Image.Image | None = None
        kind_out = out_dir / "enemies" / kind_name

        for prefix, count in anims.items():
            for idx in range(count):
                src = kind_dir / f"{prefix}_{idx}.png"
                if not src.is_file():
                    raise SystemExit(f"Missing monster-video frame: {src}")
                with Image.open(src) as raw:
                    frame = ensure_rgba(raw.copy())
                rel = Path("enemies") / kind_name / f"{prefix}_{idx}.png"
                dest = out_dir / rel
                write_png(frame, dest)
                results.append((src, dest, frame.size))
                print(f"{src.name} -> {rel} ({frame.size[0]}x{frame.size[1]})")
                if prefix == "walk" and idx == 0:
                    walk_0 = frame

            if kind_out.is_dir():
                for stale in kind_out.glob(f"{prefix}_*.png"):
                    stale_idx = int(stale.stem.removeprefix(f"{prefix}_"))
                    if stale_idx >= count:
                        stale.unlink()
                        print(f"removed stale {kind_name} {prefix} frame: {stale.name}")

        if walk_0 is not None:
            poster_rel = Path("enemies") / f"{kind_name}.png"
            poster_dest = out_dir / poster_rel
            write_png(walk_0, poster_dest)
            results.append((kind_dir / "walk_0.png", poster_dest, walk_0.size))
            print(
                f"walk_0.png -> {poster_rel} ({walk_0.size[0]}x{walk_0.size[1]})"
            )

    return results


def import_prop_video_if_present(
    canon_dir: Path, out_dir: Path
) -> list[tuple[Path, Path, tuple[int, int]]]:
    """Import prop animations from art-canon/prop-video/<kind>/ (pre-keyed alpha)."""
    video_root = canon_dir / "prop-video"
    if not video_root.is_dir():
        return []

    results: list[tuple[Path, Path, tuple[int, int]]] = []
    for kind_name, anims in PROP_VIDEO_ANIMS.items():
        kind_dir = video_root / kind_name
        if not kind_dir.is_dir():
            raise SystemExit(f"Missing prop-video source dir: {kind_dir}")

        kind_out = out_dir / "props" / kind_name

        for prefix, count in anims.items():
            for idx in range(count):
                src = kind_dir / f"{prefix}_{idx}.png"
                if not src.is_file():
                    raise SystemExit(f"Missing prop-video frame: {src}")
                with Image.open(src) as raw:
                    frame = ensure_rgba(raw.copy())
                rel = Path("props") / kind_name / f"{prefix}_{idx}.png"
                dest = out_dir / rel
                write_png(frame, dest)
                results.append((src, dest, frame.size))
                print(f"{src.name} -> {rel} ({frame.size[0]}x{frame.size[1]})")

            if kind_out.is_dir():
                for stale in kind_out.glob(f"{prefix}_*.png"):
                    stale_idx = int(stale.stem.removeprefix(f"{prefix}_"))
                    if stale_idx >= count:
                        stale.unlink()
                        print(f"removed stale {kind_name} {prefix} frame: {stale.name}")

    return results


def import_walk_cycles_if_present(canon_dir: Path, out_dir: Path) -> list[tuple[Path, Path, tuple[int, int]]]:
    """Import run frames from art-canon/walk/ for mage/paladin (archer uses archer-video)."""
    walk_dir = canon_dir / "walk"
    if not walk_dir.is_dir():
        return []

    from import_walk_cycles import import_walk_cycles

    results: list[tuple[Path, Path, tuple[int, int]]] = []
    for src, dest in import_walk_cycles(walk_dir, out_dir):
        with Image.open(dest) as img:
            results.append((src, dest, img.size))
    return results


def import_canon(canon_dir: Path, out_dir: Path) -> list[tuple[Path, Path, tuple[int, int]]]:
    """Import all mapped canon PNGs. Returns [(src, dest, (w, h)), ...]."""
    results: list[tuple[Path, Path, tuple[int, int]]] = []
    sources = sorted(canon_dir.glob("*.png"))

    for src in sources:
        if src.name.startswith("hero-"):
            hero_name = src.stem.removeprefix("hero-")
            # Archer frames come from archer-video, not sheet slices or walk dir.
            if hero_name == "archer":
                print(f"skip sheet slice: {src.name} (archer-video-v2 import)")
                continue
            for dest, size in import_hero_sheet(src, hero_name, out_dir):
                results.append((src, dest, size))
            continue

        mappings = dest_for_source(src, canon_dir)
        if not mappings:
            print(f"skip (no mapping): {src.name}")
            continue

        for rel_dest, max_edge, mode in mappings:
            dest = out_dir / rel_dest
            if mode == "creature":
                _, size = import_creature(src, rel_dest, out_dir, max_edge)
            else:
                size = process_image(src, dest, max_edge, mode)
            results.append((src, dest, size))
            if mode != "creature":
                print(f"{src.name} -> {rel_dest} ({size[0]}x{size[1]})")

    results.extend(import_walk_cycles_if_present(canon_dir, out_dir))
    results.extend(import_archer_video_if_present(canon_dir, out_dir))
    results.extend(import_monster_video_if_present(canon_dir, out_dir))
    results.extend(import_prop_video_if_present(canon_dir, out_dir))
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
