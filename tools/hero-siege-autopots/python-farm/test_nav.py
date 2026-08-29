import unittest

import numpy as np

from nav import FLOOR, FOG, WALL, astar, classify_rgb, decide_key, nearest_fog, path_key, plan, to_grid


class ClassifyTests(unittest.TestCase):
    def test_white_line_is_wall(self):
        img = np.zeros((8, 8, 3), dtype=np.uint8)
        img[:] = (80, 90, 70)  # floor
        img[:, 4] = (240, 240, 240)
        cls = classify_rgb(img)
        self.assertTrue(np.all(cls[:, 4] == WALL))
        self.assertEqual(cls[3, 1], FLOOR)

    def test_dark_is_fog(self):
        img = np.zeros((4, 4, 3), dtype=np.uint8)
        cls = classify_rgb(img)
        self.assertTrue(np.all(cls == FOG))

    def test_downsample_keeps_thin_wall(self):
        img = np.full((9, 9, 3), 90, dtype=np.uint8)
        img[:, 4] = 250
        grid = to_grid(classify_rgb(img), cell=3)
        self.assertTrue(np.any(grid == WALL))


class PathTests(unittest.TestCase):
    def test_astar_around_wall(self):
        g = np.full((7, 7), FLOOR, dtype=np.uint8)
        g[:, 3] = WALL
        g[3, 3] = FLOOR  # gap
        path = astar(g, (3, 0), (3, 6))
        self.assertTrue(path)
        self.assertEqual(path[0], (3, 0))
        self.assertEqual(path[-1], (3, 6))
        self.assertTrue(all(g[y, x] != WALL for y, x in path))

    def test_nearest_fog_through_corridor(self):
        g = np.full((5, 8), WALL, dtype=np.uint8)
        g[2, :] = FLOOR
        g[2, 7] = FOG
        self.assertEqual(nearest_fog(g, (2, 0)), (2, 7))

    def test_path_key_goes_east(self):
        path = [(2, 2), (2, 3), (2, 4), (2, 5)]
        self.assertEqual(path_key(path), "d")

    def test_path_key_goes_north(self):
        path = [(5, 3), (4, 3), (3, 3)]
        self.assertEqual(path_key(path), "w")

    def test_plan_reaches_fog(self):
        img = np.full((30, 30, 3), 90, dtype=np.uint8)
        img[:, 14:17] = 250
        img[13:17, 14:17] = 90  # corridor through the wall
        img[:, 24:] = 8
        grid, path, key = plan(img, cell=3)[:3]
        self.assertTrue(path, msg=f"grid=\n{grid}")
        self.assertEqual(key, "d")
        self.assertTrue(np.any(grid == FOG))

    def test_path_key_staircase_uses_net_displacement(self):
        """A* paths zigzag; first steps must not flip W/D every cell."""
        path = [(8, 8), (7, 8), (7, 9), (6, 9), (6, 10), (5, 10), (5, 11)]
        self.assertEqual(path_key(path), "d")

    def test_keep_heading_on_same_axis(self):
        path = [(8, 8), (7, 8), (7, 9), (6, 9), (6, 10)]
        self.assertEqual(decide_key(path, last_key="d"), "d")

    def test_plan_starts_at_yellow_player_not_center(self):
        img = np.full((60, 60, 3), 90, dtype=np.uint8)
        img[8:13, 8:13] = (240, 220, 30)
        img[8:20, 0:6] = 8
        img[48:58, 48:58] = 8
        _grid, path, key = plan(img, cell=3)[:3]
        self.assertTrue(path, msg="should path from the yellow player")
        self.assertEqual(key, "a")

    def test_plan_starts_at_white_player_icon(self):
        img = np.full((60, 60, 3), 90, dtype=np.uint8)
        img[6:11, 6:11] = 250
        img[6:16, 0:5] = 8
        img[50:58, 50:58] = 8
        _grid, path, key = plan(img, cell=3)[:3]
        self.assertTrue(path)
        self.assertEqual(key, "a")


if __name__ == "__main__":
    unittest.main()
