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


def luma_rgb(rgb: np.ndarray) -> np.ndarray:
    r = rgb[..., 0].astype(np.int32)
    g = rgb[..., 1].astype(np.int32)
    b = rgb[..., 2].astype(np.int32)
    return (r * 2 + g * 3 + b) // 6


def classify_rgb(rgb: np.ndarray) -> np.ndarray:
    """rgb: HxWx3 uint8. White/gray lines = WALL, dark = FOG, else FLOOR."""
    h, w = rgb.shape[:2]
    out = np.full((h, w), FLOOR, dtype=np.uint8)
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


def nearest_fog(grid: np.ndarray, start: tuple[int, int]) -> tuple[int, int] | None:
    """BFS through non-walls; first fog cell that is not the start."""
    h, w = grid.shape
    sy, sx = start
    if not (0 <= sy < h and 0 <= sx < w) or grid[sy, sx] == WALL:
        return None
    seen = np.zeros_like(grid, dtype=bool)
    q = deque([(sy, sx)])
    seen[sy, sx] = True
    while q:
        y, x = q.popleft()
        if grid[y, x] == FOG and (y, x) != (sy, sx):
            return y, x
        for dy, dx, _ in STEPS:
            ny, nx = y + dy, x + dx
            if ny < 0 or nx < 0 or ny >= h or nx >= w:
                continue
            if seen[ny, nx] or grid[ny, nx] == WALL:
                continue
            seen[ny, nx] = True
            q.append((ny, nx))
    return None


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


def path_key(path: list[tuple[int, int]], look: int = 4) -> str | None:
    """First stable cardinal along the path (row down, col right)."""
    if len(path) < 2:
        return None
    votes = {"w": 0, "a": 0, "s": 0, "d": 0}
    y0, x0 = path[0]
    for y, x in path[1 : 1 + look]:
        if y < y0:
            votes["w"] += 1
        elif y > y0:
            votes["s"] += 1
        elif x < x0:
            votes["a"] += 1
        elif x > x0:
            votes["d"] += 1
        y0, x0 = y, x
    return max(votes, key=votes.get) if max(votes.values()) else None


def plan(rgb: np.ndarray, cell: int = 3) -> tuple[np.ndarray, list[tuple[int, int]], str | None]:
    cls = classify_rgb(rgb)
    grid = to_grid(cls, cell)
    gh, gw = grid.shape
    start = (gh // 2, gw // 2)
    # If center is a wall (player icon / white), search nearby floor.
    if grid[start] == WALL:
        found = None
        for r in range(1, 6):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    y, x = start[0] + dy, start[1] + dx
                    if 0 <= y < gh and 0 <= x < gw and grid[y, x] != WALL:
                        found = (y, x)
                        break
                if found:
                    break
            if found:
                break
        if found:
            start = found
        else:
            return grid, [], None
    goal = nearest_fog(grid, start)
    if goal is None:
        return grid, [], None
    path = astar(grid, start, goal)
    return grid, path, path_key(path)
