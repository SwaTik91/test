"""Minimap grid + A* for Hero Siege. No Windows APIs — unit-testable."""

from __future__ import annotations

from collections import deque
from heapq import heappop, heappush

import numpy as np

FLOOR, WALL, FOG = 0, 1, 2

# 4-way: (drow, dcol, key)  row grows down, col grows right
STEPS = (
    (-1, 0, "w"),
    (1, 0, "s"),
    (0, -1, "a"),
    (0, 1, "d"),
)
DELTA = {"w": (-1, 0), "s": (1, 0), "a": (0, -1), "d": (0, 1)}


def luma_rgb(rgb: np.ndarray) -> np.ndarray:
    r = rgb[..., 0].astype(np.int32)
    g = rgb[..., 1].astype(np.int32)
    b = rgb[..., 2].astype(np.int32)
    return (r * 2 + g * 3 + b) // 6


def classify_rgb(rgb: np.ndarray) -> np.ndarray:
    """rgb: HxWx3 uint8. White/gray lines = WALL, dark = FOG, else FLOOR."""
    out = np.full(rgb.shape[:2], FLOOR, dtype=np.uint8)
    r = rgb[..., 0].astype(np.int16)
    g = rgb[..., 1].astype(np.int16)
    b = rgb[..., 2].astype(np.int16)
    lu = luma_rgb(rgb)
    chroma = np.maximum(np.abs(r - g), np.maximum(np.abs(g - b), np.abs(r - b)))
    wall = (lu >= 165) & (chroma <= 40)
    fog = lu <= 28
    out[fog] = FOG
    out[wall] = WALL
    return out


