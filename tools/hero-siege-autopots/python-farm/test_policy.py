import tempfile
import unittest
from pathlib import Path

import numpy as np

from policy import KEYS, Policy, features, train_policy


def fake_map(side: str, n: int = 36) -> np.ndarray:
    img = np.full((n, n, 3), 90, dtype=np.uint8)
    img[n // 2 - 2 : n // 2 + 2, n // 2 - 2 : n // 2 + 2] = (240, 220, 30)
    fog = 8
    if side == "w":
        img[: n // 3] = fog
    elif side == "s":
        img[2 * n // 3 :] = fog
    elif side == "a":
        img[:, : n // 3] = fog
    elif side == "d":
        img[:, 2 * n // 3 :] = fog
    return img


class PolicyTests(unittest.TestCase):
    def test_features_are_fixed_size(self):
        x = features(fake_map("d"))
        self.assertEqual(x.ndim, 1)
        self.assertGreater(x.size, 100)

    def test_learns_walk_toward_fog(self):
        rng = np.random.default_rng(0)
        xs, ys = [], []
        for key in KEYS:
            for _ in range(12):
                img = fake_map(key)
                img = np.clip(img.astype(np.int16) + rng.integers(-8, 9, img.shape), 0, 255).astype(np.uint8)
                xs.append(img)
                ys.append(key)
        model = train_policy(xs, ys, seed=0, epochs=80)
        ok = 0
        for key in KEYS:
            pred, conf = model.predict(fake_map(key))
            if pred == key:
                ok += 1
        self.assertGreaterEqual(ok, 3, msg="should map fog side to WASD")

    def test_save_load_roundtrip(self):
        xs = [fake_map("d") for _ in range(8)] + [fake_map("a") for _ in range(8)]
        ys = ["d"] * 8 + ["a"] * 8
        model = train_policy(xs, ys, seed=1, epochs=60)
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "walk.npz"
            model.save(path)
            loaded = Policy.load(path)
        pred, _ = loaded.predict(fake_map("d"))
        self.assertEqual(pred, "d")


if __name__ == "__main__":
    unittest.main()
