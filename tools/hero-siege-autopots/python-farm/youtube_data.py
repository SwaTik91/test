"""Build a WASD dataset from video frames (YouTube or a local file).

YouTube has no key log. Labels come from minimap motion: the hero icon moving,
or the map sliding under a centered icon.
"""

from __future__ import annotations

from collections.abc import Iterable

import numpy as np

from nav import (
    FLOOR,
    FOG,
    WALL,
    _best_compact_blob,
    classify_rgb,
    find_player_cell,
    luma_rgb,
    to_grid,
)

KEYS = ("w", "a", "s", "d")


def _nn_resize(img: np.ndarray, new_h: int, new_w: int) -> np.ndarray:
    h, w = img.shape[:2]
    yy = np.clip((np.arange(new_h) * h / new_h).astype(np.int32), 0, h - 1)
    xx = np.clip((np.arange(new_w) * w / new_w).astype(np.int32), 0, w - 1)
    return img[yy[:, None], xx]


def has_gameplay_hud(frame: np.ndarray) -> bool:
    """True when the Hero Siege HP bar is visible in the top-left (not intro/webcam)."""
    h, w = frame.shape[:2]
    y1, x1 = 2, 2
    y2, x2 = max(y1 + 1, int(h * 0.18)), max(x1 + 1, int(w * 0.32))
    rgn = frame[y1:y2, x1:x2]
    if rgn.size == 0:
        return False
    r = rgn[..., 0].astype(np.int16)
    g = rgn[..., 1].astype(np.int16)
    b = rgn[..., 2].astype(np.int16)
    red = (r > 140) & (r > g + 40) & (r > b + 40)
    if float(red.mean()) < 0.015:
        return False
    return float(red.mean(axis=1).max()) >= 0.16


def hero_siege_minimap_box(h: int, w: int) -> tuple[int, int, int, int]:
    """Hero Siege 2.0 radar: square, top-right, scaled from 640×360 HUD."""
    side = max(16, int(round(w * 64 / 640)))
    right_pad = max(2, int(round(w * 12 / 640)))
    top_pad = max(2, int(round(h * 7 / 360)))
    x2 = w - right_pad
    y1 = top_pad
    x1 = x2 - side
    y2 = y1 + side
    return max(0, x1), y1, x2, min(h, y2)


def crop_looks_like_radar(crop: np.ndarray) -> bool:
    """Radar is mostly dark with some brighter pixels; photos in that corner are brighter."""
    lu = luma_rgb(crop)
    dark = float((lu <= 40).mean())
    structure = float((lu >= 70).mean())
    return dark >= 0.20 and structure >= 0.002


