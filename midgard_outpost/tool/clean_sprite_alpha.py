#!/usr/bin/env python3
"""Alpha hygiene helpers for canon sprite import."""

from __future__ import annotations

from collections import deque
from typing import Callable

from PIL import Image


def is_neutral_gray(r: int, g: int, b: int, a: int) -> bool:
    """Detect backdrop/shadow gray that should not remain in cutouts."""
    if a == 0:
        return False
    avg = (r + g + b) / 3
    return abs(r - g) <= 20 and abs(g - b) <= 20 and 70 <= avg <= 205


def is_backdrop_pixel(
    r: int,
    g: int,
    b: int,
    a: int,
    bg: tuple[int, int, int],
    tolerance: int,
) -> bool:
    if a == 0:
        return False
    dist = abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2])
    return dist <= tolerance * 3


def force_corner_alpha_zero(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        r, g, b, _ = px[x, y]
        px[x, y] = (r, g, b, 0)
    return rgba


def remove_floor_shadow(img: Image.Image, floor_fraction: float = 0.76) -> Image.Image:
    """Strip baked gray drop-shadow ovals under character feet (edge-connected only)."""
    rgba = img.convert("RGBA")
    floor_y = int(rgba.height * floor_fraction)
    bg = _estimate_background_rgb(rgba)

    def removable(r: int, g: int, b: int, a: int, y: int) -> bool:
        if y < floor_y:
            return False
        return is_neutral_gray(r, g, b, a) or is_backdrop_pixel(r, g, b, a, bg, 36)

    return _flood_remove(rgba, removable)


def defringe_backdrop(
    img: Image.Image,
    tolerance: int = 42,
    alpha_cutoff: int = 140,
) -> Image.Image:
    """Remove exterior backdrop/gray residue and binarize fringe alpha only."""
    rgba = img.convert("RGBA")
    bg = _estimate_background_rgb(rgba)

    def removable(r: int, g: int, b: int, a: int, _y: int) -> bool:
        return is_backdrop_pixel(r, g, b, a, bg, tolerance) or is_neutral_gray(r, g, b, a)

    rgba = _flood_remove(rgba, removable)
    return _binarize_fringe_alpha(rgba, alpha_cutoff=alpha_cutoff)


def clean_chroma_sprite(img: Image.Image) -> Image.Image:
    """Single-pass cleanup for magenta-chroma walk frames (no backdrop re-key)."""
    rgba = remove_floor_shadow(img)
    rgba = _binarize_fringe_alpha(rgba)
    return force_corner_alpha_zero(rgba)


def clean_sprite_cutout(
    img: Image.Image,
    *,
    bg_tolerance: int = 36,
    preserve_soft_glow: bool = False,
) -> Image.Image:
    """Full alpha cleanup pipeline for hero/enemy cutouts."""
    rgba = img.convert("RGBA")
    rgba = _remove_background(rgba, tolerance=bg_tolerance)
    rgba = remove_floor_shadow(rgba)
    if preserve_soft_glow:
        rgba = _remove_exterior_fringe(rgba, bg_tolerance=bg_tolerance)
    else:
        rgba = defringe_backdrop(rgba, tolerance=bg_tolerance + 6)
    return force_corner_alpha_zero(rgba)


def count_semi_transparent_pixels(img: Image.Image) -> int:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    return sum(
        1
        for y in range(h)
        for x in range(w)
        if 0 < px[x, y][3] < 255
    )


def count_neutral_gray_opaque(img: Image.Image) -> int:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    return sum(
        1
        for y in range(h)
        for x in range(w)
        if is_neutral_gray(*px[x, y])
    )


def count_exterior_neutral_gray(img: Image.Image) -> int:
    """Neutral gray on the outer fringe (adjacent to transparency)."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    fringe_gray = 0

    for y in range(h):
        for x in range(w):
            if not is_neutral_gray(*px[x, y]):
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                    fringe_gray += 1
                    break

    return fringe_gray


def count_opaque_in_center(img: Image.Image, margin_fraction: float = 0.25) -> int:
    """Opaque pixels in the central band (interior detail guard)."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    x0 = int(w * margin_fraction)
    x1 = int(w * (1 - margin_fraction))
    y0 = int(h * margin_fraction)
    y1 = int(h * (1 - margin_fraction))
    return sum(
        1
        for y in range(y0, y1)
        for x in range(x0, x1)
        if px[x, y][3] > 0
    )


def _estimate_background_rgb(img: Image.Image) -> tuple[int, int, int]:
    rgb = img.convert("RGB")
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


def _remove_background(img: Image.Image, tolerance: int) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    bg = _estimate_background_rgb(rgba)
    limit = tolerance * 3

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            dist = abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2])
            if dist <= limit:
                px[x, y] = (r, g, b, 0)

    return rgba


def _flood_remove(
    rgba: Image.Image,
    removable: Callable[[int, int, int, int, int], bool],
) -> Image.Image:
    """Remove pixels reachable from transparent pixels or image borders."""
    px = rgba.load()
    w, h = rgba.size
    marked = [[False] * w for _ in range(h)]
    queue: deque[tuple[int, int]] = deque()

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                marked[y][x] = True
                queue.append((x, y))
            elif x == 0 or x == w - 1 or y == 0 or y == h - 1:
                if removable(r, g, b, a, y):
                    marked[y][x] = True
                    queue.append((x, y))

    while queue:
        cx, cy = queue.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = cx + dx, cy + dy
            if not (0 <= nx < w and 0 <= ny < h) or marked[ny][nx]:
                continue
            r, g, b, a = px[nx, ny]
            if removable(r, g, b, a, ny):
                marked[ny][nx] = True
                queue.append((nx, ny))

    for y in range(h):
        for x in range(w):
            if marked[y][x]:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 0)

    return rgba


def _remove_exterior_fringe(img: Image.Image, bg_tolerance: int) -> Image.Image:
    rgba = img.convert("RGBA")
    bg = _estimate_background_rgb(rgba)

    def removable(r: int, g: int, b: int, a: int, _y: int) -> bool:
        return is_backdrop_pixel(r, g, b, a, bg, bg_tolerance) or (
            is_neutral_gray(r, g, b, a) and a < 240
        )

    return _flood_remove(rgba, removable)


def _binarize_fringe_alpha(img: Image.Image, alpha_cutoff: int = 140) -> Image.Image:
    """Snap semi-transparent pixels adjacent to transparency; keep interior soft pixels."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0 or a == 255:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                    if a < alpha_cutoff:
                        px[x, y] = (r, g, b, 0)
                    else:
                        px[x, y] = (r, g, b, 255)
                    break

    return rgba
