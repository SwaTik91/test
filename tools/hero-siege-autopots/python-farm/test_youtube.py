import unittest

import numpy as np

from youtube_data import (
    find_minimap,
    has_gameplay_hud,
    hero_siege_minimap_box,
    label_from_motion,
    pairs_to_dataset,
)


def hud_frame(map_side: int = 40) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """Fake 16:9 HUD with a minimap in the top-right and a red HP bar."""
    h, w = 180, 320
    frame = np.full((h, w, 3), 40, dtype=np.uint8)
    frame[10:16, 20:90] = (200, 30, 30)
    frame[18:22, 20:70] = (40, 70, 180)
    x1, y1 = w - map_side - 8, 6
    x2, y2 = x1 + map_side, y1 + map_side
    mm = np.full((map_side, map_side, 3), 90, dtype=np.uint8)
    mm[:, 0:2] = 250
    mm[0:2, :] = 250
    mm[:, -2:] = 250
    mm[-2:, :] = 250
    mm[8:14, 8:14] = (240, 220, 30)
    mm[:, 28:] = 8
    frame[y1:y2, x1:x2] = mm
    return frame, (x1, y1, x2, y2)


class YoutubeDataTests(unittest.TestCase):
    def test_finds_minimap_in_top_right(self):
        frame, (x1, y1, x2, y2) = hud_frame()
        box = find_minimap(frame)
        self.assertIsNotNone(box)
        cx1, cy1, cx2, cy2 = box
        overlap_x = max(0, min(x2, cx2) - max(x1, cx1))
        overlap_y = max(0, min(y2, cy2) - max(y1, cy1))
        self.assertGreater(overlap_x * overlap_y, 400)

    def test_player_moving_right_is_d(self):
        a = np.full((40, 40, 3), 90, dtype=np.uint8)
        b = a.copy()
        a[18:22, 8:12] = (240, 220, 30)
        b[18:22, 24:28] = (240, 220, 30)
        self.assertEqual(label_from_motion(a, b), "d")

    def test_radar_scroll_down_is_w(self):
        """Player-centered map: world slides down when walking up."""
        a = np.full((40, 40, 3), 90, dtype=np.uint8)
        a[4:8, :] = 250
        b = np.full((40, 40, 3), 90, dtype=np.uint8)
        b[12:16, :] = 250
        a[18:22, 18:22] = (240, 220, 30)
        b[18:22, 18:22] = (240, 220, 30)
        self.assertEqual(label_from_motion(a, b), "w")

    def test_hud_detects_red_hp_bar(self):
        frame, _ = hud_frame()
        self.assertTrue(has_gameplay_hud(frame))
        talking = np.full((180, 320, 3), 80, dtype=np.uint8)
        talking[20:80, 40:120] = (180, 140, 110)
        self.assertFalse(has_gameplay_hud(talking))

    def test_locked_box_is_top_right_square(self):
        box = hero_siege_minimap_box(360, 640)
        x1, y1, x2, y2 = box
        self.assertEqual(x2 - x1, y2 - y1)
        self.assertGreaterEqual(x1, 500)
        self.assertLessEqual(y1, 20)
        self.assertEqual(box, (564, 7, 628, 71))

    def test_dataset_skips_talking_head(self):
        hud, (x1, y1, x2, y2) = hud_frame()
        a = hud.copy()
        b = hud.copy()
        a[y1:y2, x1:x2][8:14, 8:14] = 90
        b[y1:y2, x1:x2][8:14, 8:14] = 90
        a[y1:y2, x1:x2][18:22, 8:12] = (240, 220, 30)
        b[y1:y2, x1:x2][18:22, 24:28] = (240, 220, 30)
        talking = np.full((180, 320, 3), 70, dtype=np.uint8)
        talking[10:90, 20:140] = (200, 160, 120)
        xs, ys = pairs_to_dataset([talking, talking, a, b, talking], box=(x1, y1, x2, y2))
        self.assertGreaterEqual(len(ys), 1)
        self.assertIn(ys[0], ("w", "a", "s", "d"))

    def test_dim_player_blob_still_labels_d(self):
        """360p YouTube: hero icon is a few mid-bright pixels, not gold."""
        a = np.full((40, 40, 3), 8, dtype=np.uint8)
        b = a.copy()
        a[18:20, 8:10] = (140, 138, 130)
        b[18:20, 24:26] = (140, 138, 130)
        self.assertEqual(label_from_motion(a, b), "d")


if __name__ == "__main__":
    unittest.main()
