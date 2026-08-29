import unittest

import numpy as np

from youtube_data import find_minimap, label_from_motion


def hud_frame(map_side: int = 40) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """Fake 16:9 HUD with a minimap in the top-right."""
    h, w = 180, 320
    frame = np.full((h, w, 3), 40, dtype=np.uint8)
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


if __name__ == "__main__":
    unittest.main()
