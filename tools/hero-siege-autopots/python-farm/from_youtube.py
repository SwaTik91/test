"""Download YouTube (or a local video) and build a minimap → WASD dataset."""

from __future__ import annotations

import argparse
import subprocess
import sys
from collections.abc import Iterator
from pathlib import Path

import numpy as np

from youtube_data import pairs_to_dataset

HERE = Path(__file__).resolve().parent
REC = HERE / "recordings"


def download_youtube(url: str, dest: Path) -> Path:
    dest.mkdir(parents=True, exist_ok=True)
    before = {p.name for p in dest.iterdir()}
    cmd = [
        sys.executable,
        "-m",
        "yt_dlp",
        "-f",
        "bv*[height<=720]+ba/b[height<=720]/b",
        "--merge-output-format",
        "mp4",
        "-o",
        str(dest / "%(id)s.%(ext)s"),
        url,
    ]
    print("скачиваю:", url)
    subprocess.run(cmd, check=True)
    after = [p for p in dest.iterdir() if p.name not in before]
    vids = [p for p in after if p.suffix.lower() in {".mp4", ".mkv", ".webm", ".mov"}]
    if not vids:
        vids = sorted(dest.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True)
    if not vids:
        raise FileNotFoundError("yt-dlp не положил видео в " + str(dest))
    return vids[0]


def iter_frames(path: Path, every: int = 8) -> Iterator[np.ndarray]:
    import cv2

    cap = cv2.VideoCapture(str(path))
    if not cap.isOpened():
        raise RuntimeError("не открыть видео: " + str(path))
    i = 0
    try:
        while True:
            ok, bgr = cap.read()
            if not ok:
                break
            if i % every == 0:
                yield np.asarray(bgr[:, :, ::-1].copy())
            i += 1
    finally:
        cap.release()


def collect_from_video(path: Path, every: int = 8) -> tuple[list[np.ndarray], list[str]]:
    print(f"  читаю {path.name}, каждый {every}-й кадр")
    return pairs_to_dataset(iter_frames(path, every=every))


def main() -> int:
    parser = argparse.ArgumentParser(description="YouTube / видео → датасет ходьбы")
    parser.add_argument("inputs", nargs="+", help="ссылки YouTube или пути к mp4")
    parser.add_argument("--out", default=str(REC / "yt_dataset.npz"))
    parser.add_argument("--every", type=int, default=8, help="брать каждый N-й кадр")
    args = parser.parse_args()
    REC.mkdir(parents=True, exist_ok=True)
    vid_dir = REC / "videos"
    all_x: list[np.ndarray] = []
    all_y: list[str] = []
    for item in args.inputs:
        path = Path(item)
        if item.startswith("http://") or item.startswith("https://"):
            path = download_youtube(item, vid_dir)
        elif not path.is_file():
            print("нет файла:", item)
            return 1
        xs, ys = collect_from_video(path, every=args.every)
        print(f"  примеров: {len(ys)}")
        all_x.extend(xs)
        all_y.extend(ys)
    if len(all_y) < 20:
        print("мало примеров:", len(all_y), "— нужны ролики где видна миникарта (не закрыта вебкамерой).")
        return 1
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(out, frames=np.array(all_x, dtype=object), keys=np.array(all_y))
    print("записал", out, "примеров", len(all_y))
    from collections import Counter

    print("метки:", dict(Counter(all_y)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