def to_grid(cls: np.ndarray, cell: int = 3) -> np.ndarray:
    """Downsample. Any wall in a cell stays a wall so 1px white lines survive."""
    h, w = cls.shape
    gh, gw = max(1, h // cell), max(1, w // cell)
    grid = np.full((gh, gw), FOG, dtype=np.uint8)
    for gy in range(gh):
        for gx in range(gw):
            block = cls[gy * cell : (gy + 1) * cell, gx * cell : (gx + 1) * cell]
            if np.any(block == WALL):
                grid[gy, gx] = WALL
            elif np.any(block == FLOOR):
                grid[gy, gx] = FLOOR
            else:
                grid[gy, gx] = FOG
    return grid


def walkable(grid: np.ndarray) -> np.ndarray:
    return grid != WALL


def _flood_blob(mask: np.ndarray, y0: int, x0: int, seen: np.ndarray) -> list[tuple[int, int]]:
    h, w = mask.shape
    cells: list[tuple[int, int]] = []
    q = deque([(y0, x0)])
    seen[y0, x0] = True
    while q:
        y, x = q.popleft()
        cells.append((y, x))
        for dy, dx, _ in STEPS:
            ny, nx = y + dy, x + dx
            if ny < 0 or nx < 0 or ny >= h or nx >= w:
                continue
            if seen[ny, nx] or not mask[ny, nx]:
                continue
            seen[ny, nx] = True
            q.append((ny, nx))
    return cells


def _best_compact_blob(
    mask: np.ndarray,
    *,
    min_n: int,
    max_n: int,
    max_aspect: float,
    max_side: int | None = None,
) -> tuple[int, int] | None:
    h, w = mask.shape
    seen = np.zeros(mask.shape, dtype=bool)
    best: tuple[float, int, int] | None = None
    for y, x in np.argwhere(mask):
        y, x = int(y), int(x)
        if seen[y, x]:
            continue
        blob = _flood_blob(mask, y, x, seen)
        n = len(blob)
        ys = [p[0] for p in blob]
        xs = [p[1] for p in blob]
        touch = min(ys) == 0 or min(xs) == 0 or max(ys) == h - 1 or max(xs) == w - 1
        if touch or n < min_n or n > max_n:
            continue
        bh = max(ys) - min(ys) + 1
        bw = max(xs) - min(xs) + 1
        if max(bh, bw) / max(1, min(bh, bw)) > max_aspect:
            continue
        if max_side is not None and max(bh, bw) > max_side:
            continue
        cy = int(round(sum(ys) / n))
        cx = int(round(sum(xs) / n))
        score = n * n / (bh * bw)
        if best is None or score > best[0]:
            best = (score, cy, cx)
    if best is None:
        return None
    return best[1], best[2]


def find_player_cell(rgb: np.ndarray, grid: np.ndarray, cell: int) -> tuple[int, int] | None:
    """Hero icon: yellow/gold blob, else a small compact white square (not wall lines)."""
    r = rgb[..., 0].astype(np.int16)
    g = rgb[..., 1].astype(np.int16)
    b = rgb[..., 2].astype(np.int16)
    yellow = (r >= 190) & (g >= 170) & (b <= 110) & ((r - g) <= 55) & ((g - b) >= 40)
    pix = _best_compact_blob(yellow, min_n=4, max_n=280, max_aspect=4.0)
    if pix is None:
        lu = luma_rgb(rgb)
        chroma = np.maximum(np.abs(r - g), np.maximum(np.abs(g - b), np.abs(r - b)))
        white = (lu >= 200) & (chroma <= 40)
        pix = _best_compact_blob(white, min_n=4, max_n=80, max_aspect=2.2, max_side=12)
    if pix is None:
        return None
    gy = min(grid.shape[0] - 1, max(0, pix[0] // cell))
    gx = min(grid.shape[1] - 1, max(0, pix[1] // cell))
    return gy, gx


def snap_walkable(grid: np.ndarray, start: tuple[int, int], radius: int = 6) -> tuple[int, int] | None:
    h, w = grid.shape
    sy, sx = start
    if 0 <= sy < h and 0 <= sx < w and grid[sy, sx] != WALL:
        return sy, sx
    for r in range(1, radius + 1):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                y, x = sy + dy, sx + dx
                if 0 <= y < h and 0 <= x < w and grid[y, x] != WALL:
                    return y, x
    return None


def _is_fog_speck(grid: np.ndarray, y: int, x: int) -> bool:
    """Single dark pixel in the middle of a room is noise, not unexplored."""
    h, w = grid.shape
    fog_n = floor_n = 0
    for dy, dx, _ in STEPS:
        ny, nx = y + dy, x + dx
        if ny < 0 or nx < 0 or ny >= h or nx >= w:
            continue
        if grid[ny, nx] == FOG:
            fog_n += 1
        elif grid[ny, nx] == FLOOR:
            floor_n += 1
    return fog_n == 0 and floor_n >= 3


def nearest_fog(grid: np.ndarray, start: tuple[int, int]) -> tuple[int, int] | None:
    """BFS through non-walls; first real fog cell that is not the start."""
    h, w = grid.shape
    sy, sx = start
    if not (0 <= sy < h and 0 <= sx < w) or grid[sy, sx] == WALL:
        return None
    seen = np.zeros_like(grid, dtype=bool)
    q = deque([(sy, sx)])
    seen[sy, sx] = True
    fallback: tuple[int, int] | None = None
    while q:
        y, x = q.popleft()
        if grid[y, x] == FOG and (y, x) != (sy, sx):
            if not _is_fog_speck(grid, y, x):
                return y, x
            if fallback is None:
                fallback = (y, x)
        for dy, dx, _ in STEPS:
            ny, nx = y + dy, x + dx
            if ny < 0 or nx < 0 or ny >= h or nx >= w:
                continue
            if seen[ny, nx] or grid[ny, nx] == WALL:
                continue
            seen[ny, nx] = True
            q.append((ny, nx))
    return fallback


def astar(grid: np.ndarray, start: tuple[int, int], goal: tuple[int, int]) -> list[tuple[int, int]]:
    h, w = grid.shape
    sy, sx = start
    gy, gx = goal
    if grid[sy, sx] == WALL or grid[gy, gx] == WALL:
        return []

    def heur(y: int, x: int) -> int:
        return abs(y - gy) + abs(x - gx)

    openh: list[tuple[int, int, int, int]] = [(heur(sy, sx), 0, sy, sx)]
    came: dict[tuple[int, int], tuple[int, int]] = {}
    gscore = {(sy, sx): 0}
    closed: set[tuple[int, int]] = set()
    while openh:
        _, g, y, x = heappop(openh)
        if (y, x) in closed:
            continue
        if (y, x) == (gy, gx):
            path = [(y, x)]
            while (y, x) in came:
                y, x = came[(y, x)]
                path.append((y, x))
            path.reverse()
            return path
        closed.add((y, x))
        for dy, dx, _ in STEPS:
            ny, nx = y + dy, x + dx
            if ny < 0 or nx < 0 or ny >= h or nx >= w or grid[ny, nx] == WALL:
                continue
            ng = g + 1
            if ng >= gscore.get((ny, nx), 1_000_000):
                continue
            gscore[(ny, nx)] = ng
            came[(ny, nx)] = (y, x)
            heappush(openh, (ng + heur(ny, nx), ng, ny, nx))
    return []


def path_key(path: list[tuple[int, int]], look: int = 12, last_key: str | None = None) -> str | None:
    """Cardinal from net displacement, not the A* staircase's first step."""
    if len(path) < 2:
        return None
    y0, x0 = path[0]
    y1, x1 = path[min(look, len(path) - 1)]
    dy = y1 - y0
    dx = x1 - x0
    if dy == 0 and dx == 0:
        return last_key
    adx, ady = abs(dx), abs(dy)
    horiz = "d" if dx > 0 else "a" if dx < 0 else None
    vert = "s" if dy > 0 else "w" if dy < 0 else None
    if last_key == horiz and horiz and adx * 2 >= ady:
        return last_key
    if last_key == vert and vert and ady * 2 >= adx:
        return last_key
    if adx > ady:
        return horiz
    if ady > adx:
        return vert
    if last_key in (horiz, vert):
        return last_key
    return horiz or vert


def _ahead_wall(grid: np.ndarray | None, start: tuple[int, int], key: str) -> bool:
    if grid is None or key not in DELTA:
        return False
    y, x = start
    dy, dx = DELTA[key]
    ny, nx = y + dy, x + dx
    h, w = grid.shape
    return ny < 0 or nx < 0 or ny >= h or nx >= w or grid[ny, nx] == WALL


def decide_key(
    path: list[tuple[int, int]],
    last_key: str | None = None,
    grid: np.ndarray | None = None,
) -> str | None:
    if not path:
        return None
    key = path_key(path, last_key=last_key)
    if key and _ahead_wall(grid, path[0], key):
        other = path_key(path, last_key=None)
        if other and other != key and not _ahead_wall(grid, path[0], other):
            return other
        return None
    return key


def plan(
    rgb: np.ndarray,
    cell: int = 3,
    last_key: str | None = None,
) -> tuple[np.ndarray, list[tuple[int, int]], str | None]:
    cls = classify_rgb(rgb)
    grid = to_grid(cls, cell)
    found = find_player_cell(rgb, grid, cell)
    start = found if found is not None else (grid.shape[0] // 2, grid.shape[1] // 2)
    snapped = snap_walkable(grid, start)
    if snapped is None:
        return grid, [], None
    start = snapped
    goal = nearest_fog(grid, start)
    if goal is None:
        return grid, [], None
    path = astar(grid, start, goal)
    return grid, path, decide_key(path, last_key=last_key, grid=grid)
