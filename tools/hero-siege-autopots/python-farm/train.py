"""Train walk.npz from recordings/*.npz (YouTube dataset or key-logged runs)."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np

from policy import train_policy

HERE = Path(__file__).resolve().parent


def load_runs(paths: list[Path]) -> tuple[list[np.ndarray], list[str]]:
    images: list[np.ndarray] = []
    labels: list[str] = []
    for path in paths:
        data = np.load(path, allow_pickle=True)
        frames = data["frames"]
        keys = data["keys"]
        for im, k in zip(frames, keys):
            k = str(k)
            if k not in ("w", "a", "s", "d"):
                continue
            images.append(np.asarray(im, dtype=np.uint8))
            labels.append(k)
    return images, labels


def main() -> int:
    parser = argparse.ArgumentParser(description="обучить маленькую модель ходьбы")
    parser.add_argument("data", nargs="*", default=[str(HERE / "recordings")])
    parser.add_argument("--out", default=str(HERE / "walk.npz"))
    parser.add_argument("--epochs", type=int, default=80)
    args = parser.parse_args()
    files: list[Path] = []
    for raw in args.data:
        p = Path(raw)
        if p.is_dir():
            files.extend(sorted(p.glob("*.npz")))
        elif p.is_file():
            files.append(p)
    if not files:
        print("нет .npz — сначала: python from_youtube.py <ссылки>")
        return 1
    images, labels = load_runs(files)
    print("примеров:", len(labels), "из", len(files), "файлов")
    if len(labels) < 20:
        print("мало данных")
        return 1
    model = train_policy(images, labels, epochs=args.epochs)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    model.save(out)
    ok = 0
    for im, k in zip(images, labels):
        pred, _ = model.predict(im)
        if pred == k:
            ok += 1
    print("записал", out, "точность на train:", round(ok / len(labels), 3))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