def find_minimap(frame: np.ndarray) -> tuple[int, int, int, int] | None:
    """Square HUD map, usually top-right. Returns x1,y1,x2,y2 in frame pixels."""
    if has_gameplay_hud(frame):
        return hero_siege_minimap_box(frame.shape[0], frame.shape[1])
    h, w = frame.shape[:2]
    scale = 1.0
    work = frame
    if w > 480:
        scale = 480 / w
        work = _nn_resize(frame, max(1, int(h * scale)), 480)
    wh, ww = work.shape[:2]
    cls = classify_rgb(work)
    wall = cls == WALL
    fog = cls == FOG
    floor = cls == FLOOR
    x0 = int(ww * 0.50)
    region_h = int(wh * 0.55)
    min_side = max(16, int(min(wh, ww) * 0.10))
    max_side = min(region_h, ww - x0, int(min(wh, ww) * 0.42))
    if max_side < min_side:
        return None
    best: tuple[float, int, int, int] | None = None
    step_side = max(4, max(1, (max_side - min_side) // 8))
    for side in range(min_side, max_side + 1, step_side):
        step = max(4, side // 5)
        for y in range(0, region_h - side + 1, step):
            for x in range(x0, ww - side + 1, step):
                sl = np.s_[y : y + side, x : x + side]
                ww_m = float(wall[sl].mean())
                ff = float(fog[sl].mean())
                fl = float(floor[sl].mean())
                if ww_m < 0.015 or ff < 0.04 or fl < 0.05:
                    continue
                score = min(ww_m, 0.2) * 3.0 + min(ff, 0.4) + min(fl, 0.5)
                if best is None or score > best[0]:
                    best = (score, y, x, side)
    if best is None:
        side = max(16, int(min(h, w) * 0.18))
        x1 = max(0, w - side - int(w * 0.02))
        y1 = max(0, int(h * 0.02))
        return x1, y1, min(w, x1 + side), min(h, y1 + side)
    _, y, x, side = best
    if scale != 1.0:
        inv = 1.0 / scale
        y, x, side = int(y * inv), int(x * inv), int(side * inv)
    return x, y, x + side, y + side


def crop_box(frame: np.ndarray, box: tuple[int, int, int, int]) -> np.ndarray | None:
    x1, y1, x2, y2 = box
    x1, x2 = max(0, x1), min(frame.shape[1], x2)
    y1, y2 = max(0, y1), min(frame.shape[0], y2)
    if x2 - x1 < 16 or y2 - y1 < 16:
        return None
    return frame[y1:y2, x1:x2]


def _to_cell(pix: tuple[int, int] | None, grid: np.ndarray, cell: int) -> tuple[int, int] | None:
    if pix is None or grid.size == 0:
        return None
    gy = min(grid.shape[0] - 1, max(0, pix[0] // cell))
    gx = min(grid.shape[1] - 1, max(0, pix[1] // cell))
    return gy, gx


def _player_cell_video(rgb: np.ndarray, grid: np.ndarray, cell: int = 2) -> tuple[int, int] | None:
    """360p / compressed radar: hero icon is a few mid-bright pixels, not gold."""
    r = rgb[..., 0].astype(np.int16)
    g = rgb[..., 1].astype(np.int16)
    b = rgb[..., 2].astype(np.int16)
    lu = luma_rgb(rgb)
    yellow = (r >= 140) & (g >= 110) & (b <= 150) & ((g - b) >= 12)
    pix = _best_compact_blob(yellow, min_n=1, max_n=40, max_aspect=4.0, max_side=10)
    if pix is None:
        chroma = np.maximum(np.abs(r - g), np.maximum(np.abs(g - b), np.abs(r - b)))
        bright = (lu >= 105) & (chroma <= 55)
        pix = _best_compact_blob(bright, min_n=1, max_n=24, max_aspect=2.8, max_side=10)
    return _to_cell(pix, grid, cell)


def _player_cell(rgb: np.ndarray) -> tuple[int, int] | None:
    grid = to_grid(classify_rgb(rgb), cell=2)
    pix = find_player_cell(rgb, grid, 2)
    if pix is not None:
        return pix
    return _player_cell_video(rgb, grid, 2)


def _luma(rgb: np.ndarray) -> np.ndarray:
    r = rgb[..., 0].astype(np.int32)
    g = rgb[..., 1].astype(np.int32)
    b = rgb[..., 2].astype(np.int32)
    return (r * 2 + g * 3 + b) // 6


def _sad_shift(la: np.ndarray, lb: np.ndarray, dy: int, dx: int) -> float:
    h, w = la.shape
    ay0, ax0 = max(0, -dy), max(0, -dx)
    ay1, ax1 = min(h, h - dy), min(w, w - dx)
    if ay1 - ay0 < h // 3 or ax1 - ax0 < w // 3:
        return 1e18
    aa = la[ay0:ay1, ax0:ax1]
    bb = lb[ay0 + dy : ay1 + dy, ax0 + dx : ax1 + dx]
    return float(np.mean(np.abs(aa.astype(np.int32) - bb.astype(np.int32))))


def _scroll_shift(a: np.ndarray, b: np.ndarray, max_shift: int = 10) -> tuple[int, int]:
    la, lb = _luma(a), _luma(b)
    best = (1e18, 0, 0)
    for dy in range(-max_shift, max_shift + 1, 2):
        for dx in range(-max_shift, max_shift + 1, 2):
            s = _sad_shift(la, lb, dy, dx)
            if s < best[0]:
                best = (s, dy, dx)
    return best[1], best[2]


def label_from_motion(prev: np.ndarray, cur: np.ndarray) -> str | None:
    """WASD implied by hero-icon motion, else by radar map scroll."""
    pa, pb = _player_cell(prev), _player_cell(cur)
    if pa is not None and pb is not None:
        dy, dx = pb[0] - pa[0], pb[1] - pa[1]
        if abs(dx) + abs(dy) >= 1:
            if abs(dx) > abs(dy):
                return "d" if dx > 0 else "a"
            if abs(dy) > abs(dx):
                return "s" if dy > 0 else "w"
            return None
    la, lb = _luma(prev), _luma(cur)
    s0 = _sad_shift(la, lb, 0, 0)
    dy, dx = _scroll_shift(prev, cur)
    s1 = _sad_shift(la, lb, dy, dx)
    if abs(dx) + abs(dy) < 2 or s1 >= s0 * 0.75:
        return None
    # Shift that aligns prev onto cur: content moved that way, player walked opposite.
    if abs(dx) > abs(dy):
        return "a" if dx > 0 else "d"
    return "w" if dy > 0 else "s"


def pairs_to_dataset(
    frames: Iterable[np.ndarray],
    box: tuple[int, int, int, int] | None = None,
) -> tuple[list[np.ndarray], list[str]]:
    crops: list[np.ndarray] = []
    labels: list[str] = []
    prev = None
    locked = box
    for frame in frames:
        if not has_gameplay_hud(frame):
            prev = None
            continue
        if locked is None:
            locked = hero_siege_minimap_box(frame.shape[0], frame.shape[1])
        crop = crop_box(frame, locked)
        if crop is None or not crop_looks_like_radar(crop):
            prev = None
            continue
        if prev is not None:
            lab = label_from_motion(prev, crop)
            if lab is not None:
                crops.append(prev.copy())
                labels.append(lab)
        prev = crop
    return crops, labels
