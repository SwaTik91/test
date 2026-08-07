#!/usr/bin/env python3
"""Compose store listing art: launcher icons and landscape store screenshots."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parents[2]
MIDGARD = REPO_ROOT / "midgard_outpost"
ASSETS = MIDGARD / "assets" / "images"
STORE_ICONS = REPO_ROOT / "store" / "icons"
STORE_SCREENSHOTS = REPO_ROOT / "store" / "screenshots"
MIPMAP_DIR = MIDGARD / "android" / "app" / "src" / "main" / "res"

ICON_SIZE = 512
HERO_TARGET = 280
SCREEN_W = 1920
SCREEN_H = 1080
CAPTION_BAR_H = 96
TOOLS_DIR = Path(__file__).resolve().parent
BUNDLED_CAPTION_FONT = TOOLS_DIR / "fonts" / "DejaVuSans-Bold.ttf"
SYSTEM_CAPTION_FONT = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")

MIPMAP_SIZES: dict[str, int] = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def cover_scale(image: Image.Image, size: int) -> Image.Image:
    """Scale image to cover a square canvas, then center-crop."""
    w, h = image.size
    scale = max(size / w, size / h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    scaled = image.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - size) // 2
    top = (new_h - size) // 2
    return scaled.crop((left, top, left + size, top + size))


def cover_scale_rect(image: Image.Image, width: int, height: int) -> Image.Image:
    """Scale image to cover a rectangular canvas, then center-crop."""
    w, h = image.size
    scale = max(width / w, height / h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    scaled = image.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - width) // 2
    top = (new_h - height) // 2
    return scaled.crop((left, top, left + width, top + height))


def scale_sprite(image: Image.Image, target: int) -> Image.Image:
    """Upscale a sprite with nearest-neighbor to at least `target` px on the long edge."""
    w, h = image.size
    scale = target / max(w, h)
    new_size = (max(1, int(round(w * scale))), max(1, int(round(h * scale))))
    return image.resize(new_size, Image.Resampling.NEAREST)


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def load_rgb(path: Path) -> Image.Image:
    return Image.open(path).convert("RGB")


def resolve_caption_font_path(*, required: bool = False) -> Path | None:
    if BUNDLED_CAPTION_FONT.exists():
        return BUNDLED_CAPTION_FONT
    if SYSTEM_CAPTION_FONT.exists():
        return SYSTEM_CAPTION_FONT
    if required:
        print(
            "ERROR: DejaVu Sans Bold is required for RU screenshot captions.\n"
            f"  Bundled font missing: {BUNDLED_CAPTION_FONT}\n"
            f"  System fallback missing: {SYSTEM_CAPTION_FONT}\n"
            "  Copy DejaVuSans-Bold.ttf into store/tools/fonts/ and retry.",
            file=sys.stderr,
        )
        sys.exit(1)
    return None


def caption_font(size: int = 52) -> ImageFont.FreeTypeFont:
    font_path = resolve_caption_font_path(required=True)
    return ImageFont.truetype(str(font_path), size)


def draw_caption(canvas: Image.Image, text: str) -> None:
    """Draw a high-contrast caption bar along the bottom."""
    draw = ImageDraw.Draw(canvas)
    bar_top = SCREEN_H - CAPTION_BAR_H
    draw.rectangle((0, bar_top, SCREEN_W, SCREEN_H), fill=(16, 16, 24, 220))
    font = caption_font()
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (SCREEN_W - text_w) // 2
    y = bar_top + (CAPTION_BAR_H - text_h) // 2
    draw.text((x + 2, y + 2), text, font=font, fill=(0, 0, 0))
    draw.text((x, y), text, font=font, fill=(255, 240, 200))


def new_screenshot_canvas(bg_path: Path) -> Image.Image:
    bg = load_rgb(bg_path)
    content_h = SCREEN_H - CAPTION_BAR_H
    bg_layer = cover_scale_rect(bg, SCREEN_W, content_h)
    canvas = Image.new("RGBA", (SCREEN_W, SCREEN_H), (16, 16, 24, 255))
    canvas.paste(bg_layer, (0, 0))
    return canvas


def paste_centered(canvas: Image.Image, sprite: Image.Image, cx: int, cy: int) -> None:
    x = cx - sprite.width // 2
    y = cy - sprite.height // 2
    canvas.paste(sprite, (x, y), sprite)


def compose_hub_screenshot() -> Image.Image:
    canvas = new_screenshot_canvas(ASSETS / "hub" / "town_bg.png")
    content_h = SCREEN_H - CAPTION_BAR_H
    icons = [
        load_rgba(ASSETS / "hub" / "icon_archer.png"),
        load_rgba(ASSETS / "hub" / "icon_mage.png"),
        load_rgba(ASSETS / "hub" / "icon_paladin.png"),
    ]
    scaled = [scale_sprite(icon, 220) for icon in icons]
    gap = SCREEN_W // (len(scaled) + 1)
    cy = content_h // 2 + 20
    for i, icon in enumerate(scaled):
        paste_centered(canvas, icon, gap * (i + 1), cy)
    draw_caption(canvas, "Выбери класс")
    return canvas


def compose_run_screenshot(
    bg_name: str,
    hero_name: str,
    caption: str,
    *,
    enemy_name: str | None = None,
) -> Image.Image:
    canvas = new_screenshot_canvas(ASSETS / "world" / bg_name)
    content_h = SCREEN_H - CAPTION_BAR_H
    ground_y = int(content_h * 0.78)

    hero = scale_sprite(load_rgba(ASSETS / "heroes" / f"{hero_name}.png"), 360)
    paste_centered(canvas, hero, SCREEN_W // 2 - 120, ground_y - hero.height // 2)

    if enemy_name:
        enemy = scale_sprite(load_rgba(ASSETS / "enemies" / f"{enemy_name}.png"), 300)
        paste_centered(canvas, enemy, SCREEN_W // 2 + 280, ground_y - enemy.height // 2)

    draw_caption(canvas, caption)
    return canvas


def compose_boss_chest_screenshot() -> Image.Image:
    canvas = new_screenshot_canvas(ASSETS / "world" / "bg_forest.png")
    content_h = SCREEN_H - CAPTION_BAR_H
    ground_y = int(content_h * 0.78)

    boss = scale_sprite(load_rgba(ASSETS / "enemies" / "boss_ogre.png"), 420)
    chest = scale_sprite(load_rgba(ASSETS / "props" / "chest.png"), 260)
    paste_centered(canvas, boss, SCREEN_W // 2 - 100, ground_y - boss.height // 2)
    paste_centered(canvas, chest, SCREEN_W // 2 + 320, ground_y - chest.height // 2 + 20)

    draw_caption(canvas, "Боссы и сундуки")
    return canvas


def compose_screenshots() -> None:
    resolve_caption_font_path(required=True)
    STORE_SCREENSHOTS.mkdir(parents=True, exist_ok=True)

    specs: list[tuple[str, Image.Image]] = [
        ("01_hub.png", compose_hub_screenshot()),
        (
            "02_run_archer.png",
            compose_run_screenshot("bg_fields.png", "archer", "Лучник", enemy_name="mob_goblin"),
        ),
        ("03_run_mage.png", compose_run_screenshot("bg_forest.png", "mage", "Маг")),
        ("04_run_paladin.png", compose_run_screenshot("bg_fields.png", "paladin", "Паладин")),
        ("05_boss_chest.png", compose_boss_chest_screenshot()),
    ]

    for filename, image in specs:
        out_path = STORE_SCREENSHOTS / filename
        rgb = image.convert("RGB")
        rgb.save(out_path, format="PNG")
        print(f"Wrote {out_path.relative_to(REPO_ROOT)}")


def compose_launcher_icon() -> Image.Image:
    bg_path = ASSETS / "hub" / "town_bg.png"
    hero_path = ASSETS / "heroes" / "paladin.png"

    bg = Image.open(bg_path).convert("RGB")
    canvas = cover_scale(bg, ICON_SIZE)

    hero = Image.open(hero_path).convert("RGBA")
    hero_w, hero_h = hero.size
    scale = HERO_TARGET / max(hero_w, hero_h)
    new_size = (max(1, int(round(hero_w * scale))), max(1, int(round(hero_h * scale))))
    hero_scaled = hero.resize(new_size, Image.Resampling.NEAREST)

    x = (ICON_SIZE - new_size[0]) // 2
    y = (ICON_SIZE - new_size[1]) // 2
    canvas.paste(hero_scaled, (x, y), hero_scaled)
    return canvas


def write_icons() -> None:
    icon = compose_launcher_icon()

    STORE_ICONS.mkdir(parents=True, exist_ok=True)
    master_path = STORE_ICONS / "ic_launcher_512.png"
    icon.save(master_path, format="PNG")

    for density, px in MIPMAP_SIZES.items():
        out_dir = MIPMAP_DIR / f"mipmap-{density}"
        out_dir.mkdir(parents=True, exist_ok=True)
        resized = icon.resize((px, px), Image.Resampling.LANCZOS)
        resized.save(out_dir / "ic_launcher.png", format="PNG")

    print(f"Wrote {master_path.relative_to(REPO_ROOT)}")
    for density in MIPMAP_SIZES:
        rel = MIPMAP_DIR / f"mipmap-{density}" / "ic_launcher.png"
        print(f"Wrote {rel.relative_to(REPO_ROOT)}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compose Midgard Outpost store art assets.")
    parser.add_argument("--icons", action="store_true", help="Generate launcher icon master and mipmaps")
    parser.add_argument(
        "--screenshots",
        action="store_true",
        help="Generate landscape store screenshots (1920×1080)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Generate icons and screenshots",
    )
    args = parser.parse_args(argv)

    if args.all:
        args.icons = True
        args.screenshots = True

    if not args.icons and not args.screenshots:
        parser.error("Specify at least one of --icons, --screenshots, or --all")

    if args.icons:
        write_icons()

    if args.screenshots:
        compose_screenshots()

    return 0


if __name__ == "__main__":
    sys.exit(main())
