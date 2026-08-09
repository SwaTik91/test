#!/usr/bin/env python3
"""Hero-quality mob walk frames: neutralize magenta → rembg → close → fill → despill → 192px."""
from __future__ import annotations

import subprocess
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from rembg import remove

ROOT = Path("/tmp/mob-v2")
CANON = Path("/workspace/docs/superpowers/art-canon/monster-video")
ASSETS = Path("/workspace/midgard_outpost/assets/images/enemies")
MAX_EDGE = 192

MOB_PICKS = {
    "lunatic": (4, 7, 10, 13, 16, 19),
    "wolf": (7, 10, 13, 16, 19, 22),
    "mushroom": (4, 7, 10, 13, 16, 19),
    "bee": (1, 4, 7, 10, 13, 16),
    "crab": (4, 7, 10, 13, 16, 19),
    "ghost": (1, 4, 7, 10, 13, 16),
    "plant": (4, 7, 10, 13, 16, 19),
    "boss_demon": (4, 7, 10, 13, 16, 19),
    "boss_spider": (4, 7, 10, 13, 16, 19),
    "boss_undead": (4, 7, 10, 13, 16, 19),
    "boss_golem": (4, 7, 10, 13, 16, 19),
}


def is_magenta(r: int, g: int, b: int) -> bool:
    chroma = (r + b) / 2.0 - g
    if r >= 160 and b >= 160 and g <= 110 and chroma >= 70:
        return True
    if r >= 190 and b >= 170 and g <= 130 and chroma >= 60:
        return True
    return False


def neutralize_magenta(img: Image.Image) -> Image.Image:
    a = np.array(img.convert("RGB"))
    h, w = a.shape[:2]
    rem = np.zeros((h, w), dtype=bool)
    for y in range(h):
        row = a[y]
        for x in range(w):
            r, g, b = map(int, row[x])
            rem[y, x] = is_magenta(r, g, b)
    vis = np.zeros_like(rem)
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        if rem[0, x]:
            vis[0, x] = True
            q.append((0, x))
        if rem[h - 1, x]:
            vis[h - 1, x] = True
            q.append((h - 1, x))
    for y in range(h):
        if rem[y, 0]:
            vis[y, 0] = True
            q.append((y, 0))
        if rem[y, w - 1]:
            vis[y, w - 1] = True
            q.append((y, w - 1))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and rem[ny, nx] and not vis[ny, nx]:
                vis[ny, nx] = True
                q.append((ny, nx))
    out = a.copy()
    out[vis] = [0, 255, 0]
    return Image.fromarray(out)


def fill_holes(rgba: np.ndarray) -> np.ndarray:
    a = rgba.copy()
    bin_im = Image.fromarray(((a[:, :, 3] > 16).astype(np.uint8) * 255))
    for _ in range(3):
        bin_im = bin_im.filter(ImageFilter.MaxFilter(5)).filter(
            ImageFilter.MinFilter(5)
        )
    solid = np.array(bin_im) > 127
    h, w = solid.shape
    empty = ~solid
    vis = np.zeros_like(empty)
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        if empty[0, x]:
            vis[0, x] = True
            q.append((0, x))
        if empty[h - 1, x]:
            vis[h - 1, x] = True
            q.append((h - 1, x))
    for y in range(h):
        if empty[y, 0]:
            vis[y, 0] = True
            q.append((y, 0))
        if empty[y, w - 1]:
            vis[y, w - 1] = True
            q.append((y, w - 1))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and empty[ny, nx] and not vis[ny, nx]:
                vis[ny, nx] = True
                q.append((ny, nx))
    holes = empty & ~vis
    out = a.copy()
    ys, xs = np.where(holes)
    for y, x in zip(ys, xs):
        y0, y1 = max(0, y - 5), min(h, y + 6)
        x0, x1 = max(0, x - 5), min(w, x + 6)
        patch = rgba[y0:y1, x0:x1]
        m = patch[:, :, 3] > 40
        if m.any():
            out[y, x, :3] = patch[:, :, :3][m].mean(0)
        out[y, x, 3] = 255
    body = solid | holes
    out[:, :, 3] = np.where(body, 255, 0).astype(np.uint8)
    return out


