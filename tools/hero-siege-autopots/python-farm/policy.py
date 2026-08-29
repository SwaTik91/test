"""Tiny numpy MLP: minimap crop → WASD. No PyTorch."""

from __future__ import annotations

from pathlib import Path

import numpy as np

from nav import FLOOR, FOG, WALL, classify_rgb

KEYS = ("w", "a", "s", "d")
SIZE = 16


def downscale(img: np.ndarray, size: int = SIZE) -> np.ndarray:
    h, w = img.shape[:2]
    yy = np.clip((np.arange(size) * h / size).astype(np.int32), 0, h - 1)
    xx = np.clip((np.arange(size) * w / size).astype(np.int32), 0, w - 1)
    if img.ndim == 2:
        return img[yy[:, None], xx]
    return img[yy[:, None], xx]


def features(rgb: np.ndarray) -> np.ndarray:
    """16×16 RGB + wall/fog/floor channel, flattened."""
    small = downscale(rgb).astype(np.float32) / 255.0
    cls = downscale(classify_rgb(rgb))
    ch = np.full((SIZE, SIZE, 1), 0.5, dtype=np.float32)
    ch[cls == FOG] = 0.0
    ch[cls == WALL] = 1.0
    ch[cls == FLOOR] = 0.45
    return np.concatenate([small, ch], axis=2).reshape(-1)


def _softmax(z: np.ndarray) -> np.ndarray:
    z = z - z.max(axis=-1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=-1, keepdims=True)


class Policy:
    def __init__(self, w1: np.ndarray, b1: np.ndarray, w2: np.ndarray, b2: np.ndarray) -> None:
        self.w1, self.b1, self.w2, self.b2 = w1, b1, w2, b2

    def logits(self, x: np.ndarray) -> np.ndarray:
        h = np.maximum(0.0, x @ self.w1 + self.b1)
        return h @ self.w2 + self.b2

    def predict(self, rgb: np.ndarray) -> tuple[str | None, float]:
        z = self.logits(features(rgb))
        p = _softmax(z)
        i = int(p.argmax())
        return KEYS[i], float(p[i])

    def save(self, path: str | Path) -> None:
        np.savez(
            path,
            w1=self.w1,
            b1=self.b1,
            w2=self.w2,
            b2=self.b2,
        )

    @classmethod
    def load(cls, path: str | Path) -> Policy:
        data = np.load(path)
        return cls(data["w1"], data["b1"], data["w2"], data["b2"])


def train_policy(
    images: list[np.ndarray],
    labels: list[str],
    seed: int = 0,
    epochs: int = 80,
    lr: float = 0.12,
    hidden: int = 32,
) -> Policy:
    rng = np.random.default_rng(seed)
    X = np.stack([features(im) for im in images]).astype(np.float32)
    y_idx = np.array([KEYS.index(k) for k in labels], dtype=np.int64)
    n, d = X.shape
    Y = np.eye(len(KEYS), dtype=np.float32)[y_idx]
    w1 = rng.normal(0, 0.04, (d, hidden)).astype(np.float32)
    b1 = np.zeros(hidden, dtype=np.float32)
    w2 = rng.normal(0, 0.04, (hidden, len(KEYS))).astype(np.float32)
    b2 = np.zeros(len(KEYS), dtype=np.float32)
    rate = lr
    for ep in range(epochs):
        hpre = X @ w1 + b1
        h = np.maximum(0.0, hpre)
        p = _softmax(h @ w2 + b2)
        dlog = (p - Y) / n
        gw2 = h.T @ dlog
        gb2 = dlog.sum(axis=0)
        dh = dlog @ w2.T
        dh[hpre <= 0] = 0
        gw1 = X.T @ dh
        gb1 = dh.sum(axis=0)
        decay = 2e-4
        w2 -= rate * (gw2 + decay * w2)
        b2 -= rate * gb2
        w1 -= rate * (gw1 + decay * w1)
        b1 -= rate * gb1
        if ep in (35, 55, 70):
            rate *= 0.5
    return Policy(w1, b1, w2, b2)
