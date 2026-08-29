"""Hero Siege minimap farm (Windows). Pots stay in the AHK script."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import numpy as np

from nav import FLOOR, FOG, WALL, plan

CONFIG_PATH = Path(__file__).with_name("farm.json")
VK_F3, VK_F4, VK_SHIFT, VK_ESCAPE = 0x72, 0x73, 0x10, 0x1B
VK = {"w": 0x57, "a": 0x41, "s": 0x53, "d": 0x44}
TURN = {"w": "d", "d": "s", "s": "a", "a": "w"}


def enable_dpi() -> None:
    """Cursor pixels must match DXGI/dxcam pixels (125%/150% scaling)."""
    import ctypes

    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)
    except Exception:
        try:
            ctypes.windll.user32.SetProcessDPIAware()
        except Exception:
            pass


def patch_bytes(grid: np.ndarray, start: tuple[int, int], r: int = 4) -> bytes:
    y, x = start
    return np.ascontiguousarray(grid[max(0, y - r) : y + r + 1, max(0, x - r) : x + r + 1]).tobytes()


def load_cfg() -> dict:
    if CONFIG_PATH.exists():
        return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    return {"x1": 0, "y1": 0, "x2": 0, "y2": 0}


def save_cfg(cfg: dict) -> None:
    CONFIG_PATH.write_text(json.dumps(cfg, indent=2), encoding="utf-8")


class WindowsIO:
    def __init__(self) -> None:
        import ctypes
        from ctypes import wintypes

        self.ct = ctypes
        self.user32 = ctypes.WinDLL("user32", use_last_error=True)
        self._held: set[str] = set()

        class POINT(ctypes.Structure):
            _fields_ = [("x", wintypes.LONG), ("y", wintypes.LONG)]

        self.POINT = POINT

        class KEYBDINPUT(ctypes.Structure):
            _fields_ = (
                ("wVk", wintypes.WORD),
                ("wScan", wintypes.WORD),
                ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD),
                ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
            )

        class HARDWAREINPUT(ctypes.Structure):
            _fields_ = (
                ("uMsg", wintypes.DWORD),
                ("wParamL", wintypes.WORD),
                ("wParamH", wintypes.WORD),
            )

        class MOUSEINPUT(ctypes.Structure):
            _fields_ = (
                ("dx", wintypes.LONG),
                ("dy", wintypes.LONG),
                ("mouseData", wintypes.DWORD),
                ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD),
                ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
            )

        class INPUTUNION(ctypes.Union):
            _fields_ = (("ki", KEYBDINPUT), ("mi", MOUSEINPUT), ("hi", HARDWAREINPUT))

        class INPUT(ctypes.Structure):
            _fields_ = (("type", wintypes.DWORD), ("union", INPUTUNION))

        self.KEYBDINPUT = KEYBDINPUT
        self.INPUTUNION = INPUTUNION
        self.INPUT = INPUT
        self.KEYEVENTF_KEYUP = 0x0002

    def key_down(self, vk: int) -> bool:
        return bool(self.user32.GetAsyncKeyState(vk) & 0x8000)

    def cursor(self) -> tuple[int, int]:
        pt = self.POINT()
        self.user32.GetCursorPos(self.ct.byref(pt))
        return int(pt.x), int(pt.y)

    def game_focused(self) -> bool:
        hwnd = self.user32.GetForegroundWindow()
        buf = self.ct.create_unicode_buffer(260)
        self.user32.GetWindowTextW(hwnd, buf, 260)
        t = buf.value.lower()
        return "hero siege" in t or "hero_siege" in t

    def _send(self, vk: int, up: bool) -> None:
        extra = self.ct.c_ulong(0)
        inp = self.INPUT()
        inp.type = 1
        inp.union.ki = self.KEYBDINPUT(
            vk, 0, self.KEYEVENTF_KEYUP if up else 0, 0, self.ct.pointer(extra)
        )
        self.user32.SendInput(1, self.ct.byref(inp), self.ct.sizeof(inp))

    def hold(self, key: str | None) -> None:
        want = {key} if key else set()
        for k in ("w", "a", "s", "d"):
            on = k in want
            if on and k not in self._held:
                self._send(VK[k], False)
                self._held.add(k)
            elif not on and k in self._held:
                self._send(VK[k], True)
                self._held.discard(k)

    def release(self) -> None:
        self.hold(None)


class Grabber:
    def __init__(self) -> None:
        self.mode = ""
        self._cam = None
        self._mss = None
        try:
            import dxcam

            self._cam = dxcam.create(output_color="RGB")
            self.mode = "dxcam"
            return
        except Exception as e:
            self._dx_err = str(e)
        try:
            import mss

            self._mss = mss.mss()
            self.mode = "mss"
        except Exception as e:
            raise RuntimeError(
                "Нет захвата кадра. pip install dxcam  (или mss). dxcam: " + getattr(self, "_dx_err", "") + " mss: " + str(e)
            ) from e

    def grab(self) -> np.ndarray | None:
        if self._cam is not None:
            frame = self._cam.grab()
            return None if frame is None else np.asarray(frame)
        mon = self._mss.monitors[1]
        raw = np.asarray(self._mss.grab(mon))
        return raw[:, :, 2::-1].copy()


def crop_map(frame: np.ndarray, cfg: dict) -> np.ndarray | None:
    x1, y1, x2, y2 = (int(cfg[k]) for k in ("x1", "y1", "x2", "y2"))
    if x2 < x1:
        x1, x2 = x2, x1
    if y2 < y1:
        y1, y2 = y2, y1
    h, w = frame.shape[:2]
    x1, x2 = max(0, x1), min(w, x2)
    y1, y2 = max(0, y1), min(h, y2)
    if x2 - x1 < 24 or y2 - y1 < 24:
        return None
    # Thin pad: a large inset can cut off the hero icon near the map edge.
    pad_x = max(2, int((x2 - x1) * 0.03))
    pad_y = max(2, int((y2 - y1) * 0.03))
    return frame[y1 + pad_y : y2 - pad_y, x1 + pad_x : x2 - pad_x]


def debug_view(grid: np.ndarray, path: list[tuple[int, int]]) -> np.ndarray:
    vis = np.zeros((grid.shape[0], grid.shape[1], 3), dtype=np.uint8)
    vis[grid == FLOOR] = (70, 160, 80)
    vis[grid == WALL] = (255, 255, 255)
    vis[grid == FOG] = (18, 18, 18)
    for y, x in path:
        if 0 <= y < vis.shape[0] and 0 <= x < vis.shape[1]:
            vis[y, x] = (40, 220, 255)
    if path:
        vis[path[0]] = (50, 50, 255)
        vis[path[-1]] = (255, 80, 40)
    return vis


def main() -> int:
    if sys.platform != "win32":
        print("Этот фарм нужно запускать на Windows, рядом с игрой.")
        print("На этой машине можно только тесты: python test_nav.py")
        return 1
    enable_dpi()
    parser = argparse.ArgumentParser(description="Hero Siege minimap A* farm")
    parser.add_argument("--debug", action="store_true", help="окно: белое=стена, тёмное=туман, жёлтый=путь, красный=герой")
    parser.add_argument(
        "--keys",
        choices=("wasd", "arrows"),
        default="wasd",
        help="клавиши ходьбы (в Hero Siege 2.0 по умолчанию стрелки)",
    )
    args = parser.parse_args()
    if args.keys == "arrows":
        VK.update({"w": 0x26, "a": 0x25, "s": 0x28, "d": 0x27})
    io = WindowsIO()
    grabber = Grabber()
    print("Захват:", grabber.mode, "  клавиши:", args.keys)
    print("F3 — два угла миникарты (внутри рамки). F4 — ходьба. Shift+Esc — выход.")
    print("С --debug красная точка = герой. Если она не на тебе — напиши цвет иконки.")
    if args.keys == "wasd":
        print("Если WASD в игре — скиллы, а ходишь стрелками:  python farm.py --debug --keys arrows")
    cfg = load_cfg()
    enabled = False
    calib_step = 0
    prev_f3 = prev_f4 = False
    last_key: str | None = None
    lock_until = 0.0
    stuck_sig = b""
    stuck_since = 0.0
    cv2 = None
    if args.debug:
        try:
            import cv2 as _cv2

            cv2 = _cv2
        except ImportError:
            print("Нет opencv-python — debug-окно выключено")

    try:
        while True:
            f3, f4 = io.key_down(VK_F3), io.key_down(VK_F4)
            if io.key_down(VK_SHIFT) and io.key_down(VK_ESCAPE):
                break
            if f3 and not prev_f3:
                x, y = io.cursor()
                if calib_step == 0:
                    cfg["x1"], cfg["y1"] = x, y
                    calib_step = 1
                    print(f"Угол 1: {x},{y}  — теперь правый нижний, F3")
                else:
                    cfg["x2"], cfg["y2"] = x, y
                    calib_step = 0
                    save_cfg(cfg)
                    print(f"Угол 2: {x},{y}  — карта сохранена в {CONFIG_PATH.name}")
            if f4 and not prev_f4:
                if not cfg.get("x2"):
                    print("Сначала F3 два раза")
                else:
                    enabled = not enabled
                    if not enabled:
                        io.release()
                        last_key = None
                        lock_until = 0.0
                    else:
                        stuck_sig = b""
                        stuck_since = 0.0
                    print("ХОДЬБА", "ВКЛ" if enabled else "ВЫКЛ")
            prev_f3, prev_f4 = f3, f4

            if not enabled:
                time.sleep(0.03)
                continue
            if not io.game_focused():
                io.release()
                last_key = None
                lock_until = 0.0
                time.sleep(0.05)
                continue
            frame = grabber.grab()
            if frame is None:
                time.sleep(0.02)
                continue
            rgb = crop_map(frame, cfg)
            if rgb is None:
                io.release()
                time.sleep(0.05)
                continue
            grid, path, key = plan(rgb, cell=2, last_key=last_key)
            now = time.monotonic()
            if path:
                sig = patch_bytes(grid, path[0])
                if sig != stuck_sig:
                    stuck_sig, stuck_since = sig, now
                elif last_key and now - stuck_since > 1.25:
                    nxt = TURN[last_key]
                    print(f"\nзастрял → {nxt}")
                    last_key = nxt
                    io.hold(nxt)
                    lock_until = now + 0.75
                    stuck_sig, stuck_since = b"", now
                    time.sleep(0.08)
                    continue
            if last_key and now < lock_until and key and key != {"w": "s", "s": "w", "a": "d", "d": "a"}.get(last_key):
                key = last_key
            if key != last_key:
                io.hold(key)
                last_key = key
                lock_until = now + 0.55
                print(f"\r{(key or '-'):2s}  путь {len(path):3d}   ", end="", flush=True)
            if cv2 is not None:
                vis = debug_view(grid, path)
                vis = cv2.resize(vis, (vis.shape[1] * 6, vis.shape[0] * 6), interpolation=cv2.INTER_NEAREST)
                cv2.imshow("HS farm", vis)
                cv2.waitKey(1)
            time.sleep(0.1)
    finally:
        io.release()
        if cv2 is not None:
            cv2.destroyAllWindows()
        print("\nстоп")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