def despill(a: np.ndarray) -> np.ndarray:
    h, w = a.shape[:2]
    r = a[:, :, 0].astype(np.float32)
    g = a[:, :, 1].astype(np.float32)
    b = a[:, :, 2].astype(np.float32)
    al = a[:, :, 3].astype(np.float32)
    spill = (
        np.clip((np.minimum(r, b) - g) / 55.0, 0, 1)
        * (al > 0)
        * ((r > g + 8) & (b > g + 8))
    )
    r = r - spill * np.maximum(0, r - g) * 0.95
    b = b - spill * np.maximum(0, b - g) * 0.95
    g = g + spill * np.maximum(0, (r + b) / 2 - g) * 0.15
    gspill = (
        np.clip((g - np.maximum(r, b)) / 50.0, 0, 1)
        * (al > 0)
        * (g > r + 15)
        * (g > b + 15)
    )
    g = g - gspill * np.maximum(0, g - np.maximum(r, b)) * 0.85
    r = r + gspill * 8
    b = b + gspill * 4
    mag = (r >= 200) & (b >= 180) & (g <= 90) & (al > 0)
    al_shift = np.pad(al, 1, constant_values=0)
    near = (
        (al_shift[0:h, 1 : w + 1] < 20)
        | (al_shift[2 : h + 2, 1 : w + 1] < 20)
        | (al_shift[1 : h + 1, 0:w] < 20)
        | (al_shift[1 : h + 1, 2 : w + 2] < 20)
    )
    al = np.where(mag & near, 0, al)
    strong = (r >= 220) & (b >= 200) & (g <= 70) & (al > 0) & near
    al = np.where(strong, 0, al)
    # Re-harden body after fringe kill
    body = al > 16
    al = np.where(body, 255, 0)
    return np.clip(np.stack([r, g, b, al], -1), 0, 255).astype(np.uint8)


def process_frame(img: Image.Image) -> Image.Image:
    neu = neutralize_magenta(img)
    cut = remove(neu)
    arr = fill_holes(np.array(cut.convert("RGBA")))
    arr = despill(arr)
    alpha = arr[:, :, 3]
    ys, xs = np.where(alpha > 20)
    if len(ys) == 0:
        return Image.new("RGBA", (MAX_EDGE, MAX_EDGE), (0, 0, 0, 0))
    y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    crop = arr[max(0, y0 - 4) : y1 + 5, max(0, x0 - 4) : x1 + 5]
    im = Image.fromarray(crop)
    scale = MAX_EDGE / max(im.size)
    if abs(scale - 1) > 1e-6:
        im = im.resize(
            (max(1, int(im.width * scale)), max(1, int(im.height * scale))),
            Image.Resampling.LANCZOS,
        )
    return im


def union_bottom(frames: list[Image.Image]) -> list[Image.Image]:
    bboxes = [f.getbbox() for f in frames]
    if any(b is None for b in bboxes):
        frames = [f for f, b in zip(frames, bboxes) if b is not None]
        bboxes = [f.getbbox() for f in frames]
    cw = max(x1 - x0 for x0, y0, x1, y1 in bboxes)
    ch = max(y1 - y0 for x0, y0, x1, y1 in bboxes)
    out = []
    for f, (x0, y0, x1, y1) in zip(frames, bboxes):
        crop = f.crop((x0, y0, x1, y1))
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        canvas.paste(crop, ((cw - crop.width) // 2, ch - crop.height), crop)
        out.append(canvas)
    return out


def extract(mob: str) -> Path:
    vid = ROOT / f"{mob}.mp4"
    frames_dir = ROOT / "frames" / mob
    frames_dir.mkdir(parents=True, exist_ok=True)
    if len(list(frames_dir.glob("f_*.png"))) < 20:
        for p in frames_dir.glob("f_*.png"):
            p.unlink()
        subprocess.check_call(
            [
                "ffmpeg",
                "-y",
                "-i",
                str(vid),
                "-vf",
                "fps=8",
                str(frames_dir / "f_%03d.png"),
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    return frames_dir


def process_mob(mob: str) -> None:
    frames_dir = extract(mob)
    picks = MOB_PICKS[mob]
    avail = sorted(frames_dir.glob("f_*.png"))
    srcs = []
    for n in picks:
        p = frames_dir / f"f_{n:03d}.png"
        if not p.exists():
            p = avail[min(n - 1, len(avail) - 1)]
        srcs.append(p)
    frames = [process_frame(Image.open(p)) for p in srcs]
    frames = union_bottom(frames)
    (CANON / mob).mkdir(parents=True, exist_ok=True)
    (ASSETS / mob).mkdir(parents=True, exist_ok=True)
    for i, f in enumerate(frames):
        f.save(CANON / mob / f"walk_{i}.png")
        f.save(ASSETS / mob / f"walk_{i}.png")
    frames[0].save(ASSETS / f"{mob}.png")
    print(f"{mob}: {frames[0].size} ok")


def main() -> None:
    for mob in MOB_PICKS:
        process_mob(mob)


if __name__ == "__main__":
    main()
