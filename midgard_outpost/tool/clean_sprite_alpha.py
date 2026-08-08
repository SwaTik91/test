#!/usr/bin/env python3
"""Alpha hygiene helpers for canon sprite import."""

from __future__ import annotations

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
    """Strip baked gray drop-shadow ovals under character feet."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    floor_y = int(h * floor_fraction)

    for y in range(floor_y, h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if is_neutral_gray(r, g, b, a):
                px[x, y] = (r, g, b, 0)

    return rgba


def defringe_backdrop(
    img: Image.Image,
    tolerance: int = 42,
    alpha_cutoff: int = 140,
) -> Image.Image:
    """Remove soft backdrop residue and binarize alpha for crisp sprite edges."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    bg = _estimate_background_rgb(rgba)

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if is_backdrop_pixel(r, g, b, a, bg, tolerance) or is_neutral_gray(r, g, b, a):
                px[x, y] = (r, g, b, 0)
                continue
            if a < alpha_cutoff:
                px[x, y] = (r, g, b, 0)
            elif a < 255:
                px[x, y] = (r, g, b, 255)

    return rgba


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
        rgba = _remove_neutral_fringe(rgba, bg_tolerance=bg_tolerance)
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


def _remove_neutral_fringe(img: Image.Image, bg_tolerance: int) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    bg = _estimate_background_rgb(rgba)

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if is_backdrop_pixel(r, g, b, a, bg, bg_tolerance) or (
                is_neutral_gray(r, g, b, a) and a < 240
            ):
                px[x, y] = (r, g, b, 0)

    return rgba
